# `ds04` · Proyecto · Embudo

Código de la sección [`ds04-embudo.md`](../../ds04-embudo.md).

| Archivo | Qué es |
|---|---|
| `attribution.py` | Los cuatro modelos de reparto, la madurez y el costo por adquisición |
| `funnel.py` | Tasas por etapa, cohortes y el índice de estacionalidad |
| `partners.py` | La red de aliados: comisión contra pacientes que se quedaron |
| `bench_attribution.py` | La medición de la sección 6, con su intervalo bootstrap |
| `test_embudo.py` | 23 pruebas **sin dependencias**: `pytest test_embudo.py` |

Cero dependencias. Es deliberado y la tabla de `ds03` es la justificación: a la escala de
Áurea, la biblioteca estándar gana de punta a punta y este informe corre una vez al mes.

## Los datos

```bash
python ../ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py --salida data
python bench_attribution.py --datos data --corte 2026-03-31     # ~13 s
```

Los trece segundos son casi todos bootstrap: 200 remuestreos × 4 modelos × 3 canales, cada
uno recalculando el crédito de 5.451 pacientes. El ejercicio 10 pide bajarlo.

## Las tres decisiones que este código toma y que no son de ingeniería

1. **Qué modelo de atribución se reporta.** Los cuatro están implementados porque **ninguno
   es el correcto**; la herramienta obliga a nombrar el elegido en la salida. La sección 6
   recomienda el lineal como cifra principal y publicar las dos esquinas al lado.
2. **Hasta dónde llega la ventana.** `MATURITY = 96 días`, el rezago máximo del canal más
   lento. Los leads más recientes **no han fracasado: no han terminado**, y contarlos infla
   el costo de los canales lentos un 8,6%.
3. **Qué se hace con los canales sin gasto.** No salen en la tabla de costo. Un cero los
   habría puesto primeros y habría sugerido gastar todo el presupuesto ahí.

## ⚠️ Numerador y denominador, la misma ventana

```python
mature = mature_leads(created, cutoff)          # denominador: leads hasta corte − 96 días
spend = load_spend(data, until=cutoff - MATURITY)  # numerador: gasto hasta la misma fecha
```

La primera versión de este módulo filtraba solo el denominador, y entonces el filtro de
madurez **empeoraba** el costo de TikTok en vez de mejorarlo — exactamente al revés de lo que
decía el texto. Lo encontró la medición, no la lectura del código. Hay una prueba que lo fija
(`test_el_filtro_de_madurez_abarata_mas_al_canal_mas_lento`).

## Lo que fijan las pruebas

1. **Los cuatro modelos reparten exactamente un crédito por paciente**, y en total reparten
   5.451,0 créditos para 5.451 pacientes. Es la comprobación que ningún tablero de plataforma
   pasa.
2. **El ranking se invierte entre el primer y el último toque.** TikTok es el canal más
   barato con uno y el más caro por un factor de cinco con el otro. La tesis de la sección,
   convertida en aserción.
3. **El aliado sin retornos no encabeza el ranking**: su costo por paciente retenido es
   infinito, no cero.
4. **La cohorte reciente convierte peor y es un espejismo** — si dejara de ser cierto, el
   filtro de madurez no tendría nada que corregir.

Los archivos generados no se versionan.
