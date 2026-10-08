#!/usr/bin/env python3
"""Crea el directorio de trabajo de una sesión en zz-code/.

Uso, desde cualquier sitio:
    python3 zz-code/nuevo.py <curso> [--tanda T3] [--proposito "prototipo del outbox"]

Crea `zz-code/<curso>-<AAAAMMDD>-<hash>/` con su MANIFIESTO.md y el esqueleto de su README.md (las
instrucciones de corrida y de medición, ver zz-code/README.md) y escribe la ruta en la salida, para
pegarla en la bitácora del plan de producción. Nunca reutiliza ni toca un directorio existente.
Solo biblioteca estándar.
"""

import argparse
import datetime
import os
import re
import secrets
import sys

RAIZ = os.path.dirname(os.path.abspath(__file__))

MANIFIESTO = """# {ident}

- **Curso:** {curso}
- **Tanda:** {tanda}
- **Creado:** {fecha}
- **Propósito:** {proposito}
- **Estado:** vigente
- **Cómo regenerar lo que limpiar.py borra:** {{{{p. ej. `npm ci`, `mvn -q package`, `python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`}}}}

## Qué hay

{{{{Una línea por subdirectorio o archivo que importe.}}}}

## Qué sirvió

{{{{Lo que se extrajo al curso, a su laboratorio o a zz-instrucciones/herramientas/, con su destino.}}}}
"""

README = """# 🧪 {ident} · cómo correr estas pruebas

> **Curso:** {curso} · **Tanda:** {tanda} · **Creado:** {fecha}
> **Propósito:** {proposito}
> Se llena **mientras se prueba**: cada script nuevo entra aquí en la misma sesión. Las reglas, en
> `zz-code/README.md` § "El README de cada directorio". Si una sección no aplica, se dice por qué.

## 1. 🎯 Qué se prueba y para qué

{{{{Prueba → fase o apéndice → hallazgo (H-n) o benchmark (B-n) que alimenta.}}}}

## 2. 🛠️ Prerrequisitos

{{{{Herramientas con versión, imágenes base, dependencias, y el estado previo: cluster, datos, tags,
configuración de la máquina.}}}}

## 3. 🧭 Reglas antes de correr

```bash
mkdir -p salidas
docker ps -aq --no-trunc > salidas/contenedores-antes.txt
docker images -q --no-trunc | sort -u > salidas/imagenes-antes.txt
docker volume ls -q > salidas/volumenes-antes.txt
docker network ls -q > salidas/redes-antes.txt
```

{{{{Etiqueta curso={curso}, puertos, y cada cambio temporal en la máquina con su comando para revertirlo.}}}}

## 4. ▶️ Cómo se corre

{{{{Comandos en orden, copiables, con el directorio desde el que se lanza cada uno; por script:
argumentos, qué hace y qué imprime.}}}}

## 5. 📏 Cómo se mide

{{{{Arnés y condiciones: máquina, motor y versión, memoria/CPU de la VM, corridas, calentamiento,
reposo, estadístico publicado y por qué; mediciones rehechas y la razón.}}}}

## 6. 🧮 Los intermedios que amasan la salida

{{{{De la salida cruda a la cifra publicada, en orden: filtros (jq, awk, sed, sort | uniq -c), scripts
que promedian o redondean, consultas, cruces y conversiones, cada uno con su archivo o su comando literal.}}}}

## 7. ✅ Qué se espera ver

{{{{Resultado de referencia de cada prueba, con fecha y dónde quedó registrado.}}}}

## 8. 📂 Salidas

{{{{Qué escribe cada prueba en salidas/, cómo se regenera y qué se copió al curso.}}}}

## 9. 🧹 Limpieza

{{{{Comandos para borrar lo creado (por etiqueta o contra el inventario) y restaurar la máquina.}}}}

## 10. 🚫 Qué se dejó fuera

{{{{Binarios, .tar, .jar, dependencias y secretos que no se guardan, con el comando que los regenera.}}}}
"""


def main():
    p = argparse.ArgumentParser(description="Crea zz-code/<curso>-<AAAAMMDD>-<hash>/ con su manifiesto.")
    p.add_argument("curso", help="slug del curso, p. ej. 05-event-driven o lab-docker-kubernetes")
    p.add_argument("--tanda", default="—")
    p.add_argument("--proposito", default="{{qué se va a probar}}")
    p.add_argument("--raiz", default=RAIZ, help="otra raíz (solo para pruebas)")
    a = p.parse_args()

    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", a.curso):
        sys.exit("El curso va en minúsculas, números y guiones, p. ej. 05-event-driven.")
    fecha = datetime.date.today()
    for _ in range(10):
        ident = f"{a.curso}-{fecha:%Y%m%d}-{secrets.token_hex(2)}"
        ruta = os.path.join(a.raiz, ident)
        if not os.path.exists(ruta):
            break
    else:
        sys.exit("No se encontró un identificador libre; vuelve a intentarlo.")
    os.makedirs(ruta)
    with open(os.path.join(ruta, "MANIFIESTO.md"), "w", encoding="utf-8") as f:
        f.write(MANIFIESTO.format(ident=ident, curso=a.curso, tanda=a.tanda,
                                  fecha=fecha.isoformat(), proposito=a.proposito))
    with open(os.path.join(ruta, "README.md"), "w", encoding="utf-8") as f:
        f.write(README.format(ident=ident, curso=a.curso, tanda=a.tanda,
                              fecha=fecha.isoformat(), proposito=a.proposito))
    print(ruta)


if __name__ == "__main__":
    main()
