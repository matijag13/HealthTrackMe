package com.healthwithme.api.service

import com.healthwithme.api.dto.HealthShieldDailyBreakdownDto
import com.healthwithme.api.dto.HealthShieldResponseDto
import com.healthwithme.api.model.*
import com.healthwithme.api.repository.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import kotlin.math.roundToInt

@Service
class HealthShieldService(
    private val healthShieldStatusRepository: HealthShieldStatusRepository,
    private val healthShieldDailyPointsRepository: HealthShieldDailyPointsRepository,
    private val userRepository: UserRepository,
    private val medicationRepository: MedicationRepository,
    private val doseLogRepository: DoseLogRepository,
    private val sleepRecordRepository: SleepRecordRepository,
    private val activityLogRepository: ActivityLogRepository,
    private val healthEntryRepository: HealthEntryRepository
) {

    @Transactional
    fun getHealthShieldForUser(userId: Long): HealthShieldResponseDto {
        val user = userRepository.findById(userId)
            .orElseThrow { RuntimeException("User not found") }

        var status = healthShieldStatusRepository.findByUserId(userId)
        if (status == null) {
            status = HealthShieldStatus(user = user)
            status = healthShieldStatusRepository.save(status)
        }

        val today = LocalDate.now()
        var dailyPoints = healthShieldDailyPointsRepository.findByUserIdAndCalculationDate(userId, today)

        if (dailyPoints == null) {
            dailyPoints = calculateDailyPoints(user, today)
            
            // Only apply points if not already applied for today
            if (status.lastCalculatedDate != today) {
                applyDailyPointsToStatus(status, dailyPoints)
                status.lastCalculatedDate = today
                status.updatedAt = LocalDateTime.now()
                healthShieldStatusRepository.save(status)
            }
        }

        return buildResponseDto(status, dailyPoints)
    }

    private fun calculateDailyPoints(user: User, date: LocalDate): HealthShieldDailyPoints {
        var supplementsPoints = 0
        var sleepPoints = 0
        var activityPoints = 0
        var wellbeingPoints = 0
        var symptomsPoints = 0
        var completedHabits = 0

        // 1. Active medication or supplement items
        val activeItems = medicationRepository.findByUserIdAndActiveTrue(user.id)
        val hasActiveItems = activeItems.isNotEmpty()
        
        if (hasActiveItems) {
            // Simplified check: checking if there is any DoseLog for today with status TAKEN
            val startOfDay = date.atStartOfDay()
            val endOfDay = date.plusDays(1).atStartOfDay()
            
            var hasTakenDose = false
            for (item in activeItems) {
                val logs = doseLogRepository.findByMedicationId(item.id)
                val takenLogs = logs.filter { 
                    it.takenTime != null && 
                    !it.takenTime.isBefore(startOfDay) && 
                    it.takenTime.isBefore(endOfDay) &&
                    it.status.toString().equals("TAKEN",true) 
                }
                if (takenLogs.isNotEmpty()) {
                    hasTakenDose = true
                    break
                }
            }
            if (hasTakenDose) {
                supplementsPoints = 15
                completedHabits++
            }
        }

        // 2. Sleep
        val sleepRecords = sleepRecordRepository.findByUserIdAndSleepDate(user.id, date)
        if (sleepRecords.isNotEmpty()) {
            val totalSleepMinutes = sleepRecords.sumOf { it.durationMinutes }
            if (totalSleepMinutes >= 420) { // 7 hours
                sleepPoints = 20
                completedHabits++
            }
        }

        // 3. Activity
        val activityLogs = activityLogRepository.findByUserIdAndActivityDate(user.id, date)
        if (activityLogs.isNotEmpty()) {
            val totalSteps = activityLogs.sumOf { it.steps ?: 0 }
            if (totalSteps >= 6000) {
                activityPoints = 20
                completedHabits++
            }
        }

        // 4. Wellbeing & Symptoms
        val entry = healthEntryRepository.findByUserIdAndEntryDateOrderByCreatedAtDesc(user.id, date).firstOrNull()
        if (entry != null) {
            // Wellbeing score applies points
            wellbeingPoints = 15
            completedHabits++

            // Symptoms points applied if symptoms are populated
            if (!entry.symptoms.isNullOrBlank()) {
                symptomsPoints = 15
                completedHabits++
            }
        }

        // 5. Routine Stability
        var routineStabilityPoints = 0
        if (completedHabits >= 3) {
            routineStabilityPoints = if (hasActiveItems) 10 else 25
        }

        val dailyPoints = HealthShieldDailyPoints(
            user = user,
            calculationDate = date,
            supplementsPoints = supplementsPoints,
            sleepPoints = sleepPoints,
            activityPoints = activityPoints,
            wellbeingPoints = wellbeingPoints,
            symptomsPoints = symptomsPoints,
            routineStabilityPoints = routineStabilityPoints,
            completedHabitsCount = completedHabits
        )

        return healthShieldDailyPointsRepository.save(dailyPoints)
    }

    private fun applyDailyPointsToStatus(status: HealthShieldStatus, daily: HealthShieldDailyPoints) {
        val positivePoints = daily.supplementsPoints + daily.sleepPoints + daily.activityPoints + 
                             daily.wellbeingPoints + daily.symptomsPoints + daily.routineStabilityPoints

        if (daily.completedHabitsCount >= 2) {
            status.consecutiveFailedDays = 0
            daily.penaltyPoints = 0
        } else {
            status.consecutiveFailedDays += 1
            var calculatedPenalty = ((15.0 * status.consecutiveFailedDays) / 2.0).roundToInt()
            if (calculatedPenalty > 45) {
                calculatedPenalty = 45
            }
            daily.penaltyPoints = calculatedPenalty
        }

        daily.totalDailyPoints = positivePoints - daily.penaltyPoints
        
        status.totalConsistencyPoints += daily.totalDailyPoints
        if (status.totalConsistencyPoints < 0) {
            status.totalConsistencyPoints = 0
        }

        status.currentLevel = calculateLevel(status.totalConsistencyPoints)

        healthShieldDailyPointsRepository.save(daily)
    }

    private fun calculateLevel(points: Int): Int {
        var level = 1
        var requiredPoints = 0
        while (true) {
            val nextLevelRequired = requiredPoints + (level * 100)
            if (points >= nextLevelRequired) {
                requiredPoints = nextLevelRequired
                level++
            } else {
                break
            }
        }
        return level
    }

    private fun getPointsForLevel(level: Int): Int {
        var requiredPoints = 0
        for (i in 1 until level) {
            requiredPoints += (i * 100)
        }
        return requiredPoints
    }

    private fun getLevelName(level: Int): String {
        return when {
            level in 1..3 -> "Osnovni ščit"
            level in 4..6 -> "Stabilni ščit"
            level in 7..9 -> "Okrepljen ščit"
            level in 10..14 -> "Močni ščit"
            level in 15..20 -> "Napredni ščit"
            level in 21..30 -> "Zanesljivi ščit"
            else -> "Dolgoročni ščit"
        }
    }

    private fun buildResponseDto(status: HealthShieldStatus, daily: HealthShieldDailyPoints): HealthShieldResponseDto {
        val currentLevelStartPoints = getPointsForLevel(status.currentLevel)
        val nextLevelPoints = currentLevelStartPoints + (status.currentLevel * 100)
        val pointsToNextLevel = nextLevelPoints - status.totalConsistencyPoints
        
        val progressPercent = if (nextLevelPoints > currentLevelStartPoints) {
            val progress = status.totalConsistencyPoints - currentLevelStartPoints
            val range = nextLevelPoints - currentLevelStartPoints
            ((progress.toDouble() / range) * 100).roundToInt()
        } else {
            100
        }

        val breakdown = HealthShieldDailyBreakdownDto(
            supplementsPoints = daily.supplementsPoints,
            sleepPoints = daily.sleepPoints,
            activityPoints = daily.activityPoints,
            wellbeingPoints = daily.wellbeingPoints,
            symptomsPoints = daily.symptomsPoints,
            routineStabilityPoints = daily.routineStabilityPoints,
            penaltyPoints = daily.penaltyPoints,
            totalDailyPoints = daily.totalDailyPoints
        )

        return HealthShieldResponseDto(
            level = status.currentLevel,
            levelName = getLevelName(status.currentLevel),
            totalConsistencyPoints = status.totalConsistencyPoints,
            currentLevelStartPoints = currentLevelStartPoints,
            nextLevelPoints = nextLevelPoints,
            pointsToNextLevel = pointsToNextLevel,
            progressPercent = progressPercent,
            todayPoints = daily.totalDailyPoints,
            penaltyPoints = daily.penaltyPoints,
            completedHabitsCount = daily.completedHabitsCount,
            consecutiveFailedDays = status.consecutiveFailedDays,
            dailyBreakdown = breakdown
        )
    }
}
