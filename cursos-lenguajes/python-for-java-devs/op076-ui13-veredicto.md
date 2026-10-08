# ⚖️ ui13 — Veredicto: prototipo o frontend

> Python para desarrolladores Java senior · **Carta** · Track `ui` — Interfaces y entregables sin
> frontend · sección 13 de 13
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las doce anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió la escalera de entregas ([`ui01`](op064-ui01-el-modelo-y-su-costo.md)), Gradio
([`ui02`](op065-ui02-gradio.md)), Streamlit ([`ui03`](op066-ui03-streamlit.md)), Dash ([`ui04`](op067-ui04-dash.md)), las
otras cinco ([`ui05`](op068-ui05-nicegui-y-compania.md)), marimo ([`ui06`](op069-ui06-marimo.md)), las presentaciones
([`ui07`](op070-ui07-presentaciones.md)), los reportes ([`ui08`](op071-ui08-reportes.md)), el escritorio
([`ui09`](op072-ui09-escritorio.md)) y la terminal ([`ui10`](op073-ui10-cli-mas-alla-de-argparse.md),
[`ui11`](op074-ui11-rich-e-interaccion.md), [`ui12`](op075-ui12-textual.md)).

La pregunta que queda es la del título, y es la que más dinero cuesta si se responde tarde: **¿cuándo lo que se hizo sin
frontend es un prototipo que hay que reemplazar, y cuándo es la solución?** La tentación es doble. Por un lado, una aplicación
de Streamlit que funciona se queda para siempre aunque ya no alcance. Por el otro, el instinto de este perfil —que viene de
proyectos con frontend— llama "juguete" a lo que para Patricia es exactamente lo que necesita.

---

## 🧠 2. El modelo

| Señal | Qué significa | Hacia dónde mueve |
|---|---|---|
| Lo usa una persona interna, unas veces por semana | El caso para el que existe el track | Archivo o aplicación de datos |
| Lo usan personas de fuera (pacientes, el público) | Diseño, accesibilidad, seguridad de cara a internet | **Frontend** |
| Más de unas decenas de usuarios a la vez | El estado por sesión en el servidor empieza a pesar | Dash (sin estado) o frontend |
| Marcela pide un diseño que la biblioteca no permite | El límite del dibujo generado | Frontend, o aceptar el límite |
| Se necesita sin red o con hardware local | La web no llega | Escritorio (`ui09`) o agente local |
| Lo consume otro programa | No es una interfaz para personas | CLI con `--json` o API |
| Nadie lo usa interactivamente: se mira y se archiva | No necesita servidor | Archivo (`ui08`) |

Y la regla de cierre: **una entrega sin frontend es la solución mientras sus usuarios sean internos y pocos, y el diseño sea
negociable.** Cuando cambia una de las tres cosas, es un prototipo que ya cumplió su función: demostró qué se necesitaba.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `escalon.py` convierte la tabla en una función, y la aplica a las entregas reales de Áurea.

```python
"""¿Qué escalón? La tabla del veredicto como función, aplicada a las entregas de Áurea."""

from dataclasses import dataclass


@dataclass
class Need:
    name: str
    external_users: bool = False       # pacientes, público
    concurrent_users: int = 1
    interactive: bool = True           # ¿alguien elige, filtra, escribe?
    consumer_is_program: bool = False
    design_negotiable: bool = True
    needs_local_hardware: bool = False


def rung(n: Need) -> str:
    if n.consumer_is_program:
        return "CLI con --json o API (ui10)"
    if n.external_users:
        return "frontend: fuera del alcance de este track"
    if n.needs_local_hardware:
        return "escritorio o agente local (ui09)"
    if not n.interactive:
        return "archivo: PDF o Excel (ui08)"
    if not n.design_negotiable:
        return "frontend, o negociar el diseño"
    if n.concurrent_users > 30:
        return "Dash, sin estado en el servidor (ui04)"
    return "aplicación de datos: Streamlit o Gradio (ui02, ui03)"


NEEDS = [
    Need("Reporte mensual de cartera", interactive=False),
    Need("Calculadora de mora de Patricia"),
    Need("Tablero de cartera de la red", concurrent_users=12),
    Need("Agendamiento en línea para pacientes", external_users=True, concurrent_users=200),
    Need("Lectura del datáfono de la sede", needs_local_hardware=True),
    Need("Resultado del cierre para el cron", consumer_is_program=True),
    Need("Tablero de Marcela con la marca exacta", design_negotiable=False),
]
for n in NEEDS:
    print(f"{n.name:<40} → {rung(n)}")
```

```bash
python3 escalon.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Reporte mensual de cartera               → archivo: PDF o Excel (ui08)
Calculadora de mora de Patricia          → aplicación de datos: Streamlit o Gradio (ui02, ui03)
Tablero de cartera de la red             → aplicación de datos: Streamlit o Gradio (ui02, ui03)
Agendamiento en línea para pacientes     → frontend: fuera del alcance de este track
Lectura del datáfono de la sede          → escritorio o agente local (ui09)
Resultado del cierre para el cron        → CLI con --json o API (ui10)
Tablero de Marcela con la marca exacta   → frontend, o negociar el diseño
```

