# pk06 — Empaquetar y publicar

Código de la sección [`op136-pk06-empaquetar-y-publicar.md`](../../op136-pk06-empaquetar-y-publicar.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `aurea-cartera/pyproject.toml` | Configuración del ejemplo |
| `aurea-cartera/src/aurea_cartera/__init__.py` | Cálculos de cartera de la red Áurea |
| `aurea-cartera/src/aurea_cartera/cli.py` | — |
| `publicar.sh` | — |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install uv twine pypiserver
bash publicar.sh
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
