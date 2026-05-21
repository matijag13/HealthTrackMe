package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "medications")
data class Medication(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    val user: User? = null,

    @Column(nullable = false)
    val name: String = "",

    @Column(nullable = false)
    val dosage: String = "",

    @Column(nullable = false)
    val frequency: String = "",

    @Column(columnDefinition = "TEXT")
    val instructions: String? = null,

    @Column(nullable = false, name = "item_type")
    @Enumerated(EnumType.STRING)
    val itemType: ItemType = ItemType.MEDICATION,

    @Column(nullable = false)
    val active: Boolean = true,

    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @OneToMany(mappedBy = "medication", cascade = [CascadeType.ALL], orphanRemoval = true)
    val doseLogs: MutableList<DoseLog> = mutableListOf()
)

enum class ItemType {
    MEDICATION,
    VITAMIN,
    SUPPLEMENT,
    OTHER
}