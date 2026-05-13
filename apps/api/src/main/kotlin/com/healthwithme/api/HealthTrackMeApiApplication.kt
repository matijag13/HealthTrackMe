package com.healthwithme.api

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class HealthTrackMeApiApplication

fun main(args: Array<String>) {
    runApplication<HealthTrackMeApiApplication>(*args)
}