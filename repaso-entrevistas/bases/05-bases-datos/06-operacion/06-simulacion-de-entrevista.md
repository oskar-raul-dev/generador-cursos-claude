# 06 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiséis transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los cinco capítulos del
> bloque, de [`01`](01-usuarios-roles-y-permisos.md) a [`05`](05-monitorizacion-y-mantenimiento.md).
> **Vigencia:** 27 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. Las preguntas de operación llegan casi siempre como una historia —«un
lunes la base se paró», «el despliegue borró datos»— y la respuesta buena **nombra el mecanismo,
dice cómo se comprueba y qué se hace para que no vuelva a pasar**.

- **Cronómetro a dos minutos por pregunta.** Y la regla del bloque: **cada política con su número**.
  *«Un volcado nocturno es un RPO de 24 horas»* es una respuesta; *«tenemos respaldos»*, no.
- **En voz alta.** Los mecanismos se recuerdan diciéndolos con su efecto: *«la lectura se quedó en
  la cola detrás del `ALTER`»*.
- **Sin mirar los capítulos.** Cuando no recuerdes una cifra, di cómo la verías: *«lo miraría en
  `pg_stat_activity`, buscando `idle in transaction`»*.
- **Después, contra [`07`](07-respuestas.md).** Busca si dijiste cómo se comprueba, y si separaste
  lo del motor de lo que es convención de operación.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿quién tiene la tabla
> abierta?»**. La cola de bloqueos, las filas muertas que no se limpian y la migración que no llega
> a aplicarse empiezan todas por una transacción que alguien dejó abierta.

---

## 2. 🧠 Transversales

### Roles y permisos

**S1.** ¿Qué es mínimo privilegio para la aplicación de la tienda, en tres permisos que no tiene? 🟡

**S2.** Una migración crea una tabla y la aplicación no puede leerla. ¿Por qué, y cómo se evita? 🟠

**S3.** ¿Qué diferencia hay entre conceder un rol en PostgreSQL y en MySQL? 🟡

**S4.** ¿Por qué se conceden los permisos a roles de grupo y no a personas? 🟢

### Respaldos

**S5.** Explica el RPO y el RTO con los números de las estrategias del bloque. 🟠

**S6.** ¿Por qué un respaldo que no se ha restaurado no existe, si `pg_verifybackup` dice que está
bien? 🟠

**S7.** ¿Qué pasa si se restaura una sola tabla con `pg_restore -t` y se pone en producción? 🟠

**S8.** Lógico o físico: ¿qué usarías para volver al segundo anterior a un `DELETE` sin `WHERE`? 🟡

**S9.** ¿Cómo se respalda en caliente una base SQLite? 🟢

### Migraciones

**S10.** ¿Por qué no se edita una migración ya aplicada? 🟡

**S11.** La misma migración falla a la mitad en PostgreSQL y en MySQL. ¿Qué queda en cada una? 🟠

**S12.** ¿Qué hizo Alembic con un renombrado de columna, y cómo se evita? 🟠

**S13.** ¿Qué es la línea base de Flyway, y cuál es su trampa? 🟡

### Cambios sin parar

**S14.** Da los cinco pasos de expandir y contraer para renombrar una columna. 🟢

**S15.** ¿Por qué un `ALTER TABLE` de un milisegundo puede parar la tienda? 🔴

**S16.** ¿Qué `ADD COLUMN` es instantáneo y cuál reescribe la tabla? 🟡

**S17.** ¿Cómo se crea un índice y se añade un `NOT NULL` en una tabla en uso? 🟠

### Salud

**S18.** ¿Cómo encuentras la consulta que más carga la base? 🟡

**S19.** ¿Qué hace una transacción olvidada con la limpieza de la base? 🟠

**S20.** ¿Por qué la tabla no encoge tras un `VACUUM`, y qué cuesta encogerla? 🟠

**S21.** ¿Qué tiene MySQL en lugar de `pg_stat_statements`? 🟢

---

## 3. 🧠 Las que descolocan

**S22.** «Tenemos réplica en otra zona, así que estamos cubiertos». ¿Qué parte es cierta? 🟠

**S23.** «Las migraciones del ORM son seguras porque las genera la herramienta». Refútalo. 🟠

