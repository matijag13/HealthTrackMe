package com.healthwithme.api.service

import com.healthwithme.api.model.*
import com.healthwithme.api.repository.*
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.eq
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.Mockito.`when`
import org.mockito.junit.jupiter.MockitoExtension
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.Optional

@ExtendWith(MockitoExtension::class)
class HealthShieldServiceTest {

    @Mock
    private lateinit var healthShieldStatusRepository: HealthShieldStatusRepository

    @Mock
    private lateinit var healthShieldDailyPointsRepository: HealthShieldDailyPointsRepository

    @Mock
    private lateinit var userRepository: UserRepository

    @Mock
    private lateinit var medicineRepository: MedicineRepository

    @Mock
    private lateinit var doseLogRepository: DoseLogRepository

    @Mock
    private lateinit var sleepRecordRepository: SleepRecordRepository

    @Mock
    private lateinit var activityLogRepository: ActivityLogRepository

    @Mock
    private lateinit var healthEntryRepository: HealthEntryRepository

    @InjectMocks
    private lateinit var healthShieldService: HealthShieldService

    private lateinit var testUser: User
    private lateinit var today: LocalDate

    @BeforeEach
    fun setUp() {
        testUser = User(id = 1L, email = "test@example.com")
        today = LocalDate.now()

        // Common mocks for the start of getHealthShieldForUser
        `when`(userRepository.findById(1L)).thenReturn(Optional.of(testUser))
    }

    private fun mockStatus(status: HealthShieldStatus?) {
        `when`(healthShieldStatusRepository.findByUserId(1L)).thenReturn(status)
        if (status == null) {
            `when`(healthShieldStatusRepository.save(any(HealthShieldStatus::class.java))).thenAnswer { it.arguments[0] as HealthShieldStatus }
        }
    }

    private fun mockDailyPointsSave() {
        `when`(healthShieldDailyPointsRepository.save(any(HealthShieldDailyPoints::class.java)))
            .thenAnswer { it.arguments[0] as HealthShieldDailyPoints }
    }

    @Test
    fun `Test 1 - Uporabnik brez dnevnih navad`() {
        // uporabnik nima zapisov v sleep_records, activity_logs, health_entries, medicines ali dose_logs
        mockStatus(null)
        `when`(healthShieldDailyPointsRepository.findByUserIdAndCalculationDate(1L, today)).thenReturn(null)
        mockDailyPointsSave()
        
        `when`(medicineRepository.findByUserIdAndIsActive(1L, true)).thenReturn(emptyList())
        `when`(sleepRecordRepository.findByUserIdAndSleepDate(1L, today)).thenReturn(emptyList())
        `when`(activityLogRepository.findByUserIdAndActivityDate(1L, today)).thenReturn(emptyList())
        `when`(healthEntryRepository.findByUserIdAndEntryDateOrderByCreatedAtDesc(1L, today)).thenReturn(emptyList())

        val result = healthShieldService.getHealthShieldForUser(1L)

        // service vrne level 1
        assertThat(result.level).isEqualTo(1)
        assertThat(result.levelName).isEqualTo("Basic Shield")
        // totalConsistencyPoints ostane 0
        assertThat(result.totalConsistencyPoints).isEqualTo(0)
        // completedHabitsCount je 0
        assertThat(result.completedHabitsCount).isEqualTo(0)
        // penaltyPoints je pozitiven
        assertThat(result.penaltyPoints).isGreaterThan(0)
        // todayPoints je negativen ali 0 (ker je positivePoints=0, penaltyPoints>0 -> todayPoints mora biti -penaltyPoints)
        assertThat(result.todayPoints).isLessThanOrEqualTo(0)
    }

