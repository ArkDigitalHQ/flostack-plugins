# Frontend / MCP / migration / stub templates

> Apply `{{PROJECT_NAME}}` and `{{SCOPE}}`. **Next.js apps** (`web`, `web-customer`)
> use NO `.js` extension on relative imports. The MCP server and Node services DO
> use explicit `.js` specifiers.

---

## `apps/mcp-server` (optional)

### `apps/mcp-server/package.json`

```json
{
  "name": "{{SCOPE}}/mcp-server",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "dev": "tsx watch --env-file=.env.local src/index.ts",
    "start": "tsx src/index.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.9.0",
    "@supabase/supabase-js": "^2.49.0",
    "{{SCOPE}}/db": "workspace:*",
    "{{SCOPE}}/services": "workspace:*",
    "tsx": "^4.19.0",
    "zod": "^3.24.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "{{SCOPE}}/config": "workspace:*",
    "typescript": "^5.7.3"
  }
}
```

### `apps/mcp-server/tsconfig.json`

```json
{ "extends": "{{SCOPE}}/config/typescript/node", "include": ["src"] }
```

### `apps/mcp-server/.env.example`

```bash
PORT=4001
MCP_API_KEY=dev-secret
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
```

### `apps/mcp-server/src/tools/items.ts`  ← handler only calls the service

```ts
import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '{{SCOPE}}/db/types'
import { listItems, getItem, getItemInput } from '{{SCOPE}}/services'

export function registerItemTools(server: McpServer, supabase: SupabaseClient<Database>) {
  /**
   * List all items. Call when an agent needs the full set of items to choose from.
   * @returns JSON-stringified array of item rows.
   */
  server.tool('list_items', 'List all items, newest first.', {}, async () => {
    const items = await listItems(supabase)
    return { content: [{ type: 'text' as const, text: JSON.stringify(items) }] }
  })

  /**
   * Get a single item by id. Call before acting on a specific item.
   * @input id - UUID of the item.
   * @returns JSON-stringified item row, or null.
   */
  server.tool(
    'get_item',
    'Get a single item by its id.',
    getItemInput.shape,
    async ({ id }) => {
      const item = await getItem(supabase, { id })
      return { content: [{ type: 'text' as const, text: JSON.stringify(item) }] }
    }
  )
}
```

### `apps/mcp-server/src/index.ts`

