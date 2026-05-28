import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    // The timezone package automatically uses the device's configured timezone
    // after tz_data.initializeTimeZones() is called. tz.local will reflect the
    // device's local timezone (e.g., Europe/London if the phone is set to that timezone).

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
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
        NotificationDetails(
          android: AndroidNotificationDetails(
            _medicineChannelId,
            _medicineChannelName,
            channelDescription: _medicineChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
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

  // =========================
  // DAILY DIARY
  // =========================

  Future<void> scheduleDailyDiaryReminder(TimeOfDay time) async {
    const int id = 999999;

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
        'Daily Health Check',
        'Time to log your health entry',
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _diaryChannelId,
            _diaryChannelName,
            channelDescription: _diaryChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'diary_reminder',
      );
    } catch (e) {
      debugPrint('Error scheduling diary reminder: $e');
    }
  }

  Future<void> cancelDailyDiaryReminder() async {
    await _plugin.cancel(999999);
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
