# 📓 Formato del cuaderno de incidentes
## Laboratorio de contenedores y Kubernetes local

Este documento **no es** el cuaderno: es su especificación. Define cómo se construye
`cuaderno-incidentes.md`, el único archivo de incidentes del curso, qué IDs están reservados y por
qué fase, y cómo se escribe cada entrada.

> **Precedencia:** debajo del [alcance](alcance-del-proyecto.md), de la
> [guía](guia-de-estilo-y-convenciones.md) y del [contrato del cluster](contrato-del-cluster.md). Si
> el catálogo de §4 cambia, se cambia aquí primero y después en la propuesta de fases §7 y §11.
> **Fecha:** 30/09/2026. **Estado:** catálogo cerrado (D13, 30/09/2026).

> 🧭 **Un solo archivo, sin excepción.** El lector trabaja sin instructor y necesita índice,
> enunciado, pistas, solución y su propia bitácora a un scroll de distancia. **Los IDs son globales y
> nunca se reasignan**, aunque un incidente se retire.

---

## 1. 🎯 Qué hace distinto a este cuaderno

Tres cosas, y las tres vienen de que el curso es de plataforma y no de aplicación:

1. **Se consulta por síntoma, no por fase.** El índice abre con la columna de lo que el lector ve
   (`ImagePullBackOff`, un 404 del `Gateway`, `x509: certificate signed by unknown authority`), y
   desde ahí se llega al incidente sin haber leído la fase que lo reservó.
2. **El centro es el reflejo de los primeros treinta segundos.** Cada entrada dice qué mirar primero
   y qué comando descarta la mitad de las hipótesis. Sin eso, el cuaderno es una lista de errores.
3. **Cada incidente se puede provocar a voluntad**, en un laboratorio que no cuesta nada romper, y
   repetir hasta que el síntoma se reconozca sin pensar.

---

## 2. 📐 Estructura del archivo

`cuaderno-incidentes.md` se organiza en este orden, y solo en este:

1. **Encabezado** — título, la frase que fija el trato (*la solución viene incluida, y abrirla antes
   de tiempo solo te perjudica a ti*) y la fecha de verificación del último incidente agregado.
2. **🧭 Cómo se trabaja un incidente** — el método (§5), las tres formas de llegar al sistema roto
   (§6) y la convención de git (§7).
3. **🔎 Índice por síntoma** — una tabla que empieza por lo que el lector ve y apunta al ID.
4. **📋 Índice por ID** — la tabla de §3.
5. **🧪 Incidentes** — una entrada por incidente, con el bloque completo de §8. Se repite entero cada
   vez: nada de "ver incidente 07". Se leen salteados y con semanas de diferencia.
6. **🪞 Retrospectiva** — §9.

---

## 3. 📋 El índice y la reserva de IDs

La fila existe desde que la fase reserva el ID. **Una fase que reserva un ID escribe su entrada
completa en el cuaderno en la misma tanda**: no hay IDs reservados sin enunciado. La columna de
estado es del lector.

```markdown
| ID | Fase | Título | Familia | Dif. | Tiempo | Estado |
|---|---|---|---|---|---|---|
| 05 | 08 | El pod espera una imagen que el cluster nunca vio | ☸️ | 🟢 | 20 min | ⬜ |
```

**El título va en palabras de quien lo sufre**, no en el diagnóstico. *"El pod espera una imagen
que el cluster nunca vio"* es un buen título; *"`imagePullPolicy: Always` con una imagen cargada con
`kind load`"* es la respuesta, y va en la solución.

**Dificultad y tiempo:** 🟢 20–30 min · 🟡 30–45 min · 🟠 45–90 min · 🔴 hasta 2 h. El tiempo
sugerido existe para que el lector sepa cuándo está atascado de verdad y conviene abrir la primera
pista.

---

## 4. 🗂️ El catálogo: 27 incidentes

Los síntomas son **los esperados**; la fase que reserva el ID publica el literal que salió, y si
difiere, se corrige aquí.

### 🩺 Ambiente — Fase 00

