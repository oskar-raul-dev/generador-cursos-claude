# 📓 ds06 — Cuadernos y reproducibilidad

> Python para desarrolladores Java senior · Track `ds` · sección 6 de 9
> Depende de: `ds04`, `ds05` · Habilita: `ds07`
> Registro de esta sección: script — un archivo que audita otros archivos
> Proyecto que avanza: Embudo — se cierra su bloque

---

## 🎯 1. Propósito

Las cuatro secciones anteriores produjeron análisis, y los produjeron en archivos `.py`
limpios porque así se escribe un curso. **En la vida real se escriben en un cuaderno**, a
saltos, ejecutando celdas en el orden en que se te van ocurriendo, con la ventana de Jupyter
abierta tres días seguidos.

Esta sección mide qué queda de eso. Y trae el prejuicio que ya tienes —*"los cuadernos son un
desastre"*— para partirlo en dos: **una mitad es correcta y la otra te está costando una
herramienta que sirve**.

> 🧭 **La regla que ordena la sección: un cuaderno guardado con sus salidas se lee como si
> funcionara.** Esa es la trampa entera, y no se resuelve con disciplina: se resuelve
> ejecutándolo de arriba abajo en un kernel nuevo, que es la medición de la sección 6.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `check_reproducibility.py` ejecuta una carpeta de cuadernos en kernels nuevos y dice
      cuántos sobreviven, con el error de cada uno.
- [ ] Sabes leer los `execution_count` de un cuaderno ajeno y decir, sin ejecutarlo, si tiene
      estado oculto.
- [ ] Puedes nombrar los cuatro defectos que matan un cuaderno y el quinto, que **no lo mata
      y es peor**.
- [ ] Sabes por qué "corre" y "es reproducible" son dos cosas distintas, y tienes la medición
      que las separa.
- [ ] Corriste el mismo análisis en marimo y sabes exactamente qué garantía te da y cuál no.
- [ ] Tienes una posición defendible sobre cuadernos en producción, con números.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Entrenar modelos** → `ds07`, que abre el proyecto Ausentismo.
- **Orquestación de pipelines** —Airflow, Dagster, Prefect— → fuera del curso. Aquí el
  programador es el `cron` de la Fase 15, y para Áurea alcanza. Cuando no alcance, la
  pregunta ya no es de cuadernos.
- **JupyterHub, Colab y los cuadernos alojados** → fuera. Cambian quién administra el
  entorno, no las propiedades que esta sección mide.
- **`nbdev` y el cuaderno como fuente de un paquete** → fuera del curso, y es una posición
  legítima que aquí no se toma.
- **Los widgets interactivos de Jupyter** → track `ui` a la carta.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

Un cuaderno `.ipynb` es un JSON con tres cosas por celda: el código, **la salida de la última
vez que se ejecutó**, y un contador. Las dos últimas son las que causan todo.

```json
{"cell_type": "code", "execution_count": 3, "outputs": [{"text": ["18.6 %\n"]}],
 "source": ["print('conversión:', round(6065 / total * 100, 1), '%')"]}
```

Ese `3` dice que la celda fue la tercera cosa que se ejecutó en la sesión. Si las celdas de
arriba tienen `1` y luego `5`, alguien ejecutó fuera de orden. Y esa salida guardada —`18.6
%`— es lo que hace que el cuaderno **se lea como si funcionara**, aunque la variable `total`
ya no exista en ninguna parte.

> 🧠 **El modelo mental correcto: un cuaderno no es un programa, es la transcripción de una
> sesión.** Confundir las dos cosas es el origen de todo lo demás. Un programa se define por
> su texto; una transcripción se define por lo que pasó, y lo que pasó no está en el archivo.

### Los cinco defectos, y cuál es el peor

`generar_cuadernos.py` produce seis cuadernos del análisis del Embudo. Uno está limpio y
cinco traen su defecto:

