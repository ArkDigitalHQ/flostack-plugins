---
name: agent-delegate
description: Package a feature sub-issue into a complete, self-contained context block for a subagent, with the architecture rules baked in.
argument-hint: "[sub-issue number or title]"
allowed-tools: Read, Grep, Glob
---

# /agent-delegate — Package a sub-issue into a subagent context block

Run this before spawning a subagent to work a feature sub-issue. It produces a standardised, complete context block that the subagent receives so it can implement correctly without needing to re-read the whole codebase.

---

## Inputs required

- The sub-issue title and body (copy from GitHub)
- The acceptance criteria from the sub-issue
- The **Relevant paths** list from the sub-issue
- The **Out of scope** list from the sub-issue
- The parent feature issue number and title (for context)

---

## Step 1: Choose the subagent variant

Select the subagent based on what the sub-issue primarily involves:

| Sub-issue involves                                               | Use subagent                             |
| ---------------------------------------------------------------- | ---------------------------------------- |
| Next.js pages, React components, UI/UX, Tailwind, shadcn         | `frontend-developer`                     |
| Service layer, tRPC routers, MCP tools, API design, new packages | `backend-architect`                      |
| Failing tests, unclear root cause, debugging a regression        | `debugger`                               |
| Anything else                                                    | default (no named subagent — run inline) |

If the sub-issue spans both UI and service layer, prefer `backend-architect` and instruct it to implement the full stack for that session.

---

## Step 2: Produce the context block

Output the following block exactly, filled in with the real values. This is what you pass to the subagent:

```
FEATURE: #<parent-number> — <parent-title>
SUB-ISSUE: #<sub-issue-number> — <sub-issue-title>

TASK
<sub-issue body — paste verbatim>

ACCEPTANCE CRITERIA
<paste from sub-issue>

IN-SCOPE PATHS (stay within these)
<paste Relevant paths list from sub-issue>

OUT OF SCOPE
<paste from sub-issue>

ARCHITECTURE RULES (mandatory — do not skip any)

1. Service-layer-first: all business logic goes in packages/services/src/<domain>.ts first.
   Wire into tRPC routers (apps/api/src/routers/) and MCP tools (apps/mcp-server/src/tools/) after.
   Never duplicate logic between them.

2. Before creating any tRPC endpoint, run these checks:
   grep -r "export async function" packages/services/src/
   ls apps/api/src/routers/
   Only proceed if nothing already covers this use case.

3. Before creating any MCP tool, confirm the service function exists first.
   grep -r "server.tool" apps/mcp-server/src/tools/

4. Tests are mandatory: every new or modified service function in packages/services/src/<domain>.ts
   must have a corresponding test in <domain>.test.ts (same directory).
   Use buildSupabaseMock() from @flostack/test-utils.

5. No mutations in Server Components. Any write that must happen on first page load
   must be delegated to a Client Component using the useEffect + useRef pattern.
   Reference implementation: any existing `*AutoInitiator` client component in `apps/web-customer/src/app/` that performs the init-on-first-visit pattern.

6. Import convention:
   - In apps/web and apps/web-customer: no .js extensions on relative imports
   - In apps/api, apps/mcp-server, apps/scheduler, packages/*: use explicit .js ESM specifiers

7. Never hardcode colors, font sizes, or spacing. Use Tailwind theme tokens only.

8. If your implementation requires a Supabase schema change (new table, column, index, RLS policy),
   run /db-migration before committing.

POST-IMPLEMENTATION (run after your changes are complete, before reporting back)
- Added or changed a tRPC procedure? Run /new-endpoint
- Added or changed an MCP tool? Run /new-mcp-tool
- Modified agent code? Run /doc-agent
- Made an architectural decision not covered by the sub-issue? Run /add-adr

COMMIT AND REPORT
Commit all changes on this branch. Do not merge. Do not push to main.
Report back: what you changed, which files were modified, any decisions you made where the sub-issue was silent,
and anything you chose not to implement with the reason.
```

---

## Step 3: Spawn the subagent

Pass the context block above as the subagent's prompt. If using a named subagent variant, specify it. After the subagent returns, run `/agent-scope-check` before merging its session branch.
