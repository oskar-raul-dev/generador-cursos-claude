# ⚖️ ia06 — Evaluación, regresiones y el juez que también se equivoca

> Python para desarrolladores Java senior · Track `ia` · sección 6 de 8
> Depende de: `ia01`, `ia02`, `ia04`, `ia05` · Habilita: `ia07`, `ia08`
> Registro de esta sección: aplicación
> Proyecto que avanza: NormaRAG gana su arnés de calidad; se pagan dos deudas 💸 del track

---

## 🎯 1. Propósito

NormaRAG funciona. Verifica sus citas, se abstiene cuando no encuentra y publica la cobertura de
su corpus. Y aun así, hoy, si cambias el troceado o subes el número de fragmentos recuperados, la
única forma que tienes de saber si mejoró es **abrir cinco respuestas y leerlas**. Eso no es una
metodología: es una corazonada con pasos intermedios.

Esta sección convierte *"se ve mejor"* en un número que se puede comparar entre versiones, defender
ante Julián y colgar de un proceso automático. Y trae la parte que casi nadie hace: **medir al
juez**. Si vas a dejar que un modelo califique a otro modelo, tienes que saber cuánto se parece ese
juez a una persona, porque si no estás construyendo tu métrica sobre otra cosa que tampoco
mediste.

> 🧭 **La regla que ordena la sección: una métrica que no se ha comparado contra un juicio humano
> no es una métrica, es una opinión automatizada.** Da lo mismo que salga un número con tres
> decimales.

---

## ✅ 2. Qué queda listo al terminar

- [ ] El conjunto de evaluación existe como **activo versionado**: archivo en el repositorio, con
      su huella, partido en desarrollo y retención, y con las respuestas de referencia escritas por
      una persona.
- [ ] `run_eval.py` corre el conjunto completo contra NormaRAG y produce un informe reproducible
      con su fecha, su huella del conjunto y su costo.
- [ ] El juez automático califica con una rúbrica escrita, y **su acuerdo contra treinta juicios
      humanos está medido** con acuerdo bruto y kappa.
- [ ] Las pruebas de calidad corren en CI **sin volverse intermitentes**: umbral, número de
      corridas e intervalo de confianza, no reintentos hasta que pase.
- [ ] La deuda 💸 de `ia04` está pagada: el umbral de distancia sale de los datos, no de la
      intuición.
- [ ] La deuda 💸 de `ia01` está pagada: hay un `Protocol` de proveedor y el mismo conjunto corre
      contra la API y contra el modelo local.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Evaluar el agente de WhatsApp** → `ia07`. Evaluar una conversación de varios turnos es un
  problema distinto —¿qué es una respuesta correcta cuando hay cuatro?— y aquí se monta el aparato
  para respuestas de un solo turno.
- **Observabilidad en producción** → `ia08`. Evaluación es antes de desplegar; observabilidad es
  después, y confundirlas produce sistemas que miden lo que ya no se puede cambiar.
- **Optimización automática de prompts** → fuera del curso. Con el conjunto de evaluación bien
  hecho se puede hacer, y la primera versión es un bucle de prueba y error a mano, que es lo que
  esta sección habilita.
- **Métricas de recuperación** → ya están en `ia04` y se reusan; no se redefinen aquí.

---

## 🧠 4. Concepto mínimo

### Qué queda por medir, después de todo lo anterior

Vale la pena ordenarlo, porque el track ya mide bastante y lo que falta es preciso:

| Ya medido | Dónde | Cómo |
|---|---|---|
| ¿Llegó el fragmento correcto? | `ia04` | recall@5, MRR. Mecánico, contra anotación |
| ¿La cita existe y corresponde? | `ia05` | Verificación literal. Mecánico, sin juicio |
| ¿El sistema se abstiene cuando debe? | `ia05` | Tasa de abstención por causa |
| **¿La respuesta es correcta?** | **aquí** | **Juicio: humano, o juez medido contra humano** |
| **¿Sirve para lo que Patricia necesita?** | **aquí** | **Juicio, con rúbrica escrita** |

Las dos últimas no tienen atajo mecánico, y toda la sección va de convertirlas en algo comparable
entre versiones sin fingir objetividad que no hay.

### El conjunto de evaluación es un activo, no un archivo de pruebas

Y esto tiene tres consecuencias prácticas que se suelen descubrir tarde.

**Se versiona y se le calcula la huella.** Si el conjunto cambia, los números de antes y de después
no son comparables, y un informe que no diga contra qué versión del conjunto corrió es un informe
que no se puede citar en una discusión.

**Se parte en dos.** El conjunto de **desarrollo** es contra el que iteras: cambias el prompt,
mides, repites. El de **retención** se toca lo mínimo posible. La razón es la misma de siempre y en
este contexto muerde más rápido de lo que crees: después de veinte iteraciones contra el mismo
conjunto, tu sistema está ajustado a esas cincuenta preguntas y no a las de Patricia.

**Lo escribe una persona, y esa persona sabe del dominio.** Una respuesta de referencia generada
por otro modelo es un espejo: mide si tu sistema se parece a ese otro modelo, que es una pregunta
que a nadie le interesa.

### Tu instinto de Java dice… y esta vez se equivoca

Este es el reflejo más fuerte de todo el track, porque es una virtud profesional bien ganada:
**una prueba que falla una de cada veinte veces es una prueba rota.** Has pasado años cazando
pruebas intermitentes, y con razón: la intermitencia destruye la confianza en la suite entera.

