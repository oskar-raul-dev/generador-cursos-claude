# 🚢 ds09 — Servir el modelo, y el ⚖️ veredicto del track

> Python para desarrolladores Java senior · Track `ds` · sección 9 de 9 🏁
> Depende de: `ds08`, Fase 10 (FastAPI), Fase 15 (el cierre nocturno), Fase 16 (`pickle`)
> Registro de esta sección: **aplicación** — endpoint, configuración y frontera
> Proyecto que avanza: Ausentismo — sale del portátil

---

## 🎯 1. Propósito

`ds08` dejó un modelo entrenado en un archivo de tu máquina. Esta sección lo pone donde sirve
—dentro de AgendaAPI, contestando por HTTP— y contesta las tres preguntas que aparecen en ese
camino: **en qué formato viaja, cuánto cuesta cargarlo, y quién lo vuelve a entrenar**.

La primera de las tres es de seguridad y el curso ya la abrió en la Fase 16: **un artefacto de
modelo es un ejecutable disfrazado de dato**. Aquí se cobra en el caso concreto.

Y después cierra el track: de los dos proyectos de datos que Áurea tenía planteados, **cuál
valía la pena y cuál no** — con las ocho mediciones ya ejecutadas de las secciones anteriores
sobre la mesa.

> 🧭 **La regla que ordena la sección: el modelo se despliega en un formato que solo sepa
> describir números.** Todo lo demás —latencia, tamaño, arranque— es secundario y se mide;
> esto es una decisión de seguridad y se toma antes de medir nada.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `export.py` produce el modelo en `pickle` y en ONNX, y **se niega a publicar** si los
      dos no predicen lo mismo.
- [ ] El endpoint `/riesgo` de AgendaAPI contesta con cualquiera de los dos backends, elegido
      por configuración y anunciado en `/salud`.
- [ ] Puedes demostrar en diez líneas que cargar un `.pkl` ejecuta código, y explicar por qué
      no hay validación previa posible.
- [ ] Sabes qué lleva dentro un `.pkl` que un `.onnx` no lleva, y lo comprobaste mirando los
      bytes.
- [ ] `bench_serving.py` mide los dos backends **sobre HTTP real**, con arranque en frío.
- [ ] Tienes escrito dónde vive el reentrenamiento y qué lo detiene.
- [ ] Puedes decir, con números, cuál de los dos proyectos de datos de Áurea valió la pena.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra

- **Servidores de modelos dedicados** —TorchServe, BentoML, Triton, KServe— → fuera del
  curso. Áurea tiene un modelo de seis coeficientes y una API que ya existe desde la Fase 10;
  montar una plataforma de servicio aquí es el anti-patrón que el track lleva ocho secciones
  enseñando a no cometer.
- **Registro de modelos y seguimiento de experimentos** (MLflow y parientes) → fuera. Con un
  modelo, el "registro" es un archivo con fecha en el nombre y una línea en el `CHANGELOG`.
- **Despliegue continuo del modelo** —reentrenar y publicar sin intervención— → fuera, y la
  sección 5.5 explica por qué en este dominio eso es una decisión de gobierno, no de CI.
- **Cuantización, compilación y aceleradores** → fuera. Con 0,7 ms de latencia sobre seis
  coeficientes, no hay nada que acelerar.
- **Detección de deriva** → declarada fuera **con una deuda**: `ds07` §6.2 mostró que el
  conjunto del curso no tiene deriva por construcción, así que aquí no se puede medir. Lo que
  sí queda escrito es dónde iría y qué apagaría.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

El modelo vive en `modelo.pkl`, 1,2 KB, en la carpeta donde `ds08` lo dejó. Para que Yuli lo
use hay que llevarlo a un sitio donde AgendaAPI lo pueda consultar, y ahí aparecen tres
preguntas que nadie hace hasta que duelen:

1. **¿En qué formato viaja?** Un `pickle` es cómodo: una línea para guardar, una para cargar,
   y funciona con cualquier objeto de Python. Esa comodidad tiene un precio que se paga
   entero.
2. **¿Qué tiene que estar instalado para cargarlo?** Un `pickle` de scikit-learn necesita
   scikit-learn —de la versión compatible— en el servidor que lo abre. Un grafo ONNX necesita
   un intérprete de ONNX y nada más.
3. **¿Quién lo vuelve a entrenar, cuándo, y qué lo detiene?**

### `pickle` no lee datos: reconstruye objetos

Esta es la frase entera. `pickle.load` no parsea una estructura: sigue un pequeño programa de
instrucciones que dice qué objetos crear y cómo. Y una de esas instrucciones es *"llama a esta
función con estos argumentos"*.

