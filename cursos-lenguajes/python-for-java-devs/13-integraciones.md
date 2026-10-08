# 🌐 Fase 13 — Integraciones

> Python para desarrolladores Java senior · Fase 13 de 18 · Bloque C
> Depende de: Fase 12 · Habilita: Fase 14
> Registro de esta fase: **aplicación**
> Proyecto que avanza: AgendaAPI · **sale a hablar con el mundo**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Hablar con sistemas que no controlas sin que un fallo ajeno se convierta en un error propio — ni,
mucho peor, en un cobro duplicado.

Todo lo que construiste hasta ahora vive dentro de tu proceso y de tu base de datos: si algo falla,
es culpa tuya y lo arreglas tú. A partir de aquí hay del otro lado un socio que responde en seis
segundos, uno que devuelve `500` una de cada tres veces, y uno que responde `200` y no procesa
nada. Ninguno de los tres es hipotético.

Y la idea que ordena la fase no es un apartado: **es la idempotencia**. El reintento sobre una
operación que no es idempotente es exactamente cómo se le cobra dos veces a un paciente, y en
Áurea eso no es una métrica degradada: es una llamada a Clara, la mamá del paciente, un sábado.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Configuras un cliente HTTP con timeouts **en las cuatro capas**, y sabes qué cubre cada uno.
- [ ] Sabes qué se reintenta y —más importante— **qué no**.
- [ ] Puedes explicar por qué un timeout **no es una cancelación**, con el número que lo demuestra.
- [ ] Diseñas las dos puntas de un webhook: emisor con reintento y receptor idempotente.
- [ ] Firmas lo que emites y verificas lo que recibes, con comparación en tiempo constante.
- [ ] Tienes el número de cuántas notificaciones se pierden y cuántas se duplican, con y sin
      defensas.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Concurrencia** → Fase 14. Esta fase envía en serie a propósito: mezclar los dos problemas
  —fallos ajenos y paralelismo— haría imposible saber cuál causó qué.
- **Colas de trabajo y reintentos diferidos** → Fase 15. Aquí el reintento es inmediato y en el
  proceso; el reintento de mañana a las dos de la mañana es otro problema.
- **Automatizar portales sin API** —los de las aseguradoras, que Áurea tiene— → track `au`. Se
  nombra porque es trabajo real del lector y **no entra**: automatizar un navegador es otra
  disciplina, con sus propias herramientas y su propia fragilidad.
- **OAuth y la autenticación de terceros.** El curso usa firma con secreto compartido, que es lo
  que Áurea tiene con sus socios. OAuth se nombra y se cierra: es un protocolo entero.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** *"si falló, reintento"*.

Es razonable, es lo que hacen los frameworks que conoces, y la mitad de las veces es correcto. El
problema es la otra mitad, y se ve en cuanto se mira lo que de verdad pasó del otro lado:

```python
# ❌ Lo que sale solo
for attempt in range(3):
    try:
        response = client.post(url, json=payload)
        break
    except Exception:
        continue
```

Ese código tiene tres errores, y el tercero es el que cuesta dinero:

**Uno: no mira el código de respuesta.** Es el mismo error de la Fase 05 con `subprocess`, con
otro vestido: `httpx` **no lanza** por un `500`. Devuelve una respuesta con `status_code == 500` y
sigue. Si nadie lo mira, el `break` se ejecuta y el fallo se convierte en un éxito silencioso.
En la medición de §6, eso son **20 de 60 notificaciones perdidas sin que el emisor se entere**.

**Dos: no distingue qué se puede reintentar.** Un `500` o un timeout, sí. Un `400` —tu petición
está mal— no: reintentarla es mandar tres veces lo mismo mal. Un `401`, tampoco. Y un `409`,
depende de qué signifique para ese servicio.

**Tres, y es el grande: reintentar una operación no idempotente la ejecuta dos veces.** Y esto es
lo que el instinto no ve, porque en el modelo mental habitual "falló" significa "no ocurrió". No
es así:

> ⚠️ **Un timeout no es una cancelación.** Tu cliente deja de esperar; **el servidor sigue
> trabajando**. En la medición de §6, con un timeout de un segundo, el emisor dio **diez de diez**
> notificaciones por perdidas — y las diez **habían llegado y se habían procesado**. Reintentar
> esas diez habría duplicado las diez.

**Qué se escribe en su lugar**, y son cuatro decisiones explícitas: timeout, criterio de
reintento, *backoff*, y **clave de idempotencia**. Las cuatro, siempre, y la última es la única
que de verdad protege.

### Idempotencia, que es la fase entera

Una operación es idempotente si ejecutarla dos veces deja el sistema igual que ejecutarla una. `GET`
lo es por definición; `PUT` y `DELETE` lo son si están bien hechos; **`POST` no lo es**, y por eso
todo lo que importa pasa por ahí.

La solución estándar y la que el curso usa: **una clave de idempotencia**. El emisor genera un
identificador único **por operación** —no por intento— y lo manda en cada reintento. El receptor
guarda las claves que ya procesó y, si le llega una repetida, devuelve el resultado anterior sin
volver a ejecutar.

```python
# Emisor: la clave se genera UNA vez, fuera del bucle de reintentos.
idempotency_key = f"disp-{branch}-{slot_id}-{revision}"

for attempt in range(3):
    response = client.post(url, json=payload, headers={"Idempotency-Key": idempotency_key})
    ...
```

```python
# Receptor: consultar y registrar, en la MISMA transacción que el trabajo.
def receive(payload: Payload, key: str, session: Session) -> Result:
    existing = session.get(ProcessedEvent, key)
    if existing is not None:
        return existing.result          # ya se procesó: se devuelve lo mismo
    result = do_the_work(payload)
    session.add(ProcessedEvent(key=key, result=result))
    return result                        # el commit lo hace la transacción del endpoint
```

