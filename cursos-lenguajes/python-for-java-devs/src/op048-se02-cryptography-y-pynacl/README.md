# se02 — `cryptography` y PyNaCl

Código de la sección [`op048-se02-cryptography-y-pynacl.md`](../../op048-se02-cryptography-y-pynacl.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `cifrado_backoffice.py` | Una columna cifrada con rotación de claves, y un archivo que solo la central puede abrir |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add cryptography pynacl

python3 cifrado_backoffice.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
