package dev.mono.legacy.service;

import dev.mono.legacy.entity.BatchRun;
import dev.mono.legacy.entity.Order;
import dev.mono.legacy.repository.BatchRunRepository;
import dev.mono.legacy.repository.OrderRepository;
import dev.mono.legacy.util.OrderCache;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.net.InetAddress;
import java.time.Duration;
import java.time.Instant;
import java.util.List;

// "cierre diario": cuenta los pedidos del día, lo deja en batch_runs y de paso precalienta la caché
@Component
public class DailyCloseJob {
    private static final Logger log = LoggerFactory.getLogger(DailyCloseJob.class);
    private final OrderRepository orders;
    private final BatchRunRepository runs;
    private final OrderCache cache;

    public DailyCloseJob(OrderRepository orders, BatchRunRepository runs, OrderCache cache) {
        this.orders = orders;
        this.runs = runs;
        this.cache = cache;
    }

    @Scheduled(fixedRateString = "${legacy.daily-close.every-ms}", initialDelayString = "${legacy.daily-close.every-ms}")
    public void run() throws Exception {
        BatchRun run = new BatchRun();
        run.setJobName("dailyClose");
        run.setStatus("STARTED");
        run.setStartedAt(Instant.now());
        run.setHost(InetAddress.getLocalHost().getHostName());
        List<Order> today = orders.findByCreatedAtAfter(Instant.now().minus(Duration.ofDays(1)));
        cache.clear();
        today.forEach(cache::put);
        run.setOrdersRead(today.size());
        run.setStatus("COMPLETED");
        run.setEndedAt(Instant.now());
        runs.save(run);
        log.info("dailyClose #{}: {} pedidos, caché con {}", run.getId(), today.size(), cache.size());
    }
}
