package com.healthwithme.api.controller

import com.healthwithme.api.dto.CreateMedicineRequest
import com.healthwithme.api.dto.MedicineDto
import com.healthwithme.api.dto.ApiResponse
import com.healthwithme.api.service.MedicineService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/medicines")
class MedicineController(private val medicineService: MedicineService) {

    @PostMapping("/users/{userId}")
    fun createMedicine(@PathVariable userId: Long, @RequestBody request: CreateMedicineRequest): ResponseEntity<ApiResponse<MedicineDto>> {
        return try {
            val medicine = medicineService.createMedicine(userId, request)
            ResponseEntity.status(HttpStatus.CREATED).body(
                ApiResponse(success = true, message = "Medicine added", data = medicine)
            )
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = e.message, data = null))
        }
    }

    @GetMapping("/{id}")
    fun getMedicine(@PathVariable id: Long): ResponseEntity<ApiResponse<MedicineDto>> {
        return try {
            val medicine = medicineService.getMedicineById(id)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Medicine found", data = medicine))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping("/users/{userId}")
    fun getUserMedicines(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<MedicineDto>>> {
        return try {
            val medicines = medicineService.getMedicinesByUser(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Medicines found", data = medicines))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }

    @GetMapping("/users/{userId}/active")
    fun getActiveMedicines(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<MedicineDto>>> {
        return try {
            val medicines = medicineService.getActiveMedicinesByUser(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Medicines found", data = medicines))
        } catch (e: Exception) {
            ResponseEntity.notFound().build()
        }
    }
}

