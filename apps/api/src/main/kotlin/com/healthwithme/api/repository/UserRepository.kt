package com.healthwithme.api.repository

import com.healthwithme.api.model.User
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UserRepository : JpaRepository<User, Long> {
    fun findByEmail(email: String): Optional<User>
    fun findByGoogleSub(googleSub: String): Optional<User>
    fun existsByEmail(email: String): Boolean
    fun findAllByIsActiveTrue(): List<User>
}

