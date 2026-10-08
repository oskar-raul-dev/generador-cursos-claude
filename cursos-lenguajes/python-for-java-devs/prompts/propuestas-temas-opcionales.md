# 🧩 Propuesta de temas opcionales

> Curso *Python para desarrolladores Java senior*. Estado: **propuesta en discusión**.
> El camino base y los tracks de IA y datos viven en `propuestas-fases-base-ia-datos.md`.
>
> ⚠️ **Los tracks `ia` y `ds` salieron de este documento el 13/09/2026.** Dejaron de ser platos
> de la carta: son **complementos del camino base**, construyen los cuatro proyectos de IA y datos
> de Áurea, y se nombran `iaNN-<slug>.md` / `dsNN-<slug>.md` con tags `ia-fase-NN` / `ds-fase-NN`.
> La decisión, con su tabla comparativa, está en `propuestas-fases-base-ia-datos.md` **§0**. Nada
> de lo que este documento dice sobre `opNNN-` les aplica.
>
> **Estado del camino base: escrito.** Las 18 fases —numeradas 00 a 17—, `BENCHMARKS.md` e
> `INSTINTOS.md` están publicados. Este documento es el inventario del material que viene
> **después**.

## 🍽️ Qué es esto: material **a la carta**

Y conviene decirlo antes que nada, porque cambia el criterio con el que se lee todo lo demás.

**El camino base es un curso: se recorre en orden, de la Fase 00 a la 17, y cada fase depende de
la anterior.** Esto no. Esto es una **carta**: secciones **totalmente opcionales**, que se leen
sueltas, cuando el lector necesita un tutorial concreto de una herramienta y quiere un ejemplo que
corra y un ejercicio que lo fije.

De ahí salen cuatro consecuencias, y las cuatro son distintas del camino base:

- **No hay tope de tamaño.** Cien secciones están bien. Doscientas también. Una carta larga no es
  un problema: es una carta larga. Lo que sí sería un problema es una sección que no se pueda leer
  sola.
- **Cada sección se sostiene por sí misma.** No se asume que el lector hizo la anterior del mismo
  track. El orden dentro de un track es una **sugerencia de lectura**, no una dependencia.
- **No todo tiene que pasar por Áurea.** El camino base construye software para una empresa
  ficticia y esa disciplina es lo que lo hace defendible. Aquí, en cambio, el objetivo es **dar el
  sabor de una capacidad de Python** con un ejemplo concreto: si el ejemplo natural de `turtle` es
  dibujar una espiral, se dibuja una espiral, y nadie tiene que inventar por qué una clínica
  odontológica necesita tortugas.
- **Y por eso Áurea decide la prioridad, no la admisión.** Lo que encaja con el dominio se escribe
  primero, porque le sirve al lector el lunes y porque hereda un contexto ya montado. Lo demás se
  escribe al final, y se escribe igual de bien.

> 🧭 **La regla de forma de una sección a la carta:** un ejemplo que corre, un ejercicio concreto,
> y la honestidad de siempre —si hay una afirmación comparativa, lleva su número; si una biblioteca
> está abandonada, se dice—. **Lo que no se le exige es miniproyecto ni medición obligatoria**: eso
> es del camino base, donde hay un sistema que construir. Aquí el entregable es que el lector
> entienda de qué es capaz la herramienta y sepa si le sirve.

⚠️ **El riesgo de este formato, declarado:** una carta de doscientas secciones sueltas es un
catálogo, y un catálogo envejece y no enseña. Lo que lo salva es que cada sección responda a *qué
problema resuelve esta herramienta y cuándo no usarla* — que es el criterio del curso entero,
aplicado a una pieza pequeña.

**Qué cambia en esta revisión** —tres cosas, y las tres afectan a todo lo anterior:

1. **Los archivos se llaman distinto.** Todo lo opcional pasa a `opNNN-<tt>NN-<slug>.md`
   —`op014-ui02-gradio.md`— para que el material opcional quede en **un solo bloque** detrás del
   camino base, **ordenado por el número global de tres dígitos** en vez de por el azar alfabético
   de sus dos letras. Es una de las tres convenciones de nombre del curso —guía de estilo §8.2— y
   va argumentada en la §2.
2. **Nueve tracks nuevos**, todos elegidos por el mismo criterio: **el registro en el que Python
   es el pegamento correcto** —orquestación, frontera nativa, protocolos, formatos de legado,
   seguridad, observabilidad, optimización, geoespacial y sistema operativo—. Van en la §17, con
   la recomendación de qué recortar a cambio, porque veinticinco tracks no se escriben.
3. **Se retiran las bibliotecas abandonadas.** Las versiones anteriores proponían enseñar
   `ffmpeg-python`, `pysftp`, `face_recognition`, GINO y `svgwrite` *como lección* sobre mirar la
   fecha de la última publicación. La lección se queda —vive en la Fase 00 del camino base—, pero
   los muertos salen del temario y se van a la §18.

---

## 1. El criterio: qué es núcleo, qué es carta, y en qué orden se escribe

Hay **dos** criterios distintos y conviene no confundirlos, porque la versión anterior de este
documento los mezclaba y eso descartaba temas que no había por qué descartar.

**El primero decide qué entra al camino base.** Cuatro preguntas, y basta que falle la primera
para que el tema salga del curso obligatorio:

1. **¿Enseña un modelo que el lector no tiene, o es una API que puede leer bajo demanda?**
   Pillow es una API. Los generadores son un modelo.
2. **¿El lector lo hará mal por defecto, arrastrando su reflejo de Java?** Si su instinto ya
   funciona, es referencia, no lección.
3. **¿Alimenta a un proyecto del curso?** Si no alimenta después a un servicio, no es del camino
   base. *(Ojo: eso lo saca del curso obligatorio, **no** lo descalifica para la carta — es la
   confusión que la versión anterior de este documento cometía.)*
4. **¿Se puede enseñar como modelo de acceso en vez de como producto?** Es el principio rector del
   repositorio, y es el que decide si un tema con nombre comercial merece una **fase del camino
   base**: *Cassandra* es un producto; *"columnar ancho, sin joins, modelado por consulta"* es un
   modelo. En la carta esta pregunta se relaja, y la §6 explica en qué se convierte.

**El segundo criterio decide el orden en que se escribe la carta**, y no es el mismo. Una vez que
un tema está fuera del camino base ya no hay nada que "aprobar": si alguien quiere saber cómo se
dibuja con `turtle` o cómo se le habla a Cassandra desde Python, esa sección tiene derecho a
existir. Lo único que se decide es **cuándo se escribe**, y ahí manda una sola pregunta:

> 🧭 **¿Le sirve a Áurea?** Si el tema tiene un encargo creíble en el dominio del curso, se escribe
> primero: el lector lo va a usar el lunes, y la sección hereda un contexto ya montado que no hay
> que inventar. Si no lo tiene, se escribe igual — al final, con su propio ejemplo, y sin forzar a
> una clínica odontológica a necesitar algo que no necesita.

**Y un desempate de segundo orden:** entre dos temas que Áurea no usa, va antes el que recalibre un
reflejo de Java —los ORMs, los modelos de datos no relacionales, la concurrencia nativa— y después
el que solo enseñe una API que se puede leer bajo demanda.

Los temas de la carta se agrupan en **tracks con tesis propia**, cada uno con su token de dos
letras y su espacio de tags. El agrupamiento sirve para orientarse; **la unidad real es la sección
suelta**, que es como se va a leer. La forma exacta de los nombres —y por qué diverge de la
convenciones de nombre del curso— está en la §2, y su definición en la guía de estilo §8.2.

> ⚠️ **Y una regla que este documento aprendió del camino base:** una sección que sea un **desfile
> de bibliotecas** no vale nada. Cuando abajo aparezca una lista larga de nombres, es **inventario
> del terreno, no el índice del capítulo**: la sección elige una o dos, las hace correr, y enlaza
> el resto. Un catálogo se puede buscar solo; lo que el lector no puede buscar solo es *cuál de
> estas sirve para lo suyo y cuándo no usarla*.

### 1.1 🪦 Las dos decisiones que este documento revierte

Se dejan escritas porque estaban descartadas en la versión anterior y ahora entran:

**Cassandra y el resto de los modelos no relacionales entran**, reformulados. La versión anterior
los descartó por "enseñanza de producto con poco contenido específico de Python", y ese argumento
era correcto **para esa formulación**. Organizados por **modelo de acceso** —documental, clave-valor,
columnar ancho, grafo, serie de tiempo, vectorial— dejan de ser catálogo y pasan a ser exactamente
la pregunta que ordena el repositorio. Ver §6.

**El correo entra, y con él las comunicaciones.** Estaba como "🔴 desafío de cierre de `au06`", y
se queda corto: el correo con adjuntos, IMAP, rebotes y la lista de bloqueo es un problema real de
Áurea —Patricia manda las liquidaciones por correo todos los meses— y da para más que un
ejercicio. Ver §10.

---

## 2. 🔤 La nomenclatura: `opNNN-<tt>NN-<slug>.md`

> **Decisión tomada.** Cierra la pregunta que la versión anterior dejaba abierta sobre los
> prefijos, y cambia el nombre de todos los archivos que este documento propone.

El problema no se ve hasta que hay archivos en el disco. Con prefijos sueltos —`ui01-`, `ar01-`,
`db01-`, `cl01-`— el directorio del curso queda así al listarlo:

```text
00-instalacion-ambiente-editores-y-ecosistema.md
01-modelo-de-datos.md
…
17-el-duelo-y-el-veredicto.md
ar01-binario-de-verdad.md          ← empieza el material opcional
au01-http-contra-sistemas-ajenos.md
co01-…                             ← y aquí ya se perdió el hilo
cl01-…
co01-…
db01-…
```

Dieciséis tracks, dieciséis prefijos, y **ninguna forma de ver de un vistazo dónde termina el
camino base y empieza lo opcional**. Peor: los tracks quedan ordenados por el azar de sus dos
letras, así que `cl` (terminal y TUI) cae entre `au` y `co` sin ninguna razón.

La convención que este documento adopta lo arregla entero, y añade lo que una **carta** necesita
y un conjunto de tracks sueltos no da: **un número de plato**.

```text
op<NNN>-<tt><NN>-<slug>.md
 │  │      │   │     └── el tema, en español, minúsculas, con guiones
 │  │      │   └──────── dos dígitos dentro del track, desde 01
 │  │      └──────────── las dos letras del track: ui, ar, db, wf…
 │  └─────────────────── tres dígitos: el número de la sección en la carta completa
 └────────────────────── literal, siempre, para todo lo opcional
```

**El número de tres dígitos es el orden de la carta**, y se asigna **en el orden en que las
secciones se escriben**, no por track. Así `op001-` es la primera sección que existió, y una
sección nueva de cualquier track se numera con el siguiente libre. Tres dígitos dan **hasta 999
secciones**, que es holgura de sobra para una carta que puede crecer indefinidamente.

Y el listado pasa a ser este:

| Archivo | Qué es |
|---|---|
| `00-instalacion-ambiente-editores-y-ecosistema.md` … `17-el-duelo-y-el-veredicto.md` | El camino base, intacto y contiguo |
| `op001-db01-el-panorama-y-el-db-api.md` | La primera sección de la carta que se escribió |
| `op002-db02-postgres-desde-python.md` | La segunda |
| `op014-ui02-gradio.md` | La sección suelta que el lector busca por nombre |
| `op057-ed01-turtle.md` | Una de las últimas: sin encargo de Áurea, y escrita igual |

**Cuatro propiedades que se ganan y que justifican el cambio:**

- **Un solo bloque.** Todo lo opcional queda contiguo y *después* del camino base, porque `0`–`9`
  ordenan antes que cualquier letra. El curso obligatorio se lee de arriba abajo sin ruido.
- **El orden del listado es el orden de la carta**, y no el azar alfabético de dos letras. `ls
  op*` devuelve las secciones en el orden en que se publicaron, que para material a la carta es
  más útil que agruparlas por track — el lector que vuelve quiere ver **qué hay de nuevo**.
- **El track sigue siendo filtrable.** `ls op*-db*` es el track de datos completo, esté donde esté
  su numeración global; `ls op*-*01-*` es la primera sección de cada track, que es lo que mira
  quien busca por dónde entrar.
- **Y el filtro grueso es trivial en todas partes.** `op*` en `ls`, en `git tag -l`, en un
  `.gitignore` de borrador, en la barra del editor y en el índice del `README`.

⚠️ **El costo, dicho entero:** el número global **no se puede deducir** del track ni del tema — hay
que consultarlo antes de crear un archivo, y si dos secciones se escriben en paralelo hay que
desempatar a mano. Es el precio de tener orden de publicación en el nombre. La alternativa
—numerar por track y ordenar alfabéticamente— no tiene ese costo y pierde lo que la carta
necesita. **Se acepta el costo, y la mitigación es un renglón en este documento:** la siguiente
sección libre es la **`op001`**, porque todavía no se ha escrito ninguna.

### 2.1 Lo que arrastra el cambio

**El código.** Cada sección con código usa el mismo nombre que su documento, como en el camino
base: `src/op014-ui02-gradio/`, `src/op001-db01-el-panorama-y-el-db-api/`. La regla del
repositorio —el directorio se llama exactamente como el archivo que lo acompaña— se mantiene.

**Los tags de git.** El camino base usa `fase-NN` y `mini-NN`. Lo opcional lleva su track y su
`op-` delante, **sin el número global**: el tag identifica la sección dentro de su track, que es
como se la nombra en prosa.

```bash
git tag -a op-ui-fase-02 -m "op ui02 cerrada: …"
```

Con eso, `git tag -l 'fase-*'` sigue siendo el índice limpio del camino base —que es la propiedad
que estas convenciones existen para conservar—, `git tag -l 'op-*'` es el índice de toda la carta,
y `git tag -l 'op-ui-*'` es un track.

> 📝 **Por qué el tag no lleva el número global** aunque el archivo sí: el número de la carta es un
> **orden de publicación**, y un tag es una **identidad**. Si algún día hay que reordenar la carta
> —fusionar dos secciones, insertar una— los archivos se renombran y los tags no deberían moverse.
> Separarlos evita ese acoplamiento.

**Los commits.** Mismo criterio, con el prefijo delante: `op ui02: …` para el cuerpo y
`op ui02 ej07: …` para ejercicios. **El `mini:` no aplica por defecto**: el miniproyecto es del
camino base, y una sección de la carta lo lleva solo si el tema lo pide.

**Los identificadores en prosa.** Dentro de este documento y de las tablas, una sección se sigue
nombrando `ui02`, `db06`, `wf03` — corto, legible y estable. **El `opNNN-` es del archivo**, no del
nombre de la sección; en el texto se escribe el nombre completo solo cuando se habla de archivos.
Esa separación es deliberada: el número de la carta puede cambiar y el identificador no.

### 2.2 El costo de esta convención, dicho entero

Los nombres se alargan seis caracteres, y el curso pasa a tener **tres** convenciones de nombre en
vez de una —camino base, complementos `ia`/`ds`, y esta—. La tabla completa de las tres está en la
guía de estilo §8.2, que es donde se definen.

Se acepta el costo porque las tres marcan tres clases de material distintas —obligatorio,
complementario y suelto— y colapsarlas en una habría borrado justo esa distinción. Y porque un
prefijo por track, con veinte tracks proyectados, deja de separar y empieza a mezclar: `ar01-`,
`cl01-` y `db01-` se intercalan por el azar alfabético de sus dos letras y el bloque opcional deja
de ser un bloque.

⚠️ **El costo que no se puede mitigar:** el número global **no se deduce** del track ni del tema.
Hay que consultarlo antes de crear un archivo, y si dos secciones se escriben en paralelo hay que
desempatar a mano. Es el precio de tener orden de publicación en el nombre, y la mitigación es un
renglón en este documento: la siguiente sección libre es la **`op001`**, porque todavía no se ha
escrito ninguna.

> 🪦 **Alcance del cambio, corregido el 13/09/2026.** Esta nota decía que la convención `opNNN-`
> se aplicaba también a los dos tracks de
> [`propuestas-fases-base-ia-datos.md`](propuestas-fases-base-ia-datos.md), con nombres
> `op031-ia01-…` / `op042-cd01-…`. **Ya no.** Esos dos tracks no son opcionales por la misma
> definición: construyen los cuatro proyectos de IA y datos de Áurea sobre el código del camino
> base, con su medición y su miniproyecto, así que llevan su propio prefijo —`ia01-…`,
> `ds01-…`— y sus propios tags. El razonamiento completo está en la §0 de aquel documento. Lo que
> esta sección decide sigue valiendo **para la carta y solo para la carta**.

---

## 3. Track `ui` — Interfaces y entregables sin frontend

> **Tesis:** entregar resultados cuando no tienes equipo de frontend, y saber el precio que pagas
> por ello.

| Fase | Tema |
|---|---|
| ui01 | El modelo y su costo: qué es exactamente una UI generada desde el backend |
| ui02 | **Gradio**: el demo en veinte líneas, y por qué eso es su virtud y su límite |
| ui03 | **Streamlit** y su modelo de re-ejecución (que muerde) |
| ui04 | **Dash / Plotly** y los callbacks: el modelo reactivo |
| ui05 | **NiceGUI, Reflex, Shiny for Python, Panel, Flet** — comparados sobre la misma pantalla |
| ui06 | **marimo**: el notebook que es una app, y el problema del estado oculto que resuelve |
| ui07 | **Presentaciones programáticas**: `python-pptx`, Quarto/reveal.js, Marp, `manim` |
| ui08 | **Reportes**: Jinja2 → HTML → PDF con WeasyPrint, Excel con `xlsxwriter`, Great Tables |
| ui09 | **Escritorio**, si se decide incluirlo: PySide/Qt, Tkinter, Kivy, Toga/BeeWare, pywebview |
| ui10 | ⚖️ Veredicto: cuándo esto es un prototipo y cuándo debiste llamar a un frontend |

**Inventario del terreno** (para elegir, no para cubrir): Gradio · Streamlit · Dash · Panel ·
Shiny for Python · NiceGUI · Reflex · Flet · marimo · Voilà · Mesop · Taipy · ipywidgets ·
Anvil · Textual-web · Solara · FastHTML · `htpy` · HTMX servido desde FastAPI — que es la ruta que
más se parece a "no tener frontend" sin renunciar a HTML de verdad.

📝 **ui09 es la fase dudosa.** El escritorio no tiene demanda en el dominio de Áurea y arrastra
el problema de distribución de la Fase 09 multiplicado. Si el track se recorta, es la primera que
se cae — o se convierte en una sección de `ui01` que explica **por qué** casi nadie escribe
escritorio en Python hoy.

---

## 4. Track `ar` — Archivos y multimedia

> **Tesis:** pipelines de transformación de archivos, y cuándo Python es el pegamento correcto
> contra cuándo debe limitarse a invocar al binario que ya hace el trabajo.

| Fase | Tema |
|---|---|
| ar01 | Binario de verdad: `struct`, `mmap`, encodings, zip y tar |
| ar02 | **Pillow**: pipelines, thumbnails, EXIF, formatos |
| ar03 | **OpenCV, scikit-image** y generación programática (SVG, cairo) |
| ar04 | **PDF**: `pypdf`, `pdfplumber`, `pymupdf`, ReportLab, `pyhanko` para firmar, y OCR con `pytesseract` o `ocrmypdf` |
| ar05 | **Office**: `python-docx`, `openpyxl`, `python-pptx`, `xlsxwriter` |
| ar06 | Markdown, HTML y conversión universal con `pandoc` orquestado |
| ar07 | LaTeX y Typst |
| ar08 | EPUB |
| ar09 | **Vídeo**: `ffmpeg` orquestado, PyAV, MoviePy, extracción de cuadros, *keyframes*, vídeo desde imágenes |
| ar10 | **Audio**: `pydub`, `librosa`, `mutagen`, `soundfile`, `pedalboard`, y metadatos |
| ar11 | ⚖️ Veredicto: el pegamento contra el binario |

**Inventario de vídeo y audio** — y aquí hay una lección que el track tiene que dar de frente:

| Biblioteca | Qué es | Estado |
|---|---|---|
| **`ffmpeg` por `subprocess`** | Invocar el binario directamente (Fase 05 del camino base) | La opción que no se rompe |
| **PyAV** | Enlace real a las bibliotecas de FFmpeg; cuadro a cuadro | Activo |
| **MoviePy** | Edición declarativa: cortar, concatenar, superponer | Activo |
| `imageio` / `imageio-ffmpeg` | Leer y escribir secuencias de imágenes y vídeo | Activo |
| `vidgear` | Lectura acelerada, captura en vivo | Nicho, activo |

🧭 **`ar09` se escribe alrededor de una decisión, no de una biblioteca:** *envolver el binario o
llamarlo*. FFmpeg evoluciona rápido y su superficie de línea de comandos es enorme, así que
cualquier envoltorio que no esté financiado se queda atrás — y el cementerio de §21 tiene el
ejemplo. La fase mide las dos rutas sobre el mismo trabajo: `subprocess` contra el binario, y PyAV
cuando de verdad hace falta entrar cuadro a cuadro.

📝 **Nota de recorte (se mantiene):** EPUB estuvo propuesto como fase propia y se bajó — es un zip
con XHTML y un OPF. Puede terminar como 🔴 desafío de cierre de `ar06`.

---

## 5. Track `au` — Automatización externa

> **Tesis:** automatizar sistemas que no controlas, y el costo real de la fragilidad.

| Fase | Tema |
|---|---|
| au01 | HTTP contra sistemas ajenos: paginación, límites de tasa, autenticación |
| au02 | **Scraping** (`selectolax`, BeautifulSoup, `lxml`, Scrapy, `httpx`) y su fragilidad |
| au03 | **Playwright**: automatización de navegador — y los portales de las aseguradoras de Áurea |
| au04 | Pruebas e2e de web con Playwright + `pytest` *(candidata a mudarse a `qa`, ver §12)* |
| au05 | Sistemas remotos: SSH, **Paramiko**, Fabric, y la frontera honesta con Ansible |
| au06 | APIs de SaaS: GitHub, Jira, Slack, Google Workspace — y `authlib` para el OAuth de cada uno |
| au07 | Desplegar automatizaciones: `cron`, `systemd`, contenedor |
| au08 | ⚖️ Veredicto: la automatización que se rompe sola |