> 🧭 **La clave es de la operación, no del intento.** Si la generas dentro del bucle —o con
> `uuid4()` en cada envío— no sirve para nada: cada reintento trae una clave nueva y el receptor
> los procesa todos. Es el error más común, y produce exactamente el problema que se venía a
> evitar.

Y el número que lo justifica, de §6: **60 notificaciones enviadas con reintento y sin clave de
idempotencia produjeron 89 operaciones del otro lado. Veintinueve duplicados.** Con clave, 60 y
60.

### Esto sí funciona igual

**Todo tu criterio sobre integraciones se transfiere entero**, y es mucho: timeouts, reintentos,
*backoff* exponencial con *jitter*, cortacircuitos, colas de mensajes muertos, degradación
elegante. Si has trabajado con Resilience4j o Hystrix, la teoría no cambia ni una coma.

**Las garantías de entrega son las de siempre:** *a lo sumo una vez*, *al menos una vez*, y
*exactamente una vez* —que no existe en la práctica y se emula con "al menos una vez" más un
receptor idempotente. Esa frase la sabes; lo que esta fase hace es cobrártela con números.

**Y el diseño de contratos entre sistemas es el mismo oficio:** versionar el evento, no romper a
quien te consume, y no asumir que el otro lado despliega cuando tú.

Lo único que cambia es la caja de herramientas, y —hay que decirlo— **es más pobre que la tuya**:
no hay un Resilience4j de referencia en este ecosistema. Hay bibliotecas buenas (`tenacity`,
`stamina`), pero la configuración declarativa con anotaciones que tienes en Spring no tiene
equivalente directo. Se escribe más a mano.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| `RestTemplate` / `WebClient` | `httpx.Client` / `AsyncClient` | La misma biblioteca hace síncrono y asíncrono |
| `HttpClient` de Java 11 | `httpx` | Igual de moderno; `requests` es el clásico y no habla `async` |
| `@Retryable` de Spring Retry | un decorador propio, o `tenacity` | **No hay estándar**: se escribe o se elige biblioteca |
| Resilience4j CircuitBreaker | `pybreaker`, o a mano | Igual: no hay uno de referencia |
| `connectTimeout` / `readTimeout` | `httpx.Timeout(connect=, read=, write=, pool=)` | **Cuatro capas**, no dos, y el valor por defecto no es infinito pero sí generoso |
| Pool de conexiones del cliente | `Client` reutilizado | **Crear un `Client` por petición es el error de rendimiento más común** |
| `@Idempotent` (no existe) | una tabla de claves procesadas | Se escribe en los dos mundos; aquí no hay ni la ilusión de que venga incluido |
| Firma HMAC | `hmac` + `hashlib` | En la caja, y `compare_digest` es obligatorio |

> 📝 **Nota de ecosistema — `requests` y `httpx`.** `requests` fue el cliente HTTP de Python
> durante quince años, está en todas partes, y sigue siendo perfectamente válido para código
> síncrono. `httpx` nació con la misma API a propósito —para que migrar sea copiar y pegar— y
> agrega lo que `requests` no tiene: soporte `async`, HTTP/2, y timeouts por capa. El curso usa
> `httpx` porque el Bloque C tiene `async` de por medio; si llegas a un proyecto con `requests`,
> no está roto.

### El cliente, bien configurado

Tres cosas que casi nadie hace y que deciden el comportamiento bajo fallo:

**Un `Client` reutilizado, no uno por petición.** Cada `Client` nuevo abre conexiones nuevas, y
eso es TCP más TLS: decenas de milisegundos que se pagan en cada llamada. Es el mismo argumento
del *pool* de la Fase 11, y la misma magnitud.

**Timeouts en las cuatro capas.** `httpx` los distingue y cada uno cubre un fallo distinto:
`connect` —el socio no responde al saludo—, `read` —empezó a responder y se quedó a medias—,
`write` —no acepta lo que le mandas—, y `pool` —tu propio cliente no tiene conexiones libres—. Un
timeout global tapa los cuatro con el mismo número, que casi nunca es el correcto para todos.

**Y límites de conexión**, para no convertir un socio lento en un problema tuyo: si todas tus
conexiones están esperando al socio que tarda seis segundos, lo que se cae es tu API.

### Qué se reintenta y qué no

| Situación | ¿Reintentar? | Por qué |
|---|---|---|
| Timeout de conexión | **Sí** | Probablemente no llegó |
| Timeout de lectura | **Sí, con clave de idempotencia** | **Puede haber llegado y procesado** |
| `500`, `502`, `503`, `504` | **Sí** | Fallo del otro lado, transitorio |
| `429` (demasiadas peticiones) | **Sí, respetando `Retry-After`** | Te están pidiendo que esperes |
| `400`, `422` | **No** | Tu petición está mal; reintentar es repetir el error |
| `401`, `403` | **No** | Falta autorización: reintentar no la consigue |
| `404` | **Depende** | Si el recurso debería existir, puede ser propagación; si no, no |
| `200` con cuerpo inválido | **No sin pensar** | El otro lado cree que funcionó. §5.4 |

Y el *backoff* exponencial **con *jitter***, que es el detalle que casi siempre se olvida: si mil
clientes reintentan exactamente a los 100, 200 y 400 milisegundos, el servidor que se estaba
recuperando recibe tres avalanchas sincronizadas. Un componente aleatorio las dispersa.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El cliente

```python
"""Cliente HTTP de Áurea para hablar con los socios."""

import httpx

# Un solo cliente para todo el proceso. Reutiliza conexiones, y eso es TCP y TLS
# que no se pagan otra vez. Se crea al arrancar la aplicación y se cierra al salir.
partner_client = httpx.Client(
    timeout=httpx.Timeout(
        connect=2.0,   # el socio no contesta el saludo
        read=5.0,      # empezó a responder y se quedó a medias
        write=5.0,     # no acepta lo que le mandamos
        pool=1.0,      # NUESTRO cliente no tiene conexiones libres
    ),
    limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
    headers={"User-Agent": "aurea-agenda/0.13"},
    follow_redirects=False,   # un redirect inesperado es un problema, no un detalle
)
```

