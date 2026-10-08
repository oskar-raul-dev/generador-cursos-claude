# jv04 — La arquitectura mixta: dónde poner la frontera

Código de la sección [`op095-jv04-la-arquitectura-mixta.md`](../../op095-jv04-la-arquitectura-mixta.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `frontera.py` | El costo de una frontera HTTP con un servicio Java: llamada por llamada, en lote, y la equivalencia |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
java -Dsun.net.httpserver.nodelay=true ServidorRegalias.java &      # el porqué de la opción, en §4

uv add httpx
python3 frontera.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