```python
class InnocentLookingModel:
    def __init__(self, target: Path) -> None:
        self.target = target

    def __reduce__(self):
        return (Path(self.target).write_text,
                ("Este texto lo escribió el archivo al cargarse.\n",))
```

`__reduce__` es el gancho que `pickle` usa para saber cómo reconstruir un objeto, y devuelve
**una función y sus argumentos**. Nada obliga a que esa función construya nada. Al cargar:

```
Efecto observado al cargar: 'Este texto lo escribió el archivo al cargarse.'

No hubo ninguna advertencia, ninguna excepción y ninguna forma de verlo venir.
```

> ⚠️ **Y no hay validación previa posible.** Para saber qué hay dentro de un `.pkl` habría que
> interpretarlo, que es exactamente lo que produce el problema. No existe un
> `pickle.load(safe=True)`, y los intentos de restringirlo con `find_class` se rompen en
> cuanto el modelo necesita una clase legítima.

La regla que sale de ahí, y es corta: **un `.pkl` solo se carga si tu propio proceso lo
escribió**. No "si confías en quien te lo pasó", no "si viene del repositorio interno": si lo
escribió tu proceso de entrenamiento, en tu infraestructura, y nadie pudo tocarlo desde
entonces. Todo lo demás se convierte primero a un formato que solo sepa describir números.

### ONNX, en una frase

Un archivo ONNX es **un grafo de operaciones sobre tensores**: multiplica esta matriz, suma
este vector, aplica esta sigmoide. No tiene forma de nombrar una función de Python porque su
vocabulario no incluye funciones de Python.

Se puede comprobar mirando los bytes:

```python
assert b"sklearn" in pickle_bytes      # el .pkl dice qué módulos va a importar
assert b"sklearn" not in onnx_bytes    # el .onnx no menciona ninguno
assert b"builtins" not in onnx_bytes
```

Ese es el argumento entero, y es de seguridad antes que de rendimiento.

### Tu instinto de Java dice… y esta vez se equivoca

Tu instinto dice **"serializar es serializar"**, y viene con una cicatriz: en la JVM ya
aprendiste que `ObjectInputStream` sobre datos ajenos es una vulnerabilidad de libro, y por
eso hoy mandas JSON. La parte transferible es exacta.

Donde falla es en el contexto. Con JSON **nadie duda** de que hay que validar; con un modelo,
el `.pkl` se siente como un binario opaco —"es el modelo, qué le voy a validar"— y viaja por
correo, por un bucket compartido o dentro de una imagen que alguien más construyó.

```python
# ❌ El reflejo. La misma línea que en Java te haría saltar, aquí no le llama la atención a nadie.
with open("modelo_de_la_consultora.pkl", "rb") as file:
    modelo = pickle.load(file)
```

```python
# ✅ Un formato que no puede ejecutar nada, y un servidor que no necesita sklearn instalado.
session = onnxruntime.InferenceSession("modelo.onnx", providers=["CPUExecutionProvider"])
```

Y el segundo instinto, más caro a largo plazo: **"el modelo es un detalle de implementación"**.
No lo es. Es el único componente del sistema **que se degrada solo, sin que nadie toque el
código**: los datos cambian, el mundo cambia, y la función que ayer acertaba hoy no. Ningún
otro artefacto de tu stack tiene esa propiedad.

### Esto sí funciona igual

- **Medir sobre HTTP, no en proceso.** Lo enseñó la Fase 10 y vuelve a valer: el costo que
  parece grande medido adentro se lo come el servidor.
- **La configuración por variable de entorno**, y un endpoint de salud que dice qué hay
  cargado. Es lo mismo que hiciste en la Fase 16 para la observabilidad.
- **Validar en la frontera.** El `Appointment` de Pydantic es exactamente el modelo de entrada
  de la Fase 10; que lo que entre sea una predicción no lo hace especial.
- **Una dependencia menos en la imagen es una imagen más chica y una superficie menor.**

### Diccionario de traducción

| Lo que sabes | Aquí | Dónde se rompe el paralelo |
|---|---|---|
| `ObjectInputStream` sobre datos ajenos | `pickle.load` | Paralelo exacto, incluida la moraleja. Lo que cambia es que aquí nadie desconfía |
| JSON como formato de intercambio | ONNX | Los dos solo describen datos. ONNX además describe **operaciones**, no solo valores |
| Un `.jar` en el classpath | un `.pkl` en disco | Los dos son código. El `.jar` lo sabe todo el mundo; el `.pkl` no |
| Versión del artefacto en el manifiesto | versión del modelo en `/salud` | Igual en espíritu, y aquí importa más: el binario cambia sin que cambie el código |
| Rollback a la versión anterior | volver al modelo anterior | Igual de fácil de hacer y mucho más fácil de olvidar: el modelo no está en el `git log` |
| Una dependencia en `pom.xml` | scikit-learn en el servidor | Con ONNX **desaparece**: el servidor deja de necesitar la biblioteca que entrenó |

