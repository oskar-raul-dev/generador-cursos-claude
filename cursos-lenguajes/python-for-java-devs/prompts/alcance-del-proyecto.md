# 🎯 Alcance del proyecto
## Python para desarrolladores Java senior

Documento de encuadre. Define qué es este curso, para quién, qué produce y —tan
importante— qué **no** hace. Se lee antes de escribir cualquier fase.

> 🧭 **Este documento es la autoridad máxima del curso**, junto con
> `propuesta-fases-y-alcance.md` para lo estructural. Las dos propuestas exploratorias
> (`propuestas-fases-base-ia-datos.md` y `propuestas-temas-opcionales.md`) siguen siendo
> material de trabajo válido, pero **cuando contradigan a este documento, manda este**.
> No hay ninguna autoridad por encima: ver la §0.

> ✅ **Estado (13/09/2026): el camino base está escrito.** Las **18 fases (00–17)** existen en la
> raíz del curso, junto con `0-ESTRUCTURA-CURSO.md`, `00-convencion-de-git-y-tags.md`,
> `00-historia-de-aurea.md`,
> `BENCHMARKS.md` e `INSTINTOS.md`. Lo que sigue es **material a la carta**: secciones opcionales
> `opNNN-<tt>NN-<slug>.md` catalogadas en `propuestas-temas-opcionales.md`. Este documento pasa de
> ser un plan a ser el contrato de lo escrito: si una fase ya publicada lo contradice, se corrige
> aquí y se anota el porqué, no se reescribe la fase en silencio.

---

## 0. El curso es autocontenido

> **Decisión de forma, y la que más consecuencias tiene para quien escriba aquí.** Esta carpeta
> se puede copiar a cualquier sitio —otro repositorio, otro proyecto, un `zip` que alguien
> descarga— y **funciona entera**, sin depender de ningún archivo que esté por encima de ella ni
> al lado de ella.

Eso significa tres cosas concretas, y las tres se comprueban leyendo:

**No hay autoridad externa.** Este documento es el techo. Todo lo que gobierna al curso —la voz,
el idioma, el estilo de código, los marcadores, las convenciones de archivo, la disciplina de
medición, el flujo de git— vive en `prompts/` y está escrito aquí dentro. Un documento de este
curso **nunca** empieza su lista de fuentes de verdad con un archivo de fuera.

**No se cita ningún otro curso.** Ni como material complementario, ni como "eso vive en otro
sitio", ni para justificar una decisión de forma. Cuando el curso excluye un tema —teoría de
aprendizaje automático, cómputo en GPU, orquestación de contenedores— **declara la exclusión y se
detiene ahí**: nombrar dónde estaría ese material convierte una exclusión limpia en una promesa
que esta carpeta no puede cumplir.

**Y el lector no necesita nada más que esto y un intérprete.** Es la regla 4 de la guía §11 y
aquí está su origen: ningún ejercicio pide un sistema, un dato o una persona que el lector pueda
no tener. Las versiones están fijadas en la §9, los datos los generan los scripts de `src/`, y el
dominio es ficticio y completo.

### 0.1 Lo que esto cambió, y por qué se anota

Las convenciones de nombre y de tags de este curso —`NN-tema.md` para el camino base,
`<tt>NN-<slug>.md` para los complementos `ia` y `ds`, `opNNN-<tt>NN-<slug>.md` para la carta— se
redactaron originalmente como **divergencias declaradas** respecto de una convención de más
arriba. Al hacerse autocontenido el curso, esa forma dejó de tener sentido: **son, simplemente,
las convenciones del curso**, y están definidas en la guía de estilo §8.2 sin referencia a nada
externo.

Lo que se conserva de aquella redacción es lo único que valía: **el argumento**. Por qué el camino
base se lista contiguo, por qué los complementos no llevan `op`, y qué cuesta tener tres
convenciones en vez de una. Un argumento sigue siendo útil aunque ya no haya nada contra lo que
argumentar; una referencia a un archivo que no está en la carpeta, no.

---

## 1. En una frase

Un curso práctico que enseña a un desarrollador Java senior a **elegir el registro correcto
de Python** —script, herramienta o aplicación— y a escribir cada uno como se escribe de
verdad, midiendo lo que gana y lo que pierde frente al stack que ya domina.

