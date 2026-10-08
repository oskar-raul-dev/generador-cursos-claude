# 🪜 Fase 06 — Del compose al cluster: dónde se rompe el instinto, y el bucle que lo reemplaza

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 06 de 27 · Parte I — El modelo y el salto · **densa**
> **Perfil:** compose, sin cluster · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 `podman kube play` corre un manifiesto de Kubernetes sin cluster
> **Servicios que toca:** `pricing` como sujeto; `inventory`, `replenish`, `catalog` y `storefront` donde el instinto se rompe distinto · **Paso de generación:** ninguno
> **Depende de:** [Fase 05](05-los-dos-motores.md) · **Habilita:** [Fase 07](07-el-cluster-local.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna
> **Apéndices de apoyo:** [a05](a05-diccionarios.md), [a01](a01-el-laboratorio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64, con Docker y con Podman
> **Objetivo:** demostrar en compose, caso por caso, las cinco garantías que compose no da, explicar el bucle de reconciliación que las da, y traducir cualquier `compose.yaml` a los objetos de Kubernetes que lo reemplazan.

---

## 🧭 1. Dónde estamos

La Parte I armó el modelo: un contenedor es un proceso con la vista recortada ([Fase 03](03-el-contenedor-por-dentro.md)), una imagen
se construye en una etapa y corre en otra ([Fase 04](04-empaquetar-los-cuatro-runtimes.md)), y los dos motores corren lo mismo con plomería
distinta ([Fase 05](05-los-dos-motores.md)). El sistema sigue en compose, donde funciona. Esta fase es la bisagra del curso:
**por qué no alcanza con compose**, demostrado en compose, antes de levantar el primer cluster.

En la reunión en que Valentina presentó el plan de la Parte II, Luz Marina dibujó en el tablero la
historia del Siga (historia §1.6, §1.7 y §1.10): en 2012, un cluster de nodos detrás de un
balanceador; en 2016, una copia en espera en Bogotá; en 2021, un segundo Siga activo con la base
partida por región. Cada paso resolvió el problema de su año, y cada uno sumó licencias. Debajo
escribió la frase que en sistemas ya es de la casa:

> *"Lo multiplicamos, pero no lo separamos. Ahora díganme qué promete ese cluster suyo que no
> prometía el nuestro, porque 'réplicas' y 'balanceador' ya los tenemos."*

Es la pregunta correcta, y tiene una respuesta corta que esta fase convierte en larga: el cluster
del Siga multiplica el sistema y le pone delante un balanceador; un orquestador **mantiene un estado
deseado**, todo el tiempo, sin que nadie lo vuelva a pedir. Para que la diferencia no sea un acto de
fe, cada promesa se prueba primero en compose, que es lo que el lector ya usa, y se ve dónde falla.

---

## 🎯 2. Objetivos de esta fase

1. Ver fallar `depends_on` sin condición, y ver por qué un `healthcheck` de compose no puede arreglarlo
   en dos de los cinco servicios.
2. Mostrar que `restart: always` no reinicia un contenedor enfermo ni recrea uno borrado.
3. Comprobar que la red de compose resuelve nombres pero no es el DNS de un cluster.
4. Medir cómo reparte compose el tráfico entre tres réplicas, con conexión reutilizada y sin ella.
5. Explicar el bucle de reconciliación con un diagrama, y probar un manifiesto de Kubernetes sin
   cluster con `podman kube play`.

---

## 🚫 3. Qué NO entra todavía

- El cluster, sus nodos y `kubectl` → [Fase 07](07-el-cluster-local.md).
- El primer `Deployment` en un cluster de verdad → [Fase 08](08-el-primer-despliegue.md); los `Service` y el DNS del cluster en
  vivo, Fases 08 y 09.
- Las sondas de verdad (`readinessProbe`, `livenessProbe`) → [Fase 15](15-salud-y-recursos.md).
- Compose como herramienta de producción: fuera del curso. No lo es, y decirlo es parte del
  contenido de esta fase.

---

## 🧨 4. El problema, en el laboratorio

Una caja de droguería que, apenas arranca, le pregunta a `inventory` cuánto hay de salbutamol. En
compose, con la dependencia declarada como la escribe todo el mundo:

```yaml
# f06-depende.yaml — una caja que pregunta la existencia apenas arranca
name: f06
services:
  inventory:
    image: lab/inventory
  caja:
    image: lab/replenish
    command: ["wget", "-qO-", "http://inventory:8080/stock/DRO-007/SKU-0003"]
    depends_on: [inventory]
```

```text
$ docker compose -f f06-depende.yaml up caja
 Container f06-caja-1 Starting
caja-1  | wget: can't connect to remote host (192.168.16.2): Connection refused
caja-1 exited with code 1
```

Tres de tres corridas, el mismo error. `depends_on` esperó a que el contenedor de `inventory`
**arrancara**, y Spring Boot necesita más o menos un segundo para abrir el puerto. La respuesta de
manual es un `healthcheck` y `condition: service_healthy`:

```yaml
  inventory:
    image: lab/inventory
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health/ready"]
      interval: 2s
      retries: 10
  caja:
    # …
    depends_on:
      inventory: {condition: service_healthy}
```

```text
$ docker compose -f f06-sana.yaml up caja
 Container f06-inventory-1 Waiting
 Container f06-inventory-1 Error dependency inventory failed to start
dependency failed to start: container f06-inventory-1 is unhealthy
$ docker inspect f06-inventory-1 --format '{{json .State.Health.Log}}'
[{"Start":"2026-10-03T23:27:48.700074428Z",…,"ExitCode":-1,"Output":"OCI runtime exec failed: exec failed: unable to start container process: exec: \"wget\": executable file not found in $PATH"},…
```

La imagen de `inventory` de la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) corre sobre el JRE, y no tiene `wget` ni `curl`. **El
`healthcheck` de compose se ejecuta adentro del contenedor, con las herramientas del contenedor.**
Para `pricing`, que corre sobre distroless sin shell, no hay `healthcheck` posible. La salida de
compose es meter un cliente HTTP en cada imagen solo para que la sonda tenga con qué correr, que es
deshacer lo que la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) se esforzó en quitar.

