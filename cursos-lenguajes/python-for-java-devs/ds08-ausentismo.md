# 🧠 ds08 — Proyecto · Ausentismo

> Python para desarrolladores Java senior · Track `ds` · sección 8 de 9
> Depende de: `ds07` · Habilita: `ds09`
> Registro de esta sección: script — un archivo por pieza, ejecutado a mano
> Proyecto que avanza: Ausentismo — se cierra el modelo y se abre la decisión

---

## 🎯 1. Propósito

`ds07` dejó una línea base con nombre y apellido: **0,799 de AUC, 0,526 de precisión a
capacidad del 20%, 1,2 KB de artefacto**. Esta sección pone una red neuronal a competir
contra eso, sobre los mismos datos y el mismo corte temporal.

Y después hace lo que nadie hace: **convierte el resultado en una decisión de plata**. Porque
la pregunta de Julián nunca fue *"¿cuál modelo tiene mejor AUC?"*, fue **"¿conviene
sobreagendar el jueves a las cuatro, y en qué medida?"** — y para contestar eso, el AUC no
sirve. Hace falta que el modelo diga *cuánto*, no solo *quién*.

Al final llega la parte que no es técnica y es la más importante del track: **qué se hace con
la predicción**. Recordarle más al paciente señalado es legítimo. Darle peor horario porque
el modelo lo señaló, no. Esa línea se dibuja aquí, antes de que alguien la cruce sin darse
cuenta.

> 🧭 **La regla que ordena la sección: un modelo que ordena bien no sirve para decidir cuánto
> apostar.** Ordenar es AUC; decidir es calibración. Son dos preguntas y hacen falta las dos.

---

## ✅ 2. Qué queda listo al terminar

- [ ] La red neuronal está entrenada, es **determinista** y su resultado se puede reproducir.
- [ ] Sabes cuánto le gana a la línea base **y con qué intervalo**, no solo el punto.
- [ ] Reprodujiste la logística con **una columna escrita a mano** y sabes qué le pasó a la
      ventaja de la red.
- [ ] Puedes explicar la diferencia entre discriminar y calibrar, y demostrarla con un modelo
      que ordena igual y miente el doble.
- [ ] `overbooking.py` convierte probabilidades en una decisión, con la asimetría de costos
      escrita en un número que alguien puede discutir.
- [ ] Sabes cuánto cuesta equivocarse: qué pasa cuando se sobreagenda con un puntaje mal
      calibrado.
- [ ] Tienes escrita la línea ética: qué se puede hacer con la predicción y qué no.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Servir el modelo** → `ds09`: el endpoint, `pickle` contra ONNX y el reentrenamiento.
- **Arquitecturas más grandes** —más capas, más anchas, *dropout*, *batch norm*— → el
  ejercicio 12 mide qué pasa al crecerlas, y el resultado no invita a seguir.
- **Gradiente potenciado** (`HistGradientBoostingClassifier`, XGBoost, LightGBM) → es el
  competidor que **debería** estar aquí y no está: quedó como ejercicio 24 de `ds07` y como
  📌 pendiente. Declararlo es más honesto que fingir que la red era el rival natural.
- **GPU** → fuera del curso. Con 241 parámetros y 72.396 filas, el modelo entrena en dos
  segundos en un portátil; proponer una GPU aquí sería el anti-patrón del track.
- **Explicabilidad con SHAP o LIME** → fuera. Con cinco variables y un modelo lineal, los
  coeficientes ya explican; con la red, el ejercicio 17 pregunta qué se perdió.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

Un jueves a las cuatro de la tarde, la sede de Kennedy tiene doce cupos. El modelo dice que
tres de esos pacientes van a faltar. **¿Se meten tres pacientes más en la agenda?**

Si aciertas, rescatas tres consultas que se habrían perdido. Si te equivocas, tienes dos
pacientes en la misma silla: cuarenta minutos de espera, una disculpa, y a veces un paciente
que no vuelve. **Las dos cosas no cuestan lo mismo**, y hasta que esa asimetría no esté
escrita en un número, la decisión no es del modelo.

```python
COLLISION_RATIO = 3.0   # cuántas veces peor es una colisión que una silla vacía
```

Ese `3.0` **no es un hiperparámetro**: es una decisión de Marcela y de Julián, que son los que
responden ante un paciente enojado. El código lo deja en una constante visible, con su
comentario, para que se pueda discutir en una reunión — que es lo único que hace falta que
pase con él.

Y de ahí sale el umbral, en una línea de álgebra:

```python
def break_even(ratio: float = COLLISION_RATIO) -> float:
    """`p = ratio / (1 + ratio)`."""
    return ratio / (1 + ratio)
```

Con `ratio = 3`, hace falta que el paciente falte **tres de cada cuatro veces** para que
sobreagendar su cupo no destruya valor. Ese 0,75 es el número operativo de la sección, y no
salió de ningún modelo: salió de la aritmética de una asimetría que alguien decidió.

### Discriminar no es calibrar

