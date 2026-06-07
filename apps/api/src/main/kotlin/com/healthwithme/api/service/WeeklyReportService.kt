package com.healthwithme.api.service

import com.healthwithme.api.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service

/**
 * Emails the AI-generated weekly health report to every user who opted in
 * (users.weekly_report_enabled = true). Runs on a cron schedule; the default is
 * every Monday at 09:00 (server time) and can be overridden with the
 * `app.weekly-report.cron` property.
 */
@Service
class WeeklyReportService(
    private val userRepository: UserRepository,
    private val healthDetectiveService: HealthDetectiveService,
    private val emailService: EmailService
) {
    private val logger = LoggerFactory.getLogger(WeeklyReportService::class.java)

    @Scheduled(cron = "\${app.weekly-report.cron:0 0 9 * * MON}")
    fun sendWeeklyReports() {
        if (!emailService.isConfigured) {
            logger.info("Weekly reports skipped: email is not configured")
            return
        }

        val recipients = userRepository.findByWeeklyReportEnabledTrueAndIsActiveTrue()
        if (recipients.isEmpty()) {
            logger.info("Weekly reports: no opted-in users")
            return
        }

        logger.info("Weekly reports: sending to ${recipients.size} user(s)")
        for (user in recipients) {
            try {
                val body = healthDetectiveService.generateNarrativeSummary(user.id, daysBack = 7)
                emailService.sendPlainText(
                    to = user.email,
                    subject = "Your weekly HealthTrackMe report",
                    body = body
                )
            } catch (e: Exception) {
                logger.warn("Weekly report failed for user ${user.id}: ${e.message}")
            }
        }
    }
}
