# ⚖️ qa10 — Veredicto: qué vale la pena cuando eres uno

> Python para desarrolladores Java senior · **Carta** · Track `qa` — Calidad, pruebas y
> mantenimiento · sección 10 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las nueve anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió el oficio completo: el mapa de riesgo y el presupuesto
([`qa01`](op030-qa01-la-piramide-para-uno.md)), `pytest` a fondo ([`qa02`](op031-qa02-pytest-a-fondo.md)),
dobles y datos ([`qa03`](op032-qa03-dobles-y-datos.md)), integración contra el motor real
([`qa04`](op033-qa04-integracion-de-verdad.md)), propiedades y modelos
([`qa05`](op034-qa05-propiedades-y-modelos.md)), mutación ([`qa06`](op035-qa06-medir-la-suite.md)), carga
([`qa07`](op036-qa07-carga-y-rendimiento.md)), la cadena de calidad
([`qa08`](op037-qa08-la-cadena-de-calidad.md)) y las pruebas e2e
([`qa09`](op038-qa09-e2e-con-playwright.md)). Todo eso, junto, es más de lo que una persona sostiene.

La pregunta del cierre es la de la tesis del curso: **con un solo ingeniero durante tres años, ¿qué se
queda, qué se usa a veces y qué es ceremonia?** La respuesta no es una lista de buenas prácticas, sino una
tabla de costo contra lo que atrapa, y una forma barata de vigilar que la suite no se degrade.

---

## 🧠 2. El modelo

| Práctica | Qué atrapa | Costo de mantener | Veredicto para uno |
|---|---|---|---|
| `ruff` + `mypy` en `pre-commit` (`qa08`) | Lo evidente sin ejecutar: tipos, *imports*, patrones inseguros | Casi cero, una vez encendido | **Siempre** |
| Unitarias + propiedades del dominio rojo (`qa01`, `qa05`) | Los errores de dinero y de reglas | Bajo: el dominio cambia poco | **Siempre**, solo en lo rojo |
| Pruebas doradas de formatos | Los cambios de las contrapartes | Bajo: un archivo por mes | **Siempre**, en cada formato ajeno |
| Integración con `testcontainers` (`qa04`) | Lo que solo existe en el motor | Medio: Docker en el CI | **Sí**, pocas |
| Una e2e por camino crítico (`qa09`) | El camino que el paciente usa | Medio: navegador y datos | **Sí**, tres o cuatro |
| `pip-audit` en el CI (`qa08`) | Vulnerabilidades publicadas | Casi cero | **Siempre** |
| Mutación en lo rojo (`qa06`) | Aserciones débiles | Alto en tiempo de máquina | **A veces**: cuando lo rojo cambia |
| Carga (`qa07`) | Capacidad antes de un cambio grande | Medio | **A veces**: antes de un cambio de arquitectura |
| Cobertura como meta | Nada que las demás no atrapen | Alto: pruebas para subir un número | **No** |
| e2e de cada pantalla | Cambios de diseño | Altísimo | **No** |

La última columna tiene tres valores y la tercera es la que más importa: decir **no** en voz alta, con su
razón, es lo que evita que una sesión futura —o un consultor de paso— vuelva a meter la ceremonia.

---

## 💻 3. El ejemplo que corre

Vigilar el presupuesto de tiempo no necesita un servicio. `pytest` escribe un reporte JUnit en XML con
`--junitxml`, y la biblioteca estándar lo lee. `presupuesto.py`:

```python
"""Lee el reporte JUnit de pytest y vigila el presupuesto: total, las más lentas y por archivo."""

import sys
import xml.etree.ElementTree as ET
from collections import defaultdict

BUDGET_SECONDS = 10.0            # la suite rápida de qa01


def summarize(path: str) -> int:
    root = ET.parse(path).getroot()
    cases = root.iter("testcase")
    rows = [(c.get("classname", ""), c.get("name", ""), float(c.get("time", 0))) for c in cases]
    total = sum(t for *_, t in rows)
    by_file: dict[str, float] = defaultdict(float)
    for classname, _, seconds in rows:
        by_file[classname.split(".")[0]] += seconds

    print(f"{len(rows)} pruebas en {total:.2f} s (presupuesto {BUDGET_SECONDS:.0f} s)")
    print("las tres más lentas:")
    for classname, name, seconds in sorted(rows, key=lambda r: r[2], reverse=True)[:3]:
        print(f"  {seconds:6.2f} s  {classname}::{name}")
    print("por archivo:", {k: round(v, 2) for k, v in sorted(by_file.items(), key=lambda kv: -kv[1])})
    return 0 if total <= BUDGET_SECONDS else 1


if __name__ == "__main__":
    sys.exit(summarize(sys.argv[1]))
```

```bash
pytest -q -m "not integration" --junitxml=reporte.xml
python3 presupuesto.py reporte.xml
```

Salida (Python 3.14.7, 05/10/2026), sobre la suite de `qa01`:

```text
4 pruebas en 0.05 s (presupuesto 10 s)
las tres más lentas:
    0.05 s  test_liquidacion::test_never_negative_and_never_above_rate
    0.00 s  test_liquidacion::test_known_cases[18420000-0-1105200]
    0.00 s  test_liquidacion::test_known_cases[18420000-420000-1080000]
por archivo: {'test_liquidacion': 0.05}
```

