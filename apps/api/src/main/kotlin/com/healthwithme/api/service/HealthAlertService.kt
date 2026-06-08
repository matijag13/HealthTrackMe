package com.healthwithme.api.service

import com.healthwithme.api.dto.HealthAlertDto
import com.healthwithme.api.model.AlertSeverity
import com.healthwithme.api.model.AlertType
import com.healthwithme.api.model.HealthAlert
import com.healthwithme.api.repository.HealthAlertRepository
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class HealthAlertService(
    private val alertRepository: HealthAlertRepository,
    private val userRepository: UserRepository
) {

    fun createAlert(userId: Long, title: String, description: String,
                   alertType: String, severity: String, actionRequired: String? = null): HealthAlertDto {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }

        val alert = HealthAlert(
            user = user,
            title = title,
            description = description,
            alertType = AlertType.valueOf(alertType),
            severity = AlertSeverity.valueOf(severity),
            actionRequired = actionRequired,
            isRead = false,
            createdAt = LocalDateTime.now()
        )
        
        val savedAlert = alertRepository.save(alert)
        return toAlertDto(savedAlert)
    }

    fun getAlertById(id: Long): HealthAlertDto {
        val alert = alertRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Alert not found") }
        return toAlertDto(alert)
    }

    fun getAlertsByUser(userId: Long): List<HealthAlertDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return alertRepository.findByUserIdOrderByCreatedAtDesc(userId)
            .map { toAlertDto(it) }
    }

    fun getUnreadAlerts(userId: Long): List<HealthAlertDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return alertRepository.findByUserIdAndIsRead(userId, false)
            .map { toAlertDto(it) }
    }

    fun markAlertAsRead(id: Long): HealthAlertDto {
        val alert = alertRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Alert not found") }
        
        val updatedAlert = alert.copy(
            isRead = true,
            acknowledgedAt = LocalDateTime.now()
        )
        
        val savedAlert = alertRepository.save(updatedAlert)
        return toAlertDto(savedAlert)
    }

    fun deleteAlert(id: Long): Boolean {
        alertRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Alert not found") }
        
        alertRepository.deleteById(id)
        return true
    }

    private fun toAlertDto(alert: HealthAlert): HealthAlertDto {
        return HealthAlertDto(
            id = alert.id,
            title = alert.title,
            description = alert.description,
            alertType = alert.alertType.toString(),
            severity = alert.severity.toString(),
            triggerReason = alert.triggerReason,
            isRead = alert.isRead,
            actionRequired = alert.actionRequired,
            createdAt = alert.createdAt.toString()
        )
    }
}

