# ⚖️ ia08 — Producción, y el veredicto del track

> Python para desarrolladores Java senior · Track `ia` · sección 8 de 8 🏁
> Depende de: todo el track · Habilita: el track `ds`
> Registro de esta sección: aplicación
> Proyecto que avanza: los dos — NormaRAG y Recepción asistida, puestos a producir

---

## 🎯 1. Propósito

Los dos proyectos funcionan. Uno cita o se calla; el otro escala o propone. Lo que ninguno de los
dos tiene todavía es lo que separa una demostración de algo que Áurea puede sostener tres años con
un solo ingeniero: **saber cuánto cuesta, no poder gastar más de la cuenta, y enterarse cuando algo
se degrada**.

Y después de eso, la sección hace lo único que este curso se debe a sí mismo: **el veredicto**.
Cuándo NO usar un LLM, con los números de Áurea delante y con la valentía de decir que alguno de
los dos proyectos no debió construirse.

> 🧭 **La pregunta que cierra el track:** de todo lo que construiste en siete secciones, ¿qué parte
> se queda, qué parte se borra, y qué parte nunca debió empezar? Si la respuesta es "todo se
> queda", la sección está mal escrita.

---

## ✅ 2. Qué queda listo al terminar

- [ ] La caché de prompt está colocada donde de verdad acierta, y lo demuestras con
      `cache_read_input_tokens` distinto de cero en peticiones repetidas.
- [ ] Probaste la inyección desde el documento (el ejercicio 24 de `ia02`) contra Recepción
      asistida, y ninguna instrucción escondida llega a confirmar una cita ni pasa la revisión de
      salida de `ia07`.
- [ ] `audit_prefix.py` detecta un invalidador silencioso comparando dos peticiones, y lo pruebas
      con los cuatro clásicos: reloj, identificador, JSON sin ordenar y lista de herramientas que
      cambia de orden.
- [ ] Hay un presupuesto por usuario y por día que **corta**, en `Decimal`, y una prueba que lo
      demuestra sin llamar a la API.
- [ ] El registro de producción guarda lo que hace falta para mejorar el sistema y **no guarda** lo
      que no se puede guardar. La frontera está escrita y probada.
- [ ] `bench_caching.py` produce la tabla de la sección 6 sobre el tráfico de un día.
- [ ] Existe la comparación medida contra un framework, con la misma tarea y el mismo conjunto de
      evaluación de `ia06`.
- [ ] Está escrito el ⚖️ veredicto de los dos proyectos, con su número y con su condición de
      revisión.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra

Esta es la última sección del track, así que aquí no hay diferimientos: lo que no entra, no entra.

- **Despliegue, contenedores y orquestación.** El camino base ya decidió que no hay fase de eso
  (`0-ESTRUCTURA-CURSO.md`), y estos dos servicios se despliegan como los cuatro del camino base.
- **Un panel de observabilidad.** El track `ui` a la carta lo cubre; aquí se producen las métricas,
  no las pantallas.
- **Afinamiento de modelos.** Fuera del curso, declarado desde `ia01`.
- **La evaluación de conversaciones de varios turnos.** `ia06` montó el aparato para respuestas de
  un turno y `ia07` lo aplicó a su guardrail; evaluar un hilo completo es un problema abierto y el
  curso **lo declara abierto** en vez de resolverlo mal en media sección.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

El reflejo es sobre la caché, y es de los más arraigados porque llevas una década aplicándolo bien:
**una caché es una clave y un valor**. `@Cacheable("coberturas")`, la clave sale de los argumentos,
el valor es lo que devolvió el método, y si acierta te ahorras la llamada entera.

La caché de prompt no es eso, y confundirlas produce código que parece correcto y no ahorra nada.

```python
# ❌ El reflejo. Cachear "la respuesta a esta pregunta". Ni siquiera es lo que la API ofrece.
@lru_cache(maxsize=1024)
def answer(question: str) -> str:
    return call_model(system=SYSTEM, question=question)
```

Tres diferencias, y las tres cambian el diseño:

**Cachea el prefijo de la petición, no la respuesta.** Lo que se reutiliza es el trabajo de leer
los primeros N tokens: el sistema, las herramientas, los documentos que van al principio. La
respuesta se genera igual, y se paga igual. Por eso la caché no reduce el costo de salida ni un
peso, y por eso `ia01` insistía en mirar la columna de salida.

**El orden de renderizado es fijo y hay que conocerlo**: `tools` → `system` → `messages`. Lo
estable va delante y lo volátil detrás del último punto de corte. Si pones la pregunta del usuario
antes del contrato, has invalidado todo lo que sigue.

**Y falla en silencio.** Cualquier byte que cambie en el prefijo invalida todo lo posterior, sin
error, sin aviso, sin nada en el log: simplemente la siguiente petición cuesta el precio completo.
Los cuatro invalidadores clásicos son de manual y los cuatro dan ganas de escribirlos:

```python
# ❌ Los cuatro asesinos silenciosos de la caché. Ninguno falla. Todos cuestan.
system = f"Hoy es {datetime.now():%Y-%m-%d %H:%M}. Eres el asistente…"   # ① el reloj
system += f"\nID de sesión: {uuid4()}"                                    # ② el identificador
system += f"\nCoberturas: {json.dumps(coverages)}"                        # ③ dict sin ordenar
tools = [t for t in registry.values()]                                     # ④ orden no garantizado
```

El ① es el más frecuente y el más razonable de escribir: el modelo necesita saber qué día es. La
solución no es quitárselo, es **moverlo detrás del último punto de corte**, al mensaje del usuario,
donde ya no invalida nada.

> 🧭 **La regla:** la caché de prompt es un **prefijo**, no una clave. Lo estable delante, lo
> volátil detrás, y **se verifica con `cache_read_input_tokens`** — si es cero en peticiones
> repetidas, hay un invalidador, y no te lo va a decir nadie.

