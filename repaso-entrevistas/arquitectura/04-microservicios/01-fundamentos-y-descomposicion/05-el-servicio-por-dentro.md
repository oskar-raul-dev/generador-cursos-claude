# 05 — El servicio por dentro

> Qué hay dentro de un servicio bien hecho: estructura interna, chassis, configuración, apagado
> ordenado y health checks. Es el primer capítulo con comparativa de las cuatro plataformas, y el que
> fija el vocabulario que los bloques `02` a `04` dan por sabido. Asume leído
> [`01`](01-que-es-un-microservicio.md). La estructura hexagonal como decisión de diseño es de
> [`arquitectura/01-bases/01-bases/03`](../../01-bases/01-bases/03-arquitecturas-de-aplicacion.md),
> y en profundidad de [`arquitectura/03-hexagonal`](../../03-hexagonal/); aquí se usa, no se justifica.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Tienes que crear el servicio número seis. Los cinco anteriores los hizo cada uno a su manera: uno
loguea en texto plano y otro en JSON; tres exponen `/health` y dos `/status`; uno lee la configuración
de un fichero y otro de variables de entorno; ninguno apaga bien, así que **cada despliegue tira un
puñado de peticiones en vuelo** y nadie sabe exactamente cuántas.

Eso no es un problema de estilo. Tiene consecuencias medibles:

```text
Sin formato de log común      →  no puedes buscar una petición en los cinco a la vez
Sin health check uniforme     →  el orquestador no sabe cuándo enviar tráfico
Sin apagado ordenado          →  cada despliegue produce errores 502 que nadie cuenta
Sin cliente HTTP configurado  →  cada servicio hereda el timeout por defecto, que suele ser ninguno
```

La respuesta no es un documento de buenas prácticas: es **código compartido y una plantilla**. Y la
decisión interesante —la que se pregunta en una entrevista de Tech Lead— es cuánto de eso se comparte
y en qué forma, porque compartir mal es exactamente el antipatrón del capítulo
[`04`](04-el-monolito-distribuido.md).

---

## 2. 🧱 La estructura interna mínima

**Qué es.** Cuatro zonas dentro del servicio, con una regla de dependencia: hacia dentro se permite,
hacia fuera no.

```text
transporte     controladores HTTP, consumidores de cola, handlers de gRPC
aplicación     casos de uso: orquestan, no deciden reglas
dominio        las reglas y las invariantes. No conoce a nadie
salida         repositorios, clientes de otros servicios, publicadores de eventos
```

**Cómo va.** El dominio no importa nada del framework. El caso de uso habla con interfaces; las
implementaciones concretas —el repositorio, el cliente HTTP del otro servicio— viven en salida. Esa
disciplina es lo que permite probar el caso de uso sin levantar nada.

**Con qué.** Es la misma estructura en las cuatro plataformas, con nombres distintos: paquetes en
Java y Go, módulos en NestJS, paquetes en Python. Ninguna necesita librería para esto.

**Cuánto.** Cuesta mapeo entre la entidad de persistencia y la de dominio, y cuesta interfaces que a
veces tienen una sola implementación. En un servicio con reglas de verdad se paga solo; en uno que
solo persiste, es ceremonia.

**Cuándo sí.** Cuando el servicio tiene invariantes que proteger o cuando su lógica va a crecer.

**Cuándo no.** En un servicio de lectura pura —una proyección que sirve consultas— donde la capa de
dominio estaría vacía. Ahí se admite ir del transporte a la consulta directamente, y se declara.

> **Veredicto:** hexagonal rinde más en un microservicio que en un monolito, porque el servicio es
> pequeño y la frontera se puede mantener de verdad. Pero un servicio sin reglas no necesita
> dominio: estarías pagando el mapeo para nada.

---

## 3. 🧱 El service chassis

**Qué es.** El conjunto de piezas transversales que todo servicio necesita y que **ninguna es de
negocio**: configuración, logs estructurados, métricas, tracing, health checks, cliente HTTP con
timeouts, apagado ordenado, manejo uniforme de errores.

