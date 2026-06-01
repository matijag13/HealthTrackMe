package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateSportActivityRequest
import com.healthwithme.api.dto.SportActivityDto
import com.healthwithme.api.model.SportActivity
import com.healthwithme.api.repository.SportActivityRepository
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class SportActivityService(
    private val activityRepository: SportActivityRepository,
    private val userRepository: UserRepository
) {

    fun createActivity(userId: Long, request: CreateSportActivityRequest): SportActivityDto {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        val activity = SportActivity(
            user = user,
            activityType = request.activityType,
            activityDate = request.activityDate,
            duration = request.duration,
            distance = request.distance,
            caloriesBurned = request.caloriesBurned,
            steps = request.steps,
            intensity = request.intensity,
            averageHeartRate = request.averageHeartRate,
            notes = request.notes,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val savedActivity = activityRepository.save(activity)
        return toActivityDto(savedActivity)
    }

    fun getActivityById(id: Long): SportActivityDto {
        val activity = activityRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Activity not found") }
        return toActivityDto(activity)
    }

    fun getActivitiesByUser(userId: Long): List<SportActivityDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return activityRepository.findByUserIdOrderByActivityDateDesc(userId)
            .map { toActivityDto(it) }
    }

    fun getActivitiesByDateRange(userId: Long, startDate: String, endDate: String): List<SportActivityDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return activityRepository.findByUserIdAndActivityDateBetween(userId, startDate, endDate)
            .map { toActivityDto(it) }
    }

    /**
     * Return raw SportActivity entities for a given user. Useful for admin/debug clients
     * that need the full entity instead of DTOs.
     */
    fun getRawActivitiesByUser(userId: Long): List<SportActivity> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }

        return activityRepository.findByUserIdOrderByActivityDateDesc(userId)
    }

    fun deleteActivity(id: Long): Boolean {
        activityRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Activity not found") }
        
        activityRepository.deleteById(id)
        return true
    }

    fun getActivityStatistics(userId: Long): Map<String, Any> {
        val activities = activityRepository.findByUserId(userId)
        
        val totalActivities = activities.size
        val totalDuration = activities.mapNotNull { it.duration }.sum()
        val totalDistance = activities.mapNotNull { it.distance }.sum()
        val totalCalories = activities.mapNotNull { it.caloriesBurned }.sum()
        val averageHeartRate = if (activities.isNotEmpty()) {
            activities.mapNotNull { it.averageHeartRate }.average()
        } else 0.0
        
        return mapOf(
            "totalActivities" to totalActivities,
            "totalDuration" to totalDuration,
            "totalDistance" to totalDistance,
            "totalCalories" to totalCalories,
            "averageHeartRate" to averageHeartRate
        )
    }

    private fun toActivityDto(activity: SportActivity): SportActivityDto {
        return SportActivityDto(
            id = activity.id,
            activityType = activity.activityType,
            activityDate = activity.activityDate,
            duration = activity.duration,
            distance = activity.distance,
            caloriesBurned = activity.caloriesBurned,
            steps = activity.steps,
            intensity = activity.intensity,
            averageHeartRate = activity.averageHeartRate,
            notes = activity.notes,
            createdAt = activity.createdAt.toString()
        )
    }
}

