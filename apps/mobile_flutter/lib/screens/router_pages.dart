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

class HealthVitalsPage extends StatelessWidget {
  const HealthVitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HealthSnapshot>(
      future: _loadHealthSnapshot(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final latest =
            data?.entries.isNotEmpty == true ? data!.entries.first : null;
        return Scaffold(
          appBar: AppBar(title: const Text('Vitals')),
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
                        title: 'Vitals',
                        subtitle: 'Your core health markers at a glance.'),
                    const SizedBox(height: 12),
                    if (latest != null) ...[
                      _MetricCard(
                          label: 'Wellbeing score',
                          value: latest.effectiveWellbeingScore.toString(),
                          suffix: '/ 100',
                          color: AppColors.primary),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _MetricCard(
                                  label: 'Energy',
                                  value: '${latest.energyLevel ?? 0}',
                                  suffix: '/ 100',
                                  color: AppColors.success)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _MetricCard(
                                  label: 'Stress',
                                  value: '${latest.stressLevel ?? 0}',
                                  suffix: '/ 100',
                                  color: AppColors.danger)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _MetricCard(
                                  label: 'Sleep',
                                  value:
                                      latest.sleepHours?.toStringAsFixed(1) ??
                                          '—',
                                  suffix: 'h',
                                  color: AppColors.sleep)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _MetricCard(
                                  label: 'Symptoms',
                                  value: latest.symptoms.length.toString(),
                                  suffix: '',
                                  color: AppColors.warning)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LATEST ENTRY',
                                  style:
                                      Theme.of(context).textTheme.labelSmall),
                              const SizedBox(height: 8),
                              Text(_formatDate(latest.entryDate)),
                              const SizedBox(height: 8),
                              Text('Mood: ${latest.mood ?? '—'}'),
                              Text(
                                  'Symptoms: ${latest.symptoms.isEmpty ? 'None' : latest.symptoms.join(', ')}'),
                              Text(
                                  'Notes: ${extractNote(latest.notes).isEmpty ? 'No notes' : extractNote(latest.notes)}'),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      EmptyState(
                          animationUrl:
                              'https://assets2.lottiefiles.com/packages/lf20_1pxqjqps.json',
                          title: 'No readings yet',
                          subtitle: 'Log your vitals in the daily diary',
                          buttonLabel: 'Log vitals',
                          onPressed: () => context.goNamed('log')),
                    ],
                  ],
                ),
        );
      },
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
