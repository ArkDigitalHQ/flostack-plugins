# FloStack Web App SDK (`web-app-sdk`)

A Claude Code plugin that packages a reusable set of agents, skills, hooks,, and architecture rules for projects that share this stack:

> **Turborepo + pnpm** monorepo · **Next.js App Router** (staff + customer web) ·
> **Hono + tRPC v11 + Zod** API · **MCP server** · **AI agents**
> (claude-agent-sdk / Vercel AI SDK) · **Supabase** (Postgres + RLS) ·
> **Fumadocs** docs · a **service-layer-first** convention.

It was generalized from a working project's `.claude/` directory. All
project-specific branding has been removed; the package scope is `@flostack/`
(rename it to your own scope if it differs).

## What's inside

### Agents (`agents/`)

| Agent                | Use it for                                                                 |
| -------------------- | -------------------------------------------------------------------------- |
| `backend-architect`  | Service/API architecture and design decisions                              |
| `mcp-expert`         | Building/reviewing MCP tools that wrap service functions (no logic in handlers) |
| `code-reviewer`      | Comprehensive code review — quality, security, maintainability             |
| `debugger`           | Root-cause analysis of bugs, crashes, race conditions, leaks               |
| `api-documenter`     | OpenAPI specs, reference docs, integration guides                          |
| `frontend-developer` | Building front-end applications and component systems                      |
| `ui-ux-designer`     | UI/UX review, accessibility, visual critique                              |

### Skills (`skills/`)

Everything is a Skill — usable as `/name` and (unless noted) auto-invoked by Claude
when its description matches what you're doing. In a plugin they're namespaced,
e.g. `/web-app-sdk:verify`.

**Workflow & documentation-sync**

`/new-endpoint` · `/new-mcp-tool` · `/doc-agent` · `/update-docs` ·
`/check-docs` · `/add-adr` · `/db-migration` · `/verify` ·
`/agent-delegate` · `/agent-scope-check`

**Scaffolding & knowledge**

- **`/init-app`** — scaffold a brand-new project on this stack. Asks at run time
  which apps and packages to include, then generates a **runnable vertical slice**
  (an example domain threaded through a service + test, a tRPC router, an MCP tool,
  a Next.js page, and a Supabase migration) plus all monorepo config and a
  filled-in `CLAUDE.md`. `pnpm install && pnpm typecheck` passes out of the box.
- **`architecture-conventions`** — auto-loads the mandatory engineering rules
  (service-layer-first, pre-flight checklists, Next.js rules, branch-per-task)
  whenever you work in a repo with this shape. Works even before a `CLAUDE.md`
  exists.
- **`add-agent`** — scaffold a new background or streaming-chat AI agent.
- **`add-notification`** — add an event-bus notification rule + activity-feed entry.
- **`add-role`** — add an app role or org role with permissions and notification domains.

### Hooks (`hooks/`)

- **`docs-guard.sh`** (PostToolUse on Write/Edit) — non-blocking reminders to sync
  the Fumadocs content when you change a router, MCP tool, agent, migration, etc.
- **`pre-push-check.sh`** (PreToolUse on Bash) — when Claude is about to
  `git push`, runs `pnpm test`, `pnpm typecheck`, `pnpm lint`, `pnpm format:check`
  and **blocks the push** if any fail.

Both read the hook payload from stdin and reference scripts via
`${CLAUDE_PLUGIN_ROOT}`, so they work from any install location.

### CLAUDE.md template (`templates/CLAUDE.md`)

A generic, copy-in `CLAUDE.md` for new projects on this stack. Copy it to your
repo root, fill in the `{{PLACEHOLDERS}}`, and adjust the tech-stack table.

## Install

From the Cowork/Claude desktop app, accept the `.plugin` file in chat.

Or, in Claude Code, add it to a marketplace and install with
`/plugin install web-app-sdk@flostack`, or point at a local
checkout. See the [Claude Code plugin docs](https://code.claude.com/docs/en/plugins).

## Adapting it to a project

1. **Package scope** — files use `@flostack/`. If your monorepo uses a different
   scope (e.g. `@acme/`), find-and-replace it across the plugin or in your
   `CLAUDE.md`.
2. **Docs paths** — skills assume a Fumadocs site at
   `apps/docs/content/docs/`. Adjust the paths if your docs live elsewhere.
3. **CLAUDE.md** — copy `templates/CLAUDE.md` into the target repo and fill it in;
   it is the source of truth and overrides the `architecture-conventions` skill.

## Optional: typecheck-on-edit hook

This plugin intentionally does **not** typecheck on every edit (running a full
monorepo `pnpm typecheck` after each Write/Edit is slow and noisy). If you want
it anyway, add a second hook to `hooks/hooks.json` under `PostToolUse` →
`"matcher": "Write|Edit"`:

```json
{ "type": "command", "command": "pnpm typecheck 2>&1 | tail -40" }
```

## Notes

- No machine-specific paths, permission allow-lists, or secrets are shipped — those
  stay in each developer's local `settings.local.json`.
- The vendored `shadcn` skill from the source project is **not** included; install
  it per-project with `pnpm dlx shadcn@latest` / the shadcn skill instead.
