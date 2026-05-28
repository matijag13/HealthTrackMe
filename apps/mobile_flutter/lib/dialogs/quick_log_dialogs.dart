import 'package:flutter/material.dart';
import '../config/theme.dart';

// Mood Log Dialog
class MoodLogDialog extends StatefulWidget {
  const MoodLogDialog({Key? key}) : super(key: key);

  @override
  State<MoodLogDialog> createState() => _MoodLogDialogState();
}

class _MoodLogDialogState extends State<MoodLogDialog> {
  String? _selectedMood;
  final moods = [
    {'emoji': '😄', 'label': 'Great', 'value': 'great'},
    {'emoji': '😊', 'label': 'Good', 'value': 'good'},
    {'emoji': '😐', 'label': 'Okay', 'value': 'okay'},
    {'emoji': '😔', 'label': 'Bad', 'value': 'bad'},
    {'emoji': '😢', 'label': 'Terrible', 'value': 'terrible'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: moods.map((mood) {
                final isSelected = _selectedMood == mood['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood['value'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryOrange.withValues(alpha: 0.2)
                          : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryOrange : AppColors.darkBorder,
                        width: isSelected ? 2 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mood['emoji'] as String,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mood['label'] as String,
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMood != null
                    ? () => Navigator.pop(context, {'mood': _selectedMood})
                    : null,
                child: const Text('Log Mood'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Water Log Dialog
class WaterLogDialog extends StatefulWidget {
  const WaterLogDialog({Key? key}) : super(key: key);

  @override
  State<WaterLogDialog> createState() => _WaterLogDialogState();
}

class _WaterLogDialogState extends State<WaterLogDialog> {
  int _amount = 250; // ml

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Water Intake',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    '$_amount',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                  ),
                  Text(
                    'ml',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _amount.toDouble(),
              min: 100,
              max: 500,
              divisions: 8,
              activeColor: AppColors.primaryBlue,
              onChanged: (value) => setState(() => _amount = value.toInt()),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _amount = 250),
                    child: const Text('250ml'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _amount = 500),
                    child: const Text('500ml'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {'water_ml': _amount}),
                child: const Text('Log Water'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Medication Log Dialog
class MedicationLogDialog extends StatefulWidget {
  const MedicationLogDialog({Key? key}) : super(key: key);

  @override
  State<MedicationLogDialog> createState() => _MedicationLogDialogState();
}

class _MedicationLogDialogState extends State<MedicationLogDialog> {
  final medications = [
    'Metformin 500mg',
    'Lisinopril 10mg',
    'Atorvastatin 20mg',
  ];
  String? _selectedMedication;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark Medication as Taken',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Column(
              children: medications.map((med) {
                final isSelected = _selectedMedication == med;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMedication = med),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen.withValues(alpha: 0.1)
                            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : AppColors.darkBorder,
                          width: isSelected ? 2 : 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primaryGreen : AppColors.darkBorder,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              med,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMedication != null
                    ? () => Navigator.pop(context, {'medication': _selectedMedication})
                    : null,
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Symptom Log Dialog
class SymptomLogDialog extends StatefulWidget {
  const SymptomLogDialog({Key? key}) : super(key: key);

  @override
  State<SymptomLogDialog> createState() => _SymptomLogDialogState();
}

class _SymptomLogDialogState extends State<SymptomLogDialog> {
  final symptoms = [
    'Headache',
    'Nausea',
    'Fatigue',
    'Dizziness',
    'Pain',
    'Fever',
  ];
  final List<String> _selectedSymptoms = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Symptoms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: symptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSymptoms.remove(symptom);
                      } else {
                        _selectedSymptoms.add(symptom);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryOrange.withValues(alpha: 0.2)
                          : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryOrange : AppColors.darkBorder,
                        width: isSelected ? 2 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      symptom,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isSelected ? AppColors.primaryOrange : null,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSymptoms.isNotEmpty
                    ? () => Navigator.pop(context, {'symptoms': _selectedSymptoms})
                    : null,
                child: const Text('Log Symptoms'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sleep Log Dialog
class SleepLogDialog extends StatefulWidget {
  const SleepLogDialog({Key? key}) : super(key: key);

  @override
  State<SleepLogDialog> createState() => _SleepLogDialogState();
}

class _SleepLogDialogState extends State<SleepLogDialog> {
  int _hours = 7;
  int _minutes = 30;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Sleep',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      SizedBox(
                        width: 60,
                        child: TextField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: '$_hours'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            final val = int.tryParse(value);
                            if (val != null && val >= 0 && val <= 24) {
                              setState(() => _hours = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'h',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: '$_minutes'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            final val = int.tryParse(value);
                            if (val != null && val >= 0 && val <= 59) {
                              setState(() => _minutes = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'm',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: ${_hours}h ${_minutes}m',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  {'sleep_hours': _hours, 'sleep_minutes': _minutes},
                ),
                child: const Text('Log Sleep'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
