# 📊 ds05 — Visualización, y cuándo una tabla gana

> Python para desarrolladores Java senior · Track `ds` · sección 5 de 9
> Depende de: `ds04` · Habilita: `ds06`
> Registro de esta sección: script — un archivo por figura, ejecutado a mano
> Proyecto que avanza: Embudo — nace su tablero

---

## 🎯 1. Propósito

`ds04` terminó con una banda: el costo por paciente adquirido está entre 1,06 y 7,96
millones según quién se lleve el mérito. Ahora hay que presentarlo, y ahí aparece la
tentación de la que trata esta sección: **un gráfico de barras con una cifra por canal se ve
mucho mejor que una tabla con una banda, y es exactamente la mentira que acabamos de
desmontar**.

Al terminar sabes producir el mismo tablero en las tres bibliotecas que importan, sabes
cuánto cuesta cada una, y —lo que de verdad se lleva el lector— sabes cuándo **no** hacer un
gráfico.

> 🧭 **La regla que ordena la sección: si el dato tiene incertidumbre, el dibujo la muestra o
> el dibujo miente.** Vale igual para una barra, para una línea y para una tabla. Todo lo
> demás —qué biblioteca, qué colores, qué formato— es secundario y se decide midiendo.

---

## ✅ 2. Qué queda listo al terminar

- [ ] El mismo tablero existe en cuatro versiones —tabla, matplotlib, plotly y altair— y las
      cuatro muestran la banda de `ds04`, no solo el punto.
- [ ] `palette.py` calcula el contraste de la paleta de Áurea y dice para qué sirve cada
      color, con el número al lado.
- [ ] Sabes por qué el dorado de la marca no puede llevar texto encima y sí puede ser una
      barra, y puedes decírselo a Marcela sin que suene a capricho.
- [ ] Comprobaste que la paleta completa **no sobrevive a una impresión en blanco y negro**,
      y sabes qué haces con eso.
- [ ] `bench_render.py` produce la tabla de la sección 6 en tu máquina, con cada opción en su
      propio entorno.
- [ ] Puedes defender, con dos números, cuándo la tabla de texto es la respuesta correcta.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Cuadernos** → `ds06`, que va a medir cuántos de los que produzcas aquí vuelven a correr.
- **Tableros con servidor** —Dash, Streamlit, Panel, marimo como aplicación— → track `ui` a
  la carta. Aquí se produce un archivo: PNG o HTML estático. La diferencia no es de
  biblioteca, es de registro: un servidor es una aplicación y hay que operarla.
- **Mapas, redes y grafos** → fuera del curso. Áurea tiene diez sedes en una ciudad; un mapa
  aquí es decoración, y decirlo es parte de la sección.
- **La gramática de gráficos completa** —facetas, escalas compuestas, transformaciones— →
  fuera del curso. Se usa lo que hace falta para un tablero de siete cifras.
- **Animación y `plotly.express`** → fuera. `express` es cómodo y esconde lo que hace; para
  aprender el modelo conviene ver el objeto que se construye.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

El comité de franquicia dura cuarenta minutos y el Embudo tiene **siete cifras**: tres
canales por su banda, más el total. Marcela pide "un gráfico". La pregunta que hay que
hacerse antes de abrir cualquier biblioteca es **para qué**, porque hay tres respuestas
distintas y cada una lleva a una herramienta distinta:

- **Para que alguien decida algo en la reunión** → los valores exactos importan, van a
  citarse en voz alta, y se comparan con los del mes pasado. Eso es una tabla.
- **Para que alguien vea una forma** —una estacionalidad, una caída, una cola larga— → eso es
  un gráfico, y la forma es el dato.
- **Para que alguien explore** —abrir, filtrar, pasar el ratón, preguntarse— → eso es
  interactivo, y tiene el costo de que alguien lo mantenga.

Casi todo el mundo pide lo primero y construye lo tercero.

### Las tres bibliotecas, en una frase cada una

**matplotlib** dibuja: le dices dónde va cada cosa y produce una imagen. Es la más antigua,
la más verbosa y la única que produce algo que se pega en un correo y se ve sin navegador.

