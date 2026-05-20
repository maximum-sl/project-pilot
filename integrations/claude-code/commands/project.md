---
description: Project briefs , intake, resume, status, render, dispatch hint. Wraps `pilot` (the single writer) and the briefs skill.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /project

Parse argv:

- `/project` → `pilot` (lists active briefs). Offer `new` or to resume a listed slug.
- `/project <slug>` → invoke **briefs** skill, resume mode (loads brief, opens plan in browser, surfaces current state + next actions).
- `/project new "<goal>"` → invoke **briefs** skill, intake mode.
- `/project status <slug> <phase> <state> [note]` → `pilot status <slug> <phase> <state> "<note>"`.
- `/project render <slug> [view]` → `pilot render <slug> <view>`.
- `/project open <slug>` → `pilot open <slug>` (re-renders if stale, opens plan in browser).
- `/project hint <slug> <phase>` → `pilot hint <slug> <phase>` (prints the dispatch instruction for the phase's executor).
- `/project show <slug>` → `pilot show <slug>` (terminal view).

If `<slug>` does not match a known verb AND a brief exists at `briefs/<slug>/brief.md`, treat it as resume mode. If the slug does not exist, offer to create it via `new`.

Never edit brief.md directly. Every mutation goes through `pilot`.
