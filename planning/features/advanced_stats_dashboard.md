# Feature: Advanced Stats Dashboard

## Status
TODO

## Overview
Provide users with detailed insights into their viewing habits through an interactive stats dashboard with charts. Summary cards live on the profile screen; tapping opens a dedicated full-screen stats experience with mood distribution, watch time trends, completion rate, episode pace, peak viewing hours, and streak tracking. All stats are filterable by time window (Week / Month / Year / All Time).

## User Stories
- As a user, I want to see a summary of my viewing stats on my profile
- As a user, I want to tap into a full stats screen with detailed charts
- As a user, I want to see which moods I watch most (based on existing MoodTag system)
- As a user, I want to see my watch time trends over days/weeks
- As a user, I want to know my completion rate across my watchlists
- As a user, I want to see how many episodes I watch per day on average
- As a user, I want to know what time of day I watch the most
- As a user, I want to see my current watch streak (consecutive days)
- As a user, I want to filter all stats by week / month / year / all time

## Acceptance Criteria
- [ ] Profile screen: summary stat cards (time watched, completions, streak) — tap to open full stats
- [ ] Dedicated stats screen with time window picker (Week / Month / Year / All Time)
- [ ] Mood distribution chart (donut/pie) using existing `MoodTag` genre mapping
- [ ] Watch time trend chart (bar chart — minutes per day or per week depending on window)
- [ ] Completion rate card (completed / total items as percentage + ring chart)
- [ ] Average episode pace (episodes per day in the selected window)
- [ ] Peak watch hours chart (bar chart — distribution by hour of day, 0-23)
- [ ] Watch streak tracker (current streak + longest streak in days)
- [ ] All charts use `fl_chart` library
- [ ] Loading skeletons while stats compute
- [ ] Empty states when no data exists for selected time window

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Placement | Profile summary + dedicated screen | Summary cards on profile for quick glance; tap opens full stats screen with all charts. Avoids cluttering profile. |
| Time windows | Week / Month / Year / All Time | Four standard windows. Simple picker, covers most use cases. No custom date ranges for v1. |
| Mood system | Existing `MoodTag` enum (6 moods) | Reuses the genre-to-mood mapping already in `mood_tag.dart`. No new data model needed — aggregate by TMDB genre IDs, group into moods client-side. |
| Chart library | `fl_chart` | Most popular Flutter chart lib. Supports pie, line, bar. Well-maintained. |
| Aggregation | Server-side RPCs | Heavy aggregation in Postgres RPCs for performance. Client receives pre-computed numbers and chart data points. |
| Social stats | None (v1) | Personal stats only. Social leaderboards deferred to a future version. |
| Streak calculation | Server-side | Streak requires scanning consecutive days — more efficient as a single SQL query than fetching all progress rows to the client. |
| Peak hours | Based on `watched_at` timestamps | Uses existing timestamp data on `watch_progress` rows. Groups by hour of day (0-23). |

---

## Existing Infrastructure

These already exist and will be leveraged:

| Component | Location | What it does |
|-----------|----------|-------------|
| `get_user_stats()` RPC | Migration 026 | Total minutes, movies, shows, episodes (all-time) |
| `get_streaming_breakdown()` RPC | Migration 026 | Provider distribution |
| `ProfileController` | Frontend | Loads basic stats, streaming breakdown |
| Profile stat cards | Frontend | 4-tile layout (time, episodes, movies, shows) |
| `MoodTag` enum | `shared/models/mood_tag.dart` | 6 moods with TMDB genre ID mappings |

---

## Backend Changes

### New RPC: `get_stats_dashboard(p_time_window TEXT)`

Returns all stats for the selected time window in a single call. Time window values: `'week'`, `'month'`, `'year'`, `'all'`.

**Returns (JSON object):**
```json
{
  "summary": {
    "minutes_watched": 4320,
    "items_completed": 12,
    "total_items": 45,
    "episodes_watched": 87,
    "movies_completed": 5,
    "shows_completed": 7
  },
  "watch_time_trend": [
    { "date": "2026-02-03", "minutes": 120 },
    { "date": "2026-02-04", "minutes": 45 },
    ...
  ],
  "genre_distribution": [
    { "genre_id": 35, "genre_name": "Comedy", "minutes": 800, "count": 5 },
    { "genre_id": 18, "genre_name": "Drama", "minutes": 1200, "count": 8 },
    ...
  ],
  "peak_hours": [
    { "hour": 0, "minutes": 30 },
    { "hour": 1, "minutes": 0 },
    ...
    { "hour": 20, "minutes": 180 },
    { "hour": 21, "minutes": 240 },
    ...
  ],
  "streaks": {
    "current_streak": 5,
    "longest_streak": 14
  },
  "episode_pace": {
    "episodes_per_day": 2.3,
    "days_in_window": 30
  }
}
```

