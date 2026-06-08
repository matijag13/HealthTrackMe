import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// Surfaces the health alerts the backend raises from trend analysis (high
/// stress, low/high sleep, low energy, recurring symptoms). The data + endpoints
/// already existed; this screen is the missing surface. Tapping an alert marks
/// it read.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _api = ApiService.instance;
  late Future<List<HealthAlertSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<HealthAlertSummary>> _load() => _api.getHealthAlerts();

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _markRead(HealthAlertSummary alert) async {
    if (alert.isRead) return;
    final ok = await _api.markAlertRead(alert.id);
    if (ok) {
      await _refresh();
    }
  }

  Future<void> _markAllRead(List<HealthAlertSummary> alerts) async {
    final unread = alerts.where((a) => !a.isRead).toList();
    if (unread.isEmpty) return;
    await Future.wait(unread.map((a) => _api.markAlertRead(a.id)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health alerts'),
        actions: [
          FutureBuilder<List<HealthAlertSummary>>(
            future: _future,
            builder: (context, snap) {
              final data = snap.data ?? const <HealthAlertSummary>[];
              final hasUnread = data.any((a) => !a.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllRead(data),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HealthAlertSummary>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final alerts = snap.data ?? const <HealthAlertSummary>[];
            if (alerts.isEmpty) {
              return _emptyState(context);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _AlertCard(
                alert: alerts[i],
                onTap: () => _markRead(alerts[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.verified_outlined,
            size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(height: 16),
        Center(
          child:
              Text('No alerts — all clear', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "We'll flag things like unusually low sleep, high stress, or recurring symptoms here.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final HealthAlertSummary alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  Color _severityColor() {
    switch (alert.severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return const Color(0xFFE25555);
      case 'MEDIUM':
        return const Color(0xFFD9933A);
      default:
        return const Color(0xFF5B8DEF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor();
    final unread = !alert.isRead;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread
                  ? color.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5, right: 12),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _relativeTime(alert.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(alert.message, style: theme.textTheme.bodySmall),
                    if (alert.actionRequired != null &&
                        alert.actionRequired!.isNotEmpty &&
                        alert.actionRequired != 'VISIT_DOCTOR') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 14, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              alert.actionRequired!,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: color),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${t.day}/${t.month}';
  }
}
