# 02 — Descomposición y fronteras

> Dónde se corta un sistema en servicios, con qué criterios, y cómo se defiende ese corte en papel y
> en voz alta. Asume leído [`01`](01-que-es-un-microservicio.md) —la definición por autonomía y el
> precio— y da por conocido DDD estratégico, que es de
> [`arquitectura/01-bases/01-bases/06`](../../01-bases/01-bases/06-ddd-estrategico.md).
>
> **Este capítulo no lleva sección de plataformas** (§6, punto 6 de la guía), y que no la lleve es
> contenido: dónde cortar es de las poquísimas decisiones de este corpus que sale idéntica en Java,
> en Node, en Go y en Python.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Te dan un dominio y te piden una propuesta de servicios en quince minutos, con papel. Y la trampa no
es cortar: es que **casi cualquier corte parece razonable mientras lo dibujas**. Las cajas quedan
bonitas, los nombres suenan bien, y el problema aparece seis meses después, cuando cada cambio de
regla toca tres servicios y cada pantalla necesita cuatro llamadas.

El corte malo tiene una firma reconocible:

```text
Un cambio de negocio          →  toca 3 servicios y 3 despliegues coordinados
Una pantalla del usuario      →  necesita 4 llamadas encadenadas
Una consulta habitual         →  necesita datos de 3 almacenes distintos
```

Ninguno de esos síntomas es un problema de tecnología. Los tres dicen lo mismo: **la frontera está
en el sitio equivocado**. Y son carísimos de arreglar, porque mover una frontera después significa
mover datos que ya tienen historial y contratos que ya tienen clientes.

Por eso este capítulo va de criterios, y por eso los criterios que funcionan miran al **cambio** y a
los **datos**, no al modelo de clases.

---

## 2. 🧱 Descomposición por capacidad de negocio

**Qué es.** Un servicio por **capacidad**: algo que la empresa hace y por lo que podría responder una
persona. Gestión de pedidos. Catálogo. Cobro. Reserva de existencias. Si la capacidad existiría
aunque el software no existiera, es buena candidata.

**Cómo va.** Se saca del organigrama y del lenguaje del negocio, no del modelo de datos. La prueba
rápida: si le lees el nombre del servicio a alguien de negocio y entiende de qué habla, vas bien; si
tienes que explicárselo, probablemente cortaste por tecnología.

```text
Capacidades reales           Falsas capacidades
──────────────────           ──────────────────
Catálogo                     Servicio de validación
Pedidos                      Servicio de base de datos
Cobros                       Servicio de utilidades
Reserva de existencias       Servicio de integración
```

**Cuánto.** Es el criterio más barato de aplicar y el que produce fronteras más estables, porque las
capacidades de una empresa cambian mucho más despacio que su software. Lo que cuesta es que requiere
acceso a alguien de negocio: sin esa conversación, acabas inventando capacidades desde el código.

**Cuándo sí.** Siempre como primer corte, y especialmente cuando el dominio es conocido y el
organigrama refleja de verdad cómo se trabaja.

**Cuándo no.** Cuando el organigrama es un accidente histórico —tres departamentos que hacen lo
mismo por motivos de una fusión de hace diez años—. Ahí copiar la estructura organizativa te
congela el accidente en la arquitectura.

> **Veredicto:** cortar por capacidad de negocio es el criterio por defecto y el que mejor envejece.
> Si solo te llevas un criterio de este capítulo, llévate este.

---

## 3. 🧱 Descomposición por subdominio, y la diferencia que importa

**Qué es.** El mismo ejercicio, hecho con las herramientas de DDD: identificas subdominios —nuclear,
de soporte, genérico— y sus **contextos acotados** (*bounded contexts*), y propones un servicio por
contexto.

**Cómo va.** La diferencia real con §2 no es el resultado, que suele parecerse mucho. Es **qué
descubres por el camino**: el mapa de contextos te obliga a nombrar dónde cambia el significado de
una palabra. "Cliente" en `orders` es una dirección de envío y un historial; en `payments` es un medio
de pago y un riesgo; en `customers` es una persona con consentimientos. Son tres modelos distintos con
el mismo nombre, y el corte por capacidad puede no verlo.

```text
Misma palabra, tres modelos:

  orders.Customer     → dirección de envío, historial de compras
  payments.Customer   → medio de pago, límite, scoring
  customers.Customer  → identidad, consentimientos, datos personales
```

Ese descubrimiento tiene una consecuencia directa de diseño: **cada contexto tiene su propio modelo y
traduce en la frontera**. No se comparte una clase `Customer` entre servicios, ni aunque tiente.

