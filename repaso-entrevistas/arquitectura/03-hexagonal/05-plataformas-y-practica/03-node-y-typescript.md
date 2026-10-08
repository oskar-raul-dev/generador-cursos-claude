# 03 — Node y TypeScript

Este capítulo enseña a aprovechar módulos, tipos y asincronía de Node sin confundir tipos borrados con validación, providers con puertos ni promesas con entrega garantizada.

## 1. 🎯 El problema

Un controller declara `body: CreateOrderDto`, hace un cast del JSON y pasa un cliente Prisma a `CreateOrder`. La interfaz compila, pero un campo ausente llega como `undefined`; un retry lanza otra promesa después de que la petición fue cancelada. TypeScript describió el código, no validó el mundo exterior ni controló su ciclo de vida.

## 2. 🧭 Tipos estáticos y datos runtime

Las `interface` y muchos tipos de TypeScript se eliminan al generar JavaScript. Por eso el borde valida JSON con un schema o pipe real antes de construir un comando propio. NestJS puede usar pipes; Fastify puede asociar JSON Schema a la ruta. El núcleo recibe `CreateOrderCommand`, no `Request`, decorators ni objetos del ORM.

```text
JSON desconocido ─► schema/pipeline ─► DTO válido ─► comando ─► CreateOrder
                                                        │
                                              puerto ─► adapter
```

Un cast `as CreateOrderDto` no inspecciona el dato. `strict` mejora el análisis del programa, pero tampoco valida payloads, variables de entorno o respuestas remotas.

## 3. 🔄 Providers, tokens y asincronía

Una interfaz no existe en runtime, así que NestJS necesita un token estable:

```typescript
export const ORDERS = Symbol('ORDERS');

@Module({
  providers: [
    { provide: ORDERS, useFactory: (db: PrismaClient) => new PrismaOrders(db),
      inject: [PrismaClient] },
    { provide: CreateOrder,
      useFactory: (orders: Orders) => new CreateOrder(orders),
      inject: [ORDERS] },
  ],
})
export class OrdersModule {}
```

El token resuelve composición; no convierte a `PrismaOrders` en buen puerto. En Fastify o Node puro, una función `buildApp(deps)` puede ser suficiente y más visible.

Toda promesa debe tener dueño. Propaga cancelación y deadline a clientes remotos mediante `AbortSignal`; espera publicación y cierre antes de confirmar el resultado. `AsyncLocalStorage` puede mantener correlación entre callbacks, pero no debería ser la fuente oculta de actor, permiso o transacción. Esas decisiones se pasan explícitamente cuando afectan política.

## 4. 🧩 Transacción, errores y pruebas

El cliente transaccional concreto queda en el adaptador o en una unidad de trabajo de aplicación. Todas las operaciones de una unidad deben usar el mismo `tx`; abrir una segunda llamada con el cliente raíz rompe atomicidad. Traduce errores Prisma, HTTP o broker a resultados propios una vez. No captures todo para devolver `InternalError`: conserva causas para logs y distingue conflicto, ausencia, indisponibilidad e incertidumbre.

Prueba dominio y casos de uso con `node:test` o el runner elegido sin levantar Nest. Para HTTP, construye la app con dobles controlados y ejecuta una petición real; Fastify ofrece `inject`, mientras Nest permite módulos de prueba. El adaptador Prisma necesita una base compatible y el wiring necesita una prueba de arranque.

## 5. 🧰 Contraste de plataforma

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | tipos runtime, beans y proxies | controlar anotaciones y límites | asumir que DI garantiza dirección |
| Node/TS | tipos estructurales, módulos y async runtime | validación, tokens, cancelación y ownership | confiar en tipos borrados o promesas sueltas |
| Go | interfaces runtime y contexto explícito | wiring y errores como valores | propagar detalles técnicos sin traducir |
| Python | anotaciones, validadores y async | decidir qué se valida y dónde | creer que type hints validan entradas solos |

