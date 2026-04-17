# Feature: App Navigation & UX Reorganization

## Status
COMPLETED — 2026-04-14

## Chosen Approach: Option A — 5-Tab Bottom Nav

| Index | Tab | Screen | Change |
|-------|-----|--------|--------|
| 0 | Home | DashboardScreen (body only) | Kept |
| 1 | Library | LibraryScreen (NEW) | Watchlists + Playlists tabs |
| 2 | Search | SearchScreen | Kept |
| 3 | Social | FriendListScreen | **New tab** — surfaces Watch Parties |
| 4 | Profile | ProfileScreen | Added Settings gear to AppBar |

## What Changed

### `dashboard_screen.dart`
- Converted to StatefulWidget with IndexedStack navigation
- 5-tab NavigationBar with filled/outlined icon pairs
- Social tab badge driven by `FriendController.to.pendingReceived.length`
- Home body extracted to `_HomeTab` + `_HomeHeader` private widgets

### `library_screen.dart` (NEW)
- Thin wrapper with `DefaultTabController` (2 tabs: Watchlists / Playlists)
- Watchlists tab: `WatchlistScreen(showBackButton: false)`
- Playlists tab: `PlaylistsSection` via `_PlaylistsTab`

### `watchlist_screen.dart`
- Added `showBackButton` parameter (default `true`)
- Hides back button when embedded in LibraryScreen

### `friend_list_screen.dart`
- Removed back button from header (now a top-level nav destination)

### `profile_screen.dart`
- Added Settings gear `IconButton` to AppBar → `SettingsScreen`

## Acceptance Criteria
- [x] Watch Parties discoverable within 2 taps (Social tab → tab 0)
- [x] Playlists discoverable within 2 taps (Library tab → Playlists tab)
- [x] Settings accessible within 2 taps (Profile tab → gear icon)
- [x] All existing features remain accessible
- [x] Material 3 NavigationBar pattern with icon+label on all tabs
- [x] Badge on Social tab for pending friend requests
