# 07 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiséis transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los seis capítulos del bloque,
> de [`01`](01-el-modelo-clave-valor.md) a [`06`](06-dynamodb-diseno-desde-el-acceso.md).
> **Vigencia:** 27 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. Este bloque tiene una trampa propia: **las preguntas sobre Redis y
DynamoDB suelen llegar con una conclusión dentro** —«Redis es más rápido», «DynamoDB escala
infinitamente», «borra la caché al escribir y listo»— y la respuesta buena no la acepta ni la
niega: dice en qué caso es cierta, con un número, y qué se paga.

- **Cronómetro a dos minutos por pregunta.** Y la regla del bloque: **cada afirmación con su
  precio**. *«4 373 escrituras por segundo en PostgreSQL frente a 121 080 en Redis, y Redis puede
  perder el último segundo si cae la máquina»*. Sin el precio, la respuesta es un folleto.
- **En voz alta.** Los mecanismos se recuerdan diciéndolos con su efecto: *«el `DEL` devolvió cero
  porque no había nada que borrar, y el lector escribió lo viejo después»*.
- **Sin mirar los capítulos.** Cuando no recuerdes una cifra, di cómo la obtendrías: *«lo vería con
  `--return-consumed-capacity`»*, *«lo mediría con el `slowlog` a cero»*.
- **Después, contra [`08`](08-respuestas.md).** Busca si separaste el motor de la convención, y si
  dijiste qué se pierde.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿qué pasa con este dato
> si el proceso muere ahora mismo?»**. Separa la caché de los datos, el AOF del RDB, el `MULTI` del
> «todo o nada» y la cola que olvida de la que espera confirmación.

---

## 2. 🧠 Transversales

### El modelo y las estructuras

**S1.** Explica en qué es más rápido Redis que PostgreSQL y en qué no, con las cifras medidas. 🟡

**S2.** ¿Por qué `KEYS` está prohibido en producción, y qué usas en su lugar? 🟢

**S3.** El ranking de ventas: compara el `GROUP BY` de PostgreSQL con un conjunto ordenado de Redis
en tiempo, en espacio y en lo que hay que mantener. 🟠

**S4.** ¿Por qué el carrito de un cliente va en un hash y no en una cadena JSON? 🟡

**S5.** Una caché de fichas deja de caducar tras un despliegue. ¿Qué orden lo explica casi siempre?
🟠

**S6.** Distingue caducidad y desalojo, y di qué política de memoria pondrías a un Redis que guarda
sesiones. 🟡

### Atomicidad y durabilidad

**S7.** ¿Qué garantiza `MULTI … EXEC` y qué no? Compáralo con una transacción de PostgreSQL. 🟡

**S8.** ¿Cuándo usas `WATCH`, cuándo un script de Lua y cuándo basta un `HINCRBY`? 🟠

**S9.** Un script de Lua que tarda 50 ms, ¿qué le hace al resto de clientes? 🟠

**S10.** Con AOF por segundo, ¿qué se pierde si muere el proceso, y qué si cae la máquina? 🟠

**S11.** ¿Por qué un Redis solo con RDB perdió 149 498 confirmaciones al reiniciarlo? 🟠

**S12.** ¿Qué cuesta `appendfsync always`, y cuándo lo pondrías? 🟡

### Caché y colas

**S13.** Describe la carrera de *cache-aside* paso a paso y di qué la cierra de verdad. 🔴

**S14.** Las tres mitigaciones de la estampida, y el caso que ninguna de las tres cubre. 🟠

**S15.** ¿Cómo se implementa una limitación de tasa atómica en Redis, y qué defecto tiene la ventana
fija? 🟡

**S16.** Cola con `BRPOP` frente a grupo de consumidores de un *stream*: qué pasa si el consumidor
cae, y qué obliga eso a hacer. 🟠

### DynamoDB

**S17.** ¿Qué son la clave de partición y la de orden, y qué decide cada una? 🟢

**S18.** Un filtro sobre `estado` devolvió nueve pedidos y cobró cincuenta y dos. Explícalo. 🟡

**S19.** Índice local frente a global: diferencias y precio. 🟡

**S20.** ¿Cómo se produce una partición caliente con una tabla que reparte bien? 🟠

**S21.** Explica el diseño desde los patrones de acceso en cinco pasos. 🟠

**S22.** ¿Por qué el primer diseño de las líneas con `PRODUCTO#` como clave de orden perdía datos, y
cómo se evita? 🔴

---

## 3. 🧠 Las que descolocan

**S23.** «Redis es solo una caché». Corrígelo con dos ejemplos del bloque. 🟡

**S24.** «DynamoDB escala infinitamente». ¿Qué parte es cierta? 🟠

**S25.** «Si borras la clave después de escribir en la base, la caché nunca queda vieja». Refútalo.
🟠

