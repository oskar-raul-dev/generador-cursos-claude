# 08 — Idempotencia, conciliación y auditoría

> El capítulo que cierra el bloque y explica cómo la banca lleva décadas viviendo con sistemas que
> fallan: partida doble, idempotencia con clave de negocio, conciliación como red de seguridad, y
> una pista de auditoría que no se puede alterar.
> Asume leídos [`02-eventos/03`](../02-eventos/03-garantias-orden-e-idempotencia.md) y
> [`01`](01-core-bancario-y-legado.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tu sistema ordenó 14.238 transferencias ayer. El core registró 14.237. Falta una, o sobra una, o hay
una duplicada y otra perdida que se compensan en el conteo.

Y esta es la parte importante: **eso va a pasar**. No es una hipótesis:

```text
Un timeout que no significaba fallo
Un reintento sobre una operación no idempotente
Un mensaje que se perdió entre la cola y el core
Un batch que se cayó a la mitad y se relanzó
Una transacción XA que quedó en duda
```

En un sistema distribuido con integraciones heredadas, la pregunta no es si habrá descuadres, sino
**cómo los detectas y en cuánto tiempo**.

> **Regla importante:** en banca la consistencia no la garantiza el transporte, la garantiza la
> **conciliación**. Todo lo demás reduce la frecuencia de los descuadres; la conciliación es lo que
> los encuentra.

---

## 2. 📖 Partida doble y el libro inmutable

**Qué es.** El mecanismo con el que la contabilidad resolvió la integridad hace seiscientos años, y
que sigue siendo la mejor respuesta.

```text
Todo movimiento genera al menos dos asientos: un cargo y un abono, por el mismo importe.
La suma de todos los cargos es igual a la suma de todos los abonos. SIEMPRE.
Si no cuadra, hay un error, y el sistema puede detectarlo solo.
```

- **Es una invariante verificable a posteriori**, y eso es lo que la hace poderosa: no depende de que
  ninguna transacción fuera correcta, se comprueba sobre el resultado.
- **El libro es inmutable**: no se borra ni se modifica un asiento. Un error se corrige con un
  **contra-asiento** que lo anula y un asiento nuevo correcto. Los tres quedan visibles.
- Es exactamente el modelo de [`02-eventos/07`](../02-eventos/07-event-sourcing.md): hechos
  inmutables, estado derivado. La banca hacía event sourcing antes de que existiera el término, y
  por eso es el dominio donde el patrón se descubre en vez de imponerse.

**Lo que implica para tu diseño:**

```text
El saldo es DERIVADO, no un contador que mutas.
    saldo = suma de movimientos, o un campo actualizado en la MISMA transacción que la inserción.
Un movimiento se inserta, nunca se actualiza ni se borra.
La corrección es un movimiento nuevo con signo contrario y referencia al original.
```

> **Veredicto:** modelar movimientos en vez de mutar contadores da idempotencia, auditoría y
> capacidad de conciliar, las tres a la vez. Es la decisión de diseño más rentable del bloque.

---

## 3. 🔑 Idempotencia con clave de negocio

**Qué es.** La aplicación bancaria de
[`02-eventos/03`](../02-eventos/03-garantias-orden-e-idempotencia.md), con un matiz propio: **la
clave no se inventa, viene dada**.

```text
Pago interbancario  → el identificador de extremo a extremo del mensaje (end-to-end ID)
Tarjeta             → el identificador de la transacción, que viaja en autorización y liquidación
Fichero de remesas  → identificador de la remesa + número de orden dentro de ella
Orden del cliente   → un identificador que TÚ generas al aceptarla, antes de hacer nada
```

- **Usar el identificador del estándar es lo correcto**, y evita el problema de correlacionar dos
  identificadores distintos cuando hay un descuadre.
- **El mecanismo es una restricción única**, no un `if`: `INSERT` del movimiento con la clave como
  índice único. Reintentar viola la restricción y no hace nada. Sin consulta previa, sin ventana de
  carrera.
- **Y tiene que ser atómico con el efecto**, en la misma transacción. Es la regla de
  [`02-eventos/03` §5](../02-eventos/03-garantias-orden-e-idempotencia.md) y en banca su
  incumplimiento produce descuadres que aparecen semanas después.

**El caso ambiguo, que es el que define el diseño:**

```text
Ordenaste al core y no llegó respuesta.
NO reintentes a ciegas. Tres opciones, en orden:
  1. Consultar el estado en el core por la clave de negocio.
  2. Si no se puede consultar: dejarlo en estado SIN RESPUESTA y que lo resuelva la conciliación.
  3. Nunca: reintentar y esperar que sea idempotente si no lo has verificado.
```

> **Veredicto:** la idempotencia bancaria no es una técnica añadida, es la forma del modelo: un
> movimiento con identificador único e inserción con restricción. Lo demás son parches sobre un
> modelo que mutaba contadores.

---

## 4. ⚖️ Conciliación

**Qué es.** Comparar dos registros de la misma realidad y encontrar las diferencias. Es el proceso
más característico de la banca y el que menos se enseña.

Los tipos que hay que distinguir:

```text
Interna     → tu sistema contra el core. ¿Ordené 14.238 y él registró 14.237?
Externa     → tu banco contra otro, contra la red de tarjetas, contra el proveedor.
De posición → el saldo derivado de los movimientos contra el saldo que dice el core.
Temporal    → el cierre de hoy contra el de ayer más los movimientos del día.
```

**Cómo funciona un proceso de conciliación:**

```text
1. Obtener ambos conjuntos para el mismo periodo. El corte temporal es CRÍTICO:
   si uno incluye las 23:59 y el otro no, todo el resto es ruido.
2. Casar por clave de negocio. No por importe y fecha: eso produce falsos emparejamientos.
3. Clasificar las diferencias:
     solo en el mío     → ordené y no se aplicó, o el corte difiere
     solo en el suyo    → se aplicó algo que yo no ordené, o llegó por otro canal
     en ambos, distinto → importe, divisa o fecha valor no coinciden
4. Resolver: automático cuando la regla es clara, manual cuando no.
5. Registrar TODO: qué se detectó, qué se resolvió y cómo. Es materia de auditoría.
```

- **El corte temporal es el origen del 80 % de los falsos positivos.** Dos sistemas con husos
  horarios distintos, o con fecha contable frente a fecha de operación, producen listas de
  diferencias que no son diferencias.
- **La conciliación debe ser automática y medida**: número de descuadres, tiempo hasta detectarlos,
  porcentaje resuelto automáticamente. Sin métricas, no se sabe si el sistema está empeorando.
- **Un descuadre que no cuadra en el plazo acordado escala.** En banca hay plazos regulatorios para
  resolver diferencias.

> 🧠 **Modelo mental.** La conciliación es a la banca lo que las fitness functions de
> [`01-bases/01`](../01-bases/01-fundamentos-del-arquitecto.md) son a la arquitectura: una
> verificación automática y periódica de una invariante que el sistema debería cumplir y que nadie
> puede garantizar por construcción.

> **Veredicto:** diseñar un sistema bancario sin conciliación es diseñar sin red. Y proponerla sin
> que nadie la pida es de las cosas que más señalan experiencia real en el sector.

---

## 5. 📜 La pista de auditoría

**Qué es.** El registro de qué pasó, quién lo ordenó y con qué autorización, conservado de forma que
no se pueda alterar.

Lo que tiene que contener, y viene de
[`04-seguridad/04`](../04-seguridad/04-propagacion-de-identidad.md):

```text
Qué operación        → tipo, importe, cuentas implicadas
Quién la ordenó      → identidad del usuario (sub), no del servicio
A través de qué      → el actor (act) y el canal: app, oficina, API de terceros
Cuándo               → marca de tiempo fiable, con huso declarado
Con qué autorización → qué política permitió la decisión, y si hubo aprobación de un segundo
Resultado            → aceptada, rechazada y por qué
```

**Las propiedades que la distinguen de los logs de aplicación:**

- **Inmutable**: solo-anexado, sin actualización ni borrado. Idealmente con encadenamiento o firma que
  permita detectar manipulación.
- **Retención regulatoria**: años, no días. Y no se borra con la rotación normal.
- **Acceso restringido y a su vez auditado**: quién consultó la pista de auditoría también se
  registra.
- **Separada de los logs técnicos**: mezclarlas produce o pérdida de evidencia o coste absurdo.

> ⚠️ **Advertencia.** La pista de auditoría **no es un log con más retención**. Si un operador con
> permisos puede borrarla o modificarla, no cumple su función, y esa es exactamente la comprobación
> que hace un auditor.

> **Veredicto:** la pista de auditoría se diseña como un almacén aparte, solo-anexado y con
> retención propia. Cuesta infraestructura y disciplina de escritura; la alternativa barata
> —reutilizar los logs de aplicación— cuesta la evidencia el día que un auditor la pide.

---

## 6. 🔁 Cuando hay que corregir

**Qué es.** El procedimiento, porque la respuesta intuitiva —arreglar el dato— es la equivocada.

```text
1. NO se modifica el movimiento erróneo. Nunca.
2. Se emite un CONTRA-ASIENTO que lo anula, con referencia al original y motivo.
3. Se emite el asiento correcto, si procede.
4. Los tres quedan visibles en el extracto del cliente, y hay que decidir cómo se le explica.
5. Se registra en la pista de auditoría quién autorizó la corrección.
```

- **La visibilidad para el cliente es una decisión de negocio**, no técnica: verá un cargo, su
  anulación y el cargo correcto. Comunicarlo bien evita una reclamación.
- **La corrección masiva** —un bug que afectó a 40.000 cuentas— es un proceso batch con su propio
  cuadre, su aprobación y su registro. No es un `UPDATE` ejecutado por alguien de soporte.
- **La separación de deberes aplica**: quien detecta el error no debería ser quien autoriza la
  corrección, y esa es una exigencia, no una buena práctica.

> **Veredicto:** en banca no se arreglan datos, se emiten operaciones correctoras. Quien propone un
> `UPDATE` sobre un movimiento no ha entendido que el libro **es** la evidencia.

---

## 7. 🧭 Cómo se elige

```text
Modelado, siempre:
    → MOVIMIENTOS inmutables con identificador único, no contadores mutables
    → saldo derivado, o actualizado en la MISMA transacción que la inserción
    → corrección = contra-asiento + asiento nuevo. Nunca UPDATE.

Idempotencia:
    → clave de NEGOCIO, la que da el estándar o el canal. No inventes una.
    → restricción ÚNICA en la base de datos, no un `if` con consulta previa
    → atómica con el efecto, en la misma transacción

Ante un estado ambiguo (timeout sin respuesta):
    1. consultar el estado por la clave de negocio
    2. si no se puede: estado SIN RESPUESTA y que lo resuelva la conciliación
    3. NUNCA reintentar a ciegas

Conciliación, sin excepción:
    → automática, diaria como mínimo, con corte temporal bien definido
    → casar por clave de negocio, nunca por importe y fecha
    → métricas: descuadres, tiempo de detección, porcentaje resuelto automáticamente
    → escalado cuando no cuadra en el plazo acordado

Auditoría:
    → almacén aparte, inmutable, retención regulatoria, acceso restringido y auditado
    → sub, act, canal, política aplicada y resultado. Nunca el token.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Corregimos el movimiento" | Se emite un contra-asiento: el libro es inmutable y es la evidencia |
| "El saldo es un campo que actualizamos" | Es derivado de los movimientos; mutarlo pierde auditoría e idempotencia |
| "Inventamos una clave de idempotencia" | La da el estándar o el canal; usarla evita correlacionar dos identificadores |
| "Si no hay respuesta, reintentamos" | Puede haberse ejecutado: consulta o concilia, no reintentes a ciegas |
| "Conciliamos por importe y fecha" | Produce falsos emparejamientos; se casa por clave de negocio |
| "No cuadra, ajustamos el corte" | El corte se define primero; ajustarlo después es esconder el descuadre |
| "La auditoría es un log con más retención" | Debe ser inmutable, con acceso restringido y a su vez auditado |
| "La conciliación es cosa de operaciones" | Es parte del diseño: sin ella el sistema no tiene red |

---

## 📚 Para profundizar

- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017). Capítulos
  11 y 12: por qué la inmutabilidad de los hechos permite derivar y reconciliar, con el argumento
  general del que la partida doble es un caso particular de seis siglos.
- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulos 3 y 4:
  idempotencia, outbox y saga, que son las piezas técnicas de este capítulo.
- **Libro** — Vaughn Vernon, *Implementing Domain-Driven Design* (Addison-Wesley, 2013). El apéndice
  sobre event sourcing: el modelo que la contabilidad ya usaba.
- **Libro** — Michael Nygard, *Release It!*, 2ª ed. (Pragmatic Bookshelf, 2018). Los capítulos de
  estabilidad y de recuperación: por qué un sistema se diseña asumiendo que va a fallar.
- [microservices.io — Transactional outbox](https://microservices.io/patterns/data/transactional-outbox.html):
  el mecanismo que reduce la frecuencia de los descuadres.
- [microservices.io — Saga](https://microservices.io/patterns/data/saga.html): la compensación como
  operación nueva, que es el contra-asiento en vocabulario técnico.
- [Spring Batch — Reference documentation](https://docs.spring.io/spring-batch/reference/index.html):
  el marco con el que se construyen los procesos de conciliación y de corrección masiva.
- **Video** — GOTO Conferences, charlas sobre event sourcing en dominios financieros y sobre
  sistemas contables. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es la partida doble? 🟢
2. ¿Qué es un contra-asiento? 🟢
3. ¿Qué tipos de conciliación existen? 🟢
4. ¿Qué debe contener una pista de auditoría? 🟢
5. ¿De dónde sale la clave de idempotencia en un pago interbancario? 🟢
6. ¿Por qué el saldo debe ser derivado y no un contador mutable? 🟡
7. ¿Qué invariante permite detectar errores en la partida doble? 🟡
8. ¿Por qué se casa por clave de negocio y no por importe y fecha? 🟡
9. ¿Qué tres propiedades distinguen la pista de auditoría de un log? 🟡
10. ¿Cómo se implementa la idempotencia: con un `if` o con una restricción? 🟡
11. ¿Qué relación tiene la partida doble con el event sourcing? 🟡
12. ¿Por qué el corte temporal es crítico en una conciliación? 🟡
13. ¿Qué haces ante un timeout sin respuesta del core? 🟠
14. ¿Qué métricas tiene un proceso de conciliación? 🟠
15. ¿Por qué no se modifica un movimiento erróneo? 🟠
16. ¿Cómo se hace una corrección masiva de 40.000 cuentas? 🟠
17. ¿Por qué la separación de deberes aplica a las correcciones? 🟠
18. ¿Por qué "la conciliación es cosa de operaciones" es un error de diseño? 🟠
19. ¿Qué se registra y qué NUNCA se registra en la auditoría? 🟠
20. ¿Por qué la conciliación es el equivalente bancario de una fitness function? 🟠
21. Diseña la conciliación diaria entre tu sistema de pagos y el core, con
    14.000 operaciones al día y plazo regulatorio de resolución. 🔴
22. Un bug aplicó una comisión dos veces a 40.000 clientes durante tres días.
    Describe el procedimiento completo de corrección. 🔴
23. Tu sistema ordenó 14.238 transferencias y el core registró 14.237.
    Describe cómo investigas y qué tuvo que estar diseñado de antemano. 🔴

---

**Anterior:** [`07` — BPM y workflow](07-bpm-y-workflow.md) ·
**Siguiente:** [`09` — Simulación de entrevista](09-simulacion-de-entrevista.md) ·
**Relacionado:** [`02-eventos/03` — Garantías e idempotencia](../02-eventos/03-garantias-orden-e-idempotencia.md)
