# 07 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiséis transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los seis capítulos del bloque,
> de [`01`](01-mas-alla-de-las-tablas.md) a [`06`](06-vectorial-y-embeddings.md).
> **Vigencia:** 27 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. En este bloque la pregunta casi nunca es «¿cómo funciona Cassandra?»:
es **«¿usarías Cassandra aquí?»**, y la respuesta buena no empieza por el motor. Empieza por cómo se
lee el dato, qué mecanismo falla hoy medido, y si algo dentro de la base actual lo resuelve.

- **Cronómetro a dos minutos por pregunta.** Y la regla del bloque: **cada ventaja con su cifra y
  cada cifra con su precio**. *«El camino más corto tardó 25 ms en Neo4j y 3,7 s con la CTE; la
  recomendación, 305 ms frente a 143»* gana a cualquier folleto.
- **En voz alta.** Los mecanismos se recuerdan diciéndolos con su efecto: *«el `WHERE` se aplica
  después del índice, y con 40 candidatos no quedó ninguno de deporte»*.
- **Sin mirar los capítulos.** Cuando no recuerdes una cifra, di cómo la verías: *«mediría el
  recall contra la búsqueda exacta, sin índice»*.
- **Después, contra [`08`](08-respuestas.md).** Busca si dijiste lo que se paga, y si separaste lo
  del motor de lo que es convención.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿qué se pierde?»**. Cada
> modelo del bloque ganó en algo concreto y lo pagó con algo que PostgreSQL daba gratis: `JOIN`,
> exactitud, visibilidad inmediata, una sola copia del dato.

---

## 2. 🧠 Transversales

### El criterio

**S1.** ¿Por qué «NoSQL» no sirve para decidir nada? Da tres motores que no comparten ni el modelo
ni el comportamiento ante fallos. 🟡

**S2.** Explica CAP sin decir «elige dos de tres», con lo que hicieron MongoDB y Cassandra al perder
dos de tres nodos. 🟠

**S3.** ¿Qué cinco preguntas harías antes de proponer un motor nuevo, y cuál es la que más se
salta? 🟠

**S4.** ¿Qué es el *hinted handoff*, y qué pasa si un nodo está caído más de tres horas? 🟡

### Wide-column

**S5.** ¿Qué decide la clave de partición en Cassandra, y qué deciden las columnas de
clustering? 🟢

**S6.** «Una consulta nueva es una tabla nueva». Explícalo con los eventos de los pedidos. 🟡

**S7.** PostgreSQL cargó los eventos más de seis veces más rápido que Cassandra. ¿Qué argumento a
favor de Cassandra sobrevive? 🟠

**S8.** ¿Por qué un `INSERT` en Cassandra puede perder datos sin dar error, y qué cuesta evitarlo? 🟠

**S9.** ¿Por qué borrar en Cassandra no libera espacio, y por qué es mala idea montar una cola
encima? 🟠

### Grafo

**S10.** ¿En qué tipo de recorrido gana una base de grafos y en cuál no, con las cifras del
bloque? 🟠

**S11.** ¿Qué hace `shortestPath` para tardar 25 ms, y por qué supo en 2 ms que no había camino? 🟡

**S12.** ¿Cuándo puede parar antes una CTE recursiva, y por qué no conviene contar con ello? 🔴

**S13.** ¿Qué es un supernodo, y qué hizo el de la tienda con la pregunta de «clientes
conectados»? 🟡

### Series temporales

**S14.** ¿Qué gana una hipertabla sobre una tabla normal con índice, y en qué empata? 🟠

**S15.** Un agregado continuo enseña un recuento viejo. ¿Por qué, y qué opciones hay? 🟡

**S16.** `drop_chunks` frente a `DELETE` para borrar por antigüedad: qué hace cada uno y qué se
midió. 🟡

### Búsqueda de texto

**S17.** Da las cinco razones por las que `LIKE '%texto%'` no sirve como buscador. 🟢

**S18.** ¿Por qué la búsqueda de texto de PostgreSQL arregló la tilde y no el singular? 🟠

**S19.** ¿Qué se paga por tener el buscador en OpenSearch en vez de en PostgreSQL? 🟡

### Vectorial

**S20.** ¿Qué es el *recall* de un índice vectorial, y cuánto dio el HNSW con los parámetros de
defecto? 🟢

**S21.** HNSW o IVFFlat: qué elegirías para un catálogo que se reindexa cada noche, y por qué. 🟠

**S22.** ¿Por qué una búsqueda vectorial con filtro puede devolver menos filas de las pedidas? 🔴

**S23.** ¿Por qué la búsqueda semántica de la tienda devolvió aspiradoras cuando se pedía
música? 🟠

---

## 3. 🧠 Las que descolocan

