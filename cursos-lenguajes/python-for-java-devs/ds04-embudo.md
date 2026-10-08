# 💸 ds04 — Proyecto · Embudo

> Python para desarrolladores Java senior · Track `ds` · sección 4 de 9
> Depende de: `ds01`, `ds02`, `ds03` · Habilita: `ds05`
> Registro de esta sección: **herramienta** — `aur-embudo`, instalable, con subcomandos
> Proyecto que avanza: Embudo — nace entero

---

## 🎯 1. Propósito

Áurea gasta seis mil millones de pesos en pauta y nadie sabe cuánto cuesta un paciente. Esta
sección lo responde, y la respuesta es más incómoda que un número: **hay cuatro respuestas,
todas correctas, y entre la más baja y la más alta hay 7,5 veces de diferencia sobre los
mismos datos**.

No es un problema de datos sucios ni de una biblioteca mal usada. Es que la pregunta *"¿qué
canal me trajo este paciente?"* **no tiene respuesta** cuando el paciente vio un video en
enero, le escribió a la sede en febrero y buscó en Google en marzo. Alguien tiene que
decidir cómo se reparte el mérito, esa decisión es de negocio y no de ingeniería, y viene
puesta por defecto en todos los tableros.

Al terminar tienes la herramienta que Marcela va a llevar al comité de franquicia, y —lo
que vale más— sabes decir en voz alta cuál es el supuesto que la sostiene.

> 🧭 **La regla que ordena la sección: un modelo de atribución es un reparto, y todo reparto
> suma uno.** Cada paciente adquirido reparte exactamente un crédito entre los canales que
> lo tocaron. Si los números de tus fuentes suman más pacientes de los que hubo, no tienes
> un informe: tienes tres plataformas acreditándose la misma conversión.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `aur-embudo costo` imprime el costo por paciente adquirido por canal, **con el modelo
      de atribución dicho en la primera línea** y su intervalo al lado.
- [ ] Los cuatro modelos están implementados y los cuatro reparten exactamente un crédito
      por paciente, comprobado por prueba sobre el conjunto completo.
- [ ] Sabes explicar por qué el informe excluye a los leads de los últimos tres meses, y qué
      pasa con el número si no los excluyes.
- [ ] El numerador y el denominador de todo cociente del informe cubren **la misma ventana**,
      y sabes qué se rompe cuando no.
- [ ] `aur-embudo aliados` responde la segunda pregunta de plata: cuánto cuesta un paciente
      retenido a través de la red, por aliado, por especialidad y por zona.
- [ ] Puedes decir, con el índice al lado, cuánto de una subida de enero es la campaña y
      cuánto es enero.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Gráficos** → `ds05`. Todo sale en tablas de texto, y parte del veredicto de `ds05` es
  que para estas siete cifras la tabla gana.
- **Cuadernos y reproducibilidad** → `ds06`, que va a medir cuántos de los cuadernos que
  produzcas aquí vuelven a correr.
- **Predecir** cualquier cosa → `ds07` en adelante. Esto es descripción, y la diferencia
  importa: aquí nada se entrena y nada generaliza.
- **Atribución por valor de Shapley o modelos markovianos** → fuera del curso. Reparten el
  mérito con más teoría y **no resuelven el problema de fondo**, que es que el contrafactual
  —*¿habría venido igual sin ese anuncio?*— no está en los datos. Lo que sí lo resuelve es
  un experimento, y eso es el ejercicio 24.
- **El costo de la valoración gratuita** —silla, tiempo de dos especialistas— → declarado
  fuera por falta de dato: el conjunto no lo tiene. Es una omisión que **favorece a todos
  los canales por igual** y se dice en el informe, no se esconde.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

Este es el recorrido del lead `L0000097`, que aceptó un plan de 9.900.000 pesos en la sede de
Suba. Está en el conjunto, tal cual:

```
2024-01-09 18:29  tiktok      (tt-antes-y-despues)
2024-01-21 02:41  instagram   (ig-brackets-adolescente)
2024-01-21 05:13  google      (sem-ortodoncia-bogota)
2024-02-13        plan_aceptado
```

¿Qué canal trajo a este paciente? Las tres respuestas obvias son defendibles: TikTok, porque
sin el video no existiría; Google, porque es donde decidió; los tres, porque hicieron falta
los tres. Y cada una de las tres le da un costo por adquisición distinto a un canal en el que
Marcela gasta **casi setenta y cinco millones de pesos al mes** — los tres canales pagos
reciben casi lo mismo, y esa simetría del presupuesto es justamente lo que hace que la
diferencia de la sección 6 venga del reparto y no del gasto.

**Esto no es una ambigüedad del dato: es una ambigüedad del mundo.** Los datos están
completos y limpios. Lo que falta es el contrafactual —qué habría pasado sin el video— y eso
no está en ningún archivo, porque no ocurrió.

### Los cuatro modelos, y por qué son cuatro

