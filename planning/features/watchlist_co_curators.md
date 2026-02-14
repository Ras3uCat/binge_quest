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

## Analytics & Scoring

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
