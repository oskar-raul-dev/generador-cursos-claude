# se03 — Contraseñas y tokens

Código de la sección [`op049-se03-contrasenas-y-tokens.md`](../../op049-se03-contrasenas-y-tokens.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `acceso.py` | Contraseñas con Argon2, y la diferencia entre una sesión que se revoca y un JWT que no |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add argon2-cffi pyjwt

python3 acceso.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
