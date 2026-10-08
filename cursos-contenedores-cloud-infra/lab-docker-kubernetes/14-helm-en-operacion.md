# 🔧 Fase 14 — Helm en operación: la red de seguridad, los tres perfiles y la segunda cadena

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 14 de 27 · Parte II — El despliegue · **media**
> **Perfil:** los tres, en uso real: `minimo`, `medicion` (sobre `minimo`) y `lab` · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: Helm le habla al cluster, no al motor
> **Servicios que toca:** los cinco, en dos cadenas · **Paso de generación:** ninguno
> **Depende de:** [Fase 13](13-helm-el-paquete.md) · **Habilita:** [Fase 15](15-salud-y-recursos.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna propia; la memoria de la segunda cadena entra a B-00 en [a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64
> **Objetivo:** cambiar el sistema sin miedo —ver el cambio antes, volver atrás en segundos y saber qué no vuelve—, usar los tres perfiles de verdad, e instalar una segunda cadena con un archivo de valores y sin tocar una plantilla.

---

## 🧭 1. Dónde estamos

La [Fase 13](13-helm-el-paquete.md) dejó el sistema en un paquete, con una revisión por despliegue, y una cicatriz: tres
revisiones en `failed`, una a medias, y un precio regulado mal cobrado. Instalar ya no da trabajo.
**Cambiar todavía da miedo**, y un equipo con miedo despliega poco y en paquetes grandes.

Germán llegó a la revisión de La Rebotica con la hoja del encargo, señalando la cuarta pregunta:

> *"Esto es lo que le prometí al consejo, mano. ¿Se puede instalar para una segunda cadena sin copiarlo
> todo? No le pregunto si se puede vender. Le pregunto si para la cadena de Don Rodrigo hay que copiar
> el código o no."*

Es la condición con que el consejo aprobó Paracelso (historia §1.13). Esta fase la contesta con el
chart que ya existe, después de armar lo que hace falta para tocarlo con tranquilidad.

---

## 🎯 2. Objetivos de esta fase

1. Ver un cambio antes de aplicarlo (`task deploy:diff`), incluida la deriva que alguien dejó a mano.
2. Volver atrás con `helm rollback`, medir cuánto tarda, y saber qué no vuelve.
3. Saber qué detecta cada capa antes de aplicar: `helm template`, `--dry-run`, el esquema de valores y el
   servidor.
4. Usar los tres perfiles en sus clusters: `minimo`, `medicion` y `lab`.
5. Instalar la segunda cadena (`tenant-b` en `apps-b`) con un archivo de valores, medir lo que suma, y
   apagarla.

---

## 🚫 3. Qué NO entra todavía

- Las cuotas que impiden que una cadena le quite la máquina a la otra → [Fase 15](15-salud-y-recursos.md).
- El aislamiento de red entre las dos cadenas → [Fase 20](20-seguridad-del-pod-y-de-la-red.md).
- GitOps, el destino natural de todo esto: un repositorio que el cluster sigue solo. Va en el apéndice
  [a11](a11-gitops-de-lectura.md), de lectura.

---

## 🧨 4. El problema, en el laboratorio

Llega una circular de precios y alguien la transcribe con un cero de menos. El tope de `SKU-0003` pasa
de 20.000 a 1.800 en `values.yaml`, y `task deploy`:

```text
$ grep -n 'SKU-0003' charts/platform/values.yaml
44:      SKU-0003: 1800
$ task deploy -- minimo 2>&1 | grep -E 'REVISION|STATUS:'
STATUS: deployed
REVISION: 6
$ curl -s -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":12900}' http://api.localhost:8080/pricing/prices/SKU-0003
{"sku":"SKU-0003","store":"DRO-007","price":1800,"currency":"COP","regulatedCap":1800,"capped":true}
```

`deployed`, ningún error, la suite en verde, y una caja de Chapinero cobrando 1.800 pesos por lo que
vale 12.900. **El despliegue no falló: el cambio estaba mal.** Ninguna herramienta sabe que 1.800 es un
error de dedo; lo que puede hacer es mostrarte el cambio antes y deshacerlo rápido después.

> 🩻 **Esto sí funciona igual.** En compose, la red de seguridad es git: `git diff` antes y `git
> revert` y `up -d` después. Funciona, y es lo mismo que hace Helm, con una diferencia: Helm compara
> contra lo que **está en el cluster**, no contra lo que alguien cree que está.

---

## 🛟 5. La red de seguridad, con `pricing`

### 5.1 Ver el cambio antes: el diff

El plugin helm-diff (de [a01](a01-el-laboratorio.md#-versiones-fijadas)) renderiza el chart con los valores nuevos y lo compara con lo
instalado. `task deploy:diff` es `helm diff upgrade` con los mismos argumentos que `task deploy`:

```text
$ task deploy:diff -- minimo
apps, pricing, Deployment (apps) has changed:
-         checksum/regulated-caps: 1d678f703b7d6e36b9557f68d4c3b68551b5a7229168074faea4f7d716b1dae2
+         checksum/regulated-caps: f96f18f3eed96c3ed5b470b43e3302f38ead63fd61b2242cc8b29be6426c44c8
apps, pricing-regulated-caps, ConfigMap (v1) has changed:
-     SKU-0003,20000
+     SKU-0003,1800
```

Ahí estaba el 1.800, una línea antes de cobrarlo, y el aviso de que el pod de `pricing` se reemplaza.

**Con `--three-way-merge`, y no sin él.** Por defecto, helm-diff compara el chart nuevo contra el
manifiesto **guardado en el release**, no contra el cluster. Con una imagen cambiada a mano
(`kubectl set image … pricing=lab/pricing:g1`), los dos dicen cosas distintas:

```text
$ helm diff upgrade lab charts/platform -n apps … --context 2
(fin del diff sin three-way)
$ task deploy:diff -- minimo
apps, pricing, Deployment (apps) has changed:
...
-         image: lab/pricing:g1
+         image: lab/pricing:g3
```

Sin la bandera, nada; con ella, la deriva. `task deploy:diff` la lleva siempre.

### 5.2 Aplicar con red: `--rollback-on-failure`

`task deploy` suma dos banderas desde esta fase:

```bash
helm upgrade --install lab charts/platform -n apps … --wait --timeout 10m \
  --rollback-on-failure --history-max 10
```

`--rollback-on-failure` (el `--atomic` de Helm 3) hace que un despliegue que falla vuelva solo a la
última revisión buena, en lugar de quedar a medias como en la sección 9 de la [Fase 13](13-helm-el-paquete.md#️-9-autopsia-adoptar-los-objetos-para-no-cortar-el-servicio). `--history-max
10` guarda diez revisiones, un `Secret` cada una, y borra las más viejas.

Con un valor inválido —`--set pricing.replicaCount=dos`—, el despliegue falla y se deshace solo:

```text
level=WARN msg="upgrade failed" name=lab error="server-side apply failed for object apps/pricing apps/v1, Kind=Deployment: failed to create typed patch object (apps/pricing; apps/v1, Kind=Deployment): .spec.replicas: expected numeric (int or float), got string"
Error: UPGRADE FAILED: release lab failed, and has been rolled back due to rollback-on-failure being set: …
$ helm -n apps history lab | tail -2
8   …  failed    platform-0.13.0  Upgrade "lab" failed: server-side apply failed for object apps/pricing …
9   …  deployed  platform-0.13.0  Rollback to 7
```

Veinte segundos, y el sistema quedó como estaba. **Casi**: los cuatro `Job` de migraciones de la
revisión 8 corrieron antes de que el `Deployment` fallara.

```text
$ kubectl -n apps get pods -l app.kubernetes.io/component=migration
NAME                      READY   STATUS      RESTARTS   AGE
catalog-migrate-lwfls     0/1     Completed   0          20s
…
```

Hoy no cambian nada. El día que una migración agregue una columna, el rollback devolverá los `Deployment`
y **la columna se quedará**: Helm deshace objetos, y lo que le hicieron a una base no es un objeto.

### 5.3 Volver atrás a mano: `helm rollback`

Para la circular del 1.800, que se desplegó sin fallar, la vuelta es a mano. `helm rollback lab` sin
número vuelve a la revisión anterior:

```text
$ helm -n apps history lab | tail -2
5   …  superseded  platform-0.13.0  Upgrade complete
6   …  deployed    platform-0.13.0  Upgrade complete
$ time helm -n apps rollback lab --wait
Rollback was a success! Happy Helming!
… 1.234 total
$ python3 until.py 20000 60
tope 20000 a los 0.1 s; respuestas vistas: {'20000': 1}
$ helm -n apps history lab | tail -1
7   …  deployed    platform-0.13.0  Rollback to 5
```

Un rollback **es una revisión nueva** (la 7, igual a la 5): la historia queda entera. Y el precio volvió:

```text
$ curl -s 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007'
{"sku":"SKU-0003","store":"DRO-007","price":12900,"currency":"COP","regulatedCap":20000,"capped":false}
```

Volvió porque `pricing` guarda el precio que le mandan y aplica el tope **al responder** (así lo hizo
G1). Un servicio que guardara el precio recortado se habría quedado con 1.800: la misma frontera de 5.2,
vista desde los datos.

> ⚠️ **El rollback devuelve la configuración, no los archivos de valores.** Después de `helm rollback`,
> `values.yaml` sigue diciendo 1.800, y el próximo `task deploy` lo vuelve a desplegar. El rollback
> compra tiempo; la corrección va en el repositorio.

### 5.4 Qué detecta cada capa antes de aplicar

El `replicas: dos` de la sección 5.2 es un error de valor que se ve a simple vista. ¿Quién lo vio antes
de que corrieran las migraciones?

```text
$ helm upgrade … --set pricing.replicaCount=dos --dry-run=server | grep -E 'replicas: dos|Error|STATUS'
STATUS: pending-upgrade
  replicas: dos
$ helm template … --set pricing.replicaCount=dos | kubectl -n apps apply --dry-run=server --server-side --field-manager=helm -f -
Error from server: failed to create typed patch object (apps/pricing; apps/v1, Kind=Deployment): .spec.replicas: expected numeric (int or float), got string
```

`helm template` y los dos `--dry-run` de Helm 4 lo dejaron pasar: el `server` habilita las consultas al
cluster que hacen algunas plantillas, pero no le pide al servidor que valide los objetos. Lo rechaza el
servidor en un *dry-run* de verdad (`kubectl apply --dry-run=server`), el diff de tres vías (con un error
de varias pantallas), o el despliegue mismo, después de los hooks.

La capa que lo detecta **antes de todo** la pone el chart: un **esquema de valores**. Desde esta fase,
`charts/platform/values.schema.json` dice qué tipo tiene cada valor que se toca por perfil o por cadena,
y Helm lo comprueba antes de renderizar:

```text
$ helm template … --set pricing.replicaCount=dos
Error: values don't meet the specifications of the schema(s) in the following chart(s):
platform:
- at '/pricing/replicaCount': got string, want integer
```

| Capa | ¿Detectó `replicas: dos`? | Cuándo |
|---|---|---|
| `values.schema.json` | sí | antes de renderizar, sin cluster |
| `helm template` · `--dry-run=client` · `--dry-run=server` | no | — |
| `task deploy:diff` (con `--three-way-merge`) | sí, con un error ilegible | antes de aplicar |
| `kubectl apply --dry-run=server --server-side` | sí | antes de aplicar |
| `task deploy` | sí | **después de correr las migraciones** |

El esquema también hace cumplir una regla del laboratorio: los hosts terminan en `.localhost`
(`'api.tenant-b.example' does not match pattern '\\.localhost$'`).

### 5.5 Los tres perfiles, en uso real

**`medicion`**, sobre el cluster `minimo`: el mismo release, con otro archivo de valores. El diff lo anuncia:

```text
$ task deploy:diff -- medicion | grep -E 'has been removed|has been added|has changed'
apps, storefront, Deployment (apps) has been removed:
apps, storefront, HTTPRoute (gateway.networking.k8s.io) has been removed:
apps, storefront, Service (v1) has been removed:
apps, storefront-config, ConfigMap (v1) has been removed:
$ task deploy -- medicion
REVISION: 10
$ curl -s -o /dev/null -w '%{http_code}\n' http://storefront.localhost:8080/config.json
404
```

Cambiar de perfil **es** un upgrade: lo que el perfil apaga, Helm lo borra, y `task deploy -- minimo` lo
devuelve (sin el seed, que es `post-install`).

**`lab`**, en su cluster de tres nodos (uno a la vez: los dos publican el 8080 del host, [Fase 07](07-el-cluster-local.md)):

```bash
task cluster:down -- minimo && task cluster:up -- lab
task platform:gateway -- lab && task platform:postgres -- lab && task images:load -- lab
task deploy -- lab
```

```text
$ kubectl --context kind-lab -n apps get pods -o wide --sort-by=.spec.nodeName | awk '{print $1, $3, $7}'
NAME STATUS NODE
catalog-f7f689f78-w92gx Running lab-worker
replenish-6d458f46d-qr9v6 Running lab-worker
inventory-9c87f5648-nb6jz Running lab-worker
pricing-5dc7bcf5f-jwds4 Running lab-worker
pricing-5dc7bcf5f-875s6 Running lab-worker2
…
```

Una réplica de cada backend en cada worker, sin pedirlo: el planificador reparte las de un mismo
`Deployment` cuando puede. La suite de G1 pasó igual (`task conformance TARGET=cluster PROFILE=lab --
G1`). Martha Lucía ya tiene perfiles que se instalan igual dos veces; su costo es el ejercicio 24 de la
[Fase 13](13-helm-el-paquete.md#-ejercicio-24--el-costo-de-cada-perfil).

### 5.6 La segunda cadena

La cuarta pregunta, con lo que ya hay. **Lo que es de plataforma** —un namespace, cuatro bases y sus
credenciales— lo hace `task platform:postgres TENANT=tenant-b`: el namespace de `platform/tenants/`, los
`Secret` de `credentials.py --tenant tenant-b`, y las bases `<svc>_tenant_b` en el Postgres que ya corre,
con SQL que se puede repetir (el `init.sh` solo corre con el disco vacío):

```text
$ task platform:postgres TENANT=tenant-b -- minimo
namespace/apps-b created
secret/pricing-db created
…
$ kubectl -n data exec postgres-0 -- psql -U postgres -Atc "select datname from pg_database where datname like '%tenant_b'"
pricing_tenant_b
inventory_tenant_b
catalog_tenant_b
replenish_tenant_b
```

**Lo que es de la cadena** es un archivo, `charts/platform/values-tenant-b.yaml`:

```yaml
global:
  # Sus propios hosts: con los de La Vecina, las dos cadenas compiten por las mismas rutas en la misma
  # puerta, y gana la ruta más vieja (Fase 14, sección 8).
  hosts:
    api: api.tenant-b.localhost
    storefront: storefront.tenant-b.localhost
storefront:
  brandName: Droguerías Río Negro
# Sus droguerías: cuarenta, en el seed.
seed:
  stores: 40
```

Y `task deploy TENANT=tenant-b -- minimo` instala el mismo chart como release `tenant-b` en `apps-b`, con
ese archivo encima del perfil:

```text
$ task deploy TENANT=tenant-b -- minimo
NAMESPACE: apps-b
STATUS: deployed
REVISION: 1
$ kubectl -n apps-b logs job/seed
sembrado: 8 productos en catalog, 320 precios en pricing (40 droguerías)
$ curl -s http://storefront.localhost:8080/config.json
{"apiBaseUrl":"http://api.localhost:8080","brandName":"Droguerías La Vecina"}
$ curl -s http://storefront.tenant-b.localhost:8080/config.json
{"apiBaseUrl":"http://api.tenant-b.localhost:8080","brandName":"Droguerías Río Negro"}
$ curl -s 'http://api.localhost:8080/pricing/prices?store=DRO-040'
[]
$ curl -s 'http://api.tenant-b.localhost:8080/pricing/prices?store=DRO-040' | head -c 80
[{"sku":"SKU-0001","store":"DRO-040","price":18000,"currency":"COP","regulatedCap":null,…
```

La droguería 40 existe en una cadena y no en la otra, y **ninguna plantilla cambió**. La respuesta a
Germán: *"no se copia el código: se escribe un archivo de valores, y plataforma le da un namespace y sus
bases"*. La letra chica está en la sección 8.

**Al terminar, se apaga**: el perfil `minimo` no la lleva.

```text
$ helm -n apps-b uninstall tenant-b --wait
release "tenant-b" uninstalled
$ kubectl delete namespace apps-b
namespace "apps-b" deleted
```

Las bases `<svc>_tenant_b` se quedan en Postgres: no son del release ni del namespace. La [Fase 15](15-salud-y-recursos.md) vuelve
a encender la cadena para las cuotas.

### 5.7 Kustomize: la otra escuela

Helm resuelve la diferencia entre perfiles con **plantillas**: el YAML con huecos, y valores que los
llenan. Kustomize, que viene dentro de `kubectl` (`Kustomize Version: v5.8.1` en el de la verificación),
la resuelve con **parches**: el YAML plano tal cual, y un archivo que dice qué cambiar.
El mismo perfil `lab` para `pricing` (`deploy/kustomize/lab/kustomization.yaml`):

```yaml
resources:
  - ../../manifests/pricing/deployment.yaml
  - ../../manifests/pricing/service.yaml
  - ../../manifests/pricing/configmap.yaml
patches:
  # Un parche JSON sobre un objeto que ya existe: dos réplicas, como values-lab.yaml.
  - target: {kind: Deployment, name: pricing}
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 2
```

```text
$ kubectl kustomize deploy/kustomize/lab
error: accumulating resources: … security; file '…/deploy/manifests/pricing/deployment.yaml' is not in or below '…/deploy/kustomize/lab'
$ kubectl kustomize --load-restrictor LoadRestrictionsNone deploy/kustomize/lab | grep -E '^kind:|replicas:'
kind: ConfigMap
kind: Service
kind: Deployment
  replicas: 2
```

El error es una opinión de Kustomize: los archivos van debajo de la carpeta que se construye, y un
repositorio pensado para Kustomize organiza así su base y sus *overlays* desde el principio. La
diferencia de fondo: **Kustomize no esconde el YAML**, y no tiene releases, revisiones, rollback ni
hooks: genera, y `kubectl apply -k` aplica. Helm tiene todo eso y lo paga con plantillas. Muchos equipos
usan los dos —Helm para lo de terceros, Kustomize para lo propio—, y ninguno es el correcto.

**Prueba de fuego.** Las dos cadenas encendidas, cada una en su host, con su marca y sus droguerías, y
`task deploy:diff` vacío en las dos.

**El patrón a memorizar.** Antes de aplicar, el diff de tres vías y el esquema; al aplicar, que un fallo
vuelva solo atrás; después, el rollback a mano compra tiempo y el arreglo va al repositorio. Y lo que
Helm deshace son objetos: los datos y las migraciones, no.

---

## 🔁 6. Los otros tres: donde no es mecánico

En operación, los cuatro backends se comportan igual ante Helm: un upgrade reemplaza sus pods y un
rollback también. Lo que cambia es **cuánto tarda** cada uno en estar listo detrás de un `--wait`, y eso es lo
que hace largo un despliegue y lento un rollback. Con la readiness trivial de hoy, el `--wait` ni
siquiera sabe cuándo están listos de verdad: lo arregla la [Fase 15](15-salud-y-recursos.md).

**`catalog`**: un cambio en su `nginx.conf` reemplaza el pod entero, PHP incluido. **`storefront`**: el
único que `medicion` apaga y el único cuya configuración cambia por cadena.

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto, en su mejor versión: *"si sale mal, `rollback` y quedo como estaba"*. En compose era
`git revert` y `up -d`, y funcionaba porque el estado era el del archivo.

> 🪞 **Apuesta antes de ejecutar.** Un `helm rollback` de un cambio de tope deja el precio viejo en
> menos de 30 s, sin tocar nada a mano.
>
> **Resultado: ganada, con letra chica.** 1,2 s, y el tope volvió al instante (5.3). La letra chica: el
> precio volvió porque `pricing` aplica el tope al responder; las migraciones de una revisión fallida se
> quedaron (5.2); `values.yaml` siguió diciendo 1.800; y el rollback **también puede fallar**: con una
> imagen cambiada a mano, chocó con `kubectl-set` igual que el despliegue:

```text
level=WARN msg="Rollback \"lab\" failed: conflict occurred while applying object apps/pricing apps/v1, Kind=Deployment: Apply failed with 1 conflict: conflict with \"kubectl-set\" using apps/v1: .spec.template.spec.containers[name=\"pricing\"].image"
$ helm -n apps history lab | tail -2
3  …  superseded  platform-0.13.0  Upgrade "lab" failed: conflict occurred while applying object apps/pricing …
4  …  failed      platform-0.13.0  Rollback "lab" failed: conflict occurred while applying object apps/pricing …
```

Un rollback es otro despliegue, y falla por lo mismo que cualquier despliegue. La entrada completa está
en [INSTINTOS.md](INSTINTOS.md#si-sale-mal-rollback-y-quedo-como-estaba).

> 🪞 **Apuesta antes de ejecutar.** `tenant-b` en `apps-b` se instala con un archivo de valores y sin
> tocar una plantilla, y suma a la máquina virtual menos de 400 MiB (los cinco servicios de G1 sumaron
> 295 MiB en `a01`; con Postgres compartido, la segunda cadena no suma otro Postgres).
>
> **Resultado: ganada.**

> 📏 **La segunda cadena, en la máquina virtual** · perfil `minimo`, con el release `lab` y Postgres ya
> corriendo, sin patrimonio ni observabilidad · Docker Desktop 4.92.0 (Engine 29.8.0), máquina virtual
> de 4 GiB · kind 0.33.0, nodo 1.36.4 · MacBook Pro M1 Pro, 32 GB, macOS · 3 corridas: desinstalar,
> 60 s, leer; instalar, 60 s, leer · verificado el 03/10/2026
>
> | | MiB |
> |---|---|
> | lo que sube la máquina virtual con `tenant-b` | 212 (191–227) |
> | máquina virtual usada con las dos cadenas | 2.831–2.901, de 3.916 |
> | `task deploy TENANT=tenant-b` hasta listo (s) | 25 (23–25) |
>
> Reproducir: con `minimo` y el release `lab` arriba, `task platform:postgres TENANT=tenant-b -- minimo`,
> y medir `MemTotal − MemAvailable` del nodo antes y 60 s después de `task deploy TENANT=tenant-b -- minimo`
> ([a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)).

Menos que los 295 MiB de G1, sin que se separaran las razones (la máquina ya venía trabajando; no hay
segundo Postgres). Con dos cadenas queda algo más de 1 GiB libre: el patrimonio, unos 800 MiB, ya no
entraría cómodo encima.

---

## 🧨 8. La rotura: la segunda cadena que se queda con el tráfico

La primera versión de `values-tenant-b.yaml` no tenía hosts. Parecía bien: *"solo lo que la cadena
cambia"*, la marca y las droguerías. **El cambio exacto:** el archivo sin la sección `global.hosts`.

```text
$ task deploy TENANT=tenant-b -- minimo
STATUS: deployed
$ kubectl -n apps-b get httproute pricing -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
Accepted=True Accepted
ResolvedRefs=True ResolvedRefs
RouteRulesOverlap=True RouteRulesOverlap
$ curl -s http://storefront.localhost:8080/config.json
{"apiBaseUrl":"http://api.localhost:8080","brandName":"Droguerías La Vecina"}
```

**El síntoma: ninguno.** Release `deployed`, pods `Running`, seed con cuarenta droguerías, rutas
`Accepted=True`. La única pista es `RouteRulesOverlap=True` en las rutas de **las dos** cadenas: mismo
host y mismo prefijo en la misma puerta. Gateway API resuelve el empate a favor de la ruta más vieja, y
la de La Vecina lo es: la segunda cadena está instalada, sembrada, y no le llega una sola petición.

Hasta que la ruta de La Vecina deja de ser la más vieja. Basta con que se recree —un `kubectl delete`
por error, un `uninstall` y un `install` para arreglar otra cosa—:

```text
$ kubectl get httproute -A -l app.kubernetes.io/name=storefront -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CREATED:.metadata.creationTimestamp
NS       NAME         CREATED
apps-b   storefront   2026-10-04T04:46:43Z
apps     storefront   2026-10-04T04:47:20Z
$ curl -s http://storefront.localhost:8080/config.json
{"apiBaseUrl":"http://api.localhost:8080","brandName":"Droguerías Río Negro"}
```

**Los clientes de La Vecina viendo la página de la otra cadena**, que además le pide precios al API de
La Vecina, porque las rutas del API siguen ganando las viejas. Nadie desplegó nada en `apps-b`.

**Para salir:** cada cadena con sus hosts. El diff lo dice antes de aplicar:

```text
$ helm diff upgrade tenant-b charts/platform -n apps-b … -f charts/platform/values-tenant-b.yaml …
apps-b, catalog, HTTPRoute (gateway.networking.k8s.io) has changed:
-   hostnames: ["api.localhost"]
+   hostnames: ["api.tenant-b.localhost"]
-             allowOrigins: ["http://storefront.localhost:8080"]
+             allowOrigins: ["http://storefront.tenant-b.localhost:8080"]
…
apps-b, storefront-config, ConfigMap (v1) has changed:
-   API_BASE_URL: "http://api.localhost:8080"
+   API_BASE_URL: "http://api.tenant-b.localhost:8080"
```

Y las rutas de `apps` vuelven a tener solo `Accepted=True` y `ResolvedRefs=True`. La lección es de
multi-cadena, no de Helm: **dos releases en dos namespaces no son dos sistemas si comparten la puerta.**
El namespace separa nombres, no hosts; la puerta es del cluster. La [Fase 20](20-seguridad-del-pod-y-de-la-red.md) cierra lo que la red no
separa.

---

## ⚰️ 9. Autopsia: confiar en el rollback como única red

**La decisión, con su mejor argumento.** Desplegar sin diff previo, con `--rollback-on-failure`: *"si
algo falla, vuelve solo; para qué revisar lo que se deshace en veinte segundos."* Es la conclusión
natural después de la [Fase 13](13-helm-el-paquete.md#️-9-autopsia-adoptar-los-objetos-para-no-cortar-el-servicio), donde el despliegue a medias fue el problema.

**Por qué era razonable.** La bandera hace lo que promete: el `replicas: dos` volvió solo en veinte
segundos.

**Qué pasó después, con número.** Tres casos en esta misma fase. La circular del 1.800 se desplegó sin
fallar: `--rollback-on-failure` no la tocó, porque no falló nada (sección 4). El `replicas: dos` dejó
sus cuatro migraciones aplicadas antes de volver (5.2). Y con una imagen cambiada a mano, el rollback
automático falló igual que el despliegue, y dejó el release en `failed` con la imagen equivocada
corriendo (sección 7). **De tres errores, la bandera arregló uno, y a medias.**

**Cuánto cuesta salir, con número.** Lo que faltaba no es caro: `task deploy:diff` antes de cada
despliegue (unos segundos), el esquema de valores (un archivo de un centenar de líneas que rechaza el `dos` sin
cluster), y `FORCE=true` solo después de leer quién es el dueño del conflicto.

**Qué lo habría cambiado.** La pregunta *¿qué clase de error atrapa esta red?* `--rollback-on-failure`
atrapa los errores que Kubernetes rechaza. El esquema atrapa los que tienen forma de dato inválido. El
diff atrapa los que solo una persona reconoce —un cero de menos—. Ninguno atrapa los tres.

**Antes y después, con números:** con solo la bandera, 1 de 3 errores deshecho; con diff, esquema y
bandera, los 3 vistos antes de llegar a una caja.

---

## 📖 10. Traducción

| En compose | Con Helm | Lo que cambia |
|---|---|---|
| `git diff` antes de `up -d` | `task deploy:diff` (helm-diff con `--three-way-merge`) | compara contra el cluster, no contra el archivo |
| `git revert` y `up -d` | `helm rollback` | una revisión nueva que repite una vieja; el archivo de valores no cambia |
| `docker compose config` que falla por un tipo | `values.schema.json` | el esquema lo escribe el chart; compose valida su propio formato |
| dos proyectos con `-p` | dos releases en dos namespaces | comparten la puerta: las rutas compiten |
| `compose.override.yaml` | Kustomize (`kubectl kustomize`, `apply -k`) | parches sobre YAML plano, sin releases ni rollback |

Y de vuelta: `--rollback-on-failure` no tiene traducción en compose, que no sabe cuál fue la última
versión buena. Las filas completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, la segunda cadena suma además un dominio y un certificado ([Fase 19](19-tls-y-certificados.md)). 🚧 Lo que el
laboratorio no da: facturar, dar soporte y actualizar a cada cadena por separado.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**La red de seguridad cuesta pasos**: tres cosas que leer y mantener. En un sistema que despliega una
vez al mes y tiene una sola instalación, `git diff`, YAML plano y `kubectl apply` alcanzan, y un rollback
es un `git revert`.

**El rollback no es una máquina del tiempo.** Devuelve objetos; las migraciones, los datos y los
mensajes se quedan.

**La segunda cadena con un archivo de valores es multi-cadena de laboratorio.** Comparte cluster,
puerta, Postgres y la persona que opera. Sirve para contestar *"¿hay que copiar el código?"* —no— y no
para contestar *"¿le podemos vender esto a Don Rodrigo?"*. Lo que falta (cuotas, aislamiento de red,
identidad, datos separados de verdad) lo van poniendo las Fases 15 y 20, y lo que un SaaS necesita
además queda fuera del curso. Y suma 212 MiB por cadena en 4 GiB: tres cadenas más el patrimonio ya no
entran.

**GitOps** —un repositorio que el cluster sigue solo, con Argo CD o Flux— es el paso siguiente, y tiene
su apéndice de lectura, [a11](a11-gitops-de-lectura.md): exige un repositorio accesible desde el cluster y un controlador más.

**La pregunta del curso, para esta fase:** el contenedor no cambió. El orquestador te dio un servidor que
valida y una puerta compartida que resuelve empates. Helm te dio el diff, la historia y el rollback.
**Te tocó a ti** el esquema, la disciplina de mirar el diff, los hosts de cada cadena, y saber que los
datos no vuelven.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`task deploy:diff` no muestra nada y el cluster está distinto.** Causa: un diff sin
`--three-way-merge`, que compara contra el release. Comprobación 🩺: `helm diff upgrade … --three-way-merge`.

**`Rollback "lab" failed: conflict …`.** Causa: lo mismo que hizo fallar el despliegue (sección 7).
Salida: averiguar al dueño en `managedFields` y, si se decide, `task deploy FORCE=true`.

**La segunda cadena no responde y todo dice `Running`.** La sección 8: `RouteRulesOverlap` y los hosts.

**`conflict with "kubectl" with subresource "scale"` después de un `kubectl scale`.** Escalar a mano
también le quita a Helm el campo `replicas`: el despliegue falla, y el rollback automático con él. Salida:
el número de réplicas va en el archivo de valores del perfil, y `task deploy FORCE=true` una vez. (El
autoescalado de la [Fase 16](16-escalado-y-rollout.md) hace lo mismo que `kubectl scale`, y por eso esa fase decide quién es dueño de
las réplicas.)

**`values don't meet the specifications of the schema(s)`.** El esquema haciendo su trabajo: lee la ruta
y el tipo esperado.

---

## 📋 14. Checklist de validación

```text
[ ] task deploy:diff con un cambio de tope: el ConfigMap y el hash del pod
[ ] la deriva a mano: invisible sin --three-way-merge, visible con él
[ ] replicas: dos rechazado por el esquema; y sin él, deshecho por --rollback-on-failure
[ ] la circular equivocada desplegada y deshecha con helm rollback, con el tiempo medido
[ ] el rollback que falla por un conflicto, y la revisión en failed
[ ] task deploy -- medicion sin storefront, y de vuelta a minimo
[ ] task deploy -- lab en el cluster lab: una réplica de cada backend en cada worker; G1 en verde
[ ] tenant-b sin hosts: RouteRulesOverlap y el tráfico robado al recrear la ruta de apps
[ ] tenant-b con sus hosts: dos marcas, DRO-040 solo en la suya; la memoria que suma
[ ] tenant-b apagado; sus bases todavía en Postgres
[ ] kubectl kustomize con el parche de dos réplicas
```

---

## 🧪 15. Ejercicios (20)

Un tercio son de diagnóstico; varios trabajan con la segunda cadena o con `catalog`.

## 🟢 Fácil — la red (1–6)

### 🟢 Ejercicio 1 — Ver antes
Cambia la marca del `storefront` en `values.yaml` y mira el diff antes de desplegar.

**Criterio:** el diff muestra `storefront-config` y el hash del `Deployment` del `storefront`, y nada más.

<details><summary>Solución</summary>

`task deploy:diff -- minimo`. Si aparece algo más, alguien cambió el cluster a mano.
</details>

### 🟢 Ejercicio 2 — La historia
Lista la historia del release y explica cada estado que aparece.

**Criterio:** al menos `deployed`, `superseded` y, si tienes, `failed`.

<details><summary>Solución</summary>

`helm -n apps history lab`. `deployed` es la que corre; `superseded`, una que fue reemplazada; `failed`,
una que no terminó (y si después dice `Rollback to N`, Helm volvió).
</details>

### 🟢 Ejercicio 3 — Volver
Despliega un tope distinto y vuelve a la revisión anterior.

**Criterio:** el tope viejo en `GET /pricing/prices/SKU-0003?store=DRO-007`, y una revisión nueva con `Rollback to N`.

<details><summary>Solución</summary>

`task deploy -- minimo` con el valor cambiado, `helm -n apps rollback lab --wait`, y el `curl`. Devuelve
el valor en `values.yaml` antes del próximo despliegue.
</details>

### 🟢 Ejercicio 4 — El esquema
Intenta desplegar con `--set catalog.replicaCount=-1`.

**Criterio:** el error del esquema, sin que corra ninguna migración.

<details><summary>Solución</summary>

`minimum: 0` en `values.schema.json`: `at '/catalog/replicaCount': minimum: got -1, want 0`. Ningún pod
de migración nuevo en `kubectl -n apps get pods`.
</details>

### 🟢 Ejercicio 5 — El perfil de medición
Pasa a `medicion` y vuelve a `minimo`, mirando el diff en cada paso.

**Criterio:** cuatro objetos del `storefront` borrados y después creados.

<details><summary>Solución</summary>

`task deploy:diff -- medicion`, `task deploy -- medicion`, `task deploy:diff -- minimo`, `task deploy -- minimo`.
</details>

### 🟢 Ejercicio 6 — Kustomize
Construye el overlay de `deploy/kustomize/lab` y cuenta las réplicas.

**Criterio:** `replicas: 2` en el `Deployment` de `pricing`.

<details><summary>Solución</summary>

`kubectl kustomize --load-restrictor LoadRestrictionsNone deploy/kustomize/lab`.
</details>

## 🟡 Intermedio — la segunda cadena (7–12)

### 🟡 Ejercicio 7 — La cadena de cero
Enciende la segunda cadena en un cluster `minimo` nuevo.

**Criterio:** `http://storefront.tenant-b.localhost:8080/config.json` con su marca, y 320 precios en su seed.

<details><summary>Solución</summary>

`task platform:postgres TENANT=tenant-b -- minimo` y `task deploy TENANT=tenant-b -- minimo`.
</details>

### 🟡 Ejercicio 8 — Un tope solo para la otra cadena
Haz que `tenant-b` tenga otro tope para `SKU-0003` sin cambiar el de La Vecina.

**Criterio:** los dos API responden topes distintos.

<details><summary>Solución</summary>

`pricing.regulatedCap.caps` en `values-tenant-b.yaml`. Antes de hacerlo de verdad, recuerda que la
regulación es nacional: lo que este ejercicio demuestra es que se puede, no que se deba.
</details>

### 🟡 Ejercicio 9 — `catalog` con dos réplicas en la otra cadena
Sube `catalog` a dos réplicas solo en `tenant-b`.

**Criterio:** `kubectl -n apps-b get deploy catalog` con 2/2, y `apps` con 1/1.

<details><summary>Solución</summary>

`catalog: {replicaCount: 2}` en `values-tenant-b.yaml` y `task deploy TENANT=tenant-b -- minimo`.
</details>

### 🟡 Ejercicio 10 — ¿Quién ve qué base?
Desde un pod de `apps-b`, intenta conectarte a la base `pricing` de La Vecina con la credencial de la
otra cadena. **Predice** el error.

**Criterio:** la predicción y el error literal.

<details><summary>Solución</summary>

`permission denied for database "pricing"` y `User does not have CONNECT privilege`, por el `REVOKE ALL …
FROM PUBLIC`: el mismo de la [Fase 12](12-estado-y-almacenamiento.md). La red sí la deja llegar a Postgres; eso es la [Fase 20](20-seguridad-del-pod-y-de-la-red.md).
</details>

### 🟡 Ejercicio 11 — Apagar sin perder
Desinstala `tenant-b` y vuelve a instalarlo. **Predice** cuántos precios ve.

**Criterio:** la predicción y el conteo después.

<details><summary>Solución</summary>

Los mismos: las bases `<svc>_tenant_b` no son del release, y el seed vuelve a correr (`post-install`) sin
duplicar nada.
</details>

### 🟡 Ejercicio 12 — El perfil lab, con otra cuenta
Cambia `values-lab.yaml` para que `inventory` tenga tres réplicas, y mira en qué nodos quedan.

**Criterio:** tres pods de `inventory` y su `NODE`.

<details><summary>Solución</summary>

`kubectl --context kind-lab -n apps get pods -o wide -l app.kubernetes.io/name=inventory`: en la
verificación, dos en `lab-worker` y uno en `lab-worker2`. Ninguno en el control-plane, que tiene la marca
`node-role.kubernetes.io/control-plane:NoSchedule` (`kubectl describe node lab-control-plane`). El
reparto parejo no está garantizado sin reglas: es la [Fase 16](16-escalado-y-rollout.md).
</details>

## 🟠 Difícil — diagnosticar (13–17)

### 🟠 Ejercicio 13 — La ruta robada
Reproduce la sección 8 y diagnostícala sin mirar la fase: alguien te dice que la página de La Vecina
muestra otra marca.

**Criterio:** la causa, y el comando que la confirmó.

**Rúbrica:** las dos rutas con el mismo host; `RouteRulesOverlap`; las fechas de creación; y la regla de
precedencia de Gateway API.

### 🟠 Ejercicio 14 — El rollback que no puede
Provoca un despliegue que falla y cuyo rollback automático también falla. Sácalo de `failed`.

**Criterio:** el release en `deployed` con la imagen del chart.

**Rúbrica:** el conflicto de `managedFields`; `task deploy FORCE=true`; y por qué `helm rollback` a mano
fallaría igual.

### 🟠 Ejercicio 15 — La migración que no vuelve
Agrega a `replenish` una migración que crea una columna, despliega, y haz rollback. **Predice** qué queda
en la base.

**Criterio:** la predicción y `\d` de la tabla después del rollback.

**Rúbrica:** la columna sigue; por qué el código viejo la tolera (o no); y qué haría falta para que un
rollback de esquema sea seguro (migraciones compatibles hacia atrás, en dos pasos).

### 🟠 Ejercicio 16 — El diff que no avisa
Edita a mano el `ConfigMap` de topes y corre el diff con y sin `--three-way-merge`.

**Criterio:** las dos salidas, y cuál dice la verdad.

**Rúbrica:** el release no sabe del cambio a mano; el de tres vías compara con lo vivo; y por qué el
incidente 09 vuelve aunque exista el hash.

### 🟠 Ejercicio 17 — ¿Qué atrapa cada capa?
Arma tres cambios equivocados —un tipo inválido, una imagen que no existe, un valor de negocio absurdo—
y di qué capa atrapa cada uno.

**Criterio:** una tabla con los tres cambios y las cinco capas de la sección 5.4.

**Rúbrica:** el esquema, el tipo; el despliegue con rollback, la imagen (con el hook bloqueado); nadie, el
valor de negocio, salvo una persona leyendo el diff.

## 🔴 Muy difícil — operar en serio (18–20)

### 🔴 Ejercicio 18 — Una tercera cadena
Agrega `tenant-c` sin tocar ninguna plantilla. **Predice** la memoria que queda.

**Criterio:** tres cadenas respondiendo en sus hosts, o la evidencia de por qué no entran.

**Rúbrica:** lo que hay que tocar fuera del chart (namespace, bases, el `allowedRoutes` del `Gateway`, el
mapa de `credentials.py`, el Taskfile); la medición; y la decisión si no entra en 4 GiB.

### 🔴 Ejercicio 19 — El mismo perfil con Kustomize, entero
Lleva el perfil `lab` de los cinco servicios a Kustomize, sin `--load-restrictor`.

**Criterio:** `kubectl apply -k` produce lo mismo que `task deploy -- lab` en réplicas, imágenes y rutas.

**Rúbrica:** una base con su `kustomization.yaml` junto al YAML plano (y qué rompe eso en `kubectl apply
-R`); los hooks que no existen (las migraciones vuelven a ser una tarea); y qué se perdió: historia,
rollback, esquema.

### 🔴 Ejercicio 20 — GitOps a mano
Sin instalar nada, escribe un script que cada minuto compare `git` con el cluster (`task deploy:diff`) y
avise si hay diferencias.

**Criterio:** el aviso aparece cuando alguien hace `kubectl set image`.

**Rúbrica:** `--detailed-exitcode` de helm-diff; qué falta para que sea GitOps de verdad (que aplique, con
qué credenciales, desde dónde); y por qué eso es un controlador en el cluster y no un script en tu
portátil.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Helm, `helm rollback`: https://helm.sh/docs/helm/helm_rollback/ y `helm history`: https://helm.sh/docs/helm/helm_history/
- Helm, `helm upgrade`, con `--rollback-on-failure`, `--history-max` y `--dry-run`: https://helm.sh/docs/helm/helm_upgrade/
- Helm, *Charts*, la sección de los archivos de esquema (`values.schema.json`): https://helm.sh/docs/topics/charts/
- helm-diff, el plugin, con `--three-way-merge`: https://github.com/databus23/helm-diff
- Gateway API, la referencia de la API, con la precedencia entre rutas ("the oldest Route based on
  creation timestamp"): https://gateway-api.sigs.k8s.io/reference/api-spec/main/ (es la rama principal;
  la regla está igual en la versión del curso)
- Kubernetes, *Declarative Management of Kubernetes Objects Using Kustomize*:
  https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
- Kustomize, la referencia: https://kubectl.docs.kubernetes.io/references/kustomize/
- Argo CD: https://argo-cd.readthedocs.io/en/stable/ · Flux: https://fluxcd.io/flux/ — para leer qué es GitOps
  antes de [a11](a11-gitops-de-lectura.md).

**Libros**

- Betsy Beyer, Chris Jones, Jennifer Petoff y Niall Richard Murphy (eds.), *Site Reliability Engineering*
  (2016), el capítulo de ingeniería de versiones (*Release Engineering*): https://sre.google/sre-book/table-of-contents/

**Orden de lectura sugerido:** antes, `helm rollback`; durante, helm-diff y la precedencia de Gateway API
con la sección 8 delante; después, el capítulo de SRE.

> ⚠️ Las URL y los contenidos cambian. La referencia de Gateway API enlazada es la rama principal, no la
> versión exacta del curso.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 14 (perfil lab; minimo para lo demás)

  task deploy -- minimo|lab|medicion   helm upgrade --install … --wait --rollback-on-failure --history-max 10
  task deploy:diff -- <perfil>         helm diff upgrade … --three-way-merge
  charts/platform/values.schema.json   tipos de réplicas, hosts (.localhost), seed
  charts/platform/values-tenant-b.yaml la segunda cadena: hosts, marca, cuarenta droguerías
  task platform:postgres TENANT=tenant-b   namespace apps-b, Secret y bases <svc>_tenant_b
  deploy/kustomize/lab/                el perfil lab de pricing con Kustomize, para comparar

  apps-b    apagado al cerrar (las bases <svc>_tenant_b quedan en Postgres)
```

> **La señal de que quedó bien:** *"Antes de desplegar miro el diff de tres vías; si falla, vuelve solo;
> si sale mal sin fallar, hago rollback y corrijo el archivo. Y sé que una segunda cadena es un archivo de
> valores, un namespace, sus bases y sus propios hosts."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-14-helm-en-operacion -m "F14 cerrada: deploy:diff con three-way-merge; --rollback-on-failure y --history-max; values.schema.json; los tres perfiles en uso; tenant-b en apps-b con su archivo de valores, sus bases y sus hosts; Kustomize para comparar"
> ```
>
> Commits con prefijo `f14:` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F15:** las cuotas por namespace con las dos cadenas encendidas; el tiempo hasta listo de cada
  servicio detrás de `--wait` (sección 6).
- **F20:** la `NetworkPolicy` entre `apps` y `apps-b`, y la misma puerta: lo que la red no separa.
- **`a11`:** el ejercicio 20 como puente.
- **T15 (README):** la segunda cadena como respuesta a la cuarta pregunta del encargo.