La prueba más lenta es la de propiedades, que genera cien ejemplos: es el costo esperado de Hypothesis, y
el número dice que la suite entera cabe doscientas veces en el presupuesto. Cuando no quepa, el reporte dice dónde
está el tiempo antes de que alguien proponga "apagar las pruebas lentas".

**Detalles con intención**

- **JUnit XML** es el formato que lee cualquier CI; el mismo archivo sirve para el resumen y para el
  panel del CI.
- **El script devuelve 1 si se pasa del presupuesto**: en el CI, la suite rápida que se volvió lenta es un
  fallo, no un aviso.
- **Sin dependencias**: un script que vigila la suite no debería ser otra cosa que mantener.

---

## ⚠️ 4. Lo que se rompe

**Agregar herramientas sin quitar ninguna.** Cada sección del track propone algo útil, y todas juntas son
más de lo que una persona mantiene. La tabla de §2 tiene filas de "no" a propósito; si en un año todas
dicen "sí", alguien dejó de decidir.

**El presupuesto que se renegocia en silencio.** Subir el límite de diez segundos a veinte "porque ya no
cabe" es lo que lleva a la suite de diez minutos que nadie corre. Se mueve lo lento de escalón, o se
acelera; el límite se cambia por escrito, con su razón.

**Las pruebas que nadie entiende.** Una prueba que falla y nadie sabe qué protege se borra o se arregla
mal. El nombre y el comentario de cada prueba en lo rojo dicen qué regla de negocio defienden.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Con un equipo.** Con tres ingenieros y alguien de QA, las filas de "a veces" pasan a "siempre" y algunas
de "no" a "sí": el costo de mantener se reparte.

**En un sistema con obligaciones regulatorias de prueba.** Si un auditor exige evidencia de cobertura o de
pruebas por requisito, se produce esa evidencia aunque la tabla diga que no vale; el costo lo pone la
regulación, no el criterio técnico.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Corre `presupuesto.py` sobre la suite de un proyecto tuyo. **Criterio:** el total, las tres más lentas y
   si cabe en diez segundos.
2. Llena la tabla de §2 para tu proyecto con tus propios veredictos. **Criterio:** al menos dos filas de
   "no" con su razón.

**🟡 Intermedio (3–4)**

3. Haz que `presupuesto.py` guarde el total de cada corrida en un CSV y avise cuando crezca más de un 25%
   en una semana. **Criterio:** una corrida con una prueba lenta agregada dispara el aviso.
4. Agrega al resumen la cuenta de pruebas por marca leyendo las propiedades del reporte (`-o
   junit_family=xunit2` y `record_property`). **Criterio:** el resumen dice cuántas pruebas `integration`
   hay.

**🟠 Difícil (5–6)**

5. Mide cuántas horas al mes te cuesta mantener la suite de un proyecto (pruebas que cambiaste sin que
   cambiara la regla). **Criterio:** el número, y qué fila de la tabla concentra el costo.
6. Aplica el veredicto a Cartera: escribe qué del track se adopta hoy, qué en seis meses y qué nunca.
   **Criterio:** una lista con fecha y condición para cada "en seis meses".

**🔴 Muy difícil (7–8)**

7. Escribe la página "cómo se prueba Cartera" para quien herede el sistema. **Criterio:** una página.
   *Rúbrica:* (a) qué se prueba, dónde y en cuánto tiempo; (b) qué no se prueba y por qué; (c) cómo se
   corre todo en una máquina nueva; (d) qué hacer cuando una prueba falla y no se entiende.
8. Diseña la medición que diría si la cadena de calidad se paga sola: defectos atrapados antes del commit
   contra horas invertidas. **Criterio:** una especificación con hipótesis, qué se cuenta y durante cuánto
   tiempo. *Rúbrica:* (a) define "defecto atrapado" sin ambigüedad; (b) cuenta el tiempo de mantener, no
   solo el de instalar; (c) dice qué resultado te haría apagar una herramienta; (d) declara qué no se puede
   medir.

---

## 📚 7. Referencias

- `pytest`, reportes JUnit XML: https://docs.pytest.org/en/stable/how-to/output.html#creating-junitxml-format-files
- `xml.etree.ElementTree`: https://docs.python.org/3/library/xml.etree.elementtree.html

Las del resto del track, en cada sección.

---

## 🚀 8. Cierre

Para un equipo de uno, la calidad es una tabla con tres columnas de veredicto —siempre, a veces, no— y una
suite rápida vigilada por un script de treinta líneas. Lo que se queda es barato de mantener y atrapa lo que
cuesta dinero; lo demás se usa cuando hace falta o no se usa, y se dice por qué.

**La señal de que quedó bien:** *"La suite rápida tarda cuatro segundos hace un año, y cuando alguien propuso
medir la cobertura de las pantallas, la tabla ya decía que no y por qué."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-qa-fase-10 -m "op qa10 cerrada: el veredicto del track y la vigilancia del presupuesto"
> ```
>
> Los commits llevan su prefijo (`op qa10: …`) y los de ejercicio su número
> (`op qa10 ej07: …`).
