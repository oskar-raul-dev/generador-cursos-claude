# 🏷️ Convención de git y tags
## Python para desarrolladores Java senior

Dos páginas, una sola vez. Las dieciocho fases enlazan aquí y ninguna vuelve a explicar nada de
esto.

> **Cuándo se lee:** antes de la [Fase 00](00-instalacion-ambiente-editores-y-ecosistema.md), y cada
> vez que el bloque 🏷️ de cierre de una fase te mande aquí.
> **Vigencia:** 2026-10-07.

> 🔑 **La frase para memorizar:** un tag es un puntero a un commit. No ocupa espacio, no agrega
> overhead y se borra con `git tag -d`. La pregunta no es "¿vale la pena etiquetar esto?", es "¿por
> qué no?".

---

## 📌 Por qué hay un repositorio

No por disciplina. Por tres usos concretos que el curso hace todo el tiempo y que sin historia
no existen.

**Volver a un punto.** El CLI de Patricia nace en la Fase 01 y llega vivo hasta la 17,
cambiando de forma por el camino. Cuando la Fase 07 lo convierte en paquete, vas a querer mirar
cómo se veía seis fases atrás — y no de memoria.

**Leer la factura de una deuda.** El curso deja atajos marcados 💸 y los cobra en una fase
concreta. La factura de cada uno es literalmente un `git diff` entre dos tags, y las fases te
la piden por su nombre.

**Comparar tus propios números.** Cada miniproyecto produce una medición. El número vive en el
mensaje de su tag, así que el de la Fase 15 se compara con el de la Fase 02 sin buscar en
ningún cuaderno.

---

## 🗂️ El repositorio

Se crea en la Fase 00, vacío, y es tuyo. Un solo repositorio para todo el curso: los cuatro
proyectos conviven ahí, cada uno en su directorio, y las fases te dicen cuál tocas.

El `.gitignore` es la primera lección de git del curso, y tiene una línea que a alguien que
viene de Java no se le ocurre sola:

```gitignore
# El entorno virtual NUNCA se versiona: es una carpeta con rutas absolutas
# de tu máquina adentro, y en otra máquina no sirve para nada.
.venv/

__pycache__/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/
dist/
build/
*.egg-info/

# Datos de Áurea: entran generados, no versionados (el generador sí se versiona).
data/*.csv
data/*.sqlite3
.env
```

Y cuando llegues a los complementos `ia` y `ds`, esas tres líneas se quedan cortas: los tracks
generan corpus, conjuntos de datos, figuras, cuadernos ejecutados y **artefactos de modelo**.
Todo eso se regenera con su semilla fija, así que tampoco se versiona:

```gitignore
# Lo que generan los scripts de los complementos.
data/
modelos/
salida/
cuadernos/
*.parquet
*.png
*.html

# Artefactos de modelo. Y hay una segunda razón para esta línea, además del peso:
# un `.pkl` es código ejecutable, y un binario ejecutable que entra al repositorio
# sin que nadie lo revise es exactamente el problema que estudia `ds09`.
*.pkl
*.onnx
```

> ⚠️ **El `.venv/` no se versiona, y la razón importa más que la regla.** Un entorno virtual no
> es una carpeta de dependencias como `target/` con sus JAR: adentro tiene rutas absolutas de
> tu máquina y binarios de tu plataforma. Copiado a otra máquina no falla con un error claro —
> falla raro. Lo que se versiona es la **declaración** del entorno, que en el Bloque A es una
> línea en el README diciendo qué versión de Python hace falta, y desde la Fase 07 es
> `pyproject.toml` con su lockfile.

> 📝 **Sobre el Bloque A.** Hasta la Fase 07 no hay `pyproject.toml` ni paquete: el repositorio
> de esas siete fases es un puñado de archivos `.py` sueltos y algunos datos de ejemplo. Está
> bien, es el registro. Si a mitad del Bloque A sientes la necesidad de "organizarlo bien", esa
> sensación es exactamente el tema de la Fase 07 — anótala y espera.

---

## ✍️ Commits

Prefijo siempre, y el prefijo dice de qué parte de la fase salió el cambio:

```text
fase 03: dataclass para el plan integral, sin jerarquía
fase 03 ej12: reescribe el validador con Protocol
fase 03 mini: motor de comisiones, primera versión que corre
```

Tres prefijos y nada más: `fase NN:` para el trabajo del cuerpo de la fase, `fase NN ejMM:`
para un ejercicio, `fase NN mini:` para el miniproyecto. El número de la fase va con dos
dígitos y el del ejercicio con dos también, para que `git log --oneline | sort` no mienta.

**Un commit por unidad de trabajo terminada**, no por párrafo ni por archivo guardado. El
criterio práctico: si no puedes describir el commit sin la palabra "y", probablemente eran dos.

---

## 🏷️ Tags

Dos familias por track, todas **anotadas** (`-a`), porque el mensaje es donde vive la
información que después se recupera.

### `fase-NN` — cierra la fase

Se crea cuando el checklist de la sección 2 de la fase está en verde, el miniproyecto corre y
`git status` está limpio. El mensaje lleva el checklist, una línea por ítem:

```bash
git tag -a fase-06 -m "F6 cerrada:
- el CLI lee CSV con el módulo csv y sobrevive a comas y comillas dentro de celda
- el export latin-1 de Odontovía y el BOM de Excel se leen sin tocarlos a mano
- el histórico vive en sqlite3 y el reporte del mes sale de una consulta
- deuda de la Fase 01 pagada: git diff fase-01 fase-06 lo muestra"
```

### `mini-NN` — cierra el miniproyecto

Y este tiene una regla propia que vale la pena respetar, porque el curso cuenta con ella:

> 🧭 **En el mensaje del tag `mini-NN` va el número que arrojó la medición del miniproyecto.**
> Es el único lugar donde ese número queda guardado, y es de donde lo recuperas después.

```bash
git tag -a mini-06 -m "Mini F6: consolidador de las diez sedes · 8.400 filas en 2.1 s, pico 31 MB"
```

Tres fases después, cuando la 15 te pida comparar el cierre nocturno contra lo que hacía tu
herramienta a mano, ese número ya está escrito y no tienes que volver a medir el pasado.

### Y los complementos y la carta: `ia-`, `ds-` y `op-`

Después de la Fase 17, el curso sigue con dos tracks complementarios —`ia01`–`ia08` y
`ds01`–`ds09`— que construyen los cuatro proyectos de IA y de datos de Áurea. **Cierran igual,
con su propio espacio de nombres:**

| | Camino base | Track `ia` | Track `ds` | Carta opcional (`opNNN-<tt>NN-…`) |
|---|---|---|---|---|
| Tag de sección | `fase-NN` | `ia-fase-NN` | `ds-fase-NN` | `op-<tt>-fase-NN` |
| Tag de miniproyecto | `mini-NN` | `ia-mini-NN` | `ds-mini-NN` | `op-<tt>-mini-NN` |
| Prefijo de commit | `fase NN: …` | `ia NN: …` | `ds NN: …` | `op <tt>NN: …` |
| Ejercicio | `fase NN ejMM: …` | `ia NN ejMM: …` | `ds NN ejMM: …` | `op <tt>NN ejMM: …` |

Las secciones de la carta son opcionales y se toman sueltas, así que cada una se etiqueta solo si
la hiciste: `git tag -a op-lg-fase-01 -m "op lg01 cerrada: …"`. El curso no tiene apéndices, y por
eso no hay tags de apéndice.

```bash
git tag -a ds-fase-07 -m "ds07 cerrada: <el checklist, una línea por ítem>"
git tag -a ds-mini-07 -m "Mini ds07: lista de Yuli · precisión 0.53 a cupo 20"
```

> 🧭 **Varios espacios de nombres y no uno, por una razón que se cobra el día que los uses:**
> `git tag -l 'fase-*'` devuelve exactamente el camino base, `'ia-*'` y `'ds-*'` cada
> complemento, y `'op-*'` lo que hiciste de la carta. Con un solo prefijo, esa consulta mezclaría treinta y cinco tags y dejaría de
> servir para orientarse.

La regla del `mini-NN` vale igual en los tres: **en el mensaje va el número que arrojó la
medición**, y es el único sitio donde queda guardado.

Y cuando un track termina, un tag más sin número de sección:

```bash
git tag -a ia-track -m "Track ia completo: 8 secciones"
git tag -a ds-track -m "Track ds completo: 9 secciones, 9 mediciones ejecutadas de 10"
```

### Ramas

Con prefijo, para que no choquen con los tags ni entre ellas: `wip/` para trabajo a medias que
no quieres perder, `spike/` para probar algo que probablemente se borre. El trabajo normal del
curso va en la rama principal — eres una sola persona y un flujo de ramas aquí es ceremonia sin
pago.

> ⚠️ **Volver a un tag te deja en `detached HEAD`.** `git checkout fase-06` te pone a mirar ese
> estado sin estar en ninguna rama; por eso el comando de abajo crea una (`git switch -c`). Y por
> eso las ramas llevan prefijo: una rama y un tag que se llaman igual vuelven ambiguo cualquier
> `git checkout`.

No hace falta remoto. Si lo tienes, recuerda que **los tags no viajan solos**: `git push --tags`.

---

## 🔧 Los tres usos, con su comando

**Recuperar el estado de una fase anterior**, sin perder lo que llevas:

```bash
git switch -c revision-f01 fase-01   # mira la 01 en una rama aparte
git switch -                          # y vuelve a donde estabas
```

**Leer la factura de una deuda 💸**, que es la forma en que el curso te muestra qué costó el
atajo:

```bash
git diff fase-01 fase-06 -- aur_cli.py
```

**Recuperar el número de un miniproyecto** para compararlo con el de hoy:

```bash
git show mini-02 | head -5
git tag -n9 -l 'mini-*'   # todos los números del curso, de una
```

Ese último comando, corrido al terminar la Fase 17, es tu tabla de mediciones personal — la que
vas a contrastar contra `BENCHMARKS.md`.

---

## ✅ El cierre de fase, en cuatro líneas

```bash
ruff check . && ruff format --check .   # desde la Fase 00
pytest                                   # desde la Fase 08
git status                               # limpio, o no cierras
git tag -a fase-NN -m "..."
```

Antes del tag, el checklist de la sección 2 de la fase en verde y el miniproyecto corriendo, con su
`mini-NN` y la medición en el mensaje. Si algo de eso falla, la fase no está cerrada. El tag no es un trofeo: es la afirmación de que
ese punto de la historia compila, corre y se puede volver a él.
