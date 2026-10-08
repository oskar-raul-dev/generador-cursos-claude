# 09 — Implementaciones (opcional)

> **Este bloque está fuera del hilo principal y no hace falta para aprobar una entrevista.** La
> teoría vive en los bloques [`01`](../01-fundamentos/) a [`08`](../08-entrada-salida-y-recursos/); esto es para
> quien quiera ver el código, compararlo entre lenguajes y teclearlo.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md) §7.4

---

## Qué es esto, y qué no

```text
El hilo principal (01–08)  → qué elegir, cuánto cuesta y cómo decirlo en voz alta.
Este bloque (09)           → cómo se escribe, en cinco lenguajes, y qué cambia entre ellos.
```

**Reglas propias de este bloque**, distintas a las del resto del corpus:

- **Las soluciones van inline**, debajo de cada enunciado. No hay `🧠 Preguntas` ni solucionario,
  porque esto se hace con el editor abierto y no de memoria.
- **El código se ejecutó antes de publicarse.** Las salidas que aparecen en los documentos son las
  reales, no las esperadas.
- **Java implementa a pie; Python muestra lo prehecho.** Es el reparto declarado en la guía §5.1
  llevado al extremo: el mismo problema resuelto dos veces, construyendo e importando, con la cuenta
  de líneas y de bugs al lado.
- **Ningún documento del hilo principal depende de este bloque.** Lo enlazan como "si quieres verlo
  implementado", nunca como "el resto está en".

---

## Versiones ejecutadas

| Lenguaje | Versión usada | ¿Se ejecutó? |
|---|---|---|
| **Java** | Zulu **21.0.12** y **17.0.15** (sdkman) | ✅ compilado y ejecutado **en las dos** |
| **Python** | 3.13 | ✅ ejecutado |
| **JavaScript** | Node 24.21 | ✅ ejecutado |
| **TypeScript** | 5.x vía `npx`, sobre Node 24.21 | ✅ **type-checkeado** con `tsc --noEmit --strict` |
| **Go** | 1.27 | ✅ compilado y ejecutado |

**Sobre las dos versiones de Java.** El hilo principal enlaza siempre la API de Java 21, que es la
versión de referencia del corpus. Todo el código de este bloque se compiló y ejecutó **con 17.0.15 y
con 21.0.12**, y produce una salida **idéntica** en ambas: no usa nada posterior a 17 —`record`,
`var`, interfaces funcionales, `Map.of` y las colecciones son de 16 o antes—, así que sirve tanto si
tu proyecto está en 17 como si ya migró.

