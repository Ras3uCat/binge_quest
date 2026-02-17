# Current Task: Search + Provider Filter Integration

**Status**: TODO
**Mode**: FLOW
**Priority**: Medium
**Started**: 2026-02-17
**Specs**: N/A (bugfix — search ignores text query when provider filter is active)

---

## Overview

When a user searches by text AND selects a streaming provider filter, the search results should be filtered to only show items available on that provider. Currently, selecting a provider switches entirely to "Discover" mode, discarding the text query.

**Approach:** Reactive client-side filtering via the `filteredResults` getter. No API changes needed (TMDB search doesn't support provider filtering).

---

## Tasks

### Frontend Tasks

| # | Task | Status | Owner |
|---|------|--------|-------|
| 1 | Update `toggleProvider` — don't call `_discoverByProviders` when `_searchQuery` is active; just toggle the provider and let `filteredResults` handle it | TODO | Frontend |
| 2 | Update `filteredResults` getter — when `_selectedProviders` is not empty AND `_searchQuery` is not empty, filter results to items where `_cachedStreamingProviders[id]` contains any selected provider ID | TODO | Frontend |
| 3 | Verify: empty search + provider selected still uses Discover mode (existing behavior preserved) | TODO | QA |
| 4 | Verify: "Batman" + Netflix filter shows only Batman titles on Netflix | TODO | QA |
| 5 | Verify: toggling providers on/off reactively filters without re-fetching | TODO | QA |
| 6 | Verify: clearing search text with providers active reverts to Discover mode | TODO | QA |

**Single file modified:** `lib/features/search/controllers/search_controller.dart`

---

## Previous Tasks

- Friends Watching Content Indicator - **Complete**
- Mood Guide - **Complete**
- Social Features Suite (Friend System, Watchlist Co-Curators) - **In Progress** (Watch Party + Shareable Playlists remaining)
- Follow Talent (Actors & Directors) - **Complete**
- Streaming Availability Alerts - **Complete**
- Push Notifications Infrastructure - **Complete**
- Move Item Between Watchlists - **Complete**
- Release & Air Dates Display - **Complete**
- Partial Episode Progress Display Fix - **Complete**
- External Sharing - **Complete**
- Dashboard Performance Optimization - **Complete**
- Profile Stats Performance & Minutes Watched Accuracy - **Complete**
- Queue Health Watchlist Switch Bug - **Complete**
- Badge Placement Consistency - **Complete**
