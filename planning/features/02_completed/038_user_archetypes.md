# Feature: User Archetypes (Viewer Personality Classification)

## Status
Planning

## Summary
Classify each user into one of 12 viewer archetypes based on their watching behavior. The archetype lives on the user's profile as a badge-like identity label, computed periodically from real activity data. Each archetype has a creative name, flavor text, icon, and a data-driven scoring formula.

## Scope
- [x] Included: 12 archetype definitions with scoring criteria
- [x] Included: Backend computation (SQL function or Edge Function)
- [x] Included: Store active archetype on user profile
- [x] Included: Display archetype on profile (own + friends)
- [x] Included: Archetype history (track changes over time)
- [x] Included: Manual override / pin (user can lock their favorite archetype)
- [ ] **NOT** Included: Archetype-based matchmaking or social recommendations (future)
- [ ] **NOT** Included: Archetype-based content suggestions (future)
- [ ] **NOT** Included: Leaderboards per archetype (future)

---

## The 12 Archetypes

Each archetype maps a creative identity to measurable signals from `watch_progress`, `watchlist_items`, and `content_cache`.

### 1. Weekend Warrior
> They vanish Monday-Thursday, then return like a storm front. Entire seasons fall between Friday night and Sunday midnight.

**Signal:** >= 70% of `watched_at` timestamps fall on Friday 6PM - Sunday midnight (user's local time).

### 2. Action Junkie (Genre Loyalist)
> They found their lane and never swerved. Their watchlist is a cathedral dedicated to one flavor of story.

**Signal:** >= 70% of completed titles share one or two dominant genres (via `content_cache.genre_ids`). The archetype name adapts to their genre (e.g., "Horror Devotee", "Anime Purist") but the classification is "Genre Loyalist."

### 3. Sampler Surfer (Pilot Collector)
> They start everything. Finish almost nothing. Their "Continue Watching" row is a museum of beginnings.

**Signal:** High ratio of started-but-not-completed titles. >= 60% of titles have <= 2 episodes watched AND total started titles >= 10.

### 4. Season Slayer (Completionist)
> No show left unfinished. If they start Episode 1, they will reach the final credits.

**Signal:** >= 80% completion rate across all started titles. Rarely has more than 1 in-progress show at a time.

### 5. Backlog Excavator
> They dig into the vault. Long-ignored titles finally get their moment. Their queue gets shorter while everyone else's grows.

**Signal:** Average gap between `watchlist_items.added_at` and first `watch_progress.watched_at` for that item is >= 60 days. High ratio of aged queue items finally completed vs. recently-added items.

### 6. Midnight Drifter
> Their prime viewing hours begin when the world goes quiet. 11PM to 3AM is sacred storytelling time.

**Signal:** >= 50% of `watched_at` timestamps fall between 10PM and 4AM (user's local time).

### 7. Social Curator
> They watch so they can recommend. Their group chat depends on them. "Trust me, just watch episode 3" is their signature phrase.

**Signal:** Top 10% of users by `reviews` count. Simple `COUNT(*)` from `reviews` table where `user_id = p_user_id` within the 90-day window, normalized against the platform average.

### 8. Binge Sprinter
> They don't watch shows -- they devour them. Three episodes? That's a warm-up. An entire season in one sitting? Now we're talking.

**Signal:** Frequent clusters of 3+ episodes with `watched_at` timestamps within ~2 hours of each other. Calculated by grouping consecutive `watched_at` entries per title where the gap between them is <= 90 minutes, then averaging cluster size. Score rises with average session length.

### 9. Mood Surfer (Mood Hopper)
> They don't pick shows -- they follow feelings. Their queue changes with the weather of their soul.

**Signal:** High genre entropy per week. Watches >= 3 distinct genre families within a 7-day rolling window, consistently.

### 10. Finish-First Strategist
> Efficiency is the game. They pick the show that's closest to done and knock it out. Their "in progress" list is always short and shrinking.

**Signal:** Users who disproportionately watch items with high existing completion % before starting new titles. Measured by average completion % at time of each session start -- high values mean they prioritize nearly-done shows. Also: low number of concurrent in-progress titles (typically <= 2).

### 11. Trend Chaser
> They ride the algorithm's wave. Top 10 lists, viral clips, what everyone's talking about right now.

**Signal:** >= 50% of recently started titles have `content_cache.popularity_score` in the top 10% at the time they were added. High correlation between add date and content trending date.

### 12. Deep Cut Explorer
> They dig where others don't. Foreign films, indie gems, forgotten series from 2009.

**Signal:** >= 40% of watched titles have `popularity_score` below the 25th percentile OR `release_date` older than 5 years at time of watching. Low overlap with trending/popular lists.

---

## Scoring Engine Design

### Approach: Weighted Multi-Signal Scoring

Each archetype has a scoring function that returns a value from 0.0 to 1.0 based on the user's activity. The archetype with the highest score becomes the user's active classification.

```
user_archetype = argmax(score_weekend_warrior(user), score_genre_loyalist(user), ..., score_deep_cut(user))
```

### Minimum Activity Threshold
- User must have >= 5 completed titles AND >= 20 episodes watched to receive a classification.
- Below this threshold: archetype = `null` (display: "Still Exploring...")

### Tie-Breaking
- If two archetypes score within 0.05 of each other, the user gets a **dual archetype** label (e.g., "Midnight Drifter + Completionist").
- Maximum 2 archetypes displayed.

### Recomputation Schedule
- **Trigger:** Recompute on every 5th episode completion (via database trigger or Edge Function).
- **Fallback:** Nightly batch recompute for all active users (cron Edge Function).
- **Window:** Scoring uses a rolling 90-day activity window (avoids stale data from years ago dominating).

### Self-Selection Supplement (Optional, Low Priority)
All 12 archetypes are now fully data-driven. A "Viewing Style Quiz" could still be offered as a fun profile feature, but is no longer required for accurate classification. If implemented, quiz answers would act as minor signal boosts (+0.1) rather than filling detection gaps.

---

## Backend / Data Layer

### New Tables

#### `archetypes` (reference table)
| Column | Type | Notes |
|--------|------|-------|
| `id` | `text` PK | e.g., `weekend_warrior`, `genre_loyalist` |
| `display_name` | `text` | "Weekend Warrior" |
| `tagline` | `text` | Short flavor text |
| `description` | `text` | Full creative description |
| `icon_name` | `text` | Icon asset reference |
| `color_hex` | `text` | Brand color for the archetype |
| `sort_order` | `int` | Display ordering |

Seeded with 12 rows. Immutable from client side.

#### `user_archetypes` (computed results)
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid` PK | default `gen_random_uuid()` |
| `user_id` | `uuid` FK -> users.id | ON DELETE CASCADE |
| `archetype_id` | `text` FK -> archetypes.id | |
| `score` | `numeric(4,3)` | 0.000 - 1.000 |
| `rank` | `smallint` | 1 = primary, 2 = secondary |
| `computed_at` | `timestamptz` | When this was calculated |
| `is_pinned` | `boolean` | User manually pinned this |

- Unique constraint on `(user_id, archetype_id, computed_at)`.
- Index on `(user_id, computed_at DESC)` for quick "current archetype" lookups.

#### Add to `users` table
| Column | Type | Notes |
|--------|------|-------|
| `primary_archetype` | `text` FK -> archetypes.id | Denormalized for fast reads |
| `secondary_archetype` | `text` FK -> archetypes.id | Nullable |
| `archetype_updated_at` | `timestamptz` | |

### RLS Policies
- `archetypes`: SELECT for all authenticated users (read-only reference data).
- `user_archetypes`: SELECT own rows + friends' rows (via `are_friends()`). No INSERT/UPDATE/DELETE from client (service_role only).
- `users.primary_archetype`: Already visible via existing users SELECT policy.

### Database Functions

#### `compute_user_archetype(p_user_id uuid)`
- **Type:** SECURITY DEFINER function (called by Edge Function or trigger).
- **Logic:** Runs all 12 scoring queries against the user's 90-day activity window, inserts results into `user_archetypes`, updates `users.primary_archetype` and `secondary_archetype`.
- **Returns:** The winning archetype ID.

#### Scoring Sub-Queries (inside the function)
Each archetype score is a standalone CTE or sub-function:

1. **Weekend Warrior:** `COUNT(watched_at WHERE dow IN (5,6,0)) / COUNT(watched_at)` (adjusted for timezone)
2. **Genre Loyalist:** Max single-genre ratio from completed titles' `genre_ids`
3. **Sampler Surfer:** `COUNT(titles with <= 2 eps) / COUNT(started titles)`
4. **Season Slayer:** `AVG(completion_rate) across started titles`
5. **Backlog Excavator:** `AVG(first_watched_at - added_at)` in days, normalized (higher = stronger signal)
6. **Midnight Drifter:** `COUNT(watched_at WHERE hour BETWEEN 22 AND 4) / COUNT(watched_at)`
7. **Social Curator:** `COUNT(reviews) / platform_avg_reviews` normalized to 0-1
8. **Binge Sprinter:** Average session cluster size (consecutive episodes within 90min gaps), normalized
9. **Mood Surfer:** Genre entropy (Shannon entropy of genre distribution per week, averaged)
10. **Finish-First Strategist:** `AVG(completion_pct at session start)` + penalty for concurrent in-progress titles > 2
11. **Trend Chaser:** `AVG(popularity_percentile of titles at add time)`
12. **Deep Cut Explorer:** `AVG(1 - popularity_percentile)` + age bonus

### Edge Function: `compute-archetypes`
- **Trigger:** Called by cron (nightly) or by a Postgres trigger after every 5th episode completion.
- **Logic:** Calls `compute_user_archetype()` for target user(s).
- **Auth:** service_role only.

### Data Dependencies (All Existing -- No Schema Changes Needed)
- `watch_progress.watched_at` -- timestamp analysis (time-of-day, day-of-week, session clustering)
- `watch_progress.minutes_watched` -- not used for classification (unreliable as attention proxy)
- `watchlist_items.added_at` -- when user added content (backlog age calculation)
- `content_cache.genre_ids` -- genre classification
- `content_cache.popularity_score` -- trending/obscure detection
- `content_cache.release_date` -- old vs. new content
- `content_cache.number_of_episodes` -- completion rate calculation
- `reviews` -- social curator signal (simple count)
- `notification_preferences.timezone` -- localize time-of-day calculations (fallback: UTC)

---

## UX & Interaction

### Profile Display
- Archetype badge displayed prominently on the user's profile card, below display name.
- Shows: icon + archetype name + tagline.
- Tap to expand: full description + score breakdown (radar chart showing all 12 scores).
- If dual archetype: show both with a "+" connector.
- If no archetype yet: "Still Exploring..." with a progress indicator toward the 5-title threshold.

### Archetype Detail Sheet
- Bottom sheet triggered by tapping the archetype badge.
- Content: full description, "You scored X% in this archetype", radar/spider chart of all 12 scores, history timeline.
- Action: "Pin this archetype" toggle (prevents auto-update).
- Action (optional): "Take the Viewing Style Quiz" button (low priority -- see below).

### Friends' Profiles
- Show archetype badge on friend profile cards and friend list items.
- Compact display: icon + name only (no tagline).

### Viewing Style Quiz (Optional -- Low Priority)
- All 12 archetypes are now fully data-driven, so this is a "nice to have" engagement feature.
- 5 multiple-choice questions. Results give minor score boosts (+0.1).
- Can be retaken once per month.
- Accessible from: Profile Settings > "Viewing Style Quiz".
- **Recommendation:** Skip for v1. Revisit if users request it.

### Notifications
- Push notification when archetype changes: "Your viewing style has evolved! You're now a Weekend Warrior."
- Respect existing notification preferences.

---

## Migration Plan (Ordered)

### Migration 1: `create_archetypes_tables`
```sql
-- Create reference table
CREATE TABLE public.archetypes ( ... );

-- Seed 12 archetypes
INSERT INTO public.archetypes VALUES ( ... );

-- Create user_archetypes table
CREATE TABLE public.user_archetypes ( ... );

-- Add columns to users table
ALTER TABLE public.users ADD COLUMN primary_archetype text REFERENCES archetypes(id);
ALTER TABLE public.users ADD COLUMN secondary_archetype text REFERENCES archetypes(id);
ALTER TABLE public.users ADD COLUMN archetype_updated_at timestamptz;

-- RLS
ALTER TABLE public.archetypes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_archetypes ENABLE ROW LEVEL SECURITY;
CREATE POLICY ... ;

-- Indexes
CREATE INDEX ... ;
```

### Migration 2: `create_archetype_scoring_function`
```sql
CREATE OR REPLACE FUNCTION compute_user_archetype(p_user_id uuid) ...
```

No schema changes needed to existing tables -- all 12 archetypes are computed from existing columns.

---

## Frontend Changes

### Models
- `Archetype` -- maps to `archetypes` table
- `UserArchetype` -- maps to `user_archetypes` with score/rank

### Repository
- `ArchetypeRepository`
  - `fetchAllArchetypes()` -- reference data (cache locally)
  - `fetchUserArchetype(userId)` -- current primary + secondary
  - `fetchArchetypeScores(userId)` -- all 12 scores for radar chart
  - `fetchArchetypeHistory(userId)` -- timeline of changes
  - `pinArchetype(archetypeId)` -- toggle pin
  - `submitQuizAnswers(answers)` -- post quiz results

### Controller
- `ArchetypeController` (GetX)
  - `currentArchetype`, `secondaryArchetype` observables
  - `allScores` for radar chart
  - `isPinned` state
  - `quizCompleted` state

### Widgets
- `ArchetypeBadge` -- compact badge for profile cards / friend list
- `ArchetypeDetailSheet` -- bottom sheet with full info + radar chart
- `ArchetypeRadarChart` -- spider/radar chart of all 12 scores
- `ViewingStyleQuiz` -- multi-step quiz widget
- `ArchetypeHistoryTimeline` -- scrollable timeline of past archetypes

---

## Acceptance Criteria
- [ ] 12 archetypes seeded in reference table
- [ ] Scoring function correctly computes all 12 scores from existing activity data (no new columns required)
- [ ] User's primary (and optional secondary) archetype displays on their profile
- [ ] Archetype displays on friend profiles
- [ ] Tapping archetype opens detail sheet with score breakdown
- [ ] User can pin an archetype to prevent auto-updates
- [ ] Archetype recomputes nightly and on every 5th episode completion
- [ ] Users below activity threshold see "Still Exploring..." placeholder
- [ ] Push notification sent when archetype changes
- [ ] All new tables have proper RLS policies
- [ ] No classification runs on users with < 5 completed titles

---

## Open Questions
1. **Historical depth:** Should the radar chart show score trends over time, or just the current snapshot?
2. **Archetype art:** Do we want unique illustrations per archetype, or icon-based with color coding?
3. **Dual archetype display:** "Weekend Warrior + Completionist" -- is "+" the right connector, or use "x" / "&"?
4. **Social visibility:** Should archetype be visible to all users, or only friends? (Current plan: friends only via existing users SELECT policy.)
5. **Quiz (low priority):** Worth building as a fun engagement feature even though it's no longer needed for classification accuracy?
