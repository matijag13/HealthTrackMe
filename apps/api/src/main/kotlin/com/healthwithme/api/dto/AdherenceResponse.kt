package com.healthwithme.api.dto

data class AdherenceDailyPoint(
    val date: String,
    val status: String
)

data class AdherenceResponse(
    val percentage: Double,
    val takenCount: Int,
    val missedCount: Int,
    val dailyBreakdown: List<AdherenceDailyPoint>
)

