# python-for-java-devs-20261006-772f

- **Curso:** python-for-java-devs
- **Tanda:** rescate posterior al cierre (camino base, tracks `ia` y `ds`, carta hasta T19)
- **Creado:** 2026-10-06
- **Propósito:** rescatar de las transcripciones de las sesiones el código de prueba de la producción del curso, con instrucciones para replicarlo
- **Estado:** archivado
- **Cómo regenerar lo que limpiar.py borra:** nada de aquí lo necesita; `salidas/claude-501/` se rehace con `./preparar_base.sh`

## Qué hay

- `README.md`: qué prueba cada carpeta, de qué sesión salió, cómo se corre hoy en contenedor y cómo se limpia.
- `rescatar.sh`: rehace desde cero las carpetas generadas de este directorio; es un envoltorio de `../regenerar-rescates.py --dir <este directorio>`, que lee las sesiones y opciones de `../rescates.tsv`.
- `01-base-b74cbeda/`: el arnés del camino base (F00–F17) que vivía en `/tmp/claude-501/`, 73 archivos, más bitácora y comandos.
- `02-ia-bd47dbaf/`, `03-ds-2859734a/`: bitácora, comandos y verificaciones de los tracks `ia` y `ds` (su código está en `src/` del curso) y las cuatro sondas de `ds02`.
- `04-carta-5c52573d/`: bitácora y comandos de la carta, `humo-por-seccion.sh` (136 secciones) y 16 archivos que ya no existen en disco.
- `05-carta-codigo/`: copia versionada del código de `../python-for-java-devs-20261005-f516/salidas/` (273 archivos), hecha con `copiar_codigo_carta.sh`.
- `preparar_base.sh`, `extraer_humo.py`, `copiar_codigo_carta.sh`: los auxiliares de corrida y de reconstrucción.

## Qué sirvió

- Nada se extrajo de nuevo: los resultados ya están en el curso (`BENCHMARKS.md`, las 📏 de cada fase y las salidas de la carta). Se archiva como referencia de cómo se midió y para repetir las mediciones con dos núcleos, la deuda que declara `BENCHMARKS.md`.
- No se ejecutó nada al rescatar.
- La carta sigue en producción (T20 en adelante) en `../python-for-java-devs-20261005-f516/`; si escribe más código en su `salidas/`, `rescatar.sh` lo vuelve a copiar.
