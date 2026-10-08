package dev.ms.orders.saga;

import org.apache.kafka.common.TopicPartition;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.FixedBackOff;
import tools.jackson.core.JacksonException;

// Lo que en Go y en Python se escribió a mano (06/06), en Spring es configuración: tres intentos con
// 200 ms entre ellos y, después, el mensaje a <topic>.dlq con encabezados del error. Lo que no se puede
// leer no se reintenta. Boot conecta este bean al contenedor de @KafkaListener.
@Configuration
public class KafkaErrorConfig {

    @Bean
    DefaultErrorHandler kafkaErrorHandler(KafkaTemplate<String, String> template) {
        var recoverer = new DeadLetterPublishingRecoverer(template, (rec, ex) -> new TopicPartition(rec.topic() + ".dlq", 0));
        var handler = new DefaultErrorHandler(recoverer, new FixedBackOff(200L, 2L));
        handler.addNotRetryableExceptions(JacksonException.class, IllegalArgumentException.class, NullPointerException.class);
        return handler;
    }
}
