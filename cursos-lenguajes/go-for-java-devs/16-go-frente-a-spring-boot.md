# ⚖️ Fase 16 — Go frente a Spring Boot: el duelo medido ⭐

> Go para desarrolladores Java senior · Fase 16 de 17 · **8 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 15 · Habilita: Fase 17
> Proyecto: **ClearingHouse**, en sus dos implementaciones
> Mini proyectos: ninguno; el banco de pruebas es el laboratorio

---

## 🎯 1. Propósito

Esta es la fase por la que existe el curso.

Llevas quince fases aprendiendo Go con un objetivo que no era aprender Go: poder
sentarte delante de tu arquitecto y responder **con números** la pregunta que
llevas meses oyendo en los pasillos. *¿Migramos este servicio de Spring Boot a Go,
y qué ganamos exactamente?*

Hoy se responde. ClearingHouse está implementado dos veces —la versión Go que
construiste y una Spring Boot 3 equivalente que el curso entrega hecha— y se miden
las dos con el mismo banco, en la misma máquina, con la misma carga.

Y hay una condición que gobierna toda la fase: **el veredicto tiene que doler un
poco en las dos direcciones.** Si tu resultado es "Go gana en todo", la medición
está mal montada o la estás leyendo con los ojos que querías tener. Si es "no
había ninguna diferencia", tampoco. La realidad es más interesante que las dos.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Las dos implementaciones de ClearingHouse pasan **la misma suite de contrato
      HTTP** y producen asientos idénticos sobre los mismos datos.
- [ ] La JVM está medida en **tres configuraciones**: por defecto, ajustada, y
      `native-image`.
- [ ] Tienes las ocho mediciones de §6.3 con sus condiciones declaradas y su
      variabilidad por debajo del 5%.
- [ ] Tienes las cinco métricas que **no** salen en un gráfico y deciden proyectos
      igual.
- [ ] **B-24 está escrita**, con su sección "qué NO demuestra" completa.
- [ ] `docs/veredicto.md` existe: la recomendación que le darías a tu arquitecto,
      con sus condiciones.
- [ ] Sabes nombrar **al menos cuatro casos concretos** donde quedarse en Spring
      Boot es la decisión correcta.
- [ ] Y sabes por qué el resultado de tu medición **no es una tabla para citar en
      una reunión** sin repetir el experimento.

---

## 🚫 3. Qué NO entra todavía

- El capstone y el veredicto general del curso → Fase 17.
- Optimizar cualquiera de las dos implementaciones **durante** la medición → sería
  falsear el experimento. Las optimizaciones se hacen antes, se documentan, y se
  aplican a las dos por igual o a ninguna.
- Kubernetes, escalado horizontal real y coste de infraestructura medido en
  factura → fuera del curso; se estiman y se declara que son estimaciones.
- Comparación con otros stacks (Quarkus, Micronaut, .NET, Rust) → fuera del
  alcance. Se nombran en el ⚖️.

---

## 🧠 4. Concepto mínimo

### Las tres reglas que hacen honesto el experimento

Están en `prompts/formato-de-benchmarks.md` §3 y aquí es donde más filo tienen:

**1. Se prueban todos los competidores, no solo el que queremos que gane.** Si el
curso menciona `native-image`, `native-image` se mide. Si menciona la JVM ajustada,
se ajusta de verdad, con criterio, no con dos banderas puestas para poder decir que
se ajustó.

**2. La JVM se mide ajustada y calentada.** Comparar Go contra una JVM recién
arrancada, con el JIT en modo intérprete y sin ajustar, es hacer trampa. **Y se
nota.** El calentamiento se declara: cuántas peticiones, cuánto tiempo, y cómo se
verifica que el JIT ya compiló lo caliente.

**3. Se publica el resultado incómodo.** Si Java gana en algo —y va a ganar en
varias cosas—, esa fila se escribe igual de grande que las otras.

### Las tres reglas que mantienen honesto al gemelo Java

El gemelo vive en `reference/clearinghouse-spring/` y **se entrega hecho**: el
lector ya sabe escribir Spring Boot, y enseñarlo sería perder el tiempo. Lo que sí
importa es que sea una comparación legítima:

**1. Mismo esquema, mismas migraciones, mismos endpoints, mismo cierre.** Las dos
implementaciones apuntan a la misma base de datos con el mismo `goose`/Flyway sobre
el mismo SQL. Nada de que una tenga un índice que la otra no.

**2. Escrito como lo escribiría un equipo Java competente**, no como un
espantapájaros. Spring Data JPA donde encaja, Spring Batch para el cierre,
Actuator, Micrometer, validación con anotaciones. **Si el gemelo está mal escrito,
la comparación no vale nada y todo el mundo lo sabrá.**

**3. No se enseña a escribirlo.** Se lee, se compara y se mide.

> ⚠️ **El gemelo todavía no se publica con el curso.** `reference/clearinghouse-spring/`
> está pendiente, así que hoy esta fase se lee y se prepara —la suite de contrato, el
> conjunto de datos, los comandos de B-24—, pero el duelo no se puede correr con el
> material del curso. Si quieres correrlo ya, el gemelo lo escribes tú con las tres
> reglas de arriba, y la regla de la suite de contrato pasa a ser también tu prueba de
> que lo escribiste bien.

> 🧭 **Regla del proyecto.** Antes de medir nada, **las dos implementaciones tienen
> que pasar la misma suite de contrato HTTP y producir asientos byte a byte
> idénticos** sobre el mismo conjunto de datos. Si no lo hacen, no estás comparando
> dos implementaciones del mismo servicio: estás comparando dos servicios
> distintos, y cualquier número que salga es ruido.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"la JVM es lenta"*. Es un reflejo que muchos desarrolladores de
Java han interiorizado **de sus propios usuarios**: la aplicación tarda en
arrancar, consume mucha memoria, y el primer usuario de la mañana espera.

**Qué pasa si lo aplicas.** Mides el arranque en frío, ves 4,2 segundos frente a 18
milisegundos, y concluyes que Go es 230 veces más rápido. Y entonces mides el
**rendimiento sostenido** y la diferencia casi desaparece — o se invierte.

**Por qué.** La JVM no es lenta: **es lenta al principio**. Y la razón es que su
modelo de ejecución es distinto, no peor:

```mermaid
flowchart TD
    subgraph JV["JVM"]
        direction LR
        J1["arranque"] --> J2["interpretar bytecode"] --> J3["perfilar qué<br/>se ejecuta mucho"]
        J3 --> J4["compilar a código<br/>máquina con C1"] --> J5["recompilar con C2 optimizando<br/>AGRESIVAMENTE con la información<br/>de ejecución real"]
    end
    subgraph GO["Go"]
        direction LR
        G1["compilar todo a código máquina ANTES"] --> G2["ejecutar"]
    end
    JV ~~~ GO
```

El JIT de la JVM **sabe cosas que un compilador anticipado no puede saber**: qué
ramas se toman de verdad, qué tipos llegan realmente a un punto polimórfico, qué
métodos merece la pena incorporar. Con esa información hace optimizaciones que Go
no puede hacer: desvirtualización especulativa, *inlining* agresivo guiado por
perfil, eliminación de comprobaciones de rango basada en el comportamiento real.

**El precio es el calentamiento.** Los primeros segundos —o minutos, según la
carga— la JVM ejecuta código peor que Go. Después, puede ejecutar código **mejor**.

**Qué pensar en su lugar.** La pregunta no es "¿cuál es más rápido?". Es **"¿cuál
es el perfil de ejecución de mi servicio?"**:

| Perfil | Quién gana | Por qué |
|---|---|---|
| Proceso efímero que arranca, hace su trabajo y muere | **Go, claro** | la JVM nunca llega a calentarse |
| Función serverless con arranques en frío frecuentes | **Go, claro** | ídem, y la memoria se factura |
| Servicio de larga duración con carga sostenida | **empate, o JVM** | la JVM se calienta y el JIT trabaja |
| Escalado horizontal agresivo (sube y baja réplicas) | **Go** | cada réplica nueva paga el arranque |
| Servicio con carga muy variable | **depende** | el JIT se "enfría" en los valles |

> 🧠 **Modelo mental.** Go es un **velocista constante**; la JVM es una **corredora
> de fondo que necesita calentar**. Preguntar cuál corre más rápido sin decir la
> distancia no tiene respuesta.

### Y el instinto contrario, que también hay que desmontar

**El instinto:** *"con `native-image` Java arranca igual que Go, así que no hay
diferencia"*.

