import 'package:flutter_test/flutter_test.dart';
import 'package:healthtrackme/models/wearable_device.dart';

void main() {
  group('WearableDevice Model Tests', () {
    const mockDeviceJson = {
      'id': 1,
      'deviceName': 'Apple Watch',
      'deviceType': 'appleWatch',
      'deviceId': 'watch-001',
      'serialNumber': 'ABC123',
      'connectedAt': '2026-05-20T10:00:00.000Z',
      'lastSyncTime': '2026-05-28T10:30:00.000Z',
      'syncStatus': 'synced',
      'isActive': true,
    };

    test('WearableDevice.fromJson should parse correctly', () {
      final device = WearableDevice.fromJson(mockDeviceJson);

      expect(device.id, 1);
      expect(device.name, 'Apple Watch');
      expect(device.type, WearableDeviceType.appleWatch);
      expect(device.deviceId, 'watch-001');
      expect(device.syncStatus, SyncStatus.synced);
      expect(device.isActive, true);
    });

    test('WearableDevice.toJson should serialize correctly', () {
      final device = WearableDevice.fromJson(mockDeviceJson);
      final json = device.toJson();

      expect(json['id'], 1);
      expect(json['deviceName'], 'Apple Watch');
      expect(json['deviceType'], 'appleWatch');
    });

    test('Device type should have correct display names', () {
      expect(WearableDeviceType.appleWatch.displayName, 'Apple Watch');
      expect(WearableDeviceType.fitbit.displayName, 'Fitbit');
      expect(WearableDeviceType.garmin.displayName, 'Garmin');
      expect(WearableDeviceType.oura.displayName, 'Oura Ring');
      expect(WearableDeviceType.whoop.displayName, 'WHOOP');
    });

    test('Device type should have correct emojis', () {
      expect(WearableDeviceType.appleWatch.emoji, '⌚');
      expect(WearableDeviceType.oura.emoji, '💍');
      expect(WearableDeviceType.googleFit.emoji, '📊');
    });

    test('Sync status should have correct labels', () {
      expect(SyncStatus.synced.label, 'Synced');
      expect(SyncStatus.syncing.label, 'Syncing...');
      expect(SyncStatus.failed.label, 'Sync Failed');
      expect(SyncStatus.paused.label, 'Paused');
      expect(SyncStatus.notConnected.label, 'Not Connected');
    });

    test('lastSyncLabel should calculate time correctly', () {
      final device = WearableDevice.fromJson(mockDeviceJson);
      expect(device.lastSyncLabel, isNotEmpty);
    });

    test('needsSync should return true if sync overdue', () {
      final oldSync = DateTime.now().subtract(const Duration(hours: 2));
      final device = WearableDevice(
        id: 1,
        name: 'Watch',
        type: WearableDeviceType.appleWatch,
        deviceId: 'test',
        connectedAt: DateTime.now(),
        lastSyncAt: oldSync,
      );

      expect(device.needsSync, true);
    });

    test('needsSync should return false if recently synced', () {
      final recentSync = DateTime.now().subtract(const Duration(minutes: 30));
      final device = WearableDevice(
        id: 1,
        name: 'Watch',
        type: WearableDeviceType.appleWatch,
        deviceId: 'test',
        connectedAt: DateTime.now(),
        lastSyncAt: recentSync,
      );

      expect(device.needsSync, false);
    });

    test('needsSync should return true if never synced', () {
      final device = WearableDevice(
        id: 1,
        name: 'Watch',
        type: WearableDeviceType.appleWatch,
        deviceId: 'test',
        connectedAt: DateTime.now(),
      );

      expect(device.needsSync, true);
    });
  });

  group('WearableSyncData Tests', () {
    const mockSyncJson = {
      'date': '2026-05-28T10:30:00.000Z',
      'steps': 8500,
      'activeMinutes': 45,
      'calories': 2400,
      'heartRateAvg': 72.5,
      'heartRateMax': 120,
      'heartRateMin': 55,
      'sleepHours': 7.5,
      'sleepQuality': 'GOOD',
    };

    test('WearableSyncData.fromJson should parse correctly', () {
      final data = WearableSyncData.fromJson(mockSyncJson);

      expect(data.steps, 8500);
      expect(data.heartRateAvg, 72.5);
      expect(data.sleepHours, 7.5);
      expect(data.sleepQuality, 'GOOD');
    });

    test('WearableSyncData.toJson should serialize correctly', () {
      final data = WearableSyncData.fromJson(mockSyncJson);
      final json = data.toJson();

      expect(json['steps'], 8500);
      expect(json['heartRateAvg'], 72.5);
    });

    test('hasData should return true when data is present', () {
      final data = WearableSyncData.fromJson(mockSyncJson);
      expect(data.hasData, true);
    });

    test('hasData should return false when no data', () {
      final data = WearableSyncData(
        date: DateTime.now(),
      );
      expect(data.hasData, false);
    });
  });

  group('SyncEvent Tests', () {
    const mockEventJson = {
      'id': 1,
      'deviceName': 'Apple Watch',
      'deviceType': 'appleWatch',
      'syncTime': '2026-05-28T10:30:00.000Z',
      'success': true,
      'recordsSync': 15,
    };

    test('SyncEvent.fromJson should parse correctly', () {
      final event = SyncEvent.fromJson(mockEventJson);

      expect(event.id, 1);
      expect(event.deviceName, 'Apple Watch');
      expect(event.success, true);
      expect(event.recordsSync, 15);
      expect(event.status, 'Synced');
      expect(event.statusEmoji, '✅');
    });

    test('SyncEvent should show error status for failed sync', () {
      final failedJson = {
        ...mockEventJson,
        'success': false,
        'errorMessage': 'Connection timeout',
      };

      final event = SyncEvent.fromJson(failedJson);
      expect(event.status, 'Failed');
      expect(event.statusEmoji, '❌');
      expect(event.errorMessage, 'Connection timeout');
    });
  });
}
