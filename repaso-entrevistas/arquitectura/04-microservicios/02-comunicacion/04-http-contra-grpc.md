# 04 — HTTP contra gRPC

> La comparación dimensión por dimensión, el criterio para elegir en voz alta, y los terceros en
> discordia —GraphQL, tRPC y el SOAP que sigue vivo en banca—. Asume leídos
> [`02`](02-http-entre-servicios.md) y [`03`](03-grpc.md): aquí no se explica ninguno de los dos, se
> comparan.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Es la pregunta más probable de toda la entrevista, y casi nadie la contesta bien:

> —¿HTTP o gRPC entre tus servicios?

Las dos respuestas malas son gemelas. Una: *"gRPC, porque es más rápido"* — que apuesta todo a una
dimensión que casi nunca decide. Otra: *"REST, porque es el estándar"* — que confunde lo conocido con
lo correcto.

La respuesta buena tiene tres partes y se puede decir en un minuto: **qué dimensiones importan de
verdad, cuál manda en tu contexto, y qué cuesta adoptarlo en tu plataforma**. Este capítulo es esas
tres partes.

---

## 2. ⚖️ La comparación, dimensión por dimensión

| Dimensión | HTTP + JSON | gRPC | Quién gana, y cuánto importa |
|---|---|---|---|
| **Contrato** | OpenAPI, descriptivo; se puede ignorar | `.proto`, compilado; romperlo no compila | gRPC, y **es la dimensión que más decide** |
| **Formato** | Texto, legible, verboso | Binario, compacto, ilegible sin esquema | gRPC en tamaño; HTTP en depuración |
| **Latencia** | Serialización y parseo de JSON | Serialización más barata | gRPC, pero suele ser ruido frente a red y trabajo del servidor |
| **Streaming** | SSE en un sentido; nada bidireccional nativo | Cuatro modos, incluido bidireccional | gRPC, si de verdad lo necesitas |
| **Plazos** | Timeout local por salto | Deadline que se propaga y cancela | gRPC, y se infravalora muchísimo |
| **Tooling** | `curl`, navegador, cualquier proxy | Herramientas propias; reflexión ayuda | HTTP, sobre todo para equipos mixtos |
| **Navegador** | Nativo | No directamente | HTTP, sin discusión |
| **Infraestructura** | Todo lo entiende: proxies, WAF, cachés, balanceadores | Necesita HTTP/2 extremo a extremo y balanceo por llamada | HTTP, y es el coste oculto de gRPC |
| **Versionado** | Convenciones y disciplina | Reglas claras de compatibilidad en el esquema | gRPC |
| **Curva de equipo** | Todo el mundo la tiene | Generación, esquemas, herramientas nuevas | HTTP |

Dos lecturas que conviene decir en voz alta al recorrer la tabla:

- **La dimensión del contrato es la que justifica gRPC.** Si tu dolor es que los contratos derivan y
  te enteras en producción, gRPC lo resuelve de raíz. Si tu dolor es otro, estás comprando la
  solución a un problema que no tienes.
