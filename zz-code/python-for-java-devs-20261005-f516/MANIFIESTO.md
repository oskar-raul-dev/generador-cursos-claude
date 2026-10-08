# python-for-java-devs-20261005-f516

- **Curso:** python-for-java-devs
- **Tanda:** P-carta
- **Creado:** 2026-10-05
- **Propósito:** preparación, redacción y verificación de la carta opcional (opNNN), T1–T24
- **Estado:** extraído (07/10/2026): la carta está cerrada (T1–T24) y su código pasó al curso como `src/opNNN-…/`
- **Cómo regenerar lo que limpiar.py borra:** volver a correr la sección con su comando de `../python-for-java-devs-20261006-772f/04-carta-5c52573d/humo-por-seccion.sh`

## Qué hay

- `README.md`: el arnés, cómo se corre una sección, el inventario de Docker y la limpieza.
- `humo.py`, `humo_servicio.py`: la prueba de humo de una sección en `python:3.14.7`, sola o con servicios en red propia.
- `probado.py`, `plan.py`, `carta.py`: rótulos de la sección, filas del plan de producción y la lista única de la carta.
- `verificar_urls.py`: el código de estado de cada URL de una sección.
- Desde T20 (07/10/2026): `comparar.py` (salida publicada contra corrida), `ensamblar.py` (sección desde plantilla con el código y la salida reales) y `src_desde_secciones.py` (T24: extrae los archivos de cada sección y arma `src/opNNN-…/` con su README).
- `salidas/t24/`: los andamios de la verificación final (systemd como PID 1, el servidor FTPS, los esquemas del ejercicio 4 de lg02, la firma de lg03 y la cadena de qa08).
- `salidas/<id>/`: el código y las salidas de cada sección (no versionado; copia del código en `../python-for-java-devs-20261006-772f/05-carta-codigo/`).
- `salidas/imagenes-bajadas.txt` y los dos inventarios de Docker.

## Qué sirvió

- Al curso pasó el código de cada sección, como `src/opNNN-…/`, generado desde el Markdown publicado con `src_desde_secciones.py --escribir` (las secciones siguen sin citar `zz-code/`).
- `humo_servicio.py` (red propia etiquetada, servicios sin puertos, limpieza garantizada) es candidato a `zz-instrucciones/herramientas/` cuando cierre la carta.
