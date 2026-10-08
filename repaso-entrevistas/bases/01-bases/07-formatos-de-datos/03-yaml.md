# 03 — YAML

> El formato de la configuración —Kubernetes, CI, Spring, Docker Compose— y el único del temario
> donde **el mismo archivo significa cosas distintas según el lenguaje que lo lea**. Por qué `NO` se
> convierte en `false`, por qué `022` es 18 y `12:30` es 750, y por qué cargar YAML de fuera con la
> función equivocada es ejecución remota de código.
>
> **Asume leído:** [`01` — JSON](01-json.md).
>
> **Vigencia:** 2026-09-18. Todas las salidas de este capítulo están **ejecutadas**.

---

## 1. 🎯 El problema

Un mismo archivo de configuración, cinco claves, tres lenguajes. Este es el archivo:

```yaml
paises: [NO, SE]
version: 1.10
puerto: 022
hora: 12:30
si: yes
```

Y esto es lo que cada biblioteca entrega, ejecutado:

| clave | Python (PyYAML 6.0.3) | Java (SnakeYAML 2.3) | Go (yaml.v3) |
|---|---|---|---|
| `paises` | `[False, 'SE']` | `[false, SE]` | `["NO", "SE"]` |
| `version` | `1.1` *float* | `1.1` *Double* | `1.1` *float64* |
| `puerto` | `18` *int* | `18` *Integer* | `18` *int* |
| `hora` | `750` *int* | `750` *Integer* | `"12:30"` *string* |
| `si` | `True` | `true` | `"yes"` *string* |

Cuatro desastres en cinco líneas, y ninguno lanza error:

- **`NO` es el código ISO de Noruega** y se convierte en el booleano falso. Es tan conocido que tiene
  nombre propio: *the Norway problem*.
- **`1.10` es un número, no una versión**, y como número `1.10` es `1.1`: el cero desaparece y tu
  despliegue apunta a otra versión.
- **`022` se lee en octal** y vale 18. Si era un puerto, un código de sucursal o un día del mes con
  cero delante, ya está mal.
- **`12:30` se lee en sexagesimal** —12 × 60 + 30— y vale 750. Era una hora.

**Y la divergencia entre lenguajes es peor que cualquiera de los cuatro errores por separado:** el
mismo archivo desplegado por una herramienta en Go y leído por un servicio en Java **no contiene lo
mismo**.

---

## 2. 🧱 Qué es YAML, y por qué hay dos YAML

**Qué es.** Un formato de serialización pensado para que lo escriban y lo lean personas: sin llaves,
sin comillas obligatorias, con indentación significativa y con comentarios — lo que JSON no tiene y
por lo que la configuración se mudó aquí.

**Cómo va.** Y el dato que explica la tabla de arriba: **hay dos versiones de la norma en uso**.

```text
YAML 1.1 (2005)   yes/no/on/off son booleanos · 022 es octal · 12:30 es sexagesimal
YAML 1.2 (2009)   se realinea con JSON: el "core schema" deja solo true/false
```

- **YAML 1.2 es JSON**: todo documento JSON válido es YAML 1.2 válido. Esa compatibilidad fue el
  objetivo declarado de la revisión.
- **La mitad del ecosistema sigue en 1.1.** PyYAML y SnakeYAML implementan 1.1; `yaml.v3` de Go
  aplica el esquema de 1.2 para booleanos. De ahí que `yes` sea `true` en Java y Python, y la cadena
  `"yes"` en Go — **verificado arriba, no deducido**.
- El octal sobrevive en los tres, porque ahí las dos versiones coinciden en tratar `0` inicial como
  base 8.

**Cuánto cuesta.** Parsear YAML es varias veces más caro que JSON: la gramática es mucho mayor y hay
que resolver la conversión implícita de tipos. En configuración da igual —se lee una vez al
arrancar—; como formato de intercambio en caliente, no.

**Cuándo sí.** Archivos escritos y revisados por personas: configuración, canalizaciones de CI,
manifiestos, plantillas de infraestructura.