- **La dimensión de infraestructura es la que lo frena.** gRPC exige HTTP/2 de punta a punta y
  balanceo por llamada ([`03` §6](03-grpc.md#6--el-balanceo-que-es-su-problema-operativo)); si tu
  plataforma no lo da, lo vas a descubrir el día del pico.

---

## 3. 💰 Lo del rendimiento, con honestidad

Es donde más folclore hay, así que conviene tener la aritmética a mano.

```text
Una llamada típica entre servicios:

  red (ida y vuelta)            0,5 – 5 ms
  trabajo del servidor          10 – 100 ms   (base de datos, lógica, otras llamadas)
  serializar + parsear JSON     decenas de microsegundos a pocos ms según tamaño
                                ───────────────────────────────────────────────
  ¿dónde está tu tiempo?        casi todo en las dos primeras líneas
```

De ahí sale la frase honesta: **el serializador rara vez es tu cuello de botella**. gRPC reduce
tamaño de mensaje y coste de parseo, y eso importa de verdad en tres casos concretos:

- mensajes grandes o muy frecuentes —telemetría, sincronización masiva—;
- clientes móviles, donde el ancho de banda sí se nota;
- servicios de altísimo volumen donde el porcentaje de CPU dedicado a serializar es medible.

Y una advertencia sobre las cifras que circulan: los *benchmarks* que comparan HTTP y gRPC suelen
medir **servidores vacíos** que devuelven una respuesta fija. Ahí la serialización es el 100 % del
trabajo, así que la diferencia parece enorme. En un servicio real que consulta una base de datos, esa
misma diferencia se diluye hasta ser difícil de medir.

> **⚠️ Advertencia:** si vas a citar un número de rendimiento en una entrevista, di de dónde sale y
> qué no mide. Citar "siete veces más rápido" sin contexto es la forma más rápida de que te pregunten
> por el contexto.

---

## 4. 🧭 Cómo se elige, en voz alta

```text
¿El consumidor es un navegador, un tercero o un script?
├─ sí ─► HTTP. Fin.
└─ no
   │
   ├─ ¿Tu dolor real es la deriva de contratos entre equipos?
   │   ├─ sí ─► gRPC es la respuesta directa… si además:
   │   │        · tu plataforma balancea por llamada
   │   │        · los dos equipos van a mantener la generación
   │   │        · el equipo puede aprenderlo sin que sea la prioridad del trimestre
   │   │        Si falla alguna, HTTP con OpenAPI verificado en CI.
   │   └─ no
   │       ├─ ¿Necesitas streaming bidireccional o volumen muy alto? ─► gRPC
   │       └─ ¿Nada de lo anterior? ──────────────────────────────── ► HTTP
```

Y las frases que conviene tener listas:

> "gRPC hacia adentro cuando el contrato entre dos servicios es estable y los dos equipos van a
> mantenerlo; HTTP hacia afuera y hacia el navegador siempre. Y antes de meter gRPC compruebo cómo
> balancea la plataforma, porque es donde duele."

> "La ventaja de gRPC que más me ha servido no es el rendimiento: son los deadlines, que se propagan
> por la cadena. Con HTTP ese presupuesto hay que construirlo a mano."

---

## 5. ⚖️ Los terceros en discordia

**GraphQL.** Un lenguaje de consulta donde el cliente pide exactamente los campos que necesita.

- **Su sitio es el borde**, entre el frontend y los servicios, no entre servicios internos. Resuelve
  el problema de "cada pantalla necesita una combinación distinta", que es un problema de
  consumidores heterogéneos.
- **Cuesta**: un punto de entrada que hay que proteger de consultas caras —profundidad, complejidad,
  coste—, caché mucho más difícil que con HTTP, y el `N+1` que aparece solo si no se agrupan las
  resoluciones.
- **Cuándo no**: entre dos servicios internos que se conocen. Ahí la flexibilidad no compra nada y el
  coste de operación se paga entero.

**tRPC.** Llamadas tipadas de extremo a extremo sin generación de código, aprovechando que el tipo de
TypeScript viaja del servidor al cliente.

- **Su nicho es exacto y hay que decirlo así**: ambos lados en TypeScript, en el mismo repositorio,
  desplegados juntos. Ahí es imbatible en ergonomía.
- **No es una alternativa a gRPC entre equipos distintos**: en cuanto un lado deja de ser TypeScript
  o deja de compartir repositorio, el modelo se rompe.

**SOAP.** Sigue vivo en banca, seguros y administración, y conviene no despacharlo con desdén.

- Tiene contrato fuerte —WSDL—, herramientas maduras y estándares de seguridad y transacción que el
  sector lleva veinte años auditando.
- Si te lo encuentras, lo normal no es migrarlo: es ponerle una capa anticorrupción delante
  ([`01-fundamentos-y-descomposicion/03`](../01-fundamentos-y-descomposicion/03-el-camino-desde-el-monolito.md))
  y no dejar que su modelo entre en tu dominio.

> **🧠 Modelo mental:** GraphQL es para consumidores heterogéneos; gRPC para contratos estables entre
> servicios; tRPC para un monorepo de TypeScript; HTTP para todo lo demás y para todo lo que salga
> al exterior.

---

## 6. 🧰 El coste de adopción, por plataforma

Esta es la tabla que de verdad decide en la práctica, y casi nunca aparece en las comparativas.

| Plataforma | Cuánto cuesta adoptar gRPC | Qué tan idiomático queda | Lo que te deja a ti |
|---|---|---|---|
| **Java** | Bajo: la generación se integra en la construcción y los frameworks modernos lo arrancan por convención | Bien, aunque con un poco de ceremonia de stubs | Elegir tipo de stub, fijar deadlines por llamada, y montar interceptores |
| **Node/TS** | Medio: hay implementación madura y alternativas con mejor ergonomía de tipos | Correcto; depende de cuánto encaje la generación con tu configuración | Vigilar el coste de serialización en el hilo único, y la ergonomía de los tipos generados |
| **Go** | **El más bajo**: gRPC nació aquí, el código generado es idiomático y el `context` ya trae deadline y cancelación | Excelente | Casi nada más allá del cableado y la política de reparto |
| **Python** | Medio: la generación funciona bien; hay que decidir entre API síncrona y asíncrona | Aceptable; el código generado se nota generado | No mezclar los dos modelos de ejecución, y contar con el coste de serializar |

Lo que esta tabla implica en una decisión real: **el mismo cambio es barato en un equipo de Go y caro
en uno que no domina la generación de código**. Y en un sistema políglota, el coste no es la suma de
los cuatro: es el de mantener cuatro cadenas de generación en cuatro pipelines, que es
desproporcionadamente mayor.

> **🧰 Plataforma:** si te preguntan "¿gRPC o REST?" y el sistema es todo Go, la respuesta se inclina
> sola. Si es un sistema con cuatro plataformas y equipos que rotan, HTTP con contrato verificado en
> CI suele ganar por coste total, y eso es una respuesta de Tech Lead, no una concesión.

---

## 7. 🧱 El caso mixto, que es el más habitual

**Qué es.** gRPC entre servicios internos y HTTP en el borde, con una traducción en medio.

```text
navegador ──HTTP/JSON──► gateway o BFF ──gRPC──► orders ──gRPC──► inventory
                                                    │
        terceros ──HTTP/JSON──► fachada REST ───────┘
```

**Cómo va.** La traducción vive en el gateway o en un BFF. Y aquí está la decisión importante: **el
contrato externo no se genera automáticamente del interno**. Si lo haces, cada refactor interno se
convierte en una ruptura para el navegador, que es el cliente más caro de migrar.

**Cuánto.** Cuesta mantener dos contratos —el interno y el externo— y una traducción entre ambos. Ese
coste es real y hay que decirlo; a cambio, lo interno puede evolucionar sin negociar con el
frontend.

**Cuándo sí.** Cuando de verdad hay una frontera entre lo interno y lo externo, con consumidores
distintos y ritmos distintos.

**Cuándo no.** En un sistema pequeño con un solo frontend y tres servicios: ahí mantener dos
contratos es puro peaje.

> **Veredicto:** el caso mixto no es indecisión, es reconocer que los consumidores internos y
> externos tienen restricciones distintas. Lo que sí es un error es exponer el contrato interno tal
> cual al exterior y llamarlo API.

---

## 8. 🔭 Dónde aparece de verdad

- **La migración que se atascó en el balanceo.** Equipo que migra tres servicios a gRPC, todo bien en
  pruebas, y en producción una instancia al 90 % y dos ociosas. El problema no era gRPC: era que
  nadie miró cómo repartía la plataforma.
- **El equipo que eligió gRPC por rendimiento y ganó en contratos.** Midieron y la latencia mejoró
  poco; pero dejaron de tener incidentes por campos renombrados. El beneficio real era otro, y solo
  lo vieron después.
- **El BFF que se generó del `.proto`.** Publicaron automáticamente el contrato interno como REST
  para el frontend. Seis meses después, cualquier refactor interno rompía la web, y acabaron
  escribiendo a mano la capa que se habían ahorrado.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "gRPC es siete veces más rápido, lo dice el benchmark" | Esos benchmarks miden servidores vacíos, donde serializar es el 100 % del trabajo. En un servicio real casi todo el tiempo es red y base de datos |
| "REST para APIs públicas y gRPC para internas, y ya" | Es un buen punto de partida, pero la decisión depende del dolor real, del balanceo de la plataforma y del coste de adopción del equipo |
| "Con gRPC no hay que versionar" | Hay que respetar las reglas de evolución del esquema. Lo que cambia es que un error incompatible falla al compilar, no que no exista |
| "gRPC no sirve porque el navegador no lo soporta" | Correcto para el borde; irrelevante para el interior. Por eso el caso mixto es el más común |
| "GraphQL sustituye a REST" | Resuelve consumidores heterogéneos en el borde. Entre dos servicios internos añade coste sin comprar flexibilidad que nadie use |
| "tRPC es el gRPC de TypeScript" | Solo si ambos lados son TypeScript y comparten repositorio. Fuera de ahí, su modelo no aplica |
| "Elegimos gRPC y migramos todo el trimestre" | El coste de adopción es muy distinto por plataforma. Se prueba con un par de servicios, se mide, y se decide con datos |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 5, donde
   compara estilos de comunicación sin vender ninguno. **La mejor lectura para este capítulo.**
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 3 y capítulo 8, con
   el papel del gateway en el caso mixto.
3. **Documentación** — gRPC, buenas prácticas de rendimiento, útil para saber qué se mide de verdad:
   [grpc.io/docs/guides/performance/](https://grpc.io/docs/guides/performance/).
4. **Documentación** — gRPC, el problema del balanceo, que es el coste oculto de §2:
   [grpc.io/blog/grpc-load-balancing/](https://grpc.io/blog/grpc-load-balancing/).
5. **Documentación** — GraphQL, para situar su problema y su coste:
   [graphql.org/learn/](https://graphql.org/learn/).
6. **Documentación** — tRPC, conceptos, donde se ve explícito su requisito de extremos en TypeScript:
   [trpc.io/docs/concepts](https://trpc.io/docs/concepts).
7. **Documentación** — Connect, una alternativa que habla gRPC y HTTP con el mismo servicio, útil
   cuando el borde y el interior no se ponen de acuerdo:
   [connectrpc.com/docs/introduction/](https://connectrpc.com/docs/introduction/).
8. **Especificación** — OpenAPI, para el lado HTTP del contrato verificado:
   [spec.openapis.org/oas/latest.html](https://spec.openapis.org/oas/latest.html).

---

## 🧠 Preguntas

1. Nombra cinco dimensiones en las que se comparan HTTP y gRPC. 🟢
2. ¿Cuál es la dimensión que más justifica adoptar gRPC? 🟢
3. ¿Qué parte del tiempo de una llamada típica ocupa la serialización? 🟢
4. ¿Por qué el navegador obliga a HTTP en el borde? 🟢
5. ¿Cuál es el nicho exacto de tRPC? 🟢
6. ¿Dónde tiene su sitio GraphQL y dónde no? 🟡
7. ¿Por qué los benchmarks que comparan HTTP y gRPC exageran la diferencia? 🟡
8. ¿En qué se diferencia el versionado de un `.proto` del de una API REST? 🟡
9. ¿Por qué los deadlines son una ventaja infravalorada frente a los timeouts locales? 🟡
10. ¿Qué coste de infraestructura introduce gRPC que HTTP no tiene? 🟡
11. ¿En qué casos concretos sí domina el coste de serialización? 🟡
12. ¿Por qué no se debe generar el contrato externo a partir del interno? 🟠
13. Sistema todo en Go, contratos estables, dos equipos. ¿HTTP o gRPC? Justifica. 🟠
14. Sistema con cuatro plataformas y equipos que rotan. Misma pregunta, y di qué cambia. 🟠
15. Te piden migrar a gRPC "por rendimiento". ¿Qué mides antes de aceptar? 🟠
16. ¿Cómo diseñarías el borde de un sistema que usa gRPC por dentro? 🟠
17. El equipo de frontend pide GraphQL. ¿Qué preguntas antes de decidir? 🟠
18. ¿Qué harías con un servicio SOAP del core bancario con el que tienes que integrarte? 🟠
19. ¿Qué tres comprobaciones haces sobre tu plataforma antes de aprobar gRPC? 🟠
20. Defiende HTTP con OpenAPI verificado en CI frente a alguien que quiere gRPC por el contrato. 🟠
21. Escribe la respuesta completa de dos minutos a "¿HTTP o gRPC entre tus servicios?", con las tres
    partes del capítulo. 🔴
22. Diseña la comunicación de un sistema con web, móvil, cinco servicios internos y una integración
    con un tercero, eligiendo estilo para cada tramo y justificando. 🔴
23. Un equipo migró a gRPC y el rendimiento no mejoró. Analiza qué pudo pasar y qué beneficio
    pudieron haber obtenido igualmente. 🔴
24. Diseña el plan de prueba de tres semanas que decidiría si adoptar gRPC en tu sistema: qué mides,
    con qué umbrales, y qué decisión tomas con cada resultado. 🔴

---

**Anterior:** [`03` — gRPC](03-grpc.md) · **Siguiente:**
[`05` — Tiempo real: WebSockets, SSE y los demás](05-tiempo-real-websockets-y-sse.md) ·
**Relacionado:** [`07` — Contratos y versionado](07-contratos-y-versionado.md) ·
[`05-plataformas`](../05-plataformas/)

**Taller, opcional:** [`06/04` — gRPC](../06-talleres/04-grpc.md).
