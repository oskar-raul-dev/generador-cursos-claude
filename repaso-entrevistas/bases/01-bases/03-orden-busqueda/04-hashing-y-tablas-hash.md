# 04 — Hashing y tablas hash

> El contrato `equals`/`hashCode` y qué se rompe exactamente al incumplirlo, encadenamiento
> contra direccionamiento abierto, el factor de carga y por qué es 0.75, la treeification del
> `HashMap` de Java 8, y las dos estructuras que se derivan y se preguntan: hashing consistente
> y filtro de Bloom.
> Asume leídos [`01-fundamentos/02` — TDAs](../01-fundamentos/02-tdas-contrato-e-implementacion.md)
> y [`02` — Comparadores](02-comparadores-y-orden-total.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tres incidentes reales que nacen del mismo capítulo.

**Uno.** Alguien añade un campo a una clase de dominio y sobrescribe `equals` para incluirlo,
pero no `hashCode`. A partir de ahí, `mapa.get(clave)` devuelve `null` para una clave que
**está** dentro del mapa. El objeto existe, es igual al que buscas, y es inalcanzable.

**Dos.** Un `HashMap` con 50 000 claves cuyo `hashCode` está mal distribuido —por ejemplo,
devuelve el mismo valor para muchos objetos— tarda segundos en cada búsqueda. La estructura que
prometía O(1) se convirtió en una lista enlazada.

**Tres.** Un objeto mutable se usa como clave, alguien modifica uno de sus campos, y ese objeto
deja de encontrarse en el conjunto donde está. No se puede recuperar ni borrar: queda como
basura ocupando memoria hasta que el mapa muere.

Los tres son el mismo error de fondo: **la tabla hash confía en un contrato que el compilador no
verifica**, y cuando se incumple no falla ruidosamente, sino que devuelve respuestas
incorrectas.

> **Regla de entrevista:** siempre que digas "uso un `HashMap`", el entrevistador puede
> preguntar por el contrato. La respuesta completa es: objetos iguales tienen que dar el mismo
> hash, y la clave tiene que ser **inmutable** en los campos que participan en el hash.

---

## 2. 🧱 Qué es una tabla hash

**Qué es.** Un arreglo de *buckets* más una función que convierte la clave en un índice de ese
arreglo. Buscar es calcular el índice y mirar ahí.

```text
clave "abracadabra" → hashCode() → -1234567 → índice = hash & (capacidad - 1) → bucket 5
```

- La función hash **no** determina la posición por sí sola: se combina con la capacidad. Java
  usa `hash & (n-1)`, que solo funciona porque la capacidad es siempre una potencia de dos —y
  es más rápido que el módulo—.
- Java además aplica un paso de mezcla (`h ^ (h >>> 16)`) para que los bits altos influyan,
  porque `& (n-1)` solo mira los bits bajos. Sin esa mezcla, dos claves que difieren solo en los
  bits altos colisionarían siempre.

**Cuánto.** O(1) amortizado para buscar, insertar y borrar, **con buena función hash**. O(n) en
el peor caso, o O(log n) en Java 8+ si las claves son comparables.

**Cuándo sí.** Pertenencia y acceso por clave exacta. Es la estructura por defecto correcta.

**Cuándo no.** Cuando necesitas orden, rangos o vecinos: el hash destruye el orden por diseño.
Eso es un árbol, y está en [`04-arboles-grafos/01`](../04-arboles-grafos/01-arboles.md).

> **Veredicto:** la tabla hash cambia orden por velocidad. Si nunca preguntas "¿qué hay entre A
> y B?", es la elección correcta; si lo preguntas alguna vez, el hash te obliga a recorrerlo
> todo.

---

## 3. 🧱 El contrato `equals` / `hashCode`

**El contrato**, en tres reglas:

```text
1. Si a.equals(b) → a.hashCode() == b.hashCode()      OBLIGATORIO
2. Si a.hashCode() == b.hashCode() → a.equals(b)?     NO necesariamente (es una colisión)
3. hashCode() debe ser estable mientras el objeto esté en la colección
```

- **La regla 1 es la que se rompe** y la que produce el incidente uno: sobrescribir `equals` sin
  `hashCode`. El objeto va al bucket del hash heredado de `Object` —que depende de la identidad—
  y al buscar con otro objeto igual se calcula un bucket distinto.
- **La regla 2 al revés no aplica**: dos objetos distintos pueden compartir hash, y eso es
  normal. Por eso el bucket se recorre comparando con `equals`.
- **La regla 3 es la del incidente tres**: mutar un campo que participa en el hash con el objeto
  ya dentro de un `HashSet` lo deja inalcanzable.

**La consecuencia práctica más citada:** usa como clave tipos **inmutables**. `String`,
`Integer`, `LocalDate`, un `record` sin campos mutables. Si tu clave es una entidad con
identidad, la clave correcta es su identificador, no la entidad.

```java
// record: equals y hashCode generados y coherentes, y el tipo es inmutable
public record ProductoId(long valor) { }
Map<ProductoId, Money> precios = new HashMap<>();
```

- Los `record` de Java 16+ generan `equals`, `hashCode` y `toString` coherentes entre sí. Es la
  razón práctica más fuerte para usarlos como claves y como objetos de valor.
- Un buen `hashCode` **distribuye**: `Objects.hash(campo1, campo2)` es suficiente para casi todo.
  Devolver una constante es técnicamente válido y convierte el mapa en una lista.

> ⚠️ **Advertencia.** El error más caro es sutil: en JPA, una entidad cuyo `hashCode` usa el
> `id` generado por la base cambia de hash cuando se persiste, porque antes el `id` era `null`.
> Si la metiste en un `HashSet` antes de guardar, después del `flush` ya no está donde debería.
> Es la razón por la que se recomienda basar `equals`/`hashCode` en una clave de negocio o en un
> UUID asignado en el constructor.

---

## 4. 🧱 Colisiones: encadenamiento y direccionamiento abierto

Dos claves distintas pueden caer en el mismo bucket. Hay dos familias de solución y cada
lenguaje elige una.

**Encadenamiento (separate chaining).** Cada bucket guarda una lista de entradas. Java lo usa.

- Sencillo, tolera factores de carga altos, y borrar es trivial.
- Cuesta un objeto de nodo por entrada y perjudica la localidad de caché.

**Direccionamiento abierto (open addressing).** Todo vive en el propio arreglo: si el bucket está
ocupado, se prueba otro según una secuencia (lineal, cuadrática, doble hash). Python y Go lo
usan.

- Mucha mejor localidad de caché: los sondeos leen posiciones contiguas.
- Se degrada mal con factores de carga altos, y **borrar es complicado**: hay que dejar una
  marca de borrado, o la cadena de sondeo se rompe y los elementos siguientes se vuelven
  inalcanzables.

> 📝 **Contexto.** Desde **Java 8**, un bucket con más de 8 entradas y capacidad suficiente se
> convierte en un **árbol rojo-negro**, lo que baja el peor caso de O(n) a O(log n). No se hizo
> por rendimiento general sino por **seguridad**: era la defensa contra los ataques de
> inundación de hash, donde un atacante envía miles de claves que colisionan a propósito para
> convertir cada búsqueda en un recorrido lineal. Requiere que las claves sean `Comparable`; si
> no lo son, el bucket sigue siendo una lista.

---

## 5. 🧱 Factor de carga y redimensionado

**Qué es.** El factor de carga es `elementos / capacidad`. Cuando lo supera, la tabla duplica su
capacidad y **rehashea** todo.

**Por qué 0.75 en Java.** Es el punto de equilibrio empírico entre dos costes opuestos: por
debajo se desperdicia memoria, por encima las colisiones crecen rápido —según la paradoja del
cumpleaños, mucho antes de lo que la intuición sugiere—.

```text
capacidad 16, factor 0.75 → redimensiona al insertar el elemento 13
capacidad 32, factor 0.75 → redimensiona al insertar el elemento 25
```

- El redimensionado es **O(n)**: recalcula la posición de cada entrada. De ahí el "amortizado"
  del O(1).
- Con un mapa grande, esa inserción concreta **sí** tarda, y es el problema de p99 de
  [`01-fundamentos/01` §6](../01-fundamentos/01-complejidad-y-o-grande.md#6--coste-amortizado).
- Preasignar la capacidad lo elimina: `new HashMap<>(esperados / 0.75 + 1)`. La división por el
  factor es el detalle que casi todo el mundo olvida, y sin ella el mapa redimensiona igual.

**Cuánto cuesta cada valor de factor:** con 0.5 la tabla ocupa el doble y colisiona muy poco;
con 0.9 ahorra memoria y las cadenas se alargan. Python usa 2/3 y Go alrededor de 6.5 entradas
por bucket, porque su diseño de buckets es distinto.

---

## 6. 🧱 Dos derivados que se preguntan

**Hashing consistente.** El problema: con `hash % N` servidores, añadir o quitar uno remapea
**casi todas** las claves, y un caché distribuido se invalida entero.

- La solución es colocar servidores y claves en un anillo de 0 a 2³²; cada clave va al servidor
  siguiente en el anillo. Al añadir un servidor, solo se remapea la porción que le corresponde:
  **K/N claves en vez de todas**.
- Los *nodos virtuales* —cada servidor colocado en varios puntos del anillo— corrigen el reparto
  desigual que se produce con pocos servidores.
- Dónde aparece: el particionado de Cassandra y DynamoDB, el reparto de un clúster de
  Memcached, el balanceo con afinidad de sesión.

**Filtro de Bloom.** Una estructura probabilística que responde "¿puede estar?" con muy poca
memoria.

- Varias funciones hash marcan bits en un arreglo. Si algún bit está a 0, el elemento
  **seguro que no está**; si todos están a 1, **probablemente sí**.
- **Falsos positivos sí, falsos negativos no.** Esa asimetría es lo que lo hace útil y lo que
  hay que poder enunciar.
- No permite borrar (hay variantes con contadores) ni recuperar los elementos.
- Dónde aparece: antes de consultar el disco en un LSM-tree (Cassandra, HBase, RocksDB), en
  listas de URL maliciosas, en deduplicación aproximada de flujos.

> 💡 **Truco.** "¿Cómo compruebas si una URL está entre diez mil millones sin guardarlas?" es
> una pregunta de diseño cuya respuesta es "filtro de Bloom, y acepto falsos positivos porque el
> paso siguiente los descarta". Nombrarlo con esa condición explícita es lo que puntúa.

---

## 7. ⏱️ La tabla de costes

| Operación | Medio | Peor | Espacio | Lo que la tabla no dice |
|---|---|---|---|---|
| `get` / `put` / `remove` | O(1) | O(n), u **O(log n)** en Java 8+ | O(n) | El "medio" depende por completo de tu `hashCode` |
| Redimensionado | O(n), amortizado a O(1) | O(n) en esa inserción | Pico de 2× | Rompe el p99. Se evita preasignando |
| Recorrer | O(capacidad) | O(capacidad) | — | Recorre **buckets vacíos** también: un mapa poco lleno es lento de iterar |
| Hashing consistente | O(log servidores) | O(log servidores) | O(servidores × réplicas) | Remapea K/N claves al cambiar el clúster, no todas |
| Filtro de Bloom | O(k) funciones hash | O(k) | **Bits, no objetos** | 10 bits por elemento dan ~1 % de falsos positivos |

---

## 8. ⚖️ Los cinco lenguajes

| Lenguaje | Resolución de colisiones | Orden de iteración | El detalle que muerde |
|---|---|---|---|
| **Java** | Encadenamiento, con árbol desde 8 entradas | No garantizado | El contrato `equals`/`hashCode` es responsabilidad tuya y nada lo verifica |
| **Python** | Direccionamiento abierto | **Orden de inserción**, garantizado desde 3.7 | El hash de `str` se aleatoriza por proceso (`PYTHONHASHSEED`) contra ataques |
| **JavaScript** | Depende del motor | **Orden de inserción** en `Map` | Las claves de un objeto plano se convierten a string; `Map` admite cualquier valor |
| **TypeScript** | Igual que JS | Igual que JS | `Map<K,V>` tipado; el tipo no garantiza que `K` sea una clave sensata |
| **Go** | Direccionamiento abierto por buckets de 8 | **Aleatorio a propósito** | Las claves deben ser comparables con `==`: un slice no puede ser clave, y no compila |

Dos diseños que merecen la comparación:

- **Go lo verifica en compilación.** Un tipo no comparable —slice, mapa, función— no puede ser
  clave, y el compilador lo rechaza. Java acepta cualquier objeto y te deja descubrir en
  ejecución que su `hashCode` era el heredado.
- **Python aleatoriza el hash de los strings** en cada proceso, precisamente para que nadie
  pueda precalcular colisiones y montar un ataque de inundación. Java eligió la treeification en
  vez de la aleatorización: dos defensas distintas contra la misma amenaza.

---

## 9. 🧭 Cómo se elige

```text
¿Acceso por clave exacta, sin orden?              → HashMap
¿Necesitas orden de inserción, o LRU?             → LinkedHashMap
¿Necesitas orden por clave, rangos, vecinos?      → TreeMap
¿Escrituras concurrentes?                         → ConcurrentHashMap, no HashMap sincronizado

¿La clave es mutable?                             → NO es una clave. Usa su identificador
¿Sabes cuántas entradas habrá?                    → preasigna: new HashMap<>(n / 0.75 + 1)
¿Repartes claves entre N servidores?              → hashing consistente, no hash % N
¿Solo "¿puede estar?" con memoria mínima?         → filtro de Bloom, asumiendo falsos positivos
```

> **Regla de entrevista:** "uso un `HashMap`" es una respuesta incompleta. La completa añade
> **cuál es la clave y por qué es inmutable**. Esa segunda frase es la que demuestra que
> entiendes el contrato y no solo la estructura.

---

## 10. 🔭 Dónde aparece de verdad

En el *hash join* del optimizador de una base de datos, que construye una tabla hash con la
relación pequeña y sondea con la grande; en el particionado por clave de Kafka, donde el mismo
`key` va siempre a la misma partición y por eso el orden se garantiza por clave y no
globalmente; en el filtro de Bloom que Cassandra consulta antes de tocar disco; en el reparto de
un caché distribuido con hashing consistente; y en la deduplicación de eventos por
identificador, que es una tabla hash con expiración y es la implementación práctica de la
idempotencia.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El `HashMap` es O(1)" | Amortizado y **con buen `hashCode`**. Degenerado es O(n), o O(log n) desde Java 8 |
| "Sobrescribo `equals` y ya" | Sin `hashCode` coherente, el objeto se vuelve inalcanzable en el mapa |
| "Uso la entidad como clave" | Si es mutable, mutarla la pierde dentro del conjunto. Usa el identificador |
| "`new HashMap<>(1000)` para 1000 entradas" | Redimensiona igual: hay que dividir por el factor de carga |
| "Dos objetos con el mismo hash son iguales" | Es una colisión, y es normal. La igualdad la decide `equals` |
| "Reparto con `hash % N` servidores" | Al cambiar N se remapea casi todo. Hashing consistente remapea K/N |
| "El filtro de Bloom puede fallar en los dos sentidos" | Falsos positivos sí; falsos negativos **nunca** |

---

## 📚 Para profundizar

- **Libro** — Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). **Ítems 10 y 11**:
  `equals` y `hashCode`, con los cinco requisitos del contrato y los contraejemplos. Si solo
  lees una cosa de este capítulo, esta.
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4ª ed. (Addison-Wesley, 2011). Capítulo 3.4:
  encadenamiento y direccionamiento abierto con el análisis del factor de carga medido.
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT
  Press, 2022). Capítulo 11, con el análisis probabilístico y el hashing universal.
