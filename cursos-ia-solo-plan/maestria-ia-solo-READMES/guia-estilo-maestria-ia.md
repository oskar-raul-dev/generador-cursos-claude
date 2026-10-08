
# ✍️ Guía de estilo, tono y convenciones
## Maestría autodidacta en Inteligencia Artificial — Pista A + Pista B

Esta guía es la **fuente de verdad editorial** de todos los documentos que
produzca este proyecto: capítulos de fase, apéndices, hojas de ejercicios,
soluciones, notas de lectura y post-mortems de proyecto. Cualquier chat que
genere un `.md` la sigue.

Su objetivo es que decenas de documentos escritos en ~30 meses se lean como
escritos por la misma mano, y que ninguno se convierta en relleno bonito que
no ayuda a reconstruir fluidez real.

Documentos hermanos:

- `Curriculo_Maestro_IA_v2.md` — el plan (fases, temario, bibliografía, proyecto tesis).
- `perfil_personal.md` — restricciones reales (6 h/semana, presupuesto, dominios).
- `GLOSARIO-CODIGO.md` — diccionario de identificadores del proyecto tesis (§5.3).
- `NOTACION-MATEMATICA.md` — convenciones de símbolos y traducción entre libros (§6).

> 🧭 **Regla de una línea que rige todo:** el **código y la notación en inglés
> estándar**; todo lo demás —narrativa, comentarios, ejercicios, títulos— en
> **español latinoamericano con tuteo**. El detalle está en §4 y §5.

---

## 1. Principio rector

**Todo lo que se escribe apunta a que puedas reconstruirlo sin el documento
delante.** El criterio de avance del currículo no es terminar el capítulo: es
poder explicar el concepto sin notas y reescribir el código desde cero
(estándar tipo Feynman/Karpathy). Un párrafo que no acerca a eso, sobra.

De ahí se derivan tres consecuencias que atraviesan toda la guía:

1. **El "por qué" antes que el "cómo".** Ningún bloque de código aparece antes
   de que quede claro qué problema resuelve y por qué esa es la forma de
   resolverlo. Si el orden se invierte, el documento está mal escrito.
2. **Nada se entrega resuelto de entrada.** Las soluciones viven en archivos
   aparte, con pistas escalonadas (§10.3). Un capítulo que trae la solución
   pegada al ejercicio incumple la regla 1 del proyecto.
3. **Honestidad sobre lo que no sabemos.** Resultados negativos, límites de un
   método y cifras no verificables se declaran (§12). Es la diferencia entre
   documentación y marketing.

---

## 2. Perfil del lector (a quién le hablas)

Escribes para **una sola persona con un perfil muy específico**. Darlo por
sentado es lo que evita explicar de más y explicar de menos:

**Lo que ya sabe y no se explica nunca:**
programación (más de una década), diseño de APIs, HTTP, JSON, SQL básico,
git, modelado relacional, despliegue, estructuras de datos, complejidad
algorítmica, testing, lectura de código ajeno. Nada de "qué es una función" ni
"qué es un endpoint". Explicarle esto es condescendencia.

**Lo que tuvo y perdió (y es el eje de la Fase 0):**
cálculo, álgebra lineal y probabilidad de nivel universitario, ~20 años sin
ejercitarse. **Los conceptos los reconoce; la fluidez mecánica no está.** Por
eso el tratamiento matemático nunca es "esto es una derivada", pero tampoco
salta pasos: se muestran las manipulaciones completas, porque lo que se está
reconstruyendo es justamente la capacidad de producirlas.

**Lo que es nuevo de verdad:**
la maquinaria estadística y de aprendizaje, la notación de ML (que no es la de
un curso de cálculo), el criterio de evaluación de modelos, y el andamiaje de
producción propio de IA.

**Su restricción real:** 6 horas por semana, en sesiones de 60-90 minutos. Un
capítulo que solo se puede leer de corrido en cuatro horas está mal
dimensionado (§8.2).

---

## 3. Tono