---

## 2. El problema que resuelve

El lector no necesita aprender a programar. Necesita **desaprender un reflejo**.

> 🧭 **La pregunta que ordena todo el curso: ¿esto es un script, una herramienta o una
> aplicación?**

Un senior de Java construye una aplicación para todo. Le pides convertir cuatrocientos CSV y
entrega un proyecto Maven con interfaces, capas, inyección de dependencias y un
`Application.java`. Python tiene tres registros de escritura reales y distintos, y este
perfil escribe siempre en el tercero —pagando una ceremonia que no necesita— o, cuando por
fin escribe un script de verdad, **no sabe reconocer el momento en que ese script dejó de
serlo** y merece paquete, tipos, pruebas y distribución.

Los dos fracasos son simétricos y los dos son caros. El curso se organiza para provocarlos a
propósito y después cobrarlos con números.

El veredicto honesto de cierre se escribe solo: **cuándo tu script debía quedarse en cuarenta
líneas, cuándo debía ser un paquete, y cuándo debiste escribirlo en Java.**

---

## 3. Objetivo pedagógico

Al terminar, el lector puede:

- Mirar un encargo y decidir **en qué registro se escribe**, y defender la decisión con el
  costo de las otras dos opciones.
- Escribir Python de stdlib pura que resuelve trabajo real sin instalar nada, y saber cuánto
  viene en la caja.
- Reconocer el momento exacto en que un script merece `pyproject.toml`, tipos, pruebas y una
  forma de distribuirse — y ejecutar esa migración sin reescribir desde cero.
- Leer y escribir Python idiomático: iteradores, generadores, `dataclasses`, `Protocol`,
  context managers, EAFP — y reconocer dónde su instinto de Java produce código que funciona
  pero que nadie en ese ecosistema escribiría.
- Construir y operar una aplicación real: API, persistencia, concurrencia, lotes,
  observabilidad y contenedor.
- **Medir** en vez de opinar: rendimiento, arranque en frío, costo y latencia, con un arnés
  consistente.
- Decir con datos delante cuándo Python no era la respuesta.

Lo que **NO** es objetivo: formar científicos de datos, enseñar teoría de aprendizaje
automático, ni convencer a nadie de abandonar la JVM.

---

## 4. Perfil del lector

Un desarrollador **Java senior**, con ocho o más años de oficio. Domina orientación a
objetos, concurrencia, SQL, HTTP, pruebas, build, contenedores y despliegue. Ha leído
documentación técnica toda su vida y sabe resolver un problema mirando un ejemplo de código.

De eso se derivan dos reglas que atraviesan todo el material y que lo separan de un tutorial
de Python normal:

> 🧭 **No se explica lo que ya sabe.** Nada de qué es una función, un bucle, una excepción,
> una petición HTTP o una transacción. Cada párrafo que explique eso se borra, aunque esté
> bien escrito.
>
> 🧭 **La dificultad no se baja.** El lector resuelve leyendo documentación y ejemplos. Los
> ejercicios y los miniproyectos se calibran para alguien así: si un miniproyecto se puede
> terminar copiando el código de la fase, está mal diseñado.

El salto conceptual real está en cinco puntos, y ahí se gasta el espacio: **el modelo de
datos de Python** (todo es objeto, mutabilidad, identidad ⇄ igualdad), **los tres registros y
la frontera entre ellos**, **el ecosistema de empaquetado y entornos**, **el tipado gradual y
por qué no es el tipado del compilador que conoce**, y **la concurrencia con GIL y sin él**.

---

## 5. El dominio: Áurea · Escultores de Sonrisas

El curso construye software para una empresa ficticia: **Áurea**, una red odontológica
colombiana de diez sedes —cuatro propias y seis franquiciadas— con 2.800 pacientes activos en
ortodoncia, un producto insignia llamado **Arquitectura de Sonrisa** y una red de veintitrés
odontólogos aliados.

La historia completa vive en **[`00-historia-de-aurea.md`](../00-historia-de-aurea.md)**
y es fuente de verdad para todo lo narrativo: personajes, cifras, cronología y reglas de
negocio. Ninguna fase la contradice y ninguna fase la amplía por su cuenta.

