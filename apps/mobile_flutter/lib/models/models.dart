class HealthEntry {
  final String id;
  final DateTime date;
  final double? heartRate;
  final int? steps;
  final Duration? sleepDuration;
  final String? mood;
  final double? energyLevel;
  final List<String>? symptoms;
  final double? stressLevel;
  final String? notes;

  HealthEntry({
    required this.id,
    required this.date,
    this.heartRate,
    this.steps,
    this.sleepDuration,
    this.mood,
    this.energyLevel,
    this.symptoms,
    this.stressLevel,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'heartRate': heartRate,
      'steps': steps,
      'sleepDuration': sleepDuration?.inSeconds,
      'mood': mood,
      'energyLevel': energyLevel,
      'symptoms': symptoms,
      'stressLevel': stressLevel,
      'notes': notes,
    };
  }

  factory HealthEntry.fromJson(Map<String, dynamic> json) {
    return HealthEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      heartRate: json['heartRate']?.toDouble(),
      steps: json['steps'],
      sleepDuration: json['sleepDuration'] != null
          ? Duration(seconds: json['sleepDuration'])
          : null,
      mood: json['mood'],
      energyLevel: json['energyLevel']?.toDouble(),
      symptoms: List<String>.from(json['symptoms'] ?? []),
      stressLevel: json['stressLevel']?.toDouble(),
      notes: json['notes'],
    );
  }
}

class HealthAlertSummary {
  final String id;
  final String title;
  final String message;
  final String severity;
  final DateTime createdAt;

  HealthAlertSummary({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthAlertSummary.fromJson(Map<String, dynamic> json) {
    return HealthAlertSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Opozorilo',
      message: json['message']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'info',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final String color;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'times': times,
      'color': color,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      times: List<String>.from(json['times']),
      color: json['color'],
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
    );
  }
}

class HealthReport {
  final String id;
  final DateTime month;
  final double averageHeartRate;
  final int maxHeartRate;
  final Duration averageSleep;
  final int averageSteps;
  final double medicationAdherence;
  final Map<String, int> symptomFrequency;

  HealthReport({
    required this.id,
    required this.month,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.averageSleep,
    required this.averageSteps,
    required this.medicationAdherence,
    required this.symptomFrequency,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month.toIso8601String(),
      'averageHeartRate': averageHeartRate,
      'maxHeartRate': maxHeartRate,
      'averageSleep': averageSleep.inSeconds,
      'averageSteps': averageSteps,
      'medicationAdherence': medicationAdherence,
      'symptomFrequency': symptomFrequency,
    };
  }

  factory HealthReport.fromJson(Map<String, dynamic> json) {
    return HealthReport(
      id: json['id'],
      month: DateTime.parse(json['month']),
      averageHeartRate: json['averageHeartRate']?.toDouble() ?? 0,
      maxHeartRate: json['maxHeartRate'] ?? 0,
      averageSleep: Duration(seconds: json['averageSleep'] ?? 0),
      averageSteps: json['averageSteps'] ?? 0,
      medicationAdherence: json['medicationAdherence']?.toDouble() ?? 0,
      symptomFrequency: Map<String, int>.from(json['symptomFrequency'] ?? {}),
    );
  }
}

class DemoData {
  static List<HealthEntry> healthEntries() => [
        HealthEntry(
          id: 'demo-1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          heartRate: 72,
          steps: 6842,
          sleepDuration: const Duration(hours: 7, minutes: 20),
          mood: '😊',
          energyLevel: 0.65,
          symptoms: const ['Glavobol'],
          stressLevel: 0.3,
          notes: 'Rahlo glavobol zjutraj.',
        ),
        HealthEntry(
          id: 'demo-2',
          date: DateTime.now().subtract(const Duration(days: 2)),
          heartRate: 78,
          steps: 7412,
          sleepDuration: const Duration(hours: 6, minutes: 55),
          mood: '😐',
          energyLevel: 0.55,
          symptoms: const ['Utrujenost'],
          stressLevel: 0.42,
          notes: 'Bolj utrujen popoldne.',
        ),
      ];

  static List<Medicine> medicines() => [
        Medicine(
          id: 'med-1',
          name: 'Metformin 500mg',
          dosage: '500mg',
          times: const ['08:00'],
          color: '#4A90D9',
        ),
        Medicine(
          id: 'med-2',
          name: 'Ramipril 5mg',
          dosage: '5mg',
          times: const ['12:00'],
          color: '#E05252',
        ),
        Medicine(
          id: 'med-3',
          name: 'Vitamin D3',
          dosage: '1000 IU',
          times: const ['20:00'],
          color: '#2EC4B6',
        ),
      ];

  static List<HealthAlertSummary> alerts() => [
        HealthAlertSummary(
          id: 'alert-1',
          title: 'Srčni utrip',
          message: 'Zadnja 3 dni je srčni utrip v mirovanju povišan.',
          severity: 'warning',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];

  static HealthReport monthlyReport() => HealthReport(
        id: 'report-1',
        month: DateTime.now(),
        averageHeartRate: 74,
        maxHeartRate: 112,
        averageSleep: const Duration(hours: 7, minutes: 15),
        averageSteps: 7240,
        medicationAdherence: 0.87,
        symptomFrequency: const {
          'Glavobol': 18,
          'Utrujenost': 12,
          'Vrtoglavica': 6,
        },
      );
}

