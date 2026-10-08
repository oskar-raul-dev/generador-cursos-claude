# 🎁 Fase 09 ⭐ — Entregarle la herramienta a Patricia

> Python para desarrolladores Java senior · Fase 9 de 18 · Bloque B
> Depende de: Fase 08 · Habilita: Fase 10
> Registro de esta fase: **herramienta**
> Proyecto que avanza: **el CLI se entrega** — cierra el arco del proyecto 1
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Entregar software a alguien que no es ingeniero, en una máquina que no controlas. Es la fase que
más se parece al trabajo real que te espera después del curso, y la que menos se enseña.

Y es la fase que **no existiría en un curso de Go**, cosa que conviene decir de entrada porque
explica por qué está aquí: Go compila un binario estático, lo copias, se acabó la conversación.
No hay decisión que tomar, así que no hay nada que enseñar. En Python hay cuatro respuestas
legítimas, ninguna domina a las otras, y **elegir entre ellas es la lección completa**.

Al terminar, el CLI que nació como cuarenta líneas en la Fase 01 va a estar instalado en la
máquina de otra persona. Ese es el arco entero del proyecto 1, y es la tesis del curso demostrada
en lugar de enunciada.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `aur` está empaquetado de las cuatro formas, y las cuatro corren.
- [ ] Tienes la tabla con **tus** números: pasos del usuario, tamaño, arranque, qué pasa si no
      tiene Python, y qué hace falta para entregarle la versión siguiente.
- [ ] Puedes explicar por qué el ejecutable de un solo archivo arranca 56 veces más lento que el
      de un directorio, y decidir cuál entregarías.
- [ ] Tienes escrita la recomendación para Áurea, con la condición concreta que te haría
      cambiarla.
- [ ] Tienes resuelto **cómo se actualiza** lo que entregaste, que es la pregunta que nadie hace
      hasta que llega.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Publicar en un índice de paquetes** —PyPI, o uno interno para Áurea— es del track `pk` y no
  entra al camino base. La razón es que resuelve un problema que Áurea no tiene: un índice sirve
  cuando hay muchos consumidores anónimos, y aquí hay diez sedes y una administradora. Si algún
  día Áurea tiene equipo, el track está ahí.
- **Contenedores.** Se nombran en §5.5 con su costo, y la Fase 17 usa uno para medir arranque en
  frío. No hay fase de contenedores en este curso.
- **Firma de código y notarización.** Se nombran en §5.4 porque son la mitad del problema del
  ejecutable congelado en Windows y en macOS, y se quedan fuera con su razón: dependen de
  certificados que el lector no tiene y de trámites con Apple y con una autoridad certificadora
  que el curso no puede reproducir.
- **Actualización automática.** Se discute en §5.6 como decisión de diseño; construir un
  actualizador no entra.

---

## 🧠 4. Concepto mínimo

### El problema, que no es técnico

Tienes una herramienta que funciona. Patricia la necesita. Entre esas dos frases hay más
distancia de la que parece, y la distancia no la produce Python: la produce que **el otro lado no
es un entorno de desarrollo**.

Lo que hay del otro lado, en concreto: un portátil de la sede, sin permisos de administrador, con
un Python de origen desconocido instalado hace dos años, una persona que nunca ha abierto una
terminal, y un viernes a las siete de la tarde con el cierre sin terminar. Cualquier respuesta que
funcione solo cuando todo sale bien, no sirve.

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo, en dos tiempos.** El primero es *"que clone el repositorio y cree un entorno"*, y es
exactamente lo que responderías si te preguntaran ahora mismo. Es la respuesta que hace que
Patricia vuelva al Excel — no porque sea incapaz, sino porque son seis pasos y tres decisiones
que no son suyas, repetidos cada vez que haya una versión nueva.

El segundo tiempo es más interesante, porque es el que revela el modelo mental: **buscas el
equivalente del JAR ejecutable**. Un archivo, `java -jar`, y listo. La pregunta que traes es
*"¿cuál es el JAR de Python?"*, y la respuesta honesta es que **no hay**, y que eso no es un
descuido del ecosistema sino una consecuencia de una diferencia de fondo.

**Por qué falla:** un JAR funciona porque asume una JVM instalada, que es una pieza que tu
organización ya administra y que es compatible hacia atrás durante años. En Python el equivalente
—un intérprete compatible en la máquina de destino— es justamente lo que no puedes asumir: no hay
una versión "de empresa", las versiones menores no son intercambiables para código que usa
sintaxis nueva, y el `python` que haya ahí no lo puso nadie que supiera lo que hacía.

**Qué se escribe en su lugar:** en vez de buscar la respuesta única, **eliges** entre cuatro,
sabiendo qué asume cada una. Y la pregunta que ordena la elección no es técnica:

> 🧭 **¿Qué puede asumirse del otro lado?** Si puedes asumir un intérprete correcto, tienes tres
> opciones baratas. Si no puedes asumir nada, pagas el precio de llevarlo contigo — en tamaño, en
> arranque, y en discusiones con el antivirus.

### Esto sí funciona igual

**Tu criterio sobre versionado y compatibilidad se transfiere entero.** La disciplina de que la
versión signifique algo, de que un cambio incompatible se anuncie, y de que el usuario pueda
volver a la anterior es la misma, y aquí hace más falta porque no hay un repositorio corporativo
que la imponga.