- [Java 21 API — `HashMap`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/HashMap.html):
  el factor de carga por defecto, la nota sobre la treeification y la advertencia sobre claves
  mutables.
- [Java 21 API — `Objects`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Objects.html):
  `Objects.hash` y `Objects.equals`, que son la forma correcta de escribir ambos métodos.
- [Python — `stdtypes`](https://docs.python.org/3/library/stdtypes.html): el requisito de
  hashabilidad, por qué las listas no son claves y qué significa que un tipo sea hashable.
- [The Go Blog — Go maps in action](https://go.dev/blog/maps): la restricción de tipos
  comparables como clave y el recorrido deliberadamente aleatorio.
- **Video** — MIT OpenCourseWare, *Introduction to Algorithms* (6.006), las clases de hashing:
  la resolución de colisiones y el hashing universal con la demostración.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Cuál es el contrato entre `equals` y `hashCode`? 🟢
2. ¿Qué pasa si sobrescribes `equals` y no `hashCode`? 🟢
3. ¿Qué es el factor de carga y cuál es el de Java por defecto? 🟢
4. ¿Qué es una colisión y por qué es normal? 🟢
5. ¿Por qué `HashMap` no garantiza orden de iteración? 🟢
6. ¿En qué se diferencian encadenamiento y direccionamiento abierto? 🟡
7. ¿Por qué borrar es más complicado en direccionamiento abierto? 🟡
8. ¿Qué pasa si mutas un objeto que ya es clave de un `HashSet`? 🟡
9. ¿Por qué el factor de carga por defecto es 0.75 y no 0.9? 🟡
10. ¿Qué hace Java 8 cuando un bucket acumula más de ocho entradas, y por qué? 🟡
11. ¿Por qué la capacidad de un `HashMap` es siempre una potencia de dos? 🟡
12. ¿Qué garantiza y qué no garantiza un filtro de Bloom? 🟡
13. ¿Por qué `new HashMap<>(1000)` no evita el redimensionado si vas a meter 1000 entradas? 🟠
14. ¿Por qué recorrer un `HashMap` poco lleno puede ser más lento de lo esperado? 🟠
15. ¿Qué es un ataque de inundación de hash y cómo se defienden Java y Python, cada uno a su
    manera? 🟠
16. ¿Por qué usar una entidad JPA como clave de un `HashSet` es peligroso? 🟠
17. ¿Qué problema resuelve el hashing consistente que `hash % N` no resuelve? 🟠
18. ¿Por qué Go no deja usar un slice como clave de un mapa, y qué ventaja tiene esa
    restricción? 🟠
19. ¿Cuándo prefieres un `TreeMap` a un `HashMap` aunque sea O(log n)? 🟠
20. ¿Por qué un `record` es una buena clave de mapa? 🟠
21. Te dan diez mil millones de URLs y 2 GB de memoria: ¿cómo compruebas si una está? 🔴
22. Un `mapa.get(clave)` devuelve `null` para una clave que está en el mapa. Da tres hipótesis
    en orden de probabilidad. 🔴
23. Un endpoint se degrada a segundos por petición cuando recibe un JSON con 50 000 campos.
    Explica el mecanismo y la defensa. 🔴
24. Diseña la deduplicación de eventos por identificador para un flujo de 100 000 eventos por
    segundo, con ventana de 24 horas. 🔴
25. Diseña el reparto de un caché de 12 nodos de forma que añadir un nodo no invalide todo.
    Explica el mecanismo y qué pasa con el reparto desigual. 🔴

---

**Anterior:** [`03` — Búsqueda](03-busqueda.md) ·
**Siguiente:** [`05` — Intervalos y barrido de eventos](05-intervalos-y-barrido.md) ·
**Relacionado:** [`01-fundamentos/02` — TDAs](../01-fundamentos/02-tdas-contrato-e-implementacion.md)
