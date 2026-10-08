# 07 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiocho transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los seis capítulos del bloque,
> de [`01`](01-que-resuelve-un-dbms.md) a [`06`](06-nulos-y-logica-de-tres-valores.md).
> **Vigencia:** 20 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. La diferencia está en que aquí **se responde hablando**, y eso es lo
que falla en la entrevista real aunque te sepas el tema.

- **Cronómetro a dos minutos por pregunta.** Si a los treinta segundos no has dicho la frase que
  resume tu respuesta, empieza otra vez. La capa ⏱️ del solucionario es exactamente eso: lo que
  dices primero.
- **En voz alta, no mentalmente.** Explicar `NULL` por dentro de tu cabeza sale perfecto siempre.
- **Sin mirar los capítulos.** Cuando no sepas algo, dilo y sigue: *"la cláusula exacta del estándar
  no la tengo; lo que sí sé es que los tres motores lo hacen así"* es una respuesta profesional y
  completa. Inventarse la cláusula es lo que te cuesta el puesto.
- **Después, contra [`08`](08-respuestas.md).** No busques coincidencia palabra a palabra: busca si
  dijiste el mecanismo, si nombraste el precio y si distinguiste estándar de motor.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco.** Cuando una pregunta empiece por "¿es verdad que…?", la respuesta casi nunca es sí o
> no: es *"depende de si hablamos del estándar, de tu motor o de lo que se repite en el gremio"*.
> Esa frase, dicha con naturalidad, vale más que la mitad del temario.

---

## 2. 🧠 Transversales

### Modelo, claves e identidad

**S1.** ¿Qué es una clave candidata, y cuántas tiene `clientes` en este esquema? 🟢

**S2.** El esquema guarda `id` y `codigo` en todas las tablas. Explica por qué las dos, y cuál de
las dos expondrías en la URL de una API. 🟠

**S3.** `pedido_lineas` tiene clave primaria `(pedido_id, linea)`. ¿Qué te dice eso sobre la
identidad de una línea, y qué nombre recibe esa clase de entidad? 🟡

**S4.** Un compañero propone cambiar la clave primaria de `pedidos` de `id` a `codigo`, "que ya es
único y además significa algo". Da tres consecuencias concretas, con números si puedes. 🔴

**S5.** ¿Declarar una clave crea un índice? ¿Lo manda el estándar o lo decide cada motor? 🟠

---

### Normalización y el dato duplicado a propósito

**S6.** `pedidos.total` duplica lo que se puede calcular desde `pedido_lineas`. ¿Qué forma normal
viola, y por qué está ahí de todas formas? 🟡

**S7.** `pedido_lineas.precio_unit` también parece duplicar `productos.precio`. ¿Por qué esa sí es
legítima y la anterior es una concesión? 🟠

**S8.** ¿Las formas normales las fija ISO/IEC 9075? 🟡

**S9.** Escribe la consulta que detecta si algún `pedidos.total` se ha desincronizado, y di cada
cuánto la correrías y por qué. 🔴

**S10.** Guardar `jsonb` en `eventos_pedido.carga`, ¿viola la primera forma normal? 🟠

---

### Nulos

**S11.** ¿Por qué `NULL = NULL` no es verdadero? 🟢

**S12.** `pagos.referencia` es `UNIQUE` y hay 273 126 filas con el valor nulo. ¿Por qué no chocan
entre sí? 🟡

**S13.** Un informe con `NOT IN (SELECT referencia FROM pagos …)` devuelve cero filas y nadie
entiende por qué. Diagnostica en voz alta y da la corrección. 🔴

**S14.** Diferencia entre `COUNT(*)` y `COUNT(referencia)` sobre `pagos`, con los dos números. 🟢

**S15.** ¿Dónde coloca cada motor los nulos en un `ORDER BY … ASC`, y cómo escribes un orden que se
comporte igual en los cuatro? 🟠

---

### Integridad y el modelo ER

**S16.** `pedido_lineas` y `eventos_pedido` tienen `ON DELETE CASCADE`; `pagos` no. ¿Es un olvido?
Defiende la asimetría. 🟠

**S17.** ¿Qué devuelve `PRAGMA foreign_keys` en una conexión nueva de SQLite, y qué implica para una
suite de pruebas? 🟡

**S18.** ¿Qué diferencia hay entre `NO ACTION` y `RESTRICT`? 🟠

**S19.** Escribe el DDL de una relación N:M con atributos propios, y di por qué `pedido_lineas` no
lleva `UNIQUE (pedido_id, producto_id)`. 🔴

---

### Álgebra, consulta y motor

**S20.** Traduce a SQL el anti-join del álgebra relacional, y di qué nodo esperas ver en el plan. 🟡

**S21.** ¿Por qué `NATURAL JOIN clientes, pedidos` devuelve cero filas en este esquema? 🟠

**S22.** ¿Qué significa que SQL sea declarativo, y cuál es el modo de fallo típico de esa propiedad?
🟡

---

## 3. 🧠 Las que descolocan

Las que no se responden con la definición, y donde se nota quién entendió el mecanismo.

**S23.** *"Si uso transacciones, no puedo perder una actualización."* Rebate con un caso concreto en
el que todo funciona correctamente y el dato acaba mal. 🟠