**El problema de la actualización es el problema de siempre.** Cómo llega la versión nueva, cómo
sabes quién tiene cuál, y qué pasa con quien no actualiza. En tu mundo lo resolvía un pipeline;
aquí lo resuelves tú, y la buena noticia es que el criterio ya lo tienes.

**Y la idea de que el entregable se prueba como lo recibe el usuario** es la misma disciplina que
te hizo desconfiar de "en mi máquina funciona". El layout `src/` de la Fase 07 existía por esto,
y hoy se cobra.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| JAR ejecutable + `java -jar` | `.pyz` (zipapp) + `python app.pyz` | La idea es idéntica; la diferencia es que la JVM se asume instalada y el intérprete no |
| *Fat JAR* / *uber-JAR* | `.pyz` con dependencias adentro | Igual de válido, y con el mismo problema: las dependencias con código compilado no siempre viajan |
| `jpackage` / GraalVM native-image | PyInstaller, Nuitka | El resultado no es un binario nativo: es tu intérprete y tu código dentro de un archivo que se desempaqueta |
| El JRE instalado en la máquina | el intérprete que haya, o ninguno | Nadie administra los Python de las máquinas de tu empresa. Nadie |
| Repositorio corporativo de artefactos | índice de paquetes propio | Existe, se puede montar, y es del track `pk` |
| `brew install` / `apt install` de tu herramienta | `uv tool install` / `pipx install` | Muy parecido, con la diferencia de que instala en el directorio del usuario y no necesita administrador |

> 📝 **Nota de ecosistema — `pipx` y `uv tool`.** Durante años la respuesta a "quiero instalar una
> herramienta de Python sin que se mezcle con nada" fue `pipx`, que creaba un entorno aislado por
> herramienta y ponía el ejecutable en el `PATH` del usuario. Sigue funcionando y sigue siendo
> perfectamente válido; `uv tool` hace lo mismo con el mismo modelo, más rápido y con la ventaja
> de que además puede traerse el intérprete. El curso usa `uv tool` porque `uv` ya es el gestor
> desde la Fase 07, no porque `pipx` esté mal. Si llegas a una empresa donde solo hay `pipx`, es
> el mismo concepto con otro comando.

### Las cuatro formas, en una frase cada una

**Instalación aislada** (`uv tool install` / `pipx`): la herramienta vive en su propio entorno y
su ejecutable aparece en el `PATH` del usuario. Asume que la máquina puede conseguir un
intérprete — `uv` lo baja si hace falta.

**Archivo único ejecutable** (`zipapp`, un `.pyz`): tu código comprimido en un ZIP con una
cabecera que dice cómo ejecutarlo. Asume un intérprete compatible instalado.

**Script autocontenido** (PEP 723): **un solo archivo `.py`** que declara sus dependencias en un
comentario en la cabecera, y que `uv run` ejecuta resolviéndolas al vuelo. Asume `uv`.

**Ejecutable congelado** (PyInstaller): tu código, el intérprete y todo lo demás dentro de un
ejecutable. No asume nada — y lo paga.

---

## 💻 5. Las cuatro formas, construidas

### 5.1 Instalación aislada

```bash
uv tool install .
```

```text
Installed 1 executable: aur
```

Eso es todo. Crea un entorno propio para `aur` fuera del proyecto, instala el paquete de la Fase
07, y deja el ejecutable en el directorio de herramientas del usuario. No toca el entorno de
ningún otro proyecto, no necesita administrador, y `aur` funciona desde cualquier directorio.

```bash
aur --version     # aur 0.7.0
uv tool upgrade aur    # la actualización, cuando haya versión nueva
uv tool uninstall aur  # y la desinstalación, que también cuenta
```

**Detalles con intención**

- **La primera vez hay que arreglar el `PATH`.** `uv` avisa —`uv tool update-shell`— y ese es un
  paso que Patricia no va a dar sola. Anótalo: cuenta para la tabla.
- **El entorno resultante pesa 128 KB**, porque `aur` no tiene dependencias y el intérprete se
  enlaza en vez de copiarse. Ese número va a cambiar mucho en la Fase 10, cuando entre FastAPI.
- **Y la actualización es un comando**, que es la ventaja que las otras tres no tienen.

### 5.2 Archivo único: `zipapp`

Un `.pyz` es un ZIP con tu código y una cabecera que dice qué ejecutar. Está en la biblioteca
estándar desde 3.5, no necesita instalar nada, y casi nadie sabe que existe:

```bash
mkdir build-pyz
cp -r src/aur build-pyz/
python -m zipapp build-pyz --output aur.pyz --main "aur.cli:main" --python "/usr/bin/env python3"
```

```bash
python aur.pyz --version    # aur 0.7.0
```

**6.9 KB.** Un archivo, que se manda por correo, que se copia a una carpeta compartida, y que no
instala nada en ninguna parte. Y como la cabecera lleva el `#!`, en Linux y macOS basta con
`chmod +x aur.pyz` para que `./aur.pyz` funcione directo — comprobado.

