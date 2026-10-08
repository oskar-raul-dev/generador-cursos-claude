# sy05 — Reaccionar a cambios

Código de la sección [`op119-sy05-reaccionar-a-cambios.md`](../../op119-sy05-reaccionar-a-cambios.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `entrada.py` | La carpeta de la aseguradora: leer al 'crearse' lee a medias; 'closed' y el renombrado leen completo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add watchdog

python3 entrada.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
