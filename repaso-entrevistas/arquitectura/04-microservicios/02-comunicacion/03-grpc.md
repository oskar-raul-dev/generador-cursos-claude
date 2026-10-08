# 03 — gRPC

> Qué es gRPC de verdad —un contrato compilado sobre HTTP/2—, sus cuatro modos, los deadlines que se
> propagan, y por qué el balanceo es su problema operativo característico. Asume leído
> [`02`](02-http-entre-servicios.md); la comparación con HTTP y el criterio de elección están en
> [`04`](04-http-contra-grpc.md), que es su continuación natural.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

`orders` llama a `inventory` por HTTP con JSON. Funciona, pero hay tres cosas que nadie ha
resuelto y que aparecen cuando el sistema crece:

```text
1. El contrato vive en un documento. Si inventory renombra un campo,
   orders se entera en producción.
2. Cada equipo escribe su cliente a mano, y cada uno interpreta el JSON
   a su manera: fechas, nulos, números grandes.
3. Nadie sabe cuánto tiempo le queda a una petición. Cada salto pone
   su propio timeout y ninguno sabe lo que ya se consumió.
```

gRPC ataca los tres con la misma idea: **el contrato es un archivo que se compila**, y de él salen el
servidor, el cliente y los tipos en todos los lenguajes. Lo que se gana no es principalmente
velocidad —eso se discute en [`04`](04-http-contra-grpc.md)—: es que el contrato deja de ser una
promesa y pasa a ser código que no compila si lo rompes.

---

## 2. 🧱 Protocol Buffers: el contrato compilado

**Qué es.** Un lenguaje de definición de esquemas y un formato binario. El archivo `.proto` es la
fuente de verdad; de ahí se genera el código de las cuatro plataformas.

```protobuf
// El contrato entre pedidos e inventario. Este archivo es el que se versiona.
service InventoryService {
  rpc Reserve(ReserveRequest) returns (ReserveResponse);
}

message ReserveRequest {
  string order_id = 1;          // el número NO es decorativo: es la identidad del campo
  repeated OrderLine lines = 2;
  string idempotency_key = 3;
}
```

- **Los números de campo son el contrato real.** El nombre es para las personas; lo que viaja en el
  cable es el número. Por eso se pueden renombrar campos sin romper nada, y por eso **jamás se
  reutiliza un número**: si un consumidor viejo lee el campo `3` esperando otra cosa, no falla,
  interpreta mal.
- **`repeated` es una lista** y en el cable es simplemente el mismo campo repetido; por eso añadir
  elementos no cambia la forma del mensaje.
- Cuando un campo se elimina, su número se marca como reservado para que nadie lo vuelva a usar.

**Cómo va.** El formato es binario y posicional: sin el esquema, los bytes no significan nada. Eso es
la ventaja —compacto y rápido de parsear— y el inconveniente: no puedes leer el tráfico con los ojos.

**Con qué.** El compilador de protobuf con el plugin de cada lenguaje, o una herramienta de
construcción que además publique el esquema en un registro ([`07`](07-contratos-y-versionado.md)).

**Cuánto.** Cuesta un paso de generación en el pipeline y disciplina con los números. A cambio, un
cambio incompatible **falla al compilar** en vez de en producción.

**Cuándo sí.** Cuando el contrato entre dos servicios es estable y ambos lados los mantienen equipos
que pueden coordinar la generación.

**Cuándo no.** Cuando el consumidor es un navegador, un tercero o un script que solo quiere hacer una
llamada: ahí el coste de generar supera el beneficio.

> **Veredicto:** el valor de protobuf no es el tamaño del mensaje, es que el contrato se compila. Si
> tu problema no es la deriva de contratos, gRPC te está vendiendo algo que no necesitas.

---

## 3. 🧱 Los cuatro modos

**Qué es.** gRPC no es solo petición-respuesta: HTTP/2 permite flujos en ambos sentidos, y eso da
cuatro formas.