> 📝 **Nota de ecosistema.** ONNX nació como formato de intercambio entre frameworks —exportar
> de PyTorch e importar en otra cosa— y terminó siendo sobre todo un **formato de despliegue**,
> que es como se usa aquí. Lo que conviene saber antes de adoptarlo: la conversión no siempre
> es completa. Un `Pipeline` de scikit-learn con transformaciones estándar se convierte sin
> drama; uno con una función propia envuelta en `FunctionTransformer`, no. Por eso el
> exportador de esta sección **comprueba** que los dos formatos coinciden en vez de confiar:
> el conversor avisa de lo que no sabe hacer, y también hay cosas que convierte con una
> diferencia numérica que solo se ve midiendo.

---

## 💻 5. Código mínimo con comentarios

Registro **aplicación**, y es el primero del track: esto vive dentro de AgendaAPI, tiene
configuración, tiene frontera y tiene pruebas. Lo que `ds01` habría resuelto con un script,
aquí necesita un contrato.

```bash
uv run --with scikit-learn==1.9.1 --with skl2onnx==1.20.0 python export.py --salida modelos
AUREA_BACKEND=onnx uvicorn serve:app --port 8100
```

### 5.1 Exportar, y comprobar que lo exportado es lo mismo

```python
    sample = matrix[:1000]
    original = [float(row[1]) for row in pipeline.predict_proba(sample)]
    exported = probabilities_onnx(onnx_path.read_bytes(), sample)
    worst = max(abs(a - b) for a, b in zip(original, exported, strict=True))
    if worst > TOLERANCE:
        raise SystemExit(f"El ONNX no coincide con el original: {worst:.2e} > {TOLERANCE:.0e}")
```

**Detalles con intención**

- **La tolerancia es `1e-6` y no cero.** ONNX calcula en `float32` y scikit-learn en
  `float64`: exigir igualdad exacta fallaría siempre. Sobre los datos de Áurea la diferencia
  máxima real es **9,44 × 10⁻⁸**, dos órdenes por debajo del umbral.
- **Se exporta el `Pipeline` completo, no el estimador.** El escalado es parte del modelo;
  exportar solo la regresión y escalar a mano en el servidor es garantizar que algún día los
  dos escalados dejen de coincidir.
- **`zipmap=False`** en la conversión. Sin eso, el conversor envuelve la salida en una lista
  de diccionarios que es cómoda en Python y traiciona el punto de ONNX, que es que el
  consumidor pueda ser cualquier cosa.

### 5.2 El endpoint, con la frontera donde va

```python
class Appointment(BaseModel):
    inasistencias_previas: float = Field(ge=0)
    jueves_tarde: float = Field(ge=0, le=1)
    lluvia_mm: float = Field(ge=0)
    distancia_km: float = Field(gt=0)
    dias_desde_agendamiento: float = Field(ge=0)

    def vector(self) -> list[float]:
        return [..., self.lluvia_mm * self.distancia_km]
```

Dos decisiones que valen la sección entera:

- **Los campos llegan con nombre, no como una lista de seis números.** Aceptar una lista
  habría sido más corto y convierte cualquier reordenamiento en un error silencioso: el
  modelo seguiría respondiendo, con otras predicciones.
- **La interacción la calcula el servidor.** Es parte del modelo, no del contrato; pedírsela
  al cliente sería filtrar el modelo a la API y garantizar que el día que cambie haya que
  cambiar a todos los que llaman.

### 5.3 Los dos backends, intercambiables

```python
BACKEND: Literal["pickle", "onnx"] = os.environ.get("AUREA_BACKEND", "onnx")
...
@app.get("/salud")
def health() -> dict[str, str]:
    return {"estado": "ok", "backend": BACKEND}
```

El backend por defecto es ONNX, y eso no es una preferencia: es la decisión de la sección 4
escrita en el código. `pickle` sigue ahí para poder medirlo y para el día en que un modelo no
se deje convertir.

### 5.4 El experimento que rompe a propósito

```bash
python pickle_danger.py
```

