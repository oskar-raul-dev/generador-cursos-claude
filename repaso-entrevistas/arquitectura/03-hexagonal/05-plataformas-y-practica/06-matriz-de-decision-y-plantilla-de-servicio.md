# 06 — Matriz de decisión y plantilla de servicio

Este capítulo enseña a elegir cuánta separación necesita un servicio y a diseñar una plantilla que automatice controles operativos sin inventar dominio ni capas vacías.

## 1. 🎯 El problema

Una organización genera todos los servicios con seis módulos, doce interfaces, outbox, broker y tres bases aunque el primero sea un CRUD interno. Otra entrega un repositorio vacío y cada equipo redescubre salud, build, logs y manejo de secretos. Una plantilla útil reduce decisiones repetitivas; no decide de antemano la complejidad del negocio.

## 2. 🧭 Tres profundidades posibles

| Profundidad | Señales | Estructura inicial |
|---|---|---|
| Directa | CRUD estable, una entrada, una DB, vida corta | handler + aplicación simple + persistencia, con imports hacia adentro |
| Selectiva | reglas relevantes o una integración volátil | casos de uso y puertos solo en esas fronteras |
| Completa | varias entradas, efectos críticos, larga vida o equipos separados | dominio explícito, puertos, adapters, contratos y reglas de módulos |

No son niveles de madurez. Un CRUD puede quedarse directo durante años; un flujo de pagos puede necesitar separación completa desde el inicio. La decisión se revisa cuando cambian riesgo, volatilidad o ownership.

## 3. 🔄 Matriz de decisión

Puntúa cualitativamente cinco fuerzas:

| Fuerza | Baja | Alta |
|---|---|---|
| Volatilidad de reglas | campos y estados estables | reglas cambian con frecuencia |
| Integraciones | una DB conocida | varios proveedores o broker |
| Riesgo | efecto reversible | dinero, inventario o cumplimiento |
| Equipo | pequeño y conjunto | varios equipos o ownership dividido |
| Vida útil | experimento acotado | producto duradero |

Una fuerza alta no ordena “arquitectura completa”; señala dónde comprar una frontera. Un proveedor de pagos volátil justifica `PaymentGateway` aunque el resto siga simple. Una DB estable no necesita repository genérico. Registra la decisión, la excepción y una señal de revisión: segunda entrada, incidente por acoplamiento, nueva regla o cambio de ownership.

## 4. 🧩 Plantilla mínima

```text
service/
├── src/<capability>/
│   ├── domain/           # vacío hasta que exista política
│   ├── application/      # casos de uso y puertos necesarios
│   └── infrastructure/   # entradas, salidas y composición
├── tests/
├── docs/decisiones/
├── build + lint + regla de dependencias
├── configuración validada + ejemplo sin secretos
├── health/readiness + cierre ordenado
└── observabilidad base de baja cardinalidad
```

La plantilla puede generar el build, una prueba de arranque, logging seguro, configuración tipada, health checks y un adapter HTTP de ejemplo. No debe generar `CustomerRepository`, eventos o agregados ficticios: esos nombres parecen guía pero consolidan decisiones sin contexto. Un ejemplo se elimina o renombra al crear el servicio.

## 5. 🧰 Adaptación por plataforma

| Plataforma | Qué automatizar | Qué no generar | Trampa frecuente |
|---|---|---|---|
| Java | módulos, build, reglas ArchUnit, config y test de contexto | interfaces para cada service y entity JPA de dominio | starter que impone capas globales |
| Node/TS | `tsconfig`, lint, validación runtime, build y cierre | tokens para dependencias que aún no existen | copiar un módulo Nest vacío por capacidad |
| Go | módulo, comandos de build/test, server y shutdown | paquete `interfaces` o repository genérico | tree enorme contrario a paquetes pequeños |
| Python | paquete, type checker, pytest, config y app factory | `Protocol` y modelos duplicados sin consumidor | globals de sesión en el skeleton |

## 6. ⚖️ Gobernanza y simplificación