El AUC contesta *"¿ordena bien?"*. Para elegir a quién llama Yuli, alcanza. Para decidir si se
sobreagenda, **no**: ahí hay que multiplicar por una probabilidad, y una probabilidad mal
calibrada convierte una esperanza matemática en un número inventado.

La demostración cabe en cuatro líneas:

```python
scores = [0.8, 0.6, 0.4, 0.2]
halved = [score / 2 for score in scores]    # el mismo orden, la mitad de confianza

roc_auc(halved, target) == roc_auc(scores, target)   # idéntico
brier_score(halved, target) > brier_score(scores, target)   # mucho peor
```

Por eso al AUC lo acompañan dos métricas más: el **Brier**, que es el error cuadrático medio
de la probabilidad, y el **ECE**, que es cuánto se desvía en promedio lo predicho de lo
observado. Y por eso la tabla de fiabilidad —decil a decil, predicho contra observado— es lo
que hay que mirar antes de usar una probabilidad para decidir plata.

### Tu instinto de Java dice… y esta vez se equivoca

Tu instinto dice **"si el modelo más complejo gana, uso el modelo más complejo"**. Es el mismo
criterio con el que eliges una estructura de datos, y ahí funciona: si el `HashMap` gana, usas
el `HashMap`, porque mantenerlo no cuesta nada.

Aquí el modelo más complejo **sí gana** —la sección 6 lo muestra— y la conclusión no se sigue.

```python
# ❌ El razonamiento completo, tal como suena en una reunión.
# "La red saca 0,812 contra 0,799. Usamos la red."
```

Falta la mitad de la frase: **qué cuesta la red**, y contra qué otra cosa se podría haber
comparado. Porque el 0,812 de la red lo alcanza también una regresión logística con **una
columna más, escrita a mano en una línea** — y esa comparación no aparece en ninguna parte
salvo que alguien la haga.

```python
# ✅ La columna. Es todo lo que la red encontró de más.
return ([[*row, row[rain] * row[distance]] for row in matrix], target)
```

El instinto hermano, y es el que más daño hace en este dominio: **"el modelo decide"**. No
decide. El modelo produce una probabilidad; la decisión es la asimetría de costos, y esa la
pone la empresa. Un equipo que delega el umbral en el `argmax` de una métrica ha tomado una
decisión de negocio sin enterarse.

### Autopsia: el puntaje que ordena bien y decide pésimo

La regla de tres variables de `ds07` saca **0,672 de AUC**: no es un desastre, ordena
razonablemente, y para llamar a los veinte de mayor riesgo sirve.

Su puntaje, en cambio, **no es una probabilidad**. Es una suma de pesos dividida por su
máximo, y su ECE es de **0,1918** — casi veinte puntos de desviación entre lo que anuncia y
lo que pasa. Aplicada a la decisión de sobreagendar con la asimetría de Áurea:

| | Cupos sobreagendados | Consultas ganadas contra no hacer nada |
|---|---|---|
| regla de 3 variables | 6.187 | **−6.336** |
| logística de 5 | 1.247 | +1.664 |
| red neuronal | 1.994 | +3.023 |

**La regla no pierde un poco: pierde casi todo lo que había para ganar**, y además pierde
respecto a no hacer nada. Sobreagenda seis mil cupos porque su puntaje de 0,8 no significa
80%, significa "alto". Y nada avisa: los pacientes enojados aparecen tres semanas después.

> 💡 **La lección que se lleva, y vale para cualquier modelo:** si tu puntaje va a multiplicar
> algo —plata, cupos, riesgo—, **no basta con que ordene**. Mide la calibración antes, o el
> primer trimestre te lo explica.

### Esto sí funciona igual

- **Medir antes de optimizar.** La red entrena en dos segundos; la tentación de crecerla es
  la misma tentación de siempre, y se resuelve igual: midiendo.
- **Una dependencia es una decisión.** PyTorch pesa cientos de megas y trae su propio
  `libomp`; la sección 5.5 cuenta lo que eso significa en una máquina real.
- **Lo que decide plata se prueba.** `calibration.py` y `overbooking.py` tienen sus pruebas y
  **no dependen de torch ni de sklearn**: son aritmética.
- **El criterio de parada es un criterio.** Entrenar hasta que deje de mejorar sobre datos que
  no ha visto es la misma disciplina de no sintonizar contra el conjunto de prueba.

### Diccionario de traducción

| Lo que sabes | Aquí | Dónde se rompe el paralelo |
|---|---|---|
| Elegir la estructura de datos que gana | elegir el modelo que gana | La estructura no cuesta mantenimiento; el modelo sí, y el costo puede superar la ganancia |
| `Optional.orElse(default)` | umbral de decisión | El default es una preferencia; el umbral es una esperanza matemática con plata detrás |
| Precisión numérica | calibración | Buen paralelo: las dos son "el número que sale, ¿cuánto vale?" |
| Prueba de carga | sobreagendamiento | Los dos son "cuánto de más aguanta esto", y los dos tienen un costo asimétrico al pasarse |
| Refactorizar a una abstracción | ingeniería de variables | Aquí la "abstracción" es conocimiento del dominio, y la escribe quien conoce la operación |
| Tiempo de compilación | tiempo de entrenamiento | Falso amigo: compilar es determinista; entrenar depende de semilla, orden de lotes y parada |

