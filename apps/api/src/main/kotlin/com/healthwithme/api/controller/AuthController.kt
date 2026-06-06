package com.healthwithme.api.controller

import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.dto.GoogleLoginRequest
import com.healthwithme.api.dto.LoginRequest
import com.healthwithme.api.dto.UserDto
import com.healthwithme.api.service.GoogleTokenVerifier
import com.healthwithme.api.service.JwtService
import com.healthwithme.api.service.UserService
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/v1/auth")
class AuthController(
    private val userService: UserService,
    private val googleTokenVerifier: GoogleTokenVerifier,
    private val jwtService: JwtService
) {
    private val objectMapper = jacksonObjectMapper()

    @PostMapping("/login")
    fun login(@RequestBody request: LoginRequest): ResponseEntity<ApiResponse<Map<String, Any?>>> {
        return try {
            val user = userService.login(request.email, request.password)
            ResponseEntity.ok(
                ApiResponse(success = true, message = "Login successful", data = authPayload(user))
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                ApiResponse(success = false, message = "Invalid email or password", data = null)
            )
        }
    }

    @PostMapping("/google")
    fun googleLogin(@RequestBody request: GoogleLoginRequest): ResponseEntity<ApiResponse<Map<String, Any?>>> {
        return try {
            val googleUser = googleTokenVerifier.verify(request.idToken)
            val user = userService.loginWithGoogle(googleUser)
            ResponseEntity.ok(
                ApiResponse(success = true, message = "Google login successful", data = authPayload(user))
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                ApiResponse(success = false, message = "Invalid Google token", data = null)
            )
        }
    }

    /** Returns the currently authenticated user, derived from the JWT (set by JwtAuthFilter). */
    @GetMapping("/me")
    fun me(request: HttpServletRequest): ResponseEntity<ApiResponse<UserDto>> {
        val userId = request.getAttribute("authUserId") as? Long
            ?: return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                ApiResponse(success = false, message = "Not authenticated", data = null)
            )
        return try {
            ResponseEntity.ok(
                ApiResponse(success = true, message = "Current user", data = userService.getUserById(userId))
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                ApiResponse(success = false, message = "User not found", data = null)
            )
        }
    }

    /**
     * Backward-compatible auth payload: the user's fields are spread at the top level (so the older
     * app that reads `data.id`/`data.email` keeps working) AND a `token` + nested `user` are added
     * (so the new app reads `data.token`/`data.user`). Both APK versions parse this correctly.
     */
    private fun authPayload(user: UserDto): Map<String, Any?> {
        val map = objectMapper.convertValue(user, object : TypeReference<LinkedHashMap<String, Any?>>() {})
        map["token"] = jwtService.issueToken(user.id, user.email)
        map["user"] = user
        return map
    }
}
