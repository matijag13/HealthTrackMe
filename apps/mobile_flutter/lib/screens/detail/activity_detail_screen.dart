import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  int _selectedDays = 7;

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
          'Activity Summary',
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
            // Summary Stats
            _buildActivitySummary(context),
            const SizedBox(height: 24),

            // Time Range Selector
            _buildTimeRangeSelector(context),
            const SizedBox(height: 20),

            // Daily Steps Chart
            _buildDailyStepsCard(context),
            const SizedBox(height: 20),

            // Activity Types
            _buildActivityTypesCard(context),
            const SizedBox(height: 20),

            // Trends
            _buildTrendsCard(context),
            const SizedBox(height: 20),

            // Goals Progress
            _buildGoalsCard(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          context,
          label: 'Steps',
          value: '8,247',
          unit: 'today',
          color: AppColors.primaryGreen,
        ),
        _buildStatCard(
          context,
          label: 'Exercise',
          value: '45',
          unit: 'min',
          color: AppColors.primaryBlue,
        ),
        _buildStatCard(
          context,
          label: 'Calories',
          value: '520',
          unit: 'kcal',
          color: AppColors.primaryOrange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          left: BorderSide(color: color, width: 3),
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
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
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

  Widget _buildDailyStepsCard(BuildContext context) {
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
            'Daily Steps Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildDayProgressBar(context, 'Mon', 8500, 10000),
              const SizedBox(height: 10),
              _buildDayProgressBar(context, 'Tue', 9200, 10000),
              const SizedBox(height: 10),
              _buildDayProgressBar(context, 'Wed', 7300, 10000),
              const SizedBox(height: 10),
              _buildDayProgressBar(context, 'Thu', 8800, 10000),
              const SizedBox(height: 10),
              _buildDayProgressBar(context, 'Fri', 10500, 10000),
              const SizedBox(height: 10),
              _buildDayProgressBar(context, 'Sat', 9200, 10000),
              const SizedBox(height: 10),
              _buildDayProgressBar(context, 'Sun', 8247, 10000),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayProgressBar(BuildContext context, String day, int steps, int goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (steps / goal).clamp(0.0, 1.0);

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
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '$steps',
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

  Widget _buildActivityTypesCard(BuildContext context) {
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
            'Activity Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _buildActivityType(context, '🏃 Running', '12.5 km', 3, AppColors.primaryGreen),
          const SizedBox(height: 12),
          _buildActivityType(context, '🚴 Cycling', '8.2 km', 2, AppColors.primaryBlue),
          const SizedBox(height: 12),
          _buildActivityType(context, '🏊 Swimming', '1.2 km', 1, AppColors.primaryOrange),
        ],
      ),
    );
  }

  Widget _buildActivityType(
    BuildContext context,
    String activity,
    String distance,
    int sessions,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$distance • $sessions sessions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsCard(BuildContext context) {
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
          Text(
            '📈 Weekly Trends',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildTrendRow(
            context,
            'Avg Steps/Day',
            '8,967',
            '↑ 12% vs last week',
            AppColors.primaryGreen,
          ),
          const SizedBox(height: 12),
          _buildTrendRow(
            context,
            'Total Exercise',
            '4h 22m',
            '↑ 8% consistency',
            AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow(
    BuildContext context,
    String label,
    String value,
    String trend,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 2),
            Text(
              trend,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildGoalsCard(BuildContext context) {
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
            'Weekly Goals',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _buildGoal(context, 'Steps Goal', 70000, 58900),
          const SizedBox(height: 16),
          _buildGoal(context, 'Exercise Goal', 250, 311),
        ],
      ),
    );
  }

  Widget _buildGoal(BuildContext context, String label, int goal, int current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (current / goal).clamp(0.0, 1.0);
    final isComplete = current >= goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isComplete ? AppColors.primaryGreen : AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? AppColors.primaryGreen : AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$current / $goal',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
