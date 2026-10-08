# 03 — Monolito tradicional, modular y *big ball of mud*

Aprenderás a separar topología, organización interna y deterioro estructural. «Monolito», «monolito
modular» y *big ball of mud* no son etapas inevitables ni etiquetas intercambiables: cada una exige
evidencia diferente.

## 1. 🎯 Tres preguntas distintas

```text
¿cómo se despliega?       → monolito o sistema distribuido
¿cómo se limita el código?→ capas, módulos, dependencias verificables
¿cómo cambia en realidad? → localizado o enmarañado
```

Un monolito tradicional suele organizarse por capas técnicas: controllers, services y repositories.
Puede funcionar bien, pero una capacidad como `CreateOrder` atraviesa cada capa y comparte tipos con
otras capacidades. Un monolito modular organiza límites verticales alrededor de razones de cambio.

```text
por capas                         por capacidades
controllers                      orders/
services                         inventory/
repositories                     payments/
models                           notifications/
```

La segunda lista todavía no prueba modularidad. Hacen falta APIs internas deliberadas, dependencias
dirigidas, propiedad de datos y controles que detecten accesos indebidos.

## 2. 🧱 Monolito modular y *modulith*

Un monolito modular conserva una unidad de despliegue y crea unidades de cambio internas. Cada
módulo expone una superficie pequeña, oculta detalles y posee decisiones coherentes. *Modulith* es
un nombre usado para esa combinación de módulos explícitos y despliegue monolítico; no es un
framework ni una certificación automática.

La garantía conservada es la colaboración local: llamadas en proceso y, cuando corresponde,
transacciones locales. El coste es disciplina: el compilador, las pruebas o el CI deben impedir que
la comodidad del proceso compartido erosione los límites.

## 3. 🕳️ Qué es una *big ball of mud*

Foote y Yoder describen una estructura en la que cualquier parte parece depender de cualquier otra,
los límites son débiles y el conocimiento está disperso. No significa «código viejo» ni «muchas
líneas». Se observa en el trabajo:

- un cambio pequeño modifica varios dominios sin una invariante que lo justifique;
- los datos se escriben desde lugares sin propietario claro;
- aparecen ciclos y utilidades globales con reglas de negocio;
- nadie puede predecir el impacto sin ejecutar todo el sistema;
- las excepciones arquitectónicas se vuelven la ruta normal.

La causa puede incluir crecimiento apresurado, límites falsos o incentivos de entrega. El síntoma es
el cambio transversal. La consecuencia es riesgo y coordinación crecientes. La etiqueta no explica
por sí sola cuál de esas causas domina.

## 4. 📏 Un continuo, no una escalera

| Forma | Despliegue | Límite interno | Evidencia de cambio |
|---|---|---|---|
| Monolito por capas | uno | principalmente técnico | puede ser localizado o transversal |
| Monolito modular | uno | capacidades y APIs internas | cambios mayormente contenidos |
| *Big ball of mud* | uno o varios | erosionado | impacto impredecible |
| Sistema distribuido | varios | contratos remotos | autonomía por demostrar |

Un sistema distribuido también puede ser una bola de barro: la red endurece fronteras físicas, pero
no corrige ownership difuso, release trains ni modelos compartidos. Del mismo modo, un monolito por
capas pequeño puede ser la opción proporcional sin convertirse en modular por ceremonia.

## 5. 🔍 Cómo comprobar modularidad

1. Elige un cambio real, por ejemplo añadir expiración a una reserva.
2. Revisa qué archivos, tablas, pruebas y equipos modifica.
3. Dibuja imports y escrituras, no solo carpetas.
4. Identifica la API que otros módulos consumen.
5. Comprueba si una regla automatizada detectaría una violación.
6. Repite con cambios de otra volatilidad.

Una observación aislada —paquetes limpios— permite inferir intención. El diagnóstico de modularidad
requiere que los cambios se contengan y que el ownership se cumpla. La recomendación puede ser
reforzar una sola costura antes que reorganizar todo el árbol.

## 6. 🧰 Mecanismos ligeros por plataforma

| Plataforma | Límite disponible | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | paquetes, módulos de build y JPMS | ownership o cohesión | exportar todos los paquetes |
| Node/TypeScript | ES modules, packages y project references | imports profundos en runtime | un `index.ts` que reexporta todo |
| Go | paquetes, módulos y directorios `internal` | granularidad de negocio | paquete `common` omnipresente |
| Python | módulos, paquetes y API por convención | privacidad fuerte por sí sola | confiar solo en guiones bajos |

