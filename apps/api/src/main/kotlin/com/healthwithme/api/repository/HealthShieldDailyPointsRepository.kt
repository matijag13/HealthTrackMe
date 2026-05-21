package com.healthwithme.api.repository

import com.healthwithme.api.model.HealthShieldDailyPoints
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface HealthShieldDailyPointsRepository : JpaRepository<HealthShieldDailyPoints, Long> {
    fun findByUserIdAndCalculationDate(userId: Long, calculationDate: LocalDate): HealthShieldDailyPoints?
}
