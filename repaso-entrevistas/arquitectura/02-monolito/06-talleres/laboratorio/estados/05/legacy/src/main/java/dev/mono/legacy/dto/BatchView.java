package dev.mono.legacy.dto;

import dev.mono.legacy.entity.BatchRun;

import java.time.Instant;
import java.util.List;

// La forma de BatchExecution de los contratos hermanos, rellenada con lo que el legado sabe: un solo
// paso, sus pedidos leídos y nada más (el legado no tiene lotes de verdad; ver prompt-base §9)
public record BatchView(Long id, String jobName, String status, Instant startTime, Instant endTime, List<Step> steps) {

    public record Step(String name, String status, int readCount) {}

    public static BatchView from(BatchRun r) {
        return new BatchView(r.getId(), r.getJobName(), r.getStatus(), r.getStartedAt(), r.getEndedAt(),
                             List.of(new Step(r.getJobName(), r.getStatus(), r.getOrdersRead())));
    }
}
