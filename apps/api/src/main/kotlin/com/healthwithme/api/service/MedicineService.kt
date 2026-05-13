package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateMedicineRequest
import com.healthwithme.api.dto.MedicineDto
import com.healthwithme.api.dto.UpdateMedicineRequest
import com.healthwithme.api.model.Medicine
import com.healthwithme.api.repository.MedicineRepository
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class MedicineService(
    private val medicineRepository: MedicineRepository,
    private val userRepository: UserRepository
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