> 📝 **Nota de ecosistema.** PyTorch en CPU es perfectamente razonable para un problema de este
> tamaño, y eso conviene decirlo porque la fama sugiere lo contrario: 241 parámetros y 72.396
> filas entrenan en menos de dos segundos en un portátil. Lo que sí trae es peso —cientos de
> megas de instalación— y sus propias dependencias nativas. Y una cosa que casi nadie
> menciona: **su API de entrenamiento es un bucle que escribes tú**, con optimizador, lotes,
> semillas y criterio de parada. Eso es libertad y es superficie de error: cinco decisiones
> que en `scikit-learn` venían resueltas y aquí son tuyas, incluida la de cuándo parar.

---

## 💻 5. Código mínimo con comentarios

Registro **script**: un archivo por pieza. Cinco módulos y no uno, porque tres de ellos
—`calibration.py`, `overbooking.py` y el `shared.py` que trae la línea base— **no dependen de
torch**, y esa frontera es la que permite probarlos y medirlos aparte.

```bash
uv run --with torch==2.14.0 --with scikit-learn==1.9.1 python bench_net.py --datos data
```

### 5.1 Importar la línea base en vez de copiarla

```python
# src/ds08-ausentismo/shared.py
DS07 = Path(__file__).resolve().parent.parent / "ds07-scikit-learn"
if str(DS07) not in sys.path:
    sys.path.insert(0, str(DS07))
```

Es **la única vez en los dos tracks** que una sección importa código de otra, y la razón es
concreta: la comparación solo vale si las dos usan exactamente las mismas variables, el mismo
tope de historial y el mismo corte. Copiar `features.py` habría sido más limpio de leer y
habría garantizado que algún día las dos definiciones divergieran **sin que nadie se entere**
— y ese día la tabla de la sección 6 dejaría de significar algo sin dar ningún error.

La excepción se declara, con su motivo, en vez de esconderse detrás de un `sys.path` sin
comentario.

### 5.2 La red, con sus cinco decisiones a la vista

```python
HIDDEN = (16, 8)
SEED = 20260913
EPOCHS = 60
BATCH_SIZE = 512
LEARNING_RATE = 0.01
PATIENCE = 8
```

**Detalles con intención**

- **La validación sale del final del tramo de entrenamiento**, no de una muestra al azar. Es
  el criterio temporal de `ds07` aplicado una vez más hacia adentro: cortar por pérdida de
  validación usando un trozo elegido al azar sería decidir cuándo parar con información del
  futuro.
- **`BCEWithLogitsLoss` y no `BCELoss` sobre una sigmoide.** Es numéricamente estable, y es la
  razón de que la red devuelva logits y la sigmoide viva en `score_network`.
- **La semilla se fija en tres sitios**: los pesos iniciales, el orden de los lotes y el
  generador de permutaciones. Con menos, dos corridas dan números distintos y la comparación
  contra una logística determinista deja de ser justa.
- **El escalado usa la media y la desviación del tramo de entrenamiento**, y una columna
  constante recibe desviación 1 para no producir infinitos silenciosos.

### 5.3 La columna que iguala a la red

```python
def build_with_interaction(rows):
    matrix, target = build_matrix(rows)
    rain = HONEST.index("lluvia_mm")
    distance = HONEST.index("distancia_km")
    return ([[*row, row[rain] * row[distance]] for row in matrix], target)
```

Una regresión logística solo puede **sumar** efectos. Si el mundo tiene un producto —llover
importa más cuando vives lejos, que es lo que le pasa a un paciente de Soacha en octubre— el
modelo lineal no lo ve y una red sí.

La salida barata es escribirlo a mano. **Y esto no es hacer trampa: es el trabajo.** La
ingeniería de variables es donde se mete el conocimiento del dominio, y el dominio lo tiene
Julián: *"cuando llueve, los de la sabana no vienen"*. Una red descubre esa interacción sola;
un humano la escribe en una línea. Comparar las dos opciones **incluye comparar quién la
mantiene**.

### 5.4 De la probabilidad a la decisión

```python
def expected_gain(probability: float, ratio: float = COLLISION_RATIO) -> float:
    """`p × 1` por la consulta que se rescata, menos `(1 − p) × ratio` por la colisión."""
    return probability - (1 - probability) * ratio
```

Doce líneas de módulo que valen más que la red entera, porque son las que convierten un
puntaje en algo que alguien hace. Y trae su contraparte, que es la que comprueba si la cuenta
era verdad:

```python
def realised_cost(probabilities, decisions, actual_no_show, ratio=COLLISION_RATIO):
    """Lo que **de verdad** pasó, con las decisiones tomadas y los resultados observados.

    La diferencia entre esto y `expected_cost` es la prueba de fuego de la calibración: si
    el modelo está bien calibrado, las dos cifras se parecen.
    """
```

