# 09 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiocho transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los ocho capítulos del bloque,
> de [`01`](01-familias-del-lenguaje-y-tipos.md) a [`08`](08-dialectos.md), y el bloque
> [`01`](../01-fundamentos-y-modelo-relacional/README.md) entero.
> **Vigencia:** 20 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. La diferencia está en que aquí **se responde hablando**, y eso es lo
que falla en la entrevista real aunque te sepas el tema.

- **Cronómetro a dos minutos por pregunta.** Si a los treinta segundos no has dicho la frase que
  resume tu respuesta, empieza otra vez. La capa ⏱️ del solucionario es exactamente eso: lo que
  dices primero.
- **En voz alta, no mentalmente.** Explicar un marco de ventana por dentro de tu cabeza sale
  perfecto siempre.
- **Sin mirar los capítulos.** Cuando no sepas algo, dilo y sigue: *"la cláusula exacta del estándar
  no la tengo; lo que sí sé es que estos cuatro motores lo hacen así"* es una respuesta profesional
  y completa. Inventarse la cláusula es lo que te cuesta el puesto.
- **Después, contra [`10`](10-respuestas.md).** No busques coincidencia palabra a palabra: busca si
  dijiste el mecanismo, si nombraste el precio y si distinguiste estándar de motor.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** Casi todas las preguntas de SQL admiten la misma apertura: *"depende
> de si hablamos del estándar, del motor o de lo que se repite en el gremio"*. En el bloque 01 esa
> frase era un recurso; aquí es **la respuesta correcta la mitad de las veces**, porque el eje del
> bloque es justamente ese. Lo que la hace valiosa no es decirla, es **poder seguirla con la fila
> concreta**: qué hace PostgreSQL, qué hace MySQL y con qué error.

---

## 2. 🧠 Transversales

### Tipos, y lo que de verdad se guarda

**S1.** `pedidos.total` es `numeric(12,2)` en PostgreSQL y texto en SQLite, porque SQLite no tiene
decimal exacto. El mismo filtro `total > 1000` cuenta 481 887 filas en un motor y 451 468 en el
otro, **sin un solo error**. Explica el mecanismo y di cómo lo detectarías antes que contabilidad. 🟠

**S2.** Un servicio escribe `creado_en` en `timestamptz` desde tres regiones y un informe agrupa por
día. ¿Dónde se decide en qué día cae un pedido de las 23:40, y qué tiene que estar escrito en algún
sitio para que ese informe sea reproducible dentro de seis meses? 🟠

**S3.** Guardas la respuesta cruda del proveedor de pagos para poder auditarla más tarde. ¿`json` o
`jsonb`? Nombra las dos cosas que decide la respuesta, y cuál de ellas es la que manda aquí. 🟡

---

### El orden lógico, y lo que no garantiza

**S4.** `WHERE iva > 100`, con `iva` declarado como alias en el `SELECT`, falla en PostgreSQL y
devuelve filas en SQLite. Di si eso lo fija el estándar o el motor, y por qué el `ORDER BY` sí
acepta el alias en los cuatro. 🟡

**S5.** `ORDER BY estado LIMIT 5` devolvió cinco pedidos distintos en dos ejecuciones del mismo
motor, sobre los mismos datos y sin que nadie tocara nada. Explica qué cambió y da la corrección,
que cabe en una línea. 🟠

**S6.** Una API pagina con `LIMIT 20 OFFSET :n`. En la página 45 000 tarda 631,392 ms y en la 0
tarda 0,432 ms, **con el mismo plan**. Explica por qué, y di qué le cambia el orden de magnitud. 🟠

**S7.** ¿Por qué `SELECT *` puede convertir un `Index Only Scan` en un `Index Scan`, y qué le cuesta
eso a la consulta cuando la tabla es grande? 🟡

---

### Joins, y las filas que aparecen y desaparecen

**S8.** Un informe une `pedidos` con `pedido_lineas` y suma `p.total`. Di por cuánto está inflado el
resultado **sin mirar los datos**, y de dónde sale ese factor. 🟢

**S9.** Un compañero arregla ese informe añadiendo `DISTINCT`. Di en qué caso `DISTINCT` arregla
algo de verdad, en cuál no, y cuáles son las dos escrituras correctas. 🟠

**S10.** Mover un predicado del `ON` al `WHERE` de un `LEFT JOIN` pasó el informe de 50 000 clientes
a 34 876. Di qué decidió el planificador y en qué se ve en el plan. 🟡