El tono es **semiformal, de tuteo, español latinoamericano neutro**: un colega
con más recorrido en el tema explicándote algo con precisión, sin acartonarse
y sin palmaditas en la espalda.

- **Tuteo siempre, nunca voseo ni "usted".** "Deriva esto a mano y compara",
  no "derivá esto" ni "derive usted esto". Tampoco el plural falso de manual
  ("procedemos a calcular") salvo cuando de verdad hablamos de una decisión
  compartida del proyecto ("acá decidimos usar DuckDB porque…").
- **Español neutro de América Latina.** Nada de "ordenador", "coger", "vale",
  "chaval", "zumo". Usa "computadora", "tomar", "de acuerdo", "archivo",
  "arreglo" (o "array", que es el nombre real). Evita también localismos
  fuertes de un solo país; el registro es el de la documentación técnica
  regional.
- **Semiformal.** Se permite una figura, una ironía seca ocasional, un emoji de
  callout (§7). No se permite el registro de coach ("¡tú puedes!"), ni la
  solemnidad de manual corporativo, ni el humor como relleno. Si dudas entre
  un chiste y una frase precisa, va la frase precisa.
- **Honesto sobre lo difícil.** Cuando algo es genuinamente duro (la primera
  derivación de backprop, el pipeline de aggregation, la identificación causal)
  se dice: "esto cuesta la primera vez y es normal releerlo dos veces". No se
  finge que todo es intuitivo.
- **Sin promesas.** Nada de "vas a dominar el deep learning en esta fase". El
  criterio de éxito es siempre el criterio de salida del currículo, medible y
  escrito.

> 🪞 **Matiz propio de este currículo.** El lector no llega en blanco: llega
> con instintos de ingeniero de software backend. Muchos le sirven (§7.2, 🩻)
> y algunos lo traicionan (§7.2, 🪞): "un modelo con 95% de accuracy funciona"
> es el equivalente de aquí al "`$lookup` es un JOIN gratis". Nunca se
> ridiculiza el instinto de ingeniería: se lo reconoce y se lo recalibra.

---

## 4. Idioma y forma de la narrativa

- Español para todo lo que no es código ni notación: títulos, explicaciones,
  ejercicios, criterios de salida, referencias comentadas.
- Los términos técnicos se dejan en inglés cuando ese es su nombre real:
  *overfitting*, *bias-variance tradeoff*, *learning rate*, *embedding*,
  *feature*, *baseline*, *drift*, *prompt*, *fine-tuning*, *pipeline*,
  *forward/backward chaining*, *confounder*, *policy*, *reward*. No se
  traducen a la fuerza. Cuando exista una traducción realmente asentada
  (verosimilitud, sesgo, varianza, gradiente, entropía, aprendizaje
  supervisado), se usa la española.
- **Primera aparición:** término en español seguido del inglés entre
  paréntesis, y de ahí en adelante uno solo, el que sea más usual.
  "máxima verosimilitud (maximum likelihood, MLE)" → luego "MLE".
- Markdown siempre. Encabezados con emoji **con moderación**: uno por sección
  de plantilla (§8), y los emoji-tipo de callout donde aporten (§7).
- **Prosa antes que listas.** Se razona en párrafos. Las listas son para cosas
  que de verdad son listas: pasos de un algoritmo, ítems paralelos, supuestos.
- **Tablas solo para comparar, decidir o mapear.** "Cuándo usar L1 vs L2",
  "notación de Goodfellow ↔ notación de ISLR", "método causal ↔ supuesto que
  exige". Nunca para narrar.
- **Longitud de párrafo:** 3-6 líneas. Un muro de doce líneas se parte.

---

## 5. Idioma del código fuente

Normativa para **todo** fragmento de código de cualquier documento.

### 5.1 Regla general

