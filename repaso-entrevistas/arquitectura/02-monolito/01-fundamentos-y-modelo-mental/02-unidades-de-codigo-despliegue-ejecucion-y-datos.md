# 02 — Unidades de código, despliegue, ejecución y datos

Aprenderás a nombrar qué está unido antes de juzgar el acoplamiento. Repositorio, artefacto,
proceso, réplica, esquema, transacción y equipo responden preguntas diferentes; confundirlos produce
diagnósticos y migraciones equivocadas.

## 1. 🎯 El síntoma

El equipo dice: «Tenemos un monolito porque todo está en Git». Sin embargo, `payments` produce un
artefacto propio y se despliega sin `orders`. Otro equipo afirma: «Tenemos microservicios porque
Kubernetes muestra cuatro pods», aunque los cuatro ejecutan la misma imagen y versión.

Ambas conclusiones saltan de una observación a un diagnóstico sin identificar la unidad relevante.

## 2. 🗺️ El mapa de unidades

| Unidad | Pregunta | Ejemplo |
|---|---|---|
| Repositorio | ¿qué historial y permisos comparte el código? | monorepo de comercio |
| Build | ¿qué se compila o valida junto? | workspace con cuatro módulos |
| Artefacto | ¿qué paquete versionado se entrega? | `commerce-v18.jar` |
| Despliegue | ¿qué se promueve o revierte junto? | una release de la aplicación |
| Proceso | ¿qué comparte memoria y destino de fallo? | JVM, proceso Node, binario Go |
| Réplica | ¿qué copia equivalente atiende carga? | tres instancias de v18 |
| Esquema | ¿qué estructura lógica organiza datos? | tablas `orders` y `payments` |
| Transacción | ¿qué cambios confirman o revierten juntos? | pedido más reserva |
| Equipo | ¿quién decide y opera una capacidad? | equipo Checkout |

Estas unidades pueden alinearse, pero no tienen que hacerlo. Un monorepo puede producir servicios
independientes. Varios repositorios pueden ensamblarse en un solo artefacto. Un proceso puede abrir
varias conexiones y una base puede alojar datos con propietarios distintos.

## 3. 🔀 Tres grafos, no una flecha

```text
dependencia de código:  orders ──importa──► inventory API
flujo de ejecución:     HTTP ──► orders ──llama──► inventory
dependencia operativa:  checkout ──requiere disponible──► base/proveedor de pago
```

Un import indica conocimiento estático; no prueba que la llamada ocurra en cada petición. Una
llamada runtime puede invertirse mediante una interfaz sin cambiar quién debe estar disponible. Un
evento puede eliminar espera inmediata y mantener acoplamiento de contrato o datos. Hay que dibujar
los grafos por separado.

## 4. 💱 Las cinco monedas

Para `CreateOrder`, pregunta:

1. **Código:** ¿qué debe cambiar y validarse cuando cambia la reserva?
2. **Datos:** ¿quién escribe el stock y qué confirma atómicamente?
3. **Despliegue:** ¿qué versiones deben convivir o liberarse juntas?
4. **Runtime:** ¿qué componentes deben responder para completar la operación?
5. **Equipos:** ¿quién puede decidir y operar sin reunión interequipos?

No busques independencia total. Si `orders` e `inventory` comparten una invariante fuerte y un
equipo, pagar una transacción y release comunes puede ser razonable. Si cambian y escalan de forma
distinta, la misma unión puede volverse cara.

## 5. 🧰 Cómo se materializan las unidades

| Plataforma | Build y artefacto frecuentes | Ejecución y datos | Trampa frecuente |
|---|---|---|---|
| Java | módulos Maven/Gradle dentro de uno o varios JAR | una o varias JVM y pools JDBC | equiparar módulo de build con autonomía |
| Node/TypeScript | paquetes/workspaces y salida JS o bundle | uno o varios procesos y pools | confundir worker con servicio |
| Go | paquetes en un módulo y uno o varios binarios | procesos del binario y conexiones SQL | equiparar `go.mod` con despliegue |
| Python | paquetes y wheel/zipapp/imagen | procesos ASGI/WSGI, workers y conexiones | tratar cada worker como versión distinta |

El formato ayuda a observar, no decide la arquitectura. Comprueba qué comando produce qué artefacto,
qué pipeline lo promueve y qué versión corre realmente.

## 6. 🔬 Secuencia de diagnóstico