- **Estado oculto** (`estado-oculto.ipynb`): la celda 2 usa algo que define la celda 3.
  Funcionó porque se ejecutó la 3 primero. **Los `execution_count` van 1, 3, 2** y son la
  única señal visible sin ejecutar nada.
- **Celda borrada** (`celda-borrada.ipynb`): la celda que definía `leads` ya no está. Alguien
  la borró después de ejecutarla. **Y aquí no hay señal**: los contadores van en orden, solo
  que empiezan en 2.
- **Ruta absoluta** (`ruta-absoluta.ipynb`): `/Users/marcela/Escritorio/aurea/data/leads.csv`.
  El defecto más común del mundo.
- **Dependencia no declarada**: importa algo que está en la máquina de quien lo escribió.
- **Azar sin semilla** (`azar-sin-semilla.ipynb`): **este sí corre**. Da otro número cada vez,
  no falla, no avisa, y el informe del mes pasado no se puede reproducir.

El quinto es el peor y por eso la medición tiene dos columnas: **correr y ser reproducible no
son lo mismo**, y la mayoría de las auditorías solo miden lo primero.

### Tu instinto de Java dice… y esta vez se equivoca a medias

Tu instinto dice **"un cuaderno no es código de verdad"**, y hay que decirlo entero: en lo
que se refiere a *entregar* algo, **tienes razón**. Un `.ipynb` no se revisa en un pull
request —el diff es un JSON con imágenes en base64—, no se importa desde otro módulo sin
trucos, no se prueba con `pytest` sin herramientas adicionales, y arrastra salidas que pueden
contener datos de pacientes en un repositorio.

Donde el instinto falla es en la conclusión que sacas: **"entonces no los uso"**. Eso te
cuesta lo único que un cuaderno hace mejor que un script, que es el bucle de exploración:
cargar un millón de filas una vez y hacerles cuarenta preguntas sin volver a cargarlas. Es
exactamente lo que `ds01` midió en otro contexto —la conversión se paga una vez y las cuentas
se amortizan— y es la razón de que el formato exista.

```python
# ❌ El reflejo: el script que recarga todo en cada iteración de tu pensamiento.
python analisis.py   # 4 s de carga · 0,2 s de cuenta · repetido cuarenta veces

# ✅ Lo que el cuaderno hace bien: cargar una vez, preguntar cuarenta.
```

**La regla que sale de ahí, y es la posición del curso: el cuaderno es para pensar, el módulo
es para entregar.** Lo que se descubre en el cuaderno se muda a un `.py` con su prueba
**antes** de que alguien dependa de ello. El error no es usar cuadernos: es entregarlos.

### Esto sí funciona igual

- **Un artefacto que no reconstruyes desde cero no es tuyo.** Es la misma disciplina del
  build reproducible que aplicas desde siempre.
- **Fijar semillas es fijar versiones.** La misma razón por la que el `pyproject.toml` lleva
  versiones exactas desde la Fase 07.
- **El entorno es parte del programa.** Lo aprendiste en la Fase 07 con `uv`; un cuaderno no
  lo cambia, solo lo esconde mejor.
- **Los datos no van en el repositorio.** Todos los generadores del track escriben a `data/`
  y nada de eso se versiona.

### Diccionario de traducción

| Lo que sabes | Aquí | Dónde se rompe el paralelo |
|---|---|---|
| REPL / consola de depuración | el cuaderno | El REPL no guarda nada; el cuaderno **sí**, y ahí está el problema |
| `main()` que corre de arriba abajo | ejecutar todo el cuaderno | En el cuaderno eso es una opción del menú, no el modo normal de trabajo |
| Estado de una sesión de depuración | el kernel | Igual de efímero, y aquí sobrevive días a la vista de todos |
| Build reproducible | reejecución limpia | Igual en espíritu. Aquí no hay herramienta que lo garantice: hay que medirlo |
| `git diff` de un `.java` | `git diff` de un `.ipynb` | Falso amigo. Es JSON con salidas embebidas: ilegible para un humano |
| Cuaderno de marimo | un `.py` | Aquí el paralelo **sí** funciona: es un archivo Python que se ejecuta como script |

