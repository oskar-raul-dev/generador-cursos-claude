# 03 — Dirección de dependencias y ciclos entre módulos

Aprenderás a leer el grafo de módulos y romper ciclos según ownership y flujo de información. Añadir
inyección de dependencias o un bus interno puede cambiar flechas de código; no corrige por sí solo un
límite falso, un ciclo de datos ni una coordinación circular.

## 1. 🎯 El ciclo que importa

`orders` consulta disponibilidad, `inventory` importa `Order` para reservar y `payments` llama de
vuelta a `orders` para cambiar su estado. El build revela:

```text
orders ──► inventory ──► payments
   ▲                         │
   └─────────────────────────┘
```

El ciclo impide razonar y probar una parte sin las demás. Pero quitar un import no basta: puede
quedar una tabla escrita por ambos o un flujo que exige disponibilidad circular.

## 2. 🗺️ Tres grafos y ownership

| Grafo | Arista | Pregunta |
|---|---|---|
| Estático | import, tipo o módulo de build | ¿quién conoce a quién? |
| Runtime | llamada, mensaje o callback | ¿quién activa a quién? |
| Datos | lectura o escritura | ¿quién posee y modifica estado? |

La dirección deseable nace de la responsabilidad. `orders` puede orquestar `CreateOrder` y depender
de la API de `inventory`; `inventory` no necesita conocer la entidad `Order`, solo el identificador
y las líneas que reserva. El propietario del pedido decide su estado después del resultado.

```text
orders ──comando──► inventory
orders ◄──resultado─ inventory

dependencia estática: orders ──► inventory.api
flujo de datos de retorno: no crea un import inverso
```

## 3. 🛠️ Estrategias para romper un ciclo

1. **Reducir el contrato:** reemplazar entidad ajena por un valor o resultado estable.
2. **Mover responsabilidad:** llevar la regla al módulo que posee la invariante.
3. **Invertir localmente:** el consumidor define una interfaz que composición implementa.
4. **Mediar el caso de uso:** un coordinador de aplicación conoce APIs sin volverlos pares circulares.
5. **Publicar un hecho:** cuando no se requiere respuesta inmediata ni atomicidad compartida.
6. **Fusionar módulos:** cuando el ciclo revela una única razón de cambio.

Cada opción conserva algo y cuesta algo. La mediación concentra flujo pero puede volverse un módulo
«orquestador» omnisciente. Un evento reduce conocimiento del consumidor, pero añade orden,
entrega y errores. Fusionar pierde separación nominal y puede recuperar cohesión real.

## 4. 🚫 Lo que DI y eventos no arreglan

Inyección de dependencias separa construcción de uso y permite invertir una referencia si la
abstracción vive con quien la necesita. Si `inventory` define `OrdersService` copiando todos los
métodos de `orders`, el ciclo semántico sigue.

Un bus interno puede esconder la arista:

```text
orders ─► bus ◄─ inventory
```

Pero si `OrderCreated` solo existe para ordenar a `inventory` reservar y el creador no puede
completar sin respuesta, hay un RPC disfrazado, ahora con handlers y orden implícito. Usa un evento
para un hecho consumado con consumidores opcionales o tolerantes al tiempo.

## 5. 🧪 Secuencia de refactoring reversible

1. Captura una prueba del flujo y el resultado actual.
2. Dibuja imports, llamadas y escrituras del ciclo.
3. Elige la arista con ownership más débil.
4. Crea un contrato mínimo junto al propietario correcto.
5. Migra un consumidor y prohíbe nuevas dependencias viejas.
6. Elimina la ruta anterior y vuelve a medir el grafo.

Si al reducir contratos cada operación sigue cruzando ida y vuelta, detente: quizá los módulos no son
unidades distintas. El criterio de éxito no es un grafo acíclico bonito, sino cambios y pruebas más
contenidos sin perder la garantía del caso de uso.

## 6. 🧰 Controles por ecosistema

| Plataforma | Mecanismo verificado | Qué detecta | Límite |
|---|---|---|---|
| Java | ArchUnit 1.5.1 | dependencias, capas y ciclos en bytecode | no entiende ownership de datos |
| Node/TypeScript | dependency-cruiser | imports prohibidos y ciclos | resolución dinámica puede escapar |
| Go | compilador y `depguard` de golangci-lint | ciclos de packages e imports denegados | no modela llamadas ni SQL |
| Python | Import Linter | contratos de capas e imports | imports dinámicos y datos requieren revisión |

