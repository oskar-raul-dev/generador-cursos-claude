package dev.mono.legacy.shared;

import org.springframework.http.HttpStatus;

// Taller 04: los códigos estables del contrato (openapi.yaml, schema Problem). Un cliente decide por
// `code`, nunca por el texto: el título y el detalle pueden cambiar, el código no.
public enum ErrorCode {
    VALIDATION_FAILED(HttpStatus.BAD_REQUEST, "Validation failed"),
    INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED, "Invalid credentials"),
    UNAUTHENTICATED(HttpStatus.UNAUTHORIZED, "Unauthenticated"),
    TOKEN_REVOKED(HttpStatus.UNAUTHORIZED, "Token revoked"),
    FORBIDDEN(HttpStatus.FORBIDDEN, "Forbidden"),
    PRODUCT_NOT_FOUND(HttpStatus.NOT_FOUND, "Product not found"),
    PRODUCT_ALREADY_EXISTS(HttpStatus.CONFLICT, "Product already exists"),
    ORDER_NOT_FOUND(HttpStatus.NOT_FOUND, "Order not found"),
    INSUFFICIENT_INVENTORY(HttpStatus.CONFLICT, "Insufficient inventory"),
    ORDER_NOT_PAYABLE(HttpStatus.CONFLICT, "Order not payable"),
    ORDER_NOT_CANCELLABLE(HttpStatus.CONFLICT, "Order not cancellable"),
    BATCH_NOT_FOUND(HttpStatus.NOT_FOUND, "Batch not found"),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "Internal error");

    private final HttpStatus status;
    private final String title;

    ErrorCode(HttpStatus status, String title) {
        this.status = status;
        this.title = title;
    }

    public HttpStatus status() { return status; }

    public String title() { return title; }
}
