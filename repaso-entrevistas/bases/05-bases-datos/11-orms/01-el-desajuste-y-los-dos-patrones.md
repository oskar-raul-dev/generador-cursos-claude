# 01 — El desajuste y los dos patrones

> Qué problema resuelve un ORM y por qué nunca lo resuelve del todo: el **desajuste** entre objetos
> y filas, contado sin mística. Después, los dos patrones con que se construyen los ORM —*Active
> Record* y *Data Mapper*— y las dos piezas que separan a un ORM de verdad de un constructor de
> consultas: el **mapa de identidad** (*Identity Map*) y la **unidad de trabajo** (*Unit of Work*),
> corridas en Hibernate y SQLAlchemy frente a GORM y Drizzle, que no las tienen. **Asume leído:**
> [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) y
> [`10/06`](../10-interfaz-con-los-lenguajes/06-python-typescript-y-go.md), donde estas cuatro
> bibliotecas ya leyeron el pedido de ejemplo. **Vigencia:** 24 de septiembre de 2026.

---

## 1. 🎯 El problema

El servicio de pedidos carga `PED-00042`, se lo pasa a dos funciones que lo modifican, y al final
guarda. En Java con Hibernate, se escribe una sola vez, con los dos cambios. En Go con GORM, cada
función leyó su propia copia, y la segunda escritura pisa la primera. Nadie cambió de base de datos:
cambió **lo que la biblioteca hace con los objetos entre la lectura y la escritura**.

```text
¿Cuántos objetos hay en memoria para una misma fila, y quién decide eso?
¿Cuándo se escribe un cambio: cuando lo haces, cuando lo pides, o cuando confirmas?
¿Y qué problema resuelven esas decisiones, que la tabla no tenga ya resuelto?
```

> **📝 Contexto.** Todo está **corrido** en los contenedores de lenguaje, con las versiones de §4.6
> del dominio. Las escrituras de §5 se hacen dentro de una transacción que **se deshace al final**:
> `PED-00042` sigue en `PAGADO`. Los logs de SQL se pegan sin la hora ni las consultas con que cada
> biblioteca inspecciona el servidor al conectar.

---

## 2. 🧱 El desajuste, sin mística

**Qué es:** el nombre que el oficio da —*object-relational impedance mismatch*— a que objetos y
tablas modelan lo mismo con reglas distintas. No es un misterio: son cinco diferencias concretas, y
cada ORM decide qué hacer con cada una.

| Diferencia | En la tabla | En el objeto | En la tienda |
|---|---|---|---|
| Identidad | La clave primaria | La dirección en memoria | Dos objetos pueden representar `PED-00042` |
| Asociación | Una clave foránea en el hijo | Una referencia o una colección en el padre | `pedido.lineas` no existe en `pedidos` |
| Navegación | Un `JOIN` que decides tú | Seguir referencias, una a una | Recorrer `lineas` puede ser una consulta más |
| Granularidad | Columnas planas | Objetos anidados | Una dirección sería tres columnas o un objeto |
| Herencia | No existe | Clases y subclases | Tres formas de guardarla, ninguna gratis |

- **La tercera fila es la que más cuesta en producción**: navegar objetos es gratis en memoria y es
  una consulta por salto en la base. Es el N+1 de [`02`](02-el-problema-n-mas-1.md).
- **La primera es la que este capítulo corre**: si una fila puede tener dos objetos en memoria, dos
  partes del código pueden cambiarla sin enterarse la una de la otra.

**Quién lo manda:** nadie: es una diferencia de modelos, y el estándar no dice nada de objetos. Cada
biblioteca la resuelve a su manera, y esa manera es lo que se elige al elegir ORM.

---

## 3. 🧱 *Active Record* frente a *Data Mapper*

**Qué es:** los dos patrones, con los nombres del catálogo de Martin Fowler, con que se construye
casi todo ORM.

| | *Active Record* | *Data Mapper* |
|---|---|---|
| Quién sabe guardar | **El propio objeto**: `pedido.save()` | Un objeto aparte: la sesión o el `EntityManager` |
| El objeto conoce la base | Sí: hereda de una clase de la biblioteca | No: es una clase normal, mapeada desde fuera |
| Ejemplos | Rails, Django, Eloquent de Laravel | Hibernate y JPA, SQLAlchemy ORM, Doctrine |
| Encaja con | Tablas y objetos casi iguales | Un dominio que no quiere depender de la base |

