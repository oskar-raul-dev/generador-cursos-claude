# 02 — Los errores escondidos

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`01` — Heredar el legado](01-heredar-el-legado.md): usa el mismo `mono-legacy` y la misma semilla.
Provoca, uno por uno, los cuatro accidentes que el legado deja salir por su API —el `200` con un
error dentro, el `500` con la traza de Java, la entidad serializada con datos que no debían salir y
una `LazyInitializationException` que aparece a ratos— y los hace sufrir a un cliente React limpio.
No corrige ninguno: su dueño es el taller 04. Termina cuando puedes explicar, con salidas pegadas,
por qué un servidor sin contrato **acopla al cliente con sus accidentes**.

> Ejercita [`02/02` — API pública del módulo y encapsulación interna](../02-modularidad-y-limites-internos/02-api-publica-del-modulo-y-encapsulacion-interna.md)
> y [`04/04` — Contratos frágiles y despliegues coordinados](../04-monolito-distribuido/04-contratos-fragiles-y-despliegues-coordinados.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en npm y Maven Central; salidas corridas
> ese día en macOS con Docker Desktop, Node 24.21.0 y Chrome 154.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--provocación-el-200-que-esconde-un-error) · [6](#6--provocación-el-500-que-enseña-la-traza) · [7](#7--provocación-la-entidad-sale-entera) · [8](#8--provocación-la-excepción-que-aparece-a-ratos) · [9](#9-️-en-el-frontend) · [10](#10--evidencia-lo-que-el-cliente-tiene-que-saber) · [11](#11--errores-reales-al-correrlo) · [12](#12--plataformas) · [13](#13--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

Un contrato no es un documento: es lo que un cliente puede dar por cierto sin leer el código del
servidor. Sin contrato, el cliente aprende de lo que ve, y lo que ve incluye los accidentes.

```text
navegador ──► Vite :35173 ──/api──► mono-legacy :38081
(React)       (proxy)               ├─ 200 {"error": "..."}         el error se disfraza de éxito
                                    ├─ 500 {"trace": "..."}         la implementación sale por la API
                                    ├─ {"customer": {"passwordHash"}} la entidad sale entera
                                    └─ 500 a ratos                  el estado interno decide la respuesta
```

Tres ideas:

- **Un código de estado es parte del contrato.** Si todo es `200`, el cliente tiene que buscar un
  campo `error` que nadie documentó; si no lo busca, muestra un fallo como un éxito.
- **Lo que se serializa se publica.** Devolver la entidad JPA convierte cada columna, cada relación
  perezosa y cada detalle de sesión de Hibernate en respuesta de la API.
- **El cliente limpio es el que más sufre.** Un frontend bien escrito confía en HTTP y en tipos; el
  legado rompe las dos confianzas, y la interfaz se queda en blanco.

El precio del taller es mirar accidentes sin arreglarlos. Lo que compra es la lista exacta de lo que
el contrato del taller 04 tendrá que corregir, y de lo que romperá al corregirlo.

## 2. 🧰 Prerrequisitos y versiones

Todo lo del [taller 01](01-heredar-el-legado.md#2--prerrequisitos-y-versiones), más el frontend
opcional:

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Node.js | `24.21.0` (LTS) | Vite y el recorrido `front-smoke`; ejecuta `.ts` quitando los tipos |
| `react` y `react-dom` | `19.3.0` | la interfaz |
| `vite` | `8.3.1` | servidor de desarrollo con proxy hacia el legado |
| `@vitejs/plugin-react` | `6.1.1` | JSX y recarga en caliente |
| `typescript` | `7.0.2` | comprobación de tipos (`npm run build`) |
| `@types/react`, `@types/react-dom` | `19.3.0` | tipos de React |

Las versiones son las últimas estables publicadas en npm el día de escritura, fijadas sin `^` ni `~`
en `laboratorio/frontend/package.json`. El frontend escucha en `35173` (§12 de la guía).

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── legacy/                     sin cambios respecto de estados/01
├── frontend/                   nuevo en este taller, opcional
│   ├── package.json            versiones exactas; package-lock.json las congela
│   ├── vite.config.ts          proxy /api y /health → :38081
│   ├── src/api.ts              el cliente HTTP "limpio"
│   ├── src/view.ts             los textos que ve el usuario, funciones puras
│   ├── src/App.tsx             la interfaz: catálogo, pedidos, detalle
│   └── scripts/smoke.ts        recorre en Node los mismos caminos que la interfaz
├── scripts/lab.py              + frontend, front-smoke, trace, lazy
└── estados/02/                 el laboratorio al cerrar este taller
```

## 4. 🔎 Recorrido de la base de código

Las rutas citan `laboratorio/estados/02/`.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿Quién convierte un error en `200`? | cada método de `legacy/src/main/java/dev/mono/legacy/controller/OrderController.java`: `catch (LegacyException e) { return Json.error(...) }`; y `config/SecurityConfig.java`, que escribe `{"error":"Not logged in"}` con estado `200` |
| ¿Qué pone la traza en el cuerpo? | `legacy/src/main/resources/application.yaml`: `spring.web.error.include-stacktrace: always` |
| ¿Por qué sale la contraseña? | `controller/OrderController.java` devuelve la entidad `Order`; `entity/Order.java` tiene `customer` como `@ManyToOne` hacia `User`, y `entity/User.java` expone `getPasswordHash()` |
| ¿Quién llena la caché de pedidos? | `service/DailyCloseJob.java`, fuera de cualquier petición; `service/OrderService.findEntity` la consulta antes que la base |
| ¿Qué cree el frontend? | `frontend/src/api.ts`: si `res.ok`, el cuerpo tiene la forma pedida; si no, el mensaje está en `message` |

La lectura clave es la de `api.ts`: el cliente no está mal escrito. Hace lo que haría cualquier
cliente HTTP razonable, y por eso cada accidente del servidor le llega intacto.

## 5. 🧨 Provocación: el `200` que esconde un error

```bash
python3 laboratorio/scripts/lab.py seed
python3 laboratorio/scripts/lab.py api POST /api/v1/orders '{"lines":[{"sku":"SKU-004","quantity":1}]}'
```

- `seed` deja `SKU-004` con stock `0`; el `POST` intenta comprarlo como `ana`.

```text
HTTP 200 · application/json · 8 ms
{
  "error": "Not enough stock for SKU-004"
}
```

El estado dice «todo bien» y el cuerpo dice lo contrario. El mensaje es texto libre en inglés,
escrito por quien programó `InventoryService`: si mañana alguien lo cambia a «Insufficient stock», un
cliente que lo compare deja de reconocerlo. No hay un código estable, ni un campo que diga qué
línea falló, ni una forma de distinguir «sin stock» de «pedido vacío» sin comparar cadenas.

## 6. 🧨 Provocación: el `500` que enseña la traza

```bash
python3 laboratorio/scripts/lab.py trace
```

- `trace` inicia sesión como `ana` y compra un `SKU-999`, que no existe. `lab.py` recorta la traza a
  cuatro líneas al mostrarla; el cuerpo real las trae todas.

```text
HTTP 500 · application/json · 7 ms
{
  "timestamp": "2026-09-29T20:43:06.489Z",
  "status": 500,
  "error": "Internal Server Error",
  "trace": [
    "java.lang.NullPointerException: Cannot invoke \"dev.mono.legacy.entity.Product.getStock()\" because \"p\" is null",
    "\tat dev.mono.legacy.service.InventoryService.take(InventoryService.java:26)",
    "\tat dev.mono.legacy.service.OrderService.create(OrderService.java:56)",
    "\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:104)",
    "… (103 líneas más de traza)"
  ],
  "message": "Cannot invoke \"dev.mono.legacy.entity.Product.getStock()\" because \"p\" is null",
  "path": "/api/v1/orders"
}
```

Un producto inexistente no es un error de negocio para el legado: nadie lo previó, así que llega
como `NullPointerException`. La respuesta publica la estructura de paquetes, los nombres de clase,
los números de línea, la versión del JDK y la cadena completa de filtros de seguridad —107 líneas—.
Para un atacante es un mapa; para el cliente, un `500` que no puede distinguir de una caída real.

El mismo pedido tiene dos respuestas según el SKU falle por stock o por no existir: `200` con
`error` o `500` con traza. El cliente tiene que manejar las dos, y ninguna está escrita.

## 7. 🧨 Provocación: la entidad sale entera

```bash
python3 laboratorio/scripts/lab.py api POST /api/v1/orders '{"lines":[{"sku":"SKU-002","quantity":1}]}'
```

- Una compra válida como `ana`; lo que importa es la forma de la respuesta.

```text
HTTP 200 · application/json · 16 ms
{
  "createdAt": "2026-09-29T20:45:17.891730Z",
  "currency": "USD",
  "customer": {
    "email": "ana@mono.local",
    "id": "11111111-1111-4111-8111-111111111111",
    "passwordHash": "$2y$10$Rdmvw5b4tBFmQ7.1vLA/p.Mg5xRLfiL2itgsZuNtaAZGv2IJxsQf6",
    "role": "customer"
  },
  "id": "60e72678-7561-4f38-9245-93d348bf5bd9",
  "lines": [
    {
      "id": 1,
      "productName": "USB-C cable",
      "quantity": 1,
      "sku": "SKU-002",
      "unitPrice": 9.9
    }
  ],
  "payments": [],
  "status": "CONFIRMED",
  "total": 9.9
}
```

Cada campo de las clases de `entity/` es ahora contrato: el hash de bcrypt, la clave interna de la
línea, la lista de pagos, el dinero como número. Si el equipo renombra `productName` en la base, el
JSON cambia. Si añade una columna sensible, sale sola. Y el orden alfabético de los campos no lo
eligió nadie: es el comportamiento por defecto de Jackson 3, que Spring Boot 4 trae.

`OrderLine.order` lleva `@JsonIgnore` y `User` lleva
`@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})`: son las dos marcas de alguien que
se topó con una recursión infinita y con un proxy de Hibernate que Jackson no sabía serializar, y
los tapó uno a uno. Son parches sobre la decisión de fondo —serializar entidades—, y los dos son
pistas para el recorrido del taller 04.

## 8. 🧨 Provocación: la excepción que aparece a ratos

```bash
python3 laboratorio/scripts/lab.py lazy
```

- `lazy` crea un pedido, lo pide una vez, espera a que el cierre diario escriba una fila nueva en
  `batch_runs` (hasta 40 s) y lo vuelve a pedir.

```text
pedido 8e7507b8-cf7f-4f08-8244-9a3c074d5835 creado; GET antes del cierre diario:
HTTP 200 · application/json · status=CONFIRMED
esperando al cierre diario (hasta 40 s: busca una fila nueva en batch_runs)…
GET después del cierre diario:
HTTP 500 · application/json · 7 ms
{
  "timestamp": "2026-09-29T20:33:19.109Z",
  "status": 500,
  "error": "Internal Server Error",
  "trace": [
    "org.springframework.http.converter.HttpMessageNotWritableException: Could not write JSON: Could not initialize proxy [dev.mono.legacy.entity.User#11111111-1111-4111-8111-111111111111] - no session",
    "\tat org.springframework.http.converter.AbstractJacksonHttpMessageConverter.writeInternal(AbstractJacksonHttpMessageConverter.java:444)",
    "\tat org.springframework.http.converter.AbstractSmartHttpMessageConverter.write(AbstractSmartHttpMessageConverter.java:116)",
    "\tat org.springframework.web.servlet.mvc.method.annotation.AbstractMessageConverterMethodProcessor.writeWithMessageConverters(AbstractMessageConverterMethodProcessor.java:342)",
    "… (117 líneas más de traza)"
  ],
  "message": "Could not write JSON: Could not initialize proxy [dev.mono.legacy.entity.User#11111111-1111-4111-8111-111111111111] - no session",
  "path": "/api/v1/orders/8e7507b8-cf7f-4f08-8244-9a3c074d5835"
}
```

La misma petición, dos respuestas, y la diferencia está en un estado que el cliente no ve:

```text
antes del cierre diario                      después del cierre diario
GET /orders/{id}                             GET /orders/{id}
  └─ caché vacía → findById en la petición     └─ caché: entidad cargada por el job, sin sesión
     open-in-view: sesión abierta hasta           customer es un proxy sin inicializar
     serializar → customer se carga               Jackson lo toca → no session → 500
