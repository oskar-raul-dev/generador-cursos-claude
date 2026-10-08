# 04 — Contratos frágiles y despliegues coordinados

Aprenderás a cambiar un contrato entre componentes sin exigir que `orders`, `payments` y
`notifications` se actualicen el mismo día: qué combinaciones de versiones tienen que funcionar, cómo
se secuencia un cambio incompatible y por qué versionar la URL no sustituye esa disciplina.

## 1. 🎯 Síntoma y decisión

`payments` quiere renombrar `authorizationId` a `reference` en su evento `PaymentAuthorized` y en la
respuesta de consulta de pagos. Tres consumidores leen ese campo —`orders`, `notifications` y el
informe financiero—, así que el cambio se agenda para el release conjunto del viernes, con los cuatro
equipos de guardia. No es la primera vez: hace un mes, `payments` añadió el estado
`PARTIALLY_CAPTURED`; el consumidor de `orders` rechazaba valores desconocidos y, al reprocesar una
semana de mensajes retenidos, 300 pedidos quedaron sin confirmar. La propuesta de hoy es publicar una
`/v2` y «que cada uno migre cuando pueda».

El contrato filtra cada cambio del proveedor a sus consumidores y convierte la liberación en un acto
coordinado. La decisión de este capítulo es cómo evolucionar el contrato para que cada componente
salga cuando le toca, y qué evidencia demuestra que puede hacerlo.

## 2. 🧠 Modelo mental

La compatibilidad siempre se enuncia con dos roles, lector y escritor. **Hacia atrás**: un lector
nuevo entiende datos escritos por la versión vieja. **Hacia adelante**: un lector viejo entiende datos
escritos por la versión nueva. En una petición, el proveedor lee; en una respuesta o un evento,
escribe. Y en un sistema distribuido conviven versiones siempre: durante cada despliegue, y durante
todo el tiempo que se retengan mensajes.

```text
                        escritor viejo            escritor nuevo
lector viejo            funciona hoy              ¿tolera campos y valores nuevos?  (adelante)
lector nuevo            ¿tolera lo que falta?     objetivo
                        (atrás, y replay)
cambio desacoplado: las cuatro casillas funcionan durante toda la ventana de convivencia
```

Un campo añadido es compatible solo si el lector viejo lo ignora; un enum nuevo, solo si el lector
sabe qué hacer con un valor desconocido. Que el JSON se deserialice no prueba que importe, moneda o
estado conserven su significado. La independencia de despliegue no es una propiedad del formato: es
una propiedad del contrato **y** de cómo lo leen sus consumidores.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | el renombrado exige que tres consumidores salgan en el mismo release; el enum nuevo rompió a `orders` al reprocesar mensajes retenidos; la CI de `payments` prueba solo contra las ramas actuales de los consumidores; los tres consumidores importan la misma librería con las clases de los eventos |
| Inferencia | los lectores no toleran cambios aditivos, la retención de mensajes no forma parte del contrato y la librería común obliga a actualizar a la vez |
| Diagnóstico | contrato frágil en la moneda de despliegue: cada cambio del proveedor es un cambio coordinado |
| Recomendación | lectores tolerantes, cambios aditivos con ventana de convivencia fechada, pruebas de consumidor contra las versiones desplegadas y retirada gobernada del campo viejo |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si el release conjunto fuera
una política voluntaria —los componentes pueden salir por separado y lo prueban de vez en cuando—, el
problema sería de proceso, no de contrato. Y si solo uno de los tres consumidores rompe ante cambios
aditivos, la corrección es de ese lector, no del proveedor. Solo junto con historial de cambios,
acceso a datos y dependencias runtime, un contrato frágil sostiene el
[diagnóstico de monolito distribuido](01-anatomia-y-evidencia-del-monolito-distribuido.md).

## 4. 🛠️ Evolucionar sin lockstep

El renombrado se convierte en una secuencia de cambios compatibles, la versión del contrato de
[expand-contract](../03-datos-ejecucion-y-operacion/05-despliegues-migraciones-de-esquema-y-rollback.md):

```text
1. payments publica reference además de authorizationId      (expandir; ambos con el mismo valor)
2. la CI de payments ejecuta las expectativas de los consumidores desplegados
3. cada consumidor lee reference, con authorizationId de respaldo, y sale cuando quiera
4. telemetría: qué versión de cada consumidor sigue leyendo authorizationId
5. al cerrar la ventana de soporte y sin lectores, se retira authorizationId   (contraer)
```

