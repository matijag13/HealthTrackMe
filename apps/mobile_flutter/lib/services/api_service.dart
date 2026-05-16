import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class ApiService {
  ApiService._internal();

  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;

  static const _prefsKey = 'healthtrackme_api_base_url';
  static const String _webDefault = 'http://localhost:8080/api';
  static const String _androidDefault = 'http://10.0.2.2:8080/api';

  late SharedPreferences _prefs;
  String _baseUrl = _resolveDefaultBaseUrl();

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) return _webDefault;
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidDefault
        : _webDefault;
  }

  String get baseUrl => _baseUrl;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _baseUrl = _prefs.getString(_prefsKey) ?? _baseUrl;
  }

  Future<void> setBaseUrl(String value) async {
    var normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (!normalized.endsWith('/api')) {
      normalized = '$normalized/api';
    }
    _baseUrl = normalized;
    await _prefs.setString(_prefsKey, normalized);
  }

  Future<void> resetBaseUrl() async {
    _baseUrl = _resolveDefaultBaseUrl();
    await _prefs.remove(_prefsKey);
  }

  Future<bool> canReachBackend() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health-entries'),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode >= 100;
    } catch (_) {
      return false;
    }
  }

  // Health Entry endpoints
  Future<List<HealthEntry>> getHealthEntries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health-entries'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => HealthEntry.fromJson(e)).toList();
      } else {
        return DemoData.healthEntries();
      }
    } catch (e) {
      return DemoData.healthEntries();
    }
  }

  Future<HealthEntry> createHealthEntry(HealthEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/health-entries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(entry.toJson()),
      );

      if (response.statusCode == 201) {
        return HealthEntry.fromJson(jsonDecode(response.body));
      } else {
        return entry;
      }
    } catch (e) {
      return entry;
    }
  }

  // Medicine endpoints
  Future<List<Medicine>> getMedicines() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicines'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Medicine.fromJson(e)).toList();
      } else {
        return DemoData.medicines();
      }
    } catch (e) {
      return DemoData.medicines();
    }
  }

  // Reports endpoints
  Future<HealthReport> getMonthlyReport(DateTime month) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/reports/monthly?month=${month.year}-${month.month.toString().padLeft(2, '0')}'),
      );

      if (response.statusCode == 200) {
        return HealthReport.fromJson(jsonDecode(response.body));
      } else {
        return DemoData.monthlyReport();
      }
    } catch (e) {
      return DemoData.monthlyReport();
    }
  }

  // Alerts endpoints
  Future<List<HealthAlertSummary>> getHealthAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health-alerts'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .whereType<Map<String, dynamic>>()
            .map(HealthAlertSummary.fromJson)
            .toList();
      } else {
        return DemoData.alerts();
      }
    } catch (e) {
      return DemoData.alerts();
    }
  }
}