**Cómo va.** Hay dos formas de repartirlo, y la elección es la pregunta de entrevista:

| Forma | Qué es | Lo que cuesta |
|---|---|---|
| **Librería (chassis)** | Una dependencia que trae todo configurado | Subir versión toca a todos; hay que evitar que se le meta dominio |
| **Plantilla (template)** | Un generador que crea el proyecto ya cableado | Cada servicio diverge con el tiempo; las mejoras no llegan solas |

En la práctica se combinan: **librería para lo que debe ser idéntico** —formato de log, nombres de
métricas, propagación de contexto— y **plantilla para lo que cada servicio va a tocar** —estructura
de carpetas, pipeline, manifiestos—.

**Con qué.** En Java el chassis suele ser un starter propio sobre Spring Boot; en Node/TS, un paquete
privado más un generador; en Go, una plantilla de repositorio y un par de paquetes internos —la
cultura del ecosistema empuja a copiar antes que a compartir—; en Python, un paquete privado con la
configuración de logging y de OpenTelemetry.

**Cuánto.** La librería cuesta gobierno: alguien tiene que ser su dueño y decidir qué entra. Y cuesta
la disciplina de §4 del capítulo [`04`](04-el-monolito-distribuido.md): **nada de dominio dentro**,
nunca, ni "solo esta clase".

**Cuándo sí.** A partir del tercer servicio. Con dos, copiar es más barato que gobernar.

**Cuándo no.** Cuando cada servicio está en una plataforma distinta: mantener cuatro chassis
equivalentes es el coste real del poliglotismo, y se discute en [`05/06`](../05-plataformas/06-la-matriz-de-decision.md).

> **Veredicto:** el chassis es la única librería compartida legítima entre servicios, y lo es
> mientras no contenga una sola regla de negocio. El día que la contenga, es el monolito.

---

## 4. 🧱 Configuración y el arranque

**Qué es.** Todo lo que cambia entre entornos vive fuera del artefacto: la misma imagen se despliega
en pruebas y en producción, y lo que cambia es el entorno.

**Cómo va.** La jerarquía habitual, de menor a mayor prioridad: valores por defecto en el código →
fichero empaquetado → variables de entorno → secretos inyectados por la plataforma. Y dos reglas que
evitan la mayoría de incidentes:

- **Fallar al arrancar si falta configuración obligatoria.** Un servicio que arranca sin la URL de su
  dependencia y falla en la primera petición convierte un error de despliegue en un incidente.
- **Nunca un secreto en el artefacto ni en el repositorio.** Se inyectan; su gestión concreta es de
  los corpus de nube.

**Con qué.** Las cuatro plataformas tienen su mecanismo —propiedades y perfiles en Spring, `dotenv` y
módulos de configuración en Node, variables y banderas en Go, `pydantic-settings` en Python—. Lo que
no varía es la regla: **la configuración se lee al arrancar y se valida ahí**, salvo lo que
explícitamente deba poder cambiar en caliente, como un feature flag.

**Cuánto.** Validar al arrancar cuesta escribir el esquema de configuración. Se paga la primera vez
que un despliegue falla rápido y claro en vez de lento y raro.

**Cuándo sí.** Siempre.

**Cuándo no.** No hay "cuándo no" para externalizar; sí lo hay para la recarga en caliente, que añade
complejidad y solo se justifica para flags y para niveles de log.

> **📝 Contexto:** de los doce factores originales, los que siguen mandando son configuración por
> entorno, procesos sin estado y paridad entre entornos. El que envejeció es "logs a stdout y que
> alguien los recoja": sigue siendo correcto, pero hoy lo que importa es que el log sea
> **estructurado y correlacionado**, no dónde se escribe.

---

## 5. 🧱 Apagado ordenado

**Qué es.** Cuando llega la señal de terminación, el servicio deja de aceptar peticiones nuevas,
termina las que tiene en curso y solo entonces se muere.

**Cómo va.** La secuencia completa, que es la que hay que saber dibujar:

```text
1. La plataforma marca la instancia como no lista (readiness = false)
2. El balanceador deja de mandarle tráfico          ← aquí hay un retraso real
3. El servicio termina las peticiones en vuelo
4. Cierra pools, conexiones y consumidores
5. Sale
```

El paso 2 es el que casi nadie modela: entre que la instancia se marca como no lista y el balanceador
se entera pasan segundos. Si el servicio se cierra de inmediato, esas peticiones se pierden. Por eso
la práctica recomendada incluye **esperar unos segundos antes de empezar a cerrar**, aunque parezca
absurdo.

Un consumidor de cola tiene su propia versión: dejar de pedir mensajes nuevos, terminar el que tiene,
confirmar, y cerrar. Si se cierra sin confirmar, el mensaje se reentrega — y ahí la idempotencia deja
de ser teoría.

**Cuánto.** Cuesta unos segundos más por despliegue. Lo que compra es que un despliegue no produzca
errores visibles, que en un sistema con despliegues diarios es la diferencia entre confiar en el
proceso o temerlo.

> **⚠️ Advertencia:** sin apagado ordenado, cada despliegue tira peticiones. Con réplicas y rolling
> update eso son cientos de errores al día que aparecen en el tablero como "ruido de fondo" y que
> acaban normalizándose. El ruido de fondo casi siempre es esto.

---

## 6. 🧱 Health checks que sirven

**Qué es.** Dos preguntas distintas que la plataforma hace y que se confunden constantemente:

| Sonda | Pregunta | Qué pasa si falla |
|---|---|---|
| **Liveness** | ¿Estás vivo o hay que reiniciarte? | Te reinician |
| **Readiness** | ¿Puedes recibir tráfico ahora? | Te sacan del balanceo, sin reiniciar |

**Cómo va.** La regla que evita el incidente clásico: **liveness no comprueba dependencias**. Si tu
liveness consulta la base de datos y la base se cae, la plataforma reinicia todas tus instancias, en
bucle, mientras la base sigue caída. Has convertido una degradación en una caída total con reinicios.

```text
liveness   → ¿el proceso responde? Nada más.
readiness  → ¿tengo lo imprescindible para atender? (conexiones abiertas, caché cargada)
```

**Con qué.** El endpoint estándar es del chassis, no de cada servicio: mismo camino, mismo formato.
En Java lo da Actuator con sus grupos; en las otras tres se escribe una vez en la plantilla.

**Cuánto.** Cuesta pensar qué dependencias son imprescindibles y cuáles no. Esa lista es una decisión
de diseño: si `orders` puede responder consultas con `payments` caído, `payments` no va en su readiness.

> **Veredicto:** liveness sin dependencias, readiness con las imprescindibles, y la lista de
> "imprescindibles" es la definición operativa de qué puede degradarse en tu servicio.

---

## 7. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Apagado ordenado con una propiedad, health checks con grupos y métricas por Actuator, configuración con perfiles y validación | Decidir qué va en readiness, y recordar que el periodo de gracia por defecto puede quedarse corto |
| **Node/TS** | NestJS trae ganchos de ciclo de vida y módulo de configuración; Fastify trae ganchos de cierre | Cerrar a mano lo que abriste —pools, consumidores—, y que el proceso no muera antes por una excepción no capturada |
| **Go** | `net/http` trae `Shutdown` con contexto; señales y `context` en la librería estándar | Todo el cableado: señales, orden de cierre, health checks, formato de log. A cambio, se ve entero |
| **Python** | `lifespan` en ASGI para arranque y cierre; configuración tipada con Pydantic | Que los trabajadores del servidor cierren ordenados, y que las tareas de fondo terminen antes de salir |

El apagado ordenado es el mejor ejemplo de la diferencia real entre plataformas, porque es donde una
te da una propiedad y otra te da el mecanismo entero. En Java:

```java
// Todo el apagado ordenado, en configuración. El periodo de gracia es el que
// tarda el balanceador en enterarse: si es más corto, se pierden peticiones.
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
```

