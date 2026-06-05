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

/**
 * Payload for idempotent wearable/health sync. All vitals are optional; the entry for the given
 * day is updated in place (or created once if absent), so repeated syncs never pile up duplicate
 * rows and never overwrite a wellbeing score the user logged themselves.
 */
data class SyncVitalsRequest(
    val entryDate: String,
    val measuredAt: String? = null,
    val heartRate: Int? = null,
    val sleepHours: Double? = null,
    val sleepQuality: String? = null,
    val caloriesConsumed: Int? = null,
    val systolicBp: Int? = null,
    val diastolicBp: Int? = null,
    val spO2: Int? = null,
    val weight: Double? = null,
    val notes: String? = null
)

