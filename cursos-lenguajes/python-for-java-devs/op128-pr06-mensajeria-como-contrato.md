# 📬 pr06 — Mensajería como contrato

> Python para desarrolladores Java senior · **Carta** · Track `pr` — Protocolos y contratos más
> allá de REST · sección 6 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las APIs REST de Áurea tienen su contrato: FastAPI publica el OpenAPI, y quien la consume sabe qué mandar. Los eventos que viajan por la cola de mensajes,
no: el formato de "cita confirmada" está en el código del productor, y cada consumidor lo adivinó leyendo mensajes de ejemplo. Cuando un consumidor recibe
un mensaje que no entiende, lo reintenta para siempre, o lo descarta en silencio, o se cae.

La mensajería necesita lo mismo que una API: un contrato escrito y validado en los dos extremos. **AsyncAPI** es el OpenAPI de los eventos: describe los
canales, quién publica, quién consume, y el esquema de cada mensaje. Esta sección lo usa con **RabbitMQ** (AMQP) desde Python con **`aio-pika`**: el
productor valida contra el contrato antes de publicar, el consumidor valida al recibir, y lo que no cumple va a una **cola de mensajes muertos** donde
alguien lo mira, en vez de perderse o atascar la cola.

---

## 🧠 2. El modelo

```mermaid
flowchart LR
    C["asyncapi.yaml<br/>(el contrato)"] -.-> P["Productor<br/>valida antes de publicar"]
    C -.-> R["Consumidor<br/>valida al recibir"]
    P --> X["exchange 'agenda'"] -- "citas.confirmada" --> Q["cola 'recordatorios'"]
    Q --> R
    R -- "rechazado" --> D["cola 'citas.invalidas'<br/>(mensajes muertos)"]
```

| Protocolo | Biblioteca | Versión | Para qué |
|---|---|---|---|
| AMQP (RabbitMQ) | `aio-pika` | 10.1.0 | Colas con enrutamiento, confirmaciones y mensajes muertos |
| AMQP (RabbitMQ) | `pika` | 1.4.4 | Lo mismo, síncrono |
| MQTT | `paho-mqtt` | 2.1.0 💤 | Dispositivos (sensores, equipos de sede); sin versiones desde abril de 2024 |
| NATS | `nats-py` | 2.16.0 | Mensajería liviana (`db14`) |

### Tu instinto de Java dice… y esta vez se equivoca

Con Spring AMQP, el instinto confía en el `MessageConverter` y en las clases compartidas entre productor y consumidor para "tener contrato". Eso funciona
mientras los dos lados sean Java y compartan el *jar*. Con un consumidor en Python, el contrato tiene que estar fuera del código de los dos: un documento
que ninguno de los dos posee y que los dos validan.

---

## 💻 3. El ejemplo que corre

`asyncapi.yaml`:

```yaml
asyncapi: 3.0.0
info:
  title: Eventos de la agenda de Áurea
  version: 1.2.0
channels:
  citaConfirmada:
    address: citas.confirmada
    messages:
      CitaConfirmada:
        payload:
          type: object
          required: [cita, sede, hora]
          additionalProperties: false
          properties:
            cita: {type: integer, minimum: 1}
            sede: {type: string, enum: [Centro, Chapinero, Suba, Kennedy, Usaquén, Engativá, Fontibón, Restrepo, Soacha, Zipaquirá]}
            hora: {type: string, pattern: "^([01][0-9]|2[0-3]):[0-5][0-9]$"}
operations:
  publicarCitaConfirmada:
    action: send
    channel: {$ref: "#/channels/citaConfirmada"}
```

```bash
docker run -d --name aurea-rabbit -p 5672:5672 rabbitmq:4.3.6-alpine
uv add aio-pika jsonschema pyyaml
```

`contrato.py`:

```python
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
```

```bash
AUREA_AMQP=amqp://guest:guest@localhost/ python3 contrato.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
productor no publica 102: ["sede: 'Bogotá' is not one of ['Centro', 'Chapinero', 'Suba', 'Kennedy', 'Usaquén', 'Engativá', 'Fontibón', 'Restrepo', 'Soacha', 'Zipaquirá']", "hora: '9am' does not match '^([01][0-9]|2[0-3]):[0-5][0-9]$'"]
consumidor procesa 101: recordatorio para Suba a las 09:00
consumidor rechaza 103: ["(raíz): 'sede' is a required property", "(raíz): 'hora' is a required property", "(raíz): Additional properties are not allowed ('sede_id' was unexpected)"]
en citas.invalidas: {"cita": 103, "sede_id": 3} · motivo: rejected
```

El productor que respeta el contrato no publicó la cita 102 y dijo por qué: sede inexistente, hora en otro formato. La 101 llegó y se procesó. La 103, del
productor viejo, llegó porque nadie la validó al salir; el consumidor la rechazó con tres motivos, y RabbitMQ la llevó a `citas.invalidas` con la cabecera
`x-death` que dice que fue rechazada. Nada se perdió y nada se atascó.

**Detalles con intención**

- **El esquema sale del documento de AsyncAPI**, no de una copia en el código: si el contrato cambia, los dos extremos validan contra la versión nueva.
- **`additionalProperties: false`** hace que un campo inesperado sea un error. Es lo que detecta al productor viejo (`sede_id` en vez de `sede`).
- **`reject(requeue=False)`** con una cola que declara `x-dead-letter-exchange` manda el mensaje a la cola de muertos, con la cabecera `x-death` que dice por
  qué. Sin la cola de muertos, el mensaje se pierde; con `requeue=True`, vuelve a la cola y se reintenta para siempre.
- **`connect_robust`** reconecta solo si RabbitMQ se reinicia, y vuelve a declarar colas y enlaces.

---

## ⚠️ 4. Lo que se rompe

**El mensaje envenenado que se reintenta para siempre.** Un consumidor que hace `reject(requeue=True)` —o que se cae antes de confirmar— con un mensaje que
nunca va a poder procesar lo recibe una y otra vez, y bloquea a los que vienen detrás. La cola de mensajes muertos es lo que lo saca del camino.

**Las colas no durables en RabbitMQ 4.** `declare_queue("x")` sin `durable=True` declara una cola transitoria y compartida, y RabbitMQ 4.3 ya no las
permite por defecto: la conexión se cierra con `INTERNAL_ERROR - Feature transient_nonexcl_queues is deprecated`, que fue el primer error de este ejemplo. El
código de casi todos los tutoriales tiene esa línea. Las colas compartidas se declaran durables (o exclusivas, si son de una sola conexión).

**El contrato que solo valida el productor.** Un productor viejo, un script de prueba o un cambio sin coordinar publican igual. El consumidor valida siempre.

**La cola de muertos que nadie mira.** Los mensajes rechazados se acumulan en `citas.invalidas` y nadie se entera. Se vigila su tamaño y se avisa (`ob`).

**MQTT con `paho-mqtt` en un proyecto nuevo.** Funciona, y lleva desde abril de 2024 sin versiones (💤). Para MQTT es la biblioteca de referencia; se fija la
versión y se vigila.

---

## ⚖️ 5. Cuándo NO usarlo

**AsyncAPI para dos servicios del mismo equipo.** Un esquema compartido en un paquete (`pr01`) da lo mismo con menos documento; AsyncAPI se paga cuando hay
varios equipos o un catálogo de eventos que alguien consulta.

**RabbitMQ si ya hay Kafka o NATS.** Un sistema de mensajería más es un servicio más que operar (`db14`).

**Validación completa en mensajes de altísimo volumen.** Validar cada mensaje con JSON Schema cuesta; con millones por minuto, se valida en la frontera de
entrada y con `msgspec` (`pr03`), que es mucho más rápido.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas qué hizo cada extremo con cada uno de los tres mensajes.
2. Cambia `requeue=False` por `requeue=True` y deja el consumidor corriendo un segundo más. **Criterio:** cuántas veces recibe el mensaje 103.
3. Abre `asyncapi.yaml` en el AsyncAPI Studio (o genera la documentación con su CLI). **Criterio:** la documentación muestra el canal y el esquema.

**🟡 Intermedio (4–6)**

4. Agrega la versión 1.3.0 del contrato con un campo opcional `canal`. **Criterio:** los mensajes viejos siguen siendo válidos y los nuevos también.
5. Pon una cola con `x-message-ttl` y mira qué pasa con los mensajes vencidos. **Criterio:** llegan a la cola de muertos con motivo `expired`.
6. Vigila el tamaño de `citas.invalidas` y avisa si pasa de 10. **Criterio:** el aviso con el último motivo.

**🟠 Difícil (7–9)**

7. Haz el consumidor en Java con Spring AMQP y el mismo contrato. **Criterio:** los dos consumidores rechazan el mismo mensaje.
8. Mide cuántos mensajes por segundo valida y publica el productor con `jsonschema` y con `msgspec`. **Criterio:** la tabla.
9. Usa confirmaciones del publicador (`publisher confirms`) y simula que RabbitMQ rechaza un mensaje. **Criterio:** el productor se entera.

**🔴 Muy difícil (10)**

10. Escribe el catálogo de eventos de Áurea en AsyncAPI. **Criterio:** el documento y una página. *Rúbrica:* (a) cada evento con su canal, productor y
    consumidores; (b) el esquema de cada uno y sus reglas de evolución; (c) qué pasa con los mensajes inválidos; (d) dónde vive el documento y quién lo
    cambia.

---

## 📚 7. Referencias

**Documentación oficial**

- AsyncAPI 3.0: https://www.asyncapi.com/docs/reference/specification/v3.0.0
- `aio-pika`: https://docs.aio-pika.com/
- RabbitMQ, mensajes muertos: https://www.rabbitmq.com/docs/dlx

**Orden de lectura sugerido:** la página de mensajes muertos de RabbitMQ; después la introducción de AsyncAPI.

---

## 🚀 8. Cierre

Los eventos necesitan contrato igual que las APIs. AsyncAPI lo escribe fuera del código de todos; el productor valida antes de publicar, el consumidor valida al
recibir, y lo que no cumple va a una cola de mensajes muertos con su motivo, en vez de perderse o atascar la cola.

**La señal de que quedó bien:** *"Un productor viejo mandó eventos con el formato anterior, y quedaron en la cola de inválidos con su motivo, sin tumbar los
recordatorios."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pr-fase-06 -m "op pr06 cerrada: AsyncAPI validado en los dos extremos y la cola de muertos"
> ```
>
> Los commits llevan su prefijo (`op pr06: …`) y los de ejercicio su número
> (`op pr06 ej07: …`).
