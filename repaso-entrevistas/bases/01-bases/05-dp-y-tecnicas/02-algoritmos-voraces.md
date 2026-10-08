# 02 — Algoritmos voraces

> Por qué el voraz es la técnica más peligrosa del temario —parece correcta casi siempre y lo es
> casi nunca—, cómo se demuestra que funciona con el argumento de intercambio, los cinco problemas
> donde sí es óptimo, y los dos contraejemplos que hay que tener en la punta de la lengua.
> Asume leído [`01` — Programación dinámica](01-programacion-dinamica.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un algoritmo voraz toma, en cada paso, **la decisión que parece mejor localmente**, sin
reconsiderarla nunca. Es el enfoque más natural y el que más gente propone primero, porque casi
siempre produce una respuesta que **parece** correcta.

El problema es que solo a veces lo es:

```text
Cambio de monedas con {1, 5, 10, 25}, objetivo 30
   voraz: 25 + 5              = 2 monedas   ✅ óptimo

Cambio de monedas con {1, 3, 4}, objetivo 6
   voraz: 4 + 1 + 1           = 3 monedas   ❌
   óptimo: 3 + 3              = 2 monedas
```

**El mismo algoritmo, sobre el mismo problema, con otro conjunto de datos, deja de ser óptimo.** Y
no falla ruidosamente: devuelve una respuesta válida y peor, que en producción nadie detecta hasta
que alguien compara con otro sistema.

Por eso el voraz es la técnica que más hay que **justificar**. Con DP, si el estado es correcto el
resultado es óptimo por construcción. Con voraz, la corrección depende de una propiedad del
problema que hay que demostrar o, al menos, argumentar.

> **Regla de entrevista:** si propones un voraz, di en la misma frase **por qué es seguro**. Un
> voraz sin justificación es una apuesta, y el entrevistador casi siempre tiene el contraejemplo
> preparado.

---

## 2. 🧱 Qué hace falta para que un voraz sea correcto

Dos propiedades, y la primera es la que distingue el voraz de la DP:

**Propiedad de elección voraz.** La elección localmente óptima forma parte de **alguna** solución
globalmente óptima. Es decir: elegir lo mejor ahora no te cierra la puerta a lo mejor después.

**Subestructura óptima.** La misma que en DP: tras tomar la decisión, lo que queda es un
subproblema del mismo tipo cuya solución óptima completa la global.

```text
Elección voraz segura + subestructura óptima   →  voraz, O(n log n) típicamente
Solo subestructura óptima                      →  DP, O(n · algo)
```

- **La diferencia práctica:** la DP prueba todas las opciones y se queda con la mejor; el voraz
  **elige una y no vuelve**. Por eso el voraz es mucho más barato y por eso necesita la garantía.
- Cuando existe, el voraz suele ser O(n log n) —dominado por una ordenación— frente al O(n·W) de la
  DP equivalente. La diferencia es enorme, y por eso vale la pena buscarlo.

**Cuándo no perder el tiempo buscándolo:** si al escribir el contraejemplo tardas menos de dos
minutos en encontrarlo, no hay voraz. Esa comprobación empírica es más rápida que cualquier intento
de demostración.

---

## 3. 🧱 El argumento de intercambio

Es la forma estándar de demostrar que un voraz es correcto, y se puede explicar en tres frases sin
formalismo. Se aplica al problema de **selección de actividades**: dado un conjunto de reuniones con
inicio y fin, elegir el máximo número que no se solapen.

**El voraz:** ordenar por **hora de fin** y coger siempre la que termina antes de las compatibles.

**La demostración, por intercambio:**

```text
1. Sea O una solución óptima cualquiera, y sea g la primera actividad que elige el voraz.
2. Si O no contiene g, sustituye en O su primera actividad por g.
3. g termina antes o igual, así que no solapa con el resto de O: la nueva solución
   sigue siendo válida y tiene el mismo tamaño → sigue siendo óptima.
4. Repitiendo, se transforma O en la solución del voraz sin empeorarla. Luego el voraz es óptimo.
```

- La clave del paso 3 es **por qué terminar antes no cierra puertas**: deja el máximo tiempo libre
  para lo que venga después. Ese es el argumento de fondo, y es el que hay que poder decir.
- Ordenar por **duración** o por **hora de inicio** parece igual de razonable y **es incorrecto**.
  Es el contraejemplo que conviene tener preparado: una reunión larga que empieza pronto bloquea
  varias cortas.

> 💡 **Truco.** No hace falta demostrar formalmente en una entrevista. Basta con decir *"es seguro
> porque elegir la que termina antes deja el máximo margen para las siguientes, y cualquier óptimo
> se puede transformar en este sin empeorar"*. Eso **es** el argumento de intercambio dicho en
> lenguaje llano, y demuestra que sabes que hace falta justificarlo.

---

## 4. 🧱 Los cinco donde el voraz sí es óptimo

**Selección de actividades.** Ordenar por hora de fin. O(n log n). Es el caso canónico y el que
mejor se explica.

**Mochila fraccionaria.** Ordenar por ratio valor/peso y llenar hasta agotar la capacidad, partiendo
el último objeto. O(n log n).

- **Contrasta con la mochila 0/1**, donde el voraz **falla** porque no puedes partir los objetos. La
  diferencia entre las dos es una de las mejores preguntas del tema: la fraccionaria es voraz y la
  0/1 es DP, y el motivo es exactamente que una admite fracciones y la otra no.

**Codificación de Huffman.** Combinar repetidamente los dos símbolos menos frecuentes con un heap.
O(n log n). Es compresión real —está en ZIP, JPEG y MP3— y es voraz con demostración.

**Dijkstra, Prim y Kruskal.** Los tres del bloque [`04-arboles-grafos`](../04-arboles-grafos/) son
voraces:

- **Dijkstra** cierra siempre el nodo no cerrado más cercano, y es seguro **porque los pesos no son
  negativos** — la condición que hace válida la elección voraz. Con pesos negativos la propiedad se
  rompe, y eso es exactamente por qué falla.
- **Kruskal y Prim** añaden siempre la arista más ligera disponible, y su corrección viene de la
  propiedad del corte: la arista más ligera que cruza cualquier corte pertenece a algún árbol de
  expansión mínima.

**Planificación para minimizar el tiempo medio de espera.** Ordenar por duración ascendente
(*shortest job first*). Es el mismo razonamiento que la selección de actividades, y aparece en
planificadores de tareas y colas de trabajo.

---

## 5. 🧱 Los dos contraejemplos que hay que tener listos

**Cambio de monedas con sistema no canónico.** `{1, 3, 4}` y objetivo 6: el voraz da 3 monedas, el
óptimo son 2. Sirve para demostrar que *"el voraz funciona con euros"* no implica *"el voraz
funciona"*.

- Un sistema de monedas donde el voraz siempre acierta se llama **canónico**. El euro y el dólar lo
  son por diseño; los sistemas históricos no siempre lo eran.

**Mochila 0/1.** Objetos `(peso 10, valor 60)`, `(20, 100)`, `(30, 120)` con capacidad 50:

```text
voraz por ratio:   10+20 = 30 de peso, valor 160, y no cabe el tercero
óptimo:            20+30 = 50 de peso, valor 220
```

- El voraz por ratio coge los objetos "más eficientes" y se queda sin capacidad para la combinación
  buena. **Con fracciones sería óptimo**; sin ellas, hace falta DP.

**Un tercero que conviene conocer:** el **coloreado de grafos**. Colorear voraz —asignar a cada nodo
el color más bajo disponible— da una solución válida y a veces usa muchos más colores de los
necesarios. El problema es NP-difícil y el voraz es una heurística, no un algoritmo óptimo. Es el
ejemplo de que un voraz puede ser perfectamente útil **sin** ser óptimo.

> ⚠️ **Advertencia.** Un voraz que no es óptimo puede seguir siendo la decisión correcta de
> ingeniería: si el problema es NP-difícil y el voraz da el 95 % del óptimo en tiempo lineal, eso
> gana. Lo que no vale es **no saber** que no es óptimo.

---

## 6. ⏱️ La tabla de costes

| Problema | Voraz | ¿Óptimo? | Alternativa si no | Lo que la tabla no dice |
|---|---|---|---|---|
| Selección de actividades | O(n log n) | ✅ | — | Ordenar por **fin**, no por inicio ni duración |
| Mochila fraccionaria | O(n log n) | ✅ | — | El último objeto se parte: eso es lo que lo salva |
| Mochila 0/1 | O(n log n) | ❌ | DP O(n·W) | El voraz por ratio se queda sin capacidad |
| Cambio de monedas | O(n) | **Depende** | DP O(n·cantidad) | Óptimo solo con sistemas canónicos |
| Huffman | O(n log n) | ✅ | — | Voraz con heap, y es compresión real |
| Dijkstra | O((V+E) log V) | ✅ | Bellman-Ford | Óptimo **porque** los pesos no son negativos |
| Kruskal / Prim | O(E log V) | ✅ | — | Propiedad del corte: la arista más ligera es segura |
| Coloreado de grafos | O(V + E) | ❌ | NP-difícil | Heurística útil aunque no óptima |

---

## 7. 🧭 Cómo se elige

```text
¿Puedes demostrar que la elección local no cierra puertas?  → voraz, y dilo
¿Encuentras un contraejemplo en dos minutos?                → NO hay voraz: DP
¿El problema admite fracciones?                             → suele haber voraz
¿Los objetos son indivisibles y hay una capacidad?          → casi siempre DP
¿El problema es NP-difícil?                                 → voraz como heurística, declarándolo
¿Ordenar por algo hace que el problema se resuelva solo?    → esa es la señal del voraz
```

> **Regla de entrevista:** propón el voraz **con su justificación o con su contraejemplo**. Decir
> *"probé con `{1,3,4}` y 6, y el voraz falla, así que voy a DP"* es una respuesta excelente:
> demuestra método, honestidad y que sabes cuál es el riesgo de la técnica.

> **Veredicto:** el voraz es la técnica con mejor relación código/rendimiento del bloque y la
> única que puede estar **silenciosamente equivocada**. Úsalo cuando puedas nombrar la propiedad
> que lo hace correcto; si no puedes, no es que sea arriesgado: es que no sabes si funciona.

---

## 8. 🔭 Dónde aparece de verdad

En el planificador de tareas que ejecuta primero lo más corto para minimizar la espera media; en la
compresión de cualquier archivo ZIP, JPEG o MP3, que lleva Huffman dentro; en el enrutado de red,
que es Dijkstra y por tanto voraz; en el reparto de carga entre repartidores o entre nodos, donde el
"primer ajuste decreciente" es un voraz con cota de aproximación conocida; y en la selección de qué
funcionalidades caben en un sprint dado un presupuesto de puntos, que es la mochila 0/1 disfrazada
—y donde el voraz por ratio valor/esfuerzo es exactamente lo que hace todo el mundo, sin saber que
no es óptimo—.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El voraz es más simple, lo uso" | Es más simple **y** puede dar una respuesta peor sin avisar |
| "El voraz resuelve el cambio de monedas" | Solo con sistemas canónicos. Con `{1,3,4}` y 6 falla |
| "La mochila se resuelve por ratio" | La **fraccionaria** sí; la 0/1 no, y la diferencia es poder partir |
| "Ordeno por duración las reuniones" | Hay que ordenar por **hora de fin**; por duración es incorrecto |
| "Dijkstra es DP" | Es voraz, y su corrección depende de que los pesos no sean negativos |
| "Si el voraz no es óptimo, no sirve" | En problemas NP-difíciles es la solución práctica; lo que hay que saber es que es una heurística |
| "Propongo un voraz y si falla lo cambio" | Sin justificación ni contraejemplo, es una apuesta |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT
  Press, 2022). Capítulo 15: la propiedad de elección voraz, selección de actividades, Huffman, y
  la comparación sistemática con la DP del capítulo anterior. **El capítulo de este tema.**
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005). Capítulo 4: es el que
  mejor enseña el **argumento de intercambio** como método, con varias demostraciones completas y
  accesibles.
