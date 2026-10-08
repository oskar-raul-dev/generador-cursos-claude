# 🔍 El script de integridad, explicado como para un bebé

> **Qué es esto:** la explicación de [`check-course.sh`](check-course.sh), el script que
> comprueba que el curso no se ha roto por dentro.
> **Para quién:** para ti dentro de seis meses, cuando vuelvas a tocar el curso y no te
> acuerdes de por qué existe cada comprobación.
> **Estado:** versionado junto con el script desde el commit inicial del curso. Desde el
> 05/10/2026 el script convive con `verificar-corpus.py`, que hace las validaciones base de los
> lineamientos del repositorio (enlaces, anclas, callouts, diagramas); este documento explica
> solo `check-course.sh`. Cómo se reparten está en la guía §16.3.

Este documento no asume que sepas Bash, ni Python, ni qué es un *exit code*. Sigue la misma
regla que el curso: **cada decisión responde a "¿por qué estamos haciendo esto?"**.

---

## 1. 🧭 El problema antes de la herramienta

Un curso de 202.000 palabras repartidas en 56 documentos que se citan entre sí **tiene una
propiedad incómoda**: casi cualquier cambio puede romper algo en otro sitio, en silencio.

Ejemplos reales, todos ocurridos mientras se escribía este curso:

- Renombrar el índice de `000-programa-del-curso.md` a `0-programa-del-curso.md` dejó
  **trece documentos** apuntando a un archivo que ya no existía.
- Recalibrar los ejercicios cambió su numeración, y con ella **393 frases** del tipo
  *"como viste en el ejercicio 15"* pasaron a apuntar al ejercicio equivocado.
- Un enlazador automático creó **25 autoenlaces**: documentos que se enlazaban a sí mismos, y
  uno de ellos se comió parte de un título.

Ninguno de los tres produce un error visible. El Markdown sigue siendo válido, el documento
sigue abriéndose, y el fallo solo aparece cuando alguien hace clic. **Eso es exactamente lo
que un script de integridad existe para cazar.**

> 🧠 **Modelo mental.** Esto no es un corrector de estilo ni un linter de Markdown. Es una
> **prueba de regresión para prosa**: comprueba invariantes que tú decidiste que el curso debe
> cumplir siempre, y grita cuando dejan de cumplirse.

---

## 2. ▶️ Cómo se usa

El script vive en `prompts/` y se sitúa solo, así que da igual desde dónde lo llames:

```bash
# desde la raíz del curso
./prompts/check-course.sh

# desde cualquier otro sitio, también funciona
/ruta/completa/docker-container-legacy/prompts/check-course.sh
```

Sale una línea por comprobación:

```text
🔍 Verificando el curso en /…/docker-container-legacy

  ✅ enlaces .md resuelven
  ✅ sin autoenlaces
  ✅ ejercicios numerados 1..N
  …
✅ 13 comprobaciones, ninguna falla.
```

Y cuando algo falla, el script **te dice qué archivo y qué línea**, no solo que hay un
problema:

```text
  ❌ enlaces .md resuelven
       enlace roto: 12-capas-cache-y-contexto.md → 13-overlayfs.md
```

**El modo silencioso** solo imprime lo que falla, que es lo que quieres si lo cuelgas de algo
automático:

```bash
./prompts/check-course.sh -q
```

---

## 3. 🔢 Los códigos de salida, y por qué importan

Todo programa de Unix devuelve un número al terminar. Cero significa "todo bien" y cualquier
otra cosa significa "hubo un problema". Nadie lo ve, pero **todo lo automático lo usa para
decidir**.

```bash
./prompts/check-course.sh
echo $?        # 0 si todo pasó, 1 si algo falló
```

Es lo mismo que [F16](../16-pid1-senales-y-ciclo-de-vida.md) §9.1 explica sobre los códigos de
salida de un contenedor, y lo que hace que estas dos cosas funcionen:

```bash
# encadenar: solo commitea si el curso está sano
./prompts/check-course.sh -q && git commit -m "…"

# un hook de pre-commit: aborta el commit si algo falla
echo './prompts/check-course.sh -q' >> .git/hooks/pre-commit
```

> 💡 **Si algún día lo quieres en CI**, ya está listo: cualquier runner interpreta el `1` como
> "falla el job". No hace falta tocar nada del script.

---

## 4. 🧩 Cómo está construido, por dentro

El script es Bash **por fuera** y Python **por dentro**, y esa mezcla es deliberada.

Bash es cómodo para lo de fuera —ordenar comprobaciones, contar, imprimir con colores, devolver
un código de salida— y es horrible para lo de dentro, que es leer 56 archivos y buscar patrones
en su texto. Python hace eso en tres líneas.

La pieza que los une es esta función:

```bash
comprobar() {
    local nombre="$1"; shift
    local salida
    salida="$(python3 - "$@" 2>&1)"
    if [[ -z "$salida" ]]; then
        ok "$nombre"
    else
        falla "$nombre"
        printf '%s\n' "$salida" | sed 's/^/       /'
    fi
}
```

