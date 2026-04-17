# Feature: Content Cache on View

## Status
Completed

## Overview
Expand content caching strategy to cache content metadata (including streaming providers) when a user views content details, not just when added to a watchlist. This enables streaming badges on search results for previously-viewed content and improves app performance.

## Related
- Enhances `streaming_badge.md` - enables badges on search results
- Improves overall app performance (cached detail views)

## Current Behavior
- Content only cached when added to watchlist
- Search results have no streaming badge data
- Every detail view fetches fresh from TMDB

## New Behavior
- Content cached on detail view (click)
- Search results show streaming badge for cached content
- Detail views load instantly for cached content
- Cache cleaned up periodically for unused content

## Benefits
1. **Streaming badges on search** - gradually covers more content
2. **Faster detail views** - cached content loads instantly
3. **Reduced API calls** - TMDB called once per content
4. **Shared cache** - User A views content, User B benefits

## Data Model Changes

### content_cache table (existing)
Add column:
```sql
ALTER TABLE content_cache
ADD COLUMN last_accessed_at TIMESTAMPTZ DEFAULT NOW();
```

Update on every access (view or already in watchlist load).

## Implementation

### Phase 1: Cache on Detail View

**File:** `lib/features/search/controllers/search_controller.dart` (or content detail logic)

When user opens content detail:
1. Check if content exists in `content_cache`
2. If exists: load from cache, update `last_accessed_at`
3. If not: fetch from TMDB, cache with streaming providers

```dart
Future<ContentCache> getOrFetchContent(int tmdbId, MediaType mediaType) async {
  // Try cache first
  var cached = await ContentCacheRepository.get(tmdbId, mediaType);

  if (cached != null) {
    // Update last accessed
    await ContentCacheRepository.updateLastAccessed(tmdbId, mediaType);
    return cached;
  }

  // Fetch from TMDB
  final details = mediaType == MediaType.movie
      ? await TmdbService.getMovieDetails(tmdbId)
      : await TmdbService.getTvShowDetails(tmdbId);

  // Fetch streaming providers
  final providers = await TmdbService.getWatchProviders(tmdbId, mediaType);

  // Cache and return
  final content = ContentCacheRepository.fromTmdb(details, providers);
  return ContentCacheRepository.upsert(content);
}
```

### Phase 2: Streaming Badge on Search Results

**File:** `lib/features/search/controllers/search_controller.dart`

After search results return, batch lookup cached streaming data:

```dart
Future<void> _enrichSearchResultsWithStreamingData() async {
  final tmdbIds = searchResults.map((r) => r.id).toList();

  // Single batch query
  final cachedProviders = await ContentCacheRepository.getStreamingProvidersForIds(tmdbIds);

  // Merge into results (or store in separate map)
  _streamingProviderMap.value = cachedProviders;
}
```

**New repository method:**
```dart
static Future<Map<int, List<StreamingProviderInfo>>> getStreamingProvidersForIds(
  List<int> tmdbIds,
) async {
  final response = await _client
      .from('content_cache')
      .select('tmdb_id, streaming_providers')
      .inFilter('tmdb_id', tmdbIds);

  return Map.fromEntries(
    (response as List).map((row) => MapEntry(
      row['tmdb_id'] as int,
      _parseProviders(row['streaming_providers']),
    )),
  );
}
```

### Phase 3: Top 10 Streaming Badge

Modify RPC to join `content_cache`:

```sql
CREATE OR REPLACE FUNCTION get_top_10_by_users()
RETURNS TABLE(
  tmdb_id INTEGER,
  media_type TEXT,
  title TEXT,
  poster_path TEXT,
  user_count BIGINT,
  streaming_providers JSONB  -- Add this
) AS $$
  SELECT
    wi.tmdb_id,
    wi.media_type,
    wi.title,
    wi.poster_path,
    COUNT(DISTINCT wi.user_id) as user_count,
    cc.streaming_providers
  FROM watchlist_items wi
  LEFT JOIN content_cache cc
    ON cc.tmdb_id = wi.tmdb_id
    AND cc.media_type = wi.media_type
  GROUP BY wi.tmdb_id, wi.media_type, wi.title, wi.poster_path, cc.streaming_providers
  ORDER BY user_count DESC
  LIMIT 10;
$$ LANGUAGE SQL STABLE;
```

### Phase 4: Cache Cleanup (Background Job)

**Supabase scheduled function or Edge Function:**

```sql
-- Run weekly: Remove stale unclaimed content
DELETE FROM content_cache
WHERE tmdb_id NOT IN (SELECT DISTINCT tmdb_id FROM watchlist_items)
  AND last_accessed_at < NOW() - INTERVAL '90 days';
```

## Migration

**File:** `execution/backend/supabase/migrations/023_content_cache_last_accessed.sql`

```sql
-- Add last_accessed_at column
ALTER TABLE content_cache
ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMPTZ DEFAULT NOW();

-- Backfill existing rows
UPDATE content_cache SET last_accessed_at = updated_at WHERE last_accessed_at IS NULL;

-- Index for cleanup query
CREATE INDEX idx_content_cache_last_accessed
ON content_cache(last_accessed_at)
WHERE tmdb_id NOT IN (SELECT DISTINCT tmdb_id FROM watchlist_items);
```

## Task Summary

| # | Task | Scope |
|---|------|-------|
| 1 | Add `last_accessed_at` column migration | Backend |
| 2 | Add `getStreamingProvidersForIds()` to repository | Frontend |
| 3 | Add `updateLastAccessed()` to repository | Frontend |
| 4 | Cache content on detail view | Frontend |
| 5 | Enrich search results with cached streaming data | Frontend |
| 6 | Update Top 10 RPC to include streaming_providers | Backend |
| 7 | Update `TopContent` model for streaming data | Frontend |
| 8 | Add StreamingBadge to search result cards | Frontend |
| 9 | Add StreamingBadge to Top 10 cards | Frontend |
| 10 | Create cleanup scheduled function | Backend |

## Acceptance Criteria
- [ ] Viewing content details caches to `content_cache`
- [ ] Cached content loads faster on subsequent views
- [ ] Search results show streaming badge for cached content
- [ ] Top 10 shows streaming badges
- [ ] Cache cleaned up after 90 days for non-watchlist content
- [ ] No performance degradation on search

## QA Checklist
- [ ] Search for popular movie → no badge (first time)
- [ ] Click to view details → content cached
- [ ] Search again → badge now appears
- [ ] View Top 10 → badges appear
- [ ] Performance: Search still fast with batch lookup
