# 05 — El árbol de directorios

> El recorrido que parece un ejercicio de primer año y es un recorrido de grafo con ciclos, permisos
> que fallan a mitad y un coste por entrada que casi nadie mide. Qué hace cada lenguaje ante un
> enlace simbólico que apunta hacia arriba —y son tres cosas distintas—, y por qué preguntar el
> tamaño de cada archivo multiplica por cinco el tiempo del recorrido.
>
> **Asume leído:** [`04/03` — Grafos: representación y recorridos](../04-arboles-grafos/03-grafos-representacion-y-recorridos.md),
> de donde viene la detección de ciclos.
>
> **Vigencia:** 2026-09-18. Todas las salidas de este capítulo están **ejecutadas**.

---

## 1. 🎯 El problema

Un árbol de tres niveles con un archivo, y un enlace simbólico que apunta a su propio ancestro:

```bash
mkdir -p arbol/a/b/c && echo hola > arbol/a/b/c/f.txt
ln -s ../../.. arbol/a/b/c/bucle     # el enlace apunta tres niveles hacia arriba
```

- `ln -s` crea un enlace **simbólico**: una entrada de directorio cuyo contenido es una ruta, no
  datos. El sistema la resuelve al abrirla.
- `../../..` desde `arbol/a/b/c` es `arbol`. El enlace apunta a su propio ancestro: **eso ya no es un
  árbol, es un grafo con ciclo**.

Y ahora, el mismo recorrido en tres lenguajes:

```text
Python  os.walk(followlinks=True)  -> no termina: ciclo por enlace simbólico
Go      filepath.WalkDir           -> 2 entradas (no sigue enlaces)
Java    Files.walk(FOLLOW_LINKS)   -> FileSystemLoopException: arbol/a/b/c/bucle
```

**Tres comportamientos distintos para la misma estructura:** uno se cuelga, uno lo evita por defecto y
uno lo detecta y avisa. Ninguno está mal; hay que saber cuál tienes delante.

---

## 2. 🧱 Un directorio es un grafo, no un árbol

**Qué es.** El sistema de archivos parece un árbol —hay una raíz, cada directorio cuelga de otro— y
dos mecanismos lo convierten en grafo:

```text
ENLACE SIMBÓLICO (symlink)   una entrada que contiene una RUTA. Puede apuntar a cualquier sitio,
                             incluso a un ancestro, incluso a algo que no existe.
ENLACE DURO (hard link)      dos entradas que apuntan al MISMO inodo. El archivo tiene dos nombres
                             y ninguno es "el original".
```

**Cómo va.** Las consecuencias para el recorrido:

- **Con enlaces simbólicos hay ciclos**, y por tanto hace falta **detección de ciclos**: exactamente
  lo del bloque `04`, con el conjunto de visitados. La diferencia es qué se guarda en ese conjunto:
  no la ruta —dos rutas distintas pueden llevar al mismo sitio— sino la **identidad real del
  directorio**, que es el par dispositivo más inodo.
- **Con enlaces duros hay repetición sin ciclo**: el mismo contenido aparece dos veces con nombres
  distintos. Un `du` ingenuo cuenta su tamaño dos veces; `du` de verdad recuerda los inodos ya vistos.
- **El mismo archivo puede tener infinitas rutas** a través de enlaces, así que "la ruta de un
  archivo" no es un identificador. El identificador es el inodo.

**Cuánto cuesta.** El recorrido en sí es `O(entradas)`, lineal. Lo que se paga aparte es lo de la
sección 4: cada dato adicional sobre cada entrada es otra llamada al sistema.

**Cuándo sí** seguir los enlaces: cuando el usuario los puso a propósito para componer un árbol —un
directorio de configuración que apunta a otro sitio— y espera que se recorran.

**Cuándo no:** en cualquier recorrido sobre datos que no controlas. Un enlace simbólico en un archivo
subido por un usuario es un vector de ataque: apunta a `/etc` y tu copia de seguridad se lleva lo que
no debe.

