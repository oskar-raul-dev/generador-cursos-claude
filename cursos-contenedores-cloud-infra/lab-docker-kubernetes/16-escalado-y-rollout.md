# 📈 Fase 16 — Escalado y rollout: la venta completa, la quincena, y por qué un portátil no es la nube

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 16 de 27 · Parte II — El despliegue · **densa**
> **Perfil:** `lab` (control-plane y dos workers), por primera vez en uso; `medicion` sobre `lab` para 📏 · **Observabilidad encendida:** solo metrics-server
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: el escalado y el rollout son del cluster
> **Servicios que toca:** los cuatro backends y `storefront` · **Paso de generación:** G5 · El flujo de venta 🌊
> **Depende de:** [Fase 15](15-salud-y-recursos.md) · **Habilita:** [Fase 17](17-metricas-y-dashboards.md)
> **Incidentes que reserva:** 16, 17 · **Medición:** B-16
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** que la venta cruce los cuatro servicios sin carreras; que un despliegue con carga no pierda ni una petición; que el sistema crezca solo cuando la carga sube, sabiendo cuánto tarda; y medir cuántas réplicas pide cada runtime para la misma tasa.

---

## 🧭 1. Dónde estamos

Hasta aquí, cada servicio atendía lo suyo y ninguno le hablaba a otro: catorce fases de plataforma con
un dominio que devolvía datos poco interesantes, como se avisó en la [Fase 02](02-compose-el-sistema-en-un-archivo.md). La [Fase 15](15-salud-y-recursos.md) dejó a cada
contenedor diciendo cuándo está listo y cuánta memoria necesita. Ahora el sistema hace lo que existe
para hacer: **vender**.

Es quincena en Bogotá, y Valentina le muestra a Germán el perfil `lab`: tres nodos, dos réplicas de cada
servicio, y un generador de carga empujando peticiones por la puerta. Germán hace la pregunta que hace
siempre:

> *"¿Y cuántas ventas aguanta esto? Porque un pico como el del 14 de octubre es el triple de un martes,
> mano. Once mil domicilios por tres."*

Valentina le contesta con la regla de los números de la casa (historia §7), que el curso repite a
propósito:

> *"Esto corre en un portátil, Germán. Si le digo que aguanta treinta y tres mil, le miento. Lo que le
> puedo decir es cuántas veces más le cuesta un servicio en Java que uno en Go para la misma carga, cuánto
> tarda el cluster en reaccionar, y qué se pierde mientras tanto. Eso sí vale en cualquier nube."*

Esta fase mide esas tres cosas.

---

## 🎯 2. Objetivos de esta fase

1. Generar G5: la venta completa (`catalog` valida, `pricing` pone el precio, `inventory` descuenta y
   avisa a `replenish` sin esperar), desde la API y desde la página, sin la carrera de la [Fase 12](12-estado-y-almacenamiento.md).
2. Hacer un rollout con carga sin perder ni una petición, y saber qué pieza lo logra.
3. Instalar metrics-server, encender el autoescalado y medir cuánto tarda en reaccionar.
4. Medir con B-16 cuántas réplicas pide cada runtime para la misma tasa, y cuánta memoria cuesta cada una.
5. Nombrar lo que el laboratorio no puede reproducir: interrupciones voluntarias, nodos que se agregan
   solos, zonas.

---

## 🚫 3. Qué NO entra todavía

- Timeouts, reintentos y circuit breaker en las llamadas de la venta → [Fase 22](22-resiliencia-y-caos.md) (G9). Hoy, a propósito, no
  hay ninguno.
- *¿Y si el aviso a `replenish` se pierde?* → [Fase 25](25-la-coreografia.md). Hoy queda en el log.
- Ver la venta cruzar los servicios en una traza → [Fase 23](23-grpc-y-el-balanceo.md).
- Métricas propias de los servicios y tableros → [Fase 17](17-metricas-y-dashboards.md). metrics-server solo sabe de CPU y memoria.
- `PodDisruptionBudget`, autoescalado de nodos y multi-zona: 🚧 se nombran en el veredicto y no se montan.

---

## 🧨 4. El problema, en el laboratorio

Dos cosas que el sistema de la [Fase 15](15-salud-y-recursos.md) todavía no resuelve, medidas en el perfil `lab`.

**La primera: cada despliegue con carga pierde peticiones.** `pricing`, con dos réplicas y 200 peticiones
por segundo por la puerta, y un `rollout restart` a los ocho segundos, tres veces:

```text
sin apagado limpio (pricing:g4), sin preStop · corrida 1: http_req_failed: 0.37%  30 out of 8001
sin apagado limpio (pricing:g4), sin preStop · corrida 2: http_req_failed: 0.22%  18 out of 8001
sin apagado limpio (pricing:g4), sin preStop · corrida 3: http_req_failed: 0.48%  39 out of 8001
```

La readiness de la [Fase 15](15-salud-y-recursos.md) protege al pod que entra; nadie protege al que sale.

**La segunda: con más carga de la que un pod aguanta, el pod muere.** `pricing` con una réplica y 1.500
peticiones por segundo, con el límite de 64 MiB que la [Fase 15](15-salud-y-recursos.md) midió con veinte usuarios:

```text
   11 s · cpu 2% · deseadas 1 · listas 1
   16 s · cpu 2% · deseadas 1 · listas 0
   21 s · cpu ?% · deseadas 1 · listas 0
…
$ kubectl -n apps describe pod pricing-6db85d47cc-265nj | sed -n '/Last State/,/Exit Code/p'
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
```

En compose, la respuesta a las dos era la misma: aguantar. Un `up -d` cortaba lo que estuviera en vuelo,
y más réplicas eran un `--scale` a mano.

