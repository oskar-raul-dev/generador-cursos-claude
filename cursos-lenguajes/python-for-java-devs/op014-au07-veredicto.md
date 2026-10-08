# ⚖️ au07 — Veredicto: la automatización que se rompe sola

> Python para desarrolladores Java senior · **Carta** · Track `au` — Automatización externa ·
> sección 7 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las seis anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Todo el track automatiza sistemas **que no controlas**: una API ajena
([`au01`](op008-au01-http-contra-sistemas-ajenos.md)), una página que se rediseña
([`au02`](op009-au02-scraping.md)), un portal sin API ([`au03`](op010-au03-playwright.md)), equipos
remotos ([`au04`](op011-au04-ssh-y-sistemas-remotos.md)), un SaaS con permisos que se revocan
([`au05`](op012-au05-apis-de-saas.md)) y la máquina donde todo eso corre
([`au06`](op013-au06-desplegar-automatizaciones.md)). La tesis del track es que esa automatización
**se rompe sola**: no porque esté mal escrita, sino porque la otra parte cambia sin avisar.

La pregunta que cierra el track, entonces, no es "¿se puede automatizar?" —casi siempre se puede—
sino **"¿sigue valiendo la pena?"**. Un robot que ahorra cuatro horas a la semana y se rompe una vez
al mes, con dos horas de arreglo cada vez, es un buen negocio. Uno que ahorra una hora y se rompe
cada semana es una forma cara de hacer el trabajo a mano. La diferencia no se ve en el momento de
escribirlo: se ve en el registro de seis meses de corridas.

---

## 🧠 2. El modelo

La cuenta tiene cuatro números, y los cuatro salen de datos que la automatización ya produce si se
desplegó como en `au06`:

| Número | De dónde sale | Qué dice |
|---|---|---|
| **Horas ahorradas** | Lo que tardaba la persona, por corrida exitosa | El beneficio |
| **Tasa de rotura** | Corridas fallidas sobre corridas totales | Qué tan frágil es la otra parte |
| **Tiempo de arreglo** | Horas desde el aviso hasta que vuelve a funcionar | Qué tan frágil es tu código |
| **Costo de la rotura silenciosa** | Lo que pasó mientras nadie sabía que estaba roto | Lo que el latido de `au06` evita |

Y una clasificación de las automatizaciones del track según **quién controla el cambio**:

| Automatización | Quién cambia la interfaz | Frecuencia típica del cambio | Fragilidad |
|---|---|---|---|
| API documentada (`au01`, `au05`) | El proveedor, con versión y aviso | Años | Baja |
| SSH a equipos propios (`au04`) | Tú | Cuando tú decides | Baja |
| Scraping de una página (`au02`) | El proveedor, sin aviso | Meses | Media |
| Portal con navegador (`au03`) | El proveedor, sin aviso, y a veces contra ti | Semanas a meses | Alta |

El veredicto sale de cruzar las dos tablas: **una automatización frágil solo vale la pena si ahorra
mucho y se arregla rápido**, y para eso tiene que estar escrita para fallar en voz alta y para
cambiarse en un solo lugar —el `Page Object`, el selector anclado, la validación de forma—.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `cuenta_robots.py` lee el registro de corridas —una línea por corrida, que es
exactamente lo que deja el diario de `systemd` si se exporta— y hace la cuenta de cada
automatización.

