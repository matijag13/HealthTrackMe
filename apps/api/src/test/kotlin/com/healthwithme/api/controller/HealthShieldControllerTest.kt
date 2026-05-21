package com.healthwithme.api.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.healthwithme.api.dto.HealthShieldDailyBreakdownDto
import com.healthwithme.api.dto.HealthShieldResponseDto
import com.healthwithme.api.service.HealthShieldService
import org.junit.jupiter.api.Test
import org.mockito.Mockito.`when`
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.boot.test.mock.mockito.MockBean
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*

@WebMvcTest(HealthShieldController::class)
class HealthShieldControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockBean
    private lateinit var healthShieldService: HealthShieldService

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Test
    fun `GET health-shield returns 200 and correct properties`() {
        val breakdown = HealthShieldDailyBreakdownDto(
            supplementsPoints = 15,
            sleepPoints = 20,
            activityPoints = 20,
            wellbeingPoints = 15,
            symptomsPoints = 15,
            routineStabilityPoints = 10,
            penaltyPoints = 0,
            totalDailyPoints = 95
        )
        val responseDto = HealthShieldResponseDto(
            level = 2,
            levelName = "Osnovni ščit",
            totalConsistencyPoints = 150,
            currentLevelStartPoints = 100,
            nextLevelPoints = 300,
            pointsToNextLevel = 150,
            progressPercent = 25,
            todayPoints = 95,
            penaltyPoints = 0,
            completedHabitsCount = 5,
            consecutiveFailedDays = 0,
            dailyBreakdown = breakdown
        )

        `when`(healthShieldService.getHealthShieldForUser(1L)).thenReturn(responseDto)

        mockMvc.perform(get("/api/health-shield/{userId}", 1L)
            .accept(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk)
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.level").value(2))
            .andExpect(jsonPath("$.levelName").value("Osnovni ščit"))
            .andExpect(jsonPath("$.totalConsistencyPoints").value(150))
            .andExpect(jsonPath("$.todayPoints").value(95))
            .andExpect(jsonPath("$.penaltyPoints").value(0))
            .andExpect(jsonPath("$.completedHabitsCount").value(5))
            .andExpect(jsonPath("$.dailyBreakdown.supplementsPoints").value(15))
    }
}
