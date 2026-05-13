package com.healthwithme.api.repository

import com.healthwithme.api.model.HealthAlert
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface HealthAlertRepository : JpaRepository<HealthAlert, Long> {
    fun findByUserId(userId: Long): List<HealthAlert>
    fun findByUserIdOrderByCreatedAtDesc(userId: Long): List<HealthAlert>
    fun findByUserIdAndIsRead(userId: Long, isRead: Boolean): List<HealthAlert>
}

