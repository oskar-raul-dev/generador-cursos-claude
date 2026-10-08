# 🧪 jv03 — GraalPy y Jython

> Python para desarrolladores Java senior · **Carta** · Track `jv` — Convivir con tu stack Java ·
> sección 3 de 4
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

`jv02` llamó a Java desde Python. La pregunta inversa también aparece en una casa Java: ¿se puede correr Python **sobre la
JVM**, dentro del mismo proceso que el Spring Boot, sin un intérprete aparte? Este perfil seguramente oyó hablar de **Jython**,
que lo prometió durante veinte años, y de **GraalPy**, la implementación de Python de GraalVM, que lo promete ahora.

La sección responde con un veredicto honesto, porque las dos tienen una historia muy distinta. **Jython** sigue en Python 2.7:
no corre el código Python que este curso enseña. **GraalPy** implementa Python 3.13 sobre la JVM de GraalVM, se puede incrustar en
una aplicación Java con unas dependencias de Maven, y tiene un compilador JIT que, una vez caliente, puede ser mucho más rápido
que CPython en código Python puro. El costo está en el arranque, en el calentamiento y en las extensiones en C, que es donde vive
casi todo el ecosistema de datos.

---

## 🧠 2. El modelo

| | CPython 3.14 | GraalPy 25.4.4 | Jython 2.7.4 |
|---|---|---|---|
| Versión del lenguaje | 3.14 | **3.13** | **2.7** |
| Sobre qué corre | Su propio intérprete en C | GraalVM (Truffle + JIT de Graal) | La JVM (HotSpot) |
| Incrustable en Java | No | **Sí**: API *polyglot*, dependencias de Maven | Sí |
| Extensiones en C (NumPy, pandas) | Todas | Muchas, con ruedas propias y a veces compilando | **No** |
| Arranque (`-c pass`, medido) | 0,01 s | 0,16 s (lanzador nativo) | 0,64 s (la JVM) |
| Código Python puro, ya caliente | La referencia | **Mucho más rápido** (el ejemplo lo mide) | Más lento |
| Para qué sirve hoy | Todo | Incrustar Python en una aplicación Java; código Python puro de larga duración | Mantener *scripts* heredados de Python 2 |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de la JVM dice que "un JIT siempre gana a un intérprete". Es cierto **después del calentamiento**, y el ejemplo lo
mide. Pero el trabajo típico de Python en Áurea —un *script* que arranca, procesa un archivo y termina; un proceso que pasa el 90 %
del tiempo dentro de NumPy o de una base— no vive lo suficiente para calentar el JIT, o no corre código Python puro donde el JIT
ayude.

---

## 💻 3. El ejemplo que corre

`cuenta.py` corre igual en CPython y en GraalPy: cinco rondas del mismo cálculo de regalías en Python puro, para ver el
calentamiento.

```python
"""El mismo bucle de Python puro, cinco rondas: para ver el arranque y el calentamiento del JIT."""

import platform
import sys
import time


def royalties(n: int) -> int:
    total = 0
    for i in range(n):
        sales = 100_000_000 + (i * 7919) % 50_000_000
        total += (sales * 450 + 5_000) // 10_000
    return total


print(platform.python_implementation(), sys.version.split()[0])
for round_ in range(1, 6):
    start = time.perf_counter()
    result = royalties(2_000_000)
    print(f"  ronda {round_}: {time.perf_counter() - start:.3f} s  ({result})")
```

```bash
python3 cuenta.py
# GraalPy: descargar graalpy3.13-community-25.4.4 de github.com/oracle/graalpython/releases
./graalpy-community-25.4.4-linux-aarch64/bin/graalpy cuenta.py
```

Y Jython, con una línea de Python moderno:

```bash
java -jar jython-standalone-2.7.4.jar -c 'print "Python 2 sí"'
java -jar jython-standalone-2.7.4.jar -c 'sede = "Suba"; print(f"regalía de {sede}")'
```

