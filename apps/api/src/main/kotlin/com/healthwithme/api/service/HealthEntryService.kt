package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateHealthEntryRequest
import com.healthwithme.api.dto.HealthEntryDto
import com.healthwithme.api.dto.UpdateHealthEntryRequest
import com.healthwithme.api.model.HealthEntry
import com.healthwithme.api.repository.HealthEntryRepository
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
import java.time.LocalDate
import java.time.LocalDateTime

@Service
class HealthEntryService(
    private val healthEntryRepository: HealthEntryRepository,
    private val userRepository: UserRepository
) {

    fun createHealthEntry(userId: Long, request: CreateHealthEntryRequest): HealthEntryDto {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        val entry = HealthEntry(
            user = user,
            entryDate = LocalDate.parse(request.entryDate),
            wellbeingScore = request.wellbeingScore,
            symptoms = request.symptoms.joinToString(","),
            mood = request.mood,
            energyLevel = request.energyLevel,
            sleepHours = request.sleepHours,
            sleepQuality = request.sleepQuality,
            stressLevel = request.stressLevel,
            doctorNotes = request.notes,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val savedEntry = healthEntryRepository.save(entry)
        return toHealthEntryDto(savedEntry)
    }

    fun getHealthEntry(id: Long): HealthEntryDto {
        val entry = healthEntryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Health entry not found") }
        return toHealthEntryDto(entry)
    }

    fun getHealthEntriesByUser(userId: Long): List<HealthEntryDto> {
        // Verify user exists
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return healthEntryRepository.findByUserIdOrderByEntryDateDesc(userId)
            .map { toHealthEntryDto(it) }
    }

    fun updateHealthEntry(id: Long, request: UpdateHealthEntryRequest): HealthEntryDto {
        val entry = healthEntryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Health entry not found") }
        
        val updatedEntry = entry.copy(
            wellbeingScore = request.wellbeingScore ?: entry.wellbeingScore,
            symptoms = request.symptoms?.joinToString(",") ?: entry.symptoms,
            mood = request.mood ?: entry.mood,
            energyLevel = request.energyLevel ?: entry.energyLevel,
            sleepHours = request.sleepHours ?: entry.sleepHours,
            sleepQuality = request.sleepQuality ?: entry.sleepQuality,
            stressLevel = request.stressLevel ?: entry.stressLevel,
            doctorNotes = request.notes ?: entry.doctorNotes,
            updatedAt = LocalDateTime.now()
        )
        
        val savedEntry = healthEntryRepository.save(updatedEntry)
        return toHealthEntryDto(savedEntry)
    }

    fun deleteHealthEntry(id: Long): Boolean {
        val entry = healthEntryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Health entry not found") }
        
        healthEntryRepository.delete(entry)
        return true
    }

    fun getHealthEntriesByDateRange(userId: Long, startDate: String, endDate: String): List<HealthEntryDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return healthEntryRepository.findByUserIdAndEntryDateBetween(
            userId,
            LocalDate.parse(startDate),
            LocalDate.parse(endDate)
        )
            .map { toHealthEntryDto(it) }
    }

    private fun toHealthEntryDto(entry: HealthEntry): HealthEntryDto {
        return HealthEntryDto(
            id = entry.id,
            entryDate = entry.entryDate.toString(),
            wellbeingScore = entry.wellbeingScore,
            symptoms = entry.symptoms
                ?.split(",")
                ?.map { it.trim() }
                ?.filter { it.isNotBlank() }
                ?: emptyList(),
            mood = entry.mood,
            energyLevel = entry.energyLevel,
            sleepHours = entry.sleepHours,
            sleepQuality = entry.sleepQuality,
            stressLevel = entry.stressLevel,
            notes = entry.doctorNotes,
            createdAt = entry.createdAt.toString(),
            updatedAt = entry.updatedAt.toString()
        )
    }
}

