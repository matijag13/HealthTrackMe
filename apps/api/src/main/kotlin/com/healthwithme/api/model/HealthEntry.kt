package com.healthwithme.api.model

import jakarta.persistence.*
import jakarta.validation.constraints.Max
import jakarta.validation.constraints.Min
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

@Entity
@Table(name = "health_entries")
data class HealthEntry(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,
    
    @Column(nullable = false)
    val entryDate: LocalDate = LocalDate.now(),

    @Column(nullable = true)
    val measuredAt: LocalDateTime? = null,

    @field:Min(1)
    @field:Max(10)
    @Column(nullable = false)
    val wellbeingScore: Int = 1,

    // TODO: Migrate to PostgreSQL JSONB + at-rest encryption for sensitive symptom data.
    @Column(columnDefinition = "TEXT")
    val symptoms: String? = null,
    
    @Column(nullable = true)
    val mood: String? = null,
    
    @Column(nullable = true)
    val energyLevel: Int? = null, // 1-10

    @Column(nullable = true)
    val stressLevel: Int? = null, // 1-10
    
    @Column(nullable = true)
    val sleepHours: Double? = null,
    
    @Column(nullable = true)
    val sleepQuality: String? = null, // POOR, FAIR, GOOD, EXCELLENT
    
    @Column(nullable = true)
    val weight: Double? = null,

    @Column(nullable = true)
    val heartRate: Int? = null,

    @Column(nullable = true)
    val systolicBp: Int? = null,

    @Column(nullable = true)
    val diastolicBp: Int? = null,

    @Column(nullable = true)
    val bloodGlucose: Double? = null,

    @Column(nullable = true)
    val bodyTemperature: Double? = null,

    @Column(nullable = true)
    val spO2: Int? = null,

    @Column(nullable = true)
    val waterIntakeMl: Int? = null,

    @Column(nullable = true)
    val caloriesConsumed: Int? = null,

    @Column(nullable = true)
    val alcoholUnits: Double? = null,

    @field:Min(0)
    @field:Max(10)
    @Column(nullable = true)
    val painLevel: Int? = null,

    @Column(nullable = true)
    val bedtime: LocalTime? = null,

    @Column(nullable = true)
    val wakeTime: LocalTime? = null,

    @Column(nullable = true)
    val sleepQualityStars: Int? = null,

    @Column(columnDefinition = "TEXT")
    val tags: String? = null,
    
    // TODO: Encrypt doctor notes at rest before production rollout.
    @Column(columnDefinition = "TEXT")
    val doctorNotes: String? = null,
    
    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)





