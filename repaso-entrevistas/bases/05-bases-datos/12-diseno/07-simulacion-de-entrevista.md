# 07 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiséis transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los seis capítulos del bloque,
> de [`01`](01-elegir-motor.md) a [`06`](06-paginacion-y-busqueda-de-texto.md). **Vigencia:** 27 de
> septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. Las preguntas de diseño llegan casi siempre como una pizarra en
blanco —«diseña las tablas de…», «¿qué base usarías para…?»— y la respuesta buena **empieza por la
pregunta que hace el negocio, elige el mecanismo que la contesta y dice lo que cuesta**.

- **Cronómetro a dos minutos por pregunta.** Y la regla del bloque: **cada decisión con su precio**.
  *«Clave temporal, a cambio de rangos en las consultas y `btree_gist`»* es una respuesta; *«lo
  guardaría con historial»*, no.
- **En voz alta.** Las trampas se recuerdan diciéndolas con su síntoma: *«el `SET` se quedó en la
  conexión y la siguiente petición vio España»*.
- **Sin mirar los capítulos.** Cuando no recuerdes una cifra, di cómo la verías: *«lo miraría en el
  plan, con el rol de la aplicación»*.
- **Después, contra [`08`](08-respuestas.md).** Busca si dijiste el precio, y si separaste lo del
  estándar, lo del motor y lo que es convención de diseño.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿qué pregunta hace el
> negocio?»**. «¿Quién lo cambió?» es auditoría y «¿cuánto valía?» es historial; «¿cuándo pasó?» es
> un instante y «¿a qué hora en la tienda?» es una hora local; «dame los siguientes» es una clave y
> «ve a la página 3» es un desplazamiento.

---

## 2. 🧠 Transversales

### Elegir motor

**S1.** ¿Por qué el curso empieza por una base relacional, y cuándo no? 🟢

**S2.** ¿Qué preguntas harías antes de aceptar un motor nuevo en la arquitectura? 🟡

**S3.** El contador de visitas de un producto en campaña no aguanta. ¿Qué harías antes de añadir
Redis? 🟠

**S4.** ¿Qué cuesta un motor más que no aparece en ningún benchmark? 🟡

### Identidad y claves

**S5.** ¿Clave natural o sustituta para `clientes`, y qué haces con el correo? 🟢

**S6.** ¿Por qué no es un argumento contra la clave natural el tamaño del índice? 🟠

**S7.** ¿Qué revela un entero en la URL, y qué revela un UUIDv7? 🟡

**S8.** ¿Por qué un UUID en la URL no es un control de acceso? 🟠

### Fechas y dinero

**S9.** ¿Qué columna para un pedido, un cupón y una recogida en tienda? 🟢

**S10.** ¿Por qué sumar un día no es sumar 24 horas? 🟡

**S11.** ¿Por qué una cita futura no se guarda en UTC? 🟠

**S12.** ¿Qué tres reglas sigue una columna de dinero? 🟡

### El pasado de los datos

**S13.** Distingue borrado lógico, auditoría e historial por la pregunta que contestan. 🟢

**S14.** ¿Qué rompe el borrado lógico en las restricciones, y cómo se arregla? 🟠

**S15.** ¿Qué es una clave temporal, y qué no tiene PostgreSQL que sí tiene MariaDB? 🟡

**S16.** ¿Por qué el borrado lógico no cumple con borrar datos personales? 🟡

### Inquilinos

**S17.** ¿Cuáles son los tres modelos multi-inquilino, y qué cuesta cada uno? 🟢

**S18.** ¿Quién se salta la seguridad a nivel de fila? 🟡

**S19.** ¿Cómo provoca un pool una fuga entre inquilinos? 🟠

### Paginación y búsqueda

**S20.** ¿Por qué `OFFSET` se vuelve lento, y qué lo sustituye? 🟡

**S21.** ¿Cuándo basta la búsqueda de texto de PostgreSQL? 🟠

---

## 3. 🧠 Las que descolocan

**S22.** «Una política de fila no cambia el rendimiento: solo añade un filtro». Refútalo con la
sesión. 🔴

**S23.** «Con `double` y un redondeo al mostrar, el dinero cuadra». ¿Qué parte es cierta? 🟠

**S24.** «La auditoría ya nos da el historial de precios». Refútalo. 🟠

