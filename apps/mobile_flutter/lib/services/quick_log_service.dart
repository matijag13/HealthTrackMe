import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';

class QuickLogService {
  final ApiService _api = ApiService.instance;

  Future<bool> logMood(String mood) async {
    try {
      await _api.ensureActiveUserId();

      final entry = HealthEntry(
        entryDate: DateTime.now(),
        heartRate: null,
        bloodPressure: null,
        bloodSugar: null,
        weight: null,
        sleepHours: null,
        notes: 'Mood: $mood',
      );

      // In production, you'd have an API endpoint for logging
      // For now, this is a placeholder for the API call
      // await _api.createHealthEntry(entry);

      print('✅ Mood logged: $mood');
      return true;
    } catch (e) {
      print('❌ Error logging mood: $e');
      return false;
    }
  }

  Future<bool> logWater(int milliliters) async {
    try {
      await _api.ensureActiveUserId();

      final entry = HealthEntry(
        entryDate: DateTime.now(),
        heartRate: null,
        bloodPressure: null,
        bloodSugar: null,
        weight: null,
        sleepHours: null,
        notes: 'Water intake: ${milliliters}ml',
      );

      // In production: await _api.createHealthEntry(entry);
      print('✅ Water logged: ${milliliters}ml');
      return true;
    } catch (e) {
      print('❌ Error logging water: $e');
      return false;
    }
  }

  Future<bool> logMedication(String medicationName) async {
    try {
      await _api.ensureActiveUserId();

      final entry = HealthEntry(
        entryDate: DateTime.now(),
        heartRate: null,
        bloodPressure: null,
        bloodSugar: null,
        weight: null,
        sleepHours: null,
        notes: 'Medication taken: $medicationName',
      );

      // In production:
      // Could also update medicine adherence tracking
      // await _api.markMedicationTaken(medicationName, DateTime.now());

      print('✅ Medication logged: $medicationName');
      return true;
    } catch (e) {
      print('❌ Error logging medication: $e');
      return false;
    }
  }

  Future<bool> logSymptoms(List<String> symptoms) async {
    try {
      await _api.ensureActiveUserId();

      final entry = HealthEntry(
        entryDate: DateTime.now(),
        heartRate: null,
        bloodPressure: null,
        bloodSugar: null,
        weight: null,
        sleepHours: null,
        notes: 'Symptoms: ${symptoms.join(", ")}',
      );

      // In production: await _api.createHealthEntry(entry);
      print('✅ Symptoms logged: ${symptoms.join(", ")}');
      return true;
    } catch (e) {
      print('❌ Error logging symptoms: $e');
      return false;
    }
  }

  Future<bool> logSleep(int hours, int minutes) async {
    try {
      await _api.ensureActiveUserId();

      final sleepHours = hours + (minutes / 60);
      final entry = HealthEntry(
        entryDate: DateTime.now(),
        heartRate: null,
        bloodPressure: null,
        bloodSugar: null,
        weight: null,
        sleepHours: sleepHours,
        notes: 'Sleep logged: ${hours}h ${minutes}m',
      );

      // In production: await _api.createHealthEntry(entry);
      print('✅ Sleep logged: ${hours}h ${minutes}m');
      return true;
    } catch (e) {
      print('❌ Error logging sleep: $e');
      return false;
    }
  }

  // Helper to show snackbar notification
  static void showLogSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showLogError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
