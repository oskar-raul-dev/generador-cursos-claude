# 07 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veinticuatro transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los seis capítulos del bloque,
> de [`01`](01-como-se-almacena-una-tabla.md) a [`06`](06-cuando-el-indice-no-se-usa.md), y los
> bloques [`01`](../01-fundamentos-y-modelo-relacional/README.md) y [`02`](../02-sql/README.md).
> **Vigencia:** 20 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. Este bloque tiene una dificultad propia que los dos anteriores no
tenían: **casi todas sus respuestas llevan un número**, y un número que no recuerdas se nota mucho
más que un concepto que explicas con otras palabras.

- **Cronómetro a dos minutos por pregunta.** Y una regla de este bloque: si la respuesta lleva una
  cifra, **dila con su unidad y con su moneda** —páginas, milisegundos, registros de WAL—. "Mucho
  más rápido" no es una respuesta aquí.
- **En voz alta.** Leer un plan por dentro de tu cabeza sale perfecto siempre; explicarlo en voz
  alta, señalando en qué orden lo recorres, es lo que de verdad se practica.
- **Sin mirar los capítulos.** Y cuando no tengas el número exacto, di el orden de magnitud y dilo
  como lo que es: *"no recuerdo la cifra; lo que recuerdo es que el índice leía el 88 % de sus
  páginas y perdía contra el barrido"*. Eso es una respuesta profesional. Inventarse el número, no.
- **Después, contra [`08`](08-respuestas.md).** No busques coincidencia palabra a palabra: busca si
  dijiste el mecanismo, si nombraste el precio y si distinguiste lo que decide el motor de lo que
  decide tu esquema.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La apertura que sirve para casi cualquier pregunta de índices y planes
> es **"depende de cuántas filas pasan el filtro"**. No es una evasiva: es literalmente el criterio
> del planificador, y encadena sola con la cifra concreta. Lo que la hace valiosa es poder seguirla
> con *"y en este caso eran 273 126 de 820 000, así que el barrido gana"*.

---

## 2. 🧠 Transversales

### Dónde vive una fila

**S1.** `pedidos` son 10 770 páginas de 8 kB, y cualquier plan que toque la tabla se mide en páginas
antes que en filas. Explica por qué el motor no puede leer "una fila" del disco, y qué consecuencia
tiene eso para el coste de cualquier acceso por índice. 🟡

**S2.** Un `UPDATE` sobre `PED-00042` movió su `ctid` de `(10769,20)` a `(10769,21)`. Di qué guarda
un `ctid`, por qué cambió sin que nadie borrara nada, y por qué eso les importa a todos los índices
de la tabla. 🟠

**S3.** En InnoDB la tabla **es** el índice primario y en PostgreSQL es un heap aparte. Da las dos
consecuencias prácticas: una al elegir la clave primaria y otra al leer por un índice secundario. 🟠

---

### Qué estructura para qué pregunta

**S4.** Tienes que acelerar tres cosas: una igualdad por `pedidos.codigo`, un *"¿contiene esta
clave?"* sobre `eventos_pedido.carga`, que es `jsonb`, y un rango por `ocurrido_en` sobre 4 100 000
filas que se insertaron en orden de tiempo. Di qué familia de índice para cada una y por qué. 🟠

**S5.** ¿Cuándo gana un índice hash a un B-tree sobre la misma columna, y por qué casi nunca se usa?
🟡

**S6.** Un BRIN sobre `eventos_pedido.ocurrido_en` ocupa 40 kB donde un B-tree ocuparía decenas de
megabytes. Di de qué depende que sirva de algo, y qué le pasa al plan cuando eso no se cumple. 🟠

---

### El orden de las columnas

**S7.** Con un índice sobre `(producto_id, cantidad)` y un `WHERE cantidad = 5`, el índice **aparece
en el plan** y la consulta va más lenta que sin él. Da el mecanismo, la línea del plan que lo delata
y las dos cifras de tiempo. 🟠

**S8.** Explica la regla del prefijo izquierdo sin usar la palabra "índice", y di dónde se rompe la
analogía que uses. 🟢

**S9.** Un índice parcial con `WHERE estado = 'ANULADO'` se usa cuando el valor va escrito en la
consulta y deja de usarse cuando llega en un parámetro. Explica por qué, y di qué comando te lo
confirma sin adivinar. 🟠

---

### Lo que el motor cree