**Cuánto.** Cuesta tiempo y conversaciones: un mapa de contextos honesto sale de talleres con
negocio, no de leer el esquema de la base de datos. A cambio te ahorra el error más caro, que es
compartir un modelo canónico entre servicios.

**Cuándo sí.** Cuando el dominio tiene reglas ricas y el mismo término significa cosas distintas
según quién lo diga — banca, seguros, logística.

**Cuándo no.** En un dominio pequeño y sin ambigüedad, donde el vocabulario es uno solo. Ahí el
aparato de DDD es ceremonia y el corte por capacidad basta.

> **Veredicto:** capacidad y subdominio suelen dar el mismo dibujo; lo que cambia es que el segundo
> te obliga a declarar dónde una palabra cambia de significado. Cuando el dominio es ambiguo, esa
> declaración es justamente el diseño.

---

## 4. 🧭 Las cuatro heurísticas que de verdad deciden

Cuando capacidad y subdominio empatan —y empatan a menudo—, estas cuatro desempatan. Ninguna es
teórica: las cuatro se pueden comprobar con datos que ya tienes.

| Heurística | La pregunta | Qué indica |
|---|---|---|
| **Razón de cambio** | ¿Qué partes cambian siempre juntas en los últimos seis meses de commits? | Lo que cambia junto, va junto |
| **Volatilidad** | ¿Qué parte cambia cada semana y cuál no se toca desde hace un año? | Aislar lo volátil protege lo estable |
| **Perfil de carga** | ¿Qué parte recibe el 90 % del tráfico o consume el 90 % de la CPU? | Candidato a escalar solo |
| **Dueño del dato** | ¿Quién escribe este dato? ¿Uno o varios? | Si escriben varios, la frontera está mal |

La primera es la más útil y la menos usada. El historial de tu repositorio ya sabe dónde están las
fronteras: los archivos que aparecen juntos en el mismo commit una y otra vez pertenecen al mismo
servicio, digan lo que digan las cajas del diagrama.

Y hay una quinta que en banca manda sobre todas: **la frontera de cumplimiento**. Si una parte del
sistema está sujeta a auditoría, retención o certificación distintas del resto, aislarla tiene un
valor que no aparece en ninguna métrica técnica. Es un argumento que rinde en entrevistas del sector
porque casi nadie lo menciona.

> **💡 Truco:** cuando en la entrevista te pidan justificar un corte, di *"y lo confirmaría mirando
> qué archivos cambian juntos en el historial"*. Es concreto, es verificable y demuestra que has
> hecho esto con un sistema real y no solo en una pizarra.

---

## 5. 🪦 Los cuatro cortes que no son criterio

Cuatro formas de cortar que aparecen solas si nadie las frena, y que producen exactamente los
síntomas de §1.

- **Por capa técnica.** Un servicio "de acceso a datos", otro "de lógica", otro "de API". Es el
  monolito en capas repartido por la red: cada caso de uso los atraviesa los tres, así que cada
  cambio toca los tres y ninguno se despliega solo.
- **Por entidad.** Un servicio por tabla: `customers`, `addresses`, `products`, `prices`. Produce
  servicios anémicos que solo hacen CRUD y empuja toda la lógica de negocio al que los llama —que
  acaba siendo un orquestador gigante con todas las reglas—.
- **Por verbo.** Un servicio "validador", un "notificador", un "calculador". Suena a responsabilidad
  única y es lo contrario: son funciones, no capacidades, y ninguna es dueña de ningún dato.
- **Por reutilización.** "Este servicio lo van a usar todos". Optimizar por reutilización produce
  dependencias en estrella: cuando el servicio compartido cambia, cambia todo el mundo, y cuando se
  cae, se cae todo el mundo.

El patrón común de los cuatro: **cortan por cómo está hecho el software, no por cómo cambia el
negocio**. Y la frontera se paga en cambios, no en ejecución.

> **⚠️ Advertencia:** el corte por entidad es el más frecuente en entrevistas porque es el que sale
> solo al mirar un diagrama entidad-relación. Si tu propuesta tiene un servicio por tabla, el
> entrevistador va a preguntar dónde vive la regla de negocio — y la respuesta honesta va a ser "en
> el que los llama a todos".

---

## 6. ⚖️ El test de la frontera

Tres comprobaciones que se pueden hacer sobre un diagrama en cinco minutos. Son el criterio de
aceptación de cualquier propuesta de corte, incluida la tuya.

| Prueba | Cómo se comprueba | Si falla |
|---|---|---|
| **Cambian juntos** | ¿Un cambio de negocio típico toca uno o varios? | Fusiónalos: son uno |
| **Hablan poco** | ¿Cuántas llamadas cruzan la frontera por caso de uso? | Si son muchas, la frontera está en medio de una operación |
| **Datos propios** | ¿Cada dato tiene exactamente un escritor? | Si tiene dos, la frontera está mal, no los datos |

