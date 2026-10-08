# 📎 Apéndice a09 — Qué cambia cuando el frontend necesita un runtime

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 11](11-configuracion-y-secretos.md) (el contrapunto), [Fase 04](04-empaquetar-los-cuatro-runtimes.md) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** de 32 a 92 MiB por réplica del *storefront* con renderizado en servidor, contra 7 MiB del nginx de siempre
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. La [Fase 04](04-empaquetar-los-cuatro-runtimes.md) dijo que el
frontend no es un servicio: es un archivo que alguien sirve. Este apéndice muestra qué pasa cuando deja de serlo, porque
la página se arma en el servidor (*server-side rendering*, SSR).

**Qué queda fuera:** los frameworks de SSR completos (Next.js y sus parientes), la hidratación en el navegador, y el
botón de venta: la versión de este apéndice solo lista el catálogo con precios.

---

## Índice

- [El storefront de siempre, y el que renderiza en el servidor](#el-storefront-de-siempre-y-el-que-renderiza-en-el-servidor)
- [Ahora es un servicio](#ahora-es-un-servicio)
- [La configuración, en cada petición](#la-configuración-en-cada-petición)
- [Lo que cuesta, medido](#lo-que-cuesta-medido)
- [Cuando un vecino se cae](#cuando-un-vecino-se-cae)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-5)

---

## El storefront de siempre, y el que renderiza en el servidor

El `storefront` del curso es React compilado por Vite y servido por nginx sin privilegios: el navegador baja el HTML y
el JavaScript, y después pide `/config.json` ([Fase 11](11-configuracion-y-secretos.md), G2), el catálogo y los precios a
la puerta. El servidor no sabe qué hay en la página.

La versión de este apéndice hace lo contrario: un proceso de Node recibe la petición, pide el catálogo a `catalog` y los
precios a `pricing` **por la red del cluster**, arma el HTML con `renderToString` de React, y lo devuelve con los datos
adentro. Son 61 líneas, sin JSX ni build:

```javascript
// server.mjs (a09): la página se arma en cada petición.
const [products, priceList] = await Promise.all([
  getJson(`${CATALOG}/products`),                                  // http://catalog.apps.svc.cluster.local:8080
  getJson(`${PRICING}/prices?store=${store}`).catch(() => []),
]);
const html = '<!doctype html>' + renderToString(h(Page, { brand, store, products, prices }));
```

```text
$ curl -s "http://ssr.localhost:8080/?store=DRO-007"
<!doctype html><html lang="es"><head><meta charSet="utf-8"/><title>Droguerías La Vecina</title></head><body>
<h1>Droguerías La Vecina</h1><p>Droguería DRO-007</p><ul><li data-sku="SKU-0001">Acetaminofén 500 mg · $24.100</li>…
```

## Ahora es un servicio

Todo lo que el curso le enseñó a un backend, ahora lo necesita el frontend:

- **Sondas** que deciden el tráfico y la vida ([Fase 15](15-salud-y-recursos.md)).
- **Memoria y CPU** que se miden y se limitan: el render consume CPU en cada petición, y el HPA tiene algo que medir
  ([Fase 16](16-escalado-y-rollout.md)).
- **Red hacia los vecinos**: llama a `catalog` y a `pricing` por adentro del cluster, así que la `NetworkPolicy` de la
  cadena ([Fase 20](20-seguridad-del-pod-y-de-la-red.md)) tiene que dejarlo salir, y deja de necesitar CORS
  ([Fase 10](10-la-entrada-al-sistema.md)): el navegador ya no le habla a la API para listar.
- **Una imagen de servicio**: 254 MB (Node y React) contra 82 MB del `storefront` con nginx.

## La configuración, en cada petición

Es el contrapunto de la [Fase 11](11-configuracion-y-secretos.md), con el mismo experimento de dos despliegues: la misma
imagen, una para La Vecina y otra para QA, cada una con su `ConfigMap`. Y una diferencia: el proceso lee la marca de un
archivo montado **en cada petición**, no al arrancar:

```javascript
const brand = process.env.BRAND_FILE
  ? readFileSync(process.env.BRAND_FILE, 'utf8').trim()
  : (process.env.BRAND_NAME ?? 'Droguerías La Vecina');
```

```text
$ curl -s http://ssr.localhost:8080/ | grep -o "<title>[^<]*</title>"        <title>Droguerías La Vecina</title>
$ curl -s http://ssr-qa.localhost:8080/ | grep -o "<title>[^<]*</title>"     <title>La Vecina · QA</title>
$ kubectl -n apps patch configmap storefront-ssr-brand --type merge -p '{"data":{"brand":"Droguerías La Vecina · Siempre llega"}}'
la página cambió 68 s después del patch
storefront-ssr-766c7d5c8f-c98q7 reinicios: 0
```

Sesenta y ocho segundos y ningún reinicio: el kubelet actualiza los archivos de un `ConfigMap` montado en su próxima
sincronización. En la [Fase 11](11-configuracion-y-secretos.md), el `storefront` lee `/config.json` **al arrancar**: cambiar la marca es un rollout. Con un
runtime, la configuración puede cambiar con el proceso vivo. Es una capacidad, y también un riesgo: un cambio que no pasa
por un despliegue no pasa por su revisión.

## Lo que cuesta, medido

Lo que tarda en estar la página con sus datos, a 20 por segundo durante 30 s, desde el host por la puerta, tres
corridas. La estática son cuatro peticiones (el HTML, `/config.json`, el catálogo y los precios), sin contar el JavaScript
de la página; la SSR, una:

| | Mediana | p95 | Memoria del pod en reposo | Después de la carga |
|---|---|---|---|---|
| estática (nginx), cuatro peticiones | 18,2 ms (18,2–18,2) | 20,8 ms (20,4–20,9) | 7 MiB | 7 MiB |
| SSR (Node), una petición | 16,6 ms (16,6–16,7) | 18,5 ms (18,2–19,1) | 32–71 MiB | 92 MiB |

**En la misma red, casi lo mismo.** Las cuatro peticiones de la estática viajan del host a la puerta en un portátil; en
una red real, cada una es un viaje del navegador del cliente hasta el servidor, y ahí es donde la SSR gana, con una sola.
No lo medí con latencia de red real: la diferencia que se vería en Bogotá con un celular no está en esta tabla. Lo que sí
está: **de 4 a 13 veces la memoria** por réplica, y CPU en cada petición donde nginx no gastaba nada. (Los 32 MiB son de
la réplica de QA, que no atendió tráfico; los 71, de la de La Vecina después de las primeras pruebas.)

## Cuando un vecino se cae

Con `catalog` en cero réplicas:

```text
ssr: 503 · No se pudo armar la página: The operation was aborted due to timeout
estática, el HTML: 200 · y el catálogo que pide después: 503
readiness de la ssr: 1/1
```

La estática entrega su página, y la página muestra el error del catálogo; la SSR no tiene página que entregar. Y su
readiness sigue en verde, porque —la regla de G4, [Fase 15](15-salud-y-recursos.md)— una sonda no consulta a los vecinos.
**El frontend con runtime hereda los vecinos del backend**: timeouts, circuitos y qué mostrar cuando faltan
([Fase 22](22-resiliencia-y-caos.md)). La versión de este apéndice espera 2 s y se rinde; una de verdad mostraría el
catálogo de la última vez.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| una página que lista y vende, para clientes con buena conexión | estática con nginx, como el curso | 7 MiB, nada que escalar, y la página sobrevive a un vecino caído |
| el primer contenido importa (buscadores, celulares lentos, enlaces compartidos) | SSR | una petición con los datos, en lugar de cuatro viajes desde el navegador |
| la configuración tiene que cambiar sin un despliegue | SSR con un `ConfigMap` montado, o la estática con su `config.json` leído en cada visita | con runtime se puede leer en cada petición; sin runtime, el navegador lo vuelve a pedir |
| el equipo no quiere un servicio más que operar | estática | la SSR trae sondas, límites, red y resiliencia, como un backend |

## ⚠️ Advertencias

- La medición de latencia es en red local y no incluye el JavaScript de la página estática.
- Una corrida de memoria por estado; el orden de magnitud es lo que importa (nginx en un dígito, Node en decenas).
- La versión de este apéndice no hidrata la página: sin JavaScript, el botón de venta no existe.

## 📚 Referencias

- React, `renderToString`: https://react.dev/reference/react-dom/server/renderToString
- Kubernetes, *ConfigMaps montados que se actualizan solos*: https://kubernetes.io/docs/concepts/configuration/configmap/#mounted-configmaps-are-updated-automatically
- web.dev, *Rendering on the Web* (los modos de renderizado y su costo): https://web.dev/articles/rendering-on-the-web
- k6, *constant-arrival-rate*: https://grafana.com/docs/k6/latest/using-k6/scenarios/executors/constant-arrival-rate/

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (5)

### Ejercicio 1 — Dos marcas, una imagen
Despliega las dos variantes de este apéndice y comprueba que cada una muestra su marca.

**Criterio:** los dos `<title>` distintos con `curl`, y una sola imagen (`kubectl -n apps get deploy -o jsonpath='{..image}'`).

### Ejercicio 2 — Cuánto tarda el `ConfigMap`
Cambia la marca tres veces y mide cuánto tarda cada una en verse.

**Criterio:** los tres tiempos, entre 0 y unos 90 s, y ningún reinicio del pod.

### Ejercicio 3 — La SSR con límite de CPU
Pon un límite de CPU de 100m a la SSR y repite la carga.

**Criterio:** la mediana y el p95 con y sin límite, y una frase sobre qué escala aquí y qué no escalaba con nginx.

### Ejercicio 4 — Que la SSR sobreviva a `catalog`
Haz que la SSR guarde el último catálogo y lo use si `catalog` no contesta.

**Criterio:** con `catalog` en cero, la SSR contesta 200 con el catálogo anterior y un aviso en la página.

### Ejercicio 5 — ¿La Vecina necesita SSR?
En media página, decide si el portal de pedidos de La Vecina debería renderizar en el servidor.

**Criterio:** la decisión, con la tabla de este apéndice, y lo que no se midió (la red del cliente).

---

> 🏷️ **Este apéndice no lleva tag propio.**