> ⚠️ **Y lo que hay que decir de inmediato:** eso funciona porque `aur` no tiene dependencias.
> Con dependencias puras de Python se puede meterlas adentro (`pip install --target build-pyz`) y
> sigue funcionando. Con dependencias que traen código compilado —las que el track de datos usa
> todo el tiempo— **deja de funcionar**, porque un `.pyz` no puede cargar una biblioteca binaria
> desde dentro del ZIP sin extraerla primero. Es la limitación que decide si esta opción está
> disponible para ti, y depende de tus dependencias, no de tu código.

En Windows, el instalador oficial asocia `.pyz` con el lanzador, así que **el doble clic
funciona** — que es exactamente el gesto que Patricia sí hace. Verifícalo antes de prometerlo: la
asociación existe si Python se instaló con el instalador de python.org, y no si llegó por otro
camino.

### 5.3 Script autocontenido: PEP 723

Un solo archivo `.py` que declara sus dependencias **adentro**, en un comentario con formato:

```python
# /// script
# requires-python = ">=3.13"
# dependencies = ["httpx==0.28.1"]
# ///
"""Reporte de glosas por vencer. Un archivo, y dice lo que necesita."""

import httpx
...
```

```bash
uv run cierre.py
```

`uv` lee la cabecera, crea un entorno efímero con lo que pide, y lo ejecuta. La primera vez con
la caché vacía tarda **1.7 s**; las siguientes, **99 ms**.

Esto es lo más cercano que tiene Python a *"te mando el archivo y ya"* **con dependencias
incluidas**, y es una capacidad relativamente nueva que mucha gente con años de Python no conoce.
Para el curso importa por una razón adicional: es la forma correcta de escribir esos scripts de
pegamento que la vida de Áurea produce sin parar —el que lee el cuaderno de Zipaquirá, el que
convierte un export raro— sin convertirlos en proyectos.

**El patrón a memorizar**

> Un script con cabecera PEP 723 es un script que declara su entorno. Sigue siendo el registro
> script —un archivo, sin estructura, sin instalación— pero deja de mentir sobre lo que necesita.
> Es la respuesta a "esto no merece ser un proyecto, pero necesita dos bibliotecas".

> 📝 **Nota de ecosistema.** PEP 723 se aprobó en 2024, y antes de él la única forma de decir qué
> necesitaba un script suelto era un comentario en prosa que nadie leía o un `requirements.txt` al
> lado que se perdía. Vas a encontrar muchísimo código sin esta cabecera; no está roto, es
> anterior. Y la cabecera la entiende más de una herramienta, no solo `uv`: es un estándar, no un
> formato propietario.

### 5.4 Ejecutable congelado

La opción que no asume nada: tu código, el intérprete y todo lo demás dentro de un ejecutable.

```bash
uv pip install pyinstaller==6.22.3
pyinstaller --onefile --name aur --paths src src/aur/__main__entry.py
```

Y aquí aparece el número más interesante de la fase. Las dos variantes de PyInstaller sobre
exactamente el mismo código:

| | `--onefile` | `--onedir` |
|---|---|---|
| Qué produce | un ejecutable | una carpeta con 49 archivos |
| Tamaño | **8.4 MB** | 31.2 MB |
| Tiempo de construcción | 8.0 s | 5.8 s |
| **Arranque** | **3 099 ms** | **55 ms** |

**Tres segundos.** El "archivo único" —lo que suena a la respuesta ideal, lo que se parece al JAR
que estabas buscando— arranca **56 veces más lento** que la carpeta.

La causa no es misteriosa y conviene entenderla porque explica el número: en modo `--onefile`, el
ejecutable **se desempaqueta completo en un directorio temporal en cada ejecución**, corre desde
ahí, y lo borra al salir. No es un binario nativo que se carga: es un ZIP que se extrae. Ese es el
precio del archivo único, y casi ninguna guía lo publica.

**Y lo que no se mide pero decide igual:**

- **El antivirus.** Un ejecutable sin firmar que se autoextrae en un temporal es, literalmente, el
  comportamiento que los antivirus buscan. En Windows corporativo, la probabilidad de que
  SmartScreen o el antivirus de la empresa lo bloqueen no es despreciable, y el mensaje que ve
  Patricia dice que el archivo es peligroso. Firmarlo lo resuelve; firmarlo cuesta un certificado
  y un trámite, y queda fuera del curso (§3).
- **Hay que construirlo en cada plataforma.** PyInstaller no hace compilación cruzada: el
  ejecutable de Windows se construye en Windows. Si tu máquina es un Mac y Patricia usa Windows,
  necesitas una máquina Windows o un CI que la tenga.
- **Y la actualización es un archivo nuevo.** No hay `upgrade`: hay volver a mandar 8.4 MB y
  confiar en que reemplace el anterior y no lo guarde como `aur (2).exe`.

### 5.5 La quinta opción, y por qué casi nunca es la respuesta

**Un contenedor.** Resuelve el problema de verdad —el entorno completo, reproducible, idéntico en
todas partes— y por eso es la respuesta correcta en el servidor, que es donde la Fase 17 lo usa.

