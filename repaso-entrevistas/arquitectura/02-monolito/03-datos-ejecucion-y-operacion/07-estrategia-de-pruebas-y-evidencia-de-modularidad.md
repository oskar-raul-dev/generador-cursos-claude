# 07 — Estrategia de pruebas y evidencia de modularidad

Aprenderás a elegir, para cada riesgo del monolito, la prueba más cercana que puede demostrarlo:
qué prueba una regla de negocio, qué solo prueba una base real, qué demuestra que los módulos
respetan sus límites, y por qué ni la cobertura ni un E2E verde son evidencia de modularidad.

## 1. 🎯 Síntoma y decisión

La suite tiene 1.400 pruebas, 85 % de cobertura y está en verde. Casi todas simulan los
repositorios. En el trimestre hubo tres incidentes y ninguno rompió una prueba antes: la sobreventa
del capítulo de [concurrencia](02-concurrencia-locking-e-idempotencia.md), el rollout roto por una
[migración](05-despliegues-migraciones-de-esquema-y-rollback.md) y un `UPDATE` que `orders` hacía por
SQL directo sobre las reservas de `inventory`. La propuesta del equipo es añadir más E2E, que ya
tardan 25 minutos y fallan de forma intermitente.

La suite prueba mucho, pero no los riesgos que causaron los incidentes. La decisión de este capítulo
es qué prueba corresponde a cada riesgo y qué evidencia sostiene que el monolito es modular.

## 2. 🧠 Modelo mental

Una prueba vale por el fallo que puede detectar. Para cada riesgo se busca la prueba más cercana que
**puede ponerse roja** cuando el riesgo ocurre; si no puede, no es evidencia, por rápida o numerosa
que sea.

```text
riesgo                            prueba que puede fallar por él
regla de negocio de orders    ──► prueba de módulo, sin infraestructura
restricción, SQL, aislamiento ──► integración con la base real
carrera entre réplicas        ──► concurrencia real contra la base, repetida
import prohibido              ──► regla arquitectónica estática
escritura cruzada por SQL     ──► permisos de base y prueba de ownership
convivencia de versiones      ──► migración ejecutada con la versión N y la N+1
composición completa          ──► pocos E2E
```

La modularidad no la certifica ninguna prueba sola. Se sostiene con evidencias combinadas: imports
permitidos, escritura de cada tabla solo por su dueño, contratos pequeños y cambios que se quedan
dentro de un módulo.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | 85 % de cobertura; nueve de cada diez pruebas con repositorios simulados; tres incidentes sin prueba roja previa; E2E de 25 minutos con fallos intermitentes |
| Inferencia | la suite prueba decisiones del código con la infraestructura simulada; los riesgos que viven en la base, la concurrencia y los límites no tienen una prueba que pueda fallar |
| Diagnóstico | cobertura alta de líneas y cobertura nula de los riesgos que causaron incidentes |
| Recomendación | mapa de riesgos a pruebas: integración con base real para restricciones y carreras, regla arquitectónica y permisos para límites, migración probada con dos versiones y E2E solo para la composición crítica |

Qué refutaría el diagnóstico: si los incidentes vinieran de diferencias de configuración entre
producción y el entorno de prueba, el hueco sería de paridad de entornos y no de tipos de prueba. Por
eso el primer paso es tomar cada incidente y preguntar qué prueba, de existir, se habría puesto roja.

## 4. 🛠️ Una prueba para cada propiedad

| Riesgo | Prueba más cercana | Evidencia que produce |
|---|---|---|
| regla de `orders` | módulo/unidad | resultado sin infraestructura ajena |
| constraint o consulta | integración con DB real | SQL, aislamiento y migración efectivos |
| import prohibido | regla arquitectónica | dirección estática del código |
| contrato interno | consumidor-proveedor o compilación | compatibilidad del intercambio |
| carrera de reserva | concurrencia real | una invariante bajo interleavings |
| despliegue compatible | migración con versión vieja y nueva | convivencia durante rollout |
| checkout crítico | pocos E2E | composición y configuración reales |

Los mocks sirven para forzar errores y verificar decisiones del consumidor; no prueban que una
restricción SQL, un timeout o una migración existan. Testcontainers u otra base efímera acercan la
semántica real, pero una imagen distinta a producción todavía puede ocultar diferencias.

La modularidad necesita varias evidencias: imports permitidos, escritura solo por propietario,
contratos pequeños y cambios contenidos. Una regla estática no detecta SQL cruzado; un E2E verde no
revela quién escribió la tabla. Cada excepción arquitectónica se documenta con owner, motivo y fecha
de caducidad para que la suite no petrifique una frontera equivocada.

La pirámide se diseña por coste de diagnóstico y riesgo, no por porcentajes universales. Si un fallo
solo aparece con dos transacciones reales, esa prueba de integración vale más que diez mocks rápidos.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | JUnit/Testcontainers y ArchUnit como candidatos | ninguna herramienta descubre ownership | mockear la base para probar constraints |
| Node/TypeScript | runner, contenedor de DB y reglas de imports | tipos no prueban migraciones | snapshot como contrato completo |
| Go | `testing`, race detector e integración real | `-race` no prueba carreras en la base | solo tests de paquete |
| Python | pytest, DB real selectiva y reglas de imports | un mock ORM no prueba SQL | marcar todo como unitario |

