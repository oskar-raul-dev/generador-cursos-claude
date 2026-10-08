# 06 — Algoritmos sobre flujos

> Qué haces cuando los datos no caben y solo puedes recorrerlos una vez: muestreo de reservorio,
> Count-Min Sketch para frecuencias, HyperLogLog para cardinalidad y t-digest para percentiles. Las
> cuatro estructuras que aparecen en el corpus de pasada y que aquí se explican, con el precio que
> todas comparten: **la respuesta deja de ser exacta**.
> Asume leído [`04` — Hashing y tablas hash](04-hashing-y-tablas-hash.md), en especial el filtro de
> Bloom.
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

El corpus ya ha propuesto tres veces una solución que no cabe:

```text
"los 100 productos más vendidos de un flujo continuo"   → heap acotado, y ¿el mapa de conteos?
"cuántos usuarios distintos hoy"                        → un HashSet de 500 millones de ids
"el percentil 99 de latencia del último minuto"         → guardar todas las muestras
```

El heap acotado del top-K es O(k) de memoria, pero **el mapa de frecuencias que lo alimenta es
O(elementos distintos)**, y con cien millones de productos distintos eso ya no cabe. Ahí se acaba lo
exacto.

El modelo de flujo tiene tres restricciones, y las tres a la vez:

```text
1. Una sola pasada: no puedes volver atrás
2. Memoria sublineal: mucho menos que el número de elementos
3. Tiempo constante por elemento: llegan más rápido de lo que puedes pensar
```

**Con esas tres restricciones, la respuesta exacta es imposible** para casi cualquier pregunta
interesante. Lo que se negocia es qué tipo de error aceptas, y ese es el contenido del capítulo.

> **Regla de entrevista:** cuando digas "usaría HyperLogLog", di en la misma frase **cuál es el error
> y por qué es aceptable aquí**. Una estructura probabilística propuesta sin nombrar su error es una
> respuesta a medias.

---

## 2. 🧱 Muestreo de reservorio

**El problema.** Quedarte con k elementos **uniformemente aleatorios** de un flujo cuya longitud no
conoces. Sin saber n no puedes decidir con qué probabilidad quedarte con cada uno.

**Cómo va.** Los k primeros entran directos. A partir de ahí, el elemento i-ésimo entra con
probabilidad k/i, sustituyendo a uno al azar:

```java
List<T> reservorio = new ArrayList<>(k);
int i = 0;
for (T elemento : flujo) {
    if (i < k) reservorio.add(elemento);
    else {
        int j = aleatorio.nextInt(i + 1);        // 0..i inclusive
        if (j < k) reservorio.set(j, elemento);
    }
    i++;
}
```

**Por qué es uniforme.** Cada elemento acaba en el reservorio con probabilidad exactamente k/n,
aunque n no se conozca hasta el final: la probabilidad de entrar decrece igual de rápido que la de
ser expulsado después. Verificado empíricamente con 10 elementos, k=3 y 300 000 ensayos:

```text
esperado por elemento: 0.3000
observado: 0.2992  0.2988  0.2997  0.3017  0.2996  0.2997  0.2984  0.3017  0.3002  0.3008
```

**Cuánto.** O(1) por elemento, **O(k) de memoria**, una sola pasada.

**Cuándo sí.** Muestrear logs o eventos para analizarlos después; conservar ejemplos
representativos de un flujo infinito; el *sampling* de trazas de un sistema de observabilidad.

**Cuándo no.** Cuando el muestreo debe ser **reproducible** —dos ejecuciones dan muestras distintas—
o cuando necesitas que ciertos elementos entren siempre: ahí se usa muestreo estratificado o
determinista por hash, `hash(id) % 100 < 1` para un 1 %, que además es estable entre ejecuciones y
entre nodos.

> **Veredicto:** es el único algoritmo de este capítulo cuyo resultado es **exacto en distribución**:
> no aproxima nada, solo no sabe cuál te va a tocar. Por eso es el más fácil de defender.

---

## 3. 🧱 Count-Min Sketch: frecuencias aproximadas

**El problema.** "¿Cuántas veces ha aparecido este elemento?" sobre un flujo con demasiados
elementos distintos como para un mapa de conteos.

**Cómo va.** Una matriz de contadores de `d` filas por `w` columnas, y `d` funciones hash
independientes. Al llegar un elemento, se incrementa una celda por fila. Al consultar, se toma el
**mínimo** de las `d` celdas.

