# Content Cache Migration Plan

## Status
Completed

## Overview

Refactor the data model to introduce a shared `content_cache` table that stores TMDB metadata once per title, eliminating redundant data storage across users and enabling popularity-based features.

---

## Current State

### Tables

**`watchlist_items`** (stores redundant content data per user):
```sql
id UUID PRIMARY KEY,
watchlist_id UUID,
tmdb_id INTEGER,
media_type TEXT,
title TEXT,              -- redundant
poster_path TEXT,        -- redundant
total_runtime_minutes INTEGER,  -- redundant
episode_runtime INTEGER, -- redundant
genre_ids INTEGER[],     -- redundant
release_date DATE,       -- redundant
added_at TIMESTAMPTZ
```

**`watch_progress`**:
```sql
id UUID PRIMARY KEY,
watchlist_item_id UUID,
season_number INTEGER,
episode_number INTEGER,
runtime_minutes INTEGER,
minutes_watched INTEGER,
watched BOOLEAN,
watched_at TIMESTAMPTZ
```

### Problems

1. **Data duplication**: If 1,000 users have "Breaking Bad", title/poster/runtime stored 1,000 times
2. **No popularity data**: Can't sort by TMDB popularity score
3. **No streaming data**: Can't filter by streaming service
4. **Stale data**: No mechanism to refresh outdated content info

---

## New Data Model

### `content_cache` (NEW - shared metadata)

One row per unique TMDB title. Shared across all users.

```sql
CREATE TABLE content_cache (
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),

  -- Basic info
  title TEXT NOT NULL,
  poster_path TEXT,
  backdrop_path TEXT,
  overview TEXT,

  -- Ratings & popularity
  vote_average FLOAT,
  vote_count INTEGER,
  popularity_score FLOAT,

  -- Categorization
  genre_ids INTEGER[],
  status TEXT,  -- "Released", "Returning Series", etc.

  -- Dates
  release_date DATE,  -- movies: release_date, TV: first_air_date

  -- Runtime
  total_runtime_minutes INTEGER,  -- movies: runtime, TV: estimated total
  episode_runtime INTEGER,        -- TV: average episode runtime

  -- TV-specific
  number_of_seasons INTEGER,
  number_of_episodes INTEGER,

  -- Streaming availability (lazy-loaded)
  streaming_providers JSONB,  -- [{id: 8, name: "Netflix", logo_path: "..."}]

  -- Freshness tracking
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  PRIMARY KEY (tmdb_id, media_type)
);

-- Index for freshness queries
CREATE INDEX idx_content_cache_updated_at ON content_cache(updated_at);

-- Index for popularity sorting
CREATE INDEX idx_content_cache_popularity ON content_cache(popularity_score DESC);
```

### `watchlist_items` (MODIFIED - slim link table)

Remove redundant content columns. Keep only the link between watchlist and content.

```sql
CREATE TABLE watchlist_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  watchlist_id UUID NOT NULL REFERENCES watchlists(id) ON DELETE CASCADE,
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
  added_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key to content cache
  FOREIGN KEY (tmdb_id, media_type) REFERENCES content_cache(tmdb_id, media_type),

  -- Prevent duplicates in same watchlist
  UNIQUE (watchlist_id, tmdb_id, media_type)
);

-- Index for querying items by watchlist
CREATE INDEX idx_watchlist_items_watchlist ON watchlist_items(watchlist_id);

-- Index for finding all users with specific content
CREATE INDEX idx_watchlist_items_content ON watchlist_items(tmdb_id, media_type);
```

### `watch_progress` (UNCHANGED)

No changes needed. Still references `watchlist_item_id`.

```sql
-- Existing structure remains
id UUID PRIMARY KEY,
watchlist_item_id UUID REFERENCES watchlist_items(id) ON DELETE CASCADE,
season_number INTEGER,
episode_number INTEGER,
runtime_minutes INTEGER,
minutes_watched INTEGER DEFAULT 0,
watched BOOLEAN DEFAULT FALSE,
watched_at TIMESTAMPTZ
```

---

## Freshness Strategy

| Data Type | Stale After | Refresh Trigger |
|-----------|-------------|-----------------|
| Basic info (title, poster, etc.) | 30 days | User views item detail |
| Popularity score | 30 days | User views item detail |
| Streaming providers | 7 days | User views item detail |

### Refresh Logic (in Flutter)

```dart
Future<ContentCache> getContentWithFreshness(int tmdbId, MediaType mediaType) async {
  final cached = await ContentCacheRepository.get(tmdbId, mediaType);

  if (cached == null) {
    // Not in cache - fetch from TMDB and insert
    return await _fetchAndCache(tmdbId, mediaType);
  }

  final age = DateTime.now().difference(cached.updatedAt);

  if (age.inDays > 30) {
    // Stale - refresh in background, return cached for now
    _refreshInBackground(tmdbId, mediaType);
  }

  return cached;
}
```

---

## Migration Steps

### Step 1: Create `content_cache` Table

```sql
-- Migration: 010_content_cache.sql

CREATE TABLE content_cache (
  tmdb_id INTEGER NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
  title TEXT NOT NULL,
  poster_path TEXT,
  backdrop_path TEXT,
  overview TEXT,
  vote_average FLOAT,
  vote_count INTEGER,
  popularity_score FLOAT,
  genre_ids INTEGER[],
  status TEXT,
  release_date DATE,
  total_runtime_minutes INTEGER,
  episode_runtime INTEGER,
  number_of_seasons INTEGER,
  number_of_episodes INTEGER,
  streaming_providers JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (tmdb_id, media_type)
);

CREATE INDEX idx_content_cache_updated_at ON content_cache(updated_at);
CREATE INDEX idx_content_cache_popularity ON content_cache(popularity_score DESC);

-- RLS: Everyone can read, only service role can write
ALTER TABLE content_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content cache"
  ON content_cache FOR SELECT USING (true);

-- Note: Writes happen via service role or Edge Function, not direct client access
```

