# 03 — Relacional, NoSQL y DynamoDB

> Cuándo deja de servir el modelo relacional, qué familias de NoSQL existen y para qué, y
> **DynamoDB con detalle** — porque es la base NoSQL que más se pregunta en backend Java sobre AWS
> y porque su modelo de diseño invierte todo lo que enseña SQL.
> Asume leído [`02` — Transacciones y bloqueo](02-transacciones-y-bloqueo.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

*"¿SQL o NoSQL?"* mal respondida suena a moda. Bien respondida empieza por reconocer lo que el
modelo relacional hace mejor que nadie, y solo entonces dice qué lo rompe:

```text
El relacional te da, gratis y bien:
  consistencia transaccional · consultas que no previste · integridad referencial
  un lenguaje que todo el mundo conoce · décadas de herramientas

Deja de servir cuando:
  el volumen supera lo que una máquina escribe    → y escalar escrituras exige repartir
  el esquema varía mucho entre filas              → y acabas con 40 columnas nulas
  el acceso es siempre por la misma clave         → y pagas un motor de consultas que no usas
  necesitas latencia de un dígito garantizada     → a cualquier escala
```

> **Regla de entrevista:** el relacional es el valor por defecto y necesita poca justificación.
> Lo que sí la necesita es **no** usarlo, y la justificación tiene que ser una de esas cuatro.

---

## 2. 🗂️ Las familias de NoSQL

**Qué es.** Cuatro modelos de datos distintos que comparten poco más que el nombre.

| Familia | Modelo | Bueno para | Ejemplos |
|---|---|---|---|
| **Clave-valor** | Mapa | Sesión, caché, contadores | Redis, DynamoDB |
| **Documento** | JSON anidado por clave | Agregados completos, esquema variable | MongoDB, DocumentDB |
| **Columnar ancho** | Filas con columnas dinámicas por clave | Series temporales, escritura masiva | Cassandra, HBase |
| **Grafo** | Nodos y aristas | Relaciones profundas: fraude, recomendación | Neo4j |

- **Clave-valor y documento son un continuo**: DynamoDB es clave-valor con documentos dentro.
- **La familia de grafo es la única que resuelve algo que el relacional no puede**: consultas de
  profundidad variable —"amigos de amigos hasta el sexto grado"— que en SQL serían `JOIN`
  recursivos inviables.
- Las otras tres resuelven **escala y forma**, no expresividad.

**Cuándo sí NoSQL.** Cuando una de las cuatro condiciones de §1 se cumple de verdad, con números.

**Cuándo no.** Cuando el argumento es "es más moderno", "es más rápido" o "escala mejor" sin
medida. Y cuando necesitas consultas ad hoc que no puedes prever: ahí el relacional no tiene
rival.

> **Veredicto:** "NoSQL" no es una categoría útil: agrupa cuatro cosas que no se parecen. La
> pregunta correcta nunca es "¿SQL o NoSQL?" sino "¿qué patrón de acceso tengo?".

---

## 3. 🔑 DynamoDB: el modelo

**Qué es.** Base de datos clave-valor y documental, totalmente gestionada, con latencia de un
dígito en milisegundos a cualquier escala. Su modelo es simple y **estricto**, y ahí está todo.

```text
Tabla
 └ Partition Key (PK)  → decide en qué partición física vive el elemento. OBLIGATORIA.
   └ Sort Key (SK)     → ordena los elementos dentro de esa partición. Opcional.

Clave primaria = PK sola  (simple)   → acceso solo por igualdad exacta
               = PK + SK  (compuesta)→ acceso por PK exacta + rango sobre SK
```

**Las tres operaciones, y la diferencia entre ellas lo es todo:**

```text
GetItem → un elemento por clave completa.      Coste fijo. Lo que quieres.
Query   → PK exacta + condición sobre SK.      Coste proporcional a lo leído. Bien.
Scan    → recorre TODA la tabla y filtra.      Coste proporcional a la TABLA. Casi siempre un bug.
```

- **`Scan` es la señal de que el modelo está mal.** Filtra *después* de leer, así que pagas por
  todo aunque devuelvas tres elementos. En una tabla de 50 GB, un `Scan` cuesta 50 GB de lectura.
- **No hay `JOIN`, no hay agregaciones, no hay `ORDER BY` arbitrario.** El orden lo da la SK y
  nada más.

> ⚠️ **Advertencia.** La pregunta trampa clásica: *"¿cómo buscas por un campo que no es la
> clave?"*. Si respondes `Scan` con filtro, has fallado. La respuesta es un índice secundario, o
> rediseñar la clave.

> **Veredicto:** DynamoDB no es "una base de datos rápida": es una estructura de datos con un
> contrato de acceso muy estricto. Si tus consultas caben en ese contrato, es imbatible; si no,
> pelearás con ella para siempre.

---

## 4. 🔄 Diseño a partir del acceso

**Qué es.** La inversión mental que hay que hacer, y es lo que más se pregunta:

```text
Relacional:  modelas las entidades → normalizas → luego consultas como quieras
DynamoDB:    enumeras las CONSULTAS → diseñas la tabla para servirlas → y ya no cambia fácil
```

- **Se empieza por la lista de patrones de acceso**, escrita antes de tocar nada: "dame el pedido
  por id", "dame los pedidos de un cliente por fecha descendente", "dame los pedidos pendientes
  de hoy". Sin esa lista no se puede diseñar.
- **Se desnormaliza a propósito.** Duplicar el nombre del cliente en cada pedido no es un error:
  es el diseño. El coste de almacenamiento es trivial comparado con el de una consulta cruzada
  que no existe.
- **Single-table design**: todas las entidades del dominio en una sola tabla, distinguidas por el
  prefijo de sus claves. Permite traer un agregado entero —el pedido y sus líneas— en un solo
  `Query`.

```text
PK                 SK                     atributos
CLIENTE#42         PERFIL                 nombre, email
CLIENTE#42         PEDIDO#2026-09-01#771  total, estado     ← Query PK=CLIENTE#42, SK inicia por PEDIDO#
PEDIDO#771         CABECERA               cliente, total
PEDIDO#771         LINEA#01               producto, cantidad ← Query PK=PEDIDO#771 trae todo el pedido
PEDIDO#771         LINEA#02               producto, cantidad
```

- El patrón `TIPO#id` en las claves es la convención: hace legibles las claves y permite
  consultas por prefijo con `begins_with`.
- La fecha en la SK ordenada como `AAAA-MM-DD` es lo que permite "pedidos de un cliente entre dos
  fechas" sin índice adicional.

**Cuándo sí single-table.** Cuando las entidades se consultan juntas y el dominio es estable.

**Cuándo no.** Cuando el equipo no lo ha hecho antes y el dominio todavía cambia: es difícil de
leer, difícil de evolucionar, y una tabla por entidad es un punto de partida honesto que se puede
unificar después.

> 💡 **Truco.** Decir *"empezaría con una tabla por entidad y unificaría solo si las consultas lo
> exigen"* es más maduro que recitar single-table como dogma. La comunidad de DynamoDB se ha
> movido en esa dirección.

> **Veredicto:** en DynamoDB el modelo de datos no se diseña, se **deriva** de la lista de consultas. Si
> no puedes escribir esa lista, no estás listo para diseñar la tabla.

---
## 5. 📇 Índices secundarios

**Qué es.** El mecanismo para consultar por algo que no es la clave principal. Hay dos y se
confunden:

| | GSI (Global) | LSI (Local) |
|---|---|---|
| Cambia la PK | ✅ Sí, otra PK y SK | ❌ No: misma PK, otra SK |
| Cuándo se crea | En cualquier momento | **Solo al crear la tabla** |
| Consistencia | **Solo eventual** | Puede ser fuerte |
| Capacidad | Propia, separada | Comparte con la tabla |
| Límite por tabla | 20 por defecto | 5, y no se pueden borrar |

- **El GSI es el que usarás.** El LSI es rígido —hay que decidirlo al crear la tabla y no se
  puede quitar— y casi nunca compensa.
- **Un GSI es una tabla derivada mantenida por DynamoDB**: se escribe al escribir la principal,
  así que **duplica el coste de escritura** por cada índice.
- **Proyección**: eliges qué atributos se copian al índice (`KEYS_ONLY`, `INCLUDE`, `ALL`). Con
  `KEYS_ONLY` ahorras espacio y luego necesitas un `GetItem` más por elemento.

> ⚠️ **Advertencia.** Un GSI es **siempre eventualmente consistente**, sin excepción y sin flag
> que lo cambie. Leer inmediatamente después de escribir por un GSI puede no devolver el
> elemento. Es una de las preguntas favoritas y casi nadie la sabe.

> **Veredicto:** cada GSI es una escritura más y una ventana de inconsistencia más. Añadirlos por
> si acaso es la forma más común de duplicar la factura de DynamoDB.

---

## 6. 🔥 Particiones calientes y capacidad

**Qué es.** DynamoDB reparte los datos en particiones físicas por el hash de la PK, y cada
partición tiene un techo propio de throughput. Una clave con tráfico desproporcionado satura su
partición mientras las demás están ociosas.

**Las claves que lo provocan**, y son las que se eligen sin pensar:

```text
MAL:  estado ("PENDIENTE" / "ENVIADO")     → dos valores para millones de elementos
MAL:  fecha del día ("2026-09-17")         → todo el tráfico de hoy en una partición
MAL:  paísId en una app de un solo país    → cardinalidad 1
BIEN: pedidoId, clienteId, sesionId        → cardinalidad alta y reparto uniforme
```

- **La técnica de dispersión (*write sharding*)**: si necesitas agrupar por algo de baja
  cardinalidad, añade un sufijo aleatorio acotado — `PENDIENTE#3` con 10 valores— y consulta las
  10 particiones en paralelo. Multiplica el paralelismo por diez a cambio de diez consultas.
- **Modos de capacidad**: `on-demand` cobra por petición y absorbe picos sin configurar;
  `provisioned` cobra por capacidad reservada y sale más barato con carga predecible y sostenida.

> 💰 **Costo.** En DynamoDB el modelo de datos **es** el modelo de costes. Un `Scan` mal puesto o
> un GSI innecesario se ven en la factura al día siguiente, a diferencia de un `JOIN` lento en
> SQL, que solo se ve en la latencia.

> **Veredicto:** elegir la clave de partición es la decisión más importante y la más
> irreversible del diseño. Cambiarla después exige migrar la tabla entera.

---

## 7. 🧩 Lo que DynamoDB sí tiene y sorprende

**Transacciones.** `TransactWriteItems` da atomicidad sobre hasta 100 elementos, incluso en
tablas distintas. No es una transacción larga: es una operación única todo-o-nada, y cuesta el
doble de capacidad.

**Escrituras condicionales.** `ConditionExpression` permite "escribe solo si el atributo `version`
vale X" — que es **bloqueo optimista** de
[`02` §5](02-transacciones-y-bloqueo.md#5--bloqueo-optimista), integrado en la operación y sin
transacción.

**TTL.** Un atributo con marca de tiempo y DynamoDB borra el elemento solo. Es la forma natural de
implementar las reservas con caducidad de una saga.

**Streams.** Un log de cambios de la tabla, consumible por Lambda. Es CDC integrado, y es cómo se
construyen proyecciones y se propagan eventos desde DynamoDB.

> **Veredicto:** las escrituras condicionales y los streams son las dos piezas que convierten a
> DynamoDB de "almacén de claves" en algo con lo que se puede construir un dominio. Nombrarlas
> demuestra uso real.

---

## 8. 🧭 Cómo se elige

```text
¿Sabes de antemano cómo vas a consultar, y no va a cambiar mucho?
    No  → RELACIONAL. Las consultas que no previste son gratis en SQL y carísimas en Dynamo.
    Sí  → sigue.

¿Tienes alguna de las cuatro razones de §1, con números?
    No  → RELACIONAL. Es el valor por defecto y lo hace todo bien.
    Sí  → sigue.

¿Qué forma tiene el acceso?
    Siempre por una clave, latencia estricta, escala grande  → DynamoDB
    Agregado completo, esquema variable entre documentos     → documental
    Escritura masiva ordenada por tiempo                     → columnar ancho
    Relaciones de profundidad variable                       → grafo
    Estado efímero, contadores, sesión                       → clave-valor en memoria

Si eliges DynamoDB, lo primero que escribes NO es el esquema:
    → es la LISTA DE PATRONES DE ACCESO. Sin ella no se puede diseñar la clave.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "NoSQL escala mejor" | Escala **escrituras repartiendo**; a cambio pierdes consultas ad hoc |
| "Uso `Scan` con un filtro" | El filtro se aplica **después** de leer: pagas por toda la tabla |
| "Un GSI puede leerse fuerte" | Nunca: los GSI son siempre eventualmente consistentes |
| "Añado índices por si acaso" | Cada GSI duplica el coste de escritura y añade su ventana |
| "Desnormalizar es un error" | En DynamoDB es el diseño, no un atajo |
| "Single-table siempre" | Empieza por tabla por entidad si el dominio aún cambia |
| "Uso el estado como clave de partición" | Cardinalidad mínima: partición caliente garantizada |
| "DynamoDB no tiene transacciones" | Sí: hasta 100 elementos, atómicas, al doble de coste |

---

## 📚 Para profundizar

- **Libro** — Alex DeBrie, *The DynamoDB Book* (2020). **Es el libro de DynamoDB**: patrones de
  acceso, single-table design, índices y modelado de relaciones. Si la entrevista pide DynamoDB
  en serio, es este y no hay alternativa.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 2: modelos de datos y lenguajes de consulta, con la comparación relacional /
  documento / grafo mejor argumentada que existe.
- **Libro** — Pramod Sadalage y Martin Fowler, *NoSQL Distilled* (Addison-Wesley, 2012). Corto y
  todavía vigente para la taxonomía de familias y el concepto de agregado como unidad.
- [DynamoDB — Best practices for designing and using partition keys](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html):
  particiones calientes, cardinalidad y write sharding.
- [DynamoDB — NoSQL design for DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-general-nosql-design.html):
  la inversión "primero los patrones de acceso", explicada por AWS.
- [DynamoDB — Global secondary indexes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html):
  GSI contra LSI, proyecciones y su consistencia.
- [DynamoDB — Read consistency](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html):
  lectura eventual contra fuerte, y por qué los GSI quedan fuera.
- **Video** — AWS re:Invent, las charlas de Rick Houlihan sobre modelado avanzado en DynamoDB.
  Son la referencia del single-table design. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. Nombra las cuatro familias de NoSQL y para qué sirve cada una. 🟢
2. ¿Qué son la partition key y la sort key en DynamoDB? 🟢
3. ¿Qué diferencia hay entre `Query` y `Scan`? 🟢
4. ¿Qué es un GSI? 🟢
5. ¿Qué es el TTL en DynamoDB y para qué se usa? 🟢
6. ¿Qué cuatro razones justifican salir del modelo relacional? 🟡
7. ¿Por qué `Scan` con filtro es casi siempre un bug? 🟡
8. ¿Qué diferencias hay entre GSI y LSI? 🟡
9. ¿Qué consistencia tiene un GSI? 🟡
10. ¿Qué es single-table design? 🟡
11. ¿Qué son los DynamoDB Streams y para qué sirven? 🟡
12. ¿Qué familia de NoSQL resuelve algo que el relacional no puede? 🟡
13. ¿Por qué en DynamoDB se diseña a partir de los patrones de acceso? 🟡
14. ¿Qué claves de partición producen particiones calientes y por qué? 🟠
15. ¿Qué es write sharding y qué cuesta? 🟠
16. ¿Por qué cada GSI encarece las escrituras? 🟠
17. ¿Cuándo NO usarías single-table design? 🟠
18. ¿Cómo haces bloqueo optimista en DynamoDB? 🟠
19. ¿Cuándo eliges `on-demand` y cuándo `provisioned`? 🟠
20. ¿Por qué elegir la clave de partición es la decisión más irreversible? 🟠
21. Diseña la tabla de DynamoDB para: pedido por id, pedidos de un cliente por
    fecha descendente, y pedidos pendientes de hoy. 🔴
22. La factura de DynamoDB se triplicó en un mes sin subir el tráfico. Da tres
    hipótesis en orden y di cómo las confirmas. 🔴
23. Te piden migrar una tabla relacional de pedidos a DynamoDB "para que escale".
    ¿Qué preguntas y en qué casos dirías que no? 🔴

---

**Anterior:** [`02` — Transacciones y bloqueo](02-transacciones-y-bloqueo.md) ·
**Siguiente:** [`04` — Sharding y particionado](04-sharding-y-particionado.md) ·
**Relacionado:** [`01` — CAP y consistencia](01-cap-y-consistencia.md)