`native-image` de GraalVM compila la aplicación anticipadamente a un binario
nativo. Los arranques bajan a decenas de milisegundos y la memoria residente cae
mucho. **Es una tecnología impresionante y cambia la conversación de verdad.**

Y tiene costes concretos que hay que medir, no suponer:

- **La compilación es lentísima.** Minutos frente a segundos, y en un pipeline de
  CI eso se nota cada día.
- **Se pierde el JIT**, así que **el rendimiento sostenido suele ser peor que el de
  la JVM caliente**. Se cambia arranque por techo.
- **La reflexión, los *proxies* dinámicos y la carga dinámica de clases necesitan
  configuración explícita.** Spring Boot 3 lo soporta oficialmente con sus *hints*,
  y aun así hay librerías que no funcionan o requieren trabajo.
- **El ecosistema de diagnóstico cambia**: JFR funciona con limitaciones, y
  herramientas que dabas por hechas puede que no.

**Por eso las tres configuraciones se miden.** La conclusión honesta puede ser que
`native-image` cierra la brecha de arranque y abre otra de rendimiento — y que la
elección depende de cuál te importa.

### 🩻 Esto sí funciona igual

- **El método de medición** es el mismo que la Fase 15 dejó montado, y se aplica a
  los dos por igual.
- **Los percentiles, no las medias.** Igual de cierto en los dos lados.
- **La omisión coordinada** afecta a las dos mediciones por igual, y hay que
  evitarla en las dos.
- **El calentamiento se declara**, y aunque Go lo necesite menos, también tiene
  cachés frías, planes de consulta sin calentar y conexiones por abrir.
- **Las condiciones se registran con el resultado.** Un número sin máquina, sin
  versión y sin carga no es reproducible en ninguno de los dos idiomas.
- **Y el criterio de arquitectura es el mismo.** La decisión de migrar no la toman
  los benchmarks: los benchmarks informan una decisión que es de equipo, de
  plataforma y de negocio.

---

## 🛠️ 5. CLI de la fase

```bash
# ─── Preparar las dos implementaciones ───────────────────────────────────────
make build SVC=clearinghouse

cd reference/clearinghouse-spring
./mvnw clean package -DskipTests                 # JAR
./mvnw -Pnative native:compile -DskipTests       # native-image (tarda minutos)
cd -

# Tiempo de compilación desde limpio: es una de las ocho mediciones.
go clean -cache && time make build SVC=clearinghouse
cd reference/clearinghouse-spring && ./mvnw clean && time ./mvnw package -DskipTests

# ─── LAS TRES CONFIGURACIONES DE LA JVM ──────────────────────────────────────

# 1. Por defecto: sin banderas. Es lo que un equipo despliega sin pensar.
java -jar target/clearinghouse.jar

# 2. Ajustada. Cada bandera con su porqué, no un copiar y pegar:
java \
  -XX:+UseG1GC \
  -XX:MaxRAMPercentage=75.0 \         # respeta el límite del contenedor
  -XX:InitialRAMPercentage=50.0 \     # arranca con heap grande: menos GC inicial
  -XX:MaxGCPauseMillis=100 \          # objetivo de pausa, comparable a Go
  -XX:+UseStringDeduplication \       # G1 deduplica strings iguales
  -XX:+TieredCompilation \            # C1 rápido y después C2 optimizado
  -XX:+AlwaysPreTouch \               # toca las páginas al arrancar: sin fallos después
  -Xss512k \                          # pilas más pequeñas: más hilos por memoria
  -XX:+ExitOnOutOfMemoryError \       # morir rápido en vez de agonizar
  -jar target/clearinghouse.jar

# Y las que mejoran el ARRANQUE, que es donde la JVM más pierde:
java \
  -XX:TieredStopAtLevel=1 \           # solo C1: arranca antes, techo más bajo
  -XX:+UseSerialGC \                  # GC más simple: menos hilos al arrancar
  -Xshare:auto \                      # archivo de clases compartido
  -XX:SharedArchiveFile=app.jsa \     # AppCDS: clases preprocesadas
  -jar target/clearinghouse.jar
#
# ⚠️ Estas dos configuraciones son INCOMPATIBLES entre sí: la de arranque baja el
# techo de rendimiento. Hay que medir las dos y decir cuál es cuál.

# Generar el archivo AppCDS, que es la optimización de arranque más rentable de
# la JVM y casi nadie la usa:
java -XX:ArchiveClassesAtExit=app.jsa -jar target/clearinghouse.jar &
sleep 20 && kill %1

# 3. native-image
./target/clearinghouse

# ─── MEDIR ───────────────────────────────────────────────────────────────────

# ARRANQUE EN FRÍO hasta la PRIMERA PETICIÓN SERVIDA. Ese es el número, no el
# "started in X" del log: un servicio que dice que arrancó y tarda 400 ms más en
# atender no arrancó.
scripts/bench/cold-start.sh ./bin/clearinghouse
scripts/bench/cold-start.sh "java -jar target/clearinghouse.jar"

# MEMORIA RESIDENTE. RSS es lo que el sistema operativo dice que ocupa el
# proceso, y es lo comparable. El heap de la JVM NO es comparable con el heap de
# Go: la JVM tiene además metaespacio, pilas, buffers directos y el propio
# runtime.
ps -o rss= -p $(pgrep -f clearinghouse) | awk '{printf "%.1f MB\n", $1/1024}'
/usr/bin/time -v ./bin/clearinghouse 2>&1 | grep 'Maximum resident'

# LATENCIA Y RENDIMIENTO, con ritmo fijo para evitar la omisión coordinada.
vegeta attack -targets=scripts/bench/targets.txt -rate=500 -duration=120s \
  | tee results.bin | vegeta report
vegeta report -type='hist[0,5ms,10ms,25ms,50ms,100ms,250ms,500ms,1s]' < results.bin

# CPU POR PETICIÓN: tiempo de CPU consumido dividido entre peticiones servidas.
# Es la métrica que se traduce a factura y casi nadie la mide.
cat /proc/$(pgrep -f clearinghouse)/stat | awk '{print "utime:", $14, "stime:", $15}'
ps -o time= -p $(pgrep -f clearinghouse)     # macOS

# PICO DE 10×: la carga sube de golpe y se mira si se recupera.
vegeta attack -targets=targets.txt -rate=50  -duration=60s > baseline.bin
vegeta attack -targets=targets.txt -rate=500 -duration=30s > spike.bin
vegeta attack -targets=targets.txt -rate=50  -duration=60s > recovery.bin

# EL CIERRE DE UN MILLÓN, extremo a extremo.
./bin/clearinghouse seed --movements 1000000 --seed 42
time ./bin/clearinghouse close --day 2026-09-11 --chunk-size 5000
time java -jar target/clearinghouse.jar --batch --day=2026-09-11 --chunk-size=5000

# IMÁGENES
docker images | grep -E 'clearinghouse'
docker history meridian/clearinghouse-spring:jvm --format '{{.Size}}\t{{.CreatedBy}}' | head

# ─── LO QUE NO SALE EN UN GRÁFICO ────────────────────────────────────────────

# Líneas de código, sin tests ni generado.
tokei services/clearinghouse --exclude '*_test.go'
tokei reference/clearinghouse-spring/src/main

# Dependencias TRANSITIVAS, que es el número que importa.
go list -m all | wc -l
cd reference/clearinghouse-spring && ./mvnw dependency:tree | grep -c '^\[INFO\]    '

# Y el tamaño real de lo que descargas.
du -sh $(go env GOMODCACHE)
du -sh ~/.m2/repository
```

> 💡 **`cold-start.sh` mide lo correcto, y es la diferencia entre una comparación
> honesta y una tramposa.** No mide *"el log dice que arrancó"*: mide desde que se
> lanza el proceso hasta que **una petición HTTP recibe una respuesta correcta**.
> Spring Boot imprime *"Started Application in 2.4 seconds"* y después tarda otros
> cientos de milisegundos en servir la primera petición, porque el `DispatcherServlet`
> se inicializa perezosamente. Go también tiene su parte: el pool de conexiones
> abre la primera conexión en la primera consulta.

---

## 💻 6. Construcción guiada

### 6.1 El montaje: que la comparación sea legítima

**Antes de medir, verificar que son el mismo servicio.**

