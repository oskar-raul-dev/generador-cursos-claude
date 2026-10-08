package co.coodrosan.lab.inventory;

import java.sql.Connection;
import java.util.Map;
import javax.sql.DataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.availability.ApplicationAvailability;
import org.springframework.boot.availability.ReadinessState;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// La salud de inventory: un controlador propio, sin Actuator (G4 lo decidió así: el contrato pide
// {"status":"ready"} y Actuator responde {"status":"UP"}). En G6 entra Actuator, pero solo para /metrics:
// la salud sigue siendo esta.
@RestController
public class HealthController {

    private static final Logger log = LoggerFactory.getLogger(HealthController.class);

    private final ApplicationAvailability availability;
    private final DataSource dataSource;

    HealthController(ApplicationAvailability availability, DataSource dataSource) {
        this.availability = availability;
        this.dataSource = dataSource;
    }

    // La liveness nunca consulta dependencias: si el proceso contesta, está vivo.
    @GetMapping("/health/live")
    public Map<String, String> live() {
        return Map.of("status", "live");
    }

    // La readiness (G4): lista cuando Spring terminó de arrancar (ACCEPTING_TRAFFIC, que llega después
    // de que el servidor abrió el puerto) y la base contesta en un segundo. Ningún vecino: eso sería una cascada.
    @GetMapping("/health/ready")
    public ResponseEntity<Map<String, String>> ready() {
        if (availability.getReadinessState() != ReadinessState.ACCEPTING_TRAFFIC) {
            return notReady("la aplicación todavía no acepta tráfico");
        }
        try (Connection connection = dataSource.getConnection()) {
            if (!connection.isValid(1)) {
                return notReady("la base no contesta en un segundo");
            }
        } catch (Exception e) {
            return notReady("la base no contesta: " + e.getMessage());
        }
        return ResponseEntity.ok(Map.of("status", "ready"));
    }

    private ResponseEntity<Map<String, String>> notReady(String why) {
        log.warn("no listo: {}", why);
        return ResponseEntity.status(503).body(Map.of("status", "not_ready"));
    }
}
