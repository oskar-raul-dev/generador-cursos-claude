package hex.orders.infrastructure.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

// Configuración tipada y validada al arrancar: el resto del sistema recibe valores, no strings.
@ConfigurationProperties(prefix = "hex")
public record HexProperties(String catalog, Jwt jwt, Outbox outbox, Cors cors, Jms jms, Events events, Kafka kafka, Payment payment, Batch batch) {

    public record Jwt(String secret, long ttlSeconds) {
        public Jwt {
            if (secret == null || secret.getBytes().length < 32) {
                throw new IllegalArgumentException("hex.jwt.secret must be at least 32 bytes for HS256");
            }
            if (ttlSeconds <= 0) {
                throw new IllegalArgumentException("hex.jwt.ttl-seconds must be positive");
            }
        }
    }

    public record Outbox(long pollMs) {}

    public record Cors(String allowedOrigin) {}

    // taller 08: colas de entrada y de respuesta, consumidores por instancia
    public record Jms(String inbound, String reply, int concurrency) {}

    // taller 09: por dónde sale la outbox, y el tópico
    public record Events(String transport) {
        public Events {
            if (!"table".equals(transport) && !"kafka".equals(transport)) {
                throw new IllegalArgumentException("hex.events.transport must be table or kafka, was: " + transport);
            }
        }
    }

    public record Kafka(String topic, int partitions, boolean keyed, String chaos) {}

    // taller 11: el lote
    public record Batch(int chunkSize, int skipLimit, String chaos, String outDir) {}

    // taller 10: qué proveedor de pagos y con qué plazo
    public record Payment(String provider, long deadlineMs) {
        public Payment {
            if (!"deterministic".equals(provider) && !"grpc".equals(provider)) {
                throw new IllegalArgumentException("hex.payment.provider must be deterministic or grpc, was: " + provider);
            }
        }
    }

    public HexProperties {
        if (!"postgres".equals(catalog) && !"mongo".equals(catalog)) {
            throw new IllegalArgumentException("hex.catalog must be postgres or mongo, was: " + catalog);
        }
    }
}
