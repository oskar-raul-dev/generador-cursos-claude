# 05 — Simulación de entrevista

> El examen del bloque. Treinta y cuatro preguntas `S#` transversales que cruzan los cuatro
> capítulos, más cinco problemas de pizarra. Se contesta **en voz alta y cronometrado**, y los
> problemas se **teclean**.
> Asume leídos [`01`](01-arboles.md) a [`04`](04-caminos-minimos-y-expansion-minima.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA. Grábate.
3. Los problemas de pizarra se TECLEAN, en 20 minutos, sin autocompletado.
4. Solo después vas a `06-respuestas.md`.
5. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

> **Regla:** en este bloque, la mitad del trabajo es **reconocer que el problema es de grafos**.
> Los enunciados reales nunca dicen "grafo": dicen dependencias, permisos, rutas, conexiones o
> ciclos.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Árboles

**S1.** ¿Cuál es el invariante de un BST y qué recorrido lo comprueba? 🟢

**S2.** ¿Por qué un BST se degenera, y con qué entrada de lo más normal? 🟡

**S3.** ¿En qué se diferencian AVL y rojo-negro, y cuál usa `TreeMap`? 🟡

**S4.** ¿Qué operaciones justifican pagar `TreeMap` en vez de `HashMap`? 🟠

**S5.** ¿Por qué el índice de tu base de datos es un B+tree? 🟠

**S6.** ¿Por qué un índice sirve para `LIKE 'algo%'` y no para `LIKE '%algo'`? 🟠

**S7.** Cuatro de los cinco lenguajes no traen árbol balanceado. ¿Qué hacen en su lugar? 🟠

### Bloque B — Montículos

**S8.** ¿Qué garantiza un heap y qué **no** garantiza? 🟢

**S9.** ¿Por qué construir un heap es O(n) y no O(n log n)? 🟠

**S10.** ¿Por qué para los k mayores se usa un min-heap? 🟡

**S11.** ¿Qué tres cosas hace mal `PriorityQueue` que hay que saber antes de usarla? 🟠

**S12.** ¿Cómo calculas la mediana de un flujo? 🟠

**S13.** Te piden el top 100 de 10 millones. Compara las dos soluciones con números. 🟠

### Bloque C — Grafos y recorridos

**S14.** ¿Qué estructura usa BFS y cuál DFS, y qué consecuencia tiene? 🟢

**S15.** ¿Cuál de los dos da el camino más corto y bajo qué condición? 🟢

**S16.** ¿Por qué un solo conjunto de visitados no detecta ciclos dirigidos? 🟡

**S17.** ¿Por qué "detectar dependencias circulares" y "decidir el orden de arranque" son la misma
pregunta? 🟠

**S18.** ¿Qué es Union-Find, qué lo hace casi O(1) y qué **no** puede hacer? 🟠

**S19.** ¿Cuándo eliges matriz de adyacencia? 🟠

**S20.** Spring lanza `BeanCurrentlyInCreationException`. Traduce el problema a grafos. 🟠

### Bloque D — Caminos mínimos

**S21.** ¿Cuál es la cadena de decisión entre BFS, Dijkstra y Bellman-Ford? 🟢

**S22.** ¿Por qué Dijkstra falla con pesos negativos? Explica el mecanismo. 🟠

**S23.** ¿Qué detecta Bellman-Ford que ningún otro detecta, y para qué sirve en negocio? 🟠

**S24.** ¿En qué se diferencia un árbol de expansión mínima de un conjunto de caminos mínimos? 🟠

**S25.** ¿Qué es una heurística admisible y qué pasa si no lo es? 🟡

**S26.** ¿Por qué en Dijkstra se insertan duplicados en la cola en vez de actualizar? 🟠

### Bloque E — Elección y los cinco lenguajes

**S27.** Hash, árbol o heap: da el criterio en tres frases. 🟠

**S28.** ¿Por qué ningún lenguaje de los cinco trae algoritmos de grafos en su stdlib? 🟠

**S29.** ¿Qué trae Python que los otros cuatro no traen, y por qué justamente eso? 🟠

**S30.** ¿Cómo afecta el recorrido aleatorio del mapa de Go al resultado de un BFS? 🟠

### Bloque F — Las que descolocan

**S31.** "Los grafos son para entrevistas, en mi trabajo no aparecen." Responde. 🔴

**S32.** El entrevistador te pide implementar Dijkstra y no recuerdas la relajación. ¿Qué
haces? 🔴

**S33.** ¿Cuándo has modelado algo como grafo sin que nadie lo llamara así? 🔴

**S34.** Te piden optimizar un recorrido de grafo que tarda 40 segundos sobre 50 000 nodos.
¿Dónde buscas? 🔴

---

## 3. 🧪 Problemas de pizarra

Veinte minutos cada uno, tecleando y narrando. La solución completa está en
[`06`](06-respuestas.md).

### P1 — El orden de arranque

**Fuerza:** reconocer el grafo detrás de un enunciado que no lo menciona.

Tienes 200 módulos, cada uno con su lista de módulos de los que depende. Escribe el algoritmo que
decide en qué orden arrancarlos, y qué hace si la configuración tiene un ciclo.

Repregunta: *"¿y si quieres arrancar en paralelo todo lo que se pueda?"*.

### P2 — El grado de separación

**Fuerza:** BFS con reconstrucción de camino, y el límite de la solución ingenua.

En una red social, encuentra la cadena más corta de amistades entre dos personas. Escribe la
solución, di su complejidad, y explica qué pasa cuando la red tiene 100 millones de usuarios.

Repregunta: *"¿cómo lo harías si no cabe en memoria?"*.

### P3 — El top-K del flujo

**Fuerza:** el heap acotado, y saber que la solución obvia no aplica a un flujo.

Procesa un flujo continuo de eventos de venta y mantén en todo momento los 100 productos más
vendidos. Escribe la estructura y explica su coste en tiempo y memoria.

Repregunta: *"¿y si un producto que ya está en el top vende más?"*.

### P4 — El precio vigente

**Fuerza:** elegir `TreeMap` por una operación concreta, no por costumbre.

Tienes 10 años de cambios de tarifa por producto, con su fecha de entrada en vigor. Responde
"cuál era el precio de este producto en esta fecha" en O(log n). Elige la estructura y justifica.

Repregunta: *"¿y con un `HashMap` de fecha a precio?"*.

### P5 — El arbitraje

**Fuerza:** modelar pesos para que un ciclo negativo signifique algo de negocio.

Tienes 200 divisas y sus tipos de cambio par a par. Detecta si existe una secuencia de cambios que
termine en la divisa de partida con **más** dinero del que empezaste. Modela el grafo y elige el
algoritmo.

Repregunta: *"¿por qué logaritmos?"*.

---

## 4. 🧠 Las frases que hay que tener listas

> **Sobre estructuras:** *"Hash para '¿está?', árbol para 'todos en orden' y rangos, heap para
> 'dame el siguiente'. Tres preguntas distintas, y elegir mal es el error más común."*

> **Sobre recorridos:** *"BFS y DFS son el mismo algoritmo con distinta estructura: cola o pila.
> BFS da el camino mínimo en saltos; DFS sirve para ciclos, orden topológico y componentes."*

> **Sobre caminos:** *"Sin pesos, BFS. Con pesos no negativos, Dijkstra. Con negativos,
> Bellman-Ford, que además es el único que detecta ciclos negativos — y eso es el arbitraje."*

---

**Anterior:** [`04` — Caminos mínimos y expansión mínima](04-caminos-minimos-y-expansion-minima.md) ·
**Siguiente:** [`06` — Respuestas](06-respuestas.md) ·
**Relacionado:** [`05-dp-y-tecnicas/03` — Protocolo de pizarra](../05-dp-y-tecnicas/03-protocolo-de-pizarra.md)
