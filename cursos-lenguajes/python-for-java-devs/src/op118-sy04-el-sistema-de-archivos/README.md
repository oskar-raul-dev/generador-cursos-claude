# sy04 — El sistema de archivos en serio

Código de la sección [`op118-sy04-el-sistema-de-archivos.md`](../../op118-sy04-el-sistema-de-archivos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `atomico.py` | Escribir el estado del cierre: ingenuo contra atómico, con SIGKILL a mitad de camino; y un contador con y sin filelock |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add filelock

python3 atomico.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
