# 🤖📊 Prompts de los complementos `ia` y `ds`
## Python para desarrolladores Java senior

> **Qué es esto.** El encargo de las **diecisiete secciones complementarias** que construyen los
> cuatro proyectos de IA y de datos de Áurea. Es al material `ia`/`ds` lo que
> [`prompts-de-fase.md`](prompts-de-fase.md) es al camino base, y se usa igual: **un chat, un
> archivo**.
>
> **Estos tracks no son la carta.** No llevan `op`, no se leen sueltos y no se les perdona la
> medición ni el miniproyecto. La decisión, con su tabla comparativa y su costo, está en
> [`propuestas-fases-base-ia-datos.md`](propuestas-fases-base-ia-datos.md) **§0**.

**Cómo se arma el prompt:** se copia el **§ Marco común** de este archivo y, debajo, el bloque de
la sección que toca. Los dos juntos son el prompt completo. Los bloques son cortos a propósito:
el alcance temático de cada sección está en `propuestas-fases-base-ia-datos.md` §5 y §6, y el
encargo de negocio en `00-historia-de-aurea.md` §7 y §8. Lo que agrega cada bloque es lo
que allí no está — **qué se decide en ese chat, contra qué se mide, y qué le entrega a la
siguiente**.

---

## 🗺️ Las diecisiete secciones

