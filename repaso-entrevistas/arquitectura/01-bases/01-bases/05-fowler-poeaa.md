# 05 — Fowler PoEAA aplicado hoy

> El catálogo de *Patterns of Enterprise Application Architecture* que Spring y JPA te
> dan hecho y no sabes que estás usando. El ángulo: **qué te viene implementado, qué
> precio pagas por ello, y qué pasa cuando la abstracción se rompe.**
> Asume leído [`04` — Patrones GoF](04-patrones-gof.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Fowler catalogó en 2002 lo que la industria hacía a mano. Veinte años después, **Spring
y JPA implementan la mitad del catálogo por ti**, y eso crea un tipo de candidato
peculiar: usa Unit of Work, Identity Map y Data Mapper todos los días y no sabe nombrar
ninguno.

La entrevista lo detecta con una pregunta sencilla: *"¿qué hace exactamente
`@Transactional`?"*. Si la respuesta es "abre una transacción", falta la mitad.

---

## 2. 📜 Transaction Script vs Domain Model

**La decisión de verdad de este capítulo**, y la que más veces se toma sin darse cuenta.

**Transaction Script.** Un procedimiento por operación de negocio. Entra la petición,
corre la lógica de arriba abajo, sale el resultado. Los datos son estructuras sin
comportamiento.

**Domain Model.** Objetos con datos **y** comportamiento, donde las reglas viven en la
entidad que las posee. `pedido.cancelar()` sabe si puede cancelarse.

| | Transaction Script | Domain Model |
|---|---|---|
| Lógica | En el servicio | En la entidad |
| Escala con complejidad | Mal: duplica reglas | Bien: la regla vive en un sitio |
| Curva de entrada | Plana | Alta |
| Test | Necesita mocks del repositorio | La entidad se testea sola |
| Encaja con | Capas, vertical slice | Hexagonal, DDD |

**Cuándo Transaction Script es la respuesta correcta**, que es lo que casi nadie dice:
lógica fina, pocas reglas, mucho CRUD, equipo con rotación alta. Un *script* honesto
supera a un modelo de dominio mal hecho.

> **Veredicto:** el error no es elegir Transaction Script. Es **elegirlo sin saberlo** y
> descubrir a los dos años que la regla de negocio está copiada en once servicios.

---

## 3. 🩸 El modelo anémico

**Qué es.** Entidades que son solo getters y setters, con toda la lógica en los
servicios. Fowler lo llamó antipatrón porque **tiene el costo del Domain Model —el
mapeo, las entidades, el ORM— sin ninguno de sus beneficios**.

**Cómo se detecta**, en una frase que sirve para revisar código ajeno:

> Si puedes poner un objeto en estado inválido llamando a un setter, es anémico.

**La defensa honesta.** Con Transaction Script deliberado y DTOs planos, el modelo
anémico deja de ser un antipatrón y pasa a ser una decisión. El problema es el híbrido:
entidades JPA ricas en anotaciones, vacías de comportamiento, y servicios de 900 líneas.

> ⚠️ **Advertencia.** Decir "el modelo anémico es un antipatrón" sin matiz es media
> respuesta. La completa: *"lo es cuando pagas por un Domain Model y recibes un
> Transaction Script; si eliges Transaction Script a propósito, es coherente"*.

Se conecta con [`07` — DDD táctico](07-ddd-tactico.md), donde el agregado es la forma de
proteger la invariante que el setter rompe.

> **Veredicto:** el modelo anémico no es un antipatrón por tener lógica en servicios; lo es por pagar
> el precio del Domain Model y recibir un Transaction Script. Si eliges Transaction
> Script a conciencia, no tienes un problema de diseño: tienes una decisión.

---
## 4. 🗄️ Repository

**Qué es.** Una colección en memoria, fingida. El código de negocio pide
`repositorio.porId(x)` y no sabe si detrás hay SQL, un `HashMap` o una API.

**Qué te da Spring.** `JpaRepository` con las consultas derivadas del nombre del método.

**El precio.** `JpaRepository` **filtra hacia arriba la tecnología**: devuelve `Page`,
acepta `Pageable`, expone `flush()` y `getReferenceById()`. Si tu dominio depende de esa
interfaz, no está aislado — que es justo lo que hexagonal intentaba evitar.

> 💡 **Truco.** La respuesta de arquitecto: *"defino mi propia interfaz de repositorio en
> el dominio, con métodos del lenguaje del negocio, y la implemento en infraestructura
> delegando en `JpaRepository`"*. Es el Adapter de
> [`04` §5](04-patrones-gof.md#5--adapter) aplicado a persistencia.

> **Veredicto:** `JpaRepository` es una comodidad excelente y un puerto de dominio pésimo. Usarlo
> directo está bien mientras sepas que renunciaste al aislamiento, y mal cuando creías
> que lo tenías.

---
## 5. 🔄 Unit of Work

**Qué es.** Un objeto que lleva la cuenta de lo que cambió durante una operación y lo
escribe todo junto al final, en una transacción.

**Qué te da Spring.** **`@Transactional` es Unit of Work.** El `EntityManager` rastrea
las entidades gestionadas y hace `flush` al commit.

**La consecuencia que se pregunta:** por eso **no necesitas llamar a `save()`** sobre
una entidad que ya está gestionada. Esto funciona:

```java
@Transactional
public void renombrar(Long id, String nombre) {
    Cliente c = repo.findById(id).orElseThrow();
    c.setNombre(nombre);   // sin save(): el dirty checking lo detecta al commit
}
```

- La entidad está *managed*: el `EntityManager` compara su estado al cerrar y emite el
  `UPDATE` solo si cambió.
- **Fuera de la transacción la entidad está *detached*** y ese mismo código no persiste
  nada. Es el origen del clásico "el cambio no se guardó y no hay error".

> **Veredicto:** poder decir "`@Transactional` es Unit of Work y el dirty checking es su
> mecanismo" es la respuesta que distingue a quien entiende JPA de quien lo usa.

---

## 6. 🗺️ Identity Map

**Qué es.** Un caché por transacción que garantiza que **la misma fila devuelve el mismo
objeto**.

**Qué te da Spring.** El contexto de persistencia de JPA es un Identity Map. Por eso:

```java
Cliente a = repo.findById(1L).get();
Cliente b = repo.findById(1L).get();
// a == b  → true dentro de la misma transacción: una sola consulta, un solo objeto
```

- La segunda llamada **no va a la base de datos**: la sirve el contexto de persistencia.
- Es también el caché de primer nivel de Hibernate. No hay que configurarlo: existe.

> **Veredicto:** explica por qué dos consultas idénticas en la misma transacción producen
> un solo SQL, y es la respuesta correcta a "¿qué es el caché de primer nivel?".

---

## 7. 🔀 Data Mapper vs Active Record

**Data Mapper.** Una capa traduce entre objetos y tablas; el objeto no sabe que se
persiste. **Es lo que hace JPA/Hibernate.**

**Active Record.** El objeto sabe guardarse: `pedido.save()`. Es el modelo de Rails y de
Spring Data JDBC en su forma simple.

| | Data Mapper | Active Record |
|---|---|---|
| Acoplamiento objeto↔tabla | Bajo | Alto: una clase, una tabla |
| Dominio rico | Sí | Difícil |
| Ceremonia | Alta | Baja |
| Encaja con | Hexagonal, DDD | CRUD, prototipos |

> **Veredicto:** JPA es Data Mapper, pero **el uso habitual lo degrada a Active Record**:
> si tu entidad JPA es también tu modelo de dominio y tu DTO, tienes el acoplamiento de
> Active Record pagando el precio de Data Mapper.

---

## 8. 🧩 Service Layer

**Qué es.** La frontera de la aplicación: define las operaciones disponibles, coordina
dominio y persistencia, y **es donde va la transacción**.

**El error frecuente.** Que se convierta en el vertedero de toda la lógica. Un
`@Service` de 900 líneas es una Service Layer que absorbió el Domain Model.

> **Regla:** la Service Layer **coordina**; no decide. Si tiene `if` sobre reglas de
> negocio, esa regla pertenece a la entidad.

> **Veredicto:** una Service Layer que decide reglas de negocio es un Domain Model que se fue al sitio
> equivocado. Mide su salud por el número de `if` sobre invariantes: deberían ser cero.

---
## 9. 💤 Lazy Load

**Qué es.** No traer un dato hasta que se use.

**El precio, que es la pregunta garantizada:**

- **`LazyInitializationException`**: accedes a la colección fuera de la transacción,
  cuando la entidad ya está *detached* y la sesión cerrada.
- **N+1 queries**: iteras cien pedidos y cada uno dispara una consulta por sus líneas.
  Ciento una consultas donde debía haber una.

Las soluciones, en orden de preferencia:

```text
1. JOIN FETCH o @EntityGraph   → traes lo que necesitas en una consulta
2. Proyección / DTO            → no traes la entidad, traes lo que la vista usa
3. @Transactional más amplio   → funciona y suele ser el parche, no la solución
4. OSIV (open-session-in-view) → lo desactivas; oculta el problema y lo hace peor
```

- Las dos primeras atacan la causa. Las dos últimas mantienen la sesión abierta más
  tiempo, que es el síntoma tratado como cura.
- **Spring Boot trae OSIV activo por defecto** y avisa en el log. Desactivarlo
  (`spring.jpa.open-in-view=false`) y arreglar lo que salte es la respuesta de
  arquitecto.

> 🩺 **Diagnóstico.** Para detectar N+1: activa `spring.jpa.show-sql` o el contador de
> consultas de Hibernate statistics, y ejecuta el caso de uso con diez registros. Si el
> número de consultas crece con los registros, es N+1.

> **Veredicto:** el lazy loading no es el problema; el problema es no saber cuándo se dispara. Quien
> sabe contar consultas antes de que se las cuente producción no tiene N+1.

---
## 10. 📦 DTO

**Qué es.** Un objeto plano para cruzar una frontera, agrupando datos en una sola
llamada.

**El matiz de Fowler**, que es lo que se pregunta: lo consideraba un **mal necesario de
las fronteras remotas**, no una capa obligatoria en todas partes. Su costo es el mapeo.

**Cuándo sí.** En el borde de la API, siempre: exponer la entidad JPA en el JSON acopla
tu contrato público al esquema de la base de datos, filtra campos que no deberían salir
y rompe a los clientes cuando renombras una columna.

**Cuándo no.** Entre capas internas del mismo proceso, cuando el DTO es una copia exacta
de la entidad. Ahí es mapeo puro sin beneficio.

> 💡 **Truco.** En Java moderno, un `record` como DTO más una proyección de Spring Data
> elimina el mapeo manual: la consulta construye el `record` directamente y la entidad
> ni se carga.

> **Veredicto:** DTO obligatorio en el borde remoto, sospechoso entre capas internas. El criterio no es
> la pureza arquitectónica: es si los dos lados cambian a ritmos distintos.

---
## 11. 🧭 Cómo se elige

Las tres decisiones de este capítulo, con su criterio y sin diplomacia:

```text
¿La lógica de negocio es fina, casi validación y CRUD?
    → Transaction Script. Y se declara, para que nadie crea que es un Domain Model a medias.
¿Hay invariantes que proteger y reglas que se repetirían entre casos de uso?
    → Domain Model, con la lógica en la entidad y la Service Layer solo coordinando.

¿El objeto cruza una frontera remota o una API pública?
    → DTO, siempre. Aunque hoy sea idéntico a la entidad.
¿Es una capa interna del mismo proceso y ambos cambian juntos?
    → Sin DTO. El mapeo estéril cuesta y no compra nada.

¿El dominio es núcleo y quieres testearlo sin base de datos?
    → Interfaz de repositorio propia en el dominio, JpaRepository dentro del adaptador.
¿Es un módulo de soporte?
    → JpaRepository directo, sabiendo que renunciaste al aislamiento.
```

> **Regla de entrevista:** la respuesta que más puntúa no es el nombre del patrón, es
> *"depende de si el módulo tiene invariantes; en este caso no las tiene, así que iría por
> Transaction Script y lo dejaría escrito"*. Criterio y honestidad, no doctrina.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`@Transactional` abre una transacción" | Y es Unit of Work: rastrea cambios y hace flush al commit |
| "Hay que llamar a `save()` siempre" | No, si la entidad está gestionada dentro de la transacción |
| "El modelo anémico es siempre un antipatrón" | Lo es si pagas Domain Model; con Transaction Script deliberado es coherente |
| "JPA es Active Record" | Es Data Mapper; el uso descuidado lo degrada a Active Record |
| "El N+1 se arregla con `@Transactional` más grande" | Eso oculta el síntoma; se arregla con `JOIN FETCH` o proyección |
| "El DTO es una capa obligatoria" | Obligatorio en el borde remoto; entre capas internas suele ser mapeo estéril |
| "El caché de primer nivel se configura" | No: es el contexto de persistencia, y siempre está |

---

## 📚 Para profundizar

- **Libro** — Martin Fowler, *Patterns of Enterprise Application Architecture*
  (Addison-Wesley, 2002). Capítulos 2 (organizar la lógica de dominio), 9 (Domain Logic
  Patterns) y 10–11 (Data Source y Object-Relational). El catálogo íntegro.
- **Libro** — Vlad Mihalcea, *High-Performance Java Persistence* (2016+). **El libro de
  JPA**: capítulos sobre el contexto de persistencia, dirty checking, fetching y N+1.
  Si la entrevista toca JPA en serio, es este.
- **Libro** — Eric Evans, *Domain-Driven Design* (Addison-Wesley, 2003). Capítulo 6:
  el Repository como concepto de dominio, no de infraestructura.
- [Martin Fowler — Catalog of Patterns of Enterprise Application Architecture](https://martinfowler.com/eaaCatalog/):
  la ficha corta de cada patrón, gratis y citable.
- [Spring Framework — Declarative transaction management](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative.html):
  qué hace `@Transactional` y por qué el proxy importa.
- **Tutorial** — Baeldung, «Transaction Propagation and Isolation in Spring»:
  los siete niveles de propagación con ejemplos.
- **Tutorial** — Baeldung, «The DTO Pattern»:
  el aterrizaje con `record` y proyecciones.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. ¿Qué patrón de Fowler implementa `@Transactional`? 🟢
2. ¿Qué es el dirty checking y qué permite no escribir? 🟡
3. ¿Qué patrón es el contexto de persistencia de JPA? 🟡
4. ¿Por qué dos `findById` iguales en la misma transacción hacen un solo SQL? 🟡
5. ¿Qué diferencia a Data Mapper de Active Record? 🟡
6. ¿Cómo detectas en una revisión que un modelo es anémico? 🟡
7. ¿Cuándo aparece `LazyInitializationException` y por qué? 🟡
8. ¿Qué opinaba Fowler del DTO y por qué? 🟡
9. ¿Qué es Transaction Script y cuándo es la respuesta correcta? 🟠
10. ¿Por qué el modelo anémico se considera antipatrón, y cuál es el matiz? 🟠
11. ¿Qué es el problema N+1 y cómo lo diagnosticas? 🟠
12. Enumera cuatro formas de atacar un N+1, de mejor a peor. 🟠
13. ¿Qué es OSIV, viene activo en Spring Boot, y qué harías con él? 🟠
14. ¿Por qué `JpaRepository` no es un buen puerto de dominio? 🟠
15. ¿Cuándo un DTO entre capas internas no aporta nada? 🟠
16. ¿Qué responsabilidad NO debería tener una Service Layer? 🟠
17. Un `@Service` tiene 900 líneas de `if` de negocio. ¿Qué diagnosticas? 🟠
18. Cambias una entidad dentro de `@Transactional` y no se guarda. Tres
    hipótesis en orden. 🔴
19. Diseña la capa de persistencia de un módulo hexagonal: qué interfaces, dónde
    viven, y cómo se relaciona con `JpaRepository`. 🔴
20. El equipo quiere exponer entidades JPA directamente en la API "para ir más
    rápido". Argumenta en contra con tres consecuencias concretas. 🔴

---

**Anterior:** [`04` — Patrones GoF](04-patrones-gof.md) ·
**Siguiente:** [`06` — DDD estratégico](06-ddd-estrategico.md) ·
**Relacionado:** [`07` — DDD táctico](07-ddd-tactico.md)
