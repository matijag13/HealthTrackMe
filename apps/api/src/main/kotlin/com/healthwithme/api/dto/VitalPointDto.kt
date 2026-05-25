package com.healthwithme.api.dto

data class VitalPointDto(
    val date: String,
    val value: Double?,
    val unit: String
)

