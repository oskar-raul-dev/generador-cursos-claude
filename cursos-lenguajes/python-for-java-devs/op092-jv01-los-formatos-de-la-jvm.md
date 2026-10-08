# ☕ jv01 — Los formatos que la JVM ya produce

> Python para desarrolladores Java senior · **Carta** · Track `jv` — Convivir con tu stack Java ·
> sección 1 de 4
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Este track parte de una idea que este perfil necesita oír: **Python en el borde no significa matar la JVM; significa hablarle
bien**. Los servicios Java de la casa —el Spring Boot que el camino base midió en la Fase 17, los de los aliados, el broker de
mensajería— ya producen datos en formatos con esquema: Avro en los temas de Kafka, Protobuf en los servicios gRPC, Parquet en los
lagos de datos, métricas por JMX. Python no tiene que inventar un formato ni pedirle a nadie que cambie el suyo: tiene que
**leer el que ya existe sin perder nada en la traducción**.

Y en la traducción es donde se pierde. Un `BigDecimal` de Java viaja en Avro como bytes con una escala, y llega a Python como
`Decimal` solo si el lector entiende el tipo lógico; un `Instant` viaja como milisegundos y llega con zona o sin ella según la
biblioteca; un `long` de Protobuf se vuelve **una cadena** en la representación JSON estándar. Esta sección hace que Java escriba
de verdad —un programa Java que produce un archivo Avro— y que Python lo lea.

---

## 🧠 2. El modelo

| Formato | Lo produce la JVM en… | Desde Python | La trampa en la frontera |
|---|---|---|---|
| **Avro** | Kafka con Schema Registry, Hadoop | `fastavro` 1.x, `avro` | Tipos lógicos (`decimal`, `timestamp-millis`) y evolución con esquema lector |
| **Protobuf** | gRPC, servicios internos | `protobuf` (y `grpcio`) | En JSON, `int64` es **cadena**; los valores por defecto no viajan |
| **Parquet** | Spark, Flink, lagos de datos | `pyarrow`, Polars, DuckDB (`db05`) | Marcas de tiempo `INT96` de Spark viejo; decimales |
| **JMX** | Toda JVM: memoria, hilos, métricas propias | **No directo**: Jolokia (HTTP) o el exportador de Prometheus | Python no habla RMI; se pone un puente |

| Java | Avro (tipo lógico) | Python con `fastavro` |
|---|---|---|
| `BigDecimal` | `bytes` + `decimal(precision, scale)` | `decimal.Decimal` |
| `Instant` | `long` + `timestamp-millis` | `datetime` **con zona UTC** |
| `LocalDate` | `int` + `date` | `datetime.date` |
| `UUID` | `string` + `uuid` | `uuid.UUID` |

### Esto sí funciona igual

El esquema es el contrato, en los dos lados, igual que en Java: el `.avsc` o el `.proto` vive en un repositorio compartido y se
versiona; las reglas de compatibilidad (agregar un campo con valor por defecto es compatible, quitar uno obligatorio no) son las
mismas que este perfil ya aplica con Schema Registry.

---

## 💻 3. El ejemplo que corre

El esquema compartido, `abono.avsc`:

```json
{"type": "record", "name": "Abono", "namespace": "co.aurea.cartera",
 "fields": [
   {"name": "sede", "type": "string"},
   {"name": "valor", "type": {"type": "bytes", "logicalType": "decimal", "precision": 12, "scale": 2}},
   {"name": "momento", "type": {"type": "long", "logicalType": "timestamp-millis"}}
 ]}
```

El lado Java, `EscribeAbonos.java` —un solo archivo, que Java 21 corre sin compilar aparte—:

```java
import java.io.File;
import java.math.BigDecimal;
import java.time.Instant;
import org.apache.avro.Conversions;
import org.apache.avro.Schema;
import org.apache.avro.file.DataFileWriter;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;

public class EscribeAbonos {
    public static void main(String[] args) throws Exception {
        Schema schema = new Schema.Parser().parse(new File("abono.avsc"));
        Schema valor = schema.getField("valor").schema();
        var decimal = new Conversions.DecimalConversion();
        try (var writer = new DataFileWriter<GenericRecord>(new GenericDatumWriter<>(schema))) {
            writer.create(schema, new File("abonos.avro"));
            for (String sede : new String[] {"Suba", "Centro", "Zipaquirá"}) {
                GenericRecord r = new GenericData.Record(schema);
                r.put("sede", sede);
                r.put("valor", decimal.toBytes(new BigDecimal("1250000.10"), valor, valor.getLogicalType()));
                r.put("momento", Instant.parse("2026-10-05T14:30:00Z").toEpochMilli());
                writer.append(r);
            }
        }
        System.out.println("Java escribió abonos.avro con " + schema.getFullName());
    }
}
```

