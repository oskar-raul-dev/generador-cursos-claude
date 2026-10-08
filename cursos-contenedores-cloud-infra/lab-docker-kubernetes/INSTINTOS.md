# 🪞 INSTINTOS
## Laboratorio de contenedores y Kubernetes local

La versión consultable de todas las secciones 🪞 del curso: los reflejos que trae alguien que ya
corre contenedores con compose —y antes, máquinas virtuales— y que en un orquestador producen un
sistema que **arranca, responde y está mal**. Es uno de los tres documentos vivos: **nace vacío y
crece con las fases**, una entrada como mínimo por fase.

Se organiza **por familia y no por número de fase**, porque se consulta buscando un reflejo: algo se
comportó distinto de lo que esperabas, lo buscas aquí, y la entrada te dice qué lo prueba y dónde
está desarrollado.

> 🧭 **Cada entrada explica por qué el instinto existía y dónde sigue siendo correcto.** Un reflejo que
> se ridiculiza no se desaprende: se esconde. Casi todos los de esta lista son buenos hábitos de
> compose o de la máquina virtual aplicados a una plataforma donde la garantía que los sostenía ya
> no está.

> 📝 **Este archivo crece con el curso**, con una entrada por fase como mínimo. La primera es de la
> [Fase 03](03-el-contenedor-por-dentro.md).

