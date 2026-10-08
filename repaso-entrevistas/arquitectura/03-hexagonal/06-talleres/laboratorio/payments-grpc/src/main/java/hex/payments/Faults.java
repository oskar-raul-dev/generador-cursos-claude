package hex.payments;

import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

// Fallos inyectables desde fuera (lab.py grpc fault ...): latencia fija o UNAVAILABLE en cada llamada.
// Es lo que permite provocar DEADLINE_EXCEEDED y UNAVAILABLE en el cliente sin tocar el servidor.
@Component
@RestController
public class Faults {

    public record Fault(String mode, long latencyMs) {
        static final Fault NONE = new Fault("none", 0);
    }

    private final AtomicReference<Fault> current = new AtomicReference<>(Fault.NONE);

    public Fault current() {
        return current.get();
    }

    @PostMapping("/faults")
    Fault set(@RequestBody Map<String, Object> body) {
        var fault = new Fault(String.valueOf(body.getOrDefault("mode", "none")),
            ((Number) body.getOrDefault("latencyMs", 0)).longValue());
        current.set(fault);
        return fault;
    }

    @GetMapping("/faults")
    Fault get() {
        return current.get();
    }
}
