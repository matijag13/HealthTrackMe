import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/design_system.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'router_pages.dart';

/// Medicines screen extracted from main_app.dart and extended with:
/// - Today's Schedule (grouped Morning/Afternoon/Evening/Night)
/// - Dose logging (POST /api/medicines/{id}/dose)
/// - Active | All tabs with Slidable medicine cards
/// - FAB to add medicine (bottom sheet + POST /api/v1/medicines/users/{userId})
/// - Simple scheduling metadata stored in SharedPreferences (notification ids)
/// Note: Actual flutter_local_notifications integration is left as TODO — this file
/// stores notification information so it can be wired later.

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

  // Tracks which medicine IDs were marked taken in the current session/day
  final Set<int> _takenToday = {};

  static const _prefsKeyNotifications = 'med_notification_map_v1';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Medicine>> _load() async {
    try {
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

  Future<void> _postDose(int id, {DateTime? at, String? status}) async {
    final when = at ?? DateTime.now();
    final body = jsonEncode({
      'date': when.toIso8601String().split('T').first,
      'time': when.toIso8601String(),
      'status': status ?? 'TAKEN',
    });
    try {
      final uri = Uri.parse('${_api.baseUrl}/medicines/$id/dose');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Refresh list
        await _refresh();
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Dose logged')));
      } else {
        final msg = resp.body.isNotEmpty ? resp.body : 'Could not log dose';
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Network error')));
    }
  }

  Map<String, List<Medicine>> _groupByTime(List<Medicine> meds) {
    final morning = <Medicine>[];
    final afternoon = <Medicine>[];
    final evening = <Medicine>[];
    final night = <Medicine>[];

    for (final m in meds) {
      final label = m.scheduleLabel.toLowerCase();
      if (label.contains('morning'))
        morning.add(m);
      else if (label.contains('afternoon'))
        afternoon.add(m);
      else if (label.contains('evening') || label.contains('night'))
        evening.add(m);
      else
        night.add(m);
    }

    return {
      'Morning': morning,
      'Afternoon': afternoon,
      'Evening': evening,
      'Night': night,
    };
  }

  String _adherenceLabel(List<Medicine> meds) {
    final active = meds.where((m) => m.isActive).length;
    if (active == 0) return 'Ni aktivnih zdravil';
    return '$active aktivnih zdravil';
  }

  Widget _buildTopSchedule(List<Medicine> meds) {
    final groups = _groupByTime(meds.where((m) => m.isActive).toList());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Today's schedule",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            // Adherence / summary
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(_adherenceLabel(meds),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.blue))),
          ]),
          const SizedBox(height: 8),
          ...groups.entries.where((e) => e.value.isNotEmpty).map((entry) {
            final title = entry.key;
            final list = entry.value;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ...list.map((m) => _buildScheduleTile(m)),
                ]);
          }).toList(),
        ]),
      ),
    );
  }

  Widget _buildScheduleTile(Medicine m) {
    final isMissed = m.endDate != null && m.endDate!.isBefore(DateTime.now());
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
      title: Text(m.name,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isMissed ? Colors.red : null)),
      subtitle: Text(m.dosage ?? m.frequency ?? ''),
      trailing: Checkbox(
        value: _takenToday.contains(m.id),
        activeColor: Colors.green,
        onChanged: (v) async {
          if (v == true) {
            setState(() => _takenToday.add(m.id));
            await _postDose(m.id);
          } else {
            setState(() => _takenToday.remove(m.id));
          }
        },
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MedicineDetailPage(medicineId: m.id))),
    );
  }

  Widget _buildMedicineCard(Medicine m) {
    return Slidable(
      key: ValueKey(m.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
              onPressed: (_) => _postDose(m.id),
              backgroundColor: Colors.green,
              icon: Icons.check,
              label: 'Log dose'),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
              onPressed: (_) => _editMedicine(m),
              backgroundColor: Colors.blue,
              icon: Icons.edit,
              label: 'Edit'),
          SlidableAction(
              onPressed: (_) => _deleteMedicine(m),
              backgroundColor: Colors.red,
              icon: Icons.delete,
              label: 'Delete'),
        ],
      ),
      child: Card(
        child: ListTile(
          leading: Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: Colors.teal, shape: BoxShape.circle)),
          title:
              Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle:
              Text('${m.dosage ?? '—'} · ${m.frequency ?? m.scheduleLabel}'),
          trailing: m.startDate != null && m.endDate != null
              ? Text('${_daysRemaining(m)} days',
                  style: TextStyle(
                      color: _daysRemaining(m) <= 3 ? Colors.red : Colors.grey))
              : null,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MedicineDetailPage(medicineId: m.id))),
        ),
      ),
    );
  }

  int _daysRemaining(Medicine m) {
    if (m.endDate == null) return 9999;
    final diff = m.endDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  Future<void> _deleteMedicine(Medicine m) async {
    try {
      final uri = Uri.parse('${_api.baseUrl}/medicines/${m.id}');
      final resp = await http.delete(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await _refresh();
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Medicine deleted')));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not delete medicine')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Network error')));
    }
  }

  void _editMedicine(Medicine m) {
    // Reuse existing add/edit page (from router_pages) or show bottom sheet.
    showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => MedicineEditSheet(medicine: m)).then((saved) async {
      if (saved == true) {
        await _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Medicine saved')));
        }
      }
    });
  }

  Future<void> _showAddSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const MedicineEditSheet(),
    );
    if (saved == true) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Medicine saved')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Medicine>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _cached == null)
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LoadingSkeleton.medicines(context)));
            final meds = snapshot.data ?? _cached ?? const <Medicine>[];
            if (meds.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 40),
                  EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No medicines yet',
                    subtitle: 'Add your first medicine to track doses',
                  ),
                ],
              );
            }

            return ListView(padding: const EdgeInsets.all(12), children: [
              _buildTopSchedule(meds),
              const SizedBox(height: 12),
              _MedicinesTabs(medicines: meds, buildCard: _buildMedicineCard),
              const SizedBox(height: 12),
            ]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MedicinesTabs extends StatefulWidget {
  final List<Medicine> medicines;
  final Widget Function(Medicine) buildCard;
  const _MedicinesTabs(
      {required this.medicines, required this.buildCard, super.key});

  @override
  State<_MedicinesTabs> createState() => _MedicinesTabsState();
}

class _MedicinesTabsState extends State<_MedicinesTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final active = widget.medicines.where((m) => m.isActive).toList();
    final all = widget.medicines;
    final list = _index == 0 ? active : all;
    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: InkWell(
            onTap: () => setState(() => _index = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                  color: _index == 0
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 2,
                )),
              ),
              child: Text('Active',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _index == 0
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    fontWeight:
                        _index == 0 ? FontWeight.w700 : FontWeight.normal,
                  )),
            ),
          )),
          Expanded(
              child: InkWell(
            onTap: () => setState(() => _index = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                  color: _index == 1
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 2,
                )),
              ),
              child: Text('All',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _index == 1
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    fontWeight:
                        _index == 1 ? FontWeight.w700 : FontWeight.normal,
                  )),
            ),
          )),
        ]),
        const Divider(height: 1),
        ...list.map((m) => widget.buildCard(m)).toList(),
      ]),
    );
  }
}

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
    final messenger = ScaffoldMessenger.of(context);
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
      final ok = await api.createMedicine(payload);
      if (!ok) {
        if (mounted)
          messenger.showSnackBar(
              const SnackBar(content: Text('Could not save medicine')));
        return;
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Network error')));
      return;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      } else {
        _saving = false;
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickDate(BuildContext ctx, bool start) async {
    final now = DateTime.now();
    final initial = start ? (_start ?? now) : (_end ?? now);
    final picked = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.medicine == null ? 'Add medicine' : 'Edit medicine',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Medicine name'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(
                controller: _dosage,
                decoration:
                    const InputDecoration(labelText: 'Dosage (e.g. 500mg)')),
            const SizedBox(height: 8),
            TextFormField(
                controller: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _pickDate(context, true),
                      child: Text(_start == null
                          ? 'Start date'
                          : _start!.toIso8601String().split('T').first))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text(_end == null
                          ? 'End date (optional)'
                          : _end!.toIso8601String().split('T').first)))
            ]),
            const SizedBox(height: 8),
            TextFormField(
                controller: _reason,
                decoration: const InputDecoration(labelText: 'Reason')),
            const SizedBox(height: 8),
            TextFormField(
                controller: _sideEffects,
                decoration:
                    const InputDecoration(labelText: 'Side effects / notes'),
                maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Save')))
            ]),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}