Las versiones y capacidades se verificaron el 2026-09-27. Empieza con una regla pequeña en CI y un
baseline de deuda conocida. Cada excepción necesita motivo, responsable y fecha; de lo contrario el
control solo normaliza violaciones.

## 7. ⚖️ Decisión y coste

Rompe el ciclo que contradice ownership con el mecanismo más simple que conserve respuesta,
atomicidad y manejo de errores. Invierte dependencias si protege una política; media si el flujo
pertenece a aplicación; usa eventos si el tiempo puede separarse; fusiona si la frontera era falsa.
Pagas contratos, mapeos y controles a cambio de cambio localizado.

## ⚠️ Errores frecuentes

- «Un event bus interno elimina cualquier ciclo». Puede ocultarlo o convertirlo en temporal.
- «DI corrige la dirección automáticamente». El dueño de la abstracción decide la inversión.
- «Todo ciclo debe romperse». A veces indica que debe fusionarse el límite.
- «Un grafo estático limpio prueba autonomía». Datos y runtime pueden conservar el ciclo.
- «Prohibir todas las violaciones de golpe es más riguroso». Un baseline útil evita nuevas mientras se retira deuda.

## 8. ✅ Veredicto

Usa el grafo para formular preguntas, no para reemplazar el diseño. Alinea la dirección con quién
decide y posee datos, conserva la semántica del flujo y automatiza la frontera mínima. Si romper el
ciclo produce contratos que copian el modelo completo, revisa el límite antes de añadir mediadores o
eventos.

## 📚 Referencias

- [ArchUnit User Guide 1.5.1](https://www.archunit.org/userguide/html/000_Index.html)
- [dependency-cruiser rules reference](https://github.com/sverweij/dependency-cruiser/blob/main/doc/rules-reference.md)
- [depguard settings, golangci-lint](https://golangci-lint.run/docs/linters/configuration/#depguard)
- [Import Linter — Layers contract](https://github.com/seddonym/import-linter/blob/main/docs/contract_types/layers.md)

## 🧠 Preguntas

1. 🟢 ¿Qué representa una arista en el grafo estático?
2. 🟢 ¿Qué representa una arista en el grafo runtime?
3. 🟢 ¿Qué representa una arista en el grafo de datos?
4. 🟢 ¿Qué es un ciclo entre módulos?
5. 🟢 ¿Qué significa invertir una dependencia localmente?
6. 🟢 ¿Qué función cumple un mediador de aplicación?
7. 🟢 ¿Cuándo fusionar módulos puede ser la corrección adecuada?
8. 🟡 ¿Por qué un resultado de `inventory` no crea necesariamente una dependencia estática inversa?
9. 🟡 ¿Cómo ayuda el ownership a elegir la dirección de una dependencia?
10. 🟡 ¿Qué diferencia hay entre reducir un contrato y esconder una arista?
11. 🟡 ¿Cuándo una interfaz logra inversión y cuándo solo renombra el proveedor?
12. 🟡 ¿Qué riesgo tiene un coordinador de aplicación omnisciente?
13. 🟡 ¿Cuándo un evento interno es un RPC disfrazado?
14. 🟡 ¿Qué garantía debes revisar antes de sustituir una llamada por un evento?
15. 🟡 ¿Por qué un grafo acíclico no demuestra autonomía?
16. 🟡 ¿Qué aporta un baseline de violaciones conocidas?
17. 🟡 ¿Qué detectan ArchUnit y dependency-cruiser y qué dejan fuera?
18. 🟠 Un ciclo desaparece de imports, pero ambos módulos escriben la misma tabla. ¿Qué harías después?
19. 🟠 `payments` llama a `orders` para cambiar su estado. ¿Dónde ubicarías la decisión y por qué?
20. 🟠 Un evento requiere respuesta inmediata para confirmar checkout. ¿Qué mecanismo elegirías?
21. 🟠 Romper un ciclo exige copiar veinte tipos en una interfaz. ¿Qué hipótesis revisarías?
22. 🟠 CI encuentra doscientos ciclos existentes. ¿Cómo introducirías el control sin paralizar al equipo?
23. 🟠 Una excepción de dependencia es necesaria durante una migración. ¿Qué metadatos y criterio de retirada exigirías?
24. 🟠 ¿Qué prueba y métrica usarías para demostrar que el refactoring redujo el acoplamiento?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [02 — API pública del módulo y encapsulación interna](02-api-publica-del-modulo-y-encapsulacion-interna.md).

**Siguiente:** [04 — Propiedad de datos en una base compartida](04-propiedad-de-datos-en-una-base-compartida.md).