**S11.** Unir por `pagos.referencia`, que tiene 273 126 nulos, no empareja ni una fila. Un compañero
propone `IS NOT DISTINCT FROM` "para no perder los nulos". Respóndele en dos frases: una sobre lo
que consigue y otra sobre lo que cuesta. 🟠

**S12.** Solo quieres saber **si hay pareja**, no traerla. Da las tres escrituras posibles, di cuál
prefieres y qué nodo esperas ver en el plan si el planificador te hace caso. 🟡

---

### Agregar, contar y subconsultar

**S13.** `count(*)`, `count(referencia)` y `count(DISTINCT referencia)` sobre `pagos` dan tres
números distintos. Dilos, y di qué pregunta del negocio responde cada uno. 🟡

**S14.** La media por método salió 7726,29 con la condición en el `WHERE` y 5171,35 con la misma
condición en el `HAVING`. Di cuál responde a *"media de los pedidos no anulados"* y por qué la otra
no está mal escrita: está respondiendo otra pregunta. 🟠

**S15.** "`EXISTS` siempre es más rápido que `IN`." Corrige la frase con los números del bloque, y
di dónde está la diferencia de verdad entre las dos formas. 🟡

**S16.** Escribes la comprobación que corre antes de cada despliegue para detectar los `NOT IN`
peligrosos del repositorio. Di qué los hace peligrosos, qué buscas exactamente, y por qué no vale
con mirar los planes. 🔴

---

### CTE y ventanas

**S17.** "Las CTE son lentas porque materializan." Di desde cuándo dejó de ser cierto, qué palabra
la vuelve a hacer cierta, y qué le cuesta esa palabra cuando la pones sin pensar. 🟡

**S18.** Una consulta recursiva no vuelve en producción. Di qué hace cada motor del corpus cuando
eso pasa —quién te para y quién no— y cuáles son las dos defensas que tienes que escribir tú. 🟠

**S19.** Un informe de acumulado mensual "cuadra al final pero miente en el medio". Da la hipótesis
más probable en una frase, el mecanismo exacto que la produce y el arreglo. 🟠

**S20.** La misma consulta de ranking tiene que dar el mismo número de puesto en PostgreSQL, MySQL,
MariaDB y SQLite. Di qué lo impide hoy y qué escribes para garantizarlo. 🔴

---

### Escritura, upsert y vistas

**S21.** `pagos.referencia` es `UNIQUE` y admite nulos. Explica por qué el lote "idempotente" que se
apoya en esa columna duplica filas cada noche **sin dar ningún error**. 🟡

**S22.** Un compañero propone `REPLACE INTO pedidos` para el lote nocturno de MySQL. Da tres
consecuencias concretas y di cuál de las tres es la que rompe datos que nadie estaba mirando. 🟠

**S23.** Un panel tarda 366 ms por consulta y lo abren 200 personas cada mañana. Alguien dice
*"hazla materializada"*. Di qué cambia exactamente, qué no cambia, y cuál es la pregunta que hay que
hacer antes de decidir. 🟠

---

## 3. 🧠 Las que descolocan

**S24.** "Si es ANSI, funciona en todos." Desmóntalo con el caso del límite de filas, y di cuál es
la lectura general que se saca de ahí. 🟠

**S25.** ¿Qué devuelve `SELECT 'PED-00042' || ' — ' || 'PAGADO'` en MySQL 9.7.2, y por qué eso no es
un error de sintaxis sino un resultado? 🟡

**S26.** Un lote inserta 10 000 filas dentro de una transacción y falla en la 3 000. Di qué queda
confirmado en PostgreSQL, qué queda confirmado en MySQL, cuál de los dos comportamientos es más
peligroso y cuál es el arreglo que funciona en los cuatro motores. 🔴

**S27.** "Un ORM te hace portable." Di qué traduce de verdad y nombra cinco cosas que vas a escribir
tú a mano y que no están en todos los motores. 🟠

**S28.** Tu equipo decide escribir todo el SQL en el mínimo común denominador "por si acaso". Da el
argumento que convierte esa petición en una decisión medible en vez de una intuición. 🔴

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa no es que
aciertes, es **cómo acotas el problema antes de escribir la primera línea de SQL**.

### Escenario 1 — El informe que infla el importe

Dirección comercial recibe cada lunes un informe de facturación por cliente. Desde que se le añadió
una columna de "eventos registrados", el total del mes **subió un 314 %** y nadie tocó los datos. La
consulta une `pedidos` con `pedido_lineas` y con `eventos_pedido`, agrupa por cliente y suma
`p.total`.

