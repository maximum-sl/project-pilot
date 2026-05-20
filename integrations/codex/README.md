# Project Pilot , Codex integration

> Placeholder. Contributions welcome.

`pilot` is brand-agnostic and works as a standalone CLI. To integrate it into
Codex, mirror the Claude Code pattern:

- A "skill" or "tool definition" that tells Codex how to handle `/project`-style
  commands by shelling to `pilot`.
- A slash command (if Codex supports them) or an equivalent invocation pattern.
- A README in this folder describing the install steps.

## What Codex needs to know about `pilot`

- It's a standalone bash CLI.
- It's the only writer of `briefs/<slug>/brief.md`. Never edit brief files
  directly.
- Verbs: `init`, `set-project`, `add-phase`, `status`, `validate`, `show`,
  `list`, `render`, `open`, `hint`.
- Resume a project with `pilot open <slug>` (renders + opens plan.html in browser).
- Transition phase state with `pilot status <slug> <phase> <state>`.
- Print a dispatch instruction with `pilot hint <slug> <phase>` , this is the
  text Codex itself should consume when picking up a phase.

If you build this integration, please open a PR.