```text
hash1(x) → fila 0, col 5   → +1
hash2(x) → fila 1, col 2   → +1
hash3(x) → fila 2, col 9   → +1

consultar(x) = min(fila0[5], fila1[2], fila2[9])
```

- **El mínimo es la clave.** Cada celda puede haber sido incrementada por otros elementos que
  colisionaron, así que **toda celda sobreestima**. El mínimo es la menos contaminada.
- El error es **solo por exceso**: nunca subestima. Esa asimetría es la que hay que enunciar, igual
  que en el filtro de Bloom —que nunca da falsos negativos—.
- Memoria `d × w` contadores, independiente del número de elementos distintos. Con unos pocos MB se
  cubren flujos de miles de millones.

**Cuándo sí.** *Heavy hitters* —qué elementos superan un umbral de frecuencia—, detección de picos,
limitación de tasa aproximada por clave, y **alimentar el top-K cuando el mapa exacto no cabe**, que
es el hueco que este capítulo venía a tapar.

**Cuándo no.** Cuando necesitas el conteo exacto de un elemento concreto, o cuando los elementos
raros importan: el error absoluto es proporcional al total del flujo, así que **los elementos poco
frecuentes quedan sepultados** bajo el ruido de los frecuentes.

---

## 4. 🧱 HyperLogLog: cardinalidad aproximada

**El problema.** "¿Cuántos usuarios **distintos** hubo hoy?" Un `HashSet` de 500 millones de
identificadores no cabe, y la respuesta no necesita ser exacta.

**Cómo va.** La intuición es sorprendentemente simple: si hasheas los elementos y observas el
**máximo número de ceros iniciales** que has visto en algún hash, puedes estimar cuántos elementos
distintos hubo. Ver un hash que empieza por 10 ceros sugiere que has visto del orden de 2¹⁰
elementos distintos.

```text
un solo contador → estimación pésima, con varianza enorme
HyperLogLog → 2^p registros, cada uno con su propio máximo, y se promedian con la media armónica
```

- La media **armónica** es lo que hace bueno al algoritmo: amortigua los valores atípicos, que es
  justo lo que estropea la estimación ingenua.
- Con **12 KB** de memoria, el error típico ronda el **2 %**, para cardinalidades de miles de
  millones. Esa relación —kilobytes para contar miles de millones— es lo que lo hace célebre.
- Dos HyperLogLog se pueden **fusionar** tomando el máximo registro a registro. Por eso se puede
  calcular por nodo y agregar después, que es lo que lo hace viable en sistemas distribuidos.

**Cuándo sí.** Usuarios únicos, direcciones IP distintas, cardinalidad de una dimensión en analítica.
Redis lo trae como tipo nativo (`PFADD`, `PFCOUNT`, `PFMERGE`).

**Cuándo no.** Cuando el número tiene consecuencias contractuales o contables —facturar por usuarios
únicos con un 2 % de error es un problema legal, no técnico— o cuando la cardinalidad es pequeña, en
cuyo caso un `HashSet` es exacto y cabe.

