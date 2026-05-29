package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateUserRequest
import com.healthwithme.api.dto.UpdateUserRequest
import com.healthwithme.api.dto.UserDto
import com.healthwithme.api.model.AuthProvider
import com.healthwithme.api.model.User
import com.healthwithme.api.model.UserType
import com.healthwithme.api.repository.UserRepository
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder
) {
    private val objectMapper = jacksonObjectMapper()

    fun createUser(request: CreateUserRequest): UserDto {
        if (userRepository.existsByEmail(request.email)) {
            throw IllegalArgumentException("Email already exists")
        }
        
        val user = User(
            email = request.email,
            passwordHash = passwordEncoder.encode(request.password),
            firstName = request.firstName,
            lastName = request.lastName,
            dateOfBirth = request.dateOfBirth,
            userType = UserType.valueOf(request.userType),
            medicalConditions = request.medicalConditions,
            allergies = request.allergies,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        val savedUser = userRepository.save(user)
        return toUserDto(savedUser)
    }

    fun getUserById(id: Long): UserDto {
        val user = userRepository.findById(id)
            .orElseThrow { IllegalArgumentException("User not found") }
        return toUserDto(user)
    }

    fun getUserByEmail(email: String): UserDto {
        val user = userRepository.findByEmail(email)
            .orElseThrow { IllegalArgumentException("User not found") }
        return toUserDto(user)
    }

    fun login(email: String, password: String): UserDto {
        val normalizedEmail = email.trim()
        val user = userRepository.findByEmail(normalizedEmail)
            .orElseThrow { IllegalArgumentException("Invalid email or password") }

        val passwordHash = user.passwordHash
        if (!user.isActive || passwordHash == null || !passwordEncoder.matches(password, passwordHash)) {
            throw IllegalArgumentException("Invalid email or password")
        }

        return toUserDto(user)
    }

    fun loginWithGoogle(googleUser: GoogleUserInfo): UserDto {
        if (!googleUser.emailVerified) {
            throw IllegalArgumentException("Invalid Google token")
        }

        val existingByGoogleSub = userRepository.findByGoogleSub(googleUser.sub)
        if (existingByGoogleSub.isPresent) {
            val user = existingByGoogleSub.get()
            if (!user.isActive) {
                throw IllegalArgumentException("Invalid Google token")
            }
            return toUserDto(user)
        }

        val existingByEmail = userRepository.findByEmail(googleUser.email)
        if (existingByEmail.isPresent) {
            val user = existingByEmail.get()
            if (!user.isActive) {
                throw IllegalArgumentException("Invalid Google token")
            }
            val linkedUser = user.copy(
                googleSub = googleUser.sub,
                authProvider = when (user.authProvider) {
                    AuthProvider.GOOGLE -> AuthProvider.GOOGLE
                    else -> AuthProvider.LOCAL_GOOGLE
                },
                updatedAt = LocalDateTime.now()
            )
            return toUserDto(userRepository.save(linkedUser))
        }

        val fallbackName = googleUser.email.substringBefore("@").ifBlank { "Google" }
        val user = User(
            email = googleUser.email,
            passwordHash = null,
            authProvider = AuthProvider.GOOGLE,
            googleSub = googleUser.sub,
            firstName = googleUser.givenName?.trim()?.takeIf { it.isNotEmpty() } ?: fallbackName,
            lastName = googleUser.familyName?.trim() ?: "",
            dateOfBirth = "",
            userType = UserType.PATIENT,
            isActive = true,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )

        return toUserDto(userRepository.save(user))
    }

    fun updateUser(id: Long, request: UpdateUserRequest): UserDto {
        val user = userRepository.findById(id)
            .orElseThrow { IllegalArgumentException("User not found") }

        val normalizedEmail = request.email?.trim().orEmpty()
        if (normalizedEmail.isNotEmpty() && normalizedEmail != user.email && userRepository.existsByEmail(normalizedEmail)) {
            throw IllegalArgumentException("Email already exists")
        }

        val normalizedUserType = request.userType?.trim()?.takeIf { it.isNotEmpty() }?.let {
            UserType.valueOf(it)
        } ?: user.userType
        
        val updatedUser = user.copy(
            email = if (normalizedEmail.isNotEmpty()) normalizedEmail else user.email,
            firstName = request.firstName ?: user.firstName,
            lastName = request.lastName ?: user.lastName,
            dateOfBirth = request.dateOfBirth ?: user.dateOfBirth,
            userType = normalizedUserType,
            medicalConditions = request.medicalConditions ?: user.medicalConditions,
            allergies = request.allergies ?: user.allergies,
            height = request.height ?: user.height,
            weight = request.weight ?: user.weight,
            bloodType = request.bloodType ?: user.bloodType,
            emergencyContactName = request.emergencyContactName ?: user.emergencyContactName,
            emergencyContactPhone = request.emergencyContactPhone ?: user.emergencyContactPhone,
            chronicConditions = request.chronicConditions?.joinToString(",") ?: user.chronicConditions,
            pastSurgeries = request.pastSurgeries?.let { objectMapper.writeValueAsString(it) } ?: user.pastSurgeries,
            familyHistory = request.familyHistory?.let { objectMapper.writeValueAsString(it) } ?: user.familyHistory,
            vaccinations = request.vaccinations?.let { objectMapper.writeValueAsString(it) } ?: user.vaccinations,
            organDonor = request.organDonor ?: user.organDonor,
            doctorName = request.doctorName ?: user.doctorName,
            doctorClinic = request.doctorClinic ?: user.doctorClinic,
            doctorPhone = request.doctorPhone ?: user.doctorPhone,
            insuranceProvider = request.insuranceProvider ?: user.insuranceProvider,
            insurancePolicyNumber = request.insurancePolicyNumber ?: user.insurancePolicyNumber,
            profilePhotoBase64 = request.profilePhotoBase64 ?: user.profilePhotoBase64,
            isActive = request.isActive ?: user.isActive,
            updatedAt = LocalDateTime.now()
        )
        
        val savedUser = userRepository.save(updatedUser)
        return toUserDto(savedUser)
    }

    fun deleteUser(id: Long): Boolean {
        val user = userRepository.findById(id)
            .orElseThrow { IllegalArgumentException("User not found") }
        
        val deactivatedUser = user.copy(isActive = false, updatedAt = LocalDateTime.now())
        userRepository.save(deactivatedUser)
        return true
    }

    fun getAllUsers(): List<UserDto> {
        // Return only active users with essential data (no profile photos to reduce payload)
        return userRepository.findAllByIsActiveTrue().map { toUserDtoWithoutPhoto(it) }
    }

    private fun toUserDto(user: User): UserDto {
        return UserDto(
            id = user.id,
            email = user.email,
            firstName = user.firstName,
            lastName = user.lastName,
            dateOfBirth = user.dateOfBirth,
            userType = user.userType.toString(),
            medicalConditions = user.medicalConditions,
            allergies = user.allergies,
            height = user.height,
            weight = user.weight,
            bloodType = user.bloodType,
            emergencyContactName = user.emergencyContactName,
            emergencyContactPhone = user.emergencyContactPhone,
            chronicConditions = user.chronicConditions?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() } ?: emptyList(),
            pastSurgeries = parseJsonField(user.pastSurgeries),
            familyHistory = parseJsonField(user.familyHistory),
            vaccinations = parseJsonField(user.vaccinations),
            organDonor = user.organDonor,
            doctorName = user.doctorName,
            doctorClinic = user.doctorClinic,
            doctorPhone = user.doctorPhone,
            insuranceProvider = user.insuranceProvider,
            insurancePolicyNumber = user.insurancePolicyNumber,
            profilePhotoBase64 = user.profilePhotoBase64,
            isActive = user.isActive
        )
    }

    private fun toUserDtoWithoutPhoto(user: User): UserDto {
        // Lightweight version without profile photo for list operations
        return UserDto(
            id = user.id,
            email = user.email,
            firstName = user.firstName,
            lastName = user.lastName,
            dateOfBirth = user.dateOfBirth,
            userType = user.userType.toString(),
            medicalConditions = user.medicalConditions,
            allergies = user.allergies,
            height = user.height,
            weight = user.weight,
            bloodType = user.bloodType,
            emergencyContactName = user.emergencyContactName,
            emergencyContactPhone = user.emergencyContactPhone,
            chronicConditions = user.chronicConditions?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() } ?: emptyList(),
            pastSurgeries = parseJsonField(user.pastSurgeries),
            familyHistory = parseJsonField(user.familyHistory),
            vaccinations = parseJsonField(user.vaccinations),
            organDonor = user.organDonor,
            doctorName = user.doctorName,
            doctorClinic = user.doctorClinic,
            doctorPhone = user.doctorPhone,
            insuranceProvider = user.insuranceProvider,
            insurancePolicyNumber = user.insurancePolicyNumber,
            profilePhotoBase64 = null, // Don't return photo in list operations
            isActive = user.isActive
        )
    }

    private fun parseJsonField(jsonString: String?): List<Map<String, Any>> {
        return if (!jsonString.isNullOrEmpty()) {
            try {
                @Suppress("UNCHECKED_CAST")
                objectMapper.readValue(jsonString, List::class.java) as List<Map<String, Any>>
            } catch (e: Exception) {
                emptyList()
            }
        } else {
            emptyList()
        }
    }

    fun saveProfilePhoto(userId: Long, base64: String): UserDto {
        val user = userRepository.findById(userId).orElseThrow { IllegalArgumentException("User not found") }
        val updated = user.copy(profilePhotoBase64 = base64, updatedAt = LocalDateTime.now())
        val saved = userRepository.save(updated)
        return toUserDto(saved)
    }
}

