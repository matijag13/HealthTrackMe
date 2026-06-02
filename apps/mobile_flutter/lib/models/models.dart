Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return [value.toString()];
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}

int? _tryParseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString());
}

double? _tryParseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _tryParseBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

class HealthEntry {
  final int id;
  final DateTime entryDate;
  final DateTime? measuredAt;
  final int? wellbeingScore;
  final List<String> symptoms;
  final String? mood;
  final int? energyLevel;
  final double? sleepHours;
  final String? sleepQuality;
  // new vitals
  final double? weight;
  final int? heartRate;
  final int? systolicBp;
  final int? diastolicBp;
  final double? bloodGlucose;
  final double? bodyTemperature;
  final int? spO2;
  final int? waterIntakeMl;
  final int? caloriesConsumed;
  final double? alcoholUnits;
  final int? painLevel;
  final String? bedtime;
  final String? wakeTime;
  final int? sleepQualityStars;
  final List<String>? tags;
  final int? stressLevel;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HealthEntry({
    required this.id,
    required this.entryDate,
    this.measuredAt,
    this.wellbeingScore,
    required this.symptoms,
    this.mood,
    this.energyLevel,
    this.sleepHours,
    this.sleepQuality,
    this.weight,
    this.heartRate,
    this.systolicBp,
    this.diastolicBp,
    this.bloodGlucose,
    this.bodyTemperature,
    this.spO2,
    this.waterIntakeMl,
    this.caloriesConsumed,
    this.alcoholUnits,
    this.painLevel,
    this.bedtime,
    this.wakeTime,
    this.sleepQualityStars,
    this.tags,
    this.stressLevel,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  DateTime get date => entryDate;

  int get effectiveWellbeingScore {
    if (wellbeingScore != null) return wellbeingScore!.clamp(0, 100);
    final energy = energyLevel ?? 0;
    final stress = stressLevel ?? 0;
    return ((energy * 0.6) + ((100 - stress) * 0.4)).round().clamp(0, 100);
  }

  double get effectiveSleepHours => sleepHours ?? 0.0;

  Map<String, dynamic> toJson() {
    // Backend expects wellbeingScore 0-10, not 0-100
    final scoreValue = wellbeingScore ?? effectiveWellbeingScore;
    final scaledScore =
        (scoreValue > 10) ? (scoreValue / 10).round() : scoreValue;
    return {
      'entryDate': _dateOnly(entryDate),
      if (measuredAt != null) 'measuredAt': measuredAt!.toIso8601String(),
      'wellbeingScore': scaledScore.clamp(0, 10),
      'symptoms': symptoms,
      'mood': mood,
      'energyLevel': energyLevel,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'weight': weight,
      'heartRate': heartRate,
      'systolicBp': systolicBp,
      'diastolicBp': diastolicBp,
      'bloodGlucose': bloodGlucose,
      'bodyTemperature': bodyTemperature,
      'spO2': spO2,
      'waterIntakeMl': waterIntakeMl,
      'caloriesConsumed': caloriesConsumed,
      'alcoholUnits': alcoholUnits,
      'painLevel': painLevel,
      'bedtime': bedtime,
      'wakeTime': wakeTime,
      'sleepQualityStars': sleepQualityStars,
      'tags': tags,
      'stressLevel': stressLevel,
      'notes': notes,
    };
  }

  factory HealthEntry.fromJson(dynamic json) {
    final map = _asMap(json);
    final energy = _tryParseInt(map['energyLevel']);
    final stress = _tryParseInt(map['stressLevel']);
    return HealthEntry(
      id: _tryParseInt(map['id']) ?? 0,
      entryDate:
          _tryParseDate(map['entryDate'] ?? map['date']) ?? DateTime.now(),
      measuredAt: _tryParseDate(map['measuredAt'] ?? map['measured_at']),
      wellbeingScore: _tryParseInt(map['wellbeingScore']),
      symptoms: _parseStringList(map['symptoms']),
      mood: map['mood']?.toString(),
      energyLevel: energy,
      sleepHours: _tryParseDouble(map['sleepHours'] ?? map['sleepDuration']),
      sleepQuality: map['sleepQuality']?.toString(),
      weight: _tryParseDouble(map['weight']),
      heartRate: _tryParseInt(map['heartRate']),
      systolicBp: _tryParseInt(map['systolicBp'] ?? map['systolic_bp']),
      diastolicBp: _tryParseInt(map['diastolicBp'] ?? map['diastolic_bp']),
      bloodGlucose:
          _tryParseDouble(map['bloodGlucose'] ?? map['blood_glucose']),
      bodyTemperature:
          _tryParseDouble(map['bodyTemperature'] ?? map['body_temperature']),
      spO2: _tryParseInt(map['spO2'] ?? map['spo2']),
      waterIntakeMl:
          _tryParseInt(map['waterIntakeMl'] ?? map['water_intake_ml']),
      caloriesConsumed:
          _tryParseInt(map['caloriesConsumed'] ?? map['calories_consumed']),
      alcoholUnits:
          _tryParseDouble(map['alcoholUnits'] ?? map['alcohol_units']),
      painLevel: _tryParseInt(map['painLevel'] ?? map['pain_level']),
      bedtime: _asString(map['bedtime'] ?? map['bed_time']),
      wakeTime: _asString(map['wakeTime'] ?? map['wake_time']),
      sleepQualityStars:
          _tryParseInt(map['sleepQualityStars'] ?? map['sleep_quality_stars']),
      tags: _parseStringList(map['tags']),
      stressLevel: stress,
      notes: map['notes']?.toString(),
      createdAt: _tryParseDate(map['createdAt']),
      updatedAt: _tryParseDate(map['updatedAt']),
    );
  }
}

class HealthAlertSummary {
  final int id;
  final String title;
  final String message;
  final String severity;
  final String? alertType;
  final String? triggerReason;
  final bool isRead;
  final String? actionRequired;
  final DateTime createdAt;

  const HealthAlertSummary({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.alertType,
    this.triggerReason,
    this.isRead = false,
    this.actionRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': message,
      'alertType': alertType,
      'severity': severity,
      'triggerReason': triggerReason,
      'isRead': isRead,
      'actionRequired': actionRequired,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthAlertSummary.fromJson(dynamic json) {
    final map = _asMap(json);
    return HealthAlertSummary(
      id: _tryParseInt(map['id']) ?? 0,
      title: _asString(map['title'], fallback: 'Opozorilo'),
      message: _asString(map['description'] ?? map['message']),
      severity: _asString(map['severity'], fallback: 'info'),
      alertType: map['alertType']?.toString(),
      triggerReason: map['triggerReason']?.toString(),
      isRead: _tryParseBool(map['isRead']),
      actionRequired: map['actionRequired']?.toString(),
      createdAt: _tryParseDate(map['createdAt']) ?? DateTime.now(),
    );
  }
}

class Medicine {
  final int id;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? reason;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sideEffects;
  final bool isActive;

  const Medicine({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.reason,
    this.startDate,
    this.endDate,
    this.sideEffects,
    required this.isActive,
  });

  String get scheduleLabel => frequency ?? dosage ?? 'Ni urnika';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'reason': reason,
      'startDate': startDate != null ? _dateOnly(startDate!) : null,
      'endDate': endDate != null ? _dateOnly(endDate!) : null,
      'sideEffects': sideEffects,
    };
  }

  factory Medicine.fromJson(dynamic json) {
    final map = _asMap(json);
    return Medicine(
      id: _tryParseInt(map['id']) ?? 0,
      name: _asString(map['name'], fallback: 'Unknown medicine'),
      dosage: map['dosage']?.toString(),
      frequency: map['frequency']?.toString(),
      reason: map['reason']?.toString(),
      startDate: _tryParseDate(map['startDate']),
      endDate: _tryParseDate(map['endDate']),
      sideEffects: map['sideEffects']?.toString(),
      isActive: _tryParseBool(map['isActive'], fallback: true),
    );
  }
}

class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String userType;
  final String? medicalConditions;
  final String? allergies;
  final bool isActive;

  // Extended profile / medical history fields (optional)
  final double? heightCm;
  final double? weightKg;
  final String? heightUnit; // 'cm' or 'ft'
  final String? gender;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<String>? chronicConditions; // e.g. ['Diabetes', 'Hypertension']
  final List<String>? allergiesList; // parsed allergies as list
  final List<Map<String, dynamic>>?
      pastSurgeries; // [{"name":"Appendix","year":2018}]
  final List<Map<String, dynamic>>?
      familyHistory; // [{"condition":"Heart disease","relation":"Father"}]
  final List<Map<String, dynamic>>?
      vaccinations; // [{"name":"MMR","date":"2020-01-01"}]
  final String? bloodType;
  final bool? organDonor;
  final String? doctorName;
  final String? doctorClinic;
  final String? doctorPhone;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? profilePhotoBase64;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.userType,
    this.medicalConditions,
    this.allergies,
    required this.isActive,
    this.heightCm,
    this.weightKg,
    this.heightUnit,
    this.gender,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.chronicConditions,
    this.allergiesList,
    this.pastSurgeries,
    this.familyHistory,
    this.vaccinations,
    this.bloodType,
    this.organDonor,
    this.doctorName,
    this.doctorClinic,
    this.doctorPhone,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.profilePhotoBase64,
  });

  String get fullName => [firstName, lastName]
      .where((part) => part.trim().isNotEmpty)
      .join(' ')
      .trim();

  String get initials {
    final parts =
        fullName.isNotEmpty ? fullName.split(RegExp(r'\s+')) : [email];
    final letters = parts
        .take(2)
        .map((part) => part.trim().isEmpty ? '' : part.trim()[0])
        .join();
    return letters.isEmpty ? 'U' : letters.toUpperCase();
  }

  Map<String, dynamic> toCreateJson({required String password}) {
    return {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'userType': userType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'userType': userType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'isActive': isActive,
    };

    if (heightCm != null) map['heightCm'] = heightCm;
    if (weightKg != null) map['weightKg'] = weightKg;
    if (heightUnit != null) map['heightUnit'] = heightUnit;
    if (gender != null) map['gender'] = gender;
    if (emergencyContactName != null) {
      map['emergencyContactName'] = emergencyContactName;
    }
    if (emergencyContactPhone != null) {
      map['emergencyContactPhone'] = emergencyContactPhone;
    }
    if (chronicConditions != null) map['chronicConditions'] = chronicConditions;
    if (allergiesList != null) map['allergiesList'] = allergiesList;
    if (pastSurgeries != null) map['pastSurgeries'] = pastSurgeries;
    if (familyHistory != null) map['familyHistory'] = familyHistory;
    if (vaccinations != null) map['vaccinations'] = vaccinations;
    if (bloodType != null) map['bloodType'] = bloodType;
    if (organDonor != null) map['organDonor'] = organDonor;
    if (doctorName != null) map['doctorName'] = doctorName;
    if (doctorClinic != null) map['doctorClinic'] = doctorClinic;
    if (doctorPhone != null) map['doctorPhone'] = doctorPhone;
    if (insuranceProvider != null) map['insuranceProvider'] = insuranceProvider;
    if (insurancePolicyNumber != null) {
      map['insurancePolicyNumber'] = insurancePolicyNumber;
    }
    if (profilePhotoBase64 != null) {
      map['profilePhotoBase64'] = profilePhotoBase64;
    }

    return map;
  }

  factory User.fromJson(dynamic json) {
    final map = _asMap(json);
    List<String>? parseListField(dynamic value) {
      final list = _parseStringList(value);
      return list.isEmpty ? null : list;
    }

    List<Map<String, dynamic>>? parseMapList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => Map<String, dynamic>.from(_asMap(e))).toList();
      }
      return null;
    }

    return User(
      id: _tryParseInt(map['id']) ?? 0,
      email: _asString(map['email']),
      firstName: _asString(map['firstName']),
      lastName: _asString(map['lastName']),
      dateOfBirth: _asString(map['dateOfBirth']),
      userType: _asString(map['userType'], fallback: 'PATIENT'),
      medicalConditions: map['medicalConditions']?.toString(),
      allergies: map['allergies']?.toString(),
      isActive: _tryParseBool(map['isActive'], fallback: true),
      heightCm: _tryParseDouble(map['heightCm']),
      heightUnit: _asString(map['heightUnit']),
      gender: _asString(map['gender']),
      emergencyContactName: _asString(map['emergencyContactName']),
      emergencyContactPhone: _asString(map['emergencyContactPhone']),
      chronicConditions: parseListField(map['chronicConditions']),
      allergiesList: parseListField(map['allergiesList'] ?? map['allergies']),
      pastSurgeries: parseMapList(map['pastSurgeries']),
      familyHistory: parseMapList(map['familyHistory']),
      vaccinations: parseMapList(map['vaccinations']),
      weightKg: _tryParseDouble(map['weightKg']),
      bloodType: _asString(map['bloodType']),
      organDonor: _tryParseBool(map['organDonor']),
      doctorName: _asString(map['doctorName']),
      doctorClinic: _asString(map['doctorClinic']),
      doctorPhone: _asString(map['doctorPhone']),
      insuranceProvider: _asString(map['insuranceProvider']),
      insurancePolicyNumber: _asString(map['insurancePolicyNumber']),
      profilePhotoBase64: _asString(map['profilePhotoBase64']),
    );
  }
}

