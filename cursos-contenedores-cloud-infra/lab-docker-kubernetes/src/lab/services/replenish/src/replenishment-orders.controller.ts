import { Body, Controller, Get, Headers, HttpCode, HttpException, Param, Post, Query } from '@nestjs/common';
import { Store } from './store.js';

export interface OrderRow {
  seq: number | string; // Postgres devuelve los BIGINT como texto
  sku: string;
  destination_store: string;
  origin_store: string | null;
  quantity: number;
  status: string;
  cancel_reason_code: string | null;
  replaces_order_id: string | null;
  source_event_id: string | null;
  idempotency_key: string | null;
}

const SKU = /^SKU-[0-9]{4}$/;
const STORE = /^DRO-[0-9]{3}$/;

function fail(status: number, error: string, message: string): never {
  throw new HttpException({ error, message }, status);
}

// El identificador visible sale del consecutivo: RO-0001, RO-0002…
export const orderId = (seq: number | string) => `RO-${String(seq).padStart(4, '0')}`;
const seqOf = (id: string) => (/^RO-[0-9]{4,}$/.test(id) ? Number(id.slice(3)) : -1);

export function toOrder(row: OrderRow) {
  return {
    id: orderId(row.seq),
    sku: row.sku,
    destinationStore: row.destination_store,
    originStore: row.origin_store,
    quantity: row.quantity,
    status: row.status,
    cancelReasonCode: row.cancel_reason_code,
    replacesOrderId: row.replaces_order_id,
    sourceEventId: row.source_event_id ?? null,
    idempotencyKey: row.idempotency_key ?? null,
  };
}

// Las órdenes en su propio almacén (G1; Postgres desde G3). Una orden no se edita: se cancela y se crea otra (D33).
@Controller()
export class ReplenishmentOrdersController {
  constructor(private readonly store: Store) {}

  private find(id: string): Promise<OrderRow | undefined> {
    return this.store.one<OrderRow>('SELECT * FROM replenishment_orders WHERE seq = ?', seqOf(id));
  }

  @Get('replenishment-orders')
  async list(@Query('idempotencyKey') key?: string) {
    // G13: con la clave, la orden que se creó con ella (o ninguna): así quien pidió sin respuesta puede preguntar.
    const rows = key
      ? await this.store.all<OrderRow>('SELECT * FROM replenishment_orders WHERE idempotency_key = ?', key)
      : await this.store.all<OrderRow>('SELECT * FROM replenishment_orders ORDER BY seq');
    return rows.map(toOrder);
  }

  // G13: la orden ya creada con esta clave, si el cuerpo es el mismo; 422 si la clave se usó con otro cuerpo.
  private async replay(key: string, body: Record<string, unknown>) {
    const row = await this.store.one<OrderRow>('SELECT * FROM replenishment_orders WHERE idempotency_key = ?', key);
    if (!row) return undefined;
    const same = row.sku === body.sku && row.destination_store === body.destinationStore &&
      (row.origin_store ?? null) === (body.originStore ?? null) && Number(row.quantity) === body.quantity;
    if (!same) fail(422, 'unprocessable', `la clave ${key} ya se usó con otro pedido`);
    return toOrder(row);
  }

  @Post('replenishment-orders')
  async create(@Body() body: Record<string, unknown>, @Headers('idempotency-key') key?: string) {
    if (key) {
      const previous = await this.replay(key, body ?? {});
      if (previous) return previous;
    }
    const { sku, destinationStore, originStore = null, quantity, replacesOrderId = null } = body ?? {};
    if (
      typeof sku !== 'string' || !SKU.test(sku) ||
      typeof destinationStore !== 'string' || !STORE.test(destinationStore) ||
      (originStore !== null && (typeof originStore !== 'string' || !STORE.test(originStore))) ||
      !Number.isInteger(quantity) || (quantity as number) < 1
    ) {
      fail(422, 'unprocessable', 'se esperan sku, destinationStore, quantity (1 o más) y originStore opcional');
    }
    if (replacesOrderId !== null) {
      const replaced = typeof replacesOrderId === 'string' ? await this.find(replacesOrderId) : undefined;
      if (!replaced || replaced.status !== 'CANCELLED') {
        fail(422, 'unprocessable', 'replacesOrderId tiene que ser una orden existente y cancelada');
      }
    }
    // RETURNING lo entienden los dos motores: el consecutivo nuevo, sin una segunda consulta.
    try {
      const created = await this.store.one<OrderRow>(
        `INSERT INTO replenishment_orders (sku, destination_store, origin_store, quantity, replaces_order_id, idempotency_key)
         VALUES (?, ?, ?, ?, ?, ?) RETURNING *`,
        sku as string, destinationStore as string, originStore as string | null, quantity as number,
        replacesOrderId as string | null, key ?? null);
      return toOrder(created!);
    } catch (e) {
      // G13: dos pedidos con la misma clave a la vez: el índice único deja pasar uno; el otro devuelve el primero.
      const previous = key ? await this.replay(key, body) : undefined;
      if (previous) return previous;
      throw e;
    }
  }

  @Get('replenishment-orders/:id')
  async get(@Param('id') id: string) {
    const row = await this.find(id);
    if (!row) fail(404, 'not_found', `no existe ${id}`);
    return toOrder(row);
  }

  @Post('replenishment-orders/:id/cancel')
  @HttpCode(200)
  async cancel(@Param('id') id: string, @Body() body: Record<string, unknown>) {
    const row = await this.find(id);
    if (!row) fail(404, 'not_found', `no existe ${id}`);
    const code = body?.reasonCode;
    const valid =
      typeof code === 'string' &&
      (await this.store.one('SELECT 1 FROM reason_codes WHERE code = ? AND active = 1', code)) !== undefined;
    if (!valid) fail(422, 'unprocessable', 'el código de razón no existe o está inactivo');
    // G13 (Fase 26): cancelar dos veces es cancelar una. La saga reintenta su compensación, y el primer intento
    // pudo haber llegado aunque su respuesta se perdiera: sin esto, la compensación recibe 409 para siempre.
    if (row.status === 'CANCELLED') return toOrder(row);
    // Solo se cancela lo que no salió: una orden despachada ya está en una moto.
    if (row.status !== 'PENDING') fail(409, 'conflict', `la orden está en ${row.status}, no en PENDING`);
    const cancelled = await this.store.one<OrderRow>(
      `UPDATE replenishment_orders SET status = 'CANCELLED', cancel_reason_code = ? WHERE seq = ? RETURNING *`,
      code as string, Number(row.seq));
    return toOrder(cancelled!);
  }

  @Get('reason-codes')
  async reasonCodes() {
    const rows = await this.store.all<{ code: string; description: string; active: number }>(
      'SELECT code, description, active FROM reason_codes ORDER BY code');
    return rows.map((r) => ({ code: r.code, description: r.description, active: r.active === 1 }));
  }
}