Esto es lo que compose sabe hacer y lo que no, en un solo ejemplo. Lo que sigue es cada promesa que
el instinto le atribuye a compose, probada.

---

## 🪜 5. Dónde se rompe el instinto de compose, con `pricing`

### 5.1 `depends_on` ordena el arranque, y nada más

Lo que la sección 4 mostró, dicho como regla: `depends_on` decide **en qué orden se crean los
contenedores**, una vez, al levantar. No dice nada de cuándo uno puede atender, ni de qué pasa si la
dependencia se cae una hora después. En un cluster no existe ni siquiera eso: **nadie espera a
nadie**. Cada servicio arranca cuando puede, y tiene que tolerar que su vecino todavía no esté, o que
desaparezca. Lo que impide que le llegue tráfico antes de tiempo es la readiness, y la comprueba el
kubelet **desde afuera** del contenedor, con una petición HTTP, sin que la imagen necesite traer
ninguna herramienta ([Fase 15](15-salud-y-recursos.md)).

### 5.2 `restart: always` no es un `Deployment`

`replenish` con `restart: always` y una sonda que siempre falla, para tener un servicio vivo pero
enfermo:

```yaml
# f06-restart.yaml
services:
  replenish:
    image: lab/replenish
    restart: always
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/no-existe"]
      interval: 2s
      retries: 3
```

```text
$ docker compose -f f06-restart.yaml up -d
$ docker compose -f f06-restart.yaml ps --format '{{.Name}}  {{.Status}}'      # 25 segundos después
f06-replenish-1  Up 25 seconds (unhealthy)
$ docker inspect f06-replenish-1 --format 'RestartCount={{.RestartCount}}'
RestartCount=0
```

Enfermo hace veinte segundos y nadie lo toca: **un contenedor `unhealthy` no se reinicia**. La
política de reinicio mira una sola cosa, si el proceso terminó. Cuando el proceso muere de verdad (lo
mato desde la máquina virtual, como moriría por un error), sí:

```text
$ docker run --rm --pid=host --privileged lab/replenish kill -9 5767
$ docker compose -f f06-restart.yaml ps --format '{{.Name}}  {{.Status}}'
f06-replenish-1  Up 4 seconds (health: starting)
$ docker inspect f06-replenish-1 --format 'RestartCount={{.RestartCount}}'
RestartCount=1
```

Y dos casos donde no actúa: `docker kill` cuenta como detención manual, y el contenedor se queda
detenido (`RestartCount` siguió en 0); y si el contenedor se borra (`docker rm -f`), diez segundos
después `docker compose ps -a` no muestra nada. **Nadie lo vuelve a crear**, porque la política vive
en el contenedor y el contenedor ya no existe.

Un `Deployment` no tiene política de reinicio: tiene un **número**. *"Quiero dos réplicas de
`pricing`"*. Si un pod muere, se borra, se enferma o desaparece con su nodo, un controlador ve que
hay una y crea otra. No reinicia lo que había: reemplaza hasta que lo que hay coincide con lo
pedido.

### 5.3 La red resuelve por nombre, pero no es el DNS de un cluster

```text
$ docker run --rm --network lab_default lab/replenish nslookup pricing
Server:		127.0.0.11
Address:	127.0.0.11:53

Name:	pricing
Address: 172.31.0.3
$ docker run --rm --network lab_default lab/replenish nslookup pricing.apps.svc.cluster.local
*** Can't find pricing.apps.svc.cluster.local: No answer
$ docker network create f06-otra
$ docker run --rm --network f06-otra lab/replenish wget -qO- -T 3 'http://pricing:8080/health/live'
wget: bad address 'pricing:8080'
```

El nombre lo resuelve el motor (`127.0.0.11`), **solo dentro de la red del proyecto**, y es un nombre
plano: no hay espacios de nombres, no hay dominio, y un contenedor en otra red no lo encuentra. En un
cluster, el nombre lo da un `Service`, vive en un namespace (`pricing.apps.svc.cluster.local`), y
cualquier pod del cluster lo resuelve, con permiso o sin él según las políticas de red de la Fase
20.

### 5.4 `--scale` da réplicas que nadie balancea

```text
$ docker compose -f compose/compose.yaml up -d --scale pricing=3 pricing
$ docker run --rm --network lab_default lab/replenish nslookup pricing
Name:	pricing
Address: 172.31.0.3
Name:	pricing
Address: 172.31.0.7
Name:	pricing
Address: 172.31.0.8
```

Tres réplicas, tres direcciones bajo el mismo nombre. Compose no pone nada delante de ellas: el DNS
devuelve las tres y **el cliente elige**. Cómo reparte depende entonces del cliente, y la apuesta de
la sección 7 lo mide con dos clientes distintos.

Y una réplica que publica un puerto no se puede escalar:

```text
$ docker compose -f compose/compose.yaml up -d --scale storefront=2 storefront
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint lab-storefront-2 (ef5bfaa3…): Bind for 127.0.0.1:8082 failed: port is already allocated
```

### 5.5 Los volúmenes son de esta máquina

```text
$ docker volume create f06-datos
$ docker volume inspect f06-datos --format '{{.Mountpoint}}'
/var/lib/docker/volumes/f06-datos/_data
$ ls /var/lib/docker/volumes/f06-datos          # en el Mac
ls: /var/lib/docker/volumes/f06-datos: No such file or directory
```

