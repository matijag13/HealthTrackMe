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
    return Uri.parse('${_api.baseUrl}$cleanPath')
        .replace(queryParameters: queryParameters);
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
      final permissions = types
          .map((t) => t == HealthDataType.STEPS
              ? HealthDataAccess.READ_WRITE
              : HealthDataAccess.READ)
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

  /// Sync health data from wearable device for date range
  Future<WearableSyncData> syncWearableData({
    required int userId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      if (kIsWeb) {
        return WearableSyncData(
          date: DateTime.now(),
        );
      }

      endDate ??= DateTime.now();

      debugPrint(
          '🔄 Syncing health data from ${startDate.toLocal()} to ${endDate.toLocal()}');

      // If phone-sensor tracking is on, record this phone's steps into Health
      // Connect first, so the read below includes them (no Samsung Health
      // needed). Best-effort — failures don't block the rest of the sync.
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('pref_phone_tracking') ?? false) {
          await PhoneSensorService.instance.recordSteps();
        }
      } catch (_) {}

      // Fetch data from Health package
      final steps = await _getSteps(startDate, endDate);
      final heartRate = await _getHeartRate(startDate, endDate);
      final sleep = await _getSleep(startDate, endDate);
      final calories = await _getCalories(startDate, endDate);
      final distanceKm = await _getDistance(startDate, endDate);
      final workouts = await _getWorkouts(startDate, endDate);

      final syncData = WearableSyncData(
        date: DateTime.now(),
        steps: steps,
        activeMinutes: null,
        calories: calories,
        heartRateAvg: heartRate != null ? heartRate['avg'] as double? : null,
        heartRateMax: heartRate != null ? heartRate['max'] as int? : null,
        heartRateMin: heartRate != null ? heartRate['min'] as int? : null,
        sleepHours: sleep != null ? sleep['hours'] as double? : null,
        sleepQuality: sleep != null ? sleep['quality'] as String? : null,
      );

      debugPrint('📊 Sync data: steps=$steps, distanceKm=$distanceKm, '
          'heartRate=$heartRate, sleep=$sleep, calories=$calories, '
          'workouts=${workouts.length}');

      // Upload to backend
      await _uploadSyncData(syncData,
          workouts: workouts, distanceKm: distanceKm);

      // Notify open screens (e.g. the dashboard) so freshly synced data appears
      // without a manual pull-to-refresh.
      if (syncData.hasData || workouts.isNotEmpty) {
        SyncEvents.instance.notifySynced();
      }

      debugPrint('✅ Health data synced successfully');
      return syncData;
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

  /// Get steps from health data.
  ///
  /// Uses the platform's aggregated step total, which de-duplicates overlapping
  /// records from multiple Health Connect sources (Samsung Health, the phone's
  /// own counter, Google Fit, ...). Summing the raw STEPS records instead would
  /// double/triple-count and produce wildly inflated totals (e.g. 74k for a day).
  Future<int?> _getSteps(DateTime startDate, DateTime endDate) async {
    try {
      final total = await health.getTotalStepsInInterval(startDate, endDate);
      return (total != null && total > 0) ? total : null;
    } catch (e) {
      debugPrint('⚠️ Error fetching steps: $e');
      return null;
    }
  }

  /// Get heart rate statistics
  Future<Map<String, dynamic>?> _getHeartRate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startDate,
        endTime: endDate,
      );
      if (data.isEmpty) return null;
      final values = data.map(_numericValue).toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      final max = values.reduce((a, b) => a > b ? a : b);
      final min = values.reduce((a, b) => a < b ? a : b);
      return {'avg': avg, 'max': max.toInt(), 'min': min.toInt()};
    } catch (e) {
      debugPrint('⚠️ Error fetching heart rate: $e');
      return null;
    }
  }

  /// Get sleep data
  Future<Map<String, dynamic>?> _getSleep(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final sleepType = _isAndroid
          ? HealthDataType.SLEEP_SESSION
          : HealthDataType.SLEEP_IN_BED;
      final data = await health.getHealthDataFromTypes(
        types: [sleepType],
        startTime: startDate,
        endTime: endDate,
      );
      if (data.isEmpty) return null;
      final totalMinutes = data.fold<double>(0, (s, p) => s + _numericValue(p));
      final hours = totalMinutes / 60;
      String quality = 'FAIR';
      if (hours >= 7.5) quality = 'EXCELLENT';
      if (hours >= 7) quality = 'GOOD';
      if (hours < 5) quality = 'POOR';
      return {'hours': hours, 'quality': quality};
    } catch (e) {
      debugPrint('⚠️ Error fetching sleep: $e');
      return null;
    }
  }

  /// Get calories burned
  Future<int?> _getCalories(DateTime startDate, DateTime endDate) async {
    try {
      final data = await health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startDate,
        endTime: endDate,
      );
      final total = data.fold<double>(0, (s, p) => s + _numericValue(p));
      return total > 0 ? total.toInt() : null;
    } catch (e) {
      debugPrint('⚠️ Error fetching calories: $e');
      return null;
    }
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
      DateTime startDate, DateTime endDate) async {
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
        final durationSeconds =
            point.dateTo.difference(point.dateFrom).inSeconds;
        if (durationSeconds <= 0) continue;
        final durationMinutes = (durationSeconds / 60).round().clamp(1, 9999);

        // Distance: use embedded value first, fall back to DISTANCE data points.
        double? distanceKm = v.totalDistance != null
            ? v.totalDistance! / 1000.0
            : _sumPointsInWindow(distancePoints, point.dateFrom, point.dateTo) >
                    0
                ? _sumPointsInWindow(
                        distancePoints, point.dateFrom, point.dateTo) /
                    1000.0
                : null;

        // Steps: use embedded value first, fall back to STEPS data points.
        final int? steps = v.totalSteps ??
            (_sumPointsInWindow(stepsPoints, point.dateFrom, point.dateTo) > 0
                ? _sumPointsInWindow(stepsPoints, point.dateFrom, point.dateTo)
                    .toInt()
                : null);

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
      List<HealthDataPoint> points, DateTime from, DateTime to) {
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

  /// Upload synced data to backend.
  /// Workout sessions → individual sport activities with type, duration, calories, distance, steps
  /// Daily steps total → WALKING sport activity (if no workout sessions were found)
  /// Vitals (HR, sleep, calories) → health entry
  Future<void> _uploadSyncData(
    WearableSyncData data, {
    List<Map<String, dynamic>> workouts = const [],
    double? distanceKm,
  }) async {
    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) throw Exception('No active user');

      final source = _isIOS ? 'Apple Health' : 'Health Connect';
      final dateStr = data.date.toIso8601String().split('T')[0];

      debugPrint('📤 Uploading: steps=${data.steps}, '
          'hr=${data.heartRateAvg}, sleep=${data.sleepHours}, '
          'calories=${data.calories}, workouts=${workouts.length}');

      // Save each workout session as its own sport activity (with duration, type, etc.)
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
        if (w['distanceKm'] != null) {
          payload['distance'] = w['distanceKm'];
        }
        if (w['steps'] != null) {
          payload['steps'] = w['steps'];
        }
        await _api.createSportActivity(payload, userId: userId);
      }

      // Save total daily steps as a WALKING entry only when no workout sessions
      // were synced (avoids double-counting steps that are already in workouts).
      // Include distance when available from DISTANCE_WALKING_RUNNING.
      if (data.steps != null && data.steps! > 0 && workouts.isEmpty) {
        final payload = <String, dynamic>{
          'activityType': 'WALKING',
          'activityDate': dateStr,
          'steps': data.steps,
          'caloriesBurned': data.calories,
          'notes': 'Synced from $source',
        };
        if (distanceKm != null) {
          payload['distance'] = distanceKm;
        }
        await _api.createSportActivity(payload, userId: userId);
      }

      // Save vitals as a health entry via the idempotent /sync endpoint so repeated
      // foreground syncs upsert the day's row instead of stacking duplicates. We no
      // longer send a hardcoded wellbeingScore — that's the user's to log.
      final hasVitals = data.heartRateAvg != null ||
          data.sleepHours != null ||
          data.calories != null;

      if (hasVitals) {
        final payload = <String, dynamic>{
          'entryDate': dateStr,
          'notes': 'Synced from $source',
        };
        if (data.heartRateAvg != null) {
          payload['heartRate'] = data.heartRateAvg!.toInt();
        }
        if (data.sleepHours != null) payload['sleepHours'] = data.sleepHours;
        if (data.sleepQuality != null) {
          payload['sleepQuality'] = data.sleepQuality;
        }
        if (data.calories != null) payload['caloriesConsumed'] = data.calories;

        final ok = await _api.syncHealthVitals(payload, userId: userId);
        if (!ok) {
          debugPrint('⚠️ Vitals sync upsert failed');
        }
      }

      debugPrint('✅ Data uploaded to backend');
    } catch (e) {
      debugPrint('⚠️ Error uploading sync data: $e');
      rethrow;
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
                (item) => WearableDevice.fromJson(item as Map<String, dynamic>))
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
        final device =
            WearableDevice.fromJson(data['data'] as Map<String, dynamic>);
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