---

## 6. Track `db` — Hablarle a cada sistema de datos **desde Python**

> **Tesis:** **cómo se conecta, se consulta y se escribe desde Python en cada sistema concreto.**
> No es un curso de bases de datos ni un seminario sobre modelos de acceso: es el ejemplo que
> corre. Qué biblioteca se instala, cómo se abre la conexión, cómo se ve una consulta, qué devuelve
> y en qué tipos de Python, y cuál es la trampa que ese sistema tiene reservada para quien llega
> de Postgres.

Esto es lo que hace entrar a Cassandra y compañía (§1.1), y conviene decir con precisión **qué
clase de sección es** cada una, porque la versión anterior de este documento prometía otra cosa:

| Lo que **no** es | Lo que **sí** es |
|---|---|
| Enseñar Cassandra | Enseñar `cassandra-driver`: sesión, `prepare`, consistencia, `paging`, y qué te devuelve en tipos de Python |
| Un seminario sobre modelado de datos | Un ejemplo corriendo y un ejercicio, con la advertencia de qué se rompe si modelas como en Postgres |
| Elegir tu motor de producción | Saber qué se siente cada uno desde el código, para poder opinar con fundamento |

> 📝 **Qué pasó con el "modelo de acceso".** La versión anterior organizaba el track como un
> recorrido por modelos de acceso, y era una idea defendible — pero es **material del camino base**,
> no de la carta: ahí es donde se enseña a decidir. Aquí el lector ya decidió, o solo tiene
> curiosidad, y lo que necesita es **ver el código**. El modelo de acceso se menciona en una línea
> por sección, como contexto de por qué ese sistema se usa así; no es el contenido.

| Sección | Sistema | Desde Python con… | La trampa para quien viene de Postgres |
|---|---|---|---|
| db01 | **El panorama y el DB-API 2.0** | `sqlite3`, `psycopg` | Qué es un driver, qué te resuelve, y qué es `paramstyle` |
| db02 | **MySQL / MariaDB** | `mysqlclient`, `PyMySQL`, `asyncmy` | El modo estricto, la colación, y `utf8` que no es UTF-8 |
| db03 | **SQL Server y Oracle** | `pyodbc`, `pymssql`, `oracledb` | El driver del sistema operativo, y que `pyodbc` necesita algo instalado fuera de Python |
| db04 | **SQLite a fondo** | `sqlite3` de la caja | WAL, tipos dinámicos, y el bloqueo de escritor único (Fase 06 del camino base) |
| db05 | **DuckDB** | `duckdb` | Que consulta Parquet y CSV directamente, y que no es un reemplazo de Postgres |
| db06 | **Clave-valor: Valkey/Redis** | `redis-py` | Que todo es bytes, la caducidad, y que `KEYS` en producción es un incidente |
| db07 | **Documental: MongoDB** | `pymongo`, Beanie | Sin joins de verdad, el documento de 16 MB, y el índice que creías que existía |
| db08 | **Columnar ancho: Cassandra / ScyllaDB** | `cassandra-driver` | **Modelar por consulta**: sin joins, sin `ORDER BY` libre, y la clave de partición decide todo |
| db09 | **Grafo: Neo4j** | `neo4j`, `py2neo` | Cypher, y que el recorrido barato es el que el modelo previó |
| db10 | **Serie de tiempo: TimescaleDB e InfluxDB** | `psycopg` / `influxdb-client` | Ventanas, retención y *downsampling* como primitivas |
| db11 | **Vectorial: pgvector y Qdrant** | `pgvector`, `qdrant-client` | Similitud no es igualdad: el índice es aproximado y eso está bien |
| db12 | **Búsqueda: OpenSearch, Meilisearch, Typesense** | sus clientes | Análisis de texto, y que el índice es una estructura aparte que hay que alimentar |
| db13 | **Objetos: S3 / MinIO** | `boto3`, `fsspec` | Que no hay directorios, y que listar cuesta |
| db14 | **Bitácora de eventos: Kafka / NATS** | `confluent-kafka`, `nats-py` | El desplazamiento, los grupos de consumidores, y que "leer" no borra |
| db15 | ⚖️ Cierre: **el árbol de decisión**, y por qué Postgres gana casi siempre |

> 🧭 **Si de este track solo se escriben tres secciones**, que sean `db06` (Valkey), `db07`
> (MongoDB) y `db08` (Cassandra): las dos primeras porque Áurea las va a usar de verdad —caché y
> documentos—, y la tercera porque **modelar por consulta en vez de por entidad** es el único giro
> mental del track que un senior de Postgres no puede intuir.

> ⚖️ **Y el cierre tiene que ser incómodo:** Postgres hace hoy documental (`jsonb`), vectorial
> (pgvector), serie de tiempo (Timescale), búsqueda (`tsvector`) y cola (`SKIP LOCKED`)
> razonablemente bien. **La carta existe para que sepas qué se siente cada alternativa**, no para
> venderlas: si `db15` no dice que Postgres gana casi siempre, el track se convirtió en publicidad.

⚠️ **El problema práctico de este track, declarado:** catorce sistemas son **catorce servicios que
levantar**. La regla para que sea escribible: **todo corre en contenedores, con un
`compose.yaml` por sección y datos de ejemplo que caben en segundos**, o la sección no se escribe.
Lo que no se puede pedir es que el lector monte un clúster.

📝 **Cambio respecto a la versión anterior:** los ORMs salen de aquí y se van a su propio track
(§7) — son otra pregunta: no *cómo le hablo a este sistema*, sino *qué capa pongo encima*.

---

## 7. Track `or` — ORMs y acceso a datos desde Python

> **Tesis:** el camino base usa SQLAlchemy y explica que **Core y ORM son dos herramientas, no dos
> niveles de abstracción** (Fase 11). Este track es el resto del terreno: qué otros modelos de
> acceso a datos existen en Python, cuál se parece de verdad a Hibernate, y por qué la respuesta
> más frecuente sigue siendo "SQL, escrito por ti".

| Fase | Tema |
|---|---|
| or01 | **El eje que ordena el track**: mapeo de objetos ⇄ constructor de consultas ⇄ SQL con parámetros. Y dónde cae cada biblioteca |
| or02 | **SQLAlchemy a fondo**: lo que el camino base no cubrió — herencia, `hybrid_property`, eventos, tipos personalizados, `baked queries` |
| or03 | **Los ORM activos de registro**: Django ORM, **Peewee**, **Piccolo** — y el patrón *Active Record* contra *Data Mapper*, que es la diferencia real con Hibernate |
| or04 | **Pony ORM**: el que traduce **generadores de Python a SQL**, que no tiene equivalente en Java y es el más interesante del inventario |
| or05 | **Los asíncronos**: **Tortoise ORM**, **Ormar**, `SQLModel` — y el problema de que el ORM asíncrono complica lo que ya era difícil |
| or06 | **Sin ORM**: `aiosql`, PugSQL, `records`, `dataset`, **PyPika** y `sqlglot` como constructores, y el patrón de SQL en archivos `.sql` versionados |
| or07 | **Migraciones fuera de Alembic**: `yoyo-migrations`, `dbmate`, `sqlx`-style, y las del propio framework |
| or08 | ⚖️ Veredicto **medido**: la misma consulta del plan de tratamiento en seis bibliotecas — consultas emitidas, filas traídas, líneas escritas, y qué pasa al agregar una relación |

**Inventario del terreno, con su estado verificado** *(12 de septiembre de 2026)*:

| Biblioteca | Modelo | Última versión | Nota |
|---|---|---|---|
| **SQLAlchemy** | Data Mapper + Core | 2.0.52 | El del camino base |
| **Django ORM** | Active Record | con Django 6.1.1 | Fase 12 del camino base |
| **Peewee** | Active Record | 4.5.1 (2026-09) | Pequeño, muy vivo |
| **Pony ORM** | Generadores → SQL | 0.7.20 (2026-08) | **El más original del inventario** |
| **Tortoise ORM** | Active Record, async | 1.1.8 (2026-08) | Inspirado en Django |
| **Piccolo** | Query builder + ORM, async | 1.36.0 (2026-07) | Activo |
| **SQLModel** | SQLAlchemy + Pydantic | 0.0.42 (2026-08) | ⚠️ Sigue en `0.0.x` |
| **Ormar** | SQLAlchemy Core + Pydantic | 0.26.0 (2026-06) | Activo |
| **PyPika** | Solo constructor de consultas | 0.51.1 (2026-02) | No es ORM |
| **aiosql** | SQL en archivos, funciones generadas | 15.0 (2026-01) | El modelo "anti-ORM" |
| **`records`** | Envoltorio minimalista | 0.6.0 (2024-03) | Lento de mantenimiento |
| **`dataset`** | Tablas como diccionarios | 2.0.0 (2026-04) | Para scripts, no aplicaciones |
| **Masonite ORM** | Active Record | 3.0.0 (2026-06) | Nicho, ligado a su framework |

> 🧭 **La fase que justifica el track es `or04`.** Pony traduce **expresiones generadoras de
> Python** a SQL: `select(p for p in Plan if p.total > 10_000_000)`. Eso no existe en Java —lo más
> cercano sería la Criteria API, que es lo contrario de legible— y obliga a entender qué puede y
> qué no puede traducirse, que es un modelo mental nuevo de verdad. Si el track se recorta a tres
> fases, son `or01`, `or04` y `or08`.

---

## 8. Track `tx` — Texto, plantillas y documentación

> **Tesis:** generar texto es la mitad del trabajo real de un backend —correos, reportes, HTML,
> SQL, código, documentación— y casi todo el mundo lo hace concatenando cadenas hasta que se
> quema. Este track es el panorama de hacerlo bien, y el criterio para elegir entre plantilla,
> generador y documento estructurado.

| Fase | Tema |
|---|---|
| tx01 | **El eje**: concatenar ⇄ formatear ⇄ plantilla ⇄ árbol. Cuándo cada uno, y el escape que se te olvida |
| tx02 | **Jinja2 a fondo**: herencia de plantillas, macros, filtros propios, **autoescape**, y el modo `sandbox` para plantillas que edita un usuario |
| tx03 | **Las otras plantillas**: Mako (código Python adentro), Chameleon (XML válido), plantillas de Django, `string.Template` de la caja — comparadas sobre el mismo correo |
| tx04 | **Coloreado de sintaxis y presentación de código**: **Pygments** (y sus 500+ *lexers*), `rich.syntax`, `tree-sitter` para análisis real, y la diferencia entre colorear y entender |
| tx05 | **Markdown y su ecosistema**: `markdown-it-py`, `mistune`, `python-markdown`, extensiones, y el paso a AST en vez de a HTML |
| tx06 | **Documentación como producto**: Sphinx, MkDocs Material, `docutils`, docstrings que generan API, y `doctest` como prueba |
| tx07 | **Generación de código y andamiaje**: `cookiecutter`, `copier`, plantillas de proyecto, y **generar Python con `ast.unparse`** en vez de con cadenas |
| tx08 | **Texto difícil**: Unicode de verdad (normalización, *collation*, `regex` contra `re`), internacionalización con `gettext`, y `babel` para fechas y números |
| tx09 | ⚖️ Veredicto: cuándo una plantilla es la respuesta y cuándo es un lenguaje de programación mal hecho |

