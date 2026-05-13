package com.healthwithme.api.controller

import com.healthwithme.api.dto.CreateWearableDeviceRequest
import com.healthwithme.api.dto.WearableDeviceDto
import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.service.WearableDeviceService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/wearable-devices")
class WearableDeviceController(private val deviceService: WearableDeviceService) {

    @PostMapping("/users/{userId}")
    fun registerDevice(@PathVariable userId: Long, @RequestBody request: CreateWearableDeviceRequest): ResponseEntity<ApiResponse<WearableDeviceDto>> {
        return try {
            val device = deviceService.registerDevice(userId, request)
            ResponseEntity.status(HttpStatus.CREATED).body(
                ApiResponse(success = true, message = "Device registered", data = device)
            )
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = e.message, data = null))
        }
    }

    @GetMapping("/{id}")
    fun getDevice(@PathVariable id: Long): ResponseEntity<ApiResponse<WearableDeviceDto>> {
        return try {
            val device = deviceService.getDeviceById(id)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Device found", data = device))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping("/users/{userId}")
    fun getUserDevices(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<WearableDeviceDto>>> {
        return try {
            val devices = deviceService.getDevicesByUser(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Devices found", data = devices))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @PostMapping("/{id}/sync")
    fun syncDevice(@PathVariable id: Long): ResponseEntity<ApiResponse<WearableDeviceDto>> {
        return try {
            val device = deviceService.getDeviceById(id)
            val synced = deviceService.syncDevice(device.deviceId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Device synced", data = synced))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }
}

