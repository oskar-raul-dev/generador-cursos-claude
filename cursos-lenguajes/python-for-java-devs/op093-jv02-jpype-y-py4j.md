# 🔗 jv02 — JPype y Py4J

> Python para desarrolladores Java senior · **Carta** · Track `jv` — Convivir con tu stack Java ·
> sección 2 de 4
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La liquidación de regalías de las franquicias tiene una implementación en Java que lleva años en producción: la usa el
sistema de facturación, la auditó el contador y Édgar Rojas la discute cada trimestre contra ella. El análisis nuevo en Python
—el que compara escenarios de tasa para la renegociación— necesita **exactamente** ese cálculo. Reescribirlo en Python es crear
una segunda versión que tarde o temprano va a diferir de la primera en un redondeo.

La alternativa es llamar al código Java desde Python. Hay dos formas maduras, con modelos opuestos: **JPype** carga la JVM
**dentro del proceso de Python** y deja usar las clases Java casi como módulos de Python; **Py4J** arranca la JVM **en otro proceso**
y habla con ella por un *socket*. La primera es rápida y frágil en el despliegue; la segunda es lenta y robusta. Esta sección
llama al mismo código Java de las dos formas y mide lo que cuesta cada llamada.

---

## 🧠 2. El modelo

| | JPype 1.7.1 | Py4J 0.10.9.9 |
|---|---|---|
| Dónde corre la JVM | **En el mismo proceso** que Python | En otro proceso |
| Cómo se llama | `from co.aurea import Regalias` y se usa | Por *socket*: `gateway.jvm.co.aurea.Regalias` |
| Costo por llamada | Microsegundos | Decenas o cientos de microsegundos |
| Si la JVM falla | Se cae el proceso de Python | Se cae la otra JVM; Python recibe un error |
| Conversión de tipos | Automática para los básicos | Automática para los básicos; colecciones por proxy |
| Quién lo usa | Herramientas científicas que envuelven bibliotecas Java | **PySpark** (por eso existe) |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de quien viene de Java es exponer la liquidación como un servicio REST y llamarla por HTTP. Es correcto cuando el
servicio ya existe y otros lo usan (`jv04`); para un análisis que va a llamar al cálculo un millón de veces con distintos escenarios,
un millón de peticiones HTTP son minutos. Llamar a la clase directamente es la opción que el instinto no considera, porque en Java
nunca hizo falta.

---

## 💻 3. El ejemplo que corre

El código Java, `src/main/java/co/aurea/Regalias.java` —la versión mínima de la que lleva años en producción—:

```java
package co.aurea;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

public class Regalias {
    /** Regalía en pesos: ventas por tasa, redondeo bancario al peso. */
    public static BigDecimal regalia(BigDecimal ventas, BigDecimal tasa) {
        return ventas.multiply(tasa).setScale(0, RoundingMode.HALF_EVEN);
    }

    /** La misma cuenta en enteros: tasa en puntos básicos (450 = 4,5 %). */
    public static long regaliaPesos(long ventas, int tasaBps) {
        return (ventas * tasaBps + 5_000) / 10_000;
    }

    public static List<String> franquicias() {
        return List.of("Suba", "Zipaquirá");
    }
}
```

```bash
javac -d build src/main/java/co/aurea/Regalias.java && jar cf regalias.jar -C build .
```

`llamar_java.py` usa la misma clase con JPype y con Py4J, y mide:

```python
"""La liquidación Java llamada desde Python: JPype (en proceso) y Py4J (por socket), medidas."""

import time
from decimal import Decimal

import jpype
import jpype.imports
from py4j.java_gateway import JavaGateway


def per_call_us(fn, n: int) -> float:
    start = time.perf_counter()
    for _ in range(n):
        fn()
    return (time.perf_counter() - start) / n * 1e6


# ------------------------------------------------- JPype: la JVM dentro de Python
jpype.startJVM(classpath=["regalias.jar"])
from co.aurea import Regalias           # noqa: E402  — solo existe después de arrancar la JVM
from java.math import BigDecimal        # noqa: E402

result = Regalias.regalia(BigDecimal("142900000"), BigDecimal("0.045"))
print("JPype regalia:", result, type(result).__name__, "→", repr(Decimal(str(result))))
print("JPype franquicias:", list(Regalias.franquicias()), "·", type(Regalias.franquicias()).__name__)
jp = per_call_us(lambda: Regalias.regaliaPesos(142_900_000, 450), 100_000)

# ------------------------------------------------- Py4J: la JVM en otro proceso
gateway = JavaGateway.launch_gateway(classpath="regalias.jar", die_on_exit=True)
JRegalias = gateway.jvm.co.aurea.Regalias
big = gateway.jvm.java.math.BigDecimal
print("Py4J regalia:", JRegalias.regalia(big("142900000"), big("0.045")))
py4 = per_call_us(lambda: JRegalias.regaliaPesos(142_900_000, 450), 5_000)
gateway.shutdown()

# ------------------------------------------------- la misma cuenta en Python, como referencia
sales, bps = 142_900_000, 450                 # en variables: con constantes, Python precalcula la cuenta
py = per_call_us(lambda: (sales * bps + 5_000) // 10_000, 100_000)
print(f"por llamada: Python {py:.2f} µs · JPype {jp:.2f} µs · Py4J {py4:.0f} µs")
```

```bash
uv add jpype1 py4j
python3 llamar_java.py
```

Salida (Python 3.14.7, 05/10/2026) (los microsegundos son de la máquina que corre; estos, de un contenedor en un portátil):

```text
JPype regalia: 6430500 java.math.BigDecimal → Decimal('6430500')
JPype franquicias: ['Suba', 'Zipaquirá'] · java.util.ImmutableCollections.List12
Py4J regalia: 6430500
por llamada: Python 0.09 µs · JPype 0.57 µs · Py4J 141 µs
```

El mismo cálculo Java, el mismo resultado por los dos caminos, y tres órdenes de magnitud entre ellos. Con JPype, una llamada cuesta
medio microsegundo —unas seis veces la cuenta hecha en Python—: un millón de escenarios, medio segundo. Con Py4J, cada llamada cuesta
141 µs —unas 250 veces más que JPype—: el mismo millón, dos minutos y veinte segundos. La lista que devuelve Java llega como una lista
inmutable de Java, no como una `list` de Python; se itera igual, y se convierte con `list()` si sale de la frontera.

**Detalles con intención**

- **`jpype.imports`** permite escribir `from co.aurea import Regalias` como si fuera un módulo de Python, una vez arrancada la JVM. Por
  eso el `import` está después de `startJVM`, y por eso `ruff` se queja (`E402`) con razón.
- **`BigDecimal` se construye desde una cadena**, como en Java, y se convierte a `Decimal` pasando por `str`: así no hay `float` en
  ningún paso de la frontera.
- **`launch_gateway`** arranca la JVM de Py4J con su propio *jar* (viene dentro del paquete de Python) y el nuestro en el *classpath*, y
  la apaga al terminar. En producción, la JVM de Py4J suele ser un servicio aparte que ya está corriendo.
- **La JVM de JPype no se puede reiniciar** en el mismo proceso: `startJVM` una vez, y vive hasta que Python termina.

---

## ⚠️ 4. Lo que se rompe

**Un directorio `co/` junto al script.** La primera corrida de este ejemplo tenía el código Java en `co/aurea/` al lado de
`llamar_java.py`, y `from co.aurea import Regalias` falló con `ImportError: cannot import name 'Regalias' from 'co.aurea' (unknown
location)`: Python encontró el directorio, lo tomó como un paquete de espacio de nombres (PEP 420) y nunca le preguntó a la JVM. La
segunda corrida, con las fuentes en `java/co/aurea/`, falló igual con `from java.math import BigDecimal`: ahora el directorio `java/`
tapaba el paquete `java` de la JVM. Las fuentes Java van en `src/main/java/`, cuya raíz no coincide con ningún paquete Java, o en
cualquier lugar fuera del camino de importación de Python.

**JPype y la JVM correcta.** JPype busca la JVM por `JAVA_HOME` o por la ruta por defecto; en un servidor con dos JDK, carga la que
encuentre primero, y la arquitectura tiene que coincidir con la de Python (un Python de ARM con una JVM de x86 no arranca). Se fija con
`jpype.startJVM(jvmpath=…)`.

**Un fallo de la JVM se lleva a Python.** Con JPype, un `OutOfMemoryError` o un fallo nativo en el código Java termina el proceso de
Python entero, sin `except` que lo atrape. Para código Java que no es de confianza, Py4J aísla.

