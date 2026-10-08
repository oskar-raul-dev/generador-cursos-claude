import { Type } from "class-transformer";
import { ArrayMaxSize, ArrayMinSize, IsArray, IsEmail, IsInt, IsNotEmpty, IsString, Matches, Max, MaxLength, Min, MinLength, ValidateNested, type ValidationError } from "class-validator";
import type { Page } from "../../../application/page.js";
import type { Notification } from "../../../application/ports.js";
import type { ProductWithStock } from "../../../application/usecases/list-products.js";
import { Money } from "../../../domain/money.js";
import type { Order } from "../../../domain/order.js";
import type { OrderLine } from "../../../domain/order-line.js";
import type { Payment } from "../../../domain/payment.js";

// Los DTO del contrato HTTP: forma pública y validación de forma con class-validator. Los
// decoradores viven aquí, en el borde; el núcleo recibe comandos con tipos propios.

export class LoginRequest {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
}

export class MoneyDto {
  @Matches(/^-?[0-9]+\.[0-9]{2}$/, { message: "must be a decimal with two digits" }) amount!: string;
  @Matches(/^[A-Z]{3}$/) currency!: string;

  toMoney(): Money {
    return Money.of(this.amount, this.currency);
  }
}

export class CreateProductRequest {
  @Matches(/^SKU-[0-9]{3,}$/) sku!: string;
  @IsString() @IsNotEmpty() @MaxLength(120) name!: string;
  @ValidateNested() @Type(() => MoneyDto) unitPrice!: MoneyDto;
  @IsInt() @Min(0) stock!: number;
}

export class LineRequestDto {
  @Matches(/^SKU-[0-9]{3,}$/) sku!: string;
  @IsInt() @Min(1) @Max(1000) quantity!: number;
}

export class CreateOrderRequest {
  @IsArray() @ArrayMinSize(1, { message: "must not be empty" }) @ArrayMaxSize(50)
  @ValidateNested({ each: true }) @Type(() => LineRequestDto)
  lines!: LineRequestDto[];

  // Huella canónica del cuerpo para la idempotencia
  canonical(): string {
    return this.lines.map((l) => `${l.sku}:${l.quantity}`).join(",");
  }
}

// ---------------------------------------------------------------- errores de forma

export type FieldError = { field: string; message: string };

export class ValidationFailed extends Error {
  constructor(readonly errors: FieldError[]) {
    super("validation failed");
    this.name = "ValidationFailed";
  }
}

export function flattenValidationErrors(errors: ValidationError[], prefix = ""): FieldError[] {
  return errors.flatMap((e) => {
    const field = prefix ? `${prefix}.${e.property}` : e.property;
    const own = Object.values(e.constraints ?? {}).map((message) => ({ field, message }));
    return [...own, ...flattenValidationErrors(e.children ?? [], field)];
  });
}

// ---------------------------------------------------------------- salida

const money = (m: Money) => ({ amount: m.amountAsText(), currency: m.currency });

export const toProductResponse = (p: ProductWithStock) => ({
  sku: p.product.sku, name: p.product.name, unitPrice: money(p.product.unitPrice), stock: p.stock,
});

const toLine = (l: OrderLine) => ({
  sku: l.sku, name: l.name, quantity: l.quantity, unitPrice: money(l.unitPrice), lineTotal: money(l.lineTotal()),
});

const toPayment = (p: Payment | null) => (p ? { status: p.status, operationId: p.operationId, reference: p.reference } : null);

export const toOrderResponse = (o: Order) => ({
  id: o.id, customerId: o.customerId, status: o.status, lines: o.lines.map(toLine),
  total: money(o.total), payment: toPayment(o.payment), createdAt: o.createdAt.toISOString(),
});

export const toPaymentResponse = (o: Order, p: Payment) => ({ orderId: o.id, orderStatus: o.status, payment: toPayment(p) });

export const toNotificationResponse = (n: Notification) => ({
  id: n.id, orderId: n.orderId, type: n.type, recipient: n.recipient, createdAt: n.createdAt.toISOString(),
});

export const toPageResponse = <T>(page: Page<T>) => ({ items: page.items, nextCursor: page.nextCursor });
