# 🧰 `prompts/` — la maquinaria del curso
## C# para desarrolladores Java senior

Este directorio no es material del curso: es **lo que se usa para escribirlo**. El lector nunca
lo abre. Quien escribe una fase lo lee entero antes de teclear la primera línea.

> 🏁 **Estado: el curso está escrito (13/09/2026).** Las veinticinco fases, los cinco documentos
> de encuadre y el `src/` acordado —el arnés, el legado SIGE y su observabilidad— están publicados.
> Esta maquinaria pasa de ser **instrucciones para escribir** a ser **el registro de por qué el
> curso quedó así**, y se sigue leyendo antes de tocar nada: los nombres siguen congelados, las
> reglas de medición siguen mandando, y el contenido está bloqueado.
>
> Lo único pendiente del curso son **los cinco tracks opcionales** (`ui`, `ar`, `au`, `db`, `cv`),
> que están fuera del camino obligatorio y tendrían sus propios prompts (`prompts-<track>-fase.md`),
> nunca añadidos a los existentes.

> 🪦 **Tres cosas cambiaron al escribir, y están registradas donde correspondía en vez de
> corregidas en silencio.** (1) El competidor del duelo pasó de **Spring Boot 3 a 4.1.1 / Java 25
> LTS** —medir contra la línea anterior habría sido el espantapájaros que la F23 existe para
> evitar— y quedó en `propuesta-fases-y-alcance.md` §10.5. (2) `formato-de-mediciones.md` ganó
> **dos reglas de honestidad** —la cifra de costo con fuente y fecha (§2.7), y la declaración de
> defendibilidad (§2.8)—, numeradas después de la convención ⏳ porque veinticinco documentos
> publicados citan `§2.6` y renumerarla las habría roto. (3) `src/` ganó un **tercer subárbol**,
> `src/duelo/`, declarado en el congelamiento como la única excepción a la regla de dos.
>
> Y una que no se pudo arreglar: la **F24 §4** admite **dos decisiones de orden de este
> directorio** que debieron ser otras —el sistema heredado antes del Bloque A, y el veredicto del
> escritorio después de la web—. **No se corrigieron**, por la regla de bloqueo de contenido que
> este curso se impone, y quedan escritas como errores documentados también en
> `0-ESTRUCTURA-CURSO.md` §4.

> 📝 **Revisión contra los lineamientos del repositorio (05/10/2026).** El curso se escribió antes de
> que existieran los lineamientos de producción del repositorio, y se revisó contra ellos sin
> renombrar ni reordenar nada. Lo que diverge quedó declarado en la **guía §14**: comentarios en
> español, la banda de 20–25 ejercicios, ejercicios sin solución publicada (el miniproyecto es la
> evaluación verificable), ningún apéndice, y **D-12: diagramas en Mermaid** (los dos que había se
> convirtieron). El curso ganó su verificador, `verificar-corpus.py`, y el `README.md` del curso
> dejó de describir un `src/duelo/` que el lector todavía no armó.

---

## 📖 Orden de lectura

Si llegas nuevo a este curso, en este orden y no en otro:

1. **[`alcance-del-proyecto.md`](alcance-del-proyecto.md)** — qué es el curso, para quién, qué
   produce y qué no hace. Incluye las dos reglas de forma que lo definen: **no hay apéndices** y
   **es de Windows, exclusivamente**. §10.1 tiene el inventario de qué se ejecuta, qué se
   sustituye y qué solo se estudia de la nube.
2. **[`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md)** — la estructura. §4 tiene la
   numeración oficial de las 25 fases; **§5 tiene el encargo detallado de cada una**; §7.1 tiene
   el libro de deudas 💸; §10 tiene las once decisiones cerradas con su porqué.
3. **[`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md)** — voz, idioma,
   pedagogía, estilo de código, marcadores, la plantilla de 10 secciones, ejercicios, y el
   checklist de cierre.
4. **[`00-historia-de-cordillera.md`](../00-historia-de-cordillera.md)** — la empresa del
   curso. Fuente de verdad de todo lo narrativo: personajes, cifras, cronología, reglas de negocio
   y la deuda técnica del sistema, con su fecha. **Es el único de estos documentos que vive fuera
   de `prompts/`**, en la raíz del curso, porque dejó de ser maquinaria: el lector lo lee.

Y como referencia, cuando toque:

- **[`plantillas-de-capitulo.md`](plantillas-de-capitulo.md)** — el esqueleto de fase, que se
  sigue literal. Es uno solo: no hay plantilla de apéndice porque no hay apéndices.
