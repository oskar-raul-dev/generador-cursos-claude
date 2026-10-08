# 05 — Service mesh y sidecar

> Qué mueve un mesh fuera del código, qué no mueve, cuánto cuesta, y por qué su mejor argumento es
> precisamente el poliglotismo. Asume leídos [`03`](03-resiliencia-en-la-practica.md) y
> [`04`](04-observabilidad-y-trazas.md). mTLS y zero-trust como modelo de seguridad son de
> [`arquitectura/01-bases/04-seguridad/05`](../../01-bases/04-seguridad/05-mtls-zero-trust-y-mesh.md);
> aquí entra lo que el mesh hace por ti y lo que te cuesta.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Tienes cuatro plataformas y las mismas necesidades en todas: mTLS entre servicios, reintentos,
timeouts, circuit breaker, métricas uniformes y trazas. Eso significa:

```text
Java     una librería de resiliencia + su configuración + su exportador
Node/TS  otra librería + otra configuración + otro exportador
Go       otra más
Python   otra más
        ─────────────────────────────────────────────────
        cuatro implementaciones de la misma política,
        que divergen en cuanto alguien toca una
```

La promesa del mesh es sacar todo eso del proceso y ponerlo en un **proxy al lado** —el sidecar—, que
es igual para las cuatro. La política se define una vez y se aplica a todo el tráfico, sin tocar una
línea de código de ningún servicio.

Es una promesa buena y es cierta a medias. Este capítulo es dónde está la mitad que no lo es.

---

## 2. 🧱 Sidecar: el patrón antes que el producto

**Qué es.** Un proceso que corre junto a tu servicio, comparte su ciclo de vida y se ocupa de algo
transversal. Todo el tráfico entrante y saliente pasa por él.

```text
┌──────────────────────────────┐
│  pod / unidad de despliegue  │
│  ┌──────────┐  ┌──────────┐  │
│  │ servicio │◄─┤ sidecar  │◄─┼── tráfico entrante
│  │          ├─►│ (proxy)  ├─┼──► tráfico saliente
│  └──────────┘  └──────────┘  │
└──────────────────────────────┘
```

**Cómo va.** El servicio cree que habla con `localhost`; el sidecar intercepta, aplica política y
enruta. Como está fuera del proceso, funciona igual sea cual sea el lenguaje: **esa es toda la idea**.

**Cuánto.** Cuesta un contenedor más por instancia —CPU y memoria—, un salto de red local en cada
llamada, y una pieza más en el diagnóstico: cuando algo falla, ahora hay que saber si fue el servicio
o su proxy.

**Cuándo sí.** Cuando lo transversal es igual para muchos servicios y reescribirlo en cada plataforma
sale caro.

**Cuándo no.** Cuando hay pocos servicios y una sola plataforma: ahí la librería es más simple, más
rápida y más fácil de depurar.

> **Veredicto:** el sidecar no es un truco de infraestructura, es una decisión de dónde vive lo
> transversal. En un sistema políglota es su mejor argumento; en uno homogéneo, su peor caso.

---

## 3. 🧱 Qué mueve el mesh, y qué no

**Qué mueve.** Un mesh es el sidecar más un **plano de control** que lo configura:

| Lo que mueve fuera del código | Detalle |
|---|---|
| **mTLS entre servicios** | Certificados emitidos y rotados automáticamente: el argumento más fuerte |
| **Timeouts y reintentos** | Por ruta, configurables sin desplegar |
| **Circuit breaker y límites** | Detección de instancias con fallos y expulsión temporal |
| **Balanceo por llamada** | Resuelve el problema de gRPC de [`01`](01-descubrimiento-y-enrutamiento.md) |
| **Tráfico dividido** | Canary y despliegues progresivos por porcentaje |
| **Métricas y trazas uniformes** | Las mismas para las cuatro plataformas, sin instrumentar |

**Qué NO mueve.** Y esta lista es la que hay que saber en una entrevista:

```text
La idempotencia            el mesh reintenta; no sabe si tu operación puede repetirse
La semántica del reintento qué es seguro reintentar lo decide tu dominio, no el proxy
El contrato                versionado y compatibilidad siguen siendo tuyos
La degradación             qué respuesta parcial tiene sentido lo sabe la aplicación
El dominio                 obviamente, pero conviene decirlo
```

Y el matiz que más rinde: el mesh **propaga** el contexto de traza entre servicios, pero **no lo
propaga dentro** de tu proceso. Los spans del sidecar existen; lo que pasa entre que tu servicio
recibe y responde sigue siendo responsabilidad de tu instrumentación
([`04`](04-observabilidad-y-trazas.md)).

> **⚠️ Advertencia:** "con el mesh ya no necesitas resiliencia en el código" es falso en el punto que
> más importa: el mesh puede reintentar una escritura no idempotente y duplicar un cobro. Él no sabe
> que no debía.

---

## 4. 💰 El precio