**Detalles con intención**

- **`read=5.0` y no más.** El socio lento tarda entre 2 y 6 segundos; con 5 vamos a abandonar
  algunos que habrían funcionado. **Es una decisión con costo** y por eso lleva número: con un
  timeout más largo, un socio caído bloquea nuestras conexiones y el problema pasa a ser nuestro.
- **`pool=1.0`** es el que casi nadie configura y el que produce el síntoma más confuso: peticiones
  que tardan segundos sin que el otro lado tenga la culpa, porque están **esperando una conexión
  libre en tu propio cliente**.
- **`follow_redirects=False`.** Si un socio empieza a redirigir, quiero enterarme, no seguirlo en
  silencio — sobre todo con un `POST`, donde el redirect puede convertirlo en `GET`.

### 5.2 El envío con reintento

```python
"""Envío de un evento a un socio, con las cuatro decisiones explícitas."""

import random
import time
from dataclasses import dataclass

import httpx

# Los códigos que significan "vuelve a intentar". El resto, no.
RETRYABLE = frozenset({429, 500, 502, 503, 504})
MAX_ATTEMPTS = 3


@dataclass(frozen=True, slots=True)
class DeliveryResult:
    """Lo que de verdad pasó. Nunca un booleano: hay más de dos resultados."""

    delivered: bool
    attempts: int
    status: int | None
    detail: str


def deliver(url: str, payload: dict, idempotency_key: str) -> DeliveryResult:
    """Entrega un evento a un socio.

    La clave de idempotencia se recibe como parámetro, generada UNA vez por el
    que llama: si se generara aquí, cada reintento traería una distinta y el
    receptor procesaría todos (§4).
    """
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            response = partner_client.post(
                url, json=payload, headers={"Idempotency-Key": idempotency_key}
            )
        except httpx.TimeoutException as error:
            # Puede haber llegado. La clave de idempotencia es lo único que
            # hace que reintentar aquí sea seguro.
            detail = f"timeout: {error}"
        except httpx.HTTPError as error:
            detail = f"error de transporte: {error}"
        else:
            if response.status_code < 400:
                return DeliveryResult(True, attempt, response.status_code, "entregado")
            if response.status_code not in RETRYABLE:
                # 400, 401, 422: reintentar es repetir el mismo error.
                return DeliveryResult(
                    False, attempt, response.status_code,
                    f"el socio rechazó la petición: {response.text[:200]}",
                )
            detail = f"el socio respondió {response.status_code}"

        if attempt < MAX_ATTEMPTS:
            # Backoff exponencial CON jitter: sin el componente aleatorio, mil
            # emisores reintentan a la vez y rematan al socio que se recuperaba.
            delay = (0.05 * 2 ** (attempt - 1)) * (1 + random.random())
            time.sleep(delay)

    return DeliveryResult(False, MAX_ATTEMPTS, None, detail)
```

**Detalles con intención**

- **Devuelve un resultado, no un booleano.** Quien llama necesita saber si fue rechazado —no
  reintentar nunca más— o si se agotaron los intentos —reintentar mañana, que es la Fase 15—. Un
  `True/False` pierde esa distinción y con ella la decisión.
- **El `else` del `try`** (Fase 04) para que el `except` no atrape lo que pasa al inspeccionar la
  respuesta.
- **`response.text[:200]`** y no el cuerpo completo: un socio que devuelve una página de error de
  cien kilobytes no puede llenarte el registro.
- **Y `time.sleep` bloquea.** En una aplicación `async` esto tiene que ser `await asyncio.sleep`, y
  la diferencia es la Fase 14. Aquí el envío es en serie y desde un proceso de fondo: bloquear
  está bien y está declarado.

### 5.3 El receptor idempotente

```python
"""La otra punta: recibir un webhook sin procesarlo dos veces."""

import hashlib
import hmac

from fastapi import APIRouter, Header, HTTPException, Request, status

router = APIRouter()


def verify_signature(body: bytes, signature: str, secret: bytes) -> None:
    """Comprueba la firma del emisor.

    compare_digest y no ==: la comparación normal termina en el primer byte
    distinto, y ese tiempo se puede medir para adivinar la firma byte a byte.
    """
    expected = hmac.new(secret, body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(signature, expected):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "firma inválida")


@router.post("/webhooks/partner", status_code=status.HTTP_202_ACCEPTED)
async def receive_partner_event(
    request: Request,
    session: DbSession,
    x_firma: Annotated[str, Header()],
    idempotency_key: Annotated[str, Header(alias="Idempotency-Key")],
) -> dict[str, str]:
    """Recibe un evento de un socio.

    Devuelve 202 y no 200: aceptamos el evento y lo procesaremos. Prometer que
    ya está hecho cuando el trabajo es diferido es mentirle al emisor.
    """
    body = await request.body()
    verify_signature(body, x_firma, settings.partner_secret)

    # La comprobación de idempotencia y el trabajo, en la MISMA transacción.
    # Si el registro de la clave y el trabajo se hacen en dos transacciones,
    # hay una ventana en la que un reintento entra y duplica.
    already = session.get(ProcessedEvent, idempotency_key)
    if already is not None:
        return {"estado": "ya procesado", "resultado": already.result}

    result = apply_partner_event(json.loads(body), session)
    session.add(ProcessedEvent(key=idempotency_key, result=result))
    return {"estado": "procesado", "resultado": result}
```

**Detalles con intención**

- **Se firma y se verifica sobre el cuerpo en bytes, sin reserializar.** Si lo conviertes a `dict`
  y lo vuelves a serializar, el orden de las llaves o los espacios cambian y la firma deja de
  coincidir. Es el error que produce el `401` inexplicable.
