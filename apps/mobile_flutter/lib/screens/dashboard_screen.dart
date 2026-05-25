import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import 'onboarding_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardStateModel {
  final User? user;
  final List<HealthEntry> entries;
  final List<Medicine> medicines;
  final HealthShield? shield;
  final List<Map<String, dynamic>> sportActivities; // simple map for steps/calories

  const _DashboardStateModel({
    this.user,
    this.entries = const [],
    this.medicines = const [],
    this.shield,
    this.sportActivities = const [],
  });
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService.instance;
  _DashboardStateModel _state = const _DashboardStateModel();
  bool _loading = true;
  bool _error = false;

  // Overlay toggles for weekly chart
  bool _overlaySleep = true;
  bool _overlayStress = false;
  bool _overlayEnergy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final user = await _api.getCurrentUser();
      final entries = await _api.getHealthEntries();
      final medicines = await _api.getMedicines(activeOnly: false);
      final shield = await _api.getHealthShield();

      // Try to fetch sport activities directly (some ApiService versions may not provide it)
      final sportActivities = await _fetchSportActivities();

      setState(() {
        _state = _DashboardStateModel(
          user: user,
          entries: entries,
          medicines: medicines,
          shield: shield,
          sportActivities: sportActivities,
        );
        _loading = false;
      });
      // Show onboarding once if not completed
      try {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool('onboarding_complete') ?? false;
        if (!seen && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const OnboardingScreen()));
            } catch (_) {}
          });
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSportActivities() async {
    return _api.getSportActivities();
  }

  Future<void> _markDoseTaken(int medicineId) async {
    try {
      await _api.logMedicineDose(medicineId, DateTime.now(), 'TAKEN');
      if (!mounted) return;
      await _loadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
    }
  }

  Future<void> _refresh() async => _loadAll();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  int _todayHealthIndex() {
    if (_state.entries.isEmpty) return 0;
    final today = DateTime.now();
    final todays = _state.entries.where((e) => e.entryDate.year == today.year && e.entryDate.month == today.month && e.entryDate.day == today.day);
    if (todays.isEmpty) return _state.entries.first.effectiveWellbeingScore;
    return todays.first.effectiveWellbeingScore;
  }

  double _todaySleepHours() {
    final today = DateTime.now();
    final todays = _state.entries.where((e) => e.entryDate.year == today.year && e.entryDate.month == today.month && e.entryDate.day == today.day);
    if (todays.isEmpty) return 0.0;
    return todays.first.effectiveSleepHours;
  }

  // Helper empty entry for lookups when no entry exists for a day
  HealthEntry _emptyEntry() {
    return HealthEntry(id: 0, entryDate: DateTime.now(), symptoms: const [], wellbeingScore: 0, mood: null, energyLevel: 0, sleepHours: 0.0, sleepQuality: null, stressLevel: 0, notes: null, createdAt: null, updatedAt: null);
  }

  int _todaySteps() {
    if (_state.sportActivities.isEmpty) return 0;
    // find today's activities and sum steps (if present)
    final today = DateTime.now();
    final todays = _state.sportActivities.where((a) {
      final t = DateTime.tryParse(a['start']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return t.year == today.year && t.month == today.month && t.day == today.day;
    });
    var sum = 0;
    for (final a in todays) {
      sum += (a['steps'] as int?) ?? (a['distanceMeters'] != null ? ((a['distanceMeters'] as num) / 0.8).round() : 0);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final name = _state.user?.firstName?.isNotEmpty == true ? _state.user!.firstName : (_state.user?.fullName ?? 'there');
    final greeting = '${_greeting()}, $name';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              snap: false,
              floating: false,
              expandedHeight: 140,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(left: 18, right: 18, top: 36, bottom: 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF0B3A7B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(greeting, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('Your daily health at a glance', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.blue,
                              child: Text((_state.user?.initials ?? 'U'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Body content
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // SECTION 1 - Health Score Ring
                  _buildHeroRing(context),
                  const SizedBox(height: 12),

                  // SECTION 2 - Quick Stats horizontal
                  _buildQuickStats(context),
                  const SizedBox(height: 12),

                  // SECTION 3 - Health Shield
                  HealthShieldSection(shield: _state.shield, onRefresh: _refresh),
                  const SizedBox(height: 12),

                  // SECTION 4 - Upcoming Medicines
                  _buildMedicinesSection(context),
                  const SizedBox(height: 12),

                  // SECTION 5 - Recent Diary Entries
                  _buildDiarySection(context),
                  const SizedBox(height: 12),

                  // SECTION 6 - Weekly Trend Chart
                  _buildWeeklyTrend(context),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({double height = 120}) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
      );

  Widget _buildHeroRing(BuildContext context) {
    if (_loading) return _shimmerBox(height: 220);

    final index = _todayHealthIndex();
    final sleep = _todaySleepHours();
    final steps = _todaySteps();
    // Heart rate not currently stored on HealthEntry model; show placeholder
    final bpm = 0;
    final sleepPct = (sleep / 8).clamp(0.0, 1.0);
    final activityPct = (steps / 10000).clamp(0.0, 1.0);
    final nutritionPct = 0.7;
    final vitalsPct = (bpm > 0 ? (80 - (bpm - 60)).abs() / 80 : 0.6).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: CircularPercentIndicator(
              radius: 95,
              lineWidth: 11,
              percent: (index.clamp(0, 100)) / 100,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: Colors.grey.shade200,
              progressColor: AppColors.teal,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$index', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  const Text('Health Index', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricRingChip(label: 'Sleep', percent: sleepPct, color: AppColors.navy),
              _metricRingChip(label: 'Activity', percent: activityPct, color: AppColors.teal),
              _metricRingChip(label: 'Nutrition', percent: nutritionPct, color: AppColors.blue),
              _metricRingChip(label: 'Vitals', percent: vitalsPct, color: AppColors.danger),
            ],
          ),

          const SizedBox(height: 12),
          // Pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill('😴 ${sleep > 0 ? '${sleep.toStringAsFixed(1)}h' : '—'} sleep', AppColors.navy.withValues(alpha: 0.08), AppColors.navy),
              _pill('👟 ${steps > 0 ? steps.toString() : '—'} steps', AppColors.teal.withValues(alpha: 0.08), AppColors.teal),
              _pill('💓 ${bpm > 0 ? '$bpm bpm' : '—'}', AppColors.danger.withValues(alpha: 0.08), AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricRingChip({required String label, required double percent, required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: CircularPercentIndicator(
            radius: 26,
            lineWidth: 5,
            percent: percent.clamp(0.0, 1.0),
            center: Text('${(percent * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            progressColor: color,
            backgroundColor: Colors.grey.shade200,
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }

  Widget _pill(String text, Color bg, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      );

  Widget _buildQuickStats(BuildContext context) {
    if (_loading) return SizedBox(height: 120, child: ListView.separated(scrollDirection: Axis.horizontal, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(right: 8), child: _shimmerBox(height: 100)), separatorBuilder: (_, __) => const SizedBox(), itemCount: 6));

    final cards = [
      {'icon': '👟', 'name': 'Steps', 'value': _todaySteps() > 0 ? _todaySteps().toString() : '—', 'unit': ''},
      {'icon': '💓', 'name': 'Heart', 'value': '—', 'unit': 'bpm'},
      {'icon': '⚖️', 'name': 'Weight', 'value': '—', 'unit': 'kg'},
      {'icon': '😴', 'name': 'Sleep', 'value': _todaySleepHours() > 0 ? '${_todaySleepHours().toStringAsFixed(1)}' : '—', 'unit': 'h'},
      {'icon': '💧', 'name': 'Water', 'value': '—', 'unit': 'L'},
      {'icon': '🔥', 'name': 'Calories', 'value': _state.sportActivities.isNotEmpty ? '${_state.sportActivities.map((e) => (e['calories'] ?? 0)).fold(0, (a, b) => a + (b as int))}' : '—', 'unit': 'kcal'},
      {'icon': '🧠', 'name': 'Stress', 'value': _state.entries.isNotEmpty ? '${_state.entries.first.stressLevel?.round() ?? '—'}' : '—', 'unit': ''},
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = cards[index];
          return GestureDetector(
            onTap: () {
              // navigate to detail if route exists else show snackbar
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open ${c['name']} detail')));
            },
            child: Container(
              width: 160,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(c['icon'] as String), Text(c['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(c['value'].toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      const SizedBox(width: 6),
                      Text(c['unit'].toString(), style: const TextStyle(color: AppColors.muted)),
                      const Spacer(),
                      SizedBox(width: 60, height: 34, child: _buildSparkline(_last7ValuesForMetric(c['name'] as String))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<double> _last7ValuesForMetric(String name) {
    // Try to extract 7-day series from entries/sport activities
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    if (name == 'Steps') {
      // map sport activities
      return days.map((d) {
        final sum = _state.sportActivities.where((a) {
          final t = DateTime.tryParse(a['start']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return t.year == d.year && t.month == d.month && t.day == d.day;
        }).fold<int>(0, (p, e) => p + ((e['steps'] as int?) ?? 0));
        return sum.toDouble();
      }).toList();
    }

    // For other metrics, use entries' effective values
    return days.map((d) {
      final entry = _state.entries.firstWhere((e) => e.entryDate.year == d.year && e.entryDate.month == d.month && e.entryDate.day == d.day, orElse: () => _emptyEntry());
      switch (name) {
        case 'Heart':
          return (entry.energyLevel ?? 0).toDouble();
        case 'Sleep':
          return (entry.effectiveSleepHours).toDouble();
        case 'Stress':
          return (entry.stressLevel ?? 0).toDouble();
        default:
          return 0.0;
      }
    }).toList().cast<double>();
  }

  Widget _buildSparkline(List<double> values) {
    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    return LineChart(
      LineChartData(gridData: FlGridData(show: false), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false), lineBarsData: [
        LineChartBarData(spots: spots, isCurved: true, color: AppColors.teal, dotData: FlDotData(show: false), barWidth: 2),
      ]),
    );
  }

  Widget _buildMedicinesSection(BuildContext context) {
    if (_loading) return _shimmerBox(height: 140);

    final meds = _state.medicines.where((m) => m.isActive).toList();
    final morning = meds.where((m) => m.scheduleLabel.toLowerCase().contains('morning')).toList();
    final afternoon = meds.where((m) => m.scheduleLabel.toLowerCase().contains('afternoon')).toList();
    final evening = meds.where((m) => m.scheduleLabel.toLowerCase().contains('evening') || m.scheduleLabel.toLowerCase().contains('night')).toList();

    Widget group(String title, List<Medicine> list) {
      if (list.isEmpty) return const SizedBox();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...list.map((m) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.blue, shape: BoxShape.circle)),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(m.scheduleLabel),
                trailing: IconButton(
                  icon: Icon(m.isActive ? Icons.check_circle : Icons.radio_button_unchecked, color: m.isActive ? AppColors.success : AppColors.muted),
                  onPressed: () => _markDoseTaken(m.id),
                ),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open full Meds for ${m.name}'))),
              ))
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming medicines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (meds.isEmpty)
              const Text('No medicines scheduled for today. Tap to add.')
            else
              Column(children: [group('Morning', morning), group('Afternoon', afternoon), group('Evening', evening)]),
          ],
        ),
      ),
    );
  }

  Widget _buildDiarySection(BuildContext context) {
    if (_loading) return _shimmerBox(height: 120);

    final last3 = _state.entries.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent diary entries', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (last3.isEmpty)
          const Text('No diary entries yet. Tap to create one.')
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: last3.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final e = last3[i];
                return GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open diary ${e.entryDate}'))),
                  child: Container(
                    width: 260,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Text(e.mood ?? '🙂', style: const TextStyle(fontSize: 22)), const SizedBox(width: 8), Text('${e.entryDate.toLocal().toIso8601String().split('T').first}', style: const TextStyle(fontWeight: FontWeight.w600))]),
                        const SizedBox(height: 8),
                        Text('Wellbeing ${e.effectiveWellbeingScore}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text((e.symptoms.isNotEmpty ? e.symptoms.take(2).join(', ') : 'No symptoms'), style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyTrend(BuildContext context) {
    if (_loading) return _shimmerBox(height: 200);

    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final wellbeing = days.map((d) {
      final entry = _state.entries.firstWhere((e) => e.entryDate.year == d.year && e.entryDate.month == d.month && e.entryDate.day == d.day, orElse: () => _emptyEntry());
      return entry.effectiveWellbeingScore.toDouble();
    }).toList();

    final sleep = days.map((d) {
      final entry = _state.entries.firstWhere((e) => e.entryDate.year == d.year && e.entryDate.month == d.month && e.entryDate.day == d.day, orElse: () => _emptyEntry());
      return (entry.effectiveSleepHours / 12 * 100).clamp(0.0, 100.0);
    }).toList();

    final stress = days.map((d) {
      final entry = _state.entries.firstWhere((e) => e.entryDate.year == d.year && e.entryDate.month == d.month && e.entryDate.day == d.day, orElse: () => _emptyEntry());
      return (entry.stressLevel ?? 0).toDouble();
    }).toList().cast<double>();

    List<LineChartBarData> lines = [];
    lines.add(LineChartBarData(spots: List.generate(wellbeing.length, (i) => FlSpot(i.toDouble(), wellbeing[i])), isCurved: true, color: AppColors.teal, barWidth: 3, dotData: FlDotData(show: false)));
    if (_overlaySleep) lines.add(LineChartBarData(spots: List.generate(sleep.length, (i) => FlSpot(i.toDouble(), sleep[i])), isCurved: true, color: AppColors.navy.withOpacity(0.9), barWidth: 2, dashArray: [4, 2], dotData: FlDotData(show: false)));
    if (_overlayStress) lines.add(LineChartBarData(spots: List.generate(stress.length, (i) => FlSpot(i.toDouble(), stress[i])), isCurved: true, color: AppColors.danger.withOpacity(0.9), barWidth: 2, dotData: FlDotData(show: false)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Weekly wellbeing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), Row(children: [
              TextButton(onPressed: () => setState(() { _overlaySleep = !_overlaySleep; }), child: Text('Sleep', style: TextStyle(color: _overlaySleep ? AppColors.navy : AppColors.muted))),
              TextButton(onPressed: () => setState(() { _overlayStress = !_overlayStress; }), child: Text('Stress', style: TextStyle(color: _overlayStress ? AppColors.danger : AppColors.muted))),
            ])]),
            const SizedBox(height: 6),
            SizedBox(
              height: 220,
              child: LineChart(LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25),
                titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                  final d = days[idx];
                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday % 7]));
                })), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 25))),
                borderData: FlBorderData(show: false),
                lineBarsData: lines,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
