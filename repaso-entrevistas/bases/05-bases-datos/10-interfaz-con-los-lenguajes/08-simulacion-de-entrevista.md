# 08 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiséis transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los siete capítulos del
> bloque, de [`01`](01-el-driver-la-conexion-y-el-pool.md) a
> [`07`](07-clientes-de-redis-y-mongodb.md), y el bloque
> [`04`](../04-transacciones-y-concurrencia/README.md), del que salen las transacciones.
> **Vigencia:** 24 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. Este bloque tiene una dificultad propia: **casi todas sus respuestas
dependen del lenguaje**. La misma pregunta —qué pasa si se agota el *pool*, qué tipo llega de una
columna `numeric`— tiene cuatro respuestas, y la entrevista suele ser sobre el lenguaje del puesto.

- **Cronómetro a dos minutos por pregunta.** Y una regla de este bloque: **responde primero para el
  lenguaje del puesto**, y después di en una frase qué cambia en los otros. Es lo que distingue a
  quien sabe de su driver de quien sabe de drivers.
- **En voz alta.** Los valores por defecto se olvidan leyendo; se recuerdan diciéndolos con su
  consecuencia: *«treinta segundos, y durante esos treinta segundos la petición retiene su hilo»*.
- **Sin mirar los capítulos.** Cuando no recuerdes el número, di dónde lo mirarías: *«no recuerdo el
  valor por defecto de `pgxpool`; sé que depende de los núcleos y que lo leería de `ParseConfig`»*.
  Eso es una respuesta profesional. Inventarse el número, no.
- **Después, contra [`09`](09-respuestas.md).** Busca si nombraste la capa —motor, driver o
  biblioteca—, el valor por defecto y lo que cuesta cambiarlo.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿dónde se ve?»**: el log
> del *pool*, `pg_stat_activity`, el log del servidor con `log_statement`. Quien sabe dónde mirar el
> SQL real, las conexiones reales y los valores reales no necesita recordarlos todos.

---

## 2. 🧠 Transversales

### Conexión y *pool*

**S1.** Explica por qué abrir una conexión por petición es caro, con el número medido en el corpus y
en qué se va ese tiempo. 🟡

**S2.** Diez instancias de un servicio con un *pool* de 10 cada una, contra un PostgreSQL con los
valores de fábrica. ¿Qué pasa y qué harías? 🟠

**S3.** Un *pool* de dos conexiones recibe tres peticiones que tardan 2 s. Di qué pasa con la
tercera en HikariCP, psycopg-pool, `pg.Pool` y `pgxpool`, con sus valores por defecto. 🟡

**S4.** En Go, el mismo `context` de 1 s cubre la espera del *pool* y una consulta de 2 s. Di qué ve
el cliente y qué registra el servidor. 🟠

---

### Parámetros e inyección

**S5.** Un compañero dice que un parámetro «escapa las comillas mejor que tú». Corrígelo y explica
qué hace de verdad. 🟡

**S6.** Nombra cuatro cosas que un parámetro no protege, con la forma correcta de cada una en
PostgreSQL. 🟢

**S7.** Una búsqueda concatenada recibe `x'; DROP TABLE pagos; --` y `pagos` sigue ahí. Explica por
qué se ejecutó el `DROP` y qué lo paró. 🟠

**S8.** El log de tu ORM enseña la consulta con los valores dentro del texto. ¿Hay inyección? ¿Cómo
lo compruebas? 🟡

---

### Tipos

**S9.** ¿Cómo llega una columna `numeric` a Java, a Python, a TypeScript y a Go, y en cuál de los
cuatro es una trampa? 🟡

**S10.** El informe de «pedidos de ayer» da cifras distintas desde un servicio Java y desde uno
Python. Da el mecanismo exacto y la corrección. 🟠

**S11.** En Node, un pedido creado a las 03:08 aparece a las 08:08. Da la causa y el arreglo. 🟠

**S12.** Una columna nula, leída en Java con `getLong` y en Go con `Scan` a un `int64`. ¿Qué pasa en
cada uno, y cuál prefieres? 🟡

---

### Transacciones y resultados grandes

**S13.** ¿Qué driver del corpus abre una transacción sin que se lo pidas, y qué problema produce eso
en un servicio? 🟢

**S14.** Un servicio captura el error del segundo paso de una transacción y confirma. ¿Qué queda en
la base, y cuál de los cuatro drivers te lo dice? 🟠

**S15.** La exportación nocturna muere por memoria. Explica qué hace cada driver por defecto con un
resultado grande, y la trampa específica de pgjdbc. 🟠

**S16.** ¿Cuál es la forma más barata de exportar un millón de pedidos a CSV, y qué retiene en la
base mientras dura? 🟡

---

### Los ecosistemas

**S17.** Ordena las capas de acceso a datos de Java de menos a más abstracción y di quién escribe el
SQL en cada una. 🟢

**S18.** Explica `REQUIRES_NEW` en Spring: qué conexión usa, qué pasa con sus escrituras si la
externa falla, y por qué puede agotar el *pool*. 🟠

**S19.** Distingue sqlc de GORM: qué escribe el programador, qué genera la herramienta y cuándo
elegirías cada uno. 🟡

**S20.** ¿Por qué no elegirías hoy Apache Derby para un proyecto nuevo? 🟢

---

### Redis y MongoDB

**S21.** El servidor de Redis desaparece. Di qué hacen redis-py, Jedis, node-redis y go-redis con su
configuración por defecto. 🟠

