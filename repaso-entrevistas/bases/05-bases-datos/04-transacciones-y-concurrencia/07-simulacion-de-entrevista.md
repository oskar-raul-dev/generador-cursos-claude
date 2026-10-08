# 07 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiséis transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los seis capítulos del bloque,
> de [`01`](01-acid-con-precision.md) a [`06`](06-wal-durabilidad-y-fsync.md), y los bloques
> [`01`](../01-fundamentos-y-modelo-relacional/README.md), [`02`](../02-sql/README.md) y
> [`03`](../03-el-motor-por-dentro/README.md). **Vigencia:** 22 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. Este bloque tiene una dificultad que los tres anteriores no tenían:
**casi todas sus respuestas son una secuencia en el tiempo**. Quién abrió primero, quién esperó a
quién, qué vio cada uno y en qué momento. Una respuesta que lo cuenta todo junto, sin orden, suena a
recitada aunque los datos estén bien.

- **Cronómetro a dos minutos por pregunta.** Y una regla de este bloque: cuando la respuesta tenga
  dos sesiones, **nómbralas y cuéntalas en orden** —«A abre, B abre, A escribe, B espera»—. Es lo
  que un entrevistador dibuja en la pizarra mientras hablas.
- **En voz alta.** Los niveles de aislamiento se entienden leyendo; distinguir en voz alta lo que
  dice el estándar de lo que hace tu motor es lo que de verdad se practica.
- **Sin mirar los capítulos.** Y cuando no recuerdes el detalle, di de qué depende: *«no recuerdo el
  valor por defecto de InnoDB; sé que es de decenas de segundos y que PostgreSQL no tiene ninguno»*.
  Eso es una respuesta profesional. Inventarse el número, no.
- **Después, contra [`08`](08-respuestas.md).** No busques coincidencia palabra a palabra: busca si
  dijiste el mecanismo, el precio en alguna de las tres monedas —espera, reintentos, abortos— y de
  quién es la regla: estándar, motor o convención.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La apertura que sirve para casi cualquier pregunta de concurrencia es
> **«depende de qué motor, y de si hablamos del estándar»**. No es una evasiva: el estándar define
> qué anomalías se toleran y ningún mecanismo, y los dos motores principales cumplen la misma tabla
> con mecanismos opuestos. Lo que la hace valiosa es poder seguirla con el caso concreto.

---

## 2. 🧠 Transversales

### ACID y el ámbito de la transacción

**S1.** Recita las cuatro letras de ACID y, de cada una, di **dónde termina**: qué caso concreto no
cubre. 🟡

**S2.** Una conexión vuelve al *pool* con una transacción abierta porque un camino de error no hizo
ni `COMMIT` ni `ROLLBACK`. Di qué le pasa a la siguiente petición que la toma y qué le pasa a la
base mientras tanto. 🟠

**S3.** La misma migración, con tres `ALTER TABLE` dentro de un `BEGIN`, falla en el segundo. Di
cómo queda el esquema en PostgreSQL y cómo en MySQL, y qué categoría es esa diferencia. 🟡

---

### Aislamiento

**S4.** «`REPEATABLE READ` evita las lecturas fantasma». Da las tres respuestas: la del estándar, la
de PostgreSQL y la de InnoDB, cada una con su porqué. 🟡

**S5.** Un informe cuenta los pedidos pendientes dos veces en la misma transacción y obtiene 120 000
y 120 001. Nombra la anomalía, di por qué es posible con la configuración de fábrica de PostgreSQL y
da la corrección con su precio. 🟠

**S6.** Un servicio migra de MySQL a PostgreSQL sin tocar una línea y el nivel de aislamiento cambia
sin que nadie lo decida. Di de cuál a cuál, y qué anomalía nueva puede aparecer y cuál desaparece. 🟠

**S7.** «Un pedido anulado no puede tener más de un pago de compensación». Dos operadores lo
comprueban a la vez y los dos insertan. Nombra la anomalía, di por qué `REPEATABLE READ` no la ve en
PostgreSQL, y da dos formas de impedirla. 🟠

---

### Versiones de fila

**S8.** Di dónde vive la versión antigua de una fila en PostgreSQL y dónde en InnoDB, y qué fichero
crece en cada uno cuando alguien deja una transacción abierta. 🟡

**S9.** Un `ROLLBACK` de un millón de filas termina al instante en un motor y tarda más que el
trabajo original en el otro. Di cuál es cuál y el mecanismo. 🟠

