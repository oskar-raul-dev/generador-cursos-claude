# 05 — Respuestas

> Solucionario centralizado del bloque `05-dp-y-tecnicas`. Cada respuesta en tres capas:
> **⏱️ 30 segundos**, **🗣️ 2 minutos** y **🔬 El detalle**. Los enunciados están copiados
> literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--programación-dinámica) · [02](#02--algoritmos-voraces) ·
[03](#03--protocolo-de-pizarra) ·
[04 — transversales](#04--simulación-preguntas-transversales) ·
[04 — pizarra](#04--simulación-problemas-de-pizarra)

---

# 01 — Programación dinámica

**01 → 1. ¿Cuáles son las dos condiciones para que un problema sea de programación dinámica?**

⏱️ Subestructura óptima y subproblemas solapados.
🗣️ La primera dice que la solución óptima se construye con soluciones óptimas de subproblemas. La
segunda, que los mismos subproblemas aparecen muchas veces, que es lo que hace que memoizar valga la
pena.
🔬 Si solo se cumple la primera, es divide y vencerás: merge sort tiene subestructura óptima y
subproblemas **disjuntos**, y por eso memoizarlo no ahorraría nada.

**01 → 2. ¿Qué complejidad tiene Fibonacci con y sin memoización?**

⏱️ O(2ⁿ) sin memoizar; O(n) con memoización, en tiempo y espacio.
🗣️ Sin memoizar, cada llamada genera dos y el árbol tiene profundidad n. Con memoización, cada valor
se calcula una vez y las demás veces se lee: n cálculos y n lecturas.
🔬 El espacio de la versión ingenua es solo O(n) aunque el tiempo sea exponencial, porque en cada
momento hay un único camino abierto en la pila. Es una disociación que se pregunta y que mucha gente
falla.

**01 → 3. ¿Qué diferencia hay entre memoización y tabulación?**

⏱️ La memoización es descendente y perezosa —recursión más caché—; la tabulación es ascendente y
exhaustiva —bucles más tabla—.
🗣️ Memoizar solo calcula los subproblemas que hacen falta y paga pila de recursión. Tabular calcula
todos los estados y no usa pila, lo que además permite optimizar el espacio.
🔬 En una entrevista conviene escribir la memoización —sale directa de la recursión y es difícil
equivocarse— y **decir** que se puede tabular para quitar la pila y reducir el espacio. Dices las dos
y solo escribes una.

**01 → 4. ¿Cuál es el estado de la mochila 0/1 y cuál su recurrencia?**

⏱️ `dp[i][w]` = mejor valor usando los i primeros objetos con capacidad w. La recurrencia elige entre
incluir el objeto i o no.

```text
dp[i][w] = max( dp[i-1][w],                        no incluirlo
                dp[i-1][w - peso[i]] + valor[i] )  incluirlo, si cabe
```

🗣️ Es la forma canónica de toda recurrencia de DP: **una elección entre dos opciones, y me quedo con
la mejor**. Los casos base son `dp[0][*] = 0`.
🔬 El `dp[i-1]` en el segundo término es lo que hace que sea 0/1: al incluir el objeto, se consulta la
fila **anterior**, así que no se puede usar dos veces. La variante ilimitada cambia ese `i-1` por `i`,
y es la única diferencia.

**01 → 5. ¿Qué complejidad tiene la mochila 0/1?**

⏱️ O(n·W) en tiempo y espacio, con n objetos y capacidad W.
🗣️ Se llena una tabla de n filas por W columnas, y cada celda cuesta O(1). El espacio baja a O(W) con
una sola fila recorrida al revés.
🔬 Es **pseudopolinómica**: W es el **valor** de la capacidad, no el tamaño de la entrada. Con W = 10⁹
la tabla no cabe aunque solo haya 20 objetos, y ahí la solución es otra —backtracking con poda, o
programación por ramificación y acotación—.

**01 → 6. ¿Qué problema real resuelve el algoritmo de LCS?**

⏱️ El `diff`: qué líneas comparten dos versiones de un archivo.
🗣️ La subsecuencia común más larga entre las dos versiones son las líneas que no cambiaron; lo que
sobra en una es un borrado y lo que sobra en la otra es una inserción. Es lo que hay detrás de `git
diff` y de cualquier herramienta de comparación.
🔬 También del alineamiento de secuencias de ADN, con una matriz de puntuación en vez de igualdad
exacta. Y es primo hermano de la distancia de edición: la misma matriz con otra recurrencia.

**01 → 7. ¿Por qué merge sort no es programación dinámica si es recursivo?**

⏱️ Porque sus subproblemas son **disjuntos**: las dos mitades no comparten nada.
🗣️ La DP existe para no recalcular trabajo repetido, y en merge sort no hay trabajo repetido que
evitar: cada elemento pertenece a exactamente una mitad en cada nivel. Memoizarlo no ahorraría ni una
operación y solo gastaría memoria.
🔬 Es la mejor forma de fijar la diferencia entre divide y vencerás y DP: **las dos tienen
subestructura óptima, y solo la DP tiene solapamiento**. Cuando alguien pregunta en qué se
diferencian, este es el ejemplo que lo zanja.

**01 → 8. ¿Por qué la mochila es pseudopolinómica y no polinómica?**

⏱️ Porque O(n·W) depende del **valor** de W, no del tamaño de su representación.
🗣️ Un número W ocupa log W bits en la entrada. Un algoritmo polinómico sería polinómico en log W; la
mochila es lineal en W, que es exponencial en log W. Por eso duplicar los bits de la capacidad
multiplica el trabajo por mil y no por dos.
🔬 La consecuencia práctica: la mochila es "fácil" con capacidades pequeñas y **NP-difícil** en
general. Es el ejemplo canónico de pseudopolinomialidad, y decirlo con ese nombre es lo que separa la
respuesta de nivel senior.

**01 → 9. ¿Qué gana la tabulación frente a la memoización? Da dos cosas.**

⏱️ No consume pila de recursión, y permite optimizar el espacio a una fila.
🗣️ La primera importa cuando la profundidad es grande: memoizar hasta n = 100 000 desborda en Java y
en Python. La segunda solo es posible porque al tabular controlas el orden de llenado y sabes qué
filas ya no hacen falta.
🔬 Una tercera, menor: la tabulación suele tener mejor localidad de caché, porque recorre un arreglo
contiguo en vez de saltar por un mapa. En bucles grandes eso se nota.

**01 → 10. ¿Cuándo gana la memoización frente a la tabulación?**

⏱️ Cuando el espacio de estados es enorme y solo se visita una parte pequeña.
🗣️ La tabulación llena **todos** los estados; la memoización solo los alcanzables desde la entrada
concreta. Con restricciones fuertes que podan la mayoría del espacio, la diferencia puede ser de
órdenes de magnitud.
🔬 Y gana siempre en una cosa más prosaica: es **más fácil de escribir correctamente**, porque sale
directamente de la recursión natural y no obliga a razonar el orden de llenado. En una entrevista con
tiempo limitado, eso pesa.

**01 → 11. ¿Por qué el voraz falla en el cambio de monedas con `{1, 3, 4}` y objetivo 6?**

⏱️ Porque coger la moneda mayor primero (4) deja 2, que solo se puede pagar con dos unos: 3 monedas.
El óptimo es 3+3 = 2 monedas.
🗣️ La elección localmente óptima cierra la puerta a la global. Es exactamente la propiedad que un
voraz necesita y que aquí no se cumple.
🔬 Un sistema de monedas donde el voraz siempre acierta se llama **canónico**; el euro y el dólar lo
son por diseño. Que funcione con tu moneda no implica que el algoritmo sea correcto, y ese es el
punto de la pregunta.

**01 → 12. ¿Qué relación hay entre LCS y la distancia de edición?**

⏱️ Son la misma matriz de DP con distinta recurrencia.
🗣️ LCS maximiza los caracteres comunes; la distancia de edición minimiza las operaciones para
convertir una cadena en otra. Ambas rellenan una tabla de (n+1)×(m+1) donde cada celda depende de
tres vecinas, y ambas son O(n·m).
🔬 Están relacionadas formalmente: si solo se permiten inserciones y borrados (sin sustituciones), la
distancia de edición es exactamente `n + m - 2·LCS`. La distancia de edición está en
[`02-texto/02`](../02-texto/02-algoritmos-de-cadenas.md) y aquí se ve su naturaleza de DP.

**01 → 13. ¿Cuál es el paso más difícil al atacar un problema de DP?**

⏱️ **Definir el estado.** Es el 80 % del trabajo.
🗣️ Casi todos los problemas de DP que parecen imposibles se vuelven mecánicos cuando encuentras la
definición correcta del estado, y casi todos los fallos vienen de un estado que no captura toda la
información necesaria para decidir.
🔬 La señal de que el estado está mal es que la recurrencia necesita información que el estado no
tiene: *"para decidir aquí necesito saber si ya usé el objeto k"*, y entonces el estado tiene que
incluir eso. La forma de comprobarlo es escribir la recurrencia antes que el código.

**01 → 14. ¿Por qué el camino más largo en un grafo no se resuelve con DP como el más corto?**

⏱️ Porque **no tiene subestructura óptima** cuando no se pueden repetir nodos.
🗣️ El camino más largo de A a C no contiene necesariamente el más largo de A a B: usar los nodos
"buenos" en el primer tramo puede impedirte usarlos después, y el óptimo global puede tomar un primer
tramo subóptimo. La propiedad que hace funcionar a Dijkstra desaparece.
🔬 Por eso el camino mínimo es polinómico y el máximo es **NP-difícil** en grafos generales. Con la
excepción de los **DAG**, donde sí se puede resolver con DP en O(V + E) siguiendo el orden topológico,
porque no hay ciclos que puedan reutilizar nodos. Nombrar esa excepción es la respuesta completa.

**01 → 15. ¿Por qué en la mochila 0/1 con una sola fila hay que recorrer la capacidad al revés?**

⏱️ Porque al ir descendiendo, `dp[w - peso]` todavía contiene el valor de la fila **anterior**, que es
lo que la recurrencia 0/1 necesita.
🗣️ Si se recorre hacia delante, `dp[w - peso]` ya se actualizó con el objeto actual, así que al usarlo
estarías permitiendo incluir el mismo objeto **dos veces**. El resultado sería la mochila ilimitada,
no la 0/1.
🔬 Ese único detalle —el sentido del bucle— es la diferencia entre los dos problemas con el mismo
código. Es la mejor prueba de que entendiste la recurrencia y no la copiaste, y es exactamente lo que
el entrevistador comprueba con esta pregunta.

**01 → 16. ¿Qué cambia entre la mochila 0/1 y la ilimitada en el código?**

⏱️ El sentido del bucle de la capacidad: al revés para la 0/1, hacia delante para la ilimitada. Con
la matriz completa, `dp[i-1]` frente a `dp[i]`.
🗣️ En la versión con matriz, la 0/1 consulta la fila anterior al incluir el objeto y la ilimitada
consulta la fila actual, que ya puede contener ese mismo objeto. Con una sola fila, esa distinción
se convierte en el sentido del recorrido.
🔬 Es un cambio de una línea que cambia el problema, y por eso conviene escribirlo con el comentario
puesto. Un tercer caso, la **mochila acotada** —como mucho k copias de cada objeto—, se resuelve
descomponiendo cada objeto en potencias de dos y tratándolo como 0/1.

**01 → 17. ¿Qué pierdes al reducir el espacio de una DP a una sola fila?**

⏱️ La capacidad de **reconstruir la solución**: sabes el valor óptimo, no qué lo compone.
🗣️ Reconstruir exige recorrer la tabla hacia atrás decidiendo, en cada celda, de dónde vino el
máximo. Con una sola fila esa información ya se sobrescribió.
🔬 Es una optimización con precio, no una mejora gratuita, y la pregunta que hay que hacerse antes de
aplicarla es si hace falta **el valor** o **la solución**. Existe un punto intermedio, el algoritmo de
Hirschberg, que reconstruye en O(mín(n,m)) de espacio duplicando el tiempo.

**01 → 18. ¿Por qué `computeIfAbsent` con recursión dentro falla en Java 9+ y cómo se memoiza bien?**

⏱️ Porque la función de mapeo modifica el mapa mientras `computeIfAbsent` lo tiene bloqueado: lanza
`ConcurrentModificationException`.
🗣️ `HashMap` detecta desde Java 9 la modificación reentrante. Antes no lo detectaba y el resultado era
peor: corrupción silenciosa de la estructura interna, incluidos bucles infinitos dentro de un bucket.

```java
Long v = cache.get(n);
if (v != null) return v;
long r = fib(n - 1) + fib(n - 2);   // la recursión ocurre FUERA del compute
cache.put(n, r);
return r;
```

🔬 En Python el equivalente es `@functools.cache`, que no tiene este problema porque gestiona el
diccionario fuera de la llamada. Es la diferencia más visible de este bloque entre los dos lenguajes:
una línea contra cuatro, y sin trampa.

**01 → 19. ¿Por qué la subsecuencia creciente más larga tiene una solución mejor que la DP obvia?**

⏱️ Porque en vez de comparar con todos los anteriores —O(n²)— se mantiene un arreglo de colas y se
busca binariamente: **O(n log n)**.
🗣️ La DP directa define `dp[i]` = longitud de la LIS que termina en i, y para calcularla mira todos
los j < i: cuadrático. La versión buena mantiene, para cada longitud, el menor final posible; ese
arreglo está siempre ordenado, así que se puede buscar binariamente dónde colocar cada elemento.
🔬 Es el ejemplo de que **la DP obvia no siempre es lo óptimo**, y de que una observación sobre la
estructura del problema puede cambiar la complejidad. El detalle que muerde: ese arreglo auxiliar
**no es** la subsecuencia; para reconstruirla hay que guardar predecesores aparte.

**01 → 20. ¿Cuándo un problema que parece de DP es en realidad de backtracking?**

⏱️ Cuando hay que **enumerar** todas las soluciones, no contarlas ni optimizar.
🗣️ Si la salida misma es exponencial —"dame todas las combinaciones válidas"— no hay DP que lo
arregle: el coste mínimo es el tamaño de la salida. La DP sirve para "cuántas hay" o "cuál es la
mejor", donde la salida es un número.
🔬 Y al revés: un backtracking cuyos subproblemas se repiten se convierte en DP memoizando el estado.
El caso híbrido es la **DP sobre máscaras de bits**, que es literalmente backtracking memoizado sobre
el conjunto de elementos ya usados, y aguanta hasta n ≈ 20.

**01 → 21. ¿Qué es la DP sobre máscaras de bits y hasta qué tamaño de entrada aguanta?**

⏱️ Usar un entero como conjunto —cada bit dice si el elemento está— para memoizar estados sobre
subconjuntos. Aguanta hasta n ≈ 20.
🗣️ Con n elementos hay 2ⁿ subconjuntos, y cada uno cabe en un `int` o un `long`. Con n = 20 son un
millón de estados: perfectamente viable. Con n = 30, mil millones: ya no.
🔬 Es la técnica que resuelve el viajante de comercio de forma exacta en O(2ⁿ · n²) —el algoritmo de
Held-Karp— frente al O(n!) de la fuerza bruta. Con 20 ciudades, 2²⁰·400 son 400 millones de
operaciones: segundos. Con 20 ciudades por fuerza bruta, 20! es 2·10¹⁸: imposible.

**01 → 22. ¿Por qué Postgres deja de usar DP para ordenar los *joins* a partir de 12 tablas?**

⏱️ Porque la DP sobre subconjuntos de tablas es O(2ⁿ) y con 12 tablas ya son 4 096 subconjuntos con
sus combinaciones, y sigue creciendo exponencialmente.
🗣️ El optimizador busca el orden de *joins* de menor coste, que es un problema de DP sobre
subconjuntos —exactamente el de la pregunta 21—. A partir de `geqo_threshold` (12 por defecto),
cambia a un algoritmo genético que da un plan bueno sin garantía de ser el mejor.
🔬 Es un ejemplo excelente para una entrevista porque conecta este temario con algo que el candidato
usa a diario: **el planificador de tu base de datos es un problema de DP con un umbral de rendición
configurable**. Y explica por qué una consulta con quince tablas puede tener un plan
sorprendentemente malo.

**01 → 23. Diseña la solución para "con un presupuesto de X, qué combinación de mejoras maximiza el rendimiento", y di qué devuelves además del valor.**

⏱️ Mochila 0/1 con DP: `dp[i][presupuesto]`, y hay que devolver **la lista de mejoras**, no solo el
número.
🗣️ Cada mejora tiene un coste y una ganancia estimada; el presupuesto es la capacidad. La recurrencia
es la estándar: incluir o no cada mejora. O(n · presupuesto) en tiempo.

```text
dp[i][p] = max( dp[i-1][p],  dp[i-1][p - coste[i]] + ganancia[i] )
```

🔬 Lo que hace real este problema es la reconstrucción: **el negocio quiere saber qué mejoras hacer**,
no cuánto va a ganar. Eso obliga a **mantener la matriz completa** y recorrerla hacia atrás desde
`dp[n][X]`, comparando con `dp[i-1][p]` para saber si el objeto i entró. Y por tanto **descarta la
optimización de espacio a una fila**, que es exactamente la decisión que la pregunta busca. Dos
matices más que preguntan después: si las mejoras tienen dependencias entre sí, la mochila deja de
aplicar y pasa a ser un problema sobre un DAG; y si las ganancias son estimaciones con incertidumbre,
el óptimo matemático sobre datos inventados es un espejismo, y conviene decirlo.

**01 → 24. Escribe la recurrencia de LCS, trázala sobre `"casa"` y `"cosa"`, y di dónde está la respuesta.**

⏱️ La respuesta está en `dp[n][m]`, la esquina inferior derecha: **3** (`"csa"`… en realidad `"csa"` no
es subsecuencia contigua pero sí subsecuencia: c-s-a).

```text
si a[i] == b[j]:  dp[i][j] = dp[i-1][j-1] + 1
si no:            dp[i][j] = max(dp[i-1][j], dp[i][j-1])

        ""  c  o  s  a
    ""   0  0  0  0  0
     c   0  1  1  1  1
     a   0  1  1  1  2
     s   0  1  1  2  2
     a   0  1  1  2  3      ← respuesta: 3
```

🗣️ La subsecuencia común más larga de `"casa"` y `"cosa"` es `"csa"`, de longitud 3: se toman la `c`,
la `s` y la `a` final, saltándose la `a` y la `o` de en medio. **Subsecuencia no significa contigua**,
y esa es la confusión más frecuente del problema.
🔬 Para **reconstruir** la subsecuencia y no solo su longitud, se recorre la matriz desde
`dp[n][m]` hacia atrás: si los caracteres coinciden, forma parte de la solución y se va en diagonal;
si no, se va hacia el mayor de los dos vecinos. Eso exige la matriz completa, así que aquí tampoco se
puede optimizar el espacio. Y el caso borde: si una de las cadenas es vacía, toda la primera fila o
columna es 0 y la respuesta es 0, que el `""` inicial de la tabla resuelve sin ningún `if`.

**01 → 25. Te dan un problema de DP con 10⁶ estados y memoización recursiva que desborda la pila. Da la conversión y su coste.**

⏱️ Convertir a **tabulación**: mismo tiempo, mismo espacio de tabla, y **cero pila**.
🗣️ La conversión es mecánica una vez identificado el orden de dependencias: los estados se llenan con
bucles desde los casos base hacia arriba, en un orden que garantice que las dependencias ya están
calculadas. La recurrencia no cambia; cambia quién la invoca.

```text
memoizada:  f(n) llama a f(n-1)... hasta el caso base → pila de profundidad n
tabulada:   for (i = base; i <= n; i++) dp[i] = ...   → sin pila
```

🔬 Los dos puntos que preguntan. **El orden de llenado** es la parte que hay que razonar: en una DP
unidimensional es trivial, en una bidimensional hay que decidir si se recorre por filas o por
columnas según de qué dependa cada celda, y en una DP sobre un DAG el orden es el **topológico**.
**El espacio** puede bajar todavía más: con 10⁶ estados en una tabla de `long` son 8 MB, que caben,
pero si el estado es bidimensional y solo depende de la fila anterior, se pasa de O(n·m) a O(m). Y la
alternativa que conviene nombrar si la conversión es difícil: memoización **iterativa con pila
explícita**, que conserva la pereza de la descendente sin usar la pila de llamadas, a costa de código
bastante más feo.

---

# 02 — Algoritmos voraces

**02 → 1. ¿Qué es un algoritmo voraz?**

⏱️ El que toma en cada paso la decisión que parece mejor localmente, **sin reconsiderarla nunca**.
🗣️ Esa irrevocabilidad es lo que lo hace barato —típicamente O(n log n), dominado por una
ordenación— y lo que lo hace peligroso: si la elección local cierra la puerta a la global, el
resultado es válido y peor.
🔬 La diferencia con la DP es exactamente esa: la DP prueba todas las opciones y se queda con la
mejor; el voraz elige una y sigue. Por eso el voraz necesita una garantía que la DP no necesita.

**02 → 2. ¿Qué dos propiedades necesita un problema para que el voraz sea óptimo?**

⏱️ Propiedad de elección voraz y subestructura óptima.
🗣️ La primera dice que la elección localmente óptima forma parte de **alguna** solución globalmente
óptima. La segunda, la misma de la DP: tras decidir, lo que queda es un subproblema del mismo tipo.
🔬 La segunda la comparten voraz y DP; **la primera es la que distingue**. Cuando solo se cumple la
subestructura óptima, hay que probar todas las opciones y eso es DP.

**02 → 3. ¿Por qué ordenar las reuniones por hora de fin y no por hora de inicio?**

⏱️ Porque terminar antes deja el **máximo tiempo libre** para las siguientes.
🗣️ Es la justificación de la elección voraz: elegir la que acaba antes no puede cerrar ninguna puerta,
porque cualquier otra alternativa termina igual o más tarde y por tanto deja igual o menos margen.
🔬 Ordenar por **inicio** falla: una reunión que empieza a las 9 y dura todo el día bloquea todo.
Ordenar por **duración** también falla: una reunión corta mal colocada puede solapar con dos que
juntas caben. Tener los dos contraejemplos preparados es lo que demuestra que entiendes por qué el
criterio correcto lo es.

**02 → 4. ¿Cuál es la diferencia entre la mochila fraccionaria y la 0/1?**

⏱️ En la fraccionaria puedes **partir** los objetos; en la 0/1, o entero o nada.
🗣️ Esa única diferencia cambia la técnica: la fraccionaria se resuelve con un voraz por ratio
valor/peso en O(n log n), y la 0/1 necesita DP en O(n·W).
🔬 El motivo: al poder partir, siempre puedes llenar la capacidad exactamente con el mejor ratio
disponible, así que la elección local es segura. Sin fracciones, coger el mejor ratio puede dejarte
un hueco que no se puede rellenar bien, y el óptimo global exige mirar combinaciones.

**02 → 5. Da un contraejemplo donde el voraz falle en el cambio de monedas.**

⏱️ Monedas `{1, 3, 4}` y objetivo 6: el voraz da 4+1+1 = 3 monedas, el óptimo es 3+3 = 2.
🗣️ El voraz coge la moneda mayor que cabe —4— y se queda con 2, que solo se puede pagar con dos unos.
La elección local cerró la puerta a la combinación buena.
🔬 Conviene tenerlo memorizado con esos números exactos: es el contraejemplo más corto que existe y
sirve para zanjar la afirmación *"el voraz resuelve el cambio de monedas"*, que es cierta con el euro
y falsa en general.

**02 → 6. ¿En qué se diferencian un voraz y una DP en cómo toman la decisión?**

⏱️ El voraz elige una opción y no vuelve; la DP evalúa todas las opciones de cada estado y se queda
con la mejor.
🗣️ Por eso el voraz es típicamente O(n log n) y la DP O(n · algo): la DP paga por explorar. Y por eso
el voraz necesita demostrar que no hace falta explorar, que es la propiedad de elección voraz.
🔬 Hay una relación más profunda: **un voraz correcto es una DP cuya tabla resulta ser innecesaria**,
porque en cada estado se puede demostrar cuál es la mejor opción sin calcular las demás. Cuando no se
puede demostrar, la tabla vuelve a hacer falta.

**02 → 7. ¿Qué es el argumento de intercambio?**

⏱️ La forma estándar de demostrar que un voraz es correcto: transformar cualquier solución óptima en
la del voraz sin empeorarla.
🗣️ Se toma una solución óptima cualquiera, se ve que sustituir su primera elección por la del voraz
sigue dando una solución válida y del mismo valor, y se repite. Si siempre se puede, el voraz es
óptimo.
🔬 En una entrevista no hace falta formalizarlo: basta con la frase que lo resume —*"elegir la que
termina antes deja el máximo margen, así que cualquier óptimo se puede reescribir con ella sin
empeorar"*—. Eso **es** el argumento, dicho en lenguaje llano.

**02 → 8. ¿Por qué Dijkstra es un algoritmo voraz y qué condición lo hace correcto?**

⏱️ Porque cierra siempre el nodo no cerrado más cercano y no reconsidera. Es correcto **porque los
pesos no son negativos**.
🗣️ La propiedad de elección voraz aquí es: el nodo con menor distancia tentativa ya tiene su distancia
final, porque cualquier camino alternativo pasa por nodos más lejanos y solo puede sumar. Sin pesos
negativos, "solo puede sumar" es cierto.
🔬 Con un peso negativo esa afirmación se rompe y el algoritmo falla **en silencio**. Es el mejor
ejemplo del corpus de que la corrección de un voraz depende de una condición del problema, no del
algoritmo: el mismo código es óptimo o incorrecto según los datos.

**02 → 9. ¿Por qué el voraz por ratio falla en la mochila 0/1? Da el ejemplo numérico.**

⏱️ Porque coger los objetos más eficientes puede dejar un hueco que no se rellena.

```text
objetos: (peso 10, valor 60), (20, 100), (30, 120)      capacidad 50
ratios:      6.0                 5.0          4.0

voraz por ratio:  10 + 20 = 30 de peso, valor 160, el tercero no cabe
óptimo:           20 + 30 = 50 de peso, valor 220
```

🗣️ El voraz llena 30 de los 50 y desperdicia 20 de capacidad. El óptimo renuncia al objeto de mejor
ratio y aprovecha la capacidad entera.
🔬 **Con fracciones el mismo voraz sería óptimo**: cogería los 10 y los 20 enteros y 20/30 del tercero,
para un valor de 60+100+80 = 240. La imposibilidad de partir es lo único que separa un problema
O(n log n) de uno NP-difícil, y decirlo así es la mejor respuesta a esta pregunta.

**02 → 10. ¿Qué es un sistema de monedas canónico?**

⏱️ Uno en el que el algoritmo voraz siempre da el número mínimo de monedas.
🗣️ El euro (`1, 2, 5, 10, 20, 50, 100, 200`) y el dólar lo son, por diseño: se eligieron para que la
gente pueda dar cambio sin pensar. `{1, 3, 4}` no lo es.
🔬 Comprobar si un sistema es canónico no es trivial: existe un algoritmo (Pearson) que lo decide en
tiempo polinómico examinando un número acotado de valores. La lección de entrevista es que **la
propiedad es del conjunto de monedas, no del algoritmo**, y que probar con tu moneda local no
demuestra nada.

**02 → 11. ¿Por qué Huffman es voraz y qué estructura usa?**

⏱️ Porque combina repetidamente los **dos símbolos menos frecuentes** sin reconsiderar. Usa un
min-heap.
🗣️ En cada paso extrae los dos nodos de menor frecuencia, los combina en uno nuevo cuya frecuencia es
la suma, y lo reinserta. Al final queda un árbol donde los símbolos frecuentes tienen códigos cortos.
O(n log n) por el heap.
🔬 Su corrección se demuestra con el argumento de intercambio: en un código óptimo, los dos símbolos
menos frecuentes pueden colocarse siempre como hermanos en el nivel más profundo sin empeorar. Es un
voraz **con demostración** y con uso real —ZIP, JPEG, MP3—, lo que lo hace el mejor ejemplo del tema.

**02 → 12. ¿Qué complejidad típica tiene un voraz frente a la DP equivalente?**

⏱️ El voraz suele ser O(n log n), dominado por una ordenación; la DP equivalente, O(n · algo).
🗣️ Mochila fraccionaria O(n log n) contra mochila 0/1 O(n·W). Selección de actividades O(n log n)
contra la DP que probaría todos los subconjuntos. La diferencia es enorme, y por eso vale la pena
buscar el voraz antes de resolverse por la DP.
🔬 Y a veces el voraz es incluso O(n): si los datos ya vienen ordenados, no hay ni siquiera que
ordenar. Esa es la señal de que un problema tiene voraz: **ordenar por algo hace que se resuelva
solo**.

**02 → 13. ¿Cómo compruebas rápido si un voraz es incorrecto, sin demostrar nada?**

⏱️ Buscando un contraejemplo pequeño. Si tardas menos de dos minutos en encontrarlo, no hay voraz.
🗣️ Es mucho más rápido que intentar demostrar la corrección, y es la comprobación que hace un
ingeniero de verdad: probar con conjuntos pequeños y adversariales —valores muy dispares, un
elemento que no cabe por poco, empates—.
🔬 La técnica que más contraejemplos produce: construir un caso donde la elección local **agote un
recurso** que haría falta después. En la mochila, el peso; en el cambio de monedas, el resto; en la
planificación, el tiempo. Esa es la forma general del fallo del voraz.

**02 → 14. ¿Puede ser útil un voraz que no es óptimo? Justifica con un caso.**

⏱️ Sí: en problemas NP-difíciles, un voraz que da el 95 % del óptimo en tiempo lineal es la solución
práctica.
🗣️ El coloreado de grafos es NP-difícil; el voraz da una coloración válida con más colores de los
necesarios, y para asignar frecuencias o registros es perfectamente utilizable. El empaquetado en
contenedores con "primer ajuste decreciente" tiene una cota de aproximación demostrada de 11/9 del
óptimo, y se usa en producción.
🔬 Lo que **no** vale es no saber que no es óptimo. Un voraz declarado como heurística, con su cota de
aproximación si se conoce, es una decisión de ingeniería; el mismo voraz presentado como óptimo es un
error. Esa distinción es lo que la pregunta busca.

**02 → 15. ¿Por qué la mochila fraccionaria admite voraz y la 0/1 no, exactamente?**

Cubierta por **02 → 4** y **02 → 9**. En una frase: porque partir objetos permite llenar la capacidad
**exactamente**, de modo que la elección local por mejor ratio nunca desperdicia espacio y por tanto
nunca cierra la puerta a una combinación mejor.

**02 → 16. ¿Qué propiedad hace correctos a Kruskal y a Prim?**

⏱️ La **propiedad del corte**: la arista más ligera que cruza cualquier corte del grafo pertenece a
algún árbol de expansión mínima.
🗣️ Un corte es una partición de los nodos en dos grupos. Ambos algoritmos, en cada paso, añaden la
arista más ligera que cruza algún corte —Prim el que separa su árbol del resto, Kruskal el que
separa las componentes que une—, así que ambos toman siempre una elección segura.
🔬 De ahí que sean correctos con pesos negativos también, a diferencia de Dijkstra: la propiedad del
corte no depende del signo. Es una diferencia que sorprende y que vale la pena tener clara.

**02 → 17. Ordenar por duración parece razonable en la selección de actividades. Da el contraejemplo.**

⏱️ Una reunión corta colocada en medio puede solapar con dos que juntas caben.

```text
A: 09:00–11:00      B: 10:30–11:30 (la más corta)     C: 11:00–13:00

por duración:  se coge B → A y C ya no caben → 1 reunión
por hora de fin: se coge A, después C        → 2 reuniones
```

🗣️ La duración no dice nada sobre cuánto margen deja para lo siguiente, que es lo que realmente
importa. La hora de fin sí.
🔬 Es un contraejemplo con tres elementos y conviene tenerlo memorizado: sirve para demostrar que
"parece razonable" no es un criterio, y es exactamente el tipo de comprobación de la pregunta 13.

**02 → 18. ¿Cómo justificarías un voraz en una entrevista sin hacer una demostración formal?**

⏱️ Diciendo por qué la elección local **no cierra puertas**, y mostrando que probaste un
contraejemplo y no lo encontraste.
🗣️ *"Elijo la que termina antes porque deja el máximo margen para las siguientes: ninguna otra
elección puede dar más opciones. Probé con reuniones muy dispares y con solapamientos parciales y no
encontré contraejemplo."* Eso es una justificación aceptable y demuestra que sabes que hace falta.
🔬 Lo que no vale es *"me parece que funciona"*. Y si no consigues justificarlo, lo honesto es decirlo
y pasar a DP: *"no me convence que el voraz sea seguro aquí, así que voy a la DP, que es O(n·W) pero
me da la garantía"*. Esa frase puntúa más que un voraz arriesgado.

**02 → 19. El reparto de funcionalidades en un sprint por ratio valor/esfuerzo, ¿es óptimo?**

⏱️ No: es la mochila 0/1, y el voraz por ratio **no es óptimo** ahí.
🗣️ Es exactamente el contraejemplo de la pregunta 9 con otro vocabulario: coger primero las
funcionalidades más "eficientes" puede dejar un hueco de puntos que no se rellena bien, cuando una
combinación distinta habría llenado el sprint entero con más valor.
🔬 Y aun así, es lo que hace todo el mundo y suele estar bien, por tres razones que conviene nombrar:
los valores de negocio son **estimaciones**, así que optimizar exactamente sobre datos inventados es
un espejismo; las funcionalidades tienen dependencias, lo que rompe el modelo de mochila; y la
diferencia entre el voraz y el óptimo suele ser pequeña. La respuesta completa es *"no es óptimo, y
probablemente da igual, y estas son las tres razones"*.

**02 → 20. Te dan un problema y propones un voraz. ¿Cuál es tu secuencia antes de escribir código?**

⏱️ Enunciar la elección, buscar un contraejemplo, y si no lo encuentro, articular por qué la elección
no cierra puertas.

```text
1. Enuncia la regla voraz explícitamente: "en cada paso elijo el de menor X"
2. Busca un contraejemplo pequeño, 2 minutos: valores dispares, empates, uno que no cabe por poco
3. Si lo encuentras → no hay voraz. Di el contraejemplo en voz alta y pasa a DP
4. Si no lo encuentras → articula el argumento de intercambio en lenguaje llano
5. Di la complejidad del voraz y la de la DP alternativa, para que se vea qué se gana
6. Escribe
```

🗣️ Los pasos 2 y 3 son los que más puntúan, y son los que casi nadie hace. Decir *"probé con
`{1,3,4}` y 6, el voraz falla, así que voy a DP"* demuestra método, honestidad y conocimiento del
riesgo de la técnica, todo en una frase.
🔬 Hay un séptimo paso implícito para problemas NP-difíciles: si el voraz no es óptimo **y** la DP no
cabe, el voraz vuelve como **heurística declarada**, con su cota de aproximación si se conoce. Ahí la
respuesta correcta no es el algoritmo sino la frase: *"esto es NP-difícil, uso primer ajuste
decreciente que garantiza como mucho 11/9 del óptimo, y lo documento como aproximación"*.

---

**02 → 21. Un voraz lleva dos años en producción dando resultados que nadie ha cuestionado. Diseña cómo comprobarías si es óptimo, sin demostrarlo formalmente.**

⏱️ Comparándolo contra una solución exacta sobre entradas reales y sobre entradas generadas, y midiendo
la brecha.
🗣️ El procedimiento: implementar una versión exacta —DP o fuerza bruta— que solo tiene que ser
correcta, no rápida; ejecutar las dos sobre un histórico de entradas reales y sobre miles de entradas
aleatorias pequeñas; y registrar en cuántas difieren y **cuánto** difieren.
🔬 Tres detalles que hacen válida la comprobación. **(1) Las entradas aleatorias pequeñas encuentran
contraejemplos que las reales no**, porque las reales suelen tener estructura —importes redondos,
duraciones típicas— que oculta el caso malo; hay que usar las dos fuentes. **(2) La métrica no es
"coincide o no" sino la brecha relativa**: un voraz que acierta el 99 % de las veces y falla un 30 %
cuando falla es peor que uno que falla siempre un 0,5 %. **(3) El resultado útil no es "es óptimo"**
—eso no se demuestra probando— sino **"no he encontrado contraejemplo en N casos, y si lo hay la
brecha está acotada por X"**, que es una afirmación honesta y suficiente para decidir. Y si aparece un
contraejemplo, el valor está en caracterizarlo: saber **en qué condiciones** falla permite decidir si
esas condiciones ocurren en producción.

**02 → 22. Escribe la justificación de un voraz para un comité técnico: qué propiedad lo hace correcto, qué pasa si esa propiedad deja de cumplirse y cómo lo detectarías.**

⏱️ Nombrar la propiedad —subestructura óptima más elección voraz segura—, decir qué supuesto del
dominio la sostiene, y monitorizar ese supuesto.
🗣️ La estructura de la justificación:

```text
PROPIEDAD   por qué la elección local nunca impide la solución global: el argumento de intercambio
SUPUESTO    qué del DOMINIO la sostiene (ej.: "las denominaciones son 1, 2, 5, 10…")
SI SE ROMPE qué resultado obtendríamos: subóptimo acotado, o arbitrariamente malo
DETECCIÓN   una alerta sobre el supuesto, no sobre el resultado
```
🔬 Lo que distingue esta respuesta es el último punto. **La propiedad casi nunca es matemática pura:
depende de un supuesto del negocio**, y los supuestos del negocio cambian sin avisar al equipo
técnico. El sistema de monedas es el ejemplo perfecto: el voraz es óptimo para las denominaciones
habituales y deja de serlo si alguien añade una de 4. Por eso la detección se pone **sobre el
supuesto** —una comprobación que falle si entra una denominación que rompe la propiedad— y no sobre
el resultado, que es indistinguible a simple vista. Un comité entiende bien esa forma: no estamos
diciendo "confía", estamos diciendo "es correcto mientras se cumpla esto, y esto está vigilado".

**02 → 23. Te piden sustituir una DP correcta por un voraz porque "va lenta". Escribe tu respuesta, incluido qué medirías antes de aceptar.**

⏱️ Que primero hay que comprobar que la DP es el cuello, y que un voraz solo es aceptable si puedo
nombrar por qué es correcto o acotar su error.
🗣️ El orden: **(1)** medir dónde se va el tiempo — muy a menudo no es la DP sino la entrada y salida
que la alimenta, por el bloque `08`; **(2)** si es la DP, mirar si su coste se puede bajar sin cambiar
de técnica —memoria de dos filas en vez de la tabla completa, poda, o reducir el espacio de estados—;
**(3)** solo entonces plantear el voraz, y con la justificación de la pregunta 22.
🔬 Y la alternativa que casi nunca se propone y suele ganar: **un voraz como aproximación declarada,
no como sustituto silencioso**. Si el negocio acepta una solución a un 2 % del óptimo a cambio de cien
veces menos tiempo, eso es una decisión legítima —y frecuente en planificación y reparto—, pero tiene
que tomarla el negocio con el número delante, no el equipo técnico por su cuenta. La respuesta que
cierra la conversación: *"puedo darte un voraz cien veces más rápido; necesito que me digas si un 2 %
de pérdida es aceptable, y si lo es lo documentamos como aproximación y medimos la brecha en
producción"*.

# 03 — Protocolo de pizarra

**03 → 1. ¿Cuáles son los siete pasos del protocolo, en orden?**

⏱️ Repetir, preguntar, ejemplo, fuerza bruta, optimizar, escribir, probar.
🗣️ Los tres primeros cuestan unos cinco minutos y evitan resolver el problema equivocado, que es el
fallo más caro. El cuarto establece la referencia. El séptimo es donde se recupera la nota
encontrando tus propios bugs.
🔬 El orden no es negociable: saltarse el 1 y el 2 para "ganar tiempo" es lo que hace que la gente
escriba treinta líneas y descubra al final que entendió otra cosa.

**03 → 2. ¿Qué seis preguntas se hacen antes de escribir código?**

⏱️ Tamaño de la entrada; si puede estar vacía o ser nula; si hay duplicados; si está ordenada; si hay
negativos o ceros; y qué se devuelve si no hay respuesta.
🗣️ Sirven para casi cualquier enunciado. La primera te dice la complejidad esperada, la cuarta habilita
dos punteros y binaria, y la quinta es la que más soluciones rompe.
🔬 La sexta parece burocrática y es de diseño: decidir entre `null`, `Optional`, `-1` o excepción es
una decisión de API, y tratarla como tal cambia el registro de la conversación.

**03 → 3. ¿Qué técnica delata la palabra "contiguo" en un enunciado?**

⏱️ Ventana deslizante.
🗣️ "Contiguo", "subcadena" y "subarreglo" implican que los elementos van seguidos, que es el requisito
de la ventana. Si el subconjunto **no** tiene que ser contiguo, la ventana no aplica y el problema
suele ser de ordenación o de DP.
🔬 El segundo requisito, menos visible, es que la condición sea **incremental**: que se pueda
actualizar al entrar y salir un elemento. "Suma ≤ límite" lo es; "la mediana de la ventana" no.

**03 → 4. ¿Qué técnica delata "el menor X tal que"?**

⏱️ Búsqueda binaria sobre la respuesta.
🗣️ También "minimiza el máximo", "maximiza el mínimo" y "¿cuál es la capacidad mínima que permite…?".
Todas describen una frontera en un espacio de respuestas donde el predicado es monótono.
🔬 El requisito que hay que comprobar en voz alta es la **monotonía**: si una respuesta X es viable,
todas las mayores también. Sin eso, descartar media mitad no está justificado.

**03 → 5. ¿Qué te dice el tamaño de la entrada sobre la solución esperada?**

⏱️ Casi todo: n ≤ 25 admite exponencial, n ≤ 5 000 admite cuadrático, 10⁵ pide n log n, más de 10⁷
pide lineal.
🗣️ El enunciado que menciona el tamaño lo hace a propósito. Decirlo en voz alta —*"con 10⁵ descarto el
cuadrático"*— demuestra que sabes leer el enunciado y ahorra escribir la solución que iban a
rechazar.
🔬 Y al revés: un enunciado que **no** menciona el tamaño es una invitación a preguntarlo, que es la
primera de las seis preguntas por este motivo exacto.

**03 → 6. ¿Cuáles son los siete casos borde que se recitan?**

⏱️ Vacío, un elemento, todos iguales, ya ordenado o al revés, valores extremos y desbordamiento,
duplicados, y qué devuelves si no hay respuesta.
🗣️ Se dicen **antes** de que los pregunten, adaptados al problema. Cubren casi todo lo que un
entrevistador va a buscar.
🔬 El de valores extremos es el que distingue: `a - b` desborda, `(lo + hi) / 2` desborda, la suma de
un arreglo de `int` desborda. Nombrarlo sin que te lo pidan es de las cosas que más suben la nota.

**03 → 7. ¿Por qué se dice la fuerza bruta aunque sepas la solución óptima?**

⏱️ Porque establece la referencia contra la que comparas y demuestra que entendiste el problema.
🗣️ Cuesta una frase —*"la fuerza bruta sería probar todos los pares, O(n²)"*— y hace explícito que la
optimización no es magia sino una mejora medible. Además, si te bloqueas después, ya tienes algo que
entregar.
🔬 Y tiene un efecto práctico: obliga a definir bien qué se está buscando, lo que muchas veces revela
una ambigüedad del enunciado que no habías visto.

**03 → 8. ¿Por qué el paso del ejemplo a mano es el más infravalorado?**

⏱️ Porque te obliga a entender el problema y te da con qué probar al final, por dos minutos de coste.
🗣️ Un ejemplo de cinco elementos con su respuesta esperada, escrito antes de teclear, detecta la mitad
de los malentendidos de enunciado. Y en el paso 7 es exactamente lo que se usa para probar.
🔬 El error de mucha gente es usar el ejemplo que da el enunciado, que suele ser el caso fácil.
Construir uno propio —con un duplicado, con un elemento que no cumple— es lo que hace el ejercicio
útil.

**03 → 9. ¿Por qué el silencio penaliza más que una idea equivocada?**

⏱️ Porque una idea mala dicha en voz alta se corrige entre los dos; una idea buena pensada en silencio
no existe.
🗣️ La entrevista mide **cómo trabajas cuando no sabes la respuesta**, que es lo que vas a hacer casi
todos los días en el puesto. El entrevistador no puede evaluar lo que no ve, y noventa segundos de
silencio se leen como bloqueo.
🔬 El corolario práctico: cuando te bloqueas, **narra el bloqueo**. *"Estoy intentando ver si puedo
evitar el bucle anidado; me sirve pensar en si los datos podrían estar ordenados"* es información
útil para los dos y muchas veces provoca una pista.

**03 → 10. ¿Qué cinco cosas evalúa de verdad el entrevistador?**

⏱️ Si entiendes el problema antes de resolverlo; si conoces el espacio de soluciones; si escribes
código legible; si detectas tus propios errores; y cómo reaccionas cuando te corrigen.
🗣️ Ninguna de las cinco es "si te sabes el algoritmo". Optimizar la memorización a costa del proceso
es optimizar la métrica equivocada.
🔬 La quinta es la que más gente descuida y la que más peso tiene en un puesto senior: muchas veces
la corrección del entrevistador es **deliberadamente discutible**, precisamente para ver si sostienes
una respuesta con argumentos o si cedes ante la autoridad.

**03 → 11. ¿Qué haces si ninguna señal del mapa encaja con el enunciado?**

⏱️ Fuerza bruta, dicha a propósito, después de comprobar el tamaño de la entrada.
🗣️ Si n es pequeño, el cuadrático es la respuesta correcta y decirlo así —*"con n ≤ 500 hago el
cuadrático, que es más claro y suficiente"*— demuestra criterio. Si n es grande y ninguna técnica
encaja, probablemente el problema tiene una estructura que todavía no viste y conviene volver al
ejemplo a mano.
🔬 La técnica de desbloqueo más útil: **resolver un caso más pequeño o más simple**. Quitar una
restricción, suponer que no hay duplicados, o resolverlo para n = 3. Muchas veces la generalización
aparece sola.

**03 → 12. En la plantilla de búsqueda binaria, ¿por qué `hi = mid` y no `mid - 1`?**

Cubierta por **03-orden-busqueda/03 → 8**. En una frase: porque en la búsqueda por frontera `mid`
**puede ser la respuesta** —cumple el predicado— y descartarlo perdería la solución.

**03 → 13. En la plantilla de BFS, ¿por qué se marca al encolar?**

Cubierta por **04-arboles-grafos/03 → 7**. En una frase: porque entre encolar y desencolar pueden
pasar muchas iteraciones, y cada vecino que descubra ese nodo volvería a encolarlo, rompiendo la
linealidad.

**03 → 14. En la plantilla de backtracking, ¿por qué se copia el estado al añadirlo?**

Cubierta por **01-fundamentos/04 → 14**. En una frase: porque el estado se sigue mutando después, así
que sin copia todas las soluciones apuntan al mismo objeto y acaban vacías.

**03 → 15. ¿Por qué la pregunta por los valores negativos rompe más soluciones que las demás?**

⏱️ Porque invalida al menos tres técnicas de golpe: ventana deslizante, voraz del cambio de monedas y
Dijkstra.
🗣️ La ventana deslizante asume que añadir elementos solo puede aumentar la suma, lo que con negativos
es falso y rompe la lógica de contracción. El voraz asume que coger el mayor nunca empeora. Dijkstra
asume que un camino más largo nunca es más barato.
🔬 Y hay un cuarto efecto, más sutil: con negativos, "el subarreglo de suma máxima" deja de ser
trivial y necesita Kadane, e "inicializar el máximo a 0" se convierte en un bug. Es la pregunta que
más soluciones cambia y la que más gente olvida hacer.

**03 → 16. ¿Cómo pruebas tu código en voz alta y por qué compensa el tiempo que cuesta?**

⏱️ Ejecutándolo con el dedo sobre tu ejemplo del paso 3, diciendo el valor de las variables en cada
iteración.
🗣️ Compensa porque **un bug encontrado por ti cuenta a favor y el mismo bug encontrado por el
entrevistador cuenta en contra**. Además, narrar la traza demuestra que entiendes tu propio código,
que no siempre es evidente.
🔬 Si el código es largo, se prueba la parte con más riesgo —el bucle, no la configuración— y se
eligen los valores que más probablemente rompan: el primero, el último, el duplicado. Al terminar se
repite la complejidad, que cierra el ejercicio y contesta la pregunta que iba a venir.

**03 → 17. El entrevistador afirma que tu solución es O(n²) y crees que es O(n). ¿Qué haces?**

⏱️ Pido el caso concreto —"¿sobre qué entrada?"— y trazo el conteo con él, en voz alta.
🗣️ No se defiende una complejidad afirmándola más fuerte: se cuenta cuántas veces se ejecuta la línea
más interna sobre un ejemplo pequeño. Si el desacuerdo está en un `while` anidado, el argumento es el
amortizado: cada elemento entra y sale una vez.
🔬 Y si al trazarlo resulta que tiene razón, decirlo rápido y sin ceremonia es una señal excelente. Lo
que se está midiendo aquí no es la complejidad: es **cómo discutes con alguien que va a ser tu
colega**, y muchas veces la afirmación es falsa a propósito justo para ver eso.

**03 → 18. No recuerdas el código de un algoritmo que sabes que aplica. ¿Cómo lo manejas?**

⏱️ Lo reconstruyo desde la idea, narrando, en vez de intentar recordar líneas.
🗣️ *"No me sé el código de KMP de memoria, déjame reconstruirlo desde la idea de la tabla de
prefijos"* es mejor respuesta que escribirlo de carrerilla sin poder explicarlo. La derivación
demuestra comprensión; la memoria no.
🔬 La técnica concreta: partir del caso más simple que sí recuerdas y añadir lo que falta. Para
Dijkstra, empezar por BFS y decir qué hay que cambiar para admitir pesos. Para la binaria por
frontera, empezar por la canónica. Casi todos los algoritmos del corpus son una variación de otro más
simple, y ese camino es el que hay que saber recorrer.

**03 → 19. Te quedan cinco minutos y la solución no está completa. ¿Qué haces con ellos?**

⏱️ Cierro lo que hay: enuncio el algoritmo completo en voz alta, digo la complejidad, y marco con un
comentario lo que falta.
🗣️ Una solución incompleta **bien explicada** puntúa mucho más que un intento frenético de teclear
hasta que suene el reloj. Si el algoritmo es correcto y solo falta código, el entrevistador puede
evaluar el razonamiento, que es lo que le interesa.
🔬 Y si lo que falta es un caso borde, **dilo explícitamente**: *"esto no maneja el arreglo vacío;
sería un `if` al principio devolviendo `Optional.empty()`"*. Nombrar lo que falta demuestra que lo
viste, y eso es casi tan bueno como haberlo escrito.

**03 → 20. Te dan un enunciado deliberadamente ambiguo. Escribe las preguntas que harías y di cómo cambia la solución cada respuesta.**

⏱️ Las seis preguntas del capítulo, y cada respuesta cambia la técnica o los casos borde.

```text
"Dame los elementos más frecuentes de una colección."

1. ¿Cuántos elementos? ¿Y cuántos distintos?
   → 10³: cualquier cosa. 10⁹ en un flujo: hay que hablar de aproximación (Count-Min Sketch)
2. ¿"Los más frecuentes" son cuántos? ¿Un k fijo, o todos los que pasen un umbral?
   → k fijo: heap acotado O(n log k). Umbral: una pasada y filtrar, O(n)
3. ¿Cabe en memoria?
   → sí: HashMap de conteos. No: particionar por hash, o estructura probabilística
4. ¿Qué hago con los empates?
   → decisión de negocio: devolver todos, o desempatar por un criterio estable
5. ¿Los elementos son comparables? ¿Tienen equals/hashCode correctos?
   → si son objetos de dominio mutables, el HashMap de conteos no funcionará
6. ¿Qué devuelvo si la colección está vacía?
   → lista vacía, no null
```

🗣️ Con las respuestas "10⁶ elementos, k = 100, cabe en memoria", la solución es `HashMap` de conteos
más min-heap acotado a 100: O(n log k) y O(distintos) de memoria. Con "flujo infinito, no cabe", la
solución cambia por completo a una estructura probabilística con error acotado.
🔬 Lo que la pregunta evalúa no es la solución final: es que **entiendas que hay varias soluciones
correctas y que la elección depende de información que no te dieron**. Un candidato que escribe
directamente el `HashMap` puede acertar por suerte; uno que pregunta demuestra que sabría manejar el
caso en que la suerte no acompañe.

**03 → 21. Te bloqueas por completo a los diez minutos. Describe tu procedimiento de desbloqueo.**

⏱️ Narrar el bloqueo, volver al ejemplo, simplificar el problema, y pedir una pista si hace falta.

```text
1. DILO. "Me he quedado atascado en X." El silencio es lo único que penaliza siempre
2. Vuelve al EJEMPLO a mano y resuélvelo tú, sin código. ¿Qué haces tú mentalmente?
3. SIMPLIFICA: quita una restricción. ¿Y si no hubiera duplicados? ¿Y si n fuera 3?
4. Revisa el MAPA de señales: ¿qué palabra del enunciado no he usado todavía?
5. Ofrece la FUERZA BRUTA como entregable mientras sigues pensando
6. PIDE una pista, concretando: "¿voy en la dirección correcta con la ventana deslizante?"
```

🗣️ El paso 2 es el que más veces desbloquea: si tú puedes resolver el ejemplo a mano, hay un
procedimiento, y hacerlo explícito **es** el algoritmo. El paso 6 no penaliza si la pregunta es
concreta; lo que penaliza es rendirse en silencio.
🔬 Y hay un desbloqueo específico por familia que conviene tener: si sospechas DP y no encuentras el
estado, escribe la **recursión de fuerza bruta** primero, porque sus parámetros **son** el estado. Si
sospechas grafos y no ves el grafo, pregúntate qué son los nodos y qué son las aristas
explícitamente. Casi todos los bloqueos son un paso omitido del protocolo, no una falta de
conocimiento.

**03 → 22. Diseña tu plan de preparación para una prueba de código dentro de dos semanas, con el tiempo que tienes.**

⏱️ Patrones antes que problemas, en voz alta y tecleando, con revisión espaciada de lo fallado.

```text
Semana 1 — cobertura (1,5 h/día)
  día 1-2  01-fundamentos: complejidad, TDAs, técnicas sobre secuencias
  día 3    03-orden-busqueda: la binaria por frontera, TECLEADA hasta que salga sin pensar
  día 4    04-arboles-grafos 02-03: heap, BFS/DFS, orden topológico
  día 5    01-fundamentos/04 y 05-dp: backtracking y DP, la progresión bruta→memo→tabla
  día 6-7  las simulaciones de los bloques cubiertos, EN VOZ ALTA y cronometradas

Semana 2 — profundidad y simulación (1,5 h/día)
  día 8-9   los problemas de pizarra de los cinco bloques, TECLEADOS en 20 min
  día 10    repaso SOLO de lo que fallaste en la semana 1
  día 11    04-arboles-grafos/04 y 02-texto, que son los menos probables
  día 12-13 simulación completa de 05-dp/04, con cronómetro y grabándote
  día 14    descanso, y repaso de las tres frases de cierre. Nada nuevo
```

🗣️ Los tres principios que sostienen el plan: **por patrón, no por problema** —el mapa de señales de
§4 vale más que cincuenta ejercicios sueltos—; **en voz alta y tecleando**, porque saber y saber
articular bajo presión son dos habilidades distintas y la entrevista mide la segunda; y **revisión
espaciada de lo fallado**, porque repasar lo que ya sabes es tiempo perdido.
🔬 Los ajustes por contexto. Si el proceso incluye prueba de código en vivo, el peso se va a los
problemas de pizarra y a la binaria y el BFS tecleados hasta la automatización. Si es una entrevista
de diseño con preguntas de estructuras, el peso se va a las simulaciones y a los "cómo se elige" de
cada capítulo. Y lo que **no** hay que hacer con dos semanas: empezar a resolver problemas nuevos el
día 13, ni estudiar temas que no están en el corpus. El último día no se aprende nada nuevo: se
consolida y se duerme.

---

# 04 — Simulación: preguntas transversales

Las `S#` que ya están cubiertas por una pregunta de capítulo no se repiten: se remite. Este
documento cruza también los cuatro bloques anteriores, así que algunas remiten fuera.

**04 → S1. ¿Qué dos condiciones comprueban que un problema es de DP?**

Cubierta por **01 → 1**.

**04 → S2. ¿Qué diferencia hay entre memoizar y tabular, y cuándo importa?**

Cubierta por **01 → 3**, **01 → 9** y **01 → 10**.

**04 → S3. ¿Por qué la mochila es pseudopolinómica?**

Cubierta por **01 → 8**.

**04 → S4. ¿Por qué en la mochila 0/1 con una fila se recorre la capacidad al revés?**

Cubierta por **01 → 15**.

**04 → S5. ¿Qué pierdes al optimizar el espacio de una DP?**

Cubierta por **01 → 17**.

**04 → S6. Te dan un problema de DP con recursión que desborda la pila. ¿Qué haces?**

Cubierta por **01 → 25**.

**04 → S7. ¿Qué necesita un problema para que el voraz sea óptimo?**

Cubierta por **02 → 2**.

**04 → S8. Da dos contraejemplos donde el voraz falla.**

Cubierta por **02 → 5** (cambio de monedas con `{1,3,4}` y 6) y **02 → 9** (mochila 0/1 por ratio).

**04 → S9. ¿Por qué Dijkstra es voraz y qué condición lo hace correcto?**

Cubierta por **02 → 8**.

**04 → S10. ¿Cómo justificas un voraz sin demostración formal?**

Cubierta por **02 → 18**.

**04 → S11. ¿Puede ser útil un voraz que no es óptimo?**

Cubierta por **02 → 14**.

**04 → S12. Enumera las señales léxicas que delatan cada técnica.**

⏱️ "Ordenado" → dos punteros. "Contiguo" → ventana. "El siguiente mayor" → pila monótona. "Los k
mayores" → heap. "El menor X tal que" → binaria sobre la respuesta. "Mínimos pasos" → BFS. "Ciclo" u
"orden" → DFS/topológico. "Conectados" → Union-Find. "Cuántas formas" o "el máximo total" → DP.
🗣️ El mapa completo está en [`03` §4](03-protocolo-de-pizarra.md#4--el-mapa-de-señales). La idea de
fondo es que **casi todos los enunciados de entrevista de backend caen en una de quince filas**, y
reconocer la fila es más rentable que saberse un algoritmo más.
🔬 Y la fila que no aparece en ninguna tabla: si ninguna señal encaja y n es pequeño, **fuerza
bruta**, dicha a propósito. Es una respuesta con criterio, no una rendición.

**04 → S13. ¿Cuándo un problema que parece DP es backtracking, y al revés?**

Cubierta por **01 → 20**.

**04 → S14. ¿Cuándo es correcta la fuerza bruta y cómo se dice?**

Cubierta por **01-fundamentos/01 → 16** y **03 → 11**. En una frase: cuando n está acotado por
contrato, y se dice declarándolo —*"con n ≤ 500 hago el cuadrático a propósito, que es más claro"*—.

**04 → S15. "Los k mayores de un flujo": elige y justifica en tres frases.**

⏱️ Min-heap acotado a k: O(n log k) en tiempo, O(k) en memoria, y funciona sobre un flujo infinito.
🗣️ Se usa **min**-heap para los mayores porque la cabeza es el peor de los k que están dentro, o sea
el candidato a expulsar. Ordenar sería O(n log n) y exigiría tener todos los elementos a la vez, que
sobre un flujo no es una opción.
🔬 La trampa que hay que mencionar: si un elemento que **ya está** en el top mejora su valor, el heap
no lo resuelve —`remove` es O(n)— y hace falta un `TreeSet` con desempate o un sorted set de Redis.
Está en **04-arboles-grafos/02 → 22**.

**04 → S16. "Minimiza la carga del más cargado": elige y justifica.**

Cubierta por **03-orden-busqueda/03 → 23**. En una frase: búsqueda binaria sobre la respuesta, porque
el predicado "¿se puede con carga máxima X?" es monótono, con una comprobación voraz lineal.

**04 → S17. "El precio vigente en esta fecha": elige y justifica.**

Cubierta por **04-arboles-grafos/01 → 23**. En una frase: `TreeMap` con `floorEntry(fecha)`, porque
la pregunta es por el **vecino por abajo** y eso es una consulta de orden que un hash no puede
responder.

**04 → S18. Hash, árbol, heap: da el criterio de elección.**

Cubierta por **04-arboles-grafos/05 → S27**.

**04 → S19. ¿Qué tres cosas dices al terminar de escribir cualquier solución?**

⏱️ Complejidad en tiempo, complejidad en espacio, y los casos borde.
🗣️ Y después las pruebas con tu ejemplo. Las tres cierran el ejercicio y contestan por adelantado las
preguntas que iban a venir, lo que cambia el tono: dejas de estar siendo examinado y pasas a estar
presentando.
🔬 Si el algoritmo tiene casos distintos —mejor, medio, peor— se nombran los tres. Y si hay coste
amortizado, la palabra "amortizado" tiene que aparecer: es la que demuestra que entiendes por qué
dos respuestas aparentemente contradictorias son ambas ciertas.

**04 → S20. ¿Por qué `HashMap` es O(1) con tres asteriscos?**

Cubierta por **03-orden-busqueda/07 → S22**.

**04 → S21. ¿Por qué un `sort` de biblioteca vence casi siempre al que escribirías?**

⏱️ Porque es un híbrido afinado durante décadas: TimSort aprovecha los tramos ya ordenados y cambia a
insertion sort por debajo de 32 elementos.
🗣️ Un merge sort o un quicksort escritos a mano son correctos y pierden: no detectan que los datos ya
están casi ordenados —donde TimSort es O(n)—, no tienen las optimizaciones de umbral, y no están
probados contra los casos degenerados. Además, `Arrays.sort` elige el algoritmo según el tipo.
🔬 La respuesta completa añade cuándo **sí** escribirías el tuyo: cuando necesitas una propiedad que la
biblioteca no da —counting sort con rango acotado, ordenación externa, un orden parcial— o cuando el
entrevistador te lo pide explícitamente, que es un ejercicio y hay que tratarlo como tal.

**04 → S22. ¿Qué tienen en común el peor caso de quicksort y el de un BST sin balanceo?**

⏱️ Los dos se disparan con **datos ya ordenados**, que es la entrada más común del mundo real.
🗣️ En quicksort con pivote ingenuo, un arreglo ordenado produce particiones de n-1 y 0: O(n²). En un
BST, insertar en orden creciente crea una lista enlazada: O(n) por operación. En ambos, la estructura
que debía ser logarítmica se vuelve lineal.
🔬 La lección compartida es que **los datos reales no son aleatorios**, y las dos soluciones son
análogas: aleatorizar o equilibrar. Quicksort usa pivote aleatorio o mediana de tres; el árbol usa
rotaciones. Ver que son el mismo problema con dos soluciones distintas es de las conexiones que mejor
demuestran comprensión del corpus entero.

**04 → S23. ¿Qué tienen en común el coste amortizado del `ArrayList`, el de la pila monótona y el `heapify` en O(n)?**

⏱️ Los tres son **análisis amortizados**: una operación cara se paga con muchas baratas, y el
promedio sobre la secuencia es mejor que el peor caso individual.
🗣️ En el `ArrayList`, la copia O(n) del redimensionado se reparte entre las n inserciones baratas que
la precedieron, por la serie geométrica. En la pila monótona, el `while` interno puede desapilar
muchos elementos, pero cada uno entra y sale **una sola vez** en toda la ejecución. En `heapify`, la
mayoría de los nodos son hojas que no se mueven, y la serie `Σ h/2^h` converge a 2.
🔬 Los tres comparten la misma estructura de argumento: **contar el trabajo total y dividirlo entre
las operaciones**, en vez de acotar cada operación por separado. Reconocer esa forma es lo que
permite detectar que un bucle anidado es lineal, que es la trampa de conteo que más gente falla.
Y hay un cuarto ejemplo en el corpus: la compresión de caminos de Union-Find, cuyo O(α(n)) es el
análisis amortizado más sofisticado del temario.

**04 → S24. ¿Cuáles son los siete pasos y cuál es el que más gente se salta?**

Cubierta por **03 → 1**. El que más se salta es el **3, el ejemplo a mano**, y es el que más veces
evita resolver el problema equivocado.

**04 → S25. ¿Qué seis preguntas haces antes de escribir?**

Cubierta por **03 → 2**.

**04 → S26. Te quedan cinco minutos y no has terminado. ¿Qué haces?**

Cubierta por **03 → 19**.

**04 → S27. El entrevistador te corrige y tiene razón. ¿Cómo lo manejas?**

⏱️ Lo reconozco rápido, sin ceremonia, y sigo: *"tienes razón, con ese caso mi solución falla; la
arreglo así"*.
🗣️ Lo que se está midiendo no es quién tenía razón: es cómo trabajas con alguien que va a ser tu
colega. Una corrección aceptada con naturalidad y aplicada de inmediato es una señal excelente; la
defensa a ultranza de algo que ya sabes que es dudoso es la peor respuesta posible.
🔬 Y el reverso, que también se evalúa: si **no** tiene razón, hay que sostenerlo con argumentos, no
con insistencia. Trazar el conteo sobre un ejemplo concreto es la forma de resolverlo sin que sea
una discusión de autoridad. Muchas correcciones son deliberadamente falsas para ver exactamente eso.

**04 → S28. "¿Para qué sirve esto si nunca implementas un algoritmo?" Responde.**

Cubierta por **01-fundamentos/06 → S35** y **04-arboles-grafos/05 → S31**. En una frase: sirve para
**elegir** lo que ya está implementado y para tener el vocabulario del diagnóstico cuando algo se
degrada en producción.

**04 → S29. ¿Cuál de todos estos temas te parece más sobrevalorado en las entrevistas?**

⏱️ Es una pregunta de opinión con trampa: se responde con criterio y sin desprecio.
🗣️ Una respuesta defendible: los algoritmos de cadenas con nombre propio —KMP, Boyer-Moore— porque
ningún lenguaje de los cinco los trae en su stdlib y en quince años de backend casi nadie los escribe;
mientras que el contrato `equals`/`hashCode` o la elección entre hash y árbol se usan cada semana y se
preguntan menos.
🔬 Lo que hace buena la respuesta es el **matiz**: reconocer para qué sí sirve lo que criticas
—entender por qué `indexOf` es ingenuo y cuándo eso deja de bastar es conocimiento real— y no
convertir la opinión en una queja. Contestar "todo esto es inútil" es la peor versión posible;
contestar "nada, todo es importante" es evasivo y tampoco puntúa.

**04 → S30. Te dan un problema que no sabes resolver. Describe los primeros cinco minutos.**

⏱️ Los pasos 1 a 4 del protocolo, sin saltarse ninguno: repetir, preguntar, ejemplo a mano, fuerza
bruta.

```text
min 0-1   repito el enunciado con mis palabras y confirmo que entendí
min 1-2   las seis preguntas: tamaño, vacío, duplicados, orden, negativos, qué devuelvo
min 2-4   ejemplo pequeño a mano, con su respuesta esperada, resuelto MENTALMENTE
min 4-5   enuncio la fuerza bruta con su complejidad, aunque sea horrible
```

🗣️ En el minuto 5 ya tengo tres cosas que no tenía: el problema bien definido, un caso de prueba, y
una solución entregable aunque sea mala. Desde ahí, el paso 5 —buscar la técnica en el mapa de
señales— tiene mucha más información que al principio.
🔬 Lo importante es que **estos cinco minutos son idénticos tanto si sabes resolverlo como si no**. Por
eso funcionan: no delatan que estás perdido, y muchas veces el propio proceso revela la solución. El
paso que más desbloquea es el 3: si puedes resolver el ejemplo a mano, hay un procedimiento, y
explicitarlo **es** el algoritmo. Y si a los cinco minutos sigues sin ver la técnica, decirlo en voz
alta y pedir una pista concreta —*"¿voy bien pensando en una ventana deslizante?"*— no penaliza;
rendirse en silencio, sí.

---

# 04 — Simulación: problemas de pizarra

**04 → P1. El presupuesto del sprint.**

**Reconocer el problema.** 30 funcionalidades con valor y coste, capacidad 40 puntos, objetos
indivisibles: es la **mochila 0/1**. No es la fraccionaria porque media funcionalidad no aporta medio
valor.

**Solución.** DP con una fila, recorrida al revés:

```java
int[] dp = new int[41];                                  // dp[p] = mejor valor con p puntos
for (Funcionalidad f : funcionalidades) {
    for (int p = 40; p >= f.puntos(); p--) {             // AL REVÉS: es la mochila 0/1
        dp[p] = Math.max(dp[p], dp[p - f.puntos()] + f.valor());
    }
}
return dp[40];
```

**Complejidad.** O(n · capacidad) = 30 × 40 = 1 200 operaciones. Instantáneo.

**¿Es óptimo ordenar por valor/esfuerzo?** **No.** Es el voraz por ratio, y falla en la mochila 0/1
por el contraejemplo de `02 → 9`: coger las funcionalidades más "eficientes" puede dejar un hueco de
puntos que no se rellena, cuando otra combinación habría llenado el sprint entero con más valor.

**Y aun así, suele estar bien**, y decir esto completa la respuesta: los valores de negocio son
estimaciones, así que optimizar exactamente sobre datos inventados es un espejismo; las
funcionalidades tienen dependencias entre sí, lo que rompe el modelo de mochila; y la diferencia
entre el voraz y el óptimo suele ser pequeña. La respuesta completa es *"no es óptimo, probablemente
da igual, y estas son las tres razones"*.

**Qué devuelvo además del valor.** El negocio quiere **qué funcionalidades**, no cuánto va a ganar.
Eso obliga a mantener la matriz completa y reconstruir hacia atrás, y por tanto **descarta la
optimización a una fila** que acabo de escribir. Es la decisión que hay que declarar.

**La repregunta: "¿y si se pudieran hacer a medias?"** Entonces es la **fraccionaria**, y el voraz por
ratio **sí** es óptimo: O(n log n) y se acabó la DP. Esa única diferencia —poder partir— es lo que
separa un problema NP-difícil de uno trivial.

**04 → P2. La sala de reuniones.**

**Reconocer el problema.** Máximo número de intervalos no solapados: **selección de actividades**, el
voraz canónico.

**Solución.** Ordenar por **hora de fin** y coger cada una compatible con la última elegida:

```java
reuniones.sort(Comparator.comparing(Reunion::fin));      // por FIN, no por inicio ni duración
LocalTime ultimoFin = LocalTime.MIN;
int cabidas = 0;
for (Reunion r : reuniones) {
    if (!r.inicio().isBefore(ultimoFin)) { cabidas++; ultimoFin = r.fin(); }
}
```

**Complejidad.** O(n log n), dominado por la ordenación.

**La justificación, que es la mitad del ejercicio.** Elegir la que termina antes **deja el máximo
tiempo libre** para las siguientes: ninguna otra elección puede dar más opciones. Formalmente es el
argumento de intercambio —cualquier solución óptima se puede reescribir sustituyendo su primera
reunión por la del voraz sin empeorar—, pero en voz alta basta con la primera frase.

**Los contraejemplos de los criterios equivocados**, que hay que tener preparados:

```text
por INICIO:    una reunión de 09:00 a 18:00 bloquea el día entero
por DURACIÓN:  A 09:00–11:00, B 10:30–11:30 (la más corta), C 11:00–13:00
               → por duración se coge B y se pierden A y C: 1 en vez de 2
```

**La repregunta: "¿cuántas salas hacen falta para acomodarlas todas?"** **Es otro problema**, y
detectarlo es lo que se evalúa. La respuesta es el **máximo solapamiento simultáneo**, y se calcula
con un barrido de eventos: +1 en cada inicio, −1 en cada fin, ordenados por hora, y el máximo del
acumulado. O(n log n) también, pero con un algoritmo distinto —no es voraz de selección, es un
barrido—. La conexión con el corpus: es el mismo patrón que la línea de tiempo de un
`TreeMap<LocalTime, Integer>` con incrementos y decrementos.

**04 → P3. La ruta de reparto.**

**Con 12 direcciones.** Es el **problema del viajante** (TSP), que es NP-difícil. Con n = 12 se
resuelve **exacto** con DP sobre máscaras de bits —Held-Karp—:

```text
dp[mascara][i] = coste mínimo de visitar el conjunto `mascara` terminando en i
complejidad: O(2ⁿ · n²) = 2¹² · 144 ≈ 590 000 operaciones → milisegundos
```

- La máscara es un entero donde cada bit dice si esa dirección ya se visitó. Es exactamente la
  técnica de `01 → 21`.
- La fuerza bruta sería 11! ≈ 40 millones de permutaciones: también viable con 12, y **peor**. Decir
  las dos y compararlas es lo correcto.

**Con 200 direcciones.** 2²⁰⁰ no existe: **el problema cambia de familia**. Ya no se busca el óptimo,
se busca una solución buena con garantía:

```text
construcción:  vecino más cercano (voraz)          → rápido, ~25 % peor que el óptimo
mejora:        2-opt / or-opt sobre esa ruta       → baja a ~5 % del óptimo
o directamente: Christofides, con garantía de 1.5× el óptimo (si la distancia es métrica)
o en producción: una biblioteca de optimización (OR-Tools) con límite de tiempo
```

**La repregunta: "¿qué garantía te da tu segunda solución?"** Es la pregunta clave y la respuesta
honesta es: el vecino más cercano **no tiene garantía útil** —puede ser arbitrariamente malo en el
peor caso—; 2-opt tampoco la tiene, aunque en la práctica funciona muy bien; **Christofides sí**:
como mucho 1.5 veces el óptimo, siempre que las distancias cumplan la desigualdad triangular, que en
un mapa real sí se cumple. Saber que existe una heurística **con cota demostrada** y nombrarla es lo
que distingue la respuesta.

**Lo que este problema evalúa.** Que detectes que el enunciado cambió de familia a mitad, y que sepas
que la respuesta correcta a un NP-difícil grande **no es un algoritmo exacto más rápido**: es una
aproximación declarada como tal.

**04 → P4. El detector de duplicados.**

**La solución evidente.** Un `HashSet` de identificadores vistos. O(1) por evento.

**Con 4 GB de memoria.** 500 millones de identificadores de, digamos, 16 bytes son 8 GB solo de
datos, más la sobrecarga del `HashSet` —que en Java fácilmente duplica—: no cabe ni de lejos. Las
salidas, en orden:

```text
1. Particionar por hash del id entre N nodos      → cada uno ve 1/N de los ids
2. Guardar solo un hash de 8 bytes en vez del id  → riesgo de colisión, hay que evaluarlo
3. Ventana temporal: si los duplicados llegan cerca, basta con las últimas horas
```

**Con falsos positivos aceptables y falsos negativos no.** Esta es la restricción que decide:
**filtro de Bloom**. Garantiza que si dice "no está", seguro que no está —sin falsos negativos— y
puede decir "puede estar" cuando no está.

```text
500 · 10⁶ elementos × 10 bits / 8 = ~625 MB   →  ~1 % de falsos positivos. Cabe en 4 GB.
```

- **El sentido de la asimetría importa y hay que comprobarlo.** El Bloom nunca da falso negativo, así
  que nunca dirá "nuevo" sobre algo repetido. Sus falsos positivos marcarán como repetido algo que es
  nuevo: **se perdería una transacción legítima**. Si eso es inaceptable, el Bloom es solo un filtro
  previo y hay que verificar contra un almacén real los que dé positivo.
- Con la restricción tal como está enunciada —falso positivo aceptable— el Bloom solo es suficiente
  si "aceptable" significa lo que acabo de describir. **Preguntarlo es parte de la respuesta.**

**La repregunta: "¿qué cambia si el orden de llegada importa?"** Cambia bastante: el Bloom no guarda
orden ni momento, así que no puede responder "¿cuál llegó primero?" ni expirar entradas. Haría falta
una estructura con marca de tiempo —un mapa con TTL, o la ventana de un procesador de flujos— y el
Bloom quedaría como filtro previo. Está desarrollado en **03-orden-busqueda/04 → 24**.

**04 → P5. El corrector de códigos.**

**Reconocer que son dos bloques.** El formato es fijo —`02-texto/03`, expresiones regulares— y "los
más parecidos" es **distancia de edición** —`02-texto/02` y `05-dp/01`—. Y hay una restricción de
tiempo que descarta la solución directa.

**Por qué no sirve lo obvio.** Calcular la distancia de edición contra los 2 millones de códigos son
2·10⁶ matrices de 11×11 ≈ 2,4·10⁸ celdas por consulta: muy por encima de 200 ms.

**Solución.**

```text
1. Validar el formato con la regex: si el código es válido y no existe, es un error distinto
2. Aprovechar la ESTRUCTURA: AAA-9999-XX tiene longitud fija y posiciones tipadas
   → los errores de tecleo son casi siempre: un carácter cambiado, dos transpuestos,
     o una confusión visual (O/0, I/1, S/5)
3. GENERAR las variantes a distancia 1 del código tecleado —unos cientos— y comprobar
   cuáles existen en un HashSet de los 2 millones: O(variantes) con lookup O(1)
4. Si no hay resultados, generar distancia 2 (miles de variantes) o caer a un índice
   por trigramas
```

**Complejidad.** Generar las variantes a distancia 1 de un código de 10 caracteres con alfabeto
acotado son unos pocos cientos de candidatos; cada comprobación es O(1) en el `HashSet`.
**Microsegundos**, no 200 ms.

- Es el enfoque de Norvig, y funciona aquí especialmente bien **porque el formato es fijo y el
  alfabeto por posición está acotado**: en las posiciones de dígito solo hay 10 variantes, no 36.
  Aprovechar eso es la diferencia entre cientos y miles de candidatos.
- La alternativa si el formato no fuera fijo: un **BK-tree** sobre la distancia de edición, o un
  índice de trigramas. Nombrarlas demuestra que conoces el espacio de soluciones.

**La repregunta: "¿y si te dicen que tiene que ser exacto y no aproximado?"** Aquí la respuesta
correcta es **negociar el requisito**, y esa es la trampa del problema. "Exacto" sobre "los tres más
parecidos" no significa nada por sí solo: hay que preguntar **exacto respecto a qué métrica**. Si la
métrica es la distancia de edición pura, se puede hacer exacto con un BK-tree, que poda usando la
desigualdad triangular y no exige comparar contra los 2 millones. Si lo que quieren es "que nunca
falle en sugerir el correcto", eso no es una propiedad del algoritmo sino del modelo de errores, y la
respuesta es instrumentar: registrar qué corrección elige el operario y ajustar. Decir *"'exacto'
aquí no está definido; déjame proponer dos interpretaciones"* es exactamente lo que se está
evaluando.

---

**Vuelta a:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**README del bloque:** [`05-dp-y-tecnicas`](README.md)

---

**Anterior:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**Bloque:** [README](README.md)