```go
// reference/contract/contract_test.go
//
// La suite de contrato HTTP de la Fase 05, apuntada a cualquiera de las dos
// implementaciones mediante una variable de entorno.
//
// Si las dos no pasan la MISMA suite, no hay comparación que hacer.
func TestContract(t *testing.T) {
	base := os.Getenv("CLEARINGHOUSE_URL")
	if base == "" {
		t.Skip("CLEARINGHOUSE_URL no definida")
	}

	for _, tc := range contractCases {
		t.Run(tc.name, func(t *testing.T) {
			resp := do(t, base, tc.method, tc.path, tc.body)

			if resp.StatusCode != tc.wantStatus {
				t.Fatalf("%s %s = %d, quería %d", tc.method, tc.path,
					resp.StatusCode, tc.wantStatus)
			}
			if tc.wantBodyMatch != nil {
				tc.wantBodyMatch(t, resp.Body)
			}
		})
	}
}
```

```bash
CLEARINGHOUSE_URL=http://localhost:8080 go test ./reference/contract -v   # Go
CLEARINGHOUSE_URL=http://localhost:8081 go test ./reference/contract -v   # Java
```

**Y la verificación que de verdad cierra la puerta: los asientos idénticos.**

```bash
# Las dos implementaciones cierran el MISMO día con los MISMOS movimientos,
# contra bases de datos separadas pero con el mismo esquema y los mismos datos.
./bin/clearinghouse seed --movements 1000000 --seed 42 --dsn "$DSN_GO"
psql "$DSN_JAVA" -c "..." # misma semilla, mismos datos

./bin/clearinghouse close --day 2026-09-11 --dsn "$DSN_GO"
java -jar target/clearinghouse.jar --batch --day=2026-09-11

# Y el diff. Si no es vacío, hay un bug en una de las dos y no se mide nada
# hasta arreglarlo.
psql "$DSN_GO"   -Atc "SELECT movement_id, account, amount_minor, currency FROM ledger_entries ORDER BY movement_id, account" > go.csv
psql "$DSN_JAVA" -Atc "SELECT movement_id, account, amount_minor, currency FROM ledger_entries ORDER BY movement_id, account" > java.csv
diff go.csv java.csv && echo "✅ asientos idénticos"
```

> 🧪 **Prueba de fuego.** Corre el `diff` **antes** de la primera medición.
>
> **La mentira de la pantalla:** si las dos suites de contrato pasan, es tentador
> dar por buena la equivalencia. **No basta.** La suite de contrato verifica la API;
> el `diff` de asientos verifica la **lógica de negocio**, que es lo que el cierre
> hace de verdad. Si difieren en tres asientos de un millón, tienes un bug de
> redondeo o de zona horaria en una de las dos — y probablemente es interesante.

**Las condiciones, declaradas y registradas automáticamente:**

```bash
#!/usr/bin/env bash
# scripts/bench/conditions.sh — se ejecuta antes de cada medición.
cat <<EOF
# ── CONDICIONES ──────────────────────────────────────────────────────────────
# fecha:        $(date -u +%Y-%m-%dT%H:%M:%SZ)
# máquina:      $(uname -srm)
# cpu:          $(sysctl -n machdep.cpu.brand_string 2>/dev/null || lscpu | grep 'Model name' | cut -d: -f2)
# núcleos:      $(getconf _NPROCESSORS_ONLN)
# ram:          $(( $(sysctl -n hw.memsize 2>/dev/null || echo $(free -b | awk '/Mem:/{print $2}')) / 1073741824 )) GB
# go:           $(go version)
# jdk:          $(java -version 2>&1 | head -1)
# graalvm:      $(native-image --version 2>/dev/null | head -1 || echo "no instalado")
# postgres:     $(docker compose exec -T postgres postgres --version)
# commit:       $(git rev-parse --short HEAD)
# carga previa: $(uptime | sed 's/.*load/load/')
# aislamiento:  contenedores con cpus=4, memory=2g; generador de carga en
#               $([ -n "$REMOTE_LOADGEN" ] && echo "máquina separada" || echo "LA MISMA MÁQUINA ⚠️")
EOF
```

> ⚠️ **Si el generador de carga corre en la misma máquina, hay que declararlo** —
> como hace el guion— y asumir que los números de latencia bajo carga alta están
> contaminados. Es una limitación aceptable para un curso y **tiene que aparecer en
> la sección "qué NO demuestra"** de B-24.

### 6.2 El calentamiento, que es la mitad de la honestidad

```bash
#!/usr/bin/env bash
# scripts/bench/warmup.sh
#
# La JVM necesita calentarse. Go necesita menos, y también algo: conexiones de
# base de datos abiertas, planes de consulta en caché, y el asignador estabilizado.
#
# El mismo calentamiento se aplica a las DOS. Eso es lo que lo hace justo.
set -euo pipefail
URL="${1:?uso: warmup.sh <url>}"

echo "→ calentando $URL"

# 1. Esperar a que responda.
until curl -sf "$URL/health" > /dev/null 2>&1; do sleep 0.1; done

# 2. Carga de calentamiento: 60 s a ritmo moderado, ejercitando TODAS las rutas
#    que se van a medir. Una ruta no calentada se compila en la medición.
echo "GET $URL/batches
GET $URL/movements?limit=50
POST $URL/movements" | \
  vegeta attack -rate=100 -duration=60s > /dev/null

# 3. VERIFICAR que la JVM calentó de verdad, en vez de suponerlo.
#    Si el servicio es Java, se comprueba cuánto compiló el JIT.
if [[ "$URL" == *:8081* ]]; then
  jcmd $(pgrep -f clearinghouse.jar) Compiler.codelist 2>/dev/null | wc -l
  jcmd $(pgrep -f clearinghouse.jar) VM.native_memory summary 2>/dev/null | head -20
fi

# 4. Estabilizar: una recolección forzada y un respiro, para que la medición no
#    empiece justo antes de una.
sleep 5
echo "→ calentado"
```

> 🧭 **Regla del proyecto.** **El calentamiento se aplica igual a los dos y se
> verifica, no se supone.** Sesenta segundos a 100 peticiones por segundo son 6.000
> peticiones: suficiente para que C2 haya compilado las rutas calientes. Declararlo
> en la entrada del banco es obligatorio; sin eso, cualquiera puede sospechar —con
> razón— que la JVM se midió fría.

### 6.3 Las ocho mediciones

**1. Arranque en frío hasta la primera petición servida.**

```bash
#!/usr/bin/env bash
# scripts/bench/cold-start.sh
set -euo pipefail
CMD="${1:?uso: cold-start.sh '<comando>'}"
PORT="${2:-8080}"
RUNS="${3:-10}"

for i in $(seq 1 $RUNS); do
  start=$(python3 -c 'import time; print(time.time_ns())')
  $CMD > /dev/null 2>&1 &
  pid=$!

  # El bucle es sin espera: cada intento cuesta microsegundos, así que la
  # resolución es buena. Con `sleep 0.1` entre intentos, el error sería de hasta
  # 100 ms — que es la mitad del tiempo de arranque de Go.
  until curl -sf "http://localhost:$PORT/health" > /dev/null 2>&1; do
    kill -0 $pid 2>/dev/null || { echo "el proceso murió"; exit 1; }
  done

  end=$(python3 -c 'import time; print(time.time_ns())')
  echo "scale=1; ($end - $start) / 1000000" | bc

  kill $pid 2>/dev/null; wait $pid 2>/dev/null || true
  sleep 2   # que el sistema se estabilice entre corridas
done
```

> ⚠️ **Los tres factores que contaminan esta medición y hay que controlar:** la
> caché de página del sistema operativo (la primera corrida lee el binario del
> disco y las siguientes de RAM — por eso se descarta la primera), el arranque de
> PostgreSQL (tiene que estar ya caliente y con conexiones disponibles), y el
> `AlwaysPreTouch` de la JVM, que **empeora el arranque y mejora el régimen
> estacionario**. Si se usa, hay que decirlo.

**2. Memoria residente en reposo y bajo carga.**

```bash
# En reposo: 60 s después de arrancar, sin tráfico.
# Bajo carga: durante los últimos 30 s de una carga sostenida de 120 s.
# Y el PICO, que es lo que dimensiona el contenedor.
```

> ⚠️ **Comparar el heap de Go con el heap de la JVM es un error.** La JVM tiene,
> además del heap: metaespacio, pilas de hilos, buffers directos, código compilado
> por el JIT, y el propio runtime. **RSS es la única cifra comparable**, y es la que
> factura tu proveedor de nube.
>
> Y el matiz honesto en dirección contraria: **Go tampoco devuelve la memoria al
> sistema operativo de forma agresiva**. Un proceso Go que tuvo un pico puede
> mantener el RSS alto un buen rato aunque el heap vivo sea pequeño. `GOMEMLIMIT` y
> `debug.FreeOSMemory()` influyen. Hay que declarar cómo se midió.

