import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import '../utils/health_utils.dart';
import 'edit_profile_screen.dart';

class _HealthSnapshot {
  final User? user;
  final List<HealthEntry> entries;
  final List<Medicine> medicines;
  final HealthShield? shield;
  final HealthReport report;

  const _HealthSnapshot({
    required this.user,
    required this.entries,
    required this.medicines,
    required this.shield,
    required this.report,
  });
}

Future<_HealthSnapshot> _loadHealthSnapshot({DateTime? month}) async {
  final api = ApiService.instance;
  final results = await Future.wait([
    api.getCurrentUser(),
    api.getHealthEntries(),
    api.getMedicines(activeOnly: false),
    api.getHealthShield(),
    api.getMonthlyReport(month ?? DateTime.now()),
  ]);

  return _HealthSnapshot(
    user: results[0] as User?,
    entries: results[1] as List<HealthEntry>,
    medicines: results[2] as List<Medicine>,
    shield: results[3] as HealthShield?,
    report: results[4] as HealthReport,
  );
}

String _formatDate(DateTime date) =>
    DateFormat('dd MMM yyyy').format(date.toLocal());

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HealthSnapshot>(
      future: _loadHealthSnapshot(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
              body: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LoadingSkeleton.dashboard(context))));
        }

        final data = snapshot.data ??
            _HealthSnapshot(
              user: null,
              entries: const [],
              medicines: const [],
              shield: null,
              report: HealthReport.fromEntries(
                  month: DateTime.now(),
                  entries: const [],
                  medicines: const []),
            );
        final latest = data.entries.isNotEmpty ? data.entries.first : null;
        final recent = data.entries.take(7).toList().reversed.toList();
        final averageSleep = data.report.averageSleepHours;

        return Scaffold(
          appBar: AppBar(title: const Text('Health')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(
                title: 'Health overview',
                subtitle:
                    'Charts, trends, and the monthly report now live inside the Health tab.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ShortcutCard(
                    icon: Icons.favorite_rounded,
                    title: 'Vitals',
                    subtitle: 'Wellbeing, sleep and recent markers',
                    onTap: () => context.goNamed('healthVitals'),
                  ),
                  _ShortcutCard(
                    icon: Icons.directions_run_rounded,
                    title: 'Activity',
                    subtitle: 'Consistency and daily movement',
                    onTap: () => context.goNamed('healthActivity'),
                  ),
                  _ShortcutCard(
                    icon: Icons.bedtime_rounded,
                    title: 'Sleep',
                    subtitle: 'Sleep trend and recovery',
                    onTap: () => context.goNamed('healthSleep'),
                  ),
                  _ShortcutCard(
                    icon: Icons.history_rounded,
                    title: 'History',
                    subtitle: 'Reports and past entries',
                    onTap: () => context.goNamed('healthHistory'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WELLBEING TREND',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: recent.isEmpty
                            ? EmptyState(
                                animationUrl:
                                    'https://assets2.lottiefiles.com/packages/lf20_jcikwtux.json',
                                title: 'Start tracking today',
                                subtitle:
                                    'Start tracking today — log your first entry',
                                buttonLabel: 'Log entry',
                                onPressed: () => context.goNamed('log'))
                            : LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: 100,
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 26,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 ||
                                              index >= recent.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                                DateFormat('d').format(
                                                    recent[index].entryDate),
                                                style: const TextStyle(
                                                    fontSize: 11)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      color: AppColors.primary,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                      spots: [
                                        for (var i = 0; i < recent.length; i++)
                                          FlSpot(
                                              i.toDouble(),
                                              recent[i]
                                                  .effectiveWellbeingScore
                                                  .toDouble()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _MetricCard(
                          label: 'Wellbeing',
                          value: data.report.averageWellbeingScore
                              .toStringAsFixed(0),
                          suffix: '/ 100',
                          color: AppColors.info)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _MetricCard(
                          label: 'Sleep',
                          value: averageSleep > 0
                              ? averageSleep.toStringAsFixed(1)
                              : '—',
                          suffix: 'hours',
                          color: AppColors.sleep)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _MetricCard(
                          label: 'Active meds',
                          value: data.report.activeMedicinesCount.toString(),
                          suffix: '',
                          color: AppColors.weight)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _MetricCard(
                          label: 'Shield',
                          value: data.shield?.progressPercent.toString() ?? '—',
                          suffix: '%',
                          color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REPORTS',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      const Text(
                          'The monthly report has moved into the Health section as a sub-section.'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.goNamed('healthHistory'),
                          icon: const Icon(Icons.analytics_rounded),
                          label: const Text('Open reports and history'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (latest != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.today_rounded),
                    title:
                        Text('Latest entry · ${_formatDate(latest.entryDate)}'),
                    subtitle: Text(
                        'Mood: ${latest.mood ?? '—'} · Sleep: ${latest.sleepHours?.toStringAsFixed(1) ?? '—'} h · Notes: ${extractNote(latest.notes).isEmpty ? 'none' : extractNote(latest.notes)}'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

enum _VitalsMetric {
  heartRate,
  stress,
  bloodPressure,
  spO2,
  temperature,
  weight,
}

enum _VitalsTimeRange {
  day('1D'),
  week('1W'),
  month('1M'),
  max('Max');

  final String label;

  const _VitalsTimeRange(this.label);
}

String _vitalsMetricSheetTitle(_VitalsMetric metric) {
  switch (metric) {
    case _VitalsMetric.heartRate:
      return 'Add heart rate';
    case _VitalsMetric.stress:
      return 'Add stress';
    case _VitalsMetric.bloodPressure:
      return 'Add blood pressure';
    case _VitalsMetric.spO2:
      return 'Add SpO2';
    case _VitalsMetric.temperature:
      return 'Add temperature';
    case _VitalsMetric.weight:
      return 'Add weight';
  }
}

String _vitalsMetricToastLabel(_VitalsMetric metric) {
  switch (metric) {
    case _VitalsMetric.heartRate:
      return 'Heart rate';
    case _VitalsMetric.stress:
      return 'Stress';
    case _VitalsMetric.bloodPressure:
      return 'Blood pressure';
    case _VitalsMetric.spO2:
      return 'SpO2';
    case _VitalsMetric.temperature:
      return 'Temperature';
    case _VitalsMetric.weight:
      return 'Weight';
  }
}

String _vitalsMetricUnit(_VitalsMetric metric) {
  switch (metric) {
    case _VitalsMetric.heartRate:
      return 'bpm';
    case _VitalsMetric.stress:
      return '';
    case _VitalsMetric.bloodPressure:
      return 'mmHg';
    case _VitalsMetric.spO2:
      return '%';
    case _VitalsMetric.temperature:
      return '°C';
    case _VitalsMetric.weight:
      return 'kg';
  }
}

bool _vitalsMetricUsesDecimal(_VitalsMetric metric) {
  switch (metric) {
    case _VitalsMetric.temperature:
    case _VitalsMetric.weight:
      return true;
    case _VitalsMetric.heartRate:
    case _VitalsMetric.stress:
    case _VitalsMetric.bloodPressure:
    case _VitalsMetric.spO2:
      return false;
  }
}

TextInputType _vitalsMetricKeyboardType(_VitalsMetric metric) {
  return _vitalsMetricUsesDecimal(metric)
      ? const TextInputType.numberWithOptions(decimal: true)
      : TextInputType.number;
}

List<TextInputFormatter> _vitalsMetricFormatters(_VitalsMetric metric) {
  return _vitalsMetricUsesDecimal(metric)
      ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
      : [FilteringTextInputFormatter.digitsOnly];
}

void _showVitalsToast(
  BuildContext context, {
  required String message,
  required bool success,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  final accent = success ? const Color(0xFF36D399) : const Color(0xFFFF5C7A);
  final icon =
      success ? Icons.check_circle_rounded : Icons.error_outline_rounded;
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 3),
      dismissDirection: DismissDirection.horizontal,
      content: _VitalsToastContent(
        message: message,
        accent: accent,
        icon: icon,
      ),
    ),
  );
}

class _VitalsToastContent extends StatelessWidget {
  static const _surface = Color(0xFF0F1624);
  static const _primaryText = Color(0xFFF5F7FB);

  final String message;
  final Color accent;
  final IconData icon;

  const _VitalsToastContent({
    required this.message,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(width: 4, height: 60, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.22)),
                      ),
                      child: Icon(icon, color: accent, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalsMetricDefinition {
  final _VitalsMetric metric;
  final String label;
  final IconData icon;

  const _VitalsMetricDefinition({
    required this.metric,
    required this.label,
    required this.icon,
  });
}

class _VitalsReading {
  final DateTime date;
  final double primary;
  final double? secondary;

  const _VitalsReading({
    required this.date,
    required this.primary,
    this.secondary,
  });
}

class _VitalsChartData {
  final List<FlSpot> primary;
  final List<FlSpot> secondary;
  final double minY;
  final double maxY;

  const _VitalsChartData({
    required this.primary,
    required this.secondary,
    required this.minY,
    required this.maxY,
  });
}

class _VitalsManualEntryResult {
  final HealthEntry entry;
  final DateTime selectedDateTime;

  const _VitalsManualEntryResult({
    required this.entry,
    required this.selectedDateTime,
  });
}

class HealthVitalsPage extends StatefulWidget {
  const HealthVitalsPage({super.key});

  @override
  State<HealthVitalsPage> createState() => _HealthVitalsPageState();
}

class _HealthVitalsPageState extends State<HealthVitalsPage> {
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _surfaceSoft = Color(0xFF11141B);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _diastolicColor = Color(0xFFFF5C7A);

  final ApiService _api = ApiService.instance;

  static const List<_VitalsMetricDefinition> _metricDefinitions = [
    _VitalsMetricDefinition(
      metric: _VitalsMetric.heartRate,
      label: 'Heart Rate',
      icon: Icons.monitor_heart_outlined,
    ),
    _VitalsMetricDefinition(
      metric: _VitalsMetric.stress,
      label: 'Stress',
      icon: Icons.psychology_outlined,
    ),
    _VitalsMetricDefinition(
      metric: _VitalsMetric.bloodPressure,
      label: 'Blood Pressure',
      icon: Icons.favorite_outline,
    ),
    _VitalsMetricDefinition(
      metric: _VitalsMetric.spO2,
      label: 'SpO2',
      icon: Icons.air_outlined,
    ),
    _VitalsMetricDefinition(
      metric: _VitalsMetric.temperature,
      label: 'Temperature',
      icon: Icons.thermostat_outlined,
    ),
    _VitalsMetricDefinition(
      metric: _VitalsMetric.weight,
      label: 'Weight',
      icon: Icons.scale_outlined,
    ),
  ];

  late Future<_HealthSnapshot> _snapshotFuture;
  _VitalsMetric _selectedMetric = _VitalsMetric.heartRate;
  _VitalsTimeRange _selectedTimeRange = _VitalsTimeRange.week;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadHealthSnapshot();
  }

  void _retry() {
    setState(() {
      _snapshotFuture = _loadHealthSnapshot();
    });
  }

  void _selectMetric(_VitalsMetric metric) {
    if (_selectedMetric == metric) {
      return;
    }
    setState(() {
      _selectedMetric = metric;
    });
  }

  void _selectTimeRange(_VitalsTimeRange range) {
    if (_selectedTimeRange == range) {
      return;
    }
    setState(() {
      _selectedTimeRange = range;
    });
  }

  Future<void> _openManualEntrySheet() async {
    final metric = _selectedMetric;
    debugPrint('Vitals debug: opening manual add metric=${metric.name}');
    final result = await showModalBottomSheet<_VitalsManualEntryResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _VitalsManualEntrySheet(
          metric: metric,
          api: _api,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    debugPrint(
      'Vitals debug: saved metric=${metric.name} selectedDate=${_dateOnly(result.selectedDateTime)}',
    );
    final refreshed = await _refreshVitalsData();
    if (!mounted) {
      return;
    }

    final confirmed = _refreshedSnapshotContainsEntry(
      refreshed,
      metric,
      result.entry,
      result.selectedDateTime,
    );

    if (!confirmed) {
      _showVitalsToast(
        context,
        message: '${_vitalsMetricToastLabel(metric)} saved, but not returned',
        success: false,
      );
      return;
    }

    _showVitalsToast(
      context,
      message: '${_vitalsMetricToastLabel(metric)} added',
      success: true,
    );
  }

  Future<_HealthSnapshot> _refreshVitalsData() async {
    final refreshed = _loadHealthSnapshot();
    setState(() {
      _snapshotFuture = refreshed;
    });
    return refreshed;
  }

  bool _refreshedSnapshotContainsEntry(
    _HealthSnapshot snapshot,
    _VitalsMetric metric,
    HealthEntry savedEntry,
    DateTime selectedDateTime,
  ) {
    final expected = _readingFromEntry(savedEntry, metric);
    if (expected == null) {
      debugPrint('Vitals debug: created response has no metric field');
      return false;
    }

    final sameDateReadings = _readingsForMetric(snapshot.entries, metric)
        .where((reading) =>
            _sameDate(reading.date, expected.date) ||
            _sameDate(reading.date, selectedDateTime))
        .toList(growable: false);
    debugPrint(
      'Vitals debug: refetch entries=${snapshot.entries.length} metric=${metric.name} sameDateMetricReadings=${sameDateReadings.length}',
    );

    return sameDateReadings.any((reading) {
      return (_sameDate(reading.date, expected.date) ||
              _sameDate(reading.date, selectedDateTime)) &&
          _sameValue(reading.primary, expected.primary) &&
          (expected.secondary == null ||
              (reading.secondary != null &&
                  _sameValue(reading.secondary!, expected.secondary!)));
    });
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameValue(double a, double b) => (a - b).abs() < 0.01;

  _VitalsReading? _readingFromEntry(HealthEntry entry, _VitalsMetric metric) {
    switch (metric) {
      case _VitalsMetric.heartRate:
        final value = entry.heartRate;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                primary: value.toDouble(),
              );
      case _VitalsMetric.stress:
        final value = entry.stressLevel;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                primary: value.toDouble(),
              );
      case _VitalsMetric.bloodPressure:
        if (entry.systolicBp == null || entry.diastolicBp == null) {
          return null;
        }
        return _VitalsReading(
          date: entry.entryDate,
          primary: entry.systolicBp!.toDouble(),
          secondary: entry.diastolicBp!.toDouble(),
        );
      case _VitalsMetric.spO2:
        final value = entry.spO2;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                primary: value.toDouble(),
              );
      case _VitalsMetric.temperature:
        final value = entry.bodyTemperature;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                primary: value,
              );
      case _VitalsMetric.weight:
        final value = entry.weight;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                primary: value,
              );
    }
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.goNamed('health');
  }

  _VitalsMetricDefinition get _selectedDefinition => _metricDefinitions
      .firstWhere((definition) => definition.metric == _selectedMetric);

  Widget _buildBackButton() {
    return Material(
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
          child: const Icon(
            Icons.arrow_back,
            color: _primaryText,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Vitals',
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HealthSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: _border.withValues(alpha: 0.9)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: _accent, size: 34),
                            const SizedBox(height: 12),
                            const Text(
                              'Could not load vitals',
                              style: TextStyle(
                                color: _primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try again to load the latest health entries.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _secondaryText,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _retry,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _accent,
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final data = snapshot.data ??
            _HealthSnapshot(
              user: null,
              entries: const [],
              medicines: const [],
              shield: null,
              report: HealthReport.fromEntries(
                month: DateTime.now(),
                entries: const [],
                medicines: const [],
              ),
            );
        final allReadings = _readingsForMetric(data.entries, _selectedMetric);
        final readings =
            _filterReadingsForRange(allReadings, _selectedTimeRange);
        final chartData = _chartDataForMetric(readings, _selectedMetric);
        final latestReading = readings.isNotEmpty ? readings.last : null;
        final latestDisplay = _formatLatest(readings, _selectedMetric);
        final averageDisplay = _formatAverage(readings, _selectedMetric);
        final minMaxDisplay = _formatMinMax(readings, _selectedMetric);
        final latestDateLabel =
            latestReading != null ? _formatDate(latestReading.date) : null;

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _accent,
                          ),
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                          children: [
                            _buildMetricSelector(),
                            const SizedBox(height: 16),
                            _buildTimeRangeSelector(),
                            const SizedBox(height: 16),
                            _buildChartSection(
                                chartData, readings, latestDisplay),
                            const SizedBox(height: 16),
                            _buildStatsSection(
                              latestDisplay: latestDisplay,
                              averageDisplay: averageDisplay,
                              minMaxDisplay: minMaxDisplay,
                            ),
                            const SizedBox(height: 16),
                            if (latestReading != null)
                              _buildLatestEntryCard(
                                latestDateLabel: latestDateLabel!,
                                latestDisplay: latestDisplay,
                                readingCount: readings.length,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < _metricDefinitions.length; i++) ...[
            _buildMetricChip(_metricDefinitions[i]),
            if (i < _metricDefinitions.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(_VitalsMetricDefinition definition) {
    final selected = definition.metric == _selectedMetric;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _selectMetric(definition.metric),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: 0.16) : _surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _accent : _border.withValues(alpha: 0.9),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              definition.icon,
              size: 16,
              color: selected ? _accent : _secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              definition.label,
              style: TextStyle(
                color: selected ? _primaryText : _secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          for (final range in _VitalsTimeRange.values)
            Expanded(
              child: _buildTimeRangeSegment(range),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSegment(_VitalsTimeRange range) {
    final selected = range == _selectedTimeRange;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectTimeRange(range),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: 0.18) : _surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _accent : Colors.transparent,
            ),
          ),
          child: Text(
            range.label,
            style: TextStyle(
              color: selected ? _primaryText : _secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(
    _VitalsChartData chartData,
    List<_VitalsReading> readings,
    String latestDisplay,
  ) {
    final definition = _selectedDefinition;
    final hasData = readings.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  definition.label,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _buildAddButton(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: chartData.primary.length == 1
                          ? 1
                          : (chartData.primary.length - 1).toDouble(),
                      minY: chartData.minY,
                      maxY: chartData.maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            _chartInterval(chartData.minY, chartData.maxY),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.06),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: readings.length <= 1
                                ? 1
                                : (readings.length - 1).toDouble(),
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index < 0 || index >= readings.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('d MMM')
                                      .format(readings[index].date),
                                  style: const TextStyle(
                                    color: _secondaryText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: _lineBarsForMetric(chartData),
                    ),
                  )
                : _buildEmptyChartState(),
          ),
          if (hasData && _selectedMetric == _VitalsMetric.bloodPressure) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _buildLegendPill('Systolic', _accent),
                const SizedBox(width: 10),
                _buildLegendPill('Diastolic', _diastolicColor),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text(
            hasData
                ? 'Latest trend: $latestDisplay'
                : 'No data for this period',
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openManualEntrySheet,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _surfaceSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: _accent,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChartState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border.withValues(alpha: 0.85)),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: _secondaryText,
                size: 34,
              ),
              SizedBox(height: 12),
              Text(
                'No data for this period',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tap + to add a manual value.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection({
    required String latestDisplay,
    required String averageDisplay,
    required String minMaxDisplay,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard('Latest', latestDisplay),
        _buildStatCard('Average', averageDisplay),
        _buildStatCard(
          'Min / Max',
          minMaxDisplay,
          wide: _selectedMetric == _VitalsMetric.bloodPressure,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {bool wide = false}) {
    final multiline = value.contains('\n');
    return Container(
      width: wide ? 190 : 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: multiline ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryText,
              fontSize: multiline ? 15 : 18,
              fontWeight: FontWeight.w900,
              height: multiline ? 1.25 : 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestEntryCard({
    required String latestDateLabel,
    required String latestDisplay,
    required int readingCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withValues(alpha: 0.75)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: _accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest entry',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  latestDateLabel,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  latestDisplay,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$readingCount reading${readingCount == 1 ? '' : 's'} in range',
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_VitalsReading> _readingsForMetric(
    List<HealthEntry> entries,
    _VitalsMetric metric,
  ) {
    final chronological = entries.toList().reversed.toList(growable: false);
    final readings = <_VitalsReading>[];

    for (final entry in chronological) {
      switch (metric) {
        case _VitalsMetric.heartRate:
          if (entry.heartRate != null) {
            readings.add(
              _VitalsReading(
                date: entry.entryDate,
                primary: entry.heartRate!.toDouble(),
              ),
            );
          }
          break;
        case _VitalsMetric.stress:
          if (entry.stressLevel != null) {
            readings.add(
              _VitalsReading(
                date: entry.entryDate,
                primary: entry.stressLevel!.toDouble(),
              ),
            );
          }
          break;
        case _VitalsMetric.bloodPressure:
          if (entry.systolicBp != null && entry.diastolicBp != null) {
            readings.add(
              _VitalsReading(
                date: entry.entryDate,
                primary: entry.systolicBp!.toDouble(),
                secondary: entry.diastolicBp!.toDouble(),
              ),
            );
          }
          break;
        case _VitalsMetric.spO2:
          if (entry.spO2 != null) {
            readings.add(
              _VitalsReading(
                date: entry.entryDate,
                primary: entry.spO2!.toDouble(),
              ),
            );
          }
          break;
        case _VitalsMetric.temperature:
          if (entry.bodyTemperature != null) {
            readings.add(
              _VitalsReading(
                date: entry.entryDate,
                primary: entry.bodyTemperature!,
              ),
            );
          }
          break;
        case _VitalsMetric.weight:
          if (entry.weight != null) {
            readings.add(
              _VitalsReading(
                date: entry.entryDate,
                primary: entry.weight!,
              ),
            );
          }
          break;
      }
    }

    return readings;
  }

  List<_VitalsReading> _filterReadingsForRange(
    List<_VitalsReading> readings,
    _VitalsTimeRange range,
  ) {
    if (range == _VitalsTimeRange.max) {
      return readings;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (range == _VitalsTimeRange.day) {
      return readings
          .where((reading) => _sameDate(reading.date, today))
          .toList(growable: false);
    }

    final days = range == _VitalsTimeRange.week ? 7 : 30;
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));

    return readings.where((reading) {
      final date = DateTime(
        reading.date.year,
        reading.date.month,
        reading.date.day,
      );
      return !date.isBefore(start) && date.isBefore(end);
    }).toList(growable: false);
  }

  _VitalsChartData _chartDataForMetric(
    List<_VitalsReading> readings,
    _VitalsMetric metric,
  ) {
    final primary = <FlSpot>[];
    final secondary = <FlSpot>[];
    final values = <double>[];

    for (var i = 0; i < readings.length; i++) {
      final reading = readings[i];
      primary.add(FlSpot(i.toDouble(), reading.primary));
      values.add(reading.primary);
      if (reading.secondary != null) {
        secondary.add(FlSpot(i.toDouble(), reading.secondary!));
        values.add(reading.secondary!);
      }
    }

    if (values.isEmpty) {
      return const _VitalsChartData(
        primary: [],
        secondary: [],
        minY: 0,
        maxY: 1,
      );
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs();
    double padding;
    if (metric == _VitalsMetric.bloodPressure) {
      padding = range == 0 ? 12 : range * 0.18;
    } else if (metric == _VitalsMetric.temperature) {
      padding = range == 0 ? 1.5 : range * 0.25;
    } else if (metric == _VitalsMetric.weight) {
      padding = range == 0 ? 2 : range * 0.18;
    } else {
      padding = range == 0 ? 8 : range * 0.2;
    }

    final minY = (minValue - padding).clamp(0, double.infinity).toDouble();
    final maxY = (maxValue + padding).toDouble();
    return _VitalsChartData(
      primary: primary,
      secondary: secondary,
      minY: minY == maxY ? maxY + 1 : minY,
      maxY: minY == maxY ? maxY + 1 : maxY,
    );
  }

  List<LineChartBarData> _lineBarsForMetric(_VitalsChartData chartData) {
    const primaryColor = _accent;
    const secondaryColor = _diastolicColor;
    final primaryBar = LineChartBarData(
      spots: chartData.primary,
      isCurved: true,
      color: primaryColor,
      barWidth: 3,
      dotData: FlDotData(show: chartData.primary.length == 1),
      belowBarData: BarAreaData(
        show: true,
        color: primaryColor.withValues(alpha: 0.12),
      ),
    );

    if (chartData.secondary.isEmpty) {
      return [primaryBar];
    }

    final secondaryBar = LineChartBarData(
      spots: chartData.secondary,
      isCurved: true,
      color: secondaryColor,
      barWidth: 3,
      dotData: FlDotData(show: chartData.secondary.length == 1),
    );

    return [primaryBar, secondaryBar];
  }

  Widget _buildLegendPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  double _chartInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 8) {
      return 1;
    }
    if (range <= 20) {
      return 2;
    }
    if (range <= 60) {
      return 5;
    }
    return 10;
  }

  String _formatLatest(List<_VitalsReading> readings, _VitalsMetric metric) {
    if (readings.isEmpty) {
      return '—';
    }
    return _formatReading(readings.last, metric);
  }

  String _formatAverage(List<_VitalsReading> readings, _VitalsMetric metric) {
    if (readings.isEmpty) {
      return '—';
    }
    if (metric == _VitalsMetric.bloodPressure) {
      final systolicAvg =
          readings.map((r) => r.primary).reduce((a, b) => a + b) /
              readings.length;
      final diastolicAvg =
          readings.map((r) => r.secondary ?? 0).reduce((a, b) => a + b) /
              readings.length;
      return '${systolicAvg.round()}/${diastolicAvg.round()}';
    }
    final average = readings.map((r) => r.primary).reduce((a, b) => a + b) /
        readings.length;
    return _formatSingleValue(average, metric);
  }

  String _formatMinMax(List<_VitalsReading> readings, _VitalsMetric metric) {
    if (readings.isEmpty) {
      return '—';
    }
    if (metric == _VitalsMetric.bloodPressure) {
      final systolics = readings.map((r) => r.primary).toList();
      final diastolics = readings.map((r) => r.secondary ?? 0).toList();
      final minPair =
          '${systolics.reduce((a, b) => a < b ? a : b).round()}/${diastolics.reduce((a, b) => a < b ? a : b).round()}';
      final maxPair =
          '${systolics.reduce((a, b) => a > b ? a : b).round()}/${diastolics.reduce((a, b) => a > b ? a : b).round()}';
      return 'Lowest: $minPair\nHighest: $maxPair';
    }
    final values = readings.map((r) => r.primary).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return '${_formatSingleValue(minValue, metric)} / ${_formatSingleValue(maxValue, metric)}';
  }

  String _formatReading(_VitalsReading reading, _VitalsMetric metric) {
    if (metric == _VitalsMetric.bloodPressure) {
      return '${reading.primary.round()}/${reading.secondary?.round() ?? 0}';
    }
    return _formatSingleValue(reading.primary, metric);
  }

  String _formatSingleValue(double value, _VitalsMetric metric) {
    switch (metric) {
      case _VitalsMetric.temperature:
      case _VitalsMetric.weight:
        return value.toStringAsFixed(1);
      case _VitalsMetric.heartRate:
      case _VitalsMetric.stress:
      case _VitalsMetric.spO2:
        return value.round().toString();
      case _VitalsMetric.bloodPressure:
        return value.round().toString();
    }
  }
}

class _VitalsManualEntrySheet extends StatefulWidget {
  final _VitalsMetric metric;
  final ApiService api;

  const _VitalsManualEntrySheet({
    required this.metric,
    required this.api,
  });

  @override
  State<_VitalsManualEntrySheet> createState() =>
      _VitalsManualEntrySheetState();
}

class _VitalsManualEntrySheetState extends State<_VitalsManualEntrySheet> {
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _danger = Color(0xFFFF6B6B);

  final _formKey = GlobalKey<FormState>();
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _saving = false;

  _VitalsMetric get _metric => widget.metric;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  String get _title => _vitalsMetricSheetTitle(_metric);

  String get _subtitle {
    return 'Manual entry will be saved for the selected date.';
  }

  String get _unit => _vitalsMetricUnit(_metric);

  DateTime get _selectedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  String get _dateLabel => DateFormat('dd MMM yyyy').format(_selectedDate);

  String get _timeLabel {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final entry = _buildEntry();
      final created = await widget.api.createHealthEntry(entry);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        _VitalsManualEntryResult(
          entry: created,
          selectedDateTime: _selectedDateTime,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      _showVitalsToast(
        context,
        message:
            'Could not save ${_vitalsMetricToastLabel(_metric).toLowerCase()}',
        success: false,
      );
    }
  }

  void _cancel() {
    Navigator.of(context).pop(false);
  }

  HealthEntry _buildEntry() {
    final selected = _selectedDateTime;
    switch (_metric) {
      case _VitalsMetric.heartRate:
        return HealthEntry(
          id: 0,
          entryDate: selected,
          wellbeingScore: 5,
          symptoms: const [],
          heartRate: int.parse(_primaryController.text.trim()),
        );
      case _VitalsMetric.stress:
        return HealthEntry(
          id: 0,
          entryDate: selected,
          wellbeingScore: 5,
          symptoms: const [],
          stressLevel: int.parse(_primaryController.text.trim()),
        );
      case _VitalsMetric.bloodPressure:
        return HealthEntry(
          id: 0,
          entryDate: selected,
          wellbeingScore: 5,
          symptoms: const [],
          systolicBp: int.parse(_primaryController.text.trim()),
          diastolicBp: int.parse(_secondaryController.text.trim()),
        );
      case _VitalsMetric.spO2:
        return HealthEntry(
          id: 0,
          entryDate: selected,
          wellbeingScore: 5,
          symptoms: const [],
          spO2: int.parse(_primaryController.text.trim()),
        );
      case _VitalsMetric.temperature:
        return HealthEntry(
          id: 0,
          entryDate: selected,
          wellbeingScore: 5,
          symptoms: const [],
          bodyTemperature: double.parse(_primaryController.text.trim()),
        );
      case _VitalsMetric.weight:
        return HealthEntry(
          id: 0,
          entryDate: selected,
          wellbeingScore: 5,
          symptoms: const [],
          weight: double.parse(_primaryController.text.trim()),
        );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: _pickerTheme(context),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: _pickerTheme(context),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = picked;
    });
  }

  ThemeData _pickerTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        onPrimary: Colors.white,
        surface: _surface,
        onSurface: _primaryText,
        secondary: _accent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _border),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: _surfaceAlt,
        headerForegroundColor: _primaryText,
        todayForegroundColor: WidgetStateProperty.all(_accent),
        todayBorder: const BorderSide(color: _accent),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: _surface,
        dialBackgroundColor: _surfaceAlt,
        dialHandColor: _accent,
        dialTextColor: _primaryText,
        entryModeIconColor: _secondaryText,
        hourMinuteColor: _surfaceAlt,
        hourMinuteTextColor: _primaryText,
        dayPeriodColor: _surfaceAlt,
        dayPeriodTextColor: _primaryText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: _border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _accent),
      ),
    );
  }

  String? _validatePrimary(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter a value';
    }

    final parsed =
        _metric == _VitalsMetric.temperature || _metric == _VitalsMetric.weight
            ? double.tryParse(text)
            : int.tryParse(text);
    if (parsed == null) {
      return 'Enter a valid number';
    }

    switch (_metric) {
      case _VitalsMetric.heartRate:
        return _rangeError(parsed.toDouble(), 30, 220);
      case _VitalsMetric.stress:
        return _rangeError(parsed.toDouble(), 0, 100);
      case _VitalsMetric.bloodPressure:
        return _rangeError(parsed.toDouble(), 70, 260);
      case _VitalsMetric.spO2:
        return _rangeError(parsed.toDouble(), 50, 100);
      case _VitalsMetric.temperature:
        return _rangeError(parsed.toDouble(), 30, 45);
      case _VitalsMetric.weight:
        return _rangeError(parsed.toDouble(), 1, 300);
    }
  }

  String? _validateSecondary(String? value) {
    if (_metric != _VitalsMetric.bloodPressure) {
      return null;
    }

    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter a value';
    }

    final parsed = int.tryParse(text);
    if (parsed == null) {
      return 'Enter a valid number';
    }

    final rangeError = _rangeError(parsed.toDouble(), 40, 180);
    if (rangeError != null) {
      return rangeError;
    }

    final systolic = int.tryParse(_primaryController.text.trim());
    if (systolic != null && parsed >= systolic) {
      return 'Diastolic should be lower than systolic';
    }

    return null;
  }

  String? _rangeError(double value, double min, double max) {
    if (value < min || value > max) {
      return 'Enter a value between ${min.toStringAsFixed(0)} and ${max.toStringAsFixed(0)}';
    }
    return null;
  }

  InputDecoration _decoration({
    required String label,
    String? suffix,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      labelStyle: const TextStyle(color: _secondaryText),
      hintStyle: const TextStyle(color: _secondaryText),
      suffixStyle: const TextStyle(color: _secondaryText),
      filled: true,
      fillColor: _surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _border.withValues(alpha: 0.9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _border.withValues(alpha: 0.9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _danger, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _buildPrimaryField() {
    if (_metric == _VitalsMetric.bloodPressure) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _primaryController,
              keyboardType: _vitalsMetricKeyboardType(_metric),
              inputFormatters: _vitalsMetricFormatters(_metric),
              style: const TextStyle(color: _primaryText),
              cursorColor: _accent,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _decoration(
                label: 'Systolic',
                suffix: 'mmHg',
                hint: '120',
              ),
              validator: _validatePrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _secondaryController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: _primaryText),
              cursorColor: _accent,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _decoration(
                label: 'Diastolic',
                suffix: 'mmHg',
                hint: '80',
              ),
              validator: _validateSecondary,
            ),
          ),
        ],
      );
    }

    return TextFormField(
      controller: _primaryController,
      keyboardType: _vitalsMetricKeyboardType(_metric),
      inputFormatters: _vitalsMetricFormatters(_metric),
      style: const TextStyle(color: _primaryText),
      cursorColor: _accent,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _decoration(
        label: 'Value',
        suffix: _unit.isEmpty ? null : _unit,
        hint: switch (_metric) {
          _VitalsMetric.heartRate => '72',
          _VitalsMetric.stress => '40',
          _VitalsMetric.spO2 => '98',
          _VitalsMetric.temperature => '36.6',
          _VitalsMetric.weight => '72.5',
          _VitalsMetric.bloodPressure => '120',
        },
      ),
      validator: _validatePrimary,
    );
  }

  Widget _buildDateTimeButton({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border.withValues(alpha: 0.9)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _accent, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: _border.withValues(alpha: 0.9)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _secondaryText.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: const TextStyle(
                                color: _primaryText,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _subtitle,
                              style: const TextStyle(
                                color: _secondaryText,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _saving ? null : _cancel,
                        icon: const Icon(Icons.close_rounded),
                        color: _secondaryText,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeButton(
                          label: 'Date',
                          value: _dateLabel,
                          icon: Icons.calendar_today_rounded,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimeButton(
                          label: 'Time',
                          value: _timeLabel,
                          icon: Icons.schedule_rounded,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottomInset),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPrimaryField(),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _saving ? null : _cancel,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _secondaryText,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: _border.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _saving ? null : _save,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthActivityPage extends StatelessWidget {
  const HealthActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HealthSnapshot>(
      future: _loadHealthSnapshot(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final activeMedicines =
            data?.medicines.where((medicine) => medicine.isActive).toList() ??
                const <Medicine>[];
        return Scaffold(
          appBar: AppBar(title: const Text('Activity')),
          body: snapshot.connectionState == ConnectionState.waiting &&
                  data == null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LoadingSkeleton.health(context)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(
                        title: 'Activity',
                        subtitle: 'Movement, consistency and routine support.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _MetricCard(
                                label: 'Entries',
                                value:
                                    data?.report.entriesCount.toString() ?? '0',
                                suffix: '',
                                color: AppColors.info)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _MetricCard(
                                label: 'Shield level',
                                value: data?.shield?.level.toString() ?? '—',
                                suffix: '',
                                color: AppColors.success)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ACTIVE MEDICINES',
                                style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 8),
                            if (activeMedicines.isEmpty)
                              const Text('No active medicines to show.')
                            else
                              ...activeMedicines.map(
                                (medicine) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(medicine.name),
                                  subtitle: Text(medicine.scheduleLabel),
                                  trailing: TextButton(
                                    onPressed: () => context
                                        .goNamed('medsDetail', pathParameters: {
                                      'id': medicine.id.toString()
                                    }),
                                    child: const Text('Open'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.add_circle_rounded),
                        title: const Text('Add workout / activity log'),
                        subtitle: const Text(
                            'Create a richer activity tracker entry from the Log tab later.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.goNamed('log'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class HealthSleepPage extends StatelessWidget {
  const HealthSleepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HealthSnapshot>(
      future: _loadHealthSnapshot(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final sleepEntries = data?.entries
                .where((entry) => entry.sleepHours != null)
                .toList()
                .reversed
                .toList() ??
            const <HealthEntry>[];
        final averageSleep = data?.report.averageSleepHours ?? 0;
        return Scaffold(
          appBar: AppBar(title: const Text('Sleep')),
          body: snapshot.connectionState == ConnectionState.waiting &&
                  data == null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LoadingSkeleton.health(context)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(
                        title: 'Sleep',
                        subtitle: 'Track recovery and sleep consistency.'),
                    const SizedBox(height: 12),
                    _MetricCard(
                        label: 'Average sleep',
                        value: averageSleep > 0
                            ? averageSleep.toStringAsFixed(1)
                            : '—',
                        suffix: 'hours',
                        color: AppColors.sleep),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 220,
                          child: sleepEntries.isEmpty
                              ? const Center(child: Text('No sleep data yet.'))
                              : LineChart(
                                  LineChartData(
                                    minY: 0,
                                    maxY: 12,
                                    gridData: const FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      leftTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 26,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < 0 ||
                                                index >= sleepEntries.length) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                  DateFormat('d').format(
                                                      sleepEntries[index]
                                                          .entryDate),
                                                  style: const TextStyle(
                                                      fontSize: 11)),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        isCurved: true,
                                        color: AppColors.sleep,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: true),
                                        spots: [
                                          for (var i = 0;
                                              i < sleepEntries.length;
                                              i++)
                                            FlSpot(
                                                i.toDouble(),
                                                sleepEntries[i].sleepHours ??
                                                    0),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RECENT SLEEP ENTRIES',
                                style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 8),
                            if (sleepEntries.isEmpty)
                              const Text('No entries to show.')
                            else
                              ...sleepEntries.take(5).map(
                                    (entry) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(_formatDate(entry.entryDate)),
                                      subtitle: Text(
                                          '${entry.sleepHours?.toStringAsFixed(1)} h · ${entry.sleepQuality ?? 'Unknown'}'),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class MedicineAddPage extends StatefulWidget {
  const MedicineAddPage({super.key});

  @override
  State<MedicineAddPage> createState() => _MedicineAddPageState();
}

class _MedicineAddPageState extends State<MedicineAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add medicine')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Medicine name')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _frequencyController,
                  decoration: const InputDecoration(labelText: 'Frequency')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(labelText: 'Reason')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Medicine creation is not wired to an API endpoint yet.')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MedicineDetailPage extends StatelessWidget {
  final int medicineId;

  const MedicineDetailPage({required this.medicineId, super.key});

  static const _background = Color(0xFF050608);
  static const _surface = Color(0xFF0D0F14);
  static const _surfaceSoft = Color(0xFF11141B);
  static const _border = Color(0xFF242936);
  static const _primaryText = Color(0xFFF7F8FA);
  static const _mutedText = Color(0xFF8B93A7);
  static const _accent = Color(0xFF5A8CFF);
  static const _success = Color(0xFF36D399);

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.goNamed('meds');
  }

  String _value(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Not set' : text;
  }

  String _date(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Medicine>>(
      future: ApiService.instance.getMedicines(activeOnly: false),
      builder: (context, snapshot) {
        final medicine = snapshot.data
            ?.where((item) => item.id == medicineId)
            .cast<Medicine?>()
            .firstOrNull;
        return Scaffold(
          backgroundColor: _background,
          body: snapshot.connectionState == ConnectionState.waiting &&
                  medicine == null
              ? SafeArea(
                  child: Column(
                    children: [
                      _topBar(context, 'Medicine details'),
                      const Spacer(),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: _accent,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Loading medicine',
                        style: TextStyle(
                          color: _mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                )
              : medicine == null
                  ? SafeArea(
                      child: Column(
                        children: [
                          _topBar(context, 'Medicine details'),
                          const Spacer(),
                          _emptyCard(
                            icon: Icons.search_off_rounded,
                            title: 'Medicine not found',
                            subtitle:
                                'This medicine may have been removed or is no longer available.',
                          ),
                          const Spacer(),
                        ],
                      ),
                    )
                  : SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                        children: [
                          _topBar(context, medicine.name),
                          const SizedBox(height: 14),
                          _heroCard(medicine),
                          const SizedBox(height: 16),
                          _section(
                            title: 'Schedule',
                            children: [
                              _detailRow(Icons.medication_rounded, 'Dosage',
                                  _value(medicine.dosage)),
                              _divider(),
                              _detailRow(Icons.repeat_rounded, 'Frequency',
                                  _value(medicine.frequency)),
                              _divider(),
                              _detailRow(Icons.schedule_rounded, 'Next dose',
                                  _value(medicine.scheduleLabel)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _section(
                            title: 'Notes',
                            children: [
                              _detailRow(Icons.info_outline_rounded, 'Reason',
                                  _value(medicine.reason)),
                              _divider(),
                              _detailRow(
                                  Icons.notes_rounded,
                                  'Side effects / notes',
                                  _value(medicine.sideEffects)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _section(
                            title: 'Timeline',
                            children: [
                              _detailRow(Icons.calendar_today_rounded,
                                  'Start date', _date(medicine.startDate)),
                              _divider(),
                              _detailRow(Icons.event_rounded, 'End date',
                                  _date(medicine.endDate)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Dose logging API is not wired yet.'),
                                    backgroundColor: _surface,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              icon: const Icon(Icons.add_circle_rounded),
                              label: const Text('Log dose',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context, String title) {
    return Row(
      children: [
        _iconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => _goBack(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _surfaceSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: _primaryText, size: 22),
        ),
      ),
    );
  }

  Widget _heroCard(Medicine medicine) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: _accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _value(medicine.dosage),
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(
                medicine.isActive ? 'Active' : 'Inactive',
                medicine.isActive ? _success : _mutedText,
                medicine.isActive
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_outline_rounded,
              ),
              _pill(_value(medicine.frequency), _accent, Icons.repeat_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _surfaceSoft,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _accent, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 66),
      child: Divider(height: 1, color: _border),
    );
  }

  Widget _pill(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accent, size: 34),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiaryEntryViewPage extends StatelessWidget {
  final String date;

  const DiaryEntryViewPage({required this.date, super.key});

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(date);
    return FutureBuilder<List<HealthEntry>>(
      future: ApiService.instance.getHealthEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <HealthEntry>[];
        final match = parsedDate == null
            ? null
            : entries
                .where((entry) =>
                    entry.entryDate.year == parsedDate.year &&
                    entry.entryDate.month == parsedDate.month &&
                    entry.entryDate.day == parsedDate.day)
                .firstOrNull;

        return Scaffold(
          appBar: AppBar(title: const Text('Diary entry')),
          body: snapshot.connectionState == ConnectionState.waiting &&
                  entries.isEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LoadingSkeleton.profile(context)))
              : match == null
                  ? Center(
                      child: Text(
                          'No diary entry found for ${date.isEmpty ? 'this date' : date}.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatDate(match.entryDate),
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text('Mood: ${match.mood ?? '—'}'),
                                Text(
                                    'Sleep: ${match.sleepHours?.toStringAsFixed(1) ?? '—'} hours'),
                                Text(
                                    'Energy: ${match.energyLevel?.toString() ?? '—'}'),
                                Text(
                                    'Stress: ${match.stressLevel?.toString() ?? '—'}'),
                                const SizedBox(height: 8),
                                Text(
                                    'Symptoms: ${match.symptoms.isEmpty ? 'None' : match.symptoms.join(', ')}'),
                                const SizedBox(height: 8),
                                Text(
                                    'Notes: ${extractNote(match.notes).isEmpty ? 'No notes' : extractNote(match.notes)}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

class ProfileEditRoutePage extends StatelessWidget {
  const ProfileEditRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: ApiService.instance.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
              body: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LoadingSkeleton.profile(context))));
        }
        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(
              body: Center(child: Text('No user data available.')));
        }
        return EditProfileScreen(
          user: user,
          onSaved: () => context.pop(),
        );
      },
    );
  }
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  static const _notificationsKey = 'healthtrackme_notifications_enabled';
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _green = Color(0xFF5FB878);
  static const _danger = Color(0xFFFF6B6B);

  bool _notificationsEnabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _loaded = true;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    if (mounted) setState(() => _notificationsEnabled = value);
  }

  Future<void> _deleteAllData() async {
    final confirm = await _confirmDialog(
      title: 'Delete all data?',
      message: 'This will permanently delete your data.',
      action: 'Delete',
      danger: true,
    );
    if (confirm != true) return;

    final user = await ApiService.instance.getCurrentUser();
    if (!mounted || user == null) return;
    final ok = await ApiService.instance.deleteUser(user.id);
    if (!mounted) return;
    _snack(ok ? 'Account deleted' : 'Could not delete account');
  }

  Future<void> _showApiConfiguration() async {
    final api = ApiService.instance;
    final debugInfo = await api.getDebugInfo();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
        title: const Text(
          'API Configuration',
          style: TextStyle(color: _primaryText, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _debugLine('Base URL', debugInfo['currentBaseUrl'].toString()),
            _debugLine('Platform', debugInfo['isWeb'] ? 'Web' : 'Mobile'),
            _debugLine(
              'API reachable',
              debugInfo['canReachApi'] == true ? 'Yes' : 'No',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await api.resetApiConfiguration();
              if (!ctx.mounted || !mounted) return;
              Navigator.pop(ctx);
              _snack('API configuration reset');
            },
            child: const Text('Reset API', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String action,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: _secondaryText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              action,
              style: TextStyle(color: danger ? _danger : _accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _debugLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: _secondaryText,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _topBar(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _section('Notifications', [
                        _SettingsTile(
                          icon: Icons.notifications_active_outlined,
                          accent: _accent,
                          title: 'Enable notifications',
                          subtitle:
                              'Allow HealthTrackMe to send reminders and alerts',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: _saveNotifications,
                            activeThumbColor: _accent,
                          ),
                          onTap: () =>
                              _saveNotifications(!_notificationsEnabled),
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _section('Data & Privacy', [
                        _SettingsTile(
                          icon: Icons.upload_file_outlined,
                          accent: _green,
                          title: 'Export data',
                          subtitle: 'Download your health data',
                          onTap: () => context.pushNamed('profileExport'),
                        ),
                        _SettingsTile(
                          icon: Icons.delete_outline,
                          accent: _danger,
                          title: 'Delete all my data',
                          subtitle: 'Permanent account data removal',
                          onTap: _deleteAllData,
                        ),
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          accent: _accent,
                          title: 'Privacy policy',
                          subtitle: 'Review privacy information',
                          onTap: () => _snack('Open privacy policy'),
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _section('Developer / Debug', [
                        _SettingsTile(
                          icon: Icons.api_outlined,
                          accent: _accent,
                          title: 'API Configuration',
                          subtitle: 'View and reset API settings',
                          onTap: _showApiConfiguration,
                        ),
                      ]),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _IconButtonSurface(
          icon: Icons.arrow_back,
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _primaryText,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _SettingsCard(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const _SettingsDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ProfileSettingsPageState._border.withValues(alpha: 0.75),
        ),
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              _SettingsIconTile(icon: icon, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._secondaryText,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _ProfileSettingsPageState._secondaryText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingsIconTile({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _IconButtonSurface extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonSurface({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _ProfileSettingsPageState._surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _ProfileSettingsPageState._border),
          ),
          child: Icon(
            icon,
            color: _ProfileSettingsPageState._primaryText,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Container(
        height: 1,
        color: _ProfileSettingsPageState._border.withValues(alpha: 0.45),
      ),
    );
  }
}

class ProfileMedicalHistoryPage extends StatelessWidget {
  const ProfileMedicalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: ApiService.instance.getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Medical history')),
          body: snapshot.connectionState == ConnectionState.waiting &&
                  user == null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LoadingSkeleton.profile(context)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(
                        title: 'Medical history',
                        subtitle:
                            'Conditions, allergies, surgeries and vaccinations.'),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_hospital_outlined),
                        title: const Text('Conditions'),
                        subtitle: Text(
                            user?.medicalConditions?.isNotEmpty == true
                                ? user!.medicalConditions!
                                : 'No conditions saved yet.'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: const Text('Allergies'),
                        subtitle: Text(user?.allergies?.isNotEmpty == true
                            ? user!.allergies!
                            : 'No allergies saved yet.'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.healing_outlined),
                        title: Text('Surgeries'),
                        subtitle: Text(
                            'Not yet stored in the current backend profile model.'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.vaccines_outlined),
                        title: Text('Vaccinations'),
                        subtitle: Text(
                            'Not yet stored in the current backend profile model.'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class ProfileExportPage extends StatefulWidget {
  const ProfileExportPage({super.key});

  @override
  State<ProfileExportPage> createState() => _ProfileExportPageState();
}

class _ProfileExportPageState extends State<ProfileExportPage> {
  bool _exportingHealth = false;
  bool _exportingActivities = false;
  bool _exportingAll = false;

  Future<void> _exportHealthEntries() async {
    setState(() => _exportingHealth = true);
    try {
      final api = ApiService.instance;
      final id = await api.ensureActiveUserId();
      if (id == null) {
        _snack('No active user found.');
        return;
      }

      // Hit the CSV endpoint directly via the raw getter
      final response = await api.exportCsv('/export/health-entries/csv/$id');
      if (response == null || response.isEmpty) {
        _snack('No health entries to export yet.');
        return;
      }
      await Clipboard.setData(ClipboardData(text: response));
      _snack('Health entries CSV copied to clipboard ✓', success: true);
    } catch (e) {
      _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exportingHealth = false);
    }
  }

  Future<void> _exportActivities() async {
    setState(() => _exportingActivities = true);
    try {
      final api = ApiService.instance;
      final id = await api.ensureActiveUserId();
      if (id == null) {
        _snack('No active user found.');
        return;
      }

      final response = await api.exportCsv('/export/sport-activities/csv/$id');
      if (response == null || response.isEmpty) {
        _snack('No sport activities to export yet.');
        return;
      }
      await Clipboard.setData(ClipboardData(text: response));
      _snack('Activities CSV copied to clipboard ✓', success: true);
    } catch (e) {
      _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exportingActivities = false);
    }
  }

  Future<void> _exportAll() async {
    setState(() => _exportingAll = true);
    try {
      final api = ApiService.instance;
      final id = await api.ensureActiveUserId();
      if (id == null) {
        _snack('No active user found.');
        return;
      }

      final response = await api.exportCsv('/export/all/$id');
      if (response == null || response.isEmpty) {
        _snack('No data to export yet.');
        return;
      }
      await Clipboard.setData(ClipboardData(text: response));
      _snack('Full export copied to clipboard ✓', success: true);
    } catch (e) {
      _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exportingAll = false);
    }
  }

  Future<void> _copySummary() async {
    try {
      final summary = await ApiService.instance.getHealthSummary();
      if (!mounted) return;
      if (summary == null || summary.isEmpty) {
        _snack('No summary available yet.');
        return;
      }
      await Clipboard.setData(ClipboardData(text: summary));
      if (!mounted) return;
      _snack('Summary copied to clipboard ✓', success: true);
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'Export data',
            subtitle: 'Download your health data as CSV or copy a summary.',
          ),
          const SizedBox(height: 16),

          // Health summary (text)
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Health summary'),
              subtitle: const Text('AI-generated text summary of your data.'),
              trailing: ElevatedButton(
                onPressed: _copySummary,
                child: const Text('Copy'),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Health entries CSV
          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite_border_rounded),
              title: const Text('Health entries CSV'),
              subtitle:
                  const Text('All logged entries with vitals, mood, sleep…'),
              trailing: _exportingHealth
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: _exportHealthEntries,
                      child: const Text('Export'),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Sport activities CSV
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_run_rounded),
              title: const Text('Sport activities CSV'),
              subtitle: const Text(
                  'All workouts — type, duration, calories, distance.'),
              trailing: _exportingActivities
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: _exportActivities,
                      child: const Text('Export'),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Full export
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Full export'),
              subtitle: const Text(
                  'Summary + all entries + all activities combined.'),
              trailing: _exportingAll
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: _exportAll,
                      child: const Text('All'),
                    ),
            ),
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Tip: paste the copied CSV into Excel, Google Sheets, or Numbers.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShortcutCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;

  const _MetricCard(
      {required this.label,
      required this.value,
      required this.suffix,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: color)),
                if (suffix.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(suffix,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
