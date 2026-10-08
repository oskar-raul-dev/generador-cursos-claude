# 🏷️ Convención de git: commits y tags de progreso
## {{Nombre del curso}}

> ✏️ **Plantilla:** se copia como **`00-convencion-de-git-y-tags.md` en la raíz del curso** (no en
> `prompts/`): es un documento publicado, escrito para el lector, y viaja al repositorio público. Va en
> todo curso donde el lector escribe o versiona algo (`D-09` distinto de "sin código"). Se escribe en
> la etapa E4 (tanda P7), **después del [contrato de nombres](contrato-de-nombres.md)** —del que copia
> los nombres de §7 sin cambiarlos— y **antes de las [plantillas de capítulo](plantillas-de-capitulo.md)**,
> cuyo bloque 🏷️ de cierre enlaza aquí. El modelo lleno es el de
> `cursos-legacy/angular-16-legacy-for-backend-devs/00-convencion-de-git-y-tags.md`. Las secciones
> *(opcionales)* se borran enteras si el curso no las usa; nunca se dejan vacías.

Cómo versionas el código que escribes mientras haces el curso. Es corta a propósito: no es un
proyecto de empresa, no hay releases ni equipo, y una estrategia de ramas elaborada sobraría. Son
tres cosas —{{un repo por curso | un repo por track}}, commits con un prefijo y un tag por fase
cerrada— más los usos de los tags que rinden mucho por lo poco que cuestan: {{los ejercicios, los
incidentes y las deudas 💸}}.

> **Cuándo se lee:** antes de la [Fase 0]({{00-slug.md}}), y cada vez que un bloque 🏷️ de cierre te
> mande aquí.
> **Vigencia:** {{AAAA-MM-DD}}.

> 🔑 **La frase para memorizar:** un tag es un puntero a un commit. No ocupa espacio, no agrega
> overhead y se borra con `git tag -d`. La pregunta no es "¿vale la pena etiquetar esto?", es "¿por
> qué no?".

---

## 📦 1. {{Un repo por curso | Un repo por track}}

**El curso no se hace dentro del repositorio donde se publica.** Antes de la Fase 0 copias la carpeta
del curso a un repositorio tuyo, y es ahí donde trabajas: tu `git init`, tus commits y tus tags. El
repositorio del curso queda intacto, como referencia contra la que te comparas.

{{Al empezar la Fase 0 haces `git init` en `{{nombre-del-proyecto}}`, el directorio que crea
{{la herramienta de scaffolding}}.}} {{Si hay track o curso hermano: al empezar el otro, otro
`git init` en `{{nombre-del-otro-proyecto}}`. **Dos repos, no uno**, porque {{la medición que lo
exige: p. ej. "el `git diff` del frontend tiene exactamente una línea" al cambiar el mock por el
backend real; en un monorepo ese diff te devuelve además todo el backend}}.}}

**Lo que queda fuera desde el primer commit**, porque después molesta: {{`node_modules/`, `dist/`,
`target/`, `.venv/`}}{{, `.env` y los datos del contenedor}}. Un secreto que entra al repo ya no sale,
aunque lo borres en el commit siguiente.

No hace falta remoto. Si lo tienes, recuerda que **los tags no viajan solos**: `git push --tags`.

> ✏️ **Plantilla:** si `D-09` es "un solo proyecto en `src/` con tags", deja el párrafo que sigue; si
> es "una carpeta por fase", bórralo.

**El `src/` del curso usa los mismos nombres.** En el repositorio del curso, el commit que cierra cada
fase lleva el mismo tag que tú creas en tu copia. Así, "compara tu proyecto con el del curso" es un
`git diff` entre dos tags que se llaman igual, y no una búsqueda en el log.

---

## 💬 2. Los mensajes de commit

Un prefijo, y ya. El prefijo es el código de la fase: {{`f04` en las numeradas}}{{, `q3` en las de
ruta o track}}{{, `02/f04` con bloques}}.

```bash
git commit -m "{{f04}}: {{lo que hizo el commit}}"
git commit -m "{{f04 ej17}}: {{lo que resolvió el ejercicio}}"
```

