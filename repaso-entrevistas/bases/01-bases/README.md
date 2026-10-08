# 🧮 Bases: algoritmos y estructuras de datos para entrevistas

> Corpus de repaso de **fundamentos** para entrevistas de Backend Senior / Software Architect / Tech
> Lead. Ocho bloques en el hilo principal y uno opcional, cada uno con capítulos breves, bloques
> extensos de preguntas y un solucionario aparte — para que estudiar no sea leer la respuesta al lado
> de la pregunta.
>
> **Vigencia:** 2026-09-18.

---

## Qué es esto, y qué no

```text
Un curso de algoritmos → te enseña a demostrar la cota.
Este repaso            → te enseña a elegir la estructura, decir qué te cuesta,
                         y escribirla sin bug de índice delante de alguien.
```

Es material de **repaso para entrevista**, no un curso. Por eso cada estructura cierra con un
**veredicto**, todo algoritmo viene con su **coste en tiempo y en espacio**, y cada capítulo trae una
tabla de costes con una columna que casi ninguna tabla tiene: **"lo que la tabla no dice"** —la
localidad de caché, la constante oculta, el caso degenerado—.

**Su aportación propia frente a cualquier libro de algoritmos** es la comparación entre **cinco
lenguajes**: Java, Python, JavaScript, TypeScript y Go. Casi todas las preguntas de este corpus
tienen cinco respuestas distintas, y saber cuál da cada plataforma es lo que se pregunta en una
entrevista políglota.

**Lo que queda fuera, declarado:** no es preparación de competitive programming —nada de flujo
máximo, segment trees ni geometría—, no son demostraciones formales, y no es un libro: compite con el
calendario de alguien que tiene la entrevista cerca.

---

## Los nueve bloques

| Bloque | Qué cubre | Estado |
|---|---|---|
| [`01-fundamentos/`](01-fundamentos/) | Complejidad y O grande, TDAs, arrays y técnicas sobre secuencias, recursión y backtracking | ✅ **completo** |
| [`02-texto/`](02-texto/) | Strings en los cinco lenguajes, algoritmos de cadenas, expresiones regulares y ReDoS | ✅ **completo** |
| [`03-orden-busqueda/`](03-orden-busqueda/) | Ordenación, comparadores y orden total, búsqueda binaria, hashing y tablas hash | ✅ **completo** |
| [`04-arboles-grafos/`](04-arboles-grafos/) | Árboles y B+tree, montículos, grafos y recorridos, caminos mínimos y expansión mínima | ✅ **completo** |
| [`05-dp-y-tecnicas/`](05-dp-y-tecnicas/) | Programación dinámica, algoritmos voraces, **protocolo de pizarra** | ✅ **completo** |
| [`06-numeros-tiempo-concurrencia/`](06-numeros-tiempo-concurrencia/) | Precisión y dinero, fechas y relojes, estructuras bajo concurrencia | ✅ **completo** |
| [`07-formatos-de-datos/`](07-formatos-de-datos/) | JSON, XML, YAML y CSV: qué representan, qué cuesta parsearlos y qué hace distinto cada biblioteca | ✅ **completo** |
| [`08-entrada-salida-y-recursos/`](08-entrada-salida-y-recursos/) | Descriptores y fugas, el paradigma de Unix y sus roturas, modelos de concurrencia de IO, búferes y recorrido de directorios | ✅ **completo** |
| [`09-implementaciones/`](09-implementaciones/) | **Opcional, fuera del hilo principal**: el código en los cinco lenguajes, los labs de patrones, formatos e IO, y ejercicios con solución inline | ✅ completo |

**Empieza por [`01-fundamentos/`](01-fundamentos/).** Es el troncal: fija la notación de complejidad
y el vocabulario de estructuras que los demás bloques asumen leídos.

**Si la entrevista toca integraciones** —ficheros, APIs, intercambio con terceros—, el bloque
[`07-formatos-de-datos/`](07-formatos-de-datos/) es el más rentable: es donde están los fallos que no
lanzan excepción y que casi nadie sabe explicar con números.

**Si el dominio toca dinero** —banca, seguros, facturación—, el capítulo más rentable del corpus es
[`06/01` — Números, precisión y dinero](06-numeros-tiempo-concurrencia/01-numeros-precision-y-dinero.md):
es lo primero que se pregunta a un perfil senior en esos dominios.

**Si solo tienes una tarde**, lee
[`05-dp-y-tecnicas/03` — Protocolo de pizarra](05-dp-y-tecnicas/03-protocolo-de-pizarra.md), aunque
rompa el orden. Su mapa de señales y sus siete pasos son lo que más rinde por minuto de todo el
corpus, y funcionan aunque no hayas leído nada más.

---

## Cómo está construido cada bloque

```text
NN-tema.md                  capítulo: el problema → concepto a concepto, cada uno con
                            qué es → cómo va → cuánto → cuándo sí → cuándo no → veredicto
                            → tabla de costes → cómo se elige → dónde aparece de verdad
                            → errores frecuentes → referencias → 20-30 preguntas SIN respuesta
NN-simulacion-de-entrevista.md   preguntas transversales + problemas de pizarra
NN-respuestas.md            solucionario del bloque, con el enunciado copiado literal
README.md                   índice, orden de lectura, mapa mental y "qué NO está aquí"
```

