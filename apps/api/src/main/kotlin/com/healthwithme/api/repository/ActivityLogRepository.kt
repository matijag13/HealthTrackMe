package com.healthwithme.api.repository

import com.healthwithme.api.model.ActivityLog
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface ActivityLogRepository : JpaRepository<ActivityLog, Long> {
    fun findByUserIdOrderByActivityDateDesc(userId: Long): List<ActivityLog>
    fun findByUserIdAndActivityDate(userId: Long, activityDate: LocalDate): List<ActivityLog>
}