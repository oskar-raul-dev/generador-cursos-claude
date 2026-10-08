# 12 — Orquestación y CI/CD

> **Objetivo:** separar la orquestación de la lógica de negocio, y explicar qué falta
> entre "tengo el template" y "está corriendo de forma confiable".
> **Se asume leído:** [`02`](02-computo-contenedores-y-balanceo.md),
> [`07`](07-mensajeria-eventos-integracion.md) y [`09`](09-cloudformation-iac.md).
> **Se conecta con:** [`11`](11-resiliencia-y-well-architected.md) (los reintentos de
> una State Machine son un patrón de resiliencia).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

---

## 1. 🧭 Por qué separar orquestación de la lógica de negocio

Con Lambda y ECS ya cubiertos en [`02`](02-computo-contenedores-y-balanceo.md), falta la
pieza que coordina múltiples pasos, reintentos y ramificaciones entre ellos sin meter
esa lógica dentro de una función.

```text
Lambda gigante:
  validar → cobrar → reservar inventario → notificar → actualizar analytics
  (todo en un solo handler, con try/catch anidados para cada paso)
```

```text
Con orquestador:
  Step Functions coordina el orden, los reintentos y el manejo de errores
  cada Lambda hace una sola cosa
```

Señal de que falta un orquestador: un Lambda con múltiples `try/catch` anidados, lógica de reintento manual entre pasos, o un flujo que combina llamadas síncronas a distintos servicios con ramificación condicional compleja.

---

## 2. ⚖ Step Functions — Standard vs Express workflows

| | Standard | Express |
|---|---|---|
| Duración máxima | hasta un año | minutos |
| Semántica de ejecución | exactly-once | at-least-once |
| Historial de ejecución | detallado, por ejecución | orientado a logs (CloudWatch Logs) |
| Caso típico | workflows de negocio, larga duración, auditables | alto volumen, eventos, procesamiento de streams |

No elijas Express solo por costo si necesitas semántica exactly-once y auditoría detallada por ejecución.

---

## 3. 🧱 State Machine — States (Task, Choice, Parallel, Map, Wait)

Una state machine se define declarativamente con Amazon States Language (JSON).

```text
Task     → ejecuta trabajo (invocar Lambda, ECS, otro servicio)
Choice   → rama según condición
Parallel → ejecuta ramas simultáneamente
Map      → aplica el mismo procesamiento a cada elemento de una colección
Wait     → pausa por tiempo fijo o hasta un timestamp
```

```text
Start
  │
  ▼
Task: ValidarOrden
  │
  ▼
Choice: ¿Pago aprobado?
  ├── Sí → Task: ReservarInventario → Task: Notificar → End
  └── No → Task: NotificarRechazo → End
```

---

## 4. ⚖ Step Functions + Lambda vs Step Functions + ECS

```text
Step Functions + Lambda → pasos cortos, event-driven, sin servidor
Step Functions + ECS    → pasos largos o con dependencias pesadas, contenedores ya existentes
```

Ambos pueden combinarse dentro de la misma state machine: un Task puede invocar Lambda para un paso corto y una ECS Task para un procesamiento más pesado, sin que el orquestador distinga arquitectónicamente entre ambos más allá de la integración configurada.

---

## 5. ⚖ Step Functions vs EventBridge vs colas — cuándo cada uno

Las tres piezas de [`07`](07-mensajeria-eventos-integracion.md) —cola, topic y event bus—
siguen valiendo; lo que cambia aquí es cuándo el problema pide coordinación explícita
en vez de desacoplamiento.

```text
Step Functions → conozco de antemano la secuencia de pasos y quiero orquestarla explícitamente
EventBridge    → un evento puede interesarle a varios consumidores desacoplados, sin que el productor conozca el flujo completo
SQS            → necesito desacoplar un productor de un trabajo async, sin orquestación de múltiples pasos
```

Regla de entrevista:

```text
"¿Cómo evitas un Lambda gigante con lógica de orquestación adentro?"        → Step Functions
"¿Cómo notificas a sistemas que no controlas sobre un evento de negocio?"   → EventBridge
```

---

## 6. 🧭 Por qué IaC solo no alcanza para CI/CD

CloudFormation ([`09`](09-cloudformation-iac.md)) describe declarativamente la
infraestructura, pero no decide cuándo, cómo ni bajo qué validaciones se aplica un cambio a producción — eso es CI/CD.

```text
IaC   → QUÉ infraestructura/aplicación debería existir
CI/CD → CUÁNDO y CÓMO se aplica ese cambio de forma segura y repetible
```

---

## 7. 🧭 CodePipeline — idea base

Orquesta el flujo de entrega continua entre etapas.

```text
Source (GitHub/Bitbucket/S3/otro)
   │
   ▼
Build (CodeBuild)
   │
   ▼
Deploy (CodeDeploy/CloudFormation/ECS/otro)
```

Cada etapa puede tener acciones en paralelo y aprobaciones manuales entre etapas cuando el flujo lo requiere.