El volumen vive en el disco de la máquina virtual del motor, ni siquiera en tu Mac. Es de esa
máquina y punto: si el servicio se moviera a otra, sus datos no lo seguirían. En un cluster, el
disco lo **pide** el pod (`PersistentVolumeClaim`) y lo **da** el cluster, que sabe en qué nodo
puede montarlo. Es la [Fase 12](12-estado-y-almacenamiento.md), y el experimento con el que abre es exactamente esto llevado a dos
réplicas.

### 5.6 El bucle de reconciliación

Las cinco secciones anteriores tienen una causa común. Compose **actúa cuando lo llamas**: `up -d`
compara el archivo con lo que corre, corrige las diferencias y termina. La [Fase 02](02-compose-el-sistema-en-un-archivo.md) lo vio como
idempotencia. Aquí se ve lo que eso implica:

```text
$ docker kill lab-pricing-1
$ docker compose -f compose/compose.yaml ps -a pricing --format '{{.Name}}  {{.Status}}'      # 10 s después
lab-pricing-1  Exited (137) 10 seconds ago
$ docker compose -f compose/compose.yaml up -d
 Container lab-pricing-1 Starting
 Container lab-pricing-1 Started
```

Diez segundos muerto, y diez minutos, o diez días, hasta que alguien vuelva a correr `up -d`. **En
compose, el bucle de reconciliación eres tú.** Kubernetes saca a la persona del bucle:

```mermaid
flowchart TD
    TU["tú"] -- "«quiero 2 réplicas de pricing»" --> API["API<br/>el estado deseado, guardado"]
    API --> O
    subgraph CTRL["el controlador"]
        O["1. observa<br/>¿cuántos pods de pricing hay listos?"] --> C["2. compara<br/>deseado 2 · actual 1"]
        C --> A["3. actúa<br/>crea un pod"]
    end
    A --> CL["el cluster<br/>lo que de verdad corre"]
    CL -- "y vuelve a empezar, sin parar" --> O
```

Le dices al cluster **qué quieres**, no qué haga. Un controlador observa, compara y actúa, y vuelve a
empezar: si un pod muere, si un nodo se va, si alguien borra algo a mano. Casi todo lo que el curso
enseña en la Parte II es un controlador distinto con el mismo bucle: el del `Deployment` ([Fase 08](08-el-primer-despliegue.md)),
el de la entrada ([Fase 10](10-la-entrada-al-sistema.md)), el del `StatefulSet` ([Fase 12](12-estado-y-almacenamiento.md)), el del HPA ([Fase 16](16-escalado-y-rollout.md)). **Sin esto,
Kubernetes es una API rara; con esto, casi todo se deduce.** La [Fase 08](08-el-primer-despliegue.md) lo va a mostrar en vivo,
borrando un pod.

**Dónde vive el deseo.** En compose, el estado deseado es un archivo en tu disco: si lo editas y no
corres `up`, no pasa nada, y si otra persona tiene otra copia, hay dos deseos y ninguno manda. En
Kubernetes, el deseo se **entrega** al cluster (`kubectl apply`, en la [Fase 08](08-el-primer-despliegue.md)) y queda guardado en su
API. Desde ese momento el archivo de tu disco es una copia; lo que manda es lo que la API tiene, y
cualquiera con permiso puede preguntarle al cluster qué se pidió y qué hay. Esa es la otra mitad de
la respuesta a Luz Marina: el cluster del Siga tenía réplicas, pero el "cuántas y cuáles" vivía en la
cabeza de quien hacía la ventana de despliegue.

**Lo que el bucle no promete.** No es instantáneo: observa, compara y actúa en ciclos, y entre que un
pod muere y que su reemplazo atiende pasa un tiempo que depende de lo que tarde en arrancar (la tabla
de primer 200 de la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) empieza a importar aquí). No es inteligente: si el deseo está mal —una
imagen que no existe, un límite de memoria que la JVM no aguanta—, el bucle insiste para siempre en
cumplirlo, y lo que ves es un pod que se reinicia sin parar. Y no arregla el código: un servicio que
no tolera la ausencia de su vecino falla en cada vuelta del bucle, igual que fallaba en compose.
**La plataforma reemplaza lo que muere; que lo que arranca sirva sigue siendo tuyo.**

### 5.7 🦭 El YAML es un deseo: `podman kube play`

Podman puede leer un manifiesto de Kubernetes y correrlo, sin cluster. Un `Deployment` de `pricing`
con dos réplicas:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pricing
  labels:
    app.kubernetes.io/name: pricing
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: pricing
  template:
    metadata:
      labels:
        app.kubernetes.io/name: pricing
    spec:
      containers:
        - name: pricing
          image: lab/pricing
          ports:
            - containerPort: 8080
              hostPort: 18080