> ✅ **El track `ia` está escrito y cerrado el 13/09/2026:** las ocho secciones con su `src/`, sus
> generadores de datos con semilla fija y **134 pruebas que corren sin red, sin modelo y sin
> Postgres**. Las mediciones están en `⏳` con su spec completa, salvo la fila léxica de `ia07`, que
> no llama al modelo y sí tiene número.
>
> ✅ **El track `ds` está completo (13/09/2026).** T6 dejó los dos conjuntos de datos; T7
> escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`; T11, `ds07`; T12,
> `ds08`; T13, `ds09` y el ⚖️ veredicto. **Nueve de las diez mediciones están ejecutadas** —no cuestan dinero ni API— y sus entradas
> están en `BENCHMARKS.md`. La de `ds03` son **dos tablas con ganadores distintos**: la consulta
> con el motor caliente y el informe de punta a punta. La de `ds04` no mide tiempo: mide **cuánto
> cambia la respuesta al negocio** según el modelo de atribución, y da 7,5×. **La única en `⏳`
> del track es la §6.2 de `ds05`**, que necesita cinco personas y no un portátil. **La línea
> base que `ds08` tenía que vencer quedó en 0,799 de AUC, y **la red la venció por 0,0125 — lo
> mismo que vale una columna de interacción escrita a mano**, que es el veredicto de `ds08`. Y
> `ds09` cierra con el del track entero: **los dos proyectos de datos valían la pena y casi
> ninguna de las herramientas modernas que se les asocian era necesaria**, con el umbral de cada
> veredicto escrito. **Lo único pendiente del track es la medición §6.2 de `ds05`.**
>
> El único insumo que no se puede generar es `juicios_humanos.jsonl` de `ia06`, y `bench_judges.py`
> se niega a correr sin él.

| Archivo | Sección | Proyecto de Áurea | Su medición 📏 |
|---|---|---|---|
| `ia01-el-modelo-de-acceso-de-un-llm.md` ✅ | El modelo de acceso de un LLM | — | Costo y latencia de la misma pregunta, tres modelos |
| `ia02-salida-estructurada.md` ✅ | Salida estructurada y contratos | NormaRAG | Reintentos por cien extracciones, tres estrategias |
| `ia03-tool-calling-y-el-bucle-de-agente.md` ✅ | Tool calling y el bucle | Recepción asistida | Turnos y tokens por reserva completada |
| `ia04-embeddings-y-busqueda-semantica.md` ✅ | Embeddings y búsqueda | NormaRAG | Recuperación: `pgvector` ⇄ texto completo de Postgres |
| `ia05-normarag.md` ✅ | **Proyecto · NormaRAG** | NormaRAG | Precisión de cita y costo por respuesta |
| `ia06-evaluacion.md` ✅ | Evaluación y regresiones | NormaRAG | Acuerdo juez-LLM ⇄ humano, y su costo |
| `ia07-recepcion-asistida.md` ✅ | **Proyecto · Recepción asistida** | Recepción asistida | Tasa de escalamiento correcto ante síntoma |
| `ia08-produccion-y-el-veredicto.md` ✅ | Producción y ⚖️ veredicto | los dos | Caché de prompt: ahorro real sobre tráfico de un día |
| `ds01-numpy-y-el-modelo-vectorizado.md` ✅ | NumPy y el modelo vectorizado | Embudo | Bucle ⇄ vectorizado, por tamaño — **ejecutada** |
| `ds02-pandas.md` ✅ | pandas y el modelo de DataFrame | Embudo | Memoria de un `join` mal hecho, antes y después — **ejecutada** |
| `ds03-polars-y-el-modelo-lazy.md` ✅ | Polars y el modelo lazy | Embudo | pandas ⇄ Polars ⇄ DuckDB ⇄ bucle, cuatro tamaños — **ejecutada, y son dos tablas** |
| `ds04-embudo.md` ✅ | **Proyecto · Embudo** | Embudo | Costo por paciente adquirido, por canal — **ejecutada, cuatro modelos con intervalo** |
| `ds05-visualizacion.md` ✅ | Visualización | Embudo | Tiempo hasta la primera decisión correcta — **⏳, necesita personas**; sí se ejecutó la de render y contraste |
| `ds06-notebooks-y-reproducibilidad.md` ✅ | Cuadernos y reproducibilidad | Embudo | Reejecución limpia: cuántos cuadernos sobreviven — **ejecutada: 2 de 6** |
| `ds07-scikit-learn.md` ✅ | scikit-learn y la línea base honesta | Ausentismo | Regla de tres variables ⇄ regresión logística — **ejecutada: 0,672 ⇄ 0,799** |
| `ds08-ausentismo.md` ✅ | **Proyecto · Ausentismo** | Ausentismo | Red neuronal ⇄ la línea base de `ds07` — **ejecutada: la red gana 0,0125 y una columna a mano la iguala** |
| `ds09-servir-el-modelo.md` ✅ | Servir el modelo y ⚖️ veredicto | Ausentismo | Latencia en la API: `pickle` ⇄ ONNX — **ejecutada: la latencia no era el argumento** |

**El orden de escritura es el de la tabla**, y no admite atajos por una razón concreta: `ia05` y
`ia07` importan lo que dejaron las cuatro secciones anteriores, y `ds08` no se puede escribir
antes que `ds07` porque su tesis es *la línea base le gana*.

---

## § Marco común

*Se copia tal cual al inicio de cada chat de sección `ia` o `ds`.*

````markdown
Este es un chat del curso *Python para desarrolladores Java senior*, y redacta **una sección
complementaria** de los tracks `ia` o `ds`. Produce **un solo archivo `.md`** y, cuando la
sección traiga código ejecutable, su directorio `src/<mismo nombre>/`. Nada más.

## Qué son estos tracks, y qué no

No son material a la carta. Son **la continuación del camino base sobre los proyectos de IA y
datos de Áurea**: NormaRAG, Recepción asistida, Embudo y Ausentismo. El lector llega aquí con
las 18 fases hechas, con `aur`, AgendaAPI, Consultorio y Cartera en su disco, y con el arnés de
medición de la Fase 02 funcionando. **Se apoya en todo eso y no lo reexplica.**

Por lo tanto: **plantilla de 10 secciones completa, medición obligatoria y miniproyecto
obligatorio**, exactamente como una fase base.

## Fuentes de verdad, en este orden

1. `prompts/alcance-del-proyecto.md` — el techo. Su **§0** fija que el curso es autocontenido y
   no hereda reglas de fuera de esta carpeta; su **§9** tiene **las versiones fijadas**, incluida la segunda
   tabla, la de estos dos tracks. Ninguna versión se pone de memoria.
2. `prompts/propuestas-fases-base-ia-datos.md` — **§0 manda sobre nombres, tags y forma**; §5 y
   §6 tienen el alcance temático de cada sección.
3. `prompts/guia-de-estilo-y-convenciones.md` — voz, código, marcadores, ejercicios.
4. `prompts/plantillas-de-capitulo.md` — las 10 secciones, en orden, sin extras.
5. `prompts/formato-de-miniproyectos.md` y `prompts/formato-de-mediciones.md`.
6. `00-historia-de-aurea.md`, en la **raíz del curso** — **§5 (la historia clínica), §7 (los dos
   proyectos de IA) y §8 (los dos de datos)** son el encargo literal.
7. Las 18 fases del camino base, que son código que ya existe y que no se reescribe.
8. Las secciones anteriores del mismo track.
9. Las decisiones explícitas de este chat.

`prompts/propuestas-temas-opcionales.md` **no cuenta** aquí: gobierna la carta opcional, que es
otra cosa.

## Las nueve reglas que más se rompen aquí

Las siete del camino base siguen vigentes —no explicar lo que un dev Java senior ya sabe, código
en inglés con comentarios en español, cada analogía con su límite, ninguna afirmación
comparativa sin número, el miniproyecto que no se resuelve copiando la sección, y ningún
apéndice—. Estas dos son propias de estos tracks, y son las que hunden una sección de IA:

- **La frontera clínica no se cruza, y se nombra cada vez que se roza.** Ningún dato clínico
  identificable sale hacia un servicio externo, en ningún ejemplo, ejercicio ni miniproyecto.
  NormaRAG trabaja sobre corpus **documental y contractual**; Recepción asistida ve agenda y
  tarifas, nunca odontograma; `ds` trabaja sobre un conjunto **seudonimizado**, y la sección que
  lo use tiene que decir por qué *"le quité el nombre"* no es anonimizar cuando quedan fecha de
  nacimiento, sede y fecha de cita. Cuando el ejemplo necesite tocar algo sensible, corre en
  **Ollama local** y el texto explica que esa es justamente la razón.
- **El no determinismo se trata como una propiedad del sistema, no como un defecto.** Este
  lector viene de un mundo donde la misma entrada da la misma salida y donde una prueba que
  falla una de cada veinte veces es una prueba rota. Aquí eso es lo normal, y la respuesta no es
  `temperature=0` sino evaluación, contratos y guardrails. Cualquier sección que prometa
  determinismo está mal escrita.

Y tres reglas de honestidad que este material necesita más que ninguno:

- **Ningún número de costo, latencia o calidad se inventa.** Se escribe la medición completa
  —hipótesis, condiciones, competidor, comando— y la tabla va con `⏳` celda por celda hasta que
  alguien la corra de verdad. El veredicto separa **la expectativa** del **umbral por
  determinar**. Un número inventado en un curso que se define por medir es el peor error posible.
- **El precio del modelo lleva su fecha.** Es el dato que más rápido envejece del curso.
- **El competidor no es de paja.** Contra un LLM compite la consulta SQL que ya funcionaba;
  contra una red neuronal, la regresión logística de cinco variables; contra un framework de
  agentes, cincuenta líneas de bucle. Y muy a menudo el competidor gana: cuando gane, se escribe.

## Coherencia de la ficción

La empresa es **Áurea**, red odontológica de diez sedes. Los cuatro proyectos de estos tracks ya
están definidos en la historia y **no se reinventan**: NormaRAG contesta qué cubre cada
prepagada citando documento, versión y cláusula, o no contesta; Recepción asistida atiende los
900 mensajes diarios de WhatsApp y **escala ante cualquier síntoma**; Embudo mide el costo de
adquisición por canal y el valor real de la red de aliados; Ausentismo predice la inasistencia
del 19% y **abre la discusión ética de qué se hace con esa predicción**. La cronología es fija y
el lector está en 2026.

## Cierre

La sección termina con el bloque 🏷️ de forma fija, adaptado al track:

    git tag -a ia-fase-04 -m "ia04 cerrada: <el checklist, en una línea por ítem>"

con `ia-mini-04` para el miniproyecto y su número en el mensaje. Commits `ia 04: …`,
`ia 04 ej12: …`, `ia 04 mini: …`. Después, fuera de lo que lee el estudiante, van los 📌
Pendientes.
````

---

# Track `ia` · la IA aplicada

## # ia01 — El modelo de acceso de un LLM

**Qué se decide en este chat.** El registro entero del track: **un LLM es una dependencia de red,
cara, lenta y no determinista**, y todo lo demás sale de ahí. Fija el cliente, el manejo de
errores, el conteo de tokens, el presupuesto y la primera medición de costo del curso.

**Cuidado con.** Es la sección donde más tienta explicar qué es un transformador. No entra: el
lector no va a entrenar nada, va a **consumir un servicio**, y lo que necesita es el modelo de
costo, el de latencia y el de fallo. La analogía correcta es una API de terceros con tarifa por
byte y SLA blando, y hay que decir dónde se rompe: no hay caché HTTP, la misma petición cuesta
distinto según lo que le mandes de historia, y la respuesta correcta de ayer puede no serlo hoy.

**Le entrega a la siguiente.** El cliente configurado, el patrón de reintento con `tenacity`, la
función que cuenta tokens antes de gastar, y la tabla de costo por millón con su fecha.

**Su medición.** La misma pregunta de Patricia contra tres modelos —Opus 5, Haiku 4.5 y un modelo
local en Ollama— midiendo latencia p50/p95, tokens de entrada y salida, y costo. El veredicto
tiene que llegar hasta el umbral: a partir de qué volumen mensual de preguntas deja de dar igual.

## # ia02 — Salida estructurada y el contrato del modelo

**Qué se decide en este chat.** Cómo se le pide a un modelo algo que un programa pueda consumir:
`output_config.format`, `strict: true` en las herramientas, y Pydantic como el contrato que ya
existe en el curso desde la Fase 10. El puente con lo que el lector ya sabe es directo y hay que
usarlo: **es la misma validación en el borde de FastAPI, con el modelo del otro lado.**

**Cuidado con.** El reflejo de este perfil es tratar la salida como si fuera un DTO deserializado
y confiar. Aquí la validación falla de verdad y con frecuencia, y la sección tiene que enseñar el
bucle de reintento con el error de validación **devuelto al modelo como contexto** — que es la
parte que nadie escribe la primera vez.

**Su medición.** Cien extracciones de datos de una circular de aseguradora, tres estrategias
—texto libre y parseo, JSON pedido en el prompt, y salida estructurada con esquema—, midiendo
tasa de éxito al primer intento, reintentos y costo total.

## # ia03 — Tool calling y el bucle de agente

**Qué se decide en este chat.** Que un agente es **un bucle `while` con un `switch`**, y que eso
se puede escribir en cincuenta líneas antes de decidir si hace falta algo más. Las herramientas
son las funciones que el curso ya tiene: consultar disponibilidad en AgendaAPI, buscar tarifa,
crear una reserva.

**Cuidado con.** Dos cosas. La primera, que el bucle a mano se escribe **antes** que el
`tool_runner` del SDK, porque el lector tiene que ver el mecanismo para poder depurarlo después.
La segunda, la herramienta que muta estado: reservar dos veces la cita de las 3:40 es el mismo
problema de idempotencia de la Fase 13, y aquí se cobra.

**Su medición.** Turnos, tokens y latencia hasta completar una reserva, con y sin herramientas
bien descritas. La lección medible: la descripción de la herramienta es prompt, y una mala
descripción cuesta dos turnos más.

## # ia04 — Embeddings, búsqueda semántica, y cuándo Postgres gana

**Qué se decide en este chat.** Cómo se recupera el fragmento correcto, y **la sección más
incómoda del track**: contra `pgvector` compite la búsqueda de texto completo de PostgreSQL, que
ya está instalada desde la Fase 11, no agrega dependencia y a veces gana.

**Cuidado con.** No convertir esto en un tutorial de bases de datos vectoriales. El eje es el
**modelo de acceso**: similitud aproximada contra coincidencia léxica, y qué pregunta contesta
bien cada una. El caso de Áurea lo demuestra solo — *"¿cubre el retiro de brackets?"* es léxico,
y *"¿qué pasa si el paciente cambia de plan a mitad del tratamiento?"* no lo es.

**Su medición.** Recuperación sobre un conjunto de cincuenta preguntas reales de Patricia:
`pgvector` con HNSW, texto completo con `ts_rank`, y el híbrido. Precisión en el top-5, latencia y
costo de indexación. `rank-bm25` **no** compite: está abandonado desde 2022 y eso se dice.

## # ia05 — Proyecto · NormaRAG

**Qué se decide en este chat.** El primero de los dos proyectos de IA, completo y corriendo. El
requisito duro es del negocio y no se negocia: **cada respuesta cita documento, versión y
cláusula, o no se emite.** Ese requisito es el que obliga a hacer bien la ingesta, el troceado y
la atribución.

**Cuidado con.** El corpus es **documental y contractual** —contratos con aseguradoras, anexos
tarifarios, circulares, manual de glosas—, nunca clínico, y la sección lo dice en voz alta. Y con
el troceado: es donde se pierde la cita, porque un fragmento sin su encabezado de cláusula ya no
se puede citar.

**Su medición.** Precisión de la cita sobre el conjunto de evaluación —¿la cláusula citada
contiene de verdad la respuesta?—, costo por respuesta y latencia p95. Con `⏳` hasta que se corra.

## # ia06 — Evaluación, regresiones y el juez que también se equivoca

**Qué se decide en este chat.** Cómo se sabe que un cambio mejoró algo. Conjunto de evaluación,
métricas, jueces-LLM, y el `pytest` que corre contra el modelo sin volverse intermitente.

**Cuidado con.** Este perfil sabe de pruebas, así que la sección tiene que ir directo a lo que
difiere: una prueba no determinista se escribe con umbral y con `n` ejecuciones, el juez es un
modelo que también falla y hay que medirlo contra un humano, y el conjunto de evaluación es un
activo que se versiona. La analogía con la prueba de regresión sirve, y se rompe en que aquí el
verde y el rojo son una distribución.

**Su medición.** Acuerdo entre el juez-LLM y treinta juicios humanos sobre las mismas respuestas,
más el costo de evaluar. Si el acuerdo es bajo, la sección se escribe alrededor de ese resultado.

## # ia07 — Proyecto · Recepción asistida

**Qué se decide en este chat.** El segundo proyecto: el agente que ayuda con los 900 mensajes
diarios. Usa las herramientas de `ia03`, la salida estructurada de `ia02` y la evaluación de
`ia06`.

**Cuidado con.** El guardrail no es decorativo, es **legal y profesional**: nunca da consejo
clínico, nunca promete un resultado estético, y ante cualquier síntoma escala a una persona. La
sección se evalúa contra ese límite tanto como contra su utilidad, y el diseño correcto es que el
escalamiento sea **la salida por defecto** ante la duda, no la excepción. Y una decisión de
producto que hay que escribir: el agente **propone** y una persona confirma, porque un agente que
reserva solo es un agente que cancela solo.

**Su medición.** Sobre un conjunto de mensajes reales seudonimizados: cuántos resuelve sin
intervención, cuántos escala correctamente ante síntoma —y **cuántos deja pasar**, que es la
métrica que importa—, y el costo por conversación.

## # ia08 — Producción, y el ⚖️ veredicto del track

**Qué se decide en este chat.** Lo que hace falta para que esto no explote en producción —caché
de prompt, límites de tasa, presupuesto por usuario, observabilidad del gasto, y qué se registra
de una conversación sin guardar lo que no se puede guardar— y el veredicto: **cuándo NO usar un
LLM**.

**Cuidado con.** El veredicto tiene que ser específico de Áurea y llevar sus números. Los
candidatos ya están servidos: la pregunta que contesta un `SELECT`, la extracción que resuelve
una expresión regular sobre un formato fijo, y la clasificación de cien casos al mes que sale más
barata con una regla y una persona. Aquí también va la comparación honesta de frameworks
—LangChain, LlamaIndex, Pydantic AI, o ninguno—, con la conclusión escrita de antemano y sujeta a
que la medición la desmienta.

**Su medición.** Ahorro real de la caché de prompt sobre el tráfico de un día de NormaRAG, con
`cache_read_input_tokens` como evidencia. Y la tabla de cierre del track: costo mensual de los dos
proyectos al volumen real de Áurea.

---

# Track `ds` · la ciencia de datos aplicada

## # ds01 — NumPy y el modelo vectorizado

**Qué se decide en este chat.** El modelo mental que ordena el track: **el bucle es el enemigo, y
tiene un tamaño a partir del cual lo es**. Arreglos, dtypes, broadcasting, vistas contra copias.

**Cuidado con.** El reflejo de este perfil no es escribir un bucle malo: es escribir un bucle
**correcto y legible**, que en Java habría sido lo adecuado. La sección tiene que honrar eso y
mostrar el umbral exacto donde deja de serlo, no ridiculizarlo. Y con las vistas: `a[1:3] = 0`
modifica el original, que es la primera sorpresa de quien viene de copias defensivas.

**Su medición.** El mismo cálculo —el costo por paciente adquirido, sobre el histórico de pauta—
en bucle de Python, en `list comprehension` y vectorizado, a 1.000, 100.000 y 5.000.000 de filas.
El veredicto es el umbral.

## # ds02 — pandas y el modelo de DataFrame

**Qué se decide en este chat.** El índice, la alineación automática, los tipos que cambian solos,
y por qué `SettingWithCopyWarning` no es un capricho. El puente honesto: **un DataFrame no es una
tabla y no es una lista de objetos**; es lo más parecido a una hoja de cálculo con álgebra
relacional encima, y ahí es donde se rompe la analogía con SQL.

**Cuidado con.** Es la sección con más superficie para explicar de más. Solo entra lo que produce
un error o una factura: el `join` que multiplica filas, el `apply` que recorre fila por fila, el
`object` dtype que se come la memoria, y la mutación encadenada.

**Su medición.** Memoria pico y tiempo de un `merge` sobre las citas de la red, hecho mal y hecho
bien, con `tracemalloc` y el arnés de la Fase 02.

## # ds03 — Polars, DuckDB y el modelo lazy

**Qué se decide en este chat.** El modelo perezoso —plan, optimización, ejecución— y la
comparación de cuatro esquinas que da el veredicto más útil del track.

**Cuidado con.** La conclusión incómoda está anunciada en la propuesta y hay que sostenerla si
sale: **a cinco mil filas, el bucle a mano gana y la diferencia es irrelevante**. Áurea tiene
3.900 citas al mes; el track completo se puede correr en un portátil, y decirlo es parte de la
honestidad del curso.

**Su medición.** La consolidación mensual de las diez sedes en pandas, Polars (lazy), DuckDB sobre
Parquet y bucle de Python puro, a cuatro tamaños. Tiempo, memoria pico y líneas de código.

## # ds04 — Proyecto · Embudo

**Qué se decide en este chat.** El primero de los dos proyectos de datos: limpieza, `join` entre
fuentes que no comparten llave, series temporales y estacionalidad. Y la segunda pregunta de
plata: **cuánto vale de verdad la red de aliados**.

**Cuidado con.** El veredicto está escrito en la historia y hay que llegar hasta él: **la
atribución de marketing es, en buena medida, una mentira que se cuenta con gráficos bonitos**.
La sección lo demuestra con el mismo conjunto de datos y dos modelos de atribución que dan
respuestas distintas, no lo afirma. Y con el ingreso: llega en cuotas durante veinticuatro meses,
así que *"ventas del mes"* no significa lo que parece — eso es contenido, no nota al pie.

**Su medición.** Costo por paciente adquirido por canal y por sede, con su intervalo, y la
comparación de las dos atribuciones sobre los mismos datos.

## # ds05 — Visualización, y cuándo una tabla gana

**Qué se decide en este chat.** matplotlib, plotly y altair sobre el mismo tablero, con el
criterio de cuál sirve para qué: figura para un informe, interactivo para explorar, declarativo
para una gramática que se sostiene.

**Cuidado con.** Marcela va a rechazar un tablero por el color de una barra y **no le falta
razón**: es la marca. La sección tiene que tratar la legibilidad como requisito, no como adorno.
Y el veredicto: para las siete cifras del comité de franquicia, una tabla bien hecha gana.

**Su medición.** Tiempo hasta la primera decisión correcta con cinco personas del entorno del
lector, sobre la misma información presentada como tabla, como barras y como interactivo. Se
declara que es una muestra de cinco y que eso es anecdótico salvo por el orden de magnitud.

## # ds06 — Cuadernos y reproducibilidad

**Qué se decide en este chat.** Jupyter, marimo y papermill, y el veredicto sobre cuadernos en
producción. El estado oculto —celdas ejecutadas fuera de orden— es el problema real, y marimo
existe para resolverlo.

**Cuidado con.** Este lector tiene un prejuicio contra los cuadernos que es **medio correcto**, y
la sección tiene que separar la mitad buena de la mala en vez de darle la razón o quitársela
entera.

**Su medición.** De los cuadernos que produjo `ds04`, cuántos reejecutan limpio de arriba abajo en
una máquina nueva. Es la medición más barata del curso y la más reveladora.

## # ds07 — scikit-learn y la línea base honesta

**Qué se decide en este chat.** El flujo completo —`Pipeline`, división temporal, validación,
métricas— y la disciplina que lo sostiene: **primero la línea base, siempre**. Fuga de datos con
su ejemplo concreto: usar la asistencia futura para predecir la asistencia.

**Cuidado con.** La división no es aleatoria, es **temporal**: predecir el pasado con datos del
futuro infla cualquier métrica y es el error que más se comete en este dominio.

**Su medición.** Una regla de tres variables —historial de inasistencia, día y hora— contra una
regresión logística de cinco, sobre el mismo corte temporal. AUC, precisión y recall, y **cuánto
cuesta mantener cada una**.

## # ds08 — Proyecto · Ausentismo

**Qué se decide en este chat.** El segundo proyecto de datos, y la tesis del track: **la red
neuronal probablemente pierde, y hay que aceptarlo con la medición delante**. PyTorch en CPU,
minutos de entrenamiento, y la comparación contra la línea base de `ds07`.

**Cuidado con.** La discusión ética no es un párrafo de cierre, es una sección del cuerpo:
recordarle más al paciente señalado es legítimo, llamarlo el día anterior también, **darle peor
horario porque el modelo lo señaló no lo es**, y esa línea se dibuja antes de que alguien la
cruce. Y el sobreagendamiento del jueves a las cuatro tiene un costo cuando el modelo se
equivoca: dos pacientes en la misma silla es peor que una silla vacía.

**Su medición.** Red neuronal contra la línea base: AUC, calibración, tiempo de entrenamiento,
tamaño del artefacto y **horas-persona anuales de mantenimiento estimadas**. El veredicto de la
historia de Áurea está disponible y es probable: *puede que no valga su mantenimiento*.

## # ds09 — Servir el modelo, y el ⚖️ veredicto del track

**Qué se decide en este chat.** Cómo llega el modelo a producción: `pickle` y su superficie de
ataque, ONNX como formato de intercambio, el endpoint en AgendaAPI, y el reentrenamiento como
proceso del cierre nocturno de la Fase 15.

**Cuidado con.** `pickle` ejecuta código al cargar. Ya se dijo en la Fase 16 del camino base y
aquí se cobra en un caso real: un artefacto de modelo es un ejecutable disfrazado de dato.

**Su medición.** Latencia p95 del endpoint de predicción con el modelo en `pickle` y en
`onnxruntime`, más tamaño en disco y tiempo de arranque en frío. Y el cierre del track: qué
proyecto de datos de Áurea valía la pena y cuál no.

---

## 📌 Lo que este documento deja abierto

1. **Las mediciones van con `⏳` hasta que alguien las corra.** La alternativa —publicar una
   cifra plausible y corregirla después— es exactamente lo que un curso que se define por medir
   no puede hacer, y aquí pesa más porque tres de estas mediciones cuestan dinero real. Cada
   sección deja la spec completa y el comando; el número entra después, y `BENCHMARKS.md` marca
   cuáles están pendientes.
2. **`src/` en las diecisiete.** Casi todo en estos tracks es código ejecutable, y una sección de
   IA sin su script no se puede reproducir. Lo que no lleva `src/` propio se dice en su 📌.
3. ✅ **Los conjuntos de datos de `ds` están generados (T6, 13/09/2026).** Son dos, no uno, y
   cada uno vive en el `src/` de la sección que lo estrena:

   - `src/ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py` — el Embudo: pauta, toques,
     leads, etapas, planes, cuotas y aliados. Ocho CSV, ~32.500 leads, con la estacionalidad de
     Áurea y la Semana Santa **calculada** por año. 28 pruebas.
   - `src/ds07-scikit-learn/generar_ausentismo.py` — el histórico de citas con su clima.
     ~105.600 citas, 3.900 al mes, **19,3% de inasistencia** calibrado numéricamente. 19 pruebas.

   Semilla fija, solo biblioteca estándar, cero datos clínicos y salida reproducible byte a byte.
   Las demás secciones **leen archivos de `data/`**; ninguna importa un módulo de otro directorio
   de sección. El esquema queda congelado aquí: si una sección necesita una columna nueva, se
   agrega al generador y se vuelve a correr la suite, no se inventa en el capítulo.

   Dos decisiones que esos generadores cierran y que ninguna sección reabre: los tamaños grandes
   de la medición de `ds01` salen de `--escala` y **son sintéticos declarados** —Áurea no tiene
   cinco millones de filas—, y el proceso que genera el ausentismo es **casi lineal a propósito**,
   porque es lo que hace que la tesis de `ds08` —la línea base gana— sea comprobable en vez de
   proclamada.
