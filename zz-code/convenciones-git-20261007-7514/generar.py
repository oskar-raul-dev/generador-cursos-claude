#!/usr/bin/env python3
"""Genera 00-convencion-de-git-y-tags.md en los cursos en preparación de cursos-bd.

Uso, desde la raíz del repositorio:
    python3 zz-code/convenciones-git-20261007-7514/generar.py            # vista previa (no escribe)
    python3 zz-code/convenciones-git-20261007-7514/generar.py --escribir # escribe; nunca pisa un archivo existente

Los nombres salen de lo que cada curso ya decidió (alcance D-09, contrato §7, guía); donde no hay
decisión se escribe la forma por defecto de zz-instrucciones con la marca ⏳.
"""

import os
import sys
import textwrap

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
VIGENCIA = "2026-10-07"
NOMBRE = "00-convencion-de-git-y-tags.md"

# --- datos por curso ---------------------------------------------------------------------------

DEF = dict(tag="fase-NN-<slug>", commit="fNN", ej="fNN ejM", ejemplo_tag="fase-03-<slug>",
           ejemplo_commit="f03")

def ruta_nosql(titulo, historia=None, codigo=None, decidido=True):
    return dict(titulo=titulo, decidido=decidido, historia=historia,
                codigo=codigo or ("un solo proyecto en `src/` que crece fase a fase" if decidido else None),
                track=None, apendices=None, fase0=None, extra=None)

CURSOS = {
    "cursos-bd/ruta-no-sql/00-proteo": ruta_nosql(
        "Proteo — Modelo Documental", "Mercado Ceibo"),
    "cursos-bd/ruta-no-sql/01-portalon": ruta_nosql(
        "Portalón — Modelo Clave-Valor", "Liga Pixel"),
    "cursos-bd/ruta-no-sql/02-cristaleria": ruta_nosql(
        "Cristalería — Modelo Analítico Embebido", "Pasaje",
        "un solo proyecto en `src/` que crece fase a fase: `src/pipeline/` en Python y, desde su "
        "bloque, `src/dashboard/` en TypeScript"),
    "cursos-bd/ruta-no-sql/03-oraculo-de-bolsillo": ruta_nosql(
        "Oráculo de Bolsillo — Modelo Vectorial", "Valdivieso Abogados"),
    "cursos-bd/ruta-no-sql/04-telarana": ruta_nosql(
        "Telaraña — Modelo de Grafos", "Quetzal Pay",
        "un solo proyecto en `src/` que crece fase a fase; el código del apéndice de la JVM va en "
        "`src/jvm/`, fuera del proyecto principal"),
    "cursos-bd/ruta-no-sql/05-centinela-de-flota": ruta_nosql(
        "Centinela de Flota — Modelo Columnar Ancho", decidido=False),
    "cursos-bd/ruta-no-sql/06-buscafino": ruta_nosql(
        "Buscafino — Modelo de Búsqueda", decidido=False),
    "cursos-bd/ruta-no-sql/07-bitacora-de-campo": ruta_nosql(
        "Bitácora de Campo — Modelo Offline-First", decidido=False),
    "cursos-bd/ruta-no-sql/08-el-vigia": ruta_nosql(
        "El Vigía — Modelo de Series Temporales", decidido=False),
    "cursos-bd/ruta-no-sql/09-libro-mayor": ruta_nosql(
        "Libro Mayor — Modelo NewSQL Distribuido", decidido=False),
    "cursos-bd/ruta-no-sql/10-el-arbitro": ruta_nosql(
        "El Árbitro — Capstone Políglota", decidido=False),
    "cursos-bd/gestores-sql/01-bases": dict(
        titulo="El motor de motores — La teoría que todos los gestores SQL implementan",
        decidido=True, historia=None,
        codigo="una carpeta de `src/` por cada fase o apéndice que deja código, con el nombre exacto "
               "del documento",
        commit="01-bases fNN", ej="01-bases fNN ejM", ejemplo_commit="01-bases f03",
        track=dict(nombre="el bloque A.C.", archivos="`acNN-<slug>.md`", tag="ac-fase-<slug>",
                   commit="01-bases acNN", lista="ac-fase-*"),
        apendices="`apendice-aNN-<slug>` y, en el bloque A.C., `apendice-aca-NN-<slug>`, solo los "
                  "que dejan código en `src/`",
        fase0=None, extra=None),
    "cursos-bd/ruta-sql": dict(
        titulo="Ruta SQL — La base que nadie diseñó", decidido=True, historia="Laboratorio Alameda",
        codigo="una carpeta de `src/` por cada fase o apéndice que deja código, con el nombre exacto "
               "del documento, más `src/lab/` para lo compartido",
        track=dict(nombre="el track opcional de SQL Server", archivos="`ssNN-<slug>.md`",
                   tag="ss-fase-NN-<slug>", commit="ssNN", lista="ss-fase-*"),
        apendices="`apendice-a02-compose`, `apendice-a05-la-caja` y `apendice-a10-access-de-museo`",
        fase0="00-la-base-que-nadie-diseno.md", extra=None),
}
for motor, titulo in [("02-postgresql", "PostgreSQL"), ("03-mysql", "MySQL"), ("04-mariadb", "MariaDB"),
                      ("05-sqlite", "SQLite"), ("06-sql-server", "SQL Server"), ("07-oracle", "Oracle")]:
    CURSOS[f"cursos-bd/gestores-sql/{motor}"] = dict(
        titulo=f"Gestores SQL — {titulo}", decidido=False, historia=None, codigo=None, track=None,
        apendices=None, fase0=None, extra=None)

