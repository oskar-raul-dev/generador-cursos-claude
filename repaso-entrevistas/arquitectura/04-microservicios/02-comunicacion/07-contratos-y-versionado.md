# 07 — Contratos y versionado

> Cómo se cambia un contrato en producción sin romper a nadie, y cómo se demuestra en CI en vez de
> confiar. Cubre compatibilidad, expand/contract, estrategias de versión, lector tolerante y
> contratos dirigidos por el consumidor. Asume leídos [`02`](02-http-entre-servicios.md),
> [`03`](03-grpc.md) y [`06`](06-mensajeria-y-eventos.md): aquí se versiona lo que allí se definió.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

El contrato es lo único que de verdad ata a dos servicios. Puedes cambiar la base de datos, el
lenguaje y hasta el algoritmo sin que nadie se entere; cambia un campo del contrato y rompes a gente
que no sabes ni que existe.

Y la asimetría que hace esto difícil:

```text
Tú despliegas el martes.
Tu consumidor despliega cuando puede: el jueves, o el mes que viene, o nunca
  (la app móvil que el usuario no actualiza).

Durante ese tiempo conviven las dos versiones. Siempre.
```

De ahí sale la única regla que importa de este capítulo: **nunca hay un instante en que todos cambien
a la vez**, así que todo cambio tiene que funcionar con la versión vieja y la nueva conviviendo. Todo
lo demás —versionado en la ruta, en el encabezado, semántico— son detalles comparados con eso.

---

## 2. 🧱 Compatibilidad hacia atrás y hacia adelante

**Qué es.** Dos propiedades distintas que se confunden constantemente:

```text
Hacia atrás (backward)   un consumidor NUEVO entiende datos VIEJOS
Hacia adelante (forward) un consumidor VIEJO tolera datos NUEVOS
```

**Cómo va.** En una API síncrona, la que más importa es la de adelante: despliegas el servidor antes
que los clientes, así que los clientes viejos van a recibir respuestas nuevas. En **eventos** hacen
falta las dos, porque los mensajes quedan almacenados: un consumidor nuevo leerá eventos viejos, y
uno viejo recibirá eventos nuevos.

La tabla de referencia, que conviene tener memorizada:

| Cambio | Compatible | Por qué |
|---|---|---|
| Añadir un campo opcional | ✅ | El viejo lo ignora; el nuevo lo usa si está |
| Añadir un campo obligatorio | ❌ | El productor viejo no lo envía y el consumidor nuevo falla |
| Eliminar un campo | ❌ | Alguien lo está leyendo, aunque las métricas digan que no |
| Renombrar un campo | ❌ | Es eliminar y añadir a la vez. En protobuf sí se puede: el número manda |
| Cambiar el tipo | ❌ | Ni siquiera de entero a cadena "porque JSON lo tolera" |
| Añadir un valor a un enumerado | ⚠️ | Rompe al consumidor que hace un `switch` exhaustivo y no tiene rama por defecto |
| Relajar una validación | ✅ | Aceptas más de lo que aceptabas |
| Endurecer una validación | ❌ | Rechazas lo que antes aceptabas: es una ruptura, aunque no cambie el esquema |

**Cuánto.** Mantener compatibilidad cuesta campos opcionales que conviven, código que soporta dos
formas y una fase de limpieza que hay que recordar hacer. Es barato comparado con coordinar
despliegues.

> **⚠️ Advertencia:** las dos rupturas que nadie ve venir son la última fila —endurecer una
> validación no cambia el esquema y rompe igual— y el valor nuevo en un enumerado. Ninguna de las dos
> la detecta una comparación de esquemas; la detecta un contrato de consumidor.

---

## 3. 🧱 Expand/contract, aplicado a contratos

**Qué es.** El mismo patrón de las migraciones de esquema, aplicado a las APIs: primero se añade,
después se migra, y al final se quita.

**Cómo va.** Renombrar `amount` a `total` sin romper a nadie:

```text
1. EXPAND    el servidor devuelve AMBOS campos: importe y total
             y acepta ambos en la entrada
2. MIGRATE   los consumidores pasan a usar total, a su ritmo
             se mide quién sigue usando importe (métrica por campo)
3. CONTRACT  cuando el uso de importe es cero durante un periodo,
             se anuncia, se espera, y se elimina
```

**Con qué.** La parte que casi nadie implementa es la métrica del paso 2: un contador por campo
leído, o al menos por consumidor. Sin ella, el paso 3 se decide por fe, y por eso muchas APIs nunca
llegan a contraerse y acumulan campos muertos durante años.

**Cuánto.** Cuesta que el contrato sea temporalmente más grande y feo, y cuesta acordarse de cerrar.
La alternativa —cambiar de golpe y coordinar— cuesta una ventana de despliegue conjunto, que es
exactamente lo que la arquitectura intentaba evitar.

