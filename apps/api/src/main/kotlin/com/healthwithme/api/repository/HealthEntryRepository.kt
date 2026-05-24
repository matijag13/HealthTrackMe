package com.healthwithme.api.repository

import com.healthwithme.api.model.HealthEntry
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface HealthEntryRepository : JpaRepository<HealthEntry, Long> {
    fun findByUserId(userId: Long): List<HealthEntry>
    fun findByUserIdOrderByEntryDateDesc(userId: Long): List<HealthEntry>
    fun findByUserIdAndEntryDate(userId: Long, entryDate: LocalDate): HealthEntry?
    fun findByUserIdAndEntryDateOrderByCreatedAtDesc(userId: Long, entryDate: LocalDate): List<HealthEntry>
    fun findByUserIdAndEntryDateBetween(userId: Long, startDate: LocalDate, endDate: LocalDate): List<HealthEntry>
}

