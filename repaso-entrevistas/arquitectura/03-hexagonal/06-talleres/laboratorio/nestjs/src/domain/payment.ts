export type PaymentStatus = "AUTHORIZED" | "REJECTED" | "PENDING";

// Resultado de un intento de autorización. operationId es la Idempotency-Key del intento.
export class Payment {
  constructor(
    readonly status: PaymentStatus,
    readonly operationId: string,
    readonly reference: string | null,
  ) {}
}
