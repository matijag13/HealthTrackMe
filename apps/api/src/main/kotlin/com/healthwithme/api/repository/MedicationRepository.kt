package com.healthwithme.api.repository

import com.healthwithme.api.model.Medication
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface MedicationRepository : JpaRepository<Medication, Long> {
    fun findByUserIdAndActiveTrue(userId: Long): List<Medication>
}