**plotly** produce HTML con JavaScript: el resultado es interactivo, se pasa el ratón y sale
el valor. El precio está en el archivo, y es una decisión de una línea que la sección 6 mide.

**altair** no dibuja nada: produce una **especificación** de Vega-Lite —un JSON— que otro
programa dibuja. Describes el mapeo de datos a canales visuales y el motor decide el resto.
Es lo más cercano a SQL que hay en visualización, y le pasa lo mismo que a SQL: es una
maravilla mientras no necesites algo muy específico.

```python
# Las tres, sobre los mismos datos, en su forma más corta.
axes.barh(channels, points, xerr=[lower, upper])            # matplotlib: dibuja
go.Bar(x=points, y=channels, error_x={...})                 # plotly: objeto → HTML
alt.Chart(rows).mark_bar().encode(x="lineal:Q", y="canal:N")  # altair: mapeo → spec
```

### Tu instinto de Java dice… y esta vez se equivoca

Tu instinto dice **"esto es la capa de presentación, va al final y es lo fácil"**. Es
razonable: en once años de backend, el gráfico lo hizo siempre otro, en el frontend, con una
biblioteca que tú no elegiste.

Aquí eso falla por dos razones, y la segunda es la cara.

La primera es técnica y muerde el primer día:

```python
# ❌ El reflejo. En tu portátil funciona; en el servidor que corre la tarea del lunes, no.
import matplotlib.pyplot as plt
figure.savefig("tablero.png")
```

matplotlib elige un backend al importarse, y si cree que hay pantalla intenta usarla. En una
máquina sin entorno gráfico —todas las que corren tareas programadas— eso falla con un error
que no menciona la palabra "pantalla".

```python
# ✅ Se decide explícitamente, antes de importar pyplot.
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
```

La segunda razón es la que importa: **la presentación no es la capa final, es donde se
pierde la información**. Todo el trabajo de `ds04` —los cuatro modelos, los intervalos, la
madurez— cabe en una tabla y **no cabe en un gráfico de barras simple**. Elegir el gráfico
simple no es una decisión estética: es tirar el hallazgo.

### La legibilidad se mide, no se opina

Marcela va a rechazar un tablero por el color de una barra. Tiene razón en que la marca es
suya, y tú tienes una herramienta que ella no espera: **el contraste es aritmética**.

```python
def contrast_ratio(foreground: str, background: str = "#FFFFFF") -> float:
    """De 1 (idénticos) a 21 (negro sobre blanco)."""
    lighter, darker = sorted((relative_luminance(foreground),
                              relative_luminance(background)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)
```

Los umbrales llevan años escritos en las pautas de accesibilidad: **4,5:1 para texto normal**
y **3:1 para texto grande y elementos de interfaz**. Sobre la paleta de Áurea, con fondo
blanco:

| Color | Contraste | ¿Texto? | ¿Barra? |
|---|---|---|---|
| carbón `#2B2B2B` | 14,16 | sí | sí |
| pizarra `#4A6670` | 6,13 | sí | sí |
| teja `#A34E2A` | 5,71 | sí | sí |
| **dorado `#B8860B`** | **3,25** | **no** | **sí** |
| arena `#E8DCC4` | 1,36 | no | no |

> 💡 **La frase que termina la discusión, y no es una concesión:** *"el dorado es el color de
> la marca y va en las barras, que es donde se ve. En el texto no pasa el contraste —3,25
> contra el 4,5 que exige la norma— y ahí va el carbón, que es 14,16."* Nadie discute un
> número, y la marca sigue en el gráfico.

### Esto sí funciona igual

- **Separar el cálculo de la presentación.** Es la misma disciplina de siempre, y aquí paga
  doble: la tabla y las tres figuras consumen exactamente el mismo diccionario.
- **Los artefactos se versionan y pesan.** Un PNG en el repositorio es un binario que crece
  en cada commit, igual que cualquier otro.
- **Elegir dependencias con criterio.** Lo de `ds03` sigue vigente: importar matplotlib
  cuesta 430 ms, y eso se paga en cada invocación.
- **Los valores por defecto no son decisiones.** El backend, la paleta y el DPI vienen
  puestos por alguien que no conocía tu caso.

