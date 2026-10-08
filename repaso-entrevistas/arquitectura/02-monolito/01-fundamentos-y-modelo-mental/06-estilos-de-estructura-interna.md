# 06 — Estilos de estructura interna: capas, clean, onion y vertical slice

Aprenderás a elegir cómo se organiza el código **dentro** de un despliegue y qué garantiza cada
estilo: hacia dónde apuntan las dependencias, dónde vive la lógica y qué cambio queda localizado.
Ninguno de estos estilos es una topología, y ninguno, por sí solo, produce un monolito modular.

## 1. 🎯 Cuatro nombres para una pregunta

Un equipo de ocho personas hereda el monolito de comercio organizado en `controllers/`, `services/`
y `repositories/`. Añadir la expiración de reservas tocó nueve archivos repartidos en cuatro capas y
en dos capacidades, `orders` e `inventory`. En la retrospectiva aparecen tres propuestas: el nuevo
tech lead quiere *clean architecture*, una desarrolladora propone *vertical slices* y el arquitecto
dice que lo que falta es hexagonal.

Las tres responden a preguntas distintas, y ninguna responde a la que causó los nueve archivos: por
dónde pasa el límite entre `orders` e `inventory`. Esa es la decisión de
[módulos por capacidad](../02-modularidad-y-limites-internos/01-modulos-alrededor-de-capacidades-de-negocio.md).
Este capítulo trata la otra: una vez elegido el límite, cómo se organiza lo que queda dentro.

## 2. 🧠 Tres ejes que no hay que mezclar

```text
eje 1 — cómo se corta el árbol       por capa técnica ··· por caso de uso ··· por capacidad
eje 2 — hacia dónde apuntan imports  hacia la persistencia ··· hacia el dominio
eje 3 — dónde vive la lógica         Transaction Script ··· Active Record ··· Domain Model
```

- **Capas clásicas** responden al eje 1 con «por capa técnica» y al eje 2 con «hacia abajo, hasta
  la base».
- **Clean** y **onion** responden al eje 2: las dependencias apuntan hacia el dominio. No dicen nada
  del eje 1; se pueden aplicar a un árbol entero o dentro de cada módulo.
- **Vertical slice** responde al eje 1 con «por caso de uso» y deja el eje 3 a criterio de cada
  slice.
- **Transaction Script, Active Record y Domain Model** responden al eje 3.

La confusión habitual es comparar respuestas de ejes distintos como si fueran rivales. Un módulo
`inventory` puede tener slices por caso de uso, un Domain Model para las reservas y dependencias
que apuntan hacia ese modelo: tres decisiones compatibles.

## 3. 🧱 Capas: la regla real

Una arquitectura por capas separa presentación, aplicación, dominio y acceso a datos, con una regla:
cada capa depende solo de las de abajo. En la versión **estricta**, solo de la inmediatamente
inferior; en la **relajada**, de cualquiera inferior.

```text
CreateOrder atraviesa todas las capas y comparte cada una con otras capacidades
controllers/   OrderController      InventoryController    PaymentController
services/      OrderService    ──►  InventoryService   ──► PaymentService
repositories/  OrderRepository      InventoryRepository    PaymentRepository
models/        Order  ◄──────────── entidades JPA compartidas por todos ─────────►
```

- **Qué garantiza:** que la presentación no toca la base directamente y que las responsabilidades
  técnicas están separadas. Reemplazar la capa web o probarla sin base es razonable.
- **Qué no garantiza:** límites entre capacidades. `OrderService` puede llamar a
  `InventoryRepository`, y nada en la regla de capas lo impide.
- **Dónde falla en la práctica:** el dominio depende de la persistencia, porque las entidades del
  ORM son el modelo. Un cambio de esquema sube hasta las reglas de negocio.

Capas no es mal diseño: para un dominio pequeño o CRUD, con un equipo que cabe en una reunión, es la
estructura más barata de entender. Se vuelve un problema cuando el sistema crece por capacidades y la
unidad de cambio real —una capacidad— queda repartida en todas las capas.

## 4. 🧅 Clean y onion: invertir la dependencia