- **GORM y Drizzle no son del todo ninguno de los dos**: GORM guarda con `db.Save(&pedido)`, desde
  fuera, pero sin sesión que recuerde nada; Drizzle es un constructor de consultas con consultas
  relacionales. Lo que les falta son las dos piezas de §4 y §5, y es lo que más se nota al usarlos.

**Cuánto cuesta:** *Active Record* ata cada objeto a la base, y probar la lógica sin base se vuelve
difícil; *Data Mapper* separa, a cambio de una sesión con estado que hay que entender. **Cuándo
sí:** *Active Record* en aplicaciones donde tabla y objeto son lo mismo; *Data Mapper* en dominios
con reglas propias.

> **Veredicto:** la diferencia no es de sintaxis, es de **quién tiene la responsabilidad de
> guardar**. Con *Data Mapper* es la sesión, y la sesión es la que decide cuándo va el SQL.

---

## 4. 🧱 El mapa de identidad

**Qué es:** una tabla que la sesión mantiene de **clave primaria a objeto**. Pedir dos veces la
misma fila en la misma sesión devuelve **el mismo objeto**, y la segunda vez no va a la base.

```java
var a = sesion.find(Pedido.class, 42L);                  // primera lectura: va a la base
var b = sesion.find(Pedido.class, 42L);                  // segunda: la da el mapa de identidad
System.out.println("mismo objeto: " + (a == b));
```

```text
-- Hibernate 7.4.10
Hibernate: select p1_0.id,p1_0.codigo,p1_0.estado,p1_0.total from pedidos p1_0 where p1_0.id=?
mismo objeto: true
-- SQLAlchemy ORM 2.0.54, con sesion.get(Pedido, 42) dos veces
SELECT pedidos.id AS pedidos_id, pedidos.codigo AS pedidos_codigo, pedidos.estado AS pedidos_estado, pedidos.total AS pedidos_total
FROM pedidos
WHERE pedidos.id = %(pk_1)s::INTEGER
[generated in 0.00012s] {'pk_1': 42}
mismo objeto: True
```

- **Una consulta para dos lecturas**, y un solo objeto. Dos funciones que reciben «el pedido 42» de
  la misma sesión trabajan sobre la misma instancia, y sus cambios se suman.
- **En GORM y en Drizzle cada lectura es una consulta** y cada resultado, un valor nuevo:

```text
-- GORM 1.31.2, con tx.First(&a, 42) y tx.First(&b, 42)
[0.987ms] [rows:1] SELECT * FROM "pedidos" WHERE "pedidos"."id" = 42 ORDER BY "pedidos"."id" LIMIT 1
[0.236ms] [rows:1] SELECT * FROM "pedidos" WHERE "pedidos"."id" = 42 ORDER BY "pedidos"."id" LIMIT 1
-- Drizzle 0.45.3, con dos select() iguales
Query: begin
Query: select "id", "codigo", "estado", "total" from "pedidos" where "pedidos"."id" = $1 -- params: [42]
Query: select "id", "codigo", "estado", "total" from "pedidos" where "pedidos"."id" = $1 -- params: [42]
mismo objeto: false
```

**Cuánto cuesta:** memoria —la sesión guarda todo lo que carga hasta que se cierra— y un riesgo: el
objeto del mapa puede quedar **viejo** si otra conexión cambia la fila, que es de
[`03`](03-carga-caches-y-la-sesion.md). **Cuándo sí:** sesiones cortas, una por petición. **Cuándo
no:** una sesión que vive horas y carga miles de objetos.

> **🧠 Modelo mental.** El mapa de identidad garantiza **una fila, un objeto** dentro de la sesión.
> No es una caché de la base: es la forma de que tu código no tenga dos versiones de la misma cosa.

---

## 5. 🧱 La unidad de trabajo

**Qué es:** la sesión **anota** qué objetos cambiaron y escribe los cambios juntos, cuando se vacía
—el *flush*—, que ocurre antes de una consulta, al confirmar o cuando se pide. Cambiar un atributo
no escribe nada:

```text
-- Hibernate: a.estado = "ENVIADO"; y después sesion.flush()
cambiado en memoria; aún sin UPDATE
Hibernate: update pedidos set codigo=?,estado=?,total=? where id=?
después del flush
-- SQLAlchemy: lo mismo, con sesion.flush()
cambiado en memoria; aún sin UPDATE
UPDATE pedidos SET estado=%(estado)s::VARCHAR WHERE pedidos.id = %(pedidos_id)s::INTEGER
[generated in 0.00014s] {'estado': 'ENVIADO', 'pedidos_id': 42}
después del flush
ROLLBACK
```

- **Nadie llamó a `save`**: la sesión comparó el objeto con cómo lo cargó —*dirty checking*— y
  generó el `UPDATE` sola. Es lo que hace cómodo el *Data Mapper*, y lo que sorprende cuando un
  cambio accidental en un objeto cargado acaba en la base.
- **Hibernate escribe todas las columnas**; SQLAlchemy, solo la que cambió. Hibernate lo hace para
  reutilizar una sola sentencia por entidad, y se cambia con `@DynamicUpdate`. El precio de escribir
  todo es más WAL por fila y el riesgo de pisar una columna que otra transacción cambió.
- **Sin unidad de trabajo, la escritura es explícita y es tuya**:

```text
-- GORM: a.Estado = "ENVIADO"; tx.Save(&a)
cambiado en memoria; nadie lo escribe
[0.550ms] [rows:1] UPDATE "pedidos" SET "codigo"='PED-00042',"estado"='ENVIADO',"total"='3186.23' WHERE "id" = 42
-- Drizzle: tx.update(pedidos).set({ estado: a.estado })
cambiado en memoria; nadie lo escribe
Query: update "pedidos" set "estado" = $1 where "pedidos"."id" = $2 -- params: ["ENVIADO", 42]
Query: rollback
```