Sobre los datos de Áurea, con el modelo bien calibrado, la esperanza dice **−3.600** y lo
realizado **−3.579**: se parecen porque el ECE es de 0,01. Con la regla, la esperanza dice
−2.584 y lo realizado **−12.938**: cinco veces peor de lo que el propio puntaje prometía.

### 5.5 Lo que rompe de verdad al instalar PyTorch

```
OMP: Error #15: Initializing libomp.dylib, but found libomp.dylib already initialized.
```

En un entorno con **solo torch**, esto aborta el proceso antes de la primera línea del
programa. En el mismo entorno **con scikit-learn al lado**, funciona. La causa es que más de
una biblioteca trae su propia copia del runtime de OpenMP y el enlazador dinámico encuentra
dos.

Merece estar en el cuerpo del capítulo por lo que enseña: **una dependencia nativa no se
instala sola, se instala con todo lo que arrastra**, y el conflicto no aparece en ningún
`requirements.txt`. El mensaje sugiere `KMP_DUPLICATE_LIB_OK=TRUE` y él mismo lo llama
*"unsafe, unsupported, undocumented"*: es una variable de entorno para salir del paso, no
para poner en producción.

**El patrón a memorizar**
> Antes de adoptar el modelo que ganó: ¿por cuánto ganó, con qué intervalo, y qué le pasa a
> esa ventaja si le escribo al competidor una columna que el dominio ya conocía?

**Prueba de fuego**

```bash
uv run --with torch==2.14.0 --with scikit-learn==1.9.1 --with pytest pytest -q
```

Catorce pruebas. Las de calibración y sobreagendamiento **no importan torch ni sklearn**: son
aritmética, y son justamente las que deciden plata.

La mentira que te va a contar la salida si miras el lugar equivocado: la tabla 6.1 pone a la
red y a la logística con interacción en **0,8118 las dos**. Parece un empate perfecto y es
una coincidencia de la tercera cifra decimal; lo que sostiene el veredicto no es esa igualdad
sino los intervalos de la tabla 6.4, que se solapan casi por completo.

---

## 📏 6. Medición

**Hipótesis.** Que la red neuronal le gana a la línea base de `ds07`, que la ventaja es
pequeña, y que **una columna de ingeniería de variables la iguala** — con lo cual la decisión
deja de ser de rendimiento y pasa a ser de costo de mantenimiento.

**Condiciones.** CPython 3.14.5, PyTorch 2.14.0 en CPU, scikit-learn 1.9.1; macOS 26.6.2 sobre
Apple Silicon de 8 núcleos. Los mismos datos, el mismo corte y las mismas cinco variables de
`ds07`: **72.396 citas para entrenar y 33.224 para probar**, 19,9% de inasistencia en el
tramo de prueba. La red: dos capas ocultas de 16 y 8, Adam, lotes de 512, semilla 20260913 y
parada temprana con paciencia de 8 sobre el último 20% del tramo de entrenamiento. Intervalos
bootstrap de 200 remuestreos con semilla fija.

**Competidores.** La regla de tres variables y la logística de cinco, las dos de `ds07` sin
tocar una línea, más la logística con una columna de interacción añadida aquí. El
**competidor que falta se declara**: un gradiente potenciado, que para datos tabulares de este
tamaño es el rival natural y quedó pendiente.

### 6.1 Discriminación, calibración y operación

| Candidato | AUC | Brier | ECE | Precisión @20% |
|---|---|---|---|---|
| regla de 3 | 0,6723 | 0,1952 | **0,1918** | 0,351 |
| logística de 5 | 0,7993 | 0,1204 | 0,0127 | 0,526 |
| **logística + interacción** | **0,8118** | **0,1114** | **0,0106** | 0,547 |
| red neuronal | 0,8118 | 0,1116 | 0,0107 | 0,548 |

### 6.2 Fiabilidad de la red, decil a decil

| Predicho | Observado | Casos |
|---|---|---|
| 0,039 | 0,042 | 3.322 |
| 0,095 | 0,098 | 3.322 |
| 0,184 | 0,175 | 3.322 |
| 0,272 | 0,265 | 3.322 |
| 0,367 | 0,326 | 3.322 |
| 0,795 | 0,769 | 3.326 |

*(Se muestran seis de los diez deciles; los cuatro omitidos están entre 0,049 y 0,122 y se
comportan igual.)*

### 6.3 La decisión: consultas recuperadas frente a no sobreagendar

Sin sobreagendar se pierden **6.602 consultas** de 33.224 citas.

| Una colisión cuesta | Umbral | regla de 3 | logística de 5 | + interacción | red neuronal |
|---|---|---|---|---|---|
| 1× una silla vacía | p > 0,50 | +503 | +3.497 | +4.256 | **+4.314** |
| 2× | p > 0,67 | −2.594 | +2.162 | +3.404 | **+3.482** |
| **3× (el caso base)** | p > 0,75 | **−6.336** | +1.664 | +3.006 | **+3.023** |
| 4× | p > 0,80 | −808 | +1.368 | +2.740 | **+2.768** |