- **[`formato-de-miniproyectos.md`](formato-de-miniproyectos.md)** — el miniproyecto obligatorio
  de cada fase, cómo se calibra y su prueba bloqueante.
- **[`formato-de-mediciones.md`](formato-de-mediciones.md)** — el arnés, la forma de una medición
  y **las siete reglas de honestidad**, más las dos convenciones de lo pendiente: ⏳ (§2.6, escrita
  y sin ejecutar) y 🔜 (§2.9, el competidor todavía no existe).
- **[`congelamiento-de-nombres.md`](congelamiento-de-nombres.md)** — el esquema heredado completo,
  el modelo nuevo, el borde 🧬 entre los dos y la estructura de `src/`. Se lee antes de escribir
  cualquier fase y se cita; ningún nombre se improvisa.
- **[`como-escribir-el-curso.md`](como-escribir-el-curso.md)** — el manual de operación: orden de
  autoridad, orden de escritura y qué se verifica al cerrar cada fase.

---

## 🚀 Cómo abrir una sesión de escritura

**Primero los tres documentos de la raíz del curso**, cada uno en su chat, con el prompt que le
corresponde en
**[`prompts-de-documentos-de-encuadre.md`](prompts-de-documentos-de-encuadre.md)**:

1. `README.md` del curso
2. `0-ESTRUCTURA-CURSO.md`
3. `00-convencion-de-git-y-tags.md`

Los otros dos prompts de ese archivo —`BENCHMARKS.md` e `INSTINTOS.md`— **no abren chat propio**:
esos dos documentos nacen con la Fase 00 y crecen con cada fase, así que su prompt se usa dentro
del chat de la 00 y después no se vuelve a abrir.

**Después las fases**, una por chat. El prompt se arma copiando dos cosas de
**[`prompts-de-fase.md`](prompts-de-fase.md)**: el **§ Marco común** y el bloque de esa fase.

El orden de escritura es **el de los números**, con un paso previo que compra lo que el orden
por riesgo buscaba. Así queda, y coincide con `como-escribir-el-curso.md` §3 y con §12 de la
propuesta:

| Turno | Qué | Por qué |
|---|---|---|
| 0 | **El congelamiento de nombres** | Antes de la primera fase se cierran, en un solo sitio, el modelo de dominio y el esquema heredado completo con sus nombres y tipos. Es lo que la F01 y la F07 arrastran a veintitrés fases, y equivocarse ahí se paga en todas |
| 1 | Fase **00** | Fija ambiente, arnés, marco de pruebas y estructura de `src/`. Con ella nacen `BENCHMARKS.md` e `INSTINTOS.md` |
| 2 | **Bloque A** (01-06) | Fijan la voz y el modelo. Todo lo demás las cita |
| 3 | **Bloque B** (07-11) ⭐ | El corazón, y lo que más puede obligar a retocar el Bloque A. Escribirlo pronto es barato; al final, caro |
| 4 | **Bloque C** (12-14) y **Bloque D** (15-20) | En orden: cada proyecto crece sobre el anterior, y la 18 debe cerrar la tabla que la 14 dejó abierta |
| 5 | **21**, **22**, **23** y por último **24** | El cierre necesita todas las mediciones hechas |

> ✅ **Ejecutado así, en nueve tandas, del 12 al 13 de septiembre de 2026.** El turno 5 acabó
> siendo **21, 22, 23 y 24 en una sola tanda**, y funcionó porque el cierre necesita las
> veinticinco mediciones **escritas**, no ejecutadas — que es justamente la convención ⏳.

> 📝 **Por qué cambió este orden.** La versión anterior de esta tabla escribía la 01 y la 07
> juntas, y después las ⭐ del corazón, para que un error de nombres no se propagara entre chats
> que no se ven. El congelamiento de nombres del turno 0 da la misma garantía sin desordenar la
> secuencia, y deja de contradecir a los otros dos documentos que fijan el procedimiento.

