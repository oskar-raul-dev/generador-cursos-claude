# 01 — Ordenación

> Los cinco algoritmos que hay que saber, qué significan de verdad "estable" e "in-place", por
> qué counting sort esquiva la cota de Ω(n log n), y sobre todo **qué ejecuta realmente tu
> lenguaje cuando llamas a `sort`**: TimSort y Dual-Pivot Quicksort, que no son ninguno de los
> cinco del libro.
> Asume leídos [`01-fundamentos/01` — Complejidad](../01-fundamentos/01-complejidad-y-o-grande.md)
> y [`01-fundamentos/04` — Recursión](../01-fundamentos/04-recursion-y-backtracking.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un proceso ordena los pedidos del día por fecha y después por importe, en dos pasadas. El
resultado sale mal: dentro de cada fecha, los importes están en orden, pero las fechas se
mezclaron. Nadie tocó el comparador.

La causa es que el algoritmo de la segunda pasada **no era estable**, así que destruyó el orden
que la primera había establecido. Es un bug de una palabra, y esa palabra no aparece en ninguna
tabla de complejidades.

El segundo problema es de expectativa. Todo el mundo responde "quicksort, O(n log n)" cuando le
preguntan cómo ordenar, y resulta que:

```text
Arrays.sort(int[])        → Dual-Pivot Quicksort
Arrays.sort(Object[])     → TimSort
Collections.sort(List)    → TimSort
Python sorted()           → TimSort (lo inventaron ahí)
JavaScript Array.sort()   → TimSort en V8
Go slices.Sort()          → pdqsort
```

Ninguno de los seis es "quicksort del libro". Saber **por qué** cada plataforma eligió lo que
eligió es lo que separa una respuesta memorizada de una entendida.

> **Regla de entrevista:** cuando te pregunten por ordenación, la respuesta completa tiene tres
> partes: complejidad, **estabilidad** y espacio. La del medio es la que casi nadie dice y la
> que más veces decide en un caso real.

---

## 2. 🧱 Los cuadráticos, y por qué uno sigue vivo

**Insertion sort** es el único de los tres cuadráticos clásicos que sigue ejecutándose en
producción todos los días.

**Cómo va.** Toma cada elemento y lo inserta en su sitio dentro de la parte ya ordenada, a su
izquierda.

```text
[5, 2, 9, 1, 5, 6]
[5 | 2, 9, ...]        2 < 5 → se inserta antes
[2, 5 | 9, ...]        9 ya está en su sitio
[2, 5, 9 | 1, ...]     1 viaja hasta el principio
[1, 2, 5, 9 | 5, 6]    5 se inserta tras el otro 5 → estable
```

**Cuánto.** O(n²) en el caso peor, **O(n) si ya está casi ordenado**, O(1) de espacio, y es
estable.

**Cuándo sí.** Con pocos elementos —por debajo de unos 32— y con datos casi ordenados. Ambas
condiciones se dan constantemente **dentro** de otros algoritmos: TimSort lo usa para los
tramos cortos y Dual-Pivot Quicksort también.

**Cuándo no.** Como algoritmo general. Con mil elementos desordenados ya pierde por mucho.

**Bubble sort y selection sort** no tienen ningún caso donde ganen. Se enseñan por su valor
pedagógico y la respuesta correcta sobre ellos es esa: *"no los usaría nunca; insertion sort
domina a los dos"*.

> **Veredicto:** insertion sort es el algoritmo cuadrático que sí hay que saber, porque es el
> que tu biblioteca estándar ejecuta cientos de veces por segundo sin que lo sepas.

---

## 3. 🧱 Merge sort

**Cómo va.** Divide por la mitad hasta llegar a elementos sueltos, y después **fusiona** pares
de secuencias ordenadas. El trabajo está en la fusión.

```text
[5, 2, 9, 1, 5, 6]
[5, 2, 9] [1, 5, 6]
[5][2,9]  [1][5,6]
[2,5,9]   [1,5,6]          ← cada mitad ordenada
[1, 2, 5, 5, 6, 9]         ← fusión final, comparando cabezas
```

**Cuánto.** Θ(n log n) **siempre**: mejor, medio y peor caso coinciden. O(n) de espacio
auxiliar, que es su precio y no se puede evitar de forma barata.

**Estable**, si la fusión toma el de la izquierda cuando hay empate. Ese `<=` en vez de `<` es
literalmente lo único que separa un merge sort estable de uno que no lo es.

**Cuándo sí.** Cuando necesitas **garantía** de n log n, cuando necesitas **estabilidad**, y
cuando los datos no caben en memoria: la fusión solo necesita leer secuencialmente, lo que la
hace el algoritmo de la ordenación externa.

**Cuándo no.** Cuando la memoria está ajustada y los datos caben: pagar O(n) extra para ordenar
un arreglo que ya tienes en memoria es caro comparado con quicksort.

> 💡 **Truco.** El argumento de "merge sort es el de la ordenación externa" es la mejor forma de
> demostrar que entiendes por qué existen dos algoritmos con la misma complejidad. Fusionar
> lee secuencialmente; particionar salta. En disco, esa diferencia lo es todo.

---

## 4. 🧱 Quicksort

**Cómo va.** Elige un pivote, **particiona** el arreglo en menores y mayores, y recursa sobre
cada lado. El trabajo está en la partición; no hay combinación.

**Cuánto.** Θ(n log n) en el caso medio, **Θ(n²) en el peor**, cuando el pivote es siempre el
mínimo o el máximo. O(log n) de pila si las particiones son equilibradas, O(n) si no.

**No es estable**: la partición intercambia elementos distantes y destruye el orden relativo de
los iguales.

**El peor caso es el que sorprende**: con la elección ingenua del primer elemento como pivote,
un arreglo **ya ordenado** produce el peor caso. El caso más común en producción es el peor caso
del algoritmo, lo que lo convirtió en un bug real durante décadas.

Las tres defensas, en orden histórico:

- **Mediana de tres.** Pivote = mediana del primero, el del medio y el último. Elimina el caso
  del arreglo ordenado.
- **Pivote aleatorio.** Hace el peor caso improbable en vez de imposible, y sobre todo
  **imposible de provocar** por un adversario que conozca los datos.
- **Introsort.** Cuenta la profundidad de recursión y, si se pasa de 2·log n, cambia a heapsort.
  Convierte el peor caso en O(n log n) garantizado sin perder la velocidad media.

**Cuándo sí.** Es el más rápido en la práctica sobre arreglos en memoria: su bucle interno es
simple y su patrón de acceso es secuencial, lo que la caché agradece.

**Cuándo no.** Cuando necesitas estabilidad o una garantía de peor caso sin introsort.

> ⚠️ **Advertencia.** Responder "quicksort es O(n log n)" a secas es incompleto y el
> entrevistador va a preguntar por el peor caso. La respuesta que puntúa nombra el caso
> degenerado **y** la defensa: *"O(n²) si el pivote parte mal, y por eso las implementaciones
> reales usan mediana de tres o introsort"*.

---

## 5. 🧱 Heapsort

**Cómo va.** Construye un max-heap con el arreglo —in-place, O(n)— y después extrae el máximo n
veces, poniéndolo al final. El heap está en
[`04-arboles-grafos/02`](../04-arboles-grafos/02-monticulos-y-colas-de-prioridad.md).

**Cuánto.** Θ(n log n) **garantizado**, O(1) de espacio auxiliar. Es el único de los tres
"buenos" que consigue las dos cosas a la vez.

**No es estable**, y en la práctica **es más lento que quicksort** pese a tener la misma
complejidad: el acceso a un heap salta por el arreglo (posiciones i, 2i+1, 2i+2) y destruye la
localidad de caché.

**Cuándo sí.** Cuando necesitas garantía de peor caso **y** memoria constante: sistemas
embebidos, código de tiempo real, o como red de seguridad dentro de introsort.

**Cuándo no.** Como algoritmo general: pierde contra quicksort en tiempo real por la caché.

> **Veredicto:** heapsort es el algoritmo que casi nadie ejecuta solo y que casi todas las
> bibliotecas llevan dentro. Su papel real es ser el plan B de introsort.

---

## 6. 🧱 Estable e in-place: qué significan de verdad

Dos propiedades que deciden más casos reales que la complejidad, y que se confunden.

**Estable** significa que **los elementos iguales conservan su orden relativo**. Es lo que
permite ordenar por varios criterios en pasadas sucesivas: ordena por importe, después por
fecha, y dentro de cada fecha los importes siguen en orden.

```text
Pedidos: (12-mar, 100) (11-mar, 50) (12-mar, 30)
Ordenar por fecha, estable  → (11-mar,50) (12-mar,100) (12-mar,30)   orden original preservado
Ordenar por fecha, inestable→ (11-mar,50) (12-mar,30)  (12-mar,100)  orden arbitrario
```

**In-place** significa que usa **O(1) de espacio auxiliar**. Y aquí está la trampa: quicksort se
llama in-place y usa O(log n) de pila de recursión, así que estrictamente no lo es. La
convención acepta llamarlo así; el entrevistador puede no aceptarla, y conviene decir el matiz
antes de que lo pregunte.

**Ningún algoritmo conocido es a la vez estable, in-place y O(n log n)** con constantes
razonables. Existen merge sorts estables e in-place, pero sus constantes son tan malas que nadie
los usa. Elegir es, por tanto, obligatorio.

---

## 7. 🧱 Los que no comparan

**El problema.** La cota Ω(n log n) de
[`01-fundamentos/01`](../01-fundamentos/01-complejidad-y-o-grande.md#3--las-tres-cotas-o-ω-y-θ)
aplica a los algoritmos que **comparan pares**. Si en vez de comparar usas el valor como
índice, la cota no te aplica.

**Counting sort.** Cuenta cuántas veces aparece cada valor y reconstruye. O(n + k) siendo k el
rango de valores. Estable si se construye con sumas acumuladas y se recorre al revés.

**Radix sort.** Aplica counting sort dígito a dígito, del menos significativo al más
significativo. O(d · (n + k)) con d dígitos. **Depende de que counting sort sea estable**: si no
lo fuera, cada pasada destruiría el orden de la anterior y el algoritmo no funcionaría. Es el
mejor ejemplo de por qué la estabilidad importa.

**Bucket sort.** Reparte en cubetas por rango y ordena cada una. O(n) si los datos están
uniformemente distribuidos, O(n²) si caen todos en la misma cubeta.

**Cuándo sí.** Enteros en un rango acotado y conocido: edades, códigos postales, años,
puntuaciones, prioridades. Es donde counting sort gana por mucho.

**Cuándo no.** Cuando k es grande —ordenar enteros de 32 bits arbitrarios exige un arreglo de
4 000 millones—, con coma flotante, con strings de longitud variable, o con un comparador
arbitrario definido por el negocio. Que es casi todo lo que se ordena en un backend.

> **Veredicto:** counting sort es la respuesta cara a "ordena un millón de edades" y una trampa
> a "ordena un millón de enteros". La pregunta que decide es siempre **cuál es el rango**.

---

## 8. 🧱 Lo que tu lenguaje realmente ejecuta

Ninguna plataforma seria implementa uno de los cinco algoritmos tal cual. Todas son híbridas, y
los dos híbridos que hay que conocer son estos.

**TimSort** (Java para objetos, Python, JavaScript en V8). Inventado por Tim Peters para Python
en 2002, partiendo de una observación: **los datos reales casi nunca están desordenados del
todo**.

- Busca *runs*: tramos ya ordenados ascendentes o descendentes, que invierte si hace falta.
- Extiende los tramos cortos hasta un mínimo (32–64) con **insertion sort**.
- Fusiona los tramos con merge sort, manteniendo invariantes sobre sus tamaños para equilibrar.
- Resultado: **O(n) si los datos ya están ordenados**, O(n log n) garantizado en el peor caso,
  **estable**, y O(n) de espacio.

**Dual-Pivot Quicksort** (Java para primitivos, desde Java 7). Particiona con **dos** pivotes en
tres zonas en vez de dos, lo que reduce el número de intercambios y aprovecha mejor la caché.

- No es estable, y no importa: **dos `int` con el mismo valor son indistinguibles**. Esa es
  exactamente la razón de que Java use dos algoritmos distintos según el tipo.
- Desde Java 14 incorpora también protección contra el peor caso, cambiando a heapsort.

**pdqsort** (Go desde 1.19, Rust). *Pattern-defeating quicksort*: detecta patrones que
degradarían a quicksort —datos ordenados, muchos duplicados— y cambia de estrategia. O(n log n)
garantizado, no estable; `slices.SortStable` usa otro algoritmo cuando hace falta estabilidad.

> 📝 **Contexto.** Que Java use **dos algoritmos según el tipo** es una de las mejores
> respuestas que se pueden dar en este tema: primitivos sin estabilidad (no hace falta) y con
> la velocidad de quicksort; objetos con estabilidad (sí hace falta, porque dos objetos iguales
> según el comparador pueden ser distinguibles) y con TimSort. Explica de paso por qué
> `Arrays.sort` tiene dos comportamientos que la gente descubre por accidente.

---

## 9. ⏱️ La tabla de costes

| Algoritmo | Mejor | Medio | Peor | Espacio | Estable | Lo que la tabla no dice |
|---|---|---|---|---|---|---|
| **Insertion** | O(n) | O(n²) | O(n²) | O(1) | ✅ | El mejor para n < 32; vive dentro de TimSort |
| **Merge** | O(n log n) | O(n log n) | O(n log n) | **O(n)** | ✅ | El de la ordenación externa: solo lee secuencialmente |
| **Quick** | O(n log n) | O(n log n) | **O(n²)** | O(log n) pila | ❌ | El más rápido en memoria; el peor caso era el arreglo ordenado |
| **Heap** | O(n log n) | O(n log n) | O(n log n) | **O(1)** | ❌ | Garantía + memoria constante, pero lento por la caché |
| **Counting** | O(n + k) | O(n + k) | O(n + k) | O(k) | ✅ | Solo con rango acotado; con k grande es inviable |
| **Radix** | O(d(n + k)) | O(d(n + k)) | O(d(n + k)) | O(n + k) | ✅ | **Necesita** que counting sea estable, o no funciona |
| **TimSort** | **O(n)** | O(n log n) | O(n log n) | O(n) | ✅ | Lo que ejecutas de verdad. O(n) con datos casi ordenados |

---

## 10. ⚖️ Los cinco lenguajes

| Lenguaje | Qué ejecuta `sort` | ¿Estable? | El detalle que muerde |
|---|---|---|---|
| **Java** | Dual-Pivot Quicksort (primitivos), TimSort (objetos) | Solo objetos | Dos algoritmos según el tipo. `Arrays.sort(int[])` **no** es estable y da igual |
| **Python** | TimSort | ✅ Siempre | `sorted()` devuelve copia, `list.sort()` ordena en sitio y devuelve `None` |
| **JavaScript** | TimSort en V8 | ✅ Desde ES2019 | **Sin comparador ordena como strings**: `[10,9,1].sort()` da `[1,10,9]` |
| **TypeScript** | Igual que JS | Igual que JS | El tipo no evita el error del comparador ausente |
| **Go** | pdqsort (`slices.Sort`) | ❌, salvo `SortStable` | Antes de 1.21, `sort.Slice` con una función; ahora genéricos con `slices.Sort` |

> ⚠️ **Advertencia.** `[10, 9, 1].sort()` en JavaScript devuelve `[1, 10, 9]` porque sin
> comparador convierte todo a string y ordena lexicográficamente. Está en la especificación, no
> es un bug del motor, y es probablemente el comportamiento más denunciado del lenguaje. La
> forma correcta es `sort((a, b) => a - b)`.

---

## 11. 🧭 Cómo se elige

```text
¿Vas a ordenar en una aplicación normal?     → el sort de tu lenguaje. No implementes nada
¿Necesitas estabilidad?                      → confirma que el tuyo la tiene (Java con objetos sí,
                                                Go con slices.Sort NO)
¿Enteros en rango pequeño y conocido?        → counting sort
¿No cabe en memoria?                         → merge sort externo
¿Memoria constante y garantía de peor caso?  → heapsort
¿Solo necesitas los k mayores?               → NO ordenes: heap acotado a k
¿Solo necesitas el k-ésimo?                  → quickselect, O(n) promedio
```

Las dos últimas líneas son las que más puntúan: **ordenar para quedarte con diez elementos es
tirar trabajo**. Ordenar es O(n log n); el top-K con heap es O(n log k) y el k-ésimo con
quickselect es O(n) esperado.

> **Regla de entrevista:** antes de decir qué algoritmo usarías, pregunta si de verdad hace
> falta ordenar. La mitad de los problemas que parecen de ordenación son de selección.

---

## 12. 🔭 Dónde aparece de verdad

En el `ORDER BY` de una consulta, donde el motor elige entre ordenar en memoria (`quicksort`) o
en disco (`merge sort externo`) según el `work_mem` disponible, y el `EXPLAIN` te dice cuál
eligió; en el `sort` de la fase intermedia de un MapReduce, que es lo que hace que la agregación
funcione; en la compactación de un LSM-tree —Cassandra, RocksDB—, que es una fusión de
secuencias ordenadas; y en la ordenación de los resultados de un buscador por relevancia, donde
casi siempre lo correcto es un top-K y no una ordenación completa.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Quicksort es O(n log n)" | En el caso medio. El peor es O(n²), y era el arreglo **ya ordenado** |
| "`Arrays.sort` usa quicksort" | Con primitivos sí (dual-pivot); con objetos usa TimSort, que es estable |
| "Merge sort y quicksort son equivalentes" | Merge es estable y externo; quick es in-place y más rápido en memoria |
| "Heapsort es mejor porque garantiza n log n" | Garantiza, y es más lento en la práctica por la localidad de caché |
| "Counting sort ordena cualquier cosa en O(n)" | Solo enteros en rango acotado. Con k grande es inviable |
| "Ordeno y me quedo con los 10 primeros" | O(n log n) para algo que un heap acotado hace en O(n log 10) |
| "`array.sort()` ordena números en JS" | Sin comparador los ordena como strings: `[10,9,1]` → `[1,10,9]` |

---

## 📚 Para profundizar

- **Libro** — Sedgewick y Wayne, *Algorithms*, 4ª ed. (Addison-Wesley, 2011). Capítulo 2
  completo. **Si solo lees uno de este bloque, lee este**: tiene el código en Java, las
  visualizaciones y el análisis empírico de las constantes.
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT
  Press, 2022). Capítulos 6 a 8: heapsort, quicksort y la demostración de la cota Ω(n log n).
- **Libro** — Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). Ítem 14, `Comparable`, que
  es lo que decide si tu `sort` hace lo que crees.
