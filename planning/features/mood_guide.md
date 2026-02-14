# Feature: Mood Guide

## Summary
Surface the mood-to-genre mapping to users so they understand what each mood filter represents. Two entry points: an info button on the dashboard mood filter bar, and a "Mood Guide" tile in Settings.

## Motivation
Users see mood chips (Comfort, Thriller, etc.) but have no way to know which genres each mood maps to. This creates confusion and reduces usage of the mood filter feature.

## Design

### A. Info Button on Mood Filter Bar
- Add a small `Icons.info_outline` icon button at the leading edge of the `MoodFilterChips` row.
- Tapping it opens a bottom sheet with the mood legend.
- Icon should be subtle (textSecondary color, 18px) so it doesn't compete with the chips.

### B. Settings Entry
- Add a "Help" section to `settings_screen.dart` (between "About" and "Notifications").
- Single tile: icon `Icons.mood`, label "Mood Guide".
- Tapping opens the same mood legend bottom sheet.

### C. Shared Mood Legend Bottom Sheet
A reusable widget (`MoodGuideSheet`) displaying all 6 moods:

| Mood | Description | Genres |
|------|------------|--------|
| Comfort | Feel-good & familiar | Comedy, Family, Animation |
| Thriller | Edge of your seat | Thriller, Horror, Crime, Mystery |
| Lighthearted | Fun & easy watch | Comedy, Romance, Animation |
| Intense | Action-packed | Action, Thriller |
| Emotional | Deep & moving | Drama, Romance |
| Escapism | Fantasy & sci-fi | Fantasy, Sci-Fi, Adventure |

Each row shows the mood's colored dot, icon, display name, description, and genre tags as small chips.

## Files to Change

### New
- `lib/shared/widgets/mood_guide_sheet.dart` — reusable bottom sheet widget

### Modify
- `lib/features/dashboard/widgets/mood_filter_chips.dart` — add info icon button at leading edge of the row
- `lib/features/settings/screens/settings_screen.dart` — add "Help" section with "Mood Guide" tile

## Genre Label Mapping
The `MoodTag.genreIds` use TMDB integer IDs. The sheet needs human-readable genre names. Options:
1. Hardcode a display list per mood (simplest, since moods are static).
2. Map from TMDB genre ID constants if they exist in the codebase.

Recommend option 1 — moods are an enum with fixed genre lists, no need to over-engineer.

## Verification
- Tap (i) on dashboard mood bar → bottom sheet appears with all 6 moods and their genres.
- Open Settings → "Help" section visible → tap "Mood Guide" → same bottom sheet appears.
- Bottom sheet follows existing app styling (EColors, ESizes, dark theme).
