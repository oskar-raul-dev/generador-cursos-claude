# sy03 — Inspección del sistema

Código de la sección [`op117-sy03-inspeccion-del-sistema.md`](../../op117-sy03-inspeccion-del-sistema.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `agente.py` | El agente se inspecciona, crea y recoge un zombi, choca con el límite de archivos y maneja SIGTERM |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add psutil

python3 agente.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
