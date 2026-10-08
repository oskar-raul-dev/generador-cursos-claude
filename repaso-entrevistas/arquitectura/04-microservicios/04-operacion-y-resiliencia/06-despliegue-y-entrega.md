# 06 — Despliegue y entrega

> El despliegue independiente como criterio de éxito de toda la arquitectura: pipeline por servicio,
> estrategias de despliegue, feature flags y el debate monorepo contra polirepo. Asume leído
> [`03-datos-y-consistencia/05`](../03-datos-y-consistencia/05-evolucion-de-esquema-y-migraciones.md),
> porque el esquema y el despliegue van juntos. La infraestructura concreta de cada nube es de
> [`cloud/01-aws`](../../../cloud/01-aws/) y
> [`cloud/02-gcp`](../../../cloud/02-gcp/).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Todo este corpus se apoya en una promesa: **desplegar un servicio sin desplegar los demás**. Si eso
no se cumple, nada de lo anterior compensa — es el monolito distribuido de
[`01-fundamentos-y-descomposicion/04`](../01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md).

Y sin embargo hay tres cosas que rompen esa promesa sin que nadie lo decida:

```text
1. Un contrato incompatible      → hay que desplegar consumidor y proveedor a la vez
2. Una migración destructiva     → el código nuevo y el viejo no pueden convivir
3. Un pipeline que los une       → aunque técnicamente sean independientes
```

Las dos primeras ya tienen capítulo. La tercera es de este, y es la más fácil de arreglar y la que
más se olvida: a veces los servicios **podrían** desplegarse solos y no lo hacen porque nadie ha
partido el pipeline.

---

## 2. 🧱 Una imagen, construida una vez, promovida entre entornos

**Qué es.** El artefacto se construye una sola vez y **el mismo** recorre todos los entornos. Lo que
cambia entre ellos es la configuración, que viene de fuera.

```text
construir ──► imagen:abc123 ──► pruebas ──► preproducción ──► producción
                (la misma)        (config)      (config)        (config)
```

**Cómo va.** Reconstruir por entorno rompe la garantía entera: lo que probaste no es lo que
despliegas. Y la versión del artefacto tiene que ser trazable hasta el commit, porque la primera
pregunta de cualquier incidente es "¿qué hay desplegado exactamente?".

**Cuánto.** Cuesta disciplina en la configuración —nada de perfiles compilados dentro— y un registro
de artefactos. No cuesta nada más.

**Cuándo no.** No hay excepción razonable.

> **Veredicto:** si la imagen se reconstruye para producción, las pruebas de los entornos anteriores
> valen menos de lo que parecen. Construir una vez es la base sobre la que se sostiene todo lo demás
> del capítulo.

---

## 3. ⚖️ Rolling, blue-green y canary

| | Rolling | Blue-green | Canary |
|---|---|---|---|
| **Cómo** | Se reemplazan instancias por tandas | Dos entornos completos; se conmuta el tráfico | Un porcentaje pequeño va a la versión nueva |
| **Vuelta atrás** | Desplegar la anterior (lento) | Conmutar de vuelta (inmediata) | Bajar el porcentaje (inmediata) |
| **Coste** | Ninguno extra | Doble infraestructura durante el cambio | Enrutado por porcentaje y métricas comparadas |
| **Convivencia de versiones** | Sí, obligatoria | Breve, durante la conmutación | Sí, prolongada |
| **Detecta problemas** | Cuando ya está todo desplegado | Al conmutar, con todo el tráfico | Con una fracción del tráfico |

**Lo que las tres comparten**, y es lo que hay que decir en una entrevista: **las tres requieren
compatibilidad entre versiones**. Rolling y canary la exigen durante todo el proceso; blue-green la
exige con la base de datos, que es compartida por los dos entornos.

Ese último punto es el que más se olvida: blue-green parece dar un cambio atómico, pero **la base de
datos no se duplica**. Si el esquema no es compatible con ambas versiones, la conmutación no se puede
deshacer aunque el tráfico sí.

