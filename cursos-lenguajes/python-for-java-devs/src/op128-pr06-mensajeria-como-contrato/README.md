# pr06 — Mensajería como contrato

Código de la sección [`op128-pr06-mensajeria-como-contrato.md`](../../op128-pr06-mensajeria-como-contrato.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `asyncapi.yaml` | Configuración del ejemplo |
| `contrato.py` | El contrato de AsyncAPI aplicado en los dos extremos, con RabbitMQ y una cola de mensajes muertos |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
docker run -d --name aurea-rabbit -p 5672:5672 rabbitmq:4.3.6-alpine
uv add aio-pika jsonschema pyyaml

AUREA_AMQP=amqp://guest:guest@localhost/ python3 contrato.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
