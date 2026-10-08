package dev.mono.legacy.reports.internal;

import dev.mono.legacy.orders.OrderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.net.InetAddress;
import java.time.Duration;
import java.time.Instant;

// "cierre diario": cuenta los pedidos del día y lo deja en batch_runs. Desde el taller 08, sin caché
// que precalentar y con un lease para que corra en una sola instancia.
@Component
public class DailyCloseJob {
    private static final Logger log = LoggerFactory.getLogger(DailyCloseJob.class);
    private final OrderService orders;
    private final BatchRunRepository runs;
    private final JobLeases leases;
    private final long everyMs;
    private final String instance;

    // taller 08: host:puerto, para distinguir dos instancias en la misma máquina
    public DailyCloseJob(OrderService orders, BatchRunRepository runs, JobLeases leases,
                         @Value("${legacy.daily-close.every-ms}") long everyMs, @Value("${server.port}") int port)
        throws Exception {
        this.orders = orders;
        this.runs = runs;
        this.leases = leases;
        this.everyMs = everyMs;
        this.instance = InetAddress.getLocalHost().getHostName() + ":" + port;
    }

    @Scheduled(fixedRateString = "${legacy.daily-close.every-ms}", initialDelayString = "${legacy.daily-close.every-ms}")
    public void run() throws Exception {
        // taller 08: una sola instancia por periodo; el lease dura lo que el periodo
        if (!leases.tryAcquire("dailyClose", instance, everyMs)) {
            return;
        }
        BatchRun run = new BatchRun();
        run.setJobName("dailyClose");
        run.setStatus("STARTED");
        run.setStartedAt(Instant.now());
        run.setHost(instance);
        int read = (int) orders.countCreatedSince(Instant.now().minus(Duration.ofDays(1)));
        run.setOrdersRead(read);
        run.setStatus("COMPLETED");
        run.setEndedAt(Instant.now());
        runs.save(run);
        log.info("dailyClose #{} en {}: {} pedidos", run.getId(), instance, read);
    }
}
