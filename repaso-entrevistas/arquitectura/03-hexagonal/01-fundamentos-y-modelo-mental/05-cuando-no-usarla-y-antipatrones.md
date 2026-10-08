# 05 — Cuándo no usarla y antipatrones

La madurez no consiste en añadir fronteras siempre. Consiste en proteger el cambio que importa y retirar ceremonia que no paga su alquiler.

## 1. 🎯 El problema

Un CRUD interno de tres pantallas puede acabar con controller, command, handler, port de entrada, caso de uso, entidad, mapper, port de salida, repository adapter y configuración de DI. Si el sistema es estable, el equipo paga diez lugares para cambiar una validación sencilla.

## 2. 🧱 Criterio de proporcionalidad

Pregunta qué cambio quieres proteger:

```text
¿Cambian las reglas con frecuencia? ─┐
¿Hay varias entradas o salidas?      ├─► frontera explícita
¿Vale la pena probar el núcleo solo? ─┘

Si no, ─► diseño modular más simple y una fecha de revisión
```

La alternativa no es “sin arquitectura”. Un módulo pequeño puede mantener una función de negocio separada, un repositorio local y una prueba directa, sin fingir que cada clase es un port.

## 3. 🩺 Antipatrones

- **Sobreabstracción:** interfaces sin segunda implementación ni frontera real.
- **Ports espejo:** `UserRepositoryPort` repite exactamente el API del ORM.
- **Modelo anémico:** objetos que solo transportan datos y reglas dispersas en servicios.
- **Dominio que devuelve DTO:** el núcleo conoce la presentación o el transporte.
- **God use case:** un caso de uso coordina todo el sistema y se vuelve otro monolito.
- **Infraestructura filtrada:** entidades ORM, errores HTTP o SDKs cruzan al núcleo.

Un adapter que solo delega puede ser legítimo si mantiene un límite de traducción o ciclo de vida. Es sospechoso cuando existe solo para llenar una carpeta.

## 4. 🧰 Señales por ecosistema

| Plataforma | Señal de alarma | Pregunta útil |
|---|---|---|
| Java | interfaces y paquetes por convención | ¿qué cambio protege este port? |
| Node/TS | módulo Nest confundido con frontera de negocio | ¿el núcleo compila sin Nest? |
| Go | interfaces globales y wiring disperso | ¿quién consume este contrato? |
| Python | diccionarios y imports dinámicos por todas partes | ¿cuál es la forma estable del caso de uso? |

## 5. 🧭 Excepción y fecha de revisión

No toda dependencia compartida es un pecado. Una librería de logging, un tipo realmente estable o una herramienta de composición pueden cruzar una frontera si el beneficio supera el coste. Documenta la excepción, el motivo y la fecha de revisión. Una excepción sin dueño se vuelve la arquitectura por accidente.

## 6. ⚖️ Decisión y coste

Usa la menor estructura que proteja el cambio real. Si la frontera se vuelve valiosa, puedes introducirla de manera incremental. Si no puedes explicar qué dependencia queda aislada, elimina la abstracción y conserva la prueba que te avise cuando la decisión cambie.

## ⚠️ Errores frecuentes

- “Más capas significa mejor arquitectura.” Más capas también significa más traducción y más puntos de fallo.
- “Un CRUD nunca necesita frontera.” Puede necesitarla si tiene reglas volátiles o varias entradas.
- “El modelo anémico siempre está mal.” Es una señal de riesgo; el contexto y la complejidad mandan.
- “Eliminar interfaces es retroceder.” Puede ser simplificar con criterio.

## 7. ✅ Veredicto

Mantén solo las fronteras que reduzcan un riesgo o un cambio observable. Simplificar con una regla y una fecha de revisión es diseño; conservar ceremonia sin protección es deuda.

## 📚 Referencias

- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)
- [When to Mock, Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2014/05/10/WhenToMock.html)

## 🧠 Preguntas

1. 🟢 ¿Cuál es la primera pregunta antes de añadir una frontera?
2. 🟢 ¿Qué es sobreabstracción?
3. 🟢 ¿Qué es un port espejo?
4. 🟢 ¿Qué es un modelo anémico?
5. 🟢 ¿Qué significa infraestructura filtrada?
6. 🟢 ¿Qué es un god use case?
7. 🟢 ¿Por qué una excepción debe tener fecha de revisión?
8. 🟡 ¿Cuándo un CRUD justifica hexagonal?
9. 🟡 ¿Cuándo un adapter que delega sí aporta valor?
10. 🟡 ¿Cómo detectarías una interfaz sin frontera?
11. 🟡 ¿Qué coste tiene un DTO que cruza hasta el dominio?
12. 🟡 ¿Por qué el modelo anémico no se juzga solo por el nombre?
13. 🟡 ¿Qué diferencia hay entre simplificar y saltarse una frontera?
14. 🟡 ¿Qué prueba conservarías al eliminar un port?
15. 🟡 ¿Qué parte de la arquitectura puede ser gradual?
16. 🟡 ¿Cómo medirías si una abstracción paga su coste?
17. 🟠 Diseña la solución para un CRUD interno de tres pantallas.
18. 🟠 Un equipo quiere copiar el hexágono en cada módulo. ¿Qué objeciones pondrías?
19. 🟠 Un proveedor cambia cada mes y las reglas casi nunca. ¿Qué abstraes?
20. 🟠 Las reglas cambian cada semana, pero solo hay una base de datos. ¿Qué proteges?
21. 🟠 Un port tiene quince métodos y tres consumidores. ¿Cómo lo dividirías?
22. 🟠 El equipo eliminó los adapters y ahora el ORM llega al dominio. ¿Qué migras primero?
23. 🟠 ¿Cómo presentarías una excepción arquitectónica en una revisión?
24. 🟠 ¿Qué señal indica que una simplificación dejó de ser segura?

**Siguiente:** [Simulación de entrevista](06-simulacion-de-entrevista.md).
