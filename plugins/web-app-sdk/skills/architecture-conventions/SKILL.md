---
name: architecture-conventions
description: >
  Load the mandatory engineering conventions for this monorepo architecture —
  Turborepo + pnpm, Next.js App Router (staff + customer), Hono + tRPC + Zod API,
  an MCP server, AI agents, and Supabase (Postgres + RLS). Use whenever writing
  or reviewing code in a repo with apps/api, apps/web, apps/mcp-server,
  packages/services, or supabase/migrations — especially when adding a tRPC
  endpoint, MCP tool, agent, service function, page, or database migration, or
  before committing and pushing. These rules apply even before a project CLAUDE.md
  exists.
---

# Architecture Conventions

These are the non-negotiable conventions for this monorepo. Follow them whenever
you write or review code here. If the repo has a `CLAUDE.md`, it is the source of
truth and overrides anything below; this skill exists to enforce the same rules
when no `CLAUDE.md` is present yet (a template ships in this plugin's
`templates/CLAUDE.md`).

## The architecture in one breath

A Turborepo + pnpm monorepo. Business logic lives in **one place** —
`packages/services`. Everything else is a transport or presentation layer over it:
tRPC routers (`apps/api`) for the web apps, MCP tools (`apps/mcp-server`) for AI
agents, Next.js App Router front-ends (`apps/web` staff, `apps/web-customer`
portal), AI agents (`apps/agents/*`), a scheduler, and a Fumadocs docs site
(`apps/docs`). Data is Supabase Postgres with RLS; auth is Supabase magic links.

## Service-layer-first (the rule everything else depends on)

1. New domain logic is a plain async function in `packages/services/src/<domain>.ts`.
2. It gets a unit test in `<domain>.test.ts` **in the same session** —
   use `buildSupabaseMock()` from `@flostack/test-utils`.
3. Export it from `packages/services/src/index.ts`.
4. Only then wire it into a tRPC router and/or an MCP tool. **Never duplicate
   logic between them, and never put logic in a router or MCP handler** — they
   only call service functions.

## Pre-flight before you create things

**tRPC endpoint** — search first; don't rebuild what exists:

```bash
grep -r "export async function" packages/services/src/
ls apps/api/src/routers/
```

Then: service function → test → export → router (`apps/api/src/routers/<domain>.ts`)
→ register in `apps/api/src/router.ts` → run `/new-endpoint`.

**MCP tool** — the service function MUST already exist. The handler body only
calls it; zero logic. Tool names are `snake_case`; reuse the service layer's Zod
schema. Run `/new-mcp-tool`.

**Agent** — pick the pattern (background `createAgent()` vs. streaming chat
`streamText`), give it `GET /health`, document env vars, run `/add-agent` and
`/doc-agent`.

**Database change** — author a SQL migration in `supabase/migrations/` named
`<YYYYMMDDHHMMSS>_<description>.sql`. Enable RLS + at least one policy for new
tables. Regenerate types with `pnpm db:gen-types`; never hand-edit
`packages/db/src/types.ts`. The `/db-migration` command scaffolds this.

## Supabase clients

- Server-side (API, MCP, scheduler): admin client (service role key, bypasses RLS).
- Browser: anon client (RLS enforces access).
- Protected tRPC procedures use `protectedProcedure` and require the session JWT
  via `Authorization: Bearer <token>`.

## Next.js rules

- **No mutations in Server Components.** Server Components render on every request;
  a `.mutate()` there double-writes. For init-on-first-visit writes, delegate to a
  Client Component with the `useEffect` + `useRef` guard pattern.
- **Every data-fetching `page.tsx` needs a sibling `loading.tsx`** with a skeleton
  that mirrors the layout.
- Don't re-fetch auth in a page when the layout already resolved user context.
  Use `Promise.all` for independent fetches; `<Suspense>` to stream slow sections;
  `unstable_cache` for stable data.
- **Imports:** Next.js apps use **no** `.js` extension on relative imports; the
  Node/Hono backend and packages **do** use explicit `.js` ESM specifiers. Match
  the file you're editing.

## UI

Never hardcode colors, font sizes, or spacing — use Tailwind theme tokens
(`bg-primary`, `text-muted-foreground`, `gap-4`). Check `components/ui/` before
adding a shadcn component. Read `BRAND.md` before building UI; copy must match its
voice.

## Naming

Files `kebab-case.ts` · tRPC routers `camelCase` · MCP tools `snake_case` ·
DB tables/columns `snake_case` · TS types/interfaces `PascalCase`.

## Branch per task + verify before push

Never commit to `main`. Branch with a `feature/ fix/ chore/ docs/` prefix. Before
any `git push`, run `/verify` (tests, typecheck, lint, format, docs coverage) and
only push when it reports ready. Open a PR; don't push to `main` directly.

## Documentation contract

Docs live in `apps/docs/content/docs/`. After a change, run the matching command:
`/new-endpoint` (routers) · `/new-mcp-tool` (MCP tools) · `/doc-agent` (agents) ·
`/update-docs` (structural changes) · `/add-adr` (architectural decisions) ·
`/check-docs` (audit).
