# 03 — Recuperar modularidad en un monolito legado

Aprenderás a recuperar una capacidad vertical dentro de un legado sin reorganizar todo el árbol ni
mantener una reescritura paralela: cómo elegir la costura, cómo ordenar los pasos cuando no se conocen
de antemano y cómo saber si la recuperación está sirviendo.

## 1. 🎯 Síntoma y decisión

El monolito de comercio lleva seis años en producción. Las correcciones de reservas aparecen en once
archivos repartidos entre `orders`, un job de reembolsos y un controlador de administración; en el
último trimestre, tres de cada cuatro regresiones de cancelación vinieron de cambios que nadie creía
relacionados. El equipo propone dos cosas: mover todas las clases a carpetas por dominio en un sprint,
o empezar un monolito modular nuevo en paralelo y migrar cuando esté listo.

La primera cambia carpetas sin cambiar dependencias; la segunda congela el negocio o persigue un
objetivo que se mueve. La decisión de este capítulo es por dónde empezar, cómo avanzar sin romper lo
que funciona y cuándo detenerse.

## 2. 🧠 Modelo mental

Se recupera una capacidad a la vez, de forma vertical: una entrada, sus reglas y sus escrituras,
detrás de una fachada, hasta que un solo módulo es su dueño. Cada paso deja el sistema funcionando y
se integra en la línea principal.

```text
entrada de cancelación → reglas actuales → escrituras de reserva → resultado observable
        │ caracterizar el comportamiento
        ▼
fachada ReleaseReservation → implementación anterior
        │ pasar consumidores por la fachada, conservando el contrato
        ▼
fachada ReleaseReservation → implementación nueva → único escritor de inventory
```

No se necesita la arquitectura final completa para empezar. Hace falta una ruta con salida
observable, un dueño y un alcance de datos identificable, y una red de pruebas que diga si el
comportamiento cambió.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | once archivos escriben reservas, entre ellos un job de reembolsos y un controlador de administración; tres de cada cuatro regresiones de cancelación en el trimestre; los cambios de reservas coinciden en commits con cambios de `orders`; no hay pruebas que cubran la cancelación repetida ni la reserva vencida |
| Inferencia | la regla de liberación de `inventory` está mezclada con `orders` y repartida en varios escritores |
| Diagnóstico | *hotspot* de alta frecuencia de cambio y alto defecto en la liberación de reservas, sin dueño ni red de pruebas |
| Recomendación | caracterizar la cancelación, introducir la fachada `ReleaseReservation`, pasar los escritores por ella en el orden que descubra el método Mikado y dejar a `inventory` como único escritor |

Un *hotspot* combina frecuencia de cambio con dificultad o defectos: un archivo enorme que nunca
cambia no es prioridad. Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si los
archivos cambiaron juntos por un reformateo o una actualización de dependencias, el historial exagera
el acoplamiento; se confirma con accesos SQL y trazas, no solo con commits.

## 4. 🛠️ Caracterizar, abstraer y ordenar

**Caracterizar antes de mover.** Las pruebas de caracterización registran qué hace hoy el sistema con
la cancelación repetida, la reserva vencida y el pedido inexistente. No convierten cada bug en
requisito: con negocio se clasifica qué conducta se preserva y cuál se corrige en un cambio separado.
Si no hay pruebas fiables, se empieza por observación y casos anonimizados antes de mover escrituras.

**Branch by abstraction.** Permite sustituir la implementación detrás de una interfaz sin ramas
largas. La fachada publica identidad de pedido y resultado, y oculta las tablas antiguas. Primero
todos los consumidores pasan por ella; después se cambia el interior. Mientras alguien siga
escribiendo directo, la propiedad no se ha recuperado.

**Método Mikado para ordenar la secuencia.** En un legado, el orden de los pasos rara vez se conoce
de antemano. El método de Ola Ellnestam y Daniel Brolund lo descubre: se intenta el cambio objetivo
directamente, se anota como prerrequisito todo lo que se rompe, se **revierte** el intento y se empieza
por las hojas del grafo.

