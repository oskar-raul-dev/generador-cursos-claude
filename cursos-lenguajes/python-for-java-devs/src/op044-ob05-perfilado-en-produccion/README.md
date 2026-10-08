# ob05 — Perfilado en producción

Código de la sección [`op044-ob05-perfilado-en-produccion.md`](../../op044-ob05-perfilado-en-produccion.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `agenda_con_fuga.py` | Un servicio con una fuga lenta y un punto caliente, que se deja observar sin reiniciarlo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev py-spy

python3 agenda_con_fuga.py &                 # imprime su pid
py-spy dump --pid <pid>                       # qué está haciendo ahora mismo
kill -USR1 <pid>; sleep 5; kill -USR1 <pid>   # dos fotos de memoria, cinco segundos aparte
py-spy record --pid <pid> --duration 10 -o perfil.svg   # gráfica de llamas de diez segundos
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
