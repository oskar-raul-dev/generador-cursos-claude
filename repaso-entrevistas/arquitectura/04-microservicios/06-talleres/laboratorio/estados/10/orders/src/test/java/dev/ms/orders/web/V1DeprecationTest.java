package dev.ms.orders.web;

import dev.ms.orders.config.OrdersProperties;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

// Prueba unitaria (taller 10): el formato exacto de dos normas, sin levantar Spring.
class V1DeprecationTest {

    private final V1Deprecation filter = new V1Deprecation(new OrdersProperties(null, null, null, null, null,
        new OrdersProperties.V1(Instant.parse("2026-09-29T00:00:00Z"), Instant.parse("2027-03-31T00:00:00Z"))));

    @Test
    void v1OrdersAnnounceTheirRetirement() throws Exception {
        var res = new MockHttpServletResponse();
        filter.doFilter(new MockHttpServletRequest("POST", "/api/v1/orders"), res, new MockFilterChain());
        assertThat(res.getHeader("Deprecation")).isEqualTo("@1790640000");                 // RFC 9745
        assertThat(res.getHeader("Sunset")).isEqualTo("Wed, 31 Mar 2027 00:00:00 GMT");     // RFC 8594
        assertThat(res.getHeader("Link")).contains("rel=\"successor-version\"");
    }

    @Test
    void whatHasNoSuccessorIsNotDeprecated() throws Exception {
        var res = new MockHttpServletResponse();
        filter.doFilter(new MockHttpServletRequest("GET", "/api/v1/notifications"), res, new MockFilterChain());
        assertThat(res.getHeader("Deprecation")).isNull();
    }
}
