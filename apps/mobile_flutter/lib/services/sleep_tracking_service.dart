import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'sync_events.dart';

/// Detects overnight sleep the way Samsung Health does — by noticing when the
/// phone goes untouched for a long stretch through the night — without needing
/// Samsung Health at all.
///
/// HOW IT WORKS
/// A persistent Android **foreground service** (so Android won't kill it while
/// you sleep) wakes every [_tickInterval] and reads the hardware step counter.
/// If the count barely moves, you're still. When a long still stretch that
/// spans the small hours finally ends (you pick the phone up in the morning),
/// it's recorded as a sleep session: start = when you went still, end = when you
/// moved again. The detected session is stashed in shared-prefs and pushed to
/// the running app, which uploads it to the backend and writes it to Health
/// Connect — the same pipeline Samsung-synced sleep used to flow through.
///
/// Everything in the background isolate is best-effort and wrapped in try/catch:
/// if the sensor or a plugin isn't reachable there, detection simply pauses
/// rather than crashing the service.
class SleepTrackingService {
  SleepTrackingService._();
  static final SleepTrackingService instance = SleepTrackingService._();

  static const String prefEnabled = 'pref_sleep_tracking';
  static const String prefAutoActivity = 'pref_auto_activity';

  // Handoff + detector state (shared across the two isolates via shared-prefs).
  static const String _kPendingSleep = 'sleep_pending_json';
  static const String _kPendingActivities = 'activity_pending_json';
  static const String _kLastWakeDate = 'sleep_last_wake_date';
  static const String _kUploadedWakeDate = 'sleep_uploaded_wake_date';
  static const String _kDismissedWakeDate = 'sleep_dismissed_wake_date';

  static const String _channelId = 'sleep_tracking';
  static const String _channelName = 'Sleep tracking';
  static const String _localeKey = 'healthtrackme_locale';

