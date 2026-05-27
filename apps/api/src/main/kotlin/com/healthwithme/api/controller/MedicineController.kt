package com.healthwithme.api.controller

import com.healthwithme.api.dto.CreateMedicineRequest
import com.healthwithme.api.dto.DoseRequest
import com.healthwithme.api.dto.AdherenceDailyPoint
import com.healthwithme.api.dto.AdherenceResponse
import com.healthwithme.api.dto.MedicineDto
import com.healthwithme.api.dto.UpdateMedicineRequest
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
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null))
        }
    }

    @PostMapping("/{id}/dose")
    fun logDose(@PathVariable id: Long, @RequestBody request: DoseRequest): ResponseEntity<ApiResponse<AdherenceResponse>> {
        return try {
            val date = java.time.LocalDate.parse(request.date)
            val time = java.time.LocalTime.parse(request.time)
            val result = medicineService.logDose(id, date, time, request.status)

            val dailyBreakdown = (result["dailyBreakdown"] as? List<Map<String, String>>)?.map {
                AdherenceDailyPoint(date = it["date"] ?: "", status = it["status"] ?: "SCHEDULED")
            } ?: emptyList()

            val response = AdherenceResponse(
                percentage = (result["percentage"] as? Double) ?: 0.0,
                takenCount = (result["takenCount"] as? Int) ?: 0,
                missedCount = (result["missedCount"] as? Int) ?: 0,
                dailyBreakdown = dailyBreakdown
            )

            ResponseEntity.ok().body(ApiResponse(success = true, message = "Dose logged", data = response))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null))
        }
    }

    @GetMapping("/{id}/adherence")
    fun getAdherence(@PathVariable id: Long, @RequestParam(required = false) days: Int?): ResponseEntity<ApiResponse<AdherenceResponse>> {
        return try {
            val result = medicineService.getAdherence(id, days)

            val daily = (result["dailyBreakdown"] as? List<Map<String, String>>)?.map {
                AdherenceDailyPoint(date = it["date"] ?: "", status = it["status"] ?: "SCHEDULED")
            } ?: emptyList()

            val response = AdherenceResponse(
                percentage = (result["percentage"] as? Double) ?: 0.0,
                takenCount = (result["takenCount"] as? Int) ?: 0,
                missedCount = (result["missedCount"] as? Int) ?: 0,
                dailyBreakdown = daily
            )

            ResponseEntity.ok().body(ApiResponse(success = true, message = "Adherence", data = response))
        } catch (e: Exception) {
            ResponseEntity.badRequest().body(ApiResponse(success = false, message = (e.message ?: "Bad request"), data = null))
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

    @PutMapping("/{id}")
    fun updateMedicine(@PathVariable id: Long, @RequestBody request: UpdateMedicineRequest): ResponseEntity<ApiResponse<MedicineDto>> {
        return try {
            val medicine = medicineService.updateMedicine(id, request)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Medicine updated", data = medicine))
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(404)
                .body(ApiResponse(success = false, message = e.message ?: "Medicine not found", data = null))
        } catch (e: Exception) {
            ResponseEntity.status(500)
                .body(ApiResponse(success = false, message = e.message ?: "Server error", data = null))
        }
    }

    @GetMapping("/users/{userId}")
    fun getUserMedicines(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<MedicineDto>>> {
        return try {
            val medicines = medicineService.getMedicinesByUser(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Medicines found", data = medicines))
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(404)
                .body(ApiResponse(success = false, message = e.message ?: "Not found", data = null))
        } catch (e: Exception) {
            ResponseEntity.status(500)
                .body(ApiResponse(success = false, message = e.message ?: "Server error", data = null))
        }
    }

    @GetMapping("/users/{userId}/active")
    fun getActiveMedicines(@PathVariable userId: Long): ResponseEntity<ApiResponse<List<MedicineDto>>> {
        return try {
            val medicines = medicineService.getActiveMedicinesByUser(userId)
            ResponseEntity.ok().body(ApiResponse(success = true, message = "Medicines found", data = medicines))
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(404)
                .body(ApiResponse(success = false, message = e.message ?: "Not found", data = null))
        } catch (e: Exception) {
            ResponseEntity.status(500)
                .body(ApiResponse(success = false, message = e.message ?: "Server error", data = null))
        }
    }

    @DeleteMapping("/{medicineId}")
    fun deleteMedicine(@PathVariable("medicineId") medicineId: Long): ResponseEntity<ApiResponse<Boolean>> {
        return try {
            val deleted = medicineService.deleteMedicine(medicineId)
            ResponseEntity.ok().body(
                ApiResponse(success = true, message = "Medicine deleted", data = deleted)
            )
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                ApiResponse(success = false, message = e.message ?: "Medicine not found", data = false)
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                ApiResponse(success = false, message = e.message ?: "Server error", data = false)
            )
        }
    }
}