**S10.** La tabla `pedidos` ocupa el triple de lo que pesan sus filas vivas y el autovacuum corre
sin liberar nada. Da la cadena completa desde la causa más probable hasta el disco lleno, y la
primera consulta que lanzarías. 🟠

---

### Bloqueos

**S11.** Un `ALTER TABLE … ADD COLUMN` que tarda un milisegundo tumbó el sitio diez minutos. Explica
el mecanismo y la defensa de dos líneas. 🟠

**S12.** Te proponen subir el tiempo de espera de bloqueo para que dejen de aparecer interbloqueos.
Di por qué no sirve y cuál es la única solución completa. 🟡

**S13.** Diez trabajadores sacan tareas de la misma tabla de pedidos pendientes. Di qué pasa sin
`SKIP LOCKED`, qué pasa con él, y qué se pierde al usarlo. 🟡

**S14.** Tu bucle de reintento captura `SQLSTATE 40001`. Di qué errores de concurrencia cubre en
PostgreSQL y en MySQL, y cuál se le escapa en PostgreSQL. 🟠

---

### Optimista, pesimista y transacciones largas

**S15.** Un operador abre un pedido en el panel, tarda tres minutos y guarda. ¿`FOR UPDATE` o
columna de versión? Defiende una y di por qué la otra no puede funcionar aquí. 🟡

**S16.** Tu guardado optimista recibe `UPDATE 0`. Di qué significa, qué tiene que hacer la
aplicación, y en qué caso el mismo `0` miente en MySQL. 🟠

**S17.** Una sesión hizo `FOR UPDATE` en `READ COMMITTED` y lleva diez minutos ociosa, con
`backend_xmin` vacío en `pg_stat_activity`. ¿Frena la limpieza de la base? ¿Y a quién más estorba? 🟠

**S18.** Activas `idle_in_transaction_session_timeout` y al día siguiente el *pool* reparte
conexiones muertas. Di por qué y qué arreglo es el de verdad. 🟡

---

### Durabilidad

**S19.** ¿Qué tiene que estar en disco para que PostgreSQL responda `COMMIT`? Contéstalo con las dos
posiciones del registro que se pueden consultar desde `psql`. 🟡

**S20.** Con `synchronous_commit = off`, ¿cuánto puedes perder, qué nunca pierdes, y hace falta un
corte de corriente para perderlo? 🟠

**S21.** `pg_test_fsync` dice que tu disco hace 9 300 volcados por segundo. Di por qué eso no prueba
que sea durable y qué lo probaría. 🟠

**S22.** ¿Qué hace PostgreSQL al arrancar después de una caída, y qué dos parámetros acotan cuánto
tarda? 🟢

---

## 3. 🧠 Las que descolocan

**S23.** «Con transacciones no hay condiciones de carrera». Refútalo con **dos** casos de este
bloque, uno con el nivel por defecto y otro con `REPEATABLE READ`. 🟠

**S24.** ¿Cuáles de estas cosas están en el estándar SQL: los cuatro niveles de aislamiento, MVCC,
`FOR UPDATE`, `SKIP LOCKED`, el WAL y el nivel por defecto? Una palabra por cada una, y la
consecuencia para una entrevista. 🟡

**S25.** «Si el motor dijo `UPDATE 1` y `COMMIT`, está guardado». Da tres situaciones en que eso es
falso, de la más probable a la menos. 🟠

**S26.** «InnoDB en `REPEATABLE READ` protege mejor que PostgreSQL, porque bloquea en vez de
abortar». Refútalo con lo que hace cada uno cuando dos transacciones escriben la misma fila. 🟠

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa no es que
aciertes, es **que nombres el mecanismo antes que la solución**, y que digas qué paga cada opción.

### Escenario 1 — Los pagos que superan el total

Regla de negocio: **la suma de los pagos de un pedido no puede superar su total**. Hoy vive en el
servicio: lee la suma, la compara con `pedidos.total` y, si cabe, inserta en `pagos`. En producción
aparecen, dos o tres veces por semana, pedidos con más pagado que total, siempre con dos pagos del
mismo segundo. PostgreSQL 18.6, nivel por defecto.

**Entregas:** el nombre de la anomalía y por qué el nivel por defecto no la ve; tres formas de hacer
cumplir la regla, de la más barata a la más cara, con lo que cuesta cada una en espera, reintentos o
abortos; cuál eliges y por qué; y cómo comprobarías, sin esperar a producción, que la elegida
funciona.