### 6.4 ¿Es real la ventaja?

| Diferencia de AUC | Media | IC 95% |
|---|---|---|
| red − logística de 5 | +0,0125 | [+0,0109, +0,0141] |
| interacción − logística de 5 | +0,0126 | [+0,0107, +0,0142] |

### 6.5 Lo que cuesta cada uno

| | Logística + interacción | Red neuronal |
|---|---|---|
| Entrenar | 144 ms | 1,9 s |
| Épocas corridas / mejor | — | 26 / 18 |
| Parámetros | 6 coeficientes | 241 |
| Artefacto serializado | 1,2 KB | 4,0 KB |
| Dependencias | scikit-learn | scikit-learn **y PyTorch** |
| Decisiones del entrenamiento | ninguna | arquitectura, semilla, lotes, tasa, parada |

```bash
uv run --with torch==2.14.0 --with scikit-learn==1.9.1 python bench_net.py --datos data
```

> ⚖️ **Veredicto — y no es el que este track venía anunciando.**
>
> **1. La red gana.** 0,8118 contra 0,7993 de AUC, y la diferencia **es real**: el intervalo
> al 95% es [+0,0109, +0,0141] y no toca el cero. La tesis que la historia de Áurea daba por
> probable —*la red neuronal probablemente pierde*— **no se cumplió**, y se escribe así.
>
> **2. Y gana exactamente lo que vale una columna.** La misma logística con `lluvia ×
> distancia` añadida a mano llega a **0,8118**, con un intervalo indistinguible: [+0,0107,
> +0,0142] contra [+0,0109, +0,0141]. No es casualidad: **el proceso que genera estos datos
> tiene una sola interacción**, la red la encuentra, y escribirla cuesta una línea. La ventaja
> de la red sobre la línea base no era de la red: era de la interacción que la línea base no
> tenía.
>
> **3. Entonces la decisión no es de rendimiento, es de mantenimiento.** Al mismo AUC, mismo
> Brier y misma precisión operativa, la logística cuesta 144 ms de entrenamiento, 1,2 KB de
> artefacto, seis coeficientes que se leen en voz alta y **ninguna decisión de entrenamiento**.
> La red cuesta PyTorch instalado —con su conflicto de OpenMP—, 4,0 KB, un bucle de
> entrenamiento propio y cinco decisiones que alguien tiene que volver a tomar cada vez que
> los datos cambien. **La recomendación para Áurea es la logística con la interacción**, y el
> motivo no es que la red sea mala: es que no está comprando nada.
>
> **4. Y el hallazgo que más plata mueve no es sobre modelos, es sobre calibración.** La regla
> de `ds07` ordena decentemente —0,672 de AUC— y **decide catastróficamente**: aplicada al
> sobreagendamiento con la asimetría de Áurea, pierde **6.336 consultas** contra no hacer
> nada, mientras cualquiera de los modelos calibrados recupera unas 3.000. La diferencia entre
> 0,672 y 0,799 de AUC parecía moderada; en la decisión es la diferencia entre ganar y
> destruir.
>
> **El umbral, dicho como criterio:** una red neuronal se justifica sobre datos tabulares
> cuando su ventaja **sobrevive a que le escribas al modelo lineal las interacciones que el
> dominio ya conoce**. Aquí no sobrevive ninguna. El día que el dominio tenga diez
> interacciones que nadie sabe nombrar, la respuesta cambia — y entonces el competidor a
> medir no es una red, es un gradiente potenciado.

> 📝 **Lo que esta medición no dice.** **Falta el competidor que importaba**: un gradiente
> potenciado sobre las mismas cinco variables, que para datos tabulares de este tamaño suele
> ganarle a las dos. Dejarlo fuera le regaló a la red una comparación cómoda y hay que
> decirlo. No mide qué pasa cuando los datos cambian —el generador no tiene deriva, como
> declaró `ds07` §6.2—, que es justo donde el costo de reentrenar decide. Y **no mide si
> sobreagendar funciona**: mide qué habría pasado aplicando la decisión a un histórico donde
> nadie sobreagendó. Si Áurea empieza a sobreagendar, los pacientes lo van a notar y el
> comportamiento va a cambiar; eso no está en ningún dato y es el mismo contrafactual de
> `ds04`.

---

## ⚖️ 6.6 Qué se puede hacer con la predicción, y qué no

Esto no es un párrafo de cierre. Es la sección del capítulo que más consecuencias tiene, y va
aquí —junto a los números— porque las dos cosas se deciden juntas.

El modelo produce una probabilidad por paciente. Con esa probabilidad, Áurea **puede**:

- **Recordarle más.** Un mensaje adicional el día anterior a quien tiene más riesgo. Es
  proporcional, es reversible y el paciente sale ganando.
