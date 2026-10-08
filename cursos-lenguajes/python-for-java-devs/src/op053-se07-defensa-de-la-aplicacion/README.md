# se07 — Defensa de la aplicación: deserializar, plantillas y dependencias

Código de la sección [`op053-se07-defensa-de-la-aplicacion.md`](../../op053-se07-defensa-de-la-aplicacion.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `puertas.py` | Tres formas de que un dato se vuelva código en Python, y su versión segura |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add pyyaml jinja2
uv add --dev bandit

python3 puertas.py
bandit -q -f custom --msg-template "{line}: {test_id} {severity} {msg}" puertas.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
