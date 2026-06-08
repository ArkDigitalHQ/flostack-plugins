---
name: add-adr
description: Append a new Architectural Decision Record (ADR) to the docs site decisions log.
argument-hint: "[decision summary]"
allowed-tools: Read, Edit, Write
---

# /add-adr — Log an Architectural Decision

You are adding a new Architectural Decision Record (ADR) to `apps/docs/content/docs/reference/decisions.mdx` for the platform — a full-stack TypeScript monorepo.

## Context

`apps/docs/content/docs/reference/decisions.mdx` contains a chronological log of architectural decisions in ADR format. Each entry documents: the context that created a decision, the decision made, the reasoning behind it, the consequences, and alternatives considered.

## Steps

### 1. Gather the decision details

If the user has not provided the decision in the command, ask:

> "What architectural decision was made? Describe the context and what was decided."

Then clarify if needed:

- What problem or tradeoff triggered this decision?
- What alternatives were considered and rejected?
- What are the known downsides or constraints of the chosen approach?

### 2. Determine the next ADR number

Read `apps/docs/content/docs/reference/decisions.mdx` and find the highest existing ADR number (e.g. `ADR-008`). The new entry will be `ADR-009` (or whatever follows).

### 3. Write the ADR entry

Append the following to `apps/docs/content/docs/reference/decisions.mdx`:

```markdown
---

## ADR-<number> — <Short title>

**Date:** <YYYY-MM>
**Status:** Accepted

### Context

<What situation, constraint, or requirement made this decision necessary?>

### Decision

<What was decided, in one or two clear sentences.>

### Reasoning

<Why this option was chosen over the alternatives. Be specific.>

### Consequences

<What does this decision make easier? What does it make harder or constrain?>

### Alternatives considered

<Other approaches that were evaluated and why they were rejected.>
```

If there are no alternatives to document, omit that section.

### 4. Confirm

Report the full ADR entry back to the user and confirm it has been appended to `apps/docs/content/docs/reference/decisions.mdx`.
