# Feature: Release Calendar

**Mode:** STUDIO  
**Status:** COMPLETED (2026-07-07)

## Implementation Notes (as-built, differs from original plan below)

- **Data layer**: implemented as a single server-side RPC (`get_calendar_events(from_date, to_date)`, migration `072_calendar_events_rpc.sql`) rather than two client-side `.in_()` queries. One round trip, joins `watchlist_items` + `watchlists` + `content_cache` + `content_cache_episodes` server-side, RLS-scoped via `SECURITY INVOKER`. Supersedes the "Data Layer" plan below.
- **Controller registration**: `CalendarController` is registered globally in `main.dart:118` via `Get.lazyPut(fenix: true)`, matching every other controller in this app (`AuthController`, `WatchlistController`, etc.). There is no `bindings/` pattern anywhere in the codebase — the planned `CalendarBinding` (per-route) was never a real convention here and was dropped. Supersedes the `CalendarBinding` references below.
- **Testability seam**: `CalendarController` takes an optional `CalendarEventsFetcher` constructor param (defaults to wrapping `CalendarRepository.getCalendarEvents`) so tests can inject a mock without refactoring the (static, like all repositories in this app) `CalendarRepository` itself.
- Shipped in `3f6da0d` (2026-05-27); tests added 2026-07-07 in `test/features/calendar/calendar_controller_test.dart` (14 cases: load/error states, date normalization, dedup rules, per-watchlist filtering, month navigation). No `calendar_repository_test.dart` — repository is static and hardwired to `Supabase.instance.client`, not mockable without an app-wide repository DI refactor that's out of scope here; RPC call itself is covered by manual QA only.

## Context

Users currently have no way to see what's coming out without checking each show individually. This feature adds a dedicated Calendar tab showing upcoming TV episode air dates and movie theatrical release dates from the user's watchlists, with per-watchlist filter chips so they can focus on a specific watchlist or view everything at once.

All required data already lives in the schema (`content_cache_episodes.air_date`, `content_cache.release_date`). No migration is required for V1.

> **Note on streaming release dates:** `content_cache` tracks current streaming availability (providers) but not the date a movie begins streaming. TMDB does not reliably expose this date either. V1 includes theatrical releases only; streaming release dates are a future enhancement.

---

## Scope

### What's included
- New `calendar` feature module (`lib/features/calendar/`)
- `CalendarEvent` model — flat event type covering episodes and movie releases
- `CalendarRepository` — two queries: upcoming episodes from `content_cache_episodes`, upcoming movies from `content_cache`
- `CalendarController` — loads events on init, manages selected date, focused month, and watchlist filter
- `CalendarScreen` — filter chips row + month grid + day detail list
- `CalendarMonthGrid` widget — custom month grid (no third-party package), dot indicators, day selection
- `CalendarEventCard` widget — poster + title + episode code or "Theatrical Release" label + watchlist chip
- Calendar icon (`Icons.calendar_month`) added to Library screen app bar; taps open `CalendarScreen` via `Get.to(() => const CalendarScreen())`
- `CalendarController` registered in `main.dart` alongside every other controller (see Implementation Notes above — no per-route binding)

### What's excluded
- Movie streaming release dates (data gap — see note above)
- Push notifications triggered from the calendar (handled by existing episode notification system)
- Past events / history view (90-day forward window only in V1)
- Multi-dot indicators per watchlist color (single accent dot per day in V1)

---

## Data Layer

### New: `lib/shared/models/calendar_event.dart`
```dart
class CalendarEvent {
  final DateTime date;
  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final String? posterPath;
  final CalendarEventType type; // episode | movieRelease
  final String? episodeCode;    // "S5E01" — TV only
  final String watchlistId;
  final String watchlistName;
}

enum CalendarEventType { episode, movieRelease }
```

### As-built: `lib/shared/repositories/calendar_repository.dart`
- `getCalendarEvents(DateTime from, DateTime to)` — calls the `get_calendar_events(from_date, to_date)` RPC (migration `072_calendar_events_rpc.sql`), which does the episode + movie union server-side and returns rows already scoped to the caller's watchlists via RLS.

