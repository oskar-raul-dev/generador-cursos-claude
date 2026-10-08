# 02 — Comparadores y orden total

> El contrato que tu comparador tiene que cumplir para que `sort` no reviente, la excepción
> que aparece en producción y no en test —`Comparison method violates its general contract!`—,
> y por qué `compareTo` y `equals` deberían coincidir aunque el compilador no te obligue.
> Asume leído [`01` — Ordenación](01-ordenacion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un servicio ordena una lista de pedidos con un comparador escrito hace años. Funciona en test
con veinte elementos y funciona en producción durante meses. Un día, con una lista de 3 000
pedidos, lanza esto:

```text
java.lang.IllegalArgumentException: Comparison method violates its general contract!
```

No es un error de datos. Es TimSort detectando que **el comparador miente**: dice cosas
incompatibles entre sí, y el algoritmo, que se apoya en la coherencia para fusionar tramos,
descubre la contradicción y se niega a seguir.

El comparador culpable casi siempre es uno de estos dos:

```java
// Resta que desborda: con Integer.MIN_VALUE el signo sale al revés
(a, b) -> a.importe() - b.importe();

// Devuelve 0 cuando "son parecidos": rompe la transitividad
(a, b) -> Math.abs(a.peso() - b.peso()) < 0.01 ? 0 : Double.compare(a.peso(), b.peso());
```

Lo importante es que **el error no aparece con listas pequeñas**: con menos de 32 elementos
TimSort usa insertion sort, que no comprueba nada. El bug estaba ahí desde el principio y solo
se manifiesta cuando los datos crecen.

> **Regla de entrevista:** un comparador no es una función que "decide cuál va antes". Es una
> relación de orden total, y tiene tres propiedades que hay que poder nombrar.

---

## 2. 🧱 El contrato del orden total

**Qué es.** Un comparador define un orden total si cumple tres propiedades para cualesquiera
elementos del conjunto:

```text
Antisimetría:  signo(compare(a, b)) == -signo(compare(b, a))
Transitividad: si compare(a, b) > 0 y compare(b, c) > 0, entonces compare(a, c) > 0
Coherencia:    si compare(a, b) == 0, entonces signo(compare(a, c)) == signo(compare(b, c))
```

- La **antisimetría** se rompe con la resta que desborda: si `a - b` desborda, el signo de la
  comparación inversa no es el opuesto.
- La **transitividad** se rompe con el "son parecidos": si A y B son parecidos, y B y C son
  parecidos, A y C pueden no serlo, y entonces el comparador dice que A = B, B = C y A ≠ C.
- La **coherencia** exige que los elementos que el comparador considera iguales se comporten
  igual frente a todos los demás.

**Cuánto cuesta incumplirlo.** En Java, `IllegalArgumentException` desde Java 7 —cuando entró
TimSort— con listas de más de 32 elementos. En otros lenguajes, algo peor: **no falla**, y
simplemente devuelve una lista mal ordenada, sin ningún aviso.

**Cuándo sí** hace falta pensarlo: siempre que escribas un comparador con lógica, con varios
criterios o con tolerancia. Un `Integer.compare(a, b)` no tiene este riesgo.

**Cuándo no:** cuando delegas en comparadores de la biblioteca estándar, que ya lo cumplen.

> ⚠️ **Advertencia.** Que Java lance una excepción es lo **bueno** que le puede pasar a un
> comparador roto. Python, JavaScript y Go no comprueban nada: ordenan mal en silencio, y el
> bug se descubre cuando un usuario reporta que la lista está desordenada.

---

## 3. 🧱 `Comparable` contra `Comparator`

**`Comparable<T>`** define el **orden natural** del tipo: una sola forma de ordenarse, escrita
dentro de la clase. `Integer`, `String` y `LocalDate` lo implementan.

**`Comparator<T>`** define **un** orden, escrito fuera. Puedes tener tantos como criterios.

```java
// Orden natural: el "por defecto" del tipo, y debería haber solo uno obvio
public record PedidoId(long valor) implements Comparable<PedidoId> {
    @Override public int compareTo(PedidoId otro) { return Long.compare(valor, otro.valor); }
}

// Orden alternativo: uno por criterio de negocio
Comparator<Pedido> porFechaYLuegoImporte =
    Comparator.comparing(Pedido::fecha).thenComparing(Pedido::importe, reverseOrder());
```

- **`Comparator.comparing` con `thenComparing` es la forma correcta** de encadenar criterios en
  Java moderno. Escribirlo a mano con `if` anidados es donde nacen los incumplimientos del
  contrato.
- `Long.compare` en vez de la resta: **nunca desborda**. Es la corrección del primer bug de la
  sección 1 y cuesta lo mismo.
- Un tipo debería implementar `Comparable` solo si tiene un orden natural **obvio y único**. Un
  `Pedido` no lo tiene: ¿por fecha, por importe, por cliente? Si dudas, `Comparator`.

**Cuándo no** usar `Comparable`: cuando el orden depende del contexto o del usuario. Meterlo en
la clase convierte una decisión de presentación en una propiedad del dominio.

> **Veredicto:** `Comparable` para el orden intrínseco del valor —un identificador, una fecha,
> un dinero—; `Comparator` para todo orden que responda a una pregunta de negocio.

---

## 4. 🧱 La coherencia con `equals`

**El contrato recomendado.** `a.compareTo(b) == 0` debería implicar `a.equals(b)`, y al revés.
No es obligatorio, y romperlo tiene consecuencias concretas y sorprendentes.

**Qué pasa si no coinciden.** Las **colecciones ordenadas usan `compareTo`, no `equals`**:

```java
// BigDecimal: equals compara también la escala; compareTo, no
new BigDecimal("1.0").equals(new BigDecimal("1.00"));       // false
new BigDecimal("1.0").compareTo(new BigDecimal("1.00"));    // 0

Set<BigDecimal> hash = new HashSet<>();  hash.add(uno_cero); hash.add(uno_cero_cero);  // 2 elementos
Set<BigDecimal> tree = new TreeSet<>();  tree.add(uno_cero); tree.add(uno_cero_cero);  // ¡1 elemento!
```

- El mismo par de objetos, dos conjuntos con tamaños distintos. `HashSet` pregunta a `equals`;
  `TreeSet` pregunta a `compareTo`.
- `BigDecimal` es el ejemplo canónico y está documentado como incoherente a propósito, porque
  `1.0` y `1.00` tienen distinta precisión declarada y eso es información significativa.
- La consecuencia práctica: `TreeSet` y `TreeMap` **deduplican según tu comparador**. Un
  comparador que solo mira la fecha convierte un conjunto de pedidos en un conjunto de fechas.

**Cuándo romperlo a propósito:** cuando el orden es deliberadamente más grueso que la igualdad
y sabes que no vas a meter esos objetos en una colección ordenada. Se documenta, como hace
`BigDecimal`.

---

## 5. 🧱 Nulos, y el orden que no existe

Un comparador tiene que decidir qué hacer con `null`, y la respuesta por defecto es lanzar
`NullPointerException`. Las tres salidas, en orden de preferencia:

- **No permitir nulos en la colección.** Lo correcto casi siempre: si un pedido sin fecha no
  tiene sentido, el problema está aguas arriba.
- **`Comparator.nullsFirst(...)` o `nullsLast(...)`.** Envuelve otro comparador y decide dónde
  van los nulos. Es explícito y se lee.
- **Tratarlos dentro del comparador con `if`.** Funciona y es donde se rompe la transitividad si
  hay varios criterios.

```java
Comparator<Pedido> seguro =
    Comparator.comparing(Pedido::fechaEntrega, Comparator.nullsLast(Comparator.naturalOrder()));
```

- Fíjate en que el `nullsLast` envuelve el comparador **de la clave extraída**, no el del
  pedido: es la sobrecarga de `comparing` con dos argumentos, y es la que casi nadie recuerda.

> 💡 **Truco.** Si te preguntan cómo ordenarías dejando los nulos al final, la respuesta de una
> línea con `nullsLast` vale más que quince líneas de `if`. Y si la pregunta es cómo lo harías
> sin esa utilidad, la respuesta es que el caso nulo se comprueba **antes** que cualquier otro
> criterio, siempre, o la transitividad se cae.

---

## 6. ⏱️ La tabla de costes

| Decisión | Coste | Lo que la tabla no dice |
|---|---|---|
| `Integer.compare` vs resta | Idéntico | La resta desborda; `compare` no. Gratis |
| `comparing` + `thenComparing` | Una llamada indirecta por criterio | El JIT las incorpora; la diferencia no se mide en código normal |
| Comparador con cálculo dentro | O(coste) × **O(n log n) veces** | Se llama n log n veces: un cálculo caro ahí domina la ordenación |
| `Collator` para orden humano | 5–10× más lento que `compareTo` | Se usa igual: el orden correcto vale más que el tiempo |
| `TreeMap` con comparador | O(log n) por operación | El comparador se invoca log n veces por búsqueda |

> ⏱️ **Coste.** El error de rendimiento propio de este capítulo es meter trabajo dentro del
> comparador: una consulta, un `String.format`, una normalización Unicode. Se ejecuta n log n
> veces. La corrección es el patrón **decorar-ordenar-desdecorar**: calcula la clave una vez por
> elemento, ordena por la clave, y descarta. Es exactamente lo que hace el parámetro `key` de
> `sorted()` en Python, y la razón de que exista.

---

## 7. ⚖️ Los cinco lenguajes

| Lenguaje | Cómo se ordena por criterio | ¿Valida el contrato? | El detalle que muerde |
|---|---|---|---|
| **Java** | `Comparator.comparing(...).thenComparing(...)` | **Sí**, con más de 32 elementos | Lanza `IllegalArgumentException` en producción y no en test |
| **Python** | `sorted(lista, key=...)` | No | `key` calcula la clave **una vez por elemento**: evita el trabajo repetido por diseño |
| **JavaScript** | `sort((a, b) => ...)` | No | Sin comparador ordena como strings. Un comparador incoherente ordena mal en silencio |
| **TypeScript** | Igual que JS | No | El tipo del comparador no dice nada sobre su coherencia |
| **Go** | `slices.SortFunc` con `cmp.Compare` | No | Desde 1.21, `cmp.Ordered` y genéricos; antes, `sort.Slice` con `less` |

La diferencia de diseño más interesante es la de Python: **no pasas un comparador, pasas una
función que extrae la clave**. Eso hace imposible escribir un comparador incoherente por
accidente —la clave define el orden y el orden de las claves ya es total— y elimina el problema
del cálculo repetido. Python 2 tenía `cmp` y lo retiró en Python 3 por estos dos motivos.

---

## 8. 🧭 Cómo se elige

```text
¿El tipo tiene un orden natural único y obvio?     → Comparable
¿El orden responde a una pregunta de negocio?      → Comparator
¿Varios criterios?                                 → comparing().thenComparing(), nunca ifs
¿Puede haber nulos?                                → nullsFirst / nullsLast, o prohibirlos antes
¿Orden alfabético para un humano?                  → Collator con locale, no compareTo
¿El criterio cuesta calcularlo?                    → extrae la clave una vez (key / decorar)
¿Vas a meterlo en un TreeSet o TreeMap?            → compareTo DEBE coincidir con equals
```

> **Regla de entrevista:** si escribes un comparador con más de un `if`, di en voz alta que
> estás comprobando la transitividad. Es el tipo de comentario que cambia la percepción de
> cuidado, y además te obliga a comprobarla de verdad.

---

## 9. 🔭 Dónde aparece de verdad

En el `ORDER BY` con varias columnas, que es exactamente `thenComparing` escrito en SQL; en la
colación de una columna de base de datos, que decide si `"ñ"` va después de `"n"` o al final del
alfabeto y que **no** coincide con el orden natural de Java, lo que produce listados distintos
según quién ordene; en las colas de prioridad, donde el comparador decide qué se procesa antes y
un empate mal resuelto produce inanición; y en cualquier listado paginado, donde un orden no
total hace que un mismo registro aparezca en dos páginas o en ninguna, que es el bug de
paginación más difícil de diagnosticar.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`a - b` es un comparador válido" | Desborda con valores extremos y rompe la antisimetría. Usa `Integer.compare` |
| "Devuelvo 0 si son parecidos" | Rompe la transitividad: el orden deja de ser total |
| "El comparador funciona, lo probé" | Con menos de 32 elementos TimSort no valida nada |
| "`compareTo` y `equals` son independientes" | `TreeSet` deduplica por `compareTo`: si no coinciden, cambia el tamaño del conjunto |
| "Ordeno con `compareTo` y sale alfabético" | Sale por code point: `"Zoe"` antes que `"ángel"`. Para humanos, `Collator` |
| "Meto el cálculo en el comparador" | Se ejecuta n log n veces. Extrae la clave una vez |
| "En Go pongo `less` y ya" | `slices.Sort` no es estable; si el orden secundario importa, `SortStableFunc` |

---

## 📚 Para profundizar

- **Libro** — Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). **Ítem 14, "Consider
  implementing Comparable"**: es el capítulo de este tema, con el contrato completo, el problema
  del desbordamiento y la discusión de coherencia con `equals`. Si solo lees una cosa, esta.
