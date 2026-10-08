# docker-container-legacy-20261005-7edb

- **Curso:** docker-container-legacy
- **Tanda:** — (revisión del curso cerrado contra `zz-instrucciones/`)
- **Creado:** 2026-10-05
- **Propósito:** validación contra zz-instrucciones y migración de los diagramas ASCII a Mermaid.
  Solo redacción: no se tocó Docker ni el laboratorio.
- **Estado:** extraído
- **Cómo regenerar lo que limpiar.py borra:** `salidas/` se rehace corriendo, desde la raíz del
  curso, `python3 -B prompts/verificar-corpus.py` (con y sin `--publicacion`) y
  `bash prompts/check-course.sh`; los `.mmd` se regeneran desde `migrar_diagramas.py` y se dibujan
  con `mmdc` 12.0.0.

## Qué hay

- `volcar_bloques.py` — lista los bloques `text` con marcas de diagrama, numerados, para
  clasificarlos a mano (142 con dos marcas o más, 37 con una).
- `migrar_diagramas.py` — los 58 reemplazos `text` → Mermaid, ya aplicados. Cada entrada se ancla
  por archivo, línea de la valla y comienzo de la primera línea; falla sin escribir si alguna no
  coincide.
- `salidas/candidatos.txt`, `candidatos-1-marca.txt` — el volcado que se clasificó.
- `salidas/antes.log`, `publicacion-antes.log`, `check-antes.log` — el estado inicial: 16 errores
  de ancla (15 `ANCLA-FE0F` y uno en a09), 2 `PROMPTS` en el README; `check-course.sh` en 13/13.
- `salidas/gi-antes-*.txt`, `gi-despues-*.txt` — `git ls-files -oi/-o/-ci` antes y después del
  `.gitignore` nuevo: idénticos.
- `salidas/mmd/` — los 58 diagramas sueltos, dibujados con `mmdc`, y cuatro PNG revisados a ojo.
- `salidas/docs/` — los 36 documentos migrados, dibujados enteros con `mmdc` (58 SVG, cero fallas).
- `salidas/copia-sembrada/` — copia con tres documentos en su versión ASCII de `HEAD` y un enlace
  a `prompts/` y una mención a `zz-code/` sembrados en el README: el verificador detectó los seis
  diagramas de caja o flecha vertical, el `ZZ-CODE` y el enlace; no detecta el de `docker stop` de
  F16, dibujado solo con `├─` (declarado en la guía §16.3).

## Qué sirvió

- El criterio de búsqueda pasó, reducido, al aviso `DIAGRAMA` de `prompts/verificar-corpus.py` del
  curso.
- Nada de este directorio se cita desde el curso.
