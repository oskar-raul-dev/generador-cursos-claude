# ⚖️ so07 — Veredicto: cuándo paga y cuándo bastaba la hoja

> Python para desarrolladores Java senior · **Carta** · Track `so` — Optimización, simulación y
> decisiones · sección 7 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las seis anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track midió mejoras concretas sobre problemas de Áurea: el reparto del sábado con 10 % menos de desplazamiento
([`so01`](op096-so01-describir-en-vez-de-programar.md)), el precio de una silla más ([`so02`](op097-so02-programacion-lineal.md)), los
turnos de recepción en 0,03 segundos ([`so03`](op098-so03-or-tools.md)), la ruta del mensajero con 15 % menos de kilómetros
([`so04`](op099-so04-rutas-y-grafos.md)), la espera del sábado de 36 a 12 minutos con una recepcionista en vez de una silla
([`so05`](op100-so05-simulacion-con-simpy.md)), y el ausentismo de 18,5 % a 9,3 % moviendo los recordatorios
([`so06`](op101-so06-cuando-no-hay-modelo.md)).

Cada una de esas mejoras tiene un costo que el track no cobró: construir el modelo, conseguir y limpiar los datos, validarlo, y sobre
todo **mantenerlo** cuando cambian las reglas y la persona que lo entendía se va. La pregunta del veredicto es la que Julián haría: **¿paga,
o la hoja de Patricia era suficiente?** Y la respuesta no es "la optimización siempre paga"; depende de cuánto vale la mejora, cuántas veces
se repite, y cuánto cuesta sostener el modelo.

---

## 🧠 2. El modelo

| Señal | Hacia la hoja de cálculo | Hacia el modelo |
|---|---|---|
| Cuántas veces se decide | Una vez al año | Cada día o cada semana |
| Cuánto vale una mejora del 10 % | Poco | Mucho (minutos de especialista, kilómetros, pacientes que no faltan) |
| Cuántas reglas tiene | Pocas, estables | Muchas, que cambian |
| Quién lo mantiene | Patricia, que lo entiende | Alguien que entienda el modelo… y que siga en la empresa |
| ¿Hay datos para validar? | No hace falta | **Imprescindible** |

Y la regla de cierre: **un modelo paga cuando el valor anual de su mejora supera, con margen, el costo de construirlo y de mantenerlo**, y
cuando hay alguien que lo pueda mantener. Si la mejora es del 10 % de algo que vale poco, la hoja era suficiente; si es del 50 % de algo
que se repite todos los días, el modelo se paga en semanas.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `paga.py` aplica la regla a los seis problemas del track, con supuestos de valor y costo escritos a la vista.

```python
"""¿Paga el modelo? Valor anual de la mejora medida en el track contra el costo de construirlo y mantenerlo."""

from dataclasses import dataclass

HOUR_COST = 120_000                 # costo de una hora del ingeniero, en pesos (supuesto)


@dataclass
class Case:
    name: str
    yearly_value: int               # lo que vale la mejora medida, en pesos por año (supuesto, a partir del track)
    build_hours: int
    upkeep_hours_per_year: int
    has_owner: bool = True


def verdict(c: Case) -> str:
    cost_first_year = (c.build_hours + c.upkeep_hours_per_year) * HOUR_COST
    if not c.has_owner:
        return "no: nadie lo mantendría"
    ratio = c.yearly_value / cost_first_year
    return f"{'sí' if ratio >= 3 else 'dudoso' if ratio >= 1 else 'no, la hoja basta'} (vale {ratio:.1f} veces su costo)"


CASES = [
    Case("so01 reparto del sábado (10 % de desplazamiento)", 2_600_000, 16, 8),
    Case("so02 ¿una silla más? (decisión de una vez)", 0, 24, 0),
    Case("so03 turnos de recepción (4 h de Patricia al mes)", 5_760_000, 40, 16),
    Case("so04 ruta del mensajero (3 000 km al año)", 3_000_000, 12, 4),
    Case("so05 recepcionista en vez de silla (evita una compra)", 60_000_000, 30, 0),
    Case("so06 recordatorios (ausentismo a la mitad)", 180_000_000, 60, 20, has_owner=False),
]
for c in CASES:
    print(f"{c.name:<54} → {verdict(c)}")
```

```bash
python3 paga.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
so01 reparto del sábado (10 % de desplazamiento)       → no, la hoja basta (vale 0.9 veces su costo)
so02 ¿una silla más? (decisión de una vez)             → no, la hoja basta (vale 0.0 veces su costo)
so03 turnos de recepción (4 h de Patricia al mes)      → no, la hoja basta (vale 0.9 veces su costo)
so04 ruta del mensajero (3 000 km al año)              → dudoso (vale 1.6 veces su costo)
so05 recepcionista en vez de silla (evita una compra)  → sí (vale 16.7 veces su costo)
so06 recordatorios (ausentismo a la mitad)             → no: nadie lo mantendría
```

