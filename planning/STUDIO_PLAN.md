# Mood Guide

**Status:** TODO
**Mode:** STUDIO
**Priority:** Medium
**Started:** 2026-02-12
**Specs:** `mood_guide.md`

---

## Problem Description

Users see mood filter chips (Comfort, Thriller, Lighthearted, etc.) on the dashboard but have no way to know which genres each mood maps to. This reduces discoverability and usage of the mood filter feature.

---

## Design Decisions (ADR)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Entry points | Info button on filter bar + Settings tile | Maximum discoverability: in-context where moods are used, plus always-accessible in Settings |
| Presentation | Bottom sheet (shared widget) | Consistent with existing app patterns; lightweight, no navigation needed |
| Genre labels | Hardcoded display strings per mood | Moods are a static enum; no need to resolve TMDB genre IDs at runtime |
| Settings placement | New "Help" section | Clean separation from existing sections; extensible for future help content |

---

## Solution Overview

1. **`MoodGuideSheet`** — shared bottom sheet widget showing all 6 moods with colored dot, icon, name, description, and genre chips
2. **Info button on `MoodFilterChips`** — small (i) icon at leading edge of the horizontal mood chip row
3. **Settings "Help" section** — new section with "Mood Guide" tile that opens the same sheet

---

## New Files

| File | Purpose |
|------|---------|
| `lib/shared/widgets/mood_guide_sheet.dart` | Reusable bottom sheet displaying the mood-to-genre legend |

---

## Modified Files

| File | Changes |
|------|---------|
| `lib/features/dashboard/widgets/mood_filter_chips.dart` | Add `Icons.info_outline` IconButton at the start of the chip row; on tap opens `MoodGuideSheet` |
| `lib/features/settings/screens/settings_screen.dart` | Add "Help" `_buildSection` between "About" and "Notifications" with a "Mood Guide" tile; on tap opens `MoodGuideSheet` |

---

## Widget Spec: MoodGuideSheet

```
Bottom sheet (Get.bottomSheet pattern):
├── Header: "Mood Guide" title
├── For each MoodTag.values:
│   ├── Row
│   │   ├── Colored circle (mood.color, 12px)
│   │   ├── Icon (mood.icon, 20px, mood.color)
│   │   ├── Column
│   │   │   ├── Text: mood.displayName (fontMd, bold)
│   │   │   └── Text: mood.description (fontSm, textSecondary)
│   │   └── Wrap of genre name chips (small, outlined)
```

Genre display names per mood (hardcoded):
- **Comfort**: Comedy, Family, Animation
- **Thriller**: Thriller, Horror, Crime, Mystery
- **Lighthearted**: Comedy, Romance, Animation
- **Intense**: Action, Thriller
- **Emotional**: Drama, Romance
- **Escapism**: Fantasy, Sci-Fi, Adventure

---

## Dependencies & Order

```
Task 1: MoodGuideSheet widget (standalone, no deps)
    ├── Task 2: Info button on MoodFilterChips (depends on Task 1)
    └── Task 3: Settings Help section (depends on Task 1)
```

Tasks 2 and 3 can parallelize after Task 1.

---

## Previous Plan (In Progress)

**Social Features Suite** — Friend System (done), Watchlist Co-Curators (done), Watch Party Sync (todo), Shareable Playlists (todo)
