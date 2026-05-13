package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateWearableDeviceRequest
import com.healthwithme.api.dto.WearableDeviceDto
import com.healthwithme.api.dto.UpdateWearableDeviceRequest
import com.healthwithme.api.model.DeviceType
import com.healthwithme.api.model.WearableDevice
import com.healthwithme.api.repository.WearableDeviceRepository
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class WearableDeviceService(
    private val deviceRepository: WearableDeviceRepository,
    private val userRepository: UserRepository
) {

    fun registerDevice(userId: Long, request: CreateWearableDeviceRequest): WearableDeviceDto {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        if (deviceRepository.findByDeviceId(request.deviceId) != null) {
            throw IllegalArgumentException("Device already registered")
        }
        
        val device = WearableDevice(
            user = user,
            deviceName = request.deviceName,
            deviceType = DeviceType.valueOf(request.deviceType),
            deviceId = request.deviceId,
            serialNumber = null,
            isActive = true,
            connectedAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val savedDevice = deviceRepository.save(device)
        return toWearableDeviceDto(savedDevice)
    }

    fun getDeviceById(id: Long): WearableDeviceDto {
        val device = deviceRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Device not found") }
        return toWearableDeviceDto(device)
    }

    fun getDevicesByUser(userId: Long): List<WearableDeviceDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return deviceRepository.findByUserId(userId)
            .map { toWearableDeviceDto(it) }
    }

    fun getActiveDevicesByUser(userId: Long): List<WearableDeviceDto> {
        userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        return deviceRepository.findByUserIdAndIsActive(userId, true)
            .map { toWearableDeviceDto(it) }
    }

    fun updateDevice(id: Long, request: UpdateWearableDeviceRequest): WearableDeviceDto {
        val device = deviceRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Device not found") }
        
        val updatedDevice = device.copy(
            deviceName = request.deviceName ?: device.deviceName,
            isActive = request.isActive ?: device.isActive,
            updatedAt = LocalDateTime.now()
        )
        
        val savedDevice = deviceRepository.save(updatedDevice)
        return toWearableDeviceDto(savedDevice)
    }

    fun syncDevice(deviceId: String): WearableDeviceDto {
        val device = deviceRepository.findByDeviceId(deviceId)
            ?: throw IllegalArgumentException("Device not found")
        
        val syncedDevice = device.copy(
            lastSyncTime = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val savedDevice = deviceRepository.save(syncedDevice)
        return toWearableDeviceDto(savedDevice)
    }

    fun disconnectDevice(id: Long): Boolean {
        val device = deviceRepository.findById(id)
            .orElseThrow { IllegalArgumentException("Device not found") }
        
        val disconnectedDevice = device.copy(isActive = false, updatedAt = LocalDateTime.now())
        deviceRepository.save(disconnectedDevice)
        return true
    }

    private fun toWearableDeviceDto(device: WearableDevice): WearableDeviceDto {
        return WearableDeviceDto(
            id = device.id,
            deviceName = device.deviceName,
            deviceType = device.deviceType.toString(),
            deviceId = device.deviceId,
            serialNumber = device.serialNumber,
            isActive = device.isActive,
            lastSyncTime = device.lastSyncTime?.toString(),
            connectedAt = device.connectedAt.toString()
        )
    }
}

