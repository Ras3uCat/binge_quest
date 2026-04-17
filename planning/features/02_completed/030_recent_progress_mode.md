# Feature: Recent Progress Recommendation Mode

## Status
Completed

## Overview
Add a "Recent" recommendation mode that highlights items the user has recently interacted with (e.g., updated progress). This helps users quickly resume what they were last watching.

## Acceptance Criteria
- [x] "Recent" option in recommendation mode selector (first chip)
- [x] Items sorted by the latest `watched_at` timestamp from `watch_progress`
- [x] Exclude items that have 0% progress (newly added but not started)
- [x] Dashboard section title updates to "Continue Watching" or "Recent Progress"

## Backend Changes
- Ensure `watch_progress` updates `watched_at` whenever `minutes_watched` or `watched` status changes.
- Query to fetch watchlist items joined with their latest `watch_progress` timestamp.

## Frontend Changes
- Update `RecommendationMode` enum to include `recent`.
- Update `WatchlistController` to handle the new sorting and filtering logic.
- Update `RecommendationModeSelector` to place "Recent" as the first option.
- Update `WatchlistRepository` to support fetching items ordered by recent progress.

## QA Checklist
- [ ] Verify "Recent" is the first chip in the selector.
- [ ] Verify newly added items with no progress do NOT appear in this mode.
- [ ] Verify items move to the front of the list immediately after updating progress.
- [ ] Verify mode persists across app restarts.