**S10.** Un nodo dice `rows=80` y `actual rows=14 864`, con dos filtros sobre la misma tabla. Di qué
falló, cómo se corrige **sin crear un solo índice**, y cuánto baja el error. 🟠

**S11.** El mismo `rows=20500` sale para una consulta que devuelve 0 filas y para otra que devuelve
1 366 667. Explica de dónde sale ese número y por qué no es una estimación. 🟡

**S12.** Un despliegue restaura la base con `pg_restore` a las 3:00 y a las 3:05 el primer informe
tarda veinte minutos. Di qué pasó, qué línea faltaba en el despliegue y qué consulta te lo habría
dicho en diez segundos. 🟠

**S13.** ¿El detalle con que el motor conoce sus propios datos lo fija el estándar SQL o cada motor?
Responde con lo que tiene PostgreSQL 18.6, lo que tiene MySQL 9.7.2 y lo que tiene SQLite 3.53.4. 🟡

---

### Leer el plan

**S14.** ¿En qué orden se lee un plan de ejecución, y cuál es el primer número que mirarías, antes
del tiempo? 🟢

**S15.** Un nodo dice `actual time=0.8 loops=5000`. Di cuánto tardó de verdad y por qué esto es el
error número uno al leer un `Nested Loop`. 🟡

**S16.** `Sort Method: external merge Disk: 9648kB`. Di qué te está confesando el plan y las dos
cosas que puedes hacer al verlo. 🟠

**S17.** ¿`EXPLAIN ANALYZE` sobre un `UPDATE` escribe en la tabla? Responde por separado para
PostgreSQL 18.6 y MySQL 9.7.2, y da la forma segura de medirlo. 🟡

---

### Por qué no se usa

**S18.** Enumera las seis razones por las que un índice existente no se usa, y di cuáles de las seis
**no** son un error del motor. 🟢

**S19.** `WHERE creado_en::date = DATE '2026-01-01'` no usa el índice sobre `creado_en`. Da la
reescritura que sí lo usa, di lo que cuesta, y di en qué caso hay que pagar un índice funcional en
su lugar. 🟡

**S20.** Te pasan un plan con `Index Only Scan` y `Heap Fetches: 438435`. Di qué mirarías, con qué
catálogo, en qué orden, y cuál es la corrección. 🟠

**S21.** Una tabla con cinco índices recibe 10 000 `INSERT` por minuto. Haz la cuenta del precio de
escritura y di en qué moneda lo medirías para que el número no dependa de la caché. 🟠

---

## 3. 🧠 Las que descolocan

**S22.** "Si el plan dice `Seq Scan`, falta un índice." Refútalo con **dos** casos medidos de este
bloque: uno donde el motor tiene razón y otro donde el índice existe, se usa y pierde igual. 🟠

**S23.** ¿Los índices y el plan de ejecución están en el estándar SQL? Responde en una frase, y di
qué se sigue de esa respuesta para una entrevista donde te preguntan "cómo se optimiza una
consulta". 🟡

