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
        val avgWellbeing = entries.map { it.wellbeingScore }.average().takeIf { !it.isNaN() } ?: 0.0
        val avgEnergy = entries.mapNotNull { it.energyLevel }.average().takeIf { !it.isNaN() } ?: 0.0
        val avgStress = entries.mapNotNull { it.stressLevel }.average().takeIf { !it.isNaN() } ?: 0.0
        val totalActivities = activities.size
        val totalDuration = activities.mapNotNull { it.duration }.sum()

        return buildString {
            appendLine("Health Summary")
            appendLine("Entries: ${entries.size}")
            appendLine("Average wellbeing score: ${"%.2f".format(avgWellbeing)}")
            appendLine("Average energy level: ${"%.2f".format(avgEnergy)}")
            appendLine("Average stress level: ${"%.2f".format(avgStress)}")
            appendLine("Activities: $totalActivities")
            appendLine("Total activity duration (minutes): $totalDuration")
        }
    }
}