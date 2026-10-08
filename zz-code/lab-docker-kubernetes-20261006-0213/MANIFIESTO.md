# lab-docker-kubernetes-20261006-0213

- **Curso:** lab-docker-kubernetes
- **Tanda:** P11–T16 (rescate posterior al cierre)
- **Creado:** 2026-10-06
- **Propósito:** rescatar las pruebas de la producción del curso (scratchpads de las sesiones y borradores de P11) con instrucciones para replicarlas
- **Estado:** archivado
- **Cómo regenerar lo que limpiar.py borra:** `a07/inventory` y `a08/inventory` con `./mvnw -q package -DskipTests`; `a09/ssr` con `npm ci`; lo demás no tiene dependencias instaladas

## Qué hay

- `README.md`: qué prueba cada archivo, de qué sesión salió, cómo se corre y cómo se limpia.
- `01-p11-t0-t2/`: `borrador-p11/` (copia del `prompts/verificacion-de-laboratorio/borrador/` del curso) y el scratchpad de la sesión `6c5ff4c5`.
- `02-t3-t5/`: scratchpad de la sesión `c9879aea` (F03–F12).
- `03-t6-t10/`: scratchpad de la sesión `1c1220f7` (F13–F23).
- `04-t11-t16/`: scratchpad de la sesión `ac682bf5` (F24–F27 y los apéndices a06–a15).
- `05-limpieza/`: inventarios de imágenes de la sesión de limpieza `19969a6c`.

## Qué sirvió

- Nada se extrajo de nuevo: el resultado de estas pruebas ya está en el curso (`hallazgos.md` H1–H270, `logs/`, `BENCHMARKS.md`). Se archiva como referencia de cómo se midió, para la prueba de aceptación de `prompts/pendientes-a-futuro.md`.
- Las rutas al scratchpad viejo se reescribieron hacia estas carpetas; no se ejecutó nada al copiar.
