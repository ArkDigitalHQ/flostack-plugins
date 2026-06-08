---
name: agent-scope-check
description: After a subagent returns, verify every changed file falls within the sub-issue named paths before merging.
argument-hint: "[feature-branch] [session-branch]"
allowed-tools: Bash, Read
---

# /agent-scope-check — Verify a subagent stayed within its named paths

Run this after a subagent returns and before merging its session branch into the feature branch. It catches out-of-scope changes before they propagate.

---

## Inputs required

Before running, identify:

- `<feature-branch>` — the feature branch the session branch was cut from (e.g. `feature/42-order-export`)
- `<session-branch>` — the session branch the subagent worked on (e.g. `feature/42-order-export/s101`)
- `<named-paths>` — the list of paths from the sub-issue's **Relevant paths** section

---

## Step 1: List all files changed by the subagent

```bash
git diff --name-only <feature-branch>...<session-branch>
```

If the session branch is the current branch:

```bash
git diff --name-only <feature-branch>...HEAD
```

---

## Step 2: Classify each changed file

For each file in the diff output, determine whether it falls within one of the named paths.

A file is **in scope** if it:

- Matches a named path exactly, or
- Is inside a named directory, or
- Is a file that any named path transitively requires (e.g. a shared type file imported by a named file)

A file is **out of scope** if it:

- Is not inside any named path
- Was not mentioned as a dependency in the sub-issue

Files that are always allowed regardless of named paths:

- `supabase/migrations/` — a migration is expected if the sub-issue touches schema
- `packages/db/src/types.ts` — regenerated automatically after a migration
- `.claude/` — tooling files

---

## Step 3: Output the verdict

If all changed files are in scope:

```
## /agent-scope-check

SCOPE OK — all changes within named paths.

Changed files: <list>
```

If any files are out of scope:

```
## /agent-scope-check

SCOPE VIOLATION — changes found outside named paths.

Out-of-scope files:
- <file>
- <file>

In-scope files:
- <file>

Action required: Do NOT merge the session branch. Review the out-of-scope changes. Either:
1. Revert the out-of-scope files and re-run /verify, then merge, or
2. If the changes are correct and necessary, update the sub-issue to name the additional paths, then re-run /agent-scope-check.
```
