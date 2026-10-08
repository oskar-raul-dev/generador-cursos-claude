# 02 — Frontend mínimo en React

Este taller es **opcional**, incluso dentro del bloque 06: los cinco sabores se terminan con la
suite `hurl`, no con este frontend. Depende solo de `06/01`. Lo que aporta es la otra mitad de la
frontera: ver el frontend como un *driving adapter* más, con su propio puerto y dos
implementaciones —una que habla con un backend real y otra que no necesita ninguno— y comprobar
que la UI no distingue entre ambas.

> **Vigencia:** 2026-09-27. Versiones verificadas ese día en el registro de npm.

**Salto rápido:** [1](#1--el-problema) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--el-puerto-y-sus-dos-adaptadores) · [5](#5--el-mock-con-reglas-de-negocio) · [6](#6-️-la-ui) · [7](#7--correr) · [8](#8--errores-provocados-a-propósito) · [9](#9--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 El problema

Un frontend que "espera al backend" arranca tarde y se diseña contra lo que el backend acabó
devolviendo. Un frontend con `fetch` repartido por los componentes conoce rutas, cabeceras y
códigos en veinte sitios, y cambiar la URL base o probar una pantalla sin red exige tocar todos.
Es el mismo acoplamiento que el corpus describe para un controller que llama al repositorio: el
detalle (HTTP) dicta la política (qué muestra la pantalla).

```text
UI ─► OrdersApi (puerto) ◄─ HttpOrdersApi (fetch) ─► backend real :8081…:8085
                          ◄─ HttpOrdersApi + MSW  ─► reglas de negocio en memoria
```

El contrato de `06/01` es lo que hace posible el dibujo: el puerto del frontend se escribe desde
el contrato, no desde ningún backend, y el mock implementa el contrato, no un backend concreto.
El precio es un puerto más y un mock que hay que mantener en sintonía con el contrato; la
ganancia es que la UI se termina antes que cualquier sabor y sirve después para probar los cinco.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Node.js | 24 LTS (`v24.21.0` en la máquina de referencia) | Vite, Vitest |
| `react` / `react-dom` | `19.3.0` | la UI |
| `vite` / `@vitejs/plugin-react` | `8.3.1` / `6.1.1` | servidor de desarrollo y build |
| `typescript` | `6.0.3` | la baseline del corpus es TypeScript 6 |
| `msw` | `2.15.0` | mock en navegador (service worker) y en Node |
| `vitest` | `5.0.2` | pruebas del adaptador |

Todas van con versión exacta en `package.json`, sin `^` ni `~`. No hay router, gestor de estado ni
librería de componentes: el taller no los necesita y cada uno abriría un curso aparte.

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/frontend/
├── package.json · tsconfig.json · vite.config.ts · index.html
├── .env                     VITE_API_MODE=http  · VITE_API_BASE_URL=http://localhost:8081
├── .env.mock                VITE_API_MODE=mock  (lo carga `vite --mode mock`)
├── public/mockServiceWorker.js   generado por `npx msw init public/`
└── src/
    ├── main.tsx             composition root: decide modo y construye el adaptador
    ├── App.tsx              la UI, que solo conoce OrdersApi y los tipos del contrato
    ├── api/
    │   ├── types.ts         tipos del contrato, a mano
    │   ├── ordersApi.ts     el puerto OrdersApi y ApiError
    │   ├── httpOrdersApi.ts el adaptador fetch
    │   └── httpOrdersApi.test.ts   prueba del adaptador contra MSW en Node
    └── mock/
        ├── state.ts         semilla y reglas de juguete (dinero en centavos, PaymentGateway)
        ├── handlers.ts      un handler por operación del contrato
        └── browser.ts       setupWorker para el navegador
```

La misma dirección que en el backend: `App.tsx` importa `api/ordersApi.ts` (el puerto) y
`api/types.ts`; nunca `httpOrdersApi.ts` ni nada de `mock/`. Solo `main.tsx` conoce las
implementaciones.

## 4. 📐 El puerto y sus dos adaptadores

### El puerto se escribe desde el contrato

```typescript
export interface OrdersApi {
  login(email: string, password: string): Promise<TokenResponse>;
  logout(): Promise<void>;
  listProducts(cursor?: string): Promise<Page<Product>>;
  createOrder(lines: OrderLineRequest[], idempotencyKey: string): Promise<CreateOrderResult>;
  authorizePayment(orderId: string, idempotencyKey: string): Promise<PaymentResponse>;
  cancelOrder(orderId: string): Promise<Order>;
  // …getProduct, getOrder, listOrders, listNotifications
}
```

Dos decisiones que se ven en la firma:

- **La clave de idempotencia la pasa la UI**, no la genera el adaptador. Es una decisión de
  negocio del cliente —una clave por *intento de compra*, no por clic— y por eso está en el
  puerto. `App.tsx` la genera con `crypto.randomUUID()` al pulsar "Crear pedido".
- **`createOrder` devuelve `{ order, replayed }`**: la repetición idempotente (`200` con
  `Idempotent-Replay: true`) es parte del contrato y la UI la puede mostrar. Si el puerto devolviera
  solo `Order`, esa información se perdería en el adaptador.

Los errores cruzan el puerto como `ApiError`, con el `problem+json` entero y el `status`. La UI
decide por `problem.code`, nunca por `title` ni `detail`, que son texto para humanos.

### El adaptador `fetch` conoce HTTP y nada más

`HttpOrdersApi` traduce cada método del puerto a método, ruta, cabeceras y cuerpo; guarda el
token tras `login` y lo olvida tras `logout` o cuando recibe `UNAUTHENTICATED`/`TOKEN_REVOKED`;
convierte cualquier respuesta no `2xx` en `ApiError` leyendo el `problem+json` (y fabrica uno con
`INTERNAL_ERROR` si el cuerpo no lo es, para que la UI siempre tenga un `code`). Recibe la URL base
por constructor: **la única configuración**.

Lo que no hace: no reintenta, no cachea, no conoce React. Un reintento de `createOrder` con la
misma clave sería correcto por contrato, pero es una política del cliente y va donde se decida
la política, no en el transporte.

### El segundo adaptador no es una clase: es MSW delante del mismo `fetch`

En modo mock no hay un `MockOrdersApi`. `HttpOrdersApi` es exactamente el mismo; MSW registra un
service worker que intercepta `fetch` en el navegador (o parchea los módulos de red en Node) y
responde según `mock/handlers.ts`. Eso tiene una consecuencia que vale la pena decir en una
entrevista: **el adaptador HTTP real se ejercita en modo mock**, incluidas las cabeceras, el
`problem+json` y el `Idempotent-Replay`. Un `MockOrdersApi` que devolviera objetos directamente no
probaría nada del adaptador.

## 5. 🧩 El mock con reglas de negocio

`mock/handlers.ts` tiene un handler por operación del contrato y un estado en memoria con la
semilla de §11 de la guía: los dos usuarios, los cinco productos, el inventario. Implementa las
reglas que el mock de Prism no puede: contraseñas, stock, reserva atómica, clave de idempotencia
por actor, máquina de estados del pedido, `PaymentGateway` determinista, notificación al cancelar,
`404` para el pedido ajeno.

```typescript
// La regla determinista del PaymentGateway (§11 de la guía)
export function decidePayment(totalCents: number): Payment["status"] {
  if (totalCents > 100_000) return "REJECTED";
  if (totalCents === 66_600) return "PENDING";
  return "AUTHORIZED";
}
```

Es un backend de juguete **sin arquitectura**, y eso es deliberado: sesenta líneas de reglas
mezcladas con parsing de cabeceras, en un solo archivo. El ejercicio 8 de `06/01` proponía
escribirlo para "sentir cuánto de la suite es negocio"; aquí está escrito, y compararlo con el
taller 06 (FastAPI) o 04 (NestJS) cuando existan es el contraste entre el mismo comportamiento con y
sin dirección de dependencias.

📝 El dinero se maneja en centavos enteros incluso en el mock (`toCents`, `money`): la regla
"nunca `double`" del contrato no tiene excepciones por ser JavaScript.

## 6. 🖥️ La UI

`App.tsx` es una sola pantalla con un flujo completo: login → catálogo con carrito → crear pedido
→ detalle con "Pagar" y "Cancelar" → notificaciones si el actor es `operator` → logout. Sin
router, sin gestor de estado: `useState` y una función `run` por la que pasa toda llamada al puerto
y que convierte `ApiError` en un banner con `code`, `status`, `detail` y los `errors` por campo.

```typescript
const run = useCallback(async (action: () => Promise<void>) => {
  setError(null);
  try { await action(); }
  catch (e) {
    if (e instanceof ApiError) setError(e);
    else setMessage(`Fallo inesperado: ${(e as Error).message}`);
  }
}, []);
```

Es el equivalente en el frontend del traductor central de errores de un controller: un solo sitio
donde el error propio se convierte en presentación. La UI no sabe qué es un `409`; sabe que
`INSUFFICIENT_INVENTORY` es un mensaje que mostrar.

`main.tsx` es el composition root: lee `VITE_API_MODE` y `VITE_API_BASE_URL`, arranca el worker de
MSW si el modo es `mock`, construye `HttpOrdersApi(baseUrl)` y se lo pasa a `App` por props. Es el
único archivo que importa una implementación.

## 7. 🔁 Correr

```text
python3 06-talleres/laboratorio/scripts/lab.py front --test
python3 06-talleres/laboratorio/scripts/lab.py front --mock
python3 06-talleres/laboratorio/scripts/lab.py front --base-url http://localhost:8081
```

- `front` instala las dependencias la primera vez (`npm install --no-fund --no-audit`: sin
  mensajes de patrocinio ni auditoría, que aquí solo hacen ruido). Resuelve `npm` con
  `shutil.which`, que en Windows encuentra `npm.cmd`.
- `--test` corre `npm test` → `vitest run`: las pruebas del adaptador contra MSW en Node, sin
  navegador ni backend.
- `--mock` corre `vite --mode mock`, que carga `.env.mock` y arranca el servidor de desarrollo en
  `http://localhost:5173` con MSW delante de `fetch`. No hace falta Docker.
- `--base-url` corre `vite` contra un backend real; la URL se inyecta como `VITE_API_BASE_URL`.
  Hasta que exista un sabor, esta orden termina en un fallo de conexión en el navegador: no hay
  nadie escuchando en `8081`, y el banner lo dice como "Fallo inesperado".

Salida literal de las pruebas el 2026-09-27:

```text
$ npx vitest run --reporter=verbose
 RUN  v5.0.2 frontend
 ✓ src/api/httpOrdersApi.test.ts > autenticación > login devuelve un bearer y lo usa en las siguientes peticiones 13ms
 ✓ src/api/httpOrdersApi.test.ts > autenticación > credenciales inválidas → ApiError 401 INVALID_CREDENTIALS 1ms
 ✓ src/api/httpOrdersApi.test.ts > autenticación > sin token → UNAUTHENTICATED; tras logout → TOKEN_REVOKED 2ms
 ✓ src/api/httpOrdersApi.test.ts > pedidos > crea un pedido, descuenta stock y repite idempotentemente con la misma clave 5ms
 ✓ src/api/httpOrdersApi.test.ts > pedidos > misma clave con otro cuerpo → 422 IDEMPOTENCY_KEY_REUSED 1ms
 ✓ src/api/httpOrdersApi.test.ts > pedidos > inventario insuficiente → 409 con detalle y errors; no reserva nada 1ms
 ✓ src/api/httpOrdersApi.test.ts > pedidos > el pedido de otro cliente responde 404, no 403 2ms
 ✓ src/api/httpOrdersApi.test.ts > pagos y cancelación > autorizado, rechazado y pendiente según el importe 3ms
 ✓ src/api/httpOrdersApi.test.ts > pagos y cancelación > cancelar libera stock, es idempotente y no aplica a un pedido pagado 4ms
 ✓ src/api/httpOrdersApi.test.ts > pagos y cancelación > la cancelación deja una notificación que solo el operator lee 3ms
 Test Files  1 passed (1)
      Tests  10 passed (10)
   Duration  262ms (import 57%, transform 21%, tests 20%, worker 1%)
```

- `--reporter=verbose` lista cada prueba; el `npm test` normal solo da el resumen.
- Las diez pruebas son las mismas situaciones que la suite `hurl` de `06/01`, vistas desde el
  cliente: son la evidencia de que **el adaptador traduce el contrato**, no de que el mock tenga
  razón. Si un sabor pasa la suite y la UI falla contra él, el defecto está en el adaptador o en
  la UI, no en el backend.

`typecheck` (`tsc --noEmit`) y `build` (`vite build`) también pasan; `build` deja `dist/` con un
`index.html`, un CSS y un JS de 226 kB (71 kB comprimido), más el `mockServiceWorker.js`, que en
producción sobraría.

🧠 Lo que no se muestra aquí es una captura del navegador. La prueba manual es: `front --mock`,
abrir `http://localhost:5173`, entrar como `ana@hex.local` / `ana-12345`, añadir `SKU-004` al
carrito y crear el pedido: el banner debe decir `INSUFFICIENT_INVENTORY (409) SKU-004: requested
1, available 0`. Después, tres `SKU-003` y "Pagar": `PAYMENT_PENDING`. Cuando exista el sabor Java,
la misma secuencia con `--base-url http://localhost:8081` debe verse igual.

## 8. 🩺 Errores provocados a propósito

### El tipo que MSW no acepta

La primera versión de `handlers.ts` guardaba la respuesta idempotente como `unknown` y la
devolvía tal cual:

```text
$ npm run typecheck
src/mock/handlers.ts(58,28): error TS2345: Argument of type 'unknown' is not assignable to parameter of type 'JsonBodyType'.
```

`HttpResponse.json` exige un cuerpo serializable (`JsonBodyType`); `unknown` no lo es para el
compilador aunque en runtime lo fuera —las diez pruebas pasaban con el error de tipos presente,
porque Vitest transpila sin comprobar tipos—. La corrección fue tipar el cuerpo guardado
(`saved.body as Record<string, unknown>`). La lección no es de MSW: es que **`npm test` en verde no
significa que el proyecto compile**, y por eso `build` empieza por `tsc --noEmit`.

### `VITE_API_MODE=mock vite` no existe en Windows

La primera versión del script `dev:mock` era `VITE_API_MODE=mock vite`. Funciona en macOS y Linux
y falla en `cmd.exe` y PowerShell, donde `VAR=valor comando` no es sintaxis. La forma portable es
`vite --mode mock` con un archivo `.env.mock`: Vite carga `.env.<modo>` y expone sus `VITE_*` en
`import.meta.env`. Es la misma regla que llevó a escribir `lab.py` en Python: lo que depende del
shell no es multi-OS.

## 9. 🧹 Teardown

El servidor de desarrollo se para con `Ctrl+C`; no hay contenedores. `node_modules/` y `dist/`
están en `.gitignore`. Si se quiere dejar el directorio como recién clonado, se borran esos dos y
`front` vuelve a instalar la próxima vez.

## ⚠️ Errores frecuentes

- "Un mock del frontend es un objeto que devuelve datos." Si no pasa por `fetch`, el adaptador
  real queda sin probar. MSW existe para interceptar la red, no para sustituirla.
- "La clave de idempotencia la genera el cliente HTTP." Es una decisión de negocio del cliente
  (un intento, una clave) y pertenece al puerto.
- "TypeScript ya validó la respuesta." Los tipos de `api/types.ts` son una promesa del contrato,
  no una comprobación en runtime. Un backend que devuelva `amount: 49.9` como número compila igual
  y rompe en producción; la suite `hurl` es la que lo detecta.
- "Las pruebas pasan, así que compila." Vitest transpila sin comprobar tipos.
- "El frontend necesita el backend para existir." Necesita el contrato.

## ✅ Veredicto

El frontend es un adaptador de entrada con su propio puerto, y ese puerto se escribe desde el
contrato. Con MSW delante de `fetch`, el adaptador HTTP real se ejercita sin backend y la UI se
termina antes que cualquier sabor. Lo que cuesta —un puerto, un mock con reglas, dos modos— es lo
que permite que la misma UI pruebe cinco backends cambiando una variable.

## 📚 Referencias

- [MSW: quick start](https://mswjs.io/docs/quick-start) · [integración en Node](https://mswjs.io/docs/integrations/node) · [integración en navegador](https://mswjs.io/docs/integrations/browser)
- [Vite: variables de entorno y modos](https://vite.dev/guide/env-and-mode) · [opciones del servidor](https://vite.dev/config/server-options)
- [Vitest: guía](https://vitest.dev/guide/)
- [React: `useCallback`](https://react.dev/reference/react/useCallback)
- [MDN: `crypto.randomUUID()`](https://developer.mozilla.org/en-US/docs/Web/API/Crypto/randomUUID) · [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS)

## 🧠 Preguntas

1. 🟢 ¿Qué es `OrdersApi` en términos del corpus y quién lo define?
2. 🟢 ¿Qué archivo es el composition root del frontend y qué decide?
3. 🟢 ¿Por qué `App.tsx` no importa `httpOrdersApi.ts`?
4. 🟢 ¿Qué diferencia hay entre el mock de Prism de `06/01` y el mock MSW de este taller?
5. 🟢 ¿Por qué la clave de idempotencia está en la firma del puerto?
6. 🟡 ¿Por qué en modo mock no existe una clase `MockOrdersApi`?
7. 🟡 ¿Qué prueba `httpOrdersApi.test.ts` y qué no prueba?
8. 🟡 ¿Por qué `createOrder` devuelve `{ order, replayed }` y no solo `Order`?
9. 🟡 ¿Qué hace `run` en `App.tsx` y con qué pieza del backend se corresponde?
10. 🟡 ¿Por qué las diez pruebas pasaban con un error de tipos en `handlers.ts`?
11. 🟠 Un backend devuelve `amount` como número. Ni `tsc` ni las pruebas lo detectan. ¿Qué lo detecta y por qué es correcto que sea así?
12. 🟠 El equipo quiere que el adaptador reintente `createOrder` automáticamente tras un timeout. ¿Es correcto por contrato? ¿Dónde pondrías la decisión?
13. 🟠 `VITE_API_MODE=mock vite` funcionaba en tu máquina. ¿Por qué se cambió y qué regla general del bloque aplica?
14. 🟠 ¿Qué habría que cambiar en el frontend para que el sabor Java y el sabor Go se usen alternadamente durante una demo? Defiende que sea solo eso.

## 🧪 Ejercicios

1. 🟢 Corre `front --mock`, entra como `ana`, añade `SKU-004` al carrito y crea el pedido. Anota
   qué muestra el banner y en qué archivo se decidió cada palabra que ves.
2. 🟢 Entra como `ops@hex.local`, cancela un pedido de `ana` (créalo antes con `ana`) y carga las
   notificaciones. Explica por qué `ops` puede cancelar un pedido ajeno y `ana` no puede leer
   notificaciones.
3. 🟡 Añade a `httpOrdersApi.test.ts` una prueba de que `logout` con el token ya revocado produce
   `ApiError 401` y que el adaptador no vuelve a enviar `Authorization` después.
4. 🟡 Haz que el banner de error muestre un texto en español por cada `ProblemCode`, con un mapa
   `code → mensaje` en un solo archivo. Explica por qué ese mapa vive en la UI y no en el adaptador.
5. 🟠 Añade paginación real al catálogo: un botón "Más" que use `nextCursor`. El mock ya pagina;
   comprueba con `limit=2` y describe qué tuvo que cambiar en el puerto (nada) y en la UI.
6. 🟠 Escribe una segunda implementación del puerto, `InMemoryOrdersApi`, sin `fetch` ni MSW, y
   úsala en una prueba de `App.tsx` con `@testing-library/react`. Compara qué cubre esa prueba
   frente a la de `httpOrdersApi.test.ts` y cuándo elegirías cada una.
7. 🔴 El contrato añade `GET /api/v1/orders/{orderId}/payment` para consultar al proveedor cuando
   el pedido está `PAYMENT_PENDING`. Extiende puerto, adaptador, mock y UI, y decide qué debe
   pasar en la UI si la consulta también devuelve pendiente. Documenta qué parte del cambio es
   contrato y qué parte es política del cliente.
8. 🔥 Sustituye el `useState` de `App.tsx` por un `useReducer` con acciones por intención
   (`ORDER_CREATED`, `PAYMENT_RESOLVED`, …) sin cambiar el puerto ni las pruebas. Argumenta si el
   reducer es "dominio" del frontend o solo presentación.

---

**Siguiente:** el sabor que quieras, empezando por [03 — Java y Spring Boot](03-caso-java-spring-boot.md).
