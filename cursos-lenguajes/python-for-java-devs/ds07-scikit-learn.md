# 🎯 ds07 — scikit-learn y la línea base honesta

> Python para desarrolladores Java senior · Track `ds` · sección 7 de 9
> Depende de: `ds01`, `ds06` · Habilita: `ds08`
> Registro de esta sección: script — un archivo por pieza, ejecutado a mano
> Proyecto que avanza: Ausentismo — nace su línea base

---

## 🎯 1. Propósito

El 19% de los pacientes de Áurea no llega a su cita. La pregunta operativa de Julián es
concreta: **¿a quién llama Yuli mañana por la mañana?** Tiene media mañana, así que puede
llamar a uno de cada cinco.

Esta sección construye la respuesta y, sobre todo, construye **contra qué se compara**. Porque
un AUC de 0,80 no significa nada hasta que sabes qué saca la regla que Patricia ya aplica en
la cabeza — y a veces resulta que saca 0,79.

Es también el primer cambio de naturaleza del track: hasta `ds06` todo fue **descripción**,
contar lo que pasó con los datos delante. Aquí empieza la **predicción**, y con ella llegan
dos cosas nuevas: un modelo que puede estar equivocado de formas que no se ven, y una
decisión que cae sobre personas con nombre.

> 🧭 **La regla que ordena la sección: la línea base se escribe primero y se publica siempre**,
> gane o pierda. Publicarla solo cuando pierde convierte un informe en publicidad.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Existen **dos** líneas base —"todos asisten" y la regla de tres variables— y las dos
      están medidas antes de entrenar nada.
- [ ] `features.py` separa las variables que se conocen antes de la cita de la que no, y
      sabes decir para cada columna **cuándo se llena**.
- [ ] El histórico se parte por fecha y el corte sale del manifiesto del conjunto, no de una
      constante repetida en tres archivos.
- [ ] La regresión logística vive en un `Pipeline` con su escalado **dentro**, y sabes qué se
      rompe cuando está fuera.
- [ ] Reprodujiste la fuga de datos con `inasistencias_totales_paciente` y sabes cuánto AUC
      regala.
- [ ] Sabes por qué la exactitud no sirve aquí y puedes demostrarlo con un modelo que acierta
      el 80% y es inútil.
- [ ] Elegiste el umbral por **capacidad** y no maximizando una métrica, y puedes defenderlo.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Redes neuronales** → `ds08`, que las mide contra esta línea base.
- **Servir el modelo** → `ds09`: aquí el artefacto se entrena y se guarda, no se expone.
- **La discusión ética de qué se hace con la predicción** → `ds08`, donde es una sección del
  cuerpo y no un párrafo de cierre. Aquí se construye la predicción; allí se decide qué se
  hace con ella, que es la parte difícil.
- **Predecir el abandono de tratamiento** —el paciente que desaparece en el mes ocho de
  veinticuatro— → fuera del curso. Es la otra predicción cara de Áurea y necesita un
  horizonte y una definición de "abandonó" que dan para una sección propia.
- **Selección de variables, regularización ajustada, búsqueda de hiperparámetros** → fuera.
  Con cinco variables y un modelo lineal, la ganancia es menor que el riesgo de sobreajustar
  la elección al tramo de prueba.
- **Validación cruzada** → se nombra en el ejercicio 13 y no se usa en el cuerpo: con una
  partición temporal única, la validación cruzada estándar vuelve a mezclar el tiempo.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

Áurea tiene **105.620 citas** de dos años y tres meses, y de cada una sabe cuándo fue, en qué
sede, a qué hora, cuánto había llovido, a qué distancia vive el paciente, cuántas veces había
faltado antes… y si vino.

La tentación es abrir scikit-learn. Lo primero que hay que hacer es otra cosa: **escribir lo
que Patricia ya hace**.

```python
def three_variable_rule(rows):
    """Historial, día y hora. Ocho líneas, cero dependencias, cero entrenamiento."""
    scores = []
    for row in rows:
        risk = WEIGHT_PRIOR * min(int(row["inasistencias_previas"]), PRIOR_CAP)
        if row["dia_semana"] == "3" and row["hora"] >= "16:00":
            risk += WEIGHT_THURSDAY_LATE
        if row["hora"] < "08:00":
            risk += WEIGHT_EARLY
        scores.append(risk / MAX_SCORE)
    return scores
```

