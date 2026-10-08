# 03 — Protocolo de pizarra

> El procedimiento para resolver un problema delante de alguien que te está mirando teclear: los
> siete pasos en orden, las preguntas que se hacen siempre antes de escribir, el mapa de señales
> que traduce un enunciado en una técnica, las plantillas que hay que tener memorizadas, y la
> lista de casos borde que se recita sin que te la pidan.
> Asume leído todo el corpus. Es el último capítulo del hilo principal a propósito.
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Dos candidatos con el mismo conocimiento obtienen resultados distintos, y la diferencia casi nunca
es técnica.

El primero lee el enunciado, se queda callado noventa segundos, empieza a teclear una solución,
descubre a mitad que no cubre un caso, borra, vuelve a empezar, y a los treinta minutos tiene algo
que funciona pero no ha dicho ni una frase sobre por qué.

El segundo repite el enunciado con sus palabras, hace tres preguntas, escribe un ejemplo pequeño a
mano, dice *"la fuerza bruta sería O(n²), déjame ver si puedo hacerlo mejor"*, nombra la técnica,
escribe, prueba con el ejemplo en voz alta y enumera los casos borde.

**Los dos escriben el mismo código.** El segundo aprueba.

La razón es que una entrevista técnica no mide si sabes el algoritmo: mide **cómo trabajas cuando
no sabes la respuesta todavía**, que es lo que vas a hacer el 90 % de los días en el puesto. Este
capítulo es el procedimiento que hace visible ese trabajo.

> **Veredicto:** el protocolo no sustituye a saber algoritmos; hace que lo que sabes se vea. Los
> siete pasos valen exactamente igual con un problema que dominas y con uno que no, y esa es la
> razón de tenerlos memorizados: son lo único que sigue funcionando cuando te quedas en blanco.

> **Regla de entrevista:** el silencio es lo único que penaliza siempre. Una idea mala dicha en voz
> alta se corrige entre los dos; una idea buena pensada en silencio no existe.

---

## 2. 🧱 Los siete pasos

El orden importa y no es negociable. Saltarse el 1 y el 2 es lo que hace que la gente resuelva el
problema equivocado.

```text
1. REPITE el enunciado con tus palabras          (30 s)
2. PREGUNTA lo que falta                          (1 min)
3. EJEMPLO pequeño, a mano, con la respuesta      (2 min)
4. FUERZA BRUTA en voz alta, con su complejidad   (1 min)
5. OPTIMIZA: nombra la técnica y por qué encaja   (2-3 min)
6. ESCRIBE, narrando lo que haces                 (10-15 min)
7. PRUEBA con tu ejemplo y enumera casos borde    (3-5 min)
```

- **El paso 3 es el más infravalorado.** Un ejemplo con cinco elementos escrito a mano, con su
  respuesta esperada, te obliga a entender el problema y te da con qué probar al final. Cuesta dos
  minutos y evita la mitad de los desastres.
- **El paso 4 no es opcional aunque sepas la solución buena.** Establece la referencia contra la
  que comparas y demuestra que entendiste el problema. Además, si te bloqueas después, ya tienes
  algo que entregar.
- **El paso 7 es donde se recupera la nota.** Un bug encontrado por ti al probar cuenta a favor; el
  mismo bug encontrado por el entrevistador, en contra.

---

## 3. 🧱 Las preguntas que se hacen siempre

Hay seis, y sirven para casi cualquier enunciado. Hacerlas no es inseguridad: es lo que hace un
ingeniero antes de escribir código de verdad.

```text
1. ¿Cuál es el tamaño de la entrada?        → te dice la complejidad esperada
2. ¿Puede estar vacía? ¿Puede ser null?     → el primer caso borde, siempre
3. ¿Hay duplicados?                         → cambia hash por conteo, y binaria por frontera
4. ¿Está ordenada? ¿Puedo ordenarla?        → habilita dos punteros y binaria
5. ¿Los valores pueden ser negativos? ¿Cero?→ rompe voraces, ventanas y Dijkstra
6. ¿Qué devuelvo si no hay respuesta?       → null, Optional, excepción, -1: hay que decidirlo
```