> ⚠️ **Advertencia.** HyperLogLog cuenta **cuántos**, no **cuáles**. No se puede preguntar si un
> elemento concreto estaba: para eso es el filtro de Bloom de
> [`04` §6](04-hashing-y-tablas-hash.md#6--dos-derivados-que-se-preguntan). Confundirlos es el error
> más común del tema, y son estructuras con propósitos opuestos.

---

## 5. 🧱 Percentiles: t-digest y HdrHistogram

**El problema.** El p99 de latencia. La media no sirve —esconde exactamente la cola que te
interesa— y guardar todas las muestras para ordenarlas no cabe.

**Por qué no basta con los dos heaps.** La mediana en streaming de
[`04-arboles-grafos/02`](../04-arboles-grafos/02-monticulos-y-colas-de-prioridad.md) usa O(n) de
memoria: guarda todos los elementos repartidos en dos montículos. Funciona para la mediana de un
flujo moderado y no escala a millones de muestras por segundo.

**Cómo va.** Dos enfoques que se usan de verdad:

- **HdrHistogram**: cubetas de anchura creciente con precisión relativa configurable. Memoria fija y
  conocida, error acotado **por diseño**, y es lo que usan las herramientas de carga serias.
- **t-digest**: agrupa las muestras en centroides, con más resolución en los extremos que en el
  centro — justo al revés que un histograma uniforme. Eso lo hace muy preciso en p99 y p999, que es
  donde miras.

**La propiedad que los hace útiles en sistemas distribuidos** es la misma que la de HyperLogLog: se
pueden **fusionar**. Cada nodo mantiene el suyo y se agregan.

> ⚠️ **Advertencia.** **Los percentiles no se promedian.** La media de los p99 de diez nodos **no es**
> el p99 del conjunto, y es uno de los errores de observabilidad más extendidos. Hay que agregar las
> estructuras y calcular el percentil sobre el resultado. Decir esto en una entrevista de
> arquitectura vale más que conocer los algoritmos.

---

## 6. ⏱️ La tabla de costes

| Estructura | Responde | Memoria | Error | Lo que la tabla no dice |
|---|---|---|---|---|
| **Reservorio** | Una muestra uniforme de k | O(k) | **Ninguno**: es exacto en distribución | No es reproducible entre ejecuciones |
| **Filtro de Bloom** | ¿Puede estar? | ~10 bits/elemento | Falsos positivos, **nunca** negativos | No cuenta ni recupera |
| **Count-Min Sketch** | ¿Cuántas veces? | `d × w` contadores | **Solo sobreestima** | Los elementos raros quedan bajo el ruido |
| **HyperLogLog** | ¿Cuántos distintos? | **~12 KB** | ~2 % | Cuenta *cuántos*, no *cuáles*. Fusionable |
| **t-digest / HdrHistogram** | Percentiles | Fija y configurable | Acotado por diseño | Fusionable. **Los percentiles no se promedian** |
| **Dos heaps** | Mediana exacta | **O(n)** | Ninguno | No escala: guarda todos los elementos |

---

## 7. ⚖️ Los cinco lenguajes

| Lenguaje | Qué hay | El detalle que muerde |
|---|---|---|
| **Java** | Nada en la stdlib; `HdrHistogram`, `stream-lib`, Guava (`BloomFilter`) | Micrometer y Dropwizard traen percentiles: probablemente ya los tienes sin saberlo |
| **Python** | `random.sample` para muestreo cuando la colección cabe; `datasketches` fuera | `statistics.quantiles` exige la muestra completa en memoria |
| **JavaScript** | Nada | Se usa el motor de métricas del entorno, no una biblioteca propia |
| **TypeScript** | Igual que JS | Sin aportación |
| **Go** | Nada en la stdlib; `axiomhq/hyperloglog`, `influxdata/tdigest` | El ecosistema de observabilidad de Go es donde más maduras están estas estructuras |

La observación transversal: **ninguna de estas estructuras está en ninguna biblioteca estándar**, y
casi nadie las implementa. Llegan a través de la infraestructura —**Redis** con `PFADD`, Prometheus
con sus histogramas, Elasticsearch con `cardinality` y `percentiles`—, y el trabajo real es saber
**qué garantía te está dando** la herramienta que ya usas. Esa es la respuesta de arquitecto a este
tema.

---

## 8. 🧭 Cómo se elige

```text
¿Cabe en memoria y necesitas exactitud?      → estructura exacta, y no te compliques
¿Una muestra representativa?                 → reservorio (o hash % 100 si debe ser reproducible)
¿"¿Está?" con memoria mínima?                → filtro de Bloom, asumiendo falsos positivos
¿"¿Cuántas veces?" con demasiados distintos? → Count-Min Sketch, asumiendo sobreestimación
¿"¿Cuántos distintos?"                       → HyperLogLog, ~2 % de error en 12 KB
¿Percentiles de latencia?                    → t-digest o HdrHistogram, y NO promedies percentiles
¿El número tiene consecuencias contables?    → nada aproximado: exacto, aunque cueste
```

> **Regla de entrevista:** la pregunta que decide no es cuál es la estructura, es **qué error puedes
> tolerar y en qué dirección**. Falsos positivos pero no negativos, sobreestimar pero no
> subestimar, 2 % arriba o abajo. Empezar por ahí es lo que convierte una lista de nombres en una
> decisión de ingeniería.

---

## 9. 🔭 Dónde aparece de verdad

En el `PFCOUNT` de Redis que cuenta usuarios únicos de una campaña; en los histogramas de Prometheus,
cuyos *buckets* son exactamente esta negociación entre precisión y memoria; en la agregación
`cardinality` de Elasticsearch, que es HyperLogLog con otro nombre; en el *sampling* de trazas de un
sistema de observabilidad, que es muestreo por hash para que una traza aparezca completa en todos los
servicios; en los filtros de Bloom de un LSM-tree antes de tocar disco; y en la detección de *heavy
hitters* de un WAF para decidir a quién limitar.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "HyperLogLog me dice si el usuario estaba" | Cuenta **cuántos**, no cuáles. Eso es un filtro de Bloom |
| "El Count-Min Sketch puede fallar en los dos sentidos" | **Solo sobreestima**: nunca devuelve menos del conteo real |
| "Promedio los p99 de los diez nodos" | Los percentiles **no se promedian**: hay que fusionar las estructuras |
| "El muestreo aleatorio es aproximado" | El reservorio es **exacto en distribución**: cada elemento entra con probabilidad k/n |
| "Uso los dos heaps para el p99 del flujo" | Son O(n) de memoria. Para percentiles a escala, t-digest |
| "Con un Bloom cuento elementos únicos" | No cuenta: responde pertenencia. Para contar, HyperLogLog |
| "Estas estructuras hay que implementarlas" | Llegan por Redis, Prometheus o Elasticsearch: el trabajo es saber qué garantizan |

---

## 📚 Para profundizar

- **Libro** — Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017). Capítulo 11, sobre
  procesamiento de flujos, que es el contexto arquitectónico de todo este capítulo.
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT Press,
  2022). Capítulo 5, sobre análisis probabilístico y algoritmos aleatorizados, que es el marco
  teórico del reservorio.
