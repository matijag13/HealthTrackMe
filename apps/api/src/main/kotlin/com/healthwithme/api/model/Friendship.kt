package com.healthwithme.api.model

import jakarta.persistence.*
import java.time.LocalDateTime

/**
 * A social connection between two users, used only for the gamification
 * leaderboard. [requester] sent the request to [addressee]; once [status] is
 * ACCEPTED they're friends and can see each other's Health Shield points + streak
 * on the leaderboard. No health data is shared through this relationship.
 */
@Entity
@Table(name = "friendships")
data class Friendship(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "requester_id", nullable = false)
    val requester: User? = null,

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "addressee_id", nullable = false)
    val addressee: User? = null,

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    val status: FriendshipStatus = FriendshipStatus.PENDING,

    @Column(nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

enum class FriendshipStatus {
    PENDING,
    ACCEPTED,
    DECLINED
}
