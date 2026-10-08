package hex.orders.infrastructure.inbound.http;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

// "Arrancado" según el contrato. No comprueba dependencias: eso sería readiness, y es un ejercicio.
@RestController
public class HealthController {

    @GetMapping("/health")
    Map<String, String> health() {
        return Map.of("status", "UP");
    }
}
