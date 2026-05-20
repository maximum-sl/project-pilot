# Quickstart

Five minutes from clone to your first project plan.

## Install

```bash
git clone https://github.com/YOURNAME/project-pilot.git
cd project-pilot
ln -s "$PWD/bin/pilot" /usr/local/bin/pilot
```

Requires bash, Python 3.9+, and `jq` (`brew install jq` on macOS).

## Your first brief

```bash
mkdir -p ~/my-projects && cd ~/my-projects
pilot init launch "Ship the v1 launch" standard
```

`pilot` creates `./briefs/launch/brief.md`. Now fill it in.

```bash
pilot set-project launch goal '"Ship v1 in 4 weeks with at least 10 beta users."'
pilot set-project launch definition_of_done '["10 beta users signed up", "v1 deployed to production", "feedback loop live"]'
```

Add phases:

```bash
pilot add-phase launch '{"id":"p1","title":"Spec","outcome":"v1 scope locked","acceptance_criteria":["spec doc reviewed","cut scope agreed"],"executor":"me"}'
pilot add-phase launch '{"id":"p2","title":"Build","outcome":"v1 deployed","acceptance_criteria":["staging works","prod deployed","monitoring live"],"executor":"me","depends_on":["p1"]}'
pilot add-phase launch '{"id":"p3","title":"Beta outreach","outcome":"10 users active","acceptance_criteria":["20 invites sent","10 signups","feedback channel live"],"executor":"me","depends_on":["p2"]}'

pilot validate launch
```

Validate prints `ok` when the brief is well-formed.

## Open the plan

```bash
pilot open launch
```

This:
1. Renders `briefs/launch/plan.html` (the polished HTML view)
2. Starts a local loopback server on 127.0.0.1:8765
3. Opens the URL in your default browser

Click around. Phase cards are colored by status. Dependencies are visible on
each card. The progress bar at top updates as you transition phases.

## Work the plan

When you start a phase:

```bash
pilot status launch p1 doing "kicking off spec work"
```

When it's blocked:

```bash
pilot status launch p2 blocked "waiting on infra team for staging access"
```

When it's done:

```bash
pilot status launch p1 done "spec doc at github.com/x/y, scope cut by 20%"
```

Refresh the browser. The card flips to the right color. Dependents become
eligible.

## Hand a phase to an AI assistant

If a phase has `executor != me`:

```bash
pilot hint launch p2
```

Prints the prompt to copy-paste into your AI assistant. Includes the outcome,
acceptance criteria, and the exact `pilot status` command to run when criteria
are met.

## Useful patterns

```bash
pilot                            # list active briefs
pilot show launch                # terminal view
pilot render launch checklist    # markdown checklist
pilot render launch kanban       # status-grouped
pilot render launch flowchart    # mermaid dep diagram
pilot render launch html         # plan.html (use `pilot open` to also open it)
```

## Configuration

| Env var | Default | What |
|---|---|---|
| `PILOT_ROOT` | `$PWD/briefs` | Where to store briefs |
| `PILOT_SERVER_PORT` | `8765` | Server port for `pilot open` |
| `PILOT_STATE_DIR` | `$PILOT_ROOT/.tmp` | Where the server keeps pid + log |

To use a fixed briefs root across all directories:

```bash
export PILOT_ROOT=~/briefs
```

Add to your shell rc.