Esa función es el competidor. Si el modelo no le gana, el modelo no entra — y si le gana,
ahora sabes por cuánto.

Y antes que ella, el piso absoluto:

```python
def always_attends(rows):
    """El piso: nadie falta nunca. Un solo número para todo el mundo."""
    return [0.0] * len(rows)
```

**`always_attends` acierta el 80,1% de las veces.** Ese número es la razón por la que la
exactitud no se usa en este problema: un modelo que no hace nada saca ocho de diez.

### Las métricas, en el orden en que sirven

- **AUC** es la probabilidad de que un paciente que faltó tenga más puntaje que uno que vino.
  No depende del umbral, y por eso sirve para **comparar** candidatos antes de decidir nada.
- **Precisión** es, de los que marcaste, cuántos faltaron de verdad. Es el respeto por el
  tiempo de Yuli.
- **Recall** es, de los que faltaron, cuántos marcaste. Es el ahorro que se deja sobre la mesa.
- **Exactitud** no se usa. Ver arriba.

Y una cuarta cifra que casi nunca se publica y que decide si esto es operable: **a cuántos
marcas**. Un recall precioso sobre el 60% de la agenda no sirve, porque nadie llama a esa
gente.

### El umbral no sale de una métrica: sale de la capacidad

```python
def threshold_for_capacity(scores: list[float], capacity: float) -> float:
    """El umbral que marca como mucho una fracción `capacity` de las citas."""
    ordered = sorted(scores, reverse=True)
    position = min(int(len(ordered) * capacity), len(ordered) - 1)
    return ordered[position]
```

Yuli tiene media mañana: el 20% de la agenda. Ese número no es un hiperparámetro, es un hecho
de la operación, y elegir el umbral a partir de él es lo que convierte un modelo en algo que
alguien usa. Maximizar F1 habría dado otro umbral y ninguna conversación con nadie.

### Tu instinto de Java dice… y esta vez se equivoca

Tu instinto dice **"esto es una función: entra un caso, sale una predicción, y la pruebo con
una aserción"**. Once años de código determinista dejan esa expectativa intacta, y aquí falla
en tres sitios a la vez.

```python
# ❌ El reflejo. Tres errores en dos líneas, y ninguno lanza excepción.
X_train, X_test, y_train, y_test = train_test_split(X, y)   # al azar, con fechas
model.fit(X_train, y_train)
print("exactitud:", model.score(X_test, y_test))            # 0.81 · el piso saca 0.80
```

**El primero: partir al azar datos que tienen fecha.** El modelo entrena con diciembre y
predice octubre. Aquí la sección 6.3 trae una sorpresa que conviene leer antes de indignarse.

**El segundo: `score` devuelve exactitud**, y la exactitud de este problema está dominada por
la clase mayoritaria. 0,81 contra el 0,80 del modelo que no hace nada.

**El tercero, y es el más caro: no hay línea base.** Sin ella, 0,81 parece un resultado.

```python
# ✅ Lo mismo, con las tres cosas en su sitio.
train, test = split_temporal(rows, cutoff_of(data))          # por fecha
pipeline = fit_logistic(train)                               # el escalado va dentro
auc = roc_auc(score_rows(pipeline, test), target)            # contra la regla de 8 líneas
```

Y el reflejo hermano, que aparece al final: **`predict` decide por ti**. Con una clase
positiva del 20%, el umbral de 0,5 que usa `predict` marca el **9,8%** de las citas: se deja
fuera a la mitad de los que van a faltar, y ese número no lo eligió nadie. Por eso el código
usa `predict_proba` y el umbral sale de la capacidad de Yuli.

### Autopsia: la columna que conoce el futuro

El conjunto trae `inasistencias_totales_paciente`: cuántas veces faltó ese paciente **en todo
el histórico**. Es una columna real, existe en cualquier base de datos y sale de un `GROUP BY`
que cualquiera escribe sin pensar.

```sql
-- ❌ El `GROUP BY` de treinta segundos que arruina el modelo entero.
SELECT paciente_id, count(*) FILTER (WHERE NOT asistio) AS inasistencias_totales
FROM citas GROUP BY paciente_id;
```

El problema es **cuándo se conoce ese número**. Para una cita de marzo de 2025, incluye las
inasistencias de octubre de 2025 — que todavía no han ocurrido. El modelo aprende a usarlas y
la métrica sube:

| | AUC |
|---|---|
| Cinco variables honestas | 0,799 |
| Las mismas **más la columna con fuga** | **0,862** |

**Seis puntos y medio de AUC regalados.** En producción ese modelo va a rendir como el de
0,799 —o peor—, porque el día que prediga no va a tener el futuro. Y nada falla: no hay
excepción, no hay advertencia, y la métrica que reportas es mejor.

> 🧭 **La única definición operativa de "sin fuga" que se puede aplicar columna por columna:
> una variable entra si estaba disponible *antes* de la cita.** Contestar eso obliga a saber
> cuándo se llena cada campo, que es una pregunta de negocio y no de estadística — y por eso
> la contesta alguien que conoce la operación, no el modelo.

### Esto sí funciona igual

- **Separar lo que se aprende de lo que se aplica.** El `Pipeline` es inyección de
  dependencias con otro nombre: todo lo que se ajusta con datos de entrenamiento vive dentro
  y viaja junto.
- **Una métrica agregada esconde la distribución.** Lo sabes de las latencias —por eso el
  arnés reporta p95 y no promedio— y aquí vale igual.
- **Fijar versiones y semillas.** `scikit-learn` cambia detalles entre versiones menores; el
  modelo entrenado con una y cargado con otra es una fuente de sorpresas conocida.
- **El costo de una dependencia se paga en cada invocación.** Importar sklearn cuesta 857 ms.

### Diccionario de traducción

| Lo que sabes | Aquí | Dónde se rompe el paralelo |
|---|---|---|
| Función determinista | modelo entrenado | El mismo código con otros datos de entrenamiento da otro modelo |
| Prueba unitaria con aserción | métrica sobre un conjunto retenido | No hay "correcto": hay mejor o peor que una línea base |
| Inyección de dependencias | `Pipeline` | Buen paralelo: lo que se ajusta viaja junto con lo que lo usa |
| `assertEquals(esperado, real)` | AUC contra línea base | Comparar contra una constante no dice nada; comparar contra la regla sí |
| Cobertura de pruebas | exactitud | Falso amigo. Las dos son cifras altas que no significan lo que parece |
| Validación de entrada | comprobar fuga | La validación mira el tipo; la fuga es sobre **cuándo** se conoce el valor |
| `@Transactional` | corte temporal | Los dos son "esto no puede ver aquello", y los dos fallan en silencio |

> 📝 **Nota de ecosistema.** `scikit-learn` es de 2007 y su API —`fit`, `predict`,
> `transform`— se volvió el estándar de facto: PyTorch, XGBoost y media docena más ofrecen
> envoltorios compatibles porque el `Pipeline` y `GridSearchCV` esperan esa forma. Lo que
> importa para este perfil es que **esa estabilidad es la razón para empezar aquí**: el
> modelo lineal que entrenas hoy se cambia por un gradiente potenciado mañana tocando una
> línea, y la comparación sigue siendo válida porque el resto del andamiaje no se movió.

---

## 💻 5. Código mínimo con comentarios

Registro **script**: un archivo por pieza —variables, línea base, modelo, medición—, `uv run`,
sin capas. Cuatro archivos y no uno, porque la línea base **no puede importar sklearn** y eso
es una frontera de diseño, no de organización.

```bash
uv run --with scikit-learn==1.9.1 python bench_baseline.py --datos data
```

### 5.1 Las variables, con su pregunta al lado

```python
# src/ds07-scikit-learn/features.py

# Las cinco variables honestas: todas se conocen el día que se agenda la cita.
HONEST = ["inasistencias_previas", "jueves_tarde", "lluvia_mm", "distancia_km",
          "dias_desde_agendamiento"]

# ⚠️ La sexta, que **no** se conoce: es el total del histórico del paciente, futuro incluido.
LEAKY = "inasistencias_totales_paciente"
```

**Detalles con intención**

- **`jueves_tarde` se deriva aquí y no en el generador.** Dónde se pone el corte de "tarde" es
  una decisión de modelado y tiene que poder discutirse; enterrarla en los datos la vuelve un
  hecho.
- **El historial entra topado en 3.** La tercera inasistencia ya no dice lo que dijo la
  segunda, y el generador lo sabe porque así se calibró. Sin el tope, el modelo gasta capacidad
  en distinguir al paciente de siete faltas del de nueve.
- **El objetivo es *no asistir*.** Con el objetivo invertido, "todos asisten" saca 100% de
  recall y parece un modelo.

