# Feature: Viral Hits Recommendation Mode

## Status
Completed

## Overview
Replace "Backlog First" with "Viral Hits", which recommends content from the user's watchlist based on TMDB popularity scores.

## Acceptance Criteria
- [x] "Viral Hits" option in recommendation mode selector
- [x] Watchlist items sorted by `popularity_score` (descending)
- [x] Dashboard section title updates to "Viral Hits"

## Backend Changes
- None (uses `content_cache.popularity_score`)

## Frontend Changes
- Update `RecommendationMode` enum
- Update `WatchlistController` sorting logic
- Update `RecommendationModeSelector` UI

## QA Checklist
- [ ] Verify items are sorted correctly by popularity
- [ ] Verify mode persists across app restarts