# --- el documento ------------------------------------------------------------------------------

def documento(c):
    d = dict(DEF)
    d.update({k: v for k, v in c.items() if k in DEF})
    tag, commit, ej = d["tag"], d["commit"], d["ej"]
    ec = d.get("ejemplo_commit", "f03")
    pendiente = not c["decidido"]
    l = []
    w = l.append
    w("# 🏷️ Convención de git: commits y tags de progreso")
    w(f"## {c['titulo']}")
    w("")
    w("Cómo versionas el código que escribes mientras haces el curso. Es corta a propósito: no es un")
    w("proyecto de empresa, no hay releases ni equipo, y una estrategia de ramas elaborada sobraría. Son")
    w("tres cosas —un repo, commits con un prefijo y un tag por fase cerrada— y una regla que las ordena:")
    w("el archivo que estás leyendo te dice cómo se llama su tag.")
    w("")
    fase0 = f"de la Fase 00 (`{c['fase0']}`)" if c["fase0"] else "de la Fase 00"
    w(f"> **Cuándo se lee:** antes {fase0}, y cada vez que el bloque 🏷️ de cierre de una fase te mande")
    w("> aquí.")
    w(f"> **Vigencia:** {VIGENCIA}.")
    w("")
    if pendiente:
        w("> 📝 **Curso en preparación.** Sus nombres todavía no están fijados: lo que sigue es la forma por")
        w("> defecto de todos los cursos del repositorio. Lo que lleva ⏳ se confirma cuando se fijen, y este")
        w("> documento se corrige en ese momento.")
    else:
        w("> 📝 **Curso en preparación.** Los nombres de este documento ya están decididos en sus")
        w("> lineamientos; lo que lleva ⏳ lo fija una fase o un apéndice que todavía no existe.")
    w("")
    w("> 🔑 **La frase para memorizar:** un tag es un puntero a un commit. No ocupa espacio, no agrega")
    w("> overhead y se borra con `git tag -d`. La pregunta no es \"¿vale la pena etiquetar esto?\", es \"¿por")
    w("> qué no?\".")
    w("")
    w("---")
    w("")
    w("## 📦 1. El repositorio")
    w("")
    if c["codigo"]:
        w("**El curso no se hace dentro del repositorio donde se publica.** Antes de la Fase 00 copias la")
        w("carpeta del curso a un repositorio tuyo, y es ahí donde trabajas: tu `git init`, tus commits y tus")
        w("tags. El repositorio del curso queda intacto, como referencia contra la que te comparas.")
        w("")
        w(f"El código del curso es {c['codigo']}.")
    else:
        w("**El curso no se hace dentro del repositorio donde se publica.** Antes de la Fase 00 copias la")
        w("carpeta del curso a un repositorio tuyo, y es ahí donde trabajas: tu `git init`, tus commits y tus")
        w("tags. El repositorio del curso queda intacto, como referencia contra la que te comparas.")
        w("")
        w("⏳ Cómo se organiza el código (un proyecto que crece fase a fase o una carpeta por fase) se decide")
        w("al preparar el curso.")
    if c["historia"]:
        w(f"Los nombres del sistema son los de {c['historia']}, la empresa de la historia del curso.")
    w("")
    w("**Lo que queda fuera desde el primer commit**: dependencias (`node_modules/`, `.venv/`), datos")
    w("generados que se pueden regenerar, los volúmenes de los contenedores y cualquier `.env` con valores")
    w("reales (se versiona el `.env.example`). Un secreto que entra al repo ya no sale, aunque lo borres en")
    w("el commit siguiente.")
    w("")
    w("No hace falta remoto. Si lo tienes, recuerda que **los tags no viajan solos**: `git push --tags`.")
    w("")
    w("---")
    w("")
    w("## 💬 2. Los mensajes de commit")
    w("")
    marca = " ⏳" if pendiente else ""
    w(f"Un prefijo, y ya. El prefijo es el código de la fase, `{commit}:`, y los de ejercicio llevan además")
    w(f"su número, `{ej}:`.{marca}")
    w("")
    w("```bash")
    w(f'git commit -m "{ec}: <lo que hizo el commit>"')
    w(f'git commit -m "{ec} ej12: <lo que resolvió el ejercicio>"')
    w(f"git log --oneline --grep '^{ec}'        # todo lo de la Fase 3")
    w(f"git log --oneline --grep '^{ec} ej'     # solo sus ejercicios")
    w("```")
    w("")
    w("Commitea seguido y con mensajes cortos que digan **qué decidiste**, no qué archivo tocaste.")
    w("")
    w("### Los apéndices")
    w("")
    w("**Los apéndices no cierran con tag**: un tag marca un cambio en el repositorio, y un apéndice")
    w("explica lo que ya está ahí. Lo que salga de leer uno se commitea con el prefijo de la fase desde la")
    if c["apendices"]:
        w(f"que llegaste. Las excepciones son los que dejan archivos versionados: {c['apendices']}.")
    else:
        w("que llegaste. ⏳ Si alguno deja archivos versionados, lleva un tag `apendice-aNN-<slug>`.")
    w("")
    w("---")
    w("")
    w("## 🏷️ 3. Un tag por fase cerrada")
    w("")
    w("**Cuando cierras una fase —con su checklist de validación en verde— haces commit y creas el tag.**")
    w(f"Uno por fase: `{tag}`, con el mismo slug del archivo `.md` de la fase.{marca}")
    w("")
    w("Anotado (`git tag -a`), porque así guarda fecha y mensaje. El mensaje no se inventa: es el checklist")
    w("de la fase, con lo que efectivamente quedó funcionando y las cifras que mediste.")
    w("")
    w("```bash")
    w(f'git tag -a {d["ejemplo_tag"]} -m "F03 cerrada: <el checklist, una línea por ítem>"')
    w("```")
    w("")
    w("Si al escribir el mensaje descubres que un ítem del checklist no está, no está la fase. El tag es")
    w("honesto o no sirve para nada.")
    w("")
    if c["track"]:
        t = c["track"]
        w(f"**{t['nombre'][0].upper() + t['nombre'][1:]}** ({t['archivos']}) tiene su propio espacio de nombres:")
        w(f"tags `{t['tag']}` y commits `{t['commit']}:`, para que `git tag -l 'fase-*'` siga siendo el índice")
        w(f"limpio del camino base y `git tag -l '{t['lista']}'` el del suyo.")
        w("")
    w("> ⚠️ **Volver a un tag te deja en `detached HEAD`.** Es normal: `git checkout <tag>` te pone a mirar")
    w("> ese estado sin estar en ninguna rama. Si vas a escribir desde ahí, crea una rama primero, con")
    w("> prefijo (`git switch -c wip/fase-03-intento-2`): una rama y un tag que se llaman igual vuelven")
    w("> ambiguo cualquier `git checkout`.")
    w("")
    w("---")
    w("")
    w("## 🧪 4. Tags de ejercicio *(opcionales, pero baratos)*")
    w("")
    w("Van en un espacio de nombres aparte, `ej/<fase>/<número>`, para que `git tag -l 'fase-*'` siga")
    w("limpio. Rinden en dos casos: los ejercicios de diagnóstico, con un par `-roto` / `-fix` cuyo")
    w("`git diff` es la corrección aislada del ruido, y los de medición, con la cifra en el mensaje.")
    w("")
    w("```bash")
    w("git tag ej/f03/12-roto     # el problema reproducido, antes de tocar nada")
    w("git tag ej/f03/12-fix      # la corrección aplicada y verificada")
    w('git tag -a ej/f03/18 -m "<la cifra de antes y la de después, con el tamaño del dataset>"')
    w("```")
    w("")
    w("> ⚠️ Nunca un tag llamado literalmente `ej/f03`: si existe ese ref, git no puede crear")
    w("> `ej/f03/12`. Los niveles intermedios del espacio de nombres se quedan vacíos.")
    w("")
    w("---")
    w("")
    w("## 📈 5. Los comandos que hacen que esto sirva")
    w("")
    w("```bash")
    w("git tag -l 'fase-*'                         # ¿dónde estoy?")
    w("git tag -n99 -l 'fase-*'                    # lo que cerró cada fase, con sus cifras")
    w("git for-each-ref --sort=creatordate \\")
    w("  --format='%(creatordate:short)  %(refname:short)' 'refs/tags/fase-*'   # cuándo cerré cada fase")
    w("git diff <tag-anterior>..<tag-de-la-fase> --stat   # qué costó una fase")
    w("```")
    w("")
    w("---")
    w("")
    w("## ✅ 6. Checklist de cierre de fase")
    w("")
    w("- [ ] El checklist de validación de la fase, en verde y verificado a mano.")
    w("- [ ] `git status` limpio: todo lo de la fase está commiteado.")
    w(f"- [ ] `git tag -a {tag} -m \"…\"` creado, con el checklist en el mensaje.")
    w("")
    w("> **La señal de que quedó bien:** \"vuelvo después de tres semanas, corro `git tag -l 'fase-*'`, y sé")
    w("> exactamente dónde me quedé y qué sigue — sin releer una sola línea del curso\".")
    return refluir("\n".join(l)) + "\n"