**Inventario del terreno:** Jinja2 · Mako · Chameleon · `string.Template` · Django templates ·
Mustache con `chevron` · Pygments · `rich` · `tree-sitter` · `markdown-it-py` · `mistune` ·
`python-markdown` · `docutils` · Sphinx · MkDocs · `pdoc` · `griffe` · `cookiecutter` · `copier` ·
`Faker` · `regex` · `babel` · `unidecode` · `ftfy` · `jinja2-simple-tags` · `htpy` y `dominate`
(HTML como objetos en vez de como texto) · `libcst` (reescribir Python conservando el formato) ·
`ast` y `ast.unparse` de la biblioteca estándar.

> 🧭 **`tx04` es más interesante de lo que su nombre sugiere.** Colorear sintaxis parece un tema
> cosmético y es la puerta a algo que este perfil sí necesita: **analizar código como dato**.
> Pygments tokeniza, `tree-sitter` construye un árbol, y `ast` de la biblioteca estándar te deja
> reescribir Python con Python. La fase termina donde empieza el valor: un *linter* propio de
> treinta líneas para una regla de Áurea que `ruff` no conoce.

> ⚠️ **Y `tx02` trae una advertencia de seguridad que el camino base no da:** una plantilla de
> Jinja2 editable por un usuario es **ejecución de código**, y la inyección de plantillas del lado
> del servidor es una familia de vulnerabilidad entera. El `sandbox` existe por eso y hay que
> nombrarlo.

---

## 9. Track `cl` — Terminal, CLI y TUI

> **Tesis:** el camino base usa `argparse` porque es lo que hay en la caja y alcanza. Este track
> es lo que viene después cuando la herramienta la usan otros: interfaces de línea de comandos que
> se sienten bien, y aplicaciones de terminal completas.

| Fase | Tema |
|---|---|
| cl01 | Más allá de `argparse`: **Click**, **Typer**, `cyclopts`, Fire — y qué compra cada capa |
| cl02 | **`rich`**: tablas, progreso, árboles, `traceback`, y el criterio de cuánto adorno soporta una herramienta seria |
| cl03 | **Interacción**: `questionary`, `prompt_toolkit`, autocompletado del shell, edición de línea |
| cl04 | **TUI completas con `textual`**: el modelo de la aplicación de terminal, y cuándo compite con una web |
| cl05 | Ergonomía: códigos de salida, `stdin`/`stdout` como tubería, `--json` para que otro programa te consuma, configuración en capas |
| cl06 | ⚖️ Veredicto: cuándo la terminal es la interfaz correcta — y para Patricia, casi nunca |

**Inventario:** `argparse` · Click · Typer · `cyclopts` · Fire · `rich` · `textual` ·
`prompt_toolkit` · `questionary` · `tqdm` · `blessed` · `curses` · `colorama` · `humanize` ·
`tabulate` · `shtab` · `platformdirs` · `dynaconf` y `pydantic-settings` (configuración en capas) ·
`trogon` (una TUI generada desde tu propio Click).

📝 **Track corto y candidato a fusionarse con `ui`** — y la §17.10 ya lo da por fusionado. Su tesis es cercana a la de `ui01`
—entregar sin frontend— y podría vivir como tres fases dentro de ese track. La razón para dejarlo
aparte es que el lector de este curso **sí** va a escribir CLIs: es su registro natural.

---

## 10. Track `co` — Comunicaciones y transferencia

> **Tesis:** los protocolos viejos que siguen sosteniendo el trabajo real —correo, FTP,
> transferencias programadas— y que nadie enseña porque no son novedad. Áurea manda liquidaciones
> por correo, recibe archivos por FTP de dos aseguradoras, y notifica por WhatsApp.

| Fase | Tema |
|---|---|
| co01 | **Correo saliente**: `smtplib`, el módulo `email` y los mensajes multiparte, adjuntos, HTML + texto plano, `yagmail` |
| co02 | **Que el correo llegue**: SPF, DKIM, DMARC, listas de bloqueo, rebotes duros y blandos — **el tema que decide si tu correo sirve**, y que es de infraestructura, no de código |
| co03 | **Correo entrante**: `imaplib`, `poplib`, parsear lo que llega, adjuntos hostiles, y el buzón como cola de trabajo |
| co04 | **Probar correo sin mandarlo**: `aiosmtpd`, MailHog/Mailpit, y el servidor de depuración de la caja |
| co05 | **Transferencia de archivos**: `ftplib`, FTPS, **SFTP con Paramiko**, `rsync` orquestado, y la ventana de transferencia que se cae a la mitad |
| co06 | **Mensajería**: Slack, Telegram, Twilio/WhatsApp Business, notificaciones push — con la frontera legal de Áurea delante |
| co07 | ⚖️ Veredicto: qué protocolo para qué, y por qué el correo sigue ganando en el 60% de los casos |

**Inventario, con su estado verificado** *(12 de septiembre de 2026)*:

| Biblioteca | Para qué | Estado |
|---|---|---|
| `smtplib`, `imaplib`, `email`, `ftplib` | Todo lo básico | **Biblioteca estándar** |
| `yagmail` | Correo en dos líneas | 0.16.0 (2026-05) |
| `aiosmtpd` | Servidor SMTP de pruebas | 1.4.6 (2024-05) |
| **Paramiko** | SSH y SFTP | 5.0.0 (2026-05) |
| `imap-tools` | IMAP con API humana | Activo |
| `premailer` | CSS en línea para correo HTML | Activo |

📝 **`co05` usa Paramiko directamente**, sin el envoltorio "cómodo" que sale primero en todas las
búsquedas y que lleva una década sin publicar: está retirado en §21, con los demás. El hábito que
lo evita —mirar la fecha de la última versión antes de agregar una dependencia— se enseña una vez,
en la Fase 00 del camino base, y aquí solo se cosecha.

> 🧭 **`co02` es la fase que justifica el track.** Todo el mundo sabe mandar un correo con
> `smtplib` en cinco líneas. Casi nadie sabe por qué ese correo acaba en spam, y es **la única
> parte del problema que importa**. Es también la fase más incómoda de escribir, porque la
> respuesta correcta a menudo es *"esto no lo resuelvas tú: paga un servicio de envío"*.

---

## 11. Track `vz` — Visualización y gráficos

> **Tesis:** producir una imagen que comunica un número, desde código, sin un diseñador. Y el
> criterio para no producir la que engaña.

| Fase | Tema |
|---|---|
| vz01 | El modelo: gramática de gráficos contra API imperativa, y por qué eso decide todo lo demás |
| vz02 | **Matplotlib**: el imperativo, sus dos APIs, y por qué sigue siendo el sustrato de casi todo |
| vz03 | **La gramática**: Altair/Vega-Lite, plotnine, Great Tables |
| vz04 | **Interactivos**: Plotly, Bokeh, HoloViews — y el costo de que el gráfico viaje al navegador |
| vz05 | **Gráficos que no son datos**: diagramas con Graphviz y Mermaid, redes con NetworkX, **SVG programático** con `drawsvg`, Cairo y `diagrams` |
| vz06 | **Animación y explicación visual**: `manim`, `matplotlib.animation`, GIF y vídeo desde cuadros |
| vz07 | ⚖️ Veredicto: y **el gráfico que miente** — ejes truncados, dobles escalas, mapas de color que no son perceptualmente uniformes, y la paleta que un daltónico no distingue |

**Inventario:** Matplotlib · seaborn · plotnine · Altair · Plotly · Bokeh · HoloViews/hvPlot ·
Great Tables · Graphviz · NetworkX · `drawsvg` · `pycairo` · `manim` · `pillow` (dibujo) ·
`datashader` · `pydeck` · `folium` (mapas) · `geopandas` · `mermaid` orquestado · `diagrams`
(arquitectura como código) · `svg.py`.

📝 **El SVG programático se hace con `drawsvg`.** La alternativa que sale primero en las búsquedas
está parada desde 2022 y retirada en §21.

> 📝 **Frontera con el track de datos.** `propuestas-fases-base-ia-datos.md` también toca
> visualización. La división propuesta: **allá**, visualizar para **explorar** un conjunto de
> datos; **aquí**, generar imágenes **como entregable** de un sistema —el reporte que sale del
> cierre nocturno—. Si esa frontera no se respeta, uno de los dos tracks sobra.

---

## 12. Track `qa` — Calidad, pruebas y mantenimiento

> **Tesis:** el camino base enseña `pytest` y `mypy` en una fase (la 08). Este track es el resto
> del oficio: lo que hace falta para que un sistema sobreviva tres años con una sola persona
> manteniéndolo.

