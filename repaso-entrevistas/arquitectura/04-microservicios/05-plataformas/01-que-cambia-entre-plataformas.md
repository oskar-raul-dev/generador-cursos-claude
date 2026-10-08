# 01 — Qué cambia entre plataformas

> Los ejes en los que Java, Node/TS, Go y Python difieren de verdad, los que casi nunca importan, la
> baseline de versiones del corpus y la tabla maestra de patrón × plataforma. Es el capítulo que
> ordena el bloque; los cinco siguientes lo desarrollan. Asume leídos los bloques
> [`02`](../02-comunicacion/), [`03`](../03-datos-y-consistencia/) y
> [`04`](../04-operacion-y-resiliencia/): **aquí no se explica ningún patrón**, se enlaza.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

"¿Qué plataforma usarías para este servicio?" es una pregunta de Tech Lead, y casi todas las
respuestas que se dan son malas por el mismo motivo: comparan lo que no decide.

```text
Lo que se discute          Lo que decide
─────────────────────────  ──────────────────────────────────────
velocidad del lenguaje     quién va a mantenerlo
sintaxis y elegancia       qué te da hecho el ecosistema PARA ESTE patrón
"es más moderno"           si sabes operarlo a las tres de la mañana
benchmarks de internet     cuánto cuesta el poliglotismo en tu organización
```

La columna de la izquierda es entretenida y no predice nada. La de la derecha es la que aparece en
las retrospectivas dos años después.

Este capítulo son los ejes que sí importan, con una advertencia de partida: en un servicio típico, el
**95 % del tiempo es espera** —red, base de datos, otro servicio—, así que el lenguaje casi no
aparece en la cuenta de latencia. Donde sí aparece es en el consumo de recursos, en el arranque y,
sobre todo, en cuánto código tienes que escribir para conseguir lo mismo.

---

## 2. 🧱 Baseline de versiones del corpus

**Qué es.** Los valores contra los que se escribió todo el bloque. Se declaran aquí, con fecha, y
ningún otro capítulo fija versiones menores (§5.4 de la guía).

| Plataforma | Baseline | Nota |
|---|---|---|
| **Java** | **25 LTS** | 21 LTS sigue siendo muy común en producción; los ejemplos funcionan en ambas salvo donde se indique |
| **Spring Boot** | **4.1** | 📝 La línea 3.5 salió del soporte gratuito a mediados de 2026. Mucho código en producción sigue ahí, y conviene saberlo |
| **Node** | **24 LTS** | La 26 pasa a LTS a finales de octubre de 2026 |
| **Go** | **1.27** | El proyecto mantiene las dos últimas versiones |
| **Python** | **3.14** | 3.13 sigue soportada y es lo más habitual en producción |