```ts
import { createServer, type IncomingMessage } from 'node:http'
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { SSEServerTransport } from '@modelcontextprotocol/sdk/server/sse.js'
import { createAdminClient } from '{{SCOPE}}/db'
import { registerItemTools } from './tools/items.js'

const { MCP_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env
if (!MCP_API_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('[mcp-server] Missing MCP_API_KEY, SUPABASE_URL, or SUPABASE_SERVICE_ROLE_KEY')
  process.exit(1)
}

const supabase = createAdminClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
const transports = new Map<string, SSEServerTransport>()
const isAuthorized = (req: IncomingMessage) => req.headers['x-api-key'] === MCP_API_KEY

const server = createServer(async (req, res) => {
  const url = new URL(req.url ?? '/', 'http://localhost')
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Headers', 'x-api-key, content-type')
  if (req.method === 'OPTIONS') return void res.writeHead(204).end()

  if (req.method === 'GET' && url.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' })
    return void res.end(JSON.stringify({ status: 'ok', sessions: transports.size }))
  }
  if (!isAuthorized(req)) {
    res.writeHead(401, { 'Content-Type': 'application/json' })
    return void res.end(JSON.stringify({ error: 'Unauthorized' }))
  }

  if (req.method === 'GET' && url.pathname === '/sse') {
    const mcp = new McpServer({ name: '{{PROJECT_NAME}}-data', version: '1.0.0' })
    registerItemTools(mcp, supabase)
    const transport = new SSEServerTransport('/messages', res)
    transports.set(transport.sessionId, transport)
    transport.onclose = () => transports.delete(transport.sessionId)
    await mcp.connect(transport)
    return
  }
  if (req.method === 'POST' && url.pathname === '/messages') {
    const sessionId = url.searchParams.get('sessionId')
    const transport = sessionId ? transports.get(sessionId) : undefined
    if (!transport) {
      res.writeHead(404, { 'Content-Type': 'application/json' })
      return void res.end(JSON.stringify({ error: 'Session not found' }))
    }
    await transport.handlePostMessage(req, res)
    return
  }
  res.writeHead(404, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify({ error: 'Not found' }))
})

const port = parseInt(process.env.PORT ?? '4001', 10)
server.listen(port, () => console.log(`[mcp-server] http://localhost:${port}`))
```

---

## `apps/web` (optional — `web-customer` is the same shape, customer-facing)

### `apps/web/package.json`

```json
{
  "name": "{{SCOPE}}/web",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "typecheck": "tsc --noEmit",
    "lint": "eslint ."
  },
  "dependencies": {
    "@supabase/ssr": "^0.5.0",
    "@supabase/supabase-js": "^2.49.0",
    "@trpc/client": "^11.0.0",
    "{{SCOPE}}/api": "workspace:*",
    "{{SCOPE}}/db": "workspace:*",
    "next": "^15.2.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "{{SCOPE}}/config": "workspace:*",
    "typescript": "^5.7.3"
  }
}
```

### `apps/web/tsconfig.json`

```json
{
  "extends": "{{SCOPE}}/config/typescript/nextjs",
  "compilerOptions": { "paths": { "@/*": ["./src/*"] } },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### `apps/web/next.config.ts`

```ts
import type { NextConfig } from 'next'
const config: NextConfig = { transpilePackages: ['{{SCOPE}}/api', '{{SCOPE}}/db'] }
export default config
```

### `apps/web/.env.example`

```bash
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_API_URL=http://localhost:4000
```

### `apps/web/src/lib/supabase/client.ts`

```ts
import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '{{SCOPE}}/db/types'

/** Typed Supabase browser client for Client Components. Anon key — RLS enforces access. */
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

### `apps/web/src/lib/supabase/server.ts`

```ts
import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '{{SCOPE}}/db/types'

/** Typed Supabase server client for Server Components / Actions / Route Handlers. */
export async function createSupabaseServerClient() {
  const cookieStore = await cookies()
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(toSet: { name: string; value: string; options: CookieOptions }[]) {
          try {
            toSet.forEach(({ name, value, options }) => cookieStore.set(name, value, options))
          } catch {
            // Called from a Server Component — middleware refreshes the session.
          }
        },
      },
    }
  )
}
```

### `apps/web/src/lib/trpc/server.ts`

```ts
import { createTRPCClient, httpBatchLink } from '@trpc/client'
import { cache } from 'react'
import type { AppRouter } from '{{SCOPE}}/api'
import { createSupabaseServerClient } from '@/lib/supabase/server'

/** Raw server-side tRPC client. Prefer getApi(). Calls the API directly, server-to-server. */
export function createApiClient(token?: string | null) {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000'
  return createTRPCClient<AppRouter>({
    links: [
      httpBatchLink({
        url: `${apiUrl}/api/trpc`,
        headers: token ? { Authorization: `Bearer ${token}` } : {},
        fetch: (url, options) => fetch(url, { ...options, cache: 'no-store' }),
      }),
    ],
  })
}

/** Per-request memoised session. */
export const getSession = cache(async () => {
  const supabase = await createSupabaseServerClient()
  const {
    data: { session },
  } = await supabase.auth.getSession()
  return session
})

/** Per-request memoised API client. Use in Server Components and Actions. */
export const getApi = cache(async () => {
  const session = await getSession()
  return createApiClient(session?.access_token)
})
```

### `apps/web/src/lib/trpc/client.ts`

```ts
'use client'
import { createTRPCClient, httpBatchLink } from '@trpc/client'
import type { AppRouter } from '{{SCOPE}}/api'

