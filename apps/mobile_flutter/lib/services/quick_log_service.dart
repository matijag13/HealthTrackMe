import 'package:flutter/material.dart';
import 'api_service.dart';

class QuickLogService {
  final ApiService _api = ApiService.instance;

  Future<bool> logMood(String mood) async {
    try {
      await _api.ensureActiveUserId();

      // In production, you'd have an API endpoint for logging
      // For now, this is a placeholder for the API call
      // await _api.createHealthEntry(entry);

      debugPrint('✅ Mood logged: $mood');
      return true;
    } catch (e) {
      debugPrint('❌ Error logging mood: $e');
      return false;
    }
  }

  Future<bool> logWater(int milliliters) async {
    try {
      await _api.ensureActiveUserId();

      // In production: await _api.createHealthEntry(entry);
      debugPrint('✅ Water logged: ${milliliters}ml');
      return true;
    } catch (e) {
      debugPrint('❌ Error logging water: $e');
      return false;
    }
  }

  Future<bool> logMedication(String medicationName) async {
    try {
      await _api.ensureActiveUserId();

      // In production:
      // Could also update medicine adherence tracking
      // await _api.markMedicationTaken(medicationName, DateTime.now());

      debugPrint('✅ Medication logged: $medicationName');
      return true;
    } catch (e) {
      debugPrint('❌ Error logging medication: $e');
      return false;
    }
  }

  Future<bool> logSymptoms(List<String> symptoms) async {
    try {
      await _api.ensureActiveUserId();

      // In production: await _api.createHealthEntry(entry);
      debugPrint('✅ Symptoms logged: ${symptoms.join(", ")}');
      return true;
    } catch (e) {
      debugPrint('❌ Error logging symptoms: $e');
      return false;
    }
  }

  Future<bool> logSleep(int hours, int minutes) async {
    try {
      await _api.ensureActiveUserId();

      // In production: await _api.createHealthEntry(entry);
      debugPrint('✅ Sleep logged: ${hours}h ${minutes}m');
      return true;
    } catch (e) {
      debugPrint('❌ Error logging sleep: $e');
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
