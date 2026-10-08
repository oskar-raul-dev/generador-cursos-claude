# 03 — Carga, cachés y la sesión

> Qué se carga y cuándo: la carga perezosa y la ansiosa, con el valor por defecto que JPA pone donde
> menos se espera; el error de tocar una colección perezosa con la sesión cerrada, y la «solución»
> de dejar la sesión abierta durante toda la petición, que es un antipatrón con nombre propio. Y las
> dos cachés: la de primer nivel, que es el mapa de identidad y **puede devolver un dato viejo**, y
> la de segundo nivel, que es otra cosa. **Asume leído:**
> [`01`](01-el-desajuste-y-los-dos-patrones.md) —el mapa de identidad y la unidad de trabajo— y
> [`02`](02-el-problema-n-mas-1.md), que decide la carga por consulta. **Vigencia:** 24 de
> septiembre de 2026.

---

## 1. 🎯 El problema

Tres incidentes de un servicio con JPA, en la misma semana:

```text
Cargar una línea de pedido trae también su pedido, aunque nadie lo pidió.
Una respuesta JSON falla con "no session" al serializar las líneas de un pedido.
Un proceso lee el estado de un pedido, otro lo cambia, y el primero sigue viendo el viejo.
```

Los tres vienen de **la sesión**: qué carga, cuánto vive y qué recuerda. La sesión es la pieza que
hace cómodo un ORM de tipo *Data Mapper*, y la que produce sus fallos más difíciles de ver, porque
ninguno da un error de SQL.

> **📝 Contexto.** Las secciones §2 a §4 y §6 están **corridas** en Hibernate 7.4.10 y SQLAlchemy
> 2.0.54. El cambio «desde otra conexión» de §6 se compensa en el propio programa: `PED-00042` sigue
> en `PAGADO`. **No se corren** la sesión abierta en la vista de §5, que necesita Spring Boot, ni la
> caché de segundo nivel de §7, que necesita un proveedor de caché: se explican por mecanismo, con
> la documentación, y se verían con el log de SQL de Hibernate durante una petición y con sus
> estadísticas de caché.

---

## 2. 🧱 Perezosa y ansiosa, y el defecto de JPA

**Qué es:** una asociación **perezosa** se carga la primera vez que se toca; una **ansiosa**, en el
momento en que se carga la entidad que la contiene. Lo que casi nadie recuerda es que en JPA el
defecto **depende del tipo de asociación**: las colecciones, `@OneToMany`, son perezosas; las
referencias a una sola entidad, `@ManyToOne`, **ansiosas**.

```text
-- Hibernate: sesion.find(Linea.class, (42, 1)), con @ManyToOne sin fetch declarado
Hibernate: select l1_0.pedido_id,p1_0.id,p1_0.codigo,p1_0.estado,l1_0.linea,l1_0.cantidad from pedido_lineas l1_0 join pedidos p1_0 on p1_0.id=l1_0.pedido_id where (l1_0.pedido_id,l1_0.linea) in ((?,?))
```

- **Se pidió una línea y llegó con su pedido**, en un `JOIN` que nadie escribió. Con la línea es
  barato; con una entidad que tiene cinco `@ManyToOne`, cada lectura arrastra cinco tablas, y cada
  una puede arrastrar las suyas.
- **La especificación lo dice así**: el valor por defecto del atributo `fetch` de `@ManyToOne` es
  `EAGER`. Por eso la recomendación habitual es declarar **todas** las asociaciones `LAZY` y decidir
  la carga en cada consulta, con las correcciones de [`02`](02-el-problema-n-mas-1.md) §4.
- **SQLAlchemy es perezosa por defecto en las dos direcciones**, y lo ansioso se pide con opciones.

**Quién lo manda:** **JPA**, la especificación de Jakarta, para el defecto; **biblioteca** para todo
lo demás. **Cuánto cuesta:** columnas y tablas que no se usan en cada lectura. **Cuándo sí:** lo
ansioso, en una consulta que sabe que va a necesitarlo; nunca como defecto del mapeo.

> **Veredicto:** el mapeo declara que una asociación **existe**; la consulta decide si se **carga**.
> Todo lo ansioso en el mapeo es una decisión tomada para todas las consultas a la vez.

---

## 3. 🩺 La colección perezosa, con la sesión cerrada