| ID | Título | Síntoma esperado | Dif. |
|---|---|---|---|
| 01 | Instalé todo y WSL no arranca | `HCS_E_SERVICE_NOT_AVAILABLE` / `WSL_E_DISTRO_NOT_FOUND` | 🟢 |
| 02 | La máquina dice que no puede virtualizar | la virtualización figura deshabilitada; ninguna VM arranca | 🟢 |
| 03 | La máquina de Podman no levanta | `podman machine start` falla o la máquina no existe para WSL | 🟡 |
| 04 | El CLI no encuentra el motor que está corriendo | *cannot connect* / un esquema de socket no soportado | 🟡 |
| 27 | En el portátil de la empresa no baja ninguna imagen | `pinging container registry registry-1.docker.io: … tls: failed to verify certificate: x509: certificate signed by unknown authority` en el primer `pull`, por el proxy corporativo que inspecciona TLS (reproducido con Podman en P11; con Docker Desktop, no reproducido) | 🟡 |

### ☸️ Plataforma

| ID | Fase | Título | Síntoma esperado | Dif. |
|---|---|---|---|---|
| 05 | 08 | El pod espera una imagen que el cluster nunca vio | `ErrImagePull` → `ImagePullBackOff` | 🟢 |
| 06 | 08 | El `Service` existe y nadie le contesta | la conexión se rechaza; el `Service` no tiene endpoints | 🟢 |
| 07 | 09 | `inventory` no encuentra a `catalog`, que está ahí | error de resolución de nombre desde el pod | 🟡 |
| 08 | 10 | El navegador recibe 404 y ningún pod se entera | 404 del `Gateway`; la `HTTPRoute` sin aceptar | 🟡 |
| 09 | 11 | Cambié la configuración y el servicio sigue igual | el `ConfigMap` nuevo y el comportamiento viejo | 🟢 |
| 10 | 11 | El pod no llega ni a arrancar | `CreateContainerConfigError` por un `Secret` ausente | 🟢 |
| 11 | 12 | Postgres se queda esperando para siempre | pod en `Pending`; PVC sin enlazar | 🟡 |
| 12 | 15 | `inventory` muere sin decir nada | `OOMKilled`, código de salida 137, ningún log | 🟠 |
| 13 | 15 | El servicio corre y nunca recibe tráfico | pod `Running` con `0/1` listo | 🟡 |
| 14 | 15 | Kubernetes reinicia un pod que estaba bien | reinicios crecientes, `Liveness probe failed` bajo carga | 🟠 |
| 15 | 15 | La réplica nueva no encuentra dónde vivir | `Pending` con `Insufficient memory` | 🟡 |
| 16 | 16 | El despliegue se quedó a la mitad | rollout sin avanzar, `ProgressDeadlineExceeded` | 🟠 |
| 17 | 16 | El autoescalador no ve nada | el HPA muestra `<unknown>`; `kubectl top` → `error: Metrics API not available`; el log de metrics-server: `x509: cannot validate certificate for <IP del nodo> because it doesn't contain any IP SANs` | 🟡 |
| 25 | 20 | Endurecí el pod y dejó de arrancar | `CreateContainerConfigError`: *runAsNonRoot* y la imagen corre como root | 🟡 |
| 26 | 20 | Cerré la red y se rompió todo, hasta lo permitido | fallos de resolución de nombres tras un *default deny* | 🔴 |

### 🔐 Certificados — Fase 19

| ID | Título | Síntoma esperado | Dif. |
|---|---|---|---|
| 18 | Ayer funcionaba y hoy el navegador no entra | `certificate has expired` / `NET::ERR_CERT_DATE_INVALID` | 🟢 |
| 19 | El cliente no confía en quien firmó | `x509: certificate signed by unknown authority` | 🟡 |
| 20 | El certificado es válido, pero no para este nombre | *certificate is valid for X, not Y* | 🟡 |
| 21 | El `Gateway` rechaza su propio certificado | la clave privada no corresponde al certificado | 🟢 |
| 22 | cert-manager no emite nada | el `Certificate` nunca llega a `Ready` | 🟠 |
| 23 | `pricing` rechaza a `inventory` con mTLS | `tls: certificate required` | 🟠 |
| 24 | El cluster no puede traer imágenes del registry propio | `ErrImagePull` con `failed to do request: Head "https://lab-registry:5000/v2/…": tls: failed to verify certificate: x509: certificate signed by unknown authority`; se arregla en tres sitios distintos | 🔴 |

**Por qué los IDs 25 y 26 van después de los de certificados:** los IDs siguen el orden de las
fases que los reservan, y la Fase 19 va antes que la 20. **Y por qué el 27 es de la Fase 00:** se
sumó al catálogo después de numerado (D20), y los IDs no se reasignan. Su síntoma es el mismo que
el del 24; la causa y el arreglo no, y el cuaderno los enlaza en las dos direcciones.

