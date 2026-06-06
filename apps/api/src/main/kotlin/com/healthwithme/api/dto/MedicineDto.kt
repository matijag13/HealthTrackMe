package com.healthwithme.api.dto

data class MedicineDto(
    val id: Long,
    val name: String,
    val dosage: String?,
    val frequency: String?,
    val reason: String?,
    val startDate: String?,
    val endDate: String?,
    val sideEffects: String?,
    val isActive: Boolean,
    // Comma-separated daily reminder times in HH:mm (e.g. "08:00,20:00").
    val reminderTimes: String? = null
)

data class CreateMedicineRequest(
    val name: String,
    val dosage: String?,
    val frequency: String?,
    val reason: String?,
    val startDate: String?,
    val endDate: String?,
    val sideEffects: String?,
    val reminderTimes: String? = null
)

data class UpdateMedicineRequest(
    val name: String?,
    val dosage: String?,
    val frequency: String?,
    val reason: String?,
    val startDate: String?,
    val endDate: String?,
    val sideEffects: String?,
    val isActive: Boolean?,
    val reminderTimes: String? = null
)