Y hay dos detalles operativos que conviene saber antes de medir, porque explican el *"lo puse y no
ahorró nada"*: **hay un mínimo de tokens para que un prefijo se cachee** —del orden de cientos, y
depende del modelo—, así que un sistema corto no cachea por mucho `cache_control` que le pongas; y
**escribir en la caché cuesta más que una lectura normal** (del orden de 1.25×), mientras que leer
cuesta una fracción. Con tráfico bajo y prefijos que expiran entre peticiones, la caché puede salir
**más cara**. Eso es la medición de la sección 6.

### El segundo reflejo: instrumentar con las métricas de siempre

Tu instrumentación por defecto es buena y aquí se queda corta en dos sitios.

Le falta **la columna de dólares**. Un servicio cuyo p95 está perfecto y cuyo gasto se triplicó no
tiene un problema de rendimiento, tiene un problema, y la única forma de verlo es acumular
`usage` por petición como hace `Answer` desde `ia01`.

Y le falta **la métrica que no existe en tu mundo**: la tasa de abstención de NormaRAG y la de
escalamiento de Recepción asistida. Son la señal de salud más temprana que tienen estos dos
sistemas. Si la abstención sube tres puntos en una semana, algo pasó —el corpus envejeció, alguien
tocó el troceado, cambió el modelo— y te enteras antes de que Patricia deje de abrir la
herramienta. Ninguna alerta de las que sabes poner se dispara con eso.

### Qué se registra, y qué no se puede registrar

Esta decisión es de las que hay que escribir antes del código, porque revertirla implica borrar
datos que ya guardaste.

| Se registra | No se registra |
|---|---|
| Identificador del hilo, sede, marca de tiempo | El texto del mensaje del paciente |
| La **clasificación** del mensaje y el motivo del escalamiento | Adjuntos, ni su contenido ni una copia |
| Fragmentos recuperados (sus identificadores) y citas rechazadas | Nada del odontograma, diagnóstico o plan clínico |
| Tokens, costo, latencia, modelo y versión del prompt | — |
| El borrador **bloqueado** por la capa ③ de `ia07` | — |

La primera fila de la derecha duele, porque el texto del mensaje es justamente lo que necesitas
para descubrir los falsos negativos reales que `ia07` declaró como su omisión más importante. La
salida no es guardarlo igual: es **guardar el hash y la clasificación**, y montar un procedimiento
en el que una persona con acceso legítimo revise una muestra del canal original. Menos cómodo,
defendible ante un abogado, y es el criterio 6 del miniproyecto.

> ⚠️ **El borrador bloqueado sí se guarda, y merece su frase.** Es texto que el modelo generó y que
> el sistema impidió enviar; no es información del paciente y es la materia prima para mejorar el
> prompt. Sin él solo sabes que algo se bloqueó, que es la peor de las dos situaciones.

### Esto sí funciona igual

- **El presupuesto y el interruptor de circuito** son los patrones de siempre, con dólares en vez
  de errores por segundo.
- **Los límites de tasa por usuario** son los de la Fase 16, sin cambios.
- **El registro estructurado** es `structlog` y la misma disciplina de campos de la Fase 16.
- **El despliegue** es el de los cuatro proyectos del camino base.
- **La retención de datos** es una política, se escribe, y se implementa borrando.

### Diccionario de traducción

| Java / tu stack | Track `ia` | Dónde se rompe el paralelo |
|---|---|---|
| `@Cacheable` por clave | Caché de prompt | Cachea el **prefijo de la petición**, no la respuesta; no ahorra un peso de la salida |
| Invalidación explícita | Invalidación por cambio de byte | **Silenciosa**: no falla, solo vuelve a costar el precio completo |
| Métricas de latencia y error | Las mismas **más dólares y abstención** | El gasto es una métrica de producto, y la abstención es la alerta más temprana que hay |
| Log de la petición | Log con frontera | Aquí hay texto que **no se puede guardar**, y la mejora del sistema depende justo de ese texto |
| Presupuesto de infraestructura, mensual y fijo | Presupuesto por usuario y por día | Se agota, y hay que decidir qué pasa cuando se agota |
| *Feature flag* | Versión del prompt | Cambiar un prompt cambia el comportamiento sin cambiar una línea de código: se versiona o no se puede auditar |

> 📝 **Nota de ecosistema, y con fecha.** Los frameworks del sector se mueven rápido y por eso el
> curso los fija con su número: **LangChain 1.4.0** (con `langchain-anthropic` 1.7.2),
> **LlamaIndex 0.14.24**, **Pydantic AI 2.43.0**, **instructor 1.17.0** y **LiteLLM 1.100.1**,
> verificados contra PyPI el **13 de septiembre de 2026**. Dos observaciones que hay que hacer al
> mirar esa lista, y que valen más que la lista: LlamaIndex sigue en `0.x` después de años, lo cual
> dice algo sobre la estabilidad de su superficie; y Pydantic AI publicó su versión el día antes de
> escribirse esto, lo cual dice algo sobre el ritmo de cambio del que vas a depender. **Ninguno de
> los dos datos es una descalificación** — son dos entradas en la decisión de qué te toca mantener
> cuando tú no estés.

---

## 💻 5. Código mínimo con comentarios

El código vive en `src/ia08-produccion-y-el-veredicto/`.

### 5.1 La caché, colocada donde acierta

```python
# src/ia08-produccion-y-el-veredicto/caching.py
"""Colocación de la caché de prompt, y su verificación.

La colocación es media línea; lo que cuesta es no romperla. Por eso este archivo es
sobre todo `audit_prefix`: la función que encuentra al invalidador cuando la caché deja
de acertar y nadie sabe por qué.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from decimal import Decimal

import anthropic

from pricing import CATALOG, TOKENS_PER_UNIT

MODEL = "claude-opus-5"

# Multiplicadores de la caché. Escribir cuesta MÁS que una entrada normal y leer cuesta
# una fracción; con tráfico bajo y prefijos que expiran entre peticiones, la caché puede
# salir más cara. Se declaran como constantes porque son precio, y el precio se
# reverifica: ver la fecha de pricing.py.
CACHE_WRITE_MULTIPLIER = Decimal("1.25")
CACHE_READ_MULTIPLIER = Decimal("0.10")

# El contrato del sistema es LO ESTABLE y va delante. No lleva fecha, no lleva
# identificador de sesión y no lleva nada que cambie entre peticiones: todo eso viaja en
# el mensaje del usuario, detrás del punto de corte, donde ya no invalida nada.
STABLE_SYSTEM = """Contestas preguntas sobre coberturas de prepagadas para una red
odontológica, usando únicamente los fragmentos que te paso, y citando la frase exacta
que sostiene cada afirmación.
"""


@dataclass(frozen=True, slots=True)
class CacheStats:
    """Lo que la caché hizo de verdad, que no es lo que crees que hace."""

    created: int
    read: int
    uncached: int
    output: int

    @property
    def hit_ratio(self) -> float:
        total = self.created + self.read + self.uncached
        return self.read / total if total else 0.0

    def effective_cost(self, *, model: str = MODEL) -> Decimal:
        """Costo real de la petición, con los dos multiplicadores aplicados.

        Es la función que permite falsar la hipótesis de la sección 6: si `created` es
        alto y `read` se queda en cero porque el prefijo expira entre consultas, este
        número sale MAYOR que sin caché.
        """
        pricing = CATALOG[model]
        per_input = pricing.input_per_unit / TOKENS_PER_UNIT
        per_output = pricing.output_per_unit / TOKENS_PER_UNIT

        return (
            per_input * Decimal(self.created) * CACHE_WRITE_MULTIPLIER
            + per_input * Decimal(self.read) * CACHE_READ_MULTIPLIER
            + per_input * Decimal(self.uncached)
            + per_output * Decimal(self.output)
        )


def ask_with_cache(
    client: anthropic.Anthropic,
    question: str,
    context: str,
    *,
    on: date | None = None,
) -> tuple[str, CacheStats]:
    """Una petición con el prefijo estable cacheado.

    El orden de renderizado es `tools` → `system` → `messages`, así que el corte se pone
    al final de `system` y todo lo volátil —la fecha, la pregunta— va en el mensaje del
    usuario. Poner la fecha en el sistema es el error ① de la sección 4 y no da error:
    solo deja de cachear.
    """
    response = client.messages.create(
        model=MODEL,
        max_tokens=2048,
        system=[
            {
                "type": "text",
                "text": STABLE_SYSTEM + "\n\n" + context,
                # El punto de corte. Todo lo anterior se cachea; lo que viene después,
                # no. Hay un máximo de cuatro por petición, y con uno bien puesto suele
                # bastar: más puntos de corte no es más caché, es más superficie que
                # romper.
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[
            {
                "role": "user",
                # La fecha va AQUÍ, detrás del corte. Es el mismo dato que en la versión
                # ingenua estaba en el sistema, y la diferencia entre las dos es toda la
                # caché.
                "content": f"Fecha de referencia: {(on or date.today()).isoformat()}\n\n{question}",
            }
        ],
    )

    usage = response.usage
    stats = CacheStats(
        created=usage.cache_creation_input_tokens or 0,
        read=usage.cache_read_input_tokens or 0,
        uncached=usage.input_tokens,
        output=usage.output_tokens,
    )
    return "".join(b.text for b in response.content if b.type == "text"), stats
```

**Detalles con intención**

- **El punto de corte va al final del sistema y la fecha en el mensaje del usuario.** Es la línea
  entera de esta sección: el mismo dato, en dos sitios, y la diferencia entre cachear y no.
- **Un solo punto de corte.** Se permiten cuatro, y más puntos no es más caché: es más superficie
  que romper.
- **`effective_cost` aplica los dos multiplicadores**, y por eso puede devolver un número **mayor**
  que la versión sin caché. Una función de costo que solo sabe restar no puede falsar la hipótesis
  de la sección 6.
- **`src/` trae además `ask_without_cache` y `ask_with_broken_cache`** —la fecha delante del
  corte—, que son las filas 1 y 3 de la medición. La tercera está escrita para ser medida, no para
  ser descrita.

### 5.2 El auditor del prefijo: la función que encuentra al culpable

