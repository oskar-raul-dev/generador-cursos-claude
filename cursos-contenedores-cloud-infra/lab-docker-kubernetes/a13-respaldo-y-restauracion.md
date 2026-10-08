# 📎 Apéndice a13 — Respaldo y restauración de los datos del cluster

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 12](12-estado-y-almacenamiento.md) (el Postgres del cluster) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** la de un `Job` de `pg_dump` mientras corre (pide 64 MiB, 14 s cada noche); un PVC de 1 GiB
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop, cluster `lab` y un cluster temporal `a13`

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. Contesta dos preguntas que la
[Fase 12](12-estado-y-almacenamiento.md) dejó planteadas: *"¿cómo respaldo el Postgres del cluster?"* y *"¿qué pasa con mis
datos si borro el cluster?"*. La primera tiene un `CronJob`; la segunda, una respuesta que conviene saber antes.

**Qué queda fuera:** el respaldo continuo con el registro de escritura de Postgres (WAL) y la recuperación a un instante;
los respaldos de volúmenes con Velero, que se nombra; los respaldos fuera de la máquina.

---

## Índice

- [El respaldo, como `CronJob`](#el-respaldo-como-cronjob)
- [La restauración, probada de punta a punta](#la-restauración-probada-de-punta-a-punta)
- [Qué pasa con los datos cuando se borra el cluster](#qué-pasa-con-los-datos-cuando-se-borra-el-cluster)
- [Lo que este respaldo no cubre](#lo-que-este-respaldo-no-cubre)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-6)

---

## El respaldo, como `CronJob`

El manifiesto está en `src/lab/platform/data/backup/postgres-backup.yaml`, y ninguna tarea del camino base lo aplica:

```bash
kubectl apply -f platform/data/backup/
```

Cada noche a las tres, un `pg_dump` por base en formato *custom* (el que `pg_restore` restaura por partes), y los roles
aparte, en un PVC propio, con siete días de historia. Lo esencial:

```yaml
spec:
  schedule: "0 3 * * *"            # a las tres de la mañana, cuando nadie vende
  concurrencyPolicy: Forbid        # un respaldo a la vez
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: postgres@sha256:5a5a84b1…   # postgres:18.6: pg_dump de la misma versión que la base
              command:
                - sh
                - -ec
                - |
                  dir=/backups/$(date -u +%Y%m%dT%H%M%SZ)
                  mkdir -p "$dir"
                  pg_dumpall --globals-only > "$dir/roles.sql"
                  for db in $(psql -At -c "SELECT datname FROM pg_database WHERE datallowconn AND datname NOT IN ('postgres', 'template1')"); do
                    pg_dump -Fc -d "$db" -f "$dir/$db.dump"
                  done
```

Corre como el usuario 999, sin capacidades, con la misma imagen del servidor y el `Secret` que ya existía. La
`NetworkPolicy` de Postgres ([Fase 20](20-seguridad-del-pod-y-de-la-red.md)) lo deja entrar porque vive en `data`. Una
corrida a mano, sin esperar a las tres:

```text
$ kubectl -n data create job postgres-backup-a13 --from=cronjob/postgres-backup
-rw-r--r-- 1 postgres postgres    6221 Oct  5 08:25 catalog.dump
-rw-r--r-- 1 postgres postgres 1205371 Oct  5 08:25 inventory.dump
-rw-r--r-- 1 postgres postgres    2323 Oct  5 08:25 pricing.dump
-rw-r--r-- 1 postgres postgres  430166 Oct  5 08:25 replenish.dump
-rw-r--r-- 1 postgres postgres    2895 Oct  5 08:25 roles.sql
            (y las cuatro bases de la segunda cadena, *_tenant_b.dump)
duración: 2026-10-05T08:25:29Z → 2026-10-05T08:25:43Z
```

Catorce segundos para las ocho bases de las dos cadenas. Lo más pesado es `inventory`, con los movimientos y las sagas
de la Parte IV.

## La restauración, probada de punta a punta

Un respaldo que no se restauró nunca es una hipótesis. El desastre, en una base chica: **se borra la base de `pricing`**.

```text
DROP DATABASE
+8 s · precio por la puerta: 500 · venta: 503 · pricing: 0/1
```

El precio da 500, la venta 503, y la readiness de `pricing` ([Fase 15](15-salud-y-recursos.md), G4) lo saca del tráfico.
La restauración es un `Job` con la misma imagen y el PVC de los respaldos montado en solo lectura:

```sh
last=$(ls -d /backups/*/ | sort | tail -1)
psql -c "CREATE DATABASE pricing OWNER pricing"
psql -c "REVOKE ALL ON DATABASE pricing FROM PUBLIC"
pg_restore -d pricing --exit-on-error "$last/pricing.dump"
psql -d pricing -At -c "SELECT count(*) FROM prices"
```

```text
restaurando desde /backups/20261005T082540Z/
CREATE DATABASE
REVOKE
166
+12 s · precio por la puerta: 200 · {"sku":"SKU-0001","store":"DRO-001","price":24100,…} · venta: 201
```

Los 166 precios de vuelta, y la venta a los 12 s del desastre, sin reiniciar `pricing`: el pool de conexiones de G3
reconectó solo cuando la base volvió. **El dueño de la base** se crea igual que en `init.sh` (la base es de `pricing`, no
de `postgres`), o el servicio se queda sin permisos sobre sus propias tablas.

## Qué pasa con los datos cuando se borra el cluster

Los PVC del curso usan la `StorageClass` `standard` de kind, que guarda cada volumen **en una carpeta del nodo**. Y el nodo
es un contenedor. Un cluster temporal `a13`, de un nodo, con una carpeta del host montada en él (`extraMounts`):

```yaml
nodes:
  - role: control-plane
    image: kindest/node@sha256:099e0493…
    extraMounts:
      - hostPath: /ruta/del/host/respaldos       # una carpeta de tu máquina
        containerPath: /respaldos
```

Un pod escribe lo mismo en un PVC y en la carpeta montada. Se borra el cluster, se crea otra vez con la misma
configuración, y otro pod lee los dos:

```text
--- kind delete cluster --name a13
Deleted nodes: ["a13-control-plane"]
en el host: pedido de Chapinero
--- el mismo cluster, otra vez
PVC:
cat: /datos/pedido.txt: No such file or directory
carpeta del host:
pedido de Chapinero
```

**`kind delete cluster` se lleva todos los PVC**: el Postgres del curso, sus respaldos si están en un PVC, y lo que haya en
`legacy`. Lo único que sobrevive es lo que está fuera del nodo. Por eso el respaldo de verdad no puede vivir en el PVC del
mismo cluster: en el laboratorio, una carpeta del host con `extraMounts` (que exige recrear el cluster para agregarla); en
una nube, un almacenamiento de objetos fuera del cluster.

> ⚠️ El `extraMounts` del ejemplo no está en los archivos de kind del curso ([a01](a01-el-laboratorio.md)). Agregarlo
> al cluster `lab` es recrearlo, con todo lo que eso borra.

## Lo que este respaldo no cubre

- **Lo que pasó después del último `pg_dump`.** Con un respaldo por noche, un desastre a las seis de la tarde pierde el
  día. La recuperación a un instante necesita el registro de escritura de Postgres archivado, y queda fuera.
- **La coherencia entre bases.** Cada `pg_dump` es coherente en su base, pero las ocho no se toman en el mismo instante: un
  préstamo de la [Fase 24](24-la-saga-orquestada.md) puede quedar con su reserva en el respaldo de `inventory` y sin su
  orden en el de `replenish`. Restaurar una base sola es restaurar un servicio a otro momento que sus vecinos, y la saga
  y el outbox ([Fase 26](26-idempotencia-y-outbox.md)) son los que tienen que aguantarlo.
- **El bus.** El stream de NATS ([Fase 25](25-la-coreografia.md)) vive en su propio PVC, y este `CronJob` no lo toca.
- **Los volúmenes como tales**, que es lo que hace Velero; no se instaló.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| el Postgres del laboratorio | el `CronJob` de este apéndice, copiando los respaldos fuera del nodo | 14 s por noche, y una restauración probada |
| no perder más que minutos | el registro de escritura archivado, o un Postgres gestionado | un respaldo por noche pierde el día |
| respaldar volúmenes de cualquier cosa, no solo Postgres | Velero, con un almacenamiento de objetos | sabe de PVC y de objetos de Kubernetes; no se verificó aquí |
| recrear el cluster de kind sin perder datos | `extraMounts` a una carpeta del host, o restaurar los respaldos en el cluster nuevo | los PVC mueren con el nodo |

## ⚠️ Advertencias

- Un respaldo y una restauración; el tiempo de 14 s es de estas bases, de este tamaño.
- El `Job` de restauración no borra nada: crea la base. Si la base existe, falla en el `CREATE DATABASE`, y eso es a propósito.
- La segunda cadena tiene sus bases en el mismo Postgres: un `DROP` equivocado de nombre es un desastre en la otra cadena.
- `kind create cluster --name a13` cambia el contexto de `kubectl` al cluster nuevo, y `kind delete cluster` lo deja
  **vacío**, no de vuelta en `kind-lab`: `kubectl config use-context kind-lab` antes del próximo comando.

## 📚 Referencias

- PostgreSQL, `pg_dump`: https://www.postgresql.org/docs/current/app-pgdump.html y `pg_restore`:
  https://www.postgresql.org/docs/current/app-pgrestore.html
- Kubernetes, *CronJob*: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
- kind, *Extra Mounts*: https://kind.sigs.k8s.io/docs/user/configuration/#extra-mounts
- El aprovisionador de volúmenes de kind (dónde viven los PVC): https://github.com/rancher/local-path-provisioner
- Velero: https://velero.io/docs/

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (6)

### Ejercicio 1 — El primer respaldo
Aplica el `CronJob` y corre un respaldo a mano.

**Criterio:** los nueve archivos (ocho bases y los roles) en el log del `Job`, y su duración.

### Ejercicio 2 — La restauración de `pricing`
Repite el desastre de la sección de restauración.

**Criterio:** el precio en 500 después del `DROP`, y en 200 con los 166 precios después de restaurar.

### Ejercicio 3 — Restaurar sin borrar
Restaura `inventory` en una base nueva, `inventory_restaurada`, y compara la cantidad de filas de `stock_movements` con la
original.

**Criterio:** las dos cuentas, y la diferencia explicada por las ventas hechas después del respaldo.

### Ejercicio 4 — Los respaldos fuera del nodo
Haz que el respaldo termine en una carpeta del host (`extraMounts` en un cluster nuevo, o un `kubectl cp` después del `Job`).

**Criterio:** el `.dump` en tu máquina, y la prueba de que sobrevive a `kind delete cluster`.

### Ejercicio 5 — Las dos bases, en otro momento
Restaura solo `replenish` desde un respaldo de antes de unos préstamos, y mira qué pasa con esos préstamos.

**Criterio:** la lista de préstamos `COMPLETED` cuya orden ya no existe en `replenish`, y lo que el barrido de la
[Fase 24](24-la-saga-orquestada.md) hace (o no hace) con ellos.

### Ejercicio 6 — ¿Cuánto puede perder La Vecina?
En media página: con un respaldo por noche, ¿cuánto pierde La Vecina en el peor caso, y qué costaría bajarlo?

**Criterio:** el número en ventas y préstamos de un día (historia §7), y las dos alternativas de la tabla, con su costo.

---

> 🏷️ **Este apéndice no lleva tag propio.**
