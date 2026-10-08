# 🧱 jv04 — La arquitectura mixta: dónde poner la frontera

> Python para desarrolladores Java senior · **Carta** · Track `jv` — Convivir con tu stack Java ·
> sección 4 de 4
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las tres anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track mostró tres formas de que Python y Java convivan: leer los formatos que la JVM produce
([`jv01`](op092-jv01-los-formatos-de-la-jvm.md)), llamar a Java desde Python ([`jv02`](op093-jv02-jpype-y-py4j.md)) y correr
Python sobre la JVM ([`jv03`](op094-jv03-graalpy-y-jython.md)). La pregunta que las ordena es de arquitectura: en un sistema con
partes en Java y partes en Python, **¿dónde va la frontera, y de qué está hecha?**

La respuesta de este perfil, entrenado en microservicios, suele ser automática: "un servicio REST". Es una buena respuesta muchas
veces, y tiene un costo por llamada que se olvida hasta que alguien pone la llamada en un bucle. Esta sección mide ese costo con un
servicio Java real —el servidor HTTP que trae el propio JDK, sin dependencias— y lo compara con las otras fronteras del track, para
que la decisión salga de números y no de costumbre.

---

## 🧠 2. El modelo

| Frontera | Costo por operación (medido en el track) | Acoplamiento | Si un lado falla | Ejemplo en la carta |
|---|---|---|---|---|
| En el proceso (JPype) | ≈ 0,6 µs | Máximo: una JVM en Python | Se caen los dos | `jv02` |
| Otro proceso por *socket* (Py4J) | ≈ 140 µs | Alto: mismos objetos | El otro devuelve error | `jv02` |
| HTTP, una llamada por operación | ≈ 430 µs (en el mismo contenedor) | Contrato | Error de red, reintento | Aquí |
| HTTP, en lote | ≈ 0,7 µs por elemento | Contrato | Error de red, reintento | Aquí |
| Archivo o bitácora con esquema (Avro, Kafka) | Asíncrono | Mínimo: solo el esquema | Nadie se entera hasta leer | `jv01`, `db14` |

Y las preguntas que deciden, en orden:

1. **¿Quién es dueño de cada lado y cada cuánto despliega?** Si los despliegan equipos o ritmos distintos, la frontera es un contrato
   (HTTP, esquema), no una JVM dentro de Python.
2. **¿Cuántas veces se cruza por segundo?** Muchas veces y con poco trabajo por cruce: en el proceso o en lote. Pocas: lo que sea más
   simple.
3. **¿Tiene que ser síncrono?** Si no, una bitácora o un archivo desacoplan del todo.

### Esto sí funciona igual

Todo lo que este perfil sabe de microservicios vale entre Java y Python sin cambios: contratos versionados, *timeouts*, reintentos con
idempotencia, llamadas gruesas en vez de conversadoras. El lenguaje de cada lado no cambia ninguna de esas reglas.

---

## 💻 3. El ejemplo que corre

El servicio Java, `ServidorRegalias.java`: un archivo, solo el JDK, la misma regla de redondeo de `jv02`.

```java
import com.sun.net.httpserver.HttpServer;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

public class ServidorRegalias {
    static BigDecimal regalia(BigDecimal ventas, BigDecimal tasa) {
        return ventas.multiply(tasa).setScale(0, RoundingMode.HALF_EVEN);
    }

    static void reply(com.sun.net.httpserver.HttpExchange ex, String text) throws java.io.IOException {
        byte[] body = text.getBytes(StandardCharsets.UTF_8);
        ex.sendResponseHeaders(200, body.length);
        try (var out = ex.getResponseBody()) { out.write(body); }
    }

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8090), 0);
        server.createContext("/regalia", ex -> {             // GET ?ventas=…&tasa=…  → una regalía
            var q = ex.getRequestURI().getQuery().split("[=&]");
            reply(ex, regalia(new BigDecimal(q[1]), new BigDecimal(q[3])).toPlainString());
        });
        server.createContext("/regalias", ex -> {            // POST ?tasa=…, una venta por línea → una regalía por línea
            var tasa = new BigDecimal(ex.getRequestURI().getQuery().split("=")[1]);
            var body = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            reply(ex, body.lines().map(v -> regalia(new BigDecimal(v), tasa).toPlainString())
                          .collect(Collectors.joining("\n")));
        });
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        server.start();
        System.out.println("servicio Java en :8090");
    }
}
```

```bash
java -Dsun.net.httpserver.nodelay=true ServidorRegalias.java &      # el porqué de la opción, en §4
```

