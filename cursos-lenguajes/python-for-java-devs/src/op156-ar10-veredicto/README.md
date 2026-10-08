# ar10 — Veredicto: el pegamento contra el binario

Código de la sección [`op156-ar10-veredicto.md`](../../op156-ar10-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `pegamento.py` | ¿Biblioteca en el proceso o binario por subprocess? El veredicto del track como función, aplicado a siete tareas |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 pegamento.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
