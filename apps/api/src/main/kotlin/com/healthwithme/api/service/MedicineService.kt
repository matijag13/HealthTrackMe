package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateMedicineRequest
import com.healthwithme.api.dto.MedicineDto
import com.healthwithme.api.dto.UpdateMedicineRequest
import com.healthwithme.api.model.Medicine
import com.healthwithme.api.repository.MedicineRepository
import com.healthwithme.api.repository.DoseLogRepository
import com.healthwithme.api.model.DoseLog
import com.healthwithme.api.model.DoseStatus
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class MedicineService(
    private val medicineRepository: MedicineRepository,
    private val userRepository: UserRepository
    ,
    private val doseLogRepository: DoseLogRepository
) {

    fun createMedicine(userId: Long, request: CreateMedicineRequest): MedicineDto {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        val medicine = Medicine(
            user = user,
            name = request.name,
            dosage = request.dosage,
            frequency = request.frequency,
            reason = request.reason,
            startDate = request.startDate?.let { java.time.LocalDate.parse(it) },
            endDate = request.endDate?.let { java.time.LocalDate.parse(it) },
            sideEffects = request.sideEffects,
            isActive = true,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val savedMedicine = medicineRepository.save(medicine)
        return toMedicineDto(savedMedicine)
    }

    fun getMedicineById(id: Long): MedicineDto {
        val medicine = medicineRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Medicine not found") }
        return toMedicineDto(medicine)
    }

    fun getMedicinesByUser(userId: Long): List<MedicineDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return medicineRepository.findByUserId(userId)
            .map { toMedicineDto(it) }
    }

    fun getActiveMedicinesByUser(userId: Long): List<MedicineDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return medicineRepository.findByUserIdAndIsActive(userId, true)
            .map { toMedicineDto(it) }
    }

    fun updateMedicine(id: Long, request: UpdateMedicineRequest): MedicineDto {
        val medicine = medicineRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Medicine not found") }
        
        val updatedMedicine = medicine.copy(
            dosage = request.dosage ?: medicine.dosage,
            frequency = request.frequency ?: medicine.frequency,
            reason = request.reason ?: medicine.reason,
            sideEffects = request.sideEffects ?: medicine.sideEffects,
            isActive = request.isActive ?: medicine.isActive,
            updatedAt = LocalDateTime.now()
        )
        
        val savedMedicine = medicineRepository.save(updatedMedicine)
        return toMedicineDto(savedMedicine)
    }

    fun logDose(medicationId: Long, date: java.time.LocalDate, time: java.time.LocalTime, statusStr: String): Map<String, Any> {
        val medication = medicineRepository.findById(medicationId)
            .orElseThrow { IllegalArgumentException("Medicine not found") }

        val scheduled = java.time.LocalDateTime.of(date, time)
        val status = try { DoseStatus.valueOf(statusStr) } catch (_: Exception) { DoseStatus.SCHEDULED }

        val dose = DoseLog(
            medication = medication,
            scheduledTime = scheduled,
            takenTime = if (status == DoseStatus.TAKEN) scheduled else null,
            status = status
        )

        doseLogRepository.save(dose)

        // compute adherence for all dose logs for this medication
        val logs = doseLogRepository.findByMedicationId(medicationId)
        val takenCount = logs.count { it.status == DoseStatus.TAKEN }
        val missedCount = logs.count { it.status == DoseStatus.MISSED }
        val relevant = takenCount + missedCount
        val percentage = if (relevant == 0) 0.0 else (takenCount.toDouble() / relevant.toDouble()) * 100.0

        val filtered = logs
        val daily = filtered.groupBy { it.scheduledTime.toLocalDate() }
            .map { (dateKey, list) -> mapOf("date" to dateKey.toString(), "status" to when {
                list.any { it.status == DoseStatus.TAKEN } -> "TAKEN"
                list.any { it.status == DoseStatus.MISSED } -> "MISSED"
                list.any { it.status == DoseStatus.SKIPPED } -> "SKIPPED"
                else -> "SCHEDULED"
            }) }

        return mapOf("percentage" to percentage, "takenCount" to takenCount, "missedCount" to missedCount, "dailyBreakdown" to daily)
    }

    fun getAdherence(medicationId: Long, days: Int?): Map<String, Any> {
        val medication = medicineRepository.findById(medicationId)
            .orElseThrow { IllegalArgumentException("Medicine not found") }

        val allLogs = doseLogRepository.findByMedicationIdOrderByScheduledTimeDesc(medicationId)
        val filtered = days?.let { d ->
            val cutoff = java.time.LocalDateTime.now().minusDays(d.toLong())
            allLogs.filter { it.scheduledTime.isAfter(cutoff) }
        } ?: allLogs

        val takenCount = filtered.count { it.status == DoseStatus.TAKEN }
        val missedCount = filtered.count { it.status == DoseStatus.MISSED }
        val dailyBreakdown = filtered.groupBy { it.scheduledTime.toLocalDate() }
            .map { (date, list) ->
                val status = when {
                    list.any { it.status == DoseStatus.TAKEN } -> "TAKEN"
                    list.any { it.status == DoseStatus.MISSED } -> "MISSED"
                    list.any { it.status == DoseStatus.SKIPPED } -> "SKIPPED"
                    else -> "SCHEDULED"
                }
                mapOf("date" to date.toString(), "status" to status)
            }

        val relevant = takenCount + missedCount
        val percentage = if (relevant == 0) 0.0 else (takenCount.toDouble() / relevant.toDouble()) * 100.0

        return mapOf(
            "percentage" to percentage,
            "takenCount" to takenCount,
            "missedCount" to missedCount,
            "dailyBreakdown" to dailyBreakdown
        )
    }

    fun deleteMedicine(id: Long): Boolean {
        medicineRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Medicine not found") }
        
        medicineRepository.deleteById(id)
        return true
    }

    private fun toMedicineDto(medicine: Medicine): MedicineDto {
        return MedicineDto(
            id = medicine.id,
            name = medicine.name,
            dosage = medicine.dosage,
            frequency = medicine.frequency,
            reason = medicine.reason,
            startDate = medicine.startDate?.toString(),
            endDate = medicine.endDate?.toString(),
            sideEffects = medicine.sideEffects,
            isActive = medicine.isActive
        )
    }
}

