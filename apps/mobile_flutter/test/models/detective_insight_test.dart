import 'package:flutter_test/flutter_test.dart';
import 'package:healthtrackme/models/detective_insight.dart';

void main() {
  group('DetectiveInsight Model Tests', () {
    const mockInsightJson = {
      'id': 1,
      'badge': '✨ Strong week',
      'title': 'Your consistency is paying off',
      'description': 'You have been doing great this week',
      'finding': 'Keep up the good work',
      'timeRange': 'WEEK',
      'generatedAt': '2026-05-28T10:30:00.000Z',
      'createdAt': '2026-05-28T10:30:00.000Z',
    };

    test('DetectiveInsight.fromJson should parse correctly', () {
      final insight = DetectiveInsight.fromJson(mockInsightJson);

      expect(insight.id, 1);
      expect(insight.badge, '✨ Strong week');
      expect(insight.title, 'Your consistency is paying off');
      expect(insight.description, 'You have been doing great this week');
      expect(insight.finding, 'Keep up the good work');
      expect(insight.timeRange, 'WEEK');
      expect(insight.isValid, true);
    });

    test('DetectiveInsight.toJson should serialize correctly', () {
      final insight = DetectiveInsight.fromJson(mockInsightJson);
      final json = insight.toJson();

      expect(json['id'], 1);
      expect(json['badge'], '✨ Strong week');
      expect(json['title'], 'Your consistency is paying off');
    });

    test('timeRangeLabel should return correct label', () {
      final weekInsight = DetectiveInsight.fromJson({
        ...mockInsightJson,
        'timeRange': 'WEEK',
      });
      expect(weekInsight.timeRangeLabel, 'This Week');

      final monthInsight = DetectiveInsight.fromJson({
        ...mockInsightJson,
        'timeRange': 'MONTH',
      });
      expect(monthInsight.timeRangeLabel, 'This Month');
    });

    test('isValid should return true for complete insight', () {
      final insight = DetectiveInsight.fromJson(mockInsightJson);
      expect(insight.isValid, true);
    });

    test('isValid should return false for empty insight', () {
      final insight = DetectiveInsight.fromJson({
        'id': 0,
        'badge': '',
        'title': '',
        'description': '',
        'finding': '',
        'timeRange': 'WEEK',
        'generatedAt': '',
        'createdAt': '',
      });
      expect(insight.isValid, false);
    });

    test('generatedTimeAgo should calculate time correctly', () {
      final now = DateTime.now();
      final insight = DetectiveInsight.fromJson({
        ...mockInsightJson,
        'generatedAt': now.toIso8601String(),
      });

      expect(insight.generatedTimeAgo, 'Just now');
    });
  });

  group('HealthCorrelation Tests', () {
    test('HealthCorrelation.fromJson should parse correctly', () {
      const json = {
        'metric1': 'Sleep',
        'metric2': 'Heart Rate',
        'correlation': 0.75,
        'impact': 'Higher sleep = Lower resting HR (good)',
        'example': 'Example text',
      };

      final correlation = HealthCorrelation.fromJson(json);

      expect(correlation.metric1, 'Sleep');
      expect(correlation.metric2, 'Heart Rate');
      expect(correlation.correlation, 0.75);
      expect(correlation.strengthLabel, 'Very Strong');
      expect(correlation.direction, 'Positive');
      expect(correlation.emoji, '📈');
    });

    test('strengthLabel should return correct value', () {
      final strong = HealthCorrelation.fromJson({
        'metric1': 'Sleep',
        'metric2': 'HR',
        'correlation': 0.75,
        'impact': 'test',
      });
      expect(strong.strengthLabel, 'Very Strong');

      final moderate = HealthCorrelation.fromJson({
        'metric1': 'Sleep',
        'metric2': 'HR',
        'correlation': 0.45,
        'impact': 'test',
      });
      expect(moderate.strengthLabel, 'Moderate');

      final weak = HealthCorrelation.fromJson({
        'metric1': 'Sleep',
        'metric2': 'HR',
        'correlation': 0.15,
        'impact': 'test',
      });
      expect(weak.strengthLabel, 'Weak');
    });

    test('direction should return correct correlation direction', () {
      final positive = HealthCorrelation.fromJson({
        'metric1': 'A',
        'metric2': 'B',
        'correlation': 0.5,
        'impact': 'test',
      });
      expect(positive.direction, 'Positive');

      final negative = HealthCorrelation.fromJson({
        'metric1': 'A',
        'metric2': 'B',
        'correlation': -0.5,
        'impact': 'test',
      });
      expect(negative.direction, 'Negative');

      final neutral = HealthCorrelation.fromJson({
        'metric1': 'A',
        'metric2': 'B',
        'correlation': 0.0,
        'impact': 'test',
      });
      expect(neutral.direction, 'Neutral');
    });
  });
}
