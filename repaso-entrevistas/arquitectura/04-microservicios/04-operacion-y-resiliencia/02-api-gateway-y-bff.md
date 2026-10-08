# 02 — API gateway y BFF

> Qué va en el borde y qué no, y por qué un BFF no es una capa extra gratuita. Asume leídos
> [`02-comunicacion/02`](../02-comunicacion/02-http-entre-servicios.md) y
> [`03-datos-y-consistencia/02`](../03-datos-y-consistencia/02-consultas-entre-servicios.md). La
> autenticación y la propagación de identidad son de
> [`arquitectura/01-bases/04-seguridad`](../../01-bases/04-seguridad/):
> aquí entran solo como responsabilidad del borde.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Cinco servicios internos, y fuera: una web, una aplicación móvil y dos socios que consumen la API.
Sin nada en medio, cada consumidor externo tendría que saber **demasiado**:

```text
· qué servicio responde a qué
· cómo autenticarse contra cada uno
· qué hacer cuando uno cambia de forma
· cómo llamar a cinco para pintar una pantalla
```

Y cada servicio tendría que resolver por su cuenta TLS, autenticación, límite de tasa y CORS. Poner
algo en el borde evita las dos cosas.

El problema aparece después: **ese algo en el borde crece**. Primero enruta, luego valida, luego
transforma, y un día alguien mete ahí una regla de negocio "porque está en el camino de todo". Y
entonces se ha reinventado el bus de servicios de 2008, con su equipo de plataforma como cuello de
botella de todos los demás.

---

## 2. 🧱 Qué es un API gateway

**Qué es.** Un punto único de entrada que enruta hacia los servicios y se ocupa de lo transversal del
borde.

**Cómo va.** Lo que sí le toca, con su porqué:

| Responsabilidad | Por qué en el borde |
|---|---|
| Terminación de TLS | Un solo sitio con certificados que renovar |
| Autenticación | Validar la credencial una vez, no cinco |
| Límite de tasa | Proteger a todo lo que hay detrás, por consumidor |
| Enrutado por ruta o por host | Los consumidores no conocen la topología interna |
| Observabilidad del borde | Un punto donde medir todo el tráfico entrante |
| Encabezados de seguridad y CORS | Política uniforme, y evita repetirla en cada servicio |

Y lo que **no** le toca nunca: lógica de negocio, transformaciones que conocen el dominio,
orquestación de flujos, composición pesada de varias llamadas con reglas.

**Con qué.** Hay gateways gestionados por los proveedores de nube, productos de código abierto
dedicados, y controladores de entrada del propio orquestador. La elección depende de dónde corras y
de qué necesites; lo que no cambia es la frontera de responsabilidades.

**Cuánto.** Cuesta un salto más, un componente crítico —si cae, no entra nada— y un equipo dueño. Y
cuesta una cola de peticiones de cambio si se centraliza mal, que es el riesgo real.

**Cuándo sí.** En cuanto hay más de dos o tres servicios expuestos.

**Cuándo no.** Con un solo servicio y un solo consumidor: ahí el gateway es una pieza que no compra
nada.

> **Veredicto:** el gateway es infraestructura, no arquitectura de aplicación. La prueba: si para
> cambiar una regla de negocio hay que tocar el gateway, ya se cruzó la línea.

---

## 3. 🧱 BFF: backend for frontend

**Qué es.** Un servicio por **experiencia de cliente** —web, móvil, socios— que adapta el sistema a
lo que esa experiencia necesita.

```text
        web ──► BFF web ──┐
     móvil ──► BFF móvil ─┼──► orders · catalog · customers · inventory · payments
    socios ──► API socios ┘
```

**Cómo va.** Cada BFF compone, recorta y adapta para su cliente: la web puede pedir mucho detalle en
una llamada; el móvil quiere cargas pequeñas y menos peticiones; los socios quieren un contrato
estable durante años.

Y la parte que de verdad define el patrón: **lo posee el equipo de esa experiencia**. No es una
decisión de tecnología, es de propiedad. Si lo mantiene el equipo de plataforma, cada cambio de
pantalla entra en una cola ajena y el BFF acaba siendo genérico — que es exactamente lo que no debía
ser.

