import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';

import 'api_service.dart';
import 'notification_service.dart';
import 'sync_events.dart';

/// Auto-detects walking/running sessions while the app is alive and logs each one
/// (once) to the backend + Health Connect.
///
/// Detection is **step-driven**, not event-driven. The OS Activity Recognition
/// API is noisy and transition-based — relying on it directly produced dozens of
/// tiny fragments for a single walk. Instead, an activity event only *starts* a
/// candidate session; from there a periodic poll watches the hardware step
/// counter. As long as steps keep accumulating the session stays open (so a
/// continuous walk is one session, even across short pauses), and a session is
/// only logged if it clears a real duration **and** step threshold — which throws
/// away the "3 steps in 90s" noise.
class ActivityTrackingService {
  ActivityTrackingService._();
  static final ActivityTrackingService instance = ActivityTrackingService._();

  final ApiService _api = ApiService.instance;
  final Health _health = Health();

  StreamSubscription<Activity>? _sub;
  Timer? _poll;
  bool _running = false;

  DateTime? _sessionStart;
  ActivityType? _sessionType;
  int? _sessionStartSteps;
  int? _lastSteps;
  DateTime? _lastMoveTime;

  // Distance ≈ steps × stride. A default until per-user height tuning is added.
  static const double _strideMeters = 0.75;

  /// How often we sample the step counter while a session is open.
  static const Duration _pollInterval = Duration(seconds: 45);

  /// Steps within one poll that still count as "moving" (≈ a slow walk). Below
  /// this the user is treated as stopped.
  static const int _aliveStepsPerPoll = 15;

  /// End a session after this long with no real movement.
  static const Duration _idleTimeout = Duration(minutes: 2);

  /// A session must be at least this long AND have at least this many steps to be
  /// logged — together these discard the activity-recognition noise.
  static const int _minSessionSeconds = 180; // 3 min
  static const int _minSessionSteps = 200;

  // Calorie estimate = MET × weightKg × hours (the standard no-heart-rate method).
  static const double _walkMet = 3.3;
  static const double _runMet = 9.0;
  static const double _defaultWeightKg = 70;

  bool get isRunning => _running;

