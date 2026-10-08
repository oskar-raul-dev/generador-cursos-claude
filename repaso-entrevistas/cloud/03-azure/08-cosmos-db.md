# 08 — Cosmos DB

> **Objetivo:** modelar datos en Cosmos DB desde los patrones de acceso, elegir partition key,
> throughput y nivel de consistencia, y explicar qué pasa cuando algo de eso se elige mal.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md) (regiones y zonas) y
> [`07`](07-bases-relacionales-y-cache.md) (el contraste con una base relacional).
> **Se toca más con:** [`07`](07-bases-relacionales-y-cache.md), porque la primera pregunta es
> relacional o Cosmos, y el [`13`](13-mensajeria-y-eventos.md) (mensajería), porque el change feed y la escritura
> idempotente son la costura entre datos y eventos.
> **Se practica en:** [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) (cuenta con free tier, partition key, escritura idempotente y un `429`
> provocado). Ver [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [Qué es y qué no es](#1--qué-es-cosmos-db-y-qué-no-es) ·
[Modelo de recursos](#2--modelo-de-recursos) · [APIs](#3--las-apis-se-eligen-al-crear-la-cuenta) ·
[Partition key](#4--partition-key-la-decisión-que-no-se-deshace) ·
[Request Units](#5--request-units) · [Throughput](#6--provisionado-autoscale-o-serverless) ·
[Consistencia](#7--los-cinco-niveles-de-consistencia) · [Indexación y consultas](#8--indexación-y-consultas) ·
[Change feed](#9--change-feed) · [Multi-región](#10--distribución-global-y-escrituras-multi-región) ·
[Transacciones y 429](#11--transacciones-reintentos-y-el-sdk-de-java) · [Modelado](#12--modelar-desde-los-patrones-de-acceso) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Qué es Cosmos DB y qué no es

**Azure Cosmos DB** es una base de datos distribuida, administrada, con latencias de un solo dígito de
milisegundo al percentil 99 para lecturas puntuales y escrituras, distribución global con un clic y
cinco niveles de consistencia. Escala horizontalmente repartiendo los datos por **partition key**.

Lo que **no** es, y es la mitad de las preguntas de entrevista:

- **no es una base relacional con otro nombre**: no hay joins entre contenedores, las transacciones
  multi-documento solo existen dentro de una partición lógica, y el esquema es del documento;
- **no es "multi-modelo al consultar"**: la API se elige al crear la cuenta (§3);
- **no es barata por defecto**: cobra por throughput y almacenamiento, y un mal diseño de partición
  multiplica el throughput que necesitas.

La primera decisión es **relacional o Cosmos**, y la respuesta sale de los patrones de acceso:
consultas ad hoc, joins e integridad referencial apuntan a Azure SQL o PostgreSQL ([`07`](07-bases-relacionales-y-cache.md));
acceso por clave a escala, latencia predecible y distribución global apuntan a Cosmos DB.

---

## 2. 🧱 Modelo de recursos

```text
Cuenta             inv-lab-cosmos-472913   ← API, regiones, consistencia por defecto, free tier
└── Base de datos  inv                     ← opcionalmente, throughput compartido
    └── Contenedor events                  ← partition key, indexing policy, throughput propio
        └── Item   { "id": "...", "storeId": "store-042", ... }
```

- la **cuenta** define la API, las regiones, la consistencia por defecto y si usa el free tier; su
  nombre es único en todo Azure y forma el endpoint `https://<cuenta>.documents.azure.com`;
- el **contenedor** es la unidad de escalado: tiene **una** partition key y su indexing policy;
- un **item** se identifica por **`id` más su partition key**: dos items pueden compartir `id` si
  están en particiones distintas.

---

## 3. 🧱 Las APIs se eligen al crear la cuenta

Cosmos DB expone varias APIs: **NoSQL** (la nativa, consultas tipo SQL sobre JSON), **MongoDB**
(compatibilidad de protocolo), **Cassandra**, **Gremlin** (grafos) y **Table**.

> Nunca respondas: "Cosmos DB es multi-modelo, así que consulto los mismos datos por SQL o por
> MongoDB". Mejor: "la API se fija al crear la cuenta; cada API es un contrato distinto y no se
> cambia después".

Dos matices de 2026:

- **API for MongoDB** tiene dos variantes: la basada en RU (el motor de Cosmos DB con protocolo de
  MongoDB) y **vCore** (clústeres dedicados, más compatibles con MongoDB). Son productos distintos;
- **Azure Cosmos DB for PostgreSQL** está en camino de retiro y **no se recomienda para proyectos
  nuevos**; Microsoft dirige esas cargas a los *elastic clusters* de PostgreSQL Flexible Server.

Para una aplicación Java nueva, la respuesta por defecto es **API for NoSQL**: es la que recibe
primero las funcionalidades y la que usa el laboratorio.

---

## 4. 🧱 Partition key: la decisión que no se deshace

**El problema:** tu contenedor de eventos de inventario crece a millones de documentos y miles de
escrituras por segundo. Cosmos DB tiene que repartirlo en máquinas, y la única información que tiene
para hacerlo es la partition key que elegiste.

Los items con el mismo valor de partition key forman una **partición lógica**. Cosmos DB agrupa
particiones lógicas en **particiones físicas**, que son las que tienen máquinas detrás:

```text
Partición lógica  = todos los items con el mismo valor de partition key
                    máximo 20 GB; máximo 10.000 RU/s (hereda el límite de su física)
Partición física  = una o varias lógicas; máximo 50 GB y 10.000 RU/s
                    la administra Cosmos DB; tú no la controlas
El throughput     = se reparte a partes iguales entre las físicas
```

La última línea es la que convierte una mala partition key en un problema de dinero: si provisionas
18.000 RU/s y hay tres particiones físicas, **cada una tiene 6.000**. Si todas las escrituras van a
la misma partición lógica, esa partición se satura (**hot partition**) y responde `429` mientras las
otras dos están ociosas: estás pagando 18.000 y usando 6.000.

Una buena partition key:

- **tiene alta cardinalidad**: muchos valores posibles;
- **reparte por igual** almacenamiento y RU consumidas;
- **aparece en el filtro de las consultas frecuentes**, para que sean de una sola partición;
- **no cambia**: el valor de la partition key de un item es inmutable; "moverlo" es crear otro item y
  borrar el original, sin atomicidad entre particiones.

Y **la partition key del contenedor no se puede cambiar**: cambiarla es crear otro contenedor y
migrar los datos.

Los antipatrones que se preguntan:

- **campos de baja cardinalidad** (`status`, `country`, `type`): pocas particiones y calientes;
- **una clave de alta cardinalidad que no aparece en ninguna consulta** (un GUID aleatorio): reparte
  bien las escrituras, pero toda lectura que no sea por `id` es cross-partition;
- **`/id` para cargas mixtas**: perfecta para lecturas y escrituras puntuales, mala en cuanto filtras
  por otra propiedad.

Las salidas cuando ninguna propiedad sirve sola:

- **clave sintética**: concatenar propiedades (`storeId-2026-09`), que reparte más a costa de
  consultas más complejas;
- **hierarchical partition keys**: hasta **tres niveles** (`/tenantId/storeId/sku`), que evitan el
  techo de 20 GB por partición lógica y siguen permitiendo consultas eficientes por el primer nivel.

> 🧠 **Modelo mental.** En Cosmos DB no diseñas tablas: diseñas **cómo se reparte la carga**. La
> partition key es la respuesta a "¿qué valor aparece en casi todas mis operaciones y tiene miles de
> valores distintos?".

---

## 5. 🧱 Request Units

Cosmos DB no cobra por CPU ni por IOPS: cobra en **Request Units** (RU), una moneda que normaliza el
costo de cada operación.

- **1 RU = leer un item de ~1 KB por `id` y partition key** (una *point read*). Es la referencia de
  todo lo demás;
- escribir cuesta más que leer, y más cuanto más grande es el documento y más propiedades indexadas
  tiene;
- una consulta cuesta según su complejidad y el volumen que recorre; una consulta **cross-partition**
  añade unas 2 o 3 RU por cada partición física que tiene que visitar;
- **Strong y Bounded staleness cuestan el doble en lecturas**, porque leen de dos réplicas (§7);
- el mismo `readItem` sobre el mismo dato cuesta **siempre lo mismo**, y cada respuesta dice lo que
  costó en la cabecera `x-ms-request-charge`.

```text
Regla de costo:
point read (id + partition key)  <  consulta en una partición  <  consulta cross-partition
```

La consecuencia de diseño: **si puedes leer por `id` y partition key, no hagas una consulta**.

---

## 6. 🧱 Provisionado, autoscale o serverless

Tres formas de pagar el throughput:

| Modo | Cómo funciona | Cuándo |
|---|---|---|
| **Provisionado manual** | Reservas RU/s en múltiplos de 100 y pagas por hora | Tráfico estable y previsible |
| **Autoscale** | Fijas un máximo; escala al instante entre el 10 % y ese máximo, y pagas por el pico de cada hora | Tráfico variable con SLA |
| **Serverless** | Sin reserva; pagas las RU consumidas | Desarrollo o tráfico esporádico, en una sola región |

Y dos granularidades: throughput **por contenedor** (dedicado y predecible) o **por base de datos**
(compartido entre sus contenedores, con un máximo de 25 contenedores por base con throughput
compartido).

Dos hechos que se preguntan:

- las RU provisionadas se aplican **en cada región** de la cuenta: 1.000 RU/s en tres regiones son
  3.000 RU/s facturadas;
- superar el throughput no da error permanente: da **`429 Too Many Requests`** con el tiempo de
  espera en `x-ms-retry-after-ms`, y el SDK reintenta solo (§11).

> 💰 **Costo.** El **free tier** da **1.000 RU/s y 25 GB** gratis de por vida en **una cuenta por
> suscripción**, y solo si lo pides **al crearla**; no existe para serverless. El laboratorio lo usa
> con un contenedor de 400 RU/s, dentro de la cuota. Fuera del free tier, 100 RU/s manuales cuestan
> **$0.008/h** en `eastus2`.

---

## 7. 🧱 Los cinco niveles de consistencia

**El problema:** un usuario actualiza su dirección y recarga la página; la lectura va a otra réplica
que todavía no recibió la escritura y ve la dirección vieja. ¿Es un bug o es el contrato?

La mayoría de las bases distribuidas ofrecen "fuerte" o "eventual". Cosmos DB ofrece **cinco niveles**
bien definidos, que se fijan como defecto de la cuenta y se pueden relajar por petición:

| Nivel | Garantía | Lecturas | Uso típico |
|---|---|---|---|
| **Strong** | Linealizable: siempre la última escritura confirmada | 2 réplicas, doble RU | Saldos, inventario crítico; latencia de escritura alta con varias regiones |
| **Bounded staleness** | Retraso acotado a *K* versiones o *T* segundos | 2 réplicas, doble RU | Casi fuerte entre regiones con una sola región de escritura |
| **Session** (defecto) | Dentro de una sesión: lees tus propias escrituras y en orden | 1 réplica | La mayoría de las aplicaciones de usuario |
| **Consistent prefix** | Nunca ves escrituras fuera de orden; lo escrito en una transacción aparece junto | 1 réplica | Feeds, historiales |
| **Eventual** | Sin orden ni plazo: puedes leer algo más viejo que lo que leíste antes | 1 réplica | Contadores, likes |

Lo que separa una respuesta memorizada de una entendida:

- **Session no es "la sesión HTTP"**: es un **token de sesión** que el SDK recibe con cada escritura y
  envía en las lecturas. Si dos instancias de tu API comparten el usuario pero no el token, la segunda
  no tiene garantía de leer lo que escribió la primera. El token, además, es por partición;
- **Strong no es "la opción segura"**: con varias regiones, cada escritura espera a todas las
  regiones (la latencia de escritura es dos veces el RTT entre las regiones más lejanas más 10 ms), y
  **no se puede combinar con escrituras multi-región**;
- **dentro de una región todos los niveles escriben a una mayoría local** (tres de cuatro réplicas):
  la diferencia está en cómo se lee y en qué se replica entre regiones;
- la consistencia se puede **relajar** por petición desde el SDK, nunca endurecer más allá del
  defecto de la cuenta.

> Nunca respondas: "uso Strong para no tener problemas". Mejor: "uso Session por defecto porque da
> read-your-writes a cada usuario con latencia y costo de lectura de una sola réplica; Strong solo
> donde el negocio exige linealizabilidad, sabiendo que dobla el costo de lectura y que en
> multi-región sube la latencia de escritura".

---

## 8. 🧱 Indexación y consultas

Por defecto, Cosmos DB **indexa todas las propiedades** de cada documento. Es cómodo y rara vez lo
óptimo:

- **excluir rutas** que nunca se filtran (un campo `payload` grande) reduce el costo de cada escritura;
- **índices compuestos** son necesarios para `ORDER BY` por varias propiedades y abaratan filtros
  combinados;
- el modo de indexación es **consistente**: el índice se actualiza con la escritura, y las consultas
  ven lo escrito.

La regla de consultas, que ya apareció en §5: incluir la partition key en el filtro convierte una
consulta cross-partition en una de una sola partición.

---

## 9. 🧱 Change feed

**El problema:** cada vez que se escribe un evento en `events`, hay que recalcular el stock en otro
contenedor y avisar a otro servicio, sin que el escritor tenga que conocer a los consumidores.

El **change feed** es un registro persistente y ordenado de los cambios de un contenedor, activado por
defecto en todas las cuentas. Se consume con el **change feed processor** del SDK, con un trigger de
Azure Functions o con el modelo pull.

- **Latest version** (el modo por defecto): da la última versión de cada item insertado o actualizado.
  **No incluye borrados**, y si un item cambia varias veces entre dos lecturas, solo ves la última
  versión. El truco habitual para enterarse de un borrado es un borrado lógico (un campo `deleted`)
  con TTL;
- **All versions and deletes**: da cada cambio, intermedios y borrados incluidos, pero exige
  **copias de seguridad continuas** en la cuenta y solo cubre su período de retención;
- **el orden solo está garantizado por partition key**, nunca entre particiones;
- el change feed processor da semántica **at-least-once** con checkpoints en un contenedor de
  *leases*: el consumidor tiene que ser **idempotente**.

El change feed es la pieza de muchos patrones: materializar vistas (el `stock` del laboratorio),
replicar a un buscador o publicar eventos, que es la base del patrón outbox con Cosmos DB del
[`13`](13-mensajeria-y-eventos.md).

---

## 10. 🧱 Distribución global y escrituras multi-región

Añadir regiones a una cuenta es una operación de configuración: los datos se replican y la cuenta
sigue funcionando. Dos modelos:

- **una región de escritura** y varias de lectura: sencillo, sin conflictos; si cae la región de
  escritura, se promueve otra (con *service-managed failover* si lo habilitas);
- **escrituras multi-región**: todas las regiones aceptan escrituras, con latencia local de escritura
  en cada una. El precio es la posibilidad de **conflictos**: dos regiones actualizan el mismo item a
  la vez. Se resuelven con **last writer wins** (por defecto, sobre `_ts` o una propiedad numérica que
  elijas) o con un procedimiento propio.

Recuerda que las RU se facturan en cada región (§6), y que Strong no admite escrituras multi-región
(§7). Sin varias regiones, el RPO ante la caída de la región es de hasta 240 minutos; con varias y
consistencia Session o más débil, menos de 15 minutos.

---

## 11. 🧱 Transacciones, reintentos y el SDK de Java

**Transacciones**: existen **dentro de una partición lógica**, con aislamiento de snapshot, mediante
**transactional batch** del SDK o stored procedures en JavaScript. No hay transacciones entre
particiones ni entre contenedores. Es otra razón para que la partition key agrupe lo que tiene que
cambiar junto.

**Concurrencia optimista**: cada item tiene un `_etag`; una escritura condicionada con `If-Match`
falla con `412 Precondition Failed` si otro lo modificó antes. Es la forma de evitar la actualización
perdida sin bloqueos.

**El cliente de Java**, con identidad en lugar de claves:

```java
// un único CosmosClient por aplicación: mantiene conexiones y cachés de rutas de partición
CosmosClient client = new CosmosClientBuilder()
        .endpoint("https://inv-lab-cosmos-472913.documents.azure.com:443/")
        .credential(new DefaultAzureCredentialBuilder().build())
        .consistencyLevel(ConsistencyLevel.SESSION)
        .buildClient();

CosmosContainer events = client.getDatabase("inv").getContainer("events");

// point read: id + partition key, la operación más barata que existe
CosmosItemResponse<InventoryEvent> response =
        events.readItem("evt-0001", new PartitionKey("store-042"), InventoryEvent.class);
double charge = response.getRequestCharge();  // RU consumidas, leídas de x-ms-request-charge
```

- `CosmosClientBuilder` crea el cliente **una vez**: es thread-safe y costoso de crear. Crear uno por
  petición agota conexiones y es el error de rendimiento más citado de la documentación.
- `.credential(new DefaultAzureCredentialBuilder().build())` autentica con Entra ID: en local, con tu
  sesión de `az`; en Container Apps, con la managed identity ([`09`](09-identidad-entra-id-y-managed-identities.md)). La identidad necesita un
  **rol de datos propio de Cosmos DB for NoSQL**, que se asigna con `az cosmosdb sql role assignment
  create`, no con un `az role assignment` corriente: el plano de datos de Cosmos DB tiene su propio
  RBAC. Con eso asignado, se pueden deshabilitar las claves de la cuenta.
- `.consistencyLevel(ConsistencyLevel.SESSION)` fija la consistencia del cliente, que solo puede ser
  igual o más débil que la de la cuenta.
- `readItem(id, new PartitionKey(...), clase)` es una point read: sin la partition key no es posible,
  y la alternativa —una consulta por `id`— es cross-partition y mucho más cara.
- `getRequestCharge()` devuelve las RU de la operación. Registrarlo en los logs es la forma de
  descubrir qué operación se come el throughput.

Ante un `429`, el SDK **reintenta solo**, respetando el tiempo de espera que indica el servicio,
hasta un número configurable de intentos. Si los agota, la excepción llega a tu código: es la señal de
que el throughput o la partition key no dan para la carga. [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) provoca uno a propósito.

---

## 12. 🧱 Modelar desde los patrones de acceso

En una base relacional se modela la entidad y luego se escriben las consultas. En Cosmos DB se hace
al revés: **se listan las operaciones y se modela para ellas**.

```text
1. Lista las operaciones: "leer el stock de un SKU en una tienda", "listar los eventos
   de una tienda en un día", "registrar un movimiento".
2. Para cada una, ¿qué valor tiene siempre a mano? → candidato a partition key.
3. ¿Qué se lee junto? → embébelo en el mismo documento.
4. ¿Qué crece sin límite o se lee por separado? → documento aparte, referenciado.
5. ¿Qué tiene que cambiar atómicamente? → misma partición lógica.
```

- **embeber** (las líneas de un pedido dentro del pedido) da una sola lectura barata y atomicidad,
  a costa del tamaño del documento (máximo 2 MB por item);
- **referenciar** (el cliente en otro documento) evita duplicar lo que cambia a menudo, a costa de
  dos lecturas;
- **desnormalizar** es normal: duplicar el nombre del producto en cada evento está bien si el nombre
  casi nunca cambia, y el change feed puede propagar el cambio cuando ocurra.

**Table Storage** ([`06`](06-almacenamiento-storage-accounts.md)) es el contraste útil: clave-valor muy barato con `PartitionKey` y
`RowKey`, sin índices secundarios, sin distribución global ni niveles de consistencia. Cuando basta
con eso, Cosmos DB es demasiado.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Cosmos DB es multi-modelo, elijo la API al consultar" | La API se fija al crear la cuenta |
| "Strong es la opción segura" | Dobla el costo de lectura, sube la latencia de escritura en multi-región y no admite multi-escritura |
| "Session es consistencia por sesión HTTP" | Es un token de sesión del SDK, por partición |
| "La partition key se elige por cardinalidad" | Además tiene que repartir la carga y aparecer en las consultas frecuentes |
| "Si hay `429`, sube las RU" | Primero mira si es una hot partition: subir RU la reparte igual entre físicas |
| "Puedo cambiar la partition key más adelante" | Solo creando otro contenedor y migrando |
| "El change feed trae los borrados" | Solo en all versions and deletes, que exige backups continuos |
| "Cosmos DB tiene transacciones como SQL" | Solo dentro de una partición lógica |

---

## 🧠 Preguntas rápidas

1. ¿Qué identifica unívocamente a un item en un contenedor de Cosmos DB?
2. ¿Puedes crear una cuenta con la API for NoSQL y consultar después sus datos con la API for MongoDB?
3. ¿Qué límites tienen una partición lógica y una partición física, y cuál de las dos controlas tú?
4. Provisionaste 18.000 RU/s en un contenedor con tres particiones físicas y recibes `429` aunque el consumo total está muy por debajo. ¿Qué está pasando?
5. ¿Qué tres propiedades debe tener una buena partition key?
6. ¿Qué harías si ninguna propiedad por sí sola sirve como partition key, o si una partición lógica va a superar los 20 GB?
7. ¿Qué es exactamente 1 RU y qué operación es la más barata?
8. ¿Cuándo elegirías autoscale en lugar de throughput provisionado manual, y cuándo serverless?
9. ¿Qué garantiza Session consistency y qué pasa si dos instancias de tu API no comparten el token de sesión?
10. ¿Por qué Strong consistency cuesta el doble en lecturas y por qué no se puede usar con escrituras multi-región?
11. ¿Qué no te da el change feed en modo latest version y qué alternativa hay?
12. ¿Qué garantía de orden ofrece el change feed?
13. ¿Qué alcance tienen las transacciones en Cosmos DB y cómo evitas una actualización perdida sin bloqueos?
14. ¿Por qué debe existir un único `CosmosClient` por aplicación y qué rol necesita su managed identity para leer datos?
15. ¿Qué harías antes de subir las RU de un contenedor que responde `429`?

---

## 📚 Referencias oficiales

- ¿Qué es Azure Cosmos DB?: https://learn.microsoft.com/en-us/azure/cosmos-db/overview
- Modelo de recursos: https://learn.microsoft.com/en-us/azure/cosmos-db/resource-model
- Preguntas frecuentes de Cosmos DB (una cuenta por API): https://learn.microsoft.com/en-us/azure/cosmos-db/faq
- Particionado y escalado horizontal: https://learn.microsoft.com/en-us/azure/cosmos-db/partitioning
- Hierarchical partition keys: https://learn.microsoft.com/en-us/azure/cosmos-db/hierarchical-partition-keys
- Request Units: https://learn.microsoft.com/en-us/azure/cosmos-db/request-units
- Throughput provisionado: https://learn.microsoft.com/en-us/azure/cosmos-db/set-throughput
- Autoscale: https://learn.microsoft.com/en-us/azure/cosmos-db/provision-throughput-autoscale
- Serverless: https://learn.microsoft.com/en-us/azure/cosmos-db/serverless
- Free tier: https://learn.microsoft.com/en-us/azure/cosmos-db/free-tier
- Niveles de consistencia: https://learn.microsoft.com/en-us/azure/cosmos-db/consistency-levels
- Indexing policies: https://learn.microsoft.com/en-us/azure/cosmos-db/index-policy
- Change feed: https://learn.microsoft.com/en-us/azure/cosmos-db/change-feed
- Modos del change feed: https://learn.microsoft.com/en-us/azure/cosmos-db/change-feed-modes
- Change feed processor: https://learn.microsoft.com/en-us/azure/cosmos-db/change-feed-processor
- Escrituras multi-región y conflictos: https://learn.microsoft.com/en-us/azure/cosmos-db/multi-region-writes
- Tipos de resolución de conflictos: https://learn.microsoft.com/en-us/azure/cosmos-db/conflict-resolution-policies
- Transacciones y concurrencia optimista: https://learn.microsoft.com/en-us/azure/cosmos-db/database-transactions-optimistic-concurrency
- Transactional batch: https://learn.microsoft.com/en-us/azure/cosmos-db/transactional-batch
- Consejos de rendimiento del SDK de Java v4: https://learn.microsoft.com/en-us/azure/cosmos-db/performance-tips-java-sdk-v4
- RBAC del plano de datos de Cosmos DB for NoSQL: https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-connect-role-based-access-control
- Modelado de datos en Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/modeling-data
- Cuotas y límites de Cosmos DB: https://learn.microsoft.com/en-us/azure/cosmos-db/concepts-limits
- Cosmos DB for PostgreSQL (estado y migración): https://learn.microsoft.com/en-us/azure/cosmos-db/postgresql/introduction
- Precios de Cosmos DB (provisionado): https://azure.microsoft.com/en-us/pricing/details/cosmos-db/autoscale-provisioned/
