# 02 — Diseñar un monolito modular desde cero

Aprenderás a construir el mínimo límite verificable para `orders`, `inventory`, `payments` y
`notifications` en un sistema nuevo: qué decidir el primer día, qué dejar explícitamente para después
y cómo demostrar que el límite existe antes de que el código crezca.

## 1. 🎯 Síntoma y decisión

Un equipo de seis personas empieza la plataforma de comercio desde cero y ya decidió, con la matriz
del capítulo anterior, un despliegue único. Queda el diseño interno, y las propuestas van de un
extremo al otro. Una desarrolladora quiere cuatro servicios «pero dentro del mismo JAR», cada uno con
su API REST interna. Otro prefiere un solo paquete `service` y organizar «cuando crezca». El arquitecto
pide un broker para los eventos internos desde el primer sprint.

Las tres propuestas fallan en lo mismo: ninguna dice qué debe quedar protegido desde el primer día y
qué puede esperar. La decisión de este capítulo es cuál es el diseño mínimo que protege las
garantías y los límites, y cuál es la lista de decisiones que se aplazan a propósito.

## 2. 🧠 Modelo mental

El diseño inicial separa lo que es caro de cambiar después de lo que es barato. Los límites de
datos y la identidad de las operaciones son caros de introducir tarde; el broker, las bases separadas
y los despliegues por módulo se añaden cuando una restricción los pide.

```text
composición del ejecutable
  └─ CreateOrder (orders)
       ├─ API de inventory: ReserveInventory            llamada local, misma transacción
       ├─ intención durable para payments: AuthorizePayment   fila de trabajo, fuera del commit
       └─ trabajo durable para notifications: NotifyCustomer  fila de trabajo, tras confirmar
```

Las flechas indican colaboración en runtime, no imports entre implementaciones. `orders` posee el
pedido y su estado comercial; `inventory`, stock y reservas; `payments`, intentos y referencias del
proveedor; `notifications`, entregas y preferencias de canal. Las tablas pueden compartir base, pero
ningún módulo toma la autoridad de escritura de otro.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | las reglas de reserva y de autorización tienen responsables distintos en negocio; la primera política nueva previsible —expiración de reservas— es de `inventory`; el pago depende de un proveedor externo con resultado incierto; todavía no hay carga medida ni un segundo equipo |
| Inferencia | cuatro capacidades candidatas con dueños de datos distintos; ninguna necesita todavía despliegue, base o transporte propios |
| Diagnóstico | hacen falta límites de código y de datos desde el principio; la distribución interna sería coste sin compra |
| Recomendación | cuatro módulos con API interna, dueño de tablas y una regla en CI que falle al violarlos; identidad de operación y pago durable desde el primer día; broker, bases y despliegues por módulo aplazados con criterio de revisión |

Las cifras son supuestos del ejercicio. Qué refutaría el mapa: si los primeros cambios reales
cruzan siempre el mismo límite —por ejemplo, cada política de reserva obliga a tocar `orders`—, el
corte está mal y se revisa antes de multiplicar interfaces. La definición dueña de
[módulo por capacidad](../02-modularidad-y-limites-internos/01-modulos-alrededor-de-capacidades-de-negocio.md)
evita volver a diseñarlo por capas técnicas.

## 4. 🛠️ Flujo, composición y aplazamientos

**El flujo de `CreateOrder`.** La transacción local crea el pedido pendiente y la reserva mediante la
API de `inventory`, con la misma conexión bajo un coordinador explícito, y registra el trabajo para
`payments`. Si falla la reserva, se revierten esas escrituras; si falla el proveedor después, se
aplica la [recuperación remota](../04-monolito-distribuido/05-fallos-parciales-retries-y-falsas-transacciones.md).
Solo cuando `orders` confirma su estado se programa el aviso. Notificar no decide si hay stock.

**La raíz de composición.** Un único lugar del ejecutable crea las implementaciones y las conecta. El
módulo consumidor conoce resultados estables, no entidades ORM ni clientes SQL ajenos. No se añade
HTTP entre módulos —un proceso no gana nada serializando llamadas a sí mismo— ni una interfaz por
cada clase: una API existe cuando delimita conocimiento o permite una sustitución concreta.

