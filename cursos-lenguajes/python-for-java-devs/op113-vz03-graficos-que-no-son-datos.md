# 🧩 vz03 — Gráficos que no son datos

> Python para desarrolladores Java senior · **Carta** · Track `vz` — Visualización y gráficos ·
> sección 3 de 4
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

No toda imagen que produce un sistema es un gráfico de datos. El diagrama del cierre nocturno —qué proceso corre después de cuál, qué
lee de dónde— está en una presentación de hace un año, dibujado a mano, y ya no coincide con lo que corre: se agregaron dos pasos y
nadie actualizó el dibujo. El reporte para los franquiciados quiere un semáforo por sede (verde, amarillo, rojo según la mora), y alguien
lo arma pegando íconos.

Las dos cosas se resuelven igual: **la imagen se genera desde los datos que ya describen el sistema**. Si la lista de pasos del cierre
vive en el código del orquestador (`wf`), el diagrama sale de esa lista y nunca se desactualiza. Para eso hay tres herramientas en Python:
**Graphviz** (el lenguaje DOT, con su motor de distribución automática), **Mermaid** (texto que GitHub, GitLab y los editores dibujan
solos), y **SVG programático** con `drawsvg` para lo que no es un diagrama de cajas y flechas.

---

## 🧠 2. El modelo

| Herramienta | Versión | Qué se escribe | Quién dibuja | Para qué |
|---|---|---|---|---|
| Graphviz (`graphviz`) | 0.21 + el binario `dot` | DOT | **El binario `dot`**, con distribución automática | Grafos grandes, imagen fija (SVG, PNG, PDF) |
| Mermaid | — (es texto) | Mermaid | GitHub, GitLab, los editores, `mmdc` | **Diagramas en la documentación**, versionados con el código |
| `drawsvg` | 2.4.2 | Formas en coordenadas | Tú | Íconos, indicadores, lo que no es un grafo |
| `diagrams` | 0.25.1 | Arquitectura con íconos de nube | Graphviz por debajo | Diagramas de infraestructura |
| NetworkX | 3.7 | Grafos | Matplotlib | Analizar el grafo, no presentarlo |

La regla que ordena la tabla: **una sola fuente de verdad**. La estructura (los pasos y sus dependencias) vive en un lugar del código; el DOT y
el Mermaid se generan de ahí.

### Tu instinto de Java dice… y esta vez se equivoca

Este perfil probablemente dibuja la arquitectura en draw.io o PlantUML, a mano, y la actualiza cuando se acuerda. El instinto trata el diagrama como
documentación aparte. En Python el diagrama puede ser una salida más del sistema: el mismo dato que el orquestador usa para correr los pasos, impreso
como DOT o Mermaid.

---

## 💻 3. El ejemplo que corre

```bash
sudo apt-get install -y graphviz          # el binario dot
uv add graphviz drawsvg
```

`diagramas.py`:

```python
"""El diagrama del cierre generado desde los mismos datos que lo definen (DOT y Mermaid), y un semáforo en SVG."""

import drawsvg
import graphviz

# La definición del cierre: la misma que usaría el orquestador para correr los pasos.
STEPS = {
    "extraer_odontovia": [],
    "extraer_pasarela": [],
    "conciliar_abonos": ["extraer_odontovia", "extraer_pasarela"],
    "calcular_mora": ["conciliar_abonos"],
    "liquidar_regalias": ["conciliar_abonos"],
    "generar_reportes": ["calcular_mora", "liquidar_regalias"],
    "enviar_correos": ["generar_reportes"],
}

dot = graphviz.Digraph("cierre", graph_attr={"rankdir": "LR"}, node_attr={"shape": "box", "style": "rounded"})
for step, deps in STEPS.items():
    dot.node(step, step.replace("_", " "))
    for dep in deps:
        dot.edge(dep, step)
svg_path = dot.render("cierre", format="svg", cleanup=True)
print("Graphviz:", svg_path, "·", dot.source.count("->"), "flechas")

mermaid = ["flowchart LR"] + [f'    {d} --> {s}' for s, deps in STEPS.items() for d in deps]
print("Mermaid:\n" + "\n".join(mermaid[:4]) + "\n    …")

MORA = {"Centro": 0.02, "Suba": 0.07, "Kennedy": 0.12}             # mora de más de 90 días sobre la cartera


def light(rate: float) -> str:
    return "#2E7D32" if rate < 0.05 else "#F9A825" if rate < 0.10 else "#C62828"


canvas = drawsvg.Drawing(360, 80)
for i, (sede, rate) in enumerate(MORA.items()):
    x = 20 + i * 120
    canvas.append(drawsvg.Circle(x + 15, 30, 14, fill=light(rate)))
    canvas.append(drawsvg.Text(f"{sede} {rate:.0%}", 14, x, 70, font_family="DejaVu Sans"))
canvas.save_svg("semaforo.svg")
print("drawsvg: semaforo.svg ·", sorted({light(r) for r in MORA.values()}))
```

```bash
python3 diagramas.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Graphviz: cierre.svg · 7 flechas
Mermaid:
flowchart LR
    extraer_odontovia --> conciliar_abonos
    extraer_pasarela --> conciliar_abonos
    conciliar_abonos --> calcular_mora
    …
drawsvg: semaforo.svg · ['#2E7D32', '#C62828', '#F9A825']
```

**Detalles con intención**

