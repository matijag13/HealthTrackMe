import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../widgets/design_system.dart';
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
  final ApiService _api = ApiService.instance;
  late Future<List<Medicine>> _future;
  List<Medicine>? _cached;
  final Set<int> _takenToday = {};

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

  Widget _buildHeader(List<Medicine> meds) {
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
            _statPill(
              icon: Icons.medication_rounded,
              label: '$active active',
              bg: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(width: 10),
            _statPill(
              icon: Icons.check_circle_rounded,
              label: '$taken taken today',
              bg: Colors.white.withOpacity(0.2),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _statPill({
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
              if (nonEmpty.first != e) const Divider(height: 1),
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
      'Afternoon': (Icons.wb_cloudy_rounded, const Color(0xFF0A84FF)),
      'Evening': (Icons.nights_stay_rounded, const Color(0xFF6C63FF)),
      'Other': (Icons.schedule_rounded, const Color(0xFF64748B)),
    };
    final pair = icons[label] ?? (Icons.schedule_rounded, const Color(0xFF64748B));
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: taken
              ? Colors.green.withOpacity(0.12)
              : const Color(0xFF0A84FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          taken ? Icons.check_rounded : Icons.medication_rounded,
          size: 20,
          color: taken ? Colors.green : const Color(0xFF0A84FF),
        ),
      ),
      title: Text(
        m.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          decoration: taken ? TextDecoration.lineThrough : null,
          color: taken ? Colors.grey : null,
        ),
      ),
      subtitle: Text(
        m.dosage ?? m.frequency ?? '',
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
            color: taken ? Colors.green : Colors.transparent,
            border: Border.all(
              color: taken ? Colors.green : const Color(0xFFD7DDE6),
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
        MaterialPageRoute(builder: (_) => MedicineDetailPage(medicineId: m.id)),
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
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
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
            onPressed: (_) => _confirmDelete(m),
            backgroundColor: const Color(0xFFFF453A),
            foregroundColor: Colors.white,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            icon: Icons.delete_rounded,
            label: 'Delete',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MedicineDetailPage(medicineId: m.id)),
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
                      ? const Color(0xFF0A84FF).withOpacity(0.1)
                      : const Color(0xFF64748B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  size: 22,
                  color: m.isActive
                      ? const Color(0xFF0A84FF)
                      : const Color(0xFF64748B),
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
                        color: Color(0xFF64748B),
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
                    color: urgent
                        ? const Color(0xFFFF453A).withOpacity(0.1)
                        : const Color(0xFF64748B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    urgent ? '$days days' : '$days d',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: urgent
                          ? const Color(0xFFFF453A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFD7DDE6),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7DDE6)),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete medicine?'),
        content: Text('Remove "${m.name}" from your medicines list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteMedicine(m);
  }

  Future<void> _deleteMedicine(Medicine m) async {
    try {
      await _api.deleteMedicine(m.id);
      await _refresh();
      if (mounted) _showSnack('${m.name} removed');
    } catch (e) {
      if (mounted) _showSnack('Could not delete medicine');
    }
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: FutureBuilder<List<Medicine>>(
        future: _future,
        builder: (context, snapshot) {
          // Show skeleton only on truly first load
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cached == null) {
            return Column(
              children: [
                // Placeholder header
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LoadingSkeleton.medicines(context),
                  ),
                ),
              ],
            );
          }

          final meds = snapshot.data ?? _cached ?? const <Medicine>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFF0A84FF),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(meds)),
                if (meds.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: EmptyState(
                        icon: Icons.medication_outlined,
                        title: 'No medicines yet',
                        subtitle: 'Tap + to add your first medicine',
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildScheduleSection(meds),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
        backgroundColor: const Color(0xFF0A84FF),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7DDE6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFD7DDE6), width: 1)),
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
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ),
            )
          else
            ...list.map((m) => Column(
                  children: [
                    widget.buildCard(m),
                    if (m != list.last)
                      const Divider(height: 1, indent: 74, endIndent: 0),
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
                color: selected
                    ? const Color(0xFF0A84FF)
                    : Colors.transparent,
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
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF0A84FF)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0A84FF)
                      : const Color(0xFFD7DDE6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF64748B),
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
    final payload = Medicine(
      id: 0,
      name: _name.text.trim(),
      dosage: _dosage.text.trim().isEmpty ? null : _dosage.text.trim(),
      frequency:
          _frequency.text.trim().isEmpty ? null : _frequency.text.trim(),
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      startDate: _start,
      endDate: _end,
      sideEffects:
          _sideEffects.text.trim().isEmpty ? null : _sideEffects.text.trim(),
      isActive: true,
    ).toJson();

    try {
      final ok = await api.createMedicine(payload);
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
    );
    if (picked != null && mounted) {
      setState(() => start ? _start = picked : _end = picked);
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? '' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicine != null;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD7DDE6),
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
                    Text(
                      isEdit ? 'Edit medicine' : 'Add medicine',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

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
                          label: _start == null ? 'Start date' : _fmt(_start),
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

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
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
                                isEdit ? 'Save changes' : 'Add medicine',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7DDE6)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: placeholder
                    ? const Color(0xFF64748B)
                    : const Color(0xFF0A84FF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: placeholder
                      ? const Color(0xFF64748B)
                      : const Color(0xFF0F172A),
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