Salida (Python 3.14.7, 05/10/2026) (los segundos son de la máquina que corre; estos, de un contenedor en un portátil, con GraalPy community 25.4.4 y Jython 2.7.4 sobre OpenJDK 21):

```text
CPython 3.14.7
  ronda 1: 0.265 s  (11248680650000)
  ronda 2: 0.283 s  (11248680650000)
  ronda 3: 0.267 s  (11248680650000)
  ronda 4: 0.282 s  (11248680650000)
  ronda 5: 0.266 s  (11248680650000)
GraalVM 3.13.14
  ronda 1: 0.180 s  (11248680650000)
  ronda 2: 0.128 s  (11248680650000)
  ronda 3: 0.013 s  (11248680650000)
  ronda 4: 0.012 s  (11248680650000)
  ronda 5: 0.003 s  (11248680650000)
Python 2 s??

  File "<string>", line 1
    sede = "Suba"; print(f"regal??a de {sede}")
                         ^
SyntaxError: no viable alternative at input '"regal??a de {sede}"'
```

El mismo resultado en los dos intérpretes, y dos curvas distintas. CPython tarda lo mismo en las cinco rondas, unos 0,27 s. GraalPy
empieza apenas más rápido (0,18 s) mientras compila, y desde la tercera ronda el JIT ya optimizó el bucle: 0,003 s en la quinta, unas
noventa veces menos. Un bucle de enteros sin llamadas es el mejor caso posible para un JIT; con objetos, `Decimal` o llamadas a bibliotecas,
la ventaja se achica (ejercicio 4). Y Jython hace dos cosas de Python 2 en dos líneas: imprime la "í" como `??` —las cadenas de
Python 2 no son Unicode por defecto— y no reconoce la f-string.

Medido aparte en el mismo contenedor (el mejor de tres `-c pass`): CPython arranca en 0,01 s, GraalPy en 0,16 s y Jython en 0,64 s.

**Detalles con intención**

- **Las cinco rondas** muestran la curva: en CPython son casi iguales; en GraalPy, la primera paga la compilación y las siguientes
  cosechan. Una sola ronda habría dado una conclusión falsa en cualquiera de las dos direcciones.
- **`platform.python_implementation()`** dice en qué Python se está corriendo, y en GraalPy devuelve **`GraalVM`**, no `GraalPy`: el
  código que pregunte por `"GraalPy"` no lo va a encontrar.
- **Jython falla al compilar, no al ejecutar**: las f-strings son de Python 3.6, y Jython no las conoce. Todo el código de este curso
  usa Python 3.

---

## ⚠️ 4. Lo que se rompe

**Las extensiones en C en GraalPy.** NumPy, pandas, `psycopg` y compañía son código en C escrito contra la API de CPython. GraalPy las
soporta con una capa de compatibilidad y publica ruedas para muchas, pero no para todas, y algunas se compilan en la instalación
(lento) o fallan. Antes de adoptarlo, se prueba la lista de dependencias real.

**El calentamiento en *scripts* cortos.** El lanzador de GraalPy es un binario nativo y arranca en 0,16 s —dieciséis veces lo de CPython,
pero no es lo que pesa—. Lo que pesa es que la primera ronda del ejemplo fue solo 1,5 veces más rápida que CPython: un *script* de cron
que termina antes de que el JIT compile no cosecha nada. Y GraalPy incrustado en una aplicación Java arranca con la JVM, que es otra
cuenta.

**Jython para "reutilizar" Python moderno.** No lo corre. Los proyectos que siguen usando Jython lo hacen para *scripts* heredados dentro
de herramientas Java (algunos servidores de aplicaciones, herramientas de pruebas); no es una plataforma para código nuevo.

**La licencia y la edición.** GraalPy tiene una edición *community* (de código abierto) y otra bajo la licencia de Oracle. El ejemplo usa
la *community*; para producción se lee qué permite cada una.

---

