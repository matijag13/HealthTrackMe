import 'package:flutter/material.dart';
import '../models/wearable_device.dart';
import '../services/api_service.dart';
import '../services/wearable_service.dart';

class WearablesScreen extends StatefulWidget {
  const WearablesScreen({super.key});

  @override
  State<WearablesScreen> createState() => _WearablesScreenState();
}

class _WearablesScreenState extends State<WearablesScreen> {
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _green = Color(0xFF36D399);
  static const _danger = Color(0xFFFF5C7A);

  final WearableService _wearableService = WearableService();
  final ApiService _api = ApiService.instance;

  List<WearableDevice> _devices = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = await _api.ensureActiveUserId();
      if (userId != null) {
        final devices = await _wearableService.getConnectedDevices(userId);
        if (mounted) setState(() => _devices = devices);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final userId = await _api.ensureActiveUserId();
      if (userId != null) {
        final hasPermission = await _wearableService.hasPermissions();
        if (!hasPermission) {
          final granted = await _wearableService.requestPermissions();
          if (!granted) {
            if (mounted) _showStatus('Health permissions denied', false);
            return;
          }
        }
        final result = await _wearableService.syncWearableData(
          userId: userId,
          startDate: DateTime.now().subtract(const Duration(days: 730)),
        );
        await _load();
        if (mounted) {
          final parts = <String>[];
          if (result.steps != null) parts.add('${result.steps} steps');
          if (result.heartRateAvg != null) {
            parts.add('HR ${result.heartRateAvg!.toInt()} bpm');
          }
          if (result.sleepHours != null) {
            parts.add('${result.sleepHours!.toStringAsFixed(1)}h sleep');
          }
          if (result.calories != null) {
            parts.add('${result.calories} kcal');
          }
          final msg = parts.isEmpty
              ? 'Sync complete — no new data found'
              : 'Synced: ${parts.join(', ')}';
          _showStatus(msg, parts.isNotEmpty);
        }
      }
    } catch (e) {
      if (mounted) _showStatus('Sync failed', false);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _addDevice() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: _border),
      ),
      builder: (_) => _AddDeviceSheet(
        onAdd: (type) async {
          Navigator.pop(context);
          try {
            final userId = await _api.ensureActiveUserId();
            if (userId != null) {
              await _wearableService.addDevice(userId, type.displayName, type);
              await _load();
              if (mounted) _showStatus('${type.displayName} added', true);
            }
          } catch (e) {
            if (mounted) _showStatus('Failed to add device', false);
          }
        },
      ),
    );
  }

  Future<void> _removeDevice(WearableDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
        title:
            const Text('Remove device', style: TextStyle(color: _primaryText)),
        content: Text('Remove ${device.name}?',
            style: const TextStyle(color: _secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: _secondaryText)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _wearableService.disconnectDevice(device.id);
      await _load();
      if (mounted) _showStatus('${device.name} removed', true);
    }
  }

  void _showStatus(String message, bool success) {
    final accent = success ? _green : _danger;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
        content: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        success
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: accent,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wearable Devices',
          style: TextStyle(
            color: _primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : RefreshIndicator(
              color: _accent,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Sync button
                  _SyncButton(syncing: _syncing, onSync: _sync),
                  const SizedBox(height: 24),

                  // Devices section
                  const Text(
                    'CONNECTED DEVICES',
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_devices.isEmpty)
                    _EmptyDevices(onAdd: _addDevice)
                  else
                    ..._devices.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DeviceCard(
                            device: d,
                            onRemove: () => _removeDevice(d),
                          ),
                        )),
                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: _accent, size: 16),
                          SizedBox(width: 8),
                          Text('How syncing works',
                              style: TextStyle(
                                  color: _primaryText,
                                  fontWeight: FontWeight.w700)),
                        ]),
                        SizedBox(height: 8),
                        Text(
                          'Tap "Sync Health Data" to pull the last 7 days from Samsung Health or Google Fit via Health Connect. Make sure Samsung Health is set to sync with Health Connect in its settings.',
                          style: TextStyle(
                              color: _secondaryText, height: 1.5, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  final bool syncing;
  final VoidCallback onSync;

  const _SyncButton({required this.syncing, required this.onSync});

  static const _accent = Color(0xFF5B8DEF);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: syncing ? null : onSync,
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: syncing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.sync_rounded, color: Colors.white),
        label: Text(
          syncing ? 'Syncing...' : 'Sync Health Data',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyDevices({required this.onAdd});

  static const _surface = Color(0xFF0F1624);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(Icons.watch_outlined, size: 48, color: _secondaryText),
          const SizedBox(height: 16),
          const Text('No devices connected',
              style: TextStyle(
                  color: _primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Add your wearable to track which device your data comes from',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText, height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Device',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

IconData _wearableDeviceIcon(WearableDeviceType type) {
  switch (type) {
    case WearableDeviceType.appleWatch:
    case WearableDeviceType.garmin:
    case WearableDeviceType.samsung:
      return Icons.watch_outlined;
    case WearableDeviceType.fitbit:
      return Icons.smartphone_rounded;
    case WearableDeviceType.oura:
      return Icons.circle_outlined;
    case WearableDeviceType.whoop:
      return Icons.sensors_rounded;
    case WearableDeviceType.googleFit:
      return Icons.bar_chart_rounded;
    case WearableDeviceType.other:
      return Icons.devices_other_rounded;
  }
}

class _DeviceCard extends StatelessWidget {
  final WearableDevice device;
  final VoidCallback onRemove;

  const _DeviceCard({required this.device, required this.onRemove});

  static const _surface = Color(0xFF0F1624);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _danger = Color(0xFFFF5C7A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Icon(
                _wearableDeviceIcon(device.type),
                color: _accent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name,
                    style: const TextStyle(
                        color: _primaryText, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(device.type.displayName,
                    style:
                        const TextStyle(color: _secondaryText, fontSize: 12)),
                const SizedBox(height: 2),
                Text(device.lastSyncLabel,
                    style:
                        const TextStyle(color: _secondaryText, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: _danger),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddDeviceSheet extends StatelessWidget {
  final void Function(WearableDeviceType) onAdd;

  const _AddDeviceSheet({required this.onAdd});

  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _secondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Add Wearable Device',
              style: TextStyle(
                  color: _primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Select the type of device to register',
              style: TextStyle(color: _secondaryText, fontSize: 13)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: WearableDeviceType.values.map((type) {
              return GestureDetector(
                onTap: () => onAdd(type),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _wearableDeviceIcon(type),
                        color: _primaryText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(type.displayName,
                          style: const TextStyle(
                              color: _primaryText,
                              fontWeight: FontWeight.w600)),
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
}
