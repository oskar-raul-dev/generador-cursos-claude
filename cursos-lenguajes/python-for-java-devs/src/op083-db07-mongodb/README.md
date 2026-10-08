# db07 — Documental: MongoDB

Código de la sección [`op083-db07-mongodb.md`](../../op083-db07-mongodb.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `citas_mongo.py` | MongoDB desde Python: la consulta sin índice, el documento de 16 MB y el Decimal que BSON no codifica |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add pymongo

docker run -d --name aurea-mongo -p 27017:27017 mongo:8.0.20
AUREA_MONGO=mongodb://localhost:27017 python3 citas_mongo.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