**Canary** merece un matiz: no es canary si nadie mira las métricas. Desviar un 5 % y no comparar
errores y latencia contra el resto es un rolling lento con más pasos.

> **💡 Truco:** la pregunta que distingue a quien ha desplegado de quien lo ha leído es: *"¿qué haces
> con la base de datos en un blue-green?"*. La respuesta correcta es que la base es una sola y por eso
> las migraciones tienen que ser compatibles igualmente.

---

## 4. 🧱 Desplegar no es activar: feature flags

**Qué es.** Separar el momento en que el código llega a producción del momento en que la
funcionalidad se activa.

**Cómo va.** El código nuevo se despliega apagado; se activa después, para un porcentaje o para un
grupo; y si algo va mal, se apaga sin desplegar. Eso convierte una vuelta atrás de diez minutos en
una de diez segundos.

Y tiene un efecto secundario que es el verdadero motivo por el que se usa en microservicios:
**permite integrar continuamente sin bloquear**. Una funcionalidad a medias puede estar en producción
apagada, en vez de vivir en una rama larga que diverge.

**Cuánto.** Cuesta lo que nadie presupuesta: **los flags se acumulan**. Cada uno es una bifurcación en
el código y en las pruebas, y un sistema con cincuenta flags vivos tiene un número inmanejable de
combinaciones posibles.

**Cuándo sí.** Para cambios de comportamiento arriesgados, para activaciones coordinadas y para
despliegues progresivos.

**Cuándo no.** Para cambios triviales. Y nunca sin fecha de retirada: un flag que lleva un año en
`true` no es un flag, es código muerto con un `if` delante.

> **⚠️ Advertencia:** los flags que deciden reglas de negocio acaban siendo configuración de negocio
> sin gobierno. Conviene distinguir el flag de despliegue —temporal, técnico, con fecha— del
> parámetro de negocio, que es otra cosa y merece su propio sitio.

---

## 5. ⚖️ Monorepo contra polirepo

El debate honesto, sin ganador universal:

| | Monorepo | Polirepo |
|---|---|---|
| **Refactor transversal** | Un cambio, un pull request | N cambios coordinados |
| **Visibilidad** | Todo el código a la vista | Hay que saber dónde buscar |
| **Propiedad** | Requiere convención y herramientas | Natural: un repositorio, un equipo |
| **CI** | Necesita construcción selectiva o se dispara el coste | Simple: cada uno el suyo |
| **Riesgo** | Facilita compartir código de dominio sin querer | Facilita duplicar sin querer |
| **Despliegue independiente** | Posible, pero hay que construirlo | Por defecto |

Lo importante, y es la frase que conviene tener: **ninguno de los dos determina si tu arquitectura es
de microservicios**. Hay sistemas perfectamente autónomos en un monorepo y monolitos distribuidos
repartidos en cuarenta repositorios. Lo que decide es si puedes desplegar y migrar sin coordinar.

El riesgo específico del monorepo sí merece nombrarse: como compartir código es trivial, la librería
común de dominio aparece sola. Hace falta una regla explícita y, si se puede, verificada.

---

## 6. 🧱 El pipeline de un servicio

Lo mínimo, en orden, y por qué cada paso está donde está:

```text
1. Construir           una vez; artefacto versionado y trazable al commit
2. Pruebas unitarias   rápidas; si tardan, nadie las ejecuta en local
3. Pruebas de componente con dependencias simuladas
4. Verificación de contrato  pactos de los consumidores (07)
5. Construir imagen    etiquetada con la versión del artefacto
6. Migración           paso explícito, compatible hacia atrás (03/05)
7. Desplegar           rolling o canary, gradual
8. Verificar           métricas y errores comparados con la versión anterior
9. Promover o revertir  decisión automática donde se pueda
```

El paso 4 es el que hace posible el despliegue independiente: si un cambio rompe a un consumidor, el
pipeline **del proveedor** falla antes de desplegar. Y el 8 es el que convierte el despliegue en algo
reversible de verdad: sin verificación, la vuelta atrás depende de que alguien se dé cuenta.

---

## 7. 🧰 Empaquetado y arranque, por plataforma

