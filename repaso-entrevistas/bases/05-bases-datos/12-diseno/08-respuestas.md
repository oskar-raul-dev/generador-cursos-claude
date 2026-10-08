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

- [Capítulo 01 — Elegir motor](#capítulo-01--elegir-motor)
- [Capítulo 02 — Identidad y claves](#capítulo-02--identidad-y-claves)
- [Capítulo 03 — Fechas, zonas y dinero](#capítulo-03--fechas-zonas-y-dinero)
- [Capítulo 04 — Borrado lógico, auditoría e
  historial](#capítulo-04--borrado-lógico-auditoría-e-historial)
- [Capítulo 05 — Multi-inquilino](#capítulo-05--multi-inquilino)
- [Capítulo 06 — Paginación y búsqueda de texto](#capítulo-06--paginación-y-búsqueda-de-texto)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — Elegir motor

Las 18 preguntas de [`01`](01-elegir-motor.md).

**01 → 1.** ¿Cuál es el punto de partida del curso para elegir motor, y por qué? 🟢

⏱️ **30 segundos** — Empezar con una base relacional, PostgreSQL, y añadir otro motor solo cuando
una forma de acceso concreta lo pide, medido.

🗣️ **2 minutos** — Porque el relacional contesta consultas que nadie previó con un índice más, trae
tipos comprobados, transacciones y claves foráneas, y ya resuelve dentro documentos, series, texto y
vectores. Cassandra pide una tabla por consulta y DynamoDB un índice declarado.

🔬 **El detalle** — Es **convención**, con razones medibles; no es un estándar.

---

**01 → 2.** ¿Cuáles son las cinco preguntas del árbol de la decisión? 🟢

⏱️ **30 segundos** — Cómo se lee el dato; qué mecanismo falla hoy, medido; si lo resuelve algo
dentro de la base actual; qué debe hacer el dato durante un fallo; y quién lo opera y cuántas copias
habrá.

🗣️ **2 minutos** — Saltarse cada una tiene precio: un motor que no contesta la consulta del mes
siguiente, una migración para lo que resolvía un índice, un dato mal leído en producción, un sistema
que nadie sabe restaurar.

🔬 **El detalle** — Son las de `09/01` §6, en el orden en que se contestan en una entrevista.

---

**01 → 3.** ¿Qué modelos del bloque 09 se resuelven dentro de PostgreSQL? 🟢

⏱️ **30 segundos** — Series temporales con TimescaleDB, vectores con pgvector y texto con
`tsvector`.

🗣️ **2 minutos** — Las dos primeras son extensiones; `tsvector` viene de serie. Tres de las nueve
filas de la tabla de §4 no obligan a salir de PostgreSQL.

🔬 **El detalle** — A eso se suman los documentos con `jsonb` e índice GIN, de `08/05`.

---

**01 → 4.** ¿Por qué la primera pregunta es cómo se lee el dato, y no cuánto dato hay? 🟡

⏱️ **30 segundos** — Porque cada motor escala una forma de acceso y ninguna otra. El volumen solo
dice que hay que escalar; la forma de acceso dice qué modelo lo hace bien.

🗣️ **2 minutos** — Con mucho volumen leído de muchas formas, el modelo sigue siendo relacional. El
contador caliente no se arregló por volumen, sino por su forma: muchas escrituras sobre el mismo
valor.

🔬 **El detalle** — «De muchas formas, algunas aún desconocidas» es la respuesta que elige el
relacional.

---

**01 → 5.** ¿Qué se pierde al pasar el pedido de la tienda a MongoDB, con las cifras del curso? 🟡

⏱️ **30 segundos** — Se gana leer el pedido entero como un documento de 379 bytes, frente a 0,115 ms
con `JOIN`, que ya era rápido; se pierde el panel que une entidades: 472 ms con `$lookup` frente a
28 ms con `JOIN`.

🗣️ **2 minutos** — Y los tipos: MongoDB aceptó un total como texto que PostgreSQL rechazó. Las
partes del documento tampoco se consultan solas con la misma comodidad.

🔬 **El detalle** — Las cifras son de `08/01` y `08/05`, medidas en cada **motor**.

---

**01 → 6.** ¿En qué forma de acceso gana Neo4j y en cuál pierde, con números? 🟡

⏱️ **30 segundos** — Gana en profundidad variable: camino más corto en 25 ms y «no hay camino» en 2
ms, frente a 3,7 s y 24,6 s de la CTE recursiva. Pierde en profundidad fija: la recomendación, 305
ms frente a 143.

🗣️ **2 minutos** — Con profundidad fija, el `JOIN` con índices hace lo mismo que el recorrido. La
ventaja aparece cuando la profundidad no se conoce y la CTE explora todo.

🔬 **El detalle** — Y paga otra copia y los supernodos, de `09/03`.

---

**01 → 7.** ¿Qué significa que «la columna del precio nunca está vacía»? 🟡

⏱️ **30 segundos** — Que todo motor especializado que gana en su forma de acceso cobra algo por
ello: RAM, tipos sin comprobar, una tabla por consulta, otra copia con retraso.

🗣️ **2 minutos** — Las únicas filas con raya en el precio son aquellas en que el especializado ni
siquiera gana: el `$lookup` y la recomendación de Neo4j. Ahí no hay nada que pagar porque no hay
nada que comprar.

🔬 **El detalle** — Es la lectura por columnas de la tabla de §4.

---

**01 → 8.** ¿Qué cuestan las operaciones de un motor más, según el bloque 06? 🟡

⏱️ **30 segundos** — Otra copia con retraso, otro respaldo con su restauración de prueba, otro
sistema de permisos, otra forma de migrar el esquema y otra guardia.

🗣️ **2 minutos** — Cada uno se multiplica por motor: diez motores, diez respaldos que nadie ha
restaurado y diez sistemas de permisos distintos. El buscador enseñó un cambio un segundo tarde.

🔬 **El detalle** — Es **convención** de arquitectura: ningún capítulo lo cronometró.

---

**01 → 9.** ¿Por qué el paso 3 va antes que el paso 5? 🟠

⏱️ **30 segundos** — Porque si algo dentro de la base actual lo resuelve, no hay copia nueva que
operar, y el paso 5 no llega a hacer falta.

🗣️ **2 minutos** — Un índice, un `jsonb`, una extensión o una réplica de lectura no añaden respaldo,
permisos ni guardia. El paso 5 es el precio de fallar el 3, y conviene saberlo antes de pagarlo.

🔬 **El detalle** — El orden es la manera de no pagar el coste de §5 sin necesidad.

---

**01 → 10.** ¿Por qué el contador de visitas no pidió Redis como primera respuesta? 🟠

⏱️ **30 segundos** — Porque el paso 3 lo resolvió: acumular en la aplicación y volcar cada segundo
con un solo `UPDATE` quita casi toda la presión sobre la fila caliente.

🗣️ **2 minutos** — El mecanismo que fallaba era el bloqueo de una fila, 4 373 escrituras por
segundo. Redis sirve 121 080, pero añade RAM, un motor más y la pérdida del último segundo. Entra si
además hacen falta límites de uso o sesiones compartidas.

🔬 **El detalle** — El contador tolera perder un segundo, así que acumular es aceptable.

---

**01 → 11.** ¿Cuándo no vale el punto de partida relacional? 🟠

⏱️ **30 segundos** — Cuando la escala o la forma de acceso ya se conocen y no caben, como veinte mil
escrituras por segundo repartidas entre regiones, o cuando el ecosistema manda.

🗣️ **2 minutos** — Un servicio gestionado sin servidor que solo ofrece DynamoDB es el caso típico:
se diseña desde el acceso, como en `07/06`, en vez de pelear contra la plataforma.

🔬 **El detalle** — El punto de partida es **convención**, y como tal tiene excepciones razonadas.

---

**01 → 12.** ¿Por qué «microservicios» no implica un motor distinto por servicio? 🟠

⏱️ **30 segundos** — Porque cada servicio necesita su propia base, no un motor distinto. El motor lo
decide su forma de acceso.

🗣️ **2 minutos** — Diez servicios sobre diez motores son diez respaldos, diez sistemas de permisos y
diez guardias. Diez bases PostgreSQL separadas dan la misma independencia con una sola forma de
operar.

🔬 **El detalle** — Es la convención que más se repite, y la que el capítulo desmonta.

---

**01 → 13.** Un compañero propone Cassandra para el historial de estados de los pedidos de la
tienda. ¿Qué le preguntas antes de opinar? 🟠

⏱️ **30 segundos** — Qué mecanismo falla hoy, medido, en PostgreSQL. Con 4,1 millones de eventos no
falla nada.

🗣️ **2 minutos** — Después, cómo se lee: por pedido en orden lo resuelve un índice por pedido y
fecha, y partición por mes. Qué consultas vendrán: Cassandra pide una tabla por consulta. Y si el
volumen es de telemetría: `COPY` cargó 409 998 eventos en 1,22 s y Cassandra, en un nodo, en 8,04.

🔬 **El detalle** — La pregunta es la del paso 2: sin mecanismo nombrado no hay caso.

---

**01 → 14.** ¿Qué paso del árbol decide entre CP y AP, y con qué ejemplo de la tienda? 🟠

⏱️ **30 segundos** — El paso 4: qué debe hacer el dato durante un fallo. Un saldo no se lee viejo;
un contador de visitas sí.

🗣️ **2 minutos** — El contador tolera perder un segundo, y por eso acepta acumular o Redis. La
detección de fraude puede esperar unos segundos a que el grafo se sincronice. Un pago no admite
ninguna de las dos.

🔬 **El detalle** — Se elige por operación, con el nivel de consistencia de cada una, no por motor
entero.

---

**01 → 15.** Diseña la arquitectura de datos de una tienda con buscador, recomendaciones y panel de
ventas, diciendo qué motor atiende cada forma de acceso y por qué. 🔴

⏱️ **30 segundos** — PostgreSQL como fuente de verdad para pedidos, catálogo y panel; el buscador
con `tsvector` mientras baste; las recomendaciones con `JOIN`, que ganó la profundidad fija.

🗣️ **2 minutos** — El panel de ventas une entidades: `JOIN`, 28 ms. Las recomendaciones de
profundidad fija: 143 ms frente a 305 de Neo4j. El buscador pasa a OpenSearch cuando pidan erratas,
plurales o volumen, como copia que se reconstruye. Si el panel agrega años, TimescaleDB o una vista
materializada.

🔬 **El detalle** — Cada motor más se justifica por el paso 2 y se paga en el paso 5; decirlo en la
respuesta es lo que se evalúa.

---

**01 → 16.** Diagnostica: un equipo migró el catálogo a MongoDB y el informe mensual de ventas por
categoría pasó de segundos a minutos. 🔴

⏱️ **30 segundos** — El informe une entidades —ventas, productos, categorías—, que es la forma de
acceso en la que el documental pierde. El `$lookup` tardó 472 ms frente a 28 del `JOIN`.

🗣️ **2 minutos** — Lo confirmaría con el plan de la agregación. Salidas: desnormalizar la categoría
en cada venta, pagando su actualización; alimentar un almacén analítico; o volver a `jsonb` en
PostgreSQL para la ficha, que era lo que pedía el catálogo.

🔬 **El detalle** — Se eligió el motor por la ficha y se ignoró el informe: el paso 1 se contestó con
una sola forma de acceso.

---

**01 → 17.** Defiende en dos minutos que la tienda no necesita ningún motor aparte de PostgreSQL
hoy, y di qué cifra te haría cambiar de opinión para cada modelo. 🔴

⏱️ **30 segundos** — Hoy nada falla: el contador se arregla acumulando, la ficha va en `jsonb`, el
historial con índice y partición, la búsqueda con `tsvector`.

🗣️ **2 minutos** — Cambiaría con: escrituras sobre la misma clave por encima de lo que el volcado
por segundo absorbe, Redis; consultas de profundidad variable en segundos, como los 24,6 s, Neo4j;
búsquedas que exigen erratas y plurales, el 0 de 95, OpenSearch; paneles de años que ya no bajan de
91 ms con índices, TimescaleDB.

🔬 **El detalle** — Cada umbral es una cifra del curso, no una sensación.

---

**01 → 18.** Defiende o refuta «elegir PostgreSQL es la decisión aburrida y segura, sin más», con lo
que enseña el capítulo. 🔴

⏱️ **30 segundos** — Se matiza: es segura, pero no «sin más». Es no pagar por adelantado el precio
de un modelo que aún no se necesita, y tiene límites medidos.

🗣️ **2 minutos** — Pierde donde el especializado gana: 4 373 escrituras frente a 121 080, 24,6 s
frente a 2 ms. Elegirla bien es saber en qué cifra deja de valer y tener el siguiente paso pensado.

🔬 **El detalle** — El punto de partida es **convención** razonada, no una ley.

---

## Capítulo 02 — Identidad y claves

Las 18 preguntas de [`02`](02-identidad-y-claves.md).

**02 → 1.** ¿Qué diferencia una clave natural de una sustituta? 🟢

⏱️ **30 segundos** — La natural es un dato del negocio que ya identifica la fila, como el correo o
el código; la sustituta es un valor sin significado que genera la base, un entero o un UUID.

🗣️ **2 minutos** — La natural se entiende sola y evita duplicados de negocio, pero puede cambiar. La
sustituta no cambia nunca, pero no evita duplicados por sí misma.

🔬 **El detalle** — El **estándar** define la clave primaria; qué se elige es **convención**.

---

**02 → 2.** ¿Qué hace `ON UPDATE CASCADE`? 🟢

⏱️ **30 segundos** — Que al cambiar la clave referenciada se cambie también en cada fila que la
referencia.

🗣️ **2 minutos** — Cambiar el correo de `CLI-00311` en `clientes_nat` reescribió sus 52 pedidos. Sin
él, el `UPDATE` fallaría por la clave foránea.

🔬 **El detalle** — Es **estándar**; su alcance acaba en las claves foráneas de esta base.

---

**02 → 3.** ¿Qué es la deduplicación de un índice B-tree? 🟢

⏱️ **30 segundos** — Que PostgreSQL junta las entradas con el mismo valor en una lista, en vez de
repetir el valor por cada fila.

🗣️ **2 minutos** — Cada cliente aparece en veinte pedidos, y su correo se guarda casi una sola vez.
Por eso el índice sobre el correo ocupó 9 152 kB frente a 7 800 del `bigint`.

🔬 **El detalle** — Es del **motor**, descrita en la documentación del B-tree.

---

**02 → 4.** ¿Qué devuelve `uuid_extract_timestamp` para un UUIDv4, y por qué? 🟢

⏱️ **30 segundos** — Nulo, porque el v4 es aleatorio y no lleva marca de tiempo.

🗣️ **2 minutos** — La función saca la fecha de los UUID de versión 1 y 7; con un v7 devolvió el
instante de creación, al milisegundo.

🔬 **El detalle** — La documentación lo dice así; la sesión lo confirmó con el v4.

---

**02 → 5.** ¿Por qué una clave sustituta necesita además un `UNIQUE` sobre el dato natural? 🟡

⏱️ **30 segundos** — Porque la sustituta identifica filas, no clientes. Sin `UNIQUE` sobre el
correo, dos filas con el mismo correo son dos clientes distintos para la base.

🗣️ **2 minutos** — La tienda lo hace: `id bigint` como clave primaria y `codigo` con `UNIQUE`. El
`UNIQUE` además deja cambiar el dato sin tocar ninguna clave foránea.

🔬 **El detalle** — Es la trampa de la sustituta sola.

---

**02 → 6.** ¿Por qué el índice sobre el correo ocupó solo un 17 % más que el del `bigint`? ¿Lo fija
el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — Por la deduplicación: cada correo se repite en unos veinte pedidos y el índice
lo guarda casi una vez.

🗣️ **2 minutos** — Un correo mide unas tres veces lo que un entero, así que sin deduplicación la
diferencia sería mucho mayor. Con valores únicos, como la clave primaria de `clientes_nat`, no hay
nada que juntar.

🔬 **El detalle** — 9 152 kB frente a 7 800, en el **motor** PostgreSQL 18.

---

**02 → 7.** ¿Qué información revela un entero consecutivo en una URL? 🟡

⏱️ **30 segundos** — Cuántos hay y cuántos se crean: con el pedido de hoy y el de la semana pasada,
la resta es el volumen de ventas.

🗣️ **2 minutos** — Y deja probar el siguiente, `PED-00043`, que es la puerta al acceso directo a
objetos ajenos si la aplicación no comprueba la propiedad.

🔬 **El detalle** — Lo ve cualquiera que reciba la respuesta.

---

**02 → 8.** ¿Qué dice la RFC 9562 sobre usar un UUID como control de acceso? 🟡

⏱️ **30 segundos** — Que no hay que suponer que un UUID es difícil de adivinar y que no debe usarse
como credencial cuya mera posesión da acceso.

🗣️ **2 minutos** — Un v4 no se adivina, pero se filtra: en un enlace, un registro, una captura. Si
la aplicación no comprueba de quién es, el identificador filtrado abre la puerta.

🔬 **El detalle** — Está en las consideraciones de seguridad de la RFC, que es **estándar**.

---

**02 → 9.** ¿Qué gana la tienda con tener `id` y `codigo` a la vez? 🟡

⏱️ **30 segundos** — Una clave primaria estrecha que nunca cambia para las claves foráneas, y una
clave natural legible y única para el negocio.

🗣️ **2 minutos** — Si el formato del código cambia, se actualiza una columna con `UNIQUE` sin tocar
el millón de pedidos que referencian `cliente_id`. Y el código puede ser el identificador público.

🔬 **El detalle** — Es la decisión de §6: sustituta para la base, natural en un `UNIQUE`.

---

**02 → 10.** ¿Por qué cambiar el correo con la clave natural tardó casi el doble, y qué más bloqueó?
🟠

⏱️ **30 segundos** — Porque la cascada reescribió los 52 pedidos de `CLI-00311`: 1,96 ms frente a
1,07 con la clave sustituta, que toca una fila.

🗣️ **2 minutos** — Esos 52 pedidos quedaron bloqueados hasta el final de la transacción. Con un
cliente de miles de pedidos, el bloqueo y la escritura crecen con él.

🔬 **El detalle** — En milisegundos no es caro; lo caro está fuera de la base.

---

**02 → 11.** ¿Qué parte del coste de una clave natural no se puede medir dentro de la base? 🟠

⏱️ **30 segundos** — Todas las copias del valor viejo fuera de la base: registros, cachés, eventos
publicados, otros servicios, facturas emitidas.

🗣️ **2 minutos** — La cascada llega hasta donde llegan las claves foráneas de esta base. Un servicio
que guardó el correo como referencia se queda apuntando a un cliente que ya no existe con ese
nombre.

🔬 **El detalle** — Por eso la natural va en un `UNIQUE` y la primaria es sustituta.

---

**02 → 12.** ¿Por qué un UUIDv7 en la API puede ser un problema, si es único y no se adivina? 🟠

⏱️ **30 segundos** — Porque lleva la fecha dentro: `uuid_extract_timestamp` la devolvió, y
cualquiera puede extraerla en cualquier lenguaje.

🗣️ **2 minutos** — Revela la fecha de alta de un cliente o la hora de un pedido. Si eso es sensible,
el identificador público debe ser un v4 o un código propio.

🔬 **El detalle** — La marca de tiempo es la que le da el índice ordenado; es el precio.

---

**02 → 13.** ¿Por qué pasar a UUID en la URL no arregla el acceso a pedidos ajenos? 🟠

⏱️ **30 segundos** — Porque esconde el fallo, no lo arregla: el fallo es no comprobar que el pedido
es de quien lo pide.

🗣️ **2 minutos** — El UUID impide adivinar el siguiente, pero el que se filtre abre igual. La RFC
9562 prohíbe usarlo como credencial. Lo que lo arregla es comprobar la propiedad en cada petición.

🔬 **El detalle** — El identificador nunca decide quién puede ver qué.

---

**02 → 14.** ¿Cuándo elegirías UUIDv7 como clave primaria, y cuándo solo como identificador público?
🟠

⏱️ **30 segundos** — Como clave primaria, cuando la clave debe existir antes de llegar a la base: un
móvil sin conexión, varios servicios generando. Como público, si se acepta que revele la fecha.

🗣️ **2 minutos** — En el índice paga el ancho, no el desorden: 30 MB y 90 % de hojas llenas frente a
21 MB del `bigint`. Si nada exige generarla fuera, `bigint` con `IDENTITY` es más barato.

🔬 **El detalle** — Si la fecha es sensible, el público debe ser v4.

---

**02 → 15.** ¿Qué cuesta cambiar de `bigint` a UUID en una tabla que ya tiene claves foráneas? 🟠

⏱️ **30 segundos** — Reescribir la tabla y todas las que la referencian, porque la clave primaria
está en cada clave foránea que la apunta.

🗣️ **2 minutos** — Se hace con expandir y contraer: columna nueva, rellenado por lotes, claves
foráneas nuevas, cambio de lecturas y retirada de la vieja. Cada paso es un despliegue.

🔬 **El detalle** — Por eso la decisión se toma al principio, con los números de `05/03`.

---

**02 → 16.** Diseña las claves de `clientes` y `pedidos` para una API pública en la que los clientes
consultan sus pedidos. 🔴

⏱️ **30 segundos** — `id bigint GENERATED ALWAYS AS IDENTITY` como primaria interna, el correo y el
código en `UNIQUE`, y un identificador público aparte —UUIDv4 o código sin secuencia visible—.

🗣️ **2 minutos** — Las claves foráneas usan el `bigint`. La URL lleva el público. Cada petición
comprueba que el pedido pertenece al cliente autenticado. Así cambiar el correo toca una fila y la
URL no revela ni volumen ni fechas.

🔬 **El detalle** — Cuesta una columna y un índice más, a cambio de poder renumerar sin romper URLs.

---

**02 → 17.** Diagnostica: un cliente denuncia que, cambiando un número en la URL de su pedido, ve
los pedidos de otros. El equipo propone pasar a UUID. 🔴

⏱️ **30 segundos** — Es acceso directo a objetos ajenos: la API no comprueba la propiedad. El UUID
lo esconde, no lo arregla.

🗣️ **2 minutos** — Corrección inmediata: filtrar cada consulta por el cliente autenticado y devolver
404 si no es suyo. Después, si se quiere, un identificador público que no revele el volumen. Y
revisar los registros para saber qué se vio.

🔬 **El detalle** — La RFC 9562 prohíbe tratar el UUID como credencial.

---

**02 → 18.** Defiende o refuta usar el correo como clave primaria de `clientes`, con los números del
capítulo. 🔴

⏱️ **30 segundos** — Se refuta, pero no por el tamaño: el índice ocupó 9 152 kB frente a 7 800, y la
cascada cambió 52 pedidos en 1,96 ms.

🗣️ **2 minutos** — El problema es que el correo sale de la base —registros, eventos, otros
servicios, facturas— y no vuelve cuando cambia. Va en un `UNIQUE`, y la primaria es un `bigint`.

🔬 **El detalle** — Quien refuta por el tamaño del índice se equivoca con los números.

---

## Capítulo 03 — Fechas, zonas y dinero

Las 18 preguntas de [`03`](03-fechas-zonas-y-dinero.md).

**03 → 1.** ¿Qué columna usarías para cuándo se creó un pedido, y por qué? 🟢

⏱️ **30 segundos** — `timestamptz`, porque es un instante que ya pasó: se guarda el instante y se
enseña en la zona de quien lo mira.

🗣️ **2 minutos** — El mismo pedido es a las 12:00 en Madrid y a las 5:00 en Bogotá, y los dos tienen
razón. Lo que no puede cambiar es el instante, y ese es el que guarda la columna.

🔬 **El detalle** — En MySQL, el equivalente es `TIMESTAMP`, no `DATETIME`.

---

**03 → 2.** ¿Qué diferencia `timestamptz` de `timestamp` en PostgreSQL? 🟢

⏱️ **30 segundos** — `timestamptz` guarda un instante y lo enseña en la zona de la sesión;
`timestamp` guarda una fecha y hora de reloj de pared, sin zona.

🗣️ **2 minutos** — El primero sirve para lo que ya ocurrió; el segundo, junto con una columna de
zona, para una hora local futura, como la recogida del sábado a las 10:00 en Madrid.

🔬 **El detalle** — Los nombres engañan: `timestamptz` no guarda la zona, guarda el instante.

---

**03 → 3.** ¿Por qué el dinero no se guarda en coma flotante? 🟢

⏱️ **30 segundos** — Porque la coma flotante no representa exactamente la mayoría de decimales: 0,1
más 0,2 dio 0.30000000000000004.

🗣️ **2 minutos** — Sobre el millón de totales, la suma en `float8` se desvió 0,00036 de la exacta.
`numeric` en PostgreSQL y `DECIMAL` en MySQL suman exacto.

🔬 **El detalle** — El numérico exacto es **estándar**; no usar flotante es **convención**.

---

**03 → 4.** ¿Cómo guarda SQLite las fechas? 🟢

⏱️ **30 segundos** — Como texto, o como números si se decide así: no tiene tipo de fecha. `date()`
devolvió una cadena, de tipo `text`.

🗣️ **2 minutos** — Se guardan en formato ISO, que se ordena bien como texto, y las zonas son cosa de
la aplicación.

🔬 **El detalle** — Es del **motor**: SQLite no tiene tipos de fecha ni de dinero.

---

**03 → 5.** ¿Qué columna usarías para el último día de validez de un cupón, y qué pasa si usas un
instante? 🟡

⏱️ **30 segundos** — `date`: un día, sin hora ni zona que interpretar.

🗣️ **2 minutos** — Si se guarda «caduca el 31» como `timestamptz` a medianoche de una zona, en otra
zona se ve como el 30 a las 23:00, y el cupón caduca un día antes para esos clientes.

🔬 **El detalle** — El error del segundo caso horario es el contrario del tercero.

---

**03 → 6.** ¿Por qué `+ interval '1 day'` y `+ interval '24 hours'` dieron horas distintas? 🟡

⏱️ **30 segundos** — Porque el 30 de marzo de 2025 en Madrid tuvo 23 horas: un día llevó a las 12:00
y 24 horas, a las 13:00.

🗣️ **2 minutos** — Sumar un día respeta el calendario; sumar 24 horas cuenta segundos. Cuál es el
bueno lo decide el negocio: «mañana a la misma hora» es un día; «24 horas después del pago» son 24
horas.

🔬 **El detalle** — La documentación de PostgreSQL lo avisa con esas palabras.

---

**03 → 7.** ¿Qué hace PostgreSQL con una hora local que no existe? ¿Lo fija el estándar o es cosa
del motor? 🟡

⏱️ **30 segundos** — No da error: las 02:30 del 30 de marzo en Madrid, que no existieron, las
interpretó como las 03:30.

🗣️ **2 minutos** — Una cita puesta a esa hora se mueve sola, sin aviso. La aplicación que acepta
horas locales debería validarlas o avisar.

🔬 **El detalle** — Es comportamiento del **motor**.

---

**03 → 8.** Distingue `DATETIME` de `TIMESTAMP` en MySQL. 🟡

⏱️ **30 segundos** — `TIMESTAMP` convierte de la zona de la sesión a UTC al guardar y de vuelta al
leer; `DATETIME` guarda lo que se escribe.

🗣️ **2 minutos** — Insertado en UTC y leído en UTC−5, `DATETIME` devolvió `04:22` y `TIMESTAMP`,
`23:22` del día anterior. `TIMESTAMP` es el instante; `DATETIME`, el reloj de pared.

🔬 **El detalle** — Al revés de lo que sugiere el nombre para quien viene de PostgreSQL.

---

**03 → 9.** ¿Qué es la base de datos de zonas, y por qué importa que guarde la historia? 🟠

⏱️ **30 segundos** — La tabla de reglas horarias de cada ciudad —desfase y cambios de hora— que trae
cada sistema. Guarda la historia porque las reglas cambian.

🗣️ **2 minutos** — Por eso las mismas 10:00 en São Paulo son las 13:00 de Madrid en 2018 y las 14:00
en 2020. Se actualiza con el sistema cuando un gobierno cambia sus reglas.

🔬 **El detalle** — Es la que decide los resultados de §3 y §4; con una versión vieja, se equivocan.

---

**03 → 10.** ¿Por qué la misma cita en São Paulo cayó a una hora distinta en 2018 y en 2020? 🟠

⏱️ **30 segundos** — Porque en noviembre de 2018 São Paulo estaba en horario de verano, UTC−2, y en
2020 ya no existía, UTC−3: Brasil lo suprimió en 2019.

🗣️ **2 minutos** — Convertidas a instante con `AT TIME ZONE`, las mismas 10:00 locales dieron 13:00
y 14:00 en Madrid. La base de datos de zonas aplicó las reglas de cada año.

🔬 **El detalle** — Si la cita de 2020 se hubiera convertido en 2018, habría quedado desplazada.

---

**03 → 11.** ¿Por qué una hora local futura se guarda con su zona y no como instante? 🟠

⏱️ **30 segundos** — Porque convertirla a instante usa las reglas de hoy, y si la ciudad las cambia
antes de la fecha, el instante guardado deja de ser la hora local prometida.

🗣️ **2 minutos** — Se guarda `timestamp` más la zona, `'Europe/Madrid'`, y se convierte en el
momento de usarla. Lo que ya ocurrió sí se guarda como instante.

🔬 **El detalle** — Es la regla que desmonta «todo en UTC».

---

**03 → 12.** ¿Por qué la suma en coma flotante del millón de totales se desvió, y por qué importa si
al final se redondea? 🟠

⏱️ **30 segundos** — Porque cada total en `float8` es una aproximación y los errores se suman:
0,00036 sobre el millón.

🗣️ **2 minutos** — Redondeado a céntimos, este cuadra. Pero en un cálculo encadenado —impuestos
sobre descuentos sobre conversiones— las desviaciones se acumulan, y un redondeo en el borde da un
céntimo distinto.

🔬 **El detalle** — `numeric` no se desvía nunca; es la única forma de no tener que razonarlo.

---

**03 → 13.** ¿Por qué repartir 100,00 en tres dio 99,99, y cómo se reparte bien? ¿Qué parte es del
motor y qué parte es convención? 🟠

⏱️ **30 segundos** — Porque cada parte se redondea a 33,33 y tres de ellas suman 99,99. No es el
tipo: es el algoritmo.

🗣️ **2 minutos** — Se reparte dejando que la última parte lleve la diferencia: 33,33, 33,33 y 33,34.
Vale igual para plazos, líneas de pedido o cuentas.

🔬 **El detalle** — Es **convención**, y tiene que estar escrita en un solo sitio.

---

**03 → 14.** ¿Por qué el dinero necesita una columna de moneda? 🟠

⏱️ **30 segundos** — Porque un importe sin moneda es un número: sumar euros y pesos no da nada.

🗣️ **2 minutos** — Una columna con el código ISO al lado del importe, y ninguna suma entre monedas
distintas sin convertir. La escala también puede depender de la moneda.

🔬 **El detalle** — Es **convención** de diseño; ningún motor la impone.

---

**03 → 15.** ¿Por qué en SQLite se guardan céntimos enteros, si la suma de diez 0,1 salió exacta? 🟠

⏱️ **30 segundos** — Porque que esa suma saliera exacta es una observación, no una garantía: la suma
directa de 0,1 y 0,2 no dio 0,3.

🗣️ **2 minutos** — La documentación de `sum()` avisa de que con valores de magnitudes muy distintas
puede ser imprecisa y propone `decimal_sum`. Los céntimos enteros suman 100 sin depender de nada.

🔬 **El detalle** — SQLite no tiene tipo decimal exacto; los enteros son su numérico exacto.

---

**03 → 16.** Diseña las columnas de fecha y dinero de `pedidos`, `cupones` y las recogidas en
tienda, para una tienda que vende en tres países. 🔴

⏱️ **30 segundos** — `pedidos.creado_en timestamptz`; `cupones.valido_hasta date`; recogidas con
`hora_local timestamp` y `zona text`, como `'Europe/Madrid'`.

🗣️ **2 minutos** — Importes en `numeric(12,2)` con `moneda char(3)` al lado, y ninguna suma entre
monedas. El redondeo en un solo sitio, con la última parte llevando la diferencia. Los tipos de
cambio con más decimales. Los plazos en `interval`, sumados según el calendario.

🔬 **El detalle** — Si el cupón caduca a una hora, es una hora local con zona, no un instante.

---

**03 → 17.** Diagnostica: los clientes de Colombia reciben el aviso de que su cupón ha caducado un
día antes de lo anunciado, y los de España no. 🔴

⏱️ **30 segundos** — El último día se guardó como instante a medianoche de España; en Bogotá, siete
horas menos, se ve como el día anterior.

🗣️ **2 minutos** — Lo comprobaría mirando el tipo de la columna y la zona del proceso que compara.
Corrección: `date`, comparado con la fecha local de cada cliente, o una hora local con zona si el
cupón caduca a una hora concreta.

🔬 **El detalle** — Es el error del segundo caso horario de §2.

---

**03 → 18.** Defiende o refuta «guardamos todas las fechas en UTC y todos los importes en `double`,
y redondeamos al mostrar», con los números del capítulo. 🔴

⏱️ **30 segundos** — Se refuta en las dos mitades. UTC vale para lo que ya pasó; `double` no vale
para dinero.

🗣️ **2 minutos** — Una cita futura en São Paulo convertida a UTC habría quedado una hora desplazada
al cambiar las reglas; un «caduca el 31» en UTC caduca el 30 en otra zona. Y el `double` se desvió
0,00036 en un millón de totales, que se acumula al encadenar cálculos.

🔬 **El detalle** — Redondear al mostrar no arregla lo que el cálculo ya perdió.

---

## Capítulo 04 — Borrado lógico, auditoría e historial

Las 18 preguntas de [`04`](04-borrado-logico-auditoria-e-historial.md).

**04 → 1.** ¿Qué es el borrado lógico? 🟢

⏱️ **30 segundos** — Marcar la fila como borrada —una columna `borrado_en` con la fecha— en vez de
borrarla, y filtrarla en cada consulta.

🗣️ **2 minutos** — La fila sigue ahí para recuperarla, para las claves foráneas que la apuntan y
para los informes del pasado. El motor no sabe que está «borrada».

🔬 **El detalle** — Es **convención**; ningún motor lo implementa.

---

**04 → 2.** ¿Qué diferencia el tiempo de la aplicación del tiempo del sistema? 🟢

⏱️ **30 segundos** — El de la aplicación es cuándo vale un dato según el negocio, y lo fija quien lo
carga, incluso en el futuro. El del sistema es cuándo estuvo vigente en la base, y lo fija el motor
al confirmar.

🗣️ **2 minutos** — «El precio baja el 1 de julio» es de la aplicación. «Cómo estaba la tabla el día
del incidente» es del sistema.

🔬 **El detalle** — PostgreSQL 18 tiene el primero, con claves temporales; MariaDB, el segundo.

---

**04 → 3.** ¿Qué es una clave temporal en PostgreSQL 18? 🟢

⏱️ **30 segundos** — Una clave primaria con `WITHOUT OVERLAPS` sobre un rango, que impide dos
periodos solapados para el mismo valor.

🗣️ **2 minutos** — `PRIMARY KEY (producto, vigencia WITHOUT OVERLAPS)` rechazó un precio de junio a
agosto que chocaba con el de enero a julio. Por debajo es una restricción de exclusión.

🔬 **El detalle** — Es del **motor**, nueva en PostgreSQL 18.

---

**04 → 4.** ¿Qué hace `FOR SYSTEM_TIME AS OF` en MariaDB? 🟢

⏱️ **30 segundos** — Consulta una tabla versionada por el sistema tal como estaba en un instante.

🗣️ **2 minutos** — Tras dos cambios de precio, `AS OF` el instante anterior devolvió 129,90. Con
`ALL` en vez de `AS OF`, enseña todas las versiones.

🔬 **El detalle** — La documentación de MariaDB lo sitúa en SQL:2011.

---

**04 → 5.** ¿Por qué el cliente borrado lógicamente impidió registrar a otro con su correo? 🟡

⏱️ **30 segundos** — Porque la restricción `UNIQUE` sobre el correo no sabe nada de `borrado_en`:
para ella, el correo de `CLI-00311` sigue ocupado.

🗣️ **2 minutos** — El `INSERT` de `CLI-50001` falló con clave duplicada sobre `clientes_email_key`.
Cada restricción de unicidad hay que rehacerla para que ignore a los borrados.

🔬 **El detalle** — Es el primer síntoma de que el motor no sabe qué significa «borrado».

---

**04 → 6.** ¿Qué hace un índice único parcial, y cómo arregló el problema del correo? ¿Lo fija el
estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — Exige unicidad solo entre las filas que cumplen su `WHERE`. Con la condición
`borrado_en IS NULL`, solo entre los activos.

🗣️ **2 minutos** — Tras cambiar la restricción por `clientes_email_activo`, `CLI-50001` entró con el
correo del borrado, y un segundo activo con el mismo correo, `CLI-50002`, se rechazó.

🔬 **El detalle** — Es del **motor**: MySQL no tiene índices parciales.

---

**04 → 7.** ¿Por qué la clave temporal pidió la extensión `btree_gist`? 🟡

⏱️ **30 segundos** — Porque la clave se comprueba con un índice GiST, que de serie solo sabe
comparar rangos, y la clave incluye el texto de `producto`.

🗣️ **2 minutos** — El primer `CREATE TABLE` falló por no haber clase de operadores GiST para `text`.
La documentación de `CREATE TABLE` dice que se añade `btree_gist`, como forma esperada.

🔬 **El detalle** — `CREATE EXTENSION btree_gist` y el mismo `CREATE TABLE` funcionó.

---

**04 → 8.** ¿Qué significa `[2025-01-01,2025-07-01)` como rango de fechas? 🟡

⏱️ **30 segundos** — Del 1 de enero incluido al 1 de julio excluido.

🗣️ **2 minutos** — Así el periodo siguiente empieza justo donde acaba este, sin hueco ni solape.
`[2025-07-01,)` no tiene fin.

🔬 **El detalle** — El corchete incluye y el paréntesis excluye.

---

**04 → 9.** Distingue auditoría e historial: qué pregunta contesta cada uno. 🟡

⏱️ **30 segundos** — La auditoría contesta «quién cambió esto y qué había antes»; el historial,
«cuánto valía en tal fecha».

🗣️ **2 minutos** — La auditoría guarda cada cambio con su autor; para saber el valor de una fecha
hay que recorrerla hacia atrás. El historial guarda cada valor con su periodo y lo contesta con una
consulta.

🔬 **El detalle** — Mezclarlas es el fallo de diseño más habitual del capítulo.

---

**04 → 10.** ¿Por qué un informe puede contar clientes que no existen con borrado lógico, y cómo se
evita? 🟠

⏱️ **30 segundos** — Porque cada consulta tiene que filtrar, y la que lo olvida cuenta a los
borrados: `count(*)` dijo 50 001, con uno borrado.

🗣️ **2 minutos** — Se evita con una vista de activos que usen los informes, o con seguridad a nivel
de fila que esconda los borrados. Lo que no funciona es confiar en que nadie olvide el filtro.

🔬 **El detalle** — Cada consulta nueva es una ocasión de olvidarlo.

---

**04 → 11.** ¿Por qué el borrado lógico no cumple con una petición de borrar datos personales? 🟠

⏱️ **30 segundos** — Porque la fila marcada sigue guardando los datos: marcar no es borrar.

🗣️ **2 minutos** — Hay que suprimir o anonimizar los datos, y también en la auditoría, el historial
y los respaldos que los guarden. Ninguno de los tres mecanismos lo hace solo.

🔬 **El detalle** — El borrado de verdad sigue haciendo falta.

---

**04 → 12.** ¿Por qué la auditoría no contesta bien «qué precio tenía el 15 de marzo»? 🟠

⏱️ **30 segundos** — Porque guarda cambios, no estados: hay que reconstruir el valor recorriendo los
cambios hacia atrás desde hoy.

🗣️ **2 minutos** — Con los datos en `jsonb` y una tabla que solo crece, esa reconstrucción es lenta
y frágil. La clave temporal contestó 129,90 con un `@>` sobre la vigencia.

🔬 **El detalle** — Y la auditoría guarda cuándo se cambió, no desde cuándo vale.

---

**04 → 13.** ¿Por qué el `DELETE` en la tabla versionada dejó 3 filas históricas, y qué implica? ¿Lo
fija el estándar o es cosa del motor? 🟠

⏱️ **30 segundos** — Porque el `DELETE` cierra la versión vigente en vez de borrarla: 0 filas vivas
y las 3 versiones siguen en la historia.

🗣️ **2 minutos** — Implica auditoría de valores sin escribir un disparador. Y que un borrado legal
obliga a purgar la historia aparte.

🔬 **El detalle** — Es del **motor** MariaDB con `WITH SYSTEM VERSIONING`.

---

**04 → 14.** ¿Por qué el tiempo del sistema no sirve para un precio que baja el 1 de julio? 🟠

⏱️ **30 segundos** — Porque el tiempo del sistema lo fija el motor al confirmar: nadie puede poner
una fecha futura.

🗣️ **2 minutos** — El precio futuro es tiempo de la aplicación: se carga hoy con vigencia desde el 1
de julio, como en `precios_vigentes`.

🔬 **El detalle** — Los dos tiempos contestan preguntas distintas; se pueden tener los dos.

---

**04 → 15.** ¿Qué cuesta la auditoría con disparadores, con las cifras del curso? 🟠

⏱️ **30 segundos** — Actualizar 100 000 pedidos pasó de 882 ms a 2 119 ms con disparador por fila,
2,4 veces más; por sentencia con tablas de transición, 1 861 ms.

🗣️ **2 minutos** — Además, una fila de auditoría por cada fila cambiada y una tabla que solo crece,
que se particiona por mes para poder borrar lo que caduca.

🔬 **El detalle** — Las cifras son de `05/02` §3.

---

**04 → 16.** Diseña cómo guardarías los precios de la tienda para contestar el precio de cualquier
fecha, quién los cambió y cómo estaba la tabla el día de un incidente. 🔴

⏱️ **30 segundos** — Tres mecanismos: una clave temporal para el precio de cada fecha, auditoría con
disparadores para quién, y tiempo del sistema o la auditoría para el estado del incidente.

🗣️ **2 minutos** — En PostgreSQL: `precios_vigentes` con `WITHOUT OVERLAPS` y `btree_gist`; un
disparador por sentencia que escribe `auditoria`, particionada por mes. Como PostgreSQL no tiene
versionado por el sistema, el estado del incidente se reconstruye de la auditoría o se restaura un
respaldo a ese instante. En MariaDB, `WITH SYSTEM VERSIONING`.

🔬 **El detalle** — No se mezclan: cada pregunta, su mecanismo.

---

**04 → 17.** Diagnostica: tras implantar el borrado lógico en clientes, el panel dice que hay más
clientes activos que nunca y varios clientes no pueden volver a registrarse. 🔴

⏱️ **30 segundos** — Dos síntomas del mismo olvido: el panel no filtra `borrado_en`, y la unicidad
del correo sigue siendo global.

🗣️ **2 minutos** — Corrección: el panel lee de una vista de activos; la restricción se rehace como
índice único parcial `WHERE borrado_en IS NULL`. Después, revisar cada consulta e informe que toque
`clientes`.

🔬 **El detalle** — Son los dos costes del §2, apareciendo a la vez.

---

**04 → 18.** Defiende o refuta «nunca borramos nada: todo lleva `borrado = true`», con lo que enseña
el capítulo. 🔴

⏱️ **30 segundos** — Se refuta como regla general. El borrado lógico sirve para deshacer bajas y no
romper referencias, no para todo.

🗣️ **2 minutos** — Cada `UNIQUE` hay que rehacerlo como parcial, cada informe tiene que filtrar, la
columna no dice quién borró ni qué había, y no cumple con borrar datos personales.

🔬 **El detalle** — Es la convención que el capítulo desmonta.

---

## Capítulo 05 — Multi-inquilino

Las 18 preguntas de [`05`](05-multi-inquilino.md).

**05 → 1.** ¿Qué es un inquilino en una plataforma? 🟢

⏱️ **30 segundos** — Cada cliente de negocio que usa la misma aplicación con sus propios datos: en
la plataforma, cada tienda con sus clientes, productos y pedidos.

🗣️ **2 minutos** — La aplicación es una sola; la pregunta de diseño es dónde se separan los datos de
cada uno para que ninguno vea los de otro.

🔬 **El detalle** — Una fuga entre inquilinos es el peor fallo posible de una plataforma.

---

**05 → 2.** ¿Cuáles son los tres modelos de separación? ¿Qué parte es del motor y qué parte es
convención? 🟢

⏱️ **30 segundos** — Columna discriminadora, esquema por inquilino y base por inquilino.

🗣️ **2 minutos** — La columna es una base y una migración, pero una consulta sin filtro ve a todos.
El esquema separa más y multiplica migraciones. La base separa casi del todo y multiplica pools,
respaldos y migraciones.

🔬 **El detalle** — Son **convención**; lo que los hace seguros es el **motor**.

---

**05 → 3.** ¿Qué es la seguridad a nivel de fila? 🟢

⏱️ **30 segundos** — Una política que PostgreSQL añade sola a cada consulta sobre una tabla, para
que cada rol solo vea las filas que la política permite.

🗣️ **2 minutos** — Con `USING (inquilino = current_setting('app.inquilino'))`, `app_mt` vio 71 108
pedidos con `ES`. El plan enseña un `Filter` que nadie escribió.

🔬 **El detalle** — Es del **motor**; el estándar no define políticas de fila.

---

**05 → 4.** ¿Qué diferencia `SET` de `SET LOCAL`? 🟡

⏱️ **30 segundos** — `SET` dura toda la sesión; `SET LOCAL`, solo la transacción.

🗣️ **2 minutos** — Tras el `COMMIT`, la conexión con `SET` siguió con `ES` y 71 108 pedidos; con
`SET LOCAL`, el valor quedó vacío y la consulta devolvió cero filas.

🔬 **El detalle** — Con un pool, la diferencia es una fuga o su ausencia.

---

**05 → 5.** ¿Qué pasa si una consulta con RLS se lanza sin haber fijado `app.inquilino`, y por qué
es bueno? 🟡

⏱️ **30 segundos** — Da error: `current_setting` no encuentra el parámetro. La consulta falla
cerrada: ninguna fila, en vez de todas.

🗣️ **2 minutos** — Es bueno porque el olvido se ve como error en vez de como fuga. Con el segundo
argumento, `missing_ok`, devuelve nulo y la consulta da cero filas: también cerrada.

🔬 **El detalle** — Lo peligroso sería una política que con el valor vacío dejara pasar todo.

---

**05 → 6.** ¿Quién se salta las políticas de fila, según la documentación? 🟡

⏱️ **30 segundos** — Los superusuarios, los roles con `BYPASSRLS` y el dueño de la tabla, este
último salvo que se active `FORCE ROW LEVEL SECURITY`.

🗣️ **2 minutos** — Con `RESET ROLE`, el superusuario contó el millón de filas. Por eso la aplicación
entra con un rol sin esos atributos.

🔬 **El detalle** — Es la regla de `06/01`: la aplicación no es dueña de sus tablas.

---

**05 → 7.** ¿Por qué la consulta de los pedidos de `MX` devolvió cero filas con `ES` fijado? 🟡

⏱️ **30 segundos** — Porque la política se suma al `WHERE` de la consulta, no lo sustituye: pedir
`MX` y exigir `ES` a la vez no deja ninguna fila.

🗣️ **2 minutos** — La consulta no puede ampliar lo que la política permite. Un error en la
aplicación que pida otro inquilino no se convierte en fuga.

🔬 **El detalle** — Es la garantía que busca la seguridad de fila.

---

**05 → 8.** ¿Qué crece en el catálogo con un esquema por inquilino? 🟡

⏱️ **30 segundos** — Los objetos de `pg_class`: de 464 a 7 064 con doscientos inquilinos, 33 por
inquilino entre tablas, índices, secuencias y tablas TOAST.

🗣️ **2 minutos** — Cada objeto ocupa sitio en el catálogo, en la caché de cada conexión y en cada
respaldo. Con miles de inquilinos, el catálogo se vuelve un problema en sí.

🔬 **El detalle** — Y eso con las tablas vacías.

---

**05 → 9.** ¿Por qué la base por inquilino complica el pool de conexiones? 🟡

⏱️ **30 segundos** — Porque en PostgreSQL una conexión es a una base, así que cada inquilino
necesita sus propias conexiones.

🗣️ **2 minutos** — Cien inquilinos con diez conexiones cada uno son mil procesos en el servidor.
Además, un respaldo y una migración por base.

🔬 **El detalle** — Es el precio de la separación casi total.

---

**05 → 10.** ¿Por qué la política con `current_setting` sin conversión anuló el índice? 🟠

⏱️ **30 segundos** — Porque la columna es `char(2)` y `current_setting` devuelve texto: para
compararlos, el motor convirtió la columna, y un índice sobre la columna no sirve para una expresión
sobre ella.

🗣️ **2 minutos** — El plan decía `(inquilino)::text`, `Seq Scan` y 928 892 filas descartadas en 177
ms. Convirtiendo el valor a `char(2)`, `Bitmap Index Scan` en 18 ms.

🔬 **El detalle** — Es la regla de `03/06` escondida dentro de una política.

---

**05 → 11.** ¿Cómo puede un pool de conexiones provocar una fuga entre inquilinos, y cómo se evita?
🟠

⏱️ **30 segundos** — Si el inquilino se fija con `SET`, se queda en la conexión tras el `COMMIT`, y
la siguiente petición que la reciba ve los datos del anterior si olvida fijar el suyo.

🗣️ **2 minutos** — Se evita con `SET LOCAL` dentro de la transacción de cada petición, o reiniciando
la conexión al devolverla al pool. Y se prueba a propósito: dos peticiones de inquilinos distintos
por la misma conexión.

🔬 **El detalle** — No deja error en ningún registro: devuelve datos correctos del inquilino
equivocado.

---

**05 → 12.** ¿Por qué la aplicación no puede conectarse como dueña de las tablas con RLS? 🟠

⏱️ **30 segundos** — Porque el dueño se salta las políticas, salvo `FORCE ROW LEVEL SECURITY`.

🗣️ **2 minutos** — Si la aplicación entra como dueña, toda la seguridad de fila queda sin efecto.
Las migraciones usan el rol dueño; la aplicación, uno con solo los permisos que necesita.

🔬 **El detalle** — `FORCE` existe para el dueño, pero no cubre al superusuario ni a `BYPASSRLS`.

---

**05 → 13.** ¿Qué cuesta una migración con doscientos esquemas, y qué pasa si falla a la mitad? 🟠

⏱️ **30 segundos** — Son doscientas migraciones: con tablas vacías tardó 14 ms, con datos cada una
tiene sus bloqueos y su tiempo.

🗣️ **2 minutos** — Si falla a la mitad, deja inquilinos en versiones distintas del esquema, y la
aplicación tiene que servir a los dos. Hay que registrar la versión por esquema y reanudar.

🔬 **El detalle** — Los bloqueos son los de `06/04`, multiplicados por doscientos.

---

**05 → 14.** ¿Cuándo elegirías esquema por inquilino en vez de columna discriminadora? 🟠

⏱️ **30 segundos** — Con pocos inquilinos grandes que exigen separación, o exportar y restaurar cada
cliente por separado.

🗣️ **2 minutos** — Sabiendo que cada migración se repite en todos y el catálogo crece: 33 objetos
por inquilino. Con miles de inquilinos pequeños, la columna con RLS es más barata.

🔬 **El detalle** — Una consulta sin filtro solo ve su esquema: la separación es más fuerte.

---

**05 → 15.** ¿Qué tienen en común la trampa del tipo en la política y la de la volatilidad de
`05/01`? 🟠

⏱️ **30 segundos** — Que la política es una expresión escondida en cada consulta, y lo que valga
para un `WHERE` —el tipo, la volatilidad— vale para ella.

🗣️ **2 minutos** — Una conversión de la columna anula el índice; una función `VOLATILE` en la
condición también: en `05/01`, 414 ms y un millón de llamadas frente a 0,037 ms con `STABLE`. En los
dos casos nadie lo ve en el código de la aplicación.

🔬 **El detalle** — Se diagnostica con `EXPLAIN` ejecutado con el rol de la aplicación.

---

**05 → 16.** Diseña la separación de datos de una plataforma con dos mil tiendas pequeñas y tres
grandes que exigen aislamiento. 🔴

⏱️ **30 segundos** — Mezcla: las dos mil pequeñas en una base compartida con columna discriminadora
y RLS; las tres grandes, cada una en su base.

🗣️ **2 minutos** — Política con el tipo correcto, rol de aplicación sin `BYPASSRLS` ni propiedad,
inquilino con `SET LOCAL` en cada petición. Las tres grandes con su pool, su respaldo y su
migración. Dos mil esquemas serían unos 66 000 objetos en el catálogo y dos mil migraciones.

🔬 **El detalle** — La aplicación decide a qué base conectar según el inquilino; las migraciones se
aplican a cuatro bases, no a dos mil esquemas.

---

**05 → 17.** Diagnostica: un cliente de la plataforma ve, a veces, pedidos de otra tienda, siempre
justo después de un pico de tráfico. 🔴

⏱️ **30 segundos** — Sospecha: el inquilino queda fijado en una conexión con `SET` de sesión, y con
el pico se reutilizan conexiones con el valor de otro.

🗣️ **2 minutos** — Lo confirmaría con dos peticiones de inquilinos distintos por la misma conexión.
Corrección: `SET LOCAL` en la transacción de cada petición o reinicio al devolver al pool. Y revisar
los registros para saber qué se vio.

🔬 **El detalle** — No hay error en ningún registro: son datos correctos del inquilino equivocado.

---

**05 → 18.** Defiende o refuta «un esquema por cliente es lo más seguro y lo más simple», con los
números del capítulo. 🔴

⏱️ **30 segundos** — Se matiza: más seguro que una columna sin RLS, sí; lo más simple, no.

🗣️ **2 minutos** — Doscientos esquemas son 6 600 objetos más en el catálogo y doscientas migraciones
que pueden fallar a la mitad. La columna con RLS da una garantía en la base con una sola migración,
si se cuida el tipo de la política y el `SET LOCAL`.

🔬 **El detalle** — Lo más seguro es la base por inquilino, y es lo más caro de operar.

---

## Capítulo 06 — Paginación y búsqueda de texto

Las 18 preguntas de [`06`](06-paginacion-y-busqueda-de-texto.md).

**06 → 1.** ¿Qué diferencia la paginación por desplazamiento de la paginación por clave? 🟢

⏱️ **30 segundos** — Por desplazamiento se pide «sáltate N filas y dame veinte», con `OFFSET`; por
clave, «dame veinte filas después de esta», con la última fila de la página anterior como cursor.

🗣️ **2 minutos** — El desplazamiento cuesta más cuanto más lejos está la página y se desordena si
llegan filas nuevas; la clave cuesta lo mismo en cualquier página y no depende de lo que haya
delante.

🔬 **El detalle** — A la de clave se la llama también *keyset* o paginación por cursor.

---

**06 → 2.** ¿Qué es un orden total, y por qué hace falta para paginar por clave? 🟢

⏱️ **30 segundos** — Un orden en que no hay dos filas empatadas: cada fila tiene una posición única.

🗣️ **2 minutos** — Con `ORDER BY creado_en DESC` solo, dos pedidos con la misma marca de tiempo no
tienen orden, y el cursor puede saltarse uno o repetirlo. Se desempata con la clave primaria:
`creado_en DESC, id DESC`.

🔬 **El detalle** — Es **convención**; el motor no lo exige.

---

**06 → 3.** ¿Qué hace `\gset` en `psql`? 🟢

⏱️ **30 segundos** — Ejecuta la consulta y guarda las columnas de su única fila en variables de
`psql`, con el prefijo que se le dé.

🗣️ **2 minutos** — `\gset ultimo_` dejó `:ultimo_creado_en` y `:ultimo_id`, que la consulta
siguiente usó como cursor. Es lo que una API devolvería al cliente para pedir la página siguiente.

🔬 **El detalle** — Es de `psql`, no del servidor.

---

**06 → 4.** ¿Qué índice necesita la paginación por clave de los pedidos más recientes? 🟡

⏱️ **30 segundos** — Uno compuesto sobre `creado_en DESC, id DESC`: las columnas del orden, en el
mismo orden.

🗣️ **2 minutos** — Así la base lee las filas ya ordenadas, salta directamente al cursor y para en
cuanto tiene veinte. El plan lo enseñó como `Index Cond` sobre la comparación de filas.

🔬 **El detalle** — Las reglas del índice compuesto son las de `03/03`.

---

**06 → 5.** ¿Qué significa `rows=500020.00` en el plan de la página 25 000? 🟡

⏱️ **30 segundos** — Que el `Index Scan` entregó 500 020 filas al `Limit`, que tiró las primeras 500
000 y devolvió veinte.

🗣️ **2 minutos** — Por eso tardó 302 ms y tocó casi medio millón de páginas en memoria compartida,
frente a los 0,072 ms de la primera página.

🔬 **El detalle** — El índice no permite saltarse N filas: hay que recorrerlas.

---

**06 → 6.** ¿Qué dice la documentación de PostgreSQL sobre un `OFFSET` grande? 🟡

⏱️ **30 segundos** — Que las filas que se salta un `OFFSET` hay que calcularlas igual dentro del
servidor, y que por eso un `OFFSET` grande puede ser ineficiente.

🗣️ **2 minutos** — La sesión lo confirmó: `OFFSET 500000` leyó 500 020 filas del índice.

🔬 **El detalle** — Está en la página «LIMIT and OFFSET» de la documentación.

---

**06 → 7.** ¿Qué devuelve una API con paginación por clave para pedir la página siguiente? ¿Qué
parte es del motor y qué parte es convención? 🟡

⏱️ **30 segundos** — Un cursor con los valores de las columnas del orden de la última fila:
`creado_en` e `id`.

🗣️ **2 minutos** — Suele ir codificado como una cadena opaca para que el cliente no lo manipule ni
dependa de su forma. La petición siguiente lo devuelve y la consulta hace `(creado_en, id) < (…)`.

🔬 **El detalle** — Es **convención** de API; el cursor no es un permiso.

---

**06 → 8.** ¿Qué no puede hacer la paginación por clave que sí hace `OFFSET`? 🟡

⏱️ **30 segundos** — Saltar a una página concreta, como la 3 000, sin recorrer las anteriores.

🗣️ **2 minutos** — Solo va a la siguiente o, con el orden invertido, a la anterior. Tampoco dice
cuántas páginas hay, y contar tiene su precio.

🔬 **El detalle** — Por eso encaja con el desplazamiento infinito, no con «ir a la página».

---

**06 → 9.** ¿Por qué `PED-947907` salió en dos páginas seguidas con `OFFSET`? 🟠

⏱️ **30 segundos** — Porque llegó un pedido nuevo que se colocó el primero y empujó todas las filas
una posición: la tercera pasó a ser la cuarta, y `OFFSET 3` empezó por ella.

🗣️ **2 minutos** — Por clave, la página siguiente empezó justo después de `PED-947907`, llegara lo
que llegara delante. La página depende de dónde se quedó la anterior, no de cuántas filas hay antes.

🔬 **El detalle** — Es el defecto que solo aparece con tráfico, nunca en las pruebas.

---

**06 → 10.** ¿Qué pasa con `OFFSET` si se borra un pedido mientras alguien pagina? 🟠

⏱️ **30 segundos** — Lo contrario: las filas retroceden una posición y una se salta, sin salir en
ninguna página.

🗣️ **2 minutos** — Con borrado o con un cambio de estado que saque la fila del filtro, el efecto es
el mismo. Por clave, el cursor sigue marcando dónde se quedó la lista.

🔬 **El detalle** — Repetidos y perdidos son el mismo mecanismo con signo distinto.

---

**06 → 11.** ¿Por qué la página 25 000 por clave tarda lo mismo que la primera? 🟠

⏱️ **30 segundos** — Porque el índice salta directamente al cursor y lee veinte filas: 0,081 ms, del
orden de los 0,072 de la primera.

🗣️ **2 minutos** — La comparación de filas `(creado_en, id) < (…)` aparece como `Index Cond`: el
B-tree baja hasta ese punto como en cualquier búsqueda y recorre veinte entradas.

🔬 **El detalle** — El coste depende del tamaño de la página, no de su número.

---

**06 → 12.** ¿Qué cuesta enseñar «página 3 de 50 000», y qué alternativas hay? 🟠

⏱️ **30 segundos** — Un recuento en cada carga: 58 ms por contar el millón de pedidos, y más con
filtros, que son otra consulta con su plan.

🗣️ **2 minutos** — Alternativas: no enseñar el total, enseñar «más de mil», o un recuento aproximado
de las estadísticas del planificador, de `03/04`.

🔬 **El detalle** — Es **convención** de interfaz; el usuario rara vez necesita el número exacto.

---

**06 → 13.** ¿Cuándo sigue siendo razonable `OFFSET`? 🟠

⏱️ **30 segundos** — En listas cortas y acotadas, donde saltar a una página concreta importa más que
la coherencia.

🗣️ **2 minutos** — Un panel de administración con filtros que dejan pocas filas: el coste de
recorrer unas decenas de filas es despreciable y el usuario quiere ir a la página 4.

🔬 **El detalle** — Lo que deja de valer es `OFFSET` sobre la tabla entera.

---

**06 → 14.** ¿Cuándo basta la búsqueda de texto de PostgreSQL para la caja de búsqueda de la tienda,
y cuándo no? 🟠

⏱️ **30 segundos** — Basta con miles o decenas de miles de filas: `tsvector` con GIN, `unaccent`
para las tildes y `pg_trgm` para las erratas. No basta con millones, relevancia afinada o facetas.

🗣️ **2 minutos** — En `09/05`, `tsvector` encontró los 328 sin tilde pero ninguno de los 95 en
singular; OpenSearch encontró los 95 y toleró la errata, a cambio de una copia que se ve tras el
refresco de un segundo.

🔬 **El detalle** — Se prueba con las palabras reales del catálogo, porque el *stemmer* falló.

---

**06 → 15.** ¿Por qué combinar búsqueda por relevancia y `OFFSET` da problemas? 🟠

⏱️ **30 segundos** — Porque la relevancia cambia con cada documento nuevo, así que el orden se mueve
entre páginas, y el `OFFSET` repite y pierde resultados.

🗣️ **2 minutos** — Además, las páginas profundas obligan a ordenar todo lo parecido. Los motores de
búsqueda ofrecen su propio cursor para paginar resultados profundos.

🔬 **El detalle** — Es el problema de §4 con un orden aún menos estable.

---

**06 → 16.** Diseña la API de listado de pedidos del panel: parámetros, orden, cursor, índice y qué
pasa al llegar pedidos nuevos. 🔴

⏱️ **30 segundos** — `GET /pedidos?limite=20&cursor=…`, orden `creado_en DESC, id DESC`, índice
compuesto con esas columnas, cursor opaco con la fecha y el `id` de la última fila.

🗣️ **2 minutos** — La consulta hace `WHERE (creado_en, id) < (…) ORDER BY … LIMIT 20`. Los pedidos
nuevos no desplazan nada: aparecen al volver a la primera página. Sin total exacto, o aproximado.
Filtrado siempre por el cliente o el inquilino autenticado.

🔬 **El detalle** — El cursor se valida como cualquier entrada; no da acceso por sí mismo.

---

**06 → 17.** Diagnostica: el desplazamiento infinito de la app de la tienda se vuelve lento a partir
de la página 200, y algunos usuarios ven productos repetidos. 🔴

⏱️ **30 segundos** — Es `OFFSET`: el coste crece con el número de página, y los productos nuevos o
reordenados desplazan las filas y repiten.

🗣️ **2 minutos** — Lo confirmaría con el plan: `rows` del escaneo igual a `OFFSET` más el límite.
Corrección: paginación por clave con orden total y el índice compuesto que lo sirva; la página 25
000 bajó de 302 ms a 0,081.

🔬 **El detalle** — El desplazamiento infinito es el caso ideal para la clave: nunca salta páginas.

---

**06 → 18.** Defiende o refuta mantener `OFFSET` en toda la aplicación «porque los usuarios nunca
pasan de la página 5», con los números del capítulo. 🔴

⏱️ **30 segundos** — Se matiza: si de verdad nunca pasan de la página 5, el coste es el de la
primera, 0,072 ms. Pero el repetido aparece en la página 2.

🗣️ **2 minutos** — `PED-947907` salió dos veces con un solo pedido nuevo. Y los que sí pasan de la
página 5 son robots, exportaciones e integraciones, que llegan a la página 25 000: 302 ms cada una.

🔬 **El detalle** — `OFFSET` puede quedarse donde las listas son cortas; no en toda la aplicación.

---

## Simulación de entrevista

Las 26 preguntas `S#` y los cuatro escenarios de [`07`](07-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**07 → S1.** ¿Por qué el curso empieza por una base relacional, y cuándo no? 🟢

⏱️ **30 segundos** — Porque contesta consultas que nadie previó con un índice más, trae tipos,
transacciones y claves foráneas, y ya resuelve dentro documentos, series, texto y vectores.

🗣️ **2 minutos** — No vale cuando la escala o la forma de acceso ya se conocen y no caben —veinte
mil escrituras por segundo entre regiones— o cuando el ecosistema manda, como un servicio sin
servidor que solo ofrece DynamoDB.

🔬 **El detalle** — Es **convención** razonada, no un estándar.

---

**07 → S2.** ¿Qué preguntas harías antes de aceptar un motor nuevo en la arquitectura? 🟡

⏱️ **30 segundos** — Las cinco del árbol: cómo se lee el dato, qué mecanismo falla hoy medido, si lo
resuelve algo dentro de la base actual, qué debe hacer el dato durante un fallo y quién lo opera.

🗣️ **2 minutos** — Sin un mecanismo nombrado y medido no hay caso. Y el paso 3 va antes que el 5: si
un índice, un `jsonb` o una extensión lo resuelven, no hay copia nueva que operar.

🔬 **El detalle** — Lo que se evalúa es el camino, no el nombre del producto.

---

**07 → S3.** El contador de visitas de un producto en campaña no aguanta. ¿Qué harías antes de
añadir Redis? 🟠

⏱️ **30 segundos** — Acumular en la aplicación y volcar cada segundo con un solo `UPDATE`: quita
casi toda la presión sobre la fila caliente.

🗣️ **2 minutos** — El mecanismo es el bloqueo de una fila: 4 373 escrituras por segundo con 16
clientes, menos que con uno. Redis sirve 121 080, pero añade RAM, un motor y la pérdida del último
segundo. Entra si además hacen falta límites de uso o sesiones compartidas.

🔬 **El detalle** — El contador tolera perder un segundo; un saldo no.

---

**07 → S4.** ¿Qué cuesta un motor más que no aparece en ningún benchmark? 🟡

⏱️ **30 segundos** — Otra copia con retraso, otro respaldo con su restauración de prueba, otro
sistema de permisos, otra forma de migrar y otra guardia.

🗣️ **2 minutos** — El buscador enseñó un cambio un segundo tarde; cada motor tiene su RPO y alguien
tiene que saber restaurarlo a las tres de la mañana.

🔬 **El detalle** — Es **convención** de arquitectura; ningún capítulo lo cronometró.

---

**07 → S5.** ¿Clave natural o sustituta para `clientes`, y qué haces con el correo? 🟢

⏱️ **30 segundos** — Sustituta, `bigint` con `IDENTITY`, como clave primaria; el correo, en un
`UNIQUE`.

🗣️ **2 minutos** — Así las claves foráneas usan un valor que nunca cambia, el `UNIQUE` evita
clientes duplicados y el correo se puede cambiar tocando una fila.

🔬 **El detalle** — Sin el `UNIQUE`, la sustituta identifica filas, no clientes.

---

**07 → S6.** ¿Por qué no es un argumento contra la clave natural el tamaño del índice? 🟠

⏱️ **30 segundos** — Porque la deduplicación del B-tree lo compensa: el índice sobre el correo ocupó
9 152 kB frente a 7 800 del `bigint`, un 17 % más.

🗣️ **2 minutos** — Y la cascada reescribió los 52 pedidos de `CLI-00311` en 1,96 ms. El argumento
bueno es otro: el correo sale de la base —registros, eventos, otros servicios— y no vuelve cuando
cambia.

🔬 **El detalle** — Quien refuta por el tamaño se equivoca con los números.

---

**07 → S7.** ¿Qué revela un entero en la URL, y qué revela un UUIDv7? 🟡

⏱️ **30 segundos** — El entero, cuántos hay y cuántos se crean, y deja probar el siguiente. El
UUIDv7, cuándo se creó.

🗣️ **2 minutos** — `uuid_extract_timestamp` devolvió la fecha del v7 y nulo con el v4. Si la fecha
es sensible, el identificador público es un v4 o un código propio.

🔬 **El detalle** — La marca de tiempo es lo que da al v7 un índice ordenado.

---

**07 → S8.** ¿Por qué un UUID en la URL no es un control de acceso? 🟠

⏱️ **30 segundos** — Porque un identificador se filtra —en un enlace, un registro, una captura— y
abre igual. La RFC 9562 dice que no se use como credencial.

🗣️ **2 minutos** — El fallo de acceso a pedidos ajenos es no comprobar la propiedad. El UUID lo
esconde; comprobar en cada petición que el pedido es del cliente lo arregla.

🔬 **El detalle** — **Estándar**, la RFC, más una **convención** de seguridad.

---

**07 → S9.** ¿Qué columna para un pedido, un cupón y una recogida en tienda? 🟢

⏱️ **30 segundos** — El pedido, `timestamptz`; el último día del cupón, `date`; la recogida,
`timestamp` más una columna con la zona.

🗣️ **2 minutos** — El pedido es un instante que ya pasó; el cupón es un día, sin hora; la recogida
es la hora del reloj de una ciudad, que se convierte cuando se usa, con las reglas vigentes.

🔬 **El detalle** — Qué columna para qué caso es **convención**; los tipos, del **estándar** con
matices del **motor**.

---

**07 → S10.** ¿Por qué sumar un día no es sumar 24 horas? 🟡

⏱️ **30 segundos** — Porque los días del cambio de hora no tienen 24 horas: el 30 de marzo de 2025
en Madrid, un día llevó a las 12:00 y 24 horas, a las 13:00.

🗣️ **2 minutos** — «Mañana a la misma hora» es un día; «24 horas después del pago» son 24 horas. Lo
decide el negocio y hay que escribirlo.

🔬 **El detalle** — La documentación de PostgreSQL lo avisa así.

---

**07 → S11.** ¿Por qué una cita futura no se guarda en UTC? 🟠

⏱️ **30 segundos** — Porque convertirla usa las reglas de hoy, y si la ciudad las cambia, el
instante guardado deja de ser la hora prometida.

🗣️ **2 minutos** — Las mismas 10:00 en São Paulo fueron las 13:00 de Madrid en 2018 y las 14:00 en
2020, porque Brasil suprimió el horario de verano. Se guarda la hora local y la zona.

🔬 **El detalle** — Lo que ya pasó sí va en UTC, como instante.

---

**07 → S12.** ¿Qué tres reglas sigue una columna de dinero? 🟡

⏱️ **30 segundos** — Tipo exacto, la moneda al lado y el redondeo en un solo sitio con una regla
escrita.

🗣️ **2 minutos** — `numeric` o `DECIMAL`, o céntimos enteros en SQLite; nunca coma flotante, que se
desvió 0,00036 sobre el millón de totales. Un código ISO de moneda, y ninguna suma entre monedas.

🔬 **El detalle** — Son **convención**; el motor solo da el tipo exacto.

---

**07 → S13.** Distingue borrado lógico, auditoría e historial por la pregunta que contestan. 🟢

⏱️ **30 segundos** — Borrado lógico: «recupera este cliente». Auditoría: «¿quién cambió esto y qué
había?». Historial: «¿cuánto valía en tal fecha?».

🗣️ **2 minutos** — Mezclarlos es el fallo típico: `borrado_en` no dice quién borró, y la auditoría
no contesta rápido el precio de una fecha.

🔬 **El detalle** — Tres preguntas, tres mecanismos, tres precios.

---

**07 → S14.** ¿Qué rompe el borrado lógico en las restricciones, y cómo se arregla? 🟠

⏱️ **30 segundos** — El `UNIQUE`: el cliente borrado sigue ocupando su correo, y otro no puede
registrarse con él.

🗣️ **2 minutos** — Se rehace como índice único parcial `WHERE borrado_en IS NULL`: `CLI-50001` entró
con el correo del borrado, y un segundo activo con el mismo correo se rechazó.

🔬 **El detalle** — Índice parcial del **motor**; MySQL no los tiene.

---

**07 → S15.** ¿Qué es una clave temporal, y qué no tiene PostgreSQL que sí tiene MariaDB? 🟡

⏱️ **30 segundos** — Una clave primaria con `WITHOUT OVERLAPS` sobre un rango, que impide periodos
solapados. PostgreSQL 18 la tiene; no tiene tablas versionadas por el sistema.

🗣️ **2 minutos** — `WITH SYSTEM VERSIONING` dio error de sintaxis en PostgreSQL. MariaDB guardó las
tres versiones de un precio y las mantuvo tras el `DELETE`.

🔬 **El detalle** — La clave temporal pidió `btree_gist` por el texto de `producto`.

---

**07 → S16.** ¿Por qué el borrado lógico no cumple con borrar datos personales? 🟡

⏱️ **30 segundos** — Porque la fila marcada sigue guardando los datos.

🗣️ **2 minutos** — Hay que suprimir o anonimizar, también en la auditoría, el historial y lo que
guarden los respaldos. Ninguno de los tres mecanismos lo hace solo.

🔬 **El detalle** — El borrado de verdad sigue haciendo falta.

---

**07 → S17.** ¿Cuáles son los tres modelos multi-inquilino, y qué cuesta cada uno? 🟢

⏱️ **30 segundos** — Columna discriminadora, esquema por inquilino y base por inquilino.

🗣️ **2 minutos** — La columna cuesta que cada consulta filtre, o RLS. El esquema, una migración por
inquilino y el catálogo: doscientos fueron de 464 a 7 064 objetos. La base, un pool, un respaldo y
una migración por cliente.

🔬 **El detalle** — **Convención** de arquitectura; lo que la hace segura es el **motor**.

---

**07 → S18.** ¿Quién se salta la seguridad a nivel de fila? 🟡

⏱️ **30 segundos** — Los superusuarios, los roles con `BYPASSRLS` y el dueño de la tabla, salvo
`FORCE ROW LEVEL SECURITY`.

🗣️ **2 minutos** — El superusuario contó el millón de filas con la política activa. Por eso la
aplicación entra con un rol sin esos atributos ni propiedad.

🔬 **El detalle** — Es la regla de mínimo privilegio del bloque 06, con una razón más.

---

**07 → S19.** ¿Cómo provoca un pool una fuga entre inquilinos? 🟠

⏱️ **30 segundos** — Si el inquilino se fija con `SET`, sobrevive al `COMMIT`, y la siguiente
petición que recibe esa conexión ve los datos del anterior si olvida fijar el suyo.

🗣️ **2 minutos** — La sesión lo enseñó: tras el `COMMIT`, la conexión seguía con `ES` y 71 108
pedidos. Con `SET LOCAL`, cero filas después. Se prueba con dos peticiones seguidas por la misma
conexión.

🔬 **El detalle** — No deja error en ningún registro.

---

**07 → S20.** ¿Por qué `OFFSET` se vuelve lento, y qué lo sustituye? 🟡

⏱️ **30 segundos** — Porque lee todas las filas que se salta: la página 25 000 leyó 500 020 filas en
302 ms. La paginación por clave lo sustituye.

🗣️ **2 minutos** — Con orden total e índice compuesto, `(creado_en, id) < (cursor)` tardó 0,081 ms
en la misma página. Y no repite filas cuando llegan pedidos nuevos.

🔬 **El detalle** — La documentación de PostgreSQL avisa del coste de un `OFFSET` grande.

---

**07 → S21.** ¿Cuándo basta la búsqueda de texto de PostgreSQL? 🟠

⏱️ **30 segundos** — Con miles o decenas de miles de filas, con `tsvector` y GIN, `unaccent` y
`pg_trgm`.

🗣️ **2 minutos** — Encontró los 328 sin tilde; falló el singular, 0 de 95, que OpenSearch sí
encontró. El motor aparte se gana con volumen, relevancia afinada o facetas, pagando una copia con
retraso.

🔬 **El detalle** — Se prueba con las palabras reales del catálogo.

---

**07 → S22.** «Una política de fila no cambia el rendimiento: solo añade un filtro». Refútalo con la
sesión. 🔴

⏱️ **30 segundos** — La política comparaba `char(2)` con el texto de `current_setting`, el motor
convirtió la columna y el índice dejó de servir: 177 ms frente a 18.

🗣️ **2 minutos** — Convirtiendo el valor, no la columna, el plan pasó a `Bitmap Index Scan`. La
política es una expresión escondida en cada consulta; lo que valga para un `WHERE` vale para ella.

🔬 **El detalle** — Se diagnostica con `EXPLAIN` ejecutado con el rol de la aplicación.

---

**07 → S23.** «Con `double` y un redondeo al mostrar, el dinero cuadra». ¿Qué parte es cierta? 🟠

⏱️ **30 segundos** — Que un total redondeado a céntimos suele cuadrar: el millón se desvió 0,00036.

🗣️ **2 minutos** — Pero en cálculos encadenados las desviaciones se acumulan, y un redondeo en el
borde da un céntimo distinto. Con `numeric` no hay nada que razonar.

🔬 **El detalle** — Redondear al mostrar no arregla lo que el cálculo ya perdió.

---

**07 → S24.** «La auditoría ya nos da el historial de precios». Refútalo. 🟠

⏱️ **30 segundos** — La auditoría guarda cambios, no estados: el precio de una fecha hay que
reconstruirlo recorriéndola hacia atrás.

🗣️ **2 minutos** — Y guarda cuándo se cambió, no desde cuándo vale: un precio cargado hoy para el 1
de julio no sale. La clave temporal contestó 129,90 para el 15 de marzo con una consulta.

🔬 **El detalle** — Auditoría e historial contestan preguntas distintas.

---

**07 → S25.** «Con `OFFSET` y un índice, cualquier página es rápida». Refútalo con números. 🔴

⏱️ **30 segundos** — Con el índice, la primera página tardó 0,072 ms y la 25 000, 302 ms: el índice
entregó 500 020 filas para devolver veinte.

🗣️ **2 minutos** — El índice no permite saltarse N filas. Por clave, la misma página tardó 0,081 ms.
Y `OFFSET` repitió `PED-947907` al llegar un pedido nuevo.

🔬 **El detalle** — El coste de `OFFSET` crece con el número de página.

---

**07 → S26.** «MongoDB es más rápido que PostgreSQL». ¿Qué parte es cierta? 🟡

⏱️ **30 segundos** — Que lee rápido la entidad entera por su clave: el pedido como un documento de
379 bytes.

🗣️ **2 minutos** — Pero el panel que une entidades tardó 472 ms con `$lookup` frente a 28 con
`JOIN`. Cada motor gana en su forma de acceso y en ninguna otra.

🔬 **El detalle** — La pregunta correcta es «más rápido para qué forma de acceso».

---

**07 → E1.** Escenario 1 — La plataforma de tiendas

⏱️ **30 segundos** — Mezcla: las mil quinientas pequeñas en una base con columna discriminadora y
seguridad de fila; el banco en su propia base; la otra grande, en la compartida salvo que lo exija.

🗣️ **2 minutos** — Claves `bigint` internas, correo y código en `UNIQUE`, y un identificador público
sin secuencia visible; la API comprueba la propiedad. Las dos trampas: la política con el tipo
correcto para no anular el índice, y el inquilino con `SET LOCAL` para que el pool no lo arrastre;
el rol de la aplicación sin `BYPASSRLS` ni propiedad. Una migración son dos bases, no mil quinientos
esquemas.

🔬 **El detalle** — Lo que se evalúa es nombrar las dos trampas y el precio operativo de la base
aparte.

---

**07 → E2.** Escenario 2 — El precio de marzo

⏱️ **30 segundos** — Hoy no se puede contestar ninguna de las dos: el precio se pisa en el sitio y
no hay registro de cambios.

🗣️ **2 minutos** — Para contabilidad, una tabla de precios con vigencia y clave temporal, que
contesta el precio de cualquier fecha con `@>`. Para cumplimiento, auditoría con un disparador por
sentencia, a 2,1 veces el coste del `UPDATE` o menos, particionada por mes. Los productos retirados,
con borrado lógico e índices parciales, sin confundirlo con ninguna de las dos. La reclamación de
hoy, solo con un respaldo de marzo.

🔬 **El detalle** — Lo que se evalúa es separar las dos preguntas y no ofrecer `borrado` como
auditoría.

---

**07 → E3.** Escenario 3 — La app que se atasca

⏱️ **30 segundos** — El listado usa `OFFSET`: lee todo lo que se salta y repite filas cuando el
catálogo cambia. El buscador falla porque el *stemmer* español no junta el singular con el plural.

🗣️ **2 minutos** — Sin cambiar de motor: paginación por clave con orden total e índice compuesto, de
302 ms a 0,081 en la página 25 000. Elasticsearch, aceptable si el buscador necesita plurales,
erratas y relevancia, como copia que se reconstruye y se ve con un segundo de retraso. MongoDB, no:
nada falla en el catálogo que no resuelva un `jsonb`, y el panel que une entidades empeoraría.

🔬 **El detalle** — Lo que se evalúa es separar la propuesta que tiene mecanismo de la que no.

---

**07 → E4.** Escenario 4 — «Los plazos no cuadran: cambiemos a una base con decimales exactos»

⏱️ **30 segundos** — No lo resuelve la base de datos: la columna ya es `numeric`, que suma exacto.
El céntimo lo pierde el reparto: 33,33 × 3 da 99,99 en cualquier motor.

🗣️ **2 minutos** — La regla: se redondea cada plazo y el último lleva la diferencia, para que las
partes sumen el total. Se escribe en un solo sitio del código, con una prueba que compare la suma
con el total. Después, buscar los pedidos cuyos plazos no suman el total con una consulta, y revisar
los otros repartos: líneas, impuestos, devoluciones parciales.

🔬 **El detalle** — Lo que se evalúa es no aceptar el marco y encontrar el algoritmo.

---

**Volver:** [README del bloque](README.md).
