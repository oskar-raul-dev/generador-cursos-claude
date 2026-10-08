package dev.mono.legacy.reports.internal;

import dev.mono.legacy.orders.OrderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.net.InetAddress;
import java.time.Duration;
import java.time.Instant;

// "cierre diario": cuenta los pedidos del día, lo deja en batch_runs y de paso precalienta la caché
// (ahora pidiéndoselo a orders, que es quien tiene la caché)
@Component
public class DailyCloseJob {
    private static final Logger log = LoggerFactory.getLogger(DailyCloseJob.class);
    private final OrderService orders;
    private final BatchRunRepository runs;

    public DailyCloseJob(OrderService orders, BatchRunRepository runs) {
        this.orders = orders;
        this.runs = runs;
    }

    @Scheduled(fixedRateString = "${legacy.daily-close.every-ms}", initialDelayString = "${legacy.daily-close.every-ms}")
    public void run() throws Exception {
        BatchRun run = new BatchRun();
        run.setJobName("dailyClose");
        run.setStatus("STARTED");
        run.setStartedAt(Instant.now());
        run.setHost(InetAddress.getLocalHost().getHostName());
        int read = orders.warmCache(Instant.now().minus(Duration.ofDays(1)));
        run.setOrdersRead(read);
        run.setStatus("COMPLETED");
        run.setEndedAt(Instant.now());
        runs.save(run);
        log.info("dailyClose #{}: {} pedidos, caché con {}", run.getId(), read, read);
    }
}