El cliente Python, `frontera.py`: llamadas sueltas, una llamada en lote, y la prueba de equivalencia contra su propio cálculo.

```python
"""El costo de una frontera HTTP con un servicio Java: llamada por llamada, en lote, y la equivalencia."""

import os
import random
import time
from decimal import ROUND_HALF_EVEN, Decimal

import httpx

BASE = os.environ.get("AUREA_JAVA", "http://127.0.0.1:8090")
RATE = "0.045"
random.seed(17)
sales = [Decimal(random.randrange(10_000_000, 500_000_000)) / 100 for _ in range(100_000)]

with httpx.Client(base_url=BASE) as client:                 # conexión reutilizada (keep-alive)
    for _ in range(50):
        try:
            client.get("/regalia", params={"ventas": "1", "tasa": RATE})
            break
        except httpx.ConnectError:
            time.sleep(0.2)

    n = 2_000
    start = time.perf_counter()
    single = [Decimal(client.get("/regalia", params={"ventas": str(s), "tasa": RATE}).text) for s in sales[:n]]
    per_call = (time.perf_counter() - start) / n * 1e6

    start = time.perf_counter()
    response = client.post("/regalias", params={"tasa": RATE}, content="\n".join(str(s) for s in sales))
    batch = [Decimal(line) for line in response.text.splitlines()]
    per_item = (time.perf_counter() - start) / len(sales) * 1e6

python_side = [(s * Decimal(RATE)).quantize(Decimal("1"), rounding=ROUND_HALF_EVEN) for s in sales]
print(f"HTTP, una llamada por regalía: {per_call:7.1f} µs por regalía ({n} llamadas)")
print(f"HTTP, en lote:                 {per_item:7.1f} µs por regalía ({len(sales)} en una llamada)")
print("diferencias Java contra Python:", sum(a != b for a, b in zip(batch, python_side)), "de", len(sales),
      "· sueltas contra lote:", sum(a != b for a, b in zip(single, batch)))
```

```bash
uv add httpx
python3 frontera.py
```

Salida (Python 3.14.7, 05/10/2026; el servicio, con OpenJDK 21.0.12 en el mismo contenedor) (los microsegundos son de la máquina que corre):

```text
HTTP, una llamada por regalía:   432.3 µs por regalía (2000 llamadas)
HTTP, en lote:                     0.7 µs por regalía (100000 en una llamada)
diferencias Java contra Python: 0 de 100000 · sueltas contra lote: 0
```

La misma regalía, la misma regla, y seiscientas veces de diferencia según cómo se cruce la frontera: 432 µs por llamada suelta —el viaje
de ida y vuelta, aun dentro de un mismo contenedor—, 0,7 µs por regalía cuando cien mil viajan en una sola llamada. El lote queda en el
orden de JPype (`jv02`) sin meter la JVM en el proceso de Python. Y la prueba de equivalencia da cero diferencias en cien mil montos.

**Detalles con intención**

- **`httpx.Client` reutiliza la conexión**. Sin él (`httpx.get` suelto), cada llamada abre una conexión TCP nueva y el costo por
  llamada se multiplica: es el error más común al medir una frontera HTTP.
- **El lote viaja como texto, una venta por línea**: el formato más simple que conserva los decimales. JSON con números los
  convertiría en `float` en algún lado de la frontera (`jv01`).
- **La prueba de equivalencia compara las 100 000 regalías** de Java contra las de Python con la misma regla (`HALF_EVEN`, al peso). Es
  la prueba que permite decidir después si la lógica se queda en Java o se reescribe, con evidencia.
- **Hilos virtuales** (`newVirtualThreadPerTaskExecutor`) en el servidor de Java 21: un hilo por petición sin el costo de un hilo del
  sistema. No cambia la medición de un cliente; cambia cuántos clientes aguanta.

---

## ⚠️ 4. Lo que se rompe

**Los 40 ms del JDK.** La primera corrida de este ejemplo midió **46 458 µs por llamada suelta**: cien veces lo de arriba. Es la
combinación clásica del algoritmo de Nagle con el ACK diferido de TCP: el servidor HTTP del JDK escribe las cabeceras y el cuerpo en dos
escrituras, Nagle retiene la segunda hasta recibir el ACK de la primera, y el cliente demora ese ACK unos 40 ms. Con
`-Dsun.net.httpserver.nodelay=true` (que activa `TCP_NODELAY` en el servidor), bajó a 432 µs. Cualquier servicio pequeño de petición y
respuesta que mida decenas de milisegundos sin razón merece esta sospecha antes que cualquier otra.