---

## 5. 🧭 El método

Se enseña formalmente en la Fase 21, pero el cuaderno lo aplica desde el incidente 01. Siempre los
mismos siete pasos:

1. **Síntoma** — lo que se ve, literal.
2. **Evidencia** — qué mirar en los primeros treinta segundos, y en qué orden.
3. **Hipótesis** — dos o tres, ordenadas por probabilidad.
4. **Primer comando** — el que descarta más hipótesis de una vez.
5. **Causa** — la que confirmó la evidencia.
6. **Corrección** — el cambio mínimo.
7. **Prevención** — qué campo, qué sonda, qué verificación o qué hábito lo evita la próxima vez.

---

## 6. 🔁 Tres formas de llegar al sistema roto

1. **Desde el tag**, en el clon del repositorio del curso (el lector construye en su propio
   repositorio: `00-convencion-de-git-y-tags.md`): `git worktree add --detach ../inc-<ID>
   inc/<ID>/<slug>-roto`, o `git switch --detach` sobre el mismo tag, y desplegar como siempre. Es
   la forma canónica, y la única que garantiza el estado exacto.
2. **Con la tarea:** `task inc:break -- <ID>` aplica sobre el laboratorio actual el cambio mínimo que
   lo rompe, y `task inc:fix -- <ID>` lo revierte. Sirve cuando el lector ya avanzó y no quiere
   volver atrás en git.
3. **A mano:** la entrada describe el cambio en una o dos líneas, para quien quiera provocarlo sin
   herramientas. Es la que más enseña y la que más fácil sale mal.

Los incidentes de ambiente (01–04 y 27) no se provocan con las dos primeras: se describen y se
reconocen, porque romper la virtualización de la máquina del lector no es un ejercicio.

---

## 7. 🏷️ Git

- El par de tags `inc/<ID>/<slug>-roto` e `inc/<ID>/<slug>-fix`, con el ID reservado y nunca uno
  inventado. El `git diff` entre los dos **es** la corrección, aislada del ruido de la fase.
- El commit que abre el incidente: `fNN inc<ID>: <título>`.
- El slug es el del título, corto y en inglés: `inc/05/image-never-loaded-roto`.

---

## 8. 📄 El bloque de cada incidente

````markdown
### 🩺 Incidente {{ID}} — {{título en palabras de quien lo sufre}}

> **Fase:** {{NN}} · **Familia:** {{🩺 | ☸️ | 🔐}} · **Dificultad:** {{🟢🟡🟠🔴}} · **Tiempo sugerido:** {{min}}
> **Perfil:** {{minimo | lab}} · **Motor de referencia:** {{Docker}} {{· 🦭 si con Podman el síntoma cambia}}
> **Verificado el:** {{DD/MM/AAAA}} · {{plataformas}}

**El encargo.** {{Dos o tres líneas en la voz de alguien de la historia: qué ve, qué necesita, qué
consecuencia tiene si no se arregla.}}

**Cómo llegar.** `git switch --detach inc/{{ID}}/{{slug}}-roto` · o `task inc:break -- {{ID}}` · o, a
mano: {{el cambio en una línea}}.

**Lo que vas a ver.**

```text
{{la salida literal: el estado del pod, los eventos, el error del cliente}}
```

<details><summary>💡 Pista 1 — dónde mirar</summary>{{…}}</details>
<details><summary>💡 Pista 2 — qué comparar</summary>{{…}}</details>
<details><summary>💡 Pista 3 — casi la respuesta</summary>{{…}}</details>

<details><summary>✅ Solución</summary>

**Los primeros treinta segundos.** {{qué mirar y en qué orden}}
**Primer comando.** `{{…}}`, con la línea que importa de su salida.
**Causa.** {{…}}
**Corrección.** {{el cambio mínimo, con el diff}}
**Prevención.** {{campo, sonda, verificación o hábito}}
**En la nube** 🌩️ {{si el síntoma o la causa cambian en un cluster gestionado; si no, se omite}}

</details>

**📝 Tu bitácora.** Qué creíste que era · cuánto tardaste · qué te hizo verlo.
````

`<details>` es la excepción declarada al "nada de HTML" (guía §10): es la única forma de que la
solución no se lea sin querer.

---

## 9. 🪞 La retrospectiva

