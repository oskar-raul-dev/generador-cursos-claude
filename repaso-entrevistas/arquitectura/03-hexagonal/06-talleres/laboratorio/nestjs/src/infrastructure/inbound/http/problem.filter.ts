import { type ArgumentsHost, Catch, type ExceptionFilter, HttpException, Logger } from "@nestjs/common";
import type { Request, Response } from "express";
import { AccessDenied, IdempotencyKeyReused, InvalidCredentials, NotFound, ProductAlreadyExists } from "../../../application/errors.js";
import { EmptyOrder, InsufficientInventory, OrderNotCancellable, OrderNotPayable } from "../../../domain/errors.js";
import { Unauthenticated } from "./auth.guard.js";
import { type FieldError, ValidationFailed } from "./dto.js";
import { MissingIdempotencyKey } from "./idempotency.js";

type Problem = { status: number; title: string; code: string; detail?: string; errors?: FieldError[] };

// El traductor central: cada error propio se convierte UNA vez en problem+json con el código
// estable del contrato. Ni el dominio ni los casos de uso conocen estos números.
@Catch()
export class ProblemFilter implements ExceptionFilter {
  private readonly log = new Logger(ProblemFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const request = http.getRequest<Request>();
    const response = http.getResponse<Response>();
    const problem = this.translate(exception, request);
    if (problem.status >= 500) {
      this.log.error(`unexpected error handling ${request.method} ${request.url}`, (exception as Error)?.stack);
    }
    if (problem.status === 401) response.setHeader("WWW-Authenticate", "Bearer");
    response.status(problem.status).type("application/problem+json").json({
      type: "about:blank",
      title: problem.title,
      status: problem.status,
      ...(problem.detail ? { detail: problem.detail } : {}),
      instance: request.url,
      code: problem.code,
      ...(problem.errors ? { errors: problem.errors } : {}),
    });
  }

  private translate(e: unknown, request: Request): Problem {
    // dominio
    if (e instanceof InsufficientInventory) {
      return { status: 409, title: "Insufficient inventory", code: "INSUFFICIENT_INVENTORY", detail: e.message,
        errors: [{ field: `lines[${e.lineIndex}].quantity`, message: `requested ${e.requested}, available ${e.available}` }] };
    }
    if (e instanceof OrderNotPayable) return { status: 409, title: "Order not payable", code: "ORDER_NOT_PAYABLE", detail: e.message };
    if (e instanceof OrderNotCancellable) return { status: 409, title: "Order not cancellable", code: "ORDER_NOT_CANCELLABLE", detail: e.message };
    if (e instanceof EmptyOrder) return { status: 400, title: "Validation failed", code: "VALIDATION_FAILED", detail: e.message, errors: [{ field: "lines", message: "must not be empty" }] };
    // aplicación
    if (e instanceof NotFound) {
      return e.kind === "PRODUCT"
        ? { status: 404, title: "Product not found", code: "PRODUCT_NOT_FOUND", detail: e.identifier }
        : { status: 404, title: "Order not found", code: "ORDER_NOT_FOUND" };
    }
    if (e instanceof AccessDenied) return { status: 403, title: "Forbidden", code: "FORBIDDEN" };
    if (e instanceof InvalidCredentials) return { status: 401, title: "Invalid credentials", code: "INVALID_CREDENTIALS" };
    if (e instanceof IdempotencyKeyReused) return { status: 422, title: "Idempotency-Key reused with a different payload", code: "IDEMPOTENCY_KEY_REUSED" };
    if (e instanceof ProductAlreadyExists) return { status: 409, title: "Product already exists", code: "PRODUCT_ALREADY_EXISTS", detail: e.message };
    // borde
    if (e instanceof Unauthenticated) return { status: 401, title: e.code === "TOKEN_REVOKED" ? "Token revoked" : "Unauthenticated", code: e.code };
    if (e instanceof MissingIdempotencyKey) return { status: 400, title: "Idempotency-Key required", code: "IDEMPOTENCY_KEY_REQUIRED" };
    if (e instanceof ValidationFailed) return { status: 400, title: "Validation failed", code: "VALIDATION_FAILED", errors: e.errors };
    if (e instanceof HttpException) {
      // JSON ilegible, ruta inexistente, etc.: lo que Nest ya clasificó, con un código propio por rango
      const status = e.getStatus();
      if (status === 400) return { status, title: "Validation failed", code: "VALIDATION_FAILED", errors: [{ field: "body", message: "malformed request" }] };
      if (status === 401) return { status, title: "Unauthenticated", code: "UNAUTHENTICATED" };
      if (status === 403) return { status, title: "Forbidden", code: "FORBIDDEN" };
      if (status < 500) return { status, title: e.message, code: "VALIDATION_FAILED" };
    }
    // fallo técnico: mensaje genérico; la causa va al registro, nunca al cliente
    return { status: 500, title: "Internal error", code: "INTERNAL_ERROR" };
  }
}