```python
def credit_first(touches):   # todo al descubrimiento
    return {touches[0][1]: 1.0}

def credit_last(touches):    # todo a la decisión
    return {touches[-1][1]: 1.0}

def credit_linear(touches):  # a partes iguales
    share = 1.0 / len(touches)
    ...

def credit_time_decay(touches, half_life_days=14.0):  # cuanto más cerca, más mérito
    closing = touches[-1][0]
    weights = [0.5 ** ((closing - when).total_seconds() / 86400 / half_life_days)
               for when, _ in touches]
    ...
```

Los cuatro comparten una propiedad y es la única que se puede exigir: **suman exactamente
uno**. Es lo que los hace repartos y no opiniones, y es lo que permite comprobarlos:

```python
def sanity_check(journeys, acquisitions, model, eligible=None) -> float:
    """Cuánto crédito reparte el modelo en total. Tiene que ser el número de pacientes."""
    return sum(credit_by_channel(journeys, acquisitions, model, eligible).values())
```

Sobre los 5.451 pacientes maduros del conjunto, los cuatro devuelven `5451.0`. Esa línea es
la diferencia entre un informe y un tablero.

### La censura por la derecha, que es la trampa que nadie ve

El conjunto es un export tomado el 31 de marzo de 2026. Un lead creado el 20 de marzo tiene
once días de historia, y TikTok tarda **hasta noventa y seis** en cerrar. Medirlo hoy es
contarlo como fracaso.

Así se ve en las cohortes por mes de creación, sin tocar nada más:

```
2025-10   1.111 leads ·  219 aceptaron ·  19,7%   maduro
2025-11   1.352 leads ·  249 aceptaron ·  18,4%   maduro
2025-12   1.474 leads ·  278 aceptaron ·  18,9%   maduro
2026-01   1.528 leads ·  272 aceptaron ·  17,8%   ⚠️ inmaduro
2026-02   1.240 leads ·  217 aceptaron ·  17,5%   ⚠️ inmaduro
2026-03   1.082 leads ·   57 aceptaron ·   5,3%   ⚠️ inmaduro
```

Marzo no fue un desastre: **marzo no ha terminado**. Cualquiera que lea esa tabla de arriba
abajo y vea la caída de 18,9% a 5,3% va a buscar una explicación de negocio para un artefacto
del calendario — y la va a encontrar, porque siempre se encuentra una.

```python
MATURITY = timedelta(days=96)     # el rezago del canal más lento

def mature_leads(created, cutoff, maturity=MATURITY):
    limit = cutoff - maturity
    return {lead for lead, day in created.items() if day <= limit}
```

> ⚠️ **Y la mitad que casi todo el mundo olvida: si recortas el denominador, recorta también
> el numerador.** Los leads maduros son los creados hasta el 25 de diciembre; el gasto de
> pauta que les corresponde es el de hasta esa fecha, no el de todo el período. La primera
> versión de este código no lo hacía, y el filtro de madurez **empeoraba** el número de
> TikTok en vez de mejorarlo — lo contrario de lo que el texto decía. Lo encontró la
> medición, no la revisión del código.

### Tu instinto de Java dice… y esta vez se equivoca

Tu instinto viene de sistemas transaccionales, donde **cada hecho tiene un dueño**: una venta
tiene un vendedor, un pedido tiene un cliente, una fila tiene una llave foránea. Aplicado
aquí, sale esto:

```sql
-- ❌ El reflejo. Es un SQL impecable y la pregunta está mal hecha.
SELECT canal, count(*) FROM leads WHERE acepto GROUP BY canal;
```

El `GROUP BY` exige que cada paciente pertenezca a un canal, así que hay que elegir una
columna —`canal_primer_toque` o `canal_ultimo_toque`— y en el momento de elegirla **ya
tomaste la decisión de negocio sin darte cuenta**. `ds01` lo hizo: usó el último toque
porque estaba ahí, y salió que TikTok costaba siete veces lo que Google.

```python
# ✅ El crédito es fraccionario, y el modelo se nombra en la salida.
credits = credit_by_channel(journeys, acquisitions, MODELS[args.modelo], mature)
```

Lo que se rompe es la idea de que existe *el* informe. Aquí hay cuatro informes, y el trabajo
del ingeniero no es elegir el correcto: es **hacer visible que se eligió**.

Y hay un segundo reflejo, más caro: **"si la cifra cambió, pasó algo"**. En un sistema
transaccional, sí. En una serie con estacionalidad, no:

```
ortodoncia  ene 1,77  feb 1,35  mar 0,93  …  nov 0,68  dic 0,60
estética    ene 0,72  feb 0,73  mar 0,87  …  nov 1,62  dic 1,82
```

Una campaña de ortodoncia lanzada en diciembre va a "funcionar" en enero **aunque no haga
nada**: enero trae 1,77 veces el promedio todos los años. Y una campaña de estética evaluada
en febrero va a parecer un fracaso por la misma razón, al revés.

