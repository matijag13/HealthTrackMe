package com.healthwithme.api.repository

import com.healthwithme.api.model.ActivityLog
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface ActivityLogRepository : JpaRepository<ActivityLog, Long> {
    fun findByUserIdOrderByActivityDateDesc(userId: Long): List<ActivityLog>
}