### Step 2: Backfill `content_cache` from Existing Data

```sql
-- Migration: 011_backfill_content_cache.sql

-- Insert unique content from existing watchlist_items
INSERT INTO content_cache (
  tmdb_id,
  media_type,
  title,
  poster_path,
  genre_ids,
  release_date,
  total_runtime_minutes,
  episode_runtime
)
SELECT DISTINCT ON (tmdb_id, media_type)
  tmdb_id,
  media_type,
  title,
  poster_path,
  genre_ids,
  release_date,
  total_runtime_minutes,
  episode_runtime
FROM watchlist_items
ON CONFLICT (tmdb_id, media_type) DO NOTHING;
```

### Step 3: Add Foreign Key to `watchlist_items`

```sql
-- Migration: 012_watchlist_items_fk.sql

-- Add foreign key constraint
ALTER TABLE watchlist_items
  ADD CONSTRAINT fk_watchlist_items_content
  FOREIGN KEY (tmdb_id, media_type)
  REFERENCES content_cache(tmdb_id, media_type);
```

### Step 4: Remove Redundant Columns from `watchlist_items`

```sql
-- Migration: 013_slim_watchlist_items.sql

-- Drop redundant columns
ALTER TABLE watchlist_items
  DROP COLUMN IF EXISTS title,
  DROP COLUMN IF EXISTS poster_path,
  DROP COLUMN IF EXISTS total_runtime_minutes,
  DROP COLUMN IF EXISTS episode_runtime,
  DROP COLUMN IF EXISTS genre_ids,
  DROP COLUMN IF EXISTS release_date;
```

---

## Flutter Code Changes

### New Files

1. **`lib/shared/models/content_cache.dart`**
   - ContentCache model class
   - fromJson/toJson methods

2. **`lib/shared/repositories/content_cache_repository.dart`**
   - `get(tmdbId, mediaType)` - fetch from cache
   - `upsert(content)` - insert or update
   - `getStale(days)` - find stale entries
   - `refreshFromTmdb(tmdbId, mediaType)` - fetch and update

### Modified Files

1. **`lib/shared/models/watchlist_item.dart`**
   - Remove redundant fields (title, posterPath, etc.)
   - Add `ContentCache? content` field for joined data
   - Update fromJson to handle joined queries

2. **`lib/shared/repositories/watchlist_repository.dart`**
   - Update queries to JOIN with content_cache
   - `getWatchlistItems()` - join content data
   - `addItem()` - ensure content exists in cache first
   - Remove redundant field handling

3. **`lib/features/search/controllers/search_controller.dart`**
   - `addMovieToWatchlist()` - cache content first, then add link
   - `addTvShowToWatchlist()` - cache content first, then add link
   - `addMovieToWatchlists()` - same pattern
   - `addTvShowToWatchlists()` - same pattern

4. **`lib/features/watchlist/controllers/watchlist_controller.dart`**
   - Update to work with joined data model

### Query Pattern

```dart
// Old: All data in watchlist_items
final response = await client
    .from('watchlist_items')
    .select()
    .eq('watchlist_id', watchlistId);

// New: Join with content_cache
final response = await client
    .from('watchlist_items')
    .select('''
      id,
      watchlist_id,
      tmdb_id,
      media_type,
      added_at,
      content_cache (
        title,
        poster_path,
        overview,
        vote_average,
        popularity_score,
        genre_ids,
        release_date,
        total_runtime_minutes,
        episode_runtime,
        number_of_seasons,
        number_of_episodes,
        streaming_providers
      )
    ''')
    .eq('watchlist_id', watchlistId);
```

---

## Implementation Order

### Phase 1: Database Migration ✅
1. [x] Create migration 009_content_cache.sql
2. [x] Create migration 010_backfill_content_cache.sql
3. [x] Create migration 011_slim_watchlist_items.sql (includes FK constraint)
4. [ ] Run migrations on Supabase

### Phase 2: Flutter Models ✅
5. [x] Create ContentCache model (`lib/shared/models/content_cache.dart`)
6. [x] Update WatchlistItem model (remove redundant fields, add content reference)

### Phase 3: Flutter Repositories ✅
7. [x] Create ContentCacheRepository (`lib/shared/repositories/content_cache_repository.dart`)
8. [x] Update WatchlistRepository (join queries, slim addItem signature)

### Phase 4: Flutter Controllers ✅
9. [x] Update ContentSearchController (cache content before adding)
10. [x] Update WatchlistController (slim addItem, unified backfillContentCache)

### Phase 5: Freshness Logic ✅
11. [x] Add staleness check via ContentCache.isStale and ContentCache.isStreamingStale
12. [x] Add background refresh via WatchlistController.backfillContentCache()

### Phase 6: Verification
13. [ ] Run migrations on Supabase
14. [ ] Test adding new content (should create cache entry + link)
15. [ ] Test viewing watchlist (should show joined data)
16. [ ] Test progress tracking (should still work via watchlist_item_id)
17. [ ] Verify existing data migrated correctly

---

## Rollback Plan

If issues arise:
1. Keep old columns on watchlist_items during transition (don't drop immediately)
2. Add feature flag to switch between old/new query patterns
3. Only drop old columns after confirming stability

---

## Future Enhancements Enabled

With content_cache in place, we can now implement:
- **Viral Hits mode**: Sort by popularity_score
- **Streaming filters**: Filter by streaming_providers JSONB
- **BingeQuest Top 10**: Count users per content, join with popularity
- **Profile streaming breakdown**: Aggregate streaming_providers across user's items

---

*Last updated: 2025-01-24*