> 📝 **Nota de ecosistema.** El problema del estado oculto tiene la edad del formato y ha
> producido dos familias de respuestas. La primera es disciplina y herramientas alrededor:
> *"reinicia y ejecuta todo antes de guardar"*, `nbstripout` para no versionar salidas,
> `papermill` para ejecutar cuadernos con parámetros desde un programa. La segunda es cambiar
> el formato: **marimo** guarda el cuaderno como un archivo `.py` y decide el orden de
> ejecución con el **grafo de dependencias entre celdas**, no con el orden en que alguien les
> dio a ejecutar. Las dos familias son legítimas; la segunda es más joven y te ata a una
> herramienta, y esa es exactamente la clase de decisión que este curso te pide medir antes
> de tomar.

---

## 💻 5. Código mínimo con comentarios

Registro **script**: un archivo que audita otros archivos. Lo interesante es que aquí el
sujeto del programa son los cuadernos, no los datos.

```bash
python generar_cuadernos.py --salida cuadernos
uv run --with papermill==2.7.0 --with jupyterlab==4.6.3 \
       python check_reproducibility.py --cuadernos cuadernos
```

### 5.1 Ejecutar un cuaderno como si lo recibieras por correo

```python
def run_once(path: Path, timeout: int = 120) -> tuple[bool, str, list[str]]:
    with tempfile.TemporaryDirectory() as scratch:
        # El cuaderno se copia a un directorio vacío: si depende de un archivo que estaba
        # al lado, aquí se nota. Es la mitad del valor de esta medición.
        copy = Path(scratch) / path.name
        shutil.copy(path, copy)
        document = nbformat.read(copy, as_version=4)
        client = NotebookClient(document, timeout=timeout, kernel_name="python3",
                                resources={"metadata": {"path": scratch}})
```

**Detalles con intención**

- **Kernel nuevo por cuaderno.** Es lo que elimina el estado heredado, que es el defecto que
  se está buscando.
- **Directorio temporal vacío.** Sin esto, un cuaderno que lee `leads.csv` "funciona" porque
  el archivo está al lado. En la máquina de quien lo reciba, no está.
- **`timeout`.** Un cuaderno colgado no falla: espera. Sin timeout, la auditoría se cuelga
  con él.

### 5.2 El error, sin los colores

```python
ANSI = re.compile(r"\x1b\[[0-9;]*m")
...
return False, ANSI.sub("", str(error).splitlines()[-1])[:90], []
```

El kernel colorea el traceback porque cree que habla con una terminal. Sin quitar esos
códigos, el JSON de la medición queda ilegible y la tabla de la sección 6 sale con basura.
Es un detalle de tres líneas que separa una herramienta usable de un experimento.

### 5.3 El kernel sale de `ipykernel`, no de Jupyter

```python
def require_kernel(name: str = "python3") -> None:
    """Falla temprano y con un mensaje útil si no hay kernel que usar."""
    available = list(KernelSpecManager().find_kernel_specs())
    if name not in available:
        raise SystemExit(
            f"No hay un kernel «{name}» en este entorno "
            f"(encontrados: {available or 'ninguno'}). Lo instala `ipykernel`, que papermill "
            "no arrastra: agrega `--with jupyterlab==4.6.3` o `--with ipykernel`."
        )
```

Esto nació de un error real al escribir la sección: con `papermill` instalado y nada más, la
auditoría fallaba con `NoSuchKernel: No such kernel named python3` y un traceback de quince
líneas de `jupyter_client` que no menciona qué falta. **Lo que registra el kernel es
`ipykernel`**, que deja su especificación en `sys.prefix/share/jupyter/kernels/python3` al
instalarse, y `papermill` no depende de él.

