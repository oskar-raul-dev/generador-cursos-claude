# 05 — Plataformas

> El bloque que responde la pregunta que ningún libro de microservicios contesta: *¿qué me cuesta
> este patrón en mi plataforma?* Recorre Java, Node/TS, Go y Python, y cierra con la matriz de
> decisión. **No vuelve a explicar ningún patrón**: los enlaza.
>
> **Vigencia:** 2026-09-29.

---

## Orden de lectura

| Documento | Qué fija |
|---|---|
| [`01` — Qué cambia entre plataformas](01-que-cambia-entre-plataformas.md) | Los siete ejes, la baseline y **la tabla maestra** |
| [`02` — Java](02-java.md) | Ecosistema, modelo de ejecución, nativo y las trampas de lo declarativo |
| [`03` — Node y TypeScript](03-node-y-typescript.md) | Bucle de eventos, tipos que no validan, y el BFF |
| [`04` — Go](04-go.md) | `context`, goroutines, errores como valores y el cableado explícito |
| [`05` — Python](05-python.md) | WSGI contra ASGI, el bloqueo global y el empaquetado |
| [`06` — La matriz de decisión](06-la-matriz-de-decision.md) | **Cómo se elige**, y la política de plataformas |
| [`07` — Simulación de entrevista](07-simulacion-de-entrevista.md) | 34 preguntas transversales y 5 escenarios |
| [`08` — Respuestas](08-respuestas.md) | El solucionario del bloque, en tres capas |

**144 preguntas de capítulo** más las transversales, todas con respuesta en `08`.

---

## El mapa mental

```text
lo que NO decide     velocidad del lenguaje · sintaxis
lo que SÍ decide     equipo · ecosistema por patrón · operación · perfil de carga
                     · y si esa plataforma YA existe en la casa
                                    │
      ┌──────────────┬──────────────┼──────────────┬──────────────┐
    Java          Node/TS          Go           Python      la matriz
  da hecho       el borde      lo explícito     datos       (06): cómo
  lo transaccional y el tiempo  y el perfil     y tareas     se elige
                   real          operativo
```

---

## Qué NO está aquí

- **Los patrones**: están en los bloques [`02`](../02-comunicacion/),
  [`03`](../03-datos-y-consistencia/) y [`04`](../04-operacion-y-resiliencia/). Este bloque solo dice
  qué te da cada plataforma para ellos.
- **Spring por dentro** —contenedor, proxies, autoconfiguración, Batch, Security—: de
  [`frameworks/01-spring-boot`](../../../frameworks/01-spring-boot/).
- **Algoritmos y estructuras comparados entre lenguajes**: de
  [`bases/01-bases`](../../../bases/01-bases/), que compara cinco lenguajes por su
  librería estándar.
- **Cómo se despliega cada plataforma en una nube concreta**: de
  [`cloud/01-aws`](../../../cloud/01-aws/) y
  [`cloud/02-gcp`](../../../cloud/02-gcp/).

---

**Anterior:** [`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/) · **Siguiente,
opcional:** [`06-talleres`](../06-talleres/) · **Índice:** [`README.md`](../README.md)
