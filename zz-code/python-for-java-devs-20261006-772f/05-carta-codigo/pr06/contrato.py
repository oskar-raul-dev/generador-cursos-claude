"""El contrato de AsyncAPI aplicado en los dos extremos, con RabbitMQ y una cola de mensajes muertos."""

import asyncio
import json
import os

import aio_pika
import yaml
from jsonschema import Draft202012Validator

spec = yaml.safe_load(open("asyncapi.yaml"))
channel = spec["channels"]["citaConfirmada"]
validator = Draft202012Validator(channel["messages"]["CitaConfirmada"]["payload"])
ROUTING = channel["address"]


def problems(message: dict) -> list[str]:
    return [f"{'/'.join(map(str, e.path)) or '(raíz)'}: {e.message}" for e in validator.iter_errors(message)]


async def main():
    for _ in range(60):
        try:
            conn = await aio_pika.connect_robust(os.environ.get("AUREA_AMQP", "amqp://guest:guest@rabbit/"))
            break
        except Exception:
            await asyncio.sleep(1)
    async with conn:
        ch = await conn.channel()
        exchange = await ch.declare_exchange("agenda", aio_pika.ExchangeType.TOPIC, durable=True)
        dead = await ch.declare_exchange("agenda.muertos", aio_pika.ExchangeType.FANOUT, durable=True)
        invalid_q = await ch.declare_queue("citas.invalidas", durable=True)       # RabbitMQ 4: colas durables
        await invalid_q.bind(dead)
        queue = await ch.declare_queue("recordatorios", durable=True,
                                       arguments={"x-dead-letter-exchange": "agenda.muertos"})
        await queue.bind(exchange, ROUTING)

        # El productor que respeta el contrato: valida antes de publicar.
        for message in [{"cita": 101, "sede": "Suba", "hora": "09:00"}, {"cita": 102, "sede": "Bogotá", "hora": "9am"}]:
            if errors := problems(message):
                print(f"productor no publica {message['cita']}: {errors}")
                continue
            await exchange.publish(aio_pika.Message(json.dumps(message).encode()), routing_key=ROUTING)
        # Un productor viejo que no valida.
        await exchange.publish(aio_pika.Message(b'{"cita": 103, "sede_id": 3}'), routing_key=ROUTING)

        # El consumidor: valida al recibir; lo que no cumple, a mensajes muertos.
        handled = 0
        async with queue.iterator() as messages:
            async for incoming in messages:
                body = json.loads(incoming.body)
                if errors := problems(body):
                    print(f"consumidor rechaza {body.get('cita')}: {errors}")
                    await incoming.reject(requeue=False)
                else:
                    print(f"consumidor procesa {body['cita']}: recordatorio para {body['sede']} a las {body['hora']}")
                    await incoming.ack()
                handled += 1
                if handled == 2:
                    break
        await asyncio.sleep(0.5)
        dead_message = await invalid_q.get(no_ack=True)
        print("en citas.invalidas:", dead_message.body.decode(), "· motivo:", dead_message.headers["x-death"][0]["reason"])


asyncio.run(main())
