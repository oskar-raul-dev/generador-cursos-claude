# se06 — TLS y certificados

Código de la sección [`op052-se06-tls-y-certificados.md`](../../op052-se06-tls-y-certificados.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `tls.py` | Una CA interna, un servidor HTTPS y las cuatro formas de llamarlo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add httpx cryptography

python3 tls.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