### 5.2 El corte, que sale del manifiesto

```python
def cutoff_of(data: Path) -> date:
    manifest = json.loads((data / "manifiesto.json").read_text(encoding="utf-8"))
    return date.fromisoformat(manifest["corte_temporal"])


def split_temporal(rows, cutoff):
    limit = cutoff.isoformat()
    return ([row for row in rows if row["fecha"] < limit],
            [row for row in rows if row["fecha"] >= limit])
```

El corte vive en el conjunto de datos, no en el código. Así `ds07`, `ds08` y `ds09` parten por
la misma fecha y sus números se pueden poner en la misma tabla: **una constante repetida en
tres archivos es una constante que va a divergir**.

### 5.3 El `Pipeline`, y por qué el escalado va dentro

```python
    pipeline = Pipeline([
        ("escala", StandardScaler()),
        ("modelo", LogisticRegression(max_iter=1000, solver="lbfgs")),
    ])
    pipeline.fit(matrix, target)
```

Si la media y la desviación se calcularan sobre el conjunto completo **antes** de partir, el
escalado habría visto el tramo de prueba. Es una fuga más sutil que la de la sección 4 —no
regala tanto AUC— y es silenciosa igual. El `Pipeline` existe exactamente para esto: todo lo
que se ajusta con datos de entrenamiento vive dentro y viaja con el modelo.

Y los pesos que aprende, sobre datos ya escalados:

```
  inasistencias_previas       +0.554
  jueves_tarde                +0.101
  lluvia_mm                   +0.946
  distancia_km                +0.441
  dias_desde_agendamiento     +0.128
```

Los cinco positivos: todo lo que está ahí **sube** el riesgo de faltar. Eso es una frase que
Marcela entiende, y es media razón para preferir este modelo — una red neuronal no tiene nada
equivalente que enseñar.

> ⚠️ **Y la trampa de leer coeficientes:** están sobre datos escalados, así que miden efecto
> **por desviación estándar**, no importancia causal. `lluvia_mm` sale con el peso más alto
> porque llueve mucho y muy variable; `inasistencias_previas` sale menor porque casi todo el
> mundo tiene cero o uno. Que la lluvia "pese más" no significa que llover sea más importante
> que faltar antes: significa que la lluvia varía más.

### 5.4 El experimento que rompe a propósito

```bash
# Las cinco honestas
AUC 0.799
# Las cinco más `inasistencias_totales_paciente`
AUC 0.862
```

Una columna, seis puntos y medio, cero errores. **Y la tercera tabla de la sección 6 muestra
que la fuga infla igual con las tres formas de partir el histórico**: no es un problema de
partición, es un problema de columnas.

**El patrón a memorizar**
> Antes de mirar una métrica, tres preguntas: ¿contra qué línea base?, ¿esta columna estaba
> disponible antes del evento?, y ¿a cuántos casos marca? Si falta alguna, el número no se
> reporta.

**Prueba de fuego**

```bash
uv run --with scikit-learn==1.9.1 --with pytest pytest -q
```

Treinta y ocho pruebas: diecinueve del generador y diecinueve de aquí. Las de las métricas y
la regla **no importan sklearn**, y eso no es comodidad: la línea base no puede depender de la
biblioteca contra la que compite, o la cuarta tabla de la sección 6 sería mentira.

La mentira que te va a contar la salida si miras el lugar equivocado: el AUC de 0,799 es de
**todo el tramo de prueba**. Yuli no va a llamar a todo el tramo de prueba: va a llamar al 20%
de un día. La segunda tabla de la sección 6 es la que importa para esa conversación, y ahí los
números son otros y más bajos.

---

## 📏 6. Medición

**Hipótesis.** Que la regresión logística de cinco variables le gana a la regla de tres, que
la fuga infla el AUC de forma visible, y que el costo de mantener el modelo es despreciable
para el uso que Áurea le va a dar.

**Condiciones.** CPython 3.14.5, scikit-learn 1.9.1; macOS 26.6.2 sobre Apple Silicon de 8
núcleos. Histórico de ausentismo con semilla 20260913: **105.620 citas de 12.400 pacientes**.
Corte temporal en **2025-10-01**, tomado del manifiesto: **72.396 citas para entrenar y 33.224
para probar**, con 19,9% de inasistencia en el tramo de prueba. Umbral por capacidad del 20%,
que es la media mañana de Yuli. Ninguna de las cuatro tablas usa el tramo de prueba para
decidir nada.

