import io
p = "prompts/alcance-del-proyecto.md"
s = io.open(p, encoding="utf-8").read()

old_start = "| Herramienta | Versión | Dónde vive |"
old_end = "> con su número exacto en esta tabla primero.\n"
i = s.index(old_start)
j = s.index(old_end) + len(old_end)

new = """| Herramienta | Versión | Dónde vive |
|---|---|---|
| Python | **3.14.7** (piso soportado: 3.13.15) | Fase 00 · todo el curso |
| Gestión de entorno, Bloque A | `venv` + `pip` **26.2.1** de la biblioteca estándar | Fase 00 |
| Gestión de entorno, Bloques B y C | **`uv` 0.12.13** | Fase 07 en adelante |
| Comparados contra `uv` en la frontera | `pip-tools` **7.6.1** y **Miniforge 26.7.2-0** (`conda-forge`) | Fase 07, medidos |
| Formato y lint | `ruff` **0.16.7** | Fase 00 · transversal |
| Tipado | `mypy` **2.3.1** (alternativa: `pyright` **1.1.414**) en modo estricto | Fase 08 |
| Pruebas | `pytest` **9.1.1**, `pytest-cov` **7.1.0**, `hypothesis` **6.168.0** | Fase 08 · transversal |
| Editor principal | VS Code + extensión oficial de Python | Fase 00 |
| Editor alternativo | PyCharm Community | Fase 00 |

**Dependencias del Bloque C**, fijadas aquí antes de usarse:

| Herramienta | Versión | Dónde vive |
|---|---|---|
| FastAPI · Pydantic · Uvicorn | **0.141.1** · **2.13.5** · **0.52.4** | Fase 10 en adelante |
| SQLAlchemy · Alembic · psycopg | **2.0.52** · **1.20.0** · **3.3.5** | Fase 11 en adelante |
| Django | **6.1.1** | Fase 12 |
| httpx | **0.28.1** | Fase 13 |
| Celery · arq · redis-py | **5.6.3** · **0.28.0** · **8.1.0** | Fase 15 |
| structlog · prometheus-client · OpenTelemetry SDK | **26.1.0** · **0.26.0** · **1.44.0** | Fase 16 |

> 📅 **Fecha de verificación: 12 de septiembre de 2026.** Todos los números de arriba se
> consultaron ese día contra PyPI, python.org y el repositorio de Miniforge. No hay ninguno
> puesto de memoria. Cuando una fase se redacte meses después, se vuelve a verificar y **se
> corrige aquí primero**; el curso declara la fecha en vez de fingir que el ecosistema se
> detuvo.

> 📄 **Sobre conda.** Cuando el curso use conda, usa **Miniforge con el canal `conda-forge`**,
> que es comunitario y libre. Los canales por defecto de Anaconda, cuyos términos comerciales
> dependen del tamaño de la organización, **no entran al curso** — así el tema de licenciamiento
> deja de existir en vez de tener que explicarse.

> ⚠️ **Las versiones exactas —patch incluido— se cierran en la discusión de fases y se
> escriben aquí antes de redactar la primera línea que las use.** Ninguna se da por buena de
> memoria. Esta tabla es la única fuente; si una fase necesita una dependencia nueva, se fija
> con su número exacto en esta tabla primero.
"""
s = s[:i] + new + s[j:]
io.open(p, "w", encoding="utf-8").write(s)
print("ok")