- **`202 Accepted` y no `200 OK`.** Dice lo que de verdad pasó.
- **Y la clave tiene que caducar.** Una tabla de claves procesadas que crece para siempre es una
  tabla que en tres años tiene cuarenta millones de filas. Se limpia por fecha, y decidir cuánto
  se conservan es una decisión de negocio: en Áurea, más que la ventana de reintentos del socio
  más lento.

### 5.4 El socio que miente

El fallo más difícil, y el que la medición de §6 hace visible: **un socio que responde `200` y no
procesa nada**. Sesenta notificaciones enviadas, sesenta respuestas correctas, **cero llegadas**.

Ninguna defensa del emisor lo detecta, porque desde su lado todo salió bien. Las únicas respuestas
son de diseño y hay que elegirlas a conciencia:

**Confirmación explícita.** El socio no responde `200`: responde con el identificador que le
asignó al evento. Si no viene ese identificador, no fue procesado, y ahora sí puedes detectarlo.

**Reconciliación periódica.** Una vez al día se comparan los dos lados: qué mandamos contra qué
tiene él. Es lo que Áurea ya hace a mano con los aliados —y es el proyecto 4, el cierre nocturno
de la Fase 15.

**Y lo que no funciona:** confiar en el `200`. Está dicho para que se pueda citar.

> 🧭 **La regla que se lleva de aquí:** un `200` significa *"recibí tu petición"*, no *"hice lo que
> pediste"*. Si necesitas lo segundo, el contrato tiene que decirlo explícitamente — y eso es una
> conversación con el socio, no una línea de código.

**Prueba de fuego**

Con el servidor de §7 corriendo:

```bash
python enviar.py --socio intermitente --eventos 60
```

```text
enviadas 60 · entregadas 60 · reintentos 20 · duplicadas 0 · 1.7 s
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **"entregadas 60" es lo
que dice tu emisor**. Lo que hay que comprobar es lo que dice **el receptor** —`GET /_recibidos`
del servidor de pruebas—, y es el único número que no se puede discutir. La mitad de las
integraciones rotas del mundo funcionan perfectamente según quien las emite.

**El patrón a memorizar**

> Entrega *al menos una vez* más receptor idempotente. Es la única combinación que existe: *a lo
> sumo una vez* pierde, *exactamente una vez* no se puede construir, y "al menos una vez" sin
> idempotencia duplica. Las tres tienen su número en la sección 6.

---

## 📏 6. Medición — qué se pierde y qué se duplica

**Hipótesis.** Sin defensas se pierden operaciones en silencio; con reintento pero sin
idempotencia se duplican; y solo la combinación de las dos cosas entrega exactamente lo enviado.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · `httpx` 0.28.1 · el servidor de pruebas de §7,
local, con semilla `2026` · **60 notificaciones de disponibilidad** por escenario · envío en serie,
sin concurrencia (eso es la Fase 14) · reintento: hasta 3 intentos con *backoff* exponencial ·
**el conteo de lo que llegó lo da el receptor**, no el emisor.

**Competidores.** El emisor "sin defensas" es el código de §4: un `POST` sin timeout, sin mirar el
código de respuesta y sin reintento. No está saboteado — es literalmente lo que se escribe cuando
uno no ha pensado en esto, y por eso es el competidor correcto.

**Resultado.**

| Escenario | Enviadas | **Llegaron** | El emisor dijo que perdió | **Duplicadas** |
|---|---|---|---|---|
| Socio intermitente, **sin defensas** | 60 | **40** | **0** | 0 |
| Socio intermitente, con reintento | 60 | **60** | 0 | 0 |
| Socio idempotente, con reintento **sin clave** | 60 | **89** | 0 | **29** |
| Socio idempotente, con reintento **con clave** | 60 | **60** | 0 | **0** |
| Socio **mentiroso** (responde 200 y no procesa) | 60 | **0** | **0** | 0 |

**Y el socio lento, que es la otra mitad de la lección:**

| | Tiempo para 10 notificaciones | El emisor dio por perdidas | **Llegaron de verdad** |
|---|---|---|---|
| Sin timeout | **39.3 s** | 0 | 10 |
| Con timeout de 1 s | **10.0 s** | **10** | **10** |

> ⚖️ **Veredicto. Las tres filas que importan cuentan tres historias distintas y ninguna es la que
> uno espera.**
>
> **Primera: sin defensas se perdió el 33% de las notificaciones y el emisor reportó cero
> pérdidas.** Veinte de sesenta, en silencio, porque nadie miró el código de respuesta. No hay
> alerta, no hay error, no hay traza: solo socios que no se enteraron de veinte cambios de
> disponibilidad. Este es el fallo más común de las integraciones reales y el más difícil de
> descubrir, porque **todo parece funcionar**.
>
> **Segunda: el reintento sin clave de idempotencia produjo 89 operaciones de 60 envíos — un 48%
> de duplicados.** El mecanismo es exacto y vale la pena entenderlo: el socio **procesa** el
> evento y después falla al responder; el emisor ve un `500`, reintenta, y el socio lo procesa
> otra vez. Trasladado al dominio: veintinueve pacientes con la cita duplicada, o veintinueve
> cobros repetidos. **La defensa que parecía obvia —reintentar— es la que causa el daño.**
>
> **Tercera, y es la que desmonta el modelo mental: con timeout de un segundo, el emisor dio diez
> de diez por perdidas y las diez habían llegado.** Un timeout es una decisión del **cliente**;
> el servidor no se entera y sigue trabajando. Quien reintente esas diez las duplica todas. Esto
> es lo que hace que la idempotencia no sea una buena práctica opcional: **es la condición para
> que reintentar sea legítimo.**
>
> **Dónde pierde la defensa completa, y hay que decirlo:** cuesta. El reintento con *backoff*
> convierte 0.0 s en **1.7 s** para las mismas 60 notificaciones, y el timeout corto abandona
> trabajo que habría terminado —los diez del socio lento—. No es gratis: es más lento y más
> complejo, a cambio de ser correcto.
>
> **Y el socio mentiroso no lo arregla ninguna defensa del emisor: cero de sesenta, con todo
> puesto.** Es el límite de esta fase, y la respuesta está en §5.4 y en la Fase 15: confirmación
> explícita en el contrato, o reconciliación. Ninguna de las dos es código del cliente HTTP.
>
> **El umbral, como criterio:** si la operación **cambia algo del otro lado** —crea, cobra,
> agenda—, necesita clave de idempotencia, sin excepción. Si solo consulta, el reintento simple
> basta y la clave sobra. Y si no puedes poner la clave porque el socio no la soporta, **el
> reintento pasa a ser una decisión de negocio**, no técnica: hay que preguntarle a alguien qué es
> peor, perder el evento o duplicarlo.

**Lo que no se midió:** el comportamiento con varios emisores concurrentes (Fase 14), el
cortacircuitos —que se nombra y no entra—, y el costo de la tabla de claves procesadas a lo largo
de un año. Tampoco se midió contra un socio real: el servidor de pruebas imita fallos conocidos,
y los sistemas reales inventan otros.

---

## 🧱 7. Miniproyecto — *El webhook del socio*

**El encargo**

Julián: *"Los de la web y los del bot me piden lo mismo: que les avisemos cuando cambia la
disponibilidad, en vez de estar preguntando cada minuto. Y hay un tercero, la aseguradora, que
quiere lo mismo pero su gente de sistemas dice que 'tiene que venir firmado'. Yo les dije que sí a
los tres sin saber en qué me estaba metiendo."*

Diseña y construye **las dos puntas** del webhook: el emisor que notifica a los tres socios, y el
receptor que Áurea expone para recibir eventos de ellos.

**Por qué duele**

Porque la entrega *al menos una vez* obliga a que el receptor sea idempotente, y eso solo se
entiende del todo cuando te toca escribir los dos lados. Y porque los tres socios fallan de
maneras distintas: uno es lento, uno devuelve `500` intermitentes, y uno responde `200` sin
procesar — y ese último no lo puedes arreglar desde tu lado.

**Datos de entrada**

El servidor de los socios, que **falla a propósito** y que el curso trae porque sin él el
miniproyecto no se puede hacer:

```python
"""Servidor de pruebas que falla a propósito, para la Fase 13.

Imita a los tres socios de Áurea que reciben los webhooks de disponibilidad.
No es código a imitar: es un sistema ajeno, con los fallos que tienen los
sistemas ajenos de verdad.

Uso:
    python socio_falible.py [--puerto 8099] [--semilla 2026]

Comportamiento por ruta:
  /lento          responde bien, pero tarda entre 2 y 6 segundos
  /intermitente   uno de cada tres intentos devuelve 500
  /truncado       responde 200 con el cuerpo cortado: JSON inválido
  /mentiroso      responde 200 SIEMPRE y no procesa nada (el peor de todos)
  /firmado        exige la cabecera X-Firma correcta; si no, 401
  /idempotente    respeta la cabecera Idempotency-Key y no duplica

Todas las rutas registran lo que recibieron en memoria, y GET /_recibidos
devuelve el registro para poder auditar qué llegó de verdad.
"""

