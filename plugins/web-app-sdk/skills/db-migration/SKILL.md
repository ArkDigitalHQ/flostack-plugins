---
name: db-migration
description: Scaffold and apply a Supabase migration with RLS checklist and type regeneration.
argument-hint: "[schema change description]"
allowed-tools: Read, Write, Edit, Bash
---

# /db-migration — Scaffold and apply a Supabase migration

Run this command whenever your implementation requires a schema change: new table, new column, dropped column, index, constraint, RLS policy, or enum value.

---

## Step 1: Confirm a migration is needed

Review the changes you have made or are about to make. A migration is needed if any of the following apply:

- You are creating or dropping a table
- You are adding, renaming, or dropping a column
- You are adding or modifying an index or constraint
- You are changing or adding an RLS policy
- You are adding a value to a Postgres enum

If none of the above apply, stop — no migration is needed.

---

## Step 2: Generate the migration file name

Migration files must be named with a `YYYYMMDDHHMMSS` UTC timestamp prefix followed by a short snake_case description. Use the current UTC time.

Format: `supabase/migrations/<YYYYMMDDHHMMSS>_<description>.sql`

Example: `supabase/migrations/20260608143000_add_shipment_tracking_column.sql`

---

## Step 3: Write the migration SQL

Create the file at the path above. Write plain SQL — no `BEGIN`/`COMMIT` wrappers (Supabase wraps each migration in a transaction automatically).

Guidelines:

- Use `IF NOT EXISTS` / `IF EXISTS` guards where appropriate to make the migration idempotent
- Add a comment on each new column or table describing its purpose
- For new tables: include `created_at timestamptz not null default now()` and `updated_at timestamptz not null default now()` unless there is a specific reason not to

---

## Step 4: RLS checklist

Answer each question. If the answer is yes, add the corresponding SQL to the migration file.

| Question                                                              | Required action                                                                   |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Is this a new table?                                                  | Add `alter table <table> enable row level security;` and at minimum one policy    |
| Does a new column contain data that should be scoped per user or org? | Add or update the relevant RLS policy to include it                               |
| Does the new table need service-role bypass?                          | The admin client (service role key) bypasses RLS automatically — no action needed |

If you are unsure about the correct RLS policy, check an existing table in the same domain for the pattern to follow. Common patterns are in `supabase/migrations/` history.

---

## Step 5: Regenerate TypeScript types

After writing the migration file, run:

```bash
pnpm db:gen-types
```

This regenerates `packages/db/src/types.ts` from the staging schema. Do not edit `packages/db/src/types.ts` manually.

If `pnpm db:gen-types` fails because the migration has not been applied to staging yet, that is expected — the migration runs automatically when the branch is merged to `main`. Proceed with the types file as-is; CI will confirm correctness after merge.

---

## Step 6: Note the migration in your PR description

When you open the PR, include a **Schema changes** section in the PR body listing:

- The migration file name
- What the migration does in one line
- Whether RLS was updated

---

## Output

After completing all steps, output:

```
## /db-migration complete

Migration file: supabase/migrations/<filename>.sql
Schema change: <one-line summary>
RLS updated: yes / no
Types regenerated: yes / skipped (migration not yet applied to staging)
```
