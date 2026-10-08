# 01 — Base de datos por servicio

> La regla que de verdad define un microservicio, sus excepciones honestas, y cómo se llega a ella
> desde un esquema compartido. Asume leídos
> [`01-fundamentos-y-descomposicion/01`](../01-fundamentos-y-descomposicion/01-que-es-un-microservicio.md)
> y [`04`](../01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md). La teoría de
> consistencia —CAP, PACELC, niveles de aislamiento— es de
> [`arquitectura/01-bases/03-datos`](../../01-bases/03-datos/).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Has separado `orders` e `inventory` en dos servicios, dos repositorios y dos despliegues. Pero los
dos siguen conectándose a la misma base de datos, porque separarla parecía "la parte fácil, para
después".

Y entonces llega el martes en que `inventory` necesita renombrar una columna:

```text
1. Renombrar columna               → hay que mirar si orders la usa
2. orders la usa en dos consultas → hay que coordinar dos despliegues
3. Se coordina una ventana         → el jueves a las 22:00, con las dos personas
4. A la tercera vez que pasa esto  → nadie renombra nada nunca más
```

El paso 4 es el verdadero daño: el esquema se congela. Y un esquema congelado significa que el modelo
de datos deja de seguir al negocio, que es la definición práctica de deuda técnica que no se puede
pagar.

**Un servicio que no controla su esquema no es independiente**, tenga el repositorio que tenga.

---

## 2. 🧱 La regla, y por qué es la que define el estilo

**Qué es.** Cada servicio es dueño exclusivo de su almacén: nadie más lee ni escribe en él. Quien
necesite esos datos los pide por la API o los recibe por un evento.

**Cómo va.** La regla se sostiene sobre una idea: **el esquema es un detalle de implementación**. Lo
público es el contrato de la API o del evento; las tablas son tan internas como los nombres de tus
clases privadas.

```text
Público    la API de inventario, el evento InventoryReserved
Interno    la tabla reservations, sus índices, sus columnas, su motor
```

**Con qué.** No hace falta tecnología: hace falta una credencial por servicio y que ninguna tenga
permisos sobre el esquema de otro. Ese control es el único que de verdad sostiene la regla, y es
mucho más efectivo que un documento de arquitectura.

**Cuánto.** Cuesta consultas que ya no existen —los `JOIN` cruzados—, datos duplicados que mantener,
y consistencia eventual visible. Todo eso se desarrolla en [`02`](02-consultas-entre-servicios.md) y
en [`03`](03-saga.md); no son efectos secundarios, son el precio.

**Cuándo sí.** Siempre que quieras llamar microservicio a lo que construyes.

**Cuándo no.** Durante una migración con fecha, y en los casos acotados de §4. No hay más.

> **Veredicto:** puedes tener un repositorio por servicio, un pipeline por servicio y un contenedor
> por servicio; si comparten tablas, tienes un sistema con dos procesos. La propiedad de los datos es
> lo que hace real todo lo demás.

---

## 3. 🧱 Qué se rompe exactamente al compartir

Cuatro acoplamientos distintos, y conviene nombrarlos por separado porque cada uno se arregla de otra
forma:

| Acoplamiento | Cómo se manifiesta | Qué lo arregla |
|---|---|---|
| **De esquema** | No puedes migrar sin coordinar | Separar tablas; vista contractual como puente |
| **De despliegue** | Los cambios salen juntos o no salen | Consecuencia del anterior |
| **De rendimiento** | Una consulta ajena degrada tu servicio | Réplica de lectura, o separación real |
| **De fallo** | La base se satura y caen los dos | Separación real; nada más lo arregla |

El tercero es el que más sorprende en producción: tu servicio empieza a ir lento y **no has
desplegado nada**. El informe mensual que alguien lanzó contra la misma instancia se llevó por
delante tu latencia. Es un fallo que no aparece en ninguno de tus paneles porque la causa no está en
tu código.

> **🩺 Diagnóstico:** ante un servicio que se degrada sin despliegue propio, la primera pregunta es
> quién más toca esa base. Si la respuesta tarda en llegar, ya sabes que el problema es estructural y
> no puntual.

---

## 4. ⚖️ Las excepciones honestas

Tres, y cada una con su condición de caducidad. Fuera de estas, compartir es deuda sin plan.