/** Browser-side tRPC client. For Client Components. */
export function createApiClientBrowser() {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000'
  return createTRPCClient<AppRouter>({ links: [httpBatchLink({ url: `${apiUrl}/api/trpc` })] })
}
```

### `apps/web/src/app/layout.tsx`

```tsx
export const metadata = { title: '{{PROJECT_NAME}}' }

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
```

### `apps/web/src/app/page.tsx`

```tsx
import Link from 'next/link'

export default function Home() {
  return (
    <main style={{ padding: 32 }}>
      <h1>{{PROJECT_NAME}}</h1>
      <p>Starter scaffolded by the web-app-sdk plugin.</p>
      <Link href="/items">View items →</Link>
    </main>
  )
}
```

### `apps/web/src/app/items/page.tsx`  ← Server Component calling the API

```tsx
import { getApi } from '@/lib/trpc/server'

export default async function ItemsPage() {
  const api = await getApi()
  const items = await api.items.list.query()
  return (
    <main style={{ padding: 32 }}>
      <h1>Items</h1>
      <ul>
        {items.map((item) => (
          <li key={item.id}>{item.name}</li>
        ))}
      </ul>
    </main>
  )
}
```

### `apps/web/src/app/items/loading.tsx`

```tsx
export default function Loading() {
  return (
    <main style={{ padding: 32 }}>
      <h1>Items</h1>
      <p>Loading…</p>
    </main>
  )
}
```

> After scaffolding `web`, run `npx next telemetry disable` is optional; create a
> `next-env.d.ts` by running `pnpm --filter {{SCOPE}}/web exec next build` once, or
> let the first `pnpm dev` generate it.

---

## Supabase migration

### `supabase/migrations/<YYYYMMDDHHMMSS>_init_schema.sql`

> Use the current UTC timestamp for the filename prefix.

```sql
-- profiles: per-user role + active flag. protectedProcedure reads this table.
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'customer',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are self-readable" on public.profiles
  for select to authenticated using (auth.uid() = id);

-- Auto-create a profile row when a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- items: the example domain for the vertical slice.
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

alter table public.items enable row level security;

-- Anyone can read items (starter slice uses publicProcedure).
create policy "items are readable" on public.items
  for select using (true);

-- Only authenticated users can insert.
create policy "authenticated can insert items" on public.items
  for insert to authenticated with check (true);
```

---

## Stubs (optional apps)

### `apps/scheduler/package.json`

```json
{
  "name": "{{SCOPE}}/scheduler",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "dev": "tsx watch --env-file=.env.local src/index.ts",
    "start": "tsx src/index.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": { "@hono/node-server": "^1.13.0", "hono": "^4.7.0", "tsx": "^4.19.0" },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "{{SCOPE}}/config": "workspace:*",
    "typescript": "^5.7.3"
  }
}
```

### `apps/scheduler/src/index.ts`

```ts
import { serve } from '@hono/node-server'
import { Hono } from 'hono'

const app = new Hono()
app.get('/health', (c) => c.json({ status: 'ok' }))
// Register cron-style jobs here; trigger via POST /run/<job>.
app.post('/run/:job', (c) => c.json({ ran: c.req.param('job') }))

const port = parseInt(process.env.PORT ?? '4003', 10)
console.log(`[scheduler] http://localhost:${port}`)
serve({ fetch: app.fetch, port })
```

### `apps/agents/example-agent/package.json`

```json
{
  "name": "{{SCOPE}}/agent-example",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "dev": "tsx watch --env-file=.env.local src/index.ts",
    "start": "tsx src/index.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": { "@hono/node-server": "^1.13.0", "hono": "^4.7.0", "tsx": "^4.19.0" },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "{{SCOPE}}/config": "workspace:*",
    "typescript": "^5.7.3"
  }
}
```

### `apps/agents/example-agent/src/index.ts`

```ts
import { serve } from '@hono/node-server'
import { Hono } from 'hono'