Versiona la plantilla, prueba su generación en seco y publica una ruta de actualización; copiar repositorios sin evolución crea servicios congelados. Mide tiempo hasta producción, fallos de seguridad/configuración y cuánto código generado se borra. Si todos eliminan una abstracción, quítala de la plantilla. Si un control crítico se reimplementa distinto, automatízalo.

Revisa la profundidad en hitos, no cada semana: nueva integración, segundo driver, incidentes repetidos o equipo nuevo. Simplificar también es una decisión arquitectónica. Elimina puertos espejo, mappers idénticos y módulos vacíos cuando no protegen un cambio, conservando dirección y pruebas relevantes.

## ⚠️ Errores frecuentes

- “La mejor arquitectura es la más pura.” La mejor reduce riesgo a un coste sostenible.
- “La plantilla debe incluir todo lo que podría necesitarse.” El código preventivo se vuelve deuda inmediata.
- “Un árbol de carpetas garantiza límites.” Los imports y el build deben comprobarlos.
- “Generar dominio acelera al equipo.” Inventar política antes de conocerla produce nombres falsos.
- “La plantilla se copia una vez y termina.” Necesita versión, pruebas y camino de actualización.

## 7. ✅ Veredicto

Compra fronteras donde una fuerza concreta lo justifique. Automatiza seguridad, build, operación y verificación; deja que el equipo nombre dominio, puertos y casos de uso con evidencia. Revisa y elimina ceremonia cuando su coste supere la independencia que aporta.

## 📚 Referencias

- [Backstage: añadir Software Templates](https://backstage.io/docs/features/software-templates/adding-templates/)
- [Backstage: escribir y probar templates](https://backstage.io/docs/features/software-templates/writing-templates/)
- [GitHub: template repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository)
- [Cuándo no usarla y antipatrones](../01-fundamentos-y-modelo-mental/05-cuando-no-usarla-y-antipatrones.md)
- [Evolución desde un monolito](../04-adaptadores-de-salida-y-operacion/07-evolucion-y-migracion-desde-un-monolito.md)

## 🧠 Preguntas

1. 🟢 ¿Qué debe automatizar una plantilla de servicio?
2. 🟢 ¿Qué no debe inventar una plantilla?
3. 🟢 ¿Cuáles son las tres profundidades propuestas?
4. 🟢 ¿Qué cinco fuerzas usa la matriz?
5. 🟢 ¿Qué es una señal de revisión?
6. 🟢 ¿Por qué se versiona la plantilla?
7. 🟡 ¿Cuándo basta una profundidad directa?
8. 🟡 ¿Qué frontera selectiva introducirías para pagos?
9. 🟡 ¿Cuándo justificarías una separación completa?
10. 🟡 ¿Por qué una fuerza alta no obliga a crear todas las capas?
11. 🟡 ¿Qué controles pertenecen al skeleton y no al dominio?
12. 🟡 ¿Cómo pruebas una plantilla antes de publicarla?
13. 🟡 ¿Qué medirías para saber si la plantilla ayuda?
14. 🟡 ¿Por qué un repository genérico suele ser mala generación por defecto?
15. 🟡 ¿Qué cambia al aparecer un segundo driver?
16. 🟡 ¿Cuándo eliminas una abstracción generada?
17. 🟠 Un CRUD interno nace con outbox, broker y veinte interfaces. ¿Qué simplificas?
18. 🟠 Un servicio de pagos crítico usa handler y SQL directo. ¿Dónde compras fronteras primero?
19. 🟠 Cada equipo copia una versión distinta del template. ¿Qué capacidad de plataforma falta?
20. 🟠 El template incluye secretos de ejemplo funcionales. ¿Qué corriges?
21. 🟠 Todos borran tres módulos después de generar. ¿Qué evidencia te da?
22. 🟠 Una regla cambia en cinco archivos de transporte y persistencia. ¿Qué profundidad revisarías?
23. 🟠 El equipo quiere conservar un mapper idéntico “por pureza”. ¿Cómo decides?
24. 🟠 ¿Cómo defenderías una arquitectura deliberadamente simple en una entrevista senior?

**Siguiente:** [Simulación de entrevista](07-simulacion-de-entrevista.md).
