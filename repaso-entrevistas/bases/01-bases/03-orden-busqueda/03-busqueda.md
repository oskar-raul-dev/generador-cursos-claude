# 03 — Búsqueda

> La búsqueda binaria escrita sin off-by-one, sus dos fronteras —el primero que cumple y el
> último que cumple—, la búsqueda binaria **sobre la respuesta**, que es la técnica que más
> problemas difíciles resuelve, y el bug que estuvo nueve años dentro de la JDK.
> Asume leídos [`01` — Ordenación](01-ordenacion.md) y
> [`01-fundamentos/03` — Secuencias](../01-fundamentos/03-arrays-listas-y-secuencias.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

La búsqueda binaria es el algoritmo que todo el mundo sabe explicar y casi nadie escribe bien a
la primera. Jon Bentley contó que, en sus cursos, **el 90 % de los programadores
profesionales** no conseguía escribirla sin errores en dos horas. Y la propia biblioteca de Java
tuvo un bug en ella **durante nueve años**:

```java
int mid = (lo + hi) / 2;          // con lo+hi > 2 147 483 647 desborda y sale negativo
int mid = lo + (hi - lo) / 2;     // correcto
```

El bug solo se manifiesta con arreglos de más de mil millones de elementos, así que pasó
desapercibido hasta 2006. Es el ejemplo perfecto de por qué en este tema no basta con entender
la idea: hay que tener el código memorizado y saber por qué cada línea es como es.

Y hay una segunda mitad, menos conocida y más rentable: **la búsqueda binaria no es solo para
arreglos ordenados**. Sirve para cualquier problema donde puedas responder "¿esta respuesta es
suficiente?" con un sí o un no monótono. Esa variante es la que resuelve los problemas que
parecen imposibles.

> **Regla de entrevista:** antes de escribir el bucle, di en voz alta cuál es tu invariante y
> qué convenio usas para `hi`: inclusivo o exclusivo. La mitad de los errores de este tema
> vienen de mezclar los dos.

---

## 2. 🧱 La búsqueda binaria canónica

**Qué es.** Sobre una secuencia **ordenada**, comparar con el elemento central y descartar la
mitad que no puede contener el objetivo.

```java
int lo = 0, hi = datos.length - 1;        // hi INCLUSIVO → por eso el bucle usa <=
while (lo <= hi) {
    int mid = lo + (hi - lo) / 2;         // no desborda
    if (datos[mid] < objetivo) lo = mid + 1;
    else if (datos[mid] > objetivo) hi = mid - 1;
    else return mid;
}
return -(lo + 1);                          // no está: lo es el punto de inserción
```

- **El convenio manda.** Con `hi` inclusivo, la condición es `<=` y las actualizaciones son
  `mid + 1` y `mid - 1`. Con `hi` exclusivo (`datos.length`), la condición es `<` y `hi = mid`.
  Mezclarlos produce bucles infinitos o elementos no encontrados.
- **Qué vale `lo` al salir** es la parte útil que casi nadie aprovecha: es la posición donde
  habría que insertar el objetivo para mantener el orden. Por eso `Arrays.binarySearch` devuelve
  `-(punto de inserción) - 1` y no un simple `-1`.
- El `-1` extra del valor de retorno existe porque el punto de inserción puede ser 0, y `-0` no
  se distingue de `0`.

**Cuánto.** O(log n) en tiempo, O(1) en espacio si es iterativa —y O(log n) de pila si la
escribes recursiva, que no hay motivo para hacer—.

**Cuándo sí.** Datos ordenados, con acceso aleatorio, que no cambian mucho.

**Cuándo no.** Sobre una `LinkedList`: el acceso por índice es O(n), así que la "búsqueda
binaria" acaba siendo O(n log n), peor que recorrer. Y sobre datos que cambian constantemente,
donde mantener el orden cuesta más de lo que ahorra la búsqueda.

> ⚠️ **Advertencia.** `Arrays.binarySearch` sobre un arreglo **no ordenado** no lanza ninguna
> excepción: devuelve un resultado arbitrario. Es un contrato que el compilador no puede
> verificar y una fuente real de bugs silenciosos.

---

## 3. 🧱 Las dos fronteras: `lowerBound` y `upperBound`

**El problema.** Con duplicados, `[1, 2, 5, 5, 6, 9]` y objetivo 5, la búsqueda canónica
devuelve **alguno** de los dos cincos, sin decir cuál. Casi siempre lo que quieres es otra cosa:
el primero, el último, o cuántos hay.

**Cómo va.** Dos variantes que no buscan igualdad sino **la frontera del predicado**:

```java
// lowerBound: el primer índice cuyo valor es >= objetivo
int lo = 0, hi = datos.length;            // hi EXCLUSIVO
while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (datos[mid] < objetivo) lo = mid + 1;
    else hi = mid;                        // mid podría ser la respuesta: no lo descartes
}
return lo;
```

- El `hi = mid` en vez de `mid - 1` es toda la diferencia: **mid sigue siendo candidato**.
- `upperBound` es idéntico cambiando `<` por `<=`: devuelve el primer índice **mayor** que el
  objetivo.
- Con los dos: `upperBound - lowerBound` es **cuántas veces aparece** el objetivo, en O(log n).
- Si `lowerBound` devuelve un índice válido y `datos[lo] == objetivo`, el elemento existe. Esa
  es la forma de convertir la frontera en una búsqueda exacta.

**Cuándo sí.** Duplicados, consultas de rango, "el primero que cumple X", "cuántos hay menores
que X".

**Cuándo no.** Si no hay duplicados y solo quieres saber si está, la canónica es más directa.

> 🧠 **Modelo mental.** La búsqueda binaria no busca un valor: **busca la frontera entre "no
> cumple" y "sí cumple"**. Si piensas siempre en esos términos, las tres variantes son el mismo
> código con distinto predicado, y dejas de memorizar tres bucles.

---

## 4. 🧱 Búsqueda binaria sobre la respuesta

**El problema.** "Reparte 10 000 pedidos entre 8 repartidores minimizando la carga del más
cargado." No hay ningún arreglo ordenado que buscar. Y sin embargo es búsqueda binaria.

**Cómo va.** El espacio de búsqueda no son los datos: es el **rango de respuestas posibles**. La
clave es que la pregunta "¿se puede hacer con una carga máxima de X?" es **monótona**: si se
puede con X, se puede con cualquier valor mayor.

```text
respuestas posibles:  [carga mínima .......... carga máxima]
predicado:            NO NO NO NO SÍ SÍ SÍ SÍ SÍ
                                  ↑ la frontera es la respuesta
```

- Se busca binariamente en el rango de respuestas, y en cada paso se **comprueba** si esa
  respuesta es viable con un algoritmo voraz lineal.
- Coste total: O(n · log(rango)). El logaritmo es del **rango de valores**, no del número de
  elementos, y eso desconcierta la primera vez.
- Requisito imprescindible: **monotonía**. Si el predicado no es monótono, descartar media
  mitad no está justificado y la técnica no aplica.

**Cuándo sí.** "Minimiza el máximo", "maximiza el mínimo", "cuál es el menor X que cumple",
capacidad de un barco, velocidad mínima, número de días.

**Cuándo no.** Cuando la comprobación es tan cara como resolver el problema, o cuando no hay
monotonía.

> **Veredicto:** es la técnica que convierte problemas de optimización aparentemente duros en
> un bucle de treinta líneas. Reconocerla vale más que saberse tres algoritmos con nombre.

---

## 5. 🧱 Variantes que se preguntan

**Arreglo rotado.** `[5, 6, 9, 1, 2, 5]` está ordenado y rotado. En cada paso, **una de las dos
mitades está ordenada** y se puede comprobar en O(1) comparando extremos; si el objetivo cae
dentro de esa mitad ordenada, se busca ahí, y si no, en la otra. Sigue siendo O(log n). Con
duplicados degenera a O(n) en el peor caso, porque los extremos iguales no permiten decidir qué
mitad está ordenada.

**Matriz ordenada.** Si cada fila está ordenada y el primer elemento de cada fila es mayor que
el último de la anterior, la matriz es un arreglo ordenado disfrazado: se busca binariamente
sobre `filas × columnas` y se traduce el índice. Si solo están ordenadas filas y columnas por
separado, el algoritmo es otro: empezar en la **esquina superior derecha** y moverse izquierda o
abajo según la comparación, que es O(filas + columnas).

**Búsqueda exponencial.** Cuando no sabes el tamaño —un flujo, una API paginada—, duplicas el
índice hasta pasarte y después haces binaria en el último intervalo. O(log n) igual, sin conocer
n de antemano.

---

## 6. ⏱️ La tabla de costes

| Algoritmo | Tiempo | Espacio | Requisito | Lo que la tabla no dice |
|---|---|---|---|---|
| Búsqueda lineal | O(n) | O(1) | Ninguno | Con n < 100 puede ganar: sin fallos de caché ni saltos |
| Búsqueda binaria | O(log n) | O(1) | **Ordenado + acceso aleatorio** | Sobre `LinkedList` acaba siendo O(n log n) |
| `lowerBound` / `upperBound` | O(log n) | O(1) | Ordenado | Su diferencia da el número de repeticiones, gratis |
| Binaria sobre la respuesta | O(n · log rango) | O(1) | **Predicado monótono** | El log es del rango de valores, no del número de datos |
| Búsqueda en tabla hash | O(1) amortizado | O(n) | Clave exacta | No responde rangos ni vecinos: eso es [`04`](04-hashing-y-tablas-hash.md) |
| Árbol balanceado | O(log n) | O(n) | Orden | Como la binaria, pero admite inserciones sin reordenar |

> ⏱️ **Coste.** La comparación que conviene tener clara: si los datos **no cambian**, un arreglo
> ordenado con búsqueda binaria gana a un árbol balanceado, porque es contiguo y la caché lo
> agradece. Si los datos **cambian**, el arreglo pierde: cada inserción es O(n) por el
> desplazamiento, y ahí el árbol —o un `TreeMap`— es la respuesta.

---

## 7. ⚖️ Los cinco lenguajes

| Lenguaje | Búsqueda binaria | Fronteras | El detalle que muerde |
|---|---|---|---|
| **Java** | `Arrays.binarySearch`, `Collections.binarySearch` | **No hay** | Devuelve `-(inserción)-1` si no está. Sobre no ordenado, resultado arbitrario sin error |
| **Python** | `bisect.bisect_left` | `bisect_left` / `bisect_right` **son** las fronteras | No devuelve "no encontrado": devuelve dónde iría, que es más útil |
| **JavaScript** | **No hay** | No hay | Se escribe a mano. `findIndex` es lineal y mucha gente lo usa sin darse cuenta |
| **TypeScript** | Igual que JS | Igual que JS | Sin diferencia en runtime |
| **Go** | `slices.BinarySearch` | `sort.Search` es una frontera genérica | `slices.BinarySearch` devuelve `(índice, encontrado)`: el bool separa los dos casos |

La comparación más instructiva es Java contra Python. Java devuelve un número codificado que hay
que decodificar con `-(resultado) - 1`, lo que produce errores de signo constantemente. Python
devuelve directamente el punto de inserción y deja que tú compruebes si el elemento está. **La
API de Python es la frontera; la de Java es la búsqueda exacta con la frontera escondida.**

---

## 8. 🧭 Cómo se elige

```text
¿Datos ordenados y estáticos, muchas consultas?     → arreglo + búsqueda binaria
¿Datos que cambian, y necesitas orden?              → árbol balanceado (TreeMap)
¿Solo pertenencia exacta, sin orden?                → tabla hash
¿Hay duplicados y quieres el primero o contarlos?   → lowerBound / upperBound
¿"El menor X que cumple", "minimiza el máximo"?     → binaria sobre la respuesta
¿No sabes el tamaño del espacio?                    → búsqueda exponencial y después binaria
¿n < 100?                                           → lineal, y dilo a propósito
```

> **Regla de entrevista:** si el enunciado contiene "ordenado", "el primero que", "el menor
> valor tal que" o "minimiza el máximo", la respuesta lleva búsqueda binaria dentro. Las cuatro
> señales son literales y se reconocen antes de entender el problema entero.

---

## 9. 🔭 Dónde aparece de verdad

En el índice B+tree de una base de datos, donde cada nodo se recorre con búsqueda binaria y el
`WHERE fecha BETWEEN` es un `lowerBound` seguido de un recorrido secuencial; en el
`git bisect`, que es literalmente búsqueda binaria sobre el historial para encontrar el commit
que rompió algo; en los despliegues canario, donde se busca el porcentaje de tráfico que el
sistema aguanta; en el dimensionado de un pool de conexiones o de un `work_mem`, que es búsqueda
binaria sobre la respuesta hecha a mano; y en la resolución de un `git blame` o de una
compactación por rangos en un LSM-tree.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`(lo + hi) / 2`" | Desborda con arreglos enormes. `lo + (hi - lo) / 2` |
| "La búsqueda binaria devuelve -1 si no está" | En Java devuelve `-(punto de inserción) - 1`, que es información útil |
| "Da igual si `hi` es inclusivo o exclusivo" | Decide la condición del bucle y las actualizaciones. Mezclarlos cuelga el bucle |
| "Con duplicados devuelve el primero" | Devuelve **alguno**. Para el primero hace falta `lowerBound` |
| "Busco binariamente en una `LinkedList`" | El acceso por índice es O(n): el total es O(n log n), peor que recorrer |
| "`binarySearch` sobre datos sin ordenar falla" | No falla: devuelve un resultado arbitrario, sin excepción |
| "La binaria solo sirve con arreglos" | Sirve con cualquier predicado monótono: es la binaria sobre la respuesta |

---

## 📚 Para profundizar

- **Libro** — Bentley, *Programming Pearls*, 2ª ed. (Addison-Wesley, 1999). Columnas 4 y 5:
  escribir la búsqueda binaria correctamente, con invariantes y verificación. **Es el texto
  clásico sobre este tema y sigue siendo el mejor.**
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT
  Press, 2022). Capítulo 2, con el análisis de la recurrencia `T(n) = T(n/2) + O(1)`.
