# 02 — Cadenas síncronas y acoplamiento temporal

Aprenderás a decidir cuándo una colaboración síncrona entre componentes es razonable y cuándo
convierte el flujo en una unidad de fallo: cómo se componen disponibilidad y latencia en una cadena,
cómo se reparte un presupuesto de tiempo y qué alternativas quitan saltos sin fingir
desacoplamiento.

## 1. 🎯 Síntoma y decisión

Checkout atraviesa cinco componentes en línea: la pasarela llama a `orders`, y `orders` llama uno
tras otro a `inventory`, `payments` y `notifications` antes de responder. Cada componente cumple su
99,9 % mensual, pero checkout se queda en 99,4 %. Un martes, el proveedor de pagos se degrada y el
p99 de `payments` pasa de 300 ms a 4 s. Checkout falla por completo y, como los hilos de `orders`
quedan esperando, también se degrada el historial de pedidos, que no llama a `payments`. Cada
cliente HTTP tiene un timeout por defecto de cinco segundos y tres reintentos.

La cadena es más larga que la garantía que necesita, y nadie reparte el tiempo. La decisión de este
capítulo es qué llamadas deben seguir siendo síncronas, con qué presupuesto, y qué alternativa
corresponde a las demás.

## 2. 🧠 Modelo mental

```text
pasarela ─► orders ─┬─► inventory       obligatorio: sin stock no hay confirmación
                    ├─► payments        obligatorio hoy; podría quedar pendiente
                    └─► notifications   obligatorio solo porque está en la cadena
cinco componentes al 99,9 %, todos obligatorios:
0,999⁵ ≈ 99,5 % con fallos independientes; medido: 99,4 %
```

Una llamada síncrona obligatoria es **acoplamiento temporal**: si el otro no está disponible ahora,
tú tampoco. Es el precio correcto cuando el cliente necesita la respuesta para que la promesa se
cumpla —no confirmar sin stock—. Es un precio sin compra cuando la respuesta no cambia lo que se le
dice al cliente, como el aviso por correo. Y los mecanismos de resiliencia mal coordinados lo
empeoran: timeouts que no saben cuánto le queda a la petición y reintentos en cada capa multiplican
la carga sobre la dependencia que ya está peor.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | checkout en 99,4 % con componentes al 99,9 %; con `payments` degradado, el 100 % de checkout falla y el historial de pedidos también se degrada; `notifications` está en el camino síncrono aunque su resultado no cambia la respuesta; timeouts de cinco segundos y tres reintentos en cada cliente |
| Inferencia | la cadena incluye saltos que no aportan garantía, y ningún presupuesto limita la espera total |
| Diagnóstico | acoplamiento temporal innecesario en `notifications`, amplificación por reintentos y timeouts no coordinados, y recursos de `orders` compartidos entre flujos |
| Recomendación | deadline nacido en el borde y propagado, reintentos en una sola capa, `notifications` fuera del camino síncrono y `payments` con estado pendiente cuando el negocio lo acepte |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si la caída de checkout
viniera de la base compartida y no de la espera a `payments`, recortar la cadena no ayudaría. La
traza de una petición fallida durante el incidente distingue un caso del otro.

## 4. 🛠️ Presupuesto extremo a extremo

Con dependencias independientes, la disponibilidad del flujo no supera el producto de las partes
obligatorias. Cinco componentes al 99,9 % no convierten automáticamente el checkout en 99,9 %; bajo
el supuesto simplificado de fallos independientes, la cadena ronda 99,5 %. Con fallos correlacionados, el producto deja de ser una estimación válida; mide disponibilidad
del flujo completo. Tampoco sumes los p95 de cada salto para obtener el p95 del checkout.

El deadline nace en el borde y disminuye al avanzar. Cada salto reserva margen para serialización,
cola y respuesta; crear un timeout nuevo de cinco segundos en cada cliente destruye el presupuesto.
Cancelar libera trabajo solo si cada dependencia propaga y respeta la señal.

```text
cliente 900 ms
└─ orders 800 ms restantes
   ├─ inventory 180 ms, obligatorio
   ├─ payments 420 ms, obligatorio
   └─ notifications: después de responder
```

Un retry consume tiempo y carga. Se hace en una sola capa, para errores transitorios, con backoff,
jitter e idempotencia. Si la dependencia ya está saturada, reintentar en gateway, servicio y cliente
crea una tormenta. Reducir una API *chatty*, agregar localmente o mantener una proyección de lectura
puede eliminar saltos. Mensajería solo aplica si el negocio acepta respuesta diferida; si no, cambiar
HTTP por una espera sobre cola conserva el acoplamiento temporal con más piezas.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | cliente con deadline y propagación de contexto | la anotación de retry no crea presupuesto | timeout por defecto infinito |
| Node/TypeScript | `AbortSignal` y deadline explícito | promesas no cancelan dependencias solas | reintentar en cada capa |
| Go | `context` con deadline propagado | un contexto nuevo puede perder el budget | ignorar `ctx.Done` |
| Python | timeout del cliente y contexto correlacionado | timeout de socket no cubre toda la operación | sumar reintentos ocultos |