- **Libro** — Skiena, *The Algorithm Design Manual*, 3ª ed. (Springer, 2020). Sección 12.6, sobre
  muestreo aleatorio y sus trampas.
- [Redis — HyperLogLog](https://redis.io/docs/latest/develop/data-types/probabilistic/hyperloglogs/):
  `PFADD`, `PFCOUNT` y `PFMERGE`, con el error declarado del 0.81 % estándar.
- [Apache DataSketches](https://datasketches.apache.org/): la biblioteca de referencia de estas
  estructuras, con la explicación de cada garantía de error.
- [Java 21 API — `Random`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Random.html):
  la base del reservorio, con la nota sobre reproducibilidad mediante semilla.
- **Tutorial** — Baeldung, «Bloom Filter in Java with Guava»: la única de estas estructuras con una
  implementación accesible y madura en el ecosistema Java.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Cuáles son las tres restricciones del modelo de flujo? 🟢
2. ¿Qué responde un HyperLogLog? 🟢
3. ¿Qué responde un filtro de Bloom y en qué se diferencia del anterior? 🟢
4. ¿Qué memoria necesita el muestreo de reservorio? 🟢
5. ¿En qué dirección se equivoca un Count-Min Sketch? 🟢
6. ¿Por qué el reservorio se considera exacto y no aproximado? 🟡
7. ¿Por qué el elemento i-ésimo entra con probabilidad k/i? 🟡
8. ¿Por qué el Count-Min Sketch toma el **mínimo** de las celdas? 🟡
9. ¿Por qué HyperLogLog usa la media armónica? 🟡
10. ¿Qué propiedad comparten HyperLogLog y t-digest que los hace útiles en sistemas distribuidos? 🟡
11. ¿Por qué los dos heaps no sirven para el p99 de un flujo grande? 🟡
12. ¿Cuánta memoria necesita HyperLogLog y con qué error? 🟡
13. ¿Por qué no se pueden promediar los percentiles de varios nodos? 🟠
14. ¿Cuándo prefieres muestreo por hash en vez de reservorio? 🟠
15. ¿Por qué los elementos poco frecuentes se pierden en un Count-Min Sketch? 🟠
16. ¿Cuándo NO debes usar ninguna de estas estructuras? 🟠
17. El top-K usa un heap acotado de O(k). ¿Por qué eso no basta sobre un flujo con cien millones de
    elementos distintos? 🟠
18. ¿Qué garantías te está dando Prometheus cuando le pides un p99? 🟠
19. Diseña el conteo de usuarios únicos por campaña y por día, para 200 campañas y 500 millones de
    eventos diarios. 🔴
20. Te piden facturar a un cliente según sus usuarios únicos mensuales. ¿Usarías HyperLogLog?
    Justifica. 🔴

---

**Anterior:** [`05` — Intervalos y barrido de eventos](05-intervalos-y-barrido.md) ·
**Siguiente:** [`07` — Simulación de entrevista](07-simulacion-de-entrevista.md) ·
**Relacionado:** [`04` — Hashing y tablas hash](04-hashing-y-tablas-hash.md)