  Future<bool> start() async {
    if (_running || kIsWeb) return _running;
    try {
      final perm =
          await FlutterActivityRecognition.instance.requestPermission();
      if (perm != ActivityPermission.GRANTED) return false;
      _sub = FlutterActivityRecognition.instance.activityStream.listen(
        _onActivity,
        onError: (e) => debugPrint('Activity recognition error: $e'),
      );
      _running = true;
      return true;
    } catch (e) {
      debugPrint('Activity tracking start failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _running = false;
    await _finalizeSession();
  }

  void _onActivity(Activity activity) {
    final type = activity.type;
    final moving =
        (type == ActivityType.WALKING || type == ActivityType.RUNNING) &&
            activity.confidence != ActivityConfidence.LOW;
    if (!moving) return;

    if (_sessionStart == null) {
      _beginSession(type);
    } else {
      _lastMoveTime = DateTime.now();
      // Upgrade walk → run if the OS now reports running.
      if (type == ActivityType.RUNNING) _sessionType = ActivityType.RUNNING;
    }
  }

  Future<void> _beginSession(ActivityType type) async {
    final now = DateTime.now();
    _sessionStart = now;
    _sessionType = type;
    _lastMoveTime = now;
    final steps = await _currentSteps();
    _sessionStartSteps = steps;
    _lastSteps = steps;
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => _onPoll());
  }

  /// Each tick: if steps kept climbing, the session is alive; otherwise check
  /// whether we've been idle long enough to finalize.
  Future<void> _onPoll() async {
    if (_sessionStart == null) return;
    final cur = await _currentSteps();
    if (cur != null && _lastSteps != null) {
      final delta = cur - _lastSteps!;
      if (delta >= _aliveStepsPerPoll) {
        _lastMoveTime = DateTime.now();
      }
      _lastSteps = cur;
    }
    final idleFor = DateTime.now().difference(_lastMoveTime ?? DateTime.now());
    if (idleFor >= _idleTimeout) {
      await _finalizeSession();
    }
  }

  Future<void> _finalizeSession() async {
    _poll?.cancel();
    _poll = null;
    final start = _sessionStart;
    final type = _sessionType;
    final startSteps = _sessionStartSteps;
    final end = _lastMoveTime;
    _sessionStart = null;
    _sessionType = null;
    _sessionStartSteps = null;
    _lastSteps = null;
    _lastMoveTime = null;
    if (start == null || type == null || end == null) return;

    final durationSec = end.difference(start).inSeconds;
    final endSteps = await _currentSteps();
    final pedometerSteps =
        (startSteps != null && endSteps != null && endSteps >= startSteps)
            ? endSteps - startSteps
            : 0;

    // Extend the query window backwards to capture steps the OS activity
    // recogniser missed at the start of the walk (it typically fires 3-5 min in).
    final extStart = start.subtract(const Duration(minutes: 6));
    final extEnd = end.add(const Duration(seconds: 30));
    final hcSteps = await _hcStepsInWindow(extStart, extEnd);
    final hcDistanceKm = await _hcDistanceKmInWindow(extStart, extEnd);

    // Prefer Health Connect values when they're richer (GPS-backed distance from
    // Samsung / other sensors; step counts that include the pre-detection window).
    final bestSteps = (hcSteps != null && hcSteps > pedometerSteps)
        ? hcSteps
        : pedometerSteps;
    final bestDistanceKm = (hcDistanceKm != null && hcDistanceKm > 0.01)
        ? hcDistanceKm
        : pedometerSteps * _strideMeters / 1000.0;

    // The two gates that kill the noise: a real walk lasts minutes and racks up
    // hundreds of steps. Anything short or near-stationary is discarded.
    if (durationSec < _minSessionSeconds || bestSteps < _minSessionSteps) {
      return;
    }

    final durationMin = (durationSec / 60).round().clamp(1, 9999);
    final isRun = type == ActivityType.RUNNING;
    final weightKg = await _userWeightKg();
    final met = isRun ? _runMet : _walkMet;
    final calories = (met * weightKg * (durationSec / 3600.0)).round();

    bool uploaded = false;
    try {
      await _api.createSportActivity({
        'activityType': isRun ? 'RUNNING' : 'WALKING',
        'activityDate': _dateStr(start),
        'duration': durationMin,
        'steps': bestSteps,
        if (bestDistanceKm > 0) 'distance': bestDistanceKm,
        if (calories > 0) 'caloriesBurned': calories,
        'notes': 'Auto-detected on this phone',
      });
      uploaded = true;
    } catch (e) {
      debugPrint('Auto-session upload failed: $e');
    }

    // NOTE: we intentionally do NOT write this session back to Health Connect.
    // Samsung (and other wearables) already write the same walk/run to HC, and
    // if we also write one the wearable sync would re-import it and create a
    // third duplicate entry in the backend.  The backend already has the session
    // from the direct createSportActivity call above.

    if (uploaded) {
      // Notify the user so they see the auto-log immediately.
      try {
        await NotificationService.instance.showAutoActivityNotification(
          type: isRun ? 'Run' : 'Walk',
          durationMin: durationMin,
          distanceKm: bestDistanceKm,
          steps: bestSteps,
        );
      } catch (e) {
        debugPrint('Activity notification failed: $e');
      }
    }

    SyncEvents.instance.notifySynced();
  }

  /// Sums Health Connect STEPS data points in [from]..[to].
  /// Returns null if HC is unavailable or returns nothing.
  Future<int?> _hcStepsInWindow(DateTime from, DateTime to) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: [HealthDataType.STEPS],
      );
      if (points.isEmpty) return null;
      final total = points.fold<double>(0, (s, e) {
        final v = e.value;
        return s + (v is NumericHealthValue ? v.numericValue.toDouble() : 0);
      });
      return total > 0 ? total.round() : null;
    } catch (_) {
      return null;
    }
  }

  /// Sums Health Connect DISTANCE_WALKING_RUNNING (metres) in [from]..[to] and
  /// converts to kilometres. Returns null if HC is unavailable or has no data.
  Future<double?> _hcDistanceKmInWindow(DateTime from, DateTime to) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
      );
      if (points.isEmpty) return null;
      final totalMetres = points.fold<double>(0, (s, e) {
        final v = e.value;
        return s + (v is NumericHealthValue ? v.numericValue.toDouble() : 0);
      });
      return totalMetres > 1 ? totalMetres / 1000.0 : null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _currentSteps() async {
    try {
      final e = await Pedometer.stepCountStream.first
          .timeout(const Duration(seconds: 5));
      return e.steps;
    } catch (_) {
      return null;
    }
  }

  /// The user's weight for the calorie estimate, falling back to a default when
  /// it isn't on the profile.
  Future<double> _userWeightKg() async {
    try {
      final user = await _api.getCurrentUser();
      final w = user?.weightKg;
      if (w != null && w > 20 && w < 400) return w;
    } catch (_) {}
    return _defaultWeightKg;
  }

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
