# Backend templates — db, test-utils, services, api

> Apply `{{PROJECT_NAME}}` and `{{SCOPE}}`. Backend packages and the Node/Hono API
> use explicit `.js` ESM specifiers on relative imports (matches the reference).

---

## `packages/db`

### `packages/db/package.json`

```json
{
  "name": "{{SCOPE}}/db",
  "version": "0.0.1",
  "private": true,
  "exports": {
    ".": "./src/index.ts",
    "./types": "./src/types.ts",
    "./client": "./src/client.ts"
  },
  "scripts": { "typecheck": "tsc --noEmit" },
  "dependencies": { "@supabase/supabase-js": "^2.49.0" },
  "devDependencies": { "{{SCOPE}}/config": "workspace:*", "typescript": "^5.7.3" }
}
```

### `packages/db/tsconfig.json`

```json
{ "extends": "{{SCOPE}}/config/typescript/node", "include": ["src"] }
```

### `packages/db/src/client.ts`

```ts
import { createClient as _createClient } from '@supabase/supabase-js'
import type { Database } from './types.js'

/** Typed Supabase client for browser/mobile. Uses the anon key — RLS enforces access. */
export function createClient(supabaseUrl: string, supabaseAnonKey: string) {
  return _createClient<Database>(supabaseUrl, supabaseAnonKey, {
    auth: { autoRefreshToken: true, persistSession: true },
  })
}

/** Typed admin client for server use. Uses the service role key — bypasses RLS. Never expose to the browser. */
export function createAdminClient(supabaseUrl: string, supabaseServiceRoleKey: string) {
  return _createClient<Database>(supabaseUrl, supabaseServiceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })
}

export type { Database }
```

### `packages/db/src/index.ts`

```ts
export { createClient, createAdminClient } from './client.js'
export type { Database } from './types.js'
```

### `packages/db/src/types.ts`

> Placeholder until `pnpm db:gen-types` is run against a real Supabase project.
> Includes the `items` table so the slice typechecks before generation.

```ts
// AUTO-GENERATED PLACEHOLDER — replace by running `pnpm db:gen-types`.
export type Json = string | number | boolean | null | { [k: string]: Json } | Json[]

export interface Database {
  public: {
    Tables: {
      items: {
        Row: { id: string; name: string; created_at: string }
        Insert: { id?: string; name: string; created_at?: string }
        Update: { id?: string; name?: string; created_at?: string }
        Relationships: []
      }
      profiles: {
        Row: { id: string; role: string; is_active: boolean; created_at: string }
        Insert: { id: string; role?: string; is_active?: boolean; created_at?: string }
        Update: { id?: string; role?: string; is_active?: boolean; created_at?: string }
        Relationships: []
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
    CompositeTypes: Record<string, never>
  }
}
```

---

## `packages/test-utils`

### `packages/test-utils/package.json`

```json
{
  "name": "{{SCOPE}}/test-utils",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "exports": { ".": "./src/index.ts" },
  "dependencies": { "{{SCOPE}}/db": "workspace:*" },
  "devDependencies": { "@supabase/supabase-js": "^2.49.0", "vitest": "^4.0.0" }
}
```

### `packages/test-utils/tsconfig.json`

```json
{ "extends": "{{SCOPE}}/config/typescript/node", "include": ["src"] }
```

### `packages/test-utils/src/index.ts`

```ts
export { buildSupabaseMock } from './supabase-mock.js'
export type { MockResult } from './supabase-mock.js'
```

### `packages/test-utils/src/supabase-mock.ts`

> A Proxy-based Supabase client mock covering the query patterns service
> functions use: direct-await list queries, terminal `.single()`/`.maybeSingle()`,
> mutation chains, and `.rpc()`.

