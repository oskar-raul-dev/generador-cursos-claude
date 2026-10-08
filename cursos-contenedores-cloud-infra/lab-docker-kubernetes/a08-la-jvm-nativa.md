# 📎 Apéndice a08 — La JVM nativa: compilación nativa contra AOT cache, medido

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 04](04-empaquetar-los-cuatro-runtimes.md) (B-04), [Fase 15](15-salud-y-recursos.md) (el `Dockerfile.aot`) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** ninguna en el cluster; la compilación nativa necesita **entre 5,3 y 6,0 GB** mientras corre (con 4 GiB de máquina virtual no entra: hay que detener el cluster o darle más memoria)
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. Contesta la pregunta que aparece
cuando alguien ve que `inventory` tarda en arrancar y pesa siete veces lo que `pricing` (B-16): *"¿y si lo compilamos
nativo?"*. Con número, y con lo que se pierde dicho con la misma fuerza que lo que se gana.

**Qué queda fuera:** migrar entre versiones de Java, que queda fuera del curso; el rendimiento sostenido bajo carga
(donde el compilador JIT suele alcanzar a la nativa), que no se midió; GraalVM Enterprise y sus optimizaciones guiadas.

---

## Índice

- [Tres formas de correr el mismo `inventory`](#tres-formas-de-correr-el-mismo-inventory)
- [La tabla](#la-tabla)
- [El AOT cache, puesto al día](#el-aot-cache-puesto-al-día)
- [La compilación nativa: cinco intentos](#la-compilación-nativa-cinco-intentos)
- [Lo que se pierde con la nativa](#lo-que-se-pierde-con-la-nativa)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-6)

---

## Tres formas de correr el mismo `inventory`

El código es el de G13 ([Fase 26](26-idempotencia-y-outbox.md)); cambia cómo llega a la máquina:

1. **La JVM**, con el Dockerfile de siempre ([Fase 04](04-empaquetar-los-cuatro-runtimes.md)): bytecode, el JIT compila lo
   caliente mientras corre.
2. **La JVM con AOT cache** (el `Dockerfile.aot` de la [Fase 15](15-salud-y-recursos.md)): una corrida de entrenamiento al
   construir deja en la imagen las clases ya cargadas y enlazadas y los perfiles de los métodos; al arrancar, la JVM no
   rehace ese trabajo. Sigue siendo la JVM: todo lo demás es igual.
3. **La compilación nativa** con GraalVM: `native-image` analiza el programa entero al construir y produce un ejecutable,
   sin JVM en la imagen. Spring Boot lo soporta con su procesamiento AOT y el perfil `native` de Maven.

## La tabla

Mismo arnés que B-04: build sin caché (una corrida por variante), y tres corridas de arranque y memoria, con `docker run`,
sin base de datos (el SQLite de G1), sin el agente de OpenTelemetry y **sin límite de memoria**. Listo es el primer 200
en `/health/ready`; la memoria, la de `docker stats` 10 s después, y otra vez después de 1.000 peticiones (500 movimientos
y 500 lecturas):

| | Build en frío | Imagen | Listo | Memoria en reposo | Después de 1.000 peticiones |
|---|---|---|---|---|---|
| JVM | 108,3 s | 687 MB | 2,28 s (2,27–2,31) | 332 MiB (329–344) | 357 MiB (342–362) |
| JVM con AOT cache | 122,1 s | 711 MB | 1,31 s (1,31–1,34) | 306 MiB (303–306) | 337 MiB (330–338) |
| **Nativa** | **263,1 s**, con **5,36 GB** de pico | **240 MB** | **0,52 s** (0,52–0,53) | **66 MiB** (66–66) | **77 MiB** (77–78) |

**Lo que dice.** La nativa arranca **4,4 veces más rápido** que la JVM y ocupa **cinco veces menos memoria** en reposo, con
una imagen de un tercio. El AOT cache se queda en el medio en el arranque (1,7 veces más rápido), sin cambiar la memoria
de forma importante. Y la nativa cuesta **2,4 veces el tiempo de build** y una máquina con 6 GB libres para construirla.

> ⚠️ **Sin límite de memoria, la JVM dimensiona su heap contra la máquina virtual entera** (7,75 GiB en esta medición). Con
> el límite de 512 MiB del chart ([Fase 15](15-salud-y-recursos.md)), la JVM ocupa menos; la proporción con la nativa se
> achica, y no la medí con límite.

## El AOT cache, puesto al día

El `Dockerfile.aot` de la [Fase 15](15-salud-y-recursos.md) era de G4: con el código de G13 no compilaba, porque desde G10 `inventory` necesita el
contrato gRPC del contexto de build `proto`. Dos cambios lo pusieron al día, y así quedó en `services/inventory/`
(se construye con `docker build --build-context proto=contracts/proto -f services/inventory/Dockerfile.aot services/inventory`):

```dockerfile
COPY src src
COPY --from=proto pricing src/main/proto/pricing          # G10: el contrato gRPC, como en el Dockerfile
RUN ./mvnw -q -B package -DskipTests
# …
RUN java --enable-native-access=ALL-UNNAMED -XX:AOTCacheOutput=app.aot -Dspring.context.exit=onRefresh -jar inventory-0.0.1-SNAPSHOT.jar
CMD ["java", "--enable-native-access=ALL-UNNAMED", "-XX:AOTCache=app.aot", "-jar", "inventory-0.0.1-SNAPSHOT.jar"]
```

El entrenamiento corre sin base ni vecinos (`spring.context.exit=onRefresh`): arranca el contexto y sale. Es lo que la
JVM de la versión de [a01](a01-el-laboratorio.md) sabe guardar desde las JEP 483 y 515.

## La compilación nativa: cinco intentos

El Dockerfile nativo es corto: GraalVM para construir y una base `distroless` con glibc para correr.

```dockerfile
FROM ghcr.io/graalvm/native-image-community@sha256:0d936f32… AS build
# … el pom, las dependencias, el código y el contrato gRPC, como en el Dockerfile …
RUN ./mvnw -B -Pnative -DskipTests native:compile
RUN mkdir -p /out/data
FROM gcr.io/distroless/base-debian13@sha256:a0d70d6a…
COPY --from=build /src/target/inventory /inventory
COPY --from=build --chown=65532:65532 /out/data /var/lib/inventory
CMD ["/inventory"]
```

Lo que costó llegar a la tabla es la mitad del apéndice. **Cinco intentos**, con el cluster detenido para que
`native-image` tuviera memoria:

1. **Netty con código nativo.** `grpc-netty-shaded` trae BoringSSL por JNI, y `native-image` intenta inicializar esas
   clases al compilar: `Class initialization of io.grpc.netty.shaded.io.netty.internal.tcnative.AsyncSSLPrivateKeyMethod
   failed … UnsatisfiedLinkError`.
2. **Diferir una clase arrastra a otras.** Con las clases de SSL marcadas para inicializarse al arrancar: `An object of
   type 'ch.qos.logback.classic.Logger' was found in the image heap … marked for initialization at image run time`. La
   salida fue diferir **todo** netty, en un `native-image.properties` del proyecto:
   ```properties
   Args = --initialize-at-run-time=io.grpc.netty.shaded.io.netty
   ```
3. **Compiló, y no arrancó**: `Cannot read SQL script from class path resource [schema-sqlite.sql]`. Los `.sql` del
   esquema se cargan por nombre (`Migrator`, G3), y la imagen nativa solo incluye los recursos que alguien declaró:
   ```json
   {"resources": [{"glob": "*.sql"}]}
   ```
   (en `META-INF/native-image/co.coodrosan/inventory/reachability-metadata.json`). Y la carpeta de datos de G1, que el
   Dockerfile de la JVM crea, el nativo no la tenía.
4. **Arrancó en 0,122 s, y devolvió 500** en cada petición: `UnsupportedFeatureError: Record components not available for
   record class co.coodrosan.lab.inventory.StockController…`. Las respuestas van en `ResponseEntity<Object>`, así que el
   procesamiento AOT de Spring no sabe qué *records* va a convertir Jackson a JSON, y la imagen no guarda su reflexión.
5. **Funcionó**, declarando los *records* que viajan por JSON:
   ```java
   @RegisterReflectionForBinding({StockController.StockLevel.class, StockController.MovementRequest.class, …,
           LoanSaga.Loan.class, LoanSaga.LoanStep.class})
   ```

Cada intento fueron entre 2 y 3 minutos de compilación y entre 5,3 y 6,0 GB de memoria pico. Y lo que la tabla no puede
mostrar: **la suite de cada paso se tendría que correr contra la imagen nativa**, porque lo que falla, falla al ejecutar
un camino que no se ejercitó. El 500 del intento 4 lo encontró una lectura; el de una venta, un préstamo o un evento del
outbox, no se buscó.

## Lo que se pierde con la nativa

- **El tiempo de build y la máquina para hacerlo**: 263 s contra 108 s, y 6 GB libres. En un pipeline, es un *runner* más
  grande; en la máquina de Valentina, detener el cluster.
- **La reflexión, los recursos y el código nativo dejan de ser gratis.** Todo lo que Java resuelve en tiempo de ejecución
  —leer un recurso por nombre, convertir un objeto que el compilador no ve, cargar una biblioteca por JNI— hay que
  declararlo antes. Spring lo hace por su código; el tuyo y el de cada biblioteca, no siempre (la nativa del intento 4
  arrancó y fallaba en silencio).
- **El JIT.** La nativa compila todo antes y no optimiza con lo que ve en producción. Para un servicio que corre semanas
  bajo carga, la JVM suele terminar igual o más rápida; no lo medí, y no lo afirmo.
- **Las herramientas de la JVM**: el agente de OpenTelemetry (G10) no se carga en una nativa, y `jcmd` desde un
  contenedor efímero ([Fase 21](21-diagnostico.md)) no tiene a quién hablarle. Las trazas pasan a ser las de la
  instrumentación nativa de Spring, que no se configuró aquí.
- **Lo que se gana**, para que la lista sea justa: 0,52 s de arranque, 66 MiB en reposo y una imagen de 240 MB. Para
  escalar a cero, para un HPA que necesita réplicas en segundos ([Fase 16](16-escalado-y-rollout.md)) o para muchas
  réplicas pequeñas, es la diferencia entre caber y no caber.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| un servicio Java como `inventory`, de larga vida, en el laboratorio | la JVM | lo que funciona hoy, con todas las herramientas |
| el arranque importa (rollouts, picos) y no quieres cambiar nada más | AOT cache | 1,7 veces más rápido, el mismo binario y la misma JVM; solo un paso más en el build |
| escalar a cero, funciones, o muchas réplicas pequeñas | nativa | 4,4 veces más rápido y cinco veces menos memoria, si el equipo paga los metadatos y el build |
| el servicio usa bibliotecas con JNI, reflexión pesada o carga dinámica | la JVM, o nativa después de medir cada camino | cada uno fue un intento fallido aquí |
| el equipo no tiene cómo correr la suite contra la imagen nativa | la JVM | lo que falla en la nativa, falla en producción |

## ⚠️ Advertencias

- Una medición por variante para el build, y tres para el arranque y la memoria. Sin límite de memoria (sección de la tabla).
- La imagen nativa de esta prueba no pasó la suite de G13: se probaron la salud, los movimientos y la lectura de existencias.
- La versión de GraalVM y la de Spring Boot tienen que ir juntas; la de este apéndice, en [a01](a01-el-laboratorio.md).

## 📚 Referencias

- Spring Boot, *GraalVM Native Images*: https://docs.spring.io/spring-boot/reference/packaging/native-image/index.html
- Spring Framework, *Ahead of Time Optimizations* (`@RegisterReflectionForBinding`): https://docs.spring.io/spring-framework/reference/core/aot.html
- GraalVM, *Native Image*: https://www.graalvm.org/latest/reference-manual/native-image/ y *Reachability Metadata*:
  https://www.graalvm.org/latest/reference-manual/native-image/metadata/
- OpenJDK, JEP 483 (*Ahead-of-Time Class Loading & Linking*): https://openjdk.org/jeps/483 y JEP 515
  (*Ahead-of-Time Method Profiling*): https://openjdk.org/jeps/515

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (6)

### Ejercicio 1 — El AOT cache, en el cluster
Despliega la imagen con AOT cache en lugar de la de siempre y mide cuánto tarda el pod en estar `Ready`.

**Criterio:** tres corridas con la de siempre y tres con la de AOT, desde la creación del pod hasta `Ready`, con el límite
de 512 MiB del chart.

### Ejercicio 2 — La memoria, con límite
Repite la tabla con `--memory 512m` en las tres variantes.

**Criterio:** la columna de memoria con límite, y una frase sobre si la proporción con la nativa se mantiene.

### Ejercicio 3 — La nativa contra la suite
Corre la suite de G13 contra la imagen nativa (en compose o en el cluster).

**Criterio:** la lista de lo que falla, con su error. **Pista:** empieza por `/loans` y `/sales`.

### Ejercicio 4 — El intento 4, a propósito
Quita el `@RegisterReflectionForBinding` y encuentra con qué petición falla la nativa.

**Criterio:** la petición, el 500, y la línea `Record components not available` en el log.

### Ejercicio 5 — `pricing`, nativo de nacimiento
Compara el arranque y la memoria de `pricing` (Go) con la nativa de `inventory`.

**Criterio:** la tabla de las dos, y una frase sobre qué compró Go gratis que Java compró con cinco intentos.

### Ejercicio 6 — La recomendación para el Núcleo
En media página: ¿`inventory` en producción debería ser nativo?

**Criterio:** la media página, con la tabla de este apéndice y la lista de lo que se pierde, y la condición que la haría
cambiar (por ejemplo, un HPA que necesite réplicas en menos de un segundo).

---

> 🏷️ **Este apéndice no lleva tag propio.**
