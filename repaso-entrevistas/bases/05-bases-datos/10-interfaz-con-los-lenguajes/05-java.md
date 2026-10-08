# 05 — Java

> El ecosistema de acceso a datos de Java capa por capa, con el mismo ejemplo del bloque en cada
> una: JDBC y HikariCP, que ya salieron; `JdbcClient` de Spring; jOOQ; MyBatis; y JPA con Hibernate.
> Después, la propagación de transacciones de Spring corrida de verdad, y los dos motores embebidos
> que siguen apareciendo en proyectos heredados —H2 y Derby—, uno de ellos ya retirado. **Asume
> leído:** [`01`](01-el-driver-la-conexion-y-el-pool.md) a
> [`04`](04-transacciones-y-resultados-grandes.md) — el driver, el *pool*, los tipos y las
> transacciones, que aquí se dan por sabidos. **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. El mapa de capas](#2--el-mapa-de-capas)
- [3. JdbcClient: SQL a mano, mapeo automático](#3--jdbcclient-sql-a-mano-mapeo-automático) · [4.
  jOOQ y MyBatis](#4--jooq-y-mybatis)
- [5. JPA con Hibernate](#5--jpa-con-hibernate) · [6. La propagación,
  corrida](#6-️-la-propagación-corrida)
- [7. H2 y Derby, los embebidos](#7--h2-y-derby-los-embebidos) · [8. Estándar, motor y
  convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Llegas a un proyecto Java de diez años. Los informes usan `JdbcTemplate`, el alta de pedidos usa
JPA, un módulo de facturación tiene sus consultas en ficheros XML de MyBatis, y las pruebas corren
contra H2 en memoria. Alguien pregunta en la entrevista **por qué conviven cuatro formas de hablar
con la misma base**, y cuál elegirías hoy.

La respuesta útil no es una lista de marcas: es saber **qué escribe cada capa y qué decide por ti**.
Cuanto más arriba, menos SQL escribes y más SQL se escribe sin que lo veas.

```text
¿Qué capa escribe el SQL: tú, una biblioteca a partir de tu código, o un ORM a partir de tus objetos?
¿Qué pasa con la transacción cuando un método anotado llama a otro?
¿Por qué siguen apareciendo H2 y Derby, y qué problema traen?
```

> **📝 Contexto.** Todo está **corrido** en el contenedor `java` del entorno, con las versiones de §2
> fijadas en su `pom.xml` y verificadas en §4.6 del dominio. Las escrituras de §6 se deshacen o se
> compensan en el propio programa. **Longitud:** capítulo denso, declarado en §2 del plan de
> producción: cinco capas con el mismo ejemplo corrido, más la propagación y los embebidos.

---

## 2. 🧱 El mapa de capas

**Qué es:** cada capa se apoya en la de abajo. Todas terminan en JDBC y en el driver, y todas piden
conexiones a un *pool*; lo que cambia es **quién escribe el SQL**.

| Capa | Versión del corpus | Quién escribe el SQL | Qué te da |
|---|---|---|---|
| JDBC + pgjdbc | 42.7.13 | Tú, entero | Filas, columna a columna |
| HikariCP | 7.1.0 | — | Conexiones prestadas ([`01`](01-el-driver-la-conexion-y-el-pool.md)) |
| Spring `JdbcClient` | spring-jdbc 7.0.9 | Tú, entero | Filas convertidas a objetos o *records* |
| jOOQ | 3.21.8 | jOOQ, a partir de código Java tipado | SQL construido y comprobado al compilar |
| MyBatis | 3.5.19 | Tú, en anotaciones o XML | El SQL fuera del código, con su mapeo |
| JPA con Hibernate | 7.4.10.Final | **Hibernate**, a partir de tus entidades | Objetos cargados, cambiados y guardados |

> **Veredicto:** subir de capa ahorra código y quita control sobre el SQL. La pregunta de diseño no
> es cuál es mejor, sino **en qué parte del sistema quieres ver el SQL que se ejecuta**.

---

## 3. 🧱 JdbcClient: SQL a mano, mapeo automático

**Qué es:** la API fluida que Spring añadió sobre `JdbcTemplate`. Escribes el SQL con parámetros con
nombre, y Spring convierte cada fila en un objeto:

```java
record Linea(String estado, BigDecimal total, int linea, int cantidad, BigDecimal precioUnit) {}

var jdbc = JdbcClient.create(pool);                  // SQL a mano; el mapeo lo hace Spring
var lineas = jdbc.sql("""
        SELECT p.estado, p.total, l.linea, l.cantidad, l.precio_unit
          FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
         WHERE p.codigo = :codigo ORDER BY l.linea""")
    .param("codigo", "PED-00042")
    .query(Linea.class)                              // columnas -> componentes del record
    .list();
```

```text
Linea[estado=PAGADO, total=3186.23, linea=1, cantidad=1, precioUnit=102.83]
Linea[estado=PAGADO, total=3186.23, linea=2, cantidad=5, precioUnit=27.03]
Linea[estado=PAGADO, total=3186.23, linea=3, cantidad=3, precioUnit=982.75]
```

- **`precio_unit` llega a `precioUnit` sin configurar nada**: Spring traduce el guion bajo al estilo
  de Java. El `:codigo` con nombre lo convierte en `?` antes de llegar a pgjdbc.
- **Es la capa que conviene tener a mano siempre**: el SQL está a la vista, y el mapeo tedioso ya no
  se escribe.

**Cuánto cuesta:** una dependencia más y ninguna sorpresa. **Cuándo no:** si el mismo SQL se compone
de muchas piezas opcionales, construirlo como texto se vuelve frágil, y ahí entra jOOQ.

---

## 4. 🧱 jOOQ y MyBatis

**jOOQ** construye el SQL con código Java. Lo normal es generar clases desde el esquema; aquí, sin
generar nada, con los nombres como texto:

```java
var sql = using(con, SQLDialect.POSTGRES);
var consulta = sql.select(field(name("p", "estado")), field(name("p", "total")),
                          field(name("l", "linea")), field(name("l", "cantidad")))
    .from(table(name("pedidos")).as("p"))
    .join(table(name("pedido_lineas")).as("l")).on(field(name("l", "pedido_id")).eq(field(name("p", "id"))))
    .where(field(name("p", "codigo")).eq("PED-00042"))
    .orderBy(field(name("l", "linea")));
System.out.println(consulta.getSQL());               // el SQL que jOOQ construye
```

```text
select "p"."estado", "p"."total", "l"."linea", "l"."cantidad" from "pedidos" as "p" join "pedido_lineas" as "l" on "l"."pedido_id" = "p"."id" where "p"."codigo" = ? order by "l"."linea"
[PAGADO, 3186.23, 1, 1]
[PAGADO, 3186.23, 2, 5]
[PAGADO, 3186.23, 3, 3]
```

- **El valor viaja como `?`**: jOOQ parametriza solo, y cita cada identificador, que es la
  protección contra la inyección por nombres de [`02`](02-parametrizadas-e-inyeccion.md) §4 hecha
  por la biblioteca.
- **Con las clases generadas**, un nombre de columna mal escrito es un error de compilación y no un
  error en producción. Es el motivo por el que se elige jOOQ.
- Corrido con `-Dorg.jooq.no-logo=true -Dorg.jooq.no-tips=true` y el log a `warn`: sin eso, jOOQ
  imprime su logotipo, un «consejo del día» y una línea de log al arrancar.

**MyBatis** hace lo contrario: el SQL lo escribes tú, entero, **fuera** del código que lo usa, en
una anotación o en un XML, y MyBatis lo enlaza a un método:

```java
public interface PedidoMapper {                               // el SQL vive junto al método
    @Select("""
        SELECT p.estado, p.total, l.linea, l.cantidad
          FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
         WHERE p.codigo = #{codigo} ORDER BY l.linea""")
    List<Map<String, Object>> lineas(@Param("codigo") String codigo);
}
```

```text
{estado=PAGADO, total=3186.23, cantidad=1, linea=1}
{estado=PAGADO, total=3186.23, cantidad=5, linea=2}
{estado=PAGADO, total=3186.23, cantidad=3, linea=3}
```

- **`#{codigo}` es un parámetro**, que MyBatis convierte en `?`. Su hermano **`${codigo}` pega el
  texto tal cual**, y es la inyección de `02` esperando a que alguien confunda los dos signos.
- **El orden de las columnas se perdió** porque se pidió un `Map`: MyBatis mapea a clases igual que
  `JdbcClient` cuando se le da una.

**Cuánto cuesta cada una:** jOOQ, un paso de generación de código en la construcción, y una edición
de pago para los motores comerciales y las versiones antiguas, porque la libre solo cubre la última
versión de los motores libres; MyBatis, SQL en dos sitios —la consulta y el código que la llama— que
hay que mantener sincronizados. **Cuándo sí:** jOOQ, SQL complejo y dinámico con seguridad de tipos;
MyBatis, equipos que quieren el SQL a la vista y separado.

---

## 5. 🧱 JPA con Hibernate

**Qué es:** JPA es la especificación de Jakarta para mapear objetos a tablas; Hibernate, la
implementación más usada. Declaras entidades, y **Hibernate escribe el SQL**:

```java
@Entity(name = "Pedido") @Table(name = "pedidos")
public static class Pedido {
    @Id Long id;
    String codigo;
    String estado;
    BigDecimal total;
    @OneToMany(mappedBy = "pedido") @OrderBy("linea")     // perezosa por defecto
    List<Linea> lineas;
}
// …y Linea, con la clave compuesta (pedido_id, linea) como @IdClass

var pedido = sesion.createQuery("from Pedido p where p.codigo = :codigo", Pedido.class)
                   .setParameter("codigo", "PED-00042").getSingleResult();
System.out.println(pedido.estado + " " + pedido.total);
for (var l : pedido.lineas) { … }                          // aquí se cargan las líneas
```

Con `hibernate.show_sql`, estas son las líneas del SQL generado y la salida del programa, sin el log
de arranque de Hibernate:

```text
Hibernate: select p1_0.id,p1_0.codigo,p1_0.estado,p1_0.total from pedidos p1_0 where p1_0.codigo=?
PAGADO 3186.23
Hibernate: select l1_0.pedido_id,l1_0.linea,l1_0.cantidad,l1_0.precio_unit from pedido_lineas l1_0 where l1_0.pedido_id=? order by l1_0.linea
linea=1 cantidad=1 precio=102.83
linea=2 cantidad=5 precio=27.03
linea=3 cantidad=3 precio=982.75
```

- **Dos consultas donde las otras capas hacían una**: el pedido primero y, **al recorrer `lineas`**,
  las líneas. Es la carga perezosa, y la segunda consulta aparece en medio de la salida porque se
  ejecuta justo en ese momento. Con cien pedidos serían ciento una: es el N+1, que tiene su capítulo
  en el bloque 11.
- **La consulta que escribiste no es SQL**: es JPQL, sobre la entidad `Pedido`, y Hibernate la
  traduce. El nombre `@Entity(name = "Pedido")` hace falta porque, en una clase anidada, el nombre
  por defecto sería `ConHibernate$Pedido`.
- **El log de arranque avisa de dos cosas** que conviene leer: `Using built-in connection pool (not
  intended for production use)`, porque aquí no se le dio un *pool*, y `Autocommit mode: false`:
  Hibernate siempre trabaja dentro de una transacción.

**Cuánto cuesta:** SQL que no escribes y que hay que aprender a leer en el log; un contexto de
persistencia que guarda todo lo cargado; y las trampas del bloque 11. **Cuándo sí:** dominio rico
con muchas entidades y operaciones de una en una. **Cuándo no:** informes, cargas masivas y SQL que
el ORM no sabe expresar.

---

## 6. ⚖️ La propagación, corrida

**Qué es:** qué hace una operación transaccional llamada **dentro** de otra. Spring la configura en
`@Transactional(propagation = …)`; con `TransactionTemplate` se ve igual sin necesitar el
contenedor. La externa pasa `PED-99999` a `PENDIENTE`, la interna escribe `actualizado_en` de
`PED-00042`, y **después** la externa falla:

```java
var externa = new TransactionTemplate(gestor);             // REQUIRED por defecto
var dentro = new TransactionTemplate(gestor);
dentro.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);   // o REQUIRED
externa.executeWithoutResult(s -> {
    jdbc.sql("UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999'").update();
    dentro.executeWithoutResult(s2 ->
        jdbc.sql("UPDATE pedidos SET actualizado_en = now() WHERE codigo = 'PED-00042'").update());
    throw new IllegalStateException("la externa falla después");
});
```

```text
-- interna REQUIRES_NEW, pool de 5
externa: pid 33191
interna REQUIRES_NEW: pid 33192
resultado: la externa falla después
PED-99999: ANULADO · PED-00042 actualizado_en nulo: false

-- interna REQUIRED, pool de 5
externa: pid 33193
interna REQUIRED: pid 33193
resultado: la externa falla después
PED-99999: ANULADO · PED-00042 actualizado_en nulo: true

-- interna REQUIRES_NEW, pool de 1
externa: pid 33202
resultado: Could not open JDBC Connection for transaction
PED-99999: ANULADO · PED-00042 actualizado_en nulo: true
```

- **`REQUIRES_NEW` es otra conexión y otra transacción**: otro `pid`, y su escritura **sobrevive**
  al *rollback* de la externa. Es lo que se quiere para un registro de auditoría que tiene que
  quedar aunque la operación falle, y lo que no se quiere en casi todo lo demás.
- **`REQUIRED` es la misma**: mismo `pid`, y se deshace entera con la externa.
- **`REQUIRES_NEW` necesita una segunda conexión mientras retiene la primera.** Con un *pool* de
  uno, no la consigue: bajo carga, con el *pool* casi lleno, es un agotamiento que solo aparece en
  producción. Y si la interna tocara la fila que la externa tiene bloqueada, esperaría a una
  transacción que no puede terminar hasta que la interna termine.
- **El programa deja `actualizado_en` otra vez nulo** al final: es la compensación de la regla del
  bloque 04.

**Las dos trampas de la anotación**, de la documentación de Spring: la **autoinvocación** —un método
del objeto que llama a otro del mismo objeto— **no abre transacción**, porque la anotación la aplica
un *proxy* que esa llamada no atraviesa; y por defecto **solo se deshace ante excepciones no
comprobadas**: una `IOException` que sale del método confirma la transacción.

> **Veredicto:** `REQUIRES_NEW` no es «una transacción anidada»: es una segunda conexión con su
> propia confirmación. Se usa a propósito, y se cuenta en el tamaño del *pool*.

---

## 7. 🪦 H2 y Derby, los embebidos

**Qué es:** un motor **embebido** vive dentro de la JVM de la aplicación: no hay servidor, ni red,
ni instalación; se conecta con una URL y, en memoria, desaparece al terminar. Por eso llenan los
proyectos heredados: arrancan solos en las pruebas, y durante años fueron el ejemplo por defecto de
los tutoriales.

La misma consulta, escrita con `LIMIT` y con el `FETCH FIRST` del estándar, en los dos:

```java
for (var url : new String[] {"jdbc:h2:mem:tienda", "jdbc:derby:memory:tienda;create=true"}) {
    try (var con = DriverManager.getConnection(url); var st = con.createStatement()) {   // sin servidor
        …
```

```text
== H2 2.5.250 (2026-08-29)
LIMIT       -> PED-00043 PED-99999
FETCH FIRST -> PED-00043 PED-99999
== Apache Derby 10.17.1.0 - (1913217)
LIMIT       -> Syntax error: Encountered "LIMIT" at line 1, column 48.
FETCH FIRST -> PED-00043 PED-99999
```

- **Derby no entiende `LIMIT`**, que no es del estándar; H2 acepta las dos. Es una muestra pequeña
  de lo que pasa al cambiar de motor, y de por qué probar con uno y desplegar con otro es probar
  otra cosa.
- **Derby está retirado.** Su web lo dice: el 10 de octubre de 2025 sus desarrolladores votaron
  dejarlo en solo lectura; no habrá más versiones ni correcciones, y la 10.17.1.0, de noviembre de
  2023, es la última. Un proyecto que lo use tiene una migración pendiente.
- **H2 sigue vivo**, con modos de compatibilidad que imitan a otros motores. Imitar no es ser: por
  qué una prueba contra H2 puede pasar y el mismo código fallar en PostgreSQL, con el caso
  reproducido, es de [`11/05`](../11-orms/05-probar-contra-base-de-datos-real.md) §2.

**Cuánto cuesta:** pruebas que no prueban el motor de producción. **Cuándo sí:** una aplicación de
escritorio o una herramienta que necesita base propia y sin servidor. **Cuándo no:** como sustituto
de la base de producción en las pruebas.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. `FETCH
> FIRST` es la forma que se atribuye al estándar y `LIMIT` no está en él; JDBC y JPA son
> especificaciones de Java, no de SQL.

| Afirmación | Estándar | PostgreSQL 18.6 | Java |
|---|---|---|---|
| `FETCH FIRST n ROWS ONLY` | Sí | Sí | Derby y H2 lo aceptan |
| `LIMIT n` | No | Sí | H2 lo acepta; **Derby no** |
| La consulta de JPA es SQL | — | — | No: es JPQL, y Hibernate la traduce |
| Las transacciones anidadas existen | No | No: hay puntos de guardado | `REQUIRES_NEW` es **otra conexión** |
| `@Transactional` en una autoinvocación abre transacción | — | — | **No**, en el modo de *proxy* por defecto |
| Una excepción comprobada deshace | — | — | **No** por defecto en Spring |

**Convención, las dos que más se repiten.** *«JPA te libera de escribir SQL»* — te libera de
escribirlo y te obliga a leerlo en el log, porque lo que ejecuta la base es el SQL de Hibernate, no
tu JPQL. Y *«`REQUIRES_NEW` es una transacción anidada»* — es una segunda conexión con su propio
`COMMIT`, visible en el `pid`.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Hibernate hace una consulta por `find`" | Hace las que necesite: aquí, una por el pedido y otra al recorrer las líneas |
| "`#{}` y `${}` de MyBatis son lo mismo" | `#{}` es un parámetro; `${}` pega el texto, y es una inyección |
| "`REQUIRES_NEW` se deshace con la externa" | Tiene su propia confirmación: su escritura sobrevivió al *rollback* de la externa |
| "`REQUIRES_NEW` no afecta al *pool*" | Retiene dos conexiones a la vez; con un *pool* de uno, falla |
| "`@Transactional` funciona en cualquier llamada" | No en una autoinvocación, con el *proxy* por defecto |
| "Cualquier excepción deshace la transacción de Spring" | Por defecto solo las no comprobadas y los `Error` |
| "Derby sigue siendo una opción" | Se retiró el 10 de octubre de 2025; no habrá más versiones |

---

## 📚 Para profundizar

- **Documentación** — Spring Framework, «Using the JDBC Core Classes»: `JdbcClient` y
  `JdbcTemplate`. <https://docs.spring.io/spring-framework/reference/data-access/jdbc/core.html>
- **Documentación** — Spring Framework, «Transaction Propagation»: `REQUIRED`, `REQUIRES_NEW` y
  `NESTED`.
  <https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/tx-propagation.html>
- **Documentación** — Spring Framework, «Using @Transactional»: la autoinvocación y el modo de
  *proxy*.
  <https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html>
- **Documentación** — Spring Framework, «Rolling Back a Declarative Transaction»: qué excepciones
  deshacen.
  <https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/rolling-back.html>
- **Documentación** — Hibernate ORM 7.4, «User Guide»: entidades, carga perezosa y el SQL generado.
  <https://docs.hibernate.org/orm/7.4/userguide/html_single/>
- **Documentación** — jOOQ 3.21, el manual: SQL construido con código y generación desde el esquema.
  <https://www.jooq.org/doc/3.21/manual/>
- **Documentación** — MyBatis 3, «Java API»: mapeadores, `#{}` y `${}`.
  <https://mybatis.org/mybatis-3/java-api.html>
- **Documentación** — Apache Derby, la página del proyecto con el aviso de retirada.
  <https://db.apache.org/derby/>

---

## 🧠 Preguntas

1. Ordena de menos a más abstracción JDBC, `JdbcClient`, jOOQ, MyBatis y JPA, y di quién escribe el
   SQL en cada una. 🟢
2. ¿Qué es un motor embebido? Da dos ejemplos de Java. 🟢
3. ¿Qué pasó con Apache Derby en 2025? 🟢
4. ¿Qué diferencia hay entre `#{}` y `${}` en MyBatis? 🟢
5. ¿Es JPQL lo mismo que SQL? Di quién lo traduce y dónde lo ves. 🟡
6. Distingue `REQUIRED` de `REQUIRES_NEW`: qué conexión usa cada una y qué pasa con sus escrituras
   si la externa falla. 🟡
7. ¿Por qué Hibernate hizo dos consultas para leer un pedido con sus líneas, y en qué momento hizo
   la segunda? 🟡
8. ¿Está `LIMIT` en el estándar SQL? Responde para la norma, para PostgreSQL, para H2 y para Derby.
   🟡
9. ¿Qué ventaja tiene generar las clases de jOOQ desde el esquema frente a escribir los nombres como
   texto? 🟡
10. Un método anotado con `@Transactional` llama a otro método anotado del mismo objeto. Explica qué
    transacción tiene el segundo y por qué. 🟠
11. Un método `@Transactional` lanza una `IOException` después de escribir. ¿Qué queda en la base,
    con la configuración por defecto, y cómo lo cambiarías? 🟠
12. ¿Por qué `REQUIRES_NEW` puede agotar el *pool* bajo carga, y cómo lo tendrías en cuenta al
    dimensionarlo? 🟠
13. ¿Cuándo elegirías jOOQ en vez de JPA, y cuándo JPA en vez de jOOQ? 🟠
14. Un proyecto heredado prueba contra H2 y despliega contra PostgreSQL. Da dos riesgos concretos y
    qué harías antes de tocar nada. 🟠
15. Un registro de auditoría tiene que guardarse aunque la operación de negocio falle. Diseña la
    transacción con Spring y di qué cuesta. 🟠
16. Diagnostica: tras añadir `REQUIRES_NEW` a un método de auditoría, el servicio empieza a fallar
    con `Could not open JDBC Connection for transaction` en las horas punta. Da el mecanismo y dos
    correcciones. 🔴
17. Diseña la capa de datos de un servicio de pedidos nuevo en Java: qué capa usarías para el alta,
    cuál para los informes y cuál para una carga masiva nocturna, y por qué. 🔴
18. Revisa: `@Transactional public void cobrar() { guardarPago(); enviarCorreo(); }` con
    `guardarPago()` y `enviarCorreo()` en el mismo objeto y el segundo anotado con `REQUIRES_NEW`.
    Di qué transacciones existen de verdad y qué pasa si el correo falla. 🔴

---

**Anterior:** [`04`](04-transacciones-y-resultados-grandes.md) — transacciones y resultados grandes
· **Siguiente:** [`06`](06-python-typescript-y-go.md) — el mismo mapa en Python, TypeScript y Go ·
**Relacionado:** [`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md) §7 — los
puntos de guardado, que es lo único anidado que existe · [`02`](02-parametrizadas-e-inyeccion.md) —
la inyección que `${}` reabre.
