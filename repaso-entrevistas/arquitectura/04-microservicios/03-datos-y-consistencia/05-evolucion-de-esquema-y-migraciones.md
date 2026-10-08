# 05 — Evolución de esquema y migraciones

> Cómo se cambia el esquema de un servicio sin downtime y sin coordinar despliegues: expand/contract,
> migraciones compatibles, backfill por lotes y quién ejecuta qué. Asume leído
> [`01`](01-base-de-datos-por-servicio.md). La evolución de **contratos** —lo que ven otros
> servicios— es de
> [`02-comunicacion/07`](../02-comunicacion/07-contratos-y-versionado.md); aquí se cambia lo de
> dentro.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

El esquema es interno, así que puedes cambiarlo cuando quieras. Pero hay un detalle que lo complica:
durante un despliegue gradual, **el código viejo y el nuevo corren a la vez contra la misma base**.

```text
t0   3 instancias con código v1   ──► esquema v1
t1   2 con v1, 1 con v2           ──► ¿qué esquema? Tiene que valer para las dos
t2   1 con v1, 2 con v2
t3   3 con v2
```

Si la migración renombra una columna en `t1`, las instancias viejas fallan durante todo el reemplazo.
Y si la vuelta atrás implica revertir el esquema, el rollback deja de ser instantáneo y pasa a ser
una operación con riesgo.

De ahí la regla que gobierna el capítulo: **toda migración tiene que ser compatible con el código que
ya está corriendo**. No es una buena práctica: es la condición para poder desplegar sin coordinar, que
es lo que se compró al separar servicios.

---

## 2. 🧱 Expand/contract, en el esquema

**Qué es.** El mismo patrón de contratos, aplicado a la base: se añade, se migra, y al final se
quita. Renombrar `amount` a `total`:

```text
Paso              Esquema                    Código desplegado
────────────────  ─────────────────────────  ──────────────────────────────────
1. EXPAND         + columna total (nullable) v1 (no la conoce; sigue usando importe)
2. DOBLE ESCRITURA                            v2: escribe en AMBAS, lee de importe
3. BACKFILL       copiar importe → total      v2 sigue corriendo
4. CAMBIO LECTURA                             v3: lee de total, sigue escribiendo ambas
5. DEJAR DE ESCRIBIR                          v4: solo total
6. CONTRACT       − columna importe           v4 ya no la usa
```

**Cómo va.** Seis pasos para un renombrado parece exagerado, y lo es para una tabla de mil filas. Por
eso la versión práctica se ajusta al riesgo:

- **Tabla pequeña, servicio con poco tráfico:** se puede comprimir en dos o tres pasos, incluso con
  una ventana corta.
- **Tabla grande o servicio crítico:** los seis, sin atajos.

Lo que **no** se ajusta nunca es el principio: ningún paso rompe al código que ya está corriendo.

**Cuánto.** Cuesta varios despliegues en vez de uno, y tener código que escribe en dos sitios durante
un tiempo. La alternativa —una ventana de parada— cuesta coordinación y negociación con el negocio.

**Cuándo sí.** Siempre que el cambio sea incompatible y el servicio no pueda pararse.

**Cuándo no.** Cuando hay ventana de mantenimiento concedida y la migración es rápida: entonces
pararlo es más simple y más seguro, y conviene decirlo en vez de aplicar el patrón por reflejo.

> **Veredicto:** todo cambio incompatible de esquema se convierte en una secuencia de cambios
> compatibles. Si no puedes descomponerlo así, negocia una ventana — pero que sea una decisión, no un
> descuido.

---

## 3. ⚖️ Qué migraciones son seguras y cuáles no

| Cambio | ¿Seguro con código viejo corriendo? | Nota |
|---|---|---|
| Añadir tabla | ✅ | Nadie la usa todavía |
| Añadir columna **nullable** | ✅ | El código viejo la ignora |
| Añadir columna **obligatoria sin defecto** | ❌ | Los `INSERT` del código viejo fallan |
| Añadir columna obligatoria **con defecto** | ⚠️ | Seguro para el código; en tablas grandes puede bloquear |
| Añadir índice | ⚠️ | Seguro si se crea sin bloquear; el motor manda |
| Eliminar columna | ❌ | El código viejo la sigue leyendo o escribiendo |
| Renombrar columna | ❌ | Es eliminar y añadir: expand/contract |
| Cambiar tipo | ❌ | Salvo ampliaciones compatibles, y aun así con cuidado |
| Añadir restricción | ❌ | Los datos existentes pueden incumplirla; y el código viejo también |
| Eliminar restricción | ✅ | Se acepta más de lo que se aceptaba |

