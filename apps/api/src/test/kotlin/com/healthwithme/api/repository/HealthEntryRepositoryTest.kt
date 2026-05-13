package com.healthwithme.api.repository

import com.healthwithme.api.model.HealthEntry
import com.healthwithme.api.model.User
import com.healthwithme.api.model.UserRole
import com.healthwithme.api.model.UserType
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.test.context.ActiveProfiles
import java.time.LocalDate
import java.time.LocalDateTime

@DataJpaTest
@ActiveProfiles("test")
class HealthEntryRepositoryTest @Autowired constructor(
    private val userRepository: UserRepository,
    private val healthEntryRepository: HealthEntryRepository
) {

    @Test
    fun findByUserIdAndEntryDate_returnsEntryForExactDate() {
        val user = userRepository.save(
            User(
                email = "miha@example.com",
                passwordHash = "hashed-password",
                firstName = "Miha",
                lastName = "Kranjc",
                role = UserRole.USER,
                gdprConsentAccepted = true,
                gdprConsentAcceptedAt = LocalDateTime.now(),
                dateOfBirth = "1991-08-12",
                userType = UserType.PATIENT,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        )

        val entryDate = LocalDate.of(2026, 5, 13)
        healthEntryRepository.save(
            HealthEntry(
                user = user,
                entryDate = entryDate,
                wellbeingScore = 7,
                symptoms = "headache,nausea",
                mood = "neutral",
                energyLevel = 6,
                stressLevel = 4,
                doctorNotes = "Hydration recommended",
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        )

        val found = healthEntryRepository.findByUserIdAndEntryDate(user.id, entryDate)

        assertThat(found).isNotNull
        assertThat(found?.wellbeingScore).isEqualTo(7)
    }

    @Test
    fun findByUserIdOrderByEntryDateDesc_returnsSortedEntries() {
        val user = userRepository.save(
            User(
                email = "matej@example.com",
                passwordHash = "hashed-password",
                firstName = "Matej",
                lastName = "Novak",
                role = UserRole.USER,
                gdprConsentAccepted = true,
                gdprConsentAcceptedAt = LocalDateTime.now(),
                dateOfBirth = "1990-01-01",
                userType = UserType.PATIENT,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        )

        healthEntryRepository.save(
            HealthEntry(
                user = user,
                entryDate = LocalDate.of(2026, 5, 10),
                wellbeingScore = 5,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        )
        healthEntryRepository.save(
            HealthEntry(
                user = user,
                entryDate = LocalDate.of(2026, 5, 12),
                wellbeingScore = 8,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now()
            )
        )

        val entries = healthEntryRepository.findByUserIdOrderByEntryDateDesc(user.id)

        assertThat(entries).hasSize(2)
        assertThat(entries[0].entryDate).isEqualTo(LocalDate.of(2026, 5, 12))
        assertThat(entries[1].entryDate).isEqualTo(LocalDate.of(2026, 5, 10))
    }
}