# pr03 — Los formatos binarios

Código de la sección [`op125-pr03-formatos-binarios.md`](../../op125-pr03-formatos-binarios.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `evento.proto` | El contrato Protobuf |
| `formatos.py` | Diez mil eventos en siete codificaciones: tamaño, tiempo de ida y vuelta, y qué pasa con una fecha |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add orjson msgspec msgpack cbor2 protobuf grpcio-tools fastavro

python -m grpc_tools.protoc -I . --python_out=. evento.proto

python3 formatos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