```

```text
$ podman kube play pricing.yaml
$ podman pod ps
POD ID        NAME         STATUS      CREATED                 INFRA ID      # OF CONTAINERS
12fa281d4ace  pricing-pod  Running     Less than a second ago  3c1be8a16714  2
$ podman ps --format '{{.Names}}  {{.Image}}  {{.Status}}'
12fa281d4ace-infra    Up Less than a second
pricing-pod-pricing  docker.io/lab/pricing:latest  Up Less than a second
$ curl -s 'http://127.0.0.1:18080/prices/SKU-0003?store=DRO-007'
{"currency":"COP","price":12900,"sku":"SKU-0003","store":"DRO-007"}
$ podman kill pricing-pod-pricing
$ podman ps -a --format '{{.Names}}  {{.Status}}'          # 3 segundos después
12fa281d4ace-infra  Exited (0) 3 seconds ago
pricing-pod-pricing  Exited (137) 3 seconds ago
```

Tres cosas en una salida. **Pidió dos réplicas y levantó un pod**: Podman entiende el formato, no el
deseo. **Al morir, nadie lo reemplazó**: no hay controlador, no hay bucle. Y el pod tiene **dos
contenedores**: el de `pricing` y uno `infra`, que no hace nada más que sostener los namespaces que
los demás comparten. Es lo mismo que hizo `network_mode: service:catalog` en la [Fase 04](04-empaquetar-los-cuatro-runtimes.md), y es la
definición de un pod: **contenedores que comparten red y que se programan juntos**. Es la prueba más
corta de que el YAML describe un deseo, y de que lo que lo cumple es el orquestador.

> 🩻 **Esto sí funciona igual.** La imagen, el proceso 1, las variables de entorno, el puerto del
> contenedor y la idea de declarar el sistema en un archivo pasan de compose a Kubernetes sin
> cambios. Lo que cambia es quién lee el archivo, y cuántas veces.

**Prueba de fuego.** Las cinco promesas, con su resultado en tu máquina: `depends_on` con `Connection
refused`; `unhealthy` con `RestartCount=0`; `bad address` desde otra red; una réplica sin tráfico con
conexión reutilizada; un `pricing` muerto que solo vuelve con `up -d`.

**El patrón a memorizar.** Compose ejecuta un archivo cuando se lo pides; un orquestador mantiene un
estado deseado sin que se lo vuelvas a pedir. Todo lo demás —reemplazar, balancear, esperar,
mover— sale de esa diferencia.

---

## 🔁 6. Los otros tres: donde no es mecánico

El instinto se rompe igual con los cinco servicios, pero no con el mismo costo:

- **`inventory`** no puede tener `healthcheck` en compose sin agregarle un cliente HTTP a la imagen, y
  es justo el servicio que tarda en estar listo. Es el que más pierde con `depends_on`.
- **`pricing`**, sobre distroless, no puede tener ninguno: no hay shell ni herramientas. En un
  cluster, su sonda es una petición del kubelet y no le cuesta nada a la imagen.
- **`catalog`** ya es un pod en compose: dos contenedores con `network_mode: service:catalog`. Lo que
  compose no sabe es que son una unidad: si muere FPM, el nginx sigue corriendo y contesta 502 (Fase
  04, ejercicio 22). En Kubernetes los dos contenedores viven y se reemplazan juntos ([Fase 09](09-los-cuatro-servicios-dentro.md)).
- **`storefront`** no se puede escalar mientras publique un puerto en el host. En un cluster nadie
  publica en el host: se entra por un `Gateway` ([Fase 10](10-la-entrada-al-sistema.md)).
- **`replenish`**, el consumidor de eventos de la Parte IV, es el que más va a depender de que
  alguien lo reemplace cuando muera, porque procesa trabajo que nadie le vuelve a pedir.

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto, en su mejor versión: *"`--scale` me da réplicas, y el nombre del servicio las reparte.
Es un balanceador gratis."* Hay algo de verdad: el DNS de compose devuelve todas las direcciones. La
pregunta es qué hace el cliente con ellas, y depende de si reutiliza la conexión.

> 🪞 **Apuesta antes de ejecutar.** Con `--scale pricing=3` y 300 peticiones desde un cliente que
> reutiliza la conexión, una sola réplica atiende más del 90 %; abriendo una conexión nueva por
> petición, cada réplica atiende entre el 25 % y el 42 %.
>
> **Resultado: perdida la primera mitad, ganada la segunda.** Con `fetch` de Node, que mantiene las
> conexiones abiertas, cuatro corridas: tres repartieron 150 y 150 entre **dos** réplicas, y una
> mandó las 300 a una sola. **En las cuatro, al menos una réplica no recibió ni una petición.** Con
> `wget`, una conexión nueva cada vez, tres corridas: entre 86 y 111 peticiones por réplica, del 29
> al 37 %.

| Cliente, 300 peticiones a `pricing` con 3 réplicas | Réplica que más recibió | Réplicas sin tráfico |
|---|---|---|
| conexión reutilizada (`fetch` de Node), 4 corridas | 150 · 300 · 150 · 150 | 1 · 2 · 1 · 1 |
| conexión nueva cada vez (`wget`), 3 corridas | 106 · 104 · 108 | 0 · 0 · 0 |

La apuesta perdida dice algo más fino de lo que predije: no es que el cliente se pegue a una réplica,
es que **reparte entre las conexiones que abrió, y nunca abre las suficientes para todas**. En
cualquier caso, el reparto lo decide el cliente. Un `Service` de Kubernetes tampoco balancea por
petición sobre una conexión abierta —lo que lo resuelve es otra conversación, la de la [Fase 23](23-grpc-y-el-balanceo.md) con
gRPC—, pero sí pone **una sola dirección estable** delante de las réplicas listas, y deja fuera las
que no lo están, que es lo que compose no hace.

---

## 🧨 8. La rotura: `depends_on` sin condición

La rotura de esta fase es la de la sección 4, y la dejo escrita con sus tres partes porque es la que
el lector va a encontrar en su trabajo:

- **El cambio exacto:** declarar `depends_on: [inventory]` y asumir que `inventory` puede atender
  cuando el cliente arranca.
- **El síntoma literal:** `wget: can't connect to remote host (192.168.16.2): Connection refused` y
  `caja-1 exited with code 1`, tres de tres. Con `condition: service_healthy` y una imagen sin
  cliente HTTP: `dependency failed to start: container f06-inventory-1 is unhealthy`, porque la sonda
  falla con `exec: "wget": executable file not found in $PATH`.
- **Para salir:** en compose, una sonda con una herramienta que la imagen tenga, o reintentos en el
  cliente. En un cluster, reintentos en el cliente y una readiness que el kubelet comprueba desde
  afuera. La parte del cliente no la resuelve ninguna plataforma: **un servicio que no tolera que su
  vecino no esté, falla en compose y falla en Kubernetes.**

