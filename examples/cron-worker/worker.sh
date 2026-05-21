#!/usr/bin/env bash
# worker.sh , a minimal cron-friendly worker for Project Pilot.
#
# Polls for phases whose executor matches $PILOT_EXECUTOR (default: "cron"),
# runs each one via the configured handler, and writes status back. Designed
# to be invoked from cron, launchd, systemd, or any scheduler.
#
# Conforming to the Project Pilot protocol:
#   - Reads brief state via `pilot next --json` (the protocol's eligibility query)
#   - Reads phase context via `pilot hint --json` (the protocol's handoff query)
#   - Writes state via `pilot status` (the protocol's update verb)
#   - Never touches brief.md directly
#
# Usage:
#   PILOT_ROOT=/path/to/briefs ./worker.sh
#
# Cron example (every 5 minutes):
#   */5 * * * * cd /path/to/repo && PILOT_ROOT=$HOME/briefs /path/to/worker.sh

set -euo pipefail

PILOT_BIN="${PILOT_BIN:-pilot}"
PILOT_EXECUTOR="${PILOT_EXECUTOR:-cron}"
HANDLER="${WORKER_HANDLER:-$(dirname "$0")/handler.sh}"
MAX_PHASES_PER_TICK="${MAX_PHASES_PER_TICK:-3}"

command -v "$PILOT_BIN" >/dev/null 2>&1 || {
  echo "worker: '$PILOT_BIN' not on PATH , set PILOT_BIN or symlink" >&2
  exit 2
}

# 1. Ask Project Pilot for phases that are ready and assigned to us.
ready="$("$PILOT_BIN" next --executor="$PILOT_EXECUTOR" --json)"
n_ready="$(jq 'length' <<<"$ready")"

if [[ "$n_ready" -eq 0 ]]; then
  echo "worker: no ready phases for executor=$PILOT_EXECUTOR"
  exit 0
fi

echo "worker: $n_ready phase(s) ready for executor=$PILOT_EXECUTOR"

# 2. Run up to MAX_PHASES_PER_TICK in this invocation.
processed=0
while IFS= read -r phase; do
  [[ "$processed" -ge "$MAX_PHASES_PER_TICK" ]] && break
  slug="$(jq -r '.slug' <<<"$phase")"
  phase_id="$(jq -r '.phase' <<<"$phase")"
  title="$(jq -r '.title' <<<"$phase")"

  echo
  echo "─── $slug / $phase_id , $title ───"

  # Mark phase as doing so other workers don't pick it up.
  "$PILOT_BIN" status "$slug" "$phase_id" doing "picked up by cron-worker $(date -u +%FT%TZ)"

  # 3. Fetch the work package (outcome, acceptance criteria, prompt).
  packet="$("$PILOT_BIN" hint "$slug" "$phase_id" --json)"

  # 4. Run the handler. The handler receives the JSON packet on stdin and
  #    is expected to exit 0 on success, non-zero on failure.
  if "$HANDLER" <<<"$packet"; then
    "$PILOT_BIN" status "$slug" "$phase_id" done "cron-worker completed at $(date -u +%FT%TZ)"
    echo "✓ done"
  else
    rc=$?
    "$PILOT_BIN" status "$slug" "$phase_id" blocked "cron-worker handler exited $rc at $(date -u +%FT%TZ)"
    echo "✗ blocked (handler exited $rc)"
  fi

  processed=$((processed + 1))
done < <(jq -c '.[]' <<<"$ready")

echo
echo "worker: processed $processed phase(s) this tick"
