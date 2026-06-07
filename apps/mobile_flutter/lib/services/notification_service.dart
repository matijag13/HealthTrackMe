import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();

  static NotificationService get instance => _instance;

  NotificationService._();

  late final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _medicineChannelId = 'medicine_dose_reminders';
  static const String _medicineChannelName = 'Medicine Dose Reminders';
  static const String _medicineChannelDesc = 'Reminders for medicine doses';

  static const String _diaryChannelId = 'daily_diary_reminders';
  static const String _diaryChannelName = 'Daily Diary Reminders';
  static const String _diaryChannelDesc = 'Daily reminder to log health entry';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    // tz.local defaults to UTC after initializeTimeZones(). We must explicitly
    // set it to the device's actual timezone, otherwise zonedSchedule() treats
    // reminder times as UTC and they fire offset by the local UTC offset.
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Could not resolve local timezone, using UTC: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    if (kIsWeb) {
      debugPrint('Notifications disabled on Web');
      return;
    }

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    }
  }

  // =========================
  // DIAGNOSTICS / PERMISSIONS
  // =========================

  /// Whether the OS currently allows this app to post notifications.
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return (await android?.areNotificationsEnabled()) ?? false;
  }

  /// Whether the OS allows this app to schedule EXACT alarms. When false,
  /// reminders fall back to inexact alarms, which Android can delay or drop —
  /// the usual reason scheduled reminders never arrive.
  Future<bool> canScheduleExact() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return (await android?.canScheduleExactNotifications()) ?? false;
  }

  /// The resolved local timezone (should be e.g. Europe/Ljubljana, not UTC).
  String localTimezoneName() => tz.local.name;

  /// (Re)request notification + exact-alarm permission. Returns whether
  /// notifications are enabled afterwards.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return (await android?.areNotificationsEnabled()) ?? false;
    }
    return true;
  }

  /// Number of reminders currently scheduled with the OS — useful to confirm
  /// that scheduling actually took effect.
  Future<int> pendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  /// Posts a notification immediately (not scheduled) to verify the whole
  /// pipeline — permission, channel, display — works on this device.
  Future<void> showTestNotification() async {
    await _plugin.show(
      424242,
      'HealthTrackMe test ✓',
      'If you can see this, notifications work. Reminders use the same channel.',
      _medicineDetails,
    );
  }

  /// Schedules a one-off test reminder [seconds] from now (default 30s), so the
  /// scheduling/alarm path can be verified without waiting for a real reminder.
  Future<void> scheduleTestReminderIn({int seconds = 30}) async {
    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        424243,
        'HealthTrackMe scheduled test ✓',
        'Scheduled ${seconds}s ago — scheduling works.',
        when,
        _medicineDetails,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // No matchDateTimeComponents → fires once, not daily.
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint('Exact test alarm failed ($e); retrying inexact');
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e2) {
        debugPrint('Test reminder scheduling failed: $e2');
      }
    }
  }

  // =========================
  // MEDICINE REMINDER
  // =========================

  Future<void> scheduleMedicineReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
    required RepeatInterval repeat,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);

      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id,
        medicineName,
        'Take $dosage',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _medicineChannelId,
            _medicineChannelName,
            channelDescription: _medicineChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _repeatToDateTimeComponents(repeat),
        payload: 'medicine_$id',
      );
    } catch (e) {
      debugPrint('Error scheduling medicine reminder: $e');
    }
  }

  Future<void> cancelMedicineReminder(int id) async {
    await _plugin.cancel(id);
  }

  /// Up to this many distinct reminder times per medicine. Each gets a unique
  /// notification id of `medicineId * 100 + index`, which is collision-free
  /// across medicines as long as this stays below 100.
  static const int _reminderSlotsPerMedicine = 20;

  /// Schedules one daily notification per time in [times] (each 'HH:mm').
  /// Existing reminders for this medicine are cleared first, so this is safe
  /// to call repeatedly (e.g. on every medicines reload).
  Future<void> scheduleMedicineReminders({
    required int medicineId,
    required String medicineName,
    required String dosage,
    required List<String> times,
    int dosesTakenToday = 0,
  }) async {
    await cancelMedicineReminders(medicineId);

    var index = 0;
    for (final raw in times) {
      if (index >= _reminderSlotsPerMedicine) break;
      final parts = raw.trim().split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) continue;

      final slotIndex = index;
      final notifId = medicineId * 100 + index;
      index++;

      final now = tz.TZDateTime.now(tz.local);
      var scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      // Times are sorted, so the first [dosesTakenToday] slots are the doses
      // already taken today — skip those for today and resume tomorrow, so a
      // dose you've already taken doesn't trigger a reminder.
      final alreadyTakenToday = slotIndex < dosesTakenToday;
      if (alreadyTakenToday || scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _zonedScheduleDailyWithFallback(
        id: notifId,
        title: medicineName,
        body: 'Take $dosage',
        when: scheduled,
        payload: 'medicine_$medicineId',
        details: _medicineDetails,
      );
    }
  }

  static const NotificationDetails _medicineDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _medicineChannelId,
      _medicineChannelName,
      channelDescription: _medicineChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Schedule a daily-repeating notification. Tries an exact alarm first; if the
  /// OS denies exact alarms (Android 12+ without the permission granted), falls
  /// back to an inexact one so the reminder still fires (within a few minutes).
  Future<void> _zonedScheduleDailyWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String payload,
    required NotificationDetails details,
  }) async {
    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // daily
        payload: payload,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint('Exact alarm failed for $id ($e); retrying inexact');
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e2) {
        debugPrint('Error scheduling reminder ($id): $e2');
      }
    }
  }

  /// Cancels every reminder slot reserved for [medicineId].
  Future<void> cancelMedicineReminders(int medicineId) async {
    for (var i = 0; i < _reminderSlotsPerMedicine; i++) {
      await _plugin.cancel(medicineId * 100 + i);
    }
  }

  // =========================
  // DAILY DIARY
  // =========================

  static const NotificationDetails _diaryDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _diaryChannelId,
      _diaryChannelName,
      channelDescription: _diaryChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> scheduleDailyDiaryReminder(TimeOfDay time) async {
    const int id = 999999;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _zonedScheduleDailyWithFallback(
      id: id,
      title: 'Daily Health Check',
      body: 'Time to log your health entry',
      when: scheduled,
      payload: 'diary_reminder',
      details: _diaryDetails,
    );
  }

  Future<void> cancelDailyDiaryReminder() async {
    await _plugin.cancel(999999);
  }

  /// Cancels every pending medicine reminder regardless of medicine id — used
  /// by the master "Medicine reminders" toggle when it's switched off.
  Future<void> cancelAllMedicineReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.payload?.startsWith('medicine_') ?? false) {
        await _plugin.cancel(p.id);
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // =========================
  // REPEAT MAPPING (FIXED)
  // =========================

  DateTimeComponents? _repeatToDateTimeComponents(
    RepeatInterval repeat,
  ) {
    switch (repeat) {
      case RepeatInterval.everyMinute:
        return DateTimeComponents.time;

      case RepeatInterval.hourly:
        // Flutter does NOT support true hourly repeating reliably here
        return DateTimeComponents.time;

      case RepeatInterval.daily:
        return DateTimeComponents.time;

      case RepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
    }
  }
}
