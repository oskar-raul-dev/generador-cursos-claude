# POO y patrones de diseño

> Repaso para entrevistas de **Backend Senior, Arquitecto y Tech Lead**: el modelo de objetos que se aprende a los golpes,
> el modelado y los principios, los patrones del GoF, de Fowler, de DDD táctico y de concurrencia escritos en **C++ y en
> Java**, lo que cambian Go, JavaScript, TypeScript y Python, los antipatrones con su salida, y cómo se elige —o se decide no
> usar ninguno—. Todo con el mismo dominio: Ana, Luis y Carmen, sus documentos y sus cuentas.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** GCC 14.4 (C++23) · JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9) ·
> Go 1.27.1 · Node.js 24.21.0 · TypeScript 7.0.2 · Python 3.14.8 · .NET 10.0.12 (C# 14) · PostgreSQL 18.6 · mermaid-cli 11.17.0 ·
> en los talleres, Maven 3.10.0, JUnit 6.1.3 y H2 2.5.252 (2026-10-04).

**Salto rápido:** [1](#1--qué-es-y-qué-no-es) · [2](#2-️-rutas-de-estudio) · [3](#3-️-mapa-de-bloques) · [4](#4--cómo-está-hecho) · [5](#5--versiones-y-verificación) · [6](#6--qué-no-está-aquí)

---

## 1. 🧭 Qué es, y qué no es

```text
Un libro de patrones → te da el catálogo y la estructura de clases.
Este repaso          → te dice qué tensión resuelve cada patrón, cuánto le quedó vivo
                       en el lenguaje actual, y cómo se escribe y se defiende hoy.
```

- **Para quién**: alguien que ya programa en un lenguaje orientado a objetos y prepara entrevistas donde le van a pedir
  "modela esto", "¿qué patrón usarías aquí?" o "revisa este código". Java es el lenguaje de la entrevista; C++ cuenta de
  dónde viene cada patrón y qué cambia cuando hay que decidir quién es dueño de cada objeto.
- **Cómo se lee**: el problema antes que el patrón, cada diseño con su precio —indirección, acoplamiento, legibilidad,
  rendimiento— y "no usaría ningún patrón" como respuesta válida.
- **Qué no es**: un curso de UML, un catálogo para recitar ni un libro: el corpus es largo a propósito, y las rutas existen
  para no tener que leerlo entero.

---

## 2. 🛤️ Rutas de estudio

Cada ruta temática incluye **los prerrequisitos que declaran sus capítulos** (lo que cada uno dice que asume leído), así que
se puede seguir de principio a fin sin saltos. La excepción es "entrevista esta semana": sus quince capítulos se escriben para
leerse solos. Las horas salen de 2,5 h por capítulo, 3 h por simulación y 3 h por taller, con el solucionario consultado sobre
la marcha; las rutas rápidas crecieron respecto del plan inicial al incluir esos prerrequisitos.

| Ruta | Para quién | Documentos | Horas |
|---|---|---|---|
| [Completa](#ruta-completa) | Quien quiere dominar el tema | 107 | ~242 |
| [POO rápida](#ruta-poo-rápida) | Quien tiene huecos en la base o viene de otro paradigma | 20 | ~48 |
| [SOLID y diseño rápida](#ruta-solid-y-diseño-rápida) | Quien va a una entrevista de diseño o de revisión de código | 22 | ~53 |
| [Patrones rápida](#ruta-patrones-rápida) | Quien ya tiene la base y va por el catálogo | 41 | ~102 |
| [Persistencia](#ruta-persistencia) | Quien trabaja con ORMs y quiere saber qué hacen por dentro | 41 | ~98 |
| [Concurrencia](#ruta-concurrencia) | Quien necesita los patrones de concurrencia | 23 | ~56 |
| [Políglota](#ruta-políglota) | Quien trabaja en varios lenguajes | 36 | ~88 |
| [Entrevista esta semana](#ruta-entrevista-esta-semana) | Quien tiene la entrevista encima: quince capítulos que se leen solos | 15 | ~38 |

### Ruta completa

Quien quiere dominar el tema. ~242 h, de las que ~18 son los seis talleres opcionales del final.

`01/01`, `01/02`, `01/03`, `01/04`, `01/05`, `01/06`, `01/07`, `01/08`, `01/09`, `01/10` · `02/01`, `02/02`, `02/03`, `02/04`, `02/05`, `02/06`, `02/07`, `02/08`, `02/09` · `03/01`, `03/02`, `03/03`, `03/04`, `03/05`, `03/06`, `03/07` · `04/01`, `04/02`, `04/03`, `04/04`, `04/05`, `04/06`, `04/07`, `04/08`, `04/09` · `05/01`, `05/02`, `05/03`, `05/04`, `05/05`, `05/06`, `05/07`, `05/08`, `05/09` · `06/01`, `06/02`, `06/03`, `06/04`, `06/05`, `06/06`, `06/07`, `06/08`, `06/09`, `06/10`, `06/11` · `07/01`, `07/02`, `07/03`, `07/04`, `07/05`, `07/06`, `07/07` · `08/01`, `08/02`, `08/03`, `08/04`, `08/05`, `08/06`, `08/07` · `09/01`, `09/02`, `09/03`, `09/04`, `09/05` · `10/01`, `10/02`, `10/03`, `10/04`, `10/05`, `10/06`, `10/07`, `10/08` · `11/01`, `11/02`, `11/03`, `11/04`, `11/05` · `12/01`, `12/02`, `12/03`, `12/04`, `12/05`, `12/06`, `12/07` · `13/01`, `13/02`, `13/03`, `13/04`, `13/05`, `13/06` · `14/01`, `14/02`, `14/03`, `14/04`, `14/05`, `14/06`, `14/07`

### Ruta POO rápida

Quien tiene huecos en la base o viene de otro paradigma. ~48 h.

`01/01`, `01/02`, `01/03`, `01/04`, `01/05`, `01/06`, `01/08`, `01/09`, `01/10` · `02/01`, `02/02`, `02/03`, `02/04`, `02/05`, `02/06` · `03/01`, `03/02` · `12/01`, `12/02`, `12/03`

### Ruta SOLID y diseño rápida

Quien va a una entrevista de diseño o de revisión de código. ~53 h.

`01/01`, `01/02`, `01/03`, `01/04`, `01/05`, `01/06` · `02/01`, `02/02`, `02/04`, `02/06` · `03/01`, `03/02`, `03/04`, `03/05` · `04/05`, `04/06` · `12/01`, `12/02`, `12/03`, `12/05`, `12/06`, `12/07`

### Ruta patrones rápida

Quien ya tiene la base y va por el catálogo. ~102 h.

`01/01`, `01/02`, `01/03`, `01/04`, `01/05`, `01/06` · `02/01`, `02/02`, `02/03`, `02/04`, `02/05`, `02/06`, `02/07` · `03/01`, `03/02`, `03/03`, `03/04` · `04/01`, `04/03`, `04/05`, `04/06`, `04/07` · `05/01`, `05/02`, `05/03`, `05/04`, `05/05` · `06/01`, `06/02`, `06/03`, `06/04`, `06/05`, `06/06`, `06/07` · `07/01`, `07/02`, `07/03` · `10/01` · `12/04` · `13/01`, `13/04`

### Ruta persistencia

Quien trabaja con ORMs y quiere saber qué hacen por dentro. ~98 h.

`01/01`, `01/02`, `01/03`, `01/04`, `01/05`, `01/06` · `02/01`, `02/02`, `02/03`, `02/04`, `02/05`, `02/06`, `02/07` · `03/01`, `03/02`, `03/04` · `04/05`, `04/06`, `04/07` · `05/01`, `05/02`, `05/03`, `05/04` · `06/01`, `06/03`, `06/07` · `07/01`, `07/02`, `07/03`, `07/04`, `07/05`, `07/06`, `07/07` · `08/01`, `08/02`, `08/03`, `08/04`, `08/05`, `08/06`, `08/07` · `09/01`

### Ruta concurrencia

Quien necesita los patrones de concurrencia. ~56 h.

`01/01`, `01/02`, `01/03`, `01/04` · `02/01`, `02/02`, `02/04` · `03/01`, `03/02`, `03/04` · `04/05`, `04/06`, `04/07` · `06/01`, `06/03` · `10/01`, `10/02`, `10/03`, `10/04`, `10/05`, `10/06`, `10/07`, `10/08`

### Ruta políglota

Quien trabaja en varios lenguajes. ~88 h.

`01/01`, `01/02`, `01/03`, `01/04`, `01/05`, `01/06` · `02/01`, `02/02`, `02/03`, `02/04`, `02/05`, `02/06`, `02/07` · `03/01`, `03/02`, `03/04` · `04/05`, `04/06`, `04/07` · `05/01`, `05/02`, `05/03`, `05/04`, `05/05` · `06/01`, `06/03`, `06/08` · `07/01`, `07/02`, `07/03` · `11/01`, `11/02`, `11/03`, `11/04`, `11/05` · `13/02`

### Ruta entrevista esta semana

Quien tiene la entrevista encima: quince capítulos que se leen solos. ~38 h.

`01/02`, `01/03`, `01/05`, `01/06` · `02/02` · `03/02` · `04/05` · `05/02`, `05/03` · `06/01`, `06/03`, `06/07` · `07/03` · `12/03` · `13/01`

---

## 3. 🗺️ Mapa de bloques

| Bloque | Qué hace | Documentos |
|---|---|---|
| [`01` — Modelo de objetos](01-modelo-de-objetos/README.md) | Identidad, igualdad, inmutabilidad, copia, despacho, herencia, genéricos y la ausencia | 8 capítulos, simulación, solucionario |
| [`02` — Modelado OO](02-modelado-oo/README.md) | Del diagrama al código: asociaciones, propiedad, entidades y valores, tablas | 7 capítulos, simulación, solucionario |
| [`03` — Principios de diseño](03-principios-de-diseno/README.md) | Encapsulación, SOLID, GRASP, acoplamiento y contratos | 5 capítulos, simulación, solucionario |
| [`04` — Creacionales](04-creacionales/README.md) | Fábricas, Builder, Prototype, Singleton, contenedores, RAII y compañía | 7 capítulos, simulación, solucionario |
| [`05` — Estructurales](05-estructurales/README.md) | Adapter, Decorator, Proxy, Facade, Composite, Bridge, Flyweight | 7 capítulos, simulación, solucionario |
| [`06` — Comportamiento](06-comportamiento/README.md) | Strategy, Template Method, Observer, Command, Chain, State, Visitor y fichas | 9 capítulos, simulación, solucionario |
| [`07` — Fowler: dominio y datos](07-fowler-dominio-y-datos/README.md) | La lógica de negocio y lo que hay debajo de JPA | 5 capítulos, simulación, solucionario |
| [`08` — Fowler: presentación, distribución y base](08-fowler-presentacion-distribucion-y-base/README.md) | MVC, DTO, `@Version`, sesión, Value Object y Money | 5 capítulos, simulación, solucionario |
| [`09` — DDD táctico y otros](09-ddd-tactico-y-otros/README.md) | Agregados, eventos, servicios, Specification, Null Object, Type Object | 3 capítulos, simulación, solucionario |
| [`10` — Concurrencia](10-concurrencia/README.md) | Inmutable, monitor, colas y pools, futuros, Reactor, DCL | 6 capítulos, simulación, solucionario |
| [`11` — Los diferentes](11-los-diferentes/README.md) | Go, JavaScript y TypeScript, Python | 3 capítulos, simulación, solucionario |
| [`12` — Antipatrones](12-antipatrones/README.md) | *Code smells*, antipatrones de diseño, de patrón y de proceso | 5 capítulos, revisión de código en vivo, solucionario |
| [`13` — Patrones en la práctica](13-patrones-en-la-practica/README.md) | Spring, JDK y STL, refactorización, el árbol de decisión | 4 capítulos, simulación final, solucionario |
| [`14` — Talleres](14-talleres/README.md) (opcional) | Una kata de refactorización sobre un módulo legado, con código que corre | 6 talleres, solucionario, laboratorio |

Los trece bloques del hilo principal están completos: 74 capítulos, 13 simulaciones y 13 solucionarios. El bloque `14`, opcional,
suma seis talleres, su solucionario y el laboratorio: un módulo legado en Java y el estado del código al cerrar cada taller.

---

## 4. 🧱 Cómo está hecho

- **Niveles**: cada patrón es A (se escribe y se defiende), B (se reconoce y se explica) o C (ficha corta con lo que lo
  reemplazó). El README de cada bloque los lista.
- **Lenguajes**: C++ y Java en ese orden; en los bloques de Fowler y DDD, Java primero y C++ solo donde aporta. C# aparece
  como inserto cuando cambia la respuesta; Go, JavaScript, TypeScript y Python tienen su bloque. Lo que no existe en Java 17
  lleva su alternativa; Java 25 aparece solo en callouts.
- **Preguntas**: cada capítulo cierra con sus preguntas graduadas 🟢🟡🟠🔴, **sin respuesta**; las respuestas, en tres capas
  (30 segundos, 2 minutos, el detalle), están en el solucionario de su bloque, con el enunciado copiado literal.
- **Simulaciones**: preguntas transversales y ejercicios de diseño de veinte minutos; uno de ellos, siempre, se resuelve sin
  ningún patrón.
- **Diagramas** en Mermaid, que GitHub muestra sin pasos extra.
- **Independencia**: el corpus no asume leído nada de fuera de su carpeta ni enlaza a otros cursos.

---

## 5. 🧪 Versiones y verificación

El código se escribió para compilar y se verificó después en contenedores temporales, con los arneses fuera del corpus:

| Lenguaje | Versión | Qué se verificó |
|---|---|---|
| C++ | GCC 14.4, `-std=c++23` (y GCC 15.3 para los contratos) | Sintaxis de los 112 bloques; 22 afirmaciones ejecutadas; los `// no compila` fallan por lo que dicen |
| Java | JDK 21.0.12; 17.0.20 y 25.0.4 para alternativas y callouts | Los 442 bloques con `javac`; 42 afirmaciones ejecutadas, más 5 de Java 25 y 9 de Spring y JPA |
| Spring | Spring Boot 4.1.1, Spring Framework 7.0.9, Hibernate 7.4.5, H2, Tomcat 11.0.24, Spring Security 7.1.1 | Autoinvocación, proxies, eventos por fase, Identity Map, `@Version`, `JdbcTemplate`; controladores, DTO, sesión, `Specification`, la cadena de seguridad y los filtros de *servlet* contra un servidor arrancado |
| SQL | PostgreSQL 18.6 | Los esquemas, los `CHECK`, el bloqueo optimista, `RETURNING` y `ON CONFLICT` |
| Librerías Java | Lombok 1.18.48, Jackson 2.22.3 y 3.1.5, Netty 4.2.18 | El ciclo de `@Data`, dónde va `@Builder`, el ciclo en JSON, el bucle de eventos bloqueado frente al ejecutor aparte |
| Go | 1.27.1 | `gofmt` de los 15 bloques; 10 afirmaciones ejecutadas |
| JavaScript y TypeScript | Node.js 24.21.0; TypeScript 7.0.2 con `--strict` | 8 bloques JS y 5 TS; 11 afirmaciones; exhaustividad con `never` y marcas |
| Python | 3.14.8, SQLAlchemy 2.1.3, Django 6.1.1 | 13 bloques; 17 afirmaciones, con la `Session` y Django |
| C# | .NET 10.0.12 (C# 14), EF Core 10.0.12 | 7 afirmaciones de los insertos; los tipos *owned* |
| Mermaid | mermaid-cli 11.17.0 | Los 59 diagramas renderizados |
| Talleres | JDK 21.0.12, Maven 3.10.0 (`maven:3.10.0-eclipse-temurin-21`), JUnit 6.1.3, H2 2.5.252 | El legado y los seis estados del laboratorio, de 0 a 33 pruebas; cada salida pegada en los talleres es de su corrida |

En los talleres, a diferencia de los capítulos, el código se corrió mientras se escribía y el corpus lo entrega en
`14-talleres/laboratorio/`. Los servidores de `Selector`, `epoll` y Netty se probaron con cien y doscientos clientes a la vez. Lo único que no se
ejecuta son las dos carreras de hilos de `10/01` §3 y `10/02` §3, que no se reproducen de forma determinista: se razonan con
el modelo de memoria.

---

## 6. 🚫 Qué NO está aquí

| Tema | Por qué |
|---|---|
| Patrones de arquitectura (capas, hexagonal, microservicios, CQRS, Event Sourcing, Saga) | Son decisiones de sistema, no de objetos; se mencionan solo como límite |
| Patrones de integración (Hohpe) | Mensajería entre sistemas |
| El bliki de Fowler más allá de lo que toca a objetos | Fuera del alcance |
| Programación funcional como paradigma | Se usa donde reemplaza un patrón (lambdas, inmutabilidad), no se enseña |
| UML formal (OCL, perfiles, diagramas de componentes y despliegue) | Se usa el UML justo para pensar y discutir |