| Excepción | Condición | Cómo se acota |
|---|---|---|
| **Migración en curso** | Estás extrayendo un servicio y los datos aún no se separaron | Fecha de fin escrita, dueño asignado, tarea en el tablero |
| **Réplica de solo lectura para informes** | El consumo analítico no debe tocar la instancia principal | Réplica aparte, y contrato explícito: vistas, no tablas |
| **Datos de referencia** | Catálogos casi inmutables: países, divisas, tipos de producto | Un dueño que los publica; los demás los replican o los consultan |

La segunda merece un matiz que distingue a un senior: **una réplica no elimina el acoplamiento de
esquema, solo el de rendimiento**. Si el consumidor lee tus tablas de la réplica, sigues sin poder
renombrar. Por eso el contrato tiene que ser una **vista** con nombre propio y estable, que tú puedes
mantener mientras cambias lo de debajo.

> **⚠️ Advertencia:** "solo lectura" y "solo durante la migración" son las dos frases que más deuda
> permanente han generado en sistemas distribuidos. Las dos son legítimas; ninguna sobrevive sin
> fecha y sin dueño.

---

## 5. 🧱 Cómo se separa, en escalones

**Qué es.** La separación no es binaria. Hay cuatro escalones, y cada uno compra algo distinto.

```text
1. Mismo esquema, acceso por módulo    se prohíben los JOIN cruzados; duele, y es barato
2. Esquemas separados, misma instancia  cada servicio con su credencial y su espacio
3. Instancias separadas                 desaparece el acoplamiento de rendimiento y de fallo
4. Motores distintos si hace falta      solo si el perfil de acceso lo justifica
```

**Cómo va.** El escalón 1 es el más valioso y el que casi nadie hace: prohibir los `JOIN` entre
módulos **dentro del monolito**. Duele en rendimiento —donde había una consulta ahora hay dos— y ese
dolor es información: te dice el coste real de la frontera cuando todavía es gratis cambiar de idea.

El escalón 3 es el que de verdad aísla. Mientras compartas instancia, compartes CPU, memoria,
conexiones y ventana de mantenimiento, y eso significa que sigues teniendo un fallo común.

**Cuánto.** Cada escalón cuesta más dinero y más operación: instancias separadas son copias de
seguridad separadas, monitorización separada y más coste. Por eso se sube escalón a escalón y con un
motivo, no por completismo.

**Cuándo no subir al 4.** Poliglotismo de persistencia por moda. Cambiar de motor se justifica por el
patrón de acceso —clave-valor para sesiones, documental para agregados que se leen enteros, búsqueda
para texto—, nunca por currículo.

> **Veredicto:** la separación útil empieza en el escalón 1, que es gratis y enseña la verdad, y
> termina donde el aislamiento que compras deje de compensar el coste operativo que pagas.

---

## 6. 🧱 Lo que sustituye a las claves foráneas

**Qué es.** Al separar, desaparecen las garantías que daba la base de datos: claves foráneas,
transacciones que abarcan todo y consultas que cruzan.

**Cómo va.** Cada una tiene su sustituto, y la tabla es de las que conviene saber de memoria:

| Se pierde | Se sustituye por | Precio |
|---|---|---|
| Clave foránea entre servicios | Validación en el servicio dueño al crear | El dato puede quedar huérfano si el otro borra |
| Transacción que abarca todo | Saga con compensaciones ([`03`](03-saga.md)) | Consistencia eventual y estados intermedios |
| `JOIN` entre tablas de servicios | Composición o proyección ([`02`](02-consultas-entre-servicios.md)) | Latencia o duplicación de datos |
| Unicidad global | Unicidad dentro del dueño | Hay que decidir quién es el dueño de esa regla |

La fila de las claves foráneas suele generar resistencia, y la respuesta es concreta: **el referente
huérfano es un problema de negocio, no de integridad técnica**. Si `customers` borra un cliente con
pedidos, la pregunta no es cómo lo impide la base de datos, es qué debe pasar con esos pedidos — y esa
decisión es de negocio, casi nunca "borrar en cascada".

**Con qué.** En la práctica, los sistemas maduros sustituyen el borrado por **desactivación**: el
cliente se marca como inactivo y sus pedidos siguen existiendo, que es lo que el negocio quería.

