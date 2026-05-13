package com.healthwithme.api.service

import com.healthwithme.api.model.HealthEntry
import com.healthwithme.api.model.AlertType
import com.healthwithme.api.model.AlertSeverity
import org.springframework.stereotype.Service

@Service
class HealthAnalysisService(
    private val alertService: HealthAlertService
) {

    fun analyzeHealthTrends(userId: Long, entries: List<HealthEntry>) {
        if (entries.isEmpty()) return
        
        // Analyze stress trends
        analyzeStressTrend(userId, entries)
        
        // Analyze sleep quality
        analyzeSleepQuality(userId, entries)
        
        // Analyze energy levels
        analyzeEnergyLevels(userId, entries)
        
        // Analyze symptom patterns
        analyzeSymptomPatterns(userId, entries)
    }

    private fun analyzeStressTrend(userId: Long, entries: List<HealthEntry>) {
        val recentEntries = entries.take(7)
        val stressLevels = recentEntries.mapNotNull { it.stressLevel }
        
        if (stressLevels.isEmpty()) return
        
        val avgStress = stressLevels.average()
        
        if (avgStress >= 8.0) {
            alertService.createAlert(
                userId,
                "High Stress Detected",
                "Your average stress level for the past week is ${String.format("%.1f", avgStress)}/10",
                AlertType.UNUSUAL_TREND.name,
                AlertSeverity.HIGH.name,
                "Consider relaxation techniques and consult a healthcare provider if it persists"
            )
        }
    }

    private fun analyzeSleepQuality(userId: Long, entries: List<HealthEntry>) {
        val recentEntries = entries.take(7)
        val sleepHours = recentEntries.mapNotNull { it.sleepHours }
        
        if (sleepHours.isEmpty()) return
        
        val avgSleep = sleepHours.average()
        
        when {
            avgSleep < 5.0 -> {
                alertService.createAlert(
                    userId,
                    "Low Sleep Hours",
                    "Your average sleep is ${String.format("%.1f", avgSleep)} hours per night. Recommended is 7-9 hours.",
                    AlertType.UNUSUAL_TREND.name,
                    AlertSeverity.MEDIUM.name,
                    "Improve sleep hygiene and maintain consistent sleep schedule"
                )
            }
            avgSleep > 10.0 -> {
                alertService.createAlert(
                    userId,
                    "Excessive Sleep",
                    "Your average sleep is ${String.format("%.1f", avgSleep)} hours per night.",
                    AlertType.UNUSUAL_TREND.name,
                    AlertSeverity.LOW.name,
                    "Monitor for signs of depression or sleep disorders"
                )
            }
        }
    }

    private fun analyzeEnergyLevels(userId: Long, entries: List<HealthEntry>) {
        val recentEntries = entries.take(7)
        val energyLevels = recentEntries.mapNotNull { it.energyLevel }
        
        if (energyLevels.isEmpty()) return
        
        val avgEnergy = energyLevels.average()
        
        if (avgEnergy < 4.0) {
            alertService.createAlert(
                userId,
                "Low Energy Levels",
                "Your energy level is consistently low (${String.format("%.1f", avgEnergy)}/10)",
                AlertType.UNUSUAL_TREND.name,
                AlertSeverity.MEDIUM.name,
                "Visit doctor if fatigue persists"
            )
        }
    }

    private fun analyzeSymptomPatterns(userId: Long, entries: List<HealthEntry>) {
        val allSymptoms = entries.flatMap { it.symptoms }
        
        if (allSymptoms.isEmpty()) return
        
        val symptomFrequency = allSymptoms.groupingBy { it }.eachCount()
        
        // Check for recurring symptoms
        symptomFrequency.forEach { (symptom, count) ->
            if (count >= 5) { // If symptom appears in 5+ entries
                alertService.createAlert(
                    userId,
                    "Recurring Symptom Detected",
                    "You have reported '$symptom' in $count recent entries.",
                    AlertType.UNUSUAL_TREND.name,
                    AlertSeverity.MEDIUM.name,
                    "VISIT_DOCTOR"
                )
            }
        }
    }

    fun generateHealthRecommendations(entries: List<HealthEntry>): List<String> {
        val recommendations = mutableListOf<String>()
        
        if (entries.isEmpty()) return recommendations
        
        val avgEnergy = entries.mapNotNull { it.energyLevel }.average()
        if (avgEnergy < 5.0) {
            recommendations.add("Try to increase physical activity to boost energy levels")
        }
        
        val avgStress = entries.mapNotNull { it.stressLevel }.average()
        if (avgStress > 7.0) {
            recommendations.add("Practice meditation or yoga to manage stress")
        }
        
        val avgSleep = entries.mapNotNull { it.sleepHours }.average()
        if (avgSleep < 7.0) {
            recommendations.add("Aim for 7-9 hours of sleep per night")
        }
        
        return recommendations
    }
}

