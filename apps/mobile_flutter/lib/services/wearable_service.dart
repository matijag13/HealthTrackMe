import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../models/wearable_device.dart';
import 'api_service.dart';
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
      ];
    }
    return [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
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

      // Request health permissions through Health package
      final authorized = await health.requestAuthorization(_requestedDataTypes);

      if (authorized) {
        debugPrint('✅ Health permissions granted');
      } else {
        debugPrint('❌ Health permissions denied');
      }

      return authorized;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if app has permission to read health data
  Future<bool> hasPermissions() async {
    try {
      if (kIsWeb) {
        return false;
      }

      final authorized = await health.hasPermissions(_requestedDataTypes);
      return authorized ?? false;
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

      // Fetch data from Health package
      final steps = await _getSteps(startDate, endDate);
      final heartRate = await _getHeartRate(startDate, endDate);
      final sleep = await _getSleep(startDate, endDate);
      final calories = await _getCalories(startDate, endDate);

      final syncData = WearableSyncData(
        date: DateTime.now(),
        steps: steps,
        activeMinutes: null, // Can be calculated from other data
        calories: calories,
        heartRateAvg: heartRate != null ? heartRate['avg'] as double? : null,
        heartRateMax: heartRate != null ? heartRate['max'] as int? : null,
        heartRateMin: heartRate != null ? heartRate['min'] as int? : null,
        sleepHours: sleep != null ? sleep['hours'] as double? : null,
        sleepQuality: sleep != null ? sleep['quality'] as String? : null,
      );

      // Upload to backend
      await _uploadSyncData(syncData);

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

  /// Get steps from health data
  Future<int?> _getSteps(DateTime startDate, DateTime endDate) async {
    try {
      final data = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startDate,
        endTime: endDate,
      );
      final total = data.fold<double>(0, (s, p) => s + _numericValue(p));
      return total > 0 ? total.toInt() : null;
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

  /// Upload synced data to backend as a health entry
  Future<void> _uploadSyncData(WearableSyncData data) async {
    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) throw Exception('No active user');

      final payload = <String, dynamic>{
        'entryDate': data.date.toIso8601String().split('T')[0],
        'wellbeingScore': 5,
        'notes':
            'Synced from ${_isIOS ? 'Apple Health' : 'Google Fit / Health Connect'}',
      };
      if (data.heartRateAvg != null) {
        payload['heartRate'] = data.heartRateAvg!.toInt();
      }
      if (data.sleepHours != null) {
        payload['sleepHours'] = data.sleepHours;
      }
      if (data.calories != null) {
        payload['caloriesConsumed'] = data.calories;
      }

      final response = await http.post(
        _uri('/health-entries/users/$userId'),
        headers: await _headers(extra: {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['success'] == true) {
        debugPrint('✅ Data uploaded to backend');
      } else {
        debugPrint('⚠️ Backend returned error: ${result['message']}');
      }
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