- [Java 21 API — `Arrays.sort`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Arrays.html):
  la documentación declara el algoritmo y la garantía de estabilidad para cada sobrecarga.
- [Python — Sorting HOW TO](https://docs.python.org/3/howto/sorting.html):
  `key`, `reverse`, y por qué la estabilidad de TimSort permite ordenar por varios criterios en
  pasadas.
- [Wikipedia — Timsort](https://en.wikipedia.org/wiki/Timsort): la descripción del algoritmo con
  los invariantes de fusión, que no están documentados en ningún otro sitio accesible.
- [Go — `slices`](https://pkg.go.dev/slices): `Sort`, `SortStableFunc` y `BinarySearch`, con la
  nota de qué garantiza cada uno.
- **Video** — Coursera, Sedgewick, *Algorithms Part I*, semanas 3 y 4: merge sort, quicksort y
  el análisis de las constantes con mediciones reales.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué significa que un algoritmo de ordenación sea estable? 🟢
2. ¿Qué significa in-place y qué algoritmo lo cumple estrictamente? 🟢
3. ¿Cuál es la complejidad de merge sort en el mejor, medio y peor caso? 🟢
4. ¿Cuál es el peor caso de quicksort y qué entrada lo provoca con el pivote ingenuo? 🟢
5. ¿Qué algoritmo usa `Arrays.sort` sobre un `int[]`? ¿Y sobre un `Object[]`? 🟢
6. ¿Por qué insertion sort sigue usándose? 🟢
7. ¿Por qué merge sort es el algoritmo de la ordenación externa? 🟡
8. ¿Qué tres propiedades tiene TimSort que lo hacen la elección por defecto? 🟡
9. ¿Por qué heapsort es más lento que quicksort si ambos son O(n log n)? 🟡
10. ¿Por qué counting sort no incumple la cota Ω(n log n)? 🟡
11. ¿Por qué radix sort necesita que counting sort sea estable? 🟡
12. ¿Qué es introsort y qué problema resuelve? 🟡
13. ¿Por qué Java usa un algoritmo distinto para primitivos y para objetos? 🟠
14. ¿Existe un algoritmo estable, in-place y O(n log n)? Responde con matiz. 🟠
15. ¿Por qué el pivote aleatorio es mejor que la mediana de tres, si ambos evitan el peor
    caso? 🟠
16. Te dan un millón de edades para ordenar. Elige el algoritmo y justifica. 🟠
17. Te dan un millón de nombres de clientes para ordenar. Elige y justifica la diferencia con
    la anterior. 🟠
18. ¿Qué devuelve `[10, 9, 1].sort()` en JavaScript y por qué? 🟠
19. ¿Por qué `slices.Sort` de Go no es estable y qué haces si necesitas que lo sea? 🟠
20. Ordenas por importe y después por fecha, en dos pasadas, y el resultado sale mal. Explica
    la causa. 🟠
21. ¿Cuándo NO deberías ordenar aunque el enunciado diga "ordena"? 🟠
22. ¿Qué pasa si tu comparador no es transitivo y llamas a `Collections.sort`? 🟠
23. Diseña la ordenación de un archivo de 100 GB de registros en una máquina con 8 GB de RAM.
    Describe las fases y su coste. 🔴
24. Te piden los 100 productos más vendidos de un catálogo de 10 millones. Da dos soluciones
    con distinta complejidad y elige. 🔴
25. Traza merge sort sobre `[5, 2, 9, 1, 5, 6]` y señala en qué paso se decide la
    estabilidad. 🔴

---

**Siguiente:** [`02` — Comparadores y orden total](02-comparadores-y-orden-total.md) ·
**Relacionado:** [`04-arboles-grafos/02` — Montículos](../04-arboles-grafos/02-monticulos-y-colas-de-prioridad.md)
