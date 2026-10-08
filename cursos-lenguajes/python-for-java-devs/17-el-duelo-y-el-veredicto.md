# ⚔️ Fase 17 🏁 ⭐ — El duelo y el veredicto

> Python para desarrolladores Java senior · Fase 17 de 18 · Bloque C · **última fase**
> Depende de: Fase 16 · Habilita: — · Cierra el curso
> Registro de esta fase: **aplicación**
> Proyecto que avanza: **AgendaAPI, implementada dos veces**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Cerrar el curso con la única comparación que te va a servir el lunes —**el mismo endpoint en
FastAPI y en Spring Boot 3, con el mismo arnés**— y con la admisión honesta de dónde el curso se
equivocó.

Diecisiete fases enseñando a elegir el registro correcto no valen nada si no terminan con la
pregunta que las ordena todas: *¿y esto debió escribirse en Python?* A veces no. Y decirlo con
números es lo único que convierte todo lo anterior en criterio en vez de en preferencia.

> **La frase que cierra el curso, y que conviene tener delante al leer la sección 6:** si al final
> resultara que Python ganó todo, el curso estaría mal escrito.

---

## ✅ 2. Qué queda listo al terminar

- [ ] AgendaAPI existe **dos veces** y las dos versiones devuelven exactamente la misma respuesta.
- [ ] Tienes la tabla del duelo con tus números y sus condiciones declaradas.
- [ ] Sabes en cuáles columnas gana cada uno, en cuáles hay **empate**, y cuáles no deciden nada
      al volumen de Áurea.
- [ ] Puedes nombrar **dos decisiones del curso que, con los datos delante, debieron ser otras**.
- [ ] `BENCHMARKS.md` consolida las mediciones de las dieciocho fases.
- [ ] `INSTINTOS.md` recoge los reflejos recurrentes que aparecieron.
- [ ] El miniproyecto de la sección 7 —la defensa— está escrito y se puede leer en voz alta.

---

## 🚫 3. Qué NO entra

Y esta vez es definitivo, porque el curso se acaba:

- **Contenedores y orquestación.** Se usa un contenedor para medir arranque en frío y tamaño de
  imagen, y eso es todo el alcance. Lo demás —redes, volúmenes, orquestación, despliegue— **queda
  declarado fuera y no se enlaza a ninguna parte**: un curso que promete dónde está lo que no
  enseña promete algo que no controla.
- **Optimizar cualquiera de las dos implementaciones más allá de lo razonable.** Las dos están
  configuradas como las configuraría alguien que las conoce, y ahí se paran. Un duelo de
  micro-optimización mide a los duelistas, no a las herramientas.
- **GraalVM native-image y las compilaciones anticipadas de Spring.** Cambiarían la columna del
  arranque en frío de forma importante, y quedan declaradas en §6 como lo que **no** se midió.
- **Comparaciones con Go, Node o Quarkus.** La decisión del curso es un solo competidor: el que
  el lector tiene.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** comparar contra un competidor de paja.

No es mala fe: es que cuando uno lleva meses aprendiendo algo nuevo, quiere que gane. Y la forma
más fácil de que gane es medir contra una versión del otro que nadie defendería — un Spring Boot
con configuración de tutorial, sin ajustar, arrancando con `spring-boot:run` en modo desarrollo,
midiendo la primera petición con el JIT frío.

**Por qué falla aquí más que en ningún otro sitio:** el lector de este curso lleva once años
escribiendo Spring Boot. Va a mirar la configuración del competidor antes que la tabla, y si algo
está mal puesto, **la medición entera deja de valer** — con razón.

**Qué se escribe en su lugar**, y son cuatro condiciones que el duelo de esta fase cumple y que
conviene exigirle a cualquier comparación que leas:

1. **Las dos implementaciones producen el mismo resultado**, verificado byte a byte antes de
   medir. Si una devuelve menos campos o serializa distinto, no están haciendo lo mismo.
2. **Las dos están configuradas para producción**, no para desarrollo. Y eso incluye **tu** lado:
   medir uvicorn con un solo trabajador contra un Spring Boot que usa los ocho núcleos es hacerte
   trampa a ti mismo.
3. **El generador de carga no es el cuello de botella.** Esta es la que más se incumple, y la
   sección 6 tiene su propia confesión al respecto.
4. **Se declara lo que no se midió.** GraalVM, ajustes de JVM, otros escenarios.

> 🧭 **La regla, y vale para leer cualquier *benchmark* del mundo:** antes de mirar los números,
> mira la configuración del que pierde. Si no la publican, los números no significan nada.

### Esto sí funciona igual

Y en esta fase es lo más importante que se puede decir, porque es el resumen del curso:

**Tu criterio de ingeniería no cambió en dieciocho fases.** Qué medir, contra qué comparar, cómo
decidir con datos incompletos, cuándo una diferencia importa y cuándo es ruido, cómo defender una
decisión ante alguien que no es técnico. Todo eso lo trajiste, y todo eso valió.

