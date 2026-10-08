# lg07 — Veredicto: escribir el parser o comprarlo

Código de la sección [`op007-lg07-veredicto.md`](../../op007-lg07-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `test_golden.py` | Pruebas doradas: cada archivo real anonimizado tiene su salida revisada al lado |
| `conftest.py` | Configuración compartida de pytest |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev pytest

pytest tests/test_golden.py                    # en CI y antes de cada cambio
pytest tests/test_golden.py --update-golden    # solo cuando un cambio es intencional
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
