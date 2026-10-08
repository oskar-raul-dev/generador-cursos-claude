# 🤖 ia01 — El modelo de acceso de un LLM

> Python para desarrolladores Java senior · Track `ia` · sección 1 de 8
> Depende de: el camino base completo (00–17) · Habilita: `ia02`
> Registro de esta sección: herramienta
> Proyecto que avanza: ninguno todavía — esta sección monta el cimiento de NormaRAG y de
> Recepción asistida

---

## 🎯 1. Propósito

Patricia y las auxiliares queman cerca de una hora diaria contestando la misma clase de pregunta:
*"¿esta prepagada cubre el retiro de brackets en el plan complementario, o eso lo paga el
paciente?"*. Antes de escribir una sola línea de NormaRAG hay que contestar otra pregunta, que es
de ingeniería y no de producto: **cuánto cuesta, cuánto tarda y con qué frecuencia falla mandarle
eso a un modelo**, y a partir de qué volumen la respuesta cambia.

Esta sección te deja capaz de decidirlo con números propios. No enseña qué es un transformador —no
vas a entrenar nada— sino **el modelo de acceso**: una dependencia de red, sin estado, con tarifa
por token, latencia proporcional a lo que escribe y una salida que no es la misma dos veces.

> 🧭 **La pregunta que ordena el track `ia` entero: ¿esto lo tiene que contestar un modelo, o ya
> lo contestaba un `SELECT`?** La sección `ia08` cierra con el veredicto; esta te da el
> instrumento para medirlo.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Tienes credenciales resueltas por entorno y **ninguna clave en el repositorio**, verificado
      con `git grep -i "sk-ant"` devolviendo vacío.
- [ ] `llm.py` corre y contesta una pregunta real de Áurea, reportando tokens de entrada, de
      salida y costo en `Decimal`.
- [ ] `count_and_price.py` estima el costo de una petición **antes** de enviarla, y la estimación
      cae dentro del 5% del cobro real en las cinco preguntas de prueba.
- [ ] Un modelo local corre en tu máquina con Ollama y contesta la misma pregunta sin salir a
      internet ni costar un peso.
- [ ] `bench_models.py` produce la tabla de la sección 6 con el arnés de la Fase 02: latencia
      p50/p95, tokens y costo, tres modelos, treinta repeticiones.
- [ ] Sabes qué hace tu código ante los cuatro fallos —400 por contexto excedido, timeout, 429 y
      `refusal`—, y provocaste los dos primeros a mano.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Salida estructurada, esquemas y validación** → `ia02`. Aquí la respuesta es texto y se lee
  con los ojos; eso es exactamente lo que `ia02` viene a arreglar.
- **Herramientas y bucle de agente** → `ia03`.
- **Embeddings, troceado y recuperación** → `ia04` y `ia05`. Esta sección le manda al modelo la
  pregunta pelada, y la respuesta va a ser mala. Es deliberado: sin ese fracaso, `ia04` parece
  ceremonia.
- **Caché de prompt** → `ia08`, con su medición sobre tráfico de un día. Aquí solo se nombra al
  ver el campo `cache_read_input_tokens` en el uso, para que no te sorprenda.
- **Evaluación y jueces** → `ia06`. Aquí "la respuesta se ve bien" es todo el criterio de
  calidad que tenemos, y ese es el problema que `ia06` resuelve.
- **Afinamiento de modelos, entrenamiento y teoría de arquitecturas neuronales** → fuera del
  curso, y no hay apéndice al que mandarlo ni otro sitio al que enviarte. Aquí el modelo es un
  servicio que consumes, y eso es todo lo que hace falta para decidir si te conviene.

---

## 🧠 4. Concepto mínimo

### El modelo de acceso, en cuatro propiedades

Un LLM detrás de una API es una dependencia de red más, y hasta ahí la intuición sirve. Lo que
cambia son cuatro propiedades, y las cuatro tienen consecuencia directa en el diseño.

**Es sin estado, y la conversación la pagas tú.** La API no recuerda nada: cada turno le mandas la
historia completa. Un intercambio de diez turnos manda el turno uno diez veces, el dos nueve
veces, y así. El costo de una conversación no crece con el número de turnos, **crece con su
cuadrado**, y esa es la primera cuenta que casi nadie hace antes de facturar el primer mes.

**Se cobra por token, y la salida cuesta cinco veces la entrada.** Un token es la unidad en que el
modelo parte el texto —aproximadamente tres cuartas partes de una palabra en español, menos en
código y bastante menos en un XML de la DIAN—. Lo operativo es esto: podés mandarle cincuenta mil
tokens de contratos y pagar poco, o pedirle que escriba tres mil tokens de respuesta y pagar más
por esos tres mil. **Toda optimización de costo empieza por mirar la columna de salida.**

**La latencia la manda lo que escribe, no lo que lee.** El tiempo hasta el primer token es más o
menos constante; a partir de ahí es un caudal de tokens por segundo. Una respuesta de mil tokens
tarda del orden de diez veces lo que una de cien, con la misma entrada. Si la interfaz es un chat,
transmites en flujo y el usuario percibe otra cosa; si es un proceso por lotes, no importa.

**No es determinista, y eso no es un defecto que se corrija.** La misma petición, dos veces, da
dos respuestas distintas. Ninguna combinación de parámetros lo elimina —los modelos actuales del
curso ni siquiera aceptan `temperature`—, y la respuesta correcta de ayer puede no serlo hoy si
cambió el modelo. Todo el track `ia` está organizado alrededor de esa propiedad: `ia02` la
contiene con contratos, `ia06` la mide con evaluación, `ia07` la acota con guardrails.

### Tu instinto de Java dice… y esta vez se equivoca