Diez líneas, un `__reduce__`, y un archivo escrito en disco **al cargar el modelo**. La
demostración es deliberadamente inofensiva —escribe en un directorio temporal— y en su lugar
podría ir cualquier cosa que el proceso pueda hacer, que en un servidor de predicciones es
bastante.

Hay una prueba que **afirma que esto pasa**:

```python
def test_cargar_un_pickle_ejecuta_codigo():
    assert "lo escribió el archivo al cargarse" in demonstrate()
```

Está escrita como prueba y no como comentario porque el día que `pickle` deje de comportarse
así —no va a pasar— habría que reescribir media sección.

### 5.5 Dónde vive el reentrenamiento

No en el servidor. El endpoint **carga** un modelo; no entrena, no actualiza y no aprende de
lo que ve. El entrenamiento es un trabajo del **cierre nocturno de la Fase 15**, mensual, que
produce un archivo nuevo con su fecha en el nombre y **no lo publica solo**:

```
cierre nocturno (mensual)
  → entrena con los datos hasta el mes cerrado
  → exporta a ONNX y comprueba contra el pickle
  → compara su AUC con el del modelo en producción sobre el mismo tramo
  → si baja, NO publica: deja el archivo y avisa
  → si sube, deja el archivo listo y avisa. Publica una persona.
```

Las dos últimas líneas son la decisión importante y no es técnica: **en este dominio el modelo
no se despliega solo**. No porque el proceso no pueda automatizarse —puede—, sino porque lo
que cambia cuando cambia el modelo es a quién llama Yuli mañana, y eso tiene una persona
responsable. Un despliegue automático convierte un error de datos en una decisión sobre
pacientes sin que nadie la haya tomado.

**El patrón a memorizar**
> Un modelo se despliega como se despliega un binario: con versión, con endpoint de salud que
> la anuncie, con una forma de volver atrás, y en un formato que no pueda ejecutar nada. Y se
> reentrena en un proceso aparte que **propone**, no que publica.

**Prueba de fuego**

```bash
uv run --with scikit-learn==1.9.1 --with skl2onnx==1.20.0 --with onnxruntime==1.30.0 \
       --with fastapi==0.141.1 --with pytest pytest -q
```

Diez pruebas. La que sostiene la sección es `test_los_dos_formatos_predicen_lo_mismo`: si el
ONNX dejara de coincidir, el endpoint estaría sirviendo otro modelo **sin que nada fallara**.

La mentira que te va a contar la salida si miras el lugar equivocado: la tabla de la sección 6
dice que ONNX responde 0,23 ms más rápido en p95. **Ese no es el argumento** —son
microsegundos al lado de la red— y usarlo como argumento es perder la discusión con razón. El
argumento es el arranque en frío, la imagen sin scikit-learn, y sobre todo que un grafo ONNX
no puede llamar a `Path.write_text`.

---

## 📏 6. Medición

**Hipótesis.** Que servir el modelo en ONNX arranca más rápido y responde igual o mejor que
servirlo en `pickle`, y que **la diferencia de latencia es irrelevante** al lado de las dos
razones de verdad: el arranque y lo que hay que tener instalado.

**Condiciones.** CPython 3.14.5, FastAPI 0.141.1, uvicorn 0.52.4, scikit-learn 1.9.1,
onnxruntime 1.30.0, skl2onnx 1.20.0; macOS 26.6.2 sobre Apple Silicon de 8 núcleos. El modelo
ganador de `ds08` —la logística con la interacción—. **Medición sobre HTTP contra un uvicorn
real**, no con el cliente de pruebas en proceso, con cliente de `urllib` de la biblioteca
estándar. 500 peticiones por backend, 50 de calentamiento descartadas. El arranque en frío se
mide desde que se lanza el proceso hasta que `/salud` contesta.

**Competidores.** Los dos formatos, sobre el mismo modelo y el mismo endpoint. Los dos
devuelven la misma probabilidad —diferencia de 3,8 × 10⁻⁸— y hay una prueba que lo verifica:
si no, la comparación de latencias sería entre dos servicios distintos.

| Backend | Arranque en frío | p50 | p95 | Artefacto |
|---|---|---|---|---|
| `pickle` + scikit-learn | 1,10 s | 0,90 ms | 1,22 ms | 1,2 KB |
| **ONNX** + onnxruntime | **0,38 s** | **0,71 ms** | **0,99 ms** | **0,5 KB** |

Y de dónde sale el arranque, medido aparte:

| Proceso que importa… | Tiempo |
|---|---|
| FastAPI y uvicorn | 0,25 s |
| … más scikit-learn | 1,03 s |
| … más onnxruntime | 0,32 s |

