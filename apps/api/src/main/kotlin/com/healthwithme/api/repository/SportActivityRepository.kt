package com.healthwithme.api.repository

import com.healthwithme.api.model.SportActivity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface SportActivityRepository : JpaRepository<SportActivity, Long> {
    fun findByUserId(userId: Long): List<SportActivity>
    fun findByUserIdOrderByActivityDateDesc(userId: Long): List<SportActivity>
    fun findByUserIdAndActivityDateBetween(userId: Long, startDate: String, endDate: String): List<SportActivity>

    /** All activities for a user on a specific date (used for dedup checks). */
    fun findByUserIdAndActivityTypeAndActivityDate(
        userId: Long,
        activityType: String,
        activityDate: String,
    ): List<SportActivity>
}