```python
# ❌ El reflejo, en sus dos formas, y las dos son trampas.
def test_normarag_contesta_bien():
    answer = answer_question(client, connection, "¿Andina cubre el retiro de brackets?")
    assert "no está cubierto" in answer.text          # ① igualdad disfrazada

@retry(times=5)                                        # ② el reintento que esconde el problema
def test_normarag_contesta_bien_2():
    ...
```

La primera compara contra una redacción concreta, así que va a fallar el día que el modelo diga
*"no tiene cobertura"*, que significa lo mismo. La vas a ajustar, va a fallar otra vez, y en tres
semanas la vas a marcar como omitida. La segunda es peor: **el reintento convierte una prueba
probabilística en una que casi siempre pasa**, y lo que estás midiendo pasa a ser *"el sistema
acierta al menos una vez de cada cinco"*, que no es una garantía que quieras.

Lo que se escribe en su lugar acepta la naturaleza del sistema en vez de pelearse con ella:

```python
# ✅ La intermitencia es la propiedad. Se mide, se acota, y se falla con información.
def test_calidad_no_baja_del_umbral(evalset, system):
    """Corre el conjunto de retención n veces y compara el intervalo, no el punto."""
    scores = [run_evalset(evalset, system) for _ in range(RUNS)]
    rate = sum(scores) / (len(scores) * len(evalset))
    low, high = wilson_interval(successes=round(rate * len(scores) * len(evalset)),
                                trials=len(scores) * len(evalset))

    assert low >= QUALITY_FLOOR, (
        f"Calidad {rate:.2f} (IC 95%: {low:.2f}–{high:.2f}) por debajo del piso "
        f"{QUALITY_FLOOR:.2f} sobre {len(evalset)} casos × {RUNS} corridas."
    )
```

Tres diferencias, y las tres importan. **Se compara el límite inferior del intervalo**, no el
promedio: con veinte casos, un 80% es en realidad "entre 58% y 92%", y celebrar ese 80% es
engañarse con tres decimales. **El mensaje de fallo trae el número, el intervalo y el tamaño de la
muestra**, que es lo único que permite decidir si el fallo es real o es ruido. Y **el umbral es un
piso que no puede bajar**, no un objetivo que hay que alcanzar: la prueba protege contra la
regresión, que es lo que CI puede hacer.

> 🧭 **La regla:** no se reintenta hasta que pase. Se corre `n` veces, se reporta el intervalo, y
> se falla cuando el **límite inferior** cruza el piso. Un fallo así es información; un reintento
> es una alfombra.

### El segundo reflejo: el juez como oráculo

La solución obvia al problema de "esto no se puede medir automáticamente" es pedirle a un modelo
que califique. Funciona sorprendentemente bien y tiene una trampa de la que casi nadie sale: **el
juez es un modelo, y los modelos se equivocan**. Si tu métrica de calidad es un juez sin medir,
has cambiado un problema que no sabías medir por otro que tampoco mediste, con la diferencia de
que ahora sale un número y el número da confianza.

Medir al juez no es difícil, es aburrido: se toman treinta respuestas, las califica una persona
—tú, con la rúbrica delante—, las califica el juez, y se comparan. Dos números salen de ahí:

- **Acuerdo bruto**: en qué fracción coincidieron. Es fácil de leer y **engaña**: si el 90% de las
  respuestas son buenas, un juez que diga "buena" siempre acierta el 90%.
- **Kappa de Cohen**: el acuerdo descontando el que habría salido por azar. Es el número honesto.
  Por debajo de 0.4 el juez no sirve para decidir nada; entre 0.6 y 0.8 es utilizable con cuidado.

Y hay dos sesgos del juez que conviene conocer porque son reproducibles: **premia las respuestas
largas** y **prefiere lo que se parece a lo que él habría escrito**. La rúbrica escrita mitiga el
primero; el segundo se mitiga usando un modelo distinto del que genera, y aun así no desaparece.

### Esto sí funciona igual

- **Es una suite de regresión.** Corre en CI, protege contra empeorar, y su valor está en que
  falle cuando debe.
- **La separación entre conjunto de desarrollo y de retención** es la misma disciplina que
  cualquier validación: no ajustes contra lo que te mide.
- **Versionar los datos de prueba** es lo de siempre; aquí el dato de prueba es el activo caro.
- **El informe de CI** es un informe de CI: qué corrió, contra qué versión, cuánto tardó. Le
  agregas una columna de dólares.
- **El intervalo de confianza** es estadística de primer curso, y es exactamente lo que hace falta.

### Diccionario de traducción

| Java / tu stack | Track `ia` | Dónde se rompe el paralelo |
|---|---|---|
| `assertEquals` | Calificación con rúbrica | No hay valor esperado: hay un criterio, y aplicarlo tiene error |
| Suite de regresión | Conjunto de evaluación | Es un **activo de dominio**, lo escribe alguien que sabe de coberturas, y cuesta más que el código que prueba |
| Prueba intermitente = bug | Variación = propiedad | No se arregla, se acota con `n` corridas y un intervalo |
| Cobertura de código | Cobertura del conjunto | No mide líneas ejecutadas: mide **qué casos del dominio están representados**, y de eso no hay herramienta |
| Mock del colaborador | Juez automático | El doble **también se equivoca**, y hay que medir cuánto |
| Verde / rojo | Piso y límite inferior del intervalo | Una corrida no decide nada; decide la distribución |
| Tiempo de CI | Tiempo **y dólares** de CI | Correr la suite cuesta dinero, y eso cambia cada cuánto se corre |

