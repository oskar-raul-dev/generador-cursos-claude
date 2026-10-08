# 05 — Python

> Qué cambia por su modelo de ejecución —ASGI frente a WSGI, el bloqueo global del intérprete—, qué
> trae el ecosistema para cada patrón, y dónde gana de verdad. Asume leído
> [`01`](01-que-cambia-entre-plataformas.md). **Aquí no se explica ningún patrón**: se dice qué te da
> la plataforma y se enlaza.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Python arrastra dos tópicos que conviene desmontar antes de nada, porque quien los repite sin matices
pierde puntos en una entrevista:

```text
"Python es lento"          → para trabajo de espera, da igual; para cómputo,
                              depende de si la librería libera el bloqueo global
"El GIL impide concurrencia" → impide paralelismo de CPU en hilos; no impide
                              concurrencia de espera, que es el 95 % de un servicio
```

Lo que sí hay que saber es más concreto y más útil: **hay dos modelos de ejecución conviviendo**
—síncrono por procesos y asíncrono sobre ASGI— y **mezclarlos mal es el fallo más caro de esta
plataforma**. Todo lo demás se deriva de ahí.

---

## 2. 🧱 WSGI y ASGI: dos modelos conviviendo

**Qué es.** WSGI es el modelo clásico síncrono: cada petición ocupa un trabajador —proceso o hilo—
mientras dura. ASGI es el modelo asíncrono: un bucle de eventos por proceso, como Node.

| | WSGI (síncrono) | ASGI (asíncrono) |
|---|---|---|
| **Concurrencia** | Por procesos y/o hilos | Bucle de eventos, más procesos |
| **Coste por petición en espera** | Un trabajador ocupado | Casi nada |
| **Bloquear** | Es lo normal | **Congela el bucle entero** |
| **Encaja con** | Servicios con cómputo, código existente | Muchas conexiones y espera |

**El fallo característico.** Una llamada bloqueante dentro de un manejador asíncrono: un cliente HTTP
síncrono, una consulta con un controlador que no es asíncrono, una lectura de fichero. El efecto es el
de Node: **no degrada, congela**, y afecta a todas las peticiones del proceso.

**La salida**: usar clientes asíncronos de punta a punta, o ejecutar explícitamente lo bloqueante en
un hilo aparte para no retener el bucle. Lo que no funciona es mezclar sin pensar.

> **⚠️ Advertencia:** el síntoma es desconcertante porque el código "funciona": responde bien con poca
> carga y se desploma con concurrencia, sin errores. Es el equivalente exacto del bloqueo del bucle de
> Node, con la diferencia de que aquí es más fácil colarlo, porque la mayoría de las librerías tienen
> versión síncrona.

---

## 3. 🧱 El bloqueo global del intérprete, con matices

**Qué es.** Un mecanismo que impide que dos hilos ejecuten código de Python a la vez dentro del mismo
proceso.

**Qué implica de verdad:**

| Caso | ¿Le afecta? |
|---|---|
| Esperar a red o a base de datos | **No**: el bloqueo se libera durante la espera |
| Cómputo puro en Python | **Sí**: los hilos no dan paralelismo real |
| Librerías numéricas y nativas | **No suele**: liberan el bloqueo durante el cálculo |
| Varios procesos | **No**: cada proceso tiene el suyo |

**La consecuencia práctica** para un servicio: como el 95 % del tiempo es espera, el bloqueo global
casi no aparece. Donde sí aparece es en cómputo en Python puro, y la salida clásica es repartir en
procesos —que es como se despliega igualmente— o usar librerías que lo liberan.

📝 Y el matiz que conviene mencionar en 2026: existe trabajo en curso para ofrecer un modo sin
bloqueo global, lo que cambiaría el argumento a medio plazo. Saber que existe —y que todavía no es lo
habitual en producción— demuestra que se sigue el tema sin exagerar su alcance.

> **💡 Truco:** la respuesta completa a "¿el GIL no es un problema?" es: *"para un servicio de espera,
> no; para cómputo en Python puro, sí, y se reparte en procesos; y para cálculo numérico, las
> librerías lo liberan"*. Con los tres casos, la pregunta queda contestada.

---

## 4. ⚖️ FastAPI, Django y Flask

| | FastAPI | Django | Flask |
|---|---|---|---|
| **Modelo** | ASGI, asíncrono de origen | Completo, con soporte asíncrono añadido | Mínimo, síncrono; hay variantes |
| **Qué trae** | Validación por esquemas, documentación generada del código | Todo: ORM, admin, autenticación, migraciones | Casi nada, por diseño |
| **Encaja con** | APIs y servicios; el caso por defecto hoy | Productos con mucho CRUD y panel de administración | Servicios pequeños y código existente |
| **Coste** | Ecosistema asíncrono aún desigual | Pesado para un microservicio; modelo síncrono de origen | Todo lo transversal lo pones tú |

**Para microservicios, FastAPI es el caso por defecto**: es ASGI, la validación con esquemas cubre el
borde ([`02-comunicacion/07`](../02-comunicacion/07-contratos-y-versionado.md)) y la documentación
sale del propio código. Django encaja mejor en productos completos que en servicios pequeños, y Flask
sobrevive sobre todo donde ya está.

