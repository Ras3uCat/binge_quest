# Feature: Search Suggestions

## Status
Completed

## Overview
Show personalized content suggestions on the search screen before the user starts typing, based on their watchlist preferences.

## Acceptance Criteria
- [x] "Recommended for You" section on Search screen
- [x] Suggestions based on user's top genres
- [x] Exclude items already in the user's watchlist

## Backend Changes
- None (uses TMDB recommendations API)

## Frontend Changes
- `SearchController.getSuggestions()`
- `SearchSuggestions` widget
- Logic to show/hide suggestions based on search query presence

## QA Checklist
- [ ] Verify suggestions are relevant to user's history
- [ ] Verify no duplicates from watchlist appear
- [ ] Verify suggestions disappear when typing starts
