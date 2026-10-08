# qa10 — Veredicto: qué vale la pena cuando eres uno

Código de la sección [`op039-qa10-veredicto.md`](../../op039-qa10-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `presupuesto.py` | Lee el reporte JUnit de pytest y vigila el presupuesto: total, las más lentas y por archivo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pytest -q -m "not integration" --junitxml=reporte.xml
python3 presupuesto.py reporte.xml
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