**S24.** «Las lecturas nunca se bloquean en PostgreSQL». Refútalo con la sesión. 🔴

**S25.** «`VACUUM` libera espacio en disco». ¿Qué parte es cierta? 🟡

**S26.** «Si la base va lenta, hay que darle más máquina». Refútalo con números. 🔴

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa es **que se diga
cómo se comprueba cada cosa**, y que no se proponga un cambio de motor ni de máquina para lo que
arregla un índice, un permiso o un `lock_timeout`.

### Escenario 1 — El lunes que se paró la tienda

Un lunes a las diez, durante un despliegue que añadía una columna a `clientes`, todas las pantallas
de clientes dejan de responder durante tres minutos. El `ALTER` registrado tardó 4 ms. Esa noche,
además, la base había crecido 3 GB sin que se insertaran más pedidos de lo normal.

**Entregas:** la causa probable de los dos síntomas y la consulta que confirma cada una; qué harías
en el momento para desbloquear; qué cambiarías en el despliegue y en la configuración; y cómo
recuperarías el espacio sin parar la tabla.

### Escenario 2 — El borrado accidental

Un script de limpieza borra 300 000 pagos de producción a las 11:42. Se detecta a las 12:10. La
política actual es un volcado lógico cada noche a las tres, copiado al mismo servidor.

**Entregas:** qué datos se pueden recuperar con la política actual y cuáles se pierden, con el RPO;
cómo los recuperarías sin tocar el resto de la base; qué política propondrías para que la próxima
vez se pierda como mucho un minuto; y cómo demostrarías que la nueva política funciona.

### Escenario 3 — La migración que no cuadra

Tras un despliegue, en preproducción funciona todo, pero en producción la columna `descuento` de los
cupones aparece vacía, y además la aplicación falla con «permission denied» en una tabla nueva. La
migración la generó el ORM y la aplicó la propia aplicación al arrancar.

**Entregas:** la causa de cada síntoma; por qué en preproducción no se vio; cómo recuperarías los
descuentos; y el flujo de migraciones que propondrías, con herramientas y roles.

### Escenario 4 — «La base va lenta: migremos a una instancia el doble de grande»

La base de la tienda va lenta desde hace un mes, y la propuesta es duplicar la instancia. Este
escenario tiene truco: **la respuesta correcta empieza por decir que esto no lo resuelve una base
más grande**, y sigue por decir qué lo resuelve.

**Entregas:** qué mirarías primero y dónde; qué esperarías encontrar, con los números del bloque;
qué corregirías antes de tocar la instancia; y en qué caso sí propondrías una instancia mayor.

> **⚠️ Advertencia.** Aceptar el marco —*«la base necesita más recursos»*— es el fallo que más caro
> sale aquí: en diez segundos de carga, una consulta sin índice era el 99 % del tiempo, y una
> transacción olvidada puede impedir la limpieza de toda la base. Ninguna de las dos cosas la
> arregla una máquina mayor.

---

## 5. 💡 Las frases que hay que tener listas

- «La aplicación no crea tablas, no las vacía y no se conecta como superusuario.»
- «`GRANT ON ALL TABLES` no cubre las tablas futuras; eso son los privilegios por defecto.»
- «Un volcado nocturno es un RPO de 24 horas.»
- «Un respaldo que no se ha restaurado no existe.»
- «Una réplica replica también el `DELETE` sin `WHERE`.»
- «Una migración aplicada no se edita; se escribe otra.»
- «En MySQL, cada DDL confirma solo: una migración, una sentencia.»
- «El ORM no detecta renombrados: los genera como borrado y alta.»
- «Lo que para la tienda no es el `ALTER`, es su espera.»
- «Índices con `CONCURRENTLY`, restricciones con `NOT VALID`, todo con `lock_timeout`.»
- «Las consultas se buscan por tiempo total, no por la más lenta.»
- «Una transacción olvidada frena la limpieza de toda la base.»
- «`VACUUM` deja el espacio para reutilizarlo; devolverlo cuesta reescribir la tabla.»

---

**Anterior:** [`05`](05-monitorizacion-y-mantenimiento.md) — monitorización y mantenimiento ·
**Siguiente:** [`07`](07-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
