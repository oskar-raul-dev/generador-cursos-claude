package hex.orders.infrastructure.inbound.batch;

import hex.orders.infrastructure.config.HexProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.core.job.Job;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.Step;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.infrastructure.repeat.RepeatStatus;
import org.springframework.batch.core.configuration.annotation.StepScope;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

// Taller 11. El job dailyClose: un tasklet que escribe el cierre del día (pedidos por estado y su
// importe) en out/daily-close-YYYY-MM-DD.csv. Es un informe: lee, no decide, y no toca el núcleo.
// Lo que enseña es el JobInstance: el parámetro `date` lo identifica, y cerrar dos veces el mismo
// día es un error del JobRepository, no una segunda ejecución.
@Configuration
public class DailyCloseJobConfiguration {

    private static final Logger log = LoggerFactory.getLogger(DailyCloseJobConfiguration.class);

    @Bean
    Job dailyClose(JobRepository jobRepository, Step closeDayStep) {
        return new JobBuilder("dailyClose", jobRepository).start(closeDayStep).build();
    }

    @Bean
    Step closeDayStep(JobRepository jobRepository, PlatformTransactionManager transactionManager, Tasklet closeDay) {
        return new StepBuilder("closeDay", jobRepository).tasklet(closeDay, transactionManager).build();
    }

    @Bean
    @StepScope
    Tasklet closeDay(@Value("#{jobParameters['date']}") String date, JdbcTemplate jdbc, HexProperties properties) {
        return (contribution, context) -> {
            List<String> rows = jdbc.query(
                "SELECT status, count(*), coalesce(sum(total_amount), 0) FROM orders WHERE created_at::date = CAST(? AS date) GROUP BY status ORDER BY status",
                (rs, i) -> rs.getString(1) + "," + rs.getLong(2) + "," + rs.getBigDecimal(3).setScale(2).toPlainString(), date);
            Path out = Path.of(properties.batch().outDir()).resolve("daily-close-" + date + ".csv");
            Files.createDirectories(out.getParent());
            Files.write(out, concat("status,orders,amount", rows), StandardCharsets.UTF_8);
            contribution.incrementWriteCount(rows.size());
            log.info("batch: daily close for {} written to {} ({} status rows)", date, out, rows.size());
            return RepeatStatus.FINISHED;
        };
    }

    private static List<String> concat(String header, List<String> rows) {
        var all = new java.util.ArrayList<String>(rows.size() + 1);
        all.add(header);
        all.addAll(rows);
        return all;
    }
}