## ⚖️ 5. Cuándo NO usarlo

**GraalPy para el trabajo típico de Python en Áurea.** *Scripts* cortos, procesos que pasan el tiempo en bibliotecas en C o esperando a
una base: CPython es la opción.

**Jython para cualquier cosa nueva.** Python 2 dejó de recibir soporte en 2020.

**Incrustar Python en Spring Boot "porque se puede".** Si el código Python es un servicio con su propio ciclo de vida, es un proceso aparte
(`jv04`); incrustarlo junta dos *runtimes* y dos ecosistemas en un despliegue.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `cuenta.py` en CPython y en GraalPy en tu máquina. **Criterio:** la tabla de las cinco rondas, y desde qué ronda gana GraalPy (si
   gana).
2. Mide el arranque de cada uno con `time python3 -c pass` y `time graalpy -c pass`. **Criterio:** los dos tiempos.
3. Corre en Jython un *script* de Python 2 con `print` como sentencia y luego con `from __future__ import print_function`. **Criterio:**
   los dos funcionan, y explicas por qué eso no ayuda con las f-strings.

**🟡 Intermedio (4–6)**

4. Cambia `royalties` para usar `Decimal` y repite la medición. **Criterio:** cómo cambia la ventaja de GraalPy, y por qué.
5. Instala `numpy` en GraalPy (`graalpy -m pip install numpy`). **Criterio:** cuánto tarda, de dónde salió la rueda, y una operación de
   prueba.
6. Corre el mismo bucle con 20 000 iteraciones en vez de 2 000 000. **Criterio:** describes qué pasa con la ventaja cuando el trabajo es
   corto.

**🟠 Difícil (7–9)**

7. Incrusta GraalPy en un programa Java con las dependencias de Maven (`org.graalvm.polyglot:polyglot` y `python-community`) y llama a
   `royalties` desde Java. **Criterio:** Java imprime el mismo total.
8. Pasa un objeto Java (un `List<BigDecimal>`) a una función Python incrustada y suma en Python. **Criterio:** el resultado exacto, y en
   qué tipo llega a Python.
9. Mide el tamaño del *jar* o de la imagen con GraalPy incrustado. **Criterio:** el número, contra el Spring Boot sin él.

**🔴 Muy difícil (10)**

10. Decide si Áurea incrusta Python en algún servicio Java. **Criterio:** una página. *Rúbrica:* (a) el caso concreto y por qué no un
    proceso aparte; (b) las dependencias de Python que necesitaría y si GraalPy las corre; (c) arranque, calentamiento y memoria medidos;
    (d) la licencia.

---

## 📚 7. Referencias

**Documentación oficial**

- GraalPy: https://www.graalvm.org/python/
- GraalPy, documentación (incluye cómo incrustarlo en Java): https://www.graalvm.org/python/docs/
- Versiones de GraalPy: https://github.com/oracle/graalpython/releases
- Jython: https://www.jython.org/

**Orden de lectura sugerido:** la página de inicio de GraalPy, que es clara sobre compatibilidad y rendimiento; después la guía de
incrustación, si el caso existe.

---

## 🚀 8. Cierre

Jython es Python 2 y sirve para *scripts* heredados. GraalPy es Python 3.13 sobre la JVM, incrustable en Java y rápido en código Python puro
de larga duración, a cambio de un arranque lento, un calentamiento que hay que pagar y una compatibilidad parcial con las extensiones en C.
Para el trabajo típico de Python en Áurea, CPython sigue siendo la respuesta.

**La señal de que quedó bien:** *"Alguien propuso correr los scripts del cierre en la JVM, y las cinco rondas medidas decidieron la
conversación."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-jv-fase-03 -m "op jv03 cerrada: GraalPy medido con su calentamiento, y Jython en Python 2"
> ```
>
> Los commits llevan su prefijo (`op jv03: …`) y los de ejercicio su número
> (`op jv03 ej07: …`).