Cada respuesta del solucionario va en tres capas:

```text
⏱️ 30 segundos  → lo que dices primero, sin que te lo pidan. Casi siempre, la complejidad
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más"
🔬 El detalle   → para estudiar, no para decir en voz alta
```

---

## Cómo se estudia

```text
1. Lee el capítulo entero, sin saltarte los veredictos ni la tabla de costes.
2. Contesta las preguntas EN VOZ ALTA, cronometrado a 2 minutos.
3. Solo entonces abre el solucionario del bloque.
4. Lo que supiste pero no pudiste articular en 2 minutos, cuenta como fallo: vuelve.
5. Los problemas de pizarra se TECLEAN, en un editor sin autocompletado.
```

**Rutas según el calendario:**

- **Una semana.** `01` completo, `03` completo, y `05-dp-y-tecnicas/03`. Después, las simulaciones de
  esos dos bloques en voz alta.
- **Dos semanas.** El plan día a día está resuelto como respuesta en
  [`05-dp-y-tecnicas/05` → 03 → 22](05-dp-y-tecnicas/05-respuestas.md).
- **Un mes.** Los ocho bloques en orden, uno cada cuatro o cinco días, con las simulaciones
  intercaladas y el bloque `07` cuando apetezca teclear.

---

## Reglas del corpus

Están en [`prompts/guia-de-estilo-y-convenciones.md`](prompts/guia-de-estilo-y-convenciones.md), que
es normativa y **manda sobre los nueve bloques**. Lo esencial:

- **Ninguna estructura se presenta sin su coste** en tiempo y en espacio, ni sin su "cuándo no".
- **Todo concepto se ancla en la librería estándar** —`PriorityQueue`, `heapq`, `bisect`,
  `graphlib`— o se declara explícitamente que no tiene anclaje.
- **Los cinco lenguajes van siempre en el mismo orden**, y TypeScript solo aparece cuando el sistema
  de tipos cambia la respuesta; donde no aporta, se dice.
- **Las respuestas viven en un solo archivo por bloque**, con el enunciado copiado literal. Tocar una
  pregunta obliga a actualizar el solucionario en la misma edición.
- **Referencias por orden de autoridad**: libro con capítulo concreto → documentación oficial del
  lenguaje → especificación → referencia algorítmica → visualización → tutorial → video (por título,
  sin URL). Máximo ocho por capítulo.
- **No se inventan URLs**, y las que se escriben se comprueban por código de estado.
- **No hay laboratorio contra ningún servicio.** Todo corre en local, en un archivo, en segundos.

---

## Relación con el resto del repositorio

- [`repaso-arquitectura-entrevistas/`](../../arquitectura/01-bases/) — el corpus hermano, del
  que este hereda la guía de estilo. Allí se razona un **sistema**; aquí se elige y se escribe el
  **mecanismo**. La complejidad de una consulta, el diseño de un índice o la elección de un broker
  son de allí.
- [`preguntas-entrevista/`](../../../preguntas-entrevista/) — bancos de ~100 preguntas con respuesta
  inline. Allí se repasa rápido; aquí se estudia con veredicto. En particular,
  [`04-java-11-17.md`](../../../preguntas-entrevista/04-java-11-17.md) cubre el lenguaje Java más allá de
  sus estructuras, que este corpus no toca.
- [`repaso-aws-entrevistas/`](../../cloud/01-aws/) y
  [`repaso-gcp-entrevistas/`](../../cloud/02-gcp/) — la nube, con laboratorio. Este corpus es
  la capa de abajo: lo que corre dentro de cualquiera de esos servicios.

**Los puntos donde los corpus se tocan y se enlazan en vez de duplicarse:** el B+tree de un índice
(aquí la estructura, allí el diseño del índice), el hashing consistente (aquí el mecanismo, allí el
particionado), las colas de prioridad (aquí el heap, allí el broker) y los patrones GoF (allí la
teoría, aquí el lab en cinco lenguajes).

---

## El corpus en números

```text
9 bloques · 33 capítulos · 8 simulaciones de entrevista · 8 solucionarios · 5 documentos opcionales
846 preguntas de capítulo con respuesta en tres capas
266 preguntas transversales y 40 problemas de pizarra resueltos
```

Todos los enlaces externos se verificaron por código de estado el **2026-09-18**, y todo el código
del bloque opcional se compiló y ejecutó antes de publicarse: **Java Zulu 21.0.12 y 17.0.15/16** —con
salida idéntica en ambas—, Python 3.13, Node 24.21 y Go 1.27. Los fragmentos de TypeScript se
comprobaron con `tsc --noEmit --strict`, **en las dos direcciones**: que el código correcto compile y
que el que los documentos declaran imposible falle de verdad, con el mensaje del compilador copiado
literal. El detalle está en el [README del bloque opcional](09-implementaciones/README.md).
