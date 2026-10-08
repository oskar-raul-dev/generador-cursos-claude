# 🧱 Propuesta de fases — columna vertebral, IA y ciencia de datos

> Curso *Python para desarrolladores Java senior*.
> Los temas opcionales viven en `propuestas-temas-opcionales.md`.

> ⚠️ **Este documento está parcialmente superado, y conviene saber qué parte.**
>
> | Sección | Estado |
> |---|---|
> | §1 El eje · §2 La frontera · §3 Los cuatro proyectos | ✅ **Vigentes.** Se cumplieron tal cual en el curso escrito |
> | **§4 Camino base** | 🪦 **Retirada.** El camino base quedó en **18 fases (00–17)**, definidas en [`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) §4, **y ya están escritas**. La tabla de 21 fases se eliminó |
> | §5 Track IA · §6 Track Ciencia de datos | ✅ **Vigentes y en redacción.** Son **complementos del camino base**, no material a la carta — decisión de la §0, tomada el 13/09/2026 |
>
> **Qué pasó entre las 21 y las 18:** cuatro fusiones deliberadas —funciones y objetos, tipado y
> pruebas, operación y rendimiento, el duelo y el veredicto—, documentadas con su porqué y su
> mitigación en `propuesta-fases-y-alcance.md` §9.1. Las cuatro se sostuvieron al redactar, y las
> tres que tenían riesgo declarado lo dicen en sus 📌.

> 📝 **Sobre la empresa ficticia:** ya no se decide aparte. **Es Áurea**
> (`00-historia-de-aurea.md`), decisión cerrada. Los nombres de proyecto que aparecen en la
> §3 de este documento vienen de la empresa alternativa que se descartó, y hay que leerlos como
> **genéricos por registro** —"la herramienta CLI", "la API de servicio"— y no como nombres.

---

## 🧾 0. Qué son estos dos tracks, y cómo se nombran

> **Decisión cerrada el 13 de septiembre de 2026.** Reemplaza lo que decían la §7 de este
> documento y la nota final de la §2 de
> [`propuestas-temas-opcionales.md`](propuestas-temas-opcionales.md), que ubicaban estos dos
> tracks dentro de la carta opcional con nombres `opNNN-`.

Los tracks `ia` y `ds` **no son material a la carta**. La carta es un catálogo de tutoriales
sueltos de herramientas —`turtle`, Pillow, Playwright— que se leen por separado y que no tienen
por qué pasar por el dominio. Estos dos son otra cosa: **construyen los cuatro proyectos de IA y
de datos que Áurea ya tiene planteados** en `00-historia-de-aurea.md` §7 y §8 —NormaRAG,
Recepción asistida, Embudo y Ausentismo—, se apoyan en la API, el CLI y la base de datos que
levantó el camino base, y su corpus y sus datos son los de la empresa.

Son **complementos del camino base**: se leen después de las 18 fases, en el orden de su track, y
heredan la disciplina completa del curso.

| | Camino base (`NN-`) | **Complementos `ia` y `ds`** | Carta opcional (`opNNN-`) |
|---|---|---|---|
| Archivo | `07-cuando-deja-de-ser-un-script.md` | **`ia01-el-modelo-de-acceso-de-un-llm.md`** · **`ds03-polars-y-el-modelo-lazy.md`** | `op001-db01-el-panorama-y-el-db-api.md` |
| Código | `src/07-cuando-deja-de-ser-un-script/` | `src/ia01-el-modelo-de-acceso-de-un-llm/` | `src/op001-db01-…/` |
| Tags | `fase-07` · `mini-07` | **`ia-fase-01`** · **`ia-mini-01`** · `ds-fase-03` · `ds-mini-03` | `op-db-fase-01` |
| Commits | `fase 07: …` | `ia 01: …` · `ia 01 ej12: …` · `ia 01 mini: …` | `op db01: …` |
| Plantilla de 10 secciones | Obligatoria | **Obligatoria** | Guía, no molde |
| Medición 📏 y miniproyecto 🧱 | Obligatorios | **Obligatorios** | No se exigen |
| Dominio de Áurea | Obligatorio | **Obligatorio** | Opcional |

**Por qué `ds` y no `cd`.** El track se llamaba `cd` por *ciencia de datos*, y `cd` es el comando
más tecleado del oficio: un directorio `src/cd04-…` y un tag `cd-fase-04` se leen mal en una
terminal y peor en un `git log`. **`ds`** —*data science*, que además es como el lector lo va a
buscar— no colisiona con nada. El cambio se aplica a los diecisiete archivos, sus tags y sus
commits; en prosa las secciones se siguen citando cortas: `ia04`, `ds03`.

**Cómo queda el listado del curso.** Los dígitos ordenan antes que las letras y `d` < `i` < `o`,
así que el directorio se lee en el orden en que se escribió el curso, sin que ningún prefijo se
intercale con otro:

```text
00-instalacion-ambiente-editores-y-ecosistema.md   ← camino base, contiguo
…
17-el-duelo-y-el-veredicto.md
ds01-numpy-y-el-modelo-vectorizado.md  ← complementos
…
ia01-el-modelo-de-acceso-de-un-llm.md
…
op001-db01-el-panorama-y-el-db-api.md  ← carta opcional
```

⚠️ **Por qué tres convenciones y no una.** El curso tiene tres clases de material y una
convención de nombre para cada una; la tabla que las define está en la guía de estilo §8.2. Meter
estos dos tracks bajo `op` los habría escondido en un catálogo de cien tutoriales, cuando son la
continuación del camino base sobre los mismos proyectos. Lo que se conserva en las tres es la
propiedad que importa: `git tag -l 'fase-*'` sigue siendo el índice limpio del camino base, y
`git tag -l 'ia-*'` o `'ds-*'` es el índice de cada complemento.

**El costo, dicho entero:** este curso pasa a tener tres convenciones de nombre en vez de una, y
alguien que llegue nuevo tiene que leer esta tabla para entenderlas. Se acepta porque las tres
marcan tres cosas distintas —obligatorio, complementario y suelto— y colapsarlas en una habría
borrado justo esa distinción.

---

## 🧭 1. El eje del curso

La pregunta que ordena todo el material es:

> **¿Esto es un script, una herramienta o una aplicación?**

Ese es el modelo de acceso del curso. El reflejo a recalibrar es específico del perfil: **un
senior de Java construye una aplicación para todo**. Le pides convertir 400 CSV y entrega un
proyecto Maven con interfaces, capas, inyección de dependencias y un `Application.java`.
Python tiene tres registros de escritura reales y distintos, y el Java senior por defecto
escribe siempre en el tercero —pagando ceremonia que no necesita— o, cuando por fin escribe
un script de verdad, no sabe reconocer el momento en que ese script dejó de serlo y merece
paquete, tipos y pruebas.

El veredicto honesto de cierre se escribe solo: **cuándo tu script debía quedarse en 40
líneas, cuándo debía ser un paquete, y cuándo debiste escribirlo en Java.**

---

## 🕰️ 2. La frontera (el equivalente a la Fase 08 de Go)

**No** se replica la división por versión (3.8 → 3.13). En Go, empezar en 1.13 tenía un pago
pedagógico real: obligaba a escribir el enrutado a mano. En Python el salto de versión da
para dos secciones (`match`, `TaskGroup`, `ExceptionGroup`, PEP 695, `tomllib`,
free-threading), no para ocho fases. Forzarlo sería nostalgia sin pago.

La frontera con el mismo poder es **la restricción de dependencias y de forma**:

```text
Bloque A   Un archivo. stdlib pura. Sin venv, sin pyproject, sin dependencias.
Bloque B ⭐ La frontera: cuándo un script deja de ser un script.
Bloque C   Herramientas y aplicaciones. El ecosistema.
```

El Bloque A hace dos cosas a la vez: rompe el reflejo de *"agrego una dependencia para
parsear una fecha"* —que en el mundo Maven es gratis y en Python se paga caro— y **demuestra
la tesis del shell con esteroides**, porque la stdlib de Python *es* el reemplazo del shell:
`pathlib`, `subprocess`, `csv`, `json`, `argparse`, `sqlite3`, `zipfile`, `http.server`
vienen en la caja. Un senior de Java no tiene ni idea de cuánto viene en la caja.

El Bloque B es la migración real y es rica: `uv`, `pyproject.toml`, layout `src/`, tipado
estricto, pytest y **distribución** (pipx, zipapp, PEP 723, contenedor).

---

## 💼 3. Los cuatro proyectos empresariales, por registro

Cada uno cubre un registro distinto del trabajo real en Python, y ninguno se solapa con
otro. ⚠️ Los nombres propios de esta tabla son de la empresa que se descartó: **léelos como
genéricos por registro**. Los nombres reales de los cuatro proyectos son `aur`, AgendaAPI,
Consultorio y Cartera, y están en `00-historia-de-aurea.md` §6.

| # | Registro | Framework / stack | Idea base | Nace |
|---|---|---|---|---|
| 1 | **Herramienta CLI** — `cordi` | stdlib pura → Typer + Rich + uv; distribuida con pipx/zipapp | Consolida entradas heterogéneas, valida, genera reportes y orquesta binarios externos. **Nace como un archivo de 40 líneas en la Fase 01 y solo se vuelve paquete en la Fase 08.** Es el proyecto que sostiene la tesis del curso. | F01 |
| 2 | **API de servicio** — CatalogAPI | FastAPI + Pydantic v2 + SQLAlchemy 2.0 + PostgreSQL + Alembic + httpx | Servicio de lectura intensiva hacia afuera, con webhooks a socios, autenticación y exportaciones en streaming. Es el registro "aplicación" y la contraparte del duelo contra Spring Boot. | F11 |
| 3 | **Monolito con baterías** — Redacción | Django 5 (ORM, admin, migraciones, templates) + DRF mínimo | Back-office con ~40 pantallas de CRUD, permisos por rol y auditoría. Existe para que la comparación FastAPI ⇄ Django sea una decisión vivida: **son dos registros, no dos calidades.** | F13 |
| 4 | **Proceso por lotes** — NightPress | Celery o RQ + APScheduler + Valkey + patrón outbox | Cierre periódico reanudable, idempotente y auditable, más publicación programada. Donde la concurrencia y el GIL dejan de ser teoría porque el trabajo es CPU-bound de verdad. | F16 |

---

## 🪦 4. Camino base *(retirada)*

> La propuesta de 21 fases se retiró: el camino base quedó en 18 fases (00–17), ya escritas. La
> numeración oficial está en `propuesta-fases-y-alcance.md` §4 y su porqué en §9.1. El número de
> esta sección se conserva porque otros documentos citan §5 y §6.

---

## 🤖 5. Track IA — `ia` · 8 secciones, 2 proyectos

> Archivos `iaNN-<slug>.md`, tags `ia-fase-NN`. Plantilla de 10 secciones, medición y
> miniproyecto obligatorios (§0). Los dos proyectos son **NormaRAG** (`ia05`) y **Recepción
> asistida** (`ia07`), definidos en `00-historia-de-aurea.md` §7.

| Fase | Tema |
|---|---|
| ia01 | El modelo de acceso de un LLM: tokens, costo, latencia, no determinismo — y por qué rompe el instinto de API determinista |
| ia02 | Salida estructurada: Pydantic como contrato, JSON schema, validación y reintentos |
| ia03 | Tool calling y el bucle de agente, con el SDK oficial |
| ia04 | Embeddings y búsqueda semántica — **y cuándo BM25 o un `LIKE` le ganan**, con números |
| ia05 | **Proyecto IA-1 · RAG** sobre el corpus documental de la empresa, con citas obligatorias |
| ia06 | Evaluación: datasets, jueces, regresiones, costo y latencia medidos |
| ia07 | **Proyecto IA-2 · Agente** con herramientas que maneja el CLI y la API del curso |
| ia08 | Producción: caché de prompts, límites, guardrails, observabilidad, ⚖️ cuándo NO usar un LLM |

**Stack por defecto:** la API de Claude y su SDK de Python —decisión de este curso, fijada en
`alcance-del-proyecto.md` §9 y argumentada en la §8 de aquí—, con Ollama local para los ejercicios que no deban
costar dinero, y una sección comparativa honesta de frameworks —LangChain, LlamaIndex,
Pydantic AI, o ninguno— porque el veredicto más probable es *"para esto no necesitabas
framework"*.

---

## 📊 6. Track Ciencia de datos — `ds` · 9 secciones, 2 proyectos

> Archivos `dsNN-<slug>.md`, tags `ds-fase-NN`. Antes se llamaba `cd`; el porqué del cambio
> está en la §0. Los dos proyectos son **Embudo** (`ds04`) y **Ausentismo** (`ds08`), definidos
> en `00-historia-de-aurea.md` §8.

| Fase | Tema |
|---|---|
| ds01 | NumPy y el modelo vectorizado: por qué tu bucle es el enemigo, medido |
| ds02 | pandas: el modelo de DataFrame, el índice, y sus trampas clásicas |
| ds03 | Polars y el modelo lazy — **pandas ⇄ Polars ⇄ bucle a mano**, con la conclusión incómoda de que a 5.000 filas el bucle gana |
| ds04 | **Proyecto CD-1 · Análisis**: limpieza, joins, series temporales, estacionalidad del negocio |
| ds05 | Visualización: matplotlib, plotly, altair — y cuándo una tabla gana a un gráfico |
| ds06 | Notebooks y reproducibilidad: Jupyter, marimo, papermill, y el veredicto sobre notebooks en producción |
| ds07 | scikit-learn: baseline honesto, features, evaluación, fugas de datos |
| ds08 | **Proyecto CD-2 · Modelo**: redes neuronales mínimas en PyTorch (con Keras/TensorFlow comparado) |
| ds09 | Servir el modelo: ONNX, endpoint en la API del curso, latencia medida, ⚖️ veredicto |

---

## 🔢 7. Cuentas

**Cuentas de la propuesta original:** 21 fases base + 17 de proyecto (IA y datos) + los tracks
opcionales, con ocho proyectos.

**Cuentas reales, hoy:** **18 fases base escritas** (00–17, con cuatro proyectos empresariales), y
**17 secciones complementarias en redacción** —`ia01`–`ia08` y `ds01`–`ds09`—, que construyen los
cuatro proyectos de IA y datos de Áurea. **No son material a la carta**: la §0 explica por qué y
cómo se nombran.

> 🔤 **Nomenclatura, en una línea:** `ia01-el-modelo-de-acceso-de-un-llm.md`,
> `ds03-polars-y-el-modelo-lazy.md`, con `src/<mismo nombre>/` y tags `ia-fase-01` / `ds-fase-03`.
> La tabla completa, la comparación con las otras dos convenciones del curso y la divergencia
> y su argumento están en la **§0**.

> 🪦 **Lo que decía esta sección antes:** que los dos tracks eran opcionales *por la misma
> definición* que los de `propuestas-temas-opcionales.md` y que usarían `op031-ia01-…` /
> `op044-cd03-…`. Se revirtió el 13/09/2026: son complementos del camino base, no platos de la
> carta, y el nombre tenía que decirlo.

---

## 📦 8. Versiones del stack de estos dos tracks

Las versiones **no viven aquí**: viven en `alcance-del-proyecto.md` §9, que es la única fuente del
curso, y se verificaron contra PyPI el **13 de septiembre de 2026** antes de escribir la primera
línea de `ia01`. Este documento propone temas; aquel fija números.

Lo que sí se decide aquí, porque es alcance y no versión:

- **El proveedor de LLM es la API de Claude**, con el SDK oficial `anthropic`. La afirmación de
  que *"lo manda una convención de más arriba"* que traía este documento **era falsa**, y se
  corrige: es una decisión de este curso, tomada porque el material tiene que fijar un proveedor
  para poder medir costo y latencia con el mismo arnés.
- **Ollama corre en local** todos los ejercicios que no deban costar dinero, y es también la
  única vía por la que un dato que roce la frontera clínica puede tocar un modelo (§5 de la
  historia de Áurea).
- **La comparación de frameworks** —LangChain, LlamaIndex, Pydantic AI, o ninguno— es una sección
  de `ia08`, y el veredicto más probable está escrito de antemano en la propuesta: *para esto no
  necesitabas framework*. Si la medición dice otra cosa, gana la medición.