- **Libro** — Aziz, Lee y Prakash, *Elements of Programming Interviews in Java* (2018). Su
  capítulo de búsqueda binaria incluye la variante sobre la respuesta, que casi ningún libro
  trata.
- [cp-algorithms — Binary search](https://cp-algorithms.com/num_methods/binary_search.html):
  la formulación por predicado monótono y la búsqueda sobre la respuesta, con las dos fronteras.
- [Java 21 API — `Arrays`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Arrays.html):
  el contrato de `binarySearch`, incluido qué devuelve cuando no encuentra y la advertencia
  sobre arreglos no ordenados.
- [Python — `bisect`](https://docs.python.org/3/library/bisect.html):
  `bisect_left` y `bisect_right` como fronteras, con recetas para buscar, contar e insertar.
- [Go — `slices`](https://pkg.go.dev/slices): `BinarySearch`, `BinarySearchFunc` y la relación
  con `sort.Search`.
- **Video** — NeetCode, la lista de *Binary Search*, que agrupa por variante (rotado, matriz,
  sobre la respuesta) en vez de por dificultad.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Cuál es la complejidad de la búsqueda binaria y cuál su requisito? 🟢
2. ¿Por qué `mid = (lo + hi) / 2` es un bug? 🟢
3. ¿Qué devuelve `Arrays.binarySearch` cuando el elemento no está? 🟢
4. ¿Qué vale `lo` cuando el bucle de la búsqueda binaria termina sin encontrar? 🟢
5. ¿Qué hace `lowerBound` y en qué se diferencia de la búsqueda canónica? 🟢
6. ¿Cómo cuentas cuántas veces aparece un valor en un arreglo ordenado, en O(log n)? 🟢
7. ¿Qué cambia entre el convenio de `hi` inclusivo y `hi` exclusivo? 🟡
8. ¿Por qué `hi = mid` y no `hi = mid - 1` en `lowerBound`? 🟡
9. ¿Qué pasa si llamas a `Arrays.binarySearch` sobre un arreglo sin ordenar? 🟡
10. ¿Por qué buscar binariamente en una `LinkedList` es peor que recorrerla? 🟡
11. ¿Qué requisito imprescindible tiene la búsqueda binaria sobre la respuesta? 🟡
12. ¿Por qué en Java el valor de retorno lleva un `-1` extra además del signo? 🟠
13. ¿Por qué la API de `bisect` de Python es más difícil de usar mal que la de Java? 🟠
14. Escribe `upperBound` a partir de `lowerBound` y di qué cambia exactamente. 🟠
15. ¿Cómo buscas en un arreglo ordenado y rotado, y qué complejidad tiene? 🟠
16. ¿Por qué la búsqueda en un arreglo rotado **con duplicados** degenera a O(n)? 🟠
17. En una matriz con filas y columnas ordenadas por separado, ¿por qué se empieza por la
    esquina superior derecha? 🟠
18. ¿Cuándo gana un arreglo ordenado a un `TreeMap`, y cuándo pierde? 🟠
19. ¿Qué es la búsqueda exponencial y cuándo la usarías? 🟠
20. ¿Por qué el logaritmo de la búsqueda sobre la respuesta es del rango de valores y no del
    número de elementos? 🟠
21. ¿Cuándo es correcto usar búsqueda lineal aunque los datos estén ordenados? 🟠
22. Escribe la búsqueda binaria completa y di, línea a línea, por qué cada una es como es. 🔴
23. "Reparte 10 000 pedidos entre 8 repartidores minimizando la carga del más cargado."
    Diseña la solución y di su complejidad. 🔴
24. Un método encuentra a veces el elemento y a veces no, sobre los mismos datos. Da tres
    hipótesis en orden de probabilidad. 🔴
25. Diseña la búsqueda de "el primer despliegue que introdujo el error" sobre 4 000 commits,
    sabiendo que cada comprobación tarda 10 minutos. ¿Cuánto tardas? 🔴

---

**Anterior:** [`02` — Comparadores y orden total](02-comparadores-y-orden-total.md) ·
**Siguiente:** [`04` — Hashing y tablas hash](04-hashing-y-tablas-hash.md) ·
**Relacionado:** [`04-arboles-grafos/01` — Árboles](../04-arboles-grafos/01-arboles.md)
