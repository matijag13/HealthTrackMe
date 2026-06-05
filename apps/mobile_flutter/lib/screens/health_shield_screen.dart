import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class HealthShieldScreen extends StatefulWidget {
  const HealthShieldScreen({super.key});

  @override
  State<HealthShieldScreen> createState() => _HealthShieldScreenState();
}

class _HealthShieldScreenState extends State<HealthShieldScreen> {
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _green = Color(0xFF5FB878);
  static const _orange = Color(0xFFD4956A);
  static const _pink = Color(0xFFEE6C9D);
  static const _bonus = Color(0xFFA78BFA);

  final ApiService _api = ApiService.instance;
  bool _loading = true;
  _ShieldSnapshot _snapshot = _ShieldSnapshot.empty();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    List<HealthEntry> entries = const [];
    List<Map<String, dynamic>> activities = const [];
    List<Medicine> medicines = const [];
    HealthShield? backendShield;

    try {
      await _api.ensureActiveUserId();
    } catch (_) {}

    final results = await Future.wait<Object?>([
      _safe<List<HealthEntry>>(() => _api.getHealthEntries(), const []),
      _safe<List<Map<String, dynamic>>>(
        () => _api.getSportActivities(),
        const [],
      ),
      _safe<List<Medicine>>(
        () => _api.getMedicines(activeOnly: false),
        const [],
      ),
      _safe<HealthShield?>(() => _api.getHealthShield(), null),
    ]);

    entries = results[0] as List<HealthEntry>;
    activities = results[1] as List<Map<String, dynamic>>;
    medicines = results[2] as List<Medicine>;
    backendShield = results[3] as HealthShield?;