**Cuándo no.** Como formato de API o de mensajería. Ahí pagas un parser enorme, una superficie de
ataque mayor y una ambigüedad de tipos que nadie quiere en un contrato.

> **Veredicto:** YAML es un formato de edición, no de intercambio. Todo lo que no vaya a leer una
> persona debería ser JSON.

---

## 3. 🧱 La conversión implícita, y cómo se apaga

**Qué es.** YAML adivina el tipo de cada valor sin comillas mirando su forma. Eso es lo que hace
agradable escribir `puerto: 8080` sin comillas, y es exactamente lo mismo que produce los cuatro
desastres de la sección 1.

**Cómo va.** Las familias de valores que se convierten sin que nadie lo pida:

```text
booleanos    true false yes no on off y sus mayúsculas   (en YAML 1.1)
nulos        null ~ y el valor VACÍO
números      12 3.14 1e5 0x1F 0o17 022 12:30
fechas       2026-09-18  →  objeto fecha en muchas bibliotecas
```

- **El vacío es nulo.** Una clave `descripcion:` sin nada detrás no es la cadena vacía: es `null`. Es
  la causa del `NullPointerException` que aparece solo en un entorno.
- **`~` también es nulo**, y es lo que hace que un archivo se lea distinto de como se ve.

**El remedio, que es de una línea:**

```yaml
paises: ["NO", "SE"]    # con comillas ya no se convierte nada
version: "1.10"
puerto: "022"
hora: "12:30"
```

- **Todo lo que sea un código, un identificador, una versión o una hora va entrecomillado.** No es
  cuestión de estilo: las comillas son la forma que da YAML de decir "esto es texto".
- Lo contrario también importa: en Kubernetes, `replicas: "3"` con comillas **falla**, porque ahí sí
  se espera un número. La regla es entrecomillar lo que es texto, no entrecomillar todo.

> **Veredicto:** en YAML, las comillas no sobran nunca donde el valor sea un código. Cuestan dos
> caracteres y evitan el fallo que aparece solo con el país número 40 de la lista.

---

## 4. 🧱 Anclas, alias y fusión

**Qué es.** YAML puede declarar un fragmento una vez y reutilizarlo, algo que JSON no tiene:

```yaml
base: &comun          # ancla: le pone nombre a este nodo
  reintentos: 3
  timeout: 5
dev:
  <<: *comun          # alias con fusión: copia las claves de `comun`
  timeout: 30         # y esta gana
```

Ejecutado, `dev` queda como `{reintentos: 3, timeout: 30}`.

**Cuánto.** Y aquí está el precio: **un alias es una referencia, así que se puede anidar**, y anidar
diez niveles de alias con diez elementos cada uno produce 10^10 nodos a partir de un archivo de unas
pocas líneas. Es la *billion laughs* del capítulo `02`, en YAML.

- Por eso los parsers modernos limitan la expansión de alias, y por eso **un YAML que viene de fuera
  se trata con el mismo cuidado que un XML de fuera**.
- La clave `<<` de fusión es una extensión de YAML 1.1, no del núcleo: hay bibliotecas que no la
  soportan, y es una de las cosas que se rompen al cambiar de parser.

**Cuándo sí.** En archivos largos escritos a mano, para no repetir bloques de configuración.

**Cuándo no.** En archivos generados, o cuando el archivo lo va a leer otra herramienta: las anclas
son de las primeras cosas que un parser distinto interpreta mal.

> **Veredicto:** las anclas ahorran repetición y cuestan portabilidad. Úsalas en lo tuyo; no las
> pongas en un archivo que va a cruzar herramientas.

---

## 5. ⚠️ `load` frente a `safe_load`: el que ejecuta código

**Qué es.** YAML no es solo datos: su modelo permite **etiquetas** que dicen de qué tipo es un nodo,
y algunas bibliotecas las usan para **construir objetos del lenguaje**. Si el atacante controla el
archivo, controla qué objetos se construyen.

**Cómo va.** En Python la protección es elegir la función correcta, y se verifica:

```text
yaml.safe_load("!!python/object/apply:os.getcwd []")
→ rechazado: could not determine a constructor for the tag
  'tag:yaml.org,2002:python/object/apply:os.getcwd'
```

