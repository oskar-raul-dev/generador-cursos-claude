# 07 — Cómo se llega: granularidad, entidades y plataforma compartida

Aprenderás a reconocer las decisiones de corte y de plataforma que **fabrican** un monolito
distribuido, para no repetirlas al recortar. El diagnóstico del estado es de
[anatomía y evidencia](01-anatomia-y-evidencia-del-monolito-distribuido.md); este capítulo es dueño
de las causas.

## 1. 🎯 Problema y evidencia

La división de hace dos años se hizo en un trimestre y con buenas intenciones:

- Un servicio por entidad: `order-service`, `customer-service`, `product-service`, `price-service` y
  `stock-service`, cada uno un CRUD sobre su tabla. Las reglas de negocio quedaron en quien llama:
  `order-service` orquesta cinco llamadas para crear un pedido, y la pasarela calcula descuentos.
- Una librería `commons` con `Order`, `Customer`, `Money` y los validadores, que todos importan.
- Un único entorno de integración con una suite end-to-end de noventa minutos: nadie libera si la
  suite está roja, aunque el fallo sea de otro servicio.
- Los equipos siguieron organizados por capa técnica: frontend, backend y base de datos.

Dos años después, el sistema cumple el diagnóstico de monolito distribuido. La pregunta de este
capítulo no es si lo es, sino qué decisiones lo produjeron, porque la propuesta de «dividir más
fino» repetiría varias de ellas.

## 2. 🧠 Cómo se fabrica un monolito distribuido

| Decisión | Qué parecía comprar | Qué acopla en realidad | Monedas |
|---|---|---|---|
| servicio por entidad | reutilización y «un dueño por tabla» | cada caso de uso cruza varios servicios | runtime, código |
| granularidad excesiva (*nanoservices*) | despliegues pequeños | más saltos, contratos y coordinación por cambio | runtime, despliegue |
| librería `commons` con dominio | no duplicar | una versión que todos deben adoptar a la vez | código, despliegue |
| entorno de integración compartido como único filtro | seguridad antes de liberar | nadie sale si otro está rojo | despliegue, equipos |
| pasarela o BFF con reglas de negocio | un punto de composición | lógica sin dueño de dominio, cambios en dos sitios | código, equipos |
| configuración o caché compartidas | consistencia operativa | fallos correlacionados, cambios que afectan a todos | runtime |
| equipos por capa técnica | especialización | cada cambio de negocio cruza equipos | equipos |

Ninguna fila basta sola: una librería de logging compartida no es un problema, y una pasarela que
solo compone respuestas tampoco. Lo que fabrica el monolito distribuido es la combinación, y sobre
todo el corte por entidad, que obliga a las demás.

### Entidad frente a capacidad

```text
por entidad: CRUD sobre tablas              por capacidad: decisión con su dato
CreateOrder ─► order-service                CreateOrder ─► orders: pedido y total
           ─► customer-service                          ─► inventory: reserva
           ─► product-service                           ─► payments: autorización
           ─► price-service
           ─► stock-service
cinco saltos para una decisión              tres colaboraciones, cada una con su garantía
```

Un servicio por entidad es dueño del dato pero no de la **decisión**: «¿hay stock para reservar?»
necesita leer stock y escribir reserva en el mismo sitio, y un `stock-service` que solo expone
`GET` y `PUT` deja esa regla en quien llama. El llamador termina concentrando la lógica de varios
servicios y se vuelve el monolito, ahora con red. El corte por capacidad pone juntos el dato y las
reglas que lo cambian, que es lo que [módulos por capacidad](../02-modularidad-y-limites-internos/01-modulos-alrededor-de-capacidades-de-negocio.md)
enseña dentro del monolito.

### Granularidad

«Más pequeño» no significa «más desacoplado». El desacoplamiento depende de que los cambios y el
ownership queden dentro de una unidad; cada frontera adicional cuesta un contrato, una llamada o un
evento, un pipeline y una guardia. Una heurística útil: un servicio debería contener los cambios
habituales de una capacidad. Si casi todo cambio toca dos o más servicios, el corte es demasiado
fino o está en el eje equivocado.

### La ley de Conway en los dos sentidos

Melvin Conway observó en 1968 que los sistemas reproducen la estructura de comunicación de quien los
diseña. Con equipos por capa técnica, cada cambio de negocio cruza equipos, y el sistema se corta
por capas aunque el diagrama diga «servicios». En sentido inverso, cortar por capacidad sin cambiar
los equipos deja una arquitectura que la organización empuja de vuelta a su forma anterior. Diseñar
los equipos para la arquitectura buscada —a veces llamado *maniobra inversa de Conway*— es parte del
corte, y es el tema de [equipos y gobernanza](../05-decision-evolucion-y-practica/05-equipos-ownership-y-gobernanza-evolutiva.md).

### Plataforma compartida

Compartir plataforma no es el problema: transporte, autenticación, logging o métricas en librerías
estables, con dueño y sin dominio, ahorran trabajo sin acoplar decisiones. Lo que acopla es
compartir **dominio** —entidades y reglas en `commons`— y compartir **la puerta de salida** —un
entorno donde todos deben estar verdes para que cualquiera libere—. El primero obliga a recompilar y
desplegar juntos; el segundo convierte el release de cada equipo en un release de todos. La
alternativa a la suite end-to-end como único filtro son pruebas de contrato por consumidor y
despliegues que cada servicio puede hacer y revertir solo.

## 3. 🧰 Plataformas

