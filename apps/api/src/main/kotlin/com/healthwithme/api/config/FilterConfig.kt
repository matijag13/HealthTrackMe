package com.healthwithme.api.config

import com.healthwithme.api.service.JwtService
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.web.servlet.FilterRegistrationBean
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

/**
 * Registers [JwtAuthFilter] for the API path. Kept in a dedicated @Configuration (registered via
 * FilterRegistrationBean rather than as a @Component) so @WebMvcTest slices don't pull the filter —
 * and its JwtService dependency — into unrelated controller tests.
 */
@Configuration
class FilterConfig {

    @Bean
    fun jwtAuthFilterRegistration(
        jwtService: JwtService,
        @Value("\${security.auth.enabled:true}") authEnabled: Boolean
    ): FilterRegistrationBean<JwtAuthFilter> {
        val registration = FilterRegistrationBean(JwtAuthFilter(jwtService, authEnabled))
        registration.addUrlPatterns("/api/v1/*")
        registration.order = 1
        return registration
    }
}
