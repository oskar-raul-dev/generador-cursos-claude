# c-sharp-for-java-devs-20261005-f6c7

- **Curso:** c-sharp-for-java-devs
- **Tanda:** — (revisión del curso cerrado contra `zz-instrucciones/`)
- **Creado:** 2026-10-05
- **Propósito:** validación contra zz-instrucciones y migración de diagramas a Mermaid
- **Estado:** extraído
- **Cómo regenerar lo que limpiar.py borra:** `salidas/` se rehace corriendo los verificadores
  (`python3 -B zz-instrucciones/herramientas/verificador_base.py <curso> --perfil=courses-ia`, y
  `python3 -B prompts/verificar-corpus.py` desde la raíz del curso) y `mmdc` sobre los dos `.md`.

## Qué hay

- `README.md` — cómo se corre cada prueba y qué se espera ver (escrito el 06/10/2026 desde la transcripción).
- `comandos-revision.sh` — los comandos de la sesión `5c52573d` que tocaron este directorio, en orden y tal como corrieron.
- `buscar_diagramas.py` — lista los bloques `text` o sin lenguaje con forma de diagrama.
- `salidas/antes.log`, `publicacion.log` — el verificador base antes de tocar nada.
- `salidas/despues*.log` — el verificador del curso y los perfiles base al cerrar.
- `salidas/*.svg`, `f11.png`, `f24.png`, `*.mmd` — los dos diagramas dibujados con `mmdc` 12.0.0.
- `salidas/x.png` — resto de una invocación fallida de `mmdc`; sin valor.
- `salidas/copia-sembrada/` — copia de los `.md` y `prompts/` con cuatro errores sembrados para
  probar `verificar-corpus.py` (los cuatro detectados).

## Qué sirvió

- La lógica de `buscar_diagramas.py` pasó, reducida, al aviso `DIAGRAMA` de
  `prompts/verificar-corpus.py` del curso.
