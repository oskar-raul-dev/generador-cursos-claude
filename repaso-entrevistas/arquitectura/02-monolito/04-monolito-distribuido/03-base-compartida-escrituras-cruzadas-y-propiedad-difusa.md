# 03 — Base compartida, escrituras cruzadas y propiedad difusa

Aprenderás a recuperar la propiedad de los datos en un sistema distribuido que comparte base, sin
una migración física de golpe: cómo averiguar quién lee y escribe cada tabla, cómo dar a cada
conjunto un dueño con autoridad real y cuándo separar el almacenamiento compra algo.

## 1. 🎯 Síntoma y decisión

Los componentes `orders` y `payments` comparten esquema, y cada uno escribe en las tablas del otro.
Al cancelar un pedido, `orders` ejecuta un `UPDATE` directo sobre `payments.authorizations` para
anular la autorización; al autorizar, `payments` cambia el estado en `orders.orders`. Un día,
`payments` renombra en una migración el estado `VOIDED` a `CANCELLED`. El SQL de `orders` sigue
escribiendo `VOIDED`, el job de conciliación ignora esas filas y 212 autorizaciones quedan sin
anular: clientes cobrados por pedidos cancelados. Además, cada DDL necesita una reunión de tres
equipos, y alguien propone «database per service» para el próximo sprint.

La base compartida no es el problema por sí misma; lo es que funcione como canal de integración sin
dueño. La decisión de este capítulo es cómo devolver la autoridad a un propietario antes de decidir
si mover el almacenamiento.

## 2. 🧠 Modelo mental

El dueño de un conjunto de datos es quien lo escribe, quien decide su esquema y quien responde por
sus invariantes. Es el mismo concepto que la
[propiedad de datos dentro de un monolito](../02-modularidad-y-limites-internos/04-propiedad-de-datos-en-una-base-compartida.md),
aplicado ahora entre procesos que despliegan por separado y ya no comparten transacción ni release.

```text
hoy                                          objetivo, por pasos
orders ──SQL──► payments.authorizations     orders ──VoidPayment──► payments
payments ──SQL──► orders.orders             payments ──PaymentAuthorized──► orders
ambos cambian el esquema del otro           cada tabla: un escritor, un dueño del esquema
                                            la base física puede seguir siendo la misma
```

Separar la base sin resolver la autoridad copia el acoplamiento en dos bases: los dos equipos siguen
necesitando los datos del otro, y lo que era un `UPDATE` pasa a ser un dual write. El orden es
autoridad primero, almacenamiento después, y solo si compra algo.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | `orders` escribe `payments.authorizations` y `payments` escribe `orders.orders`; 212 autorizaciones sin anular tras renombrar un estado; cada DDL necesita tres equipos; el log de la base muestra seis credenciales distintas escribiendo las mismas tablas |
| Inferencia | nadie tiene autoridad sobre el significado de los estados, y el esquema funciona como un contrato implícito sin versión |
| Diagnóstico | propiedad difusa: la base compartida es el canal de integración, no solo el almacenamiento |
| Recomendación | matriz de lectores y escritores con datos reales, un dueño por conjunto de tablas, escrituras ajenas migradas a comandos, permisos revocados y separación física solo después, si compra autonomía |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si las autorizaciones sin
anular vinieran de un fallo del propio código de `payments`, y no de la escritura ajena de `orders`,
el problema sería un defecto local. El historial de la columna —quién escribió `VOIDED` después de la
migración— lo distingue.

## 4. 🛠️ Ownership antes que mudanza

Primero se construye una matriz de tablas por lector y escritor usando consultas, credenciales y
trazas, no solo entrevistas. Cada conjunto obtiene un propietario capaz de cambiar esquema, validar
invariantes y responder incidentes. Se prohíben nuevas escrituras ajenas y se migran las existentes
una por una hacia un comando del propietario.

```text
antes: orders ──SQL──► payments.authorizations

paso 1: permisos observados y owner = payments
paso 2: orders ──AuthorizePayment──► payments
paso 3: lectura frecuente ◄── proyección con versión y frescura
paso 4: separar almacenamiento solo si compra autonomía
```

Un join de reporting puede permanecer sobre una réplica o vista gobernada; no toda lectura necesita
una llamada síncrona. Para una pantalla crítica, una proyección local paga duplicación y retraso a
cambio de disponibilidad y consulta propia. Su contrato declara versión, frescura y reconciliación.

Los permisos de base hacen verificable la autoridad, pero no descubren el dueño. CDC puede alimentar
una proyección, pero tampoco vuelve correcto un evento ambiguo. La separación física llega al final:
si los mismos equipos siguen aprobando DDL y haciendo dual writes sin estrategia, dos bases conservan
el acoplamiento. Un dual write temporal exige fuente de verdad, detección de divergencia y salida.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | ORM por módulo más permisos de DB | repositorios separados no impiden SQL directo | entidades compartidas |
| Node/TypeScript | clientes/roles por propietario | tipos generados no controlan permisos | cliente global exportado |
| Go | interfaces y usuarios de DB acotados | paquetes no revocan grants | pasar `*sql.DB` a todo |
| Python | sesiones y roles por módulo | un schema ORM no prueba ownership | modelo común mutable |

