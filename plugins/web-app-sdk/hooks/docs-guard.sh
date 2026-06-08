#!/usr/bin/env bash
# docs-guard.sh — PostToolUse hook for Write|Edit.
# Reminds Claude to update the Fumadocs content that documents the file it just changed.
#
# Reads the hook payload as JSON on stdin (current Claude Code hook contract),
# falling back to the $CLAUDE_TOOL_INPUT / $TOOL_INPUT env vars for older versions.
# Emits reminders on stdout and always exits 0 (non-blocking).

set -euo pipefail

read_payload() {
  if [ ! -t 0 ]; then cat; fi
}
PAYLOAD="$(read_payload || true)"
[ -z "${PAYLOAD:-}" ] && PAYLOAD="${CLAUDE_TOOL_INPUT:-${TOOL_INPUT:-}}"

# Extract the edited file path from tool_input.file_path (or a bare {file_path:...}).
FILE_PATH="$(printf '%s' "$PAYLOAD" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    print(""); sys.exit(0)
ti=d.get("tool_input", d)
print(ti.get("file_path","") if isinstance(ti,dict) else "")
' 2>/dev/null || echo "")"

[ -z "$FILE_PATH" ] && exit 0
# Don't nag when Claude is editing the docs themselves.
echo "$FILE_PATH" | grep -q "apps/docs/" && exit 0

MSGS=()
echo "$FILE_PATH" | grep -qE "apps/api/src/routers/" && \
  MSGS+=("📝 API router changed → update apps/docs/content/docs/api/reference.mdx (/new-endpoint)")
echo "$FILE_PATH" | grep -qE "apps/mcp-server/src/tools/" && \
  MSGS+=("📝 MCP tool changed → update apps/docs/content/docs/mcp/tools.mdx (/new-mcp-tool)")
echo "$FILE_PATH" | grep -qE "apps/agents/[^/]+/src/" && \
  MSGS+=("📝 Agent changed → update apps/docs/content/docs/agents/overview.mdx (/doc-agent)")
echo "$FILE_PATH" | grep -qE "\.env\.example$" && \
  MSGS+=("📝 Env vars changed → update apps/docs/content/docs/guides/environments.mdx + architecture/overview.mdx")
echo "$FILE_PATH" | grep -qE "supabase/migrations/" && \
  MSGS+=("📝 DB schema changed → update apps/docs/content/docs/architecture/overview.mdx")
echo "$FILE_PATH" | grep -qE "pnpm-workspace\.yaml|turbo\.json" && \
  MSGS+=("📝 Monorepo structure changed → update apps/docs/content/docs/architecture/overview.mdx (/update-docs)")
echo "$FILE_PATH" | grep -qE "packages/services/src/roles\.ts" && \
  MSGS+=("📝 Roles/permissions changed → update apps/docs/content/docs/reference/roles.mdx")
echo "$FILE_PATH" | grep -qE "packages/services/src/notifications" && \
  MSGS+=("📝 Notification logic changed → update apps/docs/content/docs/reference/notifications.mdx")

if [ ${#MSGS[@]} -gt 0 ]; then
  echo ""
  echo "⚠️  DOCS UPDATE REQUIRED — sync the Fumadocs content before pushing:"
  for msg in "${MSGS[@]}"; do echo "  $msg"; done
  echo ""
fi
exit 0
