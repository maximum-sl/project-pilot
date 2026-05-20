# Project Pilot , Claude Code integration

A skill + slash command bundle for using `briefs` inside Claude Code.

## Install

```bash
# from your project root (or anywhere you want briefs available)
ln -s "$(realpath ~/code/project-pilot)/integrations/claude-code/skill" \
      .claude/skills/pilot

ln -s "$(realpath ~/code/project-pilot)/integrations/claude-code/commands/project.md" \
      .claude/commands/project.md

# also expose the pilot CLI on your PATH
ln -s "$(realpath ~/code/project-pilot)/bin/pilot" /usr/local/bin/pilot
```

Restart Claude Code. You'll have:

- `/project` , list active briefs, offer to create or resume
- `/project new "<goal>"` , guided intake
- `/project <slug>` , resume (opens plan in browser, briefs Claude on state)
- `/project status <slug> <phase> <state>` , transition a phase
- `/project render <slug> [view]` , render a view
- `/project open <slug>` , open plan in browser

The skill at `briefs/SKILL.md` tells Claude how to handle each verb.

## How it works

The skill loads when `/project` is invoked. It reads brief files via `pilot show`,
mutates them via `pilot` verbs only (never editing brief.md directly), and surfaces
the polished HTML plan via `pilot open` (which spins up a loopback static server
so the URL is clickable from VS Code's chat panel).

The skill follows five invariants that match the CLI:

1. brief.md is the contract
2. The fenced `project-state` JSON block is the source of truth
3. `pilot` is the only writer
4. Executors call `pilot status`, never edit brief.md directly
5. Acceptance criteria are required for any executor != me

## Customising

The skill is intentionally generic. If you want project-specific behavior
(e.g., always run a humanizer pass when writing content phases), fork the
skill into your own `.claude/skills/pilot-custom/` and add your steps there.