**Competidores.** El piso absoluto —"todos asisten"— y la regla de tres variables, que es lo
que Patricia hace hoy en la cabeza. No son hombres de paja: la regla usa las tres variables que
cualquiera nombraría y está escrita para funcionar, no para perder.

### 6.1 Discriminación y operación

| Candidato | AUC | Marcadas | Precisión | Recall |
|---|---|---|---|---|
| siempre asiste | 0,500 | 33.224 (100%) | 0,199 | 1,000 |
| regla de 3 variables | 0,672 | 9.712 (29%) | 0,351 | 0,516 |
| **logística de 5** | **0,799** | **6.645 (20%)** | **0,526** | **0,530** |
| logística + FUGA | 0,862 | 6.645 (20%) | 0,588 | 0,592 |

### 6.2 Tres formas de partir el mismo histórico

| Partición | Variables honestas | Con la columna con fuga |
|---|---|---|
| temporal (la correcta) | 0,799 | 0,862 |
| al azar | 0,799 | 0,859 |
| por paciente | 0,798 | 0,856 |

### 6.3 Lo que cuesta mantener cada una

| | |
|---|---|
| Regla · 33.224 filas | 7,5 ms |
| Logística · entrenar | 143,8 ms |
| Logística · 33.224 filas | 45,8 ms |
| Artefacto serializado | 1,2 KB |
| Arranque del intérprete | 29 ms |
| Arranque **+ import de sklearn** | 857 ms |
| Líneas de código · regla | 8 |
| Líneas de código · modelo + variables | ~50 |

```bash
uv run --with scikit-learn==1.9.1 python bench_baseline.py --datos data
```

> ⚖️ **Veredicto — y son cuatro.**
>
> **1. El modelo gana, y gana claro.** 0,799 contra 0,672 de AUC, y donde de verdad importa:
> a la misma capacidad del 20%, la logística acierta **0,526 de precisión contra 0,351** — de
> cada diez llamadas de Yuli, cinco aciertan en vez de tres y media. **Es un 50% más de
> aciertos por el mismo tiempo de trabajo**, y eso paga las cuarenta y dos líneas de más.
>
> **2. La regla tiene un problema que el AUC no muestra: no puede operar a capacidad.** Le
> pides que marque el 20% y marca el **29%**, porque con cuatro puntajes distintos el umbral
> cae dentro de un bloque de empates y arrastra el bloque entero. Yuli no tiene media mañana y
> media: tiene media. Una regla discreta no se puede sintonizar, y eso es una limitación
> operativa que ninguna métrica de discriminación revela.
>
> **3. La fuga regala 0,063 de AUC, y lo hace con cualquier partición.** La tercera tabla es
> el hallazgo metodológico de la sección: **el problema de la fuga es de columnas, no de
> partición**, y por eso no se arregla partiendo mejor.
>
> **4. Y el resultado que contradice al manual, que es el que más vale:** en este conjunto,
> **partir al azar da exactamente el mismo AUC que partir por fecha** (0,799 contra 0,799).
> No hay inflación. La razón está en los datos y se puede decir: **el proceso que los genera
> no tiene deriva** —las mismas variables pesan lo mismo en 2024 y en 2026—, así que mezclar
> el tiempo no aporta información. Eso **no vuelve legítimo el atajo**: lo que hace peligrosa
> a la partición al azar es que **te impide enterarte de si tu conjunto tiene deriva**. La
> partición temporal es la que detecta el problema; la aleatoria es la que lo esconde. Aquí no
> había nada que esconder, y solo se sabe porque se partió por fecha.
>
> **El umbral, dicho como criterio:** el modelo se justifica mientras la ganancia en precisión
> a la capacidad real supere el costo de mantenerlo. Aquí la ganancia es del 50% y el costo es
> 1,2 KB de artefacto y 144 ms de entrenamiento mensual: no hay discusión. El día que la
> ganancia baje a dos o tres puntos, la regla de ocho líneas vuelve a ser la respuesta — y
> `ds08` va a poner exactamente esa pregunta sobre la mesa con una red neuronal.

