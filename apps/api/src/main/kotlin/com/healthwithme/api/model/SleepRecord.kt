package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDate

@Entity
@Table(name = "sleep_records")
data class SleepRecord(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,

    @Column(nullable = false)
    val sleepDate: LocalDate = LocalDate.now(),

    @Column(nullable = false)
    val durationMinutes: Int = 0,

    @Column(nullable = true)
    val qualityScore: Int? = null,

    @Column(nullable = true)
    val source: String? = null
)