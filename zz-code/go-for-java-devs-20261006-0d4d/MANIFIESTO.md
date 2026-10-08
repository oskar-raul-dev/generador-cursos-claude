# go-for-java-devs-20261006-0d4d

- **Curso:** go-for-java-devs
- **Tanda:** rescate posterior al cierre (preparación, redacción y revisión, 12–13/09/2026)
- **Creado:** 2026-10-06
- **Propósito:** rescatar de las transcripciones de las sesiones el código de prueba de la producción del curso, con instrucciones para replicarlo
- **Estado:** archivado
- **Cómo regenerar lo que limpiar.py borra:** nada de aquí lo necesita

## Qué hay

- `README.md`: qué se verificó, cómo se corre y por qué en este curso no se ejecutó código Go.
- `rescatar.sh`: rehace desde cero las carpetas generadas de este directorio; es un envoltorio de `../regenerar-rescates.py --dir <este directorio>`, que lee las sesiones y opciones de `../rescates.tsv`.
- `01-preparacion-918474ae/`, `02-redaccion-b1c17b96/`, `03-revision-c9051874/`: comandos, bitácora y las verificaciones del corpus con su salida.

## Qué sirvió

- Nada se extrajo: las verificaciones ya viven, generalizadas, en `prompts/verificar-corpus.py` del curso (05/10/2026).
- No se ejecutó nada al rescatar.
