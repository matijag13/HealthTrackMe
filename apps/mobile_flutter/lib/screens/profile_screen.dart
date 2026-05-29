import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import 'edit_profile_screen.dart';
import 'medical_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService.instance;
  late Future<User?> _userFuture;
  User? _user;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<User?> _loadUser() async {
    final u = await _api.getCurrentUser();
    setState(() => _user = u);
    return u;
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
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      if (_user == null) {
        return;
      }
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
        profilePhotoBase64: b64,
      );
      final saved = await _api.updateUser(_user!.id, updated);
      setState(() => _user = saved);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
    }
  }

  Widget _buildUserCard(User user) {
    Widget avatar;
    if (user.profilePhotoBase64 != null &&
        user.profilePhotoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(user.profilePhotoBase64!);
        avatar = CircleAvatar(radius: 40, backgroundImage: MemoryImage(bytes));
      } catch (_) {
        avatar = CircleAvatar(radius: 40, child: Text(user.initials));
      }
    } else {
      avatar = CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.blue,
          child: Text(user.initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)));
    }

    return Card(
      color: AppColors.softBlue,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(onTap: _pickAndUploadPhoto, child: avatar),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName.isEmpty ? 'Unknown user' : user.fullName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.lightCard,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(user.userType,
                        style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
            TextButton(
                onPressed: () => _openEditProfile(user),
                child: const Text('Edit Profile'))
          ],
        ),
      ),
    );
  }

  void _openEditProfile(User user) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: user, onSaved: _refresh)));
    await _refresh();
  }

  Future<void> _exportData() async {
    final id = _api.activeUserId ?? await _api.ensureActiveUserId();
    if (!mounted) return;
    if (id == null) {
      return;
    }
    final uri = Uri.parse('${_api.baseUrl}/export/pdf/$id');
    // For simplicity open in browser (in web builds) or show message. Complex share not implemented here.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Export endpoint: $uri')));
  }

  Widget _sectionLabel(String text) {
    return SectionHeader(title: text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), elevation: 0),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LoadingSkeleton.profile(context)));
          }
          final user = snapshot.data ?? _user;
          if (user == null) {
            return const Center(child: Text('No user data available.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserCard(user),
                    const SizedBox(height: 20),
                    _sectionLabel('ACCOUNT'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5)),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(children: [
                        SettingsTile(
                            icon: const Icon(Icons.person_outline),
                            title: 'Personal details',
                            subtitle: 'Name, DOB, gender, height',
                            onTap: () => _openEditProfile(user),
                            iconBackgroundColor: AppColors.blue),
                        SettingsTile(
                            icon:
                                const Icon(Icons.medical_information_outlined),
                            title: 'Medical history',
                            subtitle: 'Conditions, allergies, surgeries',
                            onTap: () async {
                              await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          MedicalHistoryScreen(user: user)));
                              await _refresh();
                            },
                            iconBackgroundColor: AppColors.danger),
                        SettingsTile(
                            icon: const Icon(Icons.upload_file_outlined),
                            title: 'Export data',
                            subtitle: 'Download your data',
                            onTap: _exportData,
                            iconBackgroundColor: AppColors.teal),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('PREFERENCES'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5)),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(children: [
                        _UnitsTile(),
                        SettingsTile(
                            icon: const Icon(Icons.flag),
                            title: 'Start of week',
                            subtitle: 'Monday or Sunday',
                            onTap: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              if (!context.mounted) {
                                return;
                              }
                              final chosen = await showDialog<String?>(
                                  context: context,
                                  builder: (ctx) => SimpleDialog(
                                          title: const Text('Start of week'),
                                          children: [
                                            SimpleDialogOption(
                                                child: const Text('Monday'),
                                                onPressed: () => Navigator.pop(
                                                    ctx, 'Monday')),
                                            SimpleDialogOption(
                                                child: const Text('Sunday'),
                                                onPressed: () => Navigator.pop(
                                                    ctx, 'Sunday'))
                                          ]));
                              if (chosen != null) {
                                await prefs.setString(
                                    'pref_start_of_week', chosen);
                              }
                            },
                            iconBackgroundColor: AppColors.amber),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('NOTIFICATIONS'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5)),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(children: [
                        _DiaryReminderTile(),
                        SettingsTile(
                            icon: const Icon(Icons.medication),
                            title: 'Medicine reminders',
                            subtitle: 'Master toggle for medicines',
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final current =
                                  prefs.getBool('pref_medicine_reminders') ??
                                      true;
                              await prefs.setBool(
                                  'pref_medicine_reminders', !current);
                              setState(() {});
                            },
                            iconBackgroundColor: AppColors.green,
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: Colors.grey)),
                        SettingsTile(
                            icon: const Icon(Icons.bar_chart),
                            title: 'Weekly health report',
                            subtitle: 'Receive a weekly summary',
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final current =
                                  prefs.getBool('pref_weekly_report') ?? false;
                              await prefs.setBool(
                                  'pref_weekly_report', !current);
                              setState(() {});
                            },
                            iconBackgroundColor: AppColors.orange,
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: Colors.grey)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('HEALTH SHIELD'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5)),
                      color: Theme.of(context).colorScheme.surface,
                      child: const Column(children: [
                        SettingsTile(
                            icon: Icon(Icons.shield),
                            title: 'Health shield',
                            subtitle: 'Current level and progress',
                            trailing: SizedBox.shrink()),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('DATA & PRIVACY'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5)),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(children: [
                        SettingsTile(
                            icon: const Icon(Icons.download_outlined),
                            title: 'Export (PDF/CSV)',
                            onTap: _exportData,
                            iconBackgroundColor: AppColors.blue),
                        SettingsTile(
                            icon: const Icon(Icons.delete_outline),
                            title: 'Delete all my data',
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                          title: const Text('Delete all data?'),
                                          content: const Text(
                                              'This will permanently delete your data.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red)))
                                          ]));
                              if (confirm == true && _user != null) {
                                final ok = await _api.deleteUser(_user!.id);
                                if (!context.mounted) {
                                  return;
                                }
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Account deleted')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Could not delete account')));
                                }
                              }
                            },
                            iconBackgroundColor: AppColors.danger),
                        SettingsTile(
                            icon: const Icon(Icons.privacy_tip_outlined),
                            title: 'Privacy policy',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Open privacy policy')));
                            },
                            iconBackgroundColor: AppColors.teal),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('ACCOUNT'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5)),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(children: [
                        SettingsTile(
                            icon: const Icon(Icons.lock_outline),
                            title: 'Change password',
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              showModalBottomSheet(
                                  context: context,
                                  builder: (ctx) => Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                                'Change password (TODO)'),
                                            const SizedBox(height: 12),
                                            ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('Close'))
                                          ])));
                            },
                            iconBackgroundColor: AppColors.amber),
                        SettingsTile(
                            icon: const Icon(Icons.logout),
                            title: 'Sign out',
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                          title: const Text('Sign out?'),
                                          content: const Text(
                                              'Are you sure you want to sign out?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Sign out'))
                                          ]));
                              if (confirm == true) {
                                await _api.resetActiveUserId();
                                if (!context.mounted) {
                                  return;
                                }
                                Navigator.of(context).pushReplacementNamed('/');
                              }
                            },
                            iconBackgroundColor: AppColors.danger),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('DEBUG'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5)),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(children: [
                        SettingsTile(
                          icon: const Icon(Icons.api),
                          title: 'API Configuration',
                          subtitle: 'View and reset API settings',
                          onTap: () async {
                            final debugInfo = await _api.getDebugInfo();
                            if (!context.mounted) {
                              return;
                            }
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('API Configuration'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          'Base URL: ${debugInfo['currentBaseUrl']}',
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Platform: ${debugInfo['isWeb'] ? 'Web' : 'Mobile'}',
                                          style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Api Reachable: ${debugInfo['canReachApi'] ? '✓ Yes' : '✗ No'}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: debugInfo['canReachApi'] ==
                                                      true
                                                  ? Colors.green
                                                  : Colors.red)),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await _api.resetApiConfiguration();
                                      if (!ctx.mounted || !context.mounted) {
                                        return;
                                      }
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  '✓ API configuration reset')));
                                    },
                                    child: const Text('Reset API',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          iconBackgroundColor: AppColors.blue,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 40),
                  ]),
            ),
          );
        },
      ),
    );
  }
}

