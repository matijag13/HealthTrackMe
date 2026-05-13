package com.healthwithme.api.controller

import com.healthwithme.api.dto.CreateUserRequest
import com.healthwithme.api.dto.UpdateUserRequest
import com.healthwithme.api.dto.UserDto
import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

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

