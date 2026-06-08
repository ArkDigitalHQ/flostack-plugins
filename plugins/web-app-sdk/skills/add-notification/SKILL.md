---
name: add-notification
description: Add a new notification rule and/or activity feed entry for a domain event in the platform notification system
---

# Skill: Add a Notification

Use this skill when a developer asks to:

- Add a notification for a new event
- Notify users when something happens
- Wire up an alert for a domain event
- Add an entry to the activity feed

---

## How this works

All notifications flow through the event bus. **Never call `notificationService` directly** — always use `eventBus.emit()` in service functions. The processor handles routing to recipients.

---

## Step 1: Read current state

First, read the live files to understand what's there:

```bash
# Read current event types
cat packages/services/src/events/types.ts

# Read current notification rules
cat packages/services/src/notifications/rules.ts

# Read current activity rules
cat packages/services/src/activity/rules.ts
```

---

## Step 2: Add the AppEvent type

In `packages/services/src/events/types.ts`, add a new interface:

```typescript
export interface <EventName>Event extends BaseEvent {
  type: '<domain>.<event>'    // e.g. 'order.shipped', 'roster.entry_added'
  domain: '<domain_id>'       // 'platform' | 'account' | 'organizations'
  payload: {
    // ALWAYS include denormalized display names — processor never does extra DB lookups
    // e.g. orgName instead of just orgId
    orgId: string
    orgName: string
    // ... your event-specific fields
  }
}
```

Then add it to the `AppEvent` union at the bottom:

```typescript
export type AppEvent = ... | <EventName>Event
```

**Payload rules:**

- Include enough data to render the notification title + body WITHOUT extra DB queries
- Names over IDs: pass `orgName`, `userName`, `playerName` alongside the IDs
- Keep payload flat — no nested objects

---

## Step 3: Add a NotificationRule

In `packages/services/src/notifications/rules.ts`, add to `NOTIFICATION_RULES`:

```typescript
{
  event: '<domain>.<event>',
  domain: '<domain_id>',             // 'platform' | 'account' | 'organizations'
  audience_description: 'Who receives this (human-readable)',

  // Choose ONE recipient strategy:
  recipients: 'org_members',         // all active members of the org in payload.orgId
  // recipients: 'self',             // just payload.userId
  // recipients: 'admin_only',       // all active admins
  // recipients: (event) => [ids],   // custom function returning user IDs

  excludeActor: true,                // default: true. Set false if actor should also receive
  deduplication_window_seconds: 0,   // 0 = no dedup. 60-300 for noisy events.

  template: (event) => {
    const e = event as <EventName>Event
    return {
      type: 'ACTIVITY' as const,     // SYSTEM | ALERT | MESSAGE | ACTIVITY | MARKETING
      title: '<Concise title>',
      body: `<Description using ${e.payload.orgName} etc>`,
      action_url: `/orgs/${e.payload.orgId}`,  // optional
      group_key: `<event>-${e.payload.orgId}`, // optional: dedupes toasts/badges by key
    }
  },
},
```

**deduplication_window_seconds guidance:**

- `0` — no dedup (events that happen once)
- `60` — noisy member join/leave events
- `300` — org profile updates (user updates logo 3 times in a row → 1 notification)

---

## Step 4: Add an ActivityRule (if needed)

Only add this if the event should appear in the per-user activity feed.

In `packages/services/src/activity/rules.ts`, add to `ACTIVITY_RULES`:

```typescript
{
  event: '<domain>.<event>',
  domain: '<domain_id>',
  feed_owner: 'org_members',    // same strategies as NotificationRule recipients
  template: (event) => {
    const e = event as <EventName>Event
    return {
      label: `<Human-readable description of what happened>`,
      target_type: '<entity_type>',   // e.g. 'org', 'roster_entry', 'user'
      target_id: e.payload.orgId,
    }
  },
},
```

---

## Step 5: Emit in the service function

In `packages/services/src/<domain>.ts`, add `eventBus.emit()` after the successful DB operation:

```typescript
import { eventBus } from './events/bus.js'

export async function myServiceFunction(supabase, input, actorId?: string) {
  const { data, error } = await supabase.from('table')...
  if (error) throw error

  // Fetch any denormalized names not available in `data` (best-effort)
  const { data: org } = await supabase.from('organizations').select('name').eq('id', data.org_id).single()

  eventBus.emit({
    id: crypto.randomUUID(),
    type: '<domain>.<event>',
    domain: '<domain_id>',
    actor_id: actorId,
    timestamp: new Date().toISOString(),
    payload: {
      orgId: data.org_id,
      orgName: org?.name ?? '',
      // ... rest of payload
    },
  })

  return data
}
```

Then in the tRPC router that calls this function, pass `ctx.user.id` as `actorId`:

```typescript
return myServiceFunction(ctx.supabase, input, ctx.user.id)
```

---

## Self-check checklist

- [ ] AppEvent interface added with denormalized payload fields
- [ ] AppEvent added to `AppEvent` union in `types.ts`
- [ ] NotificationRule added to `NOTIFICATION_RULES`
- [ ] ActivityRule added to `ACTIVITY_RULES` (if feed entry needed)
- [ ] `eventBus.emit()` added to the service function — NOT `notificationService` directly
- [ ] `actorId` parameter added to service function signature (optional: `actorId?: string`)
- [ ] tRPC router passes `ctx.user.id` as `actorId`
- [ ] `pnpm typecheck` passes

---

## Worked example: org_member.joined (already implemented)

**Event type** (`events/types.ts`):

```typescript
export interface OrgMemberJoinedEvent extends BaseEvent {
  type: 'org_member.joined'
  domain: 'organizations'
  payload: {
    orgId: string
    orgName: string
    userId: string
    userName: string | null
    userEmail: string
    role: string
  }
}
```

**NotificationRule** (recipients = org_members, dedup 60s):

```typescript
{
  event: 'org_member.joined',
  domain: 'organizations',
  recipients: 'org_members',
  excludeActor: true,
  deduplication_window_seconds: 60,
  template: (event) => ({
    type: 'ACTIVITY',
    title: 'New member joined',
    body: `${e.payload.userName ?? e.payload.userEmail} joined ${e.payload.orgName} as ${e.payload.role}`,
    action_url: `/orgs/${e.payload.orgId}`,
    group_key: `org-members-${e.payload.orgId}`,
  }),
},
```

**ActivityRule**:

```typescript
{
  event: 'org_member.joined',
  domain: 'organizations',
  feed_owner: 'org_members',
  template: (event) => ({
    label: `${e.payload.userName ?? e.payload.userEmail} joined ${e.payload.orgName} as ${e.payload.role}`,
    target_type: 'org',
    target_id: e.payload.orgId,
  }),
},
```

**Emission** (in `addMember()` service function):

```typescript
eventBus.emit({
  id: crypto.randomUUID(),
  type: 'org_member.joined',
  domain: 'organizations',
  actor_id: actorId,
  timestamp: new Date().toISOString(),
  payload: { orgId, orgName, userId, userName, userEmail, role },
})
```