Cuatro costes, y conviene nombrarlos con números o con el tipo de problema que producen:

| Coste | Qué significa |
|---|---|
| **Latencia** | Dos saltos locales más por llamada —salida y entrada—. Normalmente de orden de milisegundo, pero se suma en cadenas largas |
| **Recursos** | Un proxy por instancia: CPU y memoria multiplicadas por el número de instancias |
| **Complejidad operativa** | Un plano de control que aprender, actualizar y depurar. Y que puede caerse |
| **Diagnóstico** | Una capa más entre el síntoma y la causa: hay errores que ahora vienen del proxy |

A eso se añade **la doble configuración**, que es el fallo característico del mesh: el reintento
configurado en el proxy y el de la librería se **multiplican**. Tres intentos en cada capa son nueve
llamadas, y el equipo suele descubrirlo en el peor momento.

> **💰 Costo:** la cuenta rápida para una entrevista: un mesh con sidecar multiplica por dos el número
> de contenedores y añade un plano de control a mantener. Con seis servicios, eso es más
> infraestructura que aplicación.

---

## 5. 🧰 La tabla invertida: qué te ahorra en cada plataforma

Aquí la tabla de las cuatro plataformas se invierte, y es el mejor momento del corpus para verlo:
**el mesh iguala las cuatro**, así que lo que se compara es cuánto te ahorra en cada una.

| Plataforma | Qué te ahorra el mesh | Qué ya tenías |
|---|---|---|
| **Java** | Poco: el ecosistema ya trae resiliencia, métricas y trazas maduras | Casi todo lo que el mesh ofrece, y con más contexto de aplicación |
| **Node/TS** | Bastante: resiliencia y mTLS no vienen de serie y hay que componerlos | Instrumentación de trazas razonable |
| **Go** | **Mucho**: la cultura es escribirlo a mano, así que el mesh evita cablear lo mismo en cada servicio | Poco hecho por defecto |
| **Python** | Bastante: el ecosistema tiene piezas sueltas, no un conjunto integrado | Reintentos y decoradores maduros |

- **Lo que te deja a ti en las cuatro:** la idempotencia, la degradación y el contrato. Ninguna de las
  cuatro filas cambia eso.
- La lectura interesante: **cuanto más maduro es el ecosistema de tu plataforma, menos te aporta el
  mesh**. Por eso un equipo de Java puede no ver el valor y uno de Go sí — y ambos tienen razón.

> **🧰 Plataforma:** el mesh es la respuesta más fuerte al coste del poliglotismo de
> [`05-plataformas/06`](../05-plataformas/06-la-matriz-de-decision.md): en vez de mantener cuatro implementaciones de la misma
> política, se mantiene una. Si tu sistema es de una sola plataforma, ese argumento desaparece y hay
> que justificarlo por otra cosa.

---

## 6. ⚖️ Mesh, librería o nada

| | Librería en el código | Sidecar / mesh | Sin nada |
|---|---|---|---|
| **Coste inicial** | Bajo si hay una plataforma | Alto: plano de control | Cero |
| **Coste por plataforma nueva** | Alto: otra implementación | Cero | Cero |
| **Contexto de aplicación** | Total: sabe qué es idempotente | Ninguno | — |
| **Cambios sin desplegar** | No | Sí | — |
| **Diagnóstico** | Directo | Una capa más | Directo |
| **Encaja con** | Pocas plataformas, pocos servicios | Muchos servicios, varias plataformas | Sistemas pequeños |

📝 Y un cambio reciente que conviene mencionar: existen modelos **sin sidecar**, donde parte de la
función se mueve a un componente por nodo en vez de uno por instancia. Reduce el coste de recursos y
el salto por llamada, a cambio de un modelo distinto de aislamiento. Es la respuesta de la industria
al principal reproche al mesh, y saber que existe demuestra que sigues el tema.

---

## 7. 🧭 Cómo se elige

```text
¿Cuántos servicios y cuántas plataformas tienes?
│
├─ < 10 servicios, 1 plataforma ──────► librería. El mesh es un segundo
│                                        sistema que mantener
│
├─ muchos servicios, varias plataformas ─► el mesh empieza a compensar,
│                                          sobre todo por mTLS y uniformidad
│
└─ requisito de mTLS en todo el tráfico ─► el mesh es la forma más barata
                                            de conseguirlo sin tocar código
```

Y la frase, que conviene tener ensayada porque es una pregunta de Tech Lead:

