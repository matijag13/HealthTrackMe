package com.healthwithme.api.dto

import com.fasterxml.jackson.annotation.JsonProperty

data class DetectiveInsightDto(
    val id: Long,
    val badge: String,
    val title: String,
    val description: String,
    val finding: String,
    val correlations: Map<String, Any>? = null,
    val timeRange: String,
    val generatedAt: String,
    val createdAt: String
)

data class DetectiveInsightRequest(
    @JsonProperty("days")
    val daysBack: Int = 7  // Default to last 7 days
)

data class HealthCorrelation(
    val metric1: String,
    val metric2: String,
    val correlation: Double,
    val impact: String,
    val example: String
)

data class HealthPattern(
    val name: String,
    val description: String,
    val confidence: Double,
    val recommendation: String
)