### Escenario 2 — La base que engorda y los despliegues que se cuelgan

En dos semanas `pedidos` ha pasado de 84 MB a 250 MB sin que cambie el número de pedidos, el informe
nocturno tarda el doble, y dos despliegues seguidos se quedaron colgados en un `ALTER TABLE` hasta
que alguien reinició el servicio. El equipo propone un `VACUUM FULL` el domingo.

**Entregas:** la hipótesis que explica los tres síntomas a la vez; las dos consultas que la
confirman en menos de un minuto; por qué el `VACUUM FULL` no arregla la causa y qué cuesta lanzarlo;
y las tres medidas —de configuración y de código— que impiden que vuelva a pasar.

### Escenario 3 — El Black Friday y el `COMMIT` que no espera

Producto quiere duplicar la capacidad de escritura para el Black Friday. Alguien ha medido que con
`synchronous_commit = off` el servidor confirma el doble de transacciones por segundo, y propone
ponerlo en todo el servidor esa semana. Otra persona propone ir más allá y apagar `fsync`.

**Entregas:** qué se pierde exactamente con cada propuesta, con el número y su origen; qué tablas
aceptarías relajar y cuáles no, y con qué sentencia lo harías sin tocar el servidor; qué medirías
antes de decidir; y qué le dirías a quien propone apagar `fsync`.

### Escenario 4 — El pedido pagado que el inventario no descontó

`pedidos` vive en PostgreSQL; las existencias las lleva otro servicio con su propia base. Al pagar,
el servicio de pedidos confirma el pago y llama por HTTP al de inventario para descontar. Una de
cada mil llamadas falla por tiempo de espera, y el pedido queda pagado sin descontar existencias. Tu
jefe pide «una transacción que abarque las dos bases» o, si no se puede, «subir a `SERIALIZABLE`».

**Entregas:** por qué ninguna de las dos peticiones resuelve el problema; qué parte **sí** aporta la
base de datos del servicio de pedidos; y el diseño que propones para que el descuento ocurra
**exactamente una vez** aunque la llamada falle o se repita. Este escenario tiene truco: **la
respuesta correcta empieza por decir que esto no lo resuelve la base de datos**, y sigue por acotar
qué mitad sí.

> **⚠️ Advertencia.** Aceptar el marco —*«subo a `SERIALIZABLE`»*— es el fallo que más caro sale
> aquí, porque el aislamiento es de **una** base y de **una** transacción, y la llamada HTTP no está
> dentro de ninguna. Se espera que digas en voz alta qué letra de ACID se está pidiendo —la A— y por
> qué no existe entre dos motores sin un protocolo aparte, antes de proponer nada.

---

## 5. 💡 Las frases que hay que tener listas

Dichas tal cual, sin adornos. Son las que cierran una respuesta y las que hacen que la siguiente
pregunta sea mejor.

- «Siempre estás dentro de una transacción. Lo único que decides es su tamaño.»
- «La A garantiza que no quede media escritura tuya. No dice nada de lo que hace el de al lado.»
- «El estándar dice qué anomalías se toleran, no cómo se evitan. Por eso dos motores con el mismo
  nivel se comportan distinto.»
- «`REPEATABLE READ` son tres respuestas: la del estándar, la de PostgreSQL y la de InnoDB.»
- «Una instantánea no es una copia: es una fecha de corte.»
- «En un motor MVCC leer no bloquea escribir. Lo único que se espera es escritor contra escritor.»
- «Un interbloqueo no es un problema de carga: es un problema de orden.»
- «Lo que tumba el sitio no es el `ALTER`: es la cola que se forma detrás.»
- «El optimista gana en la web porque es el único que sobrevive a una pausa humana.»
- «`UPDATE 0` no es un error. Si no lo miras, el control optimista no existe.»
- «Una transacción ociosa no gasta CPU: gasta el horizonte de toda la base.»
- «"Confirmado" significa descrito en un registro que está en disco, en una máquina.»
- «`synchronous_commit = off` pierde transacciones enteras; `fsync = off` pierde la base.»
- «Esto no lo resuelve la base de datos. Lo que la base de datos aporta aquí es la mitad, y te digo
  cuál.»

---

**Anterior:** [`06`](06-wal-durabilidad-y-fsync.md) — qué significa «confirmado» · **Siguiente:**
[`08`](08-respuestas.md) — las respuestas, con las de esta simulación al final · **Volver:** [README
del bloque](README.md).
