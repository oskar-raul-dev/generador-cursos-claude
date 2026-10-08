# co04 — Probar correo sin mandarlo

Código de la sección [`op018-co04-probar-correo.md`](../../op018-co04-probar-correo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `envio.py` | Arma y manda la liquidación: dos funciones, para poder probar cada una |
| `test_envio.py` | Pruebas del correo: unitaria y con un servidor SMTP real dentro del proceso |
| `compose.yaml` | Configuración del ejemplo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev pytest aiosmtpd

pytest -q test_envio.py

docker compose up -d
python3 -c "
from envio import build_settlement, send
send(build_settlement('Suba', 'edgar.rojas@franquicias.example', 'liquidacion-suba.pdf', b'%PDF'), '127.0.0.1', 1025)"
curl -s http://127.0.0.1:8025/api/v1/messages | python3 -m json.tool | head -20
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