Once años de integrar servicios REST te dejaron un reflejo bueno y automático: **si la llamada
falla o se pasa del timeout, reintenta.** Idempotencia por `GET`, backoff exponencial, tres
intentos, y a otra cosa.

Aquí ese reflejo cuesta dinero, y de una forma que la métrica no te va a mostrar:

```python
# ❌ El reflejo. Corre, no falla, y el 5 de cada mes Julián pregunta por la factura.
def ask_with_retry(question: str) -> str:
    for attempt in range(3):
        try:
            response = client.with_options(timeout=10.0).messages.create(
                model="claude-opus-5",
                max_tokens=16000,
                messages=[{"role": "user", "content": question}],
            )
            return next(b.text for b in response.content if b.type == "text")
        except anthropic.APITimeoutError:
            continue
    raise RuntimeError("El modelo no respondió")
```

Tiene tres problemas y ninguno es visible desde afuera. El primero: **un timeout del cliente no
cancela la generación del servidor**. La respuesta se generó, se cobró, y tú la tiraste; el
reintento genera y cobra otra. Con diez segundos de timeout sobre un modelo que razona, estás
pagando tres respuestas y usando una. El segundo: **el SDK ya reintenta** los 429, los 5xx y los
errores de conexión con backoff, dos veces por defecto — tu bucle multiplica por tres los
reintentos del SDK, y son nueve peticiones. El tercero: **no distingue lo que se reintenta de lo
que no**. Un `BadRequestError` porque el prompt excedió el contexto se va a reintentar tres veces
para fallar tres veces igual.

Lo que se escribe en su lugar es más corto, y la parte importante es lo que **no** hace:

```python
# ✅ El SDK reintenta lo reintentable. Tú decides el presupuesto de tiempo y qué haces al perderlo.
client = anthropic.Anthropic(max_retries=3, timeout=120.0)

def ask(question: str) -> str:
    """Hace una pregunta y devuelve el texto. Deja subir lo que no se puede reintentar."""
    response = client.messages.create(
        model="claude-opus-5",
        max_tokens=4096,
        messages=[{"role": "user", "content": question}],
    )
    return next(b.text for b in response.content if b.type == "text")
```

El timeout se sube en vez de bajarse, porque el modo de fallo caro no es esperar de más: es pagar
dos veces. Y el número de reintentos vive en el cliente, en un solo lugar, donde alguien lo puede
auditar.

> 🧭 **La regla del track:** en un servicio con tarifa por token, **un reintento es una compra**.
> Antes de escribir uno, pregúntate qué estás comprando y si ya lo pagaste.

Hay un segundo reflejo, más sutil, que conviene desarmar aquí porque envenena todo lo que sigue:
**"le pongo temperatura cero y ya es determinista"**. No. Aun con muestreo fijo hay no
determinismo en la infraestructura, el modelo cambia de versión bajo tus pies, y —lo que de verdad
importa— *determinista* no significa *correcto*. Una función que devuelve siempre la misma
respuesta equivocada es peor que una que varía, porque no la vas a descubrir con una prueba.

### Esto sí funciona igual

Casi toda tu experiencia de integración se transfiere intacta, y conviene decirlo porque el ruido
alrededor de la IA sugiere lo contrario:

- **Es HTTP.** Códigos de estado, cabeceras, `retry-after`, límites de tasa por organización. El
  429 se lee como siempre.
- **El backoff exponencial con jitter** es el mismo que escribiste diez veces, y aquí ya viene
  hecho en el SDK.
- **Los secretos se manejan igual.** Variable de entorno o gestor de secretos, nunca el archivo de
  configuración, nunca el repositorio. La rotación es la misma disciplina.
- **La observabilidad es la misma.** Registras la petición, la latencia, el identificador de
  petición y el resultado, con el `logging` de la Fase 16. Lo único nuevo es que agregas una
  columna: **dinero**.
- **El presupuesto y el circuit breaker** son los patrones de siempre. Un servicio que puede
  gastar sin techo es un incidente esperando fecha.

### Diccionario de traducción

| Java / tu stack | Track `ia` | Dónde se rompe el paralelo |
|---|---|---|
| Llamada REST con DTO de respuesta | `messages.create()` con lista de bloques | La respuesta no tiene forma garantizada: es texto hasta que `ia02` le pone un contrato |
| Excepción chequeada | `stop_reason` | No se lanza nada. La petición devuelve 200 y `refusal`; si no miras el campo, procesas una respuesta vacía como si fuera buena |
| Caché HTTP por `ETag` | Caché de prompt | No cachea la **respuesta**, cachea el **prefijo de la petición**. Dos preguntas distintas sobre el mismo contrato aciertan la caché; la misma pregunta dos veces, no necesariamente |
| Pool de conexiones | Límite de tasa por organización | El cuello no es tu proceso: es una cuota compartida entre todo lo que tu organización esté corriendo |
| `assertEquals(expected, actual)` | Evaluación con umbral (`ia06`) | La igualdad exacta no aplica. La prueba pasa con una distribución, no con un valor |
| Coste de infraestructura mensual, fijo | Costo por token, variable | Escala con el uso y **con la longitud de la conversación**, que es la variable que nadie modela al principio |
| `@Transactional` / reintento idempotente | Reintento de una petición al modelo | No es idempotente ni gratis: el reintento genera texto nuevo y lo cobra |

