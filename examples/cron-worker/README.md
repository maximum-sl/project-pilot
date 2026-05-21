# cron-worker

A minimal cron-friendly worker for Project Pilot. Polls for phases whose
executor matches `$PILOT_EXECUTOR`, runs each one via a handler script, and
writes status back to the brief.

This is a **second conforming implementation** of the Project Pilot protocol
(the `pilot` CLI is the first). It uses only the three protocol-level verbs
described in `PROTOCOL.md`:

- `pilot next --executor=X --json` , ask for ready phases
- `pilot hint <slug> <phase> --json` , fetch the work package
- `pilot status <slug> <phase> <state>` , write state back

It never reads or writes `brief.md` directly , the same invariant any
conforming implementation must respect.

## Files

| File | What |
|---|---|
| `worker.sh` | The polling loop. Idempotent, safe to run on a cron. |
| `handler.sh` | What to do with each ready phase. **Replace this with your real work.** |

## Quick start

```bash
# 1. Make the scripts executable
chmod +x worker.sh handler.sh

# 2. Run it once to verify
PILOT_ROOT=~/my-projects/briefs ./worker.sh

# 3. Add to cron (every 5 minutes)
crontab -e
# */5 * * * * cd /path/to/repo && PILOT_ROOT=$HOME/briefs /path/to/worker.sh >> /tmp/pilot-worker.log 2>&1
```

## Configuration

| Env var | Default | What |
|---|---|---|
| `PILOT_BIN` | `pilot` (on PATH) | The pilot CLI binary |
| `PILOT_ROOT` | `$PWD/briefs` | Where briefs are stored |
| `PILOT_EXECUTOR` | `cron` | Match phases assigned to this executor |
| `WORKER_HANDLER` | `./handler.sh` | Script that does the actual work |
| `MAX_PHASES_PER_TICK` | `3` | Don't process more than this per invocation |

## How it fits the protocol

Each tick:

1. **Ask:** `pilot next --executor=cron --json` returns an array of phases
   that are `status=todo`, assigned to `executor=cron`, and have all their
   `depends_on` phases at `status=done`. Protocol-level dependency
   resolution, no parsing of brief.md by the worker.

2. **Claim:** the worker transitions the phase to `doing` immediately so
   other concurrent workers don't pick it up. (For true concurrent safety
   on the same brief, the `pilot status` call goes through the protocol's
   `mkdir`-based lock.)

3. **Fetch:** `pilot hint <slug> <phase> --json` returns the work package
   (outcome, acceptance criteria, prompt, status command). The worker
   pipes this packet into the handler on stdin.

4. **Run:** the handler does the work. Default handler is a no-op for demo
   purposes , replace with your real logic (call an LLM, run a build,
   hit an API, etc.).

5. **Report:** if the handler exits 0, the worker calls `pilot status done`.
   If it exits non-zero, the worker calls `pilot status blocked` with the
   exit code as the note.

## Replacing the handler

The default `handler.sh` just logs the work package. To make this real,
replace it with whatever processes the prompt:

```bash
# Hand to Claude Code in headless mode
echo "$prompt" | claude -p --strict-mcp-config

# Or to a different vendor
echo "$prompt" | openai chat --model gpt-5

# Or a deterministic build step
case "$phase" in
  build) npm run build ;;
  test)  npm test ;;
  deploy) ./deploy.sh ;;
esac
```

The handler reads a JSON packet on stdin with this shape:

```json
{
  "slug": "launch",
  "phase": "p2",
  "executor": "cron",
  "outcome": "Build deployed to staging",
  "acceptance_criteria": ["staging URL responds 200", "smoke test passes"],
  "prompt": "Work on phase p2 of the project 'launch'.\n\nOutcome: ...",
  "status_command": "pilot status launch p2 done \"<short evidence>\""
}
```

## What this proves

This worker is ~70 lines of bash that knows nothing about the format of
`brief.md`, the schema of phases, or how dependencies resolve. It speaks
to Project Pilot exclusively through the protocol's three verbs , the same
way a Codex client, a VS Code extension, or a web dashboard would. That's
the whole point of `PROTOCOL.md`: multiple implementations can share state
without coordinating.