**Lo que cambió fue el mapa de costos**: qué es barato y qué es caro es distinto en cada
ecosistema, y eso es lo que este curso vino a recalibrar. Un hilo cuesta distinto. Una dependencia
cuesta distinto. Una clase cuesta distinto. La estructura por adelantado cuesta distinto.

**Y lo que no cambió en absoluto es la pregunta:** *¿esto es un script, una herramienta o una
aplicación?* Esa pregunta existía en tu mundo también —solo que allá el lenguaje te obligaba a
responder siempre lo mismo.

### El volumen real de Áurea, antes de mirar ninguna tabla

Esto va aquí a propósito, **antes** de los números, porque es lo que les da su significado:

Áurea tiene **2.800 pacientes activos** y agenda **unas 3.900 citas al mes**. Si cada cita
generara veinte consultas de disponibilidad —que es generoso— serían 78.000 peticiones al mes:
**menos de una peticiones cada treinta segundos** en promedio, con picos de unas pocas por segundo
los lunes por la mañana.

Guarda ese número. Porque la tabla de la sección 6 mide **trece mil peticiones por segundo**, y
la pregunta que hay que hacerse todo el tiempo es: *¿cuál de estas columnas cambia algo para
alguien que hace tres por segundo?*

---

## 💻 5. El duelo, montado

### 5.1 El endpoint, dos veces

El mismo: dado un día y una sede, devolver los 36 espacios de la grilla.

```python
"""FastAPI — el endpoint del duelo."""

from datetime import date, datetime, time, timedelta, timezone
from enum import StrEnum

from fastapi import FastAPI
from pydantic import BaseModel

BOGOTA = timezone(timedelta(hours=-5))


class Branch(StrEnum):
    CENTRO = "centro"
    CHAPINERO = "chapinero"
    SUBA = "suba"
    KENNEDY = "kennedy"
    USAQUEN = "usaquen"


class Slot(BaseModel):
    starts_at: datetime
    minutes: int


class AvailabilityResponse(BaseModel):
    branch: Branch
    day: date
    slots: list[Slot]


app = FastAPI()


@app.get("/availability", response_model=AvailabilityResponse)
def availability(branch: Branch, day: date) -> AvailabilityResponse:
    slots = [
        Slot(starts_at=datetime.combine(day, time(hour, minute), BOGOTA), minutes=20)
        for hour in range(7, 19)
        for minute in (0, 20, 40)
    ]
    return AvailabilityResponse(branch=branch, day=day, slots=slots)
```

```java
// Spring Boot — el mismo endpoint.
@RestController
public class AvailabilityController {

    @GetMapping("/availability")
    public Availability availability(
            @RequestParam Branch branch,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate day) {
        return Availability.of(branch.name().toLowerCase(), day);
    }

    public enum Branch { CENTRO, CHAPINERO, SUBA, KENNEDY, USAQUEN }
}
```

```java
public record Availability(String branch, LocalDate day, List<Slot> slots) {

    private static final ZoneOffset BOGOTA = ZoneOffset.ofHours(-5);

    public record Slot(OffsetDateTime startsAt, int minutes) {}

    public static Availability of(String branch, LocalDate day) {
        List<Slot> slots = new ArrayList<>(36);
        for (int hour = 7; hour < 19; hour++) {
            for (int minute : new int[] {0, 20, 40}) {
                slots.add(new Slot(OffsetDateTime.of(day, LocalTime.of(hour, minute), BOGOTA), 20));
            }
        }
        return new Availability(branch, day, slots);
    }
}
```

Y una pieza más del lado de Java, que existe **para que la comparación sea justa**: un conversor
que acepte la sede en minúsculas, porque el `StrEnum` de Python lo hace de fábrica y sin él las
dos APIs tendrían contratos distintos.

```java
/** Acepta la sede en minúsculas, igual que la API de Python. */
@Component
public class BranchConverter implements Converter<String, Branch> {
    @Override
    public Branch convert(String source) {
        return Branch.valueOf(source.toUpperCase(Locale.ROOT));
    }
}
```

**Prueba de fuego, y es la primera condición de §4:**

```bash
curl -s "http://127.0.0.1:8124/availability?branch=centro&day=2026-10-15" > java.json
curl -s "http://127.0.0.1:8125/availability?branch=centro&day=2026-10-15" > python.json
diff <(jq -S . java.json) <(jq -S . python.json)
```

Si eso no sale vacío —salvo por el nombre del campo `startsAt`/`starts_at`, que es la convención
de cada ecosistema— **no estás midiendo lo mismo** y la tabla no vale.

### 5.2 Cómo se configuró cada lado

Esto es lo que hay que publicar **siempre**, porque es lo que permite que alguien discuta tus
números:

**Spring Boot 3.5.16 sobre Java 21** (Zulu 21.0.8), JAR ejecutable con el Tomcat embebido por
defecto, `logging.level.root=WARN`, banner apagado. Sin ajustes de JVM: los valores por defecto,
que es como lo despliega la mayoría. **No** se usó GraalVM ni compilación anticipada.

**FastAPI 0.141.1 con Uvicorn 0.52.4 sobre CPython 3.14.5**, con nivel de registro `error` y —lo
importante— **medido con uno, dos, cuatro y ocho trabajadores**, porque medir con uno solo sería
compararse con una mano atada: un proceso de Python usa un núcleo, y Spring Boot usa los ocho.

**La máquina:** macOS 26.6, Apple Silicon, 8 núcleos. Todo local, sin red de por medio.

### 5.3 El contenedor, con lo justo

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.14-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
WORKDIR /app
RUN uv pip install --system --no-cache \
    fastapi==0.141.1 uvicorn==0.52.4 pydantic==2.13.5
COPY app_duelo.py .
EXPOSE 8000
CMD ["uvicorn", "app_duelo:app", "--host", "0.0.0.0", "--port", "8000", "--log-level", "error"]
```

```dockerfile
# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY target/agenda-0.17.0.jar app.jar
EXPOSE 8124
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Dos imágenes mínimas y comparables: una base *slim* o *alpine*, una capa de dependencias, una capa
de código. **No hay más contenedor en este curso**, y la razón está en `0-ESTRUCTURA-CURSO.md`:
los contenedores y su orquestación quedan fuera del alcance, y el duelo usa uno solo porque lo
necesita para medir.

Lo único que el duelo necesita de ellos es el arranque en frío y el tamaño — y los dos están en
§6, con una sorpresa.

---

## 📏 6. Medición — el duelo

**Hipótesis.** Spring Boot gana en rendimiento sostenido; FastAPI gana en arranque en frío, en
memoria y en líneas de código. Y al volumen real de Áurea, la mayoría de esas columnas no decide
nada.

**Condiciones.** Las de §5.2. Carga generada con **ApacheBench**, 20.000 peticiones con
concurrencia 32, precedidas de 200 de calentamiento · arranque en frío: mediana de 5 lanzamientos,
desde crear el proceso hasta la primera respuesta `200`, **comprobando que el puerto estuviera
libre antes de cada medición** · memoria: RSS del proceso y de todos sus hijos, en reposo · líneas
contadas sin blancos ni comentarios · contenedores: Docker, mediana de 5 `docker run` hasta la
primera respuesta.

**Competidores.** Los dos, configurados como en §5.2, produciendo la misma respuesta verificada
con `diff`. Y el lado de Python medido con **cuatro configuraciones de despliegue**, porque
publicar solo la de un trabajador sería exactamente el competidor de paja que §4 prohíbe — en
contra de Python, esta vez.

**Resultado — rendimiento sostenido:**

| | req/s | p50 | p95 | p99 |
|---|---|---|---|---|
| **Spring Boot 3.5.16** | **13.834** | **2 ms** | **5 ms** | **8 ms** |
| uvicorn, 1 trabajador | 2.508 | 12 ms | 15 ms | 24 ms |
| uvicorn, 2 trabajadores | 4.410 | 7 ms | 9 ms | 17 ms |
| uvicorn, 4 trabajadores | 6.258 | 4 ms | 7 ms | **9 ms** |
| uvicorn, 8 trabajadores | 6.905 | 4 ms | 9 ms | 20 ms |

**Resultado — arranque, memoria y tamaño:**

| | Spring Boot 3 | FastAPI (1 trab.) | FastAPI (4 trab.) |
|---|---|---|---|
| Arranque en frío | 1.328 ms | **277 ms** | 429 ms |
| RSS en reposo | 216 MB | **54 MB** | 263 MB |
| Líneas de código | 57 Java + 36 `pom.xml` + 3 props | **23** | 23 |
| Artefacto | 22 MB (JAR) | **17 MB** (entorno) | 17 MB |
| Imagen del contenedor | 329 MB | **297 MB** | 297 MB |
| **Arranque del contenedor** | **1.485 ms** | **1.359 ms** | — |

**Y el costo mensual al volumen de Áurea** —78.000 peticiones al mes, menos de tres por segundo en
el pico—, con precios de DigitalOcean consultados el 12 de septiembre de 2026:

| | Memoria que necesita | Máquina | Costo |
|---|---|---|---|
| Spring Boot 3 | 216 MB | 1 vCPU / 1 GiB | **$6/mes** |
| FastAPI (1 trabajador) | 54 MB | 1 vCPU / 1 GiB | **$6/mes** |

