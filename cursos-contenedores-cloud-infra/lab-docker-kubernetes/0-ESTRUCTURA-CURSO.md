# 🗺️ Estructura del curso
## Laboratorio de contenedores y Kubernetes local

Este documento es **la fuente de verdad de la estructura**: las cinco partes y por qué van en ese orden, las veintiocho
fases con lo que cada una deja, los pasos de generación que hacen crecer el sistema, los dieciséis apéndices, el
cuaderno y las mediciones. Si el material y este documento se contradicen, gana este documento y la fase se corrige.

> 📝 **Estado real:** todo lo que aparece aquí está escrito y fue ejecutado, entre el 03 y el 05/10/2026, en macOS arm64
> con Docker Desktop (y con Podman donde la fase compara los dos motores). Windows 11 y Linux están escritos desde la
> documentación oficial y marcados *"no verificado por el autor"* donde aplica.

---

## 🧱 1. Las cinco partes, y por qué en este orden

**Parte 0 · Prolegómenos** *(00–02)*. Primero funciona, después se entiende: el ambiente con los dos motores, el primer
contenedor con la Braqui tal como vino, y el sistema entero —los cinco servicios del paso G0 y el patrimonio— en un
archivo de compose. Antes de explicar qué es un contenedor, el lector ya corrió varios.

**Parte I · El modelo y el salto** *(03–06)*. Qué pasa debajo: un contenedor es un proceso con la vista recortada,
empaquetar cada runtime tiene su factura (B-04), los dos motores divergen en sitios concretos (B-05), y compose deja de
alcanzar en el momento exacto en que el sistema necesita un bucle que lo mantenga vivo.

**Parte II · El despliegue** *(07–16)*. Lo que la plataforma te regala, en YAML escrito a mano antes que con Helm: el
cluster, el primer despliegue campo por campo, la entrada compartida, la configuración, el estado, el paquete, la salud
y el escalado. Termina con la venta completa (G5) bajo carga y la pregunta de cuántas réplicas pide cada runtime
(B-16).

**Parte III · Operarlo** *(17–21)*. Lo que hace falta para vivir con el sistema: métricas, logs, la cadena de
confianza de TLS de punta a punta, la seguridad del pod y de la red, y el método de diagnóstico que abre formalmente
el cuaderno.

**Parte IV · El lab de patrones** *(22–26)*. Lo que la plataforma **no** te va a dar nunca: timeouts con criterio, el
balanceo de conexiones largas (B-23), la saga del préstamo entre droguerías, la coreografía con eventos y lo que se
pierde, y la idempotencia con outbox.

**Cierre** *(27)*. El veredicto honesto, con un número por rama: cuándo no hacía falta nada de esto. Y el proyecto
final: un servicio nuevo que la plataforma reconoce como uno más.

> 🧭 **Dos reglas de secuencia que ninguna fase se salta.** *Primero funciona, después se entiende.* Y *YAML plano antes
> que Helm, siempre*: el lector escribe los campos a mano antes de que nada se los genere.

---

## 🌊 2. Cómo crece el sistema: las oleadas y los pasos G

El sistema no se construye servicio por servicio, sino en **oleadas horizontales** que tocan los cuatro backends a la vez
con una capa fina. Dentro de cada oleada, **`pricing` va primero** (el piloto) y los otros tres lo siguen; lo
interesante son las veces en que seguirlo no es mecánico. Cada paso tiene su prompt de generación y su suite de
conformidad en [a03](a03-contratos-y-prompts-de-generacion.md).

| Paso | Fase | Qué agrega |
|---|---|---|
| **G0 · Esqueleto** 🌊 | [02](02-compose-el-sistema-en-un-archivo.md) | salud trivial y un endpoint con JSON fijo, en los cinco |
| **G1 · Almacén propio** 🌊 | [09](09-los-cuatro-servicios-dentro.md) | SQLite dentro del pod, lectura y escritura, sin cruzarse |
| **G2 · Configuración en arranque** | [11](11-configuracion-y-secretos.md) | el `storefront` lee su configuración al arrancar |
| **G3 · Postgres** | [12](12-estado-y-almacenamiento.md) | una base por servicio, `DATABASE_URL`, migraciones como `Job` |
| **G4 · Readiness real** | [15](15-salud-y-recursos.md) | la readiness comprueba lo que el servicio necesita |
| **G5 · El flujo de venta** 🌊 | [16](16-escalado-y-rollout.md) | la venta completa y el apagado limpio |
| **G6 · Métricas** | [17](17-metricas-y-dashboards.md) | `/metrics` con las métricas RED |
| **G7 · Logs estructurados** | [18](18-logs.md) | una línea JSON por evento |
| **G8 · Cliente mTLS** | [19](19-tls-y-certificados.md) | `inventory` presenta certificado a `pricing` |
| **G9 · Resiliencia** | [22](22-resiliencia-y-caos.md) | timeouts, reintentos y circuit breaker en `inventory` |
| **G10 · gRPC y trazas** | [23](23-grpc-y-el-balanceo.md) | `pricing` sirve gRPC; los cuatro propagan contexto |
| **G11 · Saga orquestada** | [24](24-la-saga-orquestada.md) | el préstamo como saga, con compensaciones de negocio |
| **G12 · Coreografía** | [25](25-la-coreografia.md) | el aviso de la venta como evento, por Valkey o por NATS |
| **G13 · Idempotencia y outbox** | [26](26-idempotencia-y-outbox.md) | claves de idempotencia, consumidor idempotente y outbox |

Entre la Fase 02 y la 16 el sistema devuelve datos poco interesantes, y es a propósito: lo que se aprende ahí es la
plataforma, no el dominio.

---

## 🪜 3. Las veintiocho fases

⭐ marca las fases de las que depende la tesis del curso. Cada fase depende de la anterior y deja el laboratorio como la
siguiente lo espera; el tag `fase-NN-<slug>` marca ese estado (la [convención de git](00-convencion-de-git-y-tags.md)).
*Ej.* son los ejercicios; *Inc.*, los incidentes del cuaderno que la fase reserva; 📏, su medición.

### Parte 0 · Prolegómenos

| # | Fase | Peso | Ej. | Paso | Inc. | 📏 |
|---|---|---|---|---|---|---|
| 00 | [🛠️ El ambiente: dos motores y tres plataformas](00-el-ambiente.md) | media | 20 | — | 01–04, 27 | |
| 01 | [📦 Tu primer contenedor, y tu primer Dockerfile](01-primer-contenedor-y-dockerfile.md) | media | 20 | — | | |
| 02 | [🧩 Compose: el patrimonio y el sistema nuevo, en un archivo](02-compose-el-sistema-en-un-archivo.md) | media | 20 | G0 | | |

### Parte I · El modelo y el salto

| # | Fase | Peso | Ej. | Paso | Inc. | 📏 |
|---|---|---|---|---|---|---|
| 03 | [🔬 El contenedor por dentro](03-el-contenedor-por-dentro.md) | media | 20 | — | | |
| 04 ⭐ | [🏗️ Empaquetar los cuatro runtimes: un patrón, cuatro facturas](04-empaquetar-los-cuatro-runtimes.md) | densa | 24 | — | | B-04 |
| 05 | [🦭 Los dos motores, sin guerra](05-los-dos-motores.md) | ligera | 12 | — | | B-05 |
| 06 | [🪜 Del compose al cluster: el bucle que reemplaza al instinto](06-del-compose-al-cluster.md) | densa | 24 | — | | |

### Parte II · El despliegue

| # | Fase | Peso | Ej. | Paso | Inc. | 📏 |
|---|---|---|---|---|---|---|
| 07 | [☸️ El cluster local: dos clusters de kind](07-el-cluster-local.md) | media | 20 | — | | B-07 |
| 08 ⭐ | [🚀 El primer despliegue, en YAML plano](08-el-primer-despliegue.md) | densa | 24 | — | 05, 06 | |
| 09 | [🧱 Los cuatro servicios dentro](09-los-cuatro-servicios-dentro.md) | media | 20 | G1 | 07 | |
| 10 | [🌐 La entrada al sistema, y el Siga perdiendo tráfico](10-la-entrada-al-sistema.md) | media | 20 | — | 08 | |
| 11 ⭐ | [⚙️ Configuración y secretos](11-configuracion-y-secretos.md) | media | 20 | G2 | 09, 10 | |
| 12 | [💾 Estado, almacenamiento y datos iniciales](12-estado-y-almacenamiento.md) | densa | 24 | G3 | 11 | B-12 |
| 13 | [📦 Helm: el paquete](13-helm-el-paquete.md) | densa | 24 | — | | |
| 14 | [🔧 Helm en operación: la red de seguridad y la segunda cadena](14-helm-en-operacion.md) | media | 20 | — | | |
| 15 ⭐ | [🩺 Salud y recursos](15-salud-y-recursos.md) | densa | 24 | G4 | 12–15 | |
| 16 | [📈 Escalado y rollout: la venta completa y la quincena](16-escalado-y-rollout.md) | densa | 24 | G5 | 16, 17 | B-16 |

