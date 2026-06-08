---
name: add-agent
description: >
  Scaffold a new AI agent service for the platform. Use when the user
  wants to add a new Railway agent (background/scripted OR streaming chat).
  Triggers for phrases like "add agent", "create agent", "new agent for <domain>".
---

# Add Agent

You are helping scaffold a new AI agent service for the platform.

## Step 1: Determine agent type

Ask the user (or infer from context):

- **Background/scripted** — runs on-demand via HTTP `POST /run`, uses `@flostack/agent` + `createAgent()`
- **Streaming chat** — serves streaming LLM responses via `POST /chat`, uses Hono + Vercel AI SDK + `@ai-sdk/anthropic`

Use any existing streaming chat agent in `apps/agents/` as the reference implementation.

## Step 2: Create the agent directory

```bash
mkdir -p apps/agents/<domain>/src
```

## Step 3: Create package.json

### Background agent

```json
{
  "name": "@flostack/agent-<domain>",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "dev": "tsx watch --env-file=.env.local src/index.ts",
    "start": "tsx src/index.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@flostack/agent": "workspace:*",
    "hono": "^4.7.0",
    "@hono/node-server": "^1.13.7",
    "tsx": "^4.19.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@flostack/config": "workspace:*",
    "typescript": "^5.7.3"
  }
}
```

### Streaming chat agent

```json
{
  "name": "@flostack/agent-<domain>",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "dev": "tsx watch --env-file=.env.local src/index.ts",
    "start": "tsx src/index.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@ai-sdk/anthropic": "^1.0.0",
    "@hono/node-server": "^1.13.7",
    "@flostack/agent": "workspace:*",
    "ai": "^4.0.0",
    "hono": "^4.7.0",
    "tsx": "^4.19.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@flostack/config": "workspace:*",
    "typescript": "^5.7.3"
  }
}
```

## Step 4: Create tsconfig.json

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "extends": "@flostack/config/typescript/node",
  "include": ["src"]
}
```

## Step 5: Create src/index.ts

### Background agent

```typescript
import { Hono } from 'hono'
import { serve } from '@hono/node-server'
import { MCPClient } from '@flostack/agent'

const app = new Hono()

// Auth middleware
app.use('/run', async (c, next) => {
  if (c.req.header('x-api-key') !== process.env.MCP_API_KEY) {
    return c.json({ error: 'Unauthorized' }, 401)
  }
  await next()
})

app.get('/health', (c) => c.json({ status: 'ok', agent: '<domain>' }))

app.post('/run', async (c) => {
  const { prompt } = await c.req.json<{ prompt: string }>()
  // TODO: implement agent logic using MCPClient
  return c.json({ response: 'Not implemented', toolCalls: [] })
})

const port = Number(process.env.PORT ?? 40XX)
serve({ fetch: app.fetch, port }, () => {
  console.log(`<domain> agent running on port ${port}`)
})
```

### Streaming chat agent (see an existing streaming agent in apps/agents/<name>/src/index.ts for full reference)

Key pattern:

```typescript
import { streamText } from 'ai'
import { anthropic } from '@ai-sdk/anthropic'
import { MCPClient } from '@flostack/agent'
import { tool } from 'ai'
import { jsonSchema } from 'ai'

app.post('/chat', async (c) => {
  const { messages } = await c.req.json()
  // Connect to MCP, get tools
  // Call streamText with model + tools
  // Return result.toDataStreamResponse()
})
```

## Step 6: Create .env.local

```bash
ANTHROPIC_API_KEY=sk-ant-...
MCP_SERVER_URL=http://localhost:4001
MCP_API_KEY=dev-secret
# Agent-specific key (if needed):
<DOMAIN>_API_KEY=dev-secret
PORT=40XX
```

## Step 7: Run pnpm install

```bash
pnpm install
```

## Step 8: Document the agent

Run `/doc-agent` to add the agent to `apps/docs/content/docs/agents/overview.mdx`.

## Step 9: Deploy to Railway

Add to `apps/docs/content/docs/deployment/production-launch.mdx` Railway services table and env vars sections.

## Ports

| Port | Agent          |
| ---- | -------------- |
| 4004 | first streaming agent |
| 4005 | next available |
