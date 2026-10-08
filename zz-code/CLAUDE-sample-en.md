# CLAUDE.md

This file guides Claude Code in this repository. It holds only what applies to **every** course and
every session; each course's own decisions live in that course's `prompts/`.

## What this repository is

A collection of AI-assisted courses written in Markdown, for **any audience**: from people who have
never programmed to senior engineers. There is no default reader. Each course declares its own
audience, depth and assessment in its kickoff sheet (`prompts/ficha-de-arranque.md`) and its scope
document (`prompts/alcance-del-proyecto.md`); never assume a reader the course did not declare.

## Repository layout

- `cursos-<family>/<course>/` — the published courses, grouped by subject family. A family directory
  is a pure container (no README, no content). A course may group sub-courses one level deeper. List
  the directories to see what exists; this file does not keep an inventory.
- `propuestas-cursos/` — drafts that are not courses yet. Read its `README.md` first. Never link to a
  proposal from published material.
- `zz-instrucciones/` — the production machinery: workflow (stages E0–E9), course types, stage
  prompts, templates, production lessons and the verifier. **Start at `zz-instrucciones/QUICK-START.md`.**
- `zz-code/` — all the code sessions write to test a course's ideas, one directory per session, each
  with a `MANIFIESTO.md` and a `README.md` explaining how to rerun and measure every test. Rules in
  `zz-code/README.md`. Courses never cite it.
- Personal or private folders of the author (if any, named here): never edit or cite them unless asked.

## Order of authority

1. The course's own guide and decisions (`prompts/guia-de-estilo-y-convenciones.md`, the scope's
   `D-xx` table, the kickoff sheet).
2. This file.
3. The course's already published documents.

A course may override any default below, but **explicitly**: its guide names the default it replaces
and why. Silence means the default applies.

## Course anatomy

- Published material at the course root: lessons or phases `00-slug.md`, appendices `a01-slug.md`, an
  optional story `00-historia-de-<slug>.md`, the git convention `00-convencion-de-git-y-tags.md` when
  the reader writes code (each phase links it from its 🏷️ closing block; the reader copies the course to
  their own repository and works there, never in this one), living documents (`cuaderno-incidentes.md`,
  `BENCHMARKS.md`, `INSTINTOS.md`) only if the course uses them, and its `README.md`.
- `prompts/` — the course's machinery: kickoff sheet, scope, proposals, guide, dictionary, naming
  contract, chapter templates, phase and appendix prompts, production plan, verifier. It is kept as
  reference and is **not** published. Read it before writing or editing anything in the course.
- Runnable code in `src/` (one folder per lesson, named like the lesson, or a single project that
  grows with git tags), or a folder with its own name (`laboratorio/`, `taller/`) that the course
  README names.
- Optional tracks share the directory with a prefix: phases `beNN-slug.md`, appendices `bea-NN-slug.md`,
  their own prompts and incident notebook as new files, and git tags in their own namespace.

## Workflow

New course: follow `zz-instrucciones/QUICK-START.md` (kickoff sheet → scope → proposal → production
plan → batches). Existing course: read its `prompts/plan-de-produccion.md` first — §3 status, §6 link
debt, §7 latest log entry, §8 checklist — and work only on the batch requested. Preparing and writing
are separate sessions. The README of a course and its structure document are written at the end, from
what actually exists.

## Default editorial rules (when the course says nothing)

- **Language:** neutral Latin American Spanish with *tuteo* (no *vos*, no *vosotros*, no peninsular
  terms). Code, identifiers, commands and terminal output in English; comments inside code in English.
- **Tone:** collegial and adapted to the declared audience. Honest about trade-offs: every option wins
  somewhere and loses somewhere, and losses carry numbers.
- **Claims:** "X is better for Y" needs a measurement (in `BENCHMARKS.md` or the lesson's measurement
  block), never an anecdote. No command, output or number is invented.
- **Shape:** prose before lists; tables only to compare or map; one emoji per major heading;
  callouts 📝 context · 🧭 principle · 🧠 mental model · ⚠️ pitfall · 💡 insight.
- **Exercises**, when the course has them: difficulty 🟢 very easy · 🟡 easy · 🟠 medium · 🔴 hard ·
  🔥 boss, with the count and mix the course declared. Every exercise ends with a verifiable
  `**Criterio:**`, and answers go where the course decided (folded under the exercise, or a separate
  answer document kept in sync in the same edit).
- **Diagrams:** the format the course decided (`D-12`); Mermaid only when it was asked for.
- **Story:** if the course has one, it is the source of truth for every narrative fact; no lesson
  invents a name, figure or rule that is not there.
- **Close every course with an honest verdict:** when NOT to use what it taught.
- **File names:** `<prefix>-<number>-<topic>`, lowercase, hyphenated, zero-padded. Don't mix appendix
  styles inside one course.

## Session rules (not negotiable)

- **Git belongs to the author.** No commits, no `git add`, `git rm` or `git mv`; don't offer commit
  messages. Read-only git (`status`, `log`, `diff`) is fine. Leave the tags the plan asks for written
  in the plan's log.
- **Delete only named files**, with `rm`; never whole directories, never `rm -rf`. The only exception
  is `zz-code/limpiar.py --borrar`, run or authorized by the author.
- **Sequential work, no subagents**, unless the author asks for them.
- **Don't install anything or create costs** on the author's machine. If something is needed, say what
  and how; the author installs it.
- **Docker:** take an initial inventory to a log; label everything `curso=<slug>`; random high ports
  bound to `127.0.0.1` (`-p 127.0.0.1::PORT`), never the defaults; when done, remove only your
  containers with their volumes. Never `prune` without a label filter, never touch what already
  existed, and restore any machine setting you changed.
- **All code goes to `zz-code/`:** create the session directory with
  `python3 zz-code/nuevo.py <course-slug>`; ephemeral output goes to its `salidas/`. Never the
  scratchpad, never `/tmp`. A one-off command that produces something citable is copied to a file, and
  the directory's `README.md` is kept up to date as you test.
- **Ask before writing.** Every stage and phase prompt starts with a questions step; if a new doubt
  appears mid-session, stop and ask. Record the literal error before fixing it.
- **Before closing a session:** run the course verifier
  (`python3 prompts/verificar-corpus.py`, or `zz-instrucciones/herramientas/verificador_base.py
  <course-folder>` before it exists) and update the plan (§3, §6, §7, §8) with traps, default decisions,
  resources left running and tags for the author.

## Memory

The production plan is the course's state; memory keeps **pointers**, not content: where the plan is,
what comes next, decisions the author made that the documents don't show, and traps shared by several
courses. Don't save what the repository already records.

## When unsure

Tone or form → the course's guide. Structure → its proposal and plan. A claim → measure it or drop it.
A decision that belongs to the author → ask, with your recommended option first. Everything else →
`zz-instrucciones/`.
