# 🩺 Fase 15 — Salud y recursos: la sonda que decide el tráfico y el límite que decide la vida

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 15 de 27 · Parte II — El despliegue · **densa** ⭐
> **Perfil:** `minimo`, con las dos cadenas y el patrimonio encendidos donde se dice · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: las sondas, los límites y las cuotas son del cluster
> **Servicios que toca:** los cuatro backends y `storefront`; Contingencia y Postgres · **Paso de generación:** G4 · Readiness real
> **Depende de:** [Fase 14](14-helm-en-operacion.md) · **Habilita:** [Fase 16](16-escalado-y-rollout.md)
> **Incidentes que reserva:** 12, 13, 14, 15 · **Medición:** ninguna con identificador; las de esta fase quedan en sus secciones
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a16](a16-el-patrimonio.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** que ningún pod reciba tráfico antes de poder atender ni se reinicie por estar ocupado; que cada contenedor pida la memoria que usa y no la de la máquina de la que vino; y que una cadena no le pueda quitar la máquina a la otra.

---

## 🧭 1. Dónde estamos

El sistema se instala con un comando y un archivo de valores ([Fase 14](14-helm-en-operacion.md)), y Kubernetes cree que todo está bien
todo el tiempo: ningún contenedor declara cuándo está listo, cuánta memoria necesita, ni cuánta puede
usar. Para el cluster, un contenedor que arrancó es un contenedor listo, y uno que no tiene límite puede
tomar la máquina entera.

El Núcleo trajo `inventory` con lo que sabía. En el Siga, cada servidor de WebLogic arranca desde 2015
con los mismos parámetros de la JVM, copiados de servidor en servidor (historia §1.6), y los pusieron en
el contenedor. Desde entonces, `inventory` se cae bajo carga **sin escribir una línea de error**: el log
termina en una petición que respondió 201, y el pod vuelve a empezar.

Luz Marina reconoció la escena, y no por Java:

> *"Eso es Contingencia el 14 de octubre, al revés. Contingencia tenía una regla: si el Siga no contesta,
> me prendo. El Siga contestaba, solo que en un minuto. Le preguntamos si estaba vivo, nunca si estaba
> en condiciones de atender."*

Esa es la fase entera: **una pregunta para saber si el proceso vive, otra para saber si puede atender**,
y la memoria contada contra el contenedor, no contra la máquina de antes.

---

## 🎯 2. Objetivos de esta fase

1. Generar G4: la readiness de cada backend dice la verdad (su base contesta), y la suite del paso pasa.
2. Ver los dos fallos por separado: la readiness que corta tráfico y la liveness que mata pods sanos.
3. Elegir `requests` y `limits` con la memoria medida de cada contenedor, y saber qué cambia en su clase de
   QoS, incluidos Contingencia y Postgres.
4. Reproducir el `OOMKilled` de la JVM de hoy y salir de él con número.
5. Poner una cuota por namespace con las dos cadenas encendidas, y comprobar que una no alcanza a la otra.

---

## 🚫 3. Qué NO entra todavía

- El apagado limpio ante `SIGTERM` y el `preStop` → [Fase 16](16-escalado-y-rollout.md).
- `kubectl top`, metrics-server y el autoescalado → [Fase 16](16-escalado-y-rollout.md).
- Varias réplicas y su reparto entre nodos → [Fase 16](16-escalado-y-rollout.md), perfil `lab`.
- Contenedores efímeros de depuración (`kubectl debug`) → [Fase 21](21-diagnostico.md).
- La comparación completa del AOT cache con la compilación nativa → apéndice [a08](a08-la-jvm-nativa.md).

---

## 🧨 4. El problema, en el laboratorio

Con los servicios de G4 desplegados **sin sondas**, una petición a `inventory` cada 100 ms por la
puerta, y un `kubectl rollout restart deployment/inventory` a los tres segundos:

```text
sin sondas, corrida 1: 421 peticiones; 12 sin 200 (2.9 %); por código: {200: 409, 503: 12}; cortes: desde 3.6 s, 1.3 s
sin sondas, corrida 2: 424 peticiones; 14 sin 200 (3.3 %); por código: {200: 410, 503: 14}; cortes: desde 3.7 s, 1.5 s
sin sondas, corrida 3: 424 peticiones; 12 sin 200 (2.8 %); por código: {200: 412, 503: 12}; cortes: desde 3.5 s, 1.3 s
```

Un segundo y medio sin servicio en cada despliegue. Sin sondas, Kubernetes considera listo a un
contenedor **en cuanto arranca**: el rollout manda tráfico al pod nuevo antes de que Spring abra el
puerto, y baja el viejo. En compose esto no se veía porque no había rollout: había `up -d`, y un corte
entre el contenedor viejo y el nuevo que nadie medía.

> 🩻 **Esto sí funciona igual.** El `healthcheck` de compose es la misma idea: un comando o una petición
> que dice si el servicio está bien. Lo que compose no tiene es la consecuencia: un `healthcheck` en rojo
> no saca al contenedor de ningún balanceador ni lo reinicia ([Fase 06](06-del-compose-al-cluster.md)).

---

## 🧩 5. Las sondas y los recursos, con `pricing`

### 5.1 Tres preguntas distintas

Kubernetes le hace a cada contenedor hasta tres preguntas, cada una con una consecuencia distinta:

- **`readinessProbe` — ¿puedes atender?** Si no, el pod sale de los endpoints de su `Service` y deja de
  recibir tráfico. No se reinicia. **La readiness decide el tráfico.**
- **`livenessProbe` — ¿estás vivo?** Si no, el kubelet mata el contenedor y lo arranca de nuevo. **La
  liveness decide la vida.**
- **`startupProbe` — ¿ya terminaste de arrancar?** Mientras no, las otras dos no cuentan. Es para el
  servicio que tarda en arrancar, para que la liveness no lo mate antes de tiempo.

Hasta G3, la readiness de los cuatro backends respondía `ready` siempre: una sonda que nunca dice que no
es lo mismo que no tener sonda. **G4** la hace verdad. En `pricing`, el piloto
([a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g4)):

```go
// La readiness (G4): lista solo si la base contesta, en menos de un segundo. No pregunta por ningún
// vecino: si pricing dependiera de que otro esté listo, una caída se volvería una cascada.
mux.HandleFunc("GET /health/ready", func(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), time.Second)
	defer cancel()
	if err := s.db.PingContext(ctx); err != nil {
		log.Printf("no listo: la base no contesta: %v", err)
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "not_ready"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
})
```

Y las sondas son valores del subchart (`charts/platform/charts/pricing/values.yaml`), que una plantilla
de `lab-common` convierte en los tres campos:

```yaml
# Las sondas (Fase 15): la readiness pregunta por la base (G4) y decide el tráfico; la liveness pregunta
# solo por el proceso y decide la vida. pricing arranca en milisegundos: no necesita startupProbe.
probes:
  readiness: {path: /health/ready, periodSeconds: 5, timeoutSeconds: 2, failureThreshold: 2}
  liveness: {path: /health/live, periodSeconds: 10, timeoutSeconds: 2, failureThreshold: 3}
```

La readiness pregunta cada 5 s y saca el pod a los dos fallos (10 s); la liveness pregunta cada 10 s y
reinicia a los tres fallos (30 s). **La liveness es más paciente a propósito**: su error se paga con un
reinicio.

Con las sondas, el mismo `rollout restart` de la sección 4:

```text
con readiness, corrida 1: 424 peticiones; 0 sin 200 (0.0 %); por código: {200: 424}; cortes: ninguno
con readiness, corrida 2: 423 peticiones; 1 sin 200 (0.2 %); por código: {200: 422, 503: 1}; cortes: desde 5.9 s, 0.1 s
con readiness, corrida 3: 425 peticiones; 0 sin 200 (0.0 %); por código: {200: 425}; cortes: ninguno
```

La petición que todavía se pierde no es del pod nuevo: es del viejo, que muere con peticiones en vuelo.
Eso es el `SIGTERM`, y lo cobra la [Fase 16](16-escalado-y-rollout.md).

### 5.2 La readiness decide el tráfico… del `Service`

Para ver la readiness trabajar, se le quita lo que necesita: Postgres a cero réplicas un minuto, con la
puerta recibiendo peticiones.

```text
$ kubectl -n data scale statefulset/postgres --replicas=0
statefulset.apps/postgres scaled
$ kubectl -n apps get pods -l app.kubernetes.io/component=backend
NAME                         READY   STATUS    RESTARTS      AGE
catalog-5b74cfcf4-kxznl      1/2     Running   0             28m
inventory-7f564dd6d6-n58h7   0/1     Running   0             60s
pricing-844465cd69-ng4dc     0/1     Running   0             28m
replenish-5fbf5f6978-4xkcc   0/1     Running   1 (25s ago)   28m
$ kubectl -n apps get endpointslices -l kubernetes.io/service-name=pricing -o jsonpath=…
10.244.0.54 ready=false
```

Los cuatro en `0/1`, ninguno reiniciado por una sonda (el reinicio de `replenish` es otra cosa: la
sección 6). Los endpoints, marcados como no listos. Desde adentro del cluster, por el `Service`:

```text
$ kubectl -n apps exec deploy/replenish -- wget -qO- -T 3 http://pricing.apps.svc.cluster.local:8080/health/live
wget: can't connect to remote host (10.96.254.66): Connection refused
```

kube-proxy no tiene a quién mandarle la conexión, y la rechaza. Pero **por la puerta, el tráfico siguió
llegando a `pricing`**:

```text
--- sonda a /pricing/health/live: 872 peticiones; 0 sin 200 (0.0 %); por código: {200: 872}; cortes: ninguno
--- sonda a /pricing/prices: 872 peticiones; 298 sin 200 (34.2 %); por código: {200: 574, 500: 298}; cortes: desde 5.1 s, 30.8 s
```

`/health/live` respondió 200 todo el tiempo, y los 500 de `/prices` son de `pricing`, con el error de la
base en el cuerpo. El proxy del `Gateway` es Envoy, que recibe los endpoints con su estado; su consola de
administración lo dice:

```text
$ curl -s localhost:51900/clusters | grep "apps/pricing" | grep health_flags
httproute/apps/pricing/rule/0::10.244.0.54:8080::health_flags::/eds_status_draining
cluster.httproute/apps/pricing/rule/0.lb_healthy_panic: 489
```

`lb_healthy_panic`: cuando quedan muy pocos endpoints sanos, Envoy entra en **modo pánico** y reparte
entre todos, sanos o no, con la idea de que algo de servicio es mejor que nada. Aquí no quedaba ninguno.
La readiness decide el tráfico de un `Service`; un proxy delante puede decidir otra cosa. Para un lector
del navegador, la diferencia es un 500 de `pricing` en lugar de un 503 de la puerta. Cuando la base
volvió, los cuatro pasaron a `1/1` solos, en menos de 20 s.

### 5.3 La liveness decide la vida, y no sabe por qué tardaste

La liveness pregunta **"¿contestas a tiempo?"**, y a tiempo depende de la máquina. Ocurrió sin buscarlo:
mientras se construía una imagen de 600 MB al lado del cluster, la máquina virtual de 4 GiB se quedó sin
aire.

```text
$ docker stats --no-stream
minimo-control-plane 2.337GiB / 3.825GiB 97.70%
$ kubectl -n apps get events --field-selector reason=Killing
4m33s       Normal   Killing   pod/pricing-844465cd69-ng4dc      Container pricing failed liveness probe, will be restarted
6m4s        Normal   Killing   pod/replenish-7d6bbcf7-z5prm      Container replenish failed liveness probe, will be restarted
6m5s        Normal   Killing   pod/storefront-7775b9d98d-cfjhj   Container storefront failed liveness probe, will be restarted
```

Tres contenedores sanos, reiniciados. Ninguno tenía nada roto: el proceso tardó en contestar porque la
máquina entera tardaba, y el nodo nunca reportó `MemoryPressure`. **Una liveness que falla mata, y un
reinicio no arregla una máquina lenta**: agrega trabajo (Java vuelve a arrancar) en el peor momento. Por
eso la liveness no consulta nada más que el proceso, y es la más tolerante de las tres.

### 5.4 Lo que se promete y lo que se impone

Cada contenedor declara dos números de memoria:

- **`requests`** — lo que se le **promete** al planificador. Un nodo acepta pods mientras la suma de sus
  `requests` quepa en lo asignable, aunque el uso real sea otro. Es la cuenta con la que se reparten los
  nodos.
- **`limits`** — lo que el **cgroup impone**. Un contenedor que lo pasa muere con `OOMKilled`.

Los números del chart salen de medir. La memoria de cada contenedor (el *working set*, leído en el nodo
con `crictl stats`), en reposo y con veinte usuarios pidiendo los cuatro backends durante un minuto:

| Contenedor | en reposo (MiB) | con carga (MiB) | `requests` / `limits` |
|---|---|---|---|
| `pricing` | 6 | 13 | 32 / 64 |
| `inventory` | 216 | 250 | 384 / 512 |
| `catalog`: PHP-FPM · nginx | 31 · 7 | 56 · 10 | 64 / 128 · 16 / 32 |
| `replenish` | 31 | 63 | 64 / 128 |
| `storefront` | 7 | 7 | 16 / 32 |

`inventory` pide treinta veces lo que pide `pricing`, y es la misma proporción que midió
[B-04](BENCHMARKS.md#b-04--cuánto-cuesta-empaquetar-cada-runtime) en las imágenes.

**Sin límite de CPU, a propósito.** Con CPU no pasa lo mismo que con memoria: un contenedor que pasa su
límite de CPU no muere, se **frena**, aunque el nodo esté ocioso. `pricing` con un límite igual a su
`request` (50m), bajo la misma carga de veinte usuarios:

```text
--- sin límite de CPU:  1126–1392 peticiones/s · p95 46–60 ms
--- con límite de 50m:    39–61 peticiones/s · p95 1,39 s
```

Treinta veces menos, con siete CPU libres en el nodo. El `request` de CPU sí va: es lo que reparte la
CPU cuando hay competencia.

**La clase de QoS** sale de esos números, y decide quién muere primero cuando el **nodo** se queda sin
memoria. Antes de esta fase:

```text
apps     catalog-5b74cfcf4-q8ckw          Burstable
…
data     postgres-0                       BestEffort
legacy   contingencia-5ccd487968-7w8k6    BestEffort
legacy   contingencia-db-579d7bd5df-rzqdp BestEffort
```

`BestEffort` —sin `requests` ni `limits`— es el primero que mata el kernel. Es lo que le pasó a
Contingencia tres veces en la [Fase 12](12-estado-y-almacenamiento.md#️-13-errores-comunes-y-diagnóstico). Contingencia ocupa 601 MiB, porque GlassFish arranca con su
`-Xmx512m` de fábrica; Postgres, 54. Los dos llevan ahora sus números (`deploy/legacy/contingencia.yaml`,
`platform/data/postgres/statefulset.yaml`) y pasan a `Burstable`. Y Postgres importa más que ninguno: con
G4, si Postgres muere, los cuatro servicios salen del tráfico.

### 5.5 La cuota: que una cadena no le quite la máquina a la otra

Una cuota (`ResourceQuota`) limita lo que **todos los pods de un namespace** pueden pedir juntos. Es de
plataforma, no del chart, y va con el namespace (`deploy/manifests/namespace.yaml`, y
`platform/tenants/apps-b.yaml` para la segunda cadena):

```yaml
spec:
  hard:
    requests.memory: 1280Mi    # los servicios piden 576 MiB; el resto, para el pod de más de un rollout
    limits.memory: 2Gi
    pods: "20"
```

Con una cuota de memoria, un contenedor sin `requests` no se puede crear. Para los que no los declaran
—los `Job` de migraciones, la suite— va un `LimitRange` al lado, que les pone 64 MiB por defecto.

Con las dos cadenas encendidas:

```text
$ kubectl -n apps describe resourcequota apps | tail -3
limits.memory    896Mi  2Gi
pods             5      15
requests.memory  576Mi  1280Mi
```

Y la quincena de la otra cadena, con una petición a La Vecina cada 100 ms mientras tanto: la apuesta de
la sección 7.

**Prueba de fuego.**

```text
$ task conformance TARGET=cluster -- G4
Success /suite/pricing.g4.hurl (3 request(s) in 4 ms)
Success /suite/inventory.g4.hurl (3 request(s) in 10 ms)
Success /suite/replenish.g4.hurl (3 request(s) in 11 ms)
Success /suite/catalog.g4.hurl (3 request(s) in 25 ms)
Executed files:    4
Succeeded files:   4 (100.0%)
```

Y la de G1, que sigue valiendo para el resto del contrato, en verde.

**El patrón a memorizar.** La readiness pregunta por lo que el servicio necesita para atender, y nada
más; la liveness pregunta solo si el proceso contesta, y con paciencia. Los `requests` se miden, los
`limits` de memoria dejan lugar a lo que no es heap, y la CPU no lleva límite.

---

## 🔁 6. Los otros tres: el mismo campo, cuatro significados

Esta es la sección que solo un curso políglota puede escribir. El campo `readinessProbe` es el mismo en
los cuatro `Deployment`; lo que significa "listo" no.

**El tiempo hasta listo**, desde que el pod se crea hasta que su condición `Ready` pasa a `True`, en tres
`rollout restart` de todo el sistema:

| | corrida 1 | corrida 2 | corrida 3 |
|---|---|---|---|
| `pricing` · `catalog` · `storefront` | 1–2 s | 1–2 s | 1–2 s |
| `replenish` | 2 s | 2 s | 6 s |
| `inventory` | 5 s | 5 s | 3 s |

Son segundos enteros, y con la readiness preguntando cada 5 s: el número incluye la espera de la sonda.
**Y la primera petición después de estar listo**, por la puerta, cinco seguidas:

```text
pricing corrida 1:   0.021386 0.006250 0.002146 0.002142 0.003322
inventory corrida 1: 0.072823 0.004748 0.003978 0.004214 0.003935
catalog corrida 1:   0.025634 0.014851 0.012955 0.012679 0.013887
replenish corrida 1: 0.011393 0.003623 0.003996 0.003676 0.003092
```

**`inventory` (Java)** tarda más en estar listo y su primera petición tarda 73 ms contra los 4 de la
segunda: la JVM carga y compila lo que esa ruta usa la primera vez. Su readiness espera dos cosas: que
Spring diga `ACCEPTING_TRAFFIC` —que llega **después** de abrir el puerto, a diferencia de un puerto
abierto— y que la base conteste. G4 dejó Actuator afuera: el contrato pide `{"status":"ready"}` y
Actuator responde `UP`. Y lleva `startupProbe`, con 120 s de margen: es el único servicio que algún día
puede tardar en arrancar más que la paciencia de la liveness.

**`catalog` (PHP)** tiene el problema de los dos procesos ([Fase 09](09-los-cuatro-servicios-dentro.md)). PHP-FPM escucha en `127.0.0.1:9000`, donde el
kubelet no llega: las sondas van en el contenedor `nginx`, y su `/health/ready` cruza nginx, FPM y
Laravel hasta la base. Una sonda que preguntara solo a nginx diría "listo" con FPM muerto. Y FPM tiene una
capacidad fija: `pm.max_children = 5`, cinco peticiones a la vez. Con 200 usuarios, la mediana del
catálogo fue 593 ms; con 400, una sonda mal calibrada empieza a matar al proceso equivocado: es el
[incidente 14](cuaderno-incidentes.md#-incidente-14--kubernetes-reinicia-un-pod-que-estaba-bien).

**`replenish` (Node)** se reinició cuando cayó Postgres, en la sección 5.2, y ninguna sonda tuvo que
ver. Su log anterior:

```text
    throw er; // Unhandled 'error' event
error: terminating connection due to administrator command
Emitted 'error' event on BoundPool instance at:
```

Postgres cerró las conexiones que estaban quietas en el pool, `pg` emitió `error` en el pool, y en Node un
`error` sin manejador es una excepción que mata el proceso. Se arregló en el prompt de G4 (un manejador
del evento) y la caída siguiente de Postgres no lo reinició. Es el modelo de Node: un solo proceso, y
cualquier error sin atender lo tumba entero.

**`storefront`** no tiene base: su readiness pide `/config.json`, que nginx arma al arrancar (G2). Si lo
sirve, la página tiene su configuración.

### 6.1 🔥 El AOT cache de la JVM

La respuesta de la JVM de hoy al arranque lento: una corrida de entrenamiento al construir la imagen,
que guarda lo que la JVM aprendió al arrancar (clases cargadas y enlazadas, perfiles de métodos) en un
archivo que la siguiente usa (`services/inventory/Dockerfile.aot`):

```dockerfile
# El entrenamiento: arranca la aplicación hasta que el contexto de Spring queda listo, y sale.
RUN java -XX:AOTCacheOutput=app.aot -Dspring.context.exit=onRefresh -jar inventory-0.0.1-SNAPSHOT.jar \
    && chown inventory app.aot
CMD ["java", "-XX:AOTCache=app.aot", "-jar", "inventory-0.0.1-SNAPSHOT.jar"]
```

```text
#22 4.187 AOTCache creation is complete: app.aot 55181312 bytes
sin AOT cache, corridas 1–3: Started InventoryApplication in 1.116 / 1.167 / 1.135 seconds · hasta Ready: 3 / 2 / 2 s
con AOT cache, corridas 1–3: Started InventoryApplication in 0.547 / 0.471 / 0.487 seconds · hasta Ready: 3 / 2 / 2 s
```

Spring arranca en menos de la mitad, y la imagen pesa 69 MB más (639 contra 570). El pod queda listo en el
mismo tiempo: con un arranque de un segundo, lo que manda es la sonda. El cache vale cuando el arranque
cuenta —un autoescalado que necesita la réplica ya, un servicio grande—, y no en este. La comparación con
la compilación nativa es el apéndice [a08](a08-la-jvm-nativa.md).

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"con un health check alcanza; y la memoria del contenedor es la que
tenía la máquina"*. En compose y en la máquina virtual, las dos cosas funcionaban: el health check era
informativo y la máquina era del proceso.

> 🪞 **Apuesta antes de ejecutar.** Un `rollout restart` de `inventory` con una petición cada 100 ms por la
> puerta: sin sondas, más del 5 % de las peticiones fallan; con la readiness de G4, menos del 1 %.
>
> **Resultado: perdida la primera mitad, ganada la segunda.** Sin sondas fallaron entre el 2,8 % y el
> 3,3 % (sección 4): menos de lo apostado, y un segundo y medio de corte en cada despliegue igual. Con
> la readiness, 0, 1 y 0 peticiones (sección 5.1).

> 🪞 **Apuesta antes de ejecutar.** Con `-Xmx4096m` y un límite de 512 MiB, `inventory` muere `OOMKilled`
> en menos de cinco minutos de carga sostenida; con el mismo límite y la JVM dimensionándose sola, aguanta
> la misma carga con el pico de memoria del contenedor por debajo del 80 % del límite.
>
> **Resultado: perdida la primera mitad, ganada la segunda.** Con solo `-Xmx4096m`, `inventory` aguantó
> cinco minutos entre 222 y 243 MiB, sin un reinicio: el `-Xmx` es un techo, y la JVM no usa memoria que
> no necesita. Lo que sí la mató fue el `-Xms` (la sección 9). Sin opciones, el pico fue 296 MiB: el 58 %
> del límite.

> 🪞 **Apuesta antes de ejecutar.** Con una `ResourceQuota` de memoria en `apps-b`, la segunda cadena no
> puede crecer más allá de su cuota: la réplica que sobra no se crea, y el evento lo dice (`exceeded
> quota`); `apps` no se entera.
>
> **Resultado: ganada.**

```text
$ kubectl -n apps-b scale deployment/inventory --replicas=3   # la quincena de la otra cadena
$ kubectl -n apps-b get deploy inventory
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
inventory   1/3     2            1           2m38s
$ kubectl -n apps-b get events --field-selector reason=FailedCreate | tail -1
6s          Warning   FailedCreate   replicaset/inventory-6c9f9b7c48   (combined from similar events): Error creating: pods "inventory-6c9f9b7c48-zdxnl" is forbidden: exceeded quota: apps-b, requested: limits.memory=512Mi,requests.memory=384Mi, used: limits.memory=1408Mi,requests.memory=960Mi, limited: limits.memory=1536Mi,requests.memory=1Gi
--- La Vecina, mientras tanto (inventory/reason-codes cada 100 ms): 378 peticiones; 0 sin 200 (0.0 %); por código: {200: 378}; cortes: ninguno
```

La segunda réplica entró en la cuota (960 de 1.024 MiB); la tercera no, y nadie la crea. Sin la cuota, las
tres habrían competido con La Vecina por el mismo nodo.

> 🪞 **Apuesta antes de ejecutar** (🔥). Con el AOT cache de la JVM, `inventory` queda listo en menos de la
> mitad del tiempo que sin él.
>
> **Resultado: perdida.** Spring arrancó en menos de la mitad (0,49 s contra 1,14 s), pero el pod quedó
> listo en los mismos 2–3 s (sección 6.1).

Las entradas están en [INSTINTOS.md](INSTINTOS.md#con-un-health-check-alcanza): la del health check y la
de la memoria de la máquina.

---

## 🧨 8. La rotura: Postgres sin `requests`, y lo que arrastra

Antes de esta fase, Postgres era `BestEffort`, y con G4 su suerte es la de los cuatro servicios. El
experimento de la sección 5.2 lo mostró con un `scale` a mano. **El cambio exacto** que lo provoca en
serio es el contrario: darle **demasiado**. En `apps` no se puede, porque la cuota rechaza el pod; en
`data` no hay cuota. Es el [incidente 15](cuaderno-incidentes.md#-incidente-15--la-réplica-nueva-no-encuentra-dónde-vivir), y su síntoma es este:

```text
$ kubectl -n data get pods
NAME         READY   STATUS    RESTARTS   AGE
postgres-0   0/1     Pending   0          30s
$ kubectl -n apps get pods -l app.kubernetes.io/component=backend
NAME                        READY   STATUS    RESTARTS      AGE
catalog-5b74cfcf4-mpbhr     1/2     Running   0             5m18s
inventory-84f859ffc-ssrf5   0/1     Running   0             8m59s
pricing-844465cd69-ng4dc    0/1     Running   2 (18m ago)   93m
replenish-7d6bbcf7-6zbr2    0/1     Running   0             6m45s
```

Un cambio en un objeto de `data`, cuatro servicios fuera del tráfico. **Lo que costó salir** está en el
cuaderno, y tiene una vuelta que vale la pena descubrir sola. Lo que esta fase se lleva es la cadena: la
readiness hizo exactamente lo que debía —ningún servicio atendió sin base—, y por eso el arreglo de la
base es el arreglo de todo.

---

## ⚰️ 9. Autopsia: el `-Xms4096m -Xmx4096m` del Siga

**La decisión, con su mejor argumento.** El Núcleo arrancó `inventory` con los parámetros de la JVM de los
servidores de WebLogic: `-Xms4096m -Xmx4096m`, el heap fijo de 4 GiB que se copia de servidor en servidor
desde 2015 (historia §1.6). *"Así corre el Siga desde hace diez años sin caerse por memoria."*

**Por qué era razonable.** En un servidor de WebLogic con 16 GB, fijar el heap mínimo igual al máximo
evita que la JVM lo agrande y lo achique bajo carga, y es una práctica de afinación conocida. La JVM era
la dueña de la máquina.

**Qué pasó después, con número.** En un contenedor con límite de 512 MiB, con cuarenta usuarios sobre
`inventory`:

```text
11 s: inventory 407.3 MiB · reinicios: 1 OOMKilled 137
32 s: inventory 450.9 MiB · reinicios: 2 OOMKilled 137
…
222 s: inventory 497.2 MiB · reinicios: 5 OOMKilled 137
    http_req_failed................: 98.48%  4615425 out of 4686234
$ kubectl -n apps logs pod/inventory-7d98cc8858-km9m8 --previous | tail -2
… c.c.lab.inventory.RequestLogFilter       : POST /stock/DRO-011/SKU-0007/movements 201
… c.c.lab.inventory.RequestLogFilter       : GET /reason-codes 200
$ docker exec minimo-control-plane dmesg | grep -i 'killed process' | tail -1
[ 5667.986171] Memory cgroup out of memory: Killed process 83756 (java) total-vm:9842476kB, anon-rss:503764kB, file-rss:4kB, shmem-rss:0kB, UID:10001 pgtables:1876kB oom_score_adj:902
```

Muerto a los 11 segundos, cinco veces en cinco minutos, y el 98 % de las peticiones perdidas. **Ni una
línea de error**: el último renglón del log es un 201. El kernel mató al proceso por pasarse del límite
del cgroup, y la JVM no alcanzó a enterarse.

No fue el `-Xmx`. Con **solo** `-Xmx4096m`, la misma carga durante cinco minutos dejó a `inventory` entre
222 y 243 MiB, sin un reinicio: un techo de 4 GiB no se toca si no hace falta. El `-Xms4096m` es un
**piso**, y con él la JVM organiza desde el arranque un heap de 4 GiB cuya generación joven mide 1,4 GB:

```text
$ kubectl -n apps exec deploy/inventory -- java -Xms4096m -Xmx4096m -XX:+PrintFlagsFinal -version | grep -E " UseSerialGC | NewSize "
   size_t NewSize                                  = 1431633920                                {product} {ergonomic}
     bool UseSerialGC                              = true                                      {product} {ergonomic}
```

La carga la llena de objetos nuevos, página por página, y el contenedor pasa de 512 MiB antes de la
primera recolección. Java 25 sabe que está en un contenedor —sin opciones,
calcula un heap máximo de 128 MiB para el límite de 512 MiB—, pero una opción explícita le gana a lo que
la JVM sabe.

**Cuánto cuesta salir, con número.** Borrar las opciones. La JVM, sola, eligió un heap de 25 % del límite
y, con un contenedor tan chico, el recolector Serial:

```text
[89.991s][info][gc] GC(706) Pause Young (Allocation Failure) 62M->49M(62M) 2.115ms
inventory-79888f47cb-bm95h               inventory      288.9 MiB
```

**62 MiB de heap en un contenedor de 289**: lo que no es heap —metaspace con las clases de Spring, las
pilas de los hilos del servidor, la caché de código compilado, los búferes— pesa tres veces más que el
heap. Por eso un límite se calcula contra el contenedor entero y no contra el `-Xmx`.

**Qué lo habría cambiado.** Una pregunta antes de copiar los parámetros: *¿cuánta memoria tiene este
contenedor, y cuánta le pide la JVM al arrancar?*

**Antes y después, con números:** con `-Xms4096m -Xmx4096m`, cinco `OOMKilled` en cinco minutos y el
98,5 % de las peticiones perdidas; sin opciones, la misma carga durante cinco minutos con la memoria
entre 191 y 296 MiB, cero reinicios y cero peticiones fallidas de 1.435.095.

---

## 📖 10. Traducción

| En compose o en la máquina virtual | En Kubernetes | Lo que cambia |
|---|---|---|
| `healthcheck:` | `readinessProbe`, `livenessProbe` y `startupProbe` | tres preguntas con tres consecuencias: salir del tráfico, reiniciar, esperar |
| `deploy.resources.reservations` | `resources.requests` | es una promesa que el planificador cuenta, no un uso |
| `mem_limit` | `resources.limits.memory` | pasarlo es `OOMKilled`, sin aviso al proceso |
| `cpus` | `resources.limits.cpu` | pasarlo frena el contenedor aunque el nodo esté ocioso |
| `-Xms` y `-Xmx` de la VM | el límite del contenedor, y la JVM calculando su heap contra él | el heap es un pedazo; lo que no es heap también cuenta |
| *sin equivalente* | `ResourceQuota` y `LimitRange` | lo que un namespace entero puede pedir |

Las filas completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, los `requests` deciden **cuántos nodos** pagas: un nodo se llena de promesas, no de uso, y
un autoescalador de nodos crea otro cuando un pod queda `Pending`. 🚧 Aquí hay un solo nodo, y el
`Pending` se queda `Pending`.

---

## 🩺 11. Incidentes de esta fase

- **[12 — `inventory` muere sin decir nada](cuaderno-incidentes.md#-incidente-12--inventory-muere-sin-decir-nada).**
  `CrashLoopBackOff`, y el log tiene una sola línea: la de las opciones de la JVM.
- **[13 — El servicio corre y nunca recibe tráfico](cuaderno-incidentes.md#-incidente-13--el-servicio-corre-y-nunca-recibe-tráfico).**
  `replenish` en `Running` con `0/1`, sin un reinicio, y 500 por la puerta.
- **[14 — Kubernetes reinicia un pod que estaba bien](cuaderno-incidentes.md#-incidente-14--kubernetes-reinicia-un-pod-que-estaba-bien).**
  Con carga, el contenedor `nginx` de `catalog` se reinicia una y otra vez: `Liveness probe failed`.
- **[15 — La réplica nueva no encuentra dónde vivir](cuaderno-incidentes.md#-incidente-15--la-réplica-nueva-no-encuentra-dónde-vivir).**
  `postgres-0` en `Pending`, sin logs, y los cuatro backends en `0/1`.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Una readiness que pregunta por la base cuesta una consulta cada 5 s por pod**: con cuatro servicios,
casi una por segundo contra Postgres, sin tráfico. En un sistema con cientos de réplicas, esa cuenta se
hace antes. Y una readiness que pregunta por más de lo que el servicio necesita convierte cada caída en
una cascada: la de `inventory` no pregunta por `catalog`, aunque en la [Fase 16](16-escalado-y-rollout.md) lo vaya a llamar.

**La liveness casi nunca hace falta para un proceso que muere solo cuando falla.** Go, Node y Java salen
cuando se rompen, y el reinicio lo hace el contenedor sin sonda. La liveness es para el proceso que se
cuelga sin morir; para todo lo demás, es una forma de reiniciar lo que estaba lento, como en la sección
5.3. Si dudas, sin liveness o con una muy paciente.

**Los `requests` cuestan dinero aunque no se usen.** Los cinco servicios piden 576 MiB y usan unos 290 en
reposo; la diferencia es memoria reservada para picos. Medido de menos, el nodo se sobrevende y el kernel
elige a quién matar; medido de más, pagas nodos vacíos.

**Y una cuota solo separa promesas**, no el uso: dos cadenas en el mismo nodo siguen compartiendo CPU,
disco, red y Postgres. La [Fase 20](20-seguridad-del-pod-y-de-la-red.md) separa la red; lo demás es la frontera de un SaaS de verdad.

**Cuándo NO todo esto:** un `Job` que corre una vez y termina no necesita sondas; una herramienta interna
con una réplica y sin despliegues bajo carga puede vivir sin readiness. **Cuándo sí:** cualquier servicio
que se despliega mientras recibe tráfico, y cualquier contenedor que comparte nodo.

**La pregunta del curso, para esta fase:** el contenedor te dio un cgroup que cuenta la memoria de todo lo
que corre adentro. El orquestador te dio las sondas, el planificador que reparte promesas, la QoS y las
cuotas. **Te tocó a ti** escribir una readiness que diga la verdad, una liveness que no mate por lentitud,
medir cada contenedor, y entender la JVM que pusiste adentro.

---

## ⚠️ 13. Errores comunes y diagnóstico

**La readiness falla con `connection refused` en los primeros segundos.** Es normal: la sonda pregunta
antes de que el proceso abra el puerto. Si sigue después, el puerto con nombre `http` no es el del
proceso. Comprobación 🩺: `kubectl -n apps describe pod … | grep Unhealthy`.

**Por la puerta llega tráfico a un pod `0/1`.** Es el modo pánico de Envoy (sección 5.2), cuando no queda
ninguno listo. Por el `Service`, desde adentro, la conexión se rechaza.

**Un `StatefulSet` no reemplaza un pod roto aunque arreglaste la plantilla.** No lo hace con un pod que
nunca estuvo listo: hay que borrarlo (incidente 15).

**`exceeded quota` al desplegar.** No es un error del chart: la cuota del namespace se quedó corta para
el pod de más del rollout, o un `Job` sin `requests` cayó en el `LimitRange`. `kubectl describe
resourcequota -n apps` dice cuánto queda.

**`kubectl top` no funciona.** Todavía no hay metrics-server: llega en la [Fase 16](16-escalado-y-rollout.md). La memoria de un
contenedor, mientras tanto, en el nodo: `crictl stats` ([a04](a04-kubectl-y-k9s.md)).

---

## 📋 14. Checklist de validación

```text
[ ] el rollout sin sondas (2,8–3,3 % perdido) y con la readiness de G4 (0–1 peticiones)
[ ] task conformance TARGET=cluster -- G4 y -- G1 en verde
[ ] Postgres a cero: cuatro servicios 0/1, ninguno reiniciado por sonda; el Service rechaza y la puerta no
[ ] lb_healthy_panic en la consola de Envoy
[ ] la memoria de cada contenedor en reposo y con carga, y los requests y limits elegidos con ella
[ ] pricing con límite de CPU: treinta veces menos peticiones por segundo
[ ] Contingencia y Postgres en Burstable
[ ] -Xmx4096m sin muerte; -Xms4096m -Xmx4096m OOMKilled en 11 s; sin opciones, 191–296 MiB
[ ] la cuota de apps-b rechazando la tercera réplica, y La Vecina sin un error
[ ] los incidentes 12–15 provocados y reparados con inc:break e inc:fix
[ ] 🔥 el AOT cache: Spring en menos de la mitad, el pod listo en lo mismo
```

---

## 🧪 15. Ejercicios (24)

La mitad de diagnóstico o medición; varios con `inventory`, `catalog` y el patrimonio.

## 🟢 Fácil — las sondas y los números (1–7)

### 🟢 Ejercicio 1 — La readiness, en su sitio
Muestra las tres sondas de `inventory` tal como las ve el cluster.

**Criterio:** `startupProbe`, `readinessProbe` y `livenessProbe`, con sus rutas y tiempos.

<details><summary>Solución</summary>

`kubectl -n apps get deploy inventory -o jsonpath='{.spec.template.spec.containers[0]}'`, o `describe
pod` y las líneas `Liveness:`, `Readiness:` y `Startup:`.
</details>

### 🟢 Ejercicio 2 — Listo, no listo
Apaga Postgres y mira cuántos backends quedan listos.

**Criterio:** los cuatro en `0/1` y ningún reinicio nuevo.

<details><summary>Solución</summary>

`kubectl -n data scale statefulset/postgres --replicas=0`, esperar 20 s, `kubectl -n apps get pods`.
Vuelve con `--replicas=1`.
</details>

### 🟢 Ejercicio 3 — El 503 de la readiness
Con Postgres apagado, pide la readiness de `pricing` desde adentro de su propio pod.

**Criterio:** `{"status":"not_ready"}` y la línea del log que dice por qué.

<details><summary>Solución</summary>

`pricing` no tiene shell, y el `Service` ya no tiene endpoints listos: `kubectl -n apps port-forward
deploy/pricing 51081:8080` y `curl -s localhost:51081/health/ready` (el `port-forward` va al pod, no al
`Service`). Y `kubectl -n apps logs deploy/pricing | grep "no listo"`.
</details>

### 🟢 Ejercicio 4 — La clase de cada pod
Lista la clase de QoS de todos los pods de `apps`, `data` y `legacy`.

**Criterio:** `Burstable` en todos los que llevan `requests`.

<details><summary>Solución</summary>

`kubectl get pods -A -o custom-columns=NS:.metadata.namespace,POD:.metadata.name,QOS:.status.qosClass`.
</details>

### 🟢 Ejercicio 5 — La memoria, medida
Mide la memoria de los contenedores de `apps` en reposo.

**Criterio:** una tabla con los seis contenedores y su *working set*.

<details><summary>Solución</summary>

`docker exec minimo-control-plane crictl stats --label io.kubernetes.pod.namespace=apps -o json`, o la
tabla de `crictl stats` con los IDs de `crictl ps`.
</details>

### 🟢 Ejercicio 6 — La cuota
Muestra cuánto de su cuota usa cada cadena.

**Criterio:** `Used` y `Hard` de las dos `ResourceQuota`.

<details><summary>Solución</summary>

`kubectl -n apps describe resourcequota apps` y `kubectl -n apps-b describe resourcequota apps-b`.
</details>

### 🟢 Ejercicio 7 — El heap que elige la JVM
Muestra el heap máximo que calcula la JVM de `inventory` con su límite.

**Criterio:** `MaxHeapSize` de unos 128 MiB, y `MaxRAMPercentage` en 25.

<details><summary>Solución</summary>

`kubectl -n apps exec deploy/inventory -- java -XX:+PrintFlagsFinal -version | grep -E " MaxHeapSize| MaxRAMPercentage"`.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — La readiness de Contingencia
Escribe una readiness para Contingencia que pregunte si su servicio SOAP de precios contesta.

**Criterio:** con su base apagada, el pod de Contingencia en `1/2` (la fachada sigue lista).

<details><summary>Solución</summary>

`httpGet` a `/PriceService/PriceService?wsdl` en el 8080 (GlassFish publica los servicios en la raíz,
[a16](a16-el-patrimonio.md)), con `periodSeconds: 10` y `failureThreshold: 3`, y una `startupProbe` con
margen. Pruébalo antes con `curl` desde un pod: si el WSDL pide la misma autenticación que el servicio, la
sonda lleva la cabecera `Authorization` en `httpGet.httpHeaders`.
</details>

### 🟡 Ejercicio 9 — La liveness de `inventory`, calibrada
Calcula cuánto tiempo puede estar `inventory` sin contestar antes de que la liveness lo reinicie.

**Criterio:** el número, con la cuenta.

<details><summary>Solución</summary>

`periodSeconds × failureThreshold` más el último `timeoutSeconds`: 10 × 3 + 2, unos 32 s. Y la
`startupProbe` le da 120 s al arrancar.
</details>

### 🟡 Ejercicio 10 — El primer request
Mide la primera petición después de un `rollout restart` en `catalog` y en `inventory`.

**Criterio:** las cinco primeras de cada uno, y cuál paga más la primera.

<details><summary>Solución</summary>

El bucle de `curl -w '%{time_total}'` de la sección 6. En la verificación, `inventory` 73–78 ms contra 4;
`catalog` 21–26 contra 13.
</details>

### 🟡 Ejercicio 11 — Sin límite de CPU, con límite
Repite la medición de la sección 5.4 con `inventory`.

**Criterio:** peticiones por segundo y p95 con y sin `limits.cpu` igual a su `request`.

<details><summary>Solución</summary>

`helm upgrade … --set inventory.resources.limits.cpu=250m` y la carga de k6. Vuelve con `task deploy`.
</details>

### 🟡 Ejercicio 12 — Postgres sin `requests`
Quita los `requests` de Postgres y mira su clase y su `oom_score_adj`.

**Criterio:** `BestEffort` y el número que el kernel le asigna.

<details><summary>Solución</summary>

Sin `resources`, `kubectl apply`. Dentro del nodo, el proceso de Postgres y su
`/proc/<pid>/oom_score_adj`: 1000 en `BestEffort`, el primero en morir.
</details>

### 🟡 Ejercicio 13 — Un `Job` sin `requests`
Corre un `Job` cualquiera en `apps` sin `resources`. **Predice** qué recursos tiene su pod.

**Criterio:** la predicción y el `resources` del pod.

<details><summary>Solución</summary>

Los del `LimitRange`: `requests` de 50m y 64Mi, `limits` de 256Mi. Sin el `LimitRange`, la cuota lo
rechazaría.
</details>

### 🟡 Ejercicio 14 — La cuota de la segunda cadena
Baja la cuota de `apps-b` a 512 MiB de `requests`, desinstala `tenant-b` y vuelve a instalarlo. **Predice**
qué hace Helm.

**Criterio:** la predicción, el tiempo que tarda `task deploy TENANT=tenant-b`, y el evento de la cuota.

<details><summary>Solución</summary>

La cuota se cambia en `platform/tenants/apps-b.yaml`: un `kubectl patch` no dura, porque `task deploy`
vuelve a aplicar ese archivo antes de Helm. Con 512 MiB, los servicios que piden poco entran y
`inventory` (384) no: `exceeded quota: apps-b, requested: requests.memory=384Mi, used:
requests.memory=192Mi`. Helm espera su `--timeout` entero —10 min 15 s en la verificación— y, como era
una instalación, `--rollback-on-failure` la desinstala: `release tenant-b failed, and has been uninstalled`.
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — El incidente 12
Provócalo y diagnostícalo sin el cuaderno. **Predice** dónde está la causa.

**Criterio:** la causa, y el comando que la confirmó.

**Rúbrica:** el `Last State`; el 137; `dmesg` en el nodo; la cuenta del heap inicial contra el límite.

### 🟠 Ejercicio 16 — El incidente 13
Provócalo y encuentra la causa en menos de dos minutos.

**Criterio:** la línea del log de la readiness.

**Rúbrica:** `0/1` sin reinicios; los eventos `Unhealthy`; el log; y por qué el pod viejo seguía bien.

### 🟠 Ejercicio 17 — El incidente 14
Provócalo con la carga, y demuestra cuál contenedor es el lento y cuál el que se reinicia.

**Criterio:** los reinicios por contenedor y la mediana de k6.

**Rúbrica:** nginx reiniciado, FPM no; `pm.max_children`; la cola donde espera la sonda.

### 🟠 Ejercicio 18 — El incidente 15
Provócalo y repáralo sin `task inc:fix`.

**Criterio:** `postgres-0` en `Running` y los cuatro backends en `1/1`.

**Rúbrica:** el `FailedScheduling`; `Allocated resources` del nodo; la plantilla buena; y lo que hace falta
además de aplicarla.

### 🟠 Ejercicio 19 — El pánico de Envoy
Con un solo backend sin endpoints listos, demuestra que la puerta le manda tráfico y el `Service` no.

**Criterio:** el `Connection refused` por el `Service`, la respuesta por la puerta, y `lb_healthy_panic`.

**Rúbrica:** el `port-forward` a la consola de Envoy (19000); `health_flags`; y qué cambiaría con dos
réplicas, una lista y otra no.

### 🟠 Ejercicio 20 — El `Node` que se cae solo
Reproduce el pool de `pg` que tumba a `replenish`, con la imagen de G3.

**Criterio:** el `Unhandled 'error' event` en `logs --previous` y el reinicio.

**Rúbrica:** por qué no fue una sonda; el evento `error` del pool; y por qué Go y Java no se caen igual.

## 🔴 Muy difícil — el sistema con límites (21–24)

### 🔴 Ejercicio 21 — Lo que no es heap
Mide, en `inventory`, cuánto ocupa cada parte de lo que no es heap.

**Criterio:** un desglose que sume la memoria del contenedor con un margen de 10 %.

**Rúbrica:** `-XX:NativeMemoryTracking=summary`; cómo llegar a `jcmd` (la imagen JRE no lo trae, y desde
un contenedor efímero el *attach* no contestó en la verificación de esta fase; con el pod sin root de la
[Fase 20](20-seguridad-del-pod-y-de-la-red.md), sí: la [Fase 21](21-diagnostico.md) lo muestra); metaspace, hilos,
código; y qué cambia con menos hilos de Tomcat.

### 🔴 Ejercicio 22 — Las tres sondas de Contingencia
Escribe las tres sondas de Contingencia y prueba que ninguna lo reinicia durante un despliegue de
GlassFish de 40 segundos.

**Criterio:** un rollout de Contingencia sin reinicios y sin tráfico antes de que el SOAP conteste.

**Rúbrica:** la `startupProbe` con el tiempo medido en [a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil) (43 s hasta desplegar); la readiness al
WSDL; y la liveness al puerto, no al SOAP.

### 🔴 Ejercicio 23 — El `-Xmx` que sí sirve
Elige las opciones de la JVM de `inventory` para un límite de 768 MiB y defiende el número.

**Criterio:** la carga de la sección 9 durante cinco minutos, sin reinicios y con el pico bajo el 80 %.

**Rúbrica:** `MaxRAMPercentage` y no `-Xmx`; qué recolector elige la JVM con 768 MiB; lo que no es heap
medido; y el margen.

### 🔴 Ejercicio 24 — Tres cadenas en 4 GiB
Calcula cuántas cadenas caben en el nodo con los `requests` de hoy, y demuéstralo.

**Criterio:** el número, y el `Pending` o el `exceeded quota` de la que no cabe.

**Rúbrica:** lo asignable del nodo; lo que ya piden `kube-system`, la puerta, Postgres y el patrimonio;
cuotas por cadena; y la diferencia entre lo que cabe en promesas y lo que cabe en uso.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *Probes*: https://kubernetes.io/docs/concepts/workloads/pods/probes/
- Kubernetes, *Resource Management for Pods and Containers*: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Kubernetes, *Pod Quality of Service Classes*: https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/
- Kubernetes, *Resource Quotas*: https://kubernetes.io/docs/concepts/policy/resource-quotas/ · *Limit Ranges*: https://kubernetes.io/docs/concepts/policy/limit-range/
- Envoy, *Panic threshold*: https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/panic_threshold
  (es la documentación de la versión en desarrollo de Envoy; el comportamiento es el mismo).
- JDK, JEP 514 y JEP 515, el AOT cache de Java 25: https://openjdk.org/jeps/514 · https://openjdk.org/jeps/515
- Spring Boot, *Application Availability*: https://docs.spring.io/spring-boot/reference/features/spring-application.html (la sección *Application Availability*)

**Libros**

- Marko Lukša y Kevin Conner, *Kubernetes in Action*, 2.ª edición (2026): los capítulos de sondas y de
  recursos.
- Betsy Beyer y otros (eds.), *Site Reliability Engineering* (2016), *Handling Overload*:
  https://sre.google/sre-book/handling-overload/

**Orden de lectura sugerido:** antes, *Probes*; durante, *Resource
Management* con la sección 5.4 delante; después, *Handling Overload*, con la sección 5.3.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 15 (minimo)

  apps     los cuatro backends en :g4 (readiness real) · storefront :g2
           cada contenedor con sondas y con requests/limits de memoria medidos; sin límite de CPU
           ResourceQuota apps (1280Mi de requests) · LimitRange (64Mi por defecto)
  apps-b   la misma cuota más chica (1Gi) · la segunda cadena, apagada al cerrar
  data     postgres-0 Burstable (128Mi / 512Mi)
  legacy   Contingencia Burstable (640Mi / 896Mi), con el patrimonio apagado al cerrar
  🔥       lab/inventory:g4-aot (Dockerfile.aot), fuera del chart
```

> **La señal de que quedó bien:** *"Despliego con tráfico sin perder peticiones por el pod nuevo, sé qué
> sonda mata y cuál solo aparta, y cuando un contenedor muere con 137 miro el límite antes que el
> código."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite de G4 pasando y `git status`
> limpio:
>
> ```bash
> git tag -a fase-15-salud-y-recursos -m "F15 cerrada: G4 con readiness real en los cuatro backends; sondas, requests y limits medidos en el chart; QoS de Postgres y del patrimonio; ResourceQuota y LimitRange en apps y apps-b; incidentes 12-15; AOT cache como Dockerfile.aot"
> ```
>
> Y los pares de los incidentes: `inc/12/jvm-pretouch-oomkilled-*`, `inc/13/stale-db-password-*`,
> `inc/14/liveness-too-strict-*` e `inc/15/requests-too-big-*`. Commits con prefijo `f15:`.

---

## 📌 Pendientes sugeridos

- **F16:** el pod viejo que se lleva peticiones al morir (sección 5.1); `pricing` que sale con error ante
  `SIGTERM`; el HPA como dueño de `replicas` frente a Helm.
- **F21:** el *attach* de `jcmd` desde un contenedor efímero, que no contestó (ejercicio 21).
- **`a08`:** el AOT cache contra la compilación nativa, con el mismo `Dockerfile.aot` como punto de partida.
- **`a16`:** Contingencia con sus `requests` y `limits`, y su `-Xmx512m` de fábrica.