**3. Latencia p50/p95/p99 y rendimiento sostenido.**

```bash
for rate in 50 100 250 500 1000 2000; do
  echo "→ $rate req/s"
  vegeta attack -targets=targets.txt -rate=$rate -duration=60s \
    | vegeta report -type=json | jq -r '
      "\(.rate) \(.latencies.p50/1000000) \(.latencies.p95/1000000) \(.latencies.p99/1000000) \(.success)"'
done
```

**El número que de verdad importa no es la latencia a un ritmo fijo: es el ritmo al
que el p99 se dispara.** Esa es la capacidad real, y es lo que dimensiona el
despliegue.

**4. CPU por petición.**

```text
CPU por petición = (utime + stime) / peticiones servidas
```

Es la métrica que se traduce directamente a coste, y **casi nadie la mide**. Un
servicio con la misma latencia y la mitad de CPU por petición cuesta la mitad al
escalar.

**5. El cierre de un millón de movimientos, extremo a extremo.**

```bash
./bin/clearinghouse seed --movements 1000000 --seed 42
time ./bin/clearinghouse close --day 2026-09-11 --chunk-size 5000
time java -jar target/clearinghouse.jar --batch --day=2026-09-11 --chunk-size=5000
```

> 💡 **Esta es la medición donde Spring Batch puede sorprender**, y por eso es
> interesante. El `JdbcBatchItemWriter` agrupa inserciones de forma muy eficiente,
> el `JdbcCursorItemReader` está muy optimizado, y **la JVM tiene noventa minutos
> para calentarse**. Es exactamente el perfil donde el JIT trabaja a su favor.
>
> Y hay que medir además la memoria máxima y el tiempo hasta el primer fragmento
> confirmado, porque el total esconde el arranque.

**6. Tamaño de imagen y tiempo de compilación desde limpio.**

Reutiliza B-21 (Fase 14) para el tamaño, y añade el tiempo de construcción — que en
un pipeline que corre cincuenta veces al día es un coste real.

**7. Comportamiento bajo un pico de diez veces el tráfico.**

```bash
vegeta attack -rate=50  -duration=60s > baseline.bin
vegeta attack -rate=500 -duration=30s > spike.bin
vegeta attack -rate=50  -duration=60s > recovery.bin
```

**Tres preguntas:** ¿cuánto sube el p99 durante el pico? ¿Cuántas peticiones se
rechazan o fallan? Y la que más enseña: **¿cuánto tarda en volver a la línea base
después?**

> 💡 **Aquí la JVM tiene un comportamiento propio que hay que buscar:** un pico de
> carga puede disparar recompilaciones del JIT, deoptimizaciones y recolecciones
> más frecuentes. La curva de recuperación de la JVM suele ser más larga, y **esa
> es una diferencia real que no sale en una medición de régimen estacionario**.

**8. La JVM en sus tres configuraciones.**

Ya descritas en §5. Las tres se miden en todo lo anterior, y las filas de la tabla
son **cinco**: Go, JVM por defecto, JVM ajustada para rendimiento, JVM ajustada
para arranque, y `native-image`.

### 6.4 Lo que no sale en un gráfico y decide proyectos igual

**Cinco métricas, y suelen pesar más que las ocho anteriores.**

**1. Líneas de código.**

```bash
tokei services/clearinghouse --exclude '*_test.go'
tokei reference/clearinghouse-spring/src/main
```

> ⚠️ **Y hay que medirlo con honestidad, porque es la métrica más fácil de
> manipular.** Cuenta por separado: lógica de negocio, configuración/cableado,
> infraestructura escrita a mano (lo que el framework daría), y tests. **La
> comparación interesante no es el total: es cuánta infraestructura tuviste que
> escribir en Go que en Spring venía hecha.** El cierre por lotes de la Fase 13 lo
> midió: 520 líneas frente a 180.

**2. Dependencias de tercero.**

```bash
go list -m all | wc -l
cd reference/clearinghouse-spring && ./mvnw dependency:tree | grep -c '^\[INFO\]    '
```

**El número transitivo, no el declarado.** Y lo que de verdad importa: **superficie
de actualización y de vulnerabilidades**. Un proyecto con 400 dependencias
transitivas tiene 400 posibles CVE y 400 posibles cambios incompatibles.

**3. Tiempo hasta el primer endpoint funcionando.**

Con un desarrollador que conoce el stack: en Spring Boot, minutos —`start.spring.io`,
un `@RestController`, arrancar—. En Go, más, porque el enrutado, la decodificación y
el manejo de errores se escriben.

**Es una ventaja real de Spring Boot y conviene reconocerla.** Lo que cambia es qué
pasa en el mes tres, cuando el proyecto tiene veinte endpoints y hay que depurar
por qué una anotación no se aplica.

**4. Madurez del ecosistema por área.**

| Área | Java | Go | Comentario honesto |
|---|---|---|---|
| Web / REST | ★★★★★ | ★★★★☆ | Go cubre lo esencial; Spring hace mucho más |
| Persistencia relacional | ★★★★★ | ★★★☆☆ | JPA/Hibernate no tiene equivalente. `sqlc` se acerca |
| Procesamiento por lotes | ★★★★★ | ★★☆☆☆ | **Spring Batch no tiene rival.** Fase 13 |
| Mensajería | ★★★★★ | ★★★☆☆ | Clientes buenos; la integración es más artesanal |
| Observabilidad | ★★★★★ | ★★★★☆ | Actuator y JFR por delante; OTel iguala las trazas |
| Seguridad / OAuth / SAML | ★★★★★ | ★★☆☆☆ | **Spring Security es enorme.** Brecha grande |
| Concurrencia | ★★★★☆ | ★★★★★ | Go gana en modelo; Java 21 recortó mucho |
| Herramientas de línea de comandos | ★★☆☆☆ | ★★★★★ | Un binario estático no tiene rival |
| Contenedores / nube | ★★★☆☆ | ★★★★★ | Arranque, huella, imágenes |
| Científico / ML / datos | ★★★★☆ | ★★☆☆☆ | Go casi no está |
| Depuración en producción | ★★★★★ | ★★★☆☆ | JFR es superior a `pprof` |

**5. Facilidad de contratar.**

El dato incómodo: **hay muchos más desarrolladores de Java que de Go**, y la
diferencia es de un orden de magnitud en la mayoría de los mercados. Migrar a Go
significa un mercado de contratación más pequeño y un periodo de formación para el
equipo actual.

**Y el dato en dirección contraria:** Go se aprende rápido. Este curso son 131
horas. Un desarrollador de Java senior es productivo en Go en semanas, no en meses
— que es lo que tarda alguien en ser productivo en un proyecto Spring grande y
ajeno.

### 6.5 Cómo leer los resultados sin engañarse

**Tres errores de lectura, y los tres son fáciles de cometer:**

**1. El titular sin la condición.** *"Go arranca 200 veces más rápido"* es cierto y
**es irrelevante para un servicio que arranca una vez a la semana**. Cada número
tiene un contexto donde importa y otro donde no.

**2. Extrapolar.** `prompts/formato-de-benchmarks.md` §3 regla 8 lo prohíbe: que el cierre
de un millón tarde X **no autoriza** a afirmar nada sobre diez millones. Los
recolectores, las cachés y los índices no escalan linealmente.

**3. Confundir la medición con la decisión.** Los números informan; no deciden. Un
equipo de veinte personas con quince años de Spring, una plataforma montada y un
servicio que cumple sus objetivos **no debería migrar aunque Go gane en las ocho
mediciones**.

> 🧭 **Advertencia de método, y va escrita en la fase y en B-24.** Estos números
> son de **una** máquina, **una** carga y **una** versión de cada stack. Enseñan a
> medir; **no son una tabla para citar en una reunión sin repetir el experimento**.
> Si alguien usa tus números para decidir sobre un sistema que no es este, le estás
> haciendo un flaco favor.

### 6.6 🔥 Sección opcional: gRPC en los dos stacks

Es la pregunta que siempre aparece cuando alguien dice "microservicios", y por eso
está aquí — fuera del recorrido base.

```protobuf
// reference/grpc/clearing.proto
syntax = "proto3";
package meridian.clearing.v1;

service ClearingService {
  rpc SubmitMovements(stream Movement) returns (SubmitSummary);
  rpc GetBatch(GetBatchRequest) returns (Batch);
}
```

