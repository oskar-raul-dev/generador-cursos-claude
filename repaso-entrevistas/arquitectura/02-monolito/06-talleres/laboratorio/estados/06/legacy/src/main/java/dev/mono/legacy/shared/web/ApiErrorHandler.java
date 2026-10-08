package dev.mono.legacy.shared.web;

import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.net.URI;
import java.util.List;
import java.util.Map;

// Taller 04: el único sitio donde un error se convierte en respuesta HTTP. Sustituye a los
// catch (LegacyException e) { return Json.error(...) } repartidos por los controladores y al 500 con
// la traza de Java en el cuerpo. Formato: application/problem+json (RFC 9457) + `code` propio.
@RestControllerAdvice
public class ApiErrorHandler {
    private static final Logger log = LoggerFactory.getLogger(ApiErrorHandler.class);

    @ExceptionHandler(LegacyException.class)
    ResponseEntity<ProblemDetail> business(LegacyException e, HttpServletRequest req) {
        var problem = problem(e.code(), e.getMessage(), req);
        if (!e.errors().isEmpty()) {
            problem.setProperty("errors", e.errors());
        }
        return respond(problem);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ProblemDetail> invalidBody(MethodArgumentNotValidException e, HttpServletRequest req) {
        var errors = e.getBindingResult().getFieldErrors().stream()
            .map(fe -> Map.of("field", fe.getField(),
                              "message", fe.getDefaultMessage() == null ? "invalid" : fe.getDefaultMessage()))
            .toList();
        var problem = problem(ErrorCode.VALIDATION_FAILED, null, req);
        problem.setProperty("errors", errors);
        return respond(problem);
    }

    // cuerpo que no es JSON, un id que no es UUID, un parámetro fuera de rango: forma, no existencia
    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class,
        HandlerMethodValidationException.class})
    ResponseEntity<ProblemDetail> malformed(Exception e, HttpServletRequest req) {
        var problem = problem(ErrorCode.VALIDATION_FAILED, "malformed request", req);
        problem.setProperty("errors", List.of(Map.of("field", "request", "message", "malformed request")));
        return respond(problem);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    ResponseEntity<ProblemDetail> noRoute(NoResourceFoundException e, HttpServletRequest req) {
        var problem = ProblemDetail.forStatus(404);
        problem.setTitle("Not found");
        problem.setInstance(URI.create(req.getRequestURI()));
        return respond(problem);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ProblemDetail> unexpected(Exception e, HttpServletRequest req) {
        // la causa, entera, al log; al cliente, un código y nada de clases, SQL ni trazas
        log.error("unexpected error on {} {}", req.getMethod(), req.getRequestURI(), e);
        return respond(problem(ErrorCode.INTERNAL_ERROR, null, req));
    }

    static ProblemDetail problem(ErrorCode code, String detail, HttpServletRequest req) {
        var problem = ProblemDetail.forStatus(code.status());
        problem.setTitle(code.title());
        problem.setDetail(detail);
        problem.setInstance(URI.create(req.getRequestURI()));
        problem.setProperty("code", code.name());
        return problem;
    }

    private static ResponseEntity<ProblemDetail> respond(ProblemDetail problem) {
        return ResponseEntity.status(problem.getStatus()).contentType(MediaType.APPLICATION_PROBLEM_JSON).body(problem);
    }
}