### Esto sí funciona igual

- **Los `join` y las llaves.** Todo lo de `ds02` sigue vigente: aquí se unen cuatro fuentes
  que no comparten llave y `validate=` sigue siendo la red de seguridad.
- **La aritmética de cocientes.** Si numerador y denominador no cubren el mismo período, el
  cociente no significa nada. Es lo mismo que ya sabes de cualquier KPI mal construido.
- **Desconfiar de las diferencias pequeñas.** El intervalo de confianza no es estadística
  académica: es lo que separa "TikTok subió" de "TikTok subió más de lo que se mueve solo".
- **Nombrar los supuestos.** Un informe que no dice su modelo es como una medición que no
  dice su hardware.

### Autopsia: sumar los tableros de las tres plataformas

Es el error más caro del marketing digital y se comete todos los meses. Cada plataforma
reporta las conversiones que **ella** considera suyas, con su propia ventana y su propio
modelo. Sumarlas da esto:

- TikTok, con el modelo que más le favorece —primer toque—, se acredita **1.658**.
- Instagram, con el mismo, **1.549**.
- Google, con el suyo —último toque—, **1.136**.
- Total: **4.343 pacientes traídos por un canal pago**… cuando los tres canales pagos juntos
  solo fueron el último toque de **1.883** de los 5.451 adquiridos.

Cada plataforma aplica a sus propios datos el modelo que mejor la deja, que es lo que hace
cada una en la vida real. **La suma no cuadra porque no puede cuadrar**: el mismo paciente
está contado hasta tres veces, y sobran 2.460 conversiones que no existieron.

> 💡 **La comprobación de un minuto que hay que hacerle a cualquier informe de marketing:**
> suma las conversiones atribuidas de todas las fuentes y compáralo con los pacientes que
> entraron de verdad. Si la suma es mayor, alguien está contando dos veces, y el informe no
> se discute hasta que eso se explique.

### Diccionario de traducción

| Lo que sabes | Aquí | Dónde se rompe el paralelo |
|---|---|---|
| `GROUP BY canal` | reparto de crédito | El `GROUP BY` exige un dueño por fila; aquí el crédito es fraccionario |
| Llave foránea | modelo de atribución | La llave es un hecho; el modelo es una **decisión** que alguien tomó |
| `COUNT(*)` de conversiones | suma de créditos | El conteo suma enteros y siempre cuadra; los créditos suman uno **por diseño**, y hay que comprobarlo |
| Media y desviación | intervalo bootstrap | No hay fórmula cerrada: el CAC es un cociente de dos cantidades del mismo conjunto |
| Cohorte de usuarios | cohorte de leads | Igual en espíritu. La diferencia es que aquí la cohorte reciente **está incompleta**, no es peor |
| "Los datos no mienten" | — | Falso amigo. Los datos no mienten; el reparto sí opina, y opina por defecto |

> 📝 **Nota de ecosistema.** Los modelos de atribución de las plataformas de publicidad
> cambian, y cambian sin avisar y de forma no auditable: la ventana de conversión, qué cuenta
> como toque y cómo se reparte el mérito son decisiones del proveedor, no tuyas. Por eso el
> informe de Áurea **calcula el reparto desde sus propios toques** en vez de sumar lo que
> reporta cada tablero. Cuesta más y es lo único defendible ante un franquiciado que pregunta
> de dónde sale el número.

---

## 💻 5. Código mínimo con comentarios

El registro cambia aquí, y es la primera vez en el track: esto ya no es un script de
análisis, es una **herramienta** que Marcela corre sola, todos los meses, sin ti. Eso
significa lo que significó en la Fase 09 — entrada por `argparse` con subcomandos, salida
estable, códigos de salida que signifiquen algo y **ningún parámetro escondido en el
código**.

```bash
uv run aur-embudo costo --modelo primer-toque --corte 2026-03-31
uv run aur-embudo aliados --por especialidad
```

### 5.1 El reparto, que es todo el proyecto

```python
# src/ds04-embudo/attribution.py

def credit_by_channel(journeys, acquisitions, model, eligible=None):
    """Crédito total por canal, sumando el reparto de cada paciente adquirido."""
    totals: defaultdict[str, float] = defaultdict(float)
    for lead in acquisitions:
        if eligible is not None and lead not in eligible:
            continue
        touches = journeys.get(lead)
        if not touches:
            continue
        for channel, share in model(touches).items():
            totals[channel] += share
    return dict(totals)
```

**Detalles con intención**

- **`model` es un parámetro, no un `if`.** Los cuatro modelos son funciones con la misma
  firma y viven en un diccionario. Es lo que permite que la herramienta acepte `--modelo` y
  que la medición los recorra todos sin duplicar código.
- **`eligible` es opcional y por defecto no filtra.** Así el mismo código produce el número
  ingenuo y el honesto, que es lo que la sección 6 compara.
