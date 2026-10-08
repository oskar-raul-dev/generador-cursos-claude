# or04 — Pony ORM: generadores a SQL

Código de la sección [`op106-or04-pony.md`](../../op106-or04-pony.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `pony_saldos.py` | La consulta del track escrita como un generador de Python, el SQL que genera, y lo que no se puede traducir |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add pony

python3 pony_saldos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