En el portátil de una sede es otra cosa: requiere instalar Docker Desktop (administrador, licencia
para empresas de cierto tamaño, un servicio corriendo), y convierte *"abre el programa"* en
*"abre una terminal y escribe `docker run -v $(pwd)/data:/data aur resumen ...`"*, que incluye
explicarle a Patricia qué es un volumen. **El costo no está en el contenedor: está en que el
usuario tiene que entenderlo.**

Se nombra, se cierra, y se declara fuera de alcance. No se enlaza a ninguna parte: el contenedor
como forma de distribuirle una herramienta a Patricia está resuelto aquí —no sirve—, y el
contenedor como forma de desplegar un servicio es otro tema y otro curso, que este no promete.

### 5.6 La pregunta que nadie hace: cómo se actualiza

Toda la conversación anterior es sobre la **primera** entrega. La segunda es la que decide si tu
herramienta sobrevive, porque va a haber una: dentro de tres semanas vas a arreglar algo y
Patricia va a necesitar la versión nueva un día que tú estés de vacaciones.

Lo que cada opción puede ofrecer:

**Instalación aislada** tiene `uv tool upgrade aur`, un comando, y es la única de las cuatro con
una respuesta de una línea. Si el paquete está en un índice —que es del track `pk`— la
actualización ni siquiera necesita que le mandes nada.

**`.pyz` y script PEP 723** se actualizan reemplazando el archivo, lo que es simple y tiene un
problema real: **no hay forma de saber qué versión tiene cada quien**. Cuando Patricia diga "me
sale un error", tu primera pregunta va a ser cuál versión tiene, y la respuesta va a ser "la que
me mandaste". Mitigación barata y obligatoria: que la herramienta imprima su versión en cada
ejecución, no solo con `--version`.

**Ejecutable congelado** es lo mismo pero con 8.4 MB por correo, y con el antivirus opinando cada
vez.

> 🧭 **El criterio que ordena la decisión, y es el que te llevas:** elige por la **segunda**
> entrega, no por la primera. La primera la haces tú, en persona, con tiempo. La segunda la hace
> ella sola, con prisa, y es la que define si la herramienta se queda o se abandona.

---

## 📏 6. Medición — las cuatro formas, con las columnas del otro lado

**Hipótesis.** No hay una forma que domine a las demás. La que menos pasos le pide al usuario no
es la más pequeña, la más pequeña no es la que mejor se actualiza, y la que no asume nada —la que
suena ideal— paga el precio en el arranque.

**Condiciones.** macOS 26.6 · Apple Silicon, 8 núcleos · CPython 3.14.5 · `uv` 0.12.13 ·
PyInstaller 6.22.3 · el paquete `aur` de la Fase 07, **sin dependencias de terceros** —dato que
favorece a las opciones basadas en archivo y hay que declararlo—. Arranque: mediana y p95 de 10
ejecuciones de `aur --version`, medidas desde un proceso padre, con la caché del sistema de
archivos caliente.

**Competidores.** Las cuatro formas reales, cada una construida como la construiría alguien que
la conoce; y del ejecutable congelado se miden **las dos variantes**, porque comparar solo
`--onefile` sería quedarse con la peor mitad y presentarla como si fuera la opción.

**Resultado.**

| | `uv tool install` | `.pyz` (zipapp) | PEP 723 + `uv run` | Congelado `--onefile` | Congelado `--onedir` |
|---|---|---|---|---|---|
| Tamaño del entregable | 128 KB *(entorno)* | **6.9 KB** | **1 archivo** | 8.4 MB | 31.2 MB, 49 archivos |
| Construirlo | 0.3 s | 2 ms | — | 8.0 s | 5.8 s |
| Arranque (mediana) | **49 ms** | 54 ms | 99 ms | **3 099 ms** | 55 ms |
| ¿Necesita Python instalado? | no: `uv` lo trae | **sí** | no: `uv` lo trae | **no** | **no** |
| ¿Necesita instalar algo? | sí: `uv` | no | sí: `uv` | no | no |
| Pasos del usuario | 3 | **1** | 2 | **1** | 2 |
| Actualizar | **un comando** | mandar el archivo | mandar el archivo | mandar 8.4 MB | mandar una carpeta |
| ¿Sabes qué versión tiene? | sí | no | no | no | no |
| Dependencias compiladas | sí | **no** | sí | sí | sí |
| Riesgo con el antivirus | ninguno | ninguno | ninguno | **alto** | medio |