  Future<bool> _isSlovenian() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) == 'sl';
  }

  final ApiService _api = ApiService.instance;
  final Health _health = Health();

  bool _mainWired = false;

  /// Wire the main-isolate side once, early in app start (before/around
  /// runApp). Sets up the port the background isolate uses to hand a detected
  /// sleep session to the app so it can upload immediately when open.
  void initMain() {
    if (_mainWired || kIsWeb) return;
    _mainWired = true;
    try {
      FlutterForegroundTask.initCommunicationPort();
      FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    } catch (e) {
      debugPrint('Sleep initMain failed: $e');
    }
  }

  void _onTaskData(Object data) {
    // The background isolate sends a detected session as a JSON string, tagged
    // with 'kind' ('sleep' or 'activity'). Older payloads have no kind → sleep.
    if (data is! String) return;
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      if ((map['kind'] as String?) == 'activity') {
        _uploadActivityFromMap(map);
        return;
      }
    } catch (_) {}
    // Sleep is NOT auto-logged anymore — the background isolate already stashed
    // it as a pending suggestion. Just nudge any open screen to surface the
    // "save this sleep?" card (see pendingSleepSuggestion).
    SyncEvents.instance.notifySynced();
  }

  Future<bool> isRunning() async {
    if (kIsWeb) return false;
    try {
      return await FlutterForegroundTask.isRunningService;
    } catch (_) {
      return false;
    }
  }

  /// Start the always-on sleep detector. Asks for the notification permission
  /// (the service must show an ongoing notification) and, best-effort, for the
  /// battery-optimisation exemption so Android keeps the service alive
  /// overnight. Returns true if the service is running afterwards.
  Future<bool> start() async {
    if (kIsWeb) return false;
    try {
      // Foreground services must post an ongoing notification on Android 13+.
      final notif = await FlutterForegroundTask.checkNotificationPermission();
      if (notif != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      // Best-effort: keep the service alive through the night.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      final sl = await _isSlovenian();
      _init(sl);

      if (await FlutterForegroundTask.isRunningService) {
        return true;
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: 7341,
        serviceTypes: const [ForegroundServiceTypes.health],
        notificationTitle: 'HealthTrackMe',
        notificationText: sl
            ? 'Spremljanje korakov in spanja s tega telefona.'
            : 'Tracking your steps & sleep from this phone.',
        callback: startSleepCallback,
      );
      return result is ServiceRequestSuccess;
    } catch (e) {
      debugPrint('Sleep tracking start failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('Sleep tracking stop failed: $e');
    }
  }

  /// Starts the foreground service when EITHER sleep or walk/run auto-detection
  /// is enabled, and stops it only when both are off. Both detectors share the
  /// one always-on service. Returns whether the service is running afterwards.
  Future<bool> refreshService() async {
    if (kIsWeb) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final want = (prefs.getBool(prefEnabled) ?? false) ||
          (prefs.getBool(prefAutoActivity) ?? false);
      if (want) {
        await start();
      } else {
        await stop();
      }
      return await isRunning();
    } catch (e) {
      debugPrint('refreshService failed: $e');
      return false;
    }
  }

  void _init(bool sl) {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: sl ? 'Spremljanje spanja' : _channelName,
        channelDescription: sl
            ? 'Med počitkom zaznava tvoje spanje.'
            : 'Keeps detecting your sleep while you rest.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          _tickInterval.inMilliseconds,
        ),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  // ----- Main-isolate upload path -------------------------------------------

  /// Uploads any sleep session the background isolate detected while the app was
  /// closed. Call on app resume. Returns the human-readable hours if a fresh
  /// session was uploaded (so the UI can surface a suggestion), else null.
  /// Drains background-detected sessions on app open/resume. Walks/runs upload
  /// automatically; SLEEP does NOT — it's surfaced as a suggestion the user
  /// confirms (see [pendingSleepSuggestion]). We just nudge the UI so the
  /// "save this sleep?" card appears when a suggestion is waiting.
  Future<void> processPending() async {
    if (kIsWeb) return;
    unawaited(_processPendingActivities());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // pick up the background isolate's write
      if ((prefs.getString(_kPendingSleep) ?? '').isNotEmpty) {
        SyncEvents.instance.notifySynced();
      }
    } catch (e) {
      debugPrint('processPending failed: $e');
    }
  }

  // ----- Sleep suggestion (user-confirmed, not auto-logged) -----------------

  /// Last night's *detected but not-yet-saved* sleep, as a suggestion
  /// {start, end, hours, quality} — or null if nothing is pending (or the user
  /// already saved/dismissed that night).
  Future<Map<String, dynamic>?> pendingSleepSuggestion() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(_kPendingSleep);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final startMs = (map['startMs'] as num).toInt();
      final endMs = (map['endMs'] as num).toInt();
      final hours = (map['hours'] as num).toDouble();
      final end = DateTime.fromMillisecondsSinceEpoch(endMs);
      final wakeDate = _dateStr(end);
      if (prefs.getString(_kUploadedWakeDate) == wakeDate) return null;
      if (prefs.getString(_kDismissedWakeDate) == wakeDate) return null;
      return {
        'start': DateTime.fromMillisecondsSinceEpoch(startMs),
        'end': end,
        'hours': hours,
        'quality': map['quality'] as String? ?? _qualityFor(hours),
      };
    } catch (e) {
      debugPrint('pendingSleepSuggestion failed: $e');
      return null;
    }
  }

  /// Save the pending detected sleep as-is (upload + write to Health Connect).
  Future<double?> confirmSleepSuggestion() async {
    if (kIsWeb) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(_kPendingSleep);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final start =
          DateTime.fromMillisecondsSinceEpoch((map['startMs'] as num).toInt());
      final end =
          DateTime.fromMillisecondsSinceEpoch((map['endMs'] as num).toInt());
      return await _uploadSleepSession(start, end);
    } catch (_) {
      return null;
    }
  }

  /// Save the detected sleep with user-adjusted bedtime / wake time.
  Future<double?> saveAdjustedSleep(DateTime start, DateTime end) =>
      _uploadSleepSession(start, end);

  /// Discard the suggestion so it's not offered again for that night.
  Future<void> dismissSleepSuggestion() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(_kPendingSleep);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final end =
            DateTime.fromMillisecondsSinceEpoch((map['endMs'] as num).toInt());
        await prefs.setString(_kDismissedWakeDate, _dateStr(end));
      }
      await prefs.remove(_kPendingSleep);
      SyncEvents.instance.notifySynced();
    } catch (e) {
      debugPrint('dismissSleepSuggestion failed: $e');
    }
  }

  /// Uploads a sleep session for [start]..[end] — backend entry + Health Connect
  /// write — then clears the pending suggestion and marks the wake-day saved.
  /// Shared by "save as detected" and "save adjusted"; hours are derived from
  /// the (possibly user-edited) start/end.
  Future<double?> _uploadSleepSession(DateTime start, DateTime end) async {
    try {
      if (!end.isAfter(start)) return null;
      final hours = end.difference(start).inMinutes / 60.0;
      final quality = _qualityFor(hours);
      final wakeDate = _dateStr(end);

      final userId = await _api.ensureActiveUserId();
      if (userId == null) return null;

      // Backend: upsert the wake-day's health entry with the sleep figures.
      final ok = await _api.syncHealthVitals({
        'entryDate': wakeDate,
        'sleepHours': double.parse(hours.toStringAsFixed(2)),
        'sleepQuality': quality,
        'notes': 'Auto-detected on this phone',
      }, userId: userId);

      // Health Connect: write the sleep session so it shows alongside other
      // sources and feeds the existing read-back sync.
      try {
        await _health.writeHealthData(
          value: (hours * 60).roundToDouble(),
          type: HealthDataType.SLEEP_SESSION,
          startTime: start,
          endTime: end,
          recordingMethod: RecordingMethod.automatic,
        );
      } catch (e) {
        debugPrint('Health Connect sleep write failed: $e');
      }

      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUploadedWakeDate, wakeDate);
        await prefs.remove(_kPendingSleep);
        SyncEvents.instance.notifySynced();
        return hours;
      }
      return null;
    } catch (e) {
      debugPrint('Sleep upload failed: $e');
      return null;
    }
  }

  // ----- Activity (walk/run) upload path ------------------------------------

  /// Uploads any walk/run sessions the background isolate detected. Idempotent:
  /// the backend de-duplicates by type+date+duration+steps, so a session pushed
  /// live AND replayed here on resume only ever creates one row.
  Future<void> _processPendingActivities() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(_kPendingActivities);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      for (final item in list) {
        if (item is Map) {
          await _uploadActivityFromMap(Map<String, dynamic>.from(item));
        }
      }
      await prefs.remove(_kPendingActivities);
    } catch (e) {
      debugPrint('processPendingActivities failed: $e');
    }
  }

  Future<void> _uploadActivityFromMap(Map<String, dynamic> map) async {
    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) return;
      final start =
          DateTime.fromMillisecondsSinceEpoch((map['startMs'] as num).toInt());
      final payload = <String, dynamic>{
        'activityType': (map['type'] as String?) ?? 'WALKING',
        'activityDate': _dateStr(start),
        'duration': (map['durationMin'] as num?)?.toInt() ?? 0,
        'steps': (map['steps'] as num?)?.toInt() ?? 0,
        'notes': 'Auto-detected on this phone',
      };
      final dist = (map['distanceKm'] as num?)?.toDouble();
      if (dist != null && dist > 0) payload['distance'] = dist;
      final cal = (map['calories'] as num?)?.toInt();
      if (cal != null && cal > 0) payload['caloriesBurned'] = cal;
      await _api.createSportActivity(payload, userId: userId);
      SyncEvents.instance.notifySynced();
    } catch (e) {
      debugPrint('Activity upload failed: $e');
    }
  }

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _qualityFor(double hours) {
    if (hours >= 7.5) return 'EXCELLENT';
    if (hours >= 7) return 'GOOD';
    if (hours < 5) return 'POOR';
    return 'FAIR';
  }

  // ----- Detector tuning (shared with the isolate handler) ------------------

  /// How often the service wakes to sample the step counter. 5 min is fine for
  /// sleep and gives walk/run detection usable granularity.
  static const Duration _tickInterval = Duration(minutes: 5);

  /// Below this many steps/hour the user is treated as "still" (asleep-ish).
  static const double _stillStepsPerHour = 120;

  /// A still stretch must be at least this long to count as sleep.
  static const double _minSleepHours = 3.5;

  /// Ignore absurdly long stretches (phone left behind, not on the sleeper).
  static const double _maxSleepHours = 14;

  // ----- Walk/run detection tuning ------------------------------------------

  /// At or above this many steps/hour the user is treated as actively walking
  /// (~50 steps/min). High enough to ignore incidental pottering around a room.
  static const double _walkStepsPerHour = 3000;

  /// An active stretch must clear both gates to be logged as a session.
  static const int _minWalkSeconds = 240; // 4 min
  static const int _minWalkSteps = 300;

  /// At/above this cadence the session is logged as a run rather than a walk.
  static const double _runStepsPerMin = 130;

  /// Rough distance estimate: steps × stride.
  static const double _strideMeters = 0.75;

  /// Calorie estimate uses a default weight (the background isolate has no
  /// profile access) × MET × hours.
  static const double _defaultWeightKg = 70;
  static const double _walkMet = 3.3;
  static const double _runMet = 9.0;
}

