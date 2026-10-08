# pk05 — Poetry y PDM

Código de la sección [`op135-pk05-poetry-y-pdm.md`](../../op135-pk05-poetry-y-pdm.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `medir_gestores.sh` | — |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install poetry pdm uv
bash medir_gestores.sh
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
