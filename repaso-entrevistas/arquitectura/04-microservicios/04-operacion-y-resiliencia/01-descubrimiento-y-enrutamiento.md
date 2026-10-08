# 01 — Descubrimiento y enrutamiento

> Cómo encuentra un servicio a otro cuando las direcciones cambian en cada despliegue: descubrimiento
> en el cliente o en el servidor, DNS y sus trampas, y por qué el balanceo con HTTP/2 no reparte.
> Asume leídos
> [`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)
> y [`02-comunicacion/03`](../02-comunicacion/03-grpc.md). La implementación concreta en cada nube es
> de [`cloud/01-aws`](../../../cloud/01-aws/) y
> [`cloud/02-gcp`](../../../cloud/02-gcp/).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

`orders` tiene que llamar a `inventory`. ¿A qué dirección?

```text
Hoy      10.0.3.17:8080, 10.0.3.42:8080
Mañana   se despliega: mueren esas dos y nacen 10.0.5.8 y 10.0.5.11
Tarde    escala a cuatro instancias
Noche    una se cae y el orquestador la reemplaza en otra máquina
```

Cualquier dirección escrita en configuración caduca en horas. Y el problema no es solo encontrar una
dirección válida: es **repartir** entre las que hay, **dejar de mandar** a las que ya no sirven, y
que todo eso ocurra sin desplegar nada.

Históricamente esto se resolvía dentro de la aplicación, con un registro y una librería. Hoy lo
resuelve la plataforma, y el cambio tiene una consecuencia práctica: **lo que en 2016 era código, hoy
es configuración**, y saber por qué cambió es parte de la respuesta en una entrevista.

---

## 2. ⚖️ Descubrimiento en el cliente contra en el servidor

**Qué es.** Dos formas de resolver la misma pregunta.

```text
En el CLIENTE                          En el SERVIDOR
───────────────────────────────        ──────────────────────────────
las instancias se registran            el cliente llama a un nombre estable
el cliente consulta el registro        algo delante decide a qué instancia
el cliente elige instancia y llama     el cliente no sabe cuántas hay
```

| | En el cliente | En el servidor |
|---|---|---|
| **Quién decide** | La aplicación, con su librería | El proxy, el balanceador o la plataforma |
| **Saltos** | Directo a la instancia | Uno más, salvo que sea un sidecar |
| **Políticas finas** | Sí: reparto por latencia, zona, reintentos | Las que soporte el intermediario |
| **Coste** | Librería en cada plataforma; registro que operar | Un componente que ya suele existir |
| **Encaja con** | Sistemas homogéneos con librería madura | Sistemas políglotas y plataformas modernas |

**Cuánto.** El del cliente cuesta una librería **por plataforma** —cuatro, en un sistema políglota— y
un registro que mantener disponible. El del servidor cuesta un salto y depende de lo que el
intermediario sepa hacer.

**Cuándo sí y cuándo no.** Hoy, salvo que necesites políticas de reparto muy finas, gana el del
servidor: la plataforma ya lo hace y no hay que escribir nada. El del cliente vuelve a tener sentido
con gRPC, por lo que se ve en §5.

> **📝 Contexto:** el registro en la aplicación fue la respuesta correcta cuando no había una
> plataforma debajo que resolviera nombres. Con orquestadores modernos, ese registro es una pieza
> más que mantener sin necesidad. Si en una entrevista citas herramientas de esa época, conviene
> situarlas en su momento y decir qué las sustituyó.

---

## 3. 🧱 DNS, y sus tres trampas

**Qué es.** El mecanismo real detrás de casi todo el descubrimiento del lado del servidor: un nombre
estable que resuelve a una o varias direcciones.

**Cómo va.** En un orquestador, cada servicio tiene un nombre interno que resuelve a una dirección
virtual estable, y esa dirección reparte entre las instancias vivas. El servicio escala, se despliega
y se mueve; el nombre no cambia.

**Las trampas**, que son tres y todas producen incidentes:

| Trampa | Qué pasa | Qué hacer |
|---|---|---|
| **Caché del resolvedor** | El cliente sigue usando una dirección muerta | Respetar el tiempo de vida; no cachear indefinidamente |
| **Caché del runtime** | Algunos entornos cachean la resolución más de lo que dice el registro | Configurarlo explícitamente; es distinto en cada plataforma (§6) |
| **Resolución en el arranque** | El cliente resuelve una vez al crearse y nunca más | Usar clientes que re-resuelvan, o reciclar conexiones |

La tercera es la más común y la más silenciosa: un cliente creado al arrancar guarda la dirección de
entonces y sigue mandando tráfico ahí aunque esa instancia ya no exista.

> **🩺 Diagnóstico:** si tras un despliegue de `inventory` algunos clientes siguen fallando y otros
> no, mira la caché de resolución antes que nada. El patrón característico es que se arregla solo al
> reiniciar el cliente, que es exactamente la señal.

---

## 4. 🧱 El registro y la ventana en la que miente

**Qué es.** El componente que sabe qué instancias están vivas. En una plataforma moderna es el propio
orquestador, que usa las sondas de salud
([`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)).

