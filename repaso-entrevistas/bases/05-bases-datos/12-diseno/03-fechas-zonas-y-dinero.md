# 03 — Fechas, zonas y dinero

> Qué columna usar para cada caso horario y para cada importe, que es la decisión que queda después
> de conocer los tipos de [`02/01`](../02-sql/01-familias-del-lenguaje-y-tipos.md) y cómo los
> entrega cada lenguaje en [`10/03`](../10-interfaz-con-los-lenguajes/03-mapeo-de-tipos.md). Medido:
> en Madrid, sumar un día y sumar 24 horas dan horas distintas el fin de semana del cambio; la misma
> cita de las diez en São Paulo cae una hora distinta en 2018 y en 2020; MySQL devuelve el mismo
> valor como `04:22` en `DATETIME` y como `23:22` del día anterior en `TIMESTAMP`; y repartir 100,00
> en tres partes redondeadas deja 99,99. **Asume leído:** los dos capítulos citados. **Vigencia:**
> 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Cuatro casos horarios, cuatro
  columnas](#2--cuatro-casos-horarios-cuatro-columnas)
- [3. El cambio de hora](#3--el-cambio-de-hora) · [4. Las reglas de zona
  cambian](#4--las-reglas-de-zona-cambian)
- [5. MySQL y SQLite](#5-️-mysql-y-sqlite) · [6. Dinero: exacto, con moneda y sin céntimos
  perdidos](#6--dinero-exacto-con-moneda-y-sin-céntimos-perdidos)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tienda guarda cuándo se hizo cada pedido, cuándo caduca cada cupón y a qué hora se recoge cada
envío en tienda. Las tres son «una fecha», y las tres necesitan columnas distintas: un pedido
ocurrió en un **instante**; un cupón caduca un **día**; una recogida es a una **hora local** en una
ciudad, aunque las reglas horarias de esa ciudad cambien antes de que llegue.

El dinero tiene el mismo tipo de trampa, más discreta: un tipo que suma casi bien, un importe sin
moneda, un redondeo que pierde un céntimo al repartir. Ninguno da un error: dan informes que no
cuadran por muy poco, que son los más difíciles de encontrar.

> **📝 Contexto.** PostgreSQL y MySQL se corrieron en la copia aislada `bd-lab-prueba`; SQLite, en
> una base en memoria. Las tablas de prueba se crean y se tiran. Las zonas horarias son las de la
> base de datos de zonas que trae cada motor, que es la que decide los resultados de §3 y §4.
> La sesión de PostgreSQL es una sola, repartida en orden entre §3, §4 y §6.
> **Longitud:** unas 325 líneas; capítulo normal.

---

## 2. 🧭 Cuatro casos horarios, cuatro columnas

| Caso | Ejemplo en la tienda | Columna en PostgreSQL | Por qué |
|---|---|---|---|
| **Un instante que ya pasó** | Cuándo se creó `PED-00042` | `timestamptz` | Guarda el instante; se enseña en la zona de quien lo mira |
| **Un día, sin hora** | El último día de validez de un cupón | `date` | No hay hora ni zona que interpretar |
| **Una hora local futura** | La recogida del sábado a las 10:00 en la tienda de Madrid | `timestamp` más una columna con la zona, `'Europe/Madrid'` | La hora es la del reloj de la ciudad, aunque cambien sus reglas |
| **Una duración** | El plazo de devolución, 30 días | `interval` | Se suma a una fecha según el calendario, no según los segundos |

**Quién lo manda:** los tipos son del **estándar** con diferencias de cada **motor**
([`02/01`](../02-sql/01-familias-del-lenguaje-y-tipos.md) §4); qué columna para qué caso es
**convención** de diseño.

- **El caso que más se equivoca es el tercero**: guardar la recogida futura como instante
  —`timestamptz`— la convierte a UTC con las reglas de hoy. Si la ciudad cambia sus reglas antes del
  sábado, el instante guardado ya no son las 10:00 locales. §4 lo mide.
- **El segundo se equivoca al revés**: guardar «caduca el 31» como `timestamptz` a medianoche hace
  que en otra zona caduque el 30 a las 23:00.

---

## 3. 🩺 El cambio de hora

En España, la madrugada del 30 de marzo de 2025 los relojes pasaron de las 02:00 a las 03:00. Con la
sesión en esa zona:

```text
tienda=# SET TimeZone = 'Europe/Madrid';
SET
tienda=# SELECT timestamptz '2025-03-29 12:00' + interval '1 day' AS mas_un_dia, timestamptz '2025-03-29 12:00' + interval '24 hours' AS mas_24_horas;
       mas_un_dia       |      mas_24_horas      
------------------------+------------------------
 2025-03-30 12:00:00+02 | 2025-03-30 13:00:00+02
(1 fila)

tienda=# SELECT timestamptz '2025-03-30 02:30' AS hora_que_no_existe;
   hora_que_no_existe   
------------------------
 2025-03-30 03:30:00+02
(1 fila)
```

- **`+ interval '1 day'` da las 12:00 del día siguiente; `+ interval '24 hours'`, las 13:00.** Ese
  día tuvo 23 horas. La documentación de PostgreSQL lo dice con estas palabras: en una zona con
  cambio de hora, sumar un día no tiene por qué dar lo mismo que sumar 24 horas.
- **Cuál es el bueno depende del caso**: «el mismo pedido, mañana a la misma hora» es un día;
  «caduca 24 horas después del pago» son 24 horas. La columna es la misma; la aritmética la decide
  el negocio, y hay que escribirla.
- **Las 02:30 de ese día no existieron**, y PostgreSQL no da error: la interpreta como las 03:30.
  Una cita puesta a esa hora se mueve sola.

---

## 4. 🩺 Las reglas de zona cambian

Brasil suprimió el horario de verano en 2019. La misma cita, a las 10:00 locales del 15 de noviembre
en São Paulo, convertida a instante en 2018 y en 2020, vista desde Madrid:

```text
tienda=# SELECT timestamp '2018-11-15 10:00' AT TIME ZONE 'America/Sao_Paulo' AS cita_2018, timestamp '2020-11-15 10:00' AT TIME ZONE 'America/Sao_Paulo' AS cita_2020;
       cita_2018        |       cita_2020        
------------------------+------------------------
 2018-11-15 13:00:00+01 | 2020-11-15 14:00:00+01
(1 fila)

tienda=# RESET TimeZone;
RESET
```

- **`timestamp … AT TIME ZONE 'America/Sao_Paulo'`** interpreta una hora local de esa ciudad y
  devuelve el instante, que la sesión enseña en su zona, Madrid.
- **Las mismas 10:00 locales son las 13:00 de Madrid en 2018 y las 14:00 en 2020**: en noviembre de
  2018 São Paulo estaba en horario de verano, UTC−2; en 2020 ya no existía, UTC−3. La base de datos
  de zonas guarda la historia de cada ciudad.
- **La consecuencia para las citas futuras**: si en 2018 se hubiera guardado la cita de 2020 como
  instante, con las reglas de entonces, habría quedado una hora desplazada cuando Brasil cambió las
  suyas. Guardando la hora local y la zona, se convierte en el momento de usarla, con las reglas
  vigentes.

> **⚠️ Advertencia.** Los gobiernos cambian las reglas horarias con meses de aviso, y la base de
> datos de zonas se actualiza con el sistema. Lo que se guarda como hora local futura se convierte
> tarde; lo que ya ocurrió se guarda como instante.

---

## 5. ⚖️ MySQL y SQLite

**MySQL** tiene dos tipos con nombres engañosos:

```text
mysql> CREATE TABLE horas (como_datetime DATETIME, como_timestamp TIMESTAMP);
Query OK, 0 rows affected (0.008 sec)

mysql> SET time_zone = '+00:00';
Query OK, 0 rows affected (0.000 sec)

mysql> INSERT INTO horas VALUES ('2025-02-21 04:22:09', '2025-02-21 04:22:09');
Query OK, 1 row affected (0.002 sec)

mysql> SET time_zone = '-05:00';
Query OK, 0 rows affected (0.000 sec)

mysql> SELECT como_datetime, como_timestamp FROM horas;
+---------------------+---------------------+
| como_datetime       | como_timestamp      |
+---------------------+---------------------+
| 2025-02-21 04:22:09 | 2025-02-20 23:22:09 |
+---------------------+---------------------+
1 row in set (0.000 sec)

mysql> SELECT CAST(0.1 AS DOUBLE) + CAST(0.2 AS DOUBLE) AS flotante, CAST(0.1 AS DECIMAL(12,2)) + CAST(0.2 AS DECIMAL(12,2)) AS exacto;
+---------------------+--------+
| flotante            | exacto |
+---------------------+--------+
| 0.30000000000000004 |   0.30 |
+---------------------+--------+
1 row in set (0.001 sec)
```

- **El mismo valor, insertado en UTC y leído en UTC−5**: `DATETIME` devuelve `04:22`, lo que se
  escribió; `TIMESTAMP` devuelve `23:22` del día anterior. Su manual lo dice: convierte `TIMESTAMP`
  de la zona de la sesión a UTC al guardar y de vuelta al leer, y no lo hace con `DATETIME`.
- **`TIMESTAMP` es el instante** y `DATETIME` el reloj de pared: al revés de lo que sugieren los
  nombres para quien viene de PostgreSQL, donde `timestamp` es el reloj de pared.
- **`DOUBLE` suma mal y `DECIMAL` exacto**, igual que en PostgreSQL.

**SQLite** no tiene tipos de fecha ni de dinero:

```bash
/opt/homebrew/opt/sqlite/bin/sqlite3 :memory: < sqlite-dinero.sql
```

```text
suma_es_uno|suma_centimos
1|100
directa|igual
0.30000000000000004|0
tipo_fecha
text
```

- **`sqlite-dinero.sql`** guarda diez importes de 0,1 como `REAL` y como céntimos enteros, los suma,
  compara la suma directa de 0,1 y 0,2 con 0,3, y pregunta el tipo de una fecha.
- **La suma de las diez líneas salió exactamente 1**, y la suma directa de 0,1 y 0,2 no es 0,3. La
  documentación de `sum()` avisa de que, con valores de magnitudes muy distintas, la suma de reales
  puede ser imprecisa, y propone `decimal_sum` de su extensión decimal. **Los céntimos enteros suman
  100 sin depender de nada**: es la forma habitual de guardar dinero en SQLite.
- **La fecha es texto**: `date()` devuelve una cadena. Las fechas se guardan en formato ISO, que se
  ordena bien como texto, y las zonas son cosa de la aplicación.

---

## 6. 🧭 Dinero: exacto, con moneda y sin céntimos perdidos

```text
tienda=# SELECT 0.1::float8 + 0.2::float8 AS flotante, 0.1::numeric + 0.2::numeric AS exacto;
      flotante       | exacto 
---------------------+--------
 0.30000000000000004 |    0.3
(1 fila)

tienda=# SELECT sum(total) AS exacto, sum(total::float8) AS flotante, sum(total) - sum(total::float8)::numeric AS diferencia FROM pedidos;
    exacto     |     flotante      | diferencia 
---------------+-------------------+------------
 5178452860.88 | 5178452860.879636 |    0.00036
(1 fila)

tienda=# SELECT round(100.00 / 3, 2) AS parte, round(100.00 / 3, 2) * 3 AS suma_de_partes;
 parte | suma_de_partes 
-------+----------------
 33.33 |          99.99
(1 fila)
```

- **El millón de totales, sumado en coma flotante, se desvía 0,00036** de la suma exacta. Redondeado
  a céntimos cuadra; en un cálculo encadenado —impuestos sobre descuentos sobre conversiones—, las
  desviaciones se acumulan. `numeric` no se desvía nunca.
- **Repartir 100,00 en tres partes redondeadas da 99,99**: se pierde un céntimo. No es un error del
  tipo, es del algoritmo: al repartir un importe —en plazos, entre líneas, entre cuentas— el último
  reparto lleva la diferencia, para que las partes sumen el total.

**Las reglas del dinero**, que son **convención** y no del motor:

- **Tipo exacto**: `numeric` en PostgreSQL, `DECIMAL` en MySQL, céntimos enteros en SQLite. Nunca
  coma flotante.
- **La moneda al lado**: un importe sin moneda es un número. Una columna con el código ISO de la
  moneda, y ninguna suma entre monedas distintas.
- **El redondeo, en un solo sitio y con una regla escrita**: cuándo se redondea, a cuántos decimales
  y a dónde va la diferencia.
- **La escala, suficiente**: `numeric(12,2)` basta para los totales de la tienda; los precios por
  unidad de algunos productos o los tipos de cambio necesitan más decimales.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Los tipos de fecha y los numéricos exactos están en el estándar, con
> nombres y comportamientos que cambian por motor —el `TIMESTAMP` de MySQL convierte y el de
> PostgreSQL no—. La base de datos de zonas es la que trae cada sistema. Qué columna para qué caso,
> la moneda al lado y dónde se redondea son convención de diseño.

| Afirmación | Categoría | PostgreSQL 18 | MySQL 9.7 | SQLite 3.53 |
|---|---|---|---|---|
| Sumar un día es sumar 24 horas | Motor | No, en zonas con cambio de hora | — | — |
| Una hora local que no existe da error | Motor | No: se desplaza, 02:30 → 03:30 | — | — |
| El tipo que se llama `TIMESTAMP` convierte a UTC | Motor | No | Sí | No hay tipo |
| El numérico exacto suma exacto | Estándar | `numeric`: 0,3 | `DECIMAL`: 0,30 | Céntimos enteros |
| La coma flotante suma exacto | Motor | No: 0,00036 de desvío | No | La suma de diez 0,1 salió exacta; la directa, no |
| La hora local futura se guarda con su zona | Convención | — | — | — |
| Al repartir, el último lleva la diferencia | Convención | — | — | — |

**Convención, la que más se repite.** *«Todo en UTC y listo»* — sirve para los instantes que ya
pasaron. Una recogida futura a las 10:00 de Madrid, guardada en UTC, deja de ser las 10:00 si Madrid
cambia sus reglas, y un «caduca el 31» en UTC caduca el 30 en otra zona.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Sumar un día es sumar 24 horas" | El 30 de marzo en Madrid dio las 12:00 y las 13:00 |
| "Una cita futura se guarda en UTC" | La misma cita en São Paulo cayó una hora distinta en 2018 y en 2020 |
| "`TIMESTAMP` en MySQL es el reloj de pared" | Convierte a UTC: devolvió `23:22` del día anterior |
| "Una hora inexistente da error" | PostgreSQL movió las 02:30 a las 03:30 sin avisar |
| "Con `double` basta si se redondea al final" | Se desvió 0,00036 sobre un millón de totales, y se acumula al encadenar cálculos |
| "Repartir con redondeo suma el total" | 33,33 × 3 dio 99,99 |
| "El importe se entiende sin moneda" | Es un número; sumar euros y pesos no da nada |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Date/Time Types»: `timestamptz`, `timestamp`, `date` e
  `interval`. <https://www.postgresql.org/docs/18/datatype-datetime.html>
- **Documentación** — PostgreSQL 18, «Date/Time Functions and Operators»: sumar un día frente a 24
  horas. <https://www.postgresql.org/docs/18/functions-datetime.html>
- **Documentación** — PostgreSQL 18, «Numeric Types»: `numeric` y la coma flotante.
  <https://www.postgresql.org/docs/18/datatype-numeric.html>
- **Documentación** — MySQL 9.7, «The DATE, DATETIME, and TIMESTAMP Types».
  <https://dev.mysql.com/doc/refman/9.7/en/datetime.html>
- **Documentación** — SQLite, «Built-in Aggregate Functions»: `sum()` y `decimal_sum`.
  <https://www.sqlite.org/lang_aggfunc.html>
- **Documentación** — SQLite, «Date And Time Functions».
  <https://www.sqlite.org/lang_datefunc.html>

---

## 🧠 Preguntas

1. ¿Qué columna usarías para cuándo se creó un pedido, y por qué? 🟢
2. ¿Qué diferencia `timestamptz` de `timestamp` en PostgreSQL? 🟢
3. ¿Por qué el dinero no se guarda en coma flotante? 🟢
4. ¿Cómo guarda SQLite las fechas? 🟢
5. ¿Qué columna usarías para el último día de validez de un cupón, y qué pasa si usas un instante? 🟡
6. ¿Por qué `+ interval '1 day'` y `+ interval '24 hours'` dieron horas distintas? 🟡
7. ¿Qué hace PostgreSQL con una hora local que no existe? ¿Lo fija el estándar o es cosa del motor?
   🟡
8. Distingue `DATETIME` de `TIMESTAMP` en MySQL. 🟡
9. ¿Qué es la base de datos de zonas, y por qué importa que guarde la historia? 🟠
10. ¿Por qué la misma cita en São Paulo cayó a una hora distinta en 2018 y en 2020? 🟠
11. ¿Por qué una hora local futura se guarda con su zona y no como instante? 🟠
12. ¿Por qué la suma en coma flotante del millón de totales se desvió, y por qué importa si al final
    se redondea? 🟠
13. ¿Por qué repartir 100,00 en tres dio 99,99, y cómo se reparte bien? ¿Qué parte es del motor y
    qué parte es convención? 🟠
14. ¿Por qué el dinero necesita una columna de moneda? 🟠
15. ¿Por qué en SQLite se guardan céntimos enteros, si la suma de diez 0,1 salió exacta? 🟠
16. Diseña las columnas de fecha y dinero de `pedidos`, `cupones` y las recogidas en tienda, para
    una tienda que vende en tres países. 🔴
17. Diagnostica: los clientes de Colombia reciben el aviso de que su cupón ha caducado un día antes
    de lo anunciado, y los de España no. 🔴
18. Defiende o refuta «guardamos todas las fechas en UTC y todos los importes en `double`, y
    redondeamos al mostrar», con los números del capítulo. 🔴

---

**Anterior:** [`02`](02-identidad-y-claves.md) — identidad y claves · **Siguiente:**
[`04`](04-borrado-logico-auditoria-e-historial.md) — borrado lógico, auditoría e historial ·
**Relacionado:** [`10/03`](../10-interfaz-con-los-lenguajes/03-mapeo-de-tipos.md) — cómo llegan
fechas y decimales a cada lenguaje.