| Capa | Idioma | Ejemplo |
|---|---|---|
| Identificadores (funciones, variables, clases) | 🇬🇧 Inglés | `def compute_gradient(x, y)`, `learning_rate = 0.01` |
| Nombres de archivo y módulo | 🇬🇧 Inglés | `linear_regression.py`, `eta_features.py` |
| Columnas de dataset y campos de esquema | 🇬🇧 Inglés | `order_id`, `delivered_at`, `zone_id`, `stock_on_hand` |
| Constantes | 🇬🇧 Inglés, `SCREAMING_SNAKE_CASE` | `RANDOM_SEED`, `MAX_ITERATIONS` |
| Comentarios de código | 🇪🇸 Español | `# la regularización va sobre los pesos, no sobre el bias` |
| Salidas legibles para humanos (`print`, gráficas, labels) | 🇪🇸 Español | `print("Error de validación:", mse)` |
| Narrativa del capítulo | 🇪🇸 Español | Todo lo que está fuera del bloque de código |

> 📝 **Por qué.** El código de ML real, sus librerías y su documentación están
> en inglés; nombrar tus variables igual que la literatura reduce fricción al
> leer papers y repos. Los comentarios en español, en cambio, existen para que
> **tú** entiendas tu decisión seis meses después, que es cuando vas a volver.

### 5.2 Convenciones de nombrado matemático en código

Cuando el código implementa una fórmula, los nombres **siguen la fórmula**, no
el estilo "descriptivo" de aplicación:

```python
# En una derivación matemática, X, y, w, b son los nombres correctos:
# reflejan la notación del libro y hacen el código verificable contra él.
y_pred = X @ w + b
grad_w = (2 / n) * X.T @ (y_pred - y)
```

En cambio, cuando el código es de **aplicación** (pipeline, servicio, ETL), los
nombres son descriptivos y de dominio: `delivery_features`, `restock_threshold`.
La regla: *notación donde hay matemática, dominio donde hay negocio.*

### 5.3 Diccionario del dominio (proyecto tesis)

El proyecto tesis del currículo es una **plataforma de operaciones logísticas e
inventario retail**. Los términos centrales se fijan acá y no cambian entre
fases (el diccionario extendido vive en `GLOSARIO-CODIGO.md`):

| Español (narrativa) | Inglés (código y datos) |
|---|---|
| pedido | `order` |
| ruta | `route` |
| entrega | `delivery` |
| repartidor | `courier` |
| zona | `zone` |
| inventario / existencias | `inventory` / `stock` |
| demanda | `demand` |
| reabastecimiento | `restock` |
| tiempo estimado de entrega | `eta` |
| retraso / entrega tardía | `delay` / `late_delivery` |
| quiebre de stock | `stockout` |
| producto | `product` / `sku` |

Estados y enums en inglés y `snake_case`: `pending` → `assigned` →
`in_transit` → `delivered` / `failed`. Nunca `'entregado'` como valor en datos.

### 5.4 Ejemplos de código: simples y ejecutables

Esta es la regla que más se incumple, así que va explícita:

- **Máximo ~25 líneas por bloque.** Si necesitas más, es que el bloque hace dos
  cosas: pártelo y narra entre medio.
- **Sin andamiaje decorativo.** Nada de clases, decoradores, `argparse`,
  logging estructurado ni abstracciones "por si acaso" dentro de un ejemplo
  pedagógico. Función suelta y datos mínimos.
- **Corre tal cual, copiado y pegado.** Nada de pseudocódigo "que se entiende",
  ni `...` en medio, ni imports implícitos. Si el bloque necesita `import numpy
  as np`, va en el bloque (o se declara una vez al inicio del capítulo).
- **Stack por defecto:** Python 3.11+, NumPy, Pandas, Matplotlib,
  scikit-learn, PyTorch (Fase 3 en adelante), DuckDB + Parquet (Fase 1.5 en
  adelante). Cualquier dependencia fuera de esa lista se justifica en el texto.
- **Reproducible:** semilla fija y explícita cuando haya aleatoriedad
  (`RANDOM_SEED = 42`), y se dice por qué importa la primera vez.
- **Una gráfica, un mensaje.** Matplotlib puro, sin estilos ni paletas
  personalizadas, con ejes etiquetados en español.
- **Con verificación incorporada.** Todo ejemplo que implementa algo "desde
  cero" incluye la comprobación contra la referencia:

```python
import numpy as np
from sklearn.linear_model import LinearRegression

# nuestra solución cerrada de mínimos cuadrados
w_ours = np.linalg.solve(X.T @ X, X.T @ y)

# la referencia: si esto no coincide, el error es nuestro, no de sklearn
ref = LinearRegression(fit_intercept=False).fit(X, y)
assert np.allclose(w_ours, ref.coef_, atol=1e-8)
```

- **Comentarios que explican el porqué, no el qué.**
  `# usamos solve en vez de inv: numéricamente más estable` sí;
  `# multiplica X por w` no.
- **Notebooks vs scripts.** La exploración se muestra como celdas sueltas; todo
  lo que sea pipeline, entrenamiento o servicio se muestra como script `.py`
  versionable. El currículo es explícito en que "notebook desordenado" es un
  anti-patrón (Fase 2), así que la guía no lo modela.

---

## 6. Matemáticas y notación

El eje diferenciador de este currículo frente a un tutorial cualquiera. Reglas:

- **LaTeX siempre**, inline con `$...$` y en bloque con `$$...$$`. Nada de
  matemáticas escritas con asteriscos y `^` sueltos.
- **Notación fijada en `NOTACION-MATEMATICA.md`** y respetada en todos los
  documentos: escalares en itálica minúscula ($x$), vectores en negrita
  minúscula ($\mathbf{x}$, columna por defecto), matrices en mayúscula
  ($\mathbf{X}$), conjuntos en caligráfica ($\mathcal{D}$), parámetros
  $\boldsymbol{\theta}$, gradiente $\nabla_{\boldsymbol{\theta}} L$.
- **Todo símbolo se define en su primera aparición del capítulo**, aunque sea
  obvio. La fluidez que se está reconstruyendo se apoya justo en eso.
- **Derivaciones completas, sin "se puede demostrar que".** Si un paso es
  largo, se muestra igual y se marca 🧮 (§7.2). Los saltos son exactamente lo
  que impide reproducir la derivación después.
- **Traducción entre fuentes.** Goodfellow, ISLR, CS229 y Bishop no usan la
  misma notación. Cuando un capítulo mezcla fuentes, incluye una tabla corta de
  equivalencias antes de la derivación. Esta es una de las causas reales de
  atasco y merece una tabla, no un pie de página.
- **Dimensiones anotadas.** En cada producto matricial no trivial se anota la
  forma: $\mathbf{X} \in \mathbb{R}^{n \times d}$. En código, el equivalente es
  un comentario o un `assert X.shape == (n, d)`.
- **De la fórmula al código, explícito.** Cuando una fórmula se implementa, el
  texto señala qué línea corresponde a qué término. Es el puente que el
  currículo llama "el traductor de matemática a notación de ML".

---

## 7. Marcadores y callouts

Vocabulario visual común a todos los documentos, para reconocerlo de un vistazo.

### 7.1 Marcadores de estado

