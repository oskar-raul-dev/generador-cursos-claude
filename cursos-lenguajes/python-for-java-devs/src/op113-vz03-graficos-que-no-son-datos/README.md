# vz03 — Gráficos que no son datos

Código de la sección [`op113-vz03-graficos-que-no-son-datos.md`](../../op113-vz03-graficos-que-no-son-datos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `diagramas.py` | El diagrama del cierre generado desde los mismos datos que lo definen (DOT y Mermaid), y un semáforo en SVG |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
sudo apt-get install -y graphviz          # el binario dot
uv add graphviz drawsvg

python3 diagramas.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
