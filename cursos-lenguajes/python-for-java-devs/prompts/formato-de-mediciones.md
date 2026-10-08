# 📏 Formato de las mediciones y del arnés
## Python para desarrolladores Java senior

La guía de estilo §4.6 fija la regla: **ninguna afirmación comparativa entra al curso sin un
número producido por el arnés del curso.** Este documento define qué es ese arnés, qué forma
tiene cada medición dentro de una fase, y cómo se consolidan en `BENCHMARKS.md`.

---

> 🧩 **Qué aplica a los complementos `ia` y `ds`.** Todo, sin descuento: **cada una de las
> diecisiete secciones produce su medición**, con el mismo arnés de la Fase 02. Estos dos tracks
> son, de hecho, donde más falta hace —"el RAG funciona mejor" y "la red neuronal predice mejor"
> son exactamente las dos frases que nadie mide— y traen dos métricas que el camino base no
> tenía: **costo en dólares por respuesta** y **calidad contra un conjunto de evaluación**. Las
> dos entran a `BENCHMARKS.md` como cualquier otra, con la advertencia de que el precio del
> modelo cambia y la fecha en que se tomó.

> 🍽️ **Qué aplica al material a la carta.** En las secciones opcionales
> (`propuestas-temas-opcionales.md`) **la medición no es obligatoria**: se incluye solo cuando hay
> dos opciones que de verdad compitan por el mismo encargo. Lo que sí heredan, sin excepción, son
> las reglas de honestidad de la sección 3: ninguna afirmación comparativa sin número, el
> competidor bien configurado, y el empate se llama empate.

## 1. Qué es el arnés, y por qué tiene que ser uno solo

Un arnés consistente es lo que separa una medición de una anécdota. Si la Fase 02 mide memoria
con una herramienta y la Fase 16 con otra, sus números no se pueden poner en la misma tabla, y
el curso pierde lo único que lo hace defendible.

> 🧭 **Un solo arnés para todo el curso**, construido con la biblioteca estándar en la Fase 02 y
> ampliado —nunca reemplazado— por las fases que lo necesiten.

El arnés vive en el repositorio del lector, se escribe en el curso como cualquier otro código, y
tiene tres responsabilidades y ninguna más:

- **Cronometrar** con reloj monótono, con repeticiones, reportando mediana y percentil 95 — nunca
  el promedio solo, que esconde la cola que es justo lo que importa.
- **Medir memoria**, pico y no consumo instantáneo, con `tracemalloc` para lo que asigna Python y
  con la medida del sistema operativo cuando el trabajo cruza a un proceso hijo.
- **Declarar el entorno**: versión del intérprete, sistema operativo, arquitectura, núcleos, y si
  hay algo más corriendo. Sin eso el número no es reproducible y por lo tanto no es un número.

Lo que el arnés **no** hace: estadística sofisticada, gráficos, ni comparación automática. Es
deliberado — un arnés que hay que aprender a usar deja de usarse.

---

## 2. La forma de una medición dentro de una fase

Es la sección 6 de la plantilla de fase, y va siempre con estas cinco partes.

**Hipótesis.** La afirmación que se va a sostener o a tumbar, en una línea y falsable. *"Una
tubería perezosa procesa el archivo de citas en memoria constante; la lista intermedia crece
linealmente con el archivo."* No vale *"los generadores son mejores"*.

**Condiciones.** Versión del intérprete, plataforma, núcleos, tamaño y forma del dato,
repeticiones, y qué se mide exactamente. Si el dato lo genera un script del curso, se dice cuál y
con qué semilla.

**Competidores.** Contra qué se compara, y **por qué esa implementación es defendible**. La regla
es dura a propósito: si el competidor es el stack de origen, tiene que ser código que alguien
aprobaría en una revisión. Un Spring Boot mal configurado no prueba nada y el lector lo va a
notar.

**Resultado.** Tabla corta. Números con su unidad y su dispersión, no un único valor limpio.

**⚖️ Veredicto.** Qué gana, dónde pierde, **y a partir de qué umbral cambia la respuesta**. Esa
tercera parte es la que convierte una medición en criterio: *"por debajo de cinco mil filas, el
bucle a mano gana y la diferencia es irrelevante; por encima de cien mil, no hay discusión."*

> ⚠️ **Las fases que no midan nada lo dicen en una línea y explican por qué**, y esa línea tiene
> que ser convincente. Una fase sin medición es la excepción; dos fases seguidas sin medición son
> un problema de diseño del curso.

---

## 3. Reglas de honestidad

Son las que hacen que el curso sobreviva a un lector escéptico, que es exactamente el lector que
tenemos.

- **Se publica lo que salió, no lo que esperabas.** Si el resultado contradice la tesis de la
  fase, se escribe la fase alrededor del resultado. Esto pasa y es el mejor material del curso.
- **El empate se llama empate.** Es la palabra que menos aparece en los cursos de tecnología y la
  que más falta hace.
- **Nada de números redondos sin dispersión.** "3× más rápido" sin percentiles ni repeticiones es
  una anécdota con formato de dato.
- **El competidor se configura bien.** Si no sabes configurarlo bien, la medición no está lista.
- **Se declara lo que no se midió.** *"No medimos consumo de memoria del contenedor; la
  comparación es solo de latencia."* Una omisión declarada es honesta; una omisión silenciosa es
  un sesgo.
- **Nunca se extrapola.** Un número de un portátil no predice una máquina virtual de dos núcleos,
  y cuando el dominio de Áurea tiene una máquina así, se dice.

---

## 4. `BENCHMARKS.md`, el consolidado del curso

Vive en la raíz del curso, no en `prompts/`. Es la tabla índice de todas las mediciones, para que
el lector pueda recorrerlas sin releer el curso y para que una fase pueda citar el número de
otra sin repetirlo.

Cada entrada lleva: **fase de origen, hipótesis en una línea, condiciones resumidas, resultado, y
veredicto con su umbral**, más el enlace a la fase donde está el detalle completo. Se escribe al
cerrar cada fase, no al final del curso.

Y lleva, arriba, la **declaración del entorno de referencia** contra el que se tomaron los números
del curso, con la advertencia de que los del lector van a ser distintos y que eso está bien
siempre que la relación entre las opciones se conserve.

---

## 5. Relación con los miniproyectos

Todo miniproyecto tiene **un criterio de aceptación que es una medición**
(`formato-de-miniproyectos.md` §4.4), y **ese número va en el mensaje del tag `mini-NN`**. No
entra a `BENCHMARKS.md`: el consolidado es de las mediciones del curso, que son iguales para
todos, mientras que el número del miniproyecto es del lector y de su máquina.

Sirve para otra cosa, igual de valiosa: que el lector pueda comparar su resultado de la Fase 15
con el suyo de la Fase 02 y ver su propia curva de aprendizaje con un `git show`.
