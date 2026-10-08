# 🐍 Python para desarrolladores Java senior

Un curso práctico que te enseña a **elegir el registro correcto de Python** —script,
herramienta o aplicación— y a escribir cada uno como se escribe de verdad, midiendo lo que
ganas y lo que pierdes frente al stack que ya dominas.

> 🧭 **La pregunta que ordena todo: ¿esto es un script, una herramienta o una aplicación?**

No vienes a aprender a programar. Vienes a desaprender un reflejo. Un senior de Java construye
una aplicación para todo: le pides convertir cuatrocientos CSV y entrega un proyecto Maven con
interfaces, capas e inyección de dependencias. Python tiene tres registros de escritura reales
y distintos, y este perfil escribe siempre en el tercero — o, cuando por fin escribe un script
de verdad, no reconoce el momento en que ese script dejó de serlo y ya merece paquete, tipos,
pruebas y una forma de distribuirse.

Los dos errores son simétricos y los dos son caros. El curso los provoca a propósito y después
te los cobra con números.

---

## 👤 Para quién es

Para un desarrollador **Java senior**, con ocho o más años de oficio, que domina orientación a
objetos, concurrencia, SQL, HTTP, pruebas, build y despliegue, y que resuelve leyendo
documentación. Aquí nadie te va a explicar qué es una excepción, un mapa o una transacción.

**Para quién no es:** para alguien que está aprendiendo a programar, o que no viene de un
lenguaje con tipos y con build. No es un curso difícil por capricho, pero el piso está alto y
bajarlo lo arruinaría.

---

## 🏗️ Qué vas a construir

Software real para **Áurea**, una red odontológica colombiana de diez sedes —cuatro propias y
seis franquiciadas, 2.800 pacientes en ortodoncia, 3.900 citas al mes— donde eres el único
ingeniero. No hay arquitecto que apruebe tus diseños ni comité que apruebe al arquitecto, la
usuaria real es la administradora que lleva la operación en Excel, y hay una frontera legal
—la historia clínica es reservada, con auditoría de accesos obligatoria— que ningún diseño
puede cruzar. Cuatro proyectos, cada uno en un registro distinto:

- **La caja de herramientas de Patricia** — un CLI que consolida los archivos de las diez
  sedes, valida antes de generar y produce lo que el país exige. Nace como un archivo de
  cuarenta líneas y solo se vuelve paquete seis fases después, cuando ya no le cabe la ropa.
- **La agenda de la red** — una API de servicio con disponibilidad de diez sedes y reservas
  desde la web y el bot. Es la que se implementa dos veces al final.
- **El back-office** — un monolito con baterías: cuarenta pantallas, permisos por sede y
  auditoría de accesos.
- **El cierre nocturno** — un proceso por lotes reanudable, idempotente y auditable línea por
  línea, que importa el CLI como biblioteca.

---

## 🧱 Cómo está organizado

Tres bloques y dieciocho fases. El **Bloque A** es un archivo, biblioteca estándar pura y cero
dependencias, y está ahí para romper el reflejo de agregar una dependencia para parsear una
fecha. El **Bloque B** es la frontera —cuándo un script deja de ser un script— y es la pieza
central del curso. El **Bloque C** es donde Python compite de frente con lo que ya sabes hacer.

