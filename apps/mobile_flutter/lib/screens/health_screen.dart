import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../utils/health_utils.dart';

import '../models/models.dart';
import '../models/wearable_device.dart';
import '../services/api_service.dart';
import '../services/wearable_service.dart';
import '../widgets/widgets.dart';

class HealthScreenTabbed extends StatefulWidget {
  const HealthScreenTabbed({super.key});

  @override
  State<HealthScreenTabbed> createState() => _HealthScreenTabbedState();
}

class _HealthScreenTabbedState extends State<HealthScreenTabbed>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService.instance;
  late TabController _tabController;

  List<HealthEntry> _entries = [];
  List<Map<String, dynamic>> _sportActivities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    // declare locals so they are available after the try/catch
    List<HealthEntry> entries = [];
    List<Map<String, dynamic>> sport = [];
    try {
      // ensure there's an active user id before making API calls
      await _api.ensureActiveUserId();

      entries = await _api.getHealthEntries();
      sport = await _fetchSportActivities();

      // Also extract any steps that were recorded using the quick steps field
      // in the Log screen (we store them in HealthEntry.notes as JSON under activity.steps).
      // This ensures the activity tab shows steps even when sport-activity records aren't created.
      final today = DateTime.now();
      final todaysEntries = entries
          .where((e) =>
              e.entryDate.year == today.year &&
              e.entryDate.month == today.month &&
              e.entryDate.day == today.day)
          .toList();
      if (todaysEntries.isNotEmpty) {
        final e = todaysEntries.first;
        if (e.notes != null && e.notes!.startsWith('{')) {
          try {
            final parsed = Map<String, dynamic>.from(jsonDecode(e.notes!));
            final activity = parsed['activity'];
            if (activity is Map && activity['steps'] != null) {
              final s = int.tryParse(activity['steps'].toString()) ?? 0;
              if (s > 0) {
                sport.add({'start': e.entryDate.toIso8601String(), 'steps': s});
              }
            }
          } catch (_) {
            // ignore parsing errors
          }
        }
      }
    } catch (_) {
      // ignore errors; we'll surface an empty state below
    }

    setState(() {
      _entries = entries;
      _sportActivities = sport;
      _loading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSportActivities() async {
    return _api.getSportActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Vitals'),
            Tab(text: 'Activity'),
            Tab(text: 'Sleep'),
            Tab(text: 'Body'),
            Tab(text: 'History'),
            Tab(text: 'Devices'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: TabBarView(controller: _tabController, children: [
                _vitalsTab(context),
                _activityTab(context),
                _sleepTab(context),
                _bodyTab(context),
                _historyTab(context),
                const _DevicesTab(),
              ]),
            ),
    );
  }

  // Vitals tab implementation (uses available fields on HealthEntry)
  Widget _vitalsTab(BuildContext context) {
    if (_entries.isEmpty) {
      return EmptyState(
        animationUrl:
            'https://assets2.lottiefiles.com/packages/lf20_1pxqjqps.json',
        title: 'No readings yet',
        subtitle: 'Log your vitals in the daily diary',
        buttonLabel: 'Log vitals',
        onPressed: () => context.goNamed('log'),
      );
    }

    final vitals = <Map<String, dynamic>>[
      {
        'key': 'energy',
        'label': 'Energy',
        'unit': '%',
        'icon': Icons.bolt,
        'normalMin': 30,
        'normalMax': 80
      },
      {
        'key': 'sleep',
        'label': 'Sleep',
        'unit': 'h',
        'icon': Icons.bedtime,
        'normalMin': 4,
        'normalMax': 9
      },
      {
        'key': 'steps',
        'label': 'Steps (today)',
        'unit': '',
        'icon': Icons.directions_walk,
        'normalMin': 0,
        'normalMax': 10000
      },
      {
        'key': 'stress',
        'label': 'Stress',
        'unit': '%',
        'icon': Icons.psychology,
        'normalMin': 0,
        'normalMax': 50
      },
      {
        'key': 'wellbeing',
        'label': 'Wellbeing',
        'unit': '/10',
        'icon': Icons.emoji_emotions,
        'normalMin': 5,
        'normalMax': 10
      },
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: vitals.length,
      itemBuilder: (context, idx) {
        final v = vitals[idx];
        final series = _lastReadingsForKey(v['key'] as String, count: 14);
        final current = _currentValueForKey(v['key'] as String);
        final color = _colorForValue(
            v['normalMin'] as num?, v['normalMax'] as num?, current);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(v['icon'] as IconData, color: color)),
            title: Text(v['label'] as String),
            subtitle:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(current != null ? '$current ${v['unit']}' : '—'),
              const SizedBox(height: 6),
              SizedBox(height: 36, child: _miniSparkline(series, color)),
            ]),
            trailing: Text(_daysAgoLabelForKey(v['key'] as String)),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => VitalDetailPage(
                    keyName: v['key'] as String,
                    label: v['label'] as String,
                    unit: v['unit'] as String,
                    entries: _entries,
                    normalMin: v['normalMin'] as num?,
                    normalMax: v['normalMax'] as num?))),
          ),
        );
      },
    );
  }

  // Activity tab implementation
  Widget _activityTab(BuildContext context) {
    // Steps per day current week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final days = List.generate(
        7,
        (i) =>
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i));
    final stepsThisWeek = days.map((d) => _sumStepsForDay(d)).toList();
    final prevWeekStart = startOfWeek.subtract(const Duration(days: 7));
    final prevDays = List.generate(
        7,
        (i) => DateTime(
            prevWeekStart.year, prevWeekStart.month, prevWeekStart.day + i));
    final stepsPrevWeek = prevDays.map((d) => _sumStepsForDay(d)).toList();

    final totalSteps = _sportActivities.fold<int>(
            0, (s, a) => s + ((a['steps'] as num?)?.toInt() ?? 0)) +
        _stepsFromEntries;
    final activeDays = stepsThisWeek.where((s) => s > 0).length;
    final avg = totalSteps > 0 ? (totalSteps / 7).round() : 0;
    final streak = _longestStepStreak(_entries);

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SectionHeader(
                title: 'Weekly steps', subtitle: 'This week vs previous week'),
            const SizedBox(height: 12),
            SizedBox(
                height: 180,
                child: _weeklyBarChart(stepsThisWeek, stepsPrevWeek)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                          child: StatItem(
                              icon: '👟',
                              value: totalSteps.toString(),
                              label: 'Total steps',
                              valueColor: AppColors.info)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: StatItem(
                              icon: '📅',
                              value: activeDays.toString(),
                              label: 'Active days',
                              valueColor: AppColors.success)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: StatItem(
                              icon: '📈',
                              value: avg.toString(),
                              label: 'Avg (daily)',
                              valueColor: AppColors.weight)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: StatItem(
                              icon: '🔥',
                              value: streak.toString(),
                              label: 'Longest streak',
                              valueColor: AppColors.teal)),
                    ])
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const SectionHeader(
                title: 'Workouts', subtitle: 'Recent activities'),
            const SizedBox(height: 8),
            if (_sportActivities.isEmpty)
              EmptyState(
                  animationUrl: '',
                  title: 'No workouts yet',
                  subtitle: 'Log a workout to see your stats',
                  buttonLabel: 'Log workout',
                  onPressed: () => context.goNamed('log'))
            else
              ..._sportActivities.map((act) => Slidable(
                    key: ValueKey(act['id'] ?? act.hashCode),
                    endActionPane:
                        ActionPane(motion: const ScrollMotion(), children: [
                      SlidableAction(
                          onPressed: (_) => _deleteActivity(act),
                          backgroundColor: AppColors.danger,
                          icon: Icons.delete,
                          label: 'Delete')
                    ]),
                    child: ListTile(
                      leading: const Icon(Icons.directions_run),
                      title: Text(act['activityType']?.toString() ??
                          act['type']?.toString() ??
                          'Activity'),
                      subtitle: Text(
                          '${act['duration'] ?? act['durationMinutes'] ?? 0} min · ${act['distance'] ?? act['distanceKm'] ?? '—'} km · ${act['caloriesBurned'] ?? act['calories'] ?? '—'} kcal${(act['steps'] as num?)?.toInt() != null ? ' · ${(act['steps'] as num).toInt()} steps' : ''}'),
                      trailing: Text(
                        (act['activityDate'] ?? act['start']) != null
                            ? DateTime.tryParse(
                                        (act['activityDate'] ?? act['start'])
                                            .toString())
                                    ?.toLocal()
                                    .toIso8601String()
                                    .split('T')
                                    .first ??
                                ''
                            : '',
                      ),
                    ),
                  )),
            const SizedBox(height: 20),
            const SectionHeader(
                title: 'Goal', subtitle: 'Weekly step goal progress'),
            const SizedBox(height: 8),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      CircularPercentIndicator(
                          radius: 72,
                          lineWidth: 10,
                          percent: (totalSteps / (70000)).clamp(0.0, 1.0),
                          center: Text(
                              '${((totalSteps / 70000) * 100).clamp(0, 100).round()}%'),
                          progressColor: AppColors.teal),
                      const SizedBox(height: 8),
                      const Text('Goal: 70 000 steps / week (default)')
                    ])))
          ]),
    );
  }

  Future<void> _deleteActivity(Map<String, dynamic> act) async {
    try {
      final id = act['id'];
      if (id == null) {
        return;
      }
      final activityId = id is int ? id : int.tryParse(id.toString());
      if (activityId == null) {
        return;
      }
      final deleted = await _api.deleteSportActivity(activityId);
      if (!mounted) return;
      if (deleted) {
        await _loadAll();
        if (!mounted) return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete activity')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Network error')));
    }
  }

  // Sleep tab implementation
  Widget _sleepTab(BuildContext context) {
    final sleepEntries = _entries.where((e) => e.sleepHours != null).toList();
    if (sleepEntries.isEmpty) {
      return const Center(
          child: Text('No sleep readings yet — log sleep in the daily diary'));
    }
    final last14 = sleepEntries.take(14).toList().reversed.toList();
    return ListView(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SectionHeader(
              title: 'Sleep (last 14 nights)',
              subtitle: 'Hours per night and quality'),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: _sleepBarChart(last14)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: StatItem(
                    icon: '😴',
                    value: last14
                                    .map((e) => e.sleepHours ?? 0)
                                    .fold(0.0, (a, b) => a + b) /
                                last14.length >
                            0
                        ? (last14
                                    .map((e) => e.sleepHours ?? 0)
                                    .fold(0.0, (a, b) => a + b) /
                                last14.length)
                            .toStringAsFixed(1)
                        : '—',
                    label: 'Avg sleep',
                    valueColor: AppColors.sleep)),
            const SizedBox(width: 12),
            Expanded(
                child: StatItem(
                    icon: '🌙',
                    value: last14
                        .map((e) => e.sleepHours ?? 0)
                        .reduce((a, b) => a > b ? a : b)
                        .toStringAsFixed(1),
                    label: 'Best night',
                    valueColor: AppColors.success))
          ]),
          const SizedBox(height: 12),
          const SectionHeader(
              title: 'Bedtime consistency',
              subtitle: 'When you went to bed each night'),
          const SizedBox(height: 12),
          SizedBox(height: 120, child: _bedtimePlot(last14)),
        ]);
  }

  // Body tab implementation
  Widget _bodyTab(BuildContext context) {
    // Extract weight from explicit field OR from notes JSON
    final weightEntries = _entries
        .map((e) {
          double? w = e.weight;
          if (w == null && e.notes != null && e.notes!.startsWith('{')) {
            try {
              final d = jsonDecode(e.notes!) as Map<String, dynamic>;
              final vitals = d['vitals'] as Map?;
              w = double.tryParse(vitals?['weight']?.toString() ?? '');
            } catch (_) {}
          }
          return w != null ? MapEntry(e.entryDate, w) : null;
        })
        .whereType<MapEntry<DateTime, double>>()
        .toList();

    if (weightEntries.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monitor_weight_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No weight data yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Log your weight in the daily diary',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => context.goNamed('log'),
              child: const Text('Log now')),
        ]),
      ));
    }

    weightEntries.sort((a, b) => b.key.compareTo(a.key));
    final latest = weightEntries.first.value;
    final oldest = weightEntries.last.value;
    final change = latest - oldest;

    return ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Current weight card
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.monitor_weight,
                        size: 40, color: Colors.blue),
                    const SizedBox(width: 16),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${latest.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                          Text(
                              change == 0
                                  ? 'No change'
                                  : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg since first entry',
                              style: TextStyle(
                                  color: change > 0
                                      ? Colors.orange
                                      : Colors.green)),
                        ]),
                  ]))),
          const SizedBox(height: 12),
          // Weight trend chart
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Weight trend',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      SizedBox(
                          height: 180,
                          child: LineChart(LineChartData(
                            gridData: const FlGridData(
                                show: true, drawVerticalLine: false),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: true, interval: 5)),
                              bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                    weightEntries.length,
                                    (i) => FlSpot(
                                        i.toDouble(),
                                        weightEntries.reversed
                                            .toList()[i]
                                            .value)),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                dotData:
                                    FlDotData(show: weightEntries.length < 10),
                              )
                            ],
                          ))),
                    ],
                  ))),
        ]);
  }

  // History tab implementation
  Widget _historyTab(BuildContext context) {
    return FutureBuilder<List<HealthEntry>>(
        future: _api.getHealthEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const [];
          return ListView(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SectionHeader(
                    title: 'History & export',
                    subtitle: 'Filter, view and export your diary history'),
                const SizedBox(height: 12),
                Row(children: [
                  ElevatedButton(
                      onPressed: _exportCsv, child: const Text('Export CSV')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                      onPressed: _exportPdf, child: const Text('Export PDF'))
                ]),
                const SizedBox(height: 12),
                ...entries
                    .map((e) => ExpansionTile(
                          title: Text(
                              '${e.entryDate.toLocal().toIso8601String().split('T').first} · ${e.mood ?? '—'}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Wellbeing: ${e.effectiveWellbeingScore}'),
                                  Text('Energy: ${e.energyLevel ?? '—'}'),
                                  Text('Stress: ${e.stressLevel ?? '—'}'),
                                  Text(
                                      'Sleep: ${e.sleepHours?.toStringAsFixed(1) ?? '—'} h'),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Symptoms: ${e.symptoms.isEmpty ? 'None' : e.symptoms.join(', ')}'),
                                  const SizedBox(height: 8),
                                  Text('Notes: ${extractNote(e.notes)}'),
                                ],
                              ),
                            )
                          ],
                        ))
                    .toList(),
              ]);
        });
  }

  // Helpers
  List<double> _lastReadingsForKey(String key, {int count = 14}) {
    // Map keys to available HealthEntry fields or derived series
    final values = <double>[];
    for (final e in _entries) {
      double? v;
      if (key == 'energy') {
        v = (e.energyLevel ?? 0).toDouble();
      }
      if (key == 'sleep') {
        v = (e.sleepHours ?? 0).toDouble();
      }
      if (key == 'stress') {
        v = (e.stressLevel ?? 0).toDouble();
      }
      if (key == 'wellbeing') {
        v = (e.effectiveWellbeingScore).toDouble();
      }
      if (key == 'steps') {
        // steps are tracked in sport activities; aggregate per day
        // we'll return 0 here for per-entry series and let VitalDetailPage handle steps differently
        v = 0.0;
      }
      if (v != null) {
        values.add(v);
      }
      if (values.length >= count) {
        break;
      }
    }
    return values.reversed.toList().cast<double>();
  }

  dynamic _currentValueForKey(String key) {
    if (_entries.isEmpty) return null;
    final e = _entries.first;
    switch (key) {
      case 'energy':
        return e.energyLevel;
      case 'sleep':
        return e.sleepHours?.toStringAsFixed(1);
      case 'stress':
        return e.stressLevel;
      case 'wellbeing':
        // Return the raw wellbeingScore if present (backend/app stores 0-10),
        // otherwise fall back to the computed effectiveWellbeingScore.
        return e.wellbeingScore ?? e.effectiveWellbeingScore;
      case 'steps':
        return _sumStepsForDay(DateTime.now());
      default:
        return null;
    }
  }

  Color _colorForValue(num? min, num? max, dynamic value) {
    if (value == null) {
      return AppColors.muted;
    }
    if (min == null || max == null) {
      return AppColors.navy;
    }
    try {
      final v = (value is String)
          ? double.tryParse(value) ?? 0.0
          : (value as num).toDouble();
      if (v < min || v > max) {
        return AppColors.danger;
      }
      // borderline if within 10% of bounds
      final range = (max - min).abs();
      if ((v - min) / (range == 0 ? 1 : range) < 0.1 ||
          (max - v) / (range == 0 ? 1 : range) < 0.1) {
        return AppColors.warning;
      }
      return AppColors.success;
    } catch (_) {
      return AppColors.muted;
    }
  }

  String _daysAgoLabelForKey(String key) {
    if (_entries.isEmpty) {
      return '';
    }
    // find last entry with that key
    for (final e in _entries) {
      final has = (key == 'energy' && e.energyLevel != null) ||
          (key == 'sleep' && e.sleepHours != null) ||
          (key == 'stress' && e.stressLevel != null) ||
          (key == 'wellbeing');
      if (has) {
        final days = DateTime.now().difference(e.entryDate).inDays;
        return days == 0 ? 'Today' : '$days days ago';
      }
    }
    return '';
  }

  Widget _miniSparkline(List<double> values, Color color) {
    if (values.isEmpty) {
      return const SizedBox();
    }
    final spots =
        List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    return LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              dotData: const FlDotData(show: false),
              barWidth: 2)
        ]));
  }

  /// Parse activity date from either 'activityDate' (backend DTO) or 'start' (legacy)
  DateTime? _activityDate(Map<String, dynamic> a) {
    final raw = a['activityDate']?.toString() ?? a['start']?.toString() ?? '';
    return DateTime.tryParse(raw);
  }

  int _sumStepsForDay(DateTime day) {
    var sum = 0;
    for (final a in _sportActivities) {
      final t = _activityDate(a);
      if (t != null &&
          t.year == day.year &&
          t.month == day.month &&
          t.day == day.day) {
        sum += (a['steps'] as num?)?.toInt() ?? 0;
      }
    }

    // Also include any steps recorded in diary entries for that day (if not already represented in sport activities)
    for (final e in _entries) {
      if (e.entryDate.year == day.year &&
          e.entryDate.month == day.month &&
          e.entryDate.day == day.day) {
        if (e.notes == null || !e.notes!.startsWith('{')) continue;
        try {
          final d = jsonDecode(e.notes!) as Map<String, dynamic>;
          final act = d['activity'] as Map?;
          final s = int.tryParse(act?['steps']?.toString() ?? '') ?? 0;
          if (s <= 0) {
            continue;
          }
          // check whether a sport activity with same steps already exists for the same day to avoid double-counting
          final existsInSport = _sportActivities.any((a) {
            final t = _activityDate(a);
            return t != null &&
                t.year == day.year &&
                t.month == day.month &&
                t.day == day.day &&
                ((a['steps'] as num?)?.toInt() ?? 0) == s;
          });
          if (!existsInSport) {
            sum += s;
          }
        } catch (_) {
          // ignore parsing errors
        }
      }
    }
    return sum;
  }

  int get _stepsFromEntries {
    return _entries.fold(0, (sum, e) {
      if (e.notes == null || !e.notes!.startsWith('{')) {
        return sum;
      }
      try {
        final d = jsonDecode(e.notes!) as Map<String, dynamic>;
        final act = d['activity'] as Map?;
        return sum + (int.tryParse(act?['steps']?.toString() ?? '') ?? 0);
      } catch (_) {
        return sum;
      }
    });
  }

  int _longestStepStreak(List<HealthEntry> entries) {
    // simple: longest consecutive days with steps>0 in sport activities
    final daysWithSteps = <DateTime>{};
    for (final a in _sportActivities) {
      final t = _activityDate(a);
      if (t != null && ((a['steps'] as num?)?.toInt() ?? 0) > 0) {
        daysWithSteps.add(DateTime(t.year, t.month, t.day));
      }
    }
    if (daysWithSteps.isEmpty) {
      return 0;
    }
    final dates = daysWithSteps.toList()..sort();
    var best = 1, cur = 1;
    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        cur++;
      } else {
        cur = 1;
      }
      if (cur > best) {
        best = cur;
      }
    }
    return best;
  }

  Widget _weeklyBarChart(List<int> thisWeek, List<int> prevWeek) {
    final maxY =
        (thisWeek + prevWeek).fold<int>(0, (a, b) => a > b ? a : b).toDouble() +
            1000;
    final groups = List.generate(
      7,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: thisWeek[i].toDouble(), color: AppColors.teal),
          BarChartRodData(
              toY: prevWeek[i].toDouble(),
              color: AppColors.muted.withValues(alpha: 0.35)),
        ],
      ),
    );

    return BarChart(
      BarChartData(
        barGroups: groups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final now = DateTime.now();
                final dayIndex = value.toInt();
                final date = DateTime(now.year, now.month, now.day)
                    .subtract(Duration(days: 6 - dayIndex));
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(days[date.weekday - 1],
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        maxY: maxY,
      ),
    );
  }

  Widget _sleepBarChart(List<HealthEntry> entries) {
    final spots = List.generate(
        entries.length,
        (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                  toY: entries[i].sleepHours ?? 0,
                  color: (entries[i].sleepHours ?? 0) >= 7
                      ? AppColors.success
                      : ((entries[i].sleepHours ?? 0) >= 5
                          ? AppColors.warning
                          : AppColors.danger))
            ]));
    return BarChart(BarChartData(
        barGroups: spots,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround));
  }

  Widget _bedtimePlot(List<HealthEntry> entries) {
    // Deduplicate entries by calendar date to avoid duplicate dots for same day
    final seen = <String>{};
    final uniqueEntries = entries.where((e) {
      final key =
          '${e.entryDate.year}-${e.entryDate.month.toString().padLeft(2, '0')}-${e.entryDate.day.toString().padLeft(2, '0')}';
      return seen.add(key);
    }).toList();

    // Simple dots showing bedtime if notes contained bedtime (best-effort). We'll fallback to random for demo.
    final spots = <Widget>[];
    for (var i = 0; i < uniqueEntries.length; i++) {
      final label = uniqueEntries[i]
          .entryDate
          .toLocal()
          .toIso8601String()
          .split('T')
          .first;
      final text = extractNote(uniqueEntries[i].notes);
      spots.add(Row(children: [
        Text(label),
        const SizedBox(width: 8),
        const Icon(Icons.circle, size: 8, color: AppColors.navy),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text.length > 60 ? '${text.substring(0, 60)}…' : text))
      ]));
    }
    return ListView(children: spots);
  }

  // Note extraction moved to lib/utils/health_utils.dart -> extractNote()

  // Weight trend chart removed - weight isn't available on HealthEntry in current model.

  Future<void> _exportCsv() async {
    final uri = Uri.parse('${_api.baseUrl}/export/csv');
    try {
      final resp = await http.get(uri);
      if (!mounted) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Export ready — check Downloads or implement share integration.')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Export failed.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error while exporting.')));
    }
  }

  Future<void> _exportPdf() async {
    final uri = Uri.parse('${_api.baseUrl}/export/pdf');
    try {
      final resp = await http.get(uri);
      if (!mounted) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'PDF export ready — check Downloads or implement share integration.')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Export failed.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error while exporting.')));
    }
  }
}

