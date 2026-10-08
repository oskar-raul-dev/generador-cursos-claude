# pr02 — gRPC y Protobuf

Código de la sección [`op124-pr02-grpc-y-protobuf.md`](../../op124-pr02-grpc-y-protobuf.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `agenda.proto` | El contrato Protobuf |
| `agenda.py` | Un servicio gRPC de prueba y su cliente: llamada unaria, streaming del servidor, plazos y su costo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add grpcio grpcio-tools

python -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. agenda.proto

python3 agenda.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