    final activeMedicines = medicines.where((m) => m.isActive).toList();
    final medicineGoal = await _buildMedicineGoal(activeMedicines);
    final snapshot = _buildSnapshot(
      entries: entries,
      activities: activities,
      activeMedicines: activeMedicines,
      medicineGoal: medicineGoal,
      backendShield: backendShield,
    );

    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<T> _safe<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (_) {
      return fallback;
    }
  }

  Future<_GoalScore> _buildMedicineGoal(List<Medicine> activeMedicines) async {
    if (activeMedicines.isEmpty) {
      return const _GoalScore(
        type: _GoalType.medicine,
        completed: false,
        applicable: false,
        fallbackActive: false,
        xp: 0,
        maxXp: 0,
        description: 'No active medicines scheduled',
      );
    }

    var adherenceReliable = false;
    var takenToday = false;
    final todayKey = _dateKey(DateTime.now());

    for (final medicine in activeMedicines) {
      try {
        final adherence = await _api.getMedicineAdherence(medicine.id, days: 1);
        adherenceReliable = true;
        final breakdown = adherence['dailyBreakdown'];
        if (breakdown is List) {
          takenToday = takenToday ||
              breakdown.any((point) {
                if (point is! Map) return false;
                final status = point['status']?.toString().toUpperCase();
                return point['date']?.toString() == todayKey &&
                    (status == 'TAKEN' || status == 'TRACKED');
              });
        } else {
          final rate = num.tryParse(
            (adherence['adherenceRate'] ?? adherence['percentage'] ?? '')
                .toString(),
          );
          takenToday = takenToday || (rate != null && rate > 0);
        }
      } catch (_) {}
    }

    if (!adherenceReliable) {
      return const _GoalScore(
        type: _GoalType.medicine,
        completed: true,
        applicable: true,
        fallbackActive: true,
        xp: 15,
        maxXp: 15,
        description: 'Tracking active',
      );
    }

    return _GoalScore(
      type: _GoalType.medicine,
      completed: takenToday,
      applicable: true,
      fallbackActive: false,
      xp: takenToday ? 15 : 0,
      maxXp: 15,
      description:
          takenToday ? 'Medicine tracked today' : 'Keep your streak alive',
    );
  }

  _ShieldSnapshot _buildSnapshot({
    required List<HealthEntry> entries,
    required List<Map<String, dynamic>> activities,
    required List<Medicine> activeMedicines,
    required _GoalScore medicineGoal,
    required HealthShield? backendShield,
  }) {
    final today = DateTime.now();
    final todaysEntries =
        entries.where((entry) => _sameDay(entry.entryDate, today)).toList();

    final sleepHours = todaysEntries
        .map((entry) => entry.sleepHours ?? 0)
        .fold<double>(0, (best, value) => value > best ? value : best);
    final sleepCompleted = sleepHours > 0;
    final sleepXp =
        sleepCompleted ? 20 + (sleepHours >= 6 && sleepHours <= 9 ? 10 : 0) : 0;

    final activityCompleted = activities.any((activity) {
      final date = _activityDate(activity);
      return date != null &&
          _sameDay(date, today) &&
          _activityDuration(activity) > 0;
    });

    final vitalsCompleted = todaysEntries.any(_hasAnyVital);

    final goals = <_GoalScore>[
      _GoalScore(
        type: _GoalType.sleep,
        completed: sleepCompleted,
        applicable: true,
        fallbackActive: false,
        xp: sleepXp,
        maxXp: 30,
        description: sleepCompleted
            ? (sleepHours >= 6 && sleepHours <= 9
                ? 'Sleep logged with bonus XP'
                : 'Sleep logged')
            : 'Log sleep to build your shield',
      ),
      _GoalScore(
        type: _GoalType.activity,
        completed: activityCompleted,
        applicable: true,
        fallbackActive: false,
        xp: activityCompleted ? 30 : 0,
        maxXp: 30,
        description: activityCompleted
            ? 'Activity completed'
            : 'Complete today\'s shield',
      ),
      _GoalScore(
        type: _GoalType.vitals,
        completed: vitalsCompleted,
        applicable: true,
        fallbackActive: false,
        xp: vitalsCompleted ? 10 : 0,
        maxXp: 10,
        description:
            vitalsCompleted ? 'Vitals logged' : 'Log one vital reading',
      ),
      medicineGoal,
    ];

    final applicableGoals = goals.where((goal) => goal.applicable).toList();
    final completedCount =
        applicableGoals.where((goal) => goal.completed).length;
    final baseXp = goals.fold<int>(0, (sum, goal) => sum + goal.xp);
    final maxBaseXp = goals.fold<int>(0, (sum, goal) => sum + goal.maxXp);
    final threeCategoryBonus = completedCount >= 3 ? 25 : 0;
    final allApplicableBonus =
        applicableGoals.isNotEmpty && completedCount == applicableGoals.length
            ? 25
            : 0;
    final todayXp = baseXp + threeCategoryBonus + allApplicableBonus;
    final maxApplicableXp = maxBaseXp + 50;
    final strength = maxApplicableXp == 0
        ? 0
        : ((todayXp / maxApplicableXp) * 100).round().clamp(0, 100);
    final dailySummaries = _dailySummaries(
      entries: entries,
      activities: activities,
      days: 30,
    );
    final weeklyProgress = _weeklyProgress(
      summaries: dailySummaries.take(7).toList(),
      medicineGoal: medicineGoal,
    );
    final streakInfo = _streakInfo(dailySummaries);
    final recentEvents = _recentXpEvents(
      goals: goals,
      completedCount: completedCount,
      allApplicableCompleted: applicableGoals.isNotEmpty &&
          completedCount == applicableGoals.length,
    );

    // MVP note: total XP can come from the backend or from recent local data.
    // Use the higher value so stale backend totals do not hide earned XP.
    final computedTotalXp = _computedRecentXp(
      entries: entries,
      activities: activities,
      medicineApplicable: activeMedicines.isNotEmpty,
    );
    final totalXp = [
      backendShield?.totalConsistencyPoints ?? 0,
      computedTotalXp,
    ].reduce((a, b) => a > b ? a : b);

    return _ShieldSnapshot(
      goals: goals,
      todayXp: todayXp,
      maxApplicableXp: maxApplicableXp,
      shieldStrength: strength,
      status: _statusFor(strength),
      level: _levelFor(totalXp),
      levelProgressPercent: _levelProgressPercent(totalXp),
      xpToNextLevel: _xpToNextLevel(totalXp),
      totalXp: totalXp,
      streak: streakInfo.currentStreak,
      weeklyProgress: weeklyProgress,
      streakInfo: streakInfo,
      recentEvents: recentEvents,
      hasAnyData: entries.isNotEmpty || activities.isNotEmpty,
    );
  }

  int _computedRecentXp({
    required List<HealthEntry> entries,
    required List<Map<String, dynamic>> activities,
    required bool medicineApplicable,
  }) {
    final today = DateTime.now();
    var total = 0;
    for (var i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      final dayEntries =
          entries.where((entry) => _sameDay(entry.entryDate, day)).toList();
      final sleep = dayEntries
          .map((entry) => entry.sleepHours ?? 0)
          .fold<double>(0, (best, value) => value > best ? value : best);
      if (sleep > 0) total += 20;
      if (sleep >= 6 && sleep <= 9) total += 10;
      if (dayEntries.any(_hasAnyVital)) total += 10;
      if (activities.any((activity) {
        final date = _activityDate(activity);
        return date != null &&
            _sameDay(date, day) &&
            _activityDuration(activity) > 0;
      })) {
        total += 30;
      }
      if (medicineApplicable && i == 0) total += 15;
    }
    return total;
  }

  List<_DailyShieldSummary> _dailySummaries({
    required List<HealthEntry> entries,
    required List<Map<String, dynamic>> activities,
    required int days,
  }) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: i));
      final dayEntries =
          entries.where((entry) => _sameDay(entry.entryDate, day)).toList();
      final sleepHours = dayEntries
          .map((entry) => entry.sleepHours ?? 0)
          .fold<double>(0, (best, value) => value > best ? value : best);
      final sleepCompleted = sleepHours > 0;
      final activityCompleted = activities.any((activity) {
        final date = _activityDate(activity);
        return date != null &&
            _sameDay(date, day) &&
            _activityDuration(activity) > 0;
      });
      final vitalsCompleted = dayEntries.any(_hasAnyVital);
      final categoryCount = [
        sleepCompleted,
        activityCompleted,
        vitalsCompleted,
      ].where((completed) => completed).length;
      final xp = (sleepCompleted ? 20 : 0) +
          (sleepHours >= 6 && sleepHours <= 9 ? 10 : 0) +
          (activityCompleted ? 30 : 0) +
          (vitalsCompleted ? 10 : 0) +
          (categoryCount >= 3 ? 25 : 0);
      return _DailyShieldSummary(
        sleepCompleted: sleepCompleted,
        activityCompleted: activityCompleted,
        vitalsCompleted: vitalsCompleted,
        xp: xp,
      );
    });
  }

  _WeeklyProgress _weeklyProgress({
    required List<_DailyShieldSummary> summaries,
    required _GoalScore medicineGoal,
  }) {
    final sleepDays = summaries.where((day) => day.sleepCompleted).length;
    final activityDays = summaries.where((day) => day.activityCompleted).length;
    final vitalsDays = summaries.where((day) => day.vitalsCompleted).length;
    final scores = <String, int>{
      'Sleep': sleepDays,
      'Activity': activityDays,
      'Vitals': vitalsDays,
    };

    var xpThisWeek = summaries.fold<int>(0, (sum, day) => sum + day.xp);
    if (medicineGoal.applicable && !medicineGoal.fallbackActive) {
      xpThisWeek += medicineGoal.xp;
      scores['Medicine'] = medicineGoal.completed ? 1 : 0;
    }

    final activeShieldDays =
        summaries.where((day) => day.categoryCount >= 2).length;
    final completedDailyShields =
        summaries.where((day) => day.categoryCount >= 3).length;
    final sortedScores = scores.entries.toList()
      ..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        return byValue == 0 ? a.key.compareTo(b.key) : byValue;
      });
    final weakestScores = scores.entries.toList()
      ..sort((a, b) {
        final byValue = a.value.compareTo(b.value);
        return byValue == 0 ? a.key.compareTo(b.key) : byValue;
      });

    return _WeeklyProgress(
      xpThisWeek: xpThisWeek,
      activeShieldDays: activeShieldDays,
      completedDailyShields: completedDailyShields,
      bestCategory: sortedScores.first.key,
      weakestCategory: weakestScores.first.key,
    );
  }

  _StreakInfo _streakInfo(List<_DailyShieldSummary> summaries) {
    var current = 0;
    var startsToday =
        summaries.isNotEmpty && summaries.first.categoryCount >= 2;
    final streakSource = startsToday ? summaries : summaries.skip(1);
    for (final day in streakSource) {
      if (day.categoryCount >= 2) {
        current++;
      } else {
        break;
      }
    }

    var best = 0;
    var rolling = 0;
    for (final day in summaries) {
      if (day.categoryCount >= 2) {
        rolling++;
        if (rolling > best) best = rolling;
      } else {
        rolling = 0;
      }
    }

    final message = startsToday
        ? 'Keep your streak alive'
        : 'Complete today\'s shield to keep your streak alive';
    return _StreakInfo(
      currentStreak: current,
      bestRecentStreak: best,
      message: message,
    );
  }

  List<_XpEvent> _recentXpEvents({
    required List<_GoalScore> goals,
    required int completedCount,
    required bool allApplicableCompleted,
  }) {
    final events = <_XpEvent>[];
    for (final goal in goals) {
      if (!goal.completed || !goal.applicable) continue;
      switch (goal.type) {
        case _GoalType.sleep:
          events.add(const _XpEvent('Sleep logged', 20, _accent));
          if (goal.xp > 20) {
            events.add(const _XpEvent('Sleep bonus', 10, _accent));
          }
          break;
        case _GoalType.activity:
          events.add(const _XpEvent('Activity completed', 30, _green));
          break;
        case _GoalType.vitals:
          events.add(const _XpEvent('Vitals logged', 10, _pink));
          break;
        case _GoalType.medicine:
          events.add(const _XpEvent('Medicine tracked', 15, _orange));
          break;
      }
    }
    if (completedCount >= 3) {
      events.add(const _XpEvent('Daily shield bonus', 25, _bonus));
    }
    if (allApplicableCompleted) {
      events.add(const _XpEvent('Complete shield bonus', 25, _bonus));
    }
    return events;
  }

  bool _hasAnyVital(HealthEntry entry) {
    return entry.heartRate != null ||
        entry.stressLevel != null ||
        entry.systolicBp != null ||
        entry.diastolicBp != null ||
        entry.spO2 != null ||
        entry.bodyTemperature != null ||
        entry.weight != null;
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

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dateKey(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  String _statusFor(int strength) {
    if (strength <= 25) return 'Low';
    if (strength <= 60) return 'Building';
    if (strength <= 85) return 'Strong';
    return 'Excellent';
  }

  int _levelFor(int totalXp) {
    if (totalXp >= 2000) return 5;
    if (totalXp >= 1000) return 4;
    if (totalXp >= 500) return 3;
    if (totalXp >= 200) return 2;
    return 1;
  }

  int _levelStartXp(int level) {
    switch (level) {
      case 5:
        return 2000;
      case 4:
        return 1000;
      case 3:
        return 500;
      case 2:
        return 200;
      default:
        return 0;
    }
  }

  int _nextLevelXp(int level) {
    switch (level) {
      case 1:
        return 200;
      case 2:
        return 500;
      case 3:
        return 1000;
      case 4:
        return 2000;
      default:
        return 2000;
    }
  }

  int _levelProgressPercent(int totalXp) {
    final level = _levelFor(totalXp);
    if (level >= 5) return 100;
    final start = _levelStartXp(level);
    final next = _nextLevelXp(level);
    return (((totalXp - start) / (next - start)) * 100).round().clamp(0, 100);
  }

  int _xpToNextLevel(int totalXp) {
    final level = _levelFor(totalXp);
    if (level >= 5) return 0;
    return (_nextLevelXp(level) - totalXp).clamp(0, 2000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? _buildLoading()
            : RefreshIndicator(
                color: _accent,
                backgroundColor: _surface,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 18),
                    _buildHeroCard(),
                    const SizedBox(height: 22),
                    _buildGoalsHeader(),
                    const SizedBox(height: 12),
                    ..._snapshot.goals.map(_buildGoalCard),
                    const SizedBox(height: 10),
                    _buildWeeklyProgressSection(),
                    const SizedBox(height: 22),
                    _buildRecentXpSection(),
                    if (!_snapshot.hasAnyData) ...[
                      const SizedBox(height: 14),
                      _buildEmptyState(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _buildTopBar(),
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('home');
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: _primaryText,
          style: IconButton.styleFrom(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _border),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Health Shield',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    final progress = (_snapshot.levelProgressPercent / 100).clamp(0.0, 1.0);
    final nextLevelLabel = _snapshot.xpToNextLevel == 0
        ? 'Max level'
        : '${_snapshot.xpToNextLevel} XP left';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconTile(Icons.shield_outlined, _accent, size: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Level progress',
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_snapshot.totalXp} total XP',
                      style:
                          const TextStyle(color: _secondaryText, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_snapshot.levelProgressPercent}%',
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: _statusPill(nextLevelLabel),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _heroStat('Level ${_snapshot.level}', 'Level'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroStat(
                  nextLevelLabel,
                  'Next level',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroStat(
                  '${_snapshot.todayXp}/${_snapshot.maxApplicableXp} XP',
                  'Today',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Shield',
          style: TextStyle(
            color: _primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Complete today\'s shield to earn XP.',
          style: TextStyle(color: _secondaryText),
        ),
      ],
    );
  }

  Widget _buildGoalCard(_GoalScore goal) {
    final meta = _goalMeta(goal.type);
    final statusText = goal.applicable
        ? goal.fallbackActive
            ? 'Tracking active'
            : goal.completed
                ? 'Completed'
                : 'Not completed'
        : 'Not applicable';
    final statusColor = goal.applicable
        ? goal.completed
            ? _green
            : _secondaryText
        : _orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            _iconTile(meta.icon, meta.color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        goal.applicable ? '+${goal.maxXp} XP' : '0 XP',
                        style: TextStyle(
                          color: goal.applicable ? meta.color : _secondaryText,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    goal.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _secondaryText, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        goal.applicable
                            ? goal.completed
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded
                            : Icons.remove_circle_outline_rounded,
                        size: 17,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressSection() {
    final weekly = _snapshot.weeklyProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Weekly progress'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withValues(alpha: 0.8)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _metricTile(
                      '${weekly.xpThisWeek} XP',
                      'XP this week',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricTile(
                      '${weekly.activeShieldDays}',
                      'active shield days',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _metricTile(
                      '${weekly.completedDailyShields}',
                      'completed daily shields',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricTile(
                      weekly.bestCategory,
                      'best category',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _metricTile(
                      weekly.weakestCategory,
                      'weakest category',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricTile(
                      '${_snapshot.streakInfo.bestRecentStreak}',
                      'best recent streak',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border.withValues(alpha: 0.65)),
                ),
                child: Text(
                  _snapshot.streakInfo.message,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentXpSection() {
    final recentTotal =
        _snapshot.recentEvents.fold<int>(0, (sum, event) => sum + event.xp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Recent XP')),
            if (_snapshot.recentEvents.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _bonus.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _bonus.withValues(alpha: 0.28)),
                ),
                child: Text(
                  '+$recentTotal XP',
                  style: const TextStyle(
                    color: _bonus,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: _snapshot.recentEvents.isEmpty
              ? Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border.withValues(alpha: 0.65)),
                  ),
                  child: const Text(
                    'Log today\'s habits to earn XP.',
                    style: TextStyle(
                      color: _secondaryText,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: List.generate(_snapshot.recentEvents.length, (i) {
                    final event = _snapshot.recentEvents[i];
                    final isLast = i == _snapshot.recentEvents.length - 1;
                    final color = event.color;
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? color.withValues(alpha: 0.08)
                                : _surfaceAlt.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: i == 0
                                  ? color.withValues(alpha: 0.24)
                                  : _border.withValues(alpha: 0.52),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _primaryText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Added to today\'s shield',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _secondaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Text(
                                  '+${event.xp} XP',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) const SizedBox(height: 10),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }

  Widget _metricTile(String value, String label) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border.withValues(alpha: 0.75)),
      ),
      child: const Text(
        'Start logging sleep, activity and vitals to build your shield.',
        style: TextStyle(color: _secondaryText, height: 1.35),
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: _primaryText,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon, Color color, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }

  _GoalMeta _goalMeta(_GoalType type) {
    switch (type) {
      case _GoalType.sleep:
        return const _GoalMeta(
          title: 'Sleep',
          icon: Icons.bedtime_outlined,
          color: _accent,
        );
      case _GoalType.activity:
        return const _GoalMeta(
          title: 'Activity',
          icon: Icons.directions_run_outlined,
          color: _green,
        );
      case _GoalType.vitals:
        return const _GoalMeta(
          title: 'Vitals',
          icon: Icons.monitor_heart_outlined,
          color: _pink,
        );
      case _GoalType.medicine:
        return const _GoalMeta(
          title: 'Medicine',
          icon: Icons.medication_outlined,
          color: _orange,
        );
    }
  }
}

enum _GoalType { sleep, activity, vitals, medicine }

class _GoalMeta {
  final String title;
  final IconData icon;
  final Color color;

  const _GoalMeta({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class _GoalScore {
  final _GoalType type;
  final bool completed;
  final bool applicable;
  final bool fallbackActive;
  final int xp;
  final int maxXp;
  final String description;

  const _GoalScore({
    required this.type,
    required this.completed,
    required this.applicable,
    required this.fallbackActive,
    required this.xp,
    required this.maxXp,
    required this.description,
  });
}

class _DailyShieldSummary {
  final bool sleepCompleted;
  final bool activityCompleted;
  final bool vitalsCompleted;
  final int xp;

  const _DailyShieldSummary({
    required this.sleepCompleted,
    required this.activityCompleted,
    required this.vitalsCompleted,
    required this.xp,
  });

  int get categoryCount => [
        sleepCompleted,
        activityCompleted,
        vitalsCompleted,
      ].where((completed) => completed).length;
}

class _WeeklyProgress {
  final int xpThisWeek;
  final int activeShieldDays;
  final int completedDailyShields;
  final String bestCategory;
  final String weakestCategory;

  const _WeeklyProgress({
    required this.xpThisWeek,
    required this.activeShieldDays,
    required this.completedDailyShields,
    required this.bestCategory,
    required this.weakestCategory,
  });

  factory _WeeklyProgress.empty() {
    return const _WeeklyProgress(
      xpThisWeek: 0,
      activeShieldDays: 0,
      completedDailyShields: 0,
      bestCategory: 'Sleep',
      weakestCategory: 'Sleep',
    );
  }
}

class _StreakInfo {
  final int currentStreak;
  final int bestRecentStreak;
  final String message;

  const _StreakInfo({
    required this.currentStreak,
    required this.bestRecentStreak,
    required this.message,
  });

  factory _StreakInfo.empty() {
    return const _StreakInfo(
      currentStreak: 0,
      bestRecentStreak: 0,
      message: 'Complete today\'s shield to keep your streak alive',
    );
  }
}

class _XpEvent {
  final String title;
  final int xp;
  final Color color;

  const _XpEvent(this.title, this.xp, this.color);
}

class _ShieldSnapshot {
  final List<_GoalScore> goals;
  final int todayXp;
  final int maxApplicableXp;
  final int shieldStrength;
  final String status;
  final int level;
  final int levelProgressPercent;
  final int xpToNextLevel;
  final int totalXp;
  final int streak;
  final _WeeklyProgress weeklyProgress;
  final _StreakInfo streakInfo;
  final List<_XpEvent> recentEvents;
  final bool hasAnyData;

  const _ShieldSnapshot({
    required this.goals,
    required this.todayXp,
    required this.maxApplicableXp,
    required this.shieldStrength,
    required this.status,
    required this.level,
    required this.levelProgressPercent,
    required this.xpToNextLevel,
    required this.totalXp,
    required this.streak,
    required this.weeklyProgress,
    required this.streakInfo,
    required this.recentEvents,
    required this.hasAnyData,
  });

  factory _ShieldSnapshot.empty() {
    return _ShieldSnapshot(
      goals: [],
      todayXp: 0,
      maxApplicableXp: 0,
      shieldStrength: 0,
      status: 'Low',
      level: 1,
      levelProgressPercent: 0,
      xpToNextLevel: 200,
      totalXp: 0,
      streak: 0,
      weeklyProgress: _WeeklyProgress.empty(),
      streakInfo: _StreakInfo.empty(),
      recentEvents: [],
      hasAnyData: false,
    );
  }
}
