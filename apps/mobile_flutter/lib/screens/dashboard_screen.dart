import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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
  final List<Map<String, dynamic>> sportActivities;

  const _DashboardStateModel({
    this.user,
    this.entries = const [],
    this.medicines = const [],
    this.shield,
    this.sportActivities = const [],
  });
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
    setState(() => _loading = true);
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

      try {
        final today = DateTime.now();
        final todays = entries
            .where((e) =>
                e.entryDate.year == today.year &&
                e.entryDate.month == today.month &&
                e.entryDate.day == today.day)
            .toList();
        if (todays.isNotEmpty) {
          final e = todays.first;
          if (e.notes != null && e.notes!.startsWith('{')) {
            final parsed = Map<String, dynamic>.from(jsonDecode(e.notes!));
            final activity = parsed['activity'];
            if (activity is Map && activity['steps'] != null) {
              final steps = int.tryParse(activity['steps'].toString()) ?? 0;
              if (steps > 0) {
                sportActivities.add(
                    {'start': e.entryDate.toIso8601String(), 'steps': steps});
              }
            }
          }
        }
      } catch (_) {
        // Ignore malformed legacy notes payloads.
      }

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
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _loadAll();

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

  int _todaySteps() => _sumStepsForDay(DateTime.now());

  int _sumStepsForDay(DateTime day) {
    var sum = 0;
    for (final activity in _state.sportActivities) {
      final time = DateTime.tryParse(activity['start']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (!_sameDay(time, day)) continue;
      sum += (activity['steps'] as int?) ??
          (activity['distanceMeters'] != null
              ? ((activity['distanceMeters'] as num) / 0.8).round()
              : 0);
    }
    return sum;
  }

  int _todayActiveMinutes() {
    final today = DateTime.now();
    return _state.sportActivities.where((activity) {
      final time = DateTime.tryParse(activity['start']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return _sameDay(time, today);
    }).fold<int>(0, (sum, activity) {
      return sum +
          (int.tryParse(activity['durationMinutes']?.toString() ?? '') ?? 0);
    });
  }

  int _todayCaloriesBurned() {
    final today = DateTime.now();
    return _state.sportActivities.where((activity) {
      final time = DateTime.tryParse(activity['start']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return _sameDay(time, today);
    }).fold<int>(0, (sum, activity) {
      return sum +
          (int.tryParse(activity['caloriesBurned']?.toString() ?? '') ??
              int.tryParse(activity['calories']?.toString() ?? '') ??
              0);
    });
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _activeMedicinesCount() {
    return _state.medicines.where((medicine) => medicine.isActive).length;
  }

  Future<void> _signOut() async {
    await _api.resetActiveUserId();
    if (!mounted) return;
    context.go('/auth');
  }

  String _formatInt(int value) {
    if (value <= 0) return 'No data';
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
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
    for (final entry in _state.entries) {
      if (_hasVitalsData(entry)) {
        return entry;
      }
    }
    return null;
  }

  String _vitalsValue() {
    final entry = _latestVitalsEntry();
    if (entry == null) return 'No data';
    if (_sameDay(entry.entryDate, DateTime.now())) {
      return 'Updated today';
    }
    return 'Last updated ${_shortDate(entry.entryDate)}';
  }

  String _favoriteVitalsValue() {
    final entry = _latestVitalsEntry();
    if (entry == null) return 'No data';
    if (_sameDay(entry.entryDate, DateTime.now())) {
      return 'Updated today';
    }
    final date = _shortDate(entry.entryDate);
    final text = 'Updated $date';
    return text.length <= 14 ? text : date;
  }

  String _favoriteVitalsSubtitle() {
    return _latestVitalsEntry() == null ? _vitalsSubtitle(null) : 'View trends';
  }

  String _vitalsSummarySubtitle() {
    return _latestVitalsEntry() == null
        ? _vitalsSubtitle(null)
        : 'Tap to view trends';
  }

  String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
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
            context.pushNamed('profileEdit');
            break;
          case 'settings':
            context.pushNamed('profileSettings');
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
        _avatarMenuItem(
          value: 'settings',
          icon: Icons.settings_outlined,
          label: 'Settings',
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
              return _favoriteCard(
                title: option.label,
                value: _formatInt(_todaySteps()),
                subtitle: _todayActiveMinutes() > 0
                    ? '${_todayActiveMinutes()} active min'
                    : 'Tap to update',
                icon: Icons.directions_walk,
                accent: _green,
                onTap: () => context.pushNamed('healthActivity'),
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
              return _favoriteCard(
                title: option.label,
                value: _state.shield?.level.toString() ?? 'No data',
                subtitle: _state.shield?.levelName ?? 'Tap to update',
                icon: Icons.shield_outlined,
                accent: _accent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Health Shield details coming soon'),
                    ),
                  );
                },
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
            TextButton(
              onPressed: _openEditFavoritesSheet,
              child: const Text('Edit'),
            ),
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
    final shield = _state.shield;
    final shieldProgress = shield?.progressPercent ?? 0;
    final calories = _todayCaloriesBurned();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _healthShieldFeedCard(shield, shieldProgress),
        _feedGap(),
        _feedCard(
          title: 'Activity',
          value: _formatInt(_todaySteps()),
          subtitle: _todaySteps() > 0
              ? '${_todayActiveMinutes()} active min • $calories kcal'
              : 'No activity data for today',
          icon: Icons.directions_run_outlined,
          accent: _green,
          onTap: () => context.pushNamed('healthActivity'),
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
      ],
    );
  }

  Widget _healthShieldFeedCard(HealthShield? shield, int progress) {
    final level = shield?.level.toString() ?? 'No data';
    final levelName = shield?.levelName ?? 'Tap to update';
    final todayPoints = shield?.todayPoints ?? 0;
    final habits = shield?.completedHabitsCount ?? 0;

    return _premiumCard(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health Shield details coming soon')),
        );
      },
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
                  shield == null ? 'No data' : 'Level $level • $progress%',
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shield == null
                      ? levelName
                      : '$levelName • $todayPoints pts today • $habits habits',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, height: 1.3),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: (progress / 100).clamp(0.0, 1.0),
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