Esta es la tabla que sostiene media discusión de [`05-plataformas`](../05-plataformas/), y se declara
aquí porque es una propiedad operativa, no de lenguaje.

| Plataforma | Imagen | Arranque | Memoria en reposo | Detalle que importa |
|---|---|---|---|---|
| **Java** | Grande salvo que se recorte con imágenes por capas o runtime a medida | De segundos; con compilación nativa baja mucho | La más alta de las cuatro, y configurable | El arranque afecta al escalado reactivo y a la sonda de arranque |
| **Node/TS** | Media; el árbol de dependencias es el peso | Rápido | Moderada | El tamaño lo marca `node_modules`: conviene construir en varias etapas |
| **Go** | **Pequeña**: un binario estático sobre una base mínima | Casi inmediato | Baja | El binario único es su mayor ventaja operativa |
| **Python** | Media-grande si hay dependencias nativas | Rápido | Moderada | Las dependencias compiladas complican la imagen y la reproducibilidad |

- **Lo que te deja a ti en las cuatro:** que el tiempo de arranque no es un detalle estético. Decide
  cuánto tarda un reemplazo, si el escalado automático llega a tiempo al pico, y cuánto margen
  necesita la sonda de arranque para no matar instancias que todavía están levantando.
- Y una consecuencia de coste: instancias que arrancan lento obligan a mantener más capacidad de
  reserva, porque no puedes esperar a que el escalado reaccione.

> **🧰 Plataforma:** en una entrevista, el arranque es el dato con el que se argumenta la elección de
> plataforma para cargas muy variables o para funciones efímeras. Y el contraargumento honesto es que
> para un servicio con tráfico constante y escalado previsible, casi da igual.

---

## 8. 🧭 Cómo se elige la estrategia

