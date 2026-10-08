# 🔒 Contrato del CLI de Patricia
## Python para desarrolladores Java senior · material de autoría

> **Para qué existe este documento.** El curso se escribe **fuera del orden numérico**: las Fases
> 07 y 09 se redactan antes que las 02–06, porque son las que más pueden obligar a reescribir el
> Bloque A. Eso crea un problema concreto: la Fase 07 refactoriza un CLI cuyo estado final
> todavía no se ha escrito. Este documento **congela ese estado fase por fase** para que la 07
> refactorice contra algo real y las fases del Bloque A lo cumplan al escribirse.
>
> **Manda sobre el redactor, no sobre el lector.** No se enlaza desde ninguna fase.

**Precedencia:** pierde contra `alcance-del-proyecto.md` y `propuesta-fases-y-alcance.md`. Si al
escribir una fase el contrato estorba, se cambia **aquí primero** y se anota qué fases quedan
afectadas.

---

## 1. El proyecto 1, en una línea

`aur` — la caja de herramientas de Patricia. Nace como un archivo suelto en la Fase 01, se
vuelve paquete en la **Fase 07**, se distribuye en la 09, y en la 15 lo importa el proceso
nocturno como biblioteca.

> 🪦 **Contradicción resuelta.** `00-historia-de-aurea.md` §6 decía que `aur` "solo se
> convierte en paquete en la Fase 08", contra la numeración oficial de
> `propuesta-fases-y-alcance.md` §4 y §7. Ganó la numeración oficial y **la historia ya quedó
> corregida a Fase 07** (dos líneas, §6). No queda nada que conciliar.

---

## 2. Nombres congelados

Estos identificadores ya están escritos en material publicado y **no se renombran**:

| Qué | Nombre | Dónde quedó fijado |
|---|---|---|
| Archivo del Bloque A | `aur_cli.py`, en la raíz del repositorio | Fase 00 (`launch.json`) y Fase 01 |
| Paquete del Bloque B en adelante | `src/aur/`, ejecutable `aur` | Fase 07 |
| Directorio de datos | `data/`, ignorado por git | Fase 00 (`.gitignore`) |
| Generador de datos | `generar_datos_f01.py`, semilla `2026` | Fase 01 |
| Archivos generados | `data/<sede>-2026-03.csv` | Fase 01 |
| Constantes de columna | `DOCUMENT, PATIENT, BRANCH, DATE, CODE, AMOUNT` | Fase 01 |
| Funciones del Bloque A | `read_rows`, `summarize`, `render` | Fase 01 |

Vocabulario del dominio: el de `guia-de-estilo-y-convenciones.md` §5.1, sin inventar términos.
`plan` a secas sigue prohibido.

---

## 3. El formato del export de Odontovía

Seis columnas en la Fase 01, y **una séptima a partir de la Fase 06**:

```text
documento,paciente,sede,fecha,codigo,valor
1019283746,Ana María Robledo,Centro,2026-03-04,D8010,180000
```

Desde la Fase 06, el generador agrega `descripcion` — texto libre **con comas y comillas
adentro**, que es lo que hace visible la factura de la deuda 💸:

```text
documento,paciente,sede,fecha,codigo,descripcion,valor
52847193,Carlos Efrén Neira,Centro,2026-03-04,D2740,"Corona en zirconio, cara vestibular",890000
```

La suciedad del dominio, repartida por fases:

- **Fase 01:** documentos con puntos, con espacio al final, nombres con y sin tildes, en
  mayúsculas. Más dos casos sembrados que ninguna normalización resuelve (§5).
- **Fase 05:** rutas de Windows, y el binario firmador simulado.
- **Fase 06:** el export `latin-1` de Odontovía, el BOM de Excel, y la coma dentro de celda.

---

## 4. El CLI, fase por fase

Cada fila dice **qué gana el archivo** y qué reflejo paga esa ganancia. Ninguna fase reescribe lo
anterior desde cero: se agrega.

