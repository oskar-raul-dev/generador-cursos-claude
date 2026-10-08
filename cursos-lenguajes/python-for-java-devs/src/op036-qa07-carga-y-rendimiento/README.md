# qa07 — Carga y rendimiento

Código de la sección [`op036-qa07-carga-y-rendimiento.md`](../../op036-qa07-carga-y-rendimiento.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `agenda_api.py` | AgendaAPI mínima: disponibilidad por sede y reserva, con una latencia simulada de base de datos |
| `locustfile.py` | Una auxiliar de recepción: consulta mucho, reserva poco, y espera entre una cosa y otra |
| `test_rendimiento.py` | El cálculo de vencimientos, medido con pytest-benchmark |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add fastapi uvicorn
uv add --dev locust pytest pytest-benchmark

pytest test_rendimiento.py --benchmark-autosave
pytest test_rendimiento.py --benchmark-compare --benchmark-compare-fail=mean:20%
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
