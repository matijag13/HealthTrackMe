import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService.instance;
  late Future<HealthReport> _future;
  HealthReport? _cachedReport;
  DateTime? _lastRefreshTime;
  static const Duration _cacheExpiry = Duration(minutes: 10);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<HealthReport> _load() async {
    try {
      // Use cached report if still fresh
      if (_cachedReport != null && _lastRefreshTime != null) {
        final elapsed = DateTime.now().difference(_lastRefreshTime!);
        if (elapsed < _cacheExpiry) {
          return _cachedReport!;
        }
      }

      final report = await _api.getMonthlyReport(DateTime.now());
      _cachedReport = report;
      _lastRefreshTime = DateTime.now();
      return report;
    } catch (e) {
      return _cachedReport ?? HealthReport.fromJson({});
    }
  }

  Future<void> _refresh() async {
    _lastRefreshTime = null; // Invalidate cache
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _copySummary() async {
    final summary = await _api.getHealthSummary();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (summary == null || summary.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No summary available right now.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: summary));
    messenger.showSnackBar(
        const SnackBar(content: Text('✅ Summary copied to clipboard')));
  }

  String _monthLabel(DateTime month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  String _formatSleep(double hours) {
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    return '${wholeHours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: const TextSpan(
                text: 'Health',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                children: [
                  TextSpan(
                      text: 'Track', style: TextStyle(color: AppColors.teal)),
                  TextSpan(text: 'Me'),
                ],
              ),
            ),
            const Spacer(),
            Text(
              _monthLabel(DateTime.now()),
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<HealthReport>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _cachedReport == null) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LoadingSkeleton.dashboard(context)));
            }
            if (snapshot.hasError && _cachedReport == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                      child: Text('Error loading report: ${snapshot.error}')),
                ],
              );
            }

            final data = snapshot.data ??
                _cachedReport ??
                HealthReport.fromEntries(
                    month: DateTime.now(),
                    entries: const [],
                    medicines: const []);
            final String scoreBadge;
            final Color scoreBadgeColor;
            final Color scoreBadgeTextColor;
            if (data.averageWellbeingScore >= 70) {
              scoreBadge = '✓ Good';
              scoreBadgeColor = const Color(0xFFE8F8F0);
              scoreBadgeTextColor = AppColors.success;
            } else if (data.averageWellbeingScore >= 40) {
              scoreBadge = '⚠ Fair';
              scoreBadgeColor = const Color(0xFFFFF3E0);
              scoreBadgeTextColor = const Color(0xFFE67E22);
            } else {
              scoreBadge = '! Low';
              scoreBadgeColor = const Color(0xFFFDECEA);
              scoreBadgeTextColor = AppColors.danger;
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              children: [
                const SectionHeader(
                  title: 'Reports',
                  subtitle: 'Monthly overview of your health data and trends.',
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.teal, Color(0xFF1a9e94)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📄 Doctor\'s Report',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Monthly summary · ${_monthLabel(data.month)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: _copySummary,
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Summary'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRENDS THIS MONTH',
                            style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 12),
                        TrendItem(
                          icon: '✨',
                          name: 'Avg. Wellbeing',
                          value:
                              '${data.averageWellbeingScore.toStringAsFixed(0)} / 100',
                          badge: scoreBadge,
                          badgeColor: scoreBadgeColor,
                          badgeTextColor: scoreBadgeTextColor,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        TrendItem(
                          icon: '😴',
                          name: 'Sleep',
                          value: data.averageSleepHours > 0
                              ? 'Avg. ${_formatSleep(data.averageSleepHours)}'
                              : 'No data',
                          badge: data.averageSleepHours >= 7
                              ? '✓ Normal'
                              : '↘ Check',
                          badgeColor: data.averageSleepHours >= 7
                              ? const Color(0xFFE8F8F0)
                              : const Color(0xFFFFF3E0),
                          badgeTextColor: data.averageSleepHours >= 7
                              ? AppColors.success
                              : const Color(0xFFE67E22),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        TrendItem(
                          icon: '📝',
                          name: 'Entries',
                          value: '${data.entriesCount} entries',
                          badge: data.entriesCount > 0 ? '✓ Active' : 'No data',
                          badgeColor: AppColors.softBlue,
                          badgeTextColor: AppColors.blue,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        TrendItem(
                          icon: '💊',
                          name: 'Active Medicines',
                          value: '${data.activeMedicinesCount} medicines',
                          badge: data.activeMedicinesCount > 0
                              ? '✓ In use'
                              : 'No medicines',
                          badgeColor: const Color(0xFFE8F8F0),
                          badgeTextColor: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COMMON SYMPTOMS',
                            style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 12),
                        if (data.symptomFrequency.isEmpty)
                          const Text('No symptoms to display.')
                        else
                          ...data.symptomFrequency.entries.map((entry) {
                            final maxCount = data.symptomFrequency.values
                                .reduce((a, b) => a > b ? a : b);
                            final percentage = maxCount == 0
                                ? 0
                                : (entry.value / maxCount * 100).toInt();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(entry.key,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.navy)),
                                  ),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.border,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        Container(
                                          width: (percentage / 100) *
                                              (MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  160),
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.blue,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 28,
                                    child: Text('${entry.value}x',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.muted)),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    border:
                        Border.all(color: const Color(0xFFBDD9F2), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📤 Share with Doctor',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy)),
                      const SizedBox(height: 6),
                      const Text(
                          'You can copy this summary and share it via email or other channels.'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _copySummary,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Copy'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _refresh,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                      color: AppColors.blue, width: 1.5),
                                ),
                              ),
                              child: const Text('Refresh'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
