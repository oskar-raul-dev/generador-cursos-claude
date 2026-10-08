"""payments escucha los hechos de orders (taller 06): al cancelarse un pedido, anula su pago pendiente.
Y participa en la saga coreografiada (taller 08): ante InventoryReserved, cobra y publica el resultado.

Un pago PENDING es un "no sé si cobré". Si el pedido se cancela, ese pago no debe resolverse después
como cobrado sin más: se marca VOIDED (anulado) y la conciliación con el proveedor decidirá si hay que
devolver algo. El efecto es idempotente por estado, y además pasa por el inbox.
"""
import asyncio
import json
import logging
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal

import httpx

from aiokafka import AIOKafkaConsumer, AIOKafkaProducer
from opentelemetry import propagate, trace

log = logging.getLogger("payments.consumer")

BROKERS = os.environ.get("PAYMENTS_KAFKA", "")
GROUP, TOPIC = "payments", "orders.events"
RESERVATIONS, RESULTS = "inventory.reservations", "payments.results"   # taller 08: la saga
MAX_ATTEMPTS = 3
# taller 07: continuar la traza que llega en los encabezados. Con "0", cada mensaje abre una traza nueva.
TRACE_KAFKA = os.environ.get("PAYMENTS_TRACE_KAFKA", "1") == "1"
tracer = trace.get_tracer("payments.consumer")


async def run(pool, psp: httpx.AsyncClient):
    consumer = AIOKafkaConsumer(TOPIC, RESERVATIONS, bootstrap_servers=BROKERS, group_id=GROUP,
                                enable_auto_commit=False,          # el offset, después del efecto
                                auto_offset_reset="earliest")
    producer = AIOKafkaProducer(bootstrap_servers=BROKERS)
    await consumer.start()
    await producer.start()
    log.info("consumer %s on %s, %s", GROUP, TOPIC, RESERVATIONS)
    try:
        async for msg in consumer:
            await handle(pool, producer, msg, psp)
            await consumer.commit()                               # solo cuando el mensaje está resuelto
    finally:
        await consumer.stop()
        await producer.stop()


async def handle(pool, producer, msg, psp):
    # el mismo trabajo que en Go: leer traceparent de los encabezados y abrir un span de consumidor
    # hijo del productor. aiokafka tiene instrumentor propio; aquí se escribe a mano para verlo.
    headers = {k: v.decode() for k, v in (msg.headers or [])}
    parent = propagate.extract(headers) if TRACE_KAFKA else None
    with tracer.start_as_current_span(f"{msg.topic} process", context=parent, kind=trace.SpanKind.CONSUMER,
                                      attributes={"messaging.system": "kafka",
                                                  "messaging.consumer.group.name": GROUP,
                                                  "messaging.destination.partition.id": str(msg.partition),
                                                  "messaging.kafka.offset": msg.offset}):
        await process(pool, producer, msg, psp)


async def process(pool, producer, msg, psp):
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            event = json.loads(msg.value)
            trace.get_current_span().set_attribute("ms.event.type", str(event.get("type")))
            if msg.topic == RESERVATIONS:                     # taller 08
                if event.get("type") == "InventoryReserved":
                    await authorize(pool, psp, event)
                return
            if event.get("type") != "OrderCancelled":
                return
            await void_pending(pool, event["eventId"], event["orderId"])
            return
        except (ValueError, KeyError) as e:
            # venenoso: reintentarlo no lo arregla. Se aparta a la DLQ con el motivo y se sigue.
            await producer.send_and_wait(msg.topic + ".dlq", msg.value, key=msg.key,
                                         headers=[("error", str(e).encode()), ("consumer", GROUP.encode())])
            log.warning("p%d o%d key=%s → DLQ (%s)", msg.partition, msg.offset, msg.key, type(e).__name__)
            return
        except Exception as e:                                    # transitorio: la base, la red…
            log.warning("p%d o%d attempt %d failed: %s", msg.partition, msg.offset, attempt, e)
            await asyncio.sleep(0.2 * attempt)
    log.error("p%d o%d: giving up after %d attempts → DLQ", msg.partition, msg.offset, MAX_ATTEMPTS)
    await producer.send_and_wait(msg.topic + ".dlq", msg.value, key=msg.key, headers=[("error", b"max attempts")])


