package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDate
import java.time.LocalDateTime

@Entity
@Table(
    name = "health_shield_daily_points",
    uniqueConstraints = [UniqueConstraint(columnNames = ["user_id", "calculation_date"])]
)
data class HealthShieldDailyPoints(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,

    @Column(nullable = false)
    val calculationDate: LocalDate = LocalDate.now(),

    @Column(nullable = false)
    var supplementsPoints: Int = 0,

    @Column(nullable = false)
    var sleepPoints: Int = 0,

    @Column(nullable = false)
    var activityPoints: Int = 0,

    @Column(nullable = false)
    var wellbeingPoints: Int = 0,

    @Column(nullable = false)
    var symptomsPoints: Int = 0,

    @Column(nullable = false)
    var routineStabilityPoints: Int = 0,

    @Column(nullable = false)
    var penaltyPoints: Int = 0,

    @Column(nullable = false)
    var totalDailyPoints: Int = 0,

    @Column(nullable = false)
    var completedHabitsCount: Int = 0,

    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
