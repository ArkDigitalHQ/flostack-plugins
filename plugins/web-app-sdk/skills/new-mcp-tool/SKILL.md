---
name: new-mcp-tool
description: Document a newly created MCP tool and add its JSDoc to the tool handler.
argument-hint: "[tool_name]"
allowed-tools: Read, Edit, Grep, Glob
---

# /new-mcp-tool — Document a New MCP Tool

You are adding documentation for a newly created MCP tool in the platform — a full-stack TypeScript monorepo. MCP tools are called autonomously by Claude AI agents.

## Context

- The MCP server lives in `apps/mcp-server/` (Railway, always-on, Node.js HTTP + SSE)
- Tools are defined using `server.tool(name, description, inputSchema, handler)`
- Tool input schemas come from `packages/services/src/*.ts` — tools reuse Zod schemas from the service layer
- The MCP server uses an admin Supabase client (service role key, bypasses RLS)
- MCP documentation lives in `apps/docs/content/docs/mcp/tools.mdx`

## Steps

### 1. Gather tool details

If the user has not already specified the tool, ask:

- What is the tool name (snake_case, e.g. `get_order`)?
- Which MCP server does it belong to (e.g. `flostack-data`)?
- What does it do — write the description as an agent-facing instruction
- What is the input schema (reference the Zod schema in `packages/services`)?
- What does it return?
- Does it require any config or auth beyond `MCP_API_KEY`?

If the tool already exists in code, read `apps/mcp-server/src/tools/<domain>.ts` instead of asking.

### 2. Add JSDoc to the tool handler

Open the relevant file in `apps/mcp-server/src/tools/<domain>.ts` and add a TSDoc comment above the `server.tool(...)` call. Include:

- Description of what the tool does and **when an agent should call it**
- Input field descriptions (these surface in the agent's reasoning)
- What the tool returns

Example format:

```typescript
/**
 * Get a single order by ID.
 *
 * Call this before any action that reads or modifies order state.
 * Returns the full order row including current status and line items.
 *
 * @input order_id - UUID of the order to retrieve
 * @returns JSON-stringified order row
 */
server.tool('get_order', ...)
```

### 3. Add entry to `apps/docs/content/docs/mcp/tools.mdx`

Read `apps/docs/content/docs/mcp/tools.mdx` first, then add the tool to the appropriate server section. Include:

```markdown
### `tool_name`

<Agent-facing description: what this does and when to call it>

| Property | Value        |
| -------- | ------------ |
| Server   | `flostack-data` |
| Auth     | MCP_API_KEY  |

**Input schema:**
\`\`\`typescript
{ input_field: z.string().describe('...') }
\`\`\`

**Returns:** Description of the response content

**Example call:**
\`\`\`json
{ "tool": "tool_name", "input": { "input_field": "example-value" } }
\`\`\`

**Example response:**
\`\`\`json
{ "content": [{ "type": "text", "text": "{...}" }] }
\`\`\`
```

### 4. Check for config or auth requirements

If the new tool requires new environment variables or a new Supabase permission, update:

- `apps/docs/content/docs/mcp/tools.mdx` — add to the server's config section
- `apps/docs/content/docs/architecture/overview.mdx` — add env var to the MCP server table
- `.env.example` — add the new variable with a comment

### 5. Confirm

Report: "Added `<tool_name>` to `apps/docs/content/docs/mcp/tools.mdx` and JSDoc to `<file>`."