**Con qué.** Suele escribirse en la plataforma del equipo que lo posee, que en frontend es
habitualmente Node/TS: comparten lenguaje, herramientas y tipos con el cliente. Es uno de los pocos
sitios donde el poliglotismo tiene un argumento claro
([`05-plataformas/06`](../05-plataformas/06-la-matriz-de-decision.md)).

**Cuánto.** Cuesta un servicio más por experiencia: pipeline, despliegue, alertas y guardia. Si el
equipo de frontend no está preparado para operar un servicio, el BFF se degrada igual.

**Cuándo sí.** Con dos o más experiencias con necesidades distintas, o cuando el móvil tiene ritmos
de despliegue que no controlas.

**Cuándo no.** Con un solo frontend y un equipo que hace todo: ahí un BFF es una capa de indirección
sin comprador.

> **💡 Truco:** la objeción "es una capa extra innecesaria" se responde con propiedad, no con
> tecnología: *"lo mantiene quien conoce la pantalla, y así el contrato de la web puede cambiar cada
> semana sin tocar los servicios ni pedir permiso a nadie"*.

---

## 4. ⚖️ Gateway, BFF y agregador: tres cosas distintas

Se confunden constantemente, y distinguirlos es una pregunta frecuente:

| | Gateway | BFF | Agregador |
|---|---|---|---|
| **Qué hace** | Enruta y aplica política de borde | Adapta el sistema a una experiencia | Junta datos de varios servicios |
| **Cuántos hay** | Uno | Uno por experiencia | Los que hagan falta |
| **Quién lo posee** | Plataforma | El equipo de esa experiencia | Quien necesite la vista |
| **Conoce el dominio** | No | Sí, el de su experiencia | Sí, el de su vista |
| **Si cae** | No entra nada | Se cae esa experiencia | Se cae esa pantalla |

Un BFF **es** un agregador, entre otras cosas; un gateway **no** debería serlo. Y la composición
ligera —dos llamadas y juntar— puede vivir en el gateway sin daño; la composición con reglas, no.

---

## 5. 🧱 Autenticación en el borde, autorización dentro

**Qué es.** El reparto que evita los dos errores clásicos: validar la credencial cinco veces, o
confiar en que "ya lo validó el gateway".

```text
BORDE                                DENTRO
─────────────────────────────        ──────────────────────────────────
valida la credencial                 vuelve a comprobar la identidad recibida
la traduce a identidad interna       decide si ESE usuario puede hacer ESO
rechaza lo no autenticado            (autorización: es del dominio)
```

**Cómo va.** El gateway valida y propaga la identidad hacia dentro por un mecanismo que el resto pueda
verificar. Lo que no hace es decidir permisos de negocio: si `orders` sabe que un usuario solo puede
ver sus pedidos, esa regla es suya.

Y la advertencia que corresponde a este capítulo: **el borde no es una frontera de confianza
suficiente**. Un servicio que confía ciegamente en cualquier encabezado de identidad es vulnerable a
cualquiera que consiga hablar directamente con él. El desarrollo de eso —mTLS, tokens internos,
zero-trust— está en
[`arquitectura/01-bases/04-seguridad/04`](../../01-bases/04-seguridad/04-propagacion-de-identidad.md).

> **⚠️ Advertencia:** "ya lo valida el gateway" es la frase que convierte una red interna en un único
> fallo de seguridad. El borde filtra el tráfico no autenticado; no sustituye a la autorización de
> cada servicio.

---

## 6. 🧱 Límite de tasa y protección del borde

**Qué es.** Rechazar temprano lo que el sistema no puede atender, y proteger a los servicios internos
de un consumidor que se descontrola.

**Cómo va.** Las decisiones que hay que tomar y que casi nunca se escriben:

| Decisión | Opciones | Comentario |
|---|---|---|
| **Por quién** | Por consumidor, por usuario, por IP | Por consumidor identificado es lo útil; por IP es lo que queda si no hay identidad |
| **Qué límite** | Peticiones por minuto, concurrencia, coste | La concurrencia protege mejor que el ritmo |
| **Qué se devuelve** | `429` con `Retry-After` | Sin `Retry-After`, el cliente reintenta a ciegas y empeora |
| **Qué se exime** | Salud, autenticación | Limitar el login en un incidente lo agrava |