```

`DailyCloseJob` carga los pedidos del día **fuera de cualquier petición**, los guarda en la caché y
termina: su sesión de Hibernate se cierra. Cuando una petición sirve la entidad desde la caché,
Jackson intenta leer `customer`, que es un proxy perezoso sin sesión que lo cargue. Antes del cierre
diario, en cambio, la entidad sale de la base dentro de la petición y *open-in-view* —activo por
defecto, con un aviso al arrancar— mantiene la sesión abierta hasta serializar. Para el cliente, el
mismo pedido responde `200` o `500` según la hora.

## 9. 🖥️ En el frontend

Sección opcional. El frontend es un cliente limpio: comprueba `res.ok`, confía en la forma de la
respuesta y muestra el `message` de los errores.

```bash
python3 laboratorio/scripts/lab.py frontend
```

- La primera vez instala las dependencias con `npm ci`, que respeta `package-lock.json` al pie de la
  letra; después arranca Vite en `:35173` en primer plano. El proxy de Vite reenvía `/api` y `/health`
  al legado, así que no hace falta configurar CORS.

Abre `http://localhost:35173`, entra como `ana` y prueba tres botones: «Comprar 1» en `SKU-004`,
«Comprar 1» en `SKU-999` y «Ver» en el pedido que no existe. La misma secuencia, sin navegador:

```bash
python3 laboratorio/scripts/lab.py front-smoke
```

- `front-smoke` ejecuta `frontend/scripts/smoke.ts` con Node 24, que corre TypeScript quitando los
  tipos. Usa el mismo `api.ts` y los mismos textos de `view.ts` que la interfaz.

```text
1. comprar SKU-002 (hay stock)
  la interfaz muestra: ✅ Pedido creado: 37c721fd-8292-45a5-a37d-ca8b97a69d17 (CONFIRMED)
2. comprar SKU-004 (sin stock)
  la interfaz muestra: ✅ Pedido creado: undefined (undefined)
3. comprar SKU-999 (no existe)
  la interfaz muestra: ❌ Error 500: Cannot invoke "dev.mono.legacy.entity.Product.getStock()" because "p" is null
4. ver un pedido que no existe
  la interfaz muestra: 💥 TypeError: Cannot read properties of undefined (reading 'map')
```

Y en el navegador, capturado con Chrome 154 en modo *headless*, dirigido por el protocolo de
DevTools sobre la interfaz real servida por Vite:

```text
comprar SKU-004 → ✅ Pedido creado: undefined (undefined)
comprar SKU-999 → ❌ Error 500: Cannot invoke "dev.mono.legacy.entity.Product.getStock()" because "p" is null
ver pedido inexistente → #root tiene 0 hijos; texto: ''
consola:
  [vite] connecting...
  %cDownload the React DevTools for a better development experience: https://react.dev/link/react-devtools font-weight:bold
  [vite] connected.
  EXCEPTION TypeError: Cannot read properties of undefined (reading 'map')
  %s
```