**Qué es:** una colección perezosa necesita la sesión para cargarse. Si la sesión ya se cerró —el
servicio devolvió la entidad y otra capa la serializa—, no hay con qué:

```text
-- Hibernate
LazyInitializationException: Cannot lazily initialize collection of role 'Sesion$Pedido.lineas' with key '42' (no session)
-- SQLAlchemy
DetachedInstanceError: Parent instance <Pedido at 0xffffaddea510> is not bound to a Session; lazy load operation of attribute 'lineas' cannot proceed (Background on this error at: https://sqlalche.me/e/20/bhk3)
```

- **El error es honesto**: dice que se intentó una consulta cuando ya no había transacción ni
  conexión. El segundo incidente del §1 es exactamente esto, con el serializador de JSON recorriendo
  `lineas`.
- **Las dos correcciones buenas** son cargar lo necesario **dentro** de la sesión —con las
  correcciones de `02`— o devolver una proyección, un objeto que no es una entidad y no tiene nada
  perezoso. Las malas están en §5.

---

## 4. 🧱 La primera caché: el mapa de identidad

**Qué es:** lo de [`01`](01-el-desajuste-y-los-dos-patrones.md) §4, mirado como caché: la sesión
guarda cada entidad cargada, y dentro de ella **una fila es siempre el mismo objeto**. Es la caché
de primer nivel: vive lo que vive la sesión, es de esa sesión sola, y no se puede apagar.

| | Primer nivel | Segundo nivel (§7) |
|---|---|---|
| Qué es | El mapa de identidad de la sesión | Una caché compartida entre sesiones |
| Cuánto vive | Lo que la sesión | Lo que se configure |
| Quién la ve | Solo esa sesión | Todas las sesiones del proceso, o del clúster |
| Se puede apagar | No | Viene apagada |

**Cuánto cuesta:** memoria mientras la sesión vive, y el dato viejo de §6. **Cuándo sí:** siempre,
porque no se elige; lo que se elige es **cuánto dura la sesión**.

---

## 5. 🪦 Sesión abierta en la vista

**Qué es:** la «solución» al error de §3 que no lo resuelve: **mantener la sesión abierta durante
toda la petición HTTP**, hasta que la vista o el serializador terminan, para que cualquier colección
perezosa se pueda cargar en cualquier momento. Tiene nombre de antipatrón: *Open Session in View*.

- **Spring Boot la trae encendida por defecto**: la propiedad `spring.jpa.open-in-view` vale `true`,
  y registra un interceptor que ata la sesión al hilo durante toda la petición. Es de las primeras
  cosas que se apagan en un proyecto que se toma en serio el acceso a datos.
- **El precio es el N+1 invisible**: el serializador recorre las colecciones y cada una es una
  consulta, lanzada desde una capa que nadie mira pensando en SQL. Y la conexión queda prestada
  durante toda la petición, también mientras se escribe la respuesta: es la retención de conexiones
  de [`10/01`](../10-interfaz-con-los-lenguajes/01-el-driver-la-conexion-y-el-pool.md) §4.
- **No se corre aquí** porque el entorno no tiene Spring Boot; se vería activando el log de SQL de
  Hibernate y mirando qué consultas salen **después** de que el controlador devolvió su resultado.

> **⚠️ Advertencia.** *Open Session in View* no quita el error de §3: lo convierte en consultas
> ocultas y conexiones retenidas. Apagarlo hace aparecer el `LazyInitializationException` en cada
> sitio que dependía de él, y esos son exactamente los sitios que había que arreglar.

---

## 6. 🩺 El dato viejo

**Qué es:** el tercer incidente del §1. La sesión carga `PED-00042`; **otra conexión** lo cambia a
`ENVIADO` y confirma; y la sesión vuelve a pedirlo:

```text
-- Hibernate
Hibernate: select p1_0.id,p1_0.codigo,p1_0.estado from pedidos p1_0 where p1_0.id=?
Hibernate: select p1_0.id,p1_0.codigo,p1_0.estado from pedidos p1_0 where p1_0.id=42
tras la consulta: PAGADO (mismo objeto: true)
Hibernate: select p1_0.id,p1_0.codigo,p1_0.estado from pedidos p1_0 where p1_0.id=?
tras refresh: ENVIADO
-- SQLAlchemy, con la transacción de la sesión todavía abierta
tras la consulta: PAGADO (mismo objeto: True)
con populate_existing: ENVIADO
```