```bash
uv run --with fastapi==0.141.1 --with uvicorn==0.52.4 --with scikit-learn==1.9.1 \
       --with onnxruntime==1.30.0 python bench_serving.py --modelos modelos
```

> ⚖️ **Veredicto.** **ONNX gana, y no por la latencia.** La diferencia de p95 es de 0,23 ms:
> real, reproducible e **irrelevante** al lado de cualquier red. Quien defienda ONNX con ese
> número va a perder la discusión con razón.
>
> Las tres razones que sí valen: **arranca 2,9× más rápido** —1,10 s contra 0,38, que es lo
> que espera un contenedor que acaba de escalar—; **la imagen no necesita scikit-learn**, que
> son cientos de megas y una dependencia que hay que mantener versionada con la que entrenó; y
> **el artefacto no puede ejecutar código**, que es la única de las tres que no es una
> optimización sino un cambio de categoría de riesgo.
>
> **El umbral, dicho como criterio:** sirve `pickle` mientras el proceso que escribe el
> archivo y el que lo carga sean tuyos, estén en la misma infraestructura y nadie pueda
> interponerse — y aun así, revisa qué tan larga es esa cadena. En cuanto el modelo cruce una
> frontera organizativa, viaje por un bucket o lo produzca alguien que no seas tú, la
> respuesta es un formato que solo describa números.

> 📝 **Lo que esta medición no dice.** La **primera** corrida de todas dio un arranque de
> **32 segundos** para el backend de `pickle`, porque el sistema de archivos no tenía nada de
> scikit-learn en caché. La tabla publica la cifra estable —1,10 s— y esta nota existe porque
> en un contenedor recién creado la primera es la que vives. Tampoco mide con carga
> concurrente: 500 peticiones secuenciales contestan *"¿cuánto tarda una?"* y no *"¿cuántas
> aguanta?"*, que necesitaría el arnés de la Fase 17. Y no mide el costo de convertir, que es
> despreciable aquí y no lo es para modelos grandes.

---

## ⚖️ 6.1 El veredicto del track: qué valió la pena y qué no

Nueve secciones y diez mediciones: **nueve ejecutadas** y una pendiente —la §6.2 de `ds05`, que
necesita cinco personas—. Esto es lo que Áurea se lleva.

### Los dos proyectos

**Embudo — valió la pena, y el entregable no es el que se pidió.** Marcela pidió el costo por
paciente adquirido y lo que se le entregó fue **una banda**: entre 1,06 y 7,96 millones para
TikTok según quién se lleve el mérito, con los intervalos de las dos esquinas sin tocarse. Eso
suena a fracaso y es lo contrario: el informe que habría dado un número único habría llevado
al comité a apagar TikTok con confianza, y TikTok es el canal de descubrimiento de la mitad de
los pacientes. **El valor del proyecto es que evitó una decisión equivocada**, que es un
entregable difícil de facturar y real.

Y de regalo, la respuesta a la pregunta que nadie había calculado: **la red de aliados cuesta
1.259.648 COP por paciente retenido**, entre Google y Instagram. Es el segundo canal más
barato de la empresa y estaba fuera de todas las conversaciones.

**Ausentismo — valió la pena, y el modelo que vale es el simple.** A la capacidad real de Yuli
—el 20% de la agenda—, el modelo acierta **cinco de cada diez llamadas contra tres y media** de
la regla que se usaba: un 50% más de aciertos por el mismo tiempo de trabajo. Y llevado a la
decisión de sobreagendar, **recupera unas 3.000 de las 6.602 consultas** que se pierden en un
semestre. Convertir eso a pesos necesita un número que Áurea tiene y este conjunto no —cuánto
vale una consulta—, y por eso aquí se deja en consultas.

### Lo que no valió la pena, que es la mitad honesta

- **La red neuronal.** Gana 0,0125 de AUC y **eso es exactamente lo que vale una columna
  escrita a mano**. Cuesta PyTorch, un bucle de entrenamiento y cinco decisiones que alguien
  retoma cada vez que los datos cambien. *(`ds08`)*
- **Los motores de consulta, a esta escala.** Para el informe mensual de once mil filas, el
  bucle de la biblioteca estándar gana de punta a punta: 34 ms contra 97 de DuckDB y 326 de
  pandas. El umbral está entre 30.000 y 115.000 filas, y Áurea genera 11.000 al mes. *(`ds03`)*
- **El tablero interactivo.** Para las siete cifras del comité, la tabla de texto gana: cabe
  la banda, se pega en un correo y se compara con un `diff`. *(`ds05`)*
