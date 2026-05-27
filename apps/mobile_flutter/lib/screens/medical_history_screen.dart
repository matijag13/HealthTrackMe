import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final User user;
  const MedicalHistoryScreen({required this.user, super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final ApiService _api = ApiService.instance;
  late List<String> _chronic;
  late List<String> _allergies;
  late List<Map<String, dynamic>> _surgeries;
  late List<Map<String, dynamic>> _family;
  late List<Map<String, dynamic>> _vaccinations;
  String? _bloodType;
  bool _organDonor = false;

  final TextEditingController _chipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chronic = widget.user.chronicConditions ?? [];
    _allergies = widget.user.allergiesList ??
        (widget.user.allergies
                ?.split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList() ??
            []);
    _surgeries = widget.user.pastSurgeries ?? [];
    _family = widget.user.familyHistory ?? [];
    _vaccinations = widget.user.vaccinations ?? [];
    _bloodType = widget.user.bloodType;
    _organDonor = widget.user.organDonor ?? false;
  }

  void _addChronic(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _chronic.add(t);
    });
    _chipController.clear();
  }

  void _removeChronic(String value) {
    setState(() {
      _chronic.remove(value);
    });
  }

  Future<void> _save() async {
    final updated = User(
      id: widget.user.id,
      email: widget.user.email,
      firstName: widget.user.firstName,
      lastName: widget.user.lastName,
      dateOfBirth: widget.user.dateOfBirth,
      userType: widget.user.userType,
      medicalConditions: widget.user.medicalConditions,
      allergies: widget.user.allergies,
      isActive: widget.user.isActive,
      chronicConditions: _chronic,
      allergiesList: _allergies,
      pastSurgeries: _surgeries,
      familyHistory: _family,
      vaccinations: _vaccinations,
      bloodType: _bloodType,
      organDonor: _organDonor,
    );

    try {
      final saved = await _api.updateUser(widget.user.id, updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Medical history saved')));
      Navigator.of(context).pop(saved);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _chips(List<String> items, void Function(String) onDelete) {
    return Wrap(
        spacing: 8,
        children: items
            .map((c) => Chip(label: Text(c), onDeleted: () => onDelete(c)))
            .toList());
  }

  @override
  void dispose() {
    _chipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical history')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Chronic conditions',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 8),
          _chips(_chronic, _removeChronic),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _chipController,
                    decoration:
                        const InputDecoration(hintText: 'Add condition'))),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: () => _addChronic(_chipController.text),
                child: const Text('Add'))
          ]),
          const SizedBox(height: 16),
          const Text('Allergies',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 8),
          _chips(_allergies, (v) => setState(() => _allergies.remove(v))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    decoration: const InputDecoration(hintText: 'Add allergy'),
                    onSubmitted: (v) => setState(() => _allergies.add(v)))),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: () => setState(() {}), child: const Text('Add'))
          ]),
          const SizedBox(height: 16),
          const Text('Past surgeries',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 8),
          Column(
              children: _surgeries
                  .map((s) => ListTile(
                      title: Text(s['name'] ?? ''),
                      subtitle: Text('Year: ${s['year'] ?? ''}'),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              setState(() => _surgeries.remove(s)))))
                  .toList()),
          ElevatedButton(
              onPressed: () async {
                final nameCtrl = TextEditingController();
                final yearCtrl = TextEditingController();
                final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                            title: const Text('Add surgery'),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                      controller: nameCtrl,
                                      decoration: const InputDecoration(
                                          labelText: 'Name')),
                                  TextField(
                                      controller: yearCtrl,
                                      decoration: const InputDecoration(
                                          labelText: 'Year'))
                                ]),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Add'))
                            ]));
                if (ok == true)
                  setState(() => _surgeries.add({
                        'name': nameCtrl.text.trim(),
                        'year': int.tryParse(yearCtrl.text) ?? ''
                      }));
              },
              child: const Text('Add surgery')),
          const SizedBox(height: 16),
          const Text('Family history',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 8),
          Column(
              children: _family
                  .map((f) => ListTile(
                      title: Text(f['condition'] ?? ''),
                      subtitle: Text(f['relation'] ?? ''),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => _family.remove(f)))))
                  .toList()),
          ElevatedButton(
              onPressed: () async {
                final cond = TextEditingController();
                final rel = TextEditingController();
                final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                            title: const Text('Add family history'),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                      controller: cond,
                                      decoration: const InputDecoration(
                                          labelText: 'Condition')),
                                  TextField(
                                      controller: rel,
                                      decoration: const InputDecoration(
                                          labelText: 'Relation'))
                                ]),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Add'))
                            ]));
                if (ok == true)
                  setState(() => _family.add({
                        'condition': cond.text.trim(),
                        'relation': rel.text.trim()
                      }));
              },
              child: const Text('Add family history')),
          const SizedBox(height: 16),
          const Text('Vaccinations',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 8),
          Column(
              children: _vaccinations
                  .map((v) => ListTile(
                      title: Text(v['name'] ?? ''),
                      subtitle: Text('Date: ${v['date'] ?? ''}'),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              setState(() => _vaccinations.remove(v)))))
                  .toList()),
          ElevatedButton(
              onPressed: () async {
                final name = TextEditingController();
                final date = TextEditingController();
                final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                            title: const Text('Add vaccination'),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                      controller: name,
                                      decoration: const InputDecoration(
                                          labelText: 'Vaccine name')),
                                  TextField(
                                      controller: date,
                                      decoration: const InputDecoration(
                                          labelText: 'Date (YYYY-MM-DD)'))
                                ]),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Add'))
                            ]));
                if (ok == true)
                  setState(() => _vaccinations.add(
                      {'name': name.text.trim(), 'date': date.text.trim()}));
              },
              child: const Text('Add vaccination')),
          const SizedBox(height: 16),
          Row(children: [
            const Text('Blood type:'),
            const SizedBox(width: 12),
            DropdownButton<String>(
                value: _bloodType,
                hint: const Text('Select'),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v))
          ]),
          SwitchListTile(
              value: _organDonor,
              title: const Text('Organ donor'),
              onChanged: (v) => setState(() => _organDonor = v)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(
                child:
                    ElevatedButton(onPressed: _save, child: const Text('Save')))
          ]),
        ]),
      ),
    );
  }
}