**Léela así:** ejecuta un trozo de Python; si el Python **no imprimió nada**, la comprobación
pasa; si imprimió algo, eso que imprimió **es** la lista de problemas y se muestra indentada.

Esa es toda la convención, y tiene una consecuencia muy práctica: **para añadir una
comprobación nueva no hay que tocar la maquinaria**. Escribes un bloque de Python que imprime
una línea por cada problema que encuentre, y ya.

```bash
comprobar "mi comprobación nueva" <<'PY'
# si esto no imprime nada, la comprobación pasa
print('algo va mal en tal sitio')
PY
```

> 📝 **Nota sobre el `<<'PY'`.** Eso es un *heredoc*: una forma de meter un texto largo dentro
> de un comando sin tener que escapar nada. Las comillas de `'PY'` son importantes — sin ellas,
> Bash intentaría interpretar los `$` y los backticks del código Python y lo destrozaría. Es el
> mismo tipo de trampa de *quoting* que [a08](../a08-windows-y-powershell.md) trata para
> PowerShell.

---

## 5. 🔍 Las trece comprobaciones, una por una

Cada una existe porque **algo se rompió de verdad** durante la escritura del curso. No hay
ninguna hipotética.

### 5.1 Enlaces `.md` resuelven

Recorre todos los documentos, extrae cada enlace que apunte a un `.md` y comprueba que el
archivo existe.

**Por qué existe:** es la comprobación que más veces ha saltado. Renombrar un archivo, mover un
apéndice o equivocarse en una ruta relativa produce un enlace roto que nada más detecta.
Hoy verifica unos **1.700 enlaces**.

**Cuándo falla de mentira:** nunca. Si esta comprobación falla, hay un enlace roto de verdad.

### 5.2 Sin autoenlaces

Detecta documentos que se enlazan a sí mismos, como una fase que dice
`[F14](14-abi-libc-y-prebuilds.md)` **dentro de** `14-abi-libc-y-prebuilds.md`.

**Por qué existe:** un enlazador automático los creó a montones. No rompen nada, pero son ruido
—hacer clic y quedarte donde estabas— y uno llegó a colarse dentro de un título.

### 5.3 Ejercicios numerados 1..N

Comprueba que dentro de cada documento los ejercicios van `1, 2, 3…` sin huecos ni repeticiones.

**Por qué existe:** al recalibrar la dificultad hubo que reordenar y renumerar ejercicios, y un
regex mal escrito llegó a renumerar los encabezados **dos veces**, dejando cosas como
`Ejercicio 16, 17, 22, 23, 28`. Se detectó con esta comprobación.

### 5.4 El conteo del título coincide con los ejercicios reales

Cada fase abre su sección con `## 🧪 Ejercicios de la Fase 13 (28)`. Esto comprueba que ese
`(28)` es verdad.

**Por qué existe:** el número del título se escribe a mano y se olvida al añadir un ejercicio.
Es la clase de error que nadie nota y que hace quedar mal al curso entero.

### 5.5 Las referencias `FNN §x.y` resuelven

El curso se cita a sí mismo constantemente —*"como explica F14 §5.1"*—. Esto comprueba que esa
sección existe en esa fase.

**Por qué existe:** al añadir cinco secciones nuevas a [F34](../34-proyecto-final.md) hubo que
renumerar el documento entero, y una auto-referencia se quedó apuntando a la numeración vieja.

**Ojo con esta**, porque es la que más se equivoca: usa una ventana de 60 caracteres para
decidir si un `§` pertenece a una fase citada antes o al documento actual. Si una referencia
cruzada queda **partida por un salto de línea**, la comprobación puede dar un falso positivo.
Cuando esta falle, mira el contexto completo antes de "arreglar" nada.

### 5.6 Ningún apéndice huérfano

Cada uno de los 16 apéndices tiene que estar enlazado desde al menos una fase.

**Por qué existe:** durante mucho tiempo **solo uno** de los dieciséis estaba enlazado. Los
otros quince se mencionaban por su código —`a05`, `a07`— sin ruta, así que para abrirlos había
que volver al índice y buscarlos a mano. Un apéndice al que no se llega es un apéndice que no
existe.

### 5.7 Banda de 20–35 ejercicios por fase práctica

La guía de estilo §9 fija ese rango. Esto lo hace cumplir, saltándose las cuatro fases exentas
—[F00](../00-problema-y-contrato.md), [F01](../01-decisiones-debian-zonas-node.md),
[F34](../34-proyecto-final.md) y [F35](../35-referencias.md)—.

### 5.8 Ninguna fase repite el reparto de la anterior

Comprueba que dos fases seguidas no tengan exactamente los mismos 🟢🟡🟠🔴.

**Por qué existe:** es la comprobación más sutil y la más valiosa. Durante mucho tiempo **las 32
fases prácticas tenían exactamente 7🟢/7🟡/4🟠/2🔴**, sin una sola excepción. Eso no es una
calibración: es una plantilla copiada. Si dos fases seguidas coinciden al dedillo, lo más
probable es que la segunda no se haya graduado ejercicio por ejercicio.

