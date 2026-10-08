package hex.orders.infrastructure.config;

import org.springframework.batch.core.configuration.support.JdbcDefaultBatchConfiguration;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;

// Taller 11. El JobRepository de Spring Batch en PostgreSQL, con el DataSource y el transaction manager
// del sistema: el checkpoint de cada chunk se confirma en la MISMA transacción que las filas que el
// chunk modificó. Batch 6 arranca por defecto con un repositorio "resourceless" (en memoria, sin
// checkpoint) y Boot 4 registra esa configuración por defecto; @EnableJdbcJobRepository no la
// desplaza (§9 del taller). Un @Configuration que EXTIENDE JdbcDefaultBatchConfiguration sí: Boot
// se retira al ver una DefaultBatchConfiguration propia.
@Configuration
public class BatchConfiguration extends JdbcDefaultBatchConfiguration {

    private final DataSource dataSource;
    private final PlatformTransactionManager transactionManager;

    public BatchConfiguration(DataSource dataSource, PlatformTransactionManager transactionManager) {
        this.dataSource = dataSource;
        this.transactionManager = transactionManager;
    }

    @Override
    protected DataSource getDataSource() {
        return dataSource;
    }

    @Override
    protected PlatformTransactionManager getTransactionManager() {
        return transactionManager;
    }
}
