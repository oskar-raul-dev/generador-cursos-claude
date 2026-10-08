# tx06 — Documentación como producto

Código de la sección [`op060-tx06-documentacion.md`](../../op060-tx06-documentacion.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `cartera.py` | Cálculos de cartera de la red Áurea |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev pdoc

python3 -m doctest -v cartera.py | tail -3
pdoc cartera.py -o docs && ls docs

sed -i 's/tasa_mensual_pct: int = 15/tasa_mensual_pct: int = 18/' cartera.py
python3 -m doctest cartera.py | head -8
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
