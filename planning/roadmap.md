# BingeQuest Roadmap

## Project Overview

**BingeQuest** is a gamified watchlist tracker that transforms streaming backlog management into a quest. Users add movies and TV shows, track progress per episode, and receive smart recommendations to finish their queue efficiently.

**Core Value Proposition:** "Finish your watchlist faster with gamified recommendations."

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (stable) |
| State Management | GetX |
| Backend | Supabase (PostgreSQL + Auth + Storage) |
| Content API | TMDB (The Movie Database) |
| Authentication | Google Sign-In, Apple Sign-In |
| Monetization | Google AdMob (free tier), Premium tier (ad-free) |
| Platforms | Android, iOS |

---

## Shipped ✅

### Core & Infrastructure
- [x] MVP — core watchlist loop (add, track progress, recommendations)
- [x] Content Cache Migration
- [x] Infrastructure & Compliance
- [x] Dashboard Performance Optimization
- [x] Profile Stats Performance & Minutes Watched Accuracy

### Gamification
- [x] Badges & Achievements
- [x] Queue Efficiency Score
- [x] User Archetypes
- [x] BingeQuest Top 10
- [x] Viral Hits Mode
- [x] Recent Progress Mode

### Discovery & Search
- [x] Enhanced Search & Discovery
- [x] Search Suggestions
- [x] Mood Guide
- [x] Watchlist Filters & Sorting
- [x] Episode Metadata Enhancements
- [x] Release & Air Dates Display
- [x] Streaming Breakdown on Profile
- [x] Streaming Badge

### Social
- [x] Friend System
- [x] Watchlist Co-Curators
- [x] Friends Watching Content Indicator
- [x] Follow Talent (Actors & Directors)
- [x] Reviews & Ratings
- [x] External Sharing
- [x] User Count Display

### Notifications
- [x] Push Notifications Infrastructure
- [x] New Episode Notifications
- [x] Streaming Availability Alerts
- [x] Notification Management (delete & clear all)

### Watch Parties
- [x] Watch Party Sync
- [x] Watch Party Sayings

### Quality of Life
- [x] Partial Episode Progress Display
- [x] Add to Multiple Watchlists
- [x] Move Item Between Watchlists
- [x] View in Watchlist Button
- [x] Contextual Info Guides
- [x] Advanced Stats Dashboard
- [x] Apple Sign-In

---

## Active 🔨

| # | Feature | File |
|---|---------|------|
| 046 | Notification Management | [01_active/046_notification_management.md](features/01_active/046_notification_management.md) |

---

## Sprint 1 — Bug Fixes (High Priority)

| # | Feature | Mode | Priority |
|---|---------|------|----------|
| 049 | Archetype History Duplicate Entries | FLOW | High |
| 050 | Content Cache Episode Staleness | FLOW | High |
| 047 | Apple Sign-In Username Display Priority | FLOW | Medium |

---

## Sprint 2 — Quick FLOW Wins (UI, no backend)

| # | Feature | Mode | Priority |
|---|---------|------|----------|
| 052 | Friend Search Hint Text | FLOW | Low |
| 057 | Watchlist Dashboard UX Pills | FLOW | Medium |
| 058 | Watch Party Multi-Select | FLOW | Medium |
| 059 | Watch Party Tab Navigation | FLOW | Low |
| 053 | Item Detail — Friends Reviews First | FLOW | Medium |
| 054 | Item Detail — Social Sharing | FLOW | Medium |

---

## Sprint 3 — Medium Complexity

| # | Feature | Mode | Priority |
|---|---------|------|----------|
| 056 | Top 10 Friends Toggle | FLOW | Low |
| 051 | Episode Notification Release Date Trigger | STUDIO | High |

---

## Sprint 4 — STUDIO Features

| # | Feature | Mode | Priority |
|---|---------|------|----------|
| 055 | Profile Sharing / Friend Invite Link | STUDIO | Medium |
| 048 | App Navigation UX Audit | STUDIO | Medium |
| 034 | Shareable Playlists | STUDIO | Medium |

---

## Deferred / Needs Scoping

| # | Feature | Notes |
|---|---------|-------|
| 008 | Community Features (challenges, leaderboards) | Too vague — needs Planner pass before actionable |

---

*Last updated: 2026-04-02*
