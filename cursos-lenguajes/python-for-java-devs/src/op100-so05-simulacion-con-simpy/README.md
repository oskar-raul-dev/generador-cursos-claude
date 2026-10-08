# so05 — Simulación de eventos discretos

Código de la sección [`op100-so05-simulacion-con-simpy.md`](../../op100-so05-simulacion-con-simpy.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `sala_de_espera.py` | El sábado de Chapinero en SimPy: dónde se forma la cola, y qué la arregla |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add simpy

python3 sala_de_espera.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
