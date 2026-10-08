# wf04 — Airflow: el grafo declarativo

Código de la sección [`op025-wf04-airflow.md`](../../op025-wf04-airflow.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `dags/noche_aurea.py` | La noche de Áurea como DAG de Airflow 3: tareas delgadas que llaman al dominio |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add "apache-airflow==3.3.2"
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