Contrato ilustrativo de `PaymentAuthorized` durante la convivencia, sin datos sensibles:

```json
{"eventId":"ev-17","type":"PaymentAuthorized","version":2,"orderId":"p-7","authorizationId":"a-9","reference":"a-9","amountMinor":12000,"currency":"COP"}
```

- `authorizationId` y `reference` llevan el mismo valor: el consumidor que encuentre los dos distintos
  lo trata como error de contrato, no elige uno en silencio.
- `version` identifica la forma del evento para quien reprocesa mensajes antiguos; no obliga a nadie a
  cambiar de lector.
- `amountMinor` y `currency` fijan la unidad del importe: la compatibilidad semántica también se
  prueba, no solo la forma.

**Lectores tolerantes.** El consumidor ignora campos que no conoce y trata un valor de enum
desconocido con una política explícita —dejar el pedido en revisión, no rechazar el mensaje—. Es lo
que habría evitado los 300 pedidos atascados: un lector estricto convierte cada evolución aditiva del
proveedor en un cambio incompatible.

**Pruebas de consumidor.** Cada consumidor publica las expectativas mínimas que usa del contrato y el
proveedor las ejecuta en su CI. Prueban compatibilidad del intercambio, no disponibilidad ni
rendimiento. La CI tiene que ejecutarlas contra las versiones **desplegadas** de cada consumidor, no
solo contra sus ramas actuales: la versión que está en producción es la que se rompe.

**Retención y replay.** Un evento retenido una semana exige compatibilidad hacia atrás durante una
semana, aunque el despliegue durara diez minutos. La ventana de convivencia se calcula con el mayor de
los dos plazos.

**Qué no resuelve una `/v2`.** Versionar la URL da un nombre a dos contratos; no dice cuándo se retira
el viejo, quién lo sigue usando ni qué pasa con los eventos, que no tienen URL. Sin retirada
gobernada, las versiones se acumulan y cada una es una rama más que mantener.

**Flags y librerías.** Una feature flag separa desplegar de activar: primero sale el soporte
compatible, después se activa por cohorte. Apagarla no borra los eventos nuevos ya persistidos. Una
librería cliente compartida puede ayudar con el transporte; una que contiene las clases del dominio y
exige actualizar a todos devuelve el lockstep por el build.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | DTO de frontera y fixtures de serialización en CI; deserializador configurado para ignorar campos desconocidos | la semántica del contrato | exportar entidades persistentes como contrato |
| Node/TypeScript | validación del payload en runtime y fixtures | los tipos compilados no validan lo que llega por la red | confiar en un cast al tipo del contrato |
| Go | tipos de frontera y pruebas con payloads anteriores | distinguir un valor ausente de un cero | confundir `0` o `""` con «no enviado» |
| Python | validación explícita y casos de contrato | las anotaciones no validan en runtime | aceptar un `dict` sin verificar |

Las cuatro trampas tienen la misma raíz: suponer que el tipo del lenguaje es el contrato. Un DTO,
una interfaz de TypeScript, un `struct` de Go o una anotación de Python describen lo que el código
espera, pero lo que llega por la red lo decide el escritor, y la política ante campos desconocidos la
decide el deserializador configurado en cada ejecutable. Por eso las fixtures de versiones anteriores
se ejecutan en cada plataforma, aunque difiera cómo compila.

## 6. ⚖️ Decisión y coste

Conserva el servicio a los consumidores vigentes con una ventana de compatibilidad con fecha y dueño.
Pagas campos duplicados, ramas temporales, pruebas de consumidor y telemetría por versión; compras que
cada componente salga cuando le toca. Mide el porcentaje de releases que **requieren** otro release,
la espera por coordinación y los fallos por versión. Si los componentes pertenecen a un único
producto y necesitan siempre el mismo cambio, un despliegue común puede ser más barato que simular
autonomía. Detén la retirada ante contradicciones monetarias o consumidores sin inventario, y no
retires un campo hasta confirmar cero uso durante el horizonte acordado.

## ⚠️ Errores frecuentes

- «Añadir un campo nunca rompe a nadie». Rompe a los lectores estrictos que rechazan campos
  desconocidos, y un enum nuevo rompe a quien no tiene política para valores que no conoce.
