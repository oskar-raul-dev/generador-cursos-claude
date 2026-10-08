# pr07 — Versionado y pruebas de contratos

Código de la sección [`op129-pr07-versionado-de-contratos.md`](../../op129-pr07-versionado-de-contratos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `cartera_api.py` | La API de cartera: calcula en cuántas cuotas se paga un saldo |
| `romper.py` | ¿La versión nueva del contrato rompe a los clientes de la anterior? Parámetros obligatorios y campos quitados |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add fastapi uvicorn schemathesis

python3 romper.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