| Modo | Forma | Cuándo se usa de verdad |
|---|---|---|
| **Unario** | 1 petición → 1 respuesta | El 90 % de las llamadas entre servicios |
| **Streaming de servidor** | 1 petición → N respuestas | Resultados largos, seguimiento de un proceso, exportaciones |
| **Streaming de cliente** | N peticiones → 1 respuesta | Ingesta: telemetría, carga por lotes |
| **Bidireccional** | N ↔ N | Sincronización continua, protocolos conversacionales |

**Cómo va.** El streaming mantiene la conexión abierta, con lo que hereda los problemas de las
conexiones largas: hay que decidir qué pasa en un despliegue, cómo se reanuda tras un corte y quién
detecta que el otro extremo murió sin avisar. Eso lo comparte con WebSocket y se desarrolla en
[`05`](05-tiempo-real-websockets-y-sse.md).

**Cuánto.** El unario cuesta lo mismo que una llamada HTTP más el ahorro de serialización. El
streaming cuesta estado en ambos extremos y complica el balanceo y el despliegue.

**Cuándo sí.** Streaming cuando el volumen o la duración hacen absurdo trocear en llamadas sueltas.

**Cuándo no.** Streaming "porque está disponible". Una conexión larga entre dos servicios internos
suele ser un lujo innecesario que complica el despliegue sin comprar nada.

> **Veredicto:** empieza siempre en unario. El streaming se justifica por volumen o por duración, no
> por elegancia.

---

## 4. 🧱 Deadlines: la pieza que más rinde

**Qué es.** Un plazo absoluto que viaja **con la llamada** y que cada salto hereda. No es un timeout
local: es parte del protocolo.

```text
orders fija deadline = ahora + 800 ms
   └─► inventory lo recibe: sabe que le quedan ~780 ms
          └─► si llama a otro, ese recibe ~750 ms
                 └─► cuando expira, TODOS abandonan: nadie sigue trabajando
                     para una respuesta que ya nadie espera
```

**Cómo va.** La diferencia con HTTP es que ahí cada salto pone su timeout sin saber el presupuesto
total, y el trabajo aguas abajo continúa aunque el de arriba ya se haya rendido. Con deadlines, la
cancelación se propaga: el servidor puede comprobar si el plazo expiró y abandonar.

**Con qué.** En Go el deadline **es** el `context`, así que sale gratis. En Java se fija en el stub.
En Node y Python se pasa en las opciones de la llamada. Es la misma idea con cuatro sintaxis.

**Cuánto.** Cuesta pensar el número —como cualquier timeout— y cuesta una disciplina: el servidor
debe comprobar la cancelación en los puntos caros, o seguirá gastando CPU para nada.

**Cuándo sí.** En todas las llamadas. Una llamada gRPC sin deadline es exactamente el problema que
gRPC venía a resolver.

> **⚠️ Advertencia:** sin deadline, el comportamiento por defecto es esperar indefinidamente. Es el
> mismo fallo del capítulo anterior, con un protocolo que tenía la solución incorporada y que nadie
> usó.

---

## 5. 🧱 Estados, metadata e interceptores

**Qué es.** gRPC tiene su propio conjunto de códigos de estado, su mecanismo de encabezados
—*metadata*— y su equivalente de los filtros —los interceptores—.

**Cómo va.** Los códigos son pocos y están pensados para que el cliente decida:

| Código gRPC | Equivale a | Qué debe hacer el cliente |
|---|---|---|
| `OK` | 200 | Seguir |
| `INVALID_ARGUMENT` | 400 | No reintentar: el resultado será el mismo |
| `NOT_FOUND` | 404 | No reintentar |
| `ALREADY_EXISTS` | 409 | No reintentar sin cambiar algo |
| `PERMISSION_DENIED` / `UNAUTHENTICATED` | 403 / 401 | Renovar credencial o rendirse |
| `RESOURCE_EXHAUSTED` | 429 | Reintentar con espera |
| `DEADLINE_EXCEEDED` | 504 | El plazo expiró; reintentar solo si es idempotente y queda tiempo |
| `UNAVAILABLE` | 503 | Reintentar con backoff: es la señal canónica de transitorio |
| `INTERNAL` | 500 | Reintentar como mucho una vez |

