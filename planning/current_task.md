# Current Task: Mood Guide

**Status**: QA
**Mode**: STUDIO
**Priority**: Medium
**Started**: 2026-02-12
**Specs**: `mood_guide.md`
**Plan**: `STUDIO_PLAN.md`

---

## Overview

Add a mood legend so users understand what genres each mood filter maps to. Two entry points: an (i) info button on the dashboard mood filter bar, and a "Mood Guide" tile in Settings.

---

## Tasks

### Frontend Tasks

| # | Task | Status | Owner |
|---|------|--------|-------|
| 1 | Create `MoodGuideSheet` shared widget (bottom sheet listing all 6 moods with icon, color, name, description, genre tags) | DONE | Frontend |
| 2 | Add info icon button to `MoodFilterChips` row that opens `MoodGuideSheet` | DONE | Frontend |
| 3 | Add "Help" section to `SettingsScreen` with "Mood Guide" tile that opens `MoodGuideSheet` | DONE | Frontend |

### QA

| # | Task | Status |
|---|------|--------|
| 4 | Verify info button on dashboard opens mood guide sheet | TODO |
| 5 | Verify Settings > Mood Guide opens same sheet | TODO |
| 6 | Verify sheet displays all 6 moods with correct genres | TODO |

---

## Previous Tasks

- Social Features Suite (Friend System, Watchlist Co-Curators) - **In Progress** (Watch Party + Shareable Playlists remaining)
- Follow Talent (Actors & Directors) - **Complete**
- Streaming Availability Alerts - **Complete**
- Push Notifications Infrastructure - **Complete**
- Move Item Between Watchlists - **Complete**
- Release & Air Dates Display - **Complete**
- Partial Episode Progress Display Fix - **Complete**
- External Sharing - **Complete**
- Dashboard Performance Optimization - **Complete**
- Profile Stats Performance & Minutes Watched Accuracy - **Complete**
- Queue Health Watchlist Switch Bug - **Complete**
- Badge Placement Consistency - **Complete**