```bash
# Con las dependencias de Avro en lib/ (avro, jackson, commons-compress, slf4j-api):
java -cp "lib/*" EscribeAbonos.java
```

El lado Python, `lee_abonos.py`:

```python
"""Leer en Python lo que Java escribió en Avro, y leerlo con un esquema que evolucionó."""

import json

import fastavro

with open("abonos.avro", "rb") as f:
    reader = fastavro.reader(f)
    print("esquema del archivo:", reader.writer_schema["name"], "· códec:", reader.codec)
    for record in reader:
        print(" ", record["sede"], repr(record["valor"]), repr(record["momento"]))

# El servicio Java aún no agrega 'canal'; el consumidor Python ya lo espera, con valor por defecto.
reader_schema = json.load(open("abono.avsc"))
reader_schema["fields"].append({"name": "canal", "type": ["null", "string"], "default": None})
with open("abonos.avro", "rb") as f:
    first = next(fastavro.reader(f, reader_schema=fastavro.parse_schema(reader_schema)))
print("con el esquema nuevo:", {k: first[k] for k in ("sede", "canal")})
```

```bash
uv add fastavro
python3 lee_abonos.py
```

Salida (Python 3.14.7, 05/10/2026; la primera línea es del lado Java, con Java 21.0.12.1 y Avro 1.12.2):

```text
Java escribió abonos.avro con co.aurea.cartera.Abono
esquema del archivo: co.aurea.cartera.Abono · códec: null
  Suba Decimal('1250000.10') datetime.datetime(2026, 10, 5, 14, 30, tzinfo=datetime.timezone.utc)
  Centro Decimal('1250000.10') datetime.datetime(2026, 10, 5, 14, 30, tzinfo=datetime.timezone.utc)
  Zipaquirá Decimal('1250000.10') datetime.datetime(2026, 10, 5, 14, 30, tzinfo=datetime.timezone.utc)
con el esquema nuevo: {'sede': 'Suba', 'canal': None}
```

**Detalles con intención**

- **Las tres líneas `SLF4J(W): No SLF4J providers were found`** que imprime Java no son un error: Avro registra con SLF4J y en `lib/`
  no hay implementación. En un servicio de verdad la pone Spring Boot (Logback); aquí se agrega `slf4j-nop` o se ignoran.
- **El archivo Avro lleva su esquema adentro** (el *writer schema*). Python lo lee sin tener el `.avsc`; el `.avsc` del ejemplo solo
  hace falta para el esquema lector.
- **`Decimal('1250000.10')` con sus dos decimales**: el tipo lógico `decimal` guarda el entero sin escala y la escala en el esquema,
  y `fastavro` los junta. Sin tipo lógico —un `double`— los centavos viajan con el error de punto flotante.
- **`timestamp-millis` llega con zona UTC**, que es lo que el `Instant` de Java significa. Un `LocalDateTime` de Java tiene su propio
  tipo lógico (`local-timestamp-millis`) y llega sin zona.
- **El esquema lector** es la evolución en acción: el consumidor Python espera un campo que el productor Java todavía no escribe, y
  Avro lo resuelve con el valor por defecto. Es la misma regla de compatibilidad de Schema Registry.

---

## ⚠️ 4. Lo que se rompe

**Protobuf en JSON.** La representación JSON estándar de Protobuf (la de `JsonFormat` en Java y `json_format` en Python) escribe
`int64` como **cadena** —`"cita_id": "1234567890123"`— porque JavaScript no representa enteros de 64 bits. Un consumidor que espera un
número en el JSON falla. Entre Java y Python, se habla Protobuf binario; el JSON es para depurar.

**Los valores por defecto de proto3.** Un campo en cero, cadena vacía o `false` no viaja: el receptor no distingue "no lo mandaron" de
"lo mandaron en cero". Para un monto en cero, importa. `optional` en proto3 recupera la presencia.

