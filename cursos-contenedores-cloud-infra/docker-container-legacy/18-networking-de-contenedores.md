# 🌐 Parte II · Fase 18 — Networking: por qué tu `localhost` no es su `localhost`

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** **[F09](09-montar-tu-proyecto.md)** (ejecutar el proyecto) y **[F16](16-pid1-senales-y-ciclo-de-vida.md)** (namespaces)
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — modelo de red de Docker 29.6.2
> **Estado de la imagen al terminar:** sin cambios
> **Objetivo:** entender el network namespace, qué hace realmente `-p`, por qué `EXPOSE` no expone nada, y cómo se hablan dos contenedores entre sí

---

## 1. 🧭 Dónde estamos

Es el tercer namespace del curso, después del PID ([F16](16-pid1-senales-y-ciclo-de-vida.md)) y el de usuario ([F17](17-usuarios-permisos-y-volumenes.md)), y el que más
preguntas genera — porque su síntoma es siempre el mismo y siempre desconcierta:

> *"El servidor dice que arrancó, pero mi navegador dice que no hay nada."*

[F10](10-vscode-y-debugging.md) te hizo publicar el puerto 9229 del debugger y te dijo que `--inspect` tenía que escuchar
en `0.0.0.0`, prometiendo la explicación para esta fase. Aquí está, con el mecanismo completo.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar qué es un **network namespace** y por qué el contenedor tiene su propio `localhost`.
- Saber por qué escuchar en `127.0.0.1` dentro del contenedor lo hace **inalcanzable**.
- Entender qué hace `-p` exactamente, y por qué `EXPOSE` **no** publica nada.
- Conectar dos contenedores por nombre usando una red de usuario.
- Llegar desde el contenedor a un servicio de tu host.
- Leer logs sabiendo de dónde salen, y distinguir `docker logs` de `docker attach`.

---

## 3. 🚧 Qué NO entra todavía

- **Docker Compose**, que es la forma cómoda de montar varios contenedores → **[a10](a10-docker-compose.md)**, después
  de que entiendas lo de aquí.
- **Selenium en su propio contenedor**, el caso multi-contenedor real → **[a09](a09-browsers-legacy.md)**.
- **Las diferencias de red entre Docker y Podman**, que son más de las que parece → **[F24](24-docker-y-podman-arquitectura.md)**.
- El **catálogo de fallos** de red, DNS, TLS y proxies → **[F31](31-catalogo-de-fallos-i.md)**.

---

## 4. 🧠 El error mental más frecuente

```text
❌ "el contenedor corre en mi máquina, así que su localhost y el mío son el mismo"
```

No lo son. Un contenedor tiene su **propio network namespace**: sus interfaces de red, su
tabla de rutas, sus puertos y su `localhost`.

```text
TU HOST                              EL CONTENEDOR
127.0.0.1  ← tu loopback             127.0.0.1  ← SU loopback
:3000 libre                          :3000 con tu app escuchando

              ✗ no se ven. Son dos pilas de red distintas
```

Es la misma idea de [F16](16-pid1-senales-y-ciclo-de-vida.md) aplicada a la red: **el namespace no crea nada, cambia lo que se ve**.
Compruébalo:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase09 \
  bash -c 'ip addr show | grep -E "^[0-9]+:|inet "'
```
```text
1: lo: <LOOPBACK,UP,LOWER_UP> ...
    inet 127.0.0.1/8 scope host lo
