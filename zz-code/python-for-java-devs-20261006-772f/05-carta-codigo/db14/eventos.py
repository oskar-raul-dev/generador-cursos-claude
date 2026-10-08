"""Kafka y NATS desde Python: leer no borra, los grupos, y la mensajería que no guarda nada."""

import asyncio
import json
import os

from confluent_kafka import Consumer, Producer
from confluent_kafka.admin import AdminClient, NewTopic

BROKER = os.environ.get("AUREA_KAFKA", "kafka:9092")
admin = AdminClient({"bootstrap.servers": BROKER})
admin.list_topics(timeout=60)                           # espera a que el broker responda
admin.create_topics([NewTopic("cita-confirmada", num_partitions=3, replication_factor=1)])["cita-confirmada"].result()

producer = Producer({"bootstrap.servers": BROKER})
for i, sede in enumerate(["Suba", "Centro", "Suba", "Kennedy", "Suba", "Centro"]):
    producer.produce("cita-confirmada", key=sede, value=json.dumps({"cita": i, "sede": sede}))
producer.flush()


def read_all(group: str, from_start: bool = True) -> list[tuple[str, int, int]]:
    consumer = Consumer({"bootstrap.servers": BROKER, "group.id": group, "enable.auto.commit": False,
                         "auto.offset.reset": "earliest" if from_start else "latest"})
    consumer.subscribe(["cita-confirmada"])
    seen, idle = [], 0
    while idle < 5:
        msg = consumer.poll(1.0)
        if msg is None:
            idle += 1
            continue
        event = json.loads(msg.value())
        seen.append((event["sede"], event["cita"], msg.partition()))
        consumer.commit(message=msg, asynchronous=False)        # después de procesar, no antes
    consumer.close()
    return seen


first = read_all("recordatorios")
print("recordatorios lee:", len(first), "eventos")
print("  Suba siempre en la misma partición:", {p for s, _, p in first if s == "Suba"},
      "· orden de Suba:", [c for s, c, _ in first if s == "Suba"])
print("recordatorios otra vez:", len(read_all("recordatorios")), "eventos (ya los confirmó)")
print("liquidacion, grupo nuevo:", len(read_all("liquidacion")), "eventos (leer no borró nada)")


# ------------------------------------------------- NATS: sin JetStream no guarda; con JetStream, sí
async def nats_demo():
    import nats

    nc = await nats.connect(os.environ.get("AUREA_NATS", "nats://nats:4222"))
    await nc.publish("cita.confirmada", b'{"cita": 99}')        # nadie está suscrito todavía
    sub = await nc.subscribe("cita.confirmada")
    try:
        await sub.next_msg(timeout=1)
        print("NATS básico: llegó")
    except nats.errors.TimeoutError:
        print("NATS básico: el mensaje publicado antes de suscribirse se perdió")

    js = nc.jetstream()
    await js.add_stream(name="CITAS", subjects=["citas.>"])
    await js.publish("citas.confirmada", b'{"cita": 99}')        # tampoco hay nadie
    psub = await js.pull_subscribe("citas.>", durable="liquidacion")
    msgs = await psub.fetch(1, timeout=2)
    print("JetStream:", [m.data.decode() for m in msgs], "· secuencia", msgs[0].metadata.sequence.stream)
    await msgs[0].ack()
    await nc.close()


asyncio.run(nats_demo())
