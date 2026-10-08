# 🧪 c-sharp-for-java-devs-20261005-f6c7 · cómo correr estas pruebas

> **Curso:** c-sharp-for-java-devs · **Tanda:** — (revisión del curso cerrado contra `zz-instrucciones/`)
> · **Creado:** 2026-10-05
> **Propósito:** validar el curso contra `zz-instrucciones/` y migrar sus diagramas a Mermaid.
> **Vigencia:** el README se escribió el 2026-10-06, después de la sesión (`5c52573d`, 05/10, 15:00–15:08
> UTC), a partir de su transcripción. Los comandos de §4 son los que corrió, copiados en
> `comandos-revision.sh`.

---

## 1. 🎯 Qué se prueba y para qué

| Prueba | Para qué | Resultado en el curso |
|---|---|---|
| Verificador base con `--perfil=courses-ia` y `--perfil=publicacion` antes de tocar nada | el punto de partida de la revisión | `salidas/antes.log`, `salidas/publicacion.log` |
| `buscar_diagramas.py` | encontrar los bloques `text` con forma de diagrama (cajas, flechas, árboles) | dos diagramas de verdad: el árbol de la F24 §5.1 y las tres categorías de la F11 §5.2, pasados a Mermaid (decisión D-12 del alcance §13) |
| `mmdc` sobre los dos `.md` | ver que los dos Mermaid nuevos dibujan bien | `salidas/*.svg`, `f11.png`, `f24.png` |
| `prompts/verificar-corpus.py` del curso contra una copia con cuatro errores sembrados | probar que el verificador nuevo del curso los detecta | los cuatro detectados |
| Verificador del curso y perfiles base al cerrar | el estado final | `salidas/despues*.log`: 0 errores, 13 avisos |

## 2. 🛠️ Prerrequisitos

- Python 3 (biblioteca estándar) para `buscar_diagramas.py` y los verificadores.
- `zz-instrucciones/herramientas/verificador_base.py` y, en el curso, `prompts/verificar-corpus.py` con su
  copia de `verificador_base.py`.
- **mermaid-cli 12.0.0** (`mmdc`) instalado en la máquina, para dibujar. Sin él, la alternativa con
  Docker es `zz-instrucciones/herramientas/exportar-diagramas.py --motor docker`.

## 3. 🧭 Reglas antes de correr

- Todo es de solo lectura **salvo** los `perl -pi` de `comandos-revision.sh`, que ya se aplicaron al
  curso: no se vuelven a correr.
- La siembra de errores se hace **siempre en `salidas/copia-sembrada/`**, nunca en el curso.
- No usa Docker (`mmdc` corrió en el host): no hace falta inventario.

## 4. ▶️ Cómo se corre

Desde la raíz del repositorio:

```bash
C=cursos-algoritmos-lenguajes/c-sharp-for-java-devs
Z=zz-code/c-sharp-for-java-devs-20261005-f6c7
mkdir -p $Z/salidas
python3 -B zz-instrucciones/herramientas/verificador_base.py $C --perfil=courses-ia > $Z/salidas/antes.log
python3 -B zz-instrucciones/herramientas/verificador_base.py $C --perfil=publicacion > $Z/salidas/publicacion.log
python3 $Z/buscar_diagramas.py $C | tee $Z/salidas/diagramas.log
```

`buscar_diagramas.py <carpeta>` recorre todos los `.md` y, por cada bloque sin lenguaje o en `text`,
`txt`, `plaintext`, `ascii` o `mermaid` con dos o más líneas de cajas o flechas, imprime
`archivo:línea lang=… lineas=… marcas=…`. No distingue un árbol de archivos de un diagrama: la lista se
revisa a mano.

Para dibujar un Mermaid (desde `salidas/`, con los `.mmd` que quedaron ahí):

```bash
mmdc -i f11.mmd -o f11.png -w 1400 -b white
mmdc -i f24.mmd -o f24.png -w 1400 -b white
```

