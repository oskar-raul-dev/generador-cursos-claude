# 🧱 Fase 09 — Los cuatro servicios dentro: un namespace, cinco despliegues y la Oleada 1

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 09 de 27 · Parte II — El despliegue · **media**
> **Perfil:** `minimo` · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase (las imágenes llegan con `task images:load`)
> **Servicios que toca:** los cinco · **Paso de generación:** G1 · Almacén propio 🌊
> **Depende de:** [Fase 08](08-el-primer-despliegue.md) · **Habilita:** [Fase 10](10-la-entrada-al-sistema.md)
> **Incidentes que reserva:** 07 · **Medición:** ninguna
> **Apéndices de apoyo:** [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a01](a01-el-laboratorio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64
> **Objetivo:** desplegar los cinco servicios del paso G1 en el namespace `apps`, cada uno con su almacén y sin llamarse entre ellos, y que la suite G1 pase dentro del cluster dos veces seguidas.

---

## 🧭 1. Dónde estamos

La [Fase 08](08-el-primer-despliegue.md) dejó a `pricing` solo en `default`, con el precio fijo de G0, para construir el patrón sin
ruido. Esta fase trae a los otros cuatro siguiendo ese patrón, y con ellos la primera oleada de
dominio: **cada servicio guarda lo suyo**.

Valentina convocó a los cuatro equipos el lunes siguiente a la circular de precios (historia §2). Cada
uno traía su servicio y su forma de pensar los datos: el Núcleo, con la existencia que solo cambia por
movimientos; el equipo del portal, con el catálogo que se edita; el de la Braqui, con las órdenes que
no se tocan una vez creadas. La regla de la reunión fue de Valentina:

> *"Cada uno con su almacén, y nadie le pregunta nada a nadie todavía. Si mañana necesitan hablarse,
> lo hablamos con contrato, no con una tabla compartida."*

Es exactamente lo que hace el paso G1 de la matriz de generación
([a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g1)): un almacén por servicio, en
SQLite, dentro del pod, y **ninguna llamada entre servicios**. Las direcciones de los vecinos existen
desde hoy en un `ConfigMap`, y nadie las usa hasta la venta de la [Fase 16](16-escalado-y-rollout.md). Y el SQLite dentro del pod
es una deuda 💸 con fecha de cobro: la [Fase 12](12-estado-y-almacenamiento.md).

---

## 🎯 2. Objetivos de esta fase

1. Crear el namespace `apps` y llevar a `pricing` a él, con los otros cuatro.
2. Generar el paso G1 con los prompts de `a03` y que su suite pase en compose y en el cluster.
3. Unir los cinco con labels y selectores, y listar el sistema entero con una sola.
4. Resolver nombres entre namespaces, y provocar el incidente 07.
5. Explicar dónde vive el almacén de cada servicio y cuánto dura.

---

## 🚫 3. Qué NO entra todavía

- Que un servicio llame a otro → [Fase 16](16-escalado-y-rollout.md) (la Oleada 2).
- Postgres y la persistencia de verdad → [Fase 12](12-estado-y-almacenamiento.md); hoy, SQLite en un `emptyDir`.
- Ver el catálogo en el navegador → [Fase 10](10-la-entrada-al-sistema.md).
- La configuración del `storefront` en arranque → [Fase 11](11-configuracion-y-secretos.md).

---

## 🧨 4. El problema, en el laboratorio

Con todo en `default`, un nombre corto funciona siempre, y eso es lo peligroso. Lo que la [Fase 08](08-el-primer-despliegue.md)
dejó entrever en el `resolv.conf` se vuelve concreto en cuanto hay dos namespaces. Con los servicios
ya en `apps`, un pod de `default` que pregunta como se preguntaba en compose:

```text
$ kubectl run cliente -n default --restart=Never --image=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e -- curl -sS -m 5 http://catalog:8080/health/live
$ kubectl -n default logs cliente
curl: (6) Could not resolve host: catalog (Domain name not found)
$ kubectl run cliente -n default … -- curl -sS -m 5 http://catalog.apps:8080/health/live
{"status":"live"}
```

El nombre `catalog` existe, pero en otro namespace. Un namespace es una frontera de nombres: lo que
vive en `apps` se llama distinto desde afuera. Y el segundo problema no da error: los cinco
servicios ya guardan datos, y hay que saber **dónde** y **cuánto duran** antes de confiarles nada.

---

## 🧱 5. El namespace, los vecinos y el almacén, con `pricing`

### 5.1 `apps`: la frontera

```yaml
# La frontera de los servicios del sistema (Fase 09): nombres, permisos y, desde la Fase 15, cuotas.
apiVersion: v1
kind: Namespace
metadata:
  name: apps
  labels:
    app.kubernetes.io/part-of: lab
```

Y en el manifiesto de `pricing`, una línea: `namespace: apps` en el `metadata` del `Deployment` y del
`Service`. El de la [Fase 08](08-el-primer-despliegue.md) se borra de `default` (`kubectl -n default delete deploy/pricing
svc/pricing`): ningún servicio del sistema vive ahí desde hoy. **Un namespace no es una red aparte ni
una máquina aparte**: los pods de `apps` y los de `default` se ven por red igual que antes. Es una
frontera de nombres, de permisos ([Fase 20](20-seguridad-del-pod-y-de-la-red.md)) y de cuotas ([Fase 15](15-salud-y-recursos.md)). Y una frontera de borrado, que la
sección 8 mide.

### 5.2 G1 en `pricing`: el almacén dentro del pod

El paso G1 de `pricing` se generó con su prompt de
[a03](a03-contratos-y-prompts-de-generacion.md#g1--pricing-el-piloto): `PUT /prices/{sku}` guarda,
`GET` lee, y la base es un SQLite en `DATA_DIR`. Dos decisiones del prompt vienen de fases anteriores:
el driver es **Go puro** (`modernc.org/sqlite`), porque con cgo el binario deja de correr en distroless
([Fase 04](04-empaquetar-los-cuatro-runtimes.md)); y la carpeta de los datos **existe en la imagen a nombre del usuario 65532**, porque si no,
el primer volumen que se monte ahí nace de `root` ([Fase 03](03-el-contenedor-por-dentro.md)).

En el pod, esa carpeta es un volumen `emptyDir`:

```yaml
          volumeMounts:
            - name: data
              mountPath: /var/lib/pricing   # DATA_DIR: el SQLite de G1, dentro del pod (💸 Fase 12)
      volumes:
        - name: data
          # emptyDir: vive lo que vive el pod. Es la deuda que cobra la Fase 12, a propósito.
          emptyDir: {}
```

Un **`emptyDir`** es una carpeta que el `kubelet` crea vacía cuando el pod nace y borra cuando el pod
se va. Dura más que un contenedor y menos que un pod, y la sección 7 lo mide. Es la versión de
cluster de la capa escribible de la [Fase 03](03-el-contenedor-por-dentro.md), con una vuelta más.

### 5.3 Los vecinos, en un `ConfigMap` que nadie usa

```yaml
# Las direcciones de los vecinos (Fase 09). Nadie las usa todavía: la primera llamada entre servicios
# es la venta de la Fase 16. Van con el nombre completo del Service, que resuelve desde cualquier
# namespace; el nombre corto solo resuelve dentro de `apps` (incidente 07).
apiVersion: v1
kind: ConfigMap
metadata:
  name: neighbors
  namespace: apps
data:
  CATALOG_URL: http://catalog.apps.svc.cluster.local:8080
  INVENTORY_URL: http://inventory.apps.svc.cluster.local:8080
  PRICING_URL: http://pricing.apps.svc.cluster.local:8080
  REPLENISH_URL: http://replenish.apps.svc.cluster.local:8080
```

Y en cada backend, `envFrom` lo convierte en variables de entorno:

```text
$ kubectl -n apps exec deploy/inventory -- env | grep _URL
CATALOG_URL=http://catalog.apps.svc.cluster.local:8080
INVENTORY_URL=http://inventory.apps.svc.cluster.local:8080
PRICING_URL=http://pricing.apps.svc.cluster.local:8080
REPLENISH_URL=http://replenish.apps.svc.cluster.local:8080
```

Un **`ConfigMap`** es configuración como objeto aparte del `Deployment`. Hoy es el sitio más tranquilo
para estrenarlo: nadie lo lee, así que nada se rompe si está mal. La [Fase 11](11-configuracion-y-secretos.md) lo vuelve serio, con la
lección incómoda de que cambiarlo no reinicia nada. Las URL van **con el nombre completo** por la
sección 4: un nombre que resuelve desde cualquier namespace no depende de dónde corra quien lo usa.

### 5.4 Las labels, como pegamento

Los cinco llevan las mismas cuatro labels del contrato ([Fase 08](08-el-primer-despliegue.md)), y eso permite hablarle al sistema
entero de una vez:

```text
$ kubectl -n apps get pods -o wide
NAME                          READY   STATUS    RESTARTS   AGE   IP            NODE
catalog-79b8574c49-7pkf2      2/2     Running   0          1s    10.244.0.14   minimo-control-plane
inventory-5f4f7fb8c5-lvnhg    1/1     Running   0          1s    10.244.0.15   minimo-control-plane
pricing-99859bc4c-r9mrv       1/1     Running   0          1s    10.244.0.16   minimo-control-plane
replenish-f4b58d9c5-hxbzn     1/1     Running   0          1s    10.244.0.17   minimo-control-plane
storefront-67696b4d86-r68gk   1/1     Running   0          1s    10.244.0.18   minimo-control-plane
```

`kubectl get pods -A -l app.kubernetes.io/part-of=lab` encuentra los cinco aunque estén en otro
namespace, y `-l app.kubernetes.io/component=backend` deja fuera al `storefront`. Las labels no hacen
nada por sí mismas: son lo que los selectores, los comandos y, desde la [Fase 13](13-helm-el-paquete.md), las plantillas usan
para encontrar cosas.

### 5.5 La suite, dentro del cluster

Primero contra compose, dos veces seguidas, porque la suite de G1 tiene que poder repetirse:

```text
$ task conformance -- G1
Success /suite/storefront.g1.hurl (3 request(s) in 5 ms)
Success /suite/pricing.g1.hurl (9 request(s) in 23 ms)
Success /suite/replenish.g1.hurl (12 request(s) in 58 ms)
Success /suite/inventory.g1.hurl (14 request(s) in 218 ms)
Success /suite/catalog.g1.hurl (13 request(s) in 302 ms)
Executed files:    5
Executed requests: 51 (157.9/s)
Succeeded files:   5 (100.0%)
```

Y desde esta fase, **contra el cluster**, que es donde la Parte II verifica cada paso:

```bash
task conformance TARGET=cluster -- G1
```

Debajo, dos comandos: la suite entra al cluster como un `ConfigMap` (`kubectl -n apps create configmap
conformance --from-file=contracts/conformance`), y Hurl corre en un pod de `apps` que lo monta, con
las direcciones de `cluster.env` (`http://pricing.apps.svc.cluster.local:8080`…):

```text
Success /suite/storefront.g1.hurl (3 request(s) in 18 ms)
Success /suite/pricing.g1.hurl (9 request(s) in 21 ms)
Success /suite/replenish.g1.hurl (12 request(s) in 85 ms)
Success /suite/inventory.g1.hurl (14 request(s) in 271 ms)
Success /suite/catalog.g1.hurl (13 request(s) in 324 ms)
--------------------------------------------------------------------------------
Executed files:    5
Executed requests: 51 (148.7/s)
Succeeded files:   5 (100.0%)
Failed files:      0 (0.0%)
```

### 5.6 La Oleada 1, en datos

G1 trae poco dominio, a propósito, pero el poco que trae ya tiene una regla que el Siga no tenía
(D33): **los datos maestros se editan; el estado se cambia con hechos.** En `inventory`, la existencia
no se escribe: se mueve. Un conteo del lunes, una entrada, un traslado que no llegó y el conteo del
martes, contra `inventory` en el cluster (cada `curl` desde un pod cliente):

```text
$ POST COUNT 30
{"id":"MOV-000004","store":"DRO-007","sku":"SKU-0003","type":"COUNT","quantity":-1,"reasonCode":null,"reference":"conteo-lunes",…}
$ POST RESTOCK 6
{"id":"MOV-000005","store":"DRO-007","sku":"SKU-0003","type":"RESTOCK","quantity":6,"reasonCode":null,"reference":"RO-0002",…}
$ POST ADJUSTMENT -2 TRANSFER_LOST
{"id":"MOV-000006","store":"DRO-007","sku":"SKU-0003","type":"ADJUSTMENT","quantity":-2,"reasonCode":"TRANSFER_LOST","reference":"traslados_20261003_0308.txt",…}
$ POST COUNT 31
{"id":"MOV-000007","store":"DRO-007","sku":"SKU-0003","type":"COUNT","quantity":-3,"reasonCode":null,"reference":"conteo-martes",…}
$ GET /stock/DRO-007/SKU-0003
{"store":"DRO-007","sku":"SKU-0003","quantity":31,"reorderThreshold":0}
$ PATCH /stock/DRO-007/SKU-0003  {"quantity":50}
{"error":"unprocessable","message":"solo se cambia reorderThreshold, entero no negativo; la cantidad cambia con movimientos"}
```

Un conteo guarda la **diferencia** (−1, −3) y no lo contado, para que la suma de los movimientos siga
siendo la existencia. El ajuste exige su código de razón, y su `reference` apunta al archivo de
traslados que nunca llegó: la maña de la Braqui (`a16`) ya tiene dónde quedar registrada. Y la
cantidad no se parcha. Es poco, pero es la diferencia entre un número que alguien escribió y una
historia que alguien puede auditar el lunes.

> 📝 **La primera vez que corrí esa secuencia, el primer `POST` no devolvió nada.** Venía de reiniciar
> `inventory` con un `rollout restart`, y el cliente salió apenas el `rollout status` dijo que estaba
> listo: el pod figuraba listo antes de que Spring abriera el puerto, porque la readiness de G1 sigue
> siendo trivial. `curl -s` se tragó el error. Es la [Fase 15](15-salud-y-recursos.md), con otra cara.

**Prueba de fuego.** La salida de 5.5, dos veces seguidas. La generación de G1 pasó la suite al primer
intento con los cinco servicios, y lo digo porque no siempre es así (en G0 falló uno): los prompts de
G1 heredaron de las fases anteriores las tres trampas que podían romperlos —el driver con cgo, la
carpeta sin dueño y el `exec` del arranque—, y por eso no las pisaron.

**El patrón a memorizar.** Un namespace es una frontera de nombres; un `ConfigMap` es configuración
como objeto; las labels unen todo; y la suite es la que dice que el paso está hecho, también dentro
del cluster.

---

## 🔁 6. Los otros tres: donde no es mecánico

**`catalog`, un pod con dos contenedores.** Lo que en compose era `network_mode: service:catalog`
(D34) aquí es la definición misma de pod: dos contenedores que comparten red y se programan juntos.

```text
$ kubectl -n apps get pod -l app.kubernetes.io/name=catalog -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"  "}{.image}{"\n"}{end}'
php-fpm  lab/catalog:g1
nginx  nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e
$ kubectl -n apps logs deploy/catalog -c nginx --tail=1
10.244.0.22 - - [04/Oct/2026:01:21:26 +0000] "GET /health/live HTTP/1.1" 200 28 "-" "curl/8.22.0" "-"
$ kubectl -n apps logs deploy/catalog -c php-fpm --tail=2
[2026-10-04 01:21:26] production.INFO: GET /health/live 200
127.0.0.1 -  04/Oct/2026:01:21:26 +0000 "GET /index.php" 200
```

`2/2` en la columna `READY`, y `-c` para elegir de qué contenedor leer. La misma petición deja una línea
en cada uno: nginx la recibe de otro pod, y FPM de `127.0.0.1`, porque comparten red. El `nginx.conf`
tiene una sola fuente, `services/catalog/nginx.conf`, y `task deploy` lo convierte en el `ConfigMap`
`catalog-nginx` que se monta en el contenedor de nginx. Y el arranque de FPM aplica el esquema y
termina con `exec php-fpm`, para que FPM siga siendo el proceso 1 ([Fase 03](03-el-contenedor-por-dentro.md)).

**`inventory`, el que trae código nativo sin decirlo.** El driver de SQLite para Java carga una
biblioteca nativa, y Java 25 lo avisa al arrancar:

```text
WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by org.sqlite.SQLiteJDBCLoader in an unnamed module (file:/app/lib/sqlite-jdbc-3.53.2.1.jar)
WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
WARNING: Restricted methods will be blocked in a future release unless native access is enabled
```

La biblioteca viene dentro del jar, compilada para glibc: funciona en la imagen de Temurin (Ubuntu) y
no funcionaría en Alpine, que es la lección de musl de la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) en una dependencia que nadie mira.
El aviso queda a propósito: es G3 el que cambia de driver.

**`replenish`, sin dependencias nativas, y con la deuda de la [Fase 03](03-el-contenedor-por-dentro.md).** Usa el `node:sqlite` que trae
Node, para no compilar nada en Alpine. Y es el único de los cinco que tarda en irse: borrar su pod
tarda 31,1 segundos, contra 0,6 de `pricing` y 1,0 de `catalog`. Son los 30 segundos de gracia que el
pod espera por defecto (`terminationGracePeriodSeconds: 30`) antes de matar a un proceso 1 que no
atiende `SIGTERM`. En compose eran 10. La [Fase 16](16-escalado-y-rollout.md) lo cobra.

**`storefront`, la página que todavía no alcanza al catálogo.** Su G1 pide los productos desde el
navegador a una dirección horneada al compilar, `http://api.localhost:8080`:

```text
$ curl -s http://127.0.0.1:18082/ | head -8          # con kubectl port-forward svc/storefront 18082:8080
<!doctype html>
<html lang="es">
  <head>
    …
    <title>Droguerías La Vecina</title>
    <script type="module" crossorigin src="/assets/index-2WMfVtp6.js"></script>
$ curl -s http://127.0.0.1:18082/assets/index-2WMfVtp6.js | grep -o "api.localhost:8080"
api.localhost:8080
$ curl -sS -m 5 http://api.localhost:8080/catalog/products
curl: (52) Empty reply from server
```

La dirección está dentro del JavaScript, y en esa dirección todavía no contesta nadie: es la puerta
que abre la [Fase 10](10-la-entrada-al-sistema.md). Que la dirección esté horneada en el archivo, y no se pueda cambiar sin
reconstruir la imagen, es el problema de la [Fase 11](11-configuracion-y-secretos.md).

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto, en su mejor versión: *"los datos del contenedor viven lo que vive el contenedor; si
quiero que duren, un volumen."* En compose es la regla de la [Fase 03](03-el-contenedor-por-dentro.md) y la [Fase 06](06-del-compose-al-cluster.md). En un pod hay un
nivel más: el `emptyDir` no es del contenedor sino del pod.

> 🪞 **Apuesta antes de ejecutar.** Matar solo el contenedor `php-fpm` del pod de `catalog` no borra
> el catálogo (el `emptyDir` vive lo que vive el pod); borrar el pod, sí: el pod nuevo arranca con el
> catálogo vacío.
>
> **Resultado: ganada.** Con un producto creado, `kubectl -n apps exec deploy/catalog -c php-fpm --
> kill -TERM 1` reinició solo ese contenedor (`2/2 Running 1 (8s ago)`) y el producto siguió ahí.
> Borrado el pod, el nuevo contestó `[]`.

```text
$ kubectl -n apps get pods -l app.kubernetes.io/name=catalog
NAME                       READY   STATUS    RESTARTS     AGE
catalog-79b8574c49-rdqvp   2/2     Running   1 (8s ago)   15s
… curl http://catalog:8080/products
[{"sku":"SKU-0003","name":"Salbutamol inhalador 100 mcg","category":"venta libre","status":"ACTIVE","statusReasonCode":null}]
$ kubectl -n apps delete pod -l app.kubernetes.io/name=catalog
… curl http://catalog:8080/products
[]
```

La lección es la deuda: **cualquier cosa que borre el pod borra el almacén** —un despliegue nuevo, un
nodo que se cae, un `rollout restart`—. Y con dos réplicas, cada pod tendría su propio catálogo. Es el
experimento con que abre la [Fase 12](12-estado-y-almacenamiento.md).

---

## 🧨 8. La rotura: borrar el namespace

La frontera de la sección 5.1 también es un botón de borrar. **El cambio exacto:**

```text
$ kubectl get all -n apps --no-headers | wc -l
      20
$ time kubectl delete namespace apps
namespace "apps" deleted
kubectl delete namespace apps  0.04s user 0.02s system 0% cpu 36.179 total
$ kubectl get pods -n apps
No resources found in apps namespace.
```

**El síntoma:** veinte objetos —cinco `Deployment`, cinco `ReplicaSet`, cinco pods y cinco `Service`,
más los `ConfigMap`— y todos los datos de G1, borrados con un comando que no pregunta. Tardó 36
segundos, casi todos esperando a `replenish` (sección 6). **Para salir:** `task deploy -- minimo` lo
recrea todo en 0,6 segundos, y la suite G1 vuelve a pasar; lo que no vuelve son los datos, porque
vivían en los pods. En producción, el borrado de un namespace es el comando que más conviene proteger
con permisos ([Fase 20](20-seguridad-del-pod-y-de-la-red.md)).

---

## ⚰️ 9. Autopsia: el nombre corto en la configuración

**La decisión, con su mejor argumento.** Escribir las direcciones de los vecinos como en compose:
`CATALOG_URL=http://catalog:8080`. *"Es más corto, se lee mejor, y funciona."*

**Por qué era razonable.** Funciona, mientras quien la usa viva en el mismo namespace que `catalog`:
el `resolv.conf` del pod completa el nombre con su propio namespace ([Fase 08](08-el-primer-despliegue.md)).

**Qué pasa después, con número.** El día que alguien corre el mismo servicio en otro namespace —una
prueba, la segunda cadena de la [Fase 14](14-helm-en-operacion.md), un pod de depuración—, la misma configuración no resuelve:
`curl: (6) Could not resolve host: catalog (Domain name not found)`, sin que el servicio ni su
configuración hayan cambiado.

**Cuánto cuesta salir, con número.** Cuatro líneas: las URL del `ConfigMap` con el nombre completo
(`catalog.apps.svc.cluster.local`), como están desde esta fase.

**Qué lo habría cambiado.** Preguntar *¿desde dónde se va a usar este nombre?* Si la respuesta es "no
sé", el nombre completo.

**Antes y después, con números:** desde `default`, `http://catalog:8080` no resuelve; `http://catalog.apps:8080`
y el nombre completo responden `{"status":"live"}`.

---

## 📖 10. Traducción

| En compose | En Kubernetes | Lo que cambia |
|---|---|---|
| un proyecto | un namespace | frontera de nombres, permisos y cuotas, dentro del mismo cluster |
| `environment:` | `env` / `envFrom` con un `ConfigMap` | la configuración es un objeto aparte |
| `network_mode: service:catalog` | dos contenedores en un pod | la excepción de compose es la unidad |
| un volumen con nombre | `emptyDir` (hoy) · `PersistentVolumeClaim` ([Fase 12](12-estado-y-almacenamiento.md)) | el `emptyDir` vive lo que vive el pod |
| `docker compose logs catalog` | `kubectl logs deploy/catalog -c nginx` | con dos contenedores, se elige |

El diccionario completo, en [a05](a05-diccionarios.md#-compose--kubernetes).

---

## 🩺 11. Incidentes de esta fase

- **[07 — `inventory` no encuentra a `catalog`, que está ahí](cuaderno-incidentes.md#-incidente-07--inventory-no-encuentra-a-catalog-que-está-ahí).**
  Desde el pod de `inventory`, `getent hosts catalog` no devuelve nada y sale con código 2, aunque
  `kubectl get svc -A` muestra a `catalog` en `apps`.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**El SQLite dentro del pod no sirve para nada que tenga que durar**, y esta fase lo dejó así a
propósito. Un `rollout restart` o un nodo caído borran los datos; dos réplicas tienen dos verdades.
Para un servicio sin estado propio, o para una prueba, es perfecto; para el inventario de una
droguería, es la autopsia de la [Fase 12](12-estado-y-almacenamiento.md).

**Un namespace por servicio sería más frontera, y más trabajo**: el curso usa uno solo para los cinco,
porque los cinco son del mismo sistema y los despliega el mismo equipo de plataforma. La pérdida es
concreta: nadie puede darle permisos solo sobre `catalog` al equipo del portal sin la [Fase 20](20-seguridad-del-pod-y-de-la-red.md).

Y lo que se compró con todo esto, medido: los cinco servicios de G1 dentro del cluster suman 319 MiB
(304–373) de memoria de trabajo, y la máquina virtual sube unos 295 MiB (279–337) con ellos ([B-00 en
a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)). En compose, los mismos cinco de G0
sumaban 446 MiB.

**La pregunta del curso, para esta fase:** el contenedor te dio cinco procesos aislados. El orquestador
te dio un namespace, un `ConfigMap`, labels para encontrarlos y un DNS que los nombra. **Te tocó a ti**
decidir dónde vive cada almacén, cuánto dura, y escribir las direcciones para que resuelvan desde
cualquier lado.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`READY 1/2` en `catalog`.** Uno de los dos contenedores no arrancó. Comprobación 🩺: `kubectl -n apps
describe pod -l app.kubernetes.io/name=catalog`, y los eventos de cada contenedor. Causa frecuente: el
`ConfigMap` `catalog-nginx` no existe (se aplicó el manifiesto sin `task deploy`).

**`WARNING: A restricted method in java.lang.System has been called`.** Es un aviso, no un error: el
driver de SQLite carga código nativo. El servicio arranca igual.

**La suite G1 falla la segunda vez.** Si un servicio regenerado no es idempotente (por ejemplo, un
`POST` que no acepta un 409), la segunda corrida lo delata. Salida: corregir el prompt, no la suite
([a03](a03-contratos-y-prompts-de-generacion.md#️-cuando-el-código-generado-no-pasa)).

**`Error from server (NotFound): namespaces "apps" not found`.** Se aplicó un manifiesto antes que el
namespace. Salida: `task deploy`, que aplica el namespace primero.

---

## 📋 14. Checklist de validación

```text
[ ] task conformance -- G1 pasa dos veces seguidas contra compose
[ ] task images:load -- minimo y task deploy -- minimo: cinco pods Running, catalog en 2/2
[ ] task conformance TARGET=cluster -- G1 pasa dos veces seguidas
[ ] desde default, catalog no resuelve y catalog.apps sí
[ ] el producto sobrevive a matar php-fpm y no sobrevive a borrar el pod
[ ] sabes por qué borrar el pod de replenish tarda 30 segundos
```

---

## 🧪 15. Ejercicios (20)

Un tercio son de diagnóstico; varios usan servicios que no son `pricing`.

## 🟢 Fácil — los cinco dentro (1–6)

### 🟢 Ejercicio 1 — Despliega el sistema
Despliega los cinco servicios de G1 en `minimo`.

**Criterio:** `kubectl -n apps get pods` con cinco pods `Running` y `catalog` en `2/2`.

<details><summary>Solución</summary>

`task build:all`, `task images:load -- minimo`, `task deploy -- minimo`.
</details>

### 🟢 Ejercicio 2 — La suite en el cluster
Corre la suite G1 dentro del cluster.

**Criterio:** `Succeeded files: 5 (100.0%)`.

<details><summary>Solución</summary>

`task conformance TARGET=cluster -- G1`.
</details>

### 🟢 Ejercicio 3 — Los vecinos
Muestra las URL de los vecinos dentro de `replenish`.

**Criterio:** las cuatro variables `_URL` con el nombre completo.

<details><summary>Solución</summary>

`kubectl -n apps exec deploy/replenish -- env | grep _URL`.
</details>

### 🟢 Ejercicio 4 — Los dos contenedores
Lee los logs de los dos contenedores de `catalog` después de pedir `/products`.

**Criterio:** una línea en `nginx` y una en `php-fpm` por la misma petición.

<details><summary>Solución</summary>

`kubectl -n apps logs deploy/catalog -c nginx --tail=2` y `-c php-fpm`.
</details>

### 🟢 Ejercicio 5 — Todo el sistema con una label
Lista todos los pods del sistema en todo el cluster.

**Criterio:** `kubectl get pods -A -l app.kubernetes.io/part-of=lab` con los cinco.

<details><summary>Solución</summary>

El comando del criterio.
</details>

### 🟢 Ejercicio 6 — Un precio, de verdad
Fija el precio de `SKU-0003` en `DRO-007` y léelo desde otro pod.

**Criterio:** el `PUT` responde 200 y el `GET` devuelve el precio que pusiste.

<details><summary>Solución</summary>

Dos `kubectl run cliente -n apps --rm --attach --restart=Never --image=<nginx de a01> -- curl …` con
`-X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":13500}'` y después el `GET`.
</details>

## 🟡 Intermedio — nombres y datos (7–12)

### 🟡 Ejercicio 7 — Desde otro namespace
Desde `default`, llama a `inventory` con el nombre corto, con `inventory.apps` y con el nombre completo.

**Criterio:** el primero falla con `Could not resolve host`; los otros dos responden.

<details><summary>Solución</summary>

Tres pods cliente en `default` con cada URL.
</details>

### 🟡 Ejercicio 8 — Un conteo y un ajuste
Registra en `inventory` un conteo de 30 unidades de `SKU-0003` en `DRO-007` y un ajuste de −2 por
producto averiado.

**Criterio:** la existencia queda en 28, y el ajuste sin `reasonCode` da 422.

<details><summary>Solución</summary>

`POST /stock/DRO-007/SKU-0003/movements` con `{"type":"COUNT","quantity":30}` y con
`{"type":"ADJUSTMENT","quantity":-2,"reasonCode":"DAMAGED"}`.
</details>

### 🟡 Ejercicio 9 — Una orden mal hecha
En `replenish`, crea una orden con la cantidad equivocada, cancélala con su código y crea la que la
reemplaza.

**Criterio:** la orden nueva con `replacesOrderId` igual al id de la cancelada.

<details><summary>Solución</summary>

El mismo recorrido de `replenish.g1.hurl`, a mano.
</details>

### 🟡 Ejercicio 10 — Lo que sobrevive
Crea una orden en `replenish`, haz `kubectl -n apps rollout restart deploy/replenish` y búscala.

**Criterio:** la orden ya no existe después del rollout.

<details><summary>Solución</summary>

El rollout crea un pod nuevo con un `emptyDir` nuevo. Fíjate también en cuánto tarda.
</details>

### 🟡 Ejercicio 11 — El arranque de FPM
Muestra que FPM es el proceso 1 del contenedor `php-fpm`, aunque el arranque sea un script.

**Criterio:** `ps` dentro del contenedor con `php-fpm: master process` como proceso 1.

<details><summary>Solución</summary>

`kubectl -n apps exec deploy/catalog -c php-fpm -- ps -o pid,args`. El `exec` del `start.sh`.
</details>

### 🟡 Ejercicio 12 — Un descontinuado
Descontinúa un producto con un código que no existe, y después con uno que sí.

**Criterio:** 422 la primera vez; 200 la segunda, y el producto ausente de `GET /products`.

<details><summary>Solución</summary>

`PATCH /products/<sku>` con `Content-Type: application/merge-patch+json` y `{"status":"DISCONTINUED",
"reasonCode":"NO_EXISTE"}`, y después con `SANITARY_RECALL`.
</details>

## 🟠 Difícil — predecir y diagnosticar (13–17)

### 🟠 Ejercicio 13 — El incidente 07
Provoca el incidente 07 con `task inc:break -- 07` y diagnostícalo sin leer el cuaderno. **Predice**
la causa antes de mirar.

**Criterio:** la causa y el comando que la confirmó.

**Rúbrica:** las hipótesis en orden; el primer comando; la causa; y la prevención que ya está en el
`ConfigMap` de esta fase.

### 🟠 Ejercicio 14 — Dos réplicas de `catalog`
Sube `catalog` a dos réplicas, crea un producto y pide la lista diez veces. **Predice** qué ves.

**Criterio:** la predicción, y las diez respuestas.

**Rúbrica:** el producto aparece en unas respuestas y no en otras; por qué (dos `emptyDir`); y que esto
es exactamente el experimento de la [Fase 12](12-estado-y-almacenamiento.md). Vuelve a una réplica al terminar.

### 🟠 Ejercicio 15 — Un namespace por servicio
Despliega `catalog` en su propio namespace `catalog` y haz que la suite G1 pase igual.

**Criterio:** la suite pasando con un `cluster.env` que apunte a `catalog.catalog.svc.cluster.local`.

**Rúbrica:** los cambios; qué ganaste (una frontera de permisos); y qué perdiste (un `ConfigMap` de
vecinos por namespace, y más manifiestos).

### 🟠 Ejercicio 16 — 30 segundos
Haz que borrar el pod de `replenish` tarde menos de dos segundos sin tocar su código.

**Criterio:** `time kubectl -n apps delete pod -l app.kubernetes.io/name=replenish` por debajo de dos
segundos.

**Rúbrica:** lo que cambiaste (`terminationGracePeriodSeconds`, o un proceso 1 que reenvíe la señal); y
por qué bajar el tiempo de gracia esconde el problema en vez de resolverlo ([Fase 16](16-escalado-y-rollout.md)).

### 🟠 Ejercicio 17 — La suite que no se repite
Escribe un caso de Hurl para `catalog` que pase la primera vez y falle la segunda. **Predice** el
error.

**Criterio:** la predicción, y las dos corridas.

**Rúbrica:** el caso (un `POST` que espera 201 siempre); el fallo literal; y cómo lo resuelve la suite
del curso (`status toString matches "^(201|409)$"`).

## 🔴 Muy difícil — el sistema roto (18–20)

### 🔴 Ejercicio 18 — El namespace equivocado, de cinco formas
Encuentra cinco formas distintas de que un objeto de este sistema termine en el namespace equivocado.

**Criterio:** cinco comandos o manifiestos, cada uno con su evidencia en `kubectl get -A`.

**Rúbrica:** un manifiesto sin `namespace:`, un `-n` equivocado, el namespace del contexto, un
`kubectl run` olvidado, y uno tuyo; y para cada uno, la prevención.

### 🔴 Ejercicio 19 — Regenera `replenish`
Borra el código de G1 de `replenish` y regenéralo con su prompt de `a03`, con el asistente que uses.

**Criterio:** la suite G1 pasando dos veces contra compose y contra el cluster.

**Rúbrica:** el asistente; las iteraciones; lo que tuviste que agregar al prompt (si algo); y si el
código nuevo trae algo que G1 no pide.

### 🔴 Ejercicio 20 — El almacén que dura
Haz que el catálogo de `catalog` sobreviva a borrar el pod, sin Postgres.

**Criterio:** un producto creado sigue ahí después de `kubectl -n apps delete pod -l
app.kubernetes.io/name=catalog`.

**Rúbrica:** el mecanismo (un `PersistentVolumeClaim` con la clase de almacenamiento de kind); y lo
que todavía está mal (dos réplicas siguen siendo dos bases). Es un adelanto de la [Fase 12](12-estado-y-almacenamiento.md); no lo dejes
en los manifiestos del curso.

---

## 📚 16. Referencias

**Documentación oficial** (la versión 1.36 de [a01](a01-el-laboratorio.md))

- Kubernetes, *Namespaces*: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- Kubernetes, *Labels and Selectors*: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- Kubernetes, *ConfigMaps*: https://kubernetes.io/docs/concepts/configuration/configmap/
- Kubernetes, *Volumes*, `emptyDir`: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
- Kubernetes, *Pods*, los pods de varios contenedores: https://kubernetes.io/docs/concepts/workloads/pods/

**Libros**

- Brendan Burns, Joe Beda, Kelsey Hightower y Lachlan Evenson, *Kubernetes: Up and Running*, 3.ª
  edición (2022), los capítulos de labels y de `ConfigMap`.

**Orden de lectura sugerido:** antes, la página de namespaces; durante, la de labels; después, la de
`emptyDir`, con la apuesta de la sección 7 delante.

> ⚠️ Las URL y los contenidos cambian; las de Kubernetes tienen selector de versión.

---

## 🏁 17. Resultado de la fase

```text
EL SISTEMA AL CERRAR LA FASE 09 (minimo, namespace apps, paso G1)

  ConfigMap neighbors (URL de los vecinos, sin uso) ──envFrom──► los cuatro backends
  pricing     1/1   SQLite en emptyDir   PUT/GET precios, tope regulado opcional
  inventory   1/1   SQLite en emptyDir   movimientos: RESTOCK, ADJUSTMENT, COUNT
  catalog     2/2   php-fpm + nginx      productos, categorías, descontinuados
  replenish   1/1   SQLite en emptyDir   órdenes que se cancelan y se reemplazan
  storefront  1/1   nginx                pide el catálogo a api.localhost:8080 (nadie contesta: F10)

  task conformance TARGET=cluster -- G1  →  5 archivos, 51 peticiones, 0 fallidos
  💸 todo el almacén vive lo que vive el pod: Fase 12
```

> **La señal de que quedó bien:** *"Sé dónde vive el almacén de cada servicio, cuánto dura, y desde
> dónde resuelve cada nombre."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite G1 pasando y `git status`
> limpio:
>
> ```bash
> git tag -a fase-09-los-cuatro-servicios-dentro -m "F09 cerrada: namespace apps; G1 en los cinco servicios; ConfigMap de vecinos; catalog en un pod de dos contenedores; suite G1 en compose y en el cluster; incidente 07"
> ```
>
> Y el par del incidente: `inc/07/short-name-wrong-namespace-roto` e
> `inc/07/short-name-wrong-namespace-fix`. Commits con prefijo `f09:` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F16:** los 30 segundos de `replenish` en el cluster son el "antes" del apagado limpio.
- **G3 (F12):** el driver de `inventory` cambia, y con él el aviso de acceso nativo.
- **F10:** la página del `storefront` necesita CORS en el `Gateway` para leer `api.localhost` desde
  `storefront.localhost`.
