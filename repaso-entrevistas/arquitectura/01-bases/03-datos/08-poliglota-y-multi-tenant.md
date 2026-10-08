# 08 — Persistencia políglota y multi-tenant

> Cuándo tener varias bases de datos es diseño y cuándo es acumulación, y las tres formas de
> aislar los datos de varios clientes en el mismo sistema, con su coste real en operación,
> cumplimiento normativo y facturación.
> Asume leído [`07` — Caché](07-cache.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Dos preguntas distintas que acaban en el mismo capítulo porque comparten la trampa: **más
separación parece siempre mejor y nunca lo es gratis.**

```text
Políglota   → "cada servicio elige su base de datos" suena a autonomía.
              También significa N tecnologías que operar, respaldar y parchear.

Multi-tenant→ "cada cliente su base de datos" suena a aislamiento perfecto.
              También significa N migraciones, N backups y N conexiones.
```

> **Regla:** en ambos casos, la pregunta no es "¿cuánto puedo separar?" sino "¿qué separación
> compra algo que no puedo conseguir más barato?".

---

# Parte I — Persistencia políglota

## 2. 🧩 Qué es y qué compra

**Qué es.** Usar la tecnología de almacenamiento que mejor encaja con cada problema, en vez de
forzar todo a una sola. El término es de Fowler y Sadalage.

```text
Pedidos y pagos        → relacional. Transacciones, integridad, consultas no previstas.
Catálogo con búsqueda  → índice invertido (Elasticsearch). Texto libre, facetas, relevancia.
Sesión y contadores    → clave-valor en memoria (Redis).
Recomendación, fraude  → grafo (Neo4j). Relaciones de profundidad variable.
Series temporales      → columnar o específico. Escritura masiva ordenada por tiempo.
```

- **La justificación tiene que ser una capacidad que el motor actual no tiene**, no una
  preferencia. "Búsqueda por texto con relevancia" es una capacidad; "es más moderno" no.
- Postgres, en particular, cubre bastantes de esos casos —`JSONB`, búsqueda de texto,
  `pg_trgm`— y usarlo antes de añadir un motor es la respuesta barata que casi nadie propone.

**Cuándo sí.** Cuando una necesidad concreta está identificada, medida y el motor actual no la
cubre aceptablemente.

**Cuándo no.** Cuando la razón es autonomía de equipo sin necesidad técnica, o curiosidad. Cada
motor añadido trae respaldo, monitorización, parcheo, experiencia que alguien debe tener a las
tres de la mañana, y un modo de fallo nuevo.

> 💰 **Costo.** El coste de una tecnología de datos no es la licencia: es la **guardia**. Añadir
> un motor significa que alguien tiene que saber diagnosticarlo bajo presión, y eso escala mal con
> el tamaño del equipo.

> **Veredicto:** políglota es una decisión de **capacidad**, no de gusto. Y la primera pregunta
> siempre es si lo que necesitas cabe en lo que ya tienes.

---

## 3. 🔗 Mantener coherentes varios almacenes

**Qué es.** El problema que la persistencia políglota crea: el mismo dato vive en dos sitios y
tienen que coincidir.

- **Una fuente de verdad, el resto derivados.** El relacional manda; Elasticsearch y Redis son
  proyecciones. Si divergen, se reconstruyen desde la fuente. Es
  [`02-eventos/08`](../02-eventos/08-proyecciones-y-streaming.md) aplicado aquí.
- **La propagación va por eventos o por CDC**, nunca por doble escritura en el mismo método: eso
  es el problema de la doble escritura de
  [`02-eventos/06`](../02-eventos/06-outbox-y-cdc.md), y se resuelve igual, con outbox.
- **Hace falta poder reconstruir**, y hace falta un mecanismo de **reconciliación** que detecte la
  divergencia: un conteo comparado, un muestreo periódico.

> **Veredicto:** políglota sin una fuente de verdad declarada no es políglota, son dos sistemas
> que se contradicen. La pregunta *"¿quién manda si no coinciden?"* tiene que tener respuesta
> antes de añadir el segundo motor.

---

# Parte II — Multi-tenant

## 4. 🏢 Las tres estrategias

**Qué es.** Cómo se separan los datos de distintos clientes en un sistema compartido. Son tres y
la elección se pregunta mucho en producto B2B y en banca.

**1. Base de datos por tenant.** Cada cliente, su base de datos.

```text
+ Aislamiento máximo: fallo, rendimiento y seguridad separados por construcción
+ Restaurar el backup de UN cliente es trivial
+ Residencia de datos por país, si la normativa lo exige
+ Facturación por consumo real, medible
− N migraciones de esquema, y pueden divergir
− N conexiones: 500 tenants no caben en un pool
− Coste fijo por tenant: inviable con muchos clientes pequeños
```

**2. Esquema por tenant.** Una base de datos, un esquema por cliente.

```text
+ Aislamiento lógico razonable, backup selectivo posible
+ Una sola instancia que operar
− Sigue habiendo N migraciones
− Muchos esquemas degradan el catálogo del motor
```

**3. Tabla compartida con `tenant_id`.** Todos en las mismas tablas, discriminados por columna.

```text
+ Una migración, un backup, un pool. Escala a miles de tenants
+ Coste marginal por tenant casi cero
− El aislamiento depende de que NUNCA falte el filtro. Un olvido = fuga de datos entre clientes
− Un tenant grande degrada a todos (vecino ruidoso)
− Restaurar un solo tenant es un ejercicio manual
```

> ⚠️ **Advertencia.** En la opción 3, **el aislamiento es responsabilidad del código**, y ese es
> su riesgo real. Un `WHERE tenant_id = ?` olvidado en una consulta es una fuga de datos entre
> clientes: el incidente más grave posible en un producto B2B.

> **Veredicto:** ninguna de las tres es la respuesta en un producto real: los tenants no son homogéneos, y
> el modelo híbrido con directorio es lo que se acaba usando.

---
## 5. 🛡️ Hacer seguro el modelo compartido

**Qué es.** Lo que convierte la opción 3 de "arriesgada" en "aceptable", y es lo que demuestra
experiencia real.

```text
1. Row-Level Security del motor     → Postgres filtra por política, aunque el SQL no lo pida.
                                      Es la ÚNICA defensa que no depende de la disciplina.
2. Filtro automático en el ORM      → @TenantId de Hibernate, o un filtro global.
3. Tenant en el contexto de petición→ resuelto en un único punto, nunca pasado como parámetro
4. Tests que verifican el aislamiento→ un test que consulta con el tenant A y espera cero filas de B
5. Índices que empiezan por tenant_id→ o cada consulta escanea datos de todos
```

- **La 1 es la que cambia el juego.** Con *Row-Level Security*, un desarrollador que olvide el
  filtro no ve datos ajenos: el motor los oculta. Todo lo demás es mitigación.
- **La 5 es de rendimiento y se olvida**: sin `tenant_id` como primera columna del índice, las
  consultas de un cliente pequeño recorren datos de todos.

**El vecino ruidoso** se ataca con límites de tasa por tenant, cuotas, y —cuando uno crece
demasiado— **moviéndolo a su propia base de datos**. Por eso la estrategia de directorio de
[`04` §3](04-sharding-y-particionado.md#3--estrategias-de-reparto) encaja tan bien aquí: permite
modelos mixtos.

> 💡 **Truco.** La respuesta madura no es elegir una de las tres, es **el modelo híbrido**: tabla
> compartida para la mayoría, base de datos propia para los tenants grandes o con requisitos de
> residencia. Un directorio dice dónde vive cada uno.

> **Veredicto:** en tabla compartida, el aislamiento que depende de la disciplina **no es aislamiento**.
> Row-Level Security es la única medida que protege cuando alguien se olvida, y por eso no
> es opcional.

---
## 6. 🧭 Cómo se elige

```text
POLÍGLOTA
    ¿Qué capacidad concreta necesitas que el motor actual no da?
        No sabes nombrarla         → no añadas un motor
        ¿Cabe en Postgres? (JSONB, texto, extensiones) → úsalo. Casi siempre cabe.
        No cabe                    → añade el motor, con fuente de verdad declarada
                                     y propagación por eventos o CDC, nunca doble escritura

MULTI-TENANT
    ¿Cuántos tenants y de qué tamaño?
        Pocos y grandes (decenas)        → base de datos por tenant
        Muchos y pequeños (miles)        → tabla compartida con tenant_id
        Mezcla, con algunos enormes      → HÍBRIDO + directorio. La respuesta real.

    ¿Hay requisito regulatorio de residencia o de aislamiento físico?
        → base de datos por tenant para ESOS, compartida para el resto

    Si eliges compartida, no es negociable:
        Row-Level Security + filtro en el ORM + tenant en el contexto
        + tests de aislamiento + tenant_id como primera columna del índice
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Cada servicio elige su base de datos" | Cada motor añade respaldo, parcheo y guardia; hace falta una capacidad concreta |
| "Añadimos Elasticsearch para buscar" | ¿Probaste la búsqueda de texto de Postgres? Casi siempre basta |
| "Sincronizo los dos almacenes al escribir" | Doble escritura: se resuelve con outbox o CDC, no con dos `save()` |
| "Base de datos por tenant es más seguro" | Y son N migraciones, N backups y N conexiones; no escala a miles |
| "Filtro por `tenant_id` en el repositorio" | Basta un olvido para una fuga; hace falta Row-Level Security |
| "El vecino ruidoso se arregla escalando" | Se arregla con cuotas por tenant, y moviendo al grande a su base |
| "Hay que elegir una de las tres" | El modelo híbrido con directorio es lo que se usa en producción |

---

## 📚 Para profundizar

- **Libro** — Pramod Sadalage y Martin Fowler, *NoSQL Distilled* (Addison-Wesley, 2012).
  Capítulo 13: el origen del término persistencia políglota y su criterio de aplicación.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulos 1 a 3: por qué distintos motores resuelven problemas distintos, y qué se paga por
  mantener varias copias coherentes.
- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulos 4 y 5:
  mantener la coherencia entre almacenes con eventos, aplicado aquí.
- Martin Fowler — [PolyglotPersistence](https://martinfowler.com/bliki/PolyglotPersistence.html):
  la ficha original, con la advertencia sobre su coste.
- [PostgreSQL — Row Security Policies](https://www.postgresql.org/docs/current/ddl-rowsecurity.html):
  el mecanismo que hace seguro el modelo de tabla compartida.
- [PostgreSQL — Full Text Search](https://www.postgresql.org/docs/current/textsearch.html): la
  capacidad que evita añadir un motor de búsqueda en muchos casos.
- [Debezium — Architecture](https://debezium.io/documentation/reference/stable/architecture.html):
  cómo se propagan los cambios entre almacenes sin doble escritura.
- **Video** — GOTO Conferences, charlas sobre arquitecturas multi-tenant y sobre el coste real de
  la persistencia políglota. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es la persistencia políglota? 🟢
2. Nombra las tres estrategias de multi-tenancy. 🟢
3. ¿Qué es el vecino ruidoso? 🟢
4. ¿Qué es Row-Level Security? 🟢
5. ¿Qué motor usarías para búsqueda por texto con relevancia? 🟢
6. ¿Qué justifica añadir un motor de datos nuevo? 🟡
7. ¿Cuál es el coste real de añadir una tecnología de datos? 🟡
8. ¿Cómo se propagan los cambios entre dos almacenes? 🟡
9. ¿Qué ventajas tiene base de datos por tenant? 🟡
10. ¿Qué ventajas tiene la tabla compartida con `tenant_id`? 🟡
11. ¿Por qué Postgres evita muchas decisiones de políglota? 🟠
12. ¿Cuál es el riesgo principal de la tabla compartida? 🟠
13. ¿Por qué Row-Level Security es distinta de un filtro en el ORM? 🟠
14. ¿Por qué `tenant_id` debe ser la primera columna del índice? 🟠
15. ¿Qué significa "una fuente de verdad, el resto derivados"? 🟠
16. ¿Por qué base de datos por tenant no escala a miles? 🟠
17. ¿Cómo se ataca el vecino ruidoso? 🟠
18. ¿Qué es el modelo híbrido y por qué es la respuesta real? 🟠
19. ¿Qué pasa si no declaras quién manda cuando dos almacenes divergen? 🟠
20. ¿Qué cinco medidas hacen aceptable el modelo de tabla compartida? 🟠
21. Diseña la multi-tenancy de un SaaS con 3.000 clientes pequeños y 5 grandes,
    uno de ellos con requisito de residencia de datos en la UE. 🔴
22. Te proponen añadir MongoDB "porque el esquema del catálogo cambia mucho".
    ¿Qué preguntas y qué propones? 🔴
23. Un cliente reporta que vio datos de otro cliente. Describe la investigación
    y las medidas, inmediatas y de fondo. 🔴

---

**Anterior:** [`07` — Caché](07-cache.md) ·
**Siguiente:** [`09` — Simulación de entrevista](09-simulacion-de-entrevista.md) ·
**Relacionado:** [`04` — Sharding y particionado](04-sharding-y-particionado.md)