**Salto rápido:** [La forma de una entrada](#-la-forma-de-una-entrada) · [De compose](#-de-compose) · [De la máquina virtual](#️-de-la-máquina-virtual) · [De la operación](#-de-la-operación) · [Del código distribuido](#-del-código-distribuido)

---

## 🧾 La forma de una entrada

Siempre la misma, para que se lean igual aunque las separen veinte fases:

````markdown
### "El reflejo, en las palabras en que se te ocurre"

**De dónde viene:** dónde era correcto, y por qué lo aprendiste.
**La apuesta:** lo que predijo la fase antes de ejecutar, copiado tal cual.
**Lo que pasó:** la prueba en el laboratorio, con la salida literal o el número (y su `B-NN` si hubo
medición). Ganada, perdida o empate.
**Lo que se hace en su lugar:** la alternativa, corta.
**Dónde sigue valiendo:** la columna que hace útil este archivo.
**Desarrollado en:** la fase.
````

Una apuesta perdida se copia aquí igual que una ganada, y con la misma prominencia. Que el instinto
del lector haya acertado también es información: es la prueba de que no todo lo de compose se tira.

---

## 🐳 De compose

Los reflejos de quien levanta su sistema con un archivo y un comando: el nombre del servicio como
dirección, el reinicio como remedio, la configuración horneada, el volumen que siempre está.

### "La imagen pesada es la lenta, en la misma proporción"

**De dónde viene:** con `build:` en el compose, la imagen nunca sale de tu máquina y su tamaño solo
se nota como espacio en disco; si algo es lento, el sospechoso natural es lo que más pesa.
**La apuesta:** Con el multi-stage definitivo, la imagen de `pricing` queda por debajo de 20 MB y la
de `inventory` por encima de 200 MB: más de diez veces. En build en frío, `inventory` tarda más de
cinco veces lo que `pricing`. Con caché y un cambio solo en el código, los cuatro backends bajan a
menos de un cuarto de su build en frío. Hasta el primer 200, `pricing` contesta en menos de medio
segundo e `inventory` en más de dos: más de veinte veces.
**Lo que pasó:** ganada en tamaño y en build en frío, perdida en lo demás (B-04). `inventory` pesa 45
veces más y tarda 15 veces más en frío, pero con un cambio de código reconstruye en 2,7 s (el 3 % de
su frío), mientras `pricing`, la imagen más chica, tarda 5,6 s (el 97 %). Y `inventory` arranca en
1,16 s: siete veces `pricing`.
**Lo que se hace en su lugar:** medir cada eje por separado; ordenar el Dockerfile para que lo que
cambia quede al final; y no usar el tamaño como proxy del arranque.
**Dónde sigue valiendo:** en lo que viaja: el tamaño sí predice cuánto se descarga en cada nodo y
cuánto tarda el build en frío.
**Desarrollado en:** [Fase 04](04-empaquetar-los-cuatro-runtimes.md), §7 y §8.

### "Podman es Docker sin demonio: con la misma memoria, cuesta lo mismo"

**De dónde viene:** los comandos son casi idénticos, las imágenes son las mismas, y compose levanta
el mismo archivo con los dos. Para lo que corre dentro del contenedor, es correcto.
**La apuesta:** Con las dos máquinas virtuales en 4 GiB, los dos motores empatan en memoria en
reposo (dentro de la dispersión); Podman crea el cluster `minimo` más de un 20 % más lento que
Docker; y el build en frío de `pricing` queda dentro de un 15 % entre los dos.
**Lo que pasó:** perdida en las tres (B-05). Recién arrancados, los procesos de Docker Desktop
alrededor de la máquina virtual suman 3.184 MB contra 38 de Podman; el cluster tarda un 12 % más con
Podman, y el build de `pricing`, más del doble. Y hay plomería que no es igual: kind no ve las
imágenes de Podman (`not present locally`), y Podman no publica el puerto 80 en macOS.
**Lo que se hace en su lugar:** un motor a la vez, `task images:load` para llevar imágenes al cluster,
puertos 8080 y 8443, y medir antes de elegir.
**Dónde sigue valiendo:** dentro del contenedor: el proceso, la imagen y el formato son los mismos.
**Desarrollado en:** [Fase 05](05-los-dos-motores.md), §5, §7 y §8.

### "`--scale` me da réplicas, y el nombre del servicio las reparte"

**De dónde viene:** el DNS de compose devuelve todas las direcciones de un servicio escalado, y con
herramientas como `wget`, que abren una conexión por petición, el reparto se ve parejo.
**La apuesta:** Con `--scale pricing=3` y 300 peticiones desde un cliente que reutiliza la conexión,
una sola réplica atiende más del 90 %; abriendo una conexión nueva por petición, cada réplica atiende
entre el 25 % y el 42 %.
**Lo que pasó:** perdida la primera mitad, ganada la segunda. Con `fetch` de Node (conexiones
reutilizadas), cuatro corridas: tres repartieron 150 y 150 entre dos réplicas y una mandó 300 a una
sola; **en las cuatro, al menos una réplica no recibió nada**. Con `wget`, del 29 % al 37 % por
réplica.
**Lo que se hace en su lugar:** una dirección estable delante de las réplicas listas (un `Service`
desde la [Fase 08](08-el-primer-despliegue.md)) y, cuando la conexión es larga, balancear por petición ([Fase 23](23-grpc-y-el-balanceo.md)).
**Dónde sigue valiendo:** con clientes que abren una conexión por petición, el DNS reparte razonable.
**Desarrollado en:** [Fase 06](06-del-compose-al-cluster.md), §5.4 y §7.

### "`restart: always` y un `healthcheck`: si algo anda mal, se arregla solo"

**De dónde viene:** cubre el fallo más común, que el proceso muera, y la columna `STATUS` dice
`(unhealthy)` cuando algo anda mal.
**La apuesta:** la [Fase 06](06-del-compose-al-cluster.md) no apostó sobre esto; lo midió directamente.
**Lo que pasó:** un `replenish` con la sonda fallando estuvo 25 s `(unhealthy)` con `RestartCount=0`;
detenido con `docker kill`, no volvió; borrado, no volvió. Solo un proceso muerto desde afuera se
reinició (`RestartCount=1`). La política vigila que el proceso exista, no que sirva.
**Lo que se hace en su lugar:** un `Deployment` que reemplaza hasta tener lo pedido, y sondas que el
kubelet comprueba desde afuera (Fases 08 y 15).
**Dónde sigue valiendo:** para reponerse de un proceso que muere en una máquina sola, alcanza.
**Desarrollado en:** [Fase 06](06-del-compose-al-cluster.md), §5.2 y §9.

### "Si borro el contenedor, se fue"

**De dónde viene:** en compose, un contenedor borrado o muerto se queda así hasta el próximo `up`.
**La apuesta:** Borrando el pod de `pricing`, el `Deployment` tiene un pod nuevo en `Running` en menos
de 5 segundos, cinco veces de cinco.
**Lo que pasó:** ganada: 0,49 a 0,57 segundos, cinco de cinco. Con trampa: "listo" es trivial en G0, y
con un servicio que tarda en abrir el puerto, ese medio segundo miente ([Fase 15](15-salud-y-recursos.md)).
**Lo que se hace en su lugar:** un `Deployment` y nunca un pod suelto; borrar un pod es pedir otro.
**Dónde sigue valiendo:** para un pod suelto (`kubectl run`), que nadie reemplaza.
**Desarrollado en:** [Fase 08](08-el-primer-despliegue.md), §5.3, §7 y §9.

### "Los datos viven lo que vive el contenedor"

**De dónde viene:** en compose, la capa escribible se va con el contenedor y el volumen se queda.
**La apuesta:** Matar solo el contenedor `php-fpm` del pod de `catalog` no borra el catálogo (el
`emptyDir` vive lo que vive el pod); borrar el pod, sí: el pod nuevo arranca con el catálogo vacío.
**Lo que pasó:** ganada: con el contenedor reiniciado (`RESTARTS 1`), el producto siguió; con el pod
borrado, `[]`.
**Lo que se hace en su lugar:** saber qué dura cuánto: el contenedor, el pod (`emptyDir`) o el cluster
(un `PersistentVolumeClaim`, [Fase 12](12-estado-y-almacenamiento.md)).
**Dónde sigue valiendo:** para la capa escribible del contenedor, igual que en compose.
**Desarrollado en:** [Fase 09](09-los-cuatro-servicios-dentro.md), §5.2 y §7.

### "Para exponer un servicio, publico su puerto"

**De dónde viene:** en compose, `ports:` en cada servicio que se mira desde afuera, y en un servidor,
un puerto abierto en el firewall por aplicación. Funciona, y en un cluster tiene su equivalente
directo: un `NodePort` o un `LoadBalancer` por servicio.
**La apuesta:** Con la `HTTPRoute` de precios repartida 80/20 entre Contingencia y `pricing`, de 200
peticiones `pricing` recibe entre el 15 % y el 25 %.
**Lo que pasó:** ganada, con exactitud: tres corridas de 200, Contingencia 160 y `pricing` 40 las
tres; con 50/50, 101 y 99; con 100/0, 200 a `pricing`. Ningún puerto por servicio permite ese reparto:
lo hace una puerta compartida que mira nombre, ruta y peso. Y el `LoadBalancer` por servicio, en kind
con cloud-provider-kind, recibió una IP que no llegó al host (`Connection timed out after 8003
milliseconds`).
**Lo que se hace en su lugar:** una `Gateway` de plataforma y una `HTTPRoute` por equipo; la pregunta
deja de ser "qué puerto" y pasa a ser "qué nombre, qué ruta y qué peso".
**Dónde sigue valiendo:** con un solo servicio que mirar desde afuera, y para lo que no es HTTP (una
base que un cliente externo tiene que alcanzar).
**Desarrollado en:** [Fase 10](10-la-entrada-al-sistema.md), §4, §6.1 y §7.

### "Cambio la configuración y el servicio la toma"

**De dónde viene:** en compose, cambiar el `.env` o el `environment:` y correr `up -d` recrea el
contenedor: cambiar y reiniciar son el mismo gesto, y uno deja de distinguirlos.
**La apuesta:** Después de cambiar la tabla de topes regulados en el `ConfigMap`, `pricing` sigue
respondiendo con el tope viejo al menos cinco minutos: el archivo montado se actualiza, pero `pricing`
lo leyó al arrancar.
**Lo que pasó:** ganada. El archivo montado cambió entre los 60 y los 90 segundos; `pricing` siguió
recortando a 20.000 los 393 segundos de la prueba, con el `ConfigMap` en 18.000. El reinicio aplicó el
tope nuevo y, de paso, borró los precios del `emptyDir`.
**Lo que se hace en su lugar:** cada cambio de configuración con su reinicio, y que lo haga una
herramienta: el hash del `ConfigMap` en la plantilla ([Fase 13](13-helm-el-paquete.md)). Y la configuración de una página web,
leída al arrancar el contenedor, no horneada al compilar.
**Dónde sigue valiendo:** en un proceso que relee su archivo cuando cambia (nginx con `reload`, por
ejemplo), y en compose.
**Desarrollado en:** [Fase 11](11-configuracion-y-secretos.md), §4, §5 y §7.

### "Para las pruebas, SQLite alcanza: SQL es SQL"

**De dónde viene:** en desarrollo, con compose o sin él, SQLite es un archivo, no un servicio: arranca
al instante, no pide credenciales, y las consultas sencillas se escriben igual en los dos motores.
**La apuesta:** La suite de pruebas contra Postgres con Testcontainers tarda más de diez veces lo que
contra SQLite, y hay al menos un comportamiento (una restricción o un tipo) que SQLite acepta y
Postgres rechaza.
**Lo que pasó:** perdida en el tiempo, ganada en la fidelidad. La tarea que corre una persona tardó
2,3 veces (12,70 s contra 5,45 s; el binario de pruebas, 59 veces), y la prueba de un precio de
3.000.000.000 pasó en SQLite y falló en Postgres (`greater than maximum value for int4`). B-12.
**Lo que se hace en su lugar:** las pruebas del almacén, contra el motor de producción, en un
contenedor que arranca la propia suite.
**Dónde sigue valiendo:** para lo que no toca SQL específico del motor, y cuando la diferencia de siete
segundos por corrida importa más que un error de tipo (casi nunca).
**Desarrollado en:** [Fase 12](12-estado-y-almacenamiento.md), §7.

---

### "Con un health check alcanza"

**De dónde viene:** en compose, el `healthcheck` era uno y era informativo: decía `(unhealthy)` y nadie
actuaba. En el Siga, la regla de Contingencia era una sola pregunta: *"¿el Siga contesta?"*. Con una
pregunta y sin consecuencias, una alcanza.
**La apuesta:** Un `rollout restart` de `inventory` con una petición cada 100 ms por la puerta: sin
sondas, más del 5 % de las peticiones fallan; con la readiness de G4, menos del 1 %.
**Lo que pasó:** perdida la primera mitad, ganada la segunda: sin sondas falló entre el 2,8 % y el 3,3 %
(un segundo y medio de corte por despliegue); con la readiness, 0, 1 y 0 peticiones. Y las dos preguntas
tienen consecuencias distintas: con Postgres apagado, la readiness sacó a los cuatro servicios del
tráfico sin reiniciar ninguno; con la máquina virtual ahogada, la liveness reinició a tres contenedores
sanos.
**Lo que se hace en su lugar:** una readiness que pregunta por lo que el servicio necesita para atender
(su base, y ningún vecino), una liveness que pregunta solo por el proceso y con paciencia, y una
`startupProbe` para el que arranca lento.
**Dónde sigue valiendo:** en un proceso sin balanceador delante, o en un `Job`: ahí no hay tráfico que
apartar, y una pregunta alcanza.
**Desarrollado en:** [Fase 15](15-salud-y-recursos.md), §5 y §7.

---

## 🖥️ De la máquina virtual

Los reflejos de quien piensa el contenedor como una máquina chica: el `-Xmx` fijo, el proceso que se
apaga cuando se apaga la máquina, el disco que es de uno, el puerto 80 que siempre se pudo abrir.

### "Un Kubernetes local es un Kubernetes local: elijo el que arranque más rápido"

**De dónde viene:** la API es la misma en todos, y para aprender parece que da igual cuál.
**La apuesta:** B-07 se midió sin apuesta escrita (error de método, declarado). La que sí se escribió
antes: k3d trae de serie un controlador de entrada (Traefik) y un balanceador propio. Creado con
Traefik apagado, su memoria en reposo baja más de 100 MiB respecto de los 681 MiB medidos en B-07, y
queda por debajo de kind (651 MiB).
**Lo que pasó:** ganada: 463 MiB sin Traefik. Y en B-07, cada herramienta trae otra versión de
Kubernetes, otros componentes y otra compatibilidad con Podman (solo kind pasó entero).
**Lo que se hace en su lugar:** comparar con lo mismo encima, y elegir por versión, por motor y por lo
que no trae.
**Dónde sigue valiendo:** para la API: los manifiestos aplican igual en todos.
**Desarrollado en:** [Fase 07](07-el-cluster-local.md), §6 a §8.

### "Le doy a la JVM la memoria que tenía el servidor"

**De dónde viene:** en un servidor de WebLogic, la JVM era la dueña de la máquina, y fijar el heap
(`-Xms4096m -Xmx4096m`) evitaba que creciera y se achicara bajo carga. El Siga corre así desde 2015.
**La apuesta:** Con `-Xmx4096m` y un límite de 512 MiB, `inventory` muere `OOMKilled` en menos de cinco
minutos de carga sostenida; con el mismo límite y la JVM dimensionándose sola, aguanta la misma carga
con el pico de memoria del contenedor por debajo del 80 % del límite.
**Lo que pasó:** perdida la primera mitad, ganada la segunda. Con solo `-Xmx4096m` no murió: estuvo
entre 222 y 243 MiB cinco minutos. Lo que la mató fue el `-Xms4096m`: una generación joven de 1,4 GB que
la carga llena en segundos; `OOMKilled` a los 11 s, cinco veces en cinco minutos, sin una línea de error
en el log. Sin opciones, la JVM eligió 128 MiB de heap máximo, y el contenedor quedó entre 191 y 296 MiB
(el 58 % del límite) con cero fallos.
**Lo que se hace en su lugar:** el límite del contenedor manda, la JVM calcula su heap contra él
(`MaxRAMPercentage`, nunca `-Xms` ni `-Xmx` copiados), y el límite deja lugar a lo que no es heap: en
`inventory`, tres veces el heap.
**Dónde sigue valiendo:** en una máquina virtual donde la JVM es el único proceso, y fijar el heap sigue
siendo una buena afinación.
**Desarrollado en:** [Fase 15](15-salud-y-recursos.md), §7 y §9.

### "`docker stop` apaga el contenedor como se apaga un servidor"

**De dónde viene:** en una máquina virtual, un sistema de arranque (systemd, el servicio de Windows,
el script de WebLogic) recibe el aviso de apagado y se lo reparte a cada proceso; si alguno se
cuelga, al rato se corta la luz. Es correcto ahí, y lo aprendiste apagando servidores.
**La apuesta:** `inventory` (la JVM instala su manejador de `SIGTERM`) sale en menos de un segundo
con 143. `pricing` (Go como PID 1) también sale enseguida, pero con código 2: el runtime de Go muere
ante la señal sin apagado limpio. `replenish`, `catalog` y `storefront` agotan los diez segundos y
mueren con 137, porque Node y el `sh -c` como PID 1 no atienden la señal.
**Lo que pasó:** perdida en dos de cinco. Con `docker stop -t 10`, tres corridas: `pricing`,
`inventory` y `storefront` salieron en 0,12–0,16 s con 143 (`pricing` muerto por la señal, sin
cerrar nada; `storefront` porque su proceso 1 es `npm exec`, que reenvía); `catalog` y `replenish`
agotaron el tiempo, 10,12–10,17 s, y murieron con 137. Y la misma JVM que cierra en 0,12 s tarda
10,14 s y muere con 137 si el `CMD` va en forma de texto o un `start.sh` la lanza sin `exec`.
**Lo que se hace en su lugar:** preguntar quién es el proceso 1 (`docker exec … ps`); `CMD` en forma
JSON; `exec` al final de cualquier script de arranque; `--init` como parche mientras el programa no
atienda `SIGTERM`.
**Dónde sigue valiendo:** dentro de un contenedor con un proceso 1 que reparte señales (`tini`, un
sistema de arranque de verdad), y en el nodo del cluster, que sí es una máquina.
**Desarrollado en:** [Fase 03](03-el-contenedor-por-dentro.md), §6 a §9; se cobra en la [Fase 16](16-escalado-y-rollout.md).

---

## 🩺 De la operación

Los reflejos de quien diagnostica mirando un servidor: los logs en un archivo, el certificado que se
renueva una vez al año, el tablero que se arma cuando algo se cae, la red interna en la que todos
confían en todos.

### "El próximo `apply` devuelve todo a lo que dice el repositorio"

**De dónde viene:** con `kubectl apply`, era cierto. El perfil escalado a mano volvía a una réplica en
el siguiente despliegue, y `task inc:fix` reparaba los incidentes aplicando los manifiestos. El
repositorio mandaba, y lo que alguien hacía a mano se borraba sin preguntar.
**La apuesta:** Cambio la imagen de `pricing` a mano (`kubectl set image`, el incidente 05) y corro
`task deploy -- minimo` con los mismos valores. Apuesta: **no** la devuelve como hacía `kubectl apply`:
falla con un conflicto de server-side apply, porque `kubectl set image` se quedó con la propiedad del
campo.
**Lo que pasó:** ganada. `Error: UPGRADE FAILED: conflict occurred while applying object apps/pricing
apps/v1, Kind=Deployment: Apply failed with 1 conflict: conflict with "kubectl-set" using apps/v1:
.spec.template.spec.containers[name="pricing"].image`, y la imagen siguió siendo la puesta a mano. Helm 4
aplica del lado del servidor: cada campo tiene dueño (`managedFields`), y no pisa el de otro sin
`--force-conflicts`. Peor: donde Helm y `kubectl` habían escrito el mismo valor, quedaron dueños
compartidos, y el conflicto apareció el día en que el valor cambió, con el upgrade a medias.
**Lo que se hace en su lugar:** antes de forzar, mirar quién es el dueño
(`-o jsonpath='{.metadata.managedFields[*].manager}'`) y por qué tocó el campo; `task deploy FORCE=true`
cuando se decide devolverle el campo al chart; y mudar un sistema a Helm borrando y reinstalando, no
adoptando.
**Dónde sigue valiendo:** con `kubectl apply` del lado del cliente, y con Helm cuando nadie más escribe
en los objetos del release.
**Desarrollado en:** [Fase 13](13-helm-el-paquete.md), §7 y §9.

### "Si sale mal, `rollback` y quedo como estaba"

**De dónde viene:** en compose, volver atrás era `git revert` y `up -d`, y quedabas exactamente como
estabas, porque el estado era el del archivo.
**La apuesta:** Un `helm rollback` de un cambio de tope deja el precio viejo en menos de 30 s, sin tocar
nada a mano.
**Lo que pasó:** ganada, con letra chica. El rollback tardó 1,2 s y el tope volvió al instante. Pero el
precio volvió solo porque `pricing` aplica el tope al responder; las migraciones de una revisión que
falló quedaron aplicadas; el archivo de valores siguió diciendo 1.800; y con una imagen cambiada a mano,
el rollback automático falló por el mismo conflicto que el despliegue (`Rollback "lab" failed: conflict
occurred … conflict with "kubectl-set"`) y dejó el release en `failed`.
**Lo que se hace en su lugar:** el diff de tres vías antes (`task deploy:diff`), un esquema de valores, y
`--rollback-on-failure` al aplicar; el rollback a mano compra tiempo, y la corrección va al repositorio;
migraciones que la versión anterior del código tolere.
**Dónde sigue valiendo:** para la configuración y los objetos de Kubernetes, siempre que nadie más sea
dueño de sus campos.
**Desarrollado en:** [Fase 14](14-helm-en-operacion.md), §5 y §7.

### "El autoescalado me salva del pico"

**De dónde viene:** es la promesa de cualquier nube, y es cierta para la carga que sube a lo largo de
minutos. En compose, más réplicas eran un `--scale` a mano; tener a alguien que las agregue solo suena a
resolver el problema.
**La apuesta:** Desde que empieza una carga que pide más réplicas, el HPA tarda más de 60 s en crear la
primera réplica nueva.
**Lo que pasó:** perdida: pidió réplicas a los 31–37 s, y estuvieron listas 5–11 s después. Pero medio
minuto alcanzó para que `pricing`, con un límite de memoria medido con poca carga, muriera `OOMKilled` a los
16 s; y en una corrida murió antes de la primera lectura, el HPA se quedó en `<unknown>` y no escaló nunca:
el 94 % de las peticiones perdidas, con el autoescalado encendido. Y con `catalog`, cuatro réplicas no
alcanzaron, porque su capacidad son procesos de PHP-FPM y no CPU.
**Lo que se hace en su lugar:** las réplicas del pico, antes del pico (`minReplicas`, o un escalado
programado para la quincena); límites medidos con la carga del peor día; y una métrica que mida la
capacidad de cada runtime.
**Dónde sigue valiendo:** con carga que sube despacio, servicios sin estado y un límite que aguanta hasta
que llegan las réplicas.
**Desarrollado en:** [Fase 16](16-escalado-y-rollout.md), §5.4, §6 y §9.

### "Si el proceso apaga con cortesía, el despliegue no pierde nada"

**De dónde viene:** de la [Fase 03](03-el-contenedor-por-dentro.md): un proceso que atiende `SIGTERM` cierra lo suyo, y en compose eso
alcanzaba.
**La apuesta:** Un rollout de `pricing` con carga constante: sin apagado limpio ni `preStop`, se pierde al
menos una petición; con los dos, ninguna.
**Lo que pasó:** ganada, con sorpresa. Sin nada, 18–39 peticiones perdidas de 8.000; **con apagado
limpio y sin `preStop`, 24–29**: igual. Con `preStop` de 5 s, cero, con o sin apagado limpio. Las
peticiones se perdían antes de que el proceso recibiera la señal, mientras la puerta todavía no sabía que
el pod se iba.
**Lo que se hace en su lugar:** un `preStop` que le dé tiempo a la puerta, y el apagado limpio para las
peticiones que duran más que esa pausa.
**Dónde sigue valiendo:** donde no hay balanceador entre el cliente y el proceso, como en compose.
**Desarrollado en:** [Fase 16](16-escalado-y-rollout.md), §5.2.

---

### "Las métricas son un tablero que se instala al final"

**De dónde viene:** de la operación de servidores, donde el monitoreo era un producto que alguien instalaba
encima (un agente, un tablero) y la aplicación no tenía que hacer nada. Y en compose, `docker stats`
alcanzaba para saber si algo estaba vivo.
**La apuesta:** Si `pricing` etiqueta con la ruta cruda (`/prices/SKU-0001`) en vez del patrón
(`/prices/{sku}`), 2.000 SKU distintos multiplican por más de 100 las series de `pricing`, y la memoria de
Prometheus crece más de un 50 %.
**Lo que pasó:** ganada: las series de `pricing` pasaron de 123 a 28.095 y la memoria de Prometheus de 65 a
172 MiB. Y lo que el cluster daba gratis (CPU y memoria) no decía nada de las ventas: la métrica de negocio
la tuvo que contar `inventory`. En `catalog`, la librería instalada y el endpoint respondiendo no contaron
**ninguna** de 200 peticiones hasta que hubo APCu: en PHP-FPM, nada sobrevive a una petición.
**Lo que se hace en su lugar:** instrumentar como parte del servicio, con el mismo nombre y las mismas
etiquetas en todos los runtimes, y etiquetas de valores pocos y conocidos; los identificadores, a los logs.
**Dónde sigue valiendo:** para CPU, memoria y reinicios, que sí da la plataforma sin pedir nada; y para un
servicio que nadie va a mirar, donde instrumentar es costo sin retorno.
**Desarrollado en:** [Fase 17](17-metricas-y-dashboards.md), §4, §6 y §9.

### "Con `docker logs` y un grep alcanza"

**De dónde viene:** de compose y de los servidores, donde había una máquina, un archivo de log o un
`docker logs`, y la persona que buscaba sabía en cuál mirar. El texto libre era cómodo de leer.
**La apuesta:** Poner `request_id` como etiqueta de Loki en vez de dejarlo en la línea multiplica los flujos
por el número de peticiones, y Loki empieza a rechazar o a crecer en memoria con unos pocos miles.
**Lo que pasó:** ganada: 5.001 flujos en cinco minutos, Loki de 90 a 145 MiB, 429 en Fluent Bit y una línea
de cada cuatro perdida. Y antes de eso, lo que el instinto no ve: cuatro formatos de texto distintos para
la misma petición, nada que dijera que dos líneas eran la misma venta, y los logs de un pod borrado, idos con
él. Un `catalog` con el canal de fábrica de Laravel escribió mil líneas a un archivo dentro del contenedor y
ninguna a su salida.
**Lo que se hace en su lugar:** una línea JSON por evento a stdout, con los mismos campos en todos los
servicios; un `request_id` que cada servicio reenvía; un recolector por nodo; y los identificadores en la
línea, nunca en las etiquetas.
**Dónde sigue valiendo:** con un servicio, una réplica y alguien mirando en el momento: `kubectl logs` (y
`--previous`) alcanza.
**Desarrollado en:** [Fase 18](18-logs.md), §4, §5.1, §5.3 y §9.

### "Un certificado se instala una vez al año"

**De dónde viene:** de veinte años de servidores: el certificado se compra o se pide, se instala en el
servidor web y se anota la fecha. Mientras alguien se acuerde, funciona.
**La apuesta:** Con cert-manager, un certificado del `Gateway` de una hora se renueva solo antes de vencer, y
Envoy empieza a servir el nuevo sin reiniciar ningún pod ni cortar una petición.
**Lo que pasó:** ganada: el certificado nuevo, servido en el segundo de la renovación, y 2.226 peticiones sin
un fallo. Del otro lado, el certificado puesto a mano: cero avisos antes de vencer, todas las conexiones HTTPS
rechazadas después, y la puerta diciendo `ResolvedRefs=True` mientras tanto. Y un certificado ya vencido que
alguien pone para "arreglarlo" la puerta ni lo carga: se cae el HTTPS de todos los nombres.
**Lo que se hace en su lugar:** que el certificado lo emita quien lo renueva (cert-manager), con una alerta
sobre la fecha de vencimiento de todos modos; y los servicios que relean sus certificados cuando cambian.
**Dónde sigue valiendo:** un servidor con un certificado de una CA pública y sin cluster, con dos personas a
cargo del recordatorio.
**Desarrollado en:** [Fase 19](19-tls-y-certificados.md), §5.4 y §9.

### "La red del cluster es interna"

**De dónde viene:** del centro de datos, donde lo que estaba detrás del firewall se consideraba de confianza, y de
compose, donde la red del proyecto es una sola y nadie más está en ella.
**La apuesta:** Sin `NetworkPolicy`, un pod de `apps-b` llega al Postgres de `data` y a `pricing` de `apps` sin que nada
lo impida; con una política de *default deny* por namespace y sus excepciones, no.
**Lo que pasó:** ganada: la segunda cadena le contestaba 200 a La Vecina y conectaba a su base; con las políticas, timeout
para todo lo que no es suyo. Pero cerrar sin abrir el DNS dejó a todo el namespace sin resolver un nombre (504 a los
16 s), y la red no separó lo que la segunda cadena **necesita** compartir: el Postgres.
**Lo que se hace en su lugar:** *default deny* por namespace con las excepciones escritas, empezando por el DNS, y
probadas desde adentro; y la identidad (usuarios de la base, certificados, `ServiceAccount`) para lo que la red no
separa.
**Dónde sigue valiendo:** un cluster de un solo equipo y un solo sistema, sin datos de terceros.
**Desarrollado en:** [Fase 20](20-seguridad-del-pod-y-de-la-red.md), §4, §5.4 y §9.

### "Si falla, lo reinicio, y después miro"

**De dónde viene:** de compose y de los servidores, donde reiniciar era barato, casi siempre funcionaba, y había un solo
log que seguía ahí después.
**La apuesta:** `kubectl debug` con un contenedor efímero que comparte el espacio de procesos permite ver los procesos de
`pricing` (distroless, sin shell), y el `jcmd` desde un efímero sobre `inventory` sigue sin contestar, como en la F15.
**Lo que pasó:** mitad y mitad: el efímero vio todo, y el `jcmd` contestó, porque el endurecimiento de la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) le dio
al efímero el usuario de la JVM. Y el reflejo del título le costó al autor dos corridas de un experimento: el pod se
reemplazó antes de leer su `logs --previous`, y la causa raíz no se pudo citar.
**Lo que se hace en su lugar:** los primeros treinta segundos, que solo leen; la evidencia guardada; y recién después, el
arreglo.
**Dónde sigue valiendo:** cuando el sistema está caído y hay un camino conocido de vuelta: primero se guardan diez
segundos de evidencia, y después se vuelve.
**Desarrollado en:** [Fase 21](21-diagnostico.md), §5.2, §5.7 y §9.

