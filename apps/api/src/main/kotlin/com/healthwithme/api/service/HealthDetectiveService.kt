package com.healthwithme.api.service

import com.healthwithme.api.dto.DetectiveInsightDto
import com.healthwithme.api.model.*
import com.healthwithme.api.repository.*
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import kotlin.math.abs

@Service
class HealthDetectiveService(
    private val healthEntryRepository: HealthEntryRepository,
    private val detectiveInsightRepository: DetectiveInsightRepository,
    private val userRepository: UserRepository,
    private val medicineRepository: MedicineRepository,
    private val sportActivityRepository: SportActivityRepository
) {

    private val logger = LoggerFactory.getLogger(HealthDetectiveService::class.java)
    private val objectMapper = ObjectMapper()

    @Value("\${anthropic.api.key:}")
    private lateinit var apiKey: String

    /**
     * Analyze health data and generate insights using Claude API
     */
    fun generateHealthInsight(userId: Long, daysBack: Int = 7): DetectiveInsightDto {
        logger.info("Generating health insight for user $userId, last $daysBack days")

        // Verify user exists
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }

        // Get health entries for the period
        val endDate = LocalDate.now()
        val startDate = endDate.minusDays(daysBack.toLong())

        val entries = healthEntryRepository
            .findByUserIdAndEntryDateBetween(userId, startDate, endDate)
            .sortedByDescending { it.entryDate }

        if (entries.isEmpty()) {
            return createEmptyInsight("No data", "Not enough health data", "Start logging your health metrics to get insights")
        }

        // Analyze correlations and patterns
        val analysis = analyzeHealthData(entries, user)

        // Generate AI insight using Claude (if API key available)
        val insight = if (apiKey.isNotBlank()) {
            generateInsightWithClaude(user, entries, analysis, daysBack)
        } else {
            generateInsightWithRules(user, entries, analysis, daysBack)
        }

        // Save to database for caching
        val timeRange = when (daysBack) {
            7 -> TimeRange.WEEK
            30 -> TimeRange.MONTH
            else -> TimeRange.ALL_TIME
        }

        val savedInsight = DetectiveInsight(
            user = user,
            badge = insight["badge"] as String,
            title = insight["title"] as String,
            description = insight["description"] as String,
            finding = insight["finding"] as String,
            correlations = objectMapper.writeValueAsString(analysis["correlations"]),
            timeRange = timeRange,
            generatedAt = LocalDateTime.now()
        )

        detectiveInsightRepository.save(savedInsight)

        return DetectiveInsightDto(
            id = savedInsight.id,
            badge = savedInsight.badge,
            title = savedInsight.title,
            description = savedInsight.description,
            finding = savedInsight.finding,
            timeRange = savedInsight.timeRange.toString(),
            generatedAt = savedInsight.generatedAt.toString(),
            createdAt = savedInsight.createdAt.toString()
        )
    }

    /**
     * Analyze health data for correlations and patterns
     */
    private fun analyzeHealthData(entries: List<HealthEntry>, user: User): Map<String, Any> {
        val analysis = mutableMapOf<String, Any>()

        // Sleep Analysis
        val sleepData = entries.mapNotNull { it.sleepHours }
        if (sleepData.isNotEmpty()) {
            analysis["avgSleep"] = sleepData.average()
            analysis["sleepTrend"] = calculateTrend(sleepData)
        }

        // Heart Rate Analysis
        val hrData = entries.mapNotNull { it.heartRate?.toDouble() }
        if (hrData.isNotEmpty()) {
            analysis["avgHeartRate"] = hrData.average()
            analysis["hrTrend"] = calculateTrend(hrData)
            analysis["hrVariability"] = calculateStandardDeviation(hrData)
        }

        // Mood & Stress Analysis
        val moodMap = mapMoodToScore(entries.mapNotNull { it.mood })
        if (moodMap.isNotEmpty()) {
            analysis["avgMood"] = moodMap.values.average()
            analysis["moodTrend"] = calculateTrend(moodMap.values.toList())
        }

        val stressData = entries.mapNotNull { it.stressLevel?.toDouble() }
        if (stressData.isNotEmpty()) {
            analysis["avgStress"] = stressData.average()
            analysis["stressTrend"] = calculateTrend(stressData)
        }

        // Medication Adherence
        val medications = medicineRepository.findByUserIdAndIsActive(user.id!!, true)
        analysis["medicationCount"] = medications.size
        analysis["adherenceScore"] = calculateMedicationAdherence(user.id!!, entries)

        // Activity Analysis
        val totalSteps = entries.mapNotNull { it.waterIntakeMl }.sum() // Using water as proxy
        analysis["totalActivity"] = totalSteps

        // Symptom Patterns
        val symptoms = extractSymptomPatterns(entries)
        analysis["topSymptoms"] = symptoms.take(3)

        // Calculate correlations
        val correlations = calculateCorrelations(entries)
        analysis["correlations"] = correlations

        return analysis
    }

    /**
     * Generate insight using Claude API
     */
    private fun generateInsightWithClaude(
        user: User,
        entries: List<HealthEntry>,
        analysis: Map<String, Any>,
        daysBack: Int
    ): Map<String, String> {
        return try {
            // Build context for Claude
            val context = buildClaudePrompt(user, entries, analysis, daysBack)

            logger.info("Sending request to Claude API for user ${user.id}")

            // Note: This is a placeholder for actual Claude API integration
            // You'll need to implement the actual API call here
            val response = callClaudeAPI(context)

            parseClaudeResponse(response)
        } catch (e: Exception) {
            logger.warn("Claude API call failed, falling back to rule-based analysis: ${e.message}")
            generateInsightWithRules(user, entries, analysis, daysBack)
        }
    }

    /**
     * Fallback: Generate insight using rule-based analysis
     */
    private fun generateInsightWithRules(
        user: User,
        entries: List<HealthEntry>,
        analysis: Map<String, Any>,
        daysBack: Int
    ): Map<String, String> {
        val badge: String
        val title: String
        val description: String
        val finding: String

        val avgSleep = (analysis["avgSleep"] as? Double) ?: 0.0
        val avgStress = (analysis["avgStress"] as? Double) ?: 5.0
        val avgMood = (analysis["avgMood"] as? Double) ?: 5.0
        val hrVariability = (analysis["hrVariability"] as? Double) ?: 0.0
        val adherence = (analysis["adherenceScore"] as? Double) ?: 0.0
        val sleepTrend = (analysis["sleepTrend"] as? Double) ?: 0.0

        // Determine badge and insights
        when {
            avgSleep >= 7.5 && avgStress < 5.0 && avgMood >= 7.0 -> {
                badge = "✨ Strong week"
                title = "Your consistency is paying off"
                description = "Your sleep quality has improved by ${String.format("%.0f", sleepTrend)}%, " +
                        "stress levels are well-managed, and your mood is excellent. Keep up this rhythm!"
                finding = "📊 Key pattern: Your HRV variability of ${String.format("%.0f", hrVariability)} ms " +
                        "indicates excellent recovery. Maintain your current routine for best results."
            }
            avgSleep < 6.0 && daysBack >= 7 -> {
                badge = "⚠️ Rest needed"
                title = "Your sleep needs attention"
                description = "You've been averaging ${String.format("%.1f", avgSleep)} hours of sleep, " +
                        "which is below the recommended 7-9 hours. This may affect your energy and mood."
                finding = "💡 Consider: Earlier bedtime, limiting screen time, and consistent sleep schedule. " +
                        "Sleep quality is crucial for stress management."
            }
            avgStress >= 7.0 -> {
                badge = "⚡ Stress alert"
                title = "High stress detected"
                description = "Your stress levels have been averaging ${String.format("%.1f", avgStress)}/10. " +
                        "Combined with sleep patterns, this needs intervention."
                finding = "🎯 Action items: Practice meditation, increase exercise, and prioritize rest. " +
                        "Consider discussing with a healthcare provider."
            }
            adherence >= 0.9 -> {
                badge = "💪 Excellent adherence"
                title = "Your commitment is impressive"
                description = "You've maintained ${String.format("%.0f", adherence * 100)}% medication adherence " +
                        "this week. This consistency directly correlates with better health outcomes."
                finding = "📈 Your dedication shows: Consistent adherence + good sleep + mood management = " +
                        "sustainable health improvement."
            }
            else -> {
                badge = "📈 Keep going"
                title = "Track your progress"
                description = "You're logging your health data consistently. This awareness is the first step " +
                        "toward meaningful improvements."
                finding = "🔍 Next steps: Focus on one area (sleep, stress, or mood) this week and track changes."
            }
        }

        return mapOf(
            "badge" to badge,
            "title" to title,
            "description" to description,
            "finding" to finding
        )
    }

    /**
     * Build prompt for Claude API
     */
    private fun buildClaudePrompt(
        user: User,
        entries: List<HealthEntry>,
        analysis: Map<String, Any>,
        daysBack: Int
    ): String {
        val dateRange = "${LocalDate.now().minusDays(daysBack.toLong())} to ${LocalDate.now()}"

        val healthSummary = """
            User: ${user.firstName} ${user.lastName}
            Period: Last $daysBack days ($dateRange)

            Health Metrics:
            - Average Sleep: ${String.format("%.1f", analysis["avgSleep"] as? Double ?: 0.0)} hours
            - Average Heart Rate: ${String.format("%.0f", analysis["avgHeartRate"] as? Double ?: 0.0)} bpm
            - Average Mood: ${String.format("%.1f", analysis["avgMood"] as? Double ?: 0.0)}/10
            - Average Stress: ${String.format("%.1f", analysis["avgStress"] as? Double ?: 0.0)}/10
            - HR Variability: ${String.format("%.1f", analysis["hrVariability"] as? Double ?: 0.0)} ms
            - Medication Adherence: ${String.format("%.0f", (analysis["adherenceScore"] as? Double ?: 0.0) * 100)}%
            - Active Medications: ${analysis["medicationCount"] as? Int ?: 0}

            Entry Count: ${entries.size} entries

            Task: Analyze this health data and provide ONE key insight about health patterns and correlations.
            Generate a professional health insight card with:
            1. badge: Short emoji + insight type (max 20 chars, e.g., "✨ Strong week")
            2. title: Main finding (max 50 chars, e.g., "Your consistency is paying off")
            3. description: Detailed explanation with specific metrics (150-200 chars)
            4. finding: Actionable recommendation with emoji (150-200 chars)

            Format response as JSON:
            {
                "badge": "emoji text",
                "title": "title text",
                "description": "description text",
                "finding": "finding text"
            }
        """.trimIndent()

        return healthSummary
    }

    /**
     * Call Claude API (placeholder - needs actual implementation)
     */
    private fun callClaudeAPI(prompt: String): String {
        // TODO: Implement actual Anthropic Claude API call
        // This would require setting up the Anthropic client with the API key
        // and making a messages.create() call

        logger.info("Claude API call placeholder - implement with actual Anthropic SDK")

        // For now, return empty response which will trigger fallback
        throw UnsupportedOperationException("Claude API not yet configured. Configure apiKey in application.yml")
    }

    /**
     * Parse Claude API response
     */
    private fun parseClaudeResponse(response: String): Map<String, String> {
        return try {
            // Extract JSON from response
            val jsonStart = response.indexOf("{")
            val jsonEnd = response.lastIndexOf("}") + 1

            if (jsonStart == -1 || jsonEnd == 0) {
                throw IllegalArgumentException("No JSON found in response")
            }

            val jsonStr = response.substring(jsonStart, jsonEnd)
            val jsonMap = objectMapper.readValue(jsonStr, Map::class.java) as Map<String, String>

            mapOf(
                "badge" to (jsonMap["badge"] as? String ?: ""),
                "title" to (jsonMap["title"] as? String ?: ""),
                "description" to (jsonMap["description"] as? String ?: ""),
                "finding" to (jsonMap["finding"] as? String ?: "")
            )
        } catch (e: Exception) {
            logger.warn("Failed to parse Claude response: ${e.message}")
            mapOf(
                "badge" to "📊 Analysis",
                "title" to "Health insight generated",
                "description" to "AI analysis of your health patterns",
                "finding" to "Continue logging for more detailed insights"
            )
        }
    }

    /**
     * Helper: Calculate trend (positive or negative change)
     */
    private fun calculateTrend(data: List<Double>): Double {
        if (data.size < 2) return 0.0

        val first = data.takeLast(data.size / 2).average()
        val last = data.take(data.size / 2).average()

        return ((last - first) / first) * 100
    }

    /**
     * Helper: Calculate standard deviation (for HRV)
     */
    private fun calculateStandardDeviation(data: List<Double>): Double {
        if (data.size < 2) return 0.0

        val mean = data.average()
        val variance = data.map { (it - mean) * (it - mean) }.average()

        return kotlin.math.sqrt(variance)
    }

    /**
     * Helper: Map mood strings to numeric scores
     */
    private fun mapMoodToScore(moods: List<String>): Map<String, Double> {
        val moodScores = mapOf(
            "terrible" to 1.0,
            "bad" to 2.0,
            "okay" to 3.0,
            "good" to 4.0,
            "great" to 5.0
        )

        return moods.associate { mood ->
            mood to (moodScores[mood.lowercase()] ?: 3.0)
        }
    }

    /**
     * Helper: Extract symptom patterns
     */
    private fun extractSymptomPatterns(entries: List<HealthEntry>): List<String> {
        val allSymptoms = entries
            .mapNotNull { it.symptoms }
            .flatMap { it.split(",").map { s -> s.trim() } }
            .filter { it.isNotBlank() }

        return allSymptoms
            .groupingBy { it }
            .eachCount()
            .entries
            .sortedByDescending { it.value }
            .map { it.key }
    }

    /**
     * Helper: Calculate medication adherence score
     */
    private fun calculateMedicationAdherence(userId: Long, entries: List<HealthEntry>): Double {
        if (entries.isEmpty()) return 0.0

        // Simple heuristic: check if entries contain medication info
        val entriesWithMeds = entries.count {
            it.doctorNotes?.contains("medication", ignoreCase = true) == true ||
            it.tags?.contains("medication", ignoreCase = true) == true
        }

        return entriesWithMeds.toDouble() / entries.size
    }

    /**
     * Helper: Calculate correlations between metrics
     */
    private fun calculateCorrelations(entries: List<HealthEntry>): List<Map<String, Any>> {
        val correlations = mutableListOf<Map<String, Any>>()

        // Sleep -> Heart Rate correlation
        val sleepHrPairs = entries
            .filter { it.sleepHours != null && it.heartRate != null }
            .sortedBy { it.entryDate }

        if (sleepHrPairs.size >= 3) {
            val correlation = calculatePearsonCorrelation(
                sleepHrPairs.map { it.sleepHours!! },
                sleepHrPairs.map { it.heartRate!!.toDouble() }
            )

            if (abs(correlation) > 0.3) {
                correlations.add(mapOf(
                    "metric1" to "Sleep",
                    "metric2" to "Heart Rate",
                    "correlation" to correlation,
                    "impact" to if (correlation < 0) "Higher sleep = Lower resting HR (good)" else "Higher sleep = Higher HR"
                ))
            }
        }

        // Stress -> Sleep correlation
        val stressSleepPairs = entries
            .filter { it.stressLevel != null && it.sleepHours != null }

        if (stressSleepPairs.size >= 3) {
            val correlation = calculatePearsonCorrelation(
                stressSleepPairs.map { it.stressLevel!!.toDouble() },
                stressSleepPairs.map { it.sleepHours!! }
            )

            if (abs(correlation) > 0.3) {
                correlations.add(mapOf(
                    "metric1" to "Stress",
                    "metric2" to "Sleep",
                    "correlation" to correlation,
                    "impact" to if (correlation < 0) "High stress = Lower sleep quality" else "High stress = Higher sleep duration"
                ))
            }
        }

        return correlations
    }

    /**
     * Calculate Pearson correlation coefficient
     */
    private fun calculatePearsonCorrelation(x: List<Double>, y: List<Double>): Double {
        if (x.size < 2 || x.size != y.size) return 0.0

        val xMean = x.average()
        val yMean = y.average()

        val numerator = x.indices.sumOf { i ->
            (x[i] - xMean) * (y[i] - yMean)
        }

        val xStdDev = kotlin.math.sqrt(x.indices.sumOf { i ->
            (x[i] - xMean) * (x[i] - xMean)
        })

        val yStdDev = kotlin.math.sqrt(x.indices.sumOf { i ->
            (y[i] - yMean) * (y[i] - yMean)
        })

        if (xStdDev == 0.0 || yStdDev == 0.0) return 0.0

        return numerator / (xStdDev * yStdDev)
    }

    /**
     * Helper: Create empty insight
     */
    private fun createEmptyInsight(badge: String, title: String, finding: String): DetectiveInsightDto {
        return DetectiveInsightDto(
            id = 0,
            badge = badge,
            title = title,
            description = "Not enough data to generate insights yet.",
            finding = finding,
            timeRange = "WEEK",
            generatedAt = LocalDateTime.now().toString(),
            createdAt = LocalDateTime.now().toString()
        )
    }

    /**
     * Get cached insight for user
     */
    fun getCachedInsight(userId: Long, timeRange: TimeRange = TimeRange.WEEK): DetectiveInsightDto? {
        val insight = detectiveInsightRepository
            .findFirstByUserIdAndTimeRangeOrderByGeneratedAtDesc(userId, timeRange)

        return insight?.let {
            DetectiveInsightDto(
                id = it.id,
                badge = it.badge,
                title = it.title,
                description = it.description,
                finding = it.finding,
                timeRange = it.timeRange.toString(),
                generatedAt = it.generatedAt.toString(),
                createdAt = it.createdAt.toString()
            )
        }
    }

    /**
     * Get insight history for user
     */
    fun getInsightHistory(userId: Long, limit: Int = 10): List<DetectiveInsightDto> {
        return detectiveInsightRepository
            .findByUserIdOrderByGeneratedAtDesc(userId)
            .take(limit)
            .map { insight ->
                DetectiveInsightDto(
                    id = insight.id,
                    badge = insight.badge,
                    title = insight.title,
                    description = insight.description,
                    finding = insight.finding,
                    timeRange = insight.timeRange.toString(),
                    generatedAt = insight.generatedAt.toString(),
                    createdAt = insight.createdAt.toString()
                )
            }
    }
}
