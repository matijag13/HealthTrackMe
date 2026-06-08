package com.healthwithme.api.repository

import com.healthwithme.api.model.Friendship
import com.healthwithme.api.model.FriendshipStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param

interface FriendshipRepository : JpaRepository<Friendship, Long> {

    fun findByRequesterIdAndAddresseeId(requesterId: Long, addresseeId: Long): Friendship?

    fun findByAddresseeIdAndStatus(addresseeId: Long, status: FriendshipStatus): List<Friendship>

    fun findByRequesterIdAndStatus(requesterId: Long, status: FriendshipStatus): List<Friendship>

    /** Friendships with [status] involving [userId] on either side. */
    @Query(
        """
        SELECT f FROM Friendship f
        WHERE f.status = :status
          AND (f.requester.id = :userId OR f.addressee.id = :userId)
        """
    )
    fun findForUserWithStatus(
        @Param("userId") userId: Long,
        @Param("status") status: FriendshipStatus
    ): List<Friendship>

    @Modifying
    @Query(
        """
        DELETE FROM Friendship f
        WHERE f.requester.id = :userId OR f.addressee.id = :userId
        """
    )
    fun deleteAllForUser(@Param("userId") userId: Long): Int
}
