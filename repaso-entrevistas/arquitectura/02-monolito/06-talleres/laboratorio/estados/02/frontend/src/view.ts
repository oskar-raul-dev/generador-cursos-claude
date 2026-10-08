// Textos que ve el usuario. Funciones puras: las usa la interfaz y las usa scripts/smoke.ts.
import type { Order } from "./api.ts";

export const created = (order: Order) => `✅ Pedido creado: ${order.id} (${order.status})`;

export const lineSummary = (order: Order) =>
  order.lines.map((l) => `${l.quantity} × ${l.productName}`).join(", ");

export const money = (n: number) => `$${n}`;
