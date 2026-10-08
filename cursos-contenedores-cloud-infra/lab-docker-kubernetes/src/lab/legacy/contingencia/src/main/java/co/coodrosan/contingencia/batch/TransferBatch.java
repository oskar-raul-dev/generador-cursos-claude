package co.coodrosan.contingencia.batch;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.Resource;
import jakarta.ejb.EJB;
import jakarta.ejb.Singleton;
import jakarta.ejb.Startup;
import jakarta.ejb.Timeout;
import jakarta.ejb.Timer;
import jakarta.ejb.TimerConfig;
import jakarta.ejb.TimerService;
import jakarta.ejb.TransactionAttribute;
import jakarta.ejb.TransactionAttributeType;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.logging.Logger;

// El lote de traslados: cada TRANSFER_BATCH_MINUTES minutos despacha los préstamos pendientes y deja
// el archivo que la Braqui recoge. Primero confirma en la base y DESPUÉS escribe el archivo.
@Singleton
@Startup
public class TransferBatch {

    private static final Logger LOG = Logger.getLogger(TransferBatch.class.getName());
    private static final DateTimeFormatter NAME = DateTimeFormatter.ofPattern("yyyyMMdd_HHmm");

    @Resource
    private TimerService timerService;

    @EJB
    private LoanDispatcher dispatcher;

    @PostConstruct
    void schedule() {
        long minutes = Long.parseLong(System.getenv().getOrDefault("TRANSFER_BATCH_MINUTES", "15"));
        timerService.createIntervalTimer(minutes * 60_000, minutes * 60_000, new TimerConfig("traslados", false));
        LOG.info("Lote de traslados programado cada " + minutes + " minutos");
    }

    // Sin transacción propia: la de LoanDispatcher ya se confirmó cuando se escribe el archivo.
    @Timeout
    @TransactionAttribute(TransactionAttributeType.NOT_SUPPORTED)
    void run(Timer timer) {
        List<String> lines = dispatcher.dispatchPending();
        if (lines.isEmpty()) {
            return;
        }
        Path dir = Path.of(System.getenv().getOrDefault("TRANSFER_DIR", "/var/lib/contingencia/traslados"));
        String base = "traslados_" + LocalDateTime.now().format(NAME);
        try {
            Files.createDirectories(dir);
            Files.write(dir.resolve(base + ".txt"), lines, StandardCharsets.UTF_8);
            // El .ok vacío es el primer parche de 2020: avisa que el .txt terminó de escribirse.
            Files.createFile(dir.resolve(base + ".ok"));
            LOG.info("Escrito " + base + ".txt con " + lines.size() + " traslados");
        } catch (IOException e) {
            // Los préstamos ya quedaron despachados en la base. Nadie los va a recibir.
            LOG.severe("No se pudo escribir " + base + ".txt: " + e.getMessage());
        }
    }
}