> ⚖️ **Veredicto.**
>
> **Spring Boot gana el rendimiento, y no está cerca: 13.834 contra 6.258 peticiones por
> segundo** — **2.2×** contra la configuración de Python bien desplegada, y **5.5×** contra la
> ingenua de un solo trabajador. Su latencia p50 es de 2 ms contra 4. Once años de optimización
> de la JVM y un modelo de hilos que usa los ocho núcleos desde el primer momento: eso es real, y
> el curso no va a fingir lo contrario.
>
> **FastAPI gana el arranque en frío por 4.8×** —277 ms contra 1.328— **y la memoria por 4×** con
> un trabajador. Y gana las líneas de código por **2.5×**: 23 contra 57, y eso sin contar las 39
> líneas de `pom.xml` y configuración que el lado de Java necesita para existir.
>
> **Y ahora los tres empates, que son la parte que casi ningún *benchmark* publica:**
>
> **Empate en el arranque dentro de un contenedor: 1.485 ms contra 1.359 ms.** La ventaja de 4.8×
> que Python tenía en la máquina desnuda **se evapora** cuando el que arranca es Docker: el
> segundo largo que cuesta levantar el contenedor domina, y las dos opciones quedan a un 9% de
> distancia. Si tu despliegue es en contenedores —y hoy casi todos lo son— **el arranque en frío
> deja de ser un argumento a favor de Python.**
>
> **Empate en la memoria, en cuanto igualas el rendimiento.** Python gana 4× con un trabajador…
> y con los cuatro que hacen falta para acercarse a Spring Boot, consume **263 MB contra 216**:
> pierde. Cada trabajador es un intérprete completo, y esa es la letra pequeña de la ventaja de
> memoria de Python.
>
> **Empate en la latencia de cola:** p99 de 9 ms con cuatro trabajadores contra 8 ms de Spring
> Boot. Para una API que atiende personas, esa diferencia no existe.
>
> **Y el empate que decide todo, que es el del costo: $6 al mes, los dos.** Al volumen real de
> Áurea —menos de tres peticiones por segundo— las dos implementaciones caben holgadamente en la
> máquina más barata que alguien pondría en producción. **La columna del rendimiento, que es la
> que más discusión genera, no cambia un peso de la factura de esta empresa.**
>
> **El umbral, que es lo único que hay que llevarse de esta tabla:** el rendimiento empieza a
> decidir alrededor de las **6.000 peticiones por segundo sostenidas**, que es donde Python
> necesitaría una máquina claramente mayor que Java. Áurea está **tres órdenes de magnitud por
> debajo**. Si tu sistema está por encima de ese umbral, esta tabla dice que elijas la JVM; si
> está por debajo —y la mayoría de los sistemas del mundo lo están— **elige por las otras
> columnas**, que son las que sí cambian tu vida: líneas de código, quién lo mantiene, y con qué
> ecosistema tienes que convivir.

**La confesión de método, que forma parte de la medición.** La primera versión de este duelo usó
un generador de carga escrito en Python con `httpx` y `asyncio`, y dio **390 req/s para Spring
Boot y 418 para FastAPI** — números casi idénticos, y por lo tanto sospechosos. Lo eran: el cuello
de botella era el propio cliente, no los servidores. Con ApacheBench, los mismos servidores dieron
13.834 y 2.508. **Un generador de carga que no puede superar al servidor mide al generador**, y
esa es la tercera condición de §4 — incumplida por quien escribió esta fase, encontrada al ver
dos números demasiado parecidos, y publicada aquí porque el error es más instructivo que el
acierto.

**Lo que no se midió, declarado:**

- **GraalVM native-image y la compilación anticipada de Spring Boot**, que reducen el arranque en
  frío de la JVM a decenas de milisegundos y cambiarían esa columna por completo. Se declara
  porque sin esta línea, la comparación de arranque favorece a Python más de lo debido.
- **El *bytecode* de Python compilado en la imagen.** La imagen instala con `uv` sin
  `--compile-bytecode`, así que cada arranque en frío incluye compilar el *bytecode* de FastAPI y
  Pydantic: el costo que la Fase 07 midió en 2.28 s para el primer `import fastapi`. Con
  `--compile-bytecode` la compilación se paga al construir la imagen y el arranque de Python baja;
  cuánto, queda sin medir (⏳). Se declara porque, a diferencia de GraalVM, este ajuste favorece a
  Python.
- **Ajustes de JVM** —tamaño del *heap*, recolector, `-XX:TieredStopAtLevel`—. Los valores por
  defecto son lo que despliega la mayoría, y lo contrario habría que justificarlo para los dos
  lados.
- **El comportamiento con base de datos de por medio**, que es el caso real: ahí la consulta
  domina y las dos tablas se aplanan. La Fase 11 midió que una consulta cuesta 0.51 ms y una
  conexión nueva 3.39 ms — órdenes de magnitud por encima de la diferencia de 2 ms entre los dos
  frameworks.