La última línea es el aviso de React sobre el error no capturado; el protocolo entrega su plantilla
de formato (`%s`) y no el texto ya formateado.

Tres fallos, uno por accidente:

- **El `200` con error se muestra como éxito.** `res.ok` es verdadero, así que el cliente cree que
  llegó un `Order`; `order.id` no existe y el usuario lee «Pedido creado: undefined».
- **El `500` le enseña Java al usuario.** El cliente muestra el `message`, como haría con cualquier
  error: el usuario ve el nombre de una clase interna y una `NullPointerException`.
- **El `200` con error deja la pantalla en blanco.** Al ver un pedido inexistente, el legado responde
  `200 {"error":"Order not found"}`; la interfaz lo guarda como pedido y, al pintar sus líneas,
  `order.lines.map` falla. Un error de renderizado que no atrapa ningún *error boundary* hace que
  React desmonte todo el árbol: `#root` queda vacío.

## 10. 🧪 Evidencia: lo que el cliente tiene que saber

| Accidente | Lo que ve el cliente | Lo que el cliente tiene que saber para sobrevivir |
|---|---|---|
| error de negocio | `200 {"error": "texto libre"}` | buscar `error` en todo `200` y comparar cadenas en inglés |
| fallo no previsto | `500` con `trace` y `message` | que `message` no es para el usuario; que un `500` puede ser un SKU inexistente |
| entidad serializada | el modelo JPA entero, dinero como número | qué campos ignorar, y que pueden aparecer nuevos sin aviso |
| caché y sesión | `200` o `500` según el cierre diario | reintentar a ciegas, sin saber por qué funciona |

