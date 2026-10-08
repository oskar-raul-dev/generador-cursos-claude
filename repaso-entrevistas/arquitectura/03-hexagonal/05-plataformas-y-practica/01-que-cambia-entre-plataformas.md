# 01 — Qué cambia entre plataformas

Este capítulo enseña a conservar la misma dirección de dependencias cuando cambian el lenguaje, el framework y sus mecanismos de composición, transacción, contexto y prueba.

## 1. 🎯 El problema

Un equipo copia la estructura de un proyecto Spring a Go: crea una interfaz por clase, paquetes `controller/service/repository` y un contenedor casero. Otro equipo lleva un ejemplo Go a NestJS y confía en que una `interface` TypeScript se pueda inyectar en runtime. Ambos copiaron la forma y perdieron la decisión: el núcleo define contratos y los detalles se conectan desde afuera.

## 2. 🧭 Baseline verificada

La baseline editorial al **25 de septiembre de 2026** es Java 25 LTS con Spring Boot 4.1, Node.js 24 LTS con TypeScript 6, Go 1.27 y Python 3.14. Sirve para comprobar APIs y ejemplos; no obliga a migrar un servicio estable ni reemplaza la matriz de soporte de cada organización.

```text
política estable ─► puerto propio ◄─ mecanismo de plataforma ─► detalle
                                   beans / token / constructor / factory
```

Java ofrece nominal typing y reflexión; TypeScript usa tipos estructurales que se borran al ejecutar; Go satisface interfaces de forma implícita; Python combina duck typing con anotaciones opcionales y `Protocol`. Ninguna de esas propiedades decide por sí sola dónde vive `CreateOrder`.

## 3. 🔄 Seis ejes que sí cambian

| Eje | Pregunta de diseño | Fallo que debes evitar |
|---|---|---|
| Tipos | ¿el contrato existe en runtime o solo al analizar? | confundir compilación con validación de entrada |
| Composición | ¿contenedor, token, constructor o fábrica? | esconder dependencias en globales o service locator |
| Transacción | ¿proxy, callback, `sql.Tx` o context manager? | partir la unidad de consistencia |
| Contexto | ¿hilo, async context o parámetro explícito? | filtrar contexto técnico al dominio |
| Pruebas | ¿qué runner y qué recurso real revelan la frontera? | premiar mocks que no ejecutan el adapter |
| Build | ¿qué regla impide imports hacia afuera? | depender solo de convenciones de carpetas |

El diseño empieza por el riesgo, no por la herramienta. Si el fallo posible está en SQL, una integración real importa más que el runner. Si está en imports, una regla de módulos vale más que otro test del camino feliz.

## 4. 🧩 El mismo puerto, distinto mecanismo

`PaymentGateway` puede ser una interfaz Java implementada por una clase Spring, una interfaz TypeScript enlazada con un `Symbol`, una interfaz Go declarada junto al consumidor o un `Protocol` Python. El contrato útil sigue siendo `authorize(operationId, amount)` con resultados propios. Copiar la API del SDK produciría el mismo acoplamiento en los cuatro lenguajes.

La transacción también cambia de forma: Spring puede aplicar un interceptor alrededor del caso de uso; Node necesita compartir el cliente o contexto transaccional correcto; Go hace visible `sql.Tx`; SQLAlchemy delimita sesión y transacción. El mecanismo debe conservar un commit único sin obligar al agregado a conocerlo.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Java 25, Spring Boot 4.1, DI, proxies transaccionales y JPA | paquetes, puertos, límites y alcance de beans | creer que una anotación crea la arquitectura |
| Node/TS | Node 24, TypeScript 6, módulos, async runtime y test runner | validación runtime, tokens y transacción async | inyectar una interfaz borrada o confiar en un cast |
| Go | Go 1.27, interfaces implícitas, `context` y `database/sql` | wiring, ownership y traducción explícita | convertir cada paquete en una capa ceremonial |
| Python | Python 3.14, anotaciones, `Protocol` y context managers | disciplina de imports, validación y scopes async | usar globals porque el lenguaje lo permite |

## 6. ⚖️ Decisión y coste

