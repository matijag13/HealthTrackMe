import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
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

String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date.toLocal());

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HealthSnapshot>(
      future: _loadHealthSnapshot(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.dashboard(context))));
        }

        final data = snapshot.data ??
            _HealthSnapshot(
              user: null,
              entries: const [],
              medicines: const [],
              shield: null,
              report: HealthReport.fromEntries(month: DateTime.now(), entries: const [], medicines: const []),
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
                subtitle: 'Charts, trends, and the monthly report now live inside the Health tab.',
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
                      Text('WELLBEING TREND', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: recent.isEmpty
                            ? EmptyState(animationUrl: 'https://assets2.lottiefiles.com/packages/lf20_jcikwtux.json', title: 'Start tracking today', subtitle: 'Start tracking today — log your first entry', buttonLabel: 'Log entry', onPressed: () => context.goNamed('log'))
                            : LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: 100,
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 26,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= recent.length) return const SizedBox.shrink();
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(DateFormat('d').format(recent[index].entryDate), style: const TextStyle(fontSize: 11)),
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
                                          FlSpot(i.toDouble(), recent[i].effectiveWellbeingScore.toDouble()),
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
                  Expanded(child: _MetricCard(label: 'Wellbeing', value: data.report.averageWellbeingScore.toStringAsFixed(0), suffix: '/ 100', color: AppColors.info)),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricCard(label: 'Sleep', value: averageSleep > 0 ? averageSleep.toStringAsFixed(1) : '—', suffix: 'hours', color: AppColors.sleep)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _MetricCard(label: 'Active meds', value: data.report.activeMedicinesCount.toString(), suffix: '', color: AppColors.weight)),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricCard(label: 'Shield', value: data.shield?.progressPercent.toString() ?? '—', suffix: '%', color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REPORTS', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      const Text('The monthly report has moved into the Health section as a sub-section.'),
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
                    title: Text('Latest entry · ${_formatDate(latest.entryDate)}'),
                    subtitle: Text('Mood: ${latest.mood ?? '—'} · Sleep: ${latest.sleepHours?.toStringAsFixed(1) ?? '—'} h · Notes: ${(latest.notes ?? '').trim().isEmpty ? 'none' : latest.notes!}'),
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
        final latest = data?.entries.isNotEmpty == true ? data!.entries.first : null;
        return Scaffold(
          appBar: AppBar(title: const Text('Vitals')),
          body: snapshot.connectionState == ConnectionState.waiting && data == null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.health(context)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(title: 'Vitals', subtitle: 'Your core health markers at a glance.'),
                    const SizedBox(height: 12),
                    if (latest != null) ...[
                      _MetricCard(label: 'Wellbeing score', value: latest.effectiveWellbeingScore.toString(), suffix: '/ 100', color: AppColors.primary),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _MetricCard(label: 'Energy', value: '${latest.energyLevel ?? 0}', suffix: '/ 100', color: AppColors.success)),
                          const SizedBox(width: 12),
                          Expanded(child: _MetricCard(label: 'Stress', value: '${latest.stressLevel ?? 0}', suffix: '/ 100', color: AppColors.danger)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _MetricCard(label: 'Sleep', value: latest.sleepHours?.toStringAsFixed(1) ?? '—', suffix: 'h', color: AppColors.sleep)),
                          const SizedBox(width: 12),
                          Expanded(child: _MetricCard(label: 'Symptoms', value: latest.symptoms.length.toString(), suffix: '', color: AppColors.warning)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LATEST ENTRY', style: Theme.of(context).textTheme.labelSmall),
                              const SizedBox(height: 8),
                              Text(_formatDate(latest.entryDate)),
                              const SizedBox(height: 8),
                              Text('Mood: ${latest.mood ?? '—'}'),
                              Text('Symptoms: ${latest.symptoms.isEmpty ? 'None' : latest.symptoms.join(', ')}'),
                              Text('Notes: ${(latest.notes ?? '').trim().isEmpty ? 'No notes' : latest.notes!}'),
                            ],
                          ),
                        ),
                      ),
                      ] else ...[
                       EmptyState(animationUrl: 'https://assets2.lottiefiles.com/packages/lf20_1pxqjqps.json', title: 'No readings yet', subtitle: 'Log your vitals in the daily diary', buttonLabel: 'Log vitals', onPressed: () => context.goNamed('log')),
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
        final activeMedicines = data?.medicines.where((medicine) => medicine.isActive).toList() ?? const <Medicine>[];
        return Scaffold(
          appBar: AppBar(title: const Text('Activity')),
          body: snapshot.connectionState == ConnectionState.waiting && data == null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.health(context)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(title: 'Activity', subtitle: 'Movement, consistency and routine support.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _MetricCard(label: 'Entries', value: data?.report.entriesCount.toString() ?? '0', suffix: '', color: AppColors.info)),
                        const SizedBox(width: 12),
                        Expanded(child: _MetricCard(label: 'Shield level', value: data?.shield?.level.toString() ?? '—', suffix: '', color: AppColors.success)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ACTIVE MEDICINES', style: Theme.of(context).textTheme.labelSmall),
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
                                    onPressed: () => context.goNamed('medsDetail', pathParameters: {'id': medicine.id.toString()}),
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
                        subtitle: const Text('Create a richer activity tracker entry from the Log tab later.'),
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
        final sleepEntries = data?.entries.where((entry) => entry.sleepHours != null).toList().reversed.toList() ?? const <HealthEntry>[];
        final averageSleep = data?.report.averageSleepHours ?? 0;
        return Scaffold(
          appBar: AppBar(title: const Text('Sleep')),
          body: snapshot.connectionState == ConnectionState.waiting && data == null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.health(context)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(title: 'Sleep', subtitle: 'Track recovery and sleep consistency.'),
                    const SizedBox(height: 12),
                    _MetricCard(label: 'Average sleep', value: averageSleep > 0 ? averageSleep.toStringAsFixed(1) : '—', suffix: 'hours', color: AppColors.sleep),
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
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 26,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < 0 || index >= sleepEntries.length) return const SizedBox.shrink();
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(DateFormat('d').format(sleepEntries[index].entryDate), style: const TextStyle(fontSize: 11)),
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
                                          for (var i = 0; i < sleepEntries.length; i++)
                                            FlSpot(i.toDouble(), sleepEntries[i].sleepHours ?? 0),
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
                            Text('RECENT SLEEP ENTRIES', style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 8),
                            if (sleepEntries.isEmpty)
                              const Text('No entries to show.')
                            else
                              ...sleepEntries.take(5).map(
                                (entry) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(_formatDate(entry.entryDate)),
                                  subtitle: Text('${entry.sleepHours?.toStringAsFixed(1)} h · ${entry.sleepQuality ?? 'Unknown'}'),
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
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Medicine name')),
              const SizedBox(height: 12),
              TextFormField(controller: _dosageController, decoration: const InputDecoration(labelText: 'Dosage')),
              const SizedBox(height: 12),
              TextFormField(controller: _frequencyController, decoration: const InputDecoration(labelText: 'Frequency')),
              const SizedBox(height: 12),
              TextFormField(controller: _reasonController, decoration: const InputDecoration(labelText: 'Reason')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine creation is not wired to an API endpoint yet.')),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Medicine>>(
      future: ApiService.instance.getMedicines(activeOnly: false),
      builder: (context, snapshot) {
        final medicine = snapshot.data?.where((item) => item.id == medicineId).cast<Medicine?>().firstOrNull;
        return Scaffold(
          appBar: AppBar(title: const Text('Medicine details')),
          body: snapshot.connectionState == ConnectionState.waiting && medicine == null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.medicines(context)))
              : medicine == null
                  ? const Center(child: Text('Medicine not found.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(medicine.name, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text('Dosage: ${medicine.dosage ?? '—'}'),
                                Text('Frequency: ${medicine.frequency ?? '—'}'),
                                Text('Reason: ${medicine.reason ?? '—'}'),
                                Text('Status: ${medicine.isActive ? 'Active' : 'Inactive'}'),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Dose logging API is not wired yet.')),
                                      );
                                    },
                                    icon: const Icon(Icons.add_circle_rounded),
                                    label: const Text('Log dose'),
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
            : entries.where((entry) =>
                entry.entryDate.year == parsedDate.year &&
                entry.entryDate.month == parsedDate.month &&
                entry.entryDate.day == parsedDate.day).firstOrNull;

        return Scaffold(
          appBar: AppBar(title: const Text('Diary entry')),
          body: snapshot.connectionState == ConnectionState.waiting && entries.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.profile(context)))
              : match == null
                  ? Center(child: Text('No diary entry found for ${date.isEmpty ? 'this date' : date}.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatDate(match.entryDate), style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text('Mood: ${match.mood ?? '—'}'),
                                Text('Energy: ${match.energyLevel ?? 0}'),
                                Text('Stress: ${match.stressLevel ?? 0}'),
                                Text('Sleep: ${match.sleepHours?.toStringAsFixed(1) ?? '—'} h'),
                                Text('Symptoms: ${match.symptoms.isEmpty ? 'None' : match.symptoms.join(', ')}'),
                                const SizedBox(height: 8),
                                Text('Notes: ${(match.notes ?? '').trim().isEmpty ? 'No notes' : match.notes!}'),
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
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
           return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.profile(context))));
         }
        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('No user data available.')));
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
  static const _unitsKey = 'healthtrackme_units';
  static const _notificationsKey = 'healthtrackme_notifications_enabled';

  bool _notificationsEnabled = true;
  String _units = 'metric';
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
      _units = prefs.getString(_unitsKey) ?? 'metric';
      _loaded = true;
    });
  }

  Future<void> _save({bool? notificationsEnabled, String? units}) async {
    final prefs = await SharedPreferences.getInstance();
    if (notificationsEnabled != null) {
      _notificationsEnabled = notificationsEnabled;
      await prefs.setBool(_notificationsKey, notificationsEnabled);
    }
    if (units != null) {
      _units = units;
      await prefs.setString(_unitsKey, units);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: !_loaded
          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.profile(context)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(title: 'Account settings', subtitle: 'Theme, notifications and units.'),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    title: const Text('Dark mode'),
                    subtitle: const Text('Persisted with SharedPreferences'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    value: _notificationsEnabled,
                    onChanged: (value) => _save(notificationsEnabled: value),
                    title: const Text('Notifications'),
                    subtitle: const Text('Medication reminders and health alerts'),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Units preference'),
                    subtitle: const Text('Metric or imperial'),
                    trailing: DropdownButton<String>(
                      value: _units,
                      items: const [
                        DropdownMenuItem(value: 'metric', child: Text('Metric')),
                        DropdownMenuItem(value: 'imperial', child: Text('Imperial')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _save(units: value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme choice'),
                    subtitle: Text(themeProvider.isDarkMode ? 'Dark' : 'Light'),
                    trailing: TextButton(
                      onPressed: themeProvider.toggleTheme,
                      child: const Text('Toggle'),
                    ),
                  ),
                ),
              ],
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
          body: snapshot.connectionState == ConnectionState.waiting && user == null
                  ? Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.profile(context)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(title: 'Medical history', subtitle: 'Conditions, allergies, surgeries and vaccinations.'),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_hospital_outlined),
                        title: const Text('Conditions'),
                        subtitle: Text(user?.medicalConditions?.isNotEmpty == true ? user!.medicalConditions! : 'No conditions saved yet.'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: const Text('Allergies'),
                        subtitle: Text(user?.allergies?.isNotEmpty == true ? user!.allergies! : 'No allergies saved yet.'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: const ListTile(
                        leading: Icon(Icons.healing_outlined),
                        title: Text('Surgeries'),
                        subtitle: Text('Not yet stored in the current backend profile model.'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: const ListTile(
                        leading: Icon(Icons.vaccines_outlined),
                        title: Text('Vaccinations'),
                        subtitle: Text('Not yet stored in the current backend profile model.'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class ProfileExportPage extends StatelessWidget {
  const ProfileExportPage({super.key});

  Future<void> _copySummary(BuildContext context) async {
    final summary = await ApiService.instance.getHealthSummary();
    if (!context.mounted) return;
    if (summary == null || summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No export summary available yet.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: summary));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary copied to clipboard.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Export data', subtitle: 'Copy your health summary or prepare it for sharing.'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Health summary'),
              subtitle: const Text('Uses the backend export summary endpoint.'),
              trailing: ElevatedButton(
                onPressed: () => _copySummary(context),
                child: const Text('Copy'),
              ),
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

  const _ShortcutCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  const _MetricCard({required this.label, required this.value, required this.suffix, required this.color});

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
                Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
                if (suffix.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(suffix, style: Theme.of(context).textTheme.bodySmall),
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



