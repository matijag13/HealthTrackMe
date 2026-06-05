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
    val height: Double?,
    val weight: Double?,
    val bloodType: String?,
    val emergencyContactName: String?,
    val emergencyContactPhone: String?,
    val chronicConditions: List<String>?,
    val pastSurgeries: List<Map<String, Any>>?,
    val familyHistory: List<Map<String, Any>>?,
    val vaccinations: List<Map<String, Any>>?,
    val organDonor: Boolean?,
    val doctorName: String?,
    val doctorClinic: String?,
    val doctorPhone: String?,
    val insuranceProvider: String?,
    val insurancePolicyNumber: String?,
    val profilePhotoBase64: String?,
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

data class LoginRequest(
    val email: String,
    val password: String
)

data class GoogleLoginRequest(
    val idToken: String
)

/** Returned by /auth/login and /auth/google — the JWT plus the authenticated user. */
data class AuthResponse(
    val token: String,
    val user: UserDto
)

data class UpdateUserRequest(
    val email: String?,
    val firstName: String?,
    val lastName: String?,
    val dateOfBirth: String?,
    val userType: String?,
    val medicalConditions: String?,
    val allergies: String?,
    val height: Double?,
    val weight: Double?,
    val bloodType: String?,
    val emergencyContactName: String?,
    val emergencyContactPhone: String?,
    val chronicConditions: List<String>?,
    val pastSurgeries: List<Map<String, Any>>?,
    val familyHistory: List<Map<String, Any>>?,
    val vaccinations: List<Map<String, String>>?,
    val organDonor: Boolean?,
    val doctorName: String?,
    val doctorClinic: String?,
    val doctorPhone: String?,
    val insuranceProvider: String?,
    val insurancePolicyNumber: String?,
    val profilePhotoBase64: String?,
    val isActive: Boolean?
)

data class ChangePasswordRequest(
    val currentPassword: String,
    val newPassword: String,
    val confirmPassword: String
)