### Parte III · Operarlo

| # | Fase | Peso | Ej. | Paso | Inc. | 📏 |
|---|---|---|---|---|---|---|
| 17 | [📊 Métricas y tableros](17-metricas-y-dashboards.md) | densa | 24 | G6 | | |
| 18 | [🔎 Logs: qué pasó con esa venta](18-logs.md) | media | 20 | G7 | | |
| 19 ⭐ | [🔐 TLS y certificados: la cadena de confianza](19-tls-y-certificados.md) | densa | 24 | G8 | 18–24 | |
| 20 | [🛡️ Seguridad del pod y de la red](20-seguridad-del-pod-y-de-la-red.md) | media | 20 | — | 25, 26 | |
| 21 | [🩻 Diagnóstico: el kit, el método y los primeros treinta segundos](21-diagnostico.md) | densa | 24 | — | abre el cuaderno | |

### Parte IV · El lab de patrones

| # | Fase | Peso | Ej. | Paso | Inc. | 📏 |
|---|---|---|---|---|---|---|
| 22 | [🔥 Resiliencia y caos: el vecino lento](22-resiliencia-y-caos.md) | media | 20 | G9 | | |
| 23 ⭐ | [🔌 gRPC, y el balanceo que no balancea](23-grpc-y-el-balanceo.md) | densa | 24 | G10 | | B-23 |
| 24 | [🎬 La saga orquestada: el préstamo sale de la base](24-la-saga-orquestada.md) | densa | 24 | G11 | | |
| 25 | [📡 La coreografía, y los mensajes que se pierden](25-la-coreografia.md) | densa | 24 | G12 | | |
| 26 ⭐ | [🔁 Idempotencia y outbox: dos motos, un inhalador](26-idempotencia-y-outbox.md) | densa | 24 | G13 | | |

### Cierre

| # | Fase | Peso | Ej. | Paso | Inc. | 📏 |
|---|---|---|---|---|---|---|
| 27 | [⚖️ El veredicto honesto, y el proyecto final](27-el-veredicto-y-el-proyecto-final.md) | densa | 12 | — | | |

**En total:** quince fases densas, doce medias y una ligera; **600 ejercicios**, graduados 🟢🟡🟠🔴 y cada uno con su
criterio verificable. La Parte IV no reserva incidentes: sus fallos son de diseño y se miden en sus fases.

---

## 📎 4. Los apéndices

No se leen de corrido: se entra por el índice buscando algo concreto. Los de **laboratorio y consulta** se usan durante
el curso y crecieron con él; los 🔥 son **ampliaciones** que ninguna fase espera, cada una ejecutada en el laboratorio y
con lo que suma de memoria.