---

## ⚰️ 9. Autopsia: `restart: always` como alta disponibilidad

**La decisión, con su mejor argumento.** Un servicio en una máquina, con `restart: always` y un
`healthcheck`: *"si se cae, se levanta solo, y la sonda me avisa si algo anda mal."* Es lo que se
escribe en la mitad de los `compose.yaml` que corren en un servidor.

**Por qué era razonable.** Cubre el fallo más común que uno imagina, que el proceso muera, y cubre
también el reinicio de la máquina. Y la columna `STATUS` dice `(unhealthy)` cuando algo anda mal,
así que parece que hay alguien mirando.

**Qué pasa después, con número.** Lo que esta fase midió: un `replenish` enfermo estuvo veinticinco
segundos `unhealthy` con `RestartCount=0`, y habría seguido así indefinidamente; uno detenido con
`docker kill` no volvió; uno borrado no volvió. **La política vigila que el proceso exista, no que
sirva.** La Vecina conoce esa diferencia en su versión cara: la regla de Contingencia era *"se prende
cuando el Siga no contesta"*, y el 14 de octubre el Siga contestaba, solo que tarde. Las 263 cajas
estuvieron congeladas tres horas y cuarenta minutos, y Contingencia no se prendió en ningún sitio
(historia §1.14). Una regla que mira "vivo" en vez de "sirve" falla exactamente cuando más hace falta.

**Cuánto cuesta salir, con número.** En compose, no hay salida completa: hace falta algo afuera que
mire la sonda y actúe (un script, un supervisor), y ese algo es un orquestador hecho a mano. En
Kubernetes son dos campos: una `livenessProbe` que reinicia lo que no responde, y una
`readinessProbe` que le quita tráfico a lo que no puede atender ([Fase 15](15-salud-y-recursos.md)), más el `Deployment` que
reemplaza lo que desaparece ([Fase 08](08-el-primer-despliegue.md)).

**Qué lo habría cambiado.** La pregunta *¿qué observa esta regla: que el proceso exista, o que
pueda atender?*, hecha antes de confiarle la disponibilidad.

**Antes y después, con números:** con `restart: always`, un servicio enfermo siguió enfermo 25
segundos con 0 reinicios, y uno borrado no volvió; con un `Deployment` y sus sondas, el enfermo se
reinicia y el borrado se reemplaza, y la [Fase 15](15-salud-y-recursos.md) lo mide.

---

## 📖 10. Traducción

