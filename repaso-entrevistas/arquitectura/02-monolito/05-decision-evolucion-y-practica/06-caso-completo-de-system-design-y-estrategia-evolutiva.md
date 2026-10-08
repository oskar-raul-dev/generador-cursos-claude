# 06 — Caso completo de system design y estrategia evolutiva

Aprenderás a conducir una entrevista de diseño desde los requisitos hasta un sistema operable y un
roadmap revisable, usando todo lo anterior: qué preguntar antes de dibujar, qué topología proponer,
cómo recorrer `CreateOrder` con sus fallos y cómo cerrar con lo que harías primero y lo que te haría
cambiar de idea. Los números son supuestos del ejercicio, no mediciones de un sistema real.

## 1. 🎯 Síntoma y decisión

La consigna llega en una frase: «Diseña la plataforma de pedidos de una tienda online. Tienes 45
minutos». El error habitual es empezar a dibujar cajas —gateway, cuatro servicios, Kafka, una base por
servicio— en el minuto dos, y descubrir en el treinta que el negocio no admite pagos pendientes o que
todo el tráfico cabe en tres réplicas. El entrevistador no evalúa cuántas tecnologías conoces, sino si
conectas requisito, garantía, mecanismo, fallo y evidencia.

La decisión de este capítulo es cómo usar esos 45 minutos: qué aclarar, qué proponer, qué recorrer
en detalle y cómo cerrar.

## 2. 🧠 Modelo mental

Una respuesta senior recorre la misma cadena en cada tramo del diseño y la hace explícita en voz alta:

```text
requisito  →  garantía  →  mecanismo  →  fallo  →  evidencia
«no vender   un pedido     reserva en la   dos réplicas   prueba con
 sin stock»  confirmado    misma           reservan el    concurrencia real
             tiene su      transacción     último SKU     contra la base
             reserva       que el pedido
```

La conversación tiene cuatro fases: **aclarar** (requisitos y cifras), **proponer** (topología y flujo
principal), **estresar** (capacidad, fallos, operación) y **cerrar** (roadmap, alternativa y qué dato
cambiaría la decisión). Saltarse la primera produce un diseño para un problema que nadie planteó.

## 3. 🔍 Evidencia antes del diagnóstico

Antes de dibujar se pregunta qué significa confirmar una compra, si se permite esperar el pago,
cuánto dura una reserva, qué picos existen, qué pérdida es aceptable y quién opera el sistema. Con las
respuestas del ejercicio:

| Nivel | En el sistema de comercio |
|---|---|
| Observación | un equipo capaz de mantener un producto; 100 compras/s en pico y 10 lecturas por compra; el negocio admite estado pendiente de pago, exige no sobrevender y no autorizar dos veces la misma intención; proveedor de pagos externo |
| Inferencia | la carga cabe en réplicas de un artefacto; pedido y reserva forman una invariante local; el pago es un efecto externo con resultado incierto |
| Diagnóstico | ninguna restricción pide varios procesos hoy; las garantías críticas son locales salvo el pago |
| Recomendación | monolito modular replicado, base con dueño por módulo, trabajo durable para pago y avisos, y revisión con fecha si aparecen equipos o aislamientos que lo cambien |

El SLO ilustrativo separa aceptación de completitud: el 99,9 % de las solicitudes de creación válidas
recibe identificación durable o rechazo de negocio en un segundo; y, aparte, el 99 % de los pedidos
admitidos alcanza estado terminal en cinco minutos con el proveedor funcionando normalmente.
Responder rápido con un pendiente no demuestra completar compras. Qué refutaría la recomendación: si
el entrevistador añade que pagos debe aislarse por regulación, o que hay tres equipos con cadencias
distintas, la [matriz](01-monolito-monolito-modular-o-servicios-matriz-de-decision.md) se reabre en voz
alta.

## 4. 🛠️ De la topología a los fallos

**La topología.** Réplicas del mismo artefacto, módulos con dueño y una base con propiedad por
módulo:

```text
cliente → balanceo → réplicas del mismo artefacto
                       ├─ orders → inventory (API local, misma transacción)
                       ├─ payments → proveedor externo (worker, clave estable)
                       └─ notifications → canal externo (worker)
                              │
                     base con ownership por módulo
                     + trabajo durable y estados
```

Las flechas indican flujo de ejecución; la conexión transaccional compartida se usa solo donde la
garantía lo pide. Las réplicas no guardan sesión exclusiva ni ejecutan jobs sin coordinación en
memoria.

