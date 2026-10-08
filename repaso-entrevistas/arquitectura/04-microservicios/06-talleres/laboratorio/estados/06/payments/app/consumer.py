"""payments escucha los hechos de orders (taller 06): al cancelarse un pedido, anula su pago pendiente.

Un pago PENDING es un "no sé si cobré". Si el pedido se cancela, ese pago no debe resolverse después
como cobrado sin más: se marca VOIDED (anulado) y la conciliación con el proveedor decidirá si hay que
devolver algo. El efecto es idempotente por estado, y además pasa por el inbox.
"""
import asyncio
import json
import logging
import os

from aiokafka import AIOKafkaConsumer, AIOKafkaProducer

log = logging.getLogger("payments.consumer")

BROKERS = os.environ.get("PAYMENTS_KAFKA", "")
GROUP, TOPIC, DLQ = "payments", "orders.events", "orders.events.dlq"
MAX_ATTEMPTS = 3


async def run(pool):
    consumer = AIOKafkaConsumer(TOPIC, bootstrap_servers=BROKERS, group_id=GROUP,
                                enable_auto_commit=False,          # el offset, después del efecto
                                auto_offset_reset="earliest")
    producer = AIOKafkaProducer(bootstrap_servers=BROKERS)
    await consumer.start()
    await producer.start()
    log.info("consumer %s on %s", GROUP, TOPIC)
    try:
        async for msg in consumer:
            await handle(pool, producer, msg)
            await consumer.commit()                               # solo cuando el mensaje está resuelto
    finally:
        await consumer.stop()
        await producer.stop()


async def handle(pool, producer, msg):
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            event = json.loads(msg.value)
            if event.get("type") != "OrderCancelled":
                return
            await void_pending(pool, event["eventId"], event["orderId"])
            return
        except (ValueError, KeyError) as e:
            # venenoso: reintentarlo no lo arregla. Se aparta a la DLQ con el motivo y se sigue.
            await producer.send_and_wait(DLQ, msg.value, key=msg.key,
                                         headers=[("error", str(e).encode()), ("consumer", GROUP.encode())])
            log.warning("p%d o%d key=%s → DLQ (%s)", msg.partition, msg.offset, msg.key, type(e).__name__)
            return
        except Exception as e:                                    # transitorio: la base, la red…
            log.warning("p%d o%d attempt %d failed: %s", msg.partition, msg.offset, attempt, e)
            await asyncio.sleep(0.2 * attempt)
    log.error("p%d o%d: giving up after %d attempts → DLQ", msg.partition, msg.offset, MAX_ATTEMPTS)
    await producer.send_and_wait(DLQ, msg.value, key=msg.key, headers=[("error", b"max attempts")])


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
