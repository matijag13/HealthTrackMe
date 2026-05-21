package com.healthwithme.api.repository

import com.healthwithme.api.model.HealthShieldStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface HealthShieldStatusRepository : JpaRepository<HealthShieldStatus, Long> {
    fun findByUserId(userId: Long): HealthShieldStatus?
}
