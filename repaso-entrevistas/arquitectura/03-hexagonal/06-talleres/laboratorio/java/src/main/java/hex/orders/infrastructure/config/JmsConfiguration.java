package hex.orders.infrastructure.config;

import jakarta.jms.ConnectionFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.jms.autoconfigure.DefaultJmsListenerContainerFactoryConfigurer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jms.annotation.EnableJms;
import org.springframework.jms.config.DefaultJmsListenerContainerFactory;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.connection.JmsTransactionManager;

// Taller 08. Dos transacciones locales, en orden: la de PostgreSQL la abre y cierra el caso de uso
// (puerto UnitOfWork), la de la sesión JMS la abre y cierra el contenedor del listener
// (JmsTransactionManager). El listener devuelve → el contenedor confirma la sesión → ACK del mensaje
// y envío de la respuesta, juntos. Si el proceso cae entre el commit de la base y ese ACK, el broker
// vuelve a entregar y la idempotencia por operationId absorbe la repetición. No es XA: es la ventana
// que el taller provoca a propósito.
//
// Lo que NO se hace: poner el JpaTransactionManager en el contenedor para que el listener corra
// dentro de la transacción de la base. Un rechazo de negocio lanzado dentro del UnitOfWork marcaría
// esa transacción externa como rollback-only, el listener respondería REJECTED, el commit fallaría en
// silencio y el broker reintentaría diez veces hasta la DLQ (§8 del taller).
@Configuration
@EnableJms
public class JmsConfiguration {

    private static final Logger log = LoggerFactory.getLogger(JmsConfiguration.class);

    private static Throwable rootCause(Throwable t) {
        while (t.getCause() != null && t.getCause() != t) {
            t = t.getCause();
        }
        return t;
    }

    // Sustituye a la fábrica que Boot registraría con el mismo nombre: la nuestra lleva un
    // JmsTransactionManager propio (no es un @Bean: convivir con el de JPA haría ambigua la
    // inyección de PlatformTransactionManager en el resto del sistema) y la concurrencia de hex.jms.
    @Bean
    DefaultJmsListenerContainerFactory jmsListenerContainerFactory(ConnectionFactory connectionFactory,
                                                                   DefaultJmsListenerContainerFactoryConfigurer configurer,
                                                                   HexProperties properties) {
        var factory = new DefaultJmsListenerContainerFactory();
        configurer.configure(factory, connectionFactory);
        factory.setTransactionManager(new JmsTransactionManager(connectionFactory));  // sesión transaccionada por mensaje
        factory.setSessionTransacted(true);                                            // ACK = commit de la sesión, al volver
        factory.setConcurrency(String.valueOf(properties.jms().concurrency()));
        // una línea por intento fallido; sin esto Spring vuelca la traza entera en cada redelivery
        factory.setErrorHandler(t -> log.warn("jms: listener failed, the broker will redeliver: {}", rootCause(t).toString()));
        return factory;
    }

    // Las respuestas se envían con la sesión transaccionada del listener (el JmsTransactionManager
    // la deja ligada al hilo): salen con el ACK, o no salen.
    @Bean
    JmsTemplate jmsTemplate(ConnectionFactory connectionFactory) {
        var template = new JmsTemplate(connectionFactory);
        template.setSessionTransacted(true);
        return template;
    }
}
