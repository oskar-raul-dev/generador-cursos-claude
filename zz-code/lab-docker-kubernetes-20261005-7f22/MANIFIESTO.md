# lab-docker-kubernetes-20261005-7f22

- **Curso:** lab-docker-kubernetes
- **Tanda:** — (revisión del curso cerrado)
- **Creado:** 2026-10-05
- **Propósito:** revisión contra zz-instrucciones: anclas, verificador y diagramas Mermaid
- **Estado:** extraído
- **Cómo regenerar lo que limpiar.py borra:** `salidas/` se regenera con `volcar_bloques.py` y `migrar_diagramas.py --volcar salidas/mmd` + `mmdc`

## Qué hay

- `arreglar_anclas_fe0f.py` — corrige los `ANCLA-FE0F` que reporta el verificador base (el verificador ya trae `--corregir-fe0f`, que hace lo mismo).
- `volcar_bloques.py` — copia del de docker-container-legacy: vuelca los bloques `text` con marcas de diagrama.
- `migrar_diagramas.py` — los siete diagramas en Mermaid y el reemplazo en el curso (`--aplicar`), con `--volcar` para dibujarlos.
- `salidas/` — el volcado de bloques y los `.mmd`/`.png` dibujados con `mmdc`.

## Qué sirvió

- 32 anclas corregidas y 7 diagramas en Mermaid, ya aplicados al curso (D44, guía §19).
- `prompts/verificar-corpus.py` del curso, escrito a partir del de docker-container-legacy.
