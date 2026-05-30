import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  final ApiService _api = ApiService.instance;
  _DashboardStateModel _state = const _DashboardStateModel();
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAll();
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

  HealthEntry? _todayEntry() {
    final today = DateTime.now();
    final matches = _state.entries.where((e) =>
        e.entryDate.year == today.year &&
        e.entryDate.month == today.month &&
        e.entryDate.day == today.day);
    return matches.isNotEmpty ? matches.first : null;
  }

  double _todaySleepHours() => _todayEntry()?.effectiveSleepHours ?? 0.0;

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
    return value > 0 ? value.toStringAsFixed(1) : 'No data';
  }

  String _formatHeart(HealthEntry? entry) {
    return entry?.heartRate != null ? '${entry!.heartRate}' : 'No data';
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
        Expanded(
          child: Text(
            'Summary',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: _primaryText,
                  fontWeight: FontWeight.w900,
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

    final entry = _todayEntry();
    final activeMeds = _activeMedicinesCount();
    final firstMedicine = _state.medicines.where((m) => m.isActive).isNotEmpty
        ? _state.medicines.firstWhere((m) => m.isActive)
        : null;

    final cards = [
      _favoriteCard(
        title: 'Activity',
        value: _formatInt(_todaySteps()),
        subtitle: _todayActiveMinutes() > 0
            ? '${_todayActiveMinutes()} active min'
            : 'Tap to update',
        icon: Icons.directions_walk,
        accent: _green,
        onTap: () => context.pushNamed('healthActivity'),
      ),
      _favoriteCard(
        title: 'Sleep',
        value: _formatSleep(_todaySleepHours()),
        subtitle: _todaySleepHours() > 0 ? 'hours today' : 'Tap to update',
        icon: Icons.bedtime_outlined,
        accent: _accent,
        onTap: () => context.pushNamed('healthSleep'),
      ),
      _favoriteCard(
        title: 'Heart',
        value: _formatHeart(entry),
        subtitle: entry?.heartRate != null ? 'bpm' : 'Tap to update',
        icon: Icons.favorite_outline,
        accent: _danger,
        onTap: () => context.pushNamed('healthVitals'),
      ),
      _favoriteCard(
        title: 'Medicines',
        value: activeMeds > 0 ? activeMeds.toString() : 'No data',
        subtitle: firstMedicine?.name ?? 'Tap to update',
        icon: Icons.medication_outlined,
        accent: _orange,
        onTap: () => context.pushNamed('meds'),
      ),
    ];

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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Favorites editing coming soon')),
                );
              },
              child: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.28,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        ),
      ],
    );
  }

  Widget _buildFeed() {
    if (_loading) return _loadingCard(height: 420);

    final entry = _todayEntry();
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
              ? entry?.sleepQuality ?? 'Sleep recorded'
              : 'No sleep data for today',
          icon: Icons.nightlight_outlined,
          accent: _accent,
          onTap: () => context.pushNamed('healthSleep'),
        ),
        _feedGap(),
        _feedCard(
          title: 'Vitals',
          value: _formatHeart(entry),
          subtitle: _vitalsSubtitle(entry),
          icon: Icons.monitor_heart_outlined,
          accent: _danger,
          onTap: () => context.pushNamed('healthVitals'),
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
          onTap: () => context.pushNamed('meds'),
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
