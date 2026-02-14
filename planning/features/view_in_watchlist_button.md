# Feature: View in Watchlist Button

## Status
Completed

## Overview
Replace the disabled "Already in Watchlist" button with a functional "View in Watchlist" button that navigates directly to the item's detail page.

## Acceptance Criteria
- [x] Button text changes to "View in Watchlist" if item is already owned
- [x] Tapping navigates to `ItemDetailScreen`
- [x] Sheet context awareness (hide button if already on detail screen)

## Backend Changes
- None

## Frontend Changes
- UI: Update `ContentDetailSheet` logic
- UI: Pass `showWatchlistAction: false` from `ItemDetailScreen`

## QA Checklist
- [ ] Verify button navigates correctly
- [ ] Verify button is hidden when viewing from within a watchlist
