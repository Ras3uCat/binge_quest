# Feature: Contextual Info Guides

## Status
🔲 Planned

## Overview
Extend the existing info icon + bottom sheet pattern (currently used on Queue Health and Mood) to other parts of the app where users encounter non-obvious metrics, scoring systems, or modes. Each guide is a lightweight bottom sheet, accessible via a small `Icons.info_outline` icon next to the relevant heading. All guides should also be listed in Settings > Help for discoverability.

## Existing Pattern (reference implementation)
- `QueueEfficiencyGuideSheet` — `lib/shared/widgets/queue_efficiency_guide_sheet.dart`
- `MoodGuideSheet` — `lib/shared/widgets/mood_guide_sheet.dart`
- Entry point: info icon tap → `GuideSheet.show()` (static method on the widget)
- Settings > Help lists all guides as tappable rows

---

## Proposed Guides

### 1. Streak Guide
**Priority:** High
**Location:** Stats screen, next to the Streak section heading
**Widget to create:** `lib/shared/widgets/streak_guide_sheet.dart`
**Settings entry:** "Streak & Activity"

**Content to cover:**
- What counts as a streak day (any watch progress logged that calendar day)
- What breaks a streak (missing a full calendar day with no progress)
- Current streak vs. best streak distinction
- The 7-day activity dot row — what filled vs. empty means
- Tip: even partial progress on an episode counts toward keeping a streak alive

---

### 2. Recommendation Modes Guide
**Priority:** High
**Location:** Dashboard recommendations section, next to the mode selector chips (Smart / New Arrivals / Popular / Top Rated)
**Widget to create:** `lib/shared/widgets/recommendation_modes_guide_sheet.dart`
**Settings entry:** "Recommendation Modes"

**Content to cover:**
- **Smart** — personalised picks from your watchlist based on mood, genre history, and what you're close to finishing
- **New Arrivals** — recently added to streaming in your region
- **Popular** — trending across BingeQuest users this week
- **Top Rated** — highest TMDB scores filtered to what's available on your streaming services
- Note: Smart mode uses your current mood filter if one is selected

---

### 3. Badges Guide
**Priority:** Medium
**Location:** Badges screen, top-right info icon in the app bar
**Widget to create:** `lib/shared/widgets/badges_guide_sheet.dart`
**Settings entry:** "Badges & Achievements"

**Content to cover:**
- Badge categories: Completion, Milestone, Genre, Activity/Streak
- How badges are awarded (automatically on next app open after criteria met)
- Examples of thresholds (e.g., watch 10 hours total, complete 5 shows, maintain a 7-day streak)
- Locked badges still visible as motivation
- Activity badges (Queue Manager 50+, Efficiency Expert 75+, Queue Master 90+) tie back to the Queue Health score

---

### 4. Watch Party Guide
**Priority:** Medium
**Location:** Watch Party screen, info icon in the app bar or next to "Members" heading
**Widget to create:** `lib/shared/widgets/watch_party_guide_sheet.dart`
**Settings entry:** "Watch Parties"

**Content to cover:**
- Watch parties are async (not live screen-share) — everyone watches on their own time
- Progress is tracked per member; the party view shows where each person is
- For TV shows: per-episode progress per member across seasons
- For movies: a progress bar per member
- Creator can dissolve the party; members can leave independently
- Completing all episodes/movie marks you as done in the party

---

### 5. Stats Overview Guide
**Priority:** Medium
**Location:** Stats screen, info icon next to "Your Stats" heading or in app bar
**Widget to create:** `lib/shared/widgets/stats_guide_sheet.dart`
**Settings entry:** "Stats & Analytics"

**Content to cover:**
- **Watch Time bar chart** — hours logged per weekday across the selected time window
- **Peak Hours chart** — time-of-day distribution; shows when you most often start watching
- **Completion ring** — completed vs. remaining across your entire watchlist
- **Mood donut** — breakdown of completed items by mood tag
- **Time windows** (This Week / Month / Year / All Time) — all charts filter to the selected window except the completion ring (always all-time)
- Progress is based on logged watch events, not estimated from runtime

---

### 6. Streaming Breakdown Guide
**Priority:** Low
**Location:** Profile screen, info icon next to "Streaming Breakdown" heading
**Widget to create:** `lib/shared/widgets/streaming_breakdown_guide_sheet.dart`
**Settings entry:** "Streaming Breakdown"

**Content to cover:**
- Percentage is calculated by number of items completed per service, not by hours watched
- A title is attributed to whichever streaming provider was listed first in its metadata at time of completion
- Only completed items are counted (in-progress items not included)
- Items with no streaming provider data show as "Other"

---

## Settings > Help Section Updates

Add all new guide entries to the Help section in `settings_screen.dart`, following the existing pattern:

| Row Label | Guide Sheet |
|---|---|
| Queue Health Score ✅ | `QueueEfficiencyGuideSheet` |
| Mood Categories ✅ | `MoodGuideSheet` |
| Streak & Activity 🔲 | `StreakGuideSheet` |
| Recommendation Modes 🔲 | `RecommendationModesGuideSheet` |
| Badges & Achievements 🔲 | `BadgesGuideSheet` |
| Watch Parties 🔲 | `WatchPartyGuideSheet` |
| Stats & Analytics 🔲 | `StatsGuideSheet` |
| Streaming Breakdown 🔲 | `StreamingBreakdownGuideSheet` |

---

## Implementation Notes
- Each sheet follows the same layout: handle bar → header + close → scrollable content
- Use `_buildSectionHeader`, `_buildScoreItem`, `_buildStatusItem` helper pattern from existing guides
- `show()` is always a static method — no state needed, sheets are purely informational
- Max height: `MediaQuery.of(context).size.height * 0.85`
- Sheets registered in Settings regardless of whether the in-context info icon exists yet (discoverability first)
