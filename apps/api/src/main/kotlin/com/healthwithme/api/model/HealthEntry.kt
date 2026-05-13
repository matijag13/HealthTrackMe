package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

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
    val entryDate: String = "",
    
    @ElementCollection
    @CollectionTable(name = "health_symptoms", joinColumns = [JoinColumn(name = "health_entry_id")])
    @Column(name = "symptom")
    val symptoms: MutableList<String> = mutableListOf(),
    
    @Column(nullable = true)
    val mood: String? = null,
    
    @Column(nullable = true)
    val energyLevel: Int? = null, // 1-10
    
    @Column(nullable = true)
    val sleepHours: Double? = null,
    
    @Column(nullable = true)
    val sleepQuality: String? = null, // POOR, FAIR, GOOD, EXCELLENT
    
    @Column(nullable = true)
    val stressLevel: Int? = null, // 1-10
    
    @Column(nullable = true)
    val notes: String? = null,
    
    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