- «Con una `/v2` cada consumidor migra cuando puede». Sin fecha de retirada ni telemetría de uso, las
  versiones se acumulan, y los eventos no tienen URL que versionar.
- «Si la CI del proveedor está verde, los consumidores están a salvo». Solo si ejecuta las
  expectativas de las versiones desplegadas, no las de las ramas actuales.
- «Apagar la flag revierte el cambio». Los eventos ya emitidos con la forma nueva siguen en el broker y
  en los replays.
- «El release train es la causa». Puede ser una política voluntaria; la causa es el contrato que no
  permite salir por separado, y se comprueba intentándolo.

## 7. ✅ Veredicto

Un contrato es estable cuando admite evolución comprobada y una retirada gobernada, no cuando no
cambia. Haz los cambios aditivos, lectores tolerantes y pruebas de consumidor contra lo desplegado;
calcula la ventana de convivencia con el despliegue y con la retención de mensajes; y retira lo viejo
cuando la telemetría lo permita. La métrica útil es cambio entregado sin coordinación obligatoria, no
cantidad de versiones publicadas.

## 📚 Referencias

- [Consumer-Driven Contracts: A Service Evolution Pattern, Ian Robinson](https://martinfowler.com/articles/consumerDrivenContracts.html)
- [Parallel Change, Martin Fowler](https://martinfowler.com/bliki/ParallelChange.html)
- [Expand and Contract, Tim Wellhausen](https://www.tim-wellhausen.de/papers/ExpandAndContract/ExpandAndContract.html)

## 🧠 Preguntas

1. 🟢 ¿Qué significa liberar en *lockstep* y en qué moneda se paga?
2. 🟢 ¿Qué diferencia hay entre compatibilidad hacia atrás y hacia adelante, nombrando lector y escritor?
3. 🟢 ¿Quién es el lector y quién el escritor en una respuesta de `payments` y en un evento `PaymentAuthorized`?
4. 🟢 ¿Qué es un lector tolerante?
5. 🟢 ¿Qué demuestra una prueba de consumidor y qué no demuestra?
6. 🟡 ¿Por qué añadir un campo o un valor de enum puede romper a un consumidor?
7. 🟡 ¿Cómo migrarías `authorizationId` a `reference`?
8. 🟡 ¿Por qué `orders` dejó 300 pedidos sin confirmar al reprocesar mensajes, y qué política lo habría evitado?
9. 🟡 ¿Por qué probar solo contra las ramas actuales de los consumidores resulta insuficiente?
10. 🟡 ¿Cómo afecta la retención de mensajes a la ventana de convivencia?
11. 🟡 ¿Qué resuelve y qué no resuelve publicar una `/v2`?
12. 🟡 ¿Qué coste tiene una librería compartida con las clases de los eventos?
13. 🟡 ¿Qué métrica distingue autonomía de despliegue de simple frecuencia de releases?
14. 🟡 ¿Cuándo aceptarías un release train como decisión razonable?
15. 🟡 ¿Cómo probarías la compatibilidad semántica del importe, además de la forma?
16. 🟡 ¿Qué diferencia hay entre una feature flag y una versión del contrato?
17. 🟡 ¿Qué comparten un DTO de Java y una interfaz de TypeScript como frontera remota, y en qué difieren?
18. 🟠 ¿Qué riesgo comparten los valores cero de Go y los diccionarios sin validar de Python al leer un contrato?
19. 🟠 `payments` ya emitió eventos con la forma nueva y aparece un fallo. ¿Puedes revertir el proveedor?
20. 🟠 Una prueba contractual verde, ¿te permite retirar la autenticación anterior de una API?
21. 🟠 La telemetría muestra que un consumidor sin dueño conocido sigue leyendo `authorizationId`. ¿Qué haces?
22. 🟠 Apagaste la flag del cambio y siguen apareciendo fallos en `orders`. ¿Qué pasa y qué haces?
23. 🟠 ¿Aceptarías mantener dos contratos indefinidamente?
24. 🟠 ¿Qué evidencia te haría detener la retirada de `authorizationId`?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [03 — Base compartida, escrituras cruzadas y propiedad difusa](03-base-compartida-escrituras-cruzadas-y-propiedad-difusa.md).

**Siguiente:** [05 — Fallos parciales, retries y falsas transacciones](05-fallos-parciales-retries-y-falsas-transacciones.md).
