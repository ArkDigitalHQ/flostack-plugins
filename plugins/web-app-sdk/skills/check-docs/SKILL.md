---
name: check-docs
description: Audit documentation health — missing TSDoc, undocumented endpoints/MCP tools, stale architecture docs and CLAUDE.md.
allowed-tools: Read, Grep, Glob, Bash
---

# /check-docs — Documentation Health Audit

You are auditing the documentation health of the monorepo — a full-stack TypeScript monorepo.

## What to audit

### 1. Missing JSDoc/TSDoc on exported functions

Scan these files for exported functions, types, and constants that lack TSDoc comments:

- `packages/services/src/*.ts` — all service functions and Zod schemas
- `apps/api/src/context.ts` — `Context` type and `createContext`
- `apps/api/src/trpc.ts` — `publicProcedure`, `protectedProcedure`
- `apps/api/src/routers/*.ts` — all routers and their procedures
- `apps/web/src/lib/supabase/client.ts` — `createClient`
- `apps/web/src/lib/supabase/server.ts` — `createSupabaseServerClient`
- `apps/web/src/lib/trpc/server.ts` — `createApiClient`
- `apps/web/src/middleware.ts` — `middleware`
- `apps/web/src/app/auth/callback/route.ts` — `GET`
- `packages/db/src/client.ts` — `createClient`, `createAdminClient`

Flag any exported symbol that lacks at minimum a description line.

### 2. API docs coverage

Read `apps/docs/content/docs/api/reference.mdx`. Then scan `apps/api/src/routers/` for all tRPC procedures and `apps/api/src/index.ts` for all bare HTTP routes. Flag any procedure or route not documented in `apps/docs/content/docs/api/reference.mdx`.

### 3. MCP docs coverage

Read `apps/docs/content/docs/mcp/tools.mdx`. Then scan `apps/mcp-server/src/tools/` (if it exists) for all `server.tool(...)` calls. Flag any tool not documented in `apps/docs/content/docs/mcp/tools.mdx`.

### 4. Architecture docs coverage

Read `apps/docs/content/docs/architecture/overview.mdx`. Check whether:

- All packages in `packages/` are described
- All apps in `apps/` are described
- All environment variables in `.env.example` are listed
- The DB schema matches the latest migration files in `supabase/migrations/`

### 5. CLAUDE.md staleness

Read `CLAUDE.md` and verify:

- The tech stack table reflects what's actually in `package.json` files
- The phase status table matches `ARCHITECTURE.md`
- All slash commands listed in the documentation contract exist in `.claude/commands/`

## Output format

Group findings by category. Use this format:

```
## [Category Name]
- [ ] <file>:<line or function> — <what's missing>
- [x] <thing> — OK
```

After listing all findings, show a summary count: `X issues found across Y categories.`

Then ask: **"Would you like me to fix all of these now?"**
