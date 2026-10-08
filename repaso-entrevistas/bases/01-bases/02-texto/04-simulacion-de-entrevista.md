# 04 — Simulación de entrevista

> El examen del bloque. Treinta y dos preguntas `S#` transversales que cruzan los tres
> capítulos, más cuatro problemas de pizarra completos. Se contesta **en voz alta y
> cronometrado**, y los problemas se **teclean**.
> Asume leídos [`01`](01-strings-entre-lenguajes.md) a
> [`03`](03-expresiones-regulares.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA. Grábate.
3. Los problemas de pizarra se TECLEAN, en 20 minutos, sin autocompletado.
4. Solo después vas a `05-respuestas.md`.
5. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

> **Regla:** en este bloque, la mitad de las preguntas tienen una respuesta que empieza por
> *"depende de qué estés contando"*. Si esa frase no te sale sola, vuelve a
> [`01`](01-strings-entre-lenguajes.md).

---

## 2. 🧠 Preguntas transversales

### Bloque A — El modelo de string

**S1.** ¿Por qué el string es inmutable en los cinco lenguajes? Da tres razones distintas. 🟢

**S2.** "¿Cuántos caracteres tiene esta cadena?" ¿Qué preguntas antes de contestar? 🟡

**S3.** ¿Qué devuelve contar `"👍"` en cada uno de los cinco lenguajes? 🟡

**S4.** ¿Por qué una comparación de strings puede funcionar en test y fallar con datos
reales? Da dos causas independientes. 🟠

**S5.** ¿Dónde normalizas Unicode: al entrar, al comparar o al guardar? Justifica. 🟠

**S6.** Te piden truncar un campo a 30 caracteres. Enumera todo lo que preguntas antes. 🟠

### Bloque B — Rendimiento con texto

**S7.** ¿Qué complejidad tiene concatenar en un bucle y por qué? 🟢

**S8.** ¿Por qué `a + b + c` en una línea no es un problema y en un bucle sí? 🟡

**S9.** ¿Qué operación de una expresión regular hay que sacar del bucle, y por qué? 🟡

**S10.** Un informe que arma 200 000 líneas tarda cuatro minutos. Da tu diagnóstico y tu
solución. 🟠

**S11.** ¿Por qué `substring` dejó de ser O(1) en Java 7, y qué enseña ese cambio? 🟠

**S12.** ¿Qué haces si el perfilador dice que el 40 % del tiempo está en `String.format`? 🟠

### Bloque C — Búsqueda de patrones

**S13.** ¿Qué algoritmo usa `indexOf` y por qué es una decisión razonable? 🟢

**S14.** ¿Qué garantiza KMP que no garantiza la búsqueda ingenua? 🟡

**S15.** ¿En qué se diferencian KMP y Boyer-Moore, en una frase? 🟡

**S16.** ¿Cuál es la ventaja real de Rabin-Karp? 🟠

**S17.** ¿Cuándo un trie se justifica y cuándo es sobreingeniería? 🟠

**S18.** Te piden buscar 5 000 términos prohibidos en cada mensaje entrante. Elige el
enfoque. 🟠

**S19.** ¿Por qué ningún lenguaje de los cinco trae KMP en su stdlib? ¿Qué te dice eso? 🟠

### Bloque D — Expresiones regulares

**S20.** ¿Qué es un lenguaje regular y qué no lo es? Da dos ejemplos de cada uno. 🟡

**S21.** ¿Por qué `(a+)+$` es peligroso? 🟡

**S22.** ¿Cómo defiendes un endpoint que aplica una regex a entrada de usuario? 🟠

**S23.** ¿Por qué Go no puede sufrir ReDoS y qué perdió a cambio? 🟠

**S24.** Te piden validar correos electrónicos con una expresión regular. Responde. 🟠

**S25.** ¿Qué señales te hacen abrir una revisión de código sobre una regex heredada? 🟠

### Bloque E — Los cinco lenguajes

**S26.** ¿Qué hace `len(s)` en Go y por qué es coherente con el diseño del lenguaje? 🟡

**S27.** ¿Qué aporta TypeScript en este bloque, y dónde no aporta nada? 🟠

**S28.** ¿Por qué `"".join(lista)` es el idioma de Python y no `+=`? 🟠

**S29.** Compara cómo resuelven los cinco lenguajes la construcción de texto en bucle. 🟠

### Bloque F — Las que descolocan

**S30.** "Las expresiones regulares son ilegibles, no las uso nunca." Responde a un compañero
que dice esto. 🔴

**S31.** Un cliente aparece duplicado en la base con el mismo nombre visible. Da tu
investigación completa. 🔴

**S32.** ¿Cuándo has tenido un bug de codificación de caracteres y cómo lo encontraste? 🔴

---

## 3. 🧪 Problemas de pizarra

Veinte minutos cada uno, tecleando y narrando. La solución completa está en
[`05`](05-respuestas.md).

### P1 — Contar palabras de un archivo de 2 GB

**Fuerza:** elegir entre regex, `split` y recorrido manual con criterio de coste.

Cuenta la frecuencia de cada palabra en un archivo de texto de 2 GB que no cabe en memoria.
Escribe la solución, di su complejidad y su consumo de memoria, y justifica por qué elegiste
esa forma de separar palabras y no las otras dos.

Repregunta: *"¿y si te piden las 10 más frecuentes?"*.

### P2 — El validador de nombres

**Fuerza:** que la respuesta correcta exige preguntar antes de escribir.

Valida un campo "nombre completo": máximo 50 caracteres, letras, espacios, apóstrofos y
guiones. Tiene que funcionar con `María José`, `O'Connor`, `Müller-Schmidt` y con nombres en
árabe y en japonés.

Repregunta: *"¿es segura tu expresión frente a una entrada hostil?"*.

### P3 — Anagramas agrupados

**Fuerza:** el hash correcto, y la diferencia entre dos soluciones que parecen iguales.

Dada una lista de palabras, agrúpalas por anagramas: `["cosa", "caso", "arco", "roca"]` →
`[["cosa", "caso"], ["arco", "roca"]]`. Da dos soluciones con distinta complejidad y elige.

Repregunta: *"¿y si las palabras tienen acentos?"*.

### P4 — El log que hay que parsear

**Fuerza:** decidir si es regex o no, y defender la decisión con números.

Tienes 50 GB de logs con líneas de formato fijo:
`2026-09-17T10:33:02Z INFO [pedidos] PedidoConfirmado id=12345 monto=99.50`. Extrae el id y el
monto de las líneas de `PedidoConfirmado`. Escribe la solución que usarías en producción.

Repregunta: *"¿cuánto tarda tu solución y dónde está el tiempo?"*.

---

## 4. 🧠 Las frases que hay que tener listas

> **Sobre contar:** *"Depende de qué cuentes: unidades de código, code points o grafemas. En
> Java `length()` da unidades UTF-16, así que un emoji cuenta dos y cortar por ahí rompe el
> texto."*

> **Sobre buscar:** *"Empiezo con `indexOf`, que es ingenuo y basta en texto natural. Cambiaría
> a KMP si el alfabeto fuera pequeño y repetitivo, o a Aho-Corasick si fueran muchos patrones
> a la vez."*

> **Sobre regex:** *"Una regex es código con un peor caso exponencial en casi todos los
> motores. La compilo una vez en una constante, acoto la longitud de la entrada, y si la
> estructura es anidada no uso regex: uso un parser."*

---

**Anterior:** [`03` — Expresiones regulares](03-expresiones-regulares.md) ·
**Siguiente:** [`05` — Respuestas](05-respuestas.md) ·
**Relacionado:** [`01-fundamentos/05` — Simulación](../01-fundamentos/06-simulacion-de-entrevista.md)