Adapta la implementación al ecosistema, pero conserva tres invariantes: el núcleo no importa transporte o persistencia; el puerto habla negocio; la composición conoce las implementaciones. La portabilidad no significa que el mismo árbol de carpetas compile en cuatro lenguajes. Significa que puedes explicar la misma frontera con mecanismos idiomáticos. Mantener esa equivalencia cuesta documentación, reglas de build y pruebas distintas por plataforma.

## ⚠️ Errores frecuentes

- “Hexagonal se implementa igual en todos los lenguajes.” La regla es común; los mecanismos no.
- “Un framework con DI ya resolvió los puertos.” Solo construyó objetos.
- “Si TypeScript o Python aceptan el dato, ya está validado.” Los tipos estáticos no validan JSON ajeno.
- “Go no necesita arquitectura porque tiene interfaces.” También puede mezclar HTTP, SQL y política.
- “La versión más reciente es la baseline correcta.” Soporte, riesgo y compatibilidad mandan.

## 7. ✅ Veredicto

Compara plataformas por decisiones observables: contrato runtime, composición, transacción, contexto, prueba y build. Usa el mecanismo más simple que mantenga la dependencia hacia adentro y que el equipo pueda operar.

## 📚 Referencias

- [Oracle: Java SE Support Roadmap](https://www.oracle.com/java/technologies/java-se-support-roadmap.html)
- [Spring Boot: documentación y versiones estables](https://docs.spring.io/spring-boot/documentation.html)
- [Node.js: historial y estado de releases](https://nodejs.org/en/about/previous-releases)
- [TypeScript 6.0: release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html)
- [Go: historial de releases](https://go.dev/doc/devel/release)
- [Python 3.14](https://www.python.org/downloads/release/python-3140/)

## 🧠 Preguntas

1. 🟢 ¿Qué permanece igual al cambiar de plataforma?
2. 🟢 ¿Para qué sirve la baseline del bloque?
3. 🟢 ¿Qué diferencia hay entre contrato estático y runtime?
4. 🟢 ¿Qué cuatro mecanismos de composición compara el capítulo?
5. 🟢 ¿Qué expresa el puerto `PaymentGateway` en cualquier lenguaje?
6. 🟢 ¿Qué seis ejes se comparan entre plataformas?
7. 🟡 ¿Por qué una interfaz TypeScript necesita un token en NestJS?
8. 🟡 ¿Qué ventaja da una interfaz implícita de Go al consumidor?
9. 🟡 ¿Qué aporta `Protocol` en Python y qué no ejecuta?
10. 🟡 ¿Qué diferencia hay entre proxy transaccional y `sql.Tx` explícito?
11. 🟡 ¿Por qué el runner de test no determina la calidad de la prueba?
12. 🟡 ¿Qué regla debe comprobar el build además de compilar?
13. 🟡 ¿Por qué no copiarías la estructura de Spring a Go?
14. 🟡 ¿Cómo mantienes el mismo contrato sin usar la misma sintaxis?
15. 🟡 ¿Qué criterio usarías para escoger una versión baseline?
16. 🟡 ¿Qué contexto técnico no debería convertirse en estado de dominio?
17. 🟠 Un equipo migra a TypeScript y elimina validación de JSON porque tiene tipos. ¿Qué falla?
18. 🟠 Un proyecto Go crea un contenedor DI para imitar Spring. ¿Qué revisarías primero?
19. 🟠 Python usa una sesión global para evitar pasar dependencias. ¿Qué riesgos aparecen?
20. 🟠 Spring inyecta directamente el SDK de pagos en `Order`. ¿Qué no resolvió DI?
21. 🟠 Dos plataformas usan herramientas distintas pero el núcleo importa sus ORMs. ¿Son equivalentes arquitectónicamente?
22. 🟠 La última versión rompe una librería crítica soportada. ¿Mantienes la baseline o actualizas?
23. 🟠 Un test de puerto pasa con fake en cuatro lenguajes y falla con PostgreSQL. ¿Qué evidencia faltó?
24. 🟠 ¿Cómo demostrarías que una implementación es idiomática sin sacrificar la regla de dependencias?

**Siguiente:** [Java y Spring Boot](02-java-y-spring-boot.md).