---

## 7. 🧰 En las cuatro plataformas

Lo que se compara aquí no es el ORM: es **quién versiona el esquema y cuándo corre la migración**,
que es lo que decide si el servicio puede desplegarse solo.

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Mapeo objeto-relacional maduro y acceso directo por SQL cuando conviene; migraciones versionadas integradas en el arranque de la aplicación | Decidir si la migración corre al arrancar —cómodo, pero acopla despliegue y esquema— o en un paso aparte del pipeline |
| **Node/TS** | Clientes tipados que generan el acceso desde el esquema, con su propio sistema de migraciones | Que el esquema del ORM no se convierta en el contrato compartido entre servicios; y ejecutar migraciones fuera del arranque |
| **Go** | Acceso explícito por SQL y generación de código tipado desde las consultas; herramientas de migración como binario independiente | Todo el cableado. A cambio, la migración es un paso del pipeline por defecto, que es lo correcto |
| **Python** | Mapeo maduro y migraciones con generación automática de diferencias | Revisar siempre la migración generada: la diferencia automática acierta en lo fácil y se equivoca justo en lo caro |

- **Lo que te deja a ti en las cuatro:** la decisión de **dónde corre la migración**. Al arrancar la
  aplicación es lo más cómodo y lo que peor escala: con varias instancias arrancando a la vez hay que
  garantizar exclusión, y un fallo de migración se convierte en un fallo de arranque en bucle.
- La recomendación, y se dice así en una entrevista: **migración como paso explícito del pipeline,
  antes de desplegar el código nuevo, y siempre compatible hacia atrás**
  ([`05`](05-evolucion-de-esquema-y-migraciones.md)).

> **🧰 Plataforma:** el ORM no es la decisión importante de este capítulo. La importante es quién
> tiene permisos sobre qué esquema, y eso se configura en la base de datos, no en el código. Si las
> credenciales de dos servicios pueden leer las mismas tablas, la regla de este capítulo es una
> sugerencia.

---

## 8. 🧭 Cómo se elige el motor

```text
¿Qué patrón de acceso tiene este servicio?
│
├─ transaccional, relaciones, consultas variadas ──► relacional. El caso por defecto.
│
├─ se lee y escribe el agregado entero, por clave ─► documental o clave-valor
│
├─ búsqueda por texto o filtros complejos ─────────► índice de búsqueda, como
│                                                     proyección, no como fuente de verdad
│
└─ series temporales o métricas ──────────────────► almacén específico
```

Y las dos frases que conviene tener listas:

> "Relacional por defecto. Cambio de motor cuando el patrón de acceso lo justifica, no cuando el
> servicio es nuevo y apetece probar algo."

> "La persistencia políglota es una posibilidad de los microservicios, no una obligación: cada motor
> nuevo son copias de seguridad, monitorización y una guardia más que alguien tiene que saber
> atender."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Cada servicio tiene su base de datos" | Su **esquema** como mínimo, y su instancia cuando el aislamiento de rendimiento importa. Son escalones distintos con costes distintos |
| "Compartir la base para lecturas no acopla" | Acopla el esquema y el rendimiento. Una réplica quita el segundo, no el primero |
| "Sin claves foráneas se corrompen los datos" | La integridad entre servicios se valida en el dueño; el huérfano es una decisión de negocio, no un fallo técnico |
| "Cada servicio elige su motor, y eso es bueno" | Cada motor nuevo es operación, copias, monitorización y conocimiento. Se justifica por patrón de acceso |
| "Primero separamos la base y luego el código" | Al revés: se separa el acceso dentro del monolito, y después el almacén |
| "La migración corre al arrancar y ya" | Con varias instancias hace falta exclusión, y un fallo se vuelve un bucle de reinicios. Mejor paso explícito del pipeline |
| "Duplicar datos entre servicios es un antipatrón" | Duplicar sin dueño lo es. Copiar a propósito lo que el negocio quiere congelado —el precio pagado, la dirección de envío— es diseño |

---

## 📚 Para profundizar

1. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 2, sección de
   datos, y capítulo 5 completo. **El tratamiento más directo del problema de este capítulo.**
2. **Libro** — Sam Newman, *Monolith to Microservices*, O'Reilly, 2019. Capítulo 4, "Decomposing the
   Database": los patrones de separación de datos, uno a uno, con sus contraindicaciones.
