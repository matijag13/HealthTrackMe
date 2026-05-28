import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/detective_insight_card.dart';
import '../widgets/dashboard_bottom_nav.dart';
import '../widgets/quick_log_fab.dart';
import '../dialogs/quick_log_dialogs.dart';
import '../services/quick_log_service.dart';
import 'detail/sleep_detail_screen.dart';
import 'detail/activity_detail_screen.dart';
import 'detail/heart_rate_detail_screen.dart';
import 'detail/medications_detail_screen.dart';

class DarkModeDashboardScreen extends StatefulWidget {
  const DarkModeDashboardScreen({super.key});

  @override
  State<DarkModeDashboardScreen> createState() =>
      _DarkModeDashboardScreenState();
}

class _DarkModeDashboardScreenState extends State<DarkModeDashboardScreen> {
  final ApiService _api = ApiService.instance;
  final QuickLogService _quickLogService = QuickLogService();
  List<HealthEntry> _entries = [];
  List<Map<String, dynamic>> _sportActivities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _handleQuickLog(String logType) async {
    dynamic result;

    switch (logType) {
      case 'mood':
        result = await showDialog(
          context: context,
          builder: (context) => const MoodLogDialog(),
        );
        if (result != null && mounted) {
          final success = await _quickLogService.logMood(result['mood']);
          if (!mounted) return;
          if (success) {
            QuickLogService.showLogSuccess(context, '✨ Mood logged!');
          } else {
            QuickLogService.showLogError(context, 'Failed to log mood');
          }
        }
        break;

      case 'water':
        result = await showDialog(
          context: context,
          builder: (context) => const WaterLogDialog(),
        );
        if (result != null && mounted) {
          final success = await _quickLogService.logWater(result['water_ml']);
          if (!mounted) return;
          if (success) {
            QuickLogService.showLogSuccess(context, '💧 Water logged!');
          } else {
            QuickLogService.showLogError(context, 'Failed to log water');
          }
        }
        break;

      case 'medication':
        result = await showDialog(
          context: context,
          builder: (context) => const MedicationLogDialog(),
        );
        if (result != null && mounted) {
          final success =
              await _quickLogService.logMedication(result['medication']);
          if (!mounted) return;
          if (success) {
            QuickLogService.showLogSuccess(context, '💊 Medication logged!');
          } else {
            QuickLogService.showLogError(context, 'Failed to log medication');
          }
        }
        break;

      case 'symptom':
        result = await showDialog(
          context: context,
          builder: (context) => const SymptomLogDialog(),
        );
        if (result != null && mounted) {
          final success = await _quickLogService.logSymptoms(
            List<String>.from(result['symptoms']),
          );
          if (!mounted) return;
          if (success) {
            QuickLogService.showLogSuccess(context, '📝 Symptoms logged!');
          } else {
            QuickLogService.showLogError(context, 'Failed to log symptoms');
          }
        }
        break;

      case 'sleep':
        result = await showDialog(
          context: context,
          builder: (context) => const SleepLogDialog(),
        );
        if (result != null && mounted) {
          final success = await _quickLogService.logSleep(
            result['sleep_hours'],
            result['sleep_minutes'],
          );
          if (!mounted) return;
          if (success) {
            QuickLogService.showLogSuccess(context, '😴 Sleep logged!');
          } else {
            QuickLogService.showLogError(context, 'Failed to log sleep');
          }
        }
        break;
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await _api.ensureActiveUserId();
      final entries = await _api.getHealthEntries();
      final activities = await _api.getSportActivities();

      setState(() {
        _entries = entries;
        _sportActivities = activities;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  int _getStepsToday() {
    final today = DateTime.now();
    final todayEntries = _entries
        .where((e) =>
            e.entryDate.year == today.year &&
            e.entryDate.month == today.month &&
            e.entryDate.day == today.day)
        .toList();

    int steps = 0;
    for (final entry in todayEntries) {
      if (entry.notes != null && entry.notes!.startsWith('{')) {
        try {
          final parsed = Map<String, dynamic>.from(jsonDecode(entry.notes!));
          final activity = parsed['activity'];
          if (activity is Map && activity['steps'] != null) {
            steps += int.tryParse(activity['steps'].toString()) ?? 0;
          }
        } catch (_) {}
      }
    }

    for (final activity in _sportActivities) {
      try {
        final start = DateTime.parse(activity['start']);
        if (start.year == today.year &&
            start.month == today.month &&
            start.day == today.day) {
          steps += (activity['steps'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}
    }

    return steps;
  }

  double _getSleepToday() {
    final today = DateTime.now();
    final todayEntries = _entries
        .where((e) =>
            e.entryDate.year == today.year &&
            e.entryDate.month == today.month &&
            e.entryDate.day == today.day)
        .toList();

    double sleepHours = 0;
    for (final entry in todayEntries) {
      if (entry.sleepHours != null) {
        sleepHours = entry.sleepHours!;
      }
    }

    return sleepHours;
  }

  int _getHeartRateToday() {
    final today = DateTime.now();
    final todayEntries = _entries
        .where((e) =>
            e.entryDate.year == today.year &&
            e.entryDate.month == today.month &&
            e.entryDate.day == today.day)
        .toList();

    if (todayEntries.isNotEmpty && todayEntries.last.heartRate != null) {
      return todayEntries.last.heartRate!.toInt();
    }
    return 0;
  }

  int _getMedicationTodayCount() {
    final today = DateTime.now();
    final todayEntries = _entries
        .where((e) =>
            e.entryDate.year == today.year &&
            e.entryDate.month == today.month &&
            e.entryDate.day == today.day)
        .toList();

    return todayEntries.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }

    final steps = _getStepsToday();
    final sleep = _getSleepToday();
    final hr = _getHeartRateToday();
    final medCount = _getMedicationTodayCount();
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Good morning, keep your momentum',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Primary Metrics Grid (2x2)
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivityDetailScreen(),
                      ),
                    ),
                    child: HealthMetricCard(
                      label: 'Steps',
                      value: '$steps',
                      unit: '/ 10,000',
                      trend: '↑ 12% vs yesterday',
                      accentColor: AppColors.primaryGreen,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SleepDetailScreen(),
                      ),
                    ),
                    child: HealthMetricCard(
                      label: 'Sleep',
                      value: '${sleep.toStringAsFixed(1)}h',
                      unit: 'excellent',
                      trend: 'Score: 92%',
                      accentColor: AppColors.primaryGreen,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HeartRateDetailScreen(),
                      ),
                    ),
                    child: HealthMetricCard(
                      label: 'Heart Rate',
                      value: '$hr',
                      unit: 'bpm',
                      trend: 'Resting: 62 bpm',
                      accentColor: AppColors.primaryBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicationsDetailScreen(),
                      ),
                    ),
                    child: HealthMetricCard(
                      label: 'Medications',
                      value: '$medCount',
                      unit: '/ 5 taken',
                      trend: '100% adherence',
                      accentColor: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // AI Detective Insight
              const DetectiveInsightCard(
                badge: '✨ Strong week',
                title: 'Your consistency is paying off',
                description:
                    'Consistent morning exercise combined with evening caffeine avoidance has improved your sleep quality by 18% this week. Medication adherence is perfect, and your HRV shows excellent recovery.',
                finding:
                    '📊 Key pattern: Your HRV spikes 15% higher when you maintain this routine for 5+ consecutive days. You\'re in a great rhythm.',
              ),
              const SizedBox(height: 12),

              // Ask Detective Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Detective feature coming soon!')),
                    );
                  },
                  child: const Text('Ask Detective More Questions'),
                ),
              ),
              const SizedBox(height: 24),

              // Secondary Metrics
              Text(
                'Other Metrics',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSecondaryMetricCard(
                    context,
                    'Hydration',
                    '7/8L',
                    AppColors.primaryBlue,
                  ),
                  _buildSecondaryMetricCard(
                    context,
                    'HRV',
                    '58ms',
                    AppColors.primaryGreen,
                  ),
                  _buildSecondaryMetricCard(
                    context,
                    'Stress',
                    'Low',
                    AppColors.primaryBlue,
                  ),
                  _buildSecondaryMetricCard(
                    context,
                    'Mood',
                    'Great',
                    AppColors.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: QuickLogFAB(
        onOptionSelected: _handleQuickLog,
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentTab: DashboardTab.dashboard,
        onTabChanged: (tab) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tab.label} feature coming soon!')),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryMetricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 0.5,
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
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
