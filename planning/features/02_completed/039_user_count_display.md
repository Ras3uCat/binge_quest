# Feature: User Count Display

## Status
Completed

## Overview
Show how many other BingeQuest users have a specific item in their watchlist.

## Acceptance Criteria
- [ ] "X users watching" text on item detail sheet/screen
- [ ] Formatting: exact count for <1K, "K" notation for 1K+

## Backend Changes
- Query to count unique users for a given `tmdb_id` + `media_type`

## Frontend Changes
- `WatchlistRepository.getUserCount(tmdbId, mediaType)`
- UI: Update `ContentDetailSheet` and `ItemDetailScreen`

## QA Checklist
- [ ] Verify count is accurate
- [ ] Verify formatting (e.g., 1,234 -> 1.2K)