```text
objetivo: ReleaseReservation es el único escritor de reservas
   ├─ el servicio de cancelación usa la fachada
   │     └─ la fachada devuelve el resultado que hoy lee ese servicio
   ├─ el job de reembolsos usa la fachada
   │     └─ caracterizar el reembolso de pedidos enviados en parte
   └─ el controlador de administración deja de escribir la tabla
         └─ inventory expone una operación de ajuste
```

- Cada hoja es un cambio pequeño que deja el sistema funcionando y se integra en la línea principal.
- El grafo es el plan y el registro de avance: muestra qué falta y por qué, y se puede repartir entre
  varias personas sin pisarse.
- El precio es la disciplina de revertir el intento fallido en lugar de «arreglar lo que falta» sobre
  la marcha, que es lo que produce refactors de semanas que no terminan.

## 5. 💻 Implementación mínima de la transición

Pseudocódigo de la selección de ruta; no ejecuta ambas escrituras:

```text
ReleaseReservation(orderId):
    route = cohorts.stableRoute(orderId)
    if route == NEW: return newInventory.release(orderId)
    return legacyInventory.release(orderId)
```

- La ruta se decide por pedido y permanece estable en reintentos, consultas y cancelaciones.
- Si las dos implementaciones usan la misma tabla, comparten una sola política de escritura y las
  mismas restricciones; si hay copia de datos, se aplica la
  [migración de autoridad](04-extraer-un-modulo-a-servicio.md) antes del corte.
- La comparación en sombra se limita a lecturas o cálculos sin efectos, con diferencias clasificadas:
  no reserva ni libera dos veces.

Tras validar una cohorte, se amplía; la implementación anterior se retira cuando no tiene
consumidores y termina la ventana de recuperación.

## 6. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | fachada de paquete, compilación de los consumidores y regla arquitectónica | accesos SQL ocultos en consultas nativas | mover clases públicas y conservar el acoplamiento |
| Node/TypeScript | API del paquete y revisión de imports | imports dinámicos y payloads sin validar | suponer que compilar prueba la migración |
| Go | paquete con API pequeña, `internal/` y pruebas de integración | dependencias de datos | reemplazar imports sin mover la autoridad sobre las tablas |
| Python | caracterización y contratos de importación | cobertura de rutas dinámicas | renombrar paquetes sin ejercitar los flujos |

Las cuatro trampas confunden mover código con mover autoridad. El compilador y las reglas de imports
confirman que los consumidores pasan por la fachada en el código; no ven un `UPDATE` en una consulta
nativa, un script de administración ni un import dinámico. Por eso la recuperación combina
[controles arquitectónicos](../02-modularidad-y-limites-internos/06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md)
sobre la costura nueva con permisos de base y pruebas de caracterización. Y sobre un legado con miles
de violaciones, la regla bloquea las nuevas y reduce el inventario conocido, en lugar de convertir la
CI en una pared.

## 7. ⚖️ Decisión y coste

Entrega una costura vertical utilizable y demuestra que un cambio real pasa por ella. Pagas
caracterización, adaptadores transitorios y doble mantenimiento limitado; compras que la regla cambie
bajo un dueño y con pruebas. Compara cambios de reserva semejantes antes y después —componentes
tocados, defectos, tiempo de entrega, esperas de revisión— sin atribuir a la costura una mejora que
viene de menos trabajo. Si la evidencia no mejora, detén la expansión y revisa la costura; un legado
estable puede necesitar solo esa reparación. Para un sistema ya distribuido, se añade la
[recuperación de runtime y releases](../04-monolito-distribuido/08-desmontar-un-monolito-distribuido.md).

## ⚠️ Errores frecuentes

- «Movemos todo a carpetas por dominio en un sprint y ya es modular». Cambia la ubicación, no las
  dependencias ni los escritores.
- «Empezamos un monolito modular nuevo en paralelo». El destino se mueve mientras el legado sigue
  cambiando, y nada llega a producción hasta el final.
