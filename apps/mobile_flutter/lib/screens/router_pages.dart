import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
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

bool _isValidSleepHoursValue(double? hours) {
  if (hours == null) {
    return false;
  }
  return hours > 0 && hours <= 16;
}

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
  final DateTime? measuredAt;
  final DateTime? createdAt;
  final double primary;
  final double? secondary;

  const _VitalsReading({
    required this.date,
    this.measuredAt,
    this.createdAt,
    required this.primary,
    this.secondary,
  });
}

class _VitalsChartData {
  final List<FlSpot> primary;
  final List<FlSpot> secondary;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  const _VitalsChartData({
    required this.primary,
    required this.secondary,
    required this.minX,
    required this.maxX,
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
          onClose: (result) => Navigator.of(sheetContext).pop(result),
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

  DateTime _readingDateForDayFilter(_VitalsReading reading) {
    return reading.measuredAt ?? reading.date;
  }

  DateTime _readingTimestampForDayChart(_VitalsReading reading) {
    return reading.measuredAt ?? reading.createdAt ?? reading.date;
  }

  double _hourOfDay(DateTime dateTime) {
    return dateTime.hour +
        (dateTime.minute / 60) +
        (dateTime.second / 3600) +
        (dateTime.millisecond / 3600000);
  }

  _VitalsReading? _readingFromEntry(HealthEntry entry, _VitalsMetric metric) {
    switch (metric) {
      case _VitalsMetric.heartRate:
        final value = entry.heartRate;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
                primary: value.toDouble(),
              );
      case _VitalsMetric.stress:
        final value = entry.stressLevel;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
                primary: value.toDouble(),
              );
      case _VitalsMetric.bloodPressure:
        if (entry.systolicBp == null || entry.diastolicBp == null) {
          return null;
        }
        return _VitalsReading(
          date: entry.entryDate,
          measuredAt: entry.measuredAt,
          createdAt: entry.createdAt,
          primary: entry.systolicBp!.toDouble(),
          secondary: entry.diastolicBp!.toDouble(),
        );
      case _VitalsMetric.spO2:
        final value = entry.spO2;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
                primary: value.toDouble(),
              );
      case _VitalsMetric.temperature:
        final value = entry.bodyTemperature;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
                primary: value,
              );
      case _VitalsMetric.weight:
        final value = entry.weight;
        return value == null
            ? null
            : _VitalsReading(
                date: entry.entryDate,
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
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
        final chartData = _chartDataForMetric(
          readings,
          _selectedMetric,
          _selectedTimeRange,
        );
        final latestReading = readings.isNotEmpty ? readings.last : null;
        final latestDisplay =
            _formatLatest(readings, _selectedMetric, _selectedTimeRange);
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
                              hasData: readings.isNotEmpty,
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
                      minX: chartData.minX,
                      maxX: chartData.maxX,
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
                            interval: _selectedTimeRange == _VitalsTimeRange.day
                                ? 6
                                : readings.length <= 1
                                    ? 1
                                    : (readings.length - 1).toDouble(),
                            getTitlesWidget: (value, meta) {
                              if (_selectedTimeRange == _VitalsTimeRange.day) {
                                final hour = value.round();
                                if (hour % 6 != 0 || hour < 0 || hour > 24) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${hour}h',
                                    style: const TextStyle(
                                      color: _secondaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
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
    required bool hasData,
    required String latestDisplay,
    required String averageDisplay,
    required String minMaxDisplay,
  }) {
    if (!hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border.withValues(alpha: 0.75)),
        ),
        child: const Text(
          'No sleep data for this period',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

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
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
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
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
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
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
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
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
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
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
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
                measuredAt: entry.measuredAt,
                createdAt: entry.createdAt,
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
      final dayReadings = readings
          .where(
              (reading) => _sameDate(_readingDateForDayFilter(reading), today))
          .toList(growable: false);
      dayReadings.sort(
        (a, b) => _readingTimestampForDayChart(a)
            .compareTo(_readingTimestampForDayChart(b)),
      );
      return dayReadings;
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
    _VitalsTimeRange range,
  ) {
    final primary = <FlSpot>[];
    final secondary = <FlSpot>[];
    final values = <double>[];
    final useTimeScale = range == _VitalsTimeRange.day;

    for (var i = 0; i < readings.length; i++) {
      final reading = readings[i];
      final x = useTimeScale
          ? _hourOfDay(_readingTimestampForDayChart(reading))
          : i.toDouble();
      primary.add(FlSpot(x, reading.primary));
      values.add(reading.primary);
      if (reading.secondary != null) {
        secondary.add(FlSpot(x, reading.secondary!));
        values.add(reading.secondary!);
      }
    }

    if (values.isEmpty) {
      return _VitalsChartData(
        primary: const [],
        secondary: const [],
        minX: 0,
        maxX: range == _VitalsTimeRange.day ? 24 : 1,
        minY: 0,
        maxY: 1,
      );
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final valueRange = (maxValue - minValue).abs();
    double padding;
    if (metric == _VitalsMetric.bloodPressure) {
      padding = valueRange == 0 ? 12 : valueRange * 0.18;
    } else if (metric == _VitalsMetric.temperature) {
      padding = valueRange == 0 ? 1.5 : valueRange * 0.25;
    } else if (metric == _VitalsMetric.weight) {
      padding = valueRange == 0 ? 2 : valueRange * 0.18;
    } else {
      padding = valueRange == 0 ? 8 : valueRange * 0.2;
    }

    final minY = (minValue - padding).clamp(0, double.infinity).toDouble();
    final maxY = (maxValue + padding).toDouble();
    return _VitalsChartData(
      primary: primary,
      secondary: secondary,
      minX: 0,
      maxX: useTimeScale
          ? 24
          : (primary.length == 1 ? 1 : (primary.length - 1).toDouble()),
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

  String _formatLatest(
    List<_VitalsReading> readings,
    _VitalsMetric metric,
    _VitalsTimeRange range,
  ) {
    if (readings.isEmpty) {
      return '—';
    }
    final latest = readings.last;
    final value = _formatReading(latest, metric);
    if (range != _VitalsTimeRange.day) {
      return value;
    }
    final time =
        DateFormat('HH:mm').format(_readingTimestampForDayChart(latest));
    return '$value at $time';
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
  final ValueChanged<_VitalsManualEntryResult?> onClose;

  const _VitalsManualEntrySheet({
    required this.metric,
    required this.api,
    required this.onClose,
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
      widget.onClose(
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
    widget.onClose(null);
  }

  HealthEntry _buildEntry() {
    final selected = _selectedDateTime;
    switch (_metric) {
      case _VitalsMetric.heartRate:
        return HealthEntry(
          id: 0,
          entryDate: _selectedDate,
          measuredAt: selected,
          wellbeingScore: 5,
          symptoms: const [],
          heartRate: int.parse(_primaryController.text.trim()),
        );
      case _VitalsMetric.stress:
        return HealthEntry(
          id: 0,
          entryDate: _selectedDate,
          measuredAt: selected,
          wellbeingScore: 5,
          symptoms: const [],
          stressLevel: int.parse(_primaryController.text.trim()),
        );
      case _VitalsMetric.bloodPressure:
        return HealthEntry(
          id: 0,
          entryDate: _selectedDate,
          measuredAt: selected,
          wellbeingScore: 5,
          symptoms: const [],
          systolicBp: int.parse(_primaryController.text.trim()),
          diastolicBp: int.parse(_secondaryController.text.trim()),
        );
      case _VitalsMetric.spO2:
        return HealthEntry(
          id: 0,
          entryDate: _selectedDate,
          measuredAt: selected,
          wellbeingScore: 5,
          symptoms: const [],
          spO2: int.parse(_primaryController.text.trim()),
        );
      case _VitalsMetric.temperature:
        return HealthEntry(
          id: 0,
          entryDate: _selectedDate,
          measuredAt: selected,
          wellbeingScore: 5,
          symptoms: const [],
          bodyTemperature: double.parse(_primaryController.text.trim()),
        );
      case _VitalsMetric.weight:
        return HealthEntry(
          id: 0,
          entryDate: _selectedDate,
          measuredAt: selected,
          wellbeingScore: 5,
          symptoms: const [],
          weight: double.parse(_primaryController.text.trim()),
        );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDate.isAfter(today) ? today : _selectedDate;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: _pickerTheme(context),
          child: Dialog(
            backgroundColor: _surface,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: _border),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: _accent,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Select date',
                            style: TextStyle(
                              color: _primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('EEE, MMM d, yyyy').format(initialDate),
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: CalendarDatePicker(
                        initialDate: initialDate,
                        firstDate: DateTime(2000),
                        lastDate: today,
                        currentDate: today,
                        onDateChanged: (date) {
                          Navigator.of(dialogContext).pop<DateTime>(date);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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

class HealthActivityPage extends StatefulWidget {
  const HealthActivityPage({super.key});

  @override
  State<HealthActivityPage> createState() => _HealthActivityPageState();
}

class _HealthActivityPageState extends State<HealthActivityPage> {
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _surfaceSoft = Color(0xFF11141B);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);

  final ApiService _api = ApiService.instance;
  late Future<List<Map<String, dynamic>>> _activitiesFuture;
  _ActivityType _selectedType = _ActivityType.walking;
  _ActivityTimeRange _selectedTimeRange = _ActivityTimeRange.week;

  bool get _isWalkingTab => _selectedType == _ActivityType.walking;

  static const _activityTypes = [
    _ActivityTypeDefinition(
        _ActivityType.walking, 'Walking', Icons.directions_walk_rounded),
    _ActivityTypeDefinition(
        _ActivityType.running, 'Running', Icons.directions_run_rounded),
    _ActivityTypeDefinition(
        _ActivityType.cycling, 'Cycling', Icons.directions_bike_rounded),
    _ActivityTypeDefinition(
        _ActivityType.workout, 'Workout', Icons.fitness_center_rounded),
    _ActivityTypeDefinition(
        _ActivityType.swimming, 'Swimming', Icons.pool_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _loadActivities();
  }

  Future<List<Map<String, dynamic>>> _loadActivities() async {
    final activities = await _api.getSportActivities();
    activities.sort((a, b) {
      final aDate = _activityDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _activityDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return activities;
  }

  Future<List<Map<String, dynamic>>> _refreshActivities() {
    final refreshed = _loadActivities();
    setState(() => _activitiesFuture = refreshed);
    return refreshed;
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.goNamed('health');
    }
  }

  Future<void> _openManualEntrySheet() async {
    final result = await showModalBottomSheet<_ActivityManualEntryResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ActivityManualEntrySheet(
        api: _api,
        initialType: _selectedType,
        onClose: (result) => Navigator.of(sheetContext).pop(result),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedType = result.type);
    final refreshed = await _refreshActivities();
    if (!mounted) return;
    final confirmed = refreshed.any(
      (activity) => _activityMatchesResult(activity, result),
    );
    _showVitalsToast(
      context,
      message:
          confirmed ? 'Activity added' : 'Activity refresh did not confirm it',
      success: confirmed,
    );
  }

  DateTime? _activityDate(Map<String, dynamic> activity) {
    final raw = activity['activityDate'] ?? activity['start'];
    return raw == null ? null : DateTime.tryParse(raw.toString());
  }

  int _activityDuration(Map<String, dynamic> activity) {
    return int.tryParse(
          (activity['duration'] ?? activity['durationMinutes'] ?? '')
              .toString(),
        ) ??
        0;
  }

  String _activityTypeLabel(Map<String, dynamic> activity) {
    final raw = (activity['activityType'] ?? activity['type'] ?? '').toString();
    for (final definition in _activityTypes) {
      if (definition.label.toLowerCase() == raw.toLowerCase()) {
        return definition.label;
      }
    }
    return raw;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _activityMatchesResult(
    Map<String, dynamic> activity,
    _ActivityManualEntryResult result,
  ) {
    final date = _activityDate(activity);
    if (date == null || !_sameDate(date, result.activityDate)) {
      return false;
    }

    if (_activityTypeLabel(activity) != result.type.label) {
      return false;
    }

    if (_activityDuration(activity) != result.duration) {
      return false;
    }

    if (result.distance != null &&
        _activityDistance(activity) != result.distance) {
      return false;
    }

    if (result.calories != null &&
        _activityCalories(activity) != result.calories) {
      return false;
    }

    if (result.notes != null && _activityNotes(activity) != result.notes) {
      return false;
    }

    return true;
  }

  double? _activityDistance(Map<String, dynamic> activity) {
    return double.tryParse(
      (activity['distance'] ?? activity['distanceKm'] ?? '').toString(),
    );
  }

  int? _activityCalories(Map<String, dynamic> activity) {
    return int.tryParse(
      (activity['caloriesBurned'] ?? activity['calories'] ?? '').toString(),
    );
  }

  int _activitySteps(Map<String, dynamic> activity) {
    return (activity['steps'] as num?)?.toInt() ?? 0;
  }

  String? _activityNotes(Map<String, dynamic> activity) {
    final raw = (activity['notes'] ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }

  List<_ActivityPoint> _pointsForRange(List<Map<String, dynamic>> activities) {
    final points = <_ActivityPoint>[];
    for (final activity in activities.reversed) {
      final date = _activityDate(activity);
      if (date == null) continue;
      if (_activityTypeLabel(activity) != _selectedType.label) continue;
      if (_isWalkingTab) {
        final steps = _activitySteps(activity);
        final duration = _activityDuration(activity);
        final value = steps > 0 ? steps : duration;
        if (value > 0) points.add(_ActivityPoint(date, value));
      } else {
        final duration = _activityDuration(activity);
        if (duration > 0) points.add(_ActivityPoint(date, duration));
      }
    }
    if (_selectedTimeRange == _ActivityTimeRange.max) return points;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedTimeRange == _ActivityTimeRange.day) {
      return points.where((p) => _sameDate(p.date, today)).toList();
    }
    final days = _selectedTimeRange == _ActivityTimeRange.week ? 7 : 30;
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));
    return points.where((p) {
      final date = DateTime(p.date.year, p.date.month, p.date.day);
      return !date.isBefore(start) && date.isBefore(end);
    }).toList();
  }

  _ActivityChartData _chartData(List<_ActivityPoint> points) {
    if (points.isEmpty) {
      return const _ActivityChartData([], 0, 1);
    }
    final spots = <FlSpot>[];
    var maxValue = 0.0;
    for (var i = 0; i < points.length; i++) {
      final value = points[i].value.toDouble();
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxValue) maxValue = value;
    }
    final padding = maxValue <= 30 ? 10.0 : maxValue * 0.18;
    return _ActivityChartData(spots, 0, maxValue + padding);
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '-';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$remaining min';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }

  String _latest(List<_ActivityPoint> points) {
    if (points.isEmpty) return '-';
    return _isWalkingTab
        ? '${points.last.value} steps'
        : _formatDuration(points.last.value);
  }

  String _average(List<_ActivityPoint> points) {
    if (points.isEmpty) return '-';
    final total = points.fold<int>(0, (sum, point) => sum + point.value);
    final avg = (total / points.length).round();
    return _isWalkingTab ? '$avg steps' : _formatDuration(avg);
  }

  String _total(List<_ActivityPoint> points) {
    if (points.isEmpty) return '-';
    final sum = points.fold<int>(0, (sum, point) => sum + point.value);
    return _isWalkingTab ? '$sum steps' : _formatDuration(sum);
  }

  bool _isActivityInSelectedRange(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(date.year, date.month, date.day);

    switch (_selectedTimeRange) {
      case _ActivityTimeRange.day:
        return _sameDate(activityDate, today);
      case _ActivityTimeRange.week:
        final start = today.subtract(const Duration(days: 6));
        final end = today.add(const Duration(days: 1));
        return !activityDate.isBefore(start) && activityDate.isBefore(end);
      case _ActivityTimeRange.month:
        final start = today.subtract(const Duration(days: 29));
        final end = today.add(const Duration(days: 1));
        return !activityDate.isBefore(start) && activityDate.isBefore(end);
      case _ActivityTimeRange.max:
        return true;
    }
  }

  List<Map<String, dynamic>> _filteredActivitiesForRange(
    List<Map<String, dynamic>> activities,
  ) {
    final filtered = activities.where((activity) {
      final date = _activityDate(activity);
      final duration = _activityDuration(activity);
      final steps = _activitySteps(activity);
      final hasData = _isWalkingTab ? (steps > 0 || duration > 0) : duration > 0;
      return _activityTypeLabel(activity) == _selectedType.label &&
          date != null &&
          hasData &&
          _isActivityInSelectedRange(date);
    }).toList(growable: false);

    filtered.sort((a, b) {
      final aDate = _activityDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _activityDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  String _formatDistance(double distance) {
    final text = distance == distance.truncateToDouble()
        ? distance.toStringAsFixed(0)
        : distance.toStringAsFixed(1);
    return '$text km';
  }

  String _formatCalories(int calories) => '$calories kcal';

  String _formatActivitySummary(Map<String, dynamic> activity) {
    final parts = <String>[];

    final duration = _activityDuration(activity);
    if (duration > 0) parts.add(_formatDuration(duration));

    final distance = _activityDistance(activity);
    if (distance != null) parts.add(_formatDistance(distance));

    final calories = _activityCalories(activity);
    if (calories != null) parts.add(_formatCalories(calories));

    final steps = _activitySteps(activity);
    if (steps > 0) parts.add('$steps steps');

    return parts.isEmpty ? '-' : parts.join(' • ');
  }

  String _formatActivityDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('d MMM yyyy').format(date);
  }

  String _activityListTitle() {
    switch (_selectedTimeRange) {
      case _ActivityTimeRange.day:
        return "Today's ${_selectedType.label}";
      case _ActivityTimeRange.week:
        return '${_selectedType.label} this week';
      case _ActivityTimeRange.month:
        return '${_selectedType.label} this month';
      case _ActivityTimeRange.max:
        return 'All ${_selectedType.label} activities';
    }
  }

  String _activityEmptyStateMessage() {
    return 'No ${_selectedType.label} activities for this period';
  }

  void _openActivityDetails(Map<String, dynamic> activity) {
    final typeLabel = _activityTypeLabel(activity);
    final date = _activityDate(activity);
    final steps = _activitySteps(activity);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityDetailsSheet(
        title: '$typeLabel details',
        dateLabel: _formatActivityDate(date),
        durationLabel: _formatDuration(_activityDuration(activity)),
        distanceLabel: _activityDistance(activity) == null
            ? null
            : _formatDistance(_activityDistance(activity)!),
        caloriesLabel: _activityCalories(activity) == null
            ? null
            : _formatCalories(_activityCalories(activity)!),
        stepsLabel: steps > 0 ? '$steps steps' : null,
        notes: _activityNotes(activity),
      ),
    );
  }

  Widget _buildActivityListSection(List<Map<String, dynamic>> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _activityListTitle(),
          style: const TextStyle(
            color: _primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        if (activities.isEmpty)
          _buildActivityEmptyState()
        else
          Column(
            children: [
              for (var i = 0; i < activities.length; i++) ...[
                _buildActivityListCard(activities[i]),
                if (i < activities.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildActivityEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withValues(alpha: 0.75)),
      ),
      child: Text(
        _activityEmptyStateMessage(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildActivityListCard(Map<String, dynamic> activity) {
    final title = _activityTypeLabel(activity);
    final summary = _formatActivitySummary(activity);
    final dateLabel = _formatActivityDate(_activityDate(activity));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openActivityDetails(activity),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withValues(alpha: 0.75)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: _secondaryText,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
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
                'Activity',
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

  Widget _activitySelector() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < _activityTypes.length; i++) ...[
              _activityChip(_activityTypes[i]),
              if (i < _activityTypes.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      );

  Widget _activityChip(_ActivityTypeDefinition definition) {
    final selected = definition.type == _selectedType;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _selectedType = definition.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: 0.16) : _surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _accent : _border.withValues(alpha: 0.9),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(definition.icon,
              size: 16, color: selected ? _accent : _secondaryText),
          const SizedBox(width: 8),
          Text(
            definition.label,
            style: TextStyle(
              color: selected ? _primaryText : _secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _timeRangeSelector() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border.withValues(alpha: 0.75)),
        ),
        child: Row(
          children: [
            for (final range in _ActivityTimeRange.values)
              Expanded(child: _timeRangeSegment(range)),
          ],
        ),
      );

  Widget _timeRangeSegment(_ActivityTimeRange range) {
    final selected = range == _selectedTimeRange;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedTimeRange = range),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: 0.18) : _surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _accent : Colors.transparent),
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

  Widget _chartCard(_ActivityChartData chartData, List<_ActivityPoint> points) {
    final hasData = points.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withValues(alpha: 0.75)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              _selectedType.label,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _addButton(),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: hasData ? _chart(chartData, points) : _emptyChart(),
        ),
        const SizedBox(height: 14),
        Text(
          hasData
              ? (_isWalkingTab
                  ? 'Step count in the selected range.'
                  : 'Activity duration in the selected range.')
              : 'No activity data for this period',
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ]),
    );
  }

  Widget _chart(_ActivityChartData data, List<_ActivityPoint> points) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: data.spots.length == 1 ? 1 : (data.spots.length - 1).toDouble(),
        minY: data.minY,
        maxY: data.maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: data.maxY <= 90
              ? 15
              : data.maxY <= 300
                  ? 60
                  : (data.maxY / 4).ceilToDouble(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: points.length <= 7
                  ? 1
                  : ((points.length / 4).ceil()).toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d MMM').format(points[index].date),
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
        lineBarsData: [
          LineChartBarData(
            spots: data.spots,
            isCurved: data.spots.length > 1,
            color: _accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: data.spots.length == 1),
            belowBarData: BarAreaData(
              show: data.spots.length > 1,
              color: _accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton() => Material(
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
            child: const Icon(Icons.add_rounded, color: _accent, size: 22),
          ),
        ),
      );

  Widget _emptyChart() => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border.withValues(alpha: 0.85)),
        ),
        child: const Center(
          child: Text(
            'No activity data for this period',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  Widget _stats(List<_ActivityPoint> points) {
    if (points.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border.withValues(alpha: 0.75)),
        ),
        child: const Text(
          'No activity data for this period',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Wrap(spacing: 12, runSpacing: 12, children: [
      _statCard('Latest', _latest(points)),
      _statCard('Average', _average(points)),
      _statCard('Total', _total(points)),
    ]);
  }

  Widget _statCard(String label, String value) => Container(
        width: 148,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border.withValues(alpha: 0.75)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _activitiesFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final activities = snapshot.data ?? const <Map<String, dynamic>>[];
        final filteredActivities = _filteredActivitiesForRange(activities);
        final points = _pointsForRange(filteredActivities);
        final chartData = _chartData(points);

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(children: [
              _topBar(),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _accent),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                        children: [
                          _activitySelector(),
                          const SizedBox(height: 16),
                          _timeRangeSelector(),
                          const SizedBox(height: 16),
                          _chartCard(chartData, points),
                          const SizedBox(height: 16),
                          _stats(points),
                          const SizedBox(height: 16),
                          _buildActivityListSection(filteredActivities),
                        ],
                      ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

enum _ActivityType {
  walking('Walking'),
  running('Running'),
  cycling('Cycling'),
  workout('Workout'),
  swimming('Swimming');

  final String label;

  const _ActivityType(this.label);
}

enum _ActivityTimeRange {
  day('1D'),
  week('1W'),
  month('1M'),
  max('Max');

  final String label;

  const _ActivityTimeRange(this.label);
}

class _ActivityTypeDefinition {
  final _ActivityType type;
  final String label;
  final IconData icon;

  const _ActivityTypeDefinition(this.type, this.label, this.icon);
}

class _ActivityPoint {
  final DateTime date;
  final int value;

  const _ActivityPoint(this.date, this.value);
}

class _ActivityChartData {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;

  const _ActivityChartData(this.spots, this.minY, this.maxY);
}

class _ActivityManualEntryResult {
  final _ActivityType type;
  final DateTime activityDate;
  final int duration;
  final double? distance;
  final int? calories;
  final String? notes;

  const _ActivityManualEntryResult(
    this.type,
    this.activityDate,
    this.duration, {
    this.distance,
    this.calories,
    this.notes,
  });
}

class _ActivityDetailsSheet extends StatelessWidget {
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _surfaceSoft = Color(0xFF11141B);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);

  final String title;
  final String dateLabel;
  final String durationLabel;
  final String? distanceLabel;
  final String? caloriesLabel;
  final String? stepsLabel;
  final String? notes;

  const _ActivityDetailsSheet({
    required this.title,
    required this.dateLabel,
    required this.durationLabel,
    required this.distanceLabel,
    required this.caloriesLabel,
    required this.stepsLabel,
    required this.notes,
  });

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailNotes(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withValues(alpha: 0.8)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: _primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final hasNotes = notes != null && notes!.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: _border.withValues(alpha: 0.85)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _secondaryText.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _primaryText,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _surfaceSoft,
                          side: BorderSide(
                            color: _border.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border.withValues(alpha: 0.75)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('Date', dateLabel),
                      if (stepsLabel != null)
                        _detailRow('Steps', stepsLabel!),
                      _detailRow('Duration', durationLabel),
                      if (distanceLabel != null)
                        _detailRow('Distance', distanceLabel!),
                      if (caloriesLabel != null)
                        _detailRow('Calories burned', caloriesLabel!),
                      if (hasNotes) ...[
                        const Text(
                          'Notes',
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _detailNotes(notes!.trim()),
                      ],
                    ],
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

class _ActivityManualEntrySheet extends StatefulWidget {
  final ApiService api;
  final _ActivityType initialType;
  final ValueChanged<_ActivityManualEntryResult?> onClose;

  const _ActivityManualEntrySheet({
    required this.api,
    required this.initialType,
    required this.onClose,
  });

  @override
  State<_ActivityManualEntrySheet> createState() =>
      _ActivityManualEntrySheetState();
}

class _ActivityManualEntrySheetState extends State<_ActivityManualEntrySheet> {
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _surfaceSoft = Color(0xFF11141B);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _danger = Color(0xFFFF6B6B);

  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  late _ActivityType _selectedType;
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? suffix}) =>
      InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: const TextStyle(color: _secondaryText),
        suffixStyle: const TextStyle(color: _secondaryText),
        filled: true,
        fillColor: _surfaceAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _border.withValues(alpha: 0.85)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _danger),
        ),
        errorStyle: const TextStyle(color: _danger),
      );

  TextStyle get _inputStyle =>
      const TextStyle(color: _primaryText, fontWeight: FontWeight.w700);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDate.isAfter(today) ? today : _selectedDate;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => Theme(
        data: Theme.of(context).copyWith(
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
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _accent),
          ),
        ),
        child: Dialog(
          backgroundColor: _surface,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: _border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: _accent,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select date',
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('EEE, MMM d, yyyy').format(initialDate),
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: CalendarDatePicker(
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: today,
                      currentDate: today,
                      onDateChanged: (date) {
                        Navigator.of(dialogContext).pop<DateTime>(date);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() =>
          _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final duration = int.parse(_durationController.text.trim());
    final distance = _selectedType == _ActivityType.workout
        ? null
        : double.tryParse(_distanceController.text.trim());
    final calories = int.tryParse(_caloriesController.text.trim());
    final notes = _notesController.text.trim();
    final payload = <String, dynamic>{
      'activityType': _selectedType.label,
      'activityDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'duration': duration,
      if (distance != null) 'distance': distance,
      if (calories != null) 'caloriesBurned': calories,
      if (notes.isNotEmpty) 'notes': notes,
    };

    setState(() => _saving = true);
    try {
      final saved = await widget.api.createSportActivity(payload);
      if (!mounted) return;
      if (!saved) {
        _showVitalsToast(
          context,
          message: 'Could not save activity',
          success: false,
        );
        setState(() => _saving = false);
        return;
      }
      widget.onClose(
        _ActivityManualEntryResult(
          _selectedType,
          _selectedDate,
          duration,
          distance: distance,
          calories: calories,
          notes: notes.isEmpty ? null : notes,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showVitalsToast(
        context,
        message: 'Could not save activity',
        success: false,
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: _border.withValues(alpha: 0.85)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _secondaryText.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add ${_selectedType.label}',
                          style: const TextStyle(
                            color: _primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: IconButton(
                          onPressed:
                              _saving ? null : () => widget.onClose(null),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _primaryText,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _surfaceSoft,
                            side: BorderSide(
                              color: _border.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: _decoration('Date'),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: _inputStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: _inputStyle,
                    decoration: _decoration('Duration', suffix: 'min'),
                    validator: (value) {
                      final duration = int.tryParse(value?.trim() ?? '') ?? 0;
                      return duration > 0
                          ? null
                          : 'Duration must be greater than 0';
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_selectedType != _ActivityType.workout) ...[
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _distanceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          style: _inputStyle,
                          decoration: _decoration('Distance', suffix: 'km'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: _inputStyle,
                          decoration: _decoration('Calories', suffix: 'kcal'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ] else ...[
                    TextFormField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: _inputStyle,
                      decoration: _decoration('Calories', suffix: 'kcal'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    style: _inputStyle,
                    decoration: _decoration('Notes'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HealthSleepPage extends StatefulWidget {
  const HealthSleepPage({super.key});

  @override
  State<HealthSleepPage> createState() => _HealthSleepPageState();
}

class _HealthSleepPageState extends State<HealthSleepPage> {
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _surfaceSoft = Color(0xFF11141B);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);

  final ApiService _api = ApiService.instance;

  late Future<_HealthSnapshot> _snapshotFuture;
  _SleepTimeRange _selectedTimeRange = _SleepTimeRange.week;

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

  void _selectTimeRange(_SleepTimeRange range) {
    if (_selectedTimeRange == range) {
      return;
    }
    setState(() {
      _selectedTimeRange = range;
    });
  }

  Future<_HealthSnapshot> _refreshSleepData() {
    final refreshed = _loadHealthSnapshot();
    setState(() {
      _snapshotFuture = refreshed;
    });
    return refreshed;
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.goNamed('health');
  }

  Future<void> _openManualEntrySheet() async {
    final result = await showModalBottomSheet<_SleepManualEntryResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SleepManualEntrySheet(api: _api);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    final refreshed = await _refreshSleepData();
    if (!mounted) {
      return;
    }

    final confirmed = _containsRefreshedSleepEntry(refreshed, result);
    if (!confirmed) {
      _showVitalsToast(
        context,
        message: 'Sleep saved, but not returned by refresh',
        success: false,
      );
      return;
    }

    _showVitalsToast(
      context,
      message: 'Sleep added',
      success: true,
    );
  }

  bool _containsRefreshedSleepEntry(
    _HealthSnapshot snapshot,
    _SleepManualEntryResult result,
  ) {
    final created = result.entry;
    return snapshot.entries.any((entry) {
      if (entry.sleepHours == null) {
        return false;
      }

      if (created.id != 0 && entry.id == created.id) {
        return true;
      }

      final sameDate = _sameDate(entry.entryDate, result.entryDate);
      final sameHours = created.sleepHours != null && entry.sleepHours != null
          ? _sameValue(entry.sleepHours!, created.sleepHours!)
          : false;
      final sameBedtime =
          _matchesOptionalString(entry.bedtime, created.bedtime);
      final sameWakeTime =
          _matchesOptionalString(entry.wakeTime, created.wakeTime);
      final sameStars = _matchesOptionalInt(
        entry.sleepQualityStars,
        created.sleepQualityStars,
      );

      return sameDate && sameHours && sameBedtime && sameWakeTime && sameStars;
    });
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameValue(double a, double b) => (a - b).abs() < 0.01;

  bool _matchesOptionalString(String? value, String? expected) {
    final expectedText = expected?.trim();
    if (expectedText == null || expectedText.isEmpty) {
      return true;
    }
    final actualText = value?.trim();
    return actualText != null &&
        actualText.isNotEmpty &&
        actualText == expectedText;
  }

  bool _matchesOptionalInt(int? value, int? expected) {
    if (expected == null) {
      return true;
    }
    return value == expected;
  }

  List<HealthEntry> _sleepEntriesForRange(
    List<HealthEntry> entries,
    _SleepTimeRange range,
  ) {
    final chronological = entries
        .where((entry) => _isValidSleepHoursValue(entry.sleepHours))
        .toList(growable: false)
        .reversed
        .toList(growable: false);

    if (range == _SleepTimeRange.max) {
      return chronological;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (range == _SleepTimeRange.day) {
      return chronological
          .where((entry) => _sameDate(entry.entryDate, today))
          .toList(growable: false);
    }

    final days = range == _SleepTimeRange.week ? 7 : 30;
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));

    return chronological.where((entry) {
      final date = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      return !date.isBefore(start) && date.isBefore(end);
    }).toList(growable: false);
  }

  _SleepChartData _chartDataForEntries(List<HealthEntry> entries) {
    final spots = <FlSpot>[];
    final values = <double>[];

    for (var i = 0; i < entries.length; i++) {
      final hours = entries[i].sleepHours;
      if (!_isValidSleepHoursValue(hours)) {
        continue;
      }

      final validHours = hours!;
      spots.add(FlSpot(spots.length.toDouble(), validHours));
      values.add(validHours);
    }

    if (values.isEmpty) {
      return const _SleepChartData(spots: [], minY: 0, maxY: 1);
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs();
    final padding = range == 0 ? 1.0 : (range * 0.2).clamp(0.8, 2.0).toDouble();
    final minY = (minValue - padding).clamp(0, double.infinity).toDouble();
    final maxY = (maxValue + padding).toDouble();

    return _SleepChartData(
      spots: spots,
      minY: minY == maxY ? maxY + 1 : minY,
      maxY: minY == maxY ? maxY + 1 : maxY,
    );
  }

  String _formatDuration(double hours) {
    final totalMinutes = (hours * 60).round().clamp(0, 16 * 60);
    final wholeHours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${wholeHours}h';
    }
    return '${wholeHours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _formatLatest(List<HealthEntry> entries) {
    final values = _validSleepHours(entries);
    if (values.isEmpty) {
      return '—';
    }
    return _formatDuration(values.last);
  }

  String _formatAverage(List<HealthEntry> entries) {
    final values = _validSleepHours(entries);
    if (values.isEmpty) {
      return '—';
    }
    final average = values.reduce((a, b) => a + b) / values.length;
    return _formatDuration(average);
  }

  String _formatMinMax(List<HealthEntry> entries) {
    final values = _validSleepHours(entries);
    if (values.isEmpty) {
      return '—';
    }
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return 'Low ${_formatDuration(minValue)}\nHigh ${_formatDuration(maxValue)}';
  }

  List<double> _validSleepHours(List<HealthEntry> entries) {
    return entries
        .map((entry) => entry.sleepHours)
        .where((hours) => _isValidSleepHoursValue(hours))
        .cast<double>()
        .toList(growable: false);
  }

  double _bottomTitleInterval(int readingCount) {
    if (readingCount <= 7) {
      return 1;
    }
    return ((readingCount / 4).ceil()).toDouble();
  }

  double _horizontalGridInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 3) {
      return 0.5;
    }
    if (range <= 6) {
      return 1;
    }
    if (range <= 12) {
      return 2;
    }
    return 4;
  }

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
              'Sleep',
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
          for (final range in _SleepTimeRange.values)
            Expanded(
              child: _buildTimeRangeSegment(range),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSegment(_SleepTimeRange range) {
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
    _SleepChartData chartData,
    List<HealthEntry> entries,
  ) {
    final hasData = entries.isNotEmpty;
    final spots = chartData.spots;

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
              const Expanded(
                child: Text(
                  'Sleep',
                  style: TextStyle(
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
                      maxX:
                          spots.length == 1 ? 1 : (spots.length - 1).toDouble(),
                      minY: chartData.minY,
                      maxY: chartData.maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _horizontalGridInterval(
                            chartData.minY, chartData.maxY),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.06),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _bottomTitleInterval(entries.length),
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index < 0 || index >= entries.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('d MMM')
                                      .format(entries[index].entryDate),
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
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: spots.length > 1,
                          color: _accent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: spots.length == 1),
                          belowBarData: BarAreaData(
                            show: spots.length > 1,
                            color: _accent.withValues(alpha: 0.12),
                          ),
                          spots: spots,
                        ),
                      ],
                    ),
                  )
                : _buildEmptyChartState(),
          ),
          const SizedBox(height: 14),
          Text(
            hasData
                ? 'Sleep hours in the selected range.'
                : 'No sleep data for this period',
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
                Icons.bedtime_rounded,
                color: _secondaryText,
                size: 34,
              ),
              SizedBox(height: 12),
              Text(
                'No sleep data for this period',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tap + to add a sleep entry.',
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
        _buildStatCard('Min / Max', minMaxDisplay, wide: true),
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

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: _accent,
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
                              'Could not load sleep',
                              style: TextStyle(
                                color: _primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try again to load the latest sleep entries.',
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
        final sleepEntries =
            _sleepEntriesForRange(data.entries, _selectedTimeRange);
        final chartData = _chartDataForEntries(sleepEntries);
        final latestDisplay = _formatLatest(sleepEntries);
        final averageDisplay = _formatAverage(sleepEntries);
        final minMaxDisplay = _formatMinMax(sleepEntries);

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: isLoading
                      ? _buildLoadingState()
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                          children: [
                            _buildTimeRangeSelector(),
                            const SizedBox(height: 16),
                            _buildChartSection(chartData, sleepEntries),
                            const SizedBox(height: 16),
                            _buildStatsSection(
                              latestDisplay: latestDisplay,
                              averageDisplay: averageDisplay,
                              minMaxDisplay: minMaxDisplay,
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
}

enum _SleepTimeRange {
  day('1D'),
  week('1W'),
  month('1M'),
  max('Max');

  final String label;

  const _SleepTimeRange(this.label);
}

class _SleepChartData {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;

  const _SleepChartData({
    required this.spots,
    required this.minY,
    required this.maxY,
  });
}

class _SleepManualEntryResult {
  final HealthEntry entry;
  final DateTime entryDate;

  const _SleepManualEntryResult({
    required this.entry,
    required this.entryDate,
  });
}

class _SleepManualEntrySheet extends StatefulWidget {
  final ApiService api;

  const _SleepManualEntrySheet({required this.api});

  @override
  State<_SleepManualEntrySheet> createState() => _SleepManualEntrySheetState();
}

class _SleepManualEntrySheetState extends State<_SleepManualEntrySheet> {
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _surfaceSoft = Color(0xFF11141B);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);

  late DateTime _selectedDate;
  late TimeOfDay _bedtime;
  late TimeOfDay _wakeTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _bedtime = const TimeOfDay(hour: 22, minute: 30);
    _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  }

  String get _dateLabel => DateFormat('dd MMM yyyy').format(_selectedDate);

  String get _bedtimeLabel => _formatTimeOfDay(_bedtime);

  String get _wakeTimeLabel => _formatTimeOfDay(_wakeTime);

  int? get _sleepDurationMinutes {
    final bedtimeMinutes = _bedtime.hour * 60 + _bedtime.minute;
    final wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;

    if (wakeMinutes > bedtimeMinutes) {
      return wakeMinutes - bedtimeMinutes;
    }

    return wakeMinutes + (24 * 60) - bedtimeMinutes;
  }

  Duration? get _sleepDuration {
    final minutes = _sleepDurationMinutes;
    if (minutes == null || minutes <= 0) {
      return null;
    }
    return Duration(minutes: minutes);
  }

  double? get _sleepHours {
    final duration = _sleepDuration;
    if (duration == null) {
      return null;
    }
    return double.parse((duration.inMinutes / 60).toStringAsFixed(2));
  }

  String get _durationLabel {
    final duration = _sleepDuration;
    if (duration == null) {
      return '—';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDate.isAfter(today) ? today : _selectedDate;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: _pickerTheme(context),
          child: Dialog(
            backgroundColor: _surface,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: _border),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: _accent,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Select date',
                            style: TextStyle(
                              color: _primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('EEE, MMM d, yyyy').format(initialDate),
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: CalendarDatePicker(
                        initialDate: initialDate,
                        firstDate: DateTime(2000),
                        lastDate: today,
                        currentDate: today,
                        onDateChanged: (date) {
                          Navigator.of(dialogContext).pop<DateTime>(date);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
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
      _bedtime = picked;
    });
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
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
      _wakeTime = picked;
    });
  }

  String _timeFrom(TimeOfDay timeOfDay) => _formatTimeOfDay(timeOfDay);

  Map<String, dynamic> _buildPayload() {
    final entry = HealthEntry(
      id: 0,
      entryDate: _selectedDate,
      wellbeingScore: 5,
      symptoms: const [],
      sleepHours: _sleepHours,
      bedtime: _timeFrom(_bedtime),
      wakeTime: _timeFrom(_wakeTime),
    );
    final payload = entry.toJson();
    payload.remove('sleepQualityStars');
    return payload;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final sleepHours = _sleepHours;
    if (sleepHours == null || sleepHours <= 0) {
      _showVitalsToast(
        context,
        message: 'Sleep duration is invalid',
        success: false,
      );
      return;
    }

    if (sleepHours > 16) {
      _showVitalsToast(
        context,
        message:
            'Sleep duration looks too long. Please check bedtime and wake time.',
        success: false,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final userId = await widget.api.ensureActiveUserId();
      if (userId == null) {
        throw StateError('No active user selected');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('${widget.api.baseUrl}/health-entries/users/$userId'),
        headers: headers,
        body: jsonEncode(_buildPayload()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Could not save health entry');
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        _SleepManualEntryResult(
          entry: HealthEntry(
            id: 0,
            entryDate: _selectedDate,
            wellbeingScore: 5,
            symptoms: const [],
            sleepHours: sleepHours,
            bedtime: _timeFrom(_bedtime),
            wakeTime: _timeFrom(_wakeTime),
          ),
          entryDate: _selectedDate,
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
        message: 'Could not save sleep',
        success: false,
      );
    }
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surfaceAlt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _surfaceSoft,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _border),
                ),
                child: Icon(icon, color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _surfaceSoft,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border),
            ),
            child:
                const Icon(Icons.timelapse_rounded, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Duration',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _durationLabel,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canSave = !_saving && _sleepHours != null;
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: _secondaryText,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _border.withValues(alpha: 0.9)),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: _border.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 26,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _secondaryText.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add sleep',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Save bedtime and wake time. Sleep duration is calculated automatically.',
                  style: TextStyle(
                    color: _secondaryText,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPickerField(
                  label: 'Date',
                  value: _dateLabel,
                  icon: Icons.calendar_today_rounded,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                _buildPickerField(
                  label: 'Bedtime',
                  value: _bedtimeLabel,
                  icon: Icons.nightlight_round,
                  onTap: _pickBedtime,
                ),
                const SizedBox(height: 12),
                _buildPickerField(
                  label: 'Wake time',
                  value: _wakeTimeLabel,
                  icon: Icons.wb_sunny_rounded,
                  onTap: _pickWakeTime,
                ),
                const SizedBox(height: 12),
                _buildDurationCard(),
                const SizedBox(height: 12),
                const Text(
                  'Bedtime and wake time are stored when the API supports these fields.',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
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

  static const _background = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceSoft = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _mutedText = Color(0xFF94A3B8);
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
