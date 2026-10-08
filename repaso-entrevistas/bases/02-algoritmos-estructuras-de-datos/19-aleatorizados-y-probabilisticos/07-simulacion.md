# 07 — Simulación

> El examen del bloque `19`: preguntas que cruzan Las Vegas y Monte Carlo, *hashing* universal, estructuras
> probabilísticas, muestreo, estructuras espaciales y datos masivos; cuatro problemas propios cronometrados que
> no dicen de qué capítulo son —uno se resuelve con el determinista de siempre porque cabe en memoria—, y
> cuatro problemas externos que no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están en el
> [solucionario](08-respuestas.md#07--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos por problema propio (20 para el 🟢).
- **En voz alta.** Antes de cada problema, di si tu solución es exacta, Las Vegas o Monte Carlo, y cuál es su
  garantía (tiempo esperado, probabilidad de error, memoria).
- **Tecleando de verdad**, con un contador de frecuencias en el del depósito: ejecútalo muchas veces sobre un
  flujo corto con números al azar y comprueba que cada elemento sale con la misma probabilidad
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Lo básico y un patrón

**S1.** ¿Qué diferencia hay entre un algoritmo Las Vegas y uno Monte Carlo? 🟢

**S2.** ¿Qué garantiza una familia universal de funciones de *hash*? 🟢

**S3.** ¿Qué responde un filtro de Bloom, y qué error puede cometer? 🟢

**S4.** ¿Cómo se baraja un arreglo de forma uniforme en `Θ(n)`? 🟢

**S5.** ¿Cuánto cuesta una consulta de rango ortogonal en un árbol k-d del plano? 🟡

### Estructuras, flujos y datos masivos

**S6.** ¿Qué estima Count-Min y en qué sentido se equivoca? 🟢

**S7.** ¿Qué resuelve el *reservoir sampling*? 🟢

**S8.** ¿Cuántos bits por elemento necesita un Bloom con un 1 % de falsos positivos? 🟡

**S9.** ¿Qué garantiza Misra-Gries con `k` contadores? 🟡

**S10.** ¿Cuál es la distribución estacionaria de un paseo aleatorio en un grafo no dirigido conexo? 🟡

### Las que descolocan

**S11.** «Aleatorizado significa que a veces falla.» ¿Qué respondes? 🟠

**S12.** Tu solución con `unordered_map` pasa los ejemplos y da TLE tras un *hack*. ¿Qué ha pasado y qué
cambias? 🟠

**S13.** Tu barajado intercambia cada posición con una de todo el arreglo. ¿Qué tiene de malo? 🟠

**S14.** Alguien propone un filtro de Bloom para detectar identificadores repetidos entre `10⁶`. ¿Qué dices? 🟠

**S15.** Tu árbol k-d con vectores de 300 dimensiones no es más rápido que recorrerlos todos. ¿Por qué? 🟠

**S16.** «Para ordenar 100 GB hace falta una máquina con 100 GB de memoria.» ¿Qué respondes? 🟠

**S17.** «Con más máquinas, un trabajo MapReduce termina antes.» ¿Siempre? 🟠

**S18.** Tu Count-Min da frecuencias altas a elementos que casi no aparecen. ¿Es un error de programación? 🟠

**S19.** Demuestra que Freivalds acepta una `C` incorrecta con probabilidad como mucho `1/2`. 🔴

**S20.** Diseña cómo detectar, con memoria fija, las IP que generan más del 1 % del tráfico de un enlace que
recibe `10⁹` paquetes por hora, y di qué garantiza tu diseño. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### El depósito del registro

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** muestrear un flujo sin conocer su longitud.

Llega un flujo de valores y hay que quedarse con `k` de ellos. Los `k` primeros entran directamente. Para que
la ejecución sea comprobable, cada elemento `i > k` (contando desde 1) trae un número `rᵢ`: se calcula
`j = rᵢ mod i`, y si `j < k` el elemento sustituye al que ocupa la casilla `j` (desde 0). Imprime el depósito
final.

- **Entrada.** Una línea con `n` y `k`. Una línea con los `n` valores. Una línea con los `n − k` números `rᵢ`.
- **Salida.** Una línea con los `k` valores del depósito, por casilla.
- **Restricciones.** `1 ≤ k ≤ n ≤ 10⁶`; valores y `rᵢ` entre `0` y `10¹⁸`.

```text
Entrada         Salida
6 2             5 2
5 2 9 1 5 6
3 7 10 22

Entrada         Salida
5 3             50 40 30
10 20 30 40 50
1 5
```

**Pista 1:** ¿qué probabilidad de entrar tiene el elemento `i` si `rᵢ` fuera uniforme, y para qué sirve que la
casilla sea también `j`?

### Dimensionar el filtro

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** pasar de la fórmula continua a parámetros enteros.

Para un filtro de Bloom con `n` elementos, imprime el **menor** número de bits `m` para el que existe un entero
`k ≥ 1` con `(1 − e^{−kn/m})ᵏ ≤ ε`, y el menor `k` que lo consigue con ese `m`.

- **Entrada.** Una línea con `n` y `ε`.
- **Salida.** Una línea con `m` y `k`.
- **Restricciones.** `1 ≤ n ≤ 10⁹`; `10⁻⁶ ≤ ε ≤ 0,5`. Se garantiza que la respuesta no cambia si `ε` varía en
  `10⁻⁹`.

```text
Entrada         Salida
1000 0.01       9593 7

Entrada         Salida
500 0.05        3124 4
```

**Pista 1:** la fórmula continua da un `m` y un `k` reales. ¿Qué pasa con la tasa al redondear `k`, y cómo
encuentras el menor `m` que funciona con algún `k` entero?

### ¿Es el producto?

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** verificar más barato de lo que cuesta calcular.

Imprime `YES` si `A · B = C` módulo `10⁹ + 7`, y `NO` si no.

- **Entrada.** Una línea con `n`. Después, las tres matrices `A`, `B` y `C`, cada una en `n` líneas de `n`
  enteros.
- **Salida.** `YES` o `NO`.
- **Restricciones.** `1 ≤ n ≤ 1 000`; entradas entre `0` y `10⁹ + 6`.

```text
Entrada         Salida
2               YES
1 2
3 4
5 6
7 8
19 22
43 50

Entrada         Salida
2               NO
1 2
3 4
5 6
7 8
19 22
43 51
```

**Pista 1:** con `n = 1 000`, multiplicar son `10⁹` operaciones modulares. ¿Cuánto cuesta multiplicar una matriz
por un vector, y qué te dice comparar `A(Br)` con `Cr`?

### ¿Hay repetidos?

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no usar una estructura aproximada cuando la exacta cabe.

Imprime `YES` si algún identificador aparece más de una vez y `NO` si no.

- **Entrada.** Una línea con `n`. Una línea con `n` identificadores.
- **Salida.** `YES` o `NO`.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; identificadores entre `0` y `10¹⁸`.

```text
Entrada         Salida
6               YES
5 2 9 1 5 6

Entrada         Salida
3               NO
7 8 9
```

**Pista 1:** ¿cuánta memoria ocupan `10⁶` enteros de 64 bits, y qué ganarías aceptando errores?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Same Differences](https://codeforces.com/problemset/problem/1520/D) | Codeforces | 🟢 | Si reescribes `aⱼ − aᵢ = j − i`, ¿qué cantidad tienen que compartir `i` y `j`? |
| [ ] | [Remove Two Letters](https://codeforces.com/problemset/problem/1800/D) | Codeforces | 🟢 | ¿Cuándo dan la misma cadena dos borrados de letras consecutivas en posiciones vecinas? |
| [ ] | [Andrey and Problem](https://codeforces.com/problemset/problem/442/B) | Codeforces | 🟠 | Si pides a un conjunto de amigos, ¿qué probabilidad hay de que exactamente uno te dé el problema, y a quiénes conviene añadir primero? |
| [ ] | [Tourism](https://codeforces.com/problemset/problem/1310/D) | Codeforces | 🔴 | Un camino cerrado sin ciclos impares alterna entre dos grupos de ciudades: ¿qué pasa si repartes las ciudades en dos grupos al azar muchas veces? |

---

## ✅ Las frases que hay que tener listas

> «Las Vegas acierta siempre y su tiempo es aleatorio; Monte Carlo tarda lo mismo y se equivoca con
> probabilidad acotada, que se baja repitiendo. Y la semilla, del reloj.»

> «Bloom: falsos positivos sí, falsos negativos nunca; 10 bits por elemento para el 1 %. Count-Min nunca
> subestima. Si la estructura exacta cabe en memoria, la exacta.»

> «Barajar es Fisher-Yates con `j` en `[0, i]`; muestrear un flujo es el *reservoir*: el elemento `i` entra con
> probabilidad `k/i`.»

---

**Anterior:** [`19/06` — Datos masivos](06-datos-masivos.md) · **Siguiente:** [`19/08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`19/01` — Las Vegas y Monte Carlo](01-las-vegas-y-monte-carlo.md).
