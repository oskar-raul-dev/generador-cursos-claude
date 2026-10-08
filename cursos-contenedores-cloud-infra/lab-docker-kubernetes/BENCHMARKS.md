# 📏 BENCHMARKS
## Laboratorio de contenedores y Kubernetes local

Todas las mediciones del curso, en un solo sitio y con el mismo formato, para que se puedan comparar
entre sí y para que ninguna se cite sin sus condiciones. Es uno de los tres documentos vivos del
curso: **nace vacío y crece con las fases**. Cada fase que mide agrega aquí su entrada en la misma
tanda en que se escribe, y la fase la cita por su identificador.

> 🧭 **La regla que sostiene el curso: si no lo puedes medir en el laboratorio, no lo afirmas.** Ni
> "más liviano", ni "arranca antes", ni "escala mejor", ni "sale más barato". Cuando la medición no
> existe, la frase se escribe sin el comparativo.

> 📝 **Este archivo crece con el curso.** La primera medición es la de la
> [Fase 04](04-empaquetar-los-cuatro-runtimes.md), que fija el arnés. Los números de la tabla de memoria del laboratorio (B-00) no viven aquí sino en
> [a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil), porque son requisito de instalación
> y no resultado de una fase.

**Salto rápido:** [Qué hace creíble un número](#️-qué-hace-creíble-un-número) · [El formato de una entrada](#-el-formato-de-una-entrada) · [Las mediciones del curso](#️-las-mediciones-del-curso) · [Las entradas](#-las-entradas)

---

## ⚖️ Qué hace creíble un número

Una medición mal presentada es peor que ninguna, porque parece evidencia. En este curso el tiempo
**es** parte de lo medido —el build en frío, el arranque, la creación del cluster—, así que la
máquina importa tanto como el resultado. Por eso cada entrada trae seis datos, sin excepción:

1. **La hipótesis**, escrita antes de medir y en una línea. No se edita después, ni si se pierde.
2. **Qué se midió**, con la unidad.
3. **Con qué motor, qué versión de kind y qué perfil.** Las versiones se nombran por referencia a
   [a01](a01-el-laboratorio.md#-versiones-fijadas), que es el único sitio donde viven.
4. **En qué máquina**: CPU, memoria y plataforma.
5. **La dispersión**: cuántas corridas, y la mediana con su mínimo y su máximo. Nunca un número solo.
6. **Cómo reproducirla**: `task measure -- <id>`, que deja los crudos en `src/lab/bench/`.

Y seis reglas que hacen que el resultado sobreviva a un lector escéptico:

- **Se publica lo que salió**, no lo que esperabas.
- **El empate se llama empate.**
- **Nada de números redondos sin dispersión.**
- **El competidor se configura bien**: medir Java sin sus opciones de contenedor contra Go afinado no
  es una medición, es un argumento.
- **Se declara lo que no se midió.**
- **Nunca se extrapola**: lo que pasó con tres réplicas en un portátil no dice nada de treinta en un
  cluster gestionado.

> 💡 **La conclusión se escribe sobre la proporción, no sobre el absoluto.** *"La imagen de
> `inventory` pesa once veces la de `pricing`"* sobrevive a la próxima máquina; *"pesa 312 MB"* no
> sobrevive a la próxima versión.

---

## 🧾 El formato de una entrada

Cada entrada lleva un identificador `B-NN`, con el número de la fase que la produce, y ese
identificador no se reutiliza nunca:

```markdown
### B-NN · El título, en palabras de la pregunta que contesta
**Hipótesis:** la apuesta, tal como se escribió antes de medir
**Condiciones:** perfil `medicion` · motor y su versión · versión de kind · máquina · carga
**Resultado:** tabla con mediana, mínimo y máximo · **Apuesta:** ganada | perdida | empate
**Veredicto:** la guía que se desprende, en una o dos frases
**Reproducir:** `task measure -- B-NN` · **Fecha:** DD/MM/AAAA · **Plataforma:** macOS arm64
```

**Una entrada publicada nunca se edita.** Si la medición se rehace con otra versión o en otra
máquina, se agrega una entrada nueva que cita a la anterior, y la diferencia entre las dos también es
un dato.

**Si mides en tu máquina**, tu resultado no reemplaza al del autor: va debajo, con tu máquina
declarada. Las mediciones de Windows 11 y de Linux entran así, a medida que alguien las corre.

---

## 🗂️ Las mediciones del curso

Seis en el camino base, todas con el mismo arnés. La tabla dice qué pregunta contesta cada una;
**la hipótesis exacta la escribe su fase antes de medir**, y por eso no está aquí.

| ID | Fase | La pregunta que contesta |
|---|---|---|
| B-04 | 04 | ¿Cuánto cuesta empaquetar cada runtime: tamaño, build en frío, build con caché y arranque? |
| B-05 | 05 | ¿Qué cambia entre los dos motores: creación del cluster, build y memoria del host en reposo? |
| B-07 | 07 | ¿Cuánto cuesta cada cluster local: arranque, memoria en reposo y multi-nodo? |
| B-12 | 12 | ¿Qué se gana y qué se pierde probando contra SQLite en lugar del motor real? |
| B-16 | 16 | ¿Cuántas réplicas de cada runtime sostienen la misma tasa, y cuánta memoria cuesta cada una? |
| B-23 | 23 | ¿Cómo se reparte el tráfico gRPC entre réplicas, antes y después del arreglo? |

Los apéndices 🔥 pueden sumar entradas propias cuando el resultado lo merece, con el mismo formato.

---

## 📊 Las entradas

### B-04 · ¿Cuánto cuesta empaquetar cada runtime?

**Hipótesis:** Con el multi-stage definitivo, la imagen de `pricing` queda por debajo de 20 MB y la
de `inventory` por encima de 200 MB: más de diez veces. En build en frío, `inventory` tarda más de
cinco veces lo que `pricing`. Con caché y un cambio solo en el código, los cuatro backends bajan a
menos de un cuarto de su build en frío. Hasta el primer 200, `pricing` contesta en menos de medio
segundo e `inventory` en más de dos: más de veinte veces.
**Condiciones:** sin cluster · Docker Desktop 4.92.0 (Engine 29.8.0), máquina virtual de 4 GiB y 8
CPU · MacBook Pro M1 Pro, 32 GB, macOS arm64 · imágenes base ya descargadas · los Dockerfile de la
[Fase 04](04-empaquetar-los-cuatro-runtimes.md) · 5 corridas de cada build, 10 arranques.
**Resultado:** mediana (mínimo–máximo).

| | descomprimida | viaja | build en frío | build con caché | primer 200 |
|---|---|---|---|---|---|
| `pricing` (Go) | 8,5 MB | 3,5 MB | 5,8 s (5,7–7,0) | 5,6 s (5,5–5,7) | 0,16 s (0,15–0,18) |
| `inventory` (Java) | 383,9 MB | 136,2 MB | 88,8 s (87,8–95,4) | 2,7 s (2,6–3,9) | 1,16 s (1,14–1,26) |
| `catalog` (PHP-FPM + nginx) | 125,2 MB | 43,6 MB | 7,5 s (7,4–8,6) | 3,7 s (3,6–4,2) | 0,43 s (0,41–0,54) |
| `replenish` (Node) | 175,7 MB | 64,2 MB | 7,0 s (6,9–7,3) | 2,2 s (2,1–2,4) | 0,46 s (0,44–0,48) |
| `storefront` (nginx) | 54,3 MB | 23,2 MB | 5,2 s (5,0–5,2) | 2,0 s (2,0–2,0) | 0,19 s (0,16–0,20) |

*Descomprimida* según `dive`; *viaja*, el archivo de `docker save`; *con caché*, tras cambiar una
línea de código; *primer 200*, desde `docker run` hasta la primera respuesta 200 de la ruta de G0.
**Apuesta:** ganada en tamaño (45 veces) y en build en frío (15 veces); perdida en caché (solo
`inventory` bajó de un cuarto; `pricing` quedó en el 97 %) y en arranque (`inventory`, siete veces
`pricing`, no veinte).
**Veredicto:** el peso de la imagen predice lo que viaja y el build en frío, no el build con caché ni
el arranque. El build con caché lo decide el paso que queda después del cambio; Java tiene un piso
de tamaño que ningún multi-stage quita, y con el jar por capas es el que menos paga por commit.
**Reproducir:** `task measure -- B-04` · **Fecha:** 03/10/2026 · **Plataforma:** macOS arm64

> 📝 Una primera corrida completa se descartó: el arnés agregaba siempre el mismo cambio al código y,
> desde la segunda corrida, medía la caché del motor y no el build. Se corrigió antes de publicar
> nada; la [Fase 04](04-empaquetar-los-cuatro-runtimes.md#-8-la-medición-b-04) lo cuenta.

> 📝 **`pricing` otra vez, con G10 (05/10/2026).** Con G3, una corrida suelta de build en frío dio 398 s, y la tabla
> quedó en duda para `pricing`. Repetida con el mismo arnés y las mismas condiciones, salvo el código: 5 builds en frío,
> 5 con caché y 10 arranques. **Descomprimida 26,6 MB, viaja 9,6 MB, build en frío 23,5 s (22,8–24,9), con caché 16,9 s
> (16,6–17,4), primer 200 0,22 s (0,20–0,31).** Los 398 s no se repitieron: fueron la red de ese día bajando los módulos.
> Lo que sí cambió es real: el binario creció con gRPC, OpenTelemetry y el driver de Postgres (de 8,5 a 26,6 MB) y el
> build en frío se multiplicó por cuatro; con caché sigue en el 72 % del frío, porque cambiar `main.go` vuelve a compilar
> las dependencias en el `go build`. Dos cambios de método: el primer 200 se midió en `/health/live`, porque la ruta de G0
> da 404 sin precios en la SQLite (`--path`); y el arnés guarda la imagen con su tag (`lab/pricing:latest`), porque
> `docker save lab/pricing` sin tag exportó todos los tags del repositorio y dio 128 MB "que viajan". Los otros cuatro
> servicios no se repitieron.

### B-05 · ¿Qué cambia entre los dos motores?

**Hipótesis:** Con las dos máquinas virtuales en 4 GiB, los dos motores empatan en memoria en reposo
(dentro de la dispersión); Podman crea el cluster `minimo` más de un 20 % más lento que Docker; y el
build en frío de `pricing` queda dentro de un 15 % entre los dos.
**Condiciones:** cluster `minimo` · Docker Desktop 4.92.0 (Engine 29.8.0) y Podman 6.1.3 (libkrun),
las dos máquinas virtuales en 4 GiB, un motor encendido a la vez · kind 0.33.0, nodo 1.36.4 · MacBook
Pro M1 Pro, 32 GB, macOS arm64 · 5 corridas; la huella del host, 5 lecturas cada 10 s tras 60 s de
reposo.
**Resultado:** mediana (mínimo–máximo).

| | Docker | Podman |
|---|---|---|
| crear el cluster `minimo` (s) | 25,8 (25,1–26,7) | 29,0 (28,7–29,6) |
| build en frío de `pricing` (s) | 5,2 (5,2–6,5) | 11,1 (11,1–11,9) |
| build en frío de `inventory` (s) | 93,2 (91,9–96,4) | 99,1 (93,6–102,1) |
| host recién arrancado: máquina virtual / demás procesos (MB) | 1.244 / 3.184 | 1.479 / 38 |
| host después de trabajar: máquina virtual / demás procesos (MB) | 4.145 / 415 | 7.369 / 48 |

La huella es el `phys_footprint` de macOS. La de la máquina virtual de Podman después de trabajar
fluctuó: unos minutos después de la medición, `footprint` la daba en 3.110 MB.
**Apuesta:** perdida en las tres: no empatan en memoria (Podman, +19 % en la máquina virtual y 98 %
menos en los demás procesos), el cluster tardó +12 % y el build de `pricing` +113 %.
**Veredicto:** Docker gana en tiempo de build y de cluster; Podman, en lo que corre alrededor de la
máquina virtual. Después de trabajar, cuenta con la asignación entera de la máquina virtual ocupada
en el host, con cualquiera de los dos; por eso, un motor a la vez.
**Reproducir:** `task measure -- B-05`, con el motor que se mide como activo y el otro apagado ·
**Fecha:** 03/10/2026 · **Plataforma:** macOS arm64

### B-07 · ¿Cuánto cuesta cada cluster local?

**Hipótesis:** **no se escribió antes de medir**, y por eso esta entrada no tiene apuesta. Se declara
como error de método; la [Fase 07](07-el-cluster-local.md) lo cuenta y apuesta sobre un experimento
posterior (k3d sin Traefik).
**Condiciones:** un nodo, sin nada desplegado · Docker Desktop 4.92.0 (Engine 29.8.0) y Podman 6.1.3,
máquinas virtuales de 4 GiB · kind 0.33.0, k3d 5.9.0, minikube 1.39.0, el Kubernetes de Docker Desktop
en modo kind · MacBook Pro M1 Pro, 32 GB, macOS arm64 · 3 corridas, con las imágenes de cada
herramienta ya descargadas; memoria = lo que sube la memoria usada de la máquina virtual tras 60 s de
reposo.
**Resultado:** mediana (mínimo–máximo).

| | Kubernetes | un nodo listo | memoria del cluster | tres nodos |
|---|---|---|---|---|
| kind, Docker | 1.36.4 | 26 s (26–27) | 651 MiB (632–668) | 36,2 s |
| kind, Podman | 1.36.4 | 30 s (29–30) | 507 MiB (403–547) | 34,9 s |
| k3d, Docker | 1.35.5+k3s1 | 17 s (17–17) | 681 MiB (655–697) | 29,3 s |
| k3d, Docker, sin Traefik | 1.35.5+k3s1 | 17 s (16,8–17,9) | 463 MiB (366–478) | no medido |
| k3d, Podman | — | no arrancó | — | — |
| minikube, Docker | 1.37.0 | 39 s (38–40) | 498 MiB (494–536) | 60,7 s |
| minikube, Podman | 1.37.0 | 36 s (35–36) | 504 MiB (496–520) | no une los workers |
| Docker Desktop, modo kind | 1.36.1 | 35 s (34,8–36,3)* | ≈ 750 MiB** | no medido |

\* Desde `docker desktop start`; el motor solo, 6 s. \*\* 1.358 MiB (1.352–1.363) con Kubernetes contra
608 (587–642) sin él, con el cluster borrado de verdad (deshabilitarlo no lo apaga).
**Apuesta:** sin apuesta en la medición principal. La de k3d sin Traefik (que bajaría más de 100 MiB y
quedaría por debajo de kind) se ganó: 463 MiB.
**Veredicto:** ninguno gana en todo; la memoria depende de lo que cada uno trae de serie. kind es el
cluster del curso porque fue el único que corrió entero con los dos motores, con la versión fijada y
sin componentes que apagar.
**Reproducir:** `task measure -- B-07 --tool kind|k3d|minikube`; Docker Desktop, con el procedimiento
de la [Fase 07](07-el-cluster-local.md) · **Fecha:** 03/10/2026 · **Plataforma:** macOS arm64

---

### B-12 · ¿Qué se gana y qué se pierde probando contra SQLite en lugar del motor real?

**Hipótesis:** la suite de pruebas contra Postgres con Testcontainers tarda más de diez veces lo que
contra SQLite, y hay al menos un comportamiento (una restricción o un tipo) que SQLite acepta y
Postgres rechaza. Escrita antes de medir.
**Condiciones:** las 7 pruebas del almacén de `pricing` (`services/pricing/main_test.go`), las mismas
contra los dos motores; con Postgres, Testcontainers arranca un contenedor `postgres:18.6` por corrida,
no por prueba · `task test:pricing`, dentro de un contenedor `golang:1.27.1`, con las cachés de módulos
y de compilación calientes · Docker Desktop (Engine 29.8.0), máquina virtual de 4 GiB, con el cluster
`minimo` corriendo · MacBook Pro M1 Pro, 32 GB, macOS arm64 · 5 corridas por motor, después de una sin
medir · dos tiempos: el de la tarea entera (lo que espera quien la corre) y el que informa `go test`
para el paquete (el binario de pruebas, con el arranque del motor dentro).
**Resultado:** mediana (mínimo–máximo), de la segunda serie de cinco.

| | la tarea | `go test` | pasan | fallan |
|---|---|---|---|---|
| SQLite | 5,45 s (4,27–6,81) | 0,10 s (0,07–0,19) | 7 | ninguna |
| Postgres con Testcontainers | 12,70 s (9,48–13,93) | 6,24 s (4,49–6,62) | 6 | `TestLargePrice` |
| Postgres / SQLite | **2,3x** | **59x** | | |

La primera serie, sin el tiempo de `go test`, dio 5,18 s y 10,82 s (2,1x). La prueba que falla guarda
un precio de 3.000.000.000: SQLite lo acepta en una columna `INTEGER`, y Postgres lo rechaza (`unable
to encode 3000000000 into binary format for int4 (OID 23): 3000000000 is greater than maximum value
for int4`).
**Apuesta:** el tiempo, **perdida** en lo que importa a quien la corre: la tarea tarda 2,3 veces,
porque el contenedor y la compilación pesan lo mismo con los dos motores. En el binario de pruebas, 59
veces. La fidelidad, **ganada**: SQLite dejó pasar un error de tipo que en producción es un 500.
**Veredicto:** probar contra SQLite ahorra unos siete segundos por corrida y deja pasar errores que el
motor real ve. Con
pruebas de almacén, conviene el motor real; SQLite sirve para lo que no toca SQL específico del motor.
**Reproducir:** `task measure -- B-12 --runs 5` (con Docker: Testcontainers usa su socket) · **Fecha:**
03/10/2026 · **Plataforma:** macOS arm64 · 🦭 con Podman, no medido

### B-16 · ¿Cuántas réplicas pide cada runtime para la misma tasa, y cuánto cuesta cada una?

**Hipótesis:** para la misma tasa de lecturas por la puerta, con p95 bajo 100 ms, `pricing` con una
réplica, y los otros tres con más; y una réplica de `inventory` ocupa más de diez veces la memoria de una
de `pricing`. Escrita antes de medir.
**Condiciones:** perfil `medicion` sobre el cluster `lab` (control-plane y dos workers; sin `storefront`,
sin autoescalado), con los servicios de G5 y Postgres · 300 peticiones por segundo, tasa constante con
k6 (`bench/b16/rate.js`), desde el host por `api.localhost:8080`, contra una lectura de cada servicio
(`pricing` `/prices?store=DRO-007`, `inventory` `/stock/DRO-010/SKU-0001`, `catalog` `/products`,
`replenish` `/replenishment-orders`) · 1, 2 y 3 réplicas, escaladas a mano; por cada punto, 10 s de
calentamiento que no cuentan y 3 corridas de 30 s · la memoria por réplica con `kubectl top` al final ·
Docker Desktop (Engine 29.8.0), máquina virtual de 4 GiB, kind 0.33.0, nodo 1.36.4 · MacBook Pro M1
Pro, 32 GB, macOS arm64.
**Resultado:** el p95 en ms, mediana (mínimo–máximo) de 3 corridas; la memoria de cada réplica, en MiB.

| | 1 réplica | 2 réplicas | 3 réplicas | memoria por réplica |
|---|---|---|---|---|
| `pricing` (Go) | 4 (4–5) | 4 (3–4) | 3 (3–4) | 9–28 |
| `inventory` (Java) | 3 (3–3) | 6 (4–26) | 7 (5–74) | 175–217 |
| `catalog` (PHP-FPM + nginx) | **147 (85–292)** | 45 (40–86) | 162 (155–189) | 46–56 |
| `replenish` (Node) | 4 (4–4) | 4 (4–5) | 4 (4–6) | 40–51 |

Fallidas: ninguna en `pricing`, `catalog` y `replenish`; en `inventory`, hasta el 0,05 % con dos réplicas
y el 0,26 % con tres.
**Apuesta:** **perdida**, en las dos mitades. A 300 peticiones por segundo, `pricing`, `inventory` y
`replenish` cumplen con una réplica; solo `catalog` necesita dos. Y una réplica de `inventory` (208 MiB)
ocupa 7,4 veces la de `pricing` (28 MiB), no más de diez. Con tres réplicas, `catalog` empeoró (162 ms) y
`inventory` tuvo una corrida mala (74 ms): en tres nodos-contenedor de la misma máquina, más réplicas
compiten por la misma CPU y por el mismo Postgres, y no lo separé.
**Veredicto:** para lecturas cortas, el runtime no decide cuántas réplicas hacen falta: decide **cuánto
cuesta cada una** (siete veces más en Java que en Go) y **cuántas peticiones atiende a la vez**: PHP-FPM,
con cinco procesos por pod, es el único que se queda corto con una. Escalar `catalog` es escalar procesos.
**Reproducir:** `task deploy CLUSTER=lab -- medicion` y `task measure -- B-16 --runs 3 --rate 300` ·
**Fecha:** 04/10/2026

### B-23 · ¿Cómo se reparte el tráfico gRPC entre réplicas, antes y después del arreglo?

**Hipótesis:** con tres réplicas de `pricing` y gRPC por un `Service` normal, más del 90 % de las llamadas de una
réplica de `inventory` van a una sola réplica de `pricing`; con balanceo en el cliente (un `Service` *headless* y
`round_robin`), cada réplica recibe entre el 25 % y el 40 %. Y la mediana de la venta no cambia más de un 10 % al pasar
el precio de HTTP a gRPC. Escrita antes de medir.
**Condiciones:** valores de `minimo` sobre el cluster `lab` (control-plane y dos workers), servicios en G10, Postgres
de G3, observabilidad apagada · tres réplicas de `pricing`, una de `inventory` · 20 ventas por segundo, tasa constante
con k6 (`bench/b23/ventas.js`), desde el host por `api.localhost:8080` · por corrida, `inventory` reiniciado (una
conexión nueva), 5 s de calentamiento que no cuentan y 30 s medidos; las llamadas de cada réplica, de su contador
(`grpc_server_requests_total` o, sin gRPC, `http_server_requests_seconds_count` de `/prices/{sku}`) · 3 corridas por modo ·
modos: `service` (gRPC, `Service` normal, `pick_first`), `client` (gRPC, *headless*, `round_robin`), `service+age`
(gRPC, `Service` normal, `pricing` con `MaxConnectionAge` de 10 s), `http` (sin gRPC: el 8443 con mTLS, que negocia
HTTP/2) y `http1` (sin gRPC ni mTLS: el 8080, HTTP/1.1) · aparte, **la réplica nueva**: dos réplicas, 60 s de ventas y
una tercera a los 20 s, una corrida por modo · Docker Desktop (Engine 29.8.0), máquina virtual de 4 GiB, kind 0.33.0,
nodo 1.36.4, kube-proxy en modo `iptables` · MacBook Pro M1 Pro, 32 GB, macOS arm64.
**Resultado:** la parte de las llamadas que recibió la réplica más cargada, mediana (mínimo–máximo) de 3 corridas; la
mediana de la venta, en ms, entre la menor y la mayor de las 3.

| Modo | La más cargada | Repartos de las 3 corridas | Mediana de la venta |
|---|---|---|---|
| `service` (gRPC) | **100 %** (100–100) | 1/0/0 · 1/0/0 · 1/0/0 | 23,6–25,4 |
| `client` (gRPC) | **33 %** (33–33) | ⅓ cada una, las tres | 23,1–24,5 |
| `service+age` (gRPC) | 100 % (70–100) | 1/0/0 · 1/0/0 · 0,70/0,30/0 | 24,1–25,7 |
| `http` (HTTP/2, mTLS) | 100 % (100–100) | 1/0/0 · 0,998/0,002/0 · 1/0/0 | 23,4–24,0 |
| `http1` (HTTP/1.1) | 50 % (50–100) | 1/0/0 · 0,5/0,5/0 · 0,5/0,5/0 | 23,1–24,0 |

| La réplica nueva (2 → 3 a los 20 s de 60) | Llamadas que recibió la nueva |
|---|---|
| `client` | **0 de 1200** |
| `client+age` | 237 de 1201 (lo que le tocaba en sus 40 s: ~267) |

Fallidas: ninguna, en ningún modo. Con `service+age`, una muestra aparte de tres minutos (18 reconexiones, contadas en
conntrack) repartió 6/6/6.
**Apuesta:** **ganada**, las dos mitades: 100 % a una réplica con el `Service` normal y 33 % con el balanceo en el
cliente; la mediana de la venta, igual con gRPC, con HTTP/2 y con HTTP/1.1. Lo que no estaba en la apuesta fue lo más
caro: **HTTP por el 8443 ya iba entero a una réplica desde la [Fase 19](19-tls-y-certificados.md)**, porque negocia HTTP/2; y el balanceo en el
cliente, solo, no ve una réplica nueva.
**Veredicto:** un `Service` reparte conexiones, y HTTP/2 (el de gRPC y el que negocia cualquier HTTPS moderno) manda
todo por una. Para repartir **llamadas**, balanceo en el cliente sobre un *headless*; para que el cliente vea las
réplicas nuevas, **además** una edad máxima de conexión en el servidor. La edad sola rota la carga, no la reparte. Un
proxy de capa 7 (un mesh) lo resuelve sin tocar el código, a cambio de una pieza más; no se midió.
**Reproducir:** `task deploy CLUSTER=lab FORCE=true -- minimo`, `task measure -- B-23 --runs 3 --rate 20 --modes
service,client,service+age,http,http1` y `task measure -- B-23 --scale --modes client,client+age --rate 20`; después,
`task deploy CLUSTER=lab FORCE=true -- minimo` (el `kubectl scale` de la medición se queda con `.spec.replicas`) ·
**Fecha:** 04/10/2026