- **`journeys.get(lead)`, no `journeys[lead]`.** Un paciente adquirido sin ningún toque
  registrado es un dato incompleto, no un `KeyError` a las siete de la mañana del día uno.

### 5.2 El canal sin gasto no cuesta cero

```python
def cost_per_acquisition(spend, credits):
    """Costo por paciente adquirido, canal por canal.

    Solo se calcula para los canales con gasto conocido. El referido, el aliado y quien
    entra por la puerta **no tienen costo cero**: tienen un costo que esta fuente no mide
    —la comisión del aliado, el tiempo de la valoración gratuita— y devolver un cero ahí
    sería la mentira más cara del informe.
    """
    return {channel: spent / credits[channel]
            for channel, spent in sorted(spend.items()) if credits.get(channel)}
```

Es una decisión de diseño con consecuencias: el informe **no tiene fila** para el referido.
Un cero habría puesto al referido a la cabeza de la tabla y habría sugerido gastar todo el
presupuesto ahí. Un hueco declarado obliga a la pregunta correcta, que es cuánto cuesta de
verdad —y para los aliados, la sección 5.4 la contesta.

### 5.3 El intervalo, y por qué es bootstrap

```python
def interval(pool, journeys, model, spend, channel, repetitions, seed):
    """Percentiles 2,5 y 97,5 de remuestrear los pacientes con reemplazo."""
    rng = random.Random(seed)
    size = len(pool)
    samples = sorted(
        cac_for([pool[rng.randrange(size)] for _ in range(size)], journeys, model,
                spend, channel)
        for _ in range(repetitions))
    return samples[int(0.025 * repetitions)], samples[int(0.975 * repetitions) - 1]
```

No hay fórmula cerrada para el error estándar de este número: el costo por adquisición es un
cociente donde el denominador es una **suma de créditos fraccionarios** sobre el mismo
conjunto de pacientes. Remuestrear es lo que queda, y es honesto siempre que se declare la
semilla: **un intervalo que cambia entre corridas no es un número del curso**.

### 5.4 La segunda pregunta de plata

```python
@property
def cost_per_returned(self) -> float:
    """Lo que costó cada paciente que se quedó. `inf` si no se quedó ninguno.

    Se devuelve el infinito en vez de un cero o un `None` porque **es la respuesta
    correcta**: un aliado al que le pagaste comisiones y no te dejó un solo paciente
    tiene un costo por paciente retenido que no es un número, y esconderlo detrás de un
    cero lo pondría primero en el ranking.
    """
    return self.fees_cop / self.returned if self.returned else float("inf")
```

Y el umbral que evita el ranking indefendible:

```python
MINIMUM_REFERRALS = 30
```

Con veinte remisiones, dos pacientes de diferencia mueven la tasa de retorno diez puntos. Los
aliados por debajo del umbral **aparecen agrupados**, no ordenados uno por uno en una lista
que alguien va a usar para dejar de mandarle casos a un odontólogo.

**El patrón a memorizar**
> Antes de publicar un cociente, contesta tres preguntas: ¿el numerador y el denominador
> cubren la misma ventana?, ¿la ventana dejó terminar a los casos lentos?, y ¿qué supuesto
> de reparto estoy usando? Si alguna no tiene respuesta, el número no sale.

**Prueba de fuego**

```bash
pytest test_embudo.py -q
```

Veintitrés pruebas, sin dependencias. La que sostiene la sección es
`test_todo_modelo_reparte_exactamente_un_credito`; la que más disfruta el lector es
`test_el_ranking_se_invierte_entre_el_primer_y_el_ultimo_toque`, que es la tesis convertida
en aserción.

La mentira que te va a contar la salida si miras el lugar equivocado: la tabla de la sección
6 tiene intervalos estrechos y da la impresión de precisión. **Esa precisión es sobre el
muestreo, no sobre la verdad.** El intervalo dice cuánto se movería el número si repitieras
el trimestre con otros pacientes; no dice nada sobre si el reparto elegido es el correcto, y
esa incertidumbre —la que importa— es 7,5 veces más grande.

---

## 📏 6. Medición

**Hipótesis.** Que la elección del modelo de atribución mueve el costo por paciente adquirido
**más que cualquier diferencia real entre canales**, y que esa diferencia no se explica por
ruido de muestreo.

**Condiciones.** CPython 3.14.5, biblioteca estándar, sin dependencias. Conjunto del Embudo
con semilla 20260913: 32.550 leads, 6.065 adquiridos. Corte el 2026-03-31 y **madurez de 96
días** —el rezago máximo del canal más lento—, lo que deja 28.416 leads maduros y 5.451
pacientes adquiridos maduros. El gasto se recorta a la misma ventana: 5.283.929.067 COP
hasta el 2025-12-25. Intervalo bootstrap por percentiles, 200 remuestreos con reemplazo,
semilla 20260913. Los cuatro modelos corren **sobre exactamente el mismo conjunto de
pacientes**, y hay una prueba que verifica que los cuatro reparten 5.451,0 créditos.

