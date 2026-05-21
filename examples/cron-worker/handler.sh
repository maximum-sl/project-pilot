#!/usr/bin/env bash
# handler.sh , default cron-worker handler.
#
# Receives a JSON packet on stdin in the format emitted by `pilot hint --json`:
#   { slug, phase, executor, outcome, acceptance_criteria, prompt, status_command }
#
# This default implementation just logs the work package. Replace this script
# (or override $WORKER_HANDLER) with your own worker logic , send the prompt
# to an AI vendor, run a build command, hit an API, whatever the phase requires.
#
# Exit 0 on success → worker.sh marks the phase done.
# Exit non-zero → worker.sh marks the phase blocked with the exit code.

set -euo pipefail

# Read the JSON packet from stdin.
packet="$(cat)"

slug="$(jq -r '.slug' <<<"$packet")"
phase="$(jq -r '.phase' <<<"$packet")"
prompt="$(jq -r '.prompt' <<<"$packet")"

echo "[handler] running phase: $slug / $phase"
echo "[handler] prompt:"
echo "$prompt" | sed 's/^/    /'

# ── Replace below with real work ─────────────────────────────────────────────
#
# Examples:
#
#   # Hand to Claude Code in headless mode:
#   echo "$prompt" | claude -p --strict-mcp-config
#
#   # Hand to a different vendor's CLI:
#   echo "$prompt" | openai chat --model gpt-5
#
#   # Run a deterministic build step:
#   case "$phase" in
#     build) npm run build ;;
#     test)  npm test ;;
#     deploy) ./deploy.sh ;;
#   esac
#
# For demo purposes, this handler succeeds immediately.
# ─────────────────────────────────────────────────────────────────────────────

exit 0