> 🩻 **Esto sí funciona igual.** `deploy.replicas` en compose y `replicas` en un `Deployment` son la
> misma idea: cuántas copias. Lo que compose no tiene es alguien que las cambie solo, y alguien que las
> reemplace de a una sin bajar el servicio.

---

## 🧩 5. Escalar y desplegar, con `pricing`

### 5.1 La venta, por fin

G5 es la segunda oleada de dominio ([a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g5-)). `POST /sales` en `inventory`
hace, en orden, lo que el contrato describe: le pregunta a `catalog` si el producto existe y está activo,
le pide a `pricing` el precio vigente en la droguería (con el tope regulado aplicado), descuenta la
existencia con un movimiento `SALE` y, si queda por debajo del umbral, le pide a `replenish` una orden de
reposición **sin esperar su respuesta**:

```java
// 4. Bajo el umbral: el aviso a replenish, SIN esperar su respuesta. La venta ya está hecha y no
// puede fallar porque replenish no conteste; el resultado va al log. ¿Y si el aviso se pierde?
// Esa pregunta es de la Fase 25.
if (done.sale().replenishmentRequested()) {
    Thread.ofVirtual().start(() -> { … replenish.post().uri("/replenishment-orders") … });
}
```

Es el préstamo entre vecinas de la historia: si la droguería se queda sin el producto, se pide a otra, y
el cliente que está en el mostrador no espera esa llamada. **Es la primera vez en el curso que un servicio
llama a otro por trabajo de negocio**, y lo hace sin timeouts ni reintentos: esa deuda 💸 la cobra la Fase
22. La suite del paso la recorre entera:

```text
$ task conformance TARGET=cluster PROFILE=lab -- G5
Success /suite/inventory.g5.hurl (9 request(s) in 379 ms)
$ kubectl -n apps logs -l app.kubernetes.io/name=inventory | grep "aviso a replenish" | tail -1
… c.c.lab.inventory.SalesController        : aviso a replenish: RO-0004 para SKU-0002 en DRO-021 (quedan 4)
```