**Competidores.** Los cuatro modelos entre sí. No hay hombre de paja: el de último toque es
el que traen por defecto casi todos los tableros, el lineal es el que propone cualquiera que
quiera ser justo, y el de decaimiento es el que más se parece a lo que la gente cree que está
midiendo.

**Resultado — reparto del crédito, en porcentaje.**

| Canal | Primer toque | Último toque | Lineal | Decaimiento |
|---|---|---|---|---|
| tiktok | **30,4%** | **4,1%** | 16,7% | 15,1% |
| instagram | 28,4% | 9,6% | 18,6% | 17,8% |
| google | 11,7% | 20,8% | 16,1% | 17,0% |
| referido | 11,1% | 30,1% | 20,3% | 21,4% |
| aliado | 11,4% | 24,7% | 18,0% | 18,4% |
| walk_in | 6,9% | 10,7% | 10,3% | 10,2% |

**Resultado — costo por paciente adquirido, en millones de COP, con su intervalo al 95%.**

| Canal | Primer toque | Último toque | Lineal | Decaimiento |
|---|---|---|---|---|
| google | 2,76 [2,59–3,04] | **1,55** [1,47–1,64] | 2,01 [1,94–2,10] | 1,90 [1,83–1,98] |
| instagram | 1,14 [1,09–1,18] | 3,35 [3,08–3,67] | 1,74 [1,66–1,80] | 1,81 [1,73–1,88] |
| tiktok | **1,06** [1,03–1,11] | **7,96** [7,01–9,07] | 1,93 [1,87–2,02] | 2,14 [2,07–2,25] |

**Resultado — lo que cuesta ignorar la madurez** (modelo de último toque):

| Canal | Sin filtro | Solo maduros | Cambio |
|---|---|---|---|
| google | 1.588.548 | 1.553.096 | −2,2% |
| instagram | 3.557.016 | 3.346.105 | −5,9% |
| tiktok | 8.706.318 | 7.961.814 | **−8,6%** |

```bash
python bench_attribution.py --datos data --corte 2026-03-31
```

> ⚖️ **Veredicto — y es el más incómodo del track.**
>
> **La atribución de marketing es, en buena medida, una mentira que se cuenta con gráficos
> bonitos, y aquí está la demostración.** Sobre los mismos 5.451 pacientes, TikTok cuesta
> **1,06 millones** por paciente si el mérito es del descubrimiento y **7,96 millones** si es
> de la decisión: **7,5×**. El ranking no se mueve, se invierte: TikTok es el canal más
> barato de los tres con un modelo y el más caro por un factor de cinco con el otro.
>
> **Y no es ruido.** Los intervalos al 95% no se tocan ni de lejos —[1,03–1,11] contra
> [7,01–9,07]—, así que la diferencia no viene de qué pacientes tocaron: viene de **quién
> decide que un video de TikTok cuenta**. Esa decisión no está en los datos y no la puede
> tomar el ingeniero.
>
> **La recomendación operativa, que es lo que Marcela necesita:** el informe de Áurea reporta
> el modelo **lineal** como cifra principal —1,74 a 2,01 millones, los tres canales dentro de
> un rango estrecho— y publica al lado las dos esquinas. No porque el lineal sea el correcto,
> sino porque es el único que no premia a nadie por diseño, y porque **la banda entre los
> cuatro modelos es la incertidumbre real** y esconderla es lo que hace daño.
>
> **Y una decisión concreta que sí se puede tomar con esto:** apagar TikTok era la conclusión
> obvia de `ds01`, que usó el último toque sin decirlo. Con los cuatro modelos delante, la
> respuesta honesta es que **TikTok es el canal de descubrimiento de Áurea** —el 30,4% de los
> primeros toques— y que apagarlo apagaría también parte de lo que hoy se le acredita a
> Google. El experimento que lo resolvería está en el ejercicio 24, y cuesta plata.
>
> **El umbral, dicho como criterio:** cuando dos modelos de atribución te dan la misma
> decisión, adelante sin discutir cuál era el correcto. Cuando te dan decisiones opuestas
> —como aquí—, el informe **no puede decidir**, y lo que corresponde es un experimento o una
> decisión declaradamente política, no un número mejor.

> 📝 **Lo que esta medición no dice.** No mide el costo de la valoración gratuita, que
> consume silla y tiempo de dos especialistas y que **ningún canal paga en esta tabla** — es
> una omisión declarada que favorece a todos por igual. No mide el valor del paciente, solo
> su costo: un paciente de estética vale más que uno de ortodoncia y esta tabla los suma. Y
> no resuelve el contrafactual, que es el único que respondería de verdad la pregunta.

### 6.1 La segunda pregunta: cuánto vale la red de aliados