> 💡 Es un caso de libro de lo que enseña el curso desde la Fase 04: **un error que no dice
> qué hacer cuesta media hora**. Tres líneas de comprobación al arrancar la ahorran, y son
> más baratas que la primera vez que alguien la pierda.

### 5.4 El mismo análisis en marimo

```python
@app.cell
def _(gasto, adquiridos):
    # Esta celda está ANTES de la que define `adquiridos` y funciona igual: marimo resuelve
    # el orden por dependencias. En Jupyter, esto mismo es el bug de `estado-oculto.ipynb`.
    costos = {canal: gasto[canal] * 1e6 / adquiridos[canal] for canal in gasto}
    print(sorted(costos, key=costos.get))
    return (costos,)
```

Las celdas declaran qué reciben y qué devuelven, y marimo construye el grafo. El archivo es
`.py`: se lee, se revisa en un pull request, se versiona con un diff legible y **se ejecuta
como script**.

```bash
uv run --with marimo==0.24.2 python cuaderno_marimo.py
# ['google', 'instagram', 'tiktok']
```

Lo que marimo garantiza: **no puede haber estado oculto**, porque no hay orden manual que
recordar. Lo que no garantiza, y conviene decirlo en la misma frase: no te salva de la ruta
absoluta, ni de la dependencia no declarada, ni del azar sin semilla. **Resuelve uno de los
cinco defectos**, que resulta ser el más difícil de ver.

>💡 **Y un atajo que apareció al escribir la sección: `ruff` ya lee cuadernos.** Al aplicarle
> la configuración del curso a la carpeta generada, encuentra **sin ejecutar nada** dos de los
> cinco defectos:
>
> ```
> cuadernos/estado-oculto.ipynb:cell 2:1:31: F821 Undefined name `adquiridos`
> cuadernos/celda-borrada.ipynb:cell 1:1:13: F821 Undefined name `leads`
> ```
>
> Es exactamente lo que el ejercicio 7 pide construir con `ast`, ya hecho y en milisegundos.
> **Lo que no hace** —y por eso la medición sigue valiendo— es detectar la ruta absoluta como
> problema, la dependencia que no está instalada, ni el azar sin semilla; y un `F821` puede ser
> un falso positivo legítimo cuando una celda define nombres dinámicamente. El auditor del
> miniproyecto se apoya en `ruff` para lo que `ruff` hace bien, y no lo reimplementa.

**El patrón a memorizar**
> El cuaderno es para pensar; el módulo es para entregar. Y entre los dos hay una única
> prueba que vale: reejecutarlo de arriba abajo, en un kernel nuevo, desde un directorio
> vacío. Si no pasa, no es un entregable: es una transcripción.

**Prueba de fuego**

```bash
uv run --with pytest --with papermill==2.7.0 --with jupyterlab==4.6.3 \
       --with marimo==0.24.2 pytest -q
```

Quince pruebas, ocho segundos. Las del generador **no necesitan kernel**; las que ejecutan
cuadernos se saltan solas si no lo hay — que es la misma tesis de la sección aplicada a sus
propias pruebas.

La mentira que te va a contar la salida si miras el lugar equivocado: el resumen dice "2 de
6 corren". Suena a que el 33% está bien. **Uno de esos dos es el cuaderno de control, que se
escribió correcto a propósito**, y el otro corre dando un número distinto cada vez. De los
cinco cuadernos "reales", cero sirven.

---

## 📏 6. Medición

**Hipótesis.** Que de una carpeta de cuadernos escritos con normalidad, **la mayoría no
reejecuta**, y que el subconjunto que sí reejecuta es todavía menor cuando se exige que dé el
mismo resultado dos veces.

**Condiciones.** CPython 3.14.5, `nbclient` 0.11.0 vía papermill 2.7.0 y jupyterlab 4.6.3;
macOS 26.6.2. Seis cuadernos del análisis del Embudo generados con `generar_cuadernos.py`
—uno limpio y cinco con un defecto sembrado cada uno, todos **guardados con sus salidas**—.
Cada uno se ejecuta en un **kernel nuevo**, desde un **directorio temporal vacío**, de la
primera celda a la última, con timeout de 120 s. Los que corren se ejecutan **una segunda
vez** y se comparan sus salidas.

