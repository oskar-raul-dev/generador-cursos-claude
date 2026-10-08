# pk04 — conda, mamba y Miniforge

Código de la sección [`op134-pk04-conda-y-compania.md`](../../op134-pk04-conda-y-compania.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `binario.sh` | 1) pip contra GDAL en una máquina limpia |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
docker run --rm -v "$PWD:/w" python:3.14.7 sh /w/binario.sh
docker run --rm -v "$PWD:/w" condaforge/miniforge3:26.7.2-0 sh /w/binario.sh
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