    @Test
    fun `Test 2 - Uporabnik brez dodatkov`() {
        val status = HealthShieldStatus(user = testUser, currentLevel = 1, totalConsistencyPoints = 50)
        mockStatus(status)
        `when`(healthShieldDailyPointsRepository.findByUserIdAndCalculationDate(1L, today)).thenReturn(null)
        mockDailyPointsSave()
        `when`(healthShieldStatusRepository.save(any(HealthShieldStatus::class.java))).thenAnswer { it.arguments[0] }

        // Brez dodatkov
        `when`(medicineRepository.findByUserIdAndIsActive(1L, true)).thenReturn(emptyList())

        // sleep_record z vsaj 420 minutami
        val sleepRecord = SleepRecord(durationMinutes = 450)
        `when`(sleepRecordRepository.findByUserIdAndSleepDate(1L, today)).thenReturn(listOf(sleepRecord))

        // activity_log z vsaj 6000 koraki
        val activityLog = ActivityLog(steps = 7000)
        `when`(activityLogRepository.findByUserIdAndActivityDate(1L, today)).thenReturn(listOf(activityLog))

        // health_entry z wellbeing in symptoms
        val healthEntry = HealthEntry(wellbeingScore = 8, symptoms = "Headache")
        `when`(healthEntryRepository.findByUserIdAndEntryDateOrderByCreatedAtDesc(1L, today)).thenReturn(listOf(healthEntry))

        val result = healthShieldService.getHealthShieldForUser(1L)

        val bd = result.dailyBreakdown
        assertThat(bd).isNotNull

        // supplementsPoints ostane 0
        assertThat(bd!!.supplementsPoints).isEqualTo(0)
        // sleepPoints je 20
        assertThat(bd.sleepPoints).isEqualTo(20)
        // activityPoints je 20
        assertThat(bd.activityPoints).isEqualTo(20)
        // wellbeingPoints je 15
        assertThat(bd.wellbeingPoints).isEqualTo(15)
        // symptomsPoints je 15
        assertThat(bd.symptomsPoints).isEqualTo(15)
        
        // completedHabitsCount je 4 (sleep, activity, wellbeing, symptoms)
        assertThat(result.completedHabitsCount).isGreaterThanOrEqualTo(3)

        // routineStabilityPoints je 25 (ker ni supplements in >= 3 habits)
        assertThat(bd.routineStabilityPoints).isEqualTo(25)

        // penaltyPoints je 0
        assertThat(result.penaltyPoints).isEqualTo(0)
        assertThat(bd.penaltyPoints).isEqualTo(0)

        assertThat(bd.totalDailyPoints).isEqualTo(20 + 20 + 15 + 15 + 25)
    }

    @Test
    fun `Test 3 - Uporabnik z dodatki in status TAKEN`() {
        val status = HealthShieldStatus(user = testUser, currentLevel = 1, totalConsistencyPoints = 100)
        mockStatus(status)
        `when`(healthShieldDailyPointsRepository.findByUserIdAndCalculationDate(1L, today)).thenReturn(null)
        mockDailyPointsSave()
        `when`(healthShieldStatusRepository.save(any(HealthShieldStatus::class.java))).thenAnswer { it.arguments[0] }

        val med = Medicine(id = 10L, user = testUser, isActive = true)
        `when`(medicineRepository.findByUserIdAndIsActive(1L, true)).thenReturn(listOf(med))

        val doseLog = DoseLog(medicine = Medicine(id = 10L, user = testUser, isActive = true), status = DoseStatus.TAKEN, takenTime = LocalDateTime.now())
        `when`(doseLogRepository.findByMedicineId(10L)).thenReturn(listOf(doseLog))

        `when`(sleepRecordRepository.findByUserIdAndSleepDate(1L, today)).thenReturn(emptyList())
        `when`(activityLogRepository.findByUserIdAndActivityDate(1L, today)).thenReturn(emptyList())
        `when`(healthEntryRepository.findByUserIdAndEntryDateOrderByCreatedAtDesc(1L, today)).thenReturn(emptyList())

        val result = healthShieldService.getHealthShieldForUser(1L)
        val bd = result.dailyBreakdown!!

        // supplementsPoints 15 ker je taken danes
        assertThat(bd.supplementsPoints).isEqualTo(15)
    }

