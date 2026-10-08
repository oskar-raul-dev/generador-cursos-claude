# 04 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veinticuatro transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los tres capítulos del bloque,
> de [`01`](01-funciones-y-procedimientos.md) a [`03`](03-claves-generadas.md).
> **Vigencia:** 27 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. En este bloque la pregunta suele llegar como un juicio —«¿los
procedimientos almacenados son mala práctica?», «¿los disparadores son el demonio?», «¿por qué no
UUID?»— y la respuesta buena no toma partido: **dice qué se mide, qué se paga y quién más escribe en
esa tabla**.

- **Cronómetro a dos minutos por pregunta.** Y la regla del bloque: **cada opinión con su cifra**.
  *«Desde el cliente fueron 6,2 s, en PL/pgSQL 888 ms y en una sentencia 470»* acaba con la
  discusión de dónde va la lógica.
- **En voz alta.** Los mecanismos se recuerdan diciéndolos con su efecto: *«la función era
  `VOLATILE`, así que el motor la llamó un millón de veces»*.
- **Sin mirar los capítulos.** Cuando no recuerdes una cifra, di cómo la verías: *«lo miraría con
  `EXPLAIN (ANALYZE)`: el tiempo de cada disparador sale al final»*.
- **Después, contra [`05`](05-respuestas.md).** Busca si separaste lo del motor de lo que es
  convención, y si dijiste qué pasa con dos sesiones a la vez.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿y si llegan dos a la
> vez?»**. El disparador de integridad, la secuencia sin huecos y el procedimiento que confirma por
> lotes cambian de respuesta en cuanto hay concurrencia.

---

## 2. 🧠 Transversales

### Funciones y procedimientos

**S1.** ¿Qué diferencia una función de un procedimiento, y qué puede hacer el segundo que la primera
no? 🟢

**S2.** Una función sencilla en SQL y otra en PL/pgSQL hacen lo mismo. ¿Por qué solo la segunda
puede hundir un plan? 🟡

**S3.** Explica la trampa de la volatilidad con la sesión: qué plan salió con `VOLATILE` y cuál con
`STABLE`. 🟠

**S4.** ¿Cuánto costaron las idas y vueltas al anular 10 929 pedidos, y qué forma fue la más
rápida? 🟠

**S5.** ¿Por qué un bloque `EXCEPTION` cuesta aunque no salte ningún error? 🟡

**S6.** ¿Por qué un procedimiento que confirma por lotes puede fallar al llamarlo desde una
aplicación? 🟠

**S7.** ¿Dónde programarías la anulación nocturna de pedidos, y por qué no dentro de la base? 🟡

### Disparadores

**S8.** Da los tres usos legítimos de un disparador y el coste medido de dos de ellos. 🟡

**S9.** Fila o sentencia: ¿qué ahorra un disparador por sentencia y qué no? 🟠

**S10.** ¿Por qué mantener un total con un disparador cuesta más de lo que parece? 🟠

**S11.** Una regla de integridad comprobada en un disparador pasa todas las pruebas y falla en
producción. ¿Por qué? 🔴

**S12.** ¿Qué motores del curso tienen disparadores por sentencia? 🟢

**S13.** ¿En qué orden se ejecutan dos disparadores del mismo evento en PostgreSQL y en MySQL? 🟡

### Claves generadas

**S14.** ¿Por qué una secuencia tiene huecos, y por qué no es un error? 🟢

**S15.** ¿Cómo se desincroniza una secuencia, y qué opción de `IDENTITY` lo impide? 🟡

**S16.** ¿Qué hace SQLite con el identificador de una fila borrada? 🟡

**S17.** UUIDv4 frente a UUIDv7 frente a `bigint`: las tres cifras que hay que saber. 🟠

**S18.** ¿Por qué en InnoDB una clave primaria aleatoria engorda también los índices secundarios? 🟠

**S19.** ¿Cuándo sí usarías UUID como clave? 🟠

---

## 3. 🧠 Las que descolocan

**S20.** «Los procedimientos almacenados son una mala práctica». ¿Qué parte es cierta? 🟠

**S21.** «La lógica en la base es más rápida». Matízalo con los números del bloque. 🟠

