package com.healthwithme.api.service

import com.healthwithme.api.dto.DetectiveInsightDto
import com.healthwithme.api.model.*
import com.healthwithme.api.repository.*
import com.healthwithme.api.util.ExportUtil
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration
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

    @Value("\${groq.api.key:}")
    private lateinit var apiKey: String

    @Value("\${groq.model:llama-3.3-70b-versatile}")
    private lateinit var model: String

    private val httpClient: HttpClient = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(10))
        .build()

    /**
     * Analyze health data and generate insights using Claude API
     */
    fun generateHealthInsight(userId: Long, daysBack: Int = 7, language: String = "en"): DetectiveInsightDto {
        logger.info("Generating health insight for user $userId, last $daysBack days")
        val locale = normalizeLanguage(language)

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
            return createEmptyInsight(locale)
        }

        // Analyze correlations and patterns
        val analysis = analyzeHealthData(entries, user)

        // Generate AI insight using Claude (if API key available)
        val insight = if (apiKey.isNotBlank()) {
            generateInsightWithClaude(user, entries, analysis, daysBack, locale)
        } else {
            generateInsightWithRules(user, entries, analysis, daysBack, locale)
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
        daysBack: Int,
        language: String
    ): Map<String, String> {
        return try {
            // Build context for Claude
            val context = buildClaudePrompt(user, entries, analysis, daysBack, language)

            logger.info("Sending request to Groq API for user ${user.id}")

            // Note: This is a placeholder for actual Claude API integration
            // You'll need to implement the actual API call here
            val response = callClaudeAPI(context)

            parseClaudeResponse(response)
        } catch (e: Exception) {
            logger.warn("Groq API call failed, falling back to rule-based analysis: ${e.message}")
            generateInsightWithRules(user, entries, analysis, daysBack, language)
        }
    }

    /**
     * Fallback: Generate insight using rule-based analysis
     */
    private fun generateInsightWithRules(
        user: User,
        entries: List<HealthEntry>,
        analysis: Map<String, Any>,
        daysBack: Int,
        language: String
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
        val sl = language == "sl"

        // Determine badge and insights
        when {
            avgSleep >= 7.5 && avgStress < 5.0 && avgMood >= 7.0 -> {
                badge = if (sl) "✨ Močan teden" else "✨ Strong week"
                title = if (sl) "Doslednost se ti obrestuje" else "Your consistency is paying off"
                description = if (sl) {
                    "Kakovost spanja se je izboljšala za ${String.format("%.0f", sleepTrend)}%, " +
                        "stres je dobro obvladan, razpoloženje pa odlično. Nadaljuj ta ritem!"
                } else {
                    "Your sleep quality has improved by ${String.format("%.0f", sleepTrend)}%, " +
                        "stress levels are well-managed, and your mood is excellent. Keep up this rhythm!"
                }
                finding = if (sl) {
                    "📊 Ključni vzorec: HRV variabilnost ${String.format("%.0f", hrVariability)} ms " +
                        "kaže na zelo dobro regeneracijo. Ohrani trenutno rutino."
                } else {
                    "📊 Key pattern: Your HRV variability of ${String.format("%.0f", hrVariability)} ms " +
                        "indicates excellent recovery. Maintain your current routine for best results."
                }
            }
            avgSleep < 6.0 && daysBack >= 7 -> {
                badge = if (sl) "⚠️ Potreben počitek" else "⚠️ Rest needed"
                title = if (sl) "Spanje potrebuje pozornost" else "Your sleep needs attention"
                description = if (sl) {
                    "V povprečju spiš ${String.format("%.1f", avgSleep)} ure, kar je pod priporočenimi " +
                        "7-9 urami. To lahko vpliva na energijo in razpoloženje."
                } else {
                    "You've been averaging ${String.format("%.1f", avgSleep)} hours of sleep, " +
                        "which is below the recommended 7-9 hours. This may affect your energy and mood."
                }
                finding = if (sl) {
                    "💡 Poskusi: zgodnejši odhod v posteljo, manj zaslonov zvečer in stalen urnik spanja. " +
                        "Kakovost spanja je pomembna za obvladovanje stresa."
                } else {
                    "💡 Consider: Earlier bedtime, limiting screen time, and consistent sleep schedule. " +
                        "Sleep quality is crucial for stress management."
                }
            }
            avgStress >= 7.0 -> {
                badge = if (sl) "⚡ Opozorilo stres" else "⚡ Stress alert"
                title = if (sl) "Zaznan je višji stres" else "High stress detected"
                description = if (sl) {
                    "Tvoja povprečna raven stresa je ${String.format("%.1f", avgStress)}/10. " +
                        "Skupaj z vzorci spanja je to vredno pozornosti."
                } else {
                    "Your stress levels have been averaging ${String.format("%.1f", avgStress)}/10. " +
                        "Combined with sleep patterns, this needs intervention."
                }
                finding = if (sl) {
                    "🎯 Naslednji koraki: poskusi meditacijo, več gibanja in prednostno načrtuj počitek. " +
                        "Ob zdravstvenih skrbeh se pogovori z zdravnikom."
                } else {
                    "🎯 Action items: Practice meditation, increase exercise, and prioritize rest. " +
                        "Consider discussing with a healthcare provider."
                }
            }
            adherence >= 0.9 -> {
                badge = if (sl) "💪 Odlično jemanje" else "💪 Excellent adherence"
                title = if (sl) "Tvoja predanost izstopa" else "Your commitment is impressive"
                description = if (sl) {
                    "Ta teden imaš ${String.format("%.0f", adherence * 100)}% doslednost pri zdravilih. " +
                        "Takšna rutina podpira boljše dolgoročne rezultate."
                } else {
                    "You've maintained ${String.format("%.0f", adherence * 100)}% medication adherence " +
                        "this week. This consistency directly correlates with better health outcomes."
                }
                finding = if (sl) {
                    "📈 Tvoja doslednost se pozna: redno jemanje + dobro spanje + spremljanje počutja = " +
                        "trajnosten napredek."
                } else {
                    "📈 Your dedication shows: Consistent adherence + good sleep + mood management = " +
                        "sustainable health improvement."
                }
            }
            else -> {
                badge = if (sl) "📈 Nadaljuj" else "📈 Keep going"
                title = if (sl) "Spremljaj svoj napredek" else "Track your progress"
                description = if (sl) {
                    "Zdravstvene podatke beležiš dosledno. To zavedanje je prvi korak " +
                        "do smiselnih izboljšav."
                } else {
                    "You're logging your health data consistently. This awareness is the first step " +
                        "toward meaningful improvements."
                }
                finding = if (sl) {
                    "🔍 Naslednji koraki: ta teden se osredotoči na eno področje " +
                        "(spanje, stres ali razpoloženje) in spremljaj spremembe."
                } else {
                    "🔍 Next steps: Focus on one area (sleep, stress, or mood) this week and track changes."
                }
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
    /**
     * The user's aggregated health metrics as plain text — shared by the insight
     * prompt and the Q&A prompt.
     */
    private fun buildHealthContext(
        user: User,
        entries: List<HealthEntry>,
        analysis: Map<String, Any>,
        daysBack: Int
    ): String {
        val dateRange = "${LocalDate.now().minusDays(daysBack.toLong())} to ${LocalDate.now()}"

        return """
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
        """.trimIndent()
    }

    /**
     * Build prompt for the Claude insight card (health context + JSON-format task).
     */
    private fun buildClaudePrompt(
        user: User,
        entries: List<HealthEntry>,
        analysis: Map<String, Any>,
        daysBack: Int,
        language: String
    ): String {
        return buildHealthContext(user, entries, analysis, daysBack) + "\n\n" + """
            Language: ${languageName(language)}.
            Write every user-facing JSON value in ${languageName(language)}.

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
    }

    /**
     * Build a friendly, plain-text narrative health summary for the given period,
     * used by the on-demand "email me a summary" action and the scheduled weekly
     * report. Uses the AI model when available; otherwise returns the factual
     * [ExportUtil] summary so the email always has useful content.
     */
    fun generateNarrativeSummary(userId: Long, daysBack: Int = 7): String {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }

        val endDate = LocalDate.now()
        val startDate = endDate.minusDays(daysBack.toLong())

        val entries = healthEntryRepository
            .findByUserIdAndEntryDateBetween(userId, startDate, endDate)
            .sortedByDescending { it.entryDate }

        val activities = sportActivityRepository.findByUserId(userId).filter {
            val d = runCatching { LocalDate.parse(it.activityDate) }.getOrNull()
            d != null && !d.isBefore(startDate) && !d.isAfter(endDate)
        }

        val firstName = user.firstName.ifBlank { "there" }

        if (entries.isEmpty() && activities.isEmpty()) {
            return "Hi $firstName,\n\nWe didn't see any health data logged in the last " +
                "$daysBack days, so there's nothing to summarise yet. Log a few days of vitals, " +
                "sleep, or activity and your next report will have plenty to say.\n\n— HealthTrackMe"
        }

        val factualSummary = ExportUtil.generateHealthSummary(entries, activities)
        if (apiKey.isBlank()) return factualSummary

        return try {
            val userMessage = buildString {
                appendLine("User's first name: ${user.firstName}")
                appendLine("Reporting period: last $daysBack days.")
                appendLine()
                appendLine("Here is the factual data for that period:")
                appendLine(factualSummary)
                appendLine()
                appendLine("Write the health report email now.")
            }
            callClaude(WEEKLY_SUMMARY_SYSTEM_PROMPT, userMessage, 900)
                .trim()
                .ifBlank { factualSummary }
        } catch (e: Exception) {
            logger.warn("AI narrative summary failed, using factual summary: ${e.message}")
            factualSummary
        }
    }

    /**
     * Answer a free-form question about the user's recent health data using Claude.
     * Returns {"answer": ...}. Degrades gracefully when there's no data or no API
     * key, so the "ask your health data" feature never errors out.
     */
    fun answerQuestion(
        userId: Long,
        question: String,
        daysBack: Int = 30,
        language: String = "en"
    ): Map<String, String> {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        val locale = normalizeLanguage(language)
        val sl = locale == "sl"

        if (question.isBlank()) {
            return mapOf(
                "answer" to if (sl) {
                    "Vpiši vprašanje o svojem zdravju."
                } else {
                    "Please type a question about your health."
                }
            )
        }

        val endDate = LocalDate.now()
        val startDate = endDate.minusDays(daysBack.toLong())
        val entries = healthEntryRepository
            .findByUserIdAndEntryDateBetween(userId, startDate, endDate)
            .sortedByDescending { it.entryDate }

        if (entries.isEmpty()) {
            return mapOf(
                "answer" to if (sl) {
                    "Nimam še dovolj tvojih zdravstvenih podatkov. Zabeleži nekaj dni vitalnih znakov, " +
                        "spanja ali aktivnosti in vprašaj znova."
                } else {
                    "I don't have enough of your health data yet. Log a few days of " +
                        "vitals, sleep, or activity and ask again."
                }
            )
        }

        if (apiKey.isBlank()) {
            return mapOf(
                "answer" to if (sl) {
                    "AI odgovori na strežniku še niso omogočeni. Ko bo API ključ nastavljen, " +
                        "bom lahko odgovarjal na vprašanja o tvojih trendih."
                } else {
                    "AI answers aren't enabled on the server yet. Once an API key is " +
                        "configured, I can answer questions about your trends."
                }
            )
        }

        return try {
            val analysis = analyzeHealthData(entries, user)
            val userMessage = buildString {
                appendLine("Answer language: ${languageName(locale)}.")
                appendLine("Write the full answer in ${languageName(locale)}.")
                appendLine()
                appendLine("Here is the user's recent health data:")
                appendLine(buildHealthContext(user, entries, analysis, daysBack))
                appendLine()
                appendLine("Question: $question")
            }
            val answer = callClaude(ASK_SYSTEM_PROMPT, userMessage, 1024).trim()
            mapOf(
                "answer" to answer.ifBlank {
                    if (sl) {
                        "V tvojih podatkih nisem našel odgovora."
                    } else {
                        "I couldn't find an answer in your data."
                    }
                }
            )
        } catch (e: Exception) {
            logger.warn("Detective Q&A failed: ${e.message}")
            mapOf(
                "answer" to if (sl) {
                    "Tega trenutno ne morem analizirati. Poskusi znova."
                } else {
                    "I couldn't analyze that right now. Please try again."
                }
            )
        }
    }

    /**
     * Call Claude for the insight card. Delegates to [callClaude] with the
     * card-generation system prompt; the data + format instructions are in [prompt].
     */
    private fun callClaudeAPI(prompt: String): String {
        return callClaude(INSIGHT_SYSTEM_PROMPT, prompt, 1024)
    }

    private fun normalizeLanguage(language: String): String {
        return if (language.lowercase().startsWith("sl")) "sl" else "en"
    }

    private fun languageName(language: String): String {
        return if (normalizeLanguage(language) == "sl") "Slovenian" else "English"
    }

    /**
     * Raw HTTP call to Groq's OpenAI-compatible chat completions endpoint.
     * Throws on non-2xx so callers can fall back to rule-based analysis.
     */
    private fun callClaude(systemPrompt: String, userMessage: String, maxTokens: Int): String {
        if (apiKey.isBlank()) {
            throw IllegalStateException("Groq API key not configured")
        }

        val body = mapOf(
            "model" to model,
            "max_tokens" to maxTokens,
            "messages" to listOf(
                mapOf("role" to "system", "content" to systemPrompt),
                mapOf("role" to "user", "content" to userMessage)
            )
        )

        val request = HttpRequest.newBuilder()
            .uri(URI.create("https://api.groq.com/openai/v1/chat/completions"))
            .timeout(Duration.ofSeconds(30))
            .header("content-type", "application/json")
            .header("authorization", "Bearer $apiKey")
            .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(body)))
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
        if (response.statusCode() !in 200..299) {
            throw IllegalStateException("Groq API error ${response.statusCode()}: ${response.body()}")
        }

        return objectMapper.readTree(response.body())
            .path("choices").first()
            .path("message").path("content").asText()
            .also { if (it.isBlank()) throw IllegalStateException("Groq returned no content") }
    }

    companion object {
        private const val INSIGHT_SYSTEM_PROMPT =
            "You are a supportive, evidence-aware health insights assistant for a personal health " +
                "tracking app. You analyze the user's own logged data and surface one clear, " +
                "encouraging insight. Never give a medical diagnosis or prescribe treatment. " +
                "Respond ONLY with the requested JSON object — no prose before or after."

        private const val ASK_SYSTEM_PROMPT =
            "You are a supportive health assistant inside a personal health tracking app. Answer the " +
                "user's question using ONLY the health data provided. Be concise (2-4 sentences), " +
                "specific, and encouraging. If the data can't answer the question, say so plainly. " +
                "Never give a medical diagnosis or prescribe treatment; suggest seeing a clinician for " +
                "medical concerns."

        private const val WEEKLY_SUMMARY_SYSTEM_PROMPT =
            "You are a warm, encouraging health coach writing a short health summary email for a " +
                "personal health tracking app. Use ONLY the data provided — never invent numbers. " +
                "Write 3-4 short paragraphs in plain text (no markdown, no bullet symbols): greet the " +
                "user by first name, highlight what went well with specific numbers, gently flag one " +
                "area to improve with a concrete, doable tip, and close with encouragement. Keep it " +
                "under ~200 words. Never give a medical diagnosis or prescribe treatment; suggest " +
                "seeing a clinician for medical concerns. Sign off on its own line as '— HealthTrackMe'."
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
    private fun createEmptyInsight(language: String): DetectiveInsightDto {
        val sl = language == "sl"
        return DetectiveInsightDto(
            id = 0,
            badge = if (sl) "Ni podatkov" else "No data",
            title = if (sl) "Premalo zdravstvenih podatkov" else "Not enough health data",
            description = if (sl) {
                "Za pripravo vpogledov še ni dovolj podatkov."
            } else {
                "Not enough data to generate insights yet."
            },
            finding = if (sl) {
                "Začni beležiti zdravstvene metrike, da dobiš vpoglede."
            } else {
                "Start logging your health metrics to get insights"
            },
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
