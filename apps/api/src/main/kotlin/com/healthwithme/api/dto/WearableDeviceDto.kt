package com.healthwithme.api.dto

data class WearableDeviceDto(
    val id: Long,
    val deviceName: String,
    val deviceType: String,
    val deviceId: String,
    val serialNumber: String?,
    val isActive: Boolean,
    val lastSyncTime: String?,
    val connectedAt: String
)

data class CreateWearableDeviceRequest(
    val deviceName: String,
    val deviceType: String,
    val deviceId: String
)

data class UpdateWearableDeviceRequest(
    val deviceName: String?,
    val isActive: Boolean?
)

data class SyncWearableDataRequest(
    val deviceId: String,
    val heartRate: Int?,
    val steps: Int?,
    val caloriesBurned: Int?
)

