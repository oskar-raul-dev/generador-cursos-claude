package hex.orders.infrastructure.inbound.http;

import hex.orders.application.error.NotFound;
import org.springframework.batch.core.job.JobExecution;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.StepExecution;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;

// Taller 11. Ventana operativa al JobRepository: qué hizo una ejecución, cuánto leyó, escribió y
// saltó, y en qué chunk quedó. Solo operator. Es lectura de infraestructura de lotes, no del núcleo.
@RestController
@RequestMapping("/api/v1/batches")
public class BatchController {

    public record StepSummary(String name, String status, long readCount, long writeCount, long skipCount, long commitCount, long rollbackCount) {
        static StepSummary from(StepExecution s) {
            return new StepSummary(s.getStepName(), s.getStatus().name(), s.getReadCount(), s.getWriteCount(),
                s.getSkipCount(), s.getCommitCount(), s.getRollbackCount());
        }
    }

    public record ExecutionResponse(long id, String jobName, String status, String exitCode, LocalDateTime startTime,
                                    LocalDateTime endTime, List<StepSummary> steps) {}

    private final JobRepository jobs;
    private final ActorResolver actors;

    public BatchController(JobRepository jobs, ActorResolver actors) {
        this.jobs = jobs;
        this.actors = actors;
    }

    @GetMapping("/{executionId}")
    ExecutionResponse get(@AuthenticationPrincipal Jwt jwt, @PathVariable long executionId) {
        actors.from(jwt).requireOperator();
        JobExecution execution;
        try {
            execution = jobs.getJobExecution(executionId);
        } catch (EmptyResultDataAccessException e) {
            execution = null;   // el DAO JDBC de Batch 6 lanza en vez de devolver null cuando no hay fila
        }
        if (execution == null) {
            throw new NotFound(NotFound.Kind.ORDER, "batch execution " + executionId);   // 404 con la forma del contrato
        }
        return new ExecutionResponse(execution.getId(), execution.getJobInstance().getJobName(), execution.getStatus().name(),
            execution.getExitStatus().getExitCode(), execution.getStartTime(), execution.getEndTime(),
            execution.getStepExecutions().stream().map(StepSummary::from).toList());
    }
}
