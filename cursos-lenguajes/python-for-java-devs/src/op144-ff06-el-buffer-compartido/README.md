# ff06 — El buffer compartido y la copia cero

Código de la sección [`op144-ff06-el-buffer-compartido.md`](../../op144-ff06-el-buffer-compartido.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `copia_cero.py` | Copiar o compartir: memoryview, NumPy, memoria compartida entre procesos y Arrow mapeado de disco |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install numpy pyarrow
python3 copia_cero.py           # en Docker, con --shm-size=512m: shared_memory vive en /dev/shm
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
