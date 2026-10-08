# ob03 — Métricas

Código de la sección [`op042-ob03-metricas.md`](../../op042-ob03-metricas.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `metricas_cierre.py` | Métricas de un proceso por lotes: histograma, contador por motivo y la hora del último éxito |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add prometheus-client

python3 metricas_cierre.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