def refluir(texto, ancho=100):
    """Rehace los párrafos de prosa (y de blockquote) fuera de los bloques de código."""
    salida, parrafo, prefijo, en_codigo = [], [], "", False

    def vaciar():
        if parrafo:
            salida.extend(textwrap.wrap(" ".join(parrafo), ancho, initial_indent=prefijo,
                                        subsequent_indent=prefijo, break_on_hyphens=False,
                                        break_long_words=False))
            parrafo.clear()

    for linea in texto.split("\n"):
        if linea.startswith("```"):
            vaciar()
            en_codigo = not en_codigo
            salida.append(linea)
            continue
        es_cita = linea.startswith("> ")
        cuerpo = linea[2:] if es_cita else linea
        if en_codigo or not linea.strip() or linea.startswith(("#", "|", "- [", "---")):
            vaciar()
            salida.append(linea)
            continue
        nuevo = "> " if es_cita else ""
        if parrafo and (nuevo != prefijo or (es_cita and cuerpo.startswith("**"))):
            vaciar()
        prefijo = nuevo
        parrafo.append(cuerpo.strip())
    vaciar()
    return "\n".join(salida)


def main():
    escribir = "--escribir" in sys.argv
    for rel, c in CURSOS.items():
        ruta = os.path.join(RAIZ, rel, NOMBRE)
        if not os.path.isdir(os.path.join(RAIZ, rel)):
            print("FALTA EL CURSO", rel)
            continue
        if os.path.exists(ruta):
            print("YA EXISTE, no se pisa:", rel)
            continue
        texto = documento(c)
        if escribir:
            with open(ruta, "w", encoding="utf-8") as f:
                f.write(texto)
        print(("escrito " if escribir else "vista   ") + rel, f"({texto.count(chr(10))} líneas)")


if __name__ == "__main__":
    main()
