# {{PROJECT_NAME}} — Claude Context

> Copy this file to the root of your repository as `CLAUDE.md` and fill in the
> `{{PLACEHOLDERS}}`. It encodes the conventions of a full-stack TypeScript
> monorepo built on Turborepo + pnpm, Next.js (App Router), Hono + tRPC + Zod,
> a Model Context Protocol server, AI agents, and Supabase (Postgres + RLS).
> The `@flostack/` package scope is used throughout — rename it to your own
> workspace scope with a find-and-replace if it differs.

## What This Is

{{ONE_PARAGRAPH_DESCRIPTION — what the product does, who it serves, and the
core lifecycle it manages. Keep it to 2–3 sentences.}}

## Tech Stack

| Layer          | Tech                                                                  |
| -------------- | --------------------------------------------------------------------- |
| Web (staff)    | Next.js App Router — `apps/web` (UI only — no API routes)             |
| Web (customer) | Next.js App Router — `apps/web-customer` (customer portal)            |
| Mobile         | Expo + Expo Router — optional, add when needed                        |
| API            | Hono + tRPC v11 + Zod — `apps/api` (always-on)                        |
| MCP Server     | Node.js HTTP + SSE — `apps/mcp-server`                                |
| AI Agents      | claude-agent-sdk / Vercel AI SDK — `apps/agents/*`                    |
| Scheduler      | Hono jobs runner — `apps/scheduler`                                   |
| Database       | Supabase PostgreSQL + RLS                                             |
| Auth           | Supabase magic links (OTP)                                            |
| Storage        | Supabase Storage (signed URLs)                                        |
| Email          | {{EMAIL_PROVIDER, e.g. Resend + React Email}}                         |
| Payments       | {{PAYMENTS_PROVIDER, if any}}                                         |
| Monorepo       | Turborepo + pnpm workspaces                                           |
| Docs           | Fumadocs (Next.js, port 3001 in dev)                                  |

> Add or remove rows to match your project. Domain-specific integrations
> (SMS, shipping, CRM, etc.) belong here too — list them with the package or
> service file that owns them.

## Workspace Layout

**Apps** (`apps/*`): `web` (staff portal), `web-customer` (customer portal),
`api` (tRPC + Hono), `mcp-server` (MCP tools over HTTP/SSE), `scheduler` (jobs
runner), `agents/*` (AI agents), `docs` (Fumadocs site).

**Packages** (`packages/*`): `services` (business logic — source of truth),
`db` (Supabase types + clients), `agent` (agent + MCP client helpers),
`test-utils` (mock builders for tests), plus any domain packages you add.

## Running the Project

Local dev points at a **staging Supabase project** as the database — not a local
`supabase start` stack. `.env.local` files point at the staging URL + service
role key. There is no Docker step.

```bash
pnpm install        # install all dependencies
pnpm dev            # run all apps in dev mode

# Individual services (adjust ports to your setup):
# Web (staff):    cd apps/web && pnpm dev            → http://localhost:3000
# Web (customer): cd apps/web-customer && pnpm dev   → http://localhost:3002
# API only:       cd apps/api && pnpm dev            → http://localhost:4000
# MCP Server:     cd apps/mcp-server && pnpm dev     → http://localhost:4001
# Scheduler:      cd apps/scheduler && pnpm dev      → http://localhost:4003
# Docs:           cd apps/docs && pnpm dev           → http://localhost:3001
```

## Building and Checking

```bash
pnpm build        # build all packages and apps
pnpm typecheck    # typecheck all packages and apps
pnpm lint         # lint all packages and apps
pnpm format       # format all files with Prettier
pnpm test         # run all unit tests
```

## Database

Local dev points at the staging Supabase project — there is no local Postgres.
Migrations are authored as SQL files under `supabase/migrations/` and applied to
staging on push to `main` via CI (production applies on `v*` tag push).

```bash
pnpm db:gen-types           # regenerate packages/db/src/types.ts from staging schema
supabase db push            # apply local migrations to the linked remote (CI usually handles this)
```

## Key Conventions

**Service layer:** Business logic lives in `packages/services`. New domain
operations go there first as plain async functions, then get wired into tRPC
routers (`apps/api/src/routers/`) and MCP tools (`apps/mcp-server/src/tools/`).
Never duplicate logic between them.

**Tests:** Any new service function in `packages/services/src/<domain>.ts` MUST
have a corresponding unit test in `<domain>.test.ts` (same directory). Any new or
modified tRPC middleware procedure in `apps/api/src/trpc.ts` MUST have tests in
`apps/api/src/trpc.test.ts`. Use `buildSupabaseMock()` from `@flostack/test-utils`.
Always run `pnpm test` before pushing.

**Supabase clients:**

- Server-side (API, MCP): always use the admin client (service role key, bypasses RLS)
- Browser: always use the anon client (RLS enforces access)

**Auth:** All protected tRPC procedures use `protectedProcedure`. Never call a
protected procedure without forwarding the session JWT via
`Authorization: Bearer <token>`.

**Imports:** In the Next.js apps (`apps/web`, `apps/web-customer`) never use
explicit `.js` extensions on relative imports — they break Next.js's webpack
bundler. The Node/Hono backend (`apps/api`, `apps/mcp-server`, `apps/scheduler`,
`packages/*`) **does** use explicit `.js` ESM specifiers. Match the convention
already used in the file you are editing.

**Naming:**

- Files: `kebab-case.ts`
- tRPC routers: `camelCase` (e.g. `health`, `orderRouting`)
- MCP tool names: `snake_case` (e.g. `get_order`, `create_quote`)
- Database tables/columns: `snake_case`
- TypeScript types/interfaces: `PascalCase`

**Adding a tRPC router:**