- **La consulta sí fue a la base**, y la base devolvió `ENVIADO`. Pero la sesión ya tenía ese objeto
  en su mapa de identidad, y **no lo sobrescribe**: devuelve el que tenía, con `PAGADO`. Es la
  garantía de «una fila, un objeto» cumpliéndose a costa de la frescura.
- **Para ver el dato nuevo hay que pedirlo**: `refresh` en Hibernate, `populate_existing` en
  SQLAlchemy, o cerrar la sesión y abrir otra.
- **SQLAlchemy lo evita en un caso**: al hacer `commit`, **expira** todos los objetos de la sesión
  —`expire_on_commit`, activo por defecto— y la siguiente lectura los recarga. Corrido con un
  `commit` antes del cambio, salió `ENVIADO` a la primera. Hibernate no hace eso.
- **El programa devuelve el pedido a `PAGADO`** en un `finally`, con la compensación de la regla del
  bloque 04.

**Cuánto cuesta:** decisiones tomadas con datos que ya no son: el operador que ve `PAGADO` y cobra
otra vez. **Cuándo duele:** en sesiones largas —un proceso por lotes, una sesión reutilizada entre
peticiones— y nunca en sesiones de una petición corta, que es el argumento para tenerlas cortas.

> **🧠 Modelo mental.** El mapa de identidad no es una foto de la base: es la **memoria de la
> sesión**. Lo que la sesión cargó, lo recuerda como lo cargó, aunque la base cambie detrás.

---

## 7. 🧱 La segunda caché

**Qué es:** una caché **compartida entre sesiones**, que en Hibernate se enchufa con un proveedor
—el estándar JCache con Caffeine o Ehcache detrás— y se activa entidad por entidad. Guarda el estado
de las entidades por clave primaria, y una sesión nueva puede cargar `PED-00042` sin ir a la base.

- **No se corre aquí**: el entorno no tiene proveedor de caché. Se vería con las estadísticas de
  Hibernate —aciertos y fallos de la caché de segundo nivel— y con el log de SQL, en el que una
  lectura servida desde la caché no deja consulta.
- **Su problema es el de toda caché**: si otro proceso o una consulta SQL directa cambia la fila, la
  caché no se entera. Por eso encaja con datos de referencia que casi no cambian —el catálogo de
  `productos`— y no con `pedidos`, que cambian de estado a cada rato.
- **SQLAlchemy no trae caché de segundo nivel**; la documentación la propone como receta con una
  biblioteca aparte. GORM y Drizzle, tampoco.

**Cuánto cuesta:** memoria, invalidación y datos viejos compartidos por todas las sesiones, que es
peor que el dato viejo de una. **Cuándo sí:** datos de referencia, de lectura frecuente y escritura
rara, que solo cambia la propia aplicación. **Cuándo no:** cualquier tabla que alguien actualice por
fuera del ORM.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 no habla de sesiones ni de cachés de objetos. JPA fija el
> defecto de carga; el resto es de cada biblioteca y de Spring Boot.

| Afirmación | JPA (Jakarta) | Hibernate 7.4 | SQLAlchemy 2.0 | Spring Boot |
|---|---|---|---|---|
| `@ManyToOne` es ansiosa por defecto | **Sí**, `EAGER` | Cumple JPA | Perezosa | — |
| Las colecciones son perezosas por defecto | Sí | Sí | Sí | — |
| Una consulta refresca las entidades ya cargadas | No lo exige | **No** | **No**, salvo `populate_existing` | — |
| El `commit` expira las entidades | No | No | **Sí**, `expire_on_commit` | — |
| La sesión vive toda la petición | — | — | — | **Sí**, `open-in-view = true` |
| Hay caché de segundo nivel | Opcional | Con proveedor | No: receta aparte | — |

