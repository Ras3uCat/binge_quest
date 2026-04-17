# Feature: Watch Party → View All Parties

## Status
DONE

## Priority
Low — discoverability improvement

## Overview
From inside a watch party screen, users can tap the group icon in the AppBar to navigate to the Friends & Parties screen, which shows all their active and pending parties.

## What Was Built
- Added `Icons.group_outlined` IconButton to `WatchPartyScreen` AppBar `actions`, before the existing info button.
- Tapping navigates via `Get.to(() => const FriendListScreen())` — standard push, back arrow returns to the party screen.

## Note on Original Spec
The original spec assumed a dedicated "Watch Parties tab" in the bottom nav. No such tab exists — the app has 4 tabs (Dashboard, Watchlist, Search, Profile). Watch parties are surfaced via the "Parties & Friends" sub-tab inside `FriendListScreen`. The `Get.to()` push approach is correct for this nav pattern.