Tres propiedades de Áurea la hacen buena materia, y conviene tenerlas presentes al escribir:

- **El lector es el único ingeniero.** No hay arquitecto, ni revisor, ni equipo de frontend,
  ni quien reciba el turno. Eso hace que "no construyas esto" sea una respuesta legítima y
  frecuente, cosa que un escenario corporativo no permite.
- **La usuaria real no es ingeniera.** Patricia, la administradora, escribió seiscientas
  líneas de VBA sin que nadie se lo pidiera. Todo lo que el curso entregue tiene que poder
  abrirse y modificarse sin llamar al autor.
- **Hay una frontera legal que no se cruza.** La historia clínica es reservada, con auditoría
  de accesos obligatoria y régimen de habeas data. Eso obliga a decisiones de diseño reales
  desde el primer modelo, en vez de a un CRUD de juguete.

> 🪦 **Decisión cerrada: la empresa es Áurea**, y es la única. Durante la discusión de fases se
> evaluó una segunda empresa ficticia —una casa editorial— y se descartó: el dominio odontológico
> gana por la frontera legal de la historia clínica, que obliga a decisiones de diseño reales en
> vez de a un CRUD de juguete. El documento de aquella alternativa **ya no vive en esta carpeta**,
> por la §0: material que el curso no usa y que no se cita desde ninguna fase es peso muerto que
> alguien va a leer por error.

---

## 6. La regla de forma que define este curso: **no hay apéndices**

Decisión cerrada, y la regla de forma más visible del curso.

Lo habitual en un curso técnico es que el material de consulta —el ambiente, las herramientas, el
puente entre versiones— viva en apéndices `aNN-`. **Aquí no.** Todo lo que en otro curso sería un
apéndice es, en este, **una fase o una sección de una fase**.

Las razones son tres y las tres son de este curso en particular:

- **El lector no necesita material de consulta de nivel básico.** Los apéndices de un curso de
  Angular existen para el backend que nunca tocó RxJS. Aquí el equivalente no existe: quien
  necesite la API de `pathlib` la lee en la documentación oficial, y el curso enlaza en vez de
  transcribir.
- **Un apéndice de herramientas envejece peor que una fase.** El ecosistema de empaquetado de
  Python se mueve; un apéndice "de entornos" separado del contenido se desactualiza en
  silencio y nadie lo nota. Dentro de una fase, con su miniproyecto, el desfase se ve al
  primer intento de ejecución.
- **El apéndice es donde se esconde lo que no supimos ubicar.** Sin esa válvula de escape,
  cada tema tiene que ganarse un lugar en la secuencia o quedarse fuera con su razón escrita.

> 🧭 **Corolario operativo:** cuando al escribir una fase aparezca material que "sería un buen
> apéndice", hay exactamente tres destinos legítimos: una sección de esa fase, una fase
> propia, o el registro 📌 de pendientes con su razón. Nunca un archivo `aNN-`.

El ambiente de trabajo —intérprete, `pip`, `venv`, VS Code y PyCharm— es el ejemplo
mayor de esta regla: **es la Fase 00 completa**, no un apéndice de setup.

---

## 7. Lo que está dentro del alcance

- El **camino base obligatorio**, con sus tres bloques: un archivo y stdlib pura, la frontera
  de script a proyecto, y aplicaciones y ecosistema.
- **Un miniproyecto por fase**, obligatorio, difícil y anclado al dominio de Áurea. Es el
  mecanismo principal de consolidación del curso: para este perfil, la unidad de práctica útil es
  un encargo completo y no un ejercicio de rellenar huecos. Su formato está en
  [`formato-de-miniproyectos.md`](formato-de-miniproyectos.md).
- Los **cuatro proyectos empresariales** que atraviesan el curso, cada uno en un registro
  distinto, y que nacen y crecen a lo largo de las fases en vez de aparecer al final.
- Las **mediciones**: todo "es más rápido", "arranca antes" o "cuesta menos" se sostiene con
  un número producido por el arnés del curso.
