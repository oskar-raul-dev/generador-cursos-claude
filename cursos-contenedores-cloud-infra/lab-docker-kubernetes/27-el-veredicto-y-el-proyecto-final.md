# ⚖️ Fase 27 — El veredicto honesto, y el proyecto final: cuándo no hacía falta nada de esto, con número

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 27 de 27 · Cierre · **densa**
> **Evidencia:** [BENCHMARKS.md](BENCHMARKS.md), entradas B-04, B-05, B-07, B-12, B-16 y B-23 · [INSTINTOS.md](INSTINTOS.md) · [cuaderno-incidentes.md](cuaderno-incidentes.md) · B-00 en [a01](a01-el-laboratorio.md)
> **Depende de:** [Fase 26](26-idempotencia-y-outbox.md) · **Habilita:** el proyecto final
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 (el proyecto final, con un servicio de prueba)
> **Objetivo:** contestar con lo medido en veintisiete fases si La Vecina necesita un orquestador, en dos ramas —sola, y con una segunda cadena—, y encargar un proyecto final cuyos criterios de aceptación son comandos.

---

## 🧭 1. Dónde estamos

Esto es lo que construiste, y lo que corre en tu portátil:

```mermaid
flowchart TD
    GW["api.localhost:8080 · storefront.localhost:8080<br/>la puerta: Envoy Gateway, Gateway API"]
    subgraph APPS["apps"]
        SF["storefront<br/>React, nginx"]
        INV["inventory<br/>Java"]
        PRI["pricing<br/>Go"]
        CAT["catalog<br/>PHP-FPM + nginx"]
        REP["replenish<br/>Node"]
        OR["outbox-relay<br/>sidecar de inventory, Go"]
    end
    subgraph DATA["data"]
        PG[("Postgres<br/>una base por servicio")]
        NATS[["NATS JetStream"]]
    end
    subgraph LEGACY["legacy"]
        LEG["Contingencia (GlassFish), el portal, la Braqui<br/>el patrimonio, detrás de la misma puerta"]
    end
    subgraph OBS["observability"]
        O["Prometheus, Grafana, Loki, Fluent Bit, Tempo<br/>cada uno con su interruptor"]
    end
    subgraph APPSB["apps-b"]
        B["la segunda cadena<br/>el mismo chart, otro release"]
    end
    GW --> APPS
    GW --> LEGACY
    INV -- "gRPC + mTLS" --> PRI
    INV --> CAT
    INV -- "saga" --> REP
    INV --> OR
    OR -- "publica" --> NATS
    NATS -- "consume" --> REP
    APPS --> PG
    DATA ~~~ OBS
    DATA ~~~ APPSB
```

Cinco servicios en cuatro runtimes, un chart, dos cadenas, un bus, una saga, y un cuaderno de 27 incidentes. Valentina
tiene que convertir eso en una recomendación para Germán, y la escena que abre esta fase es esa entrega. Germán no pidió
un informe técnico: pidió que le contestaran dos preguntas que ya estaban sobre la mesa antes del curso. La suya, del
jueves después del 14 de octubre (historia §1.14):

> *"¿Por qué un pico de domicilios en Bogotá le congela la caja a Yolanda en Girón, si para eso partimos el Siga en dos?"*

Y la tercera de su encargo, la de la asamblea: *¿cuánto cuesta operarlo, y quién lo arregla un domingo?* (historia
§5.4). Con una condición que Valentina cumplió desde la primera fase: que cada número tenga detrás una prueba que alguien
pueda repetir, y que lo que no se midió se diga.

El curso se ganó el derecho a hacer la pregunta incómoda: **¿hacía falta todo esto?** Esta fase la contesta, y en
algunos casos la respuesta es que no.

---

## 🎯 2. Objetivos de esta fase

1. Reunir, por pregunta, la medición, el instinto o el incidente que la contesta, y lo que no se midió.
2. Recorrer el árbol de decisión de abajo hacia arriba —un contenedor, compose, dos servidores, un orquestador— con un
   número en cada rama.
3. Escribir la recomendación de Valentina en dos ramas: La Vecina sola, y La Vecina con una segunda cadena.
4. Consolidar el diccionario local ⇄ nube con la frontera de lo que el laboratorio nunca dio.
5. Hacer el proyecto final: un servicio nuevo de punta a punta, aceptado por comandos.

---

## 🗂️ 3. La evidencia

El veredicto no se sostiene con opinión. Cada pregunta del árbol de la sección 4 apunta a algo que se ejecutó:

| La pregunta | Lo que la contesta | Dónde |
|---|---|---|
| ¿Cuánto cuesta empaquetar cada runtime? | `pricing` 8,5 MB y primer 200 en 0,16 s; `inventory` 383,9 MB y 1,16 s | B-04 |
| ¿Cuánta máquina se come la plataforma? | el cluster `minimo` con la puerta y metrics-server, 1,56 GiB antes del primer servicio; todo encendido, 2,3 GiB; el patrimonio entero en compose, 0,8 GiB | B-00 en `a01` |
| ¿Elegir motor o cluster local cambia algo? | dentro de la dispersión, no: ninguno gana en todo | B-05, B-07 |
| ¿El orquestador escala lo que hace falta? | a 300 peticiones/s, tres de cuatro servicios cumplen con **una** réplica; el HPA reaccionó en 31–37 s; un vecino lento tumbó a `inventory` sin una alarma de CPU | B-16, instintos "El autoescalado me salva del pico" y "Si es lento, el orquestador lo escala" |
| ¿Reparte el `Service` lo que creo? | con HTTP/2, el 100 % a una réplica | B-23, instinto "Tres réplicas reparten el tráfico entre tres" |
| ¿Se cae solo y vuelve solo? | `restart: always` vigila que el proceso exista, no que sirva; un `Deployment` con sondas, sí | instinto "`restart: always` y un `healthcheck`" |
| ¿Cuánto cuesta instalar una segunda cadena? | 212 MiB y un archivo de valores; un rollback en 1,2 s | [Fase 14](14-helm-en-operacion.md) |
| ¿La red separa a las dos cadenas? | sí, con políticas; el Postgres compartido, no | instinto "La red del cluster es interna" |
| ¿Quién arregla un domingo, y con qué? | 27 incidentes con los primeros treinta segundos escritos: 5 de ambiente, **15 de plataforma** y 7 de certificados | el cuaderno |
| ¿Qué resolvió Kubernetes en la Parte IV? | nada: la saga, el bus y la idempotencia son código | instintos "Si la llamada falló…", "Si lo publiqué…", "Si lo guardé y avisé…" |

**Lo que no se midió**, y por eso no se afirma: ninguna nube (la frontera de la sección 5); un nodo que se cae de verdad,
con su disco y su red; carga de producción (11.000 domicilios por día no caben en un portátil, y las mediciones del curso
son proporciones, nunca capacidades); Windows y Linux, que quedan para quien hace el curso; y el costo en personas de
operar un cluster durante un año. Esa última es la que más pesa, y es la que menos se puede medir en un laboratorio.

---

## ⚖️ 4. El árbol de decisión honesto

El árbol se recorre de abajo hacia arriba: se sube un piso solo si el de abajo no alcanza, y cada piso dice **qué número**
lo hace insuficiente.

```mermaid
flowchart TD
    Q1{"¿Lo resolvía un contenedor y un servicio<br/>del sistema operativo?"}
    Q1 -- "sí" --> R1["listo. Un contenedor con restart, en una máquina."]
    Q1 -- "no, porque…" --> Q2{"¿Lo resolvía compose en una máquina?"}
    Q2 -- "sí" --> R2["listo. Un archivo, una máquina, un respaldo."]
    Q2 -- "no, porque…" --> Q3{"¿Dos servidores, un balanceador<br/>y una lista de comprobación?"}
    Q3 -- "sí" --> R3["listo. Lo que ya hacía Contingencia."]
    Q3 -- "no, porque…" --> Q4{"¿De verdad un orquestador?<br/>¿Propio o gestionado?"}
```

### 4.1 ¿Lo resolvía un contenedor y un servicio del sistema?

Para **`pricing` solo, sí**. Es un binario de 8,5 MB que arranca en 0,16 s (B-04), sin estado más allá de su base. El
problema que lo sacó del Siga —la circular de precios que llega un martes y se aplica el domingo de la semana siguiente
(historia §3)— no era de orquestación: era de **despliegue**. Un contenedor, una unidad de `systemd` (o un servicio de
Windows) que lo reinicia, y un despliegue que no espera la ventana del Siga, contestan esa pregunta.