Los ejercicios llevan además su número (`ej17`), y así queda claro qué es contenido de la fase y qué
es práctica tuya. Eso te deja dos búsquedas útiles:

```bash
git log --oneline --grep '^{{f04}}'        # todo lo de la Fase 4
git log --oneline --grep '^{{f04}} ej'     # solo los ejercicios de la Fase 4
```

Commitea seguido y con mensajes cortos. Nadie va a revisar tu historia, pero tú vas a volver a ella
cuando un ejercicio te deje el proyecto irreconocible.

### Los apéndices

Lo que sale de leer un apéndice también se commitea, con su propio prefijo: `{{a04}}`, igual que el
nombre del archivo.

**Los apéndices no cierran con tag**, y no es un olvido: un tag marca un cambio en el repositorio, y
un apéndice explica lo que ya está ahí. Por eso ningún apéndice trae el bloque 🏷️ de cierre.

> 💡 **Si un apéndice te deja archivos versionados** ({{un `compose.yaml`, los scripts del build}}) y
> quieres poder volver a ese punto, `apendice-{{a04}}` existe como opción tuya. Ningún apéndice te lo
> va a pedir: es un atajo disponible, no un paso del curso.

---

## 🏷️ 3. Un tag por fase cerrada

**Cuando cierras una fase —con su checklist de "{{✅ Qué queda listo al terminar}}" en verde— haces
commit y creas el tag.** Uno por fase, y no hace falta más.

El tag se llama **`fase-` + el mismo slug del archivo `.md`**, así no hay que recordar nada: el
archivo que estás leyendo te dice cómo se llama su tag.

```text
{{04-dashboard-tickets.md}}   →   {{fase-04-dashboard-tickets}}
{{02-datos/03-indices.md}}    →   {{fase-02-03-indices}}          con bloques: el bloque va en el tag
{{be03-slug.md}}              →   {{be-fase-03-slug}}             track opcional: su propio espacio
```

Anotado (`git tag -a`), porque así guarda fecha y mensaje —y la fecha es lo que después te da la línea
de tiempo del curso—. El mensaje no se inventa: es el checklist de la fase, con lo que efectivamente
quedó funcionando.

```bash
git tag -a {{fase-04-dashboard-tickets}} -m "{{F4 cerrada: lo que quedó funcionando, ítem por ítem.
Lo que todavía no, y en qué fase llega.}}"
```

Si al escribir el mensaje descubres que un ítem del checklist no está, no está la fase. El tag es
honesto o no sirve para nada.

Los tags de fase van de `{{fase-00-slug}}` a `{{fase-NN-slug}}`{{, más los del track o la ruta}}.
`git tag -l 'fase-*'` es el índice limpio de tu progreso; por eso todo lo demás vive en otros
espacios de nombres.

> 💡 **Las fases sin código también se etiquetan.** {{La fase que produce una autopsia o un documento
> de decisión.}} Si la fase cambió algo en el repo, hay algo que marcar.

### Puntos de retorno *(opcional)*

{{Las fases que preparan algo arriesgado —una migración, un cambio de versión— te piden además un tag
**antes** de tocar nada, que no es un cierre sino el punto al que vuelves cuando la cosa se tuerce:
`git tag pre-{{algo}}`, en el mismo commit que el tag de la fase. Son dos nombres para el mismo punto:
uno dice "terminé la fase", el otro "aquí es donde vuelvo".}}

> ⚠️ **Volver a un tag te deja en `detached HEAD`.** Es normal: `git checkout {{fase-05-slug}}` te
> pone a mirar ese estado sin estar en ninguna rama. Si vas a escribir desde ahí, crea una rama
> primero (`git switch -c intento-2`); para volver, `git switch {{main}}`. Y si trabajas cada fase en
> su rama, ponle prefijo (`wip/fase-05`): una rama y un tag que se llaman igual vuelven ambiguo
> cualquier `git checkout`.

---

## 🧪 4. Tags de ejercicio *(opcional, pero baratos)*

Los tags de fase son obligatorios; los de ejercicio son tuyos. Van en un espacio de nombres aparte
para que `git tag -l 'fase-*'` siga siendo un índice limpio:

```bash
git tag ej/{{f04}}/17      # Fase 4, ejercicio 17
git tag ej/{{a01}}/3       # apéndice A01, ejercicio 3
```

Dos casos donde vale la pena de verdad. Los **ejercicios de diagnóstico**, que piden dos tags:

```bash
git tag ej/{{f08}}/25-roto     # el bug reproducido, antes de tocar nada
git tag ej/{{f08}}/25-fix      # el fix aplicado y verificado
git diff ej/{{f08}}/25-roto ej/{{f08}}/25-fix
```

Ese `diff` es la corrección aislada del ruido, y sigue siendo legible dentro de seis meses. Y los
**ejercicios de medición**, donde el número va en el mensaje del tag y queda pegado al commit que lo
produjo:

```bash
git tag -a ej/{{f07}}/22 -m "{{antes: N / X ms. Después: M / Y ms. Dataset: …}}"
```

Después, `git tag -n99 -l 'ej/{{f07}}/*'` te devuelve tu cuaderno de mediciones sin abrir un archivo.

> ⚠️ **Un cuidado, uno solo.** No crees nunca un tag llamado literalmente `ej/{{f04}}`. Git guarda los
> refs como archivos: si existe `refs/tags/ej/{{f04}}`, no puede existir además el directorio
> `refs/tags/ej/{{f04}}/`, y `git tag ej/{{f04}}/17` falla con un error confuso. Los niveles
> intermedios del espacio de nombres se quedan vacíos, siempre.

---

## 🚑 5. Incidentes: aquí el tag sí es contenido *(opcional)*

> ✏️ **Plantilla:** obligatoria si el curso tiene cuaderno de incidentes. El formato de cada
> incidente vive en el formato del cuaderno; aquí solo su traducción a git.

Los incidentes del [cuaderno]({{cuaderno-incidentes.md}}) se resuelven con la estructura de
post-mortem de {{N}} puntos: {{síntoma, repro, evidencia, causa raíz, corrección, prueba de regresión,
prevención y análisis sin culpables}}. Esa estructura tiene una traducción exacta a git, y por eso
aquí el par de tags deja de ser opcional:

```bash
# Puntos 1–3: el síntoma reproducido y la prueba de regresión EN ROJO
git tag -a inc/{{f13}}/{{slug-corto}}-roto -m "Síntoma: {{…}}. Repro: {{…}}. Evidencia: {{…}}."

# Puntos 4–6: la causa raíz, el fix y la misma prueba EN VERDE
git tag -a inc/{{f13}}/{{slug-corto}}-fix -m "Causa raíz: {{…}}. Fix: {{…}}. Regresión: {{…}}."
```

El espacio de nombres es `inc/<fase>/<slug-corto>` y los dos sufijos son siempre `-roto` y `-fix`. El
`git diff` entre los dos **es** el punto de la corrección, aislado del ruido, y los dos mensajes son
los puntos del síntoma a la regresión, escritos donde no se pierden. `git tag -n99 -l 'inc/*'` te
devuelve tu bitácora entera.

El reparto es claro: **el cuaderno es el enunciado y tu investigación escrita; los tags son la misma
investigación, ejecutable.** Un incidente que termina sin commit (un diagnóstico, una declaración, una
decisión de equipo) no lleva par: lleva su documento.

{{Si hay track con cuaderno propio: sus incidentes usan `inc/be{{NN}}/<slug>`, en el repo del track.}}

---

## 🕵️ 6. Lo que se commitea al recorrer una pieza forense *(opcional)*

Poco. Una pieza forense **no produce código del proyecto**: te enseña a encontrar dónde está el
problema. Lo que salga de recorrerla —una nota, un script de diagnóstico— se commitea con el prefijo
de su fase. Los dos casos que sí dejan marca ya tienen espacio de nombres y **no se inventa uno
nuevo**: el par `inc/…` si corresponde a un incidente, y el par `ej/…` si sale de un ejercicio de
"rompe a propósito". No existe `forense/`: un tag marca un cambio, y mirar no cambia nada.

---

## 💸 7. La deuda que sí se paga *(opcional)*

> ✏️ **Plantilla:** si el curso declara deuda técnica a propósito (💸) y dice dónde se salda.

