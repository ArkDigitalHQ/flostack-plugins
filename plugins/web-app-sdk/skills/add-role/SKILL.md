---
name: add-role
description: Add a new app role or org role to the platform, including permissions, domain access, and notification preferences
---

# Skill: Add a Role

Use this skill when a developer asks to:

- Add a new role
- Create a new role type
- Extend the role system

---

## How this works

Roles come in two flavors:

- **App roles** (`AppRole`): Global platform access — `admin | staff | customer` (and any new ones)
- **Org roles** (`OrgRole`): Scoped to a specific organization — `owner | coach | assistant_coach | manager | parent | player | account_manager`

You MUST assign every new role to at least one notification domain before completing this task.

---

## Step 1: Read current state

```bash
cat packages/services/src/users.ts          # AppRole, ROLE_PERMISSIONS, ROLE_HIERARCHY
cat packages/services/src/organization-members.ts  # OrgRole, ORG_ROLE_PERMISSIONS
cat packages/services/src/roles.ts          # APP_ROLES, ORG_ROLES descriptors
cat packages/services/src/notifications/domains.ts  # DOMAINS eligibleRoles
```

---

## Step 2: Add enum value (DB migration)

For **app roles** only — org roles use the `org_role` enum, app roles use `app_role`.

Create a new migration in `supabase/migrations/`:

```sql
-- Add new app role
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'dispatcher';
```

Then run `pnpm db:gen-types` to regenerate `packages/db/src/types.ts`.

---

## Step 3: Update the schema in `users.ts` or `organization-members.ts`

**For app roles** (`packages/services/src/users.ts`):

```typescript
const appRoleSchema = z.enum(['admin', 'staff', 'customer', 'dispatcher'])
// AppRole type is derived from the DB enum via Database['public']['Enums']['app_role']
// — it auto-updates after pnpm db:gen-types
```

Update `ROLE_HIERARCHY`:

```typescript
export const ROLE_HIERARCHY: Record<AppRole, number> = {
  admin: 1,
  staff: 2,
  customer: 3,
  dispatcher: 4, // choose appropriate level
}
```

Update `ROLE_PERMISSIONS`:

```typescript
export const ROLE_PERMISSIONS = {
  // ...existing roles...
  dispatcher: {
    manageUsers: false,
    manageCustomers: false,
    assignRoles: false,
    deactivateUsers: false,
    viewAdminDashboard: true, // can dispatchers see /admin?
    manageOrders: true,
    manageQuotes: false,
    manageOrganizations: false,
    manageAllMembers: false,
    manageAllRosters: false,
    viewPortal: true,
  },
}
```

**For org roles** (`packages/services/src/organization-members.ts`):

```typescript
export const orgRoleSchema = z.enum([
  'owner',
  'coach',
  'assistant_coach',
  'manager',
  'parent',
  'player',
  'account_manager',
  'trainer', // new role
])

export const ORG_ROLE_PERMISSIONS = {
  // ...existing roles...
  trainer: {
    manageOrgProfile: false,
    manageOrgMembers: false,
    manageOrgRoster: true,
    viewOrgMembers: true,
    viewOrgRoster: true,
  },
}
```

---

## Step 4: Add descriptor to `roles.ts`

In `packages/services/src/roles.ts`:

```typescript
export const APP_ROLES: Record<AppRole, RoleDescriptor> = {
  // ...existing...
  dispatcher: {
    label: 'Dispatcher',
    description: 'Manages order routing and fulfillment',
    level: 4,
    internal: true, // true = internal staff. false = customer-facing
  },
}
```

---

## Step 5: Assign to notification domains (REQUIRED)

In `packages/services/src/notifications/domains.ts`, update `eligibleRoles` for the relevant domains.

**This step is mandatory.** A role with no domain gets no notifications and won't appear in preferences.

```typescript
export const DOMAINS: Record<DomainId, NotificationDomain> = {
  platform: {
    // 'dispatcher' needs platform notifications? Add to eligibleRoles:
    eligibleRoles: ['admin', 'dispatcher'],
    // ...
  },
  account: {
    eligibleRoles: ['*'], // '*' means all roles
    // ...
  },
  organizations: {
    eligibleRoles: ['*'],
    // ...
  },
}
```

---

## Step 6: Update notification_preferences defaults in `role-sync.ts`

In `packages/services/src/notifications/role-sync.ts`, `ROLE_DEFAULT_DOMAINS` maps each role to its accessible domain IDs. This is used when initializing preferences for newly assigned roles.

```typescript
const ROLE_DEFAULT_DOMAINS: Partial<Record<string, string[]>> = {
  admin: ['platform', 'account', 'organizations'],
  staff: ['account', 'organizations'],
  customer: ['account', 'organizations'],
  dispatcher: ['platform', 'account'], // add your new role here
}
```

---

## Step 7: Update tRPC role guards (if needed)

If the new role needs a dedicated middleware procedure (like `adminProcedure` or `staffOrAdminProcedure`), add it in `apps/api/src/trpc.ts`:

```typescript
export const dispatcherProcedure = protectedProcedure.use(({ ctx, next }) => {
  if (ctx.appRole !== 'admin' && ctx.appRole !== 'dispatcher') {
    throw new TRPCError({ code: 'FORBIDDEN', message: 'Dispatcher access required' })
  }
  return next({ ctx })
})
```

---

## Step 8: Run `pnpm db:gen-types`

After applying the migration:

```bash
supabase db reset          # or: supabase db push (for staging/prod)
pnpm db:gen-types          # regenerate packages/db/src/types.ts
pnpm typecheck             # verify everything compiles
```

---

## Self-check checklist

- [ ] DB migration created for new enum value (app roles only)
- [ ] `appRoleSchema` / `orgRoleSchema` updated in the service file
- [ ] `ROLE_HIERARCHY` updated (app roles only)
- [ ] `ROLE_PERMISSIONS` / `ORG_ROLE_PERMISSIONS` updated
- [ ] `APP_ROLES` / `ORG_ROLES` descriptor added in `roles.ts`
- [ ] Role assigned to at least one domain in `DOMAINS.eligibleRoles` ← **REQUIRED**
- [ ] `ROLE_DEFAULT_DOMAINS` updated in `role-sync.ts`
- [ ] `pnpm db:gen-types` run
- [ ] `pnpm typecheck` passes

---

## Worked example: adding a "dispatcher" app role

1. Migration: `ALTER TYPE app_role ADD VALUE 'dispatcher';`
2. `appRoleSchema`: add `'dispatcher'`
3. `ROLE_HIERARCHY`: `{ dispatcher: 4 }`
4. `ROLE_PERMISSIONS`: `{ dispatcher: { viewAdminDashboard: true, manageOrders: true, ... } }`
5. `APP_ROLES`: `{ dispatcher: { label: 'Dispatcher', description: '...', level: 4, internal: true } }`
6. `DOMAINS.platform.eligibleRoles`: add `'dispatcher'`
7. `ROLE_DEFAULT_DOMAINS`: `{ dispatcher: ['platform', 'account'] }`
8. `pnpm db:gen-types && pnpm typecheck`
