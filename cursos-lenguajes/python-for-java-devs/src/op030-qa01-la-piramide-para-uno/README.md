# qa01 — La pirámide para un equipo de uno

Código de la sección [`op030-qa01-la-piramide-para-uno.md`](../../op030-qa01-la-piramide-para-uno.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `pyproject.toml` | Configuración del ejemplo |
| `liquidacion.py` | Regalías del trimestre: la regla que más dinero mueve y más se discute |
| `test_liquidacion.py` | Unitarias y propiedades de la regalía: rápidas, sin servicios, en cada cambio |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev pytest hypothesis

pytest -m "not integration" --durations=3
pytest -m integration
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