**Lo que hay que medir si se hace:** latencia frente a REST/JSON, rendimiento con
*streaming* bidireccional, tamaño del mensaje, y **tiempo de desarrollo** —que es
donde la comparación se pone interesante, porque la generación de código desde el
`.proto` es igual de buena en los dos.

**Y la conclusión honesta, adelantada:** gRPC es bueno en los dos stacks y la
diferencia entre ellos es **mucho menor** que la diferencia entre gRPC y REST. Si
tu pregunta era "¿migro a Go para usar gRPC?", la respuesta es que no hace falta.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el benchmark que decidió una migración

**El cadáver.** Una empresa que no es Meridian decidió migrar su plataforma de
Spring Boot a Go. La decisión se tomó en una reunión, con una diapositiva:

```text
        Arranque    Memoria    Latencia p99    Imagen
Go        18 ms      24 MB        12 ms        14 MB
Spring   4.200 ms   512 MB       47 ms       380 MB
```

Dieciocho meses después, la migración se abandonó al 60%, con dos sistemas en
producción y un equipo agotado.

**El informe forense del benchmark, punto por punto:**

| Lo que se midió | El problema |
|---|---|
| Arranque | Se midió el *"Started in"* del log, no la primera petición servida. Y el servicio arrancaba **una vez por despliegue**, dos veces por semana |
| Memoria | `-Xmx` por defecto en una máquina de 32 GB: la JVM reservó lo que le dejaron. **Con `-XX:MaxRAMPercentage=25` bajaba a 180 MB** |
| Latencia p99 | **La JVM se midió fría.** 500 peticiones tras arrancar, con el JIT en C1. Con calentamiento, 14 ms frente a 12 ms |
| Imagen | Comparó `distroless` de Go contra `eclipse-temurin` **completo** con JDK. Con JRE `alpine`, 140 MB |
| `native-image` | **No se midió.** "No nos daba tiempo" |
| El endpoint elegido | Un `/health` que devolvía `{"status":"ok"}`. **No ejercitaba la base de datos, ni la serialización, ni la lógica** |

**Y lo que no estaba en la diapositiva**, que es lo que hundió el proyecto:

- **Spring Security con SAML.** El cliente corporativo exigía federación de
  identidades. En Go se escribió a mano: cuatro meses, dos incidentes de seguridad.
- **Spring Batch.** Doce procesos por lotes con reanudación y reintento por ítem.
  Reescribirlos fue el 40% del esfuerzo total.
- **Cuarenta desarrolladores** que sabían Spring y tuvieron que aprender Go
  mientras entregaban.
- **Dos plataformas en producción durante dieciocho meses**, con dos sistemas de
  observabilidad, dos pipelines y dos rotaciones de guardia.

**El coste real de la migración: unos 2.400 días-persona.** El ahorro estimado en
infraestructura: unos 40.000 euros al año.

**Las cuatro causas de la muerte:**

1. **Se midió lo fácil, no lo que importaba.** Arranque y memoria son fáciles de
   medir; el coste de reescribir Spring Batch y Spring Security no aparece en un
   benchmark.
2. **Se midió mal.** JVM fría, sin ajustar, `native-image` sin probar, y un
   endpoint que no ejercitaba nada.
3. **Se comparó tecnología, no sistemas.** El sistema incluye el equipo, la
   plataforma, el conocimiento acumulado y las integraciones.
4. **Y la que más duele: nadie preguntó qué problema se estaba resolviendo.** El
   servicio cumplía sus objetivos de latencia. La memoria no era un cuello de
   botella. El arranque no molestaba a nadie. **Se optimizó una métrica que a nadie
   le dolía.**

**El contrafactual, que es lo que hay que llevarse:** con la JVM ajustada, AppCDS
para el arranque y una imagen sobre JRE `alpine`, **los números de Spring Boot
habrían sido suficientes para todos los objetivos del negocio**. La migración no
era necesaria.

> ☕ **El patrón a memorizar.** **Un benchmark que compara tecnologías sin medir el
> coste de migrar no informa una decisión: la justifica a posteriori.** Antes de
> medir nada, la pregunta es *"¿qué problema tengo, y cuánto me está costando?"*.
> Si no hay respuesta, ningún número de esta fase debería mover nada.

### Errores comunes

**1. Medir la JVM fría.**
*Síntoma:* latencias de 3 a 10 veces peores que las reales.
*Fix mínimo:* calentamiento declarado y verificado con `jcmd`.

**2. Medir la JVM sin ajustar.**
*Síntoma:* memoria residente enorme.
*Causa:* sin `-XX:MaxRAMPercentage`, la JVM toma el 25% de la RAM física, que en
una máquina grande es mucho.
*Fix mínimo:* ajustar, y medir las tres configuraciones.

**3. No medir `native-image`.**
*Síntoma:* el argumento del arranque se sostiene sobre una comparación incompleta.
*Fix mínimo:* medirlo. Tarda minutos en compilar y da la fila más interesante.

**4. Comparar heap con heap.**
*Síntoma:* números que no cuadran con lo que factura la nube.
*Fix mínimo:* RSS en los dos.

**5. Elegir un endpoint que no ejercita nada.**
*Síntoma:* se mide el framework HTTP, no el servicio.
*Fix mínimo:* endpoints reales, con base de datos y lógica.

**6. Comparar imágenes distintas.**
*Síntoma:* 380 MB frente a 14 MB.
*Causa:* JDK completo frente a distroless.
*Fix mínimo:* las siete variantes de B-21.

**7. Medir con el generador de carga en la misma máquina.**
*Síntoma:* latencias peores y menos consistentes.
*Fix mínimo:* otra máquina, o declararlo como limitación.

**8. Omisión coordinada.**
*Síntoma:* la latencia bajo carga alta parece buena.
*Fix mínimo:* ritmo fijo, y la charla de Gil Tene (Fase 15).

**9. Una sola corrida.**
*Síntoma:* diferencias que no se reproducen.
*Fix mínimo:* mínimo diez, con variabilidad reportada.

**10. Extrapolar.**
*Síntoma:* "con diez millones tardaría diez veces más".
*Fix mínimo:* medir, o no afirmar.

**11. Optimizar una implementación durante la medición.**
*Síntoma:* la comparación deja de ser válida.
*Fix mínimo:* optimizaciones antes, documentadas, y las mismas oportunidades para
las dos.

**12. Ignorar el coste de migrar.**
*Síntoma:* la autopsia.
*Fix mínimo:* estimarlo, aunque sea a ojo, y ponerlo al lado del ahorro.

**13. No preguntar qué problema se resuelve.**
*Síntoma:* una migración sin objetivo que no termina nunca.
*Fix mínimo:* el objetivo, escrito, antes de medir.

### 🧨 Rompe a propósito

**Reproduce la diapositiva de la autopsia, y después arréglala.**

```bash
# ── LA VERSIÓN TRAMPOSA ──────────────────────────────────────────────────────
java -jar target/clearinghouse.jar &            # sin ajustar
sleep 1                                          # sin calentar
echo "GET http://localhost:8081/health" | vegeta attack -rate=100 -duration=10s | vegeta report

# ── LA VERSIÓN HONESTA ───────────────────────────────────────────────────────
java -XX:MaxRAMPercentage=25 -XX:+UseG1GC -jar target/clearinghouse.jar &
scripts/bench/warmup.sh http://localhost:8081    # 60 s de calentamiento
echo "GET http://localhost:8081/batches" | vegeta attack -rate=100 -duration=60s | vegeta report
```

**Anota las dos y la diferencia entre ellas.** En la mayoría de las máquinas, la
latencia p99 de la versión honesta es entre tres y diez veces mejor que la
tramposa, y la memoria residente menos de la mitad.

**Y el tercer experimento, el que de verdad incomoda:** mide el **rendimiento
sostenido** de las dos implementaciones durante diez minutos, no sesenta segundos.

```bash
vegeta attack -targets=targets.txt -rate=800 -duration=600s | vegeta report
```

Con diez minutos, la JVM lleva rato completamente caliente. **Busca el punto donde
la JVM iguala o supera a Go en rendimiento**, porque en cargas con mucha
polimorfia y llamadas repetidas suele haberlo. Si no lo encuentras, di en qué
condiciones buscaste — es un resultado igual de válido y hay que publicarlo.

---

## 🧪 8. Ejercicios (30)

**🟢 Fácil (1–6)**

1. Verifica que las dos implementaciones pasan la misma suite de contrato.
   *Criterio:* las dos en verde; si alguna falla, documentas la diferencia antes de
   medir nada.