```text
1. seguir un cambio real en Git y CI
2. enumerar artefactos producidos
3. observar promociones, rollbacks y versiones convivientes
4. trazar procesos, réplicas y dependencias runtime
5. localizar propietarios de escritura y fronteras transaccionales
6. contrastar con ownership y coordinación de equipos
```

El resultado puede ser asimétrico: independencia de código con datos compartidos, despliegues
separados con release train o procesos distintos operados por el mismo equipo. Esa asimetría es el
hallazgo; no la ocultes bajo una etiqueta prematura.

## 7. ⚖️ Decisión y coste

Alinear varias unidades simplifica: un build, una release y una transacción reducen coordinación
técnica. Separarlas puede comprar aislamiento o cadencia, pero exige compatibilidad, observabilidad y
ownership explícito. El criterio no es contar repositorios o procesos, sino comprobar qué autonomía
obtienes y qué moneda pagas.

## ⚠️ Errores frecuentes

- «Un repositorio equivale a un monolito». El repositorio no determina el despliegue.
- «Varios procesos equivalen a servicios». Pueden ser réplicas o workers del mismo release.
- «Un esquema es una base física». Es una organización lógica dentro de un motor.
- «DI elimina la dependencia runtime». Puede invertir código y conservar disponibilidad requerida.
- «Separar el build separa los datos». Son unidades distintas.

## 8. ✅ Veredicto

Antes de recomendar modularizar o distribuir, nombra la unidad exacta que causa dolor. Sigue cambios
reales a través de código, datos, despliegue, runtime y equipos. Una arquitectura madura no maximiza
separaciones: alinea las necesarias para conservar garantías al menor coste total.

## 📚 Referencias

- [JAR File Specification, Oracle](https://docs.oracle.com/en/java/javase/25/docs/specs/jar/jar.html)
- [Modules: Packages, Node.js](https://nodejs.org/api/packages.html)
- [How to Write Go Code, Go](https://go.dev/doc/code)
- [zipapp — Manage executable Python zip archives, Python](https://docs.python.org/3/library/zipapp.html)

## 🧠 Preguntas

1. 🟢 ¿Qué pregunta responde un repositorio?
2. 🟢 ¿Qué diferencia hay entre build y artefacto?
3. 🟢 ¿Qué es una unidad de despliegue?
4. 🟢 ¿Qué distingue un proceso de una réplica?
5. 🟢 ¿Qué pregunta responde una frontera transaccional?
6. 🟢 ¿Cuáles son las cinco monedas de una decisión arquitectónica?
7. 🟢 ¿Qué diferencia hay entre esquema lógico y base física?
8. 🟡 ¿Por qué un monorepo puede contener varios servicios autónomos?
9. 🟡 ¿Por qué varios repositorios pueden terminar en un monolito?
10. 🟡 ¿Qué diferencia hay entre dependencia de código y flujo de ejecución?
11. 🟡 ¿Qué diferencia hay entre flujo de ejecución y dependencia operativa?
12. 🟡 ¿Qué demuestra un import y qué no demuestra?
13. 🟡 ¿Cómo puede una interfaz invertir código sin eliminar acoplamiento temporal?
14. 🟡 ¿Qué evidencia usarías para identificar el despliegue real?
15. 🟡 ¿Por qué un módulo de build no concede ownership de datos?
16. 🟡 ¿Qué ganas y qué pagas al alinear build, artefacto y despliegue?
17. 🟡 ¿Cómo compararías un worker Node con una réplica de un binario Go?
18. 🟠 CI produce cuatro artefactos pero un pipeline siempre los libera juntos. ¿Qué autonomía existe?
19. 🟠 Dos equipos poseen carpetas distintas, pero ambos escriben `inventory`. ¿Qué unidad está mal definida?
20. 🟠 Un cambio de contrato compila sin tocar consumidores, pero obliga a desplegarlos juntos. ¿Qué grafos revisarías?
21. 🟠 Un incidente aparece solo cuando conviven versiones durante rolling deployment. ¿Qué unidades relacionarías?
22. 🟠 Se propone dividir el repositorio para reducir coordinación. ¿Qué evidencia pedirías primero?
23. 🟠 `payments` está en otro proceso, pero comparte transacción mediante 2PC. ¿Qué independencia obtuvo y qué coste añadió?
24. 🟠 ¿Cómo presentarías un sistema que es independiente en código pero no en datos ni equipos?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [01 — Qué es una arquitectura monolítica](01-que-es-una-arquitectura-monolitica.md).

**Siguiente:** [03 — Monolito tradicional, modular y *big ball of mud*](03-monolito-tradicional-modular-y-big-ball-of-mud.md).
