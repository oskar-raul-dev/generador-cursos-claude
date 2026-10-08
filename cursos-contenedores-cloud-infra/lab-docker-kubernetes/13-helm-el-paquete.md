# 📦 Fase 13 — Helm: el paquete: veinticuatro archivos casi iguales, y el release que los recuerda

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 13 de 27 · Parte II — El despliegue · **densa**
> **Perfil:** `minimo`; `lab` y `medicion`, solo renderizados · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: Helm le habla al cluster, no al motor
> **Servicios que toca:** los cinco, y el seed · **Paso de generación:** ninguno
> **Depende de:** [Fase 12](12-estado-y-almacenamiento.md) · **Habilita:** [Fase 14](14-helm-en-operacion.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64
> **Objetivo:** que el sistema entero se instale con un comando y un archivo de valores por perfil, que el chart produzca exactamente lo que producía el YAML plano —con cada diferencia explicada—, y que las migraciones y el seed corran solos, en su orden, como parte de la instalación.

---

## 🧭 1. Dónde estamos

La [Fase 12](12-estado-y-almacenamiento.md) cerró la tesis del almacenamiento: cada servicio en su
base, las migraciones como `Job` antes del rollout, el seed por la API. Para llegar ahí, `task deploy`
hace tres cosas en orden —aplica el namespace, corre `task migrate` y aplica `deploy/manifests/`— y el
seed es otra tarea aparte. Funciona. Son veinticuatro archivos de YAML y cuatro pasos que alguien tiene
que recordar.

Martha Lucía Cáceres, la vicepresidenta financiera, pidió lo que pide siempre: el número. Valentina le
había mostrado el sistema en el perfil `minimo` y le había dicho que para medir el escalado hacía falta
el perfil `lab`, con más nodos y más réplicas.

> *"Valentina, no me diga que depende. ¿Cuánto cuesta el chiquito y cuánto cuesta el grande? Y que el
> grande sea el mismo grande la próxima vez que me lo muestre, no el que usted se acuerde."*

La segunda frase es la que duele. El perfil `minimo` está escrito: es lo que dice el repositorio. El
perfil `lab`, hoy, es lo que alguien escaló a mano con `kubectl scale` la última vez. Y el perfil
`medicion` no existe en ningún archivo. Esta fase hace de los tres algo que se instala igual dos veces,
y del sistema entero un paquete: **un chart**.

---

## 🎯 2. Objetivos de esta fase

1. Contar el dolor en tu propio repositorio: cuántos archivos, cuántas líneas repetidas, y qué pasa con
   un perfil hecho a mano.
2. Construir el chart paraguas `charts/platform/` con un subchart por servicio y una librería de
   plantillas compartidas, y los tres perfiles como archivos de valores.
3. Demostrar que el chart produce lo mismo que el YAML plano: `task chart:compare` lista cada
   diferencia, y cada una tiene su explicación; la suite de G1 y la de G2 pasan igual.
4. Pasar las migraciones y el seed a *hooks*, y ver qué hace un hook que no puede correr.
5. Mudar el sistema del YAML aplicado a mano a un release, y saber por qué la mudanza conviene hacerla
   borrando y reinstalando.

---

## 🚫 3. Qué NO entra todavía

- `upgrade`, `rollback`, `--dry-run` y el *diff* como red de seguridad → [Fase 14](14-helm-en-operacion.md).
- La segunda cadena (`tenant-b` en `apps-b`) → [Fase 14](14-helm-en-operacion.md). El chart ya la permite, y esta fase no la instala.
- Kustomize, la otra escuela → [Fase 14](14-helm-en-operacion.md), sección corta.
- `--rollback-on-failure` como regla de `task deploy` → [Fase 14](14-helm-en-operacion.md). Aquí se ve una vez, en la sección 8.
- Lo que encienden los interruptores de observabilidad → [Fase 17](17-metricas-y-dashboards.md); los del bus → Parte IV.
- Publicar el chart en un registry y versionarlo como producto: fuera del curso.

---

## 🧨 4. El problema, en el laboratorio

Cuenta tus archivos. Desde `src/lab/`, en el estado del tag de la [Fase 12](12-estado-y-almacenamiento.md):

```text
$ find deploy/manifests deploy/jobs -name '*.yaml' -not -path '*/experimentos/*' | wc -l
      24
```

Veinticuatro archivos. Ahora, cuántas de sus líneas son la misma línea con otro nombre. El script compara
el `Deployment`, el `Service`, la `HTTPRoute` y el `Job` de migraciones de cada backend con los de
`pricing`, sin comentarios y con el nombre del servicio reemplazado por un comodín:

```text
deployment  pricing     46 líneas,  46 iguales a pricing salvo el nombre
deployment  inventory   36 líneas,  36 iguales a pricing salvo el nombre
deployment  catalog     46 líneas,  38 iguales a pricing salvo el nombre
deployment  replenish   36 líneas,  36 iguales a pricing salvo el nombre
service     pricing     17 líneas,  17 iguales a pricing salvo el nombre
service     inventory   17 líneas,  17 iguales a pricing salvo el nombre
…
migrate     replenish   29 líneas,  28 iguales a pricing salvo el nombre
total 444 líneas sin comentarios; 429 iguales a las de pricing salvo el nombre (96 %)
```

El 96 %. Cuando la [Fase 12](12-estado-y-almacenamiento.md) agregó `DATABASE_URL`, fueron cuatro ediciones idénticas; cuando la [Fase 15](15-salud-y-recursos.md)
agregue sondas, serán cuatro más.

Y el perfil. El `lab` necesita dos réplicas de cada backend. A mano:

```text
$ kubectl -n apps scale deploy/pricing deploy/inventory --replicas=2
deployment.apps/pricing scaled
deployment.apps/inventory scaled
$ kubectl apply -R -f deploy/manifests/ | grep -v unchanged
…
deployment.apps/inventory configured
deployment.apps/pricing configured
…
$ kubectl -n apps get deploy pricing inventory
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
pricing     1/1     1            1           2m6s
inventory   1/1     1            1           2m6s
```

El siguiente `task deploy` devolvió las réplicas a 1, porque el archivo dice 1. El perfil `lab` no
sobrevive a un despliegue; para que sobreviva hay que escribirlo, y con YAML plano escribirlo es copiar
los cinco `Deployment` a otra carpeta con un número distinto. **Tres perfiles, cuatro servicios: doce
`Deployment` casi iguales**, y la próxima variable de entorno, en doce sitios.

> 🩻 **Esto sí funciona igual.** Lo que hacías en compose con un `compose.override.yaml` o con varios
> `-f` —un archivo base y otro que solo dice lo que cambia— es exactamente la idea. Lo que compose no
> tiene es la plantilla: su archivo de override reemplaza claves, no las calcula.

---

## 📦 5. El chart, con `pricing`

### 5.1 Una plantilla es el YAML con huecos

Un **chart** es una carpeta con tres cosas: un `Chart.yaml` que lo nombra y lo versiona, unas
**plantillas** en `templates/`, que son YAML con huecos escritos en el lenguaje de plantillas de Go, y
un `values.yaml` con los valores por defecto de esos huecos. Helm junta plantillas y valores, produce
YAML, y se lo da al cluster.

El `Deployment` de `pricing` como plantilla (`charts/platform/charts/pricing/templates/deployment.yaml`)
es el de la [Fase 12](12-estado-y-almacenamiento.md) con cinco huecos:

```yaml
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "lab-common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "lab-common.podLabels" . | nindent 8 }}
      annotations:
        # El hash de la tabla de topes: si la tabla cambia, cambia el pod, y el Deployment lo reemplaza.
        checksum/regulated-caps: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
    spec:
      containers:
        - name: pricing
          image: {{ include "lab-common.image" . }}
          imagePullPolicy: {{ .Values.global.imagePullPolicy }}
          …
          env:
            {{- include "lab-common.databaseEnv" . | nindent 12 }}
            - name: REGULATED_CAP_ENABLED
              value: {{ .Values.regulatedCap.enabled | quote }}
```

`{{ .Values.replicaCount }}` se reemplaza por un valor; `{{ include "…" . }}` inserta otra plantilla con
nombre, y `nindent 6` la indenta seis espacios (el error más común: un YAML bien armado y mal indentado).
`helm template` muestra lo que sale sin tocar el cluster, y la primera vez, sin los tags, falla a propósito:

```text
Error: execution error at (platform/charts/storefront/templates/deployment.yaml:22:20): falta storefront.image.tag: el tag del paso (task deploy lo toma de STEP_TAGS)
```

El tag no tiene valor por defecto en el chart: desde la [Fase 11](11-configuracion-y-secretos.md) vive en `STEP_TAGS` del Taskfile, y
`task deploy` lo pasa como `--set <svc>.image.tag=…`. Un segundo lugar para el mismo dato terminaría
separándose; `required` convierte la ausencia en un error con instrucciones.

### 5.2 El paraguas, los subcharts y una librería

El chart del sistema es un **chart paraguas**: `charts/platform/` no tiene un `Deployment` propio; tiene
un subchart por servicio en `charts/platform/charts/`, declarado como dependencia en su `Chart.yaml`:

```yaml
dependencies:
  # Las plantillas compartidas. Una librería no crea ningún objeto por sí sola.
  - name: lab-common
    version: 0.13.0
  # Los subcharts viven en charts/ (no se descargan de ningún repositorio). La condición es el
  # interruptor de cada servicio: <svc>.enabled en los valores.
  - name: pricing
    version: 0.13.0
    condition: pricing.enabled
  …
```

```text
charts/platform/
├── Chart.yaml                 el paraguas: nombre, versión y dependencias
├── values.yaml                lo que vale para cualquier perfil y cualquier cadena
├── values-minimo.yaml         lo que cambia el perfil minimo (nada)
├── values-lab.yaml            lo que cambia el perfil lab (las réplicas)
├── values-medicion.yaml       lo que cambia el perfil medicion (sin página ni seed)
├── templates/                 lo que es del sistema: neighbors, el Job del seed y las notas
└── charts/
    ├── lab-common/            librería: labels, imagen, Service, HTTPRoute, Job de migraciones
    ├── pricing/               su Deployment, su tabla de topes y tres líneas que incluyen la librería
    ├── inventory/  replenish/  storefront/
    └── catalog/               su Deployment de dos contenedores y su nginx.conf
```

**`lab-common` es lo que ataca el 96 %.** Es un chart de tipo `library`: no crea objetos, solo define
plantillas con nombre. El `Service`, la `HTTPRoute` y el `Job` de migraciones son idénticos salvo el
nombre, y en cada servicio quedan en una línea:

```yaml
{{ include "lab-common.service" . }}
```

Dentro de la plantilla, `.Chart.Name` es el nombre del subchart que la incluye: `pricing` en un sitio,
`replenish` en otro.

> 🧠 **Los nombres de las plantillas son globales.** Helm carga las plantillas del paraguas y de sus
> subcharts en un solo espacio de nombres: por eso los cinco hermanos usan `lab-common`, que es
> dependencia del paraguas y no de ellos. El precio: un subchart **no se instala solo**, y dos `define
> "labels"` en dos subcharts se pisan sin aviso. De ahí el prefijo (`lab-common.labels`).

El `Deployment` **no** va en la librería, y es deliberado. Es donde los servicios difieren —la tabla de
topes de `pricing`, los dos contenedores de `catalog`, la configuración del `storefront`—, y una plantilla
genérica con parámetros para cada excepción esconde exactamente lo que el curso quiere que se vea (la
regla de la [Fase 06](06-del-compose-al-cluster.md): nada de cajas negras antes de tiempo). Cada servicio
escribe su `Deployment` con los fragmentos de la librería.

### 5.3 Qué va en cada archivo de valores

Tres niveles, y una regla para cada uno:

- **`charts/<svc>/values.yaml`**: lo que es del servicio y no cambia ni por perfil ni por cadena. El
  repositorio de la imagen, el comando de migración, el componente.
- **`charts/platform/values.yaml`**: lo que vale para todo el sistema. La puerta, los hosts, el puerto
  público, la tabla de topes vigente, los interruptores.
- **`values-<perfil>.yaml`**: **solo** lo que el perfil cambia. El de `lab` tiene cuatro líneas:

```yaml
# Perfil lab (contrato §5): control-plane y dos workers. Dos réplicas de cada backend, para que el
# reparto entre nodos se vea. Lo demás (observabilidad, bus) lo enciende cada fase.
pricing:   { replicaCount: 2 }
inventory: { replicaCount: 2 }
catalog:   { replicaCount: 2 }
replenish: { replicaCount: 2 }
```

El de `minimo` es `{}`: los valores por defecto **son** ese perfil, y el archivo existe para que `task
deploy -- minimo` diga lo que hace. El de `medicion` apaga el `storefront` y el seed.

**Lo que no va en ningún archivo de valores: los secretos.** Los `Secret` `<svc>-db` los crea `task
platform:postgres` desde `.secrets/`, fuera de git, y el chart solo los nombra en un `secretKeyRef`. Un
valor del chart termina guardado en el release (sección 5.6), y lo que va en el release lo lee cualquiera
que pueda leer los `Secret` del namespace.

Los **interruptores** del contrato nacen aquí con su nombre definitivo —`observability.metrics`,
`.dashboards`, `.logs`, `.traces`, `bus.valkey` y `bus.nats`, todos en `enabled: false`—. Hoy no encienden
nada, y las notas del release lo avisan si alguien lo intenta.

### 5.4 Los *hooks*: lo que la Fase 12 hacía a mano

`task deploy` corría las migraciones **antes** de aplicar los servicios, y el seed era una tarea aparte
**después**. En el chart, los dos son *hooks*: objetos que Helm aplica en un momento del ciclo del
release, fuera del resto, y espera a que terminen.

```yaml
metadata:
  name: {{ .Chart.Name }}-migrate
  annotations:
    # Un hook: Helm lo aplica antes del resto, en cada install y en cada upgrade, y espera a que
    # termine. Si falla, el release falla y ningún Deployment se toca.
    "helm.sh/hook": pre-install,pre-upgrade
    # Los cuatro con el mismo peso: Helm los corre de a uno, por nombre (catalog, inventory, pricing,
    # replenish). Aquí el orden no importa, porque cada uno migra su base; si importara, lo fija el peso.
    "helm.sh/hook-weight": "0"
    # El Job anterior se borra justo antes de crear el nuevo: un Job no se puede volver a aplicar
    # (Fase 12), y así su log se puede leer hasta el próximo despliegue.
    "helm.sh/hook-delete-policy": before-hook-creation
```

El seed es `post-install`: corre después de que los `Deployment` están listos, y **solo al instalar**.
En un upgrade los datos ya están.

Y `task deploy`, desde esta fase, es un `helm upgrade --install` (un *install* si el release no existe,
un *upgrade* si existe):

```bash
kubectl apply -f deploy/manifests/namespace.yaml     # el namespace es de plataforma, no del chart
task seed:image -- minimo                            # la imagen del seed, al nodo
helm upgrade --install lab charts/platform -n apps --kube-context kind-minimo \
  -f charts/platform/values-minimo.yaml --set pricing.image.tag=g3 … --wait --timeout 10m
```

`--wait` hace que Helm no termine hasta que los `Deployment` estén listos; sin él, el seed correría
contra servicios que todavía arrancan. Las migraciones, en cambio, Helm las espera siempre: es lo que
hace con los hooks.

### 5.5 El hash que cobra el incidente 09

El [incidente 09](cuaderno-incidentes.md#-incidente-09--cambié-la-configuración-y-el-servicio-sigue-igual) es el `ConfigMap` que cambia y el pod que sigue con lo que leyó al arrancar. La anotación
`checksum/regulated-caps` del pod de `pricing` es el hash del `ConfigMap` renderizado: si la tabla
cambia, el hash cambia, la plantilla del pod cambia, y el `Deployment` reemplaza el pod. La circular de
los 18.000 pesos ya no es un `kubectl edit`: es una línea de `values.yaml` y un `task deploy`.

```text
$ grep -n 'SKU-0003' charts/platform/values.yaml
44:      SKU-0003: 20000
$ kubectl -n apps get pods -l app.kubernetes.io/name=pricing,app.kubernetes.io/component=backend
NAME                       READY   STATUS    RESTARTS   AGE
pricing-688c5d755d-fb8q6   1/1     Running   0          15s
$ time task deploy -- minimo 2>&1 | grep -E 'REVISION|STATUS:'
STATUS: deployed
REVISION: 9
task deploy -- minimo 2>&1  1.00s user 0.60s system 9% cpu 16.951 total
$ kubectl -n apps get pods -l app.kubernetes.io/name=pricing,app.kubernetes.io/component=backend
NAME                       READY   STATUS    RESTARTS   AGE
pricing-688c5d755d-fb8q6   0/1     Error     0          33s
pricing-7d84bcbcc9-s8rln   1/1     Running   0          1s
$ curl -sS -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":21900}' http://api.localhost:8080/pricing/prices/SKU-0003
{"sku":"SKU-0003","store":"DRO-007","price":20000,"currency":"COP","regulatedCap":20000,"capped":true}
```

(Esta corrida devolvía la tabla de 18.000 a 20.000; la sección 9 cuenta por qué hubo que hacerla dos
veces. El pod viejo en `Error` es `pricing` saliendo con código distinto de cero al recibir `SIGTERM`: lo
cobra la [Fase 16](16-escalado-y-rollout.md).)

> ⚠️ **El hash solo protege lo que pasa por Helm.** Si alguien edita el `ConfigMap` con `kubectl`, el
> pod no se entera, igual que en la [Fase 11](11-configuracion-y-secretos.md): `task inc:break -- 09` lo sigue provocando. El
> `catalog` lleva la misma anotación por su `nginx.conf`, y el `storefront` por su configuración.

### 5.6 Qué es un release

Instalar un chart con un nombre en un namespace crea un **release**. Un release no es los objetos: es
el registro de lo que Helm instaló, con qué valores y en qué revisión. Vive en el cluster, como un
`Secret` por revisión:

```text
$ kubectl -n apps get secrets -l owner=helm
NAME                        TYPE                 DATA   AGE
sh.helm.release.v1.lab.v1   helm.sh/release.v1   1      91s
```

Adentro, en base64 sobre gzip, están el chart, los valores y el manifiesto renderizado completo. Por eso
Helm puede decir qué valores le diste:

```text
$ helm -n apps get values lab
USER-SUPPLIED VALUES:
catalog:
  image:
    tag: g3
…
storefront:
  image:
    tag: g2
```

Solo los tags: `values-minimo.yaml` está vacío. `helm get values lab --all` muestra los valores
calculados, con los de cada subchart y los globales repetidos en cada uno. Y cada `task deploy` es una
revisión nueva, con la anterior guardada: la [Fase 14](14-helm-en-operacion.md) vive de eso.

### 5.7 La mudanza: del YAML aplicado al release

Tu cluster de la [Fase 12](12-estado-y-almacenamiento.md) tiene los objetos que creó `kubectl apply`. El primer `task deploy` con el chart
se encuentra con ellos:

```text
Release "lab" does not exist. Installing it now.
Error: unable to continue with install: ConfigMap "catalog-nginx" in namespace "apps" exists and cannot be imported into the current release: invalid ownership metadata; label validation error: missing key "app.kubernetes.io/managed-by": must be set to "Helm"; annotation validation error: missing key "meta.helm.sh/release-name": must be set to "lab"; annotation validation error: missing key "meta.helm.sh/release-namespace": must be set to "apps"
```

Helm se niega a adueñarse de algo que no creó, y no tocó nada: ni siquiera corrió los hooks. Hay dos
salidas. **Adoptar** los objetos con `--take-ownership`, sin cortar el servicio, o **borrar y
reinstalar**. La sección 9 cuenta qué pasó adoptándolos; el camino que deja el cluster limpio es el
segundo, porque el chart no tiene estado propio —Postgres vive fuera de él, en `data`— y los `Secret`
de las bases no se tocan:

```bash
kubectl -n apps delete deploy,svc,httproute -l app.kubernetes.io/part-of=lab --wait=false
kubectl -n apps delete configmap neighbors pricing-regulated-caps storefront-config catalog-nginx
kubectl -n apps delete job -l app.kubernetes.io/component=migration
task deploy -- minimo
```

`catalog-nginx` va por nombre porque `task deploy` lo creaba con `kubectl create configmap`, sin labels.
Y **no** se borra el namespace: se llevaría los `Secret` `<svc>-db`. Con una sonda pidiendo
`/pricing/health/ready` y `/config.json` cada 100 ms:

```text
$ time task deploy -- minimo 2>&1 | grep -E 'REVISION|STATUS:|Error'
STATUS: deployed
REVISION: 1
task deploy -- minimo 2>&1  0.89s user 0.63s system 7% cpu 19.835 total
http://api.localhost:8080/pricing/health/ready: 701/850 con 200; cortes: desde 5.0 s, 15.7 s
http://storefront.localhost:8080/config.json: 701/850 con 200; cortes: desde 5.0 s, 15.7 s
```

**15,7 segundos sin servicio**, una vez, en el laboratorio. Y el seed corrió como `post-install`, sobre
los datos que ya estaban:

```text
$ kubectl -n apps logs job/seed
sembrado: 8 productos en catalog, 160 precios en pricing (20 droguerías)
```

**Prueba de fuego.** Que el chart produzca lo mismo que el YAML plano. `task chart:compare` renderiza el
chart con el perfil `minimo` y lo compara, objeto por objeto y campo por campo, con `deploy/manifests/` y
`deploy/jobs/`:

```text
$ task chart:compare
…
24 objetos en el chart, 23 en el YAML plano; 117 diferencias, por campo:
   23  + metadata.labels.app.kubernetes.io/instance
   23  + metadata.labels.app.kubernetes.io/managed-by
   23  - metadata.namespace
    9  + spec.template.metadata.labels.app.kubernetes.io/instance
    9  + spec.template.metadata.labels.app.kubernetes.io/managed-by
    7  + metadata.labels.app.kubernetes.io/component
    5  + metadata.annotations.helm.sh/hook
    5  + metadata.annotations.helm.sh/hook-delete-policy
    5  - spec.ttlSecondsAfterFinished
    4  + metadata.annotations.helm.sh/hook-weight
    1  + ConfigMap/catalog-nginx (el objeto entero)
    1  + spec.template.metadata.annotations.checksum/config
    1  + spec.template.metadata.annotations.checksum/nginx
    1  + spec.template.metadata.annotations.checksum/regulated-caps
```

Ciento diecisiete diferencias en catorce clases, y cada clase tiene su explicación. El namespace (23) lo
pone Helm al instalar, con `-n`, y eso es lo que permitirá instalarlo en `apps-b`. `instance` y
`managed-by` (64) son las labels recomendadas que dicen quién instaló el objeto y en qué release.
`component` (7) faltaba en las `HTTPRoute` y los `ConfigMap` del YAML plano: una corrección. Los
`helm.sh/hook…` y el `ttlSecondsAfterFinished` que se fue (19) son los cinco `Job` convertidos en hooks.
`catalog-nginx` lo creaba antes el Taskfile. Y los tres `checksum/…` son la sección 5.5. **Ninguna toca un
selector, un puerto, una imagen, una variable ni un volumen.** Y la suite:

```text
$ task conformance TARGET=cluster -- G1
Executed files:    5
Succeeded files:   5 (100.0%)
$ task conformance TARGET=cluster -- G2
Executed files:    1
Succeeded files:   1 (100.0%)
```

**El patrón a memorizar.** Una plantilla por objeto que se repite y una por objeto que difiere; un
archivo de valores por cada razón distinta de cambio —el servicio, el sistema, el perfil—, y nunca un
secreto en ninguno; y una prueba que compare lo renderizado con lo que había, antes de confiar en el
paquete.

---

## 🔁 6. Los otros tres: donde no es mecánico

**`inventory` y `replenish`** se replican sin sorpresas: el `Deployment` de `pricing` sin la tabla de
topes, tres archivos de una línea, y su comando de migración en sus valores.

**`catalog`** no sigue la plantilla, y se nota a propósito. Sus dos contenedores (D34, [Fase 09](09-los-cuatro-servicios-dentro.md))
no caben en un `Deployment` genérico sin un parámetro para cada diferencia, así que escribe el suyo. Y su
`nginx.conf` tenía un problema de fuente única: compose lo monta desde `services/catalog/nginx.conf`, y
una plantilla de Helm solo puede leer archivos **de dentro del chart** (`.Files.Get`). Copiarlo sería
tener dos. Quedó como enlace simbólico, `charts/catalog/files/nginx.conf → services/catalog/nginx.conf`,
que Helm sigue y avisa:

```text
level=INFO msg="found symbolic link in path. Contents of linked file included and used" path=…/charts/platform/charts/catalog/files/nginx.conf resolved=…/services/catalog/nginx.conf
```

El aviso sale en cada comando: el precio de no duplicar un archivo.

**`storefront`** no tiene base ni migraciones, y su configuración deja de ser un archivo escrito a mano:
`API_BASE_URL` se calcula de los valores globales.

```yaml
data:
  # La dirección pública del API: la que ve el navegador, no la del cluster.
  API_BASE_URL: {{ printf "http://%s:%v" .Values.global.hosts.api .Values.global.publicPort | quote }}
  BRAND_NAME: {{ .Values.brandName | quote }}
```

El host del API estaba escrito en tres sitios del YAML plano —las rutas, el CORS de `catalog` y esta
configuración—; ahora es un valor, y en la [Fase 14](14-helm-en-operacion.md) cambiar de cadena es cambiarlo.

**El `ConfigMap` de los vecinos** dejó de decir `apps`: usa el namespace del release.

```yaml
data:
  {{- range $svc := list "catalog" "inventory" "pricing" "replenish" }}
  {{ upper $svc }}_URL: http://{{ $svc }}.{{ $.Release.Namespace }}.svc.cluster.local:8080
  {{- end }}
```

Instalado en `apps-b`, cada servicio le hablará a sus vecinos y no a los de `apps`.

---

## 🪞 7. Tu instinto de `kubectl apply` dice… y la apuesta

El instinto lo sembró este mismo curso: **el estado correcto es el del repositorio**. `kubectl apply`
lo garantizaba: cualquier cosa que alguien cambiara a mano, el próximo `apply` la devolvía —por eso el
perfil escalado a mano de la sección 4 volvió a 1, y por eso `task inc:fix` reparaba los incidentes
aplicando los manifiestos—. Con Helm, *"el próximo `task deploy` lo devuelve"* suena igual de cierto.

> 🪞 **Apuesta antes de ejecutar.** Cambio la imagen de `pricing` a mano (`kubectl set image`, el
> incidente 05) y corro `task deploy -- minimo` con los mismos valores. Apuesta: **no** la devuelve como
> hacía `kubectl apply`: falla con un conflicto de server-side apply, porque `kubectl set image` se quedó
> con la propiedad del campo.
>
> **Resultado: ganada.**

```text
$ task inc:break -- 05
$ kubectl --context kind-minimo -n apps set image deployment/pricing pricing=lab/pricing:recien-construida
deployment.apps/pricing image updated
$ kubectl -n apps get deploy pricing -o jsonpath='{range .metadata.managedFields[*]}{.manager} {.operation}{"\n"}{end}'
helm Apply
kubectl-client-side-apply Update
kube-controller-manager Update
kubectl-set Update
$ task deploy -- minimo
…
Error: UPGRADE FAILED: conflict occurred while applying object apps/pricing apps/v1, Kind=Deployment: Apply failed with 1 conflict: conflict with "kubectl-set" using apps/v1: .spec.template.spec.containers[name="pricing"].image
$ kubectl -n apps get deploy pricing -o jsonpath='{.spec.template.spec.containers[0].image}'
lab/pricing:recien-construida
```

**Helm 4 aplica del lado del servidor** (*server-side apply*), y eso cambia lo que la documentación de
Helm 3 da por hecho. Cada campo de un objeto tiene un dueño, que se ve en `managedFields`: quien lo
escribió por última vez. Con *server-side apply*, Helm aplica **sus** campos y, si otro es dueño de uno
que Helm quiere cambiar, se detiene con un conflicto en vez de pisarlo. `kubectl set image` se hizo dueño
de la imagen, y Helm no se la quitó. Helm 3 aplicaba del lado del cliente, con una fusión de tres vías
que no pregunta por dueños; esa diferencia la describe su documentación, y no la ejecuté con Helm 3.

Para devolverle el campo a Helm hay que decirlo: `--force-conflicts`. `task deploy FORCE=true -- minimo`
lo pasa, y desde esta fase `task inc:fix` repara así los incidentes 05, 06 y 08 cuando el sistema es un
release. El 06 sigue borrando el `Service` antes, por la misma razón que en la [Fase 08](08-el-primer-despliegue.md): el `patch` le agregó al
selector una clave que es de `kubectl-patch`, y Helm no borra campos que no son suyos.

```text
$ task inc:fix -- 05
…
Incidente 05: reparado.
$ kubectl -n apps get deploy pricing -o jsonpath='{.spec.template.spec.containers[0].image}'
lab/pricing:g3
```

El conflicto te da una alarma que `kubectl apply` no daba —alguien tocó el cluster a mano— y te quita la
certeza de que desplegar deja el cluster igual al repositorio. La entrada completa está en
[INSTINTOS.md](INSTINTOS.md#el-próximo-apply-devuelve-todo-a-lo-que-dice-el-repositorio).

---

## 🧨 8. La rotura: un hook que no puede correr

Lo que pasa cuando el `pre-upgrade` no termina. **El cambio exacto**: subir el tag de `inventory` a uno
que no se cargó en el nodo, el error de cualquier viernes en que alguien despliega antes de terminar el
`task images:load`:

```text
$ time helm upgrade lab charts/platform -n apps --reuse-values --set inventory.image.tag=g4 --wait --timeout 90s
level=WARN msg="upgrade failed" name=lab error="pre-upgrade hooks failed: resource Job/apps/inventory-migrate not ready. status: InProgress, message: Job in progress\ncontext deadline exceeded"
Error: UPGRADE FAILED: pre-upgrade hooks failed: resource Job/apps/inventory-migrate not ready. status: InProgress, message: Job in progress
context deadline exceeded
… 1:33.59 total
```

**El síntoma**: un comando que no contesta durante todo el `--timeout` (con el de por defecto, cinco
minutos), y un error que habla del `Job`, no de la imagen. La causa está un nivel más abajo:

```text
$ kubectl -n apps get pods -l app.kubernetes.io/component=migration
NAME                      READY   STATUS             RESTARTS   AGE
catalog-migrate-wt8n9     0/1     Completed          0          93s
inventory-migrate-5pngq   0/1     ImagePullBackOff   0          90s
…
$ kubectl -n apps describe pod -l job-name=inventory-migrate | sed -n '/Events:/,$p' | tail -2
  Normal   BackOff    10s (x5 over 88s)  kubelet            spec.containers{migrate}: Back-off pulling image "lab/inventory:g4"
  Warning  Failed     10s (x5 over 88s)  kubelet            spec.containers{migrate}: Error: ImagePullBackOff
```

Es el [incidente 05](cuaderno-incidentes.md#-incidente-05--el-pod-espera-una-imagen-que-el-cluster-nunca-vio)
dentro de un hook. Y lo que el hook protegió:

```text
$ kubectl -n apps get deploy -o 'custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image'
NAME         IMAGE
catalog      lab/catalog:g3
inventory    lab/inventory:g3
…
$ curl -s -o /dev/null -w '%{http_code}\n' http://api.localhost:8080/inventory/health/ready
200
```

**Ningún `Deployment` cambió**: `inventory` siguió atendiendo con la imagen buena, porque sin migraciones
Helm no aplica nada más. El release quedó en `failed`, y la revisión anterior sigue siendo la que corre.
Con `--rollback-on-failure`, el nombre que Helm 4 le dio al `--atomic` de Helm 3, el fallo además vuelve
solo a la última revisión buena:

```text
Error: UPGRADE FAILED: release lab failed, and has been rolled back due to rollback-on-failure being set: pre-upgrade hooks failed: …
$ helm -n apps history lab | tail -2
11  …  failed    platform-0.13.0  Upgrade "lab" failed: pre-upgrade hooks failed: …
12  …  deployed  platform-0.13.0  Rollback to 9
```

Para salir, cargar la imagen y repetir, o volver al tag bueno: `task deploy -- minimo` corrió las cuatro
migraciones en 16 s y dejó la revisión 13 en `deployed`.

---

## ⚰️ 9. Autopsia: adoptar los objetos para no cortar el servicio

**La decisión, con su mejor argumento.** El primer `task deploy` se negó a instalar sobre los objetos de
`kubectl apply` (sección 5.7). La opción sin corte existe, y es la que elegiría cualquiera con un sistema
en producción: `--take-ownership`, que le dice a Helm que adopte lo que ya está. *"Para qué apagar
quince segundos lo que ya funciona, si Helm puede hacerse cargo."*

**Por qué era razonable.** Los objetos eran los mismos que el chart iba a producir, y la bandera está
documentada para esto.

**Qué pasó después, con número.** Primero, la adopción falló a medias:

```text
Error: conflict occurred while applying object apps/catalog gateway.networking.k8s.io/v1, Kind=HTTPRoute: Apply failed with 2 conflicts: conflicts with "kubectl-client-side-apply" using gateway.networking.k8s.io/v1:
- .spec.parentRefs
- .spec.rules && conflict occurred while applying object apps/inventory …
```

Las cinco `HTTPRoute`, en conflicto con su dueño anterior; los `Deployment`, en cambio, sí se aplicaron
(y reiniciaron sus pods), con el release en `failed`. Con `--force-conflicts` la segunda pasada terminó.
Parecía resuelto.

No lo estaba. Donde Helm y `kubectl` habían escrito **el mismo valor**, *server-side apply* los dejó
como dueños compartidos, sin conflicto, hasta el día en que el valor cambia. Ese día fue la primera
circular: la tabla de topes de 20.000 a 18.000 en `values.yaml`, y `task deploy`.

```text
7  …  failed  platform-0.13.0  Upgrade "lab" failed: conflict occurred while applying object apps/pricing-regulated-caps /v1, Kind=ConfigMap: Apply failed with 1 conflict: conflict with "kubectl-client-side-apply" using v1: .data.regulated-caps.csv
$ kubectl -n apps get configmap pricing-regulated-caps -o jsonpath='{.data}'
{"regulated-caps.csv":"SKU-0003,20000\n"}
$ kubectl -n apps logs deploy/pricing | head -3
2026/10/04 04:28:07 almacén: postgres
2026/10/04 04:28:07 tope regulado encendido: 1 productos con tope
```

El upgrade falló **a la mitad**: el `ConfigMap` no cambió, pero el `Deployment` sí, con el hash de la
tabla nueva, y `pricing` se reinició leyendo la tabla vieja. Repetido con `FORCE=true`, el `ConfigMap`
pasó a 18.000… y `pricing` **no** se reinició:

```text
$ helm -n apps get manifest lab --revision 7 | grep checksum/regulated-caps
        checksum/regulated-caps: 6dc448ba7e9f804965fb94ab58045ba16c51d4d7be38025a7b1712b64d913eaf
$ helm -n apps get manifest lab --revision 8 | grep checksum/regulated-caps
        checksum/regulated-caps: 6dc448ba7e9f804965fb94ab58045ba16c51d4d7be38025a7b1712b64d913eaf
$ curl -sS -X PUT … http://api.localhost:8080/pricing/prices/SKU-0003
{"sku":"SKU-0003","store":"DRO-007","price":20000,"currency":"COP","regulatedCap":20000,"capped":true}
```

El hash ya había cambiado en la revisión que falló; en la buena era el mismo, así que la plantilla del
pod no cambió y nadie lo reinició. **El `ConfigMap` decía 18.000 y `pricing` cobraba hasta 20.000**: el
incidente 09, exactamente, con el chart que se escribió para prevenirlo. Salió con un `kubectl rollout
restart`.

**Cuánto cuesta salir, con número.** Borrar y reinstalar: **15,7 s** sin servicio, una vez, y un cluster
donde Helm es el único dueño de cada campo (`managedFields` del `ConfigMap`: solo `helm Apply`). Contra
eso, la adopción dejó un estado que falla la primera vez que cambia cada valor compartido —sin aviso, a
la mitad—, y una revisión fallida que engañó al mecanismo de la sección 5.5.

**Qué lo habría cambiado.** Una pregunta antes de adoptar: *¿quién más es dueño de estos campos?* La
respuesta estaba en `kubectl get … -o jsonpath='{.metadata.managedFields[*].manager}'`, y decía
`kubectl-client-side-apply` en cada objeto. Y una bandera: con `--rollback-on-failure` (sección 8), el
upgrade a medias de la revisión 7 se habría deshecho solo, con el hash viejo incluido.

**Antes y después, con números:** adoptando, tres revisiones fallidas en la primera media hora (1, 3 y
7), un precio regulado mal cobrado hasta que alguien lo notó, y un reinicio a mano; borrando y
reinstalando, 15,7 s de corte y ninguna revisión fallida después.

---

## 📖 10. Traducción

| En compose o con `kubectl apply` | Con Helm | Lo que cambia |
|---|---|---|
| `compose.yaml` + `compose.override.yaml` (varios `-f`) | `values.yaml` + `values-<perfil>.yaml` (varios `-f`) | el override de compose reemplaza claves; el valor de Helm alimenta una plantilla |
| `docker compose config` | `helm template` | ver lo que va a aplicarse, sin aplicarlo |
| `docker compose up -d` · `kubectl apply -R -f` | `helm upgrade --install` | cada despliegue es una revisión guardada en el cluster |
| `depends_on: {condition: service_completed_successfully}` | un *hook* `pre-install,pre-upgrade` | el hook bloquea el release entero, no solo un servicio |
| `docker compose down` | `helm uninstall` | los `Job` de los hooks no son del release: quedan |
| el estado es el del archivo | el estado es el del release, y cada campo tiene dueño | Helm 4 no pisa lo que otro cambió sin `--force-conflicts` |

Y de vuelta: un release no tiene traducción en compose, porque compose no recuerda qué aplicó ni con
qué valores; lo más cercano es el archivo en git y la memoria de quien lo corrió. Las filas completas,
en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En un cluster gestionado Helm funciona igual; lo que cambia es cuántos más escriben en tus objetos
(controladores de la nube, operadores de políticas), y con *server-side apply* cada uno es un dueño más
con el que chocar.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Helm no ahorra líneas aquí.** El YAML plano de la [Fase 12](12-estado-y-almacenamiento.md) son 570 líneas sin comentarios en 23
archivos. El chart son 361 en 25 plantillas, más 82 de valores en 9 archivos y 53 de siete `Chart.yaml`:
496. Un 13 % menos, y más archivos. Lo que compra no es tamaño: es que **cada diferencia vive en un solo
sitio** —el perfil `lab` son 4 líneas, no cinco `Deployment` copiados— y que el sistema se instala con
un comando y deja un registro.

Lo que cuesta, con número o con nombre:

- **Las plantillas esconden el YAML.** Para saber qué le llega al cluster hay que renderizar (`helm
  template`), y un error de indentación de `nindent` produce un YAML válido y equivocado. Por eso el
  curso escribió YAML plano doce fases antes.
- **Un subchart no se instala solo** (sección 5.2), y los nombres de las plantillas son globales.
- **Los `Job` de los hooks no son del release**: `helm uninstall` no los borra.
- **Un upgrade que falla puede quedar a medias** (sección 9) si no le pides que vuelva atrás.
- **El release guarda el manifiesto completo en un `Secret` por revisión**: lo que pongas en un valor
  queda ahí, legible para quien lea los `Secret` del namespace.

**Cuándo NO un chart:** un sistema con un solo perfil y un solo destino, donde el YAML plano no se
repite; un objeto que se instala una vez y no cambia (la `GatewayClass`, el `StatefulSet` de Postgres,
que en este curso siguen fuera del chart por eso); y cualquier cosa con secretos que no tengan otro
lugar donde vivir. **Cuándo sí:** cuando el mismo sistema se instala más de una vez con diferencias —tres
perfiles hoy, dos cadenas en la [Fase 14](14-helm-en-operacion.md)—.

**La pregunta del curso, para esta fase:** el contenedor no cambió en nada. El orquestador te dio los
mismos objetos de antes y un registro de quién escribió cada campo. Helm te dio el paquete, las
revisiones y los hooks. **Te tocó a ti** decidir qué va en la plantilla y qué en cada archivo de valores,
mantener los secretos fuera, y comprobar que el paquete hace lo mismo que el YAML que reemplaza.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`falta pricing.image.tag` al renderizar.** Causa: se llamó a `helm` sin los tags. Salida: `task deploy`,
que los pasa desde `STEP_TAGS`, o `--set <svc>.image.tag=…` a mano.

**El seed no corrió.** Causa: es `post-install`, y la instalación falló antes de terminar; lo que siguió
fueron upgrades. Comprobación 🩺: `helm -n apps history lab` (la revisión 1 en `failed`). Salida: `task
seed:job`, que lo corre suelto.

**Después de `helm uninstall` quedan los `Job` de migraciones.** No es un error: los hooks no son del
release. `kubectl -n apps delete job -l app.kubernetes.io/component=migration`.

**`helm template` muestra objetos sin namespace.** Correcto: el namespace lo pone el `-n` de la
instalación. Si aplicas ese YAML con `kubectl apply` sin `-n`, cae en `default` (el incidente 07).

**`Error: … conflict with "kubectl-set"` (o `kubectl-edit`, `kubectl-patch`).** Alguien cambió a mano un
campo del chart (sección 7). Antes de `FORCE=true`, averigua por qué: el conflicto es la única pista.

---

## 📋 14. Checklist de validación

```text
[ ] el 96 % de líneas repetidas, contado en tu repositorio, y el perfil a mano revertido por apply
[ ] helm template sin tags falla con el mensaje de required
[ ] task chart:compare: 117 diferencias en 14 clases, cada una explicada
[ ] la mudanza: borrar los objetos de kubectl apply y task deploy -- minimo, con el corte medido
[ ] task conformance TARGET=cluster -- G1 y -- G2 en verde con el release
[ ] los cuatro Job de migraciones como hooks, y el seed como post-install, en su log
[ ] el sh.helm.release.v1.lab.v1 y helm get values lab
[ ] la circular en values.yaml y el pod de pricing reemplazado solo
[ ] kubectl set image + task deploy: el conflicto; task inc:fix -- 05 lo repara
[ ] el hook que no corre: 90 s bloqueado, ningún Deployment tocado
[ ] los tres perfiles renderizados: 1, 2 y sin storefront
```

---

## 🧪 15. Ejercicios (24)

Un tercio son de diagnóstico; varios usan servicios distintos de `pricing`.

## 🟢 Fácil — el paquete (1–7)

### 🟢 Ejercicio 1 — Renderizar sin cluster
Renderiza el chart con el perfil `minimo` y cuenta los objetos por tipo.

**Criterio:** 4 `ConfigMap`, 5 `Deployment`, 5 `HTTPRoute`, 5 `Job` y 5 `Service`.

<details><summary>Solución</summary>

`helm template lab charts/platform -n apps -f charts/platform/values-minimo.yaml --set pricing.image.tag=g3 …`
(los cinco tags de `STEP_TAGS`) `| grep '^kind:' | sort | uniq -c`.
</details>

### 🟢 Ejercicio 2 — El tag que falta
Renderiza sin `--set` y lee el error. ¿Qué servicio nombra, y por qué ese?

**Criterio:** el mensaje de `required` con el nombre del servicio.

<details><summary>Solución</summary>

Nombra el primero que Helm renderiza y no tiene tag (en la verificación, `storefront`). Helm se detiene
en el primer error; los otros cuatro también faltan.
</details>

### 🟢 Ejercicio 3 — El release por dentro
Muestra el `Secret` de la revisión actual y saca de él la fecha de la última instalación.

**Criterio:** el campo `last_deployed`.

<details><summary>Solución</summary>

`kubectl -n apps get secrets -l owner=helm`, y el `jsonpath='{.data.release}' | base64 -d | base64 -d |
gunzip` de la sección 5.6. Es base64 dos veces (el del `Secret` y el de Helm) sobre gzip.
</details>

### 🟢 Ejercicio 4 — Valores dados y valores calculados
Compara `helm get values lab` con `helm get values lab --all`. ¿De dónde sale `regulatedCap.caps` en el
segundo?

**Criterio:** la clave en `--all` y su archivo de origen.

<details><summary>Solución</summary>

Del `values.yaml` del paraguas (`pricing.regulatedCap.caps`), fusionado con el `values.yaml` de
`pricing`, que la deja vacía.
</details>

### 🟢 Ejercicio 5 — El perfil lab, renderizado
Renderiza los perfiles `lab` y `medicion` y di qué cambia contra `minimo`.

**Criterio:** cuatro `replicas: 2` en `lab`; sin `storefront` ni seed en `medicion`.

<details><summary>Solución</summary>

El mismo `helm template` con `-f charts/platform/values-lab.yaml` y `values-medicion.yaml`, y `grep -E
'^kind:|^  replicas:'`.
</details>

### 🟢 Ejercicio 6 — Los hooks en su orden
Corre `task deploy -- minimo` y ordena los pods de migraciones por fecha de creación.

**Criterio:** catalog, inventory, pricing, replenish.

<details><summary>Solución</summary>

`kubectl -n apps get pods -l app.kubernetes.io/component=migration --sort-by=.metadata.creationTimestamp`.
Mismo peso y mismo tipo: Helm los ordena por nombre.
</details>

### 🟢 Ejercicio 7 — La comparación
Corre `task chart:compare` y encuentra la diferencia que no es una label, una anotación ni el namespace.

**Criterio:** el `ConfigMap/catalog-nginx` y el `ttlSecondsAfterFinished` que se fue.

<details><summary>Solución</summary>

Las dos clases de la sección 5.7: el objeto entero que antes creaba el Taskfile, y el borrado a los diez
minutos que reemplazó la política del hook.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — Una variable para todos
Agrega `LOG_LEVEL=info` a los cuatro backends tocando un solo archivo de plantilla.

**Criterio:** `kubectl -n apps exec deploy/replenish -- printenv LOG_LEVEL` dice `info`, y lo mismo en los otros tres.

<details><summary>Solución</summary>

En `lab-common.databaseEnv` no (es otra cosa): una plantilla nueva, `lab-common.commonEnv`, incluida en
los cuatro `Deployment`. Son cuatro `include`, no cuatro bloques. Y el valor, en `global`.
</details>

### 🟡 Ejercicio 9 — La marca, por valor
Cambia la marca del `storefront` a "La Vecina — Rebotica" sin tocar una plantilla.

**Criterio:** `/config.json` con la marca nueva, y el pod del `storefront` reemplazado solo.

<details><summary>Solución</summary>

`storefront.brandName` en `values.yaml` del paraguas y `task deploy -- minimo`. El hash de
`storefront-config` cambia el pod.
</details>

### 🟡 Ejercicio 10 — Apagar un servicio
Instala con `replenish.enabled=false`. **Predice** qué pasa con su `Job` de migraciones y con su `Secret`.

**Criterio:** la predicción, y `kubectl -n apps get deploy,job,secret` después.

<details><summary>Solución</summary>

La condición apaga el subchart entero: su `Deployment`, su `Service`, su ruta y su hook. El `Secret`
`replenish-db` sigue, porque no es del chart.
</details>

### 🟡 Ejercicio 11 — `catalog` sin enlace
Reemplaza el enlace simbólico por una copia del `nginx.conf` y cambia la copia. **Predice** qué ve compose.

**Criterio:** la predicción, y el `default.conf` del pod contra el de compose.

<details><summary>Solución</summary>

Compose sigue con el viejo: monta `services/catalog/nginx.conf`. Dos fuentes que ya divergieron. Vuelve
al enlace.
</details>

### 🟡 Ejercicio 12 — Los vecinos de otra cadena
Renderiza el chart con `-n apps-b` y mira el `ConfigMap` `neighbors`.

**Criterio:** las cuatro URL con `.apps-b.svc.cluster.local`.

<details><summary>Solución</summary>

`helm template lab charts/platform -n apps-b …`: el `range` usa `$.Release.Namespace`.
</details>

### 🟡 Ejercicio 13 — El seed que no corre
Desinstala el release, instálalo con el tag de `catalog` mal puesto, corrígelo con un upgrade y busca el seed.

**Criterio:** `kubectl -n apps get job seed` sin resultado, y la explicación.

<details><summary>Solución</summary>

La instalación (revisión 1) falla antes del `post-install`; el upgrade que la arregla no corre hooks de
instalación. `task seed:job -- minimo` lo corre suelto.
</details>

### 🟡 Ejercicio 14 — Un subchart solo
Intenta instalar `charts/platform/charts/pricing` como chart independiente. **Predice** el error.

**Criterio:** la predicción y el error literal.

<details><summary>Solución</summary>

`template: no template "lab-common.service" associated with template "gotpl"`: la librería es
dependencia del paraguas, no de `pricing`. Lo que cuesta la sección 5.2.
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — ¿Quién es dueño?
Edita a mano el `Deployment` de `catalog` (`kubectl edit`): agrégale una label que el chart no define y
cambia una que sí define. Lista los dueños de sus campos. **Predice** qué hace el próximo `task deploy`.

**Criterio:** la predicción, los `managedFields`, y el resultado.

**Rúbrica:** una label que el chart no define no choca (es de `kubectl-edit` y Helm no la toca); una que
el chart define, sí; y por qué `task deploy` no borra la primera.

### 🟠 Ejercicio 16 — La mudanza por adopción
En un cluster con el YAML de la [Fase 12](12-estado-y-almacenamiento.md), haz la mudanza con `--take-ownership`, sin borrar nada.

**Criterio:** el release en `deployed`, y la lista de objetos con `kubectl-client-side-apply` en sus
`managedFields`.

**Rúbrica:** el conflicto de las `HTTPRoute`; `--force-conflicts`; y los campos que quedan con dos dueños
y van a fallar el primer día que cambien.

### 🟠 Ejercicio 17 — El hash engañado
Reproduce la sección 9: un upgrade que falla después de aplicar el `Deployment` y antes del `ConfigMap`.

**Criterio:** el `ConfigMap` con la tabla nueva y `pricing` cobrando con la vieja.

**Rúbrica:** cómo provocar el fallo a la mitad (un conflicto en el `ConfigMap`); por qué la revisión
siguiente no reinicia; y qué bandera lo habría evitado.

### 🟠 Ejercicio 18 — El hook lento
Haz que la migración de `catalog` tarde 2 minutos (un `sleep` en el comando, por valores). **Predice**
qué ve quien corre `task deploy`.

**Criterio:** la predicción, el tiempo total, y los servicios atendiendo durante la espera.

**Rúbrica:** el comando bloqueado; ningún `Deployment` cambiado hasta que el hook termina; y el
`--timeout` como presupuesto del despliegue entero, no de un hook.

### 🟠 Ejercicio 19 — `helm template` mintió
Aplica la salida de `helm template` con `kubectl apply -f -` sin `-n`. **Predice** dónde quedan los objetos.

**Criterio:** la predicción y `kubectl get deploy -A -l app.kubernetes.io/instance=lab`.

**Rúbrica:** en `default`; los vecinos apuntando a `apps`; y por qué Helm no escribe el namespace.

### 🟠 Ejercicio 20 — Las revisiones
Haz diez despliegues seguidos y cuenta los `Secret` de Helm. **Predice** cuántos quedan.

**Criterio:** la predicción y el conteo.

**Rúbrica:** un `Secret` por revisión, hasta `--history-max`, que en `helm upgrade` vale 10 por
defecto: quedan 10, y las más viejas se borran; qué ocupa cada uno; y qué se pierde al recortarlos (no
se puede volver a una revisión que ya no está).

## 🔴 Muy difícil — el paquete en serio (21–24)

### 🔴 Ejercicio 21 — Postgres al chart
Mueve el `StatefulSet` de Postgres al chart, como subchart con su interruptor.

**Criterio:** `task deploy` instala también Postgres, y `helm uninstall` **no** borra sus datos.

**Rúbrica:** el `PersistentVolumeClaim` de `volumeClaimTemplates` no es del release (sobrevive); los
`Secret` siguen fuera; el orden contra las migraciones (un hook no espera a un `StatefulSet` del mismo
release); y por qué el curso lo dejó fuera.

### 🔴 Ejercicio 22 — Una prueba del chart
Escribe una prueba de Helm (`helm test`) que pida `/health/ready` a los cuatro backends.

**Criterio:** `helm test lab -n apps` en verde, y en rojo con `pricing` en cero réplicas.

**Rúbrica:** el hook `test`; un pod con la imagen de Hurl; y qué agrega contra `task conformance`.

### 🔴 Ejercicio 23 — La librería, versionada
Haz de `lab-common` una dependencia de cada subchart, con `repository: file://../lab-common`.

**Criterio:** `helm install` de `pricing` solo funciona, y el chart paraguas sigue igual.

**Rúbrica:** `helm dependency build` y los `.tgz` en cada `charts/`; qué se gana (subcharts instalables
solos) y qué se paga (cinco copias, y versiones que se pueden separar).

### 🔴 Ejercicio 24 — El costo de cada perfil
Contesta la pregunta de Martha Lucía con el chart: la memoria del perfil `minimo` y la del `lab`.

**Criterio:** dos números con su dispersión, medidos con `task deploy -- minimo` y `task deploy -- lab`
en sus clusters.

**Rúbrica:** el mismo método de B-00 (`a01`); tres corridas; la diferencia de nodos y de réplicas
separadas; y la advertencia de que no es lo que cuesta en una nube.

---

## 📚 16. Referencias

**Documentación oficial** (Helm 4, la versión de [a01](a01-el-laboratorio.md))

- Helm, *Charts*: https://helm.sh/docs/topics/charts/ — la estructura, `Chart.yaml` y las dependencias.
- Helm, *Chart Template Guide*: https://helm.sh/docs/chart_template_guide/ — plantillas, `include`, `nindent`.
- Helm, *Subcharts and Global Values*: https://helm.sh/docs/chart_template_guide/subcharts_and_globals/
- Helm, *Library Charts*: https://helm.sh/docs/topics/library_charts/
- Helm, *Chart Hooks*: https://helm.sh/docs/topics/charts_hooks/ — pesos, orden y políticas de borrado.
- Helm, *Chart Development Tips and Tricks*: https://helm.sh/docs/howto/charts_tips_and_tricks/ — la
  sección "Automatically Roll Deployments" es el hash de la sección 5.5.
- Helm, *Values* (buenas prácticas): https://helm.sh/docs/chart_best_practices/values/
- Helm, `helm upgrade`: https://helm.sh/docs/helm/helm_upgrade/ — `--take-ownership`,
  `--force-conflicts`, `--rollback-on-failure`, `--server-side`.
- Helm, *Helm 4 Released*: https://helm.sh/blog/helm-4-released/ — lo que cambió, *server-side apply*
  incluido.
- Kubernetes, *Server-Side Apply*: https://kubernetes.io/docs/reference/using-api/server-side-apply/ —
  dueños, conflictos y `managedFields`.
- Kubernetes, *Recommended Labels*: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/

> ⚠️ Buena parte de lo que se encuentra escrito sobre Helm es de Helm 3, que aplica del lado del cliente:
> lo de la sección 7 no aparece ahí.

**Libros**

- Brendan Burns, Joe Beda, Kelsey Hightower y Lachlan Evenson, *Kubernetes: Up and Running*, 3.ª edición
  (2022): el capítulo sobre organizar una aplicación, para la disciplina de qué va en cada archivo.

**Orden de lectura sugerido:** antes, *Charts*; durante, la guía de plantillas y *Chart Hooks*; después,
*Server-Side Apply*, con la sección 9 delante.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 13 (minimo)

  apps      release lab (Helm), revisión N · Secret sh.helm.release.v1.lab.vN por revisión
            ├── pricing · inventory · catalog · replenish · storefront   (subcharts, con lab-common)
            ├── neighbors (namespace del release) · pricing-regulated-caps · storefront-config · catalog-nginx
            ├── hooks pre-install,pre-upgrade: <svc>-migrate × 4 · post-install: seed
            └── los Secret <svc>-db: fuera del chart (task platform:postgres)
  data      postgres-0: fuera del chart
  gateway   Envoy Gateway y la puerta lab: fuera del chart

  task deploy -- minimo|lab|medicion   = namespace + seed:image + helm upgrade --install … --wait
  task chart:compare                   = helm template | scripts/chart/compare.py
```

> **La señal de que quedó bien:** *"Instalo el sistema con un comando y un perfil, sé qué valor va en
> qué archivo, y cuando un despliegue se niega por un conflicto, sé que alguien tocó el cluster a mano
> y averiguo quién antes de forzarlo."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite pasando y `git status` limpio:
>
> ```bash
> git tag -a fase-13-helm-el-paquete -m "F13 cerrada: chart paraguas charts/platform con cinco subcharts y lab-common; perfiles minimo, lab y medicion como valores; interruptores del contrato; migraciones y seed como hooks; hash de los ConfigMap; task chart:compare; inc:fix con Helm"
> ```
>
> Commits con prefijo `f13:` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F14:** `--rollback-on-failure` como regla de `task deploy`; `--history-max`; el diff previo con
  helm-diff contra la deriva de la sección 7.
- **F16:** `pricing` sale con error al recibir `SIGTERM` (el pod viejo en `Error` de la sección 5.5).
- **F15:** el `upstream connect error` justo después de un `rollout restart` de `pricing`: la readiness
  trivial (sección 9, al reiniciar a mano).
- **`a01`:** PyYAML 6.0.3, en `scripts/chart/requirements.txt`.