> ⚖️ **Veredicto.** **Para Áurea, la recomendación es la instalación aislada con `uv tool`**, y
> el argumento decisivo está en dos filas: es la única que se actualiza con un comando y la única
> que te deja saber qué versión tiene cada quien. Los 49 ms de arranque son un bono, no la razón.
>
> **Dónde pierde, y hay que decirlo:** son tres pasos, uno de los cuales es arreglar el `PATH`, y
> requiere instalar `uv` en una máquina que no es tuya. Si Édgar no lo autoriza, esta opción
> simplemente no existe y toda la recomendación cambia.
>
> **El `.pyz` es la segunda opción y está más cerca de lo que parece.** 6 KB, un archivo, doble
> clic en Windows, cero instalación. Pierde en la actualización a ciegas y en que no soporta
> dependencias compiladas — pero para un `aur` sin dependencias, y para un uso mensual, es una
> respuesta perfectamente defendible que además es la más barata de producir. **Si mañana Áurea
> me dijera que no se puede instalar nada en las máquinas, esta es la respuesta**, y no me
> parecería un mal día.
>
> **El ejecutable congelado sale peor de lo que su reputación sugiere**, y el número que lo hunde
> no es el tamaño: son los **3 099 ms** del modo archivo único. Tres segundos de nada, cada vez,
> en la única opción que se eligió justamente por comodidad. En modo `--onedir` el arranque se
> arregla (55 ms) pero deja de ser un archivo, que era el punto — y 31 MB en 49 archivos por
> correo no es una entrega, es una mudanza. **La única situación donde gana de verdad es la que
> importa cuando pasa: una máquina donde no se puede instalar nada y no hay Python.** Ahí no hay
> alternativa, y entonces sus tres segundos son baratos.
>
> **Y hay un empate que hay que nombrar:** en arranque, `uv tool` (49 ms), `.pyz` (54 ms) y
> congelado `--onedir` (55 ms) están dentro del ruido. Tres formas radicalmente distintas con el
> mismo costo de arranque. El arranque, que es lo que todo el mundo mide primero, resulta ser la
> columna que menos decide de toda la tabla — salvo para descartar `--onefile`.
>
> **El umbral donde cambia la respuesta:** si el usuario ejecuta la herramienta muchas veces al
> día o desde un proceso automático, `--onefile` queda descartado y el resto empata. Si la
> ejecuta una vez al mes —que es el caso de Patricia—, el arranque deja de importar del todo y
> **deciden las dos últimas filas: la actualización y las dependencias**.

**Lo que no se midió, y se declara.** Ninguna medición en Windows, que es la plataforma de
Patricia, y es la plataforma donde más cambian dos de estas columnas: el antivirus y la asociación
del doble clic. Tampoco se midió con dependencias de terceros: `aur` no tiene, y eso favorece al
`.pyz` de una forma que dejará de ser cierta en la Fase 10. Tampoco se midió la opción del
contenedor, por la razón de §5.5. Y el tamaño de `uv tool install` (128 KB) **no incluye el
intérprete**, que se enlaza al que ya existe; si `uv` tiene que bajar uno, son 25 MB más — medidos
en la Fase 07.

---

## 🧱 7. Miniproyecto — *La entrega de verdad*

**El encargo**

Julián te llama un martes: *"Patricia dice que el programa le sirve. Quiero que lo usen también
Yuli y la auxiliar de Kennedy, y que no dependan de ti para nada. Y mira, te lo digo directo:
Édgar preguntó por qué hay que instalar 'programas raros' en los portátiles de las sedes, así que
lo que propongas tiene que aguantar esa conversación."*

Empaqueta `aur` de las cuatro formas, mídelas en tu máquina, y escribe la recomendación para
Áurea — sabiendo que quien la va a ejecutar cierra el mes un viernes a las siete de la tarde, y
que quien la tiene que aprobar es alguien que desconfía.

**Por qué duele**

Porque la opción técnicamente mejor y la correcta para Patricia no son la misma, y porque hay una
restricción política —Édgar— que no se resuelve con ningún número pero que cambia la respuesta.
Este miniproyecto **se evalúa por la justificación, no por el empaquetado**: las cuatro
construcciones son la parte fácil.

**Datos de entrada**

El paquete `aur` tal como quedó en la Fase 08, con sus tipos y sus pruebas. Y tres escenarios que
tienes que poder responder por escrito, porque son los que van a pasar:

1. **Patricia, primera vez.** Máquina de la sede, sin administrador, Python de origen
   desconocido, sin terminal abierta jamás.
2. **La auxiliar de Kennedy, tres semanas después.** Misma máquina, y tú acabas de arreglar un
   error en el cálculo de una glosa. Ella no sabe que hay versión nueva.
3. **Un lunes de enero.** Alguien reporta que "el programa da mal un número". Tienes que
   averiguar qué versión está corriendo, en cuál de las tres máquinas, y si el error ya estaba
   arreglado.

**Criterios de aceptación**

- [ ] Las **cuatro** formas construidas y ejecutándose de verdad, cada una con el comando exacto
      que la produce, guardado en un script para poder repetirlo.
- [ ] El ejecutable congelado, medido en **sus dos variantes**. Una tabla que solo traiga
      `--onefile` está incompleta.
- [ ] Tu propia tabla con las columnas de la sección 6, con tus números.
- [ ] **La recomendación, de media página**, con: la opción elegida, el argumento que convence a
      Édgar, la opción descartada que más te costó descartar, y la condición concreta que te haría
      cambiar de opinión.
- [ ] **Los tres escenarios contestados**, en dos o tres frases cada uno. El tercero es el que
      separa una entrega de un regalo.
- [ ] **Medición:** el arranque —mediana de al menos 10 ejecuciones— de la opción que recomiendas,
      y el tamaño del entregable. Esos dos números van en el mensaje del tag.

**Restricciones de registro**

> Esto sigue siendo una **herramienta**, y la restricción es que no puedes resolver el problema
> cambiando de registro. Si tu respuesta es *"mejor hagamos una aplicación web y que entren por
> el navegador"*, estás resolviendo otro encargo — uno legítimo, que es la Fase 12, y que a
> Áurea le va a costar un servidor, autenticación, y que Patricia tenga internet en la sede el
> viernes a las siete. Escríbelo como alternativa si quieres, con su costo, pero el entregable de
> hoy es la herramienta entregada.