> 📝 **Lo que esta medición no dice.** No mide si llamar sirve: el conjunto tiene quién falta,
> no qué pasa cuando Yuli llama. **Ese es el experimento que falta y es el mismo de `ds04`** —
> sin él, todo lo de esta sección predice y nada demuestra que intervenir cambie algo. No mide
> deriva en el tiempo, porque el generador no la tiene **por construcción**, así que la tabla
> 6.2 no puede mostrar el efecto que la literatura describe; sobre datos reales de Áurea habría
> que volver a hacerla. Y no mide calibración —si el modelo dice 0,3 ¿falta el 30%?—, que es lo
> que hace falta para sobreagendar con criterio y llega en `ds08`.

---

## 🧱 7. Miniproyecto — La lista de Yuli

**El encargo.** Yuli te dice: *"Cada mañana, antes de abrir, quiero una lista de a quiénes
llamo hoy. No más de veinte, porque es lo que me da el tiempo, y quiero saber por qué está
cada uno en la lista — si le digo a una señora que la llamo 'porque el sistema dice', me
cuelga."*

**Por qué duele.** Porque el modelo da un puntaje y Yuli necesita **una razón en español**, y
la razón tiene que ser verdadera: no vale inventar una explicación bonita para un número que
salió de cinco coeficientes. Y porque veinte es un límite duro que obliga a elegir, no a
ordenar.

**Datos de entrada.** El histórico de ausentismo, y la agenda del día siguiente —constrúyela
tomando las citas de una fecha del tramo de prueba—. El caso sucio está en los datos y es
este: **hay pacientes en su primera cita**, sin historial. El modelo les da el puntaje que
corresponde a "cero inasistencias previas", que es el mismo de un paciente con veinte citas
perfectas. Decide si eso está bien y defiéndelo.

**Criterios de aceptación.**

1. `python lista.py --fecha 2026-01-15 --cupo 20` imprime como máximo veinte filas, ordenadas
   por riesgo, con paciente, hora, sede y **una razón**.
2. La razón se deriva de las variables del caso, no de una plantilla fija: *"faltó 2 de sus
   últimas 6 citas y vive a 18 km"* es una razón; *"riesgo alto"* no lo es.
3. El programa reporta, sobre el mismo día, **cuántas de las citas que no marcó terminaron en
   inasistencia**. Es el costo de la decisión, y va en la salida, no escondido.
4. Si la agenda del día tiene menos de veinte citas de riesgo por encima de un mínimo que tú
   fijas, la lista es **más corta**. Rellenar hasta veinte con gente de riesgo bajo le hace
   perder la mañana a Yuli.
5. Una prueba compara tu lista con la que produciría la regla de tres variables sobre el mismo
   día, y reporta en cuántos nombres coinciden. Si coinciden en dieciocho de veinte, esa es una
   conclusión y hay que escribirla.
6. El modelo se entrena **una vez** y se guarda; la lista diaria lo carga. Reentrenar cada
   mañana con los datos de la mañana es la trampa de este miniproyecto.

**Restricciones de registro.** Script: un archivo para entrenar y guardar, otro para la lista
del día. `argparse`, salida en texto. Una sola dependencia: scikit-learn.

**La trampa.** El criterio 6, y es de las que se descubren tarde. Vas a querer reentrenar con
todo lo disponible cada día —suena mejor, "usa más datos"— y el día que lo hagas vas a estar
entrenando con las citas de hoy para predecir las citas de hoy. **El día que entrena y el día
que predice tienen que estar separados**, siempre, también en producción.

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

Son dos programas con vidas distintas: uno corre una vez al mes y deja un archivo, otro corre
cada mañana y lo lee. Escribirlos como uno solo es lo que produce la trampa del criterio 6.
</details>

<details><summary>Pista 2 — la herramienta</summary>

Para guardar el pipeline entrenado, `pickle` de la biblioteca estándar sirve — con la
advertencia de la Fase 16 sobre lo que significa cargar un `pickle`, que `ds09` va a cobrar.
Para la razón, mira los coeficientes y la contribución de cada variable al puntaje de ese caso
concreto: `coef_ * valor_escalado`.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def train_and_save(data: Path, target: Path, cutoff: date) -> None: ...
def daily_list(model_path: Path, agenda: list[dict], capacity: int) -> list[Call]: ...
def explain(row: dict, contributions: dict[str, float]) -> str: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-07 -m "Mini ds07: lista de Yuli · precisión <X> a cupo 20 · coincide con la regla en <N>/20"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre la medición y reproduce la tabla 6.1. Después baja la capacidad al 10% y mira cómo se
   mueven precisión y recall. Escribe la frase que le dirías a Yuli.