**Llamar a Py4J en un bucle.** Cada llamada es un viaje por el *socket*; un bucle de un millón de llamadas son minutos. Con Py4J se
diseñan llamadas gruesas: mandar la lista entera de escenarios y recibir la lista de resultados.

**El GIL y los hilos de Java.** Con JPype, el código Java corre sin el GIL de Python mientras dura la llamada, lo que es bueno; pero
los objetos Java que vuelven a Python y los *callbacks* de Java a Python sí lo toman. Las llamadas cortas desde muchos hilos de Python
no escalan como en Java.

---

## ⚖️ 5. Cuándo NO usarlo

**Si la lógica Java ya es un servicio.** Si la liquidación ya se expone por REST o gRPC y otros la consumen, Python también la consume
así; meter la JVM en el proceso de Python duplica un despliegue.

**Para tres llamadas al día.** Llamar por HTTP o por línea de comandos (`subprocess` a `java -jar`) es más simple y no carga una JVM.

**Para reescribir menos.** Si la lógica Java es pequeña y estable, reescribirla en Python con pruebas de equivalencia contra la versión
Java (ejercicio 6) puede ser más barato que operar la frontera para siempre.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** los tres tiempos por llamada y la razón entre JPype y Py4J.
2. Llama desde JPype a `java.time.LocalDate.of(2026, 10, 5).plusDays(30)`. **Criterio:** el resultado y su tipo en Python.
3. Provoca una excepción Java (`BigDecimal("abc")`) desde JPype y desde Py4J. **Criterio:** el tipo de excepción que ve Python en cada
   caso.

**🟡 Intermedio (4–6)**

4. Agrega a la clase Java un método que reciba una lista de ventas y devuelva la lista de regalías. **Criterio:** con Py4J, una llamada
   para mil escenarios, y el tiempo contra mil llamadas sueltas.
5. Arranca la JVM de JPype con `-Xmx64m` y crea un arreglo Java de 200 MB. **Criterio:** describes qué le pasa al proceso de Python.
6. Escribe una prueba de equivalencia: la regalía calculada en Python y en Java para 10 000 ventas aleatorias. **Criterio:** cero
   diferencias, o la lista de las que hay y por qué.

**🟠 Difícil (7–9)**

7. Llama al cálculo desde cuatro hilos de Python con JPype. **Criterio:** el tiempo total contra un hilo, y lo explicas.
8. Corre la JVM de Py4J como un servicio aparte (`GatewayServer` en un `main` propio) y conecta desde Python. **Criterio:** reiniciar
   Python no reinicia la JVM.
9. Empaqueta el análisis en un contenedor con Python, la JVM y el *jar*. **Criterio:** el tamaño de la imagen, y qué JDK elegiste.

**🔴 Muy difícil (10)**

10. Decide cómo llega la liquidación Java al análisis de escenarios de Áurea. **Criterio:** una página. *Rúbrica:* (a) JPype, Py4J,
    servicio o reescritura, con la medición; (b) cómo se garantiza que el cálculo es el mismo; (c) qué se despliega y dónde; (d) qué pasa
    el día que el código Java cambia.

---

## 📚 7. Referencias

**Documentación oficial**

- JPype: https://jpype.readthedocs.io/en/latest/
- JPype, guía de uso: https://jpype.readthedocs.io/en/latest/userguide.html
- Py4J: https://www.py4j.org/
- Py4J, uso desde Python: https://www.py4j.org/getting_started.html

**Orden de lectura sugerido:** la guía de usuario de JPype (sección de conversión de tipos); después la de Py4J, para ver el otro modelo.

---

## 🚀 8. Cierre

Llamar a Java desde Python evita la segunda implementación de un cálculo que ya existe. JPype mete la JVM en el proceso y cada llamada
cuesta microsegundos, a cambio de que un fallo de la JVM se lleve a Python; Py4J la deja en otro proceso, más aislada y mucho más lenta
por llamada, así que se le hacen llamadas gruesas. Los montos cruzan como `BigDecimal` construido desde texto.

**La señal de que quedó bien:** *"El análisis de escenarios usa la misma liquidación que factura, y la prueba de equivalencia corre en el
CI."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-jv-fase-02 -m "op jv02 cerrada: la liquidación Java desde Python, con JPype y Py4J medidos"
> ```
>
> Los commits llevan su prefijo (`op jv02: …`) y los de ejercicio su número
> (`op jv02 ej07: …`).
