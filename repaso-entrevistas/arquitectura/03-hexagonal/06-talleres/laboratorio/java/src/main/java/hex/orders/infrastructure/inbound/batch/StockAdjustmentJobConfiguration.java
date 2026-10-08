package hex.orders.infrastructure.inbound.batch;

import hex.orders.application.Actor;
import hex.orders.application.error.NotFound;
import hex.orders.application.usecase.AdjustStock;
import hex.orders.domain.InsufficientInventory;
import hex.orders.infrastructure.config.HexProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.core.job.Job;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.listener.SkipListener;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.Step;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.infrastructure.item.ItemProcessor;
import org.springframework.batch.infrastructure.item.ItemWriter;
import org.springframework.batch.infrastructure.item.file.FlatFileItemReader;
import org.springframework.batch.infrastructure.item.file.builder.FlatFileItemReaderBuilder;
import org.springframework.batch.core.configuration.annotation.StepScope;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.FileSystemResource;
import org.springframework.transaction.PlatformTransactionManager;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.UUID;

// Taller 11. El job stockAdjustment: lee stock-YYYY-MM-DD.csv por chunks, valida cada línea y llama
// al caso de uso AdjustStock por cada una. El lote es un adaptador de ENTRADA más (como HTTP, la cola
// o gRPC): traduce filas a comandos y no decide nada. Lo que Spring Batch pone: el chunk como
// transacción pequeña, el JobRepository como checkpoint, el reinicio desde el último chunk confirmado
// y la política de skip como cuarentena.
@Configuration
public class StockAdjustmentJobConfiguration {

    private static final Logger log = LoggerFactory.getLogger(StockAdjustmentJobConfiguration.class);
    // El lote actúa como un operador del sistema: identidad fija, de confianza, como el emisor de la cola.
    static final Actor BATCH = new Actor(UUID.fromString("00000000-0000-4000-8000-00000000ba7c"), "batch@hex.local", Actor.Role.OPERATOR);

    @Bean
    Job stockAdjustment(JobRepository jobRepository, Step adjustStockStep) {
        return new JobBuilder("stockAdjustment", jobRepository)
            .start(adjustStockStep)
            .build();
    }

    @Bean
    Step adjustStockStep(JobRepository jobRepository, PlatformTransactionManager transactionManager,
                         FlatFileItemReader<StockLine> stockLineReader, ItemProcessor<StockLine, AdjustStock.Command> validate,
                         ItemWriter<AdjustStock.Command> apply, SkipListener<StockLine, AdjustStock.Command> quarantine,
                         HexProperties properties) {
        // chunk(int) sin transaction manager es el modelo nuevo de Batch 6 (ChunkOrientedStepBuilder);
        // chunk(int, tm) es el heredado y avisa de su retirada en 7.0.
        return new StepBuilder("adjustStock", jobRepository)
            .<StockLine, AdjustStock.Command>chunk(properties.batch().chunkSize())   // N filas = una transacción
            .transactionManager(transactionManager)
            .reader(stockLineReader)
            .processor(validate)
            .writer(apply)
            .faultTolerant()
            .skip(InvalidStockLine.class, NotFound.class, InsufficientInventory.class)   // forma inválida, SKU desconocido, stock negativo: cuarentena
            .skipLimit(properties.batch().skipLimit())
            .skipListener(quarantine)
            .build();
    }

    // @StepScope: el archivo es un parámetro del job, así que el reader se construye por ejecución.
    // FlatFileItemReader guarda en el ExecutionContext cuántas líneas leyó: un reinicio sigue desde ahí.
    @Bean
    @StepScope
    FlatFileItemReader<StockLine> stockLineReader(@Value("#{jobParameters['file']}") String file) {
        return new FlatFileItemReaderBuilder<StockLine>()
            .name("stockLineReader")
            .resource(new FileSystemResource(file))
            .linesToSkip(1)                          // la cabecera sku,delta,reason
            .delimited().names("sku", "delta", "reason")
            .targetType(StockLine.class)
            .build();
    }

    // La validación de forma va en el processor; una línea mala lanza y el step la salta.
    @Bean
    ItemProcessor<StockLine, AdjustStock.Command> validate(HexProperties properties) {
        return line -> {
            if (line.sku() == null || !line.sku().matches("^SKU-[0-9]{3,}$")) {
                throw new InvalidStockLine(line, "sku must match SKU-nnn");
            }
            int delta;
            try {
                delta = Integer.parseInt(line.delta().trim());
            } catch (NumberFormatException e) {
                throw new InvalidStockLine(line, "delta must be an integer");
            }
            if (delta == 0) {
                throw new InvalidStockLine(line, "delta must not be zero");
            }
            if ("crash-on-marker".equals(properties.batch().chaos()) && "CRASH".equals(line.reason())) {
                // Solo laboratorio: la JVM muere a mitad de chunk. Lo confirmado hasta el chunk anterior
                // queda; lo de este chunk se revierte; el reinicio sigue desde el último commit.
                log.error("batch: CHAOS crash-on-marker at {} — halting the JVM mid-chunk", line.sku());
                Runtime.getRuntime().halt(137);
            }
            return new AdjustStock.Command(BATCH, line.sku(), delta, line.reason());
        };
    }

    // El writer llama al caso de uso por cada fila del chunk. Su UnitOfWork se une a la transacción del
    // chunk (REQUIRED): un fallo en la fila 37 revierte el chunk entero, y Batch reintenta el chunk
    // fila a fila para aislar la culpable y saltarla.
    @Bean
    ItemWriter<AdjustStock.Command> apply(AdjustStock adjustStock) {
        return chunk -> {
            for (AdjustStock.Command command : chunk) {
                var result = adjustStock.execute(command);
                log.debug("batch: {} {} → {}", result.sku(), result.delta(), result.available());
            }
        };
    }

    // Cuarentena: cada línea saltada se escribe con su motivo en <archivo>.quarantine.csv.
    @Bean
    @StepScope
    SkipListener<StockLine, AdjustStock.Command> quarantine(@Value("#{jobParameters['file']}") String file) {
        Path target = Path.of(file + ".quarantine.csv");
        return new SkipListener<>() {
            @Override
            public void onSkipInProcess(StockLine item, Throwable t) {
                append(item.sku() + "," + item.delta() + "," + item.reason() + ",\"" + t.getMessage() + "\"");
            }

            @Override
            public void onSkipInWrite(AdjustStock.Command item, Throwable t) {
                append(item.sku() + "," + item.delta() + "," + item.reason() + ",\"" + t.getMessage() + "\"");
            }

            private void append(String line) {
                log.warn("batch: quarantined {}", line);
                try {
                    Files.writeString(target, line + System.lineSeparator(), StandardCharsets.UTF_8,
                        StandardOpenOption.CREATE, StandardOpenOption.APPEND);
                } catch (IOException e) {
                    throw new IllegalStateException("cannot write quarantine file " + target, e);
                }
            }
        };
    }
}
