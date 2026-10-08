# 🧩 Plantilla de capítulo
## Go para desarrolladores Java senior — la plataforma Meridian

Este archivo contiene el esqueleto que se copia al abrir el chat de una fase.
Como el curso **no tiene apéndices** (`alcance-del-proyecto.md` §9), hay una sola
plantilla y es rígida: diez secciones, en orden, idénticas en las dieciocho fases.

Junto con la guía de estilo y el alcance, es lo que hace que dieciocho documentos
escritos en dieciocho chats se lean como un solo libro.

> **Nota de coherencia:** las cifras de referencia son las de
> `propuesta-fases-y-alcance.md` §2 — **131h en 18 fases**. Si cambian, se
> actualizan allí primero y aquí después, nunca al revés.

---

# 📐 Plantilla de fase

Copiar el bloque completo, rellenar los `{{placeholders}}` y borrar las notas
entre llaves antes de entregar.

````markdown
# {{emoji}} Fase {{NN}} — {{Nombre}}

> Go para desarrolladores Java senior · Fase {{N}} de 17 · **{{X}} horas**
> Época: **{{Go 1.13 (stdlib pura) | frontera | Go moderno ({{versión}})}}**
> Depende de: {{fase previa}} · Habilita: {{fase siguiente}}
> Proyectos que avanzan: {{OpsReport · EventRelay · AtlasSync · ClearingHouse}}
> Mini proyectos: {{`nombre-1`, `nombre-2`, `nombre-3`}}

---

## 🎯 1. Propósito

{{Una o dos frases: qué resuelve esta fase y por qué le importa a alguien que va
a escribir Go en su trabajo el mes que viene. Abrir con el estado en que la fase
anterior dejó los proyectos — no con una definición.}}

---

## ✅ 2. Qué queda listo al terminar

- [ ] {{resultado verificable 1}}
- [ ] {{resultado verificable 2}}
- [ ] {{...4 a 6 ítems}}
- [ ] `go vet ./...` y `golangci-lint run` en verde{{, y `go test -race ./...` si
      la fase toca concurrencia}}