**Cuánto.** Cuesta poco y evita mucho. Lo que sí cuesta es la conversación: cortar a un consumidor sin
avisar convierte un problema técnico en uno entre equipos
([`02-comunicacion/02`](../02-comunicacion/02-http-entre-servicios.md)).

> **🧠 Modelo mental:** rechazar rápido es un acto de resiliencia. Un `429` inmediato es mucho mejor
> para todos que una petición aceptada que tarda treinta segundos y acaba en timeout: consume
> recursos, ocupa hilos y encima falla.

---

## 7. 🧰 En las cuatro plataformas

El gateway casi nunca se escribe: se configura. Lo que sí se escribe es el BFF, y ahí la plataforma
importa.

| Plataforma | Papel habitual en el borde | Lo que te deja a ti |
|---|---|---|
| **Java** | Gateway programable del ecosistema cuando hace falta lógica de enrutado propia; BFF si el equipo es de backend | Vigilar el arranque y la memoria si el BFF escala mucho; y no meter dominio en el gateway programable |
| **Node/TS** | **El sitio natural del BFF**: mismo lenguaje que el frontend, tipos compartidos, composición asíncrona cómoda | Que el BFF no se convierta en un monolito de pantallas; y el bucle de eventos, si hay transformación pesada |
| **Go** | Proxies y gateways de código abierto escritos en Go; BFF eficiente si el equipo lo domina | Poca ayuda de marco: el BFF hay que estructurarlo a mano |
| **Python** | BFF cuando el equipo ya es de Python —típico si el consumidor es analítica o ciencia de datos | El modelo de ejecución al componer muchas llamadas: hay que usar bien el modo asíncrono |

- **Lo que te deja a ti en las cuatro:** decidir **quién posee** cada pieza. Es la decisión que
  determina si el BFF cumple su función, y no depende del lenguaje.
- El gateway gestionado por la nube reduce trabajo y ata a su modelo de configuración; el de código
  abierto da control y se opera. Es la misma disyuntiva de siempre y conviene plantearla así.

> **🧰 Plataforma:** que el BFF de la web se escriba en Node/TS no es una moda: comparte lenguaje y
> tipos con el cliente que lo consume, lo mantiene el mismo equipo y el contrato se verifica en el
> mismo pipeline. Es el argumento más sólido de poliglotismo que tiene este corpus.

---

## 8. 🧭 Cómo se elige

```text
¿Cuántas experiencias de cliente distintas hay?
│
├─ una ──► gateway para lo transversal; sin BFF.
│          La composición vive en el servicio que sirve esa pantalla.
│
└─ dos o más (web, móvil, socios)
   │
   ├─ ¿Sus necesidades de datos difieren de verdad? ──► un BFF por experiencia
   │
   └─ ¿Difieren poco? ──────────────────────────────► un solo BFF, y se parte
                                                       cuando duela
```

Y la frase:

> "Gateway para TLS, autenticación, límite de tasa y enrutado. BFF cuando hay varias experiencias con
> necesidades distintas, y lo posee el equipo de esa experiencia. Y ninguna regla de negocio en el
> borde: si para cambiar una regla hay que tocar el gateway, el gateway se ha convertido en el
> monolito."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El gateway es un balanceador" | El balanceador reparte carga; el gateway aplica política de borde y enruta por ruta o por host |
| "El BFF es una capa extra innecesaria" | Es una capa con dueño: el equipo de la experiencia. Sin él, cada cambio de pantalla depende de otro equipo |
| "Ponemos la validación de negocio en el gateway para no repetirla" | Si necesita conocer el dominio, no es del borde. Acabas con el equipo de plataforma como cuello de botella |
| "Con el gateway ya tenemos seguridad" | Filtra lo no autenticado. La autorización es de cada servicio, y confiar ciegamente en un encabezado es una vulnerabilidad |
| "Un BFF por cliente es duplicar código" | Duplican composición, no dominio. Y lo que evitan es un contrato genérico que no sirve bien a ninguno |
| "El gateway compone las respuestas de cinco servicios" | Composición ligera sí; con reglas, no. Eso es un BFF o un agregador con dueño |
| "Limitamos por IP" | Sirve si no hay identidad, y falla con proxies y con NAT. Con consumidores identificados, se limita por consumidor |

---

## 📚 Para profundizar

1. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 8, "External API
   patterns": gateway, BFF y composición, con sus contraindicaciones. **El capítulo de referencia.**
2. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 4, sección del
   borde, y el tratamiento de la propiedad de los equipos.
3. **Fuente primaria** — Sam Newman, «Backends For Frontends», el artículo que fijó el patrón y su
   argumento de propiedad:
   [samnewman.io/patterns/architectural/bff/](https://samnewman.io/patterns/architectural/bff/).
4. **Fuente primaria** — Chris Richardson, «Pattern: API Gateway / Backends for Frontends»:
   [microservices.io/patterns/apigateway.html](https://microservices.io/patterns/apigateway.html).
5. **Fuente primaria** — Chris Richardson, «Pattern: API Composition», para la parte de agregación:
   [microservices.io/patterns/data/api-composition.html](https://microservices.io/patterns/data/api-composition.html).
6. **Material de referencia** — Amazon Builders' Library, «Using load shedding to avoid overload»,
   para la parte de límite de tasa y rechazo temprano:
   [aws.amazon.com/builders-library/using-load-shedding-to-avoid-overload/](https://aws.amazon.com/builders-library/using-load-shedding-to-avoid-overload/).
7. **Charla** — GOTO Conferences, «Backends for Frontends» (Sam Newman). Es la versión hablada del
   artículo, con los errores de adopción más frecuentes.

---

## 🧠 Preguntas

1. ¿Qué responsabilidades tiene un API gateway? 🟢
2. ¿Qué no debe hacer nunca un gateway? 🟢
3. ¿Qué es un BFF y quién debe poseerlo? 🟢
4. Diferencia entre gateway, BFF y agregador. 🟢
5. ¿Qué se hace en el borde y qué dentro, en cuanto a identidad? 🟢
6. ¿Qué decisiones hay que tomar al configurar un límite de tasa? 🟢
7. ¿Por qué la propiedad del BFF es más importante que su tecnología? 🟡
8. ¿Por qué "ya lo valida el gateway" es una frase peligrosa? 🟡
9. ¿Por qué limitar por concurrencia protege mejor que limitar por ritmo? 🟡
10. ¿Qué diferencia hay entre composición ligera y composición con reglas, y por qué importa? 🟡
11. ¿Por qué un BFF por experiencia no es duplicar código? 🟡
12. ¿Por qué el gateway se convierte en cuello de botella organizativo? 🟡
13. ¿Qué exime del límite de tasa y por qué? 🟡
14. ¿Por qué el BFF de la web suele escribirse en Node/TS, y cuándo ese argumento deja de valer 🟡
15. El equipo de plataforma tiene tres meses de cola por cambios en el gateway. ¿Qué propones? 🟠
16. El móvil necesita cargas más pequeñas que la web. ¿Cómo lo resuelves? 🟠
17. ¿Cómo evitas que el BFF se convierta en un monolito de pantallas? 🟠
18. ¿Qué haces si el equipo de frontend no puede operar un servicio? 🟠
19. Un socio externo consume tu API interna. ¿Qué cambias? 🟠
20. El gateway se cae y no entra nada. ¿Qué medidas de diseño lo mitigan? 🟠
21. ¿Cómo decides entre gateway gestionado y gateway de código abierto? 🟠
22. Diseña el borde de un sistema con web, móvil y dos socios: qué piezas hay, quién las posee y qué
    contrato expone cada una. 🔴
23. Un equipo propone que el gateway componga las respuestas de cinco servicios y aplique
    descuentos. Responde con alternativas concretas. 🔴
24. Diseña la política de límite de tasa del sistema: por quién, qué límites, qué se devuelve, qué
    se exime y cómo se comunica a los consumidores. 🔴
25. Diagnostica: tras añadir el BFF móvil, la latencia de la aplicación empeoró. Da tres hipótesis
    ordenadas. 🔴

---

**Anterior:** [`01` — Descubrimiento y enrutamiento](01-descubrimiento-y-enrutamiento.md) ·
**Siguiente:** [`03` — Resiliencia en la práctica](03-resiliencia-en-la-practica.md) ·
**Relacionado:** [`03-datos-y-consistencia/02`](../03-datos-y-consistencia/02-consultas-entre-servicios.md)
· [`05-plataformas`](../05-plataformas/)

**Taller, opcional:** [`06/02` — Strangler fig con Envoy](../06-talleres/02-strangler-fig-con-envoy.md).
