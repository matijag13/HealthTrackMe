import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/wearable_device.dart';
import '../services/api_service.dart';
import '../services/wearable_service.dart';

class WearablesScreen extends StatefulWidget {
  const WearablesScreen({super.key});

  @override
  State<WearablesScreen> createState() => _WearablesScreenState();
}

class _WearablesScreenState extends State<WearablesScreen> {
  final WearableService _wearableService = WearableService();
  final ApiService _api = ApiService.instance;

  List<WearableDevice> _devices = [];
  List<SyncEvent> _syncHistory = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadWearableData();
  }

  Future<void> _loadWearableData() async {
    setState(() => _loading = true);

    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }

      final devices = await _wearableService.getConnectedDevices(userId);
      final history = await _wearableService.getSyncHistory(userId);

      setState(() {
        _devices = devices;
        _syncHistory = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _requestAndSyncHealthData() async {
    final hasPermission = await _wearableService.hasPermissions();

    if (!hasPermission) {
      final granted = await _wearableService.requestPermissions();
      if (!granted) {
        if (mounted) {
          WearableService.showSyncStatus(
            context,
            'Health permissions are required for syncing',
            false,
          );
        }
        return;
      }
    }

    setState(() => _syncing = true);

    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) {
        if (mounted) {
          WearableService.showSyncStatus(
            context,
            'No active user selected',
            false,
          );
        }
        return;
      }

      // Sync data from past 7 days
      final startDate = DateTime.now().subtract(const Duration(days: 7));
      await _wearableService.syncWearableData(
        userId: userId,
        startDate: startDate,
      );

      if (mounted) {
        WearableService.showSyncStatus(
          context,
          '✅ Health data synced successfully!',
          true,
        );
      }

      // Reload data
      await _loadWearableData();
    } catch (e) {
      if (mounted) {
        WearableService.showSyncStatus(
          context,
          'Failed to sync health data',
          false,
        );
      }
    } finally {
      setState(() => _syncing = false);
    }
  }

  Future<void> _addDevice() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildAddDeviceSheet(),
    );
  }

  Future<void> _disconnectDevice(WearableDevice device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Device?'),
        content: Text('Do you want to disconnect ${device.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _wearableService.disconnectDevice(device.id);

      if (mounted) {
        WearableService.showSyncStatus(
          context,
          success
              ? '${device.name} disconnected'
              : 'Failed to disconnect device',
          success,
        );

        if (success) {
          await _loadWearableData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        title: const Text('Wearable Devices'),
        actions: [
          IconButton(
            onPressed: _loadWearableData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWearableData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick sync button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _syncing ? null : _requestAndSyncHealthData,
                  icon: _syncing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.sync_alt),
                  label: Text(_syncing ? 'Syncing...' : 'Sync Health Data'),
                ),
              ),
              const SizedBox(height: 24),

              // Connected Devices Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Connected Devices',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  GestureDetector(
                    onTap: _addDevice,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Devices List
              if (_devices.isEmpty)
                _buildEmptyState(isDark)
              else
                ..._buildDevicesList(isDark),

              const SizedBox(height: 24),

              // Sync History
              if (_syncHistory.isNotEmpty) ...[
                Text(
                  'Sync History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ..._buildSyncHistory(isDark),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.watch_later_outlined,
            size: 48,
            color: AppColors.primaryBlue.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Devices Connected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect a wearable device to automatically sync health data',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addDevice,
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDevicesList(bool isDark) {
    return _devices.map((device) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        device.type.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          device.type.displayName,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getSyncStatusColor(device.syncStatus)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${device.syncStatus.emoji} ${device.syncStatus.label}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getSyncStatusColor(device.syncStatus),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Sync',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                      ),
                      Text(
                        device.lastSyncLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Connected',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                      ),
                      Text(
                        device.connectedDuration,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _disconnectDevice(device),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Disconnect'),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSyncHistory(bool isDark) {
    return _syncHistory.take(5).map((event) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                event.statusEmoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.deviceName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      event.status,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatSyncTime(event.syncTime),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAddDeviceSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Wearable Device',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WearableDeviceType.values.map((type) {
              return GestureDetector(
                onTap: () => _confirmAddDevice(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryBlue,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        type.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(type.displayName),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _confirmAddDevice(WearableDeviceType type) {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${type.displayName}?'),
        content: Text(
          'This will enable automatic syncing of health data from ${type.displayName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addNewDevice(type);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewDevice(WearableDeviceType type) async {
    try {
      final userId = await _api.ensureActiveUserId();
      if (userId == null) {
        if (mounted) {
          WearableService.showSyncStatus(
            context,
            'No active user selected',
            false,
          );
        }
        return;
      }

      final device = await _wearableService.addDevice(
        userId,
        type.displayName,
        type,
      );

      if (mounted) {
        WearableService.showSyncStatus(
          context,
          '${device.name} added successfully!',
          true,
        );
      }

      await _loadWearableData();
    } catch (e) {
      if (mounted) {
        WearableService.showSyncStatus(
          context,
          'Failed to add device',
          false,
        );
      }
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return AppColors.primaryGreen;
      case SyncStatus.syncing:
        return AppColors.primaryBlue;
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.paused:
        return AppColors.primaryOrange;
      case SyncStatus.notConnected:
        return Colors.grey;
    }
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