- **Libro** — Bloch, *Effective Java*, 3ª ed. Ítems 10 y 11, sobre `equals` y `hashCode`, que
  son la otra mitad del mismo contrato y se aplican en
  [`04` — Hashing](04-hashing-y-tablas-hash.md).
- [Java 21 API — `Comparator`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Comparator.html):
  el contrato completo, `comparing`, `thenComparing`, `nullsFirst` y `reversed`.
- [Java 21 API — `Comparable`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Comparable.html):
  la recomendación explícita —"strongly recommended, but not required"— de que `compareTo`
  coincida con `equals`, con `BigDecimal` como contraejemplo declarado.
- [Python — Sorting HOW TO](https://docs.python.org/3/howto/sorting.html):
  por qué Python 3 eliminó `cmp` y dejó solo `key`, con el patrón decorar-ordenar-desdecorar.
- [Go — `slices`](https://pkg.go.dev/slices): `SortFunc`, `SortStableFunc` y `cmp.Compare`, con
  la advertencia de qué hace cada uno con los empates.
- [MDN — `Array.prototype.sort()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort):
  la conversión a string sin comparador y la garantía de estabilidad desde ES2019.
- **Tutorial** — Baeldung, «Java 8 Comparator.comparing»: los encadenamientos y las
  sobrecargas con extractor de clave, que es lo que peor se documenta.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué diferencia hay entre `Comparable` y `Comparator`? 🟢
2. ¿Cuáles son las tres propiedades de un orden total? 🟢
3. ¿Por qué `(a, b) -> a - b` es un comparador peligroso? 🟢
4. ¿Qué excepción lanza Java cuando un comparador incumple su contrato? 🟢
5. ¿Cómo encadenas dos criterios de ordenación en Java moderno? 🟢
6. ¿Por qué un comparador roto no falla en test con listas pequeñas? 🟡
7. ¿Qué pasa si `compareTo` devuelve 0 para objetos que `equals` considera distintos? 🟡
8. ¿Por qué `new BigDecimal("1.0")` y `new BigDecimal("1.00")` dan tamaños distintos en un
   `HashSet` y en un `TreeSet`? 🟡
9. ¿Qué hace `Comparator.nullsLast` y qué envuelve exactamente? 🟡
10. ¿Por qué meter un cálculo dentro del comparador es un problema de rendimiento? 🟡
11. ¿Cuándo un tipo debería implementar `Comparable` y cuándo no? 🟡
12. ¿Por qué Python 3 eliminó el parámetro `cmp` y dejó solo `key`? 🟡
13. ¿Qué es el patrón decorar-ordenar-desdecorar y qué problema resuelve? 🟠
14. Un comparador devuelve 0 cuando dos pesos difieren en menos de 0.01. ¿Qué propiedad rompe
    y con qué ejemplo concreto? 🟠
15. ¿Por qué `TreeSet` puede "perder" elementos que `HashSet` conserva? 🟠
16. Ordenas por fecha y dentro de cada fecha por importe descendente. Escribe el comparador y
    di qué pasa si el `sort` no es estable. 🟠
17. ¿Por qué el orden de una columna de base de datos puede no coincidir con el de tu
    comparador Java, y qué consecuencias tiene? 🟠
18. ¿Qué diferencia hay entre `slices.Sort` y `slices.SortStableFunc` en Go, y cuándo importa? 🟠
19. Un listado paginado muestra el mismo registro en dos páginas. ¿Qué hipótesis tienes? 🟠
20. Te dan un comparador con cuatro `if` anidados que "funciona". ¿Cómo compruebas que cumple
    el contrato sin leerlo entero? 🔴
21. Diseña el comparador de una cola de prioridad de tareas con prioridad, fecha de creación y
    desempate estable, y explica cómo evitas la inanición. 🔴
22. Producción lanza `Comparison method violates its general contract!` con 3 000 elementos y
    nunca con 20. Da tu diagnóstico completo y la corrección. 🔴

---

**Anterior:** [`01` — Ordenación](01-ordenacion.md) ·
**Siguiente:** [`03` — Búsqueda](03-busqueda.md) ·
**Relacionado:** [`04` — Hashing y tablas hash](04-hashing-y-tablas-hash.md)