Al final del cuaderno, cinco preguntas para después de los 27: qué familia de síntomas reconoces
ya sin pensar, cuál te sigue costando, qué comando usaste más, qué incidente te pasó "de verdad" en
tu trabajo, y cuál de las siete prevenciones vas a adoptar el lunes.

---

## 10. 🗓️ Cuándo se escribe cada cosa

- **T0** crea el esqueleto: encabezado, método, las tres formas de llegar, git, los dos índices
  **vacíos** y la retrospectiva. Sin filas.
- **Cada tanda de fase** que reserva IDs agrega sus filas a los dos índices y sus entradas
  completas, con el literal que salió al ejecutar, y crea el par de tags y la entrada de
  `task inc:break`.
- **T9** (la Fase 21) revisa el cuaderno entero con el método ya enseñado: que cada entrada tenga sus
  treinta segundos, que el índice por síntoma esté completo y que ninguna solución se filtre en su
  fase.

---

## 11. 🧾 El prompt de la sesión de revisión del cuaderno

Va en la tanda T9, después de escribir la Fase 21. Las entradas se escriben en la tanda de su fase
con el prompt de esa fase; este prompt solo revisa y cierra.

```markdown
Esta es la sesión de **revisión del cuaderno de incidentes** del curso Laboratorio de contenedores
y Kubernetes local. Entregable: `cuaderno-incidentes.md` revisado, sin incidentes nuevos.

## Marco (no lo repitas, aplícalo)
Fuentes de verdad, en orden: `prompts/alcance-del-proyecto.md`,
`prompts/guia-de-estilo-y-convenciones.md`, `prompts/contrato-del-cluster.md`,
`prompts/formato-cuaderno-incidentes.md` (este formato) y `21-diagnostico.md`, ya escrita. Los
`_desechable-*` no cuentan y no se citan. No toques ningún `README.md` ni crees
`0-ESTRUCTURA-CURSO.md`.

## Qué revisar
- Los 27 IDs del catálogo §4 están en los dos índices y tienen su entrada completa, o la falta se
  declara con la tanda que la debe.
- Cada entrada tiene sus **treinta segundos** y su **primer comando** con la línea de salida que
  importa. Una entrada sin eso se reescribe.
- **Ninguna solución vive en su fase**: la fase muestra el síntoma y enlaza. **Excepción declarada
  (D40, confirmada por Oskar el 05/10/2026):** las autopsias de la F19 («el certificado puesto a mano»)
  y de la F20 («cerrar la red sin abrir el DNS») cuentan la causa de los incidentes 18 y 26, porque la
  autopsia necesita sus números y esos números salen de reproducir esos incidentes. Para quien leyó la
  fase, esos dos incidentes son práctica de reconocer el síntoma desde afuera, no de adivinar la causa.
  No se abre ninguna otra excepción sin una decisión nueva.
- El índice por síntoma empieza por lo que el lector ve, con el literal que salió.
- Los tags `inc/<ID>/…` y las tareas `inc:break` existen para cada incidente de plataforma y de
  certificados, y el `git diff` entre `-roto` y `-fix` es solo la corrección.
- El método de la Fase 21 y el de §5 dicen lo mismo con las mismas palabras.

## Cómo quiero que trabajes
**Paso 1** — Devuélveme la lista de lo que falta o está mal, por ID, sin corregir nada.
**Paso 2** — Cuando yo responda, corrige ejecutando otra vez cada incidente que toques.
**Paso 3** — Autoverificación contra la guía §16, en lista corta.
```

---

## 12. 📌 Pendientes de este documento

- ✅ **D13** y **D20** cerradas: 27 incidentes, con el 24 del registry y el 27 del proxy corporativo.
- ✅ La verificación de laboratorio (P11, 03/10/2026) fijó las piezas: Envoy Gateway 1.9, metrics-server
  0.9, el registry con CA propia y kindnet, que sí aplica `NetworkPolicy`. Ya salieron literales los
  síntomas de **17, 24 y 27**. Los de **08** (la `HTTPRoute` sin aceptar) y **26** (el *default
  deny* que corta el DNS) siguen como esperados hasta que sus fases los provoquen, como cualquier
  otro incidente del catálogo.
- ✅ **Las voces de los encargos** ya existen (historia §9): Yolanda para el mostrador, Wilson para
  los domicilios, Luz Marina para arquitectura, Valentina para plataforma, y la mesa de ayuda para
  el 27.
