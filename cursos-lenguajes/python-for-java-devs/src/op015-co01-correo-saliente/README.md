# co01 — Correo saliente

Código de la sección [`op015-co01-correo-saliente.md`](../../op015-co01-correo-saliente.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `liquidaciones.py` | Manda a cada franquiciado su liquidación trimestral: HTML, texto plano y su PDF, y solo el suyo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv run --with aiosmtpd python -m aiosmtpd -n -l 127.0.0.1:8025 &
SMTP_HOST=127.0.0.1 SMTP_PORT=8025 SMTP_TLS=0 python3 liquidaciones.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
