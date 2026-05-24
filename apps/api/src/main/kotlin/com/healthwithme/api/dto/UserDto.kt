package com.healthwithme.api.dto

data class UserDto(
    val id: Long,
    val email: String,
    val firstName: String,
    val lastName: String,
    val dateOfBirth: String,
    val userType: String,
    val medicalConditions: String?,
    val allergies: String?,
    val isActive: Boolean
)

data class CreateUserRequest(
    val email: String,
    val password: String,
    val firstName: String,
    val lastName: String,
    val dateOfBirth: String,
    val userType: String,
    val medicalConditions: String?,
    val allergies: String?
)

data class UpdateUserRequest(
    val email: String?,
    val firstName: String?,
    val lastName: String?,
    val dateOfBirth: String?,
    val userType: String?,
    val medicalConditions: String?,
    val allergies: String?,
    val isActive: Boolean?
)

data class ChangePasswordRequest(
    val currentPassword: String,
    val newPassword: String,
    val confirmPassword: String
)

