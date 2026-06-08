---
name: init-app
description: >
  Scaffold a new full-stack TypeScript monorepo starter on this stack — Turborepo
  + pnpm, Next.js App Router, Hono + tRPC + Zod, an MCP server, AI agents, and
  Supabase (Postgres + RLS). Use when the user wants to start a new project,
  initialize the repo, bootstrap the monorepo, scaffold the app skeleton, or set
  up a fresh codebase that follows the web-app-sdk architecture. Generates a
  runnable vertical slice (a service function + test wired through a tRPC router,
  an MCP tool, and a Next.js page) and asks at run time which apps and packages
  to include.
argument-hint: "[project-name]"
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
---

# Initialize a new app on this architecture

Scaffold a fresh monorepo that follows the web-app-sdk architecture: a
service-layer-first Turborepo + pnpm workspace with Next.js (App Router),
Hono + tRPC v11 + Zod, an MCP server, AI agents, a scheduler, Fumadocs, and
Supabase (Postgres + RLS). The result is a **runnable vertical slice** — a single
example domain ("items") threaded end-to-end so the patterns are demonstrated and
`pnpm install && pnpm typecheck` succeeds.

The full file contents live in `references/` (read them as you generate):

- `references/scaffold-plan.md` — directory tree, generation order, placeholder substitution, post-scaffold steps.
- `references/config-templates.md` — root + `packages/config` configuration files.
- `references/backend-templates.md` — `packages/db`, `packages/test-utils`, `packages/services` (with the example service + test), and `apps/api`.
- `references/frontend-mcp-templates.md` — `apps/mcp-server`, `apps/web`, the Supabase migration, and stubs for `apps/docs`, `apps/scheduler`, `apps/agents`.

## Workflow

### Phase 1 — Gather inputs (ASK at run time)

Use **AskUserQuestion** to collect, in one or two rounds:

1. **Project name** — kebab-case (default: the `$ARGUMENTS` value if given, else ask). Used for the root `package.json` `name` and the README title.
2. **Package scope** — the workspace npm scope for internal packages (e.g. `@app`, `@acme`). Default suggestion: `@app`. This replaces `{{SCOPE}}` everywhere.
3. **Target directory** — where to create the project (default: a new folder named after the project in the current working directory). Confirm it's empty or doesn't exist.
4. **Which apps to include** (multi-select). Always include `api` and `docs`. Offer: `web` (staff portal — recommended), `web-customer`, `mcp-server` (recommended), `scheduler`, `agents`.
5. **Which packages to include** (multi-select). Always include `config`, `db`, `services`, `test-utils`. Offer: `agent` (MCP/agent client helpers — include if `agents` or `mcp-server` selected).

If the user says "whatever's standard," default to: apps `web` + `api` + `mcp-server` + `docs`; packages `config` + `db` + `services` + `test-utils`. State the defaults you chose.

### Phase 2 — Confirm the plan

Echo back a short plan: project name, scope, target dir, and the exact apps + packages to be generated. Get a confirmation before writing files. Note that the example "items" vertical slice spans `packages/services` → `apps/api` → `apps/mcp-server` (if selected) → `apps/web` (if selected) → a Supabase migration.

### Phase 3 — Generate the files

Create the directory, then write files in the order given in
`references/scaffold-plan.md`. For every file, copy the matching template from the
reference docs and apply the substitutions:

- `{{PROJECT_NAME}}` → the project name
- `{{SCOPE}}` → the chosen package scope (e.g. `@app`)

Only generate the apps/packages the user selected. Skip an app's template block
entirely if it wasn't chosen, and remove its router/tool/page wiring from the
example slice accordingly (the reference notes mark what's conditional).

`apps/docs` is the one app you do **not** hand-write: generate it by running the
official Fumadocs CLI fully non-interactively (exact command + flags in the
`apps/docs` section of `frontend-mcp-templates.md`), then adapt the generated app
and add the documentation-contract stub pages. Run this before the Phase 4 install.

Always also drop in the architecture rules: copy this plugin's
`templates/CLAUDE.md` to the project root as `CLAUDE.md` and fill its
`{{PLACEHOLDERS}}` with the project name and scope.

### Phase 4 — Finish & report

1. From the project root run `pnpm install`.
2. Run `pnpm typecheck` to confirm the slice compiles. Fix any issues before reporting done.
3. Print next steps for the user: create a Supabase project, fill `.env.local` files from the `.env.example` templates, apply the `items` migration, then `pnpm dev`.
4. Summarize what was generated (apps, packages, the example slice) and where.

## Principles

- **Faithful, not heavy.** The templates are a simplified-but-correct version of
  the reference architecture: keep `publicProcedure` / `protectedProcedure` /
  `adminProcedure`, the admin-vs-anon Supabase client split, the service-layer-first
  rule, and the docs contract — but omit project-specific machinery (notifications
  bus, webhooks, BFF, multi-tier roles). The user grows those as needed.
- **Service-layer-first is sacred.** The example `items` logic lives only in
  `packages/services`; the tRPC router and MCP tool call it and contain no logic.
- **Runnable slice.** After scaffolding, `pnpm install && pnpm typecheck` must pass.
- **No secrets, no absolute paths.** Generate `.env.example` with placeholders;
  never write real keys.