> 📝 **Nota de ecosistema.** El SDK `anthropic` **1.5.0** que fija el curso está construido sobre
> `httpx2`, no sobre `httpx`: si importas la biblioteca HTTP por tu cuenta, es `import httpx2 as
> httpx`, y un objeto del paquete `httpx` de toda la vida se rechaza en tiempo de petición. Dos
> cosas más que vas a encontrar en material de internet escrito hace un año y que ya no aplican:
> el parámetro `output_format` de nivel superior quedó deprecado en favor de
> `output_config={"format": …}` —lo usa `ia02`—, y el presupuesto fijo de razonamiento
> (`thinking={"type": "enabled", "budget_tokens": N}`) fue **removido** en los modelos de la
> generación actual: devuelve 400. Hoy se usa razonamiento adaptativo y se regula con
> `output_config={"effort": …}`.

---

## 💻 5. Código mínimo con comentarios

El código de esta sección vive en `src/ia01-el-modelo-de-acceso-de-un-llm/` y es una
**herramienta**: paquete con tipos y pruebas, porque `ia05` y `ia07` lo van a importar. No es un
script del Bloque A y no se escribe como uno.

### 5.1 El precio, con su fecha

Empezamos por el módulo más aburrido y el que más discusiones evita. El precio es un dato que
envejece, así que se declara en un solo lugar, con la fecha en que se verificó y en `Decimal`,
porque es dinero y la Fase 01 no se olvida.

```python
# src/ia01-el-modelo-de-acceso-de-un-llm/pricing.py
"""Tarifas de los modelos que usa Áurea, con su fecha de verificación.

Verificado el 13 de septiembre de 2026 contra la documentación oficial de la API.
Los precios cambian: este archivo es el único lugar donde se tocan, y el que hay que
revisar antes de repetir cualquier medición de costo del track.
"""

from dataclasses import dataclass
from datetime import date
from decimal import Decimal

VERIFIED_ON = date(2026, 9, 13)

# Un millón de tokens. Se declara como constante porque aparece en cada división y
# un 1_000_000 suelto en medio de una fórmula es donde se cuela el error de factor mil.
TOKENS_PER_UNIT = Decimal(1_000_000)


@dataclass(frozen=True, slots=True)
class ModelPricing:
    """Tarifa de un modelo, en dólares por millón de tokens."""

    model_id: str
    input_per_unit: Decimal
    output_per_unit: Decimal
    context_window: int

    def cost_of(self, input_tokens: int, output_tokens: int) -> Decimal:
        """Costo en dólares de una petición ya ejecutada.

        No redondea: el redondeo es decisión de quien presenta el número, y redondear
        aquí escondería el costo de las peticiones baratas, que sumadas son la factura.
        """
        return (
            Decimal(input_tokens) * self.input_per_unit
            + Decimal(output_tokens) * self.output_per_unit
        ) / TOKENS_PER_UNIT


# El modelo por defecto del track es Opus 5. Haiku entra donde el volumen manda y la
# tarea es simple —clasificar, resumir una línea—, y esa decisión se toma con la
# medición de la sección 6, no por costumbre.
CATALOG: dict[str, ModelPricing] = {
    "claude-opus-5": ModelPricing(
        model_id="claude-opus-5",
        input_per_unit=Decimal("5.00"),
        output_per_unit=Decimal("25.00"),
        context_window=1_000_000,
    ),
    "claude-haiku-4-5": ModelPricing(
        model_id="claude-haiku-4-5",
        input_per_unit=Decimal("1.00"),
        output_per_unit=Decimal("5.00"),
        context_window=200_000,
    ),
}

# El modelo local no tiene tarifa por token, y poner Decimal("0") sería mentir por
# omisión: cuesta electricidad, RAM y —sobre todo— el tiempo de quien lo mantiene.
# Se representa como ausencia de tarifa para que el código que suma costos tenga que
# decidir explícitamente qué hace con él.
LOCAL_MODELS: frozenset[str] = frozenset({"gemma3"})
```

**Detalles con intención**

- `frozen=True, slots=True` — la tarifa es un valor, no un objeto con ciclo de vida. `slots`
  porque van a existir miles de instancias en la medición de la sección 6 y la memoria se nota.
- **`Decimal` y no `float`** — la regla es de la guía §6.6 y aquí no es ceremonia: la factura del
  mes es la suma de cuarenta mil peticiones de tres milésimas de dólar, y en `float` esa suma
  arrastra error.
- **Sin precio para el modelo local**, en vez de cero. Un cero se propaga en silencio; una
  ausencia obliga a decidir.

### 5.2 El cliente, y los cuatro fallos