**S22.** «Con un disparador, la regla se cumple siempre». Refútalo. 🔴

**S23.** «Los huecos en los números de pedido indican pedidos perdidos». Corrígelo. 🟡

**S24.** «UUID es la clave moderna; `bigint` es de otra época». Refútalo con números. 🔴

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa es **que se
mida antes de mover lógica de sitio**, y que no se meta en la base lo que depende de otros sistemas.

### Escenario 1 — El cierre de mes que tarda una hora

El proceso de cierre de mes lee los pedidos del mes desde un servicio en Java, calcula comisiones
fila a fila y escribe un registro por pedido. Tarda una hora, y el equipo propone reescribirlo como
un procedimiento almacenado de mil líneas.

**Entregas:** dónde crees que se va la hora y cómo lo comprobarías; qué parte movería a la base y en
qué forma —sentencia, función o procedimiento—; cómo confirmarías por lotes y reanudarías si falla;
y qué dejarías en el servicio.

### Escenario 2 — La auditoría que nadie se salta

Cumplimiento exige saber quién cambió cada pedido, qué había antes y cuándo, incluidos los cambios
hechos a mano en la consola. Hoy la aplicación escribe la auditoría, y los cambios de consola no
quedan registrados.

**Entregas:** el diseño del disparador —granularidad, qué columnas guardas, dónde—; el coste que
esperas, con los números del bloque; cómo registras el usuario real cuando la aplicación entra con
un solo rol; y qué pasa con la auditoría durante una carga masiva.

### Escenario 3 — Pedidos duplicados en la campaña

Durante una campaña, varios clientes acaban con dos pedidos pendientes, aunque hay un disparador que
lo impide. En preproducción nunca ha pasado. Además, al restaurar ayer una copia parcial, los
pedidos nuevos fallaron por clave duplicada durante veinte minutos.

**Entregas:** la causa de cada síntoma; cómo reproducirías el primero; dos correcciones para el
primero, con lo que cuesta cada una; y cómo evitarías el segundo en la próxima restauración.

### Escenario 4 — «El sistema de facturación falla: pongamos las facturas en la base»

La facturación la hace un servicio que llama a un proveedor externo para firmar cada factura. A
veces el proveedor tarda y las facturas se quedan a medias. Alguien propone moverlo todo a un
procedimiento almacenado «para que sea transaccional». Este escenario tiene truco: **la respuesta
correcta empieza por decir que esto no lo resuelve la base de datos**, y sigue por decir qué lo
resuelve.

**Entregas:** por qué meter la llamada al proveedor dentro de una transacción de la base empeora el
problema; qué patrón usarías para que ninguna factura quede a medias; qué parte sí puede vivir en la
base —la numeración sin huecos, el estado—; y cómo reintentarías sin firmar dos veces.

> **⚠️ Advertencia.** Aceptar el marco —*«si está en la base, es transaccional»*— es el fallo que
> más caro sale aquí: la transacción de la base no alcanza al proveedor, y mantenerla abierta
> mientras se espera a la red retiene bloqueos, como la transacción larga de
> [`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md).

---

## 5. 💡 Las frases que hay que tener listas

- «La lógica que cambia va fuera; el trabajo sobre muchas filas, donde están las filas.»
- «Antes que una función, una sentencia por conjuntos.»
- «Una función sin volatilidad declarada es `VOLATILE`, y no sirve en la condición de un índice.»
- «Un bloque `EXCEPTION` es una subtransacción, salte o no el error.»
- «Un procedimiento solo confirma si se le llama fuera de una transacción.»
- «Un disparador es código que corre dentro de la sentencia de otro.»
- «Si la regla cabe en una restricción, no va en un disparador.»
- «Una regla que mira otras filas tiene una carrera en `READ COMMITTED`.»
- «Las claves generadas tienen huecos por diseño; una numeración sin huecos es otra columna.»
- «UUIDv4 paga ancho y desorden; UUIDv7 paga solo el ancho.»
- «En InnoDB, la clave primaria viaja en todos los índices secundarios.»
- «Una llamada a la red no cabe en una transacción de la base.»

---

**Anterior:** [`03`](03-claves-generadas.md) — claves generadas · **Siguiente:**
[`05`](05-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
