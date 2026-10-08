# 01 — JSON

> El formato por defecto de casi todo, y el que más datos corrompe en silencio. Qué tipos tiene de
> verdad —que son seis y ninguno es una fecha—, por qué un identificador largo llega cambiado a
> JavaScript, cuánta memoria cuesta parsearlo de las dos formas posibles, y qué hace cada lenguaje
> con un campo que no esperaba.
>
> **Asume leído:** [`01-fundamentos/01` — Complejidad](../01-fundamentos/01-complejidad-y-o-grande.md)
> y [`06/01` — Números, precisión y dinero](../06-numeros-tiempo-concurrencia/01-numeros-precision-y-dinero.md).
>
> **Vigencia:** 2026-09-18. Todas las salidas de este capítulo están **ejecutadas**.

---

## 1. 🎯 El problema

Un servicio Java publica pedidos con identificador numérico. El front en TypeScript los consume. Un
día, un pedido deja de encontrarse en la base de datos:

```text
lo que envía el backend   {"id": 9007199254740993}
lo que recibe el front     9007199254740992
```

Nadie lanzó una excepción. No hubo error de red, ni de parseo, ni un `try/catch` que saltara. El
número simplemente **llegó distinto**, y todo lo que se construyó encima —la consulta, el enlace, el
informe— apuntó al pedido equivocado.

Verificado en los cinco lenguajes del corpus, con el mismo documento de entrada:

```text
Java + Jackson (a Map)          9007199254740993   Long        ✅
Python  json.load               9007199254740993   int         ✅
JavaScript  JSON.parse          9007199254740992   number      ❌
TypeScript                      igual que JavaScript           ❌
Go  encoding/json → interface{} 9.007199254740992e+15 float64  ❌
Go  con dec.UseNumber()         9007199254740993   json.Number ✅
```

**El formato no tiene la culpa: la norma no limita la precisión.** La tienen las decisiones de cada
biblioteca al elegir en qué tipo nativo cae un número, y eso es lo que hay que saber antes de
diseñar un contrato.

---

## 2. 🧱 Qué tiene JSON, y sobre todo qué no tiene

**Qué es.** Un formato de texto con **seis tipos** y nada más:

```text
object   {"clave": valor}      string   "texto"
array    [1, 2, 3]             number   42  ·  3.14  ·  -1e10
                               boolean  true / false
                               null
```

