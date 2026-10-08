# storefront

La página de Droguerías La Vecina. No sale del patrimonio: reemplaza la página del portal.

## Stack

- React (la versión de `a01`) con Vite y TypeScript.
- Imagen: `lab/storefront`, multi-stage desde la Fase 04: Vite compila en una etapa con Node, y la
  final es nginx sin privilegios sirviendo `dist/` en el 8080 (fijo: nginx no lee `PORT`). En G0 se
  servía con `vite preview`, y de ahí quedó `allowedHosts: true` en `vite.config.ts`.
- La salud es un archivo estático: `public/health/live`.
- Desde G2, la configuración (`API_BASE_URL`, `BRAND_NAME`) la lee nginx al arrancar y la sirve en
  `/config.json`, desde `nginx/default.conf.template`. La imagen va en `:g2`.

## Comandos

```bash
task build -- storefront              # construye la imagen con el motor activo
task compose:up                       # el sistema en compose
task conformance -- G2                # la suite del paso; tiene que pasar
```

## Convenciones

- Identificadores en inglés, comentarios en español con tildes.
- Una línea de texto por petición a stdout (método, ruta, estado). JSON recién en G7.
- La página le pide los productos a `catalog` desde el navegador, a la dirección de `/config.json`.
  Nada de configuración se hornea al compilar: ni `import.meta.env` ni `ARG` en el Dockerfile.
- El storefront no tiene OpenAPI: su contrato es `../../contracts/conformance/storefront.*.hurl`.

## El contrato, paso a paso

| Paso | Qué | Estado |
|---|---|---|
| G0 | una página con el nombre de la casa; `/health/live` | ✅ hecho |
| G1 | lista los productos de `catalog`, pidiéndolos desde el navegador a `VITE_API_BASE_URL` (horneada al compilar; por defecto `http://api.localhost:8080`) | ✅ hecho |
| G2 | lee su configuración al arrancar (`/config.json`, armado por nginx con `API_BASE_URL` y `BRAND_NAME`); `no-store` en la configuración y `no-cache` en `index.html` | ✅ hecho |
| G5 | el flujo de venta desde la página: la droguería en `?store=` (DRO-007 por defecto), el precio de `pricing` y un botón por producto que le pide la venta a `inventory` (`POST /sales`) | ✅ hecho |

**No agregues nada de un paso pendiente**, aunque sea fácil o el framework lo traiga de serie: una
capacidad antes de su fase invalida el paso.
