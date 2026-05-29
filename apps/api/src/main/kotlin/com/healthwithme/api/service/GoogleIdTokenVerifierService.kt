package com.healthwithme.api.service

import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport
import com.google.api.client.json.gson.GsonFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service

@Service
class GoogleIdTokenVerifierService(
    @Value("\${google.oauth.allowed-client-ids:}")
    allowedClientIdsValue: String
) : GoogleTokenVerifier {
    private val allowedClientIds = allowedClientIdsValue
        .split(",")
        .map { it.trim() }
        .filter { it.isNotEmpty() }

    private val verifier: GoogleIdTokenVerifier by lazy {
        if (allowedClientIds.isEmpty()) {
            throw IllegalStateException("Google OAuth client IDs are not configured")
        }

        GoogleIdTokenVerifier.Builder(
            GoogleNetHttpTransport.newTrustedTransport(),
            GsonFactory.getDefaultInstance()
        )
            .setAudience(allowedClientIds)
            .build()
    }

    override fun verify(idToken: String): GoogleUserInfo {
        val token = verifier.verify(idToken.trim())
            ?: throw IllegalArgumentException("Invalid Google token")
        val payload = token.payload
        val sub = payload.subject?.takeIf { it.isNotBlank() }
            ?: throw IllegalArgumentException("Invalid Google token")
        val email = payload.email?.takeIf { it.isNotBlank() }
            ?: throw IllegalArgumentException("Invalid Google token")
        val emailVerified = payload.emailVerified == true

        return GoogleUserInfo(
            sub = sub,
            email = email,
            emailVerified = emailVerified,
            givenName = payload["given_name"] as? String,
            familyName = payload["family_name"] as? String,
            picture = payload["picture"] as? String
        )
    }
}
