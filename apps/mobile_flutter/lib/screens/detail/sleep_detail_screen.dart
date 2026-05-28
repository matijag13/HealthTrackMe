import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SleepDetailScreen extends StatefulWidget {
  const SleepDetailScreen({super.key});

  @override
  State<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends State<SleepDetailScreen> {
  int _selectedDays = 7; // 7, 30, or 90 days view

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sleep Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryRow(context),
            const SizedBox(height: 24),

            // Time Range Selector
            _buildTimeRangeSelector(context),
            const SizedBox(height: 20),

            // Sleep Quality Chart
            _buildSleepQualityCard(context),
            const SizedBox(height: 20),

            // Sleep Stages Breakdown
            _buildSleepStagesCard(context),
            const SizedBox(height: 20),

            // HRV Impact Section
            _buildHRVImpactCard(context),
            const SizedBox(height: 20),

            // Insights
            _buildInsightsCard(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            label: 'Avg Sleep',
            value: '7h 34m',
            subtitle: 'This week',
            accentColor: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            label: 'Sleep Score',
            value: '92%',
            subtitle: 'Excellent',
            accentColor: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(BuildContext context) {
    return Row(
      children: [
        _buildTimeRangeButton(context, '7D', 7),
        const SizedBox(width: 8),
        _buildTimeRangeButton(context, '30D', 30),
        const SizedBox(width: 8),
        _buildTimeRangeButton(context, '90D', 90),
      ],
    );
  }

  Widget _buildTimeRangeButton(BuildContext context, String label, int days) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedDays == days;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDays = days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            border: isSelected
                ? null
                : Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepQualityCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep Quality This Week',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // Simple bar chart representation
          Column(
            children: [
              _buildWeekDayBar(context, 'Mon', 0.85),
              const SizedBox(height: 8),
              _buildWeekDayBar(context, 'Tue', 0.92),
              const SizedBox(height: 8),
              _buildWeekDayBar(context, 'Wed', 0.78),
              const SizedBox(height: 8),
              _buildWeekDayBar(context, 'Thu', 0.88),
              const SizedBox(height: 8),
              _buildWeekDayBar(context, 'Fri', 0.95),
              const SizedBox(height: 8),
              _buildWeekDayBar(context, 'Sat', 0.92),
              const SizedBox(height: 8),
              _buildWeekDayBar(context, 'Sun', 0.89),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayBar(BuildContext context, String day, double score) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            day,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepStagesCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep Stages Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _buildStageRow(context, 'Light Sleep', '3h 24m', 45, AppColors.primaryBlue),
          const SizedBox(height: 12),
          _buildStageRow(context, 'Deep Sleep', '2h 45m', 36, AppColors.primaryGreen),
          const SizedBox(height: 12),
          _buildStageRow(context, 'REM Sleep', '1h 25m', 19, AppColors.primaryOrange),
        ],
      ),
    );
  }

  Widget _buildStageRow(
    BuildContext context,
    String label,
    String duration,
    int percent,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildHRVImpactCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryGreen.withValues(alpha: 0.08)
            : AppColors.primaryGreen.withValues(alpha: 0.05),
        border: Border.all(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.2)
              : AppColors.primaryGreen.withValues(alpha: 0.15),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '💚 HRV Impact',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Optimal',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your consistent sleep schedule has improved HRV by 15% this week. Deep sleep correlates strongly with higher HRV readings.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryOrange.withValues(alpha: 0.08)
            : AppColors.primaryOrange.withValues(alpha: 0.05),
        border: Border.all(
          color: isDark
              ? AppColors.primaryOrange.withValues(alpha: 0.2)
              : AppColors.primaryOrange.withValues(alpha: 0.15),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Insights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            context,
            '📅 Consistency',
            'Sleep within 1 hour of your bedtime for best results',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            context,
            '☕ Caffeine',
            'Avoid caffeine after 2pm to maintain deep sleep quality',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            context,
            '🏃 Exercise',
            'Morning workouts improve sleep quality by 12% vs evening',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
        ),
      ],
    );
  }
}