```python
# src/ia08-produccion-y-el-veredicto/audit_prefix.py
"""Encuentra el primer byte en que dos peticiones dejan de ser iguales.

Cuando `cache_read_input_tokens` sale cero en peticiones que deberían compartir prefijo,
la pregunta es *dónde* se rompió, y leerlo a ojo sobre veinte mil caracteres de contexto
no funciona. Función pura: se prueba sin red, sin modelo y sin gastar un peso.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True, slots=True)
class Divergence:
    """Dónde y cómo se rompió el prefijo compartido."""

    position: int | None
    before: str
    after: str
    # True cuando uno de los dos prefijos es prefijo del otro. Es el caso BENIGNO —el
    # más corto se cachea entero— y confundirlo con una divergencia manda a alguien a
    # buscar un bug que no existe.
    truncation: bool = False

    @property
    def identical(self) -> bool:
        return self.position is None

    def explain(self) -> str:
        if self.identical:
            return "Los dos prefijos son idénticos: la caché debería acertar."
        if self.truncation:
            return (
                f"Un prefijo es continuación del otro; se separan en el carácter "
                f"{self.position}. El más corto sí se cachea entero: esto no rompe la "
                f"caché, solo la limita."
            )
        return (
            f"Los prefijos divergen en el carácter {self.position}.\n"
            f"  petición A: …{self.before}\n"
            f"  petición B: …{self.after}\n"
            "Todo lo que venga después de ese punto no se cachea."
        )


def render_prefix(request: dict[str, Any]) -> str:
    """Reconstruye el prefijo en el ORDEN EN QUE LO RENDERIZA LA API: tools → system.

    Reconstruirlo en otro orden da una respuesta que se ve razonable y señala al
    culpable equivocado. El orden es parte del contrato y hay que respetarlo aquí.
    """
    parts: list[str] = []

    for tool in request.get("tools", []):
        # `sort_keys=True` en el volcado del auditor, no en el de la petición: aquí se
        # normaliza para comparar. Si la petición REAL no ordena sus claves, eso es
        # justamente lo que este auditor tiene que detectar, y por eso se compara el
        # texto renderizado por la petición y no el diccionario.
        parts.append(json.dumps(tool, ensure_ascii=False))

    system = request.get("system", "")
    if isinstance(system, str):
        parts.append(system)
    else:
        parts.extend(block.get("text", "") for block in system)

    return "\n".join(parts)


def first_divergence(a: dict[str, Any], b: dict[str, Any], *, window: int = 40) -> Divergence:
    """Compara los prefijos de dos peticiones y devuelve dónde se separan."""
    left, right = render_prefix(a), render_prefix(b)

    limit = min(len(left), len(right))
    for position in range(limit):
        if left[position] != right[position]:
            return Divergence(
                position=position,
                before=left[max(0, position - window // 2) : position + window],
                after=right[max(0, position - window // 2) : position + window],
            )

    if len(left) != len(right):
        # Uno es prefijo del otro: el más corto SÍ se cachea entero, y eso importa.
        # Es el caso benigno y hay que distinguirlo del divergente.
        return Divergence(
            position=limit,
            before=left[limit : limit + window],
            after=right[limit : limit + window],
            truncation=True,
        )

    return Divergence(position=None, before="", after="")
```

**Detalles con intención**

- **`render_prefix` respeta el orden `tools` → `system`.** Auditar en otro orden produce un
  culpable equivocado con toda la confianza del mundo.
- **El caso "uno es prefijo del otro" se distingue del divergente.** Es benigno —el más corto
  cachea entero— y confundirlo con una divergencia manda a alguien a buscar un bug que no existe.
- **La función es pura y devuelve un objeto que sabe explicarse.** El `explain()` es para pegar en
  un incidente, no para leerlo en un depurador.

### 5.3 El presupuesto que corta

```python
# src/ia08-produccion-y-el-veredicto/budget.py
"""Presupuesto por usuario y por día. En Decimal, y corta de verdad.

Un servicio que puede gastar sin techo es un incidente con fecha. La pregunta que este
archivo obliga a contestar no es cuánto se gasta: es **qué pasa cuando se acaba**, y esa
respuesta es de producto.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal


class BudgetExceeded(RuntimeError):
    """Se agotó el presupuesto. Quien llama decide qué hacer, y tiene que decidirlo."""


@dataclass(slots=True)
class DailyBudget:
    """Gasto acumulado por clave y por día.

    La clave es el paciente en Recepción asistida y la sede en NormaRAG: son los dos
    ejes por los que el gasto se dispara de verdad —un paciente ansioso a las once de la
    noche, una sede que descubre la herramienta y la usa cien veces—.
    """

    limit_per_key: Decimal
    limit_total: Decimal
    day: date
    spent: dict[str, Decimal] = field(default_factory=dict)

    def total(self) -> Decimal:
        return sum(self.spent.values(), start=Decimal(0))

    def check(self, key: str, estimated: Decimal) -> None:
        """Comprueba ANTES de gastar. Es la única comprobación que previene el gasto.

        Comprobar después informa; comprobar antes protege. Se hace con la estimación
        del peor caso de `ia01` —`max_tokens` completo—, que es pesimista a propósito:
        un presupuesto que se pasa porque la estimación era optimista no es un
        presupuesto.
        """
        current = self.spent.get(key, Decimal(0))

        if current + estimated > self.limit_per_key:
            raise BudgetExceeded(
                f"{key} lleva ${current} hoy y esta petición costaría hasta ${estimated}; "
                f"el tope por clave es ${self.limit_per_key}."
            )
        if self.total() + estimated > self.limit_total:
            raise BudgetExceeded(
                f"El gasto del día va en ${self.total()} y el tope es ${self.limit_total}."
            )

    def record(self, key: str, actual: Decimal) -> None:
        """Registra lo que costó de verdad, que es menos que la estimación."""
        self.spent[key] = self.spent.get(key, Decimal(0)) + actual

    def report(self) -> str:
        top = sorted(self.spent.items(), key=lambda item: item[1], reverse=True)[:3]
        lines = [f"{self.day.isoformat()}: ${self.total():.4f} en {len(self.spent)} claves"]
        lines.extend(f"  {key}: ${amount:.4f}" for key, amount in top)
        return "\n".join(lines)
```

**Detalles con intención**

- **`check` va antes y `record` después.** Comprobar después informa; comprobar antes protege, y se
  comprueba con la estimación del **peor caso** de `ia01`, que es pesimista a propósito.
- **Dos topes, y hacen falta los dos.** El de clave atrapa al paciente ansioso de las once de la
  noche; el global atrapa el día en que se dispara todo a la vez. Cortarle a uno no puede dejar sin
  servicio a los otros nueve, y hay una prueba que lo fija.
- **`Decimal`, y aquí el número es concreto:** diez mil peticiones de tres milésimas suman
  `30.000` en `Decimal` y `30.000000000001023` en `float`. El criterio 2 del miniproyecto pide
  cuadrar con la factura del proveedor dentro del 5%; la deriva no muerde ahí, pero un número que
  no cuadra exactamente es un número que alguien va a tener que explicar.

