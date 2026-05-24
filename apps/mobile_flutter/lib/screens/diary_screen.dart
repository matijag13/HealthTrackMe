import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final ApiService _api = ApiService.instance;

  String? selectedMood;
  double energyLevel = 50;
  double stressLevel = 50;
  List<String> selectedSymptoms = [];
  final TextEditingController notesController = TextEditingController();

  final List<String> moods = ['😰', '😔', '😐', '😊', '🤩'];
  final List<String> symptoms = [
    'Glavobol',
    'Vrtoglavica',
    'Bolečine',
    'Utrujenost',
    'Slabost',
    'Zasoplost',
  ];

  int _calculateWellbeingScore() {
    final score = ((energyLevel * 0.6) + ((100 - stressLevel) * 0.4)).round();
    return score.clamp(0, 100);
  }

  String _moodLabel(String? mood) {
    switch (mood) {
      case '😰':
        return 'Zelo slabo';
      case '😔':
        return 'Slabo';
      case '😐':
        return 'Nevtralno';
      case '😊':
        return 'Dobro';
      case '🤩':
        return 'Odlično';
      default:
        return 'Izberi počutje';
    }
  }

  Future<void> saveEntry() async {
    final activeUserId = _api.activeUserId;
    if (activeUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Najprej ustvari ali izberi račun v zavihku Profil.')));
      return;
    }

    final entry = HealthEntry(
      id: 0,
      entryDate: DateTime.now(),
      wellbeingScore: _calculateWellbeingScore(),
      symptoms: selectedSymptoms,
      mood: selectedMood,
      energyLevel: energyLevel.round(),
      sleepHours: null,
      sleepQuality: null,
      stressLevel: stressLevel.round(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );

    try {
      await _api.createHealthEntry(entry, userId: activeUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vnos shranjen ✅')));
      setState(() {
        selectedMood = null;
        selectedSymptoms = [];
        energyLevel = 50;
        stressLevel = 50;
        notesController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Napaka: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dnevni vnos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Dnevni vnos',
              subtitle: 'Vnesi počutje, simptome in opombe v enotnem, mirnem vmesniku.',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KAKO SE POČUTITE DANES?', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: moods
                          .map(
                            (mood) => MoodButton(
                              emoji: mood,
                              isSelected: selectedMood == mood,
                              onTap: () => setState(() => selectedMood = mood),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _moodLabel(selectedMood),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RAVEN ENERGIJE', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 12),
                    HealthSlider(
                      value: energyLevel,
                      onChanged: (value) => setState(() => energyLevel = value),
                      leftLabel: 'Izčrpan',
                      rightLabel: 'Poln energije',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIMPTOMI DANES', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: symptoms
                          .map(
                            (symptom) => SymptomChip(
                              label: symptom,
                              isSelected: selectedSymptoms.contains(symptom),
                              onTap: () {
                                setState(() {
                                  if (selectedSymptoms.contains(symptom)) {
                                    selectedSymptoms.remove(symptom);
                                  } else {
                                    selectedSymptoms.add(symptom);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STRES', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 12),
                    HealthSlider(
                      value: stressLevel,
                      onChanged: (value) => setState(() => stressLevel = value),
                      leftLabel: 'Brez stresa',
                      rightLabel: 'Zelo pod stresom',
                      sliderColor: AppColors.teal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OPOMBA ZA ZDRAVNIKA', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Zjutraj rahel glavobol, popoldne boljše...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  '💾 Shrani vnos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}
