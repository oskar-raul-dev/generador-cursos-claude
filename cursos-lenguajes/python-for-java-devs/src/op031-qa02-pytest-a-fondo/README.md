# qa02 — `pytest` a fondo

Código de la sección [`op031-qa02-pytest-a-fondo.md`](../../op031-qa02-pytest-a-fondo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `conftest.py` | Fixtures compartidas y un plugin: el presupuesto de tiempo de la suite rápida, hecho cumplir |
| `test_regalias.py` | Pruebas que usan la fábrica, la parametrización compuesta y la indirecta |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev pytest

pytest -q --budget 0.5 test_regalias.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
