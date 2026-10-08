# go-for-java-devs-20261005-ab98

- **Curso:** go-for-java-devs
- **Tanda:** — (revisión del curso cerrado contra `zz-instrucciones/`)
- **Creado:** 2026-10-05
- **Propósito:** validación contra zz-instrucciones y migración de diagramas a Mermaid
- **Estado:** extraído
- **Cómo regenerar lo que limpiar.py borra:** `salidas/` se rehace corriendo los verificadores
  (`python3 -B zz-instrucciones/herramientas/verificador_base.py <curso> --perfil=courses-ia`, y
  `python3 -B prompts/verificar-corpus.py` desde la raíz del curso) y `mmdc` sobre los `.mmd`.

## Qué hay

- `README.md` — cómo se corre cada prueba y qué se espera ver (escrito el 06/10/2026 desde la transcripción).
- `comandos-revision.sh` — los comandos de la sesión `5c52573d` que tocaron este directorio, en orden y tal como corrieron.
- `buscar_diagramas.py` — copia del de la sesión de C#: lista bloques `text` con forma de diagrama.
- `migrar_diagramas.py` — los siete reemplazos `text` → Mermaid, ya aplicados (falla si un bloque
  no aparece exactamente una vez).
- `salidas/antes.log`, `publicacion.log`, `diagramas.log`, `candidatos.txt` — el estado inicial.
- `salidas/d*.mmd`, `d*.png` — los siete diagramas dibujados con `mmdc` 12.0.0.
- `salidas/despues.log` — el verificador del curso al cerrar.
- `salidas/copia-sembrada/` — copia con cuatro errores sembrados para probar `verificar-corpus.py`
  (los cuatro detectados).

## Qué sirvió

- La búsqueda de diagramas pasó, reducida, al aviso `DIAGRAMA` de `prompts/verificar-corpus.py`.
