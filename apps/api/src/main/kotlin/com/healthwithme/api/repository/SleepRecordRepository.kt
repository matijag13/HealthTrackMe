package com.healthwithme.api.repository

import com.healthwithme.api.model.SleepRecord
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface SleepRecordRepository : JpaRepository<SleepRecord, Long> {
    fun findByUserIdOrderBySleepDateDesc(userId: Long): List<SleepRecord>
    fun findByUserIdAndSleepDate(userId: Long, sleepDate: LocalDate): List<SleepRecord>
}