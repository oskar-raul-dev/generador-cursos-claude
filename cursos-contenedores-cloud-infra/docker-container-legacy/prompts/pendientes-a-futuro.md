# 📌 Pendientes a futuro: la hoja de verificación al tomar el curso
## Docker Legacy Node

> **Qué es este documento:** la hoja de trabajo de la pasada que cierra el curso: el autor lo toma
> como lector, desde cero, en cada sistema, monta todos los contenedores y rehace todas las pruebas.
> Al final, dos decisiones que esperan al autor. No se cita desde el curso.
> **Fecha:** 05/10/2026. Ese día la redacción quedó cerrada: `verificar-corpus.py` (los dos modos) y
> `check-course.sh` salen limpios.

La verificación de la producción fue **la del autor**, y parcial: ocho documentos (F12, F13, F14,
F15, F16, F20, F21 y F27) llevan fecha de verificación ejecutada, corridos el 03 y el 06/09/2026
sobre Docker 29.6.2 en macOS Apple Silicon, casi siempre con la imagen `linux/amd64` bajo emulación.
Los comandos `podman` de F24, F25 y F26 están contrastados con la documentación oficial, no
ejecutados. Tomar el curso entero es lo que prueba que las fases, leídas en orden por alguien que
empieza de cero, llevan a la imagen que prometen.

---

## 🧭 Las reglas de la pasada

1. **Desde cero y como lector.** La máquina arranca sin nada del curso: sin la imagen del
   laboratorio y sin la máquina de Podman (se borró el 05/10/2026). Se sigue la ruta 🎓 del programa
   (§6) y se construye la imagen fase a fase. `src/` solo se usa para compararse: si se copia de ahí,
   la prueba deja de valer.
2. **Toda diferencia se anota** en la bitácora del final de este documento, con fecha, fase, lo que
   decía el curso y lo que salió. La corrección pasa de la bitácora al documento, y la cabecera de la
   fase gana su **fecha de verificación ejecutada** solo si se corrió de verdad (guía §16).
3. **Las cifras no se pisan.** Un número propio dentro de la variación ya publicada deja la cifra
   como está; uno fuera la corrige, con la máquina declarada. Otra plataforma suma su medición al
   lado, no en lugar de la de macOS.
4. **El orden.** Primero una pasada completa en macOS; después Windows 11 y Linux, como mínimo la
   Parte I (el taller), que es donde el host pesa.

---

## 🍎 La pasada en macOS: lo que pide atención

| Tramo | Además de lo de cada fase | Cierra |
|---|---|---|
| Parte I (F00–F11) | La imagen incremental fase a fase, con las versiones fijadas de la guía §5.1 y §5.2, y la validación de F11 con un proyecto real | — |
| F11, ejercicio 24 (🔥) | La matriz de `00-node-smoke` contra las cuatro generaciones de Node | ver la decisión 2 |
| F12–F16, F20, F21, F27 | Volver a correr lo que ya tiene fecha, con la versión de Docker del momento | las cabeceras, si algo cambió |
| F22–F23 | Apple Silicon: ARM64 nativo contra AMD64 emulado | — |
| **F24–F26** | **Los comandos `podman`, ejecutados por primera vez.** Ojo: el curso no trae una receta de instalación de Podman (el ejercicio 11 de F22 solo dice «instala Podman Desktop o Colima»); si al lector le hace falta, la pasada decide si F24 suma un bloque de instalación con `podman machine init` | la advertencia «Alcance de la verificación» de las tres cabeceras, `0-programa-del-curso.md` §9 y la guía §16.4 |
| F28–F34 | Publicar la imagen, la cadena de suministro y el proyecto final con su rúbrica | — |
| **a17** | **Escribirlo durante la pasada**: es el único documento que falta, y espera justamente esta sesión de laboratorio | ver abajo |

### El apéndice a17, compilar Node desde fuente

Está diseñado y no escrito porque el curso publica salidas reales. El protocolo completo está en
`propuestas-cursos/propuesta-complemento-docker/complemento-docker-legacy.md` §9: cuatro corridas,
Lima en macOS y WSL2 con dos rootfs importados en Windows, Debian 11 bullseye para Node 14 y bookworm
o trixie para el moderno, el guion común (§9.5) y la hoja de captura (§9.6). Nada de VMware,
VirtualBox ni Parallels (§9.4). Al cerrarlo: el apéndice con su cabecera de verificación, su entrada
en `0-programa-del-curso.md` y en el README, la guía §16.4, y `check-course.sh` en verde.

---

## 🪟🐧 Windows 11 y Linux

- **Windows 11:** la Parte I con `a08` (Windows y PowerShell) y WSL2; las corridas de Windows del a17
  salen de aquí.
- **Linux:** la Parte I nativa, sin máquina virtual de por medio. Es la plataforma donde rootless
  (F25) y los user namespaces se ven sin capas extra.
- **Al cerrar:** lo que se corrió gana su fecha en la cabecera, con la plataforma; los problemas
  nuevos van al catálogo de fallos (F31–F32) o al apéndice de la plataforma.

---

## 🧭 Decisiones del autor

### 1. El solucionario de los ejercicios

La guía §16 lo declara **decisión** ("Sin solucionario: cada ejercicio cierra con `Objetivo:` o
`Pregunta:`; solo F34 trae rúbrica"), pero `0-programa-del-curso.md` §9 se lo presenta al lector como
**pendiente** ("Es un pendiente conocido"). Si es decisión, se reescribe ese párrafo del programa
para decir por qué no hay solucionario; si es pendiente, pasa a la guía §16.4 y se planifica (941
ejercicios, según el README).

### 2. La matriz de compatibilidad completa

F11 (ejercicio 24, 🔥) llama a la matriz contra las cuatro generaciones de Node "un pendiente
declarado del curso", que F20 retoma; F20 publica la suya corrida sobre `linux/amd64` emulado. La
pasada da los datos para decidir si basta con la de F20 (y F11 deja de decir "pendiente") o si hace
falta la corrida en ARM64 nativo.

---

## 📓 Bitácora de la pasada

*(vacía: se llena al tomar el curso)*