> ⚠️ **Esta comprobación puede dar un falso positivo legítimo.** Dos fases pueden merecer el
> mismo reparto por casualidad. Si estás seguro de que lo calibraste, ignórala — pero
> pregúntatelo dos veces antes.

### 5.9 `⭐` solo en F35

En este curso `⭐` significa **una sola cosa**: la valoración bibliográfica de 1 a 5 estrellas
de [F35](../35-referencias.md). No gradúa ejercicios y ya no marca "pieza central".

**Por qué existe:** el símbolo llegó a tener tres significados a la vez. Ahora tiene uno, y esto
lo vigila.

### 5.10 Sin andamiaje

Busca menciones a los documentos de trabajo de la reestructuración —`_source/`,
`mapa-de-corte.md`, `mejoras.md`, `ajuste_estructura.md`— dentro de documentos que sí publica el
curso. `prompts/` queda fuera: la guía y la propuesta los nombran a propósito, para contar cómo
se quitaron.

**Por qué existe:** el andamiaje de una migración tiende a filtrarse al material del estudiante.
Ya pasó una vez, con el glosario citando un directorio que iba a desaparecer.

### 5.11 Dockerfiles sin `:latest` ni rangos

**Por qué existe:** es una regla explícita del curso —*"todo pinneado"*— y es de las que el
curso predica en cada fase. Un `latest` en el laboratorio destruiría el argumento entero.

### 5.12 Punteros a `src/` coherentes

Dos comprobaciones en una: que cada `**Código de esta fase:** src/X/` apunte a un directorio que
existe, y que cada directorio de `src/` tenga su documento correspondiente.

**Por qué existe:** el código y la prosa se editan por separado y se desincronizan solos.

### 5.13 El índice y el README cuadran con el árbol

Cuenta las fases y los apéndices que hay **en disco** y comprueba que el `README.md` y el
`0-programa-del-curso.md` digan ese mismo número.

**Por qué existe:** los números de portada envejecen fatal. Este curso llegó a decir "845
ejercicios" cuando ya tenía 941.

---

## 6. 🧯 Qué hacer cuando algo falla

**Regla de oro, la misma que [F30](../30-troubleshooting-metodo-y-herramientas.md):** el script
te dice **el síntoma**, no la causa. No corrijas a ciegas.

1. **Lee el archivo y la línea que te da.** Están ahí para que vayas directo.
2. **Pregúntate si el fallo es real o es la comprobación la que se equivoca.** Las dos
   candidatas a falso positivo están marcadas arriba: §5.5 (referencias partidas por salto de
   línea) y §5.8 (repartos iguales por casualidad).
3. **Arregla la causa, no el síntoma.** Si un enlace está roto porque renombraste un archivo,
   el arreglo es actualizar las referencias — no borrar el enlace.
4. **Vuelve a correrlo.** Debe pasar entero.

> 🩺 **Y una advertencia sobre lo que este script NO comprueba.** No mira el tono, ni la
> ortografía, ni si un ejercicio tiene sentido, ni si una afirmación técnica es cierta. Eso lo
> decide una persona. El script solo garantiza que **la estructura no está rota**, que es una
> condición necesaria y muy lejos de ser suficiente.

---

## 7. 🔮 Qué le falta

Cosas que hoy se comprueban a mano y que valdría la pena automatizar, si alguna vez duele lo
bastante:

- **La sincronía byte a byte entre los bloques `📄` de las fases y los archivos de `src/`.**
  Hoy solo se comprueba que el directorio exista, no que el contenido coincida.
- **El tercio de ejercicios de diagnóstico** que pide la guía §9. Se intentó con palabras clave
  y **subcuenta sistemáticamente**: hay ejercicios cuyo carácter diagnóstico está en el montaje
  y no en el vocabulario. Una heurística mala es peor que ninguna, así que se dejó fuera.
- **Que cada fase declare su fecha de revisión** cuando cite documentación externa volátil.
- **Las anclas de los enlaces y la forma de los diagramas.** Ya no le faltan al curso: las
  revisa `verificar-corpus.py` (guía §16.3), y por eso este script no las duplica.
- **Enlaces externos vivos.** Requiere red y da falsos positivos por *rate limiting*; es más
  ruido que señal para correrlo en cada commit.

---

## 8. 🏁 Resultado

```text
UNA ORDEN          ./prompts/check-course.sh

TE DICE            si los enlaces, la numeración, las referencias cruzadas,
                   los punteros a src/ y las cifras de portada siguen sanos

DEVUELVE           0 si todo pasa · 1 si algo falla, para encadenarlo

NO TE DICE         si el curso está bien escrito. Eso sigue siendo tuyo
```

> **La señal de que quedó bien:** *"puedo renombrar un archivo, reordenar veinte ejercicios y
> mover una sección de sitio, y saber en tres segundos si rompí algo — en vez de enterarme
> dentro de dos meses porque alguien hizo clic."*
