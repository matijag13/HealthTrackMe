package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDate
import java.time.LocalDateTime

@Entity
@Table(name = "medicines")
data class Medicine(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,
    
    @Column(nullable = false)
    val name: String = "",
    
    @Column(nullable = true)
    val dosage: String? = null,
    
    @Column(nullable = true)
    val frequency: String? = null, // ONCE_DAILY, TWICE_DAILY, THREE_TIMES, etc.
    
    @Column(nullable = true)
    val reason: String? = null,
    
    @Column(nullable = true)
    val startDate: LocalDate? = null,
    
    @Column(nullable = true)
    val endDate: LocalDate? = null,
    
    @Column(nullable = true)
    val sideEffects: String? = null,
    
    @Column(nullable = false)
    val isActive: Boolean = true,
    
    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