> 💸 **Deuda técnica intencional, y es la última del track.** `DailyBudget` vive en memoria, así
> que **no sobrevive a un reinicio ni se comparte entre procesos**. Lo correcto es Postgres o
> Valkey, con la fila por clave y día y un `UPDATE … RETURNING` que sea atómico. **Se paga en el
> miniproyecto de esta sección**, criterio 3, y no antes por una razón pedagógica: la versión en
> memoria deja ver la aritmética y las dos comprobaciones sin el ruido de la persistencia. En
> producción, dos procesos con esta clase tienen dos presupuestos.

**El patrón a memorizar**

> Lo que no se mide en dólares se descubre en la factura. Y **la caché no se declara, se
> verifica**: `cache_read_input_tokens` en cada respuesta, y una alerta cuando cae a cero.

**Prueba de fuego**

```bash
uv run python -c "
from caching import ask_with_cache
from llm import build_client
c = build_client(); ctx = open('corpus/00-seguros-andina-plan-básico-2025.txt').read() * 8
for i in range(3):
    _, s = ask_with_cache(c, '¿cubre el 992102?', ctx)
    print(f'{i}: creados={s.created} leídos={s.read} sin cachear={s.uncached} acierto={s.hit_ratio:.0%}')
"
```

Lo que tiene que salir: la primera petición con `creados` alto y `leídos` en cero, y las dos
siguientes al revés. **La mentira que te va a contar la salida si miras el lugar equivocado:** si
el contexto es corto, las tres van a salir con todo en `sin cachear` y cero en las otras dos
columnas — y eso **no es un bug**, es el mínimo de tokens para que un prefijo se cachee. Si
concluyes que "la caché no funciona" sin mirar el tamaño del prefijo, vas a pasar una tarde
moviendo `cache_control` de sitio.

---

## 📏 6. Medición

Esta sección produce **dos** mediciones, y es la única del track que lo hace, porque cierra dos
cosas distintas: la operación y el veredicto.

### 6.1 La caché sobre el tráfico de un día

**Hipótesis.** Con el tráfico real de NormaRAG —del orden de quince consultas diarias, repartidas
a lo largo del día— **la caché de prompt no ahorra nada y puede costar más**, porque el prefijo
expira entre consultas y se paga la escritura sin llegar a amortizarla. En Recepción asistida, con
900 mensajes diarios concentrados en horario de sede, sí ahorra.

**Condiciones.** Python 3.14.7; `anthropic` 1.5.0; `claude-opus-5`. El tráfico de un día
reconstruido a partir del dominio: quince consultas de NormaRAG repartidas en ocho horas, y 900
mensajes de WhatsApp con su distribución horaria real —pico a media mañana y a las seis de la
tarde—. Tres corridas. Se miden tokens creados en caché, leídos de caché, sin cachear, y el costo
efectivo con sus multiplicadores (1.25× la escritura, ~0.1× la lectura).

**Competidores.** Tres colocaciones, todas defendibles, y una de ellas es el error de la sección 4
medido en vez de descrito:

1. **Sin caché.** La línea base.
2. **Caché bien puesta**: corte al final del sistema, lo volátil en el mensaje del usuario.
3. **Caché con la fecha en el sistema.** El error ①. No falla, no avisa, y el objetivo de medirlo
   es poder decir cuánto cuesta exactamente.

**Resultado.**

| Colocación | Tokens leídos de caché | Costo · NormaRAG (15/día) | Costo · Recepción (900/día) |
|---|---|---|---|
| Sin caché | 0 | ⏳ | ⏳ |
| Caché bien puesta | ⏳ | ⏳ | ⏳ |
| Caché con la fecha en el sistema | ⏳ | ⏳ | ⏳ |

```bash
uv run python bench_caching.py --trafico trafico_un_dia.jsonl --runs 3
```

> ⚖️ **Veredicto — pendiente de correr, con la expectativa declarada.** Esperamos que la fila 3 dé
> **exactamente lo mismo que la 1**, que es la demostración de que un invalidador silencioso
> convierte tu optimización en nada; y que la fila 2 gane en Recepción asistida y **pierda o empate
> en NormaRAG**. Si empata en NormaRAG, la recomendación es no ponerla ahí: una optimización que no
> ahorra es código que alguien tiene que mantener. **El umbral por determinar** es a partir de
> cuántas consultas por hora la caché empieza a pagar su escritura, y ese número es transferible a
> cualquier otro proyecto del lector.

### 6.2 El framework contra el bucle propio

**Hipótesis.** Para los dos proyectos de Áurea, un framework de agentes **no mejora la calidad y
sí añade superficie que mantener**: mismo resultado en el conjunto de evaluación de `ia06`, menos
líneas escritas por ti, y más dependencias que actualizar cuando no estés.

**Condiciones.** La **misma tarea** —las preguntas de `ia06`, partición de retención— y el **mismo
conjunto de evaluación**, que es la condición sin la cual esta comparación no probaría nada.
Versiones fijadas y verificadas el 13/09/2026: **LangChain 1.4.0** con `langchain-anthropic`
1.7.2, **LlamaIndex 0.14.24**, **Pydantic AI 2.43.0**. Se mide: tasa de correctas con su intervalo,
líneas de código propio, número de dependencias transitivas, tokens por respuesta y tiempo de
arranque del proceso.

**Resultado.**

| Implementación | Correctas (IC 95%) | Líneas propias | Dependencias | Tokens/resp. | Arranque |
|---|---|---|---|---|---|
| Bucle propio (`ia03` + `ia05`) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| LangChain 1.4.0 | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| LlamaIndex 0.14.24 | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Pydantic AI 2.43.0 | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |

> ⚖️ **Veredicto — pendiente de correr, y con la expectativa escrita de antemano para que se pueda
> desmentir.** La propuesta del curso dice que el resultado más probable es *"para esto no
> necesitabas framework"*, y esa frase está escrita desde antes de medir precisamente para que la
> medición pueda contradecirla. **Si un framework gana en la columna de correctas, gana y se
> escribe.** Lo que la tabla no va a poder decidir sola es la columna que más pesa en Áurea —qué le
> toca mantener a quien te reemplace—, y ahí la comparación honesta no es "menos líneas": es
> **menos líneas propias contra más superficie ajena**, y las dos se pagan.

> 📝 **Y la deuda 💸 de `ia06` se paga aquí:** esta es la primera vez del track que hay **dos
> versiones del mismo sistema** que comparar, así que el juez de `ia06` se usa en modo **comparación
> por pares** —las dos respuestas a la vez, y cuál es mejor— en lugar de calificar cada una por
> separado. Su acuerdo con el humano debería ser mayor; si no lo es, se reporta igual.

---

## ⚖️ 6.3 El veredicto del track: cuándo NO usar un LLM

Esta subsección es el contenido de la sección, no su cierre amable. Áurea construyó dos cosas con
modelos de lenguaje, y las dos tienen que pasar por el mismo examen que el camino base le hace a
sus cuatro proyectos.

**Los tres casos que el track descartó y que aparecen todo el tiempo.** Los tres tienen la misma
forma: alguien propone un LLM para un problema que ya tenía solución.

- **La pregunta que contesta un `SELECT`.** *"¿Cuántas citas tiene Suba el jueves?"* no es una
  pregunta para un modelo. La medición de `ia03` tiene una fila entera dedicada a esto —formulario
  más SQL— y existe porque para una parte de las solicitudes gana sin discusión.
- **La extracción sobre un formato fijo.** El anexo tarifario tiene una estructura regular; el
  XML de la DIAN, más. Para eso hay un parser, es determinista, cuesta cero y no hay que evaluarlo
  con kappa. El LLM entra donde la estructura **no** es fija, que es la circular en prosa de
  `ia02`.
- **La clasificación de cien casos al mes.** Con ese volumen, una regla escrita y una persona
  revisando salen más baratas que un modelo con su evaluación, su presupuesto y su mantenimiento.
  El umbral está en el volumen, no en la dificultad.

**NormaRAG: probablemente se queda, con la mitad recortada.** El proyecto tiene un encargo real
—una hora diaria de Patricia y las auxiliares— y un requisito que lo hace defendible. Pero dos de
sus mediciones pueden recortarlo a la mitad y hay que decirlo antes de correrlas: si la búsqueda
híbrida de `ia04` no le saca ventaja clara a la léxica, la mitad vectorial es un modelo que
mantener por tres puntos de recall; y si la fila 3 de `ia05` —devolver la cláusula sin generar—
le sirve a Patricia en la mitad de los casos, la generación debería enrutarse y no aplicarse
siempre. **Un NormaRAG que es un buen buscador con citas y que genera solo cuando hace falta es un
mejor proyecto que el que construimos**, y es más barato de sostener.

**Recepción asistida: el veredicto no lo firma un ingeniero.** Aquí el número está medido y es
incómodo: el guardrail léxico deja pasar **veinte de cuarenta** mensajes con síntoma. La decisión
de desplegar depende de un umbral de falsos negativos aceptables que **no le corresponde fijar a
quien escribió el sistema**: le corresponde a Marcela y a Julián, que tienen el registro
profesional. El trabajo de este track es ponerles el número delante y la alternativa al lado — la
fila 4 de `ia07`, escalarlo todo y usar el modelo solo para redactar borradores, que es mucho más
barata de sostener y probablemente ahorra casi el mismo tiempo.

**Y la conclusión que el escenario de Áurea permite y uno corporativo no.** El curso completo lo
dice y este track lo confirma: **cuando eres uno solo, la decisión correcta muy a menudo es no
construir**. Lo difícil de estos dos proyectos no fue técnico. Lo difícil es que los dos son
demostrables, los dos impresionan en un asado, y los dos tienen una alternativa aburrida que
resuelve el 70% del problema por el 5% del esfuerzo de mantenimiento.

> 🧭 **La pregunta que hay que hacerse antes de empezar cualquiera de estos, y que este track
> existe para poder contestar:** ¿qué parte de esto sigue funcionando el año que viene si nadie lo
> toca? Un `SELECT` y un parser, sí. Un prompt afinado contra un modelo que cambia, no
> necesariamente.

---

## 🧱 7. Miniproyecto — El informe que Julián lee en el asado

**El encargo.** Julián va a preguntar, otra vez y en un asado, cuánto cuesta esto y si vale la
pena. Construye `aur-ia-informe`: la herramienta que produce el estado de los dos proyectos de IA
—gasto, salud, calidad y riesgo— en una página que él pueda leer sin ser ingeniero, y que tú
puedas defender línea por línea.

**Por qué duele.** Porque la honestidad tiene consecuencias. El informe tiene que poder decir *"este
mes NormaRAG costó tanto y se abstuvo el 31% de las veces"*, y esa frase abre una conversación
sobre si el proyecto sirve. Un informe que solo muestra lo que va bien no se usa para decidir, se
usa para tranquilizar, y eso es exactamente lo que el curso viene enseñando a no hacer.

**Datos de entrada.** El registro de producción de los dos proyectos —que tienes que haber
instrumentado— y los conjuntos de evaluación de `ia06` y `ia07`.

**Criterios de aceptación.**

1. `aur-ia-informe mensual` produce una página con: gasto por proyecto y por sede, tasa de
   abstención de NormaRAG, tasa de escalamiento de Recepción asistida, la última calidad medida con
   su intervalo, y la fecha de esa medición. **Si la calidad tiene más de treinta días, el informe
   lo dice en la primera línea.**
