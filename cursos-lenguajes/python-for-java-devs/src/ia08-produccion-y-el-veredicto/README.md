# `ia08` · Producción, y el veredicto del track 🏁

Código de la sección [`ia08-produccion-y-el-veredicto.md`](../../ia08-produccion-y-el-veredicto.md).

| Archivo | Qué es |
|---|---|
| `caching.py` | Las tres colocaciones de la caché, incluida la rota a propósito, y el costo con sus multiplicadores |
| `audit_prefix.py` | **La función que encuentra al invalidador** cuando la caché deja de acertar |
| `budget.py` | Presupuesto por clave y por día, en `Decimal`, que corta antes de gastar |
| `telemetry.py` | Qué se registra y qué no. Una sola puerta, para que la frontera sea auditable |
| `bench_caching.py` | La medición 6.1 sobre el tráfico de un día |
| `test_produccion.py` | **20 pruebas sin red y sin modelo** |

## Correr las pruebas

```bash
pytest test_produccion.py -q      # 20 pruebas, milisegundos, sin gastar un peso
```

Las tres cosas que fijan:

- **Los cuatro invalidadores silenciosos de la caché** —reloj, identificador, JSON sin ordenar,
  orden de las herramientas— cada uno con su prueba. Y el caso benigno, cuando un prefijo es
  continuación del otro, distinguido del divergente: confundirlos manda a alguien a buscar un bug
  que no existe.
- **Que el presupuesto comprueba antes de gastar**, no después. Comprobar después informa;
  comprobar antes protege.
- **Que el texto del paciente no llega al registro.** `test_the_patient_text_never_reaches_the_log`
  serializa un evento real y comprueba que el mensaje no está. El borrador **bloqueado** sí se
  guarda, y hay una prueba que lo fija: es texto del modelo, no del paciente, y es la materia prima
  para mejorar el prompt.

## Por qué el dinero es `Decimal`

Diez mil peticiones de tres milésimas de dólar suman exactamente `30.000` en `Decimal` y
`30.000000000001023` en `float`. Con el criterio 2 del miniproyecto —cuadrar con la factura del
proveedor dentro del 5%— la diferencia todavía no muerde; con el volumen de un año, sí. Y sobre
todo: un número que no cuadra exactamente es un número que hay que explicar.

## Lo que falta

`trafico_un_dia.jsonl`: el tráfico reconstruido de los dos proyectos con sus marcas de tiempo. **La
distribución horaria es el experimento**, no un detalle — quince consultas repartidas en ocho horas
y 900 mensajes en dos picos no miden lo mismo, y correr las peticiones seguidas favorece a la caché
y falsea la tabla.
