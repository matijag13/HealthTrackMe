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
    val isActive: Boolean
)

data class CreateMedicineRequest(
    val name: String,
    val dosage: String?,
    val frequency: String?,
    val reason: String?,
    val startDate: String?,
    val endDate: String?,
    val sideEffects: String?
)

data class UpdateMedicineRequest(
    val dosage: String?,
    val frequency: String?,
    val reason: String?,
    val sideEffects: String?,
    val isActive: Boolean?
)

