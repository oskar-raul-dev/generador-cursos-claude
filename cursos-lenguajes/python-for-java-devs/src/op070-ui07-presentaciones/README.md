# ui07 — Presentaciones programáticas

Código de la sección [`op070-ui07-presentaciones.md`](../../op070-ui07-presentaciones.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `comite.py` | La presentación del comité mensual: una diapositiva por sede, con tabla y gráfico nativos |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add python-pptx

python3 comite.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
