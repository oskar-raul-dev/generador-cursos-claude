# ar01 — Binario de verdad

Código de la sección [`op147-ar01-binario-de-verdad.md`](../../op147-ar01-binario-de-verdad.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `binario.py` | Binario de verdad: registros con struct, acceso con mmap, mojibake, zip con zstd y el filtro de tar |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 binario.py              # solo la biblioteca estándar
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
