package com.healthwithme.api.util

import com.healthwithme.api.model.HealthEntry
import com.healthwithme.api.model.SportActivity

object ExportUtil {

    fun exportHealthEntriesToCsv(entries: List<HealthEntry>): String {
        val header = "id,entryDate,wellbeingScore,mood,energyLevel,stressLevel,symptoms,doctorNotes"
        val rows = entries.joinToString("\n") { entry ->
            listOf(
                entry.id,
                entry.entryDate,
                entry.wellbeingScore,
                entry.mood ?: "",
                entry.energyLevel ?: "",
                entry.stressLevel ?: "",
                (entry.symptoms ?: "").replace(",", "|"),
                (entry.doctorNotes ?: "").replace(",", "|")
            ).joinToString(",")
        }
        return "$header\n$rows"
    }

    fun exportSportActivitiesToCsv(activities: List<SportActivity>): String {
        val header = "id,activityType,activityDate,duration,distance,caloriesBurned,intensity,averageHeartRate,notes"
        val rows = activities.joinToString("\n") { activity ->
            listOf(
                activity.id,
                activity.activityType,
                activity.activityDate,
                activity.duration ?: "",
                activity.distance ?: "",
                activity.caloriesBurned ?: "",
                activity.intensity ?: "",
                activity.averageHeartRate ?: "",
                (activity.notes ?: "").replace(",", "|")
            ).joinToString(",")
        }
        return "$header\n$rows"
    }

    fun generateHealthSummary(entries: List<HealthEntry>, activities: List<SportActivity>): String {
        val sortedEntries = entries.sortedBy { it.entryDate }

        val avgWellbeing = entries.map { it.wellbeingScore }.average().takeIf { !it.isNaN() } ?: 0.0
        val avgEnergy = entries.mapNotNull { it.energyLevel }.average().takeIf { !it.isNaN() } ?: 0.0
        val avgStress = entries.mapNotNull { it.stressLevel }.average().takeIf { !it.isNaN() } ?: 0.0
        val sleepValues = entries.mapNotNull { it.sleepHours }.filter { it > 0 }
        val avgSleep = sleepValues.average().takeIf { !it.isNaN() } ?: 0.0

        val latest = sortedEntries.lastOrNull()

        val totalActivities = activities.size
        val totalDuration = activities.mapNotNull { it.duration }.sum()
        val totalDistance = activities.mapNotNull { it.distance }.sum()
        val totalCalories = activities.mapNotNull { it.caloriesBurned }.sum()
        val totalSteps = activities.mapNotNull { it.steps }.sum()
        val mostCommonType = activities.groupingBy { it.activityType }.eachCount()
            .maxByOrNull { it.value }?.key

        val dateRange = if (sortedEntries.isNotEmpty()) {
            "${sortedEntries.first().entryDate} to ${sortedEntries.last().entryDate}"
        } else {
            "no entries yet"
        }

        return buildString {
            appendLine("HealthTrackMe — Health Summary")
            appendLine("Period: $dateRange")
            appendLine()
            appendLine("WELLBEING")
            appendLine("  Logged days: ${entries.size}")
            appendLine("  Avg wellbeing: ${"%.1f".format(avgWellbeing)} / 10")
            appendLine("  Avg energy: ${"%.1f".format(avgEnergy)} / 10")
            appendLine("  Avg stress: ${"%.1f".format(avgStress)} / 10")
            if (avgSleep > 0) appendLine("  Avg sleep: ${"%.1f".format(avgSleep)} h")
            appendLine()
            if (latest != null) {
                appendLine("LATEST VITALS (${latest.entryDate})")
                latest.heartRate?.let { appendLine("  Heart rate: $it bpm") }
                if (latest.systolicBp != null && latest.diastolicBp != null) {
                    appendLine("  Blood pressure: ${latest.systolicBp}/${latest.diastolicBp} mmHg")
                }
                latest.spO2?.let { appendLine("  SpO2: $it%") }
                latest.weight?.let { appendLine("  Weight: ${"%.1f".format(it)} kg") }
                appendLine()
            }
            appendLine("ACTIVITY")
            appendLine("  Sessions: $totalActivities")
            appendLine("  Total duration: $totalDuration min")
            if (totalDistance > 0) appendLine("  Total distance: ${"%.1f".format(totalDistance)} km")
            if (totalCalories > 0) appendLine("  Calories burned: $totalCalories kcal")
            if (totalSteps > 0) appendLine("  Steps: $totalSteps")
            if (mostCommonType != null) appendLine("  Most common: $mostCommonType")
        }
    }
}