### Autopsia: el gráfico que se ve mejor y dice menos

El tablero que Marcela habría pedido es una barra por canal con su cifra. Sobre los datos de
`ds04`, ese gráfico dice que TikTok cuesta 1,93 millones y Google 2,01: **prácticamente lo
mismo, TikTok un poco mejor**.

El mismo dato, con su banda, dice que TikTok está entre 1,06 y 7,96 y Google entre 1,55 y
2,76. La conclusión cambia entera: **de Google y TikTok son equivalentes** a **sobre Google
sabemos bastante y sobre TikTok no sabemos casi nada**.

El "antes y después" no es de milisegundos: es de decisión. La versión bonita habría llevado
al comité a repartir el presupuesto a partes iguales con confianza; la versión con banda
lleva a la conversación correcta, que es que hace falta un experimento.

### Diccionario de traducción

| Lo que sabes | Aquí | Dónde se rompe el paralelo |
|---|---|---|
| Capa de presentación | la figura | No es la última capa: es donde se pierde información si eliges mal |
| Plantilla del lado del servidor | matplotlib | La plantilla produce texto; matplotlib produce píxeles y los píxeles no se pueden citar |
| SPA con su framework | plotly · altair | Igual en que el navegador dibuja. Distinto en que aquí no hay estado ni rutas: es un archivo |
| Declarativo (SQL, JPQL) | altair | Buen paralelo: describes qué quieres. Y se rompe igual: cuando necesitas algo muy específico, peleas con el motor |
| Un `logger` configurado | `matplotlib.use("Agg")` | Los dos son "elige el backend antes de usarlo", y los dos fallan tarde si no lo haces |
| Tema de la marca | paleta con contraste medido | El tema es una preferencia; el contraste es un umbral numérico |

> 📝 **Nota de ecosistema.** Las tres bibliotecas de esta sección conviven porque resuelven
> problemas distintos, y llevan años haciéndolo: matplotlib es de 2003 y sigue siendo lo que
> hay debajo de casi todo lo demás en Python —incluido lo que dibuja pandas con `.plot()`—;
> plotly y altair nacieron para el navegador y no compiten con ella, la complementan. Si
> alguien te dice que una "reemplazó" a otra, probablemente esté comparando la comodidad de
> su API con la potencia de la otra.

---

## 💻 5. Código mínimo con comentarios

Registro **script**: un archivo por figura, `uv run`, sin capas. La dependencia entra por
figura y no de a bloque — es la sección donde más fácil se acumulan tres bibliotecas para
hacer una cosa.

```bash
uv run --with matplotlib==3.11.2 python -c "from dashboard import as_matplotlib; as_matplotlib()"
```

### 5.1 Un solo dato, cuatro presentaciones

```python
# src/ds05-visualizacion/dashboard.py

# canal: (mínimo entre modelos, lineal, máximo entre modelos)
AUREA_CAC = {
    "tiktok": (1.06, 1.93, 7.96),
    "instagram": (1.14, 1.74, 3.35),
    "google": (1.55, 2.01, 2.76),
}
```

Los tres valores por canal son el contrato de la sección: **ninguna de las cuatro
presentaciones puede dibujar solo el del medio**. Hay una prueba que lo exige para la tabla,
y el ejercicio 7 pide escribirla para las otras tres.

### 5.2 La tabla, que es el competidor de verdad

```python
def as_table(data=AUREA_CAC) -> str:
    lines = [TITLE, SUBTITLE, "",
             f"{'canal':<12}{'mínimo':>10}{'lineal':>10}{'máximo':>10}{'banda':>10}"]
    for channel, (low, point, high) in sorted(data.items(), key=lambda item: -item[1][1]):
        lines.append(f"{channel:<12}{low:>9.2f}M{point:>9.2f}M{high:>9.2f}M"
                     f"{high / low:>9.1f}×")
    return "\n".join(lines)
```

Seis líneas, cero dependencias, 0,35 KB de salida:

```
Costo por paciente adquirido · Áurea · corte 2026-03-31
Punto: atribución lineal. Banda: el mínimo y el máximo entre los cuatro modelos.

canal           mínimo    lineal    máximo     banda
google           1.55M     2.01M     2.76M      1.8×
tiktok           1.06M     1.93M     7.96M      7.5×
instagram        1.14M     1.74M     3.35M      2.9×
```

La columna `banda` no está en ninguna de las tres figuras y es la que contesta la pregunta
del comité. Ese es el argumento entero de la sección, y está en la cuarta columna de un
bloque de texto.

### 5.3 matplotlib, con sus dos trampas

```python
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    ...
    # Las barras de error van como distancias al punto, no como límites absolutos. Es el
    # error más común de la API y produce una banda espejada que parece correcta.
    lower = [data[channel][1] - data[channel][0] for channel in channels]
    upper = [data[channel][2] - data[channel][1] for channel in channels]
    axes.barh(channels, points, xerr=[lower, upper], ...)
```

**Detalles con intención**

- **`use("Agg")` antes de importar `pyplot`**, no después: el backend se fija al importar.
- **`xerr` son distancias**, no los extremos. Pasarle `[1.06, 7.96]` produce un gráfico que
  se dibuja sin quejarse y está mal: es el error silencioso de esta sección.
- **El subtítulo va en la figura**, no en el correo que la acompaña. Una imagen se reenvía
  sola, y sin el subtítulo la banda no se sabe qué es.

### 5.4 plotly, y la decisión de una línea

```python
    figure.write_html(target, include_plotlyjs="cdn")
```

Con `"cdn"`, el archivo pesa **9,4 KB** y necesita internet para dibujarse. Con `True`, pesa
**4,10 MB** y funciona en un avión. **435 veces**, por un argumento. No hay respuesta
correcta: hay que saber a quién se lo mandas.

### 5.5 El experimento que rompe a propósito: imprime el tablero

Marcela lleva el tablero impreso al comité, en blanco y negro, porque la impresora de la sede
de Suba es así. Esto es lo que le queda de la paleta:

```python
def to_grayscale(color: str) -> str:
    """El mismo color en gris, por luminancia. Para ver qué queda al imprimir."""
    level = round(relative_luminance(color) ** (1 / 2.2) * 255)
    return f"#{level:02X}{level:02X}{level:02X}"
```

| Color | En pantalla | Impreso |
|---|---|---|
| dorado | `#B8860B` | `#8D8D8D` |
| teja | `#A34E2A` | `#666666` |
| pizarra | `#4A6670` | `#626262` |

**Teja y pizarra son el mismo gris**: su contraste entre sí, impresos, es de 1,04. En
pantalla son dos colores obviamente distintos —un terracota y un azul grisáceo— y en el papel
del comité son una sola serie. La paleta completa de cinco colores **no sobrevive a la
impresión**, y hay una prueba que lo afirma.

La salida no es renunciar al color: es **separar por luminancia** —no por tono— cuando el
gráfico vaya a imprimirse, o usar menos series.

**El patrón a memorizar**
> Antes de elegir biblioteca, contesta tres preguntas: ¿esto es para decidir, para ver una
> forma o para explorar?, ¿lo va a abrir alguien sin internet?, y ¿se va a imprimir? Las
> tres respuestas juntas eligen la herramienta; ninguna de las tres es sobre rendimiento.

**Prueba de fuego**

```bash
uv run --with pytest --with matplotlib==3.11.2 --with plotly==7.0.0 --with altair==6.2.2 \
       pytest test_dashboard.py -q
```

Quince pruebas. Las de la paleta **no necesitan ninguna biblioteca de gráficos**: el
contraste es aritmética y se puede exigir en CI aunque la máquina no tenga con qué dibujar.

La mentira que te va a contar la salida si miras el lugar equivocado: la tabla de la sección
6 dice que la tabla de texto es mil veces más liviana y quince veces más rápida. Es cierto y
**no es el argumento**. El argumento es que la tabla cabe la banda y el gráfico de barras
no; si el dato fuera una serie de veintisiete meses, la tabla perdería y perdería fuerte.

---

## 📏 6. Medición

### 6.1 Lo que cuesta producir el mismo tablero

