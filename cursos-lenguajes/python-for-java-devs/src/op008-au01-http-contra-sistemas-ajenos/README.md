# au01 — HTTP contra sistemas ajenos

Código de la sección [`op008-au01-http-contra-sistemas-ajenos.md`](../../op008-au01-http-contra-sistemas-ajenos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `prepagada.py` | Cliente de la API de autorizaciones: paginación, cuota y token que vence |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add httpx

python3 prepagada.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
