import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/detective_insight.dart';
import 'api_service.dart';

class DetectiveService {
  final ApiService _api = ApiService.instance;

  /// Generate a new health insight (analyzes health data)
  Future<DetectiveInsight> generateInsight({
    required int userId,
    int daysBack = 7,
  }) async {
    try {
      await _api.ensureActiveUserId();

      final response = await _api.get(
        '/detective/analyze',
        queryParameters: {
          'userId': userId,
          'days': daysBack,
        },
      );

      final data = jsonDecode(response) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        return DetectiveInsight.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data['message'] ?? 'Failed to generate insight');
      }
    } catch (e) {
      print('❌ Error generating insight: $e');
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

      final response = await _api.get(
        '/detective/latest',
        queryParameters: {
          'userId': userId,
          'timeRange': timeRange,
        },
      );

      final data = jsonDecode(response) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        return DetectiveInsight.fromJson(data['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('❌ Error getting latest insight: $e');
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

      final response = await _api.get(
        '/detective/history',
        queryParameters: {
          'userId': userId,
          'limit': limit,
        },
      );

      final data = jsonDecode(response) as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final insights = (data['data'] as List)
            .map((item) => DetectiveInsight.fromJson(item as Map<String, dynamic>))
            .toList();
        return insights;
      }

      return [];
    } catch (e) {
      print('❌ Error getting insight history: $e');
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

      final response = await _api.post(
        '/detective/ask',
        queryParameters: {'userId': userId},
        body: {'question': question},
      );

      final data = jsonDecode(response) as Map<String, dynamic>;

      if (data['success'] == true) {
        return data['data']?['answer'] ?? 'No response available';
      } else {
        throw Exception(data['message'] ?? 'Failed to get response');
      }
    } catch (e) {
      print('❌ Error asking question: $e');
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
