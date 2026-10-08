# 08 — Respuestas

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

- [Capítulo 01 — Más allá de las tablas](#capítulo-01--más-allá-de-las-tablas)
- [Capítulo 02 — Columnar y wide-column](#capítulo-02--columnar-y-wide-column)
- [Capítulo 03 — Grafo](#capítulo-03--grafo)
- [Capítulo 04 — Series temporales](#capítulo-04--series-temporales)
- [Capítulo 05 — Búsqueda de texto](#capítulo-05--búsqueda-de-texto)
- [Capítulo 06 — Vectorial y embeddings](#capítulo-06--vectorial-y-embeddings)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — Más allá de las tablas

Las 19 preguntas de [`01`](01-mas-alla-de-las-tablas.md).

**01 → 1.** ¿Qué significa «NoSQL», y quién lo define? 🟢

⏱️ **30 segundos** — Es una etiqueta histórica para los motores que no siguen el modelo relacional,
leída como «sin SQL» y después como «no solo SQL». No la define nadie: no hay estándar ni
especificación detrás.

🗣️ **2 minutos** — Bajo ella caben Redis, MongoDB, DynamoDB, Cassandra, Neo4j, OpenSearch y Qdrant,
y la tabla de §2 enseña que no comparten ni el modelo, ni el lenguaje, ni lo que hacen cuando cae
un nodo. Por eso en una decisión se nombra el modelo y el motor, nunca la etiqueta.

🔬 **El detalle** — **Convención** pura. La frontera tampoco es nítida por el otro lado: Couchbase y
Cassandra tienen `SELECT`, y PostgreSQL guarda documentos, vectores y series temporales.

---

**01 → 2.** Enuncia el teorema CAP con tus palabras. 🟢

⏱️ **30 segundos** — En un sistema distribuido, cuando la red se parte y los nodos no se ven, no se
puede garantizar a la vez que toda lectura vea la última escritura y que todo nodo vivo responda
sin error. Hay que elegir qué sacrificar mientras dura la partición.

🗣️ **2 minutos** — La P no se elige: las particiones ocurren. Lo que se elige es negarse a responder
a una parte de las peticiones (CP) o responder con lo que se tiene, arriesgando un dato viejo (AP).
Sin partición, un sistema puede ser consistente y disponible.

🔬 **El detalle** — Es un **teorema**, no un estándar: Brewer lo planteó en 2000 y Gilbert y Lynch lo
demostraron en 2002. La elección de cada motor sí es **motor**, y se documenta.

---

**01 → 3.** ¿Qué es un nivel de consistencia en Cassandra? 🟢

⏱️ **30 segundos** — El número de réplicas a las que el coordinador espera antes de responder a una
lectura o una escritura: `ONE`, `QUORUM`, `ALL` y variantes locales. Se elige por operación.

🗣️ **2 minutos** — Con tres réplicas, `QUORUM` son dos. En §4, con dos nodos caídos, `QUORUM` falló
con `'required_replicas': 2, 'alive_replicas': 1` y `ONE` escribió. El mismo motor se comportó como
CP y como AP según el nivel.

🔬 **El detalle** — **Motor**. En `cqlsh` se fija con `CONSISTENCY`; en los drivers, por sentencia o
por perfil de ejecución.

---

**01 → 4.** ¿Qué es el *hinted handoff*, y cuánto dura su ventana por defecto? 🟢

⏱️ **30 segundos** — Cuando una réplica está caída, el nodo que acepta la escritura guarda una nota,
un *hint*, y se la entrega cuando la réplica vuelve. La ventana por defecto es de tres horas.

🗣️ **2 minutos** — Es lo que puso al día a los nodos 2 y 3 en §4: tras la escritura en `ONE`, la
lectura en `ALL` un minuto después devolvió `ENVIADO` en las tres réplicas. Un nodo caído más de
tres horas no recibe *hints* y necesita reparación.

🔬 **El detalle** — **Motor**: `max_hint_window` en `cassandra.yaml`. Los *hints* no sustituyen a la
reparación periódica; solo cubren caídas cortas.

---

**01 → 5.** Distingue la C de CAP de la C de ACID. 🟡

⏱️ **30 segundos** — La C de ACID es que una transacción deja la base en un estado que cumple sus
reglas de integridad. La de CAP es que todas las copias se comporten como una sola: toda lectura ve
la última escritura confirmada.

🗣️ **2 minutos** — Una base de un solo nodo tiene la C de ACID y la de CAP no le aplica, porque no
hay copias. Y una base distribuida puede tener la de CAP, leyendo siempre lo último, y aceptar un
dato que viola una regla si no hay restricción que lo compruebe.

🔬 **El detalle** — La C de CAP es lo que la literatura de sistemas llama *linearizability*; la de
ACID la cubre [`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md).

---

**01 → 6.** ¿Por qué no tiene sentido decir que un PostgreSQL sin réplicas es «CA»? ¿Qué parte es
del motor y qué parte es convención? 🟡

⏱️ **30 segundos** — Porque CAP habla de sistemas distribuidos durante una partición, y un nodo solo
no se puede partir. Si ese nodo cae, no está disponible y ya: no hay elección que hacer.

🗣️ **2 minutos** — Decir «CA» es leer CAP como «elige dos de tres», que es el error más repetido. En
cuanto PostgreSQL tiene réplicas, sí aplica: con réplica síncrona, el primario espera y se comporta
como CP; con asíncrona y lecturas de la réplica, se puede leer un dato viejo.

🔬 **El detalle** — **Convención** de mal uso. El teorema no clasifica motores, clasifica el
comportamiento de una configuración durante una partición.

---

**01 → 7.** ¿Qué añade PACELC a CAP? 🟡

⏱️ **30 segundos** — Lo que pasa sin partición: aunque la red esté sana, esperar a más réplicas
tarda más, así que se elige entre latencia y consistencia.

🗣️ **2 minutos** — Explica por qué Cassandra ofrece `ONE` además de `QUORUM` incluso con los tres
nodos arriba: `ONE` responde en cuanto llega la primera réplica. En DynamoDB pasa lo mismo con la
lectura eventual y la fuerte de [`07/05`](../07-clave-valor/05-dynamodb-modelo-y-claves.md).

🔬 **El detalle** — PACELC es **convención** de análisis, no teorema: una forma útil de hacer la
pregunta que CAP no hace.

---

**01 → 8.** ¿Por qué el nodo 1 del conjunto de réplicas pasó de primario a secundario sin que nadie
lo tocara? 🟡

⏱️ **30 segundos** — Porque un primario que deja de ver a la mayoría de los miembros se degrada
solo: al otro lado de la partición podría haberse elegido otro primario, y dos primarios aceptando
escrituras romperían la consistencia.

🗣️ **2 minutos** — Con los nodos 2 y 3 parados, `rs.status()` mostró el nodo 1 como `SECONDARY` y el
*prompt* cambió a `[direct: secondary]`. La escritura falló con `NotWritablePrimary`. Al volver el
nodo 2, había mayoría —dos de tres— y el nodo 1 volvió a ser primario.

🔬 **El detalle** — **Motor**: la documentación de MongoDB dice que el conjunto no procesa escrituras
hasta que una elección termina con éxito, y que las lecturas siguen si se configuran para ir a los
secundarios.

---

**01 → 9.** ¿Por qué con tres réplicas, escribir y leer en `QUORUM` garantiza leer lo último
escrito? 🟡

⏱️ **30 segundos** — Porque la escritura llegó al menos a dos réplicas y la lectura consulta al
menos a dos, y dos más dos es más que tres: las dos mayorías comparten al menos una réplica, que
tiene el último valor.

🗣️ **2 minutos** — Es la forma de tener consistencia fuerte en un motor que por defecto es AP. Se
paga con disponibilidad: con dos nodos caídos, ni se escribe ni se lee, como enseñó el error de §4.

🔬 **El detalle** — **Motor**: la documentación de Cassandra lo formula así. La regla general es que
réplicas de escritura más réplicas de lectura superen el factor de replicación.

---

**01 → 10.** De los cinco modelos de este bloque, ¿cuáles se resuelven en algún grado dentro de
PostgreSQL, y con qué? 🟡

⏱️ **30 segundos** — Grafo, con la CTE recursiva; series temporales, con TimescaleDB, que es una
extensión; vectorial, con `pgvector`. Y la búsqueda de texto tiene `tsvector` en el propio motor. El
único sin equivalente razonable es el *wide-column* repartido entre nodos.

🗣️ **2 minutos** — Además, el documento tiene `jsonb`, que fue `08/05`. «En algún grado» importa: la
CTE recursiva sirve para profundidad acotada y pierde con la variable, como mide `03`; lo demás lo
miden `04`, `05` y `06`.

🔬 **El detalle** — Es lo que sostiene el paso 3 del criterio de elección: antes de un motor nuevo,
¿lo resuelve algo dentro de la base actual?

---

**01 → 11.** Un compañero dice que Cassandra es AP y por eso nunca es consistente. Refútalo con la
sesión. 🟠

⏱️ **30 segundos** — AP es el comportamiento por defecto, no una propiedad fija. Con `QUORUM` en
escritura y lectura garantiza leer lo último escrito, y en §4 rechazó la escritura en `QUORUM` con
solo un nodo vivo: eso es un comportamiento CP.

🗣️ **2 minutos** — La misma sesión enseñó las dos caras: `ONE` aceptó la escritura con dos nodos
caídos, y `QUORUM` la rechazó con `Cannot achieve consistency level QUORUM`. Cassandra deja elegir
por operación, y el diseño decide qué dato necesita qué.

🔬 **El detalle** — La documentación de Cassandra dice que elige disponibilidad «comprometiendo en
cierta medida la consistencia»: por defecto, no siempre.

---

**01 → 12.** ¿Qué paga un sistema CP durante una partición, y qué paga uno AP? Da un ejemplo de la
tienda para cada uno. 🟠

⏱️ **30 segundos** — CP paga en errores: las escrituras fallan o esperan hasta que vuelve la
mayoría. AP paga en datos viejos y conflictos: se acepta la escritura y alguien reconcilia después.

🗣️ **2 minutos** — Un pago o el estado de un pedido quieren CP: mejor un error que cobrar dos veces
o enseñar `ENVIADO` a quien no lo está. Un contador de visitas o el historial de eventos toleran AP:
perder la precisión un rato cuesta menos que tirar el servicio.

🔬 **El detalle** — En Cassandra, el conflicto AP lo resuelve la marca de tiempo más reciente, así
que el reloj de los clientes pasa a importar. El cliente de un sistema CP tiene que saber reintentar
sin duplicar.

---

**01 → 13.** ¿Por qué el error de `QUORUM` llegó sin intentar la escritura? 🟠

⏱️ **30 segundos** — Porque el coordinador sabía por el protocolo de estado entre nodos que solo
había una réplica viva, y `QUORUM` necesita dos. Rechaza de antemano con `Unavailable` en vez de
escribir en una y esperar a que caduque.

🗣️ **2 minutos** — El mensaje lo dice con sus números: dos réplicas requeridas y una viva. La
consecuencia práctica es buena: no queda una escritura a medias en una réplica. Distinto es un
tiempo de espera agotado, en el que la escritura pudo llegar a alguna réplica.

🔬 **El detalle** — **Motor**. `Unavailable` quiere decir «no se intentó»; un `WriteTimeout` quiere
decir «no sé si se hizo», y reintentarlo exige que la escritura sea idempotente.

---

**01 → 14.** Tras la sesión de Cassandra, ¿en qué ventana podía una lectura devolver `PAGADO`, y
cómo la habrías cerrado? 🟠

⏱️ **30 segundos** — Entre que los nodos 2 y 3 volvieron y recibieron los *hints*: una lectura en
`ONE` que cayera en ellos habría devuelto `PAGADO`. Se cierra leyendo en `QUORUM`, que junta la
réplica actualizada con una vieja y devuelve la más reciente.

🗣️ **2 minutos** — Con la escritura hecha en `ONE`, ni siquiera `QUORUM` al leer lo garantiza del
todo: dos de las tres réplicas podían tener el valor viejo. Lo que la cierra de verdad es escribir
en `QUORUM` y leer en `QUORUM`, y durante el fallo eso significaba no escribir.

🔬 **El detalle** — **Motor**: al leer en `QUORUM` y encontrar réplicas distintas, Cassandra además
repara la atrasada, lo que se llama *read repair*.

---

**01 → 15.** ¿Qué dice la segunda columna de la tabla comparada de las fichas, y por qué es la que
decide si hay caso para cambiar de modelo? 🟠

⏱️ **30 segundos** — Nombra el mecanismo que se rompe en SQL: el bloqueo de fila, el `JOIN`
repetido, el B-tree, el `LIKE` sin índice. Si no se puede nombrar el mecanismo que falla, no hay
caso para cambiar de modelo.

🗣️ **2 minutos** — Es la diferencia entre «no escala» y «dieciséis procesos sobre la misma fila
serializan en el bloqueo, 4 373 escrituras por segundo». La primera frase es un folleto; la segunda
se puede medir, y a veces se arregla sin cambiar de motor.

🔬 **El detalle** — Es **convención** del curso, y encaja con el paso 2 del criterio: el mecanismo
que falla, medido.

---

**01 → 16.** ¿Por qué el criterio de elección pregunta por la base actual antes que por el motor
nuevo? 🟠

⏱️ **30 segundos** — Porque un índice, una columna `jsonb`, una extensión o una réplica de lectura
resuelven muchos casos sin otra copia de los datos, otra copia de seguridad y otra guardia. Es la
pregunta que más migraciones evita.

🗣️ **2 minutos** — Un motor nuevo casi nunca sustituye al relacional: se añade para una forma de
acceso, y hay que mantenerlo sincronizado. Si la base actual llega, ese coste no compensa.

🔬 **El detalle** — En entrevista parece conformista y es lo contrario: demuestra que se conoce el
motor actual lo bastante como para saber dónde se acaba.

---

**01 → 17.** Diseña qué nivel de consistencia usarías en Cassandra para el estado de un pedido y
para un contador de visitas, y qué pasa en cada caso con dos de tres nodos caídos. 🔴

⏱️ **30 segundos** — Estado del pedido: escritura y lectura en `QUORUM`, para leer siempre lo
último; con dos nodos caídos, ni se escribe ni se lee. Contador: `ONE`; con dos nodos caídos sigue
funcionando, y alguna lectura puede ir por detrás.

🗣️ **2 minutos** — Lo del pedido es lo que enseñó §4: error explícito, que la aplicación tiene que
tratar —reintentar más tarde, avisar—. Lo del contador es la escritura que entró en `ONE` con un
solo nodo. En varios centros de datos, `LOCAL_QUORUM` para el pedido evita esperar a otra región.

🔬 **El detalle** — Un contador de verdad en Cassandra usa el tipo `counter`, cuyas escrituras no son
idempotentes: reintentar tras un tiempo de espera puede contar dos veces. Por eso muchos lo ponen en
Redis, como [`07/01`](../07-clave-valor/01-el-modelo-clave-valor.md).

---

**01 → 18.** Diagnostica: tras un corte de red de cuatro horas entre dos zonas, un nodo de Cassandra
devuelve estados de pedido viejos aunque la red volvió hace una hora. Da la causa y cómo la
resolverías. 🔴

⏱️ **30 segundos** — Cuatro horas superan la ventana de *hints* de tres horas: las escrituras de la
última hora del corte no se le entregaron. Se resuelve con una reparación de ese nodo, y mientras
tanto leyendo en `QUORUM`.

🗣️ **2 minutos** — Lo confirmaría con `nodetool` —la ventana configurada y el estado de la
reparación— y con una lectura en `ONE` contra ese nodo frente a una en `QUORUM`. Si las lecturas
iban en `ONE`, el síntoma es exactamente el esperado; el diseño pedía `QUORUM` para el estado del
pedido.

🔬 **El detalle** — **Motor**: la documentación de *hints* dice que un nodo caído más de
`max_hint_window` necesita reparación. Hay que repararlo antes de que pase `gc_grace_seconds`, o los
borrados pueden volver como zombis, que es `02`.

---

**01 → 19.** Defiende o refuta la propuesta de §1, «para los eventos de los pedidos usemos NoSQL,
que escala», recorriendo los cinco pasos del criterio de elección. 🔴

⏱️ **30 segundos** — Se refuta tal como está: «NoSQL» no es una propuesta. Recorriendo el criterio
puede salir Cassandra, o puede salir que PostgreSQL basta, y eso depende de medir.

🗣️ **2 minutos** — Uno: los eventos se leen por pedido y por día, lo último primero. Dos: ¿qué falla
hoy? Hay 4 100 000 filas que caben en memoria; sin medición, no hay caso. Tres: un índice por
`(pedido_id, ocurrido_en)` y el particionado por fecha resuelven mucho. Cuatro: un evento perdido un
rato es tolerable, así que AP vale. Cinco: Cassandra es otra copia y otra guardia. Hoy, PostgreSQL;
con escala de telemetría, Cassandra con partición por pedido y por día con cubo.

🔬 **El detalle** — Lo que evalúa la pregunta es que no se acepte el marco. La respuesta buena
termina con una condición medible que cambiaría la decisión.

---

## Capítulo 02 — Columnar y wide-column

Las 17 preguntas de [`02`](02-columnar-y-wide-column.md).

**02 → 1.** ¿Qué es una partición en Cassandra, y qué la decide? 🟢

⏱️ **30 segundos** — El grupo de filas que vive entero en los mismos nodos. La decide la clave de
partición: Cassandra le aplica un hash, y el *token* resultante cae en el tramo de un nodo del
anillo.

🗣️ **2 minutos** — En `eventos_por_pedido`, la partición es `pedido`: los tres eventos de
`PED-00042` viven juntos y se leen de una vez. En la sintaxis, es lo que va dentro del doble
paréntesis de `PRIMARY KEY ((pedido), ocurrido_en, tipo)`.

🔬 **El detalle** — **Motor**. Solo se puede preguntar eficientemente por la partición entera, porque
es lo único que dice en qué nodo buscar.

---

**02 → 2.** ¿Qué hacen las columnas de clustering? 🟢

⏱️ **30 segundos** — Ordenan las filas dentro de la partición, y ese orden se guarda así en disco.
Es el único orden que Cassandra sabe devolver sin ordenar en memoria.

🗣️ **2 minutos** — En `eventos_por_dia`, `CLUSTERING ORDER BY (ocurrido_en DESC, ...)` guarda el día
de lo más reciente a lo más antiguo, así que «lo último primero» es leer las tres primeras filas.
Además forman parte de la clave: dos filas con la misma partición y el mismo clustering son la
misma.

🔬 **El detalle** — **Motor**. `ORDER BY` solo acepta columnas de clustering, como mostró el error de
§3.

---

**02 → 3.** ¿Qué es una SSTable, y por qué no se modifica nunca? 🟢

⏱️ **30 segundos** — Un fichero en disco con las filas ordenadas por clave, que sale de volcar la
memtable. Es inmutable: los cambios se escriben en SSTables nuevas y la compactación las funde.

🗣️ **2 minutos** — No modificarla es lo que permite escribir sin leer: nunca hay que encontrar la
página de una clave para cambiarla. En §4, tras `nodetool flush`, la tabla pasó de una SSTable a dos
—`nb-9` y `nb-10`—: la nueva se añadió, no reemplazó a la vieja.

🔬 **El detalle** — **Motor**, el árbol LSM. La inmutabilidad es también la razón de que borrar
escriba una tombstone.

---

**02 → 4.** ¿Qué es una tombstone? 🟢

⏱️ **30 segundos** — Una marca de borrado. Como las SSTables no se cambian, un `DELETE` escribe una
marca que en la lectura tapa los valores anteriores, y el dato desaparece al compactar pasado
`gc_grace_seconds`.

🗣️ **2 minutos** — En §6, tras borrar el evento `PREPARADO`, la lectura devolvió dos filas y
`tablestats` contó una tombstone leída por lectura. Y el espacio no bajó al compactar, porque la
marca sigue diez días.

🔬 **El detalle** — **Motor**. Una partición con miles de tombstones obliga a leerlas todas para
devolver pocas filas; Cassandra avisa y llega a abortar la lectura por encima de un umbral
configurable.

---

**02 → 5.** Distingue *wide-column* de columnar. ¿Qué parte es del motor y qué parte es convención?
🟡

⏱️ **30 segundos** — *Wide-column*, como Cassandra, guarda filas agrupadas por partición, pensadas
para leer una partición entera. Columnar guarda cada columna por separado, pensado para sumar
millones de valores de una columna.

🗣️ **2 minutos** — Las bases columnares son las analíticas y de almacén de datos, que este curso
deja fuera. Se confunden por el nombre, y confundirlas en entrevista se nota: Cassandra no es buena
agregando toda una tabla, que es justo lo que hace bien una columnar.

🔬 **El detalle** — **Convención** de nombres. «Wide» viene de que una partición puede tener muchas
filas o columnas, no de guardar por columnas.

---

**02 → 6.** ¿Por qué `ORDER BY importe` falla en `eventos_por_pedido`, y qué tabla lo permitiría?
¿Lo fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — Porque Cassandra solo ordena por las columnas de clustering, y `importe` no lo
es: el error dice «Order by is currently only supported on the clustered columns». Lo permitiría una
tabla con `importe` en el clustering.

🗣️ **2 minutos** — Por ejemplo, `PRIMARY KEY ((pedido), importe, ocurrido_en, tipo)`. Pero con el
mismo dato: la aplicación escribe cada evento en las dos tablas. Si el volumen es pequeño, también
se ordena en la aplicación tras leer la partición, que aquí son tres filas.

🔬 **El detalle** — **Motor**. Es la regla del bloque: el orden se decide al escribir, no al leer.

---

**02 → 7.** ¿Por qué no se puede pedir un rango de días sobre `eventos_por_dia`, si `dia` es la
clave? 🟡

⏱️ **30 segundos** — Porque `dia` es la clave de partición, y las particiones se reparten por el
hash de su valor, no por el valor. «Los días de febrero» son 28 particiones sin relación entre sí,
repartidas por el anillo.

🗣️ **2 minutos** — Cassandra pidió `ALLOW FILTERING`, que recorrería todo el clúster. La salida es
enumerar las particiones con `IN`, que funcionó con tres días y avisó del coste —el coordinador
espera a la partición más lenta—, o una tabla cuya partición sea el mes y cuyo clustering sea el
día.

🔬 **El detalle** — **Motor**. Un rango sí funciona sobre las columnas de clustering dentro de una
partición.

---

**02 → 8.** Recorre el camino de una escritura en Cassandra desde que llega hasta que está en una
SSTable. 🟡

⏱️ **30 segundos** — El coordinador la manda a las réplicas; cada una la añade al commit log, su
WAL, y la pone en la memtable, ordenada en memoria. Cuando la memtable se llena, o con
`nodetool flush`, se vuelca entera como una SSTable nueva.

🗣️ **2 minutos** — En ningún paso se lee nada: es la ventaja frente al B-tree, que tiene que
encontrar la página de la clave. En §4, antes del volcado había tres celdas en la memtable y una
SSTable; después, cero celdas y dos SSTables.

🔬 **El detalle** — **Motor**. El commit log es lo que se reproduce si el nodo cae con la memtable
llena; después, la compactación va fundiendo SSTables.

---

**02 → 9.** ¿Por qué `tipo` forma parte de la clave de `eventos_por_pedido`? ¿Qué pasaría sin él? 🟠

⏱️ **30 segundos** — Para que dos eventos del mismo pedido en el mismo instante sean filas
distintas. Sin él, el segundo sobrescribiría al primero sin error, porque en Cassandra un `INSERT`
con una clave existente es un `UPDATE`.

🗣️ **2 minutos** — La sesión de §5 lo enseñó: un `INSERT` sobre el evento `PAGADO` cambió `web` y
3 186,23 por `movil` y 1,00, sin error y sin fila nueva. Una clave mal elegida pierde datos en
silencio; en PostgreSQL, habría dado violación de clave primaria.

🔬 **El detalle** — Aun con `tipo`, dos eventos iguales en el mismo milisegundo se pisarían. Una
clave a prueba de colisiones añade un `timeuuid` al clustering.

---

**02 → 10.** PostgreSQL cargó el CSV en 1,22 s y Cassandra en 8,04 s. ¿Qué argumento a favor de
Cassandra sobrevive a ese número? 🟠

⏱️ **30 segundos** — Que la capacidad de escritura crece añadiendo nodos, porque cada uno recibe
solo las particiones de su tramo y no hay primario. En una máquina, el `COPY` de PostgreSQL gana;
con la tabla fuera de memoria y veinte nodos, el argumento cambia.

🗣️ **2 minutos** — Y el camino de escritura sin lecturas previas: cuando el índice ya no cabe en
memoria, cada inserción en un B-tree empieza a leer de disco, y el árbol LSM no. En el entorno no se
midió el escalado, así que se dice como mecanismo y sin cifra.

🔬 **El detalle** — La carga de Cassandra pasó además por `cqlsh`, un cliente en Python que manda
lotes por la red; parte de los 8 s son del cliente.

---

**02 → 11.** ¿Por qué Cassandra ocupó 9,4 MB y PostgreSQL 52 MB con los mismos datos? 🟠

⏱️ **30 segundos** — Porque Cassandra comprime las SSTables por defecto con LZ4, en bloques de 16
KB, y PostgreSQL no comprime las filas pequeñas: solo los valores grandes, con TOAST.

🗣️ **2 minutos** — Los 52 MB incluyen el índice de la clave primaria; los 9,4 MB de Cassandra
incluyen sus propios ficheros de índice y filtro. Los datos ordenados por partición comprimen bien,
porque las filas contiguas se parecen.

🔬 **El detalle** — **Motor**: la compresión sale de `system_schema.tables`, `LZ4Compressor` con
`chunk_length_in_kb` 16. Se paga en CPU al leer y escribir.

---

**02 → 12.** ¿Qué cuesta una transacción ligera, medido, y por qué? 🟠

⏱️ **30 segundos** — Casi el triple: 1,56 ms por escritura con `IF NOT EXISTS` frente a 0,54 sin
ella, en un nodo y sin red. Cuesta porque usa Paxos, un protocolo de consenso con varias rondas
antes de escribir.

🗣️ **2 minutos** — La medida fue de mil inserciones de cada tipo con `cqlsh -f`: 0,871 s y 1,892 s,
menos los 0,33 s de arrancar `cqlsh`. Con tres réplicas, cada ronda es un viaje de red, así que en
producción la diferencia es mayor.

🔬 **El detalle** — **Motor**: la documentación habla de un «coste de rendimiento no despreciable» y
pide usarlas con moderación. Primero, una clave que evite la colisión o una escritura idempotente.

---

**02 → 13.** ¿Por qué el espacio no bajó tras el `DELETE` y la compactación? 🟠

⏱️ **30 segundos** — Porque la compactación conserva la tombstone hasta que tenga más de
`gc_grace_seconds`, 864 000 segundos, diez días. Hasta entonces, la marca y el dato tapado siguen
ocupando.

🗣️ **2 minutos** — `nodetool compact` pasó de dos SSTables a una y el espacio quedó en 9 388 929
bytes, lo de antes. La marca tiene que sobrevivir para llegar a las réplicas que estuvieran caídas;
si desapareciera antes, esas réplicas devolverían el dato borrado, el zombi.

🔬 **El detalle** — **Motor**. Bajar `gc_grace_seconds` libera antes, y exige reparar dentro del
nuevo plazo.

---

**02 → 14.** ¿Por qué una partición por día es una partición caliente, y cómo se corrige? ¿Qué se
paga? 🟠

⏱️ **30 segundos** — Porque todas las escrituras de hoy caen en la misma partición, y por tanto en
los mismos nodos, mientras el resto del clúster no recibe ninguna. Se corrige con *bucketing*: meter
la hora o un cubo en la clave de partición.

🗣️ **2 minutos** — Además crece con el negocio: 7 825 bytes de media por día aquí, frente a 235 por
pedido, que tiene tope. Con un cubo de 0 a 9 calculado del pedido, un día son diez particiones
repartidas. Se paga al leer: «lo de hoy» son diez lecturas que la aplicación junta.

🔬 **El detalle** — **Convención** de modelado que la documentación de Cassandra nombra así. Es el
mismo problema que la partición caliente de DynamoDB en `07/05`.

---

**02 → 15.** Diseña las tablas de Cassandra para tres consultas: los eventos de un pedido, los de un
día por hora y los de un cliente en un mes. Di la clave de cada una y cómo crece su partición. 🔴

⏱️ **30 segundos** — Tres tablas. Una con partición por pedido, que tiene tope; otra con partición
por día y hora, que reparte el día en 24 particiones; y otra con partición por cliente y mes, que
acota la del cliente. Las tres ordenan por `ocurrido_en` dentro.

🗣️ **2 minutos** — Cada evento se escribe tres veces, una por tabla, y la aplicación es responsable
de que las tres coincidan; un lote *logged* sobre las tres garantiza que acaben todas escritas. Si
la hora sigue siendo caliente, se añade un cubo. El `ORDER` de clustering va descendente donde se
lee «lo último primero».

🔬 **El detalle** — El método es el de `07/06`: primero la lista de consultas, después una tabla por
consulta, y cada tabla se revisa por cómo crece su partición.

---

**02 → 16.** Diagnostica: una tabla de tareas pendientes en Cassandra, en la que cada tarea se
inserta, se lee y se borra, tarda cada vez más en devolver las diez primeras aunque casi siempre hay
pocas. 🔴

⏱️ **30 segundos** — Tombstones. Cada tarea hecha deja una marca que dura diez días, y leer las diez
primeras obliga a recorrer todas las marcas de las borradas. Es el antipatrón de la cola en
Cassandra.

🗣️ **2 minutos** — Lo confirmaría con `nodetool tablestats`, mirando las tombstones leídas por
lectura, y con los avisos del registro del servidor. La solución es no usar Cassandra como cola: un
*stream* de Redis de [`07/02`](../07-clave-valor/02-redis-estructuras-y-ttl.md) o una cola de
verdad. Paliativos: particiones por intervalo que se descartan enteras.

🔬 **El detalle** — **Motor**. Bajar `gc_grace_seconds` reduce el síntoma pero exige reparar dentro
del nuevo plazo, o vuelven zombis.

---

**02 → 17.** Defiende o refuta pasar `eventos_pedido` de PostgreSQL a Cassandra en la tienda actual,
con los números del capítulo. 🔴

⏱️ **30 segundos** — Se refuta para la tienda actual. Son 4 100 000 filas que caben en memoria, y en
un nodo PostgreSQL cargó más de seis veces más rápido. Cassandra se justifica con escala de
telemetría, no con este volumen.

🗣️ **2 minutos** — Lo que se perdería: `JOIN` con los pedidos, `ORDER BY` arbitrario, que un
`INSERT` repetido dé error, y el borrado inmediato. Lo que haría hoy: un índice por pedido y fecha y
particionado por mes en PostgreSQL. Lo que cambiaría la decisión: decenas de miles de eventos por
segundo sostenidos, varias regiones escribiendo y una tabla que no cabe en una máquina.

🔬 **El detalle** — Lo que se evalúa es no aceptar el marco y dar el umbral medible que cambia la
respuesta.

---

## Capítulo 03 — Grafo

Las 18 preguntas de [`03`](03-grafo.md).

**03 → 1.** ¿Qué es un nodo, una relación y una propiedad en Neo4j? 🟢

⏱️ **30 segundos** — Un nodo es una cosa —un cliente, un producto— con etiquetas como `:Cliente`.
Una relación une dos nodos, tiene dirección y un tipo, como `:COMPRO`. Y las propiedades son pares
clave valor en los dos, como `codigo` o `unidades`.

🗣️ **2 minutos** — En el grafo del capítulo hay 48 252 nodos —43 252 clientes y 5 000 productos— y
345 378 relaciones `COMPRO` con la propiedad `unidades`. Lo que distingue al modelo es que la
relación se guarda como dato propio: desde un nodo se llega a sus vecinos sin buscar en un índice.

🔬 **El detalle** — **Motor** el almacenamiento; el modelo de grafo de propiedades es el que describe
GQL.

---

**03 → 2.** ¿Qué es un supernodo? 🟢

⏱️ **30 segundos** — Un nodo con muchas más relaciones que el resto. En la tienda, `PRD-00017`, con
2 528 compradores, cuando la media por producto es de 69,1.

🗣️ **2 minutos** — Cada recorrido que pasa por él arrastra sus miles de relaciones, y además vacía
de significado las preguntas de conexión: por su culpa, los 43 251 demás clientes están a dos
productos de `CLI-00311`.

🔬 **El detalle** — **Convención** de modelado el nombre y el remedio: excluirlo, ponderarlo o
limitar la profundidad.

---

**03 → 3.** ¿Qué es GQL, y quién lo publica? 🟢

⏱️ **30 segundos** — El lenguaje estándar para consultar grafos de propiedades, ISO/IEC 39075:2024,
publicado por ISO e IEC en 2024.

🗣️ **2 minutos** — La documentación de Cypher dice cubrir la mayoría de sus funciones obligatorias y
buena parte de las opcionales.
Convive con SQL/PGQ, la parte del estándar SQL para consultar grafos dentro de SQL.

🔬 **El detalle** — **Estándar**. Cypher es el lenguaje de Neo4j y la principal influencia de GQL.

---

**03 → 4.** ¿Qué hace `MERGE`, y en qué se diferencia de `CREATE`? ¿Lo fija el estándar o es cosa
del motor? 🟡

⏱️ **30 segundos** — `MERGE` busca el patrón y lo crea solo si no existe; `CREATE` lo crea siempre.
`MERGE` es la forma de cargar sin duplicar.

🗣️ **2 minutos** — En la carga, los nodos van con `MERGE`, porque cada cliente aparece en muchas
filas del CSV, y las relaciones con `CREATE`, porque cada fila es un par distinto. Sin índice,
`MERGE` busca recorriendo todos los nodos de la etiqueta; con la restricción de unicidad, usa su
índice.

🔬 **El detalle** — **Motor**. `MERGE` sin restricción no protege de dos cargas concurrentes: las dos
pueden no encontrar el nodo y crearlo a la vez.

---

**03 → 5.** ¿Por qué Neo4j necesita `CREATE CONSTRAINT` para evitar dos `CLI-00311`? ¿Lo fija el
estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — Porque Neo4j no tiene claves por defecto: nada impide dos nodos con la misma
propiedad `codigo`. La restricción de unicidad es lo más parecido a una clave primaria.

🗣️ **2 minutos** — La restricción crea además un índice, y ese índice es lo que hace rápidos el
`MERGE` de la carga y la búsqueda del nodo de partida en cada consulta. En `l05` §4 se provocó el
error: con la restricción, un segundo `CLI-00311` se rechazó.

🔬 **El detalle** — **Motor**. En PostgreSQL la clave primaria es obligatoria de hecho en cualquier
diseño serio; en Neo4j hay que acordarse de declararla.

---

**03 → 6.** Distingue un recorrido de profundidad fija de uno de profundidad variable, con un
ejemplo de la tienda para cada uno. 🟡

⏱️ **30 segundos** — En uno de profundidad fija, el número de saltos se sabe de antemano: la
recomendación, cliente → producto → cliente → producto, siempre tres. En uno de profundidad variable
no: el camino de `CLI-00311` a `CLI-26446` podía tener dos, cuatro u ocho saltos.

🗣️ **2 minutos** — La diferencia decide el motor. Con profundidad fija, PostgreSQL ganó: 143 ms
frente a 305. Con profundidad variable, Neo4j ganó: 25 ms frente a 3,7 s con la CTE directa, y 2 ms
frente a 24,6 s cuando no había camino.

🔬 **El detalle** — Las preguntas de fraude y de grados de separación son de profundidad variable; la
mayoría de las de negocio, de profundidad fija.

---

**03 → 7.** ¿Qué hace `shortestPath` para tardar 25 ms, según su documentación? 🟡

⏱️ **30 segundos** — Una búsqueda en anchura desde los dos extremos a la vez, que para en cuanto las
dos fronteras se encuentran, en vez de recorrer todo el grafo.

🗣️ **2 minutos** — Buscar desde el destino es también lo que hace que un camino imposible se
descarte enseguida: con `CLI-00007` sin relaciones, la frontera del destino estaba vacía desde el
primer paso y la consulta tardó 2 ms.

🔬 **El detalle** — **Motor**. La documentación lo describe para `shortestPath` con extremos
conocidos; si no se conoce el destino, no hay búsqueda desde los dos lados.

---

**03 → 8.** ¿Qué es SQL/PGQ, y qué pasó al probar `GRAPH_TABLE` en PostgreSQL 18? 🟡

⏱️ **30 segundos** — La parte del estándar SQL, añadida en 2023, para consultar grafos de
propiedades dentro de una consulta SQL, con la función `GRAPH_TABLE`. PostgreSQL 18 no la
implementa: dio error de sintaxis.

🗣️ **2 minutos** — El error fue `syntax error at or near "MATCH"`. Así que en PostgreSQL 18 el grafo
se consulta con `JOIN` y CTE recursivas, como en el capítulo.

🔬 **El detalle** — **Estándar**, sin verificar la cláusula. Lo que se afirma del motor está medido.

---

**03 → 9.** ¿Por qué la recomendación fue más rápida en PostgreSQL que en Neo4j? 🟠

⏱️ **30 segundos** — Porque la profundidad es fija: el planificador ve los tres saltos a la vez y
elige cómo unirlos, con índices que cubren las dos direcciones. 143 ms frente a 305.

🗣️ **2 minutos** — Un `JOIN` con índice no es lento; lo lento es un `JOIN` que no sabe cuántas veces
repetirse. La recomendación, además, termina en un agregado —contar clientes por producto—, que es
trabajo de conjunto, donde PostgreSQL es fuerte.

🔬 **El detalle** — Las dos cifras son de la segunda ejecución, con caché caliente. Es la razón de
que la recomendación sola no justifique una base de grafos.

---

**03 → 10.** ¿Por qué la CTE recursiva necesita `WHERE b.saltos < 2`, y qué pasa si el destino está
más lejos? 🟠

⏱️ **30 segundos** — Porque la CTE no para sola: vuelve a iterar mientras la vuelta anterior
produzca filas. El tope la limita a dos vueltas, cuatro saltos; si el destino está a seis, no lo
encuentra.

🗣️ **2 minutos** — Subir el tope multiplica el trabajo: con dos vueltas ya generó unos 25,9 millones
de filas. Y hay que adivinarlo de antemano, cuando en profundidad variable no se sabe.

🔬 **El detalle** — Es una de las dos defensas de `02/05` §5. Evita el bucle infinito; no evita la
explosión de caminos.

---

**03 → 11.** En el plan de §4, ¿qué significan `actual rows=8644018.33 loops=3` y `49055` en el
`Recursive Union`? 🟠

⏱️ **30 segundos** — Que el `Nested Loop` del término recursivo se ejecutó tres veces y produjo de
media 8,6 millones de filas en cada una: unos 25,9 millones en total. Y que de todo eso el
`Recursive Union` se quedó con 49 055 filas distintas.

🗣️ **2 minutos** — Las 49 055 son `(cliente, saltos)`: 1 en la vuelta cero, 5 802 en la primera y
43 252 en la segunda. La diferencia entre 25,9 millones y 49 055 es la explosión de caminos: cada
fila generada es un camino, no un cliente.

🔬 **El detalle** — `actual rows` en PostgreSQL 18 es la media por ejecución, con decimales; se
multiplica por `loops` para tener el total.

---

**03 → 12.** ¿Por qué `UNION` no evita que la CTE vuelva a visitar clientes? 🟠

⏱️ **30 segundos** — Porque `UNION` descarta filas repetidas, y la fila es el par de cliente y
número de saltos. Un cliente alcanzado en la vuelta 1 vuelve a salir en la 2 con otro número, y para
`UNION` es otra fila.

🗣️ **2 minutos** — Si la fila fuera solo el cliente, `UNION` sí lo descartaría, pero entonces se
pierde la distancia. Y antes de descartar, el `JOIN` ya generó todas las filas repetidas: el coste
está en producirlas.

🔬 **El detalle** — **Motor**: el término recursivo no puede consultar el resultado acumulado para
saltarse nodos visitados; solo ve la vuelta anterior.

---

**03 → 13.** ¿Por qué el supernodo `PRD-00017` hace que «estar a dos productos» no signifique nada,
y qué harías con él? 🟠

⏱️ **30 segundos** — Porque lo compraron 2 528 clientes, y a través de él y de los otros productos
populares, los 43 251 demás clientes están a dos productos de `CLI-00311`. Si todo conecta con todo,
la conexión no dice nada.

🗣️ **2 minutos** — Lo excluiría del recorrido —el más vendido no dice nada de los gustos de nadie—,
o ponderaría cada producto por lo raro que es, o limitaría la profundidad. En fraude es el teléfono
de atención al cliente que aparece en miles de cuentas.

🔬 **El detalle** — **Convención** de modelado. Conviene medir los grados antes de recorrer: la
consulta de compradores por producto tardó 126 ms.

---

**03 → 14.** ¿Cómo conseguiste que la CTE devolviera el camino y parara al encontrar el destino, y
por qué su documentación no lo recomienda? 🟠

⏱️ **30 segundos** — Arrastrando el camino en un array, con `UNION ALL` y `LIMIT 1` en la consulta
de fuera. Tardó 75 ms. Para porque PostgreSQL evalúa la CTE solo hasta las filas que pide la
consulta de fuera.

🗣️ **2 minutos** — La documentación lo explica y desaconseja usarlo como truco en producción: otros
sistemas pueden no hacerlo, y deja de funcionar si la consulta de fuera ordena o une el resultado
con otra tabla. Y `c2.cliente <> ALL (b.camino)` solo evita repetir un cliente dentro del mismo
camino.

🔬 **El detalle** — El primer camino que sale es de los más cortos porque la CTE avanza por vueltas.
Cuando no hay destino, el truco no ayuda: 24,6 s.

---

**03 → 15.** ¿Por qué Neo4j supo en 2 ms que no hay camino hasta `CLI-00007`, y la CTE tardó 24,6 s?
🟠

⏱️ **30 segundos** — Porque Neo4j busca también desde el destino, y `CLI-00007` no tiene relaciones:
su frontera está vacía desde el primer paso. La CTE busca desde un solo extremo y no sabe que no hay
camino hasta haber enumerado todos hasta el tope.

🗣️ **2 minutos** — `CLI-00007` es el cliente sin pedidos del documento de dominio; en Neo4j se dio
de alta con `MERGE` como nodo sin relaciones, que es lo que es. En el caso de fraude, casi todas las
consultas son de este tipo: la cuenta nueva no está conectada con ninguna bloqueada.

🔬 **El detalle** — **Motor**, el algoritmo. Es la cifra que más pesa a favor del grafo, porque es el
caso más frecuente.

---

**03 → 16.** Diseña el grafo para detectar anillos de fraude en la tienda: nodos, relaciones,
restricciones y qué supernodos esperas. 🔴

⏱️ **30 segundos** — Nodos `:Cliente`, `:Tarjeta`, `:Telefono` y `:Direccion`, cada uno con
restricción de unicidad sobre su identificador. Relaciones `USA`, `TIENE` y `VIVE_EN`, del cliente a
cada dato. La consulta es el camino más corto de la cuenta nueva a cualquier `:Cliente` bloqueado.

🗣️ **2 minutos** — El estado bloqueado va como etiqueta extra, `:Bloqueado`, para empezar la
búsqueda por ahí. Supernodos esperados: el teléfono de atención al cliente, las direcciones de
puntos de recogida y las tarjetas de prueba; se excluyen con una propiedad o no se cargan. El tope
de profundidad, seis saltos.

🔬 **El detalle** — El grafo es una copia: se alimenta desde la base principal, y el retraso de esa
copia es la ventana en la que un fraude pasa sin detectar.

---

**03 → 17.** Diagnostica: una consulta de «clientes conectados» en Neo4j pasó de 50 ms a 20 s tras
dar de alta el teléfono de atención al cliente como dato de contacto en todas las cuentas. 🔴

⏱️ **30 segundos** — Se creó un supernodo: el teléfono conecta a todas las cuentas entre sí, y cada
recorrido que lo toca arrastra todas sus relaciones. Además la respuesta dejó de servir: todos están
conectados con todos.

🗣️ **2 minutos** — Lo confirmaría contando relaciones por nodo, como la consulta de compradores por
producto de §5. La corrección es excluir ese teléfono: no cargarlo, marcarlo y filtrarlo en el
recorrido, o limpiar el dato en origen, que es un error de captura.

🔬 **El detalle** — **Convención** de modelado. Es el mismo fenómeno que `PRD-00017`, provocado por
un dato erróneo en vez de por popularidad.

---

**03 → 18.** Defiende o refuta añadir Neo4j a la tienda solo para la recomendación de productos, con
los números del capítulo. 🔴

⏱️ **30 segundos** — Se refuta. La recomendación es de profundidad fija, y PostgreSQL la resolvió en
143 ms frente a los 305 de Neo4j, sin otra copia de los datos.

🗣️ **2 minutos** — Añadir Neo4j significa mantener el grafo sincronizado, otra copia de seguridad y
otra guardia, para una consulta que ya va bien. Cambiaría la decisión una pregunta de profundidad
variable frecuente —fraude, grados de separación—, donde las cifras fueron 25 ms frente a 3,7 s y
2 ms frente a 24,6 s.

🔬 **El detalle** — Lo que se evalúa es separar las dos clases de recorrido y dar la cifra de cada
una.

---

## Capítulo 04 — Series temporales

Las 18 preguntas de [`04`](04-series-temporales.md).

**04 → 1.** ¿Qué es una hipertabla, y qué es un tramo? 🟢

⏱️ **30 segundos** — Una hipertabla es una tabla que TimescaleDB parte sola por intervalos de
tiempo. Cada trozo, un tramo o *chunk*, es una tabla normal de PostgreSQL; la hipertabla se consulta
con SQL normal.

🗣️ **2 minutos** — `eventos`, con tramos de siete días, quedó en 144 tramos creados al insertar, uno
por semana desde enero de 2023. El planificador descarta los tramos que no caen en el intervalo
pedido: la consulta de la última semana tocó dos.

🔬 **El detalle** — **Motor**: `create_hypertable` es de TimescaleDB; el particionado por rango que
hay debajo es el de PostgreSQL.

---

**04 → 2.** ¿Qué hace `time_bucket`? 🟢

⏱️ **30 segundos** — Redondea una marca de tiempo hacia abajo a un intervalo de la anchura que se
pida —un día, quince minutos, una semana— para agrupar por él. Es el `date_trunc` de TimescaleDB,
con cualquier anchura.

🗣️ **2 minutos** — En la consulta de la última semana, `time_bucket('1 day', ...)` dio lo mismo que
`date_trunc('day', ...)` en la tabla normal. La diferencia está en anchuras que `date_trunc` no
tiene, como `'15 minutes'`.

🔬 **El detalle** — **Motor**. Es la función en la que se apoyan los agregados continuos.

---

**04 → 3.** ¿Qué es un agregado continuo? 🟢

⏱️ **30 segundos** — Una vista materializada que TimescaleDB refresca por intervalos, recalculando
solo los que han cambiado. Contesta un panel sobre años sin recorrer los datos.

🗣️ **2 minutos** — `eventos_por_dia` se creó en 314 ms y contestó el año en 1,3 ms, frente a los
60 ms de la hipertabla sin comprimir. Su precio es que va por detrás del dato: el evento nuevo no
apareció hasta el refresco.

🔬 **El detalle** — **Motor**. En PostgreSQL sin extensión, `REFRESH MATERIALIZED VIEW` recalcula la
vista entera.

---

**04 → 4.** ¿Qué es el *downsampling*? 🟢

⏱️ **30 segundos** — Guardar el detalle poco tiempo y un resumen durante mucho más: por ejemplo, los
eventos crudos unos meses y los recuentos por día para siempre.

🗣️ **2 minutos** — En §6 se vio: `drop_chunks` borró los tramos de 2023, y el agregado continuo
siguió teniendo sus días, `min(dia)` en enero de 2023. El detalle desapareció y el resumen quedó.

🔬 **El detalle** — **Convención** de diseño. Hay que decidir qué preguntas se podrán seguir
haciendo sobre el pasado, porque las que necesitan el detalle dejan de poder contestarse.

---

**04 → 5.** Distingue la hipertabla del particionado declarativo de PostgreSQL. 🟡

⏱️ **30 segundos** — Las dos parten por rango de tiempo. Con el particionado declarativo, cada
partición se crea a mano antes de que lleguen sus datos; la hipertabla crea los tramos sola al
insertar, y añade compresión en columnas y agregados continuos.

🗣️ **2 minutos** — Borrar por antigüedad es barato en las dos, borrando particiones o tramos. Lo
que el particionado nativo no trae es convertir lo viejo a columnas —de 386 a 57 MB— ni un agregado
que se mantenga por intervalos.

🔬 **El detalle** — **Motor** las dos. Con extensiones de mantenimiento, el particionado nativo
también crea particiones por adelantado; la compresión sigue sin tenerla.

---

**04 → 6.** ¿Por qué la hipertabla no admite una clave primaria sin la columna de tiempo? 🟡

⏱️ **30 segundos** — Porque cada tramo es una tabla, y un índice único solo se comprueba dentro de
cada una. Una clave que no incluye la columna de tiempo no se puede garantizar entre tramos, y
TimescaleDB se niega a crear la hipertabla.

🗣️ **2 minutos** — En `l05` §5 se provocó el error: «cannot create a unique index without the
column "ocurrido_en"». Por eso `eventos` se creó sin clave primaria; si hiciera falta, sería
`(ocurrido_en, pedido_id, tipo)`.

🔬 **El detalle** — **Motor**, y la misma regla del particionado nativo de PostgreSQL: la clave
única tiene que incluir la columna de partición.

---

**04 → 7.** ¿Qué hacen `segmentby` y `orderby` al comprimir? 🟡

⏱️ **30 segundos** — `segmentby` agrupa las filas por el valor de una columna, que se guarda una
vez por grupo; `orderby` ordena las filas dentro del grupo, para que los valores consecutivos se
parezcan y compriman mejor.

🗣️ **2 minutos** — Con `segmentby = 'tipo'` y `orderby = 'ocurrido_en DESC'`, la hipertabla bajó de
386 a 57 MB, y contar por tipo un año pasó de 60 ms a 20, porque el grupo ya viene por tipo.

🔬 **El detalle** — **Motor**. Se elige como `segmentby` la columna por la que se filtra o agrupa;
una de muchos valores distintos haría grupos pequeños que comprimen mal.

---

**04 → 8.** ¿Por qué se dejan sin comprimir los tramos más recientes? 🟡

⏱️ **30 segundos** — Porque siguen recibiendo escrituras, y un tramo en columnas está pensado para
no cambiar: modificar una fila obliga al motor a tratar el grupo entero en el que está.

🗣️ **2 minutos** — En el capítulo se comprimieron los 139 tramos anteriores a septiembre de 2025 y
quedaron cinco sin comprimir. En producción lo hace una política que comprime lo que tiene más de
cierta edad.

🔬 **El detalle** — **Motor**: la documentación recomienda convertir solo lo que ya no cambia. Es el
precio de toda base columnar.

---

**04 → 9.** ¿Qué dice la documentación de Prometheus sobre su almacenamiento local, y qué implica? 🟡

⏱️ **30 segundos** — Que no está en clúster ni replicado, así que no es escalable sin límite ni
aguanta la pérdida de un disco o un nodo. Retiene 15 días por defecto.

🗣️ **2 minutos** — Implica que Prometheus es un sistema de monitorización, no una base para datos de
negocio: para guardar años o para no perder nada, se usa un almacenamiento remoto. Guarda las
muestras en bloques de dos horas que compacta en segundo plano.

🔬 **El detalle** — **Motor**, según su documentación de almacenamiento.

---

**04 → 10.** ¿Por qué la consulta de la última semana empató entre la hipertabla y la tabla normal?
🟠

⏱️ **30 segundos** — Porque un índice por fecha encuentra una semana de datos igual de bien en una
tabla que en 144. 2,8 ms frente a 4,0.

🗣️ **2 minutos** — El plan de la hipertabla tocó dos tramos, uno con índice y otro entero, y la
tabla normal usó su índice. La exclusión de tramos no aporta nada que el índice no diera para una
consulta así.

🔬 **El detalle** — Quien diga que TimescaleDB acelera esa consulta tiene que enseñar el plan. Lo que
acelera es el agregado largo, comprimido o materializado.

---

**04 → 11.** ¿Por qué la hipertabla tardó más en cargar y ocupaba más antes de comprimir? 🟠

⏱️ **30 segundos** — Cargar: 8,8 s frente a 6,3, porque decide el tramo de cada fila y crea los
tramos nuevos, mientras el índice de la tabla normal solo crecía por la derecha con los datos
ordenados. Ocupar: 386 MB frente a 309, porque son 144 tablas con 144 índices.

🗣️ **2 minutos** — Hasta la compresión, TimescaleDB solo cuesta. La ventaja de escritura aparece con
datos que no caben en memoria o que llegan desordenados, no en una carga ordenada.

🔬 **El detalle** — Cada tramo tiene sus páginas de cabecera y su índice propio; el sobrecoste es por
tramo, y crece si los tramos son pequeños.

---

**04 → 12.** ¿Por qué el agregado del año bajó de 60 ms a 20 al comprimir? 🟠

⏱️ **30 segundos** — Porque en columnas se leen solo las columnas que hacen falta, comprimidas, y
con `segmentby = 'tipo'` las filas ya vienen agrupadas por tipo. Leer menos bytes es tardar menos.

🗣️ **2 minutos** — La tabla normal tardó 91 ms: recorre filas enteras aunque la consulta solo use
`tipo` y `ocurrido_en`. Es el mismo principio que las bases analíticas en columnas.

🔬 **El detalle** — **Motor**. El agregado continuo contestó lo mismo en 1,3 ms, porque ni siquiera
lee eventos.

---

**04 → 13.** ¿Por qué el evento nuevo no apareció en el agregado continuo hasta el refresco, y qué
alternativas hay? 🟠

⏱️ **30 segundos** — Porque el agregado es una materialización: solo contiene lo calculado en el
último refresco. 234 antes y 235 después de `refresh_continuous_aggregate`.

🗣️ **2 minutos** — Alternativas: programar el refresco con una política, cada pocos minutos; o
activar la agregación en tiempo real con `materialized_only = false`, que suma al vuelo lo no
materializado a cambio de consultas más lentas.

🔬 **El detalle** — **Motor**: la documentación dice que desde la 2.13 la agregación en tiempo real
viene desactivada por defecto.

---

**04 → 14.** ¿Por qué quedó un evento de 2023 tras `drop_chunks` con fecha de 2024? 🟠

⏱️ **30 segundos** — Porque `drop_chunks` borra tramos enteros, y solo los que caen **del todo**
antes de la fecha. El tramo del 28 de diciembre de 2023 llega hasta enero de 2024, así que se
quedó.

🗣️ **2 minutos** — `min(ocurrido_en)` dio `2023-12-28`. Si la política exige borrar hasta el día
exacto, hace falta un `DELETE` del resto de ese tramo, o tramos alineados con la unidad de la
política.

🔬 **El detalle** — **Motor**: la documentación de `drop_chunks` advierte de que pueden quedar
marcas de tiempo anteriores a la fecha dada.

---

**04 → 15.** ¿Por qué el `DELETE` no redujo el tamaño de `eventos_plano`, y qué haría falta? 🟠

⏱️ **30 segundos** — Porque `DELETE` solo marca las filas como muertas; el espacio queda en la tabla
hasta que `VACUUM` lo recicle, y al disco solo vuelve si las páginas vacías quedan al final. Siguió
en 309 MB tras borrar 1,5 millones de filas.

🗣️ **2 minutos** — Haría falta `VACUUM` para reutilizarlo y `VACUUM FULL` o reescribir la tabla para
devolverlo, con bloqueo. Además, el `DELETE` escribió cada borrado en el WAL. `drop_chunks` borró
52 tramos en 32 ms y la hipertabla bajó de 57 a 40 MB.

🔬 **El detalle** — Es MVCC, de
[`04/03`](../04-transacciones-y-concurrencia/03-mvcc-frente-a-bloqueo.md).

---

**04 → 16.** Diseña el almacenamiento de las métricas de §7: tramo, compresión, agregados y
retención, con lo que cuesta cada decisión. 🔴

⏱️ **30 segundos** — Hipertabla con tramos de un día; compresión de lo que tiene más de siete días,
con `segmentby` por instancia y métrica; un agregado continuo por hora para los paneles, refrescado
cada pocos minutos; y `drop_chunks` diario para lo que pase de un año.

🗣️ **2 minutos** — Tramos de un día porque la retención es diaria y así se borran enteros.
Compresión a los siete días porque las métricas no se corrigen, y se paga si alguna vez hay que
hacerlo. El agregado horario lleva el panel de 90 días de 150 millones de filas a unas 2 000 por
serie, y va por detrás unos minutos. Y el agregado se conserva más que el detalle.

🔬 **El detalle** — Hay que medir la carga con el volumen real: en §2 la hipertabla cargó más
despacio que una tabla normal.

---

**04 → 17.** Diagnostica: un panel sobre un agregado continuo enseña cero pedidos en la última hora,
aunque la tabla de eventos tiene cientos. 🔴

⏱️ **30 segundos** — El agregado no se ha refrescado para esa hora, y la agregación en tiempo real
está desactivada, que es lo de defecto desde la 2.13. La vista solo tiene lo materializado.

🗣️ **2 minutos** — Lo confirmaría comparando la vista con la tabla para esa hora y revisando la
política de refresco. Corrección: refresco más frecuente para el intervalo reciente, o
`materialized_only = false` en esa vista, sabiendo que cada consulta sumará al vuelo.

🔬 **El detalle** — Es el 234 frente a 235 de la sesión. Un panel de «última hora» sobre un agregado
necesita decidir cuánto retraso acepta.

---

**04 → 18.** Defiende o refuta montar InfluxDB para los eventos de la tienda en vez de usar
TimescaleDB, con los números del capítulo. 🔴

⏱️ **30 segundos** — Se refuta. TimescaleDB, dentro de PostgreSQL, dio compresión a 57 MB, el año en
1,3 ms con un agregado continuo y la retención en 32 ms, sin otra copia de los datos ni otro
lenguaje.

🗣️ **2 minutos** — InfluxDB 3 Core es un motor aparte, que guarda en Parquet y se consulta con SQL o
InfluxQL: otra copia que sincronizar, y los eventos dejan de poder unirse con los pedidos. Cambiaría
la decisión un volumen de métricas que no quepa en PostgreSQL o un ecosistema de monitorización ya
montado sobre InfluxDB.

🔬 **El detalle** — Lo que se evalúa es que la forma temporal de los datos no basta para cambiar de
motor.

---

## Capítulo 05 — Búsqueda de texto

Las 18 preguntas de [`05`](05-busqueda-de-texto.md).

**05 → 1.** ¿Qué es un índice invertido? 🟢

⏱️ **30 segundos** — Una estructura que guarda, para cada término, la lista de documentos que lo
contienen. Buscar una palabra es leer su lista, no recorrer los documentos.

🗣️ **2 minutos** — Es lo que construye OpenSearch para cada campo `text`, y lo que es un índice GIN
sobre un `tsvector` en PostgreSQL: el plan de la búsqueda de «camara» usó un `Bitmap Index Scan`
sobre `productos_texto_fts`.

🔬 **El detalle** — **Motor** cada implementación; el concepto es de recuperación de información.

---

**05 → 2.** ¿Qué son la tokenización y el *stemming*? 🟢

⏱️ **30 segundos** — Tokenizar es partir el texto en palabras. El *stemming* reduce cada palabra a
su raíz, para que «auriculares» y «auricular» queden iguales.

🗣️ **2 minutos** — El analizador español de OpenSearch dejó «Cámara deportiva con batería» en
`camar`, `deportiv` y `bateri`: sin tildes, en minúsculas, sin «con». PostgreSQL dejó «batería» en
`bat`.

🔬 **El detalle** — **Motor**: cada motor y cada idioma tiene sus reglas, y deciden lo que se
encuentra.

---

**05 → 3.** ¿Qué es BM25, y quién lo usa por defecto? 🟢

⏱️ **30 segundos** — Un algoritmo de puntuación de relevancia: puntúa más los documentos que
contienen muchas veces las palabras buscadas, que contienen palabras raras en la colección y que son
cortos. OpenSearch lo usa por defecto.

🗣️ **2 minutos** — Los tres primeros resultados de «auriculares inalámbricos batería» empataron a
5,18 porque sus descripciones solo difieren en la coletilla, que no contiene ninguna palabra
buscada.

🔬 **El detalle** — BM25 es un algoritmo de recuperación de información, no una norma. PostgreSQL
ofrece `ts_rank`, que pondera por frecuencia.

---

**05 → 4.** ¿Qué es el refresco de un índice de OpenSearch, y cada cuánto ocurre por defecto? 🟢

⏱️ **30 segundos** — La operación que hace visibles para la búsqueda los documentos escritos desde
el refresco anterior. Por defecto, cada segundo, mientras el índice reciba búsquedas.

🗣️ **2 minutos** — Tras actualizar `PRD-00017`, contar «limitada» dio 0; tras `_refresh`, 1. El
ajuste es `refresh_interval`, que vale `1s` por defecto.

🔬 **El detalle** — **Motor**. Por eso se habla de búsqueda casi en tiempo real.

---

**05 → 5.** ¿Por qué `LIKE '%camara%'` no encontró ninguna de las 328 cámaras? 🟡

⏱️ **30 segundos** — Porque `LIKE` compara caracteres, y `a` no es `á`. Con la tilde y sin
distinguir mayúsculas, `ILIKE '%cámara%'`, encontró las 328.

🗣️ **2 minutos** — Para que la tilde no importe hace falta quitarla antes de comparar, con la
extensión `unaccent`, o usar la búsqueda de texto completo, que la quitó al analizar: `camara` y
`cámara` quedaron en `cam`.

🔬 **El detalle** — **Estándar** el `LIKE`; que compare byte a byte o por colación depende del motor.

---

**05 → 6.** ¿Por qué el B-tree sobre `descripcion` no sirvió para `LIKE '%cámara%'`? 🟡

⏱️ **30 segundos** — Porque un B-tree ordena por el principio de la cadena, y con un comodín a la
izquierda no hay principio por el que buscar. El plan siguió en `Seq Scan`.

🗣️ **2 minutos** — Con un prefijo fijo, `LIKE 'cámara%'`, sí podría usarlo si la colación lo
permite. Para comodines por los dos lados, el índice útil es GIN con trigramas, de `pg_trgm`.

🔬 **El detalle** — **Motor**. `~~` es como escribe el plan un `LIKE`.

---

**05 → 7.** Distingue `to_tsvector` de `plainto_tsquery`, y di qué hace `@@`. 🟡

⏱️ **30 segundos** — `to_tsvector` analiza el documento y devuelve sus raíces con posiciones;
`plainto_tsquery` analiza la búsqueda y une sus raíces con Y. `@@` dice si el documento cumple la
búsqueda.

🗣️ **2 minutos** — Los dos con la misma configuración, `'spanish'`: si se analizaran distinto, las
raíces no coincidirían nunca. `plainto_tsquery` es el que acepta texto libre de un usuario.

🔬 **El detalle** — **Motor**. Existen también `to_tsquery`, con operadores explícitos, y
`websearch_to_tsquery`, con sintaxis de buscador.

---

**05 → 8.** Distingue `keyword` de `text` en un mapeo de OpenSearch. 🟡

⏱️ **30 segundos** — `keyword` guarda el valor entero, para filtrar, agrupar y ordenar. `text` lo
analiza en términos, para buscar por palabras.

🗣️ **2 minutos** — En el índice `productos`, `codigo` y `categoria` son `keyword` y `descripcion` es
`text` con analizador español. Buscar una palabra dentro de un `keyword` no funciona, y agrupar por
un `text` tampoco.

🔬 **El detalle** — **Motor**. Sin mapeo explícito, OpenSearch deduce el tipo del primer documento,
como se vio en `l05` §7.

---

**05 → 9.** ¿Qué hace `"fuzziness": "AUTO"`, y cómo se acerca PostgreSQL a lo mismo? 🟡

⏱️ **30 segundos** — Acepta términos a una o dos ediciones de distancia —una letra de más, de menos
o cambiada—, según la longitud de la palabra. `auriculres` encontró los 95 auriculares.

🗣️ **2 minutos** — La búsqueda de texto de PostgreSQL no lo hace: la errata dio 0. Lo más parecido
es `pg_trgm`, que compara trigramas y da una similitud entre cadenas, con índice GIN o GiST.

🔬 **El detalle** — **Motor**. La tolerancia a erratas trae falsos positivos: palabras cortas a una
letra de otras.

---

**05 → 10.** ¿Por qué PostgreSQL encontró 0 productos buscando «auricular», si hay 95
«auriculares»? 🟠

⏱️ **30 segundos** — Porque el *stemmer* español de PostgreSQL reduce «auriculares» a `auricular` y
«auricular» a `auricul`, y las raíces no coinciden.

🗣️ **2 minutos** — Se ve en la sesión: el `tsvector` guardó `'auricular'` y la búsqueda del singular
fue `'auricul'`. OpenSearch, con `light_spanish`, dejó las dos en `auricular` y encontró 95.

🔬 **El detalle** — **Motor**. No se supone que un analizador acierta: se prueba con las palabras del
catálogo.

---

**05 → 11.** ¿Por qué el índice GIN tiene que usar exactamente la misma expresión que la
consulta? 🟠

⏱️ **30 segundos** — Porque es un índice sobre una expresión: el planificador solo lo usa si la
consulta contiene esa misma expresión, `to_tsvector('spanish', descripcion)`, con la configuración
incluida.

🗣️ **2 minutos** — Si la consulta usara `to_tsvector(descripcion)` sin configuración, dependería de
`default_text_search_config` y no casaría con el índice. La alternativa es una columna generada con
el `tsvector` e indexarla.

🔬 **El detalle** — **Motor**: es la regla de los índices de expresión de `03/02`.

---

**05 → 12.** ¿Por qué PostgreSQL devolvió solo productos con las tres palabras y OpenSearch 162? 🟠

⏱️ **30 segundos** — Porque `plainto_tsquery` une los términos con Y, y `match` de OpenSearch con O
por defecto. PostgreSQL filtra y después ordena; OpenSearch ordena todo lo que se parece.

🗣️ **2 minutos** — Los primeros resultados son los mismos. La diferencia está en la cola: OpenSearch
también devuelve los que solo tienen una o dos de las palabras, con menos puntuación.

🔬 **El detalle** — **Motor**. `match` acepta `"operator": "and"`, y PostgreSQL permite O con
`to_tsquery` o `websearch_to_tsquery`.

---

**05 → 13.** ¿Qué riesgo tiene que «cámara» se reduzca a `cam`? 🟠

⏱️ **30 segundos** — Que una raíz tan corta junta palabras distintas que empiecen igual, y la
búsqueda devuelve falsos positivos.

🗣️ **2 minutos** — En este catálogo no pasó, porque no hay otra palabra que se reduzca a `cam`. En
uno real sí puede. Es el precio de reducir: más coincidencias, algunas falsas.

🔬 **El detalle** — Se mitiga con otro diccionario o con un *stemmer* menos agresivo, a cambio de
perder variantes.

---

**05 → 14.** Tras actualizar `PRD-00017`, la búsqueda devolvió 0. ¿Por qué, y qué pasa en una
arquitectura real? 🟠

⏱️ **30 segundos** — Porque el documento estaba escrito pero no era visible para la búsqueda hasta
el siguiente refresco. Tras `_refresh`, 1.

🗣️ **2 minutos** — En una arquitectura real, el cambio llega desde la base principal por una cola o
un proceso de sincronización, y el retraso es de segundos o minutos. Durante ese tiempo, el buscador
enseña datos viejos.

🔬 **El detalle** — **Motor** el refresco; **convención** de arquitectura la sincronización.

---

**05 → 15.** ¿Por qué un motor de búsqueda nunca debe ser la fuente de verdad? 🔴

⏱️ **30 segundos** — Porque no comparte transacción con la base principal: si la sincronización
falla, se desincroniza en silencio. Es una copia para buscar, no el registro.

🗣️ **2 minutos** — Se diseña para poder reconstruirlo entero desde la base, y la aplicación vuelve a
la base para lo que importa: el precio o el stock del producto encontrado.

🔬 **El detalle** — **Convención** de arquitectura.

---

**05 → 16.** Diseña el buscador de la tienda en PostgreSQL, sin motor aparte: extensiones, índices y
consulta para tildes, plurales, erratas y orden. 🔴

⏱️ **30 segundos** — Una configuración de texto que aplique `unaccent` antes del diccionario
español, una columna generada con el `tsvector` e índice GIN, `pg_trgm` con GIN para las erratas, y
`websearch_to_tsquery` con `ts_rank` para ordenar.

🗣️ **2 minutos** — La consulta busca primero por texto completo; si no hay resultados, cae a
similitud por trigramas. Los plurales se prueban con las palabras reales del catálogo, porque el
*stemmer* de PostgreSQL falló con «auricular»; si falla, un diccionario de sinónimos o de sufijos lo
corrige.

🔬 **El detalle** — Todo en la misma base y la misma transacción: un producto dado de baja
desaparece del buscador al confirmar.

---

**05 → 17.** Diagnostica: un producto dado de baja hace una hora sigue saliendo en el buscador,
aunque en la base consta como inactivo. 🔴

⏱️ **30 segundos** — El cambio no llegó al índice de búsqueda: la sincronización entre la base y
OpenSearch falló o va con retraso. El refresco explica un segundo, no una hora.

🗣️ **2 minutos** — Lo confirmaría leyendo el documento en OpenSearch y comparándolo con la fila, y
mirando la cola o el proceso de sincronización. Corrección: reindexar ese documento, arreglar la
sincronización, y filtrar en la aplicación contra la base lo que se va a enseñar.

🔬 **El detalle** — Es lo que se paga por la copia. A medio plazo, una reconciliación periódica que
compare los dos lados.

---

**05 → 18.** Defiende o refuta montar OpenSearch para el buscador de la tienda actual, con los
números del capítulo. 🔴

⏱️ **30 segundos** — Se refuta para la tienda actual. Con 5 000 productos, PostgreSQL arregló la
tilde, ordenó por relevancia y usó un índice GIN; el singular y las erratas se cubren con
`unaccent`, un diccionario y `pg_trgm`.

🗣️ **2 minutos** — OpenSearch lo haría mejor en plurales y erratas, pero a cambio de otra copia
sincronizada que enseñó un cambio tarde, y de otro sistema que operar. Cambiaría la decisión un
catálogo de millones de productos, cientos de búsquedas por segundo o facetas complejas.

🔬 **El detalle** — Lo que se evalúa es el paso 3 del criterio de `01`: agotar lo que da la base
actual antes de añadir una copia.

---

## Capítulo 06 — Vectorial y embeddings

Las 17 preguntas de [`06`](06-vectorial-y-embeddings.md).

**06 → 1.** ¿Qué es un embedding? 🟢

⏱️ **30 segundos** — Un vector de números que un modelo calcula para un texto —o una imagen—, de
modo que los de significado parecido queden cerca. Aquí, 768 números por descripción.

🗣️ **2 minutos** — Los 5 000 se calcularon con `nomic-embed-text` en 61 s. La calidad del vector la
decide el modelo: este, entrenado sobre todo en inglés, apenas separó significados en español.

🔬 **El detalle** — El vector es del **modelo**; guardarlo y compararlo, del **motor**.

---

**06 → 2.** ¿Qué mide la distancia del coseno, y qué operador la calcula en pgvector? 🟢

⏱️ **30 segundos** — Compara la dirección de dos vectores, sin importar su longitud: 0 es la misma
dirección y 1, ninguna relación. En pgvector es `<=>`.

🗣️ **2 minutos** — Es la habitual para texto. La euclídea es `<->`. La aspiradora quedó a 0,3021 de
la pregunta de la música, y Qdrant dio 0,6979 de similitud: 1 − 0,3021.

🔬 **El detalle** — La distancia es matemática; el operador y su índice, `vector_cosine_ops`, son de
pgvector.

---

**06 → 3.** ¿Qué es el *recall* de una búsqueda aproximada? 🟢

⏱️ **30 segundos** — La fracción de los vecinos reales que devuelve. Si de los 10 más cercanos
devuelve 3, el *recall* es 0,3.

🗣️ **2 minutos** — Para medirlo hace falta la respuesta exacta: en el capítulo, la tabla `verdad`
con los 10 vecinos de cada consulta, calculada sin índice.

🔬 **El detalle** — Es la cifra que decide si un índice vectorial sirve, y no viene en ninguna
documentación: depende de los datos.

---

**06 → 4.** Distingue KNN de ANN. ¿Lo fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — KNN exacto calcula la distancia a todos los vectores y devuelve los *k* más
cercanos de verdad. ANN, aproximado, mira solo una parte y acepta perderse alguno a cambio de
velocidad.

🗣️ **2 minutos** — Con 100 000 vectores aleatorios, el exacto dio *recall* 1 en 271 ms para 20
consultas, y el HNSW 0,325 en 20 ms. El README de pgvector avisa de que los resultados cambian al
crear el índice.

🔬 **El detalle** — **Motor**: sin índice, pgvector es exacto.

---

**06 → 5.** Distingue HNSW de IVFFlat: cómo buscan y qué cuesta cada uno. 🟡

⏱️ **30 segundos** — HNSW construye un grafo de capas y baja por él hacia la pregunta. IVFFlat
reparte los vectores en listas alrededor de centros y busca en las más cercanas. HNSW da mejor
*recall* por tiempo; IVFFlat se construye mucho más rápido.

🗣️ **2 minutos** — Sobre `azar`: HNSW en 41 s y 79 MB; IVFFlat en 0,8 s y 53 MB. Con 10 listas
exploradas, IVFFlat dio 0,355 en 45 ms; HNSW con `ef_search = 200`, 0,665 en 75 ms.

🔬 **El detalle** — IVFFlat calcula sus centros con los datos que hay al crearlo; HNSW se puede crear
con la tabla vacía, según el README.

---

**06 → 6.** ¿Qué hacen `hnsw.ef_search` e `ivfflat.probes`, y cuál es su valor por defecto? 🟡

⏱️ **30 segundos** — `ef_search` es cuántos candidatos explora el HNSW, 40 por defecto. `probes` es
en cuántas listas busca IVFFlat, 1 por defecto. Más, mejor *recall* y más tiempo.

🗣️ **2 minutos** — `ef_search` de 40 a 200 subió el *recall* de 0,325 a 0,665 y el tiempo de 20 a
75 ms. `probes` de 1 a 10, de 0,080 a 0,355 y de 6 a 45 ms. Son el mando entre velocidad y
exactitud.

🔬 **El detalle** — `ef_search` también limita las filas que puede devolver una consulta con filtro,
que es §5.

---

**06 → 7.** ¿Por qué `vector(768)` fija la dimensión, y qué implica cambiar de modelo? 🟡

⏱️ **30 segundos** — Porque las distancias solo tienen sentido entre vectores del mismo espacio, del
mismo modelo. La columna rechaza un vector de otra dimensión, como se provocó en `l05` §6.

🗣️ **2 minutos** — Cambiar de modelo obliga a recalcular todos los vectores, incluidos los de las
consultas, y a reconstruir el índice. Aunque la dimensión coincidiera, mezclar modelos da distancias
sin sentido.

🔬 **El detalle** — Por eso se guarda con qué modelo y versión se calculó cada vector.

---

**06 → 8.** ¿Por qué la búsqueda semántica devolvió aspiradoras para «algo para escuchar música sin
cables»? 🟠

⏱️ **30 segundos** — Porque el modelo, `nomic-embed-text`, está entrenado sobre todo en inglés y en
español apenas separa significados: lo que acercó la aspiradora fue compartir «sin cable».

🗣️ **2 minutos** — Medido aparte, la pregunta quedaba a 0,468 de los auriculares y a 0,302 de la
aspiradora. La base de datos hizo bien su parte: devolvió los vectores más cercanos. El fallo es de
«parecido», que lo define el modelo.

🔬 **El detalle** — Antes de elegir motor se evalúa el modelo con preguntas reales en el idioma real.
Un modelo multilingüe no se ha medido aquí.

---

**06 → 9.** ¿Por qué falló la creación del índice HNSW sobre `azar`, y cómo se corrigió? 🟠

⏱️ **30 segundos** — La construcción en paralelo pidió 1 036 863 424 bytes de memoria compartida, y
el contenedor tiene 64 MB en `/dev/shm`, el valor por defecto de Docker. Se corrigió con
`max_parallel_maintenance_workers = 0`, que construye en serie.

🗣️ **2 minutos** — En serie tardó 41 s. La otra corrección es dar al contenedor más memoria
compartida, y entonces el paralelo acelera la construcción.

🔬 **El detalle** — Es un error del entorno, no de pgvector, y aparece al crecer el índice: con 5 000
vectores no se vio.

---

**06 → 10.** ¿Por qué el HNSW tuvo *recall* 0,325 con vectores aleatorios y efectivamente 1 con los
de la tienda? 🟠

⏱️ **30 segundos** — Porque los vectores aleatorios en 128 dimensiones están todos casi a la misma
distancia entre sí, y ningún índice aproximado distingue bien a los vecinos. Los embeddings reales
tienen estructura: grupos de textos parecidos.

🗣️ **2 minutos** — Con los de la tienda, las 200 posiciones de la búsqueda aproximada tuvieron la
misma distancia que las de la exacta. Además, 5 000 vectores son pocos para que el grafo pierda
algo.

🔬 **El detalle** — Por eso el *recall* se mide con datos reales y volumen real, no con un banco de
pruebas sintético.

---

**06 → 11.** ¿Cómo se comprobó que el 0,885 eran empates y no fallos? 🟠

⏱️ **30 segundos** — Comparando distancias en vez de códigos: se guardaron las 10 distancias exactas
y las 10 aproximadas de cada consulta, y coincidieron las 200.

🗣️ **2 minutos** — La exacta se forzó con `enable_indexscan = off`. Hay descripciones idénticas, con
vectores idénticos, y entre vecinos empatados el índice eligió otros códigos igual de cercanos.

🔬 **El detalle** — Es una trampa de medición: el *recall* por identificador subestima cuando hay
duplicados.

---

**06 → 12.** ¿Por qué el filtro por «deporte» devolvió 0 filas de 10, y qué lo corrige? ¿Lo fija el
estándar o es cosa del motor? 🟠

⏱️ **30 segundos** — Porque con un índice aproximado el `WHERE` se aplica después: el HNSW trae
`ef_search` candidatos, 40, y ninguno de los 40 más cercanos era de deporte. Lo corrige
`hnsw.iterative_scan`, que sigue recorriendo hasta reunir las filas.

🗣️ **2 minutos** — Había 467 productos de deporte. Con `strict_order` devolvió 10. La consulta sin
corregir no da error ni aviso: devuelve menos filas y ya.

🔬 **El detalle** — **Motor**: la búsqueda iterativa existe desde pgvector 0.8.0, con un tope
configurable.

---

**06 → 13.** ¿Por qué Qdrant no había construido índice con 5 000 puntos? 🟠

⏱️ **30 segundos** — Porque por debajo de `indexing_threshold`, 10 000 KB por defecto, Qdrant
recorre el segmento entero en vez de construir el HNSW. `indexed_vectors_count` era 0.

🗣️ **2 minutos** — La consulta exacta, con `"exact": true`, devolvió lo mismo que la normal. Con
pocos datos, recorrer es barato y construir un índice no compensa.

🔬 **El detalle** — **Motor**, según la documentación del optimizador de Qdrant.

---

**06 → 14.** ¿Qué gana y qué pierde la tienda con Qdrant frente a pgvector? 🟠

⏱️ **30 segundos** — Gana un motor optimizado para vectores, con un HNSW que tiene en cuenta los
filtros. Pierde tener el vector junto a los datos, en la misma transacción y la misma copia de
seguridad.

🗣️ **2 minutos** — Con los mismos vectores, los dos devolvieron lo mismo: 0,6979 frente a 0,3021 de
distancia. Qdrant es otra copia que sincronizar, y el filtro que en pgvector vació el resultado es
justo lo que su HNSW con filtros promete resolver.

🔬 **El detalle** — **Motor** lo de cada uno; lo de los filtros de Qdrant sale de su documentación,
no de una medición.

---

**06 → 15.** Diseña la búsqueda semántica del catálogo: modelo, tabla, índice, parámetros y cómo
medirías que funciona antes de publicarla. 🔴

⏱️ **30 segundos** — Un modelo evaluado en español; `productos_vec` con el vector, el modelo y su
versión; HNSW con distancia del coseno; `ef_search` ajustado midiendo *recall*; y búsqueda iterativa
para los filtros.

🗣️ **2 minutos** — Antes de publicar, un conjunto de preguntas reales con los productos que deberían
salir, para medir la calidad del modelo, y el *recall* del índice contra la búsqueda exacta. Probar
los filtros con categorías poco frecuentes. Y quitar repetidos del resultado.

🔬 **El detalle** — Si el modelo cambia, se recalcula todo; el diseño tiene que permitir dos columnas
de vectores durante la migración.

---

**06 → 16.** Diagnostica: tras añadir un filtro por idioma, el asistente contesta «no he encontrado
nada» para preguntas en portugués, aunque hay miles de fragmentos en ese idioma. 🔴

⏱️ **30 segundos** — El filtro se aplica después del índice: los `ef_search` candidatos más cercanos
no son en portugués, y al filtrar no queda ninguno. Es el 0 de 10 de «deporte».

🗣️ **2 minutos** — Lo confirmaría con la misma consulta y la búsqueda iterativa activada, o sin
índice. Correcciones: `hnsw.iterative_scan`, subir `ef_search`, o un índice parcial o una tabla por
idioma, para que el recorrido solo vea fragmentos en portugués.

🔬 **El detalle** — Si el modelo no es multilingüe, las preguntas en portugués pueden además quedar
lejos de todo; son dos causas distintas y se separan midiendo.

---

**06 → 17.** Defiende o refuta montar Qdrant para la tienda en vez de pgvector, con los números del
capítulo. 🔴

⏱️ **30 segundos** — Se refuta. Con 5 000 productos, pgvector dio los mismos resultados que Qdrant y
un *recall* efectivo de 1 con HNSW, y el problema de verdad fue el modelo, que ningún motor arregla.

🗣️ **2 minutos** — Qdrant añadiría otra copia y otro servicio. El filtro vacío se corrigió en
pgvector con la búsqueda iterativa. Cambiaría la decisión un volumen de millones de vectores,
filtros complejos a gran escala o una latencia que PostgreSQL no dé, medida.

🔬 **El detalle** — Lo que se evalúa es separar el problema del modelo del problema del motor.

---

## Simulación de entrevista

Las 26 preguntas `S#` y los cuatro escenarios de [`07`](07-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**07 → S1.** ¿Por qué «NoSQL» no sirve para decidir nada? Da tres motores que no comparten ni el
modelo ni el comportamiento ante fallos. 🟡

⏱️ **30 segundos** — Porque es una etiqueta histórica que agrupa motores por lo que no son. Redis
guarda estructuras por clave y pierde lo no replicado al promover una réplica; MongoDB guarda
documentos y deja de escribir sin mayoría; Cassandra guarda particiones y deja elegir por operación
cuántas réplicas esperar.

🗣️ **2 minutos** — Ninguno comparte lenguaje: órdenes por estructura, filtros y *pipeline*, CQL.
«Usemos NoSQL» no es una propuesta; «Cassandra, porque se lee por pedido y rango y aceptamos leer un
dato viejo durante un fallo», sí.

🔬 **El detalle** — **Convención**: no hay estándar ni definición detrás de la palabra.

---

**07 → S2.** Explica CAP sin decir «elige dos de tres», con lo que hicieron MongoDB y Cassandra al
perder dos de tres nodos. 🟠

⏱️ **30 segundos** — Durante una partición, un sistema distribuido o responde con lo que tiene,
arriesgando un dato viejo, o se niega a responder a una parte. MongoDB se negó: el nodo solo se
degradó a secundario y la escritura dio `NotWritablePrimary`. Cassandra con `ONE` aceptó la
escritura.

🗣️ **2 minutos** — La misma Cassandra con `QUORUM` rechazó la escritura, con dos réplicas requeridas
y una viva. CAP no clasifica motores: clasifica lo que hace cada operación durante el fallo. Sin
partición, no dice nada.

🔬 **El detalle** — Lo que se evalúa es no decir «PostgreSQL es CA»: un nodo solo no es distribuido.

---

**07 → S3.** ¿Qué cinco preguntas harías antes de proponer un motor nuevo, y cuál es la que más se
salta? 🟠

⏱️ **30 segundos** — Cómo se lee el dato; qué mecanismo falla hoy, medido; si lo resuelve algo
dentro de la base actual; qué debe hacer el dato durante un fallo; y quién lo opera y cuántas copias
habrá. La que más se salta es la tercera.

🗣️ **2 minutos** — La tercera parece conformista y evita más migraciones que ninguna: un índice, un
`jsonb`, una extensión como TimescaleDB o pgvector. La primera elige el modelo; la cuarta, CP o AP;
la quinta pone el coste que no sale en los folletos.

🔬 **El detalle** — Es la convención del curso, de `01` §6.

---

**07 → S4.** ¿Qué es el *hinted handoff*, y qué pasa si un nodo está caído más de tres horas? 🟡

⏱️ **30 segundos** — El nodo que acepta una escritura guarda una nota para cada réplica caída y se
la entrega cuando vuelve. La ventana por defecto es de tres horas; pasado ese tiempo no se guardan
notas, y el nodo necesita una reparación.

🗣️ **2 minutos** — En `01` §4, tras escribir en `ONE` con dos nodos caídos, la lectura en `ALL` un
minuto después de volver dio `ENVIADO` en las tres réplicas. Con más de tres horas, ese nodo
devolvería datos viejos hasta repararlo.

🔬 **El detalle** — **Motor**: `max_hint_window`. La reparación, además, tiene que hacerse antes de
`gc_grace_seconds`, o vuelven los zombis.

---

**07 → S5.** ¿Qué decide la clave de partición en Cassandra, y qué deciden las columnas de
clustering? 🟢

⏱️ **30 segundos** — La partición decide en qué nodos vive la fila, por el hash de su valor. El
clustering decide el orden de las filas dentro de la partición, guardado así en disco.

🗣️ **2 minutos** — Con `((pedido), ocurrido_en, tipo)`, los eventos de `PED-00042` viven juntos y
salen en orden. Solo se puede ordenar por el clustering, y no se puede pedir un rango sobre la
partición.

🔬 **El detalle** — **Motor**. El doble paréntesis es sintaxis de Cassandra.

---

**07 → S6.** «Una consulta nueva es una tabla nueva». Explícalo con los eventos de los pedidos. 🟡

⏱️ **30 segundos** — «Los eventos de un pedido» necesita partición por pedido; «lo de hoy, lo último
primero» necesita partición por día con clustering descendente. Son dos tablas con los mismos datos,
y la aplicación escribe cada evento en las dos.

🗣️ **2 minutos** — `ORDER BY importe` falló en la primera tabla porque no está en el clustering, y
el rango de días falló en la segunda porque `dia` es la partición. Cada consulta que no estaba en la
lista es otra tabla o un `ALLOW FILTERING` que recorre el clúster.

🔬 **El detalle** — **Convención** de diseño, la de `07/06`. Las vistas materializadas lo harían por
la aplicación, pero `cassandra.yaml` las trae apagadas como experimentales.

---

**07 → S7.** PostgreSQL cargó los eventos más de seis veces más rápido que Cassandra. ¿Qué argumento
a favor de Cassandra sobrevive? 🟠

⏱️ **30 segundos** — Que la capacidad de escritura crece añadiendo nodos, porque no hay primario y
cada nodo recibe solo las particiones de su tramo; y que el árbol LSM escribe sin leer la página,
lo que importa cuando el índice ya no cabe en memoria.

🗣️ **2 minutos** — 1,22 s frente a 8,04 en un nodo y un portátil, y la carga de Cassandra pasó por
`cqlsh`. El escalado no se midió en el entorno: se dice como mecanismo, sin cifra inventada.

🔬 **El detalle** — Lo que se evalúa es no esconder el número desfavorable.

---

**07 → S8.** ¿Por qué un `INSERT` en Cassandra puede perder datos sin dar error, y qué cuesta
evitarlo? 🟠

⏱️ **30 segundos** — Porque `INSERT` y `UPDATE` son lo mismo: con una clave que ya existe,
sobrescribe sin error. Evitarlo con `IF NOT EXISTS` cuesta casi el triple, porque usa Paxos.

🗣️ **2 minutos** — En la sesión, un `INSERT` cambió el evento `PAGADO` de `web` y 3 186,23 a `movil`
y 1,00 sin avisar. Mil escrituras con condición tardaron 1,56 ms cada una frente a 0,54. Antes que
la condición, una clave que haga imposible la colisión.

🔬 **El detalle** — **Motor**. La documentación lo dice así: a diferencia de SQL, `INSERT` no
comprueba si la fila existía.

---

**07 → S9.** ¿Por qué borrar en Cassandra no libera espacio, y por qué es mala idea montar una cola
encima? 🟠

⏱️ **30 segundos** — Porque un `DELETE` escribe una tombstone que dura al menos `gc_grace_seconds`,
diez días, para que llegue a las réplicas caídas. Una cola inserta y borra sin parar, y cada lectura
recorre las marcas de las tareas ya hechas.

🗣️ **2 minutos** — Tras borrar y compactar, el espacio siguió en 9 388 929 bytes, y la lectura contó
una tombstone por consulta. En una cola serían miles. Para colas, los *streams* de Redis o una cola
de verdad.

🔬 **El detalle** — **Motor**. Si la marca desapareciera antes, una réplica atrasada devolvería el
dato borrado: el zombi.

---

**07 → S10.** ¿En qué tipo de recorrido gana una base de grafos y en cuál no, con las cifras del
bloque? 🟠

⏱️ **30 segundos** — Gana con profundidad variable: el camino más corto tardó 25 ms en Neo4j y 3,7 s
con la CTE directa, y 2 ms frente a 24,6 s cuando no había camino. No gana con profundidad fija: la
recomendación tardó 143 ms en PostgreSQL y 305 en Neo4j.

🗣️ **2 minutos** — Con profundidad fija, el planificador ve todos los saltos y elige cómo unirlos
con índices. Con profundidad variable, la CTE enumera caminos: 25,9 millones de filas para quedarse
con 49 055.

🔬 **El detalle** — Las preguntas de fraude y de grados de separación son de profundidad variable; la
mayoría de las de negocio, no.

---

**07 → S11.** ¿Qué hace `shortestPath` para tardar 25 ms, y por qué supo en 2 ms que no había
camino? 🟡

⏱️ **30 segundos** — Busca en anchura desde los dos extremos y para cuando se encuentran. Hasta
`CLI-00007`, que no tiene relaciones, la frontera del destino estaba vacía desde el primer paso.

🗣️ **2 minutos** — La CTE busca desde un solo lado: para saber que no hay camino, enumera todos los
caminos hasta el tope, y tardó 24,6 s. En fraude, el caso normal es que no haya camino.

🔬 **El detalle** — **Motor**, según la documentación de Cypher.

---

**07 → S12.** ¿Cuándo puede parar antes una CTE recursiva, y por qué no conviene contar con ello? 🔴

⏱️ **30 segundos** — Cuando usa `UNION ALL` y la consulta de fuera deja de pedir filas, como con
`LIMIT 1`: PostgreSQL evalúa la CTE solo hasta donde se le pide. La que arrastraba el camino
encontró el destino en 75 ms.

🗣️ **2 minutos** — La documentación lo desaconseja como truco en producción: otros sistemas pueden
no hacerlo, y deja de funcionar si la consulta de fuera ordena o une el resultado. Y no ayuda cuando
no hay camino: la misma CTE tardó 24,6 s en devolver cero filas.

🔬 **El detalle** — Lo que se evalúa es conocer la evaluación perezosa y sus límites, no negarla.

---

**07 → S13.** ¿Qué es un supernodo, y qué hizo el de la tienda con la pregunta de «clientes
conectados»? 🟡

⏱️ **30 segundos** — Un nodo con muchas más relaciones que el resto. `PRD-00017` tiene 2 528
compradores, con una media de 69 por producto, y deja a los 43 251 demás clientes a dos productos
de `CLI-00311`.

🗣️ **2 minutos** — Si todo conecta con todo, la conexión no dice nada. Se excluye del recorrido, se
pondera por rareza o se limita la profundidad.

🔬 **El detalle** — **Convención** de modelado. En fraude, el teléfono de atención al cliente es el
supernodo típico.

---

**07 → S14.** ¿Qué gana una hipertabla sobre una tabla normal con índice, y en qué empata? 🟠

⏱️ **30 segundos** — Empata en la consulta reciente: 2,8 ms frente a 4,0. Gana en compresión, de 386
a 57 MB; en agregados, el año en 1,3 ms con un agregado continuo; y en retención, 52 tramos borrados
en 32 ms.

🗣️ **2 minutos** — Y pierde en la carga, 8,8 s frente a 6,3 con los datos ordenados, y en espacio
antes de comprimir. Lo que la tabla normal no tiene es compresión en columnas ni agregados que se
refrescan por intervalos.

🔬 **El detalle** — **Motor**, de TimescaleDB sobre el particionado de PostgreSQL.

---

**07 → S15.** Un agregado continuo enseña un recuento viejo. ¿Por qué, y qué opciones hay? 🟡

⏱️ **30 segundos** — Porque solo contiene lo materializado en el último refresco, y desde la 2.13 la
agregación en tiempo real viene desactivada. En la sesión, 234 antes del refresco y 235 después.

🗣️ **2 minutos** — Opciones: refresco programado más frecuente para el intervalo reciente, o
`materialized_only = false`, que suma al vuelo lo pendiente a cambio de consultas más lentas.

🔬 **El detalle** — **Motor**. La decisión es cuánto retraso acepta el panel.

---

**07 → S16.** `drop_chunks` frente a `DELETE` para borrar por antigüedad: qué hace cada uno y qué se
midió. 🟡

⏱️ **30 segundos** — `drop_chunks` borra tramos enteros, como borrar tablas: 52 en 32 ms, y la
hipertabla bajó de 57 a 40 MB. `DELETE` marca filas muertas y escribe WAL: 1 496 342 filas en 411
ms, y la tabla siguió en 309 MB.

🗣️ **2 minutos** — `drop_chunks` solo borra tramos que caen del todo antes de la fecha: quedó un
evento del 28 de diciembre de 2023. El espacio del `DELETE` necesita `VACUUM` para reutilizarse.

🔬 **El detalle** — El particionado nativo consigue lo mismo borrando particiones, si alguien las
mantiene.

---

**07 → S17.** Da las cinco razones por las que `LIKE '%texto%'` no sirve como buscador. 🟢

⏱️ **30 segundos** — No encuentra sin tildes, no encuentra el singular del plural, no tolera
erratas, no ordena por relevancia, y con comodín a la izquierda ningún B-tree lo sirve.

🗣️ **2 minutos** — `LIKE '%camara%'` encontró 0 de 328, y el plan siguió en `Seq Scan` con un índice
sobre la columna. Todo porque compara caracteres, y un buscador tiene que comparar palabras.

🔬 **El detalle** — **Estándar** el `LIKE`; el plan es del motor.

---

**07 → S18.** ¿Por qué la búsqueda de texto de PostgreSQL arregló la tilde y no el singular? 🟠

⏱️ **30 segundos** — Porque el *stemmer* español dejó `camara` y `cámara` en la misma raíz, `cam`,
pero «auriculares» en `auricular` y «auricular» en `auricul`. Buscar el singular dio 0 de 95.

🗣️ **2 minutos** — OpenSearch, con `light_spanish`, dejó las dos formas en `auricular` y encontró
95. Se sabe porque se probó con las palabras del catálogo, no porque lo diga el folleto de ninguno.

🔬 **El detalle** — **Motor**: cada analizador tiene sus reglas y sus fallos.

---

**07 → S19.** ¿Qué se paga por tener el buscador en OpenSearch en vez de en PostgreSQL? 🟡

⏱️ **30 segundos** — Otra copia de los datos, sin transacción con la base, que se ve con retraso:
tras actualizar un producto, la búsqueda dio 0 hasta el refresco. Y otro sistema que operar.

🗣️ **2 minutos** — En una arquitectura real, el retraso es el de la sincronización, de segundos o
minutos, y un fallo de sincronización deja el buscador desfasado en silencio. Hay que poder
reconstruirlo entero.

🔬 **El detalle** — **Motor** el refresco; **convención** la reconstrucción.

---

**07 → S20.** ¿Qué es el *recall* de un índice vectorial, y cuánto dio el HNSW con los parámetros de
defecto? 🟢

⏱️ **30 segundos** — La fracción de los vecinos reales que devuelve la búsqueda aproximada. Con
100 000 vectores aleatorios y `ef_search` de 40, 0,325.

🗣️ **2 minutos** — Con `ef_search = 200`, 0,665. Con los embeddings reales de la tienda, todas las
distancias coincidieron con las exactas. Los aleatorios son el peor caso.

🔬 **El detalle** — Se mide contra la búsqueda exacta, sin índice, con datos reales.

---

**07 → S21.** HNSW o IVFFlat: qué elegirías para un catálogo que se reindexa cada noche, y por qué.
🟠

⏱️ **30 segundos** — Depende de cuánto dure la noche. IVFFlat se construyó en 0,8 s frente a los 41
del HNSW, pero para el mismo tiempo de consulta da peor *recall*. Si el HNSW cabe en la ventana,
HNSW.

🗣️ **2 minutos** — HNSW se puede construir incrementalmente, así que a menudo no hace falta
reindexar cada noche: basta con insertar. IVFFlat calcula sus centros con los datos del momento, y
si los datos cambian mucho conviene reconstruirlo.

🔬 **El detalle** — **Motor**, según el README de pgvector. Y la construcción en paralelo necesita
memoria compartida suficiente.

---

**07 → S22.** ¿Por qué una búsqueda vectorial con filtro puede devolver menos filas de las pedidas?
🔴

⏱️ **30 segundos** — Porque con un índice aproximado el filtro se aplica después de recorrer el
índice, y el HNSW solo trae `ef_search` candidatos. Si ninguno cumple el filtro, no devuelve nada.

🗣️ **2 minutos** — Diez productos de deporte parecidos a la pregunta de la música: 0 filas con 467
candidatos. Con `hnsw.iterative_scan = strict_order`, 10. Sin error ni aviso.

🔬 **El detalle** — **Motor**, desde pgvector 0.8.0. Qdrant documenta un HNSW que tiene en cuenta los
filtros.

---

**07 → S23.** ¿Por qué la búsqueda semántica de la tienda devolvió aspiradoras cuando se pedía
música? 🟠

⏱️ **30 segundos** — Porque el modelo, `nomic-embed-text`, está entrenado sobre todo en inglés, y en
español lo que acercó la aspiradora fue compartir «sin cable». La base devolvió bien los vectores
más cercanos; el fallo fue de «parecido».

🗣️ **2 minutos** — La pregunta quedó a 0,302 de la aspiradora y a 0,468 de los auriculares, y para
«hacer ejercicio en casa» salieron sartenes. Qdrant, con los mismos vectores, dio lo mismo.

🔬 **El detalle** — El modelo se evalúa antes de elegir motor.

---

**07 → S24.** «Cassandra es AP, así que nunca es consistente». Refútalo con la sesión. 🟠

⏱️ **30 segundos** — AP es su comportamiento por defecto. Con `QUORUM` en escritura y lectura
garantiza leer lo último, y en la sesión rechazó una escritura en `QUORUM` con un solo nodo vivo.

🗣️ **2 minutos** — Con tres réplicas, dos que escriben y dos que leen comparten al menos una. Se
paga con disponibilidad: con dos nodos caídos, ni se escribe ni se lee.

🔬 **El detalle** — **Motor**: su documentación dice que compromete la consistencia «en cierta
medida», no siempre.

---

**07 → S25.** «Con una base vectorial, el buscador entenderá lo que quiere el cliente». ¿Qué parte
es cierta? 🟠

⏱️ **30 segundos** — Es cierto que buscará por cercanía de vectores y no por palabras. Lo que el
cliente «quiere decir» lo decide el modelo, no la base: con un modelo inglés, en español, devolvió
aspiradoras para la música.

🗣️ **2 minutos** — Además, el índice es aproximado y el filtro puede vaciar el resultado. Una base
vectorial es necesaria para buscar por significado a escala, pero no suficiente.

🔬 **El detalle** — Lo que se evalúa es separar el modelo del motor.

---

**07 → S26.** «Una base de grafos es más rápida con cualquier dato que tenga relaciones». Refútalo
con números. 🔴

⏱️ **30 segundos** — La recomendación, un recorrido de profundidad fija, tardó 143 ms en PostgreSQL
y 305 en Neo4j. El grafo ganó solo con profundidad variable: 25 ms frente a 3,7 s, y 2 ms frente a
24,6 s sin camino.

🗣️ **2 minutos** — Todos los datos relacionales tienen relaciones, por eso se llaman así. Lo que
decide es si el número de saltos se conoce de antemano.

🔬 **El detalle** — Y con un supernodo, cualquier recorrido pierde sentido, sea cual sea el motor.

---

**07 → E1.** Escenario 1 — La telemetría del reparto

⏱️ **30 segundos** — Dos tablas: posiciones por pedido, con partición por pedido y clustering por
tiempo descendente, que tiene tope; y posiciones por zona, día y hora, con un cubo si la hora sigue
caliente. Escritura en `ONE` o `LOCAL_ONE`, porque una posición perdida se sustituye cinco segundos
después.

🗣️ **2 minutos** — Con dos nodos caídos se sigue escribiendo, y alguna lectura irá por detrás. Se
pierden `JOIN`, `ORDER BY` arbitrario, el error por clave repetida y el borrado inmediato: la
retención de un año se hace con TTL, que también deja tombstones. Antes, una hipertabla con tramos
de un día, comprimida y con `drop_chunks`, medida con la carga real de 20 000 escrituras por
segundo.

🔬 **El detalle** — Lo que se evalúa es diseñar por consulta y por crecimiento de partición, y
comparar con la opción que no saca los datos de PostgreSQL antes de decidir.

---

**07 → E2.** Escenario 2 — El anillo de fraude

⏱️ **30 segundos** — La CTE tarda distinto porque enumera caminos: una cuenta con pocos vínculos
termina enseguida, y una conectada a un supernodo multiplica los caminos en cada salto. Cuando no
hay camino, los recorre todos hasta el tope.

🗣️ **2 minutos** — Grafo con `:Cliente`, `:Tarjeta`, `:Telefono` y `:Direccion`, restricciones de
unicidad y la etiqueta `:Bloqueado`; la consulta, el camino más corto de la cuenta nueva a cualquier
bloqueada, que en el bloque respondió en 2 ms cuando no había camino. Supernodos: teléfono de
atención, direcciones de recogida, tarjetas de prueba, que se excluyen. El grafo se alimenta de la
base por eventos, y su retraso es la ventana de riesgo.

🔬 **El detalle** — Lo que se evalúa es explicar la varianza por la explosión de caminos y no
prometer que el grafo lo arregla todo: los supernodos lo rompen igual.

---

**07 → E3.** Escenario 3 — El buscador que no encuentra

⏱️ **30 segundos** — OpenSearch resuelve tildes, singular, erratas y orden: 328, 95 y 95 en el
bloque. La búsqueda semántica no resuelve las erratas ni garantiza el orden, y con un modelo que no
sabe el idioma devolvió aspiradoras para la música.

🗣️ **2 minutos** — Primero, PostgreSQL: `tsvector` con GIN, `unaccent`, `pg_trgm` para erratas y
`ts_rank`, probado con las palabras del catálogo, porque el *stemmer* falló con el singular.
OpenSearch cuando el volumen, las facetas o la relevancia afinada lo pidan, pagando una copia con
retraso. La semántica, solo tras medir el modelo con preguntas reales en español.

🔬 **El detalle** — Lo que se evalúa es no elegir entre dos tecnologías de moda, sino medir cuál de
las quejas resuelve cada una.

---

**07 → E4.** Escenario 4 — «El panel va lento: pongamos una base de series temporales»

⏱️ **30 segundos** — No lo resuelve cambiar de base. El panel recalcula un año de pedidos en cada
consulta; lo que lo arregla es no recalcularlo: una vista materializada o una tabla de resumen por
hora, refrescada en segundo plano.

🗣️ **2 minutos** — Primero el plan: cuántas filas lee, si usa un índice por fecha. Después, el
resumen: en el bloque, un agregado materializado contestó el año en 1,3 ms frente a 60. TimescaleDB,
que es una extensión y no otra base, aportaría el refresco por intervalos y la compresión si el
volumen crece. Una base aparte perdería los `JOIN` con clientes y productos.

🔬 **El detalle** — Lo que se evalúa es no aceptar el marco: la lentitud viene de recalcular, no de
la forma temporal de los datos.

---

**Volver:** [README del bloque](README.md).
