# lg05 — Salud: HL7 v2 y FHIR

Código de la sección [`op005-lg05-hl7-y-fhir.md`](../../op005-lg05-hl7-y-fhir.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `radiologia.py` | Lee el aviso de estudio listo en HL7 v2 y lo convierte en un DiagnosticReport de FHIR |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add hl7 fhir.resources

python3 radiologia.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
