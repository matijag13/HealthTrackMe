package com.healthwithme.api.controller

import com.healthwithme.api.dto.CreateSportActivityRequest
import com.healthwithme.api.dto.SportActivityDto
import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.service.SportActivityService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/sport-activities")
class SportActivityController(private val activityService: SportActivityService) {

    @PostMapping("/users/{userId}")
    fun createActivity(@PathVariable userId: Long, @RequestBody request: CreateSportActivityRequest): ResponseEntity<ApiResponse<SportActivityDto>> {
        return try {
            val activity = activityService.createActivity(userId, request)
            ResponseEntity.status(HttpStatus.CREATED).body(
                ApiResponse(success = true, message = "Activity created", data = activity)
            )
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null))
        }
    }

    @GetMapping("/{id}")
    fun getActivity(@PathVariable id: Long): ResponseEntity<ApiResponse<SportActivityDto>> {
        return try {
            val activity = activityService.getActivityById(id)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Activity found", data = activity))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping("/users/{userId}")
    fun getUserActivities(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<SportActivityDto>>> {
        return try {
            val activities = activityService.getActivitiesByUser(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Activities found", data = activities))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    // Raw entity endpoint (returns full SportActivity entities). Kept separate from DTO endpoint.
    @GetMapping("/users/{userId}/raw")
    fun getUserActivitiesRaw(@PathVariable userId: Long): ResponseEntity<List<com.healthwithme.api.model.SportActivity>> {
        return try {
            val activities = activityService.getRawActivitiesByUser(userId)
            ResponseEntity.ok(activities)
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.BAD_REQUEST).build()
        }
    }

    @GetMapping("/users/{userId}/stats")
    fun getStatistics(@PathVariable userId: Long): ResponseEntity<ApiResponse<Map<String, Any>>> {
        return try {
            val stats = activityService.getActivityStatistics(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Statistics", data = stats))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @DeleteMapping("/{id}")
    fun deleteActivity(@PathVariable id: Long): ResponseEntity<ApiResponse<Boolean>> {
        return try {
            val deleted = activityService.deleteActivity(id)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Activity deleted", data = deleted))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }
}

