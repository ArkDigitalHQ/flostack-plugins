# FloStack Plugins

**Free, practical [Claude Code](https://claude.com/claude-code) plugins by [FloStack](https://flostack.ca).**

Real AI workflows for marketing, SEO/GEO, and ops — the kind of thing we build
for clients, packaged up and given away. Install in two commands, no account, no
catch.

---

## Install

Add the marketplace, then install any plugin:

```
/plugin marketplace add ArkDigitalHQ/flostack-plugins
/plugin install geo-audit@flostack
```

That's it. The plugin's skills and slash commands are available immediately.

## Plugins

### `geo-audit` — Generative Engine Optimization toolkit

Optimize web content so it gets **surfaced and cited by AI answer engines**
(ChatGPT, Perplexity, Claude, Gemini, Google AI Overviews) — not just ranked in
classic search.

- **`geo-optimizer` skill** — kicks in when you're writing or reviewing web
  content. Walks the six GEO dimensions: entity clarity, answer-first structure,
  structured data, topical depth, authority signals, and technical foundation.
- **`/geo-audit [url-or-file]`** — scored GEO report (x/30) with specific,
  prioritized fixes.
- **`/geo-schema [url-or-file-or-description]`** — generates valid Schema.org
  JSON-LD (Organization, FAQPage, Article, Product, and more) ready to paste.

```
/geo-audit https://example.com
/geo-schema ./about.html
```

### `web-app-sdk` — Full-stack web app developer toolkit

For teams building TypeScript web apps on a shared monorepo stack: **Turborepo +
pnpm, Next.js App Router, Hono + tRPC + Zod, an MCP server, AI agents, and
Supabase (Postgres + RLS)**. Encodes a service-layer-first workflow and keeps
docs in sync as you build.

- **`architecture-conventions` skill** — auto-loads the mandatory rules
  (service-layer-first, pre-flight checklists, Next.js patterns, branch-per-task)
  whenever you work in a repo with this shape.
- **7 subagents** — `backend-architect`, `mcp-expert`, `code-reviewer`,
  `debugger`, `api-documenter`, `frontend-developer`, `ui-ux-designer`.
- **Workflow skills** — `/verify`, `/new-endpoint`, `/new-mcp-tool`,
  `/db-migration`, `/doc-agent`, `/update-docs`, `/check-docs`, `/add-adr`,
  `/agent-delegate`, `/agent-scope-check`, plus `/add-agent`, `/add-role`,
  `/add-notification`.
- **Hooks** — doc-sync reminders on edit, and a pre-push gate that runs
  tests/typecheck/lint/format before any `git push`.
- **`CLAUDE.md` template** — drop-in conventions file for new projects.

```
/plugin install web-app-sdk@flostack
```

## Need a custom plugin or integration?

These free plugins are a taste of what we do. FloStack builds **custom Claude
Code plugins, AI workflows, and integrations** wired into the tools you already
use.

**→ [flostack.ca/contact](https://flostack.ca/contact)**

## License

[MIT](LICENSE) — use them, fork them, ship them. Attribution appreciated, not
required.

---

*Built by [FloStack](https://flostack.ca) · custom AI workflows & integrations*