> 📝 **Nota de ecosistema.** Hay bibliotecas de evaluación de sistemas RAG —Ragas, DeepEval,
> promptfoo y varias más— y todas traen métricas con nombre propio: fidelidad, pertinencia del
> contexto, corrección de la respuesta. El curso **no adopta ninguna**, por la misma razón por la
> que escribió el bucle de agente a mano en `ia03`: una métrica cuya definición no puedes recitar
> es una métrica que no puedes defender cuando Julián pregunte qué significa el 0.82. Escribe la
> tuya —son cincuenta líneas—, y después evalúa si una biblioteca te ahorra trabajo. Esa
> comparación es material de `ia08`, con su medición.

---

## 💻 5. Código mínimo con comentarios

El código vive en `src/ia06-evaluacion/`.

### 5.1 El conjunto como activo

```python
# src/ia06-evaluacion/evalset.py
"""El conjunto de evaluación: un activo versionado, no un archivo de pruebas.

Lo escribe una persona que sabe de coberturas. Cuesta más que el código que prueba y
dura más: el sistema se va a reescribir dos veces y el conjunto va a seguir sirviendo.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

# Desarrollo: contra este se itera. Retención: se toca lo mínimo posible, y es el que
# dice la verdad. Si iteras contra el de retención, en veinte vueltas tu sistema estará
# ajustado a cincuenta preguntas y no al problema de Patricia.
Split = Literal["desarrollo", "retencion"]


@dataclass(frozen=True, slots=True)
class EvalCase:
    """Un caso: la pregunta, lo que debería contestar, y por qué está en el conjunto."""

    case_id: str
    question: str
    # Escrita por una persona. Una respuesta de referencia generada por otro modelo
    # convierte la evaluación en un espejo: mide el parecido con ese modelo.
    reference_answer: str
    # Fragmento que debería recuperarse. Permite reusar las métricas de ia04 sobre el
    # mismo conjunto y separar el fallo de recuperación del de generación.
    expected_chunk_id: int | None
    # Qué se está probando con este caso. Sin esto, en seis meses nadie sabe por qué
    # está aquí ni si se puede borrar.
    rationale: str
    split: Split
    # True cuando lo correcto es NO contestar. Son los casos más valiosos del conjunto
    # y los que casi nadie incluye.
    should_abstain: bool = False


@dataclass(frozen=True, slots=True)
class EvalSet:
    """El conjunto completo, con su huella."""

    cases: list[EvalCase]
    fingerprint: str

    def split(self, which: Split) -> list[EvalCase]:
        return [case for case in self.cases if case.split == which]


def load(path: Path) -> EvalSet:
    """Carga el conjunto y calcula su huella.

    La huella entra en todos los informes: dos números producidos con conjuntos
    distintos no son comparables, y sin la huella nadie se da cuenta de que lo son.
    """
    raw = path.read_bytes()
    fingerprint = hashlib.sha256(raw).hexdigest()[:12]

    cases = [
        EvalCase(
            case_id=record["id"],
            question=record["pregunta"],
            reference_answer=record["respuesta_referencia"],
            expected_chunk_id=record.get("fragmento_esperado"),
            rationale=record["por_que"],
            split=record["particion"],
            should_abstain=record.get("debe_abstenerse", False),
        )
        for record in (json.loads(line) for line in raw.decode("utf-8").splitlines() if line.strip())
    ]

    return EvalSet(cases=cases, fingerprint=fingerprint)
```

### 5.2 El juez, con su rúbrica escrita

```python
# src/ia06-evaluacion/judge.py
"""El juez automático. Es un modelo, se equivoca, y por eso `agreement.py` existe."""

from __future__ import annotations

from decimal import Decimal
from typing import Literal

import anthropic
from pydantic import BaseModel, Field

from pricing import CATALOG

# Un modelo distinto del que genera. No elimina el sesgo de "me gusta lo que yo habría
# escrito", pero lo reduce; y es más barato, que importa cuando la suite corre a diario.
JUDGE_MODEL = "claude-haiku-4-5"

# La rúbrica va en el prompt y va en el repositorio. Si no está escrita, cada corrida
# califica con un criterio ligeramente distinto y los números dejan de ser comparables
# entre versiones, que es justo lo que la evaluación viene a evitar.
RUBRIC = """Califica la RESPUESTA contra la REFERENCIA para una administradora de una red
odontológica. Tres niveles y nada más:

- "correcta": afirma lo mismo que la referencia en lo que importa para facturar. La
  redacción puede ser distinta; el sentido no.
- "incompleta": lo que dice es cierto pero le falta algo de la referencia que cambia la
  decisión (una condición, una vigencia, un copago).
- "incorrecta": contradice la referencia, o afirma algo que la referencia no sostiene.

Dos advertencias sobre tu propio sesgo, y son parte del criterio:
- La longitud no es calidad. Una respuesta de una línea puede ser "correcta" y una de un
  párrafo puede ser "incorrecta".
- Que la respuesta no se parezca a como tú la habrías escrito no la hace peor.

Caso especial: si la referencia dice que NO se puede contestar con los documentos, una
respuesta que se abstiene es "correcta" y una que contesta es "incorrecta", por buena que
suene.
"""

Verdict = Literal["correcta", "incompleta", "incorrecta"]


class Judgment(BaseModel):
    """El fallo del juez. La justificación es obligatoria y es para ti, no para la métrica."""

    model_config = {"extra": "forbid"}

    # `reason` va ANTES que `verdict` en el orden del esquema a propósito: la salida
    # estructurada genera los campos en orden, así que obliga a que el texto de la
    # justificación exista antes de comprometerse con la etiqueta.
    reason: str = Field(min_length=10, description="Una frase. Qué falta o qué contradice.")
    verdict: Verdict


def judge(
    client: anthropic.Anthropic,
    *,
    question: str,
    reference: str,
    candidate: str,
) -> tuple[Verdict, str, Decimal]:
    """Califica una respuesta. Devuelve el veredicto, su motivo y lo que costó."""
    response = client.messages.parse(
        model=JUDGE_MODEL,
        max_tokens=512,
        system=RUBRIC,
        messages=[
            {
                "role": "user",
                "content": (
                    f"PREGUNTA: {question}\n\n"
                    f"REFERENCIA: {reference}\n\n"
                    f"RESPUESTA: {candidate}"
                ),
            }
        ],
        output_format=Judgment,
    )

    judgment = response.parsed_output
    cost = CATALOG[JUDGE_MODEL].cost_of(
        response.usage.input_tokens, response.usage.output_tokens
    )
    return judgment.verdict, judgment.reason, cost
```