*Onion architecture* (Jeffrey Palermo, 2008) pone el modelo de dominio en el centro, lo rodea de
servicios de dominio y de aplicación, y deja infraestructura e interfaz de usuario en el anillo
exterior. *Clean architecture* (Robert C. Martin, 2012) propone entidades, casos de uso, adaptadores
de interfaz y frameworks. Las dos comparten la **regla de dependencias**: el código fuente solo
apunta hacia dentro. Lo de fuera implementa interfaces que define lo de dentro.

```text
┌─ infraestructura: controlador web, repositorio JPA, cliente del PSP ──────┐
│  ┌─ aplicación: CreateOrder y los puertos que necesita ────────────────┐  │
│  │  ┌─ dominio: Order, InventoryReservation, reglas de reserva ─────┐  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
los imports apuntan hacia dentro; el repositorio JPA implementa un puerto de aplicación
```

- **Qué garantiza:** el dominio no conoce la base, el framework web ni el proveedor de pagos, así que
  se prueba sin infraestructura y un cambio de tecnología queda en el anillo exterior.
- **Qué cuesta:** interfaces para cada dependencia externa, mapeo entre el modelo de dominio y el de
  persistencia, y más archivos por caso de uso. En un CRUD sin reglas, todo eso es ceremonia.

**Hexagonal** —*ports and adapters*, de Alistair Cockburn— comparte la regla de dependencias, pero no
habla de anillos concéntricos: distingue un interior y sus puertos, y adaptadores que conducen la
aplicación o son conducidos por ella. Clean prescribe además capas internas —entidades frente a casos
de uso— que hexagonal no exige. Decir que son «lo mismo con otro nombre» acierta en la regla y falla
en el modelo; herramientas como ArchUnit las tratan como sinónimos en su API precisamente porque
verifican solo la regla. El curso de arquitectura hexagonal del repositorio da la profundidad de
puertos y adaptadores; aquí basta con saber qué garantía comparten.

## 5. 🍰 Vertical slice: el corte por caso de uso

*Vertical slice architecture*, como la describe Jimmy Bogard, organiza el código por petición o
caso de uso: cada slice contiene desde la entrada hasta el acceso a datos, y se minimiza lo que los
slices comparten entre sí. Cada slice elige su propia técnica interna: un Transaction Script para un
listado, un Domain Model para una confirmación con reglas.

```text
orders/
├── create_order/        entrada · validación · handler · SQL propio
├── cancel_order/        entrada · handler · regla de cancelación
└── list_orders/         consulta directa, sin capa de servicio
```

- **Qué garantiza:** un cambio en un caso de uso queda en su carpeta; no hay una capa de servicios
  compartida que crece con cada funcionalidad.
- **Qué no garantiza:** límites entre capacidades ni propiedad de datos. Un slice de `orders` puede
  escribir las tablas de `inventory` igual que un servicio en capas. Y la lógica común a varios
  slices tiene que ir a algún sitio —normalmente a un modelo de dominio compartido dentro del
  módulo—, o se duplica.

Por eso «vertical slice elimina la necesidad de límites» es falso: organiza el interior de una
capacidad, no sustituye la frontera entre capacidades.

## 6. 🧮 Dónde vive la lógica

| Patrón | Qué es | Cuándo encaja | Qué cobra al crecer |
|---|---|---|---|
| Transaction Script | un procedimiento por operación, que lee, decide y escribe | operaciones simples y pocas reglas | reglas duplicadas entre scripts |
| Active Record | un objeto por fila, con datos, persistencia y algo de comportamiento | CRUD con reglas cercanas a la tabla | dominio acoplado al esquema |
| Domain Model | objetos con comportamiento, independientes de la persistencia | invariantes complejas y vocabulario rico | mapeo y más código |

Los tres patrones son de Martin Fowler, en *Patterns of Enterprise Application Architecture*. No se
elige uno para todo el sistema: `list_orders` puede ser un script de diez líneas y la confirmación de
un pedido, un modelo con invariantes. Lo que conviene evitar es un Domain Model anémico —objetos sin
comportamiento— envuelto en la ceremonia de clean: paga el mapeo sin obtener el modelo.

