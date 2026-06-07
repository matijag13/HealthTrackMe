import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/sync_events.dart';
import '../widgets/ai_assistant.dart';
import '../widgets/app_logo.dart';

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
  final _HomeShieldSnapshot homeShield;
  final List<Map<String, dynamic>> sportActivities;

  const _DashboardStateModel({
    this.user,
    this.entries = const [],
    this.medicines = const [],
    this.shield,
    this.homeShield = const _HomeShieldSnapshot.empty(),
    this.sportActivities = const [],
  });
}

class _HomeGoal {
  final bool completed;
  final bool applicable;
  final int xp;
  final int maxXp;

  const _HomeGoal({
    required this.completed,
    required this.applicable,
    required this.xp,
    required this.maxXp,
  });
}

class _HomeMedicineGoal {
  final bool completed;
  final bool applicable;
  final int xp;
  final int maxXp;

  const _HomeMedicineGoal({
    required this.completed,
    required this.applicable,
    required this.xp,
    required this.maxXp,
  });
}

class _HomeShieldSnapshot {
  final int level;
  final String levelName;
  final int progressPercent;
  final int todayXp;
  final int maxTodayXp;
  final int xpToNextLevel;
  final int completedHabits;
  final String status;

  const _HomeShieldSnapshot({
    required this.level,
    required this.levelName,
    required this.progressPercent,
    required this.todayXp,
    required this.maxTodayXp,
    required this.xpToNextLevel,
    required this.completedHabits,
    required this.status,
  });

  const _HomeShieldSnapshot.empty()
      : level = 1,
        levelName = 'Basic Shield',
        progressPercent = 0,
        todayXp = 0,
        maxTodayXp = 0,
        xpToNextLevel = 200,
        completedHabits = 0,
        status = 'Low';
}

class _FavoriteOption {
  final String key;
  final String label;

  const _FavoriteOption({required this.key, required this.label});
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _green = Color(0xFF5FB878);
  static const _orange = Color(0xFFD4956A);
  static const _danger = Color(0xFFFF6B6B);
  static const _prefsFavoriteKeys = 'dashboard_favorite_keys';
  static const List<String> _defaultFavoriteKeys = [
    'activity',
    'sleep',
    'vitals',
    'medicines',
  ];

  static const List<_FavoriteOption> _favoriteOptions = [
    _FavoriteOption(key: 'activity', label: 'Activity'),
    _FavoriteOption(key: 'sleep', label: 'Sleep'),
    _FavoriteOption(key: 'vitals', label: 'Vitals'),
    _FavoriteOption(key: 'medicines', label: 'Medicines'),
    _FavoriteOption(key: 'healthShield', label: 'Health Shield'),
    _FavoriteOption(key: 'insights', label: 'Insights / Trends'),
  ];

