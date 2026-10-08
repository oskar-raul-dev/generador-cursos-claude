# 04 — CSV y los formatos tabulares

> El formato más simple del temario y el que más veces se implementa mal, porque **parece** que se
> resuelve con `split(",")`. Por qué no hay una norma que lo obligue, qué reglas de comillas hay que
> respetar, por qué los acentos y los ceros a la izquierda se pierden al abrirlo, y por qué una
> celda que empieza por `=` es un problema de seguridad.
>
> **Asume leído:** [`02-texto/01` — Strings entre lenguajes](../02-texto/01-strings-entre-lenguajes.md),
> del que hereda lo de codificación de caracteres.
>
> **Vigencia:** 2026-09-18. Todas las salidas de este capítulo están **ejecutadas**.

---

## 1. 🎯 El problema

Una línea de un fichero de pedidos, generada correctamente:

```text
PED-00042,"Muebles ""El Roble"", S.A.","Calle 5
Bogotá",007
```

Son **cuatro campos**: referencia, razón social, dirección y código de sucursal. Ahora, lo que
contesta cada forma de leerla, ejecutado:

```text
crudo.split(",")   →  5 campos, y el segundo es  '"Muebles ""El Roble""'
csv.reader         →  4 campos  ['PED-00042', 'Muebles "El Roble", S.A.', 'Calle 5\nBogotá', '007']
```

Tres trampas en una sola línea, y las tres son normales en datos reales:

- **Una coma dentro de un campo**, porque las razones sociales llevan coma.
- **Comillas dentro del campo**, que se escapan duplicándolas.
- **Un salto de línea dentro de un campo**, que hace que "una línea = un registro" sea falso — y con
  ello se cae también el `readLine()` del bucle.

Y el cuarto, que no se ve aquí: `007` es un **código**, no el número siete.

---

## 2. 🧱 Por qué no hay una norma de CSV

**Qué es.** Texto plano con un registro por línea y campos separados por un delimitador. Eso es todo,
y ahí empieza el problema: **no existe una norma que lo obligue.**

