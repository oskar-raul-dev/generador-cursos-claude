# pk03 — uv

Código de la sección [`op133-pk03-uv.md`](../../op133-pk03-uv.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `probar_uv.sh` | — |
| `ritmo.py` | Cuántas versiones publicó un paquete en los últimos 90 días, según PyPI |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install uv          # o el instalador de Astral; en la casa, una versión fija

bash probar_uv.sh
python3 ritmo.py uv pip poetry pdm
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