| Plataforma | Mecanismo de librería interna | Qué acopla | Trampa frecuente |
|---|---|---|---|
| Java | JAR interno en un repositorio de artefactos | el build resuelve una sola versión por aplicación; dos dependencias con versiones distintas obligan a alinear | `commons` con entidades JPA compartidas |
| Node/TypeScript | paquete del workspace o de un registro privado | en un monorepo con dependencias unificadas, una versión para todos | un paquete de tipos del dominio como contrato de todos |
| Go | módulo interno versionado con tags | la selección de versiones elige la mayor de las mínimas requeridas, y una actualización de un dependiente arrastra a los demás | un package `models` común |
| Python | paquete interno en un índice privado | cada aplicación resuelve su entorno, pero los modelos compartidos cambian en todas | `commerce_common` con modelos ORM |

Los cuatro mecanismos permiten versionar una librería interna; ninguno impide que contenga dominio.
Lo que la vuelve inocua es su contenido —transporte y utilidades estables— y una política de
compatibilidad que permita a cada consumidor actualizar a su ritmo.

## 4. ⚖️ Decisión y coste

Corta por capacidad —dato más decisiones— y no por entidad. Empieza grueso y divide solo cuando haya
razones de cambio, escala o aislamiento medidas. Comparte plataforma sin dominio, y sustituye la
puerta común de integración por contratos por consumidor y despliegues independientes. Alinea los
equipos con las capacidades. Cada decisión cuesta algo: capacidades más gruesas son servicios más
grandes; sin `commons` de dominio hay pequeñas duplicaciones y traducciones; sin el entorno común
hacen falta pruebas de contrato y disciplina de compatibilidad.

## ⚠️ Errores frecuentes

- «Más pequeño es más desacoplado». Más fronteras son más contratos y coordinación si los cambios
  las cruzan.
- «Un servicio por tabla es un buen punto de partida». Separa el dato de la decisión y empuja la
  lógica al llamador.
- «Una librería común evita la duplicación sin coste». La cobra en versiones y despliegues
  coordinados cuando contiene dominio.
- «Si el E2E común está verde, se puede liberar con confianza». Convierte cada release en un release
  de todos y no localiza el fallo.
- «La estructura de equipos es un asunto de RR. HH.». Es una fuerza que empuja la arquitectura hacia
  su propia forma.

## 5. ✅ Veredicto

Un monolito distribuido rara vez se diseña: se fabrica con cortes por entidad, granularidad
excesiva, dominio compartido, una puerta común de release y equipos que no coinciden con las
capacidades. Antes de volver a cortar, nombra cuáles de esas decisiones están presentes y corrige
las causas; dividir más fino con las mismas causas reproduce el problema con más piezas.

## 📚 Referencias

- [How Do Committees Invent?, Melvin E. Conway](https://www.melconway.com/Home/Committees_Paper.html)
- [Conway's Law, Martin Fowler](https://martinfowler.com/bliki/ConwaysLaw.html)
- [Pattern: Decompose by business capability, microservices.io](https://microservices.io/patterns/decomposition/decompose-by-business-capability.html)
- [Microservice Trade-Offs, Martin Fowler](https://martinfowler.com/articles/microservice-trade-offs.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es un servicio por entidad y en qué se diferencia de un servicio por capacidad?
2. 🟢 ¿Qué son los *nanoservices*?
3. 🟢 ¿Qué dice la ley de Conway?
4. 🟢 ¿Qué distingue una librería de plataforma inocua de una librería `commons` que acopla?
5. 🟢 ¿Por qué un entorno de integración compartido puede ser una señal de despliegue acoplado?
6. 🟢 ¿Qué problema causa una pasarela con reglas de negocio?
7. 🟡 ¿Por qué un `stock-service` CRUD deja la regla de reserva en quien lo llama?
8. 🟡 ¿Por qué `order-service` terminó siendo el verdadero monolito del sistema?
9. 🟡 ¿Qué heurística usarías para saber si un corte es demasiado fino?
10. 🟡 ¿Cómo empuja una organización por capas técnicas a la arquitectura?
11. 🟡 ¿Qué es la maniobra inversa de Conway y qué riesgo tiene?
12. 🟡 ¿Qué pondrías en una librería compartida y qué dejarías fuera?
13. 🟡 ¿Qué sustituye a una suite end-to-end común como filtro de release?
14. 🟡 ¿Por qué una configuración o una caché compartidas producen fallos correlacionados?
15. 🟡 ¿Qué diferencia hay entre esta lista de causas y el diagnóstico de `04/01`?
16. 🟡 ¿Por qué el corte por entidad obliga a varias de las otras decisiones de la tabla?
17. 🟡 ¿Cómo acopla una librería interna compartida en Java y en Go, y qué tienen en común?
18. 🟠 ¿Qué falla igual en un paquete de tipos compartido en TypeScript y en modelos ORM compartidos en Python?
19. 🟠 Te piden dividir los cinco servicios por entidad en diez más finos. ¿Qué harías en su lugar?
20. 🟠 Una actualización de seguridad de `commons` obliga a desplegar doce servicios el mismo día. ¿Qué harías hoy y qué cambiarías?
21. 🟠 La suite end-to-end común está roja por un servicio ajeno y tu equipo tiene una corrección urgente. ¿Qué haces y qué cambias después?
22. 🟠 Quieres pasar de servicios por entidad a servicios por capacidad sin una reescritura. ¿Qué pasos reversibles darías?
23. 🟠 Dirección quiere reorganizar equipos por capacidad antes de tocar la arquitectura y los arquitectos quieren lo contrario. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que la granularidad actual ya es la adecuada?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [06 — Acoplamiento asíncrono: el monolito distribuido con broker](06-acoplamiento-asincrono-el-monolito-distribuido-con-broker.md).

**Siguiente:** [08 — Desmontar un monolito distribuido](08-desmontar-un-monolito-distribuido.md).
