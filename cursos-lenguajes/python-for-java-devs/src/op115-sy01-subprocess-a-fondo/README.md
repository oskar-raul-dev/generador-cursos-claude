# sy01 — subprocess a fondo

Código de la sección [`op115-sy01-subprocess-a-fondo.md`](../../op115-sy01-subprocess-a-fondo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `trampas_subprocess.py` | Las tres trampas de subprocess provocadas y corregidas: tubería llena, nieto huérfano, inyección de shell |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 trampas_subprocess.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