> **Veredicto:** trata el recorrido de directorios como lo que es —un recorrido de grafo— y decide
> explícitamente si sigues enlaces. El valor por defecto de tu lenguaje es **no seguirlos**, y casi
> siempre es el correcto.

---

## 3. 🧱 Qué hace cada lenguaje

| Lenguaje | API | ¿Sigue enlaces por defecto? | ¿Detecta ciclos? |
|---|---|---|---|
| **Java** | `Files.walk` | No | **Sí, con `FOLLOW_LINKS`**: `FileSystemLoopException` |
| **Python** | `os.walk` | No | **No.** Con `followlinks=True` se cuelga |
| **Go** | `filepath.WalkDir` | No | No sigue, así que no hace falta |
| **Node** | `fs.readdir` recursivo | No | No, y hay que implementarlo |
| **TypeScript** | El de Node | No | Lo mismo, con tipos |

Lo que hay que saber decir:

- **Java es el único que trae la detección puesta**, y la documentación lo dice: al seguir enlaces
  lleva registro de los directorios visitados y lanza `FileSystemLoopException` al detectar el bucle.
  Es la implementación más completa de los cinco.
- **Python avisa en la documentación y no hace nada más**: `followlinks=True` trae una advertencia
  explícita de que puede producir recursión infinita. Verificado: se cuelga.
- **Go elige no seguir y punto.** Es coherente con su filosofía: menos funcionalidad, ningún
  comportamiento sorprendente. Si quieres seguir enlaces, lo implementas tú **y la detección también**.
- **`WalkDir` de Go es la versión moderna de `Walk`**, y la diferencia importa por lo de la sección
  siguiente: `WalkDir` entrega una `DirEntry` con la información que ya venía en la lectura del
  directorio, y `Walk` hacía un `stat` por entrada.

**Si tienes que implementar la detección**, el esquema es el del bloque `04` con un detalle:

```text
visitados ← conjunto de (dispositivo, inodo)    ← NO de rutas
recorrer(d):
    id ← identidad_real(d)
    si id ∈ visitados: volver          ← aquí se corta el ciclo
    visitados ← visitados ∪ {id}
    para cada entrada e de d:
        si e es directorio: recorrer(e)
```

- **La clave es el conjunto de identidades, no de rutas.** Con rutas, `a/b/c/bucle/a/b/c/bucle` son
  rutas distintas y el bucle no se detecta nunca.
- **Y la recursión tiene su propio límite**: un árbol profundo agota la pila. Con datos de terceros,
  conviene un recorrido iterativo con pila explícita y un tope de profundidad — que es exactamente la
  conversión de `01-fundamentos/04`.

---

## 4. 🧱 El coste de preguntar

**El problema.** Listar un directorio devuelve nombres. Todo lo demás —tamaño, fechas, permisos, si
es directorio— es **otra llamada al sistema por entrada**.

Medido sobre 10 000 archivos en 50 directorios:

```text
os.walk, solo nombres               6.8 ms
os.walk + os.stat por archivo      31.9 ms     ← casi 5×
os.scandir (stat cacheado)         26.9 ms
```

- **Pedir el tamaño de cada archivo multiplica por cinco el recorrido.** No porque `stat` sea caro en
  absoluto, sino porque son diez mil llamadas más.
- **`scandir` existe precisamente por esto**: la lectura del directorio ya devuelve parte de la
  información, y `scandir` la conserva en lugar de tirarla y volver a pedirla. Su equivalente es
  `DirEntry` en Go y `withFileTypes: true` en Node.
- La ganancia depende del sistema de archivos: si la entrada de directorio ya trae el tipo, es
  gratis; si no, se acaba haciendo el `stat` igual. Por eso aquí la mejora es del 16 % y en otros
  sistemas es mayor.

**La regla que sale de esto:** no preguntes lo que no vas a usar. Un recorrido que solo necesita
nombres no debe llamar a `stat`, y uno que necesita el tipo debe usar la API que lo trae ya.