### 5.3 Los tres números que hacen honesta la evaluación

```python
# src/ia06-evaluacion/statistics_helpers.py
"""Acuerdo, kappa e intervalo. Funciones puras: sin red, sin modelo, sin base de datos.

Son las tres piezas que convierten una calificación en algo defendible, y las tres se
escriben en cincuenta líneas. Es también la respuesta a por qué el curso no adopta una
biblioteca de evaluación: no hay nada aquí que valga una dependencia.
"""

from __future__ import annotations

import math
from collections import Counter
from collections.abc import Sequence


def raw_agreement(a: Sequence[str], b: Sequence[str]) -> float:
    """Fracción de casos en que dos jueces coincidieron.

    Fácil de leer y engañoso: si el 90% de las respuestas son buenas, un juez que diga
    siempre "correcta" saca 0.90 y no sirve para nada. Por eso nunca va solo.
    """
    if len(a) != len(b):
        raise ValueError("Las dos series de juicios tienen que tener el mismo largo.")
    if not a:
        return 0.0
    # `strict=True` es redundante con la comprobación de largos de arriba, y se pone
    # igual: si alguien borra esa comprobación, el error sale aquí en vez de dar un
    # acuerdo calculado sobre la serie más corta.
    return sum(1 for x, y in zip(a, b, strict=True) if x == y) / len(a)


def cohen_kappa(a: Sequence[str], b: Sequence[str]) -> float:
    """Acuerdo descontando el que habría salido por azar. El número honesto.

    Interpretación operativa, y conviene tenerla a mano al leer el resultado:
      < 0.40  el juez no sirve para decidir nada
      0.40–0.60  hay señal, pero no se despliega con esto
      0.60–0.80  utilizable con cuidado
      > 0.80  bueno, y sospecha de un conjunto demasiado fácil

    Devuelve 1.0 cuando los dos jueces coinciden en todo Y no hay acuerdo esperado que
    descontar; cuando ambos etiquetan siempre igual, el kappa es indefinido y se
    devuelve 1.0 declarándolo, que es la convención menos mala.
    """
    observed = raw_agreement(a, b)

    total = len(a)
    counts_a, counts_b = Counter(a), Counter(b)
    expected = sum(
        (counts_a[label] / total) * (counts_b[label] / total)
        for label in set(counts_a) | set(counts_b)
    )

    if math.isclose(expected, 1.0):
        return 1.0
    return (observed - expected) / (1 - expected)


def wilson_interval(successes: int, trials: int, *, z: float = 1.96) -> tuple[float, float]:
    """Intervalo de confianza del 95% para una proporción, método de Wilson.

    Wilson y no el normal de toda la vida porque con pocas muestras —que es siempre, en
    un conjunto de cincuenta casos— el normal da intervalos que se salen de [0, 1] y
    mienten en los extremos.

    El número que importa es el LÍMITE INFERIOR: con 16 aciertos de 20 el punto es 0.80
    y el intervalo va de 0.58 a 0.92. Celebrar el 0.80 es engañarse.
    """
    if trials <= 0:
        return 0.0, 0.0

    proportion = successes / trials
    denominator = 1 + z**2 / trials
    center = (proportion + z**2 / (2 * trials)) / denominator
    margin = (
        z
        * math.sqrt(proportion * (1 - proportion) / trials + z**2 / (4 * trials**2))
        / denominator
    )
    return max(0.0, center - margin), min(1.0, center + margin)


def required_sample_size(baseline: float, improvement: float, *, z: float = 1.96) -> int:
    """Cuántos casos hacen falta para distinguir `baseline` de `baseline + improvement`.

    Es el número del tag `ia-mini-06` y el que más va a cambiar lo que le prometes a
    Julián sobre "medimos la calidad": si para detectar cinco puntos hacen falta
    cuatrocientos casos y tienes cincuenta, no puedes detectar cinco puntos y punto.

    Aproximación normal, dos proporciones, una cola. Es una estimación de orden de
    magnitud y así hay que leerla; para eso sobra.
    """
    if not 0 < baseline < 1 or improvement <= 0 or baseline + improvement >= 1:
        raise ValueError("Las proporciones tienen que caer dentro de (0, 1).")

    p_avg = baseline + improvement / 2
    variance = 2 * p_avg * (1 - p_avg)
    return math.ceil(variance * (z / improvement) ** 2)
```