**Hipótesis.** Que las tres bibliotecas cuestan bastante más que la tabla en las cuatro
dimensiones que importan —tiempo en frío, memoria, peso del artefacto y líneas de código— y
que la diferencia entre ellas es menor que la diferencia con no usar ninguna.

**Condiciones.** CPython 3.14.5, matplotlib 3.11.2, plotly 7.0.0, altair 6.2.2; macOS
26.6.2 sobre Apple Silicon de 8 núcleos. El mismo tablero: tres canales con su banda. Cinco
repeticiones para el render con la biblioteca ya cargada; cinco procesos nuevos para el
tiempo en frío. **Cada opción se mide en un entorno donde solo está instalada su
dependencia**, por lo que descubrió `ds03`.

**Competidores.** Las tres bibliotecas y la tabla de texto. La tabla no es un hombre de paja
al revés: produce la misma información —más una columna— y es lo que Marcela va a pegar en el
correo de todos modos.

| Opción | Render | En frío | Pico RSS | Artefacto | Líneas |
|---|---|---|---|---|---|
| **tabla de texto** | **0,07 ms** | **30 ms** | **23 MB** | **0,35 KB** | **6** |
| altair | 9,7 ms | 275 ms | 108 MB | 2,3 KB | 13 |
| plotly | 14,6 ms | 193 ms | 111 MB | 9,4 KB | 15 |
| matplotlib | 57,5 ms | 457 ms | 113 MB | 29,3 KB | 18 |

Y el mismo HTML de plotly con la biblioteca embebida en vez de traída de un CDN:
**4,10 MB**, 435× el de la fila.

```bash
uv run python bench_render.py --opcion tabla
uv run --with matplotlib==3.11.2 python bench_render.py --opcion matplotlib
```

> ⚖️ **Veredicto.** **Para las siete cifras del comité de franquicia, la tabla gana.** No por
> los 30 milisegundos —a nadie le importan— sino por tres cosas que sí: cabe **la columna de
> la banda**, se pega en un correo sin adjuntos, y se compara con la del mes pasado con un
> `diff`. Las tres son requisitos reales de Marcela y ninguna de las tres figuras las cumple.
>
> **Entre las tres bibliotecas, la elección es por destino y no por rendimiento:**
> matplotlib es la única que produce algo visible sin navegador —y cuesta el doble de tiempo
> en frío que plotly—; altair produce el archivo más chico y la especificación más legible de
> revisar en un pull request; plotly es el más cómodo para explorar. Las diferencias de
> tiempo entre ellas (193 a 457 ms en frío) son irrelevantes para algo que se genera una vez
> al mes, y decisivas si alguna vez esto entra a un endpoint.
>
> **El umbral, dicho como criterio:** la tabla gana mientras el dato quepa en una pantalla y
> lo que importe sean los valores. En cuanto la pregunta sea *"¿esto sube o baja?"* sobre
> veintisiete meses, la tabla pierde y no está cerca — y ese es el tablero que `ds04` no
> pidió y que el ejercicio 21 sí construye.

### 6.2 Tiempo hasta la primera decisión correcta

**Esta es la medición que de verdad importa y no está hecha**, porque necesita personas.
Queda especificada entera para que alguien la corra:

**Hipótesis.** Que sobre la misma información —las tres cifras con su banda— el tiempo hasta
que alguien contesta correctamente *"¿en qué canal confías menos?"* es **menor con la tabla**
que con el gráfico de barras, y que el interactivo es el más lento porque invita a explorar
antes de responder.

**Protocolo.** Cinco personas del entorno del lector, con perfil de negocio y sin conocer los
datos. A cada una se le muestran las tres presentaciones **en orden distinto** —para que el
aprendizaje no favorezca siempre a la misma— y se le hace la misma pregunta. Se mide el
tiempo hasta la primera respuesta y si es correcta. Sin ayuda, sin explicar la banda.

**Cómo se reporta.** Mediana y rango por presentación, con el número de aciertos. **Y con la
advertencia delante: son cinco personas, eso es anecdótico, y lo único interpretable es el
orden de magnitud.** Si las tres medianas caen dentro de unos segundos, el resultado es que
no hay diferencia y también se publica.

