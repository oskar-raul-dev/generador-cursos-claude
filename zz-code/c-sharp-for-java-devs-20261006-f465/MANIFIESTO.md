# c-sharp-for-java-devs-20261006-f465

- **Curso:** c-sharp-for-java-devs
- **Tanda:** rescate posterior al cierre (preparación, redacción F00–F24 y revisión, 12–13/09/2026)
- **Creado:** 2026-10-06
- **Propósito:** rescatar de las transcripciones de las sesiones el código de prueba de la producción del curso, con instrucciones para replicarlo
- **Estado:** archivado
- **Cómo regenerar lo que limpiar.py borra:** nada de aquí lo necesita

## Qué hay

- `README.md`: qué se verificó, cómo se corre y por qué en este curso no se ejecutó código C#.
- `rescatar.sh`: rehace desde cero las carpetas generadas de este directorio; es un envoltorio de `../regenerar-rescates.py --dir <este directorio>`, que lee las sesiones y opciones de `../rescates.tsv`.
- `01-preparacion-3a759429/`, `02-redaccion-aadc4f68/`, `03-revision-03630220/`: comandos, bitácora y las verificaciones del corpus con su salida.
- `salidas/`: el inventario de las 23 sesiones que mencionan los cursos de `cursos-algoritmos-lenguajes`.

## Qué sirvió

- Nada se extrajo: las verificaciones de la revisión ya viven, generalizadas, en `prompts/verificar-corpus.py` del curso (05/10/2026).
- El rescatador nació aquí (`rescatar.py` e `inventariar.py`) y el 06/10/2026 pasó, unido y con rutas deducidas, a `zz-instrucciones/herramientas/rescatar-transcripcion.py`: sirve para cualquier curso producido antes de la regla 7 de `zz-code/README.md`.
- No se ejecutó nada al rescatar.
