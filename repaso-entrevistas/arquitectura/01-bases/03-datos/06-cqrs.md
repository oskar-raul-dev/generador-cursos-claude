# 06 — CQRS

> Separar el modelo de escritura del de lectura: qué problema resuelve de verdad, los tres
> niveles de separación —que casi nadie distingue—, por qué es independiente de event sourcing, y
> cuándo no compensa.
> Asume leído [`05` — Réplicas y lag](05-replicas-y-lag.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

El mismo modelo sirve para dos cosas que no se parecen:

```text
ESCRIBIR                          LEER
un agregado cada vez              muchos, filtrados y ordenados
invariantes que proteger          ninguna: solo mostrar
transaccional                     puede tolerar segundos de retraso
normalizado                       quiere todo junto, sin JOIN
pocas operaciones al día          miles por segundo
```

Forzar un solo modelo produce el compromiso de siempre: entidades con relaciones perezosas para
que la escritura no cargue de más, `JOIN` de seis tablas para que la pantalla muestre algo, DTOs
que aplanan lo que el dominio había estructurado, y consultas que degradan cuando crece el
volumen.

> **Regla:** no es que el modelo esté mal diseñado. Es que **hay dos problemas distintos** y les
> estás dando la misma forma.

---

## 2. ✂️ Qué es CQRS

**Qué es.** *Command Query Responsibility Segregation*: separar el modelo que escribe del que
lee. Viene de CQS de Meyer —un método o cambia estado o devuelve datos, nunca ambos— elevado a
nivel de arquitectura por Greg Young.

```text
Comando  → cambia estado, no devuelve datos (o solo un identificador)
Consulta → devuelve datos, no cambia estado
```

**Lo que NO es**, y hay que decirlo pronto porque es la confusión que arrastra a proyectos
enteros:

- **No implica event sourcing.** Son separables y casi siempre conviene separarlos. Event
  sourcing exige CQRS; CQRS no exige nada.
- **No implica dos bases de datos.** Eso es un nivel de separación, no la definición.
- **No implica mensajería.** Se puede hacer CQRS entero dentro de un proceso, síncrono.

> **Veredicto:** CQRS es un continuo, no un interruptor. El error de la mayoría de los proyectos
> es saltar al nivel 3 cuando el nivel 1 resolvía el problema.

---

## 3. 📶 Los tres niveles

**Nivel 1 — Modelos separados, misma base de datos.**

El lado de escritura usa el agregado y JPA; el de lectura usa consultas SQL directas que
proyectan a DTOs, sin pasar por el dominio.

```java
// Escritura: el agregado, con sus invariantes
pedidoService.confirmar(pedidoId);

// Lectura: SQL directo a un record. Ni entidad, ni repositorio de dominio, ni mapeo.
@Query("SELECT new ResumenPedido(p.id, c.nombre, p.total) FROM ...")
List<ResumenPedido> resumenPorCliente(ClienteId id);
```

- **Coste casi cero, beneficio inmediato**: desaparecen el N+1, los DTO intermedios y las
  relaciones perezosas puestas para que la pantalla funcione.
- **Sin consistencia eventual**: misma base de datos, misma transacción. No hay ventana.
- Es el 80 % del valor de CQRS y casi nadie lo llama CQRS.

**Nivel 2 — Bases de datos separadas, réplicas.**

Las lecturas van a una réplica; las escrituras al primario. Es
[`05`](05-replicas-y-lag.md) aplicado a CQRS.

- Escala lecturas de verdad, con el lag y las garantías de sesión que eso implica.
- Sigue habiendo un solo modelo de datos: la réplica es una copia, no una forma distinta.

**Nivel 3 — Almacén de lectura con otra forma.**

Una proyección construida a partir de eventos, en un almacén distinto y con la forma que la
consulta necesita: Elasticsearch para búsqueda, Redis para acceso por clave, una tabla plana para
un listado.

- Es el que da el salto de rendimiento real y el que trae todo el coste: consistencia eventual
  visible, reconstrucción, una proyección por consulta, y la maquinaria de
  [`02-eventos/08`](../02-eventos/08-proyecciones-y-streaming.md).

> 💡 **Truco.** Decir *"empezaría por el nivel 1, que cuesta nada y resuelve la mayoría de los
> síntomas, y solo subiría al 3 en la consulta concreta que lo exija"* es la respuesta que más
> distingue. Recitar "CQRS con event sourcing y Kafka" es la que menos.

> **Veredicto:** el nivel 1 es el 80 % del valor por el 5 % del coste, y casi nadie lo llama CQRS. Saltar
> directamente al 3 es el error más caro y más frecuente de este patrón.

---
## 4. 🔗 CQRS y event sourcing: la relación real

**Qué es.** Dos patrones que se citan juntos y no son lo mismo.

```text
Event sourcing → CQRS   OBLIGATORIO. El log no puede responder consultas por criterio.
CQRS → event sourcing   NO. CQRS funciona perfectamente sobre tablas normales.
```

- Casi todo el CQRS útil que existe en producción **no** usa event sourcing: separa modelos y
  proyecta desde eventos de integración o desde CDC, con el estado en tablas normales.
- Adoptarlos juntos multiplica el coste y la curva de entrada: versionado de eventos,
  reconstrucción, snapshots, consistencia eventual, todo a la vez.

> **Veredicto:** CQRS sin event sourcing es común, útil y barato. Event sourcing sin CQRS es
> imposible. Separar esas dos frases en voz alta cierra la pregunta.

---

## 5. ⏳ La ventana y qué ve el usuario

**Qué es.** En el nivel 3 —y en el 2 con réplicas— el usuario escribe y la lectura todavía no lo
refleja. Es el mismo problema de
[`02-eventos/08` §3](../02-eventos/08-proyecciones-y-streaming.md) y las salidas son las mismas
cuatro:

```text
1. Devolver el resultado en la respuesta del comando  → resuelve el 80 %, coste casi cero
2. Leer del modelo de escritura "lo mío"              → cubre la recarga, rompe la separación
3. Token de versión                                   → única garantía real, la más cara
4. Decírselo al usuario ("procesando")                → honesto, decisión de producto
```

- **La ventana es un requisito de producto, no un detalle técnico.** Se mide, se acuerda y se
  alerta si se supera.
- Y hay una pregunta previa que casi nadie hace: **¿cuánto dura de verdad?** Si son minutos y no
  milisegundos, el problema no es CQRS sino lag, y se arregla escalando el consumidor.

> **Veredicto:** la pregunta no es cómo eliminar la ventana, sino qué ve el usuario dentro de
> ella. Quien intenta eliminarla acaba reinventando una transacción y perdiendo el beneficio.

---

## 6. 🚫 Cuándo no compensa

**Qué es.** La sección que más rinde, porque CQRS es de los patrones más sobre-aplicados.

```text
CRUD con poca lógica         → el modelo único va bien. CQRS añade clases y no quita nada.
Lecturas y escrituras simétricas → si lees lo mismo que escribes, no hay dos problemas.
Volumen bajo                 → no hay nada que escalar; el nivel 1 como mucho.
Equipo sin experiencia       → el nivel 3 tiene una curva alta y modos de fallo nuevos.
Requisito de consistencia inmediata en la lectura → el nivel 3 no sirve; quédate en el 1.
```

- La señal más clara de que sí compensa: **la consulta que duele existe y está identificada**.
  "Listado de pedidos con datos de tres servicios, paginado y ordenado" es un caso; "queremos
  CQRS" no lo es.
- La segunda señal: **asimetría de carga real medida**. 10.000 lecturas por segundo contra 50
  escrituras justifica separar; 100 contra 80, no.

> ⚠️ **Advertencia.** CQRS aplicado a todo el sistema por dogma duplica el número de clases y
> reparte la lógica en dos sitios que pueden divergir. Se aplica **por caso de uso**, igual que
> el DDD táctico de [`01-bases/07`](../01-bases/07-ddd-tactico.md).

> **Veredicto:** CQRS es de los patrones más sobre-aplicados que existen. Saber decir *"aquí no"* con un
> criterio concreto vale más que saber implementarlo.

---
## 7. 🧭 Cómo se elige

```text
¿Hay una consulta concreta que duele, identificada y medida?
    No  → no hagas CQRS. Arregla índices y consultas primero.
    Sí  → sigue.

¿Basta con proyectar a un DTO con SQL directo, sin pasar por el dominio?
    Sí  → NIVEL 1. Cuesta nada, sin ventana, y resuelve la mayoría de los síntomas.
    No  → sigue.

¿El problema es volumen de lectura sobre los mismos datos?
    Sí  → NIVEL 2: réplicas + enrutamiento. Cuidado con read-your-writes.
    No, la FORMA del dato es el problema → sigue.

¿La consulta necesita una forma que la escritura no puede dar? (búsqueda, agregados, cruces)
    Sí  → NIVEL 3: proyección en otro almacén. Y asume todo el paquete:
          consistencia eventual · reconstrucción · una vista por consulta · su operación

¿Y event sourcing?
    → Es una decisión APARTE. CQRS no lo necesita. Decídelo por su cuenta (02-eventos/07).
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "CQRS implica event sourcing" | Al revés: event sourcing exige CQRS, no a la inversa |
| "CQRS son dos bases de datos" | Eso es el nivel 2 o 3; el nivel 1 comparte base de datos |
| "CQRS necesita mensajería" | El nivel 1 es síncrono y en el mismo proceso |
| "Aplicamos CQRS en todo el sistema" | Se aplica por caso de uso; por dogma duplica clases sin retorno |
| "CQRS siempre tiene consistencia eventual" | Solo del nivel 2 en adelante |
| "Hacemos CQRS para ir más rápido" | ¿Qué consulta duele? Sin ella, es complejidad sin problema |
| "La ventana hay que eliminarla" | Hay que decidir qué ve el usuario dentro de ella |

---

## 📚 Para profundizar

- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulo 7: CQRS como
  solución a las consultas que cruzan servicios, con la composición de API como alternativa.
  **El más aplicable.**
- **Libro** — Vaughn Vernon, *Implementing Domain-Driven Design* (Addison-Wesley, 2013).
  Capítulo 4 y apéndice: CQRS junto a los agregados, y cómo se separan los modelos.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 11: por qué tener varias vistas derivadas del mismo dato es la norma y no la
  excepción.
- Martin Fowler — [CQRS](https://martinfowler.com/bliki/CQRS.html): la ficha, con la advertencia
  explícita de que se sobre-aplica.
- [microservices.io — CQRS](https://microservices.io/patterns/data/cqrs.html): fuerzas, contras
  y su relación con event sourcing.
- [microservices.io — API composition](https://microservices.io/patterns/data/api-composition.html):
  la alternativa más barata, con sus límites de paginación y ordenación.
- **Video** — GOTO Conferences y Domain-Driven Design Europe, charlas de Greg Young sobre CQRS,
  incluidas las que corrigen su propia sobre-aplicación. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué significa CQRS? 🟢
2. ¿De qué principio de Meyer deriva? 🟢
3. ¿Cuáles son los tres niveles de separación? 🟢
4. ¿Qué es un comando y qué es una consulta, en este contexto? 🟢
5. ¿Necesita CQRS event sourcing? 🟡
6. ¿Necesita event sourcing CQRS? 🟡
7. ¿Qué es el nivel 1 y qué cuesta? 🟡
8. ¿En qué nivel aparece la consistencia eventual? 🟡
9. ¿Qué diferencias hay entre el nivel 2 y el nivel 3? 🟡
10. ¿Por qué el modelo único produce N+1 y DTOs intermedios? 🟡
11. Nombra cuatro formas de manejar la ventana de cara al usuario. 🟡
12. ¿Por qué el nivel 1 es "el 80 % del valor"? 🟠
13. ¿Cuándo NO compensa CQRS? 🟠
14. ¿Qué dos señales indican que sí compensa? 🟠
15. ¿Por qué CQRS se aplica por caso de uso y no al sistema? 🟠
16. ¿Qué preguntas antes de subir del nivel 1 al nivel 3? 🟠
17. ¿Por qué intentar eliminar la ventana es un error? 🟠
18. Si la ventana dura minutos en vez de milisegundos, ¿qué diagnosticas? 🟠
19. ¿Qué pasa si aplicas CQRS por dogma a todo el sistema? 🟠
20. ¿Por qué CQRS sin event sourcing es lo común en producción? 🟠
21. Una pantalla cruza datos de pedidos, clientes y envíos, con filtro y
    paginación, y tarda 6 segundos. Diseña la solución por niveles. 🔴
22. Te proponen CQRS con event sourcing y Kafka para un CRUD de catálogo.
    Argumenta y propón la alternativa. 🔴
23. Diseña el lado de lectura de "buscar pedidos por texto libre, filtrar por
    estado y ordenar por fecha", con 200 peticiones por segundo. 🔴

---

**Anterior:** [`05` — Réplicas y lag](05-replicas-y-lag.md) ·
**Siguiente:** [`07` — Caché](07-cache.md) ·
**Relacionado:** [`02-eventos/07` — Event sourcing](../02-eventos/07-event-sourcing.md)
