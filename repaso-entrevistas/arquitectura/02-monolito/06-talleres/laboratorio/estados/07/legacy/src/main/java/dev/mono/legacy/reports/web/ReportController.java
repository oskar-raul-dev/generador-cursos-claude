package dev.mono.legacy.reports.web;

import dev.mono.legacy.reports.internal.ReportService;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class ReportController {
    private final ReportService reports;

    public ReportController(ReportService reports) {
        this.reports = reports;
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
        return reports.batch(id).map(BatchView::from)
            .orElseThrow(() -> new LegacyException(ErrorCode.BATCH_NOT_FOUND, String.valueOf(id)));
    }
}