| Fase | Qué gana `aur_cli.py` | Forma de invocación |
|---|---|---|
| **01** | Nace. `read_rows` con `open` + `split(",")` 💸, `summarize` con `Decimal` y `set`, `render`. Filas como tuplas. `sys.argv` a mano, `sys.exit(2)` para el mal uso | `python aur_cli.py resumen <archivo>` |
| **02** | `read_rows` pasa a ser **generador**. Nace `bench.py` (el arnés) como archivo aparte, y el generador de datos crece al archivo de citas del trimestre | igual |
| **03** | La fila pasa de tupla a **`dataclass`**. Los validadores se declaran con `Protocol`; los comandos se registran con un **decorador** en vez de un `if/elif` que ya no cabe. Nace el **motor de comisiones** (`referral_fee`) | igual |
| **04** | Errores del dominio propios, **context managers** para lo que se abre, y `ExceptionGroup` para acumular todos los errores de validación de un lote en vez de morir en el primero | igual |
| **05** | **`argparse`** reemplaza a `sys.argv`. `pathlib` en todas las rutas. `subprocess` para invocar el binario firmador. Señales para que `Ctrl-C` no deje un archivo a medias | `python aur_cli.py resumen --sede centro --mes 2026-03` |
| **06** | **Se paga la deuda 💸:** `csv` reemplaza a `split(",")`. Entran `json` (RIPS), `tomllib` (tarifas), `sqlite3` (histórico) y `zipfile` (el lote). Cierra el Bloque A | + `rips`, `historico` |
| **07** ⭐ | **Migra a paquete**, archivo por archivo: `src/aur/` con `cli.py`, `reading.py`, `summary.py`, `fees.py`, `storage.py`; `pyproject.toml`, entry point `aur`, gestor `uv` | `aur resumen --sede centro` |
| **08** | Tipado estricto verificado y `pytest`. El motor de comisiones de la 03 queda blindado, con una prueba basada en propiedades sobre el invariante de reparto | `aur …`, más `pytest` |
| **09** ⭐ | Se distribuye: Patricia lo instala sin clonar nada. Cierra el arco del proyecto 1 | según la opción elegida |
| **09** | *(decisión tomada al escribir la fase)* El `if __name__ == "__main__":` de `cli.py` **se queda**: el `.pyz` y el ejecutable congelado lo necesitan. Ninguna fase posterior lo borra por limpieza | |
| **15** | El proceso nocturno **importa `aur` como biblioteca**: `from aur.summary import summarize`. La misma validación, desatendida, sobre las diez sedes | `python -m cartera.cierre` |

> 🧭 **Regla para el redactor de la Fase 07:** el refactor se muestra como una secuencia de
> movimientos sobre el archivo que ya existe, no como un proyecto nuevo. Si la fase termina con
> código que el lector no reconoce de las seis fases anteriores, contradice su propia lección.

---

## 5. Los dos casos sembrados en los datos

El generador de la Fase 01 los planta **deterministamente**, en sedes concretas, y son la trampa
del miniproyecto de esa fase. Verificados al escribirla: aparecen exactamente una vez cada uno y
no hay homónimos accidentales que los ahoguen.

- **Mismo documento, dos personas.** `people[7]` aparece en Centro con su nombre y en Kennedy
  como *Gloria Esperanza Mahecha Vargas*.
- **Misma persona, dos documentos.** `people[11]` aparece en Chapinero con su documento correcto
  y en Suba con dos dígitos invertidos.

Ninguna fase posterior debe "limpiar" estos casos: son el dominio. La Fase 11 los vuelve a
encontrar al modelar la identidad del paciente a través de la red.

---

## 6. La deuda 💸, y su factura

Una sola deuda en el Bloque A, y es la que enseña a leer el mecanismo:

- **Se contrae en la Fase 01**, declarada en el docstring de `read_rows` con su fase de pago.
- **Se paga en la Fase 06**, y la fase lo muestra como factura literal:
  `git diff fase-01 fase-06 -- aur_cli.py`.
- **Para que la factura se vea**, el generador tiene que emitir desde la Fase 06 la columna
  `descripcion` con comas adentro (§3). Sin ese dato, el pago de la deuda es un cambio cosmético.

Si al escribir el Bloque A aparece la tentación de una segunda deuda, se declara aquí antes de
escribirla, con su fase de pago.

---

## 7. Lo que el CLI **nunca** hace

Para que no se lo coman las fases del Bloque C, que tienen sus propios proyectos:

- **No tiene servidor HTTP.** Eso es AgendaAPI, Fase 10.
- **No habla con Postgres.** Su almacén es `sqlite3`, local, desde la Fase 06. Postgres es Fase 11.
- **No tiene interfaz gráfica ni web.** El back-office es Fase 12.
- **No programa su propia ejecución.** El scheduling es Fase 15, y ahí el CLI es la biblioteca,
  no el programador.
- **Y los miniproyectos no lo tocan** (`formato-de-miniproyectos.md` §5). Pueden leer su salida o
  medir contra él; modificarlo, no.
