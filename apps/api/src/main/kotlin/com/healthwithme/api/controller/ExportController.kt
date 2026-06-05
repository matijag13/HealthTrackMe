package com.healthwithme.api.controller

import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.repository.HealthEntryRepository
import com.healthwithme.api.repository.SportActivityRepository
import com.healthwithme.api.repository.UserRepository
import com.healthwithme.api.service.EmailService
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
    private val sportActivityRepository: SportActivityRepository,
    private val userRepository: UserRepository,
    private val emailService: EmailService
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
                ApiResponse(success = false, message = (e.message ?: "Internal server error"), data = null)
            )
        }
    }

    @PostMapping("/summary/email/{userId}")
    fun emailHealthSummary(@PathVariable userId: Long): ResponseEntity<ApiResponse<String>> {
        return try {
            val user = userRepository.findById(userId).orElse(null)
                ?: return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                    ApiResponse(success = false, message = "User not found", data = null)
                )

            val email = user.email
            val healthEntries = healthEntryRepository.findByUserId(userId)
            val activities = sportActivityRepository.findByUserId(userId)
            val summary = ExportUtil.generateHealthSummary(healthEntries, activities)

            val sent = emailService.sendPlainText(
                to = email,
                subject = "Your HealthTrackMe health summary",
                body = summary
            )

            if (!sent) {
                return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(
                    ApiResponse(
                        success = false,
                        message = "Email is not configured on the server",
                        data = null
                    )
                )
            }

            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "Summary sent to $email", data = email)
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                ApiResponse(success = false, message = (e.message ?: "Failed to send email"), data = null)
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