```python
# src/ia01-el-modelo-de-acceso-de-un-llm/llm.py
"""Cliente del modelo para las herramientas de Áurea.

Es la única puerta por la que el código del track habla con la API. Todo lo que
importe —modelo, presupuesto de tiempo, reintentos, registro— se decide aquí.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal

import anthropic

from pricing import CATALOG, ModelPricing

logger = logging.getLogger(__name__)

DEFAULT_MODEL = "claude-opus-5"

# El timeout es alto a propósito. Un modelo que razona puede tardar minutos en una
# pregunta difícil, y cortarlo antes no ahorra dinero: la generación siguió del otro
# lado y se cobró igual. Lo que se acota con timeout bajo es la experiencia de usuario,
# y eso se resuelve transmitiendo en flujo, no cancelando.
DEFAULT_TIMEOUT_SECONDS = 120.0

# Reintentos del SDK: cubre 408, 409, 429, 5xx y errores de conexión, con backoff
# exponencial. No se escribe un bucle encima; ver la sección 4.
DEFAULT_MAX_RETRIES = 3


@dataclass(frozen=True, slots=True)
class Answer:
    """Lo que devuelve una consulta al modelo, con su factura pegada.

    El costo viaja con la respuesta y no en un contador global: una respuesta que no
    sabe lo que costó es una respuesta que nadie va a poder auditar en el cierre de mes.
    """

    text: str
    model: str
    input_tokens: int
    output_tokens: int
    cached_input_tokens: int
    cost: Decimal
    stop_reason: str
    request_id: str | None


class ModelRefusedError(RuntimeError):
    """El modelo declinó contestar. No es un error de red y no se reintenta igual."""


def build_client(
    *,
    timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS,
    max_retries: int = DEFAULT_MAX_RETRIES,
) -> anthropic.Anthropic:
    """Construye el cliente.

    Sin argumento de clave: las credenciales se resuelven por entorno. Pasar la clave
    por parámetro invita a que alguien la escriba en una llamada, y esa llamada termina
    en el historial de git.
    """
    return anthropic.Anthropic(timeout=timeout_seconds, max_retries=max_retries)


def ask(
    client: anthropic.Anthropic,
    question: str,
    *,
    system: str | None = None,
    model: str = DEFAULT_MODEL,
    max_tokens: int = 4096,
) -> Answer:
    """Hace una pregunta y devuelve la respuesta con su costo.

    Lanza las excepciones del SDK sin envolverlas: quien llama necesita distinguir un
    429 de un 400, y una jerarquía propia encima solo borraría esa distinción.
    """
    pricing: ModelPricing = CATALOG[model]

    # El sistema se arma aparte en vez de pasar None: el SDK distingue "no lo mandes"
    # de "mándalo vacío", y un system vacío cuenta tokens y cambia el prefijo de caché.
    extra: dict[str, str] = {"system": system} if system is not None else {}

    response = client.messages.create(
        model=model,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": question}],
        **extra,
    )

    # Primero el motivo de parada, antes de tocar el contenido. Una negativa devuelve
    # 200 con contenido vacío: si lees el texto sin mirar esto, procesas un vacío como
    # si fuera una respuesta buena, y ese es el fallo silencioso de la sección.
    if response.stop_reason == "refusal":
        detail = response.stop_details
        category = detail.category if detail is not None else "sin categoría"
        raise ModelRefusedError(f"El modelo declinó la petición ({category}).")

    if response.stop_reason == "max_tokens":
        # No es un error: es una respuesta cortada a mitad de frase. Se avisa, porque
        # el código de arriba puede estar a punto de guardarla como si estuviera completa.
        logger.warning(
            "Respuesta truncada por max_tokens (%d). El texto está incompleto.",
            max_tokens,
        )

    text = "".join(block.text for block in response.content if block.type == "text")

    usage = response.usage
    # Los tokens leídos de caché se cobran a una fracción del precio. En esta sección
    # siempre van a ser cero porque todavía no cacheamos nada; se registran desde ahora
    # para que la medición de ia08 tenga con qué comparar.
    cached = usage.cache_read_input_tokens or 0
    cost = pricing.cost_of(usage.input_tokens + cached, usage.output_tokens)

    logger.info(
        "modelo=%s entrada=%d salida=%d costo=%s parada=%s peticion=%s",
        model,
        usage.input_tokens,
        usage.output_tokens,
        cost,
        response.stop_reason,
        response._request_id,
    )

    return Answer(
        text=text,
        model=response.model,
        input_tokens=usage.input_tokens,
        output_tokens=usage.output_tokens,
        cached_input_tokens=cached,
        cost=cost,
        stop_reason=response.stop_reason or "end_turn",
        request_id=response._request_id,
    )
```

**Detalles con intención**

- **`stop_reason` se mira antes que el contenido.** Es el equivalente funcional de la excepción
  chequeada que este servicio no tiene, y saltárselo es el error número uno de la primera semana.
- **No hay jerarquía de excepciones propia** salvo `ModelRefusedError`, que existe porque una
  negativa **no es** un error de la API y necesita tratamiento distinto: no se reintenta igual,
  se registra y se escala a una persona.
- **`response._request_id` se registra siempre.** Cuando algo se comporte raro, es el único dato
  con el que se puede pedir soporte. El guion bajo despista: es público.
- **El costo viaja pegado a la respuesta.** Un contador global de gasto se desincroniza el día que
  alguien mete una llamada por otro camino.

**Prueba de fuego**

```bash
uv run python -c "
from llm import ask, build_client
a = ask(build_client(), '¿Qué es una glosa en facturación de salud en Colombia? Responde en dos frases.')
print(a.text); print(a.input_tokens, a.output_tokens, a.cost)
"
```

Lo que tiene que salir: dos frases, y un costo del orden de cinco milésimas de dólar
(24 tokens de entrada y 180 de salida en Opus 5 son exactamente `0.004620`). **La
mentira que te va a contar la salida si miras el lugar equivocado:** si te fijas solo en el texto,
la respuesta se ve perfecta y no te enteras de que `input_tokens` fue 24 y `output_tokens` 180 —es
decir, que el 97% de lo que pagaste fue la salida—. Esa proporción es la que decide todas las
optimizaciones que vienen después.

### 5.3 Contar antes de gastar

La diferencia entre una herramienta que se puede presupuestar y una que no es esta función. Es
también donde más gente se equivoca por usar el tokenizador equivocado.

```python
# src/ia01-el-modelo-de-acceso-de-un-llm/count_and_price.py
"""Estimación de costo antes de enviar la petición."""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

import anthropic

from pricing import CATALOG


@dataclass(frozen=True, slots=True)
class CostEstimate:
    """Estimación previa. El costo de salida es una cota superior, no una predicción."""

    input_tokens: int
    max_output_tokens: int
    worst_case_cost: Decimal


def estimate(
    client: anthropic.Anthropic,
    question: str,
    *,
    system: str | None = None,
    model: str = "claude-opus-5",
    max_tokens: int = 4096,
) -> CostEstimate:
    """Cuenta los tokens de entrada contra el modelo real y calcula el peor caso.

    La entrada se cuenta exacto porque la API la cuenta por ti. La salida no se puede
    saber de antemano —el modelo decide cuánto escribe—, así que se acota con max_tokens
    y se dice que es el peor caso. Prometer una estimación de salida sería inventarla.
    """
    pricing = CATALOG[model]

    extra: dict[str, str] = {"system": system} if system is not None else {}

    counted = client.messages.count_tokens(
        model=model,
        messages=[{"role": "user", "content": question}],
        **extra,
    )

    return CostEstimate(
        input_tokens=counted.input_tokens,
        max_output_tokens=max_tokens,
        worst_case_cost=pricing.cost_of(counted.input_tokens, max_tokens),
    )
```