class HealthReport {
  final String id;
  final DateTime month;
  final double averageWellbeingScore;
  final double averageSleepHours;
  final int entriesCount;
  final int activeMedicinesCount;
  final Map<String, int> symptomFrequency;

  const HealthReport({
    required this.id,
    required this.month,
    required this.averageWellbeingScore,
    required this.averageSleepHours,
    required this.entriesCount,
    required this.activeMedicinesCount,
    required this.symptomFrequency,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month.toIso8601String(),
      'averageWellbeingScore': averageWellbeingScore,
      'averageSleepHours': averageSleepHours,
      'entriesCount': entriesCount,
      'activeMedicinesCount': activeMedicinesCount,
      'symptomFrequency': symptomFrequency,
    };
  }

  factory HealthReport.fromJson(dynamic json) {
    final map = _asMap(json);
    final freq = <String, int>{};
    final rawFreq = map['symptomFrequency'];
    if (rawFreq is Map) {
      rawFreq.forEach((key, value) {
        freq[key.toString()] = _tryParseInt(value) ?? 0;
      });
    }

    return HealthReport(
      id: _asString(map['id'], fallback: 'report'),
      month: _tryParseDate(map['month']) ?? DateTime.now(),
      averageWellbeingScore:
          _tryParseDouble(map['averageWellbeingScore']) ?? 0.0,
      averageSleepHours: _tryParseDouble(map['averageSleepHours']) ?? 0.0,
      entriesCount: _tryParseInt(map['entriesCount']) ?? 0,
      activeMedicinesCount: _tryParseInt(map['activeMedicinesCount']) ?? 0,
      symptomFrequency: freq,
    );
  }

  factory HealthReport.fromEntries({
    required DateTime month,
    required List<HealthEntry> entries,
    required List<Medicine> medicines,
  }) {
    final inMonth = entries
        .where((entry) =>
            entry.entryDate.year == month.year &&
            entry.entryDate.month == month.month)
        .toList();
    final avgWellbeing = inMonth.isEmpty
        ? 0.0
        : inMonth
                .map((entry) => entry.effectiveWellbeingScore)
                .reduce((a, b) => a + b) /
            inMonth.length;

    final sleepEntries =
        inMonth.where((entry) => entry.sleepHours != null).toList();
    final avgSleep = sleepEntries.isEmpty
        ? 0.0
        : sleepEntries
                .map((entry) => entry.sleepHours!)
                .reduce((a, b) => a + b) /
            sleepEntries.length;

    final symptomFrequency = <String, int>{};
    for (final entry in inMonth) {
      for (final symptom in entry.symptoms) {
        symptomFrequency[symptom] = (symptomFrequency[symptom] ?? 0) + 1;
      }
    }

    return HealthReport(
      id: 'report-${month.year}-${month.month.toString().padLeft(2, '0')}',
      month: DateTime(month.year, month.month),
      averageWellbeingScore: avgWellbeing,
      averageSleepHours: avgSleep,
      entriesCount: inMonth.length,
      activeMedicinesCount:
          medicines.where((medicine) => medicine.isActive).length,
      symptomFrequency: symptomFrequency,
    );
  }
}