- No hay código: el servidor deja de aceptar conexiones nuevas y espera a las activas.
- El valor de 30 segundos no es mágico: tiene que ser **mayor** que el tiempo que tarda tu
  plataforma en sacar la instancia del balanceo, y **menor** que el plazo que esa plataforma te da
  antes de matar el proceso.

Lo mismo en Go, donde se ve cada pieza:

```go
// El servidor deja de aceptar y espera a que terminen las peticiones en curso.
stop := make(chan os.Signal, 1)
signal.Notify(stop, syscall.SIGTERM)
<-stop

// Margen para que el balanceador deje de enviar tráfico antes de cerrar.
time.Sleep(5 * time.Second)

ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()
if err := server.Shutdown(ctx); err != nil { // devuelve error si expira el plazo
    log.Printf("cierre forzado: %v", err)
}
```

- `signal.Notify` es explícito: en Go decides tú qué señales atiendes y qué haces con ellas.
- El `time.Sleep` es el paso 2 de §5, escrito a mano. En Java lo esconde la plataforma; aquí se ve, y
  verlo ayuda a entender por qué existe.
- `Shutdown` recibe un `context` con plazo: si expira, corta. Ese patrón —todo lleva contexto con
  deadline— es el que hace que en Go los timeouts se propaguen tan bien, y volverá en
  [`02/03`](../02-comunicacion/03-grpc.md) con gRPC.

> **🧰 Plataforma:** la diferencia no es que una plataforma sea mejor: es **dónde está la decisión**.
> En Java la decisión está en un valor de configuración que alguien tiene que saber que existe; en Go
> está en código que alguien tiene que escribir. Las dos fallan igual si nadie piensa en el paso 2.

---

## 8. 🧭 Qué no va dentro del servicio

Tres cosas que aparecen dentro de un servicio y no deberían, con lo que hay que hacer en su lugar:

```text
Lógica de otro contexto        → va al servicio dueño; aquí solo se llama o se escucha
Acceso a datos de otro         → API o evento; si duele, la frontera está mal (02)
Reglas transversales de negocio → no existen: o son de un dueño, o son varias reglas parecidas
```

La tercera es la más discutida. "Validar que el cliente esté activo" parece transversal porque la
necesitan tres servicios; en realidad cada uno necesita algo ligeramente distinto en un momento
distinto, y unificarlas produce una dependencia común que cambia cada semana. El criterio: **si
compartirla obliga a desplegar a varios cuando cambie, no era transversal**.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Hexagonal es para monolitos" | En un servicio pequeño la frontera se puede mantener de verdad. Donde sobra es en servicios sin reglas |
| "El health check comprueba que la base de datos responde" | Eso es readiness. Si lo pones en liveness, la plataforma reinicia todas tus instancias mientras la base está caída |
| "La configuración va en el fichero del repositorio" | Va fuera del artefacto. La misma imagen debe correr en pruebas y en producción |
| "El apagado ordenado lo hace el orquestador" | El orquestador manda la señal; terminar lo que está en vuelo es del servicio, y esperar a que el balanceador se entere, también |
| "El chassis es copiar y pegar el proyecto anterior" | Eso es la plantilla, y diverge. Lo que debe ser idéntico —logs, métricas, contexto— va en librería con dueño |
| "Ponemos la validación común en la librería compartida" | Si al cambiarla hay que desplegar a varios, no era común: eran reglas parecidas de dueños distintos |
| "Si falta una variable de entorno, ya fallará cuando se use" | Fallar al arrancar convierte un incidente en un despliegue fallido, que es muchísimo más barato |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 6,
   "Workflow", y capítulo 10, "From Monitoring to Observability", para lo que el chassis tiene que
   traer resuelto.
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 11, "Developing
   production-ready services": chassis, health checks y configuración, en un solo sitio. **El
   capítulo de referencia para este tema.**
