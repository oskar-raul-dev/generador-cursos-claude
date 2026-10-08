# db14 — Bitácora de eventos: Kafka y NATS

Código de la sección [`op090-db14-bitacora-de-eventos.md`](../../op090-db14-bitacora-de-eventos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `eventos.py` | Kafka y NATS desde Python: leer no borra, los grupos, y la mensajería que no guarda nada |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add confluent-kafka nats-py

docker run -d --name aurea-kafka -p 9092:9092 apache/kafka:4.3.1
docker run -d --name aurea-nats -p 4222:4222 nats:2.15.0 -js
AUREA_KAFKA=localhost:9092 AUREA_NATS=nats://localhost:4222 python3 eventos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
