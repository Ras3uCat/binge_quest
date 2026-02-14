# Feature: Release & Air Dates Display

## Overview
Display release dates for movies and air dates for individual TV episodes to help users understand content availability and make informed watching decisions.

## Problem Statement
Users currently cannot see:
- When a movie was released
- When individual episodes aired
- Whether an episode has aired yet (for ongoing shows)

This information helps users:
- Avoid spoilers by watching in release order
- Understand why certain episodes show "0m" (not yet aired)
- Track new episode releases for ongoing shows

## Requirements

### Movies
- Display release date on movie detail screen
- Format: "Released: Jan 15, 2024" or similar
- Show "Coming Soon" or "Unreleased" for future dates

### TV Episodes
- Display air date for each episode in the episode list
- Format: "Aired: Jan 15, 2024" or "S01E05 · Jan 15, 2024"
- Show "Airs: Feb 20, 2024" for future episodes
- Show "TBA" if air date is unknown

## Data Sources

### TMDB API
- Movies: `release_date` field (already fetched)
- Episodes: `air_date` field per episode

### Database Schema

**content_cache** (existing):
- `release_date` - already exists for movies

**content_cache_episodes** (needs update):
- Add `air_date DATE` column

## Implementation Plan

### Phase 1: Backend
1. Add `air_date` column to `content_cache_episodes`
2. Update episode cache sync to fetch/store air dates from TMDB
3. Include `air_date` in episode queries and RPC responses

### Phase 2: Frontend Models
1. Update `ContentCacheEpisode` model to include `airDate`
2. Update `WatchProgress` model to expose episode air date
3. Add date formatting helpers

### Phase 3: UI Updates
1. **Movie Detail Screen**: Show release date in info section
2. **Episode List**: Show air date next to each episode
3. **Episode Row Widget**: Visual indicator for unaired episodes (grayed out, "Coming Soon" badge)

## UI Mockups

### Movie Detail
```
[Poster]  The Matrix
          Action, Sci-Fi
          Released: Mar 31, 1999
          2h 16m · 8.7/10
```

### Episode List
```
Season 1
┌─────────────────────────────────┐
│ S01E01 · Pilot                  │
│ Aired: Sep 20, 2023 · 45m    ✓  │
├─────────────────────────────────┤
│ S01E02 · The Beginning          │
│ Aired: Sep 27, 2023 · 42m    ✓  │
├─────────────────────────────────┤
│ S01E03 · Revelations      [NEW] │
│ Airs: Oct 4, 2023 · 45m         │
└─────────────────────────────────┘
```

## Files to Modify

| File | Change |
|------|--------|
| `execution/backend/supabase/migrations/029_episode_air_dates.sql` | Add `air_date` column |
| `lib/shared/models/content_cache_episode.dart` | Add `airDate` field |
| `lib/shared/models/watch_progress.dart` | Expose `airDate` from episode |
| `lib/shared/services/tmdb_service.dart` | Ensure air_date is fetched |
| `lib/features/watchlist/widgets/episode_list.dart` | Display air dates |
| `lib/features/watchlist/screens/item_detail_screen.dart` | Display release date for movies |

## Edge Cases
- Episodes with null air dates (TBA)
- Movies with future release dates
- Time zone handling (use UTC, display local)
- Episodes that aired but have no runtime yet

## Priority
Medium - Enhances user experience but not critical for core functionality

## Estimated Scope
- Backend: Small (1 migration, minor RPC update)
- Frontend: Medium (model updates, UI changes across 2-3 screens)