La segunda merece un número. Si un caso de uso habitual cruza la frontera más de dos o tres veces,
no has separado dos servicios: has partido una operación por la mitad y has puesto una red en el
corte. El coste sale en latencia, en fallos parciales y en pruebas imposibles.

Y la tercera es la que más discusiones evita en una entrevista: **cada dato, un escritor**. Cuando
dos servicios escriben lo mismo, la pregunta no es cómo se sincronizan, es por qué están separados.

```text
Regla de frontera:

  cambian juntos        →  son uno
  hablan mucho          →  la frontera está en medio de una operación
  escriben lo mismo     →  la frontera es ficción
```

---

## 7. 🔭 El corte del sistema de ejemplo, con sus dudas

Así queda el sistema del corpus, y —más importante— así se defienden las decisiones dudosas, que es
lo que te van a preguntar.

```text
catalog      productos, precios, disponibilidad publicada
customers    identidad, datos personales, consentimientos
orders       el carrito, el pedido y su ciclo de vida
inventory    existencias reales y reservas
payments     cobros, devoluciones, conciliación
```

Las tres decisiones que no son obvias, con su argumento:

- **`catalog` e `inventory` separados**, aunque los dos hablen de productos. Cortan por volatilidad
  y por carga: el catálogo se lee millones de veces y cambia poco; las existencias cambian con cada
  venta y se leen menos. Además tienen dueños distintos en el negocio.
- **`orders` y `payments` separados**, aunque el flujo los una. Cortan por cumplimiento: el cobro tiene
  requisitos de auditoría propios. Es el mismo argumento que en banca se usa para aislar el
  movimiento de dinero.
- **`customers` separado de `orders`**, aunque parezca que el pedido "tiene" un cliente. Lo que
  `orders` necesita es una copia de la dirección de envío **en el momento de la compra** —que no
  debe cambiar si el cliente actualiza su domicilio mañana—, no una referencia viva.

Esa última decisión es la que mejor demuestra criterio, porque contiene el matiz que casi nadie dice:
**hay datos que se copian a propósito porque el negocio quiere la foto, no el enlace**. La factura
lleva la dirección de entonces.

---

## 8. 🧭 Cómo se responde "¿cuántos microservicios harías?"

No se responde con un número. Se responde con el criterio y con el primer paso, que es lo que la
pregunta está midiendo:

```text
¿Cuántos equipos van a mantenerlo?      → el techo práctico está cerca de ese número
¿Cuántas fronteras están claras HOY?    → empiezas por esas, y solo por esas
¿Qué necesita desplegarse o escalar solo? → ese es el primero que extraes
```

Y la frase, que conviene tener ensayada:

> "No daría un número sin ver el dominio. Empezaría por las fronteras que el negocio ya tiene
> claras —tres o cuatro— y dejaría el resto dentro de un monolito modular hasta que alguna pida
> salir. Prefiero equivocarme por tener pocos servicios que por tener muchos: juntar es fácil,
> separar mal es caro."

Un aviso que se agradece en la entrevista: los servicios acaban pareciéndose a la organización que
los construye, lo quieras o no. Si vas a proponer un corte que no coincide con los equipos, dilo en
voz alta y di cómo lo resolverías, porque si no lo dices, el diseño se ajustará solo al organigrama
y sin que nadie lo decida.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Se descompone por entidades del modelo" | Eso produce CRUD anémico y un orquestador con todas las reglas. Se corta por capacidad de negocio |
| "Un contexto acotado es un microservicio" | Es una **frontera candidata**. Puede haber varios servicios dentro de un contexto; nunca un servicio a caballo entre dos |
| "Primero el corte técnico, luego el de negocio" | El corte técnico no se puede corregir después: los datos ya tienen historial y los contratos ya tienen clientes |
| "Este servicio lo usarán todos, así reutilizamos" | Optimizar por reutilización crea dependencias en estrella: cambia uno, despliegan todos |
| "Si comparten código, comparten servicio" | Compartir código no es criterio. Lo es compartir **razón de cambio** y **dueño del dato** |
| "Cortamos como está el organigrama" | Solo si el organigrama refleja cómo se trabaja hoy. Si es un accidente histórico, lo congelas en la arquitectura |
| "Cuantos más servicios, más flexible" | Cada frontera es un contrato que versionar y una llamada que puede fallar. La flexibilidad la dan las fronteras **correctas**, no muchas |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 2, "How to
   Model Microservices": acoplamiento y cohesión aplicados a fronteras de servicio. **El mejor
   tratamiento del tema en un solo capítulo.**
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 2, "Decomposition
   strategies", con los obstáculos que el resto de la bibliografía se salta.
