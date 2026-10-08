# 06 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiséis transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los cinco capítulos del
> bloque, de [`01`](01-el-modelo-documental.md) a [`05`](05-documental-relacional-o-jsonb.md).
> **Vigencia:** 27 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. La trampa de este bloque es la contraria a la del anterior: aquí la
pregunta suele llegar como una comparación de bandos —«¿MongoDB o PostgreSQL?»— y la respuesta buena
no elige bando: **dice cómo se lee el dato, cuánto crece y quién más lo consulta**, y de ahí sale el
modelo.

- **Cronómetro a dos minutos por pregunta.** Y la regla del bloque: **cada afirmación con lo
  medido**. *«El pedido se lee en 0,115 ms con `JOIN` y como un documento de 379 bytes en MongoDB»*
  cierra una discusión de folletos.
- **En voz alta.** Los mecanismos se recuerdan diciéndolos con su efecto: *«sin `$elemMatch`, cada
  condición se cumplió con una línea distinta»*.
- **Sin mirar los capítulos.** Cuando no recuerdes una cifra, di cómo la verías: *«lo miraría con
  `explain("executionStats")` y compararía documentos examinados con devueltos»*.
- **Después, contra [`07`](07-respuestas.md).** Busca si separaste lo del motor de lo que es
  convención de modelado, y si dijiste qué se paga.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿quién comprueba esto?»**:
> el tipo del total, la condición sobre la lista, la replicación de la escritura. En documental, la
> respuesta por defecto es «nadie, salvo que lo pidas», y la buena respuesta dice cómo pedirlo.

---

## 2. 🧠 Transversales

### El modelo

**S1.** ¿Qué gana y qué pierde el pedido de la tienda como documento, con lo medido? 🟡

**S2.** «MongoDB no tiene esquema». ¿Qué parte es cierta y qué se vio al guardar un total como
texto? 🟠

**S3.** ¿Por qué el documento ocupa más sin comprimir y menos en disco que las filas? 🟡

**S4.** Couchbase, CouchDB y Firestore: lo único que distingue a cada uno de MongoDB. 🟢

### Consulta y agregación

**S5.** Explica la trampa de dos condiciones sobre una lista y cómo la evita `$elemMatch`. 🟠

**S6.** ¿Por qué el top de productos fue tres veces más lento en MongoDB con el mismo resultado? 🟠

**S7.** `$lookup` frente a un `JOIN`: cómo se ejecuta cada uno y cuánto costó. 🟡

**S8.** ¿Por qué cambiar una línea del pedido no actualiza su total, y cómo se hace en la misma
orden? 🟡

### Modelado

**S9.** ¿Qué preguntas deciden si una parte se incrusta o se referencia? Aplícalas a las líneas y a
los pedidos de un cliente. 🟠

**S10.** ¿Cómo se llega al límite de 16 MiB, y por qué no avisa? 🟠

**S11.** La referencia extendida: qué es, cuánto ahorró y qué cuesta. 🟡

**S12.** El patrón *bucket* con los eventos de la tienda: qué cambió y qué se paga. 🟡

**S13.** ¿Por qué la tienda no necesita el patrón *outlier*? 🟠

### Índices, réplicas y transacciones

**S14.** ¿Qué es un índice multikey y cuánto ocupó el de las líneas? 🟢

**S15.** La regla ESR, con las 11 859 y las 16 claves de la sesión, y cuándo conviene romperla. 🟠

**S16.** Una escritura con `w: "majority"` devolvió error por tiempo de espera. ¿Se hizo? ¿Qué pasa
si se reintenta? 🔴

**S17.** ¿Por qué `readConcern("majority")` devolvió el valor viejo leyendo del primario? 🟠

**S18.** Dos transacciones sobre el mismo pedido en MongoDB y en PostgreSQL: qué hace cada motor. 🟡

**S19.** ¿Qué cuesta una transacción en MongoDB, medido, y cuándo merece la pena? 🟠

### La elección

**S20.** ¿Cómo valida MongoDB el esquema, y qué hay que hacer antes de activarlo? 🟡

**S21.** `jsonb` en PostgreSQL como tercera vía: qué se midió con el índice GIN y el `CHECK`. 🟡

**S22.** ¿Cuándo relacional, cuándo `jsonb` y cuándo documental? 🔴

---

## 3. 🧠 Las que descolocan

**S23.** «Si el dato es JSON, va en una base documental». Corrígelo. 🟡

**S24.** «En MongoDB no hay joins ni transacciones». ¿Qué parte es cierta? 🟠

