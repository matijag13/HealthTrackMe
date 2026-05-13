package com.healthwithme.api.controller

import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.repository.HealthEntryRepository
import com.healthwithme.api.repository.SportActivityRepository
import com.healthwithme.api.util.ExportUtil
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@RestController
@RequestMapping("/api/v1/export")
class ExportController(
    private val healthEntryRepository: HealthEntryRepository,
    private val sportActivityRepository: SportActivityRepository
) {

    @GetMapping("/health-entries/csv/{userId}")
    fun exportHealthEntriesCsv(@PathVariable userId: Long): ResponseEntity<String> {
        return try {
            val entries = healthEntryRepository.findByUserId(userId)
            
            if (entries.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NO_CONTENT).build()
            }
            
            val csv = ExportUtil.exportHealthEntriesToCsv(entries)
            
            val fileName = "health_entries_${LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HHmmss"))}.csv"
            
            ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"$fileName\"")
                .header(HttpHeaders.CONTENT_TYPE, "text/csv")
                .body(csv)
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build()
        }
    }

    @GetMapping("/sport-activities/csv/{userId}")
    fun exportSportActivitiesCsv(@PathVariable userId: Long): ResponseEntity<String> {
        return try {
            val activities = sportActivityRepository.findByUserId(userId)
            
            if (activities.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NO_CONTENT).build()
            }
            
            val csv = ExportUtil.exportSportActivitiesToCsv(activities)
            
            val fileName = "sport_activities_${LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HHmmss"))}.csv"
            
            ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"$fileName\"")
                .header(HttpHeaders.CONTENT_TYPE, "text/csv")
                .body(csv)
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build()
        }
    }

    @GetMapping("/summary/{userId}")
    fun getHealthSummary(@PathVariable userId: Long): ResponseEntity<ApiResponse<String>> {
        return try {
            val healthEntries = healthEntryRepository.findByUserId(userId)
            val activities = sportActivityRepository.findByUserId(userId)
            
            val summary = ExportUtil.generateHealthSummary(healthEntries, activities)
            
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "Health summary generated", data = summary)
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                ApiResponse(success = false, message = e.message, data = null)
            )
        }
    }

    @GetMapping("/all/{userId}")
    fun exportAllData(@PathVariable userId: Long): ResponseEntity<String> {
        return try {
            val healthEntries = healthEntryRepository.findByUserId(userId)
            val activities = sportActivityRepository.findByUserId(userId)
            
            val csv = StringBuilder()
            csv.append(ExportUtil.generateHealthSummary(healthEntries, activities))
            csv.append("\n\n=== HEALTH ENTRIES ===\n\n")
            csv.append(ExportUtil.exportHealthEntriesToCsv(healthEntries))
            csv.append("\n\n=== SPORT ACTIVITIES ===\n\n")
            csv.append(ExportUtil.exportSportActivitiesToCsv(activities))
            
            val fileName = "health_data_${LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HHmmss"))}.csv"
            
            ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"$fileName\"")
                .header(HttpHeaders.CONTENT_TYPE, "text/csv")
                .body(csv.toString())
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build()
        }
    }
}