class VitalDetailPage extends StatelessWidget {
  final String keyName;
  final String label;
  final String unit;
  final List<HealthEntry> entries;
  final num? normalMin;
  final num? normalMax;

  const VitalDetailPage(
      {required this.keyName,
      required this.label,
      required this.unit,
      required this.entries,
      this.normalMin,
      this.normalMax,
      super.key});

  @override
  Widget build(BuildContext context) {
    final data = _mapValuesForKey();
    if (data.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: Text(label)),
          body: const Center(child: Text('No data yet')));
    }
    final spots =
        List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    final chartMax =
        (spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b) + 5);
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: chartMax,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    show: true,
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.navy,
                        barWidth: 3,
                        dotData: const FlDotData(show: false)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (normalMin != null && normalMax != null)
              Text('Normal range: $normalMin - $normalMax $unit')
          ],
        ),
      ),
    );
  }

  List<double> _mapValuesForKey() {
    final list = <double>[];
    for (final e in entries) {
      double? v;
      switch (keyName) {
        case 'energy':
          v = (e.energyLevel ?? 0).toDouble();
          break;
        case 'sleep':
          v = (e.sleepHours ?? 0).toDouble();
          break;
        case 'stress':
          v = (e.stressLevel ?? 0).toDouble();
          break;
        case 'wellbeing':
          v = (e.effectiveWellbeingScore).toDouble();
          break;
        case 'steps':
          v = 0.0;
          break;
      }
      if (v != null) list.add(v);
    }
    return list.reversed.toList().cast<double>();
  }
}