```text
¿Puedes tener dos versiones conviviendo? (contratos y esquema compatibles)
├─ no ──► arréglalo primero. Ninguna estrategia funciona sin eso.
└─ sí
   │
   ├─ ¿Tienes métricas para comparar versiones automáticamente? ──► canary
   │
   ├─ ¿Necesitas vuelta atrás inmediata y puedes pagar doble
   │   infraestructura un rato? ───────────────────────────────► blue-green
   │
   └─ ¿Ninguna de las dos? ────────────────────────────────────► rolling,
                                                                  que es el
                                                                  valor por defecto
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Desplegamos todo junto porque es más seguro" | Es más arriesgado: un fallo obliga a revertir todo y el alcance del cambio es mayor |
| "Canary es lo mismo que blue-green" | Canary reparte tráfico y compara métricas; blue-green conmuta entre dos entornos completos |
| "Con blue-green la vuelta atrás es atómica" | Del tráfico sí; la base de datos es una sola y sus migraciones tienen que ser compatibles igual |
| "El monorepo acopla" | Acopla si se comparte código de dominio. El acoplamiento es de contenido, no de repositorio |
| "La imagen se reconstruye en cada entorno" | Entonces lo que probaste no es lo que despliegas. Se construye una vez y se promueve |
| "Los flags los quitamos cuando haya tiempo" | Se acumulan y multiplican las combinaciones. Nacen con fecha de retirada o no nacen |
| "Desplegar y activar es lo mismo" | Separarlos es lo que convierte una vuelta atrás de minutos en una de segundos |

---

## 📚 Para profundizar

1. **Libro** — Jez Humble y David Farley, *Continuous Delivery*, Addison-Wesley, 2010. Capítulos 5 y
   10: la tubería de despliegue y las estrategias. **Sigue siendo la referencia del tema.**
2. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulos 7 y 8, sobre
   construcción y despliegue de microservicios, con el debate de repositorios.
3. **Libro** — Nicole Forsgren, Jez Humble y Gene Kim, *Accelerate*, IT Revolution, 2018. Para las
   métricas de entrega y por qué el despliegue frecuente correlaciona con estabilidad.
4. **Fuente primaria** — Martin Fowler, «BlueGreenDeployment»:
   [martinfowler.com/bliki/BlueGreenDeployment.html](https://martinfowler.com/bliki/BlueGreenDeployment.html).
5. **Fuente primaria** — Martin Fowler, «CanaryRelease»:
   [martinfowler.com/bliki/CanaryRelease.html](https://martinfowler.com/bliki/CanaryRelease.html).
6. **Fuente primaria** — Pete Hodgson, «Feature Toggles», con la taxonomía de tipos de flag y su
   ciclo de vida:
   [martinfowler.com/articles/feature-toggles.html](https://martinfowler.com/articles/feature-toggles.html).
7. **Material de referencia** — Amazon Builders' Library, «Ensuring rollback safety during
   deployments»:
   [aws.amazon.com/builders-library/ensuring-rollback-safety-during-deployments/](https://aws.amazon.com/builders-library/ensuring-rollback-safety-during-deployments/).
8. **Charla** — GOTO Conferences, «Continuous Delivery Sounds Great, but Will It Work Here?» (Jez
   Humble). Es la mejor respuesta a las objeciones habituales en organizaciones grandes.

---

## 🧠 Preguntas

1. ¿Por qué el despliegue independiente es el criterio de éxito de la arquitectura? 🟢
2. ¿Qué significa construir una vez y promover? 🟢
3. Diferencia entre rolling, blue-green y canary. 🟢
4. ¿Qué es un feature flag y qué separa? 🟢
5. Enumera los pasos mínimos del pipeline de un servicio. 🟢
6. ¿Qué tres cosas rompen el despliegue independiente? 🟢
7. ¿Por qué blue-green no da una vuelta atrás realmente atómica? 🟡
8. ¿Por qué las tres estrategias exigen compatibilidad entre versiones? 🟡
9. ¿Qué diferencia hay entre un canary de verdad y un rolling lento? 🟡
10. ¿Por qué el monorepo no determina si hay microservicios? 🟡
11. ¿Por qué los flags que deciden reglas de negocio son problemáticos? 🟡
12. ¿Por qué el tiempo de arranque es una propiedad operativa y no estética? 🟡
13. ¿Qué cambia entre las cuatro plataformas en imagen, arranque y memoria, y qué consecuencia
    operativa tiene? 🟡
14. Tu pipeline despliega cinco servicios juntos. ¿Cómo compruebas si es necesario? 🟠
15. ¿Qué verificas automáticamente tras un despliegue para decidir si promover o revertir? 🟠
16. ¿Cómo evitas que los flags se acumulen? 🟠
17. Un equipo quiere blue-green para poder revertir rápido. ¿Qué le adviertes? 🟠
18. ¿Qué pones en el paso de verificación de contrato del pipeline y por qué ahí? 🟠
19. ¿Cómo organizarías el CI de un monorepo con veinte servicios? 🟠
20. ¿Qué haces si una funcionalidad necesita desplegar dos servicios coordinados? 🟠
21. ¿Qué métricas de entrega seguirías para saber si el sistema mejora? 🟠
22. Tu servicio escala a golpes contra picos de tráfico. ¿Qué cambia según esté escrito en Java o en
    Go, y qué harías en cada caso 🟠
23. Diseña el pipeline completo de `orders`, desde el commit hasta producción, con los puntos de
    decisión y de vuelta atrás. 🔴
24. Diseña el despliegue de un cambio que afecta a `orders` y a `inventory` a la vez, sin
    desplegarlos coordinados. 🔴
25. Escribe la política de feature flags del equipo: tipos, propiedad, caducidad y verificación. 🔴
26. Diagnostica: los despliegues producen un goteo de errores cada vez, y nadie sabe por qué. Da
    tres hipótesis ordenadas y cómo las distingues. 🔴

---

**Anterior:** [`05` — Service mesh y sidecar](05-service-mesh-y-sidecar.md) · **Siguiente:**
[`07` — Testing de microservicios](07-testing-de-microservicios.md) · **Relacionado:**
[`03-datos-y-consistencia/05`](../03-datos-y-consistencia/05-evolucion-de-esquema-y-migraciones.md) ·
[`05-plataformas`](../05-plataformas/)
