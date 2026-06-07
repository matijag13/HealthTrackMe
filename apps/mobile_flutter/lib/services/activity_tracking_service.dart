import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';

import 'api_service.dart';
import 'sync_events.dart';

/// Auto-detects walking/running sessions from the OS Activity Recognition API
/// while the app is alive (foreground or recently backgrounded) and logs them
/// to the backend + Health Connect.
///
/// NOTE: always-on detection when the app is fully killed needs a persistent
/// foreground service (a planned follow-up). This version records whenever the
/// app is running.
class ActivityTrackingService {
  ActivityTrackingService._();
  static final ActivityTrackingService instance = ActivityTrackingService._();

  final ApiService _api = ApiService.instance;
  final Health _health = Health();

  StreamSubscription<Activity>? _sub;
  bool _running = false;

  DateTime? _sessionStart;
  ActivityType? _sessionType;
  int? _sessionStartSteps;
  Timer? _endTimer;

  // Distance ≈ steps × stride. A default until per-user height tuning is added.
  static const double _strideMeters = 0.75;
  static const int _minSessionSeconds = 60; // ignore < 1 min blips
  static const Duration _endDebounce = Duration(seconds: 90);

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
    _endTimer?.cancel();
    _endTimer = null;
    await _sub?.cancel();
    _sub = null;
    _running = false;
    await _endSession();
  }

  void _onActivity(Activity activity) {
    final type = activity.type;
    final moving = type == ActivityType.WALKING || type == ActivityType.RUNNING;
    if (moving && activity.confidence != ActivityConfidence.LOW) {
      _endTimer?.cancel();
      _endTimer = null;
      if (_sessionStart == null) {
        _beginSession(type);
      }
    } else if (_sessionStart != null && _endTimer == null) {
      // Stopped moving — end the session after a debounce (ignore brief pauses).
      _endTimer = Timer(_endDebounce, _endSession);
    }
  }

  Future<void> _beginSession(ActivityType type) async {
    _sessionStart = DateTime.now();
    _sessionType = type;
    _sessionStartSteps = await _currentSteps();
  }

  Future<void> _endSession() async {
    _endTimer?.cancel();
    _endTimer = null;
    final start = _sessionStart;
    final type = _sessionType;
    final startSteps = _sessionStartSteps;
    _sessionStart = null;
    _sessionType = null;
    _sessionStartSteps = null;
    if (start == null || type == null) return;

    final end = DateTime.now();
    final durationSec = end.difference(start).inSeconds;
    if (durationSec < _minSessionSeconds) return;

    final endSteps = await _currentSteps();
    final steps =
        (startSteps != null && endSteps != null && endSteps >= startSteps)
            ? endSteps - startSteps
            : 0;
    final durationMin = (durationSec / 60).round().clamp(1, 9999);
    final distanceKm = steps * _strideMeters / 1000.0;
    final isRun = type == ActivityType.RUNNING;

    try {
      await _api.createSportActivity({
        'activityType': isRun ? 'RUNNING' : 'WALKING',
        'activityDate': _dateStr(start),
        'duration': durationMin,
        if (steps > 0) 'steps': steps,
        if (distanceKm > 0) 'distance': distanceKm,
        'notes': 'Auto-detected on this phone',
      });
    } catch (e) {
      debugPrint('Auto-session upload failed: $e');
    }

    try {
      await _health.writeWorkoutData(
        activityType: isRun
            ? HealthWorkoutActivityType.RUNNING
            : HealthWorkoutActivityType.WALKING,
        start: start,
        end: end,
        totalDistance: distanceKm > 0 ? (distanceKm * 1000).round() : null,
        recordingMethod: RecordingMethod.automatic,
      );
    } catch (e) {
      debugPrint('Health Connect workout write failed: $e');
    }

    SyncEvents.instance.notifySynced();
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

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