Cada fila es conocimiento privado del servidor que el cliente ha tenido que aprender. Eso es el
acoplamiento que describe [`04/04`](../04-monolito-distribuido/04-contratos-fragiles-y-despliegues-coordinados.md):
el servidor ya no puede cambiar su implementación sin romper a quien aprendió sus accidentes. El
taller 04 lo corrige en un único manejador de errores y con DTO, y con eso rompe a este mismo
frontend.

## 11. 🩺 Errores reales al correrlo

### Node 24 no ejecuta *parameter properties* de TypeScript

**Síntoma.** `front-smoke` falló al cargar `api.ts`: `SyntaxError [ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX]:
TypeScript parameter property is not supported in strip-only mode`.

**Causa.** `constructor(public status: number, …)` genera código: no es un tipo que se pueda borrar.
Node ejecuta TypeScript quitando los tipos, sin transformar nada, así que rechaza esa sintaxis. Vite sí
la transforma, y por eso la interfaz funcionaba.

**Lección.** La clase declara el campo y lo asigna en el constructor, y `tsconfig.json` activa
`erasableSyntaxOnly`: con esa opción, `tsc` marca la misma sintaxis como error `TS1294` antes de que
Node la encuentre. Dos herramientas que «ejecutan TypeScript» no aceptan el mismo TypeScript.

### La traza no rompe `JSON.parse`; la pantalla en blanco viene del `200`

**Síntoma.** El plan del taller esperaba que la traza de un `500` rompiera el `JSON.parse` del
cliente y dejara la pantalla en blanco. No ocurrió: el `500` llegó como JSON válido.

**Causa.** Spring Boot responde el error como JSON cuando el cliente pide `application/json`, y la
traza viaja como una cadena dentro de ese JSON. Lo que sí deja la pantalla en blanco es el `200` con
error, que el cliente trata como un pedido válido hasta que intenta pintarlo.

**Lección.** El accidente peor no es el ruidoso, sino el que parece éxito. La ficha del taller se
ajustó a lo observado.

## 12. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía). El problema de este taller —la API que publica la
implementación— aparece igual en cualquier plataforma que serialice su modelo de persistencia: un
modelo de Django REST Framework sin serializador explícito, una entidad de TypeORM devuelta tal cual,
una estructura de GORM con todas sus etiquetas. El contraste entre mecanismos de visibilidad está en
[`02/02` — API pública del módulo](../02-modularidad-y-limites-internos/02-api-publica-del-modulo-y-encapsulacion-interna.md).

