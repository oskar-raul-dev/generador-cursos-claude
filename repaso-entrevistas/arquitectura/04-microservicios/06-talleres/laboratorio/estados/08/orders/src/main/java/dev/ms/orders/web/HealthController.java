package dev.ms.orders.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {
    // Vida del proceso, sin mirar dependencias: responde aunque la base o el proveedor estén caídos.
    @GetMapping("/health")
    Map<String, String> health() { return Map.of("status", "UP"); }
}