**Cómo va.** Lo más parecido es [RFC 4180](https://www.rfc-editor.org/rfc/rfc4180), y su categoría lo
dice todo: es **Informational**, no *Standards Track*. No obliga a nadie; **documenta** lo que hacía
la mayoría en 2005. Lo que fija:

```text
· campos separados por coma, registros separados por CRLF
· un campo puede ir entre comillas dobles
· si contiene coma, comillas o salto de línea, DEBE ir entre comillas
· una comilla dentro de un campo entrecomillado se escribe DOS veces
· cabecera opcional, declarada aparte
```

**Lo que ni RFC 4180 ni nadie fija**, y es donde se rompen las integraciones:

| Sin norma | Lo que ocurre en la práctica |
|---|---|
| El delimitador | Coma, punto y coma en Europa y Latinoamérica, tabulador, barra vertical |
| La codificación | Ninguna declarada; lo que suponga quien abra |
| El fin de línea | `CRLF` según el RFC, `LF` en la mitad de los generadores |
| Nulo frente a cadena vacía | **Indistinguibles**: `a,,b` no dice cuál de los dos es |
| Fechas y decimales | El separador decimal es coma en media Latinoamérica, y es el delimitador |

- **Ese último punto es el que arruina los ficheros europeos y latinoamericanos**: si el decimal se
  escribe `1.234,56`, la coma ya no puede ser el delimitador, y por eso Excel en español genera y
  espera **punto y coma**.
- **Nulo y vacío son el mismo texto.** Si el dominio los distingue —una fecha de baja ausente frente
  a una cadena vacía—, CSV no puede expresarlo y hay que acordar un centinela.

**Cuánto cuesta.** Es el formato más compacto y más rápido de los cuatro: sin etiquetas, sin llaves,
parseable en flujo con memoria constante. Para volumen tabular, gana.

**Cuándo sí.** Volcados, importaciones, intercambio con gente que abre archivos en una hoja de
cálculo, y cualquier cosa que tenga forma de tabla y muchas filas.

**Cuándo no.** Datos anidados —no los representa—, tipos que importen, y cualquier intercambio donde
no puedas acordar por escrito delimitador, codificación y comillas.

> **Veredicto:** CSV no es un formato, es una familia de formatos parecidos. Todo intercambio en CSV
> necesita un acuerdo escrito de cinco líneas, y quien no lo escribe lo descubre en producción.

---

## 3. 🧱 Las comillas, que son toda la complejidad

**Qué es.** La única regla que hay que interiorizar: **un campo va entre comillas si contiene el
delimitador, una comilla o un salto de línea**, y dentro las comillas se duplican.

**Cómo va.** El mismo contenido, generado y vuelto a leer, en Python y en Go:

```text
generado   PED-00042,"Muebles ""El Roble"", S.A.","Calle 5\nBogotá",007
Python     ['PED-00042', 'Muebles "El Roble", S.A.', 'Calle 5\nBogotá', '007']
Go         ["PED-00042" "Muebles \"El Roble\", S.A." "Calle 5\nBogotá" "007"]
```

Las dos bibliotecas coinciden campo por campo, incluido el salto de línea interno y el `007` como
texto. **Es el único punto del capítulo donde todos los lenguajes se comportan igual**, y es
precisamente el que la gente reimplementa a mano.

**Cuánto.** Un parser correcto es una máquina de estados de una pasada: `O(n)` en tiempo y `O(1)` en
memoria por registro. **No hay ninguna ganancia de rendimiento en usar `split`**: solo hay bugs.

**Cuándo sí** escribir el parser a mano: nunca, salvo como ejercicio. Está resuelto en todas partes.

**Cuándo no:** cuando el archivo viene de fuera. Ahí, biblioteca, y además con el delimitador y la
codificación declarados explícitamente.

> **Veredicto:** `split(",")` es correcto exactamente cuando tú generas el archivo y controlas los
> datos. En cuanto entra un nombre de empresa, deja de serlo.

---

## 4. 🧱 Codificación, BOM y la hoja de cálculo

**El problema.** CSV **no lleva su codificación dentro**. Un archivo UTF-8 correcto abierto con la
página de códigos local muestra los acentos rotos, y el archivo no tiene nada que decir al respecto.

Lo que hay que saber, en orden de frecuencia:

- **El BOM de UTF-8.** Tres octetos al principio (`EF BB BF`) que no son texto, sino una marca. Es lo
  que hace que Excel en Windows detecte UTF-8. Es específico de una herramienta, es feo, y es lo que
  funciona. El coste: un parser que no lo espere se encontrará el BOM **pegado al primer nombre de
  columna**, y el clásico `KeyError: 'id'` cuando la clave real es `'﻿id'`.
- **El delimitador por región.** Excel usa el separador de lista del sistema: coma en inglés, punto y
  coma en español. Por eso el mismo archivo se abre en columnas en una máquina y en una sola columna
  en otra.
- **La conversión automática de celdas.** Al abrir, la hoja de cálculo interpreta: `007` se vuelve
  `7`, `1-2` se vuelve una fecha, un identificador largo se pasa a notación científica y un número de
  teléfono pierde el `+`. **El archivo estaba bien; lo rompió el visor** — y el usuario que lo guarda
  después ya rompió el archivo de verdad.
- Si el destinatario siempre es una hoja de cálculo, **`.xlsx` elimina toda esta clase de problemas**
  porque lleva tipos y codificación dentro. Proponerlo es mejor respuesta que pelear con el BOM.

---

## 5. ⚠️ La celda que ejecuta: inyección de fórmulas

**Qué es.** Una hoja de cálculo trata como fórmula toda celda que empiece por `=`, `+`, `-` o `@`. Si
tu exportación incluye texto que escribió un usuario, ese usuario puede colocar una fórmula en el
archivo que abrirá otra persona.

```text
nombre,comentario
Ana,"=1+1"            ← al abrirlo no muestra el texto: muestra 2
```

- De ahí en adelante, el repertorio incluye funciones que leen otras celdas y las envían a una URL, o
  que invocan programas externos con la confirmación del usuario. **El vector no es tu aplicación:
  es el escritorio de quien abre el archivo**, y por eso se escapa de casi todas las revisiones.
- **La defensa es de una línea al exportar**: si el valor empieza por uno de esos cuatro caracteres,
  se antepone un apóstrofo o se entrecomilla forzando texto. Nunca se confía en que el usuario no
  escriba `=`.
- Se le llama *CSV injection* o *formula injection*, y OWASP la documenta como tal. Saber nombrarla
  vale en una entrevista de perfil senior: demuestra que piensas en el consumidor del dato, no solo
  en el productor.

> **Veredicto:** toda exportación a CSV que contenga texto de usuario se sanea en la escritura. Es el
> mismo principio de siempre —escapar en la frontera de salida— aplicado a un consumidor que no es un
> navegador.

---

## 6. 🧱 El mapa por lenguaje

| Lenguaje | En la biblioteca estándar | Nota |
|---|---|---|
| **Python** | `csv`, con `reader`, `DictReader` y dialectos | El más completo de los cinco; `Sniffer` adivina el delimitador |
| **Go** | `encoding/csv` | Sólido; `FieldsPerRecord` detecta filas descuadradas |
| **Java** | **Nada** | Apache Commons CSV u OpenCSV. Verificado: no hay CSV en el JDK |
| **JavaScript** | **Nada** | `csv-parse` o Papa Parse |
| **TypeScript** | Lo de JavaScript | La fila es `string[]`: el tipado llega después de validar |

- **Que Java no traiga CSV sorprende** siendo el lenguaje con más carga de procesos por lotes. Es una
  de esas preguntas donde la respuesta correcta es "no está, y uso Commons CSV".
- **`DictReader` de Python y `FieldsPerRecord` de Go** resuelven el mismo problema desde ángulos
  distintos: qué hacer cuando una fila tiene más o menos campos que la cabecera. Ignorarlo es cómo se
  cuela un fichero corrupto entero.

---

## 7. ⏱️ La tabla de costes

| | CSV | JSON | XML |
|---|---|---|---|
| Tamaño para datos tabulares | referencia | 2–4 × | 4–8 × |
| Parseo en flujo | natural | necesita biblioteca de flujo | necesita SAX/StAX |
| Memoria por registro | `O(1)` | `O(1)` en flujo | `O(1)` en flujo |
| Tipos | ninguno | seis | los del XSD |
| Anidamiento | no lo tiene | sí | sí |
| Contrato validable | no existe | JSON Schema | XSD |

> Para una tabla de diez millones de filas, CSV no es una opción entre varias: es **la** opción, y lo
> que compite con él no es JSON sino un formato columnar como Parquet.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "CSV está estandarizado en RFC 4180" | Ese RFC es **Informational**: documenta, no obliga |
| "Una línea es un registro" | No, si un campo lleva un salto de línea entrecomillado |
| "Se parsea con `split(',')`" | Falla con la primera razón social que lleve coma |
| "El separador es la coma" | En español suele ser punto y coma, porque el decimal es coma |
| "El archivo trae su codificación" | No trae ninguna. Por eso existe el truco del BOM |
| "`007` se conserva" | En el archivo sí; la hoja de cálculo lo convierte en 7 al abrirlo |
| "Vacío y nulo se distinguen" | `a,,b` no dice cuál es cuál. Hay que acordar un centinela |
| "Exportar CSV no tiene riesgos" | Una celda que empieza por `=` es una fórmula en el escritorio ajeno |
| "Java trae CSV" | No lo trae. Commons CSV u OpenCSV |

---

## 📚 Para profundizar

- **Norma** — [RFC 4180 — *Common Format and MIME Type for CSV Files*](https://www.rfc-editor.org/rfc/rfc4180):
  seis páginas, y conviene leer su cabecera para ver que pone *Informational*.
- **Norma** — [W3C — *Model for Tabular Data and Metadata on the Web*](https://www.w3.org/TR/tabular-data-model/):
  el intento de dar a CSV los metadatos que le faltan. Útil para saber qué se echa en falta.
- **Python** — [`csv`](https://docs.python.org/3/library/csv.html): dialectos, `DictReader` y el
  `Sniffer`. La sección de dialectos es la que resuelve el intercambio con Excel.
- **Go** — [`encoding/csv`](https://pkg.go.dev/encoding/csv): corto y suficiente; mira
  `FieldsPerRecord` y `LazyQuotes`.
- **Java** — [Apache Commons CSV](https://commons.apache.org/proper/commons-csv/): la biblioteca con
  formatos predefinidos, incluido `EXCEL` y `RFC4180`.
- **Seguridad** — [OWASP — *CSV Injection*](https://owasp.org/www-community/attacks/CSV_Injection):
  el ataque, sus variantes y cómo se sanea al exportar.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`06` — Respuestas](06-respuestas.md).

1. ¿Qué norma define CSV? 🟢
2. ¿Cuándo hay que entrecomillar un campo? 🟢
3. ¿Cómo se escribe una comilla dentro de un campo entrecomillado? 🟢
4. ¿Puede un campo contener un salto de línea? 🟢
5. ¿Distingue CSV entre nulo y cadena vacía? 🟢
6. ¿Trae Java un lector de CSV en el JDK? 🟢
7. ¿Qué es el BOM y para qué se usa en un CSV? 🟢
8. ¿Qué es la inyección de fórmulas en CSV? 🟢
9. ¿Por qué RFC 4180 no obliga a nadie? 🟡
10. ¿Por qué en español el separador suele ser punto y coma? 🟡
11. ¿Qué le pasa a `007` al abrir el archivo en una hoja de cálculo? 🟡
12. ¿Por qué falla `split(',')` y con qué dato concreto? 🟡
13. ¿Por qué `readLine()` no basta para leer registros? 🟡
14. ¿Qué problema causa el BOM a un parser que no lo espera? 🟡
15. ¿Qué resuelven `DictReader` de Python y `FieldsPerRecord` de Go? 🟡
16. ¿Cuánto ocupa un CSV frente a un JSON con los mismos datos tabulares? 🟡
17. ¿Cuál es el coste en memoria de parsear CSV correctamente? 🟡
18. ¿Cuándo dirías que CSV es la elección correcta frente a JSON? 🟠
19. Te piden distinguir nulo de vacío en un CSV. ¿Qué propones? 🟠
20. ¿Cómo se sanea una exportación con texto de usuario, y por qué es responsabilidad tuya? 🟠
21. Los acentos se rompen solo para algunos usuarios. Diagnostica la cadena entera. 🟠
22. ¿Por qué proponer `.xlsx` puede ser mejor respuesta que arreglar el BOM? 🟠
23. Un fichero de diez millones de filas hay que agregarlo por cliente. ¿Qué estructura y qué
    coste en memoria? 🟠
24. ¿Por qué no se puede paralelizar la lectura de un CSV troceándolo por bytes? 🟠
25. ¿Qué ventaja tiene un formato columnar frente a CSV, y cuándo compensa el cambio? 🟠
26. Te dan un CSV con cabecera y otro sin ella, del mismo origen. ¿Cuál prefieres y por qué? 🟠
27. Escribe el acuerdo de intercambio de CSV con un socio: los cinco puntos que hay que fijar y
    qué pasa si falta cada uno. 🔴
28. Diseña la importación robusta de un CSV de origen desconocido: validación, filas
    descuadradas, codificación, informe de errores y qué haces con la fila 4 000 001 que viene mal.
    🔴
29. Diseña la exportación de un informe de diez millones de filas que un usuario descarga desde
    el navegador. Di qué pasa con la memoria, el tiempo y los errores a mitad. 🔴
30. Un socio te entrega ficheros diarios y un día llega uno truncado por un fallo de red. Diseña
    la detección y la recuperación. 🔴

---

**Anterior:** [`03` — YAML](03-yaml.md) ·
**Siguiente:** [`05` — Simulación de entrevista](05-simulacion-de-entrevista.md) ·
**Bloque:** [README](README.md)
