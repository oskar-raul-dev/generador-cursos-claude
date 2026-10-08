"""El publicador del outbox de payments (taller 08).

El mismo algoritmo que el de orders (Java) y el de inventory (Go): leer lo pendiente con
FOR UPDATE SKIP LOCKED, enviarlo esperando la confirmación del broker y marcarlo. Al menos una vez.
"""
import asyncio
import logging

from aiokafka import AIOKafkaProducer
from opentelemetry import propagate, trace

from app.consumer import BROKERS

log = logging.getLogger("payments.outbox")
tracer = trace.get_tracer("payments.outbox")
EVERY_S = 0.2


async def run(pool):
    producer = AIOKafkaProducer(bootstrap_servers=BROKERS, acks="all", enable_idempotence=True)
    await producer.start()
    log.info("outbox publisher every %.1f s", EVERY_S)
    try:
        while True:
            try:
                await publish_pending(pool, producer)
            except Exception as e:                            # se reintenta en la siguiente ronda, en orden
                log.warning("outbox: not published yet: %s", e)
            await asyncio.sleep(EVERY_S)
    finally:
        await producer.stop()


async def publish_pending(pool, producer):
    async with pool.connection() as conn:
        async with conn.transaction():
            cur = await conn.execute(
                "SELECT id, aggregate_id, topic, type, payload, trace_context FROM outbox_events "
                "WHERE published_at IS NULL ORDER BY occurred_at LIMIT 100 FOR UPDATE SKIP LOCKED")
            for event_id, order_id, topic, fact_type, payload, trace_context in await cur.fetchall():
                # dentro de la traza que provocó el hecho, con el contexto guardado en la fila (06/07)
                parent = propagate.extract({"traceparent": trace_context}) if trace_context else None
                with tracer.start_as_current_span(f"{topic} publish", context=parent, kind=trace.SpanKind.PRODUCER,
                                                  attributes={"messaging.system": "kafka", "ms.event.type": fact_type}):
                    headers = {}
                    propagate.inject(headers)
                    await producer.send_and_wait(topic, payload.encode(), key=str(order_id).encode(),
                                                 headers=[(k, v.encode()) for k, v in headers.items()])
                await conn.execute("UPDATE outbox_events SET published_at = clock_timestamp() WHERE id = %s", (event_id,))