```ts
import { vi } from 'vitest'
import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '{{SCOPE}}/db/types'

export type MockResult<T = unknown> =
  | { data: T; error: null }
  | { data: null; error: Record<string, unknown> }

/**
 * Creates a typed Supabase client mock.
 *
 * @example
 * const { supabase } = buildSupabaseMock({ data: [{ id: '1', name: 'A' }], error: null })
 * const items = await listItems(supabase)
 */
export function buildSupabaseMock<T = unknown>(
  defaultResult: MockResult<T> = { data: null as T, error: null }
) {
  function createBuilder(result: MockResult) {
    const spies: Record<string, ReturnType<typeof vi.fn>> = {}
    const builder: Record<string, unknown> = new Proxy({} as Record<string, unknown>, {
      get(_t, prop: string) {
        if (prop === 'then')
          return (res: (v: MockResult) => void, rej?: (e: unknown) => void) =>
            Promise.resolve(result).then(res, rej)
        if (prop === 'catch')
          return (rej: (e: unknown) => void) => Promise.resolve(result).catch(rej)
        if (prop === 'finally') return (fn: () => void) => Promise.resolve(result).finally(fn)
        if (prop === 'single' || prop === 'maybeSingle') {
          if (!spies[prop]) spies[prop] = vi.fn().mockResolvedValue(result)
          return spies[prop]
        }
        if (!spies[prop]) spies[prop] = vi.fn().mockReturnValue(builder)
        return spies[prop]
      },
    })
    return { builder, spies }
  }

  const { builder: defaultBuilder } = createBuilder(defaultResult)
  const fromMock = vi.fn().mockReturnValue(defaultBuilder)
  const rpcMock = vi.fn().mockResolvedValue(defaultResult)

  const supabase = { from: fromMock, rpc: rpcMock } as unknown as SupabaseClient<Database>

  return {
    supabase,
    fromMock,
    rpcMock,
    /** Queue a one-time result for the NEXT from() call (multi-step functions). */
    mockNextFromResult(result: MockResult) {
      const { builder } = createBuilder(result)
      fromMock.mockReturnValueOnce(builder)
      return this
    },
    /** Replace the default result for ALL subsequent from() calls. */
    mockFromResult(result: MockResult) {
      const { builder } = createBuilder(result)
      fromMock.mockReturnValue(builder)
      return this
    },
  }
}
```

---

## `packages/services` (with the example slice)

### `packages/services/package.json`

```json
{
  "name": "{{SCOPE}}/services",
  "version": "0.0.1",
  "private": true,
  "sideEffects": false,
  "exports": { ".": "./src/index.ts" },
  "scripts": {
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.49.0",
    "{{SCOPE}}/db": "workspace:*",
    "zod": "^3.24.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "{{SCOPE}}/config": "workspace:*",
    "{{SCOPE}}/test-utils": "workspace:*",
    "typescript": "^5.7.3",
    "vitest": "^4.0.0"
  }
}
```

### `packages/services/tsconfig.json`

```json
{ "extends": "{{SCOPE}}/config/typescript/node", "include": ["src"] }
```

### `packages/services/vitest.config.ts`

```ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: { environment: 'node', globals: false, include: ['src/**/*.test.ts'] },
})
```

### `packages/services/src/index.ts`

```ts
export * from './items.js'
```

### `packages/services/src/items.ts`  ← all business logic lives here

```ts
import { z } from 'zod'
import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '{{SCOPE}}/db/types'

type DB = SupabaseClient<Database>

export const getItemInput = z.object({
  id: z.string().uuid().describe('UUID of the item to fetch'),
})
export type GetItemInput = z.infer<typeof getItemInput>

export const createItemInput = z.object({
  name: z.string().min(1).describe('Display name for the new item'),
})
export type CreateItemInput = z.infer<typeof createItemInput>

export interface Item {
  id: string
  name: string
  created_at: string
}

/** List all items, newest first. */
export async function listItems(supabase: DB): Promise<Item[]> {
  const { data, error } = await supabase
    .from('items')
    .select('id, name, created_at')
    .order('created_at', { ascending: false })
  if (error) throw new Error(error.message)
  return data ?? []
}

/** Get a single item by id, or null if not found. */
export async function getItem(supabase: DB, input: GetItemInput): Promise<Item | null> {
  const { id } = getItemInput.parse(input)
  const { data, error } = await supabase
    .from('items')
    .select('id, name, created_at')
    .eq('id', id)
    .maybeSingle()
  if (error) throw new Error(error.message)
  return data
}

/** Create an item and return the inserted row. */
export async function createItem(supabase: DB, input: CreateItemInput): Promise<Item> {
  const { name } = createItemInput.parse(input)
  const { data, error } = await supabase
    .from('items')
    .insert({ name })
    .select('id, name, created_at')
    .single()
  if (error) throw new Error(error.message)
  return data
}
```

