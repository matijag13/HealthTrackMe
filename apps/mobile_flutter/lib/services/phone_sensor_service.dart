import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records step data straight from the phone's hardware step counter, so the
/// app doesn't depend on Samsung Health / a wearable for steps.
///
/// The hardware counter (`Pedometer.stepCountStream`) is cumulative since the
/// device booted, and keeps counting at near-zero battery even while the app is
/// closed. We track a per-day accumulator, handle reboots (counter resets to 0),
/// and write the new steps into Health Connect. The rest of the pipeline
/// (Health Connect → backend → dashboard) then picks them up unchanged.
class PhoneSensorService {
  PhoneSensorService._();
  static final PhoneSensorService instance = PhoneSensorService._();

  final Health _health = Health();

  static const _kDate = 'phone_steps_date';
  static const _kAccum = 'phone_steps_accum'; // steps accumulated today
  static const _kLastCumulative = 'phone_steps_last_cumulative';
  static const _kHcWritten =
      'phone_steps_hc_written'; // steps written to HC today
  static const _kHcLastWriteMs = 'phone_steps_hc_last_write_ms';

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// One-shot read of the cumulative step count from the sensor.
  Future<int?> _readCumulative() async {
    if (kIsWeb) return null;
    try {
      final event = await Pedometer.stepCountStream.first
          .timeout(const Duration(seconds: 6));
      return event.steps;
    } catch (e) {
      debugPrint('Pedometer read failed: $e');
      return null;
    }
  }

  /// Updates today's accumulated step total from the sensor and returns it.
  /// Returns null when the sensor isn't available/permitted.
  Future<int?> updateTodaySteps() async {
    final cumulative = await _readCumulative();
    if (cumulative == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_kDate);
    var accum = prefs.getInt(_kAccum) ?? 0;
    var lastCumulative = prefs.getInt(_kLastCumulative) ?? cumulative;

    if (storedDate != today) {
      // New day — reset the accumulator and HC bookkeeping.
      accum = 0;
      lastCumulative = cumulative;
      await prefs.setString(_kDate, today);
      await prefs.setInt(_kHcWritten, 0);
      await prefs.remove(_kHcLastWriteMs);
    }

    var delta = cumulative - lastCumulative;
    if (delta < 0) delta = cumulative; // reboot: counter reset to 0
    accum += delta;
    lastCumulative = cumulative;

    await prefs.setInt(_kAccum, accum);
    await prefs.setInt(_kLastCumulative, lastCumulative);
    return accum;
  }

  /// Today's accumulated steps (without touching the sensor).
  Future<int> todaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kDate) != _todayKey()) return 0;
    return prefs.getInt(_kAccum) ?? 0;
  }

  /// Writes the steps gained since the last Health Connect write as a STEPS
  /// record over the elapsed interval. Best-effort.
  Future<void> _writeNewStepsToHealthConnect(int totalToday) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final written = prefs.getInt(_kHcWritten) ?? 0;
      final delta = totalToday - written;
      if (delta <= 0) return;

      final now = DateTime.now();
      final lastMs = prefs.getInt(_kHcLastWriteMs);
      final start = lastMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMs)
          : DateTime(now.year, now.month, now.day);
      // Guard against a zero/negative window.
      final safeStart = start.isBefore(now)
          ? start
          : now.subtract(const Duration(minutes: 1));

      final ok = await _health.writeHealthData(
        value: delta.toDouble(),
        type: HealthDataType.STEPS,
        startTime: safeStart,
        endTime: now,
        recordingMethod: RecordingMethod.automatic,
      );
      if (ok) {
        await prefs.setInt(_kHcWritten, totalToday);
        await prefs.setInt(_kHcLastWriteMs, now.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('Health Connect step write failed: $e');
    }
  }

  /// Reads the sensor, updates today's total, and writes the new steps into
  /// Health Connect. Returns today's step total (or null if unavailable).
  Future<int?> recordSteps({bool writeToHealthConnect = true}) async {
    final total = await updateTodaySteps();
    if (total == null) return null;
    if (writeToHealthConnect) await _writeNewStepsToHealthConnect(total);
    return total;
  }
}
