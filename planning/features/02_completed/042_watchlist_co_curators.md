# Feature: Watchlist Co-Curators

## Status
TODO

## Overview
Allow users to invite others to be co-curators of a watchlist. Co-curators can add, update, and remove items from the shared watchlist, enabling collaborative list management for couples, roommates, or friend groups.

## User Stories
- As a user, I want to share a watchlist with my partner so we can both add shows
- As a user, I want to invite my roommate to our shared "Apartment Watchlist"
- As a user, I want to see who added an item to a shared watchlist
- As a user, I want to remove a co-curator if needed

## Acceptance Criteria
- [ ] Invite user to be co-curator via email or username
- [ ] Invitee receives notification and can accept/decline
- [ ] Co-curators can: add items, mark watched, remove items
- [ ] Curator can: all co-curator permissions + remove co-curators + delete list
- [ ] Activity feed shows who did what (optional v2)
- [ ] Co-curated lists have visual indicator
- [ ] User can leave a co-curated list

## Roles & Permissions

| Action | Curator | Co-Curator |
|--------|-------|----------|
| Add items | Yes | Yes |
| Remove items | Yes | Yes |
| Mark watched | Yes | Yes |
| Rename list | Yes | No |
| Invite co-curator | Yes | No |
| Remove co-curator | Yes | No |
| Delete list | Yes | No |
| Transfer ownership | Yes | No |
| Leave list | N/A | Yes |

## Data Model

### watchlist_members
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| watchlist_id | UUID | FK to watchlists |
| user_id | UUID | FK to users |
| role | TEXT | 'curator' or 'co_curator' (formerly 'owner'/'co_owner') |
| invited_by | UUID | FK to users (who invited) |
| status | TEXT | 'pending', 'accepted', 'declined' |
| created_at | TIMESTAMPTZ | - |
| accepted_at | TIMESTAMPTZ | When accepted |

### watchlist_activity (optional v2)
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| watchlist_id | UUID | FK to watchlists |
| user_id | UUID | Who performed action |
| action | TEXT | 'added', 'removed', 'watched' |
| item_title | TEXT | What was affected |
| created_at | TIMESTAMPTZ | - |

## Backend Changes
- Migration for `watchlist_members` table
- Update RLS policies to allow co-curator access
- Invitation system (could use existing notification infrastructure)
- Update watchlist queries to include membership check

## RLS Policy Updates
```sql
-- Allow co-curators to read watchlist
CREATE POLICY "Co-curators can read watchlist"
ON watchlists FOR SELECT
USING (
  id IN (
    SELECT watchlist_id FROM watchlist_members
    WHERE user_id = auth.uid() AND status = 'accepted'
  )
);

-- Allow co-curators to modify items
CREATE POLICY "Co-curators can modify items"
ON watchlist_items FOR ALL
USING (
  watchlist_id IN (
    SELECT watchlist_id FROM watchlist_members
    WHERE user_id = auth.uid() AND status = 'accepted'
  )
);
```

## Frontend Changes
- `WatchlistMembersRepository`
- Invite flow UI (search user, send invite)
- Manage members UI (view, remove co-curators)
- Pending invitations UI
- Co-curated list indicator icon
- "Added by" label on items (optional)

## UI Mockups

### Watchlist Settings
```
┌─────────────────────────────┐
│ Movie Night List      [⚙️]  │
├─────────────────────────────┤
│ Members                     │
│ ┌─────────────────────────┐ │
│ │ 👤 You (Curator)        │ │
│ │ 👤 Alex (Co-curator) [x]│ │
│ │ 👤 Sam (Pending...)     │ │
│ └─────────────────────────┘ │
│                             │
│ [+ Invite Co-curator]       │
└─────────────────────────────┘
```

### List Indicator
```
┌──────────────────┐
│ 👥 Movie Night   │  👥 = shared list icon
│ 3 items          │
└──────────────────┘
```

## Ownership Transfer on Delete

### Behavior
When the curator attempts to delete a watchlist that has **active co-curators** (status = `accepted`), the app intercepts with a choice dialog instead of immediately deleting:

1. **"Transfer to [name]"** -- Transfers ownership to a co-curator. The list, all items, and all progress are preserved. The original curator is removed from the list entirely.
2. **"Delete for everyone"** -- Existing cascade behavior. Wipes the list, items, progress, and all membership records.

If the watchlist has **no active co-curators**, the delete proceeds immediately (no dialog).

### Transfer Flow

```
Curator taps "Delete Watchlist"
  │
  ├── No active co-curators?
  │     └── Confirm dialog: "Delete [list name]? This cannot be undone."
  │           └── DELETE → cascade wipe
  │
  └── Has active co-curators?
        └── Choice dialog:
              ┌────────────────────────────────────┐
              │ This list has co-curators           │
              │                                     │
              │ Transfer ownership so the list      │
              │ lives on, or delete for everyone.   │
              │                                     │
              │ Transfer to:                        │
              │ ○ Alex                              │
              │ ○ Sam                               │
              │                                     │
              │ [Transfer & Leave]  [Delete for All]│
              └────────────────────────────────────┘
```

- If multiple co-curators exist, the curator picks which one receives ownership.
- If only one co-curator exists, that person is pre-selected (no radio buttons, just their name shown).

