# 04 — Hexagonal, Clean, Onion y capas

Estos estilos comparten una intención —proteger políticas de detalles—, pero no son sinónimos perfectos. En una entrevista importa explicar la regla común y elegir el vocabulario que el equipo pueda mantener.

## 1. 🎯 El problema

Dos equipos pueden dibujar círculos distintos y producir el mismo acoplamiento: el dominio importa el ORM, los casos de uso devuelven respuestas HTTP y toda la lógica termina en una capa “service”. El dibujo no garantiza nada.

## 2. 🧱 La regla común

```text
Detalle ─► frontera estable ◄─ política

La implementación del detalle depende de contratos que la política controla.
```

Hexagonal destaca puertos y adapters y trata simétricamente entradas y salidas. Onion destaca capas concéntricas alrededor del dominio. Clean describe entidades, casos de uso, interfaces y frameworks, con la *Dependency Rule*: las dependencias de código apuntan hacia adentro. Layered puede cumplir la misma regla, pero también puede degenerar en “cada capa llama a la de abajo”.

| Estilo | Imagen útil | Riesgo si se copia el dibujo |
|---|---|---|
| Hexagonal | conversaciones y adapters | crear ports sin propósito |
| Onion | dominio en el centro | confundir anillo con módulo |
| Clean | políticas frente a mecanismos | demasiadas capas nominales |
| Layered | responsabilidades por nivel | dependencia vertical hacia detalles |

## 3. 🧭 Capas correctas e incorrectas

Una arquitectura por capas puede ser correcta si la aplicación depende de contratos y la infraestructura los implementa:

```text
Controller ─► Application ─► Domain
Infrastructure ─────────────────────► contratos del núcleo
```

Es incorrecta cuando el dominio depende de la capa inferior por tradición:

```text
Domain ─► Repository JPA ─► Database
```

La palabra `service` no revela la dirección. Hay que leer imports, tipos de retorno y composición.

## 4. 🧰 Plataformas

No lleva código: la decisión es conceptual y no depende de Java, Node/TS, Go o Python. Un framework puede imponer módulos o capas iniciales, pero el equipo decide qué dependencia cruza cada frontera.

## 5. ⚖️ Cómo elegir vocabulario

Elige **Hexagonal** si quieres hablar de entradas, salidas y sustitución de adapters. Elige **Clean** si el equipo ya organiza alrededor de casos de uso y reglas de dependencia. Usa **Onion** si la conversación se centra en anillos y dominio. Usa **Layered** solo si declaras la dirección; “controller-service-repository” no es una explicación suficiente.

No combines nombres para parecer más riguroso. Un sistema puede ser hexagonal en intención y clean en su organización; lo importante es que el contrato de dependencias sea verificable.

## ⚠️ Errores frecuentes

- “Son exactamente lo mismo.” Comparten una regla, no todos los límites ni el vocabulario.
- “Las capas siempre dependen hacia abajo.” Depende de qué significa “abajo” y quién define el contrato.
- “Si hay cuatro carpetas, es Clean.” La estructura no prueba la dirección.
- “Onion obliga a cuatro anillos.” Los dibujos son modelos, no cuotas.

## 6. ✅ Veredicto

Elige el vocabulario que haga visible la regla al equipo y verifica la dirección con código, no con el dibujo. Ninguna etiqueta compensa dependencias que salen desde la política.

## 📚 Referencias

- [The Clean Architecture, Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)

## 🧠 Preguntas

1. 🟢 ¿Qué regla comparten Hexagonal, Clean y Onion?
2. 🟢 ¿Qué destaca Hexagonal?
3. 🟢 ¿Qué destaca Onion?
4. 🟢 ¿Qué significa dependencia hacia adentro?
5. 🟢 ¿Por qué el dibujo no garantiza la arquitectura?
6. 🟢 ¿Qué riesgo tiene una arquitectura por capas?
7. 🟢 ¿Qué debe declarar una capa de infraestructura?
8. 🟡 ¿Son equivalentes Hexagonal y Clean?
9. 🟡 ¿Cuándo usarías el vocabulario de ports?
10. 🟡 ¿Cuándo el vocabulario de capas es suficiente?
11. 🟡 ¿Qué revisarías en un paquete llamado `service`?
12. 🟡 ¿Cómo demostrarías que las dependencias apuntan hacia adentro?
13. 🟡 ¿Qué diferencia hay entre una frontera conceptual y un módulo compilable?
14. 🟡 ¿Por qué los anillos no son una arquitectura ejecutable?
15. 🟡 ¿Qué relación hay entre DIP y la regla de dependencias?
16. 🟡 ¿Qué lenguaje usarías para explicar una migración gradual?
17. 🟠 Un equipo mezcla Clean, Onion y Hexagonal en una presentación. ¿Qué preguntas harías?
18. 🟠 Una capa `domain` importa un mapper de infraestructura. ¿Qué nombre del estilo lo detecta?
19. 🟠 Un equipo quiere una única capa `application`. ¿Qué riesgo aceptas?
20. 🟠 La empresa tiene un estándar de capas que no puedes renombrar. ¿Cómo preservas la regla?
21. 🟠 El diagrama es correcto, pero los imports no. ¿Qué consideras fuente de verdad?
22. 🟠 ¿Cómo decidirías si un adapter merece módulo separado?
23. 🟠 ¿Qué evidencia pedirías antes de llamar “Clean” a un sistema?
24. 🟠 ¿Cómo explicarías las diferencias en treinta segundos?

**Siguiente:** [Cuándo no usarla y antipatrones](05-cuando-no-usarla-y-antipatrones.md).
