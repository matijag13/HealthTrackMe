package com.healthwithme.api.service

data class GoogleUserInfo(
    val sub: String,
    val email: String,
    val emailVerified: Boolean,
    val givenName: String?,
    val familyName: String?,
    val picture: String?
)

interface GoogleTokenVerifier {
    fun verify(idToken: String): GoogleUserInfo
}
