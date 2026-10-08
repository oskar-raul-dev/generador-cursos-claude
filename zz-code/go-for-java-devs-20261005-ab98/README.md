# 🧪 go-for-java-devs-20261005-ab98 · cómo correr estas pruebas

> **Curso:** go-for-java-devs · **Tanda:** — (revisión del curso cerrado contra `zz-instrucciones/`)
> · **Creado:** 2026-10-05
> **Propósito:** validar el curso contra `zz-instrucciones/` y migrar sus diagramas a Mermaid.
> **Vigencia:** el README se escribió el 2026-10-06, después de la sesión (`5c52573d`, 05/10, 15:13–15:28
> UTC), a partir de su transcripción. Los comandos de §4 son los que corrió, copiados en
> `comandos-revision.sh`.

---

## 1. 🎯 Qué se prueba y para qué

| Prueba | Para qué | Resultado en el curso |
|---|---|---|
| Verificador base con `--perfil=courses-ia` y `--perfil=publicacion` antes de tocar nada | el punto de partida | `salidas/antes.log` (236 avisos), `salidas/publicacion.log` |
| `buscar_diagramas.py` y el volcado de candidatos | encontrar los bloques `text` con forma de diagrama y leerlos con su contexto | 26 candidatos (`diagramas.log`, `candidatos.txt`); siete eran diagramas de verdad |
| `migrar_diagramas.py` | reemplazar esos siete bloques por Mermaid (decisión D-12) | F01, F12 ×2 (uno como `sequenceDiagram`), F13 ×2, F16 y F17, ya aplicados |
| Dibujo con `mmdc` | ver que los siete dibujan bien | `salidas/d1-01.png` … `d7-17.png` |
| `prompts/verificar-corpus.py` del curso contra una copia con cuatro errores sembrados | probar el verificador nuevo del curso | los cuatro detectados |
| Verificador del curso al cerrar | el estado final | `salidas/despues.log`: 0 errores, 29 avisos |

## 2. 🛠️ Prerrequisitos

- Python 3 (biblioteca estándar).
- `zz-instrucciones/herramientas/verificador_base.py` y, en el curso, `prompts/verificar-corpus.py` con su
  copia de `verificador_base.py`.
- **mermaid-cli 12.0.0** (`mmdc`) para dibujar; sin él, `zz-instrucciones/herramientas/exportar-diagramas.py
  --motor docker`.

## 3. 🧭 Reglas antes de correr

- **`migrar_diagramas.py` ya se aplicó y no se vuelve a correr contra el curso**: sus bloques `text` ya no
  existen, así que hoy fallaría en la primera aserción (`assert len(hallados) == 1`), sin tocar nada. Si
  se quiere repetir, se corre sobre una copia del curso anterior al 05/10 (el commit previo en git).
- La siembra de errores se hace **siempre en `salidas/copia-sembrada/`**.
- No usa Docker: no hace falta inventario.

## 4. ▶️ Cómo se corre

Desde la raíz del repositorio:

```bash
G=cursos-algoritmos-lenguajes/go-for-java-devs
Z=zz-code/go-for-java-devs-20261005-ab98
mkdir -p $Z/salidas
python3 -B zz-instrucciones/herramientas/verificador_base.py $G --perfil=courses-ia > $Z/salidas/antes.log 2>&1
python3 -B zz-instrucciones/herramientas/verificador_base.py $G --perfil=publicacion > $Z/salidas/publicacion.log 2>&1
python3 $Z/buscar_diagramas.py $G > $Z/salidas/diagramas.log
```

- `buscar_diagramas.py <carpeta>` es copia idéntica del de `../c-sharp-for-java-devs-20261005-f6c7/`: por
  cada bloque sin lenguaje o en `text` con dos o más líneas de cajas o flechas imprime
  `archivo:línea lang=… lineas=… marcas=…`.
- El volcado `candidatos.txt` lo hizo un `python3 - <<'EOF'` que, por cada línea de `diagramas.log`,
  imprime el bloque completo con la línea de contexto anterior (está literal en `comandos-revision.sh`,
  «Dump all diagram candidates to a file»).