**S24.** «Cassandra es AP, así que nunca es consistente». Refútalo con la sesión. 🟠

**S25.** «Con una base vectorial, el buscador entenderá lo que quiere el cliente». ¿Qué parte es
cierta? 🟠

**S26.** «Una base de grafos es más rápida con cualquier dato que tenga relaciones». Refútalo con
números. 🔴

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa es **que el
modelo salga de cómo se lee el dato y del mecanismo que falla medido**, y que no se proponga un
motor nuevo para lo que resuelve un índice o una extensión.

### Escenario 1 — La telemetría del reparto

La tienda quiere guardar la posición de cada repartidor cada cinco segundos: 20 000 escrituras por
segundo en campaña, consultadas por pedido —«dónde está mi pedido»— y por zona y hora para el
panel de operaciones. Hay que guardar un año, y el equipo propone Cassandra.

**Entregas:** las tablas de Cassandra con su clave y cómo crece cada partición; el nivel de
consistencia de escritura y de lectura, y qué pasa con dos nodos caídos; lo que se pierde frente a
PostgreSQL; y cómo compararías antes con una hipertabla de TimescaleDB, con qué medida.

### Escenario 2 — El anillo de fraude

Fraude detecta cuentas nuevas que comparten tarjeta, teléfono o dirección con cuentas bloqueadas,
a veces a través de dos o tres cuentas intermedias. Hoy lo hace una CTE recursiva que tarda entre
unos milisegundos y medio minuto, y a veces no termina antes de que el cliente pague.

**Entregas:** por qué la CTE tarda tan distinto de una cuenta a otra; el modelo de grafo, con nodos,
relaciones y restricciones; qué supernodos esperas y qué harías con ellos; y cómo mantendrías el
grafo al día con la base principal.

### Escenario 3 — El buscador que no encuentra

El buscador de la tienda usa `ILIKE '%texto%'`. Las quejas son que no encuentra sin tildes, ni en
singular, ni con erratas, y que los resultados salen desordenados. Un equipo propone OpenSearch;
otro, búsqueda semántica con embeddings.

**Entregas:** qué resuelve cada propuesta y qué no, con las cifras del bloque; qué harías primero
dentro de PostgreSQL; en qué caso pasarías a OpenSearch y qué te costaría; y qué tendría que
demostrar la búsqueda semántica antes de publicarla.

### Escenario 4 — «El panel va lento: pongamos una base de series temporales»

El panel de ventas por hora del último año tarda nueve segundos. Alguien propone migrar los pedidos
a una base de series temporales. Este escenario tiene truco: **la respuesta correcta empieza por
decir que esto no lo resuelve cambiar de base de datos**, y sigue por decir qué lo resuelve.

**Entregas:** qué mirarías primero —el plan, el índice, cuántas filas lee—; qué harías en PostgreSQL
para que el panel conteste en milisegundos; en qué caso sí propondrías TimescaleDB, y qué se
llevaría la tienda con él; y qué perdería con una base aparte.

> **⚠️ Advertencia.** Aceptar el marco —*«es un problema de series temporales»*— es el fallo que más
> caro sale aquí: el panel lee lo mismo cada vez, y lo que lo arregla es no recalcularlo. En el
> bloque, el agregado de un año pasó de 60 ms a 1,3 al materializarlo; en PostgreSQL, una vista
> materializada o una tabla de resumen hace lo mismo, a cambio de refrescarla.

---

## 5. 💡 Las frases que hay que tener listas

- «NoSQL dice lo que el motor no es; la decisión se toma por la forma de acceso.»
- «CAP solo habla de qué hace el sistema durante una partición, y se configura por operación.»
- «En Cassandra, una consulta nueva es una tabla nueva, y cada tabla se diseña por cómo crece.»
- «El `INSERT` de Cassandra pisa sin avisar; evitarlo con `IF NOT EXISTS` cuesta casi el triple.»
- «Borrar en Cassandra escribe una marca que dura diez días.»
- «Con profundidad fija gana el `JOIN`; con profundidad variable, el grafo.»
- «La CTE recursiva busca desde un lado; el grafo, desde los dos, y sabe cuándo no hay camino.»
- «Para leer lo reciente basta un índice; la hipertabla gana en compresión, agregados y retención.»
- «`LIKE` compara caracteres; un buscador compara palabras analizadas.»
- «El buscador es una copia que se ve con retraso, y hay que poder reconstruirlo.»
- «Un índice vectorial cambia exactitud por velocidad; el *recall* se mide, no se supone.»
- «Con un índice aproximado, el filtro va después, y puede vaciar el resultado.»
- «Lo que significa "parecido" lo decide el modelo, no la base de datos.»

---

**Anterior:** [`06`](06-vectorial-y-embeddings.md) — vectorial y embeddings · **Siguiente:**
[`08`](08-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