### Transfer Logic (single transaction)

```sql
-- 1. Change watchlist owner
UPDATE watchlists SET user_id = p_new_owner_id WHERE id = p_watchlist_id;

-- 2. Promote the co-curator to curator
UPDATE watchlist_members
  SET role = 'owner'
  WHERE watchlist_id = p_watchlist_id AND user_id = p_new_owner_id;

-- 3. Remove the old curator's membership row
DELETE FROM watchlist_members
  WHERE watchlist_id = p_watchlist_id AND user_id = p_old_owner_id;
```

All three statements must run atomically. Implemented as a SECURITY DEFINER RPC function.

### RPC: `transfer_watchlist_ownership`

```sql
CREATE OR REPLACE FUNCTION public.transfer_watchlist_ownership(
  p_watchlist_id UUID,
  p_new_owner_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_old_owner_id UUID;
BEGIN
  -- Verify caller is the current owner
  SELECT user_id INTO v_old_owner_id
  FROM watchlists
  WHERE id = p_watchlist_id;

  IF v_old_owner_id IS NULL THEN
    RAISE EXCEPTION 'Watchlist not found';
  END IF;

  IF v_old_owner_id != auth.uid() THEN
    RAISE EXCEPTION 'Only the curator can transfer ownership';
  END IF;

  -- Verify new owner is an active co-curator
  IF NOT EXISTS (
    SELECT 1 FROM watchlist_members
    WHERE watchlist_id = p_watchlist_id
      AND user_id = p_new_owner_id
      AND status = 'accepted'
  ) THEN
    RAISE EXCEPTION 'Target user is not an active co-curator';
  END IF;

  -- Atomic transfer
  UPDATE watchlists SET user_id = p_new_owner_id WHERE id = p_watchlist_id;

  UPDATE watchlist_members
    SET role = 'owner'
    WHERE watchlist_id = p_watchlist_id AND user_id = p_new_owner_id;

  DELETE FROM watchlist_members
    WHERE watchlist_id = p_watchlist_id AND user_id = v_old_owner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

### Notification
- Push to new owner: "You're now the curator of [list name]"
- Uses existing `send-notification` Edge Function with category `social`

### Frontend Changes

| File | Change |
|------|--------|
| `WatchlistMemberRepository` | Add `transferOwnership(watchlistId, newOwnerId)` calling RPC |
| `WatchlistController` (or equivalent) | Intercept delete action: check if active co-curators exist, show transfer dialog |
| New widget: `TransferOwnershipDialog` | Choice dialog with co-curator list, "Transfer & Leave" / "Delete for All" buttons |

### Edge Cases
- **Default watchlist:** Cannot be transferred (default lists are per-user). Transfer option hidden for default lists.
- **Curator is the only member:** No dialog, direct delete.
- **Transfer target declines later:** N/A -- transfer is instant, no acceptance step needed (they're already an active co-curator).
- **Curator wants to leave without deleting:** Same flow -- transfer ownership first, then they're removed. The "Leave list" action for curators should trigger this same dialog.

### Acceptance Criteria
- [ ] Deleting a watchlist with active co-curators shows transfer dialog
- [ ] Deleting a watchlist with no co-curators skips dialog (direct delete)
- [ ] Transfer changes `watchlists.user_id` to the new owner
- [ ] Transfer promotes co-curator role to `owner` in `watchlist_members`
- [ ] Transfer removes old curator from `watchlist_members`
- [ ] All items and progress are preserved after transfer
- [ ] New owner receives push notification
- [ ] "Delete for All" still works as a full cascade delete
- [ ] Default watchlists cannot be transferred
- [ ] RPC rejects non-owner callers
- [ ] RPC rejects transfer to non-active co-curators

---



### Top 10 Most Watched Logic
When calculating the "Top 10 Most Watched" (or similar popularity metrics):
- **Each user** who has an item on **any** of their watchlists counts as **1 vote** for that item.
- For **co-curated (shared) watchlists**:
  - The item counts for **every** member (Curator and all Co-curators) of the list.
  - Example: If a watchlist has 1 Curator and 2 Co-curators (3 members total) and contains the movie "Inception", then "Inception" receives **3** popularity points (1 from each member).
- This ensures that popularity reflects the true number of users interested in the content, regardless of whether they organize their lists individually or collaboratively.

## Dependencies
- Friend system may be prerequisite (or allow invite by email)
- Push notification system for invites

## QA Checklist
- [ ] Can invite user to co-curate list
- [ ] Invitee receives notification
- [ ] Accept/decline works
- [ ] Co-curator can add items
- [ ] Co-curator can mark watched
- [ ] Co-curator can remove items
- [ ] Co-curator cannot delete list
- [ ] Curator can remove co-curator
- [ ] Co-curator can leave list
- [ ] Shared list shows indicator
- [ ] Delete with co-curators shows transfer dialog
- [ ] Delete without co-curators skips dialog
- [ ] Transfer preserves all items and progress
- [ ] New owner gets curator role and push notification
- [ ] Old curator is fully removed from the list
- [ ] Default watchlist cannot be transferred
- [ ] RPC rejects unauthorized callers
