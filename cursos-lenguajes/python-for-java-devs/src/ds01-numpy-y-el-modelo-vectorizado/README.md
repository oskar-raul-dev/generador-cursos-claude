# `ds01` · NumPy y el modelo vectorizado

Código de la sección [`ds01-numpy-y-el-modelo-vectorizado.md`](../../ds01-numpy-y-el-modelo-vectorizado.md).

> 📦 Este directorio guarda además la **maquinaria de datos** de todo el track: seis secciones
> —`ds01` a `ds06`— leen el mismo conjunto del Embudo, y por eso el generador se escribió antes que
> cualquier capítulo. Si una sección necesita una columna nueva, se agrega aquí y se vuelve a correr
> la suite; no se inventa en el texto.

| Archivo | Qué es |
|---|---|
| `generar_embudo.py` | El conjunto del Embudo: pauta, toques, leads, etapas, planes, cuotas y aliados |
| `acquisition.py` | El costo por paciente adquirido, en **tres versiones** que dan lo mismo |
| `bench_vectorized.py` | La medición de la sección 6: cuatro variantes por cinco tamaños |
| `ejercicio_16_lento.py` | El diagnóstico del ejercicio 16. Dos defectos sembrados, sin pistas |
| `test_generar_embudo.py` · `test_acquisition.py` | 40 pruebas: `pytest` |

## Antes de correr las mediciones

```bash
cp ../02-secuencias-perezosas/bench.py .      # el arnés del curso, el mismo de la Fase 02
uv run --with numpy==2.5.3 python bench_vectorized.py --filas 1000 100000 5000000
```

El arnés no se copia por comodidad: es **el mismo archivo** de la Fase 02, sin una línea
cambiada, porque los números de este track tienen que poder ponerse en la misma tabla que los del
camino base. Lo único que agrega `bench_vectorized.py` es el formato con tres decimales de
milisegundo — a mil filas, la tabla del arnés sería una columna de ceros.

## Los datos

```bash
python generar_embudo.py --salida data          # ~32.500 leads · 1 segundo
```

Ocho CSV y un `manifiesto.json`, con semilla fija y salida reproducible byte a byte. Solo
biblioteca estándar: a esta altura del curso `uv` ya existe, pero el generador no necesita nada y
pedir una dependencia para escribir CSV sería el reflejo que el Bloque A enseña a no tener.

| Archivo | Filas | Qué es |
|---|---|---|
| `pauta.csv` | ~49.000 | Gasto diario por campaña y sede. **Solo los tres canales pagos** |
| `leads.csv` | ~32.500 | Un contacto, con su primer y su último toque ya resueltos |
| `toques.csv` | ~62.700 | Cada punto de contacto, en orden. Es la materia de la atribución |
| `etapas.csv` | ~64.000 | El avance por el embudo, etapa por etapa y con su reloj |
| `planes_de_tratamiento.csv` | ~6.100 | Lo aceptado, con su valor entre 8 y 22 millones |
| `cuotas.csv` | ~81.300 | Veinticuatro cuotas por plan, con su fecha de pago o sin ella |
| `aliados.csv` · `remisiones.csv` | 23 · ~2.600 | La red de aliados y lo que trajo cada uno |

El período es **2024-01-01 a 2026-03-31**, que termina donde empieza el archivo de citas del
camino base (`src/02-secuencias-perezosas/generar_citas.py`).

## Las cuatro cosas que este conjunto tiene que sostener

Están en las pruebas, no en este README, y por eso las pruebas son parte del entregable:

1. **La atribución es ambigua.** El primer toque se sesga a TikTok e Instagram y el último a
   Google y al referido, así que las dos atribuciones **discrepan por construcción**. Es la tesis
   de `ds04`, y el generador no decide cuál tiene razón.
2. **La estacionalidad está y se mueve.** Ortodoncia en enero y febrero, estética en noviembre y
   diciembre, y el agujero de Semana Santa —que cae en fecha distinta cada año y por eso se
   **calcula**, en vez de copiarse de una tabla de tres fechas que nadie va a volver a revisar—.
3. **El dinero llega en cuotas.** Aceptar un plan no es cobrarlo: quien sume el valor por mes de
   aceptación y lo llame "ventas del mes" tiene una cifra que no significa lo que parece.
4. **Los aliados se distinguen entre sí.** Si todos rindieran igual, la pregunta de Marcela sobre
   cuánto vale la red no tendría respuesta posible y `ds04` se quedaría sin sección.

## ⚠️ El factor de escala produce filas que Áurea no tiene

```bash
python generar_embudo.py --salida data --escala 60     # millones de filas, sintéticas
```

La medición de `ds01` necesita un tamaño grande para encontrar el umbral donde el bucle deja de
servir, y Áurea no lo tiene: hace 3.900 citas al mes. El generador escala **y lo declara** —
`manifiesto.json` guarda `"sintetico": true`—, y la sección que use esos números tiene que decir
que ese tercer tamaño no es el negocio. Inflar la ficción hasta que cuadre el benchmark sería
mentir sobre la empresa para ganar una fila de tabla.

Los archivos generados no se versionan.
