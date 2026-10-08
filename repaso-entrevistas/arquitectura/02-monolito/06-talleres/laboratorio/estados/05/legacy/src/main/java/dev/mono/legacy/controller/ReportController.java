package dev.mono.legacy.controller;

import dev.mono.legacy.dto.BatchView;
import dev.mono.legacy.dto.SummaryView;
import dev.mono.legacy.repository.BatchRunRepository;
import dev.mono.legacy.service.ReportService;
import dev.mono.legacy.util.ErrorCode;
import dev.mono.legacy.util.LegacyException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class ReportController {
    private final ReportService reports;
    private final BatchRunRepository runs;

    public ReportController(ReportService reports, BatchRunRepository runs) {
        this.reports = reports;
        this.runs = runs;
    }

    @GetMapping("/reports/orders-summary")
    public SummaryView summary(@AuthenticationPrincipal Jwt jwt) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            throw new LegacyException(ErrorCode.FORBIDDEN, null);
        }
        return reports.ordersSummary();
    }

    @GetMapping("/batches/{id}")
    public BatchView batch(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            throw new LegacyException(ErrorCode.FORBIDDEN, null);
        }
        return runs.findById(id).map(BatchView::from)
            .orElseThrow(() -> new LegacyException(ErrorCode.BATCH_NOT_FOUND, String.valueOf(id)));
    }
}