**Cómo va.** Esa lista tan corta es toda la gramática: se lee entera en una página, y por eso hay
parser de JSON en cualquier lenguaje que exista. Está definido dos veces —
[RFC 8259](https://www.rfc-editor.org/rfc/rfc8259) y ECMA-404— y las dos definiciones son
compatibles a propósito.

**Lo que no existe, y es la causa de la mitad de los bugs:**

| No existe | Lo que se hace en su lugar | Qué se rompe |
|---|---|---|
| **Fecha** | Texto ISO-8601: `"2026-09-18T14:30:00Z"` | Cada biblioteca parsea distinto; las zonas se pierden |
| **Entero frente a decimal** | Un solo tipo `number` | El `id` de la sección 1 |
| **Decimal exacto** | `number`, que casi todos leen como `double` | El dinero, y ya sabes de [`06/01`](../06-numeros-tiempo-concurrencia/01-numeros-precision-y-dinero.md) qué pasa |
| **Binario** | Base64 en un `string`, con su +33 % | Memoria, no ancho de banda |
| **Comentarios** | Nada. Por diseño | Por eso los archivos de configuración migraron a YAML |
| **Referencias entre nodos** | Nada: el documento es un árbol | Los grafos hay que aplanarlos con identificadores |

- **La ausencia de comentarios fue deliberada**: su autor los quitó porque la gente los usaba para
  meter directivas de parseo, y eso convierte un formato de datos en un lenguaje.
- **Las claves son siempre texto.** Un mapa con claves enteras no sobrevive el viaje de ida y vuelta:
  salen convertidas a `"1"`, `"2"`.
- **El orden de las claves no significa nada** y la norma no lo garantiza, aunque casi todas las
  bibliotecas lo conserven. Firmar un JSON tal cual, sin canonicalizar, es una trampa conocida.

**Cuánto cuesta.** Parseo lineal en el tamaño del documento, `O(n)` en tiempo. En memoria depende de
cómo se parsee, y esa es la sección 4.

**Cuándo sí.** Prácticamente siempre que haya una API sobre HTTP, y siempre que el consumidor sea
heterogéneo o desconocido.

**Cuándo no.** Cuando el volumen por llamada domina —ahí gana un binario con esquema—, cuando hace
falta precisión decimal garantizada sin acuerdo previo, y cuando el documento es un archivo de
configuración escrito a mano, porque no admite comentarios.

> **Veredicto:** JSON gana por ubicuidad, no por expresividad. Todo lo que tu dominio necesite y no
> esté en esos seis tipos —fechas, dinero, binarios— es un **acuerdo entre las dos partes**, y si no
> está escrito en el contrato, no existe.

---

## 3. 🔢 Los números, que es donde se pierde dinero

**Qué es.** JSON tiene un solo tipo numérico y **no dice cuántos dígitos hay que soportar**. RFC 8259
lo deja explícito: la interoperabilidad se consigue quedándose dentro de lo que un `double` IEEE 754
representa exactamente, es decir, hasta `2^53 - 1` = `9007199254740991`.

**Cómo va.** Ese número tiene nombre en JavaScript: `Number.MAX_SAFE_INTEGER`. A partir de ahí, los
enteros dejan de ser representables uno a uno y el parser redondea al `double` más cercano — **sin
avisar**, porque desde su punto de vista no ha pasado nada raro.

```javascript
// El identificador entra con un dígito y sale con otro
JSON.parse('{"id": 9007199254740993}').id   // 9007199254740992
```

- El problema no aparece en pruebas: los identificadores pequeños funcionan perfectamente. Aparece
  cuando la tabla crece, o cuando alguien usa una marca de tiempo en nanosegundos, o un identificador
  de Twitter, o un número de cuenta largo.
- **Java y Python aciertan por motivos distintos**: Jackson elige el tipo más pequeño que quepa y
  sube a `Long` o `BigInteger`; Python tiene enteros de precisión arbitraria y no tiene que elegir.
- **Go falla por una decisión de diseño, no por un descuido**: al deserializar en `interface{}` todo
  número cae en `float64`. La solución está en la propia biblioteca y hay que pedirla:

```go
dec := json.NewDecoder(r)
dec.UseNumber()          // el número se conserva como texto hasta que tú decidas el tipo
```

**Cuánto.** No cuesta nada en tiempo; cuesta un dígito, que es lo más caro que hay.

**Cuándo sí** mandar un número: cuando de verdad vas a hacer aritmética con él.

**Cuándo no:** los identificadores. Un `id` no se suma, no se promedia y no se ordena
aritméticamente — es una **etiqueta**.

> **Veredicto:** los identificadores viajan como **cadena**, siempre. Cuesta dos comillas y elimina
> de raíz una clase entera de corrupción silenciosa que ninguna prueba unitaria va a encontrar. Y el
> dinero, o cadena o entero de céntimos, por lo que ya sabes de [`06/01`](../06-numeros-tiempo-concurrencia/01-numeros-precision-y-dinero.md).

---

## 4. 🧱 Árbol frente a flujo: los dos modos de parsear

**Qué es.** Hay exactamente dos formas de leer un documento estructurado, y la elección es de
memoria:

```text
ÁRBOL (DOM)     se construye el documento entero en memoria y luego se navega
FLUJO (streaming) se emite un token cada vez; el programa decide qué guarda
```

**Cómo va.** El árbol es cómodo: `raiz.get("pedidos").get(0).get("total")`. El flujo es un bucle que
recibe eventos —*empieza objeto*, *nombre de campo*, *valor*— y no retrocede.

**Cuánto.** Medido de verdad, con un archivo de **30 MB** y 400 000 objetos, sumando un campo:

```text
                        memoria residente máxima
Java, línea base de la JVM          42 MB
Java, árbol (readTree)             323 MB     ← ~9 veces el tamaño del archivo
Java, flujo (JsonParser)            99 MB     ← 57 MB sobre la línea base
Python, línea base                  14 MB
Python, json.load                  225 MB     ← ~7 veces el archivo
```

- **La regla práctica que sale de ahí: un árbol cuesta entre cinco y diez veces el tamaño del
  archivo.** No es un defecto de Jackson ni de Python: un objeto con tres claves ocupa mucho más como
  estructura de datos que como texto, entre cabeceras de objeto, punteros y cadenas.
- Por eso un servicio que va bien con documentos de 1 MB se cae con uno de 100 MB, y por eso el
  límite de tamaño de petición es una defensa de memoria antes que de ancho de banda.

**Cuándo sí** el árbol: documentos pequeños y acotados, o cuando necesitas mirar el documento
completo para decidir algo. Es más corto de escribir y más fácil de leer.

**Cuándo no:** exportaciones, importaciones, cualquier cosa que venga de fuera sin límite declarado.
Ahí el flujo no es una optimización, es lo único que no se cae.

> **Veredicto:** árbol por defecto, flujo en cuanto el documento pueda crecer sin que tú lo
> controles. Y el número que hay que llevar a una entrevista: **el árbol multiplica por unas ocho**.

---

## 5. 🧱 El lector tolerante, y lo que hace cada lenguaje

**Qué es.** Llega un campo que tu modelo no conoce, porque el otro equipo desplegó antes. ¿Error o se
ignora? La respuesta **no la da JSON**: la da tu biblioteca, y la da distinta en cada lenguaje.

**Cómo va.** El mismo documento `{"a":1,"desconocido":9}` contra un tipo que solo declara `a`:

```text
Go     encoding/json   lo ignora en silencio          → {A:1}, err = nil
Java   Jackson         UnrecognizedPropertyException  → falla el despliegue
Python dict            no hay tipo que incumplir      → entra todo
```

- **Ese contraste es el corazón del *tolerant reader*:** un consumidor que ignora lo que no entiende
  permite que el productor evolucione sin coordinar despliegues; uno que falla convierte cada campo
  nuevo en una incidencia.
- En Java se desactiva por configuración —`FAIL_ON_UNKNOWN_PROPERTIES` a `false`— y es de las
  primeras decisiones de un contrato entre servicios. **Pero no siempre es la correcta**: en un
  mensaje financiero, ignorar un campo que no entiendes puede ser exactamente lo que no debes hacer.
- **Las claves duplicadas** son el caso hermano: `{"a":1,"a":2}` da `2` en los tres lenguajes
  probados, pero la norma solo dice que las claves *SHOULD* ser únicas y **no define qué hacer si no
  lo son**. Distintos parsers en la misma cadena de proxies pueden quedarse con valores distintos, y
  ahí hay una vulnerabilidad conocida.

**El caso de TypeScript**, que es donde el tipo cambia la respuesta:

```typescript
interface Pedido { id: string; total: number; }
const p = JSON.parse('{"id": 42, "total": "cien"}') as Pedido;
```

```text
tsc --strict --noEmit   →  compila sin un solo error
en ejecución            →  id -> 42 number  ·  total -> "cien" string
                           p.total.toFixed  →  undefined
```

- `JSON.parse` devuelve `any`, así que **el `as` no comprueba nada**: es una promesa del programador,
  no del compilador. TypeScript no valida datos que no ha visto compilar.
- Lo que cierra el agujero es un validador en tiempo de ejecución —Zod, io-ts, un esquema— en la
  frontera del sistema. **El tipo estático protege tu código; el validador protege tus datos.**

> **Veredicto:** decide y escribe en el contrato qué pasa con lo desconocido. Tolerante hacia dentro
> por defecto, estricto donde el dato sea irreversible — y en TypeScript, un validador en el borde,
> porque ahí el compilador no llega.

---

## 6. ⏱️ La tabla de costes

| Operación | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| Parsear a árbol | `O(n)` | **≈ 8 × el archivo** | Se mide en el perfilador, no en el reloj |
| Parsear en flujo | `O(n)` | `O(1)` por token | Código más largo y sin marcha atrás |
| Serializar | `O(n)` | `O(n)` | Escapar cadenas es lo caro, no el recorrido |
| Buscar una clave en el árbol | `O(1)` por nivel | — | Ya pagaste el árbol entero para llegar |
| Validar contra JSON Schema | `O(n)` × reglas | `O(n)` | Puede costar más que el parseo |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "JSON tiene enteros" | Tiene `number`. Lo que haga tu biblioteca con él es cosa suya |
| "Un `id` numérico es más eficiente" | Y llega cambiado a JavaScript pasados los 2^53. Va como cadena |
| "JSON tiene fechas" | Tiene texto. La fecha es un acuerdo entre las partes |
| "Parsear es barato" | En tiempo sí; en memoria un árbol cuesta unas ocho veces el archivo |
| "Si no lanza excepción, el dato llegó bien" | La corrupción numérica es silenciosa por definición |
| "El `as Pedido` de TypeScript valida" | No valida nada: `JSON.parse` devuelve `any` |
| "Las claves duplicadas dan error" | La norma no lo define; en la práctica gana la última |
| "El orden de las claves se mantiene" | No está garantizado. Firmar sin canonicalizar es un fallo |

---

## 📚 Para profundizar

- **Norma** — [RFC 8259 — *The JavaScript Object Notation (JSON) Data Interchange Format*](https://www.rfc-editor.org/rfc/rfc8259):
  seis páginas, se lee entero, y la sección 6 es la que avisa de los `2^53`.
- **Referencia** — [json.org](https://www.json.org/json-es.html): la gramática completa en
  diagramas, en español. Útil para escribir un parser a mano.
- **Referencia** — [MDN — `JSON.parse`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse):
  incluye el argumento *reviver*, que es la salida para los números grandes en JavaScript.
- **Biblioteca** — [Jackson — documentación](https://github.com/FasterXML/jackson-docs): la
  referencia de Java, con la lista de `DeserializationFeature` que decide el comportamiento tolerante.
- **Biblioteca** — [Go — `encoding/json`](https://pkg.go.dev/encoding/json): la sección de
  *Unmarshal* explica por qué todo número cae en `float64` sin `UseNumber`.
- **Biblioteca** — [Python — `json`](https://docs.python.org/3/library/json.html): y su
  `parse_float`, que es como se fuerza `Decimal` en dinero.
- **Contrato** — [JSON Schema](https://json-schema.org/): cómo se declara la forma de un documento
  para validarla en el borde.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`06` — Respuestas](06-respuestas.md).

1. ¿Cuántos tipos tiene JSON y cuáles son? 🟢
2. ¿Tiene JSON un tipo fecha? 🟢
3. ¿Qué diferencia hay entre entero y decimal en JSON? 🟢
4. ¿Por qué JSON no admite comentarios? 🟢
5. ¿Cómo se envía un binario dentro de un JSON y qué cuesta? 🟢
6. ¿Qué son las dos formas de parsear un documento? 🟢
7. ¿Qué devuelve `JSON.parse` en TypeScript? 🟢
8. ¿Qué norma define JSON? 🟢
9. ¿Por qué un identificador grande llega cambiado a JavaScript? 🟡
10. ¿Cuál es el valor exacto a partir del cual empieza el problema y por qué ese? 🟡
11. ¿Por qué Python y Java no sufren ese problema? 🟡
12. ¿Por qué Go sí lo sufre, y cómo se evita? 🟡
13. ¿Cuánta memoria cuesta parsear a árbol frente a parsear en flujo? 🟡
14. ¿Qué hace Go con un campo que no está en el `struct`? ¿Y Jackson? 🟡
15. ¿Qué es un *tolerant reader*? 🟡
16. ¿Qué pasa con las claves duplicadas y qué dice la norma? 🟡
17. ¿Por qué las claves de un objeto son siempre texto y qué rompe eso? 🟡
18. ¿Por qué un `id` debe viajar como cadena si es un número? 🟠
19. ¿Cuándo elegirías flujo en vez de árbol, y con qué dato lo justificas? 🟠
20. ¿Es siempre correcto ignorar los campos desconocidos? Da un contraejemplo. 🟠
21. ¿Por qué el `as Pedido` de TypeScript no protege, y qué lo protege? 🟠
22. ¿Por qué firmar un JSON sin canonicalizar es un fallo de seguridad? 🟠
23. Un servicio se cae al importar un archivo de 200 MB que en pruebas iba bien con 2 MB.
    Diagnostica y corrige. 🟠
24. ¿Qué diferencia práctica hay entre `{"nota": null}` y `{}`, y dónde importa? 🟠
25. Te proponen NDJSON en vez de un array JSON para una exportación. ¿Qué ganas y qué pierdes? 🟠
26. Diseña el contrato JSON de un pedido con dinero, fechas, identificadores y un adjunto.
    Justifica el tipo elegido para cada campo. 🔴
27. Dos equipos discuten si el consumidor debe fallar ante un campo desconocido. Escribe la
    política que propondrías, con los casos en que se invierte. 🔴
28. Te dan un JSON de 4 GB y hay que calcular tres agregados. Escribe el enfoque, la estructura
    de datos y el coste en memoria. 🔴
29. Tu API devuelve un `Map<Integer, String>` serializado. Explica qué llega al cliente y cómo
    lo rediseñarías. 🔴
30. Escribe la prueba automatizada que detectaría la corrupción de identificadores grandes antes
    de llegar a producción, y di por qué las pruebas actuales no la detectan. 🔴
31. Dos servicios intercambian JSON y uno empieza a recibir importes con tres decimales donde
    esperaba dos. Diagnostica sin acceso al código del otro. 🔴

---

**Siguiente:** [`02` — XML y los esquemas](02-xml-y-los-esquemas.md) ·
**Bloque:** [README](README.md)
