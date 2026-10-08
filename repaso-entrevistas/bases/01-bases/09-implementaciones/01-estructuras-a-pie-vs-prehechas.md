# 01 — Estructuras: a pie contra prehechas

> **Documento opcional.** Está fuera del hilo principal y **no hace falta leerlo para aprobar una
> entrevista**: la teoría está en [`04-arboles-grafos`](../04-arboles-grafos/) y en
> [`03-orden-busqueda`](../03-orden-busqueda/). Esto es para quien quiera ver el código.
> Tres estructuras implementadas **a pie en Java** —que es lo que te pedirán teclear— y resueltas
> **con la biblioteca en Python** —que es la respuesta cara: "no lo implemento, uso esto"—, con el
> equivalente en JavaScript y Go.
> **Versiones ejecutadas:** Java 21.0.12 y 17.0.15 (Zulu, vía sdkman), Python 3.13, Node 24.21, Go
> 1.27 — salida idéntica en ambas versiones de Java. TypeScript se comprueba con `tsc --strict`, y
> solo aparece donde el tipo cambia la respuesta.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:** [1 — heap](#1--el-heap-binario) · [2 — Union-Find](#2--union-find) ·
[3 — trie y prefijos](#3--trie-y-consultas-por-prefijo) · [4 — la cuenta](#4-️-la-cuenta-de-líneas-y-de-bugs)

---

## 1. 🧱 El heap binario

Teoría en [`04-arboles-grafos/02`](../04-arboles-grafos/02-monticulos-y-colas-de-prioridad.md).
Aquí, las dos operaciones que lo componen y cómo se resuelve en cada lenguaje.

### Java, a pie

Es lo que te van a pedir escribir. Cuarenta líneas, y las dos que importan son `siftUp` y
`siftDown`.

```java
final class MinHeap {
    private int[] datos = new int[8];
    private int tam = 0;

    void offer(int valor) {
        if (tam == datos.length) datos = Arrays.copyOf(datos, tam * 2);  // duplicar: O(1) amortizado
        datos[tam] = valor;
        siftUp(tam++);
    }

    int poll() {
        if (tam == 0) throw new IllegalStateException("heap vacío");
        int minimo = datos[0];
        datos[0] = datos[--tam];        // el último sube a la raíz
        siftDown(0);
        return minimo;
    }

    private void siftUp(int i) {
        while (i > 0) {
            int padre = (i - 1) / 2;
            if (datos[padre] <= datos[i]) break;       // invariante restaurado: para
            intercambiar(i, padre);
            i = padre;
        }
    }

    private void siftDown(int i) {
        while (true) {
            int izq = 2 * i + 1, der = 2 * i + 2, menor = i;
            if (izq < tam && datos[izq] < datos[menor]) menor = izq;
            if (der < tam && datos[der] < datos[menor]) menor = der;   // el MENOR de los dos hijos
            if (menor == i) break;
            intercambiar(i, menor);
            i = menor;
        }
    }

    private void intercambiar(int a, int b) { int t = datos[a]; datos[a] = datos[b]; datos[b] = t; }
}
```

- **No hay nodos ni punteros**: los hijos de `i` están en `2i+1` y `2i+2`, y el padre en `(i-1)/2`.
  Toda la estructura del árbol vive en la aritmética de los índices.
- **`siftDown` compara con el menor de los dos hijos**, no con el primero que sea menor. Si
  intercambias con el mayor, el invariante se rompe entre el nuevo padre y el otro hijo. Es el bug
  clásico.
- El `break` de `siftUp` es la condición de parada correcta: en cuanto el padre ya es menor o igual,
  todo lo de arriba también lo es y no hace falta seguir.

Salida verificada sobre el arreglo de juguete del corpus:

```text
offer(5,2,9,1,5,6) y poll() hasta vaciar  →  1 2 5 5 6 9
```

### Python, prehecho

```python
import heapq

datos = [5, 2, 9, 1, 5, 6]
heapq.heapify(datos)                       # O(n), in-place, sobre una lista NORMAL
print(" ".join(str(heapq.heappop(datos)) for _ in range(6)))   # 1 2 5 5 6 9

maximos = [-x for x in [5, 2, 9, 1, 5, 6]] # heapq SOLO es min-heap: se niegan las claves
heapq.heapify(maximos)
print(-heapq.heappop(maximos))             # 9

print(heapq.nlargest(3, [5, 2, 9, 1, 5, 6]))   # [9, 6, 5] — el top-K, ya hecho
```

- **`heapq` opera sobre una `list` corriente**, no sobre un tipo propio. Es minimalista hasta el
  punto de no tener clase: las funciones reciben la lista.
- **Solo hay min-heap.** El idioma para el máximo es negar las claves, y con tuplas se usa
  `(-prioridad, contador, elemento)` para que los empates no comparen el elemento —que puede no ser
  comparable y lanzar `TypeError`—.
- **`nlargest` es el top-K acotado ya implementado**, y con un heap de tamaño k por dentro: la
  respuesta de [`04-arboles-grafos/02`](../04-arboles-grafos/02-monticulos-y-colas-de-prioridad.md)
  en una línea.

### JavaScript: no hay, y se nota

```javascript
class MinHeap {
  #d = [];
  get size() { return this.#d.length; }
  peek() { return this.#d[0]; }
  offer(v) { this.#d.push(v); this.#up(this.#d.length - 1); }
  poll() {
    const min = this.#d[0], ultimo = this.#d.pop();
    if (this.#d.length) { this.#d[0] = ultimo; this.#down(0); }
    return min;
  }
  #up(i) {
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (this.#d[p] <= this.#d[i]) break;
      [this.#d[p], this.#d[i]] = [this.#d[i], this.#d[p]];
      i = p;
    }
  }
  #down(i) {
    for (;;) {
      const l = 2 * i + 1, r = 2 * i + 2; let m = i;
      if (l < this.#d.length && this.#d[l] < this.#d[m]) m = l;
      if (r < this.#d.length && this.#d[r] < this.#d[m]) m = r;
      if (m === i) break;
      [this.#d[m], this.#d[i]] = [this.#d[i], this.#d[m]];
      i = m;
    }
  }
}
```

- **Es la misma implementación que la de Java**, con campos privados `#` y desestructuración para el
  intercambio. No hay atajo porque no hay heap en la plataforma.
- El `>> 1` en vez de `/ 2` no es micro-optimización: en JavaScript la división da un `float`, y
  `(i - 1) / 2` con `i = 4` daría `1.5` como índice. Es un bug real y silencioso.

### Go: la interfaz en vez de la estructura

```go
type Enteros []int

func (e Enteros) Len() int           { return len(e) }
func (e Enteros) Less(i, j int) bool { return e[i] < e[j] }   // aquí se decide min o max
func (e Enteros) Swap(i, j int)      { e[i], e[j] = e[j], e[i] }
func (e *Enteros) Push(x any)        { *e = append(*e, x.(int)) }
func (e *Enteros) Pop() any {
	viejo := *e
	n := len(viejo)
	ultimo := viejo[n-1]
	*e = viejo[:n-1]
	return ultimo
}

datos := &Enteros{5, 2, 9, 1, 5, 6}
heap.Init(datos)                     // O(n), el heapify de Go
for datos.Len() > 0 { fmt.Print(heap.Pop(datos), " ") }    // 1 2 5 5 6 9
```

- **Tú aportas la estructura, Go aporta los algoritmos.** Implementas cinco métodos y el paquete
  `container/heap` pone `Init`, `Push`, `Pop` y `Fix`.
- Es más ceremonia que `heapq` y a cambio funciona sobre **cualquier representación tuya** sin
  copiar: si tus datos ya viven en un slice de structs, el heap opera sobre él en sitio.
- `Less` es donde se decide min o max, y cambiar `<` por `>` es todo lo que hace falta. Más limpio
  que negar las claves.

> 💡 **Truco.** La pregunta "¿cómo harías un max-heap?" tiene cuatro respuestas distintas según el
> lenguaje: comparador invertido en Java, negar las claves en Python, cambiar `<` por `>` en el
> `Less` de Go, y en JavaScript cambiar la comparación de tu propia implementación. Saber las cuatro
> es una respuesta políglota completa.

---

## 2. 🧱 Union-Find

Teoría en
[`04-arboles-grafos/03`](../04-arboles-grafos/03-grafos-representacion-y-recorridos.md#7--conectividad-componentes-y-union-find).
Ningún lenguaje de los cinco lo trae: aquí se implementa en todos.

### Java, con las dos optimizaciones

```java
final class UnionFind {
    private final int[] padre;
    private final int[] tam;
    private int componentes;

    UnionFind(int n) {
        padre = new int[n];  tam = new int[n];
        for (int i = 0; i < n; i++) { padre[i] = i; tam[i] = 1; }
        componentes = n;
    }

    int find(int x) {
        if (padre[x] != x) padre[x] = find(padre[x]);   // compresión: reengancha a la raíz
        return padre[x];
    }

    boolean union(int a, int b) {
        int ra = find(a), rb = find(b);
        if (ra == rb) return false;                    // ya estaban juntos: esta arista cierra ciclo
        if (tam[ra] < tam[rb]) { int t = ra; ra = rb; rb = t; }   // el pequeño cuelga del grande
        padre[rb] = ra;
        tam[ra] += tam[rb];
        componentes--;
        return true;
    }
}
```

- **`union` devuelve un booleano**, y eso no es un detalle de estilo: `false` significa "ya estaban
  conectados", que en Kruskal es exactamente "esta arista cierra un ciclo, descártala". Con esa
  firma, Kruskal son cinco líneas.
- La **compresión de caminos** está en la única línea de `find`: al volver de la recursión,
  reengancha cada nodo del camino directamente a la raíz.
- La **unión por tamaño** evita crear cadenas largas. Con las dos, el coste amortizado es O(α(n)):
  menos de 5 para cualquier n del universo real.

Salida verificada: tras `union(0,1)`, `union(1,3)` y `union(2,4)` sobre seis elementos,
`conectados(0,3)` es `true`, `conectados(0,4)` es `false`, y quedan **3 componentes**.

### Python, con la compresión iterativa

```python
class UnionFind:
    def __init__(self, n):
        self.padre = list(range(n))
        self.tam = [1] * n
        self.componentes = n

    def find(self, x):
        while self.padre[x] != x:
            self.padre[x] = self.padre[self.padre[x]]   # compresión por saltos: iterativa
            x = self.padre[x]
        return x

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra == rb:
            return False
        if self.tam[ra] < self.tam[rb]:
            ra, rb = rb, ra
        self.padre[rb] = ra
        self.tam[ra] += self.tam[rb]
        self.componentes -= 1
        return True
```

- **La compresión es iterativa a propósito**, y aquí el lenguaje manda: el límite de mil niveles de
  recursión de Python hace que la versión recursiva de `find` sea arriesgada con conjuntos grandes.
- `self.padre[x] = self.padre[self.padre[x]]` es *path halving*: no aplana del todo como la
  recursiva, y da la misma cota amortizada con menos trabajo por llamada.
- El intercambio `ra, rb = rb, ra` es el idioma de Python para lo que en Java son tres líneas con
  variable temporal.

**En JavaScript y Go** la implementación es la misma que la de Python, con arreglos de enteros y
`find` iterativo. No hay diferencias que enseñen nada, así que no se repiten aquí: es la aplicación
de la regla de §5.1 de la [guía](../prompts/guia-de-estilo-y-convenciones.md), que prohíbe rellenar
un apartado que no aporta.

---

## 3. 🧱 Trie y consultas por prefijo

Teoría en [`04-arboles-grafos/01`](../04-arboles-grafos/01-arboles.md#7--trie) y en
[`02-texto/02`](../02-texto/02-algoritmos-de-cadenas.md). **Y aquí está el caso donde "a pie" es la
respuesta equivocada**, que es la lección de este apartado.

### Java: el trie completo

```java
final class Trie {
    private static final class Nodo {
        final Map<Character, Nodo> hijos = new HashMap<>();
        boolean finDePalabra;
    }
    private final Nodo raiz = new Nodo();

    void insertar(String palabra) {
        Nodo actual = raiz;
        for (char c : palabra.toCharArray()) {
            actual = actual.hijos.computeIfAbsent(c, k -> new Nodo());  // sin recursión: seguro
        }
        actual.finDePalabra = true;
    }

    boolean contiene(String palabra) {
        Nodo nodo = bajar(palabra);
        return nodo != null && nodo.finDePalabra;   // el flag distingue PALABRA de PREFIJO
    }

    List<String> porPrefijo(String prefijo) {
        Nodo nodo = bajar(prefijo);
        List<String> resultado = new ArrayList<>();
        if (nodo != null) recoger(nodo, new StringBuilder(prefijo), resultado);
        return resultado;
    }

    private void recoger(Nodo nodo, StringBuilder acumulado, List<String> resultado) {
        if (nodo.finDePalabra) resultado.add(acumulado.toString());
        for (Map.Entry<Character, Nodo> e : new TreeMap<>(nodo.hijos).entrySet()) {
            acumulado.append(e.getKey());
            recoger(e.getValue(), acumulado, resultado);
            acumulado.deleteCharAt(acumulado.length() - 1);   // deshacer: es backtracking
        }
    }
}
```

- **`finDePalabra` es imprescindible.** Sin él no se puede distinguir `"cam"` —que es solo un
  prefijo— de `"cama"` —que es una palabra—. Verificado: `contiene("cama")` es `true` y
  `contiene("cam")` es `false`.
- **`recoger` es backtracking**: añade el carácter, recursa, y lo quita. Es el patrón de
  [`01-fundamentos/04`](../01-fundamentos/04-recursion-y-backtracking.md) aplicado a una estructura.
- El `new TreeMap<>(nodo.hijos)` ordena los hijos para que la salida sea determinista. Sin él, el
  orden depende del `HashMap` y cambia entre versiones de la JDK — el problema de
  [`01-fundamentos/02`](../01-fundamentos/02-tdas-contrato-e-implementacion.md).

### Java otra vez: lo mismo, en una línea

```java
TreeSet<String> terminos = new TreeSet<>(List.of("cama", "camisa", "camion", "cable", "casa"));
terminos.subSet("cam", "cam" + '￿');     // → [cama, camion, camisa]
```

- **Es el mismo resultado que las cincuenta líneas anteriores.** `'￿'` es el carácter más alto
  del plano básico, así que el rango `["cam", "cam￿")` contiene exactamente las claves que
  empiezan por `"cam"`.
- O(log n) para localizar el inicio, más el tamaño del resultado. Para unos miles de términos es
  indistinguible del trie y no hay nada que mantener.
- **El trie se justifica** con millones de términos —su coste es independiente del tamaño del
  diccionario— o cuando hace falta más que el rango: contar por prefijo, tolerar errores, o
  Aho-Corasick.

### Python: sin árbol ordenado, con `bisect`

```python
import bisect

terminos = sorted(["cama", "camisa", "camion", "cable", "casa"])

def por_prefijo(prefijo):
    izq = bisect.bisect_left(terminos, prefijo)
    der = bisect.bisect_left(terminos, prefijo + "￿")   # el rango [prefijo, prefijo+alto)
    return terminos[izq:der]

por_prefijo("cam")   # ['cama', 'camion', 'camisa']
por_prefijo("z")     # []
```

- **Es la misma idea sin `TreeSet`**, porque Python no lo tiene: una lista ordenada y dos búsquedas
  binarias. El resultado es idéntico.
- El precio está en la **inserción**: O(n) por el desplazamiento del arreglo, frente a O(log n) del
  árbol. Con un conjunto que cambia mucho, se usa `sortedcontainers`, que mantiene bloques.
- En Go la solución es la misma con `sort.SearchStrings` sobre un slice ordenado.

> 🧠 **Modelo mental.** Este apartado es el que mejor resume el bloque: **saber implementar el trie
> es lo que te piden en la pizarra; saber que `subSet` existe es lo que te hace útil en el equipo.**
> La respuesta completa en una entrevista empieza por la segunda y ofrece la primera.

---

## 4. ⚖️ La cuenta de líneas y de bugs

Lo que cuesta cada estructura en cada lenguaje, contando solo la implementación:

| Estructura | Java a pie | Python con biblioteca | JS | Go | Dónde está el riesgo |
|---|---|---|---|---|---|
| **Heap** | ~40 líneas | **3 líneas** (`heapq`) | ~35 líneas | ~15 líneas (interfaz) | `siftDown` con el hijo equivocado |
| **Union-Find** | ~20 líneas | ~18 líneas | ~18 líneas | ~18 líneas | Olvidar una de las dos optimizaciones |
| **Trie** | ~50 líneas | ~30 líneas | ~30 líneas | ~30 líneas | El flag de fin de palabra |
| **Consulta por prefijo** | **1 línea** (`subSet`) | **4 líneas** (`bisect`) | ~10 líneas | ~6 líneas (`sort.Search`) | Ninguno: usa la biblioteca |
| **LRU** | **5 líneas** (`LinkedHashMap`) | ~25 líneas | ~25 líneas | ~25 líneas | Lista simple en vez de doble |

Los tres bugs que aparecen al implementar a pie, en orden de frecuencia:

1. **`siftDown` intercambiando con el hijo equivocado.** Se detecta con un heap de tres elementos:
   raíz 9, hijos 2 y 5. Si sube el 5, el invariante se rompe en un solo paso.
2. **Union-Find sin unión por tamaño.** Funciona y degenera: con inserciones en orden, los árboles
   se convierten en cadenas y `find` pasa a ser O(n).
3. **Trie sin `finDePalabra`.** Devuelve `true` para cualquier prefijo, y el bug pasa todos los
   tests que solo prueban palabras completas.

**La conclusión operativa**, que es la razón de existir de este documento: en cuatro de las cinco
filas hay una versión de biblioteca que gana. La única donde de verdad hay que escribir código es
Union-Find, y **ningún lenguaje de los cinco lo trae**. Si tuvieras que memorizar una sola
implementación de este bloque, que sea esa.

---

## 📚 Para profundizar

- **Libro** — Sedgewick y Wayne, *Algorithms*, 4ª ed. (Addison-Wesley, 2011). Sus implementaciones en
  Java son la referencia de este documento; secciones 1.5 (Union-Find), 2.4 (heap) y 5.2 (tries).
- [Java 21 API — `PriorityQueue`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/PriorityQueue.html):
  para comparar tu implementación con la de la plataforma.
- [Python — `heapq`](https://docs.python.org/3/library/heapq.html): incluye `nlargest`, `nsmallest`
  y la explicación de por qué solo hay min-heap.
- [Go — `container/heap`](https://pkg.go.dev/container/heap): la interfaz de cinco métodos, con el
  ejemplo oficial de cola de prioridad con actualización.
- [Java 21 API — `TreeSet`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/TreeSet.html):
  `subSet`, `headSet` y `tailSet`, que son la alternativa de una línea al trie.
- [Python — `bisect`](https://docs.python.org/3/library/bisect.html): las recetas de búsqueda por
  rango sobre listas ordenadas.

---

**Siguiente:** [`02` — Lab de patrones en cinco lenguajes](02-lab-patrones-en-cinco-lenguajes.md) ·
**Relacionado:** [`04-arboles-grafos/02` — Montículos](../04-arboles-grafos/02-monticulos-y-colas-de-prioridad.md)
