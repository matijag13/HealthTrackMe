import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _streakChannelId = 'streak_reminders';
  static const String _streakChannelName = 'Streak Reminders';
  static const String _streakChannelDesc =
      'Morning nudge to keep your logging streak alive';

  static const String _activityChannelId = 'auto_activity';
  static const String _activityChannelName = 'Auto-detected Activities';
  static const String _activityChannelDesc =
      'Notification when a walk or run is automatically logged';
  static const String _localeKey = 'healthtrackme_locale';

  Future<String> _languageCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    return code == 'sl' ? 'sl' : 'en';
  }

  Future<bool> _isSlovenian() async => await _languageCode() == 'sl';

  NotificationDetails _medicineDetailsFor(bool sl) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _medicineChannelId,
        sl ? 'Opomniki za odmerke zdravil' : _medicineChannelName,
        channelDescription:
            sl ? 'Opomniki za odmerke zdravil' : _medicineChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  NotificationDetails _diaryDetailsFor(bool sl) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _diaryChannelId,
        sl ? 'Dnevni opomniki za dnevnik' : _diaryChannelName,
        channelDescription: sl
            ? 'Dnevni opomnik za beleženje zdravstvenega vnosa'
            : _diaryChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  NotificationDetails _streakDetailsFor(bool sl) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _streakChannelId,
        sl ? 'Opomniki za niz' : _streakChannelName,
        channelDescription: sl
            ? 'Jutranji opomnik za ohranjanje niza beleženja'
            : _streakChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  NotificationDetails _activityDetailsFor(bool sl) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _activityChannelId,
        sl ? 'Samodejno zaznane aktivnosti' : _activityChannelName,
        channelDescription: sl
            ? 'Obvestilo, ko je hoja ali tek samodejno zabeležen'
            : _activityChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

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
    final sl = await _isSlovenian();
    await _plugin.show(
      424242,
      'HealthTrackMe test ✓',
      sl
          ? 'Če vidiš to obvestilo, obvestila delujejo. Opomniki uporabljajo isti kanal.'
          : 'If you can see this, notifications work. Reminders use the same channel.',
      _medicineDetailsFor(sl),
    );
  }

  /// Schedules a one-off test reminder [seconds] from now (default 30s), so the
  /// scheduling/alarm path can be verified without waiting for a real reminder.
  Future<void> scheduleTestReminderIn({int seconds = 30}) async {
    final sl = await _isSlovenian();
    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        424243,
        sl
            ? 'Načrtovani test HealthTrackMe ✓'
            : 'HealthTrackMe scheduled test ✓',
        sl
            ? 'Načrtovano pred ${seconds}s — razporejanje deluje.'
            : 'Scheduled ${seconds}s ago — scheduling works.',
        when,
        _medicineDetailsFor(sl),
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
      final sl = await _isSlovenian();
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
        sl ? 'Vzemi $dosage' : 'Take $dosage',
        scheduled,
        _medicineDetailsFor(sl),
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
    final sl = await _isSlovenian();

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
        body: sl ? 'Vzemi $dosage' : 'Take $dosage',
        when: scheduled,
        payload: 'medicine_$medicineId',
        details: _medicineDetailsFor(sl),
      );
    }
  }

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

  Future<void> scheduleDailyDiaryReminder(TimeOfDay time) async {
    final sl = await _isSlovenian();
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
      title: sl ? 'Dnevni zdravstveni pregled' : 'Daily Health Check',
      body: sl
          ? 'Čas je za beleženje zdravstvenega vnosa'
          : 'Time to log your health entry',
      when: scheduled,
      payload: 'diary_reminder',
      details: _diaryDetailsFor(sl),
    );
  }

  Future<void> cancelDailyDiaryReminder() async {
    await _plugin.cancel(999999);
  }

  // =========================
  // STREAK MORNING REMINDER
  // =========================

  static const int _streakReminderId = 999998;

  /// Schedules a daily morning nudge to log today and keep the streak alive.
  Future<void> scheduleDailyStreakReminder(TimeOfDay time) async {
    final sl = await _isSlovenian();
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
      id: _streakReminderId,
      title: sl ? 'Dobro jutro! ☀️' : 'Good morning! ☀️',
      body: sl
          ? 'Zabeleži spanje in vitalne znake, da ohraniš svoj niz.'
          : 'Log your sleep & vitals to keep your streak alive.',
      when: scheduled,
      payload: 'streak_reminder',
      details: _streakDetailsFor(sl),
    );
  }

  Future<void> cancelDailyStreakReminder() async {
    await _plugin.cancel(_streakReminderId);
  }

  // =========================
  // AUTO-DETECTED ACTIVITY
  // =========================

  static const int _activityNotifId = 777777;

  /// Shows an immediate notification confirming an auto-detected walk/run was
  /// logged. [distanceKm] is the GPS-adjusted distance, [steps] the final count.
  Future<void> showAutoActivityNotification({
    required String type, // 'Walk' or 'Run'
    required int durationMin,
    required double distanceKm,
    required int steps,
  }) async {
    if (kIsWeb) return;
    final sl = await _isSlovenian();
    final emoji = type == 'Run' ? '🏃' : '🚶';
    final typeLabel = sl ? (type == 'Run' ? 'Tek' : 'Hoja') : type;
    final distStr = distanceKm >= 0.1
        ? '${distanceKm.toStringAsFixed(1)} km'
        : '${(distanceKm * 1000).round()} m';
    try {
      await _plugin.show(
        _activityNotifId,
        sl ? '$emoji $typeLabel zabeležena' : '$emoji $typeLabel logged',
        sl
            ? '$durationMin min · $distStr · $steps korakov'
            : '$durationMin min · $distStr · $steps steps',
        _activityDetailsFor(sl),
        payload: 'auto_activity',
      );
    } catch (e) {
      debugPrint('Auto-activity notification failed: $e');
    }
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