**S24.** Alguien te enseña un plan y te dice que la consulta tarda 8 segundos "por culpa del `Seq
Scan` de arriba". Di por qué el nodo de mayor `actual time` casi nunca es el culpable, y cuál es la
cifra que sí lo señala. 🟡

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa no es que
aciertes, es **en qué orden descartas hipótesis antes de tocar el esquema**.

### Escenario 1 — Los cuatro índices que no arreglaron nada

Un informe de rotación tardaba 187 ms y ahora tarda 190. Entre medias alguien creó cuatro índices
sobre `pedido_lineas` y `pedidos`, "por si acaso". El plan sigue siendo un `Nested Loop` que baja 14
864 veces por `pedidos_pkey` donde el planificador presupuestó 80, y los `INSERT` del proceso
nocturno pasaron de 40 minutos a más de una hora.

**Entregas:** el diagnóstico en una frase, con el número que lo sostiene; por qué ninguno de los
cuatro índices podía arreglarlo; la corrección, que no crea índices; el argumento con el que
propones **borrar** tres de los cuatro, en moneda de escritura; y la consulta con la que decides
cuáles.

### Escenario 2 — El índice que nadie usa y nadie se atreve a borrar

En una base de 40 tablas hay un índice de 31 MB sobre `pedidos` que nadie recuerda haber creado. El
equipo lleva dos sprints sin tocarlo "por si lo usa algún informe". Al mirarlo aparece además que su
`indisvalid` es `false`.

**Entregas:** qué significa exactamente ese `indisvalid = false` y qué está pagando la base ahora
mismo; con qué vistas del catálogo demuestras si un índice se usa y desde cuándo; qué le falta a ese
argumento —¿qué mide y qué no mide un contador de uso?—; y el procedimiento completo para retirarlo
sin sustos.

### Escenario 3 — El `CREATE INDEX` del viernes

Producción es PostgreSQL 18.6. Hay que añadir un índice sobre `pedido_lineas`, que tiene 3 500 000
filas y recibe escrituras todo el día. En el entorno de pruebas el `CREATE INDEX` tardó 829 ms, así
que el equipo propone lanzarlo sin más a las cinco de la tarde.

**Entregas:** qué bloquea un `CREATE INDEX` normal y durante cuánto; qué cambia `CREATE INDEX
CONCURRENTLY` y qué cuesta —incluido el fallo que puede dejar—; por qué el tiempo del entorno de
pruebas no predice el de producción y qué medirías en su lugar; y qué escribirías en el plan de
vuelta atrás.

### Escenario 4 — El buscador que tiene que responder en 50 ms

Producto pide un buscador de pedidos con **seis filtros combinables** —estado, cliente, rango de
fechas, rango de importe, país y texto libre sobre el nombre del producto—, cualquiera de ellos
opcional, ordenado por fecha, paginado, y **por debajo de 50 ms** sobre el millón de pedidos y sus 3
500 000 líneas. Tu jefe te pide "los índices que hagan falta".

**Entregas:** cuántas combinaciones de filtros hay y por qué eso hace inviable la respuesta que te
piden; qué **sí** se puede indexar de esa lista y qué no —el texto libre con comodín por la
izquierda es el caso duro—; y cuál es la pregunta que hay que hacerle a producto antes de escribir
una línea de DDL. Este escenario tiene truco: **la respuesta correcta empieza por decir que esto no
lo resuelve la base de datos**, y sigue por acotar el problema hasta que sí lo resuelva.

> **⚠️ Advertencia.** Aceptar el marco —*"te creo los seis índices"*— es el fallo que más caro sale
> aquí, porque produce una base con doce índices, un proceso de escritura el doble de lento y el
> buscador igual de lento. Seis filtros opcionales son 64 combinaciones, y el índice que sirve a una
> no sirve a la siguiente. Se espera que separes **qué filtros usa de verdad el 95 % de las
> búsquedas** antes de indexar nada, y que digas en voz alta qué parte del problema pertenece a otra
> capa.

---

## 5. 💡 Las frases que hay que tener listas

Dichas tal cual, sin adornos. Son las que cierran una respuesta y las que hacen que la siguiente
pregunta sea mejor.

- «El motor no lee filas: lee páginas. Todo el coste de un plan sale de ahí.»
- «Un índice de PostgreSQL no sabe si la fila está viva. Eso lo sabe el heap, y por eso existe el
  mapa de visibilidad.»
- «La primera columna del índice es la única que garantiza una sola bajada por el árbol.»
- «El planificador no mide: estima. Y estima desde una muestra.»
- «Antes de discutir un plan, comparo `rows=` con `actual rows`. El resto se decidió con ese
  número.»
- «Un plan se lee de dentro hacia fuera, y el tiempo de un nodo incluye el de sus hijos.»
- «`Rows Removed by Filter` y `Sort Method` son los dos sitios donde un plan confiesa que tira
  trabajo a la basura.»
- «"El índice no se usa" no es un diagnóstico: son seis, y en dos de ellas el motor tiene razón.»
- «Si la columna va dentro de una función, el índice de esa columna no existe para esa consulta.»
- «Cada índice es una escritura extra por `INSERT` y por cada `UPDATE` que toque sus columnas. Un
  índice que no se usa paga todo eso a cambio de nada.»
- «Se particiona para operar una tabla grande, no para acelerar una consulta.»
- «Los índices no están en el estándar. Todo lo que voy a decir de aquí en adelante es
  comportamiento de motor, y te digo de cuál.»
- «Esto no lo resuelve la base de datos. Lo que la base de datos aporta aquí es la mitad, y te digo
  cuál.»

---

**Anterior:** [`06`](06-cuando-el-indice-no-se-usa.md) — las seis razones · **Siguiente:**
[`08`](08-respuestas.md) — las respuestas, con las de esta simulación al final · **Volver:** [README
del bloque](README.md).