- «Ejecutamos las dos implementaciones con efectos para comparar». Libera o reserva dos veces; en
  sombra solo se comparan lecturas.
- «Los bugs que aparecen al caracterizar se corrigen sobre la marcha». Se decide con negocio cuáles se
  preservan y cuáles se corrigen, y la corrección va en un cambio aparte.
- «Si el cambio objetivo rompe cinco cosas, se arreglan todas en la misma rama». El método Mikado
  revierte el intento y empieza por las hojas; la rama rota durante semanas es lo que evita.

## 8. ✅ Veredicto

Elige el *hotspot* por frecuencia de cambio y defectos, caracteriza su comportamiento, pon una
fachada delante y pasa los consumidores por ella en el orden que descubra el método Mikado, hasta que
un solo módulo escriba sus datos. Amplía a otra capacidad solo cuando la mejora medida compense la
convivencia temporal, y detente cuando deje de hacerlo.

## 📚 Referencias

- [Branch By Abstraction, Martin Fowler](https://martinfowler.com/bliki/BranchByAbstraction.html)
- [Legacy Seam, Martin Fowler](https://martinfowler.com/bliki/LegacySeam.html)
- [Characterization Testing, Michael Feathers](https://michaelfeathers.silvrback.com/characterization-testing)
- [The Mikado Method, Ola Ellnestam y Daniel Brolund](https://mikadomethod.info/)

## 🧠 Preguntas

1. 🟢 ¿Qué es un *hotspot* útil para empezar una recuperación?
2. 🟢 ¿Qué caracteriza a una costura vertical?
3. 🟢 ¿Qué registra una prueba de caracterización y qué no afirma?
4. 🟢 ¿Qué aporta *branch by abstraction*?
5. 🟢 ¿Qué debe ocultar la fachada `ReleaseReservation`?
6. 🟡 ¿Por qué no mover todas las clases a carpetas por dominio en un sprint?
7. 🟡 ¿Cómo distinguirías un cambio conjunto accidental de una cohesión real en el historial?
8. 🟡 ¿Qué harías con un bug que descubres al caracterizar la cancelación?
9. 🟡 ¿En qué orden migras a los consumidores hacia la fachada?
10. 🟡 ¿Qué significa una cohorte estable en esta transición?
11. 🟡 ¿Qué puedes comparar en sombra y qué no?
12. 🟡 ¿Por qué no liberar reservas en las dos rutas a la vez?
13. 🟡 ¿Cómo controlas las violaciones históricas de imports sin bloquear al equipo?
14. 🟡 ¿Qué métricas comparas antes y después de la costura interna?
15. 🟡 ¿Cuándo retiras la implementación anterior?
16. 🟡 ¿Qué coste tiene mantener dos implementaciones durante la transición?
17. 🟡 ¿En qué se diferencian la compilación de Java y los contratos de importación de Python como red de esta migración?
18. 🟠 ¿Qué riesgo comparten los imports de TypeScript y los paquetes de Go al refactorizar, y qué no ven ninguno de los dos?
19. 🟠 ¿Cómo abortas la transición si las dos rutas usan la misma tabla?
20. 🟠 ¿Cómo abortas si ya cambiaste el almacenamiento de las reservas?
21. 🟠 Tras la costura, las esperas de revisión aumentan en lugar de bajar. ¿Qué haces?
22. 🟠 Llega una entrega urgente que toca reservas a mitad de la migración. ¿Cómo actúas?
23. 🟠 ¿Qué evidencia exigirías antes de ampliar la recuperación a otra capacidad?
24. 🟠 ¿Cuándo pararías la recuperación del legado?
25. 🟠 Al intentar que `ReleaseReservation` sea el único escritor, el build y las pruebas fallan en cinco lugares. ¿Cómo usarías el método Mikado para ordenar el trabajo?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [02 — Diseñar un monolito modular desde cero](02-disenar-un-monolito-modular-desde-cero.md).

**Siguiente:** [04 — Extraer un módulo a servicio](04-extraer-un-modulo-a-servicio.md).