La columna «Qué no resuelve» es la lista de lo que cada herramienta **no puede detectar** por muchas
veces que se ejecute: ArchUnit no ve SQL, `-race` no ve la base, un tipo no ve una migración, un mock
no ve una restricción. Elegir herramienta es elegir qué riesgo queda cubierto, y ninguna de las
cuatro descubre por sí sola quién es dueño de qué.

## 6. ⚖️ Decisión y coste

Asigna a cada riesgo la prueba más cercana que pueda demostrarlo: módulo para reglas, base real para constraints y concurrencia, controles estáticos para imports y pocos E2E para composición. Pagas fixtures y mantenimiento, pero obtienes fallos localizables. Si el legado impide aislar una regla, caracteriza primero el flujo existente. Detén la ampliación cuando los riesgos críticos tengan evidencia y las pruebas adicionales solo dupliquen cobertura.

## ⚠️ Errores frecuentes

- «La cobertura mide la calidad de la suite». Mide líneas ejecutadas, no riesgos que pueden fallar; un 85 % convivió con tres incidentes.
- «Un mock de repositorio prueba la persistencia». Prueba que el código llama al repositorio; la restricción, la consulta y el aislamiento solo existen en la base real.
- «Más E2E, más seguridad». Son lentos, frágiles y localizan mal el fallo; cubren composición, no cada regla.
- «ArchUnit demuestra la modularidad». Demuestra la dirección de los imports; un `UPDATE` por SQL a la tabla de otro módulo pasa la regla.
- «Si la prueba de concurrencia pasó, no hay carrera». Una carrera es probabilística; la prueba necesita paralelismo real y repeticiones para ser evidencia.

## 7. ✅ Veredicto

Parte de los riesgos, no de la pirámide: para cada uno, la prueba más cercana que pueda fallar
cuando el riesgo ocurre. Reglas en pruebas de módulo; restricciones y carreras contra la base real;
límites con reglas arquitectónicas y permisos; convivencia de versiones con la migración ejecutada; y
pocos E2E para la composición. La modularidad se demuestra con varias evidencias a la vez, y ninguna
prueba sola la certifica.

## 📚 Referencias

- [Java Testcontainers](https://java.testcontainers.org/)
- [Go Race Detector](https://go.dev/doc/articles/race_detector)
- [Python unittest.mock](https://docs.python.org/3/library/unittest.mock.html)
- [Martin Fowler: Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)

## 🧠 Preguntas

1. 🟢 ¿Qué significa elegir «la prueba más cercana» a un riesgo?
2. 🟢 ¿Qué puede demostrar una prueba de módulo sin infraestructura y qué no?
3. 🟢 ¿Por qué una restricción de base solo se prueba contra una base real?
4. 🟢 ¿Qué evidencias combinadas sostienen que un monolito es modular?
5. 🟢 ¿Qué es una prueba de caracterización?
6. 🟢 ¿Para qué sirven los E2E en esta estrategia?
7. 🟡 ¿Por qué contar cobertura como evidencia de modularidad es una simplificación peligrosa?
8. 🟡 ¿Cuándo usarías una prueba de caracterización temporal porque el legado impide aislar una regla?
9. 🟡 ¿Qué prueba habría detectado la sobreventa del capítulo de concurrencia, y por qué los mocks no?
10. 🟡 ¿Cómo probarías que un rolling deployment no se rompe con una migración?
11. 🟡 ¿Qué detecta una regla arquitectónica y qué escritura cruzada se le escapa?
12. 🟡 ¿Cómo complementan los permisos de base a una regla de imports?
13. 🟡 ¿Qué medirías para saber si los módulos contienen los cambios en la práctica?
14. 🟡 ¿Cuándo es útil un mock y cuándo engaña?
15. 🟡 ¿Cómo documentarías una excepción a una regla arquitectónica para que no se vuelva permanente?
16. 🟡 ¿Qué haces con un E2E que falla de forma intermitente?
17. 🟡 ¿Qué propiedades distintas cubren ArchUnit/Testcontainers en Java y el race detector en Go?
18. 🟠 ¿Qué falso positivo comparten mocks de ORM en Node/TypeScript y Python frente a una base real?
19. 🟠 Hubo tres incidentes en el trimestre y ninguno rompió una prueba antes. ¿Cómo reorganizarías la suite?
20. 🟠 La suite tarda 40 minutos y los desarrolladores la saltan. ¿Qué recortarías sin perder evidencia?
21. 🟠 Una prueba de integración pasa con la imagen de base de CI y falla en producción. ¿Qué diferencia buscarías?
22. 🟠 Quieres introducir una regla arquitectónica en un legado con 300 violaciones. ¿Cómo lo harías sin bloquear al equipo?
23. 🟠 Un equipo quiere cambiar todos los mocks por Testcontainers y otro quiere mantener la suite rápida. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que la suite ya cubre los riesgos críticos y no hay que seguir ampliándola?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [06 — Observabilidad y resiliencia del monolito](06-observabilidad-y-resiliencia-del-monolito.md).

**Siguiente:** [08 — Simulación de entrevista: Datos, ejecución y operación](08-simulacion-de-entrevista.md).