| Presentación | Tiempo hasta la respuesta | Aciertos |
|---|---|---|
| Tabla de texto | ⏳ | ⏳ |
| Barras con banda | ⏳ | ⏳ |
| Interactivo | ⏳ | ⏳ |

> 📝 **Por qué se publica vacía en vez de omitirla.** Es la misma razón por la que
> `BENCHMARKS.md` lista las mediciones pendientes del track de IA: un documento que solo
> muestra lo medido esconde cuánto falta. Y esta, en particular, es la única del track que no
> se puede hacer con un portátil — lo que dice algo sobre qué clase de preguntas contesta un
> benchmark.

---

## 🧱 7. Miniproyecto — La página que Marcela imprime

**El encargo.** Marcela te escribe: *"Del comité salgo con la hoja rayada de anotaciones. Lo
que necesito es **una** página, que pueda imprimir en la impresora de Suba que es en blanco y
negro, con el embudo del trimestre y el costo por canal. Y que la del trimestre pasado se
vea igual, para poder ponerlas una al lado de la otra."*

**Por qué duele.** Porque son tres requisitos que pelean entre sí: **una** página obliga a
elegir qué entra; **blanco y negro** elimina el color como codificación, que es la primera
herramienta que uno usa; y **comparable entre trimestres** obliga a fijar las escalas, que es
lo que ninguna biblioteca hace por defecto —cada figura se autoescala a sus datos, y dos
figuras autoescaladas no se pueden comparar aunque se vean igual—.

**Datos de entrada.** El conjunto del Embudo y los módulos de `ds04`. Genera el trimestre
actual (2026-01 a 2026-03) y el anterior (2025-10 a 2025-12) con el recorte de
`ds03/preparar_tamanos.py`. El caso sucio: **en el trimestre anterior hay un canal con menos
de treinta adquisiciones**, y su banda es enorme. Decide si aparece, y con qué advertencia.

**Criterios de aceptación.**

1. `python pagina.py --trimestre 2026-Q1 --salida pagina.png` produce **un** archivo, de una
   página, imprimible en vertical.
2. La página se lee **en escala de grises**: una prueba convierte la imagen a gris y verifica
   que las series siguen distinguiéndose. Si usas color, es adorno y no codificación.
3. Las escalas de los ejes **no se autoescalan**: salen de un rango fijo que declaras, y la
   página del trimestre anterior usa el mismo. Compruébalo generando las dos y comparando los
   límites.
4. Toda cifra con menos de treinta casos detrás lleva su advertencia **en la página**, no en
   el correo.
5. La banda entre modelos de atribución aparece. Si decides que no cabe, tienes que
   reemplazarla por algo que diga lo mismo y justificarlo en tres líneas.
6. `--formato png|txt` produce las dos versiones desde el mismo cálculo, y los dos coinciden
   en las cifras. Una prueba lo verifica.

**Restricciones de registro.** Script: un archivo, `argparse`, una sola biblioteca de
gráficos —la que elijas, con su justificación en el README—. Nada de servidores.

**La trampa.** El criterio 3. Vas a generar la página del trimestre actual, se va a ver muy
bien, y vas a generar la del anterior sin mirar los ejes. Las dos van a verse igual de bien y
**van a mentir al ponerlas una al lado de la otra**, porque una barra del mismo largo va a
significar cifras distintas. Es el error de comparación más común que existe en visualización
y no produce ningún aviso.

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

Una página imprimible es un lienzo de tamaño fijo con un presupuesto de espacio. Empieza por
decidir el tamaño en pulgadas y el DPI, y verás enseguida cuánto cabe. Todo lo demás se
acomoda a eso.
</details>

<details><summary>Pista 2 — la herramienta</summary>

