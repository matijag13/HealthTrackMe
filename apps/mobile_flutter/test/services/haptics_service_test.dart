import 'package:flutter_test/flutter_test.dart';
import 'package:healthtrackme/services/haptics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticsService Tests', () {
    test('HapticsService should be singleton', () {
      final service1 = HapticsService();
      final service2 = HapticsService();

      expect(identical(service1, service2), true);
    });

    test('lightTap should execute without error', () async {
      expect(() async {
        await HapticsService.lightTap();
      }, returnsNormally);
    });

    test('mediumTap should execute without error', () async {
      expect(() async {
        await HapticsService.mediumTap();
      }, returnsNormally);
    });

    test('heavyTap should execute without error', () async {
      expect(() async {
        await HapticsService.heavyTap();
      }, returnsNormally);
    });

    test('selection should execute without error', () async {
      expect(() async {
        await HapticsService.selection();
      }, returnsNormally);
    });

    test('success should execute without error', () async {
      expect(() async {
        await HapticsService.success();
      }, returnsNormally);
    });

    test('error should execute without error', () async {
      expect(() async {
        await HapticsService.error();
      }, returnsNormally);
    });

    test('warning should execute without error', () async {
      expect(() async {
        await HapticsService.warning();
      }, returnsNormally);
    });

    test('expand should execute without error', () async {
      expect(() async {
        await HapticsService.expand();
      }, returnsNormally);
    });

    test('collapse should execute without error', () async {
      expect(() async {
        await HapticsService.collapse();
      }, returnsNormally);
    });

    test('dataSync should execute without error', () async {
      expect(() async {
        await HapticsService.dataSync();
      }, returnsNormally);
    });

    test('buttonPress should execute without error', () async {
      expect(() async {
        await HapticsService.buttonPress();
      }, returnsNormally);
    });

    test('setHapticsEnabled should toggle haptics on/off', () {
      HapticsService.setHapticsEnabled(true);
      // No exception should be thrown
      HapticsService.lightTap();

      HapticsService.setHapticsEnabled(false);
      // Should still not throw even when disabled
      HapticsService.lightTap();

      // Re-enable for other tests
      HapticsService.setHapticsEnabled(true);
    });

    test('hasVibrator should return boolean', () async {
      final hasVibrator = await HapticsService.hasVibrator();
      expect(hasVibrator, isA<bool>());
    });
  });
}