- **Llamarlo.** Es lo que hace Yuli, es lo que el modelo ordena mejor, y es una atención.
- **Ofrecerle otra hora.** *"El jueves a las cuatro se nos complica el tráfico, ¿le sirve el
  martes a las diez?"* — una oferta, no una asignación.
- **Sobreagendar el cupo**, con la cuenta de la sección 6.3 delante y el `COLLISION_RATIO`
  discutido con quien responde por la sala de espera.

Y **no puede**:

- **Darle peor horario porque el modelo lo señaló.** Es la línea, y es la que más fácil se
  cruza sin darse cuenta: basta con que el sistema "optimice" asignando los cupos malos a los
  pacientes de alto riesgo. El paciente que más falta suele ser el que vive más lejos y tiene
  el trabajo menos flexible; darle el peor horario **es cobrarle por ser pobre** y además se
  refuerza solo —falta más, sube su puntaje, peor horario—.
- **Cobrarle distinto.** Un recargo por riesgo predicho no es un incentivo: es una multa por
  un pronóstico.
- **Negarle una cita.** Ni siquiera "temporalmente", ni siquiera "hasta que mejore su
  historial".
- **Dejar el modelo decidir solo.** Todo lo de la lista permitida lo ejecuta una persona que
  puede decir *"a esta señora no la llamo, la conozco"*.

> 🧭 **La prueba de una sola pregunta, que sirve para cualquier modelo sobre personas: si el
> paciente supiera que existe este puntaje, ¿te parecería bien contárselo?** Recordarle más,
> sí. Llamarlo, sí. Ofrecerle otra hora, sí. Darle el peor turno porque un modelo lo señaló,
> no — y si la respuesta es que mejor no se entere, esa es la respuesta.

Y una consecuencia técnica de todo lo anterior, que se implementa: **el puntaje no se guarda
en la ficha del paciente**. Vive en la lista del día, se usa esa mañana y se descarta. Un
campo persistente "riesgo de inasistencia" en un registro clínico es una etiqueta que alguien
va a leer en otro contexto dentro de dos años, y ahí ya no hay quien explique de dónde salió.

---

## 🧱 7. Miniproyecto — La política de sobreagendamiento

**El encargo.** Julián te dice: *"Con lo del jueves a las cuatro me convenciste a medias.
Quiero una propuesta escrita que pueda llevarle al comité: en qué cupos sí, en cuáles no,
cuánto esperamos ganar y qué hacemos el día que se nos junten dos pacientes. Y la quiero con
el número de cuánto cuesta equivocarnos, porque el que da la cara soy yo."*

**Por qué duele.** Porque el entregable no es un modelo ni una tabla: es una **política**, y
una política tiene que decir qué se hace cuando falla. Y porque el número que la sostiene
—cuánto peor es una colisión que una silla vacía— **no está en los datos**: hay que estimarlo,
declararlo, y mostrar cómo cambia la política si estuviera equivocado.

**Datos de entrada.** El histórico de ausentismo y el modelo entrenado. Construye la agenda de
un jueves del tramo de prueba. El caso sucio está en la operación: **hay cupos que ya vienen
sobreagendados de antes** —dos pacientes citados a la misma hora por error de la sede— y tu
política tiene que decir qué hace con ellos.

**Criterios de aceptación.**

1. `python politica.py --fecha 2026-01-15 --ratio 3` imprime, por sede y franja, qué cupos se
   sobreagendan y cuántos, con el total esperado de consultas recuperadas.
2. La salida incluye un **análisis de sensibilidad**: la misma decisión con el ratio en 1, 2,
   3 y 4, y una frase que diga a partir de qué valor la política cambia de signo.
3. Ningún cupo se sobreagenda si su probabilidad viene de un modelo cuyo ECE en el último mes
   supere un umbral que tú fijas. **La política se apaga sola si el modelo se descalibra**, y
   eso se comprueba con una prueba.
4. El programa reporta, sobre el histórico, cuántas colisiones habría producido la política y
   en qué sedes. Esa cifra va en la propuesta, no escondida.
5. La propuesta escrita —un `.md` de una página, parte del entregable— incluye la lista de la
   sección 6.6: qué se hace con la predicción y qué no.
6. Una prueba verifica que la política **nunca** sobreagenda un cupo de un paciente en su
   primera cita. Sin historial, el puntaje es el del promedio, y apostar sobre un promedio es
   apostar sobre nadie.

**Restricciones de registro.** Script: un archivo, `argparse`, salida en texto. El modelo se
carga, no se entrena: entrenar dentro de la política es el error que `ds07` §7 ya cobró.

**La trampa.** El criterio 3. Vas a implementar el apagado por descalibración y vas a
comprobarlo con el ECE del **mismo** tramo con el que decides — que siempre va a estar bien,
porque es el que el modelo ya vio. El ECE que importa es el del **último mes cerrado**, contra
resultados reales, y eso obliga a tener un ciclo: predecir, esperar, comparar. Ese ciclo es
`ds09`.

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