**S25.** «DocumentDB es MongoDB gestionado por AWS». ¿Qué habría que comprobar antes de creerlo? 🟠

**S26.** «Con `w: majority` nunca se pierde una escritura ni se duplica». Refútalo. 🔴

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa es **que el
modelo salga de cómo se lee el dato**, y que no se proponga un motor nuevo para lo que resuelve un
índice o una validación.

### Escenario 1 — El informe que no cuadra

El informe mensual de ventas, sacado de MongoDB, da un 0,3 % menos que el de contabilidad. Otro
informe, «pedidos con `PRD-00017` en cantidad de cinco o más», da un 70 % más que el mismo informe
en PostgreSQL. Ninguno de los dos registra errores.

**Entregas:** la causa más probable de cada desviación y la consulta que la confirma; la corrección
de cada consulta; qué pondrías en la colección para que la primera no vuelva a pasar; y cómo
comprobarías en adelante que los dos motores cuadran.

### Escenario 2 — El historial que ya no cabe

Un servicio guarda el historial de estados de cada pedido dentro del documento, con un `$push` por
cambio. Tras dos años, unos pocos pedidos empiezan a fallar con el error de que el documento
resultante pasa de 16 777 216 bytes. Además, el panel que enseña «los eventos de la última hora»
tarda cada vez más.

**Entregas:** por qué fallan solo unos pocos y cómo los encontrarías; el rediseño del historial, con
el patrón que usarías y lo que cuesta; cómo harías la migración sin parar el servicio; y qué índice
o estructura sirve al panel de la última hora.

### Escenario 3 — Consistencia en el panel de operaciones

El panel de operaciones lee de los secundarios para no cargar el primario, y enseña a veces pedidos
en un estado que ya cambió. El equipo ha puesto `w: "majority"` con un tiempo de espera, y un
servicio que reintenta las escrituras que dan error de replicación está duplicando movimientos de
stock.

**Entregas:** la causa de cada síntoma, con lo que se vio en la sesión; qué lectura usarías para el
panel y para la pantalla que enseña un pedido justo después de cambiarlo; cómo harías el reintento
sin duplicar; y cuándo metería una transacción.

### Escenario 4 — «Pasemos a MongoDB, que es más rápido»

La tienda tarda en su panel de ventas por país y en la ficha de algunos productos con atributos
variables. Un arquitecto propone migrar todo a MongoDB «porque es más rápido y no tiene esquema».
Este escenario tiene truco: **la respuesta correcta empieza por decir que esto no lo resuelve
cambiar de base de datos**, y sigue por decir qué lo resuelve.

**Entregas:** por qué ni el panel ni la ficha piden otro motor, con los números del bloque; qué
harías en PostgreSQL para cada uno —el índice, el `jsonb`, la validación—; en qué caso sí
propondrías una base documental; y qué perdería la tienda con la migración entera.

> **⚠️ Advertencia.** Aceptar el marco —*«MongoDB es más rápido»*— es el fallo que más caro sale
> aquí: el `JOIN` del panel tardó 28 ms frente a los 472 del `$lookup`, y la ficha con atributos
> variables cabe en una columna `jsonb` con índice GIN. Se espera que midas antes de migrar.

---

## 5. 💡 Las frases que hay que tener listas

- «El documento gana en localidad y en escribir el agregado de una vez, no en milisegundos.»
- «Sin esquema no existe: está en la tabla, o en el código de cada servicio que escribe.»
- «`$sum` ignora lo que no es número; sin validación, el informe está mal y nadie se entera.»
- «Dos condiciones sobre una lista, sin `$elemMatch`, se cumplen en elementos distintos.»
- «`$lookup` es un bucle de búsquedas, no un *join* planificado.»
- «Se incrusta lo que se lee siempre con su padre y tiene tope; lo demás se referencia.»
- «Los 16 MiB no se alcanzan de golpe: se alcanzan con un `$push` normal.»
- «En un índice compuesto, el orden de los campos decide si se ordena en memoria.»
- «Si `w: majority` da error por tiempo, la escritura ya está hecha: reintentar a ciegas duplica.»
- «Leer del secundario da datos viejos; `majority` puede ir por detrás incluso en el primario.»
- «MongoDB tiene transacciones, en conjunto de réplicas, y el reintento es del cliente.»
- «Compatible con la API significa que el driver conecta; lo que se ejecuta hay que comprobarlo.»
- «Esto no lo resuelve cambiar de base: lo resuelve un índice, un `jsonb` y una validación.»

---

**Anterior:** [`05`](05-documental-relacional-o-jsonb.md) — documental, relacional o `jsonb` ·
**Siguiente:** [`07`](07-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