{{Verificable = se comprueba corriendo un comando o mirando una salida.
"Entender los canales" no es un resultado verificable; "tu worker pool procesa
10.000 jobs sin que -race reporte nada" sí.}}

---

## 🚫 3. Qué NO entra todavía

- {{tema diferido}} → Fase {{M}}.
- {{...}}

{{Si la fase es del Bloque A, incluir aquí lo que está fuera por época, con su
marca 🕰️ y su versión mínima: "genéricos → Fase 08 (Go 1.18)".}}

---

## 🧠 4. Concepto mínimo

{{Solo la teoría necesaria para escribir el código de esta fase. Prosa, no
viñetas. El problema antes que la herramienta (guía §4.2). Ningún bloque de más
de dos pantallas sin un comando o un fragmento.}}

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

{{Obligatoria. El reflejo concreto, por qué es razonable en Java, y qué pasa
exactamente si lo aplicas aquí. Con el código de las dos versiones cuando ayude.
Cerrar con qué pensar en su lugar.}}

### 🩻 Esto sí funciona igual

{{Obligatoria, aunque sean tres líneas. El contrapeso honesto: qué se traslada
intacto desde Java. El curso no pide olvidar lo que el lector sabe.}}

> 📝 **Nota de época.** {{Qué versión de Go trajo esta API, qué reemplazó, y por
> qué el código anterior sigue siendo correcto para su momento. En el Bloque A,
> además: qué existe hoy y aquí no podemos usar todavía, marcado 🕰️.}}

---

## 🛠️ 5. CLI de la fase

{{Obligatoria en todas las fases. Los comandos que esta fase introduce o usa en
serio, con lo que hace cada bandera que aparece. No es una lista de comandos: es
el sitio donde el estudiante aprende a moverse sin IDE.}}

```bash
# {{qué hace y por qué te importa}}
go {{subcomando}} {{banderas}}
```

{{Incluir siempre: qué salida esperas, qué significa cuando falla, y el
equivalente de Maven o Gradle cuando exista — con su límite, porque casi nunca es
exacto.}}

> 💡 {{Un atajo real: una bandera poco conocida, una variable de entorno, un
> `go doc` que ahorra una búsqueda en el navegador.}}

---

## 💻 6. Construcción guiada

{{El grueso de la fase, en ciclos de "diciendo y haciendo" (guía §4.1): problema
→ comando → código mínimo → ejecútalo → qué observas → cómo sería en Java →
rómpelo → el test → llévalo al proyecto. Tantos ciclos como conceptos tenga la
fase.}}

### 6.1 Mini proyecto: `{{nombre}}`

{{Aísla un concepto. Menos de doscientas líneas, con sus tests. Vive en
`labs/{{nombre}}/`. Decir explícitamente a qué servicio va a alimentar después —
si no alimenta a ninguno, sobra.}}

### 6.2 {{Avance de {{Proyecto}}}}

{{Qué se le agrega al servicio y por qué ahora. Código ejecutable, coherente con
la época de la fase.}}

{{Estilo obligatorio — guía §6.2:
- Errores como valores; `%w` cuando el llamador pueda preguntar, `%v` cuando no,
  y la decisión comentada.
- `context.Context` como primer parámetro de todo lo que hace E/S.
- Ninguna goroutine sin dueño ni tope.
- Interfaces pequeñas, declaradas en el consumidor.
- Dependencias por constructor; sin estado global mutable; sin trabajo en `init()`.
- Paquetes de una palabra; nada de `utils`, `common`, `impl`, ni tartamudeo.
- Código en inglés, comentarios en español con tildes; mensajes de error en
  español, minúscula inicial, sin punto final.
- Reloj inyectado; fechas con zona explícita.}}

**Detalles con intención**
- {{decisión deliberada del bloque anterior}} — {{su porqué, en media línea}}.

**El patrón a memorizar**
> {{Una o dos frases con la lección transferible del fragmento.}}

**🧪 Prueba de fuego**
{{Verificación concreta: qué ejecutar, qué salida esperar, y qué mentira te va a
contar la pantalla si miras el sitio equivocado.}}

{{💸 Marcar cada deuda intencional con sus dos partes: qué sería lo correcto y
**en qué fase se paga**. Si no se paga, decirlo y explicar por qué. Un 💸 sin
destino es un error de escritura.}}

{{📐 Si la fase afirma algo sobre rendimiento, marcarlo y enlazar su entrada de
`BENCHMARKS.md`. Sin entrada, la afirmación no se escribe.}}

---

## ⚰️ 7. Autopsia y errores comunes

### ☕ Autopsia: {{nombre del antipatrón}}

{{Obligatoria desde la Fase 02. Un caso concreto de Java escrito en Go: el código
tal como lo escribiría alguien que viene de Spring, por qué es razonable que lo
escriba así, y la versión idiomática al lado. Con el costo medido: archivos,
líneas, indirecciones, asignaciones, tiempo de compilación o latencia — lo que
aplique, pero un número. Se anota en `INSTINTOS.md`.}}

### Errores comunes

{{2 a 4 errores típicos, en formato síntoma → causa → fix mínimo. Distinguir
siempre el parche mínimo de la refactorización correcta (guía §6.6).}}

### 🧨 Rompe a propósito

{{Al menos uno. Qué tocar, qué comando correr, y qué esperas ver exactamente en
la salida — el mensaje del compilador, el `WARNING: DATA RACE`, el `fatal error:
all goroutines are asleep`. Que el estudiante reconozca el error por su cara
antes de encontrárselo en producción.}}

---

## 🧪 8. Ejercicios ({{total}})

**🟢 Fácil (1–{{a}})**
1. {{...}}

**🟡 Intermedio ({{a+1}}–{{b}})**
**🟠 Difícil ({{b+1}}–{{c}})**
**🔴 Muy difícil ({{c+1}}–{{total}})**
**🔥 Opcionales**

{{20 mínimo, 24 ideal, hasta 30 en las densas. Numeración continua; el título
lleva el conteo — y cuenta SOLO los numerados: los 🔥 y los desafíos de abajo
quedan fuera. Accionables y con criterio de éxito medible. Al menos un tercio
de diagnóstico (se entrega algo roto). Desde la Fase 02, al menos dos de
detección de ☕. Al menos uno de línea de comandos. Anclados al dominio de
Meridian, nunca `foo` y `bar`. Cada 🔴 lleva rúbrica o solución de referencia.}}

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base. {{Ajustar la frase a la fase si hace falta.}}

**D1 — {{título}}.**
{{El planteamiento, en dos o tres líneas.}}
*Rúbrica:* (a) {{…}}; (b) {{…}}; (c) {{…}}; (d) {{…}}; (e) {{…}}.

**D2 — {{título}}.**
{{…}}

**D3 — {{título}}.**
{{…}}

{{Guía §9.2. EXACTAMENTE TRES, identificados D1/D2/D3, sin numerar, fuera del
conteo. Cubren lo que la fase dejó fuera A PROPÓSITO —el hueco declarado en la
§3, la comparación que no se hizo, la herramienta que el temario no montó—, no
lo que ya consolidan los 🔴 numerados. No duplican ningún ejercicio de arriba.
Respetan la época de la fase. Cada uno con rúbrica de cuatro a seis puntos, y a
ser posible produciendo algo que el lector se lleve a su trabajo. Son el sitio
legítimo para cerrar una omisión declarada del propio curso, y cuando lo hacen,
se dice.}}

---

## 📚 9. Referencias

**Documentación oficial**
- {{URL completa}} — {{qué resuelve; advertencia de versión si aplica}}

**Libros**
- {{Autor, *Título*}} — {{capítulo o tema; sin inventar ISBN ni páginas}}

**Artículos y charlas**
- {{...}}

**Video**
- {{título y canal, con la advertencia de fecha}}

**Orden de lectura sugerido:** {{qué leer antes de escribir código → qué
consultar durante → a qué volver después}}

> ⚠️ URLs, títulos y contenidos pueden haber cambiado; verifícalos. {{Y en el
> Bloque A, la advertencia propia: casi toda la documentación en línea describe
> Go moderno, así que un ejemplo con genéricos o `slog` no es un error del autor
> — es que estamos trabajando en 2019 a propósito.}}

{{Esta sección es OBLIGATORIA y NO SE RECORTA por extensión (guía §9.2). Las
cinco partes —oficial, libros, artículos y charlas, video, orden de lectura— van
siempre, aunque alguna tenga dos entradas. Si hay que quitar contenido de una
fase por longitud, se quita de la §6, nunca de la §8 ni de la §9.}}

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

{{Obligatoria. Los casos en los que lo que acabas de enseñar es la respuesta
equivocada, y qué usar en su lugar. Con nombres: si la respuesta es "quédate con
Spring", se dice.}}

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| {{concepto}} | {{concepto}} | {{la parte que importa}} |

{{Obligatoria. Mapeo en las dos direcciones — la tercera columna es la que vale.
Distinguir equivalencia aproximada, parcial y ninguna.}}

### Qué sigue

{{Qué quedó construido y por qué la Fase {{siguiente}} es el paso natural: qué
necesita de esta fase para existir.}}

> **La señal de que quedó bien:** {{criterio en forma de cita — cómo se siente el
> trabajo bien hecho de esta fase.}}

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go test -race ./...` en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-{{NN}} -m "F{{N}} cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la fase llevan su prefijo (`fase {{NN}}: …`) y los de ejercicio
> su número (`fase {{NN}} ej17: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](../00-convencion-de-git-y-tags.md).
>
> {{Si la fase tiene algo propio que decir sobre git —paga una deuda 💸 declarada
> antes, marca un hito de proyecto (`opsreport/v0.4`), deja una rama de
> comparación como la de la Fase 08— se añade un párrafo corto al final del mismo
> bloque, no un bloque nuevo.}}
````

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

Va después de la sección 10, separado por un `---`, y **no forma parte del
capítulo**: es material para quien escribe el curso.

````markdown
---

## 📌 Pendientes sugeridos

{{Lo que apareció al escribir la fase y no cabía dentro, cada uno con destino
explícito: fase posterior, ejercicio 🔥, entrada de `INSTINTOS.md`, entrada de
`BENCHMARKS.md`.}}

- {{pendiente}} → {{destino}}

## ☕ Reflejos para `INSTINTOS.md`

{{Los ☕ que esta fase descubrió, con su nombre, el síntoma en una línea y la
fase donde se documentan.}}

## 📐 Mediciones para `BENCHMARKS.md`

{{Las entradas que esta fase necesita: hipótesis, condiciones, comando. Con el
formato de `formato-de-benchmarks.md`.}}
````

---

# ✅ Antes de entregar

Pásale al documento el checklist de §13 de `guia-de-estilo-y-convenciones.md` y
reporta en una lista corta qué ítems cumples y cuáles no, con el motivo.

Los cinco que más se rompen, por orden de frecuencia:

1. **La época.** Una API posterior a 1.13 colada en el Bloque A sin marca 🕰️.
2. **El bloque teórico largo.** Más de dos pantallas sin un comando de por medio.
3. **El 💸 sin fase de cobro.**
4. **La afirmación de rendimiento sin entrada en `BENCHMARKS.md`.**
5. **La comparación que se lee como "Spring es malo".**