2. Calcula la exactitud de los cuatro candidatos. Ordénalos por exactitud y después por AUC:
   el orden cambia, y ese es el ejercicio.
3. Quita `jueves_tarde` de las variables y mide. Compara la pérdida con el coeficiente que
   tenía.
4. Entrena con las cinco variables sobre el tramo de **prueba** y evalúa sobre el mismo. El
   AUC que salga es el que reporta quien no parte los datos.
5. Cambia el objetivo a "asistió" en vez de "no asistió" y mira qué pasa con precisión y
   recall. Explica por qué el AUC no cambia.
6. Mide cuánto tarda `import sklearn.linear_model` en tu máquina y compáralo con el arranque
   del intérprete solo.

**🟡 Intermedio (7–14)**

7. Saca el `StandardScaler` del `Pipeline` y ajústalo sobre el conjunto completo antes de
   partir. Mide la diferencia de AUC. Va a ser pequeña: explica por qué sigue siendo un error.
8. Añade `sede` como variable categórica con `OneHotEncoder` dentro del `Pipeline`. Mide, y
   decide si las diez columnas nuevas se justifican.
9. Grafica precisión y recall contra la capacidad, de 5% a 50%. Ese gráfico es la conversación
   con Yuli, y `ds05` dice cómo dibujarlo.
10. La regla usa tres variables. Escribe una de cuatro que incluya la distancia y mide si le
    gana. Si le gana, la brecha con la logística se cierra: reporta cuánto.
11. Calcula el AUC con `sklearn.metrics.roc_auc_score` y compáralo con la implementación de
    `baseline.py`. Tienen que coincidir; si no, encuentra cuál está mal.
12. Entrena con solo los primeros seis meses y evalúa en el tramo de prueba de siempre.
    Después con doce, con dieciocho. ¿Cuántos datos hacen falta de verdad?
13. La validación cruzada estándar vuelve a mezclar el tiempo. Busca `TimeSeriesSplit`,
    aplícala, y explica qué garantiza y qué no.
14. Reproduce la tabla 6.2 en tu máquina. Si en la tuya la partición al azar sí infla, eso es
    un hallazgo sobre tu conjunto y hay que escribirlo.

**🟠 Difícil (15–21)**

15. Diagnóstico: un compañero reporta AUC de 0,93 con las mismas cinco variables. Enumera las
    tres formas más probables de llegar a esa cifra por error, y escribe la comprobación que
    detecta cada una.
16. Introduce deriva en el conjunto a propósito —cambia el peso de una variable a partir de
    2025— regenerando con un parámetro nuevo, y vuelve a correr la tabla 6.2. **Ahora la
    partición al azar debería inflar**: mide cuánto. Es el experimento que esta sección no
    pudo hacer.
17. Mide la calibración: agrupa las predicciones en deciles y compara la probabilidad predicha
    con la frecuencia real. Si el modelo dice 0,3, ¿falta el 30%?
18. Implementa la explicación por caso del miniproyecto —la contribución de cada variable al
    puntaje— y comprueba en tres ejemplos que la suma de contribuciones reconstruye el puntaje.
19. **De registro.** La lista diaria de Yuli corre a las 6:30 de la mañana. ¿Script con cron,
    comando de `aur` o tarea del cierre nocturno de la Fase 15? Decide con el costo de las
    otras dos y con el número de arranque de sklearn en la mano.
20. Cambia la capacidad a 20 llamadas **por sede** en vez de 20 en total. Mide qué le pasa a la
    precisión global y explica por qué.
21. El modelo no sabe nada de pacientes nuevos. Mide su rendimiento solo sobre citas de
    pacientes sin historial y decide si para ellos la regla no sería mejor.

**🔴 Muy difícil (22–25)**

22. **Defiende lo contrario.** Construye el caso, con los datos de Áurea, para desplegar la
    regla de ocho líneas en vez del modelo. Tiene que incluir el costo de mantenimiento a dos
    años y quién queda a cargo cuando tú no estés.
23. Diseña el experimento que falta: llamar o no llamar, aleatorizado, para medir si la llamada
    reduce la inasistencia. Especifica a cuántos pacientes, por cuánto tiempo, qué se mide y
    **cuántos casos hacen falta** para detectar una reducción de cinco puntos —el cálculo está
    en `src/ia06-evaluacion/statistics_helpers.py`—.