- **Y el arranque en frío bajo presión de memoria o en una máquina de dos núcleos**, que es la de
  Áurea. Todo esto es un portátil de ocho núcleos, y la Fase 14 ya enseñó lo que eso puede
  esconder.

---

## ⚖️ 6.b El veredicto del curso

Esta sección tiene su propio espacio y no es un párrafo al pie de la tabla anterior, porque es el
contenido del curso y no su cortesía final.

Dieciocho fases para contestar una pregunta —*¿esto es un script, una herramienta o una
aplicación?*— y la respuesta honesta incluye una cuarta opción que hasta ahora se nombró poco:
**o no es de Python**.

### Dónde Python fue la respuesta correcta

**El registro *script*, sin discusión.** Las siete fases del Bloque A construyeron una herramienta
que lee seis formatos, valida seis mil filas reportando todos sus errores, orquesta un binario
ajeno que se cuelga, y guarda un histórico consultable — **con cero dependencias**. El equivalente
en Java empieza con un `pom.xml` y un directorio `src/main/java`, y ninguna cantidad de habilidad
lo hace más corto.

**El pegamento.** RIPS, exports de Odontovía, el cuaderno de Zipaquirá, los portales sin API.
Trabajo irregular, que cambia cada mes, que alguien tiene que poder ajustar sin un despliegue. Ahí
la ceremonia de Java estorba y el registro script gana por goleada.

**Y el back-office**, con los números de la Fase 12: 76 líneas contra 204 para la primera
pantalla, 23 contra 70 para la siguiente. Con cuarenta pantallas y un solo ingeniero, eso no es
una preferencia.

### Dónde Java habría sido mejor, y el curso lo midió

**En el rendimiento de AgendaAPI.** 2.2× en peticiones por segundo con las dos configuradas bien.
Si Áurea fuera una plataforma de agendamiento con cien clínicas, esta fase terminaría
recomendando la JVM.

**En el cálculo de comisiones**, y este duele más porque no es de rendimiento: un sistema de tipos
verificado en compilación habría atrapado en el *build* varios de los errores que la Fase 08
encontró con `mypy` —y `mypy` **hay que acordarse de correrlo**. El curso lo dijo en su fase y
vale la pena repetirlo aquí: el tipado gradual es bueno y no es el compilador.

**Y en la concurrencia del cierre nocturno.** La Fase 14 midió que los hilos no compran nada para
trabajo de CPU —1.02×— y que la salida son procesos con su costo de serialización. En la JVM eso
habría sido un `parallelStream()` y ya. El free-threading acorta esa distancia y no la cierra:
**1.14× sobre la carga real de Áurea**.

### Las dos decisiones del curso que, con los datos delante, debieron ser otras

Esto es lo que el curso se debe a sí mismo, y son dos:

**Una: AgendaAPI no debió construirse primero.** El curso la construye en la Fase 10 porque
necesita enseñar el registro aplicación, y eso es pedagogía, no ingeniería. Con los datos del
dominio delante —el 19% de inasistencia, 3.900 citas al mes, y una administradora que pierde
cuatro días al mes en el cierre— **el orden de valor para Áurea era el CLI, el back-office, el
cierre nocturno, y la API al final**. La API resuelve el problema más visible y no el más caro.

**Dos: el histórico del CLI no debió ser `sqlite3`.** La Fase 06 lo eligió y lo midió bien —252×
más rápido que releer los CSV— y la Fase 15 lo hereda. El problema aparece en la Fase 12: cuando
el back-office necesita los mismos datos, hay dos almacenes con dos verdades. **Con la vista
puesta en dieciocho fases, el histórico debió vivir en Postgres desde el momento en que existió un
Postgres**, y el `sqlite3` debió quedarse en lo que era: el almacén local de un script.

Hay una tercera, más discutible, y se deja dicha: **el curso mide casi todo en un portátil de ocho
núcleos y el dominio tiene una máquina virtual de dos.** Está declarado en cada sección 📏 que
corresponde, y aun así es la debilidad metodológica más grande del material.

### Y la respuesta a la pregunta del curso

> 🧭 **El criterio, destilado en cuatro líneas:**
>
> - **Escríbelo como script** si lo corres tú, cabe en un archivo, y su vida es incierta. La
>   mayoría del trabajo real cae aquí y casi nadie lo acepta.
> - **Conviértelo en herramienta** cuando otra persona tenga que ejecutarlo, cambiarlo o probarlo.
>   Las cinco señales de la Fase 07, contadas antes de decidir.
> - **Hazlo aplicación** cuando tenga que estar disponible sin ti, con estado compartido y más de
>   una puerta de entrada.
> - **Y escríbelo en Java** cuando el rendimiento sostenido decida de verdad, cuando la corrección
>   en compilación valga más que la velocidad de escritura, o cuando el equipo que lo va a heredar
>   ya sea de Java. **Las tres son razones legítimas y ninguna es una derrota.**

---

## 🧱 7. Miniproyecto — *La defensa*

