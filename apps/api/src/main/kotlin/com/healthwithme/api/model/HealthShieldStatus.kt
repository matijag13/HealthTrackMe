package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDate
import java.time.LocalDateTime

@Entity
@Table(name = "health_shield_status")
data class HealthShieldStatus(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    val user: User? = null,

    @Column(nullable = false)
    var totalConsistencyPoints: Int = 0,

    @Column(nullable = false)
    var currentLevel: Int = 1,

    @Column(nullable = false)
    var consecutiveFailedDays: Int = 0,

    @Column(nullable = true)
    var lastCalculatedDate: LocalDate? = null,

    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now()
)
