# 07 — Formatos de datos

> El bloque de **las fronteras del sistema**: qué le pasa a un dato cuando sale de la memoria y se
> convierte en texto que otro programa, en otro lenguaje, va a volver a leer. Es el bloque menos
> algorítmico del corpus y el que más incidentes de producción explica, porque aquí nada lanza
> excepciones: los datos simplemente llegan distintos.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md)

---

## Qué es esto, y por qué estos cuatro juntos

```text
JSON  promete un número          → entrega un double en la mitad de los lenguajes
XML   promete un parser          → entrega una puerta, si no lo endureces
YAML  promete una cadena "NO"    → entrega el booleano falso
CSV   promete una línea = un registro → entrega media dirección postal
```

Los cuatro comparten la **forma del fallo**, y es la misma que el bloque
[`06`](../06-numeros-tiempo-concurrencia/): el código parece correcto, compila, pasa los tests y
falla al cruzar la frontera con otro sistema. Ninguno lanza excepción.

Y comparten la causa: **el formato no decide, decide la biblioteca**. El mismo XML es seguro en Go y
vulnerable en Java; el mismo YAML da `false` en Java y `"NO"` en Go; el mismo número llega exacto en
Python y redondeado en JavaScript. Todo eso está **ejecutado y medido** en los capítulos, no
deducido.

Las preguntas **no llevan la respuesta al lado**: viven en [`06-respuestas.md`](06-respuestas.md).

---

## Orden de lectura

| # | Documento | Qué cubre |
|---|---|---|
| `01` | [JSON](01-json.md) | Los seis tipos, los `2^53`, árbol frente a flujo con memoria medida, lector tolerante, `JSON.parse` y `any` |
| `02` | [XML y los esquemas](02-xml-y-los-esquemas.md) | Espacios de nombres, DOM/SAX/StAX, XPath, XSD, XXE y *billion laughs* en tres lenguajes |
| `03` | [YAML](03-yaml.md) | 1.1 frente a 1.2, el problema de Noruega, anclas, `safe_load`, escalares de bloque |
| `04` | [CSV y los formatos tabulares](04-csv-y-los-formatos-tabulares.md) | RFC 4180 y por qué no obliga, comillas, BOM y Excel, inyección de fórmulas |
| `05` | [Simulación de entrevista](05-simulacion-de-entrevista.md) | 34 preguntas transversales + 6 problemas de pizarra |
| `06` | [Respuestas](06-respuestas.md) | Solucionario completo del bloque, en tres capas |

**Si el calendario aprieta:** `01` y `04`. JSON porque es el que vas a usar seguro, y CSV porque es
el que todo el mundo cree saber y casi nadie parsea bien.

---

## Las cinco cosas que este bloque deja claras

1. **`9007199254740993` llega como `...992` a JavaScript**, y como `9.007199254740992e+15` a Go con
   mapa genérico. Por eso los identificadores viajan como cadena.
2. **Un árbol cuesta unas ocho veces el tamaño del archivo.** Medido: 30 MB de JSON → 323 MB de
   memoria residente en la JVM, frente a 99 MB en flujo.
3. **El parser XML por defecto de Java lee archivos de tu servidor.** Verificado, y Python y Go no.
   Una línea lo cierra.
4. **`NO` es `false`, `022` es 18 y `12:30` es 750** en PyYAML y SnakeYAML. En Go, dos de los tres
   no. El mismo archivo no significa lo mismo.
5. **`split(',')` devuelve 5 campos donde hay 4**, con una razón social que lleva coma. Verificado
   contra `csv.reader`.

---

## Qué NO está aquí

- **Los formatos en el cable: tipos de medio, `Content-Type`, negociación, Base64 y multipart** →
  [`repaso-apis-y-protocolos-entrevistas`](../../04-apis-protocolos/), que es dueño
  de lo que viaja por HTTP. Aquí se trata **la biblioteca**, allí **el protocolo**.
- **Formatos binarios con esquema —Protocol Buffers, Avro— y registros de esquemas** → son de
  comunicación entre servicios:
  [`arquitectura/04-microservicios`](../../../arquitectura/04-microservicios/README.md). Aquí solo aparecen como término de
  comparación.
- **Codificación de caracteres, Unicode y longitud de cadenas** → bloque
  [`02-texto`](../02-texto/), que este asume leído.
- **Coma flotante, `BigDecimal` y dinero** → [`06/01`](../06-numeros-tiempo-concurrencia/01-numeros-precision-y-dinero.md),
  al que los capítulos `01` y `04` remiten en vez de repetirlo.
- **Serialización nativa del lenguaje** —`Serializable` de Java, `pickle` de Python— que es otro tema
  y otro conjunto de vulnerabilidades. Fuera del alcance declarado.
- **El código en los cinco lenguajes** → bloque opcional
  [`09-implementaciones`](../09-implementaciones/), capítulo `04`.

---

## Las versiones con las que se ejecutó

Todo lo que este bloque publica como salida se ejecutó de verdad, con:

```text
Java      Zulu 17.0.16 y 21.0.12 · Jackson 2.18.2 · SnakeYAML 2.3
Python    3.13.4 · PyYAML 6.0.3
Node      24.21.0 · TypeScript vía npx tsc --strict
Go        1.27.1 · gopkg.in/yaml.v3
```

Las medidas de memoria son `maximum resident set size` de `/usr/bin/time -l` en macOS, con un archivo
JSON de 30 MB y 400 000 objetos.
