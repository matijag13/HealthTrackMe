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
          print('❌ Activity recognition permission denied');
          return false;
        }
      }

      // Request health permissions through Health package
      final authorized = await health.requestAuthorization(_requestedDataTypes);

      if (authorized) {
        print('✅ Health permissions granted');
      } else {
        print('❌ Health permissions denied');
      }

      return authorized;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
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
      print('❌ Error checking permissions: $e');
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

      print(
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

      print('✅ Health data synced successfully');
      return syncData;
    } catch (e) {
      print('❌ Error syncing health data: $e');
      rethrow;
    }
  }

  /// Get steps from health data
  Future<int?> _getSteps(DateTime startDate, DateTime endDate) async {
    try {
      final types = [HealthDataType.STEPS];
      final data = await health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: endDate,
      );

      int totalSteps = 0;
      for (final point in data) {
        if (point.value is int) {
          totalSteps += point.value as int;
        }
      }

      return totalSteps > 0 ? totalSteps : null;
    } catch (e) {
      print('⚠️ Error fetching steps: $e');
      return null;
    }
  }

  /// Get heart rate statistics
  Future<Map<String, dynamic>?> _getHeartRate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final types = [HealthDataType.HEART_RATE];
      final data = await health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: endDate,
      );

      if (data.isEmpty) return null;

      final values = data
          .where((p) => p.value is num)
          .map((p) => (p.value as num).toInt())
          .toList();

      if (values.isEmpty) return null;

      final avg = values.reduce((a, b) => a + b) / values.length;
      final max = values.reduce((a, b) => a > b ? a : b);
      final min = values.reduce((a, b) => a < b ? a : b);

      return {
        'avg': avg,
        'max': max,
        'min': min,
      };
    } catch (e) {
      print('⚠️ Error fetching heart rate: $e');
      return null;
    }
  }

  /// Get sleep data
  Future<Map<String, dynamic>?> _getSleep(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final types = [HealthDataType.SLEEP_IN_BED];
      final data = await health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: endDate,
      );

      if (data.isEmpty) return null;

      double totalMinutes = 0;
      for (final point in data) {
        if (point.value is int) {
          totalMinutes += (point.value as int).toDouble();
        }
      }

      final hours = totalMinutes / 60;

      String quality = 'FAIR';
      if (hours >= 7.5) quality = 'EXCELLENT';
      if (hours >= 7) quality = 'GOOD';
      if (hours < 5) quality = 'POOR';

      return {
        'hours': hours,
        'quality': quality,
      };
    } catch (e) {
      print('⚠️ Error fetching sleep: $e');
      return null;
    }
  }

  /// Get calories burned
  Future<int?> _getCalories(DateTime startDate, DateTime endDate) async {
    try {
      final types = [HealthDataType.ACTIVE_ENERGY_BURNED];
      final data = await health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: endDate,
      );

      int totalCalories = 0;
      for (final point in data) {
        if (point.value is num) {
          totalCalories += (point.value as num).toInt();
        }
      }

      return totalCalories > 0 ? totalCalories : null;
    } catch (e) {
      print('⚠️ Error fetching calories: $e');
      return null;
    }
  }

  /// Upload synced data to backend
  Future<void> _uploadSyncData(WearableSyncData data) async {
    try {
      await _api.ensureActiveUserId();

      final endpoint =
          _isIOS ? '/wearable/sync/apple-health' : '/wearable/sync/google-fit';

      // Create health entry from synced data
      final payload = {
        'date': data.date.toIso8601String().split('T')[0],
        'heartRate': data.heartRateAvg?.toInt(),
        'sleepHours': data.sleepHours,
        'sleepQuality': data.sleepQuality,
        'waterIntakeMl': null, // Not available from wearables
        'caloriesConsumed': data.calories,
        'wellbeingScore': 5, // Default middle score
        'notes': 'Synced from ${_isIOS ? 'Apple Health' : 'Google Fit'}',
      };

      final response = await http.post(
        _uri(endpoint),
        headers: await _headers(extra: {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['success'] == true) {
        print('✅ Data uploaded to backend');
      } else {
        print('⚠️ Backend returned error: ${result['message']}');
      }
    } catch (e) {
      print('⚠️ Error uploading sync data: $e');
      rethrow;
    }
  }

  /// Get list of connected wearable devices
  Future<List<WearableDevice>> getConnectedDevices(int userId) async {
    try {
      if (kIsWeb) {
        return [];
      }

      await _api.ensureActiveUserId();

      final response = await http.get(
        _uri('/wearable/devices', queryParameters: {
          'userId': userId.toString(),
        }),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final devices = (data['data'] as List)
            .map(
                (item) => WearableDevice.fromJson(item as Map<String, dynamic>))
            .toList();
        return devices;
      }

      return [];
    } catch (e) {
      print('❌ Error fetching devices: $e');
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
      if (kIsWeb) {
        throw UnsupportedError('Wearable devices are not supported on web');
      }

      await _api.ensureActiveUserId();

      final payload = {
        'deviceName': name,
        'deviceType': type.toString().split('.').last,
        'userId': userId,
      };

      final response = await http.post(
        _uri('/wearable/devices'),
        headers: await _headers(extra: {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final device =
            WearableDevice.fromJson(data['data'] as Map<String, dynamic>);
        print('✅ Device added: ${device.name}');
        return device;
      }

      throw Exception('Failed to add device');
    } catch (e) {
      print('❌ Error adding device: $e');
      rethrow;
    }
  }

  /// Disconnect device
  Future<bool> disconnectDevice(int deviceId) async {
    try {
      if (kIsWeb) {
        return false;
      }

      await _api.ensureActiveUserId();

      final response = await http.delete(
        _uri('/wearable/devices/$deviceId'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        print('✅ Device disconnected');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error disconnecting device: $e');
      return false;
    }
  }

  /// Get sync history
  Future<List<SyncEvent>> getSyncHistory(int userId) async {
    try {
      if (kIsWeb) {
        return [];
      }

      await _api.ensureActiveUserId();

      final response = await http.get(
        _uri('/wearable/sync-history', queryParameters: {
          'userId': userId.toString(),
          'limit': '20',
        }),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final events = (data['data'] as List)
            .map((item) => SyncEvent.fromJson(item as Map<String, dynamic>))
            .toList();
        return events;
      }

      return [];
    } catch (e) {
      print('❌ Error fetching sync history: $e');
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
      print('⚠️ Error checking health data availability: $e');
      return false;
    }
  }
}
