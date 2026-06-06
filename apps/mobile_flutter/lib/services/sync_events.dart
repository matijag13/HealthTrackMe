import 'package:flutter/foundation.dart';

/// Broadcasts when a foreground/background health sync uploads new data, so any
/// open screen can refresh itself. Screens listen to [revision] and reload when
/// it changes.
class SyncEvents {
  SyncEvents._();
  static final SyncEvents instance = SyncEvents._();

  /// Bumped each time a sync uploads new data. Add a listener to react.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void notifySynced() {
    revision.value++;
  }
}
