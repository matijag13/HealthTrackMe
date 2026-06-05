package com.healthwithme.api.service

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class JwtServiceTest {

    private val service = JwtService("test-secret-value-for-unit-tests", 3600)

    @Test
    fun `issued token round-trips to the user id`() {
        val token = service.issueToken(42, "user@example.com")
        assertEquals(42L, service.validateAndGetUserId(token))
    }

    @Test
    fun `garbage token returns null`() {
        assertNull(service.validateAndGetUserId("not-a-jwt"))
    }

    @Test
    fun `token signed with a different secret is rejected`() {
        val other = JwtService("a-completely-different-secret", 3600)
        val token = other.issueToken(7, "x@example.com")
        assertNull(service.validateAndGetUserId(token))
    }
}
