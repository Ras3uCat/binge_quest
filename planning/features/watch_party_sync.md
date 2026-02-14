# Feature: Watch Party Sync

## Status
TODO (on hold)

## Overview
Allow users to share watch progress for a specific TV show or movie with friends in real-time. For TV shows, users see per-episode progress across season tabs; for movies, users see percentage-based progress bars. Makes it easy to coordinate viewing and avoid spoilers.

## User Stories
- As a user, I want to see where my friends are in a show we're all watching
- As a user, I want to know if I'm ahead or behind my watch group
- As a user, I want real-time updates as friends mark episodes watched
- As a user, I want to create a watch party for a TV show or movie from my watchlist
- As a user, I want to track partial progress (e.g., "Sarah is 50% through Episode 4")

## Acceptance Criteria
- [ ] Create a "watch party" for a TV show or movie (from watchlist item page)
- [ ] Invite friends to join the party (max 10 active members)
- [ ] See all members' progress in real-time (via Supabase Realtime on denormalized table)
- [ ] TV shows: season tabs with per-member episode grid (0-100% per episode)
- [ ] Movies: per-member progress bar (0-100%)
- [ ] Partial progress for both TV episodes and movies (e.g., "Sarah is 50% through Episode 4")
- [ ] Visual indicator showing who's ahead/behind
- [ ] Push notification when party member watches an episode / updates movie progress
- [ ] "Catch up" indicator for users who are behind
- [ ] Leave party option (with rejoin support — creator can re-invite)
- [ ] Party list section in Social/Friends tab

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Content types | TV shows + movies | TV: per-episode progress with season tabs. Movies: percentage-based progress (0-100%). Both support partial progress. |
| Party scope (TV) | Whole show + season tabs | Party tracks all seasons; UI provides season tabs defaulting to the latest active season. Simpler data model than per-season parties. |
| Realtime strategy | Denormalized `watch_party_progress` + Realtime | `watch_progress` is keyed by `watchlist_item_id` — no direct `user_id` or `tmdb_id` to filter on. Denormalized table provides clean `party_id` filter. DB trigger keeps it synced. |
| Member cap | 10 active members | Keeps the progress visualization readable and Realtime payload small. |
| Rejoin | Allowed | Creator can re-invite a member who left. Same `watch_party_members` row reused (status flipped `left` → `pending`). |
| Entry point | Watchlist item page | "Create Watch Party" button on the watchlist item detail page (TV + movie). Party list lives in Social/Friends tab. |
| Invite scope | Friends only | Invites gated behind accepted friendship via `are_friends()` helper. |
| Party deletion | Creator only | When creator deletes party, all member rows and progress rows cascade-delete. |
| Progress writes | Trigger-only | `watch_party_progress` is written exclusively by a SECURITY DEFINER trigger on `watch_progress`. No direct user writes. |

---

## Data Model

### watch_parties
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Primary key |
| name | TEXT | NOT NULL | Party name (user-provided) |
| tmdb_id | INTEGER | NOT NULL | TV show or movie TMDB ID |
| media_type | TEXT | NOT NULL, CHECK IN ('tv', 'movie') | Content type |
| created_by | UUID | NOT NULL, FK auth.users ON DELETE CASCADE | Party creator |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Creation timestamp |

**Indexes:**
- `idx_watch_parties_created_by` on `created_by`
- `idx_watch_parties_tmdb_id` on `(tmdb_id, media_type)`

### watch_party_members
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Primary key |
| party_id | UUID | NOT NULL, FK watch_parties ON DELETE CASCADE | Parent party |
| user_id | UUID | NOT NULL, FK auth.users ON DELETE CASCADE | Member |
| status | TEXT | NOT NULL, DEFAULT 'pending', CHECK IN ('pending', 'active', 'left') | Membership state |
| joined_at | TIMESTAMPTZ | NULL | Set when status → 'active' |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | When invited |

**Constraints:**
- `UNIQUE(party_id, user_id)` — one row per member per party; rejoin reuses the row
- 10-member cap enforced via trigger (count active members before INSERT/UPDATE to 'active')

**Indexes:**
- `idx_watch_party_members_user_id` on `user_id`
- `idx_watch_party_members_party_status` on `(party_id, status)`