**La llamada HTTP dentro del bucle.** Es el error que la tabla muestra: lo que en lote cuesta microsegundos por elemento, en llamadas
sueltas cuesta lo que cuesta un viaje de ida y vuelta. Con la red real entre dos servidores, en vez de un mismo contenedor, el costo por
llamada sube otro orden de magnitud.

**La frontera en el lugar del organigrama.** "El equipo Java es dueño de la liquidación, así que es un servicio" está bien; "así que el
análisis de Python la llama un millón de veces por HTTP" no. El contrato puede ser un servicio **con un *endpoint* de lote**.

**Los tipos en el contrato.** Si el contrato es JSON con números, los montos cruzan como `float` en algún cliente. Se declaran como cadena
(o como enteros en la unidad mínima) en el contrato, y se prueba.

**Dos implementaciones de la misma regla sin prueba de equivalencia.** Tarde o temprano difieren en un redondeo, y Édgar lo encuentra antes
que nadie.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Si todo el sistema es Python.** Este track es para convivir con Java existente; en un sistema nuevo y solo en Python, las fronteras son
las de cualquier diseño.

**Si la frontera ya existe y nadie se queja.** Medirla está bien; rediseñarla sin un problema concreto, no.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Corre el ejemplo. **Criterio:** los dos costos por regalía, y cuántas veces más cuesta la llamada suelta.
2. Repite las llamadas sueltas con `httpx.get` sin `Client`. **Criterio:** el costo por llamada, y por qué cambió.

**🟡 Intermedio (3–4)**

3. Cambia el lote a JSON con números y compara con Python. **Criterio:** si aparecen diferencias, cuántas y por qué; si no, en qué caso
   aparecerían.
4. Agrega un *timeout* y un reintento al cliente, y apaga el servidor Java a mitad del lote. **Criterio:** el cliente falla con un mensaje
   claro, sin quedarse colgado.

**🟠 Difícil (5–6)**

5. Mide las mismas llamadas entre dos contenedores en redes distintas (o entre dos máquinas). **Criterio:** la tabla con y sin red real.
6. Escribe el mismo servicio en gRPC con Protobuf (`jv01`) y mide. **Criterio:** la tabla de costos contra HTTP con texto.

**🔴 Muy difícil (7–8)**

7. Diseña la frontera entre la facturación en Java y el análisis en Python de Áurea. **Criterio:** una página. *Rúbrica:* (a) quién es
   dueño de cada lado y cada cuánto despliega; (b) cuántas veces por segundo se cruza; (c) la frontera elegida, con los números de esta
   sección; (d) la prueba de equivalencia y dónde corre.
8. Escribe la política de convivencia Java-Python de un equipo real. **Criterio:** una página. *Rúbrica:* (a) qué va en cada lenguaje y
   por qué; (b) los formatos de frontera permitidos; (c) cómo se prueba cada frontera; (d) cuándo se reescribe algo de un lado al otro.

---

## 📚 7. Referencias

- `com.sun.net.httpserver`, el servidor HTTP del JDK: https://docs.oracle.com/en/java/javase/21/docs/api/jdk.httpserver/com/sun/net/httpserver/package-summary.html
- `httpx`, clientes y conexiones: https://www.python-httpx.org/advanced/clients/
- Sam Newman, *Building Microservices*, 2.ª ed. (O'Reilly, 2021). Los capítulos de comunicación entre servicios valen entre lenguajes.

**Orden de lectura sugerido:** la página de clientes de `httpx` (es la que evita medir mal); el resto del track tiene sus referencias en
cada sección.

---

## 🚀 8. Cierre

La frontera entre Java y Python se elige por dueño, por frecuencia y por sincronía, y se mide. En el proceso cuesta microsegundos y acopla
todo; por HTTP cuesta un viaje por llamada y desacopla, y en lote recupera casi todo el costo; con una bitácora o un archivo, se desacopla
del todo. La regla que se repite en las cuatro secciones: los montos cruzan como texto o enteros, y dos implementaciones de la misma regla
viven con una prueba de equivalencia.

**La señal de que quedó bien:** *"El análisis de escenarios manda cien mil ventas en una llamada al servicio Java, y la prueba de
equivalencia dice cero diferencias."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-jv-fase-04 -m "op jv04 cerrada: la frontera medida, suelta y en lote, con la prueba de equivalencia"
> ```
>
> Los commits llevan su prefijo (`op jv04: …`) y los de ejercicio su número
> (`op jv04 ej07: …`).