| Apéndice | Tipo | Ej. | Lo usan |
|---|---|---|---|
| [a01 · El laboratorio](a01-el-laboratorio.md) | laboratorio | 8 | todas: las versiones, el Taskfile, los perfiles y la memoria |
| [a02 · Problemas del ambiente](a02-problemas-del-ambiente.md) | consulta | 8 | Fase 00 y cada vez que el ambiente falla |
| [a03 · Contratos y prompts de generación](a03-contratos-y-prompts-de-generacion.md) | laboratorio | 8 | cada fase que estrena un paso G |
| [a04 · `kubectl` y k9s](a04-kubectl-y-k9s.md) | consulta | 10 | la Parte II y la Fase 21 |
| [a05 · Los diccionarios](a05-diccionarios.md) | consulta | 6 | las fases con 📖 o 🌩️ |
| [a06 · Arquitecturas y multiplataforma](a06-arquitecturas-y-multiplataforma.md) | 🔥 | 6 | Fases 04 y 05 |
| [a07 · Imágenes sin Docker](a07-imagenes-sin-docker.md) | 🔥 | 6 | Fase 04 |
| [a08 · La JVM nativa](a08-la-jvm-nativa.md) | 🔥 | 6 | Fases 04 y 15 |
| [a09 · El frontend con runtime](a09-frontend-con-runtime.md) | 🔥 | 5 | Fases 04 y 11 |
| [a10 · Service mesh](a10-service-mesh.md) | 🔥 | 6 | Fases 19, 22 y 23 |
| [a11 · GitOps, de lectura](a11-gitops-de-lectura.md) | 🔥 | 5 | Fases 13 y 14 |
| [a12 · Operators, de lectura](a12-operators-de-lectura.md) | 🔥 | 5 | Fases 10 y 19 |
| [a13 · Respaldo y restauración](a13-respaldo-y-restauracion.md) | 🔥 | 6 | Fase 12 |
| [a14 · Las GUI](a14-las-gui.md) | 🔥 | 5 | Fase 07 y a04 |
| [a15 · Un `StatefulSet` de varios miembros](a15-statefulset-de-varios-miembros.md) | 🔥 | 6 | Fases 12, 25 y 26 |
| [a16 · El patrimonio](a16-el-patrimonio.md) | laboratorio | 6 | Fases 00 a 02, 10 a 12, 15, 22 y 24 a 26 |

**102 ejercicios** en los apéndices. Ninguno lleva tag propio salvo [a03](a03-contratos-y-prompts-de-generacion.md),
que deja los contratos en el repositorio.

---

## 📓 5. Los documentos que acompañan

| Documento | Qué es |
|---|---|
| [La historia de La Vecina](00-historia-de-la-vecina.md) | la empresa, su gente y su encargo; de aquí sale todo lo narrativo |
| [La convención de git y tags](00-convencion-de-git-y-tags.md) | los dos repositorios, los commits, los tags de fase y los pares de cada incidente |
| [El cuaderno de incidentes](cuaderno-incidentes.md) | los 27 incidentes, con índice por síntoma y por ID |
| [`BENCHMARKS.md`](BENCHMARKS.md) | las mediciones, con hipótesis, condiciones, resultado, apuesta y veredicto |
| [`INSTINTOS.md`](INSTINTOS.md) | los reflejos que el curso corrige, uno por entrada |

---

## 📏 6. Las mediciones

| Medición | Fase | La pregunta |
|---|---|---|
| B-00 | [a01](a01-el-laboratorio.md) | ¿cuánta memoria ocupa cada perfil, con cada motor? |
| B-04 | [04](04-empaquetar-los-cuatro-runtimes.md) | ¿cuánto cuesta empaquetar cada runtime? |
| B-05 | [05](05-los-dos-motores.md) | ¿qué cambia entre los dos motores? |
| B-07 | [07](07-el-cluster-local.md) | ¿cuánto cuesta cada cluster local? |
| B-12 | [12](12-estado-y-almacenamiento.md) | ¿qué se gana y qué se pierde probando contra SQLite en lugar del motor real? |
| B-16 | [16](16-escalado-y-rollout.md) | ¿cuántas réplicas pide cada runtime para la misma tasa, y cuánto cuesta cada una? |
| B-23 | [23](23-grpc-y-el-balanceo.md) | ¿cómo se reparte el tráfico gRPC entre réplicas, antes y después del arreglo? |

Las demás cifras de cada fase (las apuestas, las roturas, los experimentos de la Parte IV) se miden en su sección y
llevan sus condiciones al lado; no tienen identificador porque no se repiten fuera de la fase.

---

## 🏁 7. El proyecto final

Agregar **un servicio nuevo** al sistema, de cero y sin tocar el código de los otros cuatro, y que la plataforma lo
reconozca como a uno más: contrato, imagen, subchart, sondas y límites medidos, métricas y logs, un papel en la saga o
en la coreografía, y su suite. Siete criterios de aceptación, todos comandos, y uno de salida. El enunciado está en la
[Fase 27](27-el-veredicto-y-el-proyecto-final.md#️-6-el-proyecto-final), y se hizo una vez de punta a punta antes de
publicarlo.
