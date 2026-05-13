package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "users")
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    @Column(unique = true, nullable = false)
    val email: String = "",
    
    @Column(nullable = false)
    val password: String = "",
    
    @Column(nullable = false)
    val firstName: String = "",
    
    @Column(nullable = false)
    val lastName: String = "",
    
    @Column(nullable = false)
    val dateOfBirth: String = "",
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    val userType: UserType = UserType.PATIENT,
    
    @Column(nullable = true)
    val medicalConditions: String? = null,
    
    @Column(nullable = true)
    val allergies: String? = null,
    
    @Column(nullable = false)
    val isActive: Boolean = true,
    
    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    
    @OneToMany(mappedBy = "user", cascade = [CascadeType.ALL])
    val healthEntries: MutableList<HealthEntry> = mutableListOf(),
    
    @OneToMany(mappedBy = "user", cascade = [CascadeType.ALL])
    val medicines: MutableList<Medicine> = mutableListOf(),
    
    @OneToMany(mappedBy = "user", cascade = [CascadeType.ALL])
    val wearableDevices: MutableList<WearableDevice> = mutableListOf()
)

enum class UserType {
    PATIENT,
    ATHLETE,
    ELDERLY,
    HEALTHCARE_WORKER
}

