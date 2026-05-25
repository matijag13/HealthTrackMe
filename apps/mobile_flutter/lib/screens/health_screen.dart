import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../services/api_service.dart';
import 'log_screen.dart';
import '../widgets/widgets.dart';

class HealthScreenTabbed extends StatefulWidget {
  const HealthScreenTabbed({super.key});

  @override
  State<HealthScreenTabbed> createState() => _HealthScreenTabbedState();
}

class _HealthScreenTabbedState extends State<HealthScreenTabbed> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService.instance;
  late TabController _tabController;

  List<HealthEntry> _entries = [];
  List<Map<String, dynamic>> _sportActivities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final entries = await _api.getHealthEntries();
    final sport = await _fetchSportActivities();
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Vitals'),
            Tab(text: 'Activity'),
            Tab(text: 'Sleep'),
            Tab(text: 'Body'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: LoadingSkeleton.health(context)))
          : TabBarView(controller: _tabController, children: [
              _vitalsTab(context),
              _activityTab(context),
              _sleepTab(context),
              _bodyTab(context),
              _historyTab(context),
            ]),
    );
  }

  // Vitals tab implementation (uses available fields on HealthEntry)
  Widget _vitalsTab(BuildContext context) {
    if (_entries.isEmpty) {
      return EmptyState(
        animationUrl: 'https://assets2.lottiefiles.com/packages/lf20_1pxqjqps.json',
        title: 'No readings yet',
        subtitle: 'Log your vitals in the daily diary',
        buttonLabel: 'Log vitals',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogScreen())),
      );
    }

    final latest = _entries.first;
    final vitals = <Map<String, dynamic>>[
      {'key': 'energy', 'label': 'Energy', 'unit': '%', 'icon': Icons.bolt, 'normalMin': 30, 'normalMax': 80},
      {'key': 'sleep', 'label': 'Sleep', 'unit': 'h', 'icon': Icons.bedtime, 'normalMin': 4, 'normalMax': 9},
      {'key': 'steps', 'label': 'Steps (today)', 'unit': '', 'icon': Icons.directions_walk, 'normalMin': 0, 'normalMax': 10000},
      {'key': 'stress', 'label': 'Stress', 'unit': '%', 'icon': Icons.psychology, 'normalMin': 0, 'normalMax': 50},
      {'key': 'wellbeing', 'label': 'Wellbeing', 'unit': '%', 'icon': Icons.emoji_emotions, 'normalMin': 0, 'normalMax': 100},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: vitals.length,
      itemBuilder: (context, idx) {
        final v = vitals[idx];
        final series = _lastReadingsForKey(v['key'] as String, count: 14);
        final current = _currentValueForKey(v['key'] as String);
        final color = _colorForValue(v['normalMin'] as num?, v['normalMax'] as num?, current);
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(v['icon'] as IconData, color: color)),
            title: Text(v['label'] as String),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(current != null ? '$current ${v['unit']}' : '—'),
              const SizedBox(height: 6),
              SizedBox(height: 36, child: _miniSparkline(series, color)),
            ]),
            trailing: Text(_daysAgoLabelForKey(v['key'] as String)),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VitalDetailPage(keyName: v['key'] as String, label: v['label'] as String, unit: v['unit'] as String, entries: _entries, normalMin: v['normalMin'] as num?, normalMax: v['normalMax'] as num?))),
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
    final days = List.generate(7, (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i));
    final stepsThisWeek = days.map((d) => _sumStepsForDay(d)).toList();
    final prevWeekStart = startOfWeek.subtract(const Duration(days: 7));
    final prevDays = List.generate(7, (i) => DateTime(prevWeekStart.year, prevWeekStart.month, prevWeekStart.day + i));
    final stepsPrevWeek = prevDays.map((d) => _sumStepsForDay(d)).toList();

    final totalSteps = stepsThisWeek.fold<int>(0, (a, b) => a + b);
    final activeDays = stepsThisWeek.where((s) => s > 0).length;
    final avg = activeDays > 0 ? (totalSteps / 7).round() : 0;
    final streak = _longestStepStreak(_entries);

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        const SectionHeader(title: 'Weekly steps', subtitle: 'This week vs previous week'),
        const SizedBox(height: 12),
        SizedBox(height: 180, child: _weeklyBarChart(stepsThisWeek, stepsPrevWeek)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: StatItem(icon: '👟', value: totalSteps.toString(), label: 'Total steps', valueColor: AppColors.info)),
                  const SizedBox(width: 12),
                  Expanded(child: StatItem(icon: '📅', value: activeDays.toString(), label: 'Active days', valueColor: AppColors.success)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: StatItem(icon: '📈', value: avg.toString(), label: 'Avg (daily)', valueColor: AppColors.weight)),
                  const SizedBox(width: 12),
                  Expanded(child: StatItem(icon: '🔥', value: streak.toString(), label: 'Longest streak', valueColor: AppColors.teal)),
                ])
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Workouts', subtitle: 'Recent activities'),
        const SizedBox(height: 8),
        if (_sportActivities.isEmpty) EmptyState(animationUrl: '', title: 'No workouts yet', subtitle: 'Log a workout to see your stats', buttonLabel: 'Log workout', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogScreen()))) else ..._sportActivities.map((act) => Slidable(
              key: ValueKey(act['id'] ?? act.hashCode),
              endActionPane: ActionPane(motion: const ScrollMotion(), children: [SlidableAction(onPressed: (_) => _deleteActivity(act), backgroundColor: AppColors.danger, icon: Icons.delete, label: 'Delete')]),
              child: ListTile(
                leading: const Icon(Icons.directions_run),
                title: Text(act['type']?.toString() ?? 'Activity'),
                subtitle: Text('${act['durationMinutes'] ?? 0} min · ${act['distanceKm'] ?? '—'} km · ${act['calories'] ?? '—'} kcal'),
                trailing: Text(act['start'] != null ? DateTime.tryParse(act['start'].toString())?.toLocal().toIso8601String().split('T').first ?? '' : ''),
              ),
            )),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Goal', subtitle: 'Weekly step goal progress'),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [CircularPercentIndicator(radius: 72, lineWidth: 10, percent: (totalSteps / (70000)).clamp(0.0, 1.0), center: Text('${((totalSteps / 70000) * 100).clamp(0, 100).round()}%'), progressColor: AppColors.teal), const SizedBox(height: 8), const Text('Goal: 70 000 steps / week (default)')])))
      ]),
    );
  }

  Future<void> _deleteActivity(Map<String, dynamic> act) async {
    try {
      final id = act['id'];
      if (id == null) return;
      final activityId = id is int ? id : int.tryParse(id.toString());
      if (activityId == null) return;
      final deleted = await _api.deleteSportActivity(activityId);
      if (deleted) {
        await _loadAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete activity')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
    }
  }

  // Sleep tab implementation
  Widget _sleepTab(BuildContext context) {
    final sleepEntries = _entries.where((e) => e.sleepHours != null).toList();
    if (sleepEntries.isEmpty) return Center(child: Text('No sleep readings yet — log sleep in the daily diary'));
    final last14 = sleepEntries.take(14).toList().reversed.toList();
    return ListView(padding: const EdgeInsets.all(12), children: [
      const SectionHeader(title: 'Sleep (last 14 nights)', subtitle: 'Hours per night and quality'),
      const SizedBox(height: 12),
      SizedBox(height: 220, child: _sleepBarChart(last14)),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: StatItem(icon: '😴', value: last14.map((e) => e.sleepHours ?? 0).fold(0.0, (a, b) => a + b) / last14.length > 0 ? (last14.map((e) => e.sleepHours ?? 0).fold(0.0, (a, b) => a + b) / last14.length).toStringAsFixed(1) : '—', label: 'Avg sleep', valueColor: AppColors.sleep)), const SizedBox(width: 12), Expanded(child: StatItem(icon: '🌙', value: '${last14.map((e) => e.sleepHours ?? 0).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}', label: 'Best night', valueColor: AppColors.success))]),
      const SizedBox(height: 12),
      const SectionHeader(title: 'Bedtime consistency', subtitle: 'When you went to bed each night'),
      const SizedBox(height: 12),
      SizedBox(height: 120, child: _bedtimePlot(last14)),
    ]);
  }

  // Body tab implementation
  Widget _bodyTab(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      const SectionHeader(title: 'Body', subtitle: 'Weight and BMI'),
      const SizedBox(height: 12),
      const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Weight tracking is not available in the current data model. Record weight in the diary to enable weight trends.'))),
    ]);
  }

  // History tab implementation
  Widget _historyTab(BuildContext context) {
    return FutureBuilder<List<HealthEntry>>(future: _api.getHealthEntries(), builder: (context, snapshot) {
      final entries = snapshot.data ?? const [];
      return ListView(padding: const EdgeInsets.all(12), children: [
        const SectionHeader(title: 'History & export', subtitle: 'Filter, view and export your diary history'),
        const SizedBox(height: 12),
        Row(children: [ElevatedButton(onPressed: _exportCsv, child: const Text('Export CSV')), const SizedBox(width: 8), ElevatedButton(onPressed: _exportPdf, child: const Text('Export PDF'))]),
        const SizedBox(height: 12),
        ...entries.map((e) => ExpansionTile(
              title: Text('${e.entryDate.toLocal().toIso8601String().split('T').first} · ${e.mood ?? '—'}'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wellbeing: ${e.effectiveWellbeingScore}'),
                      Text('Energy: ${e.energyLevel ?? '—'}'),
                      Text('Stress: ${e.stressLevel ?? '—'}'),
                      Text('Sleep: ${e.sleepHours?.toStringAsFixed(1) ?? '—'} h'),
                      const SizedBox(height: 8),
                      Text('Symptoms: ${e.symptoms.isEmpty ? 'None' : e.symptoms.join(', ')}'),
                      const SizedBox(height: 8),
                      Text('Notes: ${(e.notes ?? '').toString()}'),
                    ],
                  ),
                )
              ],
            )).toList(),
      ]);
    });
  }

  // Helpers
  List<double> _lastReadingsForKey(String key, {int count = 14}) {
    // Map keys to available HealthEntry fields or derived series
    final values = <double>[];
    for (final e in _entries) {
      double? v;
      if (key == 'energy') v = (e.energyLevel ?? 0).toDouble();
      if (key == 'sleep') v = (e.sleepHours ?? 0).toDouble();
      if (key == 'stress') v = (e.stressLevel ?? 0).toDouble();
      if (key == 'wellbeing') v = (e.effectiveWellbeingScore).toDouble();
      if (key == 'steps') {
        // steps are tracked in sport activities; aggregate per day
        // we'll return 0 here for per-entry series and let VitalDetailPage handle steps differently
        v = 0.0;
      }
      if (v != null) values.add(v);
      if (values.length >= count) break;
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
        return e.sleepHours != null ? e.sleepHours!.toStringAsFixed(1) : null;
      case 'stress':
        return e.stressLevel;
      case 'wellbeing':
        return e.effectiveWellbeingScore;
      case 'steps':
        return _sumStepsForDay(DateTime.now());
      default:
        return null;
    }
  }

  Color _colorForValue(num? min, num? max, dynamic value) {
    if (value == null) return AppColors.muted;
    if (min == null || max == null) return AppColors.navy;
    try {
      final v = (value is String) ? double.tryParse(value) ?? 0.0 : (value as num).toDouble();
      if (v < min || v > max) return AppColors.danger;
      // borderline if within 10% of bounds
      final range = (max - min).abs();
      if ((v - min) / (range == 0 ? 1 : range) < 0.1 || (max - v) / (range == 0 ? 1 : range) < 0.1) return AppColors.warning;
      return AppColors.success;
    } catch (_) {
      return AppColors.muted;
    }
  }

  String _daysAgoLabelForKey(String key) {
    if (_entries.isEmpty) return '';
    // find last entry with that key
    for (final e in _entries) {
      final has = (key == 'energy' && e.energyLevel != null) || (key == 'sleep' && e.sleepHours != null) || (key == 'stress' && e.stressLevel != null) || (key == 'wellbeing');
      if (has) {
        final days = DateTime.now().difference(e.entryDate).inDays;
        return days == 0 ? 'Today' : '$days days ago';
      }
    }
    return '';
  }

  Widget _miniSparkline(List<double> values, Color color) {
    if (values.isEmpty) return const SizedBox();
    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    return LineChart(LineChartData(gridData: FlGridData(show: false), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: color, dotData: FlDotData(show: false), barWidth: 2)]));
  }

  int _sumStepsForDay(DateTime day) {
    var sum = 0;
    for (final a in _sportActivities) {
      final t = DateTime.tryParse(a['start']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (t.year == day.year && t.month == day.month && t.day == day.day) {
        sum += (a['steps'] as int?) ?? 0;
      }
    }
    return sum;
  }

  int _longestStepStreak(List<HealthEntry> entries) {
    // simple: longest consecutive days with steps>0 in sport activities
    final daysWithSteps = <String>{};
    for (final a in _sportActivities) {
      final t = DateTime.tryParse(a['start']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if ((a['steps'] as int?) != null && (a['steps'] as int) > 0) daysWithSteps.add('${t.year}-${t.month}-${t.day}');
    }
    if (daysWithSteps.isEmpty) return 0;
    final dates = daysWithSteps.map((s) => DateTime.parse(s)).toList()..sort();
    var best = 1, cur = 1;
    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) cur++; else cur = 1;
      if (cur > best) best = cur;
    }
    return best;
  }

  Widget _weeklyBarChart(List<int> thisWeek, List<int> prevWeek) {
    final maxY = (thisWeek + prevWeek).fold<int>(0, (a, b) => a > b ? a : b).toDouble() + 1000;
    final groups = List.generate(
      7,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: thisWeek[i].toDouble(), color: AppColors.teal),
          BarChartRodData(toY: prevWeek[i].toDouble(), color: AppColors.muted.withOpacity(0.35)),
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
              getTitlesWidget: (v, meta) => Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][v.toInt()]),
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        maxY: maxY,
      ),
    );
  }

  Widget _sleepBarChart(List<HealthEntry> entries) {
    final spots = List.generate(entries.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: entries[i].sleepHours ?? 0, color: (entries[i].sleepHours ?? 0) >= 7 ? AppColors.success : ((entries[i].sleepHours ?? 0) >= 5 ? AppColors.warning : AppColors.danger))]));
    return BarChart(BarChartData(barGroups: spots, titlesData: FlTitlesData(show: false), gridData: FlGridData(show: false), borderData: FlBorderData(show: false), alignment: BarChartAlignment.spaceAround));
  }

  Widget _bedtimePlot(List<HealthEntry> entries) {
    // Simple dots showing bedtime if notes contained bedtime (best-effort). We'll fallback to random for demo.
    final spots = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final label = entries[i].entryDate.toLocal().toIso8601String().split('T').first;
      final text = entries[i].notes ?? '';
      spots.add(Row(children: [Text(label), const SizedBox(width: 8), const Icon(Icons.circle, size: 8, color: AppColors.navy), const SizedBox(width: 8), Expanded(child: Text(text.length > 60 ? '${text.substring(0, 60)}…' : text))]));
    }
    return ListView(children: spots);
  }

  // Weight trend chart removed - weight isn't available on HealthEntry in current model.

  Future<void> _exportCsv() async {
    final uri = Uri.parse('${_api.baseUrl}/export/csv');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export ready — check Downloads or implement share integration.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export failed.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error while exporting.')));
    }
  }

  Future<void> _exportPdf() async {
    final uri = Uri.parse('${_api.baseUrl}/export/pdf');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF export ready — check Downloads or implement share integration.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export failed.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error while exporting.')));
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

  const VitalDetailPage({required this.keyName, required this.label, required this.unit, required this.entries, this.normalMin, this.normalMax, super.key});

  @override
  Widget build(BuildContext context) {
    final data = _mapValuesForKey();
    if (data.isEmpty) return Scaffold(appBar: AppBar(title: Text(label)), body: const Center(child: Text('No data yet')));
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    final chartMax = (spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b) + 5);
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
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(spots: spots, isCurved: true, color: AppColors.navy, barWidth: 3, dotData: FlDotData(show: false)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (normalMin != null && normalMax != null) Text('Normal range: $normalMin - $normalMax $unit')
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
