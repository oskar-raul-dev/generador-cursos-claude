# 💾 Fase 12 — Estado, almacenamiento y datos iniciales: las dos réplicas que dicen que hay y que no hay

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 12 de 27 · Parte II — El despliegue · **densa**
> **Perfil:** `minimo` · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 B-12 y Testcontainers, solo verificados con Docker
> **Servicios que toca:** los cuatro backends; Contingencia, la Braqui y su aviso de traslados en `legacy` · **Paso de generación:** G3 · Postgres
> **Depende de:** [Fase 11](11-configuracion-y-secretos.md) · **Habilita:** [Fase 13](13-helm-el-paquete.md)
> **Incidentes que reserva:** 11 · **Medición:** B-12
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a16](a16-el-patrimonio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64
> **Objetivo:** que cada servicio guarde sus datos en un disco que sobreviva a sus pods —una base propia, en un Postgres del cluster—, con las migraciones y los datos iniciales como `Job`, y saber cuándo eso no debería hacerse así fuera del laboratorio.

---

## 🧭 1. Dónde estamos

Desde la [Fase 09](09-los-cuatro-servicios-dentro.md) los cuatro backends guardan lo suyo en un
SQLite dentro del pod, en un `emptyDir`. La suite pasa, la página muestra el catálogo, la configuración
llega al arrancar. Tres fases sin un error, y una deuda declarada 💸 que nadie ha cobrado: **el almacén
vive lo que vive el pod**.

Luz Marina la cobra con la pregunta que traía desde el primer día. Ella dirigió en 2012 el paso del
Siga de un servidor a un cluster de varios nodos, y sabe lo que pasa cuando un sistema con estado se
multiplica:

> *"Ustedes dicen que esto escala subiéndole las réplicas. Súbanle a dos al inventario y le hago una
> pregunta muy sencilla: ¿cuántos inhaladores hay en Chapinero?"*

Y la Braqui, desde el patrimonio, trae la otra mitad del problema: desde 2023 no tiene base propia.
Lee y escribe en las tablas del Siga, porque Germán quería una sola verdad (historia §1.11). Esta fase
le da a cada servicio su base, y muestra por qué la Braqui es el ejemplo de lo que no hay que repetir.

---

## 🎯 2. Objetivos de esta fase

1. Ver el fallo silencioso: dos réplicas sobre SQLite, ningún error, dos respuestas distintas.
2. Desplegar Postgres a mano, como `StatefulSet` sobre la imagen oficial, con su disco
   (`PersistentVolumeClaim`) y su nombre estable (`Service` headless).
3. Generar G3: los cuatro servicios contra su propia base, con su propia credencial, y las migraciones
   como `Job` antes del rollout.
4. Sembrar los datos iniciales con el script de [a01](a01-el-laboratorio.md), como `Job`.
5. Medir qué se pierde probando contra SQLite (B-12).
6. Pasar el aviso de traslados de la Braqui a un `CronJob`, después de ver su bloqueo huérfano.

---

## 🚫 3. Qué NO entra todavía

- Réplicas de Postgres, respaldos y recuperación: fuera del laboratorio, en el veredicto.
- Operadores de bases de datos (CloudNativePG y compañía): se nombran en el veredicto, no se instalan.
- La carrera de dos escrituras simultáneas en `inventory`: se ve en la sección 7 y la cobra la [Fase 16](16-escalado-y-rollout.md).
- Los *hooks* de Helm para las migraciones → [Fase 13](13-helm-el-paquete.md).
- Valkey y NATS, que también viven en `data` → Parte IV.

---

## 🧨 4. El problema, en el laboratorio

La pregunta de Luz Marina, literal. `inventory` con dos réplicas, seis reposiciones de 5 inhaladores
por la puerta, y veinte consultas de la existencia:

```text
$ kubectl -n apps scale deploy/inventory --replicas=2
deployment.apps/inventory scaled
=== seis reposiciones de 5 unidades de SKU-0001 en DRO-007
RESTOCK 1 → 201
RESTOCK 2 → 201
RESTOCK 3 → 201
RESTOCK 4 → 201
RESTOCK 5 → 201
RESTOCK 6 → 201
=== veinte consultas de la existencia
   7 10
  13 20
```

Entraron 30 unidades. El sistema contesta 10 o 20, según qué réplica atienda, y nunca 30. Y la venta
de 12 que pide un domicilio:

```text
=== una venta de 12 unidades (un ajuste), cuatro veces
{"error":"conflict","message":"el ajuste dejaría la existencia en -2"} → 409
{"error":"conflict","message":"el ajuste dejaría la existencia en -2"} → 409
{"error":"conflict","message":"el ajuste dejaría la existencia en -2"} → 409
{"id":"MOV-000008",…,"type":"ADJUSTMENT","quantity":-12,…} → 201
```

**Dice que hay y que no hay según quién conteste.** Los logs de las dos réplicas no tienen una sola
línea de error: cada una tiene su SQLite, en su `emptyDir`, y cada una dice la verdad sobre lo que sabe.
**Nadie olvida un bug que no produce ningún error.**

---

## 💾 5. Postgres en el cluster, y `pricing` primero

### 5.1 Un disco que sobrevive al pod

El SQLite estaba en un `emptyDir`, que vive lo que vive el pod. Para que algo sobreviva hacen falta
tres objetos, y conviene verlos en el orden en que se piden:

- Un **`PersistentVolumeClaim`** (PVC): el pedido. "Necesito 1 GiB, que lo use un solo nodo a la vez
  (`ReadWriteOnce`), de esta clase". Es del namespace, como el pod que lo usa.
- Una **`StorageClass`**: quién cumple el pedido. En kind es `standard`, que implementa
  `local-path-provisioner`; en una nube, el disco de bloque del proveedor.
- Un **`PersistentVolume`** (PV): el disco que el provisionador creó para cumplir el pedido. Es del
  cluster, no del namespace.

```text
$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  31m
```

Dos columnas que deciden cosas. `WaitForFirstConsumer`: el disco no se crea hasta que un pod lo pide,
para crearlo en el nodo donde va a correr. `Delete`: si se borra el PVC, se borra el disco. Y una
verdad de kind que no hay que olvidar: el disco es una carpeta **dentro del nodo**, que es un contenedor.

```text
$ kubectl get pv -o custom-columns=NAME:.metadata.name,CLAIM:.spec.claimRef.name,HOSTPATH:.spec.hostPath.path
NAME                                       CLAIM             HOSTPATH
pvc-defeee8a-8905-4825-a4e9-c0a8e7be6b93   data-postgres-0   /var/local-path-provisioner/pvc-defeee8a-…_data_data-postgres-0
```

`kind delete cluster` se lleva el disco con el nodo. Sobrevive a los pods; no al cluster.

### 5.2 El `StatefulSet`

Postgres no es un `Deployment` más. Necesita tres cosas que un `Deployment` no da: un disco **suyo**
que lo siga si el pod se recrea, un nombre estable, y un arranque en orden si hay más de una réplica.
Eso es un `StatefulSet`. El del laboratorio, escrito a mano sobre la imagen oficial, sin charts de
terceros (`platform/data/postgres/statefulset.yaml`):

```yaml
spec:
  # El Service headless que da a cada réplica su nombre estable.
  serviceName: postgres
  replicas: 1
  template:
    spec:
      containers:
        - name: postgres
          # postgres:18.6
          image: postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722
          envFrom:
            - secretRef: {name: postgres-users}
          volumeMounts:
            # Postgres 18 guarda sus datos en /var/lib/postgresql/18/docker: se monta la carpeta de arriba.
            - {name: data, mountPath: /var/lib/postgresql}
            - {name: init, mountPath: /docker-entrypoint-initdb.d, readOnly: true}
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "postgres"]
  # El disco: un PVC por réplica, que sobrevive al pod (y al StatefulSet, si no se borra a mano).
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: [ReadWriteOnce]
        storageClassName: standard
        resources:
          requests:
            storage: 1Gi
```

`volumeClaimTemplates` es la diferencia: el `StatefulSet` crea un PVC por réplica (`data-postgres-0`,
`data-postgres-1`…), y cada réplica recupera **el suyo** aunque cambie de pod. El `Service` es
*headless* (`clusterIP: None`): no reparte, resuelve directo a la IP del pod, y le da a cada réplica
un nombre propio.

```text
$ kubectl -n apps exec deploy/inventory -- getent hosts postgres.data.svc.cluster.local
10.244.0.62     postgres.data.svc.cluster.local
$ kubectl -n apps exec deploy/inventory -- getent hosts postgres-0.postgres.data.svc.cluster.local
10.244.0.62     postgres-0.postgres.data.svc.cluster.local
```

### 5.3 Una base por servicio, y la divergencia declarada

`task platform:postgres -- minimo` genera una contraseña por usuario en `.secrets/postgres.env` (fuera
de git, como en la [Fase 11](11-configuracion-y-secretos.md)), crea el `Secret` de Postgres en `data` y uno por servicio en `apps`
(`pricing-db`, `inventory-db`…, cada uno con su `DATABASE_URL`), y un `init.sh` que la imagen oficial
corre **una sola vez**, con la carpeta de datos vacía:

```sh
for svc in pricing inventory catalog replenish; do
  # …la contraseña de cada uno sale de la variable <SVC>_DB_PASSWORD, del Secret
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<SQL
CREATE ROLE $svc LOGIN PASSWORD '$pass';
CREATE DATABASE $svc OWNER $svc;
REVOKE ALL ON DATABASE $svc FROM PUBLIC;
SQL
done
```

```text
task platform:postgres -- minimo  0.60s user 0.25s system 7% cpu 11.511 total
$ kubectl -n data exec postgres-0 -- psql -U postgres -c '\l'
 catalog   | catalog   | UTF8 | …
 inventory | inventory | UTF8 | …
 pricing   | pricing   | UTF8 | …
 replenish | replenish | UTF8 | …
```

**La divergencia, en voz alta.** Una base por servicio es la regla; **un servidor por servicio**, no
en este laboratorio. Los cuatro comparten una instancia: su memoria, su disco, sus conexiones, su
versión y su ventana de mantenimiento. Lo que se conserva es lo que importa para el diseño —ningún
servicio puede leer las tablas de otro, porque su usuario no tiene permiso en otra base—; lo que se
pierde es el aislamiento de operación: si `inventory` agota las conexiones o llena el disco, los otros
tres lo sufren. En producción eso pesa; en 4 GiB, cuatro instancias de Postgres no entran.

### 5.4 G3 en `pricing`, y el orden que importa

G3 lleva los cuatro almacenes a Postgres sin cambiar ninguna interfaz: si hay `DATABASE_URL`,
Postgres; si no, el SQLite de G1, que sigue siendo el de compose. Los prompts están en
[a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g3). Lo que cambia de verdad es **quién
crea el esquema**: ya no cada réplica al arrancar, sino un `Job`, una vez, antes del rollout.

¿Por qué? Porque el orden se rompe solo. El `Deployment` de `pricing` con G3, aplicado antes de migrar:

```text
$ kubectl apply -f deploy/manifests/pricing/deployment.yaml
deployment "pricing" successfully rolled out
$ curl -sS -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":21900}' http://api.localhost:8080/pricing/prices/SKU-0003
{"error":"internal","message":"ERROR: relation \"prices\" does not exist (SQLSTATE 42P01)"}
```

El rollout dijo "listo" y el servicio no puede atender (la readiness de verdad es de la [Fase 15](15-salud-y-recursos.md)). El
`Job` de migraciones lo arregla sin tocar el servicio:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pricing-migrate
  namespace: apps
spec:
  # Dos reintentos: el primero suele ser Postgres que todavía no acepta conexiones.
  backoffLimit: 2
  # El Job terminado se borra solo a los diez minutos; su log se lee antes.
  ttlSecondsAfterFinished: 600
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: lab/pricing:g3
          command: ["/pricing", "migrate"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef: {name: pricing-db, key: DATABASE_URL}
```

```text
$ kubectl -n apps logs job/pricing-migrate
2026/10/04 03:35:24 migraciones aplicadas en postgres: 1
$ curl -sS -X PUT … http://api.localhost:8080/pricing/prices/SKU-0003
{"sku":"SKU-0003","store":"DRO-007","price":18000,"currency":"COP","regulatedCap":18000,"capped":true}
```

Un `Job` es un pod que corre **hasta terminar** y no se reinicia cuando termina bien. Con
`restartPolicy: Never`, un fallo crea otro pod, hasta `backoffLimit`. Y un detalle que molesta la
primera vez: un `Job` terminado no se puede volver a aplicar con otro contenido, porque su plantilla
es inmutable. `task migrate` lo borra y lo crea de nuevo, uno por servicio, y `task deploy` lo corre
antes de aplicar los servicios.

(Ese 18.000 es la circular de la [Fase 11](11-configuracion-y-secretos.md). `task deploy` devolvió el `ConfigMap` a 20.000 y dijo
`deployment.apps/pricing unchanged`: el pod siguió con el tope que leyó al arrancar. El incidente 09,
otra vez, sin buscarlo.)

**Prueba de fuego.** `task deploy -- minimo` con las cuatro migraciones terminadas, y
`task conformance TARGET=cluster -- G1` en verde con los servicios sobre Postgres.

**El patrón a memorizar.** El estado vive en un `StatefulSet` con su PVC; cada servicio, en su base y
con su usuario; y el esquema lo crea un `Job` antes del rollout, nunca la réplica al arrancar.

---

## 🔁 6. Los otros tres, el seed, y lo que G3 mostró

### 6.1 Donde no fue mecánico

**`inventory`** usaba `spring.sql.init`, que corre el esquema al arrancar y no sabe de motores: el
esquema de G1 tenía un `AUTOINCREMENT` que Postgres no entiende. Quedó un esquema por motor
(`schema-sqlite.sql`, `schema-postgresql.sql`) y una clase propia que los aplica; el comando de
migración es el mismo jar con `migrate`. Y JDBC no entiende `postgres://`: la URL se traduce al
arrancar.

**`catalog`** necesitó la extensión `pdo_pgsql`, que la imagen de PHP no trae: se compila con las
cabeceras de libpq y se borran después. Su migración es la de Laravel (`php artisan migrate --force`),
y `start.sh` solo migra cuando no hay `DATABASE_URL`.

**`replenish`** usaba el `node:sqlite` síncrono de Node; `pg` es asíncrono. Los manejadores pasaron a
`async`, detrás de una clase con dos métodos. Y Postgres devuelve los `BIGINT` como texto.

```text
$ task deploy -- minimo
job.batch/pricing-migrate condition met
2026/10/04 03:36:30 migraciones aplicadas en postgres: 1
job.batch/inventory-migrate condition met
… c.c.lab.inventory.Migrator : migraciones aplicadas en postgres: schema-postgresql.sql y data.sql
job.batch/catalog-migrate condition met
   INFO  Nothing to migrate.
job.batch/replenish-migrate condition met
migraciones aplicadas en postgres
```

La suite de G1 pasó dos veces seguidas contra los servicios con Postgres, y la de G2 también.

### 6.2 Dos réplicas que migran a la vez

`catalog` dijo `Nothing to migrate` porque ya estaba migrado, y la forma en que quedó migrado es la
lección. Antes, para ver qué pasa si dos réplicas migran al arrancar —como hacía G1—, lancé dos
migraciones a la vez sobre su base vacía, con un `Job` de `parallelism: 2`
(`deploy/jobs/experimentos/catalog-migrate-dos-a-la-vez.yaml`):

```text
$ kubectl -n apps get pods -l job-name=catalog-migrate-x2
NAME                       READY   STATUS      RESTARTS   AGE
catalog-migrate-x2-b2khm   0/1     Error       0          40s
catalog-migrate-x2-fnv6s   0/1     Completed   0          40s
[…] production.ERROR: SQLSTATE[23505]: Unique violation: 7 ERROR:  duplicate key value violates unique constraint "pg_class_relname_nsp_index"
DETAIL:  Key (relname, relnamespace)=(migrations_id_seq, 2200) already exists. (… SQL: create table "migrations" …)
```

Las dos vieron que no existía la tabla de control de Laravel y las dos la crearon. Una ganó. Esta vez
la base quedó bien (una migración aplicada, una vez); con una migración más larga, la segunda puede
morir a la mitad de la primera, y una réplica en `CrashLoopBackOff` es el síntoma más barato. Un `Job`
con una sola ejecución, antes del rollout, quita la carrera de raíz.

### 6.3 El seed, como `Job`

El seed es el `generate.py` de [a01](a01-el-laboratorio.md#-los-scripts), con su semilla
fija, empaquetado en una imagen con un `load.py` que lo carga **por la API de cada servicio**, nunca en
sus tablas (`deploy/jobs/seed.yaml`):

```text
$ task seed:job -- minimo
job.batch/seed condition met
sembrado: 8 productos en catalog, 160 precios en pricing (20 droguerías)
```

Cargar por la API es más lento que un `INSERT`, y es lo único que respeta la regla del curso: ningún
servicio, ni siquiera el seed, toca la base de otro.

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto, en dos versiones. De compose: *"para que los datos sobrevivan, un volumen"*. Correcto, y
aquí es un PVC. De Luz Marina: *"si funciona con uno, con dos es lo mismo pero más rápido"*. La sección
4 ya mostró que no, con SQLite. Con Postgres, la misma prueba:

```text
=== seis reposiciones de 5 · veinte consultas
  20 30
=== el ajuste de -12, cuatro veces
ADJUSTMENT -12 → 201
ADJUSTMENT -12 → 201
ADJUSTMENT -12 → 409
ADJUSTMENT -12 → 409
```

Una sola verdad: 30, y después 6. Y los datos sobreviven a todo lo que les pasa a los pods:

```text
$ kubectl -n data delete pod postgres-0
$ time kubectl -n data wait --for=condition=Ready pod/postgres-0 --timeout=180s
pod/postgres-0 condition met
real	0m1.029s
$ curl -sS http://api.localhost:8080/inventory/stock/DRO-007/SKU-0001
{"store":"DRO-007","sku":"SKU-0001","quantity":6,"reorderThreshold":0}
$ kubectl -n apps delete pod -l app.kubernetes.io/name=inventory
$ curl -sS http://api.localhost:8080/inventory/stock/DRO-007/SKU-0001
{"store":"DRO-007","sku":"SKU-0001","quantity":6,"reorderThreshold":0}
```

**Y ahora, lo que Postgres no arregla.** Veinte reposiciones de 1 unidad **a la vez**:

```text
respuestas: {201: 20}
después: 9 (se esperaban 20)
respuestas: {201: 20}
después: 4 (se esperaban 20)
```

Con dos réplicas, 9 y 4. Con **una** réplica, 5 y 6. `inventory` lee la existencia, suma y escribe, en
tres sentencias sin transacción; con varias conexiones, dos lecturas ven el mismo número y una escritura
pisa a la otra. Postgres le dio al sistema una sola verdad, no atomicidad. La carrera estaba en el
código desde G1, y el pool de una conexión de SQLite la hacía menos probable. **La cobra la [Fase 16](16-escalado-y-rollout.md)**,
cuando la venta completa pasa por aquí.

> 🪞 **Apuesta antes de ejecutar (B-12).** La suite de pruebas contra Postgres con Testcontainers tarda
> más de diez veces lo que contra SQLite, y hay al menos un comportamiento (una restricción o un tipo)
> que SQLite acepta y Postgres rechaza.
>
> **Resultado: perdida en el tiempo que importa, ganada en la fidelidad.** Las siete pruebas del
> almacén de `pricing`, las mismas contra los dos motores, con `task test:pricing` en un contenedor:

| | la tarea | `go test` | pasan | fallan |
|---|---|---|---|---|
| SQLite | 5,45 s | 0,10 s | 7 | ninguna |
| Postgres con Testcontainers | 12,70 s | 6,24 s | 6 | `TestLargePrice` |
| Postgres / SQLite | **2,3x** | **59x** | | |

El binario de pruebas tarda 59 veces más, porque arranca un Postgres; la tarea que corre una persona,
solo 2,3, porque el contenedor y la compilación pesan igual con los dos. Y la prueba que falla guarda
un precio de 3.000.000.000, que el contrato permite:

```text
--- FAIL: TestLargePrice (0.00s)
    main_test.go:152: PUT de un precio grande: 500 map[error:internal message:failed to encode args[2]: unable to encode 3000000000 into binary format for int4 (OID 23): 3000000000 is greater than maximum value for int4]
```

SQLite guarda cualquier entero en una columna `INTEGER`; Postgres, solo hasta 2.147.483.647. Con SQLite
en las pruebas, ese 500 se habría descubierto en producción. La entrada completa, en
[BENCHMARKS.md](BENCHMARKS.md#b-12--qué-se-gana-y-qué-se-pierde-probando-contra-sqlite-en-lugar-del-motor-real).
El error queda en `pricing` a propósito: arreglarlo con una migración es el ejercicio 21.

Testcontainers corre aquí dentro de un contenedor, con el socket del motor montado: le pide al motor un
contenedor hermano. Es cómodo, y es darle a una prueba el control del motor entero; con Podman no se
verificó.

---

## 🧨 8. La rotura: el aviso de traslados y su bloqueo

El aviso de traslados de la Braqui ([a16](a16-el-patrimonio.md)) es un script de Python que `cron`
corre cada cinco minutos, con tres parches de 2020. Uno es un **archivo de bloqueo**: si existe, otra
corrida está en curso, y el script sale callado. Con la carpeta de traslados como PVC compartido entre
Contingencia y el script, en `legacy`, el préstamo 1 llega y se procesa:

```text
=== 22:42:47 préstamo 1: dos inhaladores de Girón (DRO-003) a Chapinero (DRO-007)
<return>1</return>
=== 22:43:21 Contingencia dejó el archivo:
traslados_20261003_2243.txt
=== 22:44:36 el log del aviso (cron, cada minuto):
traslados_20261003_2243.txt: 1 traslados recibidos
```

**El cambio exacto:** una corrida que muere a la mitad deja su bloqueo. Lo simulé creando el archivo
que dejaría, y pedí otro préstamo:

```text
=== 22:45:20 archivo nuevo:
procesados/traslados_20261003_2243.txt
traslados_20261003_2245.txt
=== 22:47:50 dos minutos y medio después: el log no dice nada nuevo, y el archivo sigue ahí
traslados_20261003_2243.txt: 1 traslados recibidos
traslados_20261003_2245.txt
```

**El síntoma:** ninguno. El script corre cada minuto, ve el bloqueo y sale sin escribir una línea. Lo
que haría cualquiera —reiniciar— tampoco ayudó: `kill 1` no hizo nada, porque `crond` como proceso 1
no atiende `SIGTERM` (la [Fase 03](03-el-contenedor-por-dentro.md), otra vez), y el bloqueo está en un `emptyDir`, que sobrevive a los
reinicios del contenedor. El préstamo 2 no llegó a la base de la Braqui:

```text
=== 22:49:31 traslados en la base de la Braqui:
traslados_20261003_2243.txt|1
```

**Para salir:** que la plataforma haga lo que el bloqueo intentaba hacer. Un `CronJob`:

```yaml
spec:
  schedule: "* * * * *"
  timeZone: America/Bogota
  # Si una corrida sigue andando, la siguiente no arranca: lo que hacía el archivo de bloqueo.
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      # Una corrida colgada se mata a los dos minutos: lo que el bloqueo no sabía hacer.
      activeDeadlineSeconds: 120
      template:
        spec:
          containers:
            - name: traslados
              command: ["/app/.venv/bin/python", "/app/process_transfers.py"]
              env:
                # El bloqueo, dentro del pod: si la corrida muere, el bloqueo muere con ella.
                - {name: LOCK_FILE, value: /tmp/traslados.lock}
```

Un pod por corrida. El script es el mismo, con su bloqueo, pero el bloqueo vive y muere con el pod, y
la exclusión la garantiza `concurrencyPolicy: Forbid`:

```text
NAME                        STATUS     COMPLETIONS   DURATION   AGE
braqui-traslados-29851430   Complete   1/1           3s         72s
braqui-traslados-29851431   Complete   1/1           3s         12s
--- job.batch/braqui-traslados-29851430
traslados_20261003_2245.txt: 1 traslados recibidos
=== 22:51:12 traslados en la base de la Braqui:
traslados_20261003_2243.txt|1
traslados_20261003_2245.txt|1
```

Las otras mañas del script —reconocer un archivo por su nombre, la escritura que Contingencia confirma
antes de escribir el archivo— no las arregla ningún `CronJob`. Quedan anotadas para la Parte IV.

---

## ⚰️ 9. Autopsia: la Braqui pegada a las tablas del Siga

**La decisión, con su mejor argumento.** En 2023, Germán hizo de la Braqui un módulo del Siga: dejó su
base y pasó a leer y escribir en las tablas del Siga. *"Una sola fuente de verdad: el mismo inventario
para saber qué lleva cada moto, los mismos reportes, la misma auditoría."* Y la tuvo.

**Por qué era razonable.** Con dos bases, cada reporte del BI cruzaba dos sistemas y nadie sabía cuál
tenía razón. Una base resolvía eso de un plumazo, sin escribir una sola interfaz.

**Qué pasa después, con número.** En el laboratorio, la Braqui corre en `legacy` como en el patrimonio:
cada 30 segundos lee los despachos pendientes en las tablas de Contingencia y les asigna una moto.

```text
$ (una venta a domicilio en Contingencia, por SOAP)
<return>4</return>
$ kubectl -n legacy logs deploy/braqui | tail -1
despacho 4 (DRO-007, Calle 63 # 9-41, Chapinero) asignado a Diana Garzón
```

Funciona, hasta que el Núcleo cambia **su** tabla. Un renombre de columna, el cambio de esquema más
inocente que existe:

```text
$ psql … -c "ALTER TABLE dispatch RENAME COLUMN address TO delivery_address"
ALTER TABLE
$ (otra venta a domicilio, por SOAP)
<faultstring>jakarta.ejb.EJBException</faultstring>
$ kubectl -n legacy logs deploy/braqui | tail -1
error consultando despachos: column "address" does not exist
```

Un cambio, **dos sistemas rotos**, de dos equipos, en dos lenguajes. En el Siga, por eso, los cambios de
esquema de la Braqui entran en las ventanas de despliegue del Siga, aprobados por arquitectura: dos
equipos atados a un esquema y a un calendario. (El renombre se revirtió.)

**Cuánto cuesta salir, con número.** Lo que hizo esta fase con los servicios nuevos: una base y un
usuario por servicio (`REVOKE ALL … FROM PUBLIC`), y los datos de otro equipo solo por su API. Para la
Braqui del patrimonio, una interfaz que hoy no existe, y meses.

**Qué lo habría cambiado.** Preguntar *¿quién más va a depender de esta tabla, y quién decide cuándo
cambia?* antes de abrirla a un segundo equipo.

**Antes y después, con números:** antes, un renombre de columna rompió 2 sistemas; con una base por
servicio, `replenish` —la heredera de la Braqui— no tiene permiso para leer ninguna tabla de
`inventory`, y el mismo renombre en la base de `inventory` rompería solo a `inventory`.

---

## 📖 10. Traducción

| En compose o en la máquina virtual | En Kubernetes | Lo que cambia |
|---|---|---|
| `volumes:` con nombre | `PersistentVolumeClaim`, que cumple una `StorageClass` con un `PersistentVolume` | el disco lo pide el pod y lo da el cluster; en kind, una carpeta del nodo |
| un servicio de base de datos en compose | un `StatefulSet` con `volumeClaimTemplates` y un `Service` headless | cada réplica, su disco y su nombre estable |
| el script de esquema en `docker-entrypoint-initdb.d` | lo mismo, desde un `ConfigMap`, para crear bases y usuarios | corre una vez, con la carpeta de datos vacía |
| migrar al arrancar el contenedor | un `Job`, antes del rollout | una sola ejecución; nadie compite |
| `docker compose run --rm seed` | un `Job` | se reintenta solo, hasta `backoffLimit` |
| `cron` en un contenedor o en el servidor | un `CronJob` | la exclusión y el tiempo límite son de la plataforma |

Y de vuelta: un `StatefulSet` con una réplica, en compose, es un servicio con un volumen con nombre; con
tres, no tiene traducción, porque compose no da identidad estable por réplica. Las filas completas, en
[a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, la `StorageClass` es el disco de bloque del proveedor, con su costo por GB y por
operación, y su zona: un disco de una zona no sigue a un pod que cae en otra.

---

## 🩺 11. Incidentes de esta fase

- **[11 — Postgres se queda esperando para siempre](cuaderno-incidentes.md#-incidente-11--postgres-se-queda-esperando-para-siempre).**
  Un pod en `Pending`, un PVC en `Pending`, y ningún error en ningún log.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Postgres en el cluster: lo vas a hacer aquí, y probablemente no en producción.** Lo que este
laboratorio no tiene y una base de producción sí necesita: respaldos que se prueban restaurando,
réplicas con conmutación, actualizaciones de versión sin perder datos, y un disco que sobreviva al
cluster (el de kind no sobrevive a `kind delete cluster`). Un `StatefulSet` escrito a mano no hace
ninguna de esas cosas. Las opciones serias son dos: un **servicio gestionado** del proveedor, que hace
todo eso y te cobra cada mes, o un **operador** (CloudNativePG es el más usado para Postgres), que lo
automatiza dentro del cluster y te deja a ti la operación. Este curso no instala ninguno: el
`StatefulSet` está para que entiendas qué automatizan.

**Una instancia para cuatro bases** es la divergencia de la sección 5.3: el diseño queda bien, la
operación queda acoplada.

**Cuándo NO un `CronJob`.** Si el trabajo no puede esperar al próximo minuto, o si dos corridas
seguidas no pueden ver el mismo archivo, el problema no es el planificador: es que el aviso viaja en un
archivo. La Parte IV lo cambia por un mensaje.

**Y cuándo SQLite está bien.** Para lo que no depende del motor: lógica que no toca SQL específico. Para
las pruebas del almacén, B-12 dice que el motor real cuesta 7 segundos más por corrida y encontró un
error que SQLite dejó pasar.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso que escribe en una carpeta.
El orquestador te dio el PVC, el `StatefulSet`, el `Job` y el `CronJob`, y un disco que sigue al pod.
**Te tocó a ti** separar las bases, migrar antes del rollout, cargar los datos por la API, y saber que
la carrera de `inventory` sigue ahí.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`relation "…" does not exist` justo después de desplegar.** Causa: el servicio llegó antes que su
esquema. Salida: `task migrate`, y que `task deploy` lo corra primero.

**`The Job "…" is invalid: spec.template: … field is immutable` al aplicar un `Job`.** Causa: un `Job`
no se edita. Salida: borrarlo y crearlo,
como `task migrate`.

**El pod de Postgres en `Pending`.** Es el incidente 11: mira el PVC antes que el pod.

**`Bound` y después nada en el disco.** Causa: se montó otra carpeta. Postgres 18 guarda en
`/var/lib/postgresql/18/docker`; se monta `/var/lib/postgresql`. Comprobación 🩺:
`kubectl -n data exec postgres-0 -- printenv PGDATA`.

**El servicio `OOMKilled` sin un límite declarado.** Causa: el nodo se quedó sin memoria y el kernel
mató al proceso más grande sin garantías. En la verificación, Contingencia murió tres veces así, con el
patrimonio, Postgres, QA y dos réplicas de `inventory` en 4 GiB
([a01](a01-el-laboratorio.md#-la-memoria-que-ocupa-cada-perfil)). La [Fase 15](15-salud-y-recursos.md) lo explica.

**La Braqui deja de asignar motos.** Causa: alguien cambió una tabla del Siga. `kubectl -n legacy logs
deploy/braqui` lo dice cada 30 segundos.

---

## 📋 14. Checklist de validación

```text
[ ] el stock fantasma con dos réplicas sobre SQLite, visto
[ ] task platform:postgres -- minimo: postgres-0 Running, data-postgres-0 Bound, cuatro bases
[ ] el servicio antes que su esquema (relation … does not exist), y el Job que lo arregla
[ ] las dos migraciones a la vez, y una en Error
[ ] task deploy -- minimo con las cuatro migraciones, y la suite de G1 en verde dos veces
[ ] task seed:job: 8 productos y 160 precios
[ ] la misma prueba de dos réplicas sobre Postgres: una sola respuesta
[ ] los datos después de borrar postgres-0 y el pod de inventory
[ ] task measure -- B-12 y la prueba que falla en Postgres
[ ] el bloqueo huérfano del aviso de traslados, y el CronJob que lo reemplaza
```

---

## 🧪 15. Ejercicios (24)

Un tercio son de diagnóstico; varios trabajan con el patrimonio.

## 🟢 Fácil — el disco y la base (1–6)

### 🟢 Ejercicio 1 — Postgres de cero
Instala Postgres en `minimo` y lista sus bases.

**Criterio:** `postgres-0` en `Running` y las cuatro bases en `\l`.

<details><summary>Solución</summary>

`task platform:postgres -- minimo` y `kubectl -n data exec postgres-0 -- psql -U postgres -c '\l'`.
</details>

### 🟢 Ejercicio 2 — Los tres objetos del disco
Muestra el PVC, el PV y la `StorageClass` de Postgres, y di quién creó cada uno.

**Criterio:** los tres, con su dueño.

<details><summary>Solución</summary>

`kubectl -n data get pvc`, `kubectl get pv`, `kubectl get storageclass`. El PVC, el `StatefulSet`
(desde su plantilla); el PV, el provisionador de la `StorageClass`; la `StorageClass`, kind al crear el
cluster.
</details>

### 🟢 Ejercicio 3 — Migrar
Corre las migraciones y lee el log de cada una.

**Criterio:** las cuatro `complete`, y su línea de log.

<details><summary>Solución</summary>

`task migrate -- minimo`.
</details>

### 🟢 Ejercicio 4 — Sembrar
Corre el seed y comprueba los precios de una droguería.

**Criterio:** 8 precios en `DRO-012`.

<details><summary>Solución</summary>

`task seed:job -- minimo` y `curl -s 'http://api.localhost:8080/pricing/prices?store=DRO-012'`.
</details>

### 🟢 Ejercicio 5 — El nombre de la réplica
Resuelve `postgres-0.postgres.data.svc.cluster.local` desde un pod de `apps`.

**Criterio:** la IP del pod de Postgres.

<details><summary>Solución</summary>

`kubectl -n apps exec deploy/inventory -- getent hosts postgres-0.postgres.data.svc.cluster.local`.
</details>

### 🟢 Ejercicio 6 — Sobrevivir
Borra el pod de Postgres y comprueba que los datos siguen.

**Criterio:** la misma existencia antes y después.

<details><summary>Solución</summary>

`kubectl -n data delete pod postgres-0`, `kubectl -n data wait --for=condition=Ready pod/postgres-0`, y
el `curl` de la existencia.
</details>

## 🟡 Intermedio — el orden y la frontera (7–13)

### 🟡 Ejercicio 7 — El fantasma, en tu máquina
Repite la sección 4 con la imagen de G1 y dos réplicas.

**Criterio:** dos respuestas distintas a la misma consulta, sin un error en los logs.

<details><summary>Solución</summary>

`kubectl -n apps set image deploy/inventory inventory=lab/inventory:g1` (cargada en el nodo), la
variable `DATABASE_URL` quitada, `scale --replicas=2`, y las consultas. Vuelve con `task deploy`.
</details>

### 🟡 Ejercicio 8 — Ninguna tabla ajena
Intenta leer una tabla de `inventory` con el usuario de `replenish`. **Predice** el error.

**Criterio:** la predicción y el error literal.

<details><summary>Solución</summary>

`psql` con la `DATABASE_URL` de `replenish` apuntando a la base `inventory`: `FATAL:  permission denied
for database "inventory"` y `DETAIL:  User does not have CONNECT privilege.`, por el `REVOKE ALL … FROM
PUBLIC` del `init.sh`. El usuario ni siquiera entra a la base.
</details>

### 🟡 Ejercicio 9 — El rollout antes del esquema
Borra la tabla de `replenish`, reinicia el servicio y pide una orden.

**Criterio:** el 500 con `relation … does not exist`, y el `Job` que lo arregla.

<details><summary>Solución</summary>

`DROP TABLE replenishment_orders` como `postgres`, `kubectl rollout restart`, un `POST`, y `task migrate`.
</details>

### 🟡 Ejercicio 10 — Las dos migraciones
Reproduce la sección 6.2 con la base de `catalog` vacía.

**Criterio:** un pod en `Error` con el `duplicate key value`.

<details><summary>Solución</summary>

Borra y crea la base `catalog` como `postgres`, y `kubectl apply -f deploy/jobs/experimentos/catalog-migrate-dos-a-la-vez.yaml`.
Puede tocarte que las dos terminen bien: es una carrera. Repite.
</details>

### 🟡 Ejercicio 11 — El seed dos veces
Corre el seed dos veces. **Predice** cuántos productos hay después.

**Criterio:** la predicción y el conteo, antes y después de la segunda corrida.

<details><summary>Solución</summary>

Los mismos que antes: `load.py` toma el 409 de un producto que ya existe como cargado, y el precio se
vuelve a poner igual. En la verificación fueron 9, no 8: el noveno lo creó la suite de G1, que también
escribe en la base desde que es Postgres.
</details>

### 🟡 Ejercicio 12 — Las pruebas
Corre la suite de `pricing` contra los dos motores.

**Criterio:** 7 de 7 con SQLite, 6 de 7 con Postgres, y el mensaje de la que falla.

<details><summary>Solución</summary>

`task test:pricing` y `task test:pricing DB=postgres`.
</details>

### 🟡 Ejercicio 13 — El disco y el cluster
Muestra dónde está, en el nodo, la carpeta del disco de Postgres. **Predice** qué pasa con ella al borrar el cluster.

**Criterio:** la ruta, y la predicción.

<details><summary>Solución</summary>

`kubectl get pv -o custom-columns=…` y `docker exec minimo-control-plane ls /var/local-path-provisioner`.
Se va con el nodo: es una carpeta dentro de un contenedor.
</details>

## 🟠 Difícil — diagnosticar (14–19)

### 🟠 Ejercicio 14 — El incidente 11
Provoca el incidente 11 y diagnostícalo sin el cuaderno. **Predice** dónde está el error.

**Criterio:** la causa y el comando que la confirmó.

**Rúbrica:** el pod no dice la causa; el PVC sí; y la `StorageClass` que existe en el cluster.

### 🟠 Ejercicio 15 — La carrera de `inventory`
Repite la prueba de las veinte reposiciones a la vez con una sola réplica.

**Criterio:** el número final, y una explicación de por qué no es 20.

**Rúbrica:** las tres sentencias sin transacción; el pool de conexiones; y por qué una réplica no basta
para evitarlo.

### 🟠 Ejercicio 16 — El bloqueo huérfano
Reproduce el bloqueo huérfano con el manifiesto de `antes-de-la-fase-12`, y sácalo sin borrar el pod.

**Criterio:** el préstamo procesado.

**Rúbrica:** el archivo de bloqueo, dónde está, y por qué `kill 1` no sirvió.

### 🟠 Ejercicio 17 — El `CronJob` que se solapa
Haz que una corrida del aviso tarde más de un minuto. **Predice** qué hace el `CronJob` con la siguiente.

**Criterio:** la predicción, y lo que muestran `get jobs` y los eventos del `CronJob`.

**Rúbrica:** `concurrencyPolicy: Forbid` salta la corrida; con `Allow`, dos a la vez; y qué hace
`activeDeadlineSeconds` si la corrida pasa de dos minutos.

### 🟠 Ejercicio 18 — La tabla compartida
Cambia otra cosa de la tabla `dispatch` (un tipo, un valor de `status`) y mira a quién rompe.

**Criterio:** los síntomas en Contingencia y en la Braqui.

**Rúbrica:** cuál de los dos lo nota primero, y cuál no lo nota nunca (un valor nuevo de `status` que
la Braqui no busca no da error: deja motos sin asignar).

### 🟠 Ejercicio 19 — El tope que no cambió
Explica, con comandos, por qué `pricing` respondía 18.000 después de `task deploy` con el `ConfigMap`
en 20.000.

**Criterio:** el `ConfigMap`, el log de arranque de `pricing`, y la generación del `Deployment`.

**Rúbrica:** `unchanged`; el incidente 09; y lo que haría el hash de la [Fase 13](13-helm-el-paquete.md).

## 🔴 Muy difícil — el sistema con estado (20–24)

### 🔴 Ejercicio 20 — La transacción
Arregla la carrera de `inventory`: veinte reposiciones a la vez dejan 20.

**Criterio:** la prueba de la sección 7 con 20, cinco veces seguidas.

**Rúbrica:** `UPDATE … SET quantity = quantity + ?` o `SELECT … FOR UPDATE` dentro de una transacción;
qué pasa con el ajuste que no puede dejar la existencia en negativo; y por qué el cambio va en el
prompt de G5, no solo en el código.

### 🔴 Ejercicio 21 — El precio grande
Haz que `TestLargePrice` pase en Postgres con una migración nueva, sin romper SQLite.

**Criterio:** 7 de 7 en los dos motores, y la migración aplicada como `Job` sobre la base con datos.

**Rúbrica:** `ALTER TABLE prices ALTER COLUMN price TYPE BIGINT` en Postgres; qué hacer en SQLite (nada:
ya lo acepta); y cómo una lista de migraciones idempotentes maneja un cambio que no lo es.

### 🔴 Ejercicio 22 — Dos réplicas de Postgres
Sube el `StatefulSet` a dos réplicas. **Predice** qué obtienes.

**Criterio:** la predicción y lo que hay en `postgres-1`.

**Rúbrica:** dos servidores independientes con dos discos, no una réplica: en la verificación,
`postgres-1` tenía las cuatro bases (el `init.sh` corrió en su disco vacío) y ninguna tabla
(`relation "prices" does not exist`). Lo que haría falta (replicación de Postgres) y por qué es trabajo
de un operador. Y al bajar a una réplica, el PVC `data-postgres-1` se queda: hay que borrarlo a mano.

### 🔴 Ejercicio 23 — Un respaldo que se restaura
Haz un respaldo de la base de `pricing` con un `Job`, bórrala, y restáurala.

**Criterio:** los 160 precios después de restaurar.

**Rúbrica:** `pg_dump` en un `Job` con el usuario de `pricing`; dónde quedó el archivo (y por qué no en
el mismo disco); y cuánto tardó.

### 🔴 Ejercicio 24 — La base de la Braqui
Diseña cómo sacar a la Braqui de las tablas del Siga.

**Criterio:** un documento corto con la base nueva, la interfaz y los pasos.

**Rúbrica:** qué datos son de la Braqui (motos, asignaciones) y cuáles los lee de otro (despachos); la
interfaz que tendría que exponer Contingencia; el orden (leer por la interfaz, después dejar de leer la
tabla); y cómo se parece al *strangler* de la [Fase 10](10-la-entrada-al-sistema.md).

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *Persistent Volumes*: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- Kubernetes, *StatefulSets*: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- Kubernetes, *Jobs* y *CronJob*: https://kubernetes.io/docs/concepts/workloads/controllers/job/ ·
  https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
- Postgres, la imagen oficial (variables, `docker-entrypoint-initdb.d`): https://hub.docker.com/_/postgres
- Testcontainers para Go, módulo de Postgres: https://golang.testcontainers.org/modules/postgres/
- CloudNativePG, para leer qué automatiza un operador: https://cloudnative-pg.io/documentation/current/

**Libros**

- Martin Kleppmann, *Designing Data-Intensive Applications* (2017), el capítulo de transacciones: la
  carrera de la sección 7 tiene nombre (*lost update*).
- Sam Newman, *Building Microservices*, 2.ª edición (2021), el capítulo sobre bases compartidas.

**Orden de lectura sugerido:** antes, *Persistent Volumes*; durante, *StatefulSets*; después, el
capítulo de Kleppmann, con la sección 7 delante.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 12 (minimo)

  data      postgres-0 (StatefulSet)  ← PVC data-postgres-0 (1 GiB, standard)  · Service headless postgres
            bases pricing · inventory · catalog · replenish, cada una con su usuario
  apps      los cuatro backends en :g3, con DATABASE_URL de su Secret <svc>-db
            Jobs <svc>-migrate antes del rollout (task deploy) · Job seed (task seed:job)
  legacy    braqui (lee las tablas de Contingencia)  · CronJob braqui-traslados (Forbid, 120 s)
            PVC traslados, compartido con Contingencia
  .secrets/postgres.env   ← fuera de git
```

> **La señal de que quedó bien:** *"Le subo las réplicas a un servicio sin miedo a que cada una tenga
> su verdad, migro antes de desplegar, y sé qué no arregla una base compartida: la carrera y el
> acoplamiento."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-12-estado-y-almacenamiento -m "F12 cerrada: Postgres como StatefulSet con una base por servicio; G3 con migraciones como Job y seed como Job; B-12; la Braqui en legacy y el aviso de traslados como CronJob; incidente 11"
> ```
>
> Y el par del incidente: `inc/11/pvc-storageclass-missing-roto` e `inc/11/pvc-storageclass-missing-fix`.
> Commits con prefijo `f12:` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F13:** los `Job` de migración y de seed como *hooks* de Helm; el hash del `ConfigMap` de topes.
- **F15:** límites de memoria para Contingencia y los servicios (el `OOMKilled` de la sección 13).
- **F16:** la carrera de `inventory` (sección 7), en el prompt de G5.
- **B-04:** el build en frío de `pricing` pasó de 5,8 s (B-04, con G0) a 398 s con G3, en una corrida
  sin caché: `go mod download` baja también las dependencias de las pruebas (Testcontainers y su cliente
  de Docker). Conviene separar esas dependencias o descargar solo las del binario; la entrada de B-04
  quedó desactualizada para `pricing`.
