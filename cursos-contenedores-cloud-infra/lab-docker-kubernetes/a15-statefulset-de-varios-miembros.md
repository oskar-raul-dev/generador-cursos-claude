# 📎 Apéndice a15 — Un `StatefulSet` de varios miembros: arranque ordenado y failover

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 12](12-estado-y-almacenamiento.md) (el Postgres de un solo miembro), [Fase 25](25-la-coreografia.md) (el bus), [Fase 26](26-idempotencia-y-outbox.md) (la deduplicación) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** 29 MiB los tres miembros en reposo (11 + 9 + 9), contra 15 MiB del NATS de un miembro; tres PVC de 1 GiB
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop, cluster `lab`

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. El Postgres de la
[Fase 12](12-estado-y-almacenamiento.md) es un `StatefulSet` de una réplica, y una réplica no muestra lo que el
`StatefulSet` existe para dar: **miembros con nombre propio que se encuentran, eligen un líder y sobreviven a perder
uno**. Este apéndice lo muestra con el bus de la [Fase 25](25-la-coreografia.md), NATS con JetStream, en tres miembros:
ya está en el stack, pesa poco y elige líder por quórum.

**Qué queda fuera:** Postgres replicado (con un operator, [a12](a12-operators-de-lectura.md)); MongoDB, que se nombra
como alternativa; mover los servicios del curso al NATS de tres miembros, que queda de ejercicio.

---

## Índice

