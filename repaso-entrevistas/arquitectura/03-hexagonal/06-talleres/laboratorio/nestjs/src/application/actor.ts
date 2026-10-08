import type { Order } from "../domain/order.js";
import { AccessDenied } from "./errors.js";

export type Role = "CUSTOMER" | "OPERATOR";

// Quién ejecuta el caso de uso, ya verificado por el borde. Sin JWT, sin claims crudos, sin Nest.
export class Actor {
  constructor(
    readonly id: string,
    readonly email: string,
    readonly role: Role,
  ) {}

  isOperator(): boolean {
    return this.role === "OPERATOR";
  }

  // Autorización contextual: dueño u operador. Vive aquí porque un job o un consumidor que use el
  // mismo caso de uso tiene que cumplirla igual.
  canSee(order: Order): boolean {
    return this.isOperator() || order.customerId === this.id;
  }

  requireOperator(): void {
    if (!this.isOperator()) {
      throw new AccessDenied();
    }
  }
}