> 📝 **Contexto.** Mucho material anterior a 2024 pone CodeCommit como origen por
> defecto del pipeline. AWS dejó de admitir clientes nuevos en CodeCommit en julio de
> 2024: las cuentas que ya lo usaban siguen funcionando, pero una cuenta creada hoy no
> puede crear repositorios ahí. En una entrevista, nombrar CodeCommit como opción
> disponible para un proyecto nuevo es un error de actualidad.

---

## 8. 🧱 CodeBuild

Servicio administrado de build/test: compila, corre pruebas y produce artefactos según se defina en `buildspec.yml`.

```yaml
version: 0.2
phases:
  build:
    commands:
      - mvn test
      - docker build -t app .
artifacts:
  files:
    - '**/*'
```

No administra por sí solo el despliegue; entrega el artefacto a la siguiente etapa del pipeline.

---

## 9. 🧱 CodeDeploy — estrategias de despliegue (in-place, blue/green, canary)

```text
In-place    → actualiza las instancias/tasks existentes directamente
Blue/Green  → despliega el entorno nuevo en paralelo, corta tráfico cuando está validado
Canary      → desplaza tráfico gradualmente hacia la nueva versión, monitoreando señales antes de completar
```

```text
Blue/Green:
  Entorno actual (Blue) sirviendo 100% del tráfico
     │
     ▼
  Entorno nuevo (Green) desplegado, sin tráfico
     │ validación
     ▼
  tráfico cambia de Blue a Green
     │
     └── rollback = volver a apuntar a Blue
```

Regla de arquitectura:

```text
In-place              → más simple, rollback más lento
Blue/Green y Canary   → rollback casi inmediato, mayor costo/complejidad operativa
```

---

## 10. ⚖ Estado actual: CodePipeline/Build/Deploy vs herramientas de terceros

El curso cubre las piezas nativas de AWS, pero en la práctica muchos equipos usan GitHub Actions, GitLab CI o Jenkins junto con —o en vez de— CodePipeline/CodeBuild/CodeDeploy: el ecosistema de terceros para CI/CD está tan extendido como el de AWS-nativo.

| | CodePipeline/Build/Deploy | GitHub Actions / GitLab CI |
|---|---|---|
| Integración nativa con servicios AWS | directa | vía plugins/CLI/OIDC |
| Dónde vive el pipeline | consola/CLI AWS | junto al código, en el mismo repositorio |
| Curva si el equipo ya usa GitHub/GitLab | adicional | ninguna |
| Caso típico | shops 100% AWS, gobierno centralizado del pipeline | equipos que ya versionan y colaboran en GitHub/GitLab |

Ninguna opción es objetivamente superior: la nativa tiene mejor integración de permisos/servicios AWS; la de terceros suele ganar cuando el flujo de trabajo del equipo ya vive en esa plataforma.

---

## 11. 🧪 Pipeline recomendado end-to-end

Conecta con [`09` §34 — Workflow recomendado](09-cloudformation-iac.md#34--workflow-recomendado),
que terminaba en "commit / pull request" sin explicar qué pasa después.

```text
commit / pull request
    │
    ▼
CI: build + test (CodeBuild o equivalente)
    │
    ▼
CD: crear Change Set / plan de IaC
    │
    ▼
aprobación (automática en non-prod, manual en prod)
    │
    ▼
deploy (in-place/blue-green/canary según servicio)
    │
    ▼
monitoreo post-deploy (CloudWatch, alarms)
    │
    └── rollback automático/manual si las señales empeoran
```

---

## 🧠 Preguntas rápidas

1. ¿Qué señal indica que un Lambda necesita un orquestador en vez de más `try/catch`?
2. ¿Standard vs Express workflow en Step Functions?
3. ¿Qué hace un estado `Map` en una state machine?
4. ¿Cuándo usarías Step Functions en vez de EventBridge?
5. ¿Por qué IaC no es lo mismo que CI/CD?
6. ¿Qué produce CodeBuild y qué NO hace?
7. ¿Blue/Green vs Canary?
8. ¿Por qué in-place tiene rollback más lento?
9. ¿Es CodePipeline la única opción válida de CI/CD en un shop AWS?
10. ¿Qué aprobaciones tendría un pipeline entre non-prod y prod?

---

## 📚 Referencias oficiales

- Step Functions: https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html
- Standard vs Express workflows: https://docs.aws.amazon.com/step-functions/latest/dg/choosing-workflow-type.html
- Amazon States Language: https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html
- CodePipeline: https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html
- CodeBuild: https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html
- CodeDeploy deployment types: https://docs.aws.amazon.com/codedeploy/latest/userguide/deployments.html
- States de una State Machine: https://docs.aws.amazon.com/step-functions/latest/dg/workflow-states.html
- Manejo de errores: `Retry` y `Catch`: https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html
- Map state: https://docs.aws.amazon.com/step-functions/latest/dg/state-map.html
- Conceptos de CodePipeline: https://docs.aws.amazon.com/codepipeline/latest/userguide/concepts.html
- Referencia del `buildspec`: https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
- CodeDeploy: https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html
