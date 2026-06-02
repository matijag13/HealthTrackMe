package com.healthwithme.api.dto

data class HealthEntryDto(
    val id: Long,
    val entryDate: String,
    val measuredAt: String? = null,
    val wellbeingScore: Int,
    val symptoms: List<String>,
    val mood: String?,
    val energyLevel: Int?,
    val sleepHours: Double?,
    val sleepQuality: String?,
    val weight: Double?,
    val heartRate: Int?,
    val systolicBp: Int?,
    val diastolicBp: Int?,
    val bloodGlucose: Double?,
    val bodyTemperature: Double?,
    val spO2: Int?,
    val waterIntakeMl: Int?,
    val caloriesConsumed: Int?,
    val alcoholUnits: Double?,
    val painLevel: Int?,
    val bedtime: String?,
    val wakeTime: String?,
    val sleepQualityStars: Int?,
    val tags: List<String>?,
    val stressLevel: Int?,
    val notes: String?,
    val createdAt: String,
    val updatedAt: String
)

data class CreateHealthEntryRequest(
    val entryDate: String,
    val measuredAt: String? = null,
    val wellbeingScore: Int,
    val symptoms: List<String>,
    val mood: String?,
    val energyLevel: Int?,
    val sleepHours: Double?,
    val sleepQuality: String?,
    val weight: Double?,
    val heartRate: Int?,
    val systolicBp: Int?,
    val diastolicBp: Int?,
    val bloodGlucose: Double?,
    val bodyTemperature: Double?,
    val spO2: Int?,
    val waterIntakeMl: Int?,
    val caloriesConsumed: Int?,
    val alcoholUnits: Double?,
    val painLevel: Int?,
    val bedtime: String?,
    val wakeTime: String?,
    val sleepQualityStars: Int?,
    val tags: List<String>?,
    val stressLevel: Int?,
    val notes: String?
)

data class UpdateHealthEntryRequest(
    val measuredAt: String? = null,
    val wellbeingScore: Int?,
    val symptoms: List<String>?,
    val mood: String?,
    val energyLevel: Int?,
    val sleepHours: Double?,
    val sleepQuality: String?,
    val weight: Double?,
    val heartRate: Int?,
    val systolicBp: Int?,
    val diastolicBp: Int?,
    val bloodGlucose: Double?,
    val bodyTemperature: Double?,
    val spO2: Int?,
    val waterIntakeMl: Int?,
    val caloriesConsumed: Int?,
    val alcoholUnits: Double?,
    val painLevel: Int?,
    val bedtime: String?,
    val wakeTime: String?,
    val sleepQualityStars: Int?,
    val tags: List<String>?,
    val stressLevel: Int?,
    val notes: String?
)

data class HealthEntryFilterRequest(
    val startDate: String?,
    val endDate: String?,
    val symptom: String?
)

