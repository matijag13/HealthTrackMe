package com.healthwithme.api.controller

import com.healthwithme.api.dto.CreateUserRequest
import com.healthwithme.api.dto.ChangePasswordRequest
import com.healthwithme.api.dto.UpdateUserRequest
import com.healthwithme.api.dto.UserDto
import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile
import org.springframework.http.MediaType

@RestController
@RequestMapping("/api/v1/users")
class UserController(private val userService: UserService) {

    @PostMapping
    fun createUser(@RequestBody request: CreateUserRequest): ResponseEntity<ApiResponse<UserDto>> {
        return try {
            val user = userService.createUser(request)
            ResponseEntity.status(HttpStatus.CREATED).body(
                ApiResponse(success = true, message = "User created", data = user)
            )
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(
                 ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null)
            )
        }
    }

    @GetMapping("/{id}")
    fun getUser(@PathVariable id: Long): ResponseEntity<ApiResponse<UserDto>> {
        return try {
            val user = userService.getUserById(id)
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "User found", data = user)
            )
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @PutMapping("/{id}")
    fun updateUser(@PathVariable id: Long, @RequestBody request: UpdateUserRequest): ResponseEntity<ApiResponse<UserDto>> {
        return try {
            val user = userService.updateUser(id, request)
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "User updated", data = user)
            )
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @PutMapping("/{id}/password")
    fun changePassword(@PathVariable id: Long, @RequestBody request: ChangePasswordRequest): ResponseEntity<ApiResponse<Boolean>> {
        return try {
            val changed = userService.changePassword(id, request)
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "Password updated", data = changed)
            )
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().body(
                ApiResponse(success = false, message = (e.message ?: "Could not update password"), data = false)
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                ApiResponse(success = false, message = (e.message ?: "User not found"), data = false)
            )
        }
    }

    @PostMapping("/{id}/profile-photo", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun uploadProfilePhoto(@PathVariable id: Long, @RequestParam("file") file: MultipartFile): ResponseEntity<ApiResponse<UserDto>> {
        return try {
            val bytes = file.bytes
            val b64 = java.util.Base64.getEncoder().encodeToString(bytes)
            val user = userService.saveProfilePhoto(id, b64)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Profile photo uploaded", data = user))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null))
        }
    }

    @GetMapping("/{id}/weekly-report")
    fun getWeeklyReport(@PathVariable id: Long): ResponseEntity<ApiResponse<Boolean>> {
        return try {
            val enabled = userService.getWeeklyReport(id)
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "OK", data = enabled)
            )
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @PutMapping("/{id}/weekly-report")
    fun setWeeklyReport(
        @PathVariable id: Long,
        @RequestParam enabled: Boolean
    ): ResponseEntity<ApiResponse<Boolean>> {
        return try {
            val result = userService.setWeeklyReport(id, enabled)
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "Weekly report preference updated", data = result)
            )
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @DeleteMapping("/{id}")
    fun deleteUser(@PathVariable id: Long): ResponseEntity<ApiResponse<Boolean>> {
        return try {
            val deleted = userService.deleteUser(id)
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "User deleted", data = deleted)
            )
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping
    fun getAllUsers(): ResponseEntity<ApiResponse<List<UserDto>>> {
        val users = userService.getAllUsers()
        return ResponseEntity.ok().body(
            ApiResponse(success = true, message = "Users found", data = users)
        )
    }
}

