package com.healthwithme.api.repository

import com.healthwithme.api.model.WearableDevice
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface WearableDeviceRepository : JpaRepository<WearableDevice, Long> {
    fun findByUserId(userId: Long): List<WearableDevice>
    fun findByUserIdAndIsActive(userId: Long, isActive: Boolean): List<WearableDevice>
    fun findByDeviceId(deviceId: String): WearableDevice?
}