import argparse
import hashlib
import hmac
import json
import random
import threading
import time
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SECRET = b"el-secreto-que-comparten-aurea-y-el-socio"
received: dict[str, list[dict]] = defaultdict(list)
processed_keys: dict[str, str] = {}
attempts: dict[str, int] = defaultdict(int)
lock = threading.Lock()


class SocioHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        """Silencio: el ruido del servidor estorba en la medición."""

    def _read_body(self) -> bytes:
        length = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(length) if length else b""

    def _respond(self, code: int, payload: dict, truncate: bool = False) -> None:
        body = json.dumps(payload).encode()
        if truncate:
            # Cuerpo cortado a la mitad, con su Content-Length correcto: el
            # cliente recibe un 200 con un JSON que no se puede parsear.
            # (Una truncadura de verdad, donde el Content-Length miente, se
            # manifiesta como un timeout de lectura en vez de como JSON
            # inválido. Las dos existen; esta es la que se puede provocar de
            # forma determinista.)
            body = body[: len(body) // 2]
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/_recibidos":
            with lock:
                payload = {k: len(v) for k, v in received.items()}
                payload["_claves_procesadas"] = len(processed_keys)
            self._respond(200, payload)
        elif self.path == "/_reiniciar":
            with lock:
                received.clear()
                processed_keys.clear()
                attempts.clear()
            self._respond(200, {"ok": True})
        else:
            self._respond(404, {"error": "no existe"})

    def do_POST(self):
        body = self._read_body()
        route = self.path.split("?")[0]

        with lock:
            attempts[route] += 1
            attempt = attempts[route]

        if route == "/lento":
            time.sleep(random.uniform(2.0, 6.0))
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/intermitente":
            if attempt % 3 == 0:
                self._respond(500, {"error": "error interno del socio"})
                return
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/truncado":
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True, "detalle": "x" * 400}, truncate=True)

        elif route == "/mentiroso":
            # Responde 200 y NO guarda nada. Es el fallo más difícil de detectar.
            self._respond(200, {"ok": True})

        elif route == "/firmado":
            expected = hmac.new(SECRET, body, hashlib.sha256).hexdigest()
            if not hmac.compare_digest(self.headers.get("X-Firma", ""), expected):
                self._respond(401, {"error": "firma inválida"})
                return
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/idempotente":
            key = self.headers.get("Idempotency-Key", "")
            with lock:
                if key and key in processed_keys:
                    self._respond(200, {"ok": True, "repetido": True})
                    return
                received[route].append(json.loads(body or b"{}"))
                if key:
                    processed_keys[key] = "ok"
            # Falla una de cada tres DESPUÉS de haber procesado: el caso que
            # obliga a que el emisor reintente sobre algo ya hecho.
            if attempt % 3 == 0:
                self._respond(500, {"error": "falló al responder, pero ya procesé"})
                return
            self._respond(200, {"ok": True})

        else:
            self._respond(404, {"error": "no existe"})


