// Textos que ve el usuario. Funciones puras: las usa la interfaz y las usa scripts/smoke.ts.
import type { Money, Order, Product } from "./api.ts";

export const created = (order: Order) => `✅ Pedido creado: ${order.id} (${order.status})`;

export const lineSummary = (order: Order) =>
  order.lines.map((l) => `${l.quantity} × ${l.name}`).join(", ");

// el importe llega como texto decimal: se muestra tal cual, sin pasar por un número flotante
export const money = (m: Money) => `$${m.amount}`;

export const catalogLine = (p: Product) => `${p.sku} · ${p.name} · ${money(p.unitPrice)} · stock ${p.stock}`;

// taller 04: el mensaje sale del problem+json; el código queda para decidir, no para mostrar
export const failure = (status: number, code: string, message: string) => `❌ ${message} (${status} ${code})`;