2. El gasto reportado cuadra con la factura del proveedor dentro del 5%. Cuando no cuadre, el
   informe dice en qué se fue la diferencia y no la esconde.
3. El presupuesto **persiste y es atómico**: dos procesos no pueden pasarse del tope. Es la deuda
   💸 de la sección 5.3 y se paga aquí, con `UPDATE … RETURNING` o equivalente.
4. `--alertas` lista lo que se degradó respecto del mes anterior, con su umbral escrito. La
   abstención y el escalamiento tienen que estar entre las alertas.
5. La retención se aplica: los registros con más de la ventana definida se borran, hay una prueba
   que lo demuestra, y la ventana está escrita en un solo sitio.
6. `aur-ia-informe muestra --revision` selecciona una muestra de conversaciones para revisión
   humana **sin exponer el texto del paciente en el informe**: devuelve identificadores para que
   alguien con acceso legítimo los abra en el canal original. Es la frontera de la sección 4,
   implementada.
7. Una sección final, escrita a mano y no generada, con **la recomendación de qué hacer con cada
   proyecto** y qué tendría que pasar para cambiar de opinión.

**Restricciones de registro.** Herramienta, no aplicación: Julián la corre o la recibe por correo,
no entra a un panel. Reusa `pricing.py` de `ia01` sin modificarlo. **El informe no lo redacta un
modelo**: es la última página del track y está hecha de números que tú puedes defender, no de
prosa generada. Si no puedes explicar una cifra, no va.

**La trampa.** El criterio 7. Después de ocho secciones construyendo esto, escribir *"recomiendo
recortar la mitad vectorial de NormaRAG"* cuesta. Y es exactamente el ejercicio del curso: alguien
que sale de aquí sabiendo construir un RAG pero incapaz de recomendar no construirlo no aprendió a
decidir, aprendió a preferir.

**Cómo se entrega.** `git tag -a ia-mini-08`, y **en el mensaje del tag va el costo mensual de los
dos proyectos y tu recomendación en cinco palabras**. Las cinco palabras son el entregable.

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre la misma petición tres veces con caché y mira `cache_read_input_tokens`. Después mete un
   `datetime.now()` en el sistema y repite. La diferencia es la sección 4 en dos comandos.
2. Reduce el contexto hasta que la caché deje de acertar y encuentra el tamaño mínimo en tu
   modelo. Anótalo: te va a ahorrar una tarde algún día.
3. Usa `first_divergence` sobre dos peticiones que difieren solo en el orden de las herramientas y
   lee el `explain()`. ¿Te habría servido en un incidente?
4. Haz que el presupuesto registre también el costo del juez de `ia06`. La evaluación gasta, y no
   aparece en ningún presupuesto todavía.
5. Calcula qué fracción del costo de una respuesta de NormaRAG es entrada y qué fracción salida.
   Decide si la caché puede ayudar con lo que más pesa.
6. Añade la tasa de abstención al registro estructurado de la Fase 16 como un campo, y comprueba
   que se puede consultar por día.

**🟡 Intermedio (7–14)**

7. Implementa la alerta de abstención: si sube más de tres puntos en siete días, avisa. Decide el
   umbral con los datos que tengas y justifícalo.
8. Mide el efecto de la caché sobre el bucle de `ia03`: la lista de herramientas y el sistema son
   idénticos en cada turno y deberían acertar. **Es el ejercicio 25 de `ia03`**, y aquí tienes con
   qué hacerlo bien.
9. Implementa el presupuesto persistente del criterio 3 y demuestra con dos procesos concurrentes
   que no se pasan del tope.
10. Añade el `ttl` de una hora al punto de corte y mide si cambia algo en el tráfico de NormaRAG.
    Es la diferencia entre amortizar y no amortizar.
11. Instrumenta la versión del prompt como un campo del registro, y demuestra que puedes atribuir
    una caída de calidad a un cambio de prompt concreto.
12. Implementa la política de retención del criterio 5 y escribe el guion que la ejecuta. Después
    córrelo sobre datos de prueba y comprueba que borra lo que debe.
13. Compara el costo mensual de los dos proyectos contra el sueldo por hora de Patricia y el de
    Yuli. Los dos números en la misma tabla es lo que hace la conversación con Julián posible.
14. Implementa la comparación por pares del juez —la deuda 💸 de `ia06`— y mide su acuerdo con el
    humano frente al juicio individual.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** La factura subió un 60% sin que subiera el tráfico y `cache_read_input_tokens`
    sigue igual. Con la instrumentación de esta sección, localiza la causa. Hay cuatro candidatas y
    una no tiene nada que ver con la caché.
16. **Medición.** Implementa la fila 3 de la medición 6.1 —la fecha en el sistema— y cuantifica
    exactamente cuánto cuesta ese error al mes en Recepción asistida. Es el número que hace que
    alguien lo recuerde.
17. Implementa una de las tres alternativas de la medición 6.2 y llévala hasta poder correr el
    conjunto de evaluación. Reporta qué te costó, incluido lo que no esperabas.
18. **Diagnóstico.** La calidad de NormaRAG cayó y no cambiaste nada. Con los campos del registro,
    enumera las cuatro causas posibles y di cómo distinguirlas. Una de ellas es que cambió el
    modelo bajo tus pies.
19. **De registro.** El informe mensual de los dos proyectos: decide si es script, herramienta o
    aplicación, y **cuantifica el costo de las otras dos**. Después contesta: ¿qué pasa con este
    informe el día que tú no estés?
20. **De registro.** Llega una propuesta de "meterle IA" a la conciliación de glosas de Cartera.
    Escribe la respuesta de media página usando los tres casos descartados de la §6.3, y di qué
    parte sí y qué parte no.
