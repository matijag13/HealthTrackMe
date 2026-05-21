package com.healthwithme.api.dto

data class HealthShieldResponseDto(
    val level: Int,
    val levelName: String,
    val totalConsistencyPoints: Int,
    val currentLevelStartPoints: Int,
    val nextLevelPoints: Int,
    val pointsToNextLevel: Int,
    val progressPercent: Int,
    val todayPoints: Int,
    val penaltyPoints: Int,
    val completedHabitsCount: Int,
    val consecutiveFailedDays: Int,
    val dailyBreakdown: HealthShieldDailyBreakdownDto?
)

data class HealthShieldDailyBreakdownDto(
    val supplementsPoints: Int,
    val sleepPoints: Int,
    val activityPoints: Int,
    val wellbeingPoints: Int,
    val symptomsPoints: Int,
    val routineStabilityPoints: Int,
    val penaltyPoints: Int,
    val totalDailyPoints: Int
)