**El encargo**

Julián te escribe: *"Clara —la del consejo, la que puso la plata para la franquicia de Zipaquirá—
quiere que le expliques en qué gastamos el año. Le dije que habías construido cuatro sistemas y me
preguntó si hacía falta. Tiene una hoja de cálculo y ninguna paciencia. ¿Le puedes explicar en
una página qué hicimos y por qué?"*

Escribe **una página** —una, no tres— dirigida a Clara y a Julián, con las decisiones del curso y
sus números: qué se construyó, qué se debió comprar, qué debió quedarse en un script de cuarenta
líneas, y qué debió escribirse en Java.

**Por qué duele**

Porque llegas convencido de que Python ganó —dieciocho fases construyendo con él— y el ejercicio
exige encontrar **al menos dos decisiones donde no fue así**. Y porque escribir una página para
alguien que no es técnica es mucho más difícil que escribir cinco para alguien que sí: hay que
saber cuál número importa, y renunciar a todos los demás.

**Datos de entrada**

Todo lo que mediste en dieciocho fases. Concretamente, los tags:

```bash
git tag -n9 -l 'mini-*'        # tus números, uno por miniproyecto
git tag -n9 -l 'fase-*'        # los checklists de cierre
```

Y `BENCHMARKS.md`, que consolidas en esta misma fase.

**Criterios de aceptación**

- [ ] **Una página.** Si necesitas dos, no has terminado de decidir qué sobra.
- [ ] Cada afirmación comparativa lleva su número, y cada número dice de dónde salió.
- [ ] Ningún término técnico sin explicar en la misma frase. Clara no sabe qué es un *framework* y
      no tiene por qué.
- [ ] **Al menos dos decisiones donde Python no fue la respuesta**, con su justificación.
- [ ] **Al menos una cosa que no debió construirse**, con lo que habría costado comprarla o con la
      razón por la que se podía vivir sin ella.
- [ ] Una recomendación para el año entrante, con su costo.
- [ ] **Medición:** el número que sostiene tu argumento principal, y de qué fase salió. Ese va en
      el mensaje del tag.

**Restricciones de registro**

> Esta vez la restricción no es de código: **es de audiencia**. El entregable es un documento para
> alguien que decide con dinero y no con criterios técnicos. El reflejo que se ataca —y es el
> último del curso— es el de explicar **cómo** se construyó algo cuando lo que se pregunta es
> **por qué**.

**La trampa**

Vas a querer contar el recorrido: el Bloque A, el paquete, la API, el back-office, el cierre. Es
lo que tú viviste y es lo que a ti te parece interesante.

A Clara le interesan tres cosas: **qué se arregló, cuánto costó, y qué falta**. El cierre de mes
pasó de cuatro días de Patricia a un proceso nocturno; el 19% de inasistencia ahora se puede
medir por sede y franja; y hay comisiones de aliados de 2024 que nadie cobró porque no existía el
soporte. **Eso es la página.** El resto es cómo, y el cómo no se pregunta.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Empieza por el final: escribe primero la **recomendación** para el año entrante, en dos frases.
Después escribe hacia atrás lo que hace falta para que esa recomendación sea creíble. Todo lo que
no la sostenga, sobra.

Y para las dos decisiones donde Python no ganó: no las escondas al final. Ponlas donde se vean.
Un informe que solo trae buenas noticias no lo cree nadie que haya dirigido algo.
</details>

<details><summary>Pista 2 — la herramienta</summary>

`git tag -n9 -l 'mini-*'` te devuelve tus dieciocho mediciones con una línea cada una. Es
literalmente para esto que la convención de la Fase 00 las puso ahí.

Y para elegir cuál citar: la que cambie la decisión de Clara. Un número que no cambia ninguna
decisión es un número que sobra en una página.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```markdown
# Qué construimos este año, y qué falta

## El problema que teníamos     (tres frases, con los números de antes)
## Qué se arregló               (con el número de después)
## Qué decidí no construir      (y por qué)
## Dónde me equivoqué           (dos decisiones, con sus datos)
## Qué recomiendo para el año entrante   (con su costo)
```
</details>

**Cómo se entrega**

```bash
$EDITOR DEFENSA.md
```

```bash
git add DEFENSA.md BENCHMARKS.md INSTINTOS.md
git commit -m "fase 17 mini: la defensa"
git tag -a mini-17 -m "Mini F17: la defensa · argumento principal sostenido por <número> (fase <N>)"
```

<details><summary>💡 Solución de referencia — la forma de una defensa</summary>

**La decisión que se tomó**, y es la que hace la página: **el argumento principal es el tiempo de
Patricia, no la tecnología**. Cuatro días al mes de una persona, todos los meses, en un cierre que
ahora corre solo de noche. Eso son cuarenta y ocho días al año que existían y ya no. Clara entiende
ese número sin que nadie le explique qué es un framework, y es verificable.

