# Feature: Episode Metadata Enhancements

## Status
Completed

## Overview
Enhance the episode list by displaying episode names and descriptions fetched from TMDB.

## Acceptance Criteria
- [ ] Episode names displayed (e.g., "S1 E1 - Pilot")
- [ ] Episode overviews displayed with "Read More" expansion
- [ ] Metadata is cached in `content_cache_episodes`

## Backend Changes
- `content_cache_episodes` table (already exists in migration 013)

## Frontend Changes
- Update `TmdbService` to fetch episode details
- Update `EpisodeListItem` UI to show name and overview
- Update `ContentCacheEpisodesRepository` to store/retrieve new fields

## QA Checklist
- [ ] Verify names and overviews match TMDB data
- [ ] Verify expansion works for long descriptions
- [ ] Verify data is cached and not re-fetched unnecessarily
