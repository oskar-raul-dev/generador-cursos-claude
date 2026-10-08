import { createHash } from "node:crypto";
import { ValidationFailed } from "./dto.js";

// Regla del borde HTTP: la operación exige la cabecera del contrato.
export class MissingIdempotencyKey extends Error {
  constructor() {
    super("Idempotency-Key header is required");
    this.name = "MissingIdempotencyKey";
  }
}

export function requireIdempotencyKey(header: string | undefined): string {
  if (!header || header.trim() === "") throw new MissingIdempotencyKey();
  if (header.length < 8 || header.length > 128) {
    throw new ValidationFailed([{ field: "Idempotency-Key", message: "must be between 8 and 128 characters" }]);
  }
  return header;
}

export function requestHash(canonical: string): string {
  return createHash("sha256").update(canonical, "utf8").digest("hex");
}