| Fase | Tema |
|---|---|
| qa01 | La pirámide, revisada para un equipo de uno: qué probar cuando no hay QA |
| qa02 | **`pytest` a fondo**: *fixtures* con alcance, `parametrize` compuesto, plugins que valen la pena, escribir el tuyo, `conftest` en capas |
| qa03 | **Dobles y datos**: `unittest.mock`, `monkeypatch`, `responses`/**`respx`**, `freezegun`, **`factory_boy`**, `polyfactory`, `Faker` |
| qa04 | **Pruebas de integración de verdad**: **`testcontainers`** con Postgres, migraciones en las pruebas, y por qué el doble de la base miente |
| qa05 | **Propiedades y modelos**: Hypothesis más allá de lo básico — estrategias propias, *stateful testing*, y encontrar el invariante |
| qa06 | **Medir la suite**: cobertura con criterio, **mutación con `mutmut`**, y por qué el 90% de cobertura no dice nada |
| qa07 | **Carga y rendimiento**: **Locust**, `pytest-benchmark`, y la disciplina de la Fase 17 —el generador no puede ser el cuello de botella— |
| qa08 | **La cadena de calidad**: `ruff`, `mypy`/`pyright` estricto, `pre-commit`, `bandit`, `pip-audit`, `deptry`, `vulture`, `tox`/**`nox`** contra varias versiones |
| qa09 | **e2e de web con Playwright** *(viene de `au04`)* |
| qa10 | ⚖️ Veredicto: qué vale la pena cuando eres uno, y qué es ceremonia que no vas a mantener |

📝 **`qa09` se mueve desde `au04`.** Las pruebas e2e encajan mejor aquí, y así el track `au` queda
más apretado alrededor de su tesis —automatizar lo ajeno— en vez de repartirse entre dos temas.

> 🧭 **La fase que sostiene el track es `qa06`.** La cobertura como número es el ritual más
> extendido y más vacío del oficio, y la mutación es la forma honesta de medir una suite —cara,
> lenta, y reveladora. Ese contraste es una lección, no una herramienta.

---

## 13. Track `cv` — Visión por computador y multimedia avanzado

> **Tesis:** procesar imágenes y vídeo con modelos, no con filtros. Es el track con la frontera
> más delicada del inventario: **la mitad de sus temas rozan la frontera legal y ética que el
> curso declaró intocable**, y esa tensión es su contenido.

| Fase | Tema |
|---|---|
| cv01 | El modelo: píxeles ⇄ características ⇄ modelo entrenado. Qué hace OpenCV y qué hace una red |
| cv02 | **Detección**: rostros, objetos, códigos — Haar, DNN de OpenCV, **MediaPipe**, YOLO |
| cv03 | **Puntos de referencia faciales**: MediaPipe Face Mesh, dlib, y qué son de verdad esos 468 puntos |
| cv04 | **Morphing y transformación de rostros**: triangulación de Delaunay, warping por piezas, interpolación, `face-alignment` — **la técnica desde cero**, que es lo que la hace enseñable |
| cv05 | **Reconocimiento e identidad**: InsightFace, `deepface`, incrustaciones y distancia — **y la fase donde el curso dice que no** |
| cv06 | **Segmentación y edición**: `rembg`, SAM, inpainting, superresolución |
| cv07 | **Vídeo con modelos**: seguimiento, estabilización, detección por cuadro y el costo real en tiempo |
| cv08 | ⚖️ Veredicto **ético y legal, con nombre propio**: biometría, consentimiento, habeas data, y por qué Áurea **no** puede hacer la mitad de esto |

**Inventario, con su estado** *(12 de septiembre de 2026)*:

| Biblioteca | Para qué | Estado |
|---|---|---|
| **OpenCV** (`opencv-python`) | Todo lo clásico | Activo |
| **MediaPipe** | Malla facial, manos, pose — en tiempo real | 1.0.1 (2026-08) |
| **InsightFace** | Reconocimiento e incrustaciones | 2.0 (2026-09) |
| `rembg` | Quitar el fondo | 2.0.84 (2026-09) |
| `scikit-image` | Procesamiento científico | Activo |
| `dlib` | Detección y puntos de referencia clásicos | Mantenimiento lento, pero vivo |
| `deepface` | Envoltorio sobre varios modelos de rostro | Activo |
| `ultralytics` (YOLO) | Detección y segmentación | Activo, licencia AGPL — **mirarla** |

> ⚠️ **Este track necesita una decisión editorial antes de escribirse.** El dominio de Áurea tiene
> **fotografía clínica de pacientes** y una frontera legal explícita: la historia clínica es
> reservada y hay régimen de habeas data. Hay dos caminos y hay que elegir uno:
>
> **(a) Usar el dominio y hacer de la restricción el contenido.** Las fotos de "antes y después"
> de Marcela son datos biométricos de pacientes; el track enseña la técnica **y** enseña que
> `cv05` —reconocimiento— es exactamente lo que Áurea no puede desplegar. Es el camino más fuerte
> y el más difícil de escribir bien.
>
> **(b) Sacar el track del dominio** y usar rostros públicos o sintéticos, declarando que el
> ejercicio es técnico y que el caso real está prohibido.
>
> **Recomiendo (a)**, y con una regla dura: **ninguna imagen de paciente sale de la máquina del
> lector**, ningún ejercicio sube nada a un servicio externo, y el morphing de `cv04` se hace con
> rostros del propio lector o sintéticos. El curso ya tiene ese músculo — es la misma frontera de
> la §5 de la historia de Áurea, aplicada a imágenes.

> 🧭 **`cv04` es la fase que hace que el track no sea un desfile de modelos preentrenados.** El
> morphing se puede hacer en veinte líneas llamando a una biblioteca, y así no se aprende nada; o
> se puede construir —detectar puntos, triangular, deformar cada triángulo, interpolar— y entonces
> se entiende qué es una transformación afín por piezas. **La segunda versión es la que se
> escribe**, y la primera aparece al final como "y esto es lo que hace la biblioteca que ibas a
> usar".

---

## 14. Track `ed` — Didáctica, divulgación y juguetes **(tercer turno: sin encargo en Áurea)**

> **Tesis:** Python es el lenguaje con el que se enseña a programar en medio mundo, y este perfil
> —un senior con hijos, o con un equipo al que formar, o que da una charla— va a necesitar eso
> alguna vez. **Es el track más débil del inventario contra el criterio de §1**, y va con esa
> advertencia por delante.

| Fase | Tema |
|---|---|
| ed01 | **`turtle`**: la biblioteca estándar que nadie de este perfil ha abierto — gráficos de tortuga, recursión visible, y por qué sigue siendo la mejor introducción que existe |
| ed02 | **Juegos como vehículo**: `pygame`, `arcade`, y el bucle de juego como modelo de programa |
| ed03 | **Notebooks para explicar**: Jupyter, `ipywidgets`, marimo, y el problema del estado oculto |
| ed04 | **Visualizar algoritmos**: animar un ordenamiento, un recorrido de grafo, una estructura — con `manim` o con `matplotlib` |
| ed05 | **Enseñar a alguien que no programa**: el caso de Patricia, y qué se le puede pedir de verdad |
| ed06 | ⚖️ Veredicto: cuándo simplificar ayuda y cuándo miente |

> ⚠️ **Evaluación honesta de este track, porque el criterio de §1 se le aplica igual que a los
> demás.** Falla la pregunta 1 —`turtle` no enseña un modelo que el lector no tenga— y falla la 3
> —no alimenta a ningún proyecto de Áurea—. Lo que sí tiene es una justificación distinta a las
> otras: **no es para el trabajo del lector, es para cuando al lector le toque enseñar.** Y ahí
> `ed05` sí conecta con el dominio: el curso entero se juega la tesis en si Patricia puede abrir y
> entender lo que el lector escriba.
>
> 🪦 **Este track estuvo propuesto para eliminación, y el encuadre a la carta lo salva.** El
> argumento de arriba era correcto mientras el criterio de §1 decidía la **admisión**: con `lg` y
> `so` sobre la mesa, gastar una fase del curso en `turtle` no se sostenía. Pero en una carta no
> hay plazas que repartir — **no hay por qué eliminar un plato que alguien puede querer pedir**.
>
> **Lo que queda, entonces:** `ed` baja al **tercer turno** (§19) y se escribe al final, con su
> propio ejemplo y sin pasar por el dominio. `ed01` dibuja una espiral con `turtle` y no tiene que
> explicar por qué una clínica odontológica necesita tortugas.
>
> **Y `ed05` sí se muda**, pero no por debilidad: *enseñarle a alguien que no programa* es una
> pregunta del camino base —el curso se juega la tesis en si Patricia puede abrir lo que el lector
> escriba— y encaja mejor en `ui01`, junto a las demás formas de entregar. Que se mude es un
> ascenso, no un recorte.

---

## 15. Track `pk` — El panorama de gestores y empaquetado

> **Tesis:** el camino base elige **un** gestor y sigue adelante. Este track es el mapa completo
> del terreno que el camino base atraviesa sin mirar a los lados.

*(Sin cambios respecto a la versión anterior; se mantiene íntegro.)*

| Fase | Tema |
|---|---|
| pk01 | El modelo real: qué es un entorno, qué resuelve un gestor y qué está resolviendo de más |
| pk02 | `pip` + `venv` + `pip-tools`: el camino sin dependencias, y hasta dónde llega |
| pk03 | **`uv`**: velocidad medida, y el costo de adoptar una herramienta joven |
| pk04 | **`conda`, `mamba`, `miniforge` y Anaconda**: gestor contra distribución, canales, y el problema binario |
| pk05 | Poetry y PDM: el modelo de proyecto con *lock* propio |
| pk06 | Empaquetar y publicar: `wheel`, `sdist`, *entry points*, PyPI y un índice privado |
| pk07 | Entregar a quien no es ingeniero: `pipx`, `zipapp`, PEP 723, ejecutable congelado, contenedor |
| pk08 | ⚖️ Veredicto: cuál para un equipo de uno, para uno de quince, y para una empresa con plataforma |

📝 **Actualización:** el camino base ya midió `pip-tools`, `uv` y Miniforge en su Fase 07, y `uv
tool`, `zipapp`, PEP 723 y el congelado en la 09. **Este track ya no tiene que producir esos
números: los cita de `BENCHMARKS.md` y añade los que faltan** —Poetry, PDM, `mamba`, el índice
privado—. Eso lo acorta y lo hace más fácil de escribir.

---

## 16. Track `jv` — Convivir con tu stack Java

> **Tesis:** Python en el borde no significa matar la JVM. Significa hablarle bien.
> **Track corto (4 fases) y el más distintivo del curso.**

| Fase | Tema |
|---|---|
| jv01 | Hablarle a servicios Java: los formatos que la JVM ya produce (Avro, Protobuf, Parquet, JMX) |
| jv02 | JPype y Py4J |
| jv03 | GraalPy y Jython, con veredicto de para qué sirven hoy |
| jv04 | La arquitectura mixta: dónde poner la frontera |

📝 **Y ahora tiene un ancla que antes no tenía:** el duelo de la Fase 17 dejó un Spring Boot 3.5.16
funcionando, medido, y con el mismo contrato que la API de Python. **Ese proyecto es el sistema
Java heredado creíble que el track necesitaba** — `jv01` puede empezar hablándole a él.

---

## 17. 🧪 Nueve tracks más: donde Python **es** el pegamento correcto

> **Por qué se agregan.** El inventario anterior cubría bien los registros en los que Python
> *produce* algo —una interfaz, un archivo, un reporte—, y se quedaba corto en el registro que
> mejor lo define: **Python como capa de coordinación entre cosas que él no hace**. Un solucionador
> escrito en C++, una biblioteca de geometría escrita en C, un flujo de trabajo que vive en cuatro
> sistemas, un formato que inventó una aseguradora en 1994. Ahí no compite con Java: es el idioma
> por defecto, y el reflejo que hay que recalibrar es otro —**cuánto código propio escribir antes
> de admitir que el trabajo lo hace otro**.

> ⚠️ **Y la advertencia que corresponde, antes de las tablas:** agregar nueve tracks empeora el
> problema que la §20 ya declaraba. Veinticinco tracks no se escriben; se eligen. Al final de la
> sección va la recomendación de cuáles de estos nueve valen más que varios de los anteriores, y
> cuáles de los anteriores deberían morirse para hacerles sitio.

### 17.1 Track `wf` — Orquestación de trabajos y flujos

> **Tesis:** la Fase 15 del camino base construye el proceso nocturno con `cron`, un archivo de
> estado y reintentos escritos a mano — y lo hace a propósito, para que se vea el problema. Este
> track es lo que viene cuando ese proceso deja de ser uno y pasa a ser catorce con dependencias
> entre ellos: **el grafo de tareas como modelo**, y el precio de cada orquestador.

| Fase | Tema |
|---|---|
| wf01 | El eje: `cron` ⇄ cola de tareas ⇄ grafo dirigido ⇄ flujo durable. Qué problema resuelve cada escalón y cuál tienes de verdad |
| wf02 | **Colas de tareas**: Celery, **RQ**, **Dramatiq**, `arq`, Huey — y el broker como decisión arquitectónica |
| wf03 | **Programación en proceso**: **APScheduler**, `schedule`, y por qué el `cron` del sistema sigue ganando más veces de las que crees |
| wf04 | **El grafo declarativo**: Airflow — el estándar de facto, su modelo de operadores y su costo operativo real |
| wf05 | **La generación siguiente**: **Prefect**, **Dagster**, Kedro — flujos como funciones de Python, y el *asset* como unidad en vez de la tarea |
| wf06 | **Flujos durables**: **Temporal** y el SDK de Python — la ejecución que sobrevive al reinicio, y qué significa "determinista" ahí |
| wf07 | **Lo transversal**: idempotencia, reanudación, *backfill*, ventanas, reintentos con retroceso, y la tarea que corrió dos veces |
| wf08 | ⚖️ Veredicto **medido**: el cierre nocturno de Áurea implementado en `cron`, en Celery, en Prefect y en Temporal — líneas escritas, minutos de puesta en marcha, memoria en reposo, y qué pasa cuando se cae a la mitad |

**Inventario:** Celery · RQ · Dramatiq · `arq` · Huey · APScheduler · `schedule` · Airflow ·
Prefect · Dagster · Kedro · Luigi · Temporal · Windmill · `taskiq` · `procrastinate`
(sobre Postgres) · `flower` (monitoreo de Celery).

> 🧭 **La fase que sostiene el track es `wf07`**, no las de producto. Idempotencia y reanudación
> son el contenido; los orquestadores son cinco formas distintas de no resolverlas por ti. Un
> track que sea "cómo se declara un DAG en cada herramienta" no vale nada y es exactamente lo que
> la §1 prohíbe.

### 17.2 Track `ff` — La frontera nativa: el pegamento, literalmente

> **Tesis:** el track más cercano al corazón del curso. Python es lento y todo el mundo lo sabe;
> lo que casi nadie de este perfil sabe es **dónde está exactamente la frontera** con el código
> nativo, qué cuesta cruzarla, y por qué NumPy es rápido si está escrito en Python. Para alguien
> que viene de Java, el equivalente mental es JNI — y la comparación es reveladora porque en
> Python cruzar la frontera es **normal**, no un último recurso.

| Fase | Tema |
|---|---|
| ff01 | El modelo: qué es de verdad el GIL, qué es un módulo de extensión, y por qué `import numpy` ya es código C |
| ff02 | **`ctypes` y `cffi`**: llamar a una `.so` sin compilar nada — y el primer `segfault`, que es una experiencia nueva para quien viene de la JVM |
| ff03 | **Cython**: anotar Python hasta que deja de serlo, y medir cada anotación |
| ff04 | **`numba`**: compilación JIT sobre bucles numéricos — lo más parecido al JIT de la JVM que hay en Python, y sus límites |
| ff05 | **El lado nativo moderno**: **PyO3 + maturin** (Rust), **pybind11** y **nanobind** (C++), y por qué la mitad de las herramientas nuevas del ecosistema son Rust con sombrero |
| ff06 | **El buffer compartido**: `memoryview`, el protocolo de búferes, Arrow, y **copia cero** entre procesos y lenguajes |
| ff07 | **Paralelismo real**: `multiprocessing` contra memoria compartida, subintérpretes (PEP 734) y el intérprete **sin GIL** (PEP 703) — estado, promesas y qué se rompe |
| ff08 | ⚖️ Veredicto **medido**: la misma función caliente del cierre de Áurea en Python puro, Cython, `numba` y Rust — tiempo, memoria, líneas, y el costo de construcción y distribución que nadie mide |

**Inventario:** `ctypes` · `cffi` · Cython · `numba` · PyO3/maturin · pybind11 · nanobind ·
SWIG · `mypyc` · Nuitka · `setuptools` y `scikit-build-core` · `cibuildwheel` · `array` ·
`memoryview` · `pyarrow` · `shared_memory`.

> 🧭 **`ff08` es la fase que salva al track de ser un catálogo**, y tiene que medir lo que las
> comparaciones de internet no miden: **el costo de distribución**. Una extensión en Cython
> convierte tu paquete de "`pip install` en todas partes" a "construir una rueda por plataforma",
> y eso —que la Fase 09 del camino base ya dejó doliendo— es a menudo más caro que los 40 ms que
> se ganaron.

### 17.3 Track `pr` — Protocolos y contratos más allá de REST

> **Tesis:** el camino base construye una API REST con FastAPI y la mide. Esto es el resto del
> terreno: los otros contratos que existen, cuándo cada uno gana, y cómo se habla con un sistema
> que no expone JSON sobre HTTP — que en el mundo de Áurea es la mitad de los sistemas.

| Fase | Tema |
|---|---|
| pr01 | El eje: contrato implícito ⇄ esquema compartido ⇄ IDL con generación de código. Qué compra cada escalón, y qué compatibilidad te da |
| pr02 | **gRPC y Protobuf**: `grpcio`, `betterproto`, compatibilidad hacia atrás y hacia adelante, *streaming* bidireccional — y el terreno donde el equipo Java ya vive |
| pr03 | **Los formatos binarios**: Avro y su registro de esquemas, MessagePack, CBOR, **Protobuf contra JSON medidos** en tamaño y en tiempo |
| pr04 | **GraphQL desde Python**: **Strawberry**, Ariadne, Graphene — el problema N+1 con nombre propio y el *dataloader* |
| pr05 | **Tiempo real**: WebSocket, SSE, *long polling* — y la pregunta honesta de cuál necesitas |
| pr06 | **Mensajería como contrato**: MQTT (`paho`), AMQP (`pika`), NATS, **AsyncAPI** como el OpenAPI de los eventos |
| pr07 | **Versionado de contratos**: pruebas de contrato (`pact-python`, `schemathesis`), evolución de esquemas, y el cambio rompedor que descubres en producción |
| pr08 | ⚖️ Veredicto: REST sigue ganando, y las tres situaciones concretas en las que no |

**Inventario:** `grpcio` · `betterproto` · `protobuf` · `fastavro` · `msgspec` · `msgpack` ·
`cbor2` · `orjson` · Strawberry · Ariadne · Graphene · `websockets` · `sse-starlette` ·
`paho-mqtt` · `pika` · `aio-pika` · `nats-py` · `schemathesis` · `pact-python` ·
`datamodel-code-generator`.

> 🧭 **`pr07` es la fase con más valor y la que nadie escribe.** Un contrato roto entre dos
> servicios es el error más caro de una arquitectura distribuida, y la respuesta habitual —"lo
> hablamos en el chat"— es la que este lector ya sufrió en Java. Aquí tiene herramienta.

### 17.4 Track `lg` — Legado, intercambio sectorial y el formato que inventó alguien en 1994

> **Tesis:** el track que el dominio de Áurea pedía a gritos. La salud y los seguros corren sobre
> formatos que no eligió nadie vivo: ancho fijo de mainframe, EDI, HL7, XML firmado, planos con
> EBCDIC. **Python es el pegamento canónico de este terreno** porque es lo único que se puede
> escribir rápido contra un formato que cambia por resolución ministerial.

| Fase | Tema |
|---|---|
| lg01 | **Ancho fijo y mainframe**: `struct` aplicado de verdad, EBCDIC (`codecs`), COBOL *copybooks*, decimal empaquetado, registros de longitud variable |
| lg02 | **XML en serio**: `lxml`, XPath, XSD y validación, espacios de nombres, XSLT, y **la bomba de entidades** (XXE) que es una vulnerabilidad real, no un ejercicio |
| lg03 | **Documentos firmados**: firma XML (XAdES), firma de PDF, sellos de tiempo — el universo de la factura electrónica latinoamericana, que es trabajo pagado y constante |
| lg04 | **EDI**: X12 y EDIFACT, segmentos y bucles, y por qué el archivo parece ilegible y no lo es |
| lg05 | **Salud**: **HL7 v2** (el de las barras verticales), **FHIR** (`fhir.resources`), y la distancia entre el estándar y lo que manda de verdad la clínica |
| lg06 | **Archivos planos hostiles**: codificaciones mezcladas, `chardet`/`charset-normalizer`, saltos de línea de tres sabores, CSV que no cumple ningún RFC, y la reconciliación de lo que no cuadra |
| lg07 | ⚖️ Veredicto: cuándo escribir el parser y cuándo comprarlo — y la regla del formato que cambia una vez al año |

**Inventario:** `struct` · `codecs` · `lxml` · `xmlsec` · `signxml` · `pyhanko` (firma PDF) ·
`cryptography` · `pyx12` · `bots-edi` · `hl7apy` · `python-hl7` · `fhir.resources` ·
`charset-normalizer` · `ftfy` · `cerberus` · `pydantic` (como validador de lo que llega).

> 🧭 **Este es el track con más ventaja competitiva de todo el inventario.** No porque sea
> divertido —no lo es— sino porque **casi nadie lo enseña** y el trabajo existe, está mal pagado
> de enseñar y bien pagado de hacer. Encaja con Áurea sin forzar nada, que es lo que la §20 pedía
> y varios tracks no cumplen.

### 17.5 Track `se` — Seguridad aplicada y criptografía

> **Tesis:** la Fase 16 del camino base absorbió "criptografía y manejo de secretos" y le dio lo
> que cabe en una fase. Este track es lo que no cupo, y está organizado por **la pregunta que
> resuelve cada primitiva**, no por el nombre del algoritmo.

| Fase | Tema |
|---|---|
| se01 | El modelo: confidencialidad ⇄ integridad ⇄ autenticidad ⇄ no repudio. Qué primitiva contesta cada una, y el error de elegir por nombre |
| se02 | **`cryptography` y PyNaCl**: simétrico autenticado, asimétrico, derivación de claves, y la regla de no inventar nada |
| se03 | **Contraseñas y tokens**: Argon2, `bcrypt`, `secrets`, JWT con `pyjwt` — **y por qué un JWT no es una sesión**, que es el error más repetido del oficio |
| se04 | **Identidad delegada**: OAuth2 y OIDC con `authlib`, flujos con y sin navegador, y hablar con el Keycloak que el equipo Java ya tiene |
| se05 | **Secretos en reposo y en tránsito**: `keyring`, Vault (`hvac`), cifrado sobrante en la base, y la variable de entorno que terminó en un log |
| se06 | **TLS de verdad**: certificados, cadenas, fijación, mTLS contra la aseguradora, y el `verify=False` que alguien va a escribir |
| se07 | **Defensa de la aplicación**: `bandit`, `pip-audit`, la deserialización que ejecuta código (`pickle`, YAML), inyección de plantillas, y la cadena de suministro |
| se08 | ⚖️ Veredicto: lo que sí tienes que implementar y lo que tienes que dejar de implementar |

**Inventario:** `cryptography` · PyNaCl · `argon2-cffi` · `bcrypt` · `passlib` · `secrets` ·
`pyjwt` · `python-jose` · `authlib` · `hvac` · `keyring` · `certifi` · `bandit` · `pip-audit` ·
`detect-secrets` · `itsdangerous`.

> ⚠️ **La fase incómoda es `se03`.** El JWT sin estado como sustituto de la sesión es un patrón
> que este perfil arrastra de su stack de origen y que se rompe el día que hay que revocar algo.
> La fase tiene que decirlo con el costo delante, no como opinión.

### 17.6 Track `ob` — Observar el sistema propio

> **Tesis:** la Fase 16 del camino base deja logs estructurados y métricas básicas. Este track es
> el oficio completo, y su tesis dura: **en un equipo de uno, la observabilidad no es para
> depurar — es para no tener que estar mirando.**

| Fase | Tema |
|---|---|
| ob01 | El modelo de las tres señales, y la cuarta que importa más: los eventos anchos. Qué contesta cada una |
| ob02 | **Bitácoras**: `logging` a fondo (el que casi nadie configura bien), `structlog`, `loguru`, correlación por petición, y el costo de cardinalidad |
| ob03 | **Métricas**: `prometheus-client`, tipos de métrica, histogramas y percentiles — y por qué el promedio miente |
| ob04 | **Trazas**: OpenTelemetry en Python, instrumentación automática contra manual, propagación de contexto, muestreo |
| ob05 | **Perfilado en producción**: `py-spy` sobre un proceso vivo, `memray`, `scalene`, `tracemalloc`, y la fuga de memoria que solo aparece a las seis horas |
| ob06 | **Errores como producto**: Sentry y compañía, agrupación, ruido, y la alerta que todo el mundo silenció |
| ob07 | ⚖️ Veredicto: el presupuesto de observabilidad de un sistema pequeño, y qué se puede tirar |

**Inventario:** `logging` · `structlog` · `loguru` · `rich.logging` · `prometheus-client` ·
`opentelemetry-*` · `py-spy` · `memray` · `scalene` · `yappi` · `tracemalloc` · `objgraph` ·
`sentry-sdk` · `psutil` · `pyinstrument`.

> 🧭 **`ob05` es la fase que este perfil va a agradecer.** En la JVM tiene JFR, async-profiler y
> un ecosistema maduro; su reflejo es que en Python no hay equivalente. `py-spy` adjuntándose a un
> proceso en producción **sin reiniciarlo ni instrumentarlo** es la respuesta, y sorprende.

### 17.7 Track `so` — Optimización, simulación y decisiones

> **Tesis:** hay una familia entera de problemas que este perfil resuelve con bucles anidados y
> heurísticas inventadas —asignar turnos, rutear visitas, planificar capacidad, cuadrar
> inventario— y para los que existe una disciplina con setenta años. **Python es la interfaz
> estándar de esa disciplina**: los solucionadores están en C++ y se manejan desde aquí.

| Fase | Tema |
|---|---|
| so01 | El giro mental: **describir el problema en vez de programar la solución**. Variables, restricciones, función objetivo — y por qué eso se parece más a SQL que a un algoritmo |
| so02 | **Programación lineal y entera**: PuLP, HiGHS, y el modelo de asignación de terapeutas de Áurea |
| so03 | **OR-Tools**: CP-SAT, el solucionador que resuelve lo que parecía imposible — horarios, turnos, empaquetado |
| so04 | **Rutas y grafos**: el problema del viajante y sus primos, `networkx`, y las visitas domiciliarias |
| so05 | **Simulación de eventos discretos** con **SimPy**: colas, recursos, cuellos de botella — la sala de espera como modelo |
| so06 | **Cuando no hay modelo**: `scipy.optimize`, metaheurísticas, y la honestidad de "bueno y rápido" contra "óptimo y tarde" |
| so07 | ⚖️ Veredicto: cuándo esto paga y cuándo la hoja de cálculo de Patricia era suficiente |

**Inventario:** OR-Tools · PuLP · `highspy` · `mip` · `pyomo` · `cvxpy` · SimPy · `salabim` ·
`scipy.optimize` · `networkx` · `deap` · `optuna` · `mesa` (agentes).

> 🧭 **`so01` es el track entero.** Si el lector sale entendiendo que hay problemas que se
> *declaran* y que un solucionador es una base de datos de respuestas posibles, el track cumplió
> aunque no recuerde una sola API. Es, de los veinticinco, el que más recalibra un reflejo —porque
> el reflejo de un senior de Java ante "asigna 40 terapeutas a 300 sesiones" es escribir el bucle.

### 17.8 Track `gi` — Geoespacial

> **Tesis:** el dato con coordenadas tiene reglas propias que no se improvisan —proyecciones,
> topología, índices espaciales— y **Python es el pegamento canónico sobre GDAL y PROJ**, que son
> las dos bibliotecas en C sobre las que corre todo el mundo, incluido el resto de la industria.

| Fase | Tema |
|---|---|
| gi01 | El modelo: geometría ⇄ proyección ⇄ topología. **El SRID que no coincide** es el error número uno y cuesta kilómetros |
| gi02 | **Vectorial**: `shapely`, `geopandas`, `pyproj`, `fiona` — y las operaciones que parecen simples y no lo son |
| gi03 | **PostGIS desde Python**: índices GiST, consultas de vecindad, y "los pacientes a menos de 5 km de cada sede" |
| gi04 | **Ráster y teledetección**: `rasterio`, `xarray`, `rioxarray`, mosaicos y remuestreo |
| gi05 | **Rutas y direcciones**: `osmnx`, OSRM/Valhalla, geocodificación, y la diferencia entre distancia recta y distancia real |
| gi06 | **Mapas como entregable**: `folium`, `keplergl`, teselas vectoriales, y **H3/S2** como índice jerárquico |
| gi07 | ⚖️ Veredicto: cuándo te basta con `lat`/`lon` en dos columnas — que es más a menudo de lo que el entusiasmo sugiere |

**Inventario:** `shapely` · `geopandas` · `pyproj` · `fiona` · GDAL · `rasterio` · `xarray` ·
`rioxarray` · `osmnx` · `geopy` · `folium` · `h3` · `s2sphere` · `pydeck` · `contextily` ·
`geoalchemy2` · `duckdb` con su extensión espacial.

> 📝 **Frontera con `vz` y con el track de datos.** Aquí el mapa es **cálculo**; allá es dibujo.
> Si `gi06` se convierte en una galería de mapas bonitos, se está comiendo a `vz` y hay que
> recortarlo.

### 17.9 Track `sy` — El sistema operativo, los procesos y los archivos en movimiento

> **Tesis:** la Fase 05 del camino base enseña a orquestar procesos y a moverse por el sistema de
> archivos, y se detiene donde empieza el oficio de administrar. Este track es el resto:
> **Python como reemplazo honesto del script de shell de 400 líneas** que nadie se atreve a tocar.

| Fase | Tema |
|---|---|
| sy01 | **`subprocess` a fondo**: interbloqueos por tubería llena, `stdin`/`stdout` reales, tiempos de espera, grupos de procesos, y la inyección de shell que `shell=True` regala |
| sy02 | **Las envolturas**: `plumbum`, `sh`, `invoke`, `pyinvoke` — y cuándo vale la pena la azúcar |
| sy03 | **Inspección del sistema**: `psutil`, límites de recursos, señales, `os.fork`, y el proceso zombi |
| sy04 | **El sistema de archivos en serio**: `pathlib` avanzado, permisos, enlaces, bloqueo de archivos, escritura atómica, `fsync`, y **la operación que parecía atómica y no lo era** |
| sy05 | **Reaccionar a cambios**: `watchdog`, `inotify`, el directorio de entrada de la aseguradora, y el archivo que se leyó a medio copiar |
| sy06 | **Convivir con el sistema**: unidades de `systemd`, `supervisord`, registro en el `journal`, `sd_notify`, señales de recarga, y el demonio que se reinicia solo |
| sy07 | **Sincronización y respaldo**: `rsync` orquestado, `rclone`, instantáneas, verificación por *hash*, y el respaldo que nadie probó restaurar |
| sy08 | ⚖️ Veredicto: la línea exacta donde el script de shell deja de ser la respuesta correcta |

**Inventario:** `subprocess` · `shlex` · `plumbum` · `sh` · `invoke` · `psutil` · `watchdog` ·
`pathlib` · `shutil` · `filelock` · `tempfile` · `signal` · `resource` · `pexpect` ·
`python-daemon` · `systemd-python` · `rclone` orquestado.

> 🧭 **`sy04` es la fase con más sustancia escondida.** "Escribir un archivo" parece resuelto
> desde la Fase 01, y la escritura atómica —archivo temporal en el mismo sistema de archivos,
> `fsync`, `os.replace`— es la diferencia entre un cierre nocturno que sobrevive a un corte de luz
> y uno que deja un JSON truncado. Es exactamente el tipo de cosa que el reflejo de la JVM **no**
> cubre, porque allá lo hacía el framework.

### 17.10 Lo que estos nueve le hacen al inventario

No se agregan gratis. Con ellos son **veinticinco tracks**, que es una cifra absurda para
escribir y, más importante, una cifra que vuelve inútil la palabra *"opcional"*: si todo es
opcional, el lector no tiene criterio para elegir. La recomendación que acompaña a la propuesta
es entonces de **saldo neto, no de suma**:

**Entran arriba, por encima de casi todo lo anterior:**

- **`lg` (legado e intercambio)** — el que mejor encaja con Áurea, el que menos gente enseña, y
  el único del inventario con un argumento de empleabilidad directo.
- **`ff` (frontera nativa)** — el que mejor sostiene la tesis del curso, y el que contesta la
  pregunta que este perfil trae desde el primer día: *"¿y esto no es lentísimo?"*.
- **`so` (optimización)** — el que más recalibra un reflejo, que es el criterio número uno de §1.
- **`wf` (orquestación)** — continuación natural y obvia de la Fase 15; el lector la va a pedir.

**Entran en la mitad, y compiten de igual a igual con los anteriores:** `se`, `ob`, `pr`, `sy`.

**Entra abajo, con la misma advertencia que `vz`:** `gi`, que es magnífico y solo le sirve a quien
tiene coordenadas.

**Y a cambio, tres ajustes que esta propuesta recomienda de frente** —uno de ellos revertido después por el encuadre a la carta:

| Track | Qué se propone |
|---|---|
| `ed` — didáctica | ~~Se elimina~~ → **revertido por el encuadre a la carta**: baja al tercer turno (§19) y se escribe al final, con ejemplo propio. `ed05` sí se muda a `ui01`, por afinidad y no por recorte |
| `cl` — terminal y CLI | **Se fusiona en `ui`** como tres fases, tal como su propia ficha ya sugería |
| `vz` — visualización | **Se recorta a cuatro fases** y cede lo exploratorio al track de datos, que era la frontera que la §11 dejaba sin resolver |

> 🧭 **Y el criterio general, que vale más que la lista:** un track entra si contesta *"¿qué
> modelo de acceso tiene esto?"* mejor que el anterior. `so` contesta "declarativo contra
> imperativo". `ff` contesta "dónde está la frontera del intérprete". `lg` contesta "cómo se lee
> un formato que no puedes cambiar". `ed` no contesta nada que el lector no sepa.

---

## 18. 🪦 Bibliotecas retiradas del inventario

Las versiones anteriores de este documento **proponían enseñar bibliotecas abandonadas** —con
buena intención: servían de lección sobre mirar la fecha de la última publicación. Esa lección se
queda, pero **se da una sola vez y en la Fase 00 del camino base**, que es donde vive el criterio
de elegir dependencias. Un track opcional no puede tener como fase estrella un envoltorio muerto:
el lector se lleva el nombre y se olvida de la advertencia.

**Retiradas, con la fecha que las condena** *(dato del propio documento, verificado el 12 de
septiembre de 2026)*:

| Biblioteca | Estaba en | Última publicación | Qué se usa en su lugar |
|---|---|---|---|
| **`ffmpeg-python`** | `ar09` — vídeo | **2019** | El binario `ffmpeg` por `subprocess`, o **PyAV** si hace falta cuadro a cuadro |
| **`pysftp`** | `co05` — transferencia | **2016** | **Paramiko** directamente, que es lo que envolvía |
| **`face_recognition`** | `cv05` — reconocimiento | **2020** | **InsightFace**, o `dlib` directo asumiendo su ritmo |
| **GINO** | `or05` — ORM asíncrono | **2020** | SQLAlchemy 2.x asíncrono, que es lo que GINO adelantó |
| **`svgwrite`** | `vz05` — SVG programático | **2022** | **`drawsvg`**, activo y con mejor API |

**Retiradas por la misma razón, pero con la fecha sin verificar** — hay que confirmarlas contra
PyPI antes de dar por buena la lista:

| Biblioteca | Estaba en | Sospecha |
|---|---|---|
| `docopt` | `cl01` | Sin publicar desde hace años; existe el bifurcado `docopt-ng` |
| `pystache` | `tx03` | Mustache en Python; `chevron` lo reemplaza |
| Genshi | `tx03` | Prácticamente detenido |
| Justpy | `ui05` | Descontinuado por su autor |
| `decord` | `ar09` | Lectura de vídeo acelerada, sin movimiento |
| Luigi | `wf05` | En mantenimiento mínimo; se nombra solo como antecedente de Airflow |

📝 **Dos que se quedan, con matiz, porque "quieto" no es "muerto":** `colorama` lleva años sin
versión **porque está terminado** —resuelve un problema de la consola de Windows que no cambia—
y `aiosmtpd` publica despacio pero responde. El criterio no es la fecha sola: es la fecha **contra
la velocidad del problema que resuelve**. Un envoltorio de FFmpeg parado en 2019 está muerto
porque FFmpeg no lo está; `colorama` no.

> 🧭 **Regla para el resto del inventario, que es lo que hay que llevarse de esta sección:**
> ninguna fase se escribe sin comprobar antes la última publicación de todo lo que nombra, y toda
> tabla de inventario lleva su fecha de verificación en el encabezado. Cuando un track llegue a
> escribirse, esta sección se revisa entera — porque cualquiera de las que hoy están vivas puede
> haberse caído.

---

## 19. El orden de la carta: qué se escribe primero

**Ya no es un ranking de mérito, porque nada se descarta.** Es el orden en que se escribe, y lo
decide la pregunta de §1: **¿le sirve a Áurea?** Lo que tiene encargo en el dominio se escribe
primero —hereda un contexto ya montado y el lector lo usa el lunes—; lo demás se escribe después,
con su propio ejemplo, y se escribe igual de bien.

### 🥇 Primer turno — con encargo directo en Áurea

Estos tienen un problema concreto de la empresa esperándolos, y la sección se escribe casi sola
porque el contexto ya existe.

| Track | El encargo que lo justifica |
|---|---|
| `lg` — legado e intercambio | **RIPS, el XML de la DIAN, el export de Odontovía.** Es el trabajo de Patricia, literalmente |
| `au` — automatización | **Los portales de las aseguradoras no tienen API.** Está en la historia de la empresa, sin inventar nada |
| `co` — comunicaciones | Patricia manda las liquidaciones por correo; dos aseguradoras mandan archivos por FTP |
| `wf` — orquestación | Continuación directa de la Fase 15: el cierre nocturno ya existe y pide esto |
| `qa` — calidad y pruebas | El sistema tiene que sobrevivir tres años con un solo ingeniero. Es la tesis del curso |
| `ob` — observabilidad | El cierre corre a las 2:47 y alguien tiene que enterarse cuando falle |
| `se` — seguridad aplicada | La historia clínica es reservada. No es opcional en el dominio, solo en el temario |
| `tx` — texto y plantillas | Los reportes, los correos y el HTML que Áurea genera todos los meses |
| `ui` — interfaces sin frontend | Entregarle algo a Julián sin contratar un frontend. Absorbe `cl` |
| `db` — sistemas de datos | Parcial: Valkey y Mongo tienen caso; los otros doce son curiosidad legítima |
| `jv` — convivir con la JVM | **Odontovía es Java Swing sobre JBoss.** El sistema heredado no es hipotético |

### 🥈 Segundo turno — encargo real pero no urgente

| Track | Por qué espera |
|---|---|
| `so` — optimización y decisiones | La agenda de diez sedes **es** un problema de asignación, pero Áurea vive sin resolverlo |
| `or` — ORMs | El curso ya eligió SQLAlchemy y funciona; esto es ampliar el mapa |
| `vz` — visualización | El reporte del cierre puede llevar gráficos, y hoy no los lleva |
| `sy` — sistema operativo | Reemplaza scripts de shell que Áurea todavía no tiene |
| `pr` — protocolos y contratos | Hoy REST alcanza; el día que no alcance, esto es lo que hace falta |
| `pk` — gestores | La decisión ya se tomó en la Fase 07. Es mapa del terreno, no necesidad |

### 🥉 Tercer turno — sin encargo en Áurea, y escritos igual

Aquí es donde el encuadre **a la carta** hace su trabajo: estos temas no tienen que justificarse
ante una clínica odontológica. Se escriben con **su propio ejemplo**, el que la herramienta pide.

| Track | El ejemplo que usaría, sin pasar por Áurea |
|---|---|
| `ff` — frontera nativa | Acelerar un cálculo numérico cualquiera y medir el antes y el después |
| `ar` — archivos y multimedia | Convertir, recortar y recomponer archivos de muestra |
| `gi` — geoespacial | Un conjunto de datos abierto con coordenadas |
| `cv` — visión por computador | Rostros propios o sintéticos — y **nunca** fotografía clínica (§13) |
| `ed` — didáctica y juguetes | Una espiral con `turtle`, un juego de veinte líneas. **Y está bien que sea eso** |

> 🧭 **Lo que cambió respecto a la versión anterior de esta sección.** Antes esto era un ranking de
> 1 a 23 con dos tracks tachados —`cl` fusionado y `ed` eliminado—. **`ed` deja de estar
> eliminado:** en una carta no hay por qué eliminar un plato que alguien puede querer pedir. Baja
> al tercer turno, se escribe al final, y su sección de `turtle` dibuja una espiral sin pedirle
> permiso al dominio. La única fusión que se mantiene es `cl` dentro de `ui`, y esa es por
> solapamiento real de contenido, no por prioridad.

---

## 20. Lo que este inventario todavía no resuelve

Dos preguntas menos que antes: la de los prefijos la cierra la §2, y la de **cuántos tracks se
escriben** la cierra el encuadre a la carta — se escriben los que se alcancen, en el orden de la
§19, y la carta queda abierta. Quedan tres:

1. **¿El dominio de Áurea aguanta el primer turno completo?** Once tracks con encargo directo son
   muchos encargos. Algunos están sobrados de material (`lg`, `au`, `co`); otros van a competir por
   el mismo problema —`ob` y `qa` se solapan alrededor del cierre nocturno— y conviene repartirlos
   antes de escribir, no después.
2. **¿Qué se le exige a una sección de la carta?** El camino base pide medición y miniproyecto por
   fase. La §🍽️ dice que aquí **no** son obligatorios, y eso abre una pregunta de calidad que hay
   que contestar con un ejemplo: **la primera sección que se escriba fija el estándar** de qué es
   "un ejemplo que corre y un ejercicio concreto". Recomendación: que la primera sea del primer
   turno y con Áurea detrás, para que el listón quede alto.
3. **¿Quién verifica el estado de las bibliotecas, y cada cuánto?** La §18 retira cinco muertos
   confirmados y sospecha de otros seis sin verificar. Un inventario de este tamaño se pudre solo:
   o cada tabla lleva su fecha de verificación y un guion que la comprueba contra PyPI, o en un año
   este documento vuelve a recomendar código abandonado. **Recomendación: un
   `prompts/check-inventario.py` antes de escribir la primera sección.** Con una carta que puede
   llegar a cien secciones, esto deja de ser higiene y pasa a ser infraestructura.

---

## 21. Temas evaluados y descartados

| Tema | Por qué |
|---|---|
| ML y LLMs como track propio de investigación | Aquí solo entra la IA **aplicada**, y son los complementos `ia` y `ds`. La teoría se declara excluida y no se enlaza a ninguna parte (`alcance-del-proyecto.md` §0) |
| EPUB como fase autónoma | Insuficiente para una fase. Ver §4 |
| Cómputo científico pesado / GPU | Fuera del perfil del lector. ⚠️ El track `so` (§17.7) **no** es esto: modelar restricciones y llamar a un solucionador es otra disciplina y corre en un portátil |
| ~~Criptografía y manejo de secretos~~ | **Revertido en §17.5.** Lo básico sigue absorbido en la fase base 16; lo que no cabía ahí es ahora el track `se`, y la diferencia es que el track lo organiza por *qué pregunta contesta cada primitiva* en vez de por algoritmo |
| Comparar gestores dentro del camino base | El camino base elige uno y sigue. La comparación completa es `pk` |
| Escritorio nativo como track propio | Poca demanda en el dominio y arrastra el problema de distribución. Queda como `ui09`, y es la primera fase que se cae si hay recorte |
| **Blockchain, IoT, robótica** | Fuera del perfil y del dominio. Se nombran para que la exclusión sea explícita. ⚠️ MQTT aparece en `pr06` **como protocolo de mensajería**, no como puerta de entrada al IoT: la distinción hay que sostenerla al escribir la fase |
| **Microservicios como tema** | El curso enseña registros, no arquitecturas de despliegue. Exclusión declarada |

### 🪦 Descartes revertidos

| Tema | Estaba descartado porque… | Por qué entra ahora |
|---|---|---|
| **Cassandra, CouchDB** | "Enseñanza de producto con poco contenido específico de Python" | Reformulados como **modelos de acceso** (§6). El argumento anterior era correcto para la formulación anterior |
| **Email, IMAP, mensajería** | "Cabe como 🔴 desafío de cierre en `au06`" | Da para un track: el problema real no es mandar el correo, es que **llegue** (§10, `co02`) |
| **Criptografía aplicada** | "Se absorbe en la fase base 16" | Cabía lo básico; no cabían identidad delegada, mTLS ni cadena de suministro. Es el track `se` (§17.5) |

> 📝 **Y un descarte que esta revisión hace en dirección contraria:** las bibliotecas abandonadas
> estaban *dentro* del temario como recurso pedagógico, y salen. La §18 explica por qué el
> argumento —"sirve de lección"— no aguanta cuando la lección ya se da en la Fase 00 y el nombre
> muerto es lo único que el lector se lleva.
