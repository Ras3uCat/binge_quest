# Current Task: Watch Party Sync

**Status**: COMPLETE
**Mode**: STUDIO
**Priority**: High
**Started**: 2026-02-22
**Specs**: `STUDIO_PLAN.md`, `planning/features/watch_party_sync.md`

---

## Overview

Each user adds content to their own watchlist and marks progress normally. The watch party view collects every active member's progress in real-time and displays it together. The screen is read-only — "View in Watchlist" deep-links to the user's own watchlist item to update progress. Progress percent is derived by the DB trigger from `minutes_watched / runtime_minutes` using `content_cache` and `content_cache_episodes` — no new columns on `watch_progress`, no write path changes.

---

## Task Board

### Track A — Backend (Migration 036)

| # | Task | Status | Owner |
|---|------|--------|-------|
| A1 | Create `watch_parties` table with constraints and indexes | **DONE** | Backend |
| A2 | Create `watch_party_members` table with UNIQUE constraint, indexes, and member cap trigger (`enforce_party_member_cap`) | **DONE** | Backend |
| A3 | Create `watch_party_progress` table (denormalized Realtime relay) with UNIQUE constraint and indexes | **DONE** | Backend |
| A4 | Create `sync_watch_party_progress()` SECURITY DEFINER trigger on `watch_progress` — computes `progress_percent` from `minutes_watched / runtime_minutes` (TV: `content_cache_episodes.runtime_minutes` via `episode_cache_id`; Movie: `content_cache.total_runtime_minutes`) | **DONE** | Backend |
| A5 | RLS on all 3 tables (see STUDIO_PLAN.md — note: decline = DELETE member row, different from leave = status flip) | **DONE** | Backend |
| A6 | `ALTER PUBLICATION supabase_realtime ADD TABLE watch_party_progress` | **DONE** | Backend |

### Track B — Frontend (New Files)

| # | Task | Status | Owner |
|---|------|--------|-------|
| B1 | `lib/shared/models/watch_party.dart` — `WatchParty`, `WatchPartyMember`, `WatchPartyMemberProgress`, `EpisodeProgress` models | **DONE** | Flutter |
| B2 | `lib/shared/repositories/watch_party_repository.dart` — CRUD, invite/accept/decline(DELETE)/leave/delete, `fetchProgress`, `subscribeToProgress`, `unsubscribeFromProgress` | **DONE** | Flutter |
| B3 | `lib/features/social/controllers/watch_party_controller.dart` — GetX state, `openParty` (snapshot + subscribe), `closeParty` (unsubscribe), Realtime merge handler, season tab state | **DONE** | Flutter |
| B4 | `lib/features/social/screens/create_party_sheet.dart` — Bottom sheet: party name + friend picker + confirm | **DONE** | Flutter |
| B5 | `lib/features/social/screens/watch_party_screen.dart` — Read-only: TV season tabs + episode grid; Movie progress bars; "View in Watchlist" button | **DONE** | Flutter |
| B6 | `lib/features/social/widgets/party_progress_row.dart` — TV: ●/◐/○ episode circles; Movie: LinearProgressIndicator | **DONE** | Flutter |
| B7 | `lib/features/social/widgets/party_list_section.dart` — Pending invites (Accept/Decline) + active parties list for Social tab | **DONE** | Flutter |

### Track C — Integration (Modified Files)

| # | Task | Status | Owner |
|---|------|--------|-------|
| C1 | Watchlist item page: add "Create Watch Party" button — opens `CreatePartySheet` with `tmdbId` + `mediaType` pre-populated | **DONE** | Flutter |
| C2 | Social/Friends tab: add `PartyListSection` widget | **DONE** | Flutter |
| C3 | Notification center: party invite card with Accept/Decline actions | **DONE** | Flutter |
| C4 | Push notifications: client-side `send-notification` calls for invite sent, accepted, episode complete, party deleted | **DONE** | Flutter |

---

## Execution Order

```
A1 → A2, A3 (members + progress depend on watch_parties)
A4, A5, A6 — after A1–A3

B1 → B2 → B3 → B4, B5, B6, B7 (sequential dependency)

C1, C2, C3, C4 — after B3 controller available
```

---

## Key Decisions

- **`watch_party_progress` is the Realtime relay** — written exclusively by trigger, never by client
- **`progress_percent` computed in trigger** from `minutes_watched / runtime_minutes` — no `watch_progress` schema change, no write path changes
- **`watched = true` forces 100%** in trigger regardless of `minutes_watched`
- **Watch party screen is read-only** — "View in Watchlist" is the only path to update progress
- **Realtime:** subscribe to `watch_party_progress` filtered by `party_id`; re-fetch full snapshot on reconnect
- **Decline = DELETE row** (re-invite = new row); **Leave = status `→ left`** (rejoin = reuse row)
- **Push notifications client-side** — same pattern as friend requests

---

## Previous Tasks

- Advanced Stats Dashboard v1.1 Bug Fixes & Backfill Integrity — **Complete**
- Advanced Stats Dashboard v1.0 — **Complete**
- Pre-Launch Hardening (Tracks A, B, C) — **Complete**
- Standardize Dialog Boxes (EConfirmDialog) — **Complete**
- Search + Provider Filter Integration — **Complete**
- Friends Watching Content Indicator — **Complete**
- Mood Guide — **Complete**
- Watch Party Sync — **Complete**
- Social Features Suite (Friend System, Watchlist Co-Curators) — **In Progress** (Shareable Playlists remaining)
- Follow Talent (Actors & Directors) — **Complete**
- Streaming Availability Alerts — **Complete**
- Push Notifications Infrastructure — **Complete**
- Move Item Between Watchlists — **Complete**
- Release & Air Dates Display — **Complete**
- Partial Episode Progress Display Fix — **Complete**
- External Sharing — **Complete**
- Dashboard Performance Optimization — **Complete**
- Profile Stats Performance & Minutes Watched Accuracy — **Complete**
- Queue Health Watchlist Switch Bug — **Complete**
- Badge Placement Consistency — **Complete**