  final ApiService _api = ApiService.instance;
  _DashboardStateModel _state = const _DashboardStateModel();
  List<String> _favoriteKeys = List<String>.from(_defaultFavoriteKeys);
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFavoriteKeys());
    _loadAll();
    // Refresh automatically when a background/foreground sync uploads new data.
    SyncEvents.instance.revision.addListener(_onSynced);
  }

  @override
  void dispose() {
    SyncEvents.instance.revision.removeListener(_onSynced);
    super.dispose();
  }

  void _onSynced() {
    if (mounted) _refresh();
  }

  Future<void> _loadFavoriteKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKeys = prefs.getStringList(_prefsFavoriteKeys);
    final validKeys = _normalizeFavoriteKeys(storedKeys);
    final resolvedKeys =
        validKeys.isEmpty ? List<String>.from(_defaultFavoriteKeys) : validKeys;

    if (storedKeys == null || !_sameFavoriteKeys(storedKeys, resolvedKeys)) {
      await prefs.setStringList(_prefsFavoriteKeys, resolvedKeys);
    }

    if (!mounted) return;
    setState(() {
      _favoriteKeys = resolvedKeys;
    });
  }

  List<String> _normalizeFavoriteKeys(List<String>? keys) {
    if (keys == null) return const [];
    final normalized = <String>[];
    for (final key in _favoriteOptions.map((option) => option.key)) {
      if (keys.contains(key)) {
        normalized.add(key);
      }
    }
    return normalized;
  }

  bool _sameFavoriteKeys(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<_FavoriteOption> get _selectedFavoriteOptions {
    final selected = _favoriteKeys.toSet();
    return _favoriteOptions
        .where((option) => selected.contains(option.key))
        .toList(growable: false);
  }

  Future<void> _loadAll() async {
    // Only show the full-screen loading state on the very first load. On
    // refreshes (tab return, post-sync) keep the existing data visible so the
    // dashboard never blanks back to spinners.
    final firstLoad = _state.user == null;
    if (firstLoad) setState(() => _loading = true);
    try {
      await _api.ensureActiveUserId();

      final results = await Future.wait([
        _api.getCurrentUser(),
        _api.getHealthEntries(),
        _api.getMedicines(activeOnly: false),
        _api.getHealthShield(),
        _api.getSportActivities(),
      ]);

      final user = results[0] as User?;
      final entries = results[1] as List<HealthEntry>;
      final medicines = results[2] as List<Medicine>;
      final shield = results[3] as HealthShield?;
      final sportActivities = (results[4] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final activeMedicines = medicines.where((m) => m.isActive).toList();
      final medicineGoal = await _buildHomeMedicineGoal(activeMedicines);
      final homeShield = _buildHomeShieldSnapshot(
        entries: entries,
        activities: sportActivities,
        activeMedicines: activeMedicines,
        medicineGoal: medicineGoal,
        backendShield: shield,
      );

      if (!mounted) return;
      setState(() {
        _state = _DashboardStateModel(
          user: user,
          entries: entries,
          medicines: medicines,
          shield: shield,
          homeShield: homeShield,
          sportActivities: sportActivities,
        );
        _loading = false;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _loadAll();

  Future<_HomeMedicineGoal> _buildHomeMedicineGoal(
    List<Medicine> activeMedicines,
  ) async {
    if (activeMedicines.isEmpty) {
      return const _HomeMedicineGoal(
        completed: false,
        applicable: false,
        xp: 0,
        maxXp: 0,
      );
    }

    final todayKey = _dateKey(DateTime.now());

    // Fetch every medicine's adherence in parallel instead of one-by-one, so the
    // dashboard isn't blocked on N sequential network round-trips.
    final adherences = await Future.wait(
      activeMedicines.map((medicine) async {
        try {
          return await _api.getMedicineAdherence(medicine.id, days: 1);
        } catch (_) {
          return null;
        }
      }),
    );

    var adherenceReliable = false;
    var takenToday = false;
    for (final adherence in adherences) {
      if (adherence == null) continue;
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
    }

    if (!adherenceReliable) {
      return const _HomeMedicineGoal(
        completed: true,
        applicable: true,
        xp: 15,
        maxXp: 15,
      );
    }

    return _HomeMedicineGoal(
      completed: takenToday,
      applicable: true,
      xp: takenToday ? 15 : 0,
      maxXp: 15,
    );
  }

  _HomeShieldSnapshot _buildHomeShieldSnapshot({
    required List<HealthEntry> entries,
    required List<Map<String, dynamic>> activities,
    required List<Medicine> activeMedicines,
    required _HomeMedicineGoal medicineGoal,
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
      final date = _sportActivityDate(activity);
      return date != null &&
          _sameDay(date, today) &&
          _sportActivityDuration(activity) > 0;
    });
    final vitalsCompleted = todaysEntries.any(_hasVitalsData);

    final goals = [
      _HomeGoal(
          completed: sleepCompleted, applicable: true, xp: sleepXp, maxXp: 30),
      _HomeGoal(
        completed: activityCompleted,
        applicable: true,
        xp: activityCompleted ? 30 : 0,
        maxXp: 30,
      ),
      _HomeGoal(
        completed: vitalsCompleted,
        applicable: true,
        xp: vitalsCompleted ? 10 : 0,
        maxXp: 10,
      ),
      _HomeGoal(
        completed: medicineGoal.completed,
        applicable: medicineGoal.applicable,
        xp: medicineGoal.xp,
        maxXp: medicineGoal.maxXp,
      ),
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
    final dailyProgress = maxApplicableXp == 0
        ? 0
        : ((todayXp / maxApplicableXp) * 100).round().clamp(0, 100);
    final computedTotalXp = _computedHomeRecentXp(
      entries: entries,
      activities: activities,
      medicineApplicable: activeMedicines.isNotEmpty,
    );
    final totalXp = [
      backendShield?.totalConsistencyPoints ?? 0,
      computedTotalXp,
    ].reduce((a, b) => a > b ? a : b);

    return _HomeShieldSnapshot(
      level: _levelForShieldXp(totalXp),
      levelName: backendShield?.levelName ?? _levelNameForShieldXp(totalXp),
      progressPercent: _levelProgressPercent(totalXp),
      todayXp: todayXp,
      maxTodayXp: maxApplicableXp,
      xpToNextLevel: _xpToNextLevel(totalXp),
      completedHabits: completedCount,
      status: _shieldStatusFor(dailyProgress),
    );
  }

  Future<void> _openMedicines() async {
    final result = await context.pushNamed('meds');
    if (result == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _openSleep() async {
    await context.pushNamed('healthSleep');
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openVitals() async {
    await context.pushNamed('healthVitals');
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openActivity() async {
    await context.pushNamed('healthActivity');
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openWearables() async {
    await context.pushNamed('wearables');
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openHealthShield() async {
    await context.pushNamed('healthShield');
    if (!mounted) return;
    await _refresh();
  }

  void _showFavoritesWarning(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surfaceAlt,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _border.withValues(alpha: 0.9)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveFavoriteKeys(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsFavoriteKeys, keys);
  }

  Future<void> _openEditFavoritesSheet() async {
    final currentSelection = _favoriteKeys.toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedCount = currentSelection.length;
            final navigator = Navigator.of(sheetContext);

            void toggleFavorite(String key) {
              setSheetState(() {
                if (currentSelection.contains(key)) {
                  currentSelection.remove(key);
                } else {
                  currentSelection.add(key);
                }
              });
            }

            Future<void> saveSelection() async {
              if (currentSelection.isEmpty) {
                _showFavoritesWarning('Select at least one favorite.');
                return;
              }

              final normalizedSelection = _favoriteOptions
                  .where((option) => currentSelection.contains(option.key))
                  .map((option) => option.key)
                  .toList(growable: false);

              await _saveFavoriteKeys(normalizedSelection);
              if (!mounted) return;
              setState(() {
                _favoriteKeys = normalizedSelection;
              });
              navigator.pop();
            }

            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: _border.withValues(alpha: 0.85),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: 20 + MediaQuery.of(context).padding.bottom,
                  ),
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
                      Text(
                        'Edit favorites',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose the shortcuts shown on Home.',
                        style: TextStyle(
                          color: _secondaryText,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.56,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _favoriteOptions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final option = _favoriteOptions[index];
                            final selected =
                                currentSelection.contains(option.key);
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => toggleFavorite(option.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _accent.withValues(alpha: 0.12)
                                      : _surfaceAlt,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? _accent.withValues(alpha: 0.9)
                                        : _border.withValues(alpha: 0.85),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? _accent.withValues(alpha: 0.16)
                                            : Colors.white
                                                .withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _favoriteIconForKey(option.key),
                                        color:
                                            selected ? _accent : _secondaryText,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: TextStyle(
                                          color: selected
                                              ? _primaryText
                                              : _secondaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Checkbox(
                                      value: selected,
                                      onChanged: (_) =>
                                          toggleFavorite(option.key),
                                      activeColor: _accent,
                                      checkColor: _bg,
                                      side: BorderSide(
                                        color: selected
                                            ? _accent
                                            : _secondaryText.withValues(
                                                alpha: 0.5,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryText,
                                side: BorderSide(
                                  color: _border.withValues(alpha: 0.95),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedCount == 0
                                  ? () => _showFavoritesWarning(
                                      'Select at least one favorite.')
                                  : saveSelection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: _bg,
                                disabledBackgroundColor:
                                    _accent.withValues(alpha: 0.35),
                                disabledForegroundColor:
                                    _bg.withValues(alpha: 0.55),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _favoriteIconForKey(String key) {
    switch (key) {
      case 'activity':
        return Icons.directions_walk;
      case 'sleep':
        return Icons.bedtime_outlined;
      case 'vitals':
        return Icons.monitor_heart_outlined;
      case 'medicines':
        return Icons.medication_outlined;
      case 'healthShield':
        return Icons.shield_outlined;
      case 'insights':
        return Icons.insights_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  HealthEntry? _latestValidSleepEntryForToday() {
    final today = DateTime.now();
    final matches = _state.entries.where((entry) {
      return _sameDay(entry.entryDate, today) &&
          _isValidSleepHours(entry.sleepHours);
    }).toList(growable: false);

    if (matches.isEmpty) {
      return null;
    }

    matches.sort((a, b) => _entrySortKey(b).compareTo(_entrySortKey(a)));
    return matches.first;
  }

  double _todaySleepHours() =>
      _latestValidSleepEntryForToday()?.sleepHours ?? 0.0;

  int _todayActiveMinutes() {
    final today = DateTime.now();
    return _state.sportActivities.where((activity) {
      final date = _sportActivityDate(activity);
      return date != null && _sameDay(date, today);
    }).fold<int>(0, (sum, activity) {
      return sum + _sportActivityDuration(activity);
    });
  }

  int _computedHomeRecentXp({
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
      if (dayEntries.any(_hasVitalsData)) total += 10;
      if (activities.any((activity) {
        final date = _sportActivityDate(activity);
        return date != null &&
            _sameDay(date, day) &&
            _sportActivityDuration(activity) > 0;
      })) {
        total += 30;
      }
      if (medicineApplicable && i == 0) total += 15;
    }
    return total;
  }

  DateTime? _sportActivityDate(Map<String, dynamic> activity) {
    final raw = activity['activityDate'] ?? activity['start'];
    return raw == null ? null : DateTime.tryParse(raw.toString());
  }

  int _sportActivityDuration(Map<String, dynamic> activity) {
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

  int _levelForShieldXp(int totalXp) {
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
    final level = _levelForShieldXp(totalXp);
    if (level >= 5) return 100;
    final start = _levelStartXp(level);
    final next = _nextLevelXp(level);
    return (((totalXp - start) / (next - start)) * 100).round().clamp(0, 100);
  }

  int _xpToNextLevel(int totalXp) {
    final level = _levelForShieldXp(totalXp);
    if (level >= 5) return 0;
    return (_nextLevelXp(level) - totalXp).clamp(0, 2000);
  }

  String _levelNameForShieldXp(int totalXp) {
    final level = _levelForShieldXp(totalXp);
    switch (level) {
      case 5:
        return 'Elite Shield';
      case 4:
        return 'Advanced Shield';
      case 3:
        return 'Strong Shield';
      case 2:
        return 'Rising Shield';
      default:
        return 'Basic Shield';
    }
  }

  String _shieldStatusFor(int progress) {
    if (progress <= 25) return 'Low';
    if (progress <= 60) return 'Building';
    if (progress <= 85) return 'Strong';
    return 'Excellent';
  }

  int _activeMedicinesCount() {
    return _state.medicines.where((medicine) => medicine.isActive).length;
  }

  Future<void> _signOut() async {
    await _api.resetActiveUserId();
    if (!mounted) return;
    context.go('/auth');
  }

  String _formatSleep(double value) {
    if (!_isValidSleepHours(value)) {
      return 'No data';
    }
    final totalMinutes = (value * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _formatActivityDuration(int minutes) {
    if (minutes <= 0) return 'No data';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$remaining min';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }

  bool _isValidSleepHours(double? value) {
    return value != null && value > 0 && value <= 16;
  }

  DateTime _entrySortKey(HealthEntry entry) {
    return entry.updatedAt ?? entry.createdAt ?? entry.entryDate;
  }

  bool _hasVitalsData(HealthEntry entry) {
    return entry.heartRate != null ||
        entry.stressLevel != null ||
        (entry.systolicBp != null && entry.diastolicBp != null) ||
        entry.spO2 != null ||
        entry.bodyTemperature != null ||
        entry.weight != null;
  }

  HealthEntry? _latestVitalsEntry() {
    final entries = _state.entries.where(_hasVitalsData).toList();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => _entrySortKey(b).compareTo(_entrySortKey(a)));
    return entries.first;
  }

  /// The headline vital to show on the dashboard card (heart rate preferred).
  String _primaryVital(HealthEntry entry) {
    if (entry.heartRate != null) return '${entry.heartRate} bpm';
    if (entry.systolicBp != null && entry.diastolicBp != null) {
      return '${entry.systolicBp}/${entry.diastolicBp}';
    }
    if (entry.spO2 != null) return '${entry.spO2}% SpO2';
    if (entry.weight != null) return '${entry.weight!.toStringAsFixed(1)} kg';
    if (entry.bodyTemperature != null) {
      return '${entry.bodyTemperature!.toStringAsFixed(1)}°C';
    }
    return 'Logged';
  }

  String _vitalsValue() {
    final entry = _latestVitalsEntry();
    return entry == null ? 'No data' : _primaryVital(entry);
  }

  String _favoriteVitalsValue() {
    final entry = _latestVitalsEntry();
    return entry == null ? 'No data' : _primaryVital(entry);
  }

  String _favoriteVitalsSubtitle() {
    return _vitalsSubtitle(_latestVitalsEntry());
  }

  String _vitalsSummarySubtitle() {
    return _vitalsSubtitle(_latestVitalsEntry());
  }

  String _vitalsSubtitle(HealthEntry? entry) {
    if (entry == null) return 'Tap to update';
    final details = <String>[];
    if (entry.systolicBp != null && entry.diastolicBp != null) {
      details.add('${entry.systolicBp}/${entry.diastolicBp} BP');
    }
    if (entry.weight != null) {
      details.add('${entry.weight!.toStringAsFixed(1)} kg');
    }
    if (entry.spO2 != null) details.add('${entry.spO2}% SpO2');
    return details.isEmpty ? 'Tap to update' : details.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: const AiAssistantFab(),
      body: RefreshIndicator(
        color: _accent,
        backgroundColor: _surface,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _buildHeader(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFavoritesSection(),
                  const SizedBox(height: 24),
                  _buildFeed(),
                  const SizedBox(height: 22),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppLogo(size: 34),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'HealthTrackMe',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildAvatar(),
      ],
    );
  }

  Widget _buildAvatar() {
    final user = _state.user;
    ImageProvider? image;
    final photo = user?.profilePhotoBase64;
    if (photo != null && photo.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photo));
      } catch (_) {
        image = null;
      }
    }

    final avatar = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _border, width: 1),
      ),
      child: CircleAvatar(
        backgroundColor: _surfaceAlt,
        backgroundImage: image,
        child: image == null
            ? Text(
                user?.initials ?? 'U',
                style: const TextStyle(
                  color: _primaryText,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );

    return PopupMenuButton<String>(
      tooltip: 'Account',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 52),
      color: _surfaceAlt,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _border.withValues(alpha: 0.9)),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            context.pushNamed('profile');
            break;
          case 'signOut':
            await _signOut();
            break;
        }
      },
      itemBuilder: (context) => [
        _avatarMenuItem(
          value: 'profile',
          icon: Icons.person_outline,
          label: 'Profile',
        ),
        const PopupMenuDivider(height: 8),
        _avatarMenuItem(
          value: 'signOut',
          icon: Icons.logout,
          label: 'Sign out',
          danger: true,
        ),
      ],
      child: avatar,
    );
  }

  PopupMenuItem<String> _avatarMenuItem({
    required String value,
    required IconData icon,
    required String label,
    bool danger = false,
  }) {
    final color = danger ? _danger : _primaryText;
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection() {
    if (_loading) return _loadingCard(height: 260);

    final activeMeds = _activeMedicinesCount();
    final firstMedicine = _state.medicines.where((m) => m.isActive).isNotEmpty
        ? _state.medicines.firstWhere((m) => m.isActive)
        : null;

    final cards = _selectedFavoriteOptions
        .map((option) {
          switch (option.key) {
            case 'activity':
              final activeMinutes = _todayActiveMinutes();
              return _favoriteCard(
                title: option.label,
                value: activeMinutes > 0
                    ? _formatActivityDuration(activeMinutes)
                    : 'No data',
                subtitle: activeMinutes > 0
                    ? 'Activity logged today'
                    : 'No activity data for today',
                icon: Icons.directions_walk,
                accent: _green,
                onTap: _openActivity,
              );
            case 'sleep':
              final sleepEntry = _latestValidSleepEntryForToday();
              return _favoriteCard(
                title: option.label,
                value: sleepEntry != null
                    ? _formatSleep(sleepEntry.sleepHours ?? 0)
                    : 'No data',
                subtitle:
                    sleepEntry != null ? 'Updated today' : 'Tap to update',
                icon: Icons.bedtime_outlined,
                accent: _accent,
                onTap: _openSleep,
              );
            case 'vitals':
              return _favoriteCard(
                title: option.label,
                value: _favoriteVitalsValue(),
                subtitle: _favoriteVitalsSubtitle(),
                icon: Icons.monitor_heart_outlined,
                accent: _danger,
                onTap: _openVitals,
              );
            case 'medicines':
              return _favoriteCard(
                title: option.label,
                value: activeMeds > 0 ? activeMeds.toString() : 'No data',
                subtitle: firstMedicine?.name ?? 'Tap to update',
                icon: Icons.medication_outlined,
                accent: _orange,
                onTap: _openMedicines,
              );
            case 'healthShield':
              final homeShield = _state.homeShield;
              return _favoriteCard(
                title: option.label,
                value:
                    'Level ${homeShield.level} • ${homeShield.progressPercent}%',
                subtitle: homeShield.xpToNextLevel == 0
                    ? '${homeShield.levelName} • max level'
                    : '${homeShield.xpToNextLevel} XP to next • ${homeShield.todayXp}/${homeShield.maxTodayXp} today',
                icon: Icons.shield_outlined,
                accent: _accent,
                onTap: _openHealthShield,
              );
            case 'insights':
              return _favoriteCard(
                title: option.label,
                value: _state.entries.isNotEmpty ? 'History ready' : 'No data',
                subtitle: _state.entries.isNotEmpty
                    ? 'Review your recent health patterns'
                    : 'Add module data to unlock trends',
                icon: Icons.insights_outlined,
                accent: _accent,
                onTap: () => context.pushNamed('healthHistory'),
              );
            default:
              return null;
          }
        })
        .whereType<Widget>()
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Favorites',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _primaryText,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
            ),
            _FavoritesEditButton(onTap: _openEditFavoritesSheet),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.28,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        ),
      ],
    );
  }

  Widget _buildFeed() {
    if (_loading) return _loadingCard(height: 420);

    final activeMeds = _activeMedicinesCount();
    final homeShield = _state.homeShield;
    final activeMinutes = _todayActiveMinutes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _healthShieldFeedCard(homeShield),
        _feedGap(),
        _feedCard(
          title: 'Activity',
          value: activeMinutes > 0
              ? _formatActivityDuration(activeMinutes)
              : 'No data',
          subtitle: activeMinutes > 0
              ? 'Activity logged today'
              : 'No activity data for today',
          icon: Icons.directions_run_outlined,
          accent: _green,
          onTap: _openActivity,
        ),
        _feedGap(),
        _feedCard(
          title: 'Sleep',
          value: _formatSleep(_todaySleepHours()),
          subtitle: _todaySleepHours() > 0
              ? 'Sleep logged today'
              : 'No sleep data for today',
          icon: Icons.nightlight_outlined,
          accent: _accent,
          onTap: _openSleep,
        ),
        _feedGap(),
        _feedCard(
          title: 'Vitals',
          value: _vitalsValue(),
          subtitle: _vitalsSummarySubtitle(),
          icon: Icons.monitor_heart_outlined,
          accent: _danger,
          onTap: _openVitals,
        ),
        _feedGap(),
        _feedCard(
          title: 'Medicines',
          value: activeMeds > 0 ? '$activeMeds active' : 'No data',
          subtitle: activeMeds > 0
              ? 'Review schedule and doses'
              : 'No active medicines scheduled',
          icon: Icons.medication_liquid_outlined,
          accent: _orange,
          onTap: _openMedicines,
        ),
        _feedGap(),
        _feedCard(
          title: 'Insights / Trends',
          value: _state.entries.isNotEmpty ? 'History ready' : 'No data',
          subtitle: _state.entries.isNotEmpty
              ? 'Review your recent health patterns'
              : 'Add module data to unlock trends',
          icon: Icons.insights_outlined,
          accent: _accent,
          onTap: () => context.pushNamed('healthHistory'),
        ),
        _feedGap(),
        _feedCard(
          title: 'Wearable Devices',
          value: 'Sync & manage',
          subtitle: 'Connect your device and sync health data',
          icon: Icons.watch_outlined,
          accent: _green,
          onTap: _openWearables,
        ),
      ],
    );
  }

  Widget _healthShieldFeedCard(_HomeShieldSnapshot shield) {
    return _premiumCard(
      onTap: _openHealthShield,
      child: Row(
        children: [
          _iconTile(Icons.shield_outlined, _accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('Health Shield'),
                const SizedBox(height: 6),
                Text(
                  'Level ${shield.level} • ${shield.progressPercent}%',
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shield.xpToNextLevel == 0
                      ? '${shield.status} • max level • ${shield.todayXp} pts today'
                      : '${shield.status} • ${shield.xpToNextLevel} XP to next • ${shield.todayXp} pts today',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, height: 1.3),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: (shield.progressPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: _secondaryText),
        ],
      ),
    );
  }

  Widget _favoriteCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return _premiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: _secondaryText.withValues(alpha: 0.65),
                size: 20,
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _secondaryText.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return _premiumCard(
      onTap: onTap,
      child: Row(
        children: [
          _iconTile(icon, accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(title),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: _secondaryText),
        ],
      ),
    );
  }

  SizedBox _feedGap() => const SizedBox(height: 12);

  Widget _premiumCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: _border.withValues(alpha: 0.75), width: 1),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _loadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withValues(alpha: 0.75), width: 1),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _accent.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;

  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _DashboardScreenState._secondaryText,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FavoritesEditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FavoritesEditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _DashboardScreenState._surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _DashboardScreenState._border.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                color: _DashboardScreenState._accent,
                size: 17,
              ),
              SizedBox(width: 7),
              Text(
                'Edit',
                style: TextStyle(
                  color: _DashboardScreenState._primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
