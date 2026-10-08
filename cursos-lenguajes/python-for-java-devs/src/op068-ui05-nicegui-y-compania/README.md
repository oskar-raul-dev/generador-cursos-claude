# ui05 — NiceGUI y compañía

Código de la sección [`op068-ui05-nicegui-y-compania.md`](../../op068-ui05-nicegui-y-compania.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `app_nicegui.py` | La pantalla de cartera en NiceGUI: un manejador de evento cambia una etiqueta |
| `app_shiny.py` | La misma pantalla en Shiny: la salida declara de qué entrada depende |
| `medir.py` | Lo que pesa cada biblioteca: tamaño instalado y tiempo de importación, cada una en su venv |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 app_nicegui.py              # http://127.0.0.1:8081
shiny run app_shiny.py --port 8082  # http://127.0.0.1:8082

python3 medir.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
