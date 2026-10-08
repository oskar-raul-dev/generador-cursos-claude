import { Injectable } from "@nestjs/common";
import type { PaymentGateway } from "../../../application/ports.js";
import { Money } from "../../../domain/money.js";
import { Payment } from "../../../domain/payment.js";

// El proveedor de pagos de las partes 1–3: la regla determinista de §11 de la guía.
@Injectable()
export class DeterministicPaymentGateway implements PaymentGateway {
  async authorize(operationId: string, amount: Money): Promise<Payment> {
    if (amount.isGreaterThan(Money.usd("1000.00"))) return new Payment("REJECTED", operationId, null);
    if (amount.hasAmount("666.00")) return new Payment("PENDING", operationId, null); // el proveedor "no respondió"
    return new Payment("AUTHORIZED", operationId, `gw-${operationId}`);
  }
}
