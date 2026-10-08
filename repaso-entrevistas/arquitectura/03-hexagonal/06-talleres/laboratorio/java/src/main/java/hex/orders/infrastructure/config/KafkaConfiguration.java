package hex.orders.infrastructure.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

// Taller 09. El tópico se declara aquí, con sus particiones, y KafkaAdmin lo crea al arrancar si no
// existe. Tres particiones para que el reparto por clave sea visible; un solo broker, réplica 1.
// El número de particiones es una decisión de contrato: fija el paralelismo máximo y no se cambia
// sin reubicar claves.
@Configuration
@ConditionalOnProperty(name = "hex.events.transport", havingValue = "kafka")
public class KafkaConfiguration {

    @Bean
    NewTopic ordersEvents(HexProperties properties) {
        return TopicBuilder.name(properties.kafka().topic())
            .partitions(properties.kafka().partitions())
            .replicas(1)
            .build();
    }
}
