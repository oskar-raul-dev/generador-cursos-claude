# 06 — Simulación de entrevista

> Las preguntas de los seis labs, mezcladas y sin orden temático, como en una entrevista real.
> Veinticuatro transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los labs. **Asume hechos:** los seis labs, de
> [`l00`](l00-el-entorno-y-los-datos.md) a [`l05`](l05-los-otros-modelos.md). **Vigencia:** 24 de
> septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. Este bloque tiene una ventaja que los demás no tienen: **cada
respuesta puede empezar por «lo hice, y pasó esto»**. En una entrevista, *«provoqué un interbloqueo
y leí las dos sentencias en el registro del servidor»* vale más que la definición de interbloqueo.

- **Cronómetro a dos minutos por pregunta.** Y una regla de este bloque: **cada respuesta con su
  orden o su consulta**. No «miraría los bloqueos», sino «`pg_blocking_pids()` en
  `pg_stat_activity`».
- **En voz alta.** Los errores se recuerdan diciéndolos con su mensaje: *«`recovery ended before
  configured recovery target was reached`: faltaba un segmento de WAL»*.
- **Sin mirar los labs.** Cuando no recuerdes una bandera, di qué hace: *«la opción de
  `pg_basebackup` que pide el checkpoint inmediato»*. Eso basta.
- **Después, contra [`07`](07-respuestas.md).** Busca si diste la orden, el síntoma y el porqué.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿dónde lo viste?»**: el
> prompt de `psql`, `pg_stat_activity`, el registro del servidor, el `explain`. Un lab es sobre todo
> saber dónde mirar.

---

## 2. 🧠 Transversales

### El entorno

**S1.** ¿Por qué el corpus genera los datos en PostgreSQL y los exporta a los demás motores? 🟢

**S2.** ¿Qué te dice `password authentication failed` de PostgreSQL, y qué no? 🟡

**S3.** Un `up -d` responde `Recreate` en tres contenedores. ¿Perdiste los datos? 🟢

**S4.** ¿Por qué un plan del corpus puede darte otro `rows=` con los mismos datos, y qué tiene que
coincidir? 🟠

---

### Índices y planes

**S5.** ¿Qué dos números defienden un índice, y cuánto dieron en el lab? 🟢

**S6.** ¿Por qué un `OR` entre dos columnas necesita un índice por rama? 🟡

**S7.** ¿Por qué un `LIKE 'X%'` puede no usar el índice de la columna en PostgreSQL? 🟡

**S8.** Un índice parcial se usa en `psql` y deja de usarse en la aplicación. ¿Por qué? 🟠

**S9.** ¿Por qué hay que comparar dos planes en las mismas condiciones de caché? 🟠

---

### Concurrencia

**S10.** ¿Qué significa `idle in transaction`, y por qué es tan habitual en la sesión que bloquea? 🟢

**S11.** ¿Qué es `40001`, y qué tiene que hacer la aplicación al recibirlo? 🟡

**S12.** ¿Dónde se ven las dos sentencias de un interbloqueo en PostgreSQL? 🟡

**S13.** Distingue `lock_timeout`, `statement_timeout` e `idle_in_transaction_session_timeout`. 🟡

---

### Respaldo y recuperación

**S14.** ¿Qué diferencia hay entre un respaldo lógico y uno físico, con las cifras del lab? 🟢

**S15.** ¿Por qué `pg_basebackup` tardó 216 s y después 3? 🟡

**S16.** ¿Qué hace falta, además del respaldo base, para recuperar a un instante? 🟡

**S17.** ¿Por qué se restaura al lado del servidor dañado y no encima? 🟠

---

### Los demás motores

**S18.** ¿Qué es una estampida de caché, y cómo se corrigió en el lab? 🟡

**S19.** ¿Qué cifras de un `explain` de MongoDB delatan que falta un índice? 🟢

**S20.** ¿Por qué Cassandra obliga a diseñar una tabla por consulta? 🟡

**S21.** ¿En qué se diferencia una búsqueda de OpenSearch de un `WHERE`? 🟡

---

## 3. 🧠 Las que descolocan

**S22.** «Tenemos respaldo diario, así que estamos cubiertos». ¿Qué preguntas harías? 🟠

**S23.** «Para búsqueda por vectores hace falta una base especializada». Refútalo con el lab. 🟠