21. Diseña el procedimiento de revisión humana del criterio 6: qué muestra, cada cuánto, quién, y
    qué se hace con lo que se encuentra. **Córrelo tú sobre una muestra real de tus propios datos
    generados** y reporta cuánto tardaste: un procedimiento que no has ejecutado ni una vez es una
    página de intenciones.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye el caso en que la caché de prompt **sale más cara** que no usarla, y
    mídelo. Después escribe la regla general de cuándo ponerla, en dos frases.
23. Calcula el costo total de propiedad a tres años de los dos proyectos: API, infraestructura,
    evaluación, y **las horas tuyas y de quien te reemplace**. Ponlo al lado de lo que cuesta el
    problema hoy —una hora diaria de Patricia, el 19% de inasistencia— y saca la conclusión.
24. **Adversarial.** Escribe la mejor defensa posible de la posición contraria a tu veredicto: si
    recomendaste recortar, defiende construir; si recomendaste construir, defiende no hacerlo. Si
    la defensa contraria te convence, tu veredicto era una preferencia.
25. Escribe el documento de una página que Áurea firma para operar estos dos sistemas: qué se mide,
    qué se guarda y por cuánto tiempo, quién revisa, qué bloquea un despliegue y qué pasa cuando
    algo sale mal. Es el entregable que sobrevive a que tú te vayas.

**🔥 Opcionales**

- Mide el arranque en frío de un proceso con LangChain contra el tuyo. En un proceso que un `cron`
  invoca, esa diferencia es dinero.
- Implementa la caché con dos puntos de corte —sistema y corpus— y mide si el segundo aporta algo.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://docs.claude.com/en/docs/build-with-claude/prompt-caching` — colocación, orden de
  renderizado, mínimos de tokens, TTL y multiplicadores de precio. **Es la página que hay que leer
  entera antes de tocar `cache_control`**, y la que explica por qué "lo puse y no ahorró nada".
- `https://docs.claude.com/en/api/rate-limits` — límites por organización, cabeceras y qué hacer
  con un 429 que persiste.
- `https://docs.claude.com/en/docs/about-claude/pricing` — reverifícalo antes de cualquier número
  de esta sección. Es el dato que más rápido envejece del curso.
- `https://docs.python.org/3.14/library/decimal.html` — el presupuesto es dinero.

**Los frameworks, con su versión y su fecha**

- `https://github.com/langchain-ai/langchain` — **1.4.0** (13/09/2026), con
  `langchain-anthropic` **1.7.2**.
- `https://github.com/run-llama/llama_index` — **0.14.24**. Sigue en `0.x`, y eso es un dato.
- `https://github.com/pydantic/pydantic-ai` — **2.43.0**, publicada el día antes de escribirse
  esto. También es un dato.

**Orden de lectura sugerido:** la página de caché **entera y antes de escribir nada** —es corta y
contesta el 90% de las dudas de esta sección— → la de límites de tasa cuando montes el presupuesto
→ los repositorios de los frameworks solo cuando vayas a implementar la medición 6.2, y mirando
primero la fecha de su última publicación.

> ⚠️ URLs, títulos, versiones y precios pueden haber cambiado desde la fecha de verificación; el
> lector debe comprobarlos. Aquí no se inventan páginas, ISBN ni identificadores de video.

---

## 🚀 10. Cierre del track

El track termina donde el curso entero: **con un veredicto que puede ir en contra de lo que
acabas de construir**. Ocho secciones para llegar a poder decir, con números propios, que la mitad
vectorial de NormaRAG quizá no se justifica y que Recepción asistida no la despliega un ingeniero.

Lo que te llevas no es un RAG y un agente. Son seis reglas que se transfieren a cualquier cosa que
construyas con un modelo, y que conviene poder recitar:

1. **Un reintento es una compra.** En un servicio con tarifa por token, el reflejo de reintentar
   cuesta dinero que no aparece en ninguna métrica.
2. **Cada campo obligatorio es una invitación a inventar.** Lo obligatorio se reserva para lo que
   la fuente garantiza; *"no dice"* es un valor de primera clase.
3. **La descripción de la herramienta es prompt**, y lo que muta estado necesita clave de
   idempotencia derivada y una persona en el medio.
4. **Una búsqueda por similitud nunca devuelve vacío.** Sin umbral, el sistema no puede decir "no
   sé", y un sistema que no puede decir "no sé" inventa todos los días.
5. **El prompt orienta, el código garantiza.** Si una obligación legal depende de que el modelo
   obedezca, no está garantizada.
6. **Un número de calidad sin su tamaño de muestra no es un número**, y un juez sin medir contra
   un humano no es una métrica.

Y una séptima que es de este curso y no del ecosistema: **cuando eres uno solo, la decisión
correcta muy a menudo es no construir.**

Lo que sigue es el track `ds`, que ataca el otro lado del mismo problema. Ahí el reflejo no es
tratar al modelo como una función: es escribir el bucle correcto y legible que en Java era lo
adecuado, y descubrir el tamaño exacto a partir del cual deja de serlo. Y trae la misma clase de
veredicto incómodo, anunciado desde la historia de Áurea: **la regresión logística de cinco
variables probablemente le gana a la red neuronal**, y hay que aceptarlo con la medición delante.

> **La señal de que quedó bien:** cuando puedas presentarle a Julián el costo mensual de lo que
> construiste **y** la alternativa que no lo necesitaba, en la misma página y sin que te tiemble la
> mano.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ia-fase-08 -m "ia08 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Y con esta queda cerrado el track: `git tag -l 'ia-*'` tiene que devolver dieciséis tags, ocho de
> sección y ocho de miniproyecto. Los commits llevan su prefijo (`ia 08: …`), los de ejercicio su
> número (`ia 08 ej12: …`) y el miniproyecto el suyo (`ia 08 mini: …`), con **el costo mensual y tu
> recomendación en cinco palabras** en el mensaje del tag `ia-mini-08`. La convención completa está
> en [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
