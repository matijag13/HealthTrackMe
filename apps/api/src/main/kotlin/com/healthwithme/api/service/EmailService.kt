package com.healthwithme.api.service

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.springframework.beans.factory.ObjectProvider
import org.springframework.beans.factory.annotation.Value
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.stereotype.Service
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

/**
 * Sends the health-summary email. Transport is chosen at runtime, in priority order:
 *  1. **Brevo HTTP API** (`BREVO_API_KEY`) — verify ONE sender (no domain needed) and send FROM that
 *     address TO any recipient, over HTTPS. Best fit for "email whoever is logged in" on a host that
 *     blocks SMTP (e.g. Railway).
 *  2. **Resend HTTP API** (`RESEND_API_KEY`) — HTTPS; arbitrary recipients need a verified domain.
 *  3. **SMTP** (JavaMailSender) — local dev / MailHog.
 *
 * Opt-in via `app.mail.enabled`; returns `false` (not throwing) when disabled/unconfigured.
 */
@Service
class EmailService(
    private val mailSenderProvider: ObjectProvider<JavaMailSender>
) {
    @Value("\${app.mail.enabled:false}")
    private var enabled: Boolean = false

    @Value("\${app.mail.from:HealthTrackMe <healthtrackme@gmail.com>}")
    private lateinit var from: String

    @Value("\${spring.mail.username:}")
    private lateinit var smtpUsername: String

    @Value("\${brevo.api.key:}")
    private lateinit var brevoApiKey: String

    @Value("\${resend.api.key:}")
    private lateinit var resendApiKey: String

    private val httpClient: HttpClient = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(10))
        .build()
    private val objectMapper = jacksonObjectMapper()

    val isConfigured: Boolean
        get() = enabled && (brevoApiKey.isNotBlank() || resendApiKey.isNotBlank() ||
            (smtpUsername.isNotBlank() && mailSenderProvider.ifAvailable != null))

    /**
     * Sends a plain-text email. Returns `true` when handed to a provider, `false` when email is
     * disabled/unconfigured. Throws on an actual send failure so the caller can surface it.
     */
    fun sendPlainText(to: String, subject: String, body: String): Boolean {
        if (!enabled) return false

        if (brevoApiKey.isNotBlank()) return sendViaBrevo(to, subject, body)
        if (resendApiKey.isNotBlank()) return sendViaResend(to, subject, body)

        val mailSender = mailSenderProvider.ifAvailable
        if (smtpUsername.isBlank() || mailSender == null) return false
        val message = SimpleMailMessage().apply {
            setFrom(from)
            setTo(to)
            setSubject(subject)
            setText(body)
        }
        mailSender.send(message)
        return true
    }

    private fun sendViaBrevo(to: String, subject: String, body: String): Boolean {
        val (senderName, senderEmail) = parseFrom(from)
        val payload = mapOf(
            "sender" to mapOf("name" to senderName, "email" to senderEmail),
            "to" to listOf(mapOf("email" to to)),
            "subject" to subject,
            "textContent" to body
        )
        return postJson(
            url = "https://api.brevo.com/v3/smtp/email",
            apiKeyHeader = "api-key" to brevoApiKey,
            payload = payload,
            provider = "Brevo"
        )
    }

    private fun sendViaResend(to: String, subject: String, body: String): Boolean {
        val payload = mapOf(
            "from" to from,
            "to" to listOf(to),
            "subject" to subject,
            "text" to body
        )
        return postJson(
            url = "https://api.resend.com/emails",
            apiKeyHeader = "Authorization" to "Bearer $resendApiKey",
            payload = payload,
            provider = "Resend"
        )
    }

    private fun postJson(
        url: String,
        apiKeyHeader: Pair<String, String>,
        payload: Map<String, Any>,
        provider: String
    ): Boolean {
        val request = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .timeout(Duration.ofSeconds(20))
            .header(apiKeyHeader.first, apiKeyHeader.second)
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload)))
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
        if (response.statusCode() !in 200..299) {
            throw IllegalStateException("$provider API error ${response.statusCode()}: ${response.body()}")
        }
        return true
    }

    /** Parse "Name <email@host>" into (name, email); falls back to the whole string as the email. */
    private fun parseFrom(value: String): Pair<String, String> {
        val match = Regex("""^\s*(.*?)\s*<(.+?)>\s*$""").find(value)
        return if (match != null) {
            val name = match.groupValues[1].ifBlank { "HealthTrackMe" }
            name to match.groupValues[2].trim()
        } else {
            "HealthTrackMe" to value.trim()
        }
    }
}
