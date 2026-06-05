import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'api_service.dart';
import 'wearable_service.dart';

const String _kTaskName = 'com.healthtrackme.health_sync';
const String _kLastSyncKey = 'health_last_sync_ms';

/// Entry point called by WorkManager in a separate isolate.
/// Must be a top-level function annotated with vm:entry-point.
@pragma('vm:entry-point')
void callbackDispatcher() {
  if (kIsWeb) return;

  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await ApiService.instance.init();

      final userId = await ApiService.instance.ensureActiveUserId();
      if (userId == null) {
        debugPrint('⏭ Background sync: no logged-in user, skipping');
        return true;
      }

      final service = WearableService();
      if (!await service.hasPermissions()) {
        debugPrint('⏭ Background sync: Health Connect permissions not granted');
        return true;
      }

      // Only fetch data since the last successful sync to avoid creating
      // duplicate sport-activity entries. Fall back to 24 h on first run.
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastSyncKey);
      final startDate = lastMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMs)
          : DateTime.now().subtract(const Duration(hours: 24));

      await service.syncWearableData(userId: userId, startDate: startDate);

      await prefs.setInt(_kLastSyncKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('✅ Background health sync complete');
      return true;
    } catch (e) {
      debugPrint('❌ Background health sync error: $e');
      return false;
    }
  });
}

class BackgroundSyncService {
  static const _periodicTaskId = '${_kTaskName}_periodic';

  /// Initialise WorkManager. Call once from main() before runApp().
  static Future<void> init() async {
    if (kIsWeb) return;

    await Workmanager().initialize(callbackDispatcher);
  }

  /// Register a periodic task that fires every 15 minutes (Android minimum).
  /// Uses [ExistingWorkPolicy.keep] so re-launches don't reset the timer.
  static Future<void> schedulePeriodicSync() async {
    if (kIsWeb) return;

    await Workmanager().registerPeriodicTask(
      _periodicTaskId,
      _kTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 2),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    debugPrint('📅 Periodic health sync scheduled (every 15 min)');
  }

  /// Trigger an immediate one-off sync — call this when the app resumes.
  static Future<void> syncNow() async {
    if (kIsWeb) return;

    await Workmanager().registerOneOffTask(
      '${_kTaskName}_immediate',
      _kTaskName,
      initialDelay: Duration.zero,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancel the periodic task (e.g. on logout).
  static Future<void> cancel() async {
    if (kIsWeb) return;

    await Workmanager().cancelByUniqueName(_periodicTaskId);
  }
}
