# l00 — El entorno y los datos

> Levantar los cinco motores del corpus, cargar la tienda en PostgreSQL —un millón de pedidos,
> determinista— y llevar **exactamente las mismas filas** a MySQL, MariaDB y SQLite, comprobando
> cada carga con su verificación. Por el camino se provocan los cinco errores que más tiempo se
> pierden en un entorno así: el puerto ocupado, el rol que aún no existe, el `LOCAL INFILE`
> rechazado, el `UNIQUE` que rompe la importación y el privilegio que falta. **Tiempo estimado:** 25
> minutos, cuatro de ellos esperando cargas. **Asume instalado:** Docker, y los clientes `psql`,
> `mysql` y `sqlite3` en la máquina. **Vigencia:** 26 de septiembre de 2026.

---

## Salto rápido

- [1. Qué vas a ver](#1--qué-vas-a-ver) · [2. Paso 1 — Levantar los
  motores](#2--paso-1--levantar-los-motores)
- [3. Paso 2 — El puerto ocupado](#3--paso-2--el-puerto-ocupado) · [4. Paso 3 — PostgreSQL: esquema,
  semilla y verificación](#4--paso-3--postgresql-esquema-semilla-y-verificación)
- [5. Paso 4 — MySQL y MariaDB, desde CSV](#5--paso-4--mysql-y-mariadb-desde-csv) · [6. Paso 5 —
  SQLite, en un fichero](#6--paso-5--sqlite-en-un-fichero)
- [7. Paso 6 — Redis, MongoDB y los lenguajes](#7--paso-6--redis-mongodb-y-los-lenguajes) · [8. Paso
  7 — Lo que el rol de la aplicación no puede
  hacer](#8--paso-7--lo-que-el-rol-de-la-aplicación-no-puede-hacer)
- [9. El teardown, entero](#9--el-teardown-entero) · [Ejercicios](#-ejercicios) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 Qué vas a ver

Todo el corpus pega sesiones contra una tienda concreta: `PED-00042` está `PAGADO` y tiene tres
líneas, `CLI-00311` tiene 52 pedidos, `pedidos` ocupa 10 770 páginas. Si tu base no tiene esos datos
exactos, ningún plan de los bloques 03 y 04 se parece al tuyo, y no sabrás si la diferencia es del
motor o de los datos. Este lab deja la base en ese estado y lo comprueba.

Las tres decisiones del entorno que conviene entender antes de empezar:

- **Versiones fijas, nunca `latest`**: `postgres:18.6`, `mysql:9.7.2`, `mariadb:12.3.3`,
  `redis:8.10.1`, `mongo:8.0.20`. Una imagen móvil cambiaría los planes con cada publicación.
- **PostgreSQL genera; los demás importan.** MySQL y SQLite no tienen `generate_series` ni
  `setseed`; una semilla propia en cada motor daría otra tienda. Exportando a CSV, **los cuatro
  motores quedan con las mismas filas y los mismos `id`**.
- **La semilla es determinista**: `setseed(0.42)` fija el generador al azar antes del primer
  `random()`. Misma semilla, mismos datos, mismos planes.

> **📝 Contexto.** Todas las salidas de este lab están corridas. Las de §2, §3, §7 y §8 salen del
> entorno del corpus, `bd-lab`. **Las cargas de §4 a §6 se corrieron en una copia aislada**, con el
> mismo `compose` bajo otro nombre de proyecto y los puertos desplazados en 10 000, porque cargar de
> nuevo `bd-lab` borraría el estado que el resto del corpus necesita. La única huella visible es el
> puerto `15432` en el mensaje de error de §4. Los CSV y `tienda.db` de la copia **pesan byte a byte
> lo mismo** que los del corpus. **Denso**: 550 líneas, podado en prosa.

---

## 2. 🧱 Paso 1 — Levantar los motores

Desde la raíz del corpus:

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.yml up -d
docker compose -f 13-laboratorio/entorno/docker-compose.yml ps
```

- `-f …` apunta al `compose` sin cambiar de directorio: todas las órdenes del lab van desde la raíz
  del corpus. `up -d` crea lo que falte —red, volúmenes, contenedores— y arranca los cinco servicios
  en segundo plano. `ps` lista su estado; lo que hay que esperar en `STATUS` es `(healthy)`.

```text
 Container bd-lab-maria Recreate
 Container bd-lab-mysql Recreate
 Container bd-lab-redis Recreate
 Container bd-lab-redis Recreated
 Container bd-lab-maria Recreated
 Container bd-lab-mysql Recreated
 Container bd-lab-postgres Starting
 Container bd-lab-redis Starting
 Container bd-lab-mongo Starting
 Container bd-lab-mysql Starting
 Container bd-lab-maria Starting
 Container bd-lab-postgres Started
 Container bd-lab-redis Started
 Container bd-lab-mongo Started
 Container bd-lab-mysql Started
 Container bd-lab-maria Started
---
NAME              IMAGE            COMMAND                  SERVICE    CREATED                  STATUS                                     PORTS
bd-lab-maria      mariadb:12.3.3   "docker-entrypoint.s…"   maria      Less than a second ago   Up Less than a second (health: starting)   0.0.0.0:3307->3306/tcp, [::]:3307->3306/tcp
bd-lab-mongo      mongo:8.0.20     "docker-entrypoint.s…"   mongo      2 hours ago              Up Less than a second (health: starting)   0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
bd-lab-mysql      mysql:9.7.2      "docker-entrypoint.s…"   mysql      Less than a second ago   Up Less than a second (health: starting)   0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp
bd-lab-postgres   postgres:18.6    "docker-entrypoint.s…"   postgres   58 seconds ago           Up Less than a second (health: starting)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
bd-lab-redis      redis:8.10.1     "docker-entrypoint.s…"   redis      Less than a second ago   Up Less than a second (health: starting)   0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
```

- **`Recreate` no es un error**: el `compose` había cambiado desde que se crearon tres contenedores,
  y los rehízo. Los datos viven en **volúmenes con nombre**, que sobreviven al contenedor. La
  primera vez verás `Created`.
- **`health: starting` es «todavía no»**: cada servicio lleva su `healthcheck`, y en menos de
  quince segundos los cinco estaban en `(healthy)`. Conectarse antes da errores que parecen de
  credenciales.
- **MariaDB está en el 3307**: habla el mismo protocolo que MySQL y no pueden compartir puerto.

**Teardown de este paso** —para los contenedores y conserva todo—:

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.yml stop
```

- `stop` detiene los procesos sin borrar contenedores ni volúmenes; `up -d` los vuelve a arrancar
  con los datos cargados.

---

## 3. 🩺 Paso 2 — El puerto ocupado

**El error, a propósito.** Con `bd-lab-redis` en marcha, se intenta arrancar otro Redis en el mismo
puerto, que es lo que pasa cuando otro proyecto de la máquina ya tiene uno:

```bash
docker run -d --rm --name choque-redis -p 6379:6379 redis:8.10.1
```

- `run -d` arranca un contenedor suelto, fuera del `compose`; `--rm` lo borra al pararse; `-p
  6379:6379` publica su puerto en el 6379 del anfitrión, el que ya tiene `bd-lab-redis`.

```text
db7a0d5faaebd3c00d626ecc911d5ff14f68f57e09682533b6393586a6e92802
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint choque-redis (51c6726753cc7c504c13476d9c0ae748dd8661de3616cbea331c77c48c1399ab): Bind for 0.0.0.0:6379 failed: port is already allocated
```

- **El contenedor se crea y no arranca**; con `--rm` desaparece solo. El diagnóstico es una línea:

```bash
docker ps --format '{{.Names}}\t{{.Ports}}' | grep 6379
```

- `--format` elige las columnas con una plantilla de Go: nombre y puertos, separados por un
  tabulador. `grep 6379` deja solo la fila del puerto en disputa.

```text
bd-lab-redis	0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
```

**La corrección es parar el otro contenedor, no cambiar el puerto del corpus**: todas las sesiones
pegadas usan los puertos estándar, y cambiarlos en tu `compose` rompe cada orden que copies.

---

## 4. 🧱 Paso 3 — PostgreSQL: esquema, semilla y verificación

**El error, a propósito.** Antes de cargar nada, conectarse como el rol de la aplicación:

```bash
PGPASSWORD=tienda_app psql -h 127.0.0.1 -U tienda_app -d tienda -c "SELECT 1"
```

- `PGPASSWORD` pasa la contraseña por el entorno, solo para esta orden. `-h 127.0.0.1` fuerza TCP
  —sin él, `psql` probaría el *socket* Unix de tu máquina—; `-U` es el rol, `-d` la base y `-c` la
  sentencia que se ejecuta antes de salir.

```text
psql: error: falló la conexión al servidor en «127.0.0.1», puerto 15432: FATAL:  password authentication failed for user "tienda_app"
```

- **El rol todavía no existe, y el mensaje no lo dice.** PostgreSQL responde igual a un rol
  inexistente que a una contraseña mala: decirlo le contaría a un atacante qué nombres son válidos.
  Los roles los crea `esquema.sql`.

Las tres órdenes de la carga, como superusuario:

```bash
export PGPASSWORD=postgres
psql -h 127.0.0.1 -U postgres -d tienda -f 13-laboratorio/entorno/esquema.sql
psql -h 127.0.0.1 -U postgres -d tienda -f 13-laboratorio/entorno/semilla.sql
psql -h 127.0.0.1 -U postgres -d tienda -f 13-laboratorio/entorno/verificar.sql
```

- `-f` ejecuta un fichero entero, sentencia a sentencia, y muestra la respuesta de cada una.
- **`esquema.sql` empieza borrando las seis tablas**: es su propio teardown si una carga queda a
  medias. Crea las tablas —sin más índices que los de sus claves— y los roles `tienda_app`,
  `tienda_ro` y `tienda_admin`, en 95 ms.
- **`semilla.sql` tardó 117 s**, y con `\timing on` imprime cada fase:

| Fase | Filas | Tiempo |
|---|---|---|
| `pedidos` | 1 000 000 | 12,3 s |
| `pedido_lineas` | 3 500 000 | 31,1 s |
| `pedidos.total`, calculado desde las líneas | 1 000 000 | 15,2 s |
| `pagos` | 820 000 | 7,4 s |
| `eventos_pedido` | 4 100 000 | 31,4 s |
| `VACUUM FULL` y `ANALYZE` de las seis tablas | — | 11,5 s |

- **El último paso deja la base como el corpus la describe**: tablas compactas, estadísticas tomadas
  y el mapa de visibilidad de `pedidos` vacío, que `03/03` §6 enseña con `Heap Fetches`. La
  verificación, entera:

```text
                       Verificacion del conjunto de datos
+----+----------------------------------------+-----------+-----------+--------+
| #  |              Comprobacion              | Esperado  |   Real    | Estado |
+----+----------------------------------------+-----------+-----------+--------+
| 01 | clientes                               | 50,000    | 50,000    | OK     |
| 02 | productos                              | 5,000     | 5,000     | OK     |
| 03 | pedidos                                | 1,000,000 | 1,000,000 | OK     |
| 04 | pedido_lineas                          | 3,500,000 | 3,500,000 | OK     |
| 05 | pagos                                  | 820,000   | 820,000   | OK     |
| 06 | eventos_pedido                         | 4,100,000 | 4,100,000 | OK     |
| 07 | PED-00042 es el pedido de id 42        | 1         | 1         | OK     |
| 08 | PED-00042 tiene 3 lineas               | 3         | 3         | OK     |
| 09 | PED-00042 esta PAGADO                  | 1         | 1         | OK     |
| 10 | PED-99999 esta ANULADO                 | 1         | 1         | OK     |
| 11 | PED-99999 no tiene pagos               | 0         | 0         | OK     |
| 12 | CLI-00311 tiene 52 pedidos             | 52        | 52        | OK     |
| 13 | CLI-00311 es de ES y alta en 2024      | 1         | 1         | OK     |
| 14 | CLI-00007 no tiene pedidos             | 0         | 0         | OK     |
| 15 | PRD-00017 es de categoria audio        | 1         | 1         | OK     |
| 16 | PRD-00017 es el mas vendido (lineas)   | 1         | 1         | OK     |
| 17 | PRD-00017 es el mas vendido (unidades) | 1         | 1         | OK     |
| 18 | PRD-04980 esta inactivo                | 1         | 1         | OK     |
| 19 | pedidos sin pago = PENDIENTE+ANULADO   | 180,000   | 180,000   | OK     |
| 20 | pedidos con total desincronizado       | 0         | 0         | OK     |
| 21 | pagos en EFECTIVO sin referencia       | 0         | 0         | OK     |
| 22 | pedidos con actualizado_en no nulo     | 0         | 0         | OK     |
+----+----------------------------------------+-----------+-----------+--------+
(22 filas)
```

- **Una sola fila en `FALLA` y la carga se repite** desde `esquema.sql`. Después imprime el reparto
  por estado y el tamaño de cada tabla: `pedidos` en **136 MB y 10 770 páginas**, la cifra de todos
  los planes del bloque 03.

---

## 5. 🧱 Paso 4 — MySQL y MariaDB, desde CSV

Primero la exportación, desde `13-laboratorio/entorno/`, porque `\copy` escribe en `datos/` relativo
al directorio actual:

```bash
cd 13-laboratorio/entorno
psql -h 127.0.0.1 -U postgres -d tienda -f exportar-csv.sql
```

- `\copy` es el `COPY` del **cliente**: `psql` escribe el fichero en tu máquina. El `COPY … TO` del
  servidor lo escribiría dentro del contenedor.

```text
>> exportando a datos/
COPY 50000
COPY 5000
COPY 1000000
COPY 3500000
COPY 820000
COPY 4100000
exportar-csv.sql: seis ficheros en datos/.
```

- 13 s y 779 MB. Convierte por el camino lo que MySQL leería mal: marcas de tiempo a texto UTC,
  booleanos a 0/1 y nulos a `\N`.

**El error, a propósito.** Se crea el esquema de MySQL y se carga **sin** la bandera del cliente:

```bash
docker exec -i bd-lab-mysql mysql -uroot -proot tienda < esquema-mysql.sql
docker exec -i bd-lab-mysql mysql -uroot -proot tienda < semilla-mysql.sql
```

- `docker exec -i` ejecuta el cliente `mysql` **dentro** del contenedor con tu entrada conectada: el
  `<` le pasa el fichero. Dentro, los CSV están en `/entorno/datos`, donde el `compose` monta esta
  carpeta.
- `-uroot -proot` son usuario y contraseña pegados a la bandera, como los quiere el cliente de
  MySQL.

```text
>> clientes
ERROR 2068 (HY000) at line 31: LOAD DATA LOCAL INFILE file request rejected due to restrictions on access.
```

- **`LOCAL INFILE` necesita permiso en los dos lados.** El servidor lo tiene en el `compose`; falta
  el cliente. `LOCAL` significa que el fichero lo lee el cliente; sin `LOCAL` lo leería el servidor,
  y solo desde su `secure_file_priv`.

La corrección, rehaciendo el esquema para empezar de cero:

```bash
docker exec -i bd-lab-mysql mysql -uroot -proot tienda < esquema-mysql.sql
docker exec -i bd-lab-mysql mysql --local-infile=1 -uroot -proot tienda < semilla-mysql.sql
docker exec -i bd-lab-mysql mysql -uroot -proot -t tienda < verificar-mysql.sql
```

- `--local-infile=1` es la bandera que faltaba; `-t` pide la tabla con bordes. Cargó en **56 s**.
  La verificación son las 22 de PostgreSQL más cuatro de la importación; estas son las cuatro
  últimas filas:

```text
| 23   | productos inactivos (booleano convertido)         | 101       | 101       | OK     |
| 24   | pagos con referencia nula (NULL, no cadena vacia) | 273,126   | 273,126   | OK     |
| 25   | ningun pago con referencia vacia                  | 0         | 0         | OK     |
| 26   | el JSON llego como JSON, no como texto            | 4,100,000 | 4,100,000 | OK     |
```

- Las filas 01 a 22 salieron iguales que en PostgreSQL. **MariaDB es la misma secuencia** con
  `docker exec -i bd-lab-maria mariadb …`, en 30 s. Para no leer 26 filas a ojo, se cuentan:

```bash
docker exec -i bd-lab-maria mariadb -uroot -proot -t tienda < verificar-mysql.sql | grep -c "| OK"
```

```text
26
```

**Teardown de este paso:** `esquema-mysql.sql` borra y rehace las tablas. Los CSV se pueden borrar
cuando los tres motores estén cargados; se regeneran en 13 s.

---

## 6. 🧱 Paso 5 — SQLite, en un fichero

SQLite no tiene servicio: la base es `datos/tienda.db` y el cliente, el binario `sqlite3` 3.53.4.
**El de macOS en `/usr/bin` es más viejo**; usa el de tu gestor de paquetes.

**El error, a propósito.** Se crea el esquema y se importa `pagos` directamente:

```bash
sqlite3 datos/tienda.db < esquema-sqlite.sql
printf '.bail on\n.import --csv datos/pagos.csv pagos\n' | sqlite3 datos/tienda.db
```

- `.bail on` para en el primer error en vez de seguir. `.import --csv` lee el CSV fila a fila y hace
  un `INSERT` por cada una.

```text
datos/pagos.csv:5: INSERT failed: UNIQUE constraint failed: pagos.referencia
```

- **`.import` no entiende de nulos**: el `\N` le llega como la cadena `'\N'`, y el segundo pago en
  efectivo choca contra el `UNIQUE`. Dejó **4 filas** a medias. Por eso `semilla-sqlite.sql` importa
  `pagos` en una tabla de paso, convierte `'\N'` en `NULL` y solo entonces copia a la tabla real.

La corrección:

```bash
sqlite3 datos/tienda.db < esquema-sqlite.sql
sqlite3 datos/tienda.db < semilla-sqlite.sql
```

- El esquema de nuevo, para quitar las 4 filas, y la semilla, que tardó **28 s**. La verificación
  son 17 comprobaciones; como con MariaDB, se cuentan:

```bash
sqlite3 datos/tienda.db < verificar-sqlite.sql | grep -c "| OK"
```

```text
17
```

**Teardown de este paso:** borrar `datos/tienda.db`, un fichero de 855 MB.

---

## 7. 🧱 Paso 6 — Redis, MongoDB y los lenguajes

Redis y MongoDB no se cargan aquí: sus datos los crean los bloques 07 y 08. Basta con saber que
responden:

```bash
docker exec bd-lab-redis redis-cli ping
docker exec bd-lab-mongo mongosh --quiet -u root -p root --eval 'db.adminCommand({ping:1})'
```

- `redis-cli ping` manda `PING` al servidor del contenedor. `mongosh --quiet` abre el intérprete de
  MongoDB sin cabecera, y `--eval` ejecuta una expresión y sale.

```text
PONG
{ ok: 1 }
```

Los cuatro lenguajes de los bloques 10 y 11 viven en el perfil `lenguajes`, que `up -d` no levanta:

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.yml --profile lenguajes build
docker compose -f 13-laboratorio/entorno/docker-compose.yml run --rm -q python python -c "import psycopg; c = psycopg.connect(); print(c.execute('SELECT current_user, version()').fetchone()); print(c.execute('SELECT count(*) FROM pedidos').fetchone())"
```

- `--profile lenguajes build` construye las imágenes de Java, Python, Node y Go con sus bibliotecas
  en versión exacta: minutos la primera vez, segundos después.
- `run --rm -q python` arranca un contenedor efímero del servicio `python`, sin mensajes de
  `compose`, y lo borra al terminar. Se conecta sin argumentos: el servicio trae `PGHOST`, `PGUSER`…

```text
('tienda_app', 'PostgreSQL 18.6 (Debian 18.6-1.pgdg13+2) on aarch64-unknown-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit')
(1000000,)
```

- **Se conecta como `tienda_app`**, por el nombre del servicio `postgres` en la red del `compose`.
  Correr Testcontainers desde aquí necesita dos banderas más:
  [`11/05`](../11-orms/05-probar-contra-base-de-datos-real.md) §5.

---

## 8. 🩺 Paso 7 — Lo que el rol de la aplicación no puede hacer

`tienda_app` lee y escribe datos, y nada más. Se comprueba con dos cosas que no debería poder hacer:

```bash
PGPASSWORD=tienda_app psql -h 127.0.0.1 -U tienda_app -d tienda \
  -c "CREATE TABLE prueba (id int)" -c "DELETE FROM pedidos WHERE id = 42"
```

- Varios `-c` van en orden, cada uno en su transacción: el primer fallo no impide el segundo.

```text
ERROR:  permission denied for schema public
LÍNEA 1: CREATE TABLE prueba (id int)
                      ^
ERROR:  update or delete on table "pedidos" violates foreign key constraint "pagos_pedido_id_fkey" on table "pagos"
DETALLE:  Key (id)=(42) is still referenced from table "pagos".
```

- **El primero es el privilegio**: `tienda_app` no tiene `CREATE` en el esquema `public`. Es la
  segunda línea de defensa de
  [`10/02`](../10-interfaz-con-los-lenguajes/02-parametrizadas-e-inyeccion.md) §6: una inyección con
  este rol no puede crear ni borrar tablas.
- **El segundo sí tenía permiso**, y lo paró la clave foránea: `PED-00042` tiene un pago. El
  `DELETE` falló entero y no hay nada que deshacer.

---

## 9. 🧭 El teardown, entero

Cada paso dejó el suyo. Juntos, de menos a más destructivo:

| Orden | Qué borra | Cuánto cuesta volver |
|---|---|---|
| `docker compose … stop` | Nada: para los procesos | Un `up -d`, segundos |
| `docker compose … down` | Los contenedores y la red | Un `up -d`; los datos siguen en los volúmenes |
| `docker compose … down -v` | **También los volúmenes**: todas las bases | La carga entera: unos cuatro minutos |
| `rm -r 13-laboratorio/entorno/datos` | Los CSV y la base de SQLite | 13 s de exportación y 28 s de SQLite |
| `docker image rm bd-lab-java:25.0.4 bd-lab-python:3.14.7 bd-lab-node:24.21.0 bd-lab-go:1.27.1` | Las cuatro imágenes de lenguaje, unos 8 GB | Reconstruirlas, varios minutos |

- `-v` es la única bandera que destruye datos, y no pregunta. **No se corrió contra `bd-lab`**, por
  la razón del §1; en la copia aislada, sí.
- `down --rmi local` no serviría para las imágenes de lenguaje: solo borra las que **no** tienen
  etiqueta propia, y estas la tienen en el `compose`.

> **⚠️ Advertencia.** Después de un `down -v` y una carga nueva, los datos son los mismos, pero las
> estadísticas no: la muestra de `ANALYZE` es al azar. Los planes del corpus coinciden en forma y en
> filas reales; un `rows=` o un `cost=` algo distintos no son un error de la carga.

---

## 10. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Nada de este lab es del estándar SQL: ISO/IEC 9075 no define cómo se carga
> un fichero, ni roles con contraseña, ni `generate_series`. Cada motor lo resuelve a su manera, y
> la tabla dice cuál.

| Pieza | PostgreSQL 18 | MySQL 9.7 y MariaDB 12.3 | SQLite 3.53 |
|---|---|---|---|
| Carga masiva desde fichero | `COPY` y `\copy` | `LOAD DATA [LOCAL] INFILE` | `.import` del cliente |
| Nulo en el CSV | `NULL '\N'` en la opción | `\N` por defecto | **No existe**: llega como texto |
| Permiso para leer ficheros del cliente | No hace falta con `\copy` | En el servidor **y** en el cliente | No aplica: no hay servidor |
| Generar filas | `generate_series` | No tiene; se puede con CTE recursiva | No tiene; se puede con CTE recursiva |
| Semilla determinista | `setseed` | `RAND(n)`, por llamada | No tiene |

**Convención, la que más se repite.** *«Cada motor, su propio script de datos»* — parece más limpio
y rompe toda comparación: con semillas distintas, cada motor tiene otra tienda.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`password authentication failed` es la contraseña" | Puede ser un rol que no existe: PostgreSQL no distingue los dos casos a propósito |
| "Cambio el puerto y listo" | Rompe cada orden del corpus; se para el contenedor que lo ocupa |
| "`local_infile` en el servidor basta" | Hace falta también `--local-infile=1` en el cliente |
| "`.import` respeta los nulos" | Los carga como la cadena `'\N'`, y un `UNIQUE` lo descubre a la primera |
| "`Recreate` significa que perdí los datos" | Los datos viven en volúmenes con nombre; solo `down -v` los borra |
| "Después de recargar, los planes salen idénticos" | Las filas sí; la muestra de `ANALYZE` cambia, y con ella `rows=` y `cost=` |

---

## 🧪 Ejercicios

1. Para el entorno con `stop`, vuelve a levantarlo y mide cuántos segundos tarda cada servicio en
   llegar a `(healthy)`. ¿Cuál es el más lento? 🟢
2. Conéctate como `tienda_ro` e intenta un `UPDATE` sobre `pedidos`. Anota el error y di qué `GRANT`
   de `esquema.sql` lo produce. 🟡
3. Corre `semilla.sql` dos veces seguidas sin `esquema.sql` entre medias y explica el error que da
   la segunda. Termina con `esquema.sql`, `semilla.sql` y `verificar.sql`. 🟠
4. Cambia `setseed(0.42)` por `setseed(0.43)` en una copia de `semilla.sql`, cárgala y di qué
   comprobaciones de `verificar.sql` fallan y por qué fallan esas y no las demás. Vuelve a la
   semilla original al terminar. 🟠
4. Diseña un `healthcheck` para un servicio que dependa de que la carga haya terminado, no solo de
   que el motor acepte conexiones. Escribe la orden y di qué consulta usaría. 🔴
5. Levanta una segunda copia del entorno con otro nombre de proyecto y otros puertos, como hizo este
   lab, sin tocar la primera. Di qué tres cosas del `compose` hay que cambiar. 🔴
6. Mide el tiempo de la carga de MySQL con las comprobaciones de claves foráneas encendidas durante
   el `LOAD DATA`. 🔥 *(fuera de conteo)*

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, `psql`: `\copy` y `\timing`.
  <https://www.postgresql.org/docs/18/app-psql.html>
- **Documentación** — PostgreSQL 18, «Populating a Database»: por qué cargar primero y crear índices
  después. <https://www.postgresql.org/docs/18/populate.html>
- **Documentación** — MySQL 9.7, «Security Considerations for LOAD DATA LOCAL».
  <https://dev.mysql.com/doc/refman/9.7/en/load-data-local-security.html>
- **Documentación** — SQLite, «Command Line Shell For SQLite»: `.import` y sus límites.
  <https://www.sqlite.org/cli.html>
- **Documentación** — Docker, `docker compose down`: qué borra cada bandera.
  <https://docs.docker.com/reference/cli/docker/compose/down/>

---

## 🧠 Preguntas

1. ¿Qué hace `docker compose up -d`, y qué significa `(healthy)` en `docker compose ps`? 🟢
2. ¿Por qué el corpus fija la versión de cada imagen y nunca usa `latest`? 🟢
3. ¿Qué hace `setseed(0.42)` en la semilla, y qué pasaría sin él? 🟢
4. ¿Qué diferencia hay entre `stop`, `down` y `down -v`? 🟢
5. Distingue `COPY` de `\copy` en PostgreSQL: quién lee o escribe el fichero en cada uno. 🟡
6. ¿Por qué PostgreSQL responde lo mismo a un rol inexistente que a una contraseña mala? 🟡
7. ¿Por qué `LOAD DATA LOCAL INFILE` falla si solo el servidor tiene `local_infile` activado? 🟡
8. ¿Qué parte de la carga es del estándar SQL y qué parte de cada motor? Da dos ejemplos. 🟡
9. ¿Por qué el corpus genera los datos en PostgreSQL y los exporta, en vez de sembrar cada motor por
   separado? 🟠
10. ¿Por qué `.import` de SQLite rompe el `UNIQUE` de `pagos.referencia`, y cómo lo evita la
    semilla? 🟠
11. ¿Qué tres conversiones hace la exportación a CSV, y qué rompería cada una si faltara? 🟠
12. `up -d` responde `Recreate` en tres contenedores. ¿Qué lo provoca, y se pierden los datos? 🟠
13. Después de un `down -v` y una carga nueva, un plan del bloque 03 da otro `rows=`. ¿Es un error
    de la carga? 🟠
14. Diagnostica: `docker compose up -d` falla con `port is already allocated` en el 5432. Da la
    orden que encuentra al culpable y la corrección. 🔴
15. Diseña la comprobación de que un entorno recién cargado es el del corpus: qué mirarías en cada
    motor y en qué orden. 🔴

---

**Siguiente:** [`l01`](l01-explain-e-indices-medidos.md) — `EXPLAIN` e índices medidos ·
**Relacionado:** [`03/03`](../03-el-motor-por-dentro/03-compuestos-parciales-y-de-cobertura.md) §6 —
el mapa de visibilidad vacío que la carga deja ·
[`10/02`](../10-interfaz-con-los-lenguajes/02-parametrizadas-e-inyeccion.md) §6 — el mínimo
privilegio de `tienda_app`.
