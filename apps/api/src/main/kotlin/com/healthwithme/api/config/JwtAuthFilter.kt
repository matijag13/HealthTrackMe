package com.healthwithme.api.config

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.healthwithme.api.service.JwtService
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.web.filter.OncePerRequestFilter

/**
 * Authenticates every `/api/v1` request (except `/auth/login` and `/auth/google`) with a
 * Bearer JWT, and enforces per-user ownership: when a request targets a specific user id (via a
 * `/users/{id}` path segment or a `userId` query param), that id must match the token's user.
 *
 * Registered via [FilterConfig] (not a @Component) so it stays out of @WebMvcTest slices.
 * Gated by `security.auth.enabled` so the test profile can disable it. Resource-id endpoints
 * (e.g. `/wearable-devices/{deviceId}`) are authentication-only — deeper ownership is future work.
 */
class JwtAuthFilter(
    private val jwtService: JwtService,
    private val authEnabled: Boolean
) : OncePerRequestFilter() {

    private val objectMapper = jacksonObjectMapper()

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        val path = request.requestURI

        if (!authEnabled || request.method == "OPTIONS" || !path.startsWith("/api/v1/") || isPublic(request)) {
            filterChain.doFilter(request, response)
            return
        }

        val header = request.getHeader("Authorization")
        val token = header?.takeIf { it.startsWith("Bearer ") }?.substring(7)
        val userId = token?.let { jwtService.validateAndGetUserId(it) }

        if (userId == null) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED, "Authentication required")
            return
        }

        val requestedUserId = extractRequestedUserId(request)
        if (requestedUserId != null && requestedUserId != userId) {
            writeError(response, HttpServletResponse.SC_FORBIDDEN, "You can only access your own data")
            return
        }

        request.setAttribute("authUserId", userId)
        filterChain.doFilter(request, response)
    }

    private fun isPublic(request: HttpServletRequest): Boolean {
        val path = request.requestURI
        if (path == "/api/v1/auth/login" || path == "/api/v1/auth/google") return true
        // Registration: creating a new account has no token yet.
        if (request.method == "POST" && path == "/api/v1/users") return true
        return false
    }

    /** A user id referenced by the request: `?userId=` query param, or the `/users/{id}` segment. */
    private fun extractRequestedUserId(request: HttpServletRequest): Long? {
        request.getParameter("userId")?.toLongOrNull()?.let { return it }
        val segments = request.requestURI.split("/").filter { it.isNotEmpty() }
        val idx = segments.indexOf("users")
        if (idx >= 0 && idx + 1 < segments.size) {
            return segments[idx + 1].toLongOrNull()
        }
        // /export/... endpoints carry the target userId as the final path segment.
        if (segments.contains("export")) {
            return segments.lastOrNull()?.toLongOrNull()
        }
        return null
    }

    private fun writeError(response: HttpServletResponse, status: Int, message: String) {
        response.status = status
        response.contentType = "application/json"
        response.writer.write(
            objectMapper.writeValueAsString(
                mapOf("success" to false, "message" to message, "data" to null)
            )
        )
    }
}
