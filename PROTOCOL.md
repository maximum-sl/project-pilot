# Project Pilot Protocol , v0

> A tiny protocol for giving AI agents durable work packages, with acceptance
> criteria, dependencies, status, and evidence. Local-first. File-based.
> Brand-agnostic.

This document specifies the file format and invariants of a Project Pilot
**brief**. Any tool that reads or writes briefs in compliance with this
document is a *conforming implementation* and can interoperate with any other.

The reference implementation is the `pilot` CLI in this repository. Other
implementations (a Codex client, a web dashboard, a cron worker, a VS Code
extension) are encouraged.

**Status:** Draft. Stable as of v0.1.0. Versioned via `schema_version` in
every brief.

---

## 1. Purpose

A brief is a *durable work package* shared between a human operator and one or
more AI agents. It encodes:

- **What** the work is (goal, definition of done, phases)
- **Who** does each phase (executor)
- **When** it's complete (acceptance criteria)
- **What state** it's in (status, evidence, notes)
- **How** phases relate (dependencies)

The protocol's job is to make this package readable and writable by humans,
AI agents, and arbitrary tooling, without anyone needing to know about
anyone else.

---

## 2. File layout

Each brief is one Markdown file at:

```
<root>/<slug>/brief.md
```

Where `<root>` is the implementation's configured briefs root (the reference
CLI uses `$PILOT_ROOT`, defaulting to `./briefs`).

The file MUST contain, in order:

1. YAML frontmatter (`---`-delimited)
2. Optional projected human sections (auto-written from the JSON block)
3. Optional `## Notes` section (the only hand-authored prose region)
4. A fenced `project-state` JSON code block

Example minimal brief:

````markdown
---
slug: launch
title: Ship the v1 launch
tier: standard
status: active
created: 2026-05-19
---
## Notes

```project-state
{
  "schema_version": 1,
  "slug": "launch",
  "title": "Ship the v1 launch",
  "tier": "standard",
  "project_status": "active",
  "goal": "Ship v1 in 4 weeks.",
  "definition_of_done": ["v1 deployed", "10 beta users"],
  "phases": [],
  "metadata": {},
  "created": "2026-05-19T15:00:00Z",
  "updated": "2026-05-19T15:00:00Z"
}
```
````

---

## 3. Source of truth

The fenced `project-state` JSON block is the **single source of truth**.
All other sections in `brief.md` are projections of the JSON block, except
`## Notes` (hand-authored, optional, preserved across writes).

Conforming implementations:

- MUST read state from the JSON block, not from projected sections.
- MUST regenerate projected sections from the JSON block on every write.
- MUST preserve `## Notes` content verbatim across writes.
- MUST NOT mutate any field outside the JSON block via automated write paths.

---

## 4. Schema

### 4.1 Project object

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | int | yes | Currently `1`. |
| `slug` | string | yes | URL-safe identifier. Matches the parent directory name. |
| `title` | string | yes | Human-readable project name. |
| `tier` | string | yes | One of `quick`, `standard`, `deep`. |
| `project_status` | string | yes | One of `active`, `paused`, `archived`. |
| `goal` | string | yes | One-paragraph plain-language goal. |
| `definition_of_done` | string[] | yes | Concrete outcomes that mark the project complete. |
| `phases` | Phase[] | yes | Ordered list of phases (see §4.2). |
| `metadata` | object | no | Free-form labeled fields (e.g., owner, budget, window). Conforming UIs MAY render these in a header strip. |
| `created` | string (ISO 8601 UTC) | yes | First-write timestamp. |
| `updated` | string (ISO 8601 UTC) | yes | Last-write timestamp. |

### 4.2 Phase object

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | URL-safe. Unique within the project. Convention: `p1`, `p2`, ... |
| `title` | string | yes | One-line phase name. |
| `outcome` | string | yes | What completion of this phase delivers. |
| `acceptance_criteria` | string[] | conditional | REQUIRED if `executor != "me"`. Concrete, checkable items. |
| `owner` | string | no | Who is accountable. Default `"me"`. |
| `executor` | string | no | Who does the work. Default `"me"`. Conventional values: `me`, `claude`, `codex`, `aider`, or any custom executor name a tool implements. |
| `status` | string | yes | See §4.3. |
| `depends_on` | string[] | no | Other phase `id`s that must reach `done` before this one is eligible. |
| `dates` | object | no | Free-form scheduling fields (e.g., `start`, `due`). |
| `note` | string | no | One-line state note. Cleared on each transition unless explicitly set. |
| `last_status_change` | string (ISO 8601 UTC) | no | Set automatically on transition. |
| `completed_at` | string (ISO 8601 UTC) | no | Set when status transitions to `done`. |

### 4.3 Status states

Phases use a closed set of status values:

- `todo` , not yet started
- `doing` , in progress
- `blocked` , waiting on something external; `note` SHOULD describe what
- `needs-decision` , waiting on a human decision; `note` SHOULD describe the question
- `done` , complete; acceptance criteria met
- `cancelled` , abandoned; not counted toward progress

