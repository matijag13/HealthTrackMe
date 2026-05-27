import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../utils/health_utils.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

// Renamed and redesigned diary -> Log screen
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService.instance;

  // Form state
  String? selectedMood;
  double energyLevel = 50;
  double stressLevel = 50;
  double sleepHours = 8.0;
  TimeOfDay? bedtime;
  TimeOfDay? waketime;
  int sleepQualityStars = 3;

  // Sleep tracking checkboxes
  bool hadDreams = false;
  bool wokeUpDuringNight = false;
  bool usedSleepAid = false;
  bool menstrualCycleTracking = false;
  double painLevel = 0;

  // Vitals
  final TextEditingController weightController = TextEditingController();
  bool weightIsKg = true;
  final TextEditingController heartController = TextEditingController();
  final TextEditingController systolicController = TextEditingController();
  final TextEditingController diastolicController = TextEditingController();
  final TextEditingController glucoseController = TextEditingController();
  bool glucoseIsMg = false;
  final TextEditingController tempController = TextEditingController();
  bool tempIsC = true;
  final TextEditingController spo2Controller = TextEditingController();

  // Activity
  final TextEditingController stepsController = TextEditingController();
  final TextEditingController activeMinutesController = TextEditingController();

  // Nutrition
  final TextEditingController waterController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  int alcoholUnits = 0;

  // Notes / tags / symptoms
  final TextEditingController notesController = TextEditingController();
  List<String> selectedSymptoms = [];
  List<String> symptomOptions = [
    'Headache',
    'Dizziness',
    'Pain',
    'Fatigue',
    'Nausea',
    'Shortness of breath',
    'High stress'
  ];
  List<String> tags = [
    'work',
    'family',
    'travel',
    'sick',
    'period',
    'hangover'
  ];
  final TextEditingController customTagController = TextEditingController();
  List<String> selectedTags = [];

  // State
  bool _loading = true;
  List<HealthEntry> _entries = [];
  bool _todayLogged = false;
  HealthEntry? _todayEntry;
  bool _saving = false;

  final List<String> moods = ['😰', '😔', '😐', '😊', '🤩'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final entries = await _api.getHealthEntries();
    final today = DateTime.now();
    final todays = entries
        .where((e) =>
            e.entryDate.year == today.year &&
            e.entryDate.month == today.month &&
            e.entryDate.day == today.day)
        .toList();
    setState(() {
      _entries = entries;
      _todayLogged = todays.isNotEmpty;
      _todayEntry = todays.isNotEmpty ? todays.first : null;
      if (_todayEntry != null) _populateFromEntry(_todayEntry!);
      _loading = false;
    });
  }

  void _populateFromEntry(HealthEntry e) {
    selectedMood = e.mood;
    energyLevel = (e.energyLevel ?? 50).toDouble();
    stressLevel = (e.stressLevel ?? 50).toDouble();
    sleepHours = e.sleepHours ?? 8.0;
    selectedSymptoms = List.from(e.symptoms);

    // The notes field is stored as a JSON blob. Extract only the human-written
    // 'notes' sub-key so we never show raw JSON in the text field.
    final raw = e.notes ?? '';
    notesController.text = extractNote(raw);

    // Restore vitals from the stored JSON so editing a day repopulates fields
    try {
      if (raw.startsWith('{')) {
        final decoded = Map<String, dynamic>.from(jsonDecode(raw));
        final vitals = decoded['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          weightController.text = vitals['weight']?.toString() ?? '';
          heartController.text = vitals['heartRate']?.toString() ?? '';
          tempController.text = vitals['temp']?.toString() ?? '';
          spo2Controller.text = vitals['spo2']?.toString() ?? '';
          final bp = vitals['bp']?.toString() ?? '/';
          final parts = bp.split('/');
          if (parts.length == 2) {
            systolicController.text = parts[0];
            diastolicController.text = parts[1];
          }
        }
        final nutrition = decoded['nutrition'] as Map<String, dynamic>?;
        if (nutrition != null) {
          waterController.text = nutrition['waterMl']?.toString() ?? '';
          caloriesController.text = nutrition['calories']?.toString() ?? '';
          alcoholUnits = (nutrition['alcoholUnits'] as num?)?.toInt() ?? 0;
        }
        final activity = decoded['activity'] as Map<String, dynamic>?;
        if (activity != null) {
          stepsController.text = activity['steps']?.toString() ?? '';
          activeMinutesController.text =
              activity['activeMinutes']?.toString() ?? '';
        }
      }
    } catch (_) {}

    // Also restore directly stored vitals (new entries use explicit fields)
    if (e.heartRate != null && heartController.text.isEmpty)
      heartController.text = e.heartRate.toString();
    if (e.weight != null && weightController.text.isEmpty)
      weightController.text = e.weight.toString();
    if (e.waterIntakeMl != null && waterController.text.isEmpty)
      waterController.text = e.waterIntakeMl.toString();
    if (e.caloriesConsumed != null && caloriesController.text.isEmpty)
      caloriesController.text = e.caloriesConsumed.toString();
  }

  int _calculateWellbeingScore() {
    final score = ((energyLevel * 0.6) + ((100 - stressLevel) * 0.4)) / 10;
    return score.round().clamp(0, 10);
  }

  Future<void> _saveEntry() async {
    final activeUserId = _api.activeUserId;
    if (activeUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select an account in Profile first.')));
      return;
    }

    setState(() => _saving = true);

    final vitals = {
      'weight': weightController.text,
      'weightUnit': weightIsKg ? 'kg' : 'lb',
      'heartRate': heartController.text,
      'bp': '${systolicController.text}/${diastolicController.text}',
      'glucose': glucoseController.text,
      'glucoseUnit': glucoseIsMg ? 'mg/dL' : 'mmol/L',
      'temp': tempController.text,
      'tempUnit': tempIsC ? 'C' : 'F',
      'spo2': spo2Controller.text,
    };

    final nutrition = {
      'waterMl': waterController.text,
      'calories': caloriesController.text,
      'alcoholUnits': alcoholUnits,
    };

    final payloadNotes = {
      'notes': notesController.text.trim(),
      'vitals': vitals,
      'nutrition': nutrition,
      'tags': tags,
      'sleep': {
        'hadDreams': hadDreams,
        'wokeUpDuringNight': wokeUpDuringNight,
        'usedSleepAid': usedSleepAid,
        'bedtime': bedtime?.format(context) ?? '',
        'waketime': waketime?.format(context) ?? '',
      },
      'pain': painLevel,
      'menstrualTracking': menstrualCycleTracking,
    };

    // If user entered steps in the quick field, include it inside notes.activity so
    // the app can surface steps on dashboard even when sport-activities endpoint
    // isn't relied upon. Also populate HealthEntry vitals/nutrition fields so they
    // are visible immediately in UI and exported properly.
    final int? parsedWater = int.tryParse(waterController.text);
    final int? parsedCalories = int.tryParse(caloriesController.text);
    final int? parsedSteps = int.tryParse(stepsController.text);

    if (parsedSteps != null && parsedSteps > 0) {
      payloadNotes['activity'] = {
        'steps': parsedSteps,
        'activeMinutes': int.tryParse(activeMinutesController.text) ?? 0
      };
    }

    final entry = HealthEntry(
      id: 0,
      entryDate: DateTime.now(),
      wellbeingScore: _calculateWellbeingScore(),
      symptoms: selectedSymptoms,
      mood: selectedMood,
      energyLevel: energyLevel.round(),
      sleepHours: sleepHours,
      sleepQuality: sleepQualityStars >= 4
          ? 'GOOD'
          : (sleepQualityStars >= 2 ? 'FAIR' : 'POOR'),
      stressLevel: stressLevel.round(),
      // map vitals/nutrition into explicit fields the backend recognizes
      weight: double.tryParse(weightController.text),
      heartRate: int.tryParse(heartController.text),
      systolicBp: int.tryParse(systolicController.text),
      diastolicBp: int.tryParse(diastolicController.text),
      bloodGlucose: double.tryParse(glucoseController.text),
      bodyTemperature: double.tryParse(tempController.text),
      spO2: int.tryParse(spo2Controller.text),
      waterIntakeMl: parsedWater,
      caloriesConsumed: parsedCalories,
      alcoholUnits: (alcoholUnits > 0) ? alcoholUnits.toDouble() : null,
      painLevel: painLevel.round(),
      bedtime: bedtime?.format(context),
      wakeTime: waketime?.format(context),
      sleepQualityStars: sleepQualityStars,
      tags: selectedTags.isNotEmpty ? selectedTags : tags,
      notes: jsonEncode(payloadNotes),
    );

    try {
      await _api.createHealthEntry(entry, userId: activeUserId);
      if (!mounted) return;
      setState(() => _saving = false);

      // Show success then reload - use a local context reference
      final ctx = context;
      if (!mounted) return;

      await showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => const Center(child: _SuccessAnim()),
      );

      if (mounted) await _loadEntries();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  void _addCustomTag() {
    final t = customTagController.text.trim();
    if (t.isEmpty) return;
    setState(() {
      tags.add(t);
      customTagController.clear();
    });
  }

  void _openActivityBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ActivityForm(onSaved: (map) async {
          try {
            await _api.createSportActivity(map);
          } catch (_) {}
          if (mounted) Navigator.of(context).pop();
        }),
      ),
    );
  }

  Future<void> _openHistory() async {
    // Push a full-screen page with AppBar so the user has a clear Back button
    final parentContext = context;
    await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diary history')),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: DateTime.now(),
                  eventLoader: (day) {
                    final found = _entries
                        .where((e) =>
                            e.entryDate.year == day.year &&
                            e.entryDate.month == day.month &&
                            e.entryDate.day == day.day)
                        .toList();
                    return found;
                  },
                  calendarBuilders:
                      CalendarBuilders(markerBuilder: (context, day, events) {
                    if (events.isEmpty) return const SizedBox();
                    return Positioned(
                        bottom: 4,
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                                events.length.clamp(0, 3),
                                (_) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                        color: AppColors.teal,
                                        shape: BoxShape.circle)))));
                  }),
                  onDaySelected: (selected, focused) {
                    final found = _entries
                        .where((e) =>
                            e.entryDate.year == selected.year &&
                            e.entryDate.month == selected.month &&
                            e.entryDate.day == selected.day)
                        .toList();
                    if (found.isNotEmpty) {
                      Navigator.of(ctx).pop();
                      // navigate to read-only view using parent context so GoRouter works at root
                      parentContext.goNamed('diaryDate', pathParameters: {
                        'date': selected.toIso8601String().split('T').first
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final todayLabel =
        '${DateTime.now().toLocal().toIso8601String().split('T').first}';

    return Scaffold(
      appBar: AppBar(
          title: Row(children: [
        const Icon(Icons.calendar_today),
        const SizedBox(width: 8),
        Text('Today — $todayLabel')
      ])),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'diary_history',
        onPressed: _openHistory,
        icon: const Icon(Icons.calendar_month),
        label: const Text('History'),
      ),
      body: _loading
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LoadingSkeleton.profile(context)))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_todayLogged)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.4)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(children: [
                                      Icon(Icons.check_circle,
                                          color: Color(0xFF4CAF50), size: 18),
                                      SizedBox(width: 8),
                                      Text('Today already logged',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ]),
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _todayLogged = false),
                                      child: const Text('Update',
                                          style: TextStyle(fontSize: 13)),
                                    ),
                                  ]),
                            ),
                          ),
                        const SizedBox(height: 10),

                        // SECTION 1 - Mood & quick
                        _sectionHeader('How you feel', Icons.mood),
                        ExpansionTile(
                          initiallyExpanded: true,
                          title: const Text('How do you feel?'),
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: moods
                                  .map(
                                    (m) => GestureDetector(
                                      onTap: () =>
                                          setState(() => selectedMood = m),
                                      child: Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: selectedMood == m
                                              ? AppColors.softBlue
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: selectedMood == m
                                                ? AppColors.blue
                                                : AppColors.border,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: Center(
                                            child: Text(m,
                                                style: const TextStyle(
                                                    fontSize: 24))),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            const Text('Energy'),
                            HealthSlider(
                                value: energyLevel,
                                onChanged: (v) =>
                                    setState(() => energyLevel = v),
                                leftLabel: '0',
                                rightLabel: '100'),
                            const SizedBox(height: 6),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('0'),
                                  Text('${energyLevel.round()}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blue)),
                                  const Text('100'),
                                ]),
                            const SizedBox(height: 8),
                            const Text('Stress'),
                            HealthSlider(
                                value: stressLevel,
                                onChanged: (v) =>
                                    setState(() => stressLevel = v),
                                leftLabel: '0',
                                rightLabel: '100',
                                sliderColor: AppColors.danger),
                            const SizedBox(height: 6),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('0'),
                                  Text('${stressLevel.round()}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blue)),
                                  const Text('100'),
                                ]),
                            const SizedBox(height: 8),
                            _sectionHeader('Notes', Icons.edit_note),
                            TextField(
                                controller: notesController,
                                minLines: 2,
                                maxLines: 5,
                                decoration: InputDecoration(
                                    hintText:
                                        'How was your day? Any symptoms or observations...',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)))),
                            const SizedBox(height: 8),
                            Wrap(
                                spacing: 6,
                                children: tags
                                    .map((t) => FilterChip(
                                          label: Text('#$t'),
                                          selected: selectedTags.contains(t),
                                          onSelected: (v) => setState(() => v
                                              ? selectedTags.add(t)
                                              : selectedTags.remove(t)),
                                          selectedColor: AppColors.softBlue,
                                          checkmarkColor: AppColors.blue,
                                        ))
                                    .toList()),
                            const SizedBox(height: 6),
                            Row(children: [
                              Expanded(
                                  child: TextField(
                                      controller: customTagController,
                                      decoration: InputDecoration(
                                          hintText: 'Add tag',
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8))))),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                  onPressed: _addCustomTag,
                                  child: const Text('Add'))
                            ]),
                            const SizedBox(height: 8),
                            Wrap(
                                spacing: 6,
                                children: symptomOptions
                                    .map((s) => SymptomChip(
                                        label: s,
                                        isSelected:
                                            selectedSymptoms.contains(s),
                                        onTap: () => setState(() =>
                                            selectedSymptoms.contains(s)
                                                ? selectedSymptoms.remove(s)
                                                : selectedSymptoms.add(s))))
                                    .toList()),
                            const SizedBox(height: 8),
                          ],
                        ),

                        // SECTION 2 - Vitals
                        _sectionHeader('Vitals', Icons.favorite),
                        ExpansionTile(title: const Text('Vitals'), children: [
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: weightController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                        labelText: 'Weight',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))))),
                            const SizedBox(width: 8),
                            DropdownButton<bool>(
                                value: weightIsKg,
                                items: const [
                                  DropdownMenuItem(
                                      value: true, child: Text('kg')),
                                  DropdownMenuItem(
                                      value: false, child: Text('lb'))
                                ],
                                onChanged: (v) =>
                                    setState(() => weightIsKg = v ?? true))
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: heartController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText: 'Heart rate (bpm)',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))))),
                            const SizedBox(width: 8),
                            IconButton(
                                onPressed: () => _showInfo('Resting heart rate',
                                    'Measure resting HR for 1 minute, device should be at rest'),
                                icon: const Icon(Icons.info_outline))
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: systolicController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText: 'Systolic',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: TextField(
                                    controller: diastolicController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText: 'Diastolic',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))))),
                            const SizedBox(width: 8),
                            IconButton(
                                onPressed: () => _showInfo(
                                    'Blood pressure', 'Normal: ~120/80 mmHg'),
                                icon: const Icon(Icons.info_outline))
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: glucoseController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                        labelText: 'Blood glucose',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))))),
                            const SizedBox(width: 8),
                            DropdownButton<bool>(
                                value: glucoseIsMg,
                                items: const [
                                  DropdownMenuItem(
                                      value: false, child: Text('mmol/L')),
                                  DropdownMenuItem(
                                      value: true, child: Text('mg/dL'))
                                ],
                                onChanged: (v) =>
                                    setState(() => glucoseIsMg = v ?? false))
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: tempController,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                        labelText: 'Temperature',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))))),
                            const SizedBox(width: 8),
                            DropdownButton<bool>(
                                value: tempIsC,
                                items: const [
                                  DropdownMenuItem(
                                      value: true, child: Text('°C')),
                                  DropdownMenuItem(
                                      value: false, child: Text('°F'))
                                ],
                                onChanged: (v) =>
                                    setState(() => tempIsC = v ?? true))
                          ]),
                          const SizedBox(height: 8),
                          TextField(
                              controller: spo2Controller,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: 'SpO2 (%)',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)))),
                          const SizedBox(height: 8),
                        ]),

                        // SECTION 3 - Sleep
                        _sectionHeader('Sleep', Icons.bedtime),
                        ExpansionTile(title: const Text('Sleep'), children: [
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: Text(
                                    'Duration: ${sleepHours.toStringAsFixed(1)} h')),
                            Slider(
                                value: sleepHours,
                                min: 0,
                                max: 12,
                                divisions: 24,
                                onChanged: (v) =>
                                    setState(() => sleepHours = v))
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: Text('Bedtime')),
                            const SizedBox(width: 8),
                            TextButton(
                                onPressed: () async {
                                  final t = await showTimePicker(
                                      context: context,
                                      initialTime: bedtime ??
                                          TimeOfDay(hour: 23, minute: 0));
                                  if (t != null) setState(() => bedtime = t);
                                },
                                child:
                                    Text(bedtime?.format(context) ?? '23:00')),
                            const SizedBox(width: 16),
                            Expanded(child: Text('Wake')),
                            const SizedBox(width: 8),
                            TextButton(
                                onPressed: () async {
                                  final t = await showTimePicker(
                                      context: context,
                                      initialTime: waketime ??
                                          TimeOfDay(hour: 7, minute: 30));
                                  if (t != null) setState(() => waketime = t);
                                },
                                child:
                                    Text(waketime?.format(context) ?? '07:30'))
                          ]),
                          const SizedBox(height: 8),
                          Row(
                              children: List.generate(
                                  5,
                                  (i) => IconButton(
                                      icon: Icon(
                                          i < sleepQualityStars
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: AppColors.navy),
                                      onPressed: () => setState(
                                          () => sleepQualityStars = i + 1)))),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                              title: const Text('Had dreams'),
                              value: hadDreams,
                              onChanged: (v) =>
                                  setState(() => hadDreams = v ?? false)),
                          CheckboxListTile(
                              title: const Text('Woke up during night'),
                              value: wokeUpDuringNight,
                              onChanged: (v) => setState(
                                  () => wokeUpDuringNight = v ?? false)),
                          CheckboxListTile(
                              title: const Text('Used sleep aid'),
                              value: usedSleepAid,
                              onChanged: (v) =>
                                  setState(() => usedSleepAid = v ?? false)),
                        ]),

                        // SECTION 4 - Activity & Steps
                        _sectionHeader('Activity', Icons.directions_walk),
                        ExpansionTile(
                            title: const Text('Activity & Steps'),
                            children: [
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    child: TextField(
                                        controller: stepsController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                            labelText: 'Steps',
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8))))),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                    onPressed: () => setState(() =>
                                        stepsController.text = ((int.tryParse(
                                                        stepsController.text) ??
                                                    0) +
                                                200)
                                            .toString()),
                                    child: const Text('+200'))
                              ]),
                              const SizedBox(height: 8),
                              TextField(
                                  controller: activeMinutesController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                      labelText: 'Active minutes',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)))),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                  onPressed: _openActivityBottomSheet,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Workout')),
                            ]),

                        // SECTION 5 - Nutrition
                        _sectionHeader('Nutrition', Icons.local_dining),
                        ExpansionTile(
                            title: const Text('Nutrition'),
                            children: [
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    child: TextField(
                                        controller: waterController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                            labelText: 'Water (ml)',
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8))))),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                    onPressed: () => setState(() =>
                                        waterController.text = ((int.tryParse(
                                                        waterController.text) ??
                                                    0) +
                                                200)
                                            .toString()),
                                    child: const Text('+200ml'))
                              ]),
                              const SizedBox(height: 8),
                              TextField(
                                  controller: caloriesController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                      labelText: 'Calories consumed',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)))),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Text('Alcohol units'),
                                const SizedBox(width: 8),
                                IconButton(
                                    onPressed: () => setState(() =>
                                        alcoholUnits =
                                            (alcoholUnits - 1).clamp(0, 10)),
                                    icon: const Icon(Icons.remove)),
                                Text('$alcoholUnits'),
                                IconButton(
                                    onPressed: () => setState(() =>
                                        alcoholUnits =
                                            (alcoholUnits + 1).clamp(0, 10)),
                                    icon: const Icon(Icons.add))
                              ]),
                            ]),

                        // SECTION 6 - Additional tracking
                        ExpansionTile(
                            title: const Text('Additional Tracking'),
                            children: [
                              const SizedBox(height: 8),
                              Row(children: [
                                const Text('Pain level'),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Slider(
                                        value: painLevel,
                                        min: 0,
                                        max: 10,
                                        divisions: 10,
                                        onChanged: (v) =>
                                            setState(() => painLevel = v)))
                              ]),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                  title: const Text('Menstrual cycle tracking'),
                                  value: menstrualCycleTracking,
                                  onChanged: (v) => setState(() =>
                                      menstrualCycleTracking = v ?? false)),
                            ]),

                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveEntry,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppColors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                disabledBackgroundColor: AppColors.muted,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Save entry',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                            )),
                        const SizedBox(height: 40),
                      ]),
                ),
              ],
            ),
    );
  }

  void _showInfo(String title, String text) {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(title),
                content: Text(text),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('OK'))
                ]));
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                  letterSpacing: 1.2)),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ]),
      );

  @override
  void dispose() {
    weightController.dispose();
    heartController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    glucoseController.dispose();
    tempController.dispose();
    spo2Controller.dispose();
    stepsController.dispose();
    activeMinutesController.dispose();
    waterController.dispose();
    caloriesController.dispose();
    notesController.dispose();
    customTagController.dispose();
    super.dispose();
  }
}

