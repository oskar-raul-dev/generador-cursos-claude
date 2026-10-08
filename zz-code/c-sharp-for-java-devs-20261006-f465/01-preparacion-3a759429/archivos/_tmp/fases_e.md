
---

### 📊 Fase 21 — Los datos que mienten, y servir un modelo con ONNX

**Entra:** separar honestamente sell-in, sell-out y devolución, por país, sello y canal, con tres
distribuidores de tres calendarios y dos plataformas que reportan en semanas ISO; la canalización
que prepara los datos; ML.NET presentado y evaluado; y **servir con ONNX Runtime un modelo
entrenado en Python**.

**No entra:** teoría de aprendizaje automático, y se declara — el repositorio tiene `cursos-ia`.

**🪞 El reflejo:** creer el número del primer mes, y entrenar donde no se debe por no salir del
ecosistema. **🩻 Se transfiere:** SQL analítico, ventanas, agregaciones.

**💸 Deuda:** el modelo se sirve sin versionar. **No se paga en este curso** y se dice por qué:
resolverlo bien es un registro de modelos, que es otro curso.

**📏 Medición:** ML.NET frente al modelo entrenado en Python y servido con ONNX —latencia,
precisión y esfuerzo—, y las dos contra **el baseline de Gustavo**, que lleva treinta y un años
decidiendo tirajes mirando la portada y el mes.

**🧱 Miniproyecto:** la canalización que separa los tres tipos de venta con calendarios distintos y
sirve la predicción de tiraje dentro del sistema. *La trampa:* las devoluciones llegan hasta el
30% y aparecen meses después — el número de marzo cambia en julio, y un modelo entrenado sin eso
aprende una mentira estacional.

> ⚖️ El veredicto de esta fase está decidido de antemano y el curso lo dice sin rodeos: para este
> trabajo, lo honesto es entrenar en Python y servir desde .NET.

---

### 🤖 Fase 22 — IA aplicada: recuperación con cita y triaje con herramientas

**Nacen los dos proyectos de IA** (§10.1): AcervoRAG y EditorAgent comparten el aparato de
evaluación, y por eso comparten fase.

**Entra:** ingesta de contratos escaneados; fragmentación y recuperación; **la cita obligatoria**
—documento, versión y cláusula, o no se responde—; un agente con herramientas que llama a
CatalogAPI; la ficha de triaje estructurada; y **evaluación de verdad**, con conjunto de prueba y
métricas.

**No entra:** afinado de modelos; entrenamiento; y el aparato de agentes más allá de lo que este
caso necesita.

**🪞 El reflejo:** montar el aparato vectorial antes de probar si la búsqueda de texto completo ya
resolvía, y dejar que el agente **decida** en vez de preparar la decisión de una persona.
**🩻 Se transfiere:** contratos, evaluación, pruebas.

**💸 Deuda:** sin caché de embeddings. Se paga a la vista, dentro de la misma fase, midiendo la
factura de reindexar.

**📏 Medición:** búsqueda de texto completo de SQL Server, búsqueda vectorial del propio SQL Server
y Azure AI Search: precisión y exhaustividad sobre un conjunto de treinta preguntas reales de
derechos, latencia y costo. **Con la posibilidad admitida de que el texto completo gane.**

**🧱 Miniproyecto:** el sistema que responde *"¿tenemos los derechos en portugués de este título
para Brasil?"* citando la cláusula, o **se niega a responder**. *La trampa:* la pregunta cuya
respuesta correcta es "no tenemos esos derechos" — el recuperador siempre encuentra algo parecido,
y una alucinación sobre un contrato no es una molestia: es una demanda, y la presidenta es
abogada.

📝 Aquí va el veredicto sobre **Semantic Kernel**: cuándo aporta orquestación real y cuándo es una
capa que te cobra abstracción sin devolverte nada frente a llamar al SDK directamente.

---

### ⚔️ Fase 23 — El duelo: ASP.NET Core contra Spring Boot

**Entra:** el endpoint crítico de CatalogAPI implementado **dos veces**, con las dos
implementaciones defendibles en una revisión de código, y la comparación completa: rendimiento,
arranque en frío, memoria, costo mensual al volumen de Cordillera, líneas de código, y facilidad
de contratar a quien lo mantenga en el mercado del lector.

**No entra:** un tercer competidor. Diluye la comparación y alarga la fase (§10.5).

**🪞 El reflejo:** comparar contra un competidor de paja, que es el reflejo de todo el que quiere
que gane su equipo. **🩻 Se transfiere:** todo — es el terreno donde el lector es experto, y eso
hace la comparación más honesta, no menos.

**📏 Medición:** la del curso entero, consolidada. Y **los empates se publican como empates**
(`formato-de-mediciones.md` §2.4): al volumen de Cordillera varias columnas van a quedar dentro
del ruido, y esa es la conclusión, no un fracaso de la medición.

**🧱 Miniproyecto:** implementar la contraparte en Spring Boot 3 y publicar la tabla. *La trampa:*
escribir un Spring Boot que tú no defenderías — sin pool configurado, sin caché, con el
serializador por defecto — y creer que mediste algo.

---

### 🏁 Fase 24 — Veredicto, defensa y qué no debió migrarse

**Entra:** la revisión de todas las decisiones del curso con los datos en la mano; el árbol de
decisión ⚖️ de cuándo **no** usar lo que el curso enseña; el checklist que el lector se lleva al
trabajo; y la tabla consolidada de `BENCHMARKS.md`.

**Lo que esta fase está obligada a admitir**, y sale de §14 de la historia:

- El *lift and shift* de 2020 fue un error, cuantificado con la factura y sin absolver a nadie
  —tampoco a quien lo aprobó por miedo, que es la razón real por la que se hizo así—.
- **Parte del sistema no debió migrarse.** El módulo de inventario funciona, no cambia, y "el Fox"
  de Lima lleva veintinueve años funcionando y puede llevar tres más.
- **La migración de los pasantes de 2016 fue, en el balance, correcta.** Fue barata, salió, y
  compró diez años.
- Y **dos decisiones del propio curso que, con los datos delante, debieron ser otras.**

**📏 Medición:** no produce una propia; consolida las veinticuatro anteriores y marca 🪦 las que
una medición posterior contradijo.

**🧱 Miniproyecto:** el documento de defensa ante la junta — qué se migró, qué no, qué costó, qué
queda pendiente y con qué riesgo—, en el lenguaje de Clara y no en el de un ingeniero. *La trampa:*
escribir un informe donde .NET moderno gana todo. Si sale así, está mal hecho, y el curso lo dice
en su última línea.