**Lo que no se aplaza.** La identidad de las operaciones —claves de idempotencia en pagos—, la
recuperación del pago incierto y la autoridad de escritura de cada tabla. Son baratas al principio y
muy caras de introducir con datos en producción.

**Lo que se aplaza, con criterio.** Broker, bases físicas separadas y despliegues por módulo esperan a
una restricción que los justifique. El criterio de revisión es un cambio transversal recurrente o un
recurso compartido que incumple el SLO. Si basta una llamada local y una tabla de trabajo, el diseño
se detiene ahí.

## 5. 💻 Esqueletos mínimos

Java 17 o posterior, archivo `ReserveInventory.java` dentro de un paquete público de API. La
implementación y el repositorio viven en el paquete interno del módulo; estas declaraciones son la
frontera, no una aplicación transaccional completa.

```java
package commerce.inventory.api;
public interface ReserveInventory {
    record Request(String orderId, String sku, int units) {
        public Request {
            if (orderId == null || orderId.isBlank() || sku == null || sku.isBlank()
                    || units <= 0) throw new IllegalArgumentException("invalid reservation");
        }
    }
    enum Result { RESERVED, OUT_OF_STOCK }
    Result reserve(Request request);
}
```

- El `record` con constructor compacto valida la petición en la frontera: una reserva de cero
  unidades no llega a la implementación.
- `Result` es cerrado: `orders` decide con él sin conocer tablas ni excepciones internas.
- En Java, un subpaquete `internal` no hereda privacidad; lo que impide a `orders` usarlo es la regla
  arquitectónica de la sección 6.

TypeScript, la misma API expresada como función. La validación de la solicitud ocurre en la frontera
de runtime que la recibe; el ejemplo solo muestra la composición local.

```typescript
export type ReservationRequest = Readonly<{
  orderId: string; sku: string; units: number;
}>;
export type ReserveInventory =
  (request: ReservationRequest) => Promise<"RESERVED" | "OUT_OF_STOCK">;

export function createPreparation(reserve: ReserveInventory) {
  return (request: ReservationRequest) => reserve(request);
}
```

- `Readonly` impide que el consumidor modifique la petición después de enviarla; no la valida.
- La unión de literales cumple el papel del `enum` de Java: `orders` solo puede recibir esos dos
  resultados.
- `createPreparation` recibe la función de reserva ya construida: la raíz de composición decide la
  implementación.

Ningún fragmento impide la sobreventa: la implementación SQL, la unicidad por pedido y la transacción
se prueban con [concurrencia real](../03-datos-ejecucion-y-operacion/02-concurrencia-locking-e-idempotencia.md).
**Validación.** El 2026-09-29 el esqueleto Java se compiló con `javac 25.0.4 -Xlint:all` y una
petición de cero unidades se rechazó con `invalid reservation`; el TypeScript pasó `tsc 5.8.3 --strict`
sin errores.

## 6. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | paquetes, visibilidad y módulos del build, más una regla arquitectónica | la propiedad de las tablas | hacer `public` toda la implementación |
| Node/TypeScript | `exports` del paquete y *project references* | validar objetos que llegan por la red | importar rutas internas por atajo |
| Go | un paquete por capacidad e `internal/` | diseñar el grafo de dependencias | una interfaz gigante por módulo |
| Python | paquetes con API publicada por convención, más contratos de importación | privacidad fuerte | importar los modelos internos directamente |

En las cuatro plataformas el límite necesita dos cosas: un mecanismo del lenguaje o del build y una
prueba que falle cuando se viola. Se empieza con un repositorio y un artefacto reproducible, se usa
el [control arquitectónico ya elegido](../02-modularidad-y-limites-internos/06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md)
para prohibir imports de `inventory.internal` desde `orders` y se provoca una infracción deliberada
para comprobar que el control la detecta. Go es el único donde el compilador hace cumplir `internal/`
sin herramienta adicional.

## 7. ⚖️ Decisión y coste

Diseña una capacidad, un dueño y una API por razón de cambio, con una regla que falle cuando se viola
y una prueba de integración que demuestre el rollback conjunto de pedido y reserva. Pagas
mantenimiento de APIs internas, mapeos y controles; compras cambios contenidos y una frontera lista
si algún día hay que extraer. No pagues todavía broker, bases separadas ni HTTP interno: son costes
sin restricción que los compre.

