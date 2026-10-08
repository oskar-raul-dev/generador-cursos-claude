# tx08 — Texto difícil: Unicode e internacionalización

Código de la sección [`op062-tx08-texto-dificil.md`](../../op062-tx08-texto-dificil.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `texto.py` | Normalización, orden en español, grafemas y formatos de Colombia |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add regex babel

python3 texto.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