| | |
|---|---|
| Aliados | 23 |
| Remisiones | 2.599 |
| Pacientes que se quedaron | 925 (**35,6%**) |
| Comisiones pagadas | 1.165.174.000 COP |
| **Costo por paciente retenido** | **1.259.648 COP** |

Y el reparto, para los aliados con al menos treinta remisiones:

| Corte | Más barato | Más caro | Diferencia |
|---|---|---|---|
| Por aliado | A001 · periodoncia · occidente · 987.375 | A010 · endodoncia · centro · 1.659.407 | **1,68×** |
| Por especialidad | periodoncia 1,18 M | endodoncia 1,42 M | 1,20× |
| Por zona | norte 1,17 M | centro 1,36 M | 1,16× |

> ⚖️ **Veredicto.** La red de aliados le cuesta a Áurea **1,26 millones por paciente
> retenido**, que está entre el costo de Google (1,55) y el de Instagram (3,35) bajo el mismo
> modelo de último toque. **La red no es cara: es el canal de adquisición más barato que
> tiene la empresa después de Google**, y nadie lo había calculado.
>
> La diferencia entre el mejor aliado y el peor es de **1,68×**, y es mayor que la diferencia
> entre especialidades (1,20×) o entre zonas (1,16×). Eso apunta a que el problema —cuando lo
> hay— es del aliado y no del tipo de caso que se le remite. **Con una advertencia que el
> informe imprime:** con un centenar de remisiones por aliado, una diferencia de 1,2× está
> dentro de lo que se mueve solo, y solo la de 1,68× merece una conversación.

---

## 🧱 7. Miniproyecto — El informe que Marcela puede defender

**El encargo.** Marcela te dice: *"El jueves tengo comité de franquicia y los seis
franquiciados van a preguntar por qué pagan fondo de mercadeo. Necesito una página por canal
con el costo por paciente, y necesito poder contestar cuando Julián diga que ese número está
inflado. Lo que no puedo es llegar con un número que no sepa defender."*

**Por qué duele.** Porque el entregable no es un número: es un número **más su defensa**. Y
porque la defensa incluye decir en voz alta que hay otro número igual de válido que dice lo
contrario, sin que eso destruya la credibilidad del informe. Escribir eso bien es más difícil
que calcularlo.

**Datos de entrada.** El conjunto del Embudo completo. El caso sucio no está en los datos
sino en la pregunta: **los seis franquiciados aportan al mismo fondo de mercadeo pero no
reciben los mismos leads**, y el gasto de pauta por sede del conjunto no es proporcional a lo
que cada uno aporta. Decide cómo repartes el costo entre sedes propias y franquiciadas, y
defiende el reparto — no hay una respuesta correcta y sí hay varias indefendibles.

**Criterios de aceptación.**

1. `aur-embudo comite --corte 2026-03-31` produce el informe completo en texto, con una
   sección por canal, y **la primera línea de cada sección nombra el modelo de atribución**.
2. El informe incluye una tabla de sensibilidad: el mismo costo bajo los cuatro modelos, y
   una frase que diga qué decisión cambia y cuál no.
3. Todo cociente del informe declara su ventana, y una prueba verifica que numerador y
   denominador la comparten.
4. `--por-sede` abre el costo por sede, **con el número de pacientes al lado de cada fila**:
   ninguna cifra por debajo de treinta adquisiciones se presenta sin advertencia.
5. El informe responde explícitamente a la objeción de Julián —*"ese número está inflado"*—
   con la comparación entre el cálculo ingenuo y el maduro, en pesos.
6. Corre en menos de cinco segundos sobre el conjunto completo y **no tiene dependencias**.
   Si te descubres necesitando pandas para esto, vuelve a mirar la tabla de `ds03`.
7. Dos corridas con el mismo corte producen el mismo texto, comprobable con `diff`. Eso
   incluye la semilla del bootstrap.

**Restricciones de registro.** **Herramienta**, no script: `pyproject.toml`, entry point,
subcomandos, `--help` que se entienda, y códigos de salida distintos para "no hay datos
suficientes" y para "error de ejecución". Es lo de la Fase 09 aplicado a un informe.

**La trampa.** El criterio 4. Al abrir por sede, la mayoría de las celdas van a tener menos
de treinta pacientes, y el intervalo bootstrap se va a volver enorme. La tentación es no
mostrar el intervalo para que la tabla se vea limpia. **Esa tabla limpia es la que hace que
un franquiciado cierre TikTok en su sede por una diferencia que es ruido.**

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

El informe tiene dos capas: el cálculo, que ya está escrito en `attribution.py`, y la
presentación, que es donde está todo el trabajo. Sepáralas del todo — vas a querer probar la
segunda sin recalcular la primera.
</details>

<details><summary>Pista 2 — la herramienta</summary>

