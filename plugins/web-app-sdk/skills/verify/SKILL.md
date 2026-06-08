---
name: verify
description: Pre-push verification — run tests, typecheck, lint, format and docs-coverage checks before pushing or opening a PR.
allowed-tools: Bash, Read, Grep
---

# /verify — Pre-Push Verification

Run this command before every `git push` or before opening a PR. It verifies the full health of the codebase: tests, types, lint, format, and documentation coverage.

**Do not push until this command reports: `READY TO PUSH`.**

---

## Step 1: Run the full quality suite

Run each command in sequence. If any fails, stop and fix the issue before continuing. Do not skip a failed step.

```bash
pnpm test
```

If tests fail: identify the failing test file and function. Fix the implementation or the test, then re-run before continuing.

```bash
pnpm typecheck
```

If typecheck fails: read the error output, identify the file and line, fix the type error. Common causes: missing return types, incompatible Zod schemas, wrong import paths.

```bash
pnpm lint
```

If lint fails: fix the ESLint errors shown. Do not suppress with `eslint-disable` unless the suppression is intentional and commented.

```bash
pnpm format:check
```

If format check fails: run `pnpm format` to auto-fix all files, then re-run `pnpm format:check` to confirm.

```bash
find apps/web packages -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.css' \) | xargs bash ./scripts/check-hardcoded-colors.sh
```

If the hardcoded color check fails: replace any hardcoded hex/rgb/hsl values with Tailwind theme tokens (`bg-primary`, `text-muted-foreground`, etc.). See `BRAND.md` for the token reference.

---

## Step 2: Check API documentation coverage

Read `apps/docs/content/docs/api/reference.mdx`. Then check which tRPC procedures exist in the codebase:

```bash
grep -rh "\.query\|\.mutation" apps/api/src/routers/ | grep -v "//" | grep -oP "\w+(?=:\s*(protectedProcedure|adminProcedure|staffOrAdminProcedure|publicProcedure))" | sort
```

For each router file in `apps/api/src/routers/` that contains procedures not listed in `apps/docs/content/docs/api/reference.mdx`, flag it:

> MISSING from apps/docs/content/docs/api/reference.mdx: `<router>.<procedure>`

If any are missing, run `/new-endpoint` to add them before pushing.

---

## Step 3: Check MCP tool documentation coverage

Read `apps/docs/content/docs/mcp/tools.mdx`. Then check which tools exist in the codebase:

```bash
grep -rh "server\.tool(" apps/mcp-server/src/tools/ | grep -oP "(?<=server\.tool\()['\"]?\K[^'\",(]+"
```

For each tool name found that does NOT appear in `apps/docs/content/docs/mcp/tools.mdx`, flag it:

> MISSING from apps/docs/content/docs/mcp/tools.mdx: `<tool_name>`

If any are missing, run `/new-mcp-tool` to add them before pushing.

---

## Step 4: Check test coverage for service files

Check that every service file has a corresponding test file:

```bash
for f in packages/services/src/*.ts; do
  base="${f%.ts}"
  [[ "$f" == *".test.ts" ]] && continue
  [[ "$f" == *"index.ts" ]] && continue
  [[ "$f" == *"server.ts" ]] && continue
  [[ "$f" == *"roles.ts" ]] && continue
  test_file="${base}.test.ts"
  if [ ! -f "$test_file" ]; then
    echo "MISSING test file: $test_file"
  fi
done
```

Any service file without a test file is a blocker. Write the missing tests before pushing.

---

## Step 5: Output the results report

Output a summary in exactly this format:

```
## /verify Results

### Tests
- [PASS / FAIL] pnpm test

### Typecheck
- [PASS / FAIL] pnpm typecheck

### Lint
- [PASS / FAIL] pnpm lint

### Format
- [PASS / FAIL] pnpm format:check

### Hardcoded colors
- [PASS / FAIL] check-hardcoded-colors.sh

### API Documentation Coverage
- [OK / MISSING: <list undocumented procedures>]

### MCP Documentation Coverage
- [OK / MISSING: <list undocumented tools>]

### Test File Coverage
- [OK / MISSING: <list service files without test files>]

---
Overall: [READY TO PUSH / BLOCKED — fix the issues above first]
```

If overall is **BLOCKED**, fix every listed issue and re-run `/verify` before pushing.

If overall is **READY TO PUSH**, proceed with `git push origin <branch-name>`.
