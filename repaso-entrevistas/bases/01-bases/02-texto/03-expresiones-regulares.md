# 03 — Expresiones regulares

> El autómata que hay detrás, la sintaxis que se usa de verdad, la diferencia entre greedy,
> lazy y posesivo, y el motivo por el que una expresión de tres líneas puede tumbar un
> servicio: el backtracking catastrófico. Cierra con la pregunta que más rinde, que es cuándo
> **no** usar una expresión regular.
> Asume leído [`01` — Strings](01-strings-entre-lenguajes.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un servicio valida entradas de usuario con una expresión regular que lleva años funcionando.
Un día, una petición con una cadena de 40 caracteres deja una CPU al 100 % durante minutos.
No hay excepción, no hay error, no hay nada en los logs: solo un hilo que no vuelve.

```text
patrón:  (a+)+$
entrada: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!"
```

Esa expresión, sobre esa entrada, hace **más de mil millones** de intentos antes de rendirse.
Con cinco caracteres más, mil millones se convierten en treinta mil millones. Es un ataque de
denegación de servicio que cabe en un campo de formulario, y tiene nombre propio: **ReDoS**.

El otro problema es menos dramático y mucho más frecuente: expresiones que nadie puede leer,
que validan mal y que se copian de internet sin entenderlas. La regex de correo electrónico
"completa" tiene más de 6 000 caracteres y aun así rechaza direcciones válidas.

> **Regla de entrevista:** una expresión regular es código. Si no la puedes explicar
> carácter a carácter y decir su coste en el peor caso, no la puedes poner en producción.

---

## 2. 🧱 El autómata que hay detrás

**Qué es.** Una expresión regular describe un **lenguaje regular**, y todo lenguaje regular se
reconoce con un autómata finito. Hay dos formas de implementarlo y la diferencia lo explica
todo:

| Enfoque | Cómo funciona | Coste | Quién lo usa |
|---|---|---|---|
| **Backtracking** | Prueba una alternativa; si falla, retrocede y prueba otra | **Exponencial** en el peor caso | Java, Python, JavaScript, PCRE, .NET |
| **Autómata (Thompson)** | Simula todos los estados posibles a la vez | **O(n·m) garantizado** | Go (RE2), Rust, `grep` |

- El backtracking es más **expresivo**: permite retrorreferencias (`\1`), lookbehind variable y
  otras construcciones que ya no son lenguajes regulares en sentido estricto.
- El autómata es más **seguro**: no puede degradarse, porque no hay nada que reintentar. A
  cambio, no soporta retrorreferencias, y no es un olvido: **son imposibles** en ese modelo.
- La elección de cada lenguaje es una decisión de diseño explícita, no una casualidad de
  implementación.

> 🧠 **Modelo mental.** Casi todos los motores que usas prueban caminos y se arrepienten. Go y
> `grep` simulan todos los caminos a la vez. Esa frase explica por qué el mismo patrón es
> seguro en uno y peligroso en el otro.

---

## 3. 🧱 La sintaxis que se usa de verdad

No hacen falta las cincuenta construcciones. Con estas se escribe el 95 % de lo que aparece en
un backend:

```text
.        cualquier carácter (salvo salto de línea)
\d \w \s dígito, carácter de palabra, espacio    (\D \W \S: los negados)
[abc]    uno de estos     [^abc] ninguno de estos     [a-z] rango
^  $     inicio y fin (de la cadena, o de línea con la bandera MULTILINE)
\b       frontera de palabra
*  +  ?  cero o más, uno o más, cero o uno
{2,5}    entre 2 y 5 repeticiones
|        alternativa
( )      grupo de captura      (?: )  grupo sin captura
```

- **`(?: )` cuando no necesitas el contenido.** Capturar sin usar cuesta memoria y ensucia los
  índices de los grupos. Es la mejora más barata que se le puede hacer a una regex heredada.
- **`^` y `$` cambian de significado** con la bandera `MULTILINE`: pasan de anclar la cadena a
  anclar cada línea. Es una fuente habitual de validaciones que se saltan con un salto de
  línea.
- **`\b` es la construcción más infravalorada**: `\bcaja\b` evita que "cajamarca" cuente como
  coincidencia, y ahorra media docena de casos borde.

**Cuándo no** usar sintaxis avanzada: si tu expresión necesita retrorreferencias o lookbehind
de longitud variable, probablemente estás intentando parsear algo que no es regular —HTML,
JSON, expresiones anidadas— y la respuesta correcta es un parser.

---

## 4. 🧱 Greedy, lazy y posesivo

**El problema.** Sobre `<b>hola</b>`, el patrón `<.*>` no captura `<b>`: captura
`<b>hola</b>` entero. Y sorprende a todo el mundo la primera vez.

**Cómo va.** Los cuantificadores tienen tres modos:

| Modo | Sintaxis | Qué hace | Sobre `<b>hola</b>` con `<.*>` |
|---|---|---|---|
| **Greedy** (por defecto) | `*` `+` `?` | Coge todo lo que pueda y retrocede si hace falta | `<b>hola</b>` |
| **Lazy** (reacio) | `*?` `+?` `??` | Coge lo mínimo y avanza si hace falta | `<b>` |
| **Posesivo** | `*+` `++` `?+` | Coge todo y **no retrocede nunca** | Falla: no encuentra nada |

- El greedy **retrocede**, y ese retroceso es exactamente el mecanismo que se vuelve
  catastrófico en la sección 5.
- El posesivo existe para evitarlo: al prohibir el retroceso, acota el trabajo. Java y PCRE lo
  tienen; **JavaScript y Python no**.
- La alternativa al lazy suele ser mejor: en vez de `<.*?>`, escribir `<[^>]*>` —"cualquier
  cosa que no sea un cierre"— es más rápido, más claro y no depende del retroceso.

> 💡 **Truco.** Cuando una expresión funciona pero captura de más, la respuesta refleja es
> poner `?` para hacerla lazy. La respuesta buena es preguntarse **qué no debería aparecer
> dentro**, y usar una clase negada. Evita el retroceso en vez de dirigirlo.

---

## 5. 🧱 ReDoS: la autopsia del backtracking catastrófico

**El patrón que escribe todo el mundo.** Validar una lista de palabras separadas por comas, o
un identificador con grupos repetidos:

```text
(a+)+$
```

**Por qué parece correcto.** Funciona con todas las entradas válidas, y con las inválidas
cortas también. Pasa todos los tests que el autor escribió.

**La entrada que lo rompe.** Una cadena de aes que **no termina** como el patrón exige:
`"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!"`. El `!` final hace que la coincidencia falle, y ahí empieza
el desastre.

**Qué pasa exactamente.** El grupo interno `a+` puede repartir las 30 aes de muchísimas
maneras entre las repeticiones del grupo externo `(...)+`: una de 30, dos de 15, tres de 10,
quince de 2… El motor prueba **todas** las particiones antes de concluir que ninguna funciona.
Son 2³⁰ combinaciones: más de mil millones.

**La corrección.**

```text
(a+)+$     ← ambiguo: dos cuantificadores anidados sobre lo mismo
a+$        ← equivalente, y lineal
```

- La causa raíz es la **ambigüedad**: el mismo texto puede analizarse de varias formas. Un
  cuantificador dentro de otro sobre el mismo carácter es la señal de alarma.
- Las otras dos formas de evitarlo: cuantificadores **posesivos** (`(a+)++$`) donde el lenguaje
  los tenga, y **límite de tiempo** en la ejecución de la regex.
- Y la defensa que siempre aplica: **acotar la longitud de la entrada antes de aplicar la
  expresión**. Es una línea de código y corta el problema de raíz.

**La generalización.** Toda expresión con cuantificadores anidados o con alternativas que
pueden coincidir con lo mismo —`(a|aa)+`— es sospechosa. Si además se aplica a entrada de
usuario, es una vulnerabilidad, y está catalogada como tal por OWASP.

---

## 6. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| Compilar el patrón | O(m) | **Es lo caro.** Compilar dentro de un bucle es el error de rendimiento nº 1 |
| Coincidir, motor de autómata | O(n·m) garantizado | Go y `grep`. No se puede degradar |
| Coincidir, motor de backtracking | O(n) típico, **O(2ⁿ) peor** | Java, Python, JS. El peor caso es un ataque, no una rareza |
| `String.split` por un carácter | O(n) | En Java compila una regex cada vez, salvo para un solo carácter literal |
| `replaceAll` | O(n) más el coste de coincidir | Recompila el patrón en cada llamada si le pasas un `String` |

> ⏱️ **Coste.** `Pattern.compile` es caro y **el `Pattern` es inmutable y seguro entre
> hilos**: se guarda en una constante `static final`. Usar `String.matches()` dentro de un
> bucle recompila la expresión en cada vuelta, y es una de las diferencias de rendimiento más
> grandes que se consiguen con un cambio de dos líneas.

---

## 7. ⚖️ Los cinco lenguajes

| Lenguaje | Motor | ¿Vulnerable a ReDoS? | El detalle que muerde |
|---|---|---|---|
| **Java** | Backtracking | **Sí** | Tiene cuantificadores posesivos. `Pattern.compile` se cachea a mano, no automáticamente |
| **Python** | Backtracking | **Sí** | `re` cachea los últimos patrones compilados; aun así se precompila explícitamente |
| **JavaScript** | Backtracking | **Sí** | Sin posesivos. El literal `/…/` se compila una vez si está fuera del bucle |
| **TypeScript** | Igual que JS | Igual que JS | Aporta tipos de plantilla literal, que validan **formatos simples en compilación** |
| **Go** | **RE2, autómata** | **No** | Garantía lineal, y por eso **no soporta retrorreferencias ni lookahead**. Es el precio |

La comparación Go contra el resto es la más instructiva de todo el bloque: **Go eligió no
poder expresar ciertas cosas a cambio de no poder degradarse**. Es el mismo tipo de decisión
que aleatorizar el recorrido de los mapas, y decirlo así conecta dos capítulos.

> 📝 **Contexto.** TypeScript 4.1 introdujo los *template literal types*, que permiten validar
> formatos sencillos —`` `${string}@${string}` ``— **en tiempo de compilación**, sin ejecutar
> ninguna expresión regular. No sustituyen a una regex en runtime, pero cubren el caso de
> validar la forma de una constante o de un identificador tipado.

---

## 8. 🧭 Cómo se elige

La sección que más rinde de este capítulo: **cuándo no usar una expresión regular**.

```text
¿Es una búsqueda de subcadena literal?       → contains / indexOf. No regex
¿Separar por un solo carácter?               → split de carácter, no de patrón
¿Estructura anidada: HTML, JSON, código?     → parser. Nunca regex
¿Validar correo electrónico?                 → una regex mínima + verificación real por envío
¿El patrón lo define el usuario?             → motor de autómata, o límite de tiempo
¿Necesitas retrorreferencias?                → asegúrate de que de verdad las necesitas

¿Es un patrón fijo que se usa muchas veces?  → Pattern.compile en constante static final
```

> **Regla de entrevista:** "no lo resolvería con una expresión regular" es una respuesta
> excelente cuando viene con el motivo. Los lenguajes anidados no son regulares, y decir eso
> con esas palabras vale más que escribir el patrón.

> **Veredicto:** la expresión regular gana cuando el patrón es plano, corto y estable, y pierde
> en cuanto hay anidamiento, entrada de terceros o alguien que tendrá que mantenerla. Si no cabe
> en una línea con nombre propio, ya no es la herramienta.

---

## 9. 🔭 Dónde aparece de verdad

En la validación de formularios y de DTOs —`@Pattern` de Bean Validation es una regex con
anotación encima—; en el enrutado de peticiones y en las reglas de un WAF; en el parseo de
logs, que es donde más ReDoS se han descubierto; en las reglas de un `.gitignore` y de un
`grep` en un pipeline de CI; y en las migraciones de datos, donde una expresión mal anclada
convierte diez mil registros en basura de forma silenciosa.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Una regex siempre es rápida" | Con backtracking, el peor caso es exponencial. Es una vulnerabilidad catalogada |
| "Valido HTML con una regex" | HTML no es un lenguaje regular. Hace falta un parser |
| "`String.matches()` en el bucle" | Recompila el patrón en cada vuelta. Se usa `Pattern` en constante |
| "`.*` captura lo mínimo" | Es greedy: captura lo máximo y retrocede. Lo mínimo es `.*?` |
| "`^` y `$` anclan la cadena" | Con `MULTILINE` anclan cada línea, y ahí se cuela el salto de línea |
| "Go tiene el mismo motor de regex" | Go usa RE2: lineal garantizado, sin retrorreferencias |
| "Uso `(...)` porque hay que agrupar" | Si no usas el contenido, `(?:...)` agrupa sin capturar |

---

## 📚 Para profundizar

- **Libro** — Friedl, *Mastering Regular Expressions*, 3ª ed. (O'Reilly, 2006). Capítulos 4 y
  6, sobre el mecanismo de backtracking y la optimización de patrones. **Si solo lees uno de
  este tema, lee este**: sigue siendo la referencia veinte años después.
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4ª ed. (Addison-Wesley, 2011). Sección 5.4:
  construye el motor de autómata desde cero, que es la mejor forma de entender por qué el otro
  se degrada.
- [Russ Cox — Regular Expression Matching Can Be Simple And Fast](https://swtch.com/~rsc/regexp/regexp1.html):
  el artículo que explica la diferencia entre los dos motores con las gráficas comparativas.
  Es la fuente primaria de RE2.
- [Russ Cox — Regular Expression Matching in the Wild](https://swtch.com/~rsc/regexp/regexp3.html):
  cómo se implementó RE2 y qué se sacrificó a cambio de la garantía lineal.
- [OWASP — Regular expression Denial of Service (ReDoS)](https://owasp.org/www-community/attacks/Regular_expression_Denial_of_Service_-_ReDoS):
  el catálogo de patrones vulnerables y las mitigaciones.
- [Java 21 API — `Pattern`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/regex/Pattern.html):
  la referencia de sintaxis, incluidos los cuantificadores posesivos y las banderas.
- [Python — `re`](https://docs.python.org/3/library/re.html): la caché de patrones compilados y
  las diferencias con otros motores.
- [MDN — Regular expressions guide](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_expressions):
  la referencia de JavaScript, con las banderas y los grupos con nombre.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`05` — Respuestas](05-respuestas.md).

1. ¿Qué es un lenguaje regular y qué tipo de autómata lo reconoce? 🟢
2. ¿Qué diferencia hay entre `(...)` y `(?:...)`? 🟢
3. ¿Qué captura `<.*>` sobre `<b>hola</b>` y por qué? 🟢
4. ¿Qué hace `\b` y qué problema evita? 🟢
5. ¿Qué operación de una expresión regular es la cara: compilar o coincidir? 🟢
6. ¿Qué significa que un cuantificador sea posesivo? 🟢
7. ¿Qué es ReDoS? 🟢
8. ¿En qué se diferencia un motor de backtracking de uno de autómata? 🟡
9. ¿Por qué Go no soporta retrorreferencias? 🟡
10. ¿Qué cambian las banderas `MULTILINE` y `DOTALL`? 🟡
11. ¿Por qué `<[^>]*>` suele ser mejor que `<.*?>`? 🟡
12. ¿Por qué `String.matches()` dentro de un bucle es un problema de rendimiento? 🟡
13. ¿Qué lenguajes de los cinco tienen cuantificadores posesivos? 🟡
14. ¿Por qué `(a+)+$` es exponencial y `a+$` es lineal, si reconocen lo mismo? 🟠
15. Da tres formas distintas de defenderte de un ReDoS, ordenadas por lo que cuestan. 🟠
16. ¿Por qué no se puede validar HTML con una expresión regular? 🟠
17. ¿Es `Pattern` seguro entre hilos? ¿Y `Matcher`? 🟠
18. ¿Qué señales te hacen sospechar que una expresión heredada es vulnerable? 🟠
19. Te piden validar direcciones de correo electrónico. ¿Qué respondes? 🟠
20. ¿Qué pierde Go al elegir RE2, y por qué lo considera un buen negocio? 🟠
21. ¿Qué aportan los *template literal types* de TypeScript y qué no pueden hacer? 🟠
22. ¿Por qué `String.split(",")` en Java no es tan caro como parece, y `split("\\s+")` sí? 🟠
23. Una validación en producción deja una CPU al 100 % con una petición de 40 caracteres.
    Explica el mecanismo, identifica el patrón culpable y da la corrección. 🔴
24. Te dan `^(\w+\s?)*$` para validar nombres. Explica si es segura y corrígela si no lo es. 🔴
25. Diseña la validación de un identificador de producto con formato `AAA-9999-XX`, en Java y
    en Go, y explica qué cambia entre ambas. 🔴

---

**Anterior:** [`02` — Algoritmos de cadenas](02-algoritmos-de-cadenas.md) ·
**Siguiente:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**Relacionado:** [`01` — Strings](01-strings-entre-lenguajes.md)