**La única excepción declarada es la sección de Visitor** de
[`02` §8](02-lab-patrones-en-cinco-lenguajes.md#8--visitor-el-patrón-que-java-21-elimina), que **sí**
usa características de 21: `sealed` y pattern matching en `switch`. Está ejecutada con 21.0.12, y en
17 falla a propósito con `patterns in switch statements are a preview feature` — el mensaje real está
en el documento, porque es la mejor demostración de que la característica es de 21 y no antes.

**Sobre TypeScript: ejecutar no es comprobar.** Node 24 **ejecuta** `.ts` de forma nativa por *type
stripping*, pero **no comprueba los tipos**: un archivo con un error evidente corre y sale con
`exit=0`. Como la aportación de TypeScript en este corpus es exactamente la verificación en
compilación, ejecutarlo sin `tsc` no demostraría nada.

Por eso los fragmentos de TypeScript del corpus se comprueban con el compilador, sin instalar nada:

```bash
npx -y -p typescript tsc --noEmit --strict archivo.ts
```

⚠️ El `-p` no es opcional: el paquete se llama `typescript` pero su binario es `tsc`. Sin él, `npx`
falla con *"could not determine executable to run"*.

**Y se comprueban las dos direcciones**, que es lo que hace útil la verificación: que el fragmento
correcto compile (`exit=0`) **y que el que el documento declara imposible falle de verdad**
(`exit=1`, con el mensaje del compilador copiado literal). Los cuatro fragmentos verificados así son
el `Record` sobre unión de literales de [`02` §2](02-lab-patrones-en-cinco-lenguajes.md#2--strategy),
el centinela `never` de [`02` §8](02-lab-patrones-en-cinco-lenguajes.md#8--visitor-el-patrón-que-java-21-elimina),
el `readonly T[]` de [`01-fundamentos/07`](../01-fundamentos/07-respuestas.md) y los tipos de
plantilla literal de [`02-texto/05`](../02-texto/05-respuestas.md).

**Sobre TypeScript.** No hay compilador en el entorno donde se escribió esto, y por tanto sus
fragmentos **no están verificados por ejecución**. Es coherente con su papel en el corpus: TypeScript
solo aparece cuando el sistema de tipos cambia la respuesta —exhaustividad con tipos unión, campos
obligatorios, `readonly`—, y eso se comprueba leyendo, no corriendo. Donde no aporta, se dice "igual
que JavaScript" en vez de rellenar.

---

## Los tres documentos

| # | Documento | Qué contiene |
|---|---|---|
| `01` | [Estructuras: a pie contra prehechas](01-estructuras-a-pie-vs-prehechas.md) | Heap, Union-Find y trie en los cinco lenguajes, con la cuenta de líneas y los tres bugs frecuentes |
| `02` | [Lab: los patrones en cinco lenguajes](02-lab-patrones-en-cinco-lenguajes.md) | Nueve patrones GoF escritos en los cinco, y la tabla de cuáles sobreviven al cambio de lenguaje |
| `03` | [Ejercicios comparativos](03-ejercicios-comparativos.md) | Seis ejercicios con solución inline: tres adaptados de los bancos existentes y tres nuevos |
| `04` | [Lab: formatos en cinco lenguajes](04-lab-formatos-en-cinco-lenguajes.md) | JSON, XML, YAML y CSV con la biblioteca de cada lenguaje, y ocho ejercicios con solución inline |
| `05` | [Lab: IO bloqueante y no bloqueante](05-lab-io-bloqueante-y-no-bloqueante.md) | Siete servidores medidos, el banco de pruebas reproducible y ocho ejercicios con solución inline |

**Por dónde empezar.** Si vas a teclear en una entrevista, `01`. Si vienes de los bancos de patrones
del repositorio, `02`. Si quieres practicar con problemas cerrados, `03`.

---

## De dónde sale el material de `02` y `03`

Este bloque **no duplica** la teoría de patrones del repositorio, la aplica:

- La teoría de los patrones GoF está en
  [`repaso-arquitectura-entrevistas/01-bases/04`](../../../arquitectura/01-bases/01-bases/04-patrones-gof.md)
  —qué resuelve cada uno, dónde está en Spring, cuáles ya no se usan— y en
  [`preguntas-entrevista/01`](../../../../preguntas-entrevista/01-poo-solid-patrones.md), que es el banco
  de cien preguntas de POO, SOLID y patrones.
- Tres de los seis ejercicios de `03` están adaptados de esos dos documentos: el `switch` de doce
  casos, las notificaciones multicanal y el código que depende de la fecha.
- Los otros tres son nuevos y **cruzan aquellos patrones con el temario algorítmico de este
  corpus**: el comparador que incumple su contrato, el top-K de un flujo y la caché LRU.

---

## Qué NO está aquí

- **La teoría de cada estructura y algoritmo** → los bloques [`01`](../01-fundamentos/) a
  [`05`](../05-dp-y-tecnicas/). Aquí se enlaza, no se repite.
- **Las preguntas de entrevista y sus respuestas en tres capas** → los solucionarios de cada bloque.
  Este bloque no tiene preguntas.
- **Una batería completa de ejercicios de código** → para eso están *Cracking the Coding Interview*,
  *Elements of Programming Interviews* y las listas por patrón de NeetCode, citadas en
  [`05-dp-y-tecnicas/03`](../05-dp-y-tecnicas/03-protocolo-de-pizarra.md).
- **Proyectos ejecutables, tests ni build.** Los fragmentos son mínimos y autocontenidos a propósito:
  este repositorio no tiene código, y la guía de estilo lo declara.