> **Veredicto:** el recorrido es lineal en entradas; el coste real lo decide **cuántas llamadas al
> sistema haces por entrada**. Es el mismo principio del capítulo `04` —el peaje es por cruce, no por
> byte— aplicado a metadatos en vez de a datos.

---

## 5. ⚠️ Lo que falla a mitad del recorrido

Un recorrido sobre un árbol real falla, y hay que decidir qué hacer:

| Qué pasa | Por qué | Qué se hace |
|---|---|---|
| **Permiso denegado** en un subdirectorio | No eres su dueño | Registrar y seguir, casi siempre |
| **El archivo desaparece** entre el listado y el `stat` | Otro proceso lo borró | Ignorar esa entrada: es normal |
| **Enlace roto** | Apunta a algo que ya no existe | `stat` falla; `lstat` funciona |
| **Ciclo por enlace** | La sección 1 | Detectar por inodo, o no seguir |
| **Ruta demasiado larga** | Límite del sistema | Error; conviene acotar la profundidad |

- **La condición de carrera entre listar y consultar es inevitable**: el sistema de archivos cambia
  mientras lo recorres, y no hay forma de tomar una foto consistente. Todo código de recorrido tiene
  que tolerar que una entrada listada ya no exista.
- **`stat` sigue el enlace y `lstat` no.** Para saber si algo *es* un enlace hay que usar `lstat`; si
  usas `stat` sobre un enlace roto, falla y parece que el archivo no existe.
- **La decisión de diseño que hay que declarar**: ¿un error en una rama aborta el recorrido o se
  registra y se continúa? Para una copia de seguridad, continuar y reportar. Para una verificación de
  integridad, abortar. **No hay respuesta universal, y por eso hay que escribirla.**

---

## 6. 🔭 Dónde aparece de verdad

En la copia de seguridad que tarda el triple de lo previsto porque hace `stat` de todo; en el proceso
de limpieza que se cuelga y nadie sabe por qué, hasta que aparece un enlace simbólico que alguien
creó hace dos años; en el escáner de seguridad que sigue un enlace hacia `/etc` de un directorio
subido por usuarios; en el `du` casero que cuenta dos veces los archivos con enlace duro; y en la
entrevista, donde "recorre un directorio y suma los tamaños" parece un calentamiento y es una
pregunta con cuatro trampas.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El sistema de archivos es un árbol" | Con enlaces simbólicos es un grafo, y puede tener ciclos |
| "Guardo las rutas visitadas para evitar ciclos" | Hay que guardar (dispositivo, inodo): dos rutas pueden ser el mismo sitio |
| "`os.walk` con `followlinks` es más completo" | Y se cuelga con un enlace a un ancestro. Verificado |
| "La ruta identifica al archivo" | Con enlaces duros, un archivo tiene varios nombres |
| "Listar y consultar tamaños cuesta lo mismo" | Casi cinco veces más: una llamada extra por entrada |
| "Si `stat` falla, el archivo no existe" | Puede ser un enlace roto: ahí hay que usar `lstat` |
| "El recorrido es reproducible" | El árbol cambia mientras lo recorres; hay que tolerarlo |
| "La recursión vale para cualquier árbol" | Un árbol profundo agota la pila: pila explícita y tope |

---

## 📚 Para profundizar

- **Libro** — Stevens y Rago, *Advanced Programming in the UNIX Environment*, capítulo 4. Ahí están
  los inodos, los dos tipos de enlace y la diferencia entre `stat` y `lstat`, con el recorrido
  recursivo escrito a mano.
