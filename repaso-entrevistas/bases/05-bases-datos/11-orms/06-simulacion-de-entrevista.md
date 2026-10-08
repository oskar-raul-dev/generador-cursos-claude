# 06 — Simulación de entrevista

> Las preguntas de este bloque, mezcladas y sin orden temático, como en una entrevista real.
> Veintiséis transversales y cuatro escenarios para defender en voz alta. **Método:** cronómetro a
> dos minutos, en voz alta, sin mirar los capítulos. **Asume leído:** los cinco capítulos del
> bloque, de [`01`](01-el-desajuste-y-los-dos-patrones.md) a
> [`05`](05-probar-contra-base-de-datos-real.md), y el bloque
> [`10`](../10-interfaz-con-los-lenguajes/README.md), del que salen el driver, el *pool* y la
> propagación. **Vigencia:** 24 de septiembre de 2026.

---

## 1. 🎯 Cómo se usa esto

No es un examen: es un ensayo. Este bloque tiene una dificultad propia: **las preguntas sobre ORM
suelen llegar como opiniones** —«los ORM son lentos», «con ORM no hace falta SQL»—, y la respuesta
buena no toma partido: separa lo que hace la especificación, lo que hace la biblioteca y lo que hace
el código que la usa.

- **Cronómetro a dos minutos por pregunta.** Y una regla de este bloque: **cada afirmación con su
  número**. *«53 consultas en los cuatro lenguajes»*, *«1 372 ms con `IDENTITY` frente a 157 con
  secuencia»*. Un número corrido cierra una discusión de opiniones.
- **En voz alta.** Los mecanismos de la sesión se entienden leyendo y se olvidan en la entrevista;
  se recuerdan diciéndolos con su efecto: *«la consulta fue a la base, la base devolvió el valor
  nuevo, y la sesión devolvió el objeto que ya tenía»*.
- **Sin mirar los capítulos.** Cuando no recuerdes el defecto exacto, di cómo lo comprobarías: *«no
  recuerdo si este ORM agrupa las inserciones; lo vería contando sentencias en el log del
  servidor»*. Eso es una respuesta profesional.
- **Después, contra [`07`](07-respuestas.md).** Busca si nombraste la capa —JPA, la biblioteca o el
  motor—, dónde se ve y qué cuesta la corrección.

Las preguntas van con su dificultad: 🟢 definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o
diagnóstico. **No están ordenadas.** En una entrevista tampoco.

> **💡 Truco de este bloque.** La pregunta que desbloquea casi todas es **«¿qué SQL llegó a la
> base?»**. El N+1, las escrituras que nadie pidió, las cargas lentas y los datos viejos se
> distinguen mirando el log del servidor, no el código.

---

## 2. 🧠 Transversales

### La sesión y sus patrones

**S1.** Explica el mapa de identidad y el dato viejo que puede producir, con lo que se vio al
correrlo. 🟡

**S2.** Compara el `UPDATE` que generan Hibernate y SQLAlchemy al cambiar una sola columna, y di qué
riesgo tiene el primero. 🟡

**S3.** Dos peticiones a un servicio en Go con GORM editan el mismo pedido y una de las dos pierde
su cambio. Da el mecanismo y la corrección. 🟠

**S4.** ¿Qué es *Open Session in View*, qué valor trae en Spring Boot y qué pasa al apagarlo? 🟠

**S5.** Una entidad cargada por Hibernate se modifica sin querer en una función de formato. ¿Qué
ocurre al confirmar, y cómo lo detectarías? 🟠

---

### El N+1 y la carga

**S6.** Define el N+1 y di cuántas consultas dio en el corpus y dónde se contaron. 🟢

**S7.** Nombra las cuatro correcciones del N+1 y di cuál elegirías para un listado de solo lectura.
🟡

**S8.** ¿Por qué aparece el N+1 en GORM y Drizzle, que no tienen carga perezosa? 🟡

**S9.** ¿Qué carga Hibernate al leer una entidad con un `@ManyToOne` sin `fetch` declarado, y por
qué? 🟢

**S10.** En local, una página con N+1 responde en 90 ms. ¿Por qué no es tranquilizador? 🟠

---

### Constructores y cargas

**S11.** ¿Qué da un constructor de consultas que no dan ni el ORM ni el SQL en una cadena? 🟡

**S12.** «JPA no hace funciones de ventana». Responde con precisión. 🟡

**S13.** Elige la herramienta para cada tarea: la ficha editable de un pedido, el informe mensual de
un cliente, la carga nocturna de eventos y el paso de mil pedidos de un estado a otro. 🟠

**S14.** ¿Por qué la clave `IDENTITY` hace lenta una carga con Hibernate y no con SQLAlchemy? 🟠

**S15.** ¿Qué límite tiene un `INSERT` de muchas filas en PostgreSQL, y cómo se reconoce su error?
🟡

**S16.** Ordena por velocidad las formas de cargar 10 000 filas medidas en el bloque, con sus
cifras. 🟢

---

### Probar

**S17.** ¿Por qué no probarías el acceso a datos contra H2? Da dos diferencias corridas. 🟡

**S18.** ¿Qué hace Testcontainers, y cuánto cuesta? 🟢

**S19.** ¿Por qué SQLite en memoria miente distinto según la biblioteca que lo abra? 🟡

**S20.** ¿Qué no aísla deshacer la transacción al final de cada prueba? 🟠

---

### Transversales al bloque

**S21.** ¿Qué parte de lo visto en este bloque es de JPA, qué parte de Hibernate y qué parte del
motor? Da un ejemplo de cada una. 🟡

**S22.** Diseña cómo atraparías en la integración continua el N+1 y las escrituras que nadie pidió,
antes de que lleguen a producción. 🔴

