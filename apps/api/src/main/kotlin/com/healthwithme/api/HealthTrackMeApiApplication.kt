package com.healthwithme.api

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.scheduling.annotation.EnableScheduling

@SpringBootApplication
@EnableScheduling
class HealthTrackMeApiApplication

fun main(args: Array<String>) {
    runApplication<HealthTrackMeApiApplication>(*args)
}