### watch_party_progress (denormalized, trigger-synced)
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Primary key |
| party_id | UUID | NOT NULL, FK watch_parties ON DELETE CASCADE | Parent party |
| user_id | UUID | NOT NULL, FK auth.users ON DELETE CASCADE | Member |
| season_number | INTEGER | NOT NULL, DEFAULT 0 | 0 for movies, 1+ for TV seasons |
| episode_number | INTEGER | NOT NULL, DEFAULT 0 | 0 for movies, 1+ for TV episodes |
| progress_percent | INTEGER | NOT NULL, DEFAULT 0, CHECK BETWEEN 0 AND 100 | Granular progress for both TV episodes and movies |
| watched | BOOLEAN | NOT NULL, DEFAULT false | True when fully watched (100%) |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Last sync time |

**Constraints:**
- `UNIQUE(party_id, user_id, season_number, episode_number)` — one row per member per episode (or per movie)

**Indexes:**
- `idx_watch_party_progress_party_id` on `party_id` (Realtime filter column)
- `idx_watch_party_progress_user_party` on `(user_id, party_id)`

---

## RLS Strategy

### watch_parties
| Operation | Policy |
|-----------|--------|
| SELECT | User is an active member (`EXISTS` on `watch_party_members` WHERE `status = 'active'` AND `user_id = auth.uid()`) OR user is the creator |
| INSERT | `auth.uid() = created_by` |
| UPDATE | `auth.uid() = created_by` (rename party only) |
| DELETE | `auth.uid() = created_by` |

### watch_party_members
| Operation | Policy |
|-----------|--------|
| SELECT | User is a member of the same party (any status) OR user is the party creator |
| INSERT | Only party creator can invite; invitee must be a friend (`are_friends(auth.uid(), user_id)`); invitee not blocked (`NOT is_blocked(auth.uid(), user_id)`) |
| UPDATE | Invitee can accept (`status: 'pending' → 'active'`); any member can leave (`status → 'left'`); creator can re-invite (`status: 'left' → 'pending'`) |
| DELETE | No direct deletes — use status transitions. Cascade from party deletion handles cleanup. |

### watch_party_progress
| Operation | Policy |
|-----------|--------|
| SELECT | User is an active member of the party |
| INSERT | None — written only by SECURITY DEFINER trigger |
| UPDATE | None — written only by SECURITY DEFINER trigger |
| DELETE | None — cascade from party deletion handles cleanup |

---

## Real-Time Implementation (Denormalized Progress)

### Architecture
1. **DB trigger** on `watch_progress` INSERT/UPDATE (SECURITY DEFINER function)
   - Resolves `tmdb_id` and `user_id` via `watchlist_items → watchlists` join
   - Finds all active watch parties where the user is an active member AND `tmdb_id` matches
   - Upserts into `watch_party_progress` for each matching party
   - Sets `watched = true` when `progress_percent = 100`
2. **Realtime publication** on `watch_party_progress`
3. **Client subscribes** to `watch_party_progress` filtered by `party_id`

### Trigger Function (pseudocode)
```sql
CREATE OR REPLACE FUNCTION sync_watch_party_progress()
RETURNS TRIGGER AS $$
DECLARE
  v_tmdb_id INTEGER;
  v_media_type TEXT;
  v_user_id UUID;
  v_party RECORD;
BEGIN
  -- Resolve the content and user from the watchlist chain
  SELECT wi.tmdb_id, wi.media_type, w.user_id
  INTO v_tmdb_id, v_media_type, v_user_id
  FROM watchlist_items wi
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE wi.id = NEW.watchlist_item_id;

  -- Find all active watch parties this user belongs to for this content
  FOR v_party IN
    SELECT wp.id AS party_id
    FROM watch_parties wp
    JOIN watch_party_members wpm ON wpm.party_id = wp.id
    WHERE wp.tmdb_id = v_tmdb_id
      AND wp.media_type = v_media_type
      AND wpm.user_id = v_user_id
      AND wpm.status = 'active'
  LOOP
    -- Upsert progress row
    INSERT INTO watch_party_progress (party_id, user_id, season_number, episode_number, progress_percent, watched, updated_at)
    VALUES (v_party.party_id, v_user_id, NEW.season_number, NEW.episode_number, NEW.progress_percent, NEW.progress_percent >= 100, now())
    ON CONFLICT (party_id, user_id, season_number, episode_number)
    DO UPDATE SET
      progress_percent = EXCLUDED.progress_percent,
      watched = EXCLUDED.watched,
      updated_at = now();
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_sync_watch_party_progress
  AFTER INSERT OR UPDATE ON watch_progress
  FOR EACH ROW
  EXECUTE FUNCTION sync_watch_party_progress();
```