const app = new Hono()
app.use('/run', async (c, next) => {
  if (c.req.header('x-api-key') !== process.env.MCP_API_KEY)
    return c.json({ error: 'Unauthorized' }, 401)
  await next()
})
app.get('/health', (c) => c.json({ status: 'ok', agent: 'example' }))
app.post('/run', async (c) => {
  const { prompt } = await c.req.json<{ prompt: string }>()
  // TODO: connect to the MCP server and run the agent loop.
  return c.json({ response: 'Not implemented', prompt, toolCalls: [] })
})

const port = parseInt(process.env.PORT ?? '4004', 10)
console.log(`[agent-example] http://localhost:${port}`)
serve({ fetch: app.fetch, port })
```

### `apps/agents/example-agent/.env.example`

```bash
PORT=4004
MCP_SERVER_URL=http://localhost:4001
MCP_API_KEY=dev-secret
ANTHROPIC_API_KEY=
```

### `apps/scheduler/tsconfig.json` and `apps/agents/example-agent/tsconfig.json`

```json
{ "extends": "{{SCOPE}}/config/typescript/node", "include": ["src"] }
```

### `apps/docs` — generated by the official Fumadocs CLI

Always create the docs app with `create-fumadocs-app`, run **fully
non-interactively** by supplying every flag (each supplied flag skips its prompt).
Then adapt the generated app to the monorepo.

**1. Generate.** Run from the `apps/` directory so the project lands at `apps/docs`:

```bash
cd apps
pnpm create fumadocs-app docs \
  --template "+next+fuma-docs-mdx" \
  --no-src \
  --no-eslint \
  --no-install \
  --pm pnpm
cd ..
```

Why these flags (verified against `create-fumadocs-app` v15.6.x, which uses
`commander` + `@clack/prompts` and skips a prompt whenever its value is supplied):

- `docs` — positional project name → no "Project name" prompt. Creates `apps/docs`.
- `--template "+next+fuma-docs-mdx"` — the recommended Next.js + Fumadocs MDX
  template → no template-select prompt. (Valid values: `+next+fuma-docs-mdx`,
  `+next+content-collections`, `react-router`, `tanstack-start`.)
- `--no-src`, `--no-eslint` — skip the `/src` and ESLint confirm prompts.
- `--no-install` — skip the install prompt; the root `pnpm install` installs the
  whole workspace (including the docs app and its `fumadocs-mdx` postinstall) afterward.
- `--pm pnpm` — pin the package manager so it isn't auto-detected.

The only other interactive branch is a "directory already exists, delete?" confirm,
which does **not** fire because `apps/docs` is fresh. If the command can't reach the
npm registry (offline), stop and tell the user to run it themselves — do **not**
hand-roll a fake docs app.

**2. Adapt to the monorepo.** After generation, edit `apps/docs/package.json`:

- Set `"name": "{{SCOPE}}/docs"`.
- Change the dev script to run on port 3001: `"dev": "next dev -p 3001"`.
- Add `"typecheck": "tsc --noEmit"` if not present.

**3. Add the documentation-contract targets.** Create these stub files (each just a
`# Title` heading) so the doc-sync skills — `/new-endpoint`, `/new-mcp-tool`,
`/doc-agent`, `/update-docs`, `/check-docs`, `/add-adr` — have somewhere to write:

- `apps/docs/content/docs/api/reference.mdx`
- `apps/docs/content/docs/mcp/tools.mdx`
- `apps/docs/content/docs/agents/overview.mdx`
- `apps/docs/content/docs/architecture/overview.mdx`
- `apps/docs/content/docs/reference/decisions.mdx`
- `apps/docs/content/docs/guides/environments.mdx`

(The template already provides `content/docs/index.mdx` and the Fumadocs config —
leave those as generated. Add a `meta.json` only if you want to order the new pages.)