**`CreateOrder` de principio a fin.**

1. Valida la entrada y la identidad de la intención: la misma clave con otra solicitud es un conflicto.
2. En una transacción local crea el pedido pendiente, la reserva a través de `inventory` y el trabajo
   durable para `payments`. Sin stock, no confirma escrituras parciales.
3. Devuelve una identidad consultable tras el commit: el cliente no debe crear otra intención por una
   respuesta perdida.
4. Un worker reclama el trabajo y autoriza con clave estable; persiste el resultado o el pendiente
   incierto y reconcilia.
5. `orders` confirma solo con reserva válida y autorización suficiente. Si la reserva vence, la renueva
   bajo las reglas de `inventory` o compensa el pago según la política.
6. Persiste el aviso para `notifications`: su caída retrasa la comunicación, no vuelve falsa una
   compra confirmada.

El [diseño modular](02-disenar-un-monolito-modular-desde-cero.md) define las APIs y los
[fallos parciales](../04-monolito-distribuido/05-fallos-parciales-retries-y-falsas-transacciones.md)
gobiernan el tramo externo.

**Capacidad.** Con los supuestos, el pico de lecturas es de 1.000/s. Si el tramo local tarda de
media 0,1 s, la ley de Little sugiere unas diez creaciones simultáneas a 100/s en régimen estable; no
determina conexiones, p99 ni recursos, pero dice que el orden de magnitud es modesto. Lo que hay que
ensayar es la distribución: un SKU caliente puede serializar reservas aunque la CPU esté libre. Una
caché de catálogo sirve lecturas con frescura acordada; la autorización del stock ocurre siempre en la
base del propietario. Más réplicas aumentan conexiones y competencia, así que no garantizan más
throughput.

**Fallos y su evidencia.**

| Fallo | Conducta esperada | Evidencia de recuperación |
|---|---|---|
| caída antes del commit | no hay pedido aceptado | reintento con la misma identidad |
| respuesta perdida tras el commit | se consulta la misma operación | un pedido y una reserva |
| proveedor lento o resultado desconocido | pendiente durable | consulta, antigüedad y reconciliación |
| dos workers reciben el mismo trabajo | efecto controlado por identidad | prueba concurrente e inbox donde aplique |
| cola de avisos saturada | compra disponible, aviso retrasado | *backpressure* y alerta por edad |
| código viejo y nuevo conviven | datos compatibles | ensayo de expand-contract y rollback |

Se mide el SLO del flujo, la saturación y la antigüedad de los estados; se correlacionan pedido,
operación y evento; se prueban módulo, base y fallos con la
[estrategia por riesgo](../03-datos-ejecucion-y-operacion/07-estrategia-de-pruebas-y-evidencia-de-modularidad.md),
y se ensaya la restauración: un backup que existe no demuestra recuperación.

## 5. 🧰 Plataformas

Diseño neutral: no hace falta escribir cuatro versiones del mismo código en una entrevista de
diseño. Lo que cambia entre plataformas —build, contexto transaccional, modelo de concurrencia— se
verifica al implementar con los capítulos enlazados. Si el entrevistador pregunta por un lenguaje, la
respuesta útil es dónde vive la transacción, cómo se propaga el deadline y cómo se limita la
concurrencia del worker en esa plataforma; ningún lenguaje cambia que el proveedor externo es dueño de
su efecto.

## 6. ⚖️ Alternativa, roadmap y cierre

**El roadmap, con condiciones para continuar:**

| Momento del ejercicio | Entrega y responsable | Condición para continuar |
|---|---|---|
| Semana 1 | `orders`/`inventory`: flujo local y pruebas de concurrencia | invariantes verificadas |
| Semana 2 | `payments`: estado durable y ensayo de respuesta perdida | una intención, resultado trazable |
| Semana 3 | operación: pico, migración compatible y restauración | SLO y recuperación demostrados |
| Semana 4 | responsable técnico y producto: decidir la siguiente inversión | evidencia de cuello o de coordinación real |

**La alternativa distribuida** extrae una sola capacidad si compra aislamiento o cadencia, con
[migración y cancelación](04-extraer-un-modulo-a-servicio.md), y paga contratos remotos y guardia
propia. No son objetivos iniciales las múltiples regiones, un event store global ni una plataforma
interna general sin requisito que los pida.

