package dev.mono.legacy.controller;

import dev.mono.legacy.repository.BatchRunRepository;
import dev.mono.legacy.service.ReportService;
import dev.mono.legacy.util.Json;
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
    public Object summary(@AuthenticationPrincipal Jwt jwt) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            return Json.error("Only operators can do this");
        }
        return reports.ordersSummary();
    }

    @GetMapping("/batches/{id}")
    public Object batch(@AuthenticationPrincipal Jwt jwt, @PathVariable Long id) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            return Json.error("Only operators can do this");
        }
        return runs.findById(id).<Object>map(r -> r).orElse(Json.error("Batch not found"));
    }
}
