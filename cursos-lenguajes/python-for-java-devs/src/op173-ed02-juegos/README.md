# ed02 — Juegos como vehículo

Código de la sección [`op173-ed02-juegos.md`](../../op173-ed02-juegos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `bucle.py` | El bucle de juego como modelo: mover por cuadro, por segundo, o con paso fijo; la misma partida a 30, 60 y 144 cuadros/s |
| `juego.py` | Un juego de cuarenta líneas: atrapar la pelota. Con --auto juega solo, sin teclado ni pantalla, para probarlo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add pygame-ce==2.5.8

uv run bucle.py

uv run juego.py            # con teclado
uv run juego.py --auto     # solo; sin pantalla: SDL_VIDEODRIVER=dummy uv run juego.py --auto
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
