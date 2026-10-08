# jv02 — JPype y Py4J

Código de la sección [`op093-jv02-jpype-y-py4j.md`](../../op093-jv02-jpype-y-py4j.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `src/main/java/co/aurea/Regalias.java` | — |
| `llamar_java.py` | La liquidación Java llamada desde Python: JPype (en proceso) y Py4J (por socket), medidas |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
javac -d build src/main/java/co/aurea/Regalias.java && jar cf regalias.jar -C build .

uv add jpype1 py4j
python3 llamar_java.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