Siete entregas, cinco respuestas distintas, y solo una de ellas es "frontend". La de Marcela es la más interesante, porque la
respuesta no es técnica: es una conversación sobre si el color exacto de la barra vale un segundo código y alguien que lo
mantenga.

**Detalles con intención**

- **El orden de los `if` es el veredicto.** Que lo consuma un programa decide antes que nada; que haya usuarios de fuera decide
  antes que la cantidad de usuarios internos. Cambiar el orden es cambiar la política, y por eso está a la vista.
- **El umbral de 30 usuarios concurrentes es una suposición** de esta sección, no una medida: el número real sale de medir la
  memoria por sesión (ejercicios de `ui03` y `ui05`) en el servidor de Áurea.
- **No hay "Reflex" ni "NiceGUI" en las respuestas**: son alternativas dentro del escalón de aplicación de datos, y se eligen con
  la medición de `ui05`, no con esta tabla.

---

## ⚠️ 4. Lo que se rompe

**El prototipo que se queda.** Una aplicación de Streamlit hecha "para probar" pasa a producción sin autenticación, sin pruebas
y sin dueño. La señal para revisar es concreta: la primera vez que la usa alguien que no la pidió.

**El frontend prematuro.** El instinto de este perfil: un proyecto de React para la calculadora de mora de una persona. Seis
semanas, dos códigos, y Patricia sigue calculando a mano mientras tanto.

**La entrega que nadie le preguntó a la usuaria.** Toda la tabla supone que se sabe qué hace la persona con el resultado. La
pregunta de `ui01` —"¿qué haces con esto después?"— va antes que el código.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Si la casa tiene equipo de frontend.** Las filas cambian: el frontend deja de ser caro, y las aplicaciones de datos pasan a ser
prototipos rápidos que ese equipo reemplaza.

**Para productos.** Si lo que se construye se vende o lo usa el público, la tabla entera es la primera fila.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega tres entregas de un sistema tuyo a `NEEDS`. **Criterio:** la salida, y si estás de acuerdo con cada una.
2. Cambia el orden de dos `if` y corre. **Criterio:** qué entrega cambia de escalón y por qué.

**🟡 Intermedio (3–4)**

3. Agrega la señal "tiene que funcionar sin red" como campo propio. **Criterio:** una entrega de prueba que caiga en escritorio
   por esa razón.
4. Escribe las pruebas de `rung` con un caso por fila de la tabla de §2. **Criterio:** siete casos, todos pasan.

**🟠 Difícil (5–6)**

5. Mide la memoria por sesión de la aplicación de `ui03` en tu máquina y reemplaza el umbral de 30 por uno medido.
   **Criterio:** el número y cómo lo calculaste.
6. Haz la conversación con Marcela por escrito: el costo de un frontend para su tablero contra lo que permite la biblioteca.
   **Criterio:** horas estimadas de cada opción y la recomendación.

**🔴 Muy difícil (7–8)**

7. Escribe la política de entregas de Áurea. **Criterio:** una página. *Rúbrica:* (a) el escalón por defecto; (b) las señales que
   obligan a revisarlo; (c) quién es dueño de cada aplicación de datos y cómo se da de baja; (d) cuándo se contrata frontend.
8. Audita las aplicaciones sin frontend de un equipo real. **Criterio:** una tabla. *Rúbrica:* (a) cada una con su escalón actual
   y el que le corresponde; (b) cuáles son prototipos que se quedaron; (c) el riesgo de cada una; (d) un plan para las tres más
   urgentes.

---

## 📚 7. Referencias

- Martin Fowler, *Sacrificial Architecture*: https://martinfowler.com/bliki/SacrificialArchitecture.html

**Orden de lectura sugerido:** el ensayo de Fowler, que dice algo que este track supone: a veces lo correcto es construir algo
sabiendo que se va a tirar. El resto del track tiene sus referencias en cada sección.

---

## 🚀 8. Cierre

Una entrega sin frontend es la solución mientras sus usuarios sean internos y pocos y el diseño se pueda negociar. Cuando cambia
una de las tres, cumplió su función de prototipo. Antes de subir un escalón se pregunta qué hace la persona con el resultado, y
muchas veces la respuesta es un archivo.

**La señal de que quedó bien:** *"Pusimos las siete entregas de Áurea en la tabla y solo una necesitaba frontend; las otras seis
ya estaban resueltas."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ui-fase-13 -m "op ui13 cerrada: la escalera de entregas como política y cuándo llamar al frontend"
> ```
>
> Los commits llevan su prefijo (`op ui13: …`) y los de ejercicio su número
> (`op ui13 ej07: …`).
