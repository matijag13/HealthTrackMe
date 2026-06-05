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
 * Sends transactional emails (the health summary).
 *
 * Two transports, chosen at runtime:
 *  - **Resend HTTP API** when `RESEND_API_KEY` is set — sends over HTTPS (443), so it works on hosts
 *    that block outbound SMTP (e.g. Railway). Preferred.
 *  - **SMTP** (JavaMailSender) otherwise — used for local dev / MailHog.
 *
 * Email is opt-in via `app.mail.enabled`; when disabled or unconfigured, [sendPlainText] returns
 * `false` instead of throwing.
 */
@Service
class EmailService(
    private val mailSenderProvider: ObjectProvider<JavaMailSender>
) {
    @Value("\${app.mail.enabled:false}")
    private var enabled: Boolean = false

    @Value("\${app.mail.from:HealthTrackMe <onboarding@resend.dev>}")
    private lateinit var from: String

    @Value("\${spring.mail.username:}")
    private lateinit var smtpUsername: String

    @Value("\${resend.api.key:}")
    private lateinit var resendApiKey: String

    private val httpClient: HttpClient = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(10))
        .build()
    private val objectMapper = jacksonObjectMapper()

    val isConfigured: Boolean
        get() = enabled && (resendApiKey.isNotBlank() ||
            (smtpUsername.isNotBlank() && mailSenderProvider.ifAvailable != null))

    /**
     * Sends a plain-text email. Returns `true` when handed off to the provider, `false` when email
     * is disabled/unconfigured. Throws on an actual send failure so the caller can surface it.
     */
    fun sendPlainText(to: String, subject: String, body: String): Boolean {
        if (!enabled) return false

        // Prefer Resend (HTTPS) — survives hosts that block SMTP egress.
        if (resendApiKey.isNotBlank()) {
            return sendViaResend(to, subject, body)
        }

        val mailSender = mailSenderProvider.ifAvailable
        if (smtpUsername.isBlank() || mailSender == null) {
            return false
        }
        val message = SimpleMailMessage().apply {
            setFrom(from)
            setTo(to)
            setSubject(subject)
            setText(body)
        }
        mailSender.send(message)
        return true
    }

    private fun sendViaResend(to: String, subject: String, body: String): Boolean {
        val payload = mapOf(
            "from" to from,
            "to" to listOf(to),
            "subject" to subject,
            "text" to body
        )
        val request = HttpRequest.newBuilder()
            .uri(URI.create("https://api.resend.com/emails"))
            .timeout(Duration.ofSeconds(20))
            .header("Authorization", "Bearer $resendApiKey")
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload)))
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
        if (response.statusCode() !in 200..299) {
            throw IllegalStateException("Resend API error ${response.statusCode()}: ${response.body()}")
        }
        return true
    }
}
