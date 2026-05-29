enum WearableDeviceType {
  appleWatch,
  fitbit,
  garmin,
  oura,
  whoop,
  samsung,
  googleFit,
  other;

  String get displayName {
    switch (this) {
      case WearableDeviceType.appleWatch:
        return 'Apple Watch';
      case WearableDeviceType.fitbit:
        return 'Fitbit';
      case WearableDeviceType.garmin:
        return 'Garmin';
      case WearableDeviceType.oura:
        return 'Oura Ring';
      case WearableDeviceType.whoop:
        return 'WHOOP';
      case WearableDeviceType.samsung:
        return 'Samsung Galaxy';
      case WearableDeviceType.googleFit:
        return 'Google Fit';
      case WearableDeviceType.other:
        return 'Other Device';
    }
  }

  String get emoji {
    switch (this) {
      case WearableDeviceType.appleWatch:
        return '⌚';
      case WearableDeviceType.fitbit:
        return '📱';
      case WearableDeviceType.garmin:
        return '⌚';
      case WearableDeviceType.oura:
        return '💍';
      case WearableDeviceType.whoop:
        return '📌';
      case WearableDeviceType.samsung:
        return '⌚';
      case WearableDeviceType.googleFit:
        return '📊';
      case WearableDeviceType.other:
        return '📱';
    }
  }
}

enum SyncStatus {
  synced,
  syncing,
  failed,
  paused,
  notConnected;

  String get label {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.failed:
        return 'Sync Failed';
      case SyncStatus.paused:
        return 'Paused';
      case SyncStatus.notConnected:
        return 'Not Connected';
    }
  }

  String get emoji {
    switch (this) {
      case SyncStatus.synced:
        return '✅';
      case SyncStatus.syncing:
        return '⟳';
      case SyncStatus.failed:
        return '❌';
      case SyncStatus.paused:
        return '⏸️';
      case SyncStatus.notConnected:
        return '⭕';
    }
  }
}

class WearableDevice {
  final int id;
  final String name;
  final WearableDeviceType type;
  final String deviceId;
  final String? serialNumber;
  final DateTime connectedAt;
  final DateTime? lastSyncAt;
  final SyncStatus syncStatus;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  WearableDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.deviceId,
    this.serialNumber,
    required this.connectedAt,
    this.lastSyncAt,
    this.syncStatus = SyncStatus.notConnected,
    this.isActive = true,
    this.metadata,
  });

  /// Time since last sync
  String get lastSyncLabel {
    if (lastSyncAt == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSyncAt!);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }

  /// Time since connection
  String get connectedDuration {
    final now = DateTime.now();
    final diff = now.difference(connectedAt);

    if (diff.inDays == 0) {
      return 'Connected today';
    }
    if (diff.inDays == 1) {
      return 'Connected yesterday';
    }
    return 'Connected ${diff.inDays}d ago';
  }

  bool get needsSync =>
      lastSyncAt == null || DateTime.now().difference(lastSyncAt!).inHours >= 1;

  factory WearableDevice.fromJson(Map<String, dynamic> json) {
    return WearableDevice(
      id: json['id'] as int? ?? 0,
      name: json['deviceName'] as String? ?? 'Unknown',
      type: _parseDeviceType(json['deviceType'] as String? ?? 'other'),
      deviceId: json['deviceId'] as String? ?? '',
      serialNumber: json['serialNumber'] as String?,
      connectedAt: DateTime.tryParse(json['connectedAt'] as String? ?? '') ??
          DateTime.now(),
      lastSyncAt: DateTime.tryParse(json['lastSyncTime'] as String? ?? ''),
      syncStatus:
          _parseSyncStatus(json['syncStatus'] as String? ?? 'notConnected'),
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': name,
      'deviceType': type.toString().split('.').last,
      'deviceId': deviceId,
      'serialNumber': serialNumber,
      'connectedAt': connectedAt.toIso8601String(),
      'lastSyncTime': lastSyncAt?.toIso8601String(),
      'syncStatus': syncStatus.toString().split('.').last,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  static WearableDeviceType _parseDeviceType(String type) {
    try {
      return WearableDeviceType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == type.toLowerCase(),
        orElse: () => WearableDeviceType.other,
      );
    } catch (e) {
      return WearableDeviceType.other;
    }
  }

  static SyncStatus _parseSyncStatus(String status) {
    try {
      return SyncStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status.toLowerCase(),
        orElse: () => SyncStatus.notConnected,
      );
    } catch (e) {
      return SyncStatus.notConnected;
    }
  }
}

class WearableSyncData {
  final DateTime date;
  final int? steps;
  final int? activeMinutes;
  final int? calories;
  final double? heartRateAvg;
  final int? heartRateMax;
  final int? heartRateMin;
  final double? sleepHours;
  final String? sleepQuality;
  final Map<String, dynamic>? rawData;

  WearableSyncData({
    required this.date,
    this.steps,
    this.activeMinutes,
    this.calories,
    this.heartRateAvg,
    this.heartRateMax,
    this.heartRateMin,
    this.sleepHours,
    this.sleepQuality,
    this.rawData,
  });

  bool get hasData =>
      steps != null ||
      activeMinutes != null ||
      calories != null ||
      heartRateAvg != null ||
      sleepHours != null;

  factory WearableSyncData.fromJson(Map<String, dynamic> json) {
    return WearableSyncData(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      steps: json['steps'] as int?,
      activeMinutes: json['activeMinutes'] as int?,
      calories: json['calories'] as int?,
      heartRateAvg: (json['heartRateAvg'] as num?)?.toDouble(),
      heartRateMax: json['heartRateMax'] as int?,
      heartRateMin: json['heartRateMin'] as int?,
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      sleepQuality: json['sleepQuality'] as String?,
      rawData: json['rawData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'activeMinutes': activeMinutes,
      'calories': calories,
      'heartRateAvg': heartRateAvg,
      'heartRateMax': heartRateMax,
      'heartRateMin': heartRateMin,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'rawData': rawData,
    };
  }
}

class SyncEvent {
  final int id;
  final String deviceName;
  final WearableDeviceType deviceType;
  final DateTime syncTime;
  final bool success;
  final int? recordsSync;
  final String? errorMessage;

  SyncEvent({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.syncTime,
    required this.success,
    this.recordsSync,
    this.errorMessage,
  });

  String get status => success ? 'Synced' : 'Failed';
  String get statusEmoji => success ? '✅' : '❌';

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      id: json['id'] as int? ?? 0,
      deviceName: json['deviceName'] as String? ?? 'Unknown',
      deviceType: WearableDevice._parseDeviceType(
          json['deviceType'] as String? ?? 'other'),
      syncTime: DateTime.tryParse(json['syncTime'] as String? ?? '') ??
          DateTime.now(),
      success: json['success'] as bool? ?? false,
      recordsSync: json['recordsSync'] as int?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