Las cuatro trampas son la misma en distinto idioma: una espera que no sabe cuánto le queda a la
petición. Un timeout infinito, una promesa que nadie cancela, un `context` nuevo que borra el
deadline o un reintento oculto en el cliente rompen el presupuesto desde dentro. El mecanismo
correcto existe en las cuatro plataformas; lo que suele faltar es la decisión de propagarlo desde el
borde.

## 6. ⚖️ Decisión y coste

Asigna un presupuesto extremo a extremo y conserva la espera síncrona solo donde la respuesta inmediata sea necesaria. Diferir avisos paga cola y recuperación; duplicar lecturas paga frescura y reconciliación; fusionar componentes paga despliegue y fallo compartidos. Compara esas opciones con latencia y disponibilidad del checkout. Detente cuando el flujo cumpla su SLO y los fallos tengan una salida definida.

## ⚠️ Errores frecuentes

- «REST desacopla». Una llamada síncrona obligatoria acopla en runtime: si el otro no responde, tú tampoco.
- «Reemplazar las llamadas por mensajes siempre mejora la resiliencia». Si quien llama espera la respuesta en otra cola, conserva el acoplamiento temporal con más piezas.
- «Cada cliente con su timeout de cinco segundos está protegido». Cinco segundos por salto en una cadena de cuatro superan cualquier presupuesto del usuario.
- «Reintentar en todas las capas aumenta la probabilidad de éxito». Multiplica la carga sobre la dependencia que ya está peor.
- «El p95 del flujo es la suma de los p95 de sus saltos». Los percentiles no se suman; se mide el flujo completo.

## 7. ✅ Veredicto

Mantén síncrono solo lo que el cliente necesita saber antes de recibir la respuesta, y dale a esa
cadena un presupuesto que nace en el borde y se reparte. Todo lo demás —avisos, proyecciones,
efectos que pueden llegar después— sale del camino síncrono. Reintenta en una sola capa, con límite
y jitter. Si dos componentes se llaman siempre en ambos sentidos, compara fusionarlos antes de
añadir más mecanismos de resiliencia.

## 📚 Referencias

- [AWS: Retry with backoff](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html)
- [Marc Brooker: Exponential Backoff and Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
- [Google SRE: Handling Overload](https://sre.google/sre-book/handling-overload/)
- [gRPC Deadlines](https://grpc.io/docs/guides/deadlines/)

## 🧠 Preguntas

1. 🟢 ¿Qué es el acoplamiento temporal?
2. 🟢 ¿Cómo se compone la disponibilidad de una cadena de dependencias obligatorias?
3. 🟢 ¿Qué es un presupuesto de tiempo que nace en el borde?
4. 🟢 ¿Qué es una API *chatty* y por qué alarga la cadena?
5. 🟢 ¿Qué es una tormenta de reintentos?
6. 🟢 ¿Qué criterio decide si una llamada debe ser síncrona?
7. 🟡 ¿Por qué sustituir toda llamada por mensajes es una simplificación peligrosa?
8. 🟡 ¿Cuándo elegirías fusionar dos componentes o duplicar datos de lectura antes que mejorar la resiliencia de la llamada?
9. 🟡 ¿Qué supuestos esconde la estimación 0,999⁵ ≈ 99,5 % para checkout?
10. 🟡 ¿Por qué no se suman los p95 de cada salto para obtener el p95 del flujo?
11. 🟡 ¿Cuántas llamadas puede recibir `payments` por una sola petición si tres capas hacen hasta cuatro intentos cada una?
12. 🟡 ¿Por qué `notifications` no debería estar en el camino síncrono de checkout?
13. 🟡 ¿Qué garantía justifica que `inventory` sí esté en el camino síncrono?
14. 🟡 ¿Cómo degrada un componente lento a funciones que no dependen de él?
15. 🟡 ¿Qué aporta un circuit breaker y qué no?
16. 🟡 ¿Qué pasa con el trabajo aguas abajo cuando el cliente abandona y nadie propaga la cancelación?
17. 🟡 ¿Cómo deben representar el mismo deadline un cliente Java y un `context.Context` de Go?
18. 🟠 ¿Qué problema comparten reintentos ocultos en clientes Node/TypeScript y Python?
19. 🟠 `payments` pasa de 300 ms a 4 s en el p99 y checkout cae por completo. ¿Qué harías en la primera hora?
20. 🟠 Negocio exige confirmación de pago en la misma respuesta de checkout. ¿Cómo lo mantienes síncrono sin que un proveedor lento tumbe todo?
21. 🟠 Una página de producto llama a `inventory` 40 veces para mostrar disponibilidad. ¿Qué propondrías?
22. 🟠 Quieres sacar `notifications` del camino síncrono. ¿Qué pasos reversibles darías?
23. 🟠 Un equipo quiere un service mesh con reintentos automáticos y otro quiere recortar la cadena. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que la cadena ya es proporcional y no hay que recortarla más?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [01 — Anatomía y evidencia del monolito distribuido](01-anatomia-y-evidencia-del-monolito-distribuido.md).

**Siguiente:** [03 — Base compartida, escrituras cruzadas y propiedad difusa](03-base-compartida-escrituras-cruzadas-y-propiedad-difusa.md).