Las dos filas con ⚠️ son las que más incidentes producen, y merecen su propia explicación: **una
migración puede ser lógicamente segura y operativamente peligrosa**. Añadir una columna con valor por
defecto o crear un índice pueden bloquear la tabla el tiempo suficiente para tumbar el servicio, según
el motor, su versión y el tamaño de la tabla.

> **⚠️ Advertencia:** antes de ejecutar una migración en una tabla grande hay que saber si su motor
> la resuelve sin bloqueo y cuánto tarda. "Funcionó en el entorno de pruebas con diez mil filas" no
> dice nada sobre las cuarenta millones de producción.

---

## 4. 🧱 Backfill: mover datos sin parar nada

**Qué es.** Rellenar la columna o la tabla nueva con los datos existentes, mientras el sistema sigue
funcionando.

**Cómo va.** Nunca con un `UPDATE` sobre toda la tabla: por lotes, con pausa y con reanudación.

```text
bucle:
  seleccionar N filas pendientes (por rango de clave, no por OFFSET)
  actualizarlas en una transacción corta
  guardar la última clave procesada    ← permite reanudar tras un corte
  pausa breve                          ← deja respirar a la carga real
```

- **Por rango de clave, no por `OFFSET`:** el desplazamiento con números grandes obliga al motor a
  recorrer lo anterior y se degrada a medida que avanza.
- **Transacciones cortas:** una transacción de un millón de filas bloquea, llena el log y, si falla,
  lo pierde todo.
- **Con reanudación:** el backfill de una tabla grande tarda horas; va a interrumpirse, y hay que
  poder continuar sin repetir.
- **Con pausa:** el backfill compite con el tráfico real. Sin límite de ritmo, la migración se
  convierte en el incidente.

**Cuánto.** Cuesta tiempo —horas o días en tablas grandes— y vigilancia. A cambio no cuesta
disponibilidad, que es el objetivo.

> **💡 Truco:** el backfill se ejecuta como un proceso con su propio control —arrancar, parar,
> reanudar, ver progreso—, no como un script que alguien lanza desde su portátil. La diferencia se
> nota el día que hay que pararlo porque la base está sufriendo.

---

## 5. 🧭 Quién ejecuta la migración, y cuándo

Tres opciones, y la elección tiene consecuencias reales:

| Opción | A favor | En contra |
|---|---|---|
| **Al arrancar la aplicación** | Cero infraestructura; imposible olvidarla | Con varias instancias hace falta exclusión; un fallo se vuelve bucle de reinicios; acopla despliegue y esquema |
| **Paso del pipeline, antes de desplegar** | Fallo visible y aislado; se puede reintentar; el servicio sigue corriendo | Hay que construirlo; exige que la migración sea compatible hacia atrás |
| **Manual, por operaciones** | Control total en cambios delicados | No reproducible, no versionado, y depende de quién esté ese día |

La recomendación es la segunda, y el argumento es concreto: **separar migración de despliegue permite
desplegar el código nuevo cuando quieras y revertirlo sin tocar la base**. Con la migración al
arrancar, la vuelta atrás del código puede dejar un esquema que el código viejo no entiende.

El orden completo de un cambio compatible:

```text
1. Migración (compatible con el código actual)  → pipeline, antes del despliegue
2. Despliegue del código nuevo                  → gradual
3. Verificación                                 → métricas y errores
4. Migración de contracción, más tarde          → otro pipeline, otro día
```

Fíjate en el paso 4: **la contracción no va en el mismo despliegue**. Se hace días después, cuando el
código nuevo lleva tiempo estable y ya no hay riesgo de tener que volver atrás.

---

