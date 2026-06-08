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

  // Handoff + detector state (shared across the two isolates via shared-prefs).
  static const String _kPendingSleep = 'sleep_pending_json';
  static const String _kLastWakeDate = 'sleep_last_wake_date';
  static const String _kUploadedWakeDate = 'sleep_uploaded_wake_date';

  static const String _channelId = 'sleep_tracking';
  static const String _channelName = 'Sleep tracking';

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
    // The background isolate sends the detected session as a JSON string.
    if (data is String) {
      _uploadFromJson(data);
    }
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

      _init();

      if (await FlutterForegroundTask.isRunningService) {
        return true;
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: 7341,
        serviceTypes: const [ForegroundServiceTypes.health],
        notificationTitle: 'Sleep tracking on',
        notificationText: 'Detecting your sleep from this phone.',
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

  void _init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: 'Keeps detecting your sleep while you rest.',
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
  Future<double?> processPending() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // pick up the background isolate's write
      final raw = prefs.getString(_kPendingSleep);
      if (raw == null || raw.isEmpty) return null;
      final hours = await _uploadFromJson(raw);
      return hours;
    } catch (e) {
      debugPrint('processPending sleep failed: $e');
      return null;
    }
  }

  /// Parses a detected-session JSON payload and uploads it once (idempotent by
  /// wake date). Returns the sleep hours on a successful first upload.
  Future<double?> _uploadFromJson(String raw) async {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final startMs = (map['startMs'] as num).toInt();
      final endMs = (map['endMs'] as num).toInt();
      final hours = (map['hours'] as num).toDouble();
      final quality = map['quality'] as String? ?? _qualityFor(hours);
      final start = DateTime.fromMillisecondsSinceEpoch(startMs);
      final end = DateTime.fromMillisecondsSinceEpoch(endMs);
      final wakeDate = _dateStr(end);

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (prefs.getString(_kUploadedWakeDate) == wakeDate) {
        return null; // already uploaded this night's sleep
      }

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

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _qualityFor(double hours) {
    if (hours >= 7.5) return 'EXCELLENT';
    if (hours >= 7) return 'GOOD';
    if (hours < 5) return 'POOR';
    return 'FAIR';
  }

  // ----- Detector tuning (shared with the isolate handler) ------------------

  /// How often the service wakes to sample the step counter.
  static const Duration _tickInterval = Duration(minutes: 10);

  /// Below this many steps/hour the user is treated as "still" (asleep-ish).
  static const double _stillStepsPerHour = 120;

  /// A still stretch must be at least this long to count as sleep.
  static const double _minSleepHours = 3.5;

  /// Ignore absurdly long stretches (phone left behind, not on the sleeper).
  static const double _maxSleepHours = 14;
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

    var delta = cur - _lastSteps!;
    final gapMs = nowMs - _lastReadMs!;
    if (gapMs <= 0) return;

    // Reboot / counter reset → re-baseline, drop any in-progress still stretch.
    if (delta < 0) {
      _lastSteps = cur;
      _lastReadMs = nowMs;
      _stillSinceMs = null;
      return;
    }

    final stepsPerHour = delta / (gapMs / 3600000.0);
    final still = stepsPerHour < SleepTrackingService._stillStepsPerHour;

    if (still) {
      // The phone was still across this whole gap; mark the stretch's start at
      // the previous reading (when we last saw it quiet).
      _stillSinceMs ??= _lastReadMs;
    } else {
      // Movement resumed. The still stretch (if any) ran until the last
      // reading; evaluate it as possible sleep, with the wake at that point.
      final stillStart = _stillSinceMs;
      _stillSinceMs = null;
      if (stillStart != null) {
        await _maybeRecordSleep(stillStart, _lastReadMs!);
      }
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
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Sleep tracking on',
          notificationText:
              'Detected ~${hours.toStringAsFixed(1)} h sleep last night.',
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Record sleep failed: $e');
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
