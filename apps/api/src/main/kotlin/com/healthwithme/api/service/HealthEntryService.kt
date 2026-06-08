package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateHealthEntryRequest
import com.healthwithme.api.dto.HealthEntryDto
import com.healthwithme.api.dto.SyncVitalsRequest
import com.healthwithme.api.dto.UpdateHealthEntryRequest
import com.healthwithme.api.model.HealthEntry
import com.healthwithme.api.repository.HealthEntryRepository
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.format.DateTimeFormatter

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
            measuredAt = request.measuredAt?.let { LocalDateTime.parse(it) },
            wellbeingScore = request.wellbeingScore,
            symptoms = request.symptoms.joinToString(","),
            mood = request.mood,
            energyLevel = request.energyLevel,
            sleepHours = request.sleepHours,
            sleepQuality = request.sleepQuality,
            weight = request.weight,
            heartRate = request.heartRate,
            systolicBp = request.systolicBp,
            diastolicBp = request.diastolicBp,
            bloodGlucose = request.bloodGlucose,
            bodyTemperature = request.bodyTemperature,
            spO2 = request.spO2,
            waterIntakeMl = request.waterIntakeMl,
            caloriesConsumed = request.caloriesConsumed,
            alcoholUnits = request.alcoholUnits,
            painLevel = request.painLevel,
            bedtime = request.bedtime?.let { LocalTime.parse(it) },
            wakeTime = request.wakeTime?.let { LocalTime.parse(it) },
            sleepQualityStars = request.sleepQualityStars,
            tags = request.tags?.joinToString(","),
            stressLevel = request.stressLevel,
            doctorNotes = request.notes,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val savedEntry = healthEntryRepository.save(entry)
        return toHealthEntryDto(savedEntry)
    }

    /**
     * Idempotent upsert for wearable-synced vitals. Updates the existing entry for that day in
     * place (only the fields the sync actually carries), or creates one with a neutral wellbeing
     * baseline if the day has no entry yet. This is what makes near-real-time foreground sync safe:
     * syncing the same day every couple of minutes mutates one row instead of inserting many.
     */
    fun upsertSyncedVitals(userId: Long, request: SyncVitalsRequest): HealthEntryDto {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }

        val date = LocalDate.parse(request.entryDate)
        val existing = healthEntryRepository
            .findByUserIdAndEntryDateOrderByCreatedAtDesc(userId, date)
            .firstOrNull()

        val entry = if (existing != null) {
            existing.copy(
                measuredAt = request.measuredAt?.let { LocalDateTime.parse(it) } ?: existing.measuredAt,
                heartRate = request.heartRate ?: existing.heartRate,
                sleepHours = request.sleepHours ?: existing.sleepHours,
                sleepQuality = request.sleepQuality ?: existing.sleepQuality,
                caloriesConsumed = request.caloriesConsumed ?: existing.caloriesConsumed,
                systolicBp = request.systolicBp ?: existing.systolicBp,
                diastolicBp = request.diastolicBp ?: existing.diastolicBp,
                spO2 = request.spO2 ?: existing.spO2,
                weight = request.weight ?: existing.weight,
                waterIntakeMl = request.waterIntakeMl ?: existing.waterIntakeMl,
                doctorNotes = request.notes ?: existing.doctorNotes,
                updatedAt = LocalDateTime.now()
            )
        } else {
            HealthEntry(
                user = user,
                entryDate = date,
                measuredAt = request.measuredAt?.let { LocalDateTime.parse(it) },
                // Neutral baseline only for a brand-new synced day; never overwrites a value the
                // user logged, because existing entries take the copy() branch above.
                wellbeingScore = 5,
                heartRate = request.heartRate,
                sleepHours = request.sleepHours,
                sleepQuality = request.sleepQuality,
                caloriesConsumed = request.caloriesConsumed,
                systolicBp = request.systolicBp,
                diastolicBp = request.diastolicBp,
                spO2 = request.spO2,
                weight = request.weight,
                waterIntakeMl = request.waterIntakeMl,
                doctorNotes = request.notes,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        }

        return toHealthEntryDto(healthEntryRepository.save(entry))
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
            measuredAt = request.measuredAt?.let { LocalDateTime.parse(it) } ?: entry.measuredAt,
            wellbeingScore = request.wellbeingScore ?: entry.wellbeingScore,
            symptoms = request.symptoms?.joinToString(",") ?: entry.symptoms,
            mood = request.mood ?: entry.mood,
            energyLevel = request.energyLevel ?: entry.energyLevel,
            sleepHours = request.sleepHours ?: entry.sleepHours,
            sleepQuality = request.sleepQuality ?: entry.sleepQuality,
            weight = request.weight ?: entry.weight,
            heartRate = request.heartRate ?: entry.heartRate,
            systolicBp = request.systolicBp ?: entry.systolicBp,
            diastolicBp = request.diastolicBp ?: entry.diastolicBp,
            bloodGlucose = request.bloodGlucose ?: entry.bloodGlucose,
            bodyTemperature = request.bodyTemperature ?: entry.bodyTemperature,
            spO2 = request.spO2 ?: entry.spO2,
            waterIntakeMl = request.waterIntakeMl ?: entry.waterIntakeMl,
            caloriesConsumed = request.caloriesConsumed ?: entry.caloriesConsumed,
            alcoholUnits = request.alcoholUnits ?: entry.alcoholUnits,
            painLevel = request.painLevel ?: entry.painLevel,
            bedtime = request.bedtime?.let { LocalTime.parse(it) } ?: entry.bedtime,
            wakeTime = request.wakeTime?.let { LocalTime.parse(it) } ?: entry.wakeTime,
            sleepQualityStars = request.sleepQualityStars ?: entry.sleepQualityStars,
            tags = request.tags?.joinToString(",") ?: entry.tags,
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
            measuredAt = entry.measuredAt?.toString(),
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
            weight = entry.weight,
            heartRate = entry.heartRate,
            systolicBp = entry.systolicBp,
            diastolicBp = entry.diastolicBp,
            bloodGlucose = entry.bloodGlucose,
            bodyTemperature = entry.bodyTemperature,
            spO2 = entry.spO2,
            waterIntakeMl = entry.waterIntakeMl,
            caloriesConsumed = entry.caloriesConsumed,
            alcoholUnits = entry.alcoholUnits,
            painLevel = entry.painLevel,
            bedtime = entry.bedtime?.toString(),
            wakeTime = entry.wakeTime?.toString(),
            sleepQualityStars = entry.sleepQualityStars,
            tags = entry.tags?.split(",")?.map { it.trim() } ?: emptyList(),
            stressLevel = entry.stressLevel,
            notes = entry.doctorNotes,
            createdAt = entry.createdAt.toString(),
            updatedAt = entry.updatedAt.toString()
        )
    }

    fun getVitalsHistory(userId: Long, metric: String, days: Int): List<com.healthwithme.api.dto.VitalPointDto> {
        // Verify user exists
        userRepository.findById(userId).orElseThrow { IllegalArgumentException("User not found") }

        val end = java.time.LocalDate.now()
        val start = end.minusDays(days.toLong())

        val entries = healthEntryRepository.findByUserIdAndEntryDateBetween(userId, start, end)
            .sortedBy { it.entryDate }

        return entries.map {
            val value: Double? = when (metric.lowercase()) {
                "weight" -> it.weight
                "heartrate", "heartRate".lowercase() -> it.heartRate?.toDouble()
                "bloodpressure", "blood_pressure", "bloodPressure".lowercase() -> it.systolicBp?.toDouble()
                "glucose" -> it.bloodGlucose
                "temperature" -> it.bodyTemperature
                "spo2" -> it.spO2?.toDouble()
                else -> null
            }

            val unit = when (metric.lowercase()) {
                "weight" -> "kg"
                "heartrate", "heartRate".lowercase() -> "bpm"
                "bloodpressure", "blood_pressure", "bloodPressure".lowercase() -> "mmHg"
                "glucose" -> "mg/dL"
                "temperature" -> "°C"
                "spo2" -> "%"
                else -> ""
            }

            com.healthwithme.api.dto.VitalPointDto(date = it.entryDate.toString(), value = value, unit = unit)
        }
    }
}