**S24.** «Si el índice existe y no se usa, el motor se equivoca». Da tres casos del bloque en que el
motor acertó. 🟠

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa no es que
aciertes, es **que digas qué orden correrías, qué esperas ver y qué harías con lo que salga**.

### Escenario 1 — El entorno que no reproduce

Un compañero monta el entorno del corpus en su portátil, corre los planes del bloque 03 y ninguno
coincide: los `rows=` son otros, los costes también, y en uno sale un `Gather` que el corpus no
tiene. Concluye que el corpus está mal.

**Entregas:** qué comprobarías y en qué orden —versiones, datos, parámetros, estadísticas—, con la
orden de cada comprobación; qué diferencias son normales y cuáles son un error de montaje; y qué
explica el `Gather`.

### Escenario 2 — El `DELETE` sin `WHERE` del viernes

Un viernes a las 18:07 alguien borra todos los pagos en efectivo de producción. Hay un respaldo
lógico diario de las 03:00. No hay archivo de WAL. El negocio pregunta qué se puede recuperar y
cuánto se tarda.

**Entregas:** qué se recupera con lo que hay y qué se pierde, con el RPO y el RTO de verdad; el
procedimiento para recuperar lo posible sin perder las escrituras buenas del día; y qué montarías el
lunes para que la próxima vez se pueda volver a las 18:06.

### Escenario 3 — La API que se cuelga a ratos

Una API de pedidos se queda sin responder durante minutos, varias veces al día. La base está
tranquila: CPU baja, sin consultas lentas en el registro. Reiniciar la API lo arregla.

**Entregas:** la hipótesis más probable y las dos alternativas; qué consulta harías en
`pg_stat_activity` durante el cuelgue y qué esperas ver en cada caso; la corrección en el código; y
qué parámetro del servidor pondrías como red, con qué valor.

### Escenario 4 — El pico de cada hora en punto

Cada hora en punto, la latencia de la tienda se dispara durante unos segundos y PostgreSQL recibe
cientos de consultas idénticas a la vez. El resto de la hora, la base está casi ociosa. El equipo
propone pasar a una instancia el doble de grande y añadir dos réplicas de lectura. Este escenario
tiene truco: **la respuesta correcta empieza por decir que esto no lo resuelve la base de datos**, y
sigue por decir qué capa sí.

**Entregas:** de dónde salen las consultas idénticas y por qué a la hora en punto; por qué ni la
instancia grande ni las réplicas atacan la causa; las correcciones en la capa de caché, con lo que
protege cada una; y qué parte del problema sí es de la base.

> **⚠️ Advertencia.** Aceptar el marco —*«la base no da abasto, más base»*— es el fallo que más caro
> sale aquí: la base está ociosa 59 minutos de cada hora. Se espera que nombres la caducidad
> simultánea, la estampida y las tres defensas del lab `l04`.

---

## 5. 💡 Las frases que hay que tener listas

Dichas tal cual, sin adornos. Son las que cierran una respuesta y las que hacen que la siguiente
pregunta sea mejor.

- «Mismas filas, misma forma de plan; el `rows=` depende de una muestra al azar.»
- «Un índice se defiende con dos números: cuánto baja la consulta y cuánto cuesta tenerlo.»
- «Compara dos planes en las mismas condiciones de caché, o comparas el disco.»
- «La sesión que bloquea casi nunca está trabajando: está `idle in transaction`.»
- «`40001` significa repite la transacción entera.»
- «El cliente da los números del interbloqueo; el registro del servidor da las sentencias.»
- «Un respaldo que no se ha restaurado no existe.»
- «Sin WAL continuo desde el respaldo, no hay recuperación a un instante.»
- «Se restaura al lado, se comprueba y se copia lo perdido.»
- «La caché no quita la carga: la concentra en el instante en que caduca.»
- «Dos de los cinco motores especializados eran PostgreSQL con una extensión.»
- «Esto no lo resuelve la base de datos: la base está ociosa 59 minutos de cada hora.»

---

**Anterior:** [`l05`](l05-los-otros-modelos.md) — los otros modelos · **Siguiente:**
[`07`](07-respuestas.md) — las respuestas, con las de esta simulación al final · **Volver:**
[README del bloque](README.md).
