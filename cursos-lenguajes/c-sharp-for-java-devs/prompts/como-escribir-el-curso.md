# 🧭 Cómo se escribe este curso
## C# para desarrolladores Java senior

Manual de operación del directorio `prompts/`. Dice **qué documento manda sobre cuál**, **en qué
orden se escribe el curso** y **qué se hace en cada chat**. Se lee una vez, al empezar, y se
vuelve a él cuando haya dudas de proceso — no de contenido.

---

## 1. Qué hay aquí, y para qué sirve cada cosa

| Documento | Qué es | Cuándo se lee |
|---|---|---|
| [`alcance-del-proyecto.md`](alcance-del-proyecto.md) | Qué es el curso, para quién, qué no hace, versiones, plataforma | Antes de escribir cualquier cosa |
| [`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) | La secuencia cerrada de 25 fases y **el alcance literal de cada una** (§5) | En cada chat de fase |
| [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md) | Voz, código, marcadores, ejercicios, checklist de cierre | En cada chat, siempre |
| [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md) | El esqueleto de diez secciones | Al empezar y al cerrar una fase |
| [`formato-de-miniproyectos.md`](formato-de-miniproyectos.md) | El miniproyecto 🧱 y su prueba de calibración | Al escribir la sección 7 |
| [`formato-de-mediciones.md`](formato-de-mediciones.md) | El arnés, la medición 📏 y `BENCHMARKS.md` | Al escribir la sección 6 |
| [`prompts-de-fase.md`](prompts-de-fase.md) | El marco común y los 25 bloques de fase | Al abrir cada chat |
| [`prompts-de-documentos-de-encuadre.md`](prompts-de-documentos-de-encuadre.md) | Los prompts de README, estructura, git, benchmarks e instintos | Al abrir esos chats |
| [`congelamiento-de-nombres.md`](congelamiento-de-nombres.md) | El esquema heredado, el modelo nuevo, el borde 🧬 y la estructura de `src/` | Antes de escribir cualquier fase, y cada vez que haga falta un nombre |
| [`../00-historia-de-cordillera.md`](../00-historia-de-cordillera.md) | La empresa: personajes, cifras, cronología, deuda técnica · **publicado, en la raíz del curso** | Siempre que el material toque el dominio |

**Orden de autoridad**, cuando dos se contradigan: (1) las instrucciones del proyecto,
(2) `alcance-del-proyecto.md`, (3) `propuesta-fases-y-alcance.md`, (4) la guía de estilo,
(5) las plantillas, los formatos y el congelamiento de nombres, (6) la historia para todo lo
narrativo, (7) los entregables ya escritos, (8) las decisiones del chat actual.

> 🧭 **Si una contradicción aparece al escribir, se arregla en el documento de arriba primero.**
> Parchear la fase y dejar la propuesta desactualizada es cómo empiezan las divergencias que
> nadie detecta hasta la fase doce.

---

## 2. La regla de los chats

**Un chat, un archivo.** Cada fase y cada documento de encuadre se redacta en su propio chat y
produce un único `.md`. Si un chat no produce entregable, o sobra o se salió de alcance.

Lo que se pega al abrir un chat de fase:

1. El **§ Marco común** de `prompts-de-fase.md`, tal cual.
2. El **bloque de la fase** que toca, del mismo archivo.
3. Los documentos del marco, o la instrucción de leerlos.

El chat produce el `.md` de la fase, y nada más. Los 📌 Pendientes del final son material de
autoría: de ahí salen las entradas nuevas de `BENCHMARKS.md`, de `INSTINTOS.md` y las decisiones
que haya que subir a la propuesta.

---

## 3. El orden de escritura

**Primero el encuadre**, porque las fases lo enlazan:

1. `README.md`
2. `0-ESTRUCTURA-CURSO.md`
3. `00-convencion-de-git-y-tags.md`

**Después la Fase 00**, que es la que más decide: fija el ambiente, el arnés, el marco de pruebas
y la estructura de `src/`. Con ella nacen `BENCHMARKS.md` e `INSTINTOS.md` en su versión inicial.

**Después, en este orden:**

4. **Fases 01 a 06** (Bloque A). Fijan el modelo de dominio y la voz. Todo lo demás las cita.
5. **Fases 07 a 11** (Bloque B) ⭐. Son el corazón y las que más pueden obligar a retocar las
   anteriores. Escribirlas pronto es barato; escribirlas al final, caro.
6. **Fases 12 a 14** (Bloque C). Dependen del legado y dejan abierta la cuarta columna que
   completa la F18.
7. **Fases 15 a 20** (Bloque D).
8. **Fases 21 a 22** (Bloque E).
9. **Fases 23 y 24** (cierre). La 24 consolida y admite; va al final por definición.

> ⚠️ **La Fase 14 y la Fase 18 están acopladas, y así se resuelve** (propuesta §8): la 14
> congela la metodología y publica su tabla con tres columnas llenas y la cuarta **declarada
> pendiente**; la 18 la rellena con la misma metodología y **actualiza la tabla de la 14**. Es la
> única actualización retroactiva permitida en el curso, y está declarada en los dos sitios.

---

## 4. Qué se hace al cerrar una fase

Antes de dar por bueno el `.md`:

- [ ] Pasar el **checklist de la guía §13** entero. No es un trámite: es donde se atrapan el
      código con acento de Java, el servicio de nube sin costo y el miniproyecto mal calibrado.
- [ ] Verificar la **prueba de calibración del miniproyecto** (`formato-de-miniproyectos.md` §3):
      si se resuelve copiando la sección 5, la fase se reescribe. Es bloqueante.
- [ ] Verificar el **checklist de la medición** (`formato-de-mediciones.md` §6) y agregar la
      entrada a `BENCHMARKS.md`.
- [ ] Agregar el reflejo 🪞 de la fase a `INSTINTOS.md`.
- [ ] Revisar el **libro de deudas** (propuesta §7.1): que cada 💸 nuevo esté anotado allí con su
      fase de cobro, y que las deudas que esta fase cobra estén efectivamente cobradas, con el
      `git diff` entre los dos tags citado en el bloque 🏷️.
- [ ] Revisar que **el proyecto declarado en el encabezado avanzó de verdad**, con al menos un
      ítem verificable en el checklist de la sección 2.
- [ ] Subir a la propuesta cualquier decisión que afecte a otra fase, **antes** de cerrar el chat.

---

## 5. Qué sigue abierto: nada — y el curso ya está escrito

Las once decisiones de `propuesta-fases-y-alcance.md` §10 están cerradas, y los dos acoplamientos
también: el del bloque de escritorio con la F18 está resuelto en §8 de la propuesta, y la
convergencia de deudas en la F20 está cuadrada en el libro de §7.1.

🏁 **Y desde el 13 de septiembre de 2026 este manual describe algo que ya ocurrió:** las
veinticinco fases están escritas, en nueve tandas, con este procedimiento. El checklist de cierre
de §4 se aplicó fase por fase, y lo que produjo —dos reglas de honestidad nuevas, seis tipos de
cobro atípico en el libro de deudas, un tercer subárbol en `src/`— está registrado en el documento
que mandaba sobre cada cosa, nunca parcheado solo en la fase. Lo único del curso que queda sin
escribir son **los cinco tracks opcionales**, y cada uno tendría sus propios prompts en archivos
nuevos (`prompts-<track>-fase.md`), jamás añadidos a los existentes.

🪦 **Y el trámite de versiones también está hecho**, en dos fechas: el 12 de septiembre de 2026
—Visual Studio Community 2026, el SDK .NET 10, EF Core, Dapper, xUnit, Testcontainers, NSubstitute,
`System.IO.Hashing` y `Microsoft.Extensions.Resilience`— y el 13, al escribir los bloques D y E:
OpenTelemetry, ONNX Runtime, ML.NET, `Microsoft.Extensions.AI`, Semantic Kernel y **Spring Boot
4.1.1 / Java 25 LTS**, que obligó a corregir §10.5 de la propuesta. Todo verificado contra las
notas oficiales y las fichas de NuGet, y escrito en `alcance-del-proyecto.md` §9 con su fecha y su
fuente. Cuando una de esas piezas avance —el SDK
una vez al mes, Visual Studio cada semana— se actualiza **allí primero** y después en las fases
que la citen. Ninguna versión se da por buena de memoria: es una regla del curso y no tiene
excepción.

Y hay un paso previo a la Fase 00 que este manual incorporó después de la primera tanda: **el
congelamiento de nombres**, en [`congelamiento-de-nombres.md`](congelamiento-de-nombres.md). Cierra el modelo de
dominio y el esquema heredado completo antes de que la F01 y la F07 los usen, que es lo que
veintitrés fases arrastran. Se lee antes de escribir cualquier fase y se cita, no se copia.

---

## 6. Las tres cosas que más se rompen al escribir

No son reglas nuevas —todas están en la guía— sino las que en la práctica se cuelan:

**Explicarle al lector lo que ya sabe.** Pasa sobre todo en las fases del Bloque D, donde es
tentador introducir HTTP, colas o contenedores desde cero. El lector lleva ocho años con eso.

**Afirmar sin medir.** "Más rápido", "más liviano", "sale más barato" se escriben solos. Cada uno
necesita su número o desaparece el comparativo.

**Modernizar el código heredado de paso.** Un `var` aquí, un `using` allá, un nombre en inglés en
una tabla de 1997. Cada uno de esos es el error que el curso enseña a no cometer, cometido por el
propio curso.
