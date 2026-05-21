package com.healthwithme.api.controller

import com.healthwithme.api.dto.HealthShieldResponseDto
import com.healthwithme.api.service.HealthShieldService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/health-shield")
@CrossOrigin(origins = ["*"])
class HealthShieldController(
    private val healthShieldService: HealthShieldService
) {

    @GetMapping("/{userId}")
    fun getHealthShieldStatus(@PathVariable userId: Long): ResponseEntity<HealthShieldResponseDto> {
        return try {
            val response = healthShieldService.getHealthShieldForUser(userId)
            ResponseEntity.ok(response)
        } catch (e: Exception) {
            ResponseEntity.badRequest().build()
        }
    }
}
