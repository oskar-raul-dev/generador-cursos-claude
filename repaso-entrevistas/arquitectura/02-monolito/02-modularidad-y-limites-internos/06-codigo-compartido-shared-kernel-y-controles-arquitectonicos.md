# 06 — Código compartido, *shared kernel* y controles arquitectónicos

Aprenderás a compartir de forma deliberada sin crear un módulo `common` que posea todo. Compartir
reduce duplicación, pero convierte cada consumidor en parte del coste de cambio; por eso el alcance,
el ownership y las excepciones necesitan controles explícitos.

## 1. 🎯 El cajón `common`

Primero contiene `Money` y `Clock`. Después recibe `Order`, validadores, helpers de ORM, eventos y
reglas de promociones. `orders`, `payments` e `inventory` importan el paquete; ningún equipo puede
cambiarlo sin revisar a todos.

```text
orders ─────┐
payments ───┼──► common ──► ORM, modelo canónico, utilidades, eventos
inventory ──┘
```

Se eliminó duplicación textual a costa de una dependencia central con muchas razones de cambio.
DRY evita repetir conocimiento, no obliga a centralizar código que solo se parece.

## 2. 🧩 Cuatro clases de reutilización

| Clase | Ejemplo | Política recomendada |
|---|---|---|
| *Shared kernel* | `Money` acordado entre `orders` y `payments` | límite pequeño, owners conjuntos |
| Utilidad técnica | reloj, ID, resultado básico | estable, sin reglas de negocio |
| Plataforma interna | logging, tracing, config | API técnica y ciclo propio |
| Duplicación consciente | DTO local de dirección | aceptar y revisar divergencia |

Un *shared kernel* es un subconjunto explícito del modelo que varios contextos acuerdan compartir.
Los equipos coordinan sus cambios y pruebas. No es el nombre elegante de `common`: cuanto mayor es,
menor es la independencia de sus consumidores.

## 3. ⚖️ Compartir o duplicar

Comparte cuando el concepto tiene significado realmente común, cambia poco y divergir rompería una
invariante. Duplica cuando cada módulo necesita una representación local, el mapeo es barato y la
coordinación central costaría más que una divergencia controlada.

Ejemplo: `payments` y `orders` pueden compartir una representación mínima de moneda y redondeo si una
diferencia produciría cobros incorrectos. `notifications` puede copiar nombre y email del cliente
en su propio mensaje; no necesita importar el agregado `Customer`.

## 4. 👥 Ownership y evolución

Todo código compartido declara:

- consumidores permitidos y propósito;
- uno o varios owners con autoridad de aceptación;
- compatibilidad o migración esperada;
- pruebas que ejecutan contra consumidores relevantes;
- criterio para extraer, dividir o duplicar;
- fecha de revisión si nació como excepción.

Dentro de un único artefacto, normalmente no necesitas versionado semántico interno: cambia y migra
los consumidores en un commit. Si diferentes artefactos consumen la librería, el versionado aparece,
pero no elimina el acoplamiento; solo permite coordinarlo de forma explícita.

## 5. 🧱 Reglas como código

Una regla útil expresa una decisión concreta:

```text
permitido:  orders ─► shared.money
prohibido:  shared ─► orders
prohibido:  cualquier módulo ─► */internal/* ajeno
temporal:   reports ─► inventory/internal/sql  hasta 2026-11-15, owner Data
```

Aplica primero a nuevas violaciones. Un baseline conserva deuda conocida sin fingir que está
resuelta. Las excepciones deben ser estrechas, observables y caducar; un comodín permanente convierte
la regla en decoración.

## 6. 🧰 Controles verificados por plataforma

| Plataforma | Control candidato | Fortaleza | Límite |
|---|---|---|---|
| Java | ArchUnit 1.5.1 y JPMS | bytecode, paquetes, ciclos y exports | reflexión y datos requieren otras pruebas |
| Node/TypeScript | dependency-cruiser y project references | imports, ciclos y build lógico | runtime dinámico puede escapar |
| Go | packages `internal`, compilador y `depguard` | ciclos e imports permitidos | no modela SQL ni cohesión |
| Python | Import Linter | contratos de capas/independencia | convenciones e imports dinámicos reducen cierre |

Las capacidades se verificaron el 2026-09-27. No añadas cuatro herramientas a la vez: elige una
regla que proteja un límite real, intégrala en CI y registra tiempo, falsos positivos y excepciones.

## 7. 🔬 Qué una prueba arquitectónica no demuestra

Un build verde puede coexistir con escrituras cruzadas, eventos incompatibles, módulos sin cohesión
o equipos obligados a coordinar cada cambio. La prueba solo evidencia que el grafo observado cumple
una regla. Combínala con pruebas de módulo, permisos de datos y métricas de cambio.

