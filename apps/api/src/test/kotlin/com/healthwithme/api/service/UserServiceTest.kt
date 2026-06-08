package com.healthwithme.api.service

import com.healthwithme.api.model.User
import com.healthwithme.api.model.AuthProvider
import com.healthwithme.api.model.UserType
import com.healthwithme.api.repository.FriendshipRepository
import com.healthwithme.api.repository.UserRepository
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test
import org.mockito.ArgumentCaptor
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import java.time.LocalDateTime
import java.util.Optional

class UserServiceTest {

    private val userRepository: UserRepository = mock(UserRepository::class.java)
    private val friendshipRepository: FriendshipRepository = mock(FriendshipRepository::class.java)
    private val passwordEncoder = BCryptPasswordEncoder()
    private val userService = UserService(userRepository, passwordEncoder, friendshipRepository)

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

    @Test
    fun `login rejects Google-only user without password hash`() {
        val user = user(
            passwordHash = null,
            authProvider = AuthProvider.GOOGLE,
            googleSub = "google-sub"
        )
        `when`(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(user))

        assertThatThrownBy { userService.login("ana@example.com", "secret") }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessage("Invalid email or password")
    }

    @Test
    fun `loginWithGoogle creates new Google user`() {
        val googleUser = googleUser()
        `when`(userRepository.findByGoogleSub("google-sub")).thenReturn(Optional.empty())
        `when`(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.empty())
        `when`(userRepository.save(any(User::class.java))).thenAnswer { invocation ->
            invocation.getArgument<User>(0).copy(id = 2)
        }

        val result = userService.loginWithGoogle(googleUser)

        assertThat(result.id).isEqualTo(2)
        assertThat(result.email).isEqualTo("ana@example.com")
        assertThat(result.firstName).isEqualTo("Ana")
        assertThat(result.lastName).isEqualTo("Novak")
        assertThat(result.userType).isEqualTo("PATIENT")
        assertThat(result.dateOfBirth).isEmpty()
    }

    @Test
    fun `loginWithGoogle returns existing user by googleSub`() {
        val user = user(
            passwordHash = null,
            authProvider = AuthProvider.GOOGLE,
            googleSub = "google-sub"
        )
        `when`(userRepository.findByGoogleSub("google-sub")).thenReturn(Optional.of(user))

        val result = userService.loginWithGoogle(googleUser())

        assertThat(result.id).isEqualTo(1)
        assertThat(result.email).isEqualTo("ana@example.com")
    }

    @Test
    fun `loginWithGoogle links existing LOCAL user by verified email`() {
        val user = user(passwordHash = passwordEncoder.encode("secret"))
        `when`(userRepository.findByGoogleSub("google-sub")).thenReturn(Optional.empty())
        `when`(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(user))
        `when`(userRepository.save(any(User::class.java))).thenAnswer { invocation ->
            invocation.getArgument<User>(0)
        }

        val result = userService.loginWithGoogle(googleUser())

        assertThat(result.email).isEqualTo("ana@example.com")
        assertThat(result.id).isEqualTo(1)
        val captor = ArgumentCaptor.forClass(User::class.java)
        verify(userRepository).save(captor.capture())
        assertThat(captor.value.googleSub).isEqualTo("google-sub")
        assertThat(captor.value.authProvider).isEqualTo(AuthProvider.LOCAL_GOOGLE)
    }

    @Test
    fun `loginWithGoogle rejects unverified email`() {
        assertThatThrownBy { userService.loginWithGoogle(googleUser(emailVerified = false)) }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessage("Invalid Google token")
    }

    private fun user(
        passwordHash: String?,
        isActive: Boolean = true,
        authProvider: AuthProvider = AuthProvider.LOCAL,
        googleSub: String? = null
    ) = User(
        id = 1,
        email = "ana@example.com",
        passwordHash = passwordHash,
        authProvider = authProvider,
        googleSub = googleSub,
        firstName = "Ana",
        lastName = "Novak",
        dateOfBirth = "1994-03-10",
        userType = UserType.PATIENT,
        isActive = isActive,
        createdAt = LocalDateTime.now(),
        updatedAt = LocalDateTime.now()
    )

    private fun googleUser(emailVerified: Boolean = true) = GoogleUserInfo(
        sub = "google-sub",
        email = "ana@example.com",
        emailVerified = emailVerified,
        givenName = "Ana",
        familyName = "Novak",
        picture = "https://example.com/photo.jpg"
    )
}