1. Add service function(s) to `packages/services/src/<domain>.ts`
2. Export from `packages/services/src/index.ts`
3. Create `apps/api/src/routers/<domain>.ts`
4. Register in `apps/api/src/router.ts`
5. Run `/new-endpoint` to update docs

**Adding an MCP tool:**

1. Use an existing service function from `@flostack/services`
2. Add the tool to `apps/mcp-server/src/tools/<domain>.ts`
3. Run `/new-mcp-tool` to update docs

**Adding an AI agent:** two patterns — _background/scripted_ agents use
`@flostack/agent` + `createAgent()`; _streaming chat_ agents use Hono + Vercel
AI SDK (`streamText`) + `@ai-sdk/anthropic`. Both expose `GET /health` plus
`POST /run` or `POST /chat`. Run `/doc-agent` after wiring. (The `/add-agent`
skill scaffolds either pattern.)

**No mutations in Server Components** — never call a `.mutate()` procedure inside
a Server Component (page, layout, or any async server function). Server
Components render on every request; a mutation there writes to the DB multiple
times unintentionally. For "init on first visit" writes, delegate to a Client
Component using the `useEffect` + `useRef` guard pattern (find an existing
`*AutoInitiator` component for the reference implementation). The Server
Component computes any data the initiator needs and passes it as props.

**Migrations:** SQL migrations live in `supabase/migrations/`. Never edit
`packages/db/src/types.ts` manually — regenerate with `pnpm db:gen-types`.

**Commits:** Squash merge feature branches to `main`. Every merge deploys
everywhere.

## Page Performance Standards (MANDATORY)

Every new page must meet these rules; existing pages should comply when touched.

1. **`loading.tsx` is mandatory** — every `page.tsx` that fetches data must have
   a sibling `loading.tsx` with a skeleton that mirrors the layout.
2. **No sequential auth + data fetches** — don't call `supabase.auth.getSession()`
   in a page when the layout already resolved the user context (those helpers are
   wrapped with `React.cache()`). Use `Promise.all` for independent fetches.
3. **Stream expensive sections** — wrap a slow section in
   `<Suspense fallback={<Skeleton />}>` rather than holding the whole page.
4. **Cache stable data** — wrap `api.*` calls for data that doesn't change
   per-user-per-request in `unstable_cache` (60s user-scoped, 300s catalog).

## UI Development

**Brand:** Visual identity — color, typography, voice, icon rules — lives in
`BRAND.md`. Read it before building any UI.

- Never hardcode colors, font sizes, or spacing values. Always use Tailwind
  utilities that map to theme tokens (`bg-primary`, `text-muted-foreground`,
  `gap-4`).
- Never introduce a new shadcn component without first checking `components/ui/`.
- If a design need can't be met by existing tokens, propose a new token in
  `globals.css` before using arbitrary values.
- All user-facing copy must match the voice defined in `BRAND.md`.

## Branch Per Task (MANDATORY)

Never commit directly to `main`. Every task starts on a new branch.

```bash
git checkout main && git pull origin main
git checkout -b <type>/<short-description>   # feature/ fix/ chore/ docs/
```

At the end of every task: run `/verify` (must pass completely), push the branch,
open a PR, and wait for CI + a reviewer before merging. Never `git push origin main`.

## Pre-Flight Checklists (MANDATORY)

These are gates. Complete every step before writing code. If a check reveals the
thing already exists, STOP and use what exists.

### Before Creating Any New tRPC Endpoint

```bash
grep -r "export async function" packages/services/src/   # existing service functions
ls apps/api/src/routers/                                  # existing routers
```

Only proceed if nothing covers this use case. Then: (1) service function, (2) test
in the same session, (3) export from `index.ts`, (4) create/update the router,
(5) register it, (6) ask whether it should also be an MCP tool, (7) run `/new-endpoint`.

### Before Creating Any New MCP Tool

The service function must exist first — MCP tools contain zero logic. Confirm it,
confirm the tool doesn't already exist, then add the tool (handler only calls the
service function) and run `/new-mcp-tool`.

### Before Adding Any New Agent

Choose the pattern (background vs. streaming chat), then run `/add-agent` and
`/doc-agent`. Every agent needs a `GET /health` endpoint and documented env vars.

### Before Any `git push`

Run `/verify` and confirm it passes completely. Do not push with failing tests,
type errors, or lint errors.

## Documentation Contract

Docs live in `apps/docs/content/docs/` (Fumadocs). After any significant change,
run the relevant command. Key mapping:

| Tech stack area                       | Fumadocs content file                                |
| ------------------------------------- | ---------------------------------------------------- |
| `apps/api/src/routers/`               | `api/reference.mdx`                                  |
| `apps/mcp-server/src/tools/`          | `mcp/tools.mdx`                                      |
| `apps/agents/`                        | `agents/overview.mdx`                               |
| `.env.example` / env vars             | `guides/environments.mdx`                           |
| `supabase/migrations/`                | `architecture/overview.mdx`                         |
| `packages/services/src/roles.ts`      | `reference/roles.mdx`                               |
| `packages/services/src/notifications` | `reference/notifications.mdx`                       |

| Command         | When to run                                                     |
| --------------- | --------------------------------------------------------------- |
| `/new-endpoint` | After adding a tRPC procedure or HTTP route                     |
| `/new-mcp-tool` | After adding an MCP tool                                        |
| `/doc-agent`    | After adding a new agent or updating agent tools                |
| `/update-docs`  | After any structural change (new package, renamed module, etc.) |
| `/add-adr`      | After making a significant architectural decision               |
| `/check-docs`   | To audit for missing or stale documentation                     |
| `/verify`       | Before any `git push` or PR creation                            |