## 6. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Migraciones versionadas con control de estado y suma de verificación; integración directa con el arranque de la aplicación | Resistir la comodidad del arranque: es el valor por defecto y acopla despliegue y esquema. Y elegir entre SQL y formato declarativo |
| **Node/TS** | Los clientes tipados generan migraciones a partir del cambio del esquema declarado | **Revisar siempre lo generado**: la generación automática resuelve bien lo simple y propone borrados peligrosos en lo demás |
| **Go** | Herramientas de migración como binario independiente: encajan de forma natural como paso del pipeline | Escribir el SQL a mano, que es una ventaja disfrazada: te obliga a mirar lo que va a pasar |
| **Python** | Generación automática de la diferencia entre el modelo y la base, con control de versiones | Lo mismo que en Node: revisar la diferencia generada. Detecta mal los renombrados y los propone como borrar + crear |

- **Lo que te deja a ti en las cuatro:** que la herramienta genere la migración **no** la hace segura.
  La generación automática de un renombrado produce casi siempre `DROP` + `ADD`, que es exactamente el
  cambio destructivo que este capítulo evita.
- Y ninguna de las cuatro sabe si tu tabla tiene cuarenta millones de filas ni si el índice se va a
  crear bloqueando. Eso es responsabilidad del que revisa.

> **🧰 Plataforma:** la pregunta de entrevista que separa a quien ha hecho esto de quien lo ha leído:
> *"¿qué hace tu herramienta cuando renombras un campo en el modelo?"*. Si la respuesta es "genera la
> migración sola", la siguiente pregunta es qué SQL genera — y casi siempre es borrar y crear.

---

## 7. 🩺 Vuelta atrás: lo que se puede deshacer y lo que no

```text
Cambio                          ¿Vuelta atrás?
──────────────────────────────  ─────────────────────────────────────────────
Añadir columna nullable         sí, trivial (o simplemente dejarla)
Backfill                        sí: los datos nuevos no molestan
Cambio de lectura en el código  sí: revertir el despliegue
Eliminar columna                NO: los datos ya no están
Cambio de tipo con pérdida      NO: la precisión perdida no vuelve
```

De ahí sale la regla operativa: **las migraciones destructivas se separan en el tiempo de todo lo
demás**. El despliegue que cambia comportamiento debe poder revertirse solo con el código; la
eliminación se hace días después, cuando ya nadie va a volver atrás.

Y la copia de seguridad no es un plan de vuelta atrás: restaurar una base grande tarda horas y pierde
lo escrito desde el punto de restauración. Sirve para el desastre, no para revertir un despliegue.

> **🩺 Diagnóstico:** si alguien propone desplegar un cambio de código y una eliminación de columna
> juntos, la pregunta es: *"si tenemos que revertir el código en diez minutos, ¿qué hacemos con la
> columna?"*. Esa pregunta suele reordenar el plan sola.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La migración corre al arrancar y ya" | Con varias instancias hace falta exclusión, y un fallo de migración se vuelve un bucle de reinicios |
| "Renombrar una columna es un cambio menor" | Es eliminar y añadir a la vez: rompe al código viejo durante todo el reemplazo. Expand/contract |
| "Paramos cinco minutos y migramos" | Opción legítima si el negocio la concede y la migración es rápida. Lo que no vale es asumirla sin preguntar |
| "El backfill lo lanzo con un `UPDATE`" | En tablas grandes bloquea, llena el log y, si falla, se pierde todo. Por lotes, con reanudación y con pausa |
| "La herramienta genera la migración sola" | Y en un renombrado genera borrar y crear. Lo generado se revisa siempre |
| "Si algo sale mal, restauramos la copia" | Restaurar tarda horas y pierde lo escrito desde el punto de restauración. No es un plan de vuelta atrás |
| "El cambio de esquema y el de código van juntos" | Entonces revertir el código deja un esquema incompatible. Van separados, y lo destructivo, días después |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Monolith to Microservices*, O'Reilly, 2019. Capítulo 4, con los patrones
   de cambio de esquema durante una separación. **El más directo para este capítulo.**
2. **Libro** — Martin Fowler, Pramod Sadalage y otros, *Refactoring Databases*, Addison-Wesley, 2006.
   Es el catálogo original de refactorizaciones de base de datos con sus pasos de transición.
3. **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017. Capítulo 4,
   "Encoding and Evolution": compatibilidad de datos y de esquema, con el marco conceptual.
