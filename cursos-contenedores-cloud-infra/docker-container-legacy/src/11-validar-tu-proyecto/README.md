# 🧪 Fixtures de validación de proyectos

Los cinco proyectos mínimos que usa la fase de validación. No son ejemplos
ilustrativos: **son ejecutables y están congelados**, y por eso cada uno trae su
`package-lock.json` versionado.

---

## Qué hay aquí

| Fixture | Stack | Qué demuestra |
|---|---|---|
| `00-node-smoke` | Node puro, cero dependencias | Que el bind mount, npm scripts, build, tests, puerto, HTTP y `SIGTERM` funcionan **antes** de culpar a un framework |
| `10-vue2-min` | Vue 2.6.12 + Vue CLI 3.12.1 | Webpack 4 detrás del CLI, unit tests con Jest, dev server con HMR |
| `20-angular8-min` | Angular 8.2.14 + CLI 8.3.29 + TS 3.5.3 | Build con differential loading (ES5 + ES2015) y dev server |
| `30-react16-min` | React 16.13.1 + react-scripts 3.4.4 | CRA 3 completo: build y tests con Jest |
| `40-svelte3-min` | Svelte 3.29.0 + Rollup 2.32.1 | Compilador propio, bundle con Rollup y servidor estático escrito a mano |

---

## Regla de oro: `npm install` una vez, `npm ci` siempre

El lockfile lo genera **el autor del fixture**, una sola vez, dentro del baseline:

```text
Node 10.24.1
npm 6.14.12
linux/amd64
```

A partir de ahí el laboratorio usa exclusivamente:

```bash
npm ci
```

Si ejecutas `npm install` sobre un fixture ya congelado, resolverás un árbol
distinto al del curso y romperás justo lo que la fase intenta enseñar. Cuando
`package-lock.json` cambie sin que hayas tocado `package.json`, **eso es el
hallazgo**, no un contratiempo.

---

## Cómo se ejecutan

Desde el directorio de un fixture, con la imagen del laboratorio:

```bash
docker run \
  --rm \
  --platform linux/amd64 \
  -e NODE_VERSION=10.24.1 \
  --mount type=bind,src="$PWD",dst=/workspace \
  --mount type=volume,src=phase11-vue2-node10-modules,dst=/workspace/node_modules \
  -w /workspace \
  legacy-node-toolchain:phase11 \
  npm ci
```

El volumen lleva el nombre del proyecto **y** la versión de Node a propósito:
`node_modules` puede contener addons nativos compilados contra una ABI concreta,
y compartir un volumen entre generaciones de Node es fabricarte un bug.

---

## Estado verificado

Los cinco se validaron de punta a punta con Node 10.24.1 y npm 6.14.12 sobre
`linux/amd64`, partiendo de un volumen vacío y del lockfile congelado:

| Fixture | `npm ci` | `build` | `test` | dev server |
|---|---|---|---|---|
| `00-node-smoke` | ✅ | ✅ | ✅ | ✅ |
| `10-vue2-min` | ✅ | ✅ | ✅ | ✅ HTTP 200 en 8s |
| `20-angular8-min` | ✅ | ✅ | N/A ⁽¹⁾ | ✅ HTTP 200 en 15s |
| `30-react16-min` | ✅ | ✅ | ✅ | — |
| `40-svelte3-min` | ✅ | ✅ | ✅ | — |

⁽¹⁾ Los unit tests de Angular 8 son Karma + navegador. Eso arrastra Chromium y
dependencias gráficas, así que queda fuera del baseline y se reporta como
**N/A**, no como "no hay tests". Fingir que un test no existe es peor que
declararlo fuera de alcance.

---

## Dos trampas que ya encontramos por ti

### `@vue/cli-plugin-unit-jest` no trae preset en la línea 3.x

Escribir esto en `jest.config.js` parece lo natural y **falla**:

```js
module.exports = {
  preset: '@vue/cli-plugin-unit-jest'
};
```

```text
Validation Error:
Module @vue/cli-plugin-unit-jest should have "jest-preset.js"
or "jest-preset.json" file at the root.
```

El preset llegó con Vue CLI **4**. En la 3.x el proyecto generado llevaba la
configuración de Jest completa, y eso es lo que tiene el fixture. Es un ejemplo
perfecto de por qué copiar una receta actual a un stack de 2019 no funciona: la
receta no está mal, está fechada.

### `eventsource@2.0.2` exige Node ≥ 12

Al instalar el fixture de Vue verás:

```text
npm WARN notsup Unsupported engine for eventsource@2.0.2:
wanted: {"node":">=12.0.0"} (current: {"node":"10.24.1"})
```

Es una dependencia transitiva del cliente de HMR que se publicó años después del
stack. **La advertencia es real y el fixture funciona igual**, porque ese paquete
se carga en el navegador, no en el Node del contenedor. Queda documentado aquí
para que nadie pierda una tarde persiguiéndolo — y para que se vea el mecanismo:
un rango `^` sin lockfile deja entrar código futuro en un proyecto congelado.

---

## Lo que estos fixtures NO demuestran

No demuestran que "todo proyecto Vue 2 funciona". Demuestran que **un proyecto
mínimo representativo, bajo un conjunto exacto de versiones, funciona**. Es una
afirmación mucho más pequeña y mucho más defendible.

Tampoco cubren dependencias nativas: `node-sass`, `canvas` y compañía tienen sus
propios laboratorios. Mezclar una dependencia nativa problemática dentro del
fixture obligatorio confundiría dos preguntas distintas.