**Cómo va.** Una instancia se registra al estar lista y se da de baja al morir. Pero entre que muere y
el registro se entera pasa tiempo: el intervalo de sondeo por el número de fallos tolerados.

```text
La instancia muere ─── 0 s
                    ├── el sondeo falla      +5 s
                    ├── falla otra vez       +10 s
                    ├── se marca como caída  +15 s  ← hasta aquí, el registro MIENTE
                    └── deja de recibir tráfico
```

Durante esos segundos, el cliente recibe direcciones que no responden. Por eso **el descubrimiento no
sustituye a la resiliencia**: hace falta timeout corto y reintento hacia otra instancia, que es
[`03`](03-resiliencia-en-la-practica.md).

**Cuánto.** Bajar el intervalo reduce la ventana y aumenta la carga de sondeo y los falsos positivos.
Es un equilibrio, no un valor óptimo.

> **Veredicto:** el registro siempre va con retraso respecto a la realidad. Cualquier diseño que
> asuma que la lista de instancias está al día es frágil; lo que lo hace robusto es reintentar contra
> otra instancia cuando una no responde.

---

## 5. ⚖️ Balanceo: por conexión o por llamada

**Qué es.** La diferencia que decide si tu tráfico se reparte o no, y que aparece en cuanto hay
HTTP/2 o gRPC.

```text
Por CONEXIÓN (L4)                    Por LLAMADA (L7 o cliente)
cliente ──1 conexión──► instancia A   cliente ──┬─llamada──► A
         (todas las llamadas ahí)               ├─llamada──► B
                                                └─llamada──► C
```

Con HTTP/1.1 y conexiones cortas, repartir conexiones reparte razonablemente. Con HTTP/2 —y por tanto
con gRPC— una sola conexión multiplexa todas las llamadas, así que repartir conexiones **no reparte
nada**: el cliente abre una, se le asigna una instancia, y ahí se queda.

**Las tres salidas**, que ya aparecieron en
[`02-comunicacion/03`](../02-comunicacion/03-grpc.md) y aquí se ven desde la operación:

| Salida | Cómo | Coste |
|---|---|---|
| **Balanceo en el cliente** | El cliente resuelve todas las instancias y reparte él | Librería por plataforma; hay que reaccionar a cambios |
| **Proxy de nivel 7** | Un intermediario que entiende HTTP/2 reparte por llamada | Un salto más |
| **Service mesh** | El sidecar hace lo anterior sin tocar la aplicación | Plano de control ([`05`](05-service-mesh-y-sidecar.md)) |

**Cuándo sí y cuándo no.** Si tu plataforma solo balancea por conexión y vas a usar gRPC, esto **no
es opcional**: hay que resolverlo antes de migrar, no después del primer pico.

> **⚠️ Advertencia:** el síntoma clásico es una instancia al 90 % de CPU y las demás ociosas, con el
> balanceador informando de reparto correcto —porque para él lo es: repartió conexiones—. Y empeora
> con el escalado automático: las instancias nuevas no reciben nada porque nadie abre conexiones
> hacia ellas.

