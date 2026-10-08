# qa08 — La cadena de calidad

Código de la sección [`op037-qa08-la-cadena-de-calidad.md`](../../op037-qa08-la-cadena-de-calidad.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `cartera/reporte.py` | Un módulo con un defecto para cada herramienta de la cadena |
| `pyproject.toml` | Configuración del ejemplo |
| `.pre-commit-config.yaml` | Configuración del ejemplo |
| `noxfile.py` | La cadena completa: en el CI y en la máquina, igual |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev ruff mypy bandit pip-audit deptry vulture pre-commit nox
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
