# ui03 — Streamlit y su re-ejecución

Código de la sección [`op066-ui03-streamlit.md`](../../op066-ui03-streamlit.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `contador.py` | — |
| `cartera_app.py` | El tablero de cartera de Patricia, con los dos errores del modelo de re-ejecución a la vista |
| `prueba_app.py` | Simula a Patricia: elige una sede y marca tres veces. Cuenta cuántas veces corrió cada carga |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add streamlit

python3 prueba_app.py
streamlit run cartera_app.py      # para verla en el navegador
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