- [Tres miembros, tres nombres](#tres-miembros-tres-nombres)
- [El arranque ordenado que se traba solo](#el-arranque-ordenado-que-se-traba-solo)
- [Un stream en tres copias](#un-stream-en-tres-copias)
- [Matar al líder](#matar-al-líder)
- [Perder el quórum](#perder-el-quórum)
- [La deduplicación sobrevive al líder](#la-deduplicación-sobrevive-al-líder)
- [Lo que cuesta](#lo-que-cuesta)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-6)

---

## Tres miembros, tres nombres

El manifiesto está en `src/lab/platform/data/nats-ha/nats-ha.yaml`, convive con el `nats` de un miembro del camino base y
ninguna tarea lo aplica:

```bash
kubectl apply -f platform/data/nats-ha/
```

Lo que un `StatefulSet` da y un `Deployment` no:

- **Un nombre estable por miembro**: `nats-ha-0`, `nats-ha-1`, `nats-ha-2`. Si `nats-ha-1` muere, vuelve `nats-ha-1`, no
  un pod con un sufijo nuevo.
- **Un DNS por miembro**, a través de un `Service` *headless* (sin IP propia):
  `nats-ha-2.nats-ha-headless.data.svc.cluster.local`. Cada miembro encuentra a los otros por ese nombre:

  ```text
  cluster {
    name: lab-ha
    port: 6222
    routes: [
      nats://nats-ha-0.nats-ha-headless.data.svc.cluster.local:6222
      nats://nats-ha-1.nats-ha-headless.data.svc.cluster.local:6222
      nats://nats-ha-2.nats-ha-headless.data.svc.cluster.local:6222
    ]
  }
  ```

- **Un disco por miembro** (`data-nats-ha-0`, `-1`, `-2`), que vuelve con el mismo nombre.

## El arranque ordenado que se traba solo

El `StatefulSet` arranca, por defecto, **en orden**: `nats-ha-1` no se crea hasta que `nats-ha-0` está listo
(`podManagementPolicy: OrderedReady`). Es lo que quieres para un primario y sus réplicas. Para un cluster por quórum, con
la readiness en `/healthz`:

```text
+10 s:  nats-ha-0 0/1 Running
+180 s: nats-ha-0 0/1 Running          (y nada más: nats-ha-1 nunca se creó)
[WRN] Waiting for routing to be established...
[WRN] Healthcheck failed: "JetStream is still recovering meta layer"
```

`nats-ha-0` no está listo porque JetStream necesita quórum, dos de tres. El quórum necesita a `nats-ha-1`. Y `nats-ha-1`
espera a que `nats-ha-0` esté listo. **Se traba solo**, sin un error que lo diga. Dos cambios lo destraban:

```yaml
spec:
  podManagementPolicy: Parallel          # los tres a la vez
---
# en el Service headless:
spec:
  clusterIP: None
  publishNotReadyAddresses: true         # los miembros se encuentran antes de estar listos
```

```text
tres listos en 15 s
nats-ha-0   lab-worker2   08:46:43Z
nats-ha-1   lab-worker2   08:46:44Z
nats-ha-2   lab-worker    08:46:43Z
meta-líder: nats-ha-1 · miembros: 3
```

> ⚠️ **Dos miembros en el mismo nodo.** El cluster del curso tiene dos workers, y el control-plane no recibe pods. La
> regla de un miembro por nodo (`topologySpreadConstraints`) está en `ScheduleAnyway`; con `DoNotSchedule`, el tercero no
> arrancaría. Perder `lab-worker2` es perder dos miembros a la vez, y el quórum (abajo).

## Un stream en tres copias

Con `nats-box` (la imagen con la CLI `nats`, en [a01](a01-el-laboratorio.md)) dentro de `data`:

```text
$ nats stream add A15 --subjects 'a15.>' --replicas 3 --storage file --defaults
Leader: nats-ha-2
Replica: nats-ha-0, current
Replica: nats-ha-1, current
```

Cada stream tiene **su** líder, que recibe las escrituras y las confirma cuando dos de las tres copias las tienen. El
cliente no elige: publica en cualquier miembro y el cluster lo lleva al líder.

## Matar al líder

Un publicador manda una venta cada ~0,1 s con `nats pub -J` (espera la confirmación del stream) y un `Nats-Msg-Id`
propio, durante 47 s. A los 10 s se mata al líder, de dos maneras:

| Cómo cae el líder | Publicaciones fallidas | Hueco | Confirmadas perdidas |
|---|---|---|---|
| `kubectl delete pod` (se despide: avisa y entrega el liderazgo) | 1 de 400 (`no responders`) | 0,11 s | 0 |
| `kill -9` al proceso, desde el nodo ([a04](a04-kubectl-y-k9s.md)) | 47 de 400 | 5,4 s | 0 |

Con `kill -9`, los logs ponen la elección en su sitio:

```text
08:51:08.57  nats-ha-2 terminado (Error); el kubelet lo arranca otra vez en el mismo segundo
08:51:14.18  nats-ha-0: JetStream cluster new stream leader for '$G > A15'
```

**5,6 s de elección**, y en ese tiempo el stream no acepta escrituras: las 47 fallan con `no servers available` o
`no responders`. Y lo que importa: **ninguna confirmada se perdió, y ninguna fallida quedó guardada**. Lo que el stream
confirma está en dos copias antes de contestar. Una caída limpia (un rollout, un `drain`) casi no se nota; una caída
dura cuesta unos segundos de escrituras que el cliente tiene que reintentar, y el `Nats-Msg-Id` hace que reintentar no
duplique.

> 📝 Que `nats-ha-2` volviera en el mismo segundo no lo hace líder otra vez: vuelve con su disco, se pone al día y queda
> de réplica. El liderazgo no "vuelve a casa".

## Perder el quórum

Dos de tres, abajo: `kubectl scale statefulset nats-ha --replicas=1` durante 25 s, publicando:

```text
+25 s, con un solo miembro:
nats: error: setup failed: nats: no servers available for connection
nats-ha-0 /healthz: HTTP/1.1 503 Service Unavailable
confirmadas: 470 · fallidas: 30 (de +12,0 a +40,8 s)
de vuelta a los ~6 s del scale a 3 · confirmadas perdidas: 0
```

Lo esperado era que el stream no aceptara escrituras. Lo que pasó fue peor, y vale la pena entenderlo: el miembro solo da
503 en `/healthz`, **la readiness lo saca del `Service`**, y el `Service` queda sin destinos. Los clientes no fallan al
escribir: **no conectan**. Ni escrituras ni lecturas. Es la misma regla de la [Fase 15](15-salud-y-recursos.md) —la
readiness decide el tráfico— con una consecuencia que en un servicio sin estado no se ve: la readiness de un miembro
depende de sus vecinos. Al volver los otros dos, todo lo confirmado estaba.

## La deduplicación sobrevive al líder

La [Fase 26](26-idempotencia-y-outbox.md) confía en el `Nats-Msg-Id` para que el relay del outbox pueda reintentar. ¿Y si
el líder que recordaba el identificador se muere?

```text
con nats-ha-0 de líder:   Stored in Stream: A15 Sequence: 1
kill -9 a nats-ha-0 (08:56:31) · líder nuevo: nats-ha-1 (08:56:40)
la misma venta, otra vez: Stored in Stream: A15 Sequence: 1 Duplicate: true
mensajes en el stream: 1
```

La ventana de duplicados (120 s) es **estado del stream**, replicado como los mensajes, no memoria del líder. El outbox de
la [Fase 26](26-idempotencia-y-outbox.md) aguanta la caída de un miembro igual que la de su propio proceso.

## Lo que cuesta

- **Memoria:** 29 MiB los tres en reposo, contra 15 MiB de uno. El doble, no el triple: es lo barato de NATS.
- **Disco:** tres copias de cada mensaje de un stream R3.
- **La configuración del cliente:** el código del curso asegura `LAB_EVENTS` sin `Replicas`, que vale 1. En el NATS de tres
  miembros, ese stream viviría en **uno solo**: el cluster sobrevive, el stream no. Un stream R3 se pide explícitamente.
  (No se midió con los servicios del curso: es el ejercicio 5.)
- **Nodos:** tres miembros piden tres nodos para que un nodo caído no se lleve el quórum. El cluster del curso tiene dos.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| el laboratorio, el bus de la Parte IV | NATS de un miembro, como el curso | 15 MiB; si se cae, el `StatefulSet` lo repone con su disco y lo confirmado sigue |
| no perder escrituras confirmadas si cae un nodo | tres miembros, stream R3, en tres nodos | 0 confirmadas perdidas; 5,6 s sin escrituras en la caída dura |
| un rollout sin hueco | tres miembros y caídas limpias | 1 publicación fallida en 400 |
| un `StatefulSet` por quórum | `podManagementPolicy: Parallel` y `publishNotReadyAddresses` | con `OrderedReady`, el arranque se traba solo |
| un Postgres replicado | un operator ([a12](a12-operators-de-lectura.md)) | el failover de una base relacional es más que elegir líder: es promover una réplica y mover a los clientes |

## ⚠️ Advertencias

- Una corrida por tipo de caída y una de quórum; los segundos son de este cluster sin carga.
- Las dos primeras corridas del failover se descartaron: el publicador terminó sus 400 mensajes en 5,9 s, antes del corte
  a los 10 s. Las de la tabla publican durante 47 s.
- Dos miembros en el mismo nodo: el failover medido es el de un proceso, no el de un nodo.

## 📚 Referencias

- Kubernetes, *StatefulSets* (identidad, orden y `podManagementPolicy`): https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- NATS, *JetStream Clustering*: https://docs.nats.io/running-a-nats-service/configuration/clustering/jetstream_clustering
- NATS, *Running in Kubernetes* (su chart usa `Parallel`): https://docs.nats.io/running-a-nats-service/nats-kubernetes
- NATS, *Message Deduplication*: https://docs.nats.io/learn/jetstream/publishing
- Raft, *In Search of an Understandable Consensus Algorithm*: https://raft.github.io/raft.pdf

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (6)

### Ejercicio 1 — Los tres nombres
Aplica el manifiesto y comprueba la identidad estable: borra `nats-ha-1` y mira con qué nombre, qué disco y qué DNS vuelve.

**Criterio:** el mismo nombre, el mismo PVC (`data-nats-ha-1`) y la misma entrada de DNS, con su IP nueva.

### Ejercicio 2 — El arranque que se traba
Cambia a `OrderedReady`, aplica en limpio (borrando el `StatefulSet` y los PVC primero) y espera tres minutos.

**Criterio:** `nats-ha-0` en 0/1, sin `nats-ha-1`, y la línea del log que lo explica.

### Ejercicio 3 — El líder, cronometrado
Repite el `kill -9` al líder tres veces con un publicador que dure más que la prueba.

**Criterio:** los tres tiempos de elección por los logs, las fallidas y **0 confirmadas perdidas** en las tres.

### Ejercicio 4 — R1 en un cluster de tres
Crea un stream con `--replicas 1`, encuentra en qué miembro vive y mata ese miembro.

**Criterio:** el stream sin escrituras mientras el miembro está caído, aunque el cluster tenga quórum, y la frase que
explica la diferencia con R3.

### Ejercicio 5 — El bus del curso, en tres miembros
Haz que `inventory` y `replenish` usen `nats-ha` (la URL está fija en el chart y en el relay: vuélvela un valor) y que
`LAB_EVENTS` se cree con tres réplicas.

**Criterio:** `nats stream info LAB_EVENTS` con tres réplicas, una venta que crea su orden con el líder de `LAB_EVENTS`
caído, y la conformidad de G13 en verde.

### Ejercicio 6 — ¿Tres miembros para La Vecina?
En media página: ¿el bus de Paracelso necesita tres miembros?

**Criterio:** la respuesta con los números de este apéndice (5,6 s, 29 MiB, el quórum perdido) y el outbox de la
[Fase 26](26-idempotencia-y-outbox.md), que ya guarda lo que el bus no recibió.

---

> 🏷️ **Este apéndice no lleva tag propio.**
