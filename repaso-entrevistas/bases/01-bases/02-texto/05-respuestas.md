# 05 — Respuestas

> Solucionario centralizado del bloque `02-texto`. Cada respuesta en tres capas:
> **⏱️ 30 segundos**, **🗣️ 2 minutos** y **🔬 El detalle**. Los enunciados están copiados
> literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--strings-el-modelo-y-sus-diferencias-entre-lenguajes) ·
[02](#02--algoritmos-de-cadenas) · [03](#03--expresiones-regulares) ·
[04 — transversales](#04--simulación-preguntas-transversales) ·
[04 — pizarra](#04--simulación-problemas-de-pizarra)

---

# 01 — Strings: el modelo y sus diferencias entre lenguajes

**01 → 1. ¿Por qué el `String` de Java es inmutable? Da al menos tres razones.**

⏱️ Seguridad, hash cacheado, compartir sin copiar y concurrencia sin sincronización.
🗣️ Una ruta o una cadena de conexión no puede cambiar entre que se valida y que se usa. El
`hashCode` se calcula una vez y se guarda dentro del objeto, lo que hace baratísimo usar
strings como claves de mapa. Y dos referencias al mismo literal pueden compartir objeto sin
riesgo, que es lo que permite el *string pool*.
🔬 El precio es que cada modificación copia: por eso concatenar en bucle es O(n²) y por eso
existe `StringBuilder`. Nombrar el precio junto con las ventajas es lo que completa la
respuesta.

**01 → 2. ¿Qué complejidad tiene concatenar con `+=` dentro de un bucle de n iteraciones?**

⏱️ O(n²) en tiempo, y genera n objetos intermedios.
🗣️ Cada `+=` crea un string nuevo del tamaño de la suma y copia lo anterior. Si las n
iteraciones añaden un carácter cada una, el total copiado es 1+2+3+…+n, que es n²/2.
🔬 En Java el compilador convierte cada `+=` en un `StringBuilder` nuevo **dentro** de la
vuelta del bucle, así que la optimización que aplica a una expresión suelta no ayuda aquí. La
solución es un único `StringBuilder` fuera del bucle.

**01 → 3. ¿Cuál es la diferencia entre un grafema, un code point y una unidad de código?**

⏱️ El grafema es lo que el usuario llama "un carácter"; el code point es un valor Unicode; la
unidad de código es lo que ocupa en memoria según la codificación.
🗣️ Un emoji de familia es **un grafema**, varios **code points** unidos por caracteres de ancho
cero, y ocho **unidades** UTF-16. La `é` puede ser un code point precompuesto o dos: `e` más
acento combinante.
🔬 Ninguno de los cinco lenguajes indexa por grafema. Para eso hacen falta `ICU` en Java, el
paquete `grapheme` en Go o `Intl.Segmenter` en navegadores modernos.

**01 → 4. ¿Qué devuelve `"👍".length()` en Java y por qué?**

⏱️ 2, porque `length()` cuenta unidades UTF-16 y ese emoji está fuera del plano básico.
🗣️ Los caracteres con code point mayor que U+FFFF se representan con una **pareja sustituta**:
dos unidades de 16 bits. `length()` las cuenta por separado; `codePointCount()` da 1.
🔬 La consecuencia peligrosa es que `substring` puede partir la pareja y dejar media, que se
muestra como un rombo negro y rompe la serialización aguas abajo. En JavaScript ocurre
exactamente lo mismo.

**01 → 5. ¿Qué cuenta `len(s)` en Go?**

⏱️ Bytes, no caracteres. `len("é")` es 2 y `len("👍")` es 4.
🗣️ El string de Go es una secuencia inmutable de bytes en UTF-8. Es coherente con su filosofía:
el string son datos y la interpretación es explícita. Para contar caracteres se usa
`utf8.RuneCountInString`.
🔬 El recorrido idiomático sí es por carácter: `for i, r := range s` entrega runes, o sea code
points, junto con su posición en bytes. Indexar con `s[i]` da un byte y a mitad de un carácter
multibyte devuelve basura.

**01 → 6. ¿Qué hace `StringBuilder` para evitar el coste cuadrático?**

⏱️ Mantiene un búfer mutable que duplica su capacidad al llenarse, y copia una sola vez al
final.
🗣️ Cada `append` escribe en el búfer existente: O(1) amortizado, el mismo análisis del
`ArrayList`. La única copia completa ocurre en `toString()`. Pasa de O(n²) a O(n) y de n
objetos a uno.
🔬 Si conoces el tamaño final, `new StringBuilder(capacidad)` elimina también los
redimensionados. `StringBuffer` es la versión sincronizada y no se usa: la sincronización solo
cuesta.

**01 → 7. ¿Por qué `==` entre strings funciona en test y falla en producción en Java?**

⏱️ Porque `==` compara referencias, y en test los strings suelen ser literales que comparten
objeto en el pool.
🗣️ `"hola" == "hola"` es `true` porque el compilador interna los literales. Pero un string que
viene de la red, de un `ResultSet` o de un `StringBuilder` es un objeto distinto, aunque su
contenido sea idéntico, y `==` da `false`.
🔬 La corrección es `equals`, o `Objects.equals` si puede haber nulos. Y el
`hashCode` cacheado hace que `equals` sea barato en la práctica: las implementaciones salen
rápido por longitud distinta y las colecciones comparan hash antes de contenido.

**01 → 8. ¿Qué es el *string pool* y qué problema resuelve?**

⏱️ Una caché de literales: todos los `"hola"` del programa apuntan al mismo objeto.
🗣️ Resuelve el desperdicio de memoria de tener miles de copias del mismo texto, que es
frecuentísimo en aplicaciones reales con constantes, claves y nombres de columna. Solo es
seguro porque el string es inmutable.
🔬 `intern()` permite meter en el pool un string construido en ejecución. Se usa muy poco y mal:
en aplicaciones con muchos strings distintos llena el pool y cambia un problema de memoria por
otro. Desde Java 7 el pool vive en el heap, no en PermGen, así que al menos ya no provoca el
`OutOfMemoryError` clásico.

**01 → 9. ¿Por qué `"José"` puede no ser igual a `"José"` aunque se vean idénticos?**

⏱️ Porque uno puede tener la `é` precompuesta (U+00E9) y el otro `e` más acento combinante
(U+0065 U+0301).
🗣️ Son dos secuencias de code points distintas que se renderizan igual, así que `equals` dice
`false` y el usuario no entiende por qué. Es la causa habitual de registros duplicados con el
mismo nombre visible.
🔬 macOS entrega los nombres de archivo en NFD y Linux en NFC, lo que convierte esto en un bug
real al mover archivos entre plataformas. La corrección es normalizar con
`Normalizer.normalize(texto, Form.NFC)` **al entrar el dato**.

**01 → 10. ¿Qué diferencia hay entre NFC y NFD, y cuál usarías para almacenar?**

⏱️ NFC compone los caracteres; NFD los descompone. Para almacenar, NFC.
🗣️ NFC es más compacta y es lo que espera casi todo el ecosistema web. NFD es útil para
procesar: si descompones y filtras los caracteres combinantes, quitas los acentos, que es la
forma limpia de hacer búsquedas insensibles a tildes.
🔬 Existen además NFKC y NFKD, que son "compatibles": convierten `①` en `1` y las ligaduras en
sus letras. Son útiles para buscar y peligrosas para almacenar, porque pierden información que
no se puede recuperar.

**01 → 11. ¿Por qué `substring` dejó de ser O(1) en Java 7?**

⏱️ Porque compartía el arreglo de caracteres del original y eso mantenía vivos documentos
enteros.
🗣️ Un `substring` de 10 caracteres sobre un texto de 10 MB devolvía una vista con desplazamiento
y longitud, así que el arreglo de 10 MB no se podía liberar mientras la vista existiera. Era
una fuga de memoria silenciosa y frecuente en parsers.
🔬 Desde Java 7 copia, y por tanto es O(n). Es el ejemplo canónico de que una optimización de
tiempo puede ser una fuga de memoria, y sigue apareciendo en entrevistas precisamente por eso.

**01 → 12. ¿Qué es una pareja sustituta y qué operación la rompe?**

⏱️ Dos unidades UTF-16 que juntas representan un code point fuera del plano básico. La rompe
cualquier corte por índice de unidad.
🗣️ `substring`, `charAt` y el corte por longitud parten la pareja si el índice cae en medio. El
resultado es media pareja, que no es un carácter válido y se muestra como un rombo negro.
🔬 Las formas seguras en Java son `codePointCount()` para contar, `offsetByCodePoints()` para
calcular índices y `codePoints()` para recorrer. En JavaScript, `for...of` y el operador de
propagación recorren por code point; `for (let i = 0; ...)` no.

**01 → 13. ¿Qué indexa Python cuando haces `s[3]`, y en qué se diferencia de Java?**

⏱️ Python indexa por **code point**; Java, por unidad UTF-16.
🗣️ `len("👍")` es 1 en Python y 2 en Java. Python 3 usa una representación interna de ancho
variable —1, 2 o 4 bytes por carácter según el máximo que haya en la cadena— precisamente para
poder ofrecer indexación por code point en O(1).
🔬 Sigue sin ser indexación por grafema: la familia de emojis con caracteres de unión sigue
contando varios. Ningún lenguaje de los cinco resuelve ese nivel sin biblioteca.

**01 → 14. ¿Qué entrega `for i, r := range s` en Go y en qué se diferencia de `s[i]`?**

⏱️ El `range` entrega runes —code points— con su posición en bytes; `s[i]` entrega un byte
suelto.
🗣️ Por eso `i` no avanza de uno en uno cuando hay caracteres multibyte: salta tantos bytes como
ocupe cada rune. Es la forma idiomática y correcta de recorrer texto en Go.
🔬 Indexar directamente solo es correcto si sabes que el contenido es ASCII. Con texto de
usuario, `s[i]` puede devolver el byte intermedio de una secuencia UTF-8, que no significa
nada por sí solo.

**01 → 15. ¿Por qué `StringBuffer` no se usa aunque exista?**

⏱️ Porque es la versión sincronizada de `StringBuilder`, y la sincronización casi nunca sirve
de nada aquí.
🗣️ Un constructor de cadenas es casi siempre una variable local de un método: no se comparte
entre hilos, así que bloquear en cada `append` es coste puro. `StringBuilder` apareció en Java
5 exactamente para dar la versión sin sincronizar.
🔬 Y aunque se compartiera, la sincronización por método no garantiza que la secuencia de
operaciones sea atómica: dos hilos que hacen `append` dos veces cada uno pueden intercalarse.
Es un ejemplo clásico de sincronización que da falsa sensación de seguridad.

**01 → 16. ¿Qué son las *compact strings* de Java 9 y qué cambiaron?**

⏱️ Una representación interna que usa un byte por carácter cuando todo el texto cabe en
latin-1, en vez de dos.
🗣️ Internamente el `String` pasó de `char[]` a `byte[]` más un indicador de codificación. En
aplicaciones típicas, donde la gran mayoría del texto es ASCII, ahorró memoria de forma
notable sin cambiar la API ni la semántica de `length()`.
🔬 Es un buen ejemplo de optimización invisible: ningún código tuvo que cambiar. Y también de
que `length()` sigue contando unidades UTF-16 **conceptualmente**, aunque por dentro estén
guardadas como bytes.

**01 → 17. ¿Por qué ordenar strings con el orden natural produce listas que el usuario ve desordenadas?**

⏱️ Porque el orden natural es por valor de code point, que no es el orden alfabético de ningún
idioma.
🗣️ Todas las mayúsculas ASCII van antes que todas las minúsculas, y los acentos van después de
todo el ASCII. Así que `"Zoe"` aparece antes que `"ángel"` y `"ñu"` al final de la lista, que
es exactamente lo que un usuario hispanohablante percibe como error.
🔬 La solución es un colador sensible a la configuración regional: `Collator.getInstance(new
Locale("es"))` en Java, `Intl.Collator` en JavaScript, `locale.strxfrm` en Python. Y si hay que
ordenar en base de datos, la colación de la columna es la que manda, no el código.

**01 → 18. En Java, `a + b + c` en una sola línea, ¿es un problema de rendimiento? Justifica.**

⏱️ No: el compilador ya lo convierte en un solo `StringBuilder` con tres `append`.
🗣️ La optimización existe desde hace décadas, y desde Java 9 se hace con `invokedynamic`, que
permite al runtime elegir la estrategia. Reescribirlo a mano no mejora nada y solo lo afea.
🔬 El problema es **exclusivamente el bucle**: ahí el compilador crea un `StringBuilder` nuevo en
cada vuelta, porque no puede saber que la variable acumulada no se usa entre iteraciones.
Distinguir los dos casos es lo que separa a quien lo entendió de quien memorizó "no concatenes
con +".

**01 → 19. Te piden truncar un nombre a 20 caracteres. ¿Qué preguntas antes de escribir el código?**

⏱️ Qué es un carácter aquí —unidad, code point o grafema—, qué se hace si se corta a la mitad,
y si hay que añadir puntos suspensivos.
🗣️ El límite casi siempre viene de una columna de base de datos, y ahí el límite real puede ser
en **bytes** —`VARCHAR(20)` en una base con UTF-8 puede ser 20 bytes o 20 caracteres según el
motor—. Preguntar eso evita que el `insert` falle con nombres acentuados que sí pasaban la
validación.
🔬 El corte correcto en Java usa `offsetByCodePoints` para no partir parejas sustitutas, y
`BreakIterator` si hay que respetar grafemas. Y si el texto se va a mostrar, cortar por palabra
en vez de por carácter suele ser lo que el negocio quería de verdad.

**01 → 20. ¿Por qué concatenar con `+=` en un bucle en Python "parece" funcionar bien y aun así no se escribe?**

⏱️ Porque CPython tiene una optimización que reescribe en sitio cuando el string no tiene otras
referencias, y esa optimización no está garantizada.
🗣️ Si el contador de referencias del string acumulado es 1, CPython puede redimensionar el búfer
en vez de copiar, lo que hace el bucle lineal. Basta con que alguien guarde una referencia
intermedia, o con cambiar a PyPy o a otra implementación, para que vuelva a ser cuadrático.
🔬 El idioma correcto es `"".join(lista)`, que además es más rápido incluso cuando la
optimización aplica, porque calcula el tamaño total de una vez. Depender de un detalle de
implementación no documentado es exactamente el tipo de decisión que un entrevistador quiere
oírte rechazar.

**01 → 21. ¿Por qué ninguno de los cinco lenguajes indexa por grafema, y qué haces si lo necesitas?**

⏱️ Porque segmentar grafemas exige las tablas de Unicode y reglas que cambian con cada versión:
no cabe en una operación O(1).
🗣️ Un grafema puede ser una secuencia arbitrariamente larga de code points unidos por
caracteres de ancho cero, selectores de variación y modificadores. Indexar por grafema sería
O(n) y dependería de la versión de Unicode con la que se compiló.
🔬 Las herramientas: `BreakIterator.getCharacterInstance()` en Java, `Intl.Segmenter` en
JavaScript moderno, el módulo `regex` o `grapheme` en Python, y paquetes externos en Go. Se
usan cuando el requisito es de presentación —límites de caracteres visibles, cursores de
edición—, no cuando es de almacenamiento.

**01 → 22. ¿Dónde normalizas el texto de un usuario: al entrar, al comparar o al guardar? Justifica.**

⏱️ Al entrar, en la frontera del sistema, y una sola vez.
🗣️ Normalizar al comparar significa hacerlo en cada comparación, que es O(n) cada vez y se
olvida en algún sitio. Normalizar al guardar deja pasar datos sin normalizar a la lógica de
negocio, y los duplicados se crean antes de llegar a la base. En la frontera se hace una vez y
todo lo de dentro puede asumir la forma canónica.
🔬 Es el mismo principio que la validación y que la capa anticorrupción: **convertir en el
borde para que el interior tenga un solo modelo**. Y hay que declararlo en el contrato: si el
sistema guarda NFC, un cliente que compare contra NFD obtendrá resultados distintos, y eso es
parte de la API aunque nadie lo escriba.

**01 → 23. Un usuario aparece dos veces en la tabla con el mismo nombre visible. Da tres hipótesis en orden de probabilidad.**

⏱️ Normalización Unicode distinta; espacios invisibles al principio o al final; y caracteres
homoglifos de alfabetos distintos.
🗣️ La primera es la más probable: uno se registró desde macOS (NFD) y otro desde un formulario
web (NFC). La segunda se detecta con un `trim` y mirando la longitud. La tercera es la
`а` cirílica que se ve igual que la `a` latina, y aparece tanto por copiar y pegar como por
fraude deliberado.
🔬 Cómo se confirma cada una sin adivinar: volcar los code points de ambos valores con
`text.codePoints().forEach(...)` o con `hex(ord(c))` en Python. Es un diagnóstico de dos
minutos que resuelve la discusión. La corrección de fondo es normalizar en la frontera y añadir
una restricción de unicidad sobre el valor normalizado, no sobre el original.

**01 → 24. Diseña la validación de un campo "nombre, máximo 30 caracteres" que funcione con acentos, emojis y texto en árabe. Di qué cuentas y dónde cortas.**

⏱️ Normalizo a NFC al entrar, cuento **grafemas** para el límite visible, y valido además el
tamaño en bytes que acepta la columna.
🗣️ Son dos límites distintos y hay que respetar los dos: el que el usuario percibe —30
caracteres visibles— y el físico de almacenamiento. Contar unidades UTF-16 falla con emojis;
contar code points falla con grafemas compuestos; contar bytes falla como límite de
presentación.

```text
1. normalizar a NFC en la frontera
2. rechazar caracteres de control y de ancho cero no permitidos
3. contar grafemas con BreakIterator para el límite de 30
4. comprobar que la codificación UTF-8 cabe en la columna
5. si hay que truncar, truncar por grafema, nunca por índice
```

🔬 Lo que preguntarán después: qué hacer con el texto de derecha a izquierda. El árabe se
almacena en orden lógico y se muestra en orden visual, así que **no hay que hacer nada
especial al guardar** — y sí hay que tener cuidado con las marcas de dirección (U+202E), que
pueden usarse para disfrazar texto y son un vector de ataque conocido en nombres de archivo.
Rechazarlas en el paso 2 es la decisión correcta.

**01 → 25. Un informe que concatena 100 000 líneas tarda tres minutos. Explica la causa, da la solución y estima la mejora.**

⏱️ Concatenación cuadrática por inmutabilidad. Con `StringBuilder` baja a lineal: de minutos a
milisegundos.
🗣️ Con 100 000 líneas de unos 80 caracteres, el string final son 8 MB. Concatenando, el total
copiado es la suma de todos los tamaños intermedios: del orden de 400 GB de movimiento de
memoria, más 100 000 objetos para el recolector. Con un solo `StringBuilder`, se copian 8 MB
una vez.

```java
StringBuilder sb = new StringBuilder(10_000_000);   // capacidad estimada: evita rehashes
for (LineaPedido linea : lineas) sb.append(format(linea)).append('\n');
```

🔬 Dos matices que suben la nota. Primero: si el informe se escribe a un archivo o a una
respuesta HTTP, **lo correcto no es construir el string en memoria** sino escribir a un
`Writer` con búfer, que usa memoria constante en vez de 8 MB. Segundo: si el perfilador dice
que el tiempo está en `String.format` y no en la concatenación, la causa es otra —`format`
parsea el patrón en cada llamada— y la solución es `StringBuilder.append` directo o un patrón
precompilado. Medir antes de arreglar aplica también aquí.

---

# 02 — Algoritmos de cadenas

**02 → 1. ¿Cuál es la complejidad de la búsqueda ingenua en el peor caso y en el medio?**

⏱️ O(n·m) en el peor caso, O(n) en el caso medio con texto natural.
🗣️ El peor caso exige que el patrón coincida casi entero antes de fallar en cada posición, lo
que requiere mucha repetición. En texto natural el primer carácter falla casi siempre, así que
el bucle interno apenas avanza.
🔬 Por eso `String.indexOf` es ingenuo y está bien: con alfabetos de decenas de símbolos, el
peor caso no aparece. Aparece con ADN (cuatro letras), con cadenas binarias y con logs muy
repetitivos.

**02 → 2. ¿Qué algoritmo usa `String.indexOf` de Java?**

⏱️ Búsqueda ingenua, con una optimización que busca primero el carácter inicial del patrón.
🗣️ No es KMP ni Boyer-Moore. La decisión es deliberada: el caso medio es lineal, el código es
simple y no hay preproceso que amortizar para una sola búsqueda.
🔬 Ningún lenguaje de los cinco expone KMP en su stdlib. Go es el más sofisticado: usa
Rabin-Karp para patrones largos y la ingenua para cortos, y lo documenta en su código fuente.

**02 → 3. ¿Qué complejidad garantiza KMP?**

⏱️ O(n + m) en tiempo, garantizado, y O(m) en espacio.
🗣️ El "garantizado" es lo importante: no hay peor caso que lo degrade, a diferencia de la
ingenua y de Rabin-Karp. El puntero del texto nunca retrocede.
🔬 Esa propiedad de no retroceder es lo que lo hace apto para **flujos**: puedes buscar sobre un
stream que no permite volver atrás, cosa que Boyer-Moore no puede hacer porque salta y compara
hacia la izquierda.

**02 → 4. ¿Qué operación hace O(1) el hash rodante de Rabin-Karp?**

⏱️ Calcular el hash de la ventana siguiente a partir del de la actual.
🗣️ Con un hash polinómico, quitar el carácter que sale y añadir el que entra es aritmética:
restar su contribución, multiplicar por la base y sumar el nuevo. Sin eso, cada ventana costaría
O(m) y el algoritmo sería O(n·m).
🔬 Es la misma idea de la ventana deslizante de `01-fundamentos/03`: no recalcules, actualiza.
Y aparece también en `rsync`, que usa un hash rodante para detectar qué bloques de un archivo
cambiaron sin transmitirlo entero.

**02 → 5. ¿Qué complejidad tiene buscar una palabra en un trie?**

⏱️ O(longitud de la palabra), **independientemente de cuántas palabras haya almacenadas**.
🗣️ Bajas un nivel por letra. Con un millón de palabras o con diez, buscar "abracadabra" cuesta
once pasos. Esa independencia del tamaño del diccionario es su propiedad característica.
🔬 Lo que cuesta es la memoria: un nodo por prefijo distinto, y cada nodo con un arreglo o mapa
de hijos. Un trie de un diccionario grande ocupa bastante más que el `HashSet` equivalente.

**02 → 6. ¿Qué responde la tabla de prefijos de KMP en cada posición?**

⏱️ Cuál es el prefijo más largo de lo que llevas coincidido que es también sufijo de lo que
llevas coincidido.
🗣️ Sirve para saber, cuando fallas, cuánto del patrón puedes seguir dando por válido sin volver
a mirar el texto. Si la tabla dice 1, ya tienes un carácter bueno y continúas desde el índice 1
del patrón.
🔬 Se construye en O(m) comparando el patrón consigo mismo con la misma mecánica de dos punteros
que usa la búsqueda. Es la parte que cuesta entender y la que te van a pedir si nombras KMP.

**02 → 7. ¿Por qué KMP nunca retrocede sobre el texto?**

⏱️ Porque la tabla de prefijos ya contiene toda la información que necesita: qué parte del
patrón sigue siendo válida.
🗣️ Cuando falla, lo que retrocede es el puntero del **patrón**, no el del texto. Como el texto
solo avanza, el número total de comparaciones está acotado por 2n.
🔬 Esa es justamente la propiedad que lo hace usable sobre un flujo. Y es lo que lo distingue de
Boyer-Moore, que necesita acceso aleatorio al texto porque compara de derecha a izquierda.

**02 → 8. ¿Por qué Rabin-Karp tiene que verificar carácter a carácter aunque el hash coincida?**

⏱️ Porque dos cadenas distintas pueden tener el mismo hash: una colisión.
🗣️ El hash reduce m caracteres a un número acotado, así que por el principio del palomar hay
colisiones necesariamente. La verificación es O(m), y es lo que mantiene el peor caso en O(n·m)
aunque el caso esperado sea O(n + m).
🔬 Con un módulo primo grande las colisiones son raras. Con un módulo mal elegido y conocido, un
adversario puede fabricar entradas que colisionen siempre y degradar el algoritmo a propósito;
es el mismo tipo de ataque que las colisiones de hash contra un `HashMap`.

**02 → 9. ¿En qué se diferencian KMP y Boyer-Moore en una frase?**

⏱️ KMP nunca retrocede sobre el texto; Boyer-Moore **se salta** trozos del texto sin mirarlos.
🗣️ KMP garantiza O(n + m) mirando todos los caracteres una vez. Boyer-Moore puede ser
sublineal, O(n/m), porque cuando el carácter que falla no está en el patrón salta el patrón
entero. A cambio necesita acceso aleatorio al texto.
🔬 Por eso `grep` usa Boyer-Moore sobre archivos y KMP es la opción cuando el texto llega como
un flujo que no se puede rebobinar.

**02 → 10. ¿Por qué Boyer-Moore puede ser sublineal?**

⏱️ Porque compara de derecha a izquierda y, al fallar con un carácter que no está en el patrón,
salta m posiciones de golpe.
🗣️ Si el patrón tiene 20 caracteres y el carácter del texto en la posición 20 no aparece en el
patrón, ninguna alineación que lo incluya puede funcionar: se puede avanzar 20 posiciones sin
mirar nada por el camino. Cuanto más largo el patrón, mayores los saltos.
🔬 De ahí que sea contraintuitivo: buscar una frase larga es **más rápido** que buscar una
palabra corta. Es exactamente lo contrario de lo que espera la intuición, y es una buena
respuesta para "¿algo que te sorprendiera al aprenderlo?".

**02 → 11. ¿Qué complejidad tiene la distancia de edición y cómo se reduce su espacio?**

⏱️ O(n·m) en tiempo y espacio; el espacio baja a O(mín(n, m)) guardando solo dos filas.
🗣️ Cada celda de la matriz depende únicamente de la fila anterior y de la celda izquierda, así
que no hace falta mantener la matriz entera: basta la fila previa y la actual.
🔬 El precio de esa reducción es que **pierdes la capacidad de reconstruir las operaciones**:
para saber qué se insertó, borró y sustituyó hay que recorrer la matriz hacia atrás, y para eso
tiene que existir. Si solo necesitas el número, dos filas; si necesitas el alineamiento, la
matriz completa.

**02 → 12. Construye la tabla de prefijos de KMP para el patrón `"abra"` y explica cada valor.**

⏱️ `[0, 0, 0, 1]`.
🗣️ Posición por posición: para `"a"` no hay prefijo propio, 0. Para `"ab"`, ni `"a"` es sufijo ni
nada coincide, 0. Para `"abr"`, igual, 0. Para `"abra"`, el prefijo `"a"` **es** también sufijo:
1.

```text
patrón:   a  b  r  a
índice:   0  1  2  3
tabla:    0  0  0  1
```

🔬 Ese 1 es lo que hace útil la tabla en `"abracadabra"`: tras coincidir `"abra"` en la posición
0 y seguir buscando, el motor no vuelve al principio del patrón sino al índice 1, porque la `a`
final de la coincidencia anterior puede ser la `a` inicial de la siguiente. Un patrón sin
autosimilitud —`"abcd"`— tiene tabla `[0,0,0,0]` y KMP no aporta nada sobre la ingenua, que es
una observación que vale la pena hacer en voz alta.

**02 → 13. ¿Por qué la búsqueda ingenua basta en texto natural y falla con ADN?**

⏱️ Porque el peor caso necesita mucha repetición, y un alfabeto de cuatro letras la garantiza.
🗣️ Con un alfabeto grande, la probabilidad de que el primer carácter del patrón coincida es
baja, así que el bucle interno casi nunca avanza y el coste real es O(n). Con cuatro letras,
esa probabilidad es 1/4 y las coincidencias parciales largas son habituales.
🔬 El mismo razonamiento aplica a datos binarios, a secuencias de eventos con pocos tipos y a
logs muy formateados. Es el criterio para justificar KMP sin sonar a sobreingeniería: **no es
el tamaño del texto, es el tamaño del alfabeto**.

**02 → 14. ¿Cuál es la ventaja real de Rabin-Karp, si para un solo patrón KMP es mejor?**

⏱️ Buscar **muchos patrones a la vez**: metes todos sus hashes en un conjunto y recorres el
texto una sola vez.
🗣️ Con k patrones de la misma longitud, el coste es O(n + k·m) en vez de O(k·n). Y sirve para
detectar duplicados o plagio: comparar huellas de bloques de dos documentos es mucho más barato
que compararlos carácter a carácter.
🔬 Si los patrones tienen longitudes distintas, Rabin-Karp se complica y la respuesta correcta
pasa a ser **Aho-Corasick**: un trie de todos los patrones con enlaces de fallo, que encuentra
todas las ocurrencias de todos ellos en O(n + total de patrones + ocurrencias).

**02 → 15. ¿Cuándo un `TreeMap` sustituye a un trie, y cuándo no?**

⏱️ Lo sustituye para consultas de prefijo sobre conjuntos moderados; no lo sustituye cuando hay
millones de términos o hace falta Aho-Corasick.
🗣️ `mapa.subMap(prefijo, prefijo + '￿')` devuelve exactamente las claves que empiezan por
ese prefijo, en O(log n) más el tamaño del resultado. Para unos miles o decenas de miles de
términos es indistinguible de un trie y no exige escribir ni una clase.
🔬 El trie gana cuando el número de términos crece mucho —su coste es independiente de él— y
cuando necesitas más que el rango: contar términos por prefijo, sugerir con tolerancia a
errores, o buscar muchos patrones a la vez con enlaces de fallo. Empezar por el `TreeMap` y
justificar el salto es la respuesta con criterio.

**02 → 16. ¿Por qué ningún lenguaje de los cinco trae KMP en su biblioteca estándar?**

⏱️ Porque en el caso real —texto natural, una búsqueda— la ingenua es igual de buena y mucho más
simple.
🗣️ Las bibliotecas estándar optimizan para el caso común, y el caso común de "busca esta palabra
en este texto" no tiene el patrón de repetición que hace falta para que KMP gane. Go llega a
usar Rabin-Karp para patrones largos, que es donde sí hay diferencia medible.
🔬 Lo que dice eso es útil en una entrevista: **el algoritmo teóricamente mejor no siempre es la
elección de ingeniería correcta**. Si lo necesitas, lo escribes, y esa necesidad es la que hay
que poder justificar con el alfabeto o con la garantía de peor caso.

**02 → 17. Detectar si dos palabras son anagramas: da dos soluciones con distinta complejidad.**

⏱️ Ordenar ambas y comparar, O(n log n); o contar frecuencias, O(n).
🗣️ Ordenar es más corto de escribir: `Arrays.sort(a.toCharArray())` en ambas y comparar. Contar
frecuencias en un arreglo de 26 posiciones —o en un mapa si el alfabeto es grande— recorre cada
palabra una vez y es lineal.

```java
int[] cuenta = new int[26];
for (char c : primera.toCharArray()) cuenta[c - 'a']++;
for (char c : segunda.toCharArray()) if (--cuenta[c - 'a'] < 0) return false;
return primera.length() == segunda.length();
```

🔬 El detalle: con **Unicode** el arreglo de 26 no vale, y hay que usar un `Map<Integer,
Integer>` sobre code points, más normalización previa. Y si hay que agrupar muchas palabras por
anagrama, la versión ordenada tiene una ventaja: la palabra ordenada sirve directamente como
clave del mapa de grupos.

**02 → 18. ¿Cómo comprobarías si una cadena es palíndromo ignorando acentos y mayúsculas? ¿Qué capítulo anterior tienes que aplicar?**

⏱️ Normalizar primero —capítulo [`01`](01-strings-entre-lenguajes.md)— y después dos punteros
desde los extremos.
🗣️ El orden importa: se normaliza a NFD, se filtran los caracteres combinantes para quitar
acentos, se pasa a minúsculas y se descartan los no alfanuméricos. Solo entonces se aplican los
dos punteros, que es O(n) y O(1) de espacio.
🔬 Los casos borde: la `ñ` no es una `n` con acento en español —quitarle la tilde cambia la
palabra—, así que "ignorar acentos" es una decisión de negocio que hay que confirmar. Y
`toLowerCase()` depende del locale: en turco, la `I` mayúscula no baja a `i`, y es el bug de
internacionalización más famoso que existe.

**02 → 19. Te piden "¿quisiste decir…?" sobre un diccionario de 300 000 palabras. ¿Por qué no sirve calcular la distancia de edición contra todas?**

⏱️ Porque son 300 000 matrices de O(n·m): decenas de millones de operaciones por cada pulsación
de teclado.
🗣️ Con palabras de 10 letras, cada comparación son 100 celdas: 30 millones de celdas por
consulta. Para una caja de búsqueda que responde mientras el usuario escribe, es dos órdenes de
magnitud demasiado.
🔬 Las salidas reales: un **trie con poda**, calculando la fila de la matriz según se baja y
abandonando la rama cuando el mínimo de la fila supera el umbral —esto reduce el trabajo
drásticamente porque comparte el prefijo entre miles de palabras—; un **BK-tree**, que aprovecha
la desigualdad triangular de la distancia; o el enfoque de Peter Norvig, que genera todas las
variantes a distancia 1 y 2 de la palabra escrita y comprueba cuáles están en el diccionario.
Este último es el más fácil de explicar y el que se suele esperar.

**02 → 20. ¿Por qué reducir el espacio de la distancia de edición a dos filas impide reconstruir las operaciones?**

⏱️ Porque reconstruir exige recorrer la matriz hacia atrás, y con dos filas ya has descartado el
camino.
🗣️ El número final vive en la última celda, pero **qué** operaciones lo produjeron se averigua
siguiendo de dónde vino cada mínimo, celda a celda, hasta el origen. Eso requiere la matriz
completa.
🔬 Existe una solución intermedia, el algoritmo de Hirschberg, que reconstruye el alineamiento en
O(mín(n, m)) de espacio aplicando divide y vencerás sobre la matriz, a costa de duplicar el
tiempo. Es el mismo compromiso que aparece en muchas optimizaciones de DP: espacio contra la
capacidad de explicar el resultado.

**02 → 21. ¿Qué pasa si eliges mal el módulo en Rabin-Karp y alguien lo sabe?**

⏱️ Puede fabricar entradas que colisionen siempre y degradar el algoritmo a O(n·m).
🗣️ Cada colisión fuerza una verificación completa de O(m). Con todas las ventanas colisionando,
el algoritmo hace exactamente el trabajo de la ingenua más el coste del hash. Es un ataque de
denegación de servicio.
🔬 Las defensas son las mismas que contra las colisiones de hash en general: módulo primo
grande, base elegida **aleatoriamente en cada ejecución** para que el atacante no pueda
precalcular, o doble hash con dos módulos distintos. Es el mismo razonamiento que llevó a
aleatorizar el hash de los strings en varios lenguajes.

**02 → 22. Explica el precálculo de Boyer-Moore y por qué el tamaño del alfabeto aparece en su complejidad de espacio.**

⏱️ Se construye una tabla que dice, para **cada carácter posible**, cuánto saltar si el fallo
ocurre con ese carácter. De ahí el alfabeto en el espacio.
🗣️ La heurística del carácter malo necesita consultar en O(1) "¿dónde aparece este carácter en
el patrón?". La forma directa es un arreglo indexado por el valor del carácter, que ocupa tanto
como el alfabeto: 256 para bytes, 65 536 para UTF-16.
🔬 Por eso las implementaciones reales sobre Unicode usan un mapa disperso en vez de un arreglo:
el alfabeto teórico es demasiado grande para reservarlo entero. Y la segunda heurística, la del
sufijo bueno, necesita O(m) más y es la que garantiza el caso peor lineal; muchas
implementaciones la omiten (Boyer-Moore-Horspool) porque en la práctica casi nunca hace falta.

**02 → 23. Diseña el autocompletado de un buscador de productos con 2 millones de términos y respuesta en menos de 50 ms. Elige estructura y justifica el coste.**

⏱️ Un trie en memoria con los k mejores resultados precalculados en cada nodo.
🗣️ El trie da el prefijo en O(longitud escrita). Lo que decide el tiempo de respuesta no es
encontrar el nodo, es **ordenar los candidatos**: si un prefijo corto tiene 200 000
descendientes, recogerlos y ordenarlos por popularidad no cabe en 50 ms. La solución es guardar
en cada nodo los 10 mejores ya calculados, actualizados en un proceso por lotes.

```text
nodo "ca" → top10 precalculado: [camisa, cable, cafetera, ...]
consulta "ca" → devolver el top10 del nodo. O(longitud), sin ordenar nada
```

🔬 Lo que preguntarán después: memoria y actualización. Dos millones de términos en un trie con
top-10 por nodo son varios GB en Java por la sobrecarga de objetos, lo que lleva a un trie
compacto (radix tree) o directamente a Elasticsearch con un campo `completion`, que hace
exactamente esto con un autómata de estados finitos. Y la alternativa honesta que hay que
nombrar: si el requisito real fueran 50 000 términos, un `TreeMap` con `subMap` resolvería lo
mismo en veinte líneas y sin infraestructura.

**02 → 24. Te dan un proceso que busca 5 000 palabras prohibidas en cada mensaje de un chat con 10 000 mensajes por segundo. Diseña la solución.**

⏱️ Aho-Corasick: un trie de las 5 000 palabras con enlaces de fallo, que recorre cada mensaje
una sola vez.
🗣️ La solución ingenua —5 000 llamadas a `contains` por mensaje— son 50 millones de búsquedas
por segundo y no aguanta. Aho-Corasick construye el autómata **una vez** al arrancar y después
procesa cada mensaje en O(longitud del mensaje + ocurrencias), independientemente de cuántas
palabras haya en el diccionario.
🔬 Los detalles que suben la nota: el autómata es inmutable y se puede compartir entre hilos sin
sincronizar; hay que normalizar el mensaje antes (acentos, mayúsculas, caracteres homoglifos)
o el filtro se evade trivialmente; y la evasión con separadores —`p.a.l.a.b.r.a`— no la
resuelve ningún algoritmo de cadenas, sino la normalización previa. Si la lista cambia con
frecuencia, se reconstruye el autómata en segundo plano y se intercambia la referencia.

**02 → 25. Implementa la búsqueda de `"abra"` en `"abracadabra"` con KMP y traza el valor de los dos punteros en cada paso.**

⏱️ Dos ocurrencias, en 0 y en 7, con el puntero del texto avanzando siempre.
🗣️ Con la tabla `[0, 0, 0, 1]`, el puntero `j` del patrón retrocede según la tabla y el puntero
`i` del texto solo avanza.

```text
tabla: [0, 0, 0, 1]

i=0 a  j=0→1     i=6 d  j=1→0 (tabla[0]=0), 'd'≠'a', i avanza
i=1 b  j=1→2     i=7 a  j=0→1
i=2 r  j=2→3     i=8 b  j=1→2
i=3 a  j=3→4  ✓ ocurrencia en 0; j←tabla[3]=1     i=9 r  j=2→3
i=4 c  'c'≠'b' (j=1) → j←tabla[0]=0, 'c'≠'a'      i=10 a j=3→4  ✓ ocurrencia en 7
i=5 a  j=0→1
```

🔬 El paso que demuestra que entendiste el algoritmo es el de `i=3`: tras encontrar la
ocurrencia, `j` **no vuelve a 0** sino a `tabla[3] = 1`, porque la `a` final de `"abra"` puede
ser la `a` inicial de la siguiente ocurrencia. Con un patrón sin autosimilitud, `j` volvería a
0 y KMP no aportaría nada sobre la ingenua. Y `i` nunca retrocede: recorre las once posiciones
una sola vez, que es la propiedad que da la garantía O(n + m).

---

# 03 — Expresiones regulares

**03 → 1. ¿Qué es un lenguaje regular y qué tipo de autómata lo reconoce?**

⏱️ El que reconoce un autómata finito: sin memoria más allá de su estado actual.
🗣️ "Sin memoria" es la clave: un autómata finito no puede contar cuántos paréntesis lleva
abiertos, porque eso exigiría infinitos estados. Por eso las estructuras anidadas quedan fuera.
🔬 Los motores modernos con retrorreferencias ya **no** reconocen solo lenguajes regulares:
`(.*)\1` describe algo que ningún autómata finito puede aceptar. Esa extensión es
precisamente lo que obliga al backtracking y lo que abre la puerta al ReDoS.

**03 → 2. ¿Qué diferencia hay entre `(...)` y `(?:...)`?**

⏱️ El primero captura el contenido; el segundo solo agrupa.
🗣️ Capturar cuesta memoria y numera el grupo, lo que desplaza los índices de los demás. Si solo
necesitas aplicar un cuantificador o una alternativa a un trozo, `(?:...)` es lo correcto.
🔬 Es la mejora más barata que se le puede hacer a una regex heredada: cambiar los grupos que
nadie lee por no capturantes reduce el trabajo del motor y aclara la intención. Los grupos con
nombre, `(?<monto>...)`, son mejores todavía cuando **sí** lees el contenido.

**03 → 3. ¿Qué captura `<.*>` sobre `<b>hola</b>` y por qué?**

⏱️ Captura `<b>hola</b>` entero, porque `*` es greedy.
🗣️ El `.*` consume hasta el final de la cadena y después retrocede hasta encontrar el último `>`
que permita completar la coincidencia. El resultado es la coincidencia más larga posible, no la
más corta.
🔬 Las dos salidas: `<.*?>` la hace lazy y captura `<b>`; `<[^>]*>` prohíbe el `>` dentro y es
**mejor**, porque no depende del retroceso y por tanto es más rápida y no puede degradarse.

**03 → 4. ¿Qué hace `\b` y qué problema evita?**

⏱️ Marca una frontera de palabra: la transición entre un carácter de palabra y uno que no lo es.
🗣️ `\bcaja\b` encuentra "caja" pero no "cajamarca" ni "encajar". Sin él, media docena de casos
borde hay que resolverlos a mano con clases de caracteres y alternativas.
🔬 Su definición depende de qué cuenta como carácter de palabra, y por defecto `\w` es solo
ASCII en varios motores: `\bmañana\b` puede comportarse de forma inesperada con la `ñ`. En Java
se corrige con la bandera `UNICODE_CHARACTER_CLASS`.

**03 → 5. ¿Qué operación de una expresión regular es la cara: compilar o coincidir?**

⏱️ Compilar. Coincidir suele ser lineal; compilar construye el autómata o el árbol del patrón.
🗣️ Por eso `Pattern.compile` va en una constante `static final` y no dentro del método. Usar
`String.matches()` en un bucle recompila la expresión en cada vuelta, y es una de las mejoras de
rendimiento más grandes que se consiguen con un cambio de dos líneas.
🔬 El matiz: con backtracking, coincidir **puede** ser exponencial, y entonces el coste de
compilar es irrelevante. Las dos afirmaciones conviven: compilar es lo caro en el caso normal,
coincidir es lo catastrófico en el caso malo.

**03 → 6. ¿Qué significa que un cuantificador sea posesivo?**

⏱️ Que coge todo lo que puede y **no retrocede nunca**, aunque eso haga fallar la coincidencia.
🗣️ `a*+` consume todas las aes y no devuelve ninguna. Si el resto del patrón necesitaba una, la
coincidencia falla en vez de reintentar. Eso acota el trabajo y es la defensa estructural contra
el ReDoS.
🔬 Java y PCRE los tienen; **JavaScript y Python no**. En su lugar, en esos lenguajes se usan
grupos atómicos donde existan, o se reescribe el patrón para eliminar la ambigüedad, que es la
solución que siempre funciona.

**03 → 7. ¿Qué es ReDoS?**

⏱️ Un ataque de denegación de servicio que aprovecha el backtracking exponencial de una
expresión regular.
🗣️ Una entrada corta y cuidadosamente construida hace que el motor pruebe un número exponencial
de particiones antes de rendirse. No lanza excepción ni deja rastro en los logs: solo un hilo
consumiendo CPU al 100 %.
🔬 Está catalogado por OWASP. El patrón clásico es `(a+)+$`: cuantificadores anidados sobre lo
mismo, lo que hace que el texto pueda repartirse de 2ⁿ maneras entre las repeticiones.

**03 → 8. ¿En qué se diferencia un motor de backtracking de uno de autómata?**

⏱️ El de backtracking prueba un camino y se arrepiente; el de autómata simula todos los caminos
a la vez.
🗣️ El primero es más expresivo —permite retrorreferencias y lookbehind variable— y tiene peor
caso exponencial. El segundo garantiza O(n·m) y no puede soportar retrorreferencias, porque en
su modelo son imposibles, no difíciles.
🔬 Java, Python, JavaScript, PCRE y .NET usan backtracking. Go (RE2), Rust y `grep` usan
autómata. Es una decisión de diseño explícita en cada caso, no una casualidad de
implementación.

**03 → 9. ¿Por qué Go no soporta retrorreferencias?**

⏱️ Porque usa un autómata, y una retrorreferencia no es expresable en un autómata finito.
🗣️ `(.*)\1` exige recordar una cantidad arbitraria de texto para compararla después, y un
autómata finito no tiene memoria. No es que RE2 no lo haya implementado: es que el modelo lo
excluye.
🔬 La contrapartida es la garantía lineal, que a Google le importaba más porque RE2 se creó para
ejecutar expresiones **escritas por usuarios** sobre sus sistemas. Cuando el patrón lo define un
tercero, no poder degradarse vale más que poder expresarlo todo.

**03 → 10. ¿Qué cambian las banderas `MULTILINE` y `DOTALL`?**

⏱️ `MULTILINE` hace que `^` y `$` anclen cada línea en vez de la cadena; `DOTALL` hace que `.`
incluya el salto de línea.
🗣️ Por defecto son lo contrario: `^` y `$` anclan la cadena completa y `.` no cruza líneas.
Confundirlas es una fuente habitual de validaciones que se saltan metiendo un `\n` en el campo.
🔬 La defensa correcta para validar una entrada completa **no** es `^...$` sino `\A...\z`, que
anclan el principio y el final absolutos de la cadena independientemente de las banderas. En
Java, `matches()` ya exige coincidencia total, que es otra forma de evitar el problema.

**03 → 11. ¿Por qué `<[^>]*>` suele ser mejor que `<.*?>`?**

⏱️ Porque no depende del retroceso: es determinista y más rápida.
🗣️ El lazy consume un carácter, prueba, y si falla consume otro: el motor va y vuelve. La clase
negada le dice directamente qué puede consumir, así que avanza sin arrepentirse nunca.
🔬 Es el principio general de la optimización de expresiones regulares: **prefiere describir qué
no puede aparecer a dirigir el retroceso**. Es también la técnica que elimina la mayoría de las
ambigüedades que causan ReDoS.

**03 → 12. ¿Por qué `String.matches()` dentro de un bucle es un problema de rendimiento?**

⏱️ Porque compila la expresión en cada llamada, y compilar es lo caro.
🗣️ `"texto".matches(patron)` equivale a `Pattern.compile(patron).matcher("texto").matches()`.
Dentro de un bucle de un millón de iteraciones, eso es un millón de compilaciones.
🔬 La corrección es un `private static final Pattern` y reutilizarlo. `Pattern` es inmutable y
seguro entre hilos; `Matcher` **no lo es**, así que se crea uno por uso —o por hilo— con
`patron.matcher(texto)`.

**03 → 13. ¿Qué lenguajes de los cinco tienen cuantificadores posesivos?**

⏱️ Java sí; Python, JavaScript y TypeScript no; Go no los necesita.
🗣️ Java los heredó de PCRE. En Python y JavaScript hay que eliminar la ambigüedad reescribiendo
el patrón, porque no hay forma de prohibir el retroceso sintácticamente. Go no los tiene porque
su motor no retrocede en absoluto.
🔬 Python 3.11 añadió cuantificadores posesivos y grupos atómicos, así que la respuesta completa
incluye la versión: es un ejemplo de por qué conviene decir "desde qué versión" en las
respuestas sobre lenguajes.

**03 → 14. ¿Por qué `(a+)+$` es exponencial y `a+$` es lineal, si reconocen lo mismo?**

⏱️ Por la ambigüedad: el primero puede repartir el mismo texto de 2ⁿ maneras entre las
repeticiones, y las prueba todas antes de fallar.
🗣️ Treinta aes pueden agruparse como una de 30, dos de 15, tres de 10, quince de 2… Cada reparto
es un camino distinto que el motor explora. Con la coincidencia fallando al final por un
carácter extra, ninguno funciona y los prueba todos.
🔬 `a+$` no tiene ambigüedad: solo hay una forma de que las aes coincidan. La regla general es
que **dos cuantificadores anidados sobre el mismo conjunto de caracteres** son la señal de
alarma, igual que las alternativas que pueden coincidir con lo mismo, como `(a|aa)+`.

**03 → 15. Da tres formas distintas de defenderte de un ReDoS, ordenadas por lo que cuestan.**

⏱️ Acotar la longitud de la entrada; reescribir el patrón para quitar la ambigüedad; y ejecutar
la coincidencia con límite de tiempo.
🗣️ La primera es una línea de código y corta el problema de raíz, porque el coste exponencial
depende de la longitud: con un máximo de 100 caracteres, incluso el peor patrón termina. La
segunda es la corrección de fondo. La tercera es la red de seguridad para patrones que no
controlas.
🔬 Una cuarta, estructural: si los patrones los define el usuario —reglas de un WAF, filtros
configurables—, usar un motor de autómata como RE2 en vez de intentar validar cada patrón. Y
existen analizadores estáticos que detectan patrones vulnerables en CI, que es donde conviene
que salte la alarma.

**03 → 16. ¿Por qué no se puede validar HTML con una expresión regular?**

⏱️ Porque HTML admite anidamiento arbitrario y eso no es un lenguaje regular.
🗣️ Comprobar que las etiquetas están balanceadas requiere contar cuántas hay abiertas, y un
autómata finito no puede contar sin límite. Cualquier regex que lo intente funciona hasta cierta
profundidad y falla después, silenciosamente.
🔬 La respuesta completa nombra la alternativa: un parser —Jsoup en Java, `html.parser` en
Python— y, para el caso real de sanitizar entrada, una biblioteca de sanitización, nunca una
regex propia. Las regex de sanitización son un vector conocido de XSS por las variantes que no
cubren.

**03 → 17. ¿Es `Pattern` seguro entre hilos? ¿Y `Matcher`?**

⏱️ `Pattern` sí, `Matcher` no.
🗣️ `Pattern` es inmutable: se compila una vez y se comparte. `Matcher` guarda el estado de la
coincidencia en curso —posición, grupos capturados— y compartirlo entre hilos produce resultados
corruptos sin lanzar ninguna excepción.
🔬 El patrón correcto es `Pattern` en `static final` y `pattern.matcher(texto)` local en cada
llamada. Es un error frecuente en código heredado: alguien "optimizó" guardando también el
`Matcher` como campo, y el bug aparece solo bajo concurrencia.

**03 → 18. ¿Qué señales te hacen sospechar que una expresión heredada es vulnerable?**

⏱️ Cuantificadores anidados, alternativas que pueden coincidir con lo mismo, y `.*` en medio del
patrón.
🗣️ `(x+)+`, `(x*)*`, `(a|aa)+` y `(\w+\s?)*` son las formas clásicas. La pregunta que lo
confirma es: *"¿puede este texto analizarse de más de una manera?"*. Si la respuesta es sí, hay
retroceso posible.
🔬 La comprobación empírica es barata: probar el patrón con una cadena de 20, 25 y 30 caracteres
que **casi** coincide, y medir. Si el tiempo se duplica con cada carácter añadido, es
exponencial y ya lo has demostrado. Es mejor evidencia que cualquier argumento teórico.

**03 → 19. Te piden validar direcciones de correo electrónico. ¿Qué respondes?**

⏱️ Que una regex sencilla más un envío de verificación, y que la regex "completa" es un error.
🗣️ La gramática oficial del RFC 5322 permite comentarios anidados, comillas y caracteres que
nadie espera; la expresión que la implementa tiene miles de caracteres y aun así rechaza
direcciones válidas. Y validar la sintaxis no dice nada sobre si el buzón existe.
🔬 Lo razonable: comprobar que hay una arroba con algo a cada lado y un punto en el dominio,
acotar la longitud, y **verificar enviando un correo con un enlace**. Es la única validación que
responde a la pregunta que de verdad importa. Decir eso convierte una pregunta de sintaxis en
una de diseño, que es exactamente lo que se está evaluando.

**03 → 20. ¿Qué pierde Go al elegir RE2, y por qué lo considera un buen negocio?**

⏱️ Pierde retrorreferencias y lookahead; gana que ninguna expresión pueda tumbar el proceso.
🗣️ RE2 nació en Google para ejecutar expresiones escritas por usuarios sobre sus sistemas de
búsqueda de código. En ese contexto, un patrón malicioso o simplemente torpe no puede tener
consecuencias, así que la garantía lineal vale más que la expresividad.
🔬 Es el mismo tipo de decisión que aleatorizar el recorrido de los mapas: **preferir que lo
inseguro sea imposible antes que documentar que no se haga**. Y la contrapartida se puede
sortear: lo que necesitaba lookahead casi siempre se resuelve con dos pasadas o con código
normal.

**03 → 21. ¿Qué aportan los *template literal types* de TypeScript y qué no pueden hacer?**

⏱️ Validan formatos simples en **tiempo de compilación**; no validan nada en runtime.
🗣️ `` type Correo = `${string}@${string}` `` hace que el compilador rechace una constante mal
formada. Sirve para identificadores tipados, rutas y claves de configuración conocidas en
compilación.
🔬 Lo que no pueden: validar datos que llegan de la red, de un formulario o de un archivo,
porque los tipos de TypeScript se borran al compilar. Para eso hace falta una validación en
runtime, y ahí sí entran las expresiones regulares o una biblioteca de esquemas. Comprobado con
`tsc --strict`:

```text
const bueno: Correo = "oskar@ejemplo.com"   → compila
const malo:  Correo = "oskar-ejemplo.com"   → error TS2322: Type '"oskar-ejemplo.com"'
                                               is not assignable to type '`${string}@${string}`'
```

El matiz que cierra la respuesta: eso solo funciona con **literales conocidos en compilación**. Un
`string` que venga de un formulario es de tipo `string`, no de tipo `Correo`, y el compilador no
puede decir nada sobre su contenido — que es exactamente la frontera entre los dos mundos.

**03 → 22. ¿Por qué `String.split(",")` en Java no es tan caro como parece, y `split("\\s+")` sí?**

⏱️ Porque `split` tiene un atajo para un solo carácter literal que evita compilar la regex.
🗣️ La implementación detecta que el argumento es un carácter sin significado especial y hace un
recorrido directo. Con `"\\s+"` no puede: compila el patrón en cada llamada.
🔬 La consecuencia práctica: separar por coma en un bucle está bien; separar por espacios o por
cualquier patrón real exige `Pattern.compile` en una constante y `pattern.split(texto)`. Es una
optimización invisible de la JDK que conviene conocer porque cambia la respuesta a "¿está mal
usar split en un bucle?".

**03 → 23. Una validación en producción deja una CPU al 100 % con una petición de 40 caracteres. Explica el mecanismo, identifica el patrón culpable y da la corrección.**

⏱️ Es ReDoS: backtracking catastrófico en un patrón con cuantificadores anidados.
🗣️ El mecanismo: la entrada casi coincide pero falla al final, y el motor prueba todas las
formas de repartir el texto entre las repeticiones anidadas antes de concluir que no hay
coincidencia. Con 40 caracteres son del orden de 2⁴⁰ caminos.

```text
síntoma:   un hilo al 100 %, sin excepción y sin log
confirmar: reproducir con 20, 25 y 30 caracteres → el tiempo se duplica por carácter
culpable:  el patrón con (x+)+, (x*)* o (a|aa)+ aplicado a entrada de usuario
```

🔬 La corrección tiene tres niveles y conviene aplicar los tres: **inmediato**, acotar la
longitud de la entrada antes de la validación —una línea, despliegue de urgencia—;
**estructural**, reescribir el patrón para eliminar la ambigüedad o usar cuantificadores
posesivos; **preventivo**, un analizador de patrones vulnerables en CI y una revisión de todas
las regex que tocan entrada de usuario. Y en el post mortem: el volcado de hilos durante el
incidente habría mostrado el `Matcher` en la cima de la pila, que es la forma de diagnosticarlo
en caliente.

**03 → 24. Te dan `^(\w+\s?)*$` para validar nombres. Explica si es segura y corrígela si no lo es.**

⏱️ No es segura: `(\w+\s?)*` tiene cuantificadores anidados y `\s?` opcional, que multiplica los
repartos posibles.
🗣️ Con una entrada de palabras seguidas de un carácter no válido al final —`"aaaa aaaa aaaa!"`—
el motor prueba todas las formas de agrupar las letras y los espacios opcionales. Es un ReDoS
de manual, y aparece tal cual en aplicaciones reales.

```text
vulnerable:  ^(\w+\s?)*$
corregida:   ^\w+(\s\w+)*$        ← sin ambigüedad: palabra, y grupos de espacio+palabra
```

🔬 La corrección funciona porque **cada carácter solo puede pertenecer a una parte del patrón**:
el espacio va siempre dentro del grupo repetido y nunca es opcional dentro de él. Además, para
un campo de nombre real hay que ir más allá de `\w`, que en Java es ASCII por defecto y rechaza
`José`: hay que usar `\p{L}` con `UNICODE_CHARACTER_CLASS`, permitir apóstrofo y guion, y acotar
la longitud. Es el enunciado del problema de pizarra P2.

**03 → 25. Diseña la validación de un identificador de producto con formato `AAA-9999-XX`, en Java y en Go, y explica qué cambia entre ambas.**

⏱️ El patrón es el mismo y no tiene ambigüedad; lo que cambia es dónde se compila y qué garantía
tienes.
🗣️ El patrón `^[A-Z]{3}-\d{4}-[A-Z]{2}$` es de longitud fija y sin cuantificadores anidados, así
que es lineal en cualquier motor. No hay riesgo de ReDoS aquí, y decirlo es parte de la
respuesta.

```java
// Java: constante, compilada una vez, segura entre hilos
private static final Pattern ID_PRODUCTO = Pattern.compile("^[A-Z]{3}-\\d{4}-[A-Z]{2}$");
boolean valido = ID_PRODUCTO.matcher(entrada).matches();
```

```go
// Go: MustCompile en una variable de paquete, con RE2 detrás
var idProducto = regexp.MustCompile(`^[A-Z]{3}-\d{4}-[A-Z]{2}$`)
valido := idProducto.MatchString(entrada)
```

🔬 Las diferencias que hay que nombrar: en Java el `Matcher` **no** es seguro entre hilos y hay
que crearlo por uso, mientras que en Go el `*Regexp` sí lo es por completo y se puede usar
concurrentemente sin más. En Go la comilla invertida evita escapar las barras, que es la fuente
número uno de errores al copiar patrones entre lenguajes. Y `MustCompile` falla al arrancar si
el patrón está mal, lo que convierte un error de runtime en un error de despliegue — que es
justo lo que quieres. Para un formato tan simple, además, cabe la respuesta sin regex:
comprobar longitud y rangos de caracteres es más rápido y igual de legible, y en un camino
caliente sería la elección correcta.

---

# 04 — Simulación: preguntas transversales

Las `S#` que ya están cubiertas por una pregunta de capítulo no se repiten: se remite.

**04 → S1. ¿Por qué el string es inmutable en los cinco lenguajes? Da tres razones distintas.**

Cubierta por **01 → 1**.

**04 → S2. "¿Cuántos caracteres tiene esta cadena?" ¿Qué preguntas antes de contestar?**

⏱️ Si cuentas unidades de código, code points o grafemas.
🗣️ Son tres respuestas distintas para la misma cadena y las tres son correctas según para qué.
Si el número va a una validación de columna, hay una cuarta: bytes. Preguntarlo no es
pedantería: es la diferencia entre un truncado correcto y uno que corrompe el texto.
🔬 La respuesta por defecto de cada lenguaje: Java y JavaScript cuentan unidades UTF-16, Python
code points, Go bytes. Ninguno cuenta grafemas.

**04 → S3. ¿Qué devuelve contar `"👍"` en cada uno de los cinco lenguajes?**

⏱️ Java 2, Python 1, JavaScript 2, TypeScript 2, Go 4.
🗣️ Java y JavaScript cuentan las dos unidades UTF-16 de la pareja sustituta. Python cuenta el
único code point. Go cuenta los cuatro bytes de la codificación UTF-8.
🔬 Y en los cinco, para el usuario es **un** carácter. Ese desajuste es el origen de los bugs de
truncado y de los contadores de caracteres que no coinciden con lo que el usuario ve escrito.

**04 → S4. ¿Por qué una comparación de strings puede funcionar en test y fallar con datos reales? Da dos causas independientes.**

⏱️ `==` en vez de `equals` en Java, y normalización Unicode distinta.
🗣️ La primera funciona en test porque los literales comparten objeto en el pool y falla con
datos que vienen de la red o de la base. La segunda falla con cualquier texto acentuado que
llegue por dos caminos distintos, y es independiente del lenguaje.
🔬 Hay una tercera menos obvia: espacios invisibles al principio o al final, que sobreviven al
`trim` si son espacios sin separación (U+00A0) en vez de espacios normales. Las tres se
diagnostican igual: volcando los code points de ambos valores.

**04 → S5. ¿Dónde normalizas Unicode: al entrar, al comparar o al guardar? Justifica.**

Cubierta por **01 → 22**.

**04 → S6. Te piden truncar un campo a 30 caracteres. Enumera todo lo que preguntas antes.**

Cubierta por **01 → 19** y **01 → 24**.

**04 → S7. ¿Qué complejidad tiene concatenar en un bucle y por qué?**

Cubierta por **01 → 2**.

**04 → S8. ¿Por qué `a + b + c` en una línea no es un problema y en un bucle sí?**

Cubierta por **01 → 18**.

**04 → S9. ¿Qué operación de una expresión regular hay que sacar del bucle, y por qué?**

Cubierta por **03 → 5** y **03 → 12**.

**04 → S10. Un informe que arma 200 000 líneas tarda cuatro minutos. Da tu diagnóstico y tu solución.**

Cubierta por **01 → 25**, con el mismo razonamiento y el doble de líneas.

**04 → S11. ¿Por qué `substring` dejó de ser O(1) en Java 7, y qué enseña ese cambio?**

Cubierta por **01 → 11**.

**04 → S12. ¿Qué haces si el perfilador dice que el 40 % del tiempo está en `String.format`?**

⏱️ Sustituirlo por `StringBuilder.append` en el camino caliente, o sacar el patrón a una
constante.
🗣️ `String.format` parsea el patrón en cada llamada y usa reflexión sobre los argumentos. En un
bucle de millones de iteraciones eso domina el tiempo. Para formatear un número con dos
decimales o concatenar tres valores, `append` es un orden de magnitud más rápido.
🔬 El matiz: `String.format` es perfectamente adecuado fuera del camino caliente, y cambiarlo
por todas partes empeora la legibilidad sin ganar nada. Lo mismo aplica a los logs: el problema
casi nunca es el formateo, es formatear un mensaje de `DEBUG` que después se descarta — y eso se
arregla con el logging parametrizado, no cambiando de API.

**04 → S13. ¿Qué algoritmo usa `indexOf` y por qué es una decisión razonable?**

Cubierta por **02 → 2** y **02 → 16**.

**04 → S14. ¿Qué garantiza KMP que no garantiza la búsqueda ingenua?**

Cubierta por **02 → 3**.

**04 → S15. ¿En qué se diferencian KMP y Boyer-Moore, en una frase?**

Cubierta por **02 → 9**.

**04 → S16. ¿Cuál es la ventaja real de Rabin-Karp?**

Cubierta por **02 → 14**.

**04 → S17. ¿Cuándo un trie se justifica y cuándo es sobreingeniería?**

Cubierta por **02 → 15**.

**04 → S18. Te piden buscar 5 000 términos prohibidos en cada mensaje entrante. Elige el enfoque.**

Cubierta por **02 → 24**.

**04 → S19. ¿Por qué ningún lenguaje de los cinco trae KMP en su stdlib? ¿Qué te dice eso?**

Cubierta por **02 → 16**.

**04 → S20. ¿Qué es un lenguaje regular y qué no lo es? Da dos ejemplos de cada uno.**

⏱️ Regular: un identificador `AAA-9999`, una dirección IPv4. No regular: HTML anidado,
paréntesis balanceados.
🗣️ El criterio es si hace falta **contar sin límite**. Un formato de longitud acotada o con
repetición simple lo reconoce un autómata finito; comprobar que cada apertura tiene su cierre
exige memoria proporcional a la profundidad, y eso ya es una pila, no un autómata.
🔬 El detalle honesto: los motores modernos con retrorreferencias reconocen algo más que
lenguajes regulares, así que técnicamente "expresión regular" ya no es un nombre exacto. Eso es
justo lo que obliga al backtracking.

**04 → S21. ¿Por qué `(a+)+$` es peligroso?**

Cubierta por **03 → 14**.

**04 → S22. ¿Cómo defiendes un endpoint que aplica una regex a entrada de usuario?**

Cubierta por **03 → 15**.

**04 → S23. ¿Por qué Go no puede sufrir ReDoS y qué perdió a cambio?**

Cubierta por **03 → 9** y **03 → 20**.

**04 → S24. Te piden validar correos electrónicos con una expresión regular. Responde.**

Cubierta por **03 → 19**.

**04 → S25. ¿Qué señales te hacen abrir una revisión de código sobre una regex heredada?**

Cubierta por **03 → 18**.

**04 → S26. ¿Qué hace `len(s)` en Go y por qué es coherente con el diseño del lenguaje?**

Cubierta por **01 → 5**.

**04 → S27. ¿Qué aporta TypeScript en este bloque, y dónde no aporta nada?**

⏱️ Aporta los tipos de plantilla literal para validar formatos en compilación; no aporta nada en
el modelo de string ni en el motor de regex, que son los de JavaScript.
🗣️ Donde sí cambia la respuesta: un identificador tipado como `` `${Lowercase<string>}-${number}` ``
hace que el compilador rechace una constante mal formada, sin ejecutar nada. Donde no: contar
caracteres, construir texto, buscar patrones — todo eso es JavaScript en runtime.
🔬 Declarar que un lenguaje no aporta en un punto concreto es más honesto que rellenar la fila
de la tabla, y es una regla explícita de la guía de estilo de este corpus. En una entrevista,
decir "aquí TypeScript no cambia nada porque los tipos se borran" demuestra que entiendes su
modelo de ejecución.

**04 → S28. ¿Por qué `"".join(lista)` es el idioma de Python y no `+=`?**

Cubierta por **01 → 20**.

**04 → S29. Compara cómo resuelven los cinco lenguajes la construcción de texto en bucle.**

⏱️ Java `StringBuilder`, Python `"".join`, JavaScript `array.join("")`, TypeScript igual que
JavaScript, Go `strings.Builder`.
🗣️ Todos resuelven lo mismo: un búfer que crece amortizado en vez de copiar en cada paso. Las
diferencias son de garantía. Java y Go lo hacen explícito y siempre lineal. Python y JavaScript
tienen optimizaciones que **a veces** salvan el `+=`, y depender de ellas es frágil.
🔬 El caso más engañoso es JavaScript: los motores usan *ropes* —árboles de concatenación que
aplanan perezosamente— así que el `+=` en bucle puede ser lineal. No está especificado, varía
entre motores y entre versiones, y por eso el idioma sigue siendo acumular en un arreglo y unir
al final.

**04 → S30. "Las expresiones regulares son ilegibles, no las uso nunca." Responde a un compañero que dice esto.**

⏱️ Tiene media razón: el problema no es la herramienta, es usarla sin acotar y sin comentar.
🗣️ Una regex de veinte caracteres para validar un formato fijo es más clara que treinta líneas
de comprobaciones a mano. Una de doscientos caracteres para parsear un log es ilegible y
probablemente incorrecta, y ahí él tiene razón. La línea está en si se puede explicar carácter
a carácter.
🔬 Lo que sí se puede conceder sin ceder el argumento: el modo extendido con comentarios
(`Pattern.COMMENTS` en Java, `re.VERBOSE` en Python) permite escribir el patrón en varias líneas
con explicaciones, y los grupos con nombre hacen legible la extracción. Con eso, una regex
compleja deja de ser un jeroglífico. Y la parte donde conviene darle la razón del todo: para
estructuras anidadas, un parser, siempre.

**04 → S31. Un cliente aparece duplicado en la base con el mismo nombre visible. Da tu investigación completa.**

Cubierta por **01 → 23**.

**04 → S32. ¿Cuándo has tenido un bug de codificación de caracteres y cómo lo encontraste?**

⏱️ Es una pregunta de experiencia: responde con el síntoma, el diagnóstico y la corrección de
fondo.
🗣️ La estructura creíble tiene cuatro partes: el síntoma —caracteres raros en un informe, un
`insert` que falla, un duplicado que no debería existir—; cómo lo acotaste, que casi siempre es
volcar los bytes o los code points en el punto exacto donde se rompe; dónde estaba la frontera
sin declarar, que suele ser una lectura de archivo sin `Charset` explícito o una cabecera HTTP
sin `charset`; y qué cambiaste para que no vuelva.
🔬 Lo que se está evaluando es si sabes que **una codificación no se adivina, se declara**.
`new String(bytes)` y `new FileReader(archivo)` en Java usan la codificación por defecto de la
plataforma, que cambia entre tu portátil y el servidor: ese es el bug clásico y decirlo por su
nombre vale más que la anécdota.

---

# 04 — Simulación: problemas de pizarra

**04 → P1. Contar palabras de un archivo de 2 GB.**

**La decisión que fuerza.** Hay tres formas de separar palabras y cuestan muy distinto:

```text
regex "\\W+"          → compila una vez, pero pasa por el motor en cada línea
String.split(" ")     → atajo de un carácter literal, rápido, pero no maneja puntuación
recorrido manual      → el más rápido, el más código
```

**Solución.** Streaming línea a línea, `StringTokenizer` o un recorrido manual, y un `HashMap`
de frecuencias:

```java
Map<String, Integer> frecuencias = new HashMap<>();
try (BufferedReader lector = Files.newBufferedReader(ruta, StandardCharsets.UTF_8)) {
    String linea;
    while ((linea = lector.readLine()) != null) {
        for (String palabra : PATRON.split(linea)) {          // PATRON: constante compilada
            if (!palabra.isEmpty()) frecuencias.merge(palabra.toLowerCase(), 1, Integer::sum);
        }
    }
}
```

**Complejidad.** O(n) en el tamaño del archivo. La memoria **no** es O(n): es O(palabras
distintas), que para texto natural crece muy despacio (ley de Heaps) y cabe de sobra.

**Lo que hay que decir en voz alta.** Que el archivo no se lee entero: `Files.readAllLines`
sobre 2 GB es un `OutOfMemoryError` inmediato, y `Files.lines` con un `Stream` es la versión
perezosa correcta. Que la codificación se declara explícitamente, porque la de la plataforma
cambia entre entornos. Y que `merge` evita el `get`/`put` con comprobación de nulo.

**La repregunta: "¿y las 10 más frecuentes?"** No se ordena el mapa entero —sería O(k log k)
sobre cientos de miles de palabras—: se recorre una vez con un **min-heap acotado a 10**, que
es O(k log 10). Es exactamente el patrón del top-K, y está en
[`04-arboles-grafos/02`](../04-arboles-grafos/02-monticulos-y-colas-de-prioridad.md). Y si el
archivo fuera de 2 TB en vez de 2 GB, la respuesta cambiaría de estructura a arquitectura:
particionar por hash de la palabra y agregar por partes, que es literalmente MapReduce.

**04 → P2. El validador de nombres.**

**Lo que se pregunta antes de escribir.** Qué cuenta como "carácter" para el límite de 50; si el
límite es de presentación o de columna; qué alfabetos hay que aceptar; y si el campo se va a
usar para buscar o comparar, porque entonces hace falta normalizar.

**Solución.**

```java
private static final Pattern NOMBRE =
    Pattern.compile("^[\\p{L}\\p{M}]+(?:[ '\\-][\\p{L}\\p{M}]+)*$", Pattern.UNICODE_CHARACTER_CLASS);

boolean valido(String entrada) {
    if (entrada == null) return false;
    String normalizado = Normalizer.normalize(entrada.trim(), Normalizer.Form.NFC);
    if (normalizado.codePointCount(0, normalizado.length()) > 50) return false;  // cota ANTES
    return NOMBRE.matcher(normalizado).matches();
}
```

- `\p{L}` es "cualquier letra de cualquier alfabeto" y `\p{M}` son las marcas combinantes:
  juntos aceptan `José`, `Müller`, árabe y japonés. `\w` no sirve: en Java es ASCII por defecto.
- El patrón exige **letra al principio y al final de cada palabra**, y permite espacio,
  apóstrofo o guion **solo entre palabras**. Eso acepta `O'Connor` y `Müller-Schmidt` y rechaza
  `--` o `  `.
- No hay cuantificadores anidados sobre el mismo conjunto: `[\p{L}\p{M}]+` y `(?:...)*` operan
  sobre conjuntos disjuntos, así que no hay ambigüedad y no hay retroceso exponencial.

**La repregunta: "¿es segura frente a una entrada hostil?"** Sí, por dos motivos que hay que
nombrar por separado: el patrón no es ambiguo, y además **la longitud se acota antes de
aplicarlo**, lo que hace que el peor caso esté acotado pase lo que pase. Ese orden —cortar
primero, validar después— es la parte de la respuesta que casi nadie da.

**Casos borde.** Nulo y cadena vacía; solo espacios; nombre de una sola letra, que es legítimo;
espacios sin separación (U+00A0) que sobreviven al `trim` estándar; y marcas de dirección
(U+202E), que hay que rechazar explícitamente porque permiten disfrazar texto.

**04 → P3. Anagramas agrupados.**

**Solución A: ordenar la palabra como clave.** O(n · m log m) siendo n las palabras y m su
longitud.

```java
Map<String, List<String>> grupos = new HashMap<>();
for (String palabra : palabras) {
    char[] letras = palabra.toCharArray();
    Arrays.sort(letras);                                  // "cosa" y "caso" → "acos"
    grupos.computeIfAbsent(new String(letras), k -> new ArrayList<>()).add(palabra);
}
```

**Solución B: la firma de frecuencias como clave.** O(n · m), sustituyendo la ordenación por un
conteo: `"a1c1o1s1"` o un arreglo de 26 convertido a string.

**Cuál elijo.** La A, salvo que las palabras sean largas. Con palabras de longitud típica —menos
de 15 letras— el `log m` es 4 y la constante de ordenar un arreglo diminuto es menor que la de
construir la firma. La B gana cuando `m` crece, y es la respuesta correcta si el entrevistador
insiste en "mejor que n·m log m".

**La repregunta: "¿y si tienen acentos?"** Cambia el problema. Hay que decidir si `"caso"` y
`"cáso"` son anagramas, que es una pregunta de negocio. Si la respuesta es sí, se normaliza a
NFD y se filtran las marcas combinantes antes de generar la clave. Y el arreglo de 26 deja de
servir en cualquier caso: hay que contar sobre code points con un mapa.

**Casos borde.** Lista vacía; palabras repetidas, que caen en el mismo grupo y hay que decidir
si se deduplican; y mayúsculas, que exigen decidir si `"Roca"` y `"arco"` son anagramas.

**04 → P4. El log que hay que parsear.**

**La decisión.** El formato es fijo y posicional, así que hay tres candidatos:

```text
regex con grupos con nombre   → legible, ~2-5 µs por línea
split por espacios            → rápido, frágil ante campos con espacios
indexOf + substring           → el más rápido, el más código, el más frágil
```

**Solución que usaría en producción.** Filtro barato primero, regex después:

```java
private static final Pattern EVENTO = Pattern.compile(
    "PedidoConfirmado id=(?<id>\\d+) monto=(?<monto>\\d+\\.\\d{2})");

if (!linea.contains("PedidoConfirmado")) continue;   // descarta el 95 % sin tocar el motor
Matcher m = EVENTO.matcher(linea);
if (m.find()) { procesar(m.group("id"), m.group("monto")); }
```

- El `contains` previo es la clave del rendimiento: es una búsqueda de subcadena literal y
  descarta la inmensa mayoría de las líneas sin invocar el motor de expresiones regulares.
- Los grupos con nombre hacen el código legible sin comentarios, y sobreviven a que alguien
  añada un grupo en medio.
- El patrón no tiene ambigüedad: `\d+` y `\d+\.\d{2}` operan sobre conjuntos disjuntos del
  texto que los rodea. No hay riesgo de ReDoS, y el log no es entrada de usuario directa de
  todas formas.

**La repregunta: "¿cuánto tarda y dónde está el tiempo?"** Con 50 GB y líneas de 100 bytes son
unos 500 millones de líneas. **El tiempo está en la E/S, no en el parseo**: leer 50 GB de disco
son minutos, y el `contains` sobre cada línea son nanosegundos. Optimizar la regex antes de
haber medido la lectura es optimizar lo que no importa. Las mejoras que sí cambian el resultado
son leer con un búfer grande, evitar crear un `String` por línea si se puede trabajar sobre
bytes, y **paralelizar por bloques** del archivo, que es donde está el factor de diez.

**Casos borde.** Líneas truncadas al final del archivo o en una rotación; líneas de otro
formato mezcladas; el monto con separador de miles o con coma decimal según el locale que
generó el log; y la codificación del archivo, que hay que declarar y no adivinar.

---

**Vuelta a:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**README del bloque:** [`02-texto`](README.md)

---

**Anterior:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**Bloque:** [README](README.md)
