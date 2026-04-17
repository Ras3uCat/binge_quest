# Feature: BingeQuest Top 10

## Status
Completed

## Overview
A dashboard section showing the most popular items across the entire BingeQuest user base, with sorting options for "Most Watched" and "Top Rated".

## Acceptance Criteria
- [x] "BingeQuest Top 10" section at bottom of Dashboard
- [x] Toggle to sort by "Most Watched" or "Top Rated"
- [x] Top 10 items by user count (Most Watched mode)
- [x] Top 10 items by BingeQuest average rating (Top Rated mode)
- [x] Each item shows: poster, title, rank number badge
- [x] "X users watching" badge in Most Watched mode
- [x] TV screen rating icons + numeric rating in Top Rated mode
- [x] Tapping item opens ContentDetailSheet
- [x] Graceful empty state if no data

## Backend Changes
- `get_top_10_by_users()` RPC - returns top content by unique user count
- `get_top_10_by_rating()` RPC - returns top content by average rating (min 2 reviews)

## Frontend Changes
- `TopContent` model
- `TopContentRepository` with methods for both sort modes
- `BingeQuestTop10Section` widget with sort toggle
- `Top10ItemCard` widget for horizontal scroll items

## Decisions
| Question | Decision |
|----------|----------|
| Placement | Bottom of Dashboard, after RecommendationsSection |
| Default sort | Most Watched |
| Minimum reviews for Top Rated | 2 reviews to qualify |
| Layout | Horizontal scroll list |
| Rank display | Badge overlay on poster (#1, #2, etc.) |

## QA Checklist
- [ ] Verify Most Watched shows items sorted by user count
- [ ] Verify Top Rated shows items sorted by average rating
- [ ] Verify toggle switches between modes correctly
- [ ] Verify tapping an item opens the correct detail sheet
- [ ] Verify empty state displays when no data
- [ ] Verify Top Rated only shows items with 2+ reviews