> ⚠️ **No cuentes tokens con `tiktoken`.** Es el tokenizador de otro proveedor, subestima entre un
> 15% y un 20% en texto corriente y bastante más en código o en un XML de la DIAN, que es
> justamente lo que Áurea le va a mandar. El endpoint de conteo es gratis y exacto para el modelo
> que vas a usar; cualquier estimación por caracteres o por palabras es una fuente de sorpresas en
> la factura.

> 💡 **El truco que ahorra tiempo real:** `count_tokens` acepta la misma forma de petición que
> `create`. Puedes montarla una vez, contarla, decidir si cabe en el presupuesto y **reusar el
> mismo diccionario** para enviarla. Si la construyes dos veces, algún día van a diferir y vas a
> estar estimando una petición distinta de la que envías.

### 5.4 El modelo local, y para qué está de verdad

```python
# src/ia01-el-modelo-de-acceso-de-un-llm/local.py
"""Modelo local con Ollama.

Está por dos razones y conviene no confundirlas. La barata: los ejercicios de este
track no tienen por qué costar dinero. La importante: es la única vía por la que un
dato que roce la frontera clínica puede tocar un modelo, porque nunca sale de la
máquina. Ver 00-historia-de-aurea.md §5.
"""

from __future__ import annotations

from ollama import Client

LOCAL_MODEL = "gemma3"


def ask_local(question: str, *, model: str = LOCAL_MODEL, host: str | None = None) -> str:
    """Hace la misma pregunta a un modelo que corre en esta máquina.

    Sin costo por token y sin salida a la red. A cambio: más lento en un portátil,
    y con una calidad que la sección 6 mide en vez de suponer.
    """
    client = Client(host=host) if host is not None else Client()
    response = client.chat(
        model=model,
        messages=[{"role": "user", "content": question}],
    )
    return response.message.content or ""
```

> 💸 **Deuda técnica intencional.** `ask_local` devuelve texto pelado, sin tokens ni latencia, así
> que **no se puede comparar de igual a igual** con `ask`. Lo correcto sería una interfaz común
> —un `Protocol` con `ask(...) -> Answer`— y una implementación por proveedor. **Se paga en
> `ia06`**, cuando la evaluación tenga que correr el mismo conjunto contra los tres y la
> asimetría se vuelva insostenible. No se paga aquí porque abstraer dos proveedores antes de
> conocer el tercero es exactamente el reflejo que el camino base enseñó a no tener.

**El patrón a memorizar**

> El modelo local no es "la versión gratis". Es **la única opción cuando el dato no puede salir**,
> y esa restricción decide la arquitectura mucho antes que el presupuesto.

### 5.5 Provocar los cuatro fallos

No se entiende un modo de fallo hasta que lo ves. Estas cuatro pruebas son parte del entregable de
la sección y se corren una vez, a mano.

```python
# src/ia01-el-modelo-de-acceso-de-un-llm/test_failures.py
"""Los cuatro fallos que vas a ver en producción, provocados a propósito.

Se marcan como pruebas lentas y de red: no corren en el ciclo normal. Existen para que
la primera vez que veas cada uno no sea a las dos de la mañana.
"""

import anthropic
import pytest

from llm import ask, build_client

pytestmark = pytest.mark.network


def test_context_too_large_fails_fast() -> None:
    """Pasarse del contexto es un 400: no se reintenta y hay que detectarlo antes."""
    client = build_client(max_retries=0)
    huge_question = "hola " * 400_000

    with pytest.raises(anthropic.BadRequestError):
        ask(client, huge_question)


def test_timeout_does_not_cancel_the_generation() -> None:
    """El timeout es del cliente. Del otro lado la respuesta se generó y se cobró."""
    client = anthropic.Anthropic(timeout=0.5, max_retries=0)

    with pytest.raises(anthropic.APITimeoutError):
        ask(client, "Escribe un resumen de 2.000 palabras sobre ortodoncia.")

    # 🧨 Rompe a propósito: mira la consola de uso después de correr esto. Los tokens
    # de esa respuesta que nunca viste están facturados. Ese es el punto de la prueba.
```

Los otros dos —el 429 y la negativa— **no se provocan con una prueba automática**: el 429 depende
de la cuota de tu organización y forzarlo perjudica a lo demás que esté corriendo, y una negativa
depende de pedirle al modelo algo que no debería hacer, que no es material de curso. Se documentan
y se manejan en el código, que es lo que corresponde:

- **429** — el SDK reintenta respetando `retry-after`. Si aun así llega hasta ti, no insistas:
  encola y avisa. Un 429 sostenido es un problema de diseño de concurrencia, no de reintento.
- **`refusal`** — llega como 200 con `stop_reason` de negativa y `stop_details.category`. En
  Recepción asistida (`ia07`) esa rama **escala a una persona**, que es la respuesta correcta y la
  única defendible.

---

## 📏 6. Medición