La tabla completa de las 18 fases, los cuatro proyectos y cómo se recorre están en
[`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md).

### Y después, dos tracks complementarios

Cuando el camino base termina, Áurea todavía tiene cuatro proyectos planteados y ninguno
construido. Los **complementos** los construyen, con la misma plantilla, la misma medición
obligatoria y el mismo miniproyecto que una fase:

- **Track `ia`** (`ia01`–`ia08`) — NormaRAG, que contesta qué cubre cada prepagada citando
  documento y cláusula o no contesta; y Recepción asistida, que atiende los novecientos mensajes
  diarios de WhatsApp y **escala ante cualquier síntoma**.
- **Track `ds`** (`ds01`–`ds09`) — Embudo, que mide cuánto cuesta de verdad un paciente
  adquirido; y Ausentismo, que predice el 19% de inasistencia y abre la discusión de qué se hace
  con esa predicción. Cierra con su propio ⚖️ veredicto: **los dos proyectos valían la pena y
  casi ninguna de las herramientas modernas que se les asocian era necesaria**, cada una con el
  umbral en el que esa respuesta cambia.

No son material a la carta: son la continuación del curso sobre el código que tú dejaste escrito.
Se toman después de la Fase 17 porque necesitan el CLI, la API y la base de datos funcionando.

### Y aparte, la carta

**176 secciones sueltas en 22 tracks**, para cuando necesitas una herramienta concreta y no un
curso: los portales sin API con Playwright, el correo que tiene que llegar, Airflow contra
Temporal, pruebas e2e, OpenTelemetry, criptografía aplicada, una docena de motores de datos desde
Python, JPype y GraalPy, optimización con OR-Tools, PostGIS, visión por computador… Cada una se lee
sin haber leído ninguna otra, trae un ejemplo completo que se corrió en contenedor con Python
3.14.7 —173 de las 176 enteras; las otras tres dicen qué quedó sin correr— y cierra con **cuándo no
usar** lo que enseñó. Su código está también en `src/`, un directorio por sección.

A diferencia del camino base, la carta cubre Linux y macOS, y algunas secciones necesitan Docker
para sus servicios o bajan un modelo la primera vez; cada una lo dice en su ejemplo. Sus archivos
empiezan por `op`; la lista de los 22 tracks y cómo se lee una sección están en
[`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md), en *La carta*.

---

## 🎯 Qué lo hace distinto

**No hay apéndices.** Todo lo que en otro curso sería material de consulta es aquí una fase o
una sección de una fase. El ambiente de trabajo, por ejemplo, es la Fase 00 entera.

**Cada fase cierra con un miniproyecto difícil**, anclado al dominio y calibrado para que no se
pueda resolver copiando el código de la fase. Entre dos y cinco horas cada uno, y son
dieciocho.

**Ninguna afirmación comparativa aparece sin su número.** Ni "más rápido", ni "más liviano", ni
"sale más barato". Cada fase produce una medición con el mismo arnés, y el competidor siempre
es una implementación que alguien defendería en una revisión de código.

---

## 🛠️ Qué necesitas

**Esta carpeta y un intérprete de Python.** Nada más, y es literal: el curso es autocontenido, no
depende de ningún archivo que esté fuera de aquí, no te manda a otro material y no te pide acceso a
ningún sistema que no tengas. Puedes copiar la carpeta a donde quieras y funciona entera. Los datos
con los que trabajas los generan scripts de `src/`, con semilla fija, y el dominio es ficticio y
completo.

Python 3.14, un editor y nada más **hasta la Fase 07**. Esa es la regla que sostiene el Bloque
A: hasta que el curso lo diga, no instalas nada. Las versiones exactas de todo lo que entra
después están fijadas, con su fecha de verificación, y el curso se puede tomar entero sin
acceso a nada que no sea este repositorio y un intérprete.

Windows 11, Linux amd64 y macOS Apple Silicon están cubiertos en el cuerpo del material, sin
notas al pie.

Empieza por [`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md), sigue con
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md) y con
[`00-historia-de-aurea.md`](00-historia-de-aurea.md) —la empresa para la que vas a construir
todo—, y después con la Fase 00.

Calcula entre **100 y 150 horas** para el camino base completo; el desglose por bloque, con su
derivación, está en el documento de estructura.

Y si quieres ver de qué se trata antes de empezar, dos atajos:
**[`BENCHMARKS.md`](BENCHMARKS.md)** tiene las mediciones del curso con sus veredictos —las
dieciocho del camino base, incluidos los cinco empates, más las de los complementos— y
**[`INSTINTOS.md`](INSTINTOS.md)** tiene los reflejos de Java que el material recalibra, con lo
que cuesta cada uno.

---

## ⚖️ Cómo termina

Con el veredicto: el mismo endpoint implementado dos veces, en FastAPI y en Spring Boot 3, con
el mismo arnés, y una sección honesta sobre dónde Python no era la respuesta. Eso no es humildad
de cierre, es el contenido — quien sale sabiendo elegir entre tres registros pero incapaz de
decir *"esto debió quedarse en Java"* no aprendió a decidir, aprendió a preferir.

> Si al final resultara que Python ganó todo, el curso estaría mal escrito.
