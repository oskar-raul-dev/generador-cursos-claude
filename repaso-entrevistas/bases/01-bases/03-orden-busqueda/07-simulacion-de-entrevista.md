# 07 — Simulación de entrevista

> El examen del bloque. Treinta y cuatro preguntas `S#` transversales que cruzan los cuatro
> capítulos, más cinco problemas de pizarra. Se contesta **en voz alta y cronometrado**, y los
> problemas se **teclean**.
> Asume leídos [`01`](01-ordenacion.md) a [`06`](06-algoritmos-sobre-flujos.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA. Grábate.
3. Los problemas de pizarra se TECLEAN, en 20 minutos, sin autocompletado.
4. Solo después vas a `08-respuestas.md`.
5. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

> **Regla:** este bloque es el que más código tiene que salir de tus dedos. Una respuesta
> correcta que no puedes teclear no sirve: la búsqueda binaria y el `hashCode` se escriben, no
> se describen.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Ordenación

**S1.** Te preguntan "¿cómo ordenarías esto?". ¿Qué tres cosas dices en la respuesta? 🟢

**S2.** ¿Qué ejecuta realmente `Arrays.sort` y por qué depende del tipo? 🟡

**S3.** ¿Qué es la estabilidad y en qué caso real decide? 🟡

**S4.** ¿Por qué quicksort sigue siendo el más rápido si su peor caso es O(n²)? 🟠

**S5.** ¿Cuándo eliges merge sort sabiendo que cuesta O(n) de memoria? 🟠

**S6.** ¿Cuándo NO deberías ordenar aunque el enunciado diga "ordena"? 🟠

**S7.** Te dan 100 GB para ordenar y 8 GB de RAM. Explica el plan. 🔴

### Bloque B — Comparadores

**S8.** ¿Cuáles son las tres propiedades de un orden total? 🟢

**S9.** ¿Por qué `(a, b) -> a - b` es peligroso? 🟡

**S10.** ¿Por qué un comparador roto falla en producción y no en test? 🟠

**S11.** ¿Qué pasa si `compareTo` y `equals` no coinciden? 🟠

**S12.** Un listado paginado repite un registro en dos páginas. ¿Qué hipótesis tienes? 🟠

**S13.** ¿Por qué Python eliminó `cmp` y dejó `key`? ¿Qué dos problemas resuelve eso? 🟠

### Bloque C — Búsqueda

**S14.** ¿Cuál es el requisito de la búsqueda binaria y cuál su complejidad? 🟢

**S15.** ¿Por qué `mid = (lo + hi) / 2` es un bug? 🟢

**S16.** ¿Qué devuelve `Arrays.binarySearch` si el elemento no está, y por qué es útil? 🟡

**S17.** ¿Qué es `lowerBound` y para qué sirve la diferencia con `upperBound`? 🟡

**S18.** ¿Qué es la búsqueda binaria sobre la respuesta y qué requisito tiene? 🟠

**S19.** ¿Cuándo un arreglo ordenado gana a un `TreeMap` y cuándo pierde? 🟠

**S20.** Te dicen "el método a veces encuentra el elemento y a veces no". ¿Por dónde
empiezas? 🟠

### Bloque D — Hashing

**S21.** ¿Cuál es el contrato `equals`/`hashCode`? 🟢

**S22.** ¿Qué complejidad tiene `HashMap.get` y con cuántos matices? 🟡

**S23.** ¿Por qué una clave mutable es un error? 🟡

**S24.** ¿Qué hace Java 8 con un bucket saturado y por qué se hizo? 🟠

**S25.** ¿Qué problema resuelve el hashing consistente? 🟠

**S26.** ¿Cuándo usarías un filtro de Bloom y qué aceptas al usarlo? 🟠

**S27.** Un `get` devuelve `null` para una clave que está en el mapa. Diagnostica. 🔴

### Bloque E — Elección y los cinco lenguajes

**S28.** Ordenado contra hash contra árbol: da el criterio de elección en tres frases. 🟠

**S29.** ¿Qué garantiza cada uno de los cinco lenguajes sobre el orden de iteración de su
mapa? 🟠

**S30.** ¿Qué devuelve `[10, 9, 1].sort()` en JavaScript y qué dice eso del diseño de la
API? 🟠

**S31.** ¿Por qué Go rechaza en compilación una clave de mapa no comparable, y qué opina Java
de eso? 🟠

### Bloque F — Las que descolocan

**S32.** "Nunca he tenido que implementar un `sort`, ¿para qué me sirve esto?" Responde. 🔴

**S33.** El entrevistador insiste en que tu solución con `HashMap` es O(n). ¿Cómo lo
resuelves? 🔴

**S34.** ¿Cuál es el bug más difícil que has diagnosticado relacionado con una colección? 🔴

---

## 3. 🧪 Problemas de pizarra

Veinte minutos cada uno, tecleando y narrando. La solución completa está en
[`06`](08-respuestas.md).

### P1 — Los dos que suman

**Fuerza:** elegir entre ordenar y hashear, con los índices como restricción oculta.

Dado un arreglo de enteros **sin ordenar** y un objetivo, devuelve los **índices** de dos
elementos que sumen el objetivo. Da la fuerza bruta primero, después la solución buena, y
explica por qué la restricción de devolver índices descarta una de las dos opciones evidentes.

Repregunta: *"¿y si hay duplicados?"*.

### P2 — La búsqueda binaria completa

**Fuerza:** escribir sin off-by-one y explicar cada línea.

Escribe `lowerBound` sobre un arreglo ordenado con duplicados: el índice del **primer** elemento
mayor o igual que el objetivo. Explica el invariante, el convenio de `hi`, y qué devuelve cuando
todos los elementos son menores.

Repregunta: *"escribe ahora `upperBound` y cuenta las repeticiones"*.

### P3 — La caché LRU

**Fuerza:** combinar dos estructuras, y saber que existe la respuesta de cinco líneas.

Implementa una caché LRU con `get` y `put` en O(1). Empieza diciendo la solución corta con
`LinkedHashMap` y después impleméntala a mano, porque el enunciado dice "sin usar utilidades de
la biblioteca".

Repregunta: *"¿y si tiene que ser segura entre hilos?"*.

### P4 — La carga del repartidor

**Fuerza:** reconocer una búsqueda binaria sobre la respuesta donde no hay nada ordenado.

Tienes 10 000 pedidos con su peso, en un orden que no se puede alterar, y 8 repartidores. Cada
repartidor se lleva un tramo **contiguo** de pedidos. Minimiza el peso del repartidor más
cargado. Escribe la solución y di su complejidad.

Repregunta: *"¿por qué el logaritmo no es de 10 000?"*.

### P5 — El `hashCode` del dominio

**Fuerza:** que la respuesta correcta es cambiar el diseño, no el método.

Te dan una clase `Cliente` con `nombre`, `correo` y `fechaDeAlta` mutables, que se usa como
clave de un `HashMap` de sesiones. Escribe `equals` y `hashCode` correctos y explica qué sigue
estando mal aunque los escribas bien.

Repregunta: *"¿y si es una entidad JPA con `id` generado?"*.

---

## 4. 🧠 Las frases que hay que tener listas

> **Sobre ordenar:** *"Complejidad, estabilidad y espacio. Java usa dual-pivot quicksort con
> primitivos porque la estabilidad no significa nada ahí, y TimSort con objetos porque sí."*

> **Sobre buscar:** *"La binaria no busca un valor, busca la frontera entre 'no cumple' y 'sí
> cumple'. Por eso sirve también cuando no hay ningún arreglo, si el predicado es monótono."*

> **Sobre hashear:** *"Uso un `HashMap` con el identificador como clave, que es inmutable. Es
> O(1) amortizado con buen `hashCode`, y desde Java 8 el peor caso es O(log n) si las claves son
> comparables."*

---

**Anterior:** [`06` — Algoritmos sobre flujos](06-algoritmos-sobre-flujos.md) ·
**Siguiente:** [`08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`04-arboles-grafos/05` — Simulación](../04-arboles-grafos/05-simulacion-de-entrevista.md)