2. Ejecuta el `diff` de asientos tras el cierre. *Criterio:* vacío, o explicas la
   diferencia y la arreglas.
3. Mide el arranque de las cinco variantes, 10 corridas, descartando la primera.
   *Criterio:* reportas mediana y variabilidad, no solo el mejor.
4. Mide la memoria residente en reposo de las cinco. *Criterio:* explicas por qué
   comparas RSS y no heap.
5. Ejecuta el guion de condiciones y guarda su salida. *Criterio:* incluye si el
   generador corre en la misma máquina.
6. Compila las dos desde limpio y cronometra. *Criterio:* incluyes el tiempo de
   `native-image` y comentas qué significa en un pipeline diario.

**🟡 Intermedio (7–18)**

7. Reproduce el 🧨: la versión tramposa y la honesta. *Criterio:* la tabla de las
   dos y el factor de diferencia, con la explicación de cada causa.
8. Ajusta la JVM para rendimiento, con cada bandera justificada. *Criterio:* para
   cada una, qué mejora y qué empeora.
9. Ajusta la JVM para arranque con AppCDS y `TieredStopAtLevel=1`. *Criterio:*
   mides arranque **y** rendimiento sostenido, y muestras el intercambio.
10. Compila con `native-image`. *Criterio:* documentas los problemas que
    encontraste —los hay— y cómo los resolviste.
11. Verifica el calentamiento con `jcmd Compiler.codelist`. *Criterio:* muestras el
    número de métodos compilados antes y después.
12. Mide latencia a seis ritmos distintos para las cinco variantes. *Criterio:* la
    curva completa, y el punto de saturación de cada una.
13. Calcula la CPU por petición de las cinco. *Criterio:* explicas por qué es la
    métrica que se traduce a coste.
14. Mide el cierre de un millón. *Criterio:* tiempo total, memoria máxima, y tiempo
    hasta el primer fragmento confirmado.
15. Ejecuta el pico de 10× y mide la recuperación. *Criterio:* los tres tramos, y
    **el tiempo de vuelta a la línea base** de cada variante.
16. Mide las siete variantes de imagen (B-21) y el tiempo de construcción.
    *Criterio:* la tabla completa, con los CVE de cada base.
17. Cuenta líneas separando negocio, cableado, infraestructura y tests.
    *Criterio:* la categoría "infraestructura que el framework daría" está
    separada, y la comentas.
18. **Línea de comandos.** Cuenta dependencias transitivas de las dos y el tamaño
    de los cachés. *Criterio:* comentas qué significa para la superficie de
    actualización.

**🟠 Difícil (19–26)**

19. Mide el rendimiento sostenido durante diez minutos y **busca el punto donde la
    JVM iguala o supera a Go**. *Criterio:* lo encuentras y lo explicas con el JIT,
    o documentas en qué condiciones buscaste sin encontrarlo.
20. Perfila las dos bajo la misma carga —`pprof` y `async-profiler`—. *Criterio:*
    identificas dónde se va el tiempo en cada una y **si es en el mismo sitio**.
21. Mide el efecto de `GOGC`/`GOMEMLIMIT` frente al de las banderas del recolector
    de la JVM, sobre la misma carga. *Criterio:* comparas el esfuerzo de ajuste
    —cuántas perillas, cuánto tiempo— además del resultado.
22. Monta el experimento de escalado: 1, 2, 4 y 8 instancias tras un balanceador.
    *Criterio:* mides rendimiento total y memoria total, y calculas el coste
    relativo por petición servida.
23. **Defiende la decisión contraria (1).** Eres el arquitecto Java. Escribe el
    argumento **más fuerte posible** contra la migración, usando **tus propios
    números**. *Criterio:* al menos cinco argumentos con datos; si alguno es débil,
    lo dices.
24. **Defiende la decisión contraria (2).** Eres quien propuso Go. Escribe el
    argumento más fuerte a favor, usando los mismos números. *Criterio:* al menos
    cinco argumentos, y **reconoces explícitamente los tres puntos más débiles de
    tu propia posición**.
25. **Defiende la decisión contraria (3).** Escribe el argumento a favor de
    **`native-image`** frente a las otras dos opciones. *Criterio:* cuándo es la
    respuesta correcta, qué se pierde, y qué tendría que ser verdad del proyecto
    para que lo recomendaras.
26. Mide el coste de migrar, no solo el de ejecutar. *Criterio:* (a) inventarías lo
    que Spring da hecho y ClearingHouse Go tuvo que escribir, con líneas; (b)
    estimas el esfuerzo de migrar **los otros tres servicios**; (c) lo comparas con
    el ahorro estimado de infraestructura; (d) das el punto de equilibrio en meses.

**🔴 Muy difícil (27–30)**

27. **Escribe B-24 completa.** *Rúbrica:* (a) hipótesis falsable declarada antes de
    medir; (b) condiciones completas, incluido el aislamiento y si el generador
    estaba en la misma máquina; (c) los comandos exactos, reproducibles; (d) las
    cinco variantes × las ocho mediciones, con variabilidad; (e) veredicto como
    guía accionable, no como adjetivo; (f) **la sección "qué NO demuestra" tan
    detallada como los resultados** — es la más importante de la entrada más grande
    del banco.
28. **El veredicto honesto.** Escribe `docs/veredicto.md`. *Rúbrica:* (a) los
    casos donde Go gana claro, con el número que lo respalda; (b) **los casos donde
    quedarse en Spring Boot es la decisión correcta**, al menos cinco, con el mismo
    nivel de detalle; (c) las condiciones que cambiarían cada recomendación; (d)
    **duele en las dos direcciones**, y se nota; (e) la sección "qué mediría yo
    antes de decidir en OTRO sistema"; (f) es utilizable por alguien que no hizo el
    curso, y no se lee como una defensa de Go.
29. **El experimento que te contradiga.** Diseña y ejecuta una medición donde
    esperes que **Java gane**, y hazla con la misma honestidad. *Rúbrica:* (a) la
    hipótesis está escrita antes y explicas por qué esperas ese resultado; (b) el
    experimento es legítimo, no un caso artificial; (c) reportas el resultado sea
    cual sea; (d) **si Java gana, lo explicas técnicamente**; (e) si no gana,
    analizas por qué falló tu hipótesis; (f) candidatos: cierre por lotes largo,
    carga con mucha polimorfia, procesamiento intensivo de strings, o algo con una
    librería que en Go no existe.
30. **La presentación a tu arquitecto.** Prepara la exposición real de veinte
    minutos. *Rúbrica:* (a) empieza por **el problema**, no por la tecnología; (b)
    los números que importan **para este sistema**, no todos los que mediste; (c)
    el coste de migrar, con su punto de equilibrio; (d) una recomendación clara,
    con sus condiciones; (e) **la diapositiva de "por qué podría estar
    equivocado"**; (f) responde las cinco preguntas difíciles que te van a hacer:
    *¿y si el equipo no aprende?*, *¿y Spring Batch?*, *¿y la seguridad?*, *¿cuánto
    tardamos?*, *¿qué pasa si a mitad decidimos parar?*; (g) **si tras prepararla tu
    recomendación es no migrar, esa es una respuesta excelente** y el ejercicio está
    igual de bien resuelto.

**🔥 Opcionales**

- Implementa la sección de gRPC de §6.6 en los dos stacks y mídela.
- Añade una cuarta variante de Java: **Quarkus** o **Micronaut** con
  `native-image`. Están diseñados para compilación anticipada desde el principio y
  la comparación es distinta a la de Spring Boot.
- Mide el consumo energético de las variantes con `powermetrics` (macOS) o RAPL
  (Linux). Es un eje que empieza a importar y casi nadie lo mide.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — El segundo servicio, para ver si el veredicto aguanta.**
El duelo mide ClearingHouse, que es transaccional y de lotes. **Repítelo con
AtlasSync**, que es de lectura intensiva con caché.
*Rúbrica:* (a) implementas el gemelo Spring Boot de AtlasSync con Spring Data
MongoDB y Spring Cache; (b) aplicas el mismo banco, el mismo calentamiento y las
mismas cinco variantes; (c) **buscas activamente el resultado que contradiga al
primer duelo** — un servicio de lectura con caché caliente es donde el JIT más
trabaja; (d) comparas los dos veredictos y dices qué te enseña la diferencia sobre
generalizar desde un solo servicio; (e) actualizas la sección "qué NO demuestra" de
B-24 con lo que aprendiste.