El curso declara deuda técnica a propósito, la marca 💸 y dice en qué fase se salda. Eso convierte a
los tags en los dos extremos de una comparación, y hay dos casos.

**Cuando la deuda nace y muere en el mismo repo**, el diff entre los dos tags de fase, acotado a lo que
cambió, **es** el material del repaso:

```bash
git diff {{fase-02-slug}} {{fase-03-slug}} -- {{src/store}}
```

No es una métrica: es la respuesta a *"¿cuánto costó de verdad arreglar esto?"*, que es la pregunta
que te van a hacer la próxima vez que propongas pagar una deuda en un sistema real.

**Cuando la deuda cruza repos** (`git diff` no los cruza), se dejan escritas las dos mitades:

```bash
# Repo que declara, al cerrar la fase:
git tag -a deuda/{{slug}}-declarada -m "{{FNN: qué se debe. Se paga en …, Fase …}}"
# Repo que paga, en el commit que la salda:
git tag -a deuda/{{slug}}-pagada -m "{{FNN: qué se cerró. Cierra deuda/{{slug}}-declarada de …}}"
```

El que declara dice qué se debe y dónde se paga; el que paga, qué cerró y de dónde venía.
`git tag -n99 -l 'deuda/*'` te devuelve en cada repo su mitad del libro mayor.

---

## 🧹 8. El estado que se ensucia *(opcional)*

> ✏️ **Plantilla:** si el curso tiene datos versionados que los ejercicios modifican (un mock que
> escribe, una base de pruebas, un archivo semilla).

{{`db.json`}} se ensucia con los ejercicios, y tienes dos formas de volver que **no son la misma**:

```bash
git checkout -- {{db.json}}     # el archivo como lo commiteaste, con los escenarios que tenga dentro
{{npm run mock:reset}}          # lo regenera desde la semilla y se los lleva por delante
```

De ahí el hábito que más te va a servir: cuando un ejercicio te pida un dato particular, cárgalo,
**commitéalo como escenario** (`"{{f05 ej22}}: escenario de …"`) y etiquétalo si vas a volver.
{{Si el estado vive en una base y no en un archivo: se vuelve con `{{npm run seed}}` o levantando el
contenedor de cero.}}

---

## 📈 9. Los comandos que hacen que esto sirva

```bash
git tag -l 'fase-*'                                    # ¿dónde estoy?
git for-each-ref --sort=creatordate \
  --format='%(creatordate:short)  %(refname:short)' 'refs/tags/fase-*'   # cuándo cerré cada fase
git diff {{fase-03-slug}}..{{fase-04-slug}} --stat     # qué costó una fase
git checkout {{fase-05-slug}}                          # volver a un estado sano
git checkout {{fase-05-slug}} -- {{ruta/al/archivo}}   # recuperar un archivo sin moverte
{{git switch -c incidente/07 fase-04-slug}}            # arrancar un incidente desde su fase
git tag -n99 -l 'ej/{{f07}}/*'                         # los ejercicios de una fase
{{git tag -n99 -l 'inc/*'}}                            # el cuaderno de incidentes
{{git tag -n99 -l 'deuda/*'}}                          # el libro de deudas
```

---

## ✅ 10. Checklist de cierre de fase

- [ ] El checklist de "{{✅ Qué queda listo al terminar}}" de la fase, en verde y verificado a mano.
- [ ] `git status` limpio: todo lo de la fase está commiteado.
- [ ] `git tag -a {{fase-NN-slug}} -m "…"` creado, con el checklist en el mensaje.
- [ ] {{Si la fase dejó un incidente resuelto, su par `inc/…-roto` / `inc/…-fix` existe y sus mensajes
      cuentan síntoma, causa raíz y fix.}}
- [ ] {{Si la fase declara o paga una deuda 💸, su tag `deuda/<slug>-declarada` o `-pagada`, con el
      mensaje que nombra al otro extremo.}}

> **La señal de que quedó bien:** "vuelvo después de tres semanas, corro `git tag -l 'fase-*'`, y sé
> exactamente dónde me quedé y qué sigue — sin releer una sola línea del curso".
