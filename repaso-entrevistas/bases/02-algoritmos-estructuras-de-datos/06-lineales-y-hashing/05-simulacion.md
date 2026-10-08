# 05 — Simulación

> El examen del bloque `06`: preguntas que cruzan pilas, colas, estructuras monótonas, listas enlazadas,
> tablas *hash* y *hashing* de secuencias; cuatro problemas propios cronometrados que no dicen de qué
> capítulo son, y seis problemas externos que no aparecen antes en el bloque. Las respuestas y las pistas
> 2 y 3 están en el [solucionario](06-respuestas.md#05--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos para cada uno de los dos primeros problemas
  y 20 para los otros dos.
- **En voz alta.** Antes de cada problema, di qué estructura eliges y qué operación necesitas en `O(1)`:
  es la decisión que define este bloque.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en los dos primeros ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Pilas, colas y monótonas

**S1.** ¿Qué usarías como cola en Java y en Python, y por qué no `LinkedList` ni `list`? 🟢

**S2.** ¿Por qué la pila monótona es lineal aunque tenga un `while` dentro de un `for`? 🟡

**S3.** ¿Cuándo usas una cola monótona en lugar de una pila monótona? 🟡

### Listas enlazadas

**S4.** ¿Para qué sirve el nodo centinela? 🟢

**S5.** ¿Cómo encuentra Floyd el inicio de un ciclo? 🟡

**S6.** ¿Qué dos estructuras forman una LRU y qué aporta cada una? 🟢

### Tablas *hash*

**S7.** ¿Qué significa que una tabla *hash* sea `O(1)` «esperado»? 🟡

**S8.** ¿Por qué el *rehash* no estropea el `O(1)`? 🟢

**S9.** ¿Qué pasa si una clase redefine `equals` pero no `hashCode`? 🟢

### *Hashing* de secuencias

**S10.** ¿Por qué la base del *hash* polinomial se elige al azar? 🟡

**S11.** ¿Qué módulo usarías para meter `10⁶` *hashes* de subcadenas en un conjunto, y por qué? 🟡

**S12.** ¿Qué diferencia hay entre un *hash* Zobrist y uno de multiconjunto? 🟢

### Las que descolocan

**S13.** Tu solución con `unordered_map` pasa en local y da TLE solo en el test 47 de Codeforces. ¿Qué ha pasado y qué cambias? 🟠

**S14.** «La lista enlazada es mejor que el arreglo para insertar en el medio.» ¿Qué le respondes al entrevistador? 🟠

**S15.** Tu *hash* de subcadenas con base 31 y módulo `10⁹ + 7` falla en un caso enorme y pasa los pequeños. ¿Por qué, y qué cambias? 🟠

**S16.** Te piden «el máximo de cada ventana» y escribes una pila monótona. ¿Qué falla? 🟠

**S17.** «Uso `HashMap<int[], Integer>` para contar arreglos repetidos y no cuenta nada.» ¿Por qué? 🟠

**S18.** Demuestra que, tras el encuentro de Floyd, avanzar desde el principio y desde el encuentro a la vez acaba en el inicio del ciclo. 🔴

**S19.** ¿Por qué una familia universal de funciones de *hash* protege de cualquier entrada, y una función fija no? 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Torres en círculo

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** resolver «el siguiente mayor» cuando la secuencia da la vuelta.

Hay `n` torres en círculo con alturas `hᵢ`. Para cada torre, imprime cuántas posiciones hay que avanzar en
sentido horario hasta la primera torre estrictamente más alta, o `-1` si no hay ninguna.

- **Entrada.** Una línea con `n`. Una línea con las `n` alturas.
- **Salida.** `n` enteros separados por espacios.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ hᵢ ≤ 10⁹`.

```text
Entrada            Salida
6                  2 1 -1 1 1 3
5 2 9 1 5 6

Entrada            Salida
3                  -1 -1 -1
3 3 3
```

**Pista 1:** si duplicas el arreglo, ¿qué parte del problema circular se convierte en lineal?

### Caché de miniaturas

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** elegir la estructura que mueve un elemento al frente y expulsa el último en `O(1)`.

Un servidor guarda en memoria como mucho `C` miniaturas y, cuando está lleno, expulsa la usada hace más
tiempo. Llegan `q` peticiones de miniaturas; una petición de una miniatura que no está en memoria es un
**fallo** (y la carga). Imprime el número de fallos.

- **Entrada.** Una línea con `C` y `q`. Una línea con los `q` identificadores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ C ≤ q ≤ 10⁶`; `1 ≤ identificador ≤ 10⁹`.

```text
Entrada                          Salida
2 6                              5
1 2 1 3 2 1

Entrada                          Salida
3 12                             10
1 2 3 4 1 2 5 1 2 3 4 5
```

**Pista 1:** con `C = 10⁶`, ¿cuánto cuesta buscar la menos reciente si recorres la memoria entera?

### Pares de suma exacta

**Nivel:** 🟡 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** usar una tabla *hash* que un caso preparado no pueda degradar.

Cuenta los pares de posiciones `i < j` con `a[i] + a[j] = S`. Los casos de prueba incluyen entradas
construidas contra la función de *hash* por defecto de `unordered_map`.

- **Entrada.** Una línea con `n` y `S`. Una línea con los `n` valores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ a[i] ≤ 10⁹`; `2 ≤ S ≤ 2·10⁹`.

```text
Entrada            Salida
6 10               2
5 2 9 1 5 6

Entrada            Salida
3 8                3
4 4 4
```

**Pista 1:** recorriendo de izquierda a derecha, ¿qué necesitas saber de los anteriores para cada `a[j]`?

### Primera letra repetida

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no usar una tabla *hash* donde bastan 26 casillas.

Imprime la primera letra que aparece por segunda vez al leer la cadena de izquierda a derecha, o
`ninguna`.

- **Entrada.** Una línea con la cadena.
- **Salida.** Una letra, o `ninguna`.
- **Restricciones.** Hasta `10⁶` letras minúsculas.

```text
Entrada            Salida
abracadabra        a

Entrada            Salida
abc                ninguna
```

**Pista 1:** ¿cuántos valores distintos puede tomar la clave?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Happy Number](https://leetcode.com/problems/happy-number/) | LeetCode | 🟢 | Si el proceso no llega a 1, ¿qué tiene que pasar con los números que salen? |
| [ ] | [Word Pattern](https://leetcode.com/problems/word-pattern/) | LeetCode | 🟢 | ¿Basta con comprobar la correspondencia en un sentido? |
| [ ] | [Minimum Add to Make Parentheses Valid](https://leetcode.com/problems/minimum-add-to-make-parentheses-valid/) | LeetCode | 🟡 | ¿Qué te dice un contador que baja de cero? |
| [ ] | [Partition List](https://leetcode.com/problems/partition-list/) | LeetCode | 🟡 | ¿Cuántas listas construyes mientras recorres, y cómo las unes? |
| [ ] | [Decode String](https://leetcode.com/problems/decode-string/) | LeetCode | 🟡 | Al cerrar un corchete, ¿qué necesitas recuperar de antes de abrirlo? |
| [ ] | [Max Chunks To Make Sorted II](https://leetcode.com/problems/max-chunks-to-make-sorted-ii/) | LeetCode | 🟠 | ¿Qué tiene que cumplir el máximo de un trozo respecto de lo que viene después? |

---

## ✅ Las frases que hay que tener listas

> «Cada elemento entra y sale de la pila una sola vez: el bucle de dentro suma `n` en total, así que es
> lineal.»

> «El `O(1)` de la tabla *hash* es esperado. Si alguien puede elegir las claves, uso una semilla
> aleatoria; si necesito orden, un mapa ordenado.»

> «Con `10⁵` *hashes* en un conjunto y un módulo de `10⁹`, el cumpleaños da colisiones: uso `2⁶¹ − 1` y
> base aleatoria.»

---

**Anterior:** [`06/04` — *Hashing* de secuencias](04-hashing-de-secuencias.md) ·
**Siguiente:** [`06/06` — Respuestas](06-respuestas.md) ·
**Relacionado:** [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*](03-tablas-hash.md).