2: eth0@if42: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
```

Dos interfaces propias: un loopback que es **suyo** y una `eth0` con una IP de la red interna
de Docker. Ninguna de las dos es de tu máquina.

---

## 5. 🎯 `0.0.0.0` contra `127.0.0.1`, dentro del contenedor

Aquí está la causa número uno de "arrancó pero no responde".

Cuando un servidor "escucha", elige **en qué interfaz** hacerlo:

| Dirección | Qué significa | Alcanzable desde el host |
|---|---|---|
| `127.0.0.1` | solo el loopback **de este namespace** | ❌ **nunca** |
| `0.0.0.0` | **todas** las interfaces, incluida `eth0` | ✅ si publicas el puerto |

```javascript
server.listen(3000, '127.0.0.1');   // ❌ inalcanzable desde fuera del contenedor
server.listen(3000, '0.0.0.0');     // ✅ correcto en un contenedor
```

**Y por eso los fixtures del curso son como son.** Vuelve a mirarlos:

```json
"serve": "vue-cli-service serve --host 0.0.0.0 --port 8080"
"start": "ng serve --host 0.0.0.0 --port 4200 --disable-host-check"
"start": "HOST=0.0.0.0 PORT=3000 react-scripts start"
```

Los tres llevan `0.0.0.0` explícito, porque **muchas herramientas de desarrollo escuchan en
`127.0.0.1` por defecto** — que en tu máquina es lo correcto y seguro, y dentro de un
contenedor lo hace invisible.

> 🩺 **El diagnóstico de un comando.** Si el servidor arrancó y no responde:
>
> ```bash
> docker exec mi-contenedor ss -lntp    # o netstat -lntp
> ```
>
> Si la columna de dirección local dice `127.0.0.1:3000`, ahí acabó la investigación. Si dice
> `0.0.0.0:3000` o `*:3000`, el problema está en la publicación del puerto y no en la app.

> 📝 **Nota de época sobre `--disable-host-check`.** Angular CLI y Webpack Dev Server rechazan
> peticiones cuyo `Host` no reconocen, como protección contra rebinding de DNS. Desde fuera del
> contenedor el `Host` que llega no es el que esperan, así que la bandera hace falta. En un
> laboratorio local es aceptable; en algo expuesto, no.

---

## 6. 🚪 `-p`: qué hace realmente

Publicar un puerto le dice al motor que **reenvíe** conexiones desde una dirección del host
hacia un puerto del contenedor.

```bash
docker run -p 127.0.0.1:3000:3000 ...
             │         │    │
             │         │    └── puerto DENTRO del contenedor
             │         └─────── puerto EN el host
             └───────────────── interfaz del host donde escuchar
```

```text
tu navegador → 127.0.0.1:3000 (host) → [reenvío del motor] → 172.17.0.2:3000 (contenedor)
```

Las formas que verás, y lo que cambia entre ellas:

```bash
-p 3000:3000               # escucha en TODAS las interfaces del host ⚠️
-p 127.0.0.1:3000:3000     # solo en tu loopback  ✅ lo que usa este curso
-p 3001:3000               # puertos distintos: 3001 fuera, 3000 dentro
-p 3000                    # puerto aleatorio en el host → el de dentro
-P                         # publica todos los EXPOSE en puertos aleatorios
```

> 🚨 **Por qué el curso prefiere `127.0.0.1:`.** Sin esa parte, tu servidor de desarrollo queda
> accesible desde **cualquier máquina de tu red** — la wifi de la cafetería incluida. Para un
> proyecto legacy sin autenticación, sirviendo un dev server con recarga en caliente y quizá un
> inspector de Node en el 9229, eso es exponer bastante más de lo que crees. El prefijo lo
> limita a tu equipo.

**Los puertos del laboratorio**, que vas a repetir mucho:

```bash
docker run -d --name legacy-node-dev \
  -p 127.0.0.1:3000:3000 \    # React / Node
  -p 127.0.0.1:4200:4200 \    # Angular
  -p 127.0.0.1:8080:8080 \    # Vue
  -p 127.0.0.1:9229:9229 \    # Node Inspector (F10)
  ...
```

Y para ver qué está publicado de verdad:

```bash
docker port legacy-node-dev
```

### 6.1 `EXPOSE` no expone nada

```dockerfile
EXPOSE 3000
```

Esa instrucción **no publica el puerto**, no abre nada y no cambia el comportamiento de la red.
Es **documentación**: declara qué puertos usa la imagen, para que una persona lo lea y para que
`-P` sepa cuáles publicar.

> 🧭 **Por qué el toolchain no lleva `EXPOSE`.** Sería mentir: esta imagen no sirve un puerto
> concreto — sirve el que use el proyecto que le montes, que puede ser 3000, 4200, 8080 o lo
> que el `package.json` diga. Un `EXPOSE 3000 4200 8080 9229` daría la impresión de que la
> imagen tiene algo que ver con esos números, y no es así.

---

## 7. 🕸️ Que dos contenedores se hablen

La red por defecto —`bridge`— conecta los contenedores entre sí por IP, pero **no resuelve
nombres**. Para eso hace falta una red de usuario:

```bash
docker network create legacy-net

