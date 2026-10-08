# qa05 — Propiedades y modelos con Hypothesis

Código de la sección [`op034-qa05-propiedades-y-modelos.md`](../../op034-qa05-propiedades-y-modelos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `agenda.py` | La agenda de un odontólogo: reservar, cancelar y reagendar espacios. Tiene un error sembrado |
| `test_agenda_estado.py` | La agenda contra un modelo ingenuo, con secuencias que genera Hypothesis |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add --dev pytest hypothesis

pytest -q test_agenda_estado.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