- **`STEPS` es la única fuente**: el DOT y el Mermaid salen de ahí. Si se agrega un paso al cierre, los dos diagramas lo tienen en la próxima corrida.
- **`rankdir: LR`** dibuja de izquierda a derecha, que es como se lee un proceso. Graphviz decide dónde va cada caja; no hay coordenadas a mano.
- **El Mermaid es texto**: se pega en un `README.md` y GitHub lo dibuja. Para la documentación del repositorio, es mejor que una imagen, porque se
  revisa en un *pull request* como cualquier cambio.
- **`drawsvg` trabaja en coordenadas**, como un lienzo: es para lo que no es un grafo. El color lo decide una función con umbrales explícitos, no una
  persona eligiendo íconos.

---

## ⚠️ 4. Lo que se rompe

**`graphviz` sin el binario.** El paquete de Python solo escribe DOT; quien dibuja es el programa `dot`, que se instala aparte. Sin él,
`render` falla con `ExecutableNotFound: failed to execute PosixPath('dot')` —comprobado en la imagen de Python, que no lo trae—. En el contenedor del proceso, `apt-get install graphviz`.

**Mermaid que no se dibuja en todos lados.** GitHub y GitLab lo dibujan; un correo, un PDF o algunos visores de Markdown, no. Para esos, se convierte
a SVG con `mmdc` (de Node) o se usa Graphviz.

**Los nombres con espacios y tildes en Mermaid.** `Conciliar abonos --> ...` sin comillas rompe el diagrama. Los identificadores se escriben sin
espacios y las etiquetas entre comillas (`a["Conciliar abonos"]`).

**El diagrama generado que nadie mira.** Generarlo es la mitad; la otra mitad es publicarlo donde se lee (el README, el reporte). Un SVG en una carpeta de
salida no documenta nada.

---

## ⚖️ 5. Cuándo NO usarlo

**Para un diagrama conceptual que no sale de ningún dato.** "Cómo pensamos la arquitectura dentro de dos años" se dibuja a mano; no hay fuente de verdad
de la que generarlo.

**Graphviz para un diagrama de cinco cajas en un README.** Mermaid, escrito a mano o generado, es más simple y se versiona como texto.

**`drawsvg` para un gráfico de datos.** Para barras y líneas, `vz01` y `vz02`: dibujar ejes a mano es reinventar una biblioteca.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo y abre `cierre.svg` y `semaforo.svg`. **Criterio:** describes cómo distribuyó Graphviz los pasos.
2. Agrega el paso `respaldar_base` que depende de `enviar_correos`. **Criterio:** aparece en los dos diagramas sin tocar el código que dibuja.
3. Pega el Mermaid generado completo en un `README.md` de prueba en GitHub. **Criterio:** se dibuja.

**🟡 Intermedio (4–6)**

4. Colorea en el diagrama de Graphviz los pasos que fallaron en la última corrida (una lista de entrada). **Criterio:** el color sale de los datos.
5. Haz que las etiquetas de Mermaid tengan tildes y espacios. **Criterio:** el diagrama se dibuja bien en GitHub.
6. Genera el diagrama desde la definición real de un orquestador (un DAG de Airflow o los trabajos de RQ de `wf`). **Criterio:** el diagrama coincide con
   lo que corre.

**🟠 Difícil (7–9)**

7. Usa `diagrams` para dibujar la infraestructura de Áurea (servidor, base, Valkey, almacén S3). **Criterio:** la imagen y el código que la genera.
8. Detecta ciclos en `STEPS` con NetworkX antes de dibujar. **Criterio:** un ciclo agregado a propósito se reporta con los pasos involucrados.
9. Inserta el semáforo SVG en el PDF del reporte (`ui08`). **Criterio:** se ve nítido al imprimir.

**🔴 Muy difícil (10)**

10. Lleva toda la documentación visual de un sistema tuyo a "generada desde datos". **Criterio:** una página. *Rúbrica:* (a) qué diagramas se pueden
    generar y de qué fuente; (b) cuáles siguen a mano y por qué; (c) dónde se publican; (d) cómo se detecta que un diagrama a mano quedó viejo.

---

## 📚 7. Referencias

**Documentación oficial**

- `graphviz` (el paquete de Python): https://graphviz.readthedocs.io/en/stable/
- Graphviz, el lenguaje DOT: https://graphviz.org/doc/info/lang.html
- Mermaid, diagramas de flujo: https://mermaid.js.org/syntax/flowchart.html
- `drawsvg`: https://github.com/cduck/drawsvg

**Orden de lectura sugerido:** la sintaxis de diagramas de flujo de Mermaid (corta, y es la que más se usa en documentación); después la del lenguaje DOT.

---

## 🚀 8. Cierre

Los diagramas que describen un sistema se generan desde los datos que lo definen: una fuente de verdad, y DOT y Mermaid como salidas que nunca se
desactualizan. Graphviz dibuja grafos grandes con su binario `dot`; Mermaid vive en la documentación como texto; `drawsvg` dibuja lo que no es un grafo.

**La señal de que quedó bien:** *"Agregamos un paso al cierre y el diagrama del README lo tenía en el mismo pull request."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-vz-fase-03 -m "op vz03 cerrada: el diagrama del cierre generado desde su definición"
> ```
>
> Los commits llevan su prefijo (`op vz03: …`) y los de ejercicio su número
> (`op vz03 ej07: …`).
