# 🧩 Plantilla de capítulo
## C# para desarrolladores Java senior

Este archivo contiene **un solo esqueleto**, el de fase, porque el curso **no tiene apéndices**
(`alcance-del-proyecto.md` §6). Se copia al abrir el chat que redacta una fase, se rellenan los
`{{placeholders}}` y se borran las notas entre llaves antes de entregar.

Junto con la guía de estilo y el alcance, forma el marco para que las fases, escritas cada una
en su chat, se lean como un solo documento.

> **Nota de coherencia:** el número de fases, sus nombres, su bloque y el proyecto que cada una
> avanza salen de `propuesta-fases-y-alcance.md`. Si alguna vez cambian, **se cambian allí
> primero** y esta plantilla después.

---

# 📐 Plantilla de fase

````markdown
# {{emoji}} Fase {{NN}} — {{Nombre}}

> C# para desarrolladores Java senior · Fase {{N}} de {{total}} · Bloque {{letra — nombre}}
> Depende de: {{fase previa}} · Habilita: {{fase siguiente}}
> Estilo de esta fase: {{heredado (.NET Framework 4.8, C# de 2017) | nuevo (.NET 10, C# 14) | mixto 🧬}}
> Proyecto que avanza: {{cuál, y en qué queda al terminar}}

---

## 🎯 1. Propósito

{{Una o dos frases: qué resuelve esta fase y a qué decisión sirve. Anclar al dominio de
Cordillera. No "aprenderás X": qué vas a poder decidir o construir que antes no.}}

---

## ✅ 2. Qué queda listo al terminar

- [ ] {{resultado verificable 1}}
- [ ] {{resultado verificable 2 — al menos uno es del proyecto que avanza}}
- [ ] {{...3 a 5 ítems}}
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

{{Verificable = se comprueba ejecutando algo. "Entender X" no es un resultado verificable.}}

---

## 🚫 3. Qué NO entra todavía

- {{tema diferido}} → Fase {{M}}.
- {{...}}

{{Y si algo se difiere **fuera del curso**, se dice aquí con su razón. No hay apéndice al que
mandarlo.}}

---

## 🧠 4. Concepto mínimo

{{Solo la teoría que hace falta para escribir el código de esta fase. Prosa, no bullets. El
problema antes que la herramienta.}}

{{Aquí viven las secciones narrativas que la fase pida:}}

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

{{El reflejo concreto, el código que produce, por qué falla aquí, y qué se escribe en su lugar.
Con el contraejemplo al lado, porque la lección está en la comparación.}}

### 🩻 Esto sí funciona igual

{{Lo que se transfiere sin cambios. Importa tanto como lo anterior.}}

### 📖 Diccionario de traducción

| Java | C# / .NET | Dónde se rompe el paralelo |
|---|---|---|
| {{...}} | {{...}} | {{...}} |

{{En las dos direcciones. La tercera columna es obligatoria: una analogía sin su límite es peor
que ninguna — guía §4.2.}}

> 📝 **Nota de ecosistema.** {{Qué versión trajo esta API, qué reemplazó, y por qué lo anterior
> sigue vivo en el código que el lector va a encontrar por ahí — y en SIGE. Situada dentro de
> la cronología fija de la historia.}}

---

## 💻 5. Código mínimo con comentarios

{{El grueso de la fase. Código ejecutable, coherente con las versiones fijadas. Identificadores
nuevos en inglés, comentarios y documentación XML en español con tildes, mensajes de error y de
log en español, textos de interfaz en español.}}

{{**El avance del proyecto va aquí**, integrado en el código de la fase, no como un apartado
suelto — guía §8.1.}}

{{Estilo obligatorio — guía §6:
- **Escrito en el estilo declarado en el encabezado.** Heredado: .NET Framework 4.8, `DataSet`,
  `SqlConnection` en el manejador del botón, C# de 2017, sin `async`. Nuevo: nullable activado, `async` de punta a punta
  con `CancellationToken`, `record` para datos, pattern matching, DI del contenedor.
- **Nunca las dos generaciones dentro del mismo archivo.** Los puntos de contacto van marcados
  con 🧬.
- **El esquema heredado conserva sus nombres** — `MOVINVEN`, `VLRUNIT`, `FECMOVTO`, `BORRADO`,
  `VENTAS_2019` — y el mapeo al modelo vive en un solo borde explícito (guía §5.1).
- Cero `.Result` y `.Wait()`; nada de `async void` fuera de un manejador de eventos.
- `decimal` para dinero; `DateTimeOffset` con desplazamiento explícito; la tasa de cambio usada
  en un cálculo se guarda con el cálculo.
- Nada de `IFooService` + `FooServiceImpl`, ni `Manager`, `Helper`, `Util`.}}

{{💸 Marcar cada deuda técnica intencional con una nota de dos partes: qué sería lo correcto, y
**en qué fase se paga**. Si no se paga, decirlo y explicar por qué.}}

**Detalles con intención**
- {{decisión deliberada del bloque anterior}} — {{su porqué}}.

**El patrón a memorizar**
> {{Una o dos frases con la lección transferible del fragmento.}}

**Prueba de fuego**
{{Verificación concreta: qué ejecutar, qué esperar, y qué mentira te va a contar la salida si
miras el lugar equivocado.}}

---

## 📏 6. Medición

{{El número que esta fase produce. El formato de abajo y las reglas de honestidad están en
`formato-de-mediciones.md`; el arnés es el mismo para todo el curso y se construye en la Fase 00.
La entrada va también a `BENCHMARKS.md`.}}

**Hipótesis:** {{la afirmación que se va a sostener o a tumbar, en una línea.}}

**Condiciones:** {{versión del SDK, máquina, tamaño del dato, número de repeticiones, qué se
mide y con qué arnés.}}

**Competidores:** {{contra qué se compara. Si el competidor es el stack de origen o el código
heredado, tiene que ser una implementación que alguien defendería en una revisión — guía §4.6.}}

**Resultado:**

| {{Opción}} | {{Métrica}} | {{Métrica 2}} |
|---|---|---|
| {{...}} | {{...}} | {{...}} |

> ⚖️ **Veredicto.** {{Qué gana, dónde pierde, y **a partir de qué umbral cambia la respuesta**.
> El umbral es obligatorio: un veredicto sin él es una preferencia — `formato-de-mediciones.md`
> §3.}}

{{Si la fase toca la base de datos, el orden es obligatorio: **primero el plan de consulta,
después .NET** — guía §4.6.}}

{{Si esta fase no mide nada, esta sección dice en una línea por qué —y esa línea tiene que ser
convincente. Una fase sin medición es la excepción, no la norma.}}

---

## 🧱 7. Miniproyecto — {{Nombre}}

{{Obligatorio, uno por fase. El formato completo, con sus reglas de calibración, está en
`formato-de-miniproyectos.md` y se sigue literal. Va aquí desarrollado, no enlazado.}}

**El encargo** · **Por qué duele** · **Datos de entrada** · **Criterios de aceptación** ·
**Restricciones de estilo y alcance** · **La trampa** · **Pistas** · **Cómo se entrega**

---

## 🧪 8. Ejercicios ({{total}})

**🟢 Fácil (1–{{a}})**
1. {{...}}

**🟡 Intermedio ({{a+1}}–{{b}})**
**🟠 Difícil ({{b+1}}–{{c}})**
**🔴 Muy difícil ({{c+1}}–{{total}})**
**🔥 Opcionales**

{{20 mínimo, 25 ideal. Escala calibrada para un dev Java senior: un 🟢 no es "copia el ejemplo",
es "aplícalo a un caso que el texto no resolvió" — guía §9. Al menos un tercio de diagnóstico o
medición, al menos dos de decisión (**¿se migra, se envuelve o se deja quieto?**) y, desde el
bloque de migración, al menos uno de generación 🧬.}}

---

## 📚 9. Referencias

**Documentación oficial**
- {{URL completa}} — {{nota de versión; recordar fijar la versión en el selector de
  learn.microsoft.com, que por defecto sirve la más reciente}}

**Especificación y propuestas del lenguaje** (cuando expliquen el porqué de un diseño)
- {{...}}

**Libros / artículos** (si aplican)
**Video / apoyo**

**Orden de lectura sugerido:** {{qué leer antes de escribir código → qué consultar durante → a
qué volver después}}

> ⚠️ {{URLs, títulos y contenidos pueden haber cambiado; el lector debe verificarlos. No se
> inventan páginas, ISBN ni identificadores de video. Advertir cuando un enlace describa .NET
> Framework y no .NET moderno, que en este curso pasa seguido.}}

---

## 🚀 10. Cierre y conexión con la siguiente fase

{{Qué quedó construido, en qué quedó el proyecto que avanzó, y por qué la Fase {{siguiente}} es
el paso natural: qué necesita de esta fase para existir.}}

> **La señal de que quedó bien:** {{criterio en forma de cita — cómo se siente el trabajo bien
> hecho de esta fase.}}

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-{{NN}} -m "F{{N}} cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la fase llevan su prefijo (`fase {{NN}}: …`), los de ejercicio su número
> (`fase {{NN}} ej12: …`) y el miniproyecto el suyo (`fase {{NN}} mini: …`). El miniproyecto
> terminado lleva además su tag anotado `mini-{{NN}}`, y **en el mensaje de ese tag va el
> número que arrojó su medición** — es donde se recupera después con `git show`.
>
> {{Si la fase tiene algo propio que decir sobre git —paga una deuda 💸 declarada antes y el
> diff entre dos tags es la factura, ejecuta un paso de migración con vuelta atrás— va un
> párrafo corto acá, no un bloque nuevo.}}

---

## 📌 Pendientes sugeridos

{{Material de autoría, no de lectura. Lo que apareció al escribir la fase y no cabía adentro,
con destino explícito: otra fase, un ejercicio 🔥, una medición que falta, una entrada nueva de
`BENCHMARKS.md` o una decisión de proyecto. **Nunca "un apéndice": no existen.**}}
````

---

## Recordatorios al rellenar una fase

- **Declara el estilo de la fase en el encabezado.** Es lo primero que el lector necesita
  saber, y lo que evita que copie el `DataSet` del bloque de migración dentro de un servicio
  nuevo — o al revés, que "arregle de paso" un formulario de 2017 y rompa otras tres cosas.
- **Declara el proyecto que avanza, y hazlo avanzar de verdad.** Una fase que no mueve ningún
  proyecto está mal ubicada en la secuencia y se replantea antes de escribirla.
- El número de fases y sus nombres salen de `propuesta-fases-y-alcance.md`. Ninguna fase se
  renumera por su cuenta.
- No contradecir nombres de proyectos, clases, tablas ni modelos definidos en fases previas.
  Ante la duda, revisar el entregable anterior y el diccionario de la guía §5.2.
- **Cada fase produce una medición**, y la excepción se justifica en una línea. El número va
  también a `BENCHMARKS.md`.
- **Cada fase produce un miniproyecto**, y no se resuelve copiando la fase. Si se resuelve
  copiando la fase, está mal calibrado: `formato-de-miniproyectos.md` §3.
- Las versiones salen de `alcance-del-proyecto.md` §9. Ninguna se da por buena de memoria y
  ninguna se verifica contra un sistema externo.
- Coherencia de la ficción: Cordillera es del curso. Si una fase afirma que algo está así en
  SIGE, tiene que poder mostrarlo (guía §11), la cronología es fija y nadie es el villano.
- **Si aparece material que "sería un buen apéndice"**, tiene tres destinos legítimos: sección
  de esta fase, fase propia, o 📌 con su razón escrita.