### Realtime Subscription (client)
```dart
final channel = supabase.channel('party:$partyId');
channel.onPostgresChanges(
  event: PostgresChangeEvent.all,
  schema: 'public',
  table: 'watch_party_progress',
  filter: PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'party_id',
    value: partyId,
  ),
  callback: (payload) => _handleProgressUpdate(payload),
).subscribe();
```

### Why denormalized?
- `watch_progress` is keyed by `watchlist_item_id`, not `(user_id, tmdb_id)` — Realtime can't filter by party members directly
- Denormalized table provides clean `party_id` filter — no multi-table joins at query time
- DB trigger ensures sync regardless of where user marks progress (watchlist screen, party view, etc.)
- Max data volume: 10 members x ~24 episodes per season = tiny

---

## Notification Integration

Uses existing `send-notification` Edge Function with category `social`.

| Event | Trigger | Notification |
|-------|---------|-------------|
| Watch party invite | Client-side after member INSERT | Push to invitee: "{username} invited you to a watch party for {show_name}" |
| Invite accepted | Client-side after member status → 'active' | Push to creator: "{username} joined your {show_name} watch party" |
| Member progress update | DB trigger on `watch_party_progress` upsert | Push to other active members (when app not open): "{username} watched Episode {n} of {show_name}" |
| Party deleted | Client-side after party DELETE | Push to all active members: "{show_name} watch party was ended by {creator}" |

**Progress notification throttling:** To avoid spam, only notify on episode completion (`watched = true`) or significant movie progress jumps (crossing 25% / 50% / 75% / 100% thresholds). Partial episode progress changes should NOT trigger push notifications.

---

## Migration 035: `watch_party_sync`

### Scope
1. Create `watch_parties` table with constraints and indexes
2. Create `watch_party_members` table with UNIQUE constraint and indexes
3. Create `watch_party_progress` table with UNIQUE constraint and indexes
4. Create `enforce_party_member_cap()` trigger function (BEFORE INSERT/UPDATE on `watch_party_members`, rejects if 10+ active members)
5. Create `sync_watch_party_progress()` SECURITY DEFINER trigger function on `watch_progress`
6. Enable RLS on all three tables with policies per RLS Strategy section
7. `ALTER PUBLICATION supabase_realtime ADD TABLE watch_party_progress`

---

## UI Design

### TV Show Party Progress View
```
┌─────────────────────────────────────┐
│ Severance Watch Party               │
│ [Season 1] [Season 2]  ← tabs      │
├─────────────────────────────────────┤
│                                     │
│ Episode Progress:                   │
│ ┌─────────────────────────────────┐ │
│ │ 1  2  3  4  5  6  7  8  9  10  │ │
│ │ ●  ●  ●  ●  ◐  ○  ○  ○  ○  ○   │ │ You (Ep 5 · 50%)
│ │ ●  ●  ●  ●  ●  ●  ●  ○  ○  ○   │ │ Alex (Ep 7)
│ │ ●  ●  ◐  ○  ○  ○  ○  ○  ○  ○   │ │ Sam (Ep 3 · 30%)
│ └─────────────────────────────────┘ │
│                                     │
│ Sam is 2 episodes behind you        │
│                                     │
│ [Mark Next Watched]                 │
└─────────────────────────────────────┘
```
- ● = 100% watched, ◐ = partial (1-99%), ○ = not started (0%)
- Default to latest season with any active progress
- "Mark Next Watched" advances the user's next unwatched episode to 100%

### Movie Party Progress View
```
┌─────────────────────────────────────┐
│ Dune 2 Watch Party                  │
├─────────────────────────────────────┤
│                                     │
│ You        ████████████░░░░  75%    │
│ Alex       ██████████████░░  90%    │
│ Sam        ████████░░░░░░░░  50%    │
│                                     │
│ Sam is furthest behind              │
│                                     │
│ [Update Progress]                   │
└─────────────────────────────────────┘
```
- "Update Progress" opens a slider to set 0-100%

### Party List Item (Social/Friends tab)
```
┌─────────────────────────────────────┐
│ Severance                           │
│ 3 friends watching · You're on Ep 5 │
│ Alex just watched Episode 7!        │
└─────────────────────────────────────┘
```