3. **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017. Capítulos 5
   y 6, para replicación y particionado, que es lo que hay debajo de las excepciones de §4.
4. **Fuente primaria** — Chris Richardson, «Pattern: Database per service»:
   [microservices.io/patterns/data/database-per-service.html](https://microservices.io/patterns/data/database-per-service.html).
5. **Fuente primaria** — Chris Richardson, «Pattern: Shared database», con sus consecuencias
   declaradas:
   [microservices.io/patterns/data/shared-database.html](https://microservices.io/patterns/data/shared-database.html).
6. **Fuente primaria** — Martin Fowler, «Microservice Trade-Offs», sección de datos:
   [martinfowler.com/articles/microservice-trade-offs.html](https://martinfowler.com/articles/microservice-trade-offs.html).
7. **Charla** — GOTO Conferences, «Decomposing the Database» (Sam Newman). Es el mismo material del
   libro, con los ejemplos mejor contados.

---

## 🧠 Preguntas

1. Enuncia la regla de base de datos por servicio. 🟢
2. ¿Qué es público y qué es interno en un servicio, hablando de datos? 🟢
3. Nombra los cuatro acoplamientos que produce compartir una base. 🟢
4. ¿Cuáles son las tres excepciones honestas y qué condición tiene cada una? 🟢
5. Enumera los cuatro escalones de separación. 🟢
6. ¿Qué sustituye a una clave foránea entre servicios? 🟢
7. ¿Qué mecanismo sostiene de verdad la regla: el documento de arquitectura o los permisos? 🟢
8. ¿Por qué una réplica de lectura no elimina el acoplamiento de esquema? 🟡
9. ¿Por qué prohibir los `JOIN` cruzados dentro del monolito es un paso valioso? 🟡
10. ¿Qué acoplamiento explica que tu servicio se degrade sin haber desplegado nada? 🟡
11. ¿Por qué el borrado suele sustituirse por desactivación? 🟡
12. Diferencia entre duplicar datos por accidente y copiarlos a propósito. 🟡
13. ¿Qué cambia entre plataformas en quién versiona el esquema y cuándo corre la migración? 🟡
14. ¿Qué plataforma te ayuda más a cumplir la regla de propiedad de los datos, y por qué la pregunta
    está mal planteada? 🟡
15. Te piden acceso de solo lectura a tus tablas para un informe. ¿Qué ofreces? 🟠
16. ¿Cuándo subirías de esquemas separados a instancias separadas? 🟠
17. `customers` quiere borrar un cliente que tiene pedidos. ¿Qué diseñas? 🟠
18. ¿Dónde harías correr las migraciones y por qué? 🟠
19. Un equipo propone un motor documental para su servicio nuevo. ¿Qué preguntas? 🟠
20. ¿Cómo comprobarías, en un sistema existente, si la regla se cumple de verdad? 🟠
21. Tienes que mantener unicidad de un correo electrónico entre dos servicios. ¿Cómo lo resuelves? 🟠
22. ¿Qué datos de `catalog` copiarías dentro de `orders`, y por qué esos y no otros? 🟠
23. Diseña el plan para separar el esquema compartido de `orders` e `inventory`, con los
    escalones, lo que se despliega en cada uno y cómo se vuelve atrás. 🔴
24. Diseña el contrato de la réplica de lectura que ofrecerías al equipo de informes, incluyendo qué
    garantizas y qué no. 🔴
25. Un servicio necesita datos de otros tres para su lógica de negocio, no solo para mostrarlos.
    Analiza si la frontera está bien y propón alternativas. 🔴
26. Escribe las reglas de acceso a datos que pondrías como política del equipo, incluyendo cómo se
    verifican automáticamente. 🔴

---

**Anterior:** — · **Siguiente:** [`02` — Consultas entre servicios](02-consultas-entre-servicios.md)
· **Relacionado:** [`05` — Evolución de esquema y migraciones](05-evolucion-de-esquema-y-migraciones.md)
· [`arquitectura/01-bases/03-datos`](../../01-bases/03-datos/)

**Taller, opcional:** [`06/02` — Strangler fig con Envoy](../06-talleres/02-strangler-fig-con-envoy.md).