## 🔁 Del código distribuido

Los reflejos de quien escribe la aplicación esperando que la plataforma resuelva lo que no le
corresponde: el reintento que alguien más hará, la transacción que abarca dos servicios, el mensaje
que llega una sola vez.

### "Si es lento, el orquestador lo escala"

**De dónde viene:** de la promesa de la Parte II: reinicios, réplicas, autoescalado. Lo que se cae, vuelve; lo que no
da abasto, crece.
**La apuesta:** Sin timeouts, con 5 s de latencia inyectados en `catalog` y 50 ventas/s, las lecturas de existencias de
`inventory` (que no tocan `catalog`) pasan de un p95 menor de 50 ms a más de 1 s.
**Lo que pasó:** ganada: de 17,6 ms a 5,54 s, y un 6,6 % de fallas, sin un solo reinicio ni una alarma de CPU. El vecino
lento tumbó a `inventory` entero por los hilos, y el orquestador no tenía nada que escalar: nadie estaba ocupado,
todos esperaban. Los reintentos ingenuos le pusieron a `catalog` 1,85 veces la carga; y el circuit breaker, que lo
protegió, dejó fallar el 96 % de las ventas con un vecino degradado.
**Lo que se hace en su lugar:** timeouts siempre; reintentos con espera y en un solo lugar; un circuito ajustado a lo
que el negocio prefiere perder; y la plataforma como piso, no como solución.
**Dónde sigue valiendo:** para lo que **muere** (el reinicio) y para la carga que **crece despacio** (el autoescalado).
**Desarrollado en:** [Fase 22](22-resiliencia-y-caos.md), §4, §5.3, §5.4 y §8.