3. **Fuente primaria** — Chris Richardson, «Pattern: Microservice chassis»:
   [microservices.io/patterns/microservice-chassis.html](https://microservices.io/patterns/microservice-chassis.html).
4. **Fuente primaria** — Chris Richardson, «Pattern: Health Check API»:
   [microservices.io/patterns/observability/health-check-api.html](https://microservices.io/patterns/observability/health-check-api.html).
5. **Documentación** — Spring Boot, apagado ordenado y sus tiempos:
   [docs.spring.io/spring-boot/reference/web/graceful-shutdown.html](https://docs.spring.io/spring-boot/reference/web/graceful-shutdown.html).
6. **Documentación** — Go, `http.Server.Shutdown` y su contrato:
   [pkg.go.dev/net/http#Server.Shutdown](https://pkg.go.dev/net/http#Server.Shutdown).
7. **Documentación** — Kubernetes, sondas de liveness, readiness y startup, con sus tiempos:
   [kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).
8. **Referencia** — The Twelve-Factor App, «Config», la parte que sigue vigente:
   [12factor.net/config](https://12factor.net/config).

---

## 🧠 Preguntas

1. ¿Cuáles son las cuatro zonas de la estructura interna y cuál es la regla de dependencia? 🟢
2. ¿Qué es un service chassis y qué contiene? 🟢
3. Diferencia entre liveness y readiness. 🟢
4. Enumera los cinco pasos de un apagado ordenado. 🟢
5. ¿Por qué la configuración va fuera del artefacto? 🟢
6. ¿Qué debe pasar si falta una variable de configuración obligatoria? 🟢
7. ¿Por qué el chassis es la única librería compartida legítima entre servicios? 🟡
8. Chassis contra plantilla: ¿qué resuelve cada uno y qué se le escapa? 🟡
9. ¿Por qué comprobar la base de datos en liveness convierte una degradación en una caída total? 🟡
10. ¿Qué diferencia hay entre el apagado de un servicio HTTP y el de un consumidor de cola? 🟡
11. ¿Qué parte de los doce factores envejeció y cuál sigue mandando? 🟡
12. ¿Qué pasa entre que una instancia se marca como no lista y el balanceador deja de mandarle
    tráfico, y cómo se modela? 🟠
13. Eliges los valores de tiempo del apagado ordenado. ¿Entre qué dos límites tienen que estar y por
    qué? 🟠
14. ¿Qué dependencias pondrías en el readiness de `orders`, sabiendo que llama a `inventory` y a
    `payments`? Justifica cada una. 🟠
15. Un servicio de solo lectura que sirve una proyección: ¿le pones capa de dominio? 🟠
16. Tienes dos servicios y te proponen montar un chassis. ¿Qué respondes? 🟠
17. Alguien quiere meter en el chassis la validación de que el cliente está activo. Argumenta. 🟠
18. En Go tienes que escribir el apagado a mano y en Java es una propiedad. ¿Qué implicaciones
    prácticas tiene eso para un equipo políglota? 🟠
19. Tu tablero muestra un goteo constante de errores 502 que coincide con los despliegues. Da el
    diagnóstico y la corrección. 🟠
20. ¿Cómo evitas que el chassis se convierta en el monolito, en términos de gobierno y no de código?
    🟠
21. Diseña el contenido completo de un chassis para un equipo con servicios en Java y en Go,
    diciendo qué va en librería, qué en plantilla y qué se duplica a propósito. 🔴
22. Escribe la secuencia de apagado de un servicio que sirve HTTP y además consume de una cola, con
    el orden exacto de cierre y qué pasa si se invierte. 🔴
23. Diseña los health checks de `orders` —liveness, readiness y arranque— y di qué decisión de
    producto hay detrás de cada dependencia incluida o excluida. 🔴
24. Un equipo nuevo va a crear su primer servicio. Escribe la lista de comprobación de "listo para
    producción" que le darías, con no más de diez puntos, y justifica el orden. 🔴

---

**Anterior:** [`04` — El monolito distribuido](04-el-monolito-distribuido.md) · **Siguiente:**
[`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) · **Relacionado:**
[`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/) ·
[`05-plataformas`](../05-plataformas/)

**Talleres, opcionales:** [`06/01` — El monolito y su contrato](../06-talleres/01-el-monolito-y-su-contrato.md) · [`06/05` — Resiliencia en tres plataformas](../06-talleres/05-resiliencia-en-tres-plataformas.md).