Una política es una función de la probabilidad al conjunto de acciones permitidas, más las
condiciones bajo las que se suspende. Escribe primero las condiciones de suspensión: son las
que convierten una regla en algo que Julián puede defender.
</details>

<details><summary>Pista 2 — la herramienta</summary>

Todo lo que necesitas está en `overbooking.py` y `calibration.py`. Lo que falta es la
agrupación por sede y franja y la comparación entre `expected_cost` y `realised_cost`, que es
lo que demuestra que la cuenta era verdad.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def policy(agenda: list[dict], scores: list[float], ratio: float) -> list[Decision]: ...
def suspended(recent_scores, recent_target, max_ece: float) -> bool: ...
def sensitivity(agenda, scores, ratios: list[float]) -> str: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-08 -m "Mini ds08: política de sobreagendamiento · ratio <R> · +<N> consultas · cambia de signo en <X>"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre la medición y reproduce la tabla 6.1. Después cambia la semilla de la red y vuelve a
   correr: ¿cuánto se mueve el AUC? Ese movimiento es el ruido de tu comparación.
2. Calcula el Brier de un modelo que predice siempre 0,199 —la tasa base— y compáralo con el
   de la regla. El resultado incomoda.
3. Dibuja la curva de fiabilidad de los cuatro candidatos con lo de `ds05`. La de la regla es
   la que hay que enseñarle a alguien que no cree en la calibración.
4. Cambia `COLLISION_RATIO` a 1,5 y mira cómo se mueve el número de cupos sobreagendados y el
   neto. Escribe la frase que le dirías a Julián.
5. Entrena la red con `PATIENCE = 60` —es decir, sin parada temprana— y compara el AUC de
   prueba. La diferencia es lo que cuesta no tener criterio de parada.
6. Quita el escalado de la red y entrena. Reporta qué pasa con la pérdida.

**🟡 Intermedio (7–14)**

7. Añade una segunda interacción a la logística —la que se te ocurra del dominio— y mide. Si
   no mejora, ese también es un resultado y dice algo sobre los datos.
8. Mide el AUC de la red sobre el tramo de **entrenamiento** y sobre el de prueba. La brecha
   es el sobreajuste, y con parada temprana debería ser chica.
9. Implementa el escalado de probabilidades por temperatura —dividir los logits por un valor
   ajustado— y mira si mejora el ECE de la red sin tocar el AUC.
10. Calcula la precisión y el recall de cada modelo **solo sobre los jueves después de las
    cuatro**. Es la pregunta de Julián, y la respuesta no tiene por qué parecerse a la global.
11. Sobre el histórico, cuenta cuántas colisiones habría producido la política del caso base
    y en qué sedes se concentran. Esa cifra es la que Julián va a mirar primero.
12. Crece la red: cuatro capas de 64. Mide AUC, tiempo de entrenamiento y parámetros. Reporta
    los tres, aunque el AUC no se mueva — sobre todo si no se mueve.
13. Entrena la red cinco veces con semillas distintas y reporta la mediana y el rango del AUC.
    Compáralo con la logística, que no tiene rango.
14. Mide cuánto tarda `import torch` en frío y compáralo con `import sklearn`. Después decide
    qué significa eso para el endpoint de `ds09`.

**🟠 Difícil (15–21)**

15. Diagnóstico: la política de sobreagendamiento produjo doce colisiones en una semana en la
    sede de Soacha y ninguna en Chapinero. Formula tres hipótesis y di qué medirías para
    distinguirlas.
16. **El competidor que falta.** Entrena un `HistGradientBoostingClassifier` con las mismas
    cinco variables y mídelo contra las cuatro filas de la tabla 6.1. Si le gana a todos, el
    veredicto de la sección cambia: escríbelo.
17. La logística explica con seis coeficientes. Diseña qué le dirías a una paciente que
    pregunta por qué la llamaron, usando la red. Después usando la logística. La diferencia es
    el argumento de la sección 6.5 en una frase.
18. Implementa la suspensión por descalibración del miniproyecto y simula un mes en que el
    modelo se descalibra —desplaza las probabilidades— para comprobar que se apaga.
19. **Estima el `COLLISION_RATIO` con datos.** ¿Qué tendría que medir Áurea para ponerle un
    número a "un paciente que espera cuarenta minutos"? Diseña la medición, aunque no puedas
    correrla.
20. **De registro.** El puntaje se necesita en tres sitios: la lista de Yuli, la política de
    sobreagendamiento y —quizá— AgendaAPI. ¿Un modelo servido, tres procesos batch, o una
    tabla precalculada? Decide con los números de la sección 6.5.
21. Toma la sección 6.6 y conviértela en comprobaciones ejecutables: escribe las pruebas que
    fallarían si alguien implementara la asignación de horarios por riesgo.

**🔴 Muy difícil (22–25)**

22. **Defiende lo contrario.** Construye el caso para desplegar la red en vez de la logística
    con interacción. Tiene que incluir qué cambiaría en Áurea para que la red valga su
    mantenimiento, y ser realista.