/// Entry point for the foreground-service isolate. Must be top-level and
/// annotated so the AOT compiler keeps it.
@pragma('vm:entry-point')
void startSleepCallback() {
  FlutterForegroundTask.setTaskHandler(_SleepTaskHandler());
}

/// Runs inside the foreground-service isolate. Samples the step counter each
/// tick, tracks how long the phone has been still, and records an overnight
/// still stretch as a sleep session.
class _SleepTaskHandler extends TaskHandler {
  int? _lastSteps;
  int? _lastReadMs;
  int? _stillSinceMs;
  int? _activeSinceMs;
  int _activeSteps = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Seed the baseline so the first interval has something to diff against.
    final steps = await _readSteps();
    if (steps != null) {
      _lastSteps = steps;
      _lastReadMs = timestamp.millisecondsSinceEpoch;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _tick(timestamp).catchError((Object e) {
      debugPrint('Sleep tick failed: $e');
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  Future<void> _tick(DateTime now) async {
    final cur = await _readSteps();
    if (cur == null) return; // sensor unreachable this tick — just wait

    final nowMs = now.millisecondsSinceEpoch;
    if (_lastSteps == null || _lastReadMs == null) {
      _lastSteps = cur;
      _lastReadMs = nowMs;
      return;
    }

    final delta = cur - _lastSteps!;
    final gapMs = nowMs - _lastReadMs!;
    if (gapMs <= 0) return;

    // Reboot / counter reset → re-baseline, drop any in-progress stretches.
    if (delta < 0) {
      _lastSteps = cur;
      _lastReadMs = nowMs;
      _stillSinceMs = null;
      _activeSinceMs = null;
      _activeSteps = 0;
      return;
    }

    final stepsPerHour = delta / (gapMs / 3600000.0);

    // Which detectors are enabled (best-effort; default off). The one service
    // hosts both, so it may be running for only one of them.
    var sleepOn = false;
    var activityOn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      sleepOn = prefs.getBool(SleepTrackingService.prefEnabled) ?? false;
      activityOn =
          prefs.getBool(SleepTrackingService.prefAutoActivity) ?? false;
    } catch (_) {}

    // ----- Sleep: long still stretch -----
    if (sleepOn) {
      final still = stepsPerHour < SleepTrackingService._stillStepsPerHour;
      if (still) {
        // Still across this whole gap; mark the stretch start at the last quiet
        // reading.
        _stillSinceMs ??= _lastReadMs;
      } else {
        final stillStart = _stillSinceMs;
        _stillSinceMs = null;
        if (stillStart != null) {
          await _maybeRecordSleep(stillStart, _lastReadMs!);
        }
      }
    } else {
      _stillSinceMs = null;
    }

    // ----- Activity: sustained active-stepping stretch -----
    if (activityOn) {
      final active = stepsPerHour >= SleepTrackingService._walkStepsPerHour;
      if (active) {
        _activeSinceMs ??= _lastReadMs;
        _activeSteps += delta;
      } else {
        final activeStart = _activeSinceMs;
        final activeSteps = _activeSteps;
        _activeSinceMs = null;
        _activeSteps = 0;
        if (activeStart != null) {
          await _maybeRecordWalk(activeStart, _lastReadMs!, activeSteps);
        }
      }
    } else {
      _activeSinceMs = null;
      _activeSteps = 0;
    }

    _lastSteps = cur;
    _lastReadMs = nowMs;
  }

  /// Records [startMs]..[endMs] as sleep if it's long enough and spans the
  /// small hours. Hands the session off to the app via shared-prefs + the data
  /// port, and reflects it in the ongoing notification.
  Future<void> _maybeRecordSleep(int startMs, int endMs) async {
    final durationMs = endMs - startMs;
    final hours = durationMs / 3600000.0;
    if (hours < SleepTrackingService._minSleepHours) return;
    if (hours > SleepTrackingService._maxSleepHours) return;

    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    if (!_spansNight(start, end)) return;

    final wakeDate = SleepTrackingService._dateStr(end);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      // One sleep per wake-day.
      if (prefs.getString(SleepTrackingService._kLastWakeDate) == wakeDate) {
        return;
      }
      final quality = SleepTrackingService._qualityFor(hours);
      final payload = jsonEncode({
        'kind': 'sleep',
        'startMs': startMs,
        'endMs': endMs,
        'hours': hours,
        'quality': quality,
      });
      await prefs.setString(SleepTrackingService._kPendingSleep, payload);
      await prefs.setString(SleepTrackingService._kLastWakeDate, wakeDate);

      // Nudge the running app (if any) to upload right away.
      try {
        FlutterForegroundTask.sendDataToMain(payload);
      } catch (_) {}

      // Reflect it in the ongoing notification.
      try {
        final sl = prefs.getString(SleepTrackingService._localeKey) == 'sl';
        await FlutterForegroundTask.updateService(
          notificationTitle:
              sl ? 'Spremljanje spanja vklopljeno' : 'Sleep tracking on',
          notificationText: sl
              ? 'Zaznano približno ${hours.toStringAsFixed(1)} h spanja prejšnjo noč.'
              : 'Detected ~${hours.toStringAsFixed(1)} h sleep last night.',
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Record sleep failed: $e');
    }
  }

  /// Records [startMs]..[endMs] as a walk/run if it clears the duration + step
  /// gates. Stashes it for the app to upload and nudges the app if it's open.
  Future<void> _maybeRecordWalk(int startMs, int endMs, int steps) async {
    final durationSec = (endMs - startMs) ~/ 1000;
    if (durationSec < SleepTrackingService._minWalkSeconds) return;
    if (steps < SleepTrackingService._minWalkSteps) return;

    final durationMin = (durationSec / 60).round().clamp(1, 9999);
    final stepsPerMin = steps / (durationSec / 60.0);
    final isRun = stepsPerMin >= SleepTrackingService._runStepsPerMin;
    final distanceKm = steps * SleepTrackingService._strideMeters / 1000.0;
    final met =
        isRun ? SleepTrackingService._runMet : SleepTrackingService._walkMet;
    final calories =
        (met * SleepTrackingService._defaultWeightKg * (durationSec / 3600.0))
            .round();

    final payload = {
      'kind': 'activity',
      'startMs': startMs,
      'endMs': endMs,
      'durationMin': durationMin,
      'steps': steps,
      'type': isRun ? 'RUNNING' : 'WALKING',
      'distanceKm': distanceKm,
      'calories': calories,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(SleepTrackingService._kPendingActivities);
      final list = <dynamic>[];
      if (raw != null && raw.isNotEmpty) {
        try {
          list.addAll(jsonDecode(raw) as List);
        } catch (_) {}
      }
      list.add(payload);
      await prefs.setString(
        SleepTrackingService._kPendingActivities,
        jsonEncode(list),
      );
      // Nudge the running app (if any) to upload right away.
      try {
        FlutterForegroundTask.sendDataToMain(jsonEncode(payload));
      } catch (_) {}
    } catch (e) {
      debugPrint('Record walk failed: $e');
    }
  }

  /// True if the still stretch covers ~03:00 local on its start or end day — a
  /// strong signal it was overnight sleep rather than daytime stillness.
  bool _spansNight(DateTime start, DateTime end) {
    bool contains(DateTime t) => !t.isBefore(start) && !t.isAfter(end);
    final threeAmEnd = DateTime(end.year, end.month, end.day, 3);
    final threeAmStart = DateTime(start.year, start.month, start.day, 3);
    return contains(threeAmEnd) || contains(threeAmStart);
  }

  /// Reads the cumulative hardware step count. Returns null if the sensor/plugin
  /// isn't reachable from this isolate (treated as "no reading", not "still").
  Future<int?> _readSteps() async {
    try {
      final e = await Pedometer.stepCountStream.first
          .timeout(const Duration(seconds: 8));
      return e.steps;
    } catch (_) {
      return null;
    }
  }
}
