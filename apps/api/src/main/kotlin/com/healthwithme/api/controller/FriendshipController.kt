package com.healthwithme.api.controller

import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.dto.FriendDto
import com.healthwithme.api.dto.LeaderboardEntryDto
import com.healthwithme.api.dto.SendFriendRequestDto
import com.healthwithme.api.service.FriendshipService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

/**
 * Friends + gamification leaderboard. Every route is scoped to `/users/{userId}`
 * so the JWT ownership filter guarantees a user can only manage their own social
 * graph. Only Health Shield points + streak are ever exposed — no health data.
 */
@RestController
@RequestMapping("/api/v1/friends")
class FriendshipController(
    private val friendshipService: FriendshipService
) {

    @GetMapping("/users/{userId}/leaderboard")
    fun leaderboard(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<LeaderboardEntryDto>>> =
        ok("Leaderboard", friendshipService.leaderboard(userId))

    @GetMapping("/users/{userId}")
    fun friends(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<FriendDto>>> =
        ok("Friends", friendshipService.listFriends(userId))

    @GetMapping("/users/{userId}/requests/incoming")
    fun incoming(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<FriendDto>>> =
        ok("Incoming requests", friendshipService.listIncoming(userId))

    @GetMapping("/users/{userId}/requests/outgoing")
    fun outgoing(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<FriendDto>>> =
        ok("Outgoing requests", friendshipService.listOutgoing(userId))

    @PostMapping("/users/{userId}/requests")
    fun sendRequest(
        @PathVariable userId: Long,
        @RequestBody body: SendFriendRequestDto
    ): ResponseEntity<ApiResponse<FriendDto>> = try {
        ok("Request sent", friendshipService.sendRequest(userId, body.email))
    } catch (e: IllegalArgumentException) {
        badRequest(e.message)
    }

    @PostMapping("/users/{userId}/requests/{friendshipId}/accept")
    fun accept(
        @PathVariable userId: Long,
        @PathVariable friendshipId: Long
    ): ResponseEntity<ApiResponse<FriendDto>> = try {
        ok("Request accepted", friendshipService.respond(userId, friendshipId, accept = true))
    } catch (e: IllegalArgumentException) {
        badRequest(e.message)
    }

    @PostMapping("/users/{userId}/requests/{friendshipId}/decline")
    fun decline(
        @PathVariable userId: Long,
        @PathVariable friendshipId: Long
    ): ResponseEntity<ApiResponse<FriendDto>> = try {
        ok("Request declined", friendshipService.respond(userId, friendshipId, accept = false))
    } catch (e: IllegalArgumentException) {
        badRequest(e.message)
    }

    @DeleteMapping("/users/{userId}/{friendshipId}")
    fun remove(
        @PathVariable userId: Long,
        @PathVariable friendshipId: Long
    ): ResponseEntity<ApiResponse<Boolean>> = try {
        friendshipService.removeFriend(userId, friendshipId)
        ok("Friend removed", true)
    } catch (e: IllegalArgumentException) {
        badRequest(e.message)
    }

    private fun <T> ok(message: String, data: T): ResponseEntity<ApiResponse<T>> =
        ResponseEntity.ok(ApiResponse(success = true, message = message, data = data))

    private fun <T> badRequest(message: String?): ResponseEntity<ApiResponse<T>> =
        ResponseEntity.badRequest()
            .body(ApiResponse(success = false, message = message ?: "Request failed", data = null))
}