**S24.** El `COMMIT` te respondió `ROLLBACK`. ¿Qué pasó, y en qué motor estás? 🟠

**S25.** ¿Por qué el planificador prefiere leer un millón de filas antes que bajar por un índice
para devolver sesenta mil? Explícalo sin usar la palabra "optimización". 🟠

**S26.** Insertaste una fila, falló por una restricción, y el siguiente identificador generado da un
salto. ¿Es un fallo? ¿Qué implica para un número de factura? 🟡

**S27.** *"Probamos contra SQLite porque es más rápido y el SQL es el mismo."* Da tres diferencias
que harían pasar en verde una prueba que en producción falla. 🔴

**S28.** Te dicen que el estándar SQL obliga a que `REPEATABLE READ` evite las lecturas fantasma.
Responde. 🔴

---

## 4. 🔭 Escenarios

Aquí no se responde: se diseña y se defiende. Diez minutos cada uno, en voz alta y dibujando.

### Escenario 1 — Las devoluciones

La tienda va a aceptar devoluciones parciales: de un pedido de tres líneas se puede devolver una, o
media cantidad de una. Contabilidad necesita saber en todo momento cuánto se cobró y cuánto se
devolvió, y quiere que el histórico nunca se reescriba.

**Entregas:** el DDL de las tablas nuevas, con sus restricciones y sus acciones referenciales; y la
respuesta a tres preguntas: si `pedidos.total` debe reflejar la devolución o no, qué haces con
`pedido_lineas.precio_unit` cuando el producto ya cambió de precio, y qué impide que se devuelva más
cantidad de la comprada.

### Escenario 2 — El informe que devuelve cero

Conciliación corre cada noche una consulta que lista los pagos del proveedor que no tienen pedido
asociado. Llevaba meses devolviendo filas. Desde la semana pasada devuelve **cero**, y nadie ha
tocado el código. La tabla `pagos` tiene 820 000 filas y 273 126 de ellas tienen `referencia` nula.

**Entregas:** tres hipótesis en orden de probabilidad, la consulta que confirma o descarta la
primera, la corrección, y una regla general para que la misma clase de error no vuelva.

### Escenario 3 — El revisor y la columna redundante

Estás en la revisión de un diseño. El revisor marca `pedidos.total` como error: *"eso se calcula, no
se guarda; estás violando la tercera forma normal y te vas a desincronizar"*. Tiene razón en lo
segundo.

**Entregas:** la defensa en dos minutos, con el número que la sostiene —el agregado sobre 300 000
pedidos lee 10 770 páginas leyendo `total` y 39 937 recalculando por `JOIN`—; qué le concedes; y qué
tres cosas te comprometes a poner en el diseño para que la concesión sea defendible dentro de un
año.

### Escenario 4 — El botón pulsado dos veces

Soporte reporta que algunos clientes aparecen cobrados dos veces. El equipo de front dice que el
usuario pulsa "pagar" dos veces cuando la respuesta tarda. Tu jefe te pide que **lo arregles en la
base de datos**.

**Entregas:** qué puede hacer la base de datos y qué no; por qué un `UNIQUE` sobre `pagos` es
necesario pero no suficiente; y dónde vive la solución de verdad. Este escenario tiene truco: **la
respuesta correcta empieza por decir que esto no lo resuelve la base de datos**, y sigue explicando
qué sí aporta y por qué aun así merece la pena ponerlo.

> **⚠️ Advertencia.** Aceptar el marco de la pregunta —*"lo arreglo con un `UNIQUE` y ya"*— es el
> fallo que más caro sale en una entrevista de Tech Lead. Se espera que discutas el encuadre, no
> solo que resuelvas lo que te piden.

---

## 5. 💡 Las frases que hay que tener listas

Dichas tal cual, sin adornos. Son las que cierran una respuesta y las que hacen que la siguiente
pregunta sea mejor.

- «Una regla que está en el código se cumple donde pasa ese código. Una regla que está en el esquema
  se cumple siempre.»
- «El motor impide que la fila se corrompa. Que el número sea el correcto cuando dos transacciones
  la tocan a la vez es otra garantía, y hay que pedirla por su nombre.»
- «`NULL` no es un valor: es la ausencia de información. Por eso no se compara con `=`, y por eso
  varios `NULL` conviven bajo un `UNIQUE`.»
- «Eso depende de si hablamos del estándar, de PostgreSQL o de lo que se repite en las entrevistas.»
- «La cláusula exacta del estándar no la tengo. Lo que sí sé es que los tres motores lo hacen así.»
- «Desnormalicé a propósito, sé lo que me cuesta, y tengo la consulta que detecta la
  desincronización.»
- «Sin `ORDER BY` no hay orden. Que hasta ahora saliera ordenado es una propiedad del plan, no del
  dato.»
- «Un identificador autoincremental no es un contador: tiene huecos por diseño, así que no sirve
  como número de factura.»
- «Probar contra otro motor del que corre en producción es probar otra cosa.»
- «Esto no lo resuelve la base de datos. Lo que la base de datos aporta aquí es la última red, y te
  digo cuál.»

---

**Anterior:** [`06`](06-nulos-y-logica-de-tres-valores.md) — nulos y lógica de tres valores ·
**Siguiente:** [`08`](08-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
