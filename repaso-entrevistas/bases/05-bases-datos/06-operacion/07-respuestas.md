# 07 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su capítulo y la respuesta en tres
> capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace cada motor y lo que es pura convención**.
>
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — Usuarios, roles y permisos](#capítulo-01--usuarios-roles-y-permisos)
- [Capítulo 02 — Respaldos y recuperación](#capítulo-02--respaldos-y-recuperación)
- [Capítulo 03 — Migraciones de esquema](#capítulo-03--migraciones-de-esquema)
- [Capítulo 04 — Expandir y contraer](#capítulo-04--expandir-y-contraer)
- [Capítulo 05 — Monitorización y mantenimiento](#capítulo-05--monitorización-y-mantenimiento)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — Usuarios, roles y permisos

Las 18 preguntas de [`01`](01-usuarios-roles-y-permisos.md).

**01 → 1.** ¿Qué es un rol en PostgreSQL, y en qué se diferencia de un usuario? 🟢

⏱️ **30 segundos** — Un rol es a la vez usuario y grupo. Con `LOGIN` puede conectarse, que es lo que
llamamos usuario; y cualquier rol puede ser miembro de otro, que es lo que llamamos grupo. No hay
dos conceptos distintos.

🗣️ **2 minutos** — `analista` se creó con `LOGIN` e `IN ROLE tienda_ro`: es usuario y miembro de un
grupo a la vez. `tienda_ro` también tiene `LOGIN` en el dominio, así que el mismo objeto puede hacer
las dos cosas.

🔬 **El detalle** — **Motor**. En MySQL, las cuentas son `usuario@host` y los roles un objeto aparte,
que además hay que activar.

---

**01 → 2.** ¿Qué hacen `GRANT` y `REVOKE`? 🟢

⏱️ **30 segundos** — `GRANT` da un privilegio sobre un objeto a un rol; `REVOKE` lo quita. El
privilegio depende del objeto: `SELECT` en una tabla, `CREATE` en un esquema, `USAGE` en una
secuencia.

🗣️ **2 minutos** — Se pueden dar a nivel de columna: `GRANT SELECT (id, codigo, pais) ON clientes`
dejó al analista ver el país y no el correo. Y también se conceden roles enteros a otros roles.

🔬 **El detalle** — **Estándar**, con extensiones de cada motor.

---

**01 → 3.** ¿Qué indica el `#` o el `>` al final del *prompt* de `psql`? 🟢

⏱️ **30 segundos** — `#` indica que la sesión actúa como superusuario; `>`, como un rol normal. Tras
`SET ROLE tienda_app`, el *prompt* pasó de `tienda=#` a `tienda=>`.

🗣️ **2 minutos** — Es la forma más rápida de saber, en una sesión pegada, con qué privilegios se
estaba trabajando. El `*` delante, `tienda=*#`, indica una transacción abierta.

🔬 **El detalle** — Es del cliente `psql`, no del servidor.

---

**01 → 4.** ¿Qué tiene SQLite en lugar de usuarios y permisos? 🟢

⏱️ **30 segundos** — Nada dentro de la base: no tiene `GRANT` ni usuarios. Su documentación dice
que, como lee y escribe un fichero, los únicos permisos posibles son los del sistema operativo sobre
ese fichero.

🗣️ **2 minutos** — Quien puede leer el fichero puede leerlo todo, y quien puede escribirlo, todo.
Tiene sentido para una base embebida dentro de una aplicación.

🔬 **El detalle** — **Motor**.

---

**01 → 5.** Distingue los privilegios `DELETE` y `TRUNCATE`. ¿Lo fija el estándar o es cosa del
motor? 🟡

⏱️ **30 segundos** — `DELETE` borra filas con condición, fila a fila, pasando por los disparadores
de fila. `TRUNCATE` vacía la tabla entera de golpe, y es un privilegio aparte.

🗣️ **2 minutos** — `tienda_app` pudo `DELETE FROM pagos WHERE false` y no pudo `TRUNCATE pagos`:
«permission denied for table pagos». Separarlos evita que la aplicación pueda vaciar una tabla de un
solo golpe.

🔬 **El detalle** — **Motor**: en PostgreSQL `TRUNCATE` es un privilegio propio, la `D` de `\dp`.

---

**01 → 6.** ¿Qué significan las letras `arwd` de `\dp`? ¿Lo fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — `a` es inserción, `r` lectura, `w` actualización y `d` borrado.
`tienda_app=arwd` son los cuatro privilegios de datos de la aplicación.

🗣️ **2 minutos** — Las demás: `D` vaciado, `x` referencias, `t` disparador, `m` mantenimiento. Tras
la barra va quién concedió el privilegio: `tienda_app=arwd/postgres`.

🔬 **El detalle** — **Motor**, la notación de las listas de control de acceso de PostgreSQL.

---

**01 → 7.** ¿Qué cambió en PostgreSQL 15 con el esquema `public`? 🟡

⏱️ **30 segundos** — Que por defecto ya no todo el mundo puede crear objetos en él. Por eso
`tienda_app` recibió «permission denied for schema public» al intentar crear una tabla.

🗣️ **2 minutos** — En bases creadas antes de la 15 y actualizadas, el permiso sigue ahí y hay que
quitarlo a mano con `REVOKE CREATE ON SCHEMA public FROM PUBLIC`.

🔬 **El detalle** — **Motor**, según la documentación de esquemas.

---

**01 → 8.** ¿Qué hace `SET ROLE`, y por qué sirve para probar permisos? 🟡

⏱️ **30 segundos** — Hace que la sesión actúe con los privilegios de otro rol del que es miembro, o
de cualquiera si es superusuario. `RESET ROLE` vuelve. Sirve para comprobar qué puede hacer cada rol
sin cambiar de conexión ni conocer su contraseña.

🗣️ **2 minutos** — Todas las pruebas del capítulo se hicieron así: `SET ROLE tienda_app`, intentar,
`RESET ROLE`. En MySQL, `SET ROLE` además activa el rol, que no estaba activo.

🔬 **El detalle** — No prueba las reglas de conexión de `pg_hba.conf`; para eso hay que conectarse de
verdad con el rol.

---

**01 → 9.** ¿Por qué conviene dar los permisos al rol de grupo y no a cada persona? 🟡

⏱️ **30 segundos** — Porque un cambio en el grupo cambia a todos sus miembros a la vez, y quitar a
una persona es quitarla del grupo. El `REVOKE` sobre `tienda_ro` afectó al analista sin tocarlo.

🗣️ **2 minutos** — Con permisos por persona, cada alta y cada baja es una lista de `GRANT` que
alguien tiene que acordarse de repetir, y alguna se olvida.

🔬 **El detalle** — **Convención**.

---

**01 → 10.** ¿Por qué `tienda_app` no pudo leer `cupones`, si tenía `SELECT` en todas las tablas? 🟠

⏱️ **30 segundos** — Porque `GRANT … ON ALL TABLES IN SCHEMA public` da permisos sobre las tablas
que existen en ese momento. `cupones` se creó después, y solo su dueño podía leerla.

🗣️ **2 minutos** — Es el fallo de permisos más común tras una migración. Se evita con
`ALTER DEFAULT PRIVILEGES` para el rol que crea las tablas, o concediendo en la propia migración.

🔬 **El detalle** — **Motor**: en PostgreSQL, nadie más que el dueño tiene privilegios sobre un
objeto nuevo hasta que se le dan.

---

**01 → 11.** ¿Qué hace `ALTER DEFAULT PRIVILEGES`, y por qué importa el `FOR ROLE`? 🟠

⏱️ **30 segundos** — Fija los privilegios que tendrán los objetos que se creen en adelante. No
afecta a los que ya existen: `devoluciones` nació legible y `cupones` siguió sin serlo.

🗣️ **2 minutos** — `FOR ROLE` dice de qué creador: los privilegios por defecto se aplican a los
objetos que crea ese rol. Si las migraciones corren con `tienda_admin` y se declaran para
`postgres`, no sirven.

🔬 **El detalle** — **Motor**, según su documentación.

---

**01 → 12.** ¿Por qué el analista pudo ver el país de `CLI-00311` y no su correo, si nadie le dio
permisos a él? 🟠

⏱️ **30 segundos** — Porque es miembro de `tienda_ro` y hereda sus permisos, y a `tienda_ro` se le
quitó la tabla entera y se le dieron solo tres columnas: `id`, `codigo` y `pais`.

🗣️ **2 minutos** — El error no dijo qué columna faltaba, dijo la tabla. `\dp clientes` enseñó los
permisos por columna en su propia columna de la salida.

🔬 **El detalle** — **Motor**: la herencia es la opción `INHERIT`, la de defecto.

---

**01 → 13.** ¿Por qué en MySQL el analista no pudo ni elegir la base, si tenía el rol concedido? 🟠

⏱️ **30 segundos** — Porque en MySQL un rol concedido no está activo hasta que se activa.
`CURRENT_ROLE()` daba `NONE`, así que el analista no tenía ningún permiso sobre `tienda`: el error
1044 al entrar.

🗣️ **2 minutos** — Con `SET ROLE lectura`, el `SELECT` funcionó. La corrección permanente es
`SET DEFAULT ROLE lectura TO analista` o la variable `activate_all_roles_on_login`.

🔬 **El detalle** — **Motor**. En PostgreSQL, ser miembro basta.

---

**01 → 14.** ¿Qué pasa con un `SELECT *` cuando hay permisos por columna? 🟠

⏱️ **30 segundos** — Falla, porque pide también las columnas que no se pueden ver. El analista tiene
que nombrar las columnas permitidas.

🗣️ **2 minutos** — Es un coste real: herramientas de informes que lanzan `SELECT *` dejan de
funcionar. Una vista con las columnas permitidas es la alternativa habitual.

🔬 **El detalle** — Para ocultar filas, no columnas, hace falta seguridad a nivel de fila.

---

**01 → 15.** ¿Por qué la aplicación no debe conectarse con el superusuario, aunque todo funcione? 🟠

⏱️ **30 segundos** — Porque entonces nada para un error: una inyección, un script con el `WHERE` mal
o una migración contra la base equivocada pueden borrarlo todo. En `10/02`, el `DROP TABLE pagos`
inyectado lo paró el privilegio de `tienda_app`.

🗣️ **2 minutos** — El superusuario además salta los permisos por columna y la seguridad de fila.
Todo funciona siempre, que es justo el problema.

🔬 **El detalle** — **Convención** de mínimo privilegio.

---

**01 → 16.** Diseña los roles de la tienda para la aplicación, las migraciones, los informes y dos
personas del equipo de datos. 🔴

⏱️ **30 segundos** — `tienda_app` con datos y secuencias; `tienda_admin` como dueño de las tablas y
rol de migraciones, con privilegios por defecto hacia `tienda_app` y `tienda_ro`; `tienda_ro` de
solo lectura sin columnas sensibles; y dos roles de persona, con `LOGIN`, miembros de `tienda_ro`.

🗣️ **2 minutos** — Los privilegios por defecto, `FOR ROLE tienda_admin`. `tienda_ro` sin `email` de
clientes. Nadie trabaja con `postgres`. Las personas, con su propio usuario para que la auditoría
sepa quién fue.

🔬 **El detalle** — Lo que se evalúa es separar función de persona y aplicación de migraciones.

---

**01 → 17.** Diagnostica: tras el despliegue de una migración que añade la tabla `cupones`, la
aplicación falla con «permission denied» solo en las pantallas de cupones. 🔴

⏱️ **30 segundos** — La tabla nació sin permisos para `tienda_app`: el `GRANT … ON ALL TABLES` se
hizo antes de crearla y no hay privilegios por defecto para el rol que migra.

🗣️ **2 minutos** — Lo confirmaría con `\dp cupones`. Corrección inmediata: `GRANT` sobre esa tabla.
Definitiva: `ALTER DEFAULT PRIVILEGES FOR ROLE <rol que migra>` para que las siguientes nazcan bien.

🔬 **El detalle** — Es exactamente la sesión de §4.

---

**01 → 18.** Defiende o refuta dar a la aplicación el rol `tienda_admin` «para no tener problemas
con las migraciones», con lo que enseña el capítulo. 🔴

⏱️ **30 segundos** — Se refuta. `tienda_admin` puede crear, vaciar y borrar tablas: la aplicación
perdería la protección que paró el `DROP TABLE` inyectado de `10/02`.

🗣️ **2 minutos** — El problema real, las tablas nuevas sin permisos, se resuelve con privilegios por
defecto para el rol que migra. Las migraciones corren con sus credenciales, en su momento, y la
aplicación con las suyas.

🔬 **El detalle** — Lo que se evalúa es resolver la causa, no quitar la protección.

---

## Capítulo 02 — Respaldos y recuperación

Las 18 preguntas de [`02`](02-respaldos-y-recuperacion.md).

**02 → 1.** ¿Qué diferencia un respaldo lógico de uno físico? 🟢

⏱️ **30 segundos** — El lógico guarda sentencias y datos, lo necesario para volver a crear la base:
`pg_dump`, `mysqldump`. El físico guarda los ficheros del servidor página a página:
`pg_basebackup`.

🗣️ **2 minutos** — El lógico ocupa menos —142 MB para 1 316— y es portable y selectivo, pero
restaurarlo reconstruye los índices. El físico ocupa lo que la base, se restaura copiando y
arrancando, y es la base de la recuperación a un instante.

🔬 **El detalle** — **Motor**: cada uno tiene sus herramientas.

---

**02 → 2.** ¿Qué son el RPO y el RTO? 🟢

⏱️ **30 segundos** — El RPO es cuántos datos se aceptan perder, en tiempo; el RTO, cuánto se acepta
tardar en volver a servir.

🗣️ **2 minutos** — Un `pg_dump` cada noche da un RPO de hasta 24 horas. Con WAL continuo, segundos.
El RTO se mide restaurando: 15–22 s para la base del corpus desde un volcado.

🔬 **El detalle** — **Convención** de continuidad de negocio. Se dan con números.

---

**02 → 3.** ¿Qué es la recuperación a un instante, y qué necesita? 🟢

⏱️ **30 segundos** — Reconstruir el servidor en cualquier segundo entre un respaldo físico y el
último WAL guardado. Necesita el respaldo físico y todo el WAL posterior, continuo.

🗣️ **2 minutos** — En `l03` devolvió 273 126 pagos borrados sin perder un cambio anterior al
borrado. El WAL tiene que ser continuo: el primer intento falló porque faltaba un segmento.

🔬 **El detalle** — **Motor**. En MySQL, lo mismo con un volcado y el *binary log*.

---

**02 → 4.** ¿Qué hace `pg_verifybackup`? ¿Lo fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — Relee los ficheros de un respaldo físico y los compara con las sumas de
comprobación del manifiesto que escribió `pg_basebackup`.

🗣️ **2 minutos** — Dio `backup successfully verified` y, tras cambiar un solo byte de `pagos`,
`checksum mismatch`. Detecta corrupción que el tamaño de los ficheros no delata.

🔬 **El detalle** — **Motor**. Su documentación pide aun así restauraciones de prueba.

---

**02 → 5.** ¿Por qué el volcado lógico ocupó 142 MB para una base de 1 316 MB? 🟡

⏱️ **30 segundos** — Porque guarda datos y definiciones, no páginas: ni índices construidos, ni
espacio libre, ni versiones muertas. Y el formato propio va comprimido.

🗣️ **2 minutos** — Los índices vuelven a existir al restaurar, construyéndose; por eso restaurar
cuesta más que volcar.

🔬 **El detalle** — `-Fc` es el formato propio de PostgreSQL, comprimido y con índice de contenido.

---

**02 → 6.** ¿Por qué restaurar un volcado lógico tarda más que restaurar uno físico? 🟡

⏱️ **30 segundos** — Porque el lógico vuelve a insertar todas las filas y reconstruye todos los
índices; el físico copia los ficheros tal cual y arranca.

🗣️ **2 minutos** — Con `-j 4` el lógico bajó de 22 a 15 s, pero espera a la tabla más grande y sus
índices. En una base de cientos de GB, la diferencia es de horas.

🔬 **El detalle** — El físico, a cambio, exige la misma versión mayor y la misma plataforma.

---

**02 → 7.** ¿Qué hace `--single-transaction` en `mysqldump`, y cuándo no basta? ¿Lo fija el estándar
o es cosa del motor? 🟡

⏱️ **30 segundos** — Pone el aislamiento en `REPEATABLE READ` y abre una transacción antes de
volcar: una foto coherente sin bloquear las escrituras. Solo vale con tablas transaccionales como
las de InnoDB.

🗣️ **2 minutos** — Con tablas no transaccionales, la foto no es coherente. Y por defecto no guarda
los procedimientos ni los eventos: hacen falta `--routines` y `--events`.

🔬 **El detalle** — **Motor**, según su manual.

---

**02 → 8.** ¿Qué es el *binary log* de MySQL, y para qué sirve en una recuperación? 🟡

⏱️ **30 segundos** — El registro de todos los cambios del servidor, el equivalente del WAL para la
recuperación. Con un volcado más el *binary log* desde entonces, MySQL vuelve a un instante.

🗣️ **2 minutos** — En el entorno está activo, en formato `ROW` y con treinta días de retención. Esa
retención limita hasta cuándo se puede volver atrás.

🔬 **El detalle** — **Motor**. También es la base de la replicación de MySQL.

---

**02 → 9.** ¿Por qué copiar el fichero de SQLite no es un respaldo seguro, y qué lo es? 🟡

⏱️ **30 segundos** — Porque si alguien escribe mientras se copia, la copia puede quedar a medias e
incoherente. Lo seguro es `.backup`, sobre la API de respaldo en línea.

🗣️ **2 minutos** — La copia con `.backup` pasó `PRAGMA integrity_check` y tenía el millón de
pedidos. Copiar el fichero solo es seguro con la base cerrada.

🔬 **El detalle** — **Motor**, según la documentación de la API de respaldo.

---

**02 → 10.** ¿Qué RPO da un `pg_dump` cada noche, y qué RPO da el WAL continuo? 🟠

⏱️ **30 segundos** — El volcado nocturno, hasta 24 horas. El WAL continuo recibido con
`pg_receivewal`, segundos.

🗣️ **2 minutos** — Con archivado por segmento completo, el RPO es lo que tarde en llenarse un
segmento, salvo que se fuerce con un tiempo máximo. Por eso «respaldo diario» es una respuesta que
se contesta sola.

🔬 **El detalle** — Lo que se evalúa es dar el número, no el nombre de la herramienta.

---

**02 → 11.** ¿Por qué una réplica no es un respaldo? 🟠

⏱️ **30 segundos** — Porque replica también los errores: un `DELETE` sin `WHERE` llega a la réplica
en milisegundos. Protege de que muera una máquina, no de un error humano.

🗣️ **2 minutos** — Da RPO cero ante un fallo de disco y ninguna protección ante una migración mala.
Para eso hace falta volver a un instante anterior, que solo da el respaldo con WAL.

🔬 **El detalle** — Una réplica retrasada adrede se acerca, pero solo durante su retraso.

---

**02 → 12.** ¿Por qué `pg_verifybackup` no basta, según su propia documentación? 🟠

⏱️ **30 segundos** — Porque no hace todas las comprobaciones que haría un servidor al usar el
respaldo. La documentación pide hacer restauraciones de prueba y comprobar que la base resultante
funciona y tiene los datos correctos.

🗣️ **2 minutos** — Verifica que los ficheros son los que se escribieron, no que la base arranque ni
que los datos sean los esperados. `l03` restauró y pasó `verificar.sql`: 22 de 22.

🔬 **El detalle** — Es la regla del bloque: un respaldo que no se ha restaurado no existe.

---

**02 → 13.** ¿Qué le faltaba a `pagos` tras `pg_restore -t`, y cómo se usa bien una restauración
selectiva? 🟠

⏱️ **30 segundos** — Todos sus índices, incluida la clave primaria: 820 000 filas y cero índices. El
`-t` de `pg_restore` no incluye los objetos dependientes.

🗣️ **2 minutos** — Se usa restaurando en una base aparte y copiando las filas perdidas a la tabla
buena con `INSERT … SELECT`. Nunca poniendo la tabla restaurada en producción tal cual.

🔬 **El detalle** — **Motor**: el `-t` de `pg_dump` sí vuelca los índices; el de `pg_restore`, no los
restaura.

---

**02 → 14.** ¿Por qué el volcado de MySQL ocupó casi seis veces más que el de PostgreSQL? 🟠

⏱️ **30 segundos** — Porque `mysqldump` escribe sentencias `INSERT` en texto sin comprimir: 835 MB.
El formato propio de PostgreSQL va comprimido: 142 MB.

🗣️ **2 minutos** — Se comprime por fuera, con `gzip` en la tubería. Tardó menos, 5,8 s frente a
18,7, precisamente porque no comprimía.

🔬 **El detalle** — **Motor**, los formatos de cada herramienta.

---

**02 → 15.** ¿Por qué el RTO de una recuperación a un instante crece con el tiempo desde el último
respaldo físico? 🟠

⏱️ **30 segundos** — Porque hay que aplicar todo el WAL desde el respaldo hasta el instante elegido,
y cuanto más lejos está el respaldo, más WAL hay.

🗣️ **2 minutos** — Por eso se repite el respaldo físico cada día o cada semana aunque haya WAL
continuo: acota el WAL que hay que reproducir.

🔬 **El detalle** — Es el equilibrio entre espacio de respaldos y tiempo de recuperación.

---

**02 → 16.** Diseña la política de respaldos de la tienda para un RPO de un minuto y un RTO de
treinta minutos, y cómo demostrarías que se cumple. 🔴

⏱️ **30 segundos** — Respaldo físico diario con `pg_basebackup`, WAL continuo con `pg_receivewal`
fuera de la máquina y de la región, y un volcado lógico diario para tablas sueltas.

🗣️ **2 minutos** — `pg_verifybackup` tras cada respaldo, y una restauración completa programada que
se cronometra y se compara con 30 minutos. El RPO se comprueba con el retraso del WAL recibido.
Retención del WAL igual al periodo de recuperación que se quiera.

🔬 **El detalle** — Lo que se evalúa es la demostración, no la lista de herramientas.

---

**02 → 17.** Diagnostica: tras restaurar `pedidos` desde el volcado nocturno para recuperar filas
borradas, las consultas por código tardan segundos y se aceptan pedidos con código duplicado. 🔴

⏱️ **30 segundos** — Se restauró con `pg_restore -t pedidos` directamente en producción, y ese `-t`
no trae los índices: faltan la clave primaria y el índice único de `codigo`.

🗣️ **2 minutos** — Lo confirmaría con `\d pedidos`. Corrección: limpiar los duplicados, crear los
índices con `CONCURRENTLY` y las restricciones. La próxima vez, restaurar al lado y copiar las
filas.

🔬 **El detalle** — Es la sesión de §5, puesta en producción.

---

**02 → 18.** Defiende o refuta «con la réplica en otra zona no necesitamos respaldos», con lo que
enseña el capítulo. 🔴

⏱️ **30 segundos** — Se refuta. La réplica protege de perder la zona, no de un `DELETE` sin `WHERE`
ni de una migración mala, que replica en milisegundos.

🗣️ **2 minutos** — Solo un respaldo físico con WAL permite volver al segundo anterior al error, como
en `l03`. La réplica y el respaldo cubren fallos distintos y hacen falta los dos.

🔬 **El detalle** — Lo que se evalúa es separar disponibilidad de recuperación.

---

## Capítulo 03 — Migraciones de esquema

Las 18 preguntas de [`03`](03-migraciones-de-esquema.md).

**03 → 1.** ¿Qué es una migración de esquema, y qué guarda la tabla de historial? 🟢

⏱️ **30 segundos** — Un cambio de esquema numerado, guardado como fichero junto al código. La tabla
de historial, dentro de la base, guarda qué migraciones se aplicaron, cuándo y con qué suma de
comprobación.

🗣️ **2 minutos** — En Flyway es `flyway_schema_history`, y `info` la enseña: versión, descripción,
fecha y estado. En Alembic, `alembic_version`.

🔬 **El detalle** — **Convención** de ingeniería, sin estándar.

---

**03 → 2.** ¿Qué es la línea base en Flyway? 🟢

⏱️ **30 segundos** — Declarar que lo que ya hay en la base corresponde a una versión, para empezar a
migrar desde ahí. Se usa al adoptar migraciones en una base que ya existe.

🗣️ **2 minutos** — `baseline -baselineVersion=0` creó el historial con la versión 0, y `migrate`
aplicó `V1` y `V2` después.

🔬 **El detalle** — La línea base por defecto es la versión 1, con la trampa de §3.

---

**03 → 3.** ¿Qué diferencia una migración escrita a mano de una generada por el ORM? 🟢

⏱️ **30 segundos** — La escrita a mano ejecuta exactamente lo que alguien escribió y revisó. La
generada ejecuta lo que la herramienta dedujo comparando los modelos con la base, y hay que leerla
antes de aplicarla.

🗣️ **2 minutos** — Alembic dedujo un borrado y un alta donde había un renombrado, y se perdió un
dato.

🔬 **El detalle** — **Convención**; las dos familias conviven.

---

**03 → 4.** ¿Qué es el DDL transaccional? 🟢

⏱️ **30 segundos** — Que los cambios de esquema forman parte de la transacción y se deshacen con
ella. PostgreSQL lo tiene; MySQL no, porque cada DDL confirma implícitamente.

🗣️ **2 minutos** — Es lo que hizo que la migración fallida quedara limpia en PostgreSQL y a medias
en MySQL.

🔬 **El detalle** — **Motor**.

---

**03 → 5.** ¿Por qué Flyway se negó a migrar la base de la tienda la primera vez? 🟡

⏱️ **30 segundos** — Porque el esquema tenía tablas y no había historial: Flyway no podía saber qué
migraciones representaban ya esas tablas. Pidió una línea base.

🗣️ **2 minutos** — Es la situación real de adoptar migraciones en un proyecto que ya existe. La
corrección fue `baseline` con la versión 0.

🔬 **El detalle** — `baselineOnMigrate` lo haría automáticamente, con la misma trampa de la versión.

---

**03 → 6.** ¿Qué hace `repair`, y cuándo está justificado? 🟡

⏱️ **30 segundos** — Actualiza las sumas de comprobación del historial con las de los ficheros, y
limpia las migraciones fallidas. Está justificado cuando el cambio es de verdad inocuo, como un
comentario.

🗣️ **2 minutos** — En MySQL, tras deshacer a mano una migración a medias, `repair` quita la entrada
`Failed` del historial para poder relanzarla.

🔬 **El detalle** — Usarlo para tapar una migración editada de verdad deja bases con esquemas
distintos.

---

**03 → 7.** Distingue Flyway, Liquibase y golang-migrate en una frase cada uno. 🟡

⏱️ **30 segundos** — Flyway: SQL a mano versionado, con suma de comprobación y una transacción por
migración. Liquibase: *changelogs* en XML, YAML, JSON o SQL, independientes del motor si se escriben
en su formato. golang-migrate: pares de ficheros `up` y `down`, para Go y sin ORM.

🗣️ **2 minutos** — Las tres llevan historial en la base y dependen de que el motor sepa deshacer el
DDL.

🔬 **El detalle** — Alembic y Prisma Migrate son de la otra familia: generan desde un esquema
declarado.

---

**03 → 8.** ¿Por qué se usó `-baselineVersion=0` y no la línea base por defecto? 🟡

⏱️ **30 segundos** — Porque la de defecto es la versión 1, y con ella Flyway habría dado `V1` por
aplicada sin ejecutarla: `cupones_flyway` no existiría y nadie lo sabría hasta usarla.

🗣️ **2 minutos** — Con 0, la versión 1 sigue pendiente y se ejecuta. Es de las trampas que no dan
ningún error.

🔬 **El detalle** — Lo que se evalúa es saber qué representa la línea base.

---

**03 → 9.** ¿Qué significa el aviso de Flyway sobre MySQL 9.7? 🟡

⏱️ **30 segundos** — Que Flyway 13.8.0 solo se ha verificado hasta MySQL 9.4, y la base es más
nueva. Funcionó igual.

🗣️ **2 minutos** — Es un aviso de compatibilidad, no un error. Con una versión de la base más nueva
que la herramienta, se prueba en una copia antes de migrar producción.

🔬 **El detalle** — Está en §4.9 del documento de dominio.

---

**03 → 10.** ¿Por qué añadir un comentario a `V1` bloqueó la aplicación de `V3`? ¿Qué parte es del
motor y qué parte es convención? 🟠

⏱️ **30 segundos** — Porque cambió la suma de comprobación de `V1`, y Flyway valida todas las
migraciones aplicadas antes de ejecutar ninguna nueva. Con una discrepancia, no ejecuta nada.

🗣️ **2 minutos** — Es lo que se quiere: una migración aplicada es historia, y si se edita, las bases
donde ya corrió y las nuevas tendrían esquemas distintos. Lo que cambia es una migración nueva.

🔬 **El detalle** — **Convención** de la herramienta.

---

**03 → 11.** ¿Por qué `V3` quedó limpia en PostgreSQL y `V2` a medias en MySQL, con el mismo error?
¿Lo fija el estándar o es cosa del motor? 🟠

⏱️ **30 segundos** — Porque Flyway envuelve cada migración en una transacción, y en PostgreSQL el
DDL se deshace con ella: el `ADD COLUMN` se deshizo. En MySQL cada DDL confirma implícitamente, y el
primer `ALTER` ya estaba confirmado cuando falló el segundo.

🗣️ **2 minutos** — En PostgreSQL, `V3` quedó `Pending` y se relanza tras corregirla. En MySQL, `V2`
quedó `Failed` con `caduca_en` creada.

🔬 **El detalle** — **Motor**.

---

**03 → 12.** ¿Qué habría que hacer en MySQL para volver a lanzar la migración fallida? 🟠

⏱️ **30 segundos** — Deshacer a mano lo que sí se aplicó —borrar `caduca_en`—, limpiar el historial
con `repair` para quitar la entrada `Failed`, corregir el fichero y relanzar.

🗣️ **2 minutos** — Relanzar sin deshacer fallaría, porque la columna ya existe. Por eso Flyway dice
«restaura los respaldos y deshaz la base y el código».

🔬 **El detalle** — La prevención es una sentencia de DDL por migración en MySQL.

---

**03 → 13.** ¿Por qué Alembic generó un borrado y un alta para un renombrado, y qué se perdió? 🟠

⏱️ **30 segundos** — Porque compara nombres: ve una columna que aparece, `porcentaje`, y otra que
desaparece, `descuento`. Su documentación lo dice: no detecta cambios de nombre de columna. Se
perdió el 15 % del cupón `VERANO`.

🗣️ **2 minutos** — El fichero generado decía `add_column` y `drop_column`, con un comentario «please
adjust!». Aplicado sin leer, la columna nueva nació vacía y la vieja se borró con sus datos.

🔬 **El detalle** — Se reescribe como `op.alter_column(…, new_column_name=…)`.

---

**03 → 14.** ¿Por qué casi nadie usa la reversión de migraciones en producción? 🟠

⏱️ **30 segundos** — Porque deshacer un cambio que borró datos no los devuelve: un `downgrade` que
vuelve a crear `descuento` la crea vacía. Lo habitual es corregir hacia delante con otra migración.

🗣️ **2 minutos** — La reversión sirve en desarrollo. En producción, la red de seguridad es el
respaldo y la secuencia de expandir y contraer.

🔬 **El detalle** — **Convención**.

---

**03 → 15.** ¿Qué regla de escritura de migraciones es obligatoria en MySQL y opcional en
PostgreSQL, y por qué? 🟠

⏱️ **30 segundos** — Una migración, una sentencia de DDL. En MySQL, cada DDL confirma
implícitamente, así que una migración con varias que falla a la mitad deja la base en un estado que
ninguna versión describe. En PostgreSQL el DDL se deshace entero.

🗣️ **2 minutos** — En PostgreSQL la excepción es lo que no puede ir en una transacción, como
`CREATE INDEX CONCURRENTLY`.

🔬 **El detalle** — **Convención** derivada del **motor**.

---

**03 → 16.** Diseña el flujo de migraciones de la tienda: herramienta, quién las escribe, quién las
revisa, con qué rol se lanzan y cuándo. 🔴

⏱️ **30 segundos** — Flyway con SQL a mano en el repositorio; las escribe quien cambia el código y
las revisa otra persona en la revisión del cambio; se lanzan en el despliegue, antes de la
aplicación, con `tienda_admin` y `lock_timeout`, nunca con el rol de la aplicación.

🗣️ **2 minutos** — Se prueban contra una copia con datos, como en este capítulo. Los cambios
incompatibles, con expandir y contraer. Privilegios por defecto para que las tablas nuevas nazcan
con permisos. Si se usa un ORM, sus migraciones generadas se leen y se editan antes de guardarlas.

🔬 **El detalle** — Lo que se evalúa es quién tiene cada credencial y cuándo corre cada cosa.

---

**03 → 17.** Diagnostica: tras un despliegue, la columna `descuento` de los cupones aparece vacía
para todos los cupones antiguos, y el equipo solo cambió el nombre del campo en el modelo. 🔴

⏱️ **30 segundos** — El ORM generó el renombrado como alta de una columna nueva y borrado de la
vieja, y se aplicó sin leer: los datos estaban en la columna borrada.

🗣️ **2 minutos** — Lo confirmaría leyendo la migración generada. Recuperación: los valores de la
columna vieja, desde el respaldo, restaurado al lado. Prevención: leer toda migración generada y
reescribir los renombrados.

🔬 **El detalle** — Es la sesión de §6.

---

**03 → 18.** Defiende o refuta dejar que el ORM genere y aplique las migraciones al arrancar la
aplicación, con lo que enseña el capítulo. 🔴

⏱️ **30 segundos** — Se refuta. Generadas sin leer, un renombrado borra datos, como con Alembic; y
aplicadas al arrancar, las lanza el rol de la aplicación, que no debería poder crear tablas.

🗣️ **2 minutos** — Con varias instancias arrancando a la vez, además, compiten por migrar. Se
generan en desarrollo, se leen y se guardan, y se aplican en el despliegue con el rol de
migraciones.

🔬 **El detalle** — Lo que se evalúa es separar generar, revisar y aplicar.

---

## Capítulo 04 — Expandir y contraer

Las 18 preguntas de [`04`](04-expandir-contraer.md).

**04 → 1.** ¿Qué es expandir y contraer, y cuáles son sus cinco pasos? 🟢

⏱️ **30 segundos** — Partir un cambio incompatible en pasos compatibles con la versión anterior y la
siguiente: expandir, copiar las escrituras, rellenar, cambiar la aplicación y contraer.

🗣️ **2 minutos** — Para `pais` → `pais_iso`: añadir la columna, un disparador que copia, un relleno
por lotes, el despliegue que usa `pais_iso` y, cuando no queda ninguna versión vieja, borrar `pais`.

🔬 **El detalle** — **Convención** de despliegue.

---

**04 → 2.** ¿Qué hace `lock_timeout`? 🟢

⏱️ **30 segundos** — Cancela la sentencia que espera un bloqueo más del tiempo dado. El `ALTER`
falló a los dos segundos, y la consulta de detrás respondió al instante.

🗣️ **2 minutos** — Toda migración sobre tablas en uso se lanza con él: una que falla se reintenta;
una que espera sin límite para la tienda.

🔬 **El detalle** — **Motor**.

---

**04 → 3.** ¿Qué diferencia `CREATE INDEX` de `CREATE INDEX CONCURRENTLY`? 🟢

⏱️ **30 segundos** — El normal toma `ShareLock` y bloquea las escrituras hasta terminar; el
concurrente no las bloquea, a cambio de tardar algo más y no poder ir en una transacción.

🗣️ **2 minutos** — 166 ms frente a 192 sobre el millón de pedidos, y el `UPDATE` de otra sesión
esperó al normal.

🔬 **El detalle** — **Motor**.

---

**04 → 4.** ¿Qué hace `NOT VALID` en una restricción? 🟢

⏱️ **30 segundos** — La crea sin comprobar las filas que ya existen: solo las nuevas. Después,
`VALIDATE CONSTRAINT` comprueba las viejas sin bloquear las escrituras.

🗣️ **2 minutos** — La `CHECK` se creó en 0,6 ms y se validó en 53 ms. Con ella validada,
añadir el `NOT NULL` ya no recorre la tabla.

🔬 **El detalle** — **Motor**.

---

**04 → 5.** ¿Por qué un renombrado directo rompe un despliegue con dos versiones vivas? ¿Qué parte
es del motor y qué parte es convención? 🟡

⏱️ **30 segundos** — Porque durante el despliegue conviven la versión vieja, que usa el nombre
viejo, y la nueva. Si se renombra antes, falla la vieja; si después, la nueva.

🗣️ **2 minutos** — Expandir y contraer lo evita haciendo que las dos columnas existan a la vez hasta
que solo quede la versión nueva.

🔬 **El detalle** — **Convención** de despliegue continuo.

---

**04 → 6.** ¿Qué bloqueo toma `ADD COLUMN`, y con qué choca? ¿Lo fija el estándar o es cosa del
motor? 🟡

⏱️ **30 segundos** — `ACCESS EXCLUSIVE`, que choca con todo, incluidas las lecturas. Por eso esperó
a la transacción de informe de `A`.

🗣️ **2 minutos** — Aunque dure un milisegundo, necesita que nadie más tenga la tabla abierta, y
mientras espera deja detrás a todos los demás.

🔬 **El detalle** — **Motor**, según la tabla de conflictos de bloqueos.

---

**04 → 7.** ¿Qué indica que `pg_relation_filenode` cambie tras un `ALTER`? 🟡

⏱️ **30 segundos** — Que la tabla se reescribió entera en un fichero nuevo. Pasó de 16530 a 16642 al
añadir la columna con `DEFAULT random()`.

🗣️ **2 minutos** — Una reescritura tarda en proporción a la tabla y se hace con `ACCESS EXCLUSIVE`:
1,97 s aquí, minutos en una tabla grande.

🔬 **El detalle** — Es la forma de comprobar, sin leer la documentación, si un `ALTER` reescribe.

---

**04 → 8.** ¿Por qué `CREATE INDEX CONCURRENTLY` no puede ir en una transacción, y qué implica para
una herramienta de migraciones? 🟡

⏱️ **30 segundos** — Porque necesita varias transacciones propias: recorre la tabla, espera a las
transacciones en curso y vuelve a recorrer. Dentro de un `BEGIN` da error.

🗣️ **2 minutos** — Una herramienta que envuelve cada migración en una transacción, como Flyway o
Alembic, necesita que esa migración se marque como no transaccional.

🔬 **El detalle** — **Motor**.

---

**04 → 9.** ¿Qué hace `IS DISTINCT FROM`, y por qué se usa para comprobar el relleno? 🟡

⏱️ **30 segundos** — Compara tratando los nulos como valores: `NULL IS DISTINCT FROM 'ES'` es
verdad, mientras que `NULL <> 'ES'` es desconocido y no cuenta.

🗣️ **2 minutos** — Con `<>`, las filas aún sin rellenar, con `pais_iso` nulo, no aparecerían en el
recuento de diferencias. Con `IS DISTINCT FROM`, sí: dio cero.

🔬 **El detalle** — **Estándar**, la lógica de tres valores de `01/06`.

---

**04 → 10.** ¿Por qué la sesión `C` quedó bloqueada si solo quería leer? 🟠

⏱️ **30 segundos** — Porque se puso en la cola detrás del `ALTER` de `B`, que ya había pedido su
`ACCESS EXCLUSIVE`. Su lectura era compatible con la de `A`, pero no con el bloqueo que esperaba
delante.

🗣️ **2 minutos** — `pg_blocking_pids` lo dijo: `C` bloqueada por `B`, y `B` por `A`. Una transacción
de informe abierta y una migración bastan para parar todas las lecturas.

🔬 **El detalle** — **Motor**: la cola de bloqueos respeta el orden de llegada.

---

**04 → 11.** ¿Por qué una columna con un valor por defecto constante se añadió en 1,6 ms y una con
`random()` tardó 1,97 s? 🟠

⏱️ **30 segundos** — Porque un valor constante se guarda en los metadatos de la tabla y se devuelve
al leer las filas viejas, sin tocarlas. Uno volátil necesita un valor por fila, y reescribe la
tabla.

🗣️ **2 minutos** — La documentación de `ALTER TABLE` lo explica, y `pg_relation_filenode` lo
confirmó. Una columna que necesite un valor por fila se añade vacía y se rellena por lotes.

🔬 **El detalle** — **Motor**.

---

**04 → 12.** ¿Cómo se añade `NOT NULL` a una columna de una tabla grande sin bloquearla durante el
recorrido? 🟠

⏱️ **30 segundos** — Primero una `CHECK (columna IS NOT NULL) NOT VALID`, al instante; después
`VALIDATE CONSTRAINT`, que recorre sin bloquear las escrituras; y al final `SET NOT NULL`, que ya no
recorre porque la `CHECK` lo demuestra.

🗣️ **2 minutos** — La documentación lo da como la forma de saltarse el recorrido. Sin eso, añadir el
`NOT NULL` recorre la tabla con el bloqueo tomado.

🔬 **El detalle** — **Motor**.

---

**04 → 13.** ¿Por qué el relleno se hace por lotes con `COMMIT`, y no con un solo `UPDATE`? 🟠

⏱️ **30 segundos** — Porque un solo `UPDATE` de toda la tabla es una transacción larga que bloquea
las filas hasta el final y retiene versiones muertas. Por lotes, cada `COMMIT` libera.

🗣️ **2 minutos** — El procedimiento rellenó los 50 000 clientes en 794 ms confirmando cada 10 000, y
se puede relanzar: solo toca lo que sigue a nulo.

🔬 **El detalle** — Es el procedimiento de `05/01` §6.

---

**04 → 14.** ¿Cuándo es seguro el paso de contraer, y qué pasa si se hace antes? 🟠

⏱️ **30 segundos** — Cuando ya no queda ninguna instancia de la versión vieja de la aplicación. Si
se hace antes, las peticiones que aún atiende la vieja fallan al buscar la columna borrada.

🗣️ **2 minutos** — Se contrae en un despliegue posterior, con `lock_timeout`. Borrar la columna y el
disparador son cambios de metadatos, milisegundos.

🔬 **El detalle** — La disciplina está en esperar, no en la sentencia.

---

**04 → 15.** ¿Qué pasa si `CREATE INDEX CONCURRENTLY` falla a la mitad? 🔴

⏱️ **30 segundos** — Deja un índice inválido: existe, ocupa espacio y se mantiene en las escrituras,
pero no se usa en las consultas. Hay que borrarlo y volver a crearlo.

🗣️ **2 minutos** — Se detecta con `indisvalid` en `pg_index`, el mismo control de «ningún índice
inválido» que se hace al cerrar cada tanda de este corpus.

🔬 **El detalle** — **Motor**, entre las advertencias de la creación concurrente.

---

**04 → 16.** Diseña la migración para cambiar `pedidos.total` de `numeric(12,2)` a `numeric(14,2)`
sin parar la tienda. 🔴

⏱️ **30 segundos** — Con expandir y contraer: añadir `total_nuevo numeric(14,2)` sin valor por
defecto, un disparador que copia `total`, rellenar por lotes, comprobar con `IS DISTINCT FROM`,
cambiar la aplicación y borrar la columna vieja.

🗣️ **2 minutos** — Un `ALTER COLUMN TYPE` directo reescribiría la tabla con `ACCESS EXCLUSIVE`. Todo
con `lock_timeout`, el `NOT NULL` con `CHECK NOT VALID` y `VALIDATE`, y los índices sobre la columna
nueva con `CONCURRENTLY`.

🔬 **El detalle** — Si el motor pudiera ampliar la precisión sin reescribir, sería un solo paso; se
comprueba con `pg_relation_filenode` en una copia antes de decidir.

---

**04 → 17.** Diagnostica: durante un despliegue que solo añadía una columna, todas las pantallas de
clientes dejaron de responder dos minutos, y el `ALTER` registrado en el log tardó 3 ms. 🔴

⏱️ **30 segundos** — La cola de bloqueos: el `ALTER` esperó dos minutos a una transacción larga que
tenía `clientes` abierta, y todas las consultas llegaron detrás de él. Lo que tardó fue la espera,
no el `ALTER`.

🗣️ **2 minutos** — Lo confirmaría buscando en el registro esperas de bloqueo y la transacción larga
de ese momento. Prevención: `lock_timeout` en las migraciones y vigilar `idle in transaction` antes
de desplegar.

🔬 **El detalle** — Es la sesión de §3.

---

**04 → 18.** Defiende o refuta hacer los cambios de esquema en una ventana de mantenimiento mensual
en vez de con expandir y contraer, con lo que enseña el capítulo. 🔴

⏱️ **30 segundos** — Se refuta para una tienda que despliega a diario: la ventana obliga a acumular
cambios, a parar el servicio y a un despliegue enorme y arriesgado.

🗣️ **2 minutos** — Con los bloqueos medidos —valores por defecto constantes, `CONCURRENTLY`,
validación diferida, `lock_timeout`—, casi todo cambio se hace en caliente. La ventana queda para lo
que de verdad reescribe una tabla grande.

🔬 **El detalle** — Lo que se evalúa es conocer qué operación bloquea y cuánto.

---

## Capítulo 05 — Monitorización y mantenimiento

Las 18 preguntas de [`05`](05-monitorizacion-y-mantenimiento.md).

**05 → 1.** ¿Qué acumula `pg_stat_statements`, y por forma de qué? 🟢

⏱️ **30 segundos** — Llamadas, tiempo total, tiempo medio y más, por cada forma de consulta, con los
valores sustituidos por `$1`, `$2`.

🗣️ **2 minutos** — Las 18 285 búsquedas por código, con códigos distintos, salieron en una sola
fila: `WHERE codigo = $1`.

🔬 **El detalle** — **Motor**; en MySQL, lo mismo en `performance_schema`.

---

**05 → 2.** ¿Qué significa `idle in transaction`? 🟢

⏱️ **30 segundos** — Que la sesión no está ejecutando nada pero tiene una transacción abierta.

🗣️ **2 minutos** — Un informe a medias, un depurador parado o una conexión que la aplicación no
devolvió. Retiene su instantánea y sus bloqueos mientras siga así.

🔬 **El detalle** — `idle_in_transaction_session_timeout` la corta pasado un tiempo.

---

**05 → 3.** ¿Qué es la hinchazón de una tabla? 🟢

⏱️ **30 segundos** — Espacio dentro de la tabla que está libre pero sigue ocupando disco, tras
borrar o actualizar filas.

🗣️ **2 minutos** — Tras `VACUUM`, `clientes` seguía en 15 MB con el 66,7 % libre, según
`pgstattuple`. `VACUUM FULL` la dejó en 5 264 kB.

🔬 **El detalle** — Es consecuencia de MVCC: las versiones viejas ocupan hasta que se limpian.

---

**05 → 4.** ¿Qué hace el *autovacuum*? 🟢

⏱️ **30 segundos** — Lanza `VACUUM` y `ANALYZE` solo, cuando una tabla acumula suficientes cambios,
para limpiar versiones muertas y mantener las estadísticas.

🗣️ **2 minutos** — Sus umbrales son proporcionales al tamaño de la tabla, así que en tablas enormes
espera muchas filas muertas. Y no puede limpiar lo que una transacción abierta retiene.

🔬 **El detalle** — **Motor**; se ajusta tabla a tabla.

---

**05 → 5.** ¿Por qué `pg_stat_statements` exige reiniciar el servidor? ¿Lo fija el estándar o es
cosa del motor? 🟡

⏱️ **30 segundos** — Porque necesita memoria compartida, y eso solo se reserva al arrancar. Hay que
añadirla a `shared_preload_libraries` y reiniciar; `CREATE EXTENSION` solo crea las vistas.

🗣️ **2 minutos** — La copia se recreó con el parámetro para el capítulo. Por eso se activa desde el
primer día, y no se descubre el día del problema.

🔬 **El detalle** — **Motor**, según su documentación.

---

**05 → 6.** Distingue `total_exec_time` de `mean_exec_time`, y di por cuál se ordena. ¿Qué parte es
del motor y qué parte es convención? 🟡

⏱️ **30 segundos** — El total es la suma de todas las ejecuciones; el medio, lo que tarda una. Se
ordena por el total, porque es lo que carga la base.

🗣️ **2 minutos** — Una consulta de 39 ms que se ejecuta mil veces pesa más que una de diez segundos
al día.

🔬 **El detalle** — **Convención** de diagnóstico.

---

**05 → 7.** ¿Qué es `backend_xmin`? 🟡

⏱️ **30 segundos** — La transacción más antigua que una sesión necesita seguir viendo: el horizonte
de su instantánea. Por debajo de él, `VACUUM` no puede limpiar.

🗣️ **2 minutos** — La sesión `A` tenía `backend_xmin` 858, y mientras siguió abierta, las 100 000
versiones muertas se quedaron.

🔬 **El detalle** — **Motor**; se lee en `pg_stat_activity`.

---

**05 → 8.** Distingue `VACUUM` de `VACUUM FULL`: qué hace cada uno y qué bloquea. 🟡

⏱️ **30 segundos** — `VACUUM` marca el espacio de las versiones muertas como reutilizable, sin
bloquear el uso normal, y no devuelve espacio al disco salvo el final. `VACUUM FULL` reescribe la
tabla y devuelve todo, con `ACCESS EXCLUSIVE`.

🗣️ **2 minutos** — 15 MB tras el normal; 5 264 kB tras el completo, con la tabla inutilizable
mientras tanto.

🔬 **El detalle** — **Motor**, según la documentación de mantenimiento.

---

**05 → 9.** ¿Qué indica `SUM_ROWS_EXAMINED` en MySQL? 🟡

⏱️ **30 segundos** — Cuántas filas examinó en total una forma de consulta. Muchas filas examinadas
por cada una devuelta delatan una consulta sin índice.

🗣️ **2 minutos** — Las comprobaciones de `verificar-mysql.sql` examinaron 53 millones de filas en
tres ejecuciones.

🔬 **El detalle** — **Motor**, en `events_statements_summary_by_digest`.

---

**05 → 10.** ¿Por qué la consulta del 5 % de las llamadas se llevó el 99 % del tiempo, y por qué no
saldría en un registro de lentas? 🟠

⏱️ **30 segundos** — Porque no tiene índice en `cliente_id`: 39 ms de media frente a 0,014 de la
otra. 973 llamadas sumaron 37 883 ms. Con el umbral del registro en 100 ms, ninguna ejecución
individual llega.

🗣️ **2 minutos** — El registro de lentas ve ejecuciones sueltas; `pg_stat_statements` ve lo
acumulado. La corrección es un índice en `pedidos (cliente_id)`.

🔬 **El detalle** — Lo que se evalúa es buscar por suma.

---

**05 → 11.** ¿Por qué `VACUUM` no quitó las 100 000 filas muertas mientras la sesión `A` estaba
abierta? 🟠

⏱️ **30 segundos** — Porque `A` tenía una instantánea anterior a los `UPDATE`, y podría necesitar
ver las versiones viejas. `VACUUM` solo quita lo que ninguna sesión puede ver.

🗣️ **2 minutos** — Al terminar `A`, el siguiente `VACUUM` dejó cero muertas. Una sola transacción
olvidada frena la limpieza de toda la base.

🔬 **El detalle** — **Motor**, MVCC.

---

**05 → 12.** ¿Por qué la sesión `A` retuvo filas en `REPEATABLE READ` y no las habría retenido en
`READ COMMITTED` solo leyendo? 🟠

⏱️ **30 segundos** — Porque en `REPEATABLE READ` la instantánea dura toda la transacción; en
`READ COMMITTED` se toma y se suelta en cada sentencia, así que una transacción que solo leyó no
retiene nada entre sentencias.

🗣️ **2 minutos** — Por eso la sesión del capítulo abre `A` en `REPEATABLE READ`: es la forma de
retener sin escribir. Con una escritura, la transacción tendría identificador y retendría en
cualquier nivel.

🔬 **El detalle** — Son los niveles de `04/02`.

---

**05 → 13.** ¿Por qué la tabla siguió en 15 MB tras un `VACUUM` que dejó cero filas muertas? 🟠

⏱️ **30 segundos** — Porque `VACUUM` deja el espacio libre dentro de la tabla para reutilizarlo, no
lo devuelve al disco, salvo las páginas vacías del final. El 66,7 % quedó libre.

🗣️ **2 minutos** — Las próximas escrituras lo reutilizarán. Para devolverlo, hay que reescribir la
tabla.

🔬 **El detalle** — `04/03` midió la excepción: las páginas vacías del final sí se truncan.

---

**05 → 14.** ¿Por qué `n_dead_tup` puede salir a cero justo después de un `UPDATE` masivo? 🟠

⏱️ **30 segundos** — Porque las estadísticas no son instantáneas: cada proceso las publica como
mucho una vez por segundo. `pg_stat_force_next_flush()` las vuelca al momento.

🗣️ **2 minutos** — Por eso la sesión del capítulo llama a `pg_stat_force_next_flush()` antes de leer
`pg_stat_user_tables`.

🔬 **El detalle** — **Motor**, según la documentación de estadísticas.

---

**05 → 15.** ¿Qué harías con una tabla hinchada que no se puede parar? 🟠

⏱️ **30 segundos** — No `VACUUM FULL`, que la bloquea. Si va a volver a crecer, dejar que las
escrituras reutilicen el espacio. Si no, reescribirla con una herramienta que no bloquee, y los
índices con `REINDEX CONCURRENTLY`.

🗣️ **2 minutos** — Y buscar la causa: casi siempre una transacción larga o un *autovacuum* que no
llega.

🔬 **El detalle** — Las herramientas que reescriben sin bloquear son externas al motor.

---

**05 → 16.** Diseña el panel de salud diario de la base de la tienda: qué consultas, con qué
umbrales y qué alertas. 🔴

⏱️ **30 segundos** — Las diez consultas con más tiempo total; las sesiones `idle in transaction` de
más de cinco minutos; las esperas de bloqueo; las conexiones frente al máximo; las filas muertas por
tabla y el último *autovacuum*; la hinchazón semanal; y la verificación de respaldos.

🗣️ **2 minutos** — Alertas: transacción abierta de más de diez minutos, conexiones por encima del 80
%, respaldo sin verificar. `pg_stat_statements` activo desde el primer día y reiniciado tras cada
cambio grande.

🔬 **El detalle** — Lo que se evalúa es que cada métrica diga qué acción tomar.

---

**05 → 17.** Diagnostica: la base crece 2 GB al día aunque apenas se insertan pedidos, y el
*autovacuum* corre sin errores. 🔴

⏱️ **30 segundos** — Una transacción abierta desde hace días retiene la limpieza: el *autovacuum*
corre, pero no puede quitar nada por debajo de su `backend_xmin`, y cada `UPDATE` suma versiones
muertas.

🗣️ **2 minutos** — Lo confirmaría con `pg_stat_activity`, buscando `xact_start` antiguos, y con
`n_dead_tup` creciendo. Corrección: terminar esa sesión, dejar al *autovacuum* limpiar y poner
`idle_in_transaction_session_timeout`. El espacio ya crecido no vuelve sin reescribir.

🔬 **El detalle** — Es la sesión de §3 con días en vez de segundos.

---

**05 → 18.** Defiende o refuta «si la base va lenta, lo primero es subirle la máquina», con los
números del capítulo. 🔴

⏱️ **30 segundos** — Se refuta. En diez segundos de carga, una consulta sin índice explicaba el 99 %
del tiempo; con el doble de máquina seguiría siéndolo.

🗣️ **2 minutos** — Primero `pg_stat_statements` por tiempo total, las sesiones abiertas y la
hinchazón. Más máquina se justifica cuando lo acumulado ya está optimizado y sigue sin caber.

🔬 **El detalle** — Lo que se evalúa es medir antes de gastar.

---

## Simulación de entrevista

Las 26 preguntas `S#` y los cuatro escenarios de [`06`](06-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**06 → S1.** ¿Qué es mínimo privilegio para la aplicación de la tienda, en tres permisos que no
tiene? 🟡

⏱️ **30 segundos** — `tienda_app` lee y escribe datos, y no puede crear tablas en el esquema, no
puede vaciar una tabla con `TRUNCATE` y no es dueña de las tablas, así que no puede borrarlas.

🗣️ **2 minutos** — Por eso el `DROP TABLE pagos` inyectado de `10/02` no pasó. Las migraciones
corren con otro rol, `tienda_admin`, dueño de las tablas.

🔬 **El detalle** — **Convención** de mínimo privilegio, sobre los privilegios del **motor**.

---

**06 → S2.** Una migración crea una tabla y la aplicación no puede leerla. ¿Por qué, y cómo se
evita? 🟠

⏱️ **30 segundos** — Porque los `GRANT … ON ALL TABLES` solo cubren las tablas que existían. La
nueva nace con permisos solo para su dueño. Se evita con `ALTER DEFAULT PRIVILEGES FOR ROLE` el rol
que migra.

🗣️ **2 minutos** — `cupones` dio «permission denied» y `devoluciones`, creada tras los privilegios
por defecto, se leyó. El `FOR ROLE` tiene que ser el rol que crea las tablas.

🔬 **El detalle** — **Motor**.

---

**06 → S3.** ¿Qué diferencia hay entre conceder un rol en PostgreSQL y en MySQL? 🟡

⏱️ **30 segundos** — En PostgreSQL, ser miembro de un rol basta para usar sus permisos. En MySQL, el
rol concedido no está activo hasta `SET ROLE` o un rol por defecto: `CURRENT_ROLE()` dio `NONE`.

🗣️ **2 minutos** — Con el rol inactivo, el analista no pudo ni elegir la base: `ERROR 1044`. La
corrección es `SET DEFAULT ROLE` o `activate_all_roles_on_login`.

🔬 **El detalle** — **Motor**.

---

**06 → S4.** ¿Por qué se conceden los permisos a roles de grupo y no a personas? 🟢

⏱️ **30 segundos** — Porque cambiar el grupo cambia a todos sus miembros, y quitar a alguien es
sacarlo del grupo. El `REVOKE` a `tienda_ro` afectó al analista sin tocarlo.

🗣️ **2 minutos** — Con permisos por persona, cada alta y baja es una lista de `GRANT` que alguien
olvida.

🔬 **El detalle** — **Convención**.

---

**06 → S5.** Explica el RPO y el RTO con los números de las estrategias del bloque. 🟠

⏱️ **30 segundos** — El RPO es cuánto se pierde; el RTO, cuánto se tarda. Un volcado nocturno da un
RPO de 24 horas y un RTO de 15–22 s para la base del corpus; con WAL continuo, el RPO baja a
segundos; con una réplica síncrona, a cero para lo confirmado.

🗣️ **2 minutos** — El RTO de la recuperación a un instante crece con el WAL desde el último respaldo
físico, por eso se repite el físico cada cierto tiempo.

🔬 **El detalle** — **Convención** de continuidad; los números son del corpus.

---

**06 → S6.** ¿Por qué un respaldo que no se ha restaurado no existe, si `pg_verifybackup` dice que
está bien? 🟠

⏱️ **30 segundos** — Porque `pg_verifybackup` comprueba que los ficheros son los que se escribieron,
no que la base arranque ni tenga los datos correctos. Su propia documentación pide restauraciones de
prueba.

🗣️ **2 minutos** — Detecta corrupción —un byte cambiado dio `checksum mismatch`—, pero el RTO real
solo se conoce restaurando y cronometrando.

🔬 **El detalle** — Es la regla del bloque.

---

**06 → S7.** ¿Qué pasa si se restaura una sola tabla con `pg_restore -t` y se pone en producción? 🟠

⏱️ **30 segundos** — Que llega sin índices, ni siquiera la clave primaria: `pagos` volvió con 820
000 filas y cero índices. Las consultas se vuelven lentas y se aceptan duplicados.

🗣️ **2 minutos** — Se restaura al lado, en otra base, y se copian las filas perdidas con
`INSERT … SELECT`.

🔬 **El detalle** — **Motor**: el `-t` de `pg_restore` no incluye los objetos dependientes.

---

**06 → S8.** Lógico o físico: ¿qué usarías para volver al segundo anterior a un `DELETE` sin
`WHERE`? 🟡

⏱️ **30 segundos** — El físico con todo el WAL posterior: la recuperación a un instante. El lógico
es una foto de cuando se tomó, y lo que pasó después se pierde.

🗣️ **2 minutos** — `l03` volvió al segundo anterior a un borrado de 273 126 filas. Se restaura al
lado y se copian las filas.

🔬 **El detalle** — **Motor**.

---

**06 → S9.** ¿Cómo se respalda en caliente una base SQLite? 🟢

⏱️ **30 segundos** — Con `.backup` de su línea de órdenes, sobre la API de respaldo en línea, no
copiando el fichero mientras alguien escribe.

🗣️ **2 minutos** — La copia pasó `PRAGMA integrity_check` y tenía el millón de pedidos.

🔬 **El detalle** — **Motor**.

---

**06 → S10.** ¿Por qué no se edita una migración ya aplicada? 🟡

⏱️ **30 segundos** — Porque las bases donde ya corrió tienen una versión y las nuevas tendrían otra.
Flyway lo impide con la suma de comprobación: un comentario bloqueó todas las migraciones.

🗣️ **2 minutos** — Lo que cambia se escribe como migración nueva. `repair` solo para cambios de
verdad inocuos.

🔬 **El detalle** — **Convención** de la herramienta.

---

**06 → S11.** La misma migración falla a la mitad en PostgreSQL y en MySQL. ¿Qué queda en cada
una? 🟠

⏱️ **30 segundos** — En PostgreSQL, nada: el DDL se deshizo con la transacción y la migración siguió
pendiente. En MySQL, la primera sentencia confirmada: `caduca_en` creada y la migración `Failed`.

🗣️ **2 minutos** — En MySQL hay que deshacer a mano y limpiar el historial. De ahí la regla: una
sentencia de DDL por migración.

🔬 **El detalle** — **Motor**: MySQL confirma implícitamente cada DDL.

---

**06 → S12.** ¿Qué hizo Alembic con un renombrado de columna, y cómo se evita? 🟠

⏱️ **30 segundos** — Lo generó como `add_column` más `drop_column`, y al aplicarlo se perdió el 15 %
del cupón `VERANO`. Su documentación dice que no detecta renombrados.

🗣️ **2 minutos** — Se evita leyendo toda migración generada y reescribiendo el renombrado con
`alter_column`, o con expandir y contraer si la aplicación no puede parar.

🔬 **El detalle** — **Convención**: generar, revisar y aplicar son tres pasos.

---

**06 → S13.** ¿Qué es la línea base de Flyway, y cuál es su trampa? 🟡

⏱️ **30 segundos** — Declarar que lo que hay es una versión, para adoptar migraciones en una base
existente. La trampa: por defecto es la versión 1, y daría `V1` por aplicada sin ejecutarla.

🗣️ **2 minutos** — Por eso se usó la versión 0.

🔬 **El detalle** — No da ningún error; se descubre al usar la tabla que no existe.

---

**06 → S14.** Da los cinco pasos de expandir y contraer para renombrar una columna. 🟢

⏱️ **30 segundos** — Añadir la columna nueva, copiar las escrituras con un disparador, rellenar por
lotes, cambiar la aplicación, y borrar la vieja cuando no quede ninguna versión que la use.

🗣️ **2 minutos** — Para `pais` → `pais_iso`, el relleno fueron 794 ms y la contracción,
milisegundos.

🔬 **El detalle** — **Convención** de despliegue.

---

**06 → S15.** ¿Por qué un `ALTER TABLE` de un milisegundo puede parar la tienda? 🔴

⏱️ **30 segundos** — Porque necesita `ACCESS EXCLUSIVE`, espera a cualquier transacción que tenga la
tabla abierta, y mientras espera, todas las consultas nuevas se ponen en la cola detrás de él.

🗣️ **2 minutos** — La lectura de la sesión `C` esperó al `ALTER` de `B`, que esperaba al informe de
`A`. Con `lock_timeout = '2s'`, el `ALTER` se rindió y `C` respondió.

🔬 **El detalle** — **Motor**.

---

**06 → S16.** ¿Qué `ADD COLUMN` es instantáneo y cuál reescribe la tabla? 🟡

⏱️ **30 segundos** — Con un valor por defecto constante, instantáneo: 1,6 ms. Con uno volátil, como
`random()`, reescribe la tabla: 1,97 s y un fichero nuevo.

🗣️ **2 minutos** — El constante se guarda en los metadatos; el volátil necesita un valor por fila.

🔬 **El detalle** — **Motor**, según la documentación de `ALTER TABLE`.

---

**06 → S17.** ¿Cómo se crea un índice y se añade un `NOT NULL` en una tabla en uso? 🟠

⏱️ **30 segundos** — El índice, creándolo de forma concurrente y fuera de una transacción. La
restricción de no nulo, en tres pasos: una `CHECK` creada sin validar, su validación aparte y, al
final, el `NOT NULL`, que ya no recorre la tabla.

🗣️ **2 minutos** — El índice normal tomó `ShareLock` y bloqueó un `UPDATE`. La validación tardó 53
ms sin bloquear escrituras.

🔬 **El detalle** — Todo con `lock_timeout`.

---

**06 → S18.** ¿Cómo encuentras la consulta que más carga la base? 🟡

⏱️ **30 segundos** — Con `pg_stat_statements`, ordenando por tiempo total. La consulta sin índice
fue el 5 % de las llamadas y el 99 % del tiempo.

🗣️ **2 minutos** — El registro de lentas no la vería: 39 ms por ejecución. `pg_stat_statements` hay
que cargarlo al arrancar.

🔬 **El detalle** — **Motor**; en MySQL, `performance_schema`.

---

**06 → S19.** ¿Qué hace una transacción olvidada con la limpieza de la base? 🟠

⏱️ **30 segundos** — La frena: `VACUUM` no puede quitar las versiones que su instantánea aún podría
ver. Con una transacción `REPEATABLE READ` abierta, quedaron 100 000 filas muertas.

🗣️ **2 minutos** — Se vigila `idle in transaction` y la edad de `xact_start`, y se limita con
`idle_in_transaction_session_timeout`.

🔬 **El detalle** — Afecta a toda la base, no solo a las tablas que tocó.

---

**06 → S20.** ¿Por qué la tabla no encoge tras un `VACUUM`, y qué cuesta encogerla? 🟠

⏱️ **30 segundos** — Porque `VACUUM` deja el espacio libre para reutilizarlo: 15 MB con el 66,7 %
libre. Encogerla es reescribirla con `VACUUM FULL`, que la bloquea: 5 264 kB.

🗣️ **2 minutos** — Si la tabla va a volver a crecer, no merece la pena; si no se puede parar, se
reescribe con herramientas que no bloquean.

🔬 **El detalle** — **Motor**.

---

**06 → S21.** ¿Qué tiene MySQL en lugar de `pg_stat_statements`? 🟢

⏱️ **30 segundos** — `performance_schema.events_statements_summary_by_digest`, que agrupa por la
consulta normalizada con `?`.

🗣️ **2 minutos** — Su columna `SUM_ROWS_EXAMINED` delata las consultas sin índice. Está activo sin
reiniciar.

🔬 **El detalle** — **Motor**.

---

**06 → S22.** «Tenemos réplica en otra zona, así que estamos cubiertos». ¿Qué parte es cierta? 🟠

⏱️ **30 segundos** — Es cierta ante la pérdida de una zona: la réplica sigue. No lo es ante un error
humano, que replica en milisegundos.

🗣️ **2 minutos** — Para volver a antes del error hace falta un respaldo físico con WAL. Cubren
fallos distintos.

🔬 **El detalle** — Disponibilidad no es recuperación.

---

**06 → S23.** «Las migraciones del ORM son seguras porque las genera la herramienta». Refútalo. 🟠

⏱️ **30 segundos** — Alembic generó un renombrado como borrado y alta, y se perdió un dato sin un
error. Las genera comparando nombres.

🗣️ **2 minutos** — La seguridad está en leerlas y probarlas contra una copia con datos, no en quién
las escribe.

🔬 **El detalle** — **Convención**.

---

**06 → S24.** «Las lecturas nunca se bloquean en PostgreSQL». Refútalo con la sesión. 🔴

⏱️ **30 segundos** — La lectura de la sesión `C` se bloqueó detrás de un `ALTER` que esperaba su
`ACCESS EXCLUSIVE`. `pg_blocking_pids` lo enseñó.

🗣️ **2 minutos** — Es cierto que una lectura no bloquea a otra ni a una escritura normal, por MVCC;
no lo es frente a un cambio de esquema en la cola.

🔬 **El detalle** — **Motor**: la cola respeta el orden de llegada.

---

**06 → S25.** «`VACUUM` libera espacio en disco». ¿Qué parte es cierta? 🟡

⏱️ **30 segundos** — Libera espacio dentro de la tabla para reutilizarlo, y devuelve al disco solo
las páginas vacías del final. La tabla siguió en 15 MB.

🗣️ **2 minutos** — Devolverlo todo es `VACUUM FULL`, con la tabla bloqueada.

🔬 **El detalle** — **Motor**.

---

**06 → S26.** «Si la base va lenta, hay que darle más máquina». Refútalo con números. 🔴

⏱️ **30 segundos** — Una consulta sin índice era el 99 % del tiempo en diez segundos de carga; con
el doble de máquina seguiría siéndolo.

🗣️ **2 minutos** — Primero `pg_stat_statements`, las sesiones abiertas y la hinchazón. Una
transacción olvidada tampoco la arregla una máquina mayor.

🔬 **El detalle** — Medir antes de gastar.

---

**06 → E1.** Escenario 1 — El lunes que se paró la tienda

⏱️ **30 segundos** — Los dos síntomas apuntan a una transacción larga abierta: el `ALTER` esperó a
ella tres minutos con toda la tabla detrás, y esa misma transacción impidió limpiar la noche
anterior, de ahí los 3 GB.

🗣️ **2 minutos** — Lo confirmaría en `pg_stat_activity` —`idle in transaction`, `xact_start`
antiguo, `backend_xmin`— y con `pg_blocking_pids`. En el momento, terminar esa sesión. Después,
`lock_timeout` en las migraciones, `idle_in_transaction_session_timeout` en la configuración, y el
espacio se reutiliza o se reescribe la tabla sin bloquearla.

🔬 **El detalle** — Lo que se evalúa es ver que los dos síntomas tienen una sola causa.

---

**06 → E2.** Escenario 2 — El borrado accidental

⏱️ **30 segundos** — Con el volcado de las tres, se recuperan los pagos que había entonces, y se
pierden todos los cambios entre las 3:00 y las 11:42: un RPO de casi nueve horas. Y si el servidor
muere, el respaldo muere con él.

🗣️ **2 minutos** — Recuperación: restaurar `pagos` en una base aparte y copiar las filas borradas
que existían a las tres. Propuesta: respaldo físico diario más WAL continuo fuera de la máquina,
para volver a las 11:41; verificación con `pg_verifybackup` y restauraciones de prueba
cronometradas.

🔬 **El detalle** — Lo que se evalúa es calcular el RPO actual y no restaurar encima de producción.

---

**06 → E3.** Escenario 3 — La migración que no cuadra

⏱️ **30 segundos** — El ORM generó el renombrado como borrado y alta, y los descuentos se borraron
con la columna vieja. La tabla nueva no tiene permisos porque no hay privilegios por defecto para el
rol que la creó.

🗣️ **2 minutos** — En preproducción no se vio porque no había datos reales ni el mismo juego de
roles. Los descuentos se recuperan del respaldo, restaurado al lado. Flujo: migraciones generadas y
leídas, guardadas en el repositorio, aplicadas en el despliegue con el rol de migraciones y
`lock_timeout`, y privilegios por defecto para ese rol.

🔬 **El detalle** — Lo que se evalúa es separar generar, revisar y aplicar, y quién aplica.

---

**06 → E4.** Escenario 4 — «La base va lenta: migremos a una instancia el doble de grande»

⏱️ **30 segundos** — No lo resuelve una base más grande. Primero `pg_stat_statements` por tiempo
total, `pg_stat_activity` por transacciones abiertas y esperas, y las filas muertas y la hinchazón.

🗣️ **2 minutos** — Lo esperable, con los números del bloque: una consulta sin índice que acumula
casi todo el tiempo, y quizá una transacción olvidada frenando la limpieza. Se corrige con un
índice, con `idle_in_transaction_session_timeout` y dejando limpiar. Una instancia mayor, cuando lo
acumulado ya está optimizado y la carga no cabe.

🔬 **El detalle** — Lo que se evalúa es no aceptar el marco y medir primero.

---

**Volver:** [README del bloque](README.md).
