---
name: pilot
description: >
  Guided project intake, living brief, visual layer, and agent handoff via the
  `pilot` CLI. Use to start a project (new), resume one (slug), check status,
  render a view, transition phase state, or print a dispatch hint.
triggers: ["/project", "start a project", "plan this project", "manage this project", "pick up <slug>"]
---

# pilot

`briefs` is a project management tool, not a chat helper. The `pilot` CLI is the
only writer of brief files. This skill is the agent-facing wrapper around it.

## Invariants (never violate)

1. brief.md is the contract.
2. The fenced `project-state` JSON block is the single source of truth.
3. Every other section in brief.md is a projection. Only `## Notes` is hand-authored.
4. `pilot` is the only writer. Never edit brief.md directly.
5. Acceptance criteria are required for any executor != me.

## Intake mode (`/project new "<goal>"`)

1. One question at a time. After 1-2 answers infer the tier (quick / standard / deep).
2. Collect: goal, definition_of_done (list), constraints, phases. Per phase:
   outcome, acceptance_criteria, owner/executor, depends_on.
   `acceptance_criteria` is REQUIRED for any executor != me.
3. One review gate (show the planned phases). Then:
   - `pilot init <slug> "<title>" <tier>`
   - `pilot set-project <slug> goal '"<goal>"'`
   - `pilot set-project <slug> definition_of_done '["a","b"]'`
   - `pilot set-project <slug> metadata '{"Owner":"...", ...}'` (optional, populates the HTML header strip)
   - one `pilot add-phase <slug> '<json>'` per phase
   - `pilot validate <slug>` (must print `ok`)
4. `pilot open <slug>` , render plan.html, ensure the local pilot-server, open
   in the default browser, print the clickable URL.

## Resume mode (`/project <slug>`)

Cold-start onboarding into an existing project. Steps:

1. `pilot open <slug>` , render if stale, ensure pilot-server, open in browser.
2. `pilot show <slug>` , read the projected brief in terminal for context.
3. Brief the operator in ~5 lines: which phases are `doing` (and what acceptance
   criteria are still open on them), which phases are `todo` and unblocked,
   and 1-3 concrete next actions. Pull from any phase-specific deliverable
   folders (`briefs/<slug>/p*-*/`) that exist.
4. Surface the localhost URL. Do not surface raw file paths.

If `<slug>` does not match any brief, list active briefs (`pilot`) and offer to
create the slug via `pilot init`.

## Status transitions (`/project status <slug> <phase> <state> [note]`)

Valid states: `todo`, `doing`, `blocked`, `needs-decision`, `done`, `cancelled`.

```
pilot status <slug> <phase> <state> "<short note>"
```

The CLI atomically rewrites brief.md and re-projects the human sections.

## Dispatch hint (`/project hint <slug> <phase>`)

`pilot` does not run AI workers. It prints the prompt you'd hand to an executor
(Claude Code, Codex, Aider, etc.) for that phase. The hint includes the phase
outcome, acceptance criteria, and the exact `pilot status ... done` command to
run when criteria are met.

This is intentionally manual. Auto-dispatch couples the tool to one AI vendor.
Manual dispatch lets you route any phase to any executor on any day.

## Render views

`pilot render <slug> <view>`:

- `checklist` (default) , terminal markdown checklist
- `kanban` , status-grouped markdown
- `flowchart` , mermaid dependency diagram
- `html` , polished single-file plan.html

`pilot open <slug>` is the canonical "show me the plan" command. Prefer it over
printing file paths , VS Code routes file paths to its editor, not the
browser. The localhost URL from `pilot open` IS clickable from chat.

## Tiers (rule of thumb)

- **quick** , 1-3 phases, one-shot, no executor handoffs needed
- **standard** , 4-8 phases, multi-week, dependency tracking, optional handoffs
- **deep** , 8+ phases, multi-month, dedicated planning workspace alongside

## Anti-patterns

- Editing brief.md by hand (except `## Notes`)
- Mutating phase state without going through `pilot status`
- Adding executor != me without acceptance criteria (CLI rejects it on validate)
- Using briefs for single-session work (use a notes app)
- Using briefs for recurring tasks (use cron)
