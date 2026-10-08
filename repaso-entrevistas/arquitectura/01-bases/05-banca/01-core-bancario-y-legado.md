# 01 — Core bancario y legado

> Qué es un core bancario, por qué no se toca, cómo está construido por dentro, y el vocabulario
> —ventana batch, cierre de día, fecha valor— sin el que no se puede tener una conversación seria
> en una entrevista de banca.
> Asume leído [`01-bases/06` — DDD estratégico](../01-bases/06-ddd-estrategico.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

En una entrevista de backend en banca, la pregunta no es si sabes diseñar microservicios. Es si
entiendes **por qué no vas a poder aplicarlos donde está el dinero**.

```text
El core bancario:
  · lleva 20–40 años en producción
  · contiene reglas de negocio que nadie ha documentado y que solo existen en su código
  · es la fuente de verdad contable, auditada por el supervisor
  · no se puede parar, no se puede reescribir de golpe, y casi nunca se puede modificar
```

Quien llega proponiendo sustituirlo demuestra que no ha trabajado en banca. Quien llega sabiendo
**convivir con él** demuestra lo contrario, y ese es el perfil que se busca.

> **Regla:** en banca el core no es una dependencia, es una **restricción**. La arquitectura se
> diseña alrededor de él, no a pesar de él.

---

## 2. 🏛️ Qué es un core bancario

**Qué es.** El sistema que mantiene los saldos, los movimientos y la contabilidad. Todo lo demás
—app móvil, banca en línea, originación, tarjetas— son satélites que consultan y ordenan operaciones
contra él.

Lo que contiene y por qué importa que esté junto:

```text
Cuentas y saldos     → la verdad contable. Nada es real hasta que está aquí.
Movimientos          → el libro mayor. Inmutable por norma: no se borra, se contra-asienta.
Productos            → préstamos, depósitos, tarjetas, con sus reglas de devengo
Clientes             → la identidad canónica, con su cumplimiento normativo asociado
Contabilidad         → los asientos que alimentan el balance y los informes al supervisor
```

**Cómo está construido**, y el vocabulario que hay que reconocer:

- **Mainframe con COBOL y CICS** en los bancos grandes: transacciones en línea muy rápidas y muy
  fiables, con décadas de optimización. CICS es el monitor transaccional; DB2 o VSAM, el almacén.
- **Paquete comercial** —Temenos, Finacle, Flexcube— en bancos medianos: configurable, no
  modificable, y con un modelo de datos que viene dado.
- **Desarrollo propio en Java o .NET** en entidades más nuevas o en neobancos.

**Por qué no se toca.** Cuatro razones independientes, y cualquiera bastaría:

1. **Riesgo.** Un error en el cálculo de intereses o en un saldo es un incidente regulatorio, no un
   bug.
2. **Conocimiento perdido.** Las reglas están en el código y quienes las escribieron se jubilaron.
3. **Auditoría.** Cambiar el sistema de registro contable requiere certificación y a veces
   aprobación del supervisor.
4. **Acoplamiento.** Cuarenta sistemas dependen de su modelo de datos y de sus ventanas.

> **Veredicto:** el core no se moderniza sustituyéndolo, se moderniza **rodeándolo**. Y decir eso
> con naturalidad es lo que sitúa la respuesta.

---

## 3. 🕐 En línea contra batch, y la ventana

**Qué es.** La estructura temporal que gobierna todo en banca y que no existe en otros dominios.

```text
HORARIO EN LÍNEA     → el core atiende transacciones. Consultas y operaciones del cliente.
CIERRE DE DÍA        → el core deja de aceptar operaciones en línea. Empieza el proceso batch.
VENTANA BATCH        → de madrugada. Devengo de intereses, comisiones, liquidaciones,
                       generación de ficheros, informes regulatorios, conciliaciones.
APERTURA             → el core vuelve a estar disponible. Si el batch no terminó, NO ABRE.
```

- **La ventana batch es el recurso más escaso del banco.** Todo lo que hay que procesar de noche
  compite por ella, y si se desborda, el banco abre tarde. Eso es un incidente con visibilidad de
  comité de dirección.
- **Durante el cierre, el core puede estar total o parcialmente indisponible.** Tu sistema tiene que
  saber qué hacer en esa ventana: encolar, degradar, o rechazar explícitamente. Diseñarlo es
  obligatorio y se olvida.
- **La fecha contable no es la fecha real.** Una operación de las 23:50 puede tener fecha contable
  del día siguiente. Confundirlas produce descuadres.

**Los tres conceptos de fecha que hay que distinguir:**

```text
Fecha de operación → cuándo se ordenó
Fecha contable     → a qué día se imputa en el libro. Puede diferir de la de operación.
Fecha valor        → desde cuándo cuenta para el cálculo de intereses. Puede ser anterior
                     o posterior a las otras dos.
```

> ⚠️ **Advertencia.** La fecha valor es un concepto que no existe fuera de banca y que aparece en
> cuanto hay intereses. Un ingreso con fecha valor de ayer genera intereses desde ayer aunque se haya
> registrado hoy. Modelarlo como un solo campo `fecha` es un error que se descubre en el primer
> cierre.

> **Veredicto:** si no preguntas por la ventana batch y por el comportamiento durante el cierre,
> has diseñado un sistema que se rompe todas las noches.

---

## 4. 💰 Saldo contable y saldo disponible

**Qué es.** La distinción más útil de todo el bloque, y la que resuelve media docena de problemas de
consistencia.

```text
Saldo contable   → lo que dice el libro mayor. Firme, auditado, consistente.
Saldo disponible → contable menos retenciones, más créditos aplicables.
                   Es lo que el cliente puede gastar AHORA.
Saldo en tránsito→ operaciones ordenadas y no liquidadas.
```

- **La retención** es el mecanismo: al ordenar un pago con tarjeta, el importe se retiene aunque el
  asiento contable llegue días después. El disponible baja de inmediato; el contable, no.
- Es exactamente la **semántica de bloqueo** de las sagas de
  [`02-eventos/05`](../02-eventos/05-saga.md): un estado intermedio explícito, con caducidad, que
  evita el doble gasto sin bloquear la contabilidad.
- Y resuelve el conflicto de
  [`03-datos/01`](../03-datos/01-cap-y-consistencia.md): el disponible puede servirse con una ventana
  de consistencia si se marca con su hora; el contable, no.

> 🧠 **Modelo mental.** La banca resolvió la consistencia eventual décadas antes de que existiera el
> término: separando el dato que se muestra del dato que manda, y reconciliando después. Citar esto
> en una entrevista de arquitectura es de las mejores respuestas que hay.

> **Veredicto:** cuando te pregunten "¿cómo garantizas que el saldo sea exacto y la app nunca
> falle?", esta distinción **es** la respuesta.

---

## 5. 📤 Cómo se integra con el core

**Qué es.** Las cuatro formas, de más antigua a más moderna, y en un banco real coexisten todas.

| Forma | Cómo | Cuándo aparece |
|---|---|---|
| **Fichero** | Se deja un fichero posicional, el batch lo procesa | Lo más antiguo y lo más común aún |
| **Colas (MQ)** | Mensaje con formato fijo, respuesta por otra cola | Transaccional, con XA. Ver [`02`](02-mq-e-integracion.md) |
| **Transacción CICS** | Llamada síncrona a un programa del mainframe | Consultas en línea; muy rápida, muy acoplada |
| **API** | REST o SOAP sobre una capa de exposición | Lo que el banco añadió encima, no lo que el core es |

- **La API casi nunca es del core**: es una fachada que alguien construyó delante, y por debajo
  acaba en una de las tres anteriores. Saberlo evita suposiciones equivocadas sobre su latencia y su
  disponibilidad.
- **El fichero sigue vivo** porque es el mecanismo que soporta volumen masivo con recuperación
  simple: si algo falla, se reprocesa el fichero.

**Lo que hay que preguntar siempre** ante una integración con el core:

```text
¿Es síncrona o diferida?          → decide si puedes responder al cliente en el momento
¿Qué pasa durante la ventana?     → ¿encolas, degradas o rechazas?
¿Es idempotente? ¿Con qué clave?  → si no, un reintento duplica un asiento
¿Cuál es su SLA real?             → no el declarado: el medido
¿Cómo se concilia?                → porque va a haber descuadres
```

> **Veredicto:** la forma de integración determina el diseño de tu sistema más que ninguna otra
> decisión. Preguntarlo antes de diseñar es lo que separa una propuesta viable de una teórica.

---

## 6. 🌿 Modernizar sin tocar: la doctrina

**Qué es.** La estrategia estándar, que combina tres patrones que ya conoces:

```text
Strangler Fig  → una fachada delante; las capacidades se mueven de una en una.
                 Ver [`01-bases/02`](../01-bases/02-estilos-de-despliegue.md).
ACL            → una capa anticorrupción traduce el modelo del core al tuyo.
                 Ver [`04`](04-capa-anticorrupcion.md).
CQRS de lectura→ las consultas se sirven de una proyección alimentada por eventos o CDC,
                 no del core. Descarga el core y desacopla la disponibilidad.
```

- **Las lecturas se migran primero**, siempre: no tienen riesgo contable y descargan el core, que
  suele ser el cuello de botella y a veces cobra por transacción.
- **Las escrituras son las últimas**, y muchas veces no se migran nunca: el core sigue siendo el
  sistema de registro y tu sistema ordena operaciones contra él.
- El avance se mide en **porcentaje de tráfico** servido por lo nuevo, no en código migrado.

> 💰 **Costo.** Muchos cores comerciales **cobran por transacción**. Una consulta de saldo en cada
> carga de pantalla puede ser una partida presupuestaria. Es un argumento real —y poco conocido— a
> favor de la proyección de lectura.

> **Veredicto:** modernizar en banca es construir alrededor y desviar tráfico, no sustituir. Quien
> propone reescribir el core no ha visto lo que cuesta ni lo que arriesga.

---

## 7. 🧭 Cómo se elige

```text
Te dan un caso de uso en banca. Antes de diseñar, pregunta:

¿Toca dinero o solo consulta?
    Consulta  → candidata a proyección propia. No preguntes al core en cada carga.
    Dinero    → el core es el sistema de registro. Tú ordenas, él asienta.

¿Qué pasa durante la ventana batch?
    → Decídelo explícitamente: encolar, degradar con aviso, o rechazar. Nunca "no lo pensamos".

¿Qué saldo muestras?
    Disponible, con su marca de tiempo → para la pantalla
    Contable, consistente              → para validar cualquier operación

¿Cómo integras?
    Fichero → volumen masivo, recuperación simple, latencia de horas
    MQ      → transaccional, latencia de segundos
    CICS    → consulta en línea, muy rápida, muy acoplada
    API     → probablemente una fachada; pregunta qué hay debajo

Y en cualquier caso:
    → idempotencia con clave de negocio, y conciliación. No son extras: son el diseño.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Migramos el core a microservicios" | No se sustituye: se rodea, y las escrituras suelen quedarse |
| "El saldo es un número" | Son tres: contable, disponible y en tránsito, y significan cosas distintas |
| "La fecha de la operación" | Son tres: operación, contable y valor, y pueden no coincidir |
| "El core tiene una API REST" | Suele ser una fachada; debajo hay fichero, MQ o CICS |
| "Consultamos el saldo en cada pantalla" | Muchos cores cobran por transacción: es una partida presupuestaria |
| "El batch es un detalle operativo" | La ventana batch es el recurso más escaso del banco |
| "Borramos el movimiento erróneo" | El libro mayor es inmutable: se contra-asienta |

---

## 📚 Para profundizar

- **Libro** — Sam Newman, *Monolith to Microservices* (O'Reilly, 2019). Capítulos 3 y 4: Strangler
  Fig y los patrones de descomposición de datos, que es exactamente la doctrina de §6 aplicada a un
  legado que no se puede tocar.
- **Libro** — Michael Feathers, *Working Effectively with Legacy Code* (Prentice Hall, 2004). El
  marco mental para trabajar con código sin tests y sin documentación, que es el core.
- **Libro** — Vlad Khononov, *Learning Domain-Driven Design* (O'Reilly, 2021). Capítulo 4: la capa
  anticorrupción y los patrones de relación con un proveedor que no puedes cambiar.
- Martin Fowler — [StranglerFigApplication](https://martinfowler.com/bliki/StranglerFigApplication.html):
  el patrón con su nombre y su razón de ser.
- [microservices.io — Strangler application](https://microservices.io/patterns/refactoring/strangler-application.html):
  la ficha con las fuerzas y los contras.
- Martin Fowler — [ParallelChange](https://martinfowler.com/bliki/ParallelChange.html):
  expand/contract, que es cómo se cambia un contrato con un consumidor que no controlas.
- **Documentación** — IBM, *IBM MQ* e *IBM CICS Transaction Server*. Se citan por título: el sitio
  de IBM bloquea la verificación automática de enlaces, así que no se enlaza (§10.1 de la guía).
- **Video** — GOTO Conferences, charlas de Sam Newman sobre migración de monolitos y sobre
  convivencia con sistemas heredados. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es un core bancario y qué contiene? 🟢
2. ¿Qué es la ventana batch? 🟢
3. ¿Qué diferencia hay entre saldo contable y saldo disponible? 🟢
4. Nombra las cuatro formas de integrarse con un core. 🟢
5. ¿Qué es una retención? 🟢
6. ¿Qué tres fechas distingue una operación bancaria? 🟡
7. ¿Qué es la fecha valor y por qué no basta un solo campo de fecha? 🟡
8. ¿Por qué no se toca el core? Da cuatro razones. 🟡
9. ¿Qué pasa si el batch no termina a tiempo? 🟡
10. ¿Por qué el libro mayor es inmutable y cómo se corrige un error? 🟡
11. ¿Qué es CICS y qué papel juega? 🟡
12. ¿Por qué la API del core suele no ser del core? 🟡
13. ¿Por qué las lecturas se migran primero? 🟠
14. ¿Qué cinco cosas preguntas ante una integración con el core? 🟠
15. ¿Por qué consultar el saldo en cada pantalla puede ser un problema
    presupuestario? 🟠
16. ¿Qué relación tiene el saldo disponible con la semántica de bloqueo de una
    saga? 🟠
17. ¿Cómo resolvió la banca la consistencia eventual antes de que existiera el
    término? 🟠
18. ¿Por qué el fichero sigue siendo un mecanismo vigente? 🟠
19. ¿Qué hay que decidir explícitamente sobre el comportamiento durante la
    ventana? 🟠
20. ¿Cómo se mide el avance de una modernización de core? 🟠
21. Diseña la consulta de saldo de una app móvil con 2 millones de usuarios,
    sabiendo que el core cobra por transacción y cierra de 23:00 a 03:00. 🔴
22. Te piden "migrar el core a microservicios en 18 meses". ¿Qué respondes y
    qué propones? 🔴
23. Un cliente ve un saldo que no cuadra con sus movimientos. Describe cómo
    investigas y qué conceptos del capítulo usas. 🔴

---

**Siguiente:** [`02` — MQ e integración asíncrona clásica](02-mq-e-integracion.md) ·
**Relacionado:** [`04` — Capa anticorrupción](04-capa-anticorrupcion.md)