---

## 3. 🧠 Las que descolocan

**S23.** «Con un ORM no hace falta saber SQL». Refútalo con tres ejemplos del bloque. 🟠

**S24.** «El ORM hace el código portable entre bases de datos». ¿Qué parte es cierta? 🟡

**S25.** «Si las pruebas pasan, el SQL está bien». ¿Cuándo es falso? 🟠

**S26.** «La caché de primer nivel es una optimización de rendimiento». Corrígelo. 🟡

---

## 4. 🔭 Escenarios

No se responden de memoria: se piensan en voz alta y se defienden. Lo que se evalúa no es que
aciertes, es **que distingas qué hace la especificación, qué la biblioteca, qué tu código y qué el
motor**, y que no propongas cambiar el motor cuando el fallo está en la sesión.

### Escenario 1 — La ficha de cliente que tarda cuatro segundos

Un servicio Spring Boot con JPA enseña la ficha de un cliente con sus pedidos y las líneas de cada
uno. Con clientes nuevos tarda 60 ms; con los antiguos, cuatro segundos. No hay errores. El equipo
ha subido el *pool* de 10 a 40 y ha pedido un índice en `pedido_lineas`.

**Entregas:** la hipótesis más probable y cómo la confirmarías con el log del servidor; qué papel
juega `spring.jpa.open-in-view` y dónde se estarían lanzando las consultas; la corrección, por
consulta y no por mapeo; y por qué ni el *pool* ni el índice atacan la causa.

### Escenario 2 — La carga nocturna de tres horas

Un proceso nocturno con Hibernate inserta un millón de eventos de pedido cada noche. Tarda tres
horas y empieza a pisar la ventana de mantenimiento. La entidad usa `GenerationType.IDENTITY`, y
alguien ya subió `hibernate.jdbc.batch_size` a 1 000 sin efecto.

**Entregas:** por qué el cambio no hizo nada; las tres alternativas medidas en el bloque, con su
orden de magnitud; cuál elegirías y qué pierdes con ella —identificadores, validaciones, eventos del
ORM—; y cómo harías la carga reanudable si se corta a mitad.

### Escenario 3 — El monolito que prueba contra H2

Un monolito Java de ocho años tiene 1 200 pruebas de acceso a datos contra H2 en modo PostgreSQL.
En el último trimestre hubo tres incidentes que las pruebas no vieron: un orden distinto en un
listado, un upsert reescrito como «leer y después escribir» porque H2 no lo aceptaba, y una
consulta que en producción no usa el índice.

**Entregas:** cuál de los tres incidentes habría atrapado Testcontainers y cuál no, y por qué; cómo
organizarías la suite —contenedores, esquema, aislamiento—; qué pruebas migrarías primero; y qué
harías con el SQL que se escribió para que H2 lo aceptara.

### Escenario 4 — El estado que no cambia

Una aplicación de escritorio de operaciones, con Hibernate, mantiene una sesión abierta mientras el
operador trabaja. Otro servicio pasa los pedidos de `PAGADO` a `ENVIADO`. El operador vuelve a
consultar la lista y sigue viendo `PAGADO`, y a veces reembolsa pedidos ya enviados. El equipo
propone subir el aislamiento a `SERIALIZABLE` y añadir un índice en `pedidos (estado)`. Este
escenario tiene truco: **la respuesta correcta empieza por decir que esto no lo resuelve la base de
datos**, y sigue por decir qué capa sí.

**Entregas:** por qué la base no tiene la culpa, con lo que se vio en el log al correrlo; de dónde
sale el valor viejo; tres correcciones en la aplicación, de la más barata a la más robusta; y qué
defensa pondrías en el propio `UPDATE` del reembolso para que un estado viejo nunca se convierta en
una decisión.

> **⚠️ Advertencia.** Aceptar el marco —*«subo el aislamiento y creo el índice»*— es el fallo que
> más caro sale aquí: la consulta **ya va a la base** y la base **ya devuelve** `ENVIADO`. Se espera
> que nombres el mapa de identidad, la duración de la sesión y el `UPDATE` condicional con sus filas
> afectadas.

---

## 5. 💡 Las frases que hay que tener listas

Dichas tal cual, sin adornos. Son las que cierran una respuesta y las que hacen que la siguiente
pregunta sea mejor.

- «El N+1 no es del ORM: es de recorrer objetos sin decir qué se va a necesitar.»
- «El número de consultas se cuenta en el servidor, no en el log de mi ORM.»
- «El mapeo dice que una asociación existe; la consulta decide si se carga.»
- «La caché de primer nivel sirve a la identidad, y su efecto secundario es el dato viejo.»
- «La sesión dura una petición. Lo que dura más, recuerda de más.»
- «JPQL no tiene ventanas ni CTE; HQL sí. Lo que no llega, va en SQL, dentro de la misma
  transacción.»
- «En Hibernate, `IDENTITY` apaga los lotes. La primera pregunta de una carga lenta es el generador
  de claves.»
- «Para cargar miles de filas, `COPY`. Para cambiar miles, un `UPDATE`. El ORM es para una entidad
  cada vez.»
- «Una prueba verde contra H2 demuestra que el código funciona contra H2.»
- «La base de pruebas es la mitad del sistema que se prueba.»
- «Esto no lo resuelve la base de datos: la base devolvió el valor nuevo, y la sesión lo tapó.»

---

**Anterior:** [`05`](05-probar-contra-base-de-datos-real.md) — probar contra una base de datos real
· **Siguiente:** [`07`](07-respuestas.md) — las respuestas, con las de esta simulación al final ·
**Volver:** [README del bloque](README.md).