docker run -d --name api --network legacy-net legacy-node-toolchain:phase09 node api.js
docker run --rm --network legacy-net legacy-node-toolchain:phase09 \
  curl -s http://api:3000/health
```

**`api` funciona como nombre de host** porque Docker corre un DNS interno en las redes de
usuario, y resuelve los nombres de los contenedores conectados a ellas.

```mermaid
flowchart LR
    subgraph NET["red legacy-net"]
        WEB["web · 172.18.0.3"] -- "curl http://api<br/>el DNS de la red resuelve «api»" --> API["api · 172.18.0.2"]
    end
```

Dos detalles que ahorran tiempo:

- **Dentro de la red se usa el puerto del contenedor**, no el publicado. `api:3000` aunque
  hayas publicado el 3001 al host.
- **No hace falta publicar nada** si solo se hablan entre ellos. Publicar es para llegar desde
  **tu** máquina.

Este es el patrón que **[a09](a09-browsers-legacy.md)** usa para Selenium y el que **[a10](a10-docker-compose.md)** convierte en un
`docker-compose.yml` — después de que entiendas qué está pasando por debajo.

### 7.1 Del contenedor a un servicio de tu host

El caso inverso, y bastante común en legacy: tu proyecto necesita hablar con una base de datos,
un mock o un proxy que corre en **tu máquina**.

`localhost` desde dentro del contenedor no sirve, por §4. Docker ofrece un nombre especial:

```bash
docker run --rm legacy-node-toolchain:phase09 \
  curl -s http://host.docker.internal:5432