El otro camino —abrir con el rendimiento de la API— es el que sale solo y es el peor: son 13.834
peticiones por segundo que Áurea no necesita, y citarlos delante de alguien que decide con dinero
invita exactamente a la pregunta que no quieres: *"¿y para qué necesitábamos eso?"*.

**Las dos decisiones donde Python no ganó** se escriben en positivo y sin disculparse: *"la API es
2.2 veces más lenta que su equivalente en Java; a nuestro volumen eso no cambia nada, y si algún
día crecemos veinte veces habría que rehacerla"*. Eso es una advertencia útil y un compromiso
honesto — y le da credibilidad a todo lo demás de la página.

**La trampa, entera.** El informe que cuenta el recorrido es el que escribe quien está orgulloso
del recorrido. Y se nota: Clara va a leer tres párrafos, no va a encontrar un número que le sirva,
y va a concluir que gastó un año en algo que no entiende. **La página no es sobre ti; es sobre las
decisiones que ella tiene que tomar ahora.**

**Y la respuesta a "¿hacía falta?"** merece contestarse de frente en vez de esquivarse: de los
cuatro sistemas, **dos eran urgentes** —el cierre y el back-office, que resuelven tiempo perdido y
un requisito legal—, uno era **importante y no urgente** —la API, que ataca el 19% de
inasistencia—, y del cuarto se puede discutir el orden. Decir eso vale más que defender los
cuatro.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Levanta las dos implementaciones y compara sus respuestas con `diff` sobre el JSON ordenado.
   Documenta cualquier diferencia que encuentres.
2. Mide el arranque en frío de las dos, cinco veces cada una, comprobando que el puerto esté libre
   antes de cada medición.
3. Mide el RSS de las dos en reposo y bajo carga.
4. Cuenta las líneas de las dos implementaciones, sin blancos ni comentarios, incluyendo la
   configuración.
5. Construye las dos imágenes y compara su tamaño y sus capas con `docker history`.
6. Corre `git tag -n9 -l 'mini-*'` y comprueba que tienes los diecisiete números. Si falta alguno,
   esa fase no está cerrada.

**🟡 Intermedio (7–14)**

7. Reproduce la tabla de rendimiento con ApacheBench y después con un generador escrito por ti en
   Python. Documenta la diferencia: es la confesión de §6, reproducida.
8. Mide uvicorn con 1, 2, 4, 8 y 16 trabajadores y encuentra dónde deja de mejorar. Explica por
   qué.
9. Agrega una consulta a Postgres al endpoint en las dos implementaciones y vuelve a medir.
   Reporta cuánto se aplanó la diferencia.
10. Mide el arranque de las dos **dentro del contenedor** y compáralo con el de la máquina
    desnuda. Explica a dónde se fue la ventaja de Python.
11. Configura Spring Boot con `-XX:TieredStopAtLevel=1` y mide de nuevo el arranque en frío.
    Decide si eso cambiaría el veredicto.
12. Mide el consumo de CPU de las dos bajo la misma carga, no solo el rendimiento. Es la columna
    que decide el tamaño de la máquina.
13. Añade validación de un parámetro en las dos —que la fecha no sea pasada— y cuenta cuántas
    líneas costó en cada una.
14. Calcula el costo mensual de las dos al volumen de Áurea con los precios de tu proveedor de
    nube. Después recalcula a diez veces el volumen, y a cien.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Tu medición da números casi idénticos para las dos implementaciones. Enumera
    las tres causas más probables —una está en §6— y cómo descartarlas.
16. **Diagnóstico.** Spring Boot da mejor p50 y peor p99 que FastAPI en tu medición. Investiga la
    causa: tiene que ver con el recolector de basura y con el calentamiento del JIT. Mide para
    confirmarlo.
17. **Medición.** Construye la imagen de Java con GraalVM native-image, mide el arranque en frío, y
    completa la casilla que §6 declara como no medida. Reporta también cuánto tardó la
    construcción.
18. **Medición.** Mide las dos implementaciones **limitadas a dos núcleos** —contenedor con
    `--cpus=2`—, que es la máquina de Áurea. Compara con la tabla de ocho núcleos y di si cambia
    alguna conclusión.
19. **Medición.** Somete las dos a una carga que las sature y mide qué pasa con la latencia de cola
    y con los errores. El comportamiento bajo saturación dice más que el rendimiento máximo.
20. **De registro.** Áurea crece y abre veinte sedes más. Recalcula el volumen, mira la tabla, y
    decide si habría que reescribir AgendaAPI. Justifica con el umbral de §6.
21. **De registro.** Julián propone reescribir el cierre nocturno en Java "porque tarda mucho".
    Responde con los datos de las Fases 14, 15 y 16, y di qué harías antes de considerar
    reescribir nada.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye una medición que haga ganar a Python por goleada, y otra que haga
    ganar a Java por goleada, **sin mentir en ningún número**. Después escribe qué configuración
    cambió en cada caso. Es el ejercicio que te va a hacer desconfiar de todos los *benchmarks* que
    leas después.