El veredicto es más duro de lo que el entusiasmo del track sugería, y por eso hay que leerlo. Con la construcción cargada al primer año,
solo la simulación de la sala de espera se paga sola de lejos: cuesta unas treinta horas y evita una compra de sesenta millones. La ruta del
mensajero queda en duda. El reparto del sábado y los turnos quedan apenas por debajo de su costo (0,9): no porque no mejoren, sino porque
la mejora es chica frente a construir el modelo, y a tres años probablemente sí pagan (ejercicio 4). Y el caso más valioso de todos, los
recordatorios, se cae por la regla que más proyectos mata: sin alguien que mantenga el simulador, el modelo dura lo que dura su
calibración.

**Detalles con intención**

- **Los valores anuales son supuestos**, escritos donde se pueden discutir: 4 horas de Patricia al mes, 3 000 km de moto, una silla de sesenta
  millones que no se compra. El modelo de decisión es trivial; lo que vale es que los supuestos estén a la vista.
- **`so02` vale cero por año** a propósito: una decisión de una vez no tiene valor recurrente. Su valor es la decisión misma, y se evalúa
  aparte (ejercicio 3).
- **`has_owner=False`** en el caso más valioso: el modelo de recordatorios depende de un simulador calibrado, y si nadie en Áurea sabe
  recalibrarlo, vale lo que dure la calibración. Es la regla que más proyectos de optimización mata.

---

## ⚠️ 4. Lo que se rompe

**El modelo huérfano.** Lo construye un consultor, funciona un año, cambian las reglas y nadie sabe tocarlo. Patricia vuelve a la hoja, ahora
con desconfianza. El dueño se define antes de construir.

**La mejora medida contra un mal punto de partida.** "El modelo ahorra 30 %" contra una práctica que nadie seguía de verdad infla el número.
La comparación es contra lo que se hace hoy, medido.

**El modelo que nadie entiende.** Si Patricia no puede explicar por qué el horario salió así, no lo va a defender ante las recepcionistas.
Las reglas y los pesos se escriben en palabras, con ella.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Para decisiones de una vez con mucho en juego.** La compra de una sede, un contrato de franquicia: ahí un modelo de un mes se paga aunque se
use una vez, y el criterio de "valor anual" no aplica.

**Si la casa tiene un equipo de analítica.** El costo de mantener baja mucho, y los umbrales con él.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Cambia `HOUR_COST` a la mitad y al doble. **Criterio:** qué veredictos cambian.
2. Agrega un caso de un sistema tuyo. **Criterio:** los supuestos escritos y el veredicto.

**🟡 Intermedio (3–4)**

3. Evalúa `so02` como decisión de una vez: cuánto vale decidir bien si compra una silla de sesenta millones. **Criterio:** una cuenta con sus
   supuestos.
4. Agrega al cálculo el horizonte: el valor de tres años contra el costo de tres años. **Criterio:** cómo cambian los casos con
   construcción cara.

**🟠 Difícil (5–6)**

5. Reemplaza dos supuestos por datos reales (o de una empresa que conozcas). **Criterio:** el veredicto con datos y sin ellos.
6. Agrega una probabilidad de que el modelo no se use después de un año. **Criterio:** el valor esperado, y qué caso se cae.

**🔴 Muy difícil (7–8)**

7. Escribe la propuesta de optimización de Áurea para el próximo año. **Criterio:** una página. *Rúbrica:* (a) qué problemas, en orden de
   valor; (b) quién es dueño de cada modelo; (c) cómo se mide la mejora contra lo de hoy; (d) qué se deja en la hoja a propósito.
8. Haz la autopsia de un proyecto de optimización que no se usó (tuyo o de un caso público). **Criterio:** una página. *Rúbrica:* (a) qué
   prometía; (b) por qué no se usó; (c) cuál de las señales de §2 lo habría anticipado; (d) qué habría cambiado.

---

## 📚 7. Referencias

- Michael A. Trick, sobre el uso real de la investigación de operaciones (su blog histórico, con casos): https://mat.tepper.cmu.edu/blog/

**Orden de lectura sugerido:** cualquier par de casos del blog de Trick sobre proyectos que funcionaron y que no; el resto del track tiene sus
referencias en cada sección.

---

## 🚀 8. Cierre

La optimización y la simulación pagan cuando la decisión se repite, la mejora vale y alguien puede mantener el modelo. Cuando no, la hoja de
Patricia era suficiente, y decirlo es parte del trabajo. Los supuestos de valor y de costo se escriben a la vista, y el dueño se define antes
de construir.

**La señal de que quedó bien:** *"De los seis modelos del año, construimos el que se pagaba solo, dejamos tres en la hoja con su cuenta
escrita, uno quedó en prueba, y el más valioso espera a que alguien pueda mantenerlo."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-so-fase-07 -m "op so07 cerrada: cuándo paga el modelo y cuándo bastaba la hoja"
> ```
>
> Los commits llevan su prefijo (`op so07: …`) y los de ejercicio su número
> (`op so07 ej07: …`).
