# sy08 — Veredicto: dónde deja de servir el script de shell

Código de la sección [`op122-sy08-veredicto.md`](../../op122-sy08-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `ingenuo.sh` | — |
| `cuidadoso.sh` | — |
| `contar.py` | La misma tarea en Python, y el experimento que compara las tres versiones |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 contar.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
