package com.healthwithme.api.service

import org.springframework.beans.factory.ObjectProvider
import org.springframework.beans.factory.annotation.Value
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.stereotype.Service

/**
 * Thin wrapper around [JavaMailSender] for transactional emails (e.g. the health summary).
 *
 * Email is opt-in: it only sends when `app.mail.enabled=true` AND an SMTP username is configured
 * (via `SMTP_USERNAME`/`SMTP_PASSWORD`). When disabled or unconfigured, [sendPlainText] returns
 * `false` instead of throwing, so the API boots and behaves cleanly in local/dev without creds.
 *
 * The mail sender is resolved through an [ObjectProvider] so the app context never fails to start
 * just because mail auto-configuration produced no bean.
 */
@Service
class EmailService(
    private val mailSenderProvider: ObjectProvider<JavaMailSender>
) {
    @Value("\${app.mail.enabled:false}")
    private var enabled: Boolean = false

    @Value("\${app.mail.from:HealthTrackMe <no-reply@healthtrackme.app>}")
    private lateinit var from: String

    @Value("\${spring.mail.username:}")
    private lateinit var smtpUsername: String

    val isConfigured: Boolean
        get() = enabled && smtpUsername.isNotBlank() && mailSenderProvider.ifAvailable != null

    /**
     * Sends a plain-text email. Returns `true` when the message was handed to the SMTP server,
     * `false` when email delivery is disabled/unconfigured. Throws if an actual send fails so the
     * caller can surface a meaningful error.
     */
    fun sendPlainText(to: String, subject: String, body: String): Boolean {
        val mailSender = mailSenderProvider.ifAvailable
        if (!enabled || smtpUsername.isBlank() || mailSender == null) {
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
}