### "Tres réplicas reparten el tráfico entre tres"

**De dónde viene:** de la [Fase 16](16-escalado-y-rollout.md), donde escalar funcionó: más réplicas detrás del `Service`, menos carga en cada una.
**La apuesta:** con tres réplicas de `pricing` y gRPC por un `Service` normal, más del 90 % de las llamadas van a una
sola réplica; con balanceo en el cliente, cada una recibe entre el 25 % y el 40 %.
**Lo que pasó:** ganada, y peor de lo apostado: 600 de 600 llamadas a una réplica en las tres corridas. El `Service`
reparte **conexiones**, y HTTP/2 manda todo por una. El precio por HTTPS ya iba así desde la [Fase 19](19-tls-y-certificados.md), porque el
8443 negocia HTTP/2. Con el *headless* y `round_robin`, 200/200/200; pero una réplica nueva recibió 0 de 1200
llamadas, porque el cliente no vuelve a resolver el DNS.
**Lo que se hace en su lugar:** contar llamadas **por réplica**; balancear en el cliente (o en un proxy de capa 7) y
ponerle edad máxima a las conexiones, para que el cliente vea las réplicas nuevas.
**Dónde sigue valiendo:** con HTTP/1.1 y muchas conexiones cortas, y con todo lo que entra por la puerta, donde Envoy
reparte cada petición.
**Desarrollado en:** [Fase 23](23-grpc-y-el-balanceo.md), §4, §5.4, §5.5 y §9.

### "Si encendí las trazas, veo todo el camino"

**De dónde viene:** de la promesa de la instrumentación automática: un agente, una línea de `--import`, y cada salto
queda dibujado.
**La apuesta:** una venta aparece en Tempo como una sola traza con los cuatro servicios.
**Lo que pasó:** la primera traza tuvo tres servicios: el aviso a `replenish` salía en un hilo virtual que no hereda el
contexto, y fue otra traza. Con `Context.current().wrap(...)`, catorce spans de los cuatro. Y con Tempo caído, `catalog`
(PHP, que exporta dentro de la petición) colgó lecturas hasta el corte de 15 s y una venta falló.
**Lo que se hace en su lugar:** pasar el contexto a mano en todo lo asíncrono; y no dejar que el exportador espere
dentro de la petición: un timeout corto o un recolector local.
**Dónde sigue valiendo:** en el camino síncrono de una petición, que los cuatro runtimes instrumentan solos.
**Desarrollado en:** [Fase 23](23-grpc-y-el-balanceo.md), §5.7 y §6.

### "Si la llamada falló, no pasó nada"

**De dónde viene:** de una transacción en una sola base, donde es verdad: en Contingencia, si el tercer paso de
`register_loan` falla, la base deshace los dos primeros sola.
**La apuesta:** con *Sogamoso con lluvia* en `replenish` y 20 préstamos, las órdenes huérfanas son exactamente tantas
como los despachos que fallaron por timeout, y ninguna sale de un 503.
**Lo que pasó:** ganada: 8 timeouts, 8 órdenes en `PENDING` de préstamos ya compensados; los 2 préstamos con 503 no
dejaron nada. Un timeout no dice "no pasó": dice "no sé". El vecino recibió la petición, la atendió tarde, y la saga ya
había liberado la unidad.
**Lo que se hace en su lugar:** tratar el timeout como "resultado desconocido", no como falla; una clave que deje
preguntar o repetir sin duplicar ([Fase 26](26-idempotencia-y-outbox.md)).
**Dónde sigue valiendo:** dentro de una sola base, y con un error que el vecino contestó (un 503 que el vecino mismo
devolvió antes de hacer nada).
**Desarrollado en:** [Fase 24](24-la-saga-orquestada.md), §4, §7 y §8.

### "Si lo publiqué, alguien lo recibió"

**De dónde viene:** de una llamada HTTP, donde la respuesta dice si el otro lo recibió; y de un `PUBLISH` que no da error.
**La apuesta:** con Valkey pub/sub y `replenish` reiniciándose durante 30 ventas, se pierde al menos un aviso, sin que
ninguna venta falle.
**Lo que pasó:** perdida, de la manera más útil. Con un `rollout restart` no se perdió ninguno y se **duplicaron** diez:
hubo dos pods suscritos a la vez, y pub/sub entrega a cada suscriptor. Con el proceso reiniciado dentro del pod, uno de
30 se publicó "a 0 suscriptores" y no existió nunca. Con NATS JetStream, 30 de 30 en los dos casos, y 10 avisos
esperaron 60 s a que `replenish` volviera.
**Lo que se hace en su lugar:** un bus que guarde el mensaje hasta que el consumidor confirme (al menos una vez), un
consumidor compartido por las réplicas, y consumidores que aguanten el mensaje repetido ([Fase 26](26-idempotencia-y-outbox.md)).
**Dónde sigue valiendo:** para avisos que se pueden perder sin daño (invalidar una caché, refrescar una pantalla).
**Desarrollado en:** [Fase 25](25-la-coreografia.md), §4, §5 y §7.

### "Si lo guardé y avisé, quedó hecho"

**De dónde viene:** de un programa que hace dos cosas seguidas —confirmar la venta, mandar el aviso— y nunca vio morir
el proceso entre las dos.
**La apuesta:** con G12, un `kill -9` a `inventory` en medio de una ráfaga deja al menos una venta sin su orden; y uno a
`replenish`, al menos una orden repetida.
**Lo que pasó:** ganadas las dos, y con la letra chica de lo raro. La venta sin orden apareció en la tercera corrida
(387 ventas, 386 órdenes): la ventana es de milisegundos. La orden repetida, en dos de tres: RO-4221 y RO-5030, la misma
venta, la segunda 30 s después, cuando venció el `ack_wait`. Con G13 (outbox, `Nats-Msg-Id`, `processed_events`), cero
y cero en seis corridas; y las dos defensas, provocadas a mano, funcionaron.
**Lo que se hace en su lugar:** escribir el evento en la misma transacción que el dato (outbox), dejar que otro lo
publique, y que quien lo recibe recuerde lo que ya procesó por la clave del hecho. Y las compensaciones, también
idempotentes: sin eso, tres préstamos recibieron 409 durante diez minutos.
**Dónde sigue valiendo:** dentro de una sola base, donde confirmar es una sola cosa.
**Desarrollado en:** [Fase 26](26-idempotencia-y-outbox.md), §4, §5, §7 y §8.