**Competidores.** No hay: esto no compara herramientas, cuenta supervivientes. La comparación
con marimo es cualitativa y está en la sección 5.4, porque **el defecto que marimo previene
no se puede escribir en marimo** — no hay nada que medir.

**Resultado.**

| Cuaderno | Corre | Estable | Tiempo | Qué pasó |
|---|---|---|---|---|
| `limpio.ipynb` | ✅ | ✅ | 636 ms | — |
| `azar-sin-semilla.ipynb` | ✅ | ❌ | 1.377 ms | salidas distintas entre corridas |
| `estado-oculto.ipynb` | ❌ | — | 748 ms | `NameError: name 'adquiridos' is not defined` |
| `celda-borrada.ipynb` | ❌ | — | 713 ms | `NameError: name 'leads' is not defined` |
| `ruta-absoluta.ipynb` | ❌ | — | 681 ms | `FileNotFoundError: '/Users/marcela/Escritorio/…'` |
| `dependencia-no-declarada.ipynb` | ❌ | — | 677 ms | `ModuleNotFoundError` |

**2 de 6 corren de arriba abajo en un kernel nuevo. 1 de 6 además da el mismo resultado dos
veces seguidas.** La auditoría completa —ocho ejecuciones— tarda **siete segundos**.

```bash
uv run --with papermill==2.7.0 --with jupyterlab==4.6.3 \
       python check_reproducibility.py --cuadernos cuadernos --json resultado.json
```

> ⚖️ **Veredicto.** **Uno de cada seis, y el que sobrevive es el que se escribió correcto a
> propósito.** Los cinco defectos son los que aparecen de verdad, no versiones exageradas
> para el ejercicio, y cada uno tardó menos de un segundo en revelarse: la auditoría entera
> cuesta **siete segundos** y ningún equipo la corre. Esa desproporción —siete segundos
> contra meses de cuadernos que nadie sabe si sirven— es el resultado más útil de la sección.
>
> **El prejuicio del lector es medio correcto, y aquí está la mitad exacta.** Tiene razón en
> que un cuaderno no es un entregable: cuatro de los seis ni siquiera arrancan en otra
> máquina. Se equivoca en descartar la herramienta: ninguno de los cuatro fallos es culpa del
> formato —una ruta absoluta y una dependencia no declarada rompen un `.py` exactamente
> igual—. **El único defecto propio del formato es el estado oculto**, que es uno de cinco, y
> es el único que marimo elimina por diseño.
>
> **El umbral, dicho como criterio:** un cuaderno es un entregable el día que pasa esta
> auditoría en CI. Mientras no la pase, es una transcripción, y lo que se entrega es el `.py`
> al que se mudó su contenido. **La auditoría cuesta siete segundos: no hay excusa de costo
> para no tenerla.**

> 📝 **Lo que esta medición no dice.** No mide cuadernos reales de un equipo real —son seis
> generados, con defectos puestos a propósito—, así que el "1 de 6" **no es una estadística
> del mundo**: es una demostración de que cada defecto se detecta y de lo barato que es
> detectarlo. El ejercicio 22 pide correrlo sobre un repositorio de verdad, y ese número sí
> valdría. Tampoco mide el tiempo que cuesta *arreglar* un cuaderno roto, que es donde está
> el costo real.

---

## 🧱 7. Miniproyecto — La auditoría que corre en CI

**El encargo.** Patricia te dice: *"Marcela me manda cuadernos y yo no sé si sirven. Necesito
algo que los revise cuando los suba al repositorio y me diga en español qué está mal, sin que
yo tenga que abrir Jupyter."*