**Cuándo sí.** Siempre que el cambio sea incompatible y haya más de un consumidor.

**Cuándo no.** Cuando el consumidor es uno solo, del mismo equipo, y se despliega a la vez. Ahí
coordinar es más barato, y decirlo demuestra criterio en vez de dogma.

> **Veredicto:** todo cambio incompatible se convierte en tres cambios compatibles. Si no puedes
> hacerlo en tres pasos, lo que tienes no es un problema de contrato: es una frontera mal puesta.

---

## 4. ⚖️ Cómo se versiona, de verdad

| Estrategia | Cómo se ve | A favor | En contra |
|---|---|---|---|
| **En la ruta** | `/v2/orders` | Visible, trivial de enrutar y de cachear | Duplica rutas; invita a mantener dos implementaciones |
| **En el encabezado** | `Accept: application/vnd.orders.v2+json` | No ensucia la URL; permite negociar | Menos visible; se olvida en pruebas y en `curl` |
| **Por campo o por esquema** | El propio esquema evoluciona; nada de v1/v2 | Es lo que hace protobuf; evita duplicar | Exige disciplina de compatibilidad estricta |
| **Sin versión** | Solo cambios compatibles, siempre | Lo más simple que funciona | Obliga a no equivocarse nunca |

Lo que hace la industria, dicho sin idealismo: **versión mayor en la ruta para APIs externas**,
porque es explícita y la entienden todos los consumidores; y **evolución del esquema sin versión para
APIs internas y para eventos**, donde el coste de mantener dos implementaciones no compensa.

Y el matiz que sube la nota: **una versión mayor nueva no es una victoria, es una derrota
administrada**. Significa que vas a mantener dos implementaciones durante meses. Antes de crear `/v2`
conviene preguntarse si el cambio se puede hacer con expand/contract, que es casi siempre que sí.

---

## 5. 🧱 El lector tolerante

**Qué es.** Escribir el consumidor para que ignore lo que no conoce y no se rompa con lo que no
espera.

**Cómo va.** Tres reglas concretas:

- **Ignora campos desconocidos.** Es el valor por defecto en casi todas las librerías, y se rompe
  cuando alguien activa el modo estricto "para detectar errores antes". Detecta errores, sí: los
  provoca en producción cada vez que el otro añade un campo opcional.
- **Lee solo lo que necesitas.** Si tu consumidor extrae tres campos de veinte, que su modelo tenga
  tres. Mapear el objeto entero acopla a cosas que no usas.
- **Ten rama por defecto en los enumerados.** Un valor nuevo llegará, y lo correcto casi nunca es
  lanzar una excepción: es registrarlo y aplicar un comportamiento seguro.

**Cuánto.** Cuesta poco y evita una clase entera de incidentes. El matiz moderno —y conviene decirlo—
es que **tolerar no es aceptar cualquier cosa**: los datos que sí usas se validan estrictamente. La
tolerancia es para lo que ignoras, no para lo que interpretas.

> **💡 Truco:** la pregunta de entrevista es "¿validación estricta o tolerante?". La respuesta
> completa es: estricta con lo que uso, tolerante con lo que no. Responder solo "tolerante" suena a
> descuido; responder solo "estricta" produce servicios que se rompen cuando otro añade un campo.

---

## 6. 🧱 Contratos dirigidos por el consumidor

**Qué es.** El consumidor declara qué espera del proveedor; esa expectativa se convierte en un
artefacto —el pacto— que el proveedor verifica en **su** pipeline.

**Cómo va.**

```text
1. El consumidor escribe sus pruebas contra un simulador que se genera del pacto
2. El pacto se publica en un repositorio común
3. El proveedor, en SU pipeline, verifica que cumple todos los pactos publicados
4. Si un cambio rompe a un consumidor, falla el pipeline del PROVEEDOR,
   antes de desplegar — no en producción del consumidor
```

**Qué resuelve que no resuelven los tests de integración.** Los de integración necesitan ambos
servicios vivos y un entorno completo, son lentos, y fallan por motivos que no tienen que ver con el
contrato. El pacto es rápido, se ejecuta sin el otro servicio delante, y **responde a la única
pregunta que importa: ¿este cambio rompe a alguien?**

Y captura las dos rupturas invisibles de §2: una validación endurecida y un enumerado nuevo hacen
fallar el pacto, cuando una comparación de esquemas las daría por compatibles.

**Con qué.** El estándar de facto tiene implementación en las cuatro plataformas y un repositorio de
pactos que hace de intermediario. En el mundo Java existe además una variante integrada con el
ecosistema de Spring.

**Cuánto.** Cuesta montar el repositorio de pactos y la disciplina de publicar y verificar. Y cuesta
una conversación organizativa: el proveedor tiene que aceptar que su pipeline falle por culpa de las
expectativas de otro equipo.