**Key implementation notes:**
- Time window filter: `WHERE watched_at >= now() - INTERVAL '...'` (1 week / 1 month / 1 year / no filter)
- Watch time trend: `GROUP BY date_trunc('day', watched_at)` for week/month, `GROUP BY date_trunc('week', watched_at)` for year/all
- Genre distribution: Join `watch_progress → watchlist_items` to get genre IDs. Return raw genre-level data; client maps to moods.
- Peak hours: `GROUP BY extract(hour FROM watched_at)`
- Streak: Window function scanning consecutive distinct watch dates
- Episode pace: `episodes_watched / days_with_activity` in the window

### Migration (number TBD)

No new tables required. The RPC queries existing `watch_progress`, `watchlist_items`, and `watchlists` tables. Migration creates:

1. `get_stats_dashboard(p_user_id UUID, p_time_window TEXT)` — SECURITY DEFINER function
2. Index on `watch_progress(watched_at)` if not already present (needed for time-window queries)
3. Composite index on `watch_progress(watchlist_item_id, watched_at)` for the join + filter pattern

---

## Mood Aggregation Strategy

Genre data comes from the RPC as raw `(genre_id, minutes, count)` rows. The client maps these to moods using the existing `MoodTag.genreIds` mapping:

```dart
Map<MoodTag, MoodStats> aggregateMoods(List<GenreStats> genreData) {
  final result = <MoodTag, MoodStats>{};
  for (final mood in MoodTag.values) {
    final matchingGenres = genreData.where(
      (g) => mood.genreIds.contains(g.genreId),
    );
    result[mood] = MoodStats(
      mood: mood,
      totalMinutes: matchingGenres.fold(0, (sum, g) => sum + g.minutes),
      itemCount: matchingGenres.fold(0, (sum, g) => sum + g.count),
    );
  }
  return result;
}
```

**Note:** A single item can map to multiple moods (e.g., Comedy maps to both Comfort and Lighthearted). This is intentional — the donut chart shows mood affinity, not exclusive categories. The chart should use the mood's existing color from `MoodTag.color`.

---

## UI Design

### Profile Summary Cards (updated)
```
┌──────────────┬──────────────┐
│  72h 15m     │  12/45       │
│  Time Watched│  Completed   │
├──────────────┼──────────────┤
│  87          │  5 days      │
│  Episodes    │  Streak      │
└──────────────┴──────────────┘
       [ View Full Stats > ]
```
- Replaces current 4-card layout (swaps Movies/Shows for Completed ratio + Streak)
- "View Full Stats" opens the dedicated stats screen
- Cards show all-time values; the full screen has time filtering

### Stats Screen Layout
```
┌─────────────────────────────────────┐
│ Your Stats                     [X]  │
│ [Week] [Month] [Year] [All Time]    │
├─────────────────────────────────────┤
│                                     │
│ ┌─ Summary Row ───────────────────┐ │
│ │ 72h 15m watched  87 episodes    │ │
│ │ 12 completed     2.3 eps/day    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─ Mood Distribution ─────────────┐ │
│ │        ┌───────┐                │ │
│ │       /  Donut  \               │ │
│ │      │  Chart   │              │ │
│ │       \ (moods) /               │ │
│ │        └───────┘                │ │
│ │ Comfort 28%  Emotional 22%     │ │
│ │ Escapism 20% Intense 15%       │ │
│ │ Thriller 10% Lighthearted 5%   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─ Watch Time Trend ──────────────┐ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │  ▇                          │ │ │
│ │ │  ▇  ▇     ▇                 │ │ │
│ │ │  ▇  ▇  ▇  ▇  ▇             │ │ │
│ │ │  ▇  ▇  ▇  ▇  ▇  ▇  ▇      │ │ │
│ │ │ Mon Tue Wed Thu Fri Sat Sun  │ │ │
│ │ └─────────────────────────────┘ │ │
│ │ Total: 12h 30m this week       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─ Peak Watch Hours ──────────────┐ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │           ▇▇                │ │ │
│ │ │         ▇▇▇▇▇              │ │ │
│ │ │  ▇    ▇▇▇▇▇▇▇▇            │ │ │
│ │ │ 6am  12pm   6pm   12am     │ │ │
│ │ └─────────────────────────────┘ │ │
│ │ You watch most at 9 PM          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─ Streaks ───────────────────────┐ │
│ │ Current Streak: 5 days          │ │
│ │ Longest Streak: 14 days         │ │
│ │ ● ● ● ● ● ○ ○  (this week)    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─ Completion Rate ───────────────┐ │
│ │   ┌───────┐                     │ │
│ │  / 27%    \   12 of 45 items   │ │
│ │ │ complete │   5 movies         │ │
│ │  \        /    7 shows          │ │
│ │   └───────┘                     │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### Chart Interactions
- Donut chart: tap a segment to highlight that mood's stats
- Bar charts: tap a bar to see the exact value in a tooltip
- Time window picker: animated transition between windows
- Pull-to-refresh to reload stats

---

## Frontend Architecture

### New Files
| File | Purpose |
|------|---------|
| `lib/shared/models/stats_data.dart` | `StatsData`, `MoodStats`, `WatchTimeTrend`, `PeakHour`, `StreakData`, `GenreStats` models |
| `lib/shared/repositories/stats_repository.dart` | Calls `get_stats_dashboard` RPC, parses response |
| `lib/features/stats/controllers/stats_controller.dart` | GetX state: time window selection, loading, parsed chart data, mood aggregation |
| `lib/features/stats/screens/stats_screen.dart` | Full stats screen with scrollable chart sections |
| `lib/features/stats/widgets/mood_donut_chart.dart` | `fl_chart` PieChart for mood distribution |
| `lib/features/stats/widgets/watch_time_bar_chart.dart` | `fl_chart` BarChart for daily/weekly watch time |
| `lib/features/stats/widgets/peak_hours_chart.dart` | `fl_chart` BarChart for hourly distribution (0-23) |
| `lib/features/stats/widgets/completion_ring.dart` | `fl_chart` PieChart as a ring/gauge for completion % |
| `lib/features/stats/widgets/streak_indicator.dart` | Current + longest streak with dot visualization |
| `lib/features/stats/widgets/stats_summary_row.dart` | Compact summary numbers row at top of stats screen |
| `lib/features/stats/widgets/time_window_picker.dart` | Segmented control for Week / Month / Year / All Time |

### Modified Files
| File | Changes |
|------|---------|
| `pubspec.yaml` | Add `fl_chart` dependency |
| Profile screen | Update stat cards (add streak + completion ratio), add "View Full Stats" tap target |
| `ProfileController` | Add navigation to stats screen, update summary card data |

### New Dependency
```yaml
dependencies:
  fl_chart: ^0.69.0  # verify latest version at implementation time
