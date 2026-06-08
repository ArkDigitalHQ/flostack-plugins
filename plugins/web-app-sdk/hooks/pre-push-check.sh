#!/usr/bin/env bash
# pre-push-check.sh — PreToolUse hook for Bash.
# When Claude is about to run `git push`, run the full quality suite first and
# BLOCK the push (exit 2) if anything fails. Any other Bash command passes through.
#
# Reads the hook payload as JSON on stdin (tool_input.command), falling back to
# $CLAUDE_TOOL_INPUT / $TOOL_INPUT for older Claude Code versions.

set -uo pipefail

read_payload() {
  if [ ! -t 0 ]; then cat; fi
}
PAYLOAD="$(read_payload || true)"
[ -z "${PAYLOAD:-}" ] && PAYLOAD="${CLAUDE_TOOL_INPUT:-${TOOL_INPUT:-}}"

CMD="$(printf '%s' "$PAYLOAD" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    print(""); sys.exit(0)
ti=d.get("tool_input", d)
print(ti.get("command","") if isinstance(ti,dict) else "")
' 2>/dev/null || echo "")"

# Only gate real pushes. Let everything else through untouched.
echo "$CMD" | grep -qE "git[[:space:]]+push" || exit 0

echo "▶ Pre-push gate: running tests, typecheck, lint, and format check…"
FAILED=0
run() { echo "  → $*"; eval "$@" >/tmp/_prepush.log 2>&1 || { echo "✗ FAILED: $*"; tail -30 /tmp/_prepush.log; FAILED=1; }; }

run "pnpm test"
run "pnpm typecheck"
run "pnpm lint"
run "pnpm format:check"

if [ "$FAILED" -ne 0 ]; then
  echo "✗ Pre-push checks failed — fix the errors above before pushing. Run /verify for details." >&2
  exit 2   # exit 2 blocks the tool call and feeds stderr back to Claude
fi

echo "✓ All checks passed — push allowed."
exit 0