- **Los cuadernos como entregable.** Dos de seis reejecutan; uno de seis da el mismo resultado
  dos veces. *(`ds06`)*

### Y lo que resultó valer mucho más de lo que parecía

- **Preguntar cuándo se llena cada columna.** Una sola columna con fuga regala 0,063 de AUC sin
  lanzar nada. *(`ds07`)*
- **Medir la calibración antes de multiplicar.** Un puntaje que ordena decentemente —0,672 de
  AUC— destruye 6.336 consultas al usarse para decidir. *(`ds08`)*
- **Esperar a que las cohortes maduren, y recortar el numerador a la misma ventana.** *(`ds04`)*
- **Escribir la línea base primero.** Sin ella, el 0,81 de exactitud del modelo parece un
  resultado y es un punto por encima del modelo que no hace nada. *(`ds07`)*

> ⚖️ **El árbol de decisión que se lleva el lector, y sirve fuera de Áurea:**
>
> **¿La pregunta es descriptiva o predictiva?** Si es descriptiva, el riesgo no está en la
> herramienta: está en el método —la ventana, el reparto, la cohorte—. Si es predictiva,
> escribe la línea base antes de tocar una biblioteca.
>
> **¿Cuántas veces al día se responde?** Una al mes: biblioteca estándar, y el arranque de la
> dependencia pesa más que la consulta. Mil al día con el proceso caliente: se da vuelta
> entero.
>
> **¿El número va a ordenar o a multiplicar?** Ordenar es AUC. Multiplicar exige calibración,
> y si no la mediste, no multipliques.
>
> **¿El modelo decide sobre personas?** Entonces la pregunta que manda no es métrica: es si
> se lo contarías a la persona.

---

## 🧱 7. Miniproyecto — El despliegue que Patricia puede revertir

**El encargo.** Patricia te dice: *"Yo soy la que está a las siete de la mañana cuando algo no
funciona. Si el modelo nuevo empieza a decir cosas raras, necesito poder volver al de antes
sin llamarte, y necesito saber cuál está puesto sin entrar al servidor."*

**Por qué duele.** Porque el modelo **no está en el `git log`**: es un binario que alguien dejó
en una carpeta, y la pregunta "¿cuál está corriendo?" no tiene respuesta a menos que tú la
construyas. Y porque "volver atrás" tiene que ser una operación de treinta segundos que hace
alguien que no programa, a las siete de la mañana.

**Datos de entrada.** El histórico de ausentismo y el exportador de esta sección. Genera **tres
versiones** del modelo, entrenadas con cortes distintos, para tener algo entre qué moverse. El
caso sucio: **una de las tres tiene que ser peor** —entrénala con dos meses de datos— para que
el rollback tenga sentido.

**Criterios de aceptación.**

1. `python publicar.py --modelo modelos/2026-01.onnx` publica una versión, y `--revertir`
   vuelve a la anterior. Las dos operaciones son atómicas: nunca hay un momento en que el
   servidor no tenga modelo.
2. `/salud` devuelve **qué versión está cargada**, con su fecha de entrenamiento y el AUC que
   sacó en su tramo de prueba.
3. El servidor **se niega a arrancar** si el archivo de modelo no pasa una comprobación de
   integridad que tú defines. Explica en tres líneas qué protege esa comprobación y qué no.
4. Publicar un modelo cuyo AUC sea peor que el que está en producción **requiere una bandera
   explícita** (`--aunque-empeore`) y lo deja registrado.
5. Una prueba demuestra el ciclo completo: publicar, comprobar `/salud`, revertir, comprobar
   `/salud` otra vez.
6. Hay un `README` de media página, dirigido a Patricia, con los dos comandos y qué mirar. Sin
   jerga.

**Restricciones de registro.** **Aplicación**: configuración, endpoint de salud, códigos de
salida, pruebas. Y una restricción dura: **el servidor no carga `pickle`**. Si tu diseño lo
necesita, vuelve a la sección 4.

**La trampa.** El criterio 1, la atomicidad. Vas a implementar "publicar" como copiar el
archivo nuevo encima del viejo, y va a funcionar en tus pruebas. En el servidor, algún día, el
proceso va a leer el archivo **mientras se está copiando** y va a cargar medio modelo o
ninguno. La solución tiene nombre y es la misma que usa todo el mundo para esto; búscala.

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

Separa "qué modelos existen" de "cuál está activo". Un directorio con versiones y un puntero
al activo te da publicar y revertir casi gratis, y hace que la pregunta de `/salud` tenga una
respuesta.
</details>

<details><summary>Pista 2 — la herramienta</summary>

