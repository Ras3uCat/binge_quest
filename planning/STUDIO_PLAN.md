# Watch Party Sync

**Status:** COMPLETE — All tracks done (2026-02-22)
**Mode:** STUDIO
**Priority:** High
**Started:** 2026-02-22
**Specs:** `planning/features/watch_party_sync.md`

---

## Problem Description

Users want to see where friends are in a shared show or movie in real-time. Each person adds the content to their own watchlist and marks progress normally. The watch party view collects every active member's progress and displays it together. The screen is read-only — a "View in Watchlist" button deep-links to the user's own watchlist item to mark progress.

---

## Architecture

Three tables: `watch_parties`, `watch_party_members`, `watch_party_progress`.

`watch_party_progress` is a denormalized Realtime relay — written exclusively by a SECURITY DEFINER trigger on `watch_progress`. The trigger computes `progress_percent` from `minutes_watched / runtime_minutes` using data from `content_cache` and `content_cache_episodes`. No new columns on `watch_progress`. No changes to existing write paths.

**Progress percent computation (in trigger):**
```sql
progress_percent = CASE
  WHEN NEW.watched = true THEN 100
  WHEN NEW.minutes_watched > 0 THEN
    LEAST(100, ROUND(NEW.minutes_watched * 100.0 / NULLIF(runtime, 0)))
  ELSE 0
END
```
- **TV:** `runtime` = `content_cache_episodes.runtime_minutes` via `NEW.episode_cache_id`
- **Movie:** `runtime` = `content_cache.total_runtime_minutes` via `watchlist_items → content_cache`

**Realtime:** client subscribes to `watch_party_progress` filtered by `party_id`. On screen open, fetch full snapshot first then subscribe. On reconnect, re-fetch snapshot before resubscribing.

---

## Track A: Backend (Migration 036 — single migration)

### A1 — Tables

**`watch_parties`**
- `id UUID PK DEFAULT gen_random_uuid()`
- `name TEXT NOT NULL`
- `tmdb_id INTEGER NOT NULL`
- `media_type TEXT NOT NULL CHECK IN ('tv', 'movie')`
- `created_by UUID NOT NULL FK auth.users ON DELETE CASCADE`
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`
- Indexes: `idx_watch_parties_created_by`, `idx_watch_parties_tmdb(tmdb_id, media_type)`

**`watch_party_members`**
- `id UUID PK DEFAULT gen_random_uuid()`
- `party_id UUID NOT NULL FK watch_parties ON DELETE CASCADE`
- `user_id UUID NOT NULL FK auth.users ON DELETE CASCADE`
- `status TEXT NOT NULL DEFAULT 'pending' CHECK IN ('pending', 'active', 'left')`
- `joined_at TIMESTAMPTZ NULL`
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`
- `UNIQUE(party_id, user_id)` — rejoin reuses the row
- Indexes: `idx_watch_party_members_user_id`, `idx_watch_party_members_party_status(party_id, status)`

**`watch_party_progress`** (denormalized Realtime relay, trigger-synced)
- `id UUID PK DEFAULT gen_random_uuid()`
- `party_id UUID NOT NULL FK watch_parties ON DELETE CASCADE`
- `user_id UUID NOT NULL FK auth.users ON DELETE CASCADE`
- `season_number INTEGER NOT NULL DEFAULT 0` — 0 for movies
- `episode_number INTEGER NOT NULL DEFAULT 0` — 0 for movies
- `progress_percent INTEGER NOT NULL DEFAULT 0 CHECK BETWEEN 0 AND 100`
- `watched BOOLEAN NOT NULL DEFAULT false`
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`
- `UNIQUE(party_id, user_id, season_number, episode_number)`
- Indexes: `idx_watch_party_progress_party_id` (Realtime filter), `idx_watch_party_progress_user_party(user_id, party_id)`

### A2 — Member Cap Trigger

`enforce_party_member_cap()` — BEFORE INSERT OR UPDATE on `watch_party_members`:
- Fires when `NEW.status = 'active'`
- Count active members for `NEW.party_id` WHERE `status = 'active'`
- If count >= 10, RAISE EXCEPTION 'Party is full (10/10 members)'

### A3 — Progress Sync Trigger

`sync_watch_party_progress()` — SECURITY DEFINER AFTER INSERT OR UPDATE on `watch_progress`:

```sql
DECLARE
  v_tmdb_id INTEGER;
  v_media_type TEXT;
  v_user_id UUID;
  v_runtime INTEGER;
  v_season INTEGER;
  v_episode INTEGER;
  v_percent INTEGER;
  v_party RECORD;
