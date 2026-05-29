package com.healthwithme.api.controller

import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.dto.LoginRequest
import com.healthwithme.api.dto.UserDto
import com.healthwithme.api.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/v1/auth")
class AuthController(private val userService: UserService) {

    @PostMapping("/login")
    fun login(@RequestBody request: LoginRequest): ResponseEntity<ApiResponse<UserDto>> {
        return try {
            val user = userService.login(request.email, request.password)
            ResponseEntity.ok(
                ApiResponse(success = true, message = "Login successful", data = user)
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                ApiResponse(success = false, message = "Invalid email or password", data = null)
            )
        }
    }
}