`os.replace` es atómico dentro del mismo sistema de archivos, y `Path.symlink_to` con un
reemplazo atómico resuelve el puntero. Para la integridad, `hashlib` de la biblioteca estándar.
[docs.python.org/3.14/library/os.html#os.replace](https://docs.python.org/3.14/library/os.html#os.replace)
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def publish(version: Path, registry: Path, force: bool = False) -> None: ...
def rollback(registry: Path) -> Path: ...
def active(registry: Path) -> ModelInfo: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-09 -m "Mini ds09: publicar y revertir · <X> s de rollback · integridad por <método>"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre `pickle_danger.py` y después escribe tú un `__reduce__` que haga otra cosa inofensiva
   —listar un directorio, por ejemplo—. La facilidad es el ejercicio.
2. Busca la cadena `sklearn` dentro del `.pkl` y dentro del `.onnx` con `grep -a`. Lo que
   encuentras y lo que no es el argumento de la sección 4.
3. Mide el arranque de `import sklearn.linear_model` y de `import onnxruntime` en tu máquina.
   Compara con la tabla de la sección 6.
4. Cambia `zipmap` a `True` en el exportador y mira qué forma tiene la salida. Después decide
   cuál prefieres y por qué.
5. Manda al endpoint una cita con `distancia_km: 0` y lee el error que devuelve. Es la
   frontera de la Fase 10 haciendo su trabajo.
6. Baja `TOLERANCE` a `1e-9` en el exportador y corre. El fallo que sale es el que protege.

**🟡 Intermedio (7–14)**

7. Sirve el modelo de la **red neuronal** de `ds08` exportándolo a ONNX desde PyTorch y
   compáralo con el de sklearn. Mide el tamaño del artefacto de los dos.
8. Añade al endpoint la versión del modelo en la respuesta, no solo en `/salud`. Discute si
   eso es información que el cliente necesita o ruido.
9. Mide el endpoint con **carga concurrente** usando el arnés de la Fase 17. La pregunta que
   contesta es distinta de la de la sección 6.
10. Implementa un backend tercero: la fórmula de la regresión escrita a mano —seis
    multiplicaciones y una sigmoide— sin ninguna dependencia. Mídelo. El resultado es
    incómodo y es el espíritu del track.
11. Haz que el servidor rechace arrancar si el `.onnx` no tiene el número de entradas que el
    código espera. Comprueba que el mensaje dice qué hacer.
12. El modelo devuelve una probabilidad. Añade el umbral por capacidad de `ds07` al endpoint y
    decide si eso debería estar en el servidor o en el cliente.
13. Convierte un `Pipeline` con un `FunctionTransformer` propio y mira cómo falla la
    conversión. Es el límite de ONNX que la nota de ecosistema anuncia.
14. Mide el tamaño de una imagen de contenedor con scikit-learn y otra con solo onnxruntime.
    La diferencia es el segundo argumento del veredicto.

**🟠 Difícil (15–21)**

15. Diagnóstico: el endpoint devuelve probabilidades razonables pero **distintas** de las del
    cuaderno donde se entrenó. Enumera las cuatro causas más probables en orden, y la
    comprobación que distingue cada una.
16. Implementa la publicación atómica del miniproyecto y **demuéstrala**: lanza un bucle que
    consulte `/salud` mientras publicas, y comprueba que ninguna respuesta falla.
17. Diseña la detección de deriva que esta sección declaró fuera: qué se mide, con qué
    frecuencia, contra qué, y **qué apaga** cuando salta. El conjunto del curso no tiene
    deriva, así que tendrás que simularla.
18. **De registro.** El puntaje se necesita en la lista de Yuli (batch, de madrugada), en la
    política de sobreagendamiento (batch, semanal) y en AgendaAPI (en línea). ¿Un servicio,
    tres procesos o una tabla precalculada? Decide con las tablas de `ds07` §6.3 y de aquí.
19. El reentrenamiento mensual produce un modelo peor. Escribe el código que lo detecta y lo
    detiene, y decide **qué se le dice a quién**.
20. Escribe la comprobación de integridad del criterio 3 del miniproyecto con firma, no solo
    con hash. Explica qué ataque para cada una y cuál no.
21. Toma el endpoint y hazlo devolver, además de la probabilidad, **la contribución de cada
    variable**. Mide cuánta latencia agrega y decide si vale.

**🔴 Muy difícil (22–25)**

22. **Defiende lo contrario.** Construye el caso donde servir el `pickle` es la decisión
    correcta para Áurea. Existe, tiene que ver con un modelo que no se deja convertir, y
    obliga a describir qué controles lo hacen aceptable.
23. Implementa el ciclo completo del reentrenamiento dentro del cierre nocturno de la Fase 15:
    entrenar, exportar, comparar, proponer. Con su registro y su alerta.
24. 🔥 Sirve el mismo modelo desde Java —`onnxruntime` tiene enlace para JVM— y compáralo con
    el endpoint de Python. Es el duelo de la Fase 17 aplicado a esta sección, y su resultado
    es material del curso.
25. **De cierre.** Escribe, en una página, la recomendación que le darías a Áurea sobre sus
    dos proyectos de datos: qué mantener, qué apagar y qué medir el año que viene. Con las
    nueve secciones del track delante, y sin una sola afirmación sin número.

**🔥 Opcionales**

- Abre el `.onnx` con [netron.app](https://netron.app) y mira el grafo. Son cuatro nodos, y
  verlos es la mejor forma de entender por qué el formato no puede ejecutar código arbitrario.
- Exporta el modelo a PMML y compáralo con ONNX. Es el formato anterior y explica de dónde
  viene la idea.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://docs.python.org/3.14/library/pickle.html](https://docs.python.org/3.14/library/pickle.html)
  — **empieza por la advertencia de seguridad del principio**, que es literal y está en el
  primer párrafo.
- [https://onnx.ai/sklearn-onnx/](https://onnx.ai/sklearn-onnx/) — `skl2onnx`: qué convierte,
  qué no, y las opciones como `zipmap`.
- [https://onnxruntime.ai/docs/api/python/api_summary.html](https://onnxruntime.ai/docs/api/python/api_summary.html)
  — `InferenceSession` y los proveedores de ejecución.
- [https://fastapi.tiangolo.com/tutorial/body/](https://fastapi.tiangolo.com/tutorial/body/)
  — el modelo de entrada, que es el mismo de la Fase 10.
- [https://docs.python.org/3.14/library/os.html#os.replace](https://docs.python.org/3.14/library/os.html#os.replace)
  — para la publicación atómica del miniproyecto.

**Del propio curso**

- La Fase 16 abrió el tema de `pickle`; esta sección lo cobra.
- La Fase 15 tiene el cierre nocturno donde vive el reentrenamiento.
- [`ds08-ausentismo.md`](ds08-ausentismo.md) §6 — el modelo que aquí se sirve, y por qué es
  ese y no la red.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan
> números de página, ISBN ni identificadores de video que no se hayan comprobado.

**Orden de lectura sugerido.** Antes de escribir código: la advertencia de `pickle`, que son
cinco líneas y ordenan la sección entera. Durante: `sklearn-onnx`, cuando la conversión no
haga lo que esperabas. Después: `os.replace`, cuando llegues al miniproyecto y descubras la
trampa.

---

## 🚀 10. Cierre del track

Terminas con el modelo fuera de tu portátil, en un formato que no puede ejecutar nada, detrás
de un endpoint que dice qué tiene cargado, con un reentrenamiento que propone en vez de
publicar. Y con el veredicto de la sección 6.1, que es lo que el track venía a producir:
**los dos proyectos de datos de Áurea valían la pena, y casi ninguna de las herramientas
modernas que se les asocian era necesaria**.

Eso no es un alegato contra las herramientas. Es el resultado de medirlas en el tamaño y la
frecuencia reales de una red de diez sedes, que es el tamaño y la frecuencia de la mayoría de
las empresas que van a contratar a quien lea esto. El día que Áurea compre tres redes más, la
mitad de estos veredictos se da vuelta — y el track deja escrito **en qué umbral** pasa cada
uno, que es lo único que sobrevive al cambio de escala.

Lo que queda del curso, si vienes siguiéndolo entero: las dieciocho fases del camino base, las
ocho secciones del track `ia` y estas nueve. Los cuatro proyectos de Áurea existen, están
medidos, y de cada uno se puede decir qué ganó y qué costó.

> **La señal de que quedó bien:** cuando ante "hay que poner el modelo en producción" tu
> primera pregunta sea *"¿en qué formato viaja y quién lo escribió?"* — y cuando ante un
> proyecto de datos terminado puedas decir, con números, qué parte valió la pena y cuál no.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-09 -m "ds09 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 09: …`), los de ejercicio su número
> (`ds 09 ej12: …`) y el miniproyecto el suyo (`ds 09 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `ds-mini-09`, con **el tiempo de rollback** en el mensaje.
>
> Y como este es el cierre del track, un tag más:
>
> ```bash
> git tag -a ds-track -m "Track ds completo: 9 secciones, 9 mediciones ejecutadas de 10"
> ```
>
> La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
