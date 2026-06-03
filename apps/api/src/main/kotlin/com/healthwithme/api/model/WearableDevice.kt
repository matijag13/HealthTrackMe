package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "wearable_devices")
data class WearableDevice(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,
    
    @Column(nullable = false)
    val deviceName: String = "",
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    val deviceType: DeviceType = DeviceType.SMARTWATCH,
    
    @Column(unique = true, nullable = false)
    val deviceId: String = "",
    
    @Column(nullable = true)
    val serialNumber: String? = null,
    
    @Column(nullable = false)
    val isActive: Boolean = true,
    
    @Column(nullable = true)
    val lastSyncTime: LocalDateTime? = null,
    
    @Column(nullable = false)
    val connectedAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

enum class DeviceType {
    SMARTWATCH,
    FITNESS_TRACKER,
    HEART_MONITOR,
    BLOOD_PRESSURE_MONITOR,
    GLUCOSE_MONITOR,
    SLEEP_TRACKER,
    OTHER,
    // Brand-specific values sent by the mobile app
    APPLEWATCH,
    FITBIT,
    GARMIN,
    OURA,
    WHOOP,
    SAMSUNG,
    GOOGLEFIT
}