class _UnitsTile extends StatefulWidget {
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
    setState(() {
      _weight = prefs.getString('pref_weight_unit') ?? 'kg';
      _height = prefs.getString('pref_height_unit') ?? 'cm';
      _distance = prefs.getString('pref_distance_unit') ?? 'km';
      _temp = prefs.getString('pref_temp_unit') ?? 'C';
    });
  }

  Future<void> _pick(String key, String current, List<String> options) async {
    final chosen = await showDialog<String?>(
        context: context,
        builder: (ctx) => SimpleDialog(
            title: const Text('Choose unit'),
            children: options
                .map((o) => SimpleDialogOption(
                    child: Text(o), onPressed: () => Navigator.pop(ctx, o)))
                .toList()));
    if (chosen != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, chosen);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: const Icon(Icons.swap_horiz),
      title: 'Units',
      subtitle:
          'Weight: $_weight · Height: $_height · Distance: $_distance · Temp: $_temp',
      iconBackgroundColor: AppColors.teal,
      onTap: () async {
        HapticFeedback.lightImpact();
        await _pick('pref_weight_unit', _weight, ['kg', 'lbs']);
        await _pick('pref_height_unit', _height, ['cm', 'ft']);
        await _pick('pref_distance_unit', _distance, ['km', 'mi']);
        await _pick('pref_temp_unit', _temp, ['C', 'F']);
      },
    );
  }
}

class _DiaryReminderTile extends StatefulWidget {
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
    setState(() => _enabled = enabled);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_diary_time',
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: const Icon(Icons.calendar_today),
      title: 'Daily diary reminder',
      subtitle: 'Time: ${_time.format(context)}',
      iconBackgroundColor: AppColors.green,
      trailing: Switch(
        value: _enabled,
        onChanged: (v) async {
          HapticFeedback.selectionClick();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pref_diary_enabled', v);
          setState(() => _enabled = v);
          if (v) {
            await _pickTime();
          }
        },
      ),
      onTap: () async => await _pickTime(),
    );
  }
}
