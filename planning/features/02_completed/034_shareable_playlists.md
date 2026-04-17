# Feature: Shareable Playlists

## Status
COMPLETE

## Overview
Allow users to create named curated lists ("Top 10 Comedies", "Best Animations", "Top 5 Films of All Time", etc.) that appear on their profile and can be shared with friends. Unlike watchlists (personal progress tracking), playlists are for sharing recommendations. Friends can view a playlist and add all items to an existing or new watchlist in one tap.

## User Stories
- As a user, I want to create a playlist with any name I choose and add movies/TV shows to it
- As a user, I want my playlists to show on my profile
- As a user, I want to share a playlist link so friends can discover it
- As a friend, I want to view someone's playlist and add all items to my watchlist in one tap
- As a user, I want to edit, reorder, and delete my own playlists

## Acceptance Criteria
- [ ] Create playlist with name (required) and optional description
- [ ] Add movies and/or TV shows to a playlist (max 25 items)
- [ ] Reorder items via drag-and-drop (owner only)
- [ ] Toggle visibility: public (shareable) or private (only you)
- [ ] Playlists section visible on own profile; public playlists visible on other users' profiles
- [ ] Share button generates a `bingequest://playlist?id={id}` deep link via system share sheet
- [ ] Deep link opens `PlaylistDetailScreen` in-app
- [ ] Non-owner: "Add All to Watchlist" adds all items to a selected watchlist (existing or new)
- [ ] Non-owner: individual `+` button to add a single item to a watchlist
- [ ] Edit/delete own playlists

## Playlist vs Watchlist

| Feature | Watchlist | Playlist |
|---------|-----------|----------|
| Purpose | Personal tracking | Sharing / recommendations |
| Progress tracking | Yes | No |
| Public shareable | No | Yes (if public) |
| Co-owners | Yes | No (single creator) |
| Item limit | Unlimited | 25 max |

## Data Model

### `playlists`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK → auth.users, ON DELETE CASCADE |
| name | TEXT | Required |
| description | TEXT | Optional |
| is_public | BOOLEAN | Default true |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | Auto-updated via trigger |

### `playlist_items`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| playlist_id | UUID | FK → playlists, ON DELETE CASCADE |
| tmdb_id | INT | |
| media_type | TEXT | 'movie' or 'tv' |
| title | TEXT | Cached at add time |
| poster_path | TEXT | Cached at add time |
| position | INT | Sort order |
| note | TEXT | Optional creator note |
| added_at | TIMESTAMPTZ | |
| | | UNIQUE(playlist_id, tmdb_id, media_type) |

