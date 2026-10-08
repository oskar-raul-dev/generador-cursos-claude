# lg06 — Archivos planos hostiles

Código de la sección [`op006-lg06-archivos-planos-hostiles.md`](../../op006-lg06-archivos-planos-hostiles.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `limpiar_plano.py` | Lee un plano hostil: encoding por línea, reparación con certeza, cuarentena y conciliación |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add charset-normalizer ftfy

python3 limpiar_plano.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
