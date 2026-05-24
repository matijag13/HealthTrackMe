package com.healthwithme.api.service

import com.healthwithme.api.dto.CreateUserRequest
import com.healthwithme.api.dto.UpdateUserRequest
import com.healthwithme.api.dto.UserDto
import com.healthwithme.api.model.User
import com.healthwithme.api.repository.UserRepository
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder
) {

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
            userType = com.healthwithme.api.model.UserType.valueOf(request.userType),
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

    fun updateUser(id: Long, request: UpdateUserRequest): UserDto {
        val user = userRepository.findById(id)
            .orElseThrow { IllegalArgumentException("User not found") }

        val normalizedEmail = request.email?.trim().orEmpty()
        if (normalizedEmail.isNotEmpty() && normalizedEmail != user.email && userRepository.existsByEmail(normalizedEmail)) {
            throw IllegalArgumentException("Email already exists")
        }

        val normalizedUserType = request.userType?.trim()?.takeIf { it.isNotEmpty() }?.let {
            com.healthwithme.api.model.UserType.valueOf(it)
        } ?: user.userType
        
        val updatedUser = user.copy(
            email = if (normalizedEmail.isNotEmpty()) normalizedEmail else user.email,
            firstName = request.firstName ?: user.firstName,
            lastName = request.lastName ?: user.lastName,
            dateOfBirth = request.dateOfBirth ?: user.dateOfBirth,
            userType = normalizedUserType,
            medicalConditions = request.medicalConditions ?: user.medicalConditions,
            allergies = request.allergies ?: user.allergies,
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
        return userRepository.findAll().map { toUserDto(it) }
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
            isActive = user.isActive
        )
    }
}

