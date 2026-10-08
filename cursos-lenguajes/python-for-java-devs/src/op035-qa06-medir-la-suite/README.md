# qa06 — Medir la suite: cobertura y mutación

Código de la sección [`op035-qa06-medir-la-suite.md`](../../op035-qa06-medir-la-suite.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `regalias.py` | La regalía trimestral: tasa, piso cero y redondeo al peso |
| `tests/test_regalias.py` | — |
| `pyproject.toml` | Configuración del ejemplo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev pytest pytest-cov mutmut

pytest -q --cov=regalias --cov-branch --cov-report=term-missing
mutmut run
mutmut results
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
