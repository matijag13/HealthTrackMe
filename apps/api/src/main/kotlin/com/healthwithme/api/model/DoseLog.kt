package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "dose_logs")
data class DoseLog(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne
    @JoinColumn(name = "medication_id", nullable = false)
    val medication: Medication? = null,

    @Column(nullable = false)
    val scheduledTime: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = true)
    val takenTime: LocalDateTime? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: DoseStatus = DoseStatus.SCHEDULED,

    @Column(columnDefinition = "TEXT")
    val note: String? = null
)

enum class DoseStatus {
    SCHEDULED,
    TAKEN,
    MISSED,
    SKIPPED
}