**Lo que lo hace insuficiente:** que el proceso viva no es que sirva. `restart: always` dejó un `replenish` con la sonda
fallando 25 s sin reiniciarlo, y uno detenido con `docker kill` no volvió nunca (instinto "`restart: always` y un
`healthcheck`"). Si un servicio caído un rato no le cuesta a nadie, eso alcanza.

### 4.2 ¿Lo resolvía compose en una máquina?

Para **el POC entero, sí**, y la Parte 0 lo demostró: los cinco servicios y el patrimonio corriendo en un archivo, con la
suite pasando ([Fase 02](02-compose-el-sistema-en-un-archivo.md)). El patrimonio completo ocupa 0,8 GiB en compose (B-00);
la plataforma de Kubernetes sola, antes del primer servicio, 1,56 GiB.

**Lo que lo hace insuficiente**, con número: compose no reemplaza lo que no sirve (arriba), su `--scale` dejó réplicas sin
recibir nada en cuatro de cuatro corridas con conexiones reutilizadas (instinto "`--scale` me da réplicas"), un despliegue
sin `preStop` perdió de 18 a 39 peticiones de 8.000 (instinto "Si el proceso apaga con cortesía…"), y todo vive en **una**
máquina. Para La Vecina, una máquina es exactamente el nodo central de Bucaramanga del 14 de octubre.

### 4.3 ¿Dos servidores, un balanceador y una lista de comprobación?

Es la respuesta que La Vecina ya conoce, y no es una mala respuesta: el cluster de WebLogic de 2012 y Contingencia son
eso. Dos máquinas con compose detrás de un balanceador, un Postgres gestionado y un procedimiento escrito para desplegar
sin cortar (sacar una del balanceador, actualizar, devolverla) resuelven la disponibilidad de cinco servicios sin una
sola pieza nueva que aprender.

**Lo que lo hace insuficiente** depende de cuántas cosas cambian y cuántas veces. Con cinco servicios desplegando un martes
cada uno por su lado, la lista de comprobación se vuelve el trabajo de alguien. Y la Parte III es esa lista escrita por la
plataforma: sondas que deciden el tráfico, cuotas, certificados que se renuevan solos (la [Fase 19](19-tls-y-certificados.md)),
`NetworkPolicy`. Cada una se puede hacer a mano en dos servidores; ninguna se hace sola.

### 4.4 ¿De verdad un orquestador?

Lo que el orquestador dio en este curso, con número: reemplazar lo que deja de servir, rollouts sin cortes (cero
peticiones perdidas con `preStop`; 12.663 respuestas 200 en el rollout del proyecto final), un paquete que instala el
sistema entero con otros valores (la segunda cadena: 212 MiB y un archivo, [Fase 14](14-helm-en-operacion.md)), un
rollback en 1,2 s, y la red cerrada por cadena.

Lo que **no** dio, también con número: no escaló lo que no estaba ocupado (un vecino lento llevó el p95 de `inventory` de
17,6 ms a 5,54 s sin una alarma de CPU, instinto "Si es lento, el orquestador lo escala"); su `Service` mandó el 100 % del
gRPC a una réplica (B-23); su autoescalado tardó medio minuto y en una corrida no escaló nunca (instinto "El autoescalado me
salva del pico"); y **nada de la Parte IV**: la saga dejó 8 motos huérfanas en 20 préstamos hasta que se escribió una clave,
el pub/sub duplicó en cada rollout, y la escritura dual perdió avisos con cualquier bus. Eso lo arregló el código.

Y lo que cuesta: 15 de los 27 incidentes del cuaderno existen **porque hay un orquestador** (la familia de plataforma),
y otros 7 porque hay certificados que antes no había que manejar. Ese es el precio en domingos.

### 4.5 La recomendación de Valentina, en dos ramas

**Rama 1 · La Vecina sola.** Para una cooperativa de 263 droguerías, con un equipo que opera WebLogic y no opera
contenedores, **un Kubernetes propio no se justifica**. Lo que el curso recomienda, en orden:

- **Contenedores sí, y ya**: empaquetar y desplegar por servicio es lo que contesta la circular de los martes, y no
  necesita un cluster.
- **Separar por responsabilidad, con timeouts**: la respuesta a la pregunta de Germán no es un orquestador. La caja de
  Yolanda se congeló porque todo compartía un pool en el nodo central (historia §3), y en el laboratorio un vecino lento
  tumbó a `inventory` por los hilos con el orquestador mirando. Lo que lo evita es una base por servicio, timeouts y un
  circuito (Fases [12](12-estado-y-almacenamiento.md) y [22](22-resiliencia-y-caos.md)).
- **Dos máquinas con compose y un Postgres gestionado**, o los contenedores gestionados del proveedor (sin cluster que
  administrar), hasta que la cantidad de servicios o de despliegues haga de la lista de comprobación un puesto de trabajo.
- **La Parte IV, entera**, el día que el préstamo salga del Siga: la saga, el outbox y la clave no dependen de dónde corran.

**Rama 2 · La Vecina con una segunda cadena.** Aquí la cuenta cambia, y el curso lo midió: la misma plataforma, instalada
otra vez con un archivo de valores, por 212 MiB; cuotas para que una cadena en quincena no le quite la máquina a la otra
([Fase 15](15-salud-y-recursos.md)); la red cerrada entre las dos ([Fase 20](20-seguridad-del-pod-y-de-la-red.md)).
Con diez cadenas, dos servidores por cadena son veinte servidores y diez listas. **Un orquestador, y gestionado**: el plano
de control lo opera el proveedor, y el equipo opera lo que el curso enseñó. Con una advertencia que también se midió: la
red no separó el Postgres compartido. La identidad de cada cadena (sus usuarios, sus certificados) es trabajo propio, y en
un producto que se vende es lo primero que pregunta un cliente.

> 🧭 **Por qué dos ramas y no una.** La pregunta "¿necesitamos Kubernetes?" no tiene respuesta sin la otra: "¿para cuántos
> sistemas iguales?". Para uno, el orquestador es costo fijo; para diez, es lo que hace posible el negocio que dibujó Don
> Aurelio en la servilleta. Germán decide en cuál rama está La Vecina, y eso no lo decide el curso.

### 4.6 Lo que vale en cualquiera de las dos ramas

Hay decisiones del curso que no dependen de la rama, y son las que conviene tomar el lunes.

**El motor no es una decisión de arquitectura.** Docker y Podman ocuparon lo mismo con la misma memoria (B-00), y la
diferencia entre ellos fue menor que la dispersión de cada uno; Docker gana en tiempo de build y de cluster, Podman en lo
que corre alrededor de la máquina virtual (B-05). Para La Vecina, con más de 250 empleados, la licencia de Docker Desktop
por puesto es una línea de factura (historia §5.4): Podman la evita sin cambiar una sola línea del laboratorio. Es una
decisión de compras, y se puede tomar con los dos números delante.

**El runtime decide el costo, no la cantidad de réplicas.** A la misma tasa, tres de los cuatro servicios cumplieron con
una réplica; lo que cambió fue cuánto cuesta cada una: `inventory` ocupa siete veces lo que `pricing` (B-16), su imagen
pesa cuarenta y cinco veces más y arranca siete veces más lento (B-04). El Núcleo sabe Java desde 2008, y eso vale más que
la diferencia; pero cuando un servicio nuevo no tiene dueño todavía, el número está ahí. Y PHP-FPM escala por procesos, no
por réplicas: lo primero que se ajusta en `catalog` es el pool, no un autoescalado.

**El método vale más que la plataforma.** Los contratos en OpenAPI con una suite por paso, los prompts publicados que
generaron el código, y el cuaderno con los primeros treinta segundos de cada incidente sobreviven a cualquier rama: a
compose, a dos servidores o a un cluster gestionado. La suite de conformidad es lo que hizo posible cambiar el bus, la
saga y el despliegue en tres fases sin romper la venta; y el cuaderno es la respuesta concreta a *"¿quién lo arregla un
domingo?"*: el que lo abre en la página del síntoma.

**La prueba contra el motor real.** Probar contra SQLite ahorra siete segundos por corrida y dejó pasar un error que
Postgres atrapó (B-12). En cualquier rama, las pruebas que tocan SQL corren contra el motor que va a producción.

**Medir antes de escalar, y apostar antes de medir.** Veintisiete fases con una apuesta escrita antes de ejecutar dejaron
apuestas ganadas, perdidas y a medias, y las perdidas fueron las que enseñaron: el autoescalado que reaccionó antes de lo
que se esperaba pero no alcanzó, el pub/sub que duplicó en vez de perder, la compensación que no terminaba. Una
recomendación que no muestra sus apuestas perdidas no es un veredicto: es una presentación de ventas.

---

## 🌩️ 5. El diccionario local ⇄ nube, consolidado

El diccionario completo, en las dos direcciones y con una fila por fase, está en [a05](a05-diccionarios.md#️-local--nube).
Aquí van las filas que deciden una oferta:

| En el laboratorio | En OCI | En Azure | 🚧 Lo que el laboratorio nunca te dio |
|---|---|---|---|
| kind en un portátil | OKE | AKS | un plano de control que opera otro, con su acuerdo de servicio |
| `extraPortMappings` y un `NodePort` | un balanceador del proveedor | un balanceador del proveedor | una IP pública, su DNS y su factura mensual por puerta |
| un `StatefulSet` de Postgres escrito a mano | Postgres gestionado | Postgres gestionado | respaldos, réplicas y actualizaciones que hace otro |
| un nodo de 3,8 GiB; un pod que no cabe queda `Pending` | grupos de nodos con autoescalado | lo mismo | nodos que aparecen solos, y que se cobran por `requests`, no por uso |
| tres nodos-contenedor en una máquina | nodos en varias zonas | lo mismo | que un nodo se caiga de verdad, con su disco y su red |
| Prometheus, Loki y Tempo con un día en `emptyDir` | los servicios gestionados del proveedor | lo mismo | retención por meses y una factura por serie, por GB y por span |
| la saga, el bus y el outbox escritos a mano | motores de flujos y colas gestionados | Durable Functions, Service Bus | nada: las compensaciones, la clave y el consumidor idempotente siguen siendo tuyos |
| la `ServiceAccount` sin token, y secretos en `.secrets/` | identidad de carga de trabajo del proveedor | lo mismo | que un pod pruebe quién es ante la base o el bus sin una contraseña |

Y al revés, para leer una oferta: cada servicio gestionado que se nombra en ella reemplaza **una** fila de la columna del
laboratorio, nunca la última. Lo que el proveedor no puede vender es la decisión de qué es único, qué se compensa y qué
significa un timeout.

**Tres preguntas para cada oferta**, sacadas de lo que el laboratorio mostró y no pudo mostrar:

1. **¿Qué opera el proveedor y qué opero yo?** El plano de control, los nodos y el balanceador suelen ser del proveedor;
   las sondas, los límites, las cuotas, los certificados internos y las políticas de red siguen siendo del equipo (las
   Partes II y III enteras). Si la oferta no lo separa, pregúntalo fila por fila.
2. **¿Qué se cobra por uso y qué por promesa?** En un cluster gestionado los nodos se pagan por lo que piden los pods
   (`requests`), no por lo que usan, y la observabilidad se paga por serie, por GB y por span. Las mediciones de memoria del
   curso (B-00, B-16) son el punto de partida para esa cuenta, nunca el resultado.
3. **¿Qué pasa el domingo?** Qué cubre el acuerdo de servicio, quién contesta, y qué de los 27 incidentes del cuaderno
   desaparece con la oferta. Los de plataforma, en buena parte; los de certificados internos y los de la Parte IV, ninguno.

> 🚧 **La frontera, en una frase:** el laboratorio enseñó todo lo que pasa adentro del cluster, y nada de lo que cuesta
> tenerlo afuera: disponibilidad del plano de control, zonas, balanceadores reales, autoescalado de nodos, identidad, y la
> factura. Ninguna fase la cruzó, y esta no la promete.

---

## 🏗️ 6. El proyecto final

### 6.1 El encargo

Agregas **un servicio nuevo** al sistema, de cero, sin que ninguna fase te lo explique paso a paso, y sin tocar el código
de los otros cuatro. La plataforma tiene que reconocerlo como a uno más. El servicio es tuyo: si no tienes uno en mente,
el de La Vecina es **`notify`**, el que avisa a la droguería cuando su existencia de un producto bajó del umbral, el aviso
que la saga y la coreografía dejaron escrito en un log.

Lo que entregas, en tu repositorio, con un tag por hito:

1. **El contrato**: `contracts/openapi/<svc>.yaml`, con las rutas de plataforma (`/health/live`, `/health/ready`,
   `/metrics`) y las suyas.
2. **La imagen**: un Dockerfile multi-stage, con la base por digest y un usuario sin privilegios
   ([Fase 04](04-empaquetar-los-cuatro-runtimes.md)).
3. **El subchart**: `charts/platform/charts/<svc>/`, con el `Deployment` escrito por ti y el `Service` y la `HTTPRoute` de
   `lab-common`; una dependencia y un interruptor en el paraguas; el tag en `STEP_TAGS`.
4. **Las sondas y los límites**, medidos y no copiados ([Fase 15](15-salud-y-recursos.md)).
5. **Las métricas**: el histograma `http_server_requests_seconds` con `method`, `uri` y `status`
   ([Fase 17](17-metricas-y-dashboards.md)), y los logs en una línea JSON por evento ([Fase 18](18-logs.md)).
6. **Su papel en la saga o en la coreografía**: un consumidor durable propio de un evento que ya existe
   (`lab.inventory.stock-low`), idempotente por `eventId` ([Fase 26](26-idempotencia-y-outbox.md)); o un paso de la saga
   con su compensación ([Fase 24](24-la-saga-orquestada.md)).
7. **Su suite**: `contracts/conformance/<svc>.g13.hurl`, que se corre con las demás.

### 6.2 Los criterios de aceptación

Todos son comandos. El proyecto está aceptado cuando los siete salen como se dice:

```bash
# 1. La suite: la del servicio, junto con las demás del último paso
task conformance TARGET=cluster PROFILE=lab -- G13          # Success /suite/<svc>.g13.hurl, y las otras en verde

# 2. La puerta, sin tocar el Gateway ni las rutas de los demás
curl -s -o /dev/null -w '%{http_code}\n' http://api.localhost:8080/<svc>/health/live        # 200

# 3. El tablero: Prometheus lo descubre solo, y el panel "Peticiones por segundo" lo muestra
task obs:on -- dashboards
#   en Prometheus: up{service="<svc>"} == 1, y
#   sum by (service) (rate(http_server_requests_seconds_count{uri!~"/health.*|/metrics"}[1m])) tiene su fila

# 4. Un rollout sin cortes, con tráfico continuo por la puerta
kubectl -n apps rollout restart deploy/<svc>                # cero respuestas que no sean 200 durante el rollout

# 5. Su papel: una venta bajo el umbral llega a tu servicio, y una entrega repetida no lo duplica

# 6. Un incidente provocado y diagnosticado: rompe algo tuyo (la sonda, el selector, el límite), escribe su entrada con
#    el formato del cuaderno, y comprueba que la plataforma lo contuvo (el pod viejo atendiendo, el rollback de Helm)

# 7. Los otros cuatro, intactos
kubectl -n apps get pods        # ningún pod de pricing, inventory, catalog, replenish o storefront más joven que tu despliegue
```

**Criterio de salida:** al borrar el servicio, no queda nada suyo en el cluster, tampoco en el bus (un consumidor durable
que nadie lee acumula pendientes para siempre).

### 6.3 Hecho una vez, antes de publicarlo

Este enunciado se ejecutó de punta a punta el 05/10/2026 con `notify` (Go, unas 150 líneas, en una copia del laboratorio),
para que ningún criterio fuera una promesa. Lo que salió:

```text
Success /suite/notify.g13.hurl (9 request(s) in 1202 ms)
Success /suite/inventory.g13.hurl (15 request(s) in 1248 ms)
HTTP/1.1 200 OK                                   # /notify/health/live por la puerta
target notify up                                  # Prometheus lo encontró sin tocar su configuración
notify 1.87                                       # la consulta del panel "Peticiones por segundo"
respuestas durante el rollout: {200: 12663}
```

El build tomó 14,7 s y el despliegue 25 s; ningún pod de los otros cinco se recreó. El incidente provocado fue la readiness
en una ruta que no existe (`/health/readyz`): `Readiness probe failed: HTTP probe failed with statuscode: 404`, el rollout
atascado hasta `Progress deadline exceeded`, y `--rollback-on-failure` de vuelta a la revisión anterior a los 2 min 17 s,
con el pod viejo contestando 200 todo el tiempo. Y la limpieza encontró el criterio de salida: el chart se llevó el
`Deployment`, la ruta y el `Service`, pero dejó en NATS el consumidor durable `notify-stock-low`, que hubo que borrar a mano.

Lo que el proyecto **no** pide y la prueba dejó a la vista: `notify` guarda sus avisos en memoria, y un rollout los borra.
Si tu servicio tiene datos, la [Fase 12](12-estado-y-almacenamiento.md) también es parte del proyecto.

---

## ⚠️ 7. Errores comunes

**El orquestador por reflejo.** "Lo pusimos en Kubernetes" no es una decisión de arquitectura: es una de operación, con
15 incidentes de plataforma en su cuaderno. Si la pregunta 4.1 o 4.2 se contestaba con sí, cada una de esas entradas es
trabajo que no hacía falta.

**Una medición única como argumento.** Las mediciones del curso tienen tres corridas y dispersión porque una sola mintió
más de una vez: B-04 midió la caché del motor antes de rehacerse, y la apuesta 1 de la [Fase 26](26-idempotencia-y-outbox.md) apareció a la tercera
corrida. Una cifra sin rango no sostiene una rama del árbol.

**Confundir proporción con capacidad.** "`inventory` ocupa siete veces lo que `pricing`" (B-16) es una proporción que
viaja; "el laboratorio aguanta 300 peticiones por segundo" es una capacidad de un portátil, y no dice nada de una quincena
en Bogotá.

**Creer que la nube resuelve la Parte IV.** Ninguna fila del diccionario reemplaza la clave de idempotencia ni la
compensación (sección 5).

**Copiar la configuración en vez de medirla.** Las sondas, los límites y las cuotas de este laboratorio salieron de
medir los servicios de este laboratorio. Un límite de memoria medido con poca carga mató a `pricing` en el pico de la
[Fase 16](16-escalado-y-rollout.md); copiado a otro servicio, puede matarlo en reposo.

**Dejar el veredicto sin dueño.** El árbol dice qué piso alcanza; quién decide subir de piso, y con qué número, es una
decisión de la organización. Si nadie la tiene escrita, el sistema sube de piso solo, un servicio a la vez, y nadie
recuerda por qué.

**Elegir la rama 2 sin la segunda cadena.** El producto de Don Aurelio es un sueño sin fecha (historia §5.5). Montar la
plataforma para diez cadenas cuando hay una es pagar el costo fijo de la rama 2 con los ingresos de la rama 1.

---

## 📋 8. Checklist de validación

```text
[ ] cada rama del árbol de la sección 4 cita una medición, un instinto o un incidente, y la tabla de la sección 3 lo dice
[ ] la recomendación tiene dos ramas, y cada una dice qué número la cambiaría
[ ] el diccionario de la sección 5 tiene la frontera escrita, sin prometer lo que el laboratorio no mostró
[ ] el proyecto final: los siete criterios de la sección 6.2 salen en tu laboratorio
[ ] al borrar tu servicio, no queda nada suyo en el cluster ni en el bus
```

---

## 🧪 9. Ejercicios (12)

Son de criterio: un sistema descrito, una capa elegida, y la defensa con un número del curso.

### 🟢 Ejercicio 1 — La tabla, completa
Para cada fila de la tabla de la sección 3, encuentra el número en el documento que cita y compáralo con lo que salió en
tu máquina.

**Criterio:** la tabla con una columna más, la tuya, y una nota donde no coincidan.

<details><summary>Solución</summary>

Las filas de B-NN se reproducen con `task measure`; las de instintos, con el experimento de su fase. Si tu máquina da
otra cosa, la proporción es la que tiene que sobrevivir, no el número.
</details>

### 🟢 Ejercicio 2 — La pregunta de Germán
Contesta en un párrafo por qué un pico en Bogotá congelaba la caja de Yolanda en Girón, y qué fase del curso lo evita.

**Criterio:** un párrafo que nombra el pool compartido y lo que lo separa.

<details><summary>Solución</summary>

Todo compartía el pool del nodo central (historia §3): un vecino lento ocupa los hilos de todos. Lo evitan una base por
servicio ([Fase 12](12-estado-y-almacenamiento.md)) y los timeouts con circuito ([Fase 22](22-resiliencia-y-caos.md)),
no el orquestador, que en la [Fase 22](22-resiliencia-y-caos.md) no tuvo nada que escalar.
</details>

### 🟢 Ejercicio 3 — Contar los domingos
Cuenta en el cuaderno cuántos incidentes no existirían si el sistema corriera en compose en una máquina.

**Criterio:** el número, con la lista de IDs.

<details><summary>Solución</summary>

La familia de plataforma (15) existe porque hay un orquestador; varios de certificados, también (el `Certificate` y el
emisor de cert-manager). Los de ambiente existen en cualquier caso. Es el precio en domingos de la sección 4.4.
</details>

### 🟡 Ejercicio 4 — Un sistema descrito: la caja de Contingencia
Contingencia corre en sesenta sitios, cada uno con un computador debajo del mostrador. ¿Qué piso del árbol le corresponde?

**Criterio:** el piso, con el número que lo sostiene.

<details><summary>Solución</summary>

Un contenedor y un servicio del sistema operativo (4.1), o compose si suma el portal y la Braqui: el patrimonio entero
ocupa 0,8 GiB en compose (B-00); un cluster vacío, 1,56 GiB. Sesenta clusters serían sesenta planos de control debajo de
sesenta mostradores.
</details>

### 🟡 Ejercicio 5 — Un sistema descrito: el portal de Daniela
El portal es un Laravel en un servidor alquilado, con su SQLite y un job nocturno. ¿Qué le recomiendas?

**Criterio:** una recomendación de un párrafo con el piso del árbol y su número.

<details><summary>Solución</summary>

Un contenedor y compose en el mismo servidor, con la base fuera del contenedor y un respaldo; el job nocturno, un `cron`
del sistema o un servicio de compose. PHP-FPM escala por procesos y no por réplicas (B-16), así que lo primero que
cuidar es `pm.max_children`, no un HPA.
</details>

### 🟡 Ejercicio 6 — La rama que cambia
¿Qué número tendría que cambiar para que la rama 1 se vuelva la rama 2?

**Criterio:** el número, dónde se mide, y desde qué valor cambia la recomendación.

<details><summary>Solución</summary>

La cantidad de sistemas iguales que hay que operar (cadenas) y de despliegues independientes por semana. Una segunda
cadena con su chart cuesta 212 MiB y un archivo; una segunda cadena con dos servidores, dos servidores y una lista. El
cruce depende del costo de la persona que opera, que el curso no midió: dilo.
</details>

### 🟡 Ejercicio 7 — Leer una oferta
Toma una oferta de Kubernetes gestionado (inventada o real) y marca qué filas de la sección 5 reemplaza y cuáles no.

**Criterio:** la tabla marcada, y la lista de lo que la oferta no dice.

<details><summary>Solución</summary>

Reemplaza el plano de control, el balanceador, los nodos y quizá la observabilidad; no reemplaza la Parte IV ni la
identidad entre cadenas. Lo que no dice suele ser la factura de la observabilidad por serie y por GB.
</details>

### 🟠 Ejercicio 8 — El proyecto final, con otro servicio
Haz el proyecto final con un servicio distinto de `notify` y con base de datos propia.

**Criterio:** los siete criterios de la sección 6.2, más una migración como `Job` y una suite que sobreviva al rollout con
sus datos.

**Rúbrica:** el `Secret` de su base y su usuario en Postgres ([Fase 12](12-estado-y-almacenamiento.md)); la readiness por
la base ([Fase 15](15-salud-y-recursos.md)); la `NetworkPolicy` de salida que ya lo deja llegar a Postgres; y el incidente
documentado con el formato del cuaderno.

### 🟠 Ejercicio 9 — El argumento contrario
Escribe la mejor defensa posible de un Kubernetes propio para La Vecina sola, usando solo números del curso.

**Criterio:** una página que no use ningún número que el curso no midió.

**Rúbrica:** los rollouts sin cortes, el paquete reinstalable, el rollback de 1,2 s, la red cerrada, el diagnóstico con
método. Y una sección honesta de lo que el argumento no puede responder: el costo en personas.

### 🟠 Ejercicio 10 — Las réplicas que sobraron
Con B-16, calcula cuántas réplicas pide cada servicio a 300 peticiones por segundo, y cuánta memoria cuesta cada decisión.

**Criterio:** la tabla de réplicas y memoria por servicio, y la memoria total contra la de una réplica de cada uno.

**Rúbrica:** tres servicios con una réplica y `catalog` con dos; la memoria por réplica de B-16 (Java siete veces Go). Y la
advertencia: es una tasa de laboratorio, no la de La Vecina.

### 🔴 Ejercicio 11 — La recomendación, para la asamblea
Escribe la recomendación de la sección 4.5 en dos páginas para la asamblea, sin una palabra técnica que no se explique.

**Criterio:** dos páginas que contestan "cuánto cuesta y quién lo arregla un domingo" con números del curso.

**Rúbrica:** la condición de Germán: cada número con su prueba repetible, y lo que no se midió, dicho. Las dos ramas. Y la
frase de Doña Graciela: lo que se presta se devuelve, también la plata de los socios.

### 🔴 Ejercicio 12 — El curso, desde el otro lado
Elige una decisión del curso que harías distinto (un componente, un orden de fases, una medición) y defiéndela con lo que
mediste.

**Criterio:** la decisión, el experimento que la sostiene, y su resultado en tu laboratorio.

**Rúbrica:** el mismo formato que una autopsia: la decisión con su mejor argumento, qué pasó, cuánto cuesta cambiarla y qué
pregunta la habría cambiado. Sin juicio sobre nadie.

---

## 📚 10. Referencias

**Libros base del curso** (las ediciones de la guía de estilo)

- Sam Newman, *Building Microservices*, 2.ª edición, O'Reilly, 2021, capítulos 1 y 16: cuándo no conviene partir un
  sistema, dicho por quien escribió el libro sobre partirlos.
- Betsy Beyer y otros (eds.), *Site Reliability Engineering*, O'Reilly, 2016, capítulos 2 y 3:
  https://sre.google/sre-book/table-of-contents/ — el costo de operar, y por qué la confiabilidad tiene precio.
- Brendan Burns, Joe Beda, Kelsey Hightower y Lachlan Evenson, *Kubernetes: Up and Running*, 3.ª edición, O'Reilly, 2022,
  capítulo 1: lo que el orquestador promete, para leerlo con el árbol de la sección 4 delante.
- Chris Richardson, *Microservices Patterns*, Manning, 2018, capítulo 1: la "pila de decisiones" antes de los patrones.

**Orden de lectura sugerido:** antes, el capítulo 1 de Newman; durante, la tabla de la sección 3 con
[BENCHMARKS.md](BENCHMARKS.md) abierto; después, los capítulos 2 y 3 del libro de SRE, para la cuenta de los domingos.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 11. Resultado del curso

```text
LO QUE QUEDA

  src/lab/        el sistema: cinco servicios en cuatro runtimes, el patrimonio, un chart para dos cadenas,
                  la puerta, la observabilidad por piezas, el bus, la saga, el outbox, y su Taskfile
  BENCHMARKS.md   seis mediciones con su arnés, y B-00 en a01
  INSTINTOS.md    los reflejos que trajiste, con la apuesta que los puso a prueba
  el cuaderno     27 incidentes, con los primeros treinta segundos de cada uno
  la recomendación de Valentina, en dos ramas, y tu proyecto final
```

> **La señal de que quedó bien:** *"Antes de proponer un orquestador, sé contestar si alcanzaba con menos; y cuando hace
> falta, sé qué me da, qué no me da, y cuánto me cuesta, con un número que alguien puede repetir."*

En el escritorio de Germán sigue la carpeta que dice *"Primera ronda"*, con las dos ofertas de nube; la recomendación de
Valentina es lo que faltaba para leerlas. Y la servilleta de Don Aurelio sigue doblada en cuatro en la cartera de Doña
Graciela (historia §5.5), con la respuesta que ella le dio a la salida de la asamblea, que es también la mejor síntesis de
este curso:

> *"Primero que funcione, Aurelio. Después hablamos de holdings."*

> 🏷️ **Tag:** `fase-27-el-veredicto-y-el-proyecto-final` · prefijo de commit `f27:`
>
> ```bash
> git tag -a fase-27-el-veredicto-y-el-proyecto-final -m "F27 cerrada: el árbol de decisión con un número por rama, la recomendación en dos ramas (La Vecina sola, y con una segunda cadena), el diccionario local-nube consolidado, y el proyecto final aceptado por comandos"
> ```

---

## 📌 Pendientes sugeridos

- **README del curso (T15):** el árbol de la sección 4 en una línea, como la promesa del curso, y el proyecto final como su
  criterio de éxito.
- **`a05`:** las filas de "identidad de carga de trabajo" y de "factura de la observabilidad", que la sección 5 nombra con
  más detalle que el diccionario.