> ⚠️ **El número que conviene tener delante antes de prometer nada.** Con esa función, partiendo
> de una calidad del 80%: detectar una mejora de **diez puntos** necesita unos **98 casos**;
> detectar **cinco puntos**, unos **444**. No es una medición —es aritmética, y la puedes
> reproducir ahora mismo— pero cambia la conversación entera: un conjunto de cincuenta casos
> detecta cambios grandes y **no puede distinguir** dos versiones parecidas. Decirlo por
> adelantado es lo que separa un arnés honesto de uno que va a validar mejoras que no existen.

**Detalles con intención**

- **Tres funciones puras en un archivo sin dependencias.** Se prueban en milisegundos y se pueden
  leer enteras, que es la condición para poder defender el número que producen.
- **Wilson y no el intervalo normal.** Con veinte o cincuenta casos, el normal produce límites
  fuera de `[0, 1]`; es el error clásico de aplicar la fórmula de los apuntes sin mirar el tamaño
  de muestra.
- **El kappa trae su tabla de interpretación en el docstring.** Un número sin escala es un número
  que alguien va a leer como porcentaje.
- **`raw_agreement` documenta su propia trampa.** Una función que solo se puede usar bien
  acompañada tiene que decirlo donde se lee.
- **Las cuatro tienen prueba, y las pruebas son el contenido.** `test_statistics.py` incluye la
  del juez perezoso —acuerdo 0.90, kappa 0.00— que es la sección 4 convertida en aserción, y la
  del intervalo que no se sale de `[0, 1]` en los extremos, que es donde el intervalo normal
  miente. Trece pruebas, sin red, en milisegundos: el número que decide un despliegue tiene que
  ser el mejor probado del sistema.

### 5.4 Las dos deudas que se pagan aquí

```python
# src/ia06-evaluacion/calibrate.py
"""Pago de la deuda 💸 de ia04: el umbral de distancia sale de los datos.

En ia04 el umbral era 0.35 «por intuición», y estaba declarado como deuda. Aquí se
deriva: se corre la recuperación sobre el conjunto anotado, se miran las distancias de
los aciertos y las de los fallos, y se elige el corte que mejor los separa.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class ThresholdReport:
    """El umbral elegido, y lo que cuesta elegirlo así."""

    threshold: float
    recall_kept: float  # aciertos que sobreviven al corte
    noise_removed: float  # fallos que el corte elimina
    considered: int


def choose_threshold(
    hit_distances: list[float],
    miss_distances: list[float],
    *,
    min_recall: float = 0.95,
) -> ThresholdReport:
    """Elige el corte más estricto que conserve `min_recall` de los aciertos.

    El criterio no es "el que maximiza la exactitud": es asimétrico a propósito, porque
    los dos errores cuestan distinto. Perder un fragmento correcto hace que NormaRAG se
    abstenga de algo que sabía —Patricia deja de usarlo—; dejar pasar uno irrelevante lo
    filtra después la verificación de citas de ia05. Se prioriza no perder aciertos.
    """
    if not hit_distances:
        raise ValueError("Sin aciertos anotados no se puede calibrar nada.")

    candidates = sorted(set(hit_distances + miss_distances))
    best = ThresholdReport(
        threshold=max(candidates), recall_kept=1.0, noise_removed=0.0, considered=len(candidates)
    )

    for threshold in candidates:
        kept = sum(1 for distance in hit_distances if distance <= threshold) / len(hit_distances)
        if kept < min_recall:
            continue

        removed = (
            sum(1 for distance in miss_distances if distance > threshold) / len(miss_distances)
            if miss_distances
            else 0.0
        )
        if removed > best.noise_removed or (
            removed == best.noise_removed and threshold < best.threshold
        ):
            best = ThresholdReport(
                threshold=threshold,
                recall_kept=kept,
                noise_removed=removed,
                considered=len(candidates),
            )

    return best
```

```python
# src/ia06-evaluacion/provider.py
"""Pago de la deuda 💸 de ia01: el Protocol de proveedor.

En ia01 se dejó a propósito sin abstraer —abstraer dos proveedores antes de conocer el
tercero es el reflejo que el camino base enseña a no tener—. Aquí la abstracción se gana
el sueldo: el conjunto de evaluación tiene que correr contra la API y contra el modelo
local, y sin una interfaz común son dos arneses que se desincronizan.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Protocol


class Completion(Protocol):
    """Lo mínimo que el arnés necesita de un proveedor, y ni un método más."""

    text: str
    cost: Decimal
    latency_ms: float


class Provider(Protocol):
    """Un proveedor de respuestas. La API y Ollama lo cumplen; el arnés no los distingue."""

    name: str

    def complete(self, *, system: str, prompt: str, max_tokens: int) -> Completion: ...
```

> 💸 **Y una deuda nueva, declarada.** El juez califica **una respuesta a la vez** contra su
> referencia. Es lo más simple y tiene un techo conocido: para comparar dos versiones del sistema,
> la comparación **por pares** —mostrarle las dos respuestas y preguntar cuál es mejor— tiene
> bastante más acuerdo con el humano. **Se paga en `ia08`**, donde hay dos versiones que comparar
> de verdad. Aquí no se paga porque todavía no hay contra qué.

**El patrón a memorizar**