### `packages/services/src/items.test.ts`

```ts
import { describe, it, expect } from 'vitest'
import { buildSupabaseMock } from '{{SCOPE}}/test-utils'
import { listItems, getItem, createItem } from './items.js'

describe('items service', () => {
  it('listItems returns rows', async () => {
    const rows = [{ id: '1', name: 'A', created_at: '2026-01-01T00:00:00Z' }]
    const { supabase } = buildSupabaseMock({ data: rows, error: null })
    expect(await listItems(supabase)).toEqual(rows)
  })

  it('getItem returns a single row', async () => {
    const row = { id: '1', name: 'A', created_at: '2026-01-01T00:00:00Z' }
    const { supabase } = buildSupabaseMock({ data: row, error: null })
    expect(await getItem(supabase, { id: '11111111-1111-1111-1111-111111111111' })).toEqual(row)
  })

  it('createItem throws on error', async () => {
    const { supabase } = buildSupabaseMock({ data: null, error: { message: 'boom' } })
    await expect(createItem(supabase, { name: 'X' })).rejects.toThrow('boom')
  })
})
```

---

## `apps/api`

### `apps/api/package.json`

```json
{
  "name": "{{SCOPE}}/api",
  "version": "0.0.1",
  "private": true,
  "exports": { ".": "./src/router.ts" },
  "scripts": {
    "dev": "tsx watch --env-file=.env.local src/index.ts",
    "start": "tsx src/index.ts",
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  },
  "dependencies": {
    "@hono/node-server": "^1.13.0",
    "@supabase/supabase-js": "^2.49.0",
    "@trpc/server": "^11.0.0",
    "{{SCOPE}}/db": "workspace:*",
    "{{SCOPE}}/services": "workspace:*",
    "hono": "^4.7.0",
    "tsx": "^4.19.0",
    "zod": "^3.24.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "{{SCOPE}}/config": "workspace:*",
    "{{SCOPE}}/test-utils": "workspace:*",
    "typescript": "^5.7.3",
    "vitest": "^4.0.0"
  }
}
```

### `apps/api/tsconfig.json`

```json
{ "extends": "{{SCOPE}}/config/typescript/node", "include": ["src"] }
```

### `apps/api/vitest.config.ts`

```ts
import { defineConfig } from 'vitest/config'
export default defineConfig({ test: { environment: 'node', include: ['src/**/*.test.ts'] } })
```

### `apps/api/.env.example`

```bash
PORT=4000
CORS_ORIGINS=http://localhost:3000
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
```

### `apps/api/src/context.ts`

```ts
import { createAdminClient } from '{{SCOPE}}/db'
import type { User } from '@supabase/supabase-js'

/** tRPC context available to every procedure. */
export type Context = {
  /** Admin Supabase client — bypasses RLS. Authorize explicitly. */
  supabase: ReturnType<typeof createAdminClient>
  /** Authenticated user, or null. */
  user: User | null
}

/** Builds the per-request context: admin client + JWT-resolved user. */
export async function createContext(req: Request): Promise<Context> {
  const url = process.env.SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!url || !key) throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set')

  const supabase = createAdminClient(url, key)

  const authHeader = req.headers.get('authorization')
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
  let user: User | null = null
  if (token) {
    const { data, error } = await supabase.auth.getUser(token)
    if (!error) user = data.user
  }
  return { supabase, user }
}
```

