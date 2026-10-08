# ⚖️ pk08 — Veredicto: uno, quince o una plataforma

> Python para desarrolladores Java senior · **Carta** · Track `pk` — El panorama de gestores y
> empaquetado · sección 8 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las siete anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track abrió el modelo real de un entorno ([`pk01`](op131-pk01-el-modelo-real.md)), recorrió `pip` con `pip-tools` ([`pk02`](op132-pk02-pip-venv-y-pip-tools.md)),
`uv` ([`pk03`](op133-pk03-uv.md)), conda y Miniforge ([`pk04`](op134-pk04-conda-y-compania.md)), Poetry y PDM ([`pk05`](op135-pk05-poetry-y-pdm.md)), la
construcción y publicación de un paquete ([`pk06`](op136-pk06-empaquetar-y-publicar.md)) y las formas de entregar una herramienta
([`pk07`](op137-pk07-entregar-a-quien-no-es-ingeniero.md)). El título del veredicto resume las tres respuestas posibles a "¿con qué manejo los proyectos de
Python de la casa?".

**Uno**: `uv`, para casi todo. Hace en un binario lo que antes hacían cinco herramientas, con un *lock* universal y una salida a `requirements.txt`; medido en este
track, cinco veces más rápido que Poetry en frío y doce que PDM. **Quince**: la colección de herramientas que cada proyecto heredado trae —`pip-tools` aquí, Poetry
allá, un `setup.py` en el rincón—, que no se migra por migrar. **Una plataforma**: conda, cuando el proyecto necesita bibliotecas que no son de Python, como GDAL. La
regla de la casa es elegir **una por proyecto** y escribirla.

---

## 🧠 2. El modelo

| Situación | La respuesta | El número del track que la apoya |
|---|---|---|
| Proyecto nuevo, dependencias de PyPI | **`uv`**, con su versión fija en el CI | 1,0 s en frío contra 5,2 de Poetry y 12,1 de PDM (`pk05`); 31 versiones en 90 días (`pk03`) |
| Servidor donde solo hay `pip` | `pip` + `pip-tools`, con *hashes* | El paquete alterado se rechaza (`pk02`) |
| Bibliotecas que no son de Python | **conda** con Miniforge | `pip install gdal` falla; conda: 23 s, 81 paquetes, 517 MB (`pk04`) |
| Proyecto heredado en Poetry que funciona | Se queda en Poetry, con PEP 621 | El ahorro en segundos no paga la migración (`pk05`) |
| Biblioteca interna compartida | Rueda en un índice privado | Versión duplicada rechazada con 400 (`pk06`) |
| Herramienta para quien no es ingeniero | `uv tool`; `shiv` si es una sola plataforma | `shiv` 90 ms, `pex` 801 ms, el `.pex` atado a `cp314-aarch64` (`pk07`) |

---

## 💻 3. El ejemplo que corre

Sin dependencias. `gestor.py` es la tabla como función, aplicada a los proyectos de Áurea.

```python
"""¿uv, lo que ya hay o conda? El veredicto del track como función, aplicado a los proyectos de Áurea."""

from dataclasses import dataclass


@dataclass
class Project:
    name: str
    current_tool: str = "ninguno"           # "poetry", "pip-tools", "conda"…
    works_today: bool = True
    needs_native_libs: bool = False         # GDAL, CUDA, compiladores
    target: str = "servidor"                # "servidor", "persona", "biblioteca"
    only_pip_available: bool = False


def decide(p: Project) -> str:
    if p.needs_native_libs:
        return "conda (Miniforge), con conda-lock"
    if p.only_pip_available:
        return "pip + pip-tools, con hashes (el lock lo genera el CI)"
    if p.current_tool not in ("ninguno", "uv") and p.works_today:
        return f"se queda en {p.current_tool}; pyproject.toml en PEP 621"
    if p.target == "persona":
        return "uv tool install (o shiv, si todos usan la misma plataforma)"
    if p.target == "biblioteca":
        return "uv build + índice privado"
    return "uv, con versión fija en el CI"


PROJECTS = [
    Project("API de cartera"),
    Project("Agente de sincronización de sedes", current_tool="pip-tools", works_today=False),
    Project("Análisis geográfico de pacientes", needs_native_libs=True),
    Project("Herramienta de la franquicia de Zipaquirá", current_tool="poetry"),
    Project("aurea-cartera (biblioteca compartida)", target="biblioteca"),
    Project("Reporte de regalías para Patricia", target="persona"),
    Project("Cron del servidor de la sede Restrepo", only_pip_available=True),
]
for p in PROJECTS:
    print(f"{p.name:<44} → {decide(p)}")
```