class HealthShieldDailyBreakdown {
  final int supplementsPoints;
  final int sleepPoints;
  final int activityPoints;
  final int wellbeingPoints;
  final int symptomsPoints;
  final int routineStabilityPoints;
  final int penaltyPoints;
  final int totalDailyPoints;

  const HealthShieldDailyBreakdown({
    required this.supplementsPoints,
    required this.sleepPoints,
    required this.activityPoints,
    required this.wellbeingPoints,
    required this.symptomsPoints,
    required this.routineStabilityPoints,
    required this.penaltyPoints,
    required this.totalDailyPoints,
  });

  factory HealthShieldDailyBreakdown.fromJson(dynamic json) {
    final map = _asMap(json);
    return HealthShieldDailyBreakdown(
      supplementsPoints: _tryParseInt(map['supplementsPoints']) ?? 0,
      sleepPoints: _tryParseInt(map['sleepPoints']) ?? 0,
      activityPoints: _tryParseInt(map['activityPoints']) ?? 0,
      wellbeingPoints: _tryParseInt(map['wellbeingPoints']) ?? 0,
      symptomsPoints: _tryParseInt(map['symptomsPoints']) ?? 0,
      routineStabilityPoints: _tryParseInt(map['routineStabilityPoints']) ?? 0,
      penaltyPoints: _tryParseInt(map['penaltyPoints']) ?? 0,
      totalDailyPoints: _tryParseInt(map['totalDailyPoints']) ?? 0,
    );
  }
}

