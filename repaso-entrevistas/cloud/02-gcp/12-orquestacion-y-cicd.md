# 12 — Orquestación y CI/CD

> **Objetivo:** distinguir orquestación de entrega, y saber qué hace cada uno de los tres
> productos que la gente mete en la misma frase: Workflows, Cloud Build y Cloud Deploy.
> **Se asume leído:** [`02` — cómputo, contenedores y balanceo](02-computo-contenedores-y-balanceo.md).
> **Se toca sobre todo con:** [`07` — Pub/Sub, Eventarc e integración](07-pubsub-eventarc-integracion.md) y
> [`09` — Terraform e IaC](09-terraform-iac.md).
> **Dónde se practica:** como drill opcional —ver
> [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales)—, porque cabe en la cuota de 2.500
> build-minutes al mes. El reparto de tráfico entre revisiones sí se practica en
> [`L05` §9](l05-cloud-run-contrato-revisiones-y-trafico.md#9--revisiones-y-reparto-de-tráfico).
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Panorama

```text
Workflows     → orquestación explícita de pasos/llamadas
Cloud Build   → construir/probar artefactos
Cloud Deploy  → promover un artefacto a través de ambientes
```

```text
Workflows vs Eventarc + Cloud Run (orquestación explícita vs event-driven)
Cloud Build vs Cloud Deploy (construir/probar vs promover a ambientes)
```

---

# Parte I — Workflows

## 2. 🧱 Workflow y Steps

Un **Workflow** define una secuencia de **steps** que llaman a APIs de
GCP y a HTTP endpoints externos, con manejo de errores y retries
declarado dentro del propio workflow.

```text
Step 1: validar payload
Step 2: llamar API de pagos
   │ ¿falla?
   ├── sí → retry con backoff → si sigue fallando, ir a Step de compensación
   └── no → Step 3: publicar evento en Pub/Sub
```

## 3. ⚖ Cuándo usar Workflows en lugar de Eventarc + Cloud Run

Cuando **conoces de antemano la secuencia de pasos** y quieres
orquestarla explícitamente en un solo lugar — en contraste con un diseño
donde varios servicios desacoplados reaccionan a eventos sin que ninguno
conozca el flujo completo (Eventarc + Cloud Run, ver documento [`07`](07-pubsub-eventarc-integracion.md)).

```text
Workflow gigante con toda la lógica de orquestación adentro
```

es la señal de que probablemente convenía modelar el flujo como un
Workflow explícito en lugar de encadenar `try/catch` manuales dentro de
un único servicio.

---

# Parte II — Cloud Build

## 4. 🧱 Build triggers y build steps

Un **build trigger** dispara una ejecución de Cloud Build ante un evento
(push a una rama, tag, pull request). Cada ejecución corre una secuencia
de **build steps** (compilar, testear, construir la imagen de
contenedor).

## 5. 🧱 Integración con Artifact Registry y repositorios

```text
Push a repositorio (Cloud Source Repositories, GitHub, GitLab)
        │
        ▼
   Build trigger
        │
        ▼
   Cloud Build (build steps)
        │
        ▼
   Artifact Registry (imagen publicada)
```

Cloud Build se integra de forma nativa con Cloud Source Repositories, y
también con repositorios externos como GitHub y GitLab mediante
conectores.

---

# Parte III — Cloud Deploy

## 6. 🧱 Delivery pipelines y targets

Un **delivery pipeline** de Cloud Deploy define la secuencia de
**targets** (ej. `dev` → `staging` → `prod`) por los que un artefacto
avanza, con aprobaciones y validaciones entre etapas.

## 7. 🧱 Estrategias de despliegue

A nivel conceptual:

| Estrategia | Descripción |
|---|---|
| Rolling | Reemplaza instancias/revisiones gradualmente, una porción a la vez |
| Canary | Desplaza tráfico gradualmente hacia la versión nueva, monitoreando señales antes de completar |
| Blue/Green | Despliega el entorno nuevo en paralelo y corta el tráfico de una vez cuando está validado |

En Cloud Run, tanto canary como blue/green se apoyan de forma natural en
el mecanismo de **revisiones y tráfico dividido** (ver documento [`02`](02-computo-contenedores-y-balanceo.md)):
no hace falta infraestructura adicional para desplazar tráfico
gradualmente entre dos revisiones.

---

# Parte IV — IaC no es lo mismo que CI/CD

## 8. ⚖ Distinción importante

**IaC** (Terraform, ver documento [`09`](09-terraform-iac.md)) describe **qué** infraestructura
debería existir. **CI/CD** (Cloud Build, Cloud Deploy) decide **cuándo y
cómo** se aplica ese cambio de forma segura y repetible — construir,
probar, promover entre ambientes, con aprobaciones donde corresponda.

Un pipeline típico entre non-prod y prod: despliegue automático en
non-prod tras pasar los tests, y aprobación manual (con revisión del
`terraform plan` o del cambio propuesto) antes de aplicar en producción.

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia a Workflows de un flujo orquestado con Eventarc + Cloud Run?
2. ¿Qué señal indica que un flujo necesita un Workflow explícito en lugar de lógica de orquestación embebida en un servicio?
3. ¿Qué produce Cloud Build y qué no hace por sí solo?
4. ¿Qué define un delivery pipeline de Cloud Deploy?
5. ¿Qué diferencia a un despliegue canary de uno blue/green?
6. ¿Cómo se apoya un despliegue canary en Cloud Run sin infraestructura adicional?
7. ¿Por qué IaC no es lo mismo que CI/CD?
8. ¿Qué aprobación tendría típicamente un pipeline entre non-prod y prod?
9. ¿Con qué identidad corre un build de Cloud Build, y por qué importa para el privilegio mínimo?
10. ¿Qué gana un pipeline al construir la imagen una sola vez y promoverla entre ambientes, en lugar de reconstruirla en cada uno?
11. ¿Por qué un rollback en Cloud Run puede ser cuestión de segundos, y qué lo impediría?

---

## 📚 Referencias oficiales

- Workflows overview: https://cloud.google.com/workflows/docs/overview
- Workflows syntax and error handling: https://cloud.google.com/workflows/docs/reference/syntax/catching-errors
- Cloud Build overview: https://cloud.google.com/build/docs/overview
- Cloud Build triggers: https://cloud.google.com/build/docs/automating-builds/create-manage-triggers
- Cloud Deploy overview: https://cloud.google.com/deploy/docs/overview
- Cloud Deploy delivery pipelines: https://cloud.google.com/deploy/docs/deploy-app-run
- Cloud Run traffic management: https://cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration
