package com.healthwithme.api.controller

import com.healthwithme.api.dto.HealthAlertDto
import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.service.HealthAlertService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/health-alerts")
class HealthAlertController(private val alertService: HealthAlertService) {

    @GetMapping("/{id}")
    fun getAlert(@PathVariable id: Long): ResponseEntity<ApiResponse<HealthAlertDto>> {
        return try {
            val alert = alertService.getAlertById(id)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Alert found", data = alert))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping("/users/{userId}")
    fun getUserAlerts(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<HealthAlertDto>>> {
        return try {
            val alerts = alertService.getAlertsByUser(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Alerts found", data = alerts))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping("/users/{userId}/unread")
    fun getUnreadAlerts(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<HealthAlertDto>>> {
        return try {
            val alerts = alertService.getUnreadAlerts(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Unread alerts found", data = alerts))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @PutMapping("/{id}/read")
    fun markAsRead(@PathVariable id: Long): ResponseEntity<ApiResponse<HealthAlertDto>> {
        return try {
            val alert = alertService.markAlertAsRead(id)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Alert marked", data = alert))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @DeleteMapping("/{id}")
    fun deleteAlert(@PathVariable id: Long): ResponseEntity<ApiResponse<Boolean>> {
        return try {
            val deleted = alertService.deleteAlert(id)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Alert deleted", data = deleted))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }
}

