#!/usr/bin/env bash
# Minimal smoke test for the briefs CLI.
# Runs the happy-path of init -> set-project -> add-phase -> validate ->
# status -> render. Doesn't test the server (port-collision risk in CI).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PM="$SCRIPT_DIR/bin/pilot"
TMPDIR="$(mktemp -d)"
export PILOT_ROOT="$TMPDIR/briefs"

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "smoke: PILOT_ROOT=$PILOT_ROOT"

# init
"$PM" init smoke "Smoke test project" standard > /dev/null
[[ -f "$PILOT_ROOT/smoke/brief.md" ]] || { echo "FAIL: brief.md not created"; exit 1; }
echo "  ✓ init"

# set-project
"$PM" set-project smoke goal '"Verify the smoke test passes end to end."'
"$PM" set-project smoke definition_of_done '["init works","validate passes","render html produces output"]'
echo "  ✓ set-project"

# add-phase
"$PM" add-phase smoke '{"id":"p1","title":"One","outcome":"o","acceptance_criteria":["a"],"executor":"me"}'
"$PM" add-phase smoke '{"id":"p2","title":"Two","outcome":"o","acceptance_criteria":["a"],"executor":"claude","depends_on":["p1"]}'
echo "  ✓ add-phase"

# validate
out="$("$PM" validate smoke)"
[[ "$out" == "ok" ]] || { echo "FAIL: validate not ok: $out"; exit 1; }
echo "  ✓ validate"

# list
out="$("$PM")"
[[ "$out" == *"smoke"* ]] || { echo "FAIL: list missing slug"; exit 1; }
echo "  ✓ list"

# status transitions
"$PM" status smoke p1 doing "starting"
"$PM" status smoke p1 done "shipped"
out="$("$PM")"
[[ "$out" == *"1/2"* ]] || { echo "FAIL: counter not 1/2: $out"; exit 1; }
echo "  ✓ status transitions"

# render html
plan="$("$PM" render smoke html)"
[[ -f "$plan" ]] || { echo "FAIL: plan.html not generated"; exit 1; }
grep -q '<h1 class="title">' "$plan" || { echo "FAIL: plan.html missing title"; exit 1; }
grep -q 'class="phase done"' "$plan" || { echo "FAIL: plan.html missing done state"; exit 1; }
echo "  ✓ render html"

# hint
out="$("$PM" hint smoke p2)"
[[ "$out" == *"executor=claude"* ]] || { echo "FAIL: hint missing executor"; exit 1; }
[[ "$out" == *"Acceptance criteria"* ]] || { echo "FAIL: hint missing acceptance"; exit 1; }
echo "  ✓ hint"

echo "smoke: ALL PASS"
