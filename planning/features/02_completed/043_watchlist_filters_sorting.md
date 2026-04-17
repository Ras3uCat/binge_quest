# Feature: Watchlist Filters & Sorting

## Status
Completed

## Overview
Add comprehensive filtering (streaming service, genre, status) and sorting (popularity, remaining time) to the watchlist screen.

## Acceptance Criteria
- [ ] Filter by Streaming Service (multi-select)
- [ ] Filter by Genre (multi-select)
- [ ] Filter by Status (Not Started, In Progress, Completed)
- [ ] Sort by Popularity, Alphabetical, and Minutes Remaining

## Backend Changes
- None (uses `content_cache` joins)

## Frontend Changes
- `WatchlistFilterSheet` widget
- `WatchlistController` logic for client-side filtering and sorting
- UI: Filter/Sort icons and badges in App Bar

## QA Checklist
- [ ] Verify filters combine correctly (AND logic)
- [ ] Verify sort order is accurate
- [ ] Verify "Clear Filters" resets the view
