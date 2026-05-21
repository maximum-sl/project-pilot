# Project Pilot

> Plan multi-week projects, see them visually, hand phases off to AI to execute.

Project Pilot is a small system for getting from "I have an ambitious goal" to
"I actually finished it." It guides you through structured intake, breaks the
work into phases, gives you a polished visual plan, and lets you hand any phase
off to an AI assistant to execute, with status writing back automatically.

```bash
pilot init launch "Ship the v1 launch"        # guided intake
pilot open launch                             # opens plan in browser
pilot status launch p1 done "shipped"         # mark a phase done
pilot next --executor=cron --json             # list ready phases for a worker
pilot hint launch p2 --json                   # fetch work package as JSON
pilot                                         # list active projects
```

The plan file (`brief.md`) is the contract. The CLI is the only writer. AI
assistants read the file, work on phases, and call `pilot status` to update
state.

## Why this exists

AI assistants are great at executing well-scoped phases of work. They're
terrible at holding multi-week project context across sessions. Most project
management tools assume the operator is the source of truth and the assistant
is a helper. Project Pilot flips that: the **plan file is the contract**, and
any session (human or AI) can pick up cold by reading it.

A `brief.md` for each project contains a machine-truth JSON block plus
auto-projected human sections. A polished single-file HTML plan ships out of
the box and opens in your browser via a tiny loopback server.

## What you get

- `pilot` CLI for managing project briefs (init, add phases, transition status, render)
- Polished single-file HTML plan with status-aware phase cards
- Local loopback server for clickable plan URLs from any chat or editor
- Brand-agnostic AI dispatch hints (works with Claude Code, Codex, Aider, anything)
- Claude Code skill integration (slash command + skill bundle)
- Minimal: ~700 lines total, no runtime deps beyond Python 3.9+, bash, and `jq`

## Quick start

```bash
git clone https://github.com/YOURNAME/project-pilot.git
cd project-pilot
./bin/pilot init launch "Your first project"
```

That walks you through intake, locks a `brief.md`, and prints the path so you
can fill in the goal, definition of done, and phases.

To install globally:

```bash
ln -s "$PWD/bin/pilot" /usr/local/bin/pilot
```

Then `pilot` works from any directory. Set `PILOT_ROOT` to choose where briefs
are stored:

```bash
export PILOT_ROOT=~/briefs    # add to your shell rc
```

## Architecture in one breath

```
brief.md (the contract)
├── YAML frontmatter
├── projected human sections (auto-written by pilot)
├── ## Notes (hand-authored, optional)
└── ```project-state``` JSON block (machine truth)

bin/pilot                    single writer, mkdir-locked, atomic mv
scripts/render_html.py       brief.md → plan.html via templates/plan.html.tmpl
scripts/pilot-server.sh      127.0.0.1:8765 static server, no cache, no listing
```

The file format is specified in [`PROTOCOL.md`](PROTOCOL.md). The `pilot` CLI
in this repo is the reference implementation; alternate implementations
(Codex client, web dashboard, cron worker, IDE plugin) are encouraged.

Five invariants:

1. The fenced `project-state` JSON block is the single source of truth.
2. Every other section in `brief.md` is a projection. Only `## Notes` is
   hand-authored.
3. `pilot` is the only writer. Concurrent sessions are safe (`mkdir` lock).
4. Executors call `pilot status`, never edit `brief.md` directly.
5. Acceptance criteria are required for any executor other than `me`.

## AI assistant integration

Project Pilot is brand-agnostic. The `integrations/` folder ships skill
bundles for popular AI coding assistants. Pick the one you use and follow its
README to install.

```
integrations/
├── claude-code/    Claude Code skill + slash command, ready to symlink
└── codex/          (placeholder, contributions welcome)
```

For headless / cron-style execution, see [`examples/cron-worker/`](examples/cron-worker/)
, a ~70-line bash worker that polls for ready phases via `pilot next`, fetches
work packages via `pilot hint --json`, runs them, and writes status back. A
second conforming implementation of the protocol with no shared code.

Don't use an AI assistant? `pilot` is a useful standalone CLI on its own.

## Phase tiers

- **quick** , one-shot tasks, minimal phases, no dispatch coupling
- **standard** , multi-phase, multi-week, dependency tracking (most common)
- **deep** , large phase count, planning workspace alongside the brief

## Render views

| View | Use |
|---|---|
| `checklist` (default) | terminal markdown checklist |
| `kanban` | status-grouped markdown |
| `flowchart` | mermaid dependency diagram |
| `html` | polished single-file HTML for human review |

## Configuration

| Env var | Default | What |
|---|---|---|
| `PILOT_ROOT` | `$PWD/briefs` | Where briefs are stored |
| `PILOT_SERVER_PORT` | `8765` | Server port for `pilot open` |
| `PILOT_STATE_DIR` | `$PILOT_ROOT/.tmp` | Where the server keeps pid + log |

## Not for

- Single-session tasks , just use a notes app
- Recurring tasks , use cron or a job runner
- Real-time team collaboration , use Linear or Notion

## Roadmap

- [x] HTML render view with phase status colors
- [x] Local server for clickable URLs from any chat / editor
- [x] Claude Code integration
- [ ] Codex integration
- [ ] Phase templates (productized consulting, SaaS launch, research project)
- [ ] Acceptance auditor (third-party verifier before `done` is accepted)
- [ ] Live update loop (browser auto-refreshes when phases change)

## License

MIT