**S25.** «Con `OFFSET` y un índice, cualquier página es rápida». Refútalo con números. 🔴

**S26.** «MongoDB es más rápido que PostgreSQL». ¿Qué parte es cierta? 🟡

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa es **que cada
decisión lleve su precio**, y que no se proponga un motor nuevo para lo que resuelve una columna, un
índice o una regla escrita.

### Escenario 1 — La plataforma de tiendas

La tienda se convierte en plataforma: mil quinientas tiendas pequeñas y dos grandes, una de ellas un
banco con requisitos de auditoría, que exige que sus datos no compartan base con nadie. Los clientes
finales consultan sus pedidos por una API pública.

**Entregas:** el modelo de separación de inquilinos y por qué; las claves de `clientes` y `pedidos`
y el identificador que sale a la API; cómo impides que una petición vea los datos de otra tienda,
con las dos trampas que conoces; y qué cuesta una migración de esquema en tu diseño.

### Escenario 2 — El precio de marzo

Un cliente reclama que un pedido de marzo se le cobró a 129,90 y el producto «siempre costó 119,90».
Contabilidad quiere saber qué precio estaba vigente ese día; cumplimiento, quién lo cambió y cuándo.
Hoy la tabla `productos` tiene una columna `precio` que se actualiza en el sitio, y una columna
`borrado` para los productos retirados.

**Entregas:** qué se puede contestar hoy y qué no; el diseño que contesta las dos preguntas, con el
mecanismo de cada una; qué cuesta cada mecanismo; y qué harías con los productos retirados.

### Escenario 3 — La app que se atasca

La app de la tienda tiene un listado de productos con desplazamiento infinito que se vuelve lento a
partir de unas doscientas páginas y a veces repite productos, y un buscador que no encuentra
«auricular» cuando el catálogo dice «auriculares». El equipo propone pasar el catálogo a MongoDB y
el buscador a Elasticsearch en el mismo proyecto.

**Entregas:** la causa de cada síntoma; qué arreglarías sin cambiar de motor, con las cifras del
bloque; cuál de las dos propuestas aceptarías, en qué condiciones y a qué precio; y cuál no, y por
qué.

### Escenario 4 — «Los plazos no cuadran: cambiemos a una base con decimales exactos»

Los pagos en tres plazos de la tienda no suman el total del pedido: en uno de cada tres pedidos
falta o sobra un céntimo. La propuesta es migrar a un motor «con aritmética decimal exacta». Este
escenario tiene truco: **la respuesta correcta empieza por decir que esto no lo resuelve la base de
datos**, y sigue por decir qué lo resuelve.

**Entregas:** por qué la base no es la causa, con el tipo de la columna; dónde está el fallo; la
regla que lo arregla y dónde se escribe; y qué comprobarías para saber que no hay otros céntimos
perdidos.

> **⚠️ Advertencia.** Aceptar el marco —*«el motor redondea mal»*— es el fallo que más caro sale
> aquí: `numeric` ya suma exacto, y 33,33 × 3 da 99,99 en cualquier motor del mundo. El céntimo lo
> pierde el algoritmo de reparto, no el tipo.

---

## 5. 💡 Las frases que hay que tener listas

- «Se empieza por el relacional y se añade un motor cuando una forma de acceso lo pide, medido.»
- «Cada motor más es otra copia, otro respaldo, otros permisos y otra guardia.»
- «La clave primaria es sustituta; la natural va en un `UNIQUE`.»
- «Un UUID no es un permiso: se comprueba la propiedad en cada petición.»
- «Lo que ya pasó es un instante; lo que pasará en una ciudad es una hora local con su zona.»
- «El dinero, exacto, con su moneda y con el redondeo escrito en un solo sitio.»
- «Al repartir, el último lleva la diferencia.»
- «Borrado lógico, auditoría e historial contestan tres preguntas distintas.»
- «Con borrado lógico, los `UNIQUE` pasan a ser índices parciales.»
- «La aplicación no entra con un rol que se salte la seguridad de fila.»
- «El inquilino se fija con `SET LOCAL`, nunca con `SET`.»
- «`OFFSET` lee todo lo que se salta; la clave salta directamente.»

---

**Anterior:** [`06`](06-paginacion-y-busqueda-de-texto.md) — paginación y búsqueda de texto ·
**Siguiente:** [`08`](08-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
