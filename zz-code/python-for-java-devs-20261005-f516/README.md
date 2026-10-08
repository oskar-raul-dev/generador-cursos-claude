# 🧪 python-for-java-devs-20261005-f516 · cómo correr estas pruebas

> **Curso:** python-for-java-devs · **Tanda:** carta opcional, T1–T24 (cerrada) · **Creado:** 2026-10-05
> **Propósito:** preparar, escribir y probar en contenedor la carta opcional (`op001`–`op176`).
> **Vigencia:** el README se escribió el 2026-10-06 a partir de la transcripción de la sesión `5c52573d`
> (05/10, 14:59–21:57 UTC) y se completó el 2026-10-07 al cerrar T20–T24 (las 176 secciones). **Estado: extraído**:
> el código de cada sección está en el curso, en `src/opNNN-…/`.

Este directorio guarda el **arnés** con el que se probó cada sección de la carta. El código de cada
sección vive en `salidas/<id>/` (por ejemplo `salidas/qa06/`), que git **no** versiona; su copia
versionada, con el comando exacto de cada sección, está en el rescate
`../python-for-java-devs-20261006-772f/` (`05-carta-codigo/` y `04-carta-5c52573d/humo-por-seccion.sh`).

---

## 1. 🎯 Qué se prueba y para qué

Cada sección `opNNN-<id>-….md` de la carta trae su código en bloques. La prueba de humo **extrae esos
bloques del Markdown publicado**, los corre en `python:3.14.7` y compara la salida con la que la sección
muestra; si coincide, `probado.py` cambia los rótulos de «Salida esperada, sin correr» a «Salida (Python
3.14.7, 05/10/2026)». Así la cifra publicada sale de una corrida, no de una suposición. Las secciones que
no se pudieron correr conservan el rótulo «sin correr» y su motivo (guía §14.1 del curso).

| Archivo | Qué hace | Cómo se corre |
|---|---|---|
| `humo.py` | Extrae bloques de una sección a `salidas/<id>/` y corre un comando en `python:3.14.7` (`--rm`, etiqueta `curso=python-for-java-devs`) | `python3 humo.py <sección.md> <id> <archivo=inicio>… [--pip paq==v …] [--cmd "…"]` |
| `humo_servicio.py` | Lo mismo, con servicios (Postgres, Valkey, Kafka…) en una red propia `pfjd-<id>`, sin puertos publicados, y los borra al final pase lo que pase | `python3 humo_servicio.py <sección.md> <id> <archivo=inicio>… --svc alias=imagen [--env alias:K=V] [--args alias:"…"] [--pip …] --cmd "…"` |
| `probado.py` | Cambia el encabezado y los rótulos de una sección a «probado» | `python3 probado.py <sección.md>` |
| `carta.py` | La lista única de la carta: tracks y secciones; de ahí sale la numeración `opNNN` | `python3 carta.py` imprime la numeración |
| `plan.py` | Marca filas del plan (`prompts/plan-de-produccion-carta.md`): escrita/corrida por rango, estado de tanda, bitácora y «dónde está» | `python3 plan.py 1 7 ✅ ✅` · `python3 plan.py tanda T1 ✅` · `python3 plan.py bitacora 'texto'` · `python3 plan.py dondeesta 'texto'` |
| `verificar_urls.py` | Pide cada URL de los `.md` dados y lista las que no responden 200 tras redirecciones, o caen en otro dominio o en una portada | `python3 verificar_urls.py <archivo.md>…` |

En `<archivo=inicio>`, `inicio` es el comienzo del bloque (`'circulares.py="""Extrae las circulares'`) o
`@archivo` para el bloque que sigue a la línea `` `archivo`: ``.

## 2. 🛠️ Prerrequisitos

- Docker Desktop y Python 3 (biblioteca estándar) en el host; el arnés no instala nada fuera del
  contenedor.
- Imagen `python:3.14.7` (y `python:3.14.7-slim` en algunas). Los servicios usan imágenes de otros cursos
  sin tocarlas (postgres 18.6, mysql 9.7.2, mariadb 12.3.3, valkey 9.1, mongo 8.0.20, cassandra 5.0,
  neo4j 2026.09.0, kafka 4.3.1…) y las que la carta bajó, anotadas en `salidas/imagenes-bajadas.txt`.