**D2 — El coste, en factura.**
Traduce las mediciones a dinero.
*Rúbrica:* (a) dimensionas las instancias necesarias para servir 1.000 peticiones
por segundo con p99 bajo 100 ms, con cada variante, usando **tus** números de
saturación; (b) lo llevas a un precio real de un proveedor de nube, con el tipo de
instancia concreto; (c) añades lo que no es cómputo: transferencia, almacenamiento
de logs —que depende del volumen, y `slog` en JSON pesa más—, y el tiempo de CI; (d)
calculas el ahorro anual **y lo pones al lado del coste de migrar** del ejercicio
26; (e) das el punto de equilibrio en meses y dices si te parece un buen negocio,
con argumento.

**D3 — La cuarta variante: Quarkus o Micronaut nativos.**
Spring Boot no es el único Java. Añade un stack diseñado para compilación anticipada
desde el principio.
*Rúbrica:* (a) reimplementas ClearingHouse en Quarkus o Micronaut con
`native-image`; (b) lo mides con el mismo banco; (c) comparas con Spring Boot nativo
**y explicas la diferencia**: estos frameworks resuelven en compilación lo que
Spring resuelve con reflexión en arranque; (d) evalúas el coste real del cambio —qué
librerías no están, qué cuesta el ecosistema más pequeño—; (e) **respondes la
pregunta que hace que este ejercicio exista**: si el problema era el arranque y la
huella, ¿no era más barato cambiar de framework Java que de lenguaje? Esa es una
pregunta incómoda y merece una respuesta honesta.

---

## 📚 9. Referencias

### Documentación oficial

- **Spring Boot** — https://docs.spring.io/spring-boot/index.html — la referencia
  del gemelo.
- **Spring Boot: GraalVM Native Images** —
  https://docs.spring.io/spring-boot/reference/packaging/native-image/index.html —
  lo que hay que leer antes del ejercicio 10.
- **GraalVM Native Image** — https://www.graalvm.org/latest/reference-manual/native-image/
- **JVM: opciones de HotSpot** — https://docs.oracle.com/en/java/javase/21/docs/specs/man/java.html
- **AppCDS** — https://docs.oracle.com/en/java/javase/21/vm/class-data-sharing.html
  — la optimización de arranque más rentable de la JVM, y la más ignorada.
- **A Guide to the Go Garbage Collector** — https://go.dev/doc/gc-guide
- **`jcmd`** — https://docs.oracle.com/en/java/javase/21/troubleshoot/diagnostic-tools.html
- **vegeta** y **k6** — ya citados en la Fase 15.

### Libros

- **Efficient Go** — Płotka. El método de la Fase 15 aplicado aquí.
- **Optimizing Java** — Benjamin Evans, James Gough y Chris Newland. **El libro
  para entender qué hace la JVM y por qué el calentamiento importa.** Si vas a
  medir Java, léelo antes.
- **Java Performance: The Definitive Guide** — Scott Oaks. La referencia sobre
  ajuste de la JVM; de donde salen las banderas de §5.
- **Systems Performance** — Gregg. La metodología, otra vez.
- **Designing Data-Intensive Applications** — Kleppmann, para el capítulo de
  compromisos de arquitectura.

### Artículos y charlas

- **How NOT to Measure Latency** — Gil Tene. **Otra vez, y con más motivo.**
- **JVM warmup explained** — busca los artículos sobre la escalera de compilación
  (intérprete → C1 → C2) y por qué el calentamiento no es opcional.
- **Spring Boot 3 and GraalVM** — el material oficial y las charlas de SpringOne.
- **Go vs Java benchmarks** — busca varios y **fíjate en cuántos miden la JVM
  fría**. Es un ejercicio revelador y encaja con el 🧨 de esta fase.
- **The Cost of a Migration** — busca artículos de post mortem de migraciones
  reales; los que cuentan las que salieron mal son los más útiles.
- **Choose Boring Technology** — Dan McKinley,
  https://mcfunley.com/choose-boring-technology — **el mejor argumento escrito
  contra migrar sin una razón fuerte**, y hay que leerlo antes de escribir el
  veredicto.
- **TechEmpower Framework Benchmarks** — https://www.techempower.com/benchmarks/ —
  útiles con reservas: miden casos sintéticos muy afinados, y conviene saber leer
  sus limitaciones.

### Video

- **How NOT to Measure Latency** — Gil Tene.
- **SpringOne: Native Spring Boot** — para el contexto de `native-image`.
- **GopherCon: Go in production at scale** — casos reales de migración, con sus
  matices.
- **Choose Boring Technology** — la charla de McKinley, media hora.

> ⚠️ **Advertencia especial de esta fase.** La mayoría de las comparaciones "Go vs
> Java" que vas a encontrar en internet están mal hechas: JVM fría, sin ajustar,
> sin `native-image`, con endpoints triviales, y con una conclusión escrita antes
> del experimento. **Léelas como ejemplos de lo que no hay que hacer.** Y aplica el
> mismo escepticismo a la tuya.

### Orden de lectura sugerido

**Antes de medir:** *Optimizing Java*, al menos el capítulo de la escalera de
compilación. Sin entender el JIT no se puede medir Java con honestidad.
**Durante:** la documentación de opciones de HotSpot cuando ajustes, y la de
`native-image` cuando falle algo — que fallará.
**Después, y antes de escribir el veredicto:** *Choose Boring Technology* de
McKinley. Es media hora y va a hacer tu veredicto mucho mejor, digas lo que digas.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ El veredicto honesto

**Es el entregable de la fase. Y tiene que doler un poco en las dos direcciones.**

#### Donde Go gana claro

- **Arranque en frío.** Uno o dos órdenes de magnitud frente a la JVM. Decisivo
  para procesos efímeros, funciones sin servidor, herramientas de línea de comandos
  y escalado elástico agresivo. **Irrelevante para un servicio que arranca dos veces
  por semana.**
- **Huella de memoria.** Notablemente menor, con la JVM ajustada y todo. Al escalar
  a decenas de instancias, se traduce en factura.
- **Imágenes de contenedor.** Un binario estático sobre distroless frente a un JAR
  con su JRE. Menos que transferir, menos superficie de ataque, menos CVE en la
  base.
- **Servicios de red concurrentes con E/S dominante.** El modelo de goroutines
  encaja de forma directa, el código se lee bien, y el detector de carreras viene en
  la caja. **Java 21 con hebras virtuales recorta mucho esta ventaja**, y sigue
  siendo más simple en Go.
- **Herramientas de línea de comandos.** Sin competencia: un binario estático con
  compilación cruzada para cinco plataformas en un comando.
- **Coste por instancia al escalar horizontalmente.** La suma de arranque, memoria
  e imagen.
- **Simplicidad operativa.** Dos perillas del recolector frente a decenas. Menos
  cosas que ajustar y menos cosas que alguien pueda poner mal.

#### Donde quedarse en Spring Boot es la decisión correcta

- **Transaccionalidad compleja.** `@Transactional` con propagación declarativa,
  transacciones anidadas y eventos post-commit resuelve problemas reales que en Go
  se escriben a mano —y la autopsia de la Fase 09 muestra lo fácil que es
  escribirlos mal.
- **Lotes con reanudación fina.** **Spring Batch no tiene rival en Go.** Reintento
  por ítem, política de omisión, particionado, `JobRepository` y consola de
  operación. La Fase 13 lo midió: 180 líneas frente a 520 **para un solo job**. Con
  quince jobs, la diferencia es un proyecto.
- **Equipos grandes con la plataforma ya montada.** Si hay cuarenta personas que
  saben Spring, una plataforma de observabilidad integrada con Actuator, arquetipos,
  librerías internas y quince años de conocimiento acumulado, **migrar tira todo eso
  y hay que reconstruirlo**.
- **Ecosistemas donde la librería que necesitas solo existe en Java.** Spring
  Security con SAML y OIDC. Integraciones con ERP corporativos. Librerías de
  cálculo actuarial, de firma electrónica cualificada, de mensajería bancaria. **Si
  tu dominio tiene una de estas, la conversación se acabó.**
- **Y el que más proyectos decide: cuando el problema no era el lenguaje.** La
  mayoría de los servicios lentos lo son por la base de datos, por el diseño, o por
  una llamada de red innecesaria en un bucle. **Migrar de lenguaje no arregla
  ninguna de las tres**, y cuesta dieciocho meses descubrirlo.

#### Y las cuatro cosas que la medición no captura

1. **El coste de migrar**, que es casi siempre mayor que el ahorro de ejecutar.
2. **El periodo de convivencia**, con dos plataformas, dos pipelines y dos
   rotaciones de guardia.
