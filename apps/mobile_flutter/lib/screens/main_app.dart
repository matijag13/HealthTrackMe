import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/activity_tracking_service.dart';
import '../services/api_service.dart';
import '../services/wearable_service.dart';

class MainApp extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainApp({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  static const String _kLastSyncKey = 'health_last_sync_ms';

  /// How often we pull fresh health data while the app is open. Health Connect
  /// can't push, so a short foreground poll is what makes the data feel live.
  static const Duration _foregroundSyncInterval = Duration(minutes: 2);

  final WearableService _wearableService = WearableService();
  final ApiService _api = ApiService.instance;

  Timer? _syncTimer;
  bool _syncInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sync once on entry, then keep it ticking while the shell is alive.
    _foregroundSync();
    _syncTimer =
        Timer.periodic(_foregroundSyncInterval, (_) => _foregroundSync());
    _maybeStartActivityTracking();
  }

  /// Starts auto walk/run detection if the user enabled it.
  Future<void> _maybeStartActivityTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('pref_auto_activity') ?? false) {
        await ActivityTrackingService.instance.start();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foregroundSync();
    }
  }

  /// Pull the latest data from Health Connect / Apple Health while the app is
  /// foregrounded so on-screen vitals feel near-real-time. Best-effort and
  /// silent: it skips on web, when no user is signed in, or when health
  /// permissions aren't granted. The 15-min WorkManager job and the manual
  /// Sync button remain as fallbacks.
  Future<void> _foregroundSync() async {
    if (_syncInFlight) return;
    _syncInFlight = true;
    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) return;
      if (!await _wearableService.hasPermissions()) return;

      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastSyncKey);
      final startDate = lastMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMs)
          : DateTime.now().subtract(const Duration(hours: 24));

      await _wearableService.syncWearableData(
        userId: userId,
        startDate: startDate,
      );
      await prefs.setInt(_kLastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Swallow — background job + manual sync cover failures.
    } finally {
      _syncInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
    );
  }
}