Las cuatro trampas tienen la misma forma: un mecanismo que parece separar módulos y deja una puerta
abierta a la base. Entidades compartidas, un cliente global exportado, un `*sql.DB` pasado a todo o
un modelo ORM común permiten que cualquier componente escriba cualquier tabla. Los permisos de base
cierran esa puerta desde el otro lado, y por eso aparecen en las cuatro filas: el lenguaje organiza
el código, pero solo la base impone quién escribe.

## 6. ⚖️ Decisión y coste

Inventaria accesos, asigna propietario y migra escrituras ajenas hacia su contrato antes de revocar permisos. Conservas invariantes bajo una autoridad a cambio de compatibilidad temporal y adaptación de consumidores. Mantén joins de lectura gobernados cuando su coste sea menor que el de una API o proyección. Separa almacenamiento solo si añade autonomía demostrable; una base compartida con límites efectivos puede ser el estado final.

## ⚠️ Errores frecuentes

- «Database per service arregla el ownership». Separar la base sin dueño copia el acoplamiento en dos bases y lo convierte en dual writes.
- «Todo join distribuido debe ser una API». Un join de lectura sobre una vista gobernada puede ser más barato y más fiable que una llamada.
- «Los permisos de base descubren al dueño». Hacen cumplir una decisión; decidir quién es dueño es trabajo de negocio y de equipos.
- «Un dual write temporal es inocuo». Sin fuente de verdad, detección de divergencia y fecha de salida, se vuelve permanente y diverge.
- «CDC resuelve la integración». Publica cambios de filas; si el significado de la fila es ambiguo, publica la ambigüedad.

## 7. ✅ Veredicto

Recupera primero la autoridad y después, si compra algo, el almacenamiento. Inventaria quién lee y
escribe con datos reales, asigna un dueño por conjunto de tablas, convierte las escrituras ajenas en
comandos y revoca los permisos. Resuelve las lecturas según su necesidad: vista gobernada, API o
proyección con frescura declarada. Una base compartida con dueños efectivos puede ser el estado
final.

## 📚 Referencias

- [AWS: Database-per-service, autoridad y costes de separar datos](https://docs.aws.amazon.com/prescriptive-guidance/latest/modernization-data-persistence/database-per-service.html)
- [PostgreSQL Privileges](https://www.postgresql.org/docs/current/ddl-priv.html)
- [Martin Fowler: CQRS](https://martinfowler.com/bliki/CQRS.html)

## 🧠 Preguntas

1. 🟢 ¿Qué tres cosas definen al dueño de un conjunto de datos?
2. 🟢 ¿Qué es una escritura cruzada y por qué es peor que una lectura cruzada?
3. 🟢 ¿Qué es una matriz de lectores y escritores y de dónde sale?
4. 🟢 ¿Qué es una proyección de lectura y qué contrato declara?
5. 🟢 ¿Qué es un dual write y qué riesgo introduce?
6. 🟢 ¿Qué aporta CDC y qué no garantiza?
7. 🟡 ¿Por qué mover tablas a otra base sin acordar propietario es una simplificación peligrosa?
8. 🟡 ¿Cuándo mantendrías un join de lectura gobernado en lugar de una API o una proyección?
9. 🟡 ¿Por qué el renombrado de un estado por `payments` produjo 212 autorizaciones sin anular?
10. 🟡 ¿Por qué el esquema compartido es un contrato implícito, y qué le falta respecto a uno explícito?
11. 🟡 ¿En qué orden migrarías las escrituras ajenas y cuándo revocarías permisos?
12. 🟡 ¿Qué lecturas de `orders` sobre `payments` resolverías con API, cuáles con proyección y cuáles con vista?
13. 🟡 ¿Qué diferencia hay entre la propiedad de datos dentro de un monolito modular y entre servicios que comparten base?
14. 🟡 ¿Qué señales te dirían que separar el almacenamiento ya compra autonomía?
15. 🟡 ¿Qué pasa con las claves foráneas entre tablas de dueños distintos?
16. 🟡 ¿Cómo detectarías divergencia durante un dual write temporal?
17. 🟡 ¿Cómo complementan los permisos SQL a repositorios Java o interfaces Go sin sustituir ownership?
18. 🟠 ¿Por qué clientes globales en Node/TypeScript y modelos ORM compartidos en Python debilitan el mismo límite?
19. 🟠 Descubres las 212 autorizaciones sin anular un viernes por la tarde. ¿Qué haces primero y qué después?
20. 🟠 Un equipo propone copiar las tablas a dos bases el próximo sprint. ¿Qué preguntas harías antes de aceptar?
21. 🟠 `orders` y `payments` discrepan sobre quién es dueño del estado de pago del pedido. ¿Cómo lo resolverías?
22. 🟠 Quieres revocar a `orders` la escritura en `payments.authorizations`. ¿Qué pasos reversibles darías?
23. 🟠 Un reporte financiero hace joins entre tablas de cuatro componentes. ¿Lo conviertes en APIs, en proyección o lo dejas?
24. 🟠 ¿Qué criterio te diría que la base compartida puede ser el estado final?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [02 — Cadenas síncronas y acoplamiento temporal](02-cadenas-sincronas-y-acoplamiento-temporal.md).

**Siguiente:** [04 — Contratos frágiles y despliegues coordinados](04-contratos-fragiles-y-despliegues-coordinados.md).
