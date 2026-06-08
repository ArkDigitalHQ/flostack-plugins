---
name: doc-agent
description: Add or update documentation for an AI agent in the docs site agents overview.
argument-hint: "[agent domain]"
allowed-tools: Read, Edit, Grep, Glob
---

# /doc-agent — Document an AI Agent

You are adding or updating documentation for an AI agent in the platform.

## Context

`apps/docs/content/docs/agents/overview.mdx` contains a reference guide for all agents deployed on Railway. When new agents are added or existing agents are updated with new tools or functionality, this documentation must be kept in sync.

## Steps

### 1. Gather agent details

If not provided by the user, ask:

> "Which agent are you documenting? (profile, quoting, order-routing, etc.)"

Then collect:

- **Agent domain** — What business function does it handle?
- **Location** — `apps/agents/<domain>/`
- **Available MCP tools** — What tools does it call? (Check `apps/docs/content/docs/mcp/tools.mdx` for available tools)
- **Example usage** — Show how to instantiate and run the agent
- **Port** (if deployed) — Default is 4002 for profile, 4003+ for others
- **jsdoc additions** — Function descriptions to add to `src/index.ts`

### 2. Ensure jsdoc exists in agent code

Check `apps/agents/<domain>/src/index.ts` for proper jsdoc:

```typescript
/**
 * <Domain> Agent — <One-line description>
 *
 * Manages: <What this agent does>
 *
 * Available MCP tools:
 * - tool_name — Description
 *
 * Example:
 * const result = await agent.run('<Example user prompt>')
 */
```

If jsdoc is missing or incomplete, suggest additions.

### 3. Update `apps/docs/content/docs/agents/overview.mdx`

Locate the agent section (or create one if new). Update:

1. **Agent metadata** — Domain, location, port
2. **Description** — What it does in 1-2 sentences
3. **Available MCP tools** — List tools from `apps/docs/content/docs/mcp/tools.mdx` that this agent uses
4. **Example usage** — Show instantiation and a real use case
5. **Tools table** — Update the "Tool Availability by Agent" section

### 4. Verify and report

- Confirm the agent's jsdoc is complete
- Confirm `apps/docs/content/docs/agents/overview.mdx` reflects current state
- List any missing MCP tools (if agent needs new tools, suggest adding them via `/new-mcp-tool`)
- Report back to user with a summary of changes

---

## Example flow

**User:** "Document the quoting agent for Phase 7"

**You:**

1. Ask what tools the quoting agent will use
2. Check `apps/docs/content/docs/mcp/tools.mdx` for those tools
3. Add quoting agent section to `apps/docs/content/docs/agents/overview.mdx` with tools list
4. Suggest jsdoc for `apps/agents/quoting/src/index.ts`
5. Confirm changes and offer to verify the structure

---

## Notes

- Agent names are lowercase (`profile`, `quoting`, `order-routing`)
- Ports increment: profile=4002, quoting=4003, order-routing=4004, etc.
- All agents depend on `@flostack/agent` framework
- Available tools are defined in `apps/docs/content/docs/mcp/tools.mdx` (check there first before assuming a tool exists)