**Por qué duele.** Porque la parte fácil ya está escrita —ejecutar y ver si falla— y lo que
falta es lo difícil: **decidir qué es un error y qué es una advertencia**, y decirlo de forma
que alguien que no programa pueda actuar. Un informe que dice `NameError: name 'total' is not
defined` no le sirve a Patricia.

**Datos de entrada.** Los seis cuadernos de `generar_cuadernos.py`, más **dos que escribes
tú**: uno con un defecto que la sección no cubre y otro que parezca roto y no lo esté. Los dos
son parte del entregable.

**Criterios de aceptación.**

1. `python auditar.py cuadernos/` devuelve **código de salida 0** si todos pasan y **1** si
   alguno falla, para que sirva en CI.
2. Cada fallo se reporta con una línea en español que dice qué hacer, no qué excepción salió.
   *"La celda 2 usa `adquiridos`, que se define más abajo: ejecuta todo de arriba abajo antes
   de guardar"* en vez del `NameError`.
3. Distingue **error** de **advertencia**: no reejecutar es error; correr dando resultados
   distintos es advertencia con su explicación; tener los `execution_count` fuera de orden es
   advertencia aunque el cuaderno corra.
4. `--sin-ejecutar` hace la auditoría estática —orden de contadores, rutas absolutas, salidas
   guardadas, tamaño del archivo— en menos de **100 ms por cuaderno**, para el gancho de
   pre-commit.
5. Detecta y reporta las **salidas guardadas con datos**: si un cuaderno trae una tabla con
   documentos de pacientes en sus salidas, eso es un hallazgo de la frontera de la §5 de la
   historia de Áurea, no un detalle de formato.
6. Una prueba por cada clase de hallazgo, y los dos cuadernos que escribiste tú están en
   ella.

**Restricciones de registro.** Script: un archivo, `argparse`, códigos de salida que
signifiquen algo. Las dependencias de ejecución (`nbclient`, `ipykernel`) solo se importan en
el camino que las necesita: `--sin-ejecutar` tiene que funcionar sin ellas instaladas.

**La trampa.** El criterio 4. La auditoría estática es fácil de escribir y **fácil de
escribir mal**: vas a querer buscar rutas absolutas con una expresión regular sobre el texto
del cuaderno, y vas a marcar como defecto la cadena `/Users/` que aparece dentro de un
comentario o de una salida guardada. Un auditor que grita por cosas que no son se apaga a la
semana, y eso es peor que no tenerlo.

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

Son dos auditorías distintas con dos costos distintos: una lee el JSON y otra ejecuta. Escribe
la barata primero y completa, y que la cara sea opcional. La mayoría de los hallazgos salen
sin ejecutar nada.
</details>

<details><summary>Pista 2 — la herramienta</summary>