def main() -> None:
    parser = argparse.ArgumentParser(description="Socio que falla a propósito.")
    parser.add_argument("--puerto", type=int, default=8099)
    parser.add_argument("--semilla", type=int, default=2026)
    args = parser.parse_args()

    random.seed(args.semilla)
    server = ThreadingHTTPServer(("127.0.0.1", args.puerto), SocioHandler)
    print(f"socio falible escuchando en http://127.0.0.1:{args.puerto}")
    server.serve_forever()


if __name__ == "__main__":
    main()
```

**Criterios de aceptación**

- [ ] El **emisor** notifica a los tres socios cuando cambia la disponibilidad, con timeout en las
      cuatro capas, reintento con *backoff* y *jitter*, y clave de idempotencia por operación.
- [ ] El emisor distingue **cuatro resultados** —entregado, rechazado definitivamente, agotados
      los intentos, y respuesta inválida— y hace algo distinto con cada uno.
- [ ] Contra `/intermitente` entregas **60 de 60** sin duplicados. Compruébalo con
      `GET /_recibidos`, no con tu propio registro.
- [ ] Contra `/idempotente` entregas **60 de 60** y el receptor registra **60**, no 89.
- [ ] Contra `/firmado` la firma se calcula bien y el socio la acepta. Rompe un byte y comprueba
      que la rechaza.
- [ ] Contra `/truncado` **detectas** la respuesta inválida en vez de tratarla como éxito.
- [ ] El **receptor** de Áurea verifica firma con `compare_digest`, es idempotente por clave, y
      responde `202`. Mándale el mismo evento tres veces y demuestra que se procesa una.
- [ ] Escribes qué haces con `/mentiroso`. **La respuesta correcta puede ser "esto no se resuelve
      aquí"**, con la propuesta de qué haría falta.
- [ ] **Medición:** por cada socio, enviadas contra llegadas contra duplicadas, y el tiempo total.
      Esos números van en el mensaje del tag.

**Restricciones de registro**

> Esto es una **aplicación**: tipos verificados, pruebas, y el emisor como un módulo del proyecto,
> no un script suelto. La restricción propia de la fase: **no uses una biblioteca de reintentos**
> —`tenacity`, `stamina`— en la primera versión. Escríbelo a mano una vez, porque el objetivo es
> que entiendas las cuatro decisiones; después, en el ejercicio 14, cámbialo por la biblioteca y
> compara. El reflejo que ataca esta restricción es el contrario al del Bloque A: aquí el riesgo
> es delegar en una biblioteca algo que no entiendes.

**La trampa**

Vas a generar la clave de idempotencia con `uuid4()` justo antes de enviar, dentro del bucle de
reintentos o en cada llamada a `deliver`. Y va a funcionar: no va a fallar nada, no va a haber
error, y el socio va a responder `200` a todo.

Y vas a duplicar el 48% de los eventos, exactamente como la tercera fila de §6. Porque una clave
nueva en cada intento no identifica **la operación**: identifica **el intento**, y el receptor no
tiene forma de saber que ya vio ese evento.

La segunda trampa está en `/truncado`: `httpx` te devuelve un `200` perfectamente válido, y el
cuerpo revienta al parsearlo. Si tu código hace `response.json()` dentro de un `try` que atrapa
todo, vas a convertir una respuesta corrupta en un reintento — o, peor, en un éxito.

Y hay una variante peor que conviene conocer porque en producción es la que más se da: cuando el
servidor **miente en el `Content-Length`** y corta la conexión, el cliente se queda esperando los
bytes que faltan y lo que recibes no es un JSON inválido sino un **timeout de lectura** — sobre
una petición que el otro lado ya procesó. Es el mismo caso de §4, con otra cara: comprobado al
escribir esta fase, y la razón por la que el servidor de pruebas provoca la versión determinista.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Escribe primero **el receptor**, que es la punta que puedes probar sola mandándole el mismo evento
tres veces con `curl`. Cuando eso funcione, el emisor es más fácil de razonar porque ya sabes qué
espera el otro lado.

Y para la clave de idempotencia, la pregunta que la define: *¿qué identifica a esta operación de
forma única, independientemente de cuántas veces la intente?* Si la respuesta incluye la hora o un
número aleatorio, está mal.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`httpx` — timeouts y límites](https://www.python-httpx.org/advanced/timeouts/), y la diferencia
  entre `Client` y `AsyncClient`.
- [`hmac.compare_digest`](https://docs.python.org/3.14/library/hmac.html#hmac.compare_digest) y por
  qué no se compara con `==`.
- [`httpx` — manejo de excepciones](https://www.python-httpx.org/exceptions/): la jerarquía
  distingue timeout de conexión, de lectura y error de transporte, y esa distinción es la tabla de
  §4.
- Para el receptor, el `Request.body()` de FastAPI **en bytes** — la firma se verifica sobre lo que
  llegó, no sobre lo reserializado.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
@dataclass(frozen=True, slots=True)
class DeliveryResult:
    delivered: bool
    attempts: int
    status: int | None
    detail: str

def idempotency_key_for(event: AvailabilityEvent) -> str:
    """Identifica la OPERACIÓN. Sin hora, sin azar."""

def deliver(partner: Partner, event: AvailabilityEvent) -> DeliveryResult: ...

def notify_all(event: AvailabilityEvent) -> dict[str, DeliveryResult]: ...

# la otra punta
@router.post("/webhooks/partner", status_code=202)
async def receive(request: Request, ...): ...
```
</details>

**Cómo se entrega**