Para los subcomandos, `argparse` trae `add_subparsers`, y la Fase 09 ya lo usó para `aur`.
Para el empaquetado y el entry point, lo de la Fase 07:
[packaging.python.org/en/latest/guides/writing-pyproject-toml/](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/)
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def report(data: Path, cutoff: date, model: str) -> str: ...
def sensitivity(data: Path, cutoff: date) -> str: ...
def by_branch(data: Path, cutoff: date, model: str, minimum: int = 30) -> str: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-04 -m "Mini ds04: informe del comité · modelo <X> · CAC <Y> M [banda entre modelos: <A>–<B> M]"
```

**En el mensaje del tag va la banda entre modelos**, no solo tu cifra. Es lo que distingue
este entregable de un tablero.

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre el informe con los cuatro modelos y arma tú la tabla de la sección 6. Después
   ordénala por canal y di cuál te sorprende más.
2. Cambia `HALF_LIFE_DAYS` a 3 y a 60, y mira cómo el modelo de decaimiento se acerca al del
   último toque y al lineal. Es el parámetro decidiendo el modelo.
3. Calcula el reparto sin filtro de madurez y compáralo con el filtrado. Reporta la
   diferencia por canal, en pesos.
4. Cuenta cuántos leads tienen un solo toque. Para ellos los cuatro modelos coinciden: ¿qué
   porcentaje del total del crédito es indiscutible?
5. Corre `stage_rates` e identifica el paso donde más gente se cae. Después mira ese mismo
   paso por canal.
6. Calcula el índice de estacionalidad de las aceptaciones —no de los leads— y compáralo con
   el de los leads. El desfase es el tiempo del embudo.

**🟡 Intermedio (7–14)**

7. Implementa un quinto modelo, "posición" (40% al primero, 40% al último, 20% repartido), y
   agrégalo a la tabla. Comprueba con la prueba existente que reparte exactamente uno.
8. El intervalo bootstrap usa 200 remuestreos. Súbelo a 2.000 y mira cuánto cambian los
   extremos. Decide con qué número te quedas y explica el costo.
9. Calcula el CAC por canal **y por sede** con el modelo lineal. Cuenta cuántas celdas tienen
   menos de treinta pacientes y qué porcentaje del total representan.
10. Mide cuánto tarda `bench_attribution.py` y encuentra dónde se va el tiempo. Pista: son
    los remuestreos, y hay una forma de hacerlos mucho más baratos sin cambiar el resultado.
11. Reproduce el cálculo de la autopsia —lo que se acredita cada plataforma por separado— y
    verifica la suma. Después escribe la frase de dos líneas con la que se lo explicarías a
    Marcela.
12. Agrupa a los aliados por zona y por especialidad a la vez. Con veintitrés aliados, ¿cuántas
    celdas quedan con volumen suficiente? Esa cuenta es la respuesta al ejercicio.
13. La madurez está fijada en 96 días, el rezago máximo de TikTok. Calcula el percentil 90 del
    rezago real por canal y propón una madurez por canal en vez de una global. Mide el efecto.
14. Escribe la prueba que falla si alguien cambia `LAG_DAYS` en el generador sin tocar
    `MATURITY`. Ya hay una parecida; hazla más estricta.

**🟠 Difícil (15–21)**

15. Diagnóstico: alguien reporta un CAC de TikTok de 620.000 COP y la tabla dice 1,06
    millones en el mejor de los casos. Encuentra las dos formas de llegar a esa cifra usando
    solo datos reales del conjunto, y explica cuál de las dos es fraude y cuál es descuido.
16. El informe excluye a los canales sin gasto. Diseña la forma de estimar su costo —la
    comisión del aliado ya la tienes; el referido y el `walk_in`, no— y di qué dato le
    pedirías a Patricia para cerrarlo.
17. Construye la serie mensual de CAC con el modelo lineal y quítale la estacionalidad con el
    índice. ¿Queda alguna tendencia? Si no queda, ese también es el resultado.
18. **De registro.** El informe pasa a correr todos los lunes y a mandarse por correo a seis
    franquiciados. ¿Sigue siendo una herramienta? Decide entre herramienta con cron,
    comando de `aur` o tarea del cierre nocturno de la Fase 15, con el costo de las otras dos.
19. Un franquiciado pide su costo por paciente **solo de su sede y solo de este mes**. Calcula
    el intervalo de esa celda y escribe la respuesta que le darías, incluyendo la parte
    incómoda.
20. Cambia la definición de "adquirido" de `plan_aceptado` a `primera_cuota` y vuelve a correr
    la tabla entera. La diferencia es el 6,3% que acepta y no paga: ¿cambia alguna decisión?
21. Toma los aliados con menos de treinta remisiones y construye el intervalo de su tasa de
    retorno. Demuestra con números por qué no entran al ranking.

**🔴 Muy difícil (22–25)**

22. **Defiende lo contrario.** Escribe el caso, con los datos de Áurea, para reportar el
    modelo de **último toque** como cifra principal en vez del lineal. Tiene que ser
    defendible ante Julián, no ante un profesor.
23. El intervalo bootstrap mide incertidumbre de muestreo y la sección dice que la
    incertidumbre que importa —la del modelo— es 7,5 veces mayor. Diseña una forma de
    **reportar las dos juntas** en una sola tabla que Marcela entienda, y justifícala.
24. Diseña el experimento que sí respondería la pregunta: apagar TikTok en unas sedes y no en
    otras durante un período. Especifica cuáles, cuánto tiempo, qué se mide, **cuántos
    pacientes hacen falta para detectar un efecto del 20%** —el cálculo está en
    `src/ia06-evaluacion/statistics_helpers.py`— y qué cuesta el experimento en pesos de
    pauta perdida.
25. **De registro.** Áurea compra tres redes más y el conjunto se multiplica por cuatro. Con
    la tabla de `ds03` delante, decide si este informe sigue siendo una herramienta de
    biblioteca estándar o se muda, y a dónde. Defiende con los dos números: el de tamaño y el
    de frecuencia.

**🔥 Opcionales**

- Calcula la atribución por valor de Shapley sobre los recorridos de tres o menos toques.
  Compárala con los cuatro modelos: ¿se parece a alguno?
- Mira los recorridos de los pacientes que **no** aceptaron. ¿Se distinguen de los que sí en
  algo que no sea el canal? Esa pregunta es la puerta de `ds07`.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://docs.python.org/3.14/library/random.html](https://docs.python.org/3.14/library/random.html)
  — `Random` con semilla explícita, que es lo que hace reproducible el intervalo.
- [https://docs.python.org/3.14/library/statistics.html](https://docs.python.org/3.14/library/statistics.html)
  — medianas y cuantiles de la biblioteca estándar. Alcanzan para todo lo de esta sección.
- [https://docs.python.org/3.14/library/argparse.html](https://docs.python.org/3.14/library/argparse.html)
  — `add_subparsers`, para el registro de herramienta del miniproyecto.
- [https://packaging.python.org/en/latest/guides/writing-pyproject-toml/](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/)
  — el `pyproject.toml` y el entry point, como en la Fase 07.

**Del propio curso**

- `src/ia06-evaluacion/statistics_helpers.py` — `required_sample_size`, que es lo que
  contesta *"¿cuántos casos hacen falta para detectar un efecto de este tamaño?"*. El
  ejercicio 24 lo necesita.
- [`ds03-polars-y-el-modelo-lazy.md`](ds03-polars-y-el-modelo-lazy.md) §6 — la tabla que
  justifica que esta herramienta no tenga dependencias.

**Sobre atribución**

La literatura de atribución multitoque es abundante y desigual, y buena parte viene de
proveedores que venden la solución. Dos términos para buscar con criterio —**"multi-touch
attribution"** y **"incrementality testing"**— y una advertencia: casi todo lo que encuentres
compara modelos entre sí, y casi nada aborda el contrafactual, que es el problema de fondo.
El material serio sobre eso está en la literatura de experimentos, no en la de marketing.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan
> números de página, ISBN ni identificadores de video que no se hayan comprobado.

**Orden de lectura sugerido.** Antes de escribir código: nada nuevo, todo lo que hace falta
ya está en el curso. Durante: `argparse` cuando llegues al miniproyecto. Después: busca
*incrementality testing* si el ejercicio 24 te dejó con ganas, porque ahí está la única
respuesta de verdad.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con el proyecto Embudo entero y con la respuesta que Marcela pedía, que resultó ser
cuatro respuestas y una banda. Eso no es un fracaso del análisis: **es el análisis**. Un
informe que hubiera dado un solo número habría sido más cómodo, más fácil de presentar y
falso.

También terminas con las dos correcciones que más cambian estos números y que casi nadie
aplica: **esperar a que las cohortes maduren** y **recortar el gasto a la misma ventana**. Las
dos juntas mueven el costo de TikTok un 8,6%, que es poco al lado del 750% que mueve el
modelo — y esa comparación, la de la corrección técnica contra la decisión de método, es la
lección que se lleva el track.

`ds05` es sobre cómo se presenta todo esto. Y llega con una tesis que después de esta sección
suena distinta: **para las siete cifras del comité de franquicia, una tabla bien hecha gana**.
Porque un gráfico de barras con el costo por canal, sin la banda entre modelos al lado, es
exactamente el gráfico bonito con el que se cuenta la mentira que acabas de desmontar.

> **La señal de que quedó bien:** cuando alguien te muestre un tablero de marketing y tu
> primera pregunta sea *"¿qué modelo de atribución usa, y cuánto cambia con otro?"* — y
> cuando puedas entregar una banda en vez de un número sin sentir que no hiciste el trabajo.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-04 -m "ds04 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 04: …`), los de ejercicio su número
> (`ds 04 ej12: …`) y el miniproyecto el suyo (`ds 04 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `ds-mini-04`, con **la banda entre modelos** en el mensaje. La
> convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