class _DevicesTab extends StatefulWidget {
  const _DevicesTab();

  @override
  State<_DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<_DevicesTab> {
  final WearableService _wearableService = WearableService();
  final ApiService _api = ApiService.instance;

  List<WearableDevice> _devices = [];
  List<SyncEvent> _syncHistory = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = _api.activeUserId;
      if (userId != null) {
        final devices = await _wearableService.getConnectedDevices(userId);
        final history = await _wearableService.getSyncHistory(userId);
        if (mounted) {
          setState(() {
            _devices = devices;
            _syncHistory = history;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // Shared key for the last-sync timestamp — must match wearables_screen.dart.
  static const String _kLastSyncKey = 'health_last_sync_ms';

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final userId = _api.activeUserId;
      if (userId != null) {
        final hasPermission = await _wearableService.hasPermissions();
        if (!hasPermission) {
          await _wearableService.requestPermissions();
        }
        // Use the shared last-sync timestamp so incremental syncs only pull new
        // data. Fall back to 30 days on first use so historical HR, sleep and
        // workouts are imported — NOT just the last 24 h.
        final prefs = await SharedPreferences.getInstance();
        final lastMs = prefs.getInt(_kLastSyncKey);
        final startDate = lastMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastMs)
            : DateTime.now().subtract(const Duration(days: 30));
        await _wearableService.syncWearableData(
          userId: userId,
          startDate: startDate,
        );
        await prefs.setInt(
            _kLastSyncKey, DateTime.now().millisecondsSinceEpoch);
        await _load();
        if (mounted) {
          WearableService.showSyncStatus(context, 'Sync complete', true);
        }
      }
    } catch (e) {
      if (mounted) {
        WearableService.showSyncStatus(context, 'Sync failed', false);
      }
    }
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _addDevice() async {
    final nameController = TextEditingController();
    WearableDeviceType selectedType = WearableDeviceType.fitbit;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Device name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WearableDeviceType>(
              initialValue: selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: WearableDeviceType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) selectedType = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      try {
        final userId = _api.activeUserId;
        if (userId != null) {
          await _wearableService.addDevice(
              userId, nameController.text.trim(), selectedType);
          await _load();
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not add device')));
        }
      }
    }
  }

  Future<void> _removeDevice(WearableDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove device'),
        content: Text('Remove ${device.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await _wearableService.disconnectDevice(device.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SectionHeader(
            title: 'Wearable devices',
            subtitle: 'Manage connected devices and sync health data',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: _syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Sync'),
                onPressed: _syncing ? null : _sync,
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                onPressed: _addDevice,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_devices.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.watch_outlined,
                        size: 48, color: AppColors.muted),
                    const SizedBox(height: 12),
                    const Text('No devices connected',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'Add your wearable to start syncing health data',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _addDevice,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add device'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._devices.map(
              (device) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                    child:
                        const Icon(Icons.watch_rounded, color: AppColors.teal),
                  ),
                  title: Text(device.name),
                  subtitle: Text(device.type.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.danger),
                    onPressed: () => _removeDevice(device),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Sync history',
            subtitle: 'Recent data syncs from your devices',
          ),
          const SizedBox(height: 8),
          if (_syncHistory.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'No syncs yet — tap sync to pull data from your device'),
              ),
            )
          else
            ..._syncHistory.take(10).map(
                  (event) => Card(
                    child: ListTile(
                      leading: Icon(
                        event.success
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: event.success
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      title: Text(event.deviceName),
                      subtitle: Text(
                        event.syncTime.toLocal().toString().split('.').first,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
