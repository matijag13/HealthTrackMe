package com.healthwithme.api.service

import com.healthwithme.api.dto.FriendDto
import com.healthwithme.api.dto.LeaderboardEntryDto
import com.healthwithme.api.model.Friendship
import com.healthwithme.api.model.FriendshipStatus
import com.healthwithme.api.model.User
import com.healthwithme.api.repository.FriendshipRepository
import com.healthwithme.api.repository.HealthEntryRepository
import com.healthwithme.api.repository.UserRepository
import org.springframework.stereotype.Service
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * Social graph for the gamification leaderboard. Friends can see each other's
 * Health Shield points + logging streak — never any underlying health data.
 */
@Service
class FriendshipService(
    private val friendshipRepository: FriendshipRepository,
    private val userRepository: UserRepository,
    private val healthEntryRepository: HealthEntryRepository,
    private val healthShieldService: HealthShieldService
) {

    fun sendRequest(requesterId: Long, rawEmail: String): FriendDto {
        val email = rawEmail.trim().lowercase()
        if (email.isBlank()) throw IllegalArgumentException("Email is required")

        val requester = userRepository.findById(requesterId)
            .orElseThrow { IllegalArgumentException("User not found") }
        val addressee = userRepository.findByEmail(email)
            .orElseThrow { IllegalArgumentException("No user with that email") }

        if (addressee.id == requesterId) {
            throw IllegalArgumentException("You can't add yourself")
        }

        // Resurrect a previously declined request, or block active duplicates.
        val outgoing = friendshipRepository.findByRequesterIdAndAddresseeId(requesterId, addressee.id)
        val incoming = friendshipRepository.findByRequesterIdAndAddresseeId(addressee.id, requesterId)
        val existing = outgoing ?: incoming
        if (existing != null) {
            when (existing.status) {
                FriendshipStatus.ACCEPTED -> throw IllegalArgumentException("You're already friends")
                FriendshipStatus.PENDING -> throw IllegalArgumentException("A request is already pending")
                FriendshipStatus.DECLINED -> {
                    val revived = existing.copy(
                        requester = requester,
                        addressee = addressee,
                        status = FriendshipStatus.PENDING,
                        updatedAt = LocalDateTime.now()
                    )
                    return toFriendDto(friendshipRepository.save(revived), requesterId)
                }
            }
        }

        val saved = friendshipRepository.save(
            Friendship(requester = requester, addressee = addressee, status = FriendshipStatus.PENDING)
        )
        return toFriendDto(saved, requesterId)
    }

    fun respond(userId: Long, friendshipId: Long, accept: Boolean): FriendDto {
        val friendship = friendshipRepository.findById(friendshipId)
            .orElseThrow { IllegalArgumentException("Request not found") }
        if (friendship.addressee?.id != userId) {
            throw IllegalArgumentException("You can only respond to requests sent to you")
        }
        if (friendship.status != FriendshipStatus.PENDING) {
            throw IllegalArgumentException("This request has already been handled")
        }
        val updated = friendship.copy(
            status = if (accept) FriendshipStatus.ACCEPTED else FriendshipStatus.DECLINED,
            updatedAt = LocalDateTime.now()
        )
        return toFriendDto(friendshipRepository.save(updated), userId)
    }

    fun removeFriend(userId: Long, friendshipId: Long) {
        val friendship = friendshipRepository.findById(friendshipId)
            .orElseThrow { IllegalArgumentException("Friendship not found") }
        if (friendship.requester?.id != userId && friendship.addressee?.id != userId) {
            throw IllegalArgumentException("Not your friendship")
        }
        friendshipRepository.delete(friendship)
    }

    fun listFriends(userId: Long): List<FriendDto> =
        friendshipRepository.findAcceptedForUser(userId).map { toFriendDto(it, userId) }

    fun listIncoming(userId: Long): List<FriendDto> =
        friendshipRepository.findByAddresseeIdAndStatus(userId, FriendshipStatus.PENDING)
            .map { toFriendDto(it, userId) }

    fun listOutgoing(userId: Long): List<FriendDto> =
        friendshipRepository.findByRequesterIdAndStatus(userId, FriendshipStatus.PENDING)
            .map { toFriendDto(it, userId) }

    /** Ranks the user and their accepted friends by Health Shield points (streak breaks ties). */
    fun leaderboard(userId: Long): List<LeaderboardEntryDto> {
        val friends = friendshipRepository.findAcceptedForUser(userId)
            .mapNotNull { other(it, userId) }
        val me = userRepository.findById(userId).orElseThrow { IllegalArgumentException("User not found") }

        val people = (listOf(me) + friends).distinctBy { it.id }
        val scored = people.map { user ->
            val points = runCatching {
                healthShieldService.getHealthShieldForUser(user.id)
            }.getOrNull()
            Triple(user, points, currentStreak(user.id))
        }.sortedWith(
            compareByDescending<Triple<User, com.healthwithme.api.dto.HealthShieldResponseDto?, Int>> {
                it.second?.totalConsistencyPoints ?: 0
            }.thenByDescending { it.third }
        )

        return scored.mapIndexed { index, (user, shield, streak) ->
            LeaderboardEntryDto(
                userId = user.id,
                name = displayName(user),
                profilePhotoBase64 = user.profilePhotoBase64,
                level = shield?.level ?: 1,
                levelName = shield?.levelName ?: "Basic Shield",
                points = shield?.totalConsistencyPoints ?: 0,
                streak = streak,
                isMe = user.id == userId,
                rank = index + 1
            )
        }
    }

    /** Consecutive days with a health entry, ending today or yesterday (the logging streak). */
    private fun currentStreak(userId: Long): Int {
        val days = healthEntryRepository.findByUserIdOrderByEntryDateDesc(userId)
            .map { it.entryDate }
            .toSortedSet(reverseOrder())
        if (days.isEmpty()) return 0

        val today = LocalDate.now()
        var cursor = when {
            days.contains(today) -> today
            days.contains(today.minusDays(1)) -> today.minusDays(1)
            else -> return 0
        }
        var streak = 0
        while (days.contains(cursor)) {
            streak++
            cursor = cursor.minusDays(1)
        }
        return streak
    }

    private fun other(f: Friendship, userId: Long): User? =
        if (f.requester?.id == userId) f.addressee else f.requester

    private fun toFriendDto(f: Friendship, userId: Long): FriendDto {
        val them = other(f, userId) ?: f.addressee ?: f.requester!!
        val direction = when {
            f.status == FriendshipStatus.ACCEPTED -> "FRIEND"
            f.requester?.id == userId -> "OUTGOING"
            else -> "INCOMING"
        }
        return FriendDto(
            friendshipId = f.id,
            userId = them.id,
            name = displayName(them),
            email = them.email,
            profilePhotoBase64 = them.profilePhotoBase64,
            status = f.status.name,
            direction = direction
        )
    }

    private fun displayName(user: User): String {
        val full = "${user.firstName} ${user.lastName}".trim()
        return if (full.isBlank()) user.email else full
    }
}