**Hipótesis.** Para las preguntas frecuentes de Patricia —cortas, sobre coberturas, respondibles
en menos de doscientos tokens— **Haiku 4.5 entrega una respuesta indistinguible de la de Opus 5 a
una quinta parte del costo**, y el modelo local en el portátil de Áurea es entre cinco y diez
veces más lento que cualquiera de los dos.

**Condiciones.** Python 3.14.7; `anthropic` 1.5.0; Ollama 0.6.2 con `gemma3`. Portátil de
referencia del curso, declarado en `BENCHMARKS.md`. Veinte preguntas reales tomadas del historial
de WhatsApp de la sede Centro, seudonimizadas, **sin un solo dato clínico**; treinta repeticiones
por modelo, en orden intercalado para que una degradación de red no se le cargue entera a un
modelo. Se mide latencia de extremo a extremo (mediana y p95, reloj monótono, arnés de la Fase
02), tokens de entrada y salida reportados por la API, y costo calculado con `pricing.py`. **No se
mide calidad**: eso es `ia06`, y decirlo aquí es parte de la medición.

**Competidores.** Los tres son defendibles y por eso están: **Opus 5** es la elección por defecto
del track; **Haiku 4.5** es lo que cualquiera propondría en una revisión al ver el volumen;
**`gemma3` en Ollama** es la única opción compatible con la frontera clínica y la que Julián va a
pedir en cuanto vea la primera factura. El cuarto competidor, y el que gana algunas de estas
preguntas, es **la consulta SQL contra la tabla de coberturas que ya existe** — no entra en la
tabla porque no contesta las mismas veinte preguntas, y esa asimetría es el tema de `ia08`.

**Resultado.**

| Modelo | Latencia p50 | Latencia p95 | Tokens entrada (med.) | Tokens salida (med.) | Costo por respuesta | Costo · 900 preguntas/día |
|---|---|---|---|---|---|---|
| `claude-opus-5` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| `claude-haiku-4-5` | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| `gemma3` (Ollama, local) | ⏳ | ⏳ | — | — | sin tarifa | sin tarifa |

```bash
uv run python bench_models.py --questions preguntas_patricia.jsonl --repeats 30 --out bench_ia01.json
```

> ⚖️ **Veredicto — pendiente de correr, con la expectativa declarada.** Lo que esperamos es que
> Haiku gane por costo sin pérdida perceptible en preguntas de una línea, y que el umbral esté en
> la longitud de la respuesta: por encima de unos quinientos tokens de salida, o cuando la
> pregunta exige encadenar dos cláusulas de contratos distintos, la diferencia de calidad debería
> aparecer y Opus debería justificar su precio. **El umbral exacto está por determinar y se
> escribe aquí cuando la medición se corra**; hasta entonces esta celda dice `⏳` y ninguna
> sección del track cita un número de aquí.

> 📝 **Y lo que esta medición deliberadamente no dice:** cuál contesta *mejor*. Con veinte
> preguntas y el ojo del autor no se sostiene una afirmación de calidad, y fingir lo contrario
> sería exactamente el error que `ia06` existe para corregir.

---

## 🧱 7. Miniproyecto — El memo que Julián firma

**El encargo.** Julián te preguntó en un asado *"¿y eso cuánto nos va a costar al mes?"*, y la
respuesta correcta no es un número: es una herramienta que produzca el número y que él pueda
volver a correr en marzo cuando cambien las tarifas. Construye `aur-llm-budget`, una herramienta
de línea de comandos que, dado un archivo con el tráfico esperado, produce el presupuesto mensual
de los dos proyectos de IA de Áurea con su desglose y sus supuestos escritos.

**Por qué duele.** Porque el número obvio está mal por un factor de tres o cuatro, y la
herramienta tiene que llegar al bueno. Tres cosas lo hunden: la conversación multiturno reenvía la
historia y su costo crece con el cuadrado de los turnos; el sistema y las instrucciones se pagan
en **cada** petición, no una vez; y la salida cuesta cinco veces la entrada, así que un
`max_tokens` generoso puesto por comodidad es una línea de la factura.

**Datos de entrada.** Un `trafico.toml` que describe los dos proyectos con las cifras reales de la
historia de Áurea: NormaRAG con las consultas de coberturas de Patricia y las auxiliares —del
orden de una hora diaria de trabajo hoy—, y Recepción asistida con los **900 mensajes de WhatsApp
al día** de las diez sedes, de los cuales una fracción abre conversación de varios turnos. El
archivo lo escribes tú a partir de la historia; parte del encargo es decidir qué campos necesita.

**Criterios de aceptación.**

1. `aur-llm-budget estimar --trafico trafico.toml` imprime el costo mensual por proyecto y el
   total, en `Decimal`, con la tarifa y **su fecha de verificación** en el encabezado.
2. Modela el **crecimiento cuadrático** de la conversación: un escenario de 6 turnos cuesta más
   del triple que uno de 2 turnos con el mismo número de conversaciones, y la herramienta lo
   demuestra con `--turnos 2` y `--turnos 6`.
3. `--modelo claude-haiku-4-5` recalcula todo y la diferencia contra Opus 5 es exactamente la
   razón de las tarifas aplicada a la mezcla real de entrada y salida — no una regla de tres sobre
   el total.
4. `--verificar` toma una muestra de diez peticiones reales, las ejecuta y compara el costo
   estimado contra el cobrado. **La desviación tiene que ser menor al 5%**, y la herramienta falla
   con código de salida distinto de cero si no lo es.
5. Un `--limite 200` hace que la herramienta salga con código 2 cuando el presupuesto proyectado
   supera los 200 dólares mensuales, para poder colgarla de una alerta.
6. La salida incluye una sección **"supuestos"** con cada cosa que la herramienta asumió, en
   español y legible por Julián. Sin esa sección el entregable no se acepta: un presupuesto sin
   supuestos es una adivinanza con formato de tabla.