- `migrar_diagramas.py <carpeta-del-curso>` tiene en `CAMBIOS` los siete pares (archivo, primera línea
  del bloque `text`, bloque Mermaid nuevo). Primero comprueba que cada bloque aparece exactamente una
  vez y arma los textos nuevos en memoria; solo si los siete pasan escribe los archivos, así que una
  aserción fallida no deja el curso a medias.

La prueba del verificador con errores sembrados, desde la raíz del curso:

```bash
cd cursos-algoritmos-lenguajes/go-for-java-devs
Z=../../zz-code/go-for-java-devs-20261005-ab98/salidas/copia-sembrada
rm -rf $Z && mkdir -p $Z && cp -R *.md prompts $Z/ && cd $Z
perl -CSD -Mutf8 -pi -e 's/^## 🧪 8\. Ejercicios \(24\)/## 🧪 8. Ejercicios (25)/' 01-sintaxis-y-valores.md
perl -CSD -Mutf8 -pi -e 's/^## 🛠️ 5\. CLI de la fase/## 🛠️ 5. Línea de comandos/' 03-errores-paquetes-io.md
perl -CSD -Mutf8 -pi -e 's/^\*\*D3\b/**X3/' 05-http-rest-stdlib.md
printf '\n```text\n┌────┐\n│ a  │\n└────┘\n```\n' >> 07-context-y-ciclo-de-vida.md
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|CALLOUT\|ENCAB"
```

El cierre: `python3 -B prompts/verificar-corpus.py > ../../zz-code/go-for-java-devs-20261005-ab98/salidas/despues.log`
desde la raíz del curso. El dibujo de los siete Mermaid lo hizo otro `python3 - <<'EOF'` que extrae los
bloques de F01, F12, F13, F16 y F17 a `salidas/dN-FF.mmd` y llama a `mmdc` («Render go Mermaid diagrams
to PNG» en `comandos-revision.sh`).

## 5. 📏 Cómo se mide

No aplica: es una revisión editorial; se cuentan errores y avisos.

## 6. 🧮 Los intermedios que amasan la salida

- El resumen de avisos por tipo: `awk '{print $2}' salidas/antes.log | sort | uniq -c`.
- «Compare callout warnings before and after» en `comandos-revision.sh`: los avisos `CALLOUT` de
  `antes.log` contados por archivo (`grep CALLOUT … | awk '{print $3}' | cut -d: -f1 | sort | uniq -c`),
  para compararlos con los del cierre.
- La prueba sembrada filtra el ruido conocido con `grep -v "EMOJI\|CALLOUT\|ENCAB"`.

## 7. ✅ Qué se espera ver

- Con los cuatro errores sembrados el verificador termina en `— 1 errores, 32 avisos` (comprobado de nuevo
  el 06/10/2026 sobre la copia que quedó): un `ERROR EJERCICIOS` (F01 dice 25 y tiene 24), y avisos
  `SECCION` (F03 sin «5. CLI de la fase»), `DESAFIOS` (F05 con solo D1 y D2, guía §9.2) y `DIAGRAMA` (el
  bloque de cajas de F07).
- Al cierre, `salidas/despues.log` termina en `— 0 errores, 29 avisos` (05/10/2026): 24 `EMOJI`, 3
  `CALLOUT` y 2 `ENCAB` (F16 y F17 no dicen «Proyecto que avanza»). Antes eran 236: 195 `EMOJI`, 21
  `CALLOUT` y 20 `ENCAB`.

## 8. 📂 Salidas

- `antes.log`, `publicacion.log`, `diagramas.log`, `candidatos.txt`: el estado inicial.
- `d1-01.mmd` … `d7-17.mmd` y sus `.png`: los siete diagramas.
- `copia-sembrada/`: la copia con los cuatro errores.
- `despues.log`: el cierre.

Todo se regenera con §4 (salvo los `.mmd`, que hoy salen del curso ya migrado). Nada se copió al curso
desde `salidas/`.

## 9. 🧹 Limpieza

`rm -rf salidas/copia-sembrada`. No hay contenedores ni cambios en la máquina.

## 10. 🚫 Qué se dejó fuera

Nada: no hay dependencias ni binarios. La búsqueda de diagramas pasó, reducida, al aviso `DIAGRAMA` de
`prompts/verificar-corpus.py` del curso.