```

---

## Dependencies
- **Existing `watch_progress` table** — all stats derived from watch progress timestamps
- **Existing `MoodTag` enum** — mood-to-genre mapping for donut chart
- **Existing `get_user_stats()` RPC** — profile summary cards continue to use this for all-time quick stats
- **`watched_at` column on `watch_progress`** — required for time-windowed queries, peak hours, streaks

---

## Edge Cases
- No watch progress at all → empty state: "Start watching to see your stats!"
- Selected time window has no activity → show zeroes with "No activity this week/month/year" message
- User with only movies (no TV) → episode pace section hidden or shows "N/A"
- User with only TV (no movies) → completion rate still works (shows count)
- Single-day activity → streak = 1, trend chart shows one bar
- Content with no genres in TMDB → excluded from mood chart (doesn't map to any mood)
- Content mapping to multiple moods → counted in each mood (intentional, chart shows affinity)
- Very long streak (365+ days) → format as "1y 2d" or similar
- Large watch history (1000+ items) → RPC performance critical; indexes on `watched_at` essential
- Time zone handling → use `watched_at` in user's local time zone for peak hours (pass TZ from client or use `notification_preferences.timezone`)

---

## Performance Considerations
- Single RPC call for all stats data (avoid N+1 queries)
- Index on `watch_progress(watched_at)` for time-window filtering
- Composite index on `watch_progress(watchlist_item_id, watched_at)` for join pattern
- Client caches stats per time window — only re-fetches on pull-to-refresh or window change
- Skeleton loading placeholders while RPC executes
- Genre-to-mood aggregation happens client-side (small data, fast computation)

---

## QA Checklist
- [ ] Profile summary cards show correct all-time stats
- [ ] Tapping "View Full Stats" navigates to stats screen
- [ ] Time window picker switches between Week / Month / Year / All Time
- [ ] Stats update correctly when switching time windows
- [ ] Mood donut chart shows correct distribution with mood colors
- [ ] Tapping a donut segment highlights that mood
- [ ] Watch time trend shows correct bars per day (week/month) or per week (year/all)
- [ ] Peak hours chart shows correct hourly distribution
- [ ] Peak hour insight text identifies the correct hour
- [ ] Completion rate ring shows correct percentage
- [ ] Episode pace shows correct episodes/day average
- [ ] Current streak count is accurate
- [ ] Longest streak count is accurate
- [ ] Streak dot visualization shows correct days for current week
- [ ] Empty state displays when no activity in selected window
- [ ] Loading skeletons appear while data loads
- [ ] Charts render correctly on small screens (5" phones)
- [ ] Charts render correctly on large screens (tablets)
- [ ] Pull-to-refresh reloads stats
- [ ] Stats match actual watch history (spot-check against watchlist)
- [ ] Content with no TMDB genres is excluded from mood chart without errors
- [ ] Very large watch history (100+ items) doesn't cause slow load times