## 7. 📏 Qué estilo tolera qué equipo y qué dominio

| Situación | Estructura proporcional | Señal para revisar |
|---|---|---|
| equipo pequeño, dominio CRUD | capas simples, Transaction Script o Active Record | reglas que se duplican entre servicios |
| reglas complejas en una capacidad | Domain Model con dependencias hacia el dominio dentro de ese módulo | mapeos que nadie usa para aislar nada |
| muchas funcionalidades que cambian por separado | slices dentro de cada capacidad | lógica común copiada en varios slices |
| varios equipos o varias capacidades | módulos por capacidad primero; el estilo, dentro de cada módulo | cambios que cruzan módulos con frecuencia |

La última fila es la importante. Un monolito modular necesita límites por capacidad, API interna,
propiedad de datos y controles que los hagan cumplir; eso es el bloque 02. Una *clean architecture*
con un único anillo de dominio que contiene todo `orders`, `inventory`, `payments` y
`notifications` está bien estratificada y sigue siendo, por capacidades, una bola de barro.

## 8. 🧰 Plataformas

| Plataforma | Cómo se expresa el estilo | Qué hace cumplir la regla | Trampa frecuente |
|---|---|---|---|
| Java | paquetes por anillo o por slice; módulos de build o JPMS | ArchUnit con `layeredArchitecture()` y `onionArchitecture()`; JPMS con `exports` | entidades JPA usadas como dominio: el anillo interior anotado con la persistencia |
| Node/TypeScript | carpetas y `index.ts` por anillo o slice; paquetes del workspace | ESLint `no-restricted-imports` o dependency-cruiser | un barrel que reexporta todo y borra los anillos |
| Go | un package por anillo o por slice | el compilador prohíbe ciclos de import; `internal/`; depguard en golangci-lint | un package `models` compartido que todos importan |
| Python | paquetes por anillo o por slice | import-linter con contratos `layers` o `forbidden` | ciclos de import «resueltos» con imports dentro de funciones |

Las cuatro plataformas pueden expresar cualquiera de los estilos, y en las cuatro la regla de
dependencias solo existe si una herramienta la comprueba en CI. Go es el caso particular: su
compilador rechaza los ciclos de import, lo que obliga a decidir la dirección de las dependencias
antes, aunque no dice cuál es la correcta. El resto necesita una regla escrita; sin ella, el estilo
dura hasta el primer atajo con prisa.

## 9. ⚖️ Decisión y coste

Primero el límite por capacidad; después el estilo interno de cada módulo, según su dominio. Capas
simples para lo que es CRUD, dependencias hacia el dominio donde hay invariantes que merecen
aislarse de la infraestructura, slices donde las funcionalidades cambian por separado. Cada estilo
paga algo: clean y onion, interfaces y mapeo; vertical slice, lógica común que hay que ubicar;
capas, un dominio acoplado a la persistencia. Elegir uno para todo el sistema por uniformidad suele
pagar el coste más alto donde menos se necesita.

## ⚠️ Errores frecuentes

- «Clean y hexagonal son lo mismo con otro nombre». Comparten la regla de dependencias; clean
  prescribe capas internas y hexagonal, puertos y adaptadores sin anillos.
- «Capas equivale a mal diseño». Para un dominio pequeño o CRUD es la estructura más barata; el
  problema aparece cuando la capacidad queda repartida en todas las capas.
- «Vertical slice elimina la necesidad de límites». Organiza el interior de una capacidad; la
  frontera entre `orders` e `inventory` y la propiedad de sus datos siguen haciendo falta.
- «Con clean architecture el monolito ya es modular». Un anillo de dominio con todas las capacidades
  dentro es una bola de barro bien estratificada.
- «Hay que elegir un estilo para todo el sistema». Cada módulo puede tener el suyo; la uniformidad
  no es una garantía.

## 10. ✅ Veredicto