- **Manual** — [`man 2 stat`](https://man7.org/linux/man-pages/man2/stat.2.html) y
  [`man 7 symlink`](https://man7.org/linux/man-pages/man7/symlink.7.html): qué resuelve cada llamada
  y las reglas de resolución de enlaces.
- **Java** — [`Files.walk`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html)
  y [`FileVisitor`](https://docs.oracle.com/javase/tutorial/essential/io/walk.html): la documentación
  dice explícitamente cómo detecta los ciclos.
- **Python** — [`os.walk`](https://docs.python.org/3/library/os.html#os.walk) y
  [`os.scandir`](https://docs.python.org/3/library/os.html#os.scandir): la advertencia sobre
  `followlinks` y el porqué de `scandir` están en la propia documentación.
- **Go** — [`filepath.WalkDir`](https://pkg.go.dev/path/filepath#WalkDir): explica por qué sustituyó
  a `Walk` y qué ahorra.
- **Node** — [`fs.readdir` con `withFileTypes`](https://nodejs.org/api/fs.html#fspromisesreaddirpath-options):
  el equivalente de `scandir`.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`07` — Respuestas](07-respuestas.md).

1. ¿Qué es un enlace simbólico? 🟢
2. ¿Qué es un enlace duro? 🟢
3. ¿Sigue `os.walk` los enlaces por defecto? 🟢
4. ¿Qué es un inodo? 🟢
5. ¿Qué diferencia hay entre `stat` y `lstat`? 🟢
6. ¿Qué hace `Files.walk` de Java ante un ciclo de enlaces? 🟢
7. ¿Para qué sirve `scandir`? 🟢
8. ¿Cuánto cuesta un recorrido de directorios en notación asintótica? 🟢
9. ¿Por qué un sistema de archivos no es un árbol? 🟡
10. ¿Por qué guardar rutas visitadas no detecta ciclos? 🟡
11. ¿Qué se guarda entonces en el conjunto de visitados? 🟡
12. ¿Qué hace Python con `followlinks=True` y un enlace a un ancestro? 🟡
13. ¿Por qué `WalkDir` sustituyó a `Walk` en Go? 🟡
14. ¿Por qué un `du` ingenuo cuenta de más con enlaces duros? 🟡
15. ¿Qué pasa si un archivo desaparece entre el listado y el `stat`? 🟡
16. ¿Por qué `stat` falla sobre un enlace roto? 🟡
17. ¿Por qué pedir el tamaño multiplica por cinco el recorrido? 🟠
18. ¿Cuánto gana `scandir` y por qué depende del sistema de archivos? 🟠
19. ¿Cuándo seguirías enlaces simbólicos y cuándo no? 🟠
20. ¿Qué riesgo de seguridad tiene seguir enlaces en datos de terceros? 🟠
21. ¿Cuándo conviertes el recorrido recursivo en iterativo? 🟠
22. ¿Aborta o continúa tu recorrido ante un permiso denegado? Justifica las dos posturas. 🟠
23. ¿Por qué el recorrido de un árbol real no es reproducible? 🟠
24. Los tres lenguajes hacen cosas distintas ante el mismo ciclo. ¿Cuál prefieres como valor por
    defecto y por qué? 🟠
25. ¿Por qué el conjunto de visitados de un recorrido de archivos se parece al del bloque `04` y
    en qué se diferencia? 🟠
26. Escribe el recorrido con detección de ciclos, tope de profundidad y tolerancia a errores. Di
    qué decisiones tomaste y por qué. 🔴
27. Un proceso de limpieza nocturno se colgó una vez en dos años. Diagnostica y escribe la
    corrección y la prevención. 🔴
28. Diseña un `du` correcto: qué cuenta, qué no cuenta dos veces, qué hace con los enlaces y
    cuál es su coste. 🔴
29. Diseña un sincronizador de carpetas: qué compara, qué recorre, cómo detecta cambios y cuál
    es su coste. 🔴
30. Un escáner de seguridad recorre directorios subidos por usuarios. Escribe los controles que
    impondrías y qué ataque previene cada uno. 🔴
31. Escribe el informe de por qué una copia de seguridad pasó de dos horas a seis sin que
    crecieran los datos. 🔴

---

**Anterior:** [`04` — Búferes y el coste de la frontera](04-buferes-y-el-coste-de-la-frontera.md) ·
**Siguiente:** [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) ·
**Bloque:** [README](README.md)
