package com.healthwithme.api.repository

import com.healthwithme.api.model.DoseLog
import com.healthwithme.api.model.DoseStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface DoseLogRepository : JpaRepository<DoseLog, Long> {
    fun findByMedicineIdOrderByScheduledTimeDesc(medicineId: Long): List<DoseLog>
    fun findByMedicineId(medicineId: Long): List<DoseLog>

    /** Find dose logs for a medicine with a given status in the given time window, newest first. */
    @Query(
        "SELECT d FROM DoseLog d WHERE d.medicine.id = :medicineId AND d.status = :status " +
        "AND d.scheduledTime >= :from AND d.scheduledTime < :to ORDER BY d.scheduledTime DESC"
    )
    fun findByMedicineIdAndStatusBetween(
        @Param("medicineId") medicineId: Long,
        @Param("status") status: DoseStatus,
        @Param("from") from: LocalDateTime,
        @Param("to") to: LocalDateTime,
    ): List<DoseLog>
}