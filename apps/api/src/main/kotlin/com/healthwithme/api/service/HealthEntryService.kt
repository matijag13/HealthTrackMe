package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateHealthEntryRequest
import com.healthwithme.api.dto.HealthEntryDto
import com.healthwithme.api.dto.UpdateHealthEntryRequest
import com.healthwithme.api.model.HealthEntry
import com.healthwithme.api.repository.HealthEntryRepository
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
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
            entryDate = request.entryDate,
            symptoms = request.symptoms.toMutableList(),
            mood = request.mood,
            energyLevel = request.energyLevel,
            sleepHours = request.sleepHours,
            sleepQuality = request.sleepQuality,
            stressLevel = request.stressLevel,
            notes = request.notes,
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
            symptoms = request.symptoms?.toMutableList() ?: entry.symptoms,
            mood = request.mood ?: entry.mood,
            energyLevel = request.energyLevel ?: entry.energyLevel,
            sleepHours = request.sleepHours ?: entry.sleepHours,
            sleepQuality = request.sleepQuality ?: entry.sleepQuality,
            stressLevel = request.stressLevel ?: entry.stressLevel,
            notes = request.notes ?: entry.notes,
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
        
        return healthEntryRepository.findByUserIdAndEntryDateBetween(userId, startDate, endDate)
            .map { toHealthEntryDto(it) }
    }

    private fun toHealthEntryDto(entry: HealthEntry): HealthEntryDto {
        return HealthEntryDto(
            id = entry.id,
            entryDate = entry.entryDate,
            symptoms = entry.symptoms,
            mood = entry.mood,
            energyLevel = entry.energyLevel,
            sleepHours = entry.sleepHours,
            sleepQuality = entry.sleepQuality,
            stressLevel = entry.stressLevel,
            notes = entry.notes,
            createdAt = entry.createdAt.toString(),
            updatedAt = entry.updatedAt.toString()
        )
    }
}

