package com.healthwithme.api.repository

import com.healthwithme.api.model.Friendship
import com.healthwithme.api.model.FriendshipStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param

interface FriendshipRepository : JpaRepository<Friendship, Long> {

    fun findByRequesterIdAndAddresseeId(requesterId: Long, addresseeId: Long): Friendship?

    fun findByAddresseeIdAndStatus(addresseeId: Long, status: FriendshipStatus): List<Friendship>

    fun findByRequesterIdAndStatus(requesterId: Long, status: FriendshipStatus): List<Friendship>

    /** Accepted friendships involving [userId] on either side. */
    @Query(
        """
        SELECT f FROM Friendship f
        WHERE f.status = com.healthwithme.api.model.FriendshipStatus.ACCEPTED
          AND (f.requester.id = :userId OR f.addressee.id = :userId)
        """
    )
    fun findAcceptedForUser(@Param("userId") userId: Long): List<Friendship>
}