Separa las tres decisiones: cómo se corta el árbol, hacia dónde apuntan las dependencias y dónde
vive la lógica. Decide primero los límites por capacidad —ese es el bloque 02— y elige después, por
módulo, el estilo que su dominio justifique. Hazlo cumplir con una regla en CI. Un estilo interno
bien aplicado ordena el código de una capacidad; no convierte un sistema sin límites en un monolito
modular.

## 📚 Referencias

- [Presentation Domain Data Layering, Martin Fowler](https://martinfowler.com/bliki/PresentationDomainDataLayering.html)
- [The Clean Architecture, Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [The Onion Architecture: part 1, Jeffrey Palermo](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/)
- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)
- [Vertical Slice Architecture, Jimmy Bogard](https://www.jimmybogard.com/vertical-slice-architecture/)
- [Transaction Script](https://martinfowler.com/eaaCatalog/transactionScript.html), [Active Record](https://martinfowler.com/eaaCatalog/activeRecord.html) y [Domain Model](https://martinfowler.com/eaaCatalog/domainModel.html), Martin Fowler
- [ArchUnit User Guide: Architectures](https://www.archunit.org/userguide/html/000_Index.html#_architectures)
- [ESLint: no-restricted-imports](https://eslint.org/docs/latest/rules/no-restricted-imports)
- [Import Linter: Layers contract](https://import-linter.readthedocs.io/en/stable/contract_types/layers/)

## 🧠 Preguntas

1. 🟢 ¿Qué tres ejes de decisión mezcla la discusión entre capas, clean, onion y vertical slice?
2. 🟢 ¿Cuál es la regla de una arquitectura por capas y qué diferencia hay entre la versión estricta y la relajada?
3. 🟢 ¿Qué es la regla de dependencias que comparten clean y onion?
4. 🟢 ¿Qué es una vertical slice y qué contiene?
5. 🟢 ¿Qué diferencia hay entre Transaction Script, Active Record y Domain Model?
6. 🟢 ¿Qué diferencia hay entre paquete por capa y paquete por capacidad?
7. 🟢 ¿Por qué ninguno de estos estilos es una topología?
8. 🟡 ¿Qué garantiza una arquitectura por capas y qué no garantiza?
9. 🟡 ¿En qué se parecen y en qué se diferencian clean y hexagonal?
10. 🟡 ¿Qué cuesta invertir la dependencia hacia el dominio y cuándo ese coste es ceremonia?
11. 🟡 ¿Por qué vertical slice no elimina la necesidad de límites entre capacidades?
12. 🟡 ¿Dónde pondrías la lógica común a varios slices de `orders`?
13. 🟡 ¿Por qué usar entidades del ORM como modelo de dominio rompe el anillo interior?
14. 🟡 ¿Cuándo es un Domain Model anémico peor que un Transaction Script honesto?
15. 🟡 ¿Por qué una *clean architecture* puede ser, por capacidades, una bola de barro?
16. 🟡 ¿Puede cada módulo de un monolito modular usar un estilo interno distinto?
17. 🟡 ¿Qué cambia en la regla de dependencias entre un proyecto Go, donde el compilador prohíbe ciclos, y uno TypeScript, donde no?
18. 🟡 ¿Qué verifican ArchUnit en Java e import-linter en Python, y qué dejan fuera?
19. 🟠 Añadir la expiración de reservas tocó nueve archivos en cuatro capas. ¿Qué estilo lo arreglaría y qué comprobarías antes?
20. 🟠 El tech lead propone migrar todo el monolito a *clean architecture* en un trimestre. ¿Qué preguntas harías?
21. 🟠 Un equipo organizó `orders` en slices y ahora cada slice valida el pedido a su manera. ¿Qué harías?
22. 🟠 Quieres introducir la regla de dependencias en un módulo existente sin frenar al equipo. ¿Cómo lo harías de forma reversible?
23. 🟠 Dos desarrolladores discuten si `inventory` debe ser capas o hexagonal. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que un módulo necesita pasar de Transaction Script a Domain Model?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [05 — Cuándo elegir un monolito y antipatrones](05-cuando-elegir-un-monolito-y-antipatrones.md).

**Siguiente:** [07 — Simulación de entrevista: Fundamentos y modelo mental](07-simulacion-de-entrevista.md).