Valid transitions are unrestricted (any status to any status is permitted),
to let tools recover from edge cases. Implementations MAY warn on unusual
transitions (e.g., `done` → `todo`) but MUST NOT block them.

---

## 5. The five invariants

A conforming implementation MUST enforce these invariants:

1. **The fenced `project-state` JSON block is the single source of truth.**
   No state lives elsewhere.

2. **Every other section of brief.md is a projection.** They are derived from
   the JSON block on every write. Only `## Notes` is hand-authored.

3. **A single-writer discipline.** While brief.md is shared between sessions
   and tools, only one writer may hold the file at a time. The reference
   implementation uses `mkdir`-based locks at `<root>/<slug>/.locks/project.lock`.
   Concurrent writers MUST acquire and release this lock around any mutation.

4. **Executors call the status API, never edit brief.md.** When work is
   handed off to an executor (a Claude session, a Codex worker, a cron job),
   that executor reports state changes by calling its implementation's status
   verb (e.g., `pilot status <slug> <phase> done "evidence"`). Executors
   MUST NOT edit brief.md directly.

5. **Acceptance criteria are required for any executor other than `me`.**
   A phase with `executor != "me"` and an empty `acceptance_criteria` array
   is invalid. Implementations MUST reject such phases at write time.

---

## 6. Conformance

A tool is a **read-conforming implementation** if it:

- Parses brief.md per §2 and §4.
- Treats the JSON block as the source of truth per §3.
- Tolerates unknown fields (forward-compatibility).

A tool is a **write-conforming implementation** if it additionally:

- Regenerates projected sections per §3.
- Acquires the lock per invariant 3.
- Validates per §4 (especially the `executor` / `acceptance_criteria` rule).
- Updates `updated`, `last_status_change`, and `completed_at` timestamps
  consistent with §4.

An **executor-conforming implementation** is a tool that performs work on
behalf of an executor and:

- Reads phase outcome and acceptance criteria from brief.md.
- Reports state changes through the implementation's status verb, never
  by writing brief.md directly.

---

## 7. Versioning

Briefs declare `schema_version`. Breaking changes increment this number.
Implementations MUST:

- Refuse to write briefs with a `schema_version` newer than they support.
- Read briefs with an older `schema_version` if backward-compatible.

This protocol is `schema_version: 1`. v0.x updates remain backward-compatible.

---

## 8. Extensions

The schema is intentionally small. Conforming implementations MAY add fields
under the `metadata` object or as new top-level keys, provided:

- They tolerate other implementations not knowing about those fields.
- They never store state required for protocol-level invariants outside the
  defined schema.

If an extension becomes broadly useful, propose it for the next schema
version via the repository's issue tracker.

---

## 9. Reference implementation

The `pilot` CLI in this repository is the reference implementation. The
verbs that maintain protocol compliance are:

| Verb | Effect on protocol |
|---|---|
| `pilot init` | Creates a new conforming brief.md |
| `pilot set-project` | Mutates project-level fields |
| `pilot add-phase` | Appends a phase (validates §4.2 and §5) |
| `pilot status` | Transitions a phase; executors call this |
| `pilot validate` | Checks conformance against this spec |
| `pilot show` | Read-only terminal view |
| `pilot render` | Read-only render to other formats (markdown, HTML, mermaid) |
| `pilot open` | Read-only browser view (renders + serves) |
| `pilot next` | Read-only , lists phases that are ready to run (status=todo and all dependencies done). Supports `--executor=X` to filter by executor and `--json` for machine-readable output. The protocol's eligibility query. |
| `pilot hint` | Read-only , prints the executor handoff prompt. Supports `--json` for machine-readable output. The protocol's handoff query. |

For executor-conforming implementations (cron workers, IDE plugins, AI vendor
adapters), the canonical loop is:

```
next  →  hint  →  (do the work)  →  status
```

`pilot next --json` returns ready phases (slug + phase id + executor + title +
outcome). `pilot hint --json` returns the full work package (outcome,
acceptance criteria, prompt, status command). `pilot status` writes back. No
implementation needs to parse `brief.md` itself.

The CLI is intentionally minimal. The interesting part is this spec.

---

## 10. Non-goals

This protocol does NOT address:

- **Distribution.** Briefs are local-first. Sync between machines is left to
  the implementation (e.g., git, iCloud, S3, Dropbox).
- **Authentication.** Implementations may layer auth on top, but the protocol
  itself is single-user/single-machine by default.
- **Real-time collaboration.** Briefs are operated by one writer at a time
  (the lock). Multi-user shared state is not in scope for v0.
- **Workflow automation.** The protocol describes state; it does not
  describe rules for transitions, escalations, or notifications.

These are deliberately left to higher layers so the protocol stays small.

---

## 11. Acknowledgements

The shape of this protocol owes obvious debt to Git's file-based local-first
model. The five-invariant discipline borrows from how robust shell tooling
treats locks and projections (Make's `.PHONY`, Git's working tree vs. index).

The "AI agent as executor" framing is new. The hope is that this protocol
becomes the boring middle layer between operators with goals and assistants
with the ability to execute them.
