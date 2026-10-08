# 🧰 `prompts/` — la maquinaria del curso
## Python para desarrolladores Java senior

Este directorio no es material del curso: es **lo que se usa para escribirlo**. El lector nunca
lo abre. Quien escribe una fase lo lee entero antes de teclear la primera línea.

> ✅ **Estado: el camino base está escrito.** Las **18 fases** —numeradas 00 a 17—,
> `BENCHMARKS.md` e `INSTINTOS.md` están publicados. Para el camino base, este directorio pasa de
> ser el **encargo** a ser el **registro de lo que se decidió y por qué**.
>
> ✅ **Track `ia` cerrado el 13/09/2026** — ocho secciones, su `src/`, sus generadores de datos y
> 134 pruebas. 🚧 **Track `ds` en curso, repartido en ocho tandas (T6–T13)**. Cerradas: **T6**,
> los dos conjuntos de datos; **T7**, `ds01` y `ds02`; **T8**, `ds03`; **T9**, `ds04`; y
> **T10**, `ds05` y `ds06`; **T11**, `ds07`; **T12**, `ds08`; y **T13**, `ds09`. ✅ **El track
> `ds` está completo**: nueve secciones, los dos proyectos de datos cerrados y su ⚖️ veredicto
> escrito en `ds09` §6.1. De las diez mediciones, **nueve están ejecutadas** y una en `⏳` —la de
> `ds05` §6.2, que necesita cinco personas y no un portátil.
> La tabla está más abajo, en *Cómo abrir una sesión de escritura*.
>
> 🚧 **Los complementos `ia` y `ds`.** Diecisiete secciones que
> construyen los cuatro proyectos de IA y de datos de Áurea —NormaRAG, Recepción asistida, Embudo
> y Ausentismo— sobre el código que dejó el camino base. **No son material a la carta:** llevan la
> plantilla de 10 secciones, su medición y su miniproyecto, igual que una fase. Su encargo está en
> [`prompts-de-tracks-ia-ds.md`](prompts-de-tracks-ia-ds.md) y la decisión de forma en
> [`propuestas-fases-base-ia-datos.md`](propuestas-fases-base-ia-datos.md) §0.
>
> **Y después** viene el material **a la carta**: secciones opcionales, sueltas, que se leen cuando
> alguien necesita un tutorial concreto de una herramienta. Su inventario está en
> [`propuestas-temas-opcionales.md`](propuestas-temas-opcionales.md), y **no se rigen por
> las mismas reglas que el camino base** — no se les exige miniproyecto ni medición, y no tienen
> que pasar por el dominio de Áurea. Sus reglas están en la guía §14.
>
> ✅ **La carta, cerrada el 07/10/2026**: 176 secciones `opNNN-<tt>NN-…` en 22 tracks, 173 probadas
> enteras en contenedor y 3 en parte, con su código en `src/opNNN-…/`. El estado, la numeración y
> la bitácora viven en [`plan-de-produccion-carta.md`](plan-de-produccion-carta.md).

---

## 📖 Orden de lectura

Si llegas nuevo a este curso, en este orden y no en otro:

1. **[`alcance-del-proyecto.md`](alcance-del-proyecto.md)** — qué es el curso, para quién, qué
   produce y qué no hace. Incluye la regla de forma que lo define: **no hay apéndices**.
2. **[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md)** — la estructura. §4 tiene la
   numeración oficial de las 18 fases; **§5 tiene el encargo detallado de cada una**; §9 tiene las
   siete decisiones cerradas con su porqué.
