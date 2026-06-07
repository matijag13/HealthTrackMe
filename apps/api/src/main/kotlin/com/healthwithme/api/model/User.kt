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
    
    @Column(nullable = true)
    val passwordHash: String? = null,

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    val authProvider: AuthProvider = AuthProvider.LOCAL,

    @Column(unique = true, nullable = true)
    val googleSub: String? = null,
    
    @Column(nullable = false)
    val firstName: String = "",
    
    @Column(nullable = false)
    val lastName: String = "",

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    val role: UserRole = UserRole.USER,

    @Column(nullable = false)
    val gdprConsentAccepted: Boolean = false,

    @Column(nullable = true)
    val gdprConsentAcceptedAt: LocalDateTime? = null,
    
    @Column(nullable = false)
    val dateOfBirth: String = "",
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    val userType: UserType = UserType.PATIENT,
    
    @Column(nullable = true)
    val medicalConditions: String? = null,
    
    @Column(nullable = true)
    val allergies: String? = null,
    
    @Column(nullable = true)
    val height: Double? = null,

    @Column(nullable = true)
    val weight: Double? = null,

    @Column(nullable = true)
    val bloodType: String? = null,

    @Column(nullable = true)
    val emergencyContactName: String? = null,

    @Column(nullable = true)
    val emergencyContactPhone: String? = null,

    @Column(columnDefinition = "TEXT")
    val chronicConditions: String? = null,

    @Column(columnDefinition = "TEXT")
    val pastSurgeries: String? = null,

    @Column(columnDefinition = "TEXT")
    val familyHistory: String? = null,

    @Column(columnDefinition = "TEXT")
    val vaccinations: String? = null,

    @Column(nullable = true)
    val organDonor: Boolean? = null,

    @Column(nullable = true)
    val doctorName: String? = null,

    @Column(nullable = true)
    val doctorClinic: String? = null,

    @Column(nullable = true)
    val doctorPhone: String? = null,

    @Column(nullable = true)
    val insuranceProvider: String? = null,

    @Column(nullable = true)
    val insurancePolicyNumber: String? = null,

    @Column(columnDefinition = "TEXT")
    val profilePhotoBase64: String? = null,

    @Column(nullable = false, name = "weekly_report_enabled")
    val weeklyReportEnabled: Boolean = false,

    @Column(nullable = false)
    val isActive: Boolean = true,
    
    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    
    @OneToMany(mappedBy = "user", cascade = [CascadeType.ALL])
    val healthEntries: MutableList<HealthEntry> = mutableListOf(),

    @OneToMany(mappedBy = "user", cascade = [CascadeType.ALL])
    val sleepRecords: MutableList<SleepRecord> = mutableListOf(),

    @OneToMany(mappedBy = "user", cascade = [CascadeType.ALL])
    val activityLogs: MutableList<ActivityLog> = mutableListOf(),
    
    @OneToMany(mappedBy = "user", cascade = [CascadeType.ALL])
    val medicines: MutableList<Medicine> = mutableListOf(),
    
    @OneToMany(mappedBy = "user", cascade = [CascadeType.ALL])
    val wearableDevices: MutableList<WearableDevice> = mutableListOf()
)

enum class UserRole {
    USER,
    ADMIN
}

enum class AuthProvider {
    LOCAL,
    GOOGLE,
    LOCAL_GOOGLE
}

enum class UserType {
    PATIENT,
    ATHLETE,
    ELDERLY,
    HEALTHCARE_WORKER
}