```python
"""¿Siguen valiendo la pena los robots? La cuenta, desde el registro de corridas."""

import csv
import io
from collections import defaultdict
from dataclasses import dataclass

# Una línea por corrida: fecha, robot, ok (1/0) y horas que tomó arreglarlo si falló.
RUNS = """fecha,robot,ok,horas_arreglo
2026-07-06,radicacion,1,0
2026-07-13,radicacion,0,3.0
2026-07-20,radicacion,1,0
2026-07-27,radicacion,1,0
2026-08-03,radicacion,0,1.5
2026-08-10,radicacion,1,0
2026-08-17,radicacion,1,0
2026-08-24,radicacion,0,4.0
2026-07-06,circulares,1,0
2026-07-13,circulares,1,0
2026-07-20,circulares,1,0
2026-07-27,circulares,1,0
2026-08-03,circulares,0,0.5
2026-08-10,circulares,1,0
2026-08-17,circulares,1,0
2026-08-24,circulares,1,0
"""

# Lo que tardaba una persona en hacer el trabajo, por corrida (estimación de quien lo hacía).
MANUAL_HOURS = {"radicacion": 4.0, "circulares": 0.25}


@dataclass
class Verdict:
    robot: str
    runs: int
    failures: int
    saved: float
    fixing: float

    @property
    def net(self) -> float:
        return self.saved - self.fixing

    @property
    def failure_rate(self) -> float:
        return self.failures / self.runs


def tally(log: str) -> list[Verdict]:
    totals: dict[str, list[float]] = defaultdict(lambda: [0, 0, 0.0, 0.0])
    for row in csv.DictReader(io.StringIO(log)):
        t = totals[row["robot"]]
        t[0] += 1
        if row["ok"] == "1":
            t[2] += MANUAL_HOURS[row["robot"]]   # solo las corridas buenas ahorran
        else:
            t[1] += 1
            t[3] += float(row["horas_arreglo"])
    return [Verdict(robot, int(r), int(f), s, x) for robot, (r, f, s, x) in sorted(totals.items())]


if __name__ == "__main__":
    for v in tally(RUNS):
        print(f"{v.robot:11} corridas {v.runs:2}  fallas {v.failures} ({v.failure_rate:.0%})  "
              f"ahorro {v.saved:5.2f} h  arreglos {v.fixing:4.1f} h  neto {v.net:+6.2f} h")
```

```bash
python3 cuenta_robots.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
circulares  corridas  8  fallas 1 (12%)  ahorro  1.75 h  arreglos  0.5 h  neto  +1.25 h
radicacion  corridas  8  fallas 3 (38%)  ahorro 20.00 h  arreglos  8.5 h  neto +11.50 h
```

Los dos robots valen la pena, y por razones opuestas. El de circulares casi nunca se rompe y ahorra
poco: su valor no está en las horas sino en **enterarse** de la circular el mismo día, que la cuenta
de horas no captura. El de radicación se rompe en más de un tercio de las corridas y aun así deja
once horas y media en dos meses, porque cada corrida buena reemplaza media jornada de clics. Pero el
margen es más angosto de lo que parece: con la misma duración media de arreglo (2,8 horas), **cinco
fallas de ocho** ya dan un neto negativo (−2,2 horas), mientras que con tres fallas y arreglos del
doble de largos todavía quedan tres horas a favor. La tasa de rotura pesa más que el tiempo de
arreglo, y esa es la pregunta que hay que hacerse cada trimestre.

**Detalles con intención**

- **Solo las corridas buenas ahorran.** Una corrida fallida no ahorró nada y además costó el arreglo,
  y la persona tuvo que hacer el trabajo a mano esa semana.
- **Las horas manuales las estima quien hacía el trabajo**, no quien escribió el robot. El que
  automatiza siempre sobreestima lo que ahorró.
- **El registro es un CSV**, a propósito: lo produce cualquier automatización y lo abre cualquiera.

---

## ⚠️ 4. Lo que se rompe

**La rotura silenciosa no aparece en la cuenta.** Si el robot de circulares devolvió una lista vacía
durante un mes sin fallar, el registro dice "ok" cuatro veces y la cuenta lo celebra. Por eso las
validaciones de forma (`au02`) y el latido (`au06`) no son opcionales: sin ellos, los números de
esta sección mienten a favor del robot.

**El arreglo que nadie registra.** El tiempo de arreglo solo existe si alguien lo anota. Una línea en
el registro cuando se cierra el aviso —"arreglado, 1,5 horas, el portal cambió el botón"— es todo lo
que hace falta, y es lo primero que se deja de hacer.

**La persona que ya no sabe hacerlo a mano.** Después de un año de robot, el día que el portal cambia
y el arreglo tarda una semana, la persona que radicaba a mano ya no recuerda cómo. El procedimiento
manual se mantiene escrito, aunque nadie lo use.

---

## ⚖️ 5. Cuándo NO automatizar