> 🪦 **El trámite de versiones está hecho, en dos fechas.** El **12 de septiembre de 2026** se
> verificaron Visual Studio Community 2026, el SDK de .NET 10, EF Core, Dapper, xUnit,
> Testcontainers, NSubstitute, `System.IO.Hashing` y `Microsoft.Extensions.Resilience`; al escribir
> los bloques D y E se añadieron **OpenTelemetry 1.18.0** (F19) y, el **13 de septiembre**,
> **ONNX Runtime 1.30.0**, **ML.NET 5.0.0**, **`Microsoft.Extensions.AI` 10.10.0**,
> **Semantic Kernel 1.80.1** y **Spring Boot 4.1.1 / Java 25 LTS** (F21–F23). Todas están en
> `alcance-del-proyecto.md` §9 con su fecha y su fuente. Cuando una avance, se actualiza **allí
> primero**.
>
> 📝 Y el dato que el propio curso usa como material: **ONNX Runtime es de septiembre de 2026 y
> ML.NET de noviembre de 2025**. Ese contraste dice dónde está la inversión del ecosistema, y la
> F21 lo cita para sostener su veredicto. Las dos que más rápido van a envejecer son
> `Microsoft.Extensions.AI` y Semantic Kernel.

---

## 🗂️ Qué es cada archivo

| Archivo | Qué es | Manda sobre |
|---|---|---|
| `alcance-del-proyecto.md` | Encuadre, versiones, plataforma e inventario de nube | Todo salvo las instrucciones del proyecto |
| `propuesta-fases-y-alcance.md` | Estructura, alcance por fase, deudas y decisiones | La guía de estilo y las plantillas |
| `guia-de-estilo-y-convenciones.md` | Voz, código y forma | Las plantillas y los formatos |
| `plantillas-de-capitulo.md` | El esqueleto de fase | — |
| `formato-de-miniproyectos.md` | La sección 7 de cada fase | — |
| `formato-de-mediciones.md` | La sección 6 y `BENCHMARKS.md` | — |
| `congelamiento-de-nombres.md` | Esquema heredado, modelo nuevo, borde 🧬 y `src/` | Los entregables: ningún nombre se improvisa |
| `../00-historia-de-cordillera.md` | La empresa del curso · **publicado, en la raíz** | Todo lo narrativo |
| `prompts-de-documentos-de-encuadre.md` | Los 5 prompts del encuadre | — |
| `prompts-de-fase.md` | El marco común + los 25 prompts | — |
| `como-escribir-el-curso.md` | El procedimiento | — |
| `verificar-corpus.py` + `verificador_base.py` | El verificador del curso: enlaces, anclas, restos, callouts. Se corre desde la raíz del curso | — |

**Si al escribir aparece una contradicción, se arregla en el documento de arriba primero.**
Parchear la fase y dejar la propuesta desactualizada es cómo empiezan las divergencias que nadie
detecta hasta la fase doce.

---

## 🧭 Las cinco decisiones que explican todo lo demás

Si solo vas a retener cinco cosas de este directorio antes de escribir, que sean estas:

1. **La pregunta que ordena el curso es *¿esto se migra, se envuelve o se deja quieto?*** Las tres
   respuestas son legítimas y las tres tienen un costo calculable.
2. **El curso construye su propio sistema heredado** —.NET Framework 4.8, `DataSet`,
   procedimientos almacenados, esquema de 1997— para después cortarlo. El Bloque B es el corazón.
3. **Nada de lo que el curso proponga puede apagar el sistema.** Cordillera factura todos los días
   mientras el lector migra, y la vuelta atrás es requisito de diseño, no buena práctica.
4. **Cada fase produce una medición y un miniproyecto**, y avanza al menos un proyecto. Las tres
   cosas se declaran en el encabezado.
5. **Si al final .NET moderno gana todo, el curso está mal escrito.** El veredicto de la F24 está
   obligado a admitir qué no debió migrarse y qué decisiones del propio curso fueron erradas.
   **Cumplido:** la F23 publica empates en varias columnas y concede que el competidor gana algo
   estructural en el modelo de concurrencia; la F24 nombra el inventario, "el Fox" y Crystal
   Reports, y admite dos decisiones de este directorio.

---

## ⚠️ Las tres cosas que más se rompen al escribir

1. **Explicar lo que el lector ya sabe.** Es un dev Java senior con ocho años o más. Cada párrafo
   sobre qué es una interfaz, una transacción o HTTP se borra, aunque esté bien escrito.
2. **Modernizar el código heredado de paso.** Un `var` aquí, un `using` allá, un nombre en inglés
   en una tabla de 1997. Cada uno de esos es el error que el curso enseña a no cometer, cometido
   por el propio curso.
3. **Afirmar sin número.** Ni "más rápido", ni "más liviano", ni "sale más barato". Si la medición
   no existe, se escribe la frase sin el comparativo. Y cuando el trabajo toca la base de datos,
   se mide **primero el plan de consulta y después .NET**.
