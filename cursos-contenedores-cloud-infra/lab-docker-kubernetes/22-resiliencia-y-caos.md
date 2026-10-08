# 🔥 Fase 22 — Resiliencia y caos: el vecino lento, y lo que no te dice Kubernetes

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 22 de 27 · Parte IV — El lab de patrones distribuidos · **media**
> **Perfil:** el cluster `lab`, con los valores de `minimo` · **Observabilidad encendida:** ninguna (las cuentas salen del generador y del `/metrics` de `inventory`)
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: el caos y las respuestas viven en el cluster
> **Servicios que toca:** `inventory`, y `catalog` como víctima · **Paso de generación:** G9 · Resiliencia
> **Depende de:** [Fase 21](21-diagnostico.md) · **Habilita:** [Fase 23](23-grpc-y-el-balanceo.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna con identificador; las de esta fase quedan en sus secciones
> **Apéndices de apoyo:** [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** ver con números cómo un vecino lento tumba lo que no depende de él, y defender a `inventory` con timeouts, reintentos con espera y un circuit breaker, sabiendo lo que cada uno cuesta.

---

## 🧭 1. Dónde estamos

La Parte IV abre con la tesis del curso dicha sin rodeos: **nada de lo que sigue lo resuelve Kubernetes**. El
orquestador reinicia lo que muere y reparte el tráfico entre lo que está listo. Lo que no hace es decidir cuánto
esperar a un vecino que contesta despacio, cuántas veces volver a preguntarle, ni cuándo dejar de llamarlo.

La historia trae dos escenas. La droguería de Sogamoso, que tarda doce segundos en contestar si tiene un producto
(historia §6). Y la noche del 14 de octubre, en la que Contingencia no se prendió porque su regla era "encenderse
si el Siga no contesta", y el Siga contestaba, solo que tardaba un minuto (§1.14). En las dos, el problema no es
el que se cae: es el que **tarda**. Germán lo dice en la reunión de la Parte IV:

> *"Lo que nos tumbó no fue un servidor caído. Fue uno lento, y todos esperándolo. ¿Esto lo arregla el
> orquestador, o lo tiene que arreglar cada equipo en su código?"*

Esta fase contesta con medidas, y la respuesta es incómoda: **las dos cosas, y cada una tiene su costo**.

---

## 🎯 2. Objetivos de esta fase

1. Construir el generador de caos del curso, en Go, y ponerlo entre `inventory` y `catalog`.
2. Medir la cascada: un vecino lento que se contagia a lo que no lo usa.
3. Generar G9: timeouts, reintentos con espera creciente y al azar, y un circuit breaker en `inventory`.
4. Medir lo que cada respuesta hace bien, y lo que cuesta: el reintento que empeora, y el circuito que corta de
   más.
5. Contestar la pregunta de la Parte IV: ¿esto va en tu código o en la plataforma?

---

## 🚫 3. Qué NO entra todavía

- **Reintentar un `POST`.** El aviso a `replenish` tiene timeout pero no reintentos: reintentarlo puede pedir dos
  reposiciones. Hacerlo seguro es la idempotencia → [Fase 26](26-idempotencia-y-outbox.md).
- **El mesh**, que hace reintentos y circuitos sin tocar el código → [a10](a10-service-mesh.md). Se nombra en la sección 5.6.
- Límites de concurrencia (*bulkheads*) y de tasa: existen, y el ejercicio 19 los mide.
- El caos en `pricing`: desde la [Fase 19](19-tls-y-certificados.md) habla mTLS, y el generador no. Se usa con `catalog`.

---

## 🧨 4. El problema, en el laboratorio

`inventory` en G8: sin ningún timeout propio, como la [Fase 16](16-escalado-y-rollout.md) lo dejó a propósito. k6 hace cincuenta ventas por
segundo (pasan por `catalog`) y, al mismo tiempo, diez lecturas por segundo de existencias, que **no tocan a ningún
vecino**: `inventory` las contesta con su base. Sesenta segundos sin fallas, y sesenta con cinco segundos de latencia
inyectados en `catalog`:

```text
## sin fallas
 { scenario:existencias }: med=3.71ms p(95)=17.61ms max=302.79ms     0 de 600 fallidas
 { scenario:ventas }:      med=25.41ms p(95)=73.41ms max=1.57s       0 de 2998
## con 5 s de latencia en catalog
 { scenario:existencias }: med=2.39s p(95)=5.54s max=6.01s           37 de 557 fallidas (6,6 %)
 { scenario:ventas }:      med=7.22s p(95)=10.56s max=11.1s          180 de 2587 (7,0 %)
```

**Las lecturas de existencias, que no usan `catalog`, pasaron de 17 ms a 5,5 s en el p95**, y una de cada quince
falló. Es la cascada: cincuenta ventas por segundo que esperan cinco segundos cada una son 250 peticiones en vuelo,
y Tomcat atiende con doscientos hilos. Cuando todos esperan a `catalog`, la lectura de existencias no consigue hilo,
y espera también. El vecino lento no tumbó la venta: tumbó a `inventory` entero.

Y Kubernetes no vio nada. Los pods siguieron listos (la readiness pregunta por la base, no por los vecinos: la
[Fase 15](15-salud-y-recursos.md) lo decidió así, justamente para evitar una cascada de otro tipo), nadie se reinició, ninguna métrica de CPU subió.

> 🩻 **Esto sí funciona igual.** Un timeout es un timeout, en compose, en un servidor o en un cluster. La cascada de
> esta sección pasaría idéntica con dos contenedores en compose: es un problema del código que llama, no de dónde
> corre.

---

## 🧩 5. El caos, y las respuestas

### 5.1 El generador de caos

`src/lab/chaos/` es el generador del curso: unas 150 líneas de Go, solo biblioteca estándar, generado como los
servicios. Es un proxy inverso que se pone entre un servicio y su vecino, y le hace al tráfico lo que se le pida:

```go
type faults struct {
	LatencyMs        int `json:"latencyMs"`        // cuánto demorar…
	LatencyPercent   int `json:"latencyPercent"`   // …y a qué porcentaje
	ErrorPercent     int `json:"errorPercent"`     // un 503 sin pasarle nada al vecino
	MalformedPercent int `json:"malformedPercent"` // un 200 con JSON cortado a la mitad
	HangPercent      int `json:"hangPercent"`      // no contestar nunca
}
```

Se enciende con el chart (`global.chaos.enabled`): un `Deployment` `chaos` en `apps`, y `inventory` con
`CATALOG_URL` apuntando a él en lugar de a `catalog`. Las fallas se cambian en caliente, sin redesplegar, y llevan
nombre de ciudad, como los cuenta la historia:

```bash
task chaos:on                                      # construye, carga y lo pone en el medio
task chaos:set -- latencyMs=5000 latencyPercent=100
task chaos:set -- perfil sogamoso-con-lluvia       # la mitad tarda 3 s y un 20 % falla
task chaos:set -- show                             # la configuración, y lo que lleva contado
task chaos:off
```

El generador cuenta todo lo que recibe, y esa cuenta es la evidencia de esta fase: cuántas veces le preguntó
`inventory` a `catalog` por cada venta.

### 5.2 G9: el timeout que no estaba

El prompt de G9 está en [a03](a03-contratos-y-prompts-de-generacion.md#-el-prompt-de-g9-y-el-del-generador-de-caos). La primera respuesta es la más barata: **no esperar para siempre**. Dos
timeouts en el cliente HTTP de cada vecino: uno para conectar (1 s) y otro para esperar la respuesta (2 s).

```java
HttpClient.Builder http = HttpClient.newBuilder().connectTimeout(CONNECT_TIMEOUT);   // 1 s
JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(http.build());
factory.setReadTimeout(READ_TIMEOUT);                                                 // 2 s
```

¿Por qué dos segundos? Porque el p95 de la venta sana es de 73 ms y el de una lectura a `catalog`, mucho menos: dos
segundos es treinta veces lo normal, y menos que los 15 s con que la puerta corta. Un timeout se elige mirando la
latencia del vecino, no con un número redondo.

### 5.3 Reintentar, y el reintento que empeora

Si un vecino falla de vez en cuando, preguntar otra vez a veces funciona. El reintento ingenuo —volver a preguntar
enseguida, tres veces más— parece gratis. Con el 50 % de errores inyectados en `catalog` y treinta segundos a diez
ventas por segundo, el generador contó cuántas peticiones le llegaron por cada venta:

```text
## ingenuo: 4 intentos, sin espera, sin circuito
 { scenario:ventas }: med=30.59ms p(95)=57.48ms     20 de 301 fallidas (6,6 %)
catalog recibió 558 peticiones para 301 ventas: 1.85 por venta
## sin reintentos (1 intento), sin circuito
 { scenario:ventas }: med=22.19ms p(95)=55.07ms     150 de 301 fallidas (49,8 %)
catalog recibió 301 peticiones para 301 ventas: 1.0 por venta
```

Los reintentos salvaron ventas: del 50 % de fallas al 6,6 % (la cuenta da 0,5⁴ = 6,25 %). Y le pusieron a `catalog`
**1,85 veces la carga**. Si `catalog` falla porque está ahogado, ese 85 % de más es lo que lo termina de ahogar: el
reintento que empeora. Por eso G9 reintenta distinto:

```java
RetryConfig.custom()
    .maxAttempts(3)                                                         // el original y dos más
    .intervalFunction(IntervalFunction.ofExponentialRandomBackoff(100 ms, 2.0, 0.5))  // 100, 200… ms, al azar
    .retryOnException(e -> e instanceof RestClientException && !(e instanceof HttpClientErrorException))
```

Espera creciente (*backoff*), para darle aire al vecino; al azar (*jitter*), para que cien clientes no vuelvan
todos en el mismo milisegundo; y nunca un 4xx, que es una respuesta, no una falla. Solo las lecturas: el `POST` del
aviso no se reintenta (sección 3).

Y un detalle que se pasa por alto: **los reintentos gastan el tiempo de quien espera afuera**. Tres intentos de hasta
dos segundos, con sus esperas, son unos seis segundos y medio en el peor caso (la sección 5.6 lo mide: 6,36 s). La
puerta corta a los 15. Si `inventory` reintentara cinco veces, el cliente recibiría el 504 de la puerta mientras
`inventory` sigue intentando, y la venta podría registrarse cuando ya nadie la espera: la escena de la [Fase 21](21-diagnostico.md). Los
timeouts tienen que **decrecer hacia adentro**: el de la puerta, mayor que todo lo que `inventory` puede tardar con
sus reintentos; el de `inventory` con cada vecino, mayor que lo que tarda el vecino sano. Se llama presupuesto de
tiempo, y cada salto gasta una parte.

### 5.4 El circuit breaker: dejar de llamar

Un vecino caído no mejora porque le pregunten más. El **circuit breaker** cuenta las últimas llamadas y, cuando
fallan demasiadas, **deja de llamar**: contesta "no disponible" al instante, sin tocar al vecino, durante un rato.
Después deja pasar unas pocas de prueba; si salen bien, vuelve a llamar normal. En G9, con Resilience4j (el núcleo,
sin su integración con Spring, para que las reglas se vean en `Guard.java`):

```java
CircuitBreakerConfig.custom()
    .failureRateThreshold(50)                 // la mitad de…
    .slidingWindowSize(20)                    // …las últimas veinte llamadas (con al menos diez)
    .waitDurationInOpenState(10 s)            // abierto, diez segundos
    .permittedNumberOfCallsInHalfOpenState(3) // y después, tres de prueba
```

Con el 100 % de errores en `catalog`, diez ventas por segundo, y la cuenta del generador cada dos segundos:

```text
    0 s  catalog recibió   0  circuito open
    6 s  catalog recibió   0  circuito open
    8 s  catalog recibió   3  circuito open
   10 s  catalog recibió   0  circuito open
   …
   19 s  catalog recibió   3  circuito open
   …
   29 s  catalog recibió   3  circuito open
 { scenario:ventas }: med=4.79ms p(95)=25.01ms       401 de 401 fallidas
```

Cada diez segundos, exactamente tres llamadas de prueba; el resto del tiempo, **cero**. Las ventas fallan, como
tienen que fallar con `catalog` caído, pero en 4,8 ms y no en 15 s, y sin ocupar un hilo de Tomcat cada una. El estado
del circuito queda en `/metrics` (`resilience4j_circuitbreaker_state`), donde Prometheus lo puede leer.

### 5.5 La cascada, con G9

La misma prueba de la sección 4 —cinco segundos de latencia en `catalog`, cincuenta ventas por segundo, diez lecturas
de existencias— con `inventory:g9`:

```text
 { scenario:existencias }: med=3.59ms p(95)=10.9ms max=47.17ms       0 de 601 fallidas
 { scenario:ventas }:      med=3.21ms p(95)=14.75ms max=2.15s        2972 de 2972 fallidas
catalog recibió 89 peticiones en el minuto
```

**La cascada desapareció**: las existencias, con un p95 de 10,9 ms, igual que sin caos. Las ventas fallan todas, y
rápido: el timeout de 2 s cortó las primeras, el circuito se abrió, y desde ahí `inventory` dejó de esperar.
`catalog` recibió 89 peticiones en un minuto, contra 2.972 ventas.

Es la mejor versión de un mal día: lo que depende de `catalog` falla, y nada más.

### 5.6 Lo roto y lo mudo

El generador tiene dos fallas más, que la cascada no usa y que conviene ver una vez con G9 encendido, una venta cada
una:

```text
### malformada al 100 %   (un 200 con JSON cortado a la mitad)
503 en 0.719643s · {"message":"catalog no contesta","error":"unavailable"}
"malformed":3,"received":3
### colgado al 100 %      (no contestar nunca)
503 en 6.359110s · {"message":"catalog no contesta","error":"unavailable"}
"hung":3
```

**La respuesta rota se reintentó**: tres intentos, tres JSON cortados. Para `inventory`, un cuerpo que no se puede leer
es un error de cliente HTTP como cualquier otro, y `Guard` lo trata igual que un 503. ¿Está bien? Depende de por qué
llega roto: si es una red que corta, el reintento tiene sentido; si es un `catalog` que serializa mal, los tres
intentos van a dar lo mismo, y el reintento solo suma carga. El código no puede distinguir los dos casos sin que el
contrato le diga más (un `Content-Length` que no coincide, un código de error propio).

**El silencio costó seis segundos**: tres intentos de dos segundos cada uno, el timeout de lectura completo cada vez.
Es el peor caso de G9 para una venta individual, y es la razón de la sección 5.4: a partir de ahí, el circuito se abre
y las siguientes no esperan nada. Sin timeouts, la misma venta habría esperado hasta que la puerta cortara a los 15 s,
o para siempre si el cliente fuera otro servicio.

Las dos son la misma lección con otro disfraz: un vecino puede fallar de formas que no son "no contesta", y cada forma
pide una respuesta distinta. El generador está para probarlas antes de que lleguen solas.

### 5.7 ¿Tu código o la plataforma?

La puerta ya tenía un timeout, que nadie configuró: Envoy corta a los 15 s (el `504` de la [Fase 20](20-seguridad-del-pod-y-de-la-red.md)). Gateway API
permite fijarlo por ruta, y un service mesh pone timeouts, reintentos y circuitos entre todos los servicios sin
tocar el código ([a10](a10-service-mesh.md)). Entonces, ¿para qué G9?

Porque la plataforma ve **conexiones**, y el código ve **operaciones**. La puerta puede cortar a los 15 s, pero no
sabe que la lectura de existencias no debía esperar a `catalog`: la cascada de la sección 4 pasó **detrás** de la
puerta, en los hilos de `inventory`. Un mesh puede reintentar un `GET` a `catalog`, pero no sabe que el `POST` a
`replenish` no se reintenta, ni qué contestar cuando el circuito está abierto (aquí, un 503 con un mensaje que dice
cuál vecino). Y la plataforma no puede elegir el timeout de cada operación mejor que quien la escribió.

La respuesta honesta es **las dos**: la plataforma pone el piso (que nada espere para siempre, en ningún lado), y el
código pone lo que solo él sabe (qué operación es segura de repetir, cuánto puede esperar, qué hacer cuando no hay
vecino). Sin el piso, un servicio que se olvida de sus timeouts tumba a los demás; sin el código, el piso corta tarde
y a ciegas.

---

## 🔁 6. Los otros tres

G9 es solo de `inventory`, porque es el único que llama a otros por trabajo de negocio. Pero los otros tres también
**reciben** llamadas, y la sección 4 cambia cómo conviene pensarlos: `catalog` ahogado por los reintentos de otro
no tiene cómo defenderse, salvo limitar cuánto atiende a la vez. PHP-FPM ya lo hace sin querer: atiende cinco peticiones a la vez
por pod, y las demás esperan en la cola de nginx (la [Fase 16](16-escalado-y-rollout.md) lo midió como capacidad). `pricing` y `replenish` atienden lo
que les llegue hasta quedarse sin memoria. Limitarlos es un ejercicio.

El `storefront` tiene su propio vecino lento: la página le pide a la API desde el navegador, y un `fetch` del
navegador tampoco tiene timeout por defecto. Otro ejercicio.

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"si un servicio falla, el orquestador lo reinicia; y si es lento, se escala"*. Las
apuestas, escritas antes de ejecutar:

> 🪞 **Apuesta antes de ejecutar.** Sin timeouts, con 5 s de latencia inyectados en `catalog` y 50 ventas/s, las lecturas
> de existencias de `inventory` (que no tocan `catalog`) pasan de un p95 menor de 50 ms a más de 1 s.
>
> **Resultado: ganada:** de 17,6 ms a 5,54 s, con un 6,6 % de fallas (sección 4).

> 🪞 **Apuesta antes de ejecutar.** Con 50 % de errores en `catalog` y tres reintentos inmediatos, `catalog` recibe más
> de 1,7 peticiones por venta.
>
> **Resultado: ganada:** 1,85 (sección 5.3).

> 🪞 **Apuesta antes de ejecutar.** Con el circuito abierto, la venta falla en menos de 10 ms y `catalog` no recibe
> ninguna petición mientras dura.
>
> **Resultado: ganada:** mediana de 4,8 ms, y cero peticiones entre las tres de prueba de cada diez segundos
> (sección 5.4).

Las entradas están en [INSTINTOS.md](INSTINTOS.md#si-es-lento-el-orquestador-lo-escala).

---

## 📏 8. Lo que cuesta cada respuesta

Las tres apuestas se ganaron, y la medición que más enseña es la que nadie apostó. Con el 50 % de errores en
`catalog`, treinta segundos a diez ventas por segundo, las tres configuraciones de `inventory`:

| `inventory` | Ventas fallidas | Peticiones a `catalog` por venta |
|---|---|---|
| sin reintentos ni circuito | 49,8 % | 1,00 |
| reintentos ingenuos (4 intentos, sin espera) | 6,6 % | 1,85 |
| **G9** (3 intentos con espera, circuito al 50 %) | **95,7 %** | **0,09** |

**G9 dejó fallar casi todas las ventas.** Con la mitad de las llamadas fallando, el circuito llega a su umbral (50 %)
y se abre; abierto, rechaza todo, también la mitad que habría salido bien. Protegió a `catalog` como ninguna otra
(0,09 peticiones por venta) y le costó a La Vecina casi todas sus ventas. Con el perfil *Sogamoso con lluvia* (la
mitad tarda 3 s, un 20 % falla), lo mismo: el 87 % de las ventas, fallidas, porque 3 s supera el timeout de 2 s y cada
espera cuenta como falla.

No hay configuración gratis. El circuito de G9 está bien para un vecino **caído**, y es demasiado agresivo para uno
**degradado**. Un umbral más alto, una ventana más larga o un timeout más generoso cambian el reparto entre "protejo
al vecino" y "vendo lo que pueda", y esa es una decisión de negocio que la tabla deja ver, no una que resuelva el
código solo.

---

## ⚰️ 9. Autopsia: reintentar tres veces, sin esperar

**La decisión, con su mejor argumento.** Envolver cada llamada a un vecino en un bucle de tres reintentos inmediatos.
*"Los errores son pasajeros. Si el vecino falla, que pruebe otra vez: el usuario ni se entera."*

**Por qué era razonable.** Para errores pasajeros y aislados, funciona: con el 50 % de errores, bajó las ventas
fallidas del 49,8 % al 6,6 %. Es lo que hace cualquier biblioteca con la configuración por defecto equivocada.

**Qué pasó después, con número.** Esos reintentos le llevaron a `catalog` **1,85 peticiones por venta**. Si `catalog`
falla porque está sobrecargado —el caso más común de un 503 en una quincena—, el 85 % de carga de más es exactamente
lo que lo mantiene caído: cada cliente que reintenta empuja al vecino más abajo, y el vecino nunca se recupera
mientras haya tráfico. Y sin timeout, cada reintento a un vecino lento es otro hilo esperando: la cascada de la
sección 4, multiplicada.

**Cuánto cuesta salir, con número.** Espera creciente y al azar entre intentos, un circuito que deja de llamar, y
timeouts: con los tres, `catalog` recibió 0,09 peticiones por venta, y la cascada desapareció. A cambio, la sección 8:
con un circuito agresivo, las ventas que habrían salido bien también fallan.

**Qué lo habría cambiado.** Contar cuántas veces le preguntas a un vecino por cada operación del negocio, y ponerlo en
un tablero. Un reintento que no se cuenta es una carga que nadie ve.

**Antes y después, con números:** reintentos ingenuos, 1,85 peticiones por venta y 6,6 % de fallas; G9, 0,09 y 95,7 %,
con la cascada desaparecida. Ninguna de las dos es "la buena": la sección 8 dice por qué.

---

## 📖 10. Traducción

| En compose o en un servidor | En Kubernetes | Lo que cambia |
|---|---|---|
| el timeout del pool del servidor de aplicaciones | el timeout del cliente HTTP, en el código | nadie lo pone por ti: sin él, se espera para siempre |
| `restart: on-failure` | el reinicio del kubelet | reinicia lo que muere, no lo que tarda |
| el balanceador que saca un nodo que no contesta | la readiness, y un circuit breaker en quien llama | la readiness mira al pod; el circuito, a la operación |
| el reintento del cliente de la base | el reintento en el código, o el de un mesh | el mesh no sabe qué operación es segura de repetir |
| — | Gateway API `timeouts` por ruta, y un mesh ([a10](a10-service-mesh.md)) | el piso de la plataforma: que nada espere para siempre |

Y al revés: un `VirtualService` con `retries` en un cluster con mesh es, sin mesh, un bucle de reintentos en cada
cliente, con los mismos riesgos de la sección 9. Las filas completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, los balanceadores del proveedor y los mesh gestionados ofrecen timeouts y reintentos por
configuración, y conviene usarlos como piso. El circuito y la decisión de qué reintentar siguen siendo del código.

---

## 🩺 11. Incidentes de esta fase

La fase no reserva incidentes. Sus roturas son el caos mismo, y vuelven en los ejercicios con los perfiles de ciudad.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Un circuit breaker es un apagón voluntario.** Abierto, rechaza también lo que habría funcionado. Para un vecino
caído, es lo correcto; para uno degradado, puede costar más ventas que el problema (sección 8). Se configura mirando
qué prefiere el negocio, y se vigila.

**Los reintentos multiplican.** Cada nivel que reintenta multiplica la carga del de abajo: tres servicios en cadena,
cada uno con tres intentos, son veintisiete peticiones al último. Se reintenta en **un** lugar, con espera, y se cuenta.

**Un timeout mal elegido es peor que ninguno.** Demasiado corto, convierte un vecino lento en uno caído (el perfil de
Sogamoso); demasiado largo, no evita la cascada. Se elige con la latencia medida del vecino.

**Cuándo NO G9 entero:** un servicio que no llama a nadie (como `pricing`); una llamada que no se puede reintentar (un
`POST` sin idempotencia, [Fase 26](26-idempotencia-y-outbox.md)). **Cuándo sí:** toda llamada síncrona a otro servicio, con timeout siempre, y el
resto según la operación.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso con conexiones de red. El orquestador te
dio reinicios, réplicas, una puerta con un timeout de 15 s, y un lugar donde poner un mesh. **Te tocó a ti** cuánto
esperar a cada vecino, qué reintentar y cómo, cuándo dejar de llamar, y decidir cuántas ventas vale proteger a
`catalog`.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`task chaos:set` dice `no se pudo llegar al generador`.** El caos no está encendido (`task chaos:on`), o el
`port-forward` no alcanzó a abrir.

**Las ventas siguen pasando con el caos encendido.** `inventory` no apunta al generador: mira su `CATALOG_URL` en el
`Deployment` (`kubectl -n apps get deploy inventory -o yaml`).

**El circuito no se cierra después de `chaos:set -- clear`.** Espera el tiempo de abierto (10 s) y las tres llamadas de
prueba: necesita ventas para probar.

**Las variables `LAB_RESILIENCE_*` no cambian nada.** Spring las lee al arrancar: el `set env` reinicia el pod, y
`task deploy` las quita.

---

## 📋 14. Checklist de validación

```text
[ ] task chaos:on y task chaos:set -- show, con las cuentas en cero
[ ] la cascada sin G9: las existencias por encima del segundo con 5 s de latencia en catalog
[ ] task conformance TARGET=cluster PROFILE=lab -- G5 y G8, con inventory:g9
[ ] la cascada con G9: las existencias como sin caos
[ ] los reintentos: 1,85 por venta los ingenuos, y la tabla de la sección 8
[ ] el circuito abierto: cero peticiones entre las de prueba
[ ] task chaos:off
```

---

## 🧪 15. Ejercicios (20)

La mitad de medición. Todos con el generador encendido (`task chaos:on`) y apagado al terminar.

## 🟢 Fácil — el generador (1–6)

### 🟢 Ejercicio 1 — Encender y mirar
Enciende el generador y haz una venta. Mira las cuentas.

**Criterio:** `received` y `forwarded` en 1 (o 2, si la venta pasa por `catalog` una vez y la suite otra).

<details><summary>Solución</summary>

`task chaos:on`, una venta por la puerta, `task chaos:set -- show`.
</details>

### 🟢 Ejercicio 2 — Un error de cada dos
Con `errorPercent=50`, haz veinte ventas una por una.

**Criterio:** cuántas fallaron, y el mensaje de las que fallaron.

<details><summary>Solución</summary>

Con G9, al principio pocas (los reintentos las salvan) y, cuando el circuito se abre, casi todas, con `catalog no
disponible (circuito abierto)`.
</details>

### 🟢 Ejercicio 3 — La respuesta rota
Con `malformedPercent=100`, haz una venta. ¿Qué devuelve `inventory`?

**Criterio:** el estado y el mensaje, y la línea del log de `inventory` que lo explica.

<details><summary>Solución</summary>

El JSON cortado no se puede leer: un 503 "catalog no contesta", con el error de conversión en el log. Y se reintenta:
mira por qué en `Guard.java`.
</details>

### 🟢 Ejercicio 4 — Colgarse
Con `hangPercent=100`, haz una venta y mide cuánto tarda en fallar.

**Criterio:** unos dos segundos por intento, y por qué.

<details><summary>Solución</summary>

El timeout de lectura (2 s) por cada uno de los intentos, más la espera entre ellos, hasta que el circuito se abre.
</details>

### 🟢 Ejercicio 5 — El circuito en `/metrics`
Lee el estado del circuito de `catalog` en el `/metrics` de `inventory`, con el caos apagado y con el 100 % de errores.

**Criterio:** `closed` en uno, `open` en el otro.

<details><summary>Solución</summary>

`resilience4j_circuitbreaker_state{name="catalog"}`, la línea con `1.0`. Desde un pod de `apps` (las políticas de la
[Fase 20](20-seguridad-del-pod-y-de-la-red.md)).
</details>

### 🟢 Ejercicio 6 — Los perfiles
Prueba los tres perfiles de ciudad con el tráfico de fondo y anota el porcentaje de ventas fallidas de cada uno.

**Criterio:** la tabla, y cuál te sorprendió.

<details><summary>Solución</summary>

*Girón un martes*, ninguna; *Sogamoso con lluvia*, la mayoría (sección 8); *Bogotá en quincena* (800 ms y 5 %), pocas:
la latencia está por debajo del timeout.
</details>

## 🟡 Intermedio — ajustar (7–12)

### 🟡 Ejercicio 7 — Un circuito para un vecino degradado
Ajusta el circuito para que, con *Sogamoso con lluvia*, se pierdan menos del 30 % de las ventas.

**Criterio:** la configuración y la medida, y cuánta carga le llega a `catalog`.

<details><summary>Solución</summary>

Subir el timeout por encima de los 3 s del perfil, o el umbral del circuito, o la ventana. Cada uno cambia el reparto
entre ventas y carga: la medida lo dice.
</details>

### 🟡 Ejercicio 8 — El timeout de la puerta
Fija un timeout de 3 s para la ruta de `inventory` en su `HTTPRoute` y repite la cascada con `inventory:g8`.

**Criterio:** el efecto en las ventas y en las existencias.

<details><summary>Solución</summary>

`timeouts.request: 3s`. Las ventas fallan antes para el cliente, y la cascada **sigue**: los hilos de `inventory` siguen
esperando a `catalog`. Es la sección 5.6.
</details>

### 🟡 Ejercicio 9 — El caos en `replenish`
Pon el generador entre `inventory` y `replenish` y haz una venta que pida reposición con `hangPercent=100`.

**Criterio:** la venta sale bien, y qué pasa con el aviso.

<details><summary>Solución</summary>

`global.chaos.target=replenish`. La venta no espera el aviso (G5); el aviso falla por timeout a los 2 s y queda en el
log, sin reintento. ¿Se perdió? Esa es la [Fase 25](25-la-coreografia.md).
</details>

### 🟡 Ejercicio 10 — Contar en el tablero
Con las métricas encendidas, haz un panel con las peticiones a `catalog` por cada venta.

**Criterio:** el panel en el JSON del chart, con datos durante un reintento ingenuo.

<details><summary>Solución</summary>

`sum(rate(http_server_requests_seconds_count{service="catalog",uri="/products/{sku}"}[1m])) / sum(rate(lab_sales_total[1m]))`
(o contra las ventas intentadas: el contador de `/sales`).
</details>

### 🟡 Ejercicio 11 — El *jitter*
Mide la diferencia entre reintentos con espera fija y con espera al azar, con diez clientes a la vez y `catalog` al
100 % de errores durante 5 s y después sano.

**Criterio:** la forma de la carga en `catalog` en el segundo siguiente a la recuperación.

<details><summary>Solución</summary>

Con espera fija, los reintentos llegan en oleadas; con *jitter*, repartidos. La cuenta del generador por segundo lo
muestra.
</details>

### 🟡 Ejercicio 12 — El `fetch` del navegador
Haz que la página del `storefront` deje de esperar a la API a los 3 s, con un mensaje.

**Criterio:** con *Sogamoso con lluvia*, la página muestra el mensaje en lugar de quedarse cargando.

<details><summary>Solución</summary>

`AbortSignal.timeout(3000)` en el `fetch`, y el mensaje en el `catch`. Es G9 del lado del cliente.
</details>

## 🟠 Difícil — diagnosticar (13–17)

### 🟠 Ejercicio 13 — ¿Quién está lento?
Alguien encendió un perfil de ciudad sin decírtelo. Encuentra cuál y en qué vecino, sin mirar el generador.

**Criterio:** el perfil, con la evidencia de `inventory` y sus métricas.

<details><summary>Solución</summary>

Los tiempos de las ventas, el log de `inventory` (timeouts o 503), y `resilience4j_*` en `/metrics`.
</details>

### 🟠 Ejercicio 14 — El circuito que no abre
Configura el circuito con una ventana de 100 llamadas y repite la sección 5.4 a diez ventas por segundo. **Predice** cuánto
tarda en abrir.

**Criterio:** el tiempo medido, y cuántas ventas lentas pasaron mientras tanto.

<details><summary>Solución</summary>

Necesita al menos diez llamadas (`minimumNumberOfCalls`) y la mitad fallando en la ventana: con 100 y fallas al 100 %,
abre rápido; con fallas al 50 %, tarda lo que tarda en llenarse.
</details>

### 🟠 Ejercicio 15 — Reintentos en cadena
Agrega reintentos ingenuos también en la llamada de `inventory` a `pricing`, y pon el caos entre `pricing` y su base (o
simúlalo con latencia en `pricing`). Cuenta.

**Criterio:** las peticiones que llegan al último eslabón por venta.

<details><summary>Solución</summary>

La multiplicación de la sección 12: cada nivel que reintenta multiplica al de abajo.
</details>

### 🟠 Ejercicio 16 — La venta que se registró
Con G8 (sin timeouts) y `catalog` colgado, reproduce la venta de la [Fase 21](21-diagnostico.md) que el cliente vio fallar y se registró
dos minutos después. Repite con G9.

**Criterio:** la venta registrada con G8, y lo que pasa con G9.

<details><summary>Solución</summary>

Con G9, el timeout corta antes de registrar: la venta falla de verdad. Pero si el timeout ocurre **después** de
descontar la existencia, el problema vuelve: la [Fase 26](26-idempotencia-y-outbox.md).
</details>

### 🟠 Ejercicio 17 — El generador en `pricing`
Pon el generador entre `inventory` y `pricing`. ¿Qué tienes que cambiar, y qué se pierde?

**Criterio:** la venta pasando por el generador, y la frase sobre el mTLS.

<details><summary>Solución</summary>

El generador no habla mTLS: o `inventory` le habla en HTTP (se apaga G8 para esa llamada), o el generador presenta y
verifica certificados. Es el mismo problema que resuelve un mesh: el proxy en el medio tiene que ser parte del mTLS.
</details>

## 🔴 Muy difícil — medir y diseñar (18–20)

### 🔴 Ejercicio 18 — La tabla de la sección 8, completa
Mide la tabla de la sección 8 con 10, 30 y 50 % de errores, y con tres configuraciones de circuito.

**Criterio:** la tabla, tres corridas por celda, y una recomendación para `inventory` escrita como decisión.

**Rúbrica:** las mismas condiciones en todas las celdas; la dispersión dicha; y la recomendación con lo que se pierde.

### 🔴 Ejercicio 19 — Un *bulkhead*
Limita a veinte las llamadas simultáneas de `inventory` a `catalog` y repite la cascada **sin** timeouts.

**Criterio:** las existencias sin cascada aunque las ventas esperen.

**Rúbrica:** el *bulkhead* separa los hilos que esperan a `catalog` de los demás; con timeouts y sin él, cuál alcanza; y
qué pasa con la venta número 21.

### 🔴 Ejercicio 20 — ¿Tu código o la plataforma?
Escribe para Germán la recomendación de la sección 5.6 aplicada a los cuatro servicios: qué va en la plataforma, qué en
cada servicio, y qué se mide para saber que funciona.

**Criterio:** una página, con una tabla por servicio y la medida que la respalda.

**Rúbrica:** el piso de la plataforma (timeouts en la puerta, y un mesh si lo hay); lo que solo el código sabe; y las
mediciones de esta fase como evidencia.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Resilience4j, *CircuitBreaker* y *Retry*: https://resilience4j.readme.io/docs/circuitbreaker
- Gateway API, *HTTP timeouts*: https://gateway-api.sigs.k8s.io/guides/user-guides/http-timeouts/
- Envoy, *Circuit breaking* (lo que hace la plataforma): https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/circuit_breaking
- AWS Builders' Library, *Timeouts, retries, and backoff with jitter*: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/

**Libros y ensayos**

- Michael T. Nygard, *Release It!*, 2.ª edición (2018): los capítulos de patrones de estabilidad (timeouts, circuit
  breaker, bulkheads).
- Betsy Beyer y otros (eds.), *Site Reliability Engineering* (2016), *Addressing Cascading Failures*:
  https://sre.google/sre-book/addressing-cascading-failures/

**Orden de lectura sugerido:** antes, *Addressing Cascading Failures* (la sección 4 con otras palabras); durante, el
artículo de AWS con la sección 5.3 delante; después, los patrones de estabilidad de Nygard.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 22 (cluster lab, valores de minimo)

  apps       inventory en :g9 (Guard.java: timeouts 1 s / 2 s, 3 intentos con espera, circuito al 50 %);
             el resto como en la Fase 20
  chaos      src/lab/chaos/ (Go) y el subchart chaos, apagado (global.chaos.enabled);
             task chaos:on | off | set, con los perfiles de ciudad
  bench/f22  cascada.js
```

> **La señal de que quedó bien:** *"Cuando un vecino se pone lento, lo que no depende de él sigue funcionando; sé
> cuántas veces le pregunto por cada venta, y puedo explicarle a Germán qué ventas se pierden para proteger a
> `catalog`."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, las suites pasando y `git status` limpio:
>
> ```bash
> git tag -a fase-22-resiliencia-y-caos -m "F22 cerrada: el generador de caos en Go con perfiles de ciudad; G9, timeouts, reintentos con espera y circuit breaker en inventory; la cascada medida, el reintento que empeora y el circuito que corta de más"
> ```
>
> Commits con prefijo `f22:`.

---

## 📌 Pendientes sugeridos

- **F23:** el tiempo de cada salto de la venta, que aquí se dedujo de las cuentas del generador.
- **F26:** la venta que el cliente dio por fallida y se registró igual (la [Fase 21](21-diagnostico.md), sección 4): con timeouts ya no
  espera dos minutos, pero un timeout del cliente con la venta a medio hacer sigue siendo posible.
- **`a10`:** los mismos timeouts y circuitos, puestos por un mesh.