**Entregas:** el mecanismo en una frase; por qué el número exacto de la inflación es predecible sin
consultar nada; las dos reescrituras correctas, con cuál eliges y por qué; y la comprobación que
habría detectado esto el día que se añadió la columna.

### Escenario 2 — La paginación que repite filas

Una API lista pedidos con `ORDER BY estado LIMIT 20 OFFSET :n`. Soporte reporta dos cosas a la vez:
que **hay pedidos que aparecen en dos páginas seguidas** y que **la página 45 000 tarda medio
segundo**. El equipo de front pide un índice.

**Entregas:** por qué son **dos problemas distintos** aunque se reporten juntos; cuál de los dos
arregla el índice que te piden y cuál no; la corrección de cada uno; y qué le concedes al diseño
actual si la API expone un buscador donde el usuario salta a una página arbitraria.

### Escenario 3 — El lote que tiene que correr en los cuatro motores

Un proveedor manda cada noche un fichero de pagos. El lote lo aplica sobre `pagos` y tiene que ser
idempotente: si se relanza, no duplica. Producción es PostgreSQL 18.6, el entorno de integración es
MySQL 9.7.2, y las pruebas de los desarrolladores corren sobre SQLite.

**Entregas:** la escritura para cada motor, diciendo cuál es la del estándar y cuál corre de verdad
en los tres; qué hace que el lote **no** sea idempotente hoy aunque la columna sea `UNIQUE`; y qué
recomiendas sobre la práctica de probar en un motor distinto del de producción.

### Escenario 4 — El panel que tiene que estar siempre al día

Negocio pide un panel de ventas que **responda en menos de 50 ms** y que **esté siempre al día**. La
consulta que lo alimenta tarda 366 ms. Tu jefe te pide que *"lo optimices en la base de datos"*.

**Entregas:** qué puede hacer la base de datos y qué no; qué cambia y qué no cambia una vista
materializada, con los dos números que lo sostienen; y dónde vive la decisión de verdad. Este
escenario tiene truco: **la respuesta correcta empieza por decir que esto no lo resuelve la base de
datos**, porque los dos requisitos son incompatibles tal como están escritos, y sigue negociando
cuál de los dos es real.

> **⚠️ Advertencia.** Aceptar el marco —*"lo materializo y ya"*— es el fallo que más caro sale en
> una entrevista de Tech Lead. "Siempre al día" y "50 ms" no son dos requisitos: son un requisito y
> una frase que nadie ha cuantificado. Se espera que preguntes **cuántos minutos puede envejecer el
> dato** antes de escribir nada.

---

## 5. 💡 Las frases que hay que tener listas

Dichas tal cual, sin adornos. Son las que cierran una respuesta y las que hacen que la siguiente
pregunta sea mejor.

- «El `SELECT` se escribe primero y se evalúa el quinto. De ahí sale la mitad de las sorpresas de
  este lenguaje.»
- «Sin `ORDER BY` total no hay orden. Y con `LIMIT`, además, no hay repetibilidad.»
- «Un join produce parejas, no columnas. Si el agregado sube, cuenta las parejas antes de tocar
  nada.»
- «`EXISTS` e `IN` afirmativos son el mismo semi-join y el mismo tiempo. `NOT IN` es otra cosa, y lo
  es por los nulos antes que por el plan.»
- «Una ventana no colapsa filas: añade una columna calculada sobre las vecinas.»
- «Si la ventana lleva `ORDER BY` y tú no pones marco, el marco lo pone el estándar, y agrupa los
  empates.»
- «Una vista guarda la consulta, no las filas. Si va lenta, lo que va lenta es la consulta de
  dentro.»
- «Materializar no quita el coste: lo mueve al refresco, y te deja datos viejos entre uno y otro.»
- «Lo estándar y lo portable no son lo mismo, y a veces son formas opuestas. `MERGE` es la del
  estándar y la tiene un motor de cuatro.»
- «Probar en un motor distinto del de producción es probar otra cosa.»
- «Si la lista de motores soportados no está escrita en ningún sitio, no hay un requisito de
  portabilidad: hay una intuición.»
- «Esto no lo resuelve la base de datos. Lo que la base de datos aporta aquí es la última red, y te
  digo cuál.»

---

**Anterior:** [`08`](08-dialectos.md) — dialectos, qué es portable y qué no · **Siguiente:**
[`10`](10-respuestas.md) — las respuestas, con las de esta simulación al final · **Volver:**
[README del bloque](README.md).
