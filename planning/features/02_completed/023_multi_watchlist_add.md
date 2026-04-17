# Feature: Add to Multiple Watchlists

## Status
Completed

## Overview
Allow users to add a movie or TV show to multiple watchlists simultaneously from the search results.

## Acceptance Criteria
- [ ] Bottom sheet shows all user watchlists with checkboxes
- [ ] Batch insert logic in repository
- [ ] Success notification shows count of watchlists added to

## Backend Changes
- None (uses existing `watchlist_items` table)

## Frontend Changes
- `WatchlistRepository.addItemsToWatchlists(tmdbId, mediaType, watchlistIds)`
- UI: Update `ContentDetailSheet` to show multi-select list

## QA Checklist
- [ ] Verify item is added to all selected watchlists
- [ ] Verify item is not added twice to the same watchlist
- [ ] Verify "Add" button updates to "View" if already in at least one watchlist