BEGIN
  -- Resolve content identity and user from watchlist chain
  SELECT wi.tmdb_id, wi.media_type, w.user_id
  INTO v_tmdb_id, v_media_type, v_user_id
  FROM watchlist_items wi
  JOIN watchlists w ON w.id = wi.watchlist_id
  WHERE wi.id = NEW.watchlist_item_id;

  -- Resolve season/episode and runtime
  IF NEW.episode_cache_id IS NOT NULL THEN
    -- TV episode
    SELECT cce.season_number, cce.episode_number, cce.runtime_minutes
    INTO v_season, v_episode, v_runtime
    FROM content_cache_episodes cce
    WHERE cce.id = NEW.episode_cache_id;
  ELSE
    -- Movie
    v_season := 0;
    v_episode := 0;
    SELECT cc.total_runtime_minutes INTO v_runtime
    FROM content_cache cc
    WHERE cc.tmdb_id = v_tmdb_id AND cc.media_type = 'movie';
  END IF;

  -- Compute progress_percent
  IF NEW.watched = true THEN
    v_percent := 100;
  ELSIF NEW.minutes_watched > 0 THEN
    v_percent := LEAST(100, ROUND(NEW.minutes_watched * 100.0 / NULLIF(v_runtime, 0)));
  ELSE
    v_percent := 0;
  END IF;

  -- Upsert into watch_party_progress for each active party this user belongs to
  FOR v_party IN
    SELECT wp.id AS party_id
    FROM watch_parties wp
    JOIN watch_party_members wpm ON wpm.party_id = wp.id
    WHERE wp.tmdb_id = v_tmdb_id
      AND wp.media_type = v_media_type
      AND wpm.user_id = v_user_id
      AND wpm.status = 'active'
  LOOP
    INSERT INTO watch_party_progress
      (party_id, user_id, season_number, episode_number, progress_percent, watched, updated_at)
    VALUES
      (v_party.party_id, v_user_id, v_season, v_episode, v_percent, NEW.watched, now())
    ON CONFLICT (party_id, user_id, season_number, episode_number)
    DO UPDATE SET
      progress_percent = EXCLUDED.progress_percent,
      watched = EXCLUDED.watched,
      updated_at = now();
  END LOOP;

  RETURN NEW;
END;
```

### A4 — RLS Policies

**`watch_parties`**
| Op | Policy |
|----|--------|
| SELECT | `auth.uid() = created_by` OR EXISTS active member row for `auth.uid()` |
| INSERT | `auth.uid() = created_by` |
| UPDATE | `auth.uid() = created_by` |
| DELETE | `auth.uid() = created_by` |

**`watch_party_members`**
| Op | Policy |
|----|--------|
| SELECT | `auth.uid()` is a member (any status) OR is creator |
| INSERT | `auth.uid()` is creator; `are_friends(auth.uid(), user_id)` = true; `NOT is_blocked(auth.uid(), user_id)` |
| UPDATE | Invitee accepts (`pending → active`); member leaves (`→ left`); creator re-invites (`left → pending`) |
| DELETE | `auth.uid() = user_id` (decline own pending invite) — cascade handles party deletion cleanup |

**`watch_party_progress`**
| Op | Policy |
|----|--------|
| SELECT | `auth.uid()` is an active member of the party |
| INSERT | None — SECURITY DEFINER trigger only |
| UPDATE | None — SECURITY DEFINER trigger only |
| DELETE | None — cascade from party delete only |

### A5 — Realtime Publication

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE watch_party_progress;
```

---

## Track B: Frontend (New Files)

### B1 — Models (`lib/shared/models/watch_party.dart`)

- `WatchParty` — `id`, `name`, `tmdbId`, `mediaType`, `createdBy`, `createdAt`; `fromJson`
- `WatchPartyMember` — `id`, `partyId`, `userId`, `status` (enum: pending/active/left), `joinedAt`
- `WatchPartyMemberProgress` — `userId`, `displayName`, `avatarUrl`, `List<EpisodeProgress> episodes`
- `EpisodeProgress` — `seasonNumber`, `episodeNumber`, `progressPercent`, `watched`, `updatedAt`

### B2 — Repository (`lib/shared/repositories/watch_party_repository.dart`)

**Party CRUD:**
- `createParty(name, tmdbId, mediaType)` → `WatchParty`
- `inviteMember(partyId, userId)`
- `acceptInvite(partyId)` — UPDATE `pending → active`, set `joined_at = now()`
- `declineInvite(partyId)` — DELETE own member row
- `leaveParty(partyId)` — UPDATE `→ left`
- `reinviteMember(partyId, userId)` — INSERT new `pending` row
- `deleteParty(partyId)`
- `fetchUserParties()` → `List<WatchParty>`

**Progress:**
- `fetchProgress(partyId)` → `List<WatchPartyMemberProgress>` — queries `watch_party_progress` joined with `users` for display name and avatar
- `subscribeToProgress(partyId, callback)` — Supabase Realtime channel on `watch_party_progress` filtered by `party_id = partyId`
- `unsubscribeFromProgress(partyId)`

### B3 — Controller (`lib/features/social/controllers/watch_party_controller.dart`)

GetX (`Get.lazyPut(fenix: true)`):
- `RxList<WatchParty> activeParties`, `RxList<WatchParty> pendingParties`
- `RxMap<String, List<WatchPartyMemberProgress>> progressByParty` keyed by `partyId`
- `RxInt selectedSeason`
- `loadParties()` — populates `activeParties` + `pendingParties`
- `openParty(partyId)` — fetches full snapshot → subscribes to Realtime
- `closeParty(partyId)` — unsubscribes channel
- `_handleRealtimeUpdate(payload)` — merges row-level INSERT/UPDATE into `progressByParty`
- On reconnect: `openParty` re-fetches snapshot then resubscribes

