package com.healthwithme.api.repository

import com.healthwithme.api.model.Medicine
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface MedicineRepository : JpaRepository<Medicine, Long> {
    fun findByUserId(userId: Long): List<Medicine>
    fun findByUserIdAndIsActive(userId: Long, isActive: Boolean): List<Medicine>
}

