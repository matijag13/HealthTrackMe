package com.healthwithme.api.dto

data class HealthAlertDto(
    val id: Long,
    val title: String,
    val description: String,
    val alertType: String,
    val severity: String,
    val triggerReason: String?,
    val isRead: Boolean,
    val actionRequired: String?,
    val createdAt: String
)

data class SportActivityDto(
    val id: Long,
    val activityType: String,
    val activityDate: String,
    val duration: Int?,
    val distance: Double?,
    val caloriesBurned: Int?,
    val steps: Int?,
    val intensity: String?,
    val averageHeartRate: Int?,
    val notes: String?,
    val createdAt: String
)

data class CreateSportActivityRequest(
    val activityType: String,
    val activityDate: String,
    val duration: Int?,
    val distance: Double?,
    val caloriesBurned: Int?,
    val steps: Int?,
    val intensity: String?,
    val averageHeartRate: Int?,
    val notes: String?
)

data class ApiResponse<T>(
    val success: Boolean,
    val message: String,
    val data: T?,
    val timestamp: String = java.time.LocalDateTime.now().toString()
)

data class PagedResponse<T>(
    val content: List<T>,
    val totalElements: Long,
    val totalPages: Int,
    val currentPage: Int,
    val size: Int,
    val isFirst: Boolean,
    val isLast: Boolean
)

