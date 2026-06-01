import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with AutomaticKeepAliveClientMixin {
  static const _surface = Color(0xFF0F1624);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _accent = Color(0xFF5B8DEF);

  final ApiService _api = ApiService.instance;
  late Future<_InsightsSnapshot> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_InsightsSnapshot> _load() async {
    final results = await Future.wait<dynamic>([
      _api.getHealthEntries(),
      _api.getSportActivities(),
      _loadMedicinesInsight(),
    ]);

    final entries = (results[0] as List<HealthEntry>).toList()
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
    final activities = (results[1] as List<Map<String, dynamic>>).toList()
      ..sort((a, b) {
        final aDate = sportActivityDate(a) ?? DateTime(1900);
        final bDate = sportActivityDate(b) ?? DateTime(1900);
        return bDate.compareTo(aDate);
      });
    final medicines = results[2] as _MedicineInsight;

    return _InsightsSnapshot(
      entries: entries,
      activities: activities,
      medicines: medicines,
    );
  }

  Future<_MedicineInsight> _loadMedicinesInsight() async {
    try {
      await _api.ensureActiveUserId();
      final medicines = await _api.getMedicines(
        activeOnly: false,
        throwOnError: true,
      );
      final activeMedicines =
          medicines.where((medicine) => medicine.isActive).toList();
      return _MedicineInsight(
        activeCount: activeMedicines.length,
        takenTodayCount: await _takenTodayCount(activeMedicines),
        dataUnavailable: false,
      );
    } catch (_) {
      return const _MedicineInsight(
        activeCount: 0,
        takenTodayCount: null,
        dataUnavailable: true,
      );
    }
  }

  Future<int?> _takenTodayCount(List<Medicine> activeMedicines) async {
    if (activeMedicines.isEmpty) {
      return null;
    }

    final today = _dateOnly(DateTime.now());
    try {
      final results = await Future.wait(
        activeMedicines.map((medicine) async {
          final adherence = await _api.getMedicineAdherence(
            medicine.id,
            days: 1,
          );
          final breakdown = adherence['dailyBreakdown'];
          if (breakdown is! List) return null;
          final takenToday = breakdown.any((point) {
            if (point is! Map) return false;
            return point['date']?.toString() == today &&
                point['status']?.toString().toUpperCase() == 'TAKEN';
          });
          return takenToday ? medicine.id : null;
        }),
      );
      return results.whereType<int>().length;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() {
    final refreshed = _load();
    setState(() => _future = refreshed);
    return refreshed;
  }

  void _retry() {
    setState(() => _future = _load());
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.goNamed('health');
  }

  Widget _backButton() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _goBack,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back, color: _primaryText, size: 21),
          ),
        ),
      );

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            _backButton(),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Insights / Trends',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _primaryText,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<_InsightsSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ScaffoldFrame(
            topBar: _topBar(),
            child: Center(
              child: _ErrorCard(onRetry: _retry),
            ),
          );
        }

        final loading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final data = snapshot.data ??
            const _InsightsSnapshot(
              entries: [],
              activities: [],
              medicines: _MedicineInsight(
                activeCount: 0,
                takenTodayCount: null,
                dataUnavailable: false,
              ),
            );

        final week = currentWeekRange();
        final previousWeek = previousWeekRange();
        final sleep =
            _SleepInsight.fromEntries(data.entries, week, previousWeek);
        final activity = _ActivityInsight.fromActivities(
          data.activities,
          week,
          previousWeek,
        );
        final vitals = _VitalsInsight.fromEntries(
          data.entries,
          week,
          previousWeek,
        );
        final overview = _OverviewInsight.fromInsights(sleep, activity, vitals);
        final smartPattern = _SmartPatternInsight.fromEntries(data.entries);

        return _ScaffoldFrame(
          topBar: _topBar(),
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: _accent),
                )
              : RefreshIndicator(
                  color: _accent,
                  backgroundColor: _surface,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    children: [
                      _HealthOverviewCard(
                        insight: overview,
                        sleep: sleep,
                        activity: activity,
                        vitals: vitals,
                        medicines: data.medicines,
                      ),
                      const SizedBox(height: 16),
                      _SleepInsightCard(insight: sleep),
                      const SizedBox(height: 16),
                      _ActivityInsightCard(insight: activity),
                      const SizedBox(height: 16),
                      _VitalsInsightCard(insight: vitals),
                      const SizedBox(height: 16),
                      _MedicinesInsightCard(insight: data.medicines),
                      const SizedBox(height: 16),
                      _SmartPatternsCard(insight: smartPattern),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _ScaffoldFrame extends StatelessWidget {
  final Widget topBar;
  final Widget child;

  const _ScaffoldFrame({required this.topBar, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ReportsColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            topBar,
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _HealthOverviewCard extends StatelessWidget {
  final _OverviewInsight insight;
  final _SleepInsight sleep;
  final _ActivityInsight activity;
  final _VitalsInsight vitals;
  final _MedicineInsight medicines;

  const _HealthOverviewCard({
    required this.insight,
    required this.sleep,
    required this.activity,
    required this.vitals,
    required this.medicines,
  });

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Health Overview',
                  style: _ReportsText.title,
                ),
              ),
              _StatusChip(status: insight.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight.subtitle, style: _ReportsText.body),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryTile(
                label: 'Sleep average',
                value: sleep.hasCurrentData
                    ? formatDurationHours(sleep.averageThisWeek!)
                    : 'Needs data',
              ),
              _SummaryTile(
                label: 'Active days',
                value: '${activity.activeDaysThisWeek} this week',
              ),
              _SummaryTile(
                label: 'Vitals status',
                value: vitals.status,
              ),
              _SummaryTile(
                label: 'Active medicines',
                value: medicines.dataUnavailable
                    ? 'Unavailable'
                    : medicines.activeCountLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepInsightCard extends StatelessWidget {
  final _SleepInsight insight;

  const _SleepInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    if (!insight.hasCurrentData) {
      return const _EmptyInsightCard(
        icon: Icons.bedtime_rounded,
        title: 'Sleep Insight',
        value: 'Needs data',
        subtitle: 'Log a few nights to see your sleep trend.',
      );
    }

    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.bedtime_rounded,
            title: 'Sleep Insight',
            status: 'Stable',
          ),
          const SizedBox(height: 16),
          Text(
            formatDurationHours(insight.averageThisWeek!),
            style: _ReportsText.heroValue,
          ),
          const SizedBox(height: 6),
          Text(insight.changeLabel, style: _ReportsText.body),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryTile(
                label: 'Best night',
                value: formatDurationHours(insight.bestNightThisWeek!),
              ),
              _SummaryTile(
                label: 'Lowest night',
                value: formatDurationHours(insight.lowestNightThisWeek!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityInsightCard extends StatelessWidget {
  final _ActivityInsight insight;

  const _ActivityInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    if (!insight.hasCurrentData) {
      return const _EmptyInsightCard(
        icon: Icons.directions_walk_rounded,
        title: 'Activity Insight',
        value: 'No activity trend yet',
        subtitle: 'Log activities to see your weekly movement pattern.',
      );
    }

    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.directions_walk_rounded,
            title: 'Activity Insight',
            status: 'Stable',
          ),
          const SizedBox(height: 16),
          Text(
            '${insight.activeDaysThisWeek} active days',
            style: _ReportsText.heroValue,
          ),
          const SizedBox(height: 6),
          Text(
            '${formatMinutes(insight.totalDurationThisWeek)} total activity',
            style: _ReportsText.body,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryTile(
                label: 'Distance',
                value: formatDistance(insight.totalDistanceThisWeek),
              ),
              _SummaryTile(
                label: 'Most common',
                value: insight.mostCommonType ?? 'Needs data',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalsInsightCard extends StatelessWidget {
  final _VitalsInsight insight;

  const _VitalsInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    if (!insight.hasCurrentData) {
      return const _EmptyInsightCard(
        icon: Icons.favorite_rounded,
        title: 'Vitals Insight',
        value: 'Needs data',
        subtitle: 'Log vitals to see your weekly baseline.',
      );
    }

    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.favorite_rounded,
            title: 'Vitals Insight',
            status: insight.status,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryTile(
                label: 'Avg heart rate',
                value: insight.averageHeartRate == null
                    ? 'Needs data'
                    : '${insight.averageHeartRate!.round()} bpm',
              ),
              _SummaryTile(
                label: 'Avg stress',
                value: insight.averageStress == null
                    ? 'Needs data'
                    : insight.averageStress!.round().toString(),
              ),
              _SummaryTile(
                label: 'Latest BP',
                value: insight.latestBloodPressure ?? 'Needs data',
                wide: true,
              ),
              _SummaryTile(
                label: 'Latest SpO2',
                value: insight.latestSpO2 == null
                    ? 'Needs data'
                    : '${insight.latestSpO2}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicinesInsightCard extends StatelessWidget {
  final _MedicineInsight insight;

  const _MedicinesInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight.dataUnavailable) {
      return const _EmptyInsightCard(
        icon: Icons.medication_rounded,
        title: 'Medicines Insight',
        value: 'Medication data unavailable',
        subtitle: 'Try again to refresh your medication routine.',
      );
    }

    final hasActiveMedicines = insight.activeCount > 0;
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.medication_rounded,
            title: 'Medicines Insight',
            status: hasActiveMedicines ? 'Stable' : 'Needs data',
          ),
          const SizedBox(height: 16),
          Text(insight.activeCountLabel, style: _ReportsText.heroValue),
          const SizedBox(height: 8),
          Text(
            hasActiveMedicines
                ? 'Medication tracking is active.'
                : 'Add medicines to track your routine.',
            style: _ReportsText.body,
          ),
          if (insight.adherenceSummary != null) ...[
            const SizedBox(height: 18),
            _SummaryTile(
              label: 'Today',
              value: insight.adherenceSummary!,
              wide: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _SmartPatternsCard extends StatelessWidget {
  final _SmartPatternInsight insight;

  const _SmartPatternsCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.auto_graph_rounded,
            title: 'Smart Patterns',
            status: insight.status,
          ),
          const SizedBox(height: 16),
          Text(insight.title, style: _ReportsText.heroValue),
          const SizedBox(height: 8),
          Text(insight.message, style: _ReportsText.body),
          if (insight.daysAnalyzed >= 3) ...[
            const SizedBox(height: 18),
            _SummaryTile(
              label: 'Days analyzed',
              value: '${insight.daysAnalyzed}',
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Widget child;

  const _InsightCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ReportsColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: _ReportsColors.border.withValues(alpha: 0.75)),
      ),
      child: child,
    );
  }
}

class _EmptyInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _EmptyInsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: icon, title: title, status: 'Needs data'),
          const SizedBox(height: 16),
          Text(value, style: _ReportsText.heroValue),
          const SizedBox(height: 8),
          Text(subtitle, style: _ReportsText.body),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _ReportsColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _ReportsColors.accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: _ReportsText.title)),
        _StatusChip(status: status),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Improving' => _ReportsColors.success,
      'Stable' => _ReportsColors.accent,
      'Higher than usual' => _ReportsColors.warning,
      'Lower than usual' => _ReportsColors.warning,
      _ => _ReportsColors.secondaryText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final bool wide;

  const _SummaryTile({
    required this.label,
    required this.value,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 190 : 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ReportsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ReportsColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _ReportsText.label),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _ReportsText.tileValue,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ReportsColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ReportsColors.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _ReportsColors.accent,
            size: 34,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load insights',
            style: _ReportsText.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try again to load your latest weekly trends.',
            textAlign: TextAlign.center,
            style: _ReportsText.body,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _ReportsColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsSnapshot {
  final List<HealthEntry> entries;
  final List<Map<String, dynamic>> activities;
  final _MedicineInsight medicines;

  const _InsightsSnapshot({
    required this.entries,
    required this.activities,
    required this.medicines,
  });
}

class _OverviewInsight {
  final String status;
  final String subtitle;

  const _OverviewInsight({required this.status, required this.subtitle});

  factory _OverviewInsight.fromInsights(
    _SleepInsight sleep,
    _ActivityInsight activity,
    _VitalsInsight vitals,
  ) {
    final hasData = sleep.hasCurrentData ||
        activity.hasCurrentData ||
        vitals.hasCurrentData;
    if (!hasData) {
      return const _OverviewInsight(
        status: 'Needs data',
        subtitle: 'Log more data to unlock stronger insights.',
      );
    }

    final improving =
        sleep.changeMinutes != null && sleep.changeMinutes! >= 15 ||
            activity.activeDaysThisWeek > activity.activeDaysPreviousWeek;

    return _OverviewInsight(
      status: improving ? 'Improving' : 'Stable',
      subtitle: 'Your weekly health trends are ready.',
    );
  }
}

class _MedicineInsight {
  final int activeCount;
  final int? takenTodayCount;
  final bool dataUnavailable;

  const _MedicineInsight({
    required this.activeCount,
    required this.takenTodayCount,
    required this.dataUnavailable,
  });

  String get activeCountLabel {
    if (activeCount == 0) return 'No active medicines';
    return '$activeCount active medicine${activeCount == 1 ? '' : 's'}';
  }

  String? get adherenceSummary {
    final taken = takenTodayCount;
    if (taken == null || activeCount == 0) return null;
    return '$taken of $activeCount marked taken today';
  }
}

class _SmartPatternInsight {
  final String title;
  final String message;
  final String status;
  final int daysAnalyzed;

  const _SmartPatternInsight({
    required this.title,
    required this.message,
    required this.status,
    required this.daysAnalyzed,
  });

  factory _SmartPatternInsight.fromEntries(List<HealthEntry> entries) {
    final pairedDays = entries.where((entry) {
      return _isValidSleepHours(entry.sleepHours) && entry.stressLevel != null;
    }).toList(growable: false);

    if (pairedDays.length < 3) {
      return const _SmartPatternInsight(
        title: 'Needs more data',
        message: 'Log sleep and stress for a few more days to unlock patterns.',
        status: 'Needs data',
        daysAnalyzed: 0,
      );
    }

    final shortSleepStress = pairedDays
        .where((entry) => entry.sleepHours! < 6)
        .map((entry) => entry.stressLevel!.toDouble())
        .toList(growable: false);
    final regularSleepStress = pairedDays
        .where((entry) => entry.sleepHours! >= 6)
        .map((entry) => entry.stressLevel!.toDouble())
        .toList(growable: false);

    final hasPattern = shortSleepStress.isNotEmpty &&
        regularSleepStress.isNotEmpty &&
        average(shortSleepStress) >= average(regularSleepStress) + 10;

    return _SmartPatternInsight(
      title: hasPattern ? 'Pattern detected' : 'No strong pattern yet',
      message: hasPattern
          ? 'Short sleep days are linked with higher stress in your logs.'
          : 'No strong sleep-stress pattern detected yet.',
      status: hasPattern ? 'Stable' : 'Needs data',
      daysAnalyzed: pairedDays.length,
    );
  }
}

class _SleepInsight {
  final double? averageThisWeek;
  final int? changeMinutes;
  final double? bestNightThisWeek;
  final double? lowestNightThisWeek;

  const _SleepInsight({
    required this.averageThisWeek,
    required this.changeMinutes,
    required this.bestNightThisWeek,
    required this.lowestNightThisWeek,
  });

  bool get hasCurrentData => averageThisWeek != null;

  String get changeLabel {
    if (changeMinutes == null) {
      return 'Previous week comparison needs more data.';
    }
    return '${formatSignedMinutes(changeMinutes!)} vs last week';
  }

  factory _SleepInsight.fromEntries(
    List<HealthEntry> entries,
    DateRange week,
    DateRange previousWeek,
  ) {
    final currentValues = entries
        .where((entry) => week.contains(entry.entryDate))
        .map((entry) => entry.sleepHours)
        .where(_isValidSleepHours)
        .cast<double>()
        .toList(growable: false);
    final previousValues = entries
        .where((entry) => previousWeek.contains(entry.entryDate))
        .map((entry) => entry.sleepHours)
        .where(_isValidSleepHours)
        .cast<double>()
        .toList(growable: false);

    if (currentValues.isEmpty) {
      return const _SleepInsight(
        averageThisWeek: null,
        changeMinutes: null,
        bestNightThisWeek: null,
        lowestNightThisWeek: null,
      );
    }

    final currentAverage = average(currentValues);
    final previousAverage =
        previousValues.isEmpty ? null : average(previousValues);

    return _SleepInsight(
      averageThisWeek: currentAverage,
      changeMinutes: previousAverage == null
          ? null
          : ((currentAverage - previousAverage) * 60).round(),
      bestNightThisWeek: currentValues.reduce((a, b) => a > b ? a : b),
      lowestNightThisWeek: currentValues.reduce((a, b) => a < b ? a : b),
    );
  }
}

class _ActivityInsight {
  final int activeDaysThisWeek;
  final int activeDaysPreviousWeek;
  final int totalDurationThisWeek;
  final double totalDistanceThisWeek;
  final String? mostCommonType;

  const _ActivityInsight({
    required this.activeDaysThisWeek,
    required this.activeDaysPreviousWeek,
    required this.totalDurationThisWeek,
    required this.totalDistanceThisWeek,
    required this.mostCommonType,
  });

  bool get hasCurrentData =>
      activeDaysThisWeek > 0 || totalDurationThisWeek > 0;

  factory _ActivityInsight.fromActivities(
    List<Map<String, dynamic>> activities,
    DateRange week,
    DateRange previousWeek,
  ) {
    final current = activities.where((activity) {
      final date = sportActivityDate(activity);
      return date != null && week.contains(date);
    }).toList(growable: false);
    final previous = activities.where((activity) {
      final date = sportActivityDate(activity);
      return date != null && previousWeek.contains(date);
    }).toList(growable: false);

    final activeDays = <String>{};
    final previousActiveDays = <String>{};
    final typeCounts = <String, int>{};
    var totalDuration = 0;
    var totalDistance = 0.0;

    for (final activity in current) {
      final date = sportActivityDate(activity);
      if (date != null) activeDays.add(_dateKey(date));
      totalDuration += sportActivityDuration(activity);
      totalDistance += sportActivityDistance(activity) ?? 0;
      final type = sportActivityType(activity);
      if (type != null) typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    for (final activity in previous) {
      final date = sportActivityDate(activity);
      if (date != null) previousActiveDays.add(_dateKey(date));
    }

    String? mostCommonType;
    if (typeCounts.isNotEmpty) {
      final sorted = typeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostCommonType = sorted.first.key;
    }

    return _ActivityInsight(
      activeDaysThisWeek: activeDays.length,
      activeDaysPreviousWeek: previousActiveDays.length,
      totalDurationThisWeek: totalDuration,
      totalDistanceThisWeek: totalDistance,
      mostCommonType: mostCommonType,
    );
  }
}

class _VitalsInsight {
  final double? averageHeartRate;
  final double? averageStress;
  final String? latestBloodPressure;
  final int? latestSpO2;
  final String status;

  const _VitalsInsight({
    required this.averageHeartRate,
    required this.averageStress,
    required this.latestBloodPressure,
    required this.latestSpO2,
    required this.status,
  });

  bool get hasCurrentData =>
      averageHeartRate != null ||
      averageStress != null ||
      latestBloodPressure != null ||
      latestSpO2 != null;

  factory _VitalsInsight.fromEntries(
    List<HealthEntry> entries,
    DateRange week,
    DateRange previousWeek,
  ) {
    final current = entries
        .where((entry) => week.contains(entry.entryDate))
        .toList(growable: false);
    final previous = entries
        .where((entry) => previousWeek.contains(entry.entryDate))
        .toList(growable: false);

    final heartRateValues = current
        .map((entry) => entry.heartRate?.toDouble())
        .whereType<double>()
        .toList(growable: false);
    final stressValues = current
        .map((entry) => entry.stressLevel?.toDouble())
        .whereType<double>()
        .toList(growable: false);
    final previousHeartRateValues = previous
        .map((entry) => entry.heartRate?.toDouble())
        .whereType<double>()
        .toList(growable: false);
    final previousStressValues = previous
        .map((entry) => entry.stressLevel?.toDouble())
        .whereType<double>()
        .toList(growable: false);

    final latestBp = current.cast<HealthEntry?>().firstWhere(
          (entry) => entry?.systolicBp != null && entry?.diastolicBp != null,
          orElse: () => null,
        );
    final latestSpO2 = current.cast<HealthEntry?>().firstWhere(
          (entry) => entry?.spO2 != null,
          orElse: () => null,
        );

    final averageHeartRate =
        heartRateValues.isEmpty ? null : average(heartRateValues);
    final averageStress = stressValues.isEmpty ? null : average(stressValues);

    return _VitalsInsight(
      averageHeartRate: averageHeartRate,
      averageStress: averageStress,
      latestBloodPressure: latestBp == null
          ? null
          : '${latestBp.systolicBp}/${latestBp.diastolicBp}',
      latestSpO2: latestSpO2?.spO2,
      status: _vitalsStatus(
        averageHeartRate,
        previousHeartRateValues.isEmpty
            ? null
            : average(previousHeartRateValues),
        averageStress,
        previousStressValues.isEmpty ? null : average(previousStressValues),
      ),
    );
  }

  static String _vitalsStatus(
    double? heartRate,
    double? previousHeartRate,
    double? stress,
    double? previousStress,
  ) {
    if (heartRate == null && stress == null) return 'Needs data';
    final heartRateChange = _relativeChange(heartRate, previousHeartRate);
    final stressChange = _relativeChange(stress, previousStress);
    final changes = [heartRateChange, stressChange].whereType<double>();
    if (changes.isEmpty) return 'Stable';
    final maxChange = changes.reduce((a, b) => a.abs() > b.abs() ? a : b);
    if (maxChange >= 0.12) return 'Higher than usual';
    if (maxChange <= -0.12) return 'Lower than usual';
    return 'Stable';
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  bool contains(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return !date.isBefore(start) && date.isBefore(end);
  }
}

class _ReportsColors {
  static const bg = Color(0xFF070B13);
  static const surface = Color(0xFF0F1624);
  static const surfaceAlt = Color(0xFF121B2C);
  static const border = Color(0xFF243047);
  static const primaryText = Color(0xFFF5F7FB);
  static const secondaryText = Color(0xFF94A3B8);
  static const accent = Color(0xFF5B8DEF);
  static const success = Color(0xFF53D39A);
  static const warning = Color(0xFFFFC46B);
}

class _ReportsText {
  static const title = TextStyle(
    color: _ReportsColors.primaryText,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
  static const heroValue = TextStyle(
    color: _ReportsColors.primaryText,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: 0,
  );
  static const tileValue = TextStyle(
    color: _ReportsColors.primaryText,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: 0,
  );
  static const body = TextStyle(
    color: _ReportsColors.secondaryText,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );
  static const label = TextStyle(
    color: _ReportsColors.secondaryText,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}

DateRange currentWeekRange() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateRange(today.subtract(const Duration(days: 6)),
      today.add(const Duration(days: 1)));
}

DateRange previousWeekRange() {
  final current = currentWeekRange();
  return DateRange(
    current.start.subtract(const Duration(days: 7)),
    current.start,
  );
}

double average(List<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

String formatDurationHours(double hours) {
  final totalMinutes = (hours * 60).round().clamp(0, 24 * 60);
  final wholeHours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${wholeHours}h ${minutes.toString().padLeft(2, '0')}m';
}

String formatMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '${remaining}m';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
}

String formatSignedMinutes(int minutes) {
  final sign = minutes >= 0 ? '+' : '-';
  return '$sign${formatMinutes(minutes.abs())}';
}

String formatDistance(double kilometers) {
  if (kilometers <= 0) return '0 km';
  final value = kilometers == kilometers.truncateToDouble()
      ? kilometers.toStringAsFixed(0)
      : kilometers.toStringAsFixed(1);
  return '$value km';
}

DateTime? sportActivityDate(Map<String, dynamic> activity) {
  final raw = activity['activityDate'] ?? activity['start'] ?? activity['date'];
  return raw == null ? null : DateTime.tryParse(raw.toString());
}

int sportActivityDuration(Map<String, dynamic> activity) {
  final raw = activity['duration'] ?? activity['durationMinutes'];
  if (raw is num) return raw.round();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

double? sportActivityDistance(Map<String, dynamic> activity) {
  final raw = activity['distance'] ?? activity['distanceKm'];
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '');
}

String? sportActivityType(Map<String, dynamic> activity) {
  final raw = (activity['activityType'] ?? activity['type'])?.toString().trim();
  if (raw == null || raw.isEmpty || raw == 'null') return null;
  return raw[0].toUpperCase() + raw.substring(1);
}

bool _isValidSleepHours(double? value) {
  return value != null && value > 0 && value <= 24;
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month}-${date.day}';
}

String _dateOnly(DateTime date) {
  return date.toIso8601String().split('T').first;
}

double? _relativeChange(double? current, double? previous) {
  if (current == null || previous == null || previous == 0) return null;
  return (current - previous) / previous.abs();
}
