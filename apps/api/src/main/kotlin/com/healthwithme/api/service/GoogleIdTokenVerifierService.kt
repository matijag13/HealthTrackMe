package com.healthwithme.api.service

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport
import com.google.api.client.json.gson.GsonFactory
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service

@Service
class GoogleIdTokenVerifierService(
    @Value("\${google.oauth.allowed-client-ids:}")
    allowedClientIdsValue: String
) : GoogleTokenVerifier {
    private val logger = LoggerFactory.getLogger(GoogleIdTokenVerifierService::class.java)
    private val jsonFactory = GsonFactory.getDefaultInstance()

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
            jsonFactory
        )
            .setAudience(allowedClientIds)
            .build()
    }

    override fun verify(idToken: String): GoogleUserInfo {
        logger.info(
            "Google token verifier config: allowedClientIdsCount={} allowedClientIdsEmpty={}",
            allowedClientIds.size,
            allowedClientIds.isEmpty()
        )

        val trimmedToken = idToken.trim()
        val tokenAudiences = tokenAudiencesForDiagnostics(trimmedToken)
        val audienceMatched = tokenAudiences.any { allowedClientIds.contains(it) }
        logger.info(
            "Google token audience diagnostics: tokenAudienceCount={} audienceMatched={}",
            tokenAudiences.size,
            audienceMatched
        )

        val token = try {
            verifier.verify(trimmedToken)
        } catch (e: Exception) {
            logger.warn(
                "Google token verification failed with exception: reasonClass={} reasonMessage={}",
                e::class.java.simpleName,
                e.message
            )
            throw e
        }

        if (token == null) {
            logger.warn("Google token verification returned null")
            throw IllegalArgumentException("Invalid Google token")
        }

        val payload = token.payload
        val emailVerified = payload.emailVerified == true
        val missingEmail = payload.email.isNullOrBlank()
        val missingSub = payload.subject.isNullOrBlank()
        logger.info(
            "Google token payload diagnostics: emailVerified={} missingEmail={} missingSub={}",
            emailVerified,
            missingEmail,
            missingSub
        )

        val sub = payload.subject?.takeIf { it.isNotBlank() }
            ?: throw IllegalArgumentException("Invalid Google token")
        val email = payload.email?.takeIf { it.isNotBlank() }
            ?: throw IllegalArgumentException("Invalid Google token")

        return GoogleUserInfo(
            sub = sub,
            email = email,
            emailVerified = emailVerified,
            givenName = payload["given_name"] as? String,
            familyName = payload["family_name"] as? String,
            picture = payload["picture"] as? String
        )
    }

    private fun tokenAudiencesForDiagnostics(idToken: String): List<String> {
        return try {
            GoogleIdToken.parse(jsonFactory, idToken).payload.audienceAsList.orEmpty()
        } catch (e: Exception) {
            logger.warn(
                "Google token audience diagnostics unavailable: reasonClass={} reasonMessage={}",
                e::class.java.simpleName,
                e.message
            )
            emptyList()
        }
    }
}