### Create Party Flow (from watchlist item page)
1. User taps "Create Watch Party" on a TV show or movie watchlist item
2. Bottom sheet: enter party name (pre-filled with show/movie title)
3. Friend picker: select up to 9 friends to invite (10 total including creator)
4. Confirm → creates party, sends invitations, navigates to party progress screen

### Party Invite (recipient)
- Notification card in notification center (same pattern as friend requests / co-owner invites)
- Accept → status 'active', appears in Social/Friends tab party list
- Decline → row deleted (can be re-invited later since a new row is created)

### Leave / Delete Party
- Members: "Leave Party" in overflow menu → status set to 'left'
- Creator: "Delete Party" → cascade deletes all members and progress
- Rejoin: creator can re-invite a member who left (status flipped 'left' → 'pending')

---

## Frontend Architecture

### New Files
| File | Purpose |
|------|---------|
| `lib/shared/models/watch_party.dart` | `WatchParty` + `WatchPartyMember` + `WatchPartyProgress` models |
| `lib/shared/repositories/watch_party_repository.dart` | CRUD parties, invite/accept/leave/rejoin, Realtime subscription on `watch_party_progress` |
| `lib/features/social/controllers/watch_party_controller.dart` | GetX state + Realtime channel management + season tab state |
| `lib/features/social/screens/watch_party_screen.dart` | Party progress view — TV: season tabs + episode grid; Movies: progress bars |
| `lib/features/social/screens/create_party_screen.dart` | Create party from watchlist item page + friend picker |
| `lib/features/social/widgets/party_progress_bar.dart` | Per-member episode progress row (TV) / percentage bar (movie) |
| `lib/features/social/widgets/party_list_section.dart` | Active + pending parties section for Social/Friends tab |

### Modified Files
| File | Changes |
|------|---------|
| Watchlist item page | Add "Create Watch Party" button (TV + movies) |
| Social/Friends tab | Add "Watch Parties" section with `party_list_section.dart` |
| Notification center | Render party invite notification cards (accept/decline) |

---

## Dependencies
- **Friend system** (`friend_system.md`) — `are_friends()` + `is_blocked()` for invite gating
- **Push notification infrastructure** — `send-notification` edge function
- **Content must be in user's watchlist** — `watch_progress` only exists for watchlist items

---

## Edge Cases
- User not watching the show yet → show "Not Started" (0% for movies, no episodes for TV)
- User finishes show → show "Completed" badge on their row
- Show has multiple seasons → season tabs, default to latest season with active progress
- User removes show from watchlist → prompt to leave party (progress data remains in `watch_party_progress` but stops syncing)
- Party creator deletes party → cascade deletes all members and progress, push notification to members
- Member re-invited after leaving → status flipped from 'left' to 'pending', same row reused
- 10-member cap reached → invite button disabled with "Party is full (10/10 members)" message
- Movie progress updated → slider input (0-100%)
- User is in multiple parties for the same show → trigger syncs to all matching parties
- Realtime disconnects → re-fetch full state on reconnect via `watch_party_progress` query

---

## QA Checklist
- [ ] Can create watch party for a TV show from watchlist item page
- [ ] Can create watch party for a movie from watchlist item page
- [ ] Can invite up to 9 friends (10 total including creator)
- [ ] 11th member invite is rejected with explanation
- [ ] Friends receive party invitation notification
- [ ] Accept/decline invitation works
- [ ] Party appears in Social/Friends tab after accepting
- [ ] TV: season tabs display correctly with episode count per season
- [ ] TV: per-member episode grid shows ●/◐/○ states correctly
- [ ] Movies: per-member progress bar shows 0-100% correctly
- [ ] Partial progress (e.g., 50% through an episode) displays correctly
- [ ] Progress updates appear in real-time via Realtime subscription
- [ ] Push notification fires on episode completion (not on partial progress)
- [ ] Movie push notification fires only at 25/50/75/100% thresholds
- [ ] "Catch up" indicator shows for members who are behind
- [ ] Can leave party (status → 'left')
- [ ] Creator can re-invite a member who left
- [ ] Re-invited member can accept and rejoin
- [ ] Creator can delete party
- [ ] All members receive notification when party is deleted
- [ ] Removing show from watchlist prompts to leave party
- [ ] Realtime reconnects gracefully after network interruption
