import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/activity_tracking_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/phone_sensor_service.dart';
import '../services/sleep_tracking_service.dart';
import '../services/wearable_service.dart';
import '../widgets/dark_time_picker.dart';
import '../widgets/export_sheet.dart';
import 'edit_profile_screen.dart';

enum _ProfileToastType { success, error, neutral }

class _ProfileToastTheme {
  final IconData icon;
  final Color accent;

  const _ProfileToastTheme({required this.icon, required this.accent});
}

void _showProfileToast(
  BuildContext context,
  String message, {
  _ProfileToastType type = _ProfileToastType.neutral,
}) {
  final theme = switch (type) {
    _ProfileToastType.success => const _ProfileToastTheme(
        icon: Icons.check_circle_rounded,
        accent: _ProfileScreenState._green,
      ),
    _ProfileToastType.error => const _ProfileToastTheme(
        icon: Icons.error_outline_rounded,
        accent: _ProfileScreenState._danger,
      ),
    _ProfileToastType.neutral => const _ProfileToastTheme(
        icon: Icons.notifications_none_rounded,
        accent: _ProfileScreenState._accent,
      ),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 3),
      dismissDirection: DismissDirection.horizontal,
      content: Container(
        decoration: BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.accent.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: theme.accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: theme.accent.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(theme.icon, color: theme.accent, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: _ProfileScreenState._primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  late Future<User?> _userFuture;
  User? _user;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<User?> _loadUser() async {
    final user = await _api.getCurrentUser();
    setState(() => _user = user);
    return user;
  }

  Future<void> _refresh() async {
    setState(() => _userFuture = _loadUser());
    await _userFuture;
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null || _user == null) return;

      final b64 = base64Encode(await picked.readAsBytes());
      final updated = User(
        id: _user!.id,
        email: _user!.email,
        firstName: _user!.firstName,
        lastName: _user!.lastName,
        dateOfBirth: _user!.dateOfBirth,
        userType: _user!.userType,
        medicalConditions: _user!.medicalConditions,
        allergies: _user!.allergies,
        isActive: _user!.isActive,
        heightCm: _user!.heightCm,
        weightKg: _user!.weightKg,
        heightUnit: _user!.heightUnit,
        gender: _user!.gender,
        emergencyContactName: _user!.emergencyContactName,
        emergencyContactPhone: _user!.emergencyContactPhone,
        chronicConditions: _user!.chronicConditions,
        allergiesList: _user!.allergiesList,
        pastSurgeries: _user!.pastSurgeries,
        familyHistory: _user!.familyHistory,
        vaccinations: _user!.vaccinations,
        bloodType: _user!.bloodType,
        organDonor: _user!.organDonor,
        doctorName: _user!.doctorName,
        doctorClinic: _user!.doctorClinic,
        doctorPhone: _user!.doctorPhone,
        insuranceProvider: _user!.insuranceProvider,
        insurancePolicyNumber: _user!.insurancePolicyNumber,
        profilePhotoBase64: b64,
      );
      final saved = await _api.updateUser(_user!.id, updated);
      setState(() => _user = saved);
      if (!mounted) return;
      _showSnack('Profile photo updated');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error uploading photo: $e');
    }
  }

  void _openEditProfile(User user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: user, onSaved: _refresh),
      ),
    );
    await _refresh();
  }

  Future<void> _exportData() async {
    await showExportSheet(context);
  }

  Future<void> _testNotifications() async {
    final notifs = NotificationService.instance;
    final enabled = await notifs.requestPermissions();
    await notifs.showTestNotification();
    await notifs.scheduleTestReminderIn(seconds: 30);
    final canExact = await notifs.canScheduleExact();
    final pending = await notifs.pendingCount();
    final tzName = notifs.localTimezoneName();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _DarkDialog(
        title: 'Notification test',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bumped on each notification fix so we can confirm the running
            // build actually contains the latest changes.
            _debugLine('Build', 'notif-fix-6 (no-r8)'),
            _debugLine('Notifications allowed', enabled ? 'Yes' : 'NO'),
            _debugLine('Exact alarms allowed', canExact ? 'Yes' : 'NO'),
            _debugLine('Timezone', tzName),
            _debugLine('Scheduled (pending)', '$pending'),
            const SizedBox(height: 12),
            Text(
              canExact
                  ? 'Sent one now + one in 30s. If the 30s one never arrives, '
                      'the OS (battery/Doze) is dropping it.'
                  : 'Exact alarms are OFF — that is why scheduled reminders '
                      'never fire. Allow "Alarms & reminders" for HealthTrackMe '
                      'in Android settings.',
              style: const TextStyle(color: _secondaryText, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _DeleteDataDialog(),
    );
    if (confirm != true || _user == null) return;

    final ok = await _api.deleteUser(_user!.id);
    if (!mounted) return;
    if (ok) {
      await _api.resetActiveUserId();
      if (!mounted) return;
      context.go('/auth');
    } else {
      _showSnack('Could not delete account');
    }
  }

  Future<void> _showChangePasswordSheet() async {
    HapticFeedback.lightImpact();
    final userId = _user?.id;
    if (userId == null) {
      _showSnack('No active user');
      return;
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChangePasswordSheet(userId: userId),
    );
    if (!mounted || changed != true) return;
    _showSnack('Password updated');
  }

  Future<void> _showPrivacyPolicy() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _PrivacyPolicySheet(),
    );
  }

  Future<void> _showApiConfiguration() async {
    final debugInfo = await _api.getDebugInfo();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _DarkDialog(
        title: 'API Configuration',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              await _api.resetApiConfiguration();
              if (!ctx.mounted || !mounted) return;
              Navigator.pop(ctx);
              _showSnack('API configuration reset');
            },
            child: const Text('Reset API', style: TextStyle(color: _danger)),
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

  void _showSnack(String message) {
    final type = message.startsWith('Error') ||
            message.startsWith('Could not') ||
            message.contains('failed')
        ? _ProfileToastType.error
        : message.startsWith('Open ')
            ? _ProfileToastType.neutral
            : _ProfileToastType.success;
    _showProfileToast(context, message, type: type);
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ProfileLoading();
          }

          final user = snapshot.data ?? _user;
          if (user == null) {
            return _EmptyProfileState(onBack: _goBack);
          }

          return RefreshIndicator(
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _topBar(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _profileHeaderCard(user),
                      const SizedBox(height: 24),
                      _section('Account', [
                        _ProfileTile(
                          icon: Icons.person_outline,
                          accent: _accent,
                          title: 'Personal details',
                          subtitle: 'Name, DOB, gender, height',
                          onTap: () => _openEditProfile(user),
                        ),
                        _ProfileTile(
                          icon: Icons.emoji_events_outlined,
                          accent: _orange,
                          title: 'Friends & leaderboard',
                          subtitle:
                              'Compare streaks & Shield points with friends',
                          onTap: () => context.pushNamed('friends'),
                        ),
                        _ProfileTile(
                          icon: Icons.upload_file_outlined,
                          accent: _green,
                          title: 'Export data',
                          subtitle: 'Copy or email your health data',
                          onTap: _exportData,
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _section('Preferences', [
                        const _UnitsTile(),
                        _StartOfWeekTile(showSnack: _showSnack),
                      ]),
                      const SizedBox(height: 22),
                      _section('Manage permissions', [
                        _PreferenceToggleTile(
                          prefKey: 'pref_phone_tracking',
                          defaultValue: false,
                          icon: Icons.directions_walk_rounded,
                          accent: _green,
                          title: 'Track steps on this phone',
                          subtitle:
                              "Count steps with the phone's own sensor — no Samsung Health needed",
                          onChanged: (value) async {
                            if (value) {
                              await WearableService().requestPermissions();
                              await PhoneSensorService.instance.recordSteps();
                            }
                          },
                        ),
                        _PreferenceToggleTile(
                          prefKey: 'pref_auto_activity',
                          defaultValue: false,
                          icon: Icons.directions_run_rounded,
                          accent: _accent,
                          title: 'Auto-detect walks & runs',
                          subtitle:
                              'Log walking/running sessions automatically while the app runs',
                          onChanged: (value) async {
                            if (value) {
                              await WearableService().requestPermissions();
                              await ActivityTrackingService.instance.start();
                            } else {
                              await ActivityTrackingService.instance.stop();
                            }
                          },
                        ),
                        _PreferenceToggleTile(
                          prefKey: SleepTrackingService.prefEnabled,
                          defaultValue: false,
                          icon: Icons.bedtime_rounded,
                          accent: _orange,
                          title: 'Detect sleep in the background',
                          subtitle:
                              'Notices long overnight rest and logs your sleep — keeps a quiet notification running',
                          onChanged: (value) async {
                            if (value) {
                              await WearableService().requestPermissions();
                              final ok =
                                  await SleepTrackingService.instance.start();
                              if (!ok) {
                                _showSnack(
                                    'Could not start sleep tracking — check notification permission');
                              }
                            } else {
                              await SleepTrackingService.instance.stop();
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _section('Reminders', [
                        const _DiaryReminderTile(),
                        _PreferenceToggleTile(
                          prefKey: 'pref_streak_reminder',
                          defaultValue: false,
                          icon: Icons.local_fire_department_rounded,
                          accent: _orange,
                          title: 'Morning streak reminder',
                          subtitle:
                              'A 9 AM nudge to log today and keep your streak alive',
                          onChanged: (value) async {
                            if (value) {
                              await NotificationService.instance
                                  .requestPermissions();
                              await NotificationService.instance
                                  .scheduleDailyStreakReminder(
                                      const TimeOfDay(hour: 9, minute: 0));
                            } else {
                              await NotificationService.instance
                                  .cancelDailyStreakReminder();
                            }
                          },
                        ),
                        _PreferenceToggleTile(
                          prefKey: 'pref_medicine_reminders',
                          defaultValue: true,
                          icon: Icons.medication_outlined,
                          accent: _green,
                          title: 'Medicine reminders',
                          subtitle: 'Turn all medicine reminders on or off',
                          onChanged: (value) async {
                            // Off → cancel everything now. On → reminders are
                            // re-scheduled next time the Medicines screen loads.
                            if (!value) {
                              await NotificationService.instance
                                  .cancelAllMedicineReminders();
                            }
                          },
                        ),
                        const _WeeklyReportTile(),
                        _ProfileTile(
                          icon: Icons.notifications_active_outlined,
                          accent: _accent,
                          title: 'Test notifications',
                          subtitle: 'Send one now + one in 30 seconds',
                          onTap: _testNotifications,
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _section('Privacy / Account', [
                        _ProfileTile(
                          icon: Icons.privacy_tip_outlined,
                          accent: _accent,
                          title: 'Privacy policy',
                          subtitle: 'Review privacy information',
                          onTap: _showPrivacyPolicy,
                        ),
                        _ProfileTile(
                          icon: Icons.delete_outline,
                          accent: _danger,
                          title: 'Delete all my data',
                          subtitle: 'Permanent account data removal',
                          onTap: _deleteAllData,
                        ),
                        _ProfileTile(
                          icon: Icons.lock_outline,
                          accent: _orange,
                          title: 'Change password',
                          subtitle: 'Update your account password',
                          onTap: _showChangePasswordSheet,
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _section('Debug', [
                        _ProfileTile(
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
        },
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _IconButtonSurface(icon: Icons.arrow_back, onTap: _goBack),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Profile',
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

  Widget _profileHeaderCard(User user) {
    return _ProfileCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickAndUploadPhoto,
            child: _ProfileAvatar(user: user, radius: 42),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Unknown user' : user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
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
        _ProfileCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const _TileDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _ProfileCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileScreenState._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ProfileScreenState._border.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
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
              _IconTile(icon: icon, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileScreenState._primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ProfileScreenState._secondaryText,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _ProfileScreenState._secondaryText,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const _ProfileAvatar({required this.user, required this.radius});

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    final photo = user.profilePhotoBase64;
    if (photo != null && photo.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photo));
      } catch (_) {
        image = null;
      }
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _ProfileScreenState._border),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _ProfileScreenState._surfaceAlt,
        backgroundImage: image,
        child: image == null
            ? Text(
                user.initials,
                style: TextStyle(
                  color: _ProfileScreenState._primaryText,
                  fontSize: radius * 0.42,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconTile({required this.icon, required this.color});

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
            color: _ProfileScreenState._surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _ProfileScreenState._border),
          ),
          child: Icon(icon, color: _ProfileScreenState._primaryText, size: 21),
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Container(
        height: 1,
        color: _ProfileScreenState._border.withValues(alpha: 0.45),
      ),
    );
  }
}

class _DeleteDataDialog extends StatelessWidget {
  const _DeleteDataDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        decoration: BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _ProfileScreenState._danger.withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.46),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: _ProfileScreenState._danger,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(22),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _ProfileScreenState._danger
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _ProfileScreenState._danger
                                .withValues(alpha: 0.32),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_forever_outlined,
                          color: _ProfileScreenState._danger,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete all data?',
                              style: TextStyle(
                                color: _ProfileScreenState._primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'This permanently removes your account and health data from HealthTrackMe. This cannot be undone.',
                              style: TextStyle(
                                color: _ProfileScreenState._secondaryText,
                                height: 1.42,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _ProfileScreenState._surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _ProfileScreenState._border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _ProfileScreenState._danger,
                          size: 18,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Your login session will end after deletion.',
                            style: TextStyle(
                              color: _ProfileScreenState._primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ProfileScreenState._primaryText,
                            side: const BorderSide(
                              color: _ProfileScreenState._border,
                            ),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: _ProfileScreenState._danger,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w900),
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
}

class _ChangePasswordSheet extends StatefulWidget {
  final int userId;

  const _ChangePasswordSheet({required this.userId});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  String? _newPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 6) return 'Use at least 6 characters';
    if (value == _currentController.text) return 'Use a different password';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value != _newController.text) return 'Passwords do not match';
    return null;
  }

  void _clearServerError() {
    if (_error == null) return;
    setState(() => _error = null);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _clearServerError();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.instance.changePassword(
        userId: widget.userId,
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        confirmPassword: _confirmController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: _ProfileScreenState._surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: _ProfileScreenState._border)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Change password',
                          style: TextStyle(
                            color: _ProfileScreenState._primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: IconButton(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _ProfileScreenState._primaryText,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _ProfileScreenState._surfaceAlt,
                            side: BorderSide(
                              color: _ProfileScreenState._border
                                  .withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter your current password and choose a new one.',
                    style: TextStyle(
                      color: _ProfileScreenState._secondaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PasswordField(
                    controller: _currentController,
                    label: 'Current password',
                    visible: _showCurrent,
                    onToggle: () =>
                        setState(() => _showCurrent = !_showCurrent),
                    onChanged: (_) => _clearServerError(),
                    validator: _requiredPassword,
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: _newController,
                    label: 'New password',
                    visible: _showNew,
                    onToggle: () => setState(() => _showNew = !_showNew),
                    onChanged: (_) => _clearServerError(),
                    validator: _newPasswordValidator,
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: _confirmController,
                    label: 'Confirm new password',
                    visible: _showConfirm,
                    onToggle: () =>
                        setState(() => _showConfirm = !_showConfirm),
                    onChanged: (_) => _clearServerError(),
                    validator: _confirmPasswordValidator,
                    onSubmitted: (_) => _saving ? null : _save(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _PasswordErrorAlert(message: _error!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _ProfileScreenState._accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update password',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    required this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      textInputAction:
          onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      style: const TextStyle(color: _ProfileScreenState._primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _ProfileScreenState._secondaryText),
        filled: true,
        fillColor: _ProfileScreenState._bg,
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _ProfileScreenState._secondaryText,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ProfileScreenState._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ProfileScreenState._accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ProfileScreenState._danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ProfileScreenState._danger),
        ),
      ),
    );
  }
}

class _PasswordErrorAlert extends StatelessWidget {
  final String message;

  const _PasswordErrorAlert({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _ProfileScreenState._surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _ProfileScreenState._danger.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: _ProfileScreenState._danger,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _ProfileScreenState._danger,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: _ProfileScreenState._primaryText,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicySheet extends StatelessWidget {
  const _PrivacyPolicySheet();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.86;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: _ProfileScreenState._surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _ProfileScreenState._border)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          _ProfileScreenState._accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            _ProfileScreenState._accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: _ProfileScreenState._accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy policy',
                          style: TextStyle(
                            color: _ProfileScreenState._primaryText,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Last updated: June 7, 2026',
                          style: TextStyle(
                            color: _ProfileScreenState._secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _ProfileScreenState._primaryText,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _ProfileScreenState._surfaceAlt,
                        side: BorderSide(
                          color: _ProfileScreenState._border
                              .withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: _ProfileScreenState._border, height: 22),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: const [
                  Text(
                    'HealthTrackMe uses your health information only to show your dashboard, reminders, reports, and wearable sync results inside the app.',
                    style: TextStyle(
                      color: _ProfileScreenState._primaryText,
                      height: 1.45,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 18),
                  _PrivacyPolicyItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'Health data we store',
                    body:
                        'Profile details, symptoms, medicines, sleep, activity, steps, heart rate, calories, notes, reminders, and connected wearable device records.',
                  ),
                  _PrivacyPolicyItem(
                    icon: Icons.sync_rounded,
                    title: 'Wearable and sensor sync',
                    body:
                        'When you enable sync, the app reads permitted Health Connect or device data and uploads the selected health metrics to your HealthTrackMe account.',
                  ),
                  _PrivacyPolicyItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'How your data is protected',
                    body:
                        'Account access is controlled by authentication. Health data is sent to the backend for your account features and is not sold for advertising.',
                  ),
                  _PrivacyPolicyItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    body:
                        'Reminder settings are used to schedule medicine, diary, and health notifications. You can disable them from this screen or system settings.',
                  ),
                  _PrivacyPolicyItem(
                    icon: Icons.delete_outline_rounded,
                    title: 'Deleting your data',
                    body:
                        'Use "Delete all my data" in Privacy / Account to request permanent removal of your account data from the app backend.',
                  ),
                  _PrivacyPolicyItem(
                    icon: Icons.mail_outline_rounded,
                    title: 'Questions',
                    body:
                        'For privacy questions, contact the HealthTrackMe project owner or your course project maintainer.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPolicyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrivacyPolicyItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _ProfileScreenState._accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _ProfileScreenState._accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ProfileScreenState._primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: _ProfileScreenState._secondaryText,
                    height: 1.42,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _DarkDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _ProfileScreenState._surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _ProfileScreenState._border),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _ProfileScreenState._primaryText,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: content,
      actions: actions,
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _ProfileScreenState._accent),
    );
  }
}

class _EmptyProfileState extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyProfileState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconButtonSurface(icon: Icons.arrow_back, onTap: onBack),
            const Spacer(),
            const Center(
              child: Text(
                'No user data available.',
                style: TextStyle(color: _ProfileScreenState._secondaryText),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _UnitsTile extends StatefulWidget {
  const _UnitsTile();

  @override
  State<_UnitsTile> createState() => _UnitsTileState();
}

class _UnitsTileState extends State<_UnitsTile> {
  String _weight = 'kg';
  String _height = 'cm';
  String _distance = 'km';
  String _temp = 'C';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _weight = prefs.getString('pref_weight_unit') ?? 'kg';
      _height = prefs.getString('pref_height_unit') ?? 'cm';
      _distance = prefs.getString('pref_distance_unit') ?? 'km';
      _temp = prefs.getString('pref_temp_unit') ?? 'C';
    });
  }

  Future<void> _openUnitsDialog() async {
    final result = await showDialog<_UnitsSelection>(
      context: context,
      builder: (ctx) => _UnitsDialog(
        initial: _UnitsSelection(
          weight: _weight,
          height: _height,
          distance: _distance,
          temp: _temp,
        ),
      ),
    );
    if (result == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_weight_unit', result.weight);
    await prefs.setString('pref_height_unit', result.height);
    await prefs.setString('pref_distance_unit', result.distance);
    await prefs.setString('pref_temp_unit', result.temp);
    await _load();
    if (mounted) {
      _showProfileToast(
        context,
        'Units updated',
        type: _ProfileToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileTile(
      icon: Icons.swap_horiz,
      title: 'Units',
      subtitle:
          'Weight: $_weight • Height: $_height • Distance: $_distance • Temp: $_temp',
      accent: _ProfileScreenState._accent,
      onTap: () async {
        HapticFeedback.lightImpact();
        await _openUnitsDialog();
      },
    );
  }
}

class _UnitsSelection {
  final String weight;
  final String height;
  final String distance;
  final String temp;

  const _UnitsSelection({
    required this.weight,
    required this.height,
    required this.distance,
    required this.temp,
  });
}

class _UnitsDialog extends StatefulWidget {
  final _UnitsSelection initial;

  const _UnitsDialog({required this.initial});

  @override
  State<_UnitsDialog> createState() => _UnitsDialogState();
}

class _UnitsDialogState extends State<_UnitsDialog> {
  late String _weight;
  late String _height;
  late String _distance;
  late String _temp;

  @override
  void initState() {
    super.initState();
    _weight = widget.initial.weight;
    _height = widget.initial.height;
    _distance = widget.initial.distance;
    _temp = widget.initial.temp;
  }

  void _save() {
    Navigator.pop(
      context,
      _UnitsSelection(
        weight: _weight,
        height: _height,
        distance: _distance,
        temp: _temp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _ProfileScreenState._surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _ProfileScreenState._border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Units',
              style: TextStyle(
                color: _ProfileScreenState._primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _DialogCloseButton(onTap: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UnitOptionRow(
              icon: Icons.monitor_weight_outlined,
              title: 'Weight',
              value: _weight,
              options: const ['kg', 'lbs'],
              onChanged: (value) => setState(() => _weight = value),
            ),
            const SizedBox(height: 12),
            _UnitOptionRow(
              icon: Icons.height_rounded,
              title: 'Height',
              value: _height,
              options: const ['cm', 'ft'],
              onChanged: (value) => setState(() => _height = value),
            ),
            const SizedBox(height: 12),
            _UnitOptionRow(
              icon: Icons.route_outlined,
              title: 'Distance',
              value: _distance,
              options: const ['km', 'mi'],
              onChanged: (value) => setState(() => _distance = value),
            ),
            const SizedBox(height: 12),
            _UnitOptionRow(
              icon: Icons.thermostat_outlined,
              title: 'Temperature',
              value: _temp,
              options: const ['C', 'F'],
              onChanged: (value) => setState(() => _temp = value),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: _ProfileScreenState._accent,
              foregroundColor: _ProfileScreenState._primaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DialogCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _ProfileScreenState._surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: _ProfileScreenState._border),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: _ProfileScreenState._primaryText,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _UnitOptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _UnitOptionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        final titleRow = Row(
          children: [
            _IconTile(icon: icon, color: _ProfileScreenState._accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ProfileScreenState._primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
        final control = _UnitSegmentedControl(
          value: value,
          options: options,
          onChanged: onChanged,
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _ProfileScreenState._surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ProfileScreenState._border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: control),
                  ],
                )
              : Row(
                  children: [
                    _IconTile(icon: icon, color: _ProfileScreenState._accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _ProfileScreenState._primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    control,
                  ],
                ),
        );
      },
    );
  }
}

class _UnitSegmentedControl extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _UnitSegmentedControl({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _ProfileScreenState._bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _ProfileScreenState._border.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            _UnitSegment(
              label: option,
              selected: option == value,
              onTap: () => onChanged(option),
            ),
        ],
      ),
    );
  }
}

class _UnitSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 48,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _ProfileScreenState._accent.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? _ProfileScreenState._accent : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? _ProfileScreenState._primaryText
                  : _ProfileScreenState._secondaryText,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartOfWeekTile extends StatelessWidget {
  final ValueChanged<String> showSnack;

  const _StartOfWeekTile({required this.showSnack});

  Future<void> _pick(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) => _StartOfWeekDialog(
        initial: prefs.getString('pref_start_of_week') ?? 'Monday',
      ),
    );
    if (chosen != null) {
      await prefs.setString('pref_start_of_week', chosen);
      showSnack('Start of week set to $chosen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileTile(
      icon: Icons.flag_outlined,
      accent: _ProfileScreenState._orange,
      title: 'Start of week',
      subtitle: 'Monday or Sunday',
      onTap: () => _pick(context),
    );
  }
}

class _StartOfWeekDialog extends StatefulWidget {
  final String initial;

  const _StartOfWeekDialog({required this.initial});

  @override
  State<_StartOfWeekDialog> createState() => _StartOfWeekDialogState();
}

class _StartOfWeekDialogState extends State<_StartOfWeekDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  void _save() {
    Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _ProfileScreenState._surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _ProfileScreenState._border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Start of week',
              style: TextStyle(
                color: _ProfileScreenState._primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _DialogCloseButton(onTap: () => Navigator.pop(context)),
        ],
      ),
      content: _WeekStartPicker(
        value: _selected,
        onChanged: (value) => setState(() => _selected = value),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: _ProfileScreenState._accent,
              foregroundColor: _ProfileScreenState._primaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _WeekStartPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _WeekStartPicker({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ProfileScreenState._surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ProfileScreenState._border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WeekStartOption(
            icon: Icons.calendar_view_week_outlined,
            title: 'Monday',
            subtitle: 'Use the ISO week format',
            selected: value == 'Monday',
            onTap: () => onChanged('Monday'),
          ),
          const SizedBox(height: 10),
          _WeekStartOption(
            icon: Icons.calendar_month_outlined,
            title: 'Sunday',
            subtitle: 'Use the US week format',
            selected: value == 'Sunday',
            onTap: () => onChanged('Sunday'),
          ),
        ],
      ),
    );
  }
}

class _WeekStartOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _WeekStartOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? _ProfileScreenState._accent
        : _ProfileScreenState._secondaryText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? _ProfileScreenState._accent.withValues(alpha: 0.14)
                : _ProfileScreenState._surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _ProfileScreenState._accent
                  : _ProfileScreenState._border,
            ),
          ),
          child: Row(
            children: [
              _IconTile(icon: icon, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileScreenState._primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileScreenState._secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: accent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceToggleTile extends StatefulWidget {
  final String prefKey;
  final bool defaultValue;
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Future<void> Function(bool value)? onChanged;

  const _PreferenceToggleTile({
    required this.prefKey,
    required this.defaultValue,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.onChanged,
  });

  @override
  State<_PreferenceToggleTile> createState() => _PreferenceToggleTileState();
}

class _PreferenceToggleTileState extends State<_PreferenceToggleTile> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool(widget.prefKey) ?? widget.defaultValue;
    });
  }

  Future<void> _toggle(bool value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, value);
    if (mounted) setState(() => _enabled = value);
    await widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileTile(
      icon: widget.icon,
      accent: widget.accent,
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: Switch(
        value: _enabled ?? widget.defaultValue,
        onChanged: _toggle,
        activeThumbColor: _ProfileScreenState._accent,
      ),
      onTap: () => _toggle(!(_enabled ?? widget.defaultValue)),
    );
  }
}

class _DiaryReminderTile extends StatefulWidget {
  const _DiaryReminderTile();

  @override
  State<_DiaryReminderTile> createState() => _DiaryReminderTileState();
}

class _DiaryReminderTileState extends State<_DiaryReminderTile> {
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('pref_diary_enabled') ?? false;
    final raw = prefs.getString('pref_diary_time');
    if (raw != null) {
      final parts = raw.split(':');
      if (parts.length == 2) {
        _time =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _pickTime() async {
    final picked = await showDarkTimePicker(
      context: context,
      initialTime: _time,
      title: 'Enter time',
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pref_diary_time',
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
      );
      if (mounted) setState(() => _time = picked);
      if (_enabled) {
        await NotificationService.instance.scheduleDailyDiaryReminder(picked);
      }
    }
  }

  Future<void> _toggle(bool value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_diary_enabled', value);
    if (mounted) setState(() => _enabled = value);
    if (value) {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleDailyDiaryReminder(_time);
    } else {
      await NotificationService.instance.cancelDailyDiaryReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileTile(
      icon: Icons.notifications_active_outlined,
      accent: _ProfileScreenState._green,
      title: 'Daily reminder',
      subtitle: 'Time: ${_time.format(context)}',
      trailing: Switch(
        value: _enabled,
        onChanged: _toggle,
        activeThumbColor: _ProfileScreenState._accent,
      ),
      onTap: _pickTime,
    );
  }
}

/// Weekly AI report opt-in. State is stored server-side (so the backend's
/// scheduled job knows who to email), loaded and saved over the API.
class _WeeklyReportTile extends StatefulWidget {
  const _WeeklyReportTile();

  @override
  State<_WeeklyReportTile> createState() => _WeeklyReportTileState();
}

class _WeeklyReportTileState extends State<_WeeklyReportTile> {
  final ApiService _api = ApiService.instance;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _api.getWeeklyReport();
    if (mounted) {
      setState(() {
        _enabled = value;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _enabled = value);
    final ok = await _api.setWeeklyReport(value);
    if (!ok && mounted) {
      setState(() => _enabled = !value); // revert on failure
      _showProfileToast(
        context,
        'Could not update weekly report setting',
        type: _ProfileToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileTile(
      icon: Icons.bar_chart_outlined,
      accent: _ProfileScreenState._orange,
      title: 'Weekly health report',
      subtitle: 'AI summary emailed every Monday',
      trailing: _loading
          ? const SizedBox(
              width: 40,
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Switch(
              value: _enabled,
              onChanged: _toggle,
              activeThumbColor: _ProfileScreenState._accent,
            ),
      onTap: _loading ? null : () => _toggle(!_enabled),
    );
  }
}