```bash
python3 gestor.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
API de cartera                               → uv, con versión fija en el CI
Agente de sincronización de sedes            → uv, con versión fija en el CI
Análisis geográfico de pacientes             → conda (Miniforge), con conda-lock
Herramienta de la franquicia de Zipaquirá    → se queda en poetry; pyproject.toml en PEP 621
aurea-cartera (biblioteca compartida)        → uv build + índice privado
Reporte de regalías para Patricia            → uv tool install (o shiv, si todos usan la misma plataforma)
Cron del servidor de la sede Restrepo        → pip + pip-tools, con hashes (el lock lo genera el CI)
```

**Detalles con intención**

- **Las bibliotecas nativas se evalúan primero**: si el proyecto necesita GDAL, ninguna otra preferencia importa (`pk04`).
- **"Funciona hoy" protege lo heredado**: la herramienta de Zipaquirá sigue en Poetry. El agente de sincronización está en `pip-tools` pero no funciona bien, y ahí
  sí se migra.
- **La entrega a una persona es otra decisión** que la del entorno del proyecto: el reporte de regalías se desarrolla con `uv` y se entrega con `uv tool` (`pk07`).

---

## ⚠️ 4. Lo que se rompe

**Elegir la herramienta por la charla.** `uv` gana en casi todos los números del track, y aun así migrar veinte proyectos que funcionan es costo sin ganancia.

**Dos herramientas en un proyecto.** Un `poetry.lock` y un `uv.lock` son dos verdades, y el CI instala una que nadie revisó (`pk05`).

**La herramienta sin versión fija.** Con 31 versiones en 90 días, el `uv` del CI cambia solo (`pk03`).

---

## ⚖️ 5. Cuándo NO usar este veredicto

**En una organización que ya estandarizó.** Si toda la casa usa Poetry con plantillas y CI hechos, el proyecto nuevo también, aunque `uv` gane en el vacío.

**Si `uv` cambia de dueño o de rumbo.** Es de una empresa (Astral). La salida existe (`uv export`, PEP 621); conviene revisar el veredicto cada año.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega tres proyectos tuyos. **Criterio:** la salida, y si estás de acuerdo.
2. Cambia `works_today` del proyecto de Zipaquirá a `False`. **Criterio:** la nueva decisión y si la migración vale la pena.

**🟡 Intermedio (3–4)**

3. Agrega la dimensión "tiene CI con caché" y úsala para matizar la decisión de Poetry. **Criterio:** un caso que cambie.
4. Escribe las pruebas de `decide` con un caso por fila de §2. **Criterio:** seis casos, todos pasan.

**🟠 Difícil (5–6)**

5. Mide el CI de un proyecto real con su herramienta actual y con `uv`. **Criterio:** los dos tiempos y si justifican migrar.
6. Escribe el `Dockerfile` de la API de cartera y el del análisis geográfico, cada uno con su herramienta. **Criterio:** los dos construyen; los tamaños.

**🔴 Muy difícil (7–8)**

7. Escribe la política de empaquetado de Áurea. **Criterio:** una página. *Rúbrica:* (a) la herramienta por defecto y su versión; (b) las excepciones con su señal; (c)
   cómo se entrega a quien no es ingeniero; (d) cuándo se revisa la política.
8. Audita los proyectos de un repositorio real. **Criterio:** una tabla. *Rúbrica:* (a) cada proyecto con su herramienta actual; (b) la decisión de la tabla; (c) los que
   no coinciden y por qué; (d) el costo de cambiar los que deberían.

---

## 📚 7. Referencias

- Python Packaging User Guide, la guía oficial de empaquetado: https://packaging.python.org/en/latest/

**Orden de lectura sugerido:** la sección de herramientas de la guía de empaquetado, para ver la versión oficial del panorama; el resto del track tiene sus
referencias en cada sección.

---

## 🚀 8. Cierre

`uv` para casi todo, con su versión fija; lo heredado que funciona se queda donde está, con su `pyproject.toml` en el formato estándar; conda cuando hay bibliotecas
que no son de Python. Una herramienta por proyecto, escrita, y una entrega pensada en quien la va a usar.

**La señal de que quedó bien:** *"Cada proyecto de Áurea dice en su README con qué se instala, y los que no usan `uv` tienen la razón escrita al lado."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pk-fase-08 -m "op pk08 cerrada: uv por defecto, lo heredado se queda, conda para lo nativo"
> ```
>
> Los commits llevan su prefijo (`op pk08: …`) y los de ejercicio su número
> (`op pk08 ej07: …`).
