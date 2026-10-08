// Errores de aplicación: existencia, permisos, credenciales, idempotencia.
export abstract class ApplicationError extends Error {
  protected constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}

// "No existe" y "no es tuyo" se expresan igual: el borde responde 404 sin revelar existencia.
export class NotFound extends ApplicationError {
  constructor(
    readonly kind: "PRODUCT" | "ORDER",
    readonly identifier: string,
  ) {
    super(`${kind.toLowerCase()} not found: ${identifier}`);
  }
}

export class AccessDenied extends ApplicationError {
  constructor() {
    super("actor lacks the required capability");
  }
}

export class InvalidCredentials extends ApplicationError {
  constructor() {
    super("invalid credentials");
  }
}

export class IdempotencyKeyReused extends ApplicationError {
  constructor() {
    super("Idempotency-Key reused with a different payload");
  }
}

export class ProductAlreadyExists extends ApplicationError {
  constructor(readonly sku: string) {
    super(`${sku} already exists`);
  }
}
