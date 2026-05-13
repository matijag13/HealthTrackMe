package com.healthwithme.api.repository

import com.healthwithme.api.model.User
import com.healthwithme.api.model.UserRole
import com.healthwithme.api.model.UserType
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.test.context.ActiveProfiles
import java.time.LocalDateTime

@DataJpaTest
@ActiveProfiles("test")
class UserRepositoryTest @Autowired constructor(
    private val userRepository: UserRepository
) {

    @Test
    fun findByEmail_returnsPersistedUser() {
        val saved = userRepository.save(
            User(
                email = "ana@example.com",
                passwordHash = "hashed-password",
                firstName = "Ana",
                lastName = "Novak",
                role = UserRole.USER,
                gdprConsentAccepted = true,
                gdprConsentAcceptedAt = LocalDateTime.now(),
                dateOfBirth = "1994-03-10",
                userType = UserType.PATIENT,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        )

        val found = userRepository.findByEmail(saved.email)

        assertThat(found).isPresent
        assertThat(found.get().id).isEqualTo(saved.id)
        assertThat(found.get().passwordHash).isEqualTo("hashed-password")
    }
}