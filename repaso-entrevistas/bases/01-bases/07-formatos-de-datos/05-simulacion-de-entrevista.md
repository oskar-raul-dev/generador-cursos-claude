# 05 — Simulación de entrevista

> El examen del bloque: 34 preguntas transversales que cruzan los cuatro formatos y seis problemas de
> pizarra de veinte minutos. No se responde leyendo: se responde **en voz alta y tecleando**, que es
> como se responde en la entrevista real.
>
> Las soluciones están en [`06` — Respuestas](06-respuestas.md). Se miran **después**.
>
> **Vigencia:** 2026-09-18. · **Requisito:** los cuatro capítulos del bloque.

---

## 1. 🎯 Cómo se usa esto

```text
1. Cronómetro: 2 minutos por pregunta S#, 20 por problema de pizarra.
2. EN VOZ ALTA, y el código TECLEADO de verdad, no imaginado.
3. Primero la frase de 30 segundos. Se amplía solo si quedó completa.
4. Después se compara, y se anota qué capa faltó.
```

Dos reglas que valen más que el contenido:

- **Di siempre qué formato elegirías y por qué no los otros.** La pregunta de formatos casi nunca es
  "¿cómo se parsea?", es "¿por qué este?". Una respuesta que no compara no ha respondido.
- **Distingue lo que obliga la norma de lo que hace tu biblioteca.** Es la trampa de este bloque
  entero: casi todos los desastres de aquí vienen de una decisión de biblioteca, no del formato.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Elegir formato

**S1.** Tienes que elegir formato para una API pública nueva. ¿Cuál y por qué no los otros tres? 🟡

**S2.** ¿Y para un fichero de intercambio diario de diez millones de registros? 🟡

**S3.** ¿Y para la configuración de un servicio? 🟢

**S4.** ¿Y para un mensaje de pago hacia un banco? 🟠

**S5.** ¿Cuál de los cuatro tiene contrato validable de serie, y qué compra eso? 🟡

**S6.** ¿Cuál ocupa menos y cuánto menos? Da el orden con números. 🟡

### Bloque B — Tipos y pérdida de datos

**S7.** Nombra tres datos que ninguno de los cuatro formatos representa de forma nativa. 🟡

**S8.** ¿Cómo viaja una fecha en cada uno de los cuatro? 🟠

**S9.** ¿Cómo viaja el dinero, y por qué no como `number`? 🟠

**S10.** Un identificador numérico largo. ¿Qué le pasa en cada formato y en cada lenguaje? 🟠

**S11.** ¿Qué formatos distinguen nulo de cadena vacía y cuáles no? 🟡

**S12.** ¿Cuál de los cuatro convierte tipos sin que se lo pidas, y qué haces al respecto? 🟡

### Bloque C — Memoria y volumen

**S13.** ¿Cuánta memoria cuesta parsear un JSON de 100 MB a árbol? Da el orden de magnitud. 🟠

**S14.** ¿Qué es parsear en flujo y cuándo deja de ser opcional? 🟡

**S15.** Diferencia SAX de StAX, y di cuál usarías hoy. 🟡

**S16.** ¿Por qué un servicio que va bien con 2 MB se cae con 200 MB si el parseo es `O(n)`? 🟠

**S17.** Tienes que sumar un campo de un archivo de 4 GB. Describe el bucle. 🟠

### Bloque D — Seguridad

**S18.** Nombra un ataque propio de cada formato. 🟠

**S19.** ¿Qué hace el parser XML por defecto de Java que no hace ninguno de los otros? 🟡

**S20.** ¿Qué línea blinda ese parser y por qué esa? 🟡

**S21.** ¿Qué diferencia hay entre `yaml.load` y `yaml.safe_load`, y qué se busca en una revisión? 🟡

**S22.** ¿Por qué una celda de CSV que empieza por `=` es un problema y de quién es la
responsabilidad? 🟠

**S23.** ¿Por qué las claves duplicadas en JSON son un problema de seguridad y no solo de estilo? 🟠

### Bloque E — Contratos y evolución

**S24.** Llega un campo que tu modelo no conoce. ¿Error o se ignora? 🟡

**S25.** ¿Qué hace Go por defecto y qué hace Jackson por defecto? 🟡

**S26.** ¿Qué es un *tolerant reader* y cuándo **no** aplicarlo? 🟠

**S27.** ¿Cómo se añade un campo obligatorio a un contrato sin romper a nadie? 🟠

**S28.** ¿Qué protege el tipo de TypeScript en la frontera del sistema, y qué no? 🟠

### Bloque F — Las que descolocan

**S29.** El entrevistador afirma que `split(',')` es suficiente porque "el CSV lo generamos
nosotros". ¿Qué contestas? 🟠

