# 06 — Simulación de entrevista

> El examen del bloque `07-fowler-dominio-y-datos`: preguntas transversales que cruzan los cinco capítulos y cinco
> ejercicios de diseño de veinte minutos. Asume leídos los capítulos [`01`](01-logica-de-dominio.md) a
> [`05`](05-metadatos-y-consultas.md). Las respuestas, en
> [`07` — Respuestas](07-respuestas.md#06--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Diciendo qué hace JPA por dentro.** En este bloque el entrevistador casi siempre pregunta por patrones con nombre de
  Fowler y espera oír cómo se ven en JPA: el `EntityManager`, `@Version`, `JOIN FETCH`, `mappedBy`.
- **Con SQL a mano.** Los ejercicios de mapeo se resuelven escribiendo las tablas, no solo las anotaciones.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Organizar la lógica

**S1.** ¿Qué diferencia hay entre Transaction Script y Domain Model, y cuál es la señal para cambiar? 🟡

**S2.** ¿Por qué un modelo anémico es un Transaction Script disfrazado? 🟠

**S3.** ¿Qué decide la Service Layer y qué no? 🟠

**S4.** ¿Qué es un Table Module, y por qué se ve poco en Java? 🟢

### Bloque B — Fuentes de datos

**S5.** ¿Qué diferencia hay entre Active Record y Data Mapper? 🟡

**S6.** ¿Por qué JPA es un Data Mapper y no un Active Record? 🟠

**S7.** ¿Qué diferencia hay entre DAO, Data Mapper y Repository? 🟡

**S8.** ¿Por qué el mapeador necesita un camino de reconstrucción distinto del constructor? 🟠

### Bloque C — Lo que hace el `EntityManager`

**S9.** ¿Qué tres patrones de Fowler es el `EntityManager`? 🟢

**S10.** ¿Por qué no hace falta llamar a `save` dentro de una transacción? 🟠

**S11.** ¿Qué es el N+1 y cómo se evita? 🟠

**S12.** ¿Por qué aparece `LazyInitializationException`? 🟠

**S13.** ¿Qué diferencia hay entre una entidad gestionada y una separada? 🟡

**S14.** ¿Por qué el Identity Map no es una caché de rendimiento? 🟠

### Bloque D — Estructura

**S15.** ¿Cómo eliges entre `SINGLE_TABLE`, `JOINED` y `TABLE_PER_CLASS`? 🟠

**S16.** ¿Qué es un Embedded Value, y por qué un `Dinero` no tiene tabla propia? 🟢

**S17.** ¿Qué pasa si solo actualizas el lado inverso de una relación en JPA? 🟠

**S18.** ¿Clave natural o subrogada, y por qué? 🟡

### Bloque E — Consultas

**S19.** ¿Por qué un Repository no tiene `update`? 🟠

**S20.** ¿Cuándo usarías una `Specification` en lugar de un método con nombre? 🟡

**S21.** ¿Por qué no exponer `JpaRepository` al dominio? 🟠

### Bloque F — Los lenguajes

**S22.** ¿Qué es el `DbContext` de Entity Framework en términos de Fowler? 🟢

**S23.** ¿Por qué este bloque casi no tiene C++? 🟡

**S24.** ¿Qué marcos de otros lenguajes son Active Record y cuáles Data Mapper? 🟡

### Bloque G — Las que descolocan

**S25.** "Usamos Domain Model en todos los servicios, también en el de catálogos." ¿Qué preguntas? 🔴

**S26.** "Los ORM son lentos; nosotros escribimos todo en SQL." ¿Qué respondes? 🔴

**S27.** El entrevistador dice que `save` siempre hace falta "por seguridad". ¿Cómo lo manejas? 🔴

**S28.** "¿Para qué Repository si ya tengo Spring Data?" 🔴

**S29.** "Activamos `EAGER` en todas las relaciones para evitar `LazyInitializationException`." ¿Qué le dices? 🔴

**S30.** Te piden que expliques el `EntityManager` sin nombrar JPA. ¿Qué dices? 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — Dos casos, dos organizaciones (elegir)

**Fuerza:** elegir entre Transaction Script y Domain Model por la forma de las reglas, no por costumbre.

1. El mantenimiento del catálogo de países: alta, cambio de nombre y baja, con la única regla de que el código ISO no se
   repita.
2. Las transferencias entre cuentas: estado de la cuenta, saldo suficiente, límite diario por tipo de cuenta, comisión,
   y la misma lógica desde la API, desde los pagos programados y desde la nómina.

Di qué organización usarías en cada uno y por qué.

### E2 — Dos lecturas de Ana (explicar)

**Fuerza:** explicar el Identity Map y los estados de una entidad con un caso concreto.

```java
@Transactional
public void caso1() {
    Persona a = em.find(Persona.class, 1L);
    Persona b = em.find(Persona.class, 1L);
    a.cambiarNombre("Ana María Rojas Medina");
    System.out.println(a == b);              // ¿qué imprime?
    System.out.println(b.nombre());          // ¿y esto?
}

public void caso2() {
    Persona a = servicio.leer(1L);           // cada llamada, su propia transacción
    Persona b = servicio.leer(1L);
    System.out.println(a == b);              // ¿y aquí?
    System.out.println(a.equals(b));         // ¿de qué depende?
}
```

Explica qué imprime cada línea y por qué.

### E3 — El repositorio de personas (diseñar)

**Fuerza:** diseñar un Repository por agregado, con lo que el dominio necesita y nada más.

El alta, la edición del tutor, la importación nocturna y la pantalla de búsqueda (por nombre, nacionalidad y rango de
edad, todos opcionales) necesitan personas. Diseña la interfaz, di dónde vive, y escribe la implementación de la
búsqueda.

### E4 — Los documentos vencidos (elegir, sin patrón)

**Fuerza:** reconocer que un cambio masivo es una sentencia SQL, no un recorrido de entidades.

Cada noche hay que marcar como `VENCIDO` todos los documentos cuya fecha de vencimiento ya pasó. Son tres millones de
documentos. Un compañero propone cargar las personas con sus documentos, recorrerlos y llamar a `documento.vencer()`.
Diseña la solución.

### E5 — Los titulares de una cuenta (modelar)

**Fuerza:** mapear una asociación de varios a varios con datos y un titular que puede ser de dos tipos.

Una cuenta puede tener varios titulares, cada uno con un porcentaje y una fecha desde; un titular puede ser una persona o
una organización. Dibuja el modelo, escribe las tablas y las anotaciones esenciales.

---

## 4. 🧭 Las frases que hay que tener listas

> "JPA es un Data Mapper con Unit of Work, Identity Map y Lazy Load: no llamo a `save` sobre entidades gestionadas, dos
> `find` de la misma fila en una transacción son `==`, y un bucle sobre colecciones perezosas es un N+1."

> "Transaction Script para lo simple; Domain Model cuando las reglas se repiten entre operaciones. La Service Layer
> coordina y pone la transacción; no decide reglas."

> "Un Repository es una colección del dominio por agregado; un DAO habla de tablas."

---

**Anterior:** [`05` — Metadatos y consultas](05-metadatos-y-consultas.md) ·
**Siguiente:** [`07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`03` — Comportamiento objeto-relacional](03-comportamiento-objeto-relacional.md)