## ⚠️ Errores frecuentes

- «Cuatro servicios dentro del mismo JAR, cada uno con REST interno». Paga serialización y semántica
  remota sin ganar despliegue independiente.
- «Ya organizaremos cuando crezca». Los límites de datos y la identidad de las operaciones son caros
  de introducir con datos en producción.
- «Un broker desde el primer sprint prepara el futuro». Añade operación, orden y entrega que nadie
  necesita todavía; una tabla de trabajo cubre la asincronía local.
- «Una carpeta por módulo es un módulo». Sin API y sin una regla que falle, la carpeta se atraviesa al
  primer atajo con prisa.
- «El esqueleto de la API garantiza el stock». La API delimita; la garantía la dan la implementación
  SQL, la transacción y sus pruebas de concurrencia.

## 8. ✅ Veredicto

Empieza con cuatro módulos, sus APIs, sus dueños de datos y una regla en CI que falle al violarlos;
protege desde el primer día la identidad de las operaciones y el pago incierto. Aplaza con criterio
escrito todo lo que distribuye. Y deja que los cambios reales cuestionen el mapa: el diseño inicial
es una hipótesis que se revisa con evidencia, no un plano definitivo.

## 📚 Referencias

- [Record Classes, Java 17](https://docs.oracle.com/en/java/javase/17/language/records.html)
- [Controlling Access to Members of a Class, Oracle Java Tutorials](https://docs.oracle.com/javase/tutorial/java/javaOO/accesscontrol.html)
- [Project References, TypeScript](https://www.typescriptlang.org/docs/handbook/project-references)
- [Organizing a Go module, Go](https://go.dev/doc/modules/layout)
- [Modules, Python Tutorial](https://docs.python.org/3/tutorial/modules.html)

## 🧠 Preguntas

1. 🟢 ¿Qué responsabilidad inicial das a `orders` y qué no le das?
2. 🟢 ¿Qué pertenece a `inventory`?
3. 🟢 ¿Qué es la raíz de composición?
4. 🟢 ¿Qué garantiza el esqueleto de la API y qué no garantiza?
5. 🟢 ¿Qué primera regla arquitectónica añadirías?
6. 🟡 ¿Por qué no devolverías la entidad ORM de stock a `orders`?
7. 🟡 ¿Cuándo participan pedido y reserva en el mismo commit?
8. 🟡 ¿Qué dejas fuera de ese commit y cómo lo recuperas?
9. 🟡 ¿Cuándo emite `orders` el aviso de confirmación?
10. 🟡 ¿Por qué no introducir REST interno entre módulos del mismo proceso?
11. 🟡 La primera política nueva toca los cuatro módulos. ¿Qué harías?
12. 🟡 ¿Qué aplazarías explícitamente y qué no aplazarías nunca?
13. 🟡 ¿Cómo construirías la primera prueba de rollback conjunto de pedido y reserva?
14. 🟡 ¿Qué diferencia hay entre un módulo del build y una capacidad?
15. 🟡 ¿Cuándo compartirías un tipo entre módulos?
16. 🟡 ¿Cómo preparas opciones futuras sin sobrediseñar?
17. 🟡 ¿En qué se parecen y en qué se diferencian el `record` de Java y el `Readonly` de TypeScript como frontera?
18. 🟠 ¿Cómo expresarías el mismo límite en Go y en Python, y qué cambia en cómo se hace cumplir?
19. 🟠 ¿Qué ocurre si dos réplicas reservan a la vez el último stock con este diseño?
20. 🟠 ¿Cómo revertirías un límite que resultó incorrecto después de unos meses?
21. 🟠 La CI detecta un acceso a los internos de `inventory` que parece necesario. ¿Qué haces?
22. 🟠 La tabla de trabajo de `notifications` empieza a acumular filas. ¿Qué pasa y qué haces?
23. 🟠 Un compañero quiere una interfaz para cada clase «por si acaso». ¿Cómo respondes?
24. 🟠 ¿Cuándo consideras suficiente el diseño inicial?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [01 — Monolito, monolito modular o servicios: matriz de decisión](01-monolito-monolito-modular-o-servicios-matriz-de-decision.md).

**Siguiente:** [03 — Recuperar modularidad en un monolito legado](03-recuperar-modularidad-en-un-monolito-legado.md).