- El **duelo final** contra el stack de origen, implementando el mismo servicio dos veces.
- Los **complementos `ia` y `ds`**: diecisiete secciones que construyen los cuatro proyectos de
  IA y de datos de Áurea —NormaRAG, Recepción asistida, Embudo y Ausentismo— sobre el código que
  dejó el camino base. Se leen después de las 18 fases, heredan la plantilla de 10 secciones con
  su medición y su miniproyecto, y se nombran `iaNN-<slug>.md` / `dsNN-<slug>.md`
  (`propuestas-fases-base-ia-datos.md` §0).
- Los **tracks opcionales a la carta**, declarados fuera del camino base, con el prefijo
  `opNNN-<tt>NN-` (guía de estilo §8.2).

---

## 8. Lo que está fuera del alcance

- **Enseñar a programar.** Sintaxis básica, estructuras de control y tipos primitivos se dan
  por sabidos; solo entra lo que difiere de Java de forma que produzca un error.
- **Teoría de aprendizaje automático y de IA.** Aquí entra la IA y la ciencia de datos
  **aplicadas**, como complementos `ia` y `ds` que resuelven problemas de
  Áurea con las bibliotecas del ecosistema; la teoría —cómo se deriva un gradiente, por qué
  converge un optimizador— se enlaza y se declara excluida. La frontera práctica: el curso enseña
  a *usar y medir* un modelo, y a decidir si valía la pena; no a inventarlo.
- **Cómputo científico pesado y GPU.** Fuera del perfil del lector. `ds08` entrena en CPU, en
  minutos, y esa restricción es parte del encargo.
- **Apéndices de cualquier clase** (§6).
- **Un repositorio de partida.** El curso construye su código desde cero, por una razón concreta:
  quien lee código ajeno no distingue una decisión de un accidente.

Si algo interesante aparece fuera de alcance, se registra como **pendiente 📌** con su destino
sugerido. No se infla la fase actual.

---

## 9. Restricciones de versiones

El curso es **autocontenido**: no depende de ningún `requirements.txt` externo y no verifica
nada contra un sistema que el lector no tenga.

| Herramienta | Versión | Dónde vive |
|---|---|---|
| Python | **3.14.7** (piso soportado: 3.13.15) | Fase 00 · todo el curso |
| Gestión de entorno, Bloque A | `venv` + `pip` **26.2.1** de la biblioteca estándar | Fase 00 |
| Gestión de entorno, Bloques B y C | **`uv` 0.12.13** | Fase 07 en adelante |
| Comparados contra `uv` en la frontera | `pip-tools` **7.6.1** y **Miniforge 26.7.2-0** (`conda-forge`) | Fase 07, medidos |
| Formato y lint | `ruff` **0.16.7** | Fase 00 · transversal |
| Tipado | `mypy` **2.3.1** (alternativa: `pyright` **1.1.414**) en modo estricto | Fase 08 |
| Pruebas | `pytest` **9.1.1**, `pytest-cov` **7.1.0**, `hypothesis` **6.168.0** | Fase 08 · transversal |
| Backend de empaquetado | `hatchling` **1.32.0** | Fase 07 en adelante |
| Distribución | `PyInstaller` **6.22.3** · `zipapp` (biblioteca estándar) · `uv tool` | Fase 09 |
| Editor principal | VS Code + extensión oficial de Python | Fase 00 |
| Editor alternativo | **PyCharm 2026.2.2**, capa gratuita | Fase 00 |

**Dependencias del Bloque C**, fijadas aquí antes de usarse:

| Herramienta | Versión | Dónde vive |
|---|---|---|
| FastAPI · Pydantic · Uvicorn | **0.141.1** · **2.13.5** · **0.52.4** | Fase 10 en adelante |
| SQLAlchemy · Alembic · psycopg | **2.0.52** · **1.20.0** · **3.3.5** | Fase 11 en adelante |
| Django | **6.1.1** | Fase 12 |
| httpx | **0.28.1** | Fase 13 |
| Celery · arq · redis-py | **5.6.3** · **0.28.0** · **8.1.0** | Fase 15 |
| structlog · prometheus-client · OpenTelemetry SDK | **26.1.0** · **0.26.0** · **1.44.0** | Fase 16 |

**Dependencias de los complementos `ia` y `ds`**, fijadas antes de usarse:

| Herramienta | Versión | Dónde vive |
|---|---|---|
| SDK de Claude · `anthropic` | **1.5.0** | `ia01` en adelante |
| Modelo por defecto del track | **Claude Opus 5** (`claude-opus-5`) · 1M de contexto · USD 5 / 25 por millón de tokens de entrada / salida | `ia01` en adelante |
| Modelo barato para tandas y jueces | **Claude Haiku 4.5** (`claude-haiku-4-5`) · 200K · USD 1 / 5 | `ia04`, `ia06` |
| Modelo local, para lo que no debe costar dinero ni salir de la máquina | **Ollama 0.6.2** (cliente de Python) | `ia01` en adelante |
| Reintentos y backoff | `tenacity` **9.1.4** | `ia02` |
| Vectores en Postgres | `pgvector` **0.5.0** (sobre PostgreSQL 18.0, el de la Fase 11) | `ia04`, `ia05` |
| Modelo de embeddings, **local** | `sentence-transformers` **6.0.1** con `paraphrase-multilingual-MiniLM-L12-v2` (384 dimensiones) | `ia04`, `ia05` |
| Lectura de PDF del corpus | `pypdf` **6.18.1** | `ia05` |
| Cálculo vectorizado | `numpy` **2.5.3** | `ds01` en adelante |
| DataFrames | `pandas` **3.0.5** · `polars` **1.44.2** · `pyarrow` **25.0.1** | `ds02`, `ds03` |
| SQL analítico sobre archivos | `duckdb` **1.5.5** | `ds03` |
| Gráficos | `matplotlib` **3.11.2** · `plotly` **7.0.0** · `altair` **6.2.2** | `ds05` |
| Cuadernos | `jupyterlab` **4.6.3** · `marimo` **0.24.2** · `papermill` **2.7.0** | `ds06` |
| Modelos clásicos | `scikit-learn` **1.9.1** · `statsmodels` **0.15.0** | `ds07` |
| Redes neuronales | `torch` **2.14.0** (CPU) | `ds08` |
| Servir el modelo | `onnx` **1.22.0** · `onnxruntime` **1.30.0** · `skl2onnx` **1.20.0** | `ds09` |
| Frameworks comparados (solo en la medición) | `langchain` **1.4.0** con `langchain-anthropic` **1.7.2** · `llama-index` **0.14.24** · `pydantic-ai` **2.43.0** | `ia08` |

> 📅 **Fecha de verificación de esta segunda tabla: 13 de septiembre de 2026**, consultada contra
> PyPI. Los identificadores de modelo y sus precios se consultaron el mismo día contra la
> documentación oficial de la API de Claude. Ninguno está puesto de memoria, y el precio se
> reverifica antes de cualquier medición de costo: es el número que más rápido envejece de todo
> el curso.

> ⚠️ **El modelo de embeddings es local, y eso es una decisión con costo declarado.** Un modelo
> alojado de última generación probablemente recupere mejor, y el curso **no lo mide** porque no lo
> usa. Se elige el local por dos razones: es la única vía compatible con la frontera clínica de la
> §5 de la historia de Áurea, y el curso tiene que poder tomarse entero sin gastar dinero —embeber
> veinte mil fragmentos con una API cuesta—. La omisión se declara en la medición de `ia04` en vez
> de esconderse.

> 📝 **Sobre los tres frameworks.** Entran **solo como competidores medidos** en `ia08` §6.2; el
> curso no construye con ellos. Dos datos que se registran al fijarlos, y que valen tanto como el
> número de versión: `llama-index` sigue en `0.x` después de años, y `pydantic-ai` publicó su
> versión el día antes de la verificación. Ninguno de los dos es una descalificación — son entradas
> en la decisión de qué le toca mantener a quien reemplace al lector.

> ⚠️ **`rank-bm25` no entra.** Su última publicación es de febrero de 2022 y el curso no enseña
> bibliotecas abandonadas. El competidor léxico de `ia04` es la **búsqueda de texto completo de
> PostgreSQL** —`tsvector`, `ts_rank`, `pg_trgm`—, que ya está en el stack desde la Fase 11, no
> agrega dependencia y es exactamente lo que alguien defendería en una revisión de código.

