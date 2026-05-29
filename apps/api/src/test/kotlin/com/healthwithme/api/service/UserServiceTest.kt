package com.healthwithme.api.service

import com.healthwithme.api.model.User
import com.healthwithme.api.model.UserType
import com.healthwithme.api.repository.UserRepository
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import java.time.LocalDateTime
import java.util.Optional

class UserServiceTest {

    private val userRepository: UserRepository = mock(UserRepository::class.java)
    private val passwordEncoder = BCryptPasswordEncoder()
    private val userService = UserService(userRepository, passwordEncoder)

    @Test
    fun `login returns user when password matches bcrypt hash`() {
        val user = user(passwordHash = passwordEncoder.encode("secret"))
        `when`(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(user))

        val result = userService.login("ana@example.com", "secret")

        assertThat(result.email).isEqualTo("ana@example.com")
        assertThat(result.id).isEqualTo(1)
    }

    @Test
    fun `login rejects wrong password`() {
        val user = user(passwordHash = passwordEncoder.encode("secret"))
        `when`(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(user))

        assertThatThrownBy { userService.login("ana@example.com", "wrong") }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessage("Invalid email or password")
    }

    @Test
    fun `login rejects inactive user`() {
        val user = user(
            passwordHash = passwordEncoder.encode("secret"),
            isActive = false
        )
        `when`(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(user))

        assertThatThrownBy { userService.login("ana@example.com", "secret") }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessage("Invalid email or password")
    }

    private fun user(
        passwordHash: String,
        isActive: Boolean = true
    ) = User(
        id = 1,
        email = "ana@example.com",
        passwordHash = passwordHash,
        firstName = "Ana",
        lastName = "Novak",
        dateOfBirth = "1994-03-10",
        userType = UserType.PATIENT,
        isActive = isActive,
        createdAt = LocalDateTime.now(),
        updatedAt = LocalDateTime.now()
    )
}
