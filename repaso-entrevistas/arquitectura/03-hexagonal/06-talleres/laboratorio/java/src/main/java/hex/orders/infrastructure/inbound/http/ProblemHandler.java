package hex.orders.infrastructure.inbound.http;

import hex.orders.application.error.AccessDenied;
import hex.orders.application.error.IdempotencyKeyReused;
import hex.orders.application.error.InvalidCredentials;
import hex.orders.application.error.NotFound;
import hex.orders.application.error.ProductAlreadyExists;
import hex.orders.domain.EmptyOrder;
import hex.orders.domain.InsufficientInventory;
import hex.orders.domain.OrderNotCancellable;
import hex.orders.domain.OrderNotPayable;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.List;
import java.util.Map;

// El traductor central: cada error propio (dominio o aplicación) se convierte UNA vez en un
// problem+json con el código estable del contrato. Ni el dominio ni los casos de uso conocen
// estos números.
@RestControllerAdvice
public class ProblemHandler {

    private static final Logger log = LoggerFactory.getLogger(ProblemHandler.class);

    // ---------------------------------------------------------------- dominio

    @ExceptionHandler(InsufficientInventory.class)
    ResponseEntity<ProblemDetail> insufficientInventory(InsufficientInventory e, HttpServletRequest req) {
        var problem = problem(HttpStatus.CONFLICT, "Insufficient inventory", "INSUFFICIENT_INVENTORY", e.getMessage(), req);
        problem.setProperty("errors", List.of(Map.of(
            "field", "lines[" + e.lineIndex() + "].quantity",
            "message", "requested " + e.requested() + ", available " + e.available())));
        return respond(problem);
    }

    @ExceptionHandler(OrderNotPayable.class)
    ResponseEntity<ProblemDetail> orderNotPayable(OrderNotPayable e, HttpServletRequest req) {
        return respond(problem(HttpStatus.CONFLICT, "Order not payable", "ORDER_NOT_PAYABLE", e.getMessage(), req));
    }

    @ExceptionHandler(OrderNotCancellable.class)
    ResponseEntity<ProblemDetail> orderNotCancellable(OrderNotCancellable e, HttpServletRequest req) {
        return respond(problem(HttpStatus.CONFLICT, "Order not cancellable", "ORDER_NOT_CANCELLABLE", e.getMessage(), req));
    }

    @ExceptionHandler(EmptyOrder.class)
    ResponseEntity<ProblemDetail> emptyOrder(EmptyOrder e, HttpServletRequest req) {
        var problem = problem(HttpStatus.BAD_REQUEST, "Validation failed", "VALIDATION_FAILED", e.getMessage(), req);
        problem.setProperty("errors", List.of(Map.of("field", "lines", "message", "must not be empty")));
        return respond(problem);
    }

    // ---------------------------------------------------------------- aplicación

    @ExceptionHandler(NotFound.class)
    ResponseEntity<ProblemDetail> notFound(NotFound e, HttpServletRequest req) {
        return switch (e.kind()) {
            case PRODUCT -> respond(problem(HttpStatus.NOT_FOUND, "Product not found", "PRODUCT_NOT_FOUND", e.identifier(), req));
            case ORDER -> respond(problem(HttpStatus.NOT_FOUND, "Order not found", "ORDER_NOT_FOUND", null, req));
        };
    }

    @ExceptionHandler(AccessDenied.class)
    ResponseEntity<ProblemDetail> accessDenied(AccessDenied e, HttpServletRequest req) {
        return respond(problem(HttpStatus.FORBIDDEN, "Forbidden", "FORBIDDEN", null, req));
    }

    @ExceptionHandler(InvalidCredentials.class)
    ResponseEntity<ProblemDetail> invalidCredentials(InvalidCredentials e, HttpServletRequest req) {
        return respond(problem(HttpStatus.UNAUTHORIZED, "Invalid credentials", "INVALID_CREDENTIALS", null, req));
    }

