---
name: update-docs
description: Re-audit the codebase and sync all documentation (architecture, API reference, MCP tools, CLAUDE.md).
allowed-tools: Read, Edit, Grep, Glob, Bash
---

# /update-docs — Sync All Documentation

You are syncing all documentation with the current state of the platform codebase — a full-stack TypeScript monorepo (Turborepo monorepo: Next.js web, Hono + tRPC API, Supabase, planned MCP server and AI agents).

## Steps

### 1. Re-audit the project structure

Read these key files to understand the current state:

- `ROADMAP.md` (root) — phased build status
- `pnpm-workspace.yaml` — what packages/apps exist
- `apps/api/src/router.ts` — current tRPC router tree
- `apps/api/src/routers/*.ts` — all sub-routers
- `apps/mcp-server/src/` (if exists) — MCP tools
- `packages/services/src/*.ts` — all service functions
- `supabase/migrations/*.sql` — current schema
- `.env.example` — all environment variables
- `packages/*/package.json` and `apps/*/package.json` — dependency changes

### 2. Update `apps/docs/content/docs/architecture/overview.mdx`

- Reflect any new packages or apps in the directory structure section
- Update the DB schema table if new migrations exist
- Update the environment variables tables if `.env.example` has changed
- Update the system architecture diagram if new services have been added

### 3. Update `apps/docs/content/docs/api/reference.mdx`

- Add entries for any new tRPC procedures not yet documented
- Mark procedures as removed if their router no longer exists
- Update request/response schemas if Zod schemas have changed in `packages/services`

### 4. Update `apps/docs/content/docs/mcp/tools.mdx`

- Add entries for any new MCP tools in `apps/mcp-server/src/tools/`
- Update tool schemas if service input schemas have changed
- Update the planned tools table if new services have been added to `packages/services`

### 5. Update `CLAUDE.md`

- Update the tech stack table if new dependencies have been added
- Update the phase status table to match `ARCHITECTURE.md`
- Update run/build instructions if scripts have changed in root `package.json`
- Verify all slash commands listed in the documentation contract exist in `.claude/commands/`

### 6. Report changes

After completing all updates, output a summary:

```
## Documentation Update Summary

### apps/docs/content/docs/architecture/overview.mdx
- Added: ...
- Updated: ...

### apps/docs/content/docs/api/reference.mdx
- Added: ...

### apps/docs/content/docs/mcp/tools.mdx
- No changes needed

### CLAUDE.md
- Updated: ...
```

If nothing changed in a file, say "No changes needed."