## 6. ⚖️ NestJS, Fastify o composición directa

NestJS compensa con módulos, providers, pipes y convenciones cuando el equipo necesita un framework integrado. Fastify deja más visible el ensamblaje y ofrece un servidor pequeño con schemas. Node puro puede bastar para un worker o CLI. La elección cambia ceremonia, no la regla: el núcleo no debe importar el framework. Evalúa además ESM/CommonJS, runner, scopes y cierre de recursos; son costes operativos reales.

## ⚠️ Errores frecuentes

- “La interfaz valida el JSON.” Desaparece al ejecutar.
- “Un token de NestJS es el puerto.” Solo identifica un provider en el contenedor.
- “Una promesa lanzada terminará antes de responder.” Puede fallar o quedar huérfana.
- “`AsyncLocalStorage` sirve para cualquier contexto.” No reemplaza datos explícitos de autorización.
- “Prisma genera tipos, así que su modelo es el dominio.” Sus tipos siguen el esquema y el cliente.

## 7. ✅ Veredicto

Valida datos en runtime, usa tokens solo en composición y controla cada promesa, transacción y recurso. TypeScript ayuda a expresar el puerto; la frontera se demuestra con validación, imports y pruebas reales.

## 📚 Referencias

- [TypeScript 6.0](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html)
- [NestJS: custom providers](https://docs.nestjs.com/fundamentals/custom-providers)
- [NestJS: validation](https://docs.nestjs.com/techniques/validation)
- [Node.js: AsyncLocalStorage](https://nodejs.org/api/async_context.html)
- [Node.js: test runner](https://nodejs.org/api/test.html)
- [Fastify: testing](https://fastify.dev/docs/latest/Guides/Testing/)

## 🧠 Preguntas

1. 🟢 ¿Qué ocurre con una `interface` TypeScript en runtime?
2. 🟢 ¿Qué hace un pipe o schema de entrada?
3. 🟢 ¿Para qué sirve un token de provider?
4. 🟢 ¿Qué debe recibir `CreateOrder` en vez de `Request`?
5. 🟢 ¿Qué significa que una promesa tenga dueño?
6. 🟢 ¿Para qué sirve `AbortSignal`?
7. 🟡 ¿Por qué `as CreateOrderDto` no valida JSON?
8. 🟡 ¿Cuándo usarías un `Symbol` como token?
9. 🟡 ¿Qué diferencia hay entre módulo NestJS y límite arquitectónico?
10. 🟡 ¿Cuándo preferirías `buildApp(deps)` a un contenedor?
11. 🟡 ¿Por qué no usarías `AsyncLocalStorage` como fuente de autorización?
12. 🟡 ¿Cómo mantienes una transacción Prisma entre dos adapters?
13. 🟡 ¿Qué error externo debe traducir el adapter?
14. 🟡 ¿Qué prueba haces sin levantar NestJS?
15. 🟡 ¿Qué comprueba `fastify.inject()`?
16. 🟡 ¿Qué coste debes evaluar al elegir ESM o CommonJS?
17. 🟠 El body está tipado pero llega `customerId: null`. ¿Dónde falló la frontera?
18. 🟠 NestJS no puede resolver una interfaz inyectada. ¿Qué agregas y dónde?
19. 🟠 El caso de uso llama Prisma con el cliente raíz dentro de un callback transaccional. ¿Qué riesgo hay?
20. 🟠 Un handler responde y deja `publish()` sin `await`. ¿Qué puede ocurrir?
21. 🟠 Un error `PrismaClientKnownRequestError` llega al controller. ¿Qué cambias?
22. 🟠 Un singleton guarda actor y request actual. ¿Qué fallo de concurrencia esperas?
23. 🟠 Todos los tests mockean Prisma y una constraint falla en producción. ¿Qué prueba agregas?
24. 🟠 ¿Cuándo NestJS añadiría más ceremonia que valor?

**Siguiente:** [Go](04-go.md).