**El cierre** dice tres cosas: qué construirías primero, qué pospones a propósito y qué dato
cambiaría la decisión. Si faltan cifras, se declaran los supuestos, se propone lo más reversible y se
nombra la medición que confirmaría o refutaría la propuesta.

## ⚠️ Errores frecuentes

- «Primero dibujo la arquitectura y luego pregunto». Sin aclarar qué se confirma y cuándo, el diseño
  resuelve un problema que nadie planteó.
- «Respondemos en un segundo, así que cumplimos el SLO». Aceptar rápido con un pendiente no mide
  completitud; hace falta un segundo objetivo.
- «Un millón de usuarios exige muchas conexiones». Las conexiones se dimensionan con operaciones
  concurrentes y tiempo de uso, no con usuarios registrados.
- «Diseño desde el principio para todas las topologías futuras». Sin fecha ni señal de revisión, es
  sobrediseño que retrasa lo que sí se necesita.
- «El proveedor de pagos es parte de mi transacción». Es otro sistema con su propio efecto; se modela
  con clave, pendiente y reconciliación.

## 7. ✅ Veredicto

Una respuesta senior conecta requisito, garantía, mecanismo, fallo y evidencia en cada tramo, y lo
dice en voz alta. Aclara antes de dibujar, propone lo más simple que cumple las garantías, recorre el
flujo crítico con sus fallos, dimensiona con órdenes de magnitud y cierra con lo que construirías
primero, lo que pospones y qué dato te haría cambiar de idea.

## 📚 Referencias

- [Handling Overload, Google SRE Book](https://sre.google/sre-book/handling-overload/)
- [Microservice Trade-Offs, Martin Fowler](https://martinfowler.com/articles/microservice-trade-offs.html)
- [Monolith First, Martin Fowler](https://martinfowler.com/bliki/MonolithFirst.html)

## 🧠 Preguntas

1. 🟢 ¿Qué aclaras antes de dibujar el sistema?
2. 🟢 ¿Qué diferencia hay entre aceptación y completitud en el SLO?
3. 🟢 ¿Qué representa la cifra de 100 compras por segundo y qué no dice?
4. 🟢 ¿Qué confirma la transacción local de `CreateOrder`?
5. 🟢 ¿Qué papel tiene `notifications` en el flujo y qué no puede decidir?
6. 🟡 ¿Cómo respondes a una respuesta perdida después del commit?
7. 🟡 ¿Por qué no confirmar el pedido en cuanto el proveedor autoriza?
8. 🟡 ¿Qué cambia al replicar el artefacto, y qué deja de poder vivir en memoria?
9. 🟡 ¿Qué te sugiere la ley de Little con 100 compras/s y 0,1 s, y qué no te dice?
10. 🟡 ¿Qué cuello puede ocultar una CPU baja en este diseño?
11. 🟡 ¿Dónde usarías caché sin comprometer el stock?
12. 🟡 ¿Qué observas en un pago pendiente para saber si el sistema va bien?
13. 🟡 ¿Qué prueba priorizas para dos workers que reciben el mismo trabajo?
14. 🟡 ¿Cómo despliegas una nueva representación del estado del pedido sin romper réplicas viejas?
15. 🟡 ¿Qué constituye una alternativa distribuida defendible en este caso?
16. 🟡 ¿Qué dejas explícitamente fuera del diseño inicial y por qué?
17. 🟠 ¿Cómo ajustas el roadmap si falla la prueba de concurrencia del stock en la semana 1?
18. 🟠 ¿Qué harías ante una cola de avisos que crece durante una campaña?
19. 🟠 ¿Cómo tratarías un proveedor de pagos caído durante horas?
20. 🟠 ¿Qué harías si el negocio prohíbe el estado pendiente de pago?
21. 🟠 ¿Cómo verificas que puedes recuperar el sistema desde un backup?
22. 🟠 A mitad de la entrevista aparecen tres equipos con cadencias distintas. ¿Qué cambias?
23. 🟠 ¿Cómo cierras la entrevista si faltan cifras?
24. 🟠 ¿Cuándo consideras terminado el roadmap propuesto?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [05 — Equipos, ownership y gobernanza evolutiva](05-equipos-ownership-y-gobernanza-evolutiva.md).

**Siguiente:** [07 — Simulación de entrevista: Decisión, evolución y práctica](07-simulacion-de-entrevista.md).
