# lg03 — Documentos firmados

Código de la sección [`op003-lg03-documentos-firmados.md`](../../op003-lg03-documentos-firmados.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `firmar.py` | Firma y verifica un XML (XMLDSig) y un PDF (PAdES) con un certificado de prueba |
| `firmar_pdf.py` | Firma el PDF del plan de tratamiento en un campo visible |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add cryptography signxml lxml pyhanko

python3 firmar.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