### B4 — Create Party Sheet (`lib/features/social/screens/create_party_sheet.dart`)

Bottom sheet:
1. Party name input (pre-filled with show/movie title)
2. Friend picker — multi-select up to 9 friends (reads from `FriendController`)
3. Confirm → `createParty()` + `inviteMember()` for each → dismiss sheet, push `WatchPartyScreen`

### B5 — Watch Party Screen (`lib/features/social/screens/watch_party_screen.dart`)

**Read-only.** No progress writes on this screen.

**TV:**
- Season `TabBar` across all seasons present in any member's progress; default to latest with activity
- Per-season: one `PartyProgressRow` per member
- "X is N episodes behind" catch-up indicator
- **"View in Watchlist"** button → navigates to current user's watchlist item for this show

**Movie:**
- One `PartyProgressRow` (bar variant) per member
- "X is furthest behind" indicator
- **"View in Watchlist"** button → navigates to current user's watchlist item for this movie

**Shared:**
- Member with no rows in `watch_party_progress` → "Not Started" placeholder row
- Member with all episodes/movie `watched = true` → "Completed" badge
- Overflow menu: Leave Party (members) / Delete Party (creator)

### B6 — Party Progress Row (`lib/features/social/widgets/party_progress_row.dart`)

**TV variant:** avatar + display name + episode circles per episode in the selected season
- ● = `progress_percent = 100`
- ◐ = `progress_percent` 1–99
- ○ = `progress_percent = 0` or no row

**Movie variant:** avatar + display name + `LinearProgressIndicator(value: progressPercent / 100)` + percentage text label

### B7 — Party List Section (`lib/features/social/widgets/party_list_section.dart`)

For Social/Friends tab:
- **Pending Invites** sub-section: show name + inviter + Accept / Decline buttons
- **Active Parties** list: poster + show name + "{N} friends watching" + user's furthest episode / movie percent
- Tap row → `WatchPartyScreen`

---

## Track C: Integration (Modified Files)

### C1 — Watchlist Item Page

- Add "Create Watch Party" `OutlinedButton` for TV shows and movies
- Taps open `CreatePartySheet` with `tmdbId` and `mediaType` pre-populated
- **No write path changes needed** — trigger reads from existing `watch_progress` + `minutes_watched` + `watched`

### C2 — Social/Friends Tab

Add `PartyListSection` (B7) above existing friends list. Conditionally rendered when user has active or pending parties.

### C3 — Notification Center

New card type for party invite (`category = 'watch_party_invite'`):
- Body: "{username} invited you to a watch party for {show_name}"
- Accept / Decline action buttons → `WatchPartyController.acceptInvite` / `declineInvite`

### C4 — Push Notifications (client-side, `send-notification`)

| Event | Fired by | Recipients |
|-------|----------|------------|
| Invite sent | Creator device, after `inviteMember()` | Invitee |
| Invite accepted | Member device, after `acceptInvite()` | Creator |
| Episode/movie complete | Watcher device, after marking `watched = true` in watchlist | Other active party members |
| Party deleted | Creator device, after `deleteParty()` | All active members |

Partial progress changes (progress_percent 1–99) do NOT trigger push notifications.

---

## Files to Touch

**Backend — new:**
- `036_watch_party_sync.sql` — all tables, triggers, RLS, Realtime publication

**Frontend — new:**
- `lib/shared/models/watch_party.dart`
- `lib/shared/repositories/watch_party_repository.dart`
- `lib/features/social/controllers/watch_party_controller.dart`
- `lib/features/social/screens/watch_party_screen.dart`
- `lib/features/social/screens/create_party_sheet.dart`
- `lib/features/social/widgets/party_progress_row.dart`
- `lib/features/social/widgets/party_list_section.dart`

**Frontend — modified:**
- Watchlist item detail page: "Create Watch Party" button
- Social/Friends tab screen: `PartyListSection`
- Notification center: party invite card type

---

## Key Constraints

- **`watch_party_progress` is written only by the trigger** — no client writes, no RLS INSERT/UPDATE policies
- **`progress_percent` derived from `minutes_watched / runtime_minutes`** — no schema changes to `watch_progress`
- **`watched = true` always forces `progress_percent = 100`** in trigger regardless of minutes
- **Watch party screen is strictly read-only** — all progress updates go through "View in Watchlist"
- **Decline = DELETE row; Leave = status `→ left`** — different flows, different RLS actions
- **10-member cap enforced in DB trigger**, not client-side
- **Realtime reconnect:** re-fetch full snapshot before resubscribing
- **Push notifications client-side** — same pattern as friend requests / co-curator invites
- **`verify_jwt: false`** on any new edge function calls — use in-function `getUser(token)`

---

## Previous Plan

**Advanced Stats Dashboard v1.1** — Complete (2026-02-19)
**Advanced Stats Dashboard v1.0** — Complete (2026-02-19)
**Pre-Launch Hardening** — Complete (2026-02-19)