class HealthShield {
  final int level;
  final String levelName;
  final int totalConsistencyPoints;
  final int currentLevelStartPoints;
  final int nextLevelPoints;
  final int pointsToNextLevel;
  final int progressPercent;
  final int todayPoints;
  final int penaltyPoints;
  final int completedHabitsCount;
  final int consecutiveFailedDays;
  final HealthShieldDailyBreakdown? dailyBreakdown;

  const HealthShield({
    required this.level,
    required this.levelName,
    required this.totalConsistencyPoints,
    required this.currentLevelStartPoints,
    required this.nextLevelPoints,
    required this.pointsToNextLevel,
    required this.progressPercent,
    required this.todayPoints,
    required this.penaltyPoints,
    required this.completedHabitsCount,
    required this.consecutiveFailedDays,
    this.dailyBreakdown,
  });

  factory HealthShield.fromJson(dynamic json) {
    final map = _asMap(json);
    final breakdownJson = map['dailyBreakdown'];
    return HealthShield(
      level: _tryParseInt(map['level']) ?? 1,
      levelName: _asString(map['levelName'], fallback: 'Basic Shield'),
      totalConsistencyPoints: _tryParseInt(map['totalConsistencyPoints']) ?? 0,
      currentLevelStartPoints:
          _tryParseInt(map['currentLevelStartPoints']) ?? 0,
      nextLevelPoints: _tryParseInt(map['nextLevelPoints']) ?? 0,
      pointsToNextLevel: _tryParseInt(map['pointsToNextLevel']) ?? 0,
      progressPercent: _tryParseInt(map['progressPercent']) ?? 0,
      todayPoints: _tryParseInt(map['todayPoints']) ?? 0,
      penaltyPoints: _tryParseInt(map['penaltyPoints']) ?? 0,
      completedHabitsCount: _tryParseInt(map['completedHabitsCount']) ?? 0,
      consecutiveFailedDays: _tryParseInt(map['consecutiveFailedDays']) ?? 0,
      dailyBreakdown: breakdownJson != null
          ? HealthShieldDailyBreakdown.fromJson(breakdownJson)
          : null,
    );
  }
}