Cuando una regla molesta repetidamente, no la desactives a ciegas. Puede haber una frontera falsa,
una herramienta mal configurada o presión por atajos. La conversación es parte del control.

## 8. ⚖️ Decisión y coste

Comparte el mínimo que represente conocimiento común valioso y paga conscientemente su coordinación.
Duplica modelos locales cuando comprar autonomía sea más barato que mantener un canónico. Automatiza
pocas reglas importantes, con baseline y excepciones caducables; no uses el test para sustituir
ownership y diseño.

## ⚠️ Errores frecuentes

- «DRY obliga a centralizar». Repetición de texto no siempre es conocimiento duplicado.
- «Todo lo compartido es *shared kernel*». Utilidades técnicas y plataforma tienen otra semántica.
- «Un test arquitectónico crea buenos límites». Solo verifica reglas declaradas.
- «Versionar una librería elimina coordinación». Hace visible su compatibilidad.
- «Duplicar siempre es deuda». Puede ser el precio deliberado de autonomía.

## 9. ✅ Veredicto

Trata cada dependencia compartida como una decisión de coordinación. Dale alcance, dueño y criterio
de evolución; mantén el *shared kernel* pequeño y estable. Usa controles de lenguaje y CI para
proteger decisiones entendidas, y combina su evidencia con datos, cambios y ownership real.

## 📚 Referencias

- [Domain-Driven Design Reference, Eric Evans](https://www.domainlanguage.com/wp-content/uploads/2016/05/DDD_Reference_2015-03.pdf)
- [ArchUnit User Guide 1.5.1](https://www.archunit.org/userguide/html/000_Index.html)
- [dependency-cruiser rules reference](https://github.com/sverweij/dependency-cruiser/blob/main/doc/rules-reference.md)
- [depguard settings, golangci-lint](https://golangci-lint.run/docs/linters/configuration/#depguard)
- [Import Linter — Layers contract](https://github.com/seddonym/import-linter/blob/main/docs/contract_types/layers.md)

## 🧠 Preguntas

1. 🟢 ¿Qué es un *shared kernel*?
2. 🟢 ¿Qué diferencia hay entre *shared kernel* y utilidad técnica?
3. 🟢 ¿Qué problema suele crear un módulo `common` sin ownership?
4. 🟢 ¿Qué significa duplicación consciente?
5. 🟢 ¿Qué debe declarar todo código compartido?
6. 🟢 ¿Qué es un baseline de violaciones?
7. 🟢 ¿Qué debe incluir una excepción arquitectónica temporal?
8. 🟡 ¿Por qué DRY no obliga a compartir dos tipos parecidos?
9. 🟡 ¿Cuándo `Money` puede pertenecer a un *shared kernel*?
10. 🟡 ¿Cuándo un DTO local es preferible a importar un modelo canónico?
11. 🟡 ¿Cómo afecta el tamaño del *shared kernel* a la autonomía?
12. 🟡 ¿Por qué versionar una librería no elimina el acoplamiento?
13. 🟡 ¿Cuándo no necesitas versionado semántico interno?
14. 🟡 ¿Qué ventaja tiene empezar el control con violaciones nuevas?
15. 🟡 ¿Qué evidencia complementa una prueba arquitectónica?
16. 🟡 ¿Qué diferencias de enforcement existen entre Java, TypeScript, Go y Python?
17. 🟡 ¿Cómo distingues una regla molesta de una regla equivocada?
18. 🟠 Cuatro módulos importan un `Order` canónico y solo usan campos distintos. ¿Qué rediseño evaluarías?
19. 🟠 Dos equipos necesitan cambiar `Money` con calendarios incompatibles. ¿Qué alternativas compararías?
20. 🟠 CI bloquea una dependencia necesaria para una migración. ¿Cómo autorizas la excepción sin normalizarla?
21. 🟠 Un paquete de logging empieza a contener reglas de auditoría de negocio. ¿Dónde ubicarías cada responsabilidad?
22. 🟠 ArchUnit está verde, pero un cambio sigue tocando cinco módulos. ¿Qué investigarías?
23. 🟠 ¿Qué criterio usarías para eliminar o dividir un *shared kernel* creciente?
24. 🟠 ¿Cómo demostrarías que una duplicación compró autonomía sin crear divergencia peligrosa?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [05 — Comunicación interna: llamadas, comandos y eventos](05-comunicacion-interna-llamadas-comandos-y-eventos.md).

**Siguiente:** [07 — Simulación de entrevista: Modularidad y límites internos](07-simulacion-de-entrevista.md).