> Tres números y ninguno sobra: **el punto** dice cómo te fue, **el intervalo** dice si te lo
> puedes creer, y **el kappa del juez** dice si el número significa algo. Publicar el primero solo
> es lo que hace todo el mundo, y es de donde salen las mejoras que no existen.

**Prueba de fuego**

```bash
uv run python run_eval.py --conjunto evalset.jsonl --particion retencion --corridas 3
```

Lo que tiene que salir: la tasa por veredicto, su intervalo, la huella del conjunto, el costo total
y el kappa del juez de la última calibración. **La mentira que te va a contar la salida si miras el
lugar equivocado:** si el informe dice 0.86 de correctas y te quedas ahí, te vas a perder que el
intervalo va de 0.74 a 0.93 —así que una versión con 0.81 **no es peor**, es indistinguible— y que
el kappa del juez es 0.38, con lo cual el 0.86 no mide lo que crees. El orden en que hay que leer
el informe es exactamente el inverso al que invita: kappa, intervalo, punto.

---

## 📏 6. Medición

**Hipótesis.** El juez automático con rúbrica escrita **alcanza un kappa por encima de 0.6 contra
el juicio humano** en las respuestas de NormaRAG, suficiente para detectar regresiones grandes y
**no** suficiente para decidir entre dos versiones parecidas. Y evaluar cuesta menos que lo que
cuesta equivocarse: la suite completa vale menos que una glosa.

**Condiciones.** Python 3.14.7; `anthropic` 1.5.0; juez `claude-haiku-4-5`, generador
`claude-opus-5`. Conjunto de evaluación de cincuenta casos —treinta de desarrollo, veinte de
retención—, con respuestas de referencia escritas por el autor, **quince de ellos con abstención
como respuesta correcta**. Treinta respuestas calificadas a mano con la rúbrica delante, **antes**
de ver el fallo del juez: al revés, el anclaje arruina la comparación. Tres corridas completas.

**Competidores.** Cuatro formas de calificar, todas defendibles:

1. **Coincidencia de palabras clave** con la referencia. Es la línea base barata y es lo que hay en
   muchos repositorios; hay que medirla en serio para poder descartarla.
2. **Similitud de embeddings** entre respuesta y referencia, con el modelo local de `ia04`.
3. **Juez con rúbrica**, el de la sección 5.2.
4. **Juez con rúbrica usando `claude-opus-5`** como juez, para ver qué compra el modelo caro.

**Resultado.**

| Forma de calificar | Acuerdo bruto | Kappa | Costo de calificar 50 | Tiempo |
|---|---|---|---|---|
| Palabras clave | ⏳ | ⏳ | $0 | ⏳ |
| Similitud de embeddings | ⏳ | ⏳ | $0 (local) | ⏳ |
| Juez con rúbrica · Haiku 4.5 | ⏳ | ⏳ | ⏳ | ⏳ |
| Juez con rúbrica · Opus 5 | ⏳ | ⏳ | ⏳ | ⏳ |

```bash
uv run python bench_judges.py --conjunto evalset.jsonl --humanos juicios_humanos.jsonl
```

> ⚖️ **Veredicto — pendiente de correr, con la expectativa declarada.** Esperamos que las filas 1
> y 2 tengan acuerdo bruto alto y kappa bajo —que es exactamente la trampa que la sección 4
> describe— y que la 3 sea utilizable. **Los dos umbrales por determinar:** el kappa mínimo a
> partir del cual dejamos que el juez decida un despliegue sin que una persona mire, y **cuánto
> kappa adicional compra la fila 4 por su diferencia de precio**. Si Opus como juez no sube el
> kappa de forma clara, la decisión es Haiku y la suite puede correr a diario. **Y si ninguna
> supera 0.6, la conclusión honesta es que NormaRAG no se puede evaluar automáticamente todavía,
> y entonces lo que hay que construir es la herramienta para que una persona califique veinte
> respuestas en diez minutos** — que es más barato que fingir una métrica.

> 📝 **Lo que esta medición no dice:** si el conjunto de evaluación es representativo de lo que
> Patricia pregunta. Cincuenta casos escritos por el autor cubren lo que el autor imaginó. La
> cobertura del conjunto no tiene herramienta y se gana mirando el registro de producción, que es
> trabajo de `ia08`.

---

## 🧱 7. Miniproyecto — El informe que decide el despliegue

**El encargo.** Construye `aur-eval`, el arnés que decide si un cambio en NormaRAG se despliega o
no. Corre el conjunto de evaluación, califica, compara contra la última corrida guardada, y emite
un veredicto con su justificación. Va a correr en CI y va a bloquear un despliegue, así que su
salida tiene que ser entendible por ti dentro de seis meses y por quien te reemplace.

**Por qué duele.** Porque la respuesta correcta casi nunca es "mejoró" o "empeoró": es **"no se
puede distinguir con este tamaño de muestra"**, y esa es la que nadie quiere escribir. Un arnés que
declara mejoras que son ruido es peor que no tener arnés, porque va a validar cambios malos con
autoridad.

**Datos de entrada.** El conjunto de evaluación de cincuenta casos —lo escribes tú, y **quince
tienen que ser de abstención**— y los treinta juicios humanos de la sección 6.

**Criterios de aceptación.**

1. `aur-eval correr --particion retencion` produce un informe con: tasa por veredicto, intervalo
   de Wilson de cada una, huella del conjunto, versión del sistema, costo total y fecha.
2. `aur-eval comparar --contra <corrida>` emite uno de **tres** veredictos —mejora, regresión o
   **indistinguible**— y el tercero es el que más veces debería salir. Si tu herramienta nunca lo
   emite, está mal.
