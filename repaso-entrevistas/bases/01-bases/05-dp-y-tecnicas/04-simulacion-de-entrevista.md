# 04 — Simulación de entrevista

> El examen del bloque **y el examen final del corpus**. Treinta preguntas `S#` que cruzan los tres
> capítulos y también los cuatro bloques anteriores, más cinco problemas de pizarra completos que
> exigen elegir la técnica sin ninguna pista.
> Asume leído **todo el corpus**, de [`01-fundamentos`](../01-fundamentos/) a
> [`03`](03-protocolo-de-pizarra.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA. Grábate.
3. Los problemas se TECLEAN, en 25 minutos, aplicando los siete pasos de `03`.
4. Solo después vas a `05-respuestas.md`.
5. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

> **Regla:** este documento es el más parecido a una entrevista real de todo el corpus, porque
> **ningún enunciado dice qué técnica usar**. Esa traducción es el ejercicio.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Programación dinámica

**S1.** ¿Qué dos condiciones comprueban que un problema es de DP? 🟢

**S2.** ¿Qué diferencia hay entre memoizar y tabular, y cuándo importa? 🟡

**S3.** ¿Por qué la mochila es pseudopolinómica? 🟠

**S4.** ¿Por qué en la mochila 0/1 con una fila se recorre la capacidad al revés? 🟠

**S5.** ¿Qué pierdes al optimizar el espacio de una DP? 🟠

**S6.** Te dan un problema de DP con recursión que desborda la pila. ¿Qué haces? 🟠

### Bloque B — Voraces

**S7.** ¿Qué necesita un problema para que el voraz sea óptimo? 🟢

**S8.** Da dos contraejemplos donde el voraz falla. 🟡

**S9.** ¿Por qué Dijkstra es voraz y qué condición lo hace correcto? 🟠

**S10.** ¿Cómo justificas un voraz sin demostración formal? 🟠

**S11.** ¿Puede ser útil un voraz que no es óptimo? 🟠

### Bloque C — Elección de técnica

**S12.** Enumera las señales léxicas que delatan cada técnica. 🟡

**S13.** ¿Cuándo un problema que parece DP es backtracking, y al revés? 🟠

**S14.** ¿Cuándo es correcta la fuerza bruta y cómo se dice? 🟠

**S15.** "Los k mayores de un flujo": elige y justifica en tres frases. 🟠

**S16.** "Minimiza la carga del más cargado": elige y justifica. 🟠

**S17.** "El precio vigente en esta fecha": elige y justifica. 🟠

### Bloque D — Transversales del corpus

**S18.** Hash, árbol, heap: da el criterio de elección. 🟠

**S19.** ¿Qué tres cosas dices al terminar de escribir cualquier solución? 🟢

**S20.** ¿Por qué `HashMap` es O(1) con tres asteriscos? 🟠

**S21.** ¿Por qué un `sort` de biblioteca vence casi siempre al que escribirías? 🟠

**S22.** ¿Qué tienen en común el peor caso de quicksort y el de un BST sin balanceo? 🟠

**S23.** ¿Qué tienen en común el coste amortizado del `ArrayList`, el de la pila monótona y el
`heapify` en O(n)? 🔴

### Bloque E — Protocolo

**S24.** ¿Cuáles son los siete pasos y cuál es el que más gente se salta? 🟢

**S25.** ¿Qué seis preguntas haces antes de escribir? 🟡

**S26.** Te quedan cinco minutos y no has terminado. ¿Qué haces? 🟠

**S27.** El entrevistador te corrige y tiene razón. ¿Cómo lo manejas? 🟠

### Bloque F — Las que descolocan

**S28.** "¿Para qué sirve esto si nunca implementas un algoritmo?" Responde. 🔴

**S29.** ¿Cuál de todos estos temas te parece más sobrevalorado en las entrevistas? 🔴

**S30.** Te dan un problema que no sabes resolver. Describe los primeros cinco minutos. 🔴

---

## 3. 🧪 Problemas de pizarra

Veinticinco minutos cada uno, tecleando y narrando con el protocolo de
[`03`](03-protocolo-de-pizarra.md). **Ninguno dice qué técnica usar.** La solución completa está en
[`05`](05-respuestas.md).

### P1 — El presupuesto del sprint

**Fuerza:** distinguir mochila 0/1 de mochila fraccionaria, y detectar que el voraz no es óptimo.

Tienes 30 funcionalidades, cada una con un valor de negocio estimado y un coste en puntos. El
sprint tiene 40 puntos. Elige el subconjunto que maximiza el valor. Escribe la solución, di su
complejidad, y responde si el enfoque de "ordenar por valor/esfuerzo" que usa todo el mundo es
óptimo.

Repregunta: *"¿y si las funcionalidades se pudieran hacer a medias?"*.

### P2 — La sala de reuniones

**Fuerza:** reconocer un voraz y justificarlo, con el contraejemplo del criterio equivocado.

Dadas 500 solicitudes de reunión con hora de inicio y fin, ¿cuál es el máximo número que caben en
una sola sala? Escribe la solución y **justifica por qué tu criterio de ordenación es el correcto**
y no otro.

Repregunta: *"¿y cuántas salas hacen falta para acomodarlas todas?"*.

### P3 — La ruta de reparto

**Fuerza:** detectar que el problema cambia de familia a mitad del enunciado.

Un repartidor tiene que visitar 12 direcciones y volver al almacén, minimizando la distancia total.
Diseña la solución. Después, el enunciado cambia a 200 direcciones: rediseña.

Repregunta: *"¿qué garantía te da tu segunda solución?"*.

### P4 — El detector de duplicados

**Fuerza:** elegir entre tres estructuras según una restricción de memoria que llega tarde.

Sobre un flujo de 500 millones de identificadores de transacción al día, detecta los repetidos.
Empieza con la solución evidente. Después te dicen que solo dispones de 4 GB de memoria.
Finalmente, que un falso positivo ocasional es aceptable pero un falso negativo no.

Repregunta: *"¿qué cambia si el orden de llegada importa?"*.

### P5 — El corrector de códigos

**Fuerza:** combinar dos bloques distintos del corpus, y negociar el requisito.

Los códigos de producto tienen formato `AAA-9999-XX`. Los operarios los teclean mal. Dado un código
que no existe, sugiere los tres códigos válidos más parecidos, sobre un catálogo de 2 millones, en
menos de 200 ms.

Repregunta: *"¿y si te dicen que tiene que ser exacto y no aproximado?"*.

---

## 4. 🧠 Las frases que hay que tener listas

Las tres del corpus entero. Si solo memorizas tres cosas de todo este material, que sean estas:

> **Al empezar cualquier problema:** *"Déjame repetir el enunciado y hacer tres preguntas: tamaño
> de la entrada, si puede venir vacía, y qué devuelvo si no hay respuesta. La fuerza bruta sería
> [X], y creo que se puede hacer mejor con [técnica] porque el enunciado dice [señal]."*

> **Al terminar de escribir:** *"Complejidad [tiempo] y [espacio]. Déjame probarlo con mi ejemplo.
> Los casos borde que veo son vacío, un elemento, todos iguales y desbordamiento."*

> **Al elegir una estructura:** *"Necesito [operación], así que el contrato es [TDA] y la
> implementación [clase], porque [la operación que decidió]. Si no necesitara [X], usaría [la más
> barata]."*

---

**Anterior:** [`03` — Protocolo de pizarra](03-protocolo-de-pizarra.md) ·
**Siguiente:** [`05` — Respuestas](05-respuestas.md) ·
**Relacionado:** [`README` del corpus](../README.md)