// Small success animation used after save
class _SuccessAnim extends StatefulWidget {
  const _SuccessAnim({Key? key}) : super(key: key);

  @override
  State<_SuccessAnim> createState() => _SuccessAnimState();
}

class _SuccessAnimState extends State<_SuccessAnim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctr = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600))
    ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctr, curve: Curves.elasticOut),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child:
            const Icon(Icons.check_circle, size: 84, color: AppColors.success),
      ),
    );
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }
}

// Activity form bottom sheet (minimal)
class _ActivityForm extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onSaved;
  const _ActivityForm({required this.onSaved, Key? key}) : super(key: key);

  @override
  State<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<_ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  String type = 'Running';
  final durationCtrl = TextEditingController();
  final distanceCtrl = TextEditingController();
  final caloriesCtrl = TextEditingController();
  String intensity = 'Moderate';
  final notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Add workout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop())
        ]),
        Form(
            key: _formKey,
            child: Column(children: [
              DropdownButtonFormField<String>(
                  value: type,
                  items: [
                    'Running',
                    'Walking',
                    'Cycling',
                    'Swimming',
                    'Gym',
                    'Yoga',
                    'HIIT',
                    'Other'
                  ]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v ?? type)),
              const SizedBox(height: 8),
              TextFormField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Duration (min)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              if (['Running', 'Walking', 'Cycling', 'Swimming'].contains(type))
                TextFormField(
                    controller: distanceCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Distance (km)',
                        border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextFormField(
                  controller: caloriesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Calories burned',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                  value: intensity,
                  items: ['Light', 'Moderate', 'Hard', 'Max']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => intensity = v ?? intensity)),
              const SizedBox(height: 8),
              TextFormField(
                  controller: notesCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Notes', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () {
                            final map = {
                              'type': type,
                              'durationMinutes':
                                  int.tryParse(durationCtrl.text) ?? 0,
                              'distanceKm':
                                  double.tryParse(distanceCtrl.text) ?? 0.0,
                              'calories': int.tryParse(caloriesCtrl.text) ?? 0,
                              'intensity': intensity,
                              'notes': notesCtrl.text,
                              'start': DateTime.now().toIso8601String(),
                            };
                            widget.onSaved(map);
                          },
                          child: const Text('Save')))
                ],
              )
            ]))
      ]),
    );
  }
}
