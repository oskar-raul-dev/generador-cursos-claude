# 🧰 Parte I — Taller: un contenedor para tu proyecto legacy

> **Curso:** Docker Legacy Node
> **Fases:** [F00](00-problema-y-contrato.md) a [F11](11-validar-tu-proyecto.md) · ~51.500 palabras · 255 ejercicios · ~31 horas estimadas
> **Requisitos previos:** ninguno más allá de saber usar una terminal
> **Al terminar:** tu proyecto legacy real instala, compila, testea, corre y se depura
> dentro de un contenedor, con el código viviendo en tu máquina
> **Índice general:** [`0-programa-del-curso.md`](0-programa-del-curso.md)

---

## 🎯 Qué promete esta parte

Una cosa concreta y verificable: **que un proyecto que hoy no compila en tu máquina,
compile.** No "que entiendas Docker". No "que domines los contenedores". Que el
repositorio de 2018 que te pasaron arranque, pase sus tests y te deje poner un breakpoint.

Todo lo demás de esta parte existe para sostener esa promesa.

Si al terminar [F11](11-validar-tu-proyecto.md) tu proyecto corre y no sabes explicar qué es un PID namespace, la
Parte I hizo su trabajo. Esa explicación está en la Parte II y puede esperar a que tengas
la reunión resuelta.

---

## 🧠 La idea que ordena las once fases

> **El contenedor contiene el toolchain, no el proyecto.**

Tu código no se copia dentro de la imagen. Se queda en tu disco, con tu editor, tu Git y
tus ramas, y entra al contenedor por un *bind mount*. Lo que sí vive dentro de la imagen
es la maquinaria: Node en cuatro versiones, el compilador de C, Python 2 y 3, las
librerías del sistema, las utilidades.

De esa separación salen casi todas las decisiones que vas a ver, y conviene tenerla clara
desde el principio porque explica cosas que si no parecen arbitrarias:

```mermaid
flowchart LR
    subgraph H["TU MÁQUINA (el host)"]
        SRC["código fuente"]
        ED["editor, Git, ramas"]
    end
    subgraph C["EL CONTENEDOR"]
        WS["/workspace"]
        TC["Node 10 / 12 / 14 / 16<br/>GCC, make, pkg-config<br/>Python 2.7 y 3.7<br/>utilidades Linux"]
    end
    NM[("node_modules")]
    SRC -- "bind mount" --> WS
    NM -- "named volume" --> WS
```

`node_modules` es el caso interesante: **no vive en ninguno de los dos lados por
casualidad**, sino en un *named volume*, porque contiene binarios compilados para la
arquitectura del contenedor y mezclarlos con los de tu host es una de las formas más
rápidas de perder una tarde. [F01](01-decisiones-debian-zonas-node.md) lo explica y [F09](09-montar-tu-proyecto.md) lo monta.

---

## 🗺️ El recorrido

Las doce fases construyen una sola imagen, capa a capa. Cada una declara en su encabezado
el estado en que la deja, y ese estado encadena con el de la siguiente.

**[F00](00-problema-y-contrato.md) y [F01](01-decisiones-debian-zonas-node.md) son de decisión.** No ejecutas nada: entiendes el terreno, por qué Debian 10
y no otra, por qué esas cuatro versiones de Node, dónde vive cada cosa. Son las dos fases
más cortas y las que más te ahorran después.

**[F02](02-dockerfile-esencial.md) a [F06](06-instalacion-node.md) construyen la imagen.** Dockerfile, APT y las utilidades, el toolchain de
compilación, Python y `node-gyp`, y las cuatro generaciones de Node. Al terminar F06
tienes una imagen capaz de compilar casi cualquier cosa de la época.

**[F07](07-build-de-la-imagen.md), [F08](08-run-el-contenedor-como-proceso.md) y [F09](09-montar-tu-proyecto.md) la ponen a funcionar.** Construirla de verdad y entender el build
context; después ejecutar —`ENTRYPOINT`, `CMD`, foreground contra detached, `docker
exec`— y por último meter tu código dentro con bind mounts y volúmenes, hasta el
laboratorio end-to-end.

**[F10](10-vscode-y-debugging.md) y [F11](11-validar-tu-proyecto.md) cierran el taller.** El debugger conectado desde VS Code, y el protocolo de
validación que produce el veredicto de si tu proyecto es compatible y con qué evidencia.

---

## 🚧 Qué NO vas a encontrar aquí

Y no por omisión: está escrito, con detalle, en la Parte II.

| Lo que te vas a preguntar | Dónde se responde |
|---|---|
| ¿Cómo se montan las capas juntas en runtime? | **[F13](13-overlayfs-y-copy-on-write.md)** — OverlayFS y copy-on-write |
| ¿Por qué mi app ignora `Ctrl+C`? | **[F16](16-pid1-senales-y-ciclo-de-vida.md)** — PID 1 y señales |
| ¿Por qué este archivo salió del contenedor con dueño equivocado? | **[F17](17-usuarios-permisos-y-volumenes.md)** — usuarios y permisos |
| ¿Por qué `localhost` no funciona? | **[F18](18-networking-de-contenedores.md)** — networking |
| ¿Qué es exactamente `NODE_MODULE_VERSION`? | **[F14](14-abi-libc-y-prebuilds.md)** — ABI, libc y prebuilds |
| ¿Cómo corre un binario x86 en mi Mac ARM? | **[F21](21-arquitecturas-y-emulacion.md)** — arquitecturas y emulación |
| ¿Docker o Podman? | **[F24](24-docker-y-podman-arquitectura.md)** — dos arquitecturas comparadas |

El curso avisa cada vez que roza uno de estos temas, y siempre con la fase exacta. Si
lees una promesa de estas y no se cumple más adelante, es un bug del curso.

---

## 🧪 Cómo trabajar esta parte

**Con tu proyecto real al lado.** Los ejemplos usan fixtures que existen de verdad en
`src/11-validar-tu-proyecto/` —Vue 2, Angular 8, React 16, Svelte 3 y uno de control sin
framework, todos con su lockfile congelado—, pero el curso está escrito para que apliques
cada paso a lo tuyo en paralelo.

**Ejecutando, no leyendo.** Cada fase trae su *Prueba de fuego*: una verificación
concreta incrustada en el flujo, no al final. Si la saltas, la fase siguiente asume algo
que no comprobaste.

**Sin saltarte los errores.** Varias fases te piden **romper algo a propósito** antes de
arreglarlo. No es relleno: reproducir el fallo es la mitad del diagnóstico, y es la
habilidad que la Parte II asume que ya tienes.

---

## 🏁 La señal de que quedó bien

> "Borro la imagen, la reconstruyo mañana en otra máquina y obtengo exactamente el mismo
> entorno. Mi proyecto instala, compila, pasa sus tests y puedo poner un breakpoint —
> y sé decir qué pieza hace cada cosa."

Cuando puedas decir eso, la Parte I terminó. La Parte II te espera con la pregunta
siguiente: **¿y por qué funciona?**