async def void_pending(pool, event_id, order_id):
    async with pool.connection() as conn:
        async with conn.transaction():                            # marca y efecto, atómicos
            cur = await conn.execute(
                "INSERT INTO processed_messages (consumer, event_id) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                (GROUP, event_id))
            if cur.rowcount == 0:
                log.info("OrderCancelled %s → already applied, skipped", event_id[:8])
                return
            cur = await conn.execute(
                "UPDATE payments SET status = 'VOIDED' WHERE order_id = %s AND status = 'PENDING'", (order_id,))
            log.info("OrderCancelled %s order=%s → %d pending payment(s) voided", event_id[:8], order_id[:8], cur.rowcount)


async def authorize(pool, psp: httpx.AsyncClient, event):
    """La parte de payments en la saga: InventoryReserved → cobrar → PaymentAuthorized o PaymentRejected.

    Hay una llamada externa en medio, y no puede ir dentro de la transacción (retendría una conexión
    esperando al proveedor, 06/01). Por eso el orden es: mirar el inbox, cobrar con una clave que es la
    MISMA en cada re-entrega (el PSP no cobra dos veces), y registrar inbox + pago + hecho juntos.
    """
    event_id, order_id = event["eventId"], event["orderId"]
    amount = Decimal(event["total"]["amount"])
    key = f"saga-{order_id}"
    async with pool.connection() as conn:
        cur = await conn.execute("SELECT 1 FROM processed_messages WHERE consumer = %s AND event_id = %s", (GROUP, event_id))
        if await cur.fetchone():
            log.info("InventoryReserved %s → already applied, skipped", event_id[:8])
            return
    status, reference = "PENDING", None
    try:
        res = await psp.post("/payments", headers={"Idempotency-Key": key},
                             json={"orderId": order_id, "amount": f"{amount:.2f}", "currency": event["total"]["currency"]})
        res.raise_for_status()
        status, reference = res.json()["status"], res.json()["reference"]
    except (httpx.TimeoutException, httpx.TransportError) as e:
        # resultado incierto: el proveedor quizá cobró. La saga coreografiada no tiene a nadie que
        # vuelva a preguntar ni un plazo que venza: el pedido se queda donde está (06/08 §7).
        log.warning("psp did not answer for %s (%s): %s → PENDING, no fact published", order_id[:8], key, type(e).__name__)
    fact_type = {"AUTHORIZED": "PaymentAuthorized", "REJECTED": "PaymentRejected"}.get(status)
    carrier = {}
    propagate.inject(carrier)                                 # la traza sigue en el hecho (06/07)
    async with pool.connection() as conn:
        async with conn.transaction():                        # inbox, pago y hecho: atómicos
            cur = await conn.execute(
                "INSERT INTO processed_messages (consumer, event_id) VALUES (%s, %s) ON CONFLICT DO NOTHING", (GROUP, event_id))
            if cur.rowcount == 0:
                return                                        # otra entrega llegó antes
            await conn.execute(
                "INSERT INTO payments (id, order_id, operation_id, amount, status, reference) VALUES (%s, %s, %s, %s, %s, %s) "
                "ON CONFLICT (operation_id) DO UPDATE SET status = EXCLUDED.status, reference = EXCLUDED.reference",
                (uuid.uuid4(), order_id, key, amount, status, reference))
            if fact_type:
                fact_id = str(uuid.uuid4())
                payload = {"eventId": fact_id, "type": fact_type, "version": 1,
                           "occurredAt": datetime.now(timezone.utc).isoformat(), "orderId": order_id,
                           "causationId": event_id,
                           "payment": {"operationId": key, "status": status, "reference": reference, "amount": f"{amount:.2f}"}}
                await conn.execute(
                    "INSERT INTO outbox_events (id, aggregate_id, topic, type, payload, trace_context) VALUES (%s, %s, %s, %s, %s, %s)",
                    (fact_id, order_id, RESULTS, fact_type, json.dumps(payload), carrier.get("traceparent")))
    log.info("InventoryReserved %s order=%s → %s %s", event_id[:8], order_id[:8], status, fact_type or "(no fact)")