**Cuándo sí.** Con varios consumidores conocidos y equipos distintos. Es exactamente el caso de una
API interna.

**Cuándo no.** Con consumidores desconocidos —una API pública— porque no hay quién escriba el pacto;
ahí mandan el esquema y la disciplina. Y con un único consumidor del mismo equipo, donde una prueba
de integración normal es más barata.

> **Veredicto:** los contratos de consumidor sustituyen al entorno de integración completo, que es la
> pieza más cara y menos fiable de todo el aparato de pruebas. Si solo vas a montar una cosa de este
> capítulo, monta esto.

---

## 7. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Generación de cliente y servidor desde OpenAPI o `.proto` integrada en la construcción; verificación de pactos con la librería estándar del ecosistema y con la variante de Spring | Decidir si el contrato se escribe primero o se genera del código —y elegir lo primero—; y mantener el pipeline de verificación |
| **Node/TS** | Generadores de cliente y de tipos desde OpenAPI; validación en el borde con esquemas declarados en el propio lenguaje; implementación nativa de pactos | Que el tipo de TypeScript **no valida nada en ejecución**: hace falta validación real en el borde, y eso se olvida constantemente |
| **Go** | Generación desde `.proto` idiomática; herramientas de registro de esquemas con verificación de compatibilidad; generadores desde OpenAPI | El código generado desde OpenAPI se nota más generado que en otras plataformas; y la validación de entrada hay que escribirla |
| **Python** | Validación y serialización declarativa muy fuerte, que además genera el esquema; generación desde `.proto` | Que el esquema generado del código no se convierta en la fuente de verdad; y la verificación de compatibilidad, que no viene sola |

El punto común de las cuatro filas es la misma decisión, y es la que más consecuencias tiene:

```text
Contrato primero        el .proto o el OpenAPI se escribe y se revisa;
(contract-first)        el código se genera de él. El contrato es un acuerdo.

Código primero          el contrato se genera de las clases del servidor.
(code-first)            Cualquier refactor interno cambia el contrato sin que nadie lo decida.
```

**Contrato primero gana entre servicios**, y el argumento es concreto: con código primero, renombrar
un campo interno publica un contrato nuevo y rompe a un consumidor sin que ninguna persona haya
tomado esa decisión.

> **🧰 Plataforma:** la trampa específica de Node/TS merece nombrarse aparte: los tipos desaparecen al
> compilar, así que un `interface` no comprueba absolutamente nada en ejecución. Muchos equipos creen
> tener validación de contrato y lo que tienen es autocompletado.

---

## 8. 🧭 Quién es dueño del contrato

Es una pregunta organizativa disfrazada de técnica, y aparece en entrevistas de Tech Lead:

```text
¿Quién decide la forma del contrato?
│
├─ API pública o muchos consumidores ─► el PROVEEDOR es dueño.
│                                        Diseña para lo general y versiona con cuidado.
│
├─ API interna con pocos consumidores ─► el contrato se ACUERDA.
│                                        El proveedor lo publica; los consumidores
│                                        lo verifican con pactos.
│
└─ BFF de una experiencia ─────────────► el CONSUMIDOR es dueño.
                                         Lo mantiene el equipo de esa experiencia.
```

Y la frase que resuelve la discusión cuando dos equipos no se ponen de acuerdo:

> "El proveedor publica el contrato, pero el que decide si un cambio rompe es el consumidor, y lo
> dice su pacto en mi pipeline. Así la discusión deja de ser de opiniones y pasa a ser una prueba que
> falla o no."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Versionamos con `/v2` y ya está" | Crear una versión mayor es comprometerse a mantener dos implementaciones. Casi todo se puede hacer con expand/contract |
| "El contrato lo genera el código" | Entonces un refactor interno cambia el contrato sin que nadie lo decida. El contrato se escribe y el código se genera de él |
| "Añadir un campo nunca rompe" | Añadir uno **obligatorio** rompe; y un valor nuevo en un enumerado rompe al consumidor sin rama por defecto |
| "Los tests de integración cubren el contrato" | Necesitan ambos servicios vivos y fallan por mil motivos ajenos. El pacto responde solo a "¿rompo a alguien?" |
| "Con TypeScript el contrato está garantizado" | Los tipos desaparecen al compilar: no validan nada en ejecución. Hace falta validación real en el borde |
| "Quitamos el campo, ya no lo usa nadie" | Hay que medirlo por consumidor y anunciarlo. "Nadie lo usa" suele significar "no lo hemos mirado" |
| "Endurecer la validación no es un cambio de contrato" | Rechazar lo que antes aceptabas rompe a quien lo enviaba, aunque el esquema no cambie |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 5, sección de
   versionado y contratos, y capítulo 9 para el lugar de los pactos en las pruebas. **La referencia
   principal del capítulo.**
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 9, con los
   contratos de consumidor dentro de la estrategia de pruebas.