23. El generador tiene **una** interacción. Modifícalo para que tenga cuatro, no lineales y
    entre variables distintas, regenera y vuelve a correr la medición completa. **Ahí la red
    debería despegarse**: mide cuánto. Es el experimento que convierte el veredicto de esta
    sección en un umbral.
24. 🔥 La decisión de sobreagendar se toma por cupo. Reformúlala por **franja** —doce cupos a
    la vez, con la probabilidad conjunta— y mide si cambia el resultado. Pista: la suma de
    probabilidades no es la probabilidad de la suma.
25. **De registro y de ética.** Escribe la política de una página que Áurea publicaría si un
    paciente preguntara cómo se usa su historial de asistencia. Tiene que ser verdadera —tiene
    que describir lo que el código hace— y comprensible para alguien sin formación técnica.

**🔥 Opcionales**

- Reemplaza la red por una logística **de PyTorch** —una sola capa lineal— y comprueba que
  llega al mismo sitio que scikit-learn. Es la mejor forma de ver que la red no es magia.
- Mira `torch.set_num_threads(1)` y mide si el entrenamiento cambia. Con 241 parámetros,
  probablemente descubras que la paralelización no aporta nada.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://docs.pytorch.org/tutorials/beginner/basics/quickstart_tutorial.html](https://docs.pytorch.org/tutorials/beginner/basics/quickstart_tutorial.html)
  — el bucle de entrenamiento mínimo. Léelo entero: es lo que scikit-learn te resolvía.
- [https://docs.pytorch.org/docs/stable/notes/randomness.html](https://docs.pytorch.org/docs/stable/notes/randomness.html)
  — **la página que hay que leer para que tu resultado sea reproducible.** Dice dónde hay azar
  y cuál de esas fuentes puedes controlar.
- [https://docs.pytorch.org/docs/stable/generated/torch.nn.BCEWithLogitsLoss.html](https://docs.pytorch.org/docs/stable/generated/torch.nn.BCEWithLogitsLoss.html)
  — por qué esta y no `BCELoss` con una sigmoide delante.
- [https://scikit-learn.org/1.9/modules/calibration.html](https://scikit-learn.org/1.9/modules/calibration.html)
  — calibración, curvas de fiabilidad y los dos métodos de recalibrar.
- [https://scikit-learn.org/1.9/modules/ensemble.html#histogram-based-gradient-boosting](https://scikit-learn.org/1.9/modules/ensemble.html#histogram-based-gradient-boosting)
  — el competidor que falta, para el ejercicio 16.

**Del propio curso**

- [`ds07-scikit-learn.md`](ds07-scikit-learn.md) §6 — la línea base contra la que se mide todo
  lo de aquí.
- [`ds04-embudo.md`](ds04-embudo.md) §6 — el mismo problema del contrafactual, en el otro
  proyecto.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan
> números de página, ISBN ni identificadores de video que no se hayan comprobado.

**Orden de lectura sugerido.** Antes de escribir código: el *quickstart* de PyTorch, para ver
qué implica escribir el bucle tú. Durante: la nota sobre aleatoriedad, en cuanto tu segunda
corrida dé otro número. Después: la de calibración, que es lo que convierte este capítulo en
una decisión.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con el proyecto Ausentismo cerrado y con un veredicto que no es el que el track
anunciaba: **la red gana, gana poco, y lo que gana es una columna**. La conclusión práctica
—quédate con la logística y la interacción— se parece a la que la historia de Áurea daba por
probable, pero se llega por otro camino, y el camino importa: no es que la red pierda, es que
no está comprando nada.

También te llevas el hallazgo que más plata mueve del track entero, y no es sobre modelos:
**un puntaje que ordena bien puede decidir catastróficamente**. La regla de `ds07`, aplicada
al sobreagendamiento, pierde más de lo que había para ganar, y el aviso llega en forma de
pacientes enojados tres semanas después.

Y te llevas la línea escrita: qué se puede hacer con la predicción y qué no, con la única
pregunta que la resuelve — *si el paciente lo supiera, ¿te parecería bien contárselo?*

`ds09` cierra el track con lo que falta para que todo esto exista fuera de tu portátil: el
modelo servido, `pickle` contra ONNX —y por qué un artefacto de modelo es un ejecutable
disfrazado de dato—, el reentrenamiento dentro del cierre nocturno de la Fase 15, y el
⚖️ veredicto de los cuatro proyectos: **cuál valía la pena y cuál no**.

> **La señal de que quedó bien:** cuando ante un modelo que gana tu primera pregunta sea *"¿por
> cuánto, y qué pasa si le escribo al competidor la variable que el dominio ya conoce?"* — y
> cuando ante una probabilidad tu segunda pregunta sea *"¿está calibrada?"* antes de
> multiplicarla por algo.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-08 -m "ds08 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 08: …`), los de ejercicio su número
> (`ds 08 ej12: …`) y el miniproyecto el suyo (`ds 08 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `ds-mini-08`, con **el ratio elegido y las consultas netas** en
> el mensaje. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