3. La comparación se hace sobre el **mismo conjunto y con el mismo número de corridas**, y la
   herramienta se niega a comparar dos informes con huellas distintas, con un mensaje que dice por
   qué.
4. `aur-eval calibrar-juez --humanos juicios_humanos.jsonl` reporta acuerdo y kappa, y **el informe
   de calidad incluye el kappa vigente**. Si el kappa está por debajo de un piso configurado, el
   informe sale marcado como no concluyente.
5. Corre en CI en menos de lo que tú decidas y declares, con su costo impreso en dólares. Un arnés
   que cuesta cinco dólares por commit no se va a correr, y eso es un requisito de diseño.
6. Los quince casos de abstención se reportan **aparte**: un sistema que mejora contestando más y
   abstiene menos puede estar empeorando, y el agregado lo esconde.
7. `--semilla` fija todo lo fijable y el informe declara qué **no** es reproducible y por qué.

**Restricciones de registro.** Aplicación. Usa `statistics_helpers.py` sin modificarlo. **El
veredicto de la comparación no lo emite un modelo**: es aritmética sobre intervalos, y delegarlo en
un LLM sería el chiste final del track.

**La trampa.** El criterio 2. Para emitir "indistinguible" bien hay que comparar **intervalos, no
puntos**, y darse cuenta de que con veinte casos de retención casi todo es indistinguible. La
conclusión incómoda a la que probablemente llegues —y que quiero por escrito en el README de tu
entregable— es **cuántos casos harían falta** para detectar la mejora que te interesa. Si son
trescientos y tienes cincuenta, eso cambia lo que puedes prometerle a Julián sobre "medimos la
calidad".

**Pistas.** Empieza por el criterio 2 con datos inventados: es aritmética y se prueba sin gastar un
peso. Para el criterio 6, mira primero cuántas de las quince abstenciones acierta el sistema hoy;
si son quince de quince, el conjunto es demasiado fácil. Y para el 5, mide el costo antes de
decidir la frecuencia, no al revés.

**Cómo se entrega.** `git tag -a ia-mini-06`, y **en el mensaje del tag van el kappa del juez, la
tasa de correctas con su intervalo, y el número de casos que harían falta para detectar una mejora
de cinco puntos**. Ese tercer número es el más útil de los tres.

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Calcula el kappa entre dos jueces que califican todo "correcta" sobre un conjunto donde el 90%
   lo es. Compara con el acuerdo bruto. Es la trampa de la sección 4 en dos líneas.
2. Corre el conjunto de retención tres veces sin cambiar nada y reporta la dispersión de la tasa.
   Ese número es el piso de lo que puedes detectar.
3. Calcula el intervalo de Wilson para 16 de 20, 80 de 100 y 800 de 1.000. Los tres son 0.80.
   Escribe qué cambia.
4. Quítale a la rúbrica la advertencia sobre la longitud y califica veinte respuestas. ¿Cambia
   algo? Documenta el resultado, sea cual sea.
5. Añade al conjunto tres casos de abstención más y mira si la tasa global sube o baja. Explica
   por qué eso hace más honesto al conjunto aunque el número empeore.
6. Haz que el informe imprima la huella del conjunto y prueba que cambia al agregar un caso.

**🟡 Intermedio (7–14)**

7. Implementa la fila 1 de la medición —coincidencia de palabras clave— y encuentra la respuesta
   correcta que reprueba y la incorrecta que aprueba. Con dos ejemplos basta para descartarla.
8. Implementa la fila 2 —similitud de embeddings— reusando el modelo local de `ia04` y compara su
   kappa con el del juez.
9. Corre el juez dos veces sobre las mismas treinta respuestas y mide su acuerdo **consigo mismo**.
   Un juez que no se pone de acuerdo con su propia calificación no puede tener buen kappa contra
   nadie.
10. Haz que `choose_threshold` reporte la curva completa —recall conservado contra ruido eliminado,
    para cada corte— y grafícala. Es la deuda 💸 de `ia04`, bien pagada.
11. Implementa el `Provider` para Ollama y corre el conjunto de retención contra el modelo local.
    Reporta la diferencia de calidad y de costo.
12. Escribe la prueba de CI del criterio 5 del miniproyecto, con umbral, `n` corridas e intervalo.
    Después hazla fallar a propósito degradando el prompt.
13. Añade al informe el desglose por tipo de pregunta —léxica, semántica, mixta, de `ia04`— y busca
    si el sistema es peor en una de las tres.
14. Mide cuánto cuesta en dólares una corrida completa de la suite y calcula el gasto mensual si
    corriera en cada commit. Decide la frecuencia con ese número delante.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** El informe dice que la calidad subió de 0.78 a 0.86 tras un cambio de prompt.
    Con las herramientas de la sección, decide si la mejora es real. Hay al menos tres
    comprobaciones y una de ellas no tiene que ver con la estadística.
16. **Medición.** Calcula cuántos casos harían falta para detectar una mejora de cinco puntos
    porcentuales con confianza razonable. Es el criterio del tag `ia-mini-06` y el número que más
    va a cambiar lo que prometes.
17. Detecta el ajuste al conjunto: itera cinco veces contra el de desarrollo mejorando la métrica,
    y mide en cada vuelta qué pasa en el de retención. Grafica las dos curvas.