```bash
python socio_falible.py --puerto 8099 &
uv run python -m agenda.notify --eventos 60
curl -s localhost:8099/_recibidos
uv run pytest -q
```

```bash
git add src/agenda socio_falible.py tests/
git commit -m "fase 13 mini: webhooks con reintento e idempotencia en las dos puntas"
git tag -a mini-13 -m "Mini F13: webhooks · <N> enviadas, <M> llegadas, <D> duplicadas, <T> s"
```

<details><summary>💡 Solución de referencia — la clave, la trampa y el límite</summary>

**La decisión de diseño que se tomó.** La clave de idempotencia es **derivada del evento**, no
aleatoria: `disp-{sede}-{fecha}-{franja}-{revision}`. Es determinista, así que dos intentos de la
misma operación producen la misma clave aunque el proceso se haya reiniciado entre ellos — que es
el caso que un `uuid4()` guardado en memoria no cubre.

El otro camino defendible es un `uuid4()` **persistido junto al evento** antes del primer envío:
funciona igual de bien y es más general —sirve cuando el evento no tiene una identidad natural—,
a cambio de una escritura más. Se eligió la clave derivada porque la disponibilidad **sí** tiene
identidad natural y porque una clave legible hace que depurar una integración a las once de la
noche sea posible.

**La trampa, entera.** `uuid4()` por intento produce el 48% de duplicados de §6 **sin un solo
error visible**: el socio responde `200` a todo, tu emisor reporta éxito, y la duplicación solo
aparece cuando alguien del otro lado cuenta. Es la misma forma de fallo que el socio mentiroso —
todo parece bien— y por eso el criterio de aceptación exige comprobar con `GET /_recibidos` y no
con el registro propio.

Y la trampa del cuerpo truncado tiene una lección aparte: **la respuesta inválida no es ni un
éxito ni un fallo del socio, es un cuarto resultado**. Tratarla como éxito pierde el evento;
tratarla como fallo lo duplica si no hay clave. Por eso `DeliveryResult` tiene un campo `detail` y
no un booleano.

**Qué se habría hecho distinto si el registro fuera otro.** Como script, esto sería un `for` con
un `POST` adentro y funcionaría el 90% de las veces — que es exactamente cómo están escritas la
mayoría de las integraciones pequeñas del mundo, y por qué fallan como fallan. Como herramienta,
tendría configuración por socio y un registro en archivo. La diferencia real del registro
*aplicación* es que **hay alguien que tiene que enterarse cuando falla**, y eso es observabilidad:
Fase 16.

**Y el límite, escrito:** contra el socio mentiroso, la respuesta correcta es *"esto no se resuelve
desde el emisor"*. Lo que se propone es cambiar el contrato —que responda con el identificador que
asignó— y, mientras tanto, reconciliar una vez al día. Reconocer que un problema no es tuyo y
proponer qué haría falta es una respuesta de ingeniería, no una excusa.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Configura un `httpx.Client` con los cuatro timeouts y provoca cada uno de los cuatro. Copia la
   excepción exacta de cada caso.
2. Manda una petición al socio intermitente sin mirar el código de respuesta y demuestra que tu
   programa cree que funcionó.
3. Calcula la firma HMAC de un cuerpo y verifícala contra `/firmado`. Después cambia un byte y
   comprueba el `401`.
4. Crea un `Client` por petición y otro reutilizado, manda 100 peticiones con cada uno, y mide la
   diferencia.
5. Manda el mismo evento tres veces a tu receptor con la misma clave y demuestra que se procesó
   una vez.
6. Provoca el caso del cuerpo truncado y mira qué excepción lanza `response.json()`.

**🟡 Intermedio (7–14)**

7. Implementa el *backoff* exponencial con *jitter* y grafica —o tabula— los tiempos de espera de
   diez ejecuciones. Explica qué problema resuelve la aleatoriedad.
8. Haz que tu emisor respete la cabecera `Retry-After` de un `429`. Simúlalo agregando una ruta al
   servidor de pruebas.
9. Escribe la tabla de §4 como código: una función que decida si un resultado es reintentable.
   Pruébala con los diez casos.
10. Implementa la caducidad de las claves de idempotencia y decide cuánto duran. Justifica el
    número con la ventana de reintentos del socio más lento.
11. Averigua qué es un cortacircuitos y escribe uno mínimo: tras N fallos seguidos, deja de
    intentar durante T segundos. Pruébalo contra el socio lento.
12. Usa `httpx.AsyncClient` para notificar a los tres socios **en paralelo** y compara el tiempo
    total contra la versión en serie. (Es un adelanto de la Fase 14: hazlo y guarda el número.)
13. Haz que el receptor rechace eventos con más de cinco minutos de antigüedad —la marca de tiempo
    va firmada— y explica qué ataque previene.
14. Reemplaza tu código de reintentos por `tenacity` o `stamina` y compara: líneas, legibilidad, y
    qué se te había olvidado. Es el ejercicio que justifica haberlo escrito a mano primero.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un socio reporta eventos duplicados y tu registro dice que enviaste uno solo.
    Reprodúcelo y encuentra las **tres** causas posibles: la clave por intento, el timeout que no
    cancela, y un reintento a nivel de infraestructura que no controlas.
16. **Diagnóstico.** Tu API se degrada cuando un socio se pone lento, aunque el socio no tenga nada
    que ver con las peticiones de tus usuarios. Reprodúcelo y explica el mecanismo — está en §5.1.
17. **Medición.** Reproduce la tabla de §6 en tu máquina, con las cinco filas. Si tu número de
    duplicados difiere, explica por qué antes de dudar de la medición.
18. **Medición.** Mide cuánto cuesta la defensa completa: tiempo total de las 60 notificaciones sin
    defensas, con reintento, y con reintento más idempotencia. Decide si el costo es aceptable y
    di a partir de qué volumen dejaría de serlo.
