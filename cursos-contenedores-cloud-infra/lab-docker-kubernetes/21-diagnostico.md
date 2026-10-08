# 🩻 Fase 21 — Diagnóstico: el kit, el método y los primeros treinta segundos

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 21 de 27 · Parte III — Operarlo · **densa**
> **Perfil:** el cluster `lab`, con los valores de `minimo` · **Observabilidad encendida:** ninguna (la fase la nombra; los casos no la necesitan)
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: las herramientas hablan con el cluster, no con el motor
> **Servicios que toca:** los cinco, para romperlos · **Paso de generación:** ninguno
> **Depende de:** [Fase 20](20-seguridad-del-pod-y-de-la-red.md) · **Habilita:** Fase 22
> **Incidentes que reserva:** ninguno; **abre formalmente el cuaderno**, con sus 27 · **Medición:** ninguna
> **Apéndices de apoyo:** [a04](a04-kubectl-y-k9s.md), y el [cuaderno de incidentes](cuaderno-incidentes.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** pasar de saber desplegar a saber diagnosticar: un método de siete pasos que se aplica igual a cualquier síntoma, el orden de los primeros treinta segundos, y cada herramienta del kit estrenada en el caso que la necesita.

---

## 🧭 1. Dónde estamos

Veinte fases construyeron, midieron y rompieron. El cuaderno de incidentes tiene, a esta altura, sus 27
entradas: cada fase sumó las suyas, y cada una ya aplicaba un método sin nombrarlo. Esta fase le pone nombre.

La pregunta que la abre es la de Germán desde el primer día: *los primeros cuarenta minutos del 14 de octubre,
nadie supo por qué* (historia §1.14). La Parte III ya dio las herramientas para saberlo —métricas, logs,
certificados, la red—. Lo que faltaba es **qué hacer primero**. Fabio Arenas, de operaciones, lo pone en sus
palabras cuando Valentina le muestra el kit:

> *"Yolanda, cuando se le congela la caja, no llama a nadie: saca el cuaderno verde y anota. Hora, qué estaba
> vendiendo, qué dijo la pantalla. Después vende a mano. Sus técnicos, cuando algo se cae, ¿qué hacen primero?"*

La respuesta honesta, para la mayoría de los equipos, es *"reiniciar el pod"*. Y funciona más veces de las que
debería, que es por qué el hábito dura: el pod nuevo arranca, el síntoma desaparece, y la causa sigue ahí,
esperando el próximo martes de lluvia. Lo que Yolanda hace con el cuaderno verde es lo contrario: primero anota,
después actúa, y al otro día alguien puede saber qué pasó. Esta fase es esa otra respuesta, con las herramientas
del cluster.

---

## 🎯 2. Objetivos de esta fase

1. El método de siete pasos, con nombre: síntoma, evidencia, hipótesis, primer comando, causa, corrección,
   prevención.
2. Un orden fijo para los primeros treinta segundos, que sirve para cualquier síntoma.
3. Cada herramienta del kit —`describe`, `events`, `logs --previous`, `exec`, `port-forward`, contenedores
   efímeros, k9s— estrenada en un caso que la necesita.
4. El cuaderno de incidentes revisado con el método, y una guardia a ciegas sobre él.

---

## 🚫 3. Qué NO entra todavía

- Depurar el nodo (`kubectl debug node/…`) y el runtime: el laboratorio rompe pods, no nodos.
- Perfiladores, eBPF y trazas de sistema: herramientas de rendimiento, no de diagnóstico inicial.
- Trazas distribuidas → [Fase 23](23-grpc-y-el-balanceo.md). Esta fase diagnostica con lo que hay: estado, eventos, logs, red.
- Incidentes nuevos: el cuaderno está completo, y esta fase lo usa.

---

## 🧨 4. El problema, en el laboratorio

Un mismo síntoma con tres causas. La venta, por la puerta, da error en tres situaciones que esta Parte III ya
provocó:

```text
caso 1:  {"error":"unavailable","message":"pricing no contesta"}               503 al instante
caso 2:  upstream request timeout                                              504 a los 16 s
caso 3:  upstream request timeout                                              504 a los 15 s
```

El primero es `inventory` sin su certificado de cliente (incidente 23). El segundo, la red cerrada sin el DNS
(incidente 26). El tercero, `catalog` en cero réplicas: en la [Fase 16](16-escalado-y-rollout.md) (ejercicio 11) eso daba un 503 al instante,
`catalog no contesta`; con las `NetworkPolicy` de la [Fase 20](20-seguridad-del-pod-y-de-la-red.md), la conexión a un `Service` sin pods ya no se
rechaza: se queda esperando, y la puerta corta a los 15 segundos. Y hay más: **esa venta se registró**. Cuando
`catalog` volvió, dos minutos y medio después, `inventory` terminó la venta que el cliente ya daba por fallida:

```text
{"msg":"request",…,"method":"POST","uri":"/sales","status":201,"duration_ms":145843.719609,"service":"inventory"}
``` Los tres "no contestan". Quien reinicia `inventory` por reflejo
no arregla ninguno, y en los tres casos **borra la evidencia**: el pod nuevo no tiene el log del viejo.

Y la lista de comandos no ayuda: `kubectl` tiene más de cuarenta subcomandos, y saber qué hace cada uno no dice
**cuál correr primero**. Eso es el método.

> 🩻 **Esto sí funciona igual.** `docker logs`, `docker inspect`, `docker exec` y `docker events` son
> exactamente las mismas preguntas que esta fase le hace al cluster. Lo que cambia es que en el cluster hay más
> capas entre el síntoma y la causa: la puerta, el `Service`, el pod, el contenedor, el nodo.

---

## 🧩 5. El método, y el kit

### 5.1 Siete pasos, siempre los mismos

Los mismos del [cuaderno](cuaderno-incidentes.md#el-método-siete-pasos-siempre-los-mismos), con las mismas palabras:

1. **Síntoma** — lo que se ve, literal. Cópialo antes de tocar nada.
2. **Evidencia** — qué mirar en los primeros treinta segundos, y en qué orden.
3. **Hipótesis** — dos o tres, ordenadas por probabilidad.
4. **Primer comando** — el que descarta más hipótesis de una vez.
5. **Causa** — la que confirmó la evidencia, no la que sonaba bien.
6. **Corrección** — el cambio mínimo.
7. **Prevención** — qué campo, qué sonda, qué verificación o qué hábito lo evita la próxima vez.

El que decide una guardia es el segundo. El quinto tiene una trampa que conviene nombrar: la causa "que sonaba
bien" se confirma sola si buscas confirmarla. La evidencia se mira **antes** de tener la hipótesis favorita.

### 5.2 Los primeros treinta segundos

Un orden fijo, que sirve para cualquier síntoma porque baja por las capas del sistema de la más ancha a la más
angosta:

```bash
kubectl get pods -A | grep -vE 'Running|Completed'                    # 1. ¿algo no corre?
kubectl get pods -A -o wide | awk '$3 ~ /0\//'                       #    ¿algo corre y no está listo?
kubectl events -A --types=Warning | tail -20                          # 2. ¿qué pasó hace poco?
kubectl -n <ns> describe pod <el sospechoso>                          # 3. ¿qué dice el cluster de él?
kubectl -n <ns> logs <el sospechoso> --previous                       # 4. ¿qué dijo antes de morir?
```

Cuatro preguntas, en ese orden, y **ninguna cambia nada**. Si el síntoma es de afuera (un 404, un error de
certificado), se agrega una quinta antes de entrar al cluster: **¿quién es el cliente, y qué ve?** (la
[Fase 19](19-tls-y-certificados.md) la hizo con los certificados; el caso 5.5 la hace con una ruta).

| Lo que ves | Primera herramienta | Por qué |
|---|---|---|
| `Pending` | `describe pod` (eventos del planificador) | no hay log: nunca arrancó |
| `CreateContainerConfigError`, `ContainerCreating` | `describe pod` y el mensaje del estado | tampoco hay log |
| `ImagePullBackOff` | `describe pod` | el kubelet dice qué no pudo traer y por qué |
| `CrashLoopBackOff` | `logs --previous` | el contenedor actual acaba de empezar; el que murió sabe por qué |
| `Running` y `0/1` | `describe pod` (la sonda) y `logs` | corre, y algo de lo que mira la readiness no contesta |
| `Running`, listo, y el cliente falla | desde el cliente hacia adentro: puerta, `Service`, pod | el pod no está mal; algo en el camino sí |
| todo da timeout | `exec` en un pod: nombre contra IP | una conexión rechazada por la red no da error, espera |

### 5.3 `describe` y `events`: lo que el cluster sabe

`describe` junta el estado del objeto y sus eventos; `kubectl events` muestra los eventos solos, en orden, y con
`--for` los de un objeto. Son la memoria corta del cluster: los eventos duran una hora por defecto, y después
desaparecen.

El caso: `pricing` reiniciado en un cluster donde el emisor perdió su CA (incidente 22). El pod no tiene log,
porque nunca arrancó:

```text
$ kubectl -n apps get events --sort-by=.lastTimestamp | grep -E "FailedMount|pricing-tls"
90s   Normal    Requested     certificate/pricing-tls          Created new CertificateRequest resource "pricing-tls-3"
26s   Warning   FailedMount   pod/pricing-65b9654dcf-56nfp     MountVolume.SetUp failed for volume "tls-server" : secret "pricing-tls" not found
```

Dos objetos distintos en dos líneas: un pod que espera un `Secret`, y un `Certificate` que pidió uno. Los
eventos cuentan la historia en el orden en que pasó, y `describe` del pod solo, no la habría contado.

### 5.4 `logs` y `logs --previous`: lo que dijo antes de morir

El caso: alguien le pasó a `inventory` una opción de la JVM mal escrita (`MaxRAMPercent` en lugar de
`MaxRAMPercentage`). El pod nuevo entra en `CrashLoopBackOff`:

```text
NAME                         READY   STATUS    RESTARTS      AGE
inventory-5689d6c6f4-x557l   0/1     Running   3 (28s ago)   51s
inventory-84d9fdb4d5-r5mxw   1/1     Running   0             41m
```

`Running` con tres reinicios en 51 segundos: el contenedor arranca, muere y el kubelet lo vuelve a arrancar,
cada vez esperando más. `describe` dice que murió, no por qué:

```text
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
```

`logs --previous` lee la salida del contenedor **anterior** al actual, el que murió:

```text
$ kubectl -n apps logs inventory-5689d6c6f4-x557l --previous
Unrecognized VM option 'MaxRAMPercent=75'
Did you mean 'MaxRAMPercentage=<value>'?
Error: Could not create the Java Virtual Machine.
```

Tres cosas para notar. Es **texto**, no JSON: la JVM murió antes de que existiera el logger de G7. La réplica
vieja sigue atendiendo, porque el rollout no avanza con una nueva que no está lista (`maxUnavailable: 0`, Fase
16): el sistema no se cayó. Y `--previous` guarda **una** vida anterior, solo mientras exista el pod: borrarlo
para "ver si arranca" borra la única evidencia (sección 9).

### 5.5 `port-forward`: saltarse capas

Un síntoma de afuera atraviesa capas: el cliente, la puerta, la ruta, el `Service`, el pod. `port-forward` abre
un túnel desde tu máquina directo al `Service` (o a un pod), **sin pasar por la puerta**, y parte el camino en
dos.

El caso: `pricing` por la puerta devuelve 404, y el pod está listo y sin errores en el log.

```text
$ curl -s -o /dev/null -w "por la puerta: %{http_code}\n" -H Host:api.localhost 'http://127.0.0.1:8080/pricing/prices?store=DRO-007'
por la puerta: 404
$ kubectl -n apps port-forward svc/pricing 18080:8080 &
$ curl -s -o /dev/null -w "por port-forward al Service: %{http_code}\n" 'http://127.0.0.1:18080/prices?store=DRO-007'
por port-forward al Service: 200
```

El servicio contesta; la puerta no lo encuentra. El problema está **entre** las dos, en la ruta:

```text
$ kubectl -n apps get httproute pricing -o jsonpath='{.spec.rules[0].matches[0].path}'
{"type":"PathPrefix","value":"/precios"}
```

Alguien la tradujo. Un dato que esta fase midió de paso: el `port-forward` funcionó con las `NetworkPolicy` de la
[Fase 20](20-seguridad-del-pod-y-de-la-red.md) puestas, que no dejan entrar al 8080 desde tu máquina. El túnel lo abre el kubelet dentro del
espacio de red del pod, y para la política el tráfico es local. **Por eso el permiso de `port-forward` (`create`
sobre `pods/portforward`) es un permiso serio**: se salta la red.

### 5.6 `exec`: entrar a mirar

`exec` corre un comando dentro de un contenedor que ya corre, con su red, su sistema de archivos y su usuario.
Es la herramienta para las preguntas que solo se contestan desde adentro: *¿resuelve este nombre?, ¿llega a esa
IP?, ¿qué variables tiene?*

El caso es el incidente 26: todo da timeout después de cerrar la red. Desde `replenish`, que trae Node:

```text
$ kubectl -n apps exec deploy/replenish -- node -e "require('dns').lookup('pricing',(e,a)=>console.log('lookup pricing:',e?e.code:a))"
lookup pricing: EAI_AGAIN
```

Y la misma conexión por la IP del `Service` pasa. El nombre no resuelve: es el DNS, no `pricing`. `exec` necesita
que la imagen traiga con qué preguntar: aquí, Node. En `pricing` no hay nada:

```text
$ kubectl -n apps exec pricing-6f554c6867-m6z65 -- sh
… exec: "sh": executable file not found in $PATH
```

### 5.7 Contenedores efímeros: depurar lo que no tiene shell

`pricing` corre en una imagen distroless, sin shell ni herramientas, a propósito ([Fase 04](04-empaquetar-los-cuatro-runtimes.md)). Para mirarlo por
dentro, `kubectl debug` le agrega al pod que ya corre un **contenedor efímero**, con la imagen que tú elijas, que
comparte el espacio de procesos del contenedor que le indiques con `--target`:

```bash
kubectl -n apps debug pricing-6f554c6867-m6z65 --image=busybox@sha256:bdf57e52… --target=pricing --container=dbg -- sleep 300
kubectl -n apps exec pricing-6f554c6867-m6z65 -c dbg -- sh -c 'id; ps -o pid,user,args'
```

```text
uid=65532 gid=65532 groups=65532
PID   USER     COMMAND
    1 65532    /pricing
   29 65532    sleep 300
```

Desde ahí se ve el proceso de `pricing`, su sistema de archivos (en `/proc/1/root/`), y se le habla a `localhost:8080`
como si estuvieras adentro. El efímero no se puede quitar: vive hasta que el pod se va.

Y el efímero **corre como 65532**. No lo pediste: lo heredó del pod, porque la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) fijó `runAsUser` a nivel de pod.
`kubectl` lo avisa (`Non-root user is configured for the entire target Pod, and some capabilities granted by debug
profile may not work`), y es una ventaja que la [Fase 15](15-salud-y-recursos.md) no tuvo. Allí, el *attach* de `jcmd` desde un efímero
sobre `inventory` no contestó; aquí, con un efímero del JDK y el mismo usuario que la JVM:

```text
$ kubectl -n apps debug inventory-84d9fdb4d5-r5mxw --image=eclipse-temurin@sha256:8c0a84ea… --target=inventory --container=jdk -- sleep 600
$ kubectl -n apps exec inventory-84d9fdb4d5-r5mxw -c jdk -- jcmd -l
1 inventory-0.0.1-SNAPSHOT.jar
$ kubectl -n apps exec inventory-84d9fdb4d5-r5mxw -c jdk -- jcmd 1 VM.flags
… -XX:MaxHeapSize=134217728 … -XX:+UseSerialGC
```

El *attach* de la JVM exige que quien lo pide sea el mismo usuario que la JVM. En la [Fase 15](15-salud-y-recursos.md), el efímero corría
como root y la JVM como 10001; ahora los dos son 10001. Lo que era una deuda de la [Fase 15](15-salud-y-recursos.md) lo resolvió el
endurecimiento de la [Fase 20](20-seguridad-del-pod-y-de-la-red.md), sin buscarlo. La imagen del JDK es la misma de la etapa de build de `inventory`, y
el nodo la bajó la primera vez.

### 5.8 k9s: el mismo kit, en una pantalla

k9s (la versión de [a01](a01-el-laboratorio.md)) es una interfaz de terminal sobre la misma API: no hace nada que `kubectl` no haga, y
lo hace sin escribir. Los atajos que corresponden a esta fase:

| En k9s | Es | Sección |
|---|---|---|
| `:pods`, y `/` para filtrar | `kubectl get pods`, con `grep` | 5.2 |
| `d` sobre un pod | `describe` | 5.3 |
| `:events` | `kubectl events` | 5.3 |
| `l`, y `p` dentro de los logs | `logs`, y `logs --previous` | 5.4 |
| `shift-f` | `port-forward` | 5.5 |
| `s` | `exec` con un shell | 5.6 |

`k9s --readonly` la abre sin poder borrar ni editar nada, que es como conviene abrirla en una guardia.

> ⚠️ **Lo verificado, y lo que no.** En la máquina del autor se verificó la versión (`k9s info`, 0.51.0). Abrirla
> contra `kind-lab` y recorrer los atajos de la tabla **no se verificó** en esta tanda: la sesión de verificación no
> tenía una terminal interactiva, y k9s la necesita. Los atajos son los de su documentación para esa versión.

---

### 5.9 Hipótesis y primer comando: los tres "no contesta"

El paso que más se salta es el tercero: escribir las hipótesis **antes** de correr nada. Con los tres casos de la
sección 4, la venta devuelve "no contesta". Las hipótesis razonables, en orden de probabilidad para este sistema:

1. El vecino está caído (sin réplicas listas).
2. El vecino está, y algo en el camino corta: la red, el DNS, un certificado.
3. El vecino está, contesta, y tarda más de lo que el cliente espera.

El **primer comando** es el que descarta más de una de una vez. Aquí no es `get pods` (descarta solo la primera),
ni probar el vecino por la puerta (prueba otro camino). Es **la línea de log de `inventory` en esa venta**, que G7
dejó en JSON con el motivo completo:

```text
caso 1:  pricing no contesta: I/O error on GET request for "https://pricing.apps.svc.cluster.local:8443/…":
         (certificate_required) Received fatal alert: certificate_required
caso 2:  (ninguna línea de inventory)
caso 3:  (ninguna línea de inventory, hasta 146 s después: un 201)
```

En el caso 1, el vecino contestó y rechazó el saludo: hipótesis 2, del lado del certificado. Los casos 2 y 3 **no
tienen línea**, y la ausencia también es evidencia: algo espera. El segundo comando los separa, y es el de la sección
5.6: desde adentro de un pod, el nombre (en el caso 2, `EAI_AGAIN`; en el 3, resuelve) y los pods del vecino (en el 3,
cero). Por eso G7 escribe el motivo entero en el log cuando lo hay, y por eso la falta de un timeout en `inventory` es
lo más caro de esta tabla: convierte un vecino caído en una espera muda y en una venta que el cliente cree fallida
y que se registra igual. Esa es la [Fase 22](22-resiliencia-y-caos.md).

Dos reglas salen de este ejemplo y valen para cualquier guardia:

- **El primer comando lee, no cambia.** Ninguno de los de la sección 5.2 modifica nada. Un primer comando que
  reinicia, escala o aplica algo destruye evidencia si la hipótesis estaba mal (sección 9).
- **El primer comando mira el lado que tiene la información.** En una llamada entre servicios, el cliente sabe
  por qué falló (el error de conexión); el servidor, a veces, ni se enteró. En la [Fase 19](19-tls-y-certificados.md), el log de `pricing` tenía
  la otra mitad del caso 1; en el caso 3, `catalog` no tiene nada que decir porque no existe.

## 🔁 6. El cuaderno, con el método

El [cuaderno](cuaderno-incidentes.md) se abre por **síntoma**: su primer índice empieza por lo que ves, con el texto literal, y lleva
al incidente sin haber leído la fase que lo reservó. Con esta fase, quedó revisado entero:

- **Los 27 están**, en los dos índices, con su entrada completa: 01–04 y 27 de ambiente, 05–17 y 25–26 de
  plataforma, 18–24 de certificados.
- **Cada entrada tiene sus treinta segundos y su primer comando** con la línea de salida que importa. Las del
  ambiente (01–04 y 27) se describen y se reconocen: romper la virtualización de la máquina del lector no es un
  ejercicio.
- **El método del cuaderno y el de esta fase dicen lo mismo con las mismas palabras** (la sección 5.1 los copia).
- **Las tareas `inc:break` existen** para 05–26. Las de 05–15 apuntan al cluster `minimo`, donde las fases que
  las reservaron corrían; las de 16–26, a `lab`.
- **Dos desviaciones, aceptadas y anotadas.** Las entradas de ambiente (01–03 y 27) dicen en prosa la línea que importa
  de su primer comando, porque no se provocan en la máquina del autor. Y las autopsias de las fases 19 y 20 cuentan la
  causa de los incidentes 18 y 26 desde la decisión que los produce: no se puede enseñar la renovación sin mostrar un
  vencimiento, ni el *default deny* sin el DNS. Si lees esas fases antes de hacer esos dos incidentes, ya los conoces.

La forma de usarlo después de esta fase es **a ciegas**: alguien corre `task inc:break -- <ID>` sin decir cuál, y tú
llegas al ID desde el síntoma. Es el ejercicio 24, y es el mejor entrenamiento de guardia que el curso puede dar.

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"si algo falla, lo reinicio; y si vuelve a fallar, miro el log"*. En compose,
con un servicio y un log, el orden casi no importaba. La apuesta, escrita antes de ejecutar:

> 🪞 **Apuesta antes de ejecutar.** `kubectl debug` con un contenedor efímero que comparte el espacio de procesos
> permite ver los procesos de `pricing` (distroless, sin shell), y el `jcmd` desde un efímero sobre `inventory`
> sigue sin contestar, como en la F15.
>
> **Resultado: mitad y mitad.** El efímero vio los procesos y el sistema de archivos de `pricing`. Y el `jcmd`
> **contestó**: la apuesta perdió esa mitad por una razón que nadie había buscado, el usuario del pod que fijó la
> [Fase 20](20-seguridad-del-pod-y-de-la-red.md) (sección 5.7).

La entrada está en [INSTINTOS.md](INSTINTOS.md#si-falla-lo-reinicio-y-después-miro).

---

## 📏 8. Los 27, por la herramienta que los abre

No hay medición de rendimiento en esta fase. Lo que sí se puede contar es **con qué herramienta empieza cada
incidente del cuaderno**, leyendo el primer comando de cada entrada:

| Primera herramienta | Incidentes | Cuántos |
|---|---|---|
| fuera del cluster (la máquina, el motor, el cliente TLS) | 01, 02, 03, 04, 18, 19, 24, 27 | 8 |
| `describe`, con sus eventos | 05, 06, 10, 11, 12, 13, 14, 15, 25 | 9 |
| `get` y el `status` de un objeto (`Gateway`, `Deployment`, emisor, `Secret`) | 08, 16, 17, 20, 21, 22 | 6 |
| `logs` | 09, 23 | 2 |
| `exec` desde adentro de un pod | 07, 26 | 2 |

Casi un tercio empieza **fuera** del cluster: el cliente que valida un certificado, el motor del host, la máquina
que no virtualiza. Diecisiete de los 27 se abren con `describe`, el `status` de un objeto o los logs, que son las
preguntas de la sección 5.2. `exec` y los contenedores efímeros aparecen menos de lo que su fama sugiere: son para cuando lo que el
cluster sabe no alcanza.

---

## ⚰️ 9. Autopsia: arreglar antes de mirar

**La decisión, con su mejor argumento.** Ante un pod que falla, redesplegar primero (`task deploy`, `kubectl
rollout restart`, borrar el pod) y mirar después si vuelve a fallar. *"El servicio está caído: lo primero es que
vuelva. Si es algo de verdad, va a fallar otra vez y lo miro."*

**Por qué era razonable.** A veces vuelve, y la guardia se termina. Y el instinto de que la disponibilidad va primero
es correcto.

**Qué pasó después, con número.** Le pasó al autor de este curso, en esta tanda, dos veces seguidas. Para la [Fase 20](20-seguridad-del-pod-y-de-la-red.md)
había que saber por qué `inventory` no arrancaba con la raíz de solo lectura. El primer intento leyó los logs
después de un `task deploy` que restauraba el estado:

```text
$ kubectl -n apps logs inventory-6b476c57d-xpjjf --previous
Error: error from server (NotFound): pods "inventory-6b476c57d-xpjjf" not found in namespace "apps"
```

El segundo intento, igual: el `Deployment` reemplazó el pod antes de leer la causa raíz del *stack trace*. **Dos
corridas completas del experimento perdidas, y la causa raíz que no se pudo citar**: la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) dice
`Unable to start web server`, y no la excepción que lo explicaba, porque esa evidencia ya no existía.

**Cuánto cuesta salir, con número.** Nada: el mismo orden, al revés. `logs --previous` y `describe` primero (diez
segundos), guardados en un archivo; después, el arreglo. Y con un servicio que de verdad está caído, la réplica vieja
del rollout atiende mientras miras (sección 5.4).

**Qué lo habría cambiado.** La regla del cuaderno, que está escrita desde el incidente 01: *anota el síntoma antes de
arreglarlo*. Y saber qué borra cada arreglo: un pod borrado se lleva sus logs y sus eventos (los del pod viejo
siguen en `kubectl events` una hora); un rollout se lleva los pods; un `task deploy` puede hacer las dos cosas.

**Antes y después, con números:** arreglando primero, dos experimentos repetidos y una causa raíz perdida; mirando
primero, diez segundos.

---

## 📖 10. Traducción

| En compose o en un servidor | En Kubernetes | Lo que cambia |
|---|---|---|
| `docker ps -a` | `kubectl get pods -A` | el estado tiene más matices (`CrashLoopBackOff`, `0/1`) |
| `docker inspect` | `kubectl describe` | incluye los eventos del objeto |
| `docker events` | `kubectl events` | duran una hora, y cubren todos los objetos, no solo contenedores |
| `docker logs` | `kubectl logs` y `--previous` | la vida anterior, una sola, mientras el pod exista |
| `docker exec` | `kubectl exec` | necesita que la imagen traiga con qué |
| `docker run --pid=container:<id>` con una imagen de herramientas | `kubectl debug --target` | el efímero queda en el pod hasta que el pod se va |
| `-p` para probar el puerto del contenedor | `kubectl port-forward` | se salta la puerta y la red del cluster |

Y al revés: un `kubectl debug` en un cluster ajeno es, en compose, un contenedor de herramientas que comparte el
espacio de procesos de otro; un `port-forward` es el `-p` que nunca publicaste. Las filas completas, en
[a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, el kit es el mismo, con dos diferencias: los eventos y los logs suelen ir también al servicio del
proveedor (y duran más que una hora), y `exec`, `port-forward` y `debug` se controlan con RBAC de forma estricta,
porque cada uno es una puerta trasera al pod.

---

## 🩺 11. Incidentes de esta fase

Esta fase no reserva incidentes: usa los 27. Los casos de la sección 5 son prácticas sin ID (una opción de la JVM
mal escrita, una ruta traducida), y los incidentes que nombra (22, 23 y 26) se resuelven en el
[cuaderno](cuaderno-incidentes.md), por su síntoma.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**El kit no reemplaza la observabilidad.** `kubectl` mira el ahora: los eventos duran una hora, los logs se van con
el pod, y `--previous` guarda una vida. Para lo que pasó ayer a las 6:40 p. m., hacen falta las métricas y los logs de
las fases 17 y 18. Esta fase diagnostica lo que está pasando; aquellas, lo que pasó.

**Los contenedores efímeros son poder.** Un efímero corre dentro del pod, con su red y, si el perfil lo permite, con
más capacidades que el contenedor. En un cluster compartido, `pods/ephemeralcontainers` y `pods/exec` son permisos que
se dan a pocos y se registran.

**`port-forward` se salta la red.** Útil para partir un camino en dos; peligroso como costumbre, porque prueba un
camino que ningún cliente real usa.

**Cuándo NO diagnosticar en caliente:** cuando el sistema está caído y hay una forma conocida de volver (un `helm
rollback`, la réplica vieja): primero se guarda la evidencia en diez segundos, después se vuelve, y después se
diagnostica sobre lo guardado. **Cuándo sí:** siempre que el sistema siga atendiendo mientras miras, que con
réplicas y un rollout bien configurado es casi siempre.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso con su salida y su estado. El orquestador
te dio eventos, `describe`, `logs --previous`, efímeros y túneles. **Te tocó a ti** el orden en que se miran, la
disciplina de no arreglar antes de anotar, y saber cuándo el problema está fuera del cluster.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`logs --previous` dice `previous terminated container … not found`.** El contenedor no murió nunca (es el primero), o
el pod es otro: el `Deployment` ya creó uno nuevo. Mira `RESTARTS` y la edad del pod.

**`kubectl events` no muestra nada de lo que pasó.** Pasó hace más de una hora, o en otro namespace (`-A`).

**`exec` dice `executable file not found`.** La imagen no trae ese programa: un efímero (sección 5.7).

**El efímero arranca y no ve los procesos.** Faltó `--target`, o el runtime no comparte el espacio de procesos:
`kubectl` lo avisa al crearlo.

**`jcmd` dice que no puede adjuntarse.** El usuario del efímero no es el de la JVM. Con `runAsUser` en el pod, lo
hereda; sin él, `--custom` con un perfil que lo fije.

**`port-forward` funciona y el cliente sigue fallando.** Está bien: el problema está en lo que el túnel se saltó (la
puerta, la ruta, la red).

---

## 📋 14. Checklist de validación

```text
[ ] los primeros treinta segundos, de memoria, sobre un incidente cualquiera
[ ] logs --previous en un CrashLoopBackOff, antes de tocar nada
[ ] port-forward partiendo un 404 entre la puerta y el servicio
[ ] un efímero sobre pricing, viendo su proceso; jcmd sobre inventory desde un efímero del JDK
[ ] k9s --readonly contra kind-lab, con los seis atajos de la sección 5.8 (sin verificar por el autor)
[ ] el cuaderno revisado: los 27 en los dos índices, con su primer comando
[ ] una guardia a ciegas (ejercicio 24)
```

---

## 🧪 15. Ejercicios (24)

Más de la mitad son guardias: alguien (o tú, con los ojos cerrados) rompe algo, y tú llegas a la causa con el método.
Los incidentes 16 a 26 corren contra `lab`; los 05 a 15, contra `minimo`.

## 🟢 Fácil — una herramienta a la vez (1–7)

### 🟢 Ejercicio 1 — Los treinta segundos, escritos
Escribe los cuatro comandos de la sección 5.2 en un archivo de tu repositorio, y córrelos con el sistema sano.

**Criterio:** el archivo, y la salida limpia: ningún pod fuera de `Running`/`Completed`, ningún `Warning` reciente.

<details><summary>Solución</summary>

Si con el sistema sano aparece algo, ese es tu primer hallazgo: los `Job` de migraciones que fallaron en un reintento
dejan pods en `Error` que no son un problema actual.
</details>

### 🟢 Ejercicio 2 — Los eventos de un pod
Borra un pod de `replenish` y lista los eventos del pod nuevo, en orden.

**Criterio:** `Scheduled`, `Pulled`, `Created`, `Started` y, si los hubo, los de la sonda.

<details><summary>Solución</summary>

`kubectl -n apps events --for pod/<el nuevo>`.
</details>

### 🟢 Ejercicio 3 — `logs --previous` sin necesidad
Pide `--previous` a un pod que nunca reinició. Lee el error.

**Criterio:** el mensaje, y qué te dice sobre el pod.

<details><summary>Solución</summary>

`previous terminated container "…" in pod "…" not found`: nunca murió. `RESTARTS 0` lo decía antes.
</details>

### 🟢 Ejercicio 4 — Un efímero en el `storefront`
Mira los procesos de nginx del `storefront` desde un efímero.

**Criterio:** el proceso maestro y los trabajadores, con su usuario.

<details><summary>Solución</summary>

`kubectl debug … --image=busybox@sha256:… --target=storefront`. El usuario es 101, heredado del pod.
</details>

### 🟢 Ejercicio 5 — `port-forward` a Prometheus
Con las métricas encendidas, abre Prometheus con `port-forward` en lugar de la puerta.

**Criterio:** la interfaz en `localhost:<puerto>`, y una frase sobre qué se saltó.

<details><summary>Solución</summary>

`kubectl -n observability port-forward svc/prometheus 19090:9090`. La puerta y su ruta.
</details>

### 🟢 Ejercicio 6 — `exec` con variables
Muestra las variables de entorno que ve `inventory`, y encuentra de dónde sale cada una.

**Criterio:** `PRICING_URL` y su origen (el `Deployment`, no el `ConfigMap`).

<details><summary>Solución</summary>

`kubectl -n apps exec deploy/inventory -- env`. Compara con `kubectl -n apps get cm neighbors -o yaml`: la variable del
`Deployment` gana.
</details>

### 🟢 Ejercicio 7 — k9s, en modo de lectura
Abre `k9s --readonly` y haz la guardia del ejercicio 1 sin escribir un comando.

**Criterio:** los mismos hallazgos, y el atajo que usaste para cada uno.

<details><summary>Solución</summary>

`:pods`, `/` para filtrar, `:events`, `d`, `l`. Con `--readonly`, `ctrl-d` no borra.
</details>

## 🟡 Intermedio — guardias guiadas (8–14)

### 🟡 Ejercicio 8 — Guardia: el 16
`task inc:break -- 16`. Llega a la causa sin abrir el cuaderno.

**Criterio:** los siete pasos escritos, con el primer comando y su línea.

<details><summary>Solución</summary>

El rollout espera (`READY 2/2`, `UP-TO-DATE 1`): la versión nueva no está lista. `describe` del pod nuevo: la readiness
en 503; su log: la base no acepta la contraseña.
</details>

### 🟡 Ejercicio 9 — Guardia: el 21
`task inc:break -- 21`. **Antes** de mirar nada del cluster, di qué ves desde el cliente.

**Criterio:** la pregunta "¿quién es el cliente?" contestada, y la causa.

<details><summary>Solución</summary>

`SSL_ERROR_SYSCALL` en todos los nombres: no es un certificado mal validado, es un listener que no carga. El `status` del
`Gateway` lo dice.
</details>

### 🟡 Ejercicio 10 — Guardia: el 23
`task inc:break -- 23`. Encuentra la causa leyendo **los dos lados** de la conexión.

**Criterio:** la línea de `inventory` y la de `pricing`, del mismo segundo.

<details><summary>Solución</summary>

`certificate_required` de un lado, `client didn't provide a certificate` del otro.
</details>

### 🟡 Ejercicio 11 — Guardia: el 26
`task inc:break -- 26`. Encuentra la causa sin usar la puerta.

**Criterio:** la prueba por nombre y por IP desde un pod.

<details><summary>Solución</summary>

La sección 5.6.
</details>

### 🟡 Ejercicio 12 — El caso de la ruta, sin `port-forward`
Repite el caso de la sección 5.5 y encuéntralo **sin** `port-forward`.

**Criterio:** otra forma de partir el camino, y cuál te parece más rápida.

<details><summary>Solución</summary>

Un pod de prueba en `apps` contra `http://pricing:8080` (pasa) y el `status` de la `HTTPRoute`; o el log de `pricing`
(sin línea `request` para tu petición).
</details>

### 🟡 Ejercicio 13 — `jcmd`, más allá
Con el efímero del JDK, saca un *thread dump* de `inventory` durante una venta lenta.

**Criterio:** el hilo de la venta esperando a `pricing`, en el *dump*.

<details><summary>Solución</summary>

`jcmd 1 Thread.print`. Haz lenta la venta (el ejercicio 18 de esta fase) y busca `SalesController` en el *dump*.
</details>

### 🟡 Ejercicio 14 — Guardar la evidencia
Escribe una tarea (`task evidence -- <ns> <pod>`) que guarde en un archivo los cuatro comandos de la sección 5.2 y
`logs --previous` de un pod, con la hora.

**Criterio:** el archivo con todo, generado en menos de diez segundos.

<details><summary>Solución</summary>

Un script de Python en `scripts/` (uno para los tres sistemas) que corre `kubectl` y escribe un archivo por corrida.
Es la respuesta práctica a la sección 9.
</details>

## 🟠 Difícil — guardias a ciegas (15–20)

### 🟠 Ejercicio 15 — Uno de certificados
Alguien corre uno de los incidentes 18 a 24 sin decirte cuál.

**Criterio:** el ID, en menos de diez minutos, con el comando que lo distinguió de los demás.

<details><summary>Solución</summary>

Primero el cliente (navegador, servicio, nodo); después las cuatro preguntas de la [Fase 19](19-tls-y-certificados.md) en orden.
</details>

### 🟠 Ejercicio 16 — Uno de plataforma
Lo mismo, con los incidentes 16, 17, 25 o 26.

**Criterio:** el ID y los siete pasos.

<details><summary>Solución</summary>

El estado del pod decide la primera herramienta (la tabla de la sección 5.2).
</details>

### 🟠 Ejercicio 17 — Dos a la vez
Alguien corre dos incidentes juntos (por ejemplo, el 22 y el 26).

**Criterio:** los dos IDs, y en qué orden los arreglaste.

<details><summary>Solución</summary>

El 26 primero: sin DNS, ninguna otra evidencia es confiable (cert-manager tampoco resuelve).
</details>

### 🟠 Ejercicio 18 — La venta lenta
Haz que `pricing` tarde dos segundos en contestar (con un efímero, o con el generador de caos si ya lo tienes) y
diagnostica la lentitud de la venta **sin** tableros.

**Criterio:** la evidencia de que la espera está en `pricing`, con tiempos.

<details><summary>Solución</summary>

El `duration_ms` de la línea `request` de cada servicio (G7), con el mismo `request_id`. Es la [Fase 23](23-grpc-y-el-balanceo.md) sin trazas.
</details>

### 🟠 Ejercicio 19 — Sin `kubectl`
Diagnostica el incidente 24 sin usar `kubectl`.

**Criterio:** la causa, con los comandos del motor y del nodo.

<details><summary>Solución</summary>

`docker exec lab-worker crictl pull lab-registry:5000/lab/pricing:g8` da el mismo error; `ls
/etc/containerd/certs.d/` muestra que falta la carpeta.
</details>

### 🟠 Ejercicio 20 — El pod que se va
Un pod en `CrashLoopBackOff` y un compañero que ya lo borró "para ver si arrancaba". Recupera lo que puedas de lo
que pasó.

**Criterio:** lo que sobrevivió (eventos del pod viejo, el log del pod nuevo, las métricas), y lo que no.

<details><summary>Solución</summary>

`kubectl events` guarda una hora los del pod viejo; su `--previous` se perdió; si los logs estaban encendidos ([Fase 18](18-logs.md)),
Loki tiene todo.
</details>

## 🔴 Muy difícil — diseñar la guardia (21–24)

### 🔴 Ejercicio 21 — Un incidente tuyo
Diseña un incidente nuevo para el cuaderno, en su formato, con un síntoma que no se parezca a ninguno de los 27.

**Criterio:** la entrada completa, provocada y verificada, con su tarea en `inc.py`.

**Rúbrica:** el síntoma literal ejecutado; los treinta segundos que lo distinguen; un ID que no reasigne ninguno; y la
corrección mínima como `git diff`.

### 🔴 Ejercicio 22 — Un perfil de depuración
Escribe un perfil personalizado para `kubectl debug --custom` que te deje usar `tcpdump` en un pod endurecido, y
explica qué permiso le da.

**Criterio:** el perfil, la captura de una petición a `pricing`, y la lista de lo que el perfil abre.

**Rúbrica:** la capacidad `NET_RAW` (y `NET_ADMIN`, si hace falta) solo en el efímero; por qué no en el contenedor; y
quién debería poder usarlo.

### 🔴 Ejercicio 23 — El runbook del 14 de octubre
Escribe el primer minuto de la guardia del 14 de octubre, en este sistema: qué miras, en qué orden, con qué
herramienta de las fases 17, 18 y 21.

**Criterio:** el runbook, y una prueba sobre el laboratorio con un síntoma parecido (la base lenta).

**Rúbrica:** el tablero primero (qué va mal), los logs después (qué), el kit al final (dónde, en el ahora); y la
decisión de cuándo dejar de diagnosticar y volver atrás.

### 🔴 Ejercicio 24 — La guardia completa
Alguien corre `task inc:break` con un ID al azar entre 16 y 26. Diagnostica, arregla con el cambio mínimo, y escribe la
bitácora del cuaderno.

**Criterio:** el ID correcto, el arreglo, y la bitácora con el tiempo que tardaste.

**Rúbrica:** los treinta segundos antes de cualquier hipótesis; la evidencia guardada antes del arreglo; la prevención
escrita como algo que vas a cambiar, no como un deseo.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *Debug Running Pods* (`exec`, efímeros, `--target`): https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Kubernetes, *Ephemeral Containers*: https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/
- Kubernetes, *Determine the Reason for Pod Failure*: https://kubernetes.io/docs/tasks/debug/debug-application/determine-reason-pod-failure/
- Kubernetes, *Use Port Forwarding to Access Applications in a Cluster*: https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/
- k9s, *Commands* (los atajos): https://k9scli.io/topics/commands/
- OpenJDK, `jcmd`: https://docs.oracle.com/en/java/javase/25/docs/specs/man/jcmd.html

**Libros y ensayos**

- Betsy Beyer y otros (eds.), *Site Reliability Engineering* (2016), *Effective Troubleshooting*:
  https://sre.google/sre-book/effective-troubleshooting/
- Brendan Gregg, *The USE Method*: https://www.brendangregg.com/usemethod.html (el método para recursos, que
  complementa al de esta fase).

**Orden de lectura sugerido:** antes, *Effective Troubleshooting* (el método con otras palabras); durante, *Debug
Running Pods* con la sección 5.7 delante; después, el cuaderno, a ciegas.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 21 (cluster lab, valores de minimo)

  el sistema     sin cambios desde la Fase 20
  el cuaderno    27 incidentes con su entrada completa, revisados con el método; inc:break para 05–26
  el kit         describe · events · logs --previous · exec · port-forward · debug (efímeros) · k9s
```

> **La señal de que quedó bien:** *"Ante cualquier síntoma, sé qué cuatro cosas mirar antes de tocar nada, guardo lo
> que vi, y sé cuándo el problema está fuera del cluster."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-21-diagnostico -m "F21 cerrada: el método de siete pasos y los primeros treinta segundos; describe, events, logs --previous, exec, port-forward, efímeros (jcmd incluido) y k9s; el cuaderno revisado con sus 27"
> ```
>
> Commits con prefijo `f21:`.

---

## 📌 Pendientes sugeridos

- **F22:** el timeout que nadie puso, diagnosticado con este kit antes de arreglarlo.
- **F23:** el tiempo de cada salto, que hoy se adivina comparando las horas de los logs.
