import { Injectable, OnApplicationBootstrap, OnModuleDestroy } from '@nestjs/common';
import { Valkey } from 'iovalkey';
import { connect, type NatsConnection } from '@nats-io/transport-node';
import {
  AckPolicy,
  DeliverPolicy,
  StorageType,
  jetstream,
  jetstreamManager,
  type ConsumerMessages,
  type JetStreamManager,
} from '@nats-io/jetstream';
import { logLine } from './logger.js';
import { orderId, type OrderRow } from './replenishment-orders.controller.js';
import { Store } from './store.js';

// G12 (Fase 25): replenish escucha el aviso de la venta como evento, en vez de recibirlo como POST. Nadie le pide
// nada a nadie: inventory publica que el stock bajó, y replenish decide crear la orden.
export const STOCK_LOW = 'lab.inventory.stock-low';
// El stream de JetStream y el consumidor durable de replenish. El stream lo asegura quien llegue primero
// (inventory al publicar, replenish al consumir), con la misma configuración.
export const STREAM = 'LAB_EVENTS';
const DURABLE = 'replenish-stock-low';
const SECOND = 1_000_000_000; // JetStream cuenta los plazos en nanosegundos

interface StockLowEvent {
  eventId: string;
  type: string;
  saleId: string;
  store: string;
  sku: string;
  quantity: number;
  occurredAt: string;
}

export async function ensureStream(jsm: JetStreamManager) {
  try {
    await jsm.streams.info(STREAM);
  } catch {
    // Todo lo que empieza con lab., en disco, por un día: lo que nadie confirmó en un día, se pierde.
    await jsm.streams.add({ name: STREAM, subjects: ['lab.>'], storage: StorageType.File, max_age: 24 * 3600 * SECOND });
    logLine('INFO', `stream ${STREAM} creado`);
  }
}

@Injectable()
export class Events implements OnApplicationBootstrap, OnModuleDestroy {
  private valkey?: Valkey;
  private nats?: NatsConnection;
  private messages?: ConsumerMessages;

  constructor(private readonly store: Store) {}

  async onApplicationBootstrap() {
    // Sin EVENT_BUS no hay bus: el aviso sigue llegando por HTTP, como en G5.
    if (process.env.EVENT_BUS === 'valkey') await this.subscribeValkey();
    if (process.env.EVENT_BUS === 'nats') await this.consumeNats();
  }

  // La orden que pide el evento. G13 (Fase 26): consumidor idempotente. En una transacción, primero se anota el
  // evento en processed_events; si ya estaba, es una entrega repetida y no se crea nada. El ack va después del commit:
  // si el proceso muere entre los dos, el evento vuelve, encuentra su fila, y no crea otra moto.
  async handle(event: StockLowEvent, delivery = 1) {
    const created = await this.store.transaction(async (one) => {
      const fresh = await one<{ event_id: string }>(
        `INSERT INTO processed_events (event_id, processed_at) VALUES (?, ?)
         ON CONFLICT (event_id) DO NOTHING RETURNING event_id`, event.eventId, new Date().toISOString());
      if (!fresh) return undefined;
      const row = await one<OrderRow>(
        `INSERT INTO replenishment_orders (sku, destination_store, quantity, source_event_id)
         VALUES (?, ?, ?, ?) RETURNING *`,
        event.sku, event.store, event.quantity, event.eventId);
      await one('UPDATE processed_events SET order_id = ? WHERE event_id = ?', orderId(row!.seq), event.eventId);
      return row;
    });
    if (!created) {
      logLine('INFO', 'evento repetido: ya tiene su orden', { eventId: event.eventId, saleId: event.saleId, delivery });
      return;
    }
    logLine('INFO', 'orden creada por evento', {
      orderId: orderId(created.seq), eventId: event.eventId, saleId: event.saleId, delivery,
    });
  }

  // Valkey pub/sub: el mensaje llega a quien esté suscrito en ese instante. Si replenish está reiniciando, no
  // hay nadie, y el mensaje no existió nunca.
  private async subscribeValkey() {
    this.valkey = new Valkey(process.env.VALKEY_URL ?? 'redis://localhost:6379');
    this.valkey.on('message', (_channel: string, raw: string) => {
      this.handle(JSON.parse(raw) as StockLowEvent).catch((e: Error) =>
        logLine('ERROR', 'evento perdido al procesarlo', { error: e.message }));
    });
    await this.valkey.subscribe(STOCK_LOW);
    logLine('INFO', `suscrito a ${STOCK_LOW} en Valkey`);
  }

  // NATS JetStream: un consumidor durable con confirmación explícita. El servidor guarda el mensaje hasta el
  // ack; si no llega en ack_wait, lo vuelve a entregar. Al menos una vez: a veces, dos.
  private async consumeNats() {
    this.nats = await connect({ servers: process.env.NATS_URL, name: 'replenish', maxReconnectAttempts: -1 });
    const jsm = await jetstreamManager(this.nats);
    await ensureStream(jsm);
    try {
      await jsm.consumers.info(STREAM, DURABLE);
    } catch {
      await jsm.consumers.add(STREAM, {
        durable_name: DURABLE,
        filter_subject: STOCK_LOW,
        ack_policy: AckPolicy.Explicit,
        ack_wait: 30 * SECOND,
        deliver_policy: DeliverPolicy.All,
      });
    }
    const consumer = await jetstream(this.nats).consumers.get(STREAM, DURABLE);
    this.messages = await consumer.consume();
    logLine('INFO', `consumiendo ${STOCK_LOW} de ${STREAM} (durable ${DURABLE})`);
    void (async () => {
      for await (const m of this.messages!) {
        try {
          await this.handle(m.json<StockLowEvent>(), m.info.deliveryCount);
          m.ack(); // después de crear la orden: si el proceso muere antes, el evento vuelve
        } catch (e) {
          logLine('WARN', 'evento sin procesar; vuelve más tarde', { error: (e as Error).message });
          m.nak(5000);
        }
      }
    })();
  }

  async onModuleDestroy() {
    await this.messages?.close();
    await this.nats?.drain();
    this.valkey?.disconnect();
  }
}
