# pr01 — El eje: contrato implícito, esquema, IDL

Código de la sección [`op123-pr01-el-eje.md`](../../op123-pr01-el-eje.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `v1/cita.proto` | El contrato Protobuf |
| `v2/cita.proto` | El contrato Protobuf |
| `eje.py` | El cambio del viernes en los tres escalones: JSON implícito, esquema de Pydantic y Protobuf |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add pydantic grpcio-tools protobuf

python -m grpc_tools.protoc -I . --python_out=. v1/cita.proto v2/cita.proto

python3 eje.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
