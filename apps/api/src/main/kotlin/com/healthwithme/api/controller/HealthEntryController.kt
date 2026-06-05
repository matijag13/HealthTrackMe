package com.healthwithme.api.controller

import com.healthwithme.api.dto.CreateHealthEntryRequest
import com.healthwithme.api.dto.HealthEntryDto
import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.dto.SyncVitalsRequest
import com.healthwithme.api.service.HealthEntryService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/health-entries")
class HealthEntryController(private val healthEntryService: HealthEntryService) {

    @PostMapping("/users/{userId}")
    fun createEntry(@PathVariable userId: Long, @RequestBody request: CreateHealthEntryRequest): ResponseEntity<ApiResponse<HealthEntryDto>> {
        return try {
            val entry = healthEntryService.createHealthEntry(userId, request)
            ResponseEntity.status(HttpStatus.CREATED).body(
                ApiResponse(success = true, message = "Entry created", data = entry)
            )
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null))
        }
    }

    @PostMapping("/users/{userId}/sync")
    fun syncEntry(@PathVariable userId: Long, @RequestBody request: SyncVitalsRequest): ResponseEntity<ApiResponse<HealthEntryDto>> {
        return try {
            val entry = healthEntryService.upsertSyncedVitals(userId, request)
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "Vitals synced", data = entry)
            )
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null))
        }
    }

    @GetMapping("/{id}")
    fun getEntry(@PathVariable id: Long): ResponseEntity<ApiResponse<HealthEntryDto>> {
        return try {
            val entry = healthEntryService.getHealthEntry(id)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Entry found", data = entry))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping("/users/{userId}")
    fun getUserEntries(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<HealthEntryDto>>> {
        return try {
            val entries = healthEntryService.getHealthEntriesByUser(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Entries found", data = entries))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping("/vitals-history")
    fun getVitalsHistory(@RequestParam userId: Long, @RequestParam metric: String, @RequestParam days: Int?): ResponseEntity<ApiResponse<List<com.healthwithme.api.dto.VitalPointDto>>> {
        return try {
            val d = days ?: 90
            val points = healthEntryService.getVitalsHistory(userId, metric, d)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Vitals history", data = points))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null))
        }
    }
}