**La validación con esquemas merece mención aparte**: es de lo mejor que tiene esta plataforma frente
a las otras tres. El mismo modelo valida la entrada, documenta el contrato y da tipos en el editor, y
lo hace **en ejecución**, que es justo lo que le falta a TypeScript.

---

## 5. 🧰 Qué te da esta plataforma para cada patrón

| Patrón | Qué te da | Lo que te deja a ti |
|---|---|---|
| [Cliente HTTP](../02-comunicacion/02-http-entre-servicios.md) | Clientes síncrono y asíncrono con API casi idéntica | El plazo: el cliente clásico **no** aplica timeout por defecto |
| [gRPC](../02-comunicacion/03-grpc.md) | Generación con su propio compilador; API síncrona y asíncrona | Elegir una y no mezclarlas |
| [Mensajería](../02-comunicacion/06-mensajeria-y-eventos.md) | **Colas de tareas veteranas**: reintentos, planificación, resultados | La idempotencia, y que el estado del flujo no quede implícito en la cola |
| [Contratos](../02-comunicacion/07-contratos-y-versionado.md) | **Validación declarativa fuerte** en ejecución, con esquema generado | Que el esquema del código no se convierta en la fuente de verdad del contrato |
| [Acceso a datos](../03-datos-y-consistencia/01-base-de-datos-por-servicio.md) | Mapeo maduro y migraciones con generación de diferencias | **Revisar la migración generada**: los renombrados salen como borrar y crear |
| [Outbox](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md) | Nada integrado: se escribe sobre el ORM | Que la tarea de publicación no se solape consigo misma |
| [Resiliencia](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md) | Decoradores de reintento muy maduros; circuit breaker como decorador | Que decoradores y modelo asíncrono convivan; estado por proceso trabajador |
| [Observabilidad](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md) | Instrumentación automática de los marcos habituales | Que el contexto no se pierda entre hilos y procesos |
| [Testing](../04-operacion-y-resiliencia/07-testing-de-microservicios.md) | Ejecutor muy expresivo con accesorios reutilizables | Que los accesorios no se vuelvan un sistema paralelo ilegible |

**La lectura agregada**: fuerte en validación, en tareas en segundo plano y en todo lo que toque
datos; más débil en la mecánica transaccional y en uniformidad del modelo de ejecución.

---

## 6. 🔭 Dónde gana de verdad

- **Servicios de datos y de modelos.** Todo el ecosistema está aquí, y reescribirlo en otra
  plataforma significa perderlo. Es el argumento de poliglotismo más claro después del BFF.
- **Trabajo en segundo plano y planificado.** Las colas de tareas llevan más de una década resolviendo
  reintentos, planificación y resultados; es un patrón que Python resolvió antes que nadie.
- **Servicios que ya viven en Python.** El coste de migrar rara vez se paga si el servicio funciona.
- **Prototipado y herramientas internas.** Donde la velocidad de escritura manda sobre todo lo demás.

**Dónde cuesta defenderlo**: servicios de dominio con mucha mecánica transaccional y equipos que
vienen de marcos con más cosas resueltas. Y en despliegue, cuando las dependencias nativas complican
la imagen y la reproducibilidad.

---

## 7. 🧱 Empaquetado: el punto débil menos discutido

**Qué es.** Construir una imagen reproducible con dependencias que a veces incluyen código nativo
compilado.

**Por qué importa.** Es donde esta plataforma da más trabajo comparada con las otras tres: el árbol de
dependencias puede necesitar compilación, el tamaño de la imagen crece, y reproducir exactamente el
mismo entorno exige disciplina con el bloqueo de versiones.

**Qué hacer**: fijar versiones exactas con un fichero de bloqueo, construir en varias etapas para no
arrastrar herramientas de compilación, y elegir la imagen base con cuidado —las bases minimalistas
suelen obligar a compilar lo que en otras viene precompilado—.

> **Veredicto:** el empaquetado no cambia la decisión de plataforma por sí solo, pero es la diferencia
> entre un pipeline que tarda dos minutos y uno que tarda quince. Merece decidirse al empezar, no
> cuando el pipeline ya molesta.

---

## 8. 🧭 Cómo se elige dentro del ecosistema

```text
¿Qué tipo de servicio es?
│
├─ API o microservicio ──────► FastAPI sobre ASGI, con validación por esquemas
│
├─ producto con CRUD, panel
│   y usuarios ──────────────► Django, y asumir que no es un microservicio pequeño
│
├─ trabajo en segundo plano
│   o planificado ───────────► cola de tareas madura + un servicio ASGI delante
│
└─ código existente en Flask ► mantenerlo; migrar solo con un motivo concreto
```

Y la frase:

