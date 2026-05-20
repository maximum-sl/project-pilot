#!/usr/bin/env bash
# pilot-server.sh , local static HTTP server for the briefs root.
#
# Serves the briefs root on http://127.0.0.1:8765 so plan.html files are
# reachable via clickable links in any chat or editor. Idempotent , safe to
# call repeatedly. Only listens on loopback (not LAN).
#
# Configure via env:
#   PILOT_ROOT           path to briefs root (default: $PWD/briefs)
#   PILOT_SERVER_PORT    port to bind (default: 8765)
#   PILOT_STATE_DIR      pid/log location (default: $PILOT_ROOT/.tmp)
#
# Usage:
#   bash scripts/pilot-server.sh start   # start if not running
#   bash scripts/pilot-server.sh stop    # stop if running
#   bash scripts/pilot-server.sh status  # print pid + url or "not running"
#   bash scripts/pilot-server.sh url     # print base URL only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PILOT_DIR="${PILOT_ROOT:-$PWD/briefs}"
PORT="${PILOT_SERVER_PORT:-8765}"
HOST="127.0.0.1"
STATE_DIR="${PILOT_STATE_DIR:-$PILOT_DIR/.tmp}"
PID_FILE="$STATE_DIR/pilot-server.pid"
LOG_FILE="$STATE_DIR/pilot-server.log"
URL="http://${HOST}:${PORT}"

mkdir -p "$STATE_DIR"

_is_running() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid; pid="$(cat "$PID_FILE" 2>/dev/null || echo "")"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

_start() {
  if _is_running; then
    echo "$URL  (already running, pid $(cat "$PID_FILE"))"
    return 0
  fi
  local server_py="$SCRIPT_DIR/pilot-server.py"
  [[ -f "$server_py" ]] || { echo "pilot-server: missing $server_py" >&2; return 2; }
  nohup python3 "$server_py" "$PILOT_DIR" "$PORT" "$HOST" > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  disown 2>/dev/null || true
  sleep 0.3
  if _is_running; then
    echo "$URL  (started, pid $(cat "$PID_FILE"))"
  else
    echo "pilot-server: failed to start , check $LOG_FILE" >&2
    return 1
  fi
}

_stop() {
  if ! _is_running; then echo "not running"; return 0; fi
  local pid; pid="$(cat "$PID_FILE")"
  kill "$pid" 2>/dev/null || true
  rm -f "$PID_FILE"
  echo "stopped (pid $pid)"
}

_status() {
  if _is_running; then echo "running, pid $(cat "$PID_FILE"), $URL"
  else echo "not running"; fi
}

case "${1:-start}" in
  start) _start ;;
  stop) _stop ;;
  status) _status ;;
  url) echo "$URL" ;;
  *) echo "usage: pilot-server.sh {start|stop|status|url}" >&2; exit 2 ;;
esac
