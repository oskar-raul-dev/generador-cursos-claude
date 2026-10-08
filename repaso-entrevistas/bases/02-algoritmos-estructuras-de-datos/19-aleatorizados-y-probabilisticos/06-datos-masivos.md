# 06 — Datos masivos

> Qué cambia cuando los datos no caben en memoria o llegan en un flujo que no se puede guardar: el modelo de
> memoria externa, donde lo que se cuenta son las lecturas de bloques; el modelo de flujo, con memoria
> sublineal y una sola pasada; y MapReduce, que reparte el trabajo entre muchas máquinas a cambio de mover
> datos por la red. Para cada uno, qué garantiza, cuánto cuesta y cuándo aparece.
>
> **Niveles:** MapReduce [C] · algoritmos de flujo de datos [C] · memoria externa [C].
>
> **📚 Lectura troncal:** La Rocca, *Advanced Algorithms and Data Structures* (Manning, 2021), cap. 13;
> Medjedovic, Tahirovic y Dedovic, *Algorithms and Data Structures for Massive Datasets* (Manning, 2022),
> caps. 6, 9 y 11.
>
> **Asume leído:** [`19/03` — Estructuras probabilísticas](03-estructuras-probabilisticas.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--memoria-externa) · [4](#4--algoritmos-de-flujo-de-datos) · [5](#5--mapreduce) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Hay 100 GB de registros que ordenar y 4 GB de memoria. O un flujo de mil millones de eventos por hora del que
hay que sacar los más frecuentes, sin poder guardarlo. O un terabyte de texto que contar palabra por palabra
antes de mañana. Los algoritmos de los bloques anteriores suponen que todo está en memoria y que leer
cualquier posición cuesta lo mismo; aquí ninguna de las dos cosas es cierta.

Cada situación tiene su modelo de coste. Con datos en disco, lo caro es **leer y escribir bloques**, y un
algoritmo bueno es el que lee cada dato pocas veces y en orden. Con un flujo, lo escaso es la **memoria**: se
ve cada dato una vez. Con muchas máquinas, lo caro es **mover datos** entre ellas.

> 🧠 **Modelo mental.** Con datos masivos, el coste deja de ser «operaciones» y pasa a ser «veces que
> toco cada dato»: pasadas por el disco, memoria por elemento del flujo, bytes por la red.

---

## 2. 📐 La teoría

**Modelo de memoria externa** (Aggarwal y Vitter). Una memoria de `M` elementos y un disco que se lee en
bloques de `B` elementos. El coste es el número de bloques transferidos (E/S):

```text
recorrer N elementos:     Θ(N/B)
ordenar N elementos:      Θ((N/B) · log_{M/B}(N/B))        ordenación externa por mezcla
buscar en un árbol B:     Θ(log_B N)                       un nodo por bloque
```

**Ordenación externa.** Se leen trozos de `M`, se ordenan en memoria y se escriben (`N/M` *runs*); después se
mezclan `M/B − 1` *runs* a la vez, con un búfer de un bloque por *run*. Con 100 GB y 4 GB, son 25 *runs* de 4
GB y **una** pasada de mezcla de 25 vías: el dato se lee dos veces y se escribe dos.

**Modelo de flujo.** Los datos llegan uno a uno; se ven una vez (o pocas); la memoria es sublineal en `n`
(idealmente `O(log n)` o constante). Lo que se calcula es aproximado o aleatorizado: las estructuras de
[`19/03`](03-estructuras-probabilisticas.md), el *reservoir* de [`19/04`](04-muestreo-y-markov.md) y
algoritmos deterministas como Misra-Gries.

**Misra-Gries.** Con `k` contadores: si el elemento tiene contador, se suma 1; si hay un contador libre, se
crea con 1; si no, se resta 1 a todos y se borran los que llegan a 0. Garantía: todo elemento con frecuencia
mayor que `n/(k + 1)` sobrevive, y su contador subestima su frecuencia en como mucho `n/(k + 1)`.

**MapReduce.** Un cálculo en tres fases: *map* (cada máquina transforma su parte en pares clave-valor),
*shuffle* (la red agrupa los pares por clave) y *reduce* (cada clave se combina). Un *combiner* reduce
localmente antes del *shuffle* para mover menos datos. La ley de Amdahl limita la aceleración: con una
fracción secuencial `s` y `p` máquinas, `aceleración ≤ 1 / (s + (1 − s)/p)`.

---

## 3. 🧱 Memoria externa

**Qué resuelve.** Ordenar, agrupar, unir y buscar datos que no caben en memoria, contando lecturas de disco.

**Qué garantiza.** Ordenación en `Θ((N/B) log_{M/B}(N/B))` E/S, óptima en el modelo; con los tamaños reales
(`M/B` del orden de miles), casi siempre son **dos o tres pasadas**. Los árboles B
([`07/02`](../07-arboles/02-bst-y-balanceados.md)) y las estructuras LSM de las bases de datos buscan en
`O(log_B N)` bloques.

**Cuánto.** En el ejemplo de 100 GB con 4 GB: dos lecturas y dos escrituras completas, 400 GB de E/S. Con un
disco de 500 MB/s, unos 13 minutos de transferencia, frente a horas de un algoritmo que salte por el disco.

**Cómo reconocerlo.** «Los datos no caben en memoria», «un fichero de cientos de GB», «ordenar un log
enorme», «unir dos tablas que no caben».

**Si no te la sabes.** El sistema operativo: `sort` de Unix ya hace ordenación externa; las bases de datos
hacen lo demás. En una entrevista, describir los *runs* y la mezcla de `k` vías con un *heap*
([`08/02`](../08-heaps-y-union-find/02-patrones-con-heap.md)).

**Dónde está entera.** Medjedovic, Tahirovic y Dedovic, caps. 9 y 11; Knuth, Vol. 3, §5.4.

---

## 4. 🧱 Algoritmos de flujo de datos

**Qué resuelve.** Estadísticas de un flujo que no se guarda: elementos frecuentes, distintos, cuantiles,
muestras, sumas en ventanas deslizantes.

**Qué garantiza.** Misra-Gries: los frecuentes de umbral `n/(k + 1)` con `k` contadores, determinista.
Count-Min y HyperLogLog ([`19/03`](03-estructuras-probabilisticas.md)): frecuencias y distintos con error
acotado. *Reservoir* ([`19/04`](04-muestreo-y-markov.md)): una muestra uniforme. Todo con memoria
independiente de `n` (o logarítmica).

**Cuánto.** `O(1)` o `O(k)` por elemento; memoria `O(k)`.

**Cómo reconocerlo.** «En una sola pasada», «no se puede guardar el flujo», «memoria constante», «los más
frecuentes de hoy», «cuántos usuarios distintos».

**Si no te la sabes.** Si cabe, el exacto: un mapa de contadores o un conjunto. Si no, muestrear y contar en la
muestra, aceptando el error de muestreo.

**Dónde está entera.** Medjedovic, Tahirovic y Dedovic, caps. 6–8; Misra y Gries, «Finding repeated
elements», *Science of Computer Programming* 2(2), 1982.

---

## 5. 🧱 MapReduce

**Qué resuelve.** Cálculos sobre datos repartidos en muchas máquinas que se expresan como «transformar cada
registro» y «combinar por clave»: contar palabras, construir índices invertidos, uniones por clave.

**Qué garantiza.** Escalado casi lineal en las fases *map* y *reduce*; tolerancia a fallos (una tarea que falla
se repite). El *shuffle* mueve por la red todo lo que no reduce el *combiner*, y la máquina más lenta
(*straggler*) marca el final de cada fase.

**Cuánto.** Por fase, el máximo de lo que procesa una máquina, más el coste de la red. Contar palabras de 1 TB
con 100 máquinas: cada una lee 10 GB, el *combiner* deja un mapa de palabras por máquina, y el *shuffle* mueve
solo esos mapas.

**Cómo reconocerlo.** «Un terabyte en un clúster», «por clave», «índice invertido», procesamiento por lotes.

**Si no te la sabes.** En una máquina, ordenación externa y un recorrido agrupando por clave hacen lo mismo
que *map* + *shuffle* + *reduce*.

**Dónde está entera.** La Rocca, cap. 13; Dean y Ghemawat, «MapReduce: simplified data processing on large
clusters», *OSDI* (2004).

---

## 6. 🧭 Cómo se elige

```text
¿Cabe en memoria? → los algoritmos de siempre
¿No cabe, pero está en disco y hay que leerlo entero? → memoria externa: pocas pasadas en orden
¿Llega en flujo y no se guarda? → Misra-Gries, Count-Min, HyperLogLog, reservoir
¿Está repartido en muchas máquinas? → MapReduce con combiner; cuidado con el shuffle
¿Hace falta la respuesta exacta? → memoria externa o MapReduce, no un resumen de flujo
```

> **Regla de entrevista:** antes de proponer más máquinas, cuenta cuántas veces se lee cada dato y cuántos
> bytes cruzan la red. Más máquinas no es más rápido si el cuello está en el *shuffle*.

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Ordenar 100 GB con 4 GB de memoria» | Ordenación externa | *Runs* y mezcla de `k` vías |
| «Los más frecuentes en una sola pasada» | Misra-Gries o Count-Min | Memoria `O(k)` |
| «Cuántos distintos en un flujo» | HyperLogLog | Memoria fija |
| «Un terabyte en un clúster, por clave» | MapReduce | *Map*, *shuffle*, *reduce* |
| «Muestra uniforme de un flujo» | *Reservoir* | Una pasada, `O(k)` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Más máquinas es más rápido» | La parte secuencial, el *shuffle* y la máquina más lenta limitan la aceleración (Amdahl) |
| «Con datos en disco, el coste es el número de operaciones» | Es el número de bloques leídos y escritos: lo que importa es leer en orden y pocas veces |
| «Ordenar 100 GB necesita `log₂` pasadas» | Con mezcla de muchas vías, una o dos pasadas de mezcla bastan |
| «En un flujo se pueden calcular los frecuentes exactos con poca memoria» | Hace falta memoria lineal para el exacto; con `k` contadores, garantía aproximada |
| «Misra-Gries da las frecuencias exactas de los que sobreviven» | Las subestima en hasta `n/(k + 1)`; para el exacto, una segunda pasada |
| «El *combiner* cambia el resultado» | Con operaciones asociativas y conmutativas, no; solo reduce lo que viaja por la red |

---

## 📚 Para profundizar

- **Libro** — Medjedovic, Tahirovic y Dedovic, *Algorithms and Data Structures for Massive Datasets*
  (Manning, 2022), caps. 6 (flujos), 9 (memoria externa) y 11 (ordenación externa). *Lectura troncal.*
- **Libro** — La Rocca, *Advanced Algorithms and Data Structures* (Manning, 2021), cap. 13: MapReduce con un
  ejemplo de *clustering*. *Lectura troncal.*
- **Artículo** — Aggarwal y Vitter, «The input/output complexity of sorting and related problems»,
  *Communications of the ACM* 31(9), 1988.
- **Artículo** — Dean y Ghemawat, «MapReduce: simplified data processing on large clusters», *OSDI* (2004).

---

## 🧠 Preguntas

1. ¿Qué se cuenta como coste en el modelo de memoria externa? 🟢
2. ¿Qué tres fases tiene MapReduce? 🟢
3. ¿Qué garantiza Misra-Gries con `k` contadores? 🟢
4. ¿Cuántas pasadas necesita ordenar 100 GB con 4 GB de memoria, y por qué? 🟡
5. ¿Qué diferencia hay entre el modelo de flujo y el de memoria externa? 🟡
6. ¿Para qué sirve un *combiner*, y cuándo no se puede usar? 🟡
7. ¿Por qué «más máquinas es más rápido» es falso, con la ley de Amdahl? 🟠
8. ¿Por qué un árbol B tiene nodos grandes, y qué tiene que ver con `B`? 🟠
9. ¿Cómo encuentras las 100 palabras más frecuentes de 1 TB en un clúster? 🟠
10. ¿Qué harías para tener las frecuencias exactas de los candidatos de Misra-Gries? 🟠
11. Demuestra que Misra-Gries subestima cada frecuencia en como mucho `n/(k + 1)`. 🔴
12. Diseña la ordenación externa de 100 GB con 4 GB de memoria y bloques de 1 MB: *runs*, vías de la mezcla,
    búferes y volumen de E/S. 🔴

---

## 🧩 Problemas propios

### Los candidatos del flujo

**Nivel:** 🟡 · **Formato:** programa completo.

Aplica Misra-Gries con `k` contadores a un flujo de `n` valores: si el valor tiene contador, súmale 1; si no, y
hay menos de `k` contadores, crea uno con 1; si no, resta 1 a todos los contadores y borra los que queden en
0 (el valor actual no se guarda). Imprime los contadores finales, ordenados por valor.

- **Entrada.** Una línea con `n` y `k`. Una línea con los `n` valores.
- **Salida.** Una línea por contador con el valor y su cuenta.
- **Restricciones.** `1 ≤ n ≤ 10⁷`; `1 ≤ k ≤ 1 000`; valores entre `0` y `10⁹`.

```text
Entrada               Salida
8 2                   2 1
5 2 9 1 5 6 5 2       5 1

Entrada               Salida
6 1                   1 2
1 1 1 2 3 1
```

**Pista 1:** con `k` hasta `1 000`, restar 1 a todos cuesta `k`. ¿Cuántas veces puede pasar eso como mucho, si
cada resta se «paga» con elementos anteriores?

### Ordenar lo que no cabe

**Nivel:** 🟠 · **Formato:** diseño, por escrito.

Hay que ordenar un fichero de 100 GB de registros de 100 bytes en una máquina con 4 GB de memoria útil y un
disco que lee y escribe a 500 MB/s en bloques de 1 MB.

- **Entrega.** El número de *runs* y su tamaño; cuántas vías tiene la mezcla y cuántas pasadas de mezcla hacen
  falta; el tamaño de los búferes; el volumen total de E/S y el tiempo de transferencia estimado.
- **Restricción.** La memoria no puede pasar de 4 GB en ningún momento, búferes incluidos.

**Pista 1:** si cada *run* necesita un búfer de un bloque durante la mezcla, ¿cuántos *runs* puedes mezclar a la
vez con 4 GB?

### Las palabras más frecuentes

**Nivel:** 🟠 · **Formato:** diseño, por escrito.

Un clúster de 100 máquinas guarda 1 TB de texto, 10 GB por máquina. Hay que obtener las 100 palabras más
frecuentes del total, con su cuenta exacta.

- **Entrega.** Qué hace cada máquina con sus 10 GB; qué viaja por la red y cuánto ocupa aproximadamente; dónde
  se elige el top 100; qué cambia si solo se quiere una respuesta aproximada y la red es el cuello de botella.
- **Restricción.** Ninguna máquina puede recibir más de 10 GB por la red.

**Pista 1:** antes de enviar nada, ¿qué puede calcular cada máquina sola que reduzca lo que viaja?

---

## 🧩 Práctica externa

> 💡 **Truco.** En las preguntas de diseño, pon números a cada paso (bytes, pasadas, segundos) antes de
> dibujar cajas. Si una IA te ayuda, que sea a revisar tus cuentas, no a darte el diseño
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

Los jueces no evalúan este tema: sus límites de memoria y tiempo están pensados para datos que caben. Se
practica con los propios de diseño, con la simulación ([`19/07`](07-simulacion.md)) y con las preguntas de diseño de sistemas.

---

## ✅ Criterio de dominio

- Calcular las pasadas y la E/S de una ordenación externa para tamaños dados.
- Explicar Misra-Gries con su garantía, y cuándo usar cada estructura de `19/03` en un flujo.
- Describir MapReduce con *combiner* y explicar por qué más máquinas no siempre aceleran.
- Resolver Los candidatos del flujo y las dos preguntas de diseño.

---

**Anterior:** [`19/05` — Estructuras espaciales](05-estructuras-espaciales.md) · **Siguiente:** [`19/07` — Simulación](07-simulacion.md) ·
**Relacionado:** [`19/03` — Estructuras probabilísticas](03-estructuras-probabilisticas.md).