- **`yaml.load` sin cargador seguro construye objetos arbitrarios**; `safe_load` solo admite los
  tipos básicos. La diferencia entre las dos funciones es la diferencia entre leer un archivo y
  ejecutar lo que diga.
- En Java es lo mismo con otro nombre: SnakeYAML construye objetos por etiqueta salvo que se le pase
  un `SafeConstructor`. **SnakeYAML 2.x cambió el valor por defecto a seguro**, que es la razón por
  la que conviene saber qué versión se está usando.
- Las vulnerabilidades reales de esta familia no son teóricas: han producido ejecución remota de
  código en aplicaciones muy conocidas, siempre con la misma forma —YAML de un usuario cargado con la
  función permisiva—.

> **Veredicto:** todo YAML que no hayas escrito tú se carga con la función segura, sin excepción. Y
> si estás mirando código ajeno, `yaml.load(` a secas es de las cosas que se buscan con `grep` en una
> revisión de seguridad.

---

## 6. 🧱 La indentación y el texto multilínea

Dos detalles que consumen tiempo real de depuración:

**El tabulador está prohibido como indentación.** Verificado: PyYAML lanza *"while scanning for the
next token"*, un mensaje que no menciona la palabra tabulador.

- La norma lo prohíbe porque la anchura de un tabulador depende del editor, y la indentación es
  sintaxis. Es la primera cosa que hay que mirar ante un error de parseo inexplicable.

**Los dos escalares de bloque**, que se confunden siempre:

```yaml
literal: |      # conserva los saltos de línea
  linea 1
  linea 2
plegado: >      # los pliega en espacios
  linea 1
  linea 2
```

Ejecutado, `literal` es `"linea 1\nlinea 2\n"` y `plegado` es `"linea 1 linea 2\n"`.

- `|` para lo que tiene estructura de líneas: un script, una clave pública, un certificado.
- `>` para un párrafo largo que quieres escribir en varias líneas y leer como una.
- Ambos admiten `-` para quitar el salto final: `|-` es lo que se usa en una clave o un *token*,
  porque ese `\n` de más invalida la firma.

---

## 7. ⏱️ La tabla de costes

| | JSON | YAML |
|---|---|---|
| Tamaño de la gramática | una página | decenas de páginas |
| Velocidad de parseo | referencia | varias veces más lento |
| Comentarios | no | sí |
| Ambigüedad de tipos | ninguna | la de la sección 1 |
| Superficie de ataque | parseo | parseo + alias + etiquetas de objeto |
| Escrito por personas | incómodo | cómodo |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "YAML es JSON más legible" | YAML 1.2 es superconjunto de JSON; 1.1, que es lo que usan Java y Python, no |
| "`NO` es el código de Noruega" | Es `false` en PyYAML y SnakeYAML. Con comillas es el código |
| "`022` es el puerto 22" | Es 18: se lee en octal |
| "Una clave vacía es cadena vacía" | Es `null` |
| "Todos los parsers leen igual mi YAML" | Verificado que no: `yes` y `12:30` cambian de tipo según el lenguaje |
| "`yaml.load` está bien si el archivo es nuestro" | Hasta que deje de serlo. `safe_load` siempre |
| "`|` y `>` son equivalentes" | Uno conserva los saltos y el otro los pliega |
| "Puedo indentar con tabuladores" | Prohibido, y el error no menciona el tabulador |
| "YAML sirve como formato de API" | Es un formato de edición: parser enorme y tipos ambiguos |

---

## 📚 Para profundizar