### `apps/api/src/trpc.ts`

```ts
import { initTRPC, TRPCError } from '@trpc/server'
import type { Context } from './context.js'

const t = initTRPC.context<Context>().create()

export const router = t.router
export const middleware = t.middleware

/** Open to all callers — no auth. */
export const publicProcedure = t.procedure

/** Requires a valid Supabase session; loads role + active flag onto ctx. */
export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.user) throw new TRPCError({ code: 'UNAUTHORIZED', message: 'Not authenticated' })
  const { data: profile, error } = await ctx.supabase
    .from('profiles')
    .select('role, is_active')
    .eq('id', ctx.user.id)
    .single()
  if (error || !profile)
    throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: 'Could not resolve user role' })
  if (!profile.is_active)
    throw new TRPCError({ code: 'FORBIDDEN', message: 'Account is deactivated' })
  return next({ ctx: { ...ctx, user: ctx.user, appRole: profile.role as string } })
})

/** Requires an admin account. */
export const adminProcedure = protectedProcedure.use(({ ctx, next }) => {
  if ((ctx as { appRole?: string }).appRole !== 'admin')
    throw new TRPCError({ code: 'FORBIDDEN', message: 'Admin access required' })
  return next({ ctx })
})
```

> Note: `protectedProcedure`/`adminProcedure` are fully wired and typecheck against
> the placeholder `profiles` table in `db/src/types.ts`, but the example `items`
> slice uses `publicProcedure` so it runs before you've set up auth. Switch the
> `items` procedures to `protectedProcedure` once you have real users + a populated
> `profiles` table (the migration below creates one).

### `apps/api/src/router.ts`

```ts
import { router } from './trpc.js'
import { healthRouter } from './routers/health.js'
import { itemsRouter } from './routers/items.js'

export const appRouter = router({
  health: healthRouter,
  items: itemsRouter,
})

/** Imported by the web app for end-to-end type safety. */
export type AppRouter = typeof appRouter
```

### `apps/api/src/routers/health.ts`

```ts
import { router, publicProcedure } from '../trpc.js'

export const healthRouter = router({
  ping: publicProcedure.query(() => ({
    status: 'ok' as const,
    timestamp: new Date().toISOString(),
  })),
})
```

### `apps/api/src/routers/items.ts`  ← calls the service, no logic here

```ts
import { router, publicProcedure } from '../trpc.js'
import { listItems, getItem, createItem, getItemInput, createItemInput } from '{{SCOPE}}/services'

export const itemsRouter = router({
  list: publicProcedure.query(({ ctx }) => listItems(ctx.supabase)),
  get: publicProcedure.input(getItemInput).query(({ ctx, input }) => getItem(ctx.supabase, input)),
  create: publicProcedure
    .input(createItemInput)
    .mutation(({ ctx, input }) => createItem(ctx.supabase, input)),
})
```

### `apps/api/src/index.ts`

```ts
import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { fetchRequestHandler } from '@trpc/server/adapters/fetch'
import { appRouter } from './router.js'
import { createContext } from './context.js'

const app = new Hono()

const origins = process.env.CORS_ORIGINS?.split(',').map((s) => s.trim()) ?? [
  'http://localhost:3000',
]
app.use('/api/trpc/*', cors({ origin: origins, credentials: true }))

app.all('/api/trpc/*', (c) =>
  fetchRequestHandler({
    endpoint: '/api/trpc',
    req: c.req.raw,
    router: appRouter,
    createContext: ({ req }) => createContext(req),
    onError:
      process.env.NODE_ENV !== 'production'
        ? ({ path, error }) => console.error(`[tRPC] ${path}:`, error.message)
        : undefined,
  })
)

app.get('/health', (c) => c.json({ status: 'ok' }))
app.notFound((c) => c.json({ error: 'Not found' }, 404))

const port = parseInt(process.env.PORT ?? '4000', 10)
console.log(`[api] http://localhost:${port}`)
serve({ fetch: app.fetch, port })
```
