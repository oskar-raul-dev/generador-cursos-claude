# jv01 — Los formatos que la JVM ya produce

Código de la sección [`op092-jv01-los-formatos-de-la-jvm.md`](../../op092-jv01-los-formatos-de-la-jvm.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `abono.avsc` | — |
| `EscribeAbonos.java` | — |
| `lee_abonos.py` | Leer en Python lo que Java escribió en Avro, y leerlo con un esquema que evolucionó |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
# Con las dependencias de Avro en lib/ (avro, jackson, commons-compress, slf4j-api):
java -cp "lib/*" EscribeAbonos.java

uv add fastavro
python3 lee_abonos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
