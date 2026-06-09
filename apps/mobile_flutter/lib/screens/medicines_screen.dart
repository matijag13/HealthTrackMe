import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/dark_time_picker.dart';
import '../models/models.dart';
import 'router_pages.dart';

enum _MedicineToastType { success, error, warning, neutral }

class _MedicineToastTheme {
  final IconData icon;
  final Color accent;

  const _MedicineToastTheme({
    required this.icon,
    required this.accent,
  });
}

void _showMedicineToast(
  BuildContext context,
  String message, {
  _MedicineToastType type = _MedicineToastType.neutral,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  final theme = switch (type) {
    _MedicineToastType.success => const _MedicineToastTheme(
        icon: Icons.check_circle_rounded,
        accent: _MedicinesScreenState._success,
      ),
    _MedicineToastType.error => const _MedicineToastTheme(
        icon: Icons.error_outline_rounded,
        accent: _MedicinesScreenState._danger,
      ),
    _MedicineToastType.warning => const _MedicineToastTheme(
        icon: Icons.info_outline_rounded,
        accent: Color(0xFFF5B941),
      ),
    _MedicineToastType.neutral => const _MedicineToastTheme(
        icon: Icons.notifications_none_rounded,
        accent: _MedicinesScreenState._accent,
      ),
  };

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
          color: _MedicinesScreenState._surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.accent.withValues(alpha: 0.34)),
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
                  color: theme.accent,
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
                      color: theme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: theme.accent.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      theme.icon,
                      color: theme.accent,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: _MedicinesScreenState._primaryText,
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

class _MedicineDialogCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MedicineDialogCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _MedicinesScreenState._surfaceSoft,
            shape: BoxShape.circle,
            border: Border.all(color: _MedicinesScreenState._border),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: _MedicinesScreenState._primaryText,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Medicines screen — fully rewritten UI + bug fixes:
///
/// BUG FIX: getMedicines() used _effectiveUserId() which is synchronous and
/// returns null if _activeUserId hasn't been set yet on the singleton (e.g. on
/// cold start or after createMedicine resolved the id via ensureActiveUserId).
/// Fix: _load() now calls ensureActiveUserId() first so the id is always valid.
///
/// BUG FIX: _postDose was constructing the URL manually with _api.baseUrl which
/// already includes /api/v1, causing double-prefixing. Now uses _api directly.

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen>
    with AutomaticKeepAliveClientMixin {
  static const _background = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceSoft = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _mutedText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5A8CFF);
  static const _success = Color(0xFF36D399);
  static const _danger = Color(0xFFFF5C7A);

  final ApiService _api = ApiService.instance;
  late Future<List<Medicine>> _future;
  List<Medicine>? _cached;
  // Medicines that have had ALL of today's doses taken (used for the "done"
  // state and the header count).
  final Set<int> _takenToday = {};
  // Per-medicine count of doses taken today (for multi-dose meds).
  final Map<int, int> _doseCountToday = {};
  final Set<int> _deletingMedicineIds = {};
  final Set<int> _loggingMedicineIds = {};
  bool _hasChanges = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// FIX: always resolve the active user id before fetching, so getMedicines
  /// never gets a null id on first load.
  Future<List<Medicine>> _load() async {
    try {
      // Ensure the singleton has an active user id set
      await _api.ensureActiveUserId();
      final meds = await _api.getMedicines(activeOnly: false);
      await _syncTakenToday(meds);
      _cached = meds;
      await _rescheduleReminders(meds);
      return meds;
    } catch (e) {
      return _cached ?? const [];
    }
  }

  /// Cancels + reschedules local notifications from each medicine's persisted
  /// reminder times, so reminders are DB-driven and survive reinstall. Runs on
  /// first load and after every add/edit (via _refresh).
  Future<void> _rescheduleReminders(List<Medicine> meds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersOn = prefs.getBool('pref_medicine_reminders') ?? true;
      final notifs = NotificationService.instance;
      for (final m in meds) {
        if (remindersOn && m.isActive && m.reminderTimes.isNotEmpty) {
          await notifs.scheduleMedicineReminders(
            medicineId: m.id,
            medicineName: m.name,
            dosage: (m.dosage != null && m.dosage!.trim().isNotEmpty)
                ? m.dosage!.trim()
                : 'your dose',
            times: m.reminderTimes,
            // Skip today's reminders for doses already taken today.
            dosesTakenToday: _doseCount(m.id),
          );
        } else {
          await notifs.cancelMedicineReminders(m.id);
        }
      }
    } catch (e) {
      debugPrint('Failed to reschedule medicine reminders: $e');
    }
  }

  Future<void> _refresh() async {
    final future = _load();
    if (!mounted) return;
    setState(() {
      _future = future;
    });
    await future;
  }

  /// FIX: use api service's _postRaw via logDose helper so the correct
  /// How many doses a medicine is expected to have per day — from its reminder
  /// times if set, otherwise inferred from the frequency text.
  int _expectedDoses(Medicine m) {
    if (m.reminderTimes.isNotEmpty) return m.reminderTimes.length;
    final f = (m.frequency ?? '').toLowerCase();
    if (f.contains('four')) return 4;
    if (f.contains('three') || f.contains('thrice')) return 3;
    if (f.contains('twice') || f.contains('two')) return 2;
    return 1;
  }

  int _doseCount(int id) => _doseCountToday[id] ?? 0;

  bool _isFullyTaken(Medicine m) => _doseCount(m.id) >= _expectedDoses(m);

  Medicine? _medById(int id) {
    for (final m in _cached ?? const <Medicine>[]) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Pulls how many doses were taken today per medicine, so multi-dose meds
  /// track each dose (instead of one yes/no flag for the whole day).
  Future<void> _syncTakenToday(List<Medicine> meds) async {
    if (meds.isEmpty) {
      _takenToday.clear();
      _doseCountToday.clear();
      return;
    }

    try {
      final counts = await Future.wait(
        meds.map((m) async {
          try {
            final adherence = await _api.getMedicineAdherence(m.id, days: 1);
            final raw = adherence['takenCount'];
            final count = raw is num
                ? raw.toInt()
                : int.tryParse(raw?.toString() ?? '') ?? 0;
            return MapEntry(m.id, count < 0 ? 0 : count);
          } catch (_) {
            return MapEntry(m.id, _doseCount(m.id)); // keep last known
          }
        }),
      );
      _doseCountToday
        ..clear()
        ..addEntries(counts);
      _takenToday
        ..clear()
        ..addAll(meds.where(_isFullyTaken).map((m) => m.id));
    } catch (_) {
      // Keep local state when adherence is unavailable.
    }
  }

  Future<void> _postDose(int id, {DateTime? at, String? status}) async {
    if (_loggingMedicineIds.contains(id)) return;
    final when = at ?? DateTime.now();
    setState(() => _loggingMedicineIds.add(id));
    try {
      await _api.logDose(id, when, status ?? 'TAKEN');
      if (mounted) {
        setState(() {
          // Optimistic per-dose increment; _refresh re-syncs the real count.
          _doseCountToday[id] = _doseCount(id) + 1;
          final med = _medById(id);
          if (med != null && _isFullyTaken(med)) _takenToday.add(id);
        });
      }
      await _refresh();
      if (mounted) {
        _hasChanges = true;
        _showMedicineToast(context, context.l10n.markedAsTaken,
            type: _MedicineToastType.success);
      }
    } catch (e) {
      if (mounted) {
        _showMedicineToast(
          context,
          context.l10n.networkError,
          type: _MedicineToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loggingMedicineIds.remove(id));
      }
    }
  }

  /// Removes the most recent TAKEN dose of [id] for today.
  Future<void> _undoDose(int id) async {
    if (_loggingMedicineIds.contains(id)) return;
    setState(() => _loggingMedicineIds.add(id));
    try {
      await _api.undoLatestDose(id);
      if (mounted) {
        setState(() {
          final cur = _doseCount(id);
          _doseCountToday[id] = (cur - 1).clamp(0, 99);
          _takenToday.remove(id);
        });
      }
      await _refresh();
      if (mounted) {
        _hasChanges = true;
        _showMedicineToast(context, context.l10n.doseRemoved,
            type: _MedicineToastType.warning);
      }
    } catch (e) {
      if (mounted) {
        _showMedicineToast(context, context.l10n.couldNotUndoDose,
            type: _MedicineToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loggingMedicineIds.remove(id));
    }
  }

  void _showUndoDoseDialog(Medicine m) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.undoDoseQuestion,
          style: const TextStyle(
            color: _primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          context.l10n.removeTodaysLastDose(m.name),
          style: const TextStyle(color: _mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF5B941),
              foregroundColor: Colors.black87,
            ),
            child: Text(context.l10n.undo),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) await _undoDose(m.id);
    });
  }

  Map<String, List<Medicine>> _groupByTime(List<Medicine> meds) {
    final groups = <String, List<Medicine>>{
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
      'Other': [],
    };
    for (final m in meds) {
      final label = m.scheduleLabel.toLowerCase();
      if (label.contains('morning')) {
        groups['Morning']!.add(m);
      } else if (label.contains('afternoon')) {
        groups['Afternoon']!.add(m);
      } else if (label.contains('evening') || label.contains('night')) {
        groups['Evening']!.add(m);
      } else {
        groups['Other']!.add(m);
      }
    }
    return groups;
  }

  String _medicineMetaLine(Medicine m) {
    final dosage = m.dosage?.trim();
    final schedule = _formatFrequency(m.frequency);
    final parts = <String>[];
    if (dosage != null && dosage.isNotEmpty) {
      parts.add(context.l10n.dosageValue(dosage));
    }
    if (schedule != null) parts.add(schedule);
    return parts.isEmpty ? context.l10n.noScheduleSet : parts.join(' · ');
  }

  String? _formatFrequency(String? frequency) {
    final value = frequency?.trim();
    if (value == null || value.isEmpty) return null;

    final count = int.tryParse(value);
    if (count != null) {
      return context.l10n.timesDaily(count);
    }

    return _frequencyLabel(value);
  }

  String _frequencyLabel(String value) => switch (value) {
        'Once daily' => context.l10n.onceDaily,
        'Twice daily' => context.l10n.twiceDaily,
        'Three times daily' => context.l10n.threeTimesDaily,
        'Four times daily' => context.l10n.fourTimesDaily,
        'Every other day' => context.l10n.everyOtherDay,
        'Once weekly' => context.l10n.onceWeekly,
        'As needed' => context.l10n.asNeeded,
        _ => value,
      };

  // ─── Widgets ──────────────────────────────────────────────────────────────

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(_hasChanges);
      return;
    }
    context.goNamed('home');
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _iconButton(icon: Icons.arrow_back, onTap: _goBack),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              context.l10n.medicines,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _primaryText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: _primaryText, size: 21),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Medicine> meds) {
    final active = meds.where((m) => m.isActive).length;
    final taken = _takenToday.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: _accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.todayOverview,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _todayLabel(),
                      style: const TextStyle(color: _mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  label: context.l10n.active,
                  value: '$active',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  label: context.l10n.takenToday,
                  value: '$taken',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border.withValues(alpha: 0.75)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: _accent,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.noMedicinesYet,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.addMedicinesDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLegacyHeader(List<Medicine> meds) {
    final active = meds.where((m) => m.isActive).length;
    final taken = _takenToday.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medicines',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Today — ${_todayLabel()}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _legacyStatPill(
              icon: Icons.medication_rounded,
              label: '$active active',
              bg: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 10),
            _legacyStatPill(
              icon: Icons.check_circle_rounded,
              label: '$taken taken today',
              bg: Colors.white.withValues(alpha: 0.2),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _legacyStatPill({
    required IconData icon,
    required String label,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(List<Medicine> meds) {
    final active = meds.where((m) => m.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    final groups = _groupByTime(active);
    final nonEmpty = groups.entries.where((e) => e.value.isNotEmpty).toList();

    return _section(
      title: context.l10n.todaySchedule,
      child: Column(
        children: nonEmpty.map((e) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nonEmpty.first != e) const Divider(height: 1, color: _border),
              _timeGroupHeader(e.key),
              ...e.value.map((m) => _scheduleTile(m)),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _timeGroupLabel(String label) => switch (label) {
        'Morning' => context.l10n.morning,
        'Afternoon' => context.l10n.afternoon,
        'Evening' => context.l10n.evening,
        'Other' => context.l10n.other,
        _ => label,
      };

  Widget _timeGroupHeader(String label) {
    final icons = {
      'Morning': (Icons.wb_sunny_rounded, const Color(0xFFFF9500)),
      'Afternoon': (Icons.wb_cloudy_rounded, _accent),
      'Evening': (Icons.nights_stay_rounded, const Color(0xFF6C63FF)),
      'Other': (Icons.schedule_rounded, _mutedText),
    };
    final pair = icons[label] ?? (Icons.schedule_rounded, _mutedText);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(children: [
        Icon(pair.$1, size: 16, color: pair.$2),
        const SizedBox(width: 6),
        Text(
          _timeGroupLabel(label),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: pair.$2,
          ),
        ),
      ]),
    );
  }

  Widget _scheduleTile(Medicine m) {
    final expected = _expectedDoses(m);
    final doseCount = _doseCount(m.id);
    final taken = doseCount >= expected;
    final multiDose = expected > 1;
    final logging = _loggingMedicineIds.contains(m.id);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: taken
                ? _success.withValues(alpha: 0.12)
                : _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            taken ? Icons.check_rounded : Icons.medication_rounded,
            size: 20,
            color: taken ? _success : _accent,
          ),
        ),
        title: Text(
          m.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: taken ? _mutedText : _primaryText,
          ),
        ),
        subtitle: Text(
          multiDose
              ? '${_medicineMetaLine(m)} · ${context.l10n.dosesToday(doseCount, expected)}'
              : _medicineMetaLine(m),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: _mutedText),
        ),
        trailing: GestureDetector(
          onTap: () async {
            if (taken) {
              _showUndoDoseDialog(m);
            } else {
              await _postDose(m.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: taken ? 84 : 44,
            height: 36,
            decoration: BoxDecoration(
              color: taken ? _success.withValues(alpha: 0.16) : _surfaceSoft,
              border: Border.all(
                color: taken ? _success.withValues(alpha: 0.55) : _border,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: taken
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 17, color: _success),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.taken,
                        style: const TextStyle(
                          color: _success,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : logging
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _accent,
                          ),
                        ),
                      )
                    : multiDose
                        ? Center(
                            child: Text(
                              '$doseCount/$expected',
                              style: const TextStyle(
                                color: _accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                            size: 19,
                            color: _mutedText,
                          ),
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => MedicineDetailPage(medicineId: m.id)),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Medicine m) {
    final expected = _expectedDoses(m);
    final doseCount = _doseCount(m.id);
    final taken = doseCount >= expected;
    final multiDose = expected > 1;
    final logging = _loggingMedicineIds.contains(m.id);

    final deleting = _deletingMedicineIds.contains(m.id);

    return Slidable(
      key: ValueKey(m.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.30,
        children: [
          CustomSlidableAction(
            flex: 1,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            onPressed: (_) {
              if (taken) {
                _undoDose(m.id);
              } else {
                _postDose(m.id);
              }
            },
            child: _ActionSegment(
              label: taken
                  ? context.l10n.undo
                  : (multiDose ? '$doseCount/$expected' : context.l10n.take),
              icon: taken ? Icons.undo_rounded : Icons.check_rounded,
              backgroundColor:
                  taken ? const Color(0xFF241B0D) : const Color(0xFF11141B),
              foregroundColor: taken ? const Color(0xFFF5B941) : _success,
              borderColor: taken
                  ? const Color(0xFFF5B941).withValues(alpha: 0.38)
                  : _success.withValues(alpha: 0.38),
              busy: logging,
              isFirst: true,
              isLast: true,
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.55,
        children: [
          CustomSlidableAction(
            flex: 1,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            onPressed: (_) => _editMedicine(m),
            child: _ActionSegment(
              label: context.l10n.edit,
              icon: Icons.edit_rounded,
              backgroundColor: const Color(0xFF101A31),
              foregroundColor: _MedicinesScreenState._accent,
              borderColor: const Color(0xFF284C98),
              isFirst: true,
              isLast: false,
            ),
          ),
          CustomSlidableAction(
            flex: 1,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            onPressed: (_) {
              if (deleting) return;
              _confirmDelete(m);
            },
            child: _ActionSegment(
              label: deleting ? context.l10n.deleting : context.l10n.delete,
              icon:
                  deleting ? Icons.hourglass_top_rounded : Icons.delete_rounded,
              backgroundColor:
                  deleting ? const Color(0xFF241116) : const Color(0xFF2A1016),
              foregroundColor: _danger,
              borderColor: _danger.withValues(alpha: 0.34),
              busy: deleting,
              isFirst: false,
              isLast: true,
            ),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => MedicineDetailPage(medicineId: m.id)),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: m.isActive
                        ? const Color(0xFF0A84FF).withValues(alpha: 0.1)
                        : const Color(0xFF64748B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    size: 22,
                    color: m.isActive ? _accent : _mutedText,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _medicineMetaLine(m),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              title,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Medicine m) async {
    if (_deletingMedicineIds.contains(m.id)) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Expanded(
              child: Text(
                l10n.deleteMedicineQuestion,
                style: const TextStyle(
                  color: _primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _MedicineDialogCloseButton(onTap: () => Navigator.pop(ctx, false)),
          ],
        ),
        content: Text(
          l10n.removeMedicineFromList(m.name),
          style: const TextStyle(color: _mutedText),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: _primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.delete),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) await _deleteMedicine(m);
  }

  Future<void> _deleteMedicine(Medicine m) async {
    if (_deletingMedicineIds.contains(m.id)) return;
    if (mounted) {
      setState(() {
        _deletingMedicineIds.add(m.id);
      });
    }

    try {
      await _api.deleteMedicine(m.id);
    } catch (e) {
      if (!mounted) return;
      _showMedicineToast(
        context,
        context.l10n.couldNotDeleteMedicine,
        type: _MedicineToastType.error,
      );
      return;
    } finally {
      if (mounted) {
        setState(() {
          _deletingMedicineIds.remove(m.id);
        });
      }
    }

    _hasChanges = true;

    try {
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showMedicineToast(
        context,
        context.l10n.medicineRemovedRefreshFailed(m.name),
        type: _MedicineToastType.error,
      );
      return;
    }

    if (!mounted) return;
    _showMedicineToast(
      context,
      context.l10n.medicineRemoved(m.name),
      type: _MedicineToastType.error,
    );
  }

  void _editMedicine(Medicine m) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicineEditSheet(medicine: m),
    ).then((saved) async {
      if (saved == true) {
        _hasChanges = true;
        await _refresh();
        if (mounted) {
          _showMedicineToast(
            context,
            context.l10n.medicineUpdated,
            type: _MedicineToastType.success,
          );
        }
      }
    });
  }

  Future<void> _showAddSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MedicineEditSheet(),
    );
    if (saved == true) {
      _hasChanges = true;
      await _refresh();
      if (mounted) {
        _showMedicineToast(
          context,
          context.l10n.medicineAdded,
          type: _MedicineToastType.success,
        );
      }
    }
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _background,
      body: FutureBuilder<List<Medicine>>(
        future: _future,
        builder: (context, snapshot) {
          // Show skeleton only on truly first load
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cached == null) {
            return SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const Spacer(),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.loadingMedicines,
                    style: const TextStyle(
                      color: _mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            );
          }

          final meds = snapshot.data ?? _cached ?? const <Medicine>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            color: _accent,
            backgroundColor: _surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverSafeArea(
                  bottom: false,
                  sliver: SliverToBoxAdapter(child: _buildTopBar()),
                ),
                SliverToBoxAdapter(child: _buildSummaryCard(meds)),
                if (meds.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: _buildEmptyState(),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildScheduleSection(meds),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _MedicinesListSection(
                        medicines: meds,
                        buildCard: _buildMedicineCard,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.addMedicine,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
    );
  }
}

class _ActionSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final bool busy;
  final bool isFirst;
  final bool isLast;

  const _ActionSegment({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.isFirst,
    required this.isLast,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(16) : Radius.zero,
          right: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        border: Border.all(color: borderColor),
      ),
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              else
                Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicinesListSection extends StatefulWidget {
  final List<Medicine> medicines;
  final Widget Function(Medicine) buildCard;

  const _MedicinesListSection({
    required this.medicines,
    required this.buildCard,
  });

  @override
  State<_MedicinesListSection> createState() => _MedicinesListSectionState();
}

class _MedicinesListSectionState extends State<_MedicinesListSection> {
  @override
  Widget build(BuildContext context) {
    final list = widget.medicines;

    return Container(
      decoration: BoxDecoration(
        color: _MedicinesScreenState._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.medicines,
                    style: const TextStyle(
                      color: Color(0xFFF7F8FA),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11141B),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF242936)),
                  ),
                  child: Text(
                    '${list.length}',
                    style: const TextStyle(
                      color: Color(0xFF8B93A7),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  context.l10n.noMedicinesHere,
                  style:
                      const TextStyle(color: Color(0xFF8B93A7), fontSize: 14),
                ),
              ),
            )
          else
            ...list.map((m) => Column(
                  children: [
                    widget.buildCard(m),
                    if (m != list.last)
                      const Divider(
                        height: 1,
                        indent: 74,
                        endIndent: 0,
                        color: Color(0xFF242936),
                      ),
                  ],
                )),
        ],
      ),
    );
  }
}

// ─── Add / Edit bottom sheet ──────────────────────────────────────────────────

class MedicineEditSheet extends StatefulWidget {
  final Medicine? medicine;
  const MedicineEditSheet({this.medicine, super.key});

  @override
  State<MedicineEditSheet> createState() => _MedicineEditSheetState();
}

class _MedicineEditSheetState extends State<MedicineEditSheet> {
  static const _frequencyOptions = <String>[
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every other day',
    'Once weekly',
    'As needed',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _reason = TextEditingController();
  final _sideEffects = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  String? _selectedFrequency;
  final List<TimeOfDay> _reminderTimes = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    if (m != null) {
      _name.text = m.name;
      _dosage.text = m.dosage ?? '';
      _selectedFrequency = m.frequency;
      _reason.text = m.reason ?? '';
      _sideEffects.text = m.sideEffects ?? '';
      _start = m.startDate;
      _end = m.endDate;
      for (final t in m.reminderTimes) {
        final tod = _parseHhmm(t);
        if (tod != null) _reminderTimes.add(tod);
      }
      _sortReminderTimes();
    }
  }

  static TimeOfDay? _parseHhmm(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String _formatHhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// 12-hour display (e.g. 12:00 PM), matching the AM/PM picker.
  static String _format12h(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  void _sortReminderTimes() {
    _reminderTimes.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _reason.dispose();
    _sideEffects.dispose();
    super.dispose();
  }

  String _frequencyLabel(String value) => switch (value) {
        'Once daily' => context.l10n.onceDaily,
        'Twice daily' => context.l10n.twiceDaily,
        'Three times daily' => context.l10n.threeTimesDaily,
        'Four times daily' => context.l10n.fourTimesDaily,
        'Every other day' => context.l10n.everyOtherDay,
        'Once weekly' => context.l10n.onceWeekly,
        'As needed' => context.l10n.asNeeded,
        _ => value,
      };

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final api = ApiService.instance;
    final isEdit = widget.medicine != null;
    final payload = Medicine(
      id: 0,
      name: _name.text.trim(),
      dosage: _dosage.text.trim().isEmpty ? null : _dosage.text.trim(),
      frequency: _selectedFrequency,
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      startDate: _start,
      endDate: _end,
      sideEffects:
          _sideEffects.text.trim().isEmpty ? null : _sideEffects.text.trim(),
      isActive: true,
      reminderTimes: _reminderTimes.map(_formatHhmm).toList(),
    ).toJson();

    try {
      final ok = isEdit
          ? await api.updateMedicine(widget.medicine!.id, payload)
          : await api.createMedicine(payload);
      if (!ok) {
        if (mounted) {
          _showMedicineToast(
            context,
            context.l10n.couldNotSaveMedicine,
            type: _MedicineToastType.error,
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        _showMedicineToast(
          context,
          context.l10n.networkError,
          type: _MedicineToastType.error,
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    // Make sure notifications are actually permitted before relying on the
    // reschedule-on-load (see _MedicinesScreenState._load) to set the reminders.
    if (_reminderTimes.isNotEmpty) {
      await NotificationService.instance.requestPermissions();
    }

    // Notifications are (re)scheduled from persisted data when the list
    // reloads, so both create and edit get correct, server-id-based reminder ids.
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addReminderTime() async {
    final picked = await showDarkTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      title: context.l10n.enterTime,
    );
    if (picked == null || !mounted) return;
    final exists = _reminderTimes
        .any((t) => t.hour == picked.hour && t.minute == picked.minute);
    if (exists) return;
    setState(() {
      _reminderTimes.add(picked);
      _sortReminderTimes();
    });
  }

  void _removeReminderTime(TimeOfDay time) {
    setState(() => _reminderTimes
        .removeWhere((t) => t.hour == time.hour && t.minute == time.minute));
  }

  Widget _buildRemindersField() {
    const accent = Color(0xFF5A8CFF);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_reminderTimes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _reminderTimes)
                Container(
                  padding: const EdgeInsets.only(
                      left: 12, right: 4, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 15, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        _format12h(t),
                        style: const TextStyle(
                          color: Color(0xFFF7F8FA),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      InkWell(
                        onTap: () => _removeReminderTime(t),
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded,
                              size: 15, color: Color(0xFF8A93A6)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _DateButton(
          label: _reminderTimes.isEmpty
              ? context.l10n.addReminderTimeOptional
              : context.l10n.addAnotherTime,
          placeholder: _reminderTimes.isEmpty,
          icon: Icons.notifications_outlined,
          onTap: _addReminderTime,
        ),
      ],
    );
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // End/start dates may be in the future (e.g. a course that ends next month).
    final lastSelectable = DateTime(now.year + 5, now.month, now.day);
    final selectedDate = start ? (_start ?? today) : (_end ?? today);
    final initialDate =
        selectedDate.isAfter(lastSelectable) ? lastSelectable : selectedDate;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5A8CFF),
              onPrimary: Colors.white,
              surface: _MedicinesScreenState._surface,
              onSurface: _MedicinesScreenState._primaryText,
              secondary: Color(0xFF5A8CFF),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: _MedicinesScreenState._surface,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: _MedicinesScreenState._surface,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: _MedicinesScreenState._surfaceSoft,
              headerForegroundColor: _MedicinesScreenState._primaryText,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return _MedicinesScreenState._mutedText
                      .withValues(alpha: 0.5);
                }
                return _MedicinesScreenState._primaryText;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF5A8CFF);
                }
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return _MedicinesScreenState._mutedText
                      .withValues(alpha: 0.5);
                }
                return const Color(0xFF5A8CFF);
              }),
              todayBorder: const BorderSide(color: Color(0xFF5A8CFF)),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return _MedicinesScreenState._mutedText
                      .withValues(alpha: 0.5);
                }
                return _MedicinesScreenState._primaryText;
              }),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5A8CFF),
              ),
            ),
          ),
          child: Dialog(
            backgroundColor: _MedicinesScreenState._surface,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: _MedicinesScreenState._border),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xFF5A8CFF),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.selectDate,
                            style: const TextStyle(
                              color: _MedicinesScreenState._primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('EEE, MMM d, yyyy').format(initialDate),
                        style: const TextStyle(
                          color: _MedicinesScreenState._primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: CalendarDatePicker(
                        initialDate: initialDate,
                        firstDate: DateTime(2000),
                        lastDate: lastSelectable,
                        currentDate: today,
                        onDateChanged: (date) {
                          Navigator.of(dialogContext).pop<DateTime>(date);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => start ? _start = picked : _end = picked);
    }
  }

  String _fmt(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicine != null;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF242936)),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: const Color(0xFFF7F8FA),
              displayColor: const Color(0xFFF7F8FA),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _MedicinesScreenState._surfaceSoft,
          labelStyle: const TextStyle(color: Color(0xFF8B93A7)),
          hintStyle: const TextStyle(color: Color(0xFF6F778A)),
          prefixIconColor: const Color(0xFF8B93A7),
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: inputBorder.copyWith(
            borderSide: const BorderSide(color: Color(0xFF5A8CFF), width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF5A8CFF),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: _MedicinesScreenState._surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: _MedicinesScreenState._border)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF242936),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit
                                        ? context.l10n.editMedicine
                                        : context.l10n.addMedicine,
                                    style: const TextStyle(
                                      color: Color(0xFFF7F8FA),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    context.l10n.trackDosesSchedulesNotes,
                                    style: const TextStyle(
                                      color: Color(0xFF8B93A7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Material(
                              color: Colors.transparent,
                              child: IconButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.pop(context, false),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: _MedicinesScreenState._primaryText,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      _MedicinesScreenState._surfaceSoft,
                                  side: BorderSide(
                                    color: _MedicinesScreenState._border
                                        .withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _name,
                          style: const TextStyle(color: Color(0xFFF7F8FA)),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: context.l10n.medicineName,
                            prefixIcon: const Icon(Icons.medication_rounded),
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? context.l10n.required
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dosage,
                              style: const TextStyle(color: Color(0xFFF7F8FA)),
                              decoration: InputDecoration(
                                labelText: context.l10n.dosage,
                                hintText: 'e.g. 500mg',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedFrequency,
                              isExpanded: true,
                              dropdownColor: _MedicinesScreenState._surfaceSoft,
                              iconEnabledColor: const Color(0xFF94A3B8),
                              style: const TextStyle(color: Color(0xFFF7F8FA)),
                              decoration: InputDecoration(
                                labelText: context.l10n.frequency,
                              ),
                              hint: Text(
                                context.l10n.select,
                                style:
                                    const TextStyle(color: Color(0xFF94A3B8)),
                              ),
                              items: [
                                if (_selectedFrequency != null &&
                                    !_frequencyOptions
                                        .contains(_selectedFrequency))
                                  DropdownMenuItem(
                                    value: _selectedFrequency,
                                    child: Text(
                                        _frequencyLabel(_selectedFrequency!)),
                                  ),
                                for (final f in _frequencyOptions)
                                  DropdownMenuItem(
                                    value: f,
                                    child: Text(_frequencyLabel(f)),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedFrequency = v),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: _DateButton(
                              label: _start == null
                                  ? context.l10n.startDate
                                  : _fmt(_start),
                              placeholder: _start == null,
                              icon: Icons.calendar_today_rounded,
                              onTap: () => _pickDate(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateButton(
                              label: _end == null
                                  ? context.l10n.endDate
                                  : _fmt(_end),
                              placeholder: _end == null,
                              icon: Icons.event_rounded,
                              onTap: () => _pickDate(false),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _reason,
                          style: const TextStyle(color: Color(0xFFF7F8FA)),
                          decoration: InputDecoration(
                            labelText: context.l10n.reasonOptional,
                            prefixIcon: const Icon(Icons.info_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _sideEffects,
                          style: const TextStyle(color: Color(0xFFF7F8FA)),
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: context.l10n.sideEffectsNotes,
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 48),
                              child: Icon(Icons.notes_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildRemindersField(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF5A8CFF),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF263A66),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    context.l10n.save,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final bool placeholder;
  final IconData icon;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _MedicinesScreenState._surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF242936)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: placeholder
                    ? const Color(0xFF8B93A7)
                    : const Color(0xFF5A8CFF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: placeholder
                      ? const Color(0xFF8B93A7)
                      : const Color(0xFFF7F8FA),
                  fontWeight: placeholder ? FontWeight.normal : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