3. **Libro** — Eric Evans, *Domain-Driven Design*, Addison-Wesley, 2003. Parte IV, sobre contextos
   acotados y mapa de contextos. Se lee por partes, no entero.
4. **Fuente primaria** — Chris Richardson, «Decompose by business capability»:
   [microservices.io/patterns/decomposition/decompose-by-business-capability.html](https://microservices.io/patterns/decomposition/decompose-by-business-capability.html).
5. **Fuente primaria** — Chris Richardson, «Decompose by subdomain»:
   [microservices.io/patterns/decomposition/decompose-by-subdomain.html](https://microservices.io/patterns/decomposition/decompose-by-subdomain.html).
6. **Fuente primaria** — Martin Fowler, «BoundedContext», la definición corta y su matiz:
   [martinfowler.com/bliki/BoundedContext.html](https://martinfowler.com/bliki/BoundedContext.html).
7. **Fuente primaria** — Martin Fowler, «Conway's Law», el aviso de §8:
   [martinfowler.com/bliki/ConwaysLaw.html](https://martinfowler.com/bliki/ConwaysLaw.html).
8. **Charla** — Domain-Driven Design Europe, «Bounded Contexts» (Eric Evans). La fuente para el
   matiz de que un contexto es lingüístico antes que técnico.

---

## 🧠 Preguntas

1. ¿Qué es cortar por capacidad de negocio, y cómo sabes que una capacidad es real? 🟢
2. Define contexto acotado en una frase. 🟢
3. Enumera las cuatro heurísticas de desempate del capítulo. 🟢
4. Nombra los cuatro cortes que no son criterio y di qué produce cada uno. 🟢
5. ¿Cuáles son las tres pruebas del test de la frontera? 🟢
6. ¿Qué significa "cada dato, un escritor", y qué indica cuando se incumple? 🟡
7. ¿En qué se diferencia cortar por capacidad de cortar por subdominio, si el resultado se parece
   tanto? 🟡
8. ¿Por qué un contexto acotado es una frontera "candidata" y no directamente un servicio? 🟡
9. Tres servicios usan una clase `Customer` compartida. ¿Qué problema tienes y cómo se llama? 🟡
10. ¿Por qué cortar por capa técnica impide el despliegue independiente? 🟡
11. Diferencia entre copiar un dato a propósito y duplicar un dato por accidente. 🟡
12. ¿Qué te dice el historial de commits sobre dónde están las fronteras? 🟠
13. Un caso de uso cruza cuatro veces la frontera entre dos servicios. ¿Qué concluyes y qué haces? 🟠
14. Te proponen un servicio "de notificaciones" que usarán los cinco servicios. Argumenta a favor y
    en contra. 🟠
15. El organigrama tiene tres departamentos que hacen lo mismo por una fusión antigua. ¿Cortas según
    el organigrama? Justifica. 🟠
16. ¿Cómo justificarías separar `catalog` de `inventory` si ambos hablan de productos? 🟠
17. Dos servicios escriben el mismo campo. Da dos soluciones distintas y di cuál prefieres y por
    qué. 🟠
18. En banca, ¿qué criterio de corte puede pesar más que la carga y la volatilidad, y por qué? 🟠
19. ¿Cuándo aceptarías un servicio que solo hace CRUD sobre una entidad? 🟠
20. Te piden un número de microservicios en la primera reunión. Responde sin dar un número y sin
    sonar evasivo. 🟠
21. Propón el corte de un sistema de reservas de hotel —búsqueda, reserva, pago, limpieza,
    facturación— y defiende las dos decisiones más discutibles. 🔴
22. Tienes un corte ya hecho por entidades (`customers`, `addresses`, `products`, `prices`).
    Propón el rediseño y el orden de los pasos para llegar a él sin parar el negocio. 🔴
23. Diseña las tres comprobaciones que harías sobre un sistema existente para decidir si sus
    fronteras están bien, y di qué dato necesitas para cada una. 🔴
24. El equipo de frontend pide un endpoint que devuelva pedido, cliente y productos juntos. Da tres
    respuestas arquitectónicas distintas, con su precio, y elige. 🔴

---

**Anterior:** [`01` — Qué es un microservicio](01-que-es-un-microservicio.md) · **Siguiente:**
[`03` — El camino desde el monolito](03-el-camino-desde-el-monolito.md) · **Relacionado:**
[`04` — El monolito distribuido](04-el-monolito-distribuido.md) ·
[`arquitectura/01-bases/01-bases/06`](../../01-bases/01-bases/06-ddd-estrategico.md)

**Taller, opcional:** [`06/02` — Strangler fig con Envoy](../06-talleres/02-strangler-fig-con-envoy.md).
