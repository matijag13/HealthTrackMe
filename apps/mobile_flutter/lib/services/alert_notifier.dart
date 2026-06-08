import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'notification_service.dart';

/// Bridges the backend's health alerts to the device: after each sync it pulls
/// unread alerts and posts a local notification for any not seen before. This is
/// the "real-time" delivery — Health Connect / our backend can't push, so we
/// piggyback on the existing foreground sync cadence.
class AlertNotifier {
  AlertNotifier._();
  static final AlertNotifier instance = AlertNotifier._();

  static const String _kNotifiedIds = 'notified_alert_ids';
  static const int _maxTracked = 200;

  final ApiService _api = ApiService.instance;

  /// Fetches unread alerts, notifies once per new alert id, and returns the
  /// current unread count (handy for a badge). Best-effort and silent on error.
  Future<int> checkAndNotify() async {
    try {
      final unread = await _api.getHealthAlerts(unreadOnly: true);
      if (unread.isEmpty) return 0;

      final prefs = await SharedPreferences.getInstance();
      final notified = prefs.getStringList(_kNotifiedIds) ?? <String>[];

      for (final a in unread) {
        final key = a.id.toString();
        if (notified.contains(key)) continue;
        await NotificationService.instance.showAlertNotification(
          id: a.id,
          title: a.title,
          body: a.message,
        );
        notified.add(key);
      }

      // Keep the tracking list bounded (ids only grow).
      if (notified.length > _maxTracked) {
        notified.removeRange(0, notified.length - _maxTracked);
      }
      await prefs.setStringList(_kNotifiedIds, notified);
      return unread.length;
    } catch (_) {
      return 0;
    }
  }
}