**La trampa**

Vas a medir el arranque y vas a descubrir los tres segundos del `--onefile`, y con eso vas a
sentir que ya tienes el veredicto. No lo tienes: **para un uso mensual, el arranque es la columna
que menos importa de la tabla**, y si tu recomendación se apoya en ella, se apoya en lo que no
decide.

La que decide está en el escenario 3, y es la pregunta que casi nadie se hace hasta que le pasa:
¿cómo averiguas qué versión está corriendo en la máquina de otra persona? Tres de las cuatro
opciones no tienen una buena respuesta, y la que la tiene no es la más cómoda de instalar.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Construye primero las cuatro, sin medir nada. Son un rato; el `.pyz` son dos minutos y el
congelado es el único que tarda.

Después mide, con el mismo arnés del curso y no con `time` a ojo, y con al menos diez
repeticiones: la diferencia que vas a encontrar es tan grande que no hace falta estadística, pero
la disciplina sí.

Y solo al final escribe la recomendación. Si la escribes antes de medir, vas a estar defendiendo
lo que ya pensabas.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`zipapp`](https://docs.python.org/3.14/library/zipapp.html) — está en la biblioteca estándar,
  y la documentación explica también cómo meter dependencias adentro.
- [`uv tool`](https://docs.astral.sh/uv/concepts/tools/) — instalación, actualización y
  `update-shell`.
- [PEP 723](https://peps.python.org/pep-0723/) — el formato exacto de la cabecera. Es corto.
- [PyInstaller](https://pyinstaller.org/en/stable/usage.html) — `--onefile` contra `--onedir`, y
  la sección de por qué el primero es más lento, que la documentación explica sin rodeos.

Para el escenario 3, mira qué hace `aur --version` hoy y pregúntate de dónde saca ese número en
cada una de las cuatro formas.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def build_all() -> dict[str, Path]:
    """Construye las cuatro (cinco, con las dos variantes del congelado)."""

def measure_startup(command: list[str], reps: int = 10) -> dict[str, float]:
    """Mediana y p95 de `--version`, con el arnés del curso."""

def entregable_size(path: Path) -> tuple[float, int]:
    """MB y número de archivos. La carpeta del --onedir cuenta como uno solo si mientes."""
```

Y el informe se llama `INFORME-ENTREGA.md`.
</details>

**Cómo se entrega**

```bash
python construir_entregables.py     # las cuatro formas y la tabla
$EDITOR INFORME-ENTREGA.md          # la recomendación y los tres escenarios
```

```bash
git add construir_entregables.py INFORME-ENTREGA.md
git commit -m "fase 09 mini: las cuatro entregas medidas y la recomendación para Áurea"
git tag -a mini-09 -m "Mini F9: entrega de aur · <opción> · arranque <N> ms, entregable <M>"
```

<details><summary>💡 Solución de referencia — el estándar del informe</summary>

**La decisión que se tomó, y por qué.** `uv tool install`, por el escenario 3. Es la única de las
cuatro donde la pregunta *"¿qué versión tienes?"* tiene una respuesta que no depende de la memoria
de nadie, y es la única donde la actualización no consiste en mandar un archivo y confiar. Los 49
ms no entran en el argumento.

**El argumento que convence a Édgar**, que es la parte del encargo que no es técnica: `uv` no
instala nada en el sistema ni necesita administrador — escribe en el directorio del usuario, y se
desinstala borrando una carpeta. Eso es verificable delante de él en dos minutos, y es la
diferencia entre "un programa raro" y "un archivo en la carpeta de Patricia". Un informe que
ignore a Édgar está incompleto aunque la tabla esté perfecta: él es quien aprueba.

**El otro camino defendible, reconocido.** El `.pyz`, y de verdad: 6 KB, doble clic en Windows,
cero instalación, cero conversación con Édgar. Para un `aur` sin dependencias de terceros es una
respuesta excelente, y su única debilidad seria es la actualización a ciegas — que se mitiga
haciendo que la herramienta imprima su versión en cada corrida y que el nombre del archivo la
lleve (`aur-0.7.0.pyz`). Si el veto de Édgar llega, esta es la respuesta, y no es un plan B
vergonzoso.

**La trampa, explicada entera.** Los 3 099 ms del `--onefile` son el número más llamativo de la
fase y el menos relevante para este encargo: Patricia corre esto una vez al mes. Una
recomendación que descarte el congelado por lento está descartándolo por la razón equivocada —
hay que descartarlo por el antivirus, por los 8.4 MB en cada actualización, y por que hay que
construirlo en Windows. Y al revés: si el encargo fuera "esto lo invoca el proceso nocturno
cuatrocientas veces", los tres segundos pasarían a ser el argumento principal. **El mismo número
decide o no decide según quién ejecute.**

**Qué se habría hecho distinto si el registro fuera otro.** Como script —un archivo, sin
dependencias— la respuesta habría sido mandarlo por correo y ya, con el riesgo de que el
intérprete de la máquina no sirviera. Como aplicación, nada de esta fase existiría: se
desplegaría en un servidor y Patricia abriría un navegador, cambiando el problema de distribución
por uno de operación —que es más caro, pero se paga una vez y no diez. **Esa comparación es la
que hay que tener en la cabeza el día que alguien te diga "hagamos una web y listo": no es que
esté mal, es que mueve el costo de sitio.**
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Construye el `.pyz` y ejecútalo desde tres directorios distintos. Explica en una línea por qué
   funciona sin haber instalado nada.
2. Haz que `aur` imprima su versión en la primera línea de cada ejecución, no solo con
   `--version`. Justifica por qué eso es más importante de lo que parece.
3. Instala `aur` con `uv tool install`, actualízalo tras subir la versión a `0.9.1`, y
   desinstálalo. Documenta los tres comandos y qué quedó en disco después del tercero.
4. Escribe un script con cabecera PEP 723 que use una dependencia y ejecútalo con `uv run`.
   Después bórrale la cabecera y mira el error.
5. Construye el congelado en las dos variantes y comprueba tú mismo la diferencia de arranque.
   Reporta tus dos números.
6. Averigua dónde deja `uv tool install` el entorno y el ejecutable en tu sistema operativo, y
   comprueba que borrar esos dos sitios desinstala la herramienta.

**🟡 Intermedio (7–14)**

7. Mete una dependencia pura de Python dentro del `.pyz` (`pip install --target`) y comprueba que
   sigue funcionando. Mide cuánto creció el archivo.
8. Intenta lo mismo con una dependencia que traiga código compilado. Documenta exactamente cómo
   falla: el mensaje importa más que el hecho.
9. Lee la documentación de `zipapp` y averigua qué hace la opción `--compress`. Mídela sobre tu
   `.pyz` y decide si vale la pena.
10. Consulta la documentación de PyInstaller sobre por qué `--onefile` es más lento, y localiza en
    tu sistema el directorio temporal donde se extrae durante una ejecución.
11. Haz que el congelado incluya un archivo de datos —`tarifas.toml`— y que lo encuentre en
    tiempo de ejecución. Averigua qué es `sys._MEIPASS` y por qué hace falta.
12. Escribe el `README` de tres párrafos que acompaña a la entrega, dirigido a Patricia y no a un
    ingeniero. Dáselo a leer a alguien que no programe y anota en qué frase se atascó.
13. Compara `pipx install` con `uv tool install` sobre el mismo paquete: tiempo, disco y pasos.
    Decide si la elección del curso se sostiene.
14. Averigua qué es Nuitka y en qué se diferencia de PyInstaller. Construye `aur` con él si puedes
    y compara las tres columnas que importan; si no puedes, documenta por qué no.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Patricia dice que hizo doble clic en el `.pyz` y "se abrió una ventana negra
    y se cerró". Reproduce ese escenario, explica qué pasó, y da las dos formas de arreglarlo
    para que ella vea el resultado.
16. **Diagnóstico.** El congelado funciona en tu máquina y falla en la de un compañero con
    `ModuleNotFoundError`. Enumera las tres causas más probables —hay una que tiene que ver con
    imports que PyInstaller no puede ver— y el comando que confirma cada una.
17. **Medición.** Mide el arranque de las cinco formas con el arnés del curso, 30 repeticiones,
    reportando mediana y p95. Compara tu p95 del `--onefile` con tu mediana: la dispersión de esa
    opción cuenta una historia que la mediana esconde.
18. **Medición.** Mide cuánto tarda la **primera** ejecución de cada forma en una máquina donde
    nunca se ha corrido —caché del sistema de archivos fría, si puedes forzarla—. Esa es la
    ejecución que Patricia recuerda.
19. **Medición.** Construye el congelado con el paquete de la Fase 10 —cuando exista— o simula el
    caso agregando FastAPI como dependencia, y mide cuánto crece el ejecutable. Extrapola qué
    pasaría si Áurea distribuyera la API así, y explica por qué no se hace.
20. **De registro.** Áurea quiere que el cierre se pueda correr "desde el celular de Julián".
    Decide qué registro es eso, qué tendría que cambiar, y si alguna de las cuatro formas de esta
    fase sirve. La respuesta puede ser que ninguna.
21. **De registro.** Un script tuyo de treinta líneas, con dos dependencias, lo necesita ahora una
    segunda persona. Decide entre convertirlo en paquete (Fase 07) o dejarlo como script con
    cabecera PEP 723. Justifica con el costo de las dos, y nota que esta vez la respuesta barata
    puede ser la correcta.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Consigue que el ejecutable congelado falle en una máquina limpia por una
    razón que no sea el antivirus. Hay al menos dos caminos: una biblioteca del sistema que
    PyInstaller no empaquetó, y una ruta que tu código asume. Documenta el fallo, el mensaje que
    ve el usuario, y el arreglo.
23. **Defiende una decisión.** Escribe el argumento más fuerte que puedas **a favor del ejecutable
    congelado** para Áurea — existe y no es débil— y después respóndelo con los datos de la
    sección 6. Termina nombrando la condición bajo la cual tu propio argumento a favor gana, y di
    si Áurea la cumple.
24. **Diseño.** Resuelve el escenario 3 del miniproyecto para la opción `.pyz`: diseña un
    mecanismo —sin construir un actualizador automático— que te permita saber qué versión corre
    cada máquina. Tiene que funcionar sin red y sin que Patricia haga nada especial. Hay al menos
    dos respuestas buenas.
25. **Adversarial y de criterio.** Entrega `aur` de la forma que recomendaste a una persona real
    que no sea desarrolladora —alguien de tu casa o de tu trabajo— sin ayudarla. Anota cada punto
    donde se atascó, y cuántos minutos tardó. Después reescribe tu recomendación con eso delante.
    Es el ejercicio más incómodo del curso y el que más cambia la respuesta.

**🔥 Opcionales**

- Averigua qué es `shiv` y en qué se diferencia de `zipapp` puro. Construye `aur` con él.
- Mira cómo distribuyen sus herramientas tres proyectos de Python que uses a diario. Anota cuál de
  las cuatro formas usa cada uno y qué asume de tu máquina.
- Construye el congelado en Windows con un CI gratuito y baja el artefacto. Documenta cuánto
  tardó y qué tuviste que aprender que no sabías.

---

## 📚 9. Referencias

**Documentación oficial**

- [`zipapp`](https://docs.python.org/3.14/library/zipapp.html) — la biblioteca estándar, con la
  sección de cómo incluir dependencias y las limitaciones de las extensiones compiladas.
- [Guía de empaquetado: distribuir aplicaciones](https://packaging.python.org/en/latest/overview/)
  — el panorama completo, con el criterio de cuándo sirve cada forma.
- [`uv tool`](https://docs.astral.sh/uv/concepts/tools/) — instalación aislada, `upgrade` y
  `update-shell`.
- [PyInstaller](https://pyinstaller.org/en/stable/) — en particular *When things go wrong* y la
  explicación de `--onefile`.
- [`pipx`](https://pipx.pypa.io/) — el mismo modelo que `uv tool`, y el que vas a encontrar en
  empresas que no han migrado.

**PEPs**

- [PEP 723](https://peps.python.org/pep-0723/) — metadatos embebidos en un script. Corto y vale
  la pena leerlo entero.
- [PEP 441](https://peps.python.org/pep-0441/) — de dónde salió `zipapp`, en 2013, y qué problema
  resolvía.

**Orden de lectura sugerido.** Antes de construir: el PEP 723, que son diez minutos. Durante:
`zipapp` y `uv tool`, cada uno cuando toque. Después: la sección de PyInstaller sobre `--onefile`,
que se entiende mucho mejor cuando ya mediste los tres segundos tú mismo.

> ⚠️ URLs y contenidos cambian. PyInstaller y `uv` publican seguido; verifica contra las versiones
> fijadas en esta fase.

---

## 🚀 10. Cierre y conexión con la siguiente fase

El CLI nació como cuarenta líneas con `open` y `split(",")` en la Fase 01, y hoy está instalado en
la máquina de otra persona. Ese arco —nueve fases, un archivo que se volvió paquete y después
entregable— es la tesis del curso completa, y a partir de aquí solo se amplía: en la Fase 15, el
proceso nocturno va a importar este mismo paquete como biblioteca, y ese día vas a ver de golpe
para qué servía todo lo de la Fase 07.

Te llevas dos cosas. La primera es que **en Python no hay una respuesta única a la distribución**,
y que buscarla es el error: hay cuatro, se eligen midiendo, y la columna que decide casi nunca es
la que mediste primero. La segunda es más transferible todavía: **elige por la segunda entrega,
no por la primera.**

El **Bloque B se cierra aquí**. Sabes reconocer cuándo algo cruzó la línea, sabes migrarlo sin
reescribirlo, sabes ponerle tipos y pruebas, y sabes entregarlo. Eso es el registro *herramienta*
completo.

La **Fase 10** abre el Bloque C y cambia de registro otra vez: entra la **aplicación**, y nace
AgendaAPI — la agenda de la red, con la disponibilidad de diez sedes y las reservas desde la web y
el bot. La idea que la ordena es que se valida **en la frontera**, una sola vez, y que hacia
adentro el dato ya es de fiar. Y trae una advertencia que viene directo de esta fase: en el Bloque
C la ceremonia deja de ser un exceso y pasa a ser el piso — pero solo la que el registro pide, no
la que tu instinto de Java te va a sugerir.

> **La señal de que quedó bien:** la próxima vez que alguien te pregunte "¿y cómo lo distribuyo?",
> tu primera respuesta no va a ser una herramienta — va a ser una pregunta: *"¿qué podemos asumir
> de la máquina del otro lado?"*.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-09 -m "F9 cerrada:
> - aur empaquetado de las cuatro formas, y las cuatro corren
> - las dos variantes del congelado medidas, con la diferencia de arranque explicada
> - la tabla con las columnas del otro lado: pasos, tamaño, arranque, actualización
> - la recomendación para Áurea escrita, con su condición de cambio
> - los tres escenarios de entrega contestados, incluido el de la versión desconocida
> - Bloque B cerrado: el CLI corre en la máquina de otra persona"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 09: …`), los de ejercicio su número
> (`fase 09 ej12: …`) y el miniproyecto el suyo (`fase 09 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-09`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
