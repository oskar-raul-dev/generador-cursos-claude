package dev.ms.monolith.web;

import dev.ms.monolith.service.Errors;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.List;
import java.util.Map;

// Todo error sale como application/problem+json (RFC 9457) con un `code` estable del contrato.
@RestControllerAdvice
public class ApiErrors {
    private static final Logger log = LoggerFactory.getLogger(ApiErrors.class);

    @ExceptionHandler(Errors.InvalidCredentials.class)
    ResponseEntity<ProblemDetail> invalidCredentials(Errors.InvalidCredentials e, HttpServletRequest r) {
        return problem(HttpStatus.UNAUTHORIZED, "Invalid credentials", "INVALID_CREDENTIALS", null, r);
    }

    @ExceptionHandler(Errors.ProductNotFound.class)
    ResponseEntity<ProblemDetail> productNotFound(Errors.ProductNotFound e, HttpServletRequest r) {
        return problem(HttpStatus.NOT_FOUND, "Product not found", "PRODUCT_NOT_FOUND", e.getMessage(), r);
    }

    @ExceptionHandler({Errors.OrderNotFound.class, MethodArgumentTypeMismatchException.class})
    ResponseEntity<ProblemDetail> orderNotFound(Exception e, HttpServletRequest r) {
        return problem(HttpStatus.NOT_FOUND, "Order not found", "ORDER_NOT_FOUND", null, r);
    }

    @ExceptionHandler(Errors.InsufficientInventory.class)
    ResponseEntity<ProblemDetail> insufficient(Errors.InsufficientInventory e, HttpServletRequest r) {
        var res = problem(HttpStatus.CONFLICT, "Insufficient inventory", "INSUFFICIENT_INVENTORY", e.getMessage(), r);
        res.getBody().setProperty("errors", List.of(Map.of("field", "lines[" + e.lineIndex + "].quantity",
            "message", "requested " + e.requested + ", available " + e.available)));
        return res;
    }

    @ExceptionHandler(Errors.OrderNotPayable.class)
    ResponseEntity<ProblemDetail> notPayable(Errors.OrderNotPayable e, HttpServletRequest r) {
        return problem(HttpStatus.CONFLICT, "Order not payable", "ORDER_NOT_PAYABLE", e.getMessage(), r);
    }

    @ExceptionHandler(Errors.OrderNotCancellable.class)
    ResponseEntity<ProblemDetail> notCancellable(Errors.OrderNotCancellable e, HttpServletRequest r) {
        return problem(HttpStatus.CONFLICT, "Order not cancellable", "ORDER_NOT_CANCELLABLE", e.getMessage(), r);
    }

    @ExceptionHandler(Errors.InventoryUnavailable.class)
    ResponseEntity<ProblemDetail> inventoryUnavailable(Errors.InventoryUnavailable e, HttpServletRequest r) {
        log.warn("{} {}: {}", r.getMethod(), r.getRequestURI(), e.getMessage());
        return problem(HttpStatus.SERVICE_UNAVAILABLE, "Inventory unavailable", "INVENTORY_UNAVAILABLE", null, r);
    }

    @ExceptionHandler(Errors.IdempotencyKeyRequired.class)
    ResponseEntity<ProblemDetail> keyRequired(Errors.IdempotencyKeyRequired e, HttpServletRequest r) {
        return problem(HttpStatus.BAD_REQUEST, "Idempotency-Key required", "IDEMPOTENCY_KEY_REQUIRED", null, r);
    }

    @ExceptionHandler(Errors.IdempotencyKeyReused.class)
    ResponseEntity<ProblemDetail> keyReused(Errors.IdempotencyKeyReused e, HttpServletRequest r) {
        return problem(HttpStatus.UNPROCESSABLE_CONTENT, "Idempotency-Key reused with a different payload", "IDEMPOTENCY_KEY_REUSED", null, r);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ProblemDetail> invalid(MethodArgumentNotValidException e, HttpServletRequest r) {
        var errors = e.getBindingResult().getFieldErrors().stream()
            .map(f -> Map.of("field", f.getField(), "message", String.valueOf(f.getDefaultMessage()))).toList();
        var res = problem(HttpStatus.BAD_REQUEST, "Validation failed", "VALIDATION_FAILED", null, r);
        res.getBody().setProperty("errors", errors);
        return res;
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<ProblemDetail> unreadable(HttpMessageNotReadableException e, HttpServletRequest r) {
        return problem(HttpStatus.BAD_REQUEST, "Validation failed", "VALIDATION_FAILED", "malformed JSON body", r);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ProblemDetail> unexpected(Exception e, HttpServletRequest r) {
        log.error("unexpected error on {} {}", r.getMethod(), r.getRequestURI(), e);
        return problem(HttpStatus.INTERNAL_SERVER_ERROR, "Internal error", "INTERNAL_ERROR", e.getClass().getSimpleName(), r);
    }

    private static ResponseEntity<ProblemDetail> problem(HttpStatus status, String title, String code, String detail,
                                                         HttpServletRequest r) {
        var p = ProblemDetail.forStatus(status);
        p.setTitle(title);
        if (detail != null) p.setDetail(detail);
        p.setInstance(java.net.URI.create(r.getRequestURI()));
        p.setProperty("code", code);
        return ResponseEntity.status(status).contentType(MediaType.APPLICATION_PROBLEM_JSON).body(p);
    }
}
