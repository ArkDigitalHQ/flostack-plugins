---
name: new-endpoint
description: Document a newly created tRPC procedure or HTTP route and add its JSDoc.
argument-hint: "[router.procedure]"
allowed-tools: Read, Edit, Grep, Glob
---

# /new-endpoint — Document a New API Endpoint

You are adding documentation for a newly created API endpoint in the platform — a full-stack TypeScript monorepo using Hono + tRPC on Railway.

## Context

- All tRPC procedures live in `apps/api/src/routers/` and are registered in `apps/api/src/router.ts`
- Business logic lives in `packages/services/src/` — tRPC routers call service functions
- API documentation lives in `apps/docs/content/docs/api/reference.mdx`
- Auth is handled via `publicProcedure` (no auth) or `protectedProcedure` (requires Supabase JWT)

## Steps

### 1. Gather endpoint details

If the user has not already specified the endpoint, ask:

- What is the procedure name (e.g. `orders.get`) or HTTP route (e.g. `GET /webhooks/stripe`)?
- Is it a tRPC query, mutation, or a bare HTTP route?
- What is the input schema?
- What does it return?
- Is auth required?

If the endpoint already exists in code, read the router file and service function instead of asking.

### 2. Add JSDoc to the route handler

Open the relevant file in `apps/api/src/routers/<domain>.ts` and add a TSDoc comment block above the router or procedure definition. Include:

- `@description` — what this procedure does
- `@auth` — `None` or `Required (Supabase JWT)`
- Input and output types if not obvious from the Zod schema

Example format:

```typescript
/**
 * Get a single order by ID.
 *
 * @auth Required (Supabase JWT)
 * @returns Full order row including line items
 */
```

### 3. Add entry to `apps/docs/content/docs/api/reference.mdx`

Read `apps/docs/content/docs/api/reference.mdx` first, then add the new procedure under the appropriate router section. Include:

```markdown
### `<router>.<procedure>`

<One-sentence description>

| Property | Value            |
| -------- | ---------------- |
| Type     | Query / Mutation |
| Auth     | None / Required  |

**Input:**
\`\`\`typescript
{ field: type }
\`\`\`

**Response:**
\`\`\`typescript
{ field: type }
\`\`\`

**TypeScript client:**
\`\`\`typescript
const result = await api.<router>.<procedure>.query(input)
\`\`\`
```

For bare HTTP routes, use the existing `## Bare HTTP Endpoints` section format.

### 4. Check for architecture impact

Ask yourself: Does this endpoint represent a new domain, a new external integration, or a new data flow that should be reflected in `apps/docs/content/docs/architecture/overview.mdx`? If yes, update the relevant section.

### 5. Confirm

Report: "Added `<procedure>` to `apps/docs/content/docs/api/reference.mdx` and JSDoc to `<file>`."