- **`Save` de GORM escribe todas las columnas, como Hibernate**, con lo que haya en el objeto; si
  otra parte del código leyó su propia copia y guarda después, la última escritura gana entera. Es
  el incidente del §1, y la defensa es la columna de versión de
  [`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §3.
- **Las cuatro escrituras se deshicieron**: cada prueba terminó en *rollback*, y `PED-00042` sigue
  en `PAGADO`.

**Quién lo manda:** **biblioteca**, entero. **Cuánto cuesta:** SQL que aparece en un momento que tú
no elegiste —el *flush* antes de una consulta— y escrituras de más si un objeto cargado se toca sin
querer. **Cuándo sí:** operaciones que cambian varias entidades y deben guardarse juntas.

> **Veredicto:** con unidad de trabajo, **cambiar es escribir, más tarde**. Sin ella, cambiar no es
> nada, y escribir es tu responsabilidad. Las dos formas son correctas; lo peligroso es no saber
> cuál tienes.

---

## 6. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 no habla de objetos. JPA es una especificación de Jakarta;
> los patrones son de un libro; y todo lo demás es de cada biblioteca.

| Afirmación | Estándar SQL | JPA (Jakarta) | Bibliotecas del corpus |
|---|---|---|---|
| Hay mapa de identidad | No aplica | Sí: el contexto de persistencia | Hibernate y SQLAlchemy sí; GORM y Drizzle no |
| Cambiar un objeto cargado lo escribe | No aplica | Sí, en el *flush* | Hibernate y SQLAlchemy sí; GORM y Drizzle solo si lo pides |
| El `UPDATE` lleva solo lo que cambió | — | No lo fija | Hibernate: todo; SQLAlchemy: lo cambiado; `Save` de GORM: todo |
| *Active Record* y *Data Mapper* | — | JPA es *Data Mapper* | Los nombres son de Fowler, 2002 |

**Convención, las dos que más se repiten.** *«El ORM guarda cuando llamo a `save`»* — en Hibernate y
SQLAlchemy guarda cuando se vacía la sesión, haya `save` o no. Y *«el mapa de identidad es una
caché»* — es una garantía de identidad dentro de una sesión; que ahorre una consulta es un efecto
secundario, y que pueda quedar viejo, el precio.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Leer dos veces el mismo registro son dos consultas" | En Hibernate y SQLAlchemy, dentro de la misma sesión, una: el mapa de identidad da el mismo objeto |
| "Si no llamo a `save`, no se guarda" | Con unidad de trabajo, el *flush* escribe cualquier cambio en un objeto cargado |
| "El `UPDATE` del ORM solo toca lo que cambié" | Hibernate y el `Save` de GORM escriben todas las columnas |
| "GORM funciona como Hibernate" | No tiene sesión: cada lectura es una consulta, y la escritura es explícita |
| "*Active Record* es más moderno que *Data Mapper*" | Son de la misma época y resuelven cosas distintas: quién sabe guardar |
| "El desajuste es un problema resuelto" | Se resuelve caso a caso; la navegación sigue costando una consulta por salto |

---

## 📚 Para profundizar

- **Documentación** — Hibernate ORM 7.4, «User Guide»: contexto de persistencia, *flush* y *dirty
  checking*. <https://docs.hibernate.org/orm/7.4/userguide/html_single/>
- **Documentación** — Hibernate ORM 7.4, `@DynamicUpdate`: el `UPDATE` solo con lo cambiado.
  <https://docs.hibernate.org/orm/7.4/javadocs/org/hibernate/annotations/DynamicUpdate.html>
- **Documentación** — SQLAlchemy 2.0, «Session Basics»: identidad, *flush* y el ciclo de la sesión.
  <https://docs.sqlalchemy.org/en/20/orm/session_basics.html>
- **Documentación** — GORM, «Update»: `Save` frente a `Update` y `Updates`.
  <https://gorm.io/docs/update.html>
- **Documentación** — Drizzle ORM, «Transactions». <https://orm.drizzle.team/docs/transactions>
- **Referencia** — Martin Fowler, catálogo de *Patterns of Enterprise Application Architecture*:
  «Unit of Work». <https://martinfowler.com/eaaCatalog/unitOfWork.html>
- **Referencia** — el mismo catálogo: «Identity Map».
  <https://martinfowler.com/eaaCatalog/identityMap.html>
- **Libro** — Martin Fowler, *Patterns of Enterprise Application Architecture*, Addison-Wesley,
  2002, capítulo 10, «Data Source Architectural Patterns».

---

## 🧠 Preguntas

1. ¿Qué es el desajuste objeto-relacional, en una frase? 🟢
2. ¿Qué hace un mapa de identidad? 🟢
3. ¿Qué es el *flush* de una sesión? 🟢
4. Nombra dos ORM que sigan *Active Record* y dos que sigan *Data Mapper*. 🟢
5. Distingue *Active Record* de *Data Mapper*: quién sabe guardar en cada uno. ¿Qué parte es del
   motor y qué parte es convención? 🟡
6. ¿Por qué Hibernate hizo una sola consulta al pedir dos veces el mismo pedido, y GORM dos? 🟡
7. Diferencia el `UPDATE` que genera Hibernate del que genera SQLAlchemy al cambiar una columna. 🟡
8. ¿Están el mapa de identidad o la unidad de trabajo en el estándar SQL, en JPA o en las
   bibliotecas? Responde por separado. 🟡
9. ¿Por qué la navegación de objetos es la diferencia del desajuste que más cuesta en producción? 🟡
10. Un objeto cargado por Hibernate se modifica sin querer en una función de formato. ¿Qué pasa al
    confirmar la transacción, y cómo lo evitarías? 🟠
11. ¿Qué cuesta que Hibernate escriba todas las columnas en cada `UPDATE`, y cuándo usarías
    `@DynamicUpdate`? 🟠
12. Dos funciones de un servicio en Go leen el mismo pedido con GORM, lo modifican y lo guardan con
    `Save`. ¿Qué queda en la base, y cómo lo corriges? 🟠
13. ¿Qué cuesta una sesión que vive mucho tiempo con mapa de identidad? 🟠
14. Elige entre *Active Record* y *Data Mapper* para un servicio de pagos con reglas de negocio
    propias, y justifica la elección. 🟠
15. Diseña cómo detectarías, en un servicio con Hibernate, escrituras que nadie pidió. Di qué
    mirarías y dónde. 🔴
16. Escribe, en el lenguaje que prefieras, una operación que cambie el estado de un pedido de forma
    que dos llamadas simultáneas no se pisen, con GORM o Drizzle. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:** [`02`](02-el-problema-n-mas-1.md) — el
problema N+1 · **Relacionado:** [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) — las capas
de Java, con Hibernate arriba ·
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §3 —
la columna de versión que evita que la última escritura gane.