19. **Medición.** Mide el efecto del tamaño del *pool* de conexiones: notifica a 100 socios
    simulados con `max_connections` de 5, 20 y 100. Encuentra el punto donde deja de mejorar.
20. **De registro.** La aseguradora ofrece mandar **ella** los eventos a Áurea, en vez de recibir
    los nuestros. Decide qué cambia, qué registro es, y cuál de las dos direcciones prefieres
    defender. No hay respuesta única.
21. **De registro.** Julián pregunta si en vez de webhooks "no es más fácil que cada socio consulte
    la API cada minuto". **Tiene un argumento real**: es más simple y no tiene idempotencia que
    resolver. Escribe las dos caras con números —60 eventos al día contra 1.440 consultas— y
    decide.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Consigue duplicar un cobro. Monta el escenario completo —un endpoint que cobra,
    un timeout, un reintento— y demuéstralo con el registro del receptor. Después ciérralo y
    demuestra que ya no puedes. Es el ejercicio que justifica la fase.
23. **Adversarial.** Ataca tu propio receptor: manda un evento con firma inválida, uno con firma
    válida de un cuerpo distinto, uno repetido con clave distinta, y uno con marca de tiempo de
    hace tres días. Documenta cuáles pasaron y ciérralos.
24. **Defiende una decisión.** El curso escribe los reintentos a mano y usa clave de idempotencia
    derivada. Escribe la crítica más fuerte que puedas a las dos decisiones —existe— y respóndela.
    Termina diciendo qué harías en un equipo de diez personas en vez de uno.
25. **Diseño.** El socio mentiroso sigue ahí. Diseña la reconciliación diaria: qué se compara, con
    qué frecuencia, qué se hace con las diferencias, y quién se entera. **Conecta con la Fase 15**,
    que es donde se construye — y mira si tu diseño sobrevive a que el socio tenga su propio reloj
    y su propia zona horaria.

**🔥 Opcionales**

- Investiga el patrón *outbox* —escribir el evento en tu base de datos en la misma transacción que
  el cambio, y enviarlo después— y explica qué problema resuelve que el reintento no resuelve. La
  Fase 15 lo construye.
- Lee la especificación de la cabecera `Idempotency-Key` que están estandarizando en el IETF y
  compara con lo que implementaste.
- Monta un servidor con un certificado autofirmado y aprende a manejar la verificación TLS en
  `httpx`. Es el problema que te va a tocar con la primera aseguradora.

---

## 📚 9. Referencias

**Documentación oficial**

- [`httpx`](https://www.python-httpx.org/) — cliente, timeouts, límites, excepciones y `async`.
- [`hmac`](https://docs.python.org/3.14/library/hmac.html) y
  [`hashlib`](https://docs.python.org/3.14/library/hashlib.html) — firma y comparación segura.
- [`http.server`](https://docs.python.org/3.14/library/http.server.html) — con lo que está escrito
  el servidor de pruebas. **No es para producción**, y su documentación lo dice en la primera
  línea.
- [`tenacity`](https://tenacity.readthedocs.io/) — la biblioteca de reintentos más usada, para el
  ejercicio 14.

**Artículos y estándares**

- Los documentos de Amazon sobre *backoff* exponencial con *jitter* —hay uno clásico en su blog de
  arquitectura— explican por qué el *jitter* no es opcional. Verifica la URL: los títulos cambian.
- El borrador del IETF sobre la cabecera `Idempotency-Key`, para el ejercicio 🔥.

**Orden de lectura sugerido.** Antes de escribir: la página de timeouts de `httpx`, que son cinco
minutos y explican las cuatro capas. Durante: la jerarquía de excepciones, consultada. Después: lo
del *jitter*, que se entiende mucho mejor cuando ya viste tus tres reintentos sincronizados.

> ⚠️ URLs y contenidos cambian; verifica antes de citar.

---

## 🚀 10. Cierre y conexión con la siguiente fase

AgendaAPI habla con el mundo, y sabe hacerlo mal a propósito para poder hacerlo bien: con timeouts
en las cuatro capas, reintentando lo que se debe reintentar, y —sobre todo— con claves de
idempotencia que hacen que reintentar sea legítimo.

Lo que te llevas cabe en tres frases, y las tres tienen número detrás: **un `200` significa "recibí",
no "hice"**; **un timeout no es una cancelación**; y **"al menos una vez" más un receptor
idempotente es la única combinación que existe**. La tabla de §6 las demuestra las tres.

La **Fase 14** ⭐ es la fase donde tu instinto de Java es más fuerte y más inútil. Hasta aquí todo
se hizo en serie: un proceso, una cosa a la vez. Ahora entran los hilos, los procesos, `asyncio` y
el intérprete **sin GIL** — que ya no es un experimento sino una compilación oficial de 3.14. Y
entra con dos mediciones, no una: la misma carga de CPU y la misma de E/S en las cuatro formas,
porque **el veredicto se invierte entre las dos y esa inversión es la lección**. Ahí se cierra
también el caso que la Fase 11 dejó plantado: las dos auxiliares reservando las 3:40.

> **La señal de que quedó bien:** la próxima vez que veas un `retry` en código ajeno, tu primera
> pregunta no va a ser cuántos intentos — va a ser si la operación es idempotente.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-13 -m "F13 cerrada:
> - cliente con timeouts en las cuatro capas, límites y reutilización de conexión
> - criterio de reintento escrito: qué sí, qué no, y backoff con jitter
> - clave de idempotencia derivada de la operación, no del intento
> - receptor idempotente con firma verificada por compare_digest
> - las dos puntas del webhook, probadas contra un socio que falla a propósito
> - medido: 20 perdidas sin defensas, 29 duplicadas sin clave, 0 y 0 con todo puesto"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 13: …`), los de ejercicio su número
> (`fase 13 ej12: …`) y el miniproyecto el suyo (`fase 13 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-13`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
