# jv03 — GraalPy y Jython

Código de la sección [`op094-jv03-graalpy-y-jython.md`](../../op094-jv03-graalpy-y-jython.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `cuenta.py` | El mismo bucle de Python puro, cinco rondas: para ver el arranque y el calentamiento del JIT |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 cuenta.py
# GraalPy: descargar graalpy3.13-community-25.4.4 de github.com/oracle/graalpython/releases
./graalpy-community-25.4.4-linux-aarch64/bin/graalpy cuenta.py

java -jar jython-standalone-2.7.4.jar -c 'print "Python 2 sí"'
java -jar jython-standalone-2.7.4.jar -c 'sede = "Suba"; print(f"regalía de {sede}")'
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
