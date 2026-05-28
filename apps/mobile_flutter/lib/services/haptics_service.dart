import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticsService {
  static final HapticsService _instance = HapticsService._internal();

  factory HapticsService() {
    return _instance;
  }

  HapticsService._internal();

  static bool _hapticsEnabled = true;

  /// Enable/disable all haptic feedback
  static void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Light tap feedback (quick, subtle)
  /// Duration: ~10ms
  static Future<void> lightTap() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Medium tap feedback (noticeable)
  /// Duration: ~20ms
  static Future<void> mediumTap() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Heavy tap feedback (strong)
  /// Duration: ~30ms
  static Future<void> heavyTap() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Selection feedback (change/select)
  /// Used when toggling options
  static Future<void> selection() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Success feedback (completion)
  /// Duration: 2 short taps
  static Future<void> success() async {
    if (!_hapticsEnabled) return;
    try {
      await Vibration.vibrate(duration: 100);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 100);
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Error feedback (failure)
  /// Duration: 3 rapid taps
  static Future<void> error() async {
    if (!_hapticsEnabled) return;
    try {
      await Vibration.vibrate(pattern: [0, 100, 100, 100]);
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Warning feedback (alert)
  /// Duration: 2 longer taps
  static Future<void> warning() async {
    if (!_hapticsEnabled) return;
    try {
      await Vibration.vibrate(pattern: [0, 150, 100, 150]);
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Expansion feedback (menu opens)
  /// Duration: slight rumble
  static Future<void> expand() async {
    if (!_hapticsEnabled) return;
    try {
      await Vibration.vibrate(pattern: [0, 50, 50, 100]);
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Collapse feedback (menu closes)
  /// Duration: quick double tap
  static Future<void> collapse() async {
    if (!_hapticsEnabled) return;
    try {
      await Vibration.vibrate(pattern: [0, 80, 50, 80]);
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Button press feedback (generic button)
  static Future<void> buttonPress() async {
    if (!_hapticsEnabled) return;
    await lightTap();
  }

  /// Data sync feedback (background sync)
  static Future<void> dataSync() async {
    if (!_hapticsEnabled) return;
    try {
      await Vibration.vibrate(pattern: [0, 60, 40, 60, 40, 60]);
    } catch (e) {
      debugPrint('⚠️ Haptic feedback error: $e');
    }
  }

  /// Check if device supports haptics
  static Future<bool> hasVibrator() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      return hasVibrator;
    } catch (e) {
      debugPrint('⚠️ Error checking vibrator: $e');
      return false;
    }
  }
}