```

En Docker Desktop —macOS y Windows— funciona directamente. En **Linux nativo** hay que
declararlo:

```bash
docker run --add-host host.docker.internal=host-gateway ...
```

> ⚠️ **Es una de las diferencias de plataforma más molestas del curso**, porque produce un
> script que funciona en el Mac de un compañero y no en tu Linux. Si tu proyecto habla con algo
> del host, ponlo en el `run-dev.sh` con el `--add-host` siempre: en Docker Desktop no estorba.

---

## 8. 📜 Logs: de dónde salen

Los logs no aparecen por telepatía. `docker logs` muestra **lo que el proceso principal escribió
en `stdout` y `stderr`**, y nada más.

```bash
docker logs mi-contenedor           # todo
docker logs -f mi-contenedor        # y sigue mostrando lo nuevo
docker logs --tail 50 mi-contenedor
docker logs --since 10m mi-contenedor
docker logs -t mi-contenedor        # con marca de tiempo
```

De ahí salen tres consecuencias prácticas:

**Si tu aplicación escribe a un archivo, `docker logs` no muestra nada.** Es correcto y es la
causa del clásico "los logs están vacíos". La convención de contenedores es escribir a `stdout`
y dejar que el motor se encargue; si tu proyecto legacy escribe a `/var/log/app.log`, tendrás
que leerlo con `docker exec cat`.

**Solo el proceso principal cuenta.** Lo que imprima un `docker exec` va a **tu terminal**, no
al log del contenedor. Es la razón de que el entrypoint de [F08](08-run-el-contenedor-como-proceso.md) mande su aviso a `stderr` y no a
un archivo.

**El logging driver decide dónde acaban.** Por defecto es `json-file`, que los guarda en disco
y **crece sin límite** salvo que configures rotación. En un contenedor de desarrollo que lleva
semanas vivo, eso se nota.

```bash
docker inspect --format '{{.HostConfig.LogConfig.Type}}' mi-contenedor
```

---

## 9. 🔌 `attach` no es `exec`

Se confunden y hacen cosas distintas:

| | `docker exec` | `docker attach` |
|---|---|---|
| Qué hace | arranca un **proceso nuevo** | te conecta al **proceso principal** |
| Cuántos a la vez | los que quieras | uno, y compartís la sesión |
| Al salir | el contenedor sigue | ⚠️ `Ctrl+C` **mata el contenedor** |
| Para qué | inspeccionar, ejecutar comandos | ver e interactuar con el proceso 1 |

> ⚠️ **La trampa de `attach`.** Estás conectado al PID 1, así que un `Ctrl+C` le manda `SIGINT`
> **a tu aplicación** — y por [F16](16-pid1-senales-y-ciclo-de-vida.md) sabes cómo acaba eso. Para salir sin matar nada, la secuencia
> es **`Ctrl-p Ctrl-q`**.

**La regla del curso:** usa `exec` casi siempre. `attach` sirve para el caso concreto de
interactuar con un proceso principal que espera entrada — un REPL de Node, por ejemplo — y para
poco más.

---

## 10. ⚠️ Errores comunes y diagnóstico

**"El servidor arrancó y el navegador no responde."** Las tres causas, en orden de frecuencia:
escucha en `127.0.0.1` (§5), no publicaste el puerto (§6), o publicaste un puerto distinto al
que escucha. `docker exec ... ss -lntp` y `docker port` responden las tres.

**`port is already allocated`.** Otro proceso —o un contenedor anterior— tiene ese puerto del
host. `docker ps` y `lsof -i :3000` en el host.

**El puerto está publicado y la app no responde.** El servidor murió, o escucha en el loopback
interno. `docker logs` primero, `ss -lntp` después.

**Cambié `-p` y no hizo efecto.** Los puertos se fijan **al crear** el contenedor. Hay que
crear uno nuevo, como con `NODE_VERSION` en [F09](09-montar-tu-proyecto.md).

**`host.docker.internal` no resuelve.** Estás en Linux nativo sin `--add-host`. §7.1.

**Dos contenedores no se ven por nombre.** Están en la red `bridge` por defecto, que no tiene
DNS. Crea una red de usuario. §7.

**Los logs están vacíos.** La app escribe a un archivo, o estás mirando el contenedor
equivocado. §8.

**`Ctrl+C` mató mi contenedor.** Estabas en `attach`. §9.

---

## 11. 📋 Checklist de validación

```text
[ ] ip addr dentro del contenedor muestra lo y eth0 propias
[ ] Sabes por qué 127.0.0.1 dentro del contenedor es inalcanzable
[ ] ss -lntp te dice en qué interfaz escucha tu app
[ ] docker port muestra lo que publicaste
[ ] Tu proyecto responde desde el navegador del host
[ ] Sabes por qué el toolchain no lleva EXPOSE
[ ] Dos contenedores se resuelven por nombre en una red de usuario
[ ] Llegaste desde el contenedor a un servicio del host
[ ] docker logs muestra lo que escribió el proceso principal, y sabes por qué no lo del exec
[ ] Distingues attach de exec y sabes salir de attach sin matar nada
```

---

## 12. 🧪 Ejercicios de la Fase 18 (20)

## 🟢 Fácil — las dos pilas de red (1–7)

### 🟢 Ejercicio 1 — Dos pilas de red

Compara `ip addr` dentro del contenedor con el de tu host.

**Pregunta:** ¿cuántas interfaces tiene cada uno? ¿Alguna IP coincide?

### 🟢 Ejercicio 2 — El servidor invisible

Arranca el servidor de [F16](16-pid1-senales-y-ciclo-de-vida.md) con `HOST=127.0.0.1`, publica el puerto e intenta acceder desde el
host.

**Objetivo:** provocar el fallo número uno de esta fase a propósito.

### 🟢 Ejercicio 3 — `ss -lntp` lo delata

Sobre el ejercicio 2, ejecuta `docker exec mi-contenedor ss -lntp`.

**Objetivo:** ver `127.0.0.1:3000` en la salida y saber que ahí acabó el diagnóstico.

### 🟢 Ejercicio 4 — Arréglalo

Cambia a `HOST=0.0.0.0` y repite.

**Pregunta:** ¿qué muestra ahora `ss -lntp`? ¿Y el navegador?

### 🟢 Ejercicio 5 — Puertos distintos

Publica con `-p 127.0.0.1:3001:3000`.

**Pregunta:** ¿a qué puerto entras desde el navegador? ¿Y qué puerto usa la app dentro?

### 🟢 Ejercicio 6 — `EXPOSE` no hace nada

Construye una imagen con `EXPOSE 3000`, arráncala **sin** `-p` e intenta acceder.

**Objetivo:** comprobar que `EXPOSE` es documentación. Después prueba con `-P` y mira
`docker port`.

### 🟢 Ejercicio 7 — Lee los logs

Arranca el servidor, hazle tres peticiones y usa `docker logs`, `-f`, `--tail 2` y `-t`.

**Objetivo:** manejar las cuatro variantes con soltura.

## 🟡 Intermedio — publicar y conectar (8–13)

### 🟡 Ejercicio 8 — Dos contenedores por nombre

Monta el escenario de §7 con dos contenedores en una red de usuario.

**Objetivo:** que uno llegue al otro por nombre, sin publicar ningún puerto.

### 🟡 Ejercicio 9 — Sin red de usuario

Repite el ejercicio 8 en la red `bridge` por defecto.

**Pregunta:** ¿resuelve el nombre? ¿Funciona por IP? ¿Qué diferencia hay?

### 🟡 Ejercicio 10 — El puerto de dentro manda

Con los dos contenedores conectados, publica el de `api` en `-p 3001:3000` e intenta llegar
desde el otro contenedor a `api:3001` y a `api:3000`.

**Pregunta:** ¿cuál funciona y por qué?

### 🟡 Ejercicio 11 — Llega a tu host

Arranca un servidor simple en tu host y accede desde el contenedor con
`host.docker.internal`.

**Pregunta:** ¿funcionó directamente o necesitaste `--add-host`? Anota tu plataforma junto a la
respuesta.

### 🟡 Ejercicio 12 — `exec` no escribe en el log

Ejecuta `docker exec mi-contenedor echo hola` y después `docker logs`.

**Pregunta:** ¿aparece? Relaciónalo con por qué el entrypoint de [F08](08-run-el-contenedor-como-proceso.md) usa `stderr`.

### 🟡 Ejercicio 13 — El log que no aparece

Modifica el servidor para que escriba a un archivo en lugar de a `stdout` y ejecuta
`docker logs`.

**Objetivo:** ver el log vacío y entender por qué la convención de contenedores es escribir a
`stdout`.

## 🟠 Difícil — cuando el puerto no responde (14–17)

### 🟠 Ejercicio 14 — `attach` y la trampa

Conéctate con `attach` a un contenedor interactivo, sal con `Ctrl-p Ctrl-q`, vuelve a
conectarte y sal con `Ctrl+C`.

**Objetivo:** comprobar las dos salidas y qué le pasa al contenedor con cada una.

### 🟠 Ejercicio 15 — Cuatro fallos de red

Prepara cuatro escenarios rotos —escucha en loopback, puerto sin publicar, puerto equivocado, y
app muerta— y diagnostica cada uno.

**Objetivo:** un procedimiento que los distinga en dos comandos, y decir cuál es el primero que
ejecutas siempre.

### 🟠 Ejercicio 16 — El dev server que rechaza

Arranca el fixture Angular sin `--disable-host-check` y accede desde el navegador del host.

**Pregunta:** ¿qué responde? ¿Por qué esa protección existe, y por qué aquí estorba? Relaciónalo
con la 📝 de §5.

### 🟠 Ejercicio 17 — El puerto ocupado

Arranca dos contenedores publicando el mismo puerto del host.

**Objetivo:** leer el error, identificar al ocupante con `docker ps` o `lsof -i`, y resolverlo
sin matar lo que no toca.

## 🔴 Muy difícil — diseño y documentación (18–20)

### 🔴 Ejercicio 18 — Los logs que llenan el disco

Averigua dónde guarda tu motor los logs `json-file` y cuánto ocupan los de tu contenedor de
desarrollo.

**Pregunta:** ¿tienen rotación configurada? Si no, ¿cuánto tardarían en ser un problema? Propón
la configuración que lo evita.

### 🔴 Ejercicio 19 — Publica solo lo necesario

Revisa los puertos que publica tu toolbox de desarrollo y justifica cada uno: quién lo usa, en
qué interfaz está y qué pasaría si no lo publicaras.

**Objetivo:** quedarte con el conjunto mínimo, todos en `127.0.0.1`, y poder explicar por qué
publicar el inspector de Node en `0.0.0.0` sería una mala idea concreta —no una precaución
genérica—. Vuelve a [F10](10-vscode-y-debugging.md) §6.2 si dudas.

### 🔴 Ejercicio 20 — Documenta la red de tu proyecto

Escribe el diagrama y la tabla de puertos de tu proyecto legacy: qué escucha, en qué interfaz,
qué se publica, y a qué necesita llegar.

**Objetivo:** que alguien nuevo pueda arrancarlo sin preguntarte. Es material directo para el
`README-dev.md` del ejercicio 19 de [F10](10-vscode-y-debugging.md).

## 🔥 Opcionales

### 🔥 Ejercicio 21 — Mira el reenvío por dentro

En Linux nativo, con un puerto publicado, ejecuta `sudo iptables -t nat -L DOCKER -n`.

**Objetivo:** ver las reglas que el motor creó y entender que `-p` no es magia: son reglas de
NAT.

### 🔥 Ejercicio 22 — `--network host`

Arranca un contenedor con `--network host` en Linux y compara `ip addr` con el de tu máquina.

**Pregunta:** ¿qué namespace desapareció? ¿Sigue haciendo falta `-p`? ¿Y qué perdiste a cambio?
Ojo: en macOS y Windows se comporta distinto.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: funciona en su máquina

Un compañero con macOS tiene el proyecto funcionando. Tú, en Linux nativo, tienes tres
problemas a la vez: el dev server no responde en el navegador, la conexión a la base de datos
local falla, y los archivos del build salen con dueño equivocado.

**Objetivo:** los tres tienen causa distinta y **dos de ellos son diferencias de plataforma**,
uno de esta fase y otro de [F17](17-usuarios-permisos-y-volumenes.md). Diagnostícalos con evidencia, arréglalos, y después escribe la
parte más valiosa: **el `run-dev.sh` que funciona en las dos plataformas sin ramas
condicionales feas**, o justificando cada rama que necesites. Es el escenario real de un equipo
mixto.

---

## 13. 📚 Referencias

**Docker**
- Visión general de red: https://docs.docker.com/engine/network/
- Publicación de puertos: https://docs.docker.com/engine/network/#published-ports
- Redes bridge de usuario y DNS: https://docs.docker.com/engine/network/drivers/bridge/
- `docker logs`: https://docs.docker.com/reference/cli/docker-container-logs/
- Logging drivers y rotación: https://docs.docker.com/engine/logging/configure/
- `host.docker.internal`: https://docs.docker.com/desktop/features/networking/

**Linux**
- `network_namespaces(7)`: https://manpages.debian.org/buster/manpages/network_namespaces.7.en.html
- `ss(8)`: https://manpages.debian.org/buster/iproute2/ss.8.en.html

> ⚠️ **`host.docker.internal` es una función de Docker Desktop.** En Linux nativo funciona solo
> con `--add-host host.docker.internal=host-gateway`, y en Podman el nombre y el
> comportamiento difieren. **[F24](24-docker-y-podman-arquitectura.md)** compara los dos motores en red.

**Orden de lectura sugerido:** *Published ports* primero, que resuelve el 80% de las dudas; las
redes bridge cuando hagas el ejercicio 8.

---

## 14. 🏁 Resultado de la fase

```text
NETWORK NAMESPACE   el contenedor tiene su lo y su eth0
                    su 127.0.0.1 NO es el tuyo

ESCUCHAR            127.0.0.1 dentro → inalcanzable, siempre
                    0.0.0.0   dentro → alcanzable si publicas

PUBLICAR            -p 127.0.0.1:HOST:CONTENEDOR
                    EXPOSE no publica: es documentación
                    los puertos se fijan al CREAR el contenedor

CONECTAR            red de usuario → DNS por nombre de contenedor
                    dentro de la red se usa el puerto del contenedor
                    al host → host.docker.internal (+ --add-host en Linux)

LOGS                docker logs = stdout y stderr del PROCESO PRINCIPAL
                    lo del exec va a tu terminal, no al log
                    attach ≠ exec, y Ctrl+C en attach mata el contenedor
```

> **La señal de que quedó bien:** *"cuando algo no responde, mi primer comando es
> `ss -lntp` dentro del contenedor — porque distingue en un segundo un problema de la app de
> uno de publicación."*

En **[F19](19-dev-containers.md)** volvemos a la superficie: Dev Containers, la capa de comodidad que convierte el
contenedor en el ambiente completo de tu IDE — ahora que ya sabes qué esconde.
