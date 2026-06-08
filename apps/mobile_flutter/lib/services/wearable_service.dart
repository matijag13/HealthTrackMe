import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wearable_device.dart';
import 'api_service.dart';
import 'phone_sensor_service.dart';
import 'sync_events.dart';
import 'dart:convert';

class WearableService {
  static final WearableService _instance = WearableService._internal();

  factory WearableService() {
    return _instance;
  }

  WearableService._internal();

  final Health health = Health();
  final ApiService _api = ApiService.instance;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '${_api.baseUrl}$cleanPath',
    ).replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _headers({Map<String, String>? extra}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (extra != null) ...extra,
    };
    final token = await _api.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  List<HealthDataType> get _requestedDataTypes {
    if (_isAndroid) {
      return [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.WORKOUT,
        HealthDataType.DISTANCE_WALKING_RUNNING,
      ];
    }
    return [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.WORKOUT,
      HealthDataType.DISTANCE_WALKING_RUNNING,
    ];
  }

  /// Request necessary permissions for health data access
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) {
        return false;
      }

      if (_isAndroid) {
        // Android specific permissions
        final status = await Permission.activityRecognition.request();
        if (status.isDenied) {
          debugPrint('❌ Activity recognition permission denied');
          return false;
        }
      }

      // Request READ for everything, and READ+WRITE for steps so the phone can
      // write its own step data into Health Connect. Even if optional types
      // (distance, workout) are denied, we still consider the overall request
      // successful as long as the core types are granted.
      final types = _requestedDataTypes;
      const writeTypes = {
        HealthDataType.STEPS,
        HealthDataType.WORKOUT,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.SLEEP_SESSION,
      };
      final permissions = types
          .map(
            (t) => writeTypes.contains(t)
                ? HealthDataAccess.READ_WRITE
                : HealthDataAccess.READ,
          )
          .toList();
      await health.requestAuthorization(types, permissions: permissions);
      final coreGranted =
          (await health.hasPermissions(_coreDataTypes)) ?? false;

      if (coreGranted) {
        debugPrint('✅ Core health permissions granted');
      } else {
        debugPrint('❌ Core health permissions denied');
      }

      return coreGranted;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Core types that must be granted for a sync to be worth running.
  /// Optional types (distance, workout, etc.) are fetched best-effort and
  /// won't block syncing if not yet granted.
  static const _coreDataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  /// Check if the minimum required permissions are granted. Lenient: a single core
  /// type (heart rate OR steps) being granted is enough — some wearables (e.g. Garmin)
  /// only write one of them into Health Connect, and we shouldn't skip syncing the rest.
  Future<bool> hasPermissions() async {
    try {
      if (kIsWeb) return false;
      for (final type in _coreDataTypes) {
        if ((await health.hasPermissions([type])) ?? false) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// Sync health data from wearable device for date range.
  ///
  /// Workouts are synced as individual sport activities (already per-session).
  /// Vitals (HR, sleep, calories) are synced **per calendar day** so that the
  /// health history charts get one real data point per day, and the dashboard
  /// sleep/HR cards are never polluted by an accumulated multi-day total.
  Future<WearableSyncData> syncWearableData({
    required int userId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      if (kIsWeb) {
        return WearableSyncData(date: DateTime.now());
      }

      endDate ??= DateTime.now();

      debugPrint(
        '🔄 Syncing health data from ${startDate.toLocal()} to ${endDate.toLocal()}',
      );

      // Record phone steps into HC first (best-effort).
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('pref_phone_tracking') ?? false) {
          await PhoneSensorService.instance.recordSteps();
        }
      } catch (_) {}

      final resolvedUserId = await _api.ensureActiveUserId();
      if (resolvedUserId == null) throw Exception('No active user');
      final source = _isIOS ? 'Apple Health' : 'Health Connect';

      // ── Workouts ──────────────────────────────────────────────────────────
      // Already per-session (each has its own date + duration) — upload first
      // so the dashboard activity card can show today's exercise after sync.
      final workouts = await _getWorkouts(startDate, endDate);
      final distanceKm = await _getDistance(startDate, endDate);
      for (final w in workouts) {
        final wDate = (w['date'] as DateTime).toIso8601String().split('T')[0];
        final payload = <String, dynamic>{
          'activityType': w['activityType'],
          'activityDate': wDate,
          'duration': w['durationMinutes'],
          'notes': 'Synced from $source',
        };
        if (w['caloriesBurned'] != null) {
          payload['caloriesBurned'] = w['caloriesBurned'];
        }
        if (w['distanceKm'] != null) payload['distance'] = w['distanceKm'];
        if (w['steps'] != null) payload['steps'] = w['steps'];
        await _api.createSportActivity(payload, userId: resolvedUserId);
      }

      // ── Per-day vitals ────────────────────────────────────────────────────
      // Fetch raw points once for the full window (efficient — one HC call per
      // type), then slice them per calendar day in Dart.
      final sleepType = _isAndroid
          ? HealthDataType.SLEEP_SESSION
          : HealthDataType.SLEEP_IN_BED;

      // Vitals are aggregated over each *full* calendar day below, so raw points
      // must be fetched from the start of the first day — NOT from the raw
      // [startDate], which on an incremental foreground sync is only minutes ago.
      // Fetching from [startDate] would recompute today's HR/calories from just
      // that latest slice and clobber the full-day value already on the
      // dashboard. The extra 12h look-back captures overnight sleep that began
      // the previous evening (matching the noon→noon window in _sleepForWindow).
      final vitalsStart =
          DateTime(startDate.year, startDate.month, startDate.day)
              .subtract(const Duration(hours: 12));
      final allHrPts = await _fetchRawPoints(
        vitalsStart,
        endDate,
        HealthDataType.HEART_RATE,
      );
      final allSleepPts = await _fetchRawPoints(vitalsStart, endDate, sleepType);
      final allCalPts = await _fetchRawPoints(
        vitalsStart,
        endDate,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      );

      debugPrint(
        '📊 Raw points — HR: ${allHrPts.length}, '
        'sleep: ${allSleepPts.length}, calories: ${allCalPts.length}, '
        'workouts: ${workouts.length}',
      );

      WearableSyncData todayData = WearableSyncData(date: endDate);
      bool anySyncedData = workouts.isNotEmpty;

      final endDay = DateTime(endDate.year, endDate.month, endDate.day);
      var day = DateTime(startDate.year, startDate.month, startDate.day);

      while (!day.isAfter(endDay)) {
        final nextDay = day.add(const Duration(days: 1));
        final isToday =
            day.year == endDay.year &&
            day.month == endDay.month &&
            day.day == endDay.day;

        // HR: readings whose timestamp falls within [day, nextDay)
        final hr = _hrForWindow(allHrPts, day, nextDay);

        // Sleep: sessions overlapping a noon→noon window centred on [day].
        // This captures overnight sleep (e.g. 22:00 day-1 → 07:00 day) that
        // would otherwise fall outside a strict midnight→midnight boundary.
        final sleepFrom = day.subtract(const Duration(hours: 12));
        final sleepTo = day.add(const Duration(hours: 12));
        final sleep = _sleepForWindow(allSleepPts, sleepFrom, sleepTo);

        // Calories: readings within [day, nextDay)
        final dayCal = _sumForWindow(allCalPts, day, nextDay);

        // Active energy burned (dayCal) is intentionally NOT persisted: it would
        // land in caloriesConsumed, which is the user's manually-logged food
        // intake, and corrupt it. Per-workout caloriesBurned already captures
        // exercise energy; dayCal is kept only for the post-sync status message.
        if (hr != null || sleep != null) {
          anySyncedData = true;
          final dateStr = day.toIso8601String().split('T')[0];
          final vitalsPayload = <String, dynamic>{
            'entryDate': dateStr,
            'notes': 'Synced from $source',
          };
          if (hr != null) {
            vitalsPayload['heartRate'] = (hr['avg']! as double).toInt();
          }
          if (sleep != null) {
            vitalsPayload['sleepHours'] = sleep['hours'];
            vitalsPayload['sleepQuality'] = sleep['quality'];
          }
          await _api.syncHealthVitals(vitalsPayload, userId: resolvedUserId);

          if (isToday) {
            todayData = WearableSyncData(
              date: day,
              calories: dayCal > 0 ? dayCal.toInt() : null,
              heartRateAvg: hr != null ? hr['avg'] as double? : null,
              heartRateMax: hr != null ? hr['max'] as int? : null,
              heartRateMin: hr != null ? hr['min'] as int? : null,
              sleepHours: sleep != null ? sleep['hours'] as double? : null,
              sleepQuality: sleep != null ? sleep['quality'] as String? : null,
            );
          }
        }

        // Steps fallback for today only: if no workout sessions were synced,
        // create a WALKING sport activity so the dashboard step count is visible.
        if (isToday && workouts.isEmpty) {
          final todaySteps = await _getSteps(day, nextDay);
          if (todaySteps != null && todaySteps > 0) {
            anySyncedData = true;
            final stepPayload = <String, dynamic>{
              'activityType': 'WALKING',
              'activityDate': day.toIso8601String().split('T')[0],
              'steps': todaySteps,
            };
            if (distanceKm != null) stepPayload['distance'] = distanceKm;
            await _api.createSportActivity(stepPayload, userId: resolvedUserId);
            todayData = WearableSyncData(
              date: day,
              steps: todaySteps,
              calories: todayData.calories,
              heartRateAvg: todayData.heartRateAvg,
              heartRateMax: todayData.heartRateMax,
              heartRateMin: todayData.heartRateMin,
              sleepHours: todayData.sleepHours,
              sleepQuality: todayData.sleepQuality,
            );
          }
        }

        day = nextDay;
      }

      if (anySyncedData) SyncEvents.instance.notifySynced();
      debugPrint('✅ Health data synced successfully');
      return todayData;
    } catch (e) {
      debugPrint('❌ Error syncing health data: $e');
      rethrow;
    }
  }

  /// Extract numeric value from a HealthDataPoint.
  /// In health package 13+, values are wrapped in NumericHealthValue.
  double _numericValue(HealthDataPoint point) {
    final v = point.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return 0;
  }

  /// Get steps using the platform aggregated total (de-duplicates multiple sources).
  Future<int?> _getSteps(DateTime startDate, DateTime endDate) async {
    try {
      final total = await health.getTotalStepsInInterval(startDate, endDate);
      return (total != null && total > 0) ? total : null;
    } catch (e) {
      debugPrint('⚠️ Error fetching steps: $e');
      return null;
    }
  }

  /// Fetch all raw HealthDataPoints for [type] in [start]..[end]. Never throws.
  Future<List<HealthDataPoint>> _fetchRawPoints(
    DateTime start,
    DateTime end,
    HealthDataType type,
  ) async {
    try {
      return await health.getHealthDataFromTypes(
        types: [type],
        startTime: start,
        endTime: end,
      );
    } catch (_) {
      return [];
    }
  }

  /// Heart-rate avg / min / max for readings whose timestamp falls in [from, to).
  /// Returns null when there are no valid readings in the window.
  Map<String, dynamic>? _hrForWindow(
    List<HealthDataPoint> pts,
    DateTime from,
    DateTime to,
  ) {
    final inWin = pts
        .where((p) => !p.dateFrom.isBefore(from) && p.dateFrom.isBefore(to))
        .toList();
    if (inWin.isEmpty) return null;
    final vals = inWin
        .map(_numericValue)
        .where((v) => v > 0)
        .toList(growable: false);
    if (vals.isEmpty) return null;
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final max = vals.reduce((a, b) => a > b ? a : b);
    final min = vals.reduce((a, b) => a < b ? a : b);
    return {'avg': avg, 'max': max.toInt(), 'min': min.toInt()};
  }

  /// Sleep hours / quality for sessions overlapping [from, to).
  ///
  /// Duration is computed from [dateFrom, dateTo] on each data point.
  /// SLEEP_SESSION / SLEEP_IN_BED carry the sleep-stage code in their numeric
  /// value — NOT the duration in minutes — so using _numericValue() here would
  /// always return ~0. The real duration is the time span of the record.
  Map<String, dynamic>? _sleepForWindow(
    List<HealthDataPoint> pts,
    DateTime from,
    DateTime to,
  ) {
    // Include sessions that overlap the window (start before [to], end after [from])
    final inWin = pts
        .where((p) => p.dateFrom.isBefore(to) && p.dateTo.isAfter(from))
        .toList();
    if (inWin.isEmpty) return null;
    // Clamp each session to the window boundaries so the noon→noon approach
    // never double-counts minutes that belong to the previous/next day's window.
    final totalMins = inWin.fold<double>(0, (s, p) {
      final effFrom = p.dateFrom.isBefore(from) ? from : p.dateFrom;
      final effTo = p.dateTo.isAfter(to) ? to : p.dateTo;
      final mins = effTo.difference(effFrom).inMinutes.toDouble();
      return s + (mins > 0 ? mins : 0);
    });
    if (totalMins <= 0) return null;
    final hours = totalMins / 60;
    final quality = hours >= 7.5
        ? 'EXCELLENT'
        : hours >= 7
        ? 'GOOD'
        : hours < 5
        ? 'POOR'
        : 'FAIR';
    return {'hours': hours, 'quality': quality};
  }

  /// Sum numeric values for readings in [from, to).
  double _sumForWindow(List<HealthDataPoint> pts, DateTime from, DateTime to) {
    return pts
        .where((p) => !p.dateFrom.isBefore(from) && p.dateFrom.isBefore(to))
        .fold<double>(0, (s, p) => s + _numericValue(p));
  }

  /// Get total walking/running distance in km.
  Future<double?> _getDistance(DateTime startDate, DateTime endDate) async {
    try {
      final data = await health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: startDate,
        endTime: endDate,
      );
      // Values are in metres
      final totalMetres = data.fold<double>(0, (s, p) => s + _numericValue(p));
      return totalMetres > 0 ? totalMetres / 1000.0 : null;
    } catch (e) {
      debugPrint('⚠️ Error fetching distance: $e');
      return null;
    }
  }

  /// Get workout/exercise sessions — each carries type, duration, calories, distance, steps.
  ///
  /// Samsung Health (and some other sources) write exercise sessions to Health Connect
  /// with null totalDistance / totalSteps inside the WORKOUT record itself. Those values
  /// are stored separately in STEPS and DISTANCE_WALKING_RUNNING data types.
  /// We pre-fetch all step and distance points for the window and attribute them to each
  /// workout by their overlapping time range, so we always capture as much data as possible.
  Future<List<Map<String, dynamic>>> _getWorkouts(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startDate,
        endTime: endDate,
      );
      if (data.isEmpty) return [];

      // Pre-fetch steps and distance so we can fill in nulls from WORKOUT records.
      List<HealthDataPoint> stepsPoints = [];
      List<HealthDataPoint> distancePoints = [];
      try {
        stepsPoints = await health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startDate,
          endTime: endDate,
        );
      } catch (_) {}
      try {
        distancePoints = await health.getHealthDataFromTypes(
          types: [HealthDataType.DISTANCE_WALKING_RUNNING],
          startTime: startDate,
          endTime: endDate,
        );
      } catch (_) {}

      final results = <Map<String, dynamic>>[];
      for (final point in data) {
        final v = point.value;
        if (v is! WorkoutHealthValue) continue;

        // Use seconds to avoid dropping legitimate short sessions (< 1 min).
        final durationSeconds = point.dateTo
            .difference(point.dateFrom)
            .inSeconds;
        if (durationSeconds <= 0) continue;
        final durationMinutes = (durationSeconds / 60).round().clamp(1, 9999);

        // Distance: use embedded value first, fall back to DISTANCE data points.
        double? distanceKm = v.totalDistance != null
            ? v.totalDistance! / 1000.0
            : _sumPointsInWindow(distancePoints, point.dateFrom, point.dateTo) >
                  0
            ? _sumPointsInWindow(distancePoints, point.dateFrom, point.dateTo) /
                  1000.0
            : null;

        // Steps: use embedded value first, fall back to STEPS data points.
        final int? steps =
            v.totalSteps ??
            (_sumPointsInWindow(stepsPoints, point.dateFrom, point.dateTo) > 0
                ? _sumPointsInWindow(
                    stepsPoints,
                    point.dateFrom,
                    point.dateTo,
                  ).toInt()
                : null);

        // Skip workouts that were written to HC by our own app.  We log those
        // directly to the backend already (via createSportActivity), so picking
        // them up here again would create a duplicate entry on every sync.
        // HC stores the source app's package name in sourceId.
        const ownPkg = 'com.example.healthtrackme';
        if (point.sourceId.toLowerCase().contains('healthtrackme') ||
            point.sourceName.toLowerCase().contains('healthtrackme') ||
            point.sourceId == ownPkg) {
          continue;
        }

        // Skip trivial walk/run sessions. Samsung Health writes lots of tiny
        // auto-detected walking segments to Health Connect (a few steps each);
        // importing every one floods the log with junk. A real walk/run has
        // meaningful steps or distance.
        final isWalkRun =
            v.workoutActivityType == HealthWorkoutActivityType.WALKING ||
            v.workoutActivityType == HealthWorkoutActivityType.RUNNING;
        if (isWalkRun && (steps ?? 0) < 100 && (distanceKm ?? 0) < 0.1) {
          continue;
        }

        results.add({
          'activityType': _mapWorkoutType(v.workoutActivityType),
          'date': point.dateFrom,
          'durationMinutes': durationMinutes,
          'caloriesBurned': v.totalEnergyBurned,
          'distanceKm': distanceKm,
          'steps': steps,
        });
      }
      debugPrint('🏋️ Found ${results.length} workout sessions');
      return results;
    } catch (e) {
      debugPrint('⚠️ Error fetching workouts: $e');
      return [];
    }
  }

  /// Sum numeric values from [points] whose time window overlaps [from]–[to].
  double _sumPointsInWindow(
    List<HealthDataPoint> points,
    DateTime from,
    DateTime to,
  ) {
    return points
        .where((p) => p.dateFrom.isBefore(to) && p.dateTo.isAfter(from))
        .fold<double>(0, (acc, p) => acc + _numericValue(p));
  }

  String _mapWorkoutType(HealthWorkoutActivityType type) {
    switch (type) {
      case HealthWorkoutActivityType.WALKING:
      case HealthWorkoutActivityType.WALKING_TREADMILL:
      case HealthWorkoutActivityType.HIKING:
        return 'WALKING';
      case HealthWorkoutActivityType.RUNNING:
      case HealthWorkoutActivityType.RUNNING_TREADMILL:
        return 'RUNNING';
      case HealthWorkoutActivityType.BIKING:
      case HealthWorkoutActivityType.BIKING_STATIONARY:
        return 'CYCLING';
      case HealthWorkoutActivityType.SWIMMING:
      case HealthWorkoutActivityType.SWIMMING_OPEN_WATER:
      case HealthWorkoutActivityType.SWIMMING_POOL:
      case HealthWorkoutActivityType.WATER_FITNESS:
        return 'SWIMMING';
      case HealthWorkoutActivityType.YOGA:
      case HealthWorkoutActivityType.PILATES:
      case HealthWorkoutActivityType.TAI_CHI:
      case HealthWorkoutActivityType.MIND_AND_BODY:
        return 'YOGA';
      case HealthWorkoutActivityType.STRENGTH_TRAINING:
      case HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.WEIGHTLIFTING:
      case HealthWorkoutActivityType.CALISTHENICS:
      case HealthWorkoutActivityType.CORE_TRAINING:
        return 'GYM';
      case HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
      case HealthWorkoutActivityType.CROSS_TRAINING:
        return 'HIIT';
      case HealthWorkoutActivityType.ROWING:
      case HealthWorkoutActivityType.ROWING_MACHINE:
        return 'ROWING';
      case HealthWorkoutActivityType.ELLIPTICAL:
      case HealthWorkoutActivityType.STAIR_CLIMBING:
      case HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE:
      case HealthWorkoutActivityType.MIXED_CARDIO:
      case HealthWorkoutActivityType.CARDIO_DANCE:
        return 'CARDIO';
      default:
        return 'WORKOUT';
    }
  }

  /// Get list of connected wearable devices
  Future<List<WearableDevice>> getConnectedDevices(int userId) async {
    try {
      if (kIsWeb) return [];

      final response = await http.get(
        _uri('/wearable-devices/users/$userId'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map(
              (item) => WearableDevice.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching devices: $e');
      return [];
    }
  }

  /// Add new wearable device
  Future<WearableDevice> addDevice(
    int userId,
    String name,
    WearableDeviceType type,
  ) async {
    try {
      if (kIsWeb) throw UnsupportedError('Not supported on web');

      final deviceId =
          '${type.name}_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final payload = {
        'deviceName': name,
        'deviceType': type.name.toUpperCase(),
        'deviceId': deviceId,
      };

      final response = await http.post(
        _uri('/wearable-devices/users/$userId'),
        headers: await _headers(extra: {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final device = WearableDevice.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        debugPrint('✅ Device added: ${device.name}');
        return device;
      }

      throw Exception(data['message'] ?? 'Failed to add device');
    } catch (e) {
      debugPrint('❌ Error adding device: $e');
      rethrow;
    }
  }

  /// Stamp a device's last-sync time on the backend so its card shows real
  /// "synced X ago" status. Best-effort — failures don't block the UI.
  Future<void> markDeviceSynced(int deviceId) async {
    try {
      if (kIsWeb) return;
      await http.post(
        _uri('/wearable-devices/$deviceId/sync'),
        headers: await _headers(extra: {'Content-Type': 'application/json'}),
      );
    } catch (e) {
      debugPrint('⚠️ Error stamping device sync: $e');
    }
  }

  /// Disconnect device
  Future<bool> disconnectDevice(int deviceId) async {
    try {
      if (kIsWeb) return false;

      final response = await http.delete(
        _uri('/wearable-devices/$deviceId'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        debugPrint('✅ Device disconnected');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error disconnecting device: $e');
      return false;
    }
  }

  /// Get sync history — not yet supported by backend, returns empty
  Future<List<SyncEvent>> getSyncHistory(int userId) async {
    try {
      if (kIsWeb) return [];
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching sync history: $e');
      return [];
    }
  }

  /// Show sync status notification
  static void showSyncStatus(
    BuildContext context,
    String message,
    bool success,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.sync_alt : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Check if health data is available
  Future<bool> isHealthDataAvailable() async {
    try {
      if (kIsWeb) {
        return false;
      }

      if (!_isAndroid && !_isIOS) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('⚠️ Error checking health data availability: $e');
      return false;
    }
  }
}
