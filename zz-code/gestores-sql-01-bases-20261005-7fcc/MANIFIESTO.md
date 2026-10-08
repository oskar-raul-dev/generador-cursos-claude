# gestores-sql-01-bases-20261005-7fcc

- **Curso:** `cursos-bd/gestores-sql/01-bases` (El motor de motores)
- **Tanda:** P11 — alineación de `prompts/` con los lineamientos de producción
- **Creado:** 2026-10-05
- **Propósito:** probar con `mmdc` la convención de diagramas en Mermaid del curso (D-12, D19, D20)
  antes de fijarla en la guía §3.2, y probar los verificadores del curso contra una copia sembrada.
- **Estado:** extraído
- **Cómo regenerar lo que limpiar.py borra:** `salidas/` se rehace corriendo
  `mmdc -i prototipos/<x>.mmd -o salidas/svg/<x>.svg` por prototipo, y desde la raíz del curso
  `python3 prompts/verificar-diagramas.py --incluir-prompts --salida <este directorio>/salidas/diagramas-prompts`.
  La copia sembrada no tiene script: se rehace a mano copiando `prompts/` del curso y agregando una
  fase F15 con un error de cada tipo, un solucionario corto y un README que cita `zz-code/` y un
  desechable.

## Qué hay

- `prototipos/` — once diagramas Mermaid: boceto con óvalos (d01), entidad débil e identificadora
  (d02), pata de gallo (d04), especialización en pata de gallo (d05), clases UML (d06), árbol B+ (d07),
  árbol de consulta (d08), grafo de precedencia (d09), Bachman (d10), árbol jerárquico (d11) y grafo de
  autorización (d12). El d03 probaba las formas `@{ shape: ellipse }` y falló (`No such shape:
  ellipse.`); se borró después de anotarlo en H13.
- `salidas/svg/` — los SVG de los prototipos; `salidas/*.png` — cinco revisados a ojo.
- `salidas/antes-courses-ia.log` — el verificador base sobre el curso antes de P11: tres
  `ANCLA-FE0F` en `inventario-de-fuentes.md`.
- `salidas/copia-sembrada/` — copia de `prompts/` con una fase y un README sembrados: el verificador
  detectó `PROMPTS`, `ANCLA`, `LATEX`, `IDENT`, `RADB`, `ZZ-CODE`, `SECCION`, `EJERCICIOS`,
  `NUMERACION`, `SOLUCIONARIO`, `DIAGRAMA`, `ANCHO-TEXT`, `PALABRAS` y, con `--publicacion`,
  `PRIVADO`.
- `salidas/diagramas-sembrada/`, `salidas/diagramas-prompts/` — lo que dibujó `verificar-diagramas.py`
  (uno roto detectado en la copia; cuatro de cuatro en `prompts/`).
- `salidas/docker-inventario-inicial.log` — inventario de Docker antes de correr el verificador dentro
  de `mdm-lab`. No se creó ni se borró ningún contenedor.

## Qué sirvió

- La convención pasó a la guía §3.2 del curso y al hallazgo H13 de
  `prompts/verificacion-de-laboratorio/hallazgos.md`.
- Los verificadores probados viven en el `prompts/` del curso: `verificar-corpus.py` y
  `verificar-diagramas.py`.
- Nada de este directorio se cita desde el curso publicado.