`nbformat.read` te da el documento como objeto; cada celda tiene `source`, `outputs` y
`execution_count`. Para analizar el código sin ejecutarlo, `ast.parse` sobre el `source` de
cada celda te da los nombres que define y los que usa — y con eso el estado oculto se detecta
**sin kernel**.
[docs.python.org/3.14/library/ast.html](https://docs.python.org/3.14/library/ast.html)
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def audit_static(path: Path) -> list[Finding]: ...
def audit_running(path: Path) -> list[Finding]: ...
def render(findings: list[Finding]) -> str: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-06 -m "Mini ds06: auditoría de cuadernos · <N> hallazgos sobre 8 · estática en <X> ms"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Abre `estado-oculto.ipynb` en un editor de texto y encuentra el problema sin ejecutarlo.
   Cronométrate: es el reflejo que hay que construir.
2. Corre la auditoría y lee los cuatro errores. Para cada uno, escribe la frase que le
   dirías a Marcela.
3. Toma `celda-borrada.ipynb` y arréglalo. Es el más difícil de los cuatro y la razón es que
   la información que falta no está en el archivo.
4. Ejecuta `azar-sin-semilla.ipynb` dos veces a mano y compara las salidas. Después arréglalo
   con una línea.
5. Haz `git diff` de un `.ipynb` al que le cambiaste una celda. Después haz lo mismo con el
   `.py` de marimo. Esa comparación es media sección.
6. Corre `cuaderno_marimo.py` como script y después con `marimo edit`. El mismo archivo, dos
   modos.

**🟡 Intermedio (7–14)**

7. Escribe la detección de estado oculto **sin ejecutar nada**, con `ast`: los nombres que
   cada celda define y los que usa, en orden de archivo. Después compara tu resultado con el
   `F821` que `ruff` ya reporta sobre los mismos cuadernos, y encuentra un caso donde tu
   versión acierte y la suya no —o al revés—. Es el ejercicio más útil de la lista.
8. Agrega a la auditoría la detección de salidas guardadas grandes —imágenes en base64— y
   reporta cuánto pesa el cuaderno por culpa de ellas.
9. Usa `papermill` para ejecutar `limpio.ipynb` con parámetros distintos y compara con
   ejecutarlo a mano. ¿Qué te da papermill que `nbclient` no?
10. Mide cuánto tarda la auditoría sobre veinte cuadernos y decide si cabe en un gancho de
    pre-commit o solo en CI.
11. Convierte `limpio.ipynb` a `.py` con `jupyter nbconvert --to script` y mira qué queda.
    Decide si eso es "mudarlo a un módulo" o no.
12. Escribe el mismo análisis del Embudo en un cuaderno de marimo y pásale la auditoría de la
    sección. ¿Qué hallazgos siguen apareciendo?
13. Configura `nbstripout` en un repositorio de prueba y comprueba qué pasa al hacer commit
    de un cuaderno con salidas. Decide si lo pondrías en el repositorio de Áurea. **No está en
    las versiones fijadas del curso**: si lo instalas, fija tú la suya y anótala, que es
    exactamente la disciplina de la Fase 07.
14. Un cuaderno que tarda cuarenta minutos en correr no cabe en CI. Diseña la estrategia —qué
    se audita siempre, qué se audita de noche— y justifícala.

**🟠 Difícil (15–21)**

15. Diagnóstico: un cuaderno pasa la auditoría en tu máquina y falla en CI. Enumera las cinco
    causas más probables en orden de frecuencia, y escribe la comprobación que distingue cada
    una.
16. La medición usa cuadernos generados. Constrúyete un conjunto **realista**: toma tu propio
    trabajo de `ds04` y `ds05`, pásalo a cuadernos como lo habrías escrito de verdad, y
    audítalos. Reporta el número, sea cual sea.
17. Implementa la comparación de salidas con tolerancia: dos corridas que difieren solo en un
    timestamp no deberían marcarse como inestables. Decide dónde poner la raya.
18. **De registro.** El análisis mensual del Embudo vive hoy en un cuaderno. ¿Se queda,
    se muda a un script o se vuelve una tarea del cierre nocturno de la Fase 15? Decide con
    el costo de las otras dos.
19. Un cuaderno con salidas puede llevar datos de pacientes al repositorio. Escribe la
    comprobación que lo detecta, con la definición de "dato identificable" que uses, y
    discute sus falsos positivos.
20. Toma marimo en serio: reescribe el tablero de `ds05` como cuaderno de marimo y evalúa qué
    perdiste. La respuesta honesta probablemente incluya "ecosistema".
21. Mide el costo real del formato: el mismo análisis como `.ipynb` con salidas, como
    `.ipynb` sin salidas y como `.py`. Tamaño, legibilidad del diff y tiempo de revisión.

**🔴 Muy difícil (22–25)**

22. **Corre la auditoría sobre un repositorio de verdad** —el tuyo, el de tu equipo, uno
    público con cuadernos— y publica el número con sus condiciones. Ese sí es una estadística
    del mundo, y el "1 de 6" de esta sección no lo es.
23. **Defiende lo contrario.** Construye el caso donde entregar un cuaderno es la decisión
    correcta y mudarlo a un módulo sería un error. Existe, y tiene que ver con quién lo lee.
24. Diseña la garantía que le falta a marimo: cómo detectarías, en un cuaderno de marimo, la
    ruta absoluta, la dependencia no declarada y el azar sin semilla. Impleméntalo.
25. **De registro.** Áurea contrata a una analista que solo trabaja en cuadernos. Escribe la
    política de una página: qué puede entregar, qué tiene que mudar, qué se audita y cuándo.
    Tiene que ser aplicable, no aspiracional.

**🔥 Opcionales**

- Mira cómo se ve un `.ipynb` en el visor de diffs de GitHub y compáralo con el archivo
  crudo. La distancia entre los dos explica por qué esto es un problema cultural y no técnico.
- Prueba `jupytext`, que sincroniza un `.ipynb` con un `.py`. Es la tercera familia de
  respuestas y no entró al cuerpo de la sección.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://nbformat.readthedocs.io/en/latest/format_description.html](https://nbformat.readthedocs.io/en/latest/format_description.html)
  — qué hay exactamente dentro de un `.ipynb`. Es corta y explica el `execution_count`.
- [https://nbclient.readthedocs.io/en/latest/](https://nbclient.readthedocs.io/en/latest/)
  — ejecutar cuadernos desde Python, que es lo que hace la medición.
- [https://papermill.readthedocs.io/en/latest/](https://papermill.readthedocs.io/en/latest/)
  — parametrizar y ejecutar cuadernos, con su modelo de celdas de parámetros.
- [https://docs.marimo.io/guides/reactivity/](https://docs.marimo.io/guides/reactivity/)
  — el grafo de dependencias, que es la idea entera de marimo.
- [https://docs.python.org/3.14/library/ast.html](https://docs.python.org/3.14/library/ast.html)
  — para el ejercicio 7: analizar el código sin ejecutarlo.

**Herramientas mencionadas**

- `nbstripout` y `jupytext` se nombran en los ejercicios y no entran al cuerpo. Búscalas por
  nombre; sus URL cambian de organización cada cierto tiempo.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan
> números de página, ISBN ni identificadores de video que no se hayan comprobado.

**Orden de lectura sugerido.** Antes de escribir código: la descripción del formato de
`nbformat` —quince minutos y entiendes el problema entero—. Durante: `nbclient`, cuando
escribas la auditoría. Después: la guía de reactividad de marimo, para decidir si te
interesa.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con la medición más barata del curso y con una posición defendible sobre cuadernos,
que es lo que hacía falta: **el cuaderno es para pensar y el módulo es para entregar**, y la
única prueba que separa una cosa de la otra cuesta siete segundos.

También terminas el bloque del Embudo. De aquí en adelante el proyecto es otro —Ausentismo— y
la naturaleza del trabajo cambia de raíz: hasta ahora todo fue **descripción**, contar lo que
pasó con los datos delante. `ds07` empieza a **predecir**, y con eso llegan dos cosas nuevas
que no existían en estas cinco secciones: un modelo que puede estar equivocado de formas que
no se ven, y una decisión que afecta a personas concretas.

Y llega con la disciplina que este bloque dejó instalada: **primero la línea base**. Antes de
entrenar nada, la regla de tres variables que cualquiera escribiría a mano, medida. Si la red
neuronal no le gana a eso, la red neuronal no entra.

> **La señal de que quedó bien:** cuando al recibir un cuaderno ajeno tu primer gesto sea
> mirar los `execution_count`, y cuando ejecutarlo en limpio te parezca tan normal como
> correr las pruebas de un pull request.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-06 -m "ds06 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 06: …`), los de ejercicio su número
> (`ds 06 ej12: …`) y el miniproyecto el suyo (`ds 06 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `ds-mini-06`, con **cuántos hallazgos encontró sobre los ocho
> cuadernos** en el mensaje. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