El mecanismo debe respaldar un límite entendido. Partir el build o añadir un framework antes de
descubrir razones de cambio solo solidifica una conjetura.

## 7. ⚖️ Decisión y coste

Usa módulos cuando varias capacidades cambian con ritmos o responsables distintos, pero las ventajas
de una release y runtime comunes siguen siendo valiosas. Mantén una estructura más simple cuando el
dominio y el equipo son pequeños. Si ya hay barro, crea una costura vertical con evidencia de cambio;
una reubicación masiva de carpetas es cara, difícil de revertir y no modifica dependencias por sí sola.

## ⚠️ Errores frecuentes

- «*Modulith* es un framework». Es una forma arquitectónica; las herramientas solo la apoyan.
- «Todo monolito termina siendo barro». La erosión depende de decisiones e incentivos, no del proceso único.
- «Carpetas por dominio bastan». Los imports y datos pueden ignorarlas.
- «Distribuir crea buenos límites». También puede distribuir el barro.
- «Más módulos equivalen a más autonomía». Una granularidad excesiva aumenta coordinación interna.

## 8. ✅ Veredicto

Clasifica primero la topología y después la estructura. Llama modular a lo que contiene cambios
mediante APIs, ownership y dependencias verificables; llama *big ball of mud* a un patrón sostenido de
cambio impredecible, no a algo que simplemente te disgusta. El siguiente paso debe mejorar una
costura observable, no perseguir una etiqueta.

## 📚 Referencias

- [Big Ball of Mud, Brian Foote y Joseph Yoder](https://www.laputan.org/pub/foote/mud.pdf)
- [Microservice Trade-Offs, Martin Fowler](https://martinfowler.com/articles/microservice-trade-offs.html)
- [Organizing a Go module, Go](https://go.dev/doc/modules/layout)
- [Project References, TypeScript](https://www.typescriptlang.org/docs/handbook/project-references)

## 🧠 Preguntas

1. 🟢 ¿Qué dimensión describe la palabra monolito?
2. 🟢 ¿Qué caracteriza a una organización por capas técnicas?
3. 🟢 ¿Qué caracteriza a un monolito modular?
4. 🟢 ¿Qué significa *modulith* en este recorrido?
5. 🟢 ¿Qué es una *big ball of mud*?
6. 🟢 ¿Una *big ball of mud* tiene que ser monolítica?
7. 🟢 ¿Qué es una unidad de cambio interna?
8. 🟡 ¿Por qué una carpeta por capacidad no demuestra modularidad?
9. 🟡 ¿Qué garantías conserva un monolito modular?
10. 🟡 ¿Qué disciplina adicional exige un límite dentro del mismo proceso?
11. 🟡 ¿Cómo distingues edad del sistema y deterioro estructural?
12. 🟡 ¿Qué evidencia de cambios respalda el diagnóstico de barro?
13. 🟡 ¿Por qué los ciclos son evidencia y no un diagnóstico completo?
14. 🟡 ¿Cuándo un monolito por capas puede ser suficiente?
15. 🟡 ¿Por qué distribuir puede endurecer un límite equivocado?
16. 🟡 ¿Qué demuestra un import rule y qué no demuestra?
17. 🟡 ¿Qué cambia entre un paquete Java, uno Go y un ES module como mecanismos de límite?
18. 🟠 Un cambio de precio toca doce paquetes por dominio. ¿Qué observarías antes de rediseñar?
19. 🟠 El árbol tiene carpetas perfectas, pero todos escriben todas las tablas. ¿Cómo lo diagnosticas?
20. 🟠 Un equipo quiere dividir el build en veinte módulos esta semana. ¿Qué secuencia propones?
21. 🟠 Tras extraer servicios, todos consumen una librería con el modelo canónico completo. ¿Qué mejoró y qué no?
22. 🟠 Una excepción arquitectónica lleva dos años activa. ¿Qué decisión harías visible?
23. 🟠 ¿Qué criterio usarías para detener una recuperación de modularidad?
24. 🟠 ¿Cómo defenderías duplicación pequeña frente a un módulo `common` que acopla cuatro capacidades?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [02 — Unidades de código, despliegue, ejecución y datos](02-unidades-de-codigo-despliegue-ejecucion-y-datos.md).

**Siguiente:** [04 — Acoplamiento, cohesión y razones de cambio](04-acoplamiento-cohesion-y-razones-de-cambio.md).
