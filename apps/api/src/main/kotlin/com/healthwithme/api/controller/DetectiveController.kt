package com.healthwithme.api.controller

import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.dto.DetectiveInsightDto
import com.healthwithme.api.dto.DetectiveInsightRequest
import com.healthwithme.api.model.TimeRange
import com.healthwithme.api.service.HealthDetectiveService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/detective")
class DetectiveController(
    private val detectiveService: HealthDetectiveService
) {

    /**
     * Generate a new health insight for the user
     * GET /api/v1/detective/analyze?userId=1&days=7
     */
    @GetMapping("/analyze")
    fun analyzeHealth(
        @RequestParam userId: Long,
        @RequestParam(defaultValue = "7") days: Int,
        @RequestParam(defaultValue = "en") language: String
    ): ResponseEntity<ApiResponse<DetectiveInsightDto>> {
        return try {
            val insight = detectiveService.generateHealthInsight(userId, days, language)
            ResponseEntity.ok(
                ApiResponse(
                    success = true,
                    message = "Health insight generated",
                    data = insight
                )
            )
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(
                ApiResponse(
                    success = false,
                    message = e.message ?: "Failed to generate insight",
                    data = null
                )
            )
        }
    }

    /**
     * Get the latest cached insight for the user
     * GET /api/v1/detective/latest?userId=1&timeRange=WEEK
     */
    @GetMapping("/latest")
    fun getLatestInsight(
        @RequestParam userId: Long,
        @RequestParam(defaultValue = "WEEK") timeRange: String
    ): ResponseEntity<ApiResponse<DetectiveInsightDto?>> {
        return try {
            val range = TimeRange.valueOf(timeRange.uppercase())
            val insight = detectiveService.getCachedInsight(userId, range)

            ResponseEntity.ok(
                ApiResponse(
                    success = true,
                    message = if (insight != null) "Latest insight found" else "No cached insight available",
                    data = insight
                )
            )
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().body(
                ApiResponse(
                    success = false,
                    message = "Invalid time range. Use: WEEK, MONTH, ALL_TIME",
                    data = null
                )
            )
        }
    }

    /**
     * Get insight history for the user
     * GET /api/v1/detective/history?userId=1&limit=10
     */
    @GetMapping("/history")
    fun getInsightHistory(
        @RequestParam userId: Long,
        @RequestParam(defaultValue = "10") limit: Int
    ): ResponseEntity<ApiResponse<List<DetectiveInsightDto>>> {
        return try {
            val history = detectiveService.getInsightHistory(userId, limit)

            ResponseEntity.ok(
                ApiResponse(
                    success = true,
                    message = "Insight history retrieved",
                    data = history
                )
            )
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(
                ApiResponse(
                    success = false,
                    message = e.message ?: "Failed to retrieve history",
                    data = null
                )
            )
        }
    }

    /**
     * Analyze specific health question (future enhancement)
     * POST /api/v1/detective/ask
     */
    @PostMapping("/ask")
    fun askDetective(
        @RequestParam userId: Long,
        @RequestBody request: Map<String, String>
    ): ResponseEntity<ApiResponse<Map<String, String>>> {
        return try {
            val question = request["question"] ?: ""
            val language = request["language"] ?: "en"
            val answer = detectiveService.answerQuestion(userId, question, language = language)

            ResponseEntity.ok(
                ApiResponse(
                    success = true,
                    message = "Answer generated",
                    data = answer
                )
            )
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(
                ApiResponse(
                    success = false,
                    message = e.message ?: "Failed to process question",
                    data = null
                )
            )
        }
    }
}
