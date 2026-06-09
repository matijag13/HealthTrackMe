import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../models/social_models.dart';

class ApiService {
  ApiService._internal();

  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;

  static const _prefsKeyBaseUrl = 'healthtrackme_api_base_url';
  static const _prefsKeyActiveUserId = 'healthtrackme_active_user_id';
  static const _prefsKeyAuthToken = 'auth_token';
  static const String _webDefault = 'http://localhost:8080/api/v1';
  static const String _androidDefault =
      'https://healthtrackme-production.up.railway.app/api/v1';

  late SharedPreferences _prefs;
  String _baseUrl = _resolveDefaultBaseUrl();
  int? _activeUserId;
  String? _authToken;
  bool _sportActivitiesEndpointMissing = false;

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) {
      return _webDefault;
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidDefault
        : _webDefault;
  }

  String get baseUrl => _baseUrl;

  int? get activeUserId => _activeUserId;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Always use the compiled-in default URL, ignoring any cached URL.
    // This ensures the correct Railway URL is used after an APK update.
    final preferred = _resolveDefaultBaseUrl();
    _baseUrl = preferred;
    await _prefs.setString(_prefsKeyBaseUrl, preferred);

    _activeUserId = _prefs.getInt(_prefsKeyActiveUserId);
    _authToken = _prefs.getString(_prefsKeyAuthToken);

    // Run reconciliation in background without blocking app startup
    _reconcileStoredActiveUserIdInBackground();
  }

  /// Reconcile active user in background without blocking app startup
  Future<void> _reconcileStoredActiveUserIdInBackground() async {
    try {
      final current = _activeUserId;
      if (current == null) {
        return;
      }

      final users = await getUsers();
      if (users.isEmpty) {
        return;
      }

      final exists = users.any((u) => u.id == current);
      if (exists) {
        return;
      }

      final selected =
          users.firstWhere((u) => u.isActive, orElse: () => users.first);
      await setActiveUserId(selected.id);
    } catch (e) {
      debugPrint('Background user reconciliation error: $e');
    }
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

  /// Per-user key for the wearable last-sync timestamp. Scoping by user id stops
  /// two accounts on the same device from sharing — and stealing — each other's
  /// sync window (which would make a fresh account's first sync pull nothing).
  String lastSyncPrefsKey(int userId) => 'health_last_sync_ms_$userId';

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    if (token == null) {
      await _prefs.remove(_prefsKeyAuthToken);
    } else {
      await _prefs.setString(_prefsKeyAuthToken, token);
    }
  }

  Future<String?> getAuthToken() async =>
      _authToken ?? _prefs.getString(_prefsKeyAuthToken);

  Future<void> clearAuthToken() async => setAuthToken(null);

  /// Full sign-out: clear the JWT and the active user so the app returns to auth.
  Future<void> resetActiveUserId() async {
    await clearAuthToken();
    await setActiveUserId(null);
  }

  static String _normalizeBaseUrl(String value) {
    var normalized = value.trim();
    if (normalized.isEmpty) {
      return _resolveDefaultBaseUrl();
    }

    normalized = normalized.replaceFirst(RegExp(r'/+$'), '');

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      final segments =
          uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
      final apiIndex = _findApiV1Index(segments);
      final canonicalSegments = apiIndex >= 0
          ? segments.sublist(0, apiIndex + 2)
          : <String>[...segments, 'api', 'v1'];
      return uri
          .replace(pathSegments: canonicalSegments)
          .toString()
          .replaceFirst(RegExp(r'/+$'), '');
    }

    final apiV1Index = normalized.indexOf('/api/v1');
    if (apiV1Index >= 0) {
      return normalized.substring(0, apiV1Index + '/api/v1'.length);
    }

    if (normalized.endsWith('/api')) {
      return '$normalized/v1';
    }
    if (normalized.endsWith('/api/v1')) {
      return normalized.replaceFirst(RegExp(r'(/api/v1)+$'), '/api/v1');
    }
    return '$normalized/api/v1';
  }

  static int _findApiV1Index(List<String> segments) {
    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] == 'api' && segments[i + 1] == 'v1') {
        return i;
      }
    }
    return -1;
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final normalizedBase = _normalizeBaseUrl(_baseUrl);
    if (normalizedBase != _baseUrl) {
      _baseUrl = normalizedBase;
    }
    final uri = Uri.parse('$normalizedBase$cleanPath')
        .replace(queryParameters: queryParameters);
    debugPrint('URI: ${uri.toString()}');
    return uri;
  }

  Map<String, String> _authHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{};
    if (extra != null) {
      headers.addAll(extra);
    }
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

  Future<http.Response> _getRaw(String path,
      {Map<String, String>? queryParameters,
      Map<String, String>? headers}) async {
    final uri = _uri(path, queryParameters: queryParameters);
    final h = _authHeaders(headers);
    final resp = await http.get(uri, headers: h);
    if (resp.statusCode == 401) {
      await _handleUnauthorized(resp);
    }
    return resp;
  }

  Future<http.Response> _postRaw(String path,
      {Object? body,
      Map<String, String>? queryParameters,
      Map<String, String>? headers}) async {
    final uri = _uri(path, queryParameters: queryParameters);
    final h = _authHeaders(headers);
    final resp = await http.post(uri, headers: h, body: body);
    if (resp.statusCode == 401) {
      await _handleUnauthorized(resp);
    }
    return resp;
  }

  Future<http.Response> _putRaw(String path,
      {Object? body,
      Map<String, String>? queryParameters,
      Map<String, String>? headers}) async {
    final uri = _uri(path, queryParameters: queryParameters);
    final h = _authHeaders(headers);
    final resp = await http.put(uri, headers: h, body: body);
    if (resp.statusCode == 401) {
      await _handleUnauthorized(resp);
    }
    return resp;
  }

  Future<http.Response> _deleteRaw(String path,
      {Map<String, String>? queryParameters,
      Map<String, String>? headers}) async {
    final uri = _uri(path, queryParameters: queryParameters);
    final h = _authHeaders(headers);
    final resp = await http.delete(uri, headers: h);
    if (resp.statusCode == 401) {
      await _handleUnauthorized(resp);
    }
    return resp;
  }

  Future<http.Response> _multipartPost(String path,
      {required File file, String fieldName = 'file'}) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders({}));
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    final multipartFile = http.MultipartFile(fieldName, stream, length,
        filename: file.path.split('/').last);
    request.files.add(multipartFile);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401) {
      await _handleUnauthorized(response);
    }
    return response;
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
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

  List<T> _parseList<T>(
      http.Response response, T Function(dynamic json) fromJson) {
    final decoded = _unwrapData(_decodeBody(response));
    if (decoded is List) {
      return decoded.map(fromJson).toList();
    }
    if (decoded is Iterable) {
      return decoded.map(fromJson).toList();
    }
    return const [];
  }

  T? _parseSingle<T>(
      http.Response response, T Function(dynamic json) fromJson) {
    final decoded = _unwrapData(_decodeBody(response));
    if (decoded == null) {
      return null;
    }
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
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }

  int? _effectiveUserId({int? userId}) => userId ?? _activeUserId;

  Future<int?> ensureActiveUserId() async {
    if (_activeUserId != null) {
      return _activeUserId;
    }
    // Derive the signed-in user from the auth token instead of listing all users
    // (the API now enforces per-user ownership).
    final id = await _currentUserIdFromToken();
    if (id != null) {
      await setActiveUserId(id);
    }
    return id;
  }

  /// Resolve the current user's id from the JWT via GET /auth/me. Returns null
  /// when there's no valid token (i.e. not signed in).
  Future<int?> _currentUserIdFromToken() async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final response = await _getRaw('/auth/me');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSingle(response, User.fromJson)?.id;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> canReachBackend() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users'))
          .timeout(const Duration(seconds: 3));
      // Any HTTP response means the server is reachable — including 401, which
      // is expected now that endpoints require auth.
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
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

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _postRaw('/auth/login',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final user = await _parseAuthAndStoreToken(response);
      if (user != null) {
        return user;
      }
    }

    if (response.statusCode == 401) {
      throw Exception('Invalid email or password.');
    }

    throw Exception(_responseMessage(response) ?? 'Could not sign in');
  }

  /// Parse an AuthResponse ({token, user}) from a login response, persist the
  /// JWT, and return the user.
  Future<User?> _parseAuthAndStoreToken(http.Response response) async {
    final decoded = _unwrapData(_decodeBody(response));
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final token = map['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await setAuthToken(token);
      }
      final userJson = map['user'];
      if (userJson != null) {
        return User.fromJson(userJson);
      }
    }
    return null;
  }

  Future<User> loginWithGoogle(String idToken) async {
    final response = await _postRaw('/auth/google',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
        }));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final user = await _parseAuthAndStoreToken(response);
      if (user != null) {
        return user;
      }
    }

    if (response.statusCode == 401) {
      throw Exception('Google sign-in failed. Please try again.');
    }

    throw Exception(_responseMessage(response) ??
        'Google sign-in failed. Please try again.');
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
    if (id == null) {
      return null;
    }
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
    try {
      final response = await _postRaw('/users',
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
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
        if (created != null) {
          // Auto-login so the new account immediately holds an auth token.
          try {
            await login(email: email, password: password);
          } catch (_) {}
          return created;
        }
      }

      final message = _responseMessage(response) ?? 'Could not create user';
      debugPrint('Create user error (${response.statusCode}): $message');
      debugPrint('Response body: ${response.body}');
      throw Exception(message);
    } catch (e) {
      debugPrint('Create user exception: $e');
      rethrow;
    }
  }

  Future<User> updateUser(int id, User user) async {
    final response = await _putRaw('/users/$id',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toUpdateJson()));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final updated = _parseSingle(response, User.fromJson);
      if (updated != null) {
        return updated;
      }
    }
    throw Exception(_responseMessage(response) ?? 'Could not update user');
  }

  Future<bool> deleteUser(int id) async {
    final response = await _deleteRaw('/users/$id');
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _putRaw('/users/$userId/password',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw Exception(_responseMessage(response) ?? 'Could not update password');
  }

  // Health Entry endpoints
  Future<List<HealthEntry>> getHealthEntries({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      return const [];
    }
    try {
      final response = await _getRaw('/health-entries/users/$id');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final entries = _parseList(response, HealthEntry.fromJson);
        entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
        if (kDebugMode) {
          debugPrint(
            'Vitals debug: getHealthEntries status=${response.statusCode} count=${entries.length}',
          );
        }
        return entries;
      }
      if (kDebugMode) {
        debugPrint(
            'Vitals debug: getHealthEntries status=${response.statusCode}');
      }
      return const [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Vitals debug: getHealthEntries error=$e');
      }
      return const [];
    }
  }

  Future<HealthEntry> createHealthEntry(HealthEntry entry,
      {int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      throw StateError('No active user selected');
    }
    final payload = entry.toJson();
    if (kDebugMode) {
      debugPrint(
        'Vitals debug: createHealthEntry payloadKeys=${_debugNonNullKeys(payload)} entryDate=${payload['entryDate']}',
      );
    }
    final response = await _postRaw('/health-entries/users/$id',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));

    if (kDebugMode) {
      debugPrint(
        'Vitals debug: createHealthEntry status=${response.statusCode}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final created = _parseSingle(response, HealthEntry.fromJson);
      if (kDebugMode) {
        debugPrint(
          'Vitals debug: createHealthEntry responseKeys=${created == null ? 'null' : _debugHealthEntryFields(created)}',
        );
      }
      if (created != null) {
        return created;
      }
    }
    throw Exception(
        _responseMessage(response) ?? 'Could not save health entry');
  }

  List<String> _debugNonNullKeys(Map<String, dynamic> payload) {
    return payload.entries
        .where((entry) => entry.value != null)
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  List<String> _debugHealthEntryFields(HealthEntry entry) {
    return entry
        .toJson()
        .entries
        .where((field) => field.value != null)
        .map((field) => field.key)
        .toList(growable: false);
  }

  // Medicine endpoints
  Future<List<Medicine>> getMedicines(
      {int? userId, bool activeOnly = false, bool throwOnError = false}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      if (throwOnError) {
        throw StateError('No active user selected');
      }
      return const [];
    }
    try {
      final path =
          activeOnly ? '/medicines/users/$id/active' : '/medicines/users/$id';
      final response = await _getRaw(path);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final medicines = _parseList(response, Medicine.fromJson);
        medicines.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return medicines;
      }
      if (throwOnError) {
        throw Exception(
            _responseMessage(response) ?? 'Could not fetch medicines');
      }
      return const [];
    } catch (e) {
      if (throwOnError) {
        rethrow;
      }
      return const [];
    }
  }

  Future<bool> createMedicine(Map<String, dynamic> payload,
      {int? userId}) async {
    final id = userId ?? await ensureActiveUserId();
    if (id == null) {
      return false;
    }

    final response = await _postRaw(
      '/medicines/users/$id',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> updateMedicine(
      int medicineId, Map<String, dynamic> payload) async {
    final response = await _putRaw(
      '/medicines/$medicineId',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // Sport activity endpoints
  Future<List<Map<String, dynamic>>> getSportActivities({int? userId}) async {
    if (_sportActivitiesEndpointMissing) {
      return const [];
    }
    final id = userId ?? await ensureActiveUserId();
    if (id == null) {
      return const [];
    }
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
          return decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _normalizeSportActivityPayload(
      Map<String, dynamic> payload) {
    final normalized = Map<String, dynamic>.from(payload);

    if (!normalized.containsKey('activityType') && normalized['type'] != null) {
      normalized['activityType'] = normalized['type'];
    }
    if (!normalized.containsKey('activityDate') &&
        normalized['start'] != null) {
      final raw = normalized['start'];
      final parsed = DateTime.tryParse(raw.toString());
      normalized['activityDate'] =
          parsed?.toIso8601String().split('T').first ?? raw.toString();
    }
    if (!normalized.containsKey('duration') &&
        normalized['durationMinutes'] != null) {
      normalized['duration'] = normalized['durationMinutes'];
    }
    if (!normalized.containsKey('distance') &&
        normalized['distanceKm'] != null) {
      normalized['distance'] = normalized['distanceKm'];
    }
    if (!normalized.containsKey('caloriesBurned') &&
        normalized['calories'] != null) {
      normalized['caloriesBurned'] = normalized['calories'];
    }

    normalized.remove('type');
    normalized.remove('durationMinutes');
    normalized.remove('distanceKm');
    normalized.remove('calories');
    normalized.remove('start');

    return normalized;
  }

  Future<bool> createSportActivity(Map<String, dynamic> payload,
      {int? userId}) async {
    if (_sportActivitiesEndpointMissing) {
      return false;
    }
    final id = userId ?? await ensureActiveUserId();
    if (id == null) {
      return false;
    }
    final response = await _postRaw(
      '/sport-activities/users/$id',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_normalizeSportActivityPayload(payload)),
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

  /// Ask the backend to email the logged-in user's health summary to their own
  /// address. Returns (success, message) so the UI can surface the server's
  /// message (e.g. "Summary sent to you@example.com" or
  /// "Email is not configured on the server").
  Future<({bool success, String message})> emailHealthSummary({
    int? userId,
  }) async {
    final id = userId ?? await ensureActiveUserId();
    if (id == null) {
      return (success: false, message: 'Not signed in');
    }
    try {
      final response = await _postRaw(
        '/export/summary/email/$id',
        headers: {'Content-Type': 'application/json'},
      );
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      final message = _responseMessage(response) ??
          (ok ? 'Summary sent' : 'Could not send summary');
      return (success: ok, message: message);
    } catch (e) {
      return (success: false, message: 'Could not send summary');
    }
  }

  /// Whether the logged-in user has opted in to the weekly AI report email.
  Future<bool> getWeeklyReport({int? userId}) async {
    final id = userId ?? await ensureActiveUserId();
    if (id == null) return false;
    try {
      final response = await _getRaw('/users/$id/weekly-report');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _unwrapData(_decodeBody(response)) == true;
      }
    } catch (_) {}
    return false;
  }

  /// Opt the user in/out of the weekly AI report email. Returns success.
  Future<bool> setWeeklyReport(bool enabled, {int? userId}) async {
    final id = userId ?? await ensureActiveUserId();
    if (id == null) return false;
    try {
      final response = await _putRaw(
        '/users/$id/weekly-report',
        queryParameters: {'enabled': enabled.toString()},
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Idempotent vitals sync — upserts the day's health entry so repeated
  /// foreground syncs update one row instead of creating duplicates.
  Future<bool> syncHealthVitals(
    Map<String, dynamic> payload, {
    int? userId,
  }) async {
    final id = userId ?? await ensureActiveUserId();
    if (id == null) {
      return false;
    }
    final response = await _postRaw(
      '/health-entries/users/$id/sync',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // Alerts endpoints
  Future<List<HealthAlertSummary>> getHealthAlerts(
      {int? userId, bool unreadOnly = false}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      return const [];
    }
    try {
      final path = unreadOnly
          ? '/health-alerts/users/$id/unread'
          : '/health-alerts/users/$id';
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

  // ===========================
  // Friends + gamification leaderboard
  // ===========================

  Future<List<LeaderboardEntry>> getLeaderboard({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final r = await _getRaw('/friends/users/$id/leaderboard');
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return _parseList(r, LeaderboardEntry.fromJson);
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Friend>> getFriends({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final r = await _getRaw('/friends/users/$id');
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return _parseList(r, Friend.fromJson);
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Friend>> getIncomingRequests({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final r = await _getRaw('/friends/users/$id/requests/incoming');
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return _parseList(r, Friend.fromJson);
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Friend>> getOutgoingRequests({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return const [];
    try {
      final r = await _getRaw('/friends/users/$id/requests/outgoing');
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return _parseList(r, Friend.fromJson);
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Sends a friend request by email. Returns null on success, or an error
  /// message (e.g. "No user with that email") to show the user.
  Future<String?> sendFriendRequest(String email, {int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return 'Not signed in';
    try {
      final r = await _postRaw(
        '/friends/users/$id/requests',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) return null;
      return _responseMessage(r) ?? 'Could not send request';
    } catch (_) {
      return 'Could not send request';
    }
  }

  /// Accept/decline a friend request. Returns null on success, or an error
  /// message (from the backend when available) to show the user.
  Future<String?> respondToFriendRequest(int friendshipId, bool accept,
      {int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return 'Not signed in';
    final action = accept ? 'accept' : 'decline';
    try {
      final r =
          await _postRaw('/friends/users/$id/requests/$friendshipId/$action');
      if (r.statusCode >= 200 && r.statusCode < 300) return null;
      return _responseMessage(r) ?? 'Could not $action request';
    } catch (_) {
      return 'Could not $action request';
    }
  }

  Future<bool> removeFriend(int friendshipId, {int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) return false;
    try {
      final r = await _deleteRaw('/friends/users/$id/$friendshipId');
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<HealthReport> getMonthlyReport(DateTime month, {int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      return HealthReport.fromEntries(
          month: month, entries: const [], medicines: const []);
    }
    try {
      final entries = await getHealthEntries(userId: id);
      final medicines = await getMedicines(userId: id, activeOnly: false);
      return HealthReport.fromEntries(
          month: month, entries: entries, medicines: medicines);
    } catch (_) {
      return HealthReport.fromEntries(
          month: month, entries: const [], medicines: const []);
    }
  }

  /// Fetches a CSV export from the given [path] and returns the raw response
  /// body as a string. Returns null on error or non-2xx status.
  /// Used by ProfileExportPage for health-entries, sport-activities, and
  /// the combined /all export.
  Future<String?> exportCsv(String path) async {
    try {
      final response = await _getRaw(path);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? response.body : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getHealthSummary({int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      return null;
    }
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
    final id = userId ?? await ensureActiveUserId();
    if (id == null) {
      return null;
    }
    try {
      var response = await _getRaw('/health-shield/$id');
      if (response.statusCode == 404 && userId == null) {
        // Active user id can become stale after DB reseeds; reconcile and retry once.
        await setActiveUserId(null);
        final reconciledId = await ensureActiveUserId();
        if (reconciledId != null && reconciledId != id) {
          response = await _getRaw('/health-shield/$reconciledId');
        }
      }
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
  Future<void> logMedicineDose(
      int medicineId, DateTime date, String status) async {
    final body = jsonEncode({
      'date': _dateOnly(date),
      'time': date.toIso8601String().split('T').last,
      'status': status
    });
    final response = await _postRaw('/medicines/$medicineId/dose',
        headers: {'Content-Type': 'application/json'}, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseMessage(response) ?? 'Could not log dose');
    }
  }

  // Compatibility methods used by UI: logDose and deleteMedicine
  Future<void> logDose(
    int medicineId,
    DateTime takenAt,
    String status,
  ) async {
    await logMedicineDose(medicineId, takenAt, status);
  }

  /// Deletes the most recent TAKEN dose for today for [medicineId].
  /// Throws if the backend returns an error (e.g. no dose taken today).
  Future<void> undoLatestDose(int medicineId) async {
    final response = await _deleteRaw('/medicines/$medicineId/dose/today');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_responseMessage(response) ?? 'Failed to undo dose');
    }
  }

  Future<void> deleteMedicine(int medicineId) async {
    final response = await _deleteRaw(
      '/medicines/$medicineId',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          _responseMessage(response) ?? 'Failed to delete medicine');
    }
  }

  Future<Map<String, dynamic>> getMedicineAdherence(int medicineId,
      {int days = 30}) async {
    final response = await _getRaw('/medicines/$medicineId/adherence',
        queryParameters: {'days': days.toString()});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _unwrapData(_decodeBody(response));
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {};
    }
    throw Exception(_responseMessage(response) ?? 'Could not fetch adherence');
  }

  // Vitals history
  Future<List<Map<String, dynamic>>> getVitalsHistory(String metric,
      {int days = 90, int? userId}) async {
    final id = _effectiveUserId(userId: userId);
    if (id == null) {
      return const [];
    }
    final response = await _getRaw('/health-entries/vitals-history',
        queryParameters: {
          'userId': id.toString(),
          'metric': metric,
          'days': days.toString()
        });
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = _unwrapData(_decodeBody(response));
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return const [];
    }
    throw Exception(
        _responseMessage(response) ?? 'Could not fetch vitals history');
  }

  // Profile photo upload
  Future<void> uploadProfilePhoto(File imageFile) async {
    final id = _activeUserId;
    if (id == null) {
      throw StateError('No active user');
    }
    final response =
        await _multipartPost('/users/$id/profile-photo', file: imageFile);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          _responseMessage(response) ?? 'Could not upload profile photo');
    }
  }

  Future<User?> refreshCurrentUser() async {
    final id = _activeUserId;
    if (id == null) {
      return null;
    }
    await setActiveUserId(null);
    await setActiveUserId(id);
    return getCurrentUser();
  }
}
