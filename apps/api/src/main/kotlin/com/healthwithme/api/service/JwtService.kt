package com.healthwithme.api.service

import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.security.MessageDigest
import java.time.Instant
import java.util.Date

/**
 * Issues and validates HS256 JWTs for API authentication. The signing key is derived
 * from the configured secret via SHA-256 so any secret length yields a valid 256-bit key.
 */
@Service
class JwtService(
    @Value("\${security.jwt.secret:change-me-local-secret}") secret: String,
    @Value("\${security.jwt.expiration-seconds:2592000}") private val expirationSeconds: Long
) {
    private val key = Keys.hmacShaKeyFor(
        MessageDigest.getInstance("SHA-256").digest(secret.toByteArray(Charsets.UTF_8))
    )

    fun issueToken(userId: Long, email: String): String {
        val now = Instant.now()
        return Jwts.builder()
            .subject(userId.toString())
            .claim("email", email)
            .issuedAt(Date.from(now))
            .expiration(Date.from(now.plusSeconds(expirationSeconds)))
            .signWith(key)
            .compact()
    }

    /** Returns the authenticated user id, or null if the token is missing/invalid/expired. */
    fun validateAndGetUserId(token: String): Long? {
        return try {
            Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .payload
                .subject
                ?.toLongOrNull()
        } catch (e: Exception) {
            null
        }
    }
}