- **Libro** — Skiena, *The Algorithm Design Manual*, 3ª ed. (Springer, 2020). Sección 1.4 y el
  catálogo: los contraejemplos de heurísticas voraces que parecen correctas, que es lo más útil
  para una entrevista.
- [cp-algorithms — Kruskal](https://cp-algorithms.com/graph/mst_kruskal.html): un voraz con su
  justificación por la propiedad del corte, escrita de forma breve.
- [Java 21 API — `PriorityQueue`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/PriorityQueue.html):
  la estructura sobre la que se construyen Huffman, Dijkstra y Prim.
- **Tutorial** — Baeldung, «Huffman Coding in Java»: la implementación completa con el heap, útil
  para ver un voraz no trivial escrito.
- **Video** — MIT OpenCourseWare, *Introduction to Algorithms* (6.006), la clase de algoritmos
  voraces: incluye la demostración de la selección de actividades paso a paso.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`05` — Respuestas](05-respuestas.md).

1. ¿Qué es un algoritmo voraz? 🟢
2. ¿Qué dos propiedades necesita un problema para que el voraz sea óptimo? 🟢
3. ¿Por qué ordenar las reuniones por hora de fin y no por hora de inicio? 🟢
4. ¿Cuál es la diferencia entre la mochila fraccionaria y la 0/1? 🟢
5. Da un contraejemplo donde el voraz falle en el cambio de monedas. 🟢
6. ¿En qué se diferencian un voraz y una DP en cómo toman la decisión? 🟡
7. ¿Qué es el argumento de intercambio? 🟡
8. ¿Por qué Dijkstra es un algoritmo voraz y qué condición lo hace correcto? 🟡
9. ¿Por qué el voraz por ratio falla en la mochila 0/1? Da el ejemplo numérico. 🟡
10. ¿Qué es un sistema de monedas canónico? 🟡
11. ¿Por qué Huffman es voraz y qué estructura usa? 🟡
12. ¿Qué complejidad típica tiene un voraz frente a la DP equivalente? 🟡
13. ¿Cómo compruebas rápido si un voraz es incorrecto, sin demostrar nada? 🟠
14. ¿Puede ser útil un voraz que no es óptimo? Justifica con un caso. 🟠
15. ¿Por qué la mochila fraccionaria admite voraz y la 0/1 no, exactamente? 🟠
16. ¿Qué propiedad hace correctos a Kruskal y a Prim? 🟠
17. Ordenar por duración parece razonable en la selección de actividades. Da el contraejemplo. 🟠
18. ¿Cómo justificarías un voraz en una entrevista sin hacer una demostración formal? 🟠
19. El reparto de funcionalidades en un sprint por ratio valor/esfuerzo, ¿es óptimo? 🟠
20. Te dan un problema y propones un voraz. ¿Cuál es tu secuencia antes de escribir código? 🔴
21. Un voraz lleva dos años en producción dando resultados que nadie ha cuestionado. Diseña cómo
    comprobarías si es óptimo, sin demostrarlo formalmente. 🔴
22. Escribe la justificación de un voraz para un comité técnico: qué propiedad lo hace correcto,
    qué pasa si esa propiedad deja de cumplirse y cómo lo detectarías. 🔴
23. Te piden sustituir una DP correcta por un voraz porque "va lenta". Escribe tu respuesta,
    incluido qué medirías antes de aceptar. 🔴

---

**Anterior:** [`01` — Programación dinámica](01-programacion-dinamica.md) ·
**Siguiente:** [`03` — Protocolo de pizarra](03-protocolo-de-pizarra.md) ·
**Relacionado:** [`04-arboles-grafos/04` — Caminos mínimos](../04-arboles-grafos/04-caminos-minimos-y-expansion-minima.md)
