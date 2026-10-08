# 08 — Entrada, salida y recursos

> El bloque del **recurso del sistema operativo**: el descriptor que todo lo abre, el hilo que espera,
> el búfer que se cruza y el árbol que se recorre. Es el más cercano a la máquina de todo el corpus y
> el que explica los incidentes que parecen otra cosa — el servicio que se cae con memoria de sobra,
> el proceso por lotes que tarda ocho horas con la CPU al 8 %, el trabajo nocturno que se colgó una
> vez en dos años.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md)

---

## Qué es esto, y por qué aquí

```text
descriptor  promete un asa universal    → y archivos y sockets no se comportan igual
epoll       promete vigilar descriptores → y no sirve para archivos regulares
O(n)        promete coste lineal         → y el búfer cambia el tiempo por once mil
el árbol    promete ser un árbol         → y un enlace simbólico lo vuelve un grafo con ciclos
```

Los cuatro capítulos comparten una idea: **el coste no está donde dice la notación asintótica, sino en
cuántas veces cruzas la frontera entre tu proceso y el sistema**. Y comparten una pregunta, que es la
que hay que llevar a una entrevista:

> **¿Qué hace mi hilo mientras espera?**

Todo lo demás —modelos de servidor, hilos virtuales, bucles de eventos, contrapresión— son respuestas
distintas a esa misma pregunta.

Las preguntas **no llevan la respuesta al lado**: viven en [`07-respuestas.md`](07-respuestas.md).

---

## Orden de lectura

| # | Documento | Qué cubre |
|---|---|---|
| `01` | [El descriptor y el recurso](01-el-descriptor-y-el-recurso.md) | Qué es un descriptor, los tres límites, fugas, cierre determinista en los cinco lenguajes, diagnóstico |
| `02` | [Todo es un archivo, y dónde se rompe](02-todo-es-un-archivo.md) | El paradigma y sus cuatro roturas: archivos no seleccionables, `read` ambiguo, Windows, el pool de `libuv` |
| `03` | [Bloqueante, no bloqueante y asíncrono](03-bloqueante-no-bloqueante-y-asincrono.md) | Los dos ejes, los cinco modelos de servidor medidos, el incidente del pool acotado |
| `04` | [Búferes y el coste de la frontera](04-buferes-y-el-coste-de-la-frontera.md) | La curva del tamaño de búfer, los tres niveles de "escrito", `fsync`, contrapresión |
| `05` | [El árbol de directorios](05-el-arbol-de-directorios.md) | Enlaces y ciclos, detección por inodo, el coste de `stat`, lo que falla a mitad |
| `06` | [Simulación de entrevista](06-simulacion-de-entrevista.md) | 36 preguntas transversales + 5 problemas de pizarra |
| `07` | [Respuestas](07-respuestas.md) | Solucionario completo del bloque, en tres capas |

**Si el calendario aprieta:** `01` y `03`. El primero porque `Too many open files` es un incidente que
se pregunta y casi nadie sabe diagnosticar; el segundo porque "bloqueante o no bloqueante" aparece en
cualquier entrevista de backend senior y casi nadie distingue los dos ejes.

---

## Las cinco cosas que este bloque deja claras

1. **El límite que aplica no es el que dice `ulimit`.** Medido: `ulimit -n` dice 1 048 576 y el proceso
   muere a los **122 877**, porque manda `kern.maxfilesperproc`.
2. **`FileChannel` no es `SelectableChannel`, y no compila.** La ruptura del paradigma "todo es un
   archivo" es un error del compilador de Java, no una curiosidad teórica.
3. **2 014 hilos del sistema contra 35** para atender 2 000 conexiones con la misma latencia. Lo que
   cambia con los hilos virtuales no es la velocidad: es cuántos caben.
4. **Leer byte a byte tarda 1 879 ms; en bloques de 64 KB, 0,17 ms.** Mismo `O(n)`, factor de once mil.
5. **Un enlace simbólico a un ancestro cuelga a Python, no afecta a Go y lanza excepción en Java.** El
   mismo árbol, tres comportamientos.

---

## Qué NO está aquí

- **Estructuras de datos entre hilos, `ConcurrentHashMap`, colas acotadas y los cinco modelos de
  concurrencia** → [`06/03`](../06-numeros-tiempo-concurrencia/03-estructuras-y-concurrencia.md), que
  este bloque asume leído. Allí el ángulo es la **estructura**; aquí, el **recurso del sistema**.
- **Detección de ciclos y recorridos de grafos en general** →
  [`04/03`](../04-arboles-grafos/03-grafos-representacion-y-recorridos.md). Aquí solo su aplicación al
  sistema de archivos.
- **Recursión frente a iteración y la conversión con pila explícita** →
  [`01-fundamentos/04`](../01-fundamentos/04-recursion-y-backtracking.md).
- **Parseo de formatos, streaming de JSON y XML** → bloque [`07`](../07-formatos-de-datos/), que usa
  lo de aquí y no lo repite.
- **HTTP, TLS, versiones del protocolo y todo lo que viaja por el cable** →
  [`repaso-apis-y-protocolos-entrevistas`](../../04-apis-protocolos/).
- **Durabilidad distribuida, replicación, registro de escritura anticipada y el teorema CAP** → son de
  arquitectura: [`repaso-arquitectura-entrevistas`](../../../arquitectura/01-bases/). Aquí solo
  llega hasta `fsync`.
- **Reactivo, `WebFlux` y la configuración de pools en un framework** → fuera del alcance del corpus.
- **El código en los cinco lenguajes** → bloque opcional
  [`09-implementaciones`](../09-implementaciones/), capítulo `05`.

---

## Las versiones y el banco de pruebas

Todo lo que este bloque publica como medida se ejecutó de verdad, con:

```text
Java    Zulu 17.0.16 y 21.0.12 (sdkman)
Python  3.13.4
Node    24.21.0
Go      1.27.1
```

El banco de pruebas de los servidores es el mismo para todos: un servidor TCP que simula 100 ms de
trabajo por petición y un generador de carga con `asyncio` que abre N conexiones simultáneas. Las
medidas de memoria son `maximum resident set size` y el conteo de hilos es `ps -M` sobre el proceso
servidor durante la carga. El detalle está en
[`09-implementaciones/05`](../09-implementaciones/05-lab-io-bloqueante-y-no-bloqueante.md).
