#!/usr/bin/env bash
# Minimal smoke test for the pilot CLI.
# Runs the happy-path of init -> set-project -> add-phase -> validate ->
# status -> render -> hint -> next. Doesn't test the server (port-collision
# risk in CI).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PILOT="$SCRIPT_DIR/bin/pilot"
TMPDIR="$(mktemp -d)"
export PILOT_ROOT="$TMPDIR/briefs"

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "smoke: PILOT_ROOT=$PILOT_ROOT"

# init
"$PILOT" init smoke "Smoke test project" standard > /dev/null
[[ -f "$PILOT_ROOT/smoke/brief.md" ]] || { echo "FAIL: brief.md not created"; exit 1; }
echo "  ✓ init"

# set-project
"$PILOT" set-project smoke goal '"Verify the smoke test passes end to end."'
"$PILOT" set-project smoke definition_of_done '["init works","validate passes","render html produces output"]'
echo "  ✓ set-project"

# add-phase
"$PILOT" add-phase smoke '{"id":"p1","title":"One","outcome":"o","acceptance_criteria":["a"],"executor":"me"}'
"$PILOT" add-phase smoke '{"id":"p2","title":"Two","outcome":"o","acceptance_criteria":["a"],"executor":"claude","depends_on":["p1"]}'
echo "  ✓ add-phase"

# validate
out="$("$PILOT" validate smoke)"
[[ "$out" == "ok" ]] || { echo "FAIL: validate not ok: $out"; exit 1; }
echo "  ✓ validate"

# list
out="$("$PILOT")"
[[ "$out" == *"smoke"* ]] || { echo "FAIL: list missing slug"; exit 1; }
echo "  ✓ list"

# status transitions
"$PILOT" status smoke p1 doing "starting"
"$PILOT" status smoke p1 done "shipped"
out="$("$PILOT")"
[[ "$out" == *"1/2"* ]] || { echo "FAIL: counter not 1/2: $out"; exit 1; }
echo "  ✓ status transitions"

# render html
plan="$("$PILOT" render smoke html)"
[[ -f "$plan" ]] || { echo "FAIL: plan.html not generated"; exit 1; }
grep -q '<h1 class="title">' "$plan" || { echo "FAIL: plan.html missing title"; exit 1; }
grep -q 'class="phase done"' "$plan" || { echo "FAIL: plan.html missing done state"; exit 1; }
echo "  ✓ render html"

# hint (text)
out="$("$PILOT" hint smoke p2)"
[[ "$out" == *"executor=claude"* ]] || { echo "FAIL: hint missing executor"; exit 1; }
[[ "$out" == *"Acceptance criteria"* ]] || { echo "FAIL: hint missing acceptance"; exit 1; }
echo "  ✓ hint"

# hint --json
out="$("$PILOT" hint smoke p2 --json)"
jq -e '.executor == "claude" and .prompt != null and .status_command != null' <<<"$out" >/dev/null \
  || { echo "FAIL: hint --json shape wrong: $out"; exit 1; }
echo "  ✓ hint --json"

# next , p1 is done, p2 deps satisfied, so p2 is eligible for executor=claude
out="$("$PILOT" next --executor=claude)"
[[ "$out" == *"smoke"$'\t'"p2"* ]] || { echo "FAIL: next missing p2: $out"; exit 1; }
echo "  ✓ next --executor"

# next --json
out="$("$PILOT" next --executor=claude --json)"
jq -e '.[0].phase == "p2" and .[0].executor == "claude"' <<<"$out" >/dev/null \
  || { echo "FAIL: next --json shape wrong: $out"; exit 1; }
echo "  ✓ next --json"

# dependency gating , p3 depends on p2 (still todo), should NOT appear
"$PILOT" add-phase smoke '{"id":"p3","title":"Three","outcome":"o","acceptance_criteria":["a"],"executor":"claude","depends_on":["p2"]}'
out="$("$PILOT" next --executor=claude --json | jq -r '[.[].phase] | join(",")')"
[[ "$out" == "p2" ]] || { echo "FAIL: next should only return p2 (p3 deps not done): got $out"; exit 1; }
echo "  ✓ next respects depends_on"

echo "smoke: ALL PASS (12/12)"