### Controller data flow
1. `loadEvents()` calls the injected `CalendarEventsFetcher` (defaults to `CalendarRepository.getCalendarEvents`) with a 90-day window from today
2. Each row is mapped to a `CalendarEvent`; `event_date` is parsed and normalized to `DateTime(y, m, d)` (date-only, local time) to prevent lookup misses from time-of-day components
3. `filteredEventsByDate` is a computed getter that reads `selectedWatchlistId.value` (an `.obs`) internally — `Obx` in the view tracks this dependency automatically; no re-fetch on filter change. Deduplication (only applied for the "all" filter) key: `(tmdbId, seasonNumber, episodeNumber)` for episodes, `(tmdbId)` for movies

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `lib/shared/models/calendar_event.dart` | `CalendarEvent` model + `CalendarEventType` enum |
| `lib/shared/repositories/calendar_repository.dart` | `getCalendarEvents()` — wraps the `get_calendar_events` RPC |
| `supabase/migrations/072_calendar_events_rpc.sql` | `get_calendar_events(from_date, to_date)` SQL function + supporting indexes |
| `lib/features/calendar/controllers/calendar_controller.dart` | State + data loading + filter/dedup logic; `CalendarEventsFetcher` seam for testability |
| `lib/features/calendar/screens/calendar_screen.dart` | Filter chips + month grid + day detail list |
| `lib/features/calendar/widgets/calendar_month_grid.dart` | Custom month grid with dot indicators |
| `lib/features/calendar/widgets/calendar_event_card.dart` | Event card (poster + title + chips) |
| `lib/features/watchlist/screens/library_screen.dart` | Calendar icon in app bar `actions` (`library_screen.dart:74-75`); tap → `Get.to(() => const CalendarScreen())` |
| `test/features/calendar/calendar_controller_test.dart` | Unit tests for filter logic, deduplication, date normalization, month navigation |

---

## UI Design Notes

- **Filter chips:** Follow the `AnimatedContainer` + `_chipDecoration` pattern from `lib/features/watchlist/widgets/filter_chips.dart`. Chips: "All" (default) + one per watchlist.
- **Month grid:** Custom `GridView` — no third-party calendar package. Day cells show: day number, today circle badge, selected day fill, dot indicator (`EColors.primary`) if the day has events.
- **Day detail header:** "June 2 — N releases"
- **`CalendarEventCard`:** 60×90 poster (same aspect ratio as `WatchlistItemCard`), title 2-line truncation, episode code chip for TV, "Theatrical Release" label for movies, watchlist name chip. Tap → `Get.to(() => ItemDetailScreen(tmdbId:, mediaType:))`.
- All chip and color values use `EColors` / `ESizes` constants — no raw values.

---

## Acceptance Criteria

1. Calendar icon visible in Library screen app bar; tapping it opens `CalendarScreen` via `Get.to()`
2. Month grid shows current month by default; ◀/▶ arrows navigate months
3. Days with upcoming releases show a dot indicator; days without do not
4. Tapping a day populates the detail section with that day's events
5. "All" chip (default) aggregates events across watchlists with deduplication; per-watchlist chip filters correctly
6. TV episodes display episode code (e.g. S2E05) and show title
7. Movie theatrical releases display a "Theatrical Release" label
8. Empty state shown when no upcoming releases are found
9. Loading spinner shown during initial fetch; inline error on failure (no crash)
10. Tapping an event card navigates to the correct `ItemDetailScreen`
11. 90-day lookahead window from today; today is always visible; month navigation within that window shows correct dot indicators

---

## Verification

1. Add a TV show to a watchlist — confirm next upcoming episode appears on the correct calendar date
2. Add a movie with a future `release_date` — confirm it appears on the correct date
3. Toggle per-watchlist filter chips — confirm events filter correctly
4. Navigate months with ◀/▶ — confirm dot indicators match events
5. Tap a day with multiple events — confirm all appear in detail list
6. Tap an event card — confirm navigation to correct `ItemDetailScreen`
7. `dart analyze` passes with no new warnings
