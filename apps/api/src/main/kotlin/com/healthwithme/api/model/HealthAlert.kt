package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "health_alerts")
data class HealthAlert(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,
    
    @Column(nullable = false)
    val title: String = "",
    
    @Column(nullable = false)
    val description: String = "",
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    val alertType: AlertType = AlertType.INFO,
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    val severity: AlertSeverity = AlertSeverity.LOW,
    
    @Column(nullable = true)
    val triggerReason: String? = null,
    
    @Column(nullable = false)
    val isRead: Boolean = false,
    
    @Column(nullable = true)
    val actionRequired: String? = null, // "VISIT_DOCTOR", "MONITOR", "URGENT"
    
    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(nullable = true)
    val acknowledgedAt: LocalDateTime? = null
)

enum class AlertType {
    UNUSUAL_TREND,
    ABNORMAL_VALUE,
    MEDICATION_REMINDER,
    DOCTOR_VISIT_NEEDED,
    HIGH_RISK_DETECTED,
    INFO
}

enum class AlertSeverity {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}

