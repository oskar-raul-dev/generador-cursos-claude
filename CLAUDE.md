# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

It holds only what applies to **every** course and every session; each course's own decisions live in
that course's `prompts/`. It is adapted from `zz-code/CLAUDE-sample-en.md`.

## What this repository is

**The product of this repository is the course generator in `zz-instrucciones/`**: the workflow
(stages E0–E9), course types, stage prompts, templates, production lessons and tools that let an LLM
design, prepare and write a course in Markdown. Unless the author says otherwise, work here is about
that machinery.

**Every course in this repository is a demo**: an example of what the generator produces, copied from
two sibling repositories (`../courses-ia-generated` and `../../job-interview-sept-2026`) where those
courses are actually produced and maintained. Use them to illustrate, test and validate
`zz-instrucciones/` (run its verifier against them, cite them as examples, draw lessons from their
`prompts/`), not as products to keep growing here. Edit a demo course only when asked, and say that the
change will not reach its original repository.

There is no build, no package manager and no test suite: the "code" is Markdown plus a few
standard-library Python tools. Courses are for **any audience**; each declares its own in its
`prompts/` (kickoff sheet, scope, guide). Never assume a reader the course did not declare.

`zz-instrucciones/` is currently **identical** in this repo and in both sibling repos. If you change it
here, say so, because the copies will drift.

## Repository layout

`zz-instrucciones/` and `zz-code/` are the working folders; everything else is demo courses, which
live at different depths depending on their type. List the directories to see what exists; this file
does not keep an inventory (the root `README.md` has the table).

- `cursos-<family>/<course>/` — full and legacy courses (`cursos-contenedores-cloud-infra/`,
  `cursos-lenguajes/`). A family directory is a pure container.
- `repaso-entrevistas/<area>/<NN-course>/` — interview review corpora (type *repaso*): chapters in
  `NN-block/` folders, questions without answers plus a separate *solucionario*, optional
  `06-talleres/`. `frameworks/02-spring-webflux` and `cloud/04-oracle-cloud` are empty (only a `.gitkeep`):
  courses **pending to be created**. In `arquitectura/`, only modules `01`–`04` are in this demo; `05`–`10` are
  cited by name without links.
- `preguntas-entrevista/` — interview question banks with inline answers; one verifier for the whole
  folder in its `prompts/`.
- `cursos-ia-solo-plan/` — courses where **only the base exists** (curriculum, guides, one `README.md`
  per unit), no written lessons, no `prompts/`, no verifier.
- `zz-instrucciones/` — the production machinery: workflow (stages E0–E9), course types, stage
  prompts, templates, production lessons, tools. **Start at `zz-instrucciones/QUICK-START.md`**;
  `zz-instrucciones/README.md` is the full map.
- `zz-code/` — all code sessions write to test a course's ideas, one directory per session
  (`<course>-<YYYYMMDD>-<hash>/`) with `MANIFIESTO.md` and `README.md`. Rules in `zz-code/README.md`.
  Courses never cite it. Its `salidas/` folders and *bitácoras* are historical records: their broken
  links point at the course as it was, so don't "fix" them.

## Commands

```bash
# Verify a course (run from the course root); optionally a single block
python3 prompts/verificar-corpus.py
python3 prompts/verificar-corpus.py 04-bloque

# Base checks on any folder, before the course has its own verifier; profiles per repository style
python3 zz-instrucciones/herramientas/verificador_base.py <course-folder> [block] \
        [--perfil=base|repaso|courses-ia|publicacion]

# Export every Mermaid diagram of a file or folder to PNG/SVG (mmdc, npx or docker engine)
python3 zz-instrucciones/herramientas/exportar-diagramas.py <path> --motor docker

# zz-code sessions
python3 zz-code/nuevo.py <course-slug> [--tanda T] [--proposito "..."]
python3 zz-code/limpiar.py <id>              # lists what is regenerable; --borrar deletes it
python3 zz-code/regenerar-rescates.py --comprobar   # rebuild transcript rescues aside and compare
```

Each course's `prompts/verificar-corpus.py` is a subclass of its own copy of `verificador_base.py`
(profiles `PerfilRepasoEntrevistas`, `PerfilCoursesIA`, `PerfilPublicacion`). Most course copies are an
**older version** than `zz-instrucciones/herramientas/verificador_base.py` (missing `TAG_DE_FASE`,
`PISTA_RE`, multi-line links); the changes are backwards compatible. Errors fail the run; *avisos* are
warnings.