- **La 1 vale por media solución.** "Hasta 10⁵" significa n log n; "hasta 20" significa que se
  admite exponencial. Está en
  [`01-fundamentos/01`](../01-fundamentos/01-complejidad-y-o-grande.md#5-️-la-tabla-de-costes).
- **La 5 es la que más gente olvida** y la que más soluciones rompe: los negativos invalidan la
  ventana deslizante, el voraz del cambio de monedas y Dijkstra.
- **La 6 parece burocrática y es de diseño.** Devolver `-1` para "no encontrado" es una decisión de
  API, y decirlo así cambia la conversación.

> 💡 **Truco.** Haz las preguntas **antes** de proponer nada, no después. Preguntar por los
> duplicados una vez que ya escribiste la solución suena a que acabas de darte cuenta de que la
> rompen.

---

## 4. 🧭 El mapa de señales

La tabla que traduce el enunciado en técnica. **Casi todos los problemas de entrevista de backend
caen en una de estas filas.**

| Lo que dice el enunciado | La técnica | Dónde está |
|---|---|---|
| "ordenado", "par que suma" | Dos punteros | [`01-fund/03`](../01-fundamentos/03-arrays-listas-y-secuencias.md) |
| "contiguo", "subcadena", "subarreglo" | Ventana deslizante | [`01-fund/03`](../01-fundamentos/03-arrays-listas-y-secuencias.md) |
| "muchas consultas de rango", inmutable | Sumas de prefijos | [`01-fund/03`](../01-fundamentos/03-arrays-listas-y-secuencias.md) |
| "el siguiente mayor", "cuántos días hasta" | Pila monótona | [`01-fund/03`](../01-fundamentos/03-arrays-listas-y-secuencias.md) |
| "¿ya lo vi?", "cuántas veces aparece" | Tabla hash | [`03-orden/04`](../03-orden-busqueda/04-hashing-y-tablas-hash.md) |
| "los k mayores", "el siguiente por prioridad" | Heap | [`04-arb/02`](../04-arboles-grafos/02-monticulos-y-colas-de-prioridad.md) |
| "el menor X tal que", "minimiza el máximo" | Binaria sobre la respuesta | [`03-orden/03`](../03-orden-busqueda/03-busqueda.md) |
| "rango", "vecino más cercano", "vigente en" | Árbol ordenado | [`04-arb/01`](../04-arboles-grafos/01-arboles.md) |
| "mínimo número de pasos", sin pesos | BFS | [`04-arb/03`](../04-arboles-grafos/03-grafos-representacion-y-recorridos.md) |
| "hay un ciclo", "en qué orden" | DFS / orden topológico | [`04-arb/03`](../04-arboles-grafos/03-grafos-representacion-y-recorridos.md) |
| "conectados", "agrupar" | Union-Find | [`04-arb/03`](../04-arboles-grafos/03-grafos-representacion-y-recorridos.md) |
| "camino más barato", con pesos | Dijkstra | [`04-arb/04`](../04-arboles-grafos/04-caminos-minimos-y-expansion-minima.md) |
| "todas las combinaciones", n ≤ 25 | Backtracking | [`01-fund/04`](../01-fundamentos/04-recursion-y-backtracking.md) |
| "cuántas formas", "el máximo/mínimo total" | Programación dinámica | [`01`](01-programacion-dinamica.md) |
| "prefijo", "autocompletar" | Trie | [`02-texto/02`](../02-texto/02-algoritmos-de-cadenas.md) |

**Y la fila que falta en todas las tablas:** si ninguna señal encaja y **n es pequeño**, la fuerza
bruta es la respuesta correcta. Decirlo a propósito —*"con n ≤ 500 hago el cuadrático, que es más
claro y suficiente"*— demuestra criterio, no pereza.

---

## 5. 🧱 Las cuatro plantillas que hay que tener memorizadas

No son las únicas, pero son las que aparecen dentro de la mitad de los problemas. Tenerlas
automatizadas libera toda la atención para el problema de verdad.

**Búsqueda binaria por frontera** —la forma general, que cubre las tres variantes—:

```java
int lo = 0, hi = n;                      // hi EXCLUSIVO
while (lo < hi) {
    int mid = lo + (hi - lo) / 2;        // no desborda
    if (cumple(mid)) hi = mid;           // mid es candidato: no lo descartes
    else lo = mid + 1;
}
return lo;                                // la frontera
```

**BFS con niveles y camino**:

```java
Deque<Nodo> cola = new ArrayDeque<>();
Map<Nodo, Nodo> previo = new HashMap<>();
cola.add(origen); previo.put(origen, null);           // marca AL ENCOLAR
while (!cola.isEmpty()) {
    Nodo actual = cola.poll();
    for (Nodo vecino : vecinos(actual))
        if (previo.putIfAbsent(vecino, actual) == null) cola.add(vecino);
}
```

**Backtracking** —elegir, explorar, deshacer—:

```java
void explorar(Estado estado, List<Solucion> resultado) {
    if (esSolucion(estado)) { resultado.add(copiaDe(estado)); return; }   // COPIA
    for (Opcion opcion : opcionesDe(estado)) {
        if (!esViable(estado, opcion)) continue;      // poda
        aplicar(estado, opcion);
        explorar(estado, resultado);
        deshacer(estado, opcion);                     // el paso que todos olvidan
    }
}
```

**Union-Find con las dos optimizaciones**:

```java
int find(int x) { return padre[x] == x ? x : (padre[x] = find(padre[x])); }   // compresión
void union(int a, int b) {
    int ra = find(a), rb = find(b);
    if (ra == rb) return;
    if (tam[ra] < tam[rb]) { int t = ra; ra = rb; rb = t; }                    // por tamaño
    padre[rb] = ra; tam[ra] += tam[rb];
}
```

> ⚠️ **Advertencia.** Memorizar plantillas **no** sustituye a entenderlas. La señal de que las
> entiendes es poder decir qué pasa si cambias una línea: por qué `hi = mid` y no `mid - 1`, por qué
> se marca al encolar, por qué hay que copiar el estado. El entrevistador va a preguntar
> exactamente eso.

---

## 6. 🧱 Los casos borde que se recitan

La lista se dice **antes** de que la pregunten, y se adapta al problema. Son siete y cubren casi
todo:

```text
1. Entrada vacía         []  ""   null
2. Un solo elemento      [5]      "a"
3. Todos iguales         [5,5,5]
4. Ya ordenado / al revés [1,2,3] / [3,2,1]
5. Valores extremos      Integer.MIN_VALUE, desbordamiento al sumar o restar
6. Duplicados            si el enunciado no los prohibió, existen
7. No hay respuesta      ¿qué devuelves? ¿null, Optional, -1, excepción?
```

- **El 5 es el que distingue.** `a - b` desborda, `(lo + hi) / 2` desborda, la suma de un arreglo de
  `int` desborda. Nombrarlo sin que te lo pidan es de las cosas que más suben la nota.
- **El 7 no es un caso borde, es una decisión de diseño**, y tratarla como tal —*"devuelvo
  `Optional` porque `-1` es un valor legítimo del dominio"*— cambia el registro de la conversación.
- Hay un octavo específico de concurrencia si el problema la menciona, y uno noveno de codificación
  si hay texto: los de [`02-texto/01`](../02-texto/01-strings-entre-lenguajes.md).

---

## 7. 🧱 Cómo se prueba en voz alta

Se coge el ejemplo del paso 3 y se ejecuta el código **con el dedo**, diciendo el valor de las
variables en cada iteración. Suena lento y es la parte más rentable de los treinta minutos.

```text
"datos = [5, 2, 9, 1], objetivo = 11.
 izq=0 der=3 → 5+1=6 < 11 → izq++
 izq=1 der=3 → 2+1=3 < 11 → izq++
 ... espera, el arreglo no está ordenado. Mi solución asume orden y no lo comprobé."
```

- **Ese "espera" es oro.** Encontrar tu propio bug probando es una señal positiva; que lo encuentre
  el entrevistador, no.
- Si el código es largo, se prueba **la parte con más riesgo**: el bucle, no las tres líneas de
  configuración.
- Al terminar, se repite la complejidad en tiempo y espacio. Cierra el ejercicio y contesta la
  pregunta que iba a venir.

---

## 8. 🔭 Qué evalúa de verdad el entrevistador

No es la solución. Son cinco cosas, y conviene saberlas para no optimizar la equivocada:

- **Si entiendes el problema antes de resolverlo.** Los pasos 1 a 3.
- **Si conoces el espacio de soluciones.** Saber que existe una fuerza bruta y una optimizada, y
  poder comparar.
- **Si escribes código que se puede leer.** Nombres con significado, funciones pequeñas, sin
  `tmp` ni `arr`. La guía de este corpus lo exige por la misma razón.
- **Si detectas tus propios errores.** El paso 7.
- **Cómo reaccionas cuando te corrigen.** Si el entrevistador dice "eso es O(n²)" y tú tenías
  razón, cómo lo defiendes; y si no la tenías, cómo lo aceptas. Muchas veces la afirmación es
  deliberadamente discutible para ver exactamente eso.

**Lo que no se evalúa:** si te sabes el algoritmo de memoria. Decir *"no recuerdo el código exacto
de KMP, déjame reconstruirlo desde la idea de la tabla de prefijos"* es mejor respuesta que
escribirlo de carrerilla sin poder explicarlo.

---

## ⚠️ Errores frecuentes

| Se dice / se hace | Lo preciso |
|---|---|
| Empezar a escribir en cuanto lees el enunciado | Los pasos 1 a 3 cuestan cinco minutos y evitan resolver el problema equivocado |
| Saltarse la fuerza bruta porque sabes la buena | Es la referencia y demuestra que entendiste. Se dice en una frase |
| Pensar en silencio mientras escribes | El silencio es lo único que penaliza siempre |
| "Creo que es O(n)" sin haberlo contado | Cuenta cuántas veces se ejecuta la línea más interna |
| Dejar que el entrevistador encuentre el bug | Probar con tu ejemplo al final recupera la nota |
| No preguntar nada "para no parecer inseguro" | Preguntar es lo que hace un ingeniero antes de escribir código real |
| Defender una respuesta que ya sabes que es dudosa | Reconocer el matiz rápido puntúa más que ganar la discusión |

---

## 📚 Para profundizar

- **Libro** — McDowell, *Cracking the Coding Interview*, 6ª ed. (CareerCup, 2015). Las primeras
  cien páginas, antes de los problemas: el proceso, cómo se evalúa y cómo se comunica. **Es el
  libro de este capítulo**; los problemas son lo de menos.
- **Libro** — Aziz, Lee y Prakash, *Elements of Programming Interviews in Java* (2018). Su
  introducción sobre estrategias de resolución y el uso de patrones es más técnica y complementa
  bien a CtCI.
- **Libro** — Bentley, *Programming Pearls*, 2ª ed. (Addison-Wesley, 1999). Columnas 1 y 2: cómo se
  pasa de un enunciado confuso a un problema bien definido, que es el paso 1 de este capítulo.
- **Libro** — Skiena, *The Algorithm Design Manual*, 3ª ed. (Springer, 2020). El catálogo de la
  parte II es el mapa de señales de §4 con mucho más detalle: se consulta por problema, no se lee.
- [Big-O Cheat Sheet](https://www.bigocheatsheet.com/): la tabla de complejidades de todas las
  estructuras en una página, para repasar antes de entrar.
- **Video** — NeetCode: sus listas agrupan los problemas **por patrón** y no por dificultad, que es
  exactamente la forma de estudiar que propone §4.
- **Video** — Computerphile, los episodios sobre entrevistas técnicas y sobre por qué se hacen así,
  útiles para entender qué se está midiendo.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`05` — Respuestas](05-respuestas.md).

1. ¿Cuáles son los siete pasos del protocolo, en orden? 🟢
2. ¿Qué seis preguntas se hacen antes de escribir código? 🟢
3. ¿Qué técnica delata la palabra "contiguo" en un enunciado? 🟢
4. ¿Qué técnica delata "el menor X tal que"? 🟢
5. ¿Qué te dice el tamaño de la entrada sobre la solución esperada? 🟢
6. ¿Cuáles son los siete casos borde que se recitan? 🟡
7. ¿Por qué se dice la fuerza bruta aunque sepas la solución óptima? 🟡
8. ¿Por qué el paso del ejemplo a mano es el más infravalorado? 🟡
9. ¿Por qué el silencio penaliza más que una idea equivocada? 🟡
10. ¿Qué cinco cosas evalúa de verdad el entrevistador? 🟡
11. ¿Qué haces si ninguna señal del mapa encaja con el enunciado? 🟡
12. En la plantilla de búsqueda binaria, ¿por qué `hi = mid` y no `mid - 1`? 🟠
13. En la plantilla de BFS, ¿por qué se marca al encolar? 🟠
14. En la plantilla de backtracking, ¿por qué se copia el estado al añadirlo? 🟠
15. ¿Por qué la pregunta por los valores negativos rompe más soluciones que las demás? 🟠
16. ¿Cómo pruebas tu código en voz alta y por qué compensa el tiempo que cuesta? 🟠
17. El entrevistador afirma que tu solución es O(n²) y crees que es O(n). ¿Qué haces? 🟠
18. No recuerdas el código de un algoritmo que sabes que aplica. ¿Cómo lo manejas? 🟠
19. Te quedan cinco minutos y la solución no está completa. ¿Qué haces con ellos? 🟠
20. Te dan un enunciado deliberadamente ambiguo. Escribe las preguntas que harías y di cómo cambia
    la solución cada respuesta. 🔴
21. Te bloqueas por completo a los diez minutos. Describe tu procedimiento de desbloqueo. 🔴
22. Diseña tu plan de preparación para una prueba de código dentro de dos semanas, con el tiempo
    que tienes. 🔴

---

**Anterior:** [`02` — Algoritmos voraces](02-algoritmos-voraces.md) ·
**Siguiente:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**Relacionado:** [`01-fundamentos/05` — Simulación](../01-fundamentos/06-simulacion-de-entrevista.md)