23. **Adversarial.** Encuentra un escenario realista de Áurea donde la diferencia de rendimiento de
    §6 **sí** decida algo. Si no lo encuentras, escribe por qué no existe — esa también es una
    respuesta, y es la que los datos sugieren.
24. **Defiende una decisión.** Escribe la crítica más fuerte que puedas al curso entero: qué
    enseñó de más, qué de menos, y qué decisión estructural —el orden de las fases, el dominio, la
    elección de no tener apéndices— habrías tomado distinta. Con argumentos, no con quejas.
25. **La defensa, ampliada.** Toma tu `DEFENSA.md` del miniproyecto y escribe la versión para un
    lector técnico: la misma decisión, los mismos números, dirigida a quien te va a heredar el
    sistema. Compara las dos y anota qué cambió. Es la habilidad que más se te va a pedir y la que
    menos se enseña.

**🔥 Opcionales**

- Implementa el endpoint una tercera vez en Go o en Node y añádelo a la tabla. El curso decidió no
  hacerlo —un solo competidor— y tu propia curiosidad no tiene esa restricción.
- Mide el mismo endpoint en Django REST Framework y compáralo con FastAPI. Es la comparación
  interna que la Fase 12 no hizo.
- Repite el duelo con la API completa —con base de datos, validación y autenticación— en vez de
  con el endpoint mínimo. Es más trabajo y es más representativo.

---

## 📚 9. Referencias

**Documentación oficial**

- [Spring Boot 3.5](https://docs.spring.io/spring-boot/3.5/index.html) — configuración de
  producción y el servidor embebido.
- [FastAPI — Deployment](https://fastapi.tiangolo.com/deployment/) y
  [Uvicorn — Deployment](https://www.uvicorn.org/deployment/) — trabajadores, y por qué uno solo
  no es un despliegue.
- [ApacheBench (`ab`)](https://httpd.apache.org/docs/current/programs/ab.html) — sus límites,
  que son reales: no soporta HTTP/2 y su modelo de concurrencia es simple.
- [Docker — buenas prácticas de imagen](https://docs.docker.com/build/building/best-practices/) —
  capas, caché y tamaño.
- **Y la documentación oficial de Docker Compose** para lo que esta fase declara fuera de
  alcance: redes, volúmenes y todo lo que separa un contenedor de un despliegue.

**Orden de lectura sugerido.** Antes de medir: la página de despliegue de Uvicorn, que explica el
modelo de trabajadores y evita el error de medir con uno solo. Durante: la documentación de `ab`
sobre sus límites. Después: nada — el curso se acabó.

> ⚠️ URLs, versiones y precios cambian. Los de esta fase se verificaron el 12 de septiembre de
> 2026 y el ejercicio 14 te pide recalcularlos con los tuyos.

---

## 🚀 10. Cierre del curso

Empezaste con un archivo de cuarenta líneas que leía un CSV partiendo por comas, mal, a propósito.
Terminaste con cuatro sistemas en producción, dieciocho mediciones propias, y una tabla que dice
—con números que tomaste tú— dónde el lenguaje que acabas de aprender **pierde**.

Lo que te llevas no es Python. Python se aprende en tres meses y ya lo sabes. Lo que te llevas es
la pregunta: **¿esto es un script, una herramienta o una aplicación… o no es de Python?** Y el
hábito de contestarla con el costo de las otras tres opciones en la mano.

Si dentro de tres años estás en una reunión donde alguien propone construir una aplicación para un
problema que eran cuarenta líneas, o migrar a otro lenguaje por un rendimiento que nadie midió, y
tú eres quien pide el número antes de opinar — el curso funcionó.

> **La señal de que quedó bien:** vas a poder defender una decisión técnica delante de alguien que
> no es técnico, con un número, en una página. Y vas a poder decir en voz alta dónde te
> equivocaste.

> 🏷️ **El último tag.** Con el checklist de la sección 2 en verde, la defensa escrita,
> `BENCHMARKS.md` e `INSTINTOS.md` consolidados y `git status` limpio:
>
> ```bash
> git tag -a fase-17 -m "F17 cerrada: el curso completo.
> - AgendaAPI implementada dos veces, con la misma respuesta verificada
> - el duelo medido: 13.834 contra 6.258 req/s, y los tres empates publicados
> - el contenedor medido: la ventaja de arranque de Python se evapora
> - el costo al volumen de Áurea: seis dólares al mes, los dos
> - dos decisiones del curso reconocidas como equivocadas, con sus datos
> - la defensa escrita en una página, para alguien que no es ingeniero"
>
> git tag -n9 -l 'mini-*'    # tus dieciocho números, juntos por primera vez
> ```