    @ExceptionHandler(IdempotencyKeyReused.class)
    ResponseEntity<ProblemDetail> keyReused(IdempotencyKeyReused e, HttpServletRequest req) {
        return respond(problem(HttpStatus.UNPROCESSABLE_CONTENT, "Idempotency-Key reused with a different payload",
            "IDEMPOTENCY_KEY_REUSED", null, req));
    }

    @ExceptionHandler(ProductAlreadyExists.class)
    ResponseEntity<ProblemDetail> productExists(ProductAlreadyExists e, HttpServletRequest req) {
        return respond(problem(HttpStatus.CONFLICT, "Product already exists", "PRODUCT_ALREADY_EXISTS", e.getMessage(), req));
    }

    // ---------------------------------------------------------------- borde: forma de la petición

    @ExceptionHandler(MissingIdempotencyKey.class)
    ResponseEntity<ProblemDetail> missingKey(MissingIdempotencyKey e, HttpServletRequest req) {
        return respond(problem(HttpStatus.BAD_REQUEST, "Idempotency-Key required", "IDEMPOTENCY_KEY_REQUIRED", null, req));
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    ResponseEntity<ProblemDetail> missingHeader(MissingRequestHeaderException e, HttpServletRequest req) {
        if ("Idempotency-Key".equalsIgnoreCase(e.getHeaderName())) {
            return respond(problem(HttpStatus.BAD_REQUEST, "Idempotency-Key required", "IDEMPOTENCY_KEY_REQUIRED", null, req));
        }
        return validation(List.of(Map.of("field", e.getHeaderName(), "message", "required header")), req);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ProblemDetail> invalidBody(MethodArgumentNotValidException e, HttpServletRequest req) {
        var errors = e.getBindingResult().getFieldErrors().stream()
            .map(fe -> Map.of("field", fe.getField(), "message", messageOf(fe)))
            .toList();
        return validation(errors, req);
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class,
        HandlerMethodValidationException.class, IllegalArgumentException.class})
    ResponseEntity<ProblemDetail> unreadable(Exception e, HttpServletRequest req) {
        return validation(List.of(Map.of("field", "body", "message", "malformed request")), req);
    }

    // ---------------------------------------------------------------- fallo técnico

    @ExceptionHandler(Exception.class)
    ResponseEntity<ProblemDetail> unexpected(Exception e, HttpServletRequest req) {
        // La causa se registra entera; el cliente recibe un mensaje genérico y nada de SQL ni trazas.
        log.error("unexpected error handling {} {}", req.getMethod(), req.getRequestURI(), e);
        return respond(problem(HttpStatus.INTERNAL_SERVER_ERROR, "Internal error", "INTERNAL_ERROR", null, req));
    }

    // ---------------------------------------------------------------- utilidades

    private static ResponseEntity<ProblemDetail> validation(List<Map<String, String>> errors, HttpServletRequest req) {
        var problem = problem(HttpStatus.BAD_REQUEST, "Validation failed", "VALIDATION_FAILED", null, req);
        problem.setProperty("errors", errors);
        return respond(problem);
    }

    private static ProblemDetail problem(HttpStatus status, String title, String code, String detail, HttpServletRequest req) {
        var problem = ProblemDetail.forStatus(status);
        problem.setTitle(title);
        problem.setDetail(detail);
        problem.setInstance(java.net.URI.create(req.getRequestURI()));
        problem.setProperty("code", code);
        return problem;
    }

    private static ResponseEntity<ProblemDetail> respond(ProblemDetail problem) {
        return ResponseEntity.status(problem.getStatus())
            .contentType(MediaType.APPLICATION_PROBLEM_JSON)
            .body(problem);
    }

    private static String messageOf(FieldError fe) {
        return fe.getDefaultMessage() == null ? "invalid" : fe.getDefaultMessage();
    }
}