## 13. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py down
```

- `down` apaga PostgreSQL y Toxiproxy y borra sus volúmenes. El frontend, el legado y el
  `psp-simulator` se paran con Ctrl+C en sus terminales.

## ⚠️ Errores frecuentes

- «Devolver siempre `200` simplifica el cliente». Lo obliga a inspeccionar cada cuerpo y a conocer
  mensajes que nadie documentó.
- «La traza ayuda a depurar». Ayuda a quien depura el servidor, y se la entrega a todos los clientes.
  La traza va al log, con un identificador que la respuesta pueda citar.
- «Serializar la entidad ahorra un DTO». Ahorra una clase hoy y convierte el modelo de persistencia en
  contrato público para siempre.
- «La `LazyInitializationException` se arregla con `FetchType.EAGER`». Esconde el síntoma, carga más
  de lo necesario en cada consulta y deja el defecto real —servir entidades sin sesión desde una
  caché— donde estaba.
- «El frontend debería defenderse de todo». Un cliente que se defiende de todo es un cliente que
  conoce todos los accidentes del servidor: ese conocimiento es el acoplamiento.

## 📚 Referencias

- [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [Spring Boot: Open EntityManager in View](https://docs.spring.io/spring-boot/reference/data/sql.html#data.sql.jpa-and-spring-data.open-entity-manager-in-view)
- [React: capturar errores de renderizado con un error boundary](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary)
- [Node.js: módulos TypeScript y eliminación de tipos](https://nodejs.org/api/typescript.html)
- [TypeScript: `erasableSyntaxOnly`](https://www.typescriptlang.org/tsconfig/erasableSyntaxOnly.html)

## 🧠 Preguntas

1. ¿Por qué un `200` con `{"error"}` obliga al cliente a conocer detalles del servidor? 🟢
2. ¿Qué información entrega la traza del `500` y a quién le sirve? 🟢
3. ¿Qué campos de la respuesta de un pedido no deberían salir nunca, y por qué salen? 🟢
4. ¿Qué es *open-in-view* y qué papel juega en que el `GET` funcione antes del cierre diario? 🟢
5. ¿Por qué el mismo `GET /api/v1/orders/{id}` responde `200` o `500` según la hora? 🟡
6. ¿Por qué el frontend muestra «Pedido creado: undefined» y no un error? 🟡
7. ¿Por qué ver un pedido inexistente deja la pantalla en blanco? 🟡
8. ¿Qué dicen `@JsonIgnore` en `OrderLine.order` y `@JsonIgnoreProperties` en `User` sobre la historia del código? 🟡
9. ¿Por qué el orden alfabético de los campos del JSON es también parte del contrato accidental? 🟡
10. Un compañero propone `FetchType.EAGER` en `Order.customer` para quitar la excepción. ¿Qué arregla y qué no? 🟠
11. ¿Qué ocurrirá con este frontend cuando el taller 04 devuelva códigos de estado reales? 🟠
12. ¿Por qué el `500` de un SKU inexistente y el `200` de un SKU sin stock son un problema de contrato y no solo de código? 🟠
13. Diseña la migración de los clientes del legado a un contrato con errores reales sin romperlos a todos el mismo día. 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide que un usuario sin token
   recibe `200 {"error":"Not logged in"}`? Responde con rutas de `laboratorio/estados/02/`.
2. 🟢 Provoca un `400` enviando un cuerpo que no es JSON a `POST /api/v1/orders` con `curl`. Pega la
   respuesta y di qué campos revelan la implementación.
3. 🟡 Arranca el legado con `lab.py legacy --daily-close-ms 5000` y repite `lab.py lazy`. ¿Cuánto
   tarda ahora en aparecer el `500` y qué dice eso de un error «intermitente»?
4. 🟡 **Orientación en código ajeno.** ¿Qué línea de `OrderService` consulta la caché antes que la
   base, y qué línea de `DailyCloseJob` la llena? Explica por qué la entidad de la caché no tiene
   sesión.
5. 🟡 Añade a `frontend/src/view.ts` una comprobación que muestre «❌ No se pudo crear el pedido» si
   la respuesta trae `error`. Corre `front-smoke` y explica por qué el arreglo acopla más el cliente
   al servidor.
6. 🟠 Añade un *error boundary* a `App.tsx` y comprueba que ver un pedido inexistente ya no deja la
   pantalla en blanco. ¿Qué problema resuelve y cuál sigue ahí?
7. 🟠 Lista todos los mensajes de error distintos que puede devolver el legado buscando en el código,
   y agrupa los que un cliente debería distinguir. Es el borrador de los `code` del taller 04.
8. 🔥 Cambia `spring.web.error.include-stacktrace` a `never`, reinicia y repite `lab.py trace` y
   `front-smoke`. ¿Qué mejora, qué sigue viéndose y por qué no es la corrección del taller 04?

---

**Anterior:** [`01` — Heredar el legado](01-heredar-el-legado.md). **Siguiente:**
[`03` — Caracterización](03-caracterizacion.md).
