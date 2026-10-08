# pk07 — Entregar a quien no es ingeniero

Código de la sección [`op137-pk07-entregar-a-quien-no-es-ingeniero.md`](../../op137-pk07-entregar-a-quien-no-es-ingeniero.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `regalias/regalias.py` | Reporte de regalías: lee un JSON de ventas y escribe el total por franquicia |
| `regalias_pep723.py` | script |
| `entregar.sh` | — |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install shiv pex uv
bash entregar.sh
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
