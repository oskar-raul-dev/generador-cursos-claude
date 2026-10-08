# 🧭 C# para desarrolladores Java senior

Un curso práctico para escribir C# como se escribe de verdad, mientras decides —con números
delante— qué parte de un sistema heredado que factura todos los días se migra, cuál se envuelve y
cuál se deja quieto. No enseña a programar: enseña a cruzar de ecosistema sin traer el acento y a
defender la decisión en una junta.

> 🧭 **La pregunta que ordena las veinticinco fases: ¿esto se migra, se envuelve o se deja
> quieto?** Las tres respuestas son legítimas, las tres tienen un costo que se puede calcular, y
> el curso existe para que sepas cuál estás eligiendo.

---

## 👤 Para quién es, y para quién no

**Es para ti si** llevas ocho años o más escribiendo Java, dominas orientación a objetos,
concurrencia, SQL, HTTP, pruebas, build y despliegue, y resuelves un problema leyendo
documentación y un ejemplo. Nada aquí te explica qué es una interfaz, una transacción o un
contenedor.

**No es para ti si** buscas una introducción a la programación, un tutorial de sintaxis, un curso
de certificación en Azure o teoría de aprendizaje automático. Tampoco si esperas que alguien te
convenza de abandonar la JVM: el curso mide, y en varias columnas el resultado va a ser empate.

Dos cosas que conviene saber antes de empezar, porque no se negocian: **la dificultad no se baja**
—si un miniproyecto se puede terminar copiando el código de la fase, está mal diseñado y se
reescribe— y **ninguna afirmación comparativa entra sin su número**.

---

## 🪟 Requisito: Windows 11

**El curso es de Windows, exclusivamente.** No hay variantes por plataforma, ni notas al pie para
Linux o macOS, y no es comodidad del autor: **el sistema heredado que vas a migrar son formularios
WinForms sobre .NET Framework**, y ninguna de esas dos cosas existe fuera de Windows. Un curso que
evitara el escritorio para ser multiplataforma dejaría fuera la mitad del problema.

Que .NET 10 corra en Linux y en contenedor sigue siendo cierto, y es uno de los argumentos que el
curso usa para desarmar el *"esto hay que reescribirlo en otra cosa"*. Pero el curso **se toma en
Windows**, con WSL 2 para los contenedores.

---

## 🧰 El stack, fijado

Las versiones están cerradas y verificadas contra las notas oficiales el **12 de septiembre de
2026**. Ninguna fase usa una dependencia que no esté aquí.

| Pieza | Versión |
|---|---|
| .NET SDK | **10.0.401** (canal LTS 10.0; runtime 10.0.12) |
| Lenguaje | **C# 14** |
| El runtime heredado que vas a migrar | **.NET Framework 4.8**, escrito como C# de 2017 |
| IDE principal | **Visual Studio Community 2026, 18.10.0** |
| Base de datos | **SQL Server 2025** en contenedor |
| Datos | **EF Core 10.0.12** y **Dapper 2.1.66** |
| Pruebas | **xUnit v3 4.0.0**, **Testcontainers 4.15.0**, **NSubstitute 6.2.0** |
| Sistema operativo | **Windows 11** con WSL 2 |

Como IDE alternativo, **VS Code + C# Dev Kit** o **Rider**, los dos con su mapa de equivalencias
para quien viene de IntelliJ. La nube es Azure, emulada en local donde se puede y **medida con
precios publicados donde no**: el curso se completa entero sin una suscripción de pago y sin que
ningún miniproyecto te pida una tarjeta de crédito.

---

## 🗺️ El mapa: siete bloques, veinticinco fases

