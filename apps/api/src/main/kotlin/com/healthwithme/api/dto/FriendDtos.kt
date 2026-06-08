package com.healthwithme.api.dto

/** Request body for sending a friend request by the other person's email. */
data class SendFriendRequestDto(
    val email: String = ""
)

/**
 * A friend or pending request, from the perspective of the requesting user.
 * [direction] is FRIEND (accepted), INCOMING (they asked you), or OUTGOING (you asked them).
 */
data class FriendDto(
    val friendshipId: Long,
    val userId: Long,
    val name: String,
    val email: String,
    val profilePhotoBase64: String?,
    val status: String,
    val direction: String
)

/** One row of the gamification leaderboard. Only points/level/streak are exposed — no health data. */
data class LeaderboardEntryDto(
    val userId: Long,
    val name: String,
    val profilePhotoBase64: String?,
    val level: Int,
    val levelName: String,
    val points: Int,
    val streak: Int,
    val isMe: Boolean,
    val rank: Int
)