3. **La curva de aprendizaje del equipo**, que es real aunque Go se aprenda rápido.
4. **El coste de oportunidad**: dieciocho meses migrando son dieciocho meses sin
   construir lo que el negocio pedía.

> 🧭 **La recomendación del curso, en una frase.** **Go para servicios nuevos donde
> arranque, huella y concurrencia importen; Spring Boot para lo que ya funciona y
> para dominios donde su ecosistema resuelve problemas que en Go son proyectos.**
> Y migrar solo cuando exista un problema medido que la migración resuelva, con su
> punto de equilibrio calculado.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java | Go | Dónde se rompe la equivalencia |
|---|---|---|
| JIT (C1 → C2) | compilación anticipada | El JIT optimiza **con información de ejecución real**; el compilador anticipado no puede. El precio es el calentamiento |
| Calentamiento de la JVM | *(no aplica)* | Go ejecuta código máquina desde la primera iteración. Simplifica la medición y elimina una ventaja del JIT |
| `native-image` | compilación normal | Acerca el arranque de Java al de Go, **a costa del JIT** y del tiempo de compilación |
| `-Xmx` | `GOMEMLIMIT` | Límite **duro** frente a **suave** |
| Heap de la JVM | heap de Go | ⚠️ **No comparables**: la JVM tiene además metaespacio, pilas, buffers directos y código JIT. Compara **RSS** |
| AppCDS | *(no aplica)* | No hay clases que cargar |
| `-XX:TieredStopAtLevel=1` | *(no aplica)* | Arranque más rápido a costa del techo; Go no tiene ese intercambio |
| Hebras virtuales (Java 21) | goroutines | **Recortan mucho la ventaja de Go en concurrencia.** Quedan las diferencias de modelo |
| Spring Batch | ~520 líneas escritas | **La brecha más grande del ecosistema.** Fase 13 |
| Spring Security | *(no hay equivalente)* | SAML, OIDC, method security. En Go se ensambla |
| Spring Data JPA | `database/sql` / `sqlc` | Sin entidades gestionadas ni consultas derivadas |
| Actuator | endpoints escritos | Fase 14: se escriben |
| JFR | `runtime/trace` + `pprof` | **JFR es superior para producción continua** |
| `dependency:tree` | `go mod graph` | El número transitivo suele diferir en un orden de magnitud |
| `start.spring.io` | `go mod init` | Spring Boot llega antes al primer endpoint; Go envejece mejor |
| Mercado de contratación | — | **Muchos más desarrolladores de Java.** Dato real que pesa |

### Qué sigue

La Fase 17 cierra el curso: **el capstone y el veredicto general**.

Los cuatro servicios corriendo juntos con un `docker compose up`, con el flujo
completo atravesándolos: una tienda sincroniza movimientos, ClearingHouse los
concilia y cierra el periodo, OpsReport registra el trabajo y emite el reporte,
EventRelay notifica al socio, AtlasSync provee el tipo de cambio del día desde su
caché.

La revisión final contra el catálogo de `INSTINTOS.md`, `golangci-lint` en verde,
la cobertura sobre el umbral y la suite de integración completa.

Y **la defensa técnica**: ocho preguntas con respuesta escrita, de las que la
última —*"¿qué le dirías a tu yo de la Fase 01?"*— es la que de verdad mide si el
curso funcionó.

### La señal de que quedó bien

> *"Mi arquitecto me preguntó si migramos, le enseñé ocho números y una estimación
> de coste, y le recomendé no migrar tres de los cuatro servicios. Y estuvo de
> acuerdo."*

Si tu veredicto recomienda migrarlo todo, vuelve a la autopsia y calcula el punto
de equilibrio. Si recomienda no migrar nada, comprueba que has medido el caso donde
Go gana de verdad. **Las dos respuestas extremas suelen significar que falta una
medición.**

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, las dos implementaciones pasando la misma suite de contrato, el `diff` de
> asientos vacío, B-24 escrita con su sección "qué NO demuestra", `docs/veredicto.md`
> completo y `git status` limpio:
>
> ```bash
> git tag -a fase-16 -m "F16 cerrada: ClearingHouse medido en Go y en Spring Boot con las tres configuraciones de JVM más native-image; las ocho mediciones con calentamiento declarado y verificado; las cinco métricas que no salen en un gráfico; B-24 escrita; veredicto honesto con los casos donde quedarse en Spring es correcto"
> git tag -a duelo/v1.0 -m "El duelo medido, con sus condiciones y sus límites"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 16: …`) y los de ejercicio su
> número (`fase 16 ej30: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **La comparación NO incluye el almacén documental.** La **Fase 11** pidió que el
  ⚖️ de esta fase lo dijera explícitamente para que nadie extrapole. **No se ha
  hecho.** El duelo mide ClearingHouse (PostgreSQL) y nada de Mongo ni de Valkey.
  **Añadir una línea a la sección "qué NO demuestra" de B-24 y al ⚖️.** Es una
  petición explícita de una fase anterior sin atender.
- **La doble capa de reintento (aplicación + malla)** — la **Fase 10** la anotó
  como argumento fuerte para esta fase y para la 17. **No aparece.** Encaja bien en
  "donde quedarse en Spring Boot es correcto" o en el veredicto general de la Fase
  17. **Decidir dónde.**
- **`ScopedValue` de Java 21** — la **Fase 07** lo anotó como candidato a la
  sección de "lo que no sale en los gráficos". **No aparece.** Es menor; se puede
  retirar el pendiente.
- **El rendimiento del despachador del outbox frente al número de instancias** —
  la **Fase 13** propuso encajarlo aquí como una fila más de B-24. **Resuelto como
  entrada propia, B-27, en la Fase 13**, y no como fila del duelo: B-24 compara Go
  con Spring, y B-27 compara la cola en base de datos consigo misma al escalar.
  Mezclarlas habría contaminado las dos. Cadena cerrada.
- **B-21 se reutiliza aquí** (medición 6). Correcto y declarado.
- **El banco del ejercicio 26 de la Fase 15** está diseñado para poder medir el
  gemelo Java. **Cadena verificada.**

## ☕ Reflejos para `INSTINTOS.md`

- **"La JVM es lenta"** — es lenta **al principio**. El JIT optimiza con
  información de ejecución real y puede superar a la compilación anticipada en
  régimen estacionario. Antídoto: preguntar por el **perfil de ejecución** del
  servicio antes de comparar.
- **"Con `native-image` ya no hay diferencia"** — cierra la brecha de arranque y
  abre otra de rendimiento sostenido, y cuesta minutos de compilación. Hay que
  medir las tres configuraciones.
- **"Los benchmarks dicen que migremos"** — la autopsia: 2.400 días-persona para
  ahorrar 40.000 euros al año, con la JVM medida fría y sin ajustar. **Un benchmark
  que no mide el coste de migrar justifica una decisión ya tomada.**
- **"Comparo el heap de los dos"** — no son comparables. RSS.
- **"Mido `/health`"** — se mide el framework HTTP, no el servicio.
- **"Nuestro servicio va lento, migremos a Go"** — la mayoría de los servicios
  lentos lo son por la base de datos, el diseño o una llamada de red en un bucle.
  **Migrar de lenguaje no arregla ninguna de las tres.**

## 📐 Mediciones para `BENCHMARKS.md`

- **B-24 — El duelo completo.** Es **la entrada más grande del banco** y la que más
  responsabilidad carga. Requisitos que no son negociables:
  - **Cinco variantes** (Go, JVM por defecto, JVM ajustada para rendimiento, JVM
    ajustada para arranque, `native-image`), no dos.
  - **Calentamiento declarado y verificado** con `jcmd`, no supuesto.
  - **RSS**, nunca heap contra heap.
  - **Variabilidad reportada** en cada fila; por debajo del 5% o se repite.
  - **La sección "qué NO demuestra" tan detallada como los resultados**, e
    incluyendo al menos: una sola máquina, generador de carga posiblemente local,
    una versión de cada stack, un solo servicio (ClearingHouse), **sin Mongo ni
    Valkey en la comparación**, y sin el coste de migrar.
  - **Y el resultado incómodo, publicado.** Si Java gana en el cierre por lotes
    —que es plausible, porque el JIT tiene noventa minutos para trabajar—, esa fila
    se escribe igual de grande.
- **Revisión de B-21:** se reutiliza aquí. Verificar que las siete variantes de la
  Fase 14 coinciden con las cinco de esta fase o explicar la diferencia.