- Las versiones de cada paquete van en el `--pip` de cada corrida y están fijadas en la sección.
- Rutas: `humo.py`, `humo_servicio.py`, `probado.py` y `plan.py` traen escrita la ruta absoluta del
  curso (`CARTA`/`P`, arriba de cada archivo); si el repositorio se mueve, se corrige ahí.

## 3. 🧭 Reglas antes de correr

```bash
cd zz-code/python-for-java-devs-20261005-f516
Z=$PWD/salidas
{ date; docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}'; echo ---; docker volume ls -q; echo ---; \
  docker images --format '{{.Repository}}:{{.Tag}}' | grep -i python; } > $Z/docker-inventario-inicial.log 2>&1
```

- Ese es el inventario que tomó la sesión al empezar (`salidas/docker-inventario-inicial.log`); antes de la
  limpieza final tomó otro más completo (`salidas/inventario-docker-antes-de-limpiar.txt`).
- Todo lleva `--label curso=python-for-java-devs`; los contenedores corren con `--rm` y los servicios se
  borran en el `finally` de `humo_servicio.py`.
- **Ningún puerto publicado**: los servicios se alcanzan por alias dentro de la red `pfjd-<id>`. Cuando una
  prueba necesitó un servidor (SMTP en `co01`), corrió dentro del mismo contenedor en `127.0.0.1`.
- Cada imagen nueva que se baje se anota en `salidas/imagenes-bajadas.txt` en el momento.

## 4. ▶️ Cómo se corre

Desde este directorio, una sección por vez. Dos ejemplos tal como corrieron:

```bash
python3 humo.py op009-au02-scraping.md au02 'circulares.py="""Extrae las circulares' \
  --pip httpx==0.28.1 selectolax==1.0.0 beautifulsoup4==4.15.0 --cmd "python circulares.py"

python3 humo.py op015-co01-correo-saliente.md co01 'liquidaciones.py="""Manda a cada franquiciado' \
  --pip aiosmtpd==1.4.6 --cmd "(python -m aiosmtpd -n -l 127.0.0.1:8025 > smtp.log 2>&1 &); sleep 1; SMTP_HOST=127.0.0.1 SMTP_PORT=8025 SMTP_TLS=0 python liquidaciones.py"
```

El comando de **cada** sección probada con el arnés (136) está en
`../python-for-java-devs-20261006-772f/04-carta-5c52573d/humo-por-seccion.sh`, uno por bloque; las que se
probaron con un `docker run` directo están en la `bitacora.md` de esa misma carpeta. Después de una
corrida que coincide:

```bash
python3 probado.py op009-au02-scraping.md
cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 -B prompts/verificar-corpus.py | tail -2
python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op009-au02-scraping.md
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 9 9 ✅ ✅
```

`salidas/antes.log` es el verificador del curso antes de empezar la carta.

## 5. 📏 Cómo se mide

La carta no publica benchmarks: prueba que el código corre y fija la salida que muestra. Las pocas cifras
que una sección cita (por ejemplo `db06`: el `PING` de otro cliente esperó 316 ms con `KEYS` contra 0,8 ms
con `SCAN`) son de una corrida única en contenedor, y la sección lo dice así.

## 6. 🧮 Los intermedios que amasan la salida

`humo.py` imprime los últimos 6.000 caracteres de la salida estándar y 4.000 de la de error
(`humo_servicio.py`: 8.000 y 4.000); los comandos de la sesión casi siempre la recortaron con `| tail -N`
o `| head -N` (visible en `humo-por-seccion.sh`). Lo que se pegó en la sección es esa salida, sin otro
procesamiento. `probado.py` solo cambia rótulos.

## 7. ✅ Qué se espera ver

La salida rotulada «Salida (Python 3.14.7, 05/10/2026)» de cada sección es la referencia. Al cerrar T19:
156 de 176 secciones escritas, y el estado de cada una (escrita, corrida) en
`prompts/plan-de-produccion-carta.md` §3; la bitácora (§7) registra, por tanda, los defectos propios que
las pruebas encontraron y se corrigieron.

## 8. 📂 Salidas

- `salidas/<id>/` — el código extraído de cada sección y lo que generó su corrida (logs, bases `.db`,
  imágenes, PDF, `.so`…). Se regenera con el comando de la sección; el código, además, está copiado en
  `../python-for-java-devs-20261006-772f/05-carta-codigo/` (se refresca con su `copiar_codigo_carta.sh`).
- `salidas/antes.log`, `docker-inventario-inicial.log`, `inventario-docker-antes-de-limpiar.txt`,
  `imagenes-bajadas.txt` — el verificador inicial, los dos inventarios y la lista de imágenes bajadas.

## 9. 🧹 Limpieza

La que hizo la sesión al cortar en T19 (05/10, 21:57 UTC): borrar solo las imágenes de
`imagenes-bajadas.txt` que ningún contenedor usa, y los restos con la etiqueta.

```bash
for img in debian:trixie-slim influxdb:3.12.0-core getmeili/meilisearch:v1.54.3 rustfs/rustfs:1.0.1 nats:2.15.0 \
           eclipse-temurin:21.0.12.1_1-jdk rabbitmq:4.3.6-alpine condaforge/miniforge3:26.7.2-0; do
  users=$(docker ps -a --filter ancestor=$img -q)
  if [ -n "$users" ]; then echo "SALTO $img: la usa $users"; else docker rmi $img >/dev/null && echo "borrada $img"; fi
done
docker image prune -f --filter label=curso=python-for-java-devs
```

Después se anota en `imagenes-bajadas.txt` cuándo se borró cada una. `python:3.14.7` se conserva hasta
cerrar la carta. Lo regenerable dentro de `salidas/` (`.venv`, `dist`, `build`, `__pycache__`) lo libera
`python3 zz-code/limpiar.py python-for-java-devs-20261005-f516`.

## 10. 🚫 Qué se dejó fuera

- **Del versionado:** todo `salidas/`, por la regla del `.gitignore` de `zz-code/`; el código está a salvo
  en la copia del rescate (ver §8).
- **Binarios descargados:** `salidas/jv03/jython.jar` y `salidas/jv03/graalpy/` (el runtime de GraalPy),
  que se bajan de nuevo con los comandos de `jv03`.
- **Los comandos sueltos de la sesión:** los 864 comandos, en orden, están en
  `../python-for-java-devs-20261006-772f/04-carta-5c52573d/comandos.sh`.

## 11. ➕ Lo que agregó la sesión del 07/10/2026 (T20–T24)

- **`comparar.py <sección.md> <salida.txt> [N]`**: compara la salida rotulada número N de la sección con una corrida; `IGUAL` o el diff.
- **`ensamblar.py salidas/<id>/seccion.md <opNNN-….md> [código salida]`**: arma la sección desde una plantilla con `__CODIGO:archivo__` y
  `__SALIDA:archivo__`, para que el código y la salida publicados sean exactamente los que corrieron.
- **`probado.py`** toma la fecha del encabezado de la propia sección (T20–T22 dicen 07/10/2026).
- **`src_desde_secciones.py --informe | --escribir`** (T24): reconoce los archivos de cada sección (el párrafo que los nombra, o el comando que los
  corre) y escribe `src/opNNN-…/` con un README por sección. Lo regenera todo desde el Markdown: si se edita una sección, se vuelve a correr.
- Las corridas de T20–T22 usaron `humo.py`/`humo_servicio.py` con el mismo patrón de §4; las que necesitaban paquetes del sistema
  (`libegl1 libgles2` para MediaPipe, `xvfb` para turtle, Cairo, Pango y FFmpeg para manim) los instalan con `apt-get` dentro del
  `--cmd`, y las de MediaPipe corren con `uv` 0.12.23 y el `pyproject.toml` de la sección (`override-dependencies`).
- **`salidas/t24/`**: los andamios de la verificación final. `systemd/Dockerfile` (imagen `pfjd-systemd:t24`, ya borrada) corre con
  `--privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw` **sin** `--tmpfs /run`; aun así, systemd 257 no monta credenciales
  en el kernel de Docker Desktop. `co05/servidor.py` es el FTPS de prueba; `lg02/c*-minimo.xsd`, la solución del ejercicio 4 (no se publica).