**S22.** ¿Por qué la espera por defecto de los drivers de MongoDB puede tumbar el acceso a
PostgreSQL de un servicio que usa los dos? 🟠

---

## 3. 🧠 Las que descolocan

**S23.** «Con un ORM no hay inyección SQL». Refútalo con un ejemplo concreto del bloque. 🟠

**S24.** «Si el `commit()` no dio error, está guardado». ¿Cuándo es falso, y en qué drivers? 🟠

**S25.** ¿Hay algo de este bloque en el estándar SQL? Responde en una frase y di qué se sigue para
una entrevista. 🟡

**S26.** «Un *pool* más grande aguanta más carga». Refútalo con dos argumentos del bloque. 🟡

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa no es que
aciertes, es **que distingas qué es del motor, qué del driver y qué de tu código**, y que no
propongas cambiar el motor cuando el fallo es de configuración.

### Escenario 1 — El servicio en Node que se cuelga en la campaña

Un servicio de pedidos en Node con `pg.Pool` de fábrica se queda colgado en la hora punta de una
campaña. La base está tranquila: CPU al 20 %, sin bloqueos. Los reinicios del servicio lo arreglan
durante unos minutos. El equipo propone subir el *pool* a 50.

**Entregas:** la hipótesis más probable y las dos alternativas; qué mirarías en `pg_stat_activity` y
en el propio *pool* para distinguirlas; qué parámetro falta y por qué subir el *pool* no lo arregla;
y la configuración que propones, con cada valor justificado.

### Escenario 2 — La conciliación que no cuadra

La conciliación mensual compara los pagos del día según tres servicios —Java, Python y Node— contra
la base. Los totales difieren en céntimos y algunos pagos «de ayer» aparecen en días distintos. La
base está bien: la consulta directa en `psql` da la cifra correcta.

**Entregas:** las tres causas posibles, una por tipo de trampa —dinero, fechas y zona de la sesión—;
en qué servicio aparece cada una y por qué; la regla común que impondrías en los tres; y cómo
comprobarías que la corrección funciona sin esperar al próximo mes.

### Escenario 3 — El proyecto Java de diez años

Heredas un servicio Java con `JdbcTemplate`, JPA con Hibernate, un módulo de MyBatis con consultas
en XML, pruebas contra H2 en memoria, y una herramienta interna que guarda su configuración en
Derby. Tienes un trimestre para dejarlo mantenible.

**Entregas:** qué capa dejarías para qué uso y qué retirarías; qué riesgo tiene cada pieza que se
queda; el orden de los cambios; y qué harías con Derby y con H2, distinguiendo los dos casos.

### Escenario 4 — Treinta segundos cuando cae MongoDB

El panel de pedidos lee de PostgreSQL y, para cada pedido, su histórico de MongoDB. Cuando MongoDB
pierde la red, el panel tarda 30 s en cada página y, a los pocos minutos, también fallan las
pantallas que solo usan PostgreSQL. El equipo propone subir el *pool* de PostgreSQL y añadir índices
a `pedidos`.

**Entregas:** por qué ninguna de las dos propuestas ataca la causa; de dónde salen los 30 s y por
qué se contagian a PostgreSQL; el diseño que propones para que una caída de MongoDB degrade el panel
en vez de tumbarlo; y qué parte de ese diseño es del cliente y cuál de la aplicación. Este escenario
tiene truco: **la respuesta correcta empieza por decir que esto no lo resuelve la base de datos**, y
sigue por decir qué capa sí.

> **⚠️ Advertencia.** Aceptar el marco —*«subo el pool y creo los índices»*— es el fallo que más
> caro sale aquí: el *pool* más grande solo aguanta más peticiones esperando a MongoDB, y ningún
> índice acelera una espera de red. Se espera que nombres el valor por defecto que produce los 30 s,
> la retención de conexiones de PostgreSQL durante esa espera, y la degradación como decisión de la
> aplicación.

---

## 5. 💡 Las frases que hay que tener listas

Dichas tal cual, sin adornos. Son las que cierran una respuesta y las que hacen que la siguiente
pregunta sea mejor.

- «Una conexión de PostgreSQL es un proceso del servidor. Se abre una vez y se usa miles.»
- «El techo de conexiones es de la base, no del servicio: se reparte entre todas las instancias.»
- «El valor por defecto del *pool* no es una decisión: es la de otra persona.»
- «Un parámetro no escapa mejor: hace que el dato no pase por el analizador.»
- «Los nombres de columna no son parámetros: se eligen de una lista blanca.»
- «El dinero se lee a un decimal exacto o se deja en texto. Nunca a coma flotante.»
- «La zona horaria de la sesión la puede fijar el driver. Los informes por día la fijan en la
  consulta.»
- «Si capturas el error dentro de la transacción, el `COMMIT` se convierte en `ROLLBACK`, y dos de
  los cuatro drivers no te lo dicen.»
- «Lo que crece con la tabla se lee por tramos, y el tramo se pide.»
- «`REQUIRES_NEW` no es una transacción anidada: es otra conexión.»
- «El log de mi ORM es para leer. Lo que recibe la base lo dice el log del servidor.»
- «Un cliente de caché tiene que fallar en milisegundos, o la caché deja de ser opcional.»
- «Esto no lo resuelve la base de datos. Lo que la base de datos aporta aquí es la mitad, y te digo
  cuál.»

---

**Anterior:** [`07`](07-clientes-de-redis-y-mongodb.md) — los clientes de Redis y MongoDB ·
**Siguiente:** [`09`](09-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