**Y la carrera de la [Fase 12](12-estado-y-almacenamiento.md) se cerró en el mismo paso.** El descuento lee la existencia con la fila
bloqueada (`SELECT … FOR UPDATE` con Postgres), así que dos ventas a la vez no venden la misma unidad. La
prueba de la [Fase 12](12-estado-y-almacenamiento.md#-7-tu-instinto-de-compose-dice-y-la-apuesta), veinte reposiciones a la vez con dos réplicas, cinco veces:

```text
respuestas: {201: 20}; después: 20 (se esperaban 20)
respuestas: {201: 20}; después: 20 (se esperaban 20)
respuestas: {201: 20}; después: 20 (se esperaban 20)
respuestas: {201: 20}; después: 20 (se esperaban 20)
respuestas: {201: 20}; después: 20 (se esperaban 20)
```

La página también vende: el `storefront` de G5 muestra el precio de la droguería y un botón por producto.
Con un Chrome sin interfaz, haciendo clic en el del salbutamol:

```text
después del clic: Venta SALE-000005: $12.900.
```

El navegador habla con dos servicios más (`pricing` y `inventory`), y la puerta tiene que autorizarlo:
`GET` en la ruta de `pricing`, y `POST` con `Content-Type` en la de `inventory`, que el navegador pregunta
antes con un `OPTIONS`. Son dos valores del chart (`route.cors`).

### 5.2 El pod que sale: `SIGTERM` y `preStop`

Cuando un pod se va —un rollout, un nodo que se vacía, un autoescalado hacia abajo— pasan dos cosas **al
mismo tiempo**: el kubelet le manda `SIGTERM` al proceso, y el pod sale de los endpoints del `Service`.
Lo segundo tarda: kube-proxy en cada nodo y el proxy del `Gateway` se enteran un momento después. En ese
momento, la puerta todavía le manda peticiones a un proceso que se está yendo.

Dos piezas, y las dos están en G5 y en el chart:

- **El apagado limpio**, en el proceso: ante `SIGTERM`, dejar de aceptar conexiones y terminar las que
  tiene. En `pricing`, `signal.NotifyContext` y `srv.Shutdown`; en `inventory`, `server.shutdown=graceful`;
  en `replenish`, `enableShutdownHooks`. Es lo que la [Fase 03](03-el-contenedor-por-dentro.md) sembró: `pricing` moría por la señal sin cerrar nada.
- **El `preStop`**, en el pod: una pausa **antes** del `SIGTERM`, para que la puerta deje de mandarle
  tráfico mientras el proceso todavía atiende. Es una acción del kubelet, sin shell, que sirve también en
  la imagen distroless de `pricing`:

```yaml
lifecycle:
  preStop:
    # Una pausa del kubelet, sin shell: sirve también en distroless.
    sleep: {seconds: 5}
```

El mismo rollout de la sección 4, separando las dos piezas, tres veces cada caso:

| `pricing` | `preStop` | peticiones fallidas (de 8.000) |
|---|---|---|
| sin apagado limpio (`:g4`) | no | 30 · 18 · 39 |
| con apagado limpio (`:g5`) | no | 25 · 29 · 24 |
| sin apagado limpio (`:g4`) | 5 s | 0 · 0 · 0 |
| con apagado limpio (`:g5`) | 5 s | 0 · 0 · 0 |

**El apagado limpio, solo, no cambió nada**: las peticiones se pierden antes de que el proceso reciba la
señal, mientras la puerta todavía no sabe que el pod se va. **El `preStop` lo arregló, aun sin apagado
limpio**, porque las peticiones de `pricing` duran milisegundos: a los cinco segundos no queda ninguna en
vuelo. El apagado limpio importa cuando una petición dura más que el `preStop`: una venta que espera a
`catalog` y a `pricing`, una exportación, una conexión larga. Los dos van juntos, y caben en los 30 s de
`terminationGracePeriodSeconds`.

### 5.3 El rollout, de a una

Un `Deployment` reemplaza réplicas según su estrategia, y el chart la fija:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    # Una réplica de más mientras sube la nueva, y ninguna de menos: nunca baja la capacidad.
    maxSurge: 1
    maxUnavailable: 0
# Si el rollout no avanza en este tiempo, el Deployment lo marca ProgressDeadlineExceeded (incidente 16).
progressDeadlineSeconds: 120
```

`maxSurge: 1` y `maxUnavailable: 0` quieren decir: primero sube una réplica nueva, espera a que esté
**lista** (la readiness de la [Fase 15](15-salud-y-recursos.md)), y recién entonces baja una vieja. Cuesta un pod de más durante el
rollout —memoria, y cuota: la sección 6—, y a cambio la capacidad nunca baja. Si la versión nueva nunca
está lista, el rollout se detiene con las viejas atendiendo, y al pasar el plazo lo dice:

```text
error: deployment "inventory" exceeded its progress deadline
```

Es el [incidente 16](cuaderno-incidentes.md#-incidente-16--el-despliegue-se-quedó-a-la-mitad): el servicio atiende, y el despliegue se quedó a la mitad.

### 5.4 El autoescalado: metrics-server y el HPA

Un `HorizontalPodAutoscaler` (HPA) cambia las réplicas de un `Deployment` según una métrica. La de serie
es la CPU, que lee de la API de métricas, y esa API la sirve **metrics-server**, que en kind no viene
instalado. `task platform:metrics -- lab` aplica el manifiesto de la release, guardado en
`platform/metrics-server/` con la imagen por digest, y un `patch` aparte:

```yaml
      - >-
        {{.KCTX}} -n kube-system patch deployment metrics-server --type=json
        -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

Sin ese flag, el HPA no ve nada: es el [incidente 17](cuaderno-incidentes.md#-incidente-17--el-autoescalador-no-ve-nada). Con él:

```text
$ kubectl top pods -n apps --containers | head -4
POD                           NAME         CPU(cores)   MEMORY(bytes)
catalog-59786cbb99-7m299      nginx        1m           7Mi
catalog-59786cbb99-7m299      php-fpm      2m           32Mi
inventory-68f45cfd75-258db    inventory    3m           203Mi
$ kubectl -n apps get hpa
NAME      REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
pricing   Deployment/pricing   cpu: 2%/70%   1         4         1          2m48s
```

El HPA es otro valor del chart (`autoscaling.enabled`), y trae una regla que no es opcional: **mientras
el HPA existe, el `Deployment` no declara `replicas`**. El HPA las cambia, y quien las cambia es su dueño;
si el chart también las declarara, cada `task deploy` chocaría con el HPA, como chocó con `kubectl scale`
en la [Fase 14](14-helm-en-operacion.md#️-13-errores-comunes-y-diagnóstico). Y un efecto lateral: al encenderlo, el `Deployment` de `lab` pasó de dos réplicas a una,
porque Helm dejó de declarar el campo.

El 70 % es **de los `requests`**, no de la máquina: `pricing` pide 50m, así que el HPA escala cuando pasa
de 35m. Con 1.500 peticiones por segundo:

```text
   27 s · cpu 2% · deseadas 1 · listas 1
   32 s · cpu 390% · deseadas 4 · listas 1
   37 s · cpu 390% · deseadas 4 · listas 3
   53 s · cpu 2414% · deseadas 4 · listas 4
primera réplica pedida a los 32 s; lista a los 37 s
```

**Treinta y dos segundos sin cambiar nada**, con la CPU muy por encima del objetivo: metrics-server lee
cada 15 s, el HPA calcula cada 15 s, y el primer dato con carga llegó tarde. Después pidió el máximo de
una vez. Es la apuesta de la sección 7.

**Prueba de fuego.** `task conformance TARGET=cluster PROFILE=lab -- G5`, y la de G4, G1 y G2, en verde
en el perfil `lab`; y el rollout con carga, con cero peticiones perdidas.

**El patrón a memorizar.** Un pod que sale necesita un `preStop` que le dé tiempo a la puerta y un
proceso que termine lo que tiene; un rollout sin bajar capacidad es `maxUnavailable: 0`; y un HPA llega a
la carga medio minuto tarde, así que las réplicas que el pico necesita al empezar tienen que estar antes.

---

## 🔁 6. Los otros tres: donde no es mecánico

**`catalog` (PHP-FPM) no crece como los demás.** Con el HPA encendido y 400 peticiones por segundo, pidió
réplicas a los 31 s, como `pricing`, y llegó a cuatro. Y con cuatro, siguió sin alcanzar:

```text
=== catalog (400 peticiones/s)
    http_req_duration..............: med=1.17s p(95)=1.65s max=3.61s
    http_reqs......................: 38831  315.194908/s
=== replenish (400 peticiones/s)
    http_req_duration..............: med=2.82ms p(95)=123.89ms max=1.12s
    http_reqs......................: 47822  398.5114/s
```

La capacidad de un pod de `catalog` es un número de **procesos**, no de CPU: cinco (`pm.max_children`),
cinco peticiones a la vez. La CPU sube porque los cinco trabajan, el HPA agrega pods, y cada pod nuevo
trae cinco procesos más. Con Node, un solo proceso atiende cientos de conexiones mientras espera a la
base. **El mismo HPA, por CPU, mide cosas distintas en cada runtime.** Para PHP, la palanca es
`pm.max_children` contra la memoria del pod, y el HPA llega después.

**`inventory` (Java)** es el que más cuesta por réplica (B-16, sección 8), y el que más tarda en estar
listo cuando el HPA lo agrega. Su llamada a `catalog` y a `pricing` en cada venta es la primera cadena de
dependencias del sistema: hoy sin timeouts, a propósito.

**El patrimonio no cambió.** Contingencia sigue con su `-Xmx512m` y una réplica: nadie escala un
servidor de aplicaciones con estado de sesión por CPU.

**Y la cuota de la [Fase 15](15-salud-y-recursos.md) no alcanzó para el perfil `lab`.** Con dos réplicas de cada backend, el pod de
más del rollout y un `Job` de migraciones ya no cabían:

```text
Error creating: pods "pricing-7c68f4dcfd-5wb9w" is forbidden: exceeded quota: apps, requested: limits.memory=512Mi, used: limits.memory=1696Mi, limited: limits.memory=2Gi
```

Y un hook que no puede crear su pod bloquea el upgrade entero (la [Fase 13](13-helm-el-paquete.md#-8-la-rotura-un-hook-que-no-puede-correr)). La cuota subió a 1.536 MiB de
`requests` y 3 GiB de `limits`: se calcula con el perfil más grande, más un rollout.

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"si sube la carga, el autoescalado agrega réplicas, y si apago con
cortesía, nadie se entera"*. Las dos cosas suenan a lo que promete cualquier nube.

> 🪞 **Apuesta antes de ejecutar.** Desde que empieza una carga que pide más réplicas, el HPA tarda más de
> 60 s en crear la primera réplica nueva.
>
> **Resultado: perdida.** En las tres corridas válidas con `pricing`, el HPA pidió réplicas a los 37, 37 y
> 32 s, y estuvieron listas a los 43, 48 y 37. Con `catalog` y `replenish`, a los 31. Tarda menos de lo
> apostado, y aun así **medio minuto es mucho**: en las dos primeras corridas, con el límite de 64 MiB,
> `pricing` ya había muerto `OOMKilled` a los 16 s, y en una tercera, muerto antes de que llegara una sola
> lectura, el HPA se quedó en `<unknown>` y no escaló nunca (la sección 9).

> 🪞 **Apuesta antes de ejecutar.** Un rollout de `pricing` con carga constante: sin apagado limpio ni
> `preStop`, se pierde al menos una petición; con los dos, ninguna.
>
> **Resultado: ganada**, y con una sorpresa: el apagado limpio solo no ayudó, y el `preStop` solo alcanzó
> (sección 5.2).

> 🪞 **Apuesta antes de ejecutar (B-16).** Para la misma tasa de lecturas por la puerta, con p95 bajo
> 100 ms: `pricing` con una réplica, y los otros tres con más; y una réplica de `inventory` ocupa más de
> diez veces la memoria de una de `pricing`.
>
> **Resultado: perdida en las dos mitades** (sección 8).

Las entradas están en [INSTINTOS.md](INSTINTOS.md#el-autoescalado-me-salva-del-pico).

---

## 📏 8. La medición: B-16

> 📏 **Medición B-16 · Réplicas y memoria por runtime para la misma tasa** · perfil `medicion` sobre
> `lab` (tres nodos, sin `storefront` ni autoescalado) · Docker Desktop (Engine 29.8.0), máquina virtual
> de 4 GiB · kind 0.33.0, nodo 1.36.4 · MacBook Pro M1 Pro, 32 GB, macOS arm64 · 300 peticiones por
> segundo con k6 a tasa constante, 3 corridas de 30 s por punto · verificado el 04/10/2026
>
> | p95 en ms, mediana (mín.–máx.) | 1 réplica | 2 réplicas | 3 réplicas | memoria por réplica (MiB) |
> |---|---|---|---|---|
> | `pricing` (Go) | 4 (4–5) | 4 (3–4) | 3 (3–4) | 9–28 |
> | `inventory` (Java) | 3 (3–3) | 6 (4–26) | 7 (5–74) | 175–217 |
> | `catalog` (PHP-FPM + nginx) | 147 (85–292) | 45 (40–86) | 162 (155–189) | 46–56 |
> | `replenish` (Node) | 4 (4–4) | 4 (4–5) | 4 (4–6) | 40–51 |
>
> Reproducir: `task deploy CLUSTER=lab -- medicion` y `task measure -- B-16 --runs 3 --rate 300`

A 300 peticiones por segundo, **tres de los cuatro cumplen con una réplica**, y la apuesta se perdió en
esa mitad: para una lectura corta, Java y Node atienden muchas peticiones a la vez (hilos, un bucle de
eventos), igual que Go. **`catalog` es la excepción**: cinco procesos de PHP-FPM por pod, cinco peticiones
a la vez, y con una réplica el p95 pasó de 100 ms. Con dos bajó a 45. Con tres **empeoró** (162 ms), y
`inventory` tuvo una corrida mala con tres (74 ms): los tres nodos son contenedores de la misma máquina, y
más réplicas compiten por la misma CPU y el mismo Postgres. No separé esa causa, y no la extrapolo.

**Lo que sí sostiene la tabla es el costo por réplica**: una de `inventory` ocupa 7,4 veces la memoria de
una de `pricing` (208 contra 28 MiB, la primera réplica de cada uno). La apuesta decía más de diez, y se
perdió también. Esa proporción, y no el número de réplicas, es la que se lleva a una nube: cada réplica
de Java que el HPA agrega cuesta siete de Go. La entrada completa está en
[BENCHMARKS.md](BENCHMARKS.md#b-16--cuántas-réplicas-pide-cada-runtime-para-la-misma-tasa-y-cuánto-cuesta-cada-una).

---

## ⚰️ 9. Autopsia: el límite medido sin carga

**La decisión, con su mejor argumento.** En la [Fase 15](15-salud-y-recursos.md), el límite de memoria de `pricing` salió de medir: 6 MiB en
reposo, 13 con veinte usuarios, y un límite de 64, cinco veces el pico. *"Medí, y le di cinco veces lo
que usa."*

**Por qué era razonable.** Es exactamente lo que la [Fase 15](15-salud-y-recursos.md) recomendó, y para veinte usuarios sobraba.

**Qué pasó después, con número.** Con 1.500 peticiones por segundo y una réplica, `pricing` llegó a su
límite en dieciséis segundos y murió `OOMKilled`. El HPA, que estaba ahí para eso, todavía no había leído
la primera muestra con carga. En una de las corridas el pod murió antes de esa primera muestra, y el HPA se
quedó sin dato:

```text
NAME      REFERENCE            TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
pricing   Deployment/pricing   cpu: <unknown>/70%   1         4         1          3m7s
    http_req_failed................: 94.42% 89980 out of 95292
primera réplica pedida a los None s; lista a los None s
```

Un pod en `CrashLoopBackOff` no reporta CPU; sin CPU, el HPA no calcula; sin cálculo, no escala; y sin
réplicas nuevas, el único pod sigue muriendo. **El 94 % de las peticiones perdidas, con un autoescalador
encendido.** Con un límite de 256 MiB, la misma carga dejó a `pricing` en 59–64 MiB: el límite viejo era
exactamente su consumo.

**Cuánto cuesta salir, con número.** El límite a 128 MiB, el doble del pico medido con carga de verdad.
Con él, la corrida 4: el HPA pidió réplicas a los 32 s, cero reinicios, y `pricing` en cuatro réplicas a
los 53.

**Qué lo habría cambiado.** Medir el límite con la carga que el servicio va a recibir en su peor día, no
con la que es cómoda de generar. Y saber que el HPA protege contra la carga que sube despacio; contra la
que llega de golpe, lo que protege es tener las réplicas antes (`minReplicas`) y un límite que aguante
hasta que lleguen las demás.

**Antes y después, con números:** con 64 MiB, `OOMKilled` a los 16 s en las tres corridas y una de ellas
con el HPA ciego y el 94 % de fallos; con 128 MiB, cero reinicios y el HPA escalando a los 32 s.

---

## 📖 10. Traducción

| En compose | En Kubernetes | Lo que cambia |
|---|---|---|
| `--scale pricing=4` | `replicas: 4`, o un `HorizontalPodAutoscaler` | el HPA las cambia solo, medio minuto después |
| `stop_grace_period` | `terminationGracePeriodSeconds` | el plazo es el mismo; el `preStop` va antes y cuenta dentro |
| *sin equivalente* | `lifecycle.preStop` | la pausa para que la puerta se entere de que el pod se va |
| `up -d` con una imagen nueva | un rollout con `maxSurge` y `maxUnavailable` | reemplaza de a una, sin bajar la capacidad, y se detiene si la nueva no está lista |
| `docker stats` | `kubectl top` (con metrics-server) | la misma lectura, por pod y por contenedor |

Las filas completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, el HPA es el mismo, y casi siempre viene acompañado de lo que aquí no hay: 🚧 un
**autoescalador de nodos**, que agrega máquinas cuando los pods nuevos no caben (y tarda minutos, no
segundos); **`PodDisruptionBudget`**, que impide que un mantenimiento del proveedor baje más réplicas de las
que el servicio tolera; y **zonas**, que reparten las réplicas para que una zona caída no se lleve el
servicio. Los tres se configuran con objetos de Kubernetes que el laboratorio puede crear, y que en un
portátil de tres nodos-contenedor no protegen de nada que pueda pasar.

---

## 🩺 11. Incidentes de esta fase

- **[16 — El despliegue se quedó a la mitad](cuaderno-incidentes.md#-incidente-16--el-despliegue-se-quedó-a-la-mitad).**
  `rollout status` termina con `exceeded its progress deadline`, y el `Deployment` queda con `READY 2/2` y
  `UP-TO-DATE 1`.
- **[17 — El autoescalador no ve nada](cuaderno-incidentes.md#-incidente-17--el-autoescalador-no-ve-nada).**
  El HPA en `cpu: <unknown>/70%`, y `kubectl top` dice `error: Metrics API not available`.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**El HPA por CPU llega tarde y mide una sola cosa.** Medio minuto antes de pedir la primera réplica, y
segundos más hasta que está lista: en un pico que llega de golpe —la quincena, el 14 de octubre—, el pico
ya pasó o ya hizo daño. Y mide CPU, que para `catalog` no es la capacidad. Si la carga se puede prever, un
`minReplicas` alto para la quincena hace lo mismo sin los 30 segundos, y es honesto llamarlo escalado
programado.

**El `preStop` es una pausa a ciegas.** Cinco segundos funcionan en este laboratorio porque la puerta se
entera en menos; en un cluster más grande, con más proxies, pueden ser pocos, y cada segundo se suma a
cada rollout.

**Más réplicas no son gratis.** Lo que cuesta cada una por runtime es la tabla de B-16, y en una nube esa
tabla es la factura.

**Cuándo NO un HPA:** un servicio con estado que no se reparte (Postgres, Contingencia), un servicio con un
solo cliente pesado, y cualquier servicio cuya capacidad no sea la CPU sin medir antes qué métrica sí lo es.
**Cuándo sí:** servicios sin estado, con carga que sube a lo largo de minutos, y un límite de memoria que
aguante el pico hasta que lleguen las réplicas.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso que recibe `SIGTERM`. El
orquestador te dio las réplicas, el rollout de a una, el `preStop`, metrics-server y el HPA. **Te tocó a
ti** el apagado limpio de cada runtime, la transacción que cierra la carrera, el límite medido con carga de
verdad, y saber que nada de esto convierte un portátil en la nube.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`task deploy` falla con `conflict with "kubectl" with subresource "scale"`.** Alguien escaló a mano (o
un HPA sin el chart al tanto). Con HPA, `autoscaling.enabled=true`; sin él, las réplicas van en el archivo
de valores.

**`exceeded quota` en un `Job` de migraciones y un upgrade colgado.** La cuota del namespace se quedó corta
para el perfil más el pod de más del rollout (sección 6).

**El HPA en `<unknown>` con metrics-server funcionando.** El pod no tiene `requests` de CPU, o está en
`CrashLoopBackOff` y no reporta (sección 9). `kubectl describe hpa` lo dice en `Conditions`.

**La página no vende: `Failed to fetch` en el navegador.** Falta el CORS de la ruta de `inventory`
(`POST` y `Content-Type`); el `GET` de `catalog` pasaba porque tenía el suyo desde la [Fase 10](10-la-entrada-al-sistema.md).

---

## 📋 14. Checklist de validación

```text
[ ] task conformance TARGET=cluster PROFILE=lab -- G5, dos veces, y G4, G1 y G2 en verde
[ ] veinte reposiciones a la vez dejan 20, cinco veces
[ ] la venta desde la página, con el preflight de CORS
[ ] el rollout con carga: pérdidas sin preStop, cero con él
[ ] task platform:metrics -- lab, kubectl top, y el incidente 17 provocado y reparado
[ ] el HPA de pricing pidiendo réplicas en ~30 s; catalog sin alcanzar con cuatro
[ ] pricing OOMKilled con 64 MiB a 1.500/s, y vivo con 128 MiB
[ ] task measure -- B-16 y la entrada en BENCHMARKS.md
[ ] el incidente 16 provocado y reparado
```

---

## 🧪 15. Ejercicios (24)

La mitad de diagnóstico o medición; varios con `catalog`, `inventory` y la página.

## 🟢 Fácil — la venta y las réplicas (1–7)

### 🟢 Ejercicio 1 — Una venta por la API
Vende dos unidades de `SKU-0003` en `DRO-007` con `curl`, después de contar diez.

**Criterio:** un 201 con `unitPrice`, `total` y `replenishmentRequested`, y la existencia en 8.

<details><summary>Solución</summary>

`POST /inventory/stock/DRO-007/SKU-0003/movements` con `{"type":"COUNT","quantity":10}`, y `POST
/inventory/sales` con `{"store":"DRO-007","sku":"SKU-0003","quantity":2}`, por `api.localhost:8080`.
</details>

### 🟢 Ejercicio 2 — El aviso, en el log
Deja la existencia por debajo del umbral con una venta y encuentra el aviso.

**Criterio:** la línea `aviso a replenish: RO-…` en `inventory` y la orden en `GET /replenish/replenishment-orders`.

<details><summary>Solución</summary>

`PATCH` del umbral a 5 con 6 unidades, una venta de 2, y `kubectl -n apps logs -l
app.kubernetes.io/name=inventory | grep "aviso a replenish"`.
</details>

### 🟢 Ejercicio 3 — Vender desde la página
Abre `http://storefront.localhost:8080/?store=DRO-012` y vende un producto.

**Criterio:** el mensaje `Venta SALE-…` en la página.

<details><summary>Solución</summary>

El producto necesita existencia en `DRO-012`: un `COUNT` antes. Si dice `no hay 1 unidades`, es eso.
</details>

### 🟢 Ejercicio 4 — `kubectl top`
Instala metrics-server y lista la memoria de cada contenedor de `apps`.

**Criterio:** la tabla con los dos contenedores de `catalog` por separado.

<details><summary>Solución</summary>

`task platform:metrics -- lab` y `kubectl top pods -n apps --containers`.
</details>

### 🟢 Ejercicio 5 — Un HPA
Enciende el autoescalado de `replenish` con el chart y muéstralo.

**Criterio:** `kubectl -n apps get hpa replenish` con un porcentaje de CPU, no `<unknown>`.

<details><summary>Solución</summary>

`replenish.autoscaling.enabled: true` en el archivo de valores del perfil y `task deploy -- lab`; esperar
medio minuto a la primera lectura.
</details>

### 🟢 Ejercicio 6 — La estrategia, en el objeto
Muestra la estrategia de rollout y el plazo de `inventory` tal como los ve el cluster.

**Criterio:** `maxSurge: 1`, `maxUnavailable: 0` y `progressDeadlineSeconds: 120`.

<details><summary>Solución</summary>

`kubectl -n apps get deploy inventory -o jsonpath='{.spec.strategy}{"\n"}{.spec.progressDeadlineSeconds}'`.
</details>

### 🟢 Ejercicio 7 — El `preStop`
Borra un pod de `pricing` y mide cuánto tarda en desaparecer.

**Criterio:** unos 5 s más de lo que tardaba sin `preStop`.

<details><summary>Solución</summary>

`time kubectl -n apps delete pod <pod>`: 6,1 s en la verificación. El kubelet espera el `preStop` y después
manda `SIGTERM`; `pricing` sale enseguida.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — El rollout de `inventory`, con carga
Repite la medición de la sección 5.2 con `inventory` y su endpoint de existencias.

**Criterio:** las peticiones fallidas con y sin `preStop`, tres corridas cada una.

<details><summary>Solución</summary>

`shutdown.preStopSeconds=0` por `--set` para el caso sin, `k6` a tasa constante y `kubectl rollout
restart deployment/inventory` a los ocho segundos.
</details>

### 🟡 Ejercicio 9 — `catalog` con más procesos
Sube `pm.max_children` de PHP-FPM a 10 y repite la carga de 400 peticiones por segundo.

**Criterio:** la mediana, y la memoria de `php-fpm` en `kubectl top`.

<details><summary>Solución</summary>

Un archivo de configuración de FPM más en la imagen (`pm.max_children = 10`) y otra imagen de `catalog`. La
latencia baja y la memoria sube: cada proceso de PHP es un proceso.
</details>

### 🟡 Ejercicio 10 — `minReplicas` para la quincena
Configura el HPA de `pricing` con `minReplicas: 3` y repite la carga de 1.500 peticiones por segundo.

**Criterio:** cero `OOMKilled` y menos fallos que con `minReplicas: 1`.

<details><summary>Solución</summary>

`pricing.autoscaling.minReplicas: 3` en los valores. Las réplicas ya están cuando llega el pico: el HPA
deja de ser la primera línea.
</details>

### 🟡 Ejercicio 11 — La venta sin `catalog`
Escala `catalog` a cero y vende. **Predice** la respuesta.

**Criterio:** la predicción, y el 503 con su mensaje.

<details><summary>Solución</summary>

`{"message":"catalog no contesta","error":"unavailable"}`, 503, y una línea `catalog no contesta: I/O
error on GET request …` en el log de `inventory`. Con `catalog` en cero réplicas, el `Service` rechaza la
conexión al instante; un `catalog` que acepta y no contesta sería otra historia, sin timeouts ([Fase 22](22-resiliencia-y-caos.md)).
</details>

### 🟡 Ejercicio 12 — La venta sin `replenish`
Escala `replenish` a cero y haz una venta que deje la existencia bajo el umbral. **Predice** qué pasa.

**Criterio:** la predicción, la venta en 201 con `replenishmentRequested: true`, y el log.

<details><summary>Solución</summary>

La venta se registra (no espera a `replenish`). Lo que pasa con el aviso depende de cuánto tarde
`replenish` en volver: sin timeouts, el hilo del aviso se queda esperando la conexión. En la verificación,
con `replenish` de vuelta un minuto después, la línea `aviso a replenish: RO-0005 …` apareció **2 min 13 s
después de la venta**. Si no hubiera vuelto, el aviso habría terminado en `aviso a replenish perdido` cuando
el sistema operativo se rindiera con la conexión. Ni una cosa ni la otra la ve quien vendió: es la [Fase 22](22-resiliencia-y-caos.md)
(timeouts) y la 25 (el aviso que se pierde).
</details>

### 🟡 Ejercicio 13 — El HPA hacia abajo
Después de una carga, mide cuánto tarda el HPA en volver a una réplica.

**Criterio:** el tiempo desde que termina la carga hasta `REPLICAS 1`.

<details><summary>Solución</summary>

`kubectl -n apps get hpa pricing -w`. Unos cinco minutos: hacia abajo, el HPA espera una ventana de
estabilización (300 s por defecto) para no subir y bajar en cada ola.
</details>

### 🟡 Ejercicio 14 — La cuota y el perfil
Calcula los `requests` y `limits` de `apps` en el perfil `lab` con un rollout en curso, y compáralos con la
cuota.

**Criterio:** la cuenta, y `kubectl -n apps describe resourcequota apps` en medio de un rollout.

<details><summary>Solución</summary>

Dos réplicas de cada backend, el `storefront`, más el pod de más del servicio que se despliega. Con la
cuota de la [Fase 15](15-salud-y-recursos.md) (2 GiB de `limits`), no cabía (sección 6).
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — El incidente 16
Provócalo y diagnostícalo sin el cuaderno. **Predice** qué ven los clientes mientras tanto.

**Criterio:** la causa, y el comando que la confirmó.

**Rúbrica:** el `ProgressDeadlineExceeded`; las réplicas viejas atendiendo; y por qué la nueva nunca
estuvo lista.

### 🟠 Ejercicio 16 — El incidente 17
Provócalo y repáralo sin `task platform:metrics`.

**Criterio:** `kubectl top` contestando.

**Rúbrica:** el pod de metrics-server sin estar listo; su log; el flag; y por qué el flag no va en una nube.

### 🟠 Ejercicio 17 — El HPA ciego
Reproduce la sección 9: un límite de memoria tan justo que el pod muere antes de la primera lectura.

**Criterio:** el HPA en `<unknown>` con metrics-server funcionando.

**Rúbrica:** `CrashLoopBackOff`; `Conditions` del HPA; por qué un pod que no corre no reporta CPU.

### 🟠 Ejercicio 18 — Dos ventas, una unidad
Con una sola unidad en existencia, lanza veinte ventas a la vez. **Predice** cuántas pasan.

**Criterio:** una sola 201 y diecinueve 409, cinco veces seguidas.

**Rúbrica:** el `FOR UPDATE`; qué pasaría con la imagen de G4 (`kubectl set image`); y por qué una réplica
de `inventory` no bastaba para evitarlo.

### 🟠 Ejercicio 19 — El apagado de `catalog`
Mide un rollout de `catalog` con carga, con y sin `preStop`.

**Criterio:** las peticiones fallidas en los dos casos.

**Rúbrica:** `STOPSIGNAL SIGQUIT` en las dos imágenes; el `preStop` en los dos contenedores; y por qué FPM
no puede irse antes que nginx.

### 🟠 Ejercicio 20 — El reparto entre nodos
Escala `inventory` a cuatro réplicas y muestra en qué nodos quedaron. **Predice** el reparto.

**Criterio:** la predicción y la columna `NODE`.

**Rúbrica:** el control-plane con su marca; el reparto por defecto del planificador; y qué haría falta para
garantizarlo (`topologySpreadConstraints`).

## 🔴 Muy difícil — el sistema bajo carga (21–24)

### 🔴 Ejercicio 21 — Escalar `catalog` por otra métrica
Haz que `catalog` escale por algo que mida su capacidad de verdad.

**Criterio:** con 400 peticiones por segundo, el p95 por debajo de 500 ms.

**Rúbrica:** por qué la CPU no es su capacidad; métricas propias (los procesos de FPM ocupados) y lo que
hace falta para que el HPA las lea ([Fase 17](17-metricas-y-dashboards.md) y un adaptador); o `pm.max_children` y réplicas fijas.

### 🔴 Ejercicio 22 — Un `PodDisruptionBudget`
Escribe un PDB para `inventory` y vacía un worker con `kubectl drain`. **Predice** qué hace el drain.

**Criterio:** el drain esperando al PDB, y `inventory` sin quedarse en cero réplicas.

**Rúbrica:** `minAvailable: 1`; el drain que espera; y lo que el PDB no protege (un nodo que se apaga
sin drain).

### 🔴 Ejercicio 23 — La quincena, en proporción
Con B-16 delante, calcula cuántas réplicas de cada servicio harían falta para el doble de la tasa medida,
y cuánta memoria del perfil `lab` ocuparían.

**Criterio:** la tabla, y si entra en 4 GiB.

**Rúbrica:** la proporción, no el número absoluto; la memoria por réplica de B-16; los `requests` contra
lo asignable; y la regla de la historia: ningún número del laboratorio es un número de La Vecina.

### 🔴 Ejercicio 24 — Un rollout que dura una venta
Haz que una venta tarde 8 s (un `sleep` en `inventory`, por variable) y despliega con carga. **Predice**
qué pieza falla primero.

**Criterio:** las peticiones fallidas con `preStop` de 5 s, y con el apagado limpio de 20 s.

**Rúbrica:** el `preStop` no alcanza para una petición de 8 s; el apagado limpio sí; y el plazo total
contra `terminationGracePeriodSeconds`.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *Deployments* (estrategias y `progressDeadlineSeconds`): https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes, *Horizontal Pod Autoscaling*: https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/
- Kubernetes, *Pod Lifecycle* (la terminación del pod): https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
- Kubernetes, *Container Lifecycle Hooks* (`preStop`, y la acción `sleep`): https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/
- metrics-server, el proyecto: https://github.com/kubernetes-sigs/metrics-server
- Kubernetes, *Specifying a Disruption Budget*: https://kubernetes.io/docs/tasks/run-application/configure-pdb/ (🚧 de lectura)
- k6, *Constant arrival rate*: https://grafana.com/docs/k6/latest/using-k6/scenarios/executors/constant-arrival-rate/

**Libros**

- Brendan Burns y otros, *Kubernetes: Up and Running*, 3.ª edición (2022): el capítulo de `Deployments`.
- Betsy Beyer y otros (eds.), *Site Reliability Engineering* (2016), *Load Balancing in the Datacenter*:
  https://sre.google/sre-book/load-balancing-datacenter/

**Orden de lectura sugerido:** antes, *Pod Lifecycle* (la terminación); durante, *Horizontal Pod
Autoscaling* con la sección 5.4 delante; después, el capítulo de SRE.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 16 (perfil lab: control-plane y dos workers)

  apps     pricing · inventory · replenish en :g5, catalog en :g4, storefront en :g5
           la venta: inventory → catalog, pricing (en la petición) → replenish (sin esperar)
           preStop de 5 s, apagado limpio, maxSurge 1 / maxUnavailable 0, progressDeadlineSeconds 120
           autoscaling.enabled por servicio (apagado por defecto); pricing con límite de 128 MiB
           ResourceQuota apps: 1.536 MiB de requests, 3 GiB de limits
  kube-system   metrics-server (platform/metrics-server/, con --kubelet-insecure-tls)
  bench/b16     rate.js y los crudos de B-16
```

> **La señal de que quedó bien:** *"Despliego con carga sin perder una petición, sé cuánto tarda el
> autoescalado y qué no mide, y cuando Germán me pregunta cuántas ventas aguanta, le contesto con una
> proporción y no con un número."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite de G5 pasando y `git status`
> limpio:
>
> ```bash
> git tag -a fase-16-escalado-y-rollout -m "F16 cerrada: G5, la venta completa con aviso a replenish sin esperar, apagado limpio y la carrera de inventory cerrada; preStop, estrategia de rollout y plazo de progreso; metrics-server y HPA en el chart; B-16; incidentes 16 y 17"
> ```
>
> Y los pares: `inc/16/rollout-progress-deadline-*` e `inc/17/metrics-server-kubelet-tls-*`. Commits con
> prefijo `f16:`.

---

## 📌 Pendientes sugeridos

- **F22:** los timeouts y reintentos de la venta (hoy, ninguno).
- **F25:** el aviso a `replenish` que se pierde (hoy, una línea de log).
- **F17:** el p95 de la venta y la tasa por servicio, en un tablero, en lugar de leerlos de k6.
- **B-04:** el build en frío de `pricing` con las dependencias de las pruebas sigue sin separar.