**Convención, las dos que más se repiten.** *«La caché de primer nivel acelera las lecturas»* — su
función es la identidad, y su efecto secundario más importante es el dato viejo. Y *«el
`LazyInitializationException` se arregla con `open-in-view`»* — se esconde, a cambio de consultas
ocultas y conexiones retenidas toda la petición.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Todo en JPA es perezoso por defecto" | `@ManyToOne` es ansiosa: cargar una línea trajo su pedido en un `JOIN` |
| "Si vuelvo a consultar, veo el dato actual" | La consulta va a la base, pero la sesión devuelve el objeto que ya tenía |
| "`open-in-view` es inofensivo" | Retiene la conexión toda la petición y esconde el N+1 en la serialización |
| "El error de la sesión cerrada es un fallo de Hibernate" | Es la señal de que se intentó una consulta fuera de la transacción |
| "SQLAlchemy y Hibernate recuerdan igual" | SQLAlchemy expira todo al hacer `commit`; Hibernate no |
| "La caché de segundo nivel es gratis" | Comparte datos viejos entre todas las sesiones si alguien cambia la tabla por fuera |

---

## 📚 Para profundizar

- **Documentación** — Jakarta Persistence 3.2, `@ManyToOne`: el `fetch` y su valor por defecto.
  <https://jakarta.ee/specifications/persistence/3.2/apidocs/jakarta.persistence/jakarta/persistence/manytoone>
- **Documentación** — Hibernate ORM 7.4, «User Guide»: *fetching*, el contexto de persistencia,
  `refresh` y la caché de segundo nivel. <https://docs.hibernate.org/orm/7.4/userguide/html_single/>
- **Documentación** — SQLAlchemy 2.0, «Session Basics»: `expire_on_commit` y el ciclo de la sesión.
  <https://docs.sqlalchemy.org/en/20/orm/session_basics.html>
- **Documentación** — SQLAlchemy 2.0, «State Management»: objetos separados y `populate_existing`.
  <https://docs.sqlalchemy.org/en/20/orm/session_state_management.html>
- **Documentación** — Spring Boot, «Common Application Properties»: `spring.jpa.open-in-view` y su
  valor por defecto. <https://docs.spring.io/spring-boot/appendix/application-properties/index.html>

---

## 🧠 Preguntas

1. ¿Qué diferencia hay entre carga perezosa y ansiosa? 🟢
2. ¿Cuál es el valor por defecto de `fetch` en `@ManyToOne` y en `@OneToMany`? 🟢
3. ¿Qué es *Open Session in View*, y es una regla de JPA o una convención de Spring Boot? 🟢
4. ¿Qué hace `refresh` en Hibernate? 🟢
5. Distingue la caché de primer nivel de la de segundo nivel: qué es cada una, cuánto vive y quién
   la ve. 🟡
6. ¿Por qué aparece `LazyInitializationException`, y qué dice exactamente? 🟡
7. ¿Qué hace SQLAlchemy con los objetos de la sesión al hacer `commit`, y qué no hace Hibernate? 🟡
8. ¿Está el defecto de carga en el estándar SQL, en JPA o en cada biblioteca? Responde por separado.
   🟡
9. Una consulta JPQL vuelve a la base y devuelve un estado viejo. Explica por qué la base no tiene
   la culpa. 🟠
10. ¿Por qué *Open Session in View* es un antipatrón, en dos consecuencias concretas? 🟠
11. ¿Qué pasa al apagar `spring.jpa.open-in-view` en un proyecto grande, y por qué es buena noticia?
    🟠
12. ¿Para qué tablas de la tienda usarías una caché de segundo nivel, y para cuáles nunca? 🟠
13. ¿Por qué declarar todas las asociaciones `LAZY` es la recomendación habitual en JPA? 🟠
14. Diseña el acceso a datos de un endpoint que devuelve un pedido con sus líneas en JSON, sin
    `LazyInitializationException` y sin *Open Session in View*. 🔴
15. Diagnostica: un proceso por lotes con Hibernate que recorre pedidos durante una hora toma
    decisiones con estados que ya cambiaron. Da el mecanismo y dos correcciones. 🔴
16. Escribe la secuencia —sentencias y llamadas— que demuestra el dato viejo del mapa de identidad
    en el ORM que prefieras, dejando la base como estaba. 🔴

---

**Anterior:** [`02`](02-el-problema-n-mas-1.md) — el problema N+1 · **Siguiente:**
[`04`](04-constructores-y-cuando-no-usar-orm.md) — constructores, y cuándo no usar ORM ·
**Relacionado:** [`01`](01-el-desajuste-y-los-dos-patrones.md) §4 — el mapa de identidad ·
[`10/01`](../10-interfaz-con-los-lenguajes/01-el-driver-la-conexion-y-el-pool.md) §4 — la conexión
retenida que *Open Session in View* alarga.