La **metadata** es el equivalente de los encabezados: ahí viajan la identidad, el contexto de traza y
la clave de idempotencia. Y los **interceptores** son el sitio donde se instala todo lo transversal:
autenticación, métricas, trazas, registro. Son el chassis de
[`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)
aplicado a gRPC.

> **💡 Truco:** `UNAVAILABLE` es el único código que todos los clientes de gRPC reintentan por
> defecto en sus políticas estándar. Devolver `INTERNAL` cuando en realidad es transitorio le quita
> al cliente la información que necesita para reaccionar bien.

---

## 6. 🧱 El balanceo, que es su problema operativo

**Qué es.** gRPC va sobre HTTP/2 y multiplexa muchas llamadas en **una sola conexión TCP**. Los
balanceadores de nivel de transporte reparten conexiones, no llamadas — así que reparten una vez y
después todo el tráfico va al mismo sitio.

```text
Balanceo por conexión (L4)        Balanceo por llamada (L7 o cliente)
───────────────────────────       ──────────────────────────────────
cliente ──1 conexión──► A         cliente ──┬─llamada──► A
         (todas las llamadas)               ├─llamada──► B
                                            └─llamada──► C
```

**Cómo va.** Tres salidas, y conviene saber las tres porque es pregunta frecuente:

- **Balanceo en el cliente**: el cliente conoce las direcciones —por DNS o por un servicio de
  resolución— y reparte él. Es lo que hacen las implementaciones de gRPC con su política de reparto.
- **Proxy de nivel 7**: un intermediario que entiende HTTP/2 y reparte por llamada.
- **Service mesh**: el sidecar hace lo anterior sin que la aplicación se entere
  ([`04-operacion-y-resiliencia/05`](../04-operacion-y-resiliencia/05-service-mesh-y-sidecar.md)).

**Cuánto.** El balanceo en el cliente cuesta que cada cliente tenga que descubrir instancias y
reaccionar a los cambios; el proxy cuesta un salto; el mesh cuesta un plano de control.

> **Veredicto:** con gRPC, el balanceo deja de ser gratis. Si tu plataforma solo balancea conexiones,
> vas a servir todo el tráfico desde una instancia y lo vas a descubrir el día del pico.

---

## 7. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Generación desde `.proto` integrada en la construcción; arranque del servidor por convención en los frameworks modernos; interceptores y métricas listos | Elegir entre el stub bloqueante y el asíncrono, y no mezclarlos; y recordar fijar el deadline en cada llamada, porque el stub no lo pone solo |
| **Node/TS** | Implementación en JavaScript puro, y alternativas que generan tipos y clientes con mejor ergonomía | Que los tipos generados encajen con tu configuración de TypeScript, y vigilar el coste de serialización en el hilo único |
| **Go** | **Ciudadano de primera**: el código generado es idiomático, el `context` ya trae el deadline y la cancelación, y el servidor es parte del mismo ecosistema | Poco: el cableado de interceptores y la política de reparto. Es la plataforma donde gRPC cuesta menos |
| **Python** | Generación con su propio compilador; API síncrona y asíncrona | Decidir entre ambas y no mezclarlas; y contar con que la serialización pesada compite con el resto del proceso |

En Go se ve el contrato completo en cuatro líneas, incluido el deadline:

```go
// El deadline viaja EN la llamada: inventario sabrá cuánto tiempo le queda.
ctx, cancel := context.WithTimeout(ctx, 800*time.Millisecond)
defer cancel()

resp, err := client.Reserve(ctx, &pb.ReserveRequest{OrderId: "ORD-00042"})
if status.Code(err) == codes.DeadlineExceeded { /* el plazo expiró: no insistas sin margen */ }
```

- El plazo no se configura en el cliente: se pasa en cada llamada, que es lo que permite darle 800 ms
  a una y 3 s a otra sin tener dos clientes.
- `status.Code(err)` devuelve el código gRPC, no un error genérico: la decisión de reintentar se toma
  con él, igual que con los códigos HTTP del capítulo anterior.

Y del lado del servidor, la parte que casi nadie escribe:

```go
func (s *server) Reserve(ctx context.Context, req *pb.ReserveRequest) (*pb.ReserveResponse, error) {
    // Si el cliente ya se rindió, no gastes la base de datos en esto.
    if err := ctx.Err(); err != nil {
        return nil, status.Error(codes.DeadlineExceeded, "plazo agotado antes de empezar")
    }
    ...
}
```

- Comprobar la cancelación **antes del trabajo caro** es lo que convierte el deadline en ahorro real
  de recursos. Sin esa comprobación, el plazo solo evita que el cliente espere; el servidor sigue
  trabajando para nadie.

> **🧰 Plataforma:** el mismo contrato cuesta muy distinto según dónde. En Go es el estilo natural del
> lenguaje; en Java está muy integrado pero hay que elegir el tipo de stub; en Node y Python
> funciona, y el detalle a vigilar es que la serialización compite con el único hilo que atiende todo
> lo demás.

---

## 8. 🩺 "gRPC no se puede depurar": la respuesta

Es la objeción más frecuente y tiene respuesta concreta, que conviene dar sin ponerse a la defensiva:

```text
Objeción                         Respuesta
───────────────────────────────  ─────────────────────────────────────────────
"No puedo ver el tráfico"        cierto: es binario. Se ve con herramientas de gRPC,
                                 y en depuración se puede activar el registro de mensajes
"No puedo probar con curl"       hay clientes de línea de comandos equivalentes, y con
                                 reflexión activada descubren el esquema solos
"No puedo llamarlo desde el      cierto: el navegador no habla gRPC. Se expone una
 navegador"                      fachada REST o se usa la variante para web
"El log no me dice el error"     los códigos gRPC son más precisos que los HTTP;
                                 el problema suele ser no usarlos bien
```

La **reflexión** merece mención aparte: si el servidor la expone, las herramientas descubren los
servicios y los mensajes sin tener el `.proto` a mano. Es muy cómoda en desarrollo y hay que decidir
conscientemente si se deja activa fuera de él, porque publica el catálogo de tu API.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "gRPC es más rápido que REST" | Más compacto y más barato de parsear. En una llamada entre servicios, eso rara vez domina el tiempo total: casi todo es red y trabajo del otro lado |
| "gRPC no se puede depurar" | Hay herramientas equivalentes a `curl`, y con reflexión no hace falta ni el `.proto`. Lo que no puedes es leer los bytes a ojo |
| "Puedo cambiar el `.proto` si nadie usa ese campo" | Puedes renombrar; no puedes reutilizar el número ni cambiar el tipo. El número es la identidad del campo |
| "gRPC necesita service mesh" | Necesita balanceo por llamada. El mesh es una forma; el balanceo en el cliente y un proxy L7 son otras |
| "Pongo el timeout en el cliente y ya" | El deadline va por llamada y se propaga por la cadena. Un cliente con un plazo único desperdicia la mejor propiedad del protocolo |
| "Devuelvo `INTERNAL` para cualquier error" | Los clientes reintentan `UNAVAILABLE` y no `INTERNAL`. Elegir mal el código le quita al cliente la información con la que decide |
| "Streaming porque es más eficiente" | El unario cubre casi todo. El streaming añade estado, complica el balanceo y el despliegue, y se justifica por volumen o duración |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 5, sección
   sobre llamadas a procedimientos remotos: el contexto histórico y por qué gRPC no es CORBA.
2. **Documentación** — gRPC, conceptos básicos y los cuatro modos:
   [grpc.io/docs/what-is-grpc/core-concepts/](https://grpc.io/docs/what-is-grpc/core-concepts/).
   **La referencia principal del capítulo.**
3. **Documentación** — gRPC, deadlines y su propagación:
   [grpc.io/docs/guides/deadlines/](https://grpc.io/docs/guides/deadlines/).
4. **Documentación** — gRPC, códigos de estado y cuándo usar cada uno:
   [grpc.io/docs/guides/status-codes/](https://grpc.io/docs/guides/status-codes/).
5. **Documentación** — gRPC, el problema del balanceo y sus tres soluciones:
   [grpc.io/blog/grpc-load-balancing/](https://grpc.io/blog/grpc-load-balancing/).
6. **Documentación** — Protocol Buffers, guía del lenguaje:
   [protobuf.dev/programming-guides/proto3/](https://protobuf.dev/programming-guides/proto3/).
7. **Documentación** — Protocol Buffers, «Dos and Don'ts», que es la fuente de las reglas de
   evolución de §2:
   [protobuf.dev/programming-guides/dos-donts/](https://protobuf.dev/programming-guides/dos-donts/).
8. **Charla** — CNCF / KubeCon, «gRPC Load Balancing on Kubernetes». Es el tema que más sorprende en
   producción y la charla lo explica con casos reales.

---

## 🧠 Preguntas

1. ¿Sobre qué protocolo de transporte va gRPC y qué formato usa para los mensajes? 🟢
2. ¿Qué representa el número de un campo en un `.proto`? 🟢
3. Enumera los cuatro modos de gRPC con un caso de uso para cada uno. 🟢
4. ¿Qué es un deadline y en qué se diferencia de un timeout local? 🟢
5. Nombra cuatro códigos de estado de gRPC y qué debe hacer el cliente con cada uno. 🟢
6. ¿Para qué sirve la metadata? 🟢
7. ¿Por qué se pueden renombrar campos pero no reutilizar sus números? 🟡
8. ¿Por qué el balanceo de nivel de transporte no reparte el tráfico gRPC? 🟡
9. ¿Qué diferencia práctica hay entre `UNAVAILABLE` e `INTERNAL` para quien llama? 🟡
10. ¿Qué tiene que hacer el servidor para que el deadline ahorre recursos de verdad? 🟡
11. ¿Por qué el navegador no puede hablar gRPC directamente? 🟡
12. ¿Qué te da cada plataforma para gRPC y en cuál cuesta más adoptarlo? 🟡
13. ¿Por qué en Go el deadline "sale gratis" y en Java hay que fijarlo en cada llamada? 🟡
14. ¿Qué es la reflexión y qué decisión hay que tomar sobre ella fuera de desarrollo? 🟠
15. Te dicen que gRPC no se puede depurar. Responde en un minuto. 🟠
16. ¿Cuándo elegirías streaming de servidor en vez de varias llamadas unarias? 🟠
17. Tienes tres instancias de `inventory` y todo el tráfico va a una. Diagnostica y da dos
    soluciones. 🟠
18. ¿Cómo evolucionarías un `.proto` para añadir un campo obligatorio, sin romper a los consumidores
    actuales? 🟠
19. ¿Dónde pondrías la autenticación y la propagación de traza en un servicio gRPC, y por qué ahí? 🟠
20. Un equipo quiere exponer su servicio gRPC al equipo de frontend. ¿Qué propones? 🟠
21. ¿Qué plazo pondrías a una llamada gRPC dentro de un endpoint que promete responder en 1 s, y qué
    haces si el destino a veces tarda más? 🟠
22. ¿Qué pierdes al usar gRPC entre dos servicios de equipos que no coordinan sus despliegues? 🟠
23. Diseña el `.proto` del servicio `InventoryService` con las operaciones de reservar y liberar,
    incluyendo idempotencia y errores, y explica cada decisión. 🔴
24. Diagnostica: tras migrar de HTTP a gRPC, el p99 mejora pero aparecen picos de
    `DEADLINE_EXCEEDED` en horas punta. Da tres hipótesis ordenadas. 🔴
25. Diseña la política de reintentos de un cliente gRPC: qué códigos, cuántos intentos, qué espera,
    y qué interacción tiene con el deadline. 🔴
26. Un equipo propone pasar todas las llamadas internas a gRPC en un trimestre. Da tu plan por fases
    y di qué medirías para decidir si continuar. 🔴

---

**Anterior:** [`02` — HTTP entre servicios](02-http-entre-servicios.md) · **Siguiente:**
[`04` — HTTP contra gRPC](04-http-contra-grpc.md) · **Relacionado:**
[`07` — Contratos y versionado](07-contratos-y-versionado.md) ·
[`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/)

**Taller, opcional:** [`06/04` — gRPC](../06-talleres/04-grpc.md).