---

## 6. 🧰 En las cuatro plataformas

Lo que se compara aquí no es "qué librería de descubrimiento usas" —hoy casi siempre ninguna— sino
**cuánto tiempo cachea cada runtime una resolución de DNS**, que es la trampa de §3 y es distinta en
las cuatro.

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Cliente balanceado en el ecosistema, aunque cada vez menos necesario; resolución delegada a la JVM | **Revisar la caché de DNS de la JVM**: su política por defecto depende de la configuración de seguridad y del entorno, y puede ser mucho más larga de lo esperado |
| **Node/TS** | Resolución delegada al sistema; clientes con pool que mantienen conexiones vivas | Re-resolver: un cliente con conexiones persistentes puede no volver a preguntar nunca. Reciclar conexiones periódicamente |
| **Go** | Resolución propia o del sistema según configuración; `Transport` con control fino del pool | Fijar el tiempo de vida máximo de las conexiones: sin él, una conexión viva indefinidamente ignora cualquier cambio |
| **Python** | Resolución del sistema; clientes con pool configurable | Lo mismo: caducidad de conexiones y no guardar direcciones resueltas en variables de larga vida |

- **Lo que te deja a ti en las cuatro:** la misma decisión, con cuatro configuraciones distintas —
  **cuánto vive una conexión**. Si una conexión puede vivir horas, el cliente seguirá hablando con
  una instancia que quizá ya no debería recibir tráfico.
- Un detalle común y poco conocido: el tiempo de vida máximo de conexión es, en la práctica, el
  mecanismo que **reequilibra** el tráfico cuando escalas. Sin él, las instancias nuevas tardan en
  recibir carga.

> **🧰 Plataforma:** la pregunta que conviene hacerse en cualquier sistema: *si mato una instancia
> ahora mismo, ¿cuánto tarda cada cliente en dejar de mandarle tráfico?* La respuesta es la suma de
> la ventana del registro, la caché de DNS y la vida de las conexiones — y casi nadie la conoce.

---

## 7. 🧭 Cómo se elige

```text
¿La plataforma da nombres estables y reparte por llamada?
├─ sí ─► descubrimiento en el servidor. No escribas nada.
└─ no
   │
   ├─ ¿Usas HTTP/2 o gRPC? ──► necesitas balanceo por llamada:
   │                            cliente balanceado, proxy L7 o mesh
   │
   └─ ¿HTTP/1.1 y conexiones cortas? ──► el balanceador clásico basta
```

Y la frase para decirlo:

> "Hoy el descubrimiento lo resuelve la plataforma y no escribo nada. Lo que sí compruebo es cómo
> reparte cuando uso HTTP/2, porque el balanceo por conexión deja todo el tráfico en una instancia, y
> cuánto tarda un cliente en dejar de hablar con una instancia muerta."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El descubrimiento lo hace el registro y ya" | El registro siempre va con retraso. Hace falta timeout y reintento hacia otra instancia |
| "Kubernetes balancea las llamadas gRPC" | Reparte conexiones. Con HTTP/2 multiplexado, eso significa que no reparte llamadas |
| "El DNS ya resuelve el balanceo" | Resuelve nombres. El reparto depende de quién esté detrás y de cuánto cachee el cliente |
| "El registro sabe qué instancias están vivas" | Sabe cuáles pasaron la última sonda. Entre el fallo y la baja hay una ventana en la que miente |
| "Escribimos la dirección en la configuración" | Caduca en horas. El contrato es el **nombre lógico**, nunca una dirección |
| "Al escalar, el tráfico se reparte solo" | Solo si las conexiones se reciclan. Con conexiones persistentes, las instancias nuevas tardan en recibir carga |
| "Eso lo arreglamos con un mesh" | El mesh resuelve el reparto y añade un plano de control. Antes de eso hay opciones más baratas |

---

## 📚 Para profundizar

1. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 3, sección de
   descubrimiento: las dos variantes con sus consecuencias. **La referencia del capítulo.**
2. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 5, con el
   contexto histórico de por qué el registro se movió a la plataforma.
3. **Fuente primaria** — Chris Richardson, «Client-side service discovery»:
   [microservices.io/patterns/client-side-discovery.html](https://microservices.io/patterns/client-side-discovery.html).
4. **Fuente primaria** — Chris Richardson, «Server-side service discovery»:
   [microservices.io/patterns/server-side-discovery.html](https://microservices.io/patterns/server-side-discovery.html).
5. **Documentación** — Kubernetes, `Service`: nombres estables, direcciones virtuales y la variante
   sin dirección para balanceo en el cliente:
   [kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/).
6. **Documentación** — gRPC, balanceo de carga y sus tres estrategias:
   [grpc.io/blog/grpc-load-balancing/](https://grpc.io/blog/grpc-load-balancing/).
7. **Charla** — CNCF / KubeCon, «gRPC Load Balancing on Kubernetes». El caso de §5, con datos reales.

---

## 🧠 Preguntas

1. ¿Qué problema resuelve el descubrimiento de servicios? 🟢
2. Diferencia entre descubrimiento en el cliente y en el servidor. 🟢
3. ¿Cuáles son las tres trampas del DNS en este contexto? 🟢
4. ¿Por qué el registro "miente" durante unos segundos? 🟢
5. ¿Qué diferencia hay entre balancear por conexión y por llamada? 🟢
6. ¿Cuáles son las tres salidas al problema de balanceo con gRPC? 🟢
7. ¿Qué cambió para que el registro en la aplicación dejara de ser la respuesta por defecto? 🟢
8. ¿Por qué el balanceo por conexión no reparte el tráfico de HTTP/2? 🟡
9. ¿Por qué el descubrimiento no sustituye al timeout y al reintento? 🟡
10. ¿Qué papel juega el tiempo de vida máximo de una conexión en el reequilibrio? 🟡
11. ¿Por qué un cliente creado al arrancar puede hablar con instancias muertas? 🟡
12. ¿Por qué bajar el intervalo de sondeo no es gratis? 🟡
13. ¿Qué pasa con las conexiones abiertas durante un despliegue gradual, y cómo se mitiga? 🟡
14. Tras un despliegue, algunos clientes fallan y otros no, y se arregla al reiniciarlos.
    Diagnostica. 🟠
15. Tienes tres instancias y una recibe todo el tráfico gRPC. Da dos soluciones con su coste. 🟠
16. ¿Cuánto tarda tu sistema en dejar de mandar tráfico a una instancia muerta? Descompón la cuenta.
    🟠
17. El escalado automático añade instancias y no reciben carga. Explica y corrige. 🟠
18. ¿Cuándo justificarías balanceo en el cliente hoy? 🟠
19. ¿Qué configuración de cliente HTTP revisarías en las cuatro plataformas por este tema? 🟠
20. Un equipo quiere montar un registro propio en la aplicación. Argumenta. 🟠
21. Diseña el camino completo de una llamada de `orders` a `inventory`: resolución, reparto,
    reintento y qué ocurre en cada fallo posible. 🔴
22. Diagnostica: el p99 de una ruta se dispara solo durante los despliegues de la dependencia. Da
    tres hipótesis ordenadas. 🔴
23. Diseña la política de conexiones y resolución del chassis del equipo, con los valores que
    dependen de la plataforma. 🔴
24. Tu sistema va a migrar a gRPC. Escribe la lista de comprobaciones de infraestructura previas y
    qué harías si alguna falla. 🔴

---

**Anterior:** — · **Siguiente:** [`02` — API gateway y BFF](02-api-gateway-y-bff.md) ·
**Relacionado:** [`03` — Resiliencia en la práctica](03-resiliencia-en-la-practica.md) ·
[`02-comunicacion/03`](../02-comunicacion/03-grpc.md)

**Taller, opcional:** [`06/05` — Resiliencia en tres plataformas](../06-talleres/05-resiliencia-en-tres-plataformas.md).