> "FastAPI para servicios, por el modelo asíncrono y por la validación en ejecución, que es lo que le
> falta a TypeScript. Django cuando es un producto con panel, no un microservicio. Y lo importante no
> es el marco: es no mezclar código bloqueante dentro del modelo asíncrono."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Python es lento y por eso no se usa en backend serio" | Para trabajo de espera da igual. Hay sistemas enormes en producción; lo que hay que conocer es su modelo de ejecución |
| "El GIL impide la concurrencia" | Impide el paralelismo de CPU en hilos. La concurrencia de espera funciona perfectamente, y es el 95 % de un servicio |
| "FastAPI es asíncrono, entonces todo el código es asíncrono" | Solo si lo escribes así. Una llamada bloqueante dentro congela el bucle entero |
| "Pydantic valida en tiempo de compilación" | Valida **en ejecución**, y eso es justamente su ventaja frente a los tipos que desaparecen |
| "Los hilos resuelven el problema del GIL" | Para espera sí, para cómputo no. El paralelismo de CPU se consigue con procesos |
| "La migración la genera la herramienta, está bien" | Los renombrados se generan como borrar y crear. Toda migración generada se revisa |
| "El cliente HTTP ya trae timeout" | El cliente clásico no aplica timeout por defecto: hay que ponerlo |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 2, para situar
   la elección de plataforma y el coste del poliglotismo.
2. **Documentación** — FastAPI, guía de usuario, incluido el tratamiento de código síncrono dentro de
   manejadores asíncronos: [fastapi.tiangolo.com](https://fastapi.tiangolo.com/).
3. **Documentación** — ASGI, la especificación del modelo asíncrono de §2:
   [asgi.readthedocs.io](https://asgi.readthedocs.io/en/latest/).
4. **Documentación** — Pydantic, validación y generación de esquemas, base de §4:
   [docs.pydantic.dev](https://docs.pydantic.dev/latest/).
5. **Documentación** — Celery, la cola de tareas de referencia del ecosistema:
   [docs.celeryq.dev](https://docs.celeryq.dev/en/stable/).
6. **Fuente primaria** — PEP 703, sobre hacer opcional el bloqueo global del intérprete, para el
   apunte 📝 de §3: [peps.python.org/pep-0703](https://peps.python.org/pep-0703/).
7. **Documentación** — OpenTelemetry para Python, instrumentación automática y manual:
   [opentelemetry.io/docs/languages/python/](https://opentelemetry.io/docs/languages/python/).
8. **Charla** — PyCon, «Async Python: The Good, the Bad and the Ugly». Es donde mejor se explican los
   fallos de mezclar modelos de §2.

---

## 🧠 Preguntas

1. ¿Qué diferencia hay entre WSGI y ASGI? 🟢
2. ¿Qué impide y qué no impide el bloqueo global del intérprete? 🟢
3. ¿Cuál es el fallo característico de un servicio asíncrono en Python? 🟢
4. ¿Qué aporta la validación por esquemas frente a los tipos de TypeScript? 🟢
5. ¿Para qué tipo de servicio es FastAPI el caso por defecto? 🟢
6. Nombra dos casos donde Python gana de verdad. 🟢
7. ¿Por qué hay que revisar siempre las migraciones generadas? 🟢
8. ¿Por qué el bloqueo global casi no afecta a un servicio de espera? 🟡
9. ¿Por qué las librerías numéricas escapan al bloqueo global? 🟡
10. ¿Por qué mezclar código bloqueante en un manejador asíncrono es tan difícil de detectar? 🟡
11. ¿Por qué el estado de un circuit breaker se multiplica en esta plataforma? 🟡
12. ¿Por qué el empaquetado es el punto débil menos discutido? 🟡
13. Te dicen que Python no sirve para un servicio con mucho tráfico. Responde. 🟡
14. Tu servicio responde bien con poca carga y se desploma con concurrencia, sin errores.
    Diagnostica. 🟠
15. ¿Cómo ejecutarías una operación bloqueante inevitable dentro de un servicio asíncrono? 🟠
16. ¿Cómo implementarías el outbox aquí y qué vigilarías? 🟠
17. ¿Cuándo elegirías Django para un servicio, y cuándo sería un error? 🟠
18. ¿Qué revisarías en el empaquetado de un servicio de Python antes de producción? 🟠
19. ¿Cómo garantizarías que el contrato es la fuente de verdad y no el modelo del código? 🟠
20. ¿Qué servicios de tu sistema dejarías en Python y cuáles no? 🟠
21. Diseña el chassis de Python del equipo: qué trae, qué obliga y qué prohíbe. 🔴
22. Diseña un servicio de datos que expone API y ejecuta trabajo pesado en segundo plano, con su
    modelo de ejecución y su despliegue. 🔴
23. Diagnostica: un servicio con cuatro procesos trabajadores muestra comportamiento inconsistente
    de su circuit breaker y de su caché. Explica y corrige. 🔴
24. Un equipo quiere escribir el servicio de pedidos en Python porque es lo que domina. Responde con
    lo que concedes y lo que adviertes. 🔴

---

**Anterior:** [`04` — Go](04-go.md) · **Siguiente:**
[`06` — La matriz de decisión](06-la-matriz-de-decision.md) · **Relacionado:**
[`02-comunicacion/06`](../02-comunicacion/06-mensajeria-y-eventos.md) ·
[`03-datos-y-consistencia/04`](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md)
