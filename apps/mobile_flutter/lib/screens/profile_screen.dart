import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/export_sheet.dart';
import 'edit_profile_screen.dart';

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

  Future<void> _deleteAllData() async {
    HapticFeedback.lightImpact();
    final confirm = await _confirmDialog(
      title: 'Delete all data?',
      message: 'This will permanently delete your data.',
      action: 'Delete',
      danger: true,
    );
    if (confirm != true || _user == null) return;

    final ok = await _api.deleteUser(_user!.id);
    if (!mounted) return;
    _showSnack(ok ? 'Account deleted' : 'Could not delete account');
  }

  Future<void> _signOut() async {
    HapticFeedback.lightImpact();
    final confirm = await _confirmDialog(
      title: 'Sign out?',
      message: 'Are you sure you want to sign out?',
      action: 'Sign out',
    );
    if (confirm != true) return;

    await _api.resetActiveUserId();
    if (!mounted) return;
    context.go('/auth');
  }

  Future<void> _showChangePasswordSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change password',
              style: TextStyle(
                color: _primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Password change flow is not implemented yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryText),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
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

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String action,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _DarkDialog(
        title: title,
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                        const _DiaryReminderTile(),
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
                        const _PreferenceToggleTile(
                          prefKey: 'pref_weekly_report',
                          defaultValue: false,
                          icon: Icons.bar_chart_outlined,
                          accent: _orange,
                          title: 'Weekly health report',
                          subtitle: 'Receive a weekly summary',
                        ),
                      ]),
                      const SizedBox(height: 22),
                      _section('Privacy / Account', [
                        _ProfileTile(
                          icon: Icons.privacy_tip_outlined,
                          accent: _accent,
                          title: 'Privacy policy',
                          subtitle: 'Review privacy information',
                          onTap: () => _showSnack('Open privacy policy'),
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
                        _ProfileTile(
                          icon: Icons.logout,
                          accent: _danger,
                          title: 'Sign out',
                          subtitle: 'Return to login',
                          onTap: _signOut,
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _openEditProfile(user),
                      style: TextButton.styleFrom(
                        foregroundColor: _accent,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Edit profile'),
                    ),
                  ],
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

  Future<void> _pick(String key, List<String> options) async {
    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) => _DarkDialog(
        title: 'Choose unit',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (option) => ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(
                      color: _ProfileScreenState._primaryText,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, option),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (chosen != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, chosen);
      await _load();
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
        await _pick('pref_weight_unit', ['kg', 'lbs']);
        await _pick('pref_height_unit', ['cm', 'ft']);
        await _pick('pref_distance_unit', ['km', 'mi']);
        await _pick('pref_temp_unit', ['C', 'F']);
      },
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
      builder: (ctx) => _DarkDialog(
        title: 'Start of week',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Monday',
                  style: TextStyle(color: _ProfileScreenState._primaryText)),
              onTap: () => Navigator.pop(ctx, 'Monday'),
            ),
            ListTile(
              title: const Text('Sunday',
                  style: TextStyle(color: _ProfileScreenState._primaryText)),
              onTap: () => Navigator.pop(ctx, 'Sunday'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
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
    final picked = await showTimePicker(context: context, initialTime: _time);
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
