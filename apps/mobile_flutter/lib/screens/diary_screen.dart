import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final ApiService apiService = ApiService();

  String selectedMood = '😊';
  double energyLevel = 65;
  double stressLevel = 30;
  List<String> selectedSymptoms = ['Glavobol', 'Utrujenost'];
  TextEditingController notesController = TextEditingController();

  final List<String> moods = ['😰', '😔', '😐', '😊', '🤩'];
  final List<String> symptoms = [
    'Glavobol',
    'Vrtoglavica',
    'Bolečine',
    'Utrujenost',
    'Slabost',
    'Zasoplost',
  ];

  void saveEntry() {
    final entry = HealthEntry(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      mood: selectedMood,
      energyLevel: energyLevel,
      stressLevel: stressLevel,
      symptoms: selectedSymptoms,
      notes: notesController.text,
    );

    apiService.createHealthEntry(entry).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vnos shranjen ✓')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Napaka: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dnevni vnos'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KAKO SE POČUTITE DANES?',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: moods
                          .map(
                            (mood) => MoodButton(
                              emoji: mood,
                              isSelected: selectedMood == mood,
                              onTap: () {
                                setState(() => selectedMood = mood);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Dobro',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Energy Level
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RAVEN ENERGIJE',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: 12),
                    HealthSlider(
                      value: energyLevel,
                      onChanged: (value) {
                        setState(() => energyLevel = value);
                      },
                      leftLabel: 'Izčrpan',
                      rightLabel: 'Poln energije',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Symptoms
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIMPTOMI DANES',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...symptoms
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
                        SymptomChip(
                          label: '+ Dodaj',
                          isSelected: false,
                          onTap: () {
                            // Open add symptom dialog
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Stress Level
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STRES',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: 12),
                    HealthSlider(
                      value: stressLevel,
                      onChanged: (value) {
                        setState(() => stressLevel = value);
                      },
                      leftLabel: 'Brez stresa',
                      rightLabel: 'Zelo pod stresom',
                      sliderColor: AppColors.teal,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Notes
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OPOMBA ZA ZDRAVNIKA',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Zjutraj rahel glavobol, popoldne boljše...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '💾 Shrani vnos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
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
