import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/detective_insight.dart';
import 'api_service.dart';

class DetectiveService {
  final ApiService _api = ApiService.instance;

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

  /// Generate a new health insight (analyzes health data)
  Future<DetectiveInsight> generateInsight({
    required int userId,
    int daysBack = 7,
  }) async {
    try {
      await _api.ensureActiveUserId();

      final response = await http.get(
        _uri('/detective/analyze', queryParameters: {
          'userId': userId.toString(),
          'days': daysBack.toString(),
        }),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        return DetectiveInsight.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data['message'] ?? 'Failed to generate insight');
      }
    } catch (e) {
      debugPrint('❌ Error generating insight: $e');
      rethrow;
    }
  }

  /// Get the latest cached insight for the user
  Future<DetectiveInsight?> getLatestInsight({
    required int userId,
    String timeRange = 'WEEK',
  }) async {
    try {
      await _api.ensureActiveUserId();

      final response = await http.get(
        _uri('/detective/latest', queryParameters: {
          'userId': userId.toString(),
          'timeRange': timeRange,
        }),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        return DetectiveInsight.fromJson(data['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting latest insight: $e');
      return null;
    }
  }

  /// Get insight history for the user
  Future<List<DetectiveInsight>> getInsightHistory({
    required int userId,
    int limit = 10,
  }) async {
    try {
      await _api.ensureActiveUserId();

      final response = await http.get(
        _uri('/detective/history', queryParameters: {
          'userId': userId.toString(),
          'limit': limit.toString(),
        }),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final insights = (data['data'] as List)
            .map((item) =>
                DetectiveInsight.fromJson(item as Map<String, dynamic>))
            .toList();
        return insights;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error getting insight history: $e');
      return [];
    }
  }

  /// Ask detective a question (future enhancement)
  Future<String> askQuestion({
    required int userId,
    required String question,
  }) async {
    try {
      await _api.ensureActiveUserId();

      final response = await http.post(
        _uri('/detective/ask', queryParameters: {
          'userId': userId.toString(),
        }),
        headers: await _headers(extra: {'Content-Type': 'application/json'}),
        body: jsonEncode({'question': question}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        return data['data']?['answer'] ?? 'No response available';
      } else {
        throw Exception(data['message'] ?? 'Failed to get response');
      }
    } catch (e) {
      debugPrint('❌ Error asking question: $e');
      rethrow;
    }
  }

  /// Show success notification for insight
  static void showInsightSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.insights, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error notification
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