**Cómo se verifica.** Las fechas de soporte de todas ellas se consultan en un mismo sitio y se
comprueban antes de citarlas: [endoflife.date](https://endoflife.date/). Es de las pocas
comprobaciones que conviene rehacer cada vez que se retoma el corpus.

> **📝 Contexto:** el dato que más descoloca en una entrevista de 2026 es el de Spring Boot: mucha
> gente aprendió sobre la línea 3.x y la referencia actual es la 4.x. Saber en qué línea está el
> equipo que te entrevista, y por qué, dice más que recitar novedades.

---

## 3. ⚖️ Los siete ejes que sí importan

| Eje | Qué cambia de verdad | Dónde se nota |
|---|---|---|
| **Modelo de concurrencia** | Hilos, bucle de eventos, goroutines, corrutinas con bloqueo global | Cómo se escribe cada llamada concurrente, y qué la tumba |
| **Propagación de contexto** | Atado al hilo, `AsyncLocalStorage`, `context.Context`, `contextvars` | Dónde se pierde la traza ([`04/04`](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md)) |
| **Arranque y memoria** | De casi instantáneo a segundos; de decenas a cientos de megas | Escalado, reemplazos, capacidad de reserva |
| **Empaquetado** | Binario único, árbol de dependencias, dependencias nativas | Tamaño de imagen y reproducibilidad |
| **Madurez por patrón** | Qué te da hecho el ecosistema para **cada** patrón del corpus | Cuánto código escribes tú |
| **Tipado y contrato** | Qué se comprueba en compilación y qué en ejecución | Cuántos errores llegan a producción |
| **Contratación y rotación** | Cuánta gente hay, y cuánto tarda alguien nuevo en producir | Todo lo anterior, a dos años vista |

Y los dos que casi nunca importan, dicho sin rodeos:

- **La velocidad bruta del lenguaje.** Con el 95 % del tiempo en espera, la diferencia se diluye. Solo
  aparece en servicios con trabajo de CPU real: codificación, compresión, cálculo intensivo.
- **La sintaxis.** Es lo primero que se discute y lo último que decide nada.

> **🧠 Modelo mental:** la pregunta útil no es "¿qué plataforma es mejor?", es **"¿qué me da hecho
> esta plataforma para el patrón que necesito, y qué me deja a mí?"**. Todo este bloque es la
> respuesta a esa pregunta, patrón por patrón.

---

## 4. ⚖️ Modelo de concurrencia, comparado

Es el eje que más cambia cómo se escribe el código, y el que produce los fallos más característicos
de cada plataforma.

| Plataforma | Modelo | Qué lo tumba | Coste por conexión ociosa |
|---|---|---|---|
| **Java** | Hilo por petición; **hilos virtuales** hacen barato bloquear; modelo reactivo si se quiere | Agotar el pool con dependencias lentas | Un hilo de plataforma, o casi nada con virtuales |
| **Node/TS** | Un hilo, bucle de eventos | **Cualquier trabajo de CPU** en el hilo principal congela todo | Casi nada |
| **Go** | Goroutines baratas, planificadas por el runtime | Fugas de goroutines que nadie cancela | Casi nada |
| **Python** | `asyncio` sobre ASGI, o procesos con WSGI | Una llamada **bloqueante** dentro de código asíncrono | Casi nada en asíncrono; un proceso en el modelo clásico |

Lo interesante es que los cuatro fallos son **distintos**:

```text
Java     se agota un recurso finito (pool)     → degradación, luego caída
Node     se bloquea el único hilo              → congelación total e inmediata
Go       se acumulan goroutines sin cancelar   → fuga de memoria, muerte lenta
Python   se bloquea el bucle de eventos        → como Node, si se mezcla mal
```

📝 Y el cambio más relevante de los últimos años: con hilos virtuales, el argumento de "bloquear es
caro" deja de aplicarse en Java, lo que devuelve valor al estilo bloqueante y cambia la
recomendación sobre programación reactiva que mucha gente aprendió hace cinco años.

---

## 5. ⚖️ Arranque, memoria y empaquetado

Los números concretos dependen del servicio, así que lo que se compara son **órdenes de magnitud y
sus consecuencias operativas**, no cifras de benchmark ([§2 de la guía](../prompts/guia-de-estilo-y-convenciones.md)).

| Plataforma | Arranque | Memoria en reposo | Imagen | Consecuencia operativa |
|---|---|---|---|---|
| **Java** | Segundos; con compilación nativa, muy por debajo | La más alta, y muy configurable | Grande salvo que se recorte | Escalado reactivo llega tarde: hay que mantener reserva |
| **Node/TS** | Rápido | Moderada | Media; la marca el árbol de dependencias | Escala bien ante picos |
| **Go** | Casi inmediato | Baja | **Pequeña**: un binario | El mejor perfil para escalar y para agentes |
| **Python** | Rápido | Moderada | Media-grande con dependencias nativas | Reproducibilidad más delicada |

La consecuencia que conviene saber expresar: **el arranque no es estética, es dinero**. Instancias que
tardan en levantar obligan a mantener capacidad de reserva, porque el escalado automático no llega a
tiempo al pico. Ese coste suele ser mayor que la diferencia de consumo entre plataformas.

---

## 6. 🧰 La tabla maestra: patrón × plataforma

El corazón del bloque. Para cada patrón del corpus, **quién te lo da hecho y quién te lo deja
cablear**. Cada fila enlaza a su capítulo dueño, que es donde está explicado.

| Patrón | Java | Node/TS | Go | Python |
|---|---|---|---|---|
| [Cliente HTTP con timeouts](../02-comunicacion/02-http-entre-servicios.md) | Hecho, pero hay que poner los plazos | Hecho; falta un plazo total propio | A mano y explícito | Hecho; sin plazo por defecto |
| [gRPC](../02-comunicacion/03-grpc.md) | Muy integrado | Correcto, con alternativas mejores en tipos | **Ciudadano de primera** | Correcto; decidir sync o async |
| [WebSocket / SSE](../02-comunicacion/05-tiempo-real-websockets-y-sse.md) | Completo, con dos modelos | **Su terreno natural** | Natural, a mano | Completo en ASGI |
| [Mensajería](../02-comunicacion/06-mensajeria-y-eventos.md) | Muy hecho: escucha declarativa, DLQ | Clientes maduros y colas sobre Redis | Enrutado con reintentos | Colas de tareas veteranas |
| [Contratos](../02-comunicacion/07-contratos-y-versionado.md) | Generación y pactos integrados | Generación de tipos; validación en el borde obligatoria | Generación desde `.proto` idiomática | Validación declarativa fuerte |
| [Acceso a datos](../03-datos-y-consistencia/01-base-de-datos-por-servicio.md) | Maduro, con migraciones integradas | Clientes tipados que generan acceso | SQL explícito y generación tipada | Mapeo maduro con migraciones |
| [Saga](../03-datos-y-consistencia/03-saga.md) | El ecosistema más rico, incluido BPM | A mano, o motor de workflow | A mano, o motor | Colas de tareas, o motor |
| [Outbox](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md) | Módulos que lo implementan | **A mano** | Componentes que lo incluyen | A mano sobre el ORM |
| [Resiliencia](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md) | Librería completa y declarativa | Circuit breaker suelto; el resto se compone | A mano, explícito | Decoradores maduros |
| [Observabilidad](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md) | Agente automático muy completo | Automática en los marcos habituales | Manual y explícita | Automática en los marcos habituales |
| [Testing](../04-operacion-y-resiliencia/07-testing-de-microservicios.md) | El ecosistema más completo | Rápido, con buenos simuladores | Librería estándar y dobles a mano | Ejecutor expresivo y accesorios |

**Cómo se lee esta tabla, que es lo que importa:**

- **"Hecho" no es siempre mejor.** Lo hecho esconde comportamiento —el proxy de una anotación, la
  confirmación automática de un consumidor— y cuando falla hay que entenderlo igual.
- **"A mano" no es siempre peor.** En Go, escribir el circuit breaker son treinta líneas que se leen,
  se prueban y no sorprenden.
- **La fila que más separa a las plataformas es el outbox**, y no por casualidad: es el patrón donde
  el ecosistema de Java lleva más ventaja y donde más código propio hay que escribir en los demás.

> **🧰 Plataforma:** esta tabla es la respuesta a "¿qué cuesta este patrón en mi plataforma?". Y la
> lectura agregada es el argumento de [`06`](06-la-matriz-de-decision.md): cuantas más plataformas
> tengas, más veces pagas la columna de la derecha.

---

## 7. 🧭 Cómo se compara con honestidad

Si en una entrevista hay que comparar rendimiento o consumo, así se hace sin quedar mal:

```text
1. Mismo caso real, no un "hola mundo": con base de datos y con red de por medio.
2. Mismo perfil de carga que el sistema real: concurrencia, tamaño de mensajes.
3. Se dice qué NO se midió: arranque en frío, coste de operación, tiempo de desarrollo.
4. Se dan órdenes de magnitud y rangos, no cifras exactas de una sola ejecución.
5. Se nombra la configuración: memoria asignada, versión, modo de ejecución.
```

Y la frase que sirve para cerrar cualquier discusión de benchmarks:

> "Los números que circulan miden servidores vacíos, donde serializar es el 100 % del trabajo. En un
> servicio real con base de datos, esa diferencia se diluye. Lo que sí cambia de verdad entre
> plataformas es el arranque, la memoria y cuánto código tengo que escribir para el mismo patrón."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Go es más rápido, entonces es mejor para microservicios" | Es mejor en arranque, memoria y tamaño de imagen. En latencia de un servicio con base de datos, la diferencia se diluye |
| "Java consume mucha memoria" | Consume más, y es configurable. El dato sin versión ni configuración no significa nada |
| "Python no sirve para producción" | Sirve, y hay sistemas enormes en producción. Lo que hay que conocer es su modelo de ejecución y su empaquetado |
| "Con TypeScript tienes seguridad de tipos en ejecución" | Los tipos desaparecen al compilar. Sin validación en el borde, no hay ninguna comprobación |
| "Reactivo escala mejor" | Escalaba mejor cuando bloquear era caro. Con hilos virtuales, esa ventaja se reduce mucho |
| "Elegimos el mejor lenguaje para cada problema" | Cada plataforma nueva son herramientas, chassis, observabilidad y guardias duplicadas ([`06`](06-la-matriz-de-decision.md)) |
| "El benchmark dice que X es 7 veces más rápido" | Dice que su serializador lo es. Pregunta qué medía y qué no medía |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 2, sobre la
   libertad de stack y su precio real. **El tratamiento más honesto del poliglotismo.**
2. **Libro** — Nicole Forsgren, Jez Humble y Gene Kim, *Accelerate*, IT Revolution, 2018. Para el
   argumento de que la capacidad de entrega depende más de las prácticas que de la tecnología.
3. **Referencia** — endoflife.date, para comprobar versiones y fechas de soporte antes de citarlas:
   [endoflife.date](https://endoflife.date/).
4. **Documentación** — OpenTelemetry, estado de la instrumentación por lenguaje, que es una buena
   medida de madurez comparada:
   [opentelemetry.io/docs/languages/](https://opentelemetry.io/docs/languages/).
5. **Documentación** — gRPC, soporte por lenguaje, útil para el eje de madurez del §6:
   [grpc.io/docs/languages/](https://grpc.io/docs/languages/).
6. **Charla** — GOTO Conferences, «Polyglot Programming: The Good, the Bad and the Ugly». Es la
   contraparte honesta del entusiasmo por la libertad de stack.

---

## 🧠 Preguntas

1. Nombra cuatro de los siete ejes que diferencian plataformas de verdad. 🟢
2. ¿Qué dos ejes casi nunca importan, y por qué? 🟢
3. ¿Cuál es la baseline de versiones del corpus? 🟢
4. ¿Qué mecanismo de propagación de contexto tiene cada plataforma? 🟢
5. ¿Qué tumba a cada una de las cuatro, en términos de concurrencia? 🟢
6. ¿Por qué el arranque es una propiedad económica? 🟢
7. ¿Por qué el 95 % del tiempo de un servicio típico hace irrelevante la velocidad del lenguaje? 🟡
8. ¿Por qué "hecho" no es siempre mejor que "a mano"? 🟡
9. ¿Qué cambió con los hilos virtuales en el argumento sobre programación reactiva? 🟡
10. ¿Por qué el outbox es la fila que más separa a las plataformas? 🟡
11. ¿Por qué un `interface` de TypeScript no da seguridad en ejecución? 🟡
12. ¿Qué preguntas harías ante un benchmark que compara dos plataformas? 🟡
13. ¿Cómo explicarías la tabla maestra a alguien que solo ha trabajado en una plataforma? 🟡
14. Te piden elegir plataforma para un servicio de alta concurrencia y poca CPU. ¿Qué preguntas
    antes de responder? 🟠
15. ¿Cómo compararías dos plataformas para tu caso, con honestidad? 🟠
16. ¿Qué implica para el escalado que una plataforma arranque en segundos? 🟠
17. ¿Qué eje elegirías como decisivo para un servicio de datos con mucho cálculo? 🟠
18. Tu equipo quiere migrar un servicio a otra plataforma por rendimiento. ¿Qué mides antes? 🟠
19. ¿Qué dirías de Spring Boot 3.5 en una entrevista en 2026? 🟠
20. ¿Qué eje suele decidir de verdad a dos años vista, y por qué? 🟠
21. Diseña la comparativa que presentarías para decidir la plataforma de un servicio nuevo, con los
    criterios ponderados y los datos que pedirías. 🟠
22. Toma tres patrones del corpus y explica cómo cambia su implementación en las cuatro plataformas,
    sin repetir lo que dicen sus capítulos. 🔴
23. Escribe la respuesta de dos minutos a "¿qué plataforma elegirías para nuestro sistema?" cuando
    no conoces el sistema. 🔴
24. Un candidato afirma que Go es siempre mejor para microservicios. Responde con lo que concedes y
    lo que rechazas. 🔴

---

**Anterior:** — · **Siguiente:** [`02` — Java](02-java.md) · **Relacionado:**
[`06` — La matriz de decisión](06-la-matriz-de-decision.md) ·
[`04-operacion-y-resiliencia/06`](../04-operacion-y-resiliencia/06-despliegue-y-entrega.md)
