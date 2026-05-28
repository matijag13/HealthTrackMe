package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "detective_insights")
data class DetectiveInsight(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,

    @Column(nullable = false)
    val badge: String = "", // e.g., "✨ Strong week"

    @Column(nullable = false)
    val title: String = "", // e.g., "Your consistency is paying off"

    @Column(columnDefinition = "TEXT")
    val description: String = "", // Detailed insight about patterns

    @Column(columnDefinition = "TEXT")
    val finding: String = "", // Key pattern discovered

    @Column(columnDefinition = "TEXT")
    val correlations: String = "", // JSON string of correlations

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val timeRange: TimeRange = TimeRange.WEEK, // WEEK, MONTH, ALL_TIME

    @Column(nullable = false)
    val generatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

enum class TimeRange {
    WEEK,
    MONTH,
    ALL_TIME
}
