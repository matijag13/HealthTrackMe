import 'dart:convert';
import 'dart:io';

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
  static const _prefsKeyAuthToken = 'auth_token';
  static const String _webDefault = 'http://localhost:8081/api/v1';
  static const String _androidDefault = 'http://10.0.2.2:8080/api/v1';

  late SharedPreferences _prefs;
  String _baseUrl = _resolveDefaultBaseUrl();
  int? _activeUserId;
  String? _authToken;
  bool _sportActivitiesEndpointMissing = false;

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
    _authToken = _prefs.getString(_prefsKeyAuthToken);

    // Repair stale persisted user selection (e.g. deleted user id) when backend is reachable.
    await _reconcileStoredActiveUserId();
  }

  Future<void> _reconcileStoredActiveUserId() async {
    final current = _activeUserId;
    if (current == null) return;

    final users = await getUsers();
    if (users.isEmpty) return;

    final exists = users.any((u) => u.id == current);
    if (exists) return;

    final selected = users.firstWhere((u) => u.isActive, orElse: () => users.first);
    await setActiveUserId(selected.id);
  }

  Future<void> setBaseUrl(String value) async {
    final normalized = _normalizeBaseUrl(value);
    _baseUrl = normalized;
    _sportActivitiesEndpointMissing = false;
    await _prefs.setString(_prefsKeyBaseUrl, normalized);
  }

  Future<void> resetBaseUrl() async {
    _baseUrl = _resolveDefaultBaseUrl();
    _sportActivitiesEndpointMissing = false;
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

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    if (token == null) {
      await _prefs.remove(_prefsKeyAuthToken);
    } else {
      await _prefs.setString(_prefsKeyAuthToken, token);
    }
  }

  Future<String?> getAuthToken() async => _authToken ?? _prefs.getString(_prefsKeyAuthToken);

  Future<void> clearAuthToken() async => setAuthToken(null);

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

  Map<String, String> _authHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{};
    if (extra != null) headers.addAll(extra);
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<void> _handleUnauthorized(http.Response response) async {
    if (response.statusCode == 401) {
      // clear token and active user so router will redirect to auth
      await clearAuthToken();
      await setActiveUserId(null);
    }
  }

  Future<http.Response> _getRaw(String path, {Map<String, String>? queryParameters, Map<String, String>? headers}) async {
    final uri = _uri(path, queryParameters: queryParameters);
    final h = _authHeaders(headers);
    final resp = await http.get(uri, headers: h);
    if (resp.statusCode == 401) await _handleUnauthorized(resp);
    return resp;
  }

  Future<http.Response> _postRaw(String path, {Object? body, Map<String, String>? queryParameters, Map<String, String>? headers}) async {
    final uri = _uri(path, queryParameters: queryParameters);
    final h = _authHeaders(headers);
    final resp = await http.post(uri, headers: h, body: body);
    if (resp.statusCode == 401) await _handleUnauthorized(resp);
    return resp;
  }

  Future<http.Response> _putRaw(String path, {Object? body, Map<String, String>? queryParameters, Map<String, String>? headers}) async {
    final uri = _uri(path, queryParameters: queryParameters);
    final h = _authHeaders(headers);
    final resp = await http.put(uri, headers: h, body: body);
    if (resp.statusCode == 401) await _handleUnauthorized(resp);
    return resp;
  }

  Future<http.Response> _deleteRaw(String path, {Map<String, String>? queryParameters, Map<String, String>? headers}) async {
    final uri = _uri(path, queryParameters: queryParameters);
    final h = _authHeaders(headers);
    final resp = await http.delete(uri, headers: h);
    if (resp.statusCode == 401) await _handleUnauthorized(resp);
    return resp;
  }

  Future<http.Response> _multipartPost(String path, {required File file, String fieldName = 'file'}) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders({}));
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    final multipartFile = http.MultipartFile(fieldName, stream, length, filename: file.path.split('/').last);
    request.files.add(multipartFile);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401) await _handleUnauthorized(response);
    return response;
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
    final users = await getUsers();
    if (users.isEmpty) {
      await setActiveUserId(null);
      return null;
    }

    if (_activeUserId != null) {
      final exists = users.any((user) => user.id == _activeUserId);
      if (exists) return _activeUserId;
    }

    final selected = users.firstWhere((user) => user.isActive, orElse: () => users.first);
    await setActiveUserId(selected.id);
    return selected.id;
  }

  Future<bool> canReachBackend() async {
    return _canReachUrl(baseUrl);
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await _getRaw('/users');
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
      final response = await _getRaw('/users/$id');
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
    final response = await _postRaw('/users', headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'userType': userType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
    }));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final created = _parseSingle(response, User.fromJson);
      if (created != null) return created;
    }
    throw Exception(_responseMessage(response) ?? 'Could not create user');
  }

  Future<User> updateUser(int id, User user) async {
    final response = await _putRaw('/users/$id', headers: {'Content-Type': 'application/json'}, body: jsonEncode(user.toUpdateJson()));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final updated = _parseSingle(response, User.fromJson);
      if (updated != null) return updated;
    }
    throw Exception(_responseMessage(response) ?? 'Could not update user');
  }

  Future<bool> deleteUser(int id) async {
    final response = await _deleteRaw('/users/$id');
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // Health Entry endpoints
  Future<List<HealthEntry>> getHealthEntries({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final response = await _getRaw('/health-entries/users/$id');
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
    final response = await _postRaw('/health-entries/users/$id', headers: {'Content-Type': 'application/json'}, body: jsonEncode(entry.toJson()));

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
      final response = await _getRaw(path);
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

  // Sport activity endpoints
  Future<List<Map<String, dynamic>>> getSportActivities({int? userId}) async {
    if (_sportActivitiesEndpointMissing) return const [];
    final id = userId ?? await ensureActiveUserId();
    if (id == null) return const [];
    try {
      final response = await _getRaw('/sport-activities/users/$id');
      if (response.statusCode == 404) {
        // Some backend builds don't expose this endpoint; avoid repeated console/network spam.
        _sportActivitiesEndpointMissing = true;
        return const [];
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _unwrapData(_decodeBody(response));
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<bool> createSportActivity(Map<String, dynamic> payload, {int? userId}) async {
    if (_sportActivitiesEndpointMissing) return false;
    final id = userId ?? await ensureActiveUserId();
    if (id == null) return false;
    final response = await _postRaw(
      '/sport-activities/users/$id',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 404) {
      _sportActivitiesEndpointMissing = true;
      return false;
    }
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> deleteSportActivity(int activityId) async {
    final response = await _deleteRaw('/sport-activities/$activityId');
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // Alerts endpoints
  Future<List<HealthAlertSummary>> getHealthAlerts({int? userId, bool unreadOnly = false}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final path = unreadOnly ? '/health-alerts/users/$id/unread' : '/health-alerts/users/$id';
      final response = await _getRaw(path);
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
      final response = await _getRaw('/export/summary/$id');
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
      final response = await _getRaw('/health-shield/$id');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSingle(response, HealthShield.fromJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching health shield: $e');
      return null;
    }
  }
  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  // Dose logging
  Future<void> logMedicineDose(int medicineId, DateTime date, String status) async {
    final body = jsonEncode({'date': _dateOnly(date), 'time': date.toIso8601String().split('T').last, 'status': status});
    final response = await _postRaw('/medicines/$medicineId/dose', headers: {'Content-Type': 'application/json'}, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseMessage(response) ?? 'Could not log dose');
    }
  }

  Future<Map<String, dynamic>> getMedicineAdherence(int medicineId, {int days = 30}) async {
    final response = await _getRaw('/medicines/$medicineId/adherence', queryParameters: {'days': days.toString()});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _unwrapData(_decodeBody(response));
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    }
    throw Exception(_responseMessage(response) ?? 'Could not fetch adherence');
  }

  // Vitals history
  Future<List<Map<String, dynamic>>> getVitalsHistory(String metric, {int days = 90, int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    final response = await _getRaw('/health-entries/vitals-history', queryParameters: {'userId': id.toString(), 'metric': metric, 'days': days.toString()});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = _unwrapData(_decodeBody(response));
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return const [];
    }
    throw Exception(_responseMessage(response) ?? 'Could not fetch vitals history');
  }

  // Profile photo upload
  Future<void> uploadProfilePhoto(File imageFile) async {
    final id = _activeUserId;
    if (id == null) throw StateError('No active user');
    final response = await _multipartPost('/users/$id/profile-photo', file: imageFile);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseMessage(response) ?? 'Could not upload profile photo');
    }
  }

  Future<User?> refreshCurrentUser() async {
    final id = _activeUserId;
    if (id == null) return null;
    await setActiveUserId(null);
    await setActiveUserId(id);
    return getCurrentUser();
  }
}