**S26.** «DynamoDB Local sirve para probar si aguanta la carga». ¿Qué se puede probar y qué no? 🟡

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa es **que digas
qué se pierde con cada decisión** y que no propongas un motor nuevo cuando el fallo está en cómo se
usa el que hay.

### Escenario 1 — El contador de la campaña

La ficha de `PRD-00017` cuenta visitas con un `UPDATE` en PostgreSQL. En la campaña de mañana se
esperan 10 000 visitas por segundo sobre ese producto. Hoy, con 16 procesos, el techo medido es de
4 373 escrituras por segundo, y cada una tarda 3,7 ms. El equipo propone pasar el contador a Redis.

**Entregas:** por qué PostgreSQL no llega, con sus dos causas y cómo las separarías; el diseño con
Redis, con su persistencia y lo que pierde si cae la máquina; la alternativa sin segundo motor y lo
que pierde; y cuál elegirías si el contador alimenta un informe de pagos a los proveedores.

### Escenario 2 — La factura de DynamoDB

Un equipo migró los pedidos a DynamoDB con la clave de `05`: partición `cliente`, orden
`fecha_pedido`. A las tres semanas, la factura multiplica por veinte lo previsto. El panel de
operaciones enseña «pedidos por estado» y se refresca cada minuto en treinta pantallas. Además, en
cada oleada de pedidos aparecen errores de estrangulación aunque la tabla está bajo demanda.

**Entregas:** qué operación explica la factura, con la capacidad que cuesta y por qué filtrar no
ayuda; la causa de la estrangulación, si el equipo ya añadió un índice global por estado; tres
diseños para el panel con su precio; y qué habría cambiado haber escrito la tabla de patrones antes
de migrar.

### Escenario 3 — ¿DynamoDB para la tienda entera?

La dirección técnica quiere mover la tienda completa de PostgreSQL a DynamoDB «para no tener que
escalar la base nunca más». Hoy la tienda tiene un millón de pedidos al año, un equipo de datos que
saca informes nuevos cada semana y un pico de 300 pedidos por minuto.

**Entregas:** la pregunta que harías antes de opinar; tres argumentos a favor y tres en contra, con
números del bloque; qué partes sí pondrías en un almacén clave-valor y cuáles no; y tu
recomendación en una frase.

### Escenario 4 — El pedido que sigue `PAGADO`

La web enseña los pedidos desde una caché en Redis con *cache-aside* y 5 minutos de caducidad. El
servicio de envíos, al marcar un pedido `ENVIADO`, actualiza PostgreSQL y borra la clave. Varias
veces al día, un cliente ve su pedido `PAGADO` durante minutos después de recibir el correo de
envío. El equipo propone pasar Redis a `appendfsync always`, añadir una réplica y subir la
memoria. Este escenario tiene truco: **la respuesta correcta empieza por decir que esto no lo
resuelve la base de datos**, y sigue por decir qué capa sí.

**Entregas:** por qué ninguna de las tres propuestas toca la causa; la secuencia exacta que deja el
valor viejo, con el dato que lo delata; tres correcciones de la más barata a la más robusta; y qué
necesita la fila de `pedidos` para la corrección que cierra el problema del todo.

> **⚠️ Advertencia.** Aceptar el marco —*«pongo `always` y una réplica»*— es el fallo que más caro
> sale aquí: Redis no perdió nada, y la base tiene el valor correcto. Se espera que nombres la
> carrera entre el lector y el escritor, el `DEL` que devuelve cero, la caducidad como límite del
> daño y la escritura condicionada a la versión.

---

## 5. 💡 Las frases que hay que tener listas

Dichas tal cual, sin adornos.

- «Leer por clave con la página en caché es barato en PostgreSQL; lo que no escala es escribir
  muchas veces la misma fila.»
- «Redis ejecuta las órdenes de una en una: por eso `INCR` es atómico, y por eso un script largo
  para a todo el mundo.»
- «`MULTI` aísla, no deshace.»
- «Con AOF por segundo, matar el proceso no pierde nada; el segundo que se pierde es el de la
  máquina.»
- «Solo RDB pierde todo desde la última instantánea, aunque cada `INCR` respondiera con su número.»
- «Una caché es una copia; la caducidad acota cuánto tiempo miente.»
- «Borrar después de escribir no basta: el lector puede escribir lo viejo después de tu borrado.»
- «Una clave caliente necesita que solo uno la regenere; mil claves creadas juntas necesitan no
  caducar juntas.»
- «En DynamoDB, filtrar no ahorra lectura: se paga lo leído.»
- «La escala de DynamoDB es la del valor más popular de la clave de partición.»
- «En DynamoDB se diseña desde las preguntas; si no las tienes escritas, empieza por PostgreSQL.»
- «Esto no lo resuelve la base de datos: la base tiene el valor bueno, y la caché lo tapó.»

---

**Anterior:** [`06`](06-dynamodb-diseno-desde-el-acceso.md) — DynamoDB: diseño desde el acceso ·
**Siguiente:** [`08`](08-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
