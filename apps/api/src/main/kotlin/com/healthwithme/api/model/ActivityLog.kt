package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDate

@Entity
@Table(name = "activity_logs")
data class ActivityLog(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,

    @Column(nullable = false)
    val activityDate: LocalDate = LocalDate.now(),

    @Column(nullable = true)
    val steps: Int? = null,

    @Column(nullable = true)
    val calories: Int? = null,

    @Column(nullable = true)
    val heartRateAvg: Int? = null,

    @Column(nullable = true)
    val source: String? = null
)