La prueba del verificador con errores sembrados, desde la raíz del curso:

```bash
cd cursos-algoritmos-lenguajes/c-sharp-for-java-devs
Z=../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/copia-sembrada
rm -rf $Z && mkdir -p $Z && cp -R *.md prompts $Z/ && cd $Z
perl -CSD -Mutf8 -pi -e 's/^## 🧪 8\. Ejercicios \(25\)/## 🧪 8. Ejercicios (26)/' 01-tipos-valor-y-referencia.md
perl -CSD -Mutf8 -pi -e 's/^## 📏 6\. Medición/## 📏 6. Medida/' 05-async-await-y-cancelacion.md
printf '\n```text\n┌────┐\n│ a  │\n└────┘\n├─ b\n```\n' >> 02-nullable-y-pattern-matching.md
printf '\n> 💲 **x**\n' >> 03-linq-y-evaluacion-diferida.md
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|CALLOUT   [1B]"
```

Y el cierre, desde la raíz del curso:

```bash
python3 -B prompts/verificar-corpus.py | tee ../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/despues.log | tail -16
```

`comandos-revision.sh` trae los quince comandos de la sesión, en orden, incluidos los que editaron el
curso.

## 5. 📏 Cómo se mide

No aplica: es una revisión editorial; se cuentan errores y avisos, no tiempos.

## 6. 🧮 Los intermedios que amasan la salida

- Para resumir el verificador base se agruparon los avisos por tipo:
  `awk '{print $2}' salidas/antes.log | sort | uniq -c`.
- La prueba sembrada filtra el ruido conocido con `grep -v "EMOJI\|CALLOUT   [1B]"`.

## 7. ✅ Qué se espera ver

- Con los cuatro errores sembrados, el verificador del curso reporta los cuatro y termina en
  `— 1 errores, 15 avisos` (comprobado de nuevo el 06/10/2026 sobre la copia que quedó): un `ERROR
  EJERCICIOS` (F01 dice 26 y tiene 25), y avisos `SECCION` (F05 sin «6. Medición»), `DIAGRAMA` (el
  bloque de cajas de F02) y `CALLOUT` (el 💲 de F03). Salen además dos `DIAGRAMA` en F11 y F24, porque la
  copia se hizo antes de convertirlos a Mermaid.
- Al cierre, `salidas/despues.log` termina en `— 0 errores, 13 avisos` (05/10/2026): 9 `EMOJI` y 4
  `CALLOUT`, emojis de encabezado y callouts que el curso usa a propósito. Antes de la revisión
  (`antes.log`) eran 124 avisos, 27 de ellos `ENCAB`.

## 8. 📂 Salidas

- `antes.log`, `publicacion.log`: el verificador base antes de tocar nada.
- `diagramas.log`: los candidatos de `buscar_diagramas.py`.
- `11-migrar-el-runtime.md`, `24-veredicto-y-defensa.md`, sus `-1.svg` y sus `.mmdc.log`: la copia de las
  dos fases dibujada por `mmdc`; `f11.mmd`, `f24.mmd`, `f11.png`, `f24.png`: los dos diagramas sueltos.
- `x.png`: resto de una invocación fallida de `mmdc`; sin valor.
- `copia-sembrada/`: la copia con los cuatro errores.
- `despues.log`, `despues-courses-ia.log`, `despues-publicacion.log`: el cierre.

Todo se regenera con §4. Nada se copió al curso desde `salidas/`.

## 9. 🧹 Limpieza

`rm -rf salidas/copia-sembrada salidas/x.png`. No hay contenedores ni cambios en la máquina.

## 10. 🚫 Qué se dejó fuera

Nada: no hay dependencias ni binarios. La lógica de `buscar_diagramas.py` pasó, reducida, al aviso
`DIAGRAMA` de `prompts/verificar-corpus.py` del curso; este script queda como registro.