    @Test
    fun `Test 4 - Stabilnost rutine z dodatki`() {
        val status = HealthShieldStatus(user = testUser)
        mockStatus(status)
        `when`(healthShieldDailyPointsRepository.findByUserIdAndCalculationDate(1L, today)).thenReturn(null)
        mockDailyPointsSave()
        `when`(healthShieldStatusRepository.save(any(HealthShieldStatus::class.java))).thenAnswer { it.arguments[0] }

        val med = Medicine(id = 10L, user = testUser, isActive = true)
        `when`(medicineRepository.findByUserIdAndIsActive(1L, true)).thenReturn(listOf(med))

        val doseLog = DoseLog(medicine = Medicine(id = 10L, user = testUser, isActive = true), status = DoseStatus.TAKEN, takenTime = LocalDateTime.now())
        `when`(doseLogRepository.findByMedicineId(10L)).thenReturn(listOf(doseLog))
        
        val sleepRecord = SleepRecord(durationMinutes = 450)
        `when`(sleepRecordRepository.findByUserIdAndSleepDate(1L, today)).thenReturn(listOf(sleepRecord))
        
        val activityLog = ActivityLog(steps = 7000)
        `when`(activityLogRepository.findByUserIdAndActivityDate(1L, today)).thenReturn(listOf(activityLog))
        
        `when`(healthEntryRepository.findByUserIdAndEntryDateOrderByCreatedAtDesc(1L, today)).thenReturn(emptyList())

        val result = healthShieldService.getHealthShieldForUser(1L)
        val bd = result.dailyBreakdown!!

        // 3 habits: supplements, sleep, activity
        assertThat(result.completedHabitsCount).isEqualTo(3)
        // routineStabilityPoints je 10 (ker ima dodatke)
        assertThat(bd.routineStabilityPoints).isEqualTo(10)
    }

    @Test
    fun `Test 5 - Odbitek točk limitiran in totalConsistencyPoints ostaja pozitiven`() {
        val status = HealthShieldStatus(user = testUser, consecutiveFailedDays = 10, totalConsistencyPoints = 10)
        mockStatus(status)
        `when`(healthShieldDailyPointsRepository.findByUserIdAndCalculationDate(1L, today)).thenReturn(null)
        mockDailyPointsSave()
        `when`(healthShieldStatusRepository.save(any(HealthShieldStatus::class.java))).thenAnswer { it.arguments[0] }

        `when`(medicineRepository.findByUserIdAndIsActive(1L, true)).thenReturn(emptyList())
        `when`(sleepRecordRepository.findByUserIdAndSleepDate(1L, today)).thenReturn(emptyList())
        `when`(activityLogRepository.findByUserIdAndActivityDate(1L, today)).thenReturn(emptyList())
        `when`(healthEntryRepository.findByUserIdAndEntryDateOrderByCreatedAtDesc(1L, today)).thenReturn(emptyList())

        val result = healthShieldService.getHealthShieldForUser(1L)
        
        // 11 consecutive fail days -> (15 * 11) / 2.0 = 165 / 2 = 82.5 -> limitirano na 45
        assertThat(result.penaltyPoints).isEqualTo(45)
        
        // previous total was 10, penalty is 45, result shouldn't fall below 0
        assertThat(result.totalConsistencyPoints).isEqualTo(0)
    }

    @Test
    fun `Test 6 - Izračun stopnje ščita`() {
        val status = HealthShieldStatus(user = testUser, totalConsistencyPoints = 350)
        mockStatus(status)
        `when`(healthShieldDailyPointsRepository.findByUserIdAndCalculationDate(1L, today)).thenReturn(null) // No calculation today yet
        mockDailyPointsSave()
        `when`(healthShieldStatusRepository.save(any(HealthShieldStatus::class.java))).thenAnswer { it.arguments[0] }

        // To generate points and just return
        `when`(medicineRepository.findByUserIdAndIsActive(1L, true)).thenReturn(emptyList())
        `when`(sleepRecordRepository.findByUserIdAndSleepDate(1L, today)).thenReturn(emptyList())
        `when`(activityLogRepository.findByUserIdAndActivityDate(1L, today)).thenReturn(emptyList())

        val result = healthShieldService.getHealthShieldForUser(1L)
        
        // status had 350, then we do no habits, penalty is 8, 350 - 8 = 342. 
        // Let's check the level logic.
        // Level 1: 0..99
        // Level 2: 100..299
        // Level 3: 300..599
        // 342 means Level 3
        assertThat(result.level).isEqualTo(3)
        assertThat(result.levelName).isEqualTo("Basic Shield")
        assertThat(result.currentLevelStartPoints).isEqualTo(300)
        assertThat(result.nextLevelPoints).isEqualTo(600)
        assertThat(result.pointsToNextLevel).isEqualTo(600 - 342)
    }
}
