import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'api_service.dart';
import 'wearable_service.dart';

const String _kTaskName = 'com.healthtrackme.health_sync';

/// Entry point called by WorkManager in a separate isolate.
/// Must be a top-level function annotated with vm:entry-point.
@pragma('vm:entry-point')
void callbackDispatcher() {
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

      await service.syncWearableData(
        userId: userId,
        // Only pull the last 24 h to keep background tasks fast
        startDate: DateTime.now().subtract(const Duration(hours: 24)),
      );

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
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Register a periodic task that fires every 15 minutes (Android minimum).
  /// Uses [ExistingWorkPolicy.keep] so re-launches don't reset the timer.
  static Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      _periodicTaskId,
      _kTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 2),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
    debugPrint('📅 Periodic health sync scheduled (every 15 min)');
  }

  /// Trigger an immediate one-off sync — call this when the app resumes.
  static Future<void> syncNow() async {
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
    await Workmanager().cancelByUniqueName(_periodicTaskId);
  }
}