**S30.** Te piden migrar de XML a JSON "porque XML está obsoleto". ¿Qué preguntas antes de aceptar? 🟠

**S31.** ¿Cuándo es correcto escribir tu propio parser de un formato existente? 🟠

**S32.** El mismo YAML da resultados distintos en dos servicios y ninguno tiene un bug. Explícalo. 🟠

**S33.** ¿Por qué los formatos binarios con esquema no han sustituido a JSON, si son mejores en casi
todo? 🔴

**S34.** Si tuvieras que enseñar este bloque entero en cinco minutos, ¿qué dirías y qué dejarías
fuera? 🔴

---

## 3. 🧪 Problemas de pizarra

Veinte minutos cada uno, tecleados. Se piensa en voz alta y se pregunta lo que falte antes de
escribir.

### P1 — El parser de CSV 🟠

Escribe un lector de una línea de CSV conforme a RFC 4180: campos separados por coma, comillas
dobles, comillas escapadas duplicándolas y saltos de línea dentro del campo. Sin usar la biblioteca
del lenguaje.

**Fuerza:** que reconozcas que esto **es una máquina de estados** y no un problema de partir cadenas.
Quien empieza por `split` no termina.

### P2 — Aplanar JSON a tabla 🟠

Dado un JSON con objetos anidados y arrays, produce un CSV con una fila por elemento de la raíz.
Decide y defiende qué haces con el anidamiento, con los arrays y con los campos que no aparecen en
todos los elementos.

**Fuerza:** decisiones de esquema, no algoritmia. **No hay respuesta correcta única** y lo que se
evalúa es que declares el criterio antes de teclear.

### P3 — Streaming de XML a NDJSON 🔴

Un XML de 2 GB con millones de `<pedido>` tiene que convertirse a NDJSON —un JSON por línea—
conservando tres campos por registro. La máquina tiene 512 MB.

**Fuerza:** memoria constante. Cualquier solución que construya el árbol está mal, y hay que decir
por qué antes de escribir la primera línea.

### P4 — El diagnóstico del archivo desconocido 🟠

Te dan un archivo de texto tabular sin documentación. Escribe el procedimiento para determinar
delimitador, codificación, presencia de cabecera y fin de línea, y di qué **no** puedes determinar
con certeza.

**Fuerza:** honestidad sobre los límites de una heurística. La parte más valiosa de la respuesta es
la lista de lo que no se puede saber sin preguntar.

### P5 — Diferencia mínima entre dos JSON 🔴

Dados dos documentos JSON, produce la lista de cambios para convertir el primero en el segundo:
altas, bajas y modificaciones, con la ruta de cada una.

**Fuerza:** recursión sobre estructuras heterogéneas y la decisión sobre los arrays —¿por posición o
por identidad?—, que es donde está el problema de verdad.

### P6 — Las configuraciones casi iguales 🟢

En un directorio hay **40** archivos YAML de configuración. Encuentra todas las parejas que difieran
en menos de tres claves.

**Fuerza:** que reconozcas que **la fuerza bruta es la respuesta correcta**. Son 780 comparaciones:
el doble bucle se escribe en cinco líneas, corre en milisegundos y se lee de un vistazo. Proponer
índices invertidos o *hashing* por similitud aquí es sobreingeniería, y decirlo en voz alta vale más
que la optimización.

---

## 4. 💡 Las frases que hay que tener listas

> **"Los identificadores viajan como cadena."** Cuesta dos comillas y elimina la corrupción
> silenciosa de los `2^53` en JavaScript, verificada en el capítulo `01`.

> **"Un árbol cuesta unas ocho veces el tamaño del archivo."** Medido: 30 MB de JSON, 323 MB de
> memoria en la JVM. Por eso el flujo deja de ser opcional cuando el tamaño no lo controlas tú.

> **"El formato no decide: decide la biblioteca."** El mismo YAML da `false` en Java y `"NO"` en Go;
> el mismo XML es seguro en Go y vulnerable en Java. Lo que hay que conocer es la implementación.

---

## 5. 📝 Qué anotar después

```text
Por cada pregunta fallada:
  ¿faltó la capa de 30 segundos, la de 2 minutos o el detalle?
  ¿respondí "cómo se parsea" cuando preguntaban "por qué ese formato"?
  ¿atribuí al formato algo que era de la biblioteca?
```

La tercera es la que más se repite en este bloque, y es la que más rápido se corrige.

---

**Anterior:** [`04` — CSV y los formatos tabulares](04-csv-y-los-formatos-tabulares.md) ·
**Siguiente:** [`06` — Respuestas](06-respuestas.md) · **Bloque:** [README](README.md)