3. **[`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md)** — voz, idioma,
   pedagogía, estilo de código, marcadores, la plantilla de 10 secciones, ejercicios, y el
   checklist de cierre.
4. **[`00-historia-de-aurea.md`](../00-historia-de-aurea.md)** — la empresa del curso.
   Fuente de verdad de todo lo narrativo: personajes, cifras, cronología, reglas de negocio.
   **Vive en la raíz del curso, no aquí**: es el único documento narrativo y el lector también
   lo abre, así que se publica con las fases en vez de quedarse en la maquinaria.

Y como referencia, cuando toque:

- **[`plantillas-de-capitulo.md`](plantillas-de-capitulo.md)** — el esqueleto de fase, que se
  sigue literal. Es uno solo: no hay plantilla de apéndice porque no hay apéndices.
- **[`formato-de-miniproyectos.md`](formato-de-miniproyectos.md)** — el miniproyecto obligatorio
  de cada fase, cómo se calibra y su prueba bloqueante.
- **[`formato-de-mediciones.md`](formato-de-mediciones.md)** — el arnés, la forma de una medición
  y las reglas de honestidad.
- **[`contrato-del-cli.md`](contrato-del-cli.md)** — qué gana el CLI de Patricia en cada fase, y
  qué nombres ya están congelados. **Obligatorio antes de escribir cualquier fase entre la 01 y
  la 09, y la 15**, porque el curso se redacta fuera del orden numérico.
- **[`prompts-de-tracks-ia-ds.md`](prompts-de-tracks-ia-ds.md)** — el marco común y los 17 bloques
  de los complementos `ia` y `ds`, con la tabla de secciones y su orden de escritura.

---

## 🚀 Cómo abrir una sesión de escritura

**Primero los tres documentos de la raíz del curso**, en este orden, cada uno en su chat, con el
prompt que le corresponde en
**[`prompts-documentos-raiz.md`](prompts-documentos-raiz.md)**:

1. `0-ESTRUCTURA-CURSO.md`
2. `00-convencion-de-git-y-tags.md`
3. `README.md` del curso

`00-historia-de-aurea.md` también vive en la raíz, pero no sale de aquí: se escribió antes que
todo lo demás y es la fuente narrativa, no un entregable encargado por `prompts-documentos-raiz.md`.

**Después las fases**, una por chat. El prompt se arma copiando dos cosas de
**[`prompts-de-fase.md`](prompts-de-fase.md)**: el **§ Marco común** y el bloque de esa fase.

El orden de escritura recomendado, y no es el orden de los números:

| Turno | Qué | Por qué |
|---|---|---|
| 1 | Fases **00** y **01** | Fijan el ambiente, la voz, el registro y la forma del CLI que seis fases arrastran |
| 2 | Fases **07** y **09** | Las ⭐ de la tesis. Son las que más pueden obligar a reescribir el Bloque A, y descubrirlo tarde sale caro |
| 3 | Resto del **Bloque A** (02-06) | Con la frontera ya escrita, se sabe hacia dónde tienen que apuntar |
| 4 | **08**, y luego el **Bloque C** (10-16) | En orden, porque cada proyecto crece sobre el anterior |
| 5 | Fase **17**, y después `BENCHMARKS.md` e `INSTINTOS.md` | El cierre necesita todas las mediciones hechas |
| 6 | Los complementos **`ia01`–`ia08`** y **`ds01`–`ds09`**, en ese orden | Construyen los cuatro proyectos de IA y datos sobre el código del camino base. El prompt sale de `prompts-de-tracks-ia-ds.md` |
| 7 | **La carta**, una tanda por track | Se retoma por la línea «Dónde está» del plan de la carta; las reglas están en la guía §14 y el esqueleto en `plantillas-de-capitulo.md` |

### Las tandas del turno 6

Una tanda es **un chat**. El turno 6 es demasiado grande para uno solo, así que se parte en
catorce: **T0–T5 son el track `ia`, y están cerradas**; **T6–T13 son el track `ds`**.

| Tanda | Qué produce | Por qué esa frontera |
|---|---|---|
| T0–T5 ✅ | El track `ia` entero: `ia01`–`ia08`, su `src/`, sus generadores y 134 pruebas | Cerradas el 13/09/2026 |
| **T6** ✅ | **Maquinaria de datos**, cerrada el 13/09/2026: los dos generadores, sus dos `README.md` y **50 pruebas** que corren sin dependencias. Encargaba los dos conjuntos seudonimizados con semilla fija —Embudo en `src/ds01-…/`, Ausentismo en `src/ds07-…/`—, su esquema congelado y sus pruebas, **sin prosa publicada** | `ds01`–`ds06` leen el mismo conjunto. Si el esquema cambia en `ds04`, hay que reescribir tres secciones. En `ia` esto se pagó caro: la colisión de nombres del generador de corpus hizo que el manifiesto mintiera |
| **T7** ✅ | `ds01` + `ds02`, cerradas el 13/09/2026: 1.442 líneas de prosa, **19 pruebas nuevas** y **las dos mediciones ejecutadas** en el entorno de referencia | Fijan el registro del track y el arnés de memoria que `ds03` reutiliza. La tesis de `ds02` es la respuesta a la de `ds01` |
| **T8** ✅ | `ds03`, cerrada el 13/09/2026: **dos** tablas medidas —la consulta y el informe de punta a punta— con ganadores distintos, y 11 pruebas | Sola: cuatro motores por cuatro tamaños es la medición más cara del track, y puede obligar a matizar `ds02` |
| **T9** ✅ | `ds04`, cerrada el 13/09/2026: **cuatro** modelos de atribución, su medición con intervalo bootstrap y 23 pruebas | Solo: importa las tres anteriores y sostiene dos atribuciones sobre los mismos datos |
| **T10** ✅ | `ds05` + `ds06`, cerradas el 13/09/2026: la medición de render en cuatro opciones, la de contraste de la paleta, la auditoría de cuadernos y 30 pruebas | `ds06` mide los cuadernos que producen `ds04` y `ds05`. Cierran el bloque Embudo |
| **T11** ✅ | `ds07`, cerrada el 13/09/2026: dos líneas base, cuatro tablas medidas y 38 pruebas | Sola: fija la línea base que `ds08` tiene que vencer. Escribirla junto a `ds08` la contamina |
| **T12** ✅ | `ds08`, cerrada el 13/09/2026: la red gana por 0,0125 de AUC y **una columna a mano la iguala**; cinco tablas y 14 pruebas | Solo: `torch` en CPU y la ética en el cuerpo del capítulo |
| **T13** ✅ | `ds09` + el ⚖️ veredicto del track, cerrada el 13/09/2026: 10 pruebas y la novena medición ejecutada | El ⚖️ veredicto necesita todas las mediciones hechas, y arrastra `BENCHMARKS.md`, `INSTINTOS.md`, el `README.md` del curso y `0-ESTRUCTURA-CURSO.md` |

📝 **Dos decisiones que T6 cierra** y que ninguna sección posterior reabre: los tamaños grandes de
la medición de `ds01` **son sintéticos y se declara** —Áurea hace 3.900 citas al mes, y el archivo
grande del camino base tiene 500.000 filas—; y los generadores **escriben archivos a `data/`**,
de modo que las demás secciones leen archivos y **no importan módulos de otro directorio de
sección**.

---

## 🗂️ Qué es cada archivo

| Archivo | Qué es | Manda sobre |
|---|---|---|
| `alcance-del-proyecto.md` | Encuadre y versiones. **Su §0 fija que el curso es autocontenido** | Todo. Es el techo |
| `propuesta-fases-y-alcance.md` | Estructura y alcance por fase | La guía de estilo y las plantillas |
| `guia-de-estilo-y-convenciones.md` | Voz, código y forma | Las plantillas y los formatos |
| `plantillas-de-capitulo.md` | El esqueleto de fase | — |
| `formato-de-miniproyectos.md` | La sección 7 de cada fase | — |
| `formato-de-mediciones.md` | La sección 6 y `BENCHMARKS.md` | — |
| `../00-historia-de-aurea.md` | La empresa del curso, y la única. **Está en la raíz, publicada** | Todo lo narrativo |
| `prompts-documentos-raiz.md` | Los 3 prompts de la raíz | — |
| `prompts-de-fase.md` | El marco común + los 18 prompts del camino base | — |
| `prompts-de-tracks-ia-ds.md` | El marco común + los 17 prompts de `ia` y `ds` | Las 17 secciones complementarias |
| `contrato-del-cli.md` | La forma del CLI fase por fase, congelada | Las fases 01-09 y 15 |
| `pendientes-a-futuro.md` | Los 📌 que cada fase y sección de `ia`/`ds` traía al final, sacados de lo publicado el 07/10/2026, con su revisión y la lista de lo que no se puede resolver todavía | Lo que se escriba después |
| `plan-de-produccion-carta.md` | El plan de la carta: tandas, estado, numeración `opNNN`, bitácora y directorios de `zz-code/` | El orden y el estado de la carta |
| `inventario-verificado.md` | Las versiones de PyPI por track, verificadas; lo genera `check-inventario.py` | Toda versión que nombra una sección de la carta |
| `check-inventario.py` | Consulta PyPI y regenera el inventario (`python3 prompts/check-inventario.py <tt>`) | — |
| `verificador_base.py` · `verificar-corpus.py` | El verificador de los lineamientos del repositorio y la subclase del curso, con los chequeos de la carta (`python3 prompts/verificar-corpus.py`) | — |

### Material que **no** manda

- `propuestas-temas-opcionales.md` — exploratorio: el inventario de los tracks a la carta, que se
  escriben **después** de los complementos. **Pierde contra `propuesta-fases-y-alcance.md` en
  cualquier contradicción.**
- `propuestas-fases-base-ia-datos.md` — mixto, y conviene saber qué mitad es cuál: su **§0 sí
  manda** —es la decisión de nombres, tags y forma de los complementos `ia` y `ds`—, y sus §5 y §6
  son el alcance temático de esas diecisiete secciones. Su §4, las 21 fases del camino base, está
  superada y se conserva como registro.
- 🪦 **La historia de la empresa alternativa ya no está en esta carpeta.** Se evaluó durante la
  discusión de fases, se descartó frente a Áurea, y se conservaba "por si acaso". Salió al hacerse
  el curso autocontenido: material que ninguna fase cita es peso muerto que alguien va a leer por
  error (`alcance-del-proyecto.md` §0).

---

## 🧹 Las tres configuraciones de la raíz del curso

Desde el 13/09/2026 la raíz del curso lleva tres archivos de herramienta, y los tres existen
para que una promesa del material sea verdad y no una intención:

| Archivo | Qué sostiene |
|---|---|
| `ruff.toml` | La misma selección que imprime la Fase 00 —`E, F, I, UP, B`, línea de 100—, más `src = ["src/*"]` porque **cada carpeta de `src/` es un proyecto independiente** y sus módulos vecinos son de primera parte, y un `exclude` de lo que generan los scripts |
| `pytest.ini` | Registra el marcador `network` y **lo deselecciona por defecto**. Sin esto, `pytest` no lo conocía, lo avisaba como desconocido y ejecutaba igual las dos pruebas de `ia01` que llaman a la API: fallan sin credenciales y cuestan dinero con ellas |
| `.gitignore` | Lo que generan los scripts —`data/`, `modelos/`, `salida/`, `cuadernos/`— y los artefactos de modelo. Cada `README.md` de `src/` decía "los archivos generados no se versionan" y nada lo hacía cumplir |

🪦 **La deuda de lint quedó pagada.** Al aplicar `ruff.toml` sobre `src/` aparecieron **17
avisos en código ya publicado** —dos `E702` en la Fase 13, seis `E501`, dos `I001`, dos `F401`,
dos `B905` y dos `F821` con su `UP037` en `ia03` e `ia08`—. Se corrigieron todos, **junto con
las tres líneas que sus capítulos transcribían** (`13-integraciones.md`,
`ia03-tool-calling-y-el-bucle-de-agente.md` y `ia06-evaluacion.md`), que era la razón por la que
se habían aplazado. Dos de los arreglos no eran cosméticos: el `agenda` de `ia03` era una
anotación suelta que **no creaba el nombre** —el módulo importaba bien y reventaba con
`NameError` en la primera llamada de la herramienta—, y los dos `zip()` sin `strict=` eran el
mismo defecto que `ds01` §5.3 enseña a no cometer.

📝 El lint se corre **desde dentro de cada directorio de `src/`** o desde la raíz del curso: con
`src = ["src/*"]` las dos formas dan el mismo resultado.

---

## ⚠️ Las tres cosas que más se rompen al escribir

1. **Explicar lo que el lector ya sabe.** Es un dev Java senior. Cada párrafo sobre qué es una
   excepción, un mapa o HTTP se borra, aunque esté bien escrito.
2. **Escribir fuera del registro de la fase.** Una clase con capas en el Bloque A es el error que
   el curso enseña a no cometer, cometido en el propio material.
3. **Afirmar sin número.** Ni "más rápido", ni "más liviano", ni "sale más barato". Si la medición
   no existe, se escribe la frase sin el comparativo.
