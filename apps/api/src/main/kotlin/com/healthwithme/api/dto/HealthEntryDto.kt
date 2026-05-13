package com.healthwithme.api.dto

data class HealthEntryDto(
    val id: Long,
    val entryDate: String,
    val wellbeingScore: Int,
    val symptoms: List<String>,
    val mood: String?,
    val energyLevel: Int?,
    val sleepHours: Double?,
    val sleepQuality: String?,
    val stressLevel: Int?,
    val notes: String?,
    val createdAt: String,
    val updatedAt: String
)

data class CreateHealthEntryRequest(
    val entryDate: String,
    val wellbeingScore: Int,
    val symptoms: List<String>,
    val mood: String?,
    val energyLevel: Int?,
    val sleepHours: Double?,
    val sleepQuality: String?,
    val stressLevel: Int?,
    val notes: String?
)

data class UpdateHealthEntryRequest(
    val wellbeingScore: Int?,
    val symptoms: List<String>?,
    val mood: String?,
    val energyLevel: Int?,
    val sleepHours: Double?,
    val sleepQuality: String?,
    val stressLevel: Int?,
    val notes: String?
)

data class HealthEntryFilterRequest(
    val startDate: String?,
    val endDate: String?,
    val symptom: String?
)

