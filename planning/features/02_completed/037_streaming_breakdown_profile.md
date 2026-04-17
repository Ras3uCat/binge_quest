# Feature: Streaming Breakdown on Profile

## Status
Completed

## Overview
Show a visual breakdown of the user's watchlist by streaming service on their profile page.

## Acceptance Criteria
- [ ] List or chart showing item counts per service (Netflix, Hulu, etc.)
- [ ] Data aggregated from `watchlist_items` joined with `content_cache`

## Backend Changes
- SQL query to aggregate streaming providers for a user's items

## Frontend Changes
- `ProfileController.getStreamingBreakdown()`
- `StreamingBreakdown` widget (list or bar chart)

## QA Checklist
- [ ] Verify counts match the actual items in the watchlist
- [ ] Verify items with multiple providers are counted correctly