El índice detallado —con el reflejo que ataca cada fase y el proyecto que avanza— está en
[`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md). Esto es el mapa:

- **Bloque 0 · el ambiente** (fase 00). SDK, Visual Studio, la CLI, NuGet y WSL 2. No es un setup:
  es la primera lección de criterio, y de ella nace el arnés con el que se mide todo el resto.
- **Bloque A · el lenguaje y el runtime** (01-06). Tipos por valor, nullable, LINQ y evaluación
  diferida, delegados y recursos, `async` de punta a punta, memoria y flujo. Es donde se te quita
  el acento.
- **Bloque B ⭐ · el sistema heredado y la frontera** (07-11). El curso **escribe** el trozo de
  sistema de 1997 que después va a cortar, lo caracteriza con pruebas antes de entenderlo, y
  ejecuta un *strangler fig* con vuelta atrás demostrada. Es el corazón.
- **Bloque C · el escritorio** (12-14). Qué pasa con los 340 formularios: WinForms sobre .NET 10,
  WPF con MVVM, un prototipo en WinUI 3, y el veredicto medido — incluida la opción de no tocarlos.
- **Bloque D · servicios, datos y nube** (15-20). Minimal APIs y contrato, identidad y secretos,
  trabajo de fondo reanudable, los tres modelos de render de Blazor, observabilidad, y **la
  factura**: qué cuesta cada destino de cómputo al volumen real.
- **Bloque E · datos e IA aplicada** (21-22). Separar sell-in de sell-out y de devolución, servir
  un modelo con ONNX, y recuperación documental con cita obligatoria.
- **Cierre** (23-24). El mismo servicio implementado en ASP.NET Core y en Spring Boot, y el
  veredicto honesto de qué no debió migrarse.

---

## 🏔️ La empresa

Todo se construye para **Cordillera Media**, un grupo editorial bogotano de 1979 con 340
empleados, cuatro sellos, tres almacenes en tres países y 18.000 títulos en catálogo. Su sistema
—**SIGE**, que todo el mundo llama *"el sistema"*— viene de dBase III Plus en 1988, pasó por
Visual FoxPro hasta que Microsoft mató el producto, lo migraron tres pasantes en once meses entre
2016 y 2017, y en 2020 se fue a Azure en un *lift and shift* que quedó un 30% por encima del
centro de datos que reemplazó. Nadie se atreve a decirlo en junta.

Hoy son 340 formularios, cerca de 700 procedimientos almacenados donde vive la lógica de negocio
de verdad, un esquema congelado en 1997 —campos de diez caracteres, fechas en `char(8)`, borrado
por bandera, una tabla de ventas por año— y noventa equipos conectándose directo a la base con la
misma cadena de conexión. Y una restricción que la puso la presidenta, que es abogada: **nada de
lo que construyas puede apagar el sistema.** La editorial factura todos los días mientras tú
migras.

Aquí nadie es el villano. Wilson no es desarrollador y nunca dijo que lo fuera; Duván sostiene
solo, desde hace nueve años, algo que no diseñó; y los tres pasantes hicieron en once meses lo
que nadie más quiso hacer.

La historia completa —la genealogía del sistema de 1988 a 2026, quién es quién, las cifras del
negocio y la fecha de cada decisión incómoda— está en
[`00-historia-de-cordillera.md`](00-historia-de-cordillera.md), y conviene leerla **antes de la
fase 00**: las veinticinco fases la dan por sabida.

---

## 🛠️ Cómo se trabaja

Cada fase termina con **un miniproyecto obligatorio** —de dos a cinco horas, con datos sucios de
verdad, una trampa declarada sin resolver y criterios de aceptación que se comprueban
ejecutando algo—, **una medición** con su hipótesis, sus condiciones, su competidor defendible y
su veredicto con umbral, y **el avance de al menos uno de los seis proyectos** que atraviesan el
curso.

El código vive en `src/`, con dos soluciones que conviven: la heredada sobre .NET Framework 4.8 y
la nueva sobre .NET 10. El curso te entrega el punto de partida: el arnés de medición
`Cordillera.Bench` con sus pruebas, y el sistema heredado SIGE —esquema, procedimientos almacenados,
eventos extendidos, acceso a datos y formularios—. El resto de los proyectos lo construyes tú, fase
a fase, con los nombres que fija cada una, y cada miniproyecto 🧱 va en su `src/fases/NN-nombre/mini/`. Y la fase 23 te hace armar un tercer directorio,
`src/duelo/`, que no es parte del sistema: ahí viven las dos implementaciones del mismo endpoint
—ASP.NET Core y Spring Boot— que esa fase mide y que no entran en producción. Cada fase cerrada lleva su tag anotado, cada miniproyecto el suyo con el
número de su medición en el mensaje, y las deudas técnicas 💸 que el curso deja a propósito se
cobran con un `git diff` entre dos tags. La convención completa está en
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md); los números, en
[`BENCHMARKS.md`](BENCHMARKS.md); los reflejos, en [`INSTINTOS.md`](INSTINTOS.md).

---

## ⚖️ El veredicto que el curso se debe a sí mismo

La última fase revisa todas las decisiones con los datos en la mano y está obligada a admitir
cuatro cosas: que el *lift and shift* de 2020 fue un error, que **parte del sistema no debió
migrarse** —el módulo de inventario funciona y "el Fox" de Lima lleva veintinueve años
funcionando—, que la migración de los pasantes fue, en el balance, correcta, y **dos decisiones
del propio curso que debieron ser otras** — el sistema heredado debió llegar antes del bloque del
lenguaje, y el veredicto del escritorio debió ir después de la web. Las dos están sostenidas con una
medición o un mecanismo del propio material, y **no se corrigieron**: quedan escritas como errores
documentados.

Y las veinticuatro mediciones se publican **con sus tablas completas y sus celdas vacías**: hipótesis,
condiciones, competidores y el comando exacto, con ⏳ donde va cada número. Los números los pones tú.
Ninguna cifra de este curso es inventada porque ninguna cifra de este curso existe todavía.

> ⚖️ **Si al final resultara que .NET moderno ganó todo, el curso estaría mal escrito.**