3. **Fuente primaria** — Martin Fowler, «Consumer-Driven Contracts», el artículo que fundó la
   práctica:
   [martinfowler.com/articles/consumerDrivenContracts.html](https://martinfowler.com/articles/consumerDrivenContracts.html).
4. **Fuente primaria** — Martin Fowler, «TolerantReader», con el matiz de qué se tolera y qué no:
   [martinfowler.com/bliki/TolerantReader.html](https://martinfowler.com/bliki/TolerantReader.html).
5. **Fuente primaria** — Martin Fowler, «ParallelChange», que es el expand/contract de §3:
   [martinfowler.com/bliki/ParallelChange.html](https://martinfowler.com/bliki/ParallelChange.html).
6. **Documentación** — Pact, cómo funciona el flujo de pactos y el repositorio:
   [docs.pact.io/getting_started/how_pact_works](https://docs.pact.io/getting_started/how_pact_works).
7. **Documentación** — Protocol Buffers, «Dos and Don'ts», las reglas de evolución del esquema:
   [protobuf.dev/programming-guides/dos-donts/](https://protobuf.dev/programming-guides/dos-donts/).
8. **Especificación** — AsyncAPI, el equivalente de OpenAPI para contratos de mensajes:
   [asyncapi.com/docs](https://www.asyncapi.com/docs).

---

## 🧠 Preguntas

1. Define compatibilidad hacia atrás y hacia adelante. 🟢
2. ¿Cuáles son los tres pasos de expand/contract aplicado a un contrato? 🟢
3. Nombra tres cambios compatibles y tres incompatibles. 🟢
4. ¿Qué es un lector tolerante y cuáles son sus tres reglas? 🟢
5. ¿Qué es un contrato dirigido por el consumidor y en qué pipeline falla? 🟢
6. ¿Qué diferencia hay entre contrato primero y código primero? 🟡
7. ¿Por qué en eventos hacen falta las dos compatibilidades y en una API síncrona sobre todo una? 🟡
8. ¿Por qué añadir un valor a un enumerado puede romper a un consumidor? 🟡
9. ¿Por qué endurecer una validación es un cambio incompatible aunque el esquema no cambie? 🟡
10. ¿Qué resuelve un pacto que no resuelve una prueba de integración? 🟡
11. ¿Por qué un `interface` de TypeScript no garantiza el contrato? 🟡
12. ¿Por qué crear `/v2` se describe como "una derrota administrada"? 🟡
13. ¿Qué te da cada plataforma para generar y verificar contratos, y dónde se valida de verdad? 🟡
14. Tienes que renombrar un campo que usan tres consumidores. Da el plan completo. 🟠
15. ¿Cómo mides si alguien sigue usando un campo que quieres eliminar? 🟠
16. Un consumidor no puede desplegar hasta dentro de dos meses. ¿Qué implica para tu cambio? 🟠
17. ¿Cuándo usarías versión en la ruta y cuándo evolución del esquema? 🟠
18. ¿Qué haces si un pacto de un consumidor te impide un cambio que necesitas? 🟠
19. Diseña la política de versionado de los eventos de tu sistema. 🟠
20. ¿Quién debería ser dueño del contrato de un BFF, y por qué? 🟠
21. Tu equipo genera el OpenAPI desde el código. Argumenta a favor de cambiarlo. 🟠
22. Diseña el proceso completo de cambio de contrato en tu organización: quién propone, quién
    verifica, qué falla y dónde, y cuándo se retira lo viejo. 🔴
23. Un consumidor externo lleva seis meses sin actualizar y te bloquea la retirada de `/v1`. Da tu
    plan técnico y la conversación. 🔴
24. Diseña la verificación de compatibilidad en CI para un sistema con APIs REST y eventos, diciendo
    qué comprueba cada paso y qué no puede detectar. 🔴
25. Tienes que cambiar el significado de un campo sin cambiar su nombre ni su tipo —de importe sin
    impuestos a importe con impuestos—. Diseña el cambio. 🔴

---

**Anterior:** [`06` — Mensajería y eventos](06-mensajeria-y-eventos.md) · **Siguiente:**
[`08` — Simulación de entrevista](08-simulacion-de-entrevista.md) · **Relacionado:**
[`03` — gRPC](03-grpc.md) · [`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/)

**Talleres, opcionales:** [`06/01` — El monolito y su contrato](../06-talleres/01-el-monolito-y-su-contrato.md) · [`06/04` — gRPC](../06-talleres/04-grpc.md) · [`06/08` — Saga coreografiada](../06-talleres/08-saga-coreografiada.md) · [`06/10` — Contratos entre servicios y testing](../06-talleres/10-contratos-y-testing.md).
