# 03 — MVCC frente a bloqueo

> Cómo consigue el motor lo que [`02`](02-aislamiento-y-sus-fenomenos.md) describía: dónde vive la
> versión antigua de una fila, quién decide cuál de todas ves tú, y qué se paga por tenerlas. Los
> dos motores principales resuelven lo mismo con mecanismos opuestos —PostgreSQL deja las versiones
> en la tabla, InnoDB las reconstruye desde el *undo log*— y casi todo lo raro que verás en
> producción sale de esa diferencia. **Asume leído:** [`02`](02-aislamiento-y-sus-fenomenos.md) — de
> ahí vienen los cuatro niveles, los cinco fenómenos y la palabra «instantánea», que aquí se explica
> por dentro. **Vigencia:** 22 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Dos maneras de que un lector no
  espere](#2--dos-maneras-de-que-un-lector-no-espere)
- [3. La versión de fila en PostgreSQL](#3--la-versión-de-fila-en-postgresql) · [4. La instantánea y
  la regla de visibilidad](#4--la-instantánea-y-la-regla-de-visibilidad)
- [5. InnoDB: las versiones viven en el undo log](#5-️-innodb-las-versiones-viven-en-el-undo-log) ·
  [6. El precio de MVCC: filas muertas, VACUUM y el
  horizonte](#6--el-precio-de-mvcc-filas-muertas-vacuum-y-el-horizonte)
- [7. Lo que MVCC no resuelve](#7--lo-que-mvcc-no-resuelve) · [8. Dónde aparece de
  verdad](#8--dónde-aparece-de-verdad)
- [9. Estándar, motor y convención](#9--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El informe de cierre recorre el millón de pedidos y tarda cuarenta segundos. Mientras corre, el
proceso nocturno mueve a `ENVIADO` los doscientos setenta mil pedidos pagados del día. Las dos cosas
pasan todas las noches a la misma hora, y las dos terminan bien: el informe no se queda esperando y
el proceso nocturno tampoco.

Eso no es obvio. Con la respuesta ingenua —bloquear lo que se lee para que nadie lo cambie— una de
las dos tiene que esperar a la otra, y cuarenta segundos de espera por noche se convierten en un
incidente. Con la otra respuesta ingenua —no bloquear nada— el informe contaría unos pedidos como
`PAGADO` al principio y como `ENVIADO` al final, y no cuadraría consigo mismo.

```text
¿Dónde está el valor viejo que el informe sigue viendo?
¿Quién decide cuál de las versiones te toca a ti?
¿Quién borra las que ya no mira nadie, y qué pasa si no puede?
```

Las tres preguntas tienen respuestas distintas en PostgreSQL y en InnoDB, y este capítulo es el
dueño de esa distinción en todo el corpus.

> **📝 Contexto.** Las sesiones de este capítulo están **corridas contra el entorno** y su salida es
> literal. Los valores de `xmin`, `xmax`, `ctid`, la instantánea y `n_dead_tup` **cambian en cada
> corrida y en cada base**: dependen de cuántas transacciones lleve encima, de qué otras sesiones
> estén abiertas y de cuándo pasó el autovacuum. Lo que hay que mirar es la relación entre ellos, no
> el dígito, y es lo que explican las viñetas de §3, §4 y §6.

---

## 2. 🧱 Dos maneras de que un lector no espere

**Qué es:** hay exactamente dos familias de solución al problema de §1, y todo motor relacional usa
una, la otra, o las dos mezcladas.

| | Bloqueo de dos fases (2PL) | Control de concurrencia multiversión (MVCC) |
|---|---|---|
| Idea | Quien lee toma un bloqueo compartido; quien escribe, uno exclusivo | Quien escribe **crea una versión nueva** y deja la vieja donde estaba |
| El lector | Espera si alguien escribe esa fila | No espera nunca: lee la versión que le corresponde |
| El escritor | Espera si alguien lee esa fila | No espera a los lectores; sí a otro escritor de la misma fila |
| Se paga en | Espera, y por tanto interbloqueos | Espacio, y trabajo de limpieza posterior |
| Quién lo usa hoy | SQL Server por defecto, y DB2 | **PostgreSQL, InnoDB, Oracle**, y SQLite en modo WAL |

La frase que resume el cambio de época, y que conviene decir en voz alta porque es la que ordena
todo lo demás:

> **Veredicto:** en un motor MVCC, **leer no bloquea escribir y escribir no bloquea leer**. Lo único
> que sigue bloqueando es escritor contra escritor sobre la misma fila.

**Quién lo manda:** **motor**, entero. El estándar (§9) describe qué anomalías tolera cada nivel y
**no dice nada del mecanismo**; que `REPEATABLE READ` se consiga con versiones o con bloqueos es
decisión de quien implementa, y es justo lo que hace que dos motores «con el mismo nivel» se
comporten distinto bajo carga.

**Cuánto cuesta:** MVCC cambia una moneda por otra. Deja de pagar **concurrencia** —esperas— y pasa
a pagar **espacio en disco** —las versiones que sobran— y **E/S de limpieza** —el trabajo de quitar
las que ya no mira nadie—. Las dos secciones siguientes son cada una de esas monedas en uno de los
dos motores.

---

## 3. 🧱 La versión de fila en PostgreSQL

**Qué es:** en PostgreSQL, **un `UPDATE` no modifica la fila: escribe una fila nueva y marca la
vieja como caducada**. Las dos conviven en la tabla, y cada una lleva en su cabecera dos números que
dicen en qué ventana de tiempo es visible:

```text
xmin   el identificador de la transacción que CREÓ esta versión
xmax   el de la que la borró o la reemplazó; 0 mientras sigue vigente
```

Son columnas de sistema y se pueden seleccionar por su nombre, igual que el `ctid` que ya salió en
[`03/01`](../03-el-motor-por-dentro/01-como-se-almacena-una-tabla.md) §3:

```text
tienda=# SELECT ctid, xmin, xmax, estado FROM pedidos WHERE codigo = 'PED-99999';
    ctid     | xmin | xmax | estado
-------------+------+------+---------
 (10769,104) | 1013 |    0 | ANULADO
(1 fila)

tienda=# BEGIN;
BEGIN
tienda=*# SELECT pg_current_xact_id();
 pg_current_xact_id
--------------------
               1014
(1 fila)

tienda=*# UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999';
UPDATE 1
tienda=*# SELECT ctid, xmin, xmax, estado FROM pedidos WHERE codigo = 'PED-99999';
    ctid     | xmin | xmax |  estado
-------------+------+------+-----------
 (10769,105) | 1014 |    0 | PENDIENTE
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

- **El `ctid` cambió**: la fila nueva está en otra posición de la misma página, la 105 en vez de la
  104. La versión vieja sigue en `(10769,104)`, con su `xmax` puesto al identificador de esta
  transacción, aunque desde dentro ya no la veas. Los identificadores de esta base son bajos —1013,
  1014— porque se cargó en pocas transacciones; en una con tráfico son de ocho cifras, y lo que se
  lee es la relación, no el dígito.
- **El `xmin` de la versión nueva es el identificador de quien la escribió**, que es el mismo que
  devolvió `pg_current_xact_id()`. Esa es toda la relación que hay que mirar: los dígitos concretos
  cambian en cada base.
- **Aquí se deshace con `ROLLBACK` y no hace falta compensación**, porque la sesión no confirmó. Es
  el caso cómodo; en cuanto haya que demostrar algo entre dos sesiones vuelve a mandar la regla dura
  del [README del bloque](README.md).
- **Deshacer es gratis y eso no es casualidad.** PostgreSQL no tiene que restaurar nada: la versión
  vieja nunca se tocó, y basta con anotar que la transacción abortó para que la nueva deje de ser
  visible para todo el mundo. El contraste con InnoDB está en `01` §3 y se explica por dentro en §5.

**El caso que salva el espacio: la actualización HOT.** Si el `UPDATE` **no toca ninguna columna
indexada** y la versión nueva **cabe en la misma página**, PostgreSQL la encadena desde la vieja
dentro de la página y **no escribe ninguna entrada de índice**. Es lo que hace que actualizar
`pedidos.estado` un millón de veces no multiplique por dos el tamaño de `pedidos_pkey`… siempre que
`estado` no esté indexado, que es exactamente la clase de detalle que decide si un índice «de
consulta» sale caro.

**Cuánto cuesta:** cada `UPDATE` escribe una fila entera, no el campo que cambió. Actualizar los
doscientos setenta mil pedidos del proceso nocturno escribe doscientas setenta mil filas nuevas y
deja otras tantas muertas; con la fila de `pedidos` en los ~120 bytes que midió
[`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md) §4, son unos 32 MB de
tabla que aparecen cada noche y que alguien tiene que reciclar. **Cuándo duele:** cuando la
transacción que los escribe dura mucho, o cuando hay otra abierta que impide reciclarlos (§6).

---

## 4. 🧱 La instantánea y la regla de visibilidad

**Qué es:** la instantánea (*snapshot*) es la lista de transacciones que tu sesión considera
«pasadas». No es una copia de los datos —esa es la confusión más cara del tema—: es **tres datos
sobre identificadores de transacción**, y con ellos se decide fila a fila cuál de sus versiones te
toca.

Para que el tercer trozo no salga vacío hacen falta tres sesiones más: B abre y se queda dentro —se
lleva el identificador 1019—, C abre, coge el 1020 y **confirma**, y D abre y coge el 1021. Solo
entonces A toma su instantánea:

```text
tienda=# BEGIN;
BEGIN
tienda=*# SELECT pg_current_snapshot();
 pg_current_snapshot
---------------------
 1019:1021:1019
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

Los tres trozos, separados por dos puntos, y qué significa cada uno:

- **`1019`** — por debajo de aquí, toda transacción terminó. Lo que escribieron se ve (si
  confirmaron) o no existe (si abortaron), y no hay que preguntar nada más.
- **`1021`** — por encima de aquí —el 1021 de D incluido, que estaba abierta—, no se ve nada, aunque
  confirmen antes de que tú termines. Es el corte, y por eso **D no aparece en la lista**: no hace
  falta nombrar lo que ya queda fuera por el número.
- **`1019`** — las que estaban **en curso** en ese instante **y por debajo del corte**: aquí solo B.
  Su trabajo no se ve, confirmen cuando confirmen. C, que confirmó antes del corte, sí se ve.

Con eso, la regla de visibilidad de una versión de fila cabe en dos líneas:

```text
Se ve si   xmin está confirmado y NO está en la lista de en curso
  y además xmax es 0, o está abortado, o está en la lista de en curso
```

- **Lo que separa `READ COMMITTED` de `REPEATABLE READ` es cuándo se toma esta instantánea**, y nada
  más. En `READ COMMITTED` se toma **una por sentencia**, así que la segunda consulta de tu
  transacción ve lo que se confirmó en medio. En `REPEATABLE READ` se toma **una por transacción**,
  al principio, y la misma sirve hasta el final. Ahí están, con su mecanismo, la lectura no
  repetible y el fantasma de [`02`](02-aislamiento-y-sus-fenomenos.md) §4 y §5.
- **No hay copia de nada.** Por eso abrir una transacción `REPEATABLE READ` es instantáneo aunque la
  tabla tenga un millón de filas: solo se apuntan tres números.

**Quién lo manda:** **motor**. Ni el nombre *snapshot*, ni `pg_current_snapshot()`, ni el momento en
que se toma la instantánea están en el estándar; lo único que la norma exige es el resultado
observable, que son las filas de la tabla de `02` §2.

**Cuánto cuesta:** casi nada al tomarla, y **cada vez más al mantenerla**. Mientras tu instantánea
viva, el motor no puede reciclar ninguna versión que tú todavía podrías tener que ver, y eso es §6.

> **🧠 Modelo mental.** Una instantánea no es una foto de los datos: es una **fecha de corte**. Lo
> que decide qué ves no es lo que había en la tabla, sino qué transacciones ya habían terminado
> cuando tú empezaste.

---

## 5. ⚖️ InnoDB: las versiones viven en el undo log

**Qué es:** InnoDB resuelve el mismo problema al revés. **La tabla guarda solo la versión más
reciente**, y las anteriores se reconstruyen hacia atrás desde el *undo log* (registro de deshacer),
que es una estructura aparte.

Cada fila de InnoDB lleva escondidas dos columnas de sistema que hacen el trabajo de `xmin` y
`xmax`:

| Columna oculta | Tamaño | Qué guarda |
|---|---|---|
| `DB_TRX_ID` | 6 bytes | La última transacción que tocó la fila |
| `DB_ROLL_PTR` | 7 bytes | Puntero al registro de *undo* con la versión anterior |

Y la *read view* —el equivalente de la instantánea— hace esto: si el `DB_TRX_ID` de la fila no es
visible para ti, **sigues el `DB_ROLL_PTR` hacia atrás**, aplicando registros de *undo* uno tras
otro, hasta llegar a una versión que sí lo sea. Reconstruir, no leer.

Las cuatro consecuencias que de verdad se notan, y que son las que hay que saber contrastar:

- **La tabla no se hincha con las versiones viejas**, porque no están ahí. Lo que crece es el
  espacio de *undo*, que es otro fichero y se vigila aparte.
- **Deshacer es caro.** Un `ROLLBACK` de un millón de filas tiene que **aplicar el millón de
  registros de *undo* al revés**, y puede tardar más que el trabajo que deshace. En PostgreSQL ese
  mismo `ROLLBACK` es una anotación y termina al instante (§3). Es la diferencia que `01` §3 plantea
  y que aquí tiene su porqué.
- **Leer versiones viejas es caro, y cuanto más vieja, más.** Una transacción larga en `REPEATABLE
  READ` obliga a recorrer cadenas de *undo* cada vez más largas para ver «su» versión: el informe no
  espera a nadie, pero se va volviendo más lento según envejece su *read view*.
- **El hilo de purga** (*purge thread*) es quien borra los registros de *undo* que ya no puede
  necesitar ninguna *read view*. Si va por detrás, el indicador es `History list length` en `SHOW
  ENGINE INNODB STATUS`, y su equivalente conceptual en PostgreSQL es el recuento de filas muertas
  de §6.

**Quién lo manda:** **motor**. Ni el *undo log*, ni la *read view*, ni el hilo de purga aparecen en
el estándar; son la implementación de InnoDB, y MySQL solo los garantiza para ese motor de
almacenamiento.

**Cuánto cuesta:** espacio de *undo* mientras haya lectores antiguos, E/S de reconstrucción en cada
lectura de una versión pasada, y un `ROLLBACK` proporcional al trabajo hecho. **Cuándo gana:** en
tablas con muchísima actualización de las mismas filas, donde PostgreSQL acumularía versiones
muertas en la tabla y aquí no. **Cuándo pierde:** en lotes enormes que se deshacen, y en informes
larguísimos que arrastran cadenas de *undo*.

> **💡 Truco.** Cuando alguien pregunta «¿PostgreSQL o MySQL para esta tabla?», el argumento
> defendible en un minuto no es el rendimiento en abstracto: es **dónde prefieres pagar las
> versiones**. Si el patrón es actualizar mil veces las mismas filas, InnoDB no engorda la tabla. Si
> el patrón es insertar y leer, y los `ROLLBACK` grandes existen, PostgreSQL deshace gratis.

---

## 6. 🩺 El precio de MVCC: filas muertas, VACUUM y el horizonte

**Qué es:** la factura de §3. Las versiones que ya no puede ver nadie son **filas muertas** (*dead
tuples*): ocupan sitio en la página, no las devuelve ninguna consulta, y solo `VACUUM` las convierte
en espacio reutilizable.

```text
tienda=# SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
           FROM pg_stat_user_tables WHERE relname = 'pedidos';
 relname | n_live_tup | n_dead_tup |        last_autovacuum
---------+------------+------------+-------------------------------
 pedidos |    1000000 |      79426 | 2026-09-20 16:22:18.124547+00
(1 fila)
```

- **Esa salida es de esta base y de este momento**, y es la única cifra del capítulo que cambia
  sola: `n_dead_tup` sube con cada `UPDATE` del bloque y baja cuando pasa el autovacuum. Lo estable
  es la forma: un millón vivas, decenas de miles muertas, una fecha de última limpieza.

- **`VACUUM` casi nunca devuelve el espacio al sistema de ficheros**: lo marca como reutilizable
  dentro de la tabla. La excepción son **las páginas vacías del final del fichero**, que trunca si
  consigue un instante de bloqueo exclusivo. Corrido con `VERBOSE` mientras se escribía
  [`05`](05-optimista-pesimista-y-transacciones-largas.md): con otra sesión leyendo `pedidos` dijo
  `stopping truncate due to conflicting lock request`, y sin ella, `truncated 17640 to 10770 pages`.
  El hueco del medio solo lo recupera `VACUUM FULL`, que **reescribe la tabla entera y la bloquea en
  exclusiva**. Por eso se dice que el *bloat* se previene, no se cura.
- **El autovacuum se dispara por proporción**, no por número: cuando las filas muertas superan
  cierto porcentaje de la tabla. En una tabla de un millón de filas eso es mucho tiempo acumulando.

**Y el mecanismo que hay que saber explicar, porque es la causa raíz de casi todos los incidentes de
espacio: el horizonte.** `VACUUM` solo puede quitar una versión si **ninguna transacción abierta
podría tener que verla**. La transacción abierta más antigua fija ese horizonte, y mientras siga
ahí, el motor no recicla nada posterior —aunque esa transacción esté inactiva y no haya tocado esa
tabla jamás—.

```text
La consola abierta desde el martes, con un BEGIN olvidado
        -> el horizonte se queda en el martes
        -> VACUUM no borra nada escrito desde el martes
        -> la tabla crece, los índices crecen, y los planes empeoran
```

- **El equivalente en InnoDB es la *read view* antigua**, que impide purgar el *undo*: el mismo
  incidente con otro nombre y otro fichero creciendo.
- **Esto ya apareció como diagnóstico en `01`**, en la pregunta de la base que crece aunque se
  borren filas. Aquí está el porqué completo.

> **🩺 Diagnóstico.** Ante una tabla que crece sin parar, la primera consulta no es sobre la tabla:
> es sobre las transacciones abiertas. En PostgreSQL, `pg_stat_activity` filtrada por `xact_start`
> ordenada de más antigua a más reciente —la consulta está en
> [`02`](02-aislamiento-y-sus-fenomenos.md) §9—; en MySQL, `History list length`. Si arriba hay una
> transacción de hace horas en estado `idle in transaction`, ya tienes la causa y no hace falta
> mirar nada más.

**Cuánto cuesta:** el `VACUUM` gasta E/S y CPU en segundo plano, y **no gastarlo** cuesta disco,
páginas más vacías —y por tanto más páginas leídas por la misma consulta— y estadísticas peores.
**Cuándo se toca la configuración:** cuando una tabla concreta se actualiza mucho más que el resto y
el disparador general le queda grande. **Cuándo no:** apagar el autovacuum «para que no moleste»,
que es cambiar un coste continuo y medido por uno acumulado e imprevisible.

---

## 7. 🧱 Lo que MVCC no resuelve

**Qué es:** el límite del mecanismo, y la razón de que el capítulo siguiente exista. MVCC quita las
esperas entre lectores y escritores. **No quita ninguna de estas tres:**

| Caso | Qué hace MVCC | Qué hace falta de verdad |
|---|---|---|
| Dos transacciones actualizan la misma fila | Nada: la segunda espera al `COMMIT` de la primera | Nada más; es el bloqueo de fila, y es inevitable |
| Leo, decido en la aplicación y escribo | Nada: mi instantánea no impide que otro escriba antes | `SELECT … FOR UPDATE`, o una columna de versión |
| Leo un conjunto, decido, escribo **otra** fila | Nada: es el *write skew* de `02` §7 | `SERIALIZABLE`, o materializar el conflicto |

- **La fila del medio es la que más se confunde en entrevista.** «Estoy en `REPEATABLE READ`, así
  que mi lectura es estable» es cierto, y no sirve de nada: que tu lectura sea estable no impide que
  otro escriba esa fila y confirme. En PostgreSQL te enterarás al escribir tú, con el `40001` de
  `02` §6; en InnoDB, ni eso.
- **Un bloqueo explícito sigue siendo un bloqueo**, con sus esperas y sus interbloqueos, dentro de
  un motor MVCC. Es exactamente el material de [`04`](04-bloqueos-e-interbloqueos.md).

**Cuánto cuesta cerrar el hueco:** con `FOR UPDATE`, espera; con columna de versión, reintentos; con
`SERIALIZABLE`, abortos. Las tres monedas son las de `02` §2, y la elección concreta es de
[`05`](05-optimista-pesimista-y-transacciones-largas.md).

---

## 8. 🔭 Dónde aparece de verdad

Tres situaciones que un backend se encuentra y que son este capítulo, aunque nadie las llame MVCC:

- **«La base ocupa el triple y solo tenemos un millón de pedidos».** Alguien dejó una consola
  abierta con una transacción, o un servicio con el pool mal configurado mantiene una transacción
  por conexión ociosa. El horizonte de §6 no avanza y el `VACUUM` no recicla nada.
- **«El informe nocturno cada vez tarda más, y la consulta no ha cambiado».** En PostgreSQL suele
  ser *bloat*: las mismas filas vivas repartidas en más páginas. En MySQL, la cadena de *undo* que
  el informe recorre para ver su versión.
- **«Migramos de MySQL a PostgreSQL y ahora los despliegues con `ROLLBACK` van rapidísimo, pero el
  disco sube».** Las dos mitades de §3 y §5, y conviene decirlas juntas: no se ganó ni se perdió, se
  cambió de moneda.

---

## 9. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Para este
> capítulo eso casi no importa, y es en sí la respuesta: **la norma no habla de mecanismos**, así
> que todas las filas de abajo salvo la primera son de motor.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|---|
| La norma fija cómo se implementa el aislamiento | **No**: solo qué anomalías se toleran | MVCC con versiones en la tabla | MVCC con *undo log* | Un escritor, con instantánea en modo WAL |
| La versión antigua se queda en la tabla | No lo define | **Sí**, con `xmin`/`xmax` | No: se reconstruye desde el *undo* | No aplica |
| Leer bloquea a quien escribe | No lo define | No | No | No en modo WAL; sí en modo *journal* |
| `ROLLBACK` es proporcional al trabajo hecho | No lo define | **No**: es una anotación | **Sí**: aplica el *undo* al revés | Sí: restaura desde el *journal* |
| Hay que limpiar las versiones viejas | No lo define | `VACUUM` / autovacuum | Hilo de purga del *undo* | El `checkpoint` del WAL |
| Una transacción abierta frena la limpieza | No lo define | Sí: fija el horizonte | Sí: mantiene la *read view* | Sí: retiene el WAL |
| Las columnas de versión son visibles | No lo define | Sí: `xmin`, `xmax`, `ctid` | No: `DB_TRX_ID` está oculta | No hay equivalente |

**Convención, las dos que más se repiten.** *«MVCC significa que no hay bloqueos»* — hay bloqueo de
escritor contra escritor siempre, y bloqueo explícito cuando lo pides (§7); lo que MVCC elimina es
el bloqueo **entre lector y escritor**. Y *«el `VACUUM` libera espacio en disco»* — casi nunca: lo
marca como reutilizable dentro de la tabla y solo trunca las páginas vacías del final; quien encoge
el fichero entero es `VACUUM FULL`, con la tabla bloqueada en exclusiva mientras se reescribe.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La instantánea es una copia de los datos" | Son tres datos sobre identificadores de transacción: el corte inferior, el superior y la lista de las que estaban en curso. Por eso abrirla es instantáneo con un millón de filas |
| "En PostgreSQL un `UPDATE` modifica la fila" | Escribe una versión nueva y marca la vieja con su `xmax`. El `ctid` cambia, y por eso `ctid` no sirve como identificador |
| "MVCC quiere decir que nada espera" | Dos escrituras sobre la misma fila esperan igual. Lo que no espera es el lector frente al escritor |
| "El `ROLLBACK` cuesta lo mismo en los dos motores" | En PostgreSQL es una anotación y termina al instante; en InnoDB aplica el *undo* al revés y puede tardar más que el trabajo deshecho |
| "El `VACUUM` devuelve el espacio al disco" | Lo deja reutilizable dentro de la tabla, salvo las páginas vacías del final, que trunca si consigue el bloqueo. Encoger el resto es `VACUUM FULL`, que bloquea la tabla en exclusiva |
| "Si borro filas, la tabla encoge" | Un `DELETE` solo pone el `xmax`. Hasta que `VACUUM` pase, y si el horizonte se lo permite, el espacio sigue ocupado |
| "Una transacción inactiva no molesta" | Si está abierta, fija el horizonte y **bloquea la limpieza de toda la base**, aunque no haya tocado ninguna tabla |
| "InnoDB no tiene MVCC porque guarda una sola versión en la tabla" | Tiene MVCC: las versiones anteriores se reconstruyen desde el *undo log* siguiendo `DB_ROLL_PTR` |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Introduction» del capítulo de control de concurrencia: la
  definición de MVCC del propio motor. <https://www.postgresql.org/docs/18/mvcc-intro.html>
- **Documentación** — PostgreSQL 18, «Routine Vacuuming»: filas muertas, horizonte y qué hace de
  verdad el autovacuum. <https://www.postgresql.org/docs/18/routine-vacuuming.html>
- **Documentación** — PostgreSQL 18, «Heap-Only Tuples (HOT)»: cuándo un `UPDATE` no toca los
  índices. <https://www.postgresql.org/docs/18/storage-hot.html>
- **Documentación** — PostgreSQL 18, «System Columns»: `xmin`, `xmax`, `ctid` y por qué no son
  identificadores. <https://www.postgresql.org/docs/18/ddl-system-columns.html>
- **Documentación** — MySQL 9.7, «InnoDB Multi-Versioning»: `DB_TRX_ID`, `DB_ROLL_PTR` y la
  reconstrucción. <https://dev.mysql.com/doc/refman/9.7/en/innodb-multi-versioning.html>
- **Documentación** — MySQL 9.7, «Undo Logs»: dónde vive el espacio que crece cuando la purga se
  retrasa. <https://dev.mysql.com/doc/refman/9.7/en/innodb-undo-logs.html>
- **Documentación** — SQLite, «Write-Ahead Logging»: cómo un motor de un solo escritor consigue que
  los lectores no esperen. <https://www.sqlite.org/wal.html>
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo 7,
  apartado «Snapshot Isolation and Repeatable Read».

---

## 🧠 Preguntas

1. ¿Qué guardan exactamente `xmin` y `xmax` en una versión de fila de PostgreSQL? 🟢
2. ¿Qué le pasa al `ctid` de una fila cuando la actualizas? 🟢
3. ¿Qué es una fila muerta y quién la recicla? 🟢
4. Nombra las dos columnas ocultas con las que InnoDB hace el trabajo de `xmin` y `xmax`. 🟢
5. ¿Qué es el horizonte y qué lo fija? 🟢
6. Distingue MVCC de bloqueo de dos fases: ¿quién espera a quién en cada uno? 🟡
7. ¿Qué es una instantánea, y por qué tomarla es instantáneo aunque la tabla tenga un millón de
   filas? 🟡
8. ¿Qué cambia entre `READ COMMITTED` y `REPEATABLE READ` en términos de instantánea, y solo en esos
   términos? 🟡
9. ¿Dónde está la versión antigua de una fila en PostgreSQL y dónde en InnoDB? Di qué crece en cada
   caso y qué categoría es esa diferencia. 🟡
10. ¿Está MVCC en el estándar? Responde por separado para la norma y para los tres motores del
    corpus. 🟡
11. Explica por qué `VACUUM` casi nunca encoge el fichero de la tabla, en qué caso sí lo hace y qué
    lo encoge siempre, con su precio. 🟡
12. Explica por qué un `ROLLBACK` de un millón de filas termina al instante en PostgreSQL y puede
    tardar minutos en InnoDB. 🟠
13. ¿Qué es una actualización HOT, qué dos condiciones pide y qué ahorra exactamente? 🟠
14. Una consola con un `BEGIN` olvidado desde el martes. Explica la cadena completa hasta que el
    disco se llena, paso a paso. 🟠
15. Estás en `REPEATABLE READ` y otra sesión actualiza y confirma una fila que leíste. ¿Te protege
    tu instantánea de escribir sobre un dato caducado? Responde para los dos motores. 🟠
16. Un informe en MySQL va perdiendo velocidad según avanza, sin que cambie la consulta ni los
    datos. Da el mecanismo y el indicador que lo confirma. 🟠
17. Alguien propone apagar el autovacuum «porque mete ruido en las horas punta». Dale la
    contrapartida en las cinco monedas que apliquen. 🟠
18. Diagnostica: la tabla `pedidos` ocupa el triple de lo que deberían pesar sus filas vivas. Da
    tres hipótesis en orden de probabilidad, la consulta con la que confirmarías la primera, y qué
    harías antes de tocar nada. 🔴
19. Escribe la sesión de `psql` —sentencia a sentencia, y dejando los datos como estaban— que enseña
    que un `UPDATE` crea una versión nueva: qué seleccionas antes, qué después, y qué tres valores
    comparas. 🔴
20. Tienes una tabla de saldos que se actualiza cien veces por segundo sobre las mismas mil filas.
    Defiende PostgreSQL o InnoDB para ese caso concreto, con el mecanismo y el coste de cada uno, y
    di qué medirías para comprobar que acertaste. 🔴

---

**Anterior:** [`02`](02-aislamiento-y-sus-fenomenos.md) — los niveles y los fenómenos que aquí se
explican por dentro · **Siguiente:** [`04`](04-bloqueos-e-interbloqueos.md) — lo único que MVCC no
quita: el bloqueo entre dos que escriben · **Relacionado:**
[`03/01`](../03-el-motor-por-dentro/01-como-se-almacena-una-tabla.md) — la página, el `ctid` y el
ancho de fila que aquí se multiplican por cada versión · [`01`](01-acid-con-precision.md) — el
`ROLLBACK` cuyo precio se explica en §3 y §5.
