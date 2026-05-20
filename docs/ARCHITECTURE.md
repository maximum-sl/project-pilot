# Architecture

`briefs` is a tiny file-based project management tool. The whole design is
five invariants and one file format.

## The five invariants

1. **brief.md is the contract.** Every project is one file. Read it to know
   the state. Edit it (via `pilot`) to change the state.

2. **The fenced `project-state` JSON block is the single source of truth.**
   The schema is small and frozen (see `bin/pilot`).

3. **Every other section in brief.md is a projection.** The Goal, Definition
   of done, Phases, etc. are auto-written from the JSON block on every
   mutation. Don't edit them directly , they'll be overwritten.

4. **`pilot` is the only writer.** Concurrent sessions are safe because every
   mutating verb takes an `mkdir`-based lock around the read-modify-write
   cycle. No race conditions, no corrupted state.

5. **Executors call `pilot status`, never edit brief.md.** When you hand a phase
   to an AI assistant, the assistant runs `pilot status` to mark progress.
   It does not touch the file. This keeps the invariant cheap to enforce.

## brief.md layout

```
---
slug: launch
title: Ship the v1 launch
tier: standard
status: active
created: 2026-05-19
---

## Goal
<!-- auto-projected by pilot , edit phases, not this -->
Ship v1 in 4 weeks with at least 10 beta users.

## Definition of done
<!-- auto-projected by pilot -->
- 10 beta users signed up
- v1 deployed to production
- feedback loop live

## Phases
<!-- auto-projected by pilot -->
- p1 Spec [me] todo
- p2 Build [me] todo
- p3 Beta outreach [me] todo

## Notes
(hand-authored, optional, preserved across writes)

```project-state
{
  "schema_version": 1,
  "slug": "launch",
  "title": "Ship the v1 launch",
  "tier": "standard",
  "project_status": "active",
  "goal": "...",
  "definition_of_done": ["..."],
  "phases": [{ "id": "p1", ...}],
  "metadata": {},
  "created": "2026-05-19T...",
  "updated": "2026-05-19T..."
}
```
```

## Phase schema

```json
{
  "id": "p1",
  "title": "Spec",
  "outcome": "v1 scope locked",
  "acceptance_criteria": ["spec doc reviewed", "cut scope agreed"],
  "owner": "me",
  "executor": "me",
  "status": "todo",
  "depends_on": [],
  "dates": {},
  "note": null,
  "last_status_change": null,
  "completed_at": null
}
```

Status values: `todo`, `doing`, `blocked`, `needs-decision`, `done`, `cancelled`.

## Render pipeline

```
brief.md
  │
  ├── pilot render <slug> checklist        markdown checklist (default)
  ├── pilot render <slug> kanban           status-grouped markdown
  ├── pilot render <slug> flowchart        mermaid dep diagram
  └── pilot render <slug> html             single-file HTML view
                ↓
        templates/plan.html.tmpl + scripts/render_html.py
                ↓
        briefs/<slug>/plan.html
                ↓
        scripts/pilot-server.sh serves it at http://127.0.0.1:8765/<slug>/plan.html
                ↓
        clickable from any chat / editor
```

## Concurrency

Every mutating verb (`init`, `set-project`, `add-phase`, `status`) takes a
lock at `briefs/<slug>/.locks/project.lock` via `mkdir` (atomic on POSIX).
Reads (`show`, `list`, `render`) do not lock. The lock window is small
(read-modify-write of a single JSON document, no I/O dependency).

If two sessions try to mutate the same brief at the same time, one wins and
the other retries up to 15 times (1.5s budget). After that it returns an
error rather than silently losing the write.

## Why this is small on purpose

The original implementation of this pattern lived inside a personal agent
framework and grew dispatch loops, lease management, lock reapers, and
worker-launching subroutines. Useful for that framework, but coupling to
a specific AI vendor.

The public `briefs` package strips that complexity. The only writer is `pilot`.
The only "dispatch" is `pilot hint`, which prints a prompt , the operator (or
an AI session they control) decides where it goes. This stays vendor-neutral
and keeps the tool under 1000 lines of code.

If you want auto-dispatch to a specific AI vendor, fork the integration in
`integrations/<vendor>/` and wire it in. Don't try to make `pilot` itself
vendor-aware.
