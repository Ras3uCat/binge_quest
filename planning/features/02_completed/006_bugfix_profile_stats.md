# Bug Fix: Profile Stats Performance & Minutes Watched Accuracy

## Status
✅ Complete

## Priority
High

## Problem Description
Two related issues on the user profile "Your Stats" section:
1. **Performance**: Stats section takes a long time to load
2. **Accuracy**: Minutes watched is not updating correctly

## Expected Behavior
- Stats should load quickly (< 1 second)
- Minutes watched should accurately reflect all watched content

## Current Behavior
- Stats section has noticeable loading delay
- Minutes watched shows incorrect/stale values

## Investigation Needed

### Performance
- [ ] Profile the stats query to identify slow operations
- [ ] Check if stats are calculated on-demand vs cached
- [ ] Identify N+1 query patterns
- [ ] Check if unnecessary data is being fetched

### Accuracy
- [ ] Verify `watch_progress.minutes_watched` is being updated on episode completion
- [ ] Check if movie runtime is being counted
- [ ] Verify aggregation query sums correctly
- [ ] Check for timezone or data type issues

## Likely Affected Files
- `lib/features/profile/controllers/profile_controller.dart`
- `lib/features/profile/screens/profile_screen.dart`
- `lib/shared/repositories/stats_repository.dart` (if exists)
- `lib/shared/repositories/watchlist_repository.dart`

## Potential Fixes

### Performance
1. Create materialized view or cached stats table
2. Add database indexes for stats queries
3. Use Supabase RPC function for optimized aggregation
4. Lazy load stats section (load after initial render)

### Accuracy
1. Ensure episode completion updates `minutes_watched`
2. Fix aggregation to include both movies and TV episodes
3. Use `content_cache_episodes.runtime_minutes` for accurate TV data
4. Add migration to backfill missing minutes data

## Proposed Stats RPC
```sql
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS TABLE(
  total_items BIGINT,
  completed_items BIGINT,
  total_minutes_watched BIGINT,
  movies_watched BIGINT,
  episodes_watched BIGINT
) AS $$
  -- Optimized single query for all stats
$$ LANGUAGE SQL STABLE;
```

## Acceptance Criteria
- [x] Stats load in < 1 second
- [x] Minutes watched matches actual watch history
- [x] Stats update after marking content as watched
- [x] No visual jank during load

## Solution Applied

### Root Cause
1. **Performance**: N+1 query pattern - looping through watchlists → items → progress entries
2. **Accuracy**: `runtime_minutes` read from wrong field (top-level instead of nested `content_cache_episodes`)

### Fix
1. Created `get_user_stats` RPC (`026_user_stats_rpc.sql`) - single optimized query
2. Fixed fallback calculation to read runtime from correct nested field
3. Added movie runtime from `content_cache.total_runtime_minutes`

### Files Modified
- `execution/backend/supabase/migrations/026_user_stats_rpc.sql` (new)
- `lib/shared/repositories/watchlist_repository.dart` (updated `getUserStats`)

## QA Steps
1. Mark several episodes and movies as watched
2. Note the runtimes
3. Go to profile
4. Verify stats load quickly
5. Verify minutes watched = sum of all runtimes
6. Mark another item watched
7. Return to profile, verify stats updated