## Order of authority

1. The course's own guide and decisions (`prompts/guia-de-estilo-y-convenciones.md`, the scope's
   `D-xx` table, the kickoff sheet).
2. This file.
3. The course's already published documents.

A course may override any default below, but **explicitly**: its guide names the default it replaces
and why. Silence means the default applies. Courses produced before `zz-instrucciones/` don't fully
comply; their current state is not a precedent against the rules.

## Course anatomy

- Published material at the course root: lessons or phases `00-slug.md`, appendices `a01-slug.md`, an
  optional story `00-historia-de-<slug>.md`, the git convention `00-convencion-de-git-y-tags.md` when
  the reader writes code (each phase links it from its 🏷️ closing block; the reader copies the course to
  their own repository and works there), living documents (`cuaderno-incidentes.md`, `BENCHMARKS.md`,
  `INSTINTOS.md`) only if the course uses them, and its `README.md` (some courses also
  `0-ESTRUCTURA-CURSO.md`).
- `prompts/` — the course's machinery (kickoff sheet, scope, proposals, guide, dictionary, naming
  contract, chapter templates, phase prompts, production plan, verifier). Not published. **Read it
  before writing or editing anything in the course.**
- Runnable code in `src/` (one folder per lesson, or a single project that grows with git tags), or a
  folder the course README names (`laboratorio/`, `taller/`).
- Optional tracks share the directory with a prefix (e.g. `ds01-…` in `python-for-java-devs`).

## Workflow

New course: follow `zz-instrucciones/QUICK-START.md` (kickoff sheet → scope → proposal → production
plan → batches). Copy each template from `zz-instrucciones/plantillas/` into the course's `prompts/`
only when its stage asks for it; from then on the copy rules. Existing course: read its
`prompts/plan-de-produccion.md` first (§3 status, §6 link debt, §7 latest log entry, §8 checklist) and
work only on the batch requested. Preparing and writing are separate sessions.

## Default editorial rules (when the course says nothing)

- **Language:** neutral Latin American Spanish with *tuteo* (no *vos*, no *vosotros*). Code,
  identifiers, commands and terminal output in English; comments inside code in English.
- **Claims:** "X is better for Y" needs a measurement, never an anecdote. No command, output, URL or
  number is invented.
- **Shape:** prose before lists; tables only to compare or map; one emoji per major heading, none in
  `###` unless the course allows it; callouts 📝 🧭 🧠 ⚠️ 💡 (repasos use their own list).
- **Exercises:** difficulty 🟢 🟡 🟠 🔴 🔥, each ending with a verifiable `**Criterio:**`; answers where
  the course decided, kept in sync in the same edit.
- **Diagrams:** the format the course decided (`D-12`); Mermaid only when asked for.
- **Story:** if the course has one, it is the source of truth for every narrative fact.
- **Anchors to headings with ⚠️ ⚖️ ⚙️** keep the U+FE0F that GitHub preserves (verifier error
  `ANCLA-FE0F`).
- Template placeholders `{{…}}` and `> ✏️ **Plantilla:**` lines must not survive in a course.

## Session rules (not negotiable)

- **Git belongs to the author.** No commits, no `git add/rm/mv`, no commit messages.
- **Delete only named files**, with `rm`; never whole directories, never `rm -rf`. Exception:
  `zz-code/limpiar.py --borrar`, run or authorized by the author.
- **Sequential work, no subagents**, unless the author asks for them.
- **Don't install anything or create costs.** If something is needed, say what and how.
- **Docker:** inventory first; label everything `curso=<slug>`; random ports on `127.0.0.1`
  (`-p 127.0.0.1::PORT`); remove only your own containers and volumes; never `prune` without a label
  filter.
- **All code goes to `zz-code/`** via `nuevo.py`; ephemeral output to its `salidas/`. Never the
  scratchpad, never `/tmp`. Keep the session directory's `README.md` current.
- **Ask before writing.** Every stage and phase prompt starts with a questions step.
- **Before closing a session:** run the course verifier and update the production plan.

## When unsure

Tone or form → the course's guide. Structure → its proposal and plan. A claim → measure it or drop it.
A decision that belongs to the author → ask, with your recommended option first. Everything else →
`zz-instrucciones/`.
