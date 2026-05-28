class DetectiveInsight {
  final int id;
  final String badge;
  final String title;
  final String description;
  final String finding;
  final String timeRange;
  final String generatedAt;
  final String createdAt;

  DetectiveInsight({
    required this.id,
    required this.badge,
    required this.title,
    required this.description,
    required this.finding,
    required this.timeRange,
    required this.generatedAt,
    required this.createdAt,
  });

  factory DetectiveInsight.fromJson(Map<String, dynamic> json) {
    return DetectiveInsight(
      id: json['id'] as int? ?? 0,
      badge: json['badge'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      finding: json['finding'] as String? ?? '',
      timeRange: json['timeRange'] as String? ?? 'WEEK',
      generatedAt: json['generatedAt'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'badge': badge,
      'title': title,
      'description': description,
      'finding': finding,
      'timeRange': timeRange,
      'generatedAt': generatedAt,
      'createdAt': createdAt,
    };
  }

  /// Check if insight is valid (has content)
  bool get isValid => id > 0 && title.isNotEmpty;

  /// Get time range label
  String get timeRangeLabel {
    switch (timeRange.toUpperCase()) {
      case 'WEEK':
        return 'This Week';
      case 'MONTH':
        return 'This Month';
      case 'ALL_TIME':
        return 'All Time';
      default:
        return timeRange;
    }
  }

  /// Parse generated time to readable format
  String get generatedTimeAgo {
    try {
      final generated = DateTime.parse(generatedAt);
      final now = DateTime.now();
      final diff = now.difference(generated);

      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${(diff.inDays / 7).floor()}w ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}

class HealthCorrelation {
  final String metric1;
  final String metric2;
  final double correlation;
  final String impact;
  final String? example;

  HealthCorrelation({
    required this.metric1,
    required this.metric2,
    required this.correlation,
    required this.impact,
    this.example,
  });

  factory HealthCorrelation.fromJson(Map<String, dynamic> json) {
    return HealthCorrelation(
      metric1: json['metric1'] as String? ?? '',
      metric2: json['metric2'] as String? ?? '',
      correlation: (json['correlation'] as num?)?.toDouble() ?? 0.0,
      impact: json['impact'] as String? ?? '',
      example: json['example'] as String?,
    );
  }

  /// Get correlation strength label
  String get strengthLabel {
    final absCorr = correlation.abs();
    if (absCorr >= 0.7) {
      return 'Very Strong';
    }
    if (absCorr >= 0.5) {
      return 'Strong';
    }
    if (absCorr >= 0.3) {
      return 'Moderate';
    }
    return 'Weak';
  }

  /// Get correlation direction
  String get direction {
    if (correlation > 0) {
      return 'Positive';
    }
    if (correlation < 0) {
      return 'Negative';
    }
    return 'Neutral';
  }

  /// Get emoji representation
  String get emoji {
    if (correlation > 0.5) {
      return '📈';
    }
    if (correlation < -0.5) {
      return '📉';
    }
    if (correlation.abs() > 0.3) {
      return '⬌';
    }
    return '➡️';
  }
}