> **Omitted from original spec:** `slug` (use UUID in URL instead), `cover_image` (derived from first item's poster), `view_count` (unauthenticated increment complexity, skip MVP), cached `item_count` (computed via COUNT).

## Migration: `063_playlists.sql`

```sql
CREATE TABLE public.playlists ( ... );
CREATE TABLE public.playlist_items ( ... );

-- RLS
-- playlists: owner can do all; authenticated or anonymous can SELECT public
CREATE POLICY "owner_all"   ON public.playlists FOR ALL    USING (auth.uid() = user_id);
CREATE POLICY "public_read" ON public.playlists FOR SELECT USING (is_public = true);

-- playlist_items: mirrors playlist visibility
CREATE POLICY "owner_all"   ON public.playlist_items FOR ALL    USING (
  EXISTS (SELECT 1 FROM public.playlists WHERE id = playlist_id AND user_id = auth.uid())
);
CREATE POLICY "public_read" ON public.playlist_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.playlists WHERE id = playlist_id AND is_public = true)
);

-- updated_at trigger on playlists
```

## Sharing

### Deep Link Format
```
bingequest://playlist?id={uuid}
```
Handled in `main.dart` (same `AppLinks` stream as profile sharing from feature 055).

### Share Text
```
Check out my playlist "{name}" on BingeQuest!
bingequest://playlist?id={id}

iOS: https://apps.apple.com/app/id6759207637
Android: https://play.google.com/store/apps/details?id=com.ras3ucat.binge_quest
```

> No web/SEO page — App Store/Play Store links serve as fallback for recipients without the app.

## Frontend Architecture

### New feature directory: `lib/features/playlists/`

| File | Purpose |
|------|---------|
| `models/playlist.dart` | `Playlist` + `PlaylistItem` models with `fromJson` |
| `repositories/playlist_repository.dart` | CRUD: `getUserPlaylists`, `getPlaylistById`, `createPlaylist`, `updatePlaylist`, `deletePlaylist`, `addItem`, `removeItem`, `reorderItems` |
| `controllers/playlist_controller.dart` | Own playlists list + create/delete. Used by profile. |
| `controllers/playlist_detail_controller.dart` | Single playlist load, `isOwner` check, `addItem`, `removeItem`, `reorder`, `addAllToWatchlists` |
| `screens/playlist_detail_screen.dart` | Full-screen view — owner mode (reorder, delete, add item FAB, share/edit) and non-owner mode (Add All bottom bar, per-item + buttons) |
| `widgets/create_edit_playlist_sheet.dart` | Bottom sheet: name field, description field, is_public toggle |
| `widgets/add_to_playlist_sheet.dart` | Bottom sheet: search field (reuses `ContentSearchController`) + results list |
| `widgets/playlist_card.dart` | Compact card: first item poster, name, item count badge |
| `widgets/playlists_section.dart` | Profile section: own profile shows "New" button + cards; other profile shows public cards only; hidden if empty and not own profile |

### Modified Files

| File | Change |
|------|--------|
| `execution/backend/supabase/migrations/063_playlists.sql` | New migration |
| `lib/shared/repositories/watchlist_repository.dart` | Add `bulkAddFromPlaylist({items, watchlistIds})` — batch upsert, returns added count |
| `lib/features/profile/screens/profile_screen.dart` | Add `PlaylistsSection(userId: ..., isOwnProfile: true)` |
| `lib/features/profile/screens/user_profile_screen.dart` | Add `PlaylistsSection(userId: resolvedUserId, isOwnProfile: false)` |
| `lib/main.dart` | Add `bingequest://playlist?id=` route → `PlaylistDetailScreen(playlistId: id)` |

### "Add All to Watchlist" Flow
1. Non-owner taps "Add All to Watchlist" on `PlaylistDetailScreen`
2. `WatchlistSelectorSheet.show(...)` opens (already built — reused from content detail flow)
3. `onConfirm` callback calls `WatchlistRepository.bulkAddFromPlaylist(items: ..., watchlistIds: ...)`
4. Batch upsert with `ignoreDuplicates: true` — no N TMDB API calls needed
5. Snackbar confirms: "X items added to [watchlist name]"

### Item Search Flow (owner adding items)
1. Owner taps FAB `+` on `PlaylistDetailScreen`
2. `AddToPlaylistSheet` opens with search field
3. Reuses `ContentSearchController.searchContent(query)`
4. Tap result → `PlaylistDetailController.addItem(result)` → inserts into `playlist_items`
5. Item appears in list immediately (optimistic update)

## QA Checklist
- [ ] Create playlist with name + description; appears on own profile
- [ ] Add 25 items; 26th is blocked with a message
- [ ] Reorder items as owner; order persists after reload
- [ ] Toggle private → playlist hidden from other users' profile view and deep link returns "not found"
- [ ] Share button opens system share sheet with correct `bingequest://` link
- [ ] Tapping shared link opens `PlaylistDetailScreen`
- [ ] Non-owner: "Add All to Watchlist" adds all items to selected watchlist
- [ ] Non-owner: individual `+` adds one item via `WatchlistSelectorSheet`
- [ ] Items already in watchlist are not duplicated (upsert behaviour)
- [ ] Edit playlist name/description; changes reflect immediately
- [ ] Delete playlist; removed from profile
