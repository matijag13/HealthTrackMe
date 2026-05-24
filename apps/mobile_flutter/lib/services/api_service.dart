import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class ApiService {
  ApiService._internal();

  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;

  static const _prefsKeyBaseUrl = 'healthtrackme_api_base_url';
  static const _prefsKeyActiveUserId = 'healthtrackme_active_user_id';
  static const String _webDefault = 'http://localhost:8081/api/v1';
  static const String _androidDefault = 'http://10.0.2.2:8080/api/v1';

  late SharedPreferences _prefs;
  String _baseUrl = _resolveDefaultBaseUrl();
  int? _activeUserId;

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) return _webDefault;
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidDefault
        : _webDefault;
  }

  String get baseUrl => _baseUrl;

  int? get activeUserId => _activeUserId;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs.getString(_prefsKeyBaseUrl);
    final preferred = _normalizeBaseUrl(stored ?? _baseUrl);
    _baseUrl = await _resolveReachableBaseUrl(preferredBaseUrl: preferred);
    if (_baseUrl != preferred) {
      await _prefs.setString(_prefsKeyBaseUrl, _baseUrl);
    }
    _activeUserId = _prefs.getInt(_prefsKeyActiveUserId);
  }

  Future<void> setBaseUrl(String value) async {
    final normalized = _normalizeBaseUrl(value);
    _baseUrl = normalized;
    await _prefs.setString(_prefsKeyBaseUrl, normalized);
  }

  Future<void> resetBaseUrl() async {
    _baseUrl = _resolveDefaultBaseUrl();
    await _prefs.remove(_prefsKeyBaseUrl);
  }

  Future<void> setActiveUserId(int? userId) async {
    _activeUserId = userId;
    if (userId == null) {
      await _prefs.remove(_prefsKeyActiveUserId);
    } else {
      await _prefs.setInt(_prefsKeyActiveUserId, userId);
    }
  }

  Future<void> resetActiveUserId() => setActiveUserId(null);

  static String _normalizeBaseUrl(String value) {
    var normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.endsWith('/api/v1')) return normalized;
    if (normalized.endsWith('/api')) return '$normalized/v1';
    return '$normalized/api/v1';
  }

  List<String> _webFallbackBaseUrls() {
    return [
      'http://localhost:8081/api/v1',
      'http://localhost:8080/api/v1',
    ];
  }

  Future<bool> _canReachUrl(String baseUrl) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users')).timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<String> _resolveReachableBaseUrl({required String preferredBaseUrl}) async {
    final candidates = <String>[];
    if (kIsWeb) {
      candidates.add(preferredBaseUrl);
      for (final fallback in _webFallbackBaseUrls()) {
        if (!candidates.contains(fallback)) candidates.add(fallback);
      }
    } else {
      candidates.add(preferredBaseUrl);
    }

    for (final candidate in candidates) {
      if (await _canReachUrl(candidate)) {
        return candidate;
      }
    }

    return preferredBaseUrl;
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$cleanPath').replace(queryParameters: queryParameters);
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  dynamic _unwrapData(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('data')) return decoded['data'];
      return decoded;
    }
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map.containsKey('data')) return map['data'];
      return map;
    }
    return decoded;
  }

  List<T> _parseList<T>(http.Response response, T Function(dynamic json) fromJson) {
    final decoded = _unwrapData(_decodeBody(response));
    if (decoded is List) {
      return decoded.map(fromJson).toList();
    }
    if (decoded is Iterable) {
      return decoded.map(fromJson).toList();
    }
    return const [];
  }

  T? _parseSingle<T>(http.Response response, T Function(dynamic json) fromJson) {
    final decoded = _unwrapData(_decodeBody(response));
    if (decoded == null) return null;
    if (decoded is Map<String, dynamic> || decoded is Map) {
      return fromJson(decoded);
    }
    return null;
  }

  String? _responseMessage(http.Response response) {
    final decoded = _decodeBody(response);
    final data = _unwrapData(decoded);
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final message = map['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  int? _effectiveUserId({int? userId}) => userId ?? _activeUserId;

  Future<int?> ensureActiveUserId() async {
    if (_activeUserId != null) return _activeUserId;
    final users = await getUsers();
    if (users.isEmpty) return null;
    final selected = users.firstWhere((user) => user.isActive, orElse: () => users.first);
    await setActiveUserId(selected.id);
    return selected.id;
  }

  Future<bool> canReachBackend() async {
    return _canReachUrl(baseUrl);
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(_uri('/users'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseList(response, User.fromJson);
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<User?> getUser(int id) async {
    try {
      final response = await http.get(_uri('/users/$id'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSingle(response, User.fromJson);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    final id = await ensureActiveUserId();
    if (id == null) return null;
    return getUser(id);
  }

  Future<User> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String userType,
    String? medicalConditions,
    String? allergies,
  }) async {
    final response = await http.post(
      _uri('/users'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'userType': userType,
        'medicalConditions': medicalConditions,
        'allergies': allergies,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final created = _parseSingle(response, User.fromJson);
      if (created != null) return created;
    }
    throw Exception(_responseMessage(response) ?? 'Could not create user');
  }

  Future<User> updateUser(int id, User user) async {
    final response = await http.put(
      _uri('/users/$id'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(user.toUpdateJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final updated = _parseSingle(response, User.fromJson);
      if (updated != null) return updated;
    }
    throw Exception(_responseMessage(response) ?? 'Could not update user');
  }

  Future<bool> deleteUser(int id) async {
    final response = await http.delete(_uri('/users/$id'));
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // Health Entry endpoints
  Future<List<HealthEntry>> getHealthEntries({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final response = await http.get(_uri('/health-entries/users/$id'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final entries = _parseList(response, HealthEntry.fromJson);
        entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
        return entries;
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<HealthEntry> createHealthEntry(HealthEntry entry, {int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      throw StateError('No active user selected');
    }
    final response = await http.post(
      _uri('/health-entries/users/$id'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final created = _parseSingle(response, HealthEntry.fromJson);
      if (created != null) return created;
    }
    throw Exception(_responseMessage(response) ?? 'Could not save health entry');
  }

  // Medicine endpoints
  Future<List<Medicine>> getMedicines({int? userId, bool activeOnly = false}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final path = activeOnly ? '/medicines/users/$id/active' : '/medicines/users/$id';
      final response = await http.get(_uri(path));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final medicines = _parseList(response, Medicine.fromJson);
        medicines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return medicines;
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  // Alerts endpoints
  Future<List<HealthAlertSummary>> getHealthAlerts({int? userId, bool unreadOnly = false}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final path = unreadOnly ? '/health-alerts/users/$id/unread' : '/health-alerts/users/$id';
      final response = await http.get(_uri(path));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final alerts = _parseList(response, HealthAlertSummary.fromJson);
        alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return alerts;
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<HealthReport> getMonthlyReport(DateTime month, {int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      return HealthReport.fromEntries(month: month, entries: const [], medicines: const []);
    }
    try {
      final entries = await getHealthEntries(userId: id);
      final medicines = await getMedicines(userId: id, activeOnly: false);
      return HealthReport.fromEntries(month: month, entries: entries, medicines: medicines);
    } catch (_) {
      return HealthReport.fromEntries(month: month, entries: const [], medicines: const []);
    }
  }

  Future<String?> getHealthSummary({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return null;
    try {
      final response = await http.get(_uri('/export/summary/$id'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _unwrapData(_decodeBody(response));
        return decoded?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Health Shield endpoint
  Future<HealthShield?> getHealthShield({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return null;
    try {
      final response = await http.get(_uri('/health-shield/$id'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSingle(response, HealthShield.fromJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching health shield: $e');
      return null;
    }
  }
}