- **Norma** — [YAML 1.2.2 — especificación](https://yaml.org/spec/1.2.2/): la vigente. El capítulo
  10, del *core schema*, es el que explica por qué `yes` dejó de ser booleano.
- **Norma** — [YAML 1.1 — *Timestamps y tipos*](https://yaml.org/type/): la lista de tipos
  implícitos de 1.1, que es la que siguen PyYAML y SnakeYAML. Ahí están el octal y el sexagesimal.
- **Referencia** — [*Learn YAML in Y minutes*](https://learnxinyminutes.com/docs/yaml/): la sintaxis
  entera en una página, con las trampas señaladas.
- **Python** — [PyYAML — documentación](https://pyyaml.org/wiki/PyYAMLDocumentation): la diferencia
  entre `load` y `safe_load`, explicada por los autores.
- **Java** — [SnakeYAML — repositorio y documentación](https://bitbucket.org/snakeyaml/snakeyaml/src/master/)
  y su [javadoc](https://javadoc.io/doc/org.yaml/snakeyaml/latest/index.html): el constructor seguro y
  qué cambió en la versión 2.
- **Go** — [`gopkg.in/yaml.v3`](https://pkg.go.dev/gopkg.in/yaml.v3): la biblioteca de facto, y su
  nota sobre qué esquema implementa.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`06` — Respuestas](06-respuestas.md).

1. ¿Para qué se usa YAML y por qué no JSON? 🟢
2. ¿Es todo JSON un YAML válido? 🟢
3. ¿Qué es el problema de Noruega? 🟢
4. ¿Qué vale `022` en YAML? 🟢
5. ¿Qué es un ancla y qué es un alias? 🟢
6. ¿Qué diferencia hay entre `|` y `>`? 🟢
7. ¿Se puede indentar con tabuladores? 🟢
8. ¿Qué trae Node de serie para YAML? 🟢
9. ¿Por qué hay dos versiones de YAML en uso y qué cambia entre ellas? 🟡
10. ¿Qué pasa con `12:30` y por qué? 🟡
11. ¿Qué vale una clave sin valor? 🟡
12. ¿Cómo se evita toda la conversión implícita? 🟡
13. ¿Qué hace la clave de fusión `<<` y qué riesgo tiene? 🟡
14. ¿Por qué las anclas permiten un ataque de expansión? 🟡
15. ¿Qué diferencia hay entre `yaml.load` y `yaml.safe_load`? 🟡
16. ¿Por qué `replicas: "3"` falla en Kubernetes si entrecomillar era la recomendación? 🟡
17. ¿Por qué YAML es más lento de parsear que JSON? 🟡
18. El mismo archivo da tipos distintos en Go y en Java. ¿Por qué, y qué haces al respecto? 🟠
19. ¿Cuándo usarías `|-` en vez de `|`, y qué se rompe si te equivocas? 🟠
20. ¿Por qué YAML no debería ser el formato de una API? 🟠
21. ¿Qué buscarías con `grep` en una revisión de seguridad de un proyecto que usa YAML? 🟠
22. Una lista de países deja de funcionar al añadir Noruega. Explica la causa y las dos
    correcciones posibles. 🟠
23. Un despliegue apunta a la versión equivocada y el archivo dice `version: 1.10`. Diagnostica.
    🟠
24. ¿Por qué ninguna biblioteca estándar de los cinco lenguajes trae YAML, y qué implica? 🟠
25. ¿Cuándo es preferible generar el YAML desde código en vez de escribirlo a mano? 🟠
26. Escribe la política de uso de YAML de tu equipo: qué se entrecomilla, qué está prohibido,
    cómo se carga lo externo y cómo se verifica en la integración continua. 🔴
27. Tienes que soportar el mismo archivo de configuración desde un servicio Java y una
    herramienta Go. Di qué reglas impones para que ambos lean lo mismo. 🔴
28. Un archivo con anclas funciona en tu herramienta y falla en la del equipo vecino.
    Diagnostica y propón las dos salidas. 🔴
29. Escribe la prueba de integración continua que detecta que dos lenguajes leen el mismo YAML
    de forma distinta, y di qué cinco valores pondrías en el caso de prueba. 🔴
30. Te piden aceptar YAML subido por usuarios en una herramienta interna. Escribe los controles,
    en orden, y qué rechazas antes de parsear. 🔴

---

**Anterior:** [`02` — XML y los esquemas](02-xml-y-los-esquemas.md) ·
**Siguiente:** [`04` — CSV y los formatos tabulares](04-csv-y-los-formatos-tabulares.md) ·
**Bloque:** [README](README.md)