> 🪦 **Sobre el nombre de PyCharm.** Hasta 2025.2 el curso habría dicho *PyCharm Community
> Edition*. JetBrains descontinuó esa edición en 2025.3 y unificó el producto: hoy hay **un solo
> PyCharm** con una capa gratuita y una suscripción Pro. El curso usa la capa gratuita y declara
> en la Fase 00 qué queda del otro lado —frameworks web, herramientas de base de datos, cliente
> HTTP, desarrollo remoto y perfilador—, nada de lo cual hace falta para el camino base.

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

---

## 10. Entornos de desarrollo

**Windows 11, Linux amd64 y macOS Apple Silicon son los tres entornos soportados**, y los tres
se cubren en la Fase 00 sin nota al pie: el lector trabaja en alguno de ellos y no debería
tener que adivinar cuál asume el texto.

Donde una instrucción difiera entre plataformas, se dan las tres, en ese orden y sin
condescendencia: `py -m venv` en Windows, `python3 -m venv` en el resto, y la ruta del
activador que cada shell espera.

---

## 11. El eje que ordena el final del curso

El curso cierra con el **veredicto**: dónde Python no era la respuesta. No es un gesto de
humildad — es el contenido. Un lector que sale sabiendo elegir entre tres registros pero
incapaz de decir "esto debió quedarse en Java" no aprendió a decidir, aprendió a preferir.

Por eso el servicio central se implementa **dos veces**, y por eso cada medición del curso
incluye al stack de origen como competidor de verdad, no como espantapájaros.

---

## 12. Criterios de éxito

El curso funciona si quien lo termina puede:

1. Recibir un encargo y decidir el registro, con el costo de las alternativas.
2. Escribir un script de stdlib pura que resuelve trabajo real, y saber cuándo dejó de serlo.
3. Migrar ese script a proyecto sin reescribirlo.
4. Construir y operar una aplicación completa, con pruebas y contenedor.
5. Medir su propio código y el del competidor con el mismo arnés.
6. Terminar cada fase con su miniproyecto funcionando, sin haber copiado el código de la fase.
7. Nombrar dos decisiones del curso que, con los datos delante, debieron ser otras.

---

## 13. Decisiones cerradas

- 🪦 **Sin apéndices.** Todo es fase o sección de fase (§6).
- 🪦 **Un miniproyecto obligatorio por fase**, difícil, anclado a Áurea, con criterios de
  aceptación verificables.
- 🪦 **La Fase 00 es el ambiente completo**: intérprete, `venv`, `pip`, VS Code con sus
  extensiones y PyCharm en su capa gratuita, en las tres plataformas.
- 🪦 **El arco de gestores es de tres tiempos, y cada herramienta entra cuando el lector ya
  sintió el dolor que resuelve.** `venv` + `pip` a mano en la Fase 00, por el mecanismo; la
  comparación medida de `pip-tools`, `uv` y Miniforge en la Fase 07, provocada por un encargo
  real; y **`uv` como gestor del curso** de ahí en adelante. **conda se gana su lugar en el
  track de datos e IA**, donde el problema binario es genuino, no antes. Poetry, PDM y el resto
  del panorama viven en el track opcional `pk`.
- 🪦 **El duelo final se mide contra Spring Boot 3**, y contra nada más. Un solo endpoint,
  implementado dos veces, con el mismo arnés.
- 🪦 **La empresa es Áurea**, con la historia de `00-historia-de-aurea.md` como fuente.
- 🪦 **Código en inglés, comentarios y narrativa en español.** Guía de estilo §5.
- 🪦 **Todo "mejor que" lleva número.** Sin benchmark, no se afirma.
- 🪦 **Diagramas en Mermaid** (`D-12` de los lineamientos del repositorio), decidido por el autor el
  05/10/2026; árboles de archivos, datos y salidas siguen en `text`. Las excepciones del curso a
  esos lineamientos están en la guía §15.
- 🪦 **Los complementos `ia` y `ds` son parte del curso, no de la carta.** Diecisiete secciones,
  con la misma plantilla, la misma medición y el mismo miniproyecto que una fase base, sobre los
  cuatro proyectos de IA y datos de Áurea. Nombre y tags en `propuestas-fases-base-ia-datos.md`
  §0; el proveedor de LLM es la API de Claude y la alternativa local es Ollama.

Lo que sigue abierto es la **secuencia de fases**, y es exactamente la conversación que abre
[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md).