4. **Fuente primaria** — Martin Fowler, «ParallelChange» (expand/contract), la formulación canónica:
   [martinfowler.com/bliki/ParallelChange.html](https://martinfowler.com/bliki/ParallelChange.html).
5. **Fuente primaria** — Martin Fowler, «EvolutionaryDatabaseDesign», con el papel de las migraciones
   versionadas:
   [martinfowler.com/articles/evodb.html](https://martinfowler.com/articles/evodb.html).
6. **Material de referencia** — Amazon Builders' Library, «Ensuring rollback safety during
   deployments», que es el marco de §7:
   [aws.amazon.com/builders-library/ensuring-rollback-safety-during-deployments/](https://aws.amazon.com/builders-library/ensuring-rollback-safety-during-deployments/).
7. **Charla** — GOTO Conferences, «Zero Downtime Database Migrations». Los ejemplos de bloqueos por
   migraciones "inocentes" son los que mejor se recuerdan.

---

## 🧠 Preguntas

1. ¿Por qué toda migración tiene que ser compatible con el código que ya corre? 🟢
2. Enumera los seis pasos de expand/contract sobre un renombrado de columna. 🟢
3. Nombra tres cambios de esquema seguros y tres inseguros. 🟢
4. ¿Cómo se hace un backfill correctamente? 🟢
5. ¿Cuáles son las tres opciones de quién ejecuta la migración? 🟢
6. ¿Qué cambios de esquema no tienen vuelta atrás? 🟢
7. ¿Por qué añadir una columna obligatoria sin valor por defecto rompe al código viejo? 🟡
8. ¿Qué significa que una migración sea "lógicamente segura y operativamente peligrosa"? 🟡
9. ¿Por qué el backfill por `OFFSET` se degrada y el de rango no? 🟡
10. ¿Por qué la contracción no va en el mismo despliegue que el cambio de código? 🟡
11. ¿Por qué una copia de seguridad no es un plan de vuelta atrás? 🟡
12. ¿Qué genera tu herramienta cuando renombras un campo, y por qué importa? 🟡
13. ¿Qué pondrías en la revisión de código de toda migración? 🟡
14. ¿Dónde se ejecuta la migración por defecto en cada plataforma, y por qué eso condiciona el
    despliegue? 🟡
15. Tienes que añadir una columna obligatoria a una tabla de 40 millones de filas. Da el plan. 🟠
16. ¿Cuándo aceptarías una ventana de parada en vez de expand/contract? 🟠
17. El backfill está degradando la base en horas punta. ¿Qué haces? 🟠
18. ¿Cómo garantizas que solo una instancia ejecuta la migración si corre al arrancar? 🟠
19. Hay que revertir el despliegue y la migración ya se ejecutó. ¿Qué evalúas? 🟠
20. ¿Cómo probarías una migración antes de producción, de forma realista? 🟠
21. Un cambio de tipo pierde precisión en el 0,1 % de las filas. ¿Cómo lo abordas? 🟠
22. Diseña el cambio completo de `amount` a `total` en una tabla grande: pasos, despliegues,
    backfill, verificación y contracción, con tiempos. 🔴
23. Diseña el proceso de backfill como componente: control, reanudación, ritmo, progreso y qué se
    monitoriza. 🔴
24. Diagnostica: tras una migración, el servicio empieza a dar timeouts en escrituras pero las
    lecturas van bien. Da tres hipótesis ordenadas. 🔴
25. Escribe la política de migraciones del equipo: qué se permite, qué se revisa, quién ejecuta y
    cómo se revierte. 🔴

---

**Anterior:** [`04` — Outbox, inbox e idempotencia](04-outbox-inbox-e-idempotencia.md) ·
**Siguiente:** [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) · **Relacionado:**
[`02-comunicacion/07`](../02-comunicacion/07-contratos-y-versionado.md) ·
[`01-fundamentos-y-descomposicion/03`](../01-fundamentos-y-descomposicion/03-el-camino-desde-el-monolito.md)

**Taller, opcional:** [`06/06` — Kafka: outbox, inbox, idempotencia y DLQ](../06-talleres/06-kafka-outbox-inbox-y-dlq.md).