**El Parquet de un Spark viejo.** Las marcas de tiempo `INT96` de versiones antiguas de Spark las lee `pyarrow`, con su propia
interpretación de zona; se verifica una fila contra lo que dice el lado Java antes de confiar.

**Leer JMX desde Python "a mano".** JMX remoto es RMI, un protocolo de Java. Las bibliotecas de Python que lo hablan lanzan un proceso
Java por debajo. Lo razonable es que la JVM exponga sus métricas por HTTP (Jolokia, o el exportador de Prometheus, `ob03`) y Python las
lea como cualquier JSON.

---

## ⚖️ 5. Cuándo NO usarlo

**Inventar un formato propio para la frontera.** Si el servicio Java ya publica Avro, el consumidor Python lee Avro; un JSON "más simple"
de por medio es un formato más que mantener y una fuente más de pérdidas.

**Avro o Protobuf para una API pública o para Patricia.** Son formatos entre servicios; hacia afuera, JSON y CSV (`ui08`).

**`avro` (la biblioteca oficial) cuando el volumen importa.** Es Python puro y mucho más lenta que `fastavro`; sirve como referencia.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el lado Java y el lado Python. **Criterio:** la salida, y dónde está guardado el esquema dentro de `abonos.avro`.
2. Cambia el tipo de `valor` a `double` en el esquema y en Java. **Criterio:** muestras qué llega a Python con `0.1 + 0.2` como valor.
3. Lee el archivo con la biblioteca `avro` oficial. **Criterio:** los mismos tipos, y el tiempo de cada una con 100 000 registros.

**🟡 Intermedio (4–6)**

4. Haz que Java escriba con compresión `snappy` (`writer.setCodec`). **Criterio:** Python lo lee, y dices qué paquete hizo falta en
   cada lado.
5. Escribe el mismo abono en Protobuf desde Python y conviértelo a JSON con `json_format`. **Criterio:** el `int64` sale como cadena.
6. Escribe el registro en Avro desde Python y léelo desde Java. **Criterio:** Java obtiene un `BigDecimal` con escala 2.

**🟠 Difícil (7–9)**

7. Levanta un Schema Registry y produce desde Java a Kafka en Avro; consume desde Python con `confluent-kafka` y su deserializador
   Avro. **Criterio:** el `Decimal` llega igual que en el ejemplo.
8. Expón las métricas de la JVM con el agente de Jolokia y léelas desde Python con `httpx`. **Criterio:** el uso de *heap* en un JSON.
9. Lee un Parquet escrito por Spark (o por `pyarrow` con `use_deprecated_int96_timestamps=True`). **Criterio:** la marca de tiempo
   coincide con la original, y explicas qué hiciste para que coincidiera.

**🔴 Muy difícil (10)**

10. Inventaría las fronteras entre Java y Python de un sistema tuyo. **Criterio:** una tabla. *Rúbrica:* (a) cada frontera con su formato
    y dónde vive el esquema; (b) los tipos que cruzan y cómo llegan (montos, fechas, identificadores); (c) la regla de evolución de cada
    esquema; (d) la prueba que detectaría una pérdida en la traducción.

---

## 📚 7. Referencias

**Documentación oficial**

- Avro, especificación (tipos lógicos y resolución de esquemas): https://avro.apache.org/docs/1.12.0/specification/
- `fastavro`: https://fastavro.readthedocs.io/en/latest/
- Protobuf, el mapeo a JSON: https://protobuf.dev/programming-guides/json/
- Jolokia: https://jolokia.org/

**Orden de lectura sugerido:** de la especificación de Avro, las secciones de tipos lógicos y de resolución de esquemas; después el mapeo
JSON de Protobuf.

---

## 🚀 8. Cierre

Python en el borde lee los formatos que la JVM ya produce, con el mismo esquema como contrato. La pérdida está en la traducción de tipos:
`BigDecimal` llega como `Decimal` si hay tipo lógico, `Instant` como `datetime` con zona, el `int64` de Protobuf en JSON como cadena, y JMX
solo a través de un puente HTTP.

**La señal de que quedó bien:** *"El consumidor Python lee los abonos que publica el servicio Java, y los centavos y la hora llegan como
salieron."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-jv-fase-01 -m "op jv01 cerrada: Java escribe Avro, Python lo lee sin perder centavos ni zona"
> ```
>
> Los commits llevan su prefijo (`op jv01: …`) y los de ejercicio su número
> (`op jv01 ej07: …`).