La tabla corta; el diccionario completo, en las dos direcciones, está en
[a05](a05-diccionarios.md#-compose--kubernetes):

| En compose | En Kubernetes | Lo que cambia |
|---|---|---|
| un servicio | `Deployment` + `Service` | lo que corre y el nombre que lo encuentra son dos objetos |
| `depends_on:` | *sin equivalente* | nadie espera; cada servicio tolera, y la readiness decide el tráfico |
| `healthcheck:` | `livenessProbe` · `readinessProbe` | la sonda la hace el kubelet desde afuera |
| `restart: always` | el controlador del `Deployment` | no reinicia: reemplaza hasta tener lo pedido |
| `--scale` | `replicas:` + `Service` | una dirección estable delante de las réplicas listas |
| la red del proyecto | `Service` y DNS del cluster | el nombre lleva namespace |
| un volumen con nombre | `PersistentVolumeClaim` | el disco lo pide el pod y lo da el cluster |
| `network_mode: service:x` | dos contenedores en un pod | la excepción de compose es la unidad de Kubernetes |
| *sin equivalente* | `Namespace`, `ServiceAccount`, RBAC, el planificador, el bucle | lo que compose no tiene, porque corre en una máquina para una persona |

**Lo que no tiene traducción** tiene fase: `Namespace` en la 09, el planificador en la 07 y la 16,
`ServiceAccount` y RBAC en la 20, y el bucle de reconciliación en todas desde la 08.

🌩️ En un cluster gestionado, el bucle es el mismo y el proveedor administra el plano de control: la
API y los controladores que en kind corren en tu portátil. 🚧 Lo que kind no puede darte es lo que
el bucle hace cuando un nodo físico desaparece: aquí todos los nodos son contenedores en la misma
máquina.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Compose gana, y con número.** Los cinco servicios de G0 en compose ocupan 446 MiB y pasan su suite
nueve segundos después de `up` (B-00, en [a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)).
Solo el plano de control de un cluster `minimo` vacío —sin un servicio desplegado— ocupa 913 MiB, el
doble, y crearlo cuesta 25,8 segundos (B-05). Para un sistema que corre en una máquina, que atiende
una persona y que se puede caer un rato sin que nadie pierda plata, compose es la herramienta
correcta, y Kubernetes es un costo sin retorno.

**Cuándo el cluster empieza a pagar:** cuando hace falta que alguien reemplace lo que muere sin que
una persona corra un comando; cuando las réplicas tienen que repartirse en más de una máquina; cuando
varios equipos despliegan en el mismo sitio y necesitan nombres, permisos y cuotas separados. Si
ninguna de las tres te pasa, la respuesta honesta para tu sistema puede ser "compose y una alerta".

**Y compose como producción, la exclusión de esta fase:** no lo es, por las cinco secciones de arriba
juntas. Se usa, en servidores sueltos, y funciona hasta el día en que hace falta una de las tres
cosas del párrafo anterior.

**La pregunta del curso, para esta fase:** el contenedor te dio el proceso aislado y la imagen. El
orquestador, a partir de la [Fase 08](08-el-primer-despliegue.md), te va a dar el bucle: reemplazar, esperar a lo listo, repartir,
nombrar. **Te sigue tocando a ti** que cada servicio tolere a sus vecinos ausentes: eso ningún
bucle lo arregla.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`dependency failed to start: container … is unhealthy` con el servicio funcionando.** Causa: la
herramienta de la sonda no existe en la imagen. Comprobación 🩺: `docker inspect <contenedor> --format
'{{json .State.Health.Log}}'`. Salida: una sonda con lo que la imagen trae, o aceptar que en compose
ese servicio no tiene sonda.

**`restart: always` no reinicia después de `docker stop` o `docker kill`.** Es a propósito: una
detención manual suspende la política hasta que el motor reinicie o hasta el próximo `up`.

**Un servicio no resuelve a otro de un proyecto vecino.** Síntoma: `bad address`. Causa: los nombres
de compose solo existen dentro de la red de cada proyecto. Salida: una red compartida declarada como
`external`, o, mejor, no depender de otro proyecto.

**`port is already allocated` al escalar.** Causa: varias réplicas no pueden publicar el mismo puerto
del host. Salida: no publicar en las réplicas, y poner un proxy delante; o esperar al `Gateway` de
la [Fase 10](10-la-entrada-al-sistema.md).

---

## 📋 14. Checklist de validación

```text
[ ] depends_on sin condición: Connection refused, tres de tres
[ ] el healthcheck de inventory falla porque la imagen no tiene wget, y sabes por qué pricing no puede tener uno
[ ] replenish unhealthy con RestartCount=0; muerto desde afuera, RestartCount=1; borrado, no vuelve
[ ] nslookup de pricing desde la red del proyecto, y bad address desde otra red
[ ] --scale pricing=3: tu tabla de reparto con conexión reutilizada y con conexión nueva
[ ] docker kill de pricing: Exited hasta el próximo up -d
[ ] podman kube play de un Deployment de dos réplicas: un pod, con su contenedor infra, que nadie reemplaza
[ ] sabes traducir el compose.yaml del laboratorio con a05
```

---

## 🧪 15. Ejercicios (24)

La mitad son de diagnóstico: cada uno pone a compose en una situación donde el instinto dice una
cosa y el laboratorio otra. Escribe la predicción antes de cada 🟠 y 🔴.

## 🟢 Fácil — ver fallar (1–7)

### 🟢 Ejercicio 1 — `depends_on`, tres veces
Corre `f06-depende.yaml` tres veces.

**Criterio:** tres `Connection refused` literales.

<details><summary>Solución</summary>

`docker compose -f f06-depende.yaml up caja` y `docker compose -f f06-depende.yaml down` entre una y
otra. Crea el archivo con el contenido de la sección 4, fuera de `src/lab/`.
</details>

### 🟢 Ejercicio 2 — La sonda sin herramienta
Muestra por qué falla el `healthcheck` de `inventory`.

**Criterio:** la línea de `State.Health.Log` con `executable file not found`.

<details><summary>Solución</summary>

`docker compose -f f06-sana.yaml up caja`, y `docker inspect f06-inventory-1 --format '{{json
.State.Health.Log}}'`.
</details>

### 🟢 Ejercicio 3 — Enfermo y en paz
Levanta `f06-restart.yaml` y espera treinta segundos.

**Criterio:** `(unhealthy)` en `ps` y `RestartCount=0`.

<details><summary>Solución</summary>

`docker compose -f f06-restart.yaml up -d`, y a los treinta segundos los dos comandos de 5.2.
</details>

### 🟢 Ejercicio 4 — El servidor de nombres
Encuentra qué servidor DNS usa un contenedor de la red `lab_default`.

**Criterio:** `127.0.0.11`, leído de `/etc/resolv.conf` del contenedor.

<details><summary>Solución</summary>

`docker run --rm --network lab_default lab/replenish cat /etc/resolv.conf`.
</details>

### 🟢 Ejercicio 5 — Tres direcciones
Escala `inventory` a dos réplicas y resuelve su nombre.

**Criterio:** `nslookup inventory` devuelve dos direcciones.

<details><summary>Solución</summary>

`docker compose -f compose/compose.yaml up -d --scale inventory=2 inventory` y el `nslookup` de 5.4.
Vuelve a una con `--scale inventory=1`.
</details>

### 🟢 Ejercicio 6 — El bucle eres tú
Mata `catalog` con `docker kill` y devuélvelo con compose.

**Criterio:** `Exited (137)` y, después de `up -d`, `Up`.

<details><summary>Solución</summary>

`docker kill lab-catalog-1`, `docker compose -f compose/compose.yaml ps -a catalog` y `docker compose
-f compose/compose.yaml up -d`. Mira qué le pasa a `catalog-nginx` mientras tanto.
</details>

### 🟢 Ejercicio 7 — El diccionario
Traduce con [a05](a05-diccionarios.md) el servicio `contingencia` del `compose.yaml` del laboratorio.

**Criterio:** la lista de objetos de Kubernetes que lo reemplazarían, con la fase de cada uno.

<details><summary>Solución</summary>

Un `Deployment` y un `Service` (08), un `Secret` para las credenciales (11), un `PersistentVolumeClaim`
para la carpeta de traslados (12), y nada para `depends_on`: Contingencia tiene que tolerar que su
base no esté (15). La [Fase 10](10-la-entrada-al-sistema.md) lo mete al cluster de verdad.
</details>

## 🟡 Intermedio — medir lo que compose hace (8–14)

### 🟡 Ejercicio 8 — Tu tabla de reparto
Repite el experimento de la sección 7, tres corridas de cada cliente.

**Criterio:** tu tabla con lo que recibió cada réplica.

<details><summary>Solución</summary>

Los dos `docker run` de la sección 7 entre `up -d --force-recreate --scale pricing=3 pricing`, y
`docker compose -f compose/compose.yaml logs pricing | grep "GET /prices/SKU-0003" | awk '{print $1}'
| sort | uniq -c`.
</details>

### 🟡 Ejercicio 9 — Una sonda que sí corre
Dale a `catalog` un `healthcheck` con una herramienta que su imagen tenga, y comprueba que queda
`(healthy)`.

**Criterio:** `(healthy)` en `ps`, y la herramienta elegida.

<details><summary>Solución</summary>

La imagen de FPM tiene `wget` y `curl`, pero FPM no habla HTTP: la sonda tiene que pasar por nginx,
en `http://localhost:8080/health/live`, porque comparten la red. No lo dejes en el archivo: la [Fase 15](15-salud-y-recursos.md)
decide.
</details>

### 🟡 Ejercicio 10 — Muerto de verdad
Mata el proceso de `pricing` desde la máquina virtual, con `restart: always` en una copia del servicio,
y mira cuántas veces vuelve.

**Criterio:** `RestartCount` sube con cada `kill -9`.

<details><summary>Solución</summary>

El `docker run --rm --pid=host --privileged lab/replenish kill -9 <pid>` de 5.2, con el `pid` de
`docker inspect … --format '{{.State.Pid}}'`.
</details>

### 🟡 Ejercicio 11 — El volumen en la máquina
Encuentra los archivos de un volumen con nombre, entrando a la máquina virtual del motor.

**Criterio:** `ls` del `Mountpoint` desde un contenedor que monte la raíz de la máquina, o desde
`podman machine ssh`.

<details><summary>Solución</summary>

Con Podman, `podman machine ssh -- ls <Mountpoint>`. Con Docker Desktop, un contenedor con `-v
/var/lib/docker/volumes:/vols:ro` y `ls /vols/<volumen>/_data`.
</details>

### 🟡 Ejercicio 12 — El pod en compose
Muestra que `catalog` y `catalog-nginx` tienen la misma dirección IP.

**Criterio:** `hostname -i` (o `ip addr`) igual en los dos.

<details><summary>Solución</summary>

`docker exec lab-catalog-1 hostname -i` y `docker exec lab-catalog-nginx-1 hostname -i`. Es un solo
namespace de red, como un pod.
</details>

### 🟡 Ejercicio 13 — `kube play` con `inventory`
Corre un `Deployment` de `inventory` con `podman kube play`, con tres réplicas.

**Criterio:** `podman pod ps` muestra cuántos pods creó, y `curl` contesta.

<details><summary>Solución</summary>

El manifiesto de 5.7 con `inventory` y `replicas: 3`. Podman crea uno. Bórralo con `podman kube down`.
</details>

### 🟡 Ejercicio 14 — Otro proyecto, otro mundo
Levanta un segundo proyecto de compose con un servicio que intente llamar a `pricing`.

**Criterio:** `bad address` desde el segundo proyecto, y una frase sobre qué tendrías que declarar
para que lo encontrara.

<details><summary>Solución</summary>

Una red `external: true` compartida por los dos proyectos. Es lo que en un cluster no hace falta: el
DNS es de todo el cluster.
</details>

## 🟠 Difícil — predecir y explicar (15–20)

### 🟠 Ejercicio 15 — ¿Por qué dos y no tres?
Explica por qué, con conexión reutilizada, el tráfico se repartió entre dos réplicas y no entre tres.
**Predice** qué pasa con 30 peticiones en paralelo en vez de 300 en serie.

**Criterio:** la predicción, y la tabla con peticiones en paralelo (`Promise.all`).

**Rúbrica:** la predicción; la tabla; y una explicación de cuántas conexiones abre el cliente en
cada caso y cómo elige dirección para cada una.

### 🟠 Ejercicio 16 — La caja que reintenta
Cambia la caja de la sección 4 para que reintente durante treinta segundos antes de rendirse, sin
`healthcheck` en `inventory`.

**Criterio:** la caja obtiene la existencia en las tres corridas, y sabes cuántos intentos hizo.

**Rúbrica:** el comando; la evidencia; y por qué esto funciona igual en un cluster, donde no hay
`depends_on`.

### 🟠 Ejercicio 17 — FPM muere, nginx no
Mata el proceso de FPM de `catalog` desde la máquina virtual, sin política de reinicio. **Predice**
qué ve la suite G0.

**Criterio:** la predicción, el estado de los dos contenedores, y la salida de `task conformance --
G0`.

**Rúbrica:** `catalog` `Exited` y `catalog-nginx` `Up`; la suite fallando en `catalog.g0.hurl` con
502; y por qué en un pod el kubelet vería un contenedor muerto y lo reiniciaría ([Fase 09](09-los-cuatro-servicios-dentro.md)).

### 🟠 Ejercicio 18 — Lo que `kube play` ignora
Lista qué campos del manifiesto de 5.7 respetó Podman y cuáles no.

**Criterio:** una tabla con los campos y lo que hizo Podman con cada uno.

**Rúbrica:** `replicas` (ignorado: un pod), `selector` (sin efecto: nadie selecciona), `image` y
`ports` (respetados); y la conclusión: Podman lee el formato, no el contrato de un `Deployment`.

### 🟠 Ejercicio 19 — Compose, reconciliado por un cron
Escribe un script que corra `docker compose up -d` cada minuto, y mide cuánto tarda en volver un
`pricing` muerto.

**Criterio:** cinco mediciones del tiempo hasta `Up`.

**Rúbrica:** el script; la tabla; y por qué esto es un orquestador hecho a mano al que le falta casi
todo: no mira la salud, no reparte, no sabe de otras máquinas.

### 🟠 Ejercicio 20 — El costo del cluster, en tu máquina
Compara lo que ocupa el sistema G0 en compose con lo que ocupa un cluster `minimo` vacío, con
`task measure -- B-00`.

**Criterio:** los dos números de tu máquina, con su comando.

**Rúbrica:** los números; la proporción contra la publicada en esta fase; y una frase sobre para qué
sistema de tu trabajo pagarías esa diferencia y para cuál no.

## 🔴 Muy difícil — el instinto contra el laboratorio (21–24)

### 🔴 Ejercicio 21 — Un balanceador en compose
Pon un proxy delante de tres réplicas de `pricing` en compose (nginx o el que prefieras) y repite la
medición de la sección 7 con conexión reutilizada.

**Criterio:** la tabla de reparto a través del proxy, con las tres réplicas recibiendo tráfico.

**Rúbrica:** el `compose.yaml`; la tabla; qué hace el proxy cuando una réplica muere (prueba
matándola); y cuánto de un `Service` y un `Deployment` acabas de escribir a mano.

### 🔴 Ejercicio 22 — La regla de Contingencia
Escribe en compose una regla que encienda un "Contingencia" (cualquier servicio de respaldo) cuando
`pricing` no contesta, y rómpela haciendo que `pricing` conteste lento.

**Criterio:** con `pricing` detenido, el respaldo se enciende; con `pricing` contestando en cinco
segundos, no.

**Rúbrica:** la regla; las dos pruebas; y la relación con el 14 de octubre de la historia: qué
tendría que observar la regla para encenderse cuando el servicio contesta tarde.

### 🔴 Ejercicio 23 — Un `compose.yaml` de tu trabajo
Traduce un `compose.yaml` real de tu trabajo con [a05](a05-diccionarios.md), y marca lo que no tiene
traducción.

**Criterio:** la lista de objetos, y las líneas de tu archivo que no tienen equivalente o que lo
tienen con otro comportamiento.

**Rúbrica:** la traducción; al menos un `depends_on`, un volumen y un puerto publicado tratados con
su fila; y una decisión honesta: ¿ese sistema necesita un cluster?

### 🔴 Ejercicio 24 — La respuesta a Luz Marina
Escribe, en media página y con números de esta fase, la respuesta a *"¿qué promete ese cluster que no
prometía el nuestro?"*.

**Criterio:** media página, con al menos tres números de esta fase.

**Rúbrica:** el bucle de reconciliación explicado sin jerga; lo que el cluster del Siga sí hacía
(réplicas y balanceador) y lo que no (reemplazar, esperar lo listo); lo que compose gana; y ninguna
promesa que esta fase no haya medido.

---

## 📚 16. Referencias

**Documentación oficial** (Kubernetes, la de la versión 1.36 de [a01](a01-el-laboratorio.md))

- Kubernetes, *Controllers*: https://kubernetes.io/docs/concepts/architecture/controller/ — el bucle
  de reconciliación, en una página.
- Kubernetes, *Deployments*: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Kubernetes, *DNS for Services and Pods*: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
- Docker, *Control startup order in Compose*: https://docs.docker.com/compose/how-tos/startup-order/
- Docker, *Start containers automatically*: https://docs.docker.com/engine/containers/start-containers-automatically/
  — por qué una detención manual suspende la política.
- Podman, `podman kube play`: https://docs.podman.io/en/latest/markdown/podman-kube-play.1.html — qué
  objetos y campos soporta.

**Libros**

- Brendan Burns, Joe Beda, Kelsey Hightower y Lachlan Evenson, *Kubernetes: Up and Running*, 3.ª
  edición (2022), el capítulo introductorio sobre la configuración declarativa y los sistemas que se
  reparan solos.
- Marko Lukša y Kevin Conner, *Kubernetes in Action*, 2.ª edición (2026), la parte sobre cómo
  funcionan los controladores.

**Orden de lectura sugerido:** antes, nada; durante, la página de controladores (diez minutos);
después, el capítulo de *Kubernetes: Up and Running*, que cuenta por qué el modelo declarativo es la
idea central.

> ⚠️ Las URL y los contenidos cambian; las de Kubernetes tienen versión en el selector de la página,
> y las de Docker y Podman no fijan versión.

---

## 🏁 17. Resultado de la fase

```text
LO QUE COMPOSE NO TE DA, Y QUIÉN LO DA DESDE LA FASE 07

  promesa del instinto        lo que pasó en compose                     lo que lo da
  ─────────────────────       ────────────────────────────────────       ─────────────────────────
  depends_on espera           Connection refused, 3 de 3                 nadie espera · readiness (F15)
  restart cura                unhealthy 25 s, 0 reinicios; borrado: nada  Deployment (F08) · liveness (F15)
  el nombre es el DNS         bad address desde otra red                 Service y DNS del cluster (F08, F09)
  scale balancea              1 réplica sin tráfico, 4 de 4              Service (F08) · gRPC (F23)
  el volumen es mío           vive en la VM del motor                    PVC y StorageClass (F12)
  up -d reconcilia            solo cuando lo corres                      el bucle de reconciliación (F08)
```

El sistema sigue en compose, igual que al cerrar la [Fase 04](04-empaquetar-los-cuatro-runtimes.md): esta fase no cambió ningún archivo de
`src/lab/`. Los experimentos viven fuera del repositorio.

> **La señal de que quedó bien:** *"Puedo decir, con un experimento, qué garantía me da compose y cuál
> no, y qué objeto de Kubernetes la da."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-06-del-compose-al-cluster -m "F06 cerrada: depends_on, restart, DNS, scale y volúmenes probados en compose; el bucle de reconciliación; podman kube play; el diccionario compose-Kubernetes en a05"
> ```
>
> Commits de la fase con prefijo `f06:`, los de ejercicio `f06 ej21: …` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F08:** mostrar el bucle en vivo borrando un pod de `pricing`, y citar la tabla de la sección 17
  como el "antes".
- **F23:** la tabla de reparto con conexión reutilizada de la sección 7 es el antecedente directo de
  B-23.
