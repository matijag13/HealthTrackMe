package com.healthwithme.api.repository

import com.healthwithme.api.model.DoseLog
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface DoseLogRepository : JpaRepository<DoseLog, Long> {
    fun findByMedicineIdOrderByScheduledTimeDesc(medicineId: Long): List<DoseLog>
    fun findByMedicineId(medicineId: Long): List<DoseLog>
}