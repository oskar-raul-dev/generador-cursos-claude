# 📌 Pendientes a futuro: la hoja de verificación al tomar el curso
## Laboratorio de contenedores y Kubernetes local

> **Qué es este documento:** la hoja de trabajo de la pasada que cierra el curso: el autor lo toma
> como lector, desde cero, en cada sistema, monta todos los contenedores y rehace todas las pruebas.
> No se cita desde el curso.
> **Fecha:** 05/10/2026. Ese día la redacción quedó cerrada: `verificar-corpus.py` sale en 0 errores y
> 0 avisos en sus dos modos, y las 44 decisiones están en ✅.

La verificación de la producción fue **la del autor**: macOS arm64, comandos corridos por las
sesiones de escritura, con `src/lab/` ya armado al lado. Esa verificación prueba que el laboratorio
funciona; no prueba que las fases, leídas en orden por alguien que empieza de cero, lleven a que
funcione. Eso solo lo prueba tomar el curso, y en Windows 11 y Linux esa pasada es además la primera.

---

## 🧭 Las reglas de la pasada

1. **Desde cero y como lector.** La máquina arranca sin nada del curso: sin la máquina de Podman (se
   borró el 05/10/2026), sin clusters, sin imágenes `lab/*`. Se instala desde `a01`, sin atajos, y
   se trabaja en un repositorio propio, como manda `00-convencion-de-git-y-tags.md`. El `src/lab/`
   del curso solo se usa para compararse con los tags: si se copia de ahí, la prueba deja de valer.
2. **Toda diferencia es un hallazgo.** Va en
   [`verificacion-de-laboratorio/hallazgos.md`](verificacion-de-laboratorio/hallazgos.md) desde H271,
   con el mismo formato (fecha, log en `logs/`, documento que cambia), y la corrección pasa del
   hallazgo al documento, nunca al revés. La marca *"no verificado por el autor"* se quita solo
   donde se corrió de verdad.
3. **Las cifras no se pisan.** Un número propio dentro de la variación ya medida deja la cifra
   publicada como está; uno fuera la corrige, con la máquina declarada. Lo de Windows y Linux entra
   como filas nuevas en `BENCHMARKS.md`, no en lugar de las de macOS.
4. **El orden.** Primero una pasada completa en macOS, que valida las instrucciones; después Windows
   11 y Linux, como mínimo hasta la F07, que es donde el host pesa. De la Parte II en adelante todo
   corre dentro del cluster y diverge poco.

En cada fase, lo mínimo es lo mismo: los comandos del recorrido dan la salida publicada (o una
equivalente), la suite del paso pasa (`task conformance`), los incidentes que la fase reserva se
rompen y se arreglan con `task inc:break|fix`, y el tag de la fase coincide con lo que quedó.

---

## 🍎 La pasada en macOS: lo que pide atención por tramo

| Tramo | Además de lo de cada fase | Cierra |
|---|---|---|
| F00 + `a01` | Instalación completa desde `a01`, incluido Podman con su instalador oficial y su máquina de 4 GiB. Las versiones instaladas contra las fijadas en `a01` | — |
| F01–F02 + `a16` | El patrimonio entero con el perfil `legacy` (Contingencia, el portal, la Braqui y su aviso de traslados), y la suite G0 | — |
| F03–F05 | B-04 y B-05 con el arnés de `measure.py`, en la VM de 4 GiB | — |
| F06–F07 | Los dos clusters de kind; B-07. Si se prueba el bloque opcional con el Kubernetes de Docker Desktop: al apagarlo, confirmar que no quedan corriendo `desktop-control-plane`, `kind-registry-mirror` ni `kind-cloud-provider`. En la producción quedaron huérfanos, y si se repite, va a `a02` y a la F07 | — |
| `a01` | **B-00 de nuevo**, ahora sin el Kubernetes de Docker Desktop, que en la producción estuvo encendido al menos desde T8 (H155) | H155; B-00 en `BENCHMARKS.md`, `a01`, contrato §5, F17 §5.5 |
| F08–F16 | Los incidentes 05–17; B-12 y B-16 | — |
| F17–F18 | La observabilidad pieza por pieza, sin construir con todo encendido: con 4 GiB, trazas + Prometheus + Grafana + el agente de Java ahogan la VM | — |
| F19 | **La CA en el navegador**: con la puerta en 8443, el navegador confía sin advertencias. La CA ya está en el llavero `login` (H270) | H174 y H270; `a01` (la CA) y F19 §5.3 |
| F20–F21 | Los incidentes 18–26; k9s contra el cluster (`a04`) | — |
| F22–F26 | Caos, B-23, la saga, la coreografía y el outbox; NATS con `task bus:on` | — |
| F27 | El proyecto final con su rúbrica | — |
| Apéndices 🔥 | `a06`–`a15`, opcionales: cada uno instala y retira lo suyo | — |
| Al terminar | **Quitar la CA** con el paso 4 de `a01` (`delete-certificate -Z <SHA-1>`, H269) y probar la variante del llavero del sistema que la receta nombra. Bajar los clusters y el compose con sus tareas (`task cluster:down`, `task legacy:down`) y decidir si la máquina de Podman se queda | la sección de la CA de `a01` |

---

## 🪟🐧 Windows 11 y Linux

Las instrucciones de los dos sistemas están escritas contra la documentación oficial y marcadas *"no
verificado por el autor"* en el README, `0-ESTRUCTURA-CURSO.md`, F00–F03, F05, F07, F10, `a01`,
`a02`, `a03`, `a05`, `a06`, `a07`, `a14`, `a16` y el cuaderno.

- **Hasta la F07, como mínimo:** instalación desde `a01`, los dos motores, el patrimonio, los dos
  clusters de kind y `task images:load`. Es donde el host decide: rutas, shells, permisos, la VM o
  WSL2, el proxy de la empresa (incidente 27).
- **Las mediciones** B-00, B-04, B-05 y B-07, como filas nuevas con su máquina.
- **La CA del laboratorio**, con la receta de cada sistema en `a01`, si se llega a la F19.
- **Al cerrar:** se quita la marca solo donde se ejecutó, y `a02` suma los problemas que aparezcan.

---

## 🔁 Mantenimiento, fuera de la pasada

- **La versión del nodo de kind.** D32 lo fijó en Kubernetes 1.36 porque Envoy Gateway 1.9 no soporta
  1.37. Cuando salga una versión que lo soporte, se reabre D32 y se reverifica el camino base; las
  versiones viven solo en `a01`, así que el cambio empieza allí.
- **La publicación (etapa E9).** `verificar-corpus.py --publicacion` ya sale limpio. Falta crear el
  repositorio público sin `prompts/`, empujar `src/lab/` con los tags `fase-NN-<slug>` e
  `inc/<ID>/<slug>-roto|-fix`, y revisar que los enlaces relativos sigan resolviendo fuera de este
  repositorio. Conviene hacerlo **después** de la pasada, para publicar lo verificado.
