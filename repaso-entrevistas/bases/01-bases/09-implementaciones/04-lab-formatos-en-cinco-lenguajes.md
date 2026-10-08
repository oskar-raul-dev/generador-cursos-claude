# 04 — Lab: formatos en cinco lenguajes

> **Documento opcional.** La teoría está en el bloque [`07-formatos-de-datos`](../07-formatos-de-datos/):
> `01` JSON, `02` XML, `03` YAML y `04` CSV. Aquí solo se teclea. Nadie necesita este documento para
> aprobar una entrevista; sirve para tener el código en los dedos y para ver, lado a lado, cuánto
> cambia el mismo problema según el lenguaje.
>
> **Todo lo que aparece aquí se ejecutó**, y las versiones están declaradas al final. Las soluciones
> van inline: no hay solucionario aparte.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:** [1 — el dato de trabajo](#1--el-dato-de-trabajo) · [2 — JSON](#2--json-con-modelo-tipado) ·
[3 — XML](#3--xml-a-pie-con-stax-prehecho-con-elementtree) ·
[4 — YAML](#4--yaml-el-mismo-archivo-tres-resultados) ·
[5 — CSV](#5--csv-a-pie-en-java-prehecho-en-python) · [6 — ejercicios](#6--ejercicios) ·
[7 — versiones](#7--versiones-con-las-que-se-ejecutó)

---

## 1. 🎯 El dato de trabajo

El mismo pedido, en los cuatro formatos. Es lo que se lee y se escribe en todo el documento:

```json
{"id":"PED-00042","creado_en":"2026-09-18T14:30:00Z","total":"1250.00","divisa":"COP"}
```

```xml
<pedido id="PED-00042"><cliente>Muebles El Roble</cliente><total divisa="COP">1250.00</total></pedido>
```

```yaml
id: "PED-00042"
total: "1250.00"
divisa: COP
```

```text
PED-00042,"Muebles ""El Roble"", S.A.",007
```

Tres decisiones ya tomadas en ese dato, y son las del bloque `07`: **el identificador es cadena**, **el
importe es cadena decimal con divisa al lado** y **la fecha es ISO-8601 con zona**. El lab consiste
en que eso sobreviva el viaje de ida y vuelta en cinco lenguajes.

---

## 2. 🧱 JSON con modelo tipado

### Java — Jackson

```java
record Pedido(
    String id,
    @JsonProperty("creado_en") Instant creadoEn,
    BigDecimal total,
    String divisa
) {}

var om = new ObjectMapper()
    .findAndRegisterModules()                                    // habilita java.time
    .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
    .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);    // si no, escribe un número

Pedido p = om.readValue(json, Pedido.class);
```

```text
leído:     Pedido[id=PED-00042, creadoEn=2026-09-18T14:30:00Z, total=1250.00, divisa=COP]
total x 2: 2500.00
escrito:   {"id":"PED-00042","creado_en":"2026-09-18T14:30:00Z","total":1250.00,"divisa":"COP"}
```

- `record` funciona como modelo desde Jackson 2.12: sin anotaciones de constructor y sin *setters*.
- **`@JsonProperty` es lo que casa `creado_en` con `creadoEn`.** La alternativa global es una
  estrategia de nombres (`PropertyNamingStrategies.SNAKE_CASE`), que es lo que se hace en un proyecto
  entero en vez de anotar campo a campo.
- **`BigDecimal` se deserializa bien desde una cadena** y conserva la escala: `1250.00` sigue teniendo
  dos decimales, y `multiply` da `2500.00`. Ese es el motivo de mandar el importe como cadena.

**Los dos errores que salen de verdad, y salieron al escribir esto:**

```text
InvalidDefinitionException: Java 8 date/time type `java.time.Instant` not supported by default:
add Module "com.fasterxml.jackson.datatype:jackson-datatype-jsr310" to enable handling
```

- `findAndRegisterModules()` **no puede registrar un módulo que no está en el classpath**. Hay que
  añadir la dependencia `jackson-datatype-jsr310`. En Spring Boot ya viene; fuera de él, no.

```text
escrito: {"id":"PED-00042","creado_en":1789741800.000000000, ...}
```

- Con el módulo puesto pero sin `disable(WRITE_DATES_AS_TIMESTAMPS)`, **lee ISO-8601 y escribe un
  número**: el viaje de ida y vuelta no es simétrico. Es un bug real de contrato que pasa
  desapercibido hasta que el consumidor se queja.

### Python — `json` y `dataclass`

```python
@dataclass
class Pedido:
    id: str
    creado_en: datetime
    total: Decimal
    divisa: str

d = json.loads(crudo)                                  # dict: los campos extra no molestan
p = Pedido(
    id=d["id"],
    creado_en=datetime.fromisoformat(d["creado_en"]),  # 3.11+ acepta la Z
    total=Decimal(d["total"]),                         # Decimal DESDE CADENA, nunca desde float
    divisa=d["divisa"],
)

def codificar(o):
    if isinstance(o, datetime): return o.isoformat().replace("+00:00", "Z")
    if isinstance(o, Decimal):  return str(o)
    raise TypeError(type(o))

json.dumps(asdict(p), default=codificar)
```

```text
leído:     Pedido(id='PED-00042', creado_en=datetime(2026, 9, 18, 14, 30, tzinfo=utc), total=Decimal('1250.00'), divisa='COP')
total x 2: 2500.00
escrito:   {"id": "PED-00042", "creado_en": "2026-09-18T14:30:00Z", "total": "1250.00", "divisa": "COP"}
```

- **Python no tiene mapeo automático a clases en la biblioteca estándar**: `json.loads` da un
  diccionario y la construcción del objeto es manual. Lo automático vive en `pydantic`, que además
  valida, y es lo que se usa en un proyecto real.
- **`Decimal(d["total"])` desde cadena es obligatorio.** `Decimal(1250.00)` desde flotante arrastra la
  basura binaria de `06-numeros-tiempo-concurrencia/01`.
- El `default=` de `json.dumps` es el gancho para todo lo que el módulo no sabe escribir. Sin él,
  `TypeError: Object of type Decimal is not JSON serializable`.

### Go — etiquetas de `struct`

```go
type Pedido struct {
	ID       string    `json:"id"`
	CreadoEn time.Time `json:"creado_en"`   // time.Time habla ISO-8601 de serie
	Total    string    `json:"total"`       // el dinero, como cadena
	Divisa   string    `json:"divisa"`
	// campoNuevo no está declarado: Go lo ignora en silencio
}
```

```text
leído:    {ID:PED-00042 CreadoEn:2026-09-18 14:30:00 +0000 UTC Total:1250.00 Divisa:COP}
escrito:  {"id":"PED-00042","creado_en":"2026-09-18T14:30:00Z","total":"1250.00","divisa":"COP"}
```

- **El viaje de ida y vuelta sale simétrico sin configurar nada**, que es la ventaja real de Go aquí:
  `time.Time` serializa en RFC 3339 por defecto.
- Los campos han de ser **exportados** —mayúscula inicial— o `encoding/json` los ignora sin decir
  nada. Es el primer tropiezo de todo el mundo.
- Go no tiene decimal en la biblioteca estándar: el importe se queda como cadena y se convierte con
  `shopspring/decimal` si hay que operar.

### TypeScript — el validador que `JSON.parse` no trae

```typescript
function aPedido(x: unknown): PedidoCrudo {
  if (typeof x !== "object" || x === null) throw new TypeError("no es un objeto");
  const o = x as Record<string, unknown>;
  for (const c of ["id", "creado_en", "total", "divisa"]) {
    if (typeof o[c] !== "string") throw new TypeError(`campo ${c}: se esperaba string`);
  }
  return o as unknown as PedidoCrudo;
}
```

```text
tsc --strict: sin errores
leído:     { id: 'PED-00042', creado_en: '...', total: '1250.00', divisa: 'COP', campoNuevo: 'x' }
total x 2: 2500.00   ← ojo: esto ya es double
rechazado: campo id: se esperaba string
```

- **El parámetro es `unknown`, no `any`.** Ese es el truco: `unknown` obliga al compilador a exigir
  una comprobación antes de usarlo, y es lo que convierte la función en una frontera real.
- **El `total` deja de ser exacto en cuanto lo conviertes a `Number`.** En JavaScript no hay decimal:
  para operar con dinero se usa una biblioteca (`decimal.js`, `big.js`) o enteros de céntimos.
- En producción esto lo escribe Zod o io-ts en tres líneas y con inferencia de tipos. Escribirlo a
  mano una vez enseña **qué hace la biblioteca por ti**, que es el punto de este lab.

---

## 3. 🧱 XML: a pie con StAX, prehecho con ElementTree

**Java — el recorrido en flujo, endurecido:**

```java
var f = XMLInputFactory.newInstance();
// Blindaje: sin DOCTYPE no hay XXE ni bomba de entidades
f.setProperty(XMLInputFactory.SUPPORT_DTD, false);
f.setProperty("javax.xml.stream.isSupportingExternalEntities", false);

XMLStreamReader r = f.createXMLStreamReader(new FileInputStream("pedidos.xml"));
BigDecimal suma = BigDecimal.ZERO;
String id = null;
while (r.hasNext()) {
    if (r.next() == XMLStreamConstants.START_ELEMENT) {
        switch (r.getLocalName()) {
            case "pedido" -> id = r.getAttributeValue(null, "id");
            case "total"  -> {
                BigDecimal v = new BigDecimal(r.getElementText());
                suma = suma.add(v);
                System.out.println("  " + id + "  " + v + " " + r.getAttributeValue(null, "divisa"));
            }
        }
    }
}
```

**Python — el mismo resultado, prehecho:**

```python
raiz = ET.parse("pedidos.xml").getroot()
suma = sum(Decimal(t.text) for t in raiz.iterfind("pedido/total"))
```

Salida idéntica en los dos:

```text
  PED-00042 1250.00 COP
  PED-00043 870.50 COP
suma: 2120.50
```

- **Treinta líneas frente a dos**, y esa es exactamente la comparación que este bloque existe para
  hacer. Lo que compran las treinta es **memoria constante**: la versión de Python construye el árbol
  entero, y con el fichero de 500 MB del capítulo `02` no se ejecuta.
- **`r.getAttributeValue(null, "divisa")` hay que leerlo antes de `getElementText()`**, porque ese
  método consume el elemento y avanza el lector. Es el error clásico de StAX: se lee el texto y luego
  el atributo sale `null`.
- Las dos propiedades de blindaje son el equivalente en StAX de la bandera del capítulo `02`, y hay
  que ponerlas **aunque el XML sea tuyo**, porque el día que deje de serlo nadie va a revisar esto.

---

## 4. 🧱 YAML: el mismo archivo, tres resultados

```yaml
paises: [NO, SE]
version: 1.10
puerto: 022
hora: 12:30
si: yes
```

| clave | Python (PyYAML) | Java (SnakeYAML) | Go (yaml.v3) |
|---|---|---|---|
| `paises` | `[False, 'SE']` | `[false, SE]` | `["NO", "SE"]` |
| `version` | `1.1` | `1.1` | `1.1` |
| `puerto` | `18` | `18` | `18` |
| `hora` | `750` | `750` | `"12:30"` |
| `si` | `True` | `true` | `"yes"` |

```python
yaml.safe_load(open("doc.yaml"))          # safe_load SIEMPRE, nunca load
```

```java
new Yaml().load(new FileInputStream("doc.yaml"));   // SnakeYAML 2.x ya usa constructor seguro
```

```go
yaml.Unmarshal(b, &m)                     // yaml.v3 no instancia tipos arbitrarios
```

- **Las tres bibliotecas están bien y el archivo está mal.** La corrección es entrecomillar, y con
  comillas las tres columnas coinciden.
- El caso de prueba de cinco líneas de arriba vale como **prueba de regresión** en un proyecto que
  comparta configuración entre lenguajes: se carga con las dos bibliotecas, se serializa a JSON y se
  compara. Cinco líneas en la integración continua.

---

## 5. 🧱 CSV: a pie en Java, prehecho en Python

El JDK no trae CSV, así que en Java o se añade una dependencia o se escribe. La máquina de estados
completa son veinte líneas:

```java
static List<String> leerRegistro(String linea, char sep) {
    List<String> campos = new ArrayList<>();
    StringBuilder campo = new StringBuilder();
    boolean dentro = false;                              // ¿dentro de comillas?
    for (int i = 0; i < linea.length(); i++) {
        char c = linea.charAt(i);
        if (dentro) {
            if (c == '"') {
                if (i + 1 < linea.length() && linea.charAt(i + 1) == '"') {
                    campo.append('"'); i++;              // comilla escapada
                } else dentro = false;                   // cierre
            } else campo.append(c);
        } else {
            if (c == '"') dentro = true;
            else if (c == sep) { campos.add(campo.toString()); campo.setLength(0); }
            else campo.append(c);
        }
    }
    campos.add(campo.toString());
    return campos;
}
```

```text
split(",") → 4 campos
a pie      → 3 campos
   [PED-00042]
   [Muebles "El Roble", S.A.]
   [007]
```

```python
list(csv.reader(io.StringIO(linea)))      # una línea, y además maneja saltos internos
```

- **Esta versión de Java no maneja el salto de línea dentro del campo**, porque recibe una línea ya
  partida. Soportarlo obliga a leer carácter a carácter del flujo en vez de por líneas — y es
  exactamente la razón por la que no se escribe a mano en producción.
- `StringBuilder` y no concatenación de `String`: concatenar en un bucle es cuadrático, por
  [`02-texto/01`](../02-texto/01-strings-entre-lenguajes.md).
- En producción, Apache Commons CSV con `CSVFormat.RFC4180` resuelve esto y los casos borde que aquí
  faltan.

---

## 6. 🧪 Ejercicios

Con solución al lado. Se teclean y se ejecutan; leerlos no cuenta.

### 🟢 E1 — El viaje de ida y vuelta

Serializa un objeto con fecha e importe, deserialízalo y comprueba que sale idéntico. En Java, sin
`disable(WRITE_DATES_AS_TIMESTAMPS)` primero y con él después.

> **Solución.** Sin la bandera, la fecha vuelve como `1789741800.000000000`; con ella, como
> `"2026-09-18T14:30:00Z"`. La comprobación que hay que escribir es
> `assertEquals(original, om.readValue(om.writeValueAsString(original), Pedido.class))` — y el punto
> del ejercicio es ver que **esa prueba pasa en los dos casos**, porque el objeto se reconstruye
> igual: lo que cambia es el texto que ve el consumidor. Para detectarlo hay que comparar **la
> cadena**, no el objeto.

### 🟢 E2 — El campo desconocido

Manda un JSON con un campo de más a un modelo que no lo declara, en Java y en Go. Luego invierte el
comportamiento en los dos.

> **Solución.** Go lo ignora; Jackson lanza `UnrecognizedPropertyException`. Se invierten con
> `dec.DisallowUnknownFields()` y con
> `configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)`. Lo que hay que observar es
> que **el mensaje de Jackson nombra el campo y el de Go no dice nada**: cuando eliges ignorar,
> pierdes el diagnóstico, y por eso conviene registrar los campos desconocidos en vez de descartarlos
> en silencio.

### 🟡 E3 — El identificador que se rompe

Manda `{"id": 9007199254740993}` a los cinco lenguajes e imprime lo que llega. Luego arréglalo de las
dos formas posibles.

> **Solución.** Llega exacto en Java y Python, redondeado en JavaScript y en Go con mapa genérico.
> Las dos correcciones: **cambiar el contrato** —el `id` como cadena, que es lo correcto— o
> **cambiar el parser**: `dec.UseNumber()` en Go, y en JavaScript el *reviver* de `JSON.parse` para
> capturar el texto original, o `JSON.parse` con soporte de `BigInt`. La segunda arregla tu lado y
> deja rotos a los demás consumidores, y decirlo forma parte del ejercicio.

### 🟡 E4 — El YAML que miente

Carga el archivo de la sección 4 en dos lenguajes, compara los resultados, entrecomilla y vuelve a
comparar.

> **Solución.** Antes: `hora` es `750` en Java y `"12:30"` en Go. Después de entrecomillar: las dos
> dan `"12:30"`. El ejercicio completo es convertir eso en una prueba automática: cargar con las dos
> bibliotecas, volcar a JSON con claves ordenadas y comparar las dos cadenas. Falla en el momento en
> que alguien añade un valor sin comillas.

### 🟠 E5 — El parser de CSV, entero

Extiende la máquina de estados de la sección 5 para que lea de un flujo y soporte saltos de línea
dentro de los campos. Compárala con la biblioteca del lenguaje sobre los mismos datos.

> **Solución.** El cambio estructural es dejar de leer por líneas: el bucle consume caracteres del
> flujo y **emite un registro cuando encuentra un salto de línea estando fuera de comillas**. La
> versión Python de referencia está en el solucionario del bloque `07`, problema P1, y coincide campo
> por campo con `csv.reader`. Lo que hay que añadir en Java: leer con `Reader.read()` en vez de
> `readLine()`, tratar `\r\n` y `\n` como el mismo terminador, y decidir qué hacer con una comilla
> dentro de un campo no entrecomillado —que es entrada malformada—. La prueba es comparar contra
> Commons CSV con `CSVFormat.RFC4180` sobre un fichero con los tres casos borde.

### 🟠 E6 — Endurecer los tres parsers

Escribe el blindaje contra XXE en las tres fábricas de Java —`DocumentBuilderFactory`,
`SAXParserFactory` y `XMLInputFactory`— y demuestra con un documento malicioso que funciona.

> **Solución.** En las dos primeras,
> `setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)`; en StAX, las dos
> propiedades de la sección 3. La demostración es el archivo del capítulo `02`: sin blindar devuelve
> el contenido del fichero apuntado, y blindado lanza `SAXParseException` con *"DOCTYPE is
> disallowed"*. Lo que convierte esto en un ejercicio útil es hacerlo **una prueba automatizada**:
> una que afirme que el parser rechaza el documento con DOCTYPE. Así el blindaje no se pierde en el
> siguiente refactor.

### 🔴 E7 — El conversor en flujo

Convierte un XML de varios cientos de megas a NDJSON conservando tres campos, con memoria constante.
Mide la memoria antes y después con `/usr/bin/time -l`.

> **Solución.** StAX de entrada y un `BufferedWriter` de salida, escribiendo un objeto por línea y sin
> acumular nada. La medición es el objetivo: con DOM la memoria crece con el archivo; con StAX se
> queda plana. La referencia medida en el bloque `07`: 30 MB de JSON dieron 323 MB con árbol y 99 MB
> en flujo, con 42 MB de línea base de la JVM. Los cuatro detalles que hay que resolver —NDJSON en vez
> de array, búfer de salida, qué hacer con un registro corrupto y validación en flujo si hay XSD—
> están desarrollados en el problema P3 del solucionario del bloque `07`.

### 🔥 E8 — Fuera de conteo: el detector de formato

Escribe una función que reciba los primeros 64 KB de un archivo y adivine si es JSON, XML, YAML o CSV,
con un nivel de confianza.

> **Solución.** Las señales fuertes en orden: BOM y primer carácter no blanco —`{` o `[` para JSON,
> `<` para XML—; `---` inicial o `clave: valor` para YAML; recuento estable de delimitadores por línea
> para CSV. La trampa que hay que manejar: **todo JSON es YAML válido**, así que la respuesta para un
> `{...}` no puede ser "YAML" a secas, y CSV de una sola columna es indistinguible de texto plano. Lo
> que convierte esto en un ejercicio de nivel es **devolver la confianza y la lista de ambigüedades**,
> igual que el problema P4 del bloque `07`: el valor está en saber qué no se puede determinar.

---

## 7. 📝 Versiones con las que se ejecutó

```text
Java    Zulu 17.0.16 y 21.0.12 (sdkman) — salida IDÉNTICA en las dos
        Jackson 2.18.2 (core, databind, annotations, datatype-jsr310)
        SnakeYAML 2.3
Python  3.13.4 · PyYAML 6.0.3
Node    24.21.0 · TypeScript vía npx tsc --strict --noEmit
Go      1.27.1 · gopkg.in/yaml.v3
```

Los jars de Java se descargaron de Maven Central y se ejecutaron con `-cp`, sin Maven ni Gradle, para
que cada fragmento se pueda reproducir con `javac` y `java` a secas. Nada de lo que aparece en este
documento es una salida esperada: todas son salidas reales.

---

**Anterior:** [`03` — Ejercicios comparativos](03-ejercicios-comparativos.md) ·
**Siguiente:** [`05` — Lab: IO bloqueante y no bloqueante](05-lab-io-bloqueante-y-no-bloqueante.md) ·
**Teoría:** [`07-formatos-de-datos`](../07-formatos-de-datos/) · **Bloque:** [README](README.md)