**Cuando la frecuencia es baja y el proceso cambia seguido.** Una tarea trimestral sobre un portal
que se rediseña cada seis meses va a encontrar el robot roto casi todas las veces que lo necesite.

**Cuando el error del robot es caro y difícil de ver.** Radicar dos veces la misma factura, o no
radicarla creyendo que sí, cuesta más que la media jornada ahorrada. Si el robot no puede verificar
su propio resultado (el número de radicado de `au03`), no se le deja solo.

**Cuando hay una alternativa de fondo.** La mejor automatización de un portal sin API es convencer a
la aseguradora de que exponga una. Una carta formal de la red de diez sedes pidiendo una interfaz de
radicación, con el número de facturas al mes, a veces funciona; el robot sigue siendo el plan B.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega al registro el robot de respaldos de `au04` con ocho corridas buenas y quince minutos de
   trabajo manual por corrida. **Criterio:** la cuenta lo muestra con su neto.
2. Cambia `MANUAL_HOURS["radicacion"]` a 1,5. **Criterio:** dices en una línea si el robot sigue
   valiendo la pena y desde qué valor deja de valerla con estos arreglos.

**🟡 Intermedio (3–4)**

3. Exporta el diario de `systemd` de un servicio a este formato con
   `journalctl -u <servicio> -o json`. **Criterio:** un script que produce las líneas `fecha,robot,ok`
   a partir del diario real de una semana.
4. Agrega a la cuenta el tiempo medio de arreglo y la racha más larga sin fallas. **Criterio:** la
   salida tiene dos columnas más y las cifras cuadran a mano.

**🟠 Difícil (5–6)**

5. Agrega la columna de **rotura silenciosa**: corridas "ok" que produjeron un resultado vacío o
   sospechoso. **Criterio:** con dos corridas vacías en el registro, el neto del robot de circulares
   baja y explicas cuánto.
6. Escribe el informe trimestral de robots en una página que Julián entienda. **Criterio:** una
   tabla, una recomendación por robot ("mantener", "reescribir", "apagar") y su razón en una línea.

**🔴 Muy difícil (7–8)**

7. Diseña el criterio de apagado: con qué números se apaga un robot y se vuelve al trabajo manual.
   **Criterio:** una regla escrita, aplicada a tres historiales fabricados. *Rúbrica:* (a) usa al
   menos tres de los cuatro números del modelo; (b) incluye una ventana de tiempo, no una corrida
   suelta; (c) dice quién decide y cómo se le avisa a la persona que vuelve a hacerlo a mano; (d)
   explica por qué un robot apagado se documenta en vez de borrarse.
8. Redacta la carta a una aseguradora pidiendo una interfaz de radicación, con los números de Áurea.
   **Criterio:** una página con el volumen, el costo actual para las dos partes y una propuesta
   concreta. *Rúbrica:* (a) muestra el beneficio para la aseguradora, no solo para Áurea; (b) pide
   algo pequeño y concreto, no "una API"; (c) ofrece un plan de prueba; (d) no revela nada de los
   robots ni de su fragilidad.

---

## 📚 7. Referencias

- `journalctl` y la salida en JSON: https://man7.org/linux/man-pages/man1/journalctl.1.html
- `csv` de la biblioteca estándar: https://docs.python.org/3/library/csv.html

**Orden de lectura sugerido:** la página de `journalctl` para el formato de exportación, si vas a
alimentar la cuenta con el diario real; el resto del track ya tiene sus referencias en cada sección.

---

## 🚀 8. Cierre

Automatizar lo ajeno es aceptar que se va a romper y escribirlo para que la rotura sea **visible,
barata y localizada**. Lo que decide si vale la pena no es la elegancia del robot sino cuatro números
que salen del registro de corridas, y la disciplina de mirarlos cada trimestre.

**La señal de que quedó bien:** *"Apagamos el robot de un portal que cambiaba cada mes, y lo
decidimos con la cuenta en la mano, no por cansancio."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-au-fase-07 -m "op au07 cerrada: la cuenta de los robots y el criterio de apagado"
> ```
>
> Los commits llevan su prefijo (`op au07: …`) y los de ejercicio su número
> (`op au07 ej07: …`).
