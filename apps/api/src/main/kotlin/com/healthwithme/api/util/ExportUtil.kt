package com.healthwithme.api.util

import com.healthwithme.api.model.HealthEntry
import com.healthwithme.api.model.SportActivity
import java.io.StringWriter

object ExportUtil {

    fun exportHealthEntriesToCsv(entries: List<HealthEntry>): String {
        val writer = StringWriter()
        
        writer.append("Date,Symptoms,Mood,Energy Level,Sleep Hours,Sleep Quality,Stress Level,Notes\n")
        
        entries.forEach { entry ->
            writer.append("${entry.entryDate},")
            writer.append("\"${entry.symptoms.joinToString("; ")}\",")
            writer.append("${entry.mood ?: "N/A"},")
            writer.append("${entry.energyLevel ?: "N/A"},")
            writer.append("${entry.sleepHours ?: "N/A"},")
            writer.append("${entry.sleepQuality ?: "N/A"},")
            writer.append("${entry.stressLevel ?: "N/A"},")
            writer.append("\"${entry.notes ?: ""}\"\n")
        }
        
        return writer.toString()
    }

    fun exportSportActivitiesToCsv(activities: List<SportActivity>): String {
        val writer = StringWriter()
        
        writer.append("Date,Activity Type,Duration (min),Distance (km),Calories,Intensity,Avg Heart Rate,Notes\n")
        
        activities.forEach { activity ->
            writer.append("${activity.activityDate},")
            writer.append("${activity.activityType},")
            writer.append("${activity.duration ?: "N/A"},")
            writer.append("${activity.distance ?: "N/A"},")
            writer.append("${activity.caloriesBurned ?: "N/A"},")
            writer.append("${activity.intensity ?: "N/A"},")
            writer.append("${activity.averageHeartRate ?: "N/A"},")
            writer.append("\"${activity.notes ?: ""}\"\n")
        }
        
        return writer.toString()
    }

    fun generateHealthSummary(
        entries: List<HealthEntry>,
        activities: List<SportActivity>
    ): String {
        val builder = StringBuilder()
        
        builder.append("=== HEALTH TRACKING SUMMARY ===\n\n")
        
        // Health Entries Summary
        builder.append("HEALTH ENTRIES\n")
        builder.append("Total Entries: ${entries.size}\n")
        
        if (entries.isNotEmpty()) {
            val moods = entries.mapNotNull { it.mood }.groupingBy { it }.eachCount()
            builder.append("Mood Distribution: $moods\n")
            
            val avgEnergy = entries.mapNotNull { it.energyLevel }.average()
            builder.append("Average Energy Level: ${String.format("%.1f", avgEnergy)}/10\n")
            
            val avgSleep = entries.mapNotNull { it.sleepHours }.average()
            builder.append("Average Sleep: ${String.format("%.1f", avgSleep)} hours\n")
            
            val avgStress = entries.mapNotNull { it.stressLevel }.average()
            builder.append("Average Stress Level: ${String.format("%.1f", avgStress)}/10\n")
        }
        
        // Sport Activities Summary
        builder.append("\nSPORT ACTIVITIES\n")
        builder.append("Total Activities: ${activities.size}\n")
        
        if (activities.isNotEmpty()) {
            val totalDuration = activities.mapNotNull { it.duration }.sum()
            builder.append("Total Duration: $totalDuration minutes\n")
            
            val totalDistance = activities.mapNotNull { it.distance }.sum()
            builder.append("Total Distance: ${String.format("%.1f", totalDistance)} km\n")
            
            val totalCalories = activities.mapNotNull { it.caloriesBurned }.sum()
            builder.append("Total Calories Burned: $totalCalories\n")
        }
        
        return builder.toString()
    }
}

