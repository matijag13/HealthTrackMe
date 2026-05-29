package com.healthwithme.api.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.healthwithme.api.dto.UserDto
import com.healthwithme.api.service.UserService
import org.junit.jupiter.api.Test
import org.mockito.Mockito.`when`
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.boot.test.mock.mockito.MockBean
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status

@WebMvcTest(AuthController::class)
class AuthControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @MockBean
    private lateinit var userService: UserService

    @Test
    fun `POST login returns user for valid credentials`() {
        `when`(userService.login("ana@example.com", "secret")).thenReturn(
            UserDto(
                id = 1,
                email = "ana@example.com",
                firstName = "Ana",
                lastName = "Novak",
                dateOfBirth = "1994-03-10",
                userType = "PATIENT",
                medicalConditions = null,
                allergies = null,
                height = null,
                weight = null,
                bloodType = null,
                emergencyContactName = null,
                emergencyContactPhone = null,
                chronicConditions = emptyList(),
                pastSurgeries = emptyList(),
                familyHistory = emptyList(),
                vaccinations = emptyList(),
                organDonor = null,
                doctorName = null,
                doctorClinic = null,
                doctorPhone = null,
                insuranceProvider = null,
                insurancePolicyNumber = null,
                profilePhotoBase64 = null,
                isActive = true
            )
        )

        mockMvc.perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(mapOf("email" to "ana@example.com", "password" to "secret")))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.id").value(1))
            .andExpect(jsonPath("$.data.email").value("ana@example.com"))
    }

    @Test
    fun `POST login returns unauthorized for invalid credentials`() {
        `when`(userService.login("ana@example.com", "wrong"))
            .thenThrow(IllegalArgumentException("Invalid email or password"))

        mockMvc.perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(mapOf("email" to "ana@example.com", "password" to "wrong")))
        )
            .andExpect(status().isUnauthorized)
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("Invalid email or password"))
    }
}