**Restricciones de registro.** Es una **herramienta**, no una aplicación: paquete con `src/`,
tipos estrictos, pruebas, distribuible con `uv tool`. No lleva base de datos, no lleva servicio
web y no lleva una capa de abstracción de proveedores — con dos proveedores no se abstrae nada,
se acopla feo.

**La trampa.** El `--verificar` del criterio 4 va a fallar la primera vez, y el motivo es el que
hace útil el miniproyecto: **el costo de la caché de prompt y el de los tokens de razonamiento no
están donde crees que están**. Los tokens leídos de caché se cobran a una fracción y aparecen en
un campo distinto; el razonamiento del modelo se factura como salida aunque no lo veas en el
texto. Si tu estimación sale sistemáticamente baja, mira `usage` completo antes de tocar la
fórmula.

**Pistas.** Reusa `pricing.py` y `count_and_price.py` sin modificarlos —si necesitas cambiarlos,
la sección 5 está mal escrita y quiero saberlo—. Para el crecimiento cuadrático, la cuenta que
buscas es la suma de los prefijos, no el promedio por turno. Y escribe la prueba del criterio 2
antes que el código: es la que te dice si entendiste el problema.

**Cómo se entrega.** `git tag -a ia-mini-01`, y **en el mensaje del tag va el costo mensual total
que arrojó tu herramienta para los dos proyectos**, con la fecha de la tarifa. Dentro de un año
ese número va a ser la mitad o el doble, y vas a poder ver cuál con un `git show`.

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre la misma pregunta cinco veces con el mismo código y guarda las cinco respuestas. Escribe
   en tres líneas qué cambió entre ellas y qué no. Esta es la única forma de creerse el no
   determinismo.
2. Haz que `ask` acepte un parámetro `effort` y compara `low` contra `high` en una pregunta de
   cobertura: mide tokens de salida y latencia en cada uno.
3. Agrega el conteo previo a `ask`: que registre la estimación y el cobro real en la misma línea
   de log, para poder buscar desviaciones con `grep`.
4. Toma tres textos de Áurea —una pregunta de WhatsApp, una cláusula de contrato y un fragmento
   de XML de la DIAN— del mismo número de caracteres, y cuenta sus tokens. Explica el orden que
   sale.
5. Cambia `max_tokens` a 100 en una pregunta que necesite más, y describe exactamente cómo se ve
   una respuesta truncada desde el código. ¿Qué campo te lo dice y qué campo te miente?
6. Haz que `pricing.py` falle al importarse si `VERIFIED_ON` tiene más de noventa días. Justifica
   en un comentario por qué noventa y no trescientos sesenta y cinco.

**🟡 Intermedio (7–14)**

7. Implementa `ask_streaming` con `client.messages.stream(...)` y `get_final_message()`, y mide el
   **tiempo hasta el primer token** contra el tiempo total. Explica en qué interfaz de Áurea
   importa esa diferencia y en cuál no.
8. Añade un presupuesto duro: una clase que acumule el gasto del proceso y lance cuando pase de un
   tope. Decide y defiende dónde va la comprobación —antes de enviar o después de cobrar— sabiendo
   que solo una de las dos previene el gasto.
9. Escribe un `Protocol` con la operación de preguntar y haz que el cliente remoto y el local lo
   cumplan. Después mide cuántas líneas te costó y decide si valió la pena; escribe la respuesta,
   sea cual sea. Es la deuda 💸 de la sección 5.4, y aquí la pagas antes de tiempo a propósito.
10. Registra cada llamada en una tabla SQLite con pregunta, modelo, tokens, costo e identificador
    de petición. Consulta el gasto por día. Es el esqueleto de lo que `ia08` necesita.
11. Provoca un `BadRequestError` de tres formas distintas —contexto excedido, `max_tokens` mayor
    que el permitido, y un modelo que no existe— y compara los mensajes. ¿Cuál de los tres se
    puede detectar antes de enviar?
12. Corre la misma pregunta contra `gemma3` y contra `claude-haiku-4-5`, y escribe un párrafo
    honesto sobre en qué se diferencian las respuestas. Sin números todavía: es un juicio, y hay
    que reconocerlo como tal.
13. Mide cuánto tarda `count_tokens` y calcula qué porcentaje del tiempo total añade a una
    petición corta. Decide si vale la pena llamarlo siempre, a veces o nunca.
14. Toma la conversación de tres turnos del ejercicio 7 y calcula a mano cuántos tokens de entrada
    se pagaron en total. Compáralo con la suma de lo que "parece" que se mandó.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Te entregan un servicio que hace ochocientas llamadas diarias y cuya factura
    subió 40% sin que subiera el tráfico. Con solo el registro de `usage` de cada llamada,
    localiza la causa. Hay tres candidatas plausibles y solo una deja rastro en `output_tokens`.
16. **Medición.** Cuantifica el costo del reflejo de la sección 4: implementa el reintento
    ingenuo con timeout de diez segundos, corre cincuenta preguntas y compara el gasto real contra
    el del cliente bien configurado. El número que salga es tu autopsia de anti-patrón ⚰️.
17. Implementa concurrencia con `asyncio` y `AsyncAnthropic` sobre las veinte preguntas del banco,
    y encuentra el punto donde empiezas a recibir 429. Documenta el límite observado y qué haces
    al alcanzarlo, sabiendo que la cuota es de la organización y no tuya.
18. **Diagnóstico.** Un compañero puso `temperature` en la petición y le devolvió 400. Explica por
    qué el parámetro desapareció en esta generación de modelos, qué problema resolvía y con qué se
    resuelve hoy lo que la gente creía estar resolviendo con él.
