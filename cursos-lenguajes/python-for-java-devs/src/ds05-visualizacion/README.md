# `ds05` · Visualización, y cuándo una tabla gana

Código de la sección [`ds05-visualizacion.md`](../../ds05-visualizacion.md).

| Archivo | Qué es |
|---|---|
| `dashboard.py` | El mismo tablero en cuatro versiones: tabla, matplotlib, plotly y altair |
| `palette.py` | La paleta de Áurea, su contraste y qué queda de ella impresa |
| `bench_render.py` | La medición de la sección 6.1, una opción por entorno |
| `test_dashboard.py` | 15 pruebas: `pytest test_dashboard.py` |

## Correr las cosas

```bash
python dashboard.py                                   # la tabla, sin dependencias
uv run --with matplotlib==3.11.2 python bench_render.py --opcion matplotlib
uv run --with plotly==7.0.0     python bench_render.py --opcion plotly
uv run --with altair==6.2.2     python bench_render.py --opcion altair
uv run python bench_render.py --opcion tabla
```

**Cada opción se mide en un entorno donde solo está instalada su dependencia**, por lo que
descubrió `ds03`: una biblioteca puede importar otra si la encuentra, y entonces la tabla le
cobra a una el arranque de la otra.

## Las pruebas de la paleta no necesitan ninguna biblioteca de gráficos

El contraste es aritmética: luminancia relativa y un cociente. Por eso `palette.py` no
importa nada y sus pruebas corren en cualquier máquina, incluida una de CI sin con qué
dibujar. Las tres pruebas de renderizado se saltan solas con `importorskip`.

## Los dos hallazgos que este código deja fijados

1. **El dorado de la marca no pasa el contraste para texto** —3,25 contra el 4,5 de la
   norma— **y sí para una barra** (3:1). No se prohíbe el color: se le asigna el papel donde
   funciona, y eso termina la discusión con un número en vez de con un gusto.
2. **La paleta completa no sobrevive a una impresión en blanco y negro.** Teja `#A34E2A` y
   pizarra `#4A6670` son dos colores obviamente distintos en pantalla y el mismo gris en el
   papel: `#666666` y `#626262`, con 1,04 de contraste entre sí.

## ⚠️ Dos trampas de API que el código evita a propósito

- **`matplotlib.use("Agg")` antes de importar `pyplot`.** Sin eso, falla en cualquier máquina
  sin pantalla —todas las que corren tareas programadas— con un error que no menciona la
  palabra "pantalla".
- **`xerr` son distancias al punto, no los extremos.** Pasarle los extremos produce un
  gráfico que se dibuja sin quejarse y está mal.

Los archivos generados no se versionan.