18. **Diagnóstico.** El kappa del juez es 0.55 y quieres subirlo sin cambiar de modelo. Prueba tres
    intervenciones —rúbrica más específica, ejemplos calificados en el prompt, y partir el juicio
    en dos preguntas más simples— y mide cuál sube más.
19. **De registro.** El arnés de evaluación: decide si es script, herramienta o aplicación, y
    **cuantifica el costo de las otras dos**. Después contesta: ¿qué pasa el día que tú no estés y
    alguien tenga que decidir si un cambio se despliega?
20. **De registro.** Julián pregunta si "la IA está funcionando bien". Escribe la respuesta de
    media página que se puede dar **hoy** con lo que mides, y la lista de lo que no puedes
    contestar y por qué.
21. Construye la herramienta del veredicto de la sección 6: la que permite calificar veinte
    respuestas en diez minutos. Mide **tu propio tiempo** calificando las veinte con ella y sin
    ella; si además consigues que otra persona la use, mejor, pero el ejercicio se cierra solo.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye el cambio en NormaRAG que **sube la métrica y empeora el sistema**.
    Hay al menos dos caminos: contestar más y abstenerse menos, y alargar las respuestas. Después
    arregla la evaluación para que lo detecte.
23. Diseña la medición de la **cobertura del conjunto de evaluación**: qué preguntas de Patricia no
    están representadas. No hay herramienta y hay que inventar el procedimiento; que sea repetible.
24. **Adversarial.** Demuestra que el juez es vulnerable a una respuesta que se declara a sí misma
    correcta —*"esta respuesta cumple la rúbrica"*— y diseña la defensa. Después argumenta qué dice
    eso sobre usar un juez para decidir despliegues sin supervisión.
25. Toma las cuatro filas de la medición y escribe la política de calidad de Áurea en una página:
    qué se mide, cada cuánto, quién decide, qué bloquea un despliegue y qué se hace cuando el
    resultado es indistinguible. Tiene que poder seguirla alguien que no escribió el sistema.

**🔥 Opcionales**

- Implementa la comparación por pares —la deuda 💸 declarada— y mide si su kappa es mejor que el
  del juicio individual.
- Calcula el kappa ponderado, que penaliza más confundir "correcta" con "incorrecta" que con
  "incompleta". Decide si lo prefieres.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://docs.claude.com/en/docs/test-and-evaluate/eval-tool` — la herramienta de evaluación de
  la consola y el enfoque que recomienda el proveedor. Útil como contraste con lo que esta sección
  construye a mano.
- `https://docs.claude.com/en/docs/build-with-claude/structured-outputs` — el contrato del juez es
  el mecanismo de `ia02`.
- `https://docs.python.org/3.14/library/statistics.html` — lo que la biblioteca estándar ya trae, y
  que es casi todo lo que hace falta.
- `https://docs.pytest.org/` — parametrización y marcadores, para separar las pruebas que cuestan
  dinero de las que no.

**Artículos y libros**

- El coeficiente kappa es de Jacob Cohen (1960), *A Coefficient of Agreement for Nominal Scales*.
  El intervalo es de Edwin B. Wilson (1927). Los dos son anteriores a todo esto por medio siglo, y
  eso es parte del argumento de por qué no hace falta una biblioteca nueva. Verifica los datos
  bibliográficos: aquí no se inventan.

**Orden de lectura sugerido:** el capítulo de `statistics` de Python **antes** de escribir nada,
para saber qué no tienes que implementar → la definición de kappa mientras escribes
`statistics_helpers.py` → la herramienta del proveedor al final, para comparar tu enfoque con el
suyo y decidir con criterio.

> ⚠️ URLs, títulos y contenidos pueden haber cambiado desde la fecha de verificación; el lector
> debe comprobarlos. Aquí no se inventan páginas, ISBN ni identificadores de video.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con lo que convierte al track en ingeniería: un conjunto de evaluación versionado, un juez
cuyo error está medido, intervalos en vez de puntos, y un veredicto que sabe decir *"no se puede
distinguir"*. Y con las dos deudas del track pagadas — el umbral de `ia04` sale ahora de los datos,
y el `Protocol` de proveedores de `ia01` se ganó el sueldo cuando hubo que correr el mismo conjunto
contra tres sitios.

Lo que viene es el segundo proyecto de IA y el que más puede salir mal: **Recepción asistida**, el
agente que atiende los 900 mensajes diarios de WhatsApp. Allá las herramientas de `ia03` se
convierten en producto, y aparece una dificultad que esta sección no resolvió: **evaluar una
conversación no es evaluar una respuesta**. Y aparece un límite que no es de calidad sino de
responsabilidad profesional: el agente nunca da consejo clínico, nunca promete un resultado, y ante
cualquier síntoma escala a una persona. Ese límite se evalúa con el aparato que acabas de
construir, y con una métrica nueva que es la que de verdad importa — no cuántos escala bien, sino
**cuántos deja pasar**.

> **La señal de que quedó bien:** cuando ante un número de calidad tu primera pregunta sea *"¿sobre
> cuántos casos?"*, y cuando escribir "indistinguible" en un informe te parezca un resultado
> profesional en vez de una confesión.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ia-fase-06 -m "ia06 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ia 06: …`), los de ejercicio su número
> (`ia 06 ej12: …`) y el miniproyecto el suyo (`ia 06 mini: …`). El miniproyecto terminado lleva
> además su tag anotado `ia-mini-06`, con **el kappa, la tasa con su intervalo y el tamaño de
> muestra necesario** en el mensaje. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