19. **De registro.** Áurea necesita clasificar los 900 mensajes diarios de WhatsApp en cinco
    categorías. Decide si eso es un script, una herramienta o una aplicación, y **cuantifica el
    costo de las otras dos opciones**. Después decide si necesita un LLM, y cuantifica esa
    alternativa también.
20. **De registro.** Julián quiere "un chat con la IA" en la página web de Áurea. Escribe la
    contrapropuesta en media página: qué registro es realmente, qué se puede entregar en una
    semana, y qué parte de lo que pidió es la cara y por qué.
21. Toma la medición de la sección 6 y córrela en dos momentos del día distintos. Si los p95
    difieren más de un 30%, escribe qué significa eso para el diseño del cierre nocturno.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Diseña y ejecuta el experimento que refute la hipótesis de la sección 6:
    encuentra la familia de preguntas de Áurea donde Haiku pierde de forma medible contra Opus.
    Si no la encuentras, escribe eso —un resultado negativo bien buscado es un resultado.
23. Modela el costo total de propiedad a tres años de las tres opciones —API con Opus, API con
    Haiku, y modelo local en un servidor de Áurea— incluyendo el hardware, la electricidad y **las
    horas de la única persona que lo va a mantener**, que eres tú. Defiende el resultado.
24. **Adversarial.** El modelo local corre en la sede y por lo tanto puede ver datos clínicos.
    Escribe el documento de una página que autoriza —o no— ese uso: qué dato exacto entra, quién
    audita el acceso, qué queda registrado, y qué pasa cuando el portátil se pierde. La §5 de la
    historia de Áurea es la restricción; esto es lo que se le entrega a un abogado.
25. Implementa un interruptor de circuito completo alrededor del cliente —umbral por tasa de
    error, por latencia p95 y por gasto acumulado, con su estado semiabierto— y demuestra con una
    prueba que corta antes de que la factura se dispare. Después argumenta cuál de los tres
    umbrales es el que de verdad importa en Áurea.

**🔥 Opcionales**

- Lee `usage.iterations` en una respuesta larga y explica qué te está contando.
- Compara el mismo prompt contra dos modelos locales de tamaños distintos y grafica calidad
  percibida contra memoria RAM. Es el prototipo de lo que `ia06` va a hacer bien.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://docs.claude.com/en/api/overview` — la API de mensajes: parámetros, bloques de
  contenido, `stop_reason` y `usage`. Es la referencia que manda sobre cualquier cosa que diga
  esta sección.
- `https://docs.claude.com/en/docs/about-claude/models/overview` — identificadores de modelo,
  ventanas de contexto y capacidades. Verifica siempre contra esta página: los identificadores
  del curso están fijados con su fecha, y esa fecha envejece.
- `https://docs.claude.com/en/docs/about-claude/pricing` — las tarifas. **Es el enlace que hay que
  reabrir antes de repetir la medición de la sección 6.**
- `https://github.com/anthropics/anthropic-sdk-python` — el SDK. El `MIGRATION.md` del repositorio
  explica el salto de 0.x a 1.x, que es lo que hace que casi todo el material de internet sobre
  este SDK esté un paso atrás.
- `https://github.com/ollama/ollama-python` — el cliente de Ollama, versión 0.6.2.
- `https://docs.python.org/3.14/library/decimal.html` — por si hay que defender ante alguien por
  qué la factura no se suma en `float`.

**Libros / artículos**

- *Designing Data-Intensive Applications*, Martin Kleppmann — el capítulo sobre fiabilidad y modos
  de fallo se lee distinto cuando el servicio del que dependes cobra por byte generado. Título y
  edición pueden haber cambiado; verifícalos.

**Orden de lectura sugerido:** la página de modelos y la de precios **antes** de escribir código,
para fijar identificadores y tarifas con su fecha → la referencia de la API de mensajes mientras
escribes `llm.py`, con la sección de `usage` abierta → el `MIGRATION.md` del SDK después, cuando
encuentres el primer ejemplo de internet que no compila.

> ⚠️ URLs, títulos y contenidos pueden haber cambiado desde la fecha de verificación; el lector
> debe comprobarlos. Aquí no se inventan páginas, ISBN ni identificadores de video.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con lo que ninguna demostración de IA trae y toda herramienta de producción necesita: un
cliente configurado como se configura una dependencia de red seria, el costo de cada respuesta
pegado a la respuesta, la capacidad de estimar antes de gastar, y un modelo local para lo que no
puede salir de la máquina. Y con una tabla que dice `⏳`, que es más honesto que una tabla con
números inventados.

También terminas con un problema evidente: **la respuesta es un texto y tu programa necesita un
dato**. Hoy, para saber si la prepagada cubre el retiro de brackets, alguien tiene que leer un
párrafo. Eso no se puede meter en una factura, ni en una alerta, ni en un `if`. Esa es la sección
`ia02`: cómo se le pone un contrato a la salida de un modelo, con Pydantic —que ya usas desde la
Fase 10— del mismo lado que siempre, y qué hacer cuando el contrato no se cumple, que va a pasar.

> **La señal de que quedó bien:** cuando puedas contestar *"esa pregunta cuesta tres milésimas de
> dólar y tarda dos segundos"* sin abrir la consola, y **cuando el reflejo de meter un reintento
> te dé desconfianza en vez de tranquilidad.**

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ia-fase-01 -m "ia01 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ia 01: …`), los de ejercicio su número
> (`ia 01 ej12: …`) y el miniproyecto el suyo (`ia 01 mini: …`). El miniproyecto terminado lleva
> además su tag anotado `ia-mini-01`, y **en el mensaje de ese tag va el presupuesto mensual que
> arrojó tu herramienta**, con la fecha de la tarifa. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