> "Con seis servicios y una plataforma, no: el mesh sería más infraestructura que aplicación. Lo
> plantearía cuando tuviéramos varias plataformas o un requisito de mTLS generalizado, y aun así
> dejaría en el código la idempotencia y la degradación, que el proxy no puede decidir."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El mesh te da resiliencia gratis" | Te da reintentos y cortes; no sabe qué es idempotente ni qué degradación tiene sentido |
| "Con mTLS del mesh ya no hace falta autorizar" | mTLS dice **quién** es el que llama; si puede hacer eso lo decide tu servicio |
| "El sidecar no añade latencia relevante" | Dos saltos locales por llamada. Suele ser de orden de milisegundo y se suma en cadenas largas |
| "Si tienes Kubernetes, necesitas un mesh" | Son cosas distintas. Con pocos servicios y una plataforma, el mesh añade más de lo que quita |
| "Con el mesh ya tenemos trazas" | Tienes los spans del proxy. Lo que pasa dentro de tu proceso sigue necesitando instrumentación |
| "Configuramos los reintentos en el mesh y en la librería" | Se multiplican. Tiene que haber **una** capa de reintento y desactivarse en la otra |
| "El mesh no puede caerse, es infraestructura" | El plano de control se cae, se actualiza mal y tiene fallos. Y cuando falla, falla para todos |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 5, sección de
   service mesh, con la comparación honesta frente a librerías. **La lectura más equilibrada del
   tema.**
2. **Libro** — Michael Nygard, *Release It!*, 2.ª ed., Pragmatic Bookshelf, 2018. Para entender qué
   debe seguir viviendo en la aplicación aunque haya proxy.
3. **Fuente primaria** — Chris Richardson, «Pattern: Sidecar», la ficha del patrón:
   [microservices.io/patterns/deployment/sidecar.html](https://microservices.io/patterns/deployment/sidecar.html).
4. **Documentación** — Istio, qué es y qué hace el plano de control:
   [istio.io/latest/docs/concepts/what-is-istio/](https://istio.io/latest/docs/concepts/what-is-istio/).
5. **Documentación** — Istio, el modelo sin sidecar, para el apunte 📝 de §6:
   [istio.io/latest/docs/ambient/overview/](https://istio.io/latest/docs/ambient/overview/).
6. **Documentación** — Linkerd, visión general, útil como contraste de enfoque más ligero:
   [linkerd.io/2-edge/overview/](https://linkerd.io/2-edge/overview/).
7. **Charla** — KubeCon / CNCF, «Do You Really Need a Service Mesh?». Es la charla que mejor ordena
   la decisión, y su respuesta suele ser "todavía no".

---

## 🧠 Preguntas

1. ¿Qué es el patrón sidecar? 🟢
2. Enumera cuatro cosas que mueve un mesh fuera del código. 🟢
3. Enumera tres cosas que el mesh *no* mueve. 🟢
4. ¿Cuáles son los cuatro costes de un mesh? 🟢
5. ¿Qué es el plano de control? 🟢
6. ¿Qué es la doble configuración y qué produce? 🟡
7. ¿Por qué el mejor argumento del mesh es el poliglotismo? 🟡
8. ¿Por qué un equipo de Java puede no ver valor en el mesh y uno de Go sí? 🟡
9. ¿Por qué mTLS no sustituye a la autorización? 🟡
10. ¿Qué parte de las trazas cubre el mesh y cuál no? 🟡
11. ¿Por qué el mesh puede duplicar un cobro? 🟡
12. ¿Qué cambia el modelo sin sidecar respecto al clásico? 🟡
13. El plano de control se cae. ¿Qué ocurre con el tráfico? 🟡
14. Tienes seis servicios y una plataforma. ¿Mesh sí o no? Justifica. 🟠
15. Te exigen mTLS en todo el tráfico interno. ¿Qué opciones tienes y cuál eliges? 🟠
16. Los reintentos están en el mesh y en la librería. ¿Qué pasa y qué corriges? 🟠
17. ¿Qué dejarías siempre en el código aunque tengas mesh? 🟠
18. ¿Cómo diagnosticas un error que puede venir del servicio o de su sidecar? 🟠
19. ¿Qué medirías para decidir si el mesh está compensando su coste? 🟠
20. Un equipo propone mesh para resolver el balanceo de gRPC. ¿Qué respondes? 🟠
21. Diseña la política de resiliencia repartida entre mesh y código para un sistema con cuatro
    plataformas, diciendo qué va en cada sitio y por qué. 🔴
22. Escribe el análisis coste-beneficio de adoptar un mesh en un sistema de 25 servicios y tres
    plataformas, con los números que pedirías antes de decidir. 🔴
23. Diagnostica: tras instalar el mesh, la latencia p99 sube un 30 % y aparecen errores esporádicos
    de conexión. Da tres hipótesis ordenadas. 🔴
24. Un equipo quiere migrar toda su resiliencia al mesh en un trimestre. Da tu plan por fases y qué
    medirías en cada una. 🔴

---

**Anterior:** [`04` — Observabilidad y trazas](04-observabilidad-y-trazas.md) · **Siguiente:**
[`06` — Despliegue y entrega](06-despliegue-y-entrega.md) · **Relacionado:**
[`03` — Resiliencia en la práctica](03-resiliencia-en-la-practica.md) ·
[`arquitectura/01-bases/04-seguridad/05`](../../01-bases/04-seguridad/05-mtls-zero-trust-y-mesh.md)
