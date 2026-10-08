# 🌐 Apéndice a09 — Browsers legacy: Cypress, Selenium y Puppeteer

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra el bucle de:** [F00](00-problema-y-contrato.md) §9 · [F01](01-decisiones-debian-zonas-node.md) §5 (Zona C) · [F11](11-validar-tu-proyecto.md) §4 (nivel 3)
> **Requisitos:** haber hecho [F09](09-montar-tu-proyecto.md) y F11. Esto es una capacidad adicional, no el camino mínimo
> **Qué encontrarás:** las tres estrategias para ejecutar pruebas de navegador desde el toolchain, qué dependencias gráficas hacen falta y por qué, y por qué ARM64 complica esto mucho más que todo lo demás

Las pruebas de navegador son la **Zona C** de [F01](01-decisiones-debian-zonas-node.md): aparecen solo si tu proyecto las necesita, y
viven fuera del toolchain. Este apéndice existe porque [F00](00-problema-y-contrato.md) promete cubrirlas y porque, cuando
hacen falta, son la parte más frágil de un proyecto legacy.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Meto el navegador en mi imagen o no?" | [§1](#1-️-la-decisión-de-arquitectura) |
| "Mis tests de Karma usan PhantomJS" | [§1.1](#11-el-que-ya-no-está-phantomjs) |
| "¿Qué librerías necesita un Chromium headless?" | [§2](#2--las-dependencias-gráficas-y-por-qué) |
| "Uso Cypress" | [§3](#3--cypress-dos-estrategias) |
| "Uso Selenium" | [§4](#4-️-selenium-contenedor-aparte) |
| "Uso Puppeteer" | [§5](#5--puppeteer-y-el-chromium-que-se-descarga-solo) |
| "Estoy en un Mac ARM y nada funciona" | [§6](#6--arm64-donde-esto-se-pone-serio) |
| "Me falla y no sé por dónde empezar" | [§7](#7--diagnóstico) |

---

## 1. 🏗️ La decisión de arquitectura

Hay dos formas de darle un navegador a tus tests, y la elección importa más de lo que parece.

```mermaid
flowchart TD
    subgraph OA["OPCIÓN A — todo en una imagen"]
        A["legacy-node-toolchain<br/>+ Node + tests<br/>+ Chromium<br/>+ 25 librerías gráficas"]
    end
    subgraph OB["OPCIÓN B — contenedor aparte"]
        B1["legacy-node-toolchain<br/>tests"] -- "WebDriver / CDP" --> B2["selenium/standalone-*<br/>o browserless/chrome"]
    end
```

**La opción A** es más simple de arrancar y engorda la imagen entre 300 y 500 MB con librerías
que el 90% de tus proyectos no usa. Además te ata a una versión de navegador dentro del
toolchain, que era justo lo que [F01](01-decisiones-debian-zonas-node.md) quería evitar con las CLIs.

**La opción B** mantiene el toolchain limpio, deja el navegador en una imagen que otro mantiene,
y permite cambiar de versión sin reconstruir nada tuyo. A cambio necesitas dos contenedores y
una red entre ellos.

> 🧭 **La recomendación del curso es la B**, y es la que fija [F01](01-decisiones-debian-zonas-node.md) al poner la Zona C en su propio
> contenedor. La excepción es Cypress, que por diseño quiere el navegador en su mismo proceso —
> §3.

Y para el escenario multi-contenedor, este es el caso donde Compose por fin gana su sitio: es
exactamente el ejemplo que usa **[a10](a10-docker-compose.md)**, después de que ya entiendas `docker run`.

### 1.1 El que ya no está: PhantomJS

Si tu proyecto es de 2018 y sus tests corren con Karma, hay una probabilidad alta de que el
navegador que espera no sea Chromium sino **PhantomJS**. Conviene decir pronto qué pasa con él:
**está archivado desde 2018** y no vuelve. Su mantenedor lo dejó de forma explícita cuando
Chrome publicó su modo headless, que hacía lo mismo y mejor.

Para este laboratorio el problema no es filosófico sino binario, y es un **caso D** de
[F14](14-abi-libc-y-prebuilds.md) §4.4 de manual: `phantomjs-prebuilt` no compila nada — su script de instalación
**descarga un ejecutable ya hecho** desde un servidor externo. Ese ejecutable es x86-64 contra
glibc, no existe para ARM64, y la infraestructura que lo sirve lleva años sin nadie detrás. Los
tres riesgos de [F14](14-abi-libc-y-prebuilds.md) §7.1 en el mismo paquete.

La salida es la que tomó el ecosistema entero y cabe en unas líneas de configuración: el
Chromium de APT —el de §2, con sus librerías— más `karma-chrome-launcher` apuntando a
`CHROME_BIN`.

```javascript
// karma.conf.js — antes
browsers: ['PhantomJS'],

// karma.conf.js — después
browsers: ['ChromeHeadlessNoSandbox'],
customLaunchers: {
  ChromeHeadlessNoSandbox: {
    base: 'ChromeHeadless',
    flags: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage'],
  },
},
```

Las banderas no son adorno y cada una tiene su motivo en este curso: `--no-sandbox` porque el
contenedor no trae los permisos que el sandbox de Chrome necesita, y `--disable-dev-shm-usage`
por el `/dev/shm` de 64 MB que explica §4. `--disable-gpu` es inofensivo y ahorra ruido en los
logs.

> ⚠️ **Una advertencia de alcance, porque esto no es un cambio cosmético.** Cambiar de navegador
> **cambia los resultados**. Un test que pasaba en PhantomJS puede fallar en Chromium headless
> por diferencias reales de motor: PhantomJS iba con un WebKit de 2016 y le faltaban APIs que tu
> código quizá esté cubriendo con un polyfill. Si algo se rompe justo después de la migración,
> ese es el primer sospechoso — y no es una regresión de tu código, es que el navegador dejó de
> mentirte.

---

## 2. 📚 Las dependencias gráficas, y por qué

Un Chromium "headless" sigue siendo Chromium: enlaza contra las librerías del sistema gráfico
aunque no vaya a pintar nada en pantalla. Si faltan, el error es siempre el mismo tipo:

```text
error while loading shared libraries: libnss3.so: cannot open shared object file
```

Las familias que hacen falta, agrupadas por qué resuelven:

| Familia | Paquetes Debian 10 | Para qué |
|---|---|---|
| **NSS** | `libnss3`, `libnspr4` | criptografía y certificados |
| **X11** | `libx11-xcb1`, `libxcomposite1`, `libxdamage1`, `libxfixes3`, `libxrandr2`, `libxss1` | el servidor gráfico, aunque sea headless |
| **GTK y ATK** | `libgtk-3-0`, `libatk1.0-0`, `libatk-bridge2.0-0` | widgets y accesibilidad |
| **Render** | `libcairo2`, `libpango-1.0-0`, `libgbm1`, `libdrm2` | composición y renderizado |
| **Sistema** | `libcups2`, `libdbus-1-3`, `libasound2` | impresión, bus de sesión, audio |
| **Fuentes** | `fonts-liberation`, `xdg-utils` | sin fuentes, las capturas salen con cajas |

> 🩺 **El diagnóstico que resuelve esto en un comando.** No adivines qué falta: pregúntaselo al
> propio binario.
>
> ```bash
> ldd /ruta/al/chrome | grep 'not found'
> ```
>
> Cada línea es una librería que falta. Después, `apt-file search` o una búsqueda en
> `packages.debian.org/buster` te dice qué paquete la trae. Es el mismo método que **[F14](14-abi-libc-y-prebuilds.md)** usa
> para cualquier dependencia nativa, y funciona igual aquí.

Y el añadido que casi todo el mundo olvida: **sin `fonts-liberation` el navegador arranca**,
pero tus capturas de pantalla y tus comparaciones visuales salen con rectángulos en lugar de
texto. Es un fallo que no rompe nada y estropea todo.

---

## 3. 🌲 Cypress: dos estrategias

Cypress es la excepción a la recomendación de §1, porque su arquitectura asume que el navegador
está disponible localmente.

### 3.1 Cypress con su Electron incluido

Cypress trae un Electron propio, y **es la primera opción para proyectos realmente antiguos**:
no dependes de que exista una versión de Chrome compatible con tu Cypress, que en 2018 era una
combinación delicada.

```bash
npx cypress run          # usa Electron por defecto
```

Necesita las librerías de §2 igualmente, porque Electron es Chromium por dentro.

**El precio:** Electron no es Chrome. Si tu suite depende de comportamientos específicos de un
navegador concreto, los resultados pueden diferir.

### 3.2 Cypress con un Chromium fijado

La segunda estrategia es instalar Chromium en la imagen y decirle a Cypress que lo use:

```bash
npx cypress run --browser chromium
```

**Fija la versión.** Un `chromium` de APT en Debian 10 es el de la época, que es probablemente lo
que quieres — pero decláralo, porque un Cypress de 2018 con un Chrome de 2026 es una combinación
que nadie probó nunca.

> ⚠️ **La descarga del binario de Cypress es un punto de fallo clásico.** Cypress descarga su
> Electron en un caché durante `npm install`, desde una URL que tiene que seguir viva. Si tu
> instalación falla ahí, la variable `CYPRESS_INSTALL_BINARY` y un caché precargado son la
> salida — y es exactamente el tipo de dependencia externa que **[F28](28-publicar-la-imagen.md)** te enseña a no tener.

---

## 4. 🕸️ Selenium: contenedor aparte

Para Selenium la estrategia preferida es la opción B, sin discusión: las imágenes oficiales de
`selenium/standalone-*` traen el navegador, el driver y el servidor ya resueltos, incluidas las
veinticinco librerías de §2.

```mermaid
flowchart TD
    A["legacy-node-toolchain<br/>tus tests"] -- "WebDriver, puerto 4444" --> B["selenium/standalone-chrome<br/>navegador + driver"]
```

Los dos contenedores necesitan verse, y para eso hace falta una red — que es de **[F18](18-networking-de-contenedores.md)**:

```bash
docker network create legacy-e2e

docker run -d --name selenium --network legacy-e2e \
  --shm-size=2g \
  selenium/standalone-chrome:<version-fijada>

docker run --rm --network legacy-e2e \
  -e SELENIUM_REMOTE_URL=http://selenium:4444/wd/hub \
  --mount type=bind,src="$PWD",dst=/workspace \
  legacy-node-toolchain:phase09 \
  npm run test:e2e
```

**Dos detalles con intención:**

- **`--shm-size=2g`.** Chrome usa memoria compartida intensivamente y el 1 GB por defecto de
  `/dev/shm` se le queda corto. El síntoma es un navegador que se cierra solo a mitad de la
  suite con un error genérico. Es el problema más común de Selenium en contenedores.
- **El nombre `selenium` como host.** Dentro de la red, los contenedores se resuelven por nombre
  gracias al DNS interno de Docker. No hace falta publicar el puerto 4444 al host si solo lo
  usa el otro contenedor.

**Fija la versión de la imagen de Selenium.** `selenium/standalone-chrome:latest` trae un Chrome
actual, y tu suite de 2018 puede no entenderse con él. Elige una etiqueta de la época y déjala
escrita.

---

## 5. 🎭 Puppeteer y el Chromium que se descarga solo

Puppeteer tiene un comportamiento propio que conviene conocer antes de que te sorprenda:

```mermaid
flowchart TD
    A["npm install puppeteer"] --> B["install.js"]
    B --> C["descarga un Chromium concreto,<br/>de una URL concreta"] --> D["lo guarda en un caché local"]
```

Cada versión de Puppeteer está atada a una **revisión exacta** de Chromium. Por ejemplo,
`puppeteer@5.5.0` —publicada en 2020, y que declara necesitar Node ≥ 10.18.1, así que nuestro
baseline le vale— descarga la revisión `r818858`.

**Los tres modos de fallo, en orden de frecuencia:**

**La descarga falla o la URL ya no responde.** Es el riesgo de cualquier artefacto histórico
alojado fuera de npm. La salida es saltarse la descarga y aportar tú el navegador:

```bash
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true npm ci
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium npm run test:e2e
```

**El Chromium se descargó pero no arranca.** Faltan las librerías de §2. `ldd` sobre el binario
del caché te lo dice en una línea.

**El Chromium descargado es para otra arquitectura.** §6.

> 🧭 **La estrategia recomendada para legacy** es precisamente saltarse la descarga y usar el
> `chromium` de Debian 10, fijado por APT. Cambias una dependencia de red imprevisible por una
> del archivo histórico, que es la misma apuesta que ya hiciste en [F01](01-decisiones-debian-zonas-node.md) y que sabes que
> funciona.

---

## 6. 🍎 ARM64: donde esto se pone serio

Todo lo anterior asume `linux/amd64`. En un Mac con Apple Silicon, las pruebas de navegador son
**la parte del laboratorio que peor lleva la arquitectura**, y conviene saberlo antes de
invertir una tarde.

**Puppeteer, en sus versiones de la época, no publicó Chromium para ARM64.** Su `install.js`
descarga el binario x64 o directamente falla. El error habla de una descarga o de un ejecutable
que no existe, y no menciona la arquitectura en ningún momento.

**Las imágenes de Selenium tienen soporte ARM64 desigual** según la versión: las etiquetas de la
época son mayoritariamente amd64.

**Cypress publicó soporte ARM64 tarde**, muy posterior a las versiones que usan los proyectos de
2018.

**Las tres salidas, con su precio:**

| Estrategia | Coste | Cuándo |
|---|---|---|
| Ejecutar todo bajo emulación amd64 | lento, y los navegadores emulados son especialmente lentos | la opción por defecto, y funciona |
| Usar el `chromium` ARM64 de Debian 10 y apuntar la herramienta a él | tienes que fijar la versión y aceptar que no es el navegador que el proyecto probó | Puppeteer con `PUPPETEER_EXECUTABLE_PATH` |
| Ejecutar los E2E en CI amd64 y no en local | pierdes el ciclo rápido | equipos con CI, y es lo que muchos acaban haciendo |

> 🧭 **Y una recomendación honesta:** si estás desenterrando un proyecto de 2018 en un Mac ARM,
> haz los E2E lo último. Los niveles 2 a 5 de [F11](11-validar-tu-proyecto.md) —instalar, testear, construir, ejecutar— son
> los que deciden si el proyecto es mantenible. El nivel de E2E es valioso y es el que más caro
> sale por unidad de información.

---

## 7. 🧯 Diagnóstico

El orden que ahorra tiempo, de la comprobación más barata a la más cara:

```mermaid
flowchart TD
    Q1{"1 · ¿existe el ejecutable del navegador?<br/>which chromium · ls del caché de Puppeteer o Cypress"}
    Q1 -- "no" --> R1["problema de descarga o de instalación"]
    Q1 -- "sí" --> Q2{"2 · ¿es de la arquitectura correcta?<br/>file /ruta/al/binario"}
    Q2 -- "no" --> R2["§6"]
    Q2 -- "sí" --> Q3{"3 · ¿le faltan librerías?<br/>ldd /ruta/al/binario #124; grep 'not found'"}
    Q3 -- "sí" --> R3["§2, instala los paquetes que falten"]
    Q3 -- "no" --> Q4{"4 · ¿arranca a mano?<br/>/ruta/al/binario --headless --no-sandbox --dump-dom https://example.com"}
    Q4 -- "no" --> R4["lee su error: suele ser /dev/shm o el sandbox"]
    Q4 -- "sí" --> R5["5 · ahora sí, el problema está por encima:<br/>en Cypress, Selenium o tus tests"]
```

> 🧠 **El patrón a memorizar.** Los pasos 1 a 4 son del **navegador**; el 5 es de **tu suite**.
> Casi todo el mundo empieza depurando la suite, y casi siempre el problema estaba en el 1, el 2
> o el 3. Es el mismo método de reducción que **[F20](20-validacion-sistematica-y-evidencia.md)** formaliza.

**Dos errores con nombre propio:**

`Running as root without --no-sandbox is not supported`. El sandbox de Chrome no funciona como
root, y nuestro laboratorio corre como root ([a05](a05-non-root-a-fondo.md)). En un contenedor aislado y local,
`--no-sandbox` es aceptable — pero es una renuncia real, no un truco, y no debe viajar a nada
expuesto.

Un navegador que se cierra a mitad de la suite sin error claro: `/dev/shm`. `--shm-size=2g`.

Y uno que ni siquiera llega al paso 1 porque falla antes, durante el `npm ci`:
`PhantomJS not found on PATH` o un `Download failed` de `phantomjs-prebuilt`. Ahí no hay nada
que diagnosticar en el navegador — el binario no se descargó y probablemente ya no se descargue
nunca. Es §1.1.

---

## 🧭 Guía rápida: cuándo usar qué

| Tu situación | Elige |
|---|---|
| Solo necesitas los niveles 2–5 de [F11](11-validar-tu-proyecto.md) | **No hagas nada de esto.** Los E2E son opcionales |
| Selenium, cualquier caso | **Contenedor aparte**, §4, con `--shm-size` y versión fijada |
| Cypress con proyecto muy antiguo | **Electron incluido**, §3.1 |
| Cypress y necesitas un navegador concreto | **Chromium de APT fijado**, §3.2 |
| Puppeteer | **Salta la descarga** y apunta al `chromium` de Debian, §5 |
| Karma con Chrome headless | Chromium de APT más `CHROME_BIN`, y `--no-sandbox` |
| Karma con PhantomJS | **Migra a `ChromeHeadless`**, §1.1 — el binario ya no existe para ti |
| Mac con Apple Silicon | **Deja los E2E para el final**, y considera hacerlos solo en CI |
| Ya tienes dos contenedores hablando | Es el momento de **[a10](a10-docker-compose.md)**: Compose gana aquí su sitio |

---

## 🧪 Ejercicios (7)

### 🟢 Ejercicio 1 — Qué le falta a un Chromium

Instala `chromium` en una imagen derivada del toolchain **sin** las librerías de §2 y ejecuta
`ldd $(which chromium) | grep 'not found'`.

**Objetivo:** obtener la lista real de lo que falta en tu caso, en lugar de copiar la tabla.

### 🟢 Ejercicio 2 — El navegador a mano

Con las librerías instaladas, ejecuta
`chromium --headless --no-sandbox --dump-dom https://example.com`.

**Objetivo:** confirmar el paso 4 del diagnóstico antes de que ninguna suite esté de por medio.

### 🟡 Ejercicio 3 — Selenium en dos contenedores

Monta el escenario de §4 y ejecuta una prueba mínima que abra una página y lea su título.

**Pregunta:** ¿por qué el contenedor de tests puede resolver el nombre `selenium`? ¿Qué pasa si
quitas `--network`?

### 🟡 Ejercicio 4 — `/dev/shm`

Ejecuta la misma suite con y sin `--shm-size=2g`, con un test que abra varias páginas.

**Objetivo:** provocar el cierre inexplicable y comprobar que la bandera lo arregla.

### 🟡 Ejercicio 5 — Puppeteer sin descargar Chromium

Instala `puppeteer@5.5.0` con `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true` y apúntalo al `chromium`
de Debian.

**Pregunta:** ¿funciona? ¿Qué versión de navegador estás usando realmente, y en qué se diferencia
de la que el proyecto probó en 2020?

### 🟠 Ejercicio 6 — Sin fuentes

Ejecuta una captura de pantalla en una imagen sin `fonts-liberation` y mira el resultado.

**Objetivo:** ver los rectángulos, y entender por qué un paquete que "no rompe nada" está en la
lista.

### 🔴 Ejercicio 7 — Decide para tu proyecto

Toma tu proyecto legacy real y decide la estrategia completa: qué herramienta, qué opción de
arquitectura, qué versión de navegador, y si lo ejecutas en local o solo en CI.

**Objetivo:** justificar cada decisión con la guía rápida, y añadir el nivel de E2E a tu
`VALIDATION-REPORT.md` de [F11](11-validar-tu-proyecto.md) — aunque el veredicto sea "fuera de alcance, por estas razones".
Un "no lo hicimos y este es el porqué" documentado vale más que un silencio.

---

## 📚 Referencias

- Cypress — navegadores: https://docs.cypress.io/app/references/launching-browsers
- Cypress — variables de entorno de instalación: https://docs.cypress.io/app/references/advanced-installation
- Selenium en Docker: https://github.com/SeleniumHQ/docker-selenium
- Puppeteer — solución de problemas: https://pptr.dev/troubleshooting
- Puppeteer v5.5.0, la versión contemporánea de nuestro baseline: https://github.com/puppeteer/puppeteer/releases/tag/v5.5.0
- Paquetes de Debian 10: https://packages.debian.org/buster/

> ⚠️ **La documentación de Cypress y Puppeteer describe sus versiones actuales**, que en ambos
> casos están a varias generaciones de las que usan los proyectos de 2018. Para esas, la fuente
> buena es el `README` del tag correspondiente en GitHub. La lista de librerías de §2 sí es
> estable, porque depende de Chromium y no de la herramienta que lo lance.

**Vuelve a:** [F00 §9](00-problema-y-contrato.md) · [F11](11-validar-tu-proyecto.md) · sigue en [F15](15-laboratorios-dependencias-nativas.md) y [a10](a10-docker-compose.md)