24. 🔥 Entrena un gradiente potenciado (`HistGradientBoostingClassifier`) con las mismas cinco
    variables y mídelo contra la logística. Es el competidor real de `ds08`, no la red neuronal,
    y su resultado debería estar en esta sección.
25. **De registro.** Áurea quiere el puntaje dentro de AgendaAPI, en el momento de agendar, para
    sugerir otra hora. Decide si el modelo se sirve, se precalcula o no se hace, con la tabla
    6.3 delante. Es la pregunta que abre `ds09`.

**🔥 Opcionales**

- Mira qué hace `class_weight="balanced"` y decide si en este problema ayuda o solo mueve el
  umbral que ya estás eligiendo por capacidad.
- Reemplaza la logística por un árbol de decisión de profundidad 3 e imprímelo. Es el modelo
  más parecido a la regla que existe, y se puede leer en voz alta.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://scikit-learn.org/1.9/modules/compose.html](https://scikit-learn.org/1.9/modules/compose.html)
  — `Pipeline`, y por qué el preprocesamiento va dentro. La página central de esta sección.
- [https://scikit-learn.org/1.9/common_pitfalls.html](https://scikit-learn.org/1.9/common_pitfalls.html)
  — los errores comunes, con la fuga de datos explicada por los propios autores. **Es la
  lectura obligatoria de la sección.**
- [https://scikit-learn.org/1.9/modules/cross_validation.html#time-series-split](https://scikit-learn.org/1.9/modules/cross_validation.html#time-series-split)
  — `TimeSeriesSplit`, para el ejercicio 13.
- [https://scikit-learn.org/1.9/modules/model_evaluation.html](https://scikit-learn.org/1.9/modules/model_evaluation.html)
  — las métricas, con la advertencia sobre exactitud en clases desbalanceadas.
- [https://scikit-learn.org/1.9/modules/calibration.html](https://scikit-learn.org/1.9/modules/calibration.html)
  — calibración, que es el ejercicio 17 y el tema de `ds08`.

**Del propio curso**

- `src/ia06-evaluacion/statistics_helpers.py` — `required_sample_size`, para el ejercicio 23.
- [`ds04-embudo.md`](ds04-embudo.md) §6 — el mismo problema del contrafactual, en el otro
  proyecto. Aquí y allí la respuesta de verdad es un experimento.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan
> números de página, ISBN ni identificadores de video que no se hayan comprobado.

**Orden de lectura sugerido.** Antes de escribir código: *common pitfalls*, entera, que son
veinte minutos y te ahorra los tres errores de la sección 4. Durante: la de `Pipeline`. Después:
la de calibración, que es lo que te va a faltar en cuanto alguien pregunte *"¿y cuánto de
seguro?"*.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con dos líneas base publicadas, un modelo que les gana con claridad, y la disciplina
que hace que ese "les gana" signifique algo. También con dos hallazgos que no estaban en el
guion: **la regla no puede operar a capacidad** porque empata demasiado, y **partir al azar no
infló nada aquí** —lo que obliga a explicar por qué la partición temporal sigue siendo la
correcta, que es una explicación mejor que la que había—.

`ds08` cierra el proyecto Ausentismo con la pregunta que el track lleva anunciando desde el
principio: **una red neuronal sobre estos mismos datos, ¿le gana a esta logística?** La
hipótesis de la historia de Áurea dice que no, y ahora hay contra qué medirlo: 0,799 de AUC,
0,526 de precisión a capacidad del 20%, 1,2 KB de artefacto y 144 ms de entrenamiento.

Y trae la parte que no es técnica y que es la más importante del track: **qué se hace con la
predicción**. Recordarle más al paciente señalado es legítimo. Llamarlo el día anterior,
también. Darle peor horario porque el modelo lo señaló, no — y esa línea se dibuja antes de
que alguien la cruce sin darse cuenta.

> **La señal de que quedó bien:** cuando ante cualquier métrica tu primera pregunta sea *"¿y
> qué saca la regla tonta?"*, y cuando ante una columna nueva preguntes *"¿cuándo se llena
> este campo?"* antes que *"¿cuánto mejora el AUC?"*.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-07 -m "ds07 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 07: …`), los de ejercicio su número
> (`ds 07 ej12: …`) y el miniproyecto el suyo (`ds 07 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `ds-mini-07`, con **la precisión a cupo 20 y cuántos nombres
> coincide con la regla** en el mensaje. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
