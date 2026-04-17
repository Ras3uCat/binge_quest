# Feature: Fix Watch Party Members RLS — Update Policy

## Status
TODO

## Priority
High — security gap; members can currently self-accept invitations

## Overview
The `watch_party_members_update` policy has no `WITH CHECK` clause, meaning any member can
UPDATE their own row to any `status` value — including self-promoting from `pending → active`
without host approval.

## Live DB State (verified 2026-04-14)

### Policies on `watch_party_members`
| Policy | CMD | USING | WITH CHECK |
|---|---|---|---|
| `watch_party_members_update` | UPDATE | `user_id = auth.uid() OR is_party_owner(...)` | **null** ← gap |
| `watch_party_members_delete` | DELETE | `user_id = auth.uid() AND status = 'pending'` | — |
| `watch_party_members_insert` | INSERT | — | owner + friends only |
| `watch_party_members_select` | SELECT | owner or member | — |

### CHECK constraint
`watch_party_members_status_check` already exists:
```sql
CHECK (status = ANY (ARRAY['pending', 'active', 'left']))
```
Note: live DB uses `'left'` (not `'declined'`). The original feature draft had the wrong value.

## Acceptance Criteria
- [ ] A member cannot self-promote from `pending` → `active` via direct UPDATE.
- [ ] Only the party owner can set `status = 'active'` on another member's row.
- [ ] A member can update their own row to `status = 'left'` (leave the party).
- [ ] No regression on owner accepting/managing members.
- [ ] Existing valid rows with `'pending'`, `'active'`, or `'left'` are unaffected.

## Decision Required — Active Member Leave Path
Currently, only `status = 'pending'` rows can be deleted (decline invite). Active members
have **no way to leave** a party:
- DELETE policy: `user_id = auth.uid() AND status = 'pending'` — blocks active members
- UPDATE WITH CHECK: currently null (gap), so they *can* self-update today, but fixing this
  removes that escape hatch

**Chosen approach:** Allow members to self-update their own row to `status = 'left'`.
This gives active members a leave path without requiring a DELETE, and is consistent with
the existing CHECK constraint value `'left'`.

## Backend Changes

### Migration 066 (not 058 — that number is taken by `058_notification_delete_policy.sql`)

```sql
-- Drop and recreate update policy with WITH CHECK.
-- CHECK constraint already exists — do NOT add it again.
DROP POLICY IF EXISTS watch_party_members_update ON public.watch_party_members;

CREATE POLICY watch_party_members_update ON public.watch_party_members
  FOR UPDATE
  USING (
    -- Owner can update any member row
    is_party_owner(party_id, auth.uid())
    OR
    -- Member can only update their own row
    user_id = auth.uid()
  )
  WITH CHECK (
    -- Owner can set any valid status
    is_party_owner(party_id, auth.uid())
    OR
    -- Member can only set their own row to 'left' (leave party)
    (user_id = auth.uid() AND status = 'left')
  );
```

## Frontend Changes
If `status = 'left'` is used as the leave mechanism, the frontend `leaveParty()` in
`WatchPartyController` should be reviewed. Currently it calls `_repository.leaveParty(partyId)`
which likely DELETEs the row. If we keep DELETE for active members (expand the DELETE policy
instead), no frontend change is needed. Confirm repository implementation before shipping.

## QA Checklist
- [ ] Pending invitee cannot self-accept (UPDATE status → 'active') — returns RLS error.
- [ ] Active member can leave (UPDATE status → 'left') — succeeds.
- [ ] Owner can accept member (UPDATE status → 'active') — succeeds.
- [ ] Owner can remove member — confirm current DELETE policy covers this.
- [ ] Existing rows with 'pending', 'active', 'left' unaffected after migration.
