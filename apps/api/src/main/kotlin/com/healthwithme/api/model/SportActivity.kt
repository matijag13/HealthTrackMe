package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "sport_activities")
data class SportActivity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,
    
    @Column(nullable = false)
    val activityType: String = "", // RUNNING, CYCLING, SWIMMING, etc.
    
    @Column(nullable = false)
    val activityDate: String = "",
    
    @Column(nullable = true)
    val duration: Int? = null, // in minutes
    
    @Column(nullable = true)
    val distance: Double? = null, // in kilometers
    
    @Column(nullable = true)
    val caloriesBurned: Int? = null,

    @Column(nullable = true)
    val steps: Int? = null,
    
    @Column(nullable = true)
    val intensity: String? = null, // LOW, MODERATE, HIGH
    
    @Column(nullable = true)
    val averageHeartRate: Int? = null,
    
    @Column(nullable = true)
    val notes: String? = null,
    
    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

