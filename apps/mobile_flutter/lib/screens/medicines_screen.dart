import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'router_pages.dart';

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
  static const _background = Color(0xFF050608);
  static const _surface = Color(0xFF0D0F14);
  static const _surfaceSoft = Color(0xFF11141B);
  static const _border = Color(0xFF242936);
  static const _primaryText = Color(0xFFF7F8FA);
  static const _mutedText = Color(0xFF8B93A7);
  static const _accent = Color(0xFF5A8CFF);
  static const _success = Color(0xFF36D399);
  static const _danger = Color(0xFFFF5C7A);

  final ApiService _api = ApiService.instance;
  late Future<List<Medicine>> _future;
  List<Medicine>? _cached;
  final Set<int> _takenToday = {};
  final Set<int> _deletingMedicineIds = {};

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
      _cached = meds;
      return meds;
    } catch (e) {
      return _cached ?? const [];
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
  /// base URL (with /api/v1) is always used — no more manual URL construction.
  Future<void> _postDose(int id, {DateTime? at, String? status}) async {
    final when = at ?? DateTime.now();
    try {
      await _api.logDose(id, when, status ?? 'TAKEN');
      await _refresh();
      if (mounted) {
        _showSnack('Dose logged ✓', color: Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnack('Network error');
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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

  int _daysRemaining(Medicine m) {
    if (m.endDate == null) return 9999;
    final diff = m.endDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.goNamed('home');
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_rounded,
            onTap: _goBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Medicines',
              style: TextStyle(
                color: _primaryText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _iconButton(
            icon: Icons.add_rounded,
            onTap: _showAddSheet,
            tooltip: 'Add medicine',
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _surfaceSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: _primaryText, size: 22),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Medicine> meds) {
    final active = meds.where((m) => m.isActive).length;
    final taken = _takenToday.length;
    final nextDose = meds
        .where((m) => m.isActive && m.scheduleLabel.trim().isNotEmpty)
        .map((m) => m.scheduleLabel)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                    const Text(
                      "Today's overview",
                      style: TextStyle(
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
                  label: 'Active',
                  value: '$active',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  label: 'Taken today',
                  value: '$taken',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: _accent, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nextDose ?? 'No upcoming dose scheduled',
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
            const Text(
              'No medicines yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add medicines to track doses and reminders',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mutedText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add medicine',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
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
      title: "Today's Schedule",
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
          label,
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
    final taken = _takenToday.contains(m.id);
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            decoration: taken ? TextDecoration.lineThrough : null,
            color: taken ? _mutedText : _primaryText,
          ),
        ),
        subtitle: Text(
          m.dosage ?? m.frequency ?? '',
          style: const TextStyle(fontSize: 13, color: _mutedText),
        ),
        trailing: GestureDetector(
          onTap: () async {
            if (taken) {
              setState(() => _takenToday.remove(m.id));
            } else {
              setState(() => _takenToday.add(m.id));
              await _postDose(m.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: taken ? _success : Colors.transparent,
              border: Border.all(
                color: taken ? _success : _border,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: taken
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
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
    final days = _daysRemaining(m);
    final urgent = days <= 3 && days != 9999;

    return Slidable(
      key: ValueKey(m.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _postDose(m.id),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            icon: Icons.check_rounded,
            label: 'Taken',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => _editMedicine(m),
            backgroundColor: const Color(0xFF0A84FF),
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) {
              if (_deletingMedicineIds.contains(m.id)) return;
              _confirmDelete(m);
            },
            backgroundColor: const Color(0xFFFF453A),
            foregroundColor: Colors.white,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
            icon: Icons.delete_rounded,
            label: 'Delete',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => MedicineDetailPage(medicineId: m.id)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
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
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [m.dosage, m.frequency]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (days != 9999)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        urgent ? _danger.withValues(alpha: 0.12) : _surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: urgent ? _danger.withValues(alpha: 0.24) : _border,
                    ),
                  ),
                  child: Text(
                    urgent ? '$days days' : '$days d',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: urgent ? _danger : _mutedText,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _mutedText,
              ),
            ],
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete medicine?',
          style: TextStyle(color: _primaryText, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove "${m.name}" from your medicines list.',
          style: const TextStyle(color: _mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Delete'),
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
      _showSnack('Could not delete medicine');
      return;
    } finally {
      if (mounted) {
        setState(() {
          _deletingMedicineIds.remove(m.id);
        });
      }
    }

    try {
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showSnack('${m.name} removed. Could not refresh list.');
      return;
    }

    if (!mounted) return;
    _showSnack('${m.name} removed');
  }

  void _editMedicine(Medicine m) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicineEditSheet(medicine: m),
    ).then((saved) async {
      if (saved == true) {
        await _refresh();
        if (mounted) _showSnack('Medicine updated ✓', color: Colors.green);
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
      await _refresh();
      if (mounted) _showSnack('Medicine added ✓', color: Colors.green);
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
                  const Text(
                    'Loading medicines',
                    style: TextStyle(
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
        label: const Text('Add medicine',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
    );
  }
}

// ─── Medicines list with Active / All tabs ────────────────────────────────────

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
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final active = widget.medicines.where((m) => m.isActive).toList();
    final all = widget.medicines;
    final list = _index == 0 ? active : all;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFF242936), width: 1)),
            ),
            child: Row(
              children: [
                _tab('Active', 0, count: active.length),
                _tab('All', 1, count: all.length),
              ],
            ),
          ),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No medicines here',
                  style: TextStyle(color: Color(0xFF8B93A7), fontSize: 14),
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

  Widget _tab(String label, int index, {required int count}) {
    final selected = _index == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF5A8CFF) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF5A8CFF)
                      : const Color(0xFF8B93A7),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF5A8CFF)
                      : const Color(0xFF242936),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF8B93A7),
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

// ─── Add / Edit bottom sheet ──────────────────────────────────────────────────

class MedicineEditSheet extends StatefulWidget {
  final Medicine? medicine;
  const MedicineEditSheet({this.medicine, super.key});

  @override
  State<MedicineEditSheet> createState() => _MedicineEditSheetState();
}

class _MedicineEditSheetState extends State<MedicineEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _frequency = TextEditingController();
  final _reason = TextEditingController();
  final _sideEffects = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    if (m != null) {
      _name.text = m.name;
      _dosage.text = m.dosage ?? '';
      _frequency.text = m.frequency ?? '';
      _reason.text = m.reason ?? '';
      _sideEffects.text = m.sideEffects ?? '';
      _start = m.startDate;
      _end = m.endDate;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _frequency.dispose();
    _reason.dispose();
    _sideEffects.dispose();
    super.dispose();
  }

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
      frequency: _frequency.text.trim().isEmpty ? null : _frequency.text.trim(),
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      startDate: _start,
      endDate: _end,
      sideEffects:
          _sideEffects.text.trim().isEmpty ? null : _sideEffects.text.trim(),
      isActive: true,
    ).toJson();

    try {
      final ok = isEdit
          ? await api.updateMedicine(widget.medicine!.id, payload)
          : await api.createMedicine(payload);
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save medicine')),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? (_start ?? now) : (_end ?? now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5A8CFF),
              onPrimary: Colors.white,
              surface: Color(0xFF0D0F14),
              onSurface: Color(0xFFF7F8FA),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0D0F14),
            ),
          ),
          child: child!,
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF11141B),
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
          color: Color(0xFF0D0F14),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF242936))),
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
                                    isEdit ? 'Edit medicine' : 'Add medicine',
                                    style: const TextStyle(
                                      color: Color(0xFFF7F8FA),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Track doses, schedules, and notes.',
                                    style: TextStyle(
                                      color: Color(0xFF8B93A7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () => Navigator.pop(context, false),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF11141B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF242936),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFF7F8FA),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Medicine name',
                            prefixIcon: Icon(Icons.medication_rounded),
                          ),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dosage,
                              decoration: const InputDecoration(
                                labelText: 'Dosage',
                                hintText: 'e.g. 500mg',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _frequency,
                              decoration: const InputDecoration(
                                labelText: 'Frequency',
                                hintText: 'e.g. Once daily',
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: _DateButton(
                              label:
                                  _start == null ? 'Start date' : _fmt(_start),
                              placeholder: _start == null,
                              icon: Icons.calendar_today_rounded,
                              onTap: () => _pickDate(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateButton(
                              label: _end == null ? 'End date' : _fmt(_end),
                              placeholder: _end == null,
                              icon: Icons.event_rounded,
                              onTap: () => _pickDate(false),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _reason,
                          decoration: const InputDecoration(
                            labelText: 'Reason (optional)',
                            prefixIcon: Icon(Icons.info_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _sideEffects,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Side effects / notes',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 48),
                              child: Icon(Icons.notes_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _saving
                                      ? null
                                      : () => Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFF7F8FA),
                                    side: const BorderSide(
                                      color: Color(0xFF242936),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: _saving ? null : _save,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF5A8CFF),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFF263A66),
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
                                      : const Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
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
          color: const Color(0xFF11141B),
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
