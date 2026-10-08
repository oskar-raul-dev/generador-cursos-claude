# 🐹 Go para desarrolladores Java senior

Un curso rápido y práctico para quien ya lleva años diseñando sistemas en Java y
quiere escribir Go **que un gopher reconocería como suyo** — no Java con llaves
distintas.

No se explica qué es una variable, un bucle, una API REST ni una transacción. Se
explica, siempre, **dónde el modelo de Go difiere del de Java** y qué reflejo hay
que recalibrar.

---

## 🎯 Qué vas a construir

Cuatro servicios de la plataforma de **Meridian Retail Group**, una empresa
ficticia con ciento cuarenta tiendas y treinta socios integrados por API:

| Servicio | Qué resuelve | Eje técnico |
|---|---|---|
| **OpsReport** | Trabajos operativos y reportes | CRUD, jobs asíncronos, PostgreSQL, streaming |
| **EventRelay** | Webhooks a socios comerciales | Cliente HTTP, reintentos, idempotencia, resiliencia |
| **AtlasSync** | Catálogo de datos de referencia | APIs públicas, MongoDB, Valkey, la pirámide de pruebas completa |
| **ClearingHouse** | Conciliación y cierre por lotes | SQLite en el borde, lotes reanudables, y el duelo contra Spring Boot |

Más cuarenta y seis mini proyectos que aíslan un concepto antes de llevarlo al
servicio grande.

---

## 🕰️ La estructura: dos épocas y una frontera

```text
Bloque A — Fases 00-07   Go 1.13, stdlib pura     El lenguaje sin azúcar
Bloque B — Fase 08 ⭐     La migración              Dos servicios reales migran
Bloque C — Fases 09-17   Go moderno, ecosistema   El Go que vas a escribir
```

Empezar en **Go 1.13** no es nostalgia. Sin genéricos no hay dónde esconder un
diseño perezoso; sin `slog` se ve qué es un log estructurado; sin `ServeMux`
moderno hay que escribir el enrutado a mano una vez, que es la única forma de
entender qué hace Spring MVC por debajo de `@GetMapping`.

Y migrar **a mitad del curso**, no al final, tiene su razón: así más de la mitad
del material transcurre en el Go que de verdad vas a escribir, y la migración
misma es rica, porque migra dos servicios con persistencia, concurrencia y tests
— no un puñado de ejemplos.

---

## 📚 Cómo está escrito

**"Diciendo y haciendo".** Ningún bloque teórico pasa de dos pantallas sin un
comando o un fragmento de código. El ciclo se repite fase tras fase:

```text
el problema → el comando → el código mínimo → ejecútalo → qué observas
  → cómo sería en Java → rómpelo → el test → llévalo al proyecto
```

Cada fase lleva, obligatoriamente:

- 🪞 **Tu instinto de Java dice… y esta vez se equivoca**
- 🩻 **Esto sí funciona igual** — el contrapeso honesto
- ⚰️ **Autopsia de un antipatrón**, con su costo en números
- 🛠️ **CLI de la fase** — el toolchain sin IDE, que es medio Go
- 📖 **Diccionario Java ⇄ Go**, en las dos direcciones
- ⚖️ **Cuándo NO usar esto**
- 🧪 **20 a 30 ejercicios**, un tercio de diagnóstico
- 🔴 **Tres desafíos de cierre** fuera del conteo, para lo que la fase dejó fuera
- 📚 **Referencias** con su orden de lectura, y la advertencia de qué está fechado

Y una regla que gobierna todo el material: **ninguna afirmación de rendimiento se
escribe sin su medición en [`BENCHMARKS.md`](BENCHMARKS.md)** — incluidas las que
parecen obvias.

---

## ⚖️ El veredicto honesto

El curso termina midiendo el mismo servicio implementado dos veces, en Go y en
Spring Boot 3, con la JVM ajustada y con `native-image` — porque comparar contra
una JVM sin configurar es hacer trampa.

Y termina diciendo **dónde quedarse en Spring Boot es la decisión correcta**.
Si el resultado fuera "Go gana en todo", el curso estaría mal escrito.

> ⚠️ El gemelo Spring Boot de ClearingHouse **todavía no se publica** con el curso:
> la Fase 16 explica cómo seguir sin él. Y las cifras que verás en las salidas de las
> fases son ilustrativas; las que cuentan son las que mides tú en
> [`BENCHMARKS.md`](BENCHMARKS.md).

---

## 🗺️ Por dónde empezar

1. [`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md) — el mapa de las 18 fases
2. [`00-instalacion-ambiente-y-tooling.md`](00-instalacion-ambiente-y-tooling.md) — deja la máquina lista
3. De ahí en orden. Las fases se apoyan unas en otras y no se saltan.

Documentos transversales:
[`00-historia-de-la-empresa-meridian.md`](00-historia-de-la-empresa-meridian.md)
(quién es Meridian y de dónde sale cada servicio),
[`INSTINTOS.md`](INSTINTOS.md) (el catálogo de reflejos ☕),
[`BENCHMARKS.md`](BENCHMARKS.md) (el banco de pruebas) y
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

**Requisitos:** ocho años o más de backend en Java, Docker, y un terminal.
**Duración:** 131 horas · unos treinta y tres días de media jornada.
