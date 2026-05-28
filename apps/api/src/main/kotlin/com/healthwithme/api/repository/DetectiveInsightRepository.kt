package com.healthwithme.api.repository

import com.healthwithme.api.model.DetectiveInsight
import com.healthwithme.api.model.TimeRange
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface DetectiveInsightRepository : JpaRepository<DetectiveInsight, Long> {
    fun findByUserIdOrderByGeneratedAtDesc(userId: Long): List<DetectiveInsight>
    fun findByUserIdAndTimeRangeOrderByGeneratedAtDesc(userId: Long, timeRange: TimeRange): List<DetectiveInsight>
    fun findFirstByUserIdAndTimeRangeOrderByGeneratedAtDesc(userId: Long, timeRange: TimeRange): DetectiveInsight?
    fun findByUserIdAndGeneratedAtAfterOrderByGeneratedAtDesc(userId: Long, after: LocalDateTime): List<DetectiveInsight>
}