- ⭐ **Núcleo.** Concepto o sección que el criterio de salida evalúa directamente.
- 🔥 **Opcional / ampliación.** Excede el alcance de la fase; se puede saltar sin deuda.
- 💸 **Deuda declarada.** Simplificación deliberada que una fase posterior paga.
  Se nombra dónde se paga (ej.: "el ETA de la Fase 2 ignora el clima; la
  Fase 1.5 ya dejó la columna lista y la Fase 3 la usa").
- 🟢🟡🟠🔴 **Dificultad de ejercicios** (§10).

### 7.2 Callouts en blockquote

- 🧮 **Derivación a mano.** El paso matemático completo, para hacer con lápiz
  antes de leer. Va marcado porque es donde se reconstruye la fluidez.
- 🪞 **"Tu instinto de ingeniero dice… y acá se equivoca."** Nombra la trampa
  antes de caer: optimizar accuracy con clases desbalanceadas, evaluar sobre
  los datos de entrenamiento, tratar un modelo como código determinista, creer
  que más datos siempre arregla el problema, confundir correlación con efecto.
- 🩻 **"Esto sí funciona igual."** Lo que tu experiencia previa te regala:
  versionado, tests, idempotencia, latencia, contratos de datos, revisión de
  código. Baja la ansiedad y ahorra tiempo.
- 📝 **Nota de contexto.** Por qué un método se ve como se ve, o por qué un
  paper de 2017 sigue siendo la referencia. Historia útil, no anécdota.
- ⚠️ **Advertencia.** Algo que rompe o que produce un resultado silenciosamente
  falso (fuga de datos entre train y test, escalar antes de partir, semilla no
  fijada, `explain()` sin datos representativos).
- 💡 **Truco que ahorra tiempo real.**
- 📚 **Referencia inline** justo donde surge la duda, con la ubicación exacta
  (§11).
- ⚰️ **Anti-patrón / caso de estudio.** El error hecho a propósito, medido, y
  después corregido. Ej.: el modelo con 95% de accuracy que no sirve; el
  pipeline que no se puede reejecutar; el capstone "ATHENA" con cifras
  inventadas.

### 7.3 Secciones narrativas recurrentes

- **El patrón a memorizar.** Una o dos frases que destilan la lección
  transferible del bloque.
- **Prueba de fuego.** Verificación concreta e inmediata: "borra el directorio
  de salida, corre `make pipeline`, y los números deben ser idénticos".
- **Detalles con intención.** Lista corta de decisiones deliberadas del bloque
  y su porqué ("usamos validación cruzada estratificada porque la clase
  positiva es el 3%").
- **Conexión con el proyecto tesis.** Obligatoria en cada capítulo de fase:
  qué pieza de la plataforma logística aporta este contenido (§13).
- **La señal de que quedó bien.** En el cierre, un criterio en forma de cita:
  "puedo derivar el gradiente en una hoja sin mirar y el código me da lo mismo
  que sklearn a 1e-8."

---

## 8. Plantilla obligatoria de cada capítulo

### 8.1 Las nueve secciones

Todo capítulo de fase produce un `.md` con exactamente estas secciones, en orden:

1. **🎯 Propósito** — qué problema resuelve este capítulo y por qué va acá y no
   antes. Puede abrir con la carencia que deja el capítulo anterior.
2. **📍 Punto de partida** — qué se da por sabido (con referencia al capítulo o
   fase donde se vio) y qué NO hace falta saber todavía.
3. **🧠 El porqué antes del cómo** — la idea central en prosa, sin fórmulas
   pesadas ni código. Si esta sección no se entiende sola, el capítulo falla.
4. **🧮 Desarrollo formal** — derivaciones completas, notación definida,
   supuestos explícitos. Acá viven los callouts 🧮, 🪞 y 🩻.
5. **💻 Implementación comentada** — el código mínimo ejecutable (§5.4), con la
   correspondencia fórmula ↔ línea, la **Prueba de fuego** y los **Detalles
   con intención**.
6. **⚠️ Errores comunes y diagnóstico** — qué se rompe típicamente, cómo se ve
   el síntoma, y cómo localizarlo. En ML muchos errores no explotan: producen
   un número plausible y falso. Esta sección existe sobre todo por eso.
7. **🧪 Ejercicios** — §10, con niveles y sin soluciones.
8. **📚 Referencias** — §11, con ubicación exacta y advertencia de vigencia.
9. **🚀 Cierre, criterio de salida y conexión** — qué debes poder hacer ahora,
   la **señal de que quedó bien**, el aporte al proyecto tesis, y qué sigue.

Los apéndices y hojas sueltas no siguen la plantilla: usan índice de salto
rápido + secciones cortas + una tabla "cuándo usar qué" + 5-10 ejercicios.

### 8.2 Dimensionamiento a 6 h/semana

Un capítulo se escribe pensando en **sesiones de 60-90 minutos**, no en una
lectura continua. En consecuencia:

- Cada capítulo declara al inicio su **presupuesto estimado** ("≈ 3 sesiones:
  1 de lectura y derivación, 1 de implementación, 1 de ejercicios").
- Las secciones 4 y 5 llevan **cortes explícitos de sesión** cuando son largas
  (`--- fin de sesión sugerido ---`), en un punto donde el estado mental se
  puede reconstruir al volver.
- Un capítulo que supera **~4 sesiones** se parte en dos. Es preferible tener
  más capítulos cortos que uno que nunca se termina.
- Cada capítulo termina con **3-5 preguntas de repaso** (§10.4) para
  repetición espaciada, porque el perfil declara reconstrucción de fluidez
  como objetivo, y la fluidez se sostiene con repaso, no con lectura.

---

## 9. Orientación a la práctica y anti-vibe-coding

El currículo declara explícitamente qué **no** es: "usa el LLM de moda para
generar código sin entenderlo". Eso se traduce en reglas editoriales concretas:

- **Nada de teoría suelta.** Si se explica regularización, se explica sobre el
  modelo de ETA con pocas rutas por zona, no en abstracto.
- **Ningún bloque de código aparece antes de su justificación.** Si un capítulo
  arranca con código y explica después, está mal ordenado.
- **Toda implementación "desde cero" tiene su verificación contra una
  referencia** (§5.4). Sin eso, no hay evidencia de haber entendido.
- **Se distingue siempre la capa.** Al depurar, importa saber si el problema
  está en los datos, en las features, en el modelo, en la métrica, en el split
  o en el servicio. Cuando un capítulo toca más de una, lo dice.
- **Cuando una herramienta hace algo por ti, se explica qué hace.** Autograd,
  `sklearn.Pipeline`, un optimizador: primero a mano, después el wrapper.
- **Si un enfoque propuesto es vibe coding disfrazado, el documento lo dice.**
  Señales típicas: pedir el código completo antes de plantear la métrica de
  evaluación; usar un LLM para generar features sin entender el dominio;
  "hacer un RAG" sin definir cómo se mide la recuperación. La redirección es
  siempre concreta: qué paso previo falta y en qué fase está.

---

## 10. Ejercicios

### 10.1 Cantidad y distribución

A 6 h/semana, la cantidad se calibra distinto que en un curso intensivo:

- **12 a 20 ejercicios por capítulo** (no por fase). Un apéndice, 5-10.
- Distribución orientativa para 16: **~5 🟢, ~5 🟡, ~4 🟠, ~2 🔴**, más los 🔥
  aparte y sin numeración continua.
- **Numeración continua con encabezado de rango:**

```
## 🧪 Ejercicios (16)

**🟢 Calentamiento (1–5)**
1. …

**🟡 Intermedio (6–10)**
6. …

**🟠 Difícil (11–14)**
11. …

**🔴 Muy difícil (15–16)**
15. …

**🔥 Opcionales**
- 🔥 …
```

El título lleva el conteo total: `## 🧪 Ejercicios (16)`.

### 10.2 Tipos de ejercicio (mezcla obligatoria)

Cada capítulo incluye al menos uno de cada uno de los tres primeros tipos:

- **🧮 Derivación a mano.** Papel y lápiz, sin computadora. Es el tipo que más
  se abandona y el que más sostiene la fluidez.
- **💻 Implementación.** Escribir el código, con la verificación incluida en el
  enunciado ("y comprueba que coincide con `sklearn` a `1e-8`").
- **🔍 Diagnóstico.** Se entrega un resultado sospechoso o un fragmento con un
  bug sutil y se pide localizar la causa. En ML esto es más formativo que
  construir: "este modelo tiene AUC 0.99 en validación; encuentra la fuga".
- **🧠 Conceptual.** Explicar, comparar o decidir con criterio. Se formula
  siempre de modo verificable, no como "reflexiona sobre".
- **🏗️ De proyecto.** Aporta una pieza real a la plataforma logística (§13).
  Uno por capítulo cuando corresponda, marcado claramente.

### 10.3 Cómo se enuncian y dónde están las respuestas

- **Accionables y verificables.** "Deriva $\partial L/\partial w_j$ para la
  regresión logística y verifica numéricamente con diferencias finitas" sí;
  "estudia el gradiente" no.
- **Enganchados al dominio** cuando el contenido lo permita: pedidos, rutas,
  repartidores, zonas, stock, demanda. Los mini-proyectos independientes de
  cada fase, en cambio, **varían de dominio a propósito** (lo pide el
  currículo): agro, salud operativa, movilidad, educación.
- **Las soluciones nunca van en el mismo archivo.** Viven en
  `SOLUCIONES-<capítulo>.md`, y dentro de cada solución el orden es siempre:

  1. **Pista** (una línea que desbloquea sin resolver).
  2. **Esquema** (los pasos, sin las cuentas ni el código).
  3. **Solución completa** (con la explicación de por qué esa y no otra).

  Cada nivel bajo un `<details>` propio, para que abrir uno no revele el
  siguiente.
- **Ningún enunciado adelanta su respuesta.** Ni con "recuerda que basta
  aplicar la regla de la cadena dos veces". Eso es la pista, y va en el otro
  archivo.

### 10.4 Preguntas de repaso (el mini-quiz de cierre)

Además de los ejercicios, cada capítulo cierra con **3-5 preguntas cortas de
repaso**, orales, sin respuesta en el documento. Sirven para repetición
espaciada: se responden al terminar, a la semana y al mes. Se formulan como
"explica…", "por qué…", "en qué caso…", nunca como opción múltiple.

---

## 11. Bibliografía y referencias

**Regla:** todo lo que se explica declara de dónde viene. Es una de las reglas
del proyecto, y acá se convierte en formato.

### 11.1 Trazabilidad inline

Cada bloque conceptual sustantivo cita su fuente del currículo, en línea, con
**la ubicación más precisa que sea verificable**:

> 📚 Esto está en Russell & Norvig, *AIMA* 4ª ed., cap. 3 (búsqueda informada),
> y con código ejecutable en el repo `aimacode/aima-python`.

> 📚 Derivación equivalente en CS229 (Andrew Ng), notas de regresión lineal;
> versión más aplicada en Géron, *Hands-On ML* 3ª ed., cap. 4.

Cuando el capítulo sale del currículo (un paper, un blog), se dice
explícitamente: *"esto no está en la bibliografía del plan; lo agrego porque…"*.

### 11.2 Formato de la sección de referencias

Cuatro subsecciones fijas, en este orden:

1. **Fuente principal** — el capítulo o lecture que cubre este contenido.
2. **Complementos** — video (curso, lecture y minuto aproximado si aplica),
   lecturas alternativas para el mismo tema con otra notación.
3. **Documentación oficial** — URL completa y clicable, con nota de versión.
4. **Orden de lectura sugerido** — una línea encadenando qué leer primero y qué
   dejar para después.

Se marca siempre **[GRATIS]** / **[PAGO]** siguiendo la bibliografía
consolidada del currículo, y se prefieren las ediciones oficiales gratuitas de
los autores (deeplearningbook.org, statlearning.com, mixtape.scunning.com,
incompleteideas.net, szeliski.org, mml-book.com).

### 11.3 Advertencias sobre citas

- **No se inventan números de página, DOIs, IDs de video ni minutajes
  exactos.** Si no se conoce con certeza, se cita el capítulo o la sección.
- Cuando se menciona un recurso concreto, se advierte que **URLs, títulos y
  ediciones cambian** y que conviene verificarlos.
- Herramientas de la Pista B (Claude Code, Codex, Ollama, Unsloth, MCP)
  cambian rápido: **siempre documentación oficial, nunca tutoriales viejos**, y
  se anota la fecha de consulta.

---

## 12. Honestidad intelectual

Regla propia de este currículo, heredada de su crítica al capstone "ATHENA":

- **Cero cifras inventadas.** Ningún tamaño de mercado, porcentaje de mejora o
  proyección de ingresos sin fuente verificable. Si no la hay, se omite.
- **Los resultados negativos se documentan igual.** Si la red neuronal de la
  Fase 3 no supera al gradient boosting de la Fase 2, eso se escribe, se
  analiza y se conserva. Es información real, no un fracaso a esconder.
- **Los supuestos se declaran, y también qué pasa si no se cumplen.**
  Especialmente en la Fase 2.5, donde el método vale lo que valen sus
  supuestos.
- **Las métricas son las que puedes medir tú mismo**: precisión, latencia,
  costo de inferencia, tiempo de reconstrucción del pipeline. No proyecciones.
- **Los límites de lo aprendido se nombran.** "Con esto ya puedes X; para Y
  todavía te falta la Fase Z" es una frase perfectamente válida y frecuente.
- **Adjetivos de marketing prohibidos:** revolucionario, líder, disruptivo,
  de última generación, world-class.

---

## 13. Coherencia entre documentos

- **Fuentes de verdad, en orden:** (1) instrucciones del proyecto,
  (2) `perfil_personal.md` (las restricciones reales mandan sobre cualquier
  ambición del plan), (3) `Curriculo_Maestro_IA_v2.md`, (4) esta guía y
  `GLOSARIO-CODIGO.md` / `NOTACION-MATEMATICA.md`, (5) capítulos ya
  entregados, (6) decisiones explícitas del chat actual.
- **No contradecir capítulos anteriores** ni en pedagogía ni en nombres. Si
  algo se renombra o se corrige, se dice explícitamente qué cambió y por qué.
- **El proyecto tesis es la costura.** El esquema de datos que define la
  Fase 1.5 (`orders`, `routes`, `deliveries`, `inventory`) es el mismo que
  usan las Fases 2 a 8. Ningún capítulo inventa columnas nuevas sin declararlo
  como extensión del esquema.
- **Cada fase construye su pieza solo cuando llega.** No se adelanta
  infraestructura "por si acaso": es exactamente el error que el currículo
  identifica en ATHENA.
- **Un capítulo no depende de contenido de fases posteriores.** Si lo
  necesita, o está mal ubicado, o se acota a una caja negra declarada como
  💸 deuda con su fase de pago.

---

## 14. Post-mortems del proyecto tesis

Cuando algo del proyecto se rompe o da un resultado engañoso, se documenta con
esta estructura de ocho puntos:

1. Síntoma (incluido el caso más peligroso: "el número se veía bien").
2. Pasos de reproducción.
3. Evidencia observable (métricas, curvas, distribuciones, `explain()`, logs).
4. Causa raíz.
5. Corrección.
6. Verificación de que no vuelve (test de datos, assert, split correcto).
7. Prevención.
8. Lectura sin culpabilización: se analiza el proceso, no la persona.

El tono acá baja un punto: sereno y analítico, sin humor.

---

## 15. Checklist antes de dar por cerrado un `.md`

- [ ] Sigue la plantilla de 9 secciones (o el formato de apéndice).
- [ ] Español latinoamericano, tuteo, tono semiformal; sin voseo ni "usted".
- [ ] El "por qué" aparece **antes** que cualquier código.
- [ ] Identificadores, campos y constantes en inglés; comentarios y salidas en español.
- [ ] Los bloques de código son ≤ ~25 líneas, corren tal cual y traen su verificación.
- [ ] La notación está definida y coincide con `NOTACION-MATEMATICA.md`; las derivaciones no saltan pasos.
- [ ] Cada bloque conceptual cita su fuente del currículo con ubicación verificable.
- [ ] 12-20 ejercicios numerados, con rangos 🟢🟡🟠🔴 equilibrados y mezcla de tipos (🧮 💻 🔍).
- [ ] **Ninguna solución en este archivo**; están en `SOLUCIONES-*.md` con pista → esquema → solución.
- [ ] 3-5 preguntas de repaso al cierre, sin respuestas.
- [ ] Declara presupuesto en sesiones y tiene cortes de sesión si es largo.
- [ ] Tiene sección de errores comunes y diagnóstico (incluidos los silenciosos).
- [ ] Declara la conexión con el proyecto tesis y no contradice el esquema de datos.
- [ ] Marca 💸 la deuda (con su fase de pago) y 🔥 lo opcional.
- [ ] Cero cifras inventadas; supuestos y límites declarados.
- [ ] Incluye "La señal de que quedó bien" y el criterio de salida en el cierre.