En matplotlib, `figsize` y `dpi` en `subplots`, `set_xlim`/`set_ylim` para fijar escalas, y
`subplots` con varios ejes para poner el embudo y el costo en la misma página.
[matplotlib.org/stable/users/explain/axes/axes_scales.html](https://matplotlib.org/stable/users/explain/axes/axes_scales.html)
Para codificar sin color, mira `hatch`.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def page(quarter: str, limits: dict[str, tuple[float, float]]) -> "Figure": ...
def funnel_panel(axes, data) -> None: ...
def cost_panel(axes, data, limits) -> None: ...
def as_text(quarter: str) -> str: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-05 -m "Mini ds05: página del comité · <biblioteca> · escalas fijas <rango>"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Calcula el contraste del dorado sobre el arena, que es la combinación que Marcela va a
   proponer. Decide si sirve para texto y prepara la frase con la que se lo dices.
2. Genera el tablero en las tres bibliotecas y compara los tres archivos. Ábrelos sin
   internet y anota cuáles siguen funcionando.
3. Pásale a `xerr` los extremos absolutos en vez de las distancias. El gráfico se dibuja: di
   qué está mal en él sin mirar el código.
4. Quita `matplotlib.use("Agg")` y ejecuta el script por SSH o en un contenedor. Guarda el
   error, que es de los que uno quiere reconocer rápido.
5. Convierte la paleta a gris y encuentra tú las dos que colisionan, sin mirar la sección 5.5.
6. Cambia `include_plotlyjs` a `True` y mide el archivo. Decide a quién le mandarías cada
   versión.

**🟡 Intermedio (7–14)**

7. Escribe la prueba que exige que **las tres figuras** muestren la banda, no solo la tabla.
   Pista: en altair es fácil —la especificación es JSON—, en las otras dos no.
8. Añade a la paleta un color que sí pase 4,5:1 y que se distinga de los demás impreso.
   Justifica la elección con los dos números.
9. Reproduce la tabla de la sección 6.1 en tu máquina, con cada opción en su entorno. Si
   alguna relación se invierte, ese es el hallazgo.
10. Mide el tiempo en frío de matplotlib con y sin `matplotlib.use("Agg")`. La diferencia te
    dice cuánto cuesta el backend que no vas a usar.
11. Haz el mismo tablero con `pandas.DataFrame.plot()`. Mide, y explica por qué el número se
    parece tanto al de matplotlib.
12. La especificación que produce altair es un JSON. Ábrelo, cámbiale el color de la barra a
    mano, y vuelve a abrirlo en el navegador. Eso es lo que significa "declarativo".
13. Genera el tablero con una serie de veintisiete meses en vez de tres canales. Ahora haz la
    tabla equivalente. Escribe en cinco líneas cuál gana y por qué.
14. Mide el peso del PNG a 72, 150 y 300 DPI, y mira cuál hace falta para que se lea impreso.

**🟠 Difícil (15–21)**

15. Diagnóstico: te pasan un gráfico donde el eje y empieza en 1,5 en vez de 0 y las barras
    de TikTok y Google parecen diferir 4×. Reprodúcelo, y escribe la regla que usarías para
    decidir cuándo truncar un eje es legítimo.
16. El gráfico de barras con banda de esta sección usa una escala lineal, y la banda de
    TikTok es 7,5×. Prueba con escala logarítmica y decide cuál publicarías para el comité.
    Las dos son defendibles y la conversación es el ejercicio.
17. Implementa el tablero de forma que las tres figuras y la tabla salgan del **mismo**
    objeto de datos con una sola función de formato. Mide cuántas líneas ahorras y decide si
    valió la pena.
18. **De registro.** El tablero pasa a generarse cada noche y a publicarse en una carpeta
    compartida. ¿Sigue siendo un script? Decide con el costo de las otras dos opciones.
19. Toma la figura de matplotlib y hazla accesible de verdad: contraste comprobado, etiquetas
    con los valores, y un texto alternativo. Después mide cuántas líneas agregó.
20. Diseña la versión de una sola cifra: si el comité solo pudiera ver **un** número del
    Embudo, ¿cuál? Defiéndelo, y escribe la advertencia que lo acompaña.
21. Construye el tablero de estacionalidad —índice mensual de `ds04`, dos series— y compáralo
    con su tabla. Este es el caso donde el gráfico gana: demuéstralo.

**🔴 Muy difícil (22–25)**

22. **Corre la medición 6.2.** Cinco personas, el protocolo está escrito. Publica los
    números con su advertencia, aunque salga que no hay diferencia. Es la contribución más
    valiosa que puede hacerle alguien a esta sección.
23. **Defiende lo contrario.** Construye el caso de Áurea donde el tablero interactivo es la
    respuesta correcta y la tabla es un error. Existe, y tiene que ver con quién pregunta y
    cuántas veces.
24. 🔥 Escribe el mismo tablero en Vega-Lite a mano, sin altair, y compáralo con la
    especificación que genera la biblioteca. Explica qué te ahorró y qué te escondió.
25. **De registro.** Marcela pide que el tablero se pueda ver en el celular durante el comité.
    Decide entre PNG, HTML estático y aplicación, con el costo de operar cada uno y la tabla
    de la sección 6 en la mano.

**🔥 Opcionales**

- Mira qué hace `matplotlib.pyplot.style.use("ggplot")` y decide si un tema prestado es una
  decisión o una renuncia.
- Genera el tablero en SVG en vez de PNG y compara el peso y la nitidez al imprimir.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://matplotlib.org/3.11.2/users/explain/figure/backends.html](https://matplotlib.org/3.11.2/users/explain/figure/backends.html)
  — los backends y por qué hay que elegirlos. La página del primer tropiezo.
- [https://matplotlib.org/3.11.2/api/_as_gen/matplotlib.pyplot.errorbar.html](https://matplotlib.org/3.11.2/api/_as_gen/matplotlib.pyplot.errorbar.html)
  — las barras de error, con la aclaración de que son distancias.
- [https://plotly.com/python/interactive-html-export/](https://plotly.com/python/interactive-html-export/)
  — `include_plotlyjs` y sus modos, que es la decisión de 435×.
- [https://altair-viz.github.io/user_guide/encodings/index.html](https://altair-viz.github.io/user_guide/encodings/index.html)
  — la gramática: cómo se mapean datos a canales visuales.
- [https://vega.github.io/vega-lite/docs/](https://vega.github.io/vega-lite/docs/) — la
  especificación que altair produce. Útil cuando la biblioteca no te deja hacer algo.

**Accesibilidad**

- [https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum)
  — de dónde salen el 4,5:1 y el 3:1, y qué cuenta como texto grande. Es la referencia que
  convierte una discusión de gustos en un umbral.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan
> números de página, ISBN ni identificadores de video que no se hayan comprobado.

**Orden de lectura sugerido.** Antes de escribir código: la página de backends de matplotlib
—te ahorra el primer error— y la de codificaciones de altair, que da el modelo mental. Durante:
la de `errorbar`, cuando dibujes la banda. Después: la de contraste de WCAG, que es la que vas
a citar en una reunión.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con el tablero del Embudo en cuatro versiones, con una paleta cuyo contraste está
medido en vez de discutido, y con el veredicto más contraintuitivo de esta parte del curso:
**para las siete cifras del comité, la tabla de texto gana**. No porque los gráficos sean
malos, sino porque la banda de `ds04` —el hallazgo entero— cabe en una columna de texto y no
cabe en una barra.

También te llevas el descubrimiento de la sección 5.5, que ningún tutorial menciona: **dos
colores obviamente distintos en pantalla son el mismo gris en la impresora del comité**.

`ds06` es sobre dónde vivió todo este trabajo mientras lo hacías. Porque el análisis de
`ds04` y las figuras de aquí, en la vida real, no se escriben en archivos `.py` limpios: se
escriben en un cuaderno, a saltos, ejecutando celdas en el orden en que se te ocurren. Y la
pregunta que `ds06` contesta con la medición más barata del curso es incómoda: **de los
cuadernos que acabas de producir, ¿cuántos vuelven a correr?**

> **La señal de que quedó bien:** cuando ante un "hazme un gráfico" tu primera pregunta sea
> *"¿para decidir, para ver una forma o para explorar?"* — y cuando puedas entregar una tabla
> sin sentir que te quedaste corto.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-05 -m "ds05 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 05: …`), los de ejercicio su número
> (`ds 05 ej12: …`) y el miniproyecto el suyo (`ds 05 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `ds-mini-05`, con **la biblioteca elegida y el rango fijo de las
> escalas** en el